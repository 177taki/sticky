//
//  Contents.swift
//  sensor-ios
//
//  Created by taki on 9/8/16.
//  Copyright © 177taki All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

public class PaginationParams: ParameterEncodable {
    public var count: Int?
    public var ranked: String?
    public var unreadOnly: Bool?
    public var newerThan: Int64?
    public var continuation: String?
    public init() {}
    public func toParameters() -> [String : AnyObject] {
        var params: [String:AnyObject] = [:]
        if let _count = count { params["count"] = _count }
        if let _ranked = ranked { params["ranked"] = _ranked }
        if let _unreadOnly = unreadOnly { params["unreadOnly"] = _unreadOnly ? "true" : "false" }
        if let _continuation = continuation { params["continuation"] = _continuation }
        return params
    }
}

public class Content: Mappable {
    var updated: Int64?
    var continuation: String?
    var items: [Entry]?
    
    required public init?(_ map: Map) {
    }
    
    public func mapping(map: Map) {
        updated <- map["updated"]
        continuation <- map["continuation"]
        items <- map["items"]
    }
}

extension FeedlyAPIClient {
    public func fetchContents(streamId: String, paginationParams: PaginationParams, completionHandler: (Response<Content, NSError>) -> Void) -> Request {
        return manager.request(Router.FetchContents(streamId, paginationParams)).validate().responseObject(completionHandler: completionHandler)
    }
}
