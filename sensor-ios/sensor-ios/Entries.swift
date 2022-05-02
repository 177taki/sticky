//
//  Entries.swift
//  sensor-ios
//
//  Created by taki on 9/8/16.
//  Copyright © 177taki All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper


public class Entry: Mappable {
    var title: String?
    var author: String?
    var categores: [Category]?
    var alternates: [Alternate]?
    var originId: String?
    
    public required init?(_ map: Map) {
    }
    
    public func mapping(map: Map) {
        title <- map["title"]
        author <- map["author"]
        categores <- map["categories"]
        alternates <- map["alternate"]
        originId <- map["originId"]
    }
}

struct Category: Mappable {
    var label: String?
    
    init?(_ map: Map) {
    }
    
     mutating func mapping(map: Map) {
        label <- map["label"]
    }
}

struct Alternate: Mappable {
    var href: NSURL?
    var type: String?
    
    init?(_ map: Map) {
    }
    
    mutating func mapping(map: Map) {
        href <- (map["href"], URLTransform())
        type <- map["type"]
    }
}

extension FeedlyAPIClient {
    public func fetchEntries(entryIds: [String], completionHandler: (Response<[Entry], NSError>) -> Void) -> Request {
        return manager.request(Router.FetchEntries(entryIds)).validate().responseArray(completionHandler: completionHandler)
    }
}
