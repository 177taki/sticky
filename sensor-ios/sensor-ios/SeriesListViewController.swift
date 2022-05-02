//
//  SeriesListViewController.swift
//  sensor-ios
//
//  Created by taki on 9/2/16.
//  Copyright © 177taki. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import RZTransitions
import SafariServices

private let reuseIdentifier = "SeriesCollectionViewCell"

class SeriesListViewController: UIViewController
    , UICollectionViewDelegate
    , UICollectionViewDataSource
    , UIViewControllerTransitioningDelegate
    , RZTransitionInteractionControllerDelegate
    , RZCirclePushAnimationDelegate
    , RZRectZoomAnimationDelegate {

    @IBOutlet weak var seriesCollectionView: UICollectionView!
    
    let realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "InMemorySeries"))
    
    var circleTransitionStartPont: CGPoint = CGPointZero
    var transitionCellRect: CGRect = CGRectZero
    var presentOverscrollInteractor: RZOverscrollInteractionController?
    var presentDismissAnimationController: RZRectZoomAnimationController?
    
    var series: Results<Series>? {
        didSet {
            let uris = series?.filter("uri != ''").valueForKey("uri")
//            print (uris)
            self.seriesCollectionView.reloadData()
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presentDismissAnimationController = RZRectZoomAnimationController()
        presentDismissAnimationController?.rectZoomDelegate = self
        
        RZTransitionsManager.shared().setAnimationController(presentDismissAnimationController, fromViewController: self.dynamicType, forAction: .PresentDismiss)
        
        transitioningDelegate = RZTransitionsManager.shared()
        
        self.seriesCollectionView.delegate = self
        self.seriesCollectionView.dataSource = self
        
        pullMilieu()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func pullMilieu() {
        Alamofire.request(.GET, Backend.milieu_api, parameters: ["sensor": AppDelegate.sensorID, "subscription": "true"])
            .validate(statusCode: [200])
            .validate(contentType: ["application/json"])
            .responseArray { (response: Response<[Series], NSError>) in
                switch response.result {
                case .Success(let series):
                    do {
                        try self.realm.write {
                            for _series in series {
                                self.realm.add(_series, update: true)
                            }
                        }
                        self.series = self.realm.objects(Series).sorted("timestamp", ascending: false)
                    } catch let error as NSError {
                        //TODO: Handle error
                    }
                default:
                    break
                }
                //                let ss = self.realm.objects(Series)
        }
        
    }
    
    func newViewController(id: String?) -> UIViewController? {
        let item = self.realm.objectForPrimaryKey(Series.self, key: id)
//        let newVC = SeriesCoverViewController(imageUrl: NSURL(string: (item?.image)!)!)
        if item?.uri! != "" {
            let newVC = AppDelegate.mainStoryboard.instantiateViewControllerWithIdentifier("SeriesPageViewController") as! SeriesPageViewController
            newVC.streamId = "feed/" + (item?.uri)!
            newVC.coverImageUrl = NSURL(string: (item?.image)!)
            newVC.transitioningDelegate = RZTransitionsManager.shared()
            return newVC
        } else {
            let mainUrl = item?.mainpage != "" ? item?.mainpage! : item?.website!
            let newVC = SFSafariViewController(URL: NSURL(string: mainUrl!)!, entersReaderIfAvailable: true)
            newVC.modalPresentationStyle = .OverCurrentContext
            return newVC
        }
        return nil
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if ((self.series?.count) != nil) {
            return self.series!.count
        } else {
            return 0
        }
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? SeriesCollectionViewCell else {
            fatalError("No cell at \(indexPath)")
        }
        
        let toVC = newViewController(cell.id!)
        
        circleTransitionStartPont = collectionView.convertPoint(cell.center, toView: view)
        transitionCellRect = collectionView.convertRect(cell.frame, toView: view)
        
        self.presentViewController(toVC!, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! SeriesCollectionViewCell
        
        cell.image.image = nil
        cell.layer.borderColor = UIColor.whiteColor().CGColor
        cell.layer.borderWidth = 0.5
        cell.layer.cornerRadius = 3
        cell.backgroundColor = UIColor.whiteColor()
        
        let item = self.realm.objects(Series)[indexPath.row]
        cell.subject.text = item.subject
        cell.predicate.text = item.predicate
        cell.author.text = item.author
        cell.title.text = item.title
        
        let img = item.image! != "" ? item.image! : item.icon!
        cell.image.af_setImageWithURL(NSURL(string: img)!)
        
        cell.id = item.id
        
        return cell
    }
  
    @IBAction func back(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func nextViewControllerForInteractor(interactor: RZTransitionInteractionController!) -> UIViewController! {
        return newViewController(nil)
    }
    func rectZoomPosition() -> CGRect {
        return transitionCellRect
    }
    func circleCenter() -> CGPoint {
        return circleTransitionStartPont
    }
    func circleStartingRadius() -> CGFloat {
        return 90
    }
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
}
