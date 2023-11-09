//
//  GoogleDriveViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 09/11/23.
//

import UIKit
import GoogleAPIClientForREST_Drive

class GoogleDriveViewController: UIViewController {

    @IBOutlet weak var tblFileList: UITableView!
    @IBOutlet weak var lblNoVideos: UILabel!
    var currentPath = ""
    var files: [GTLRDrive_File] = []
    var selectedItems: [IndexPath] = []
    var selectedFiles: [GTLRDrive_File] = []
    var isEditingMode = false
    var toolbar: UIToolbar!
    var downloadButton: UIBarButtonItem!
    var toolbarHeight: CGFloat = 35
    var currentFileIndex = 0
    var hasMore = false
    private var activityIndicatorViewFooter: UIActivityIndicatorView?
    
    @IBOutlet var viewLoading: UIView!
    @IBOutlet weak var activityIndicatorPhotoLib: UIActivityIndicatorView!
    @IBOutlet weak var lblVideosImported: UILabel!
    fileprivate var googleAPIs: GoogleDriveAPI?
    var sessionFetcherAuthorizer: GTMFetcherAuthorizationProtocol?
    var nextPageToken: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.setupView()
    }
    
    func setupView() {
        self.tblFileList.delegate = self
        self.tblFileList.dataSource = self
        self.tblFileList.register(UINib(nibName: "GoogleDriveCell", bundle: nil), forCellReuseIdentifier: "GoogleDriveCell")
        self.lblNoVideos.text = "Loading..."
        
        self.tblFileList.allowsMultipleSelectionDuringEditing = true
        self.setupSelectNavigationBarButtons()
        self.setupToolbar()
        if self.currentPath == GoogleDrive.kGoogleDriveRootFolder {
            self.fetchFileListFromGoogleDrive(root: GoogleDrive.kGoogleDriveRootFolder)
        }
    }
    
    func fetchFileListFromGoogleDrive(root: String) {
        let service = GTLRDriveService()
        service.authorizer = sessionFetcherAuthorizer
        self.googleAPIs = GoogleDriveAPI(service: service)
        
        if nextPageToken != nil {
            if activityIndicatorViewFooter == nil {
                // Create the activity indicator view when needed
                activityIndicatorViewFooter = UIActivityIndicatorView(style: .medium)
                activityIndicatorViewFooter?.frame = CGRect(x: 0, y: 0, width: tblFileList.bounds.width, height: 44)
                activityIndicatorViewFooter?.hidesWhenStopped = true
                activityIndicatorViewFooter?.color = UIColor.white
                tblFileList.tableFooterView = activityIndicatorViewFooter
            }
            
            // Start the activity indicator animation
            activityIndicatorViewFooter?.startAnimating()
        }
        
        self.googleAPIs?.listFiles(root, pageToken: nextPageToken, onCompleted: { result, error in
            if error == nil {
                if let filesList : GTLRDrive_FileList = result {
                    
                    self.activityIndicatorViewFooter?.stopAnimating()
                    
                    if let pageToken = filesList.nextPageToken {
                        self.hasMore = true
                        self.nextPageToken = pageToken
                    }
                    else {
                        self.hasMore = false
                        self.nextPageToken = nil
                    }
                    
                    var newfiles: [GTLRDrive_File] = []
                    if let filesShow : [GTLRDrive_File] = filesList.files {
                        for file in filesShow {
                            newfiles.append(file)
                        }
                    }
                    
                    self.files.append(contentsOf: newfiles)
                    
                    if self.files.isEmpty {
                        self.lblNoVideos.text = "There are no videos in this folder."
                        self.tblFileList.isHidden = true
                        self.lblNoVideos.isHidden = false
                    } else {
                        self.tblFileList.isHidden = false
                        self.lblNoVideos.isHidden = true
                    }
                    
                    DispatchQueue.main.async {
                        self.tblFileList.reloadData()
                    }
                }
            }
            else {
                print("Getting error: \(String(describing: error?.localizedDescription))")
            }
        })
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

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateToolbarPosition()
    }
    
    //MARK: - Setup multiple selection methods
    func setupSelectNavigationBarButtons() {
        let editButton = UIBarButtonItem(title: isEditingMode ? "Cancel" : "Select", style: .plain, target: self, action: #selector(toggleEditing))
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
            //selectedItems.removeAll()
            //selectedFiles.removeAll()
            
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
    
    //MARK: - Download files
    @objc func downloadSelectedItems() {
        print("Downloading selected items: \(selectedFiles)")
        self.startSequentialDownloads()
    }
    
    func startSequentialDownloads() {
        currentFileIndex = 0
        updateProgressLabel()
        downloadNextFile()
        showLoadingView()
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
        print("Downloading \(fileToDownload.name ?? "")")
        var fileName = ""
        if let url = URL(string: fileToDownload.name ?? "") {
            // Remove the file extension
            fileName = url.deletingPathExtension().lastPathComponent
            fileName = "\(fileName).\(fileToDownload.fileExtension ?? "")"
        }
        
        if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
            let destinationURL = directoryURL.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                self.currentFileIndex += 1
                self.updateProgressLabel()
                downloadNextFile() // File already exists, move to the next file
                return
            }
            
            let service = GTLRDriveService()
            service.authorizer = sessionFetcherAuthorizer
            self.googleAPIs = GoogleDriveAPI(service: service)
            
            self.googleAPIs?.download(fileToDownload, onCompleted: { data, error in
                if error == nil {
                    do {
                        // Write the data to the file
                        try data?.write(to: destinationURL)
                        CoreDataManager.shared.saveVideo(videoURL: destinationURL.lastPathComponent)
                        // File has been saved successfully
                        
                        print("File saved to document directory: \(destinationURL.path)")
                    } catch {
                        print("Error saving file: \(error.localizedDescription)")
                    }
                }
                else {
                    
                }
                
                self.currentFileIndex += 1
                self.updateProgressLabel()
                self.downloadNextFile() // Download next file after completion
            })
        }
    }
}


