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
    }
    
    func playVideo(videoAsset: PHAsset) {
        PHCachingImageManager.default().requestAVAsset(forVideo: videoAsset, options: nil) { [weak self] (video, _, _) in
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
        }
    }
}
