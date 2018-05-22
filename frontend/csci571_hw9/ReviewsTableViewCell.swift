//
//  reviewsTableViewCell.swift
//  csci571_hw9
//
//  Created by Chia-Hung Lee on 4/16/18.
//  Copyright © 2018 Chia-Hung Lee. All rights reserved.
//

import UIKit
import Cosmos

class ReviewsTableViewCell: UITableViewCell {

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UITextView!
    @IBOutlet weak var userRating: CosmosView!
    @IBOutlet weak var userTime: UILabel!
    @IBOutlet weak var userComment: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
