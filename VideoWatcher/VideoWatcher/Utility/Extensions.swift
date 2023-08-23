//
//  Extensions.swift
//  VideoWatcher
//
//  Created by MyMac on 07/08/23.
//

import Foundation
import AVFoundation
import UIKit

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

extension UIApplication {
    func topViewController() -> UIViewController? {
        var topViewController: UIViewController? = nil
        if #available(iOS 13, *) {
            for scene in self.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        if window.isKeyWindow {
                            topViewController = window.rootViewController
                        }
                    }
                }
            }
        } else {
            topViewController = keyWindow?.rootViewController
        }
        while true {
            if let presented = topViewController?.presentedViewController {
                topViewController = presented
            } else if let navController = topViewController as? UINavigationController {
                topViewController = navController.topViewController
            } else if let tabBarController = topViewController as? UITabBarController {
                topViewController = tabBarController.selectedViewController
            } else {
                // Handle any other third party container in `else if` if required
                break
            }
        }
        return topViewController
    }
}

extension AVAsset {
    func generateThumbnail(at time: CMTime = CMTime.zero) -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: self)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnailImage = UIImage(cgImage: thumbnailCGImage)
            
            return thumbnailImage
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    var fullRange: CMTimeRange {
        return CMTimeRange(start: .zero, duration: duration)
    }
    
    func trimmedComposition(_ range: CMTimeRange) -> AVAsset {
        guard CMTimeRangeEqual(fullRange, range) == false else {return self}

        let composition = AVMutableComposition()
        try? composition.insertTimeRange(range, of: self, at: .zero)

        if let videoTrack = tracks(withMediaType: .video).first {
            composition.tracks.forEach {$0.preferredTransform = videoTrack.preferredTransform}
        }
        return composition
    }
}

extension UIView {
    func applyBottomToTopGradient(colors: [UIColor]) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

extension CMTime {
    var displayString: String {
        let offset = TimeInterval(seconds)
        let numberOfNanosecondsFloat = (offset - TimeInterval(Int(offset))) * 1000.0
        let nanoseconds = Int(numberOfNanosecondsFloat)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return String(format: "%@.%03d", formatter.string(from: offset) ?? "00:00", nanoseconds)
    }
    
    var displaySeconds: String {
        let offset = seconds
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(from: offset) ?? "00:00"
    }
    
    var displayStringWithHours: String {
        let offset = seconds
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: offset) ?? "00:00:00"
    }
    
    var displayTotalSeconds: String {
        let totalSeconds = Int(seconds)
        return String(totalSeconds)
    }
}

extension UIViewController {
    func showAlert(title: String, message: String, completion:@escaping (_ result:Bool) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { action in
            completion(true)
        }
        alert.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}

extension UIActivityIndicatorView {
    func setColor(_ color: UIColor) {
        if self.style == .medium {
            // For the medium style, you might need to set the color to both the color property and the tintColor
            self.color = color
            self.tintColor = color
        } else {
            // For other styles, just set the color property
            self.color = color
        }
    }
}
