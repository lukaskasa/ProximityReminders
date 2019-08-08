//
//  ReminderDatasource.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import CoreData

/// UITableViewDataSource Object
class ReminderDatasource: NSObject, UITableViewDataSource {
    
    /// Properties
    private let tableView: UITableView
    private let managedObjectContext: NSManagedObjectContext
    private let viewController: UIViewController
    private let numberOfSections: Int = 2
    
    /// Constants - Strings
    struct Constants {
        static let completedSectionKeyPath = "isCompleted"
        static let emptyTableViewText = "All done! Enjoy your day!"
        static let sectionNotCompleted = "Not Completed"
        static let sectionCompleted = "Completed"
        static let arrivingText = "When arriving at: "
        static let leavingText = "When leaving: "
        static let locationNotSet = "Location not set"
        static let checkmarkImageName = "checkmark"
    }
    
    lazy var locationManager: LocationManager = {
        return LocationManager(delegate: nil, viewController: nil)
    }()
    
    lazy var fetchedResultsController: ReminderFetchedResultsController = {
        let controller = ReminderFetchedResultsController(fetchedRequest: Reminder.fetchRequest(), managedObjectContext: managedObjectContext, sectionKeyPath: Constants.completedSectionKeyPath, tableView: tableView)
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
    /// The number of sections in the table view.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableview/1614924-numberofsections
    func numberOfSections(in tableView: UITableView) -> Int {
        /// In case the are no sections a label is configured here
        let labelText = Constants.emptyTableViewText
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
            sectionName = Constants.sectionNotCompleted
        } else if sectionName == "1" {
            sectionName = Constants.sectionCompleted
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
   
    /// Asks the data source for a cell to insert in a particular location of the table view.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableviewdatasource/1614861-tableview
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReminderCell.reuseIdentifier, for: indexPath) as! ReminderCell
        
        let reminder = fetchedResultsController.object(at: indexPath)
        
        cell.checkmarkImageView.image = reminder.isCompleted ? UIImage(imageLiteralResourceName: Constants.checkmarkImageName) : nil
        cell.descriptionLabel.text = reminder.reminderDescription
        let arrivingText = reminder.address != nil ? Constants.arrivingText : Constants.locationNotSet
        let leavingText = reminder.address != nil ? Constants.leavingText : Constants.locationNotSet
        cell.locationLabel.text = reminder.entrance ? "\(arrivingText)\(reminder.address ?? "")" : "\(leavingText)\(reminder.address ?? "")"
        cell.managedObjectContext = managedObjectContext
        cell.tableView = self.tableView
        cell.reminder = reminder
        
        return cell
    }
    
    /// Asks the data source to commit the insertion or deletion of a specified row in the receiver.
    /// https://developer.apple.com/documentation/uikit/uitableviewdatasource/1614871-tableview
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
