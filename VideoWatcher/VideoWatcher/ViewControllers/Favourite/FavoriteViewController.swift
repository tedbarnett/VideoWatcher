//
//  FavouriteViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 08/08/23.
//

import UIKit

protocol FavoriteViewControllerDelegate: AnyObject {
    func startAllPanel()
}

class FavoriteViewController: UIViewController {

    weak var delegate: FavoriteViewControllerDelegate?
    @IBOutlet weak var collectionViewFavorite: UICollectionView!
    var arrFavoriteVideoData: [VideoTable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }
    
    func setupUI() {
        self.title = "Favorite"
        self.setupNavbar()
        self.collectionViewFavorite.delegate = self
        self.collectionViewFavorite.dataSource = self
        self.collectionViewFavorite.register(UINib(nibName: "FavoriteCell", bundle: nil), forCellWithReuseIdentifier: "FavoriteCell")
        self.getFavoriteVideo()
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
    }
    
    @objc func closeButtonTapped() {
        self.delegate?.startAllPanel()
        self.dismiss(animated: true)
    }
    
    func getFavoriteVideo() {
        self.arrFavoriteVideoData = CoreDataManager.shared.getAllFavoriteVideos()
        self.collectionViewFavorite.reloadData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIApplication.shared.topViewController() is FavoriteViewController {
            self.collectionViewFavorite.reloadData()
        }
    }
}

extension FavoriteViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrFavoriteVideoData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCell", for: indexPath) as! FavoriteCell
        cell.setupCell()
        cell.setThumbnailImageOfVideo(videoAsset: self.arrFavoriteVideoData[indexPath.row])
        cell.btnFavorite?.addTarget(self, action: #selector(removeFavorite), for: .touchUpInside)
        
        return cell
    }
    
    @objc func removeFavorite(sender: UIButton) {
        let index = sender.tag
        
    }
}

extension FavoriteViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if Utility.getDeviceOrientation().isLandscape {
            // Calculate the size of each cell based on the collectionView width and number of cells per row (3)
            let cellWidth = (collectionView.bounds.width - 30) / 3.0 // Subtract 30 to consider 10px spacing on both sides and 10px spacing between cells
            let cellHeight = (collectionView.bounds.height - 25) / 2.0// Subtract 25 to consider 10px spacing on top and bottom and 5px spacing between cells
            //print("Cell size: ", CGSize(width: cellWidth, height: cellHeight))
            print("Cell size isLandscape: \(CGSize(width: cellWidth, height: cellHeight))")
            return CGSize(width: cellWidth, height: cellHeight)
        }
        else {
            // Calculate the size of each cell based on the collectionView width and number of cells per row (3)
            let cellWidth = (collectionView.bounds.width - 30) / 3.0 // Subtract 30 to consider 10px spacing on both sides and 10px spacing between cells
            let cellHeight = (collectionView.bounds.height - 25) / 2.0// Subtract 25 to consider 10px spacing on top and bottom and 5px spacing between cells
            //print("Cell size: ", CGSize(width: cellWidth, height: cellHeight))
            print("Cell size isPortrait: \(CGSize(width: cellWidth, height: cellHeight))")
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
