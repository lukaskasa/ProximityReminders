//
//  NotificationManager.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import UserNotifications

/// NotificationActionHandlerDelegate - Tells the delegate to mark a reminder as completed
protocol NotificationActionHandlerDelegate: class {
    func markAsCompleted(for identifier: String)
}

/// Handles the configuration and sending for local notifcations based on location
class NotificationManager: NSObject {
    
    // MARK: - Properties
    private let center = UNUserNotificationCenter.current()
    private let viewController: UIViewController?
    weak var notificationActionHandlerDelegate: NotificationActionHandlerDelegate?
    
    /// Constants - Strings
    struct Constants {
        static let reminderCategory = "Reminder"
        static let reminderActionName = "Completed"
        static let reminderActionTitle = "Mark as completed"
        static let notificationSoundName = "reminder.caf"
        static let settingsAlertTitle = "Change Settings"
        static let setttingsAlertText = "You will not receive any notifications, please change your settings to receive notifications."
    }
    
    /**
     Initializes manager to handle notifications
     
     - Parameters:
        - viewController: The view controller used to handle alerts and authorization requests
     
     - Returns: A manager to handle notification configuration
     */
    init(viewController: UIViewController?) {
        self.viewController = viewController
        super.init()
        center.delegate = self
        setCategories()
    }
    
    /**
     Set the notification category and adds a "Completed" action to be able to mark todos as completed
     
     - Returns: Void
     */
    func setCategories() {
        let completeAction = UNNotificationAction(identifier: Constants.reminderActionName, title: Constants.reminderActionTitle, options: [])
        let reminderCategory = UNNotificationCategory(identifier: Constants.reminderCategory, actions: [completeAction], intentIdentifiers: [], options: [])
        center.setNotificationCategories([reminderCategory])
    }
    
    /**
     Requests the permission to send notifications using alert, badge and sound
     
     - Returns: Void
     */
    func requestNotificationPermissions() {
        
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in

            if !granted {
                self.viewController?.showSettingsAlert(with: Constants.settingsAlertTitle, and: Constants.setttingsAlertText)
            }
            
            if error != nil {
                self.viewController?.showAlert(with: "Error", and: error!.localizedDescription)
            }
            
        }
        
    }
    
    /**
     Configures and schedules a notifcation
     
     - Parameters:
        - title: String:
        - identifier: String:
     
     - Returns: Void
     */
    func scheduleNotification(with title: String, identfier: String) {
        let content = UNMutableNotificationContent()
 
        content.title = title
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.categoryIdentifier = Constants.reminderCategory
        
        let soundName = UNNotificationSoundName(Constants.notificationSoundName)
        content.sound = UNNotificationSound(named: soundName)
        
        UIApplication.shared.applicationIconBadgeNumber += 1
        
        let request = UNNotificationRequest(identifier: identfier, content: content, trigger: nil)
        
        center.add(request) { error in

            if error != nil {
                print(error!.localizedDescription)
            }

        }
    }
    
}

/// The interface for handling incoming notifications and notification-related actions.
/// Apple documentation: https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// Asks the delegate how to handle a notification that arrived while the app was running in the foreground.
    /// https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649518-usernotificationcenter
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    /// Asks the delegate to process the user's response to a delivered notification.
    /// https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == Constants.reminderActionName {
            let identifier = response.notification.request.identifier
            notificationActionHandlerDelegate?.markAsCompleted(for: identifier)
        }
        
        completionHandler()
    }
    
}
