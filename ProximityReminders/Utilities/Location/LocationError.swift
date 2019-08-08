//
//  LocationError.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 03.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import Foundation

/// LocationError enum for location based errors
enum LocationError: Error {
    case unknownError
    case disallowedByUser
    case unableToFindLocation
    case backgroundRefreshIsDisabled
    case locationServicesUnavailable
}
