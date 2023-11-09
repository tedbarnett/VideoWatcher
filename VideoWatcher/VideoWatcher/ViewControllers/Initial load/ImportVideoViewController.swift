//
//  ImportVideoViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 04/08/23.
//

import UIKit
import AVFoundation
import AVKit
import PhotosUI
import SwiftyDropbox
import GoogleSignIn
import GoogleAPIClientForREST_Drive

protocol ImportVideoViewControllerDelegate: AnyObject {
    func startAllPanelFromImport()
}

class ImportVideoViewController: UIViewController {

    weak var delegate: ImportVideoViewControllerDelegate?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblLoading: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var viewLoadingContainer: UIView!
    @IBOutlet var viewLoading: UIView!
    @IBOutlet weak var btnPlayVideos: UIButton!
    @IBOutlet weak var lblCenterText: UILabel!
    @IBOutlet weak var lblCenterTextWidth: NSLayoutConstraint!
    @IBOutlet weak var lblCenterTextHeight: NSLayoutConstraint!
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    var totalProgress: Float = 0.0
    var isFromVideoPanel = false
    @IBOutlet weak var tblVideoList: UITableView!
    var arrVideos: [VideoTable] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    let fileManager = FileManager.default
    fileprivate var googleAPIs: GoogleDriveAPI?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
    }
    
    func setupView() {
        self.btnPlayVideos.layer.cornerRadius = self.btnPlayVideos.bounds.size.height / 2
        self.btnPlayVideos.layer.borderWidth = 1
        self.btnPlayVideos.layer.borderColor = UIColor(red: 61.0/255.0, green: 104.0/255.0, blue: 170.0/255.0, alpha: 1.0).cgColor
        self.btnPlayVideos.layer.masksToBounds = true
        self.btnPlayVideos.isHidden = true
        self.setupRightMenuButton()
        
        self.tblVideoList.delegate = self
        self.tblVideoList.dataSource = self
        self.tblVideoList.register(UINib(nibName: "VideoListCell", bundle: nil), forCellReuseIdentifier: "VideoListCell")
        
        if isFromVideoPanel {
            self.lblCenterText.text = "To add new videos for you to review, add videos from your Apple Photo library, or from Google Drive, or Dropbox. Click the \"+\" sign above to start that process."
        }
        else {
            //self.lblCenterText.text = "Welcome to VideoWatcher!\n\nTo start, add videos from any of these sources:\nApple Photos, Google Drive, or Dropbox.\n\nClick the \"+\" sign above to begin this process."
            let attributedString = NSMutableAttributedString(string: "Welcome to VideoWatcher!\n\nTo start, add videos from any of these sources:\nApple Photos, Google Drive, or Dropbox.\n\nClick the \"+\" sign above to begin this process.")
            let fontSize: CGFloat = 26 // Adjust the font size as needed
            let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            let range = (attributedString.string as NSString).range(of: "Welcome to VideoWatcher!")
            attributedString.addAttribute(.font, value: font, range: range)
            self.lblCenterText.attributedText = attributedString
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(getDropboxVideos), name: Notification.Name("UserLoggedInDropbox"), object: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.lblCenterTextHeight.constant = 150
            self.lblCenterTextWidth.constant = 350
        }
        
        if isFromVideoPanel == true {
            self.tblVideoList.isHidden = true
            self.viewLoadingContainer.isHidden = true
            self.lblCenterText.isHidden = true
            self.btnPlayVideos.isHidden = true
            
            self.getAllVideos()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFromVideoPanel == false {
            let videos = CoreDataManager.shared.getRandomVideos(count: 1)
            if videos.count > 0 {
                self.moveItemsToImportedVideos()
                self.copyBlankVideoFromBundleToImportedVideos()
                self.saveVideosInCoredata()
            }
            else {
                self.moveItemsToImportedVideos()
                self.copyBlankVideoFromBundleToImportedVideos()
                self.saveVideosInCoredata()
            }
        }
    }
    
    func getAllVideos() {
        self.arrVideos.removeAll()
        self.arrVideos = CoreDataManager.shared.getAllVideos()
        self.arrVideos.sort { ($0.videoURL ?? "") < ($1.videoURL ?? "") }
                
        if self.arrVideos.count > 0 {
            self.showVideoList()
            DispatchQueue.main.async {
                self.tblVideoList.reloadData()
            }
        }
        else {
            self.hideVideoList()
        }
    }
    
    func showVideoList() {
        self.tblVideoList.isHidden = false
        self.viewLoadingContainer.isHidden = true
        self.lblCenterText.isHidden = true
        self.btnPlayVideos.isHidden = true
    }
    
    func hideVideoList() {
        self.tblVideoList.isHidden = true
        self.viewLoadingContainer.isHidden = false
        self.lblCenterText.isHidden = false
        self.btnPlayVideos.isHidden = false
    }
    
    func moveItemsToImportedVideos() {
        do {
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
                let directoryContents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
                
                for itemUrl in directoryContents {
                    //0 Get the lowercase path extension
                    let itemPathExtension = itemUrl.pathExtension.lowercased()
                    
                    // Check if the item is a video file based on its file extension
                    let videoExtensions = ["mp4", "mov", "avi", "flv", "wmv", "mkv"]
                    if videoExtensions.contains(itemPathExtension) {
                        if CoreDataManager.shared.isVideoExists(videoURL: itemUrl.lastPathComponent) == false {
                            print("Saved Item: \(itemUrl.lastPathComponent)")
                            if itemUrl.lastPathComponent == "Blank.mp4" {
                                CoreDataManager.shared.saveBlankVideo(videoURL: itemUrl.lastPathComponent)
                            } else {
                                CoreDataManager.shared.saveVideo(videoURL: itemUrl.lastPathComponent)
                            }
                        } else {
                            print("Already saved: \(itemUrl.lastPathComponent)")
                        }
                    } else {
                        // This is not a video file
                        print("Not a video file: \(itemUrl.lastPathComponent)")
                    }
                }
                let videos = CoreDataManager.shared.getRandomVideos(count: 1)
                if videos.count > 0 {
                    self.gotoVideoWatcher()
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func copyBlankVideoFromBundleToImportedVideos() {
        // Step 1: Locate the video file in the app's bundle
        guard let videoURLInBundle = Bundle.main.url(forResource: "Blank", withExtension: "mp4") else {
            print("Video file not found in the bundle.")
            return
        }
        
        // Step 2: Get the path to the document directory
        guard let documentDirectoryUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let importedVideosDirectoryUrl = documentDirectoryUrl.appendingPathComponent(DirectoryName.ImportedVideos)
        
        // Set the destination URL in the document directory
        let destinationURL = importedVideosDirectoryUrl.appendingPathComponent("Blank.mp4")
        
        // Check if the video file already exists at the destination path
        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
                // Step 3: Copy the video file to the document directory
                try FileManager.default.copyItem(at: videoURLInBundle, to: destinationURL)
                self.saveVideosInCoredata()
                print("Video file copied to the document directory.")
            } catch {
                print("Error copying video file: \(error)")
            }
        } else {
            print("Video file already exists in the document directory. No need to copy.")
        }
    }
    
    func saveVideosInCoredata() {
        // Get the URL for the ImportedVideos dir
        do {
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
                let directoryContents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
                
                for itemUrl in directoryContents {
                    if CoreDataManager.shared.isVideoExists(videoURL: itemUrl.lastPathComponent) == false {
                        print("Saved Item: \(itemUrl.lastPathComponent)")
                        if itemUrl.lastPathComponent == "Blank.mp4" {
                            CoreDataManager.shared.saveBlankVideo(videoURL: itemUrl.lastPathComponent)
                        }
                        else {
                            CoreDataManager.shared.saveVideo(videoURL: itemUrl.lastPathComponent)
                        }
                    }
                    else {
                        print("Already saved: \(itemUrl.lastPathComponent)")
                    }
                }
                let videos = CoreDataManager.shared.getRandomVideos(count: 1)
                if videos.count > 0 {
                    self.gotoVideoWatcher()
                }
            }
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    func setupRightMenuButton() {
        if isFromVideoPanel == true {
            let closeButton = UIButton(type: .custom)
            closeButton.tintColor = .white
            closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
            let closeBarButtonItem = UIBarButtonItem(customView: closeButton)
            navigationItem.leftBarButtonItem = closeBarButtonItem
        }

        self.viewLoadingContainer.isHidden = true
        
        let btnPlus = UIButton(type: .system)
        btnPlus.tintColor = .white
        btnPlus.setImage(UIImage(systemName: "plus"), for: .normal)
        let PlusBarButtonItem = UIBarButtonItem(customView: btnPlus)
        let barButtonItems: [UIBarButtonItem] = [PlusBarButtonItem]
        navigationItem.rightBarButtonItems = barButtonItems
        
        let PhotoLibrary = UIAction(title: "Photo Library", image: nil) { _ in
            self.presentPhotoPicker()
        }
        
        let GoogleDrive = UIAction(title: "Google Drive", image: nil) { _ in
            
            if let authorizer = GIDSignIn.sharedInstance.currentUser?.fetcherAuthorizer {
                print("Already signed in")
                self.openGoogleDriveVideoList(sessionFetcherAuthorizer: authorizer)
            }
            else {
                GIDSignIn.sharedInstance.signIn(withPresenting: self, hint: "DONTKNOW", additionalScopes: [kGTLRAuthScopeDrive]) { result, error in
                    if error == nil {
                        print(result as Any)
                        print("Authenticate successfully")
                        self.openGoogleDriveVideoList(sessionFetcherAuthorizer: (result?.user.fetcherAuthorizer)!)
                    }
                    else {
                        print("Getting error: \(String(describing: error?.localizedDescription))")
                    }
                }
            }
        }
        
        let Dropbox = UIAction(title: "Dropbox", image: nil) { _ in
            if DropboxClientsManager.authorizedClient != nil {
                print("Already authorized 1")
                self.openDropboxVideoList()
            }
            else {
                DropboxClientsManager.authorizeFromControllerV2(
                    UIApplication.shared,
                    controller: self,
                    loadingStatusDelegate: nil,
                    openURL: {(url: URL) -> Void in UIApplication.shared.open(URL(string: "\(url)")!)},
                    scopeRequest: ScopeRequest(scopeType: .user,
                                               scopes: ["files.metadata.read",
                                                        "files.content.read",
                                                        "files.content.write",
                                                        "account_info.read"],
                                               includeGrantedScopes: true))
            }
        }
        
        btnPlus.overrideUserInterfaceStyle = .dark
        btnPlus.showsMenuAsPrimaryAction = true
        btnPlus.menu = UIMenu(title: "Import from", children: [PhotoLibrary, GoogleDrive, Dropbox])
    }
    
    @objc private func getDropboxVideos(notification: NSNotification){
        if DropboxClientsManager.authorizedClient != nil {
            print("Already authorized 2")
            self.openDropboxVideoList()
        }
    }
    
    func openGoogleDriveVideoList(sessionFetcherAuthorizer: GTMFetcherAuthorizationProtocol) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "GoogleDriveViewController") as! GoogleDriveViewController
        vc.title = "Google Drive"
        vc.sessionFetcherAuthorizer = sessionFetcherAuthorizer
        vc.currentPath = GoogleDrive.kGoogleDriveRootFolder
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openDropboxVideoList() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "DropboxViewController") as! DropboxViewController
        vc.title = "Dropbox"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func closeButtonTapped() {
        if delegate != nil {
            self.delegate?.startAllPanelFromImport()
        }
        self.dismiss(animated: true)
    }
    
    @IBAction func btnPlayVideoAction(_ sender: Any) {
        self.gotoVideoWatcher()
    }
    
    func gotoVideoWatcher() {
        DispatchQueue.main.async {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoWatcherViewController") as! VideoWatcherViewController
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    func gotoVideoSelection() {
        DispatchQueue.main.async {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImportFromPhotoLibraryViewController") as! ImportFromPhotoLibraryViewController
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    func showLoadingView() {
        self.viewLoadingContainer.isHidden = false
    }
    
    func hideLoadingView() {
        self.totalProgress = 0.0
        self.progress.progress = 0.0
        self.activityIndicator.stopAnimating()
        self.viewLoadingContainer.isHidden = true
        if isFromVideoPanel == false {
            self.btnPlayVideos.isHidden = false
        }
        self.showToast(message: "Loaded \(self.selectedAssetIdentifiers.count) videos from Photo Library")
    }
    
    func showToast(message: String) {
        let config = ToastConfiguration(
            direction: .top,
            autoHide: true,
            enablePanToClose: true,
            displayTime: 2,
            animationTime: 0.2
        )
        let toast = Toast.text(message, config: config)
        toast.show(haptic: .success)
    }
    
    //MARK: - Import from Photo Lib
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        
        // Set the filter type according to the user’s selection.
        configuration.filter = .videos
        // Set the mode to avoid transcoding, if possible, if your app supports arbitrary image/video encodings.
        configuration.preferredAssetRepresentationMode = .current
        // Set the selection behavior to respect the user’s selection order.
        configuration.selection = .default//.ordered
        // Set the selection limit to enable multiselection.
        configuration.selectionLimit = 0
        // Set the preselected asset identifiers with the identifiers that the app tracks.
        configuration.preselectedAssetIdentifiers = selectedAssetIdentifiers
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    deinit {
      NotificationCenter.default.removeObserver(self, name: Notification.Name("UserLoggedInDropbox"), object: nil)
    }
}

extension ImportVideoViewController: PHPickerViewControllerDelegate {
    /// - Tag: ParsePickerResults
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true, completion: {
            //self.btnImport.isEnabled = false
            
            let existingSelection = self.selection
            var newSelection = [String: PHPickerResult]()
            for result in results {
                let identifier = result.assetIdentifier!
                newSelection[identifier] = existingSelection[identifier] ?? result
            }
            
            // Track the selection in case the user deselects it later.
            self.selection = newSelection
            self.selectedAssetIdentifiers = results.map(\.assetIdentifier!)
            self.selectedAssetIdentifierIterator = self.selectedAssetIdentifiers.makeIterator()
            
            if self.selectedAssetIdentifiers.count > 0 {
                DispatchQueue.main.async {
                    self.showLoadingView()
                    self.lblLoading.text = "Loading \(self.selectedAssetIdentifiers.count) videos"
                    self.activityIndicator.startAnimating()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.copyVideosToDocumentDirectory()
                }
            }
        })
    }
    
    func copyVideosToDocumentDirectory() {
        let group = DispatchGroup()
        
        for assetIdentifier in selectedAssetIdentifiers {
            if let result = selection[assetIdentifier] {
                let itemProvider = result.itemProvider
                
                if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                        
                        self?.totalProgress += 1
                        if let url = url, error == nil {
                            self?.copyVideoFileToDocumentDirectory(url: url)
                        } else if let error = error {
                            print("Error loading video file: \(error)")
                        }
                        DispatchQueue.main.async {
                            self?.updateProgressBar()
                        }
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main, execute: { // executed after all async calls in for loop finish
            print("done with all async calls")
            self.lblLoading.isHidden = true
            self.progress.isHidden = true
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            //self.btnNext.isEnabled = true
            self.hideLoadingView()
            if self.isFromVideoPanel == true {
                self.getAllVideos()
            }
            //self.gotoImportFromFileVC()
        })
    }

    func copyVideoFileToDocumentDirectory(url: URL) {
        do {
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
                
                let destinationURL = directoryURL.appendingPathComponent(url.lastPathComponent)
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    if isFromVideoPanel == false {
                        try? FileManager.default.removeItem(at: destinationURL)
                        CoreDataManager.shared.deleteVideo(videoURL: destinationURL.lastPathComponent)
                    }
                    else {
                        return
                    }
                }
                
                try FileManager.default.copyItem(at: url, to: destinationURL) //Copy videos from Files or iCloud drive to app's document directory
                CoreDataManager.shared.saveVideo(videoURL: destinationURL.lastPathComponent)
                print("Video copied to document directory: \(destinationURL)")
                /*let allVideos = CoreDataManager.shared.getAllVideos()
                for video in allVideos {
                    print("Video URL from COREDATA: \(video.videoURL ?? "N/A")")
                }*/
            }
        }
        catch {
            print("Error copying video: \(error)")
        }
    }
    
    func updateProgressBar() {
        let progress = self.totalProgress / Float(self.selectedAssetIdentifiers.count)
        print("Progress: \(progress)")
        self.progress.progress = progress
    }
}

extension ImportVideoViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 57
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrVideos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoListCell") as! VideoListCell
        
        let video = self.arrVideos[indexPath.row]
        let thumbURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(video.videoURL ?? "")
        
        //cell.imgThumb.kf.setImage(with: thumbURL)
        let videoName = "\(video.videoURL ?? "")"
        cell.lblClipName.text = (videoName as NSString).deletingPathExtension
        
        cell.imgThumb.image = cell.getVideoThumbnail(url: thumbURL)
        
        let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(video.videoURL ?? "")
        let asset = AVAsset(url: videoURL)
        let duration = asset.duration
        let durationTime = CMTimeGetSeconds(duration)
        let formattedDuration = cell.formatTime(duration: durationTime)
        cell.lblDuration.text = formattedDuration
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Swipe-to-delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            self.showDeleteConfirmation(indexPath: indexPath)
            completionHandler(true)
        }
        deleteAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    //Delete clip
    @objc func showDeleteConfirmation(indexPath: IndexPath) {
        let alertController = UIAlertController(
            title: "Delete video",
            message: "Are you sure you want to delete this video?",
            preferredStyle: .actionSheet
        )
        
        let video = self.arrVideos[indexPath.row]
        let deleteAction = UIAlertAction(title: "Delete clip", style: .destructive) { _ in
            // Performing the delete action
            print("deleted video: \(video.videoURL ?? "")")
            
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
                let destinationURL = directoryURL.appendingPathComponent(video.videoURL ?? "")
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try? FileManager.default.removeItem(at: destinationURL)
                    CoreDataManager.shared.deleteVideo(videoURL: video.videoURL ?? "")
                    self.arrVideos.remove(at: indexPath.row)
                }
            }
            self.tblVideoList.deleteRows(at: [indexPath], with: .automatic)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = self.arrVideos[indexPath.row]
        self.moveToFullScreen(videoAsset: video)
    }
    
    func moveToFullScreen(videoAsset: VideoTable) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "FullscreenVideoViewController") as! FullscreenVideoViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .crossDissolve
        navController.navigationBar.isHidden = true
        
        vc.currentTime = .zero
        vc.isMuted = false
        vc.videoAsset = videoAsset
        
        self.present(navController, animated: true)
    }
}
