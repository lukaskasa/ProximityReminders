//
//  LocationSearchController.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 03.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import MapKit

class LocationSearchController: UITableViewController {
    
    var matchingItems = [MKMapItem]()
    var mapView: MKMapView?
 
    weak var handleMapSearchDelegate: HandleMapSearch?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

extension LocationSearchController: UISearchResultsUpdating, UISearchBarDelegate {
    
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
                self.matchingItems = response.mapItems
                self.tableView.reloadData()
                
                if error != nil {
                    self.showAlert(with: "Error", and: error!.localizedDescription)
                }
            }
            
        }
        
        
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
  

}

extension LocationSearchController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return matchingItems.count
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CurrentLocationCell.reuseIdentifier, for: indexPath) as! CurrentLocationCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocationResultCell", for: indexPath)
            let selectedItem = matchingItems[indexPath.row].placemark
            cell.textLabel?.text = selectedItem.name
            cell.detailTextLabel?.text = selectedItem.parseAddress()
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let selectedItem = matchingItems[indexPath.row].placemark
            handleMapSearchDelegate?.dropInZoom(placemark: selectedItem)
        } else {
            if let userLocationCoordinate = mapView?.userLocation.coordinate {
                let selectedItem = MKPlacemark(coordinate: userLocationCoordinate)
                handleMapSearchDelegate?.dropInZoom(placemark: selectedItem)
            }
     
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 44.0
        }
        
        return 55.0
    }
    
}
