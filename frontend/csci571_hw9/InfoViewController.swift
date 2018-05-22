//
//  InfoViewController.swift
//  csci571_hw9
//
//  Created by Chia-Hung Lee on 4/13/18.
//  Copyright © 2018 Chia-Hung Lee. All rights reserved.
//

import UIKit
import SwiftyJSON
import GooglePlaces
import Cosmos
import Alamofire
import AlamofireSwiftyJSON
import EasyToast

class InfoViewController: UIViewController {

    // var rowObj : JSON!
    var placeId = ""
    let placesClient = GMSPlacesClient.shared()
    var placeObj : JSON!
    
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var addressDataLabel: UILabel!
    
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var phoneData: UITextView!
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceDataLabel: UILabel!
    
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var ratingDataLabel: UILabel!
    
    @IBOutlet weak var websiteLabel: UILabel!
    @IBOutlet weak var websiteData: UITextView!
    
    @IBOutlet weak var googlePageLabel: UILabel!
    @IBOutlet weak var googlePageData: UITextView!
    
    @IBOutlet weak var cosmosView: CosmosView!

    override func viewDidLoad() {
        super.viewDidLoad()
        print("==in InfoViewController==")
        print("placeId = \(placeId)")
        
        
        self.lookUpPlaceId()
        self.callServerForPlacesDetails()
    }
    
    func lookUpPlaceId() {
        self.placesClient.lookUpPlaceID(placeId, callback: { (place, error) -> Void in
            
            if let error = error {
                print("lookup place id query error: \(error.localizedDescription)")
                return
            }
            
            if let place = place {
                print(">> \(self.placeObj)")
                print("type of place = \(type(of: place))")
                print("Place name: \(place.name)")
                print("Place address: \(String(describing: place.formattedAddress))")
                print("Place placeID: \(place.placeID)")
                print("Place attributions: \(String(describing: place.attributions))")
                print("Place placeRating: \(place.rating)")
                print("Place placePriceLevel: \(place.priceLevel)")
                print("type = \(type(of: place.priceLevel))")
                print(place)
                self.tabBarController?.navigationItem.title = place.name
                
                //---- handle BarButtonItem ----
                let rightItem_twitter = UIBarButtonItem(
                    image: UIImage(named: "forward-arrow"),
                    style: .plain,
                    target: self,
                    action: #selector(self.composeTweet(sender:))
                )
                
                var keysArr = UserDefaults.standard.stringArray(forKey: "keysArr")
                let img: UIImage
                if (keysArr?.contains(place.placeID))! {
                    img = UIImage(named: "favorite-filled")!
                } else {
                    img = UIImage(named: "favorite-empty")!
                }
                let rightItem_favorite = UIBarButtonItem(
                    image: img,
                    style: .plain,
                    target: self,
                    action: #selector(self.toggleFavorites(sender:))
                )
                self.tabBarController?.navigationItem.rightBarButtonItems = [rightItem_favorite, rightItem_twitter]

                
                // ---- Assign data ----
                self.addressLabel.text = "Address"
                if (place.formattedAddress != nil) {
                    self.addressDataLabel.text = place.formattedAddress
                } else {
                    self.addressDataLabel.text = "No address"
                }
                
                self.phoneLabel.text = "Phone Number"
                if (place.phoneNumber != nil) {
                    self.phoneData.text = place.phoneNumber
                    self.phoneData.isEditable = false
                    self.phoneData.dataDetectorTypes = UIDataDetectorTypes.phoneNumber
                } else {
                    self.phoneData.text = "No phone number"
                    self.phoneData.isEditable = false
                }
                
                
                self.ratingLabel.text = "Rating"
                if (place.rating != nil) {
                    self.cosmosView.settings.fillMode = .precise
                    self.cosmosView.rating = Double(place.rating)
                    self.cosmosView.settings.updateOnTouch = false
                }
                

                
                self.websiteLabel.text = "Website"
                if (place.website != nil) {
                    self.websiteData.text = "\(String(describing: place.website!))"
                    self.websiteData.isEditable = false
                    self.websiteData.dataDetectorTypes = UIDataDetectorTypes.link
                } else {
                    self.websiteData.text = "No website"
                    self.websiteData.isEditable = false
                }

                
            } else {
                print("No place details for \(self.placeId)")
            }
        })
    }

