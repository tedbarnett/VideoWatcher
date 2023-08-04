//
//  ImportFromFilesViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 04/08/23.
//

import UIKit
import Photos

class ImportFromFilesViewController: UIViewController {

    @IBOutlet weak var btnImport: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }
    
    func setupUI() {
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
        self.presentFilePicker()
    }
    
    private func presentFilePicker() {
        let supportedTypes: [UTType] = [UTType.movie, UTType.video]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        self.gotoVideoWatcherController()
    }

    func gotoVideoWatcherController() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoWatcherViewController") as! VideoWatcherViewController
            //vc.videosArray = self.videosArray // Pass the videosArray to the next view controller
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ImportFromFilesViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if urls.count > 0 {
            for url in urls {
                if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
                    do {
                        let _ = url.startAccessingSecurityScopedResource()
                        let destinationURL = directoryURL.appendingPathComponent(url.lastPathComponent)
                        
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try? FileManager.default.removeItem(at: destinationURL)
                            CoreDataManager.shared.deleteVideo(videoURL: destinationURL.lastPathComponent)
                        }
                        
                        try FileManager.default.copyItem(at: url, to: destinationURL) //Copy videos from Files or iCloud drive to app's document directory
                        CoreDataManager.shared.saveVideo(videoURL: destinationURL.lastPathComponent)
                        
                        url.stopAccessingSecurityScopedResource()
                        print("Video copied to document directory: \(destinationURL)")
                    } catch {
                        print("Error saving video: \(error)")
                    }
                }
            }
            controller.dismiss(animated: true, completion: {})
            
            gotoVideoWatcherController()
        }
    }
    
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//
//        if urls.count > 0 {
//            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
//
//                for url in urls {
//                    do {
//                        let _ = url.startAccessingSecurityScopedResource()
//                        let destinationURL = directoryURL.appendingPathComponent(url.lastPathComponent)
//
//                        if FileManager.default.fileExists(atPath: destinationURL.path) {
//                            try? FileManager.default.removeItem(at: destinationURL)
//                            CoreDataManager.shared.deleteVideo(videoURL: destinationURL.lastPathComponent)
//                        }
//                        CoreDataManager.shared.saveVideo(videoURL: destinationURL.lastPathComponent)
//                        try FileManager.default.copyItem(at: url, to: destinationURL) //Copy videos from Files or iCloud drive to app's document directory
//
//                        url.stopAccessingSecurityScopedResource()
//                        print("Video copied to document directory: \(destinationURL)")
//                        let allVideos = CoreDataManager.shared.getAllVideos()
//                        for video in allVideos {
//                            print("Video URL from COREDATA: \(video.videoURL ?? "N/A")")
//                        }
//                    } catch {
//                        print("Error saving video: \(error)")
//                    }
//                }
//                controller.dismiss(animated: true, completion: {})
//                //self.gotoVideoWatcherController()
//            }
//        }
//    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        //self.gotoVideoWatcherController()
    }
}

extension FileManager {
    func fileExists(atURL url: URL) -> Bool {
        var path: String
        if #available(iOS 16.0, *) {
            path = url.path(percentEncoded: false)
        } else {
            path = url.path
        }

        return FileManager.default.fileExists(atPath: path)
    }
}
