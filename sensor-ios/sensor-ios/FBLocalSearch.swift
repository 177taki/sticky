//
//  FBLocalSearch.swift
//  sensor-ios
//
//  Created by taki on 9/9/16.
//  Copyright © 177taki. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuthUI
import FBSDKCoreKit
import Alamofire
import ObjectMapper

class FBLocalSearch: NSObject {
    
//    let request: FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "search", parameters: ["q": "coffee", "type": "place", "center": "37.76,-122.427", "fields": "id,link,name,category,location"], tokenString: token, version: "v2.7", HTTPMethod: "GET")
    
    override init() {
        super.init()
    }
    
    func senseByFBGraphAPI(sensorId: String, context: NSMutableDictionary) {
        
//        if let token = FBSDKAccessToken.currentAccessToken().tokenString {
        if let token = FUIAuth.defaultAuthUI()?.providers[1].accessToken {
            let _location = context["location"]!
            let center = (_location["lat"] as! String) + "," + (_location["lng"] as! String)
            let request: FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "search", parameters: ["locale": "ja_JP", "type": "place", "center": center, "distance" : "500", "fields": "id,link,name,category,location,picture,cover,description,website"], tokenString: token, version: "v2.7", HTTPMethod: "GET")
            request.startWithCompletionHandler() { (connection, result, error) -> Void in
                if error != nil {
                    print("\(error)")
                }
                else {
                    let hoge = result as! NSDictionary
                    guard let _places = hoge["data"] else { return }
                    let places = Mapper<Place>().mapArray((_places as! NSArray).mutableCopy() as! NSMutableArray)
                    
                    let milieuData = places?.enumerate().map { (index, v) -> NSDictionary in
                        let lat = String(format: "%.4f", (v.location?.latitude)!)
                        let lng = String(format: "%.4f", (v.location?.longitude)!)
                        let attributes: NSMutableDictionary = [
                            "version": "0.1",
                            "subject": v.category!,
                            "title": v.name!,
                            "depiction": v.location!.street ?? v.location!.city ?? "",
                            "mainpage": v.website ?? "",
                            "image": v.cover ?? "",
                            "icon" : v.picture!,
                            "location": ["lat": lat, "lng": lng]
                        ]
                        
                        let _context = context.mutableCopy() as! NSMutableDictionary
                        _context["website"] = v.link ?? ""
                        let series: NSMutableDictionary = ["id": v.id!, "attributes": attributes]
                        
                        let data = ["context": _context, "series": series]
                        return data
                    }
                    
                    let milieu: NSDictionary = ["sensor": sensorId, "data": milieuData!]
                    Alamofire.request(.POST, MILIEU_STORE_API, parameters: milieu as? [String:AnyObject], encoding: .JSON)
                }
            }
            
        }
    }
}


class ResponseData: Mappable {
    var places: [Place]?
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        places <- map["data"]
    }
}

class Place: Mappable {
    var category: String?
    var id: String?
    var link: String?
    var name: String?
    var depiction: String?
    var location: Location?
    var picture: String?
    var cover: String?
    var website: String?
    
    required init?(_ map: Map) {
//        if let website = map.JSONDictionary["website"] {
//            if website as! String == "<<not-applicable>>" {
//                map.JSONDictionary["website"] = nil
//            }
//        }
    }
    
    let validation = TransformOf<String, String>( fromJSON: { (value: String?) -> String? in
        if let value = value {
            if value == "<<not-applicable>>" {
                return nil
            }
        }
        return value
        }, toJSON: { (value: String?) -> String? in
            return value
        })
    
    func mapping(map: Map) {
        category <- map["category"]
        id <- map["id"]
        link <- map["link"]
        name <- map["name"]
        depiction <- map["description"]
        location <- map["location"]
        picture <- map["picture.data.url"]
        cover <- map["cover.source"]
        website <- (map["website"], validation)
    }
}

class Location: Mappable {
    var street: String?
    var city: String?
    var state: String?
    var country: String?
    var latitude: Double?
    var longitude: Double?
    
    required init?(_ map: Map) {
    }
    
    func mapping(map: Map) {
        street <- map["street"]
        city <- map["city"]
        state <- map["state"]
        country <- map["country"]
        latitude <- map["latitude"]
        longitude <- map["longitude"]
    }
}
