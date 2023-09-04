//
//  ViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 01/08/23.
//

import UIKit
import Photos

class VideoWatcherViewController: UIViewController {

    @IBOutlet weak var collectionViewVideos: UICollectionView!
    var arrVideoData: [VideoTable] = []
    var isDeviceRotating = false
    var ellipsisButton: UIButton!
    private var isScreenVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        /*let clips = CoreDataManager.shared.getAllClips()
        for clip in clips {
            print("clip name: \(clip.clipURL ?? "")")
            print("clip videos: \(clip.video?.videoURL ?? "")")
            print("Thumb URL: \(clip.thumbnailURL ?? "")")
            print("start seconds: \(clip.startSeconds ?? "")")
        }*/
        //print(clips)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.title = "VideoWatcher"
        self.isScreenVisible = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.setupNotificationObserversForAppState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isScreenVisible = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    func setupUI() {
        self.title = "VideoWatcher"
        self.setupNavbar()
        self.collectionViewVideos.delegate = self
        self.collectionViewVideos.dataSource = self
        self.collectionViewVideos.register(UINib(nibName: "VideoWatcherCell", bundle: nil), forCellWithReuseIdentifier: "VideoWatcherCell")
        self.getRandomVideo()
    }
    
    func setupNavbar() {
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.isHidden = false
        navigationItem.hidesBackButton = true
        self.setupRightMenuButton()
    }
    
