//
//  topViewController.swift
//  sensor-ios
//
//  Created by taki on 8/23/16.
//  Copyright © 177taki. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseFacebookAuthUI
import FBSDKCoreKit
import FBSDKLoginKit

let kFirebaseTermsOfService = NSURL(string: "https://firebase.google.com/terms/")!
let kGoogleAppClientID = (FIRApp.defaultApp()?.options.clientID)!
let kFacebookAppID = FBID

enum Providers: Int, RawRepresentable {
    case Email = 0
    case Google
    case Facebook
}

class TopViewController: UIViewController {
    private var initialized: Bool = false
    
    private var authStateDidChangeHandle: FIRAuthStateDidChangeListenerHandle?
    
    private(set) var auth: FIRAuth?
    private(set) var authUI: FUIAuth?
//    private(set) var authUIDelegate: FUIAuthDelegate

    @IBOutlet weak var signInButton: UIButton!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.authStateDidChangeHandle = self.auth?.addAuthStateDidChangeListener(self.updateUI(auth:user:))
        self.navigationController?.toolbarHidden = false
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth = FIRAuth.auth()
        authUI = FUIAuth.defaultAuthUI()
        
        self.authUI?.TOSURL = kFirebaseTermsOfService
        
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth(scopes: [kGooglePlusMeScope,kGoogleUserInfoEmailScope,kGoogleUserInfoProfileScope]),
            FUIFacebookAuth(permissions: ["email", "user_friends", "ads_read"])
        ]
        self.authUI?.providers = providers
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let handle = self.authStateDidChangeHandle {
            self.auth?.removeAuthStateDidChangeListener(handle)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func signInPressed(sender: UIButton) {
        let controller = self.authUI!.authViewController()
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func updateUI(auth auth: FIRAuth, user: FIRUser?) {
        if user != nil && initialized && FBSDKAccessToken.currentAccessToken() != nil {
            self.signInButton.enabled = false
            
//            let milieuViewController = MilieuViewController.fromStoryboard()
//            self.presentViewController(milieuViewController, animated: true, completion: nil)
//            let milieuViewPageController = MilieuViewPageController.fromStoryboard()
            let navc = AppDelegate.mainStoryboard.instantiateViewControllerWithIdentifier("StartNavController") as! UINavigationController
//            navc.pushViewController(milieuViewPageController, animated: true)
            self.presentViewController(navc, animated: true, completion: nil)
        } else {
//            do {
//                try self.auth?.signOut()
//            } catch let error {
//                fatalError("\(error)")
//            }
        }
        initialized = true /* This work arround that updateUI is called twice when booted in a tricky way */
    }
    
}
