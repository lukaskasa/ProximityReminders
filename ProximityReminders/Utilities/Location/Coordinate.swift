//
//  Coordinate.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 03.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import CoreLocation

/// Cordinate to represent a geographical location
struct Coordinate {
    let latitude: Double
    let longitude: Double
}

/// Extension with a custom initializer for the Coordinate struct
extension Coordinate {
    
    init(with location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
    
}