extension GoogleDriveViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //return 60.0
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GoogleDriveCell") as! GoogleDriveCell
        
        let file = self.files[indexPath.row]
        if let mimeType = file.mimeType {
            if mimeType == "application/vnd.google-apps.folder" {
                // It's a folder
                print("Folder: \(file.name ?? "")")
                cell.lblName.text = file.name
                cell.lblDetails.isHidden = true
                cell.lblNameTop.constant = 20.0
                cell.imgView.image = UIImage(named: "folder")
                
            } 
            else {
                // It's another type of file
                print("File: \(file.name ?? "")")
                cell.lblName.text = file.name
                let fileSize = ByteCountFormatter.string(fromByteCount: Int64(truncating: file.size ?? 0), countStyle: .file)
                cell.lblDetails.text = fileSize
                cell.lblDetails.isHidden = false
                cell.lblNameTop.constant = 10.0
                cell.imgView.image = UIImage(named: "movie")
            }
        }
        
        return cell
    }
    
    func encodeFolderPath(_ folder: String, currentPath path: String) -> String {
        return "\(path)/\(folder)"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = self.files[indexPath.row]
        if let mimeType = file.mimeType {
            if mimeType == "application/vnd.google-apps.folder" {
                if self.isEditingMode {
                    tableView.deselectRow(at: indexPath, animated: true)
                    return
                }
                
                if let folderID = file.identifier {
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "GoogleDriveViewController") as! GoogleDriveViewController
                    vc.title = file.name
                    vc.currentPath = folderID
                    vc.sessionFetcherAuthorizer = sessionFetcherAuthorizer
                    vc.fetchFileListFromGoogleDrive(root: folderID)
                    self.navigationController?.pushViewController(vc, animated: true)
                    tableView.deselectRow(at: indexPath, animated: true)
                }
            }
            else {
                if isEditingMode {
                    selectedItems.append(indexPath)
                    selectedFiles.append(self.files[indexPath.row])
                    updateButtonAndTitle()
                } else {
                    self.toggleEditing()
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    self.selectedItems.append(indexPath)
                    self.selectedFiles.append(self.files[indexPath.row])
                    self.updateButtonAndTitle()
                }
            }
        }
    }
    
    func updateButtonAndTitle() {
        updateSelectAllButtonTitle()
        printSelectedItems()
        updateToolbarPosition()
        updateDownloadButtonTitle()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == files.count - 1 && self.hasMore {
            self.hasMore = false
            self.fetchFileListFromGoogleDrive(root: self.currentPath)
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
