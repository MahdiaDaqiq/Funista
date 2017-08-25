//
//  User.swift
//  
//
//  Created by Mahdia Daqiq on 7/7/17.
//
//

import Foundation
import UIKit
import FirebaseDatabase.FIRDataSnapshot

class User : NSObject {
    let uid: String
    let username: String
    var isFollowed = false
    var followerCount: Int?
    var followingCount: Int?
    var postCount: Int?
    
    init(uid: String, username: String) {
        self.uid = uid
        self.username = username
        super.init()

    }
    
    func updateCounts() {
        DatabaseReference.toLocation(.followers(uid: self.uid)).observeSingleEvent(of: .value) { (snapshot:DataSnapshot) in
            self.followerCount = Int(snapshot.childrenCount)
        }
        DatabaseReference.toLocation(.following(uid: self.uid)).observeSingleEvent(of: .value) { (snapshot:DataSnapshot) in
            self.followingCount = Int(snapshot.childrenCount)
        }
        DatabaseReference.toLocation(.posts(uid: self.uid)).observeSingleEvent(of: .value) { (snapshot:DataSnapshot) in
            self.postCount = Int(snapshot.childrenCount)
        }
        
    }
    
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let username = dict[Constants.FirDB.username] as? String,
            let followerCount = dict[Constants.FirDB.followerCount] as? Int,
            let followingCount = dict[Constants.FirDB.followingCount] as? Int,
            let postCount = dict[Constants.FirDB.postCount] as? Int
            else { return nil }
        
        self.uid = snapshot.key
        self.username = username
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.postCount = postCount

        super.init()
        
        self.updateCounts()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let uid = aDecoder.decodeObject(forKey: Constants.UserDefaults.uid) as? String,
            let username = aDecoder.decodeObject(forKey: Constants.UserDefaults.username) as? String
            else { return nil }
        
        self.uid = uid
        self.username = username
        
        super.init()
        
        self.updateCounts()
    }
    
    private static var _current: User?
    
    static var current: User {
        guard let currentUser = _current else {
            fatalError("Error: current user doesn't exist")

        }
        
        return currentUser
    }
    
    class func setCurrent(_ user: User, writeToUserDefaults: Bool = false) {
        if writeToUserDefaults {
            let data = NSKeyedArchiver.archivedData(withRootObject: user)
            
            UserDefaults.standard.set(data, forKey: Constants.UserDefaults.currentUser)
        }
        
        _current = user
    }
}

extension User: NSCoding {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(uid, forKey: Constants.UserDefaults.uid)
        aCoder.encode(username, forKey: Constants.UserDefaults.username)
    }
}