    func setupRightMenuButton() {
        ellipsisButton = UIButton(type: .system)
        ellipsisButton.tintColor = .white
        ellipsisButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        self.setupMenuOptions()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: ellipsisButton)
    }
    
    func setupMenuOptions() {
        let moreVideos = UIAction(title: "Manage Clips", image: nil) { _ in
            self.moveToManageVideosVC()
        }
        
        let favorite = UIAction(title: "Add new videos", image: nil) { _ in
            self.moveToAddNewVideoScreen()
        }
        
        let myStats = UIAction(title: "My stats", image: nil) { _ in
            self.moveToMyStats()
        }
        
        let settings = UIAction(title: "Settings", image: nil) { _ in
            self.moveToSettings()
        }
        
        ellipsisButton.overrideUserInterfaceStyle = .dark
        ellipsisButton.showsMenuAsPrimaryAction = true
        ellipsisButton.menu = UIMenu(title: "", children: [moreVideos, favorite, myStats, settings])
    }
    
    func getRandomVideo() {
        self.arrVideoData = CoreDataManager.shared.getRandomVideos(count: 6)
//        for vdata in self.arrVideoData {
//            print("V Name: \(vdata.videoURL ?? "") | isFav: \(vdata.isFavorite) | isDeleted: \(vdata.is_Deleted) | clip: \(vdata.clips?.count ?? 0)")
//        }
        self.collectionViewVideos.reloadData()
    }
    
    /*func startNextRandomVideoFrom(index: Int, isRandom: Bool) {
        if isRandom == false {
            let currentVideo = self.arrVideoData[index]
            print("currentVideo: ", currentVideo.videoURL ?? "")
            self.appendVideoInPreviousList(panel: index, currentVideo: currentVideo)
        }
        else {
            self.assignOriginalPreviousIndexesToCopy(index: index)
        }
        
        print("Changed RandomVideo at index: ", index)
        let videoData = CoreDataManager.shared.getRandomVideos(count: 1)
        if videoData.count > 0 {
            let randomAsset = videoData.first!
            self.arrVideoData[index] = randomAsset
            DispatchQueue.main.async {
                let indexPath = IndexPath(item: index, section: 0)
                if let videoCell = self.collectionViewVideos.cellForItem(at: indexPath) as? VideoWatcherCell {
                    videoCell.playVideo(videoAsset: randomAsset, isMuted: self.checkPanelIsMutedOrNot(index: index))
                }
            }
        }
    }*/
    
    func startNextRandomVideoFrom(index: Int, isRandom: Bool) {
        if isRandom == false {
            let currentVideo = self.arrVideoData[index]
            print("currentVideo: ", currentVideo.videoURL ?? "")
            self.appendVideoInPreviousList(panel: index, currentVideo: currentVideo)
        }
        else {
            self.assignOriginalPreviousIndexesToCopy(index: index)
        }
                
        let videoData = CoreDataManager.shared.getRandomVideos(count: 1)
        if videoData.count > 0 {
            
            let randomAsset = videoData.first!
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
                let destinationURL = directoryURL.appendingPathComponent(randomAsset.videoURL ?? "")
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    self.arrVideoData[index] = randomAsset
                    DispatchQueue.main.async {
                        print("Changed RandomVideo at index: ", index)
                        let indexPath = IndexPath(item: index, section: 0)
                        if let videoCell = self.collectionViewVideos.cellForItem(at: indexPath) as? VideoWatcherCell {
                            videoCell.playVideo(videoAsset: randomAsset, isMuted: self.checkPanelIsMutedOrNot(index: index))
                        }
                    }
                }
                else {
                    print("Find new RandomVideo at index: ", index)
                    self.startNextRandomVideoFrom(index: index, isRandom: isRandom)
                }
            }
        }
    }
    
    func startPreviousVideoAt(panel: Int) {
        
        var videoAsset: VideoTable?
        
        if panel == 0 {
            if AppData.shared.panel1PreviousVideosIndexCopy >= 0 {
                let prevVideoURL = AppData.shared.panel1PreviousVideos[AppData.shared.panel1PreviousVideosIndexCopy]
                print("PREV: prevVideoURL: \(prevVideoURL)")
                AppData.shared.panel1PreviousVideosIndexCopy -= 1
                
                videoAsset = CoreDataManager.shared.getVideoFrom(videoURL: prevVideoURL)
                
            } else {
                // No more previous videos in array2, play a random video from array1
                //playNextVideo()
                print("PREV: No previous video for panel: \(panel)")
            }
        }
        else if panel == 1 {
            if AppData.shared.panel2PreviousVideosIndexCopy >= 0 {
                let prevVideoURL = AppData.shared.panel2PreviousVideos[AppData.shared.panel2PreviousVideosIndexCopy]
                print("PREV: prevVideoURL: \(prevVideoURL)")
                AppData.shared.panel2PreviousVideosIndexCopy -= 1
                
                videoAsset = CoreDataManager.shared.getVideoFrom(videoURL: prevVideoURL)
                
            } else {
                // No more previous videos in array2, play a random video from array1
                //playNextVideo()
                print("PREV: No previous video for panel: \(panel)")
            }
        }
        else if panel == 2 {
            if AppData.shared.panel3PreviousVideosIndexCopy >= 0 {
                let prevVideoURL = AppData.shared.panel3PreviousVideos[AppData.shared.panel3PreviousVideosIndexCopy]
                print("PREV: prevVideoURL: \(prevVideoURL)")
                AppData.shared.panel3PreviousVideosIndexCopy -= 1
                
                videoAsset = CoreDataManager.shared.getVideoFrom(videoURL: prevVideoURL)
                
            } else {
                // No more previous videos in array2, play a random video from array1
                //playNextVideo()
                print("PREV: No previous video for panel: \(panel)")
            }
        }
        else if panel == 3 {
            if AppData.shared.panel4PreviousVideosIndexCopy >= 0 {
                let prevVideoURL = AppData.shared.panel4PreviousVideos[AppData.shared.panel4PreviousVideosIndexCopy]
                print("PREV: prevVideoURL: \(prevVideoURL)")
                AppData.shared.panel4PreviousVideosIndexCopy -= 1
                
                videoAsset = CoreDataManager.shared.getVideoFrom(videoURL: prevVideoURL)
                
            } else {
                // No more previous videos in array2, play a random video from array1
                //playNextVideo()
                print("PREV: No previous video for panel: \(panel)")
            }
        }
        else if panel == 4 {
            if AppData.shared.panel5PreviousVideosIndexCopy >= 0 {
                let prevVideoURL = AppData.shared.panel5PreviousVideos[AppData.shared.panel5PreviousVideosIndexCopy]
                print("PREV: prevVideoURL: \(prevVideoURL)")
                AppData.shared.panel5PreviousVideosIndexCopy -= 1
                
                videoAsset = CoreDataManager.shared.getVideoFrom(videoURL: prevVideoURL)
                
            } else {
                // No more previous videos in array2, play a random video from array1
                //playNextVideo()
                print("PREV: No previous video for panel: \(panel)")
            }
        }
        else if panel == 5 {
            if AppData.shared.panel6PreviousVideosIndexCopy >= 0 {
                let prevVideoURL = AppData.shared.panel6PreviousVideos[AppData.shared.panel6PreviousVideosIndexCopy]
                print("PREV: prevVideoURL: \(prevVideoURL)")
                AppData.shared.panel6PreviousVideosIndexCopy -= 1
                
                videoAsset = CoreDataManager.shared.getVideoFrom(videoURL: prevVideoURL)
                
            } else {
                // No more previous videos in array2, play a random video from array1
                //playNextVideo()
                print("PREV: No previous video for panel: \(panel)")
            }
        }
        
        DispatchQueue.main.async {
            if videoAsset != nil {
                let indexPath = IndexPath(item: panel, section: 0)
                if let videoCell = self.collectionViewVideos.cellForItem(at: indexPath) as? VideoWatcherCell {
                    videoCell.playVideo(videoAsset: videoAsset!, isMuted: self.checkPanelIsMutedOrNot(index: panel))
                }
            }
        }
    }
        
    func assignOriginalPreviousIndexesToCopy(index: Int) {
        if index == 0 {
            AppData.shared.panel1PreviousVideosIndexCopy = AppData.shared.panel1PreviousVideosIndex
        }
        else if index == 1 {
            AppData.shared.panel2PreviousVideosIndexCopy = AppData.shared.panel2PreviousVideosIndex
        }
        else if index == 2 {
            AppData.shared.panel3PreviousVideosIndexCopy = AppData.shared.panel3PreviousVideosIndex
        }
        else if index == 3 {
            AppData.shared.panel4PreviousVideosIndexCopy = AppData.shared.panel4PreviousVideosIndex
        }
        else if index == 4 {
            AppData.shared.panel5PreviousVideosIndexCopy = AppData.shared.panel5PreviousVideosIndex
        }
        else if index == 5 {
            AppData.shared.panel6PreviousVideosIndexCopy = AppData.shared.panel6PreviousVideosIndex
        }
    }
    
    func appendVideoInPreviousList(panel: Int, currentVideo: VideoTable) {
        
        if panel == 0 {
            let videoURL = currentVideo.videoURL ?? ""
            if let existingIndex = AppData.shared.panel1PreviousVideos.firstIndex(of: videoURL) {
                AppData.shared.panel1PreviousVideos.remove(at: existingIndex)
            }
            AppData.shared.panel1PreviousVideos.append(videoURL)
            AppData.shared.panel1PreviousVideosIndex = AppData.shared.panel1PreviousVideos.count - 1
            AppData.shared.panel1PreviousVideosIndexCopy = AppData.shared.panel1PreviousVideos.count - 1
            print("Panel 1 previous videos: \(AppData.shared.panel1PreviousVideos)")
        }
        else if panel == 1 {
            let videoURL = currentVideo.videoURL ?? ""
            if let existingIndex = AppData.shared.panel2PreviousVideos.firstIndex(of: videoURL) {
                AppData.shared.panel2PreviousVideos.remove(at: existingIndex)
            }
            AppData.shared.panel2PreviousVideos.append(videoURL)
            AppData.shared.panel2PreviousVideosIndex = AppData.shared.panel2PreviousVideos.count - 1
            AppData.shared.panel2PreviousVideosIndexCopy = AppData.shared.panel2PreviousVideos.count - 1
            print("Panel 2 previous videos: \(AppData.shared.panel2PreviousVideos)")
        }
        else if panel == 2 {
            let videoURL = currentVideo.videoURL ?? ""
            if let existingIndex = AppData.shared.panel3PreviousVideos.firstIndex(of: videoURL) {
                AppData.shared.panel3PreviousVideos.remove(at: existingIndex)
            }
            AppData.shared.panel3PreviousVideos.append(videoURL)
            AppData.shared.panel3PreviousVideosIndex = AppData.shared.panel3PreviousVideos.count - 1
            AppData.shared.panel3PreviousVideosIndexCopy = AppData.shared.panel3PreviousVideos.count - 1
            print("Panel 3 previous videos: \(AppData.shared.panel3PreviousVideos)")
        }
        else if panel == 3 {
            let videoURL = currentVideo.videoURL ?? ""
            if let existingIndex = AppData.shared.panel4PreviousVideos.firstIndex(of: videoURL) {
                AppData.shared.panel4PreviousVideos.remove(at: existingIndex)
            }
            AppData.shared.panel4PreviousVideos.append(videoURL)
            AppData.shared.panel4PreviousVideosIndex = AppData.shared.panel4PreviousVideos.count - 1
            AppData.shared.panel4PreviousVideosIndexCopy = AppData.shared.panel4PreviousVideos.count - 1
            print("Panel 4 previous videos: \(AppData.shared.panel4PreviousVideos)")
        }
        else if panel == 4 {
            let videoURL = currentVideo.videoURL ?? ""
            if let existingIndex = AppData.shared.panel5PreviousVideos.firstIndex(of: videoURL) {
                AppData.shared.panel5PreviousVideos.remove(at: existingIndex)
            }
            AppData.shared.panel5PreviousVideos.append(videoURL)
            AppData.shared.panel5PreviousVideosIndex = AppData.shared.panel5PreviousVideos.count - 1
            AppData.shared.panel5PreviousVideosIndexCopy = AppData.shared.panel5PreviousVideos.count - 1
            print("Panel 5 previous videos: \(AppData.shared.panel5PreviousVideos)")
        }
        else if panel == 5 {
            let videoURL = currentVideo.videoURL ?? ""
            if let existingIndex = AppData.shared.panel6PreviousVideos.firstIndex(of: videoURL) {
                AppData.shared.panel6PreviousVideos.remove(at: existingIndex)
            }
            AppData.shared.panel6PreviousVideos.append(videoURL)
            AppData.shared.panel6PreviousVideosIndex = AppData.shared.panel6PreviousVideos.count - 1
            AppData.shared.panel6PreviousVideosIndexCopy = AppData.shared.panel6PreviousVideos.count - 1
            print("Panel 6 previous videos: \(AppData.shared.panel6PreviousVideos)")
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if self.isScreenVisible {
            self.pauseAllVideoPlayers(selectedIndex: 0, isPauseAll: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playAllVideoPlayers(needToReloadCell: true)
            }
        }
    }
    
    func pauseAllVideoPlayers(selectedIndex: Int, isPauseAll: Bool? = false) {
        //print("index: ", selectedIndex)
        for (index, cell) in self.collectionViewVideos.visibleCells.enumerated() {
            if let videoCell = cell as? VideoWatcherCell {
                if let player = videoCell.player {
                    if isPauseAll == true {
                        player.pause()
                    }
                    else {
                        if index != selectedIndex {
                            player.pause()
                        }
                    }
                }
            }
        }
    }
    
    func playAllVideoPlayers(needToReloadCell: Bool = false) {
        for (_, cell) in self.collectionViewVideos.visibleCells.enumerated() {
            if let videoCell = cell as? VideoWatcherCell {
                if let player = videoCell.player {
                    if needToReloadCell {
                        videoCell.setupPlayer()
                        if let currentItem = player.currentItem, let asset = currentItem.asset as? AVURLAsset {
                            let url = asset.url.lastPathComponent
                            print("Current AVPlayerItem URL: \(url)")
                            self.setFavIcon(cell: videoCell, videoURL: url)
                        }
                    }
                    if player.isPlaying == false {
                        player.play()
                    }
                }
            }
        }
    }
    
    func setFavIcon(cell: VideoWatcherCell, videoURL: String) {
        if let videoAsset = CoreDataManager.shared.getVideoFrom(videoURL: videoURL) {
            print("Reload Name: \(videoAsset.videoURL ?? "") | isFav: \(videoAsset.isFavorite) | isDeleted: \(videoAsset.is_Deleted) | clip: \(videoAsset.clips?.count ?? 0)")
            DispatchQueue.main.async {
                if videoAsset.isFavorite {
                    cell.btnFavorite.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                    cell.btnFavorite.tintColor = .red
                }
                else {
                    if let clipsSet = videoAsset.clips {
                        var totalClips: [VideoClip] = []
                        let clipsArray = clipsSet.allObjects as? [VideoClip] ?? []
                        for clip in clipsArray {
                            //print("Clip URL: \(clip.clipURL ?? "")")
                            if clip.is_Deleted == false {
                                totalClips.append(clip)
                            }
                        }
                        
                        if totalClips.count > 0 {
                            cell.btnFavorite.setImage(UIImage(named: "img_heart_bunch"), for: .normal)
                            cell.btnFavorite.tintColor = .white
                        }
                        else {
                            cell.btnFavorite.setImage(UIImage(systemName: "heart"), for: .normal)
                            cell.btnFavorite.tintColor = .white
                        }
                    }
                    else {
                        cell.btnFavorite.setImage(UIImage(systemName: "heart"), for: .normal)
                        cell.btnFavorite.tintColor = .white
                    }
                }
            }
        }
    }
    
    func moveToFavouriteList() {
        self.pauseAllVideoPlayers(selectedIndex: 0, isPauseAll: true)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "FavoriteViewController") as! FavoriteViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .crossDissolve
        vc.delegate = self
        self.present(navController, animated: true)
    }
    
    func moveToAddNewVideoScreen() {
        self.pauseAllVideoPlayers(selectedIndex: 0, isPauseAll: true)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImportVideoViewController") as! ImportVideoViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .crossDissolve
        vc.isFromVideoPanel = true
        vc.delegate = self
        self.present(navController, animated: true)
    }
    
    func moveToMyStats() {
        self.isScreenVisible = false
        self.pauseAllVideoPlayers(selectedIndex: 0, isPauseAll: true)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyStatsViewController") as! MyStatsViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .overCurrentContext
        navController.modalTransitionStyle = .crossDissolve
        navController.navigationBar.isHidden = true
        vc.delegate = self
        self.present(navController, animated: true)
    }
    
    func moveToSettings() {
        self.isScreenVisible = false
        self.pauseAllVideoPlayers(selectedIndex: 0, isPauseAll: true)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .overCurrentContext
        navController.modalTransitionStyle = .crossDissolve
        navController.navigationBar.isHidden = true
        vc.delegate = self
        self.present(navController, animated: true)
    }
    
    func moveToManageVideosVC() {
        self.isScreenVisible = false
        self.pauseAllVideoPlayers(selectedIndex: 0, isPauseAll: true)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ManageVideosViewController") as! ManageVideosViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .overCurrentContext
        navController.modalTransitionStyle = .crossDissolve
        navController.navigationBar.isHidden = true
        vc.delegate = self
        self.present(navController, animated: true)
    }
    
    func moveToFullScreen(videoAsset: VideoTable, index: Int) {
        self.pauseAllVideoPlayers(selectedIndex: 0, isPauseAll: true)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "FullscreenVideoViewController") as! FullscreenVideoViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .crossDissolve
        navController.navigationBar.isHidden = true
        
        let indexPath = IndexPath(item: index, section: 0)
        if let videoCell = self.collectionViewVideos.cellForItem(at: indexPath) as? VideoWatcherCell {
            vc.currentTime = videoCell.player?.currentTime() ?? .zero
        }
        
        vc.isMuted = self.checkPanelIsMutedOrNot(index: index)
        vc.videoAsset = videoAsset
        vc.delegate = self
        vc.index = index
        
        self.present(navController, animated: true)
    }
}

