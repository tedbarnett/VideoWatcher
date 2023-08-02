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
    
    func setupPlayer() {
        let player = AVPlayer()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer.addSublayer(playerLayer)
        self.player = player
        self.playerLayer = playerLayer
        
        self.lblError = UILabel(frame: bounds)
        self.lblError?.textColor = .green
        self.lblError?.textAlignment = .left
        self.lblError?.numberOfLines = 0
        self.addSubview(self.lblError!)
    }
    
    func playVideo(videoAsset: Any) {
        
        if let vidAsset = videoAsset as? PHAsset {
            
            PHCachingImageManager.default().requestAVAsset(forVideo: vidAsset, options: nil) { [weak self] (video, _, _) in
                if let video = video
                {
                    DispatchQueue.main.async {
                        let playerItem = AVPlayerItem(asset: video)
                        self?.player?.replaceCurrentItem(with: playerItem)
                        self?.player?.play()
                        self?.player?.isMuted = true
                        
                        if self?.player != nil && self?.player?.currentItem != nil {
                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self?.player?.currentItem, queue: nil) { (_) in
                                self?.delegate?.startNextRandomVideo(index: self?.index ?? 0)
                            }
                        }
                    }
                }
                else {
                    var videoName = ""
                    let assetResources = PHAssetResource.assetResources(for: vidAsset)
                    if let resource = assetResources.first {
                        videoName = resource.originalFilename
                        print("Video Name: \(videoName)")
                        DispatchQueue.main.async {
                            self?.lblError?.text = "Error in playing video: \(videoName)"
                        }
                    }
                }
            }
        }
        else {
            if let videoURL = videoAsset as? URL {
                DispatchQueue.main.async {
                    let playerItem = AVPlayerItem(url: videoURL)
                    self.player?.replaceCurrentItem(with: playerItem)
                    self.player?.play()
                    self.player?.isMuted = true
                    
                    if self.player != nil && self.player?.currentItem != nil {
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil) { (_) in
                            self.delegate?.startNextRandomVideo(index: self.index)
                        }
                    }
                }
            }
        }
        
    }
}
