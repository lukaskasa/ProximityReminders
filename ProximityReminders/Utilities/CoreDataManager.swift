//
//  CoreDataManager.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import CoreData

/// Manager Object for the Core Data Stack
final class CoreDataManager {
    
    /// Name of the Model to be managed by the Core Data Manager
    private let modelName: String
    
    /// Initializes the CoreDataManager using the given model name
    init(modelName: String) {
        self.modelName = modelName
    }
    
    /// Managed Object Context self invoking closure
    /// Apple Documentation: https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext
    lazy private(set) var managedObjectContext: NSManagedObjectContext = {
        let container = self.persistentContainer
        return container.viewContext
    }()
    
    /// Managed Object Context self invoking closure
    /// Apple Documentation: https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext
    lazy private(set) var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        
        container.loadPersistentStores { storeDesciption, error in
            
            if let error = error as NSError? {
                fatalError("Unresolved error: \(error), \(error.userInfo)")
            }
            
        }
        
        return container
    }()
    
}

extension NSManagedObjectContext {
    
    /// Save changes to the context store
    func saveChanges() {
        if self.hasChanges {
            do {
                try save()
            } catch {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
    
}
