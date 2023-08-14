//
//  ManageVideosViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 14/08/23.
//

import UIKit
import Kingfisher
import AVFoundation
import AVKit

protocol ManageVideosViewControllerDelegate: AnyObject {
    func restartAllPanel()
}

class ManageVideosViewController: UIViewController {

    weak var delegate: ManageVideosViewControllerDelegate?
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var tableViewClips: UITableView!
    @IBOutlet weak var btnPlus: UIButton!
    @IBOutlet weak var viewContainerLeading: NSLayoutConstraint!
    @IBOutlet weak var viewContainerTrailing: NSLayoutConstraint!
    @IBOutlet weak var viewContainerTop: NSLayoutConstraint!
    @IBOutlet weak var viewContainerBottom: NSLayoutConstraint!
    
    var indexpathToRename: IndexPath?
    var arrClips: [Any] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
    }
    
    func setupView() {
        self.viewContainer.layer.cornerRadius = 10.0
        self.viewContainer.layer.masksToBounds = true
        self.tableViewClips.delegate = self
        self.tableViewClips.dataSource = self
        self.tableViewClips.register(UINib(nibName: "ManageVideoCell", bundle: nil), forCellReuseIdentifier: "ManageVideoCell")
        self.adjustPopupConstraints()
        self.setupMenuOptions()
        self.getAllClips()
    }
    
    func setupMenuOptions() {
        let PhotoLibrary = UIAction(title: "Photo Library", image: nil) { _ in
            
        }
        
        let GoogleDrive = UIAction(title: "Google Drive", image: nil) { _ in
          
        }
        
        let Dropbox = UIAction(title: "Dropbox", image: nil) { _ in
            
        }
        
        self.btnPlus.overrideUserInterfaceStyle = .dark
        self.btnPlus.showsMenuAsPrimaryAction = true
        self.btnPlus.menu = UIMenu(title: "Import from", children: [PhotoLibrary, GoogleDrive, Dropbox])
    }
    
    func adjustPopupConstraints() {
        if Utility.getDeviceOrientation().isLandscape {
            self.viewContainerLeading.constant = 150
            self.viewContainerTrailing.constant = 150
            self.viewContainerTop.constant = 20
            self.viewContainerBottom.constant = 20
        }
        else {
            self.viewContainerLeading.constant = 40
            self.viewContainerTrailing.constant = 40
            self.viewContainerTop.constant = 80
            self.viewContainerBottom.constant = 80
        }
    }
    
    @IBAction func btnPlusAction(_ sender: Any) {
        
    }
    
    @IBAction func btnCloseAction(_ sender: Any) {
        self.delegate?.restartAllPanel()
        self.dismiss(animated: true)
    }
    
    func getAllClips() {
        self.arrClips.removeAll()
        let wholeFavVideos = CoreDataManager.shared.getAllFavoriteVideos()
        let allClipse = CoreDataManager.shared.getAllClips()
        self.arrClips.append(contentsOf: wholeFavVideos)
        print(self.arrClips.count)
        self.arrClips.append(contentsOf: allClipse)
        print(self.arrClips.count)
        self.tableViewClips.reloadData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.adjustPopupConstraints()
    }
}

