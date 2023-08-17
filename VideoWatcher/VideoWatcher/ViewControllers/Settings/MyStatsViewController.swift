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
        self.title = "My Stats"
        self.setupRightMenuButton()
        
        self.tblMyStats.delegate = self
        self.tblMyStats.dataSource = self
        self.tblMyStats.register(UINib(nibName: "MyStatTableViewCell", bundle: nil), forCellReuseIdentifier: "MyStatTableViewCell")
        self.tblMyStats.contentInset =  UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        self.getMinutes()
    }
    
    func setupRightMenuButton() {
        let closeButton = UIButton(type: .system)
        closeButton.tintColor = .white
        closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
    }
    
    @objc func closeButtonTapped() {
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
