//
//  ReminderDelegate.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit

/// UITableViewDelegate Object
class ReminderDelegate: NSObject, UITableViewDelegate {
    
    /// Properties
    private let rowHeight: CGFloat = 70.0
    private let tableView: UITableView
    
    /// Initialize the delgate object using a UITableView
    init(tableView: UITableView) {
        self.tableView = tableView
    }
    
    // MARK: - Delegate Methods
    /// Methods for managing selections, configuring section headers and footers, deleting and reordering cells, and performing other actions in a table view.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableviewdelegate
    
    
    /// Asks the delegate for the height to use for a row in a specified location.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableviewdelegate/1614998-tableview
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    /// Asks the delegate for the editing style of a row at a particular location in a table view.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableviewdelegate/1614869-tableview
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
}
