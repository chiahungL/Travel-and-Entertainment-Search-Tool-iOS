//
//  ReviewsViewController.swift
//  csci571_hw9
//
//  Created by Chia-Hung Lee on 4/13/18.
//  Copyright © 2018 Chia-Hung Lee. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON
import Cosmos

class ReviewsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    struct AnReview {
        var name: String
        var rating: Float
        var time: String
        var originalIndex: Int
    }
    
    var placeId = ""
    var resultObj : JSON!
    var source = ""
    var sort = "default"
    var order = "ascending"
    var yelpResult : JSON!
    var display: [AnReview] = []
    
    
    var nameForYelp = ""
    var addressForYelp = ""
    var cityForYelp = ""
    var stateForYelp = ""
    var postalCodeForYelp = ""
    var countryForYelp = ""
    var latForYelp = ""
    var lngForYelp = ""
    var phoneForYelp = ""
    var urlForYelp = ""
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Source Segmented Control (google/yelp)
    @IBOutlet weak var sourceSeg: UISegmentedControl!
    @IBAction func sourceChanged(_ sender: Any) {
        if (sourceSeg.selectedSegmentIndex == 0) {
            self.source = "google"
            if (self.resultObj == nil) {
                self.callServerForPlacesDetails()
            } else {
                self.updateDisplay()
            }
        } else if (sourceSeg.selectedSegmentIndex == 1) {
            self.source = "yelp"
            self.updateDisplay()
        }
    }
    
    // MARK: Sort Segmented Control (Default/Rating/Date)
    @IBOutlet weak var sortSeg: UISegmentedControl!
    @IBAction func sortChanged(_ sender: Any) {
        if (sortSeg.selectedSegmentIndex == 0) {
            self.sort = "default"
            self.orderSeg.isUserInteractionEnabled = false
            self.orderSeg.tintColor = UIColor.gray
        } else if (sortSeg.selectedSegmentIndex == 1) {
            self.sort = "rating"
            self.orderSeg.isUserInteractionEnabled = true
            self.orderSeg.tintColor = UIColor.black
        } else if (sortSeg.selectedSegmentIndex == 2) {
            self.sort = "date"
            self.orderSeg.isUserInteractionEnabled = true
            self.orderSeg.tintColor = UIColor.black
        }
        self.updateDisplay()
    }
    
    // MARK: Order Segmented Control (Ascending/Descending)
    @IBOutlet weak var orderSeg: UISegmentedControl!
    @IBAction func orderChanged(_ sender: Any) {
        if (orderSeg.selectedSegmentIndex == 0) {
            self.order = "ascending"
        } else if (orderSeg.selectedSegmentIndex == 1) {
            self.order = "descending"
        }
        self.updateDisplay()
    }
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        
        tableView.delegate = self
        tableView.dataSource = self
        
        super.viewDidLoad()

        self.callServerForPlacesDetails()
        
        if (sortSeg.selectedSegmentIndex == 0) {
            self.orderSeg.isUserInteractionEnabled = false
            self.orderSeg.tintColor = UIColor.gray
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.source == "google" && self.resultObj != nil) {
            print ("\(self.resultObj["result"]["reviews"].count)")
            return self.resultObj["result"]["reviews"].count
        } else if (self.source == "yelp" && self.yelpResult != nil){
            return self.yelpResult["reviews"].count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reviewsCell") as! ReviewsTableViewCell
        
        if (self.source == "google" && self.resultObj != nil) {
            // USER NAME
            let index = self.display[indexPath.row].originalIndex
            cell.userName.text = self.resultObj["result"]["reviews"][index]["author_name"].string
            cell.userName.isEditable = false
            cell.userName.isScrollEnabled = false
            
            // USER RATING
            cell.userRating.rating = Double(self.resultObj["result"]["reviews"][index]["rating"].double!)
            cell.userRating.settings.updateOnTouch = false
            
            // USER SUBMITTED TIME
            let date = Date(timeIntervalSince1970: self.resultObj["result"]["reviews"][index]["time"].double!)
            let dateFormatter = DateFormatter()
            //dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            cell.userTime.text = dateFormatter.string(from: date)
            
            
            // USER COMMENT
            cell.userComment.text = self.resultObj["result"]["reviews"][index]["text"].string
            
            // USER IMAGE
            if (self.resultObj["result"]["reviews"][index]["profile_photo_url"] != JSON.null) {
                let url = URL(string: self.resultObj["result"]["reviews"][index]["profile_photo_url"].string!)
                let session = URLSession.shared.dataTask(with: url!) { (data, response, error) in
                    DispatchQueue.main.async {
                        let image = UIImage(data: data!)
                        cell.userImage.image = image
                        cell.setNeedsLayout()
                    }
                }
                session.resume()
            }
        } else if (self.source == "yelp" && self.yelpResult != nil) {
            let index = self.display[indexPath.row].originalIndex
            
            // USER NAME
            cell.userName.text = self.yelpResult["reviews"][index]["user"]["name"].string
            cell.userName.isEditable = false
            cell.userName.isScrollEnabled = false
            
            // USER RATING
            cell.userRating.rating = Double(self.yelpResult["reviews"][index]["rating"].double!)
            cell.userRating.settings.updateOnTouch = false
            
            // USER SUBMITTED TIME
            cell.userTime.text = self.yelpResult["reviews"][index]["time_created"].string
            
            // USER COMMENT
            cell.userComment.text = self.yelpResult["reviews"][index]["text"].string
            
            // USER IMAGE
            if (self.yelpResult["reviews"][index]["user"]["image_url"] != JSON.null) {
                let url = URL(string: self.yelpResult["reviews"][index]["user"]["image_url"].string!)
                let session2 = URLSession.shared.dataTask(with: url!) { (data, response, error) in
                    DispatchQueue.main.async {
                        let image = UIImage(data: data!)
                        cell.userImage.image = image
                        cell.setNeedsLayout()
                    }
                }
                session2.resume()
            }
        }
        return cell
    }
    

    func callServerForPlacesDetails() {
        self.source = "google"
//        let urlToServer = "http://localhost:8081/?action=getPlacesDetails&placeId=\(self.placeId)"
        let urlToServer = "http://csci571-2-env.us-east-2.elasticbeanstalk.com/?action=getPlacesDetails&placeId=\(self.placeId)"
        Alamofire.request(urlToServer).responseSwiftyJSON { response in
            let json = response.result.value // A JSON object
            let isSuccess = response.result.isSuccess
            if (isSuccess && (json != nil)) {
                print ("---in ReviewsViewController---")
                self.resultObj = json
                
                // test
                self.updateDisplay()
                
                // prepare the data for yelp in the future
                self.nameForYelp = self.resultObj["result"]["name"].string!
                //var address = self.resultObj["result"]["formatted_address"].string!.split(separator: "#").joined().split(separator: ",")
                var address = self.resultObj["result"]["formatted_address"].string!.replacingOccurrences(of: "#", with: "%23").split(separator: ",")
                self.countryForYelp = "US"
                var dummy = address[address.count - 2].split(separator: " ")
                self.stateForYelp = String(dummy[0])
                self.postalCodeForYelp = String(dummy[1])
                self.cityForYelp = String(address[address.count - 3]).replacingOccurrences(of: " ", with: "+")
                self.latForYelp = self.resultObj["result"]["geometry"]["location"]["lat"].stringValue
                self.lngForYelp = self.resultObj["result"]["geometry"]["location"]["lng"].stringValue
                var dummy2 : [String] = []
                if (address.count - 4 >= 0) {
                    for i in 0 ... (address.count - 4) {
                        print("i = \(i)")
                        print("address[i] = \(address[i])")
                        dummy2.append(String(address[i]).replacingOccurrences(of: " ", with: "+"))
                    }
                    print (dummy2)
                    self.addressForYelp = dummy2.joined(separator: "_")
                    print (self.addressForYelp)
                }
                self.nameForYelp = (self.resultObj["result"]["name"].string?.replacingOccurrences(of: " ", with: "+"))!
                
                if (self.resultObj["result"]["international_phone_number"] != JSON.null) {
                    self.phoneForYelp = (self.resultObj["result"]["international_phone_number"].string?.replacingOccurrences(of: " ", with: ""))!
                    self.phoneForYelp = self.phoneForYelp.replacingOccurrences(of: "-", with: "")
                }
                
//                self.urlForYelp = "http://localhost:8081/?action=getYelpReview&name=\(self.nameForYelp)&address1=\(self.addressForYelp)&city=\(self.cityForYelp)&state=\(self.stateForYelp)&postal_code=\(self.postalCodeForYelp)&country=\(self.countryForYelp)&latitude=\(self.latForYelp)&longitude=\(self.lngForYelp)&phone=\(self.phoneForYelp)"
                self.urlForYelp = "http://csci571-2-env.us-east-2.elasticbeanstalk.com/?action=getYelpReview&name=\(self.nameForYelp)&address1=\(self.addressForYelp)&city=\(self.cityForYelp)&state=\(self.stateForYelp)&postal_code=\(self.postalCodeForYelp)&country=\(self.countryForYelp)&latitude=\(self.latForYelp)&longitude=\(self.lngForYelp)&phone=\(self.phoneForYelp)"
                // print(self.urlForYelp)
                self.callServerForYelpReviews()
                
                
                
                self.tableView.reloadData()
            }
        }
    }
    
    func callServerForYelpReviews() {
        //self.source = "yelp"
        print("---in callServerForYelpReviews()---")
        print("urlForYelp = \(self.urlForYelp)")
        Alamofire.request(self.urlForYelp).responseSwiftyJSON { response in
            let json = response.result.value // A JSON object
            let isSuccess = response.result.isSuccess
            if (isSuccess && (json != nil)) {
                print ("---we got the data from yelp---")
                self.yelpResult = json
                //self.updateDisplay()
            }
        }
    }
    
    func updateDisplay() {
        print(self.source)
        print(self.sort)
        print(self.order)
        
        
        self.display = []
        if (self.source == "google") {
            let num = self.resultObj["result"]["reviews"].count
            if (num - 1 >= 0) {
                for i in 0 ... (num - 1) {
                    self.display.append(AnReview(name: self.resultObj["result"]["reviews"][i]["author_name"].string!, rating: self.resultObj["result"]["reviews"][i]["rating"].float!, time: self.resultObj["result"]["reviews"][i]["time"].stringValue, originalIndex: i))
                }
            }
            if (self.sort == "default") {
                // we're done, just pass
            } else if (self.sort == "rating" && self.order == "ascending") {
                self.display.sort(by: {$0.rating < $1.rating})
            } else if (self.sort == "rating" && self.order == "descending") {
                self.display.sort(by: {$0.rating > $1.rating})
            } else if (self.sort == "date" && self.order == "ascending") {
                self.display.sort(by: {$0.time < $1.time})
            } else if (self.sort == "date" && self.order == "descending") {
                self.display.sort(by: {$0.time > $1.time})
            }
        } else if (self.source == "yelp" && self.yelpResult != nil) {
            let num = self.yelpResult["reviews"].count
            if (num - 1 >= 0) {
                for i in 0 ... (num - 1) {
                    self.display.append(AnReview(name: self.yelpResult["reviews"][i]["user"]["name"].string!, rating: self.yelpResult["reviews"][i]["rating"].float!, time: self.yelpResult["reviews"][i]["time_created"].string!, originalIndex: i))
                }
            }
            if (self.sort == "default") {
                // we're done, just pass
            } else if (self.sort == "rating" && self.order == "ascending") {
                self.display.sort(by: {$0.rating < $1.rating})
            } else if (self.sort == "rating" && self.order == "descending") {
                self.display.sort(by: {$0.rating > $1.rating})
            } else if (self.sort == "date" && self.order == "ascending") {
                self.display.sort(by: {$0.time < $1.time})
            } else if (self.sort == "date" && self.order == "descending") {
                self.display.sort(by: {$0.time > $1.time})
            }
        }
        print("end of upadate display")
        self.tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("in didSelectRowAt~~~~~")
        print(tableView.indexPathForSelectedRow!.row)
        let index = self.display[tableView.indexPathForSelectedRow!.row].originalIndex
        if (self.source == "google") {
            if let url = URL(string: self.resultObj["result"]["reviews"][index]["author_url"].string!) {
                print(url)
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else if (self.source == "yelp") {
            if let url = URL(string: self.yelpResult["reviews"][index]["url"].string!) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        print("-----------in numberOfSections()-----------")
        print("self.source = \(self.source)")
        print("self.yelpResult is nil: \(self.yelpResult == nil)")
        var numOfSections: Int = 1
        if (self.source == "google" && self.resultObj != nil) {
            if (self.resultObj["result"]["reviews"] == JSON.null) {
                let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
                noDataLabel.text = "No reviews"
                noDataLabel.textColor = UIColor.black
                noDataLabel.textAlignment = .center
                tableView.backgroundView = noDataLabel
                tableView.separatorStyle = .none
                numOfSections = 0
            } else {
                tableView.separatorStyle = .singleLine
                numOfSections = 1
                tableView.backgroundView = nil
            }
        }
        if (self.source == "yelp" && (self.yelpResult == nil || self.yelpResult["reviews"] == JSON.null)) {
            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text = "No reviews"
            noDataLabel.textColor = UIColor.black
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
            numOfSections = 0
        } else if (self.source == "yelp" && self.yelpResult != nil && self.yelpResult["reviews"] != JSON.null) {
            tableView.separatorStyle = .singleLine
            numOfSections = 1
            tableView.backgroundView = nil
        }
        return numOfSections
    }
}
