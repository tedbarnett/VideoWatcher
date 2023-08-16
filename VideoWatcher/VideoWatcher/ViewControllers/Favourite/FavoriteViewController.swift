//
//  FavouriteViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 08/08/23.
//

import UIKit
import Kingfisher
import AVFoundation
import AVKit

protocol FavoriteViewControllerDelegate: AnyObject {
    func startAllPanel()
}

class FavoriteViewController: UIViewController {

    weak var delegate: FavoriteViewControllerDelegate?
    @IBOutlet weak var collectionViewFavorite: UICollectionView!
    var arrFavoriteVideoData: [VideoTable] = []
    var arrClips: [Any] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }
    
    func setupUI() {
        self.title = "Clips"
        self.setupNavbar()
        self.collectionViewFavorite.delegate = self
        self.collectionViewFavorite.dataSource = self
        self.collectionViewFavorite.register(UINib(nibName: "FavoriteCell", bundle: nil), forCellWithReuseIdentifier: "FavoriteCell")
        self.getAllClips()
    }
    
    func setupNavbar() {
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.isHidden = false
        navigationItem.hidesBackButton = true
        self.setupRightMenuButton()
    }
    
    func setupRightMenuButton() {
        let closeButton = UIButton(type: .system)
        closeButton.tintColor = .white
        closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        let exportButton = UIButton(type: .system)
        exportButton.tintColor = .white
        exportButton.setTitle("Export favorite", for: .normal)
        exportButton.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        
        let closeBarButtonItem = UIBarButtonItem(customView: closeButton)
        let exportBarButtonItem = UIBarButtonItem(customView: exportButton)

        // Create an array of UIBarButtonItem objects
        let barButtonItems: [UIBarButtonItem] = [closeBarButtonItem, exportBarButtonItem]

        // Assign the array to navigationItem.rightBarButtonItems
        navigationItem.rightBarButtonItems = barButtonItems
    }
    
    @objc func closeButtonTapped() {
        self.delegate?.startAllPanel()
        self.dismiss(animated: true)
    }
    
    @objc func exportButtonTapped() {
        if let url = CoreDataManager.shared.generateCSVFromVideoClips() {
            let activityViewController = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            // Present the UIActivityViewController
            present(activityViewController, animated: true, completion: nil)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIApplication.shared.topViewController() is FavoriteViewController {
            self.collectionViewFavorite.reloadData()
        }
    }
    
    func getFavoriteVideo() {
        self.arrFavoriteVideoData = CoreDataManager.shared.getAllFavoriteVideos()
        self.collectionViewFavorite.reloadData()
    }
    
    func getAllClips() {
        let wholeFavVideos = CoreDataManager.shared.getAllFavoriteVideos()
        let allClipse = CoreDataManager.shared.getAllClips()
        self.arrClips.append(contentsOf: wholeFavVideos)
        print(self.arrClips.count)
        self.arrClips.append(contentsOf: allClipse)
        print(self.arrClips.count)
        self.collectionViewFavorite.reloadData()
    }
}

extension FavoriteViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrClips.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCell", for: indexPath) as! FavoriteCell
        cell.setupCell()
        let clip = self.arrClips[indexPath.row]
        if let aClip = clip as? VideoClip {
            let thumbURL = Utility.getDirectoryPath(folderName: DirectoryName.Thumbnails)!.appendingPathComponent(aClip.thumbnailURL ?? "")
            cell.imgThumbnail.kf.setImage(with: thumbURL)
        }
        else {
            let vClip = clip as! VideoTable
            let thumbURL = Utility.getDirectoryPath(folderName: DirectoryName.Thumbnails)!.appendingPathComponent(vClip.thumbnailURL ?? "")
            cell.imgThumbnail.kf.setImage(with: thumbURL)
        }
        
        cell.btnPlay.tag = indexPath.row
        cell.btnPlay.addTarget(self, action: #selector(btnPlayAction), for: .touchUpInside)

        
        return cell
    }
    
    @objc func btnPlayAction(sender: UIButton) {
        let index = sender.tag
        let clip = self.arrClips[index]
        var clipURL: URL?
        if let aClip = clip as? VideoClip {
            clipURL = Utility.getDirectoryPath(folderName: DirectoryName.SavedClips)!.appendingPathComponent(aClip.clipURL ?? "")
        }
        else {
            let vClip = clip as! VideoTable
            clipURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(vClip.videoURL ?? "")
        }
        
        let playerItem = AVPlayerItem(url: clipURL!)
        player = AVPlayer(playerItem: playerItem)
        
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        if let playerViewController = playerViewController {
            present(playerViewController, animated: true) {
                self.player?.play()
            }
        }
    }
}

extension FavoriteViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if Utility.getDeviceOrientation().isLandscape {
            // Calculate the size of each cell based on the collectionView width and number of cells per row (3)
            let cellWidth = (collectionView.bounds.width - 30) / 3.0 // Subtract 30 to consider 10px spacing on both sides and 10px spacing between cells
            let cellHeight = (collectionView.bounds.height - 25) / 2.0// Subtract 25 to consider 10px spacing on top and bottom and 5px spacing between cells
            //print("Cell size: ", CGSize(width: cellWidth, height: cellHeight))
            //print("Cell size isLandscape: \(CGSize(width: cellWidth, height: cellHeight))")
            return CGSize(width: cellWidth, height: cellHeight)
        }
        else {
            // Calculate the size of each cell based on the collectionView width and number of cells per row (3)
            /*let cellWidth = (collectionView.bounds.width - 30) / 3.0 // Subtract 30 to consider 10px spacing on both sides and 10px spacing between cells
            let cellHeight = (collectionView.bounds.height - 25) / 2.0// Subtract 25 to consider 10px spacing on top and bottom and 5px spacing between cells
            //print("Cell size: ", CGSize(width: cellWidth, height: cellHeight))
            print("Cell size isPortrait: \(CGSize(width: cellWidth, height: cellHeight))")
            return CGSize(width: cellWidth, height: cellHeight)*/
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
        return 5.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        // Minimum inter-item spacing between two cells within the same row
        return 0.0
    }
}
