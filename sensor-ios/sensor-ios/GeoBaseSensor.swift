//
//  milieuSensor.swift
//  sensor-ios
//
//  Created by taki on 8/2/16.
//  Copyright © 177taki. All rights reserved.
//
// This code :
//  - take a current location by CoreLocation
//  - search venues around that
//  - push results by the search to backend store service

import UIKit
import Firebase
import Alamofire
import CoreLocation
import BrightFutures

let MILIEU_STORE_API = "http://localhost:8080/v0/api/milieu"
let FOURSQUARE_SEARCH_API = "https://api.foursquare.com/v2/venues/search"

class GeoBaseSensor: NSObject, CLLocationManagerDelegate {
    
    
    private var locationManager: CLLocationManager!
    
    private var client_id: String!
    private var client_secret: String!
    
    private var names = []
    private var cxt: NSMutableDictionary?
    
    private var sensorId: String!
    
    override init() {
        super.init()
        
        let path = NSBundle.mainBundle().pathForResource("Services-Info", ofType: "plist")
        let apiInfo = NSDictionary(contentsOfFile: path!)
        client_id = apiInfo?.objectForKey("FOURSQUARE_CLIENT_ID") as! String
        client_secret = apiInfo?.objectForKey("FOURSQUARE_CLIENT_SECRET") as! String
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.NotDetermined {
            self.locationManager.requestAlwaysAuthorization()
        }
        
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startMonitoringSignificantLocationChanges()
        
        let fbtest = FBLocalSearch()
    }

