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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.title = "VideoWatcher"
    }
    
    func setupUI() {
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
        let moreVideos = UIAction(title: "Import more videos",
          image: UIImage(systemName: "square.and.arrow.down")) { _ in
          
        }

        let favImage = UIImage(systemName: "heart.fill")?.withTintColor(.white,
                  renderingMode: .alwaysOriginal)
        let favorite = UIAction(title: "Favorite",
          image: favImage) { _ in
            self.moveToFavouriteList()
        }
        
        let settings = UIAction(title: "Settings",
          image: UIImage(systemName: "gearshape.fill")) { _ in
          
        }
        
        ellipsisButton.overrideUserInterfaceStyle = .dark
        ellipsisButton.showsMenuAsPrimaryAction = true
        ellipsisButton.menu = UIMenu(title: "", children: [moreVideos, favorite, settings])
    }
        
    func getRandomVideo() {
        self.arrVideoData = CoreDataManager.shared.getRandomVideosData(count: 6)
        for vdata in self.arrVideoData {
            print("V Name: \(vdata.videoURL ?? "") | isFav: \(vdata.isFavorite) | isDeleted: \(vdata.is_Deleted)")
        }
        self.collectionViewVideos.reloadData()
    }
    
    func startNextRandomVideoFrom(index: Int) {
        print("Changed RandomVideo at index: ", index)
        let videoData = CoreDataManager.shared.getRandomVideosData(count: 1)
        if videoData.count > 0 {
            let randomAsset = videoData.first!
            self.arrVideoData[index] = randomAsset
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
    
    func moveToFavouriteList() {
        self.pauseAllVideoPlayers(selectedIndex: 0, isPauseAll: true)
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "FavouriteViewController") as! FavouriteViewController
//        vc.modalPresentationStyle = .fullScreen
//        vc.modalTransitionStyle = .crossDissolve
//        self.present(vc, animated: true)
        
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "FavoriteViewController") as! FavoriteViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .crossDissolve
        vc.delegate = self
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
        videoCell.playVideo(videoAsset: self.arrVideoData[indexPath.row])
        videoCell.btnFavorite.tag = indexPath.row
        videoCell.btnFavorite.addTarget(self, action: #selector(makeFavourite), for: .touchUpInside)
        
        return videoCell
    }
    
    @objc func makeFavourite(sender: UIButton) {
        let index = sender.tag
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
            print("deleted video: \(self.arrVideoData[index].videoURL ?? "")")
            CoreDataManager.shared.updateIsDeleted(videoURL: self.arrVideoData[index].videoURL ?? "")
            self.startNextRandomVideoFrom(index: index)
            
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

extension VideoWatcherViewController: FavoriteViewControllerDelegate {
    func startAllPanel() {
        self.playAllVideoPlayers()
    }
}
