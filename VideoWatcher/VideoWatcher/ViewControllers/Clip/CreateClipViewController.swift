//
//  CreateClipViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 10/08/23.
//

import UIKit
import AVKit
import Photos

protocol CreateClipViewControllerDelegate: AnyObject {
    func startAllPanelsFromClips()
}

class CreateClipViewController: UIViewController {
    
    weak var delegate: CreateClipViewControllerDelegate?
    let playerController = AVPlayerViewController()
    var trimmer: VideoTrimmer!
    var timingStackView: UIStackView!
    var leadingTrimLabel: UILabel!
    var currentTimeLabel: UILabel!
    var trailingTrimLabel: UILabel!
    
    private var wasPlaying = false
    private var player: AVPlayer! {playerController.player}
    private var asset: AVAsset!
    var videoAsset: VideoTable?
    var finalTrimmedAsset: AVAsset?
    var isFromHome = false

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
    }
    
    private func setupView() {
        
        self.setupNavigationBar()
        let videoURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedVideos)!.appendingPathComponent(videoAsset?.videoURL ?? "")
        asset = AVURLAsset(url: videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])

        leadingTrimLabel = UILabel()
        leadingTrimLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        leadingTrimLabel.textAlignment = .left
        leadingTrimLabel.textColor = .white

        currentTimeLabel = UILabel()
        currentTimeLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        currentTimeLabel.textAlignment = .center
        currentTimeLabel.textColor = .white

        trailingTrimLabel = UILabel()
        trailingTrimLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        trailingTrimLabel.textAlignment = .right
        trailingTrimLabel.textColor = .white

        timingStackView = UIStackView(arrangedSubviews: [leadingTrimLabel, currentTimeLabel, trailingTrimLabel])
        timingStackView.axis = .horizontal
        timingStackView.alignment = .fill
        timingStackView.distribution = .fillEqually
        timingStackView.spacing = UIStackView.spacingUseSystem
        view.addSubview(timingStackView)
        timingStackView.translatesAutoresizingMaskIntoConstraints = false
       
        NSLayoutConstraint.activate([
            timingStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            timingStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            timingStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10), // Adjust spacing
        ])
        
        // THIS IS WHERE WE SETUP THE VIDEOTRIMMER:
        trimmer = VideoTrimmer()
        trimmer.minimumDuration = CMTime(seconds: 1, preferredTimescale: 600)
        trimmer.addTarget(self, action: #selector(didBeginTrimming(_:)), for: VideoTrimmer.didBeginTrimming)
        trimmer.addTarget(self, action: #selector(didEndTrimming(_:)), for: VideoTrimmer.didEndTrimming)
        trimmer.addTarget(self, action: #selector(selectedRangeDidChanged(_:)), for: VideoTrimmer.selectedRangeChanged)
        trimmer.addTarget(self, action: #selector(didBeginScrubbing(_:)), for: VideoTrimmer.didBeginScrubbing)
        trimmer.addTarget(self, action: #selector(didEndScrubbing(_:)), for: VideoTrimmer.didEndScrubbing)
        trimmer.addTarget(self, action: #selector(progressDidChanged(_:)), for: VideoTrimmer.progressChanged)
        view.addSubview(trimmer)
        trimmer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            trimmer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            trimmer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            trimmer.bottomAnchor.constraint(equalTo: timingStackView.topAnchor, constant: -10), // Adjust spacing
            trimmer.heightAnchor.constraint(equalToConstant: 50),
        ])

        playerController.player = AVPlayer()
        
        addChild(playerController)
        view.addSubview(playerController.view)
        playerController.view.translatesAutoresizingMaskIntoConstraints = false
       
        NSLayoutConstraint.activate([
            playerController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerController.view.bottomAnchor.constraint(equalTo: trimmer.topAnchor, constant: -10),
        ])

        trimmer.asset = asset
        updatePlayerAsset()

        player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: .main) { [weak self] time in
            guard let self = self else {return}
            // when we're not trimming, the players starting point is actual later than the trimmer,
            // (because the vidoe has been trimmed), so we need to account for that.
            // When we're trimming, we always show the full video
            let finalTime = self.trimmer.trimmingState == .none ? CMTimeAdd(time, self.trimmer.selectedRange.start) : time
            self.trimmer.progress = finalTime
        }

        updateLabels()
    }
    
    func setupNavigationBar() {
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.isHidden = false
        navigationItem.hidesBackButton = true
        self.setupMenuButton()
    }
    
    func setupMenuButton() {
        let closeButton = UIButton(type: .system)
        closeButton.tintColor = .white
        closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
        
        let generateClip = UIButton(type: .system)
        generateClip.tintColor = .white
        generateClip.setTitle("Save clip", for: .normal)
        generateClip.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: generateClip)
    }
    
    @objc func closeButtonTapped() {
        if self.isFromHome {
            self.delegate?.startAllPanelsFromClips()
        }
        self.dismiss(animated: true)
    }
    
    @objc func generateButtonTapped() {
        self.showAlertWithTextField()
    }
    
    func showAlertWithTextField() {
        let alertController = UIAlertController(title: "Name for this clip?", message:  nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Clip name"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let name = alertController.textFields?.first?.text, !name.isEmpty {
                // Valid text entered, perform your action here
                print("Text name: \(name)")
                self?.saveClip(clipName: name)
            } else {
                // Blank text entered, showing an error message
                self?.showValidationError()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    func showValidationError() {
        let validationAlert = UIAlertController(title: "Error", message: "Please enter valid name.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.showAlertWithTextField()
        }
        validationAlert.addAction(okAction)
        present(validationAlert, animated: true)
    }
    
    // MARK: - Input
    func saveClip(clipName: String) {
        // Create a temporary directory URL
        
        guard let avAsset = self.finalTrimmedAsset else {
            print("AVAsset is nil")
            return
        }
        
        if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.SavedClips) {
            let destinationURL = directoryURL.appendingPathComponent("\(clipName).mp4")
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                self.showAlert(title: "Clip name already exist", message: "Please choose another name") { result in
                    self.showAlertWithTextField()
                }
            }
            else {
                // Export the AVAsset to the temporary file
                let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality)
                exportSession?.outputURL = destinationURL
                exportSession?.outputFileType = .mp4
                
                exportSession?.exportAsynchronously(completionHandler: {
                    switch exportSession?.status {
                    case .completed:
                        print("Export completed")
                        //CoreDataManager.shared.saveClip(clipURL: destinationURL.lastPathComponent, videoAsset: self.videoAsset!)
                        print("clip saved to document directory path: \(destinationURL)")
                        
                        if let directoryThumbURL = Utility.getDirectoryPath(folderName: DirectoryName.Thumbnails) {
                            let destinationThumbURL = directoryThumbURL.appendingPathComponent("\(clipName).jpg")
                          
                            DispatchQueue.main.async {
                                let asset = AVAsset(url: destinationURL)
                                if let thumbnailImage = asset.generateThumbnail() {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                                        if let imageData = thumbnailImage.jpegData(compressionQuality: 0.6) {
                                            do {
                                                try imageData.write(to: destinationThumbURL)
                                                
                                                CoreDataManager.shared.saveClip(clipURL: destinationURL.lastPathComponent, thumbnailURL: destinationThumbURL.lastPathComponent, videoAsset: self.videoAsset!)
                                                                                                
                                                self.showClipSavedToast()
                                                print("Thumbnail saved successfully!")
                                            } catch {
                                                print("Error saving Thumbnail: \(error)")
                                            }
                                        }
                                    })
                                }
                            }
                        }
                        
                        let clips = CoreDataManager.shared.getAllClips()
                        print(clips)
                    case .failed:
                        print("Export failed: \(exportSession?.error?.localizedDescription ?? "Unknown error")")
                        self.showAlert(title: "Error saving clip", message: "failed: \(exportSession?.error?.localizedDescription ?? "Unknown error")") { result in}
                    default:
                        break
                    }
                })
            }
        }
    }
    
    func showClipSavedToast() {
        let config = ToastConfiguration(
            direction: .top,
            autoHide: true,
            enablePanToClose: true,
            displayTime: 2,
            animationTime: 0.2
        )
        let toast = Toast.text("Clip saved!", config: config)
        toast.show(haptic: .success)
    }
    
    // MARK: - Input
    @objc private func didBeginTrimming(_ sender: VideoTrimmer) {
        updateLabels()

        wasPlaying = (player.timeControlStatus != .paused)
        player.pause()

        updatePlayerAsset()
    }

    @objc private func didEndTrimming(_ sender: VideoTrimmer) {
        updateLabels()

        if wasPlaying == true {
            player.play()
        }

        updatePlayerAsset()
    }

    @objc private func selectedRangeDidChanged(_ sender: VideoTrimmer) {
        updateLabels()
    }

    @objc private func didBeginScrubbing(_ sender: VideoTrimmer) {
        updateLabels()

        wasPlaying = (player.timeControlStatus != .paused)
        player.pause()
    }

    @objc private func didEndScrubbing(_ sender: VideoTrimmer) {
        updateLabels()

        if wasPlaying == true {
            player.play()
        }
    }

    @objc private func progressDidChanged(_ sender: VideoTrimmer) {
        updateLabels()

        let time = CMTimeSubtract(trimmer.progress, trimmer.selectedRange.start)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // MARK: - Private
    private func updateLabels() {
        leadingTrimLabel.text = trimmer.selectedRange.start.displayString
        currentTimeLabel.text = trimmer.progress.displayString
        trailingTrimLabel.text = trimmer.selectedRange.end.displayString
    }

    private func updatePlayerAsset() {
        let outputRange = trimmer.trimmingState == .none ? trimmer.selectedRange : asset.fullRange
        let trimmedAsset = asset.trimmedComposition(outputRange)
        if trimmedAsset != player.currentItem?.asset {
            self.finalTrimmedAsset = trimmedAsset
            player.replaceCurrentItem(with: AVPlayerItem(asset: trimmedAsset))
        }
    }
}
