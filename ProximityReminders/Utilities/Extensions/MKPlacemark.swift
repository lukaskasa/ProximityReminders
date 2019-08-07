//
//  MKPlacemark.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 05.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import MapKit

public extension MKPlacemark {
    
    func parseAddress() -> String {
        var address = ""
        var street = "", houseNumber = "", zipCode = "", city = "", country = ""
        
        if self.thoroughfare != nil { street = "\(self.thoroughfare!) " }
        if self.subThoroughfare != nil { houseNumber = "\(self.subThoroughfare!) " }
        if self.postalCode != nil { zipCode = "\(self.postalCode!) " }
        if self.locality != nil { city = "\(self.locality!) " }
        if self.country != nil { country = "\(self.country!) " }
        
        address = "\(street)\(houseNumber)\(zipCode)\(city)\(country)"
        
        return address
    }
    
}
