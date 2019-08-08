//
//  UISearchBar.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 04.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit

extension UISearchBar {
    
    /**
     Gets the textfield from the UISearchBar to set the text color
     
     - Parameters:
        - color: UIColor: The text color
     
     - Returns: Void
     */
    func setTextColor(color: UIColor) {
        let views = subviews.flatMap { $0.subviews }
        guard let textField = (views.filter { $0 is UITextField }).first as? UITextField else { return }
        textField.textColor = color
    }
    
}
