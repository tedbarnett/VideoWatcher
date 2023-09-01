//
//  FullscreenVideoViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 10/08/23.
//

import UIKit
import AVFoundation

protocol FullscreenVideoViewControllerDelegate: AnyObject {
    func startAllPanels(index: Int, currentTime: CMTime)
    func setVolumeFor(index: Int)
    func deleteVideo(index: Int)
}

class FullscreenVideoViewController: UIViewController {

    weak var delegate: FullscreenVideoViewControllerDelegate?
    @IBOutlet weak var viewPlayerContainer: UIView!
    @IBOutlet weak var viewButtonContainer: UIView!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var muteButton: UIButton!
    @IBOutlet var trimButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var btnGoBackward30: UIButton!
    @IBOutlet weak var btnGoForward30: UIButton!
    @IBOutlet weak var playerProgress: UISlider!
    @IBOutlet weak var lblTime: UILabel!
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isMuted = false
    var videoAsset: VideoTable?
    var isClosedTap = false
    let gradientColors = [UIColor.black.withAlphaComponent(0.9), UIColor.clear]
    var index = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isClosedTap {
            self.deallocatePlayer()
        }
        else {
            player?.pause()
        }
    }
    
    func deallocatePlayer() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        if self.player != nil {
            self.player?.replaceCurrentItem(with: nil)
            self.player?.pause()
            self.player = nil
        }
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer = nil
        self.viewPlayerContainer.layer.sublayers?.removeAll()
        self.viewPlayerContainer.layer.sublayers = nil
    }
    
    func setupUI() {
        self.setupNavbar()
        self.setupPlayer()
        self.applyShadowToButtons(view: muteButton)
        self.applyShadowToButtons(view: playPauseButton)
        self.applyShadowToButtons(view: trimButton)
        self.applyShadowToButtons(view: closeButton)
        self.applyShadowToButtons(view: btnGoForward30)
        self.applyShadowToButtons(view: btnGoBackward30)
                
        var frame = self.viewButtonContainer.frame
        frame.size.width = self.view.frame.size.width
        self.viewButtonContainer.frame = frame
        
        viewButtonContainer.applyBottomToTopGradient(colors: self.gradientColors)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewButtonTapped))
        viewPlayerContainer.addGestureRecognizer(tapGesture)
        
        let thumbSize = CGSize(width: 20, height: 20) // Adjust the size as needed
        if let thumbImage = createThumbImage(size: thumbSize, color: .white) {
            // Set the custom thumb image
            self.playerProgress.setThumbImage(thumbImage, for: .normal)
        }
    }
    
    @objc func viewButtonTapped() {
        if viewButtonContainer.alpha == 1.0 {
            // Fade out animation
            UIView.animate(withDuration: 0.2) {
                self.viewButtonContainer.alpha = 0.0
                self.closeButton.alpha = 0.0
                self.muteButton.alpha = 0.0
                self.trimButton.alpha = 0.0
                self.btnGoBackward30.alpha = 0.0
                self.btnGoForward30.alpha = 0.0
                self.playPauseButton.alpha = 0.0
            }
        } else {
            // Fade in animation
            UIView.animate(withDuration: 0.2) {
                self.viewButtonContainer.alpha = 1.0
                self.closeButton.alpha = 1.0
                self.muteButton.alpha = 1.0
                self.trimButton.alpha = 1.0
                self.btnGoBackward30.alpha = 1.0
                self.btnGoForward30.alpha = 1.0
                self.playPauseButton.alpha = 1.0
            }
        }
    }
    
    func setupNavbar() {
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.hidesBackButton = true
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.delegate?.startAllPanels(index: self.index, currentTime: self.player?.currentTime() ?? .zero)
        self.isClosedTap = true
        self.dismiss(animated: true)
    }
    
    func applyShadowToButtons(view: UIButton) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 1.0
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.masksToBounds = false
    }
    
    func setupPlayer() {
        // Replace with your video file URL
        DispatchQueue.main.async {
            
            let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(self.videoAsset?.videoURL ?? "")
            self.player = AVPlayer(url: videoURL)
            self.playerLayer = AVPlayerLayer(player: self.player)
            self.playerLayer?.videoGravity = .resizeAspect
            self.playerLayer?.frame = self.viewPlayerContainer.bounds
            self.viewPlayerContainer.layer.addSublayer(self.playerLayer!)
            
            // Observe playback status to update play/pause button
            self.player?.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
            self.player?.isMuted = self.isMuted
            // Start playing
            self.player?.play()
            // Observe the AVPlayerItemDidPlayToEndTime notification
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.playerDidFinishPlaying),
                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                   object: self.player?.currentItem)
            
            self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] time in
                self?.updateTimeLabel(currentTime: time)
            }
            
            self.muteButton.isSelected = self.isMuted
            self.playPauseButton.isSelected = true
            
            self.updateTimeLabel(currentTime: .zero)
            
            self.playerProgress.addTarget(self, action: #selector(self.sliderValueChanged(_:)), for: .valueChanged)

            let interaction = UIContextMenuInteraction(delegate: self)
            self.viewPlayerContainer.addInteraction(interaction)
        }
    }
    
    @objc func playerDidFinishPlaying() {
        player?.seek(to: CMTime.zero)
        playPauseButton.isSelected = false // Set play button state to not playing
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.view.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.viewPlayerContainer.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
            self.playerLayer?.frame = self.viewPlayerContainer.bounds
            
            var frame = self.viewButtonContainer.frame
            frame.size.width = size.width
            self.viewButtonContainer.frame = frame
            self.viewButtonContainer.layer.sublayers?.forEach { layer in
                if layer is CAGradientLayer {
                    layer.removeFromSuperlayer()
                }
            }
            
            self.viewButtonContainer.applyBottomToTopGradient(colors: self.gradientColors)
        })
    }
    
    // MARK: Play/Pause Button Action
    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        if player?.rate == 0 {
            player?.play()
        } else {
            player?.pause()
        }
    }
    
    // MARK: Mute/Unmute Button Action
    @IBAction func muteButtonTapped(_ sender: UIButton) {
        player?.isMuted.toggle()
        sender.isSelected = player?.isMuted ?? false
        self.delegate?.setVolumeFor(index: self.index)
    }
    
    // MARK: Trim Button Action
    @IBAction func trimButtonTapped(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateClipViewController") as! CreateClipViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .crossDissolve
        //navController.navigationBar.isHidden = true
        vc.videoAsset = videoAsset
        vc.startTime = player?.currentTime()
        vc.totalDuration = player?.currentItem?.duration
        self.present(navController, animated: true)
    }
    
    // MARK: Key-Value Observing
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            //print("player?.rate: \(player?.rate)")
            let isPlaying = player?.rate != 0
            playPauseButton.isSelected = isPlaying
        }
    }
    
    // MARK: Functions to update the time label and progress slider
    func updateTimeLabel(currentTime: CMTime) {
        let totalDuration = player?.currentItem?.duration ?? .zero
        let currentTimeText = formatTime(currentTime)
        let totalDurationText = formatTime(totalDuration)
        
        self.lblTime.text = "\(currentTimeText) / \(totalDurationText)"
        
        if totalDuration != .zero {
            let progress = Float(currentTime.seconds / totalDuration.seconds)
            self.playerProgress.value = progress
        }
    }
    
    // Function to format time
    func formatTime(_ time: CMTime) -> String {
        guard time.isValid && !time.isIndefinite && !time.isNegativeInfinity && !time.isPositiveInfinity else {
            return "00:00"
        }
        
        let totalSeconds = Int(time.seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // Function to update player time based on slider value
    @objc func sliderValueChanged(_ sender: UISlider) {
        let duration = player?.currentItem?.duration ?? .zero
        let seekTime = CMTime(seconds: Double(sender.value) * duration.seconds, preferredTimescale: 1)
        player?.seek(to: seekTime)
    }
    
    @IBAction func btnGoBackward30Action(_ sender: Any) {
        self.skipTime(seconds: -30)
    }
    
    @IBAction func btnGoForward30Action(_ sender: Any) {
        self.skipTime(seconds: 30)
    }
    
    // Function to skip player time
    func skipTime(seconds: Double) {
        let currentTime = player?.currentTime() ?? .zero
        let newTime = CMTime(seconds: currentTime.seconds + seconds, preferredTimescale: 1)
        player?.seek(to: newTime)
    }
    
    func createThumbImage(size: CGSize, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.addEllipse(in: CGRect(origin: CGPoint.zero, size: size))
        context?.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.withRenderingMode(.alwaysOriginal)
    }
    
    // MARK: Deinitialization
    deinit {
        player?.removeObserver(self, forKeyPath: "rate")
    }
}

extension FullscreenVideoViewController: UIContextMenuInteractionDelegate {
      func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                
                self.showDeleteConfirmation()
            }
            return UIMenu(title: "", children: [delete])
        }
    }
    
    //MARK: - Delete menu actions
    @objc func showDeleteConfirmation() {
        let alertController = UIAlertController(
            title: "Delete video",
            message: "This video will be removed from this application. Are you sure you want to delete?",
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Delete video", style: .destructive) { _ in
            // Performing the delete action
            self.dismiss(animated: true, completion: {
                self.isClosedTap = true
                self.delegate?.deleteVideo(index: self.index)
                self.delegate?.startAllPanels(index: self.index, currentTime: .zero)
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            // Set the source view for iPad and other devices with popover support
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
