//
//  SettingsViewController.swift
//  VideoWatcher
//
//  Created by MyMac on 18/08/23.
//

import UIKit

protocol SettingsViewControllerDelegate: AnyObject {
    func restartAllPanels()
}

class SettingsViewController: UIViewController {

    weak var delegate: SettingsViewControllerDelegate?
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var tableViewSettings: UITableView!
    @IBOutlet weak var viewContainerLeading: NSLayoutConstraint!
    @IBOutlet weak var viewContainerTrailing: NSLayoutConstraint!
    @IBOutlet weak var viewContainerTop: NSLayoutConstraint!
    @IBOutlet weak var viewContainerBottom: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
    }
    
    func setupView() {
        self.viewContainer.layer.cornerRadius = 10.0
        self.viewContainer.layer.masksToBounds = true
        self.tableViewSettings.delegate = self
        self.tableViewSettings.dataSource = self
        self.tableViewSettings.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "SettingsTableViewCell")
        self.tableViewSettings.contentInset =  UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        self.adjustPopupConstraints()
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        self.delegate?.restartAllPanels()
        self.dismiss(animated: true)
    }
    
    func adjustPopupConstraints() {
        if Utility.getDeviceOrientation().isLandscape {
            self.viewContainerLeading.constant = 150
            self.viewContainerTrailing.constant = 150
            self.viewContainerTop.constant = 20
            self.viewContainerBottom.constant = 20
        }
        else {
            self.viewContainerLeading.constant = 30
            self.viewContainerTrailing.constant = 30
            self.viewContainerTop.constant = 80
            self.viewContainerBottom.constant = 80
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.adjustPopupConstraints()
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCell") as! SettingsTableViewCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let url = CoreDataManager.shared.generateCSVFromVideoClips() {
            let activityViewController = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            // Check if the device is iPad
            if let popoverPresentationController = activityViewController.popoverPresentationController {
                popoverPresentationController.sourceView = tableView
                popoverPresentationController.sourceRect = tableView.rectForRow(at: indexPath)
            }
            
            present(activityViewController, animated: true, completion: nil)
        }
    }
}
