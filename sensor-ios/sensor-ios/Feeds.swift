//
//  Feeds.swift
//  sensor-ios
//
//  Created by taki on 9/8/16.
//  Copyright © 177taki. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

public class Feed: Mappable {
    var feedId: String?
    var visualUrl: NSURL?
    var iconUrl: NSURL?
    var coverUrl: NSURL?
    var title: String?
    var description: String?
    var website: NSURL?
    
    required public init?(_ map: Map) {
    }
    
    public func mapping(map: Map) {
        feedId <- map["id"]
        visualUrl <- (map["visualUrl"], URLTransform())
        iconUrl <- (map["iconUrl"], URLTransform())
        coverUrl <- (map["coverUrl"], URLTransform())
        title <- map["title"]
        description <- map["description"]
        website <- (map["website"], URLTransform())
    }
    
}

extension FeedlyAPIClient {
    public func fetchFeeds(feedIds: [String], completionHandler: (Response<[Feed], NSError>) -> Void) -> Request {
        return manager.request(Router.FetchFeeds(feedIds)).validate().responseArray(completionHandler: completionHandler)
    }
}
