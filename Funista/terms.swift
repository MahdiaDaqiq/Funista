//
//  terms.swift
//  Funista
//
//  Created by basira daqiq on 8/22/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class Terms: UIViewController {
   
    @IBOutlet weak var policy: UIButton!
    @IBOutlet weak var terms: UIButton!
  
    @IBOutlet weak var logOut: UIButton!
    var authHandle: AuthStateDidChangeListenerHandle?

    
    @IBAction func logOutTapped(_ button: UIButton, on headerView: ProfileHeaderView) {
        AuthService.presentLogOut(viewController: self)
     
    }
    
        override func viewDidLoad() {
    
            super.viewDidLoad()
            authHandle = AuthService.authListener(viewController: self)
            
            logOut.layer.cornerRadius = 6
            logOut.layer.borderColor = UIColor.lightGray.cgColor
            logOut.layer.borderWidth = 1
            
            terms.layer.cornerRadius = 6
            terms.layer.borderColor = UIColor.lightGray.cgColor
            terms.layer.borderWidth = 1
            
            policy.layer.cornerRadius = 6
            policy.layer.borderColor = UIColor.lightGray.cgColor
            policy.layer.borderWidth = 1
    
        }
        deinit {
            AuthService.removeAuthListener(authHandle: authHandle)
        }
    
}

