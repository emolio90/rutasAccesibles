//
//  ViewController.swift
//  MapRoutesAccesibility
//
//  Created by Emilio José Ojeda Cano on 20/4/24.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    private var pois: [PointOfInterest] = []
    private var temporaryPin: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let initialLocation = CLLocation(latitude: 38.389175, longitude: -0.5163323)
        mapView.centerToLocation(initialLocation)
        let sanviCenter = CLLocation(latitude: 38.3943634, longitude: -0.5345324)
        let region = MKCoordinateRegion(center: sanviCenter.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        mapView.setCameraBoundary(MKMapView.CameraBoundary(coordinateRegion: region), animated: true)
        
        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 10000)
        mapView.setCameraZoomRange(zoomRange, animated: true)
        mapView.delegate = self
        
        let aceituna = PointOfInterest(title: "Aceituna", 
                                       subtitle: "Está muy delgadito y estreñido 🥲",
                                       coordinate: CLLocationCoordinate2D(latitude: 38.384126, longitude: -0.5118115))
        aceituna.locationName = "Universidad de Alicante"
//        mapView.addAnnotation(aceituna)
        loadInitialData()
        mapView.addAnnotations(pois)
        
        
        
        // Add a gesture recognizer to detect taps on the map
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let tapPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            print("Tapped at coordinate: \(coordinate.latitude), \(coordinate.longitude)")
            
            addTemporaryPin(at: coordinate)
            
            reverseGeocoding(coordinate)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.removeTemporaryPin()
            }
        }
    }
    
    private func addTemporaryPin(at coordinate: CLLocationCoordinate2D) {
        removeTemporaryPin()
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        temporaryPin = annotation
        
    }
    
    private func removeTemporaryPin() {
        if let pin = temporaryPin {
            mapView.removeAnnotation(pin)
            temporaryPin = nil
        }
    }
    
    private func reverseGeocoding(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
            }
            guard let placemark = placemarks?.first else {
                print("No placemark found")
                return
            }
            
            if let formattedAddress = placemark.formattedAddress {
                print("Address: \(formattedAddress)")
            } else {
                print("No address found")
            }
        }
    }
    
    private func loadInitialData() {
        guard
            let fileName = Bundle.main.url(forResource: "CatsUA", withExtension: "geojson") 
        else {
            return
        }
        guard 
            let catsData = try? Data(contentsOf: fileName)
        else {
            print("Error loadInitialData")
            return
        }
        
        do {
            let features = try MKGeoJSONDecoder()
                .decode(catsData)
                .compactMap { $0 as? MKGeoJSONFeature }
            
            let validWorks = features.compactMap(PointOfInterest.init)
            pois.append(contentsOf: validWorks)
        } catch {
            print("Unexpedted error: \(error).")
        }
    }

}

private extension MKMapView {
    func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 1000) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? PointOfInterest {
            let identifier = "cat"
            var view: MKMarkerAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            return view
        } else if annotation === temporaryPin {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            pinView.pinTintColor = .gray
            pinView.animatesDrop = true
            return pinView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let pointOfInterest = view.annotation as? PointOfInterest else {
            return
        }
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        pointOfInterest.mapItem?.openInMaps(launchOptions: launchOptions)
    }
}


extension CLPlacemark {
    var formattedAddress: String? {
        guard let name = name, let locality = locality, let country = country else { return nil }
        return "\(name), \(locality), \(country)"
    }
}
