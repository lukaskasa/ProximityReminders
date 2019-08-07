//
//  Reminder.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import CoreData
/// CoreDate Object represting each reminder
public class Reminder: NSManagedObject {
    
    @NSManaged public var createDate: NSDate
    @NSManaged public var dateIdentifier: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var reminderDescription: String
    @NSManaged public var address: String?
    @NSManaged public var longitude: NSNumber?
    @NSManaged public var latitude: NSNumber?
    @NSManaged public var entrance: Bool
    
}

extension Reminder {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reminder> {
        
        let request = NSFetchRequest<Reminder>(entityName: String(describing: Reminder.self))
        
        let sortDescriptor = NSSortDescriptor(key: "isCompleted", ascending: true)
        
        request.sortDescriptors = [sortDescriptor]
        
        return request
        
    }
    
}
