//
//  FavoriteCell.swift
//  VideoWatcher
//
//  Created by MyMac on 08/08/23.
//

import UIKit
import AVFoundation

class FavoriteCell: UICollectionViewCell {

    var imgThumbnail = UIImageView()
    let btnPlay: UIButton = {
        let button = UIButton()
        button.tintColor = .white
        button.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal) // Set your play button image here
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupCell() {
        self.layoutIfNeeded()
        DispatchQueue.main.async {
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
            
            self.addSubview(self.btnPlay)
            NSLayoutConstraint.activate([
                self.btnPlay.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                self.btnPlay.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                self.btnPlay.widthAnchor.constraint(equalToConstant: 50), // Set your desired width
                self.btnPlay.heightAnchor.constraint(equalToConstant: 50) // Set your desired height
            ])
            self.btnPlay.layer.shadowColor = UIColor.black.cgColor
            self.btnPlay.layer.shadowRadius = 4.0
            self.btnPlay.layer.shadowOpacity = 1.0
            self.btnPlay.layer.shadowOffset = CGSize(width: 0, height: 0)
            self.btnPlay.layer.masksToBounds = false
        }
    }
}
