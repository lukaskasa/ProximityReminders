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

/// LocationManagerDelegate: To handle return user location and possible errors
protocol LocationManagerDelegate: class {
    func obtainedCoordinates(_ coordinate: Coordinate)
    func failedWithError(_ error: LocationError)
}

/// LocationNotificationManagerDelegate: To handle the notification
protocol LocationNotificationManagerDelegate: class {
    func fireNotification(for identifier: String, and region: CLRegion)
}

/// Location Manager to handle
class LocationManager: NSObject, CLLocationManagerDelegate {
    
    /// Properties
    private let locationManager = CLLocationManager()
    private let geoDecoder = CLGeocoder()
    var viewController: UIViewController?
    /// Delegates
    weak var delegate: LocationManagerDelegate?
    weak var locationNotificationManagerDelegate: LocationNotificationManagerDelegate?
    
    /// Computed property to get location services authorization
    var isAuthorized: Bool {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    /// Computed property to check if monitoring and background refresh is available
    var hasFunctionality: Bool {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) && UIApplication.shared.backgroundRefreshStatus != .restricted {
            return true
        }
        
        return false
    }
    
    /**
     Initializes manager to handle Location based functionality
     
     - Parameters:
        - delegate: The delegate to handle location
        - viewController: The view controller used to handle alerts and authorization requests
     
     - Returns: A manager for location services
     */
    init(delegate: LocationManagerDelegate?, viewController: UIViewController?) {
        self.delegate = delegate
        self.viewController = viewController
        super.init()
        locationManager.delegate = self
    }
    
    /**
     Requests the Location Authorization
     
     - Throws: 'LocationError.disallowedByUser' - if location services are dissallowed by the user
     'LocationError.locationServicesUnavailable' if location servies are not available
     
     - Returns: Void
     */
    func requestLocationAuthorization() throws {
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        let locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        
        if locationServicesEnabled {
            if authorizationStatus == .restricted || authorizationStatus == .denied {
                throw LocationError.disallowedByUser
            } else if authorizationStatus == .notDetermined {
                locationManager.requestAlwaysAuthorization()
            } else {
                return
            }
        } else {
            throw LocationError.locationServicesUnavailable
        }

    }
    
    /**
     Starts the monitoring of a region
     
     - Parameters:
        - regionBoundry: MKCircle: The region boundry in form of a circle to be used
        - identifier: String: The identifier for the region monitoring instance
        - entry: Bool: Whether the notification is sent on entry or exit
     
     - Returns: Void
     */
    func monitorRegionAtLocation(regionBoundry: MKCircle, identifier: String, entry: Bool) {
        
        var boundry = regionBoundry.radius
        
        if isAuthorized && hasFunctionality {
            
            if boundry > locationManager.maximumRegionMonitoringDistance {
                boundry = locationManager.maximumRegionMonitoringDistance
            }
            
            let region = CLCircularRegion(center: regionBoundry.coordinate, radius: regionBoundry.radius, identifier: identifier)
            
            region.notifyOnEntry = entry
            region.notifyOnExit = !entry
            
            // 20 regions is the limit to monitor simultaneously
            locationManager.startMonitoring(for: region)
        }
        
    }
    
    /**
     Stops the monitoring of a region
     
     - Parameters:
        - latitude: Double: The latitude of the geographical coordinate.
        - longitude: Double: The longitude of the geographical coordinate.
        - identifier: String: The identifier for the region monitoring instance
     
     - Returns: Void
     */
    func stopMonitoring(latitude: Double, longitude: Double, identifier: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let circle = MKCircle(center: coordinate, radius: 50.0)
        let region = CLCircularRegion(center: coordinate, radius: circle.radius, identifier: identifier)
        locationManager.stopMonitoring(for: region)
    }
    
    
    /**
     Gets the address using latitude and longitude
     
     - Parameters:
        - latitude: Double: The latitude of the geographical coordinate.
        - longitude: Double: The longitude of the geographical coordinate.
     
     - Returns: Void
     
     */
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
    
    /// Requests the current user location
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
    
    /// Region based methods

    /// Tells the delegate that the user entered the specified region.
    /// Apple documentation: https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/1423560-locationmanager
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            locationNotificationManagerDelegate?.fireNotification(for: identifier, and: region)
        }
        
    }
    
    /// Tells the delegate that the user left the specified region.
    /// Apple documentation: https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/1423630-locationmanager
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            locationNotificationManagerDelegate?.fireNotification(for: identifier, and: region)
        }
        
    }

}