    @objc func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let geoCoder = CLGeocoder()
        let current = CLLocation(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        if let user = FIRAuth.auth()?.currentUser {
            self.sensorId = user.uid
        
            geoCoder.reverseGeocodeLocation(current) { (placemarks, error) -> Void in
                if error == nil && placemarks?.count > 0 {
                    let placemark = placemarks![0]
                    let administrativeArea = placemark.administrativeArea ?? ""
                    let locality = placemark.locality ?? ""
                    let thoroughfare = placemark.thoroughfare ?? ""
                    let address = administrativeArea + locality + thoroughfare
                    
                    let lat = String(format: "%.4f", locations[0].coordinate.latitude)
                    let lng = String(format: "%.4f", locations[0].coordinate.longitude)
                    
                    let date = NSDate()
                    let timestamp = Int64(date.timeIntervalSince1970)
                    
                    let cal = NSCalendar.currentCalendar()
                    let comp = cal.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: date)
                    let moment = comp.hour < 12 ? String(comp.hour) + " AM" : String(comp.hour % 12) + " PM"
                    
                    let situation = self.deriveFromSpeed(locations[0].speed).rawValue
                    
                    self.cxt = ["moment": moment, "address": address,  "location": ["lat": lat, "lng": lng], "situation": situation, "timestamp": NSNumber(longLong: timestamp)]
//                    self.getVenusFourSquare(lat, longitude: lng)
                    
                    let fbAPIClient = FBLocalSearch()
                    fbAPIClient.senseByFBGraphAPI(self.sensorId, context: self.cxt!)
                }
            }
            
        }
    }
    
    func resolveFSPhotoURL(index: Int, url: String) -> Future<Void, NoError> {
        let promise = Promise<Void, NoError>()
        let params = ["v": "20160301",
                      "locale": "ja",
                      "limit": 3,
                      "client_id": client_id,
                      "client_secret": client_secret]
        Alamofire.request(.GET, url, parameters: params as? [String : AnyObject])
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                if response.result.isSuccess {
                    let json = response.result.value as! NSDictionary
                    let data = json["response"] as! NSDictionary
                    let photos = data["photos"] as! NSDictionary
                    if let item = photos["items"] as? NSMutableArray {
                        let prefix = item[0]["prefix"] as! String
                        let suffix = item[0]["suffix"] as! String
                        self.names[index].setValue(prefix+"300x300"+suffix, forKeyPath: "attributes.image")
//                        self.names[index].attributes.setValue(prefix+"300x300"+suffix, forKey: "image")
                    }
                    promise.success()
                }
        }
        return promise.future
    }
    
    func getVenusFourSquare(latitude: String, longitude: String) {
        names = []
        
        let parameters = ["v": "20160301",
                          "locale": "ja",
                          "ll": latitude+","+longitude,
                          "limit": 10,
                          "intent": "browse",
                          "radius": 250,
                          "client_id": client_id,
                          "client_secret": client_secret]
        
        var sequence = [Future<Void, NoError>]()
        
        Alamofire.request(.GET, FOURSQUARE_SEARCH_API, parameters: parameters as? [String : AnyObject])
        .validate(statusCode: 200..<300)
            .responseJSON { response in
                if response.result.isSuccess {
                    let json = response.result.value as! NSDictionary
                    let data = json["response"] as! NSDictionary
                    
                    if let venues = data["venues"] as? NSMutableArray {
                        self.names = venues.enumerate().map{ (index, v) -> NSDictionary in
                            let id = v["id"] as! String
                            let title = v["name"] as! String
                            let location = v["location"] as! NSDictionary
                            let address = location["formattedAddress"] as! NSArray
                            let lat = String(format: "%.4f", (location["lat"]?.doubleValue)!)
                            let lng = String(format: "%.4f", (location["lng"]?.doubleValue)!)
                            let depiction = address.componentsJoinedByString(" ")
                            
                            let subject: AnyObject!
                            if let cats = v["categories"] as? NSMutableArray {
                                let cat = cats[0] as? NSDictionary
                                subject = cat!["name"] as! String
                            }
                            else {
                                subject = NSNull()
                            }
                            let uri = v["url"] as? String ?? NSNull()
                            
                            let attributes: NSMutableDictionary = [
                                    "version": "0.1",
                                    "subject": subject,
                                    "title": title,
                                    "depiction": depiction,
                                    "uri": uri,
                                    "location": ["lat": lat, "lng": lng]
                                ]
                            
                            let series: NSMutableDictionary = ["id": id, "attributes": attributes]
                            return series
                        }
                        
                        let ids = self.names.valueForKey("id") as! NSArray
                        ids.enumerate().map { (index, id) in
                            let url = "https://api.foursquare.com/v2/venues/\(id)/photos"
                            sequence.append(self.resolveFSPhotoURL(index, url: url))
                        }
                        
                        sequence.sequence().onComplete {_ in
                            let milieuData = self.names.enumerate().map { (index, v) -> NSDictionary in
                                let data = ["context": self.cxt!, "series": v]
                                return data
                            }
//                            let milieu: NSDictionary = ["sensor": self.sensorId, "series": self.names, "context": self.cxt!]
                            let milieu: NSDictionary = ["sensor": self.sensorId, "data": milieuData]
                            Alamofire.request(.POST, MILIEU_STORE_API, parameters: milieu as? [String : AnyObject], encoding: .JSON)
                        }
                    }
                }
        }
        
    }
    
    func deriveFromSpeed(speed: CLLocationSpeed) -> Situation {
        switch speed*3.6 {
        case 0..<10:
            return .Walk
        case 10..<30:
            return .Bike
        case 30..<80:
            return .Car
        case 80..<300:
            return .Train
        default:
            return .Place
        }
    }
    
}

enum Situation: String {
    case Place = "place"
    case Walk = "walk"
    case Bike = "bike"
    case Car = "car"
    case Train = "train"
    case Flight = "flight"
    case Browse = "www"
    func coloring() -> UIColor {
        switch self {
        case .Walk:
            return UIColor.greenColor()
        case .Bike:
            return UIColor.blueColor()
        case .Car:
            return UIColor.orangeColor()
        case .Train:
            return UIColor.redColor()
        case .Flight:
            return UIColor.purpleColor()
        case .Browse:
            return UIColor.yellowColor()
        default:
            return UIColor.cyanColor()
        }
    }
    func catalogID() -> String {
        switch  self {
        case .Walk:
            return "ic_directions_walk_white_48pt"
        case .Bike:
            return "ic_directions_bike_white_48pt"
        case .Car:
            return "ic_directions_car_white_48pt"
        case .Train:
            return "ic_train_white_48pt"
        case .Browse:
            return "ic_public_white_48pt"
        default:
            return "ic_location_city_white_48pt"
        }
    }
}
