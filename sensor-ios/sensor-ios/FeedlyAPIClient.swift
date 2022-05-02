//
//  FeedlyRouter.swift
//  sensor-ios
//
//  Created by taki on 9/7/16.
//  Copyright © 177taki. All rights reserved.
//

import Foundation

import Alamofire
import AlamofireObjectMapper

public typealias AccessToken = String

public protocol ParameterEncodable {
    func toParameters() -> [String: AnyObject]
}

public extension Alamofire.ParameterEncoding {
    func encode(URLRequest: URLRequestConvertible, parameters: ParameterEncodable?) -> (NSMutableURLRequest, NSError?) {
        return encode(URLRequest, parameters: parameters?.toParameters())
    }
}

extension NSMutableURLRequest {
    func addParam(params: AnyObject) -> NSMutableURLRequest {
        let data = try? NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions.PrettyPrinted)
        self.HTTPBody = data
        self.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return self
    }
}

public class FeedlyAPIClient {
    static let baseUrl = "http://cloud.feedly.com"
    
    public var manager: Alamofire.Manager!
    
    public init() {
        manager = Alamofire.Manager(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
    }
    
    public func setAccessToken(accessToken: AccessToken?) {
        let configuration = manager.session.configuration
        var headers = configuration.HTTPAdditionalHeaders ?? [:]
        if let token = accessToken {
            headers["Authorization"] = "OAuth \(token)"
        } else {
            headers.removeValueForKey("Authorization")
        }
        configuration.HTTPAdditionalHeaders = headers
        manager = Alamofire.Manager(configuration: configuration)
    }
    
    
    public enum Router: URLRequestConvertible {
        var comma: String { return "," }
        func urlEncode(string: String) -> String {
            return string.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        }
        
        //Feeds
        case FetchFeeds([String])
        //Entries
        case FetchEntries([String])
        //Streams
        case FetchContents(String, PaginationParams)
        
        var method: Alamofire.Method {
            switch self {
            case .FetchFeeds:    return .POST
            case .FetchEntries: return .POST
            case .FetchContents: return .GET
            }
        }
        
        var url: String {
            switch  self {
            case .FetchFeeds(_):    return FeedlyAPIClient.baseUrl + "/v3/feeds/.mget"
            case .FetchEntries(_):  return FeedlyAPIClient.baseUrl + "/v3/entries/.mget"
            case .FetchContents(let streamId, _):    return FeedlyAPIClient.baseUrl + "/v3/streams/" + urlEncode(streamId) + "/contents"
            }
        }
        
        public var URLRequest: NSMutableURLRequest {
            let J = Alamofire.ParameterEncoding.JSON
            let U = Alamofire.ParameterEncoding.URL
            let URL = NSURL(string: url)!
            let req = NSMutableURLRequest(URL: URL)
            
            req.HTTPMethod = method.rawValue
            
            switch self {
            case .FetchFeeds(let feedIds):   return req.addParam(feedIds)
            case .FetchEntries(let entryIds):  return  req.addParam(entryIds)
            case .FetchContents(_, let params):   return U.encode(req, parameters: params).0
            }
        }
    }
    
    
}
