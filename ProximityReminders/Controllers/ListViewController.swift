//
//  ListViewController.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 01.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ListViewController: UITableViewController {
    
    // MARK: - Properties
    let managedObjectContext = CoreDataManager(modelName: "ProximityReminders").managedObjectContext
    
    lazy var delegate: ReminderDelegate = {
        let delegate = ReminderDelegate(tableView: self.tableView)
        return delegate
    }()
    
    lazy var datasource: ReminderDatasource = {
        let source = ReminderDatasource(tableView: self.tableView, context: managedObjectContext, viewController: self)
        return source
    }()
    
    lazy var locationManager: LocationManager = {
        return LocationManager(delegate: nil, viewController: self)
    }()
    
    lazy var notificationManager: LocationNotificationManager = {
        return LocationNotificationManager(viewController: self)
    }()
    
    // MARK: View Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up
        notificationManager.requestNotificationPermissions()
        notificationManager.notificationActionHandlerDelegate = self
        locationManager.locationNotificationManagerDelegate = self
        tableView.delegate = delegate
        tableView.dataSource = datasource
        setBadgeCount()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showReminder" {
            
            guard let reminderViewController = segue.destination as? ReminderViewController,
                let indexPath = tableView.indexPathForSelectedRow else { return }
            
            reminderViewController.managedObjectContext = self.managedObjectContext
            // Configure reminder
            let reminder = datasource.object(at: indexPath)
            reminderViewController.reminder = reminder
            
        } else if segue.identifier == "newReminder" {
            
            let reminderViewController = segue.destination as! ReminderViewController
            reminderViewController.managedObjectContext = self.managedObjectContext
            
        } else {
            return
        }
        
        
    }
    
    // MARK: - Helper Methods
    
    func resetPredicate() {
        datasource.fetchedResultsController.fetchRequest.predicate = nil
        datasource.fetchedResultsController.tryFetch()
    }
    
    func setBadgeCount() {
        let predicate = NSPredicate(format: "isCompleted == %@", 0)
        datasource.fetchedResultsController.fetchRequest.predicate = predicate
        datasource.fetchedResultsController.tryFetch()
        UIApplication.shared.applicationIconBadgeNumber = datasource.fetchedResultsController.fetchedObjects!.count
        resetPredicate()
    }

}

/// LocationNotificationManagerDelegate implementation
extension ListViewController: LocationNotificationManagerDelegate {

    func fireNotification(for identifier: String, and region: CLRegion) {

        let predicate = NSPredicate(format: "dateIdentifier == %@", identifier)
        datasource.fetchedResultsController.fetchRequest.predicate = predicate
        datasource.fetchedResultsController.tryFetch()
        let reminder = datasource.fetchedResultsController.fetchedObjects?.first

        notificationManager.scheduleNotification(with: reminder?.reminderDescription ?? "No title", identfier: identifier)
        resetPredicate()

    }

}

/// NotificationActionHandlerDelegate implementation
extension ListViewController: NotificationActionHandlerDelegate {
    
    func markAsCompleted(for identifier: String) {
        
        let predicate = NSPredicate(format: "dateIdentifier == %@", identifier)
        datasource.fetchedResultsController.fetchRequest.predicate = predicate
        datasource.fetchedResultsController.tryFetch()
        resetPredicate()
        let reminder = datasource.fetchedResultsController.fetchedObjects?.first
        reminder?.isCompleted = true
        managedObjectContext.saveChanges()
        
        guard let todo = reminder else { return }
        
        if todo.isCompleted {
            if let latitude = todo.latitude as! Double?, let longitude = todo.longitude as! Double? {
                locationManager.stopMonitoring(latitude: latitude, longitude: longitude, identifier: todo.dateIdentifier)
            }
            UIApplication.shared.applicationIconBadgeNumber -= 1
        } else if !todo.isCompleted {
            if let latitude = todo.latitude as! Double?, let longitude = todo.longitude as! Double? {
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let circle = MKCircle(center: coordinate, radius: 50.0)
                locationManager.monitorRegionAtLocation(regionBoundry: circle, identifier: todo.dateIdentifier, entry: todo.entrance)
            }
        }
        
    }
    
}
