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
    let cellBgColor = UIColor(red: 15.0/255.0, green: 15.0/255.0, blue: 15.0/255.0, alpha: 1.0)
    let selectedBgColor = UIColor(red: 58.0/255.0, green: 58.0/255.0, blue: 60.0/255.0, alpha: 1.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if selected {
            contentView.backgroundColor = selectedBgColor
        } else {
            self.backgroundColor = cellBgColor
            contentView.backgroundColor = cellBgColor
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        if editing {
            selectedBackgroundView = UIView()
            selectedBackgroundView?.backgroundColor = selectedBgColor
        } else {
            selectedBackgroundView = nil
        }
    }
}
