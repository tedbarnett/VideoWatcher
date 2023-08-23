//
//  FullscreenVideoViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 10/08/23.
//

import UIKit
import AVFoundation

protocol FullscreenVideoViewControllerDelegate: AnyObject {
    func startAllPanels()
}

class FullscreenVideoViewController: UIViewController {

    weak var delegate: FullscreenVideoViewControllerDelegate?
    @IBOutlet weak var viewPlayerContainer: UIView!
    @IBOutlet weak var viewButtonContainer: UIView!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var muteButton: UIButton!
    @IBOutlet var trimButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isMuted = false
    var videoAsset: VideoTable?
    var isClosedTap = false
    let gradientColors = [UIColor.black.withAlphaComponent(0.9), UIColor.clear]
    
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
                
        var frame = self.viewButtonContainer.frame
        frame.size.width = self.view.frame.size.width
        self.viewButtonContainer.frame = frame
        
        viewButtonContainer.applyBottomToTopGradient(colors: self.gradientColors)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewButtonTapped))
        viewPlayerContainer.addGestureRecognizer(tapGesture)
    }
    
    @objc func viewButtonTapped() {
        if viewButtonContainer.alpha == 1.0 {
            // Fade out animation
            UIView.animate(withDuration: 0.2) {
                self.viewButtonContainer.alpha = 0.0
                self.closeButton.alpha = 0.0
                self.muteButton.alpha = 0.0
                self.trimButton.alpha = 0.0
            }
        } else {
            // Fade in animation
            UIView.animate(withDuration: 0.2) {
                self.viewButtonContainer.alpha = 1.0
                self.closeButton.alpha = 1.0
                self.muteButton.alpha = 1.0
                self.trimButton.alpha = 1.0
            }
        }
    }
    
    func setupNavbar() {
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.hidesBackButton = true
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.delegate?.startAllPanels()
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
            
            self.muteButton.isSelected = self.isMuted
            self.playPauseButton.isSelected = true
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
    }
    
    // MARK: Trim Button Action
    
    @IBAction func trimButtonTapped(_ sender: UIButton) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateClipViewController") as! CreateClipViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .crossDissolve
        //navController.navigationBar.isHidden = true
        vc.videoAsset = videoAsset
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
    
    // MARK: Deinitialization
    
    deinit {
        player?.removeObserver(self, forKeyPath: "rate")
    }

}