extension ManageVideosViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrClips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ManageVideoCell") as! ManageVideoCell
        
        cell.setupCell()
        let clip = self.arrClips[indexPath.row]
        if let aClip = clip as? VideoClip {
            let thumbURL = Utility.getDirectoryPath(folderName: DirectoryName.Thumbnails)!.appendingPathComponent(aClip.thumbnailURL ?? "")
            cell.imgThumb.kf.setImage(with: thumbURL)
            cell.lblClipName.text = "\(aClip.clipURL ?? "")"
            
            let clipURL = Utility.getDirectoryPath(folderName: DirectoryName.SavedClips)!.appendingPathComponent(aClip.clipURL ?? "")
            let asset = AVAsset(url: clipURL)
            let duration = asset.duration
            let durationTime = CMTimeGetSeconds(duration)
            let formattedDuration = cell.formatTime(duration: durationTime)
            cell.lblDuration.text = formattedDuration
        }
        else {
            let vClip = clip as! VideoTable
            let thumbURL = Utility.getDirectoryPath(folderName: DirectoryName.Thumbnails)!.appendingPathComponent(vClip.thumbnailURL ?? "")
                        
            cell.imgThumb.kf.setImage(with: thumbURL)
            cell.lblClipName.text = "\(vClip.videoURL ?? "")"
            
            let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(vClip.videoURL ?? "")
            let asset = AVAsset(url: videoURL)
            let duration = asset.duration
            let durationTime = CMTimeGetSeconds(duration)
            let formattedDuration = cell.formatTime(duration: durationTime)
            cell.lblDuration.text = formattedDuration
        }
        
        cell.btnPlay.tag = indexPath.row
        cell.btnPlay.addTarget(self, action: #selector(btnPlayAction), for: .touchUpInside)
                
        return cell
    }
    //
    @objc func btnPlayAction(sender: UIButton) {
        let index = sender.tag
        let clip = self.arrClips[index]
        var clipURL: URL?
        if let aClip = clip as? VideoClip {
            clipURL = Utility.getDirectoryPath(folderName: DirectoryName.SavedClips)!.appendingPathComponent(aClip.clipURL ?? "")
        }
        else {
            let vClip = clip as! VideoTable
            clipURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(vClip.videoURL ?? "")
        }
        
        let playerItem = AVPlayerItem(url: clipURL!)
        player = AVPlayer(playerItem: playerItem)
        
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        if let playerViewController = playerViewController {
            present(playerViewController, animated: true) {
                self.player?.play()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 57
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Swipe-to-delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            self.showDeleteConfirmation(indexPath: indexPath)
            completionHandler(true)
        }
        
        // Swipe-to-rename action
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { (action, view, completionHandler) in
            self.indexpathToRename = indexPath
            self.showAlertWithRenameTextField()
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .red
        renameAction.backgroundColor = .blue
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
        return configuration
    }
    
    //Rename clip
    func showAlertWithRenameTextField() {
        let alertController = UIAlertController(title: "Rename clip", message:  nil, preferredStyle: .alert)
        
        guard let indexPath = self.indexpathToRename?.row else {
            return
        }
        
        let clip = self.arrClips[indexPath]
        var oldVideoName = ""
        
        alertController.addTextField { textField in
            textField.placeholder = "Rename"
            
            if let aClip = clip as? VideoClip {
                let name = aClip.clipURL ?? ""
                oldVideoName = name
                textField.text = name.components(separatedBy: ".").dropLast().joined(separator: ".")
            }
            else {
                let vClip = clip as! VideoTable
                let name = vClip.videoURL ?? ""
                oldVideoName = name
                textField.text = name.components(separatedBy: ".").dropLast().joined(separator: ".")
            }
        }
        
        let saveAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            if let name = alertController.textFields?.first?.text, !name.isEmpty {
                // Valid text entered, perform your action here
                print("Text name: \(name)")
                self?.checkAlreadyExistAndRename(newVideoName: name, oldVideoName: oldVideoName, clip: clip)
            } else {
                // Blank text entered, showing an error message
                self?.showValidationError()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    func checkAlreadyExistAndRename(newVideoName: String, oldVideoName: String, clip: Any) {
        let url = URL(fileURLWithPath: oldVideoName)
        let oldExtenstion = url.pathExtension
        
        let newVideo = "\(newVideoName).\(oldExtenstion)"
        if newVideo == oldVideoName {
            return
        }
        else {
            if let aClip = clip as? VideoClip {
                let name = aClip.clipURL ?? ""
        
                if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.SavedClips) {
                    
                    let oldVideoURL = directoryURL.appendingPathComponent("\(oldVideoName)")
                    let newVideoURL = oldVideoURL.deletingLastPathComponent().appendingPathComponent("\(newVideoName).\(oldVideoURL.pathExtension)")
                    
                    if FileManager.default.fileExists(atPath: newVideoURL.path) {
                        self.showAlert(title: "Clip name already exist", message: "Please choose another name") { result in
                            self.showAlertWithRenameTextField()
                        }
                    }
                    else {
                        //```
                        do {
                            try FileManager.default.moveItem(at: oldVideoURL, to: newVideoURL)
                            CoreDataManager.shared.renameClip(clipURL: name, newClipURL: "\(newVideoName).\(oldVideoURL.pathExtension)")
                            DispatchQueue.main.async {
                                self.getAllClips()
                            }
                            print("Clip renamed successfully.")
                        } catch {
                            print("Error renaming clip: \(error.localizedDescription)")
                        }
                    }
                }
            }
            else {
                let vClip = clip as! VideoTable
                
                if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
                    
                    let oldVideoURL = directoryURL.appendingPathComponent("\(oldVideoName)")
                    let newVideoURL = oldVideoURL.deletingLastPathComponent().appendingPathComponent("\(newVideoName).\(oldVideoURL.pathExtension)")
                    
                    if FileManager.default.fileExists(atPath: newVideoURL.path) {
                        self.showAlert(title: "Clip name already exist", message: "Please choose another name") { result in
                            self.showAlertWithRenameTextField()
                        }
                    }
                    else {
                        do {
                            try FileManager.default.moveItem(at: oldVideoURL, to: newVideoURL)
                            CoreDataManager.shared.renameVideo(videoURL: vClip.videoURL ?? "", newVideoURL: "\(newVideoName).\(oldVideoURL.pathExtension)")
                            DispatchQueue.main.async {
                                self.getAllClips()
                            }
                            print("Video renamed successfully.")
                        } catch {
                            print("Error renaming video: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func showValidationError() {
        let validationAlert = UIAlertController(title: "Error", message: "Please enter valid name.", preferredStyle: .alert)
               
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.showAlertWithRenameTextField()
        }
        validationAlert.addAction(okAction)
        present(validationAlert, animated: true)
    }
    
    //Delete clip
    @objc func showDeleteConfirmation(indexPath: IndexPath) {
        let alertController = UIAlertController(
            title: "Delete clip",
            message: "Are you sure you want to delete?",
            preferredStyle: .actionSheet
        )
        
        let clip = self.arrClips[indexPath.row]
        let deleteAction = UIAlertAction(title: "Delete video", style: .destructive) { _ in
            // Performing the delete action
            
            if let aClip = clip as? VideoClip {
                print("deleted clip: \(aClip.clipURL ?? "")")
                
                if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.SavedClips) {
                    
                    let destinationURL = directoryURL.appendingPathComponent(aClip.clipURL ?? "")
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try? FileManager.default.removeItem(at: destinationURL)
                        CoreDataManager.shared.deleteClip(clipURL: "\(aClip.clipURL ?? "")")
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let clips = CoreDataManager.shared.getAllClips()
                    for cdata in clips {
                        print("C Name: \(cdata.clipURL ?? "") | isDeleted: \(cdata.is_Deleted)")
                    }
                }
            }
            else {
                let vClip = clip as! VideoTable
                print("deleted video: \(vClip.videoURL ?? "")")
                
                CoreDataManager.shared.updateIsFavorite(videoURL: vClip.videoURL ?? "", isFavorite: false)
                                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let videoData = CoreDataManager.shared.getAllVideos()
                    for vdata in videoData {
                        print("V Name: \(vdata.videoURL ?? "") | isFav: \(vdata.isFavorite) | isDeleted: \(vdata.is_Deleted)")
                    }
                }
            }
            self.arrClips.remove(at: indexPath.row)
            self.tableViewClips.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            // Set the source view for iPad and other devices with popover support
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
