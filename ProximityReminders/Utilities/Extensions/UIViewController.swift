//
//  UIViewController.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 04.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /**
     Sets up and shows an Alert
     
     - Parameters:
     - title: The title of the alert
     - message: The message of the alert
     
     - Returns: Void
     */
    func showAlert(with title: String, and message: String, style: UIAlertController.Style = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    /**
     Sets up and shows an Alert with app settings access
     
     - Parameters:
     - title: The title of the alert
     - message: The message of the alert
     
     - Returns: Void
     */
    func showSettingsAlert(with title: String, and message: String) {
        
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
            
        }
        
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
}
