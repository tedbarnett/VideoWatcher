//
//  VideoListCell.swift
//  VideoWatcher
//
//  Created by MyMac on 02/11/23.
//

import UIKit
import AVFoundation

class VideoListCell: UITableViewCell {
    
    @IBOutlet weak var imgThumb: UIImageView!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var lblClipName: UILabel!
    @IBOutlet weak var lblDuration: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell() {
        self.imgThumb.layer.cornerRadius = 4.0
        self.imgThumb.layer.masksToBounds = true
        
        self.btnPlay.layer.shadowColor = UIColor.black.cgColor
        self.btnPlay.layer.shadowRadius = 4.0
        self.btnPlay.layer.shadowOpacity = 1.0
        self.btnPlay.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.btnPlay.layer.masksToBounds = false
    }
    
    func formatTime(duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        var formattedTime = ""
        if hours > 0 {
            formattedTime += String(format: "%02d:", hours)
        }
        
        formattedTime += String(format: "%02d:%02d", minutes, seconds)
        
        return formattedTime
    }
    
    func getVideoThumbnail(url: URL) -> UIImage? {
        //let url = url as URL
        let request = URLRequest(url: url)
        let cache = URLCache.shared
        
        if let cachedResponse = cache.cachedResponse(for: request), let image = UIImage(data: cachedResponse.data) {
            return image
        }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 250, height: 120)
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        var image: UIImage?
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            image = UIImage(cgImage: cgImage)
        } catch { }
        
        if let image = image, let data = image.pngData(), let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) {
            let cachedResponse = CachedURLResponse(response: response, data: data)
            cache.storeCachedResponse(cachedResponse, for: request)
        }
        
        return image
    }
}
