//
//  nearbySearchViewController.swift
//  csci571_hw9
//
//  Created by Chia-Hung Lee on 4/12/18.
//  Copyright © 2018 Chia-Hung Lee. All rights reserved.
//

import UIKit
import SwiftyJSON
import SwiftSpinner
import EasyToast

class NearbySearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var resultObj : JSON!
    var pageIndex = ""
    var neverTapNext = true
    var neverTapThird = true
    var keysArr : [String] = []
    
    // MARK: Properties
    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    
    // MARK: Actions
    @IBAction func prevBtnAction(_ sender: UIButton) {
        if (pageIndex == "page1") {
            pageIndex = "page0"
        } else if (pageIndex == "page2") {
            pageIndex = "page1"
        }
        self.configPrevNextBtn()
        tableView.reloadData()
    }
    @IBAction func nextBtnAction(_ sender: UIButton) {
        if (pageIndex == "page0" && neverTapNext) {
            neverTapNext = false
            SwiftSpinner.show(duration: 1.0, title: "Loading next page...")
        } else if (pageIndex == "page1" && neverTapThird) {
            neverTapThird = false
            SwiftSpinner.show(duration: 1.0, title: "Loading next page...")
        }
        
        if (pageIndex == "page0") {
            pageIndex = "page1"
        } else if (pageIndex == "page1") {
            pageIndex = "page2"
        }
        self.configPrevNextBtn()
        
        tableView.reloadData()
    }
    
    @IBAction func clickedFavorite(_ sender: Any) {
        print("favorite is clicked")
        let button = sender as! UIButton
        //print("pressed button.tag = \(button.tag)")
        print("self.keysArr: \(self.keysArr)")
        let selectedRow = button.tag
        
        let selectedRowObj = self.resultObj[pageIndex]["results"][selectedRow]
        print("selected: \(selectedRowObj["place_id"].string!)")
        if (self.keysArr.contains(selectedRowObj["place_id"].string!)) {
            // MARK: REMOVE from favorite
            let btnImg = UIImage(named: "favorite-empty")
            let tintedImage = btnImg?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedImage, for: UIControlState.normal)
            button.tintColor = .black
            
            // remove the keys from self.keysArr, and update it in UserDefaults
            let indexToRemove = self.keysArr.index(of: selectedRowObj["place_id"].string!)
            self.keysArr.remove(at: indexToRemove!)
            UserDefaults.standard.set(self.keysArr, forKey: "keysArr")
            
            // remove the object in UserDefaults
            UserDefaults.standard.removeObject(forKey: selectedRowObj["place_id"].string!)
            
            self.view.showToast("\(selectedRowObj["name"])\nwas removed from favorites", position: .bottom, popTime: 3, dismissOnTap: false)
            
        } else {
            // MARK: ADD to favorite
            let btnImg = UIImage(named: "favorite-filled")
            let tintedImage = btnImg?.withRenderingMode(.alwaysTemplate)
            button.setImage(tintedImage, for: UIControlState.normal)
            button.tintColor = .red
            
            // add the new keys into self.keysArr, and update it in UserDefaults
            self.keysArr.append(selectedRowObj["place_id"].string!)
            print("self.keysArr: \(self.keysArr)")
            UserDefaults.standard.set(self.keysArr, forKey: "keysArr")
            
            // add the new object to UserDefaults
            let name = selectedRowObj["name"].string!
            let address = selectedRowObj["vicinity"].string!
            let category = selectedRowObj["icon"].string!
            let placeId = selectedRowObj["place_id"].string!
            let lat = String(selectedRowObj["geometry"]["location"]["lat"].stringValue)
            let lng = String(selectedRowObj["geometry"]["location"]["lng"].stringValue)
            UserDefaults.standard.set([name, address, category, placeId, lat, lng], forKey: placeId)
            
            self.view.showToast("\(selectedRowObj["name"])\nwas added to favorites", position: .bottom, popTime: 3, dismissOnTap: false)
        }
    }
    
    
    // MARK: viewDidLoad()
    override func viewDidLoad() {
        
        tableView.delegate = self
        tableView.dataSource = self
        self.configPrevNextBtn()
        neverTapNext = true
        
        super.viewDidLoad()

        print("--> in nextVC: \(resultObj[pageIndex]["results"][0]["name"])")
        
        // get an array of IDs, these IDs are in the favorite list
        let defaults = UserDefaults.standard
        self.keysArr = defaults.stringArray(forKey: "keysArr")!
        print (self.keysArr)

    }

    func configPrevNextBtn() {
        print("-->in configPrevNextBtn(), pageIndex = \(pageIndex)")
        if (pageIndex == "page0") {
            prevBtn.isEnabled = false
            if (self.resultObj["page1"] == JSON.null) {
                nextBtn.isEnabled = false
            } else {
                nextBtn.isEnabled = true
            }
        } else if (pageIndex == "page1") {
            prevBtn.isEnabled = true
            if (self.resultObj["page2"] == JSON.null) {
                nextBtn.isEnabled = false
            } else {
                nextBtn.isEnabled = true
            }
        } else if (pageIndex == "page2") {
            prevBtn.isEnabled = true
            nextBtn.isEnabled = false
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.resultObj[pageIndex]["results"].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell") as! CustomTableViewCell
        
        // place name
        cell.placeNameLabel.text = self.resultObj[pageIndex]["results"][indexPath.row]["name"].string
        
        // place address
        cell.placeAddressLabel.text = self.resultObj[pageIndex]["results"][indexPath.row]["vicinity"].string
        

        // category image
        let url = URL(string: self.resultObj[pageIndex]["results"][indexPath.row]["icon"].string!)
        let session = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            DispatchQueue.main.async {
                let image = UIImage(data: data!)
                cell.categoryImage.image = image
                cell.setNeedsLayout()
            }
        }
        session.resume()
        
        // favorite image (filled or empty)
        if (self.keysArr.contains(self.resultObj[pageIndex]["results"][indexPath.row]["place_id"].string!)) {
            let btnImg = UIImage(named: "favorite-filled")
            let tintedImage = btnImg?.withRenderingMode(.alwaysTemplate)
            cell.favoriteImage.setImage(tintedImage, for: UIControlState.normal)
            cell.favoriteImage.tintColor = .red
        } else {
            let btnImg = UIImage(named: "favorite-empty")
            let tintedImage = btnImg?.withRenderingMode(.alwaysTemplate)
            cell.favoriteImage.setImage(tintedImage, for: UIControlState.normal)
            cell.favoriteImage.tintColor = .black
        }
        cell.favoriteImage.tag = indexPath.row
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetails", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let tabCtrl : UITabBarController = segue.destination as! UITabBarController
        
        // send data to InfoViewController
        let destVC = tabCtrl.viewControllers![0] as! InfoViewController
        // destVC.rowObj = self.resultObj[pageIndex]["results"][tableView.indexPathForSelectedRow!.row]
        destVC.placeId = self.resultObj[pageIndex]["results"][tableView.indexPathForSelectedRow!.row]["place_id"].string!
        
        // send data to PhotosViewController
        let destVC2 = tabCtrl.viewControllers![1] as! PhotosViewController
        destVC2.placeId = self.resultObj[pageIndex]["results"][tableView.indexPathForSelectedRow!.row]["place_id"].string!
        
        // send data to MapViewController
        let destVC3 = tabCtrl.viewControllers![2] as! MapViewController
        destVC3.latitude = self.resultObj[pageIndex]["results"][tableView.indexPathForSelectedRow!.row]["geometry"]["location"]["lat"].double!
        destVC3.longitude = self.resultObj[pageIndex]["results"][tableView.indexPathForSelectedRow!.row]["geometry"]["location"]["lng"].double!
        
        // send data to ReviewsViewController
        let destVC4 = tabCtrl.viewControllers![3] as! ReviewsViewController
        destVC4.placeId = self.resultObj[pageIndex]["results"][tableView.indexPathForSelectedRow!.row]["place_id"].string!
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.keysArr = UserDefaults.standard.stringArray(forKey: "keysArr")!
        self.tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections: Int = 1
        if (self.resultObj[pageIndex]["status"].string == "ZERO_RESULTS") {
            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text = "No results"
            noDataLabel.textColor = UIColor.black
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
            numOfSections = 0
        }
        else {
            tableView.separatorStyle = .singleLine
            numOfSections = 1
            tableView.backgroundView = nil
        }
        
        return numOfSections
    }
}
