//
//  CurrentLocationCell.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 04.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit

/// Cell for location search results
class CurrentLocationCell: UITableViewCell {
    
    // The reuse identifier for the CurrentLocationCell
    static let reuseIdentifier = "CurrentLocationCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
}
