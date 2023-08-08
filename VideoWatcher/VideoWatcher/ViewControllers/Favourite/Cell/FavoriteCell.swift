//
//  FavoriteCell.swift
//  VideoWatcher
//
//  Created by MyMac on 08/08/23.
//

import UIKit
import AVFoundation

class FavoriteCell: UICollectionViewCell {

    var btnFavorite: UIButton?
    var imgThumbnail = UIImageView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupCell() {
        self.layoutIfNeeded()
        DispatchQueue.main.async {
            // Create the UIImageView
            if self.btnFavorite == nil {
                self.imgThumbnail.translatesAutoresizingMaskIntoConstraints = false
                self.imgThumbnail.contentMode = .scaleAspectFill
                self.addSubview(self.imgThumbnail)
                
                // Create constraints
                NSLayoutConstraint.activate([
                    self.imgThumbnail.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
                    self.imgThumbnail.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
                    self.imgThumbnail.topAnchor.constraint(equalTo: self.contentView.topAnchor),
                    self.imgThumbnail.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
                ])
                
                self.imgThumbnail.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
                self.imgThumbnail.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
                self.imgThumbnail.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
                self.imgThumbnail.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
                                
                self.btnFavorite = UIButton(frame: .zero)
                self.btnFavorite?.translatesAutoresizingMaskIntoConstraints = false
                self.btnFavorite?.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                self.btnFavorite?.tintColor = .systemPink
                self.addSubview(self.btnFavorite!)
                self.btnFavorite?.widthAnchor.constraint(equalToConstant: 30).isActive = true
                self.btnFavorite?.heightAnchor.constraint(equalToConstant: 30).isActive = true
                self.btnFavorite?.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
                self.btnFavorite?.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
                self.btnFavorite?.layer.shadowColor = UIColor.black.cgColor
                self.btnFavorite?.layer.shadowRadius = 1.0
                self.btnFavorite?.layer.shadowOpacity = 0.8
                self.btnFavorite?.layer.shadowOffset = CGSize(width: 0, height: 0)
                self.btnFavorite?.layer.masksToBounds = false
            }
        }
    }
    
    func setThumbnailImageOfVideo(videoAsset: VideoTable) {
        DispatchQueue.main.async {
            let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(videoAsset.videoURL ?? "")
            let asset = AVAsset(url: videoURL)
            if let thumbnailImage = asset.generateThumbnail() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    self.imgThumbnail.image = thumbnailImage
                    self.imgThumbnail.contentMode = .scaleAspectFill
                })
            }
        }
    }

}
