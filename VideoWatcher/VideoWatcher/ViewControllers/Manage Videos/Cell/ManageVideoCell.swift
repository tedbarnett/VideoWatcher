//
//  ManageVideoCell.swift
//  VideoWatcher
//
//  Created by MyMac on 14/08/23.
//

import UIKit

class ManageVideoCell: UITableViewCell {

    @IBOutlet weak var imgThumb: UIImageView!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var lblClipName: UILabel!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var btnShare: UIButton!
    
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
}
