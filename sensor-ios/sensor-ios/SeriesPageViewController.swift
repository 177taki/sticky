//
//  SeriesPageViewController.swift
//  sensor-ios
//
//  Created by taki on 9/5/16.
//  Copyright © 177taki. All rights reserved.
//

import UIKit
import Alamofire
import SafariServices

class SeriesPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    var streamId: String?
    var coverImageUrl: NSURL?
    
    let paginationParams = PaginationParams()
    
    let client = FeedlyAPIClient()
    
    var content: Content? {
        didSet {
            self.setViewControllers([SeriesCoverViewController(imageUrl: coverImageUrl!)], direction: .Forward, animated: true, completion: nil)
            self.didMoveToParentViewController(self)
        }
    }
    
    var index: Int = 0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        getPages()
    }

    func getPages() {
        client.fetchContents(streamId!, paginationParams: paginationParams) { (response) -> Void in
            switch response.result {
            case .Success(let results):
                self.content = results
            case .Failure(let error):
                print("error: \(error)")
            }
        }       
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func viewControllerAtIndex(index: Int) -> SFSafariViewController {
        let _url = self.content?.items![index].alternates![0].href
        let _brow = SFSafariViewController(URL: _url!, entersReaderIfAvailable: true)
        return _brow
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        index += 1
        if index == content?.items?.count {
            return nil
        }
        return viewControllerAtIndex(index)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if index == NSNotFound || index == 0 {
            return nil
        }
        index -= 1
        
        if index == 0 {
            return SeriesCoverViewController(imageUrl: coverImageUrl!)
        }
        return viewControllerAtIndex(index)
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        if let count = content?.items?.count {
            return count
        }
        return 0
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
