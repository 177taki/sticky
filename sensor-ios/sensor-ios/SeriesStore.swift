//
//  milieuStore.swift
//  sensor-ios
//
//  Created by taki on 8/2/16.
//  Copyright © 177taki. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper

class Series: Object, Mappable {
    dynamic var id: String?
    
    dynamic var version: String?
    dynamic var subject: String?
    dynamic var predicate: String?
    dynamic var author: String?
    dynamic var title: String?
    dynamic var depiction: String?
    dynamic var image: String?
    dynamic var uri: String?
    dynamic var mainpage: String?
    dynamic var icon: String?
    dynamic var location: Coordinates?
    
    dynamic var moment: String?
    dynamic var address: String?
    dynamic var location_cxt: Coordinates?
    dynamic var look: String?
    dynamic var website: String?
    dynamic var situation: String?
    dynamic var timestamp: Int = 0
    
    var subsctiption: Bool = false
    
    required convenience init?(_ map: Map) {
        self.init()
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func mapping(map: Map) {
        id <- map["Series.Id"]
        
        version <- map["Series.Attributes.Version"]
        subject <- map["Series.Attributes.Subject"]
        predicate <- map["Series.Attributes.Predicate"]
        author <- map["Series.Atributes.Author"]
        title <- map["Series.Attributes.Title"]
        depiction <- map["Series.Attributes.Depiction"]
        image <- map["Series.Attributes.Image"]
        uri <- map["Series.Attributes.Uri"]
        mainpage <- map["Series.Attributes.Mainpage"]
        icon <- map["Series.Attributes.Icon"]
        location <- map["Series.Attributes.Location"]

        moment <- map["Context.Moment"]
        address <- map["Context.Address"]
        location_cxt <- map["Context.Location"]
        look <- map["Context.Look"]
        website <- map["Context.Website"]
        situation <- map["Context.Situation"]
        timestamp <- map["Context.Timestamp"]
    }
}

class Coordinates: Object, Mappable {
    dynamic var latitude: String?
    dynamic var longitude: String?
    
    required convenience init?(_ map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        latitude <- map["Lat"]
        longitude <- map["Lng"]
    }
}
