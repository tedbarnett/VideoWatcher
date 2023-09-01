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
    let client = DropboxClientsManager.authorizedClient
    var selectedItems: [IndexPath] = []
    var selectedFiles: [Any] = []
    var isEditingMode = false
    var toolbar: UIToolbar!
    var downloadButton: UIBarButtonItem!
    var toolbarHeight: CGFloat = 35
    var currentFileIndex = 0
    var hasMore = false
    var cursor: String?
    private var activityIndicatorView: UIActivityIndicatorView?
    
    @IBOutlet var viewLoading: UIView!
    @IBOutlet weak var activityIndicatorPhotoLib: UIActivityIndicatorView!
    @IBOutlet weak var lblVideosImported: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
    }
    
    func setupView() {
        self.tblFileList.delegate = self
        self.tblFileList.dataSource = self
        self.tblFileList.register(UINib(nibName: "DropboxCell", bundle: nil), forCellReuseIdentifier: "DropboxCell")
        self.lblNoVideos.text = "Loading..."
        
        self.tblFileList.allowsMultipleSelectionDuringEditing = true
        self.setupSelectNavigationBarButtons()
        self.setupToolbar()
        
        if self.currentPath == DropBox.kDropboxRootFolder {
            self.listFilesInFolder(path: DropBox.kDropboxRootFolder)
        }
    }
    
    func showLoadingView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                // Add your custom overlay view to the window scene
                self.viewLoading.frame = windowScene.coordinateSpace.bounds
                self.viewLoading.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                windowScene.windows.first?.addSubview(self.viewLoading)
            }
        }
        self.activityIndicatorPhotoLib.startAnimating()
    }
    
    func hideLoadingView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            self.viewLoading.removeFromSuperview()
            self.activityIndicatorPhotoLib.stopAnimating()
        })
    }
    
    @objc func logoutButtonTapped() {
        DropboxClientsManager.unlinkClients()
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    //MARK: - Setup toolbar
    func setupToolbar() {
        let toolbarY = view.bounds.height - toolbarHeight - view.safeAreaInsets.bottom
        
        toolbar = UIToolbar(frame: CGRect(x: 0, y: toolbarY, width: view.bounds.width, height: toolbarHeight))
        toolbar.barTintColor = UIColor(red: 1.0/255.0, green: 1.0/255.0, blue: 1.0/255.0, alpha: 1.0)
        
        view.addSubview(toolbar)
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        downloadButton = UIBarButtonItem(title: "Import videos", style: .plain, target: self, action: #selector(downloadSelectedItems))
        
        toolbar.items = [flexibleSpace, downloadButton]
    }

    func updateToolbarPosition() {
        let toolbarHeight = toolbar.frame.size.height
        
        UIView.animate(withDuration: 0.3) {
            if self.selectedItems.count > 0 {
                let toolbarY = self.view.bounds.height - toolbarHeight - self.view.safeAreaInsets.bottom
                self.toolbar.frame = CGRect(x: 0, y: toolbarY, width: self.view.bounds.width, height: toolbarHeight)
            } else {
                let toolbarY = self.view.bounds.height + toolbarHeight
                self.toolbar.frame = CGRect(x: 0, y: toolbarY, width: self.view.bounds.width, height: toolbarHeight)
            }
        }
    }
    
    func updateDownloadButtonTitle() {
        let selectedCount = selectedItems.count
        if selectedCount > 0 {
            let downloadTitle = "Import \(selectedCount) videos"
            downloadButton.title = downloadTitle
        } else {
            downloadButton.title = "Import videos"
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateToolbarPosition()
    }
        
    @objc func downloadSelectedItems() {
        print("Downloading selected items: \(selectedFiles)")
        self.startSequentialDownloads()
    }
    
    //MARK: - Setup multiple selection methods
    func setupSelectNavigationBarButtons() {
        let editButton = UIBarButtonItem(title: isEditingMode ? "Done" : "Select", style: .plain, target: self, action: #selector(toggleEditing))
        navigationItem.rightBarButtonItem = editButton
    }
    
    @objc func toggleEditing() {
        isEditingMode.toggle()
        setupSelectNavigationBarButtons()
        
        if !isEditingMode {
            selectedItems.removeAll()
            selectedFiles.removeAll()
            updateSelectAllButtonTitle()
            navigationItem.leftBarButtonItem = nil
        } else {
            updateSelectAllButtonTitle()
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(selectAllItems))
        }
        
        self.updateToolbarPosition()
        self.tblFileList.setEditing(isEditingMode, animated: true)
    }
    
    @objc func selectAllItems() {
        if let selectAllButton = navigationItem.leftBarButtonItem, selectAllButton.title == "Select All" {
            selectedItems.removeAll()
            selectedFiles.removeAll()
            for row in 0..<self.files.count {
                let indexPath = IndexPath(row: row, section: 0)
                selectedItems.append(indexPath)
                selectedFiles.append(self.files[row])
                tblFileList.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            
            selectAllButton.title = "Deselect All"
        } else {
            for indexPath in selectedItems {
                tblFileList.deselectRow(at: indexPath, animated: false)
            }
            selectedItems.removeAll()
            selectedFiles.removeAll()
            navigationItem.leftBarButtonItem?.title = "Select All"
        }
        
        updateToolbarPosition()
        printSelectedItems()
        updateDownloadButtonTitle()
    }
    
    func updateSelectAllButtonTitle() {
        if selectedItems.count == files.count {
            navigationItem.leftBarButtonItem?.title = "Deselect All"
        } else {
            navigationItem.leftBarButtonItem?.title = "Select All"
        }
    }
    
    func printSelectedItems() {
        print("Selected Items: \(selectedItems.count)")
        print("Selected Files: \(selectedFiles.count)")
    }
    
    func listFilesInFolder(path: String) {
        client?.files.listFolder(path: path).response { response, error in
            if let result = response {
                print("response: \(String(describing: response))")
                
                self.cursor = response?.cursor
                if let hasMore = response?.hasMore {
                    self.hasMore = hasMore
                }
                else {
                    self.hasMore = false
                }
                
                self.files = result.entries.filter { entry -> Bool in
                    if let _ = entry as? Files.FolderMetadata {
                        return true
                    } else if let fileMetadata = entry as? Files.FileMetadata {
                        if let lowercasedPath = fileMetadata.pathDisplay?.lowercased() as String? {
                            if lowercasedPath.hasSuffix(".mp4") || lowercasedPath.hasSuffix(".mov") || lowercasedPath.hasSuffix(".m4v") {
                                return true
                            }
                        }
                    }
                    return false
                }
                self.currentPath = path
                //print(self.files)
                self.hasMore = result.hasMore
                
                self.files.sort { entry1, entry2 in
                    var name1: String = ""
                    if let fileMetadata = entry1 as? Files.FolderMetadata {
                        name1 = fileMetadata.name
                    } else if let fileMetadata = entry1 as? Files.FileMetadata {
                        name1 = fileMetadata.name
                    }
                    var name2: String = ""
                    if let fileMetadata = entry2 as? Files.FolderMetadata {
                        name2 = fileMetadata.name
                    } else if let fileMetadata = entry2 as? Files.FileMetadata {
                        name2 = fileMetadata.name
                    }
                    return name1.localizedCaseInsensitiveCompare(name2) == ComparisonResult.orderedAscending
                }
                
                if self.files.isEmpty {
                    self.lblNoVideos.text = "There are no videos in this folder."
                    self.tblFileList.isHidden = true
                    self.lblNoVideos.isHidden = false
                } else {
                    self.tblFileList.isHidden = false
                    self.lblNoVideos.isHidden = true
                }
                self.tblFileList.reloadData()
                
            } else if let error = error {
                print("Error listing files: \(error)")
                self.showAlert(title: "Error", message: error.description) { result in}
            }
        }
    }
    
    func listFolderContinue() {
        if let cursor = cursor {
            
            if activityIndicatorView == nil {
                // Create the activity indicator view when needed
                activityIndicatorView = UIActivityIndicatorView(style: .medium)
                activityIndicatorView?.frame = CGRect(x: 0, y: 0, width: tblFileList.bounds.width, height: 44)
                activityIndicatorView?.hidesWhenStopped = true
                activityIndicatorView?.color = UIColor.white
                tblFileList.tableFooterView = activityIndicatorView
            }
            
            // Start the activity indicator animation
            activityIndicatorView?.startAnimating()
            
            client?.files.listFolderContinue(cursor: cursor).response { response, error in
                if let result = response {
                    print("listFolderContinue response: \(String(describing: response))")
                    print(result.entries.count)
                    
                    self.cursor = response?.cursor
                    if let hasMore = response?.hasMore {
                        self.hasMore = hasMore
                    }
                    else {
                        self.hasMore = false
                    }
                    
                    let nextfiles = result.entries.filter { entry -> Bool in
                        if let _ = entry as? Files.FolderMetadata {
                            return true
                        } else if let fileMetadata = entry as? Files.FileMetadata {
                            if let lowercasedPath = fileMetadata.pathDisplay?.lowercased() as String? {
                                if lowercasedPath.hasSuffix(".mp4") || lowercasedPath.hasSuffix(".mov") || lowercasedPath.hasSuffix(".m4v") {
                                    return true
                                }
                            }
                        }
                        return false
                    }
                    
                    self.files.append(contentsOf: nextfiles)
                    self.activityIndicatorView?.stopAnimating()
                    
                    self.files.sort { entry1, entry2 in
                        var name1: String = ""
                        if let fileMetadata = entry1 as? Files.FolderMetadata {
                            name1 = fileMetadata.name
                        } else if let fileMetadata = entry1 as? Files.FileMetadata {
                            name1 = fileMetadata.name
                        }
                        var name2: String = ""
                        if let fileMetadata = entry2 as? Files.FolderMetadata {
                            name2 = fileMetadata.name
                        } else if let fileMetadata = entry2 as? Files.FileMetadata {
                            name2 = fileMetadata.name
                        }
                        return name1.localizedCaseInsensitiveCompare(name2) == ComparisonResult.orderedAscending
                    }
                    
                    print("Total files: \(self.files.count)")
                    self.tblFileList.reloadData()
                }
                else if let error = error {
                    print("Error listing files: \(error)")
                    self.showAlert(title: "Error", message: error.description) { result in}
                }
            }
        }
    }
    
    func startSequentialDownloads() {
        currentFileIndex = 0
        updateProgressLabel()
        downloadNextFile()
        showLoadingView()
    }
    
    // Recursive function to download files one by one
    func downloadNextFile() {
        guard !self.selectedFiles.isEmpty else {
            print("All files downloaded.")
//            self.selectedItems.removeAll()
//            self.selectedFiles.removeAll()
//            self.updateSelectAllButtonTitle()
//            navigationItem.leftBarButtonItem = nil
            
            self.hideLoadingView()
            self.showVideosImportedToast()
            self.toggleEditing()
            
            return
        }
        
        let fileToDownload = self.selectedFiles.removeFirst() // Get the first file from the array
        if let file = fileToDownload as? Files.FileMetadata {
            print("Downloading \(file.name)")
            let escapedSubpath = self.encodeFolderPath(file.name, currentPath: self.currentPath)
            print("Selected path: \(escapedSubpath)")
            
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
                let destinationURL = directoryURL.appendingPathComponent(file.name)
                
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    self.currentFileIndex += 1
                    self.updateProgressLabel()
                    downloadNextFile() // File already exists, move to the next file
                    return
                }
                
                let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
                    return destinationURL
                }
                client?.files.download(path: escapedSubpath, overwrite: true, destination: destination)
                    .response { response, error in
                        if let response = response {
                            print(response)
                            
                            CoreDataManager.shared.saveVideo(videoURL: destinationURL.lastPathComponent)
                            print("Video copied to document directory: \(destinationURL)")
                        } else if let error = error {
                            print(error)
                        }
                        
                        self.currentFileIndex += 1
                        self.updateProgressLabel()
                        self.downloadNextFile() // Download next file after completion
                    }
                    .progress { progressData in
                        print(progressData)
                    }
            }
        }
    }
    
    func updateProgressLabel() {
        let totalFiles = self.selectedItems.count
        let downloadedFiles = currentFileIndex
        //progressLabel.text = "\(downloadedFiles)/\(totalFiles) files downloaded"
        print("\(downloadedFiles)/\(totalFiles) videos imported...")
        self.lblVideosImported.text = "\(downloadedFiles)/\(totalFiles) videos imported"
    }
    
    func showVideosImportedToast() {
        let config = ToastConfiguration(
            direction: .top,
            autoHide: true,
            enablePanToClose: true,
            displayTime: 2,
            animationTime: 0.2
        )
        let toast = Toast.text("\(self.selectedItems.count) videos imported", config: config)
        toast.show(haptic: .success)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { context in
            if self.selectedItems.count > 0 {
                let toolbarY = size.height - self.view.safeAreaInsets.bottom - self.toolbarHeight
                self.toolbar.frame = CGRect(x: 0, y: toolbarY, width: size.width, height: self.toolbarHeight)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    self.viewLoading.frame = windowScene.coordinateSpace.bounds
                    self.viewLoading.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                }
            }
        }
    }
}

extension DropboxViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //return 60.0
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DropboxCell") as! DropboxCell
        
        let file = self.files[indexPath.row]
        if let folder = file as? Files.FolderMetadata {
            cell.lblName.text = folder.name
            cell.lblDetails.isHidden = true
            cell.lblNameTop.constant = 20.0
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
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else {
            //print("We can download it")
            if isEditingMode {
                selectedItems.append(indexPath)
                selectedFiles.append(self.files[indexPath.row])
            } else {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            updateSelectAllButtonTitle()
            printSelectedItems()
            updateToolbarPosition()
            updateDownloadButtonTitle()
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditingMode {
            if let index = selectedItems.firstIndex(of: indexPath) {
                selectedItems.remove(at: index)
               selectedFiles.remove(at: index)
            }
        }
        updateSelectAllButtonTitle()
        printSelectedItems()
        updateToolbarPosition()
        updateDownloadButtonTitle()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == files.count - 1 && self.hasMore {
            self.hasMore = false
            self.listFolderContinue()
        }
    }
    
    // MARK: - Editing and Multiple Selection Interaction
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        // You can perform any additional actions when multiple selection interaction starts
    }
}
