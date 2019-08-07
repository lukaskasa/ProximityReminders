//
//  CurrentLocationCell.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 04.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit

class CurrentLocationCell: UITableViewCell {
    
    static let reuseIdentifier = "CurrentLocationCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
}