    func callServerForPlacesDetails() {
        // Since the details for ios doesn't have "google page", use the backend for it
//        let urlToServer = "http://localhost:8081/?action=getPlacesDetails&placeId=\(self.placeId)"
        let urlToServer = "http://csci571-2-env.us-east-2.elasticbeanstalk.com/?action=getPlacesDetails&placeId=\(self.placeId)"
        print ("\(urlToServer)")
        Alamofire.request(urlToServer).responseSwiftyJSON { response in
            let json = response.result.value // A JSON object
            let isSuccess = response.result.isSuccess
            if (isSuccess && (json != nil)) {
                // print (json!)
                self.placeObj = json
                self.priceLabel.text = "Price Level"
                var price = ""
                var i = json!["result"]["price_level"].int
                if ((i) != nil) {
                    while (i! > 0) {
                        price += "$"
                        i! -= 1
                    }
                    self.priceDataLabel.text = price
                } else {
                    self.priceDataLabel.text = "Free"
                }

                self.googlePageLabel.text = "Google Page"
                if (json!["result"]["url"] != JSON.null) {
                    self.googlePageData.text = json!["result"]["url"].string
                    self.googlePageData.dataDetectorTypes = UIDataDetectorTypes.link
                } else {
                    self.googlePageData.text = "No Google page"
                }
                self.googlePageData.isEditable = false
            }
        }
    }
    
    @objc func toggleFavorites(sender: UIBarButtonItem) {
        var keysArr = UserDefaults.standard.stringArray(forKey: "keysArr")
        
        if (keysArr?.contains(self.placeId))! {
            // replace img
            sender.image = UIImage(named: "favorite-empty")
            
            // remove id from keysArr
            let indexToRemove = keysArr?.index(of: self.placeId)
            keysArr?.remove(at: indexToRemove!)
            UserDefaults.standard.set(keysArr, forKey: "keysArr")
            
            // remove object from UserDefaults
            UserDefaults.standard.removeObject(forKey: self.placeId)
            
            // toast
            self.view.showToast("\(self.placeObj["result"]["name"].string!)\nwas removed from favorites", position: .bottom, popTime: 3, dismissOnTap: false)
        } else {
            // replace img
            sender.image = UIImage(named: "favorite-filled")
            
            // add id into keysArr
            keysArr?.append(self.placeId)
            UserDefaults.standard.set(keysArr, forKey: "keysArr")
            
            // add object to UserDefaults
            let name = self.placeObj["result"]["name"].string!
            let address = self.placeObj["result"]["vicinity"].string!
            let category = self.placeObj["result"]["icon"].string!
            let placeId = self.placeObj["result"]["place_id"].string!
            let lat = String(self.placeObj["result"]["geometry"]["location"]["lat"].stringValue)
            let lng = String(self.placeObj["result"]["geometry"]["location"]["lng"].stringValue)
            
            UserDefaults.standard.set([name, address, category, placeId, lat, lng], forKey: placeId)
            
            // toast
            self.view.showToast("\(name)\nwas added to favorites", position: .bottom, popTime: 3, dismissOnTap: false)
        }
    }

    @objc func composeTweet(sender: UIBarButtonItem) {
        print("compose Tweet")
        var urlString = ""
        
        let name = self.placeObj["result"]["name"].string!.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        var address = self.placeObj["result"]["formatted_address"].string!.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        address = address.replacingOccurrences(of: ",", with: "%2C")
        
        var website = ""
        if (self.placeObj["result"]["website"] != JSON.null) {
            website = self.placeObj["result"]["website"].string!.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        } else {
            // if there's no website, use "url" instead
            website = self.placeObj["result"]["url"].string!.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        }
        
        
        urlString = "https://twitter.com/intent/tweet?text=Check%20out%20\(name)%20locate%20at%20\(address).%0AWebsite%3A&url=\(website)&hashtags=TravelAndEntertainmentSearch"
        
        if let urlToComposeTweet = URL(string: urlString) {
            UIApplication.shared.open(urlToComposeTweet, options: [:], completionHandler: nil)
        }
    }
}
