//
//  MilieuViewPage.swift
//  sensor-ios
//
//  Created by taki on 8/31/16.
//  Copyright © 177taki. All rights reserved.
//

import UIKit
import WebKit
import Alamofire

class MilieuPage: UIViewController, WKNavigationDelegate {

    var webView: WKWebView?
    var pageUrl: NSURL?
    var pageTitle: String?
    
    var id: String?
    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
         self.webView?.scrollView.scrollEnabled = true
        self.webView = WKWebView()
        self.webView!.navigationDelegate = self
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.userInteractionEnabled = true
       
        self.view.addSubview(self.webView!)
        self.webView?.frame = self.view.bounds
        self.webView?.frame.size.width -= 2
//        self.webView?.frame = UIScreen.mainScreen().bounds
        
        self.webView?.allowsBackForwardNavigationGestures = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.webView!.loadRequest(NSURLRequest(URL: pageUrl!))
    }
    
    override func viewDidLayoutSubviews() {
        self.webView!.scrollView.contentInset.top = (self.navigationController?.navigationBar.frame.height)!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
