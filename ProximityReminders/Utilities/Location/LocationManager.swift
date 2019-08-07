//
//  LocationManager.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

protocol LocationManagerDelegate: class {
    func obtainedCoordinates(_ coordinate: Coordinate)
    func failedWithError(_ error: LocationError)
}

protocol LocationNotificationManagerDelegate: class {
    func fireNotification(for identifier: String, and region: CLRegion)
}


class LocationManager: NSObject, CLLocationManagerDelegate {
    
    /// Properties
    private let locationManager = CLLocationManager()
    private let geoDecoder = CLGeocoder()
    var viewController: UIViewController?
    weak var delegate: LocationManagerDelegate?
    weak var locationNotificationManagerDelegate: LocationNotificationManagerDelegate?
    
    var isAuthorized: Bool {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    var hasFunctionality: Bool {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) && UIApplication.shared.backgroundRefreshStatus != .restricted {
            return true
        }
        
        return false
    }
    
    init(delegate: LocationManagerDelegate?, viewController: UIViewController?) {
        self.delegate = delegate
        self.viewController = viewController
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocationAuthorization() throws {
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        if authorizationStatus == .restricted || authorizationStatus == .denied {
            throw LocationError.disallowedByUser
        } else if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
        
    }
    
    func monitorRegionAtLocation(regionBoundry: MKCircle, identifier: String, entry: Bool) {
        
        var boundry = regionBoundry.radius
        
        if isAuthorized && hasFunctionality {
            
            if boundry > locationManager.maximumRegionMonitoringDistance {
                boundry = locationManager.maximumRegionMonitoringDistance
            }
            
            let region = CLCircularRegion(center: regionBoundry.coordinate, radius: regionBoundry.radius, identifier: identifier)
            
            region.notifyOnEntry = entry
            region.notifyOnExit = !entry
            // Limit is 20 regions
            
            locationManager.startMonitoring(for: region)
        }
        
    }
    
    func stopMonitoring(latitude: Double, longitude: Double, identifier: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let circle = MKCircle(center: coordinate, radius: 50.0)
        let region = CLCircularRegion(center: coordinate, radius: circle.radius, identifier: identifier)
        locationManager.stopMonitoring(for: region)
    }
    
    func getAddress(latitude: Double, longitude: Double, completion: @escaping (CLPlacemark?, Error?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        geoDecoder.reverseGeocodeLocation(location) { placemarks, error in
            
            
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            completion(placeMark, nil)
            
            if error != nil {
                self.viewController?.showAlert(with: "Error", and: error!.localizedDescription)
                completion(nil, error)
            }
            
        }
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    // MARK: - Delegate Methods
    /// Apple documentation: https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate
    
    /// Tells the delegate that the authorization status for the application changed.
    /// Apple documentation: https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/1423701-locationmanager
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            requestLocation()
        }
    }
    
    /// Tells the delegate that the location manager was unable to retrieve a location value.
    /// Apple documentation: https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/1423786-locationmanager
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        guard let error = error as? CLError else {
            return
        }
        
        switch error.code {
        case .locationUnknown, .network:
            delegate?.failedWithError(.unableToFindLocation)
        case .denied:
            delegate?.failedWithError(.disallowedByUser)
        default:
            return
        }
    }
    
    /// Tells the delegate that new location data is available.
    /// Apple documentation: https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/1423615-locationmanager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            delegate?.failedWithError(.unableToFindLocation)
            return
        }
        
        let coordinate = Coordinate(with: location)
        
        delegate?.obtainedCoordinates(coordinate)
    }
    
    // Region based methods

    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if let region = region as? CLCircularRegion {
            
            let identifier = region.identifier
            
            locationNotificationManagerDelegate?.fireNotification(for: identifier, and: region)
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        
        if let region = region as? CLCircularRegion {
            
            let identifier = region.identifier
            
            locationNotificationManagerDelegate?.fireNotification(for: identifier, and: region)
            
        }
        
    }

}
