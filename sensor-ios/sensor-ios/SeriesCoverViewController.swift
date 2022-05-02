//
//  SeriesCoverViewController.swift
//  sensor-ios
//
//  Created by taki on 9/2/16.
//  Copyright © 177taki. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class SeriesCoverViewController: UIViewController {

    var imageUrl: NSURL?
    var coverImage: UIImageView?
    
    init(imageUrl: NSURL) {
        super.init(nibName: nil, bundle: nil)
        self.imageUrl = imageUrl
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coverImage = UIImageView(frame: UIScreen.mainScreen().bounds)
//        coverImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        coverImage?.userInteractionEnabled = true
        coverImage?.af_setImageWithURL(imageUrl!)
        
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SeriesCoverViewController.dismissSelfOnTap(_:)))
//        coverImage?.addGestureRecognizer(tapGestureRecognizer)
        self.view.addSubview(coverImage!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func dismissSelfOnTap(tapGestureRecognizer: UITapGestureRecognizer) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
