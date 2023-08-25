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
import PhotosUI

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
    
    //Import from Photo Lib outlets and variables
    @IBOutlet var viewPhotoLibLoading: UIView!
    @IBOutlet weak var activityIndicatorPhotoLib: UIActivityIndicatorView!
    @IBOutlet weak var lblLoadingPhotoLib: UILabel!
    @IBOutlet weak var progressPhotoLib: UIProgressView!
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    var totalProgress: Float = 0.0
    
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
        //self.setupMenuOptions()
        self.getAllClips()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.viewPhotoLibLoading.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.size.width, height: self.viewContainer.frame.size.height)
            self.viewContainer.addSubview(self.viewPhotoLibLoading)
            self.hidePhotoLibLoadingView()
        }
    }
    
    func showPhotoLibLoadingView() {
        self.viewPhotoLibLoading.isHidden = false
        
    }
    
    func hidePhotoLibLoadingView() {
        self.viewPhotoLibLoading.isHidden = true
    }
    
    func setupMenuOptions() {
        let PhotoLibrary = UIAction(title: "Photo Library", image: nil) { _ in
            self.presentPicker()
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
            self.viewContainerLeading.constant = 30
            self.viewContainerTrailing.constant = 30
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
        
        //Getting fav videos
        let wholeFavVideos = CoreDataManager.shared.getAllFavoriteVideos()
        var finalFavVideos: [VideoTable] = []
        for video in wholeFavVideos {
            let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(video.videoURL ?? "")

            if FileManager.default.fileExists(atPath: videoURL.path) {
                finalFavVideos.append(video)
            }
            else {
                CoreDataManager.shared.deleteVideo(videoURL: video.videoURL ?? "")
                let thumbURL = Utility.getDirectoryPath(folderName: DirectoryName.Thumbnails)!.appendingPathComponent(video.thumbnailURL ?? "")
                if FileManager.default.fileExists(atPath: thumbURL.path) {
                    try? FileManager.default.removeItem(at: thumbURL)
                }
            }
        }
        self.arrClips.append(contentsOf: finalFavVideos)
        
        //Getting clips
        let allClipse = CoreDataManager.shared.getAllClips()
        var finalClips: [VideoClip] = []
        for clip in allClipse {
            let clipURL = Utility.getDirectoryPath(folderName: DirectoryName.SavedClips)!.appendingPathComponent(clip.clipURL ?? "")
            if FileManager.default.fileExists(atPath: clipURL.path) {
                finalClips.append(clip)
            }
            else {
                CoreDataManager.shared.deleteClip(clipURL: clip.clipURL ?? "")
                let thumbURL = Utility.getDirectoryPath(folderName: DirectoryName.Thumbnails)!.appendingPathComponent(clip.thumbnailURL ?? "")
                if FileManager.default.fileExists(atPath: thumbURL.path) {
                    try? FileManager.default.removeItem(at: thumbURL)
                }
            }
        }
        print(finalClips.count)
        self.arrClips.append(contentsOf: finalClips)
        
        
        print(self.arrClips.count)
        self.tableViewClips.reloadData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.adjustPopupConstraints()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.viewPhotoLibLoading.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.size.width, height: self.viewContainer.frame.size.height)
        }
    }
    
    //MARK: - Import from Photo Lib
    private func presentPicker() {
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
            let clipName = "\(aClip.clipURL ?? "")"
            cell.lblClipName.text = (clipName as NSString).deletingPathExtension
                        
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
            let videoName = "\(vClip.videoURL ?? "")"
            cell.lblClipName.text = (videoName as NSString).deletingPathExtension
            
            let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(vClip.videoURL ?? "")
            let asset = AVAsset(url: videoURL)
            let duration = asset.duration
            let durationTime = CMTimeGetSeconds(duration)
            let formattedDuration = cell.formatTime(duration: durationTime)
            cell.lblDuration.text = formattedDuration
        }
        
        cell.btnPlay.tag = indexPath.row
        cell.btnPlay.addTarget(self, action: #selector(btnPlayAction), for: .touchUpInside)
        
        cell.btnShare.tag = indexPath.row
        cell.btnShare.addTarget(self, action: #selector(btnShareAction), for: .touchUpInside)
                
        return cell
    }
    
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
    
    @objc func btnShareAction(sender: UIButton) {
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
        if clipURL != nil {
            // Create an instance of UIActivityViewController
            let activityViewController = UIActivityViewController(activityItems: [clipURL!], applicationActivities: nil)
            // Present the UIActivityViewController
            present(activityViewController, animated: true, completion: nil)
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
        /*let renameAction = UIContextualAction(style: .normal, title: "Rename") { (action, view, completionHandler) in
            self.indexpathToRename = indexPath
            self.showAlertWithRenameTextField()
            completionHandler(true)
        }*/
        
        deleteAction.backgroundColor = .red
        //renameAction.backgroundColor = .blue
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Swipe-to-rename action
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { (action, view, completionHandler) in
            self.indexpathToRename = indexPath
            self.showAlertWithRenameTextField()
            completionHandler(true)
        }
        
        renameAction.backgroundColor = .blue
        
        let configuration = UISwipeActionsConfiguration(actions: [renameAction])
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
        let deleteAction = UIAlertAction(title: "Delete clip", style: .destructive) { _ in
            // Performing the delete action
            
            if let aClip = clip as? VideoClip {
                print("deleted clip: \(aClip.clipURL ?? "")")
                
                if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.SavedClips) {
                    
                    let destinationURL = directoryURL.appendingPathComponent(aClip.clipURL ?? "")
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try? FileManager.default.removeItem(at: destinationURL)
                        CoreDataManager.shared.updateClipIsDeleted(clipURL: "\(aClip.clipURL ?? "")")
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

extension ManageVideosViewController: PHPickerViewControllerDelegate {
    /// - Tag: ParsePickerResults
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true, completion: {
            
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
                    self.showPhotoLibLoadingView()
                    self.progressPhotoLib.isHidden = false
                    self.totalProgress = 0.0
                    self.lblLoadingPhotoLib.isHidden = false
                    self.lblLoadingPhotoLib.text = "Loading \(self.selectedAssetIdentifiers.count) videos"
                    self.activityIndicatorPhotoLib.isHidden = false
                    self.activityIndicatorPhotoLib.startAnimating()
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
            self.hidePhotoLibLoadingView()
            self.showNewVideoImportedToast()
        })
    }

    func copyVideoFileToDocumentDirectory(url: URL) {
        do {
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
                
                let destinationURL = directoryURL.appendingPathComponent(url.lastPathComponent)
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    return
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
        self.progressPhotoLib.progress = progress
    }
    
    func showNewVideoImportedToast() {
        let config = ToastConfiguration(
            direction: .top,
            autoHide: true,
            enablePanToClose: true,
            displayTime: 3,
            animationTime: 0.2
        )
        let toast = Toast.text("New videos imported successfully", config: config)
        toast.show(haptic: .success)
    }
}
