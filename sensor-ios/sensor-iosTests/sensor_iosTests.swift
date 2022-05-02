//
//  sensor_iosTests.swift
//  sensor-iosTests
//
//  Created by taki on 8/1/16.
//  Copyright © 177taki. All rights reserved.
//

import XCTest
@testable import sensor_ios

class sensor_iosTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let lat = "35.6813"
        let lng = "139.7662"
        
        let date = NSDate()
        let timestamp = date.timeIntervalSince1970
        
//        let geoSensor = GeogSensor()
//        geoSensor.cxt = ["moment": "7 pm", "address": "Tokyo Sta.",  "location": ["lat": lat, "lng": lng], "situation": "place", "timestamp": timestamp]
//        geoSensor.getVenusFourSquare(lat, longitude: lng)
    }
    
    func testFeedlyAPIClient() {
        
        let client = FeedlyAPIClient()
        let streamId = "feed/http://feeds.engadget.com/weblogsinc/engadget"
        let params = PaginationParams()
        print("feedlyAPIClitn")
        print(client)
        client.fetchContents(streamId, paginationParams: params) { (response) -> Void in
            print(response.result.value)
            switch response.result {
            case .Success(let results):
                print(results.items)
            case .Failure(let error):
                print("error: \(error)")
            }
        }       
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
