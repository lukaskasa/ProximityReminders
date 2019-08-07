//
//  ReminderDatasource.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit

class ReminderDatasource: NSObject, UITableViewDataSource {
    
    private let tableView: UITableView
    private let managedObjectContext: NSManagedObjectContext
    private let viewController: UIViewController
    private let numberOfSections: Int = 2
    
    lazy var locationManager: LocationManager = {
        return LocationManager(delegate: nil, viewController: nil)
    }()
    
    lazy var fetchedResultsController: ReminderFetchedResultsController = {
        let controller = ReminderFetchedResultsController(fetchedRequest: Reminder.fetchRequest(), managedObjectContext: managedObjectContext, sectionKeyPath: "isCompleted", tableView: tableView)
        return controller
    }()
    
    init(tableView: UITableView, context: NSManagedObjectContext, viewController: UIViewController) {
        self.managedObjectContext = context
        self.tableView = tableView
        self.viewController = viewController
        super.init()
    }
    
    func object(at indexPath: IndexPath) -> Reminder {
        return fetchedResultsController.object(at: indexPath)
    }
    
    // MARK: - Datasource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        /// In case the are no sections a label is configured here
        let labelText = "All done! Enjoy your day!"
        if fetchedResultsController.sections?.count == 0 {
            let noMatchesLabel = UILabel(frame: CGRect(x: 0, y: 0, width: viewController.view.bounds.size.width, height: viewController.view.bounds.size.height))
            noMatchesLabel.tag = 100
            noMatchesLabel.text = labelText
            noMatchesLabel.textAlignment = NSTextAlignment.center
            self.tableView.backgroundView = noMatchesLabel
            self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        } else {
            if let label = viewController.view.viewWithTag(100) as? UILabel {
                label.isHidden = true
            }
            self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        }
        
        return fetchedResultsController.sections?.count ?? 0
    }
    
    /// The methods adopted by the object you use to manage data and provide cells for a table view.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableviewdatasource
    
    /// Asks the data source for the title of the header of the specified section of the table view.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableviewdatasource/1614850-tableview
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        guard var sectionName = fetchedResultsController.sections?[section].name else {
            return nil
        }
        
        if sectionName == "0" {
            sectionName = "Not Completed"
        } else if sectionName == "1" {
            sectionName = "Completed"
        }

        return sectionName
    }
    
    /// Tells the data source to return the number of rows in a given section of a table view.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableviewdatasource/1614931-tableview
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = fetchedResultsController.sections?[section] else {
            return 0
        }
        
        return section.numberOfObjects
    }
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReminderCell.reuseIdentifier, for: indexPath) as! ReminderCell
        
        let reminder = fetchedResultsController.object(at: indexPath)
        
        cell.checkmarkImageView.image = reminder.isCompleted ? UIImage(imageLiteralResourceName: "checkmark") : nil
        cell.descriptionLabel.text = reminder.reminderDescription
        cell.locationLabel.text = reminder.entrance ? "When arriving at: \(reminder.address ?? "")" : "When leaving: \(reminder.address ?? "")"
        cell.managedObjectContext = managedObjectContext
        cell.tableView = self.tableView
        cell.reminder = reminder
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let reminder = fetchedResultsController.object(at: indexPath)
        reminder.isCompleted = true
        if let latitude = reminder.latitude as! Double?, let longitude = reminder.longitude as! Double? {
            locationManager.stopMonitoring(latitude: latitude, longitude: longitude, identifier: reminder.dateIdentifier)
        }
        UIApplication.shared.applicationIconBadgeNumber -= 1
        managedObjectContext.delete(reminder)
        managedObjectContext.saveChanges()
    }
    
}
