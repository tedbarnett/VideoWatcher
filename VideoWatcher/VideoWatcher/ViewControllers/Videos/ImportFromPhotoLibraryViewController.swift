//
//  ImportFromPhotoLibraryViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 04/08/23.
//

import UIKit
import PhotosUI

class ImportFromPhotoLibraryViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblLoading: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var btnImport: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    var totalProgress: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }
    
    func setupUI() {
        self.progress.isHidden = true
        self.lblLoading.isHidden = true
        self.activityIndicator.isHidden = true
        self.btnNext.isEnabled = false
        
        self.borderAndCornerRadius(view: self.btnImport)
        self.borderAndCornerRadius(view: self.btnNext)
    }
    
    func borderAndCornerRadius(view: UIView) {
        view.layer.cornerRadius = view.bounds.size.height / 2
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red: 61.0/255.0, green: 104.0/255.0, blue: 170.0/255.0, alpha: 1.0).cgColor
        view.layer.masksToBounds = true
    }
    
    @IBAction func btnImportAction(_ sender: Any) {
        self.presentPicker()
    }
    
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
    
    @IBAction func btnNextAction(_ sender: Any) {
        self.gotoImportFromFileVC()
    }
    
    func gotoImportFromFileVC() {
        DispatchQueue.main.async {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImportFromFilesViewController") as! ImportFromFilesViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ImportFromPhotoLibraryViewController: PHPickerViewControllerDelegate {
    /// - Tag: ParsePickerResults
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true, completion: {
            self.btnImport.isEnabled = false
            
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
                    self.progress.isHidden = false
                    self.totalProgress = 0.0
                    self.lblLoading.isHidden = false
                    self.lblLoading.text = "Loading \(self.selectedAssetIdentifiers.count) videos"
                    self.activityIndicator.isHidden = false
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
            self.btnNext.isEnabled = true
            
            self.gotoImportFromFileVC()
        })
    }

    func copyVideoFileToDocumentDirectory(url: URL) {
        do {
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
                
                let destinationURL = directoryURL.appendingPathComponent(url.lastPathComponent)
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try? FileManager.default.removeItem(at: destinationURL)
                    CoreDataManager.shared.deleteVideo(videoURL: destinationURL.lastPathComponent)
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
