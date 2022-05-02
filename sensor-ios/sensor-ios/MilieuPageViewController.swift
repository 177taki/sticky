//
//  MilieuPageController.swift
//  sensor-ios
//
//  Created by taki on 8/31/16.
//  Copyright © 177taki. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import AlamofireObjectMapper
import RealmSwift
import Firebase
import CircleSlider
import Toast_Swift
import MapKit

private let reuseIdentifier = "MilieuPage"
private let milieuViewPageControllerIdentifier = "MilieuPageViewController"

class MilieuPageViewController: UIPageViewController, UIPopoverPresentationControllerDelegate, MKMapViewDelegate {
    
    let realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "InMemoryMilieu"))
    
    private var sensorId: String!
    
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var situationImage: UIImageView!
    var trayView: UIView!
    var sliderArea: UIView!
    var trayOriginalCenter: CGPoint!
    var trayDownOffset: CGFloat!
    var trayUp: CGPoint!
    var trayDown: CGPoint!
    
    private var prevValue: Int = 0
    private var index: Int = 0
    private var wise: SliderDirection = .NOWARD
    
    private var sliderOptions: [CircleSliderOption] {
        return [
            .BarColor(UIColor(red: 179/255, green: 179/255, blue: 179/255, alpha: 1)),
            .TrackingColor(UIColor(red: 179/255, green: 179/255, blue: 179/255, alpha: 1)),
            .ThumbColor(UIColor.blackColor()),
//            .ThumbImage(UIImage(named: "ic_expand_less_white_48pt")!),
            .ThumbWidth(44),
            .BarWidth(56),
            .StartAngle(-90),
            .MaxValue(4),
            .MinValue(0)
        ]
    }
    private var circleSlider: CircleSlider!
    
    private var mapView: MKMapView!
    private var button: UIButton!
   
    final var currentID = ""
    var currentIndex: Int = 0 {
        didSet(previousIndex) {
            let direction: UIPageViewControllerNavigationDirection = currentIndex > previousIndex ? .Forward : .Reverse
            self.setViewControllers([self.viewControllerAtIndex(currentIndex)], direction: direction, animated: true, completion: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sensorId = FIRAuth.auth()?.currentUser!.uid
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sliderSize: CGFloat = 256
        
        let margin: CGFloat = 0
        let deviceBounds = UIScreen.mainScreen().bounds
        
        self.trayView = UIView(frame: CGRect(x: 0, y: 0, width: deviceBounds.size.width - margin, height: sliderSize))
        self.sliderArea = UIView(frame: CGRect(x: 0, y: margin, width: sliderSize, height: sliderSize))
        self.sliderArea.center.x = trayView.center.x
        self.circleSlider = CircleSlider(frame: self.sliderArea.bounds, options: sliderOptions)
        self.circleSlider?.addTarget(self, action: #selector(MilieuPageViewController.valueChanged(_:)), forControlEvents: .ValueChanged)
        self.sliderArea.addSubview(self.circleSlider!)
        self.trayView.addSubview(self.sliderArea)
        
        var style = ToastStyle()
        style.backgroundColor = UIColor.blackColor()
        style.messageColor = UIColor.whiteColor()
        ToastManager.shared.style = style
        ToastManager.shared.queueEnabled = false
        
        mapView = MKMapView(frame: self.trayView.bounds)
        mapView.hidden = true
        self.trayView.addSubview(self.mapView)
        self.mapView.delegate = self
        
        button = UIButton(type: .InfoLight)
        button.setImage(UIImage(named: "Map-25"), forState: .Normal)
        button.addTarget(self, action: #selector(MilieuPageViewController.buttenTapped(_:)), forControlEvents: .TouchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        self.trayView.addSubview(button)
        self.trayView.addConstraints([
            NSLayoutConstraint(
                item: self.button,
                attribute: .Bottom,
                relatedBy: .Equal,
                toItem: self.trayView,
                attribute: .Bottom,
                multiplier: 1.0,
                constant: -10
                ),
            NSLayoutConstraint(
                item: self.button,
                attribute: .Trailing,
                relatedBy: .Equal,
                toItem: self.trayView,
                attribute: .Trailing,
                multiplier: 1.0,
                constant: -25
                )])
        
        self.pullMilieu()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for subView in self.view.subviews {
            if subView.isKindOfClass(UIScrollView) {
                subView.frame = self.view.bounds
                self.view.bringSubviewToFront(subView)
            } else if subView.isKindOfClass(UIPageControl) {
                self.view.willRemoveSubview(subView)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.rightCalloutAccessoryView = UIButton(type: .InfoLight)
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let selectedIndex = (view.annotation as! IndexedMKPointAnnotation).index {
            self.index = selectedIndex
            self.currentIndex = self.index
        }
    }
    
    func putPointAnnotation() {
        var points: [CLLocationCoordinate2D] = []
        var numberOfPoints: Int = 0
        var centerX: Double = 0, centerY: Double = 0, count: Double = 0
        for (i, item) in realm.objects(Series.self).sorted("timestamp", ascending: false).enumerate() {
            let lat = item.location?.latitude
            let lng = item.location?.longitude
            if let latitude = Double(lat!), let longitude = Double(lng!) {
                let annotation = IndexedMKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                annotation.title = item.title
                annotation.index = i
                self.mapView.addAnnotation(annotation)
                
                centerX += latitude
                centerY += longitude
                
                count += 1
            }
            let clat = item.location_cxt?.latitude
            let clng = item.location_cxt?.longitude
            if clat != "" && clng != "" {
               points += [CLLocationCoordinate2DMake(CLLocationDegrees(clat!)!, CLLocationDegrees(clng!)!)]
                numberOfPoints += 1
            }
        }
        let polyLine = MKPolyline(coordinates: &points, count: numberOfPoints)
        mapView.addOverlay(polyLine)
        if (centerX != 0) && (centerY != 0) {
            let center = CLLocationCoordinate2DMake(centerX/count, centerY/count)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let regin = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(regin, animated: true)
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let polyLineRendere: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
        polyLineRendere.lineWidth = 5
        polyLineRendere.strokeColor = UIColor.blueColor()
        return polyLineRendere
    }
    
    func buttenTapped(sender: UIButton) {
        if (mapView.hidden) {
            mapView.hidden = false
            button.setImage(UIImage(named: "Clock-25"), forState: .Normal)
        } else {
            mapView.hidden = true
            button.setImage(UIImage(named: "Map-25"), forState: .Normal)
        }
    }
    
    func valueChanged(sender: CircleSlider) {
        switch wise.direction(self.prevValue, current: Int(sender.value)) {
        case .ONWARD:
            break
        case .CLOCKWISE:
            if index == 0 {
                self.trayView.makeToast("No newer items.", duration: 1.2, position: .Top)
                break
            }
            index -= 1
            self.currentIndex = index
        case .ANTICLOCKWISE:
            index += 1
            if index == self.realm.objects(Series).count || self.realm.objects(Series.self).count == 0 {
                index -= 1
                self.trayView.makeToast("No older items.", duration: 1.2, position: .Top)
                break
            }
            self.currentIndex = index
        default:
            return
        }
        self.prevValue = Int(sender.value)
    }
    
    @IBAction func didTapTray(sender: UIBarButtonItem) {
        putPointAnnotation()
        
        let deviceBounds = UIScreen.mainScreen().bounds
        let sliderUIViewController: UIViewController = UIViewController()
        sliderUIViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
        sliderUIViewController.preferredContentSize = CGSizeMake(deviceBounds.size.width, 256)
        sliderUIViewController.view.addSubview(self.trayView)
        
        sliderUIViewController.popoverPresentationController?.delegate = self
        sliderUIViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Down
        sliderUIViewController.popoverPresentationController?.barButtonItem = sender
        sliderUIViewController.popoverPresentationController?.backgroundColor = UIColor(red: 227/255, green: 227/255, blue: 227/255, alpha: 1)
        
        self.navigationController?.hidesBarsOnSwipe = false
        self.presentViewController(sliderUIViewController, animated: true, completion: nil)
    }
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        self.navigationController?.hidesBarsOnSwipe = true
    }
    

    func viewControllerAtIndex(index: Int) -> MilieuPage {
        let page = self.storyboard?.instantiateViewControllerWithIdentifier(reuseIdentifier) as! MilieuPage
        let item = self.realm.objects(Series).sorted("timestamp", ascending: false)[index]
        let url = item.website != "" ? item.website! : item.mainpage!
        let urlStr = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        page.pageUrl = NSURL(string: urlStr!)
        page.id = item.id
        self.currentID = item.id!
        situationImage.tintColor = UIColor.whiteColor()
        situationImage.image = UIImage(named: Situation(rawValue: item.situation!)!.catalogID())?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
//        self.navigationItem.titleView = uv
//        self.navigationItem.titleView?.sizeToFit()
//        self.navigationController?.navigationBar.setNeedsLayout()
        self.navigationItem.prompt = item.title
        
        if item.subsctiption {
            actionButton.enabled = false
        }
        return page
    }
    
    func pullMilieu() {
        Alamofire.request(.GET, Backend.milieu_api, parameters: ["sensor": self.sensorId ])
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
                        self.index = 0
                        self.currentIndex = 0
//                        self.setViewControllers([self.viewControllerAtIndex(0)], direction: .Forward, animated: false, completion: nil)
                    } catch let error as NSError {
                        //TODO: Handle error
                    }
                default:
                    break
                }
        }
        
    }
    
    @IBAction func willRefresh(sender: UIBarButtonItem) {
        pullMilieu()
    }
    
    @IBAction func willRegister(sender: UIBarButtonItem) {
        Alamofire.request(.POST, Backend.series_api+"/\(self.currentID)", parameters: [ "sensor": AppDelegate.sensorID])
            .validate()
            .responseString { response in
                if response.result.isSuccess {
                    let dialog: UIAlertController = UIAlertController(title: "Subscription", message: "complete", preferredStyle: .Alert)
                    self.presentViewController(dialog, animated: true) { () -> Void in
                        let delay = 2 * NSEC_PER_SEC
                        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                        dispatch_after(time, dispatch_get_main_queue(), {
                            self.dismissViewControllerAnimated(true, completion: nil)
                        })
                    }
                }
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

enum SliderDirection: Int {
    case NOWARD = 0
    case CLOCKWISE
    case ANTICLOCKWISE
    case ONWARD
    
    mutating func direction(prev: Int, current: Int) -> SliderDirection {
        switch current - prev {
        case 1, -3:
            switch self {
            case .CLOCKWISE:
                if current%2 == 0 {
                    return .CLOCKWISE
                }
                self = .CLOCKWISE
            default:
                self = .CLOCKWISE
            }
        case -1, 3:
            switch self {
            case .ANTICLOCKWISE:
                if current%2 == 1 {
                    return .ANTICLOCKWISE
                }
                self = .ANTICLOCKWISE
            default:
                self = .ANTICLOCKWISE
            }
        default:
            return .NOWARD
        }
        return .ONWARD
    }
}

class IndexedMKPointAnnotation: MKPointAnnotation {
    var index: Int?
}

