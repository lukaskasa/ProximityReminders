//
//  LocationNotificationManager.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import UserNotifications
import CoreLocation

enum NotificationCategory: String {
    case reminder
}

protocol NotificationActionHandlerDelegate: class {
    func markAsCompleted(for identifier: String)
}

class LocationNotificationManager: NSObject {
    
    // Notification center
    private let center = UNUserNotificationCenter.current()
    private let viewController: UIViewController?
    weak var notificationActionHandlerDelegate: NotificationActionHandlerDelegate?
    
    init(viewController: UIViewController?) {
        self.viewController = viewController
        super.init()
        center.delegate = self
        setCategories()
    }
    
    func setCategories() {
        let completeAction = UNNotificationAction(identifier: "Completed", title: "Completed", options: [])
        let reminderCategory = UNNotificationCategory(identifier: NotificationCategory.reminder.rawValue, actions: [completeAction], intentIdentifiers: [], options: [])
        center.setNotificationCategories([reminderCategory])
    }
    
    func requestNotificationPermissions() {
        
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in

            if !granted {
                self.viewController?.showSettingsAlert(with: "Change Settings", and: "You will not receive any notifications, please change your settings to receive notifications.")
            }
            
            if error != nil {
                self.viewController?.showAlert(with: "Error", and: error!.localizedDescription)
            }
            
        }
        
    }
    
    func scheduleNotification(with title: String, identfier: String) {
        
        let content = UNMutableNotificationContent()
 
        content.title = title
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.categoryIdentifier = NotificationCategory.reminder.rawValue
        
        let soundName = UNNotificationSoundName("reminder.caf")
        content.sound = UNNotificationSound(named: soundName)
        
        // TODO:
        UIApplication.shared.applicationIconBadgeNumber += 1
        
        let request = UNNotificationRequest(identifier: identfier, content: content, trigger: nil)
        
        center.add(request) { error in

            if error != nil {
                self.viewController?.showAlert(with: "Error", and: error!.localizedDescription)
            }

        }
        
    }
    
}

extension LocationNotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .sound])
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == "Completed" {
            let identifier = response.notification.request.identifier
            notificationActionHandlerDelegate?.markAsCompleted(for: identifier)
        }
        
        completionHandler()
    }
    
}
