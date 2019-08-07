//
//  Coordinate.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 03.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import CoreLocation

struct Coordinate {
    let latitude: Double
    let longitude: Double
}

extension Coordinate {
    
    init(with location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
    
}
