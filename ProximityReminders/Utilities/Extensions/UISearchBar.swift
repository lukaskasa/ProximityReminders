//
//  UISearchBar.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 04.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit

public extension UISearchBar {
    
    func setTextColor(color: UIColor) {
        let svs = subviews.flatMap { $0.subviews }
        guard let textField = (svs.filter { $0 is UITextField }).first as? UITextField else { return }
        textField.textColor = color
    }
    
}
