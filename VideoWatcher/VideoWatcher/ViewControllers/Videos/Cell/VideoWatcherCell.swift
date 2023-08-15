//
//  VideoWatcherCell.swift
//  VideoWatcher
//
//  Created by MyMac on 01/08/23.
//

import UIKit
import AVFoundation
import Photos

protocol VideoWatcherCellDelegate: AnyObject {
    func startNextRandomVideo(index: Int)
}

class VideoWatcherCell: UICollectionViewCell {
    
    weak var delegate: VideoWatcherCellDelegate?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var index = Int()
    var lblError: UILabel?
    var btnFavorite = UIButton()
    var btnSpeaker = UIButton()
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    func setupPlayer() {
        self.layoutIfNeeded()
        DispatchQueue.main.async {
            if self.player == nil && self.playerLayer == nil {
                self.player = AVPlayer()
                self.playerLayer = AVPlayerLayer(player: self.player)
                self.playerLayer?.videoGravity = .resizeAspectFill
                self.playerLayer?.frame = self.bounds
                self.layer.addSublayer(self.playerLayer!)
                
                self.lblError = UILabel(frame: CGRect(x: 10, y: self.bounds.height - 23, width: self.bounds.width - 20, height: 13))
                self.lblError?.textColor = UIColor(red: 202.0/255.0, green: 204.0/255.0, blue: 66.0/255.0, alpha: 1.0)
                self.lblError?.layer.shadowColor = UIColor.black.cgColor
                self.lblError?.layer.shadowRadius = 1.0
                self.lblError?.layer.shadowOpacity = 0.8
                self.lblError?.layer.shadowOffset = CGSize(width: 0, height: 0)
                self.lblError?.layer.masksToBounds = false
                
                self.lblError?.textAlignment = .left
                self.lblError?.font = .boldSystemFont(ofSize: 12.0)
                self.lblError?.lineBreakMode = .byTruncatingMiddle
                self.addSubview(self.lblError!)
                
                self.btnFavorite.translatesAutoresizingMaskIntoConstraints = false
                self.btnFavorite.setImage(UIImage(systemName: "heart"), for: .normal)
                self.btnFavorite.tintColor = .white
                self.addSubview(self.btnFavorite)
                self.btnFavorite.widthAnchor.constraint(equalToConstant: 30).isActive = true
                self.btnFavorite.heightAnchor.constraint(equalToConstant: 30).isActive = true
                self.btnFavorite.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
                self.btnFavorite.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
                self.btnFavorite.layer.shadowColor = UIColor.black.cgColor
                self.btnFavorite.layer.shadowRadius = 1.0
                self.btnFavorite.layer.shadowOpacity = 0.8
                self.btnFavorite.layer.shadowOffset = CGSize(width: 0, height: 0)
                self.btnFavorite.layer.masksToBounds = false
                
                self.btnSpeaker.translatesAutoresizingMaskIntoConstraints = false
                self.btnSpeaker.setImage(UIImage(systemName: "speaker.wave.2"), for: .normal)
                self.btnSpeaker.tintColor = .red
                self.addSubview(self.btnSpeaker)
                self.btnSpeaker.widthAnchor.constraint(equalToConstant: 30).isActive = true
                self.btnSpeaker.heightAnchor.constraint(equalToConstant: 30).isActive = true
                self.btnSpeaker.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
                self.btnSpeaker.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
                self.btnSpeaker.layer.shadowColor = UIColor.black.cgColor
                self.btnSpeaker.layer.shadowRadius = 1.0
                self.btnSpeaker.layer.shadowOpacity = 0.9
                self.btnSpeaker.layer.shadowOffset = CGSize(width: 0, height: 0)
                self.btnSpeaker.layer.masksToBounds = false
                self.btnSpeaker.isHidden = true
            }
            else {
                self.lblError?.frame = CGRect(x: 10, y: self.bounds.height - 23, width: self.bounds.width - 20, height: 13)
            }
            
            self.playerLayer?.frame = self.bounds
        }
    }
    
    func playVideo(videoAsset: VideoTable, startDuration: Double? = 0.0, isMuted: Bool) {
        DispatchQueue.main.async {
            let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(videoAsset.videoURL ?? "")
            let playerItem = AVPlayerItem(url: videoURL)
            self.player?.replaceCurrentItem(with: playerItem)
            self.player?.play()
            //self.player?.isMuted = true
            self.player?.isMuted = isMuted
            
            if self.player != nil && self.player?.currentItem != nil {
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil) { (_) in
                    self.delegate?.startNextRandomVideo(index: self.index)
                }
            }
            
            if isMuted {
                self.btnSpeaker.isHidden = true
            }
            else {
                self.btnSpeaker.isHidden = false
            }
            
            if videoAsset.isFavorite {
                self.btnFavorite.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                self.btnFavorite.tintColor = .red
            }
            else {
                if (videoAsset.clips?.count ?? 0) > 0 {
                    self.btnFavorite.setImage(UIImage(named: "img_heart_bunch"), for: .normal)
                    self.btnFavorite.tintColor = .white
                }
                else {
                    self.btnFavorite.setImage(UIImage(systemName: "heart"), for: .normal)
                    self.btnFavorite.tintColor = .white
                }
            }
                                    
            print("Panel \(self.index), Video Name: \(videoURL.lastPathComponent)")
            self.lblError?.text = "\(videoURL.lastPathComponent)"
        }
    }
    
    func setSpeakerMuteUnmute(indexToChange: Int) {
        if indexToChange == 0 && AppData.shared.panel1IsMute == false {
            self.btnSpeaker.isHidden = false
        }
        else if indexToChange == 1 && AppData.shared.panel2IsMute == false {
            self.btnSpeaker.isHidden = false
        }
        else if indexToChange == 2 && AppData.shared.panel3IsMute == false {
            self.btnSpeaker.isHidden = false
        }
        else if indexToChange == 3 && AppData.shared.panel4IsMute == false {
            self.btnSpeaker.isHidden = false
        }
        else if indexToChange == 4 && AppData.shared.panel5IsMute == false {
            self.btnSpeaker.isHidden = false
        }
        else if indexToChange == 5 && AppData.shared.panel6IsMute == false {
            self.btnSpeaker.isHidden = false
        }
    }
}
