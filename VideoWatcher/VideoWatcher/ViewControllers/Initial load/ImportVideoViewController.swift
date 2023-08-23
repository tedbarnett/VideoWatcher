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

protocol ImportVideoViewControllerDelegate: AnyObject {
    func startAllPanelFromImport()
}

class ImportVideoViewController: UIViewController {

    weak var delegate: ImportVideoViewControllerDelegate?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblLoading: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet var viewLoading: UIView!
    @IBOutlet weak var btnPlayVideos: UIButton!
    @IBOutlet weak var lblCenterText: UILabel!
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    var totalProgress: Float = 0.0
    var isFromVideoPanel = false
    
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
        
        if isFromVideoPanel {
            self.lblCenterText.text = "To add new videos for you to review, add videos from your Apple Photo library, or from Google Drive, or Dropbox. Click the \"+\" sign above to start that process."
        }
        else {
            self.lblCenterText.text = "Welcome to VideoWatcher. To start, add videos from your Apple Photo library, or from Google Drive or Dropbox. Click the \"+\" sign above to start that process."
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
               
        if isFromVideoPanel == false {
            let videos = CoreDataManager.shared.getRandomVideos(count: 1)
            if videos.count > 0 {
                self.gotoVideoWatcher()
            }
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

        self.viewLoading.isHidden = true
        
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
            
        }
        
        let Dropbox = UIAction(title: "Dropbox", image: nil) { _ in
            
        }
        
        btnPlus.overrideUserInterfaceStyle = .dark
        btnPlus.showsMenuAsPrimaryAction = true
        btnPlus.menu = UIMenu(title: "Import from", children: [PhotoLibrary, GoogleDrive, Dropbox])
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
        self.viewLoading.isHidden = false
    }
    
    func hideLoadingView() {
        self.totalProgress = 0.0
        self.progress.progress = 0.0
        self.activityIndicator.stopAnimating()
        self.viewLoading.isHidden = true
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
