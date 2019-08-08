//
//  ReminderCell.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class ReminderCell: UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    
    lazy var locationManager: LocationManager = {
        return LocationManager(delegate: nil, viewController: nil)
    }()
    
    // MARK: Properties
    var managedObjectContext: NSManagedObjectContext!
    var reminder: Reminder!
    var tableView: UITableView!
    
    // The reuse identifier for the ReminderCell
    static let reuseIdentifier = "ReminderCell"
    
    override func awakeFromNib() {
        selectionStyle = .none
        super.awakeFromNib()
    }
    
    // MARK: - Actions
    
    /// Action to handle the completion of reminders
    @IBAction func complete(_ sender: Any) {
        guard let reminder = reminder else { return }
        reminder.isCompleted = !reminder.isCompleted
        checkmarkImageView.image = reminder.isCompleted ? UIImage(imageLiteralResourceName: "checkmark"): nil
        
        if reminder.isCompleted {
            if let latitude = reminder.latitude as! Double?, let longitude = reminder.longitude as! Double? {
                locationManager.stopMonitoring(latitude: latitude, longitude: longitude, identifier: reminder.dateIdentifier)
            }
            UIApplication.shared.applicationIconBadgeNumber -= 1
        } else if !reminder.isCompleted {
            if let latitude = reminder.latitude as! Double?, let longitude = reminder.longitude as! Double? {
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let circle = MKCircle(center: coordinate, radius: 50.0)
                locationManager.monitorRegionAtLocation(regionBoundry: circle, identifier: reminder.dateIdentifier, entry: reminder.entrance)
            }
        }
    
        managedObjectContext.saveChanges()
    }
    
}
