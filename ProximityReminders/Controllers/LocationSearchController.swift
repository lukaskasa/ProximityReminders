//
//  LocationSearchController.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 03.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import MapKit

/// Location Search Controller - To displaz the location search results
class LocationSearchController: UITableViewController {
    
    // MARK: - Properties
    var locationSearchResults = [MKMapItem]()
    var mapView: MKMapView?
 
    weak var handleMapSearchDelegate: HandleMapSearch?
    
    struct Constants {
        static let locationResultCellReuseIdentifier = "LocationResultCell"
        static let currentLocationCellHeight: CGFloat = 44.0
        static let seachResultsCellHeight: CGFloat = 50.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

// MARK: - UISearchResultsUpdating and UISearchBarDelegate
extension LocationSearchController: UISearchResultsUpdating, UISearchBarDelegate {
    
    /// Called when the search bar becomes the first responder or when the user makes changes inside the search bar.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uisearchresultsupdating/1618658-updatesearchresults
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let mapView = mapView,
            let searchTerm = searchController.searchBar.text else { return }
        
        
        if !searchTerm.isEmpty {
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchTerm
            request.region = mapView.region
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                guard let response = response else {
                    return
                }
                self.locationSearchResults = response.mapItems
                self.tableView.reloadData()
                
                if error != nil {
                    self.showAlert(with: "Error", and: error!.localizedDescription)
                }
            }
            
        }
        
        
    }
    
    /// Tells the delegate that the cancel button was tapped.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uisearchbardelegate/1624314-searchbarcancelbuttonclicked
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
  

}

// MARK: - UITableViewDatasource & UITableViewDelegate implementation
extension LocationSearchController {
    // MARK: - Datasource
    
    /// The number of sections in the table view.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableview/1614924-numberofsections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    /// Tells the data source to return the number of rows in a given section of a table view.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableviewdatasource/1614931-tableview
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return locationSearchResults.count
        }
        return 1
    }
    
    /// Asks the data source for a cell to insert in a particular location of the table view.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableviewdatasource/1614861-tableview
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CurrentLocationCell.reuseIdentifier, for: indexPath) as! CurrentLocationCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.locationResultCellReuseIdentifier, for: indexPath)
            let selectedItem = locationSearchResults[indexPath.row].placemark
            cell.textLabel?.text = selectedItem.name
            cell.detailTextLabel?.text = selectedItem.parseAddress()
            return cell
        }
    }
    
    /// Tells the delegate that the specified row is now selected.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitableviewdelegate/1614877-tableview
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let selectedItem = locationSearchResults[indexPath.row].placemark
            handleMapSearchDelegate?.dropInZoom(placemark: selectedItem)
        } else {
            if let userLocationCoordinate = mapView?.userLocation.coordinate {
                let selectedItem = MKPlacemark(coordinate: userLocationCoordinate)
                handleMapSearchDelegate?.dropInZoom(placemark: selectedItem)
            }
     
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    /// Asks the delegate for the height to use for a row in a specified location.
    /// https://developer.apple.com/documentation/uikit/uitableviewdelegate/1614998-tableview
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return Constants.currentLocationCellHeight
        }
        
        return Constants.seachResultsCellHeight
    }
    
}
