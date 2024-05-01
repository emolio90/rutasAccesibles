//
//  PointOfInterest.swift
//  MapRoutesAccesibility
//
//  Created by Emilio José Ojeda Cano on 20/4/24.
//

import MapKit
import Contacts //For Addresses needed to for maps

class PointOfInterest: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    var locationName: String?
    
    init(title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
    
    init?(feature: MKGeoJSONFeature) {
        guard
            let point = feature.geometry.first as? MKPointAnnotation,
            let propertiesData = feature.properties,
            let json = try? JSONSerialization.jsonObject(with: propertiesData),
            let properties = json as? [String: Any]
        else {
            return nil
        }
        
        title = properties["title"] as? String
        subtitle = properties["description"] as? String
        coordinate = point.coordinate
        super.init()
    }
    
    var mapItem: MKMapItem? { // To comunicate with maps
        guard let location = locationName else {
            return nil
        }
        
        let addressDict = [CNPostalAddressStreetKey: location]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        return mapItem
    }
    
}
