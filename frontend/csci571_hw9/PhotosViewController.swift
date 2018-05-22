//
//  PhotosViewController.swift
//  csci571_hw9
//
//  Created by Chia-Hung Lee on 4/13/18.
//  Copyright © 2018 Chia-Hung Lee. All rights reserved.
//

import UIKit
import GooglePlaces

class PhotosViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var placeId = ""
    var photoList = [UIImage]()
    var thePhoto = UIImage()
    var photoIndex = 0
    let myGroup = DispatchGroup()
    var finishDownloading = false
    
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var test: UIImageView!
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        
        super.viewDidLoad()
        
        print("--in PhotosViewController--")
        print("placeId = \(placeId)")
        
        self.loadPhotoForPlace(placeID: placeId)

        
//        tableView.rowHeight = UITableViewAutomaticDimension
//        tableView.estimatedRowHeight = 200
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.photoList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customPhotoCell") as! PhotosTableViewCell
        
        if (self.photoList.count != 0) {
            cell.placeImage.image = self.photoList[indexPath.row]
        }
        
        return cell
    }

    func loadPhotoForPlace(placeID: String) {
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: placeID) { (photos, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
            } else {
                for p in (photos?.results)! {
                    self.myGroup.enter()
                    self.loadImageForMetadata(photoMetadata: p)
                }
                self.myGroup.notify(queue: .main) {
                    print("Finished all requests.")
                    self.finishDownloading = true
                    self.tableView.reloadData()
                }
                
            }
        }
    }
    
    func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata) {
        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata, callback: {
            (photo, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
            } else {
                // self.imageView.image = photo
                // self.attributionTextView.attributedText = photoMetadata.attributions;
                self.thePhoto = photo!
                self.photoList.append(photo!)
                print("-->type of photo: \(type(of: photo))")
                print("\(self.photoList)")
                self.myGroup.leave()
            }
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections: Int = 1
        if (self.finishDownloading) {
            if (self.photoList.count == 0) {
                let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
                noDataLabel.text = "No photos"
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
        
        return numOfSections
    }

}
