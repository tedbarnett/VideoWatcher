//
//  SplashViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 04/08/23.
//

import UIKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        
        let videos = CoreDataManager.shared.getRandomVideos(count: 1)
        
        if videos.count > 0 {
            gotoVideoWatcher()
        }
        else {
            gotoVideoSelection()
        }
    }
    
    func gotoVideoWatcher() {
        DispatchQueue.main.async {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoWatcherViewController") as! VideoWatcherViewController
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    func gotoVideoSelection() {
        DispatchQueue.main.async {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImportFromPhotoLibraryViewController") as! ImportFromPhotoLibraryViewController
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
}
