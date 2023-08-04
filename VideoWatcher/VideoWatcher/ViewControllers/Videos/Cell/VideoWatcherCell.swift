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
    //@IBOutlet weak var lblErrorMessage: UILabel!
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var index = Int()
    var lblError: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    /*func setupPlayer() {
        let player = AVPlayer()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer.addSublayer(playerLayer)
        self.player = player
        self.playerLayer = playerLayer
        
        self.lblError = UILabel(frame: CGRect(x: 10, y: bounds.height - 23, width: bounds.width - 20, height: 13))
        self.lblError?.textColor = UIColor(red: 202.0/255.0, green: 204.0/255.0, blue: 66.0/255.0, alpha: 1.0)
        self.lblError?.textAlignment = .left
        self.lblError?.font = .boldSystemFont(ofSize: 12.0)
//        self.lblError?.backgroundColor = .red
        self.lblError?.lineBreakMode = .byTruncatingMiddle
        self.addSubview(self.lblError!)
        
        self.lblError?.layer.shadowColor = UIColor.black.cgColor
        self.lblError?.layer.shadowRadius = 1.0
        self.lblError?.layer.shadowOpacity = 0.8
        self.lblError?.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.lblError?.layer.masksToBounds = false
    }*/
    
    func setupPlayer() {
        self.layoutIfNeeded()
        DispatchQueue.main.async {
            print("cell height: \(self.bounds.height), width: \(self.bounds.width)")
            /*
             let player = AVPlayer()
             let playerLayer = AVPlayerLayer(player: player)
             playerLayer.videoGravity = .resizeAspectFill
             playerLayer.frame = bounds
             layer.addSublayer(playerLayer)
             self.player = player
             self.playerLayer = playerLayer
             */
            
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
            }
            else {
                self.lblError?.frame = CGRect(x: 10, y: self.bounds.height - 23, width: self.bounds.width - 20, height: 13)
            }
            
            self.playerLayer?.frame = self.bounds
        }
    }
  
    func playVideo(videoAsset: String, startDuration: Double? = 0.0, firstLoad: Bool) {
        
        if let vidAsset = videoAsset as? PHAsset {
            
            PHCachingImageManager.default().requestAVAsset(forVideo: vidAsset, options: nil) { [weak self] (video, _, _) in
                if let video = video
                {
                    DispatchQueue.main.async {
                        let playerItem = AVPlayerItem(asset: video)
                        self?.player?.replaceCurrentItem(with: playerItem)
                        if startDuration ?? 0 > 0 {
                            let seekTime = CMTime(seconds: startDuration!, preferredTimescale: 1000)
                            self?.player?.seek(to: seekTime)
                        }
                        self?.player?.play()
                        self?.player?.isMuted = true
                        
                        if self?.player != nil && self?.player?.currentItem != nil {
                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self?.player?.currentItem, queue: nil) { (_) in
                                self?.delegate?.startNextRandomVideo(index: self?.index ?? 0)
                            }
                        }
                    }
                }
            }
            
            var videoName = ""
            let assetResources = PHAssetResource.assetResources(for: vidAsset)
            if let resource = assetResources.first {
                videoName = resource.originalFilename
                print("Panel \(index), Video Name: \(videoName)")
                DispatchQueue.main.async {
                    self.lblError?.text = "\(videoName)"
                }
            }
        }
        else {
            DispatchQueue.main.async {
                let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(videoAsset)                
                let playerItem = AVPlayerItem(url: videoURL)
                self.player?.replaceCurrentItem(with: playerItem)
                self.player?.play()
                self.player?.isMuted = true
                
                if self.player != nil && self.player?.currentItem != nil {
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil) { (_) in
                        self.delegate?.startNextRandomVideo(index: self.index)
                    }
                }
                
                print("Panel \(self.index), Video Name: \(videoURL.lastPathComponent)")
                self.lblError?.text = "\(videoURL.lastPathComponent)"
            }
        }
    }
    
//    func playVideo(videoAsset: Any, startDuration: Double? = 0.0, firstLoad: Bool) {
//
//        if let vidAsset = videoAsset as? PHAsset {
//
//            PHCachingImageManager.default().requestAVAsset(forVideo: vidAsset, options: nil) { [weak self] (video, _, _) in
//                if let video = video
//                {
//                    DispatchQueue.main.async {
//                        let playerItem = AVPlayerItem(asset: video)
//                        self?.player?.replaceCurrentItem(with: playerItem)
//                        if startDuration ?? 0 > 0 {
//                            let seekTime = CMTime(seconds: startDuration!, preferredTimescale: 1000)
//                            self?.player?.seek(to: seekTime)
//                        }
//                        self?.player?.play()
//                        self?.player?.isMuted = true
//
//                        if self?.player != nil && self?.player?.currentItem != nil {
//                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self?.player?.currentItem, queue: nil) { (_) in
//                                self?.delegate?.startNextRandomVideo(index: self?.index ?? 0)
//                            }
//                        }
//                    }
//                }
//            }
//
//            var videoName = ""
//            let assetResources = PHAssetResource.assetResources(for: vidAsset)
//            if let resource = assetResources.first {
//                videoName = resource.originalFilename
//                print("Panel \(index), Video Name: \(videoName)")
//                DispatchQueue.main.async {
//                    self.lblError?.text = "\(videoName)"
//                }
//            }
//        }
//        else {
//            if let videoURL = videoAsset as? URL {
//                DispatchQueue.main.async {
//                    let playerItem = AVPlayerItem(url: videoURL)
//                    self.player?.replaceCurrentItem(with: playerItem)
//                    self.player?.play()
//                    self.player?.isMuted = true
//
//                    if self.player != nil && self.player?.currentItem != nil {
//                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil) { (_) in
//                            self.delegate?.startNextRandomVideo(index: self.index)
//                        }
//                    }
//
//                    print("Panel \(self.index), Video Name: \(videoURL.lastPathComponent)")
//                    self.lblError?.text = "\(videoURL.lastPathComponent)"
//                }
//            }
//        }
//    }
}
