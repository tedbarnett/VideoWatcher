//
//  MyStatsViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 17/08/23.
//

import UIKit
import AVFoundation

protocol MyStatsViewControllerDelegate: AnyObject {
    func startAllPanelAgain()
}

class MyStatsViewController: UIViewController {

    weak var delegate: MyStatsViewControllerDelegate?
    @IBOutlet weak var tblMyStats: UITableView!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var viewContainerLeading: NSLayoutConstraint!
    @IBOutlet weak var viewContainerTrailing: NSLayoutConstraint!
    @IBOutlet weak var viewContainerTop: NSLayoutConstraint!
    @IBOutlet weak var viewContainerBottom: NSLayoutConstraint!
    
    //"Minutes watched (across all 6 panels)"
    var arrTitle = ["Total video minutes", "Total favorite video minutes", "Minutes deleted"]
    var totalVideoMinutes = 0
    var totalFavoriteVideoMinutes = 0
    var totalMinutesDeleted = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }
    
    func setupUI() {
        self.adjustPopupConstraints()
        self.viewContainer.layer.cornerRadius = 10.0
        self.viewContainer.layer.masksToBounds = true

        self.tblMyStats.delegate = self
        self.tblMyStats.dataSource = self
        self.tblMyStats.register(UINib(nibName: "MyStatTableViewCell", bundle: nil), forCellReuseIdentifier: "MyStatTableViewCell")
        self.tblMyStats.contentInset =  UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        self.getMinutes()
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        self.delegate?.startAllPanelAgain()
        self.dismiss(animated: true)
    }
    
    func getMinutes() {
        
        ///Total Videos minutes
        var videosURLs: [URL] = []
        let videoAssets = CoreDataManager.shared.getAllVideosExceptDeleted()
        for videoAsset in videoAssets {
            let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(videoAsset.videoURL ?? "")
            videosURLs.append(videoURL)
        }
        self.totalVideoMinutes = self.calculateTotalVideoDuration(videoURLs: videosURLs)
        
        ///Total Favorite minutes
        var favVideosURLs: [URL] = []
        let favVideoAssets = CoreDataManager.shared.getAllFavoriteVideos()
        for videoAsset in favVideoAssets {
            let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(videoAsset.videoURL ?? "")
            favVideosURLs.append(videoURL)
        }
        let totalFavMinutes = self.calculateTotalVideoDuration(videoURLs: favVideosURLs)
        
        ///Total Favorite clips minutes
        var clipURLs: [URL] = []
        let clips = CoreDataManager.shared.getAllClips()
        for clip in clips {
            let clipURL = Utility.getDirectoryPath(folderName: DirectoryName.SavedClips)!.appendingPathComponent(clip.clipURL ?? "")
            clipURLs.append(clipURL)
        }
        let totalClipMinutes = self.calculateTotalVideoDuration(videoURLs: clipURLs)
        
        self.totalFavoriteVideoMinutes = totalFavMinutes + totalClipMinutes
        
        ///Total videos minutes deleted
        var deletedVideosURLs: [URL] = []
        let deletedVideoAssets = CoreDataManager.shared.getDeletedVideos()
        for videoAsset in deletedVideoAssets {
            let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(videoAsset.videoURL ?? "")
            deletedVideosURLs.append(videoURL)
        }
        let totalDeletedVideoMinutes = self.calculateTotalVideoDuration(videoURLs: deletedVideosURLs)
        
        ///Total clips minutes deleted
        var deletedClipURLs: [URL] = []
        let deletedClips = CoreDataManager.shared.getDeletedClips()
        for clip in deletedClips {
            let clipURL = Utility.getDirectoryPath(folderName: DirectoryName.SavedClips)!.appendingPathComponent(clip.clipURL ?? "")
            deletedClipURLs.append(clipURL)
        }
        let totalDeletedClipMinutes = self.calculateTotalVideoDuration(videoURLs: deletedClipURLs)
        
        self.totalMinutesDeleted = totalDeletedVideoMinutes + totalDeletedClipMinutes
        
        self.tblMyStats.reloadData()
    }
    
    private func calculateTotalVideoDuration(videoURLs: [URL]) -> Int {
        var totalSeconds: Double = 0
        
        for url in videoURLs {
            let asset = AVURLAsset(url: url)
            let duration = asset.duration.seconds
            print("duration: \(duration)")
            totalSeconds += duration
        }
        
        let totalMinutes = Int(round(totalSeconds / 60))
        return totalMinutes
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.adjustPopupConstraints()
    }
}

extension MyStatsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrTitle.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 71
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyStatTableViewCell") as! MyStatTableViewCell
        cell.lblTitle.text = self.arrTitle[indexPath.row]
        
        if indexPath.row == 0 {
            cell.lblMinutes.text = "\(self.totalVideoMinutes) Minutes"
        }
        else if indexPath.row == 1 {
            cell.lblMinutes.text = "\(self.totalFavoriteVideoMinutes) Minutes"
        }
        else if indexPath.row == 2 {
            cell.lblMinutes.text = "\(self.totalMinutesDeleted) Minutes"
        }
        else {
            cell.lblMinutes.text = "Remaining..."
        }
        
        return cell
    }
}
