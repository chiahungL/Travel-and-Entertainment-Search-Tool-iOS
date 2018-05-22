//
//  MapViewController.swift
//  csci571_hw9
//
//  Created by Chia-Hung Lee on 4/13/18.
//  Copyright © 2018 Chia-Hung Lee. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON

class MapViewController: UIViewController {

    var latitude : Double = 0.0
    var longitude : Double = 0.0
    var fromLat : Double = 0.0
    var fromLng : Double = 0.0
    
    // MARK: Properties
    @IBOutlet weak var fromField: UITextField!
    
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var seg: UISegmentedControl!
    
    // MARK: Actions
    @IBAction func autocompleteClicked(_ sender: Any) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self as? GMSAutocompleteViewControllerDelegate
        present(autocompleteController, animated: true, completion: nil)
    }
    @IBAction func valueChanged(_ sender: Any) {
        if (seg.selectedSegmentIndex == 0) {
            self.drawPath("driving")
        } else if (seg.selectedSegmentIndex == 1) {
            self.drawPath("bicycling")
        } else if (seg.selectedSegmentIndex == 2) {
            self.drawPath("transit")
        } else if (seg.selectedSegmentIndex == 3) {
            self.drawPath("walking")
        }
    }
    
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print ("-->latitude: \(latitude)")
        print ("-->longitude: \(longitude)")

        // Create a GMSCameraPosition that tells the map to display the coordinate
        let camera = GMSCameraPosition.camera(withLatitude: self.latitude, longitude: self.longitude, zoom: 15.0)
        self.mapView.camera = camera

        
        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)

        marker.map = self.mapView
        
    }

    
    func drawPath(_ mode: String) {
        self.mapView.clear()
        let origin = "\(self.fromLat),\(self.fromLng)"
        let destination = "\(self.latitude),\(self.longitude)"
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=\(mode)"
        
        Alamofire.request(url).responseJSON { response in
            do {
                let json = try JSON(data: response.data!)
                let routes = json["routes"].arrayValue
                
                for route in routes {
                    let routeOverviewPolyline = route["overview_polyline"].dictionary
                    let points = routeOverviewPolyline?["points"]?.stringValue
                    let path = GMSPath.init(fromEncodedPath: points!)
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeWidth = 4
                    //polyline.strokeColor = UIColor.
                    polyline.map = self.mapView
                }
            } catch {
                print (error)
            }
        }
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: self.fromLat, longitude: self.fromLng)
        marker.map = self.mapView
        
        let marker2 = GMSMarker()
        marker2.position = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        marker2.map = self.mapView
        
        let camera = GMSCameraPosition.camera(withLatitude: (self.fromLat + self.latitude) / 2, longitude: (self.fromLng + self.longitude) / 2, zoom: 12.0)
        self.mapView.camera = camera
    }

}

extension MapViewController: GMSAutocompleteViewControllerDelegate {
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        dismiss(animated: true, completion: nil)
        fromField.text = place.formattedAddress
        self.fromLat = place.coordinate.latitude
        self.fromLng = place.coordinate.longitude
        self.drawPath("driving")
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
