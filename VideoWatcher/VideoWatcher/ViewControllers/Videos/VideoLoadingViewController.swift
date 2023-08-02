//
//  VideoLoadingViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 01/08/23.
//

import UIKit
import Photos

class VideoLoadingViewController: UIViewController {

    @IBOutlet weak var lblTotalLoading: UILabel!
    var videosArray: [Any] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
            
        self.checkPhotoLibraryPermission()
    }
    
    func checkPhotoLibraryPermission() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            // Permission already granted
            self.fetchVideosFromPhotoLibrary()
        case .notDetermined:
            // Request photo library access
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                if status == .authorized {
                    // Permission granted, fetch videos
                    self?.fetchVideosFromPhotoLibrary()
                } else {
                    // Permission denied
                    self?.permissionDeniedAlert()
                }
            }
        case .denied, .restricted:
            self.permissionDeniedAlert()
            break
            
        case .limited:
            break
            
        @unknown default:
            break
        }
    }
    
    func permissionDeniedAlert() {
        let alert = UIAlertController(title: "Allow access to your photos", message: "This lets you share from your camera roll and enables features for the videos. Go to settings and tap \"Photos\".", preferredStyle: .alert)
        
        let notNowAction = UIAlertAction(title: "Not Now",
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(notNowAction)
        
        let openSettingsAction = UIAlertAction(title: "Open Settings",
                                               style: .default) { [unowned self] (_) in
            // Open app privacy settings
            self.gotoAppPrivacySettings()
        }
        alert.addAction(openSettingsAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func gotoAppPrivacySettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            assertionFailure("Not able to open App privacy settings")
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func fetchVideosFromPhotoLibrary() { // Using PHAsset and PHAssetCollection to fetch videos from the photo library
    
        let fetchResults = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: nil)
                
        DispatchQueue.main.async {
            if fetchResults.count > 0 {
                self.lblTotalLoading.text = "Loading \(fetchResults.count) videos..."
            }
            else {
                self.lblTotalLoading.text = "No videos were found on this device"
            }
        }
        
        fetchResults.enumerateObjects { asset, count, stop in
            self.videosArray.append(asset)
            // Check if all assets have been enumerated and it's the last asset
            
            if fetchResults.count == self.videosArray.count {
                // Navigate to the next view controller
                DispatchQueue.main.async {
                    /*let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoWatcherViewController") as! VideoWatcherViewController
                    vc.videosArray = videosArray // Pass the videosArray to the next view controller
                    self.navigationController?.pushViewController(vc, animated: true)*/
                }
            }
        }
    }
    
    func gotoVideoWatcherController() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoWatcherViewController") as! VideoWatcherViewController
            vc.videosArray = self.videosArray // Pass the videosArray to the next view controller
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func btnImportFromFilesAction(_ sender: Any) {
        let supportedTypes: [UTType] = [UTType.movie, UTType.video]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        self.present(documentPicker, animated: true, completion: nil)
    }
    
}

extension VideoLoadingViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if urls.count > 0 {
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideoFromFilesAndiCloud) {
                
                for url in urls {
                    do {
                        let _ = url.startAccessingSecurityScopedResource()
                        let destinationURL = directoryURL.appendingPathComponent(url.lastPathComponent)
                        try FileManager.default.copyItem(at: url, to: destinationURL) //Copy videos from Files or iCloud drive to app's document directory
                        self.videosArray.append(destinationURL)
                        url.stopAccessingSecurityScopedResource()
                        print("Video saved to: \(destinationURL)")
                    } catch {
                        print("Error saving video: \(error)")
                    }
                }
                controller.dismiss(animated: true, completion: {})
                self.gotoVideoWatcherController()
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.gotoVideoWatcherController()
    }
}
