//
//  ReminderFetchedResultsController.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import CoreData

class ReminderFetchedResultsController: NSFetchedResultsController<Reminder> {
    
    /// Properies
    private let tableView: UITableView
    
    init(fetchedRequest: NSFetchRequest<Reminder>, managedObjectContext: NSManagedObjectContext, sectionKeyPath: String?, tableView: UITableView) {
        self.tableView = tableView
        super.init(fetchRequest: fetchedRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionKeyPath, cacheName: nil)
        self.delegate = self
        tryFetch()
    }
    
    // MARK: - Helper
    
    /// Executes the fetch request.
    func tryFetch() {
        do {
            try performFetch()
        } catch {
            print("Unresolved error: \(error.localizedDescription)")
        }
    }
    
}

/// A delegate protocol that describes the methods that will be called by the associated fetched results controller when the fetch results have changed.
extension ReminderFetchedResultsController: NSFetchedResultsControllerDelegate {
    
    /// Notifies the receiver that the fetched results controller is about to start processing of one or more changes due to an add, remove, move, or update.
    /// Apple Documentation: https://developer.apple.com/documentation/coredata/nsfetchedresultscontrollerdelegate/1622295-controllerwillchangecontent
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    /// Notifies the receiver that the fetched results controller has completed processing of one or more changes due to an add, remove, move, or update.
    /// Apple Documentation: https://developer.apple.com/documentation/coredata/nsfetchedresultscontrollerdelegate/1622290-controllerdidchangecontent
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    /// Notifies the receiver of the addition or removal of a section
    /// Apple documentation: https://developer.apple.com/documentation/coredata/nsfetchedresultscontrollerdelegate/1622298-controller
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            let index = IndexSet(integer: sectionIndex)
            tableView.insertSections(index, with: .none)
        case .delete:
            let index = IndexSet(integer: sectionIndex)
            tableView.deleteSections(index, with: .none)
        case .move, .update:
            let index = IndexSet(integer: sectionIndex)
            tableView.reloadSections(index, with: .none)
        @unknown default:
            tableView.reloadData()
        }
        
    }
    
    /// Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update.
    /// Apple Documentation: https://developer.apple.com/documentation/coredata/nsfetchedresultscontrollerdelegate/1622296-controller
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .right)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .right)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.reloadData()
        case .move:
            guard let indexPath = indexPath else { return }
            guard let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.insertRows(at: [newIndexPath], with: .fade)
        @unknown default:
            tableView.reloadData()
        }
        
    }
    
}
