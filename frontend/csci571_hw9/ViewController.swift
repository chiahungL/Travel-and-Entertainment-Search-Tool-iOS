//
//  ViewController.swift
//  csci571_hw9
//
//  Created by Chia-Hung Lee on 4/10/18.
//  Copyright © 2018 Chia-Hung Lee. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps
import Alamofire
import AlamofireSwiftyJSON
import SwiftSpinner
import EasyToast
import SwiftyJSON


class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, CLLocationManagerDelegate {
    
    let thePicker = UIPickerView()
    let categories = ["Default", "Airport", "Amusement Park", "Aquarium", "Art Gallery", "Bakery", "Bar", "Beauty Salon", "Bowling Alley", "Bus Station", "Cafe", "Campground", "Car Rental", "Casino", "Lodging", "Movie Theater", "Museum", "Night Club", "Park", "Parking", "Restaurant", "Shopping Mall", "Stadium", "Subway Station", "Taxi Stand", "Train Station", "Transit Station", "Travel Agency", "Zoo"]
    var locationManager = CLLocationManager()
    var placesClient = GMSPlacesClient()
    var currLatitude = ""
    var currLongitude = ""
    var resultObj : JSON!
    
    
    // MARK: Properties
    @IBOutlet weak var keywordField: UITextField!
    @IBOutlet weak var categoryField: UITextField!
    @IBOutlet weak var distanceField: UITextField!
    @IBOutlet weak var fromField: UITextField!
    @IBOutlet weak var seg: UISegmentedControl!
    // ********************* end properties ***********************
    
    // MARK: Actions
    @IBAction func autocompleteClicked(_ sender: Any) {
        // fromField autocomplete
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    @IBAction func searchBtn(_ sender: UIButton) {
        var action: String
        var keyword: String
        var category: String
        var radius: double_t

        action = "getCurrentLoc"
        keyword = keywordField.text!.trimmingCharacters(in: .whitespaces)
        if (keyword == "") {
            self.view.showToast("Keyword cannot be empty", position: .bottom, popTime: 3, dismissOnTap: false)
            return
        } else {
            SwiftSpinner.show("Searching...")
            keyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            category = categoryField.text!.lowercased().replacingOccurrences(of: " ", with: "_")
            
            if (distanceField.text! == "") {
                radius = 10 * 1609.34
            } else {
                radius = double_t(distanceField.text!)! * 1609.34
            }
//            let urlToServer = "http://csci571-8.us-east-2.elasticbeanstalk.com/?action=\(action)&keyword=\(keyword)&category=\(category)&radius=\(radius)&lat=\(self.currLatitude)&lng=\(self.currLongitude)"
            let urlToServer = "http://csci571-2-env.us-east-2.elasticbeanstalk.com/?action=\(action)&keyword=\(keyword)&category=\(category)&radius=\(radius)&lat=\(self.currLatitude)&lng=\(self.currLongitude)"
            self.callServerForNearBySearch(urlToServer)
            
        }
    }
    @IBAction func clearBtn(_ sender: UIButton) {
        keywordField.text = ""
        categoryField.text = categories[0]
        thePicker.selectRow(0, inComponent: 0, animated: false)
        distanceField.text = ""
        fromField.text = "Your location"
        self.getCurrentLocation()
    }

    @IBAction func segValueChanged(_ sender: Any) {
        if (seg.selectedSegmentIndex == 0) {
            print("go to search")
        } else if (seg.selectedSegmentIndex == 1) {
            print("go to favorites")
            self.performSegue(withIdentifier: "favoriteSegue", sender: self)
            
        }
    }
    // ********************* end actions ***********************
    
    
    // MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.hidesBackButton = true

        // CATEGORY
        thePicker.delegate = self
        thePicker.dataSource = self
        thePicker.backgroundColor = .white
        
        categoryField.inputView = thePicker
        categoryField.text = categories[0]
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()

        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(ViewController.donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(ViewController.cancelPicker))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true

        categoryField.inputAccessoryView = toolBar
        
        // FROM
        fromField.text = "Your location"

        // CONFIG CURRENT LOCATION
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        locationManager.requestAlwaysAuthorization()
        placesClient = GMSPlacesClient.shared()
        self.getCurrentLocation()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: pickerView
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryField.text = categories[row]
        // categoryField.resignFirstResponder()
    }
    
    @objc func donePicker() {
        categoryField.resignFirstResponder()
    }
    
    @objc func cancelPicker() {
        categoryField.text = categories[0]
        categoryField.resignFirstResponder()
    }
    //*********************** end pickerView ***********************
    
    
    // MARK: getCurrentLocation()
    func getCurrentLocation() {
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    print ("--->getCurrentLocation() place.name = \(place.name)")
                    self.currLatitude = String(place.coordinate.latitude)
                    self.currLongitude = String(place.coordinate.longitude)
                }
            }
        })
    }

    // MARK: DO NEARBY SEARCH
    func callServerForNearBySearch(_ urlToServer: String) {
        Alamofire.request(urlToServer).responseSwiftyJSON { response in
            let json = response.result.value //A JSON object
            let isSuccess = response.result.isSuccess
            if (isSuccess && (json != nil)) {
                //do something
                print(json!["page0"]["results"][0]["name"])
                self.resultObj = json
                SwiftSpinner.hide()
                self.performSegue(withIdentifier: "searchResultsSegue", sender: self)
            } else if (response.result.isFailure) {
                SwiftSpinner.hide()
                self.view.showToast("An error occurs:\nCannot connect to the backend.", position: .bottom, popTime: 5, dismissOnTap: false)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "searchResultsSegue") {
            let destVC : NearbySearchViewController = segue.destination as! NearbySearchViewController
            destVC.resultObj = self.resultObj
            destVC.pageIndex = "page0"
        }
        
    }

}

extension ViewController: GMSAutocompleteViewControllerDelegate {
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        dismiss(animated: true, completion: nil)
        //fromField.text = place.name
        fromField.text = place.formattedAddress
        self.currLatitude = String(place.coordinate.latitude)
        self.currLongitude = String(place.coordinate.longitude)
        print (place.coordinate.latitude)
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
