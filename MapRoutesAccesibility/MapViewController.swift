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
        guard let annotation = annotation as? PointOfInterest else {
            return nil
        }
        
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
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let pointOfInterest = view.annotation as? PointOfInterest else {
            return
        }
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        pointOfInterest.mapItem?.openInMaps(launchOptions: launchOptions)
    }
}
