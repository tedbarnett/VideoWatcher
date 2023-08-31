//
//  DropboxCell.swift
//  VideoWatcher
//
//  Created by MyMac on 24/08/23.
//

import UIKit

class DropboxCell: UITableViewCell {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblNameTop: NSLayoutConstraint!
    @IBOutlet weak var lblDetails: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
//    override func setEditing(_ editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: animated)
//
//        if editing {
//            selectedBackgroundView = UIView()
//            selectedBackgroundView?.backgroundColor = UIColor.blue // Set your desired selection color
//        } else {
//            selectedBackgroundView = nil // Reset the selection background view
//        }
//    }
}
