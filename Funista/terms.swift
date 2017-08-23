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
   
    
    @IBOutlet weak var logOut: UIButton!
    var authHandle: AuthStateDidChangeListenerHandle?

    
    @IBAction func logOutTapped(_ button: UIButton, on headerView: ProfileHeaderView) {
        AuthService.presentLogOut(viewController: self)
     
    }
    
        override func viewDidLoad() {
    
            super.viewDidLoad()
            authHandle = AuthService.authListener(viewController: self)
    
        }
        deinit {
            AuthService.removeAuthListener(authHandle: authHandle)
        }
   
}

