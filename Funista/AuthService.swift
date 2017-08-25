//
//  AuthService.swift
//  Funista
//
//  Created by basira daqiq on 8/22/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//

import Foundation

import UIKit
import FirebaseAuth

struct AuthService {
    
    static func presentLogOut(viewController : UIViewController){
        let alertController = UIAlertController(title: "Are You Sure You Want To Log Out?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        let logoutAction = UIAlertAction(title: "Log Out", style: .default){_ in
            logUserOut()
        }
        alertController.addAction(logoutAction)
        
        viewController.present(alertController, animated: true)
    }
    
    
    static func logUserOut(){
        do {
            try Auth.auth().signOut()
        } catch let error as NSError {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    //will allow user to return to login controller after they logout
    
    static func authListener(viewController view : UIViewController) -> AuthStateDidChangeListenerHandle {
        let authHandle = Auth.auth().addStateDidChangeListener() { (auth, user) in
            guard user == nil else { return }
            let initialVC = UIStoryboard.initialViewController(for: .login)
            view.view.window?.rootViewController = initialVC
            view.view.window?.makeKeyAndVisible()
        }
        return authHandle
    }
    
    //use this to confirm user has logged out
    static func removeAuthListener(authHandle : AuthStateDidChangeListenerHandle?){
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }
    
    
    
    
}
