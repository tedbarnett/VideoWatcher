//
//  DropboxViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 24/08/23.
//

import UIKit
import SwiftyDropbox

class DropboxViewController: UIViewController {

    @IBOutlet weak var tblFileList: UITableView!
    @IBOutlet weak var lblNoVideos: UILabel!
    var currentPath = ""
    var files: [Any] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
    }
    
    func setupView() {
        self.tblFileList.delegate = self
        self.tblFileList.dataSource = self
        self.tblFileList.register(UINib(nibName: "DropboxCell", bundle: nil), forCellReuseIdentifier: "DropboxCell")
        if self.currentPath == DropBox.kDropboxRootFolder {
            self.listFilesInFolder(path: DropBox.kDropboxRootFolder)
        }
    }
    
    func listFilesInFolder(path: String) {
        let client = DropboxClientsManager.authorizedClient
        client?.files.listFolder(path: path).response { response, error in
            if let result = response {
                self.files = result.entries.filter { entry -> Bool in
                    if let _ = entry as? Files.FolderMetadata {
                        return true
                    } else if let fileMetadata = entry as? Files.FileMetadata {
                        if let lowercasedPath = fileMetadata.pathDisplay?.lowercased() as String? {
                            if lowercasedPath.hasSuffix(".mp4") || lowercasedPath.hasSuffix(".mov") {
                                return true
                            }
                        }
                    }
                    return false
                }
                self.currentPath = path
                print(self.files)
                if self.files.isEmpty {
                    self.tblFileList.isHidden = true
                    self.lblNoVideos.isHidden = false
                } else {
                    self.tblFileList.isHidden = false
                    self.lblNoVideos.isHidden = true
                    self.tblFileList.reloadData()
                }
            } else if let error = error {
                print("Error listing files: \(error)")
            }
        }
    }
}

extension DropboxViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DropboxCell") as! DropboxCell
        
        let file = self.files[indexPath.row]
        if let folder = file as? Files.FolderMetadata {
            cell.lblName.text = folder.name
            cell.lblDetails.isHidden = true
            cell.lblNameTop.constant = 18.0
            cell.imgView.image = UIImage(named: "folder")
        }
        else {
            let file = file as? Files.FileMetadata
            cell.lblName.text = file?.name
            
            let fileSize = ByteCountFormatter.string(fromByteCount: Int64(file?.size ?? 0), countStyle: .file)
            cell.lblDetails.text = fileSize
            cell.lblDetails.isHidden = false
            cell.lblNameTop.constant = 10.0
            cell.imgView.image = UIImage(named: "movie")
            
        }
        
        return cell
    }
    
    func encodeFolderPath(_ folder: String, currentPath path: String) -> String {
        return "\(path)/\(folder)"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let file = self.files[indexPath.row]
        if let folder = file as? Files.FolderMetadata {
            let escapedSubpath = self.encodeFolderPath(folder.name, currentPath: self.currentPath)
            print("Selected path: \(escapedSubpath)")
            
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "DropboxViewController") as! DropboxViewController
            vc.title = folder.name
            vc.currentPath = escapedSubpath
            vc.listFilesInFolder(path: escapedSubpath)
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else {
            print("We can download it")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
