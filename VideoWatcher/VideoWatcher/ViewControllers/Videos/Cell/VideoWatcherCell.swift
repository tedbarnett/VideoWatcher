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
    func startNextRandomVideo(index: Int, isRandom: Bool)
    func startPreviousVideo(index: Int)
}

class VideoWatcherCell: UICollectionViewCell {
    
    weak var delegate: VideoWatcherCellDelegate?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var index = Int()
    var lblError: UILabel?
    var btnFavorite = UIButton()
    var btnSpeaker = UIButton()
    
    var slidingAnimation: CATransition = {
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromRight
        transition.duration = 0.5
        return transition
    }()
    
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
                
                // Add swipe gesture recognizers
                let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
                leftSwipe.direction = .left
                self.addGestureRecognizer(leftSwipe)
                
                let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
                rightSwipe.direction = .right
                self.addGestureRecognizer(rightSwipe)
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
                    self.delegate?.startNextRandomVideo(index: self.index, isRandom: true)
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
                if let clipsSet = videoAsset.clips {
                    var totalClips: [VideoClip] = []
                    let clipsArray = clipsSet.allObjects as? [VideoClip] ?? []
                    for clip in clipsArray {
                        // Now you have an array of VideoClip objects
                        print("Clip URL: \(clip.clipURL ?? "")")
                        if clip.is_Deleted == false {
                            totalClips.append(clip)
                        }
                    }
                    
                    if totalClips.count > 0 {
                        self.btnFavorite.setImage(UIImage(named: "img_heart_bunch"), for: .normal)
                        self.btnFavorite.tintColor = .white
                    }
                    else {
                        self.btnFavorite.setImage(UIImage(systemName: "heart"), for: .normal)
                        self.btnFavorite.tintColor = .white
                    }
                }
                else {
                    self.btnFavorite.setImage(UIImage(systemName: "heart"), for: .normal)
                    self.btnFavorite.tintColor = .white
                }
                /*if (videoAsset.clips?.count ?? 0) > 0 {
                    self.btnFavorite.setImage(UIImage(named: "img_heart_bunch"), for: .normal)
                    self.btnFavorite.tintColor = .white
                }
                else {
                    self.btnFavorite.setImage(UIImage(systemName: "heart"), for: .normal)
                    self.btnFavorite.tintColor = .white
                }*/
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
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left {
            self.delegate?.startNextRandomVideo(index: self.index, isRandom: false)
            animateSlidingEffect(.fromRight)
        } else if gesture.direction == .right {
            if self.checkPreviousVideoAvailable() {
                self.delegate?.startPreviousVideo(index: self.index)
                animateSlidingEffect(.fromLeft)
            }
        }
    }
    
    func checkPreviousVideoAvailable() -> Bool {
        if self.index == 0 {
            if AppData.shared.panel1PreviousVideosIndexCopy >= 0 {
                return true
            }
            else {
                print("PREV: No previous video for panel: \(self.index)")
                return false
            }
        }
        else if self.index == 1 {
            if AppData.shared.panel2PreviousVideosIndexCopy >= 0 {
                return true
            }
            else {
                print("PREV: No previous video for panel: \(self.index)")
                return false
            }
        }
        else if self.index == 2 {
            if AppData.shared.panel3PreviousVideosIndexCopy >= 0 {
                return true
            }
            else {
                print("PREV: No previous video for panel: \(self.index)")
                return false
            }
        }
        else if self.index == 3 {
            if AppData.shared.panel4PreviousVideosIndexCopy >= 0 {
                return true
            }
            else {
                print("PREV: No previous video for panel: \(self.index)")
                return false
            }
        }
        else if self.index == 4 {
            if AppData.shared.panel5PreviousVideosIndexCopy >= 0 {
                return true
            }
            else {
                print("PREV: No previous video for panel: \(self.index)")
                return false
            }
        }
        else if self.index == 5 {
            if AppData.shared.panel6PreviousVideosIndexCopy >= 0 {
                return true
            }
            else
            {
                print("PREV: No previous video for panel: \(self.index)")
                return false
            }
        }
        return false
    }
    
    func animateSlidingEffect(_ subtype: CATransitionSubtype) {
        slidingAnimation.subtype = subtype
        playerLayer?.add(slidingAnimation, forKey: "transition")
    }
}