extension VideoWatcherViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrVideoData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let videoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoWatcherCell", for: indexPath) as! VideoWatcherCell
  
        videoCell.delegate = self
        videoCell.setupPlayer()
        videoCell.index = indexPath.row
        videoCell.playVideo(videoAsset: self.arrVideoData[indexPath.row], isMuted: self.checkPanelIsMutedOrNot(index: indexPath.row))
        videoCell.btnFavorite.tag = indexPath.row
        videoCell.btnFavorite.addTarget(self, action: #selector(makeFavourite), for: .touchUpInside)
        videoCell.btnSpeaker.tag = indexPath.row
        videoCell.btnSpeaker.addTarget(self, action: #selector(btnSpeakerAction), for: .touchUpInside)
        
        return videoCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.moveToFullScreen(videoAsset: self.arrVideoData[indexPath.row], index: indexPath.row)
    }
    
    @objc func makeFavourite(sender: UIButton) {
        let index = sender.tag
        let videoAsset = self.arrVideoData[index]
        if videoAsset.isFavorite == true {
            return
        }
        
        let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(videoAsset.videoURL ?? "")
        let asset = AVAsset(url: videoURL)
        let duration = asset.duration
        let durationTime = CMTimeGetSeconds(duration)
        
        print(durationTime)
        print("Duration: \(durationTime) VideoName: \(videoAsset.videoURL ?? "")")
        if durationTime > 30 {
            self.showBottomSheet(sender: sender, duration: durationTime, index: index, videoAsset: videoAsset)
        }
        else {
            self.generateThumbnailOfVideo(videoAsset: videoAsset)
            self.makeEntireVideoFavorite(index: index, sender: sender)
        }
    }

    func showBottomSheet(sender: UIButton, duration: Float64, index: Int, videoAsset: VideoTable) {
        var message = ""
        if duration >= 3600 {
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            message = String(format: "This video is %d hours %02d minutes %02d seconds long. Do you want to favorite the entire video, or select a shorter clip within the video?", hours, minutes, seconds)
        } else if duration >= 60 {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            message = String(format: "This video is %d:%02d minutes long. Do you want to favorite the entire video, or select a shorter clip within the video?", minutes, seconds)
        } else {
            message = String(format: "This video is %d seconds long. Do you want to favorite the entire video, or select a shorter clip within the video?", Int(duration))
        }
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        let entireVideoAction = UIAlertAction(title: "Entire Video", style: .default) { _ in
            // Handle "Entire Video" action
            self.generateThumbnailOfVideo(videoAsset: videoAsset)
            self.makeEntireVideoFavorite(index: index, sender: sender)
        }
        
        let shorterClipAction = UIAlertAction(title: "Shorter Clip", style: .default) { _ in
            // Handle "Shorter Clip" action
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateClipViewController") as! CreateClipViewController
            let navController = UINavigationController(rootViewController: vc)
            navController.modalPresentationStyle = .fullScreen
            navController.modalTransitionStyle = .crossDissolve
            vc.delegate = self
            vc.isFromHome = true
            vc.videoAsset = self.arrVideoData[index]
            self.present(navController, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Handle "Cancel" action
        }
        
        alertController.addAction(entireVideoAction)
        alertController.addAction(shorterClipAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
            popoverController.permittedArrowDirections = [.up]
        }
        
        present(alertController, animated: true, completion: nil)

    }
    
    func makeEntireVideoFavorite(index: Int, sender: UIButton) {
        print("Favourite video: \(self.arrVideoData[index].videoURL ?? "")")
        CoreDataManager.shared.updateIsFavorite(videoURL: self.arrVideoData[index].videoURL ?? "", isFavorite: true)
        
        sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        sender.tintColor = .systemPink
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let videoData = CoreDataManager.shared.getAllVideos()
            for vdata in videoData {
                print("V Name: \(vdata.videoURL ?? "") | isFav: \(vdata.isFavorite) | isDeleted: \(vdata.is_Deleted)")
            }
        }
    }
    
    func generateThumbnailOfVideo(videoAsset: VideoTable) {
        
        if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos) {
            let destinationURL = directoryURL.appendingPathComponent("\(videoAsset.videoURL ?? "")")
            if let directoryThumbURL = Utility.getDirectoryPath(folderName: DirectoryName.Thumbnails) {
                let destinationThumbURL = directoryThumbURL.appendingPathComponent("\(videoAsset.videoURL ?? "").jpg")
              
                DispatchQueue.main.async {
                    let asset = AVAsset(url: destinationURL)
                    if let thumbnailImage = asset.generateThumbnail() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                            if let imageData = thumbnailImage.jpegData(compressionQuality: 0.6) {
                                do {
                                    try imageData.write(to: destinationThumbURL)
                                    
                                    CoreDataManager.shared.saveThumbnailOfVideo(videoURL: videoAsset.videoURL ?? "", thumbULR: destinationThumbURL.lastPathComponent)
                                                                        
                                    print("Thumbnail saved successfully!")
                                } catch {
                                    print("Error saving Thumbnail: \(error)")
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    @objc func btnSpeakerAction(sender: UIButton) {
        let index = sender.tag
        self.menuAudioAction(index: index)
    }
    
    func collectionView(_ collectionView: UICollectionView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.isScreenVisible {
                self.playAllVideoPlayers()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        self.configureContextMenu(index: indexPath.row)
    }
    
    //Menu options for panels
    func configureContextMenu(index: Int) -> UIContextMenuConfiguration {
        let context = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (action) -> UIMenu? in

            let result = self.audioButtonTitleAndImage(index: index)
            let muteUnmute = UIAction(title: result.0, image: result.1, identifier: nil, discoverabilityTitle: nil, state: .off) { (_) in
                self.menuAudioAction(index: index)
            }
            
            let nextVideo = UIAction(title: "Next video", image: UIImage(systemName: "forward"), identifier: nil, discoverabilityTitle: nil, state: .off) { (_) in
                self.startNextRandomVideoFrom(index: index, isRandom: false)
            }
            
            let previousVideo = UIAction(title: "Previous video", image: UIImage(systemName: "backward"), identifier: nil, discoverabilityTitle: nil, state: .off) { (_) in
                self.startPreviousVideoAt(panel: index)
            }
            if self.isPreviousVideoDisabled(panel: index) {
                previousVideo.state = .off
                previousVideo.attributes = .disabled
            }
            
            let fullScreen = UIAction(title: "Full screen", image: UIImage(systemName: "arrow.up.left.and.arrow.down.right"), identifier: nil, discoverabilityTitle: nil, state: .off) { (_) in
                //self.openVideoEditor(videoAsset: self.arrVideoData[index])
                self.moveToFullScreen(videoAsset: self.arrVideoData[index], index: index)
            }
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), identifier: nil, discoverabilityTitle: nil,attributes: .destructive, state: .off) { (_) in
                self.showDeleteConfirmation(index: index)
            }
            
            self.pauseAllVideoPlayers(selectedIndex: index)
            
            //return UIMenu(title: "Options", image: nil, identifier: nil, options: UIMenu.Options.displayInline, children: [muteUnmute, nextVideo, previousVideo, fullScreen, delete])
            return UIMenu(title: "", image: nil, identifier: nil, options: UIMenu.Options.displayInline, children: [delete])
        }
        return context
    }
    
    //MARK: - Mute/unmute menu actions
    func audioButtonTitleAndImage(index: Int) -> (String, UIImage) {
        var title = "Unmute"
        var speakerImage = UIImage(systemName: "speaker.wave.2")
        
        if index == 0 && AppData.shared.panel1IsMute == false {
            title = "Mute"
            speakerImage = UIImage(systemName: "speaker.slash")
        }
        else if index == 1 && AppData.shared.panel2IsMute == false {
            title = "Mute"
            speakerImage = UIImage(systemName: "speaker.slash")
        }
        else if index == 2 && AppData.shared.panel3IsMute == false {
            title = "Mute"
            speakerImage = UIImage(systemName: "speaker.slash")
        }
        else if index == 3 && AppData.shared.panel4IsMute == false {
            title = "Mute"
            speakerImage = UIImage(systemName: "speaker.slash")
        }
        else if index == 4 && AppData.shared.panel5IsMute == false {
            title = "Mute"
            speakerImage = UIImage(systemName: "speaker.slash")
        }
        else if index == 5 && AppData.shared.panel6IsMute == false {
            title = "Mute"
            speakerImage = UIImage(systemName: "speaker.slash")
        }
        
        return (title, speakerImage!)
    }
    
    func menuAudioAction(index: Int) {
        if index == 0 {
            if AppData.shared.panel1IsMute {
                AppData.shared.panel1IsMute = false
            }
            else {
                AppData.shared.panel1IsMute = true
            }
        }
        else if index == 1 {
            if AppData.shared.panel2IsMute {
                AppData.shared.panel2IsMute = false
            }
            else {
                AppData.shared.panel2IsMute = true
            }
        }
        else if index == 2 {
            if AppData.shared.panel3IsMute {
                AppData.shared.panel3IsMute = false
            }
            else {
                AppData.shared.panel3IsMute = true
            }
        }
        else if index == 3 {
            if AppData.shared.panel4IsMute {
                AppData.shared.panel4IsMute = false
            }
            else {
                AppData.shared.panel4IsMute = true
            }
        }
        else if index == 4 {
            if AppData.shared.panel5IsMute {
                AppData.shared.panel5IsMute = false
            }
            else {
                AppData.shared.panel5IsMute = true
            }
        }
        else if index == 5 {
            if AppData.shared.panel6IsMute {
                AppData.shared.panel6IsMute = false
            }
            else {
                AppData.shared.panel6IsMute = true
            }
        }
        
        self.updateAudioStatusFor(index: index)
    }
    
    func updateAudioStatusFor(index: Int) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: index, section: 0)
            if let videoCell = self.collectionViewVideos.cellForItem(at: indexPath) as? VideoWatcherCell {
                videoCell.setSpeakerMuteUnmute(indexToChange: index)
                
                let isMuted = self.checkPanelIsMutedOrNot(index: index)
                videoCell.player?.isMuted = isMuted
                if isMuted {
                    //videoCell.btnSpeaker.isHidden = true
                    videoCell.btnSpeaker.setImage(UIImage(systemName: "speaker.slash"), for: .normal)
                    videoCell.btnSpeaker.tintColor = .white
                }
                else {
                    //videoCell.btnSpeaker.isHidden = falsespeaker.wave.2.fill
                    videoCell.btnSpeaker.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
                    videoCell.btnSpeaker.tintColor = .white
                }
                print("AVPlayer is currently muted: \(videoCell.player?.isMuted ?? false)")
            }
        }
    }
    
    func checkPanelIsMutedOrNot(index: Int) -> Bool {
        if index == 0 {
            if AppData.shared.panel1IsMute {
                return true
            }
            else {
                return false
            }
        }
        else if index == 1 {
            if AppData.shared.panel2IsMute {
                return true
            }
            else {
                return false
            }
        }
        else if index == 2 {
            if AppData.shared.panel3IsMute {
                return true
            }
            else {
                return false
            }
        }
        else if index == 3 {
            if AppData.shared.panel4IsMute {
                return true
            }
            else {
                return false
            }
        }
        else if index == 4 {
            if AppData.shared.panel5IsMute {
                return true
            }
            else {
                return false
            }
        }
        else if index == 5 {
            if AppData.shared.panel6IsMute {
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    //MARK: - Delete menu actions
    @objc func showDeleteConfirmation(index: Int) {
        let alertController = UIAlertController(
            title: "Delete video",
            message: "This video will be removed from this application. Are you sure you want to delete?",
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Delete video", style: .destructive) { _ in
            // Performing the delete action
            print("deleted video: \(self.arrVideoData[index].videoURL ?? "")")
            CoreDataManager.shared.updateIsDeleted(videoURL: self.arrVideoData[index].videoURL ?? "")
            self.startNextRandomVideoFrom(index: index, isRandom: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let videoData = CoreDataManager.shared.getAllVideos()
                for vdata in videoData {
                    print("V Name: \(vdata.videoURL ?? "") | isFav: \(vdata.isFavorite) | isDeleted: \(vdata.is_Deleted)")
                }
            }
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
    
    //MARK: - Previous audio action methods
    func isPreviousVideoDisabled(panel: Int) -> Bool {
        
        if panel == 0 {
            if AppData.shared.panel1PreviousVideosIndexCopy != -1 {
                return false
            }
            else {
                return true
            }
        }
        else if panel == 1 {
            if AppData.shared.panel2PreviousVideosIndexCopy != -1 {
                return false
            }
            else {
                return true
            }
        }
        else if panel == 2 {
            if AppData.shared.panel3PreviousVideosIndexCopy != -1 {
                return false
            }
            else {
                return true
            }
        }
        else if panel == 3 {
            if AppData.shared.panel4PreviousVideosIndexCopy != -1 {
                return false
            }
            else {
                return true
            }
        }
        else if panel == 4 {
            if AppData.shared.panel5PreviousVideosIndexCopy != -1 {
                return false
            }
            else {
                return true
            }
        }
        else if panel == 5 {
            if AppData.shared.panel6PreviousVideosIndexCopy != -1 {
                return false
            }
            else {
                return true
            }
        }
        
        return true
    }
    
    private func setupNotificationObserversForAppState() {
        self.deinitNotificationObserversForAppState()
        
        // background event
        NotificationCenter.default.addObserver(self, selector: #selector(stopAllPanelsVideos), name: UIApplication.didEnterBackgroundNotification, object: nil)

        // foreground event
        NotificationCenter.default.addObserver(self, selector: #selector(startAllPanelsVideos), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    private func deinitNotificationObserversForAppState() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    @objc fileprivate func stopAllPanelsVideos() {
        if self.isScreenVisible {
            self.pauseAllVideoPlayers(selectedIndex: 0, isPauseAll: true)
        }
    }
    
    @objc fileprivate func startAllPanelsVideos() {
        if self.isScreenVisible {
            DispatchQueue.main.async {
                self.playAllVideoPlayers(needToReloadCell: true)
            }
        }
    }
    
    @objc func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interruptionTypeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue) else {
            return
        }
        
        switch interruptionType {
        case .began:
            // Interruption began, pause AVPlayer playback
            self.stopAllPanelsVideos()
        case .ended:
            // Interruption ended, check if we should resume playback
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let interruptionOptions = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if interruptionOptions.contains(.shouldResume) {
                    self.startAllPanelsVideos()
                }
            }
        default:
            break
        }
    }
}

extension VideoWatcherViewController: UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        print(editedVideoPath)
    }
}

extension VideoWatcherViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if Utility.getDeviceOrientation().isLandscape {
            // Calculate the size of each cell based on the collectionView width and number of cells per row (3)
            let cellWidth = (collectionView.bounds.width - 30) / 3.0 // Subtract 30 to consider 10px spacing on both sides and 10px spacing between cells
            let cellHeight = (collectionView.bounds.height - 25) / 2.0// Subtract 25 to consider 10px spacing on top and bottom and 5px spacing between cells
            //print("Cell size: ", CGSize(width: cellWidth, height: cellHeight))
            return CGSize(width: cellWidth, height: cellHeight)
        }
        else {
            // Calculate the size of each cell based on the collectionView width and number of cells per row (3)
//            let cellWidth = (collectionView.bounds.width - 30) / 3.0 // Subtract 30 to consider 10px spacing on both sides and 10px spacing between cells
//            let cellHeight = (collectionView.bounds.height - 25) / 2.0// Subtract 25 to consider 10px spacing on top and bottom and 5px spacing between cells
//            //print("Cell size: ", CGSize(width: cellWidth, height: cellHeight))
//             return CGSize(width: cellWidth, height: cellHeight)
            
            let cellWidth = (collectionView.bounds.width - 25) / 2.0 // Subtract 30 to consider 10px spacing on both sides and 10px spacing between cells
            let cellHeight = (collectionView.bounds.height - 30) / 3.0// Subtract 25 to consider 10px spacing on top and bottom and 5px spacing between cells
            //print("Cell size: ", CGSize(width: cellWidth, height: cellHeight))
            return CGSize(width: cellWidth, height: cellHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // Set the spacing from each side of the UICollectionView (10px spacing on all sides)
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        // Minimum line spacing between two rows
        if UIDevice.current.orientation.isLandscape {
            return 5.0
        }
        else {
            return 5.0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        // Minimum inter-item spacing between two cells within the same row
        return 0.0
    }
}

extension VideoWatcherViewController: VideoWatcherCellDelegate {
    func startNextRandomVideo(index: Int, isRandom: Bool) {
        self.startNextRandomVideoFrom(index: index, isRandom: isRandom)
    }
    
    func startPreviousVideo(index: Int) {
        self.startPreviousVideoAt(panel: index)
    }
}

extension VideoWatcherViewController: FavoriteViewControllerDelegate {
    func startAllPanel() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playAllVideoPlayers(needToReloadCell: true)
        }
    }
}

extension VideoWatcherViewController: FullscreenVideoViewControllerDelegate {
    func startAllPanels(index: Int, currentTime: CMTime) {
        let indexPath = IndexPath(item: index, section: 0)
        if let videoCell = self.collectionViewVideos.cellForItem(at: indexPath) as? VideoWatcherCell {
            videoCell.player?.seek(to: currentTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playAllVideoPlayers(needToReloadCell: true)
        }
    }
    
    func setVolumeFor(index: Int) {
        self.menuAudioAction(index: index)
    }
    
    func deleteVideo(index: Int) {
        CoreDataManager.shared.updateIsDeleted(videoURL: self.arrVideoData[index].videoURL ?? "")
        self.startNextRandomVideoFrom(index: index, isRandom: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let videoData = CoreDataManager.shared.getAllVideos()
            for vdata in videoData {
                print("V Name: \(vdata.videoURL ?? "") | isFav: \(vdata.isFavorite) | isDeleted: \(vdata.is_Deleted)")
            }
        }
    }
}

extension VideoWatcherViewController: CreateClipViewControllerDelegate {
    func startAllPanelsFromClips() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playAllVideoPlayers(needToReloadCell: true)
        }
    }
}

extension VideoWatcherViewController: ManageVideosViewControllerDelegate {
    func restartAllPanel() {
        self.isScreenVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playAllVideoPlayers(needToReloadCell: true)
        }
    }
}

extension VideoWatcherViewController: MyStatsViewControllerDelegate {
    func startAllPanelAgain() {
        self.isScreenVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playAllVideoPlayers(needToReloadCell: true)
        }
    }
}

extension VideoWatcherViewController: SettingsViewControllerDelegate {
    func restartAllPanels() {
        self.isScreenVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playAllVideoPlayers(needToReloadCell: true)
        }
    }
}

extension VideoWatcherViewController: ImportVideoViewControllerDelegate {
    func startAllPanelFromImport() {
        self.isScreenVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playAllVideoPlayers(needToReloadCell: true)
        }
    }
}
