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
    var isDeviceRotating = false
        
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
        print("Changed RandomVideo at index: ", index)
        let videos = CoreDataManager.shared.getRandomVideos(count: 1)
        if videos.count > 0 {
            let randomAsset = videos.first!
            self.videosArray[index] = randomAsset
            DispatchQueue.main.async {
                let indexPath = IndexPath(item: index, section: 0)
                if let videoCell = self.collectionViewVideos.cellForItem(at: indexPath) as? VideoWatcherCell {
                    videoCell.playVideo(videoAsset: randomAsset)
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIApplication.shared.topViewController() is VideoWatcherViewController {
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
                    }
                    if player.isPlaying == false {
                        player.play()
                    }
                }
            }
        }
    }
}

extension VideoWatcherViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.videosArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let videoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoWatcherCell", for: indexPath) as! VideoWatcherCell
  
        videoCell.delegate = self
        videoCell.setupPlayer()
        videoCell.index = indexPath.row
        videoCell.playVideo(videoAsset: self.videosArray[indexPath.row])
        
        return videoCell
    }
    
    func collectionView(_ collectionView: UICollectionView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        self.playAllVideoPlayers(needToReloadCell: true)
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
                self.showDeleteConfirmation(index: index)
            }
            
            self.pauseAllVideoPlayers(selectedIndex: index)
            
            return UIMenu(title: "Options", image: nil, identifier: nil, options: UIMenu.Options.displayInline, children: [audio, skipForward, skipBackward, fullScreen, delete])
            
        }
        return context
    }
    
    //Contect menu actions
    @objc func showDeleteConfirmation(index: Int) {
        let alertController = UIAlertController(
            title: "Delete video",
            message: "This video will be removed from this application. Are you sure you want to delete?",
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Delete video", style: .destructive) { _ in
            // Performing the delete action
            print("deleted video: \(self.videosArray[index])")
            CoreDataManager.shared.deleteVideo(videoURL: self.videosArray[index])
            self.startNextRandomVideoFrom(index: index)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let allVideos = CoreDataManager.shared.getAllVideos()
                for video in allVideos {
                    print("Video URL from COREDATA: \(video.videoURL ?? "N/A")")
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
