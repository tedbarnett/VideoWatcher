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
    var videosArray: [String] = []
    var currentlyPlayingVideo: [Any] = [] // Array of currently playing video
    var currentlyPlayingVideoStates: [IndexPath: (Any, Double)] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }

    func setupUI() {
        self.collectionViewVideos.delegate = self
        self.collectionViewVideos.dataSource = self
        self.collectionViewVideos.register(UINib(nibName: "VideoWatcherCell", bundle: nil), forCellWithReuseIdentifier: "VideoWatcherCell")
        self.getRandomVideo()
    }
    
    func getRandomVideo() {
        self.videosArray = CoreDataManager.shared.getRandomVideos(count: 6)
        print(self.videosArray)
        self.collectionViewVideos.reloadData()
    }
    
    func startNextRandomVideoFrom(index: Int) {
        print("index: ", index)
        //let randomIndex = Int.random(in: 0..<videosArray.count)
        let videos = CoreDataManager.shared.getRandomVideos(count: 1)
        if videos.count > 0 {
            let randomAsset = videos.first!
            self.videosArray[index] = randomAsset
            DispatchQueue.main.async {
                let indexPath = IndexPath(item: index, section: 0)
                if let videoCell = self.collectionViewVideos.cellForItem(at: indexPath) as? VideoWatcherCell {
                    videoCell.playVideo(videoAsset: randomAsset, firstLoad: false)
                }
            }
        }
    }
    
    /*override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Save the current playback time before reloading the collection view
        
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        self.currentlyPlayingVideoStates.removeAll()
            for (index, cell) in self.collectionViewVideos.visibleCells.enumerated() {
                if let videoCell = cell as? VideoWatcherCell {
                    if let player = videoCell.player, let currentItem = player.currentItem {
                        let playbackTime = CMTimeGetSeconds(currentItem.currentTime())
                        
                        if let (videoURL, _) = self.currentlyPlayingVideoStates[IndexPath(item: index, section: 0)] {
                            self.currentlyPlayingVideoStates[IndexPath(item: index, section: 0)] = (videoURL, playbackTime)
                        }
                    }
                }
            }
        //}
        
        // Reload the collection view to preserve video states
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.collectionViewVideos.reloadData()
        }
    }*/
}

extension VideoWatcherViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.videosArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let videoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoWatcherCell", for: indexPath) as! VideoWatcherCell
        videoCell.delegate = self
        
//        videoCell.setupPlayer()
//        if let (videoAsset, playbackTime) = self.currentlyPlayingVideoStates[indexPath] {
//            // Resume playing the stored video from the saved playback time
//            videoCell.index = indexPath.row
//            videoCell.playVideo(videoAsset: videoAsset, startDuration: playbackTime, firstLoad: false)
//        } else {
//            let randomIndex = Int.random(in: 0..<videosArray.count)
//            let randomAsset = videosArray[randomIndex]
//            videoCell.index = indexPath.row
//            self.currentlyPlayingVideoStates[indexPath] = (randomAsset, 0)
//            videoCell.playVideo(videoAsset: randomAsset, firstLoad: true)
//        }
        //let randomIndex = Int.random(in: 0..<videosArray.count)
        //let randomAsset = videosArray[randomIndex]
        
        videoCell.setupPlayer()
        videoCell.index = indexPath.row
        videoCell.playVideo(videoAsset: self.videosArray[indexPath.row], firstLoad: true)
        return videoCell
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        self.configureContextMenu(index: indexPath.row)
    }
    
    func configureContextMenu(index: Int) -> UIContextMenuConfiguration {
        let context = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (action) -> UIMenu? in
            
            let audio = UIAction(title: "Audio", image: UIImage(systemName: "speaker.slash"), identifier: nil, discoverabilityTitle: nil, state: .off) { (_) in
                
            }
            
            let skipForward = UIAction(title: "Next video", image: UIImage(systemName: "forward"), identifier: nil, discoverabilityTitle: nil, state: .off) { (_) in
                self.startNextRandomVideoFrom(index: index)
            }
            
            let skipBackward = UIAction(title: "Previous video", image: UIImage(systemName: "backward"), identifier: nil, discoverabilityTitle: nil, state: .off) { (_) in
                
            }
            
            let fullScreen = UIAction(title: "Full screen", image: UIImage(systemName: "arrow.up.left.and.arrow.down.right"), identifier: nil, discoverabilityTitle: nil, state: .off) { (_) in
                
            }
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), identifier: nil, discoverabilityTitle: nil,attributes: .destructive, state: .off) { (_) in
            }
            
            return UIMenu(title: "Options", image: nil, identifier: nil, options: UIMenu.Options.displayInline, children: [audio, skipForward, skipBackward, fullScreen, delete])
            
        }
        return context
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
            let cellWidth = (collectionView.bounds.width - 30) / 3.0 // Subtract 30 to consider 10px spacing on both sides and 10px spacing between cells
            let cellHeight = (collectionView.bounds.height - 25) / 2.0// Subtract 25 to consider 10px spacing on top and bottom and 5px spacing between cells
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
    func startNextRandomVideo(index: Int) {
        self.startNextRandomVideoFrom(index: index)
    }
}
