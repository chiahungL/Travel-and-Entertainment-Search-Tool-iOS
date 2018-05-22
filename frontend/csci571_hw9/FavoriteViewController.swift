//
//  FavoriteViewController.swift
//  
//
//  Created by Chia-Hung Lee on 4/19/18.
//

import UIKit
import EasyToast

class FavoriteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct Place {
        var name: String
        var address: String
        var category: String
        var placeId: String
        var lat: String
        var lng: String
    }
    
    var placeDisplayArr: [Place] = []

    // MARK: PROPERTIES
    @IBOutlet weak var seg: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: ACTION
    @IBAction func segValueChanged(_ sender: Any) {
        if (seg.selectedSegmentIndex == 0) {
            self.performSegue(withIdentifier: "searchFormSegue", sender: self)
        }
    }
    
    // MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.seg.selectedSegmentIndex = 1
        self.navigationItem.hidesBackButton = true
        self.navigationItem.title = "Places Search"
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
        
        let defaults = UserDefaults.standard
        
        print(defaults.dictionaryRepresentation())
        
        let keysArr = defaults.stringArray(forKey: "keysArr")
        if (keysArr == nil) {
            defaults.set([], forKey: "keysArr")
        } else {
            for id in keysArr! {
                print("id = \(id)")
                print(defaults.stringArray(forKey: id))
                let newObj = defaults.stringArray(forKey: id)
                let newPlace = Place(name: newObj![0], address: newObj![1], category: newObj![2], placeId: newObj![3], lat: newObj![4], lng: newObj![5])
                placeDisplayArr.append(newPlace)
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //************** update the placeDisPlayArr ***************
        let defaults = UserDefaults.standard
        self.placeDisplayArr = []
        
        let keysArr = defaults.stringArray(forKey: "keysArr")
        for id in keysArr! {
            let newObj = defaults.stringArray(forKey: id)
            let newPlace = Place(name: newObj![0], address: newObj![1], category: newObj![2], placeId: newObj![3], lat: newObj![4], lng: newObj![5])
            self.placeDisplayArr.append(newPlace)
        }
        
        // ****** reloadData to trigger "No favorites" ******
        if (self.placeDisplayArr.count == 0) {
            self.tableView.reloadData()
        }
        return self.placeDisplayArr.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //***** update the placeDisPlayArr *****
        let defaults = UserDefaults.standard
        self.placeDisplayArr = []
        
        let keysArr = defaults.stringArray(forKey: "keysArr")
        for id in keysArr! {
            let newObj = defaults.stringArray(forKey: id)
            let newPlace = Place(name: newObj![0], address: newObj![1], category: newObj![2], placeId: newObj![3], lat: newObj![4], lng: newObj![5])
            self.placeDisplayArr.append(newPlace)
        }

        //****** generate the cell ******
        let cell = tableView.dequeueReusableCell(withIdentifier: "customFavoriteCell") as! FavoriteTableViewCell
        
        cell.placeNameLabel.text = self.placeDisplayArr[indexPath.row].name
        cell.placeAddressLabel.text = self.placeDisplayArr[indexPath.row].address
        
        let url = URL(string: self.placeDisplayArr[indexPath.row].category)
        let session = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            DispatchQueue.main.async {
                let image = UIImage(data: data!)
                cell.categoryImage.image = image
                cell.setNeedsLayout()
            }
        }
        session.resume()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetailsFromFavorite", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var back = UIBarButtonItem()
        back.title = " "
        self.navigationItem.backBarButtonItem = back
        
        
        if (segue.identifier == "showDetailsFromFavorite") {
            let tabCtrl : UITabBarController = segue.destination as! UITabBarController
            
            // send data to InfoViewController
            let destVC = tabCtrl.viewControllers![0] as! InfoViewController
            destVC.placeId = self.placeDisplayArr[tableView.indexPathForSelectedRow!.row].placeId
            
            // send data to PhotosViewController
            let destVC2 = tabCtrl.viewControllers![1] as! PhotosViewController
            destVC2.placeId = self.placeDisplayArr[tableView.indexPathForSelectedRow!.row].placeId
            
            // send data to MapViewController
            let destVC3 = tabCtrl.viewControllers![2] as! MapViewController
            destVC3.latitude = Double(self.placeDisplayArr[tableView.indexPathForSelectedRow!.row].lat)!
            destVC3.longitude = Double(self.placeDisplayArr[tableView.indexPathForSelectedRow!.row].lng)!
            
            // send data to ReviewsViewController
            let destVC4 = tabCtrl.viewControllers![3] as! ReviewsViewController
            destVC4.placeId = self.placeDisplayArr[tableView.indexPathForSelectedRow!.row].placeId
        }
    }

    // MARK: HANDLE DELETION
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("remove indexPath.row = \(indexPath.row)")
            print(self.placeDisplayArr[indexPath.row])
            let defaults = UserDefaults.standard
            var keysArr = defaults.stringArray(forKey: "keysArr")
            
            // remove the keys from self.keysArr, and update it in UserDefaults
            let indexToRemove = keysArr!.index(of: self.placeDisplayArr[indexPath.row].placeId)
            keysArr?.remove(at: indexToRemove!)
            defaults.set(keysArr, forKey: "keysArr")
            
            // remove the object in UserDefaults
            defaults.removeObject(forKey: self.placeDisplayArr[indexPath.row].placeId)
            
            self.view.showToast("\(self.placeDisplayArr[indexPath.row].name)\nwas removed from favorites", position: .bottom, popTime: 3, dismissOnTap: false)
            
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    // HANDLE "NO FAVORITES"
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections: Int = 1
        print("-----------in numberOfSections------------")
        if (self.placeDisplayArr.count == 0) {
            print("---self.placeDisplayArr is empty---")
            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text = "No favorites"
            noDataLabel.textColor = UIColor.black
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
            numOfSections = 0
        } else {
            print("not empty")
            tableView.separatorStyle = .singleLine
            numOfSections = 1
            tableView.backgroundView = nil
        }
        
        return numOfSections
    }
}
