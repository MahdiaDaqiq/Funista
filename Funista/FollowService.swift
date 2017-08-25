//
//  FollowService.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/10/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//


import Foundation
import FirebaseDatabase


struct FollowService {
    static func isUserFollowed(_ user: User, forCurrentUserWithCompletion completion: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let ref = DatabaseReference.toLocation(.followers(uid: user.uid))
        ref.queryEqual(toValue: nil, childKey: currentUID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? [String : Bool] {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    

    
    
    
    static func setIsFollowing(_ isFollowing: Bool, fromCurrentUserTo followee: User, success: @escaping (Bool) -> Void) {
        if isFollowing {
            followUser(followee, forCurrentUserWithSuccess: success)
        } else {
            unfollowUser(followee, forCurrentUserWithSuccess: success)
        }
    }
    
    private static func followUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let followData = ["\(Constants.FirDB.followers)/\(user.uid)/\(currentUID)" : true,
                          "\(Constants.FirDB.following)/\(currentUID)/\(user.uid)" : true]
        
        let ref = DatabaseReference.toLocation(.root)
        ref.updateChildValues(followData) { (error, _) in
            if let error = error {
                print(error.localizedDescription)
                success(false)
            }
            let dispatchGroup = DispatchGroup()
            
//            dispatchGroup.enter()
//            
//            let followingCountRef = DatabaseReference.toLocation(.followingCount(uid: currentUID))
//            followingCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
//                let currentCount = mutableData.value as? Int ?? 0
//                mutableData.value = currentCount + 1
//                
//                return TransactionResult.success(withValue: mutableData)
//                dispatchGroup.leave()
//
//            })
//            
//            dispatchGroup.enter()
//            let followerCountRef = DatabaseReference.toLocation(.followerCount(uid: user.uid))
//            followerCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
//                let currentCount = mutableData.value as? Int ?? 0
//                mutableData.value = currentCount + 1
//                dispatchGroup.leave()
//                return TransactionResult.success(withValue: mutableData)
//            })
//            
            
            dispatchGroup.enter()
            UserService.posts(for: user) { (posts) in
                let postKeys = posts.flatMap { $0.key }
                
                var followData = [String : Any]()
                let timelinePostDict = ["poster_uid" : user.uid]
                postKeys.forEach { followData["timeline/\(currentUID)/\($0)"] = timelinePostDict }
                
                ref.updateChildValues(followData, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    
                    dispatchGroup.leave()
                })
            }
            
            dispatchGroup.notify(queue: .main) {
                success(true)
            }
        }
    }
    
    private static func unfollowUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let followData = ["\(Constants.FirDB.followers)/\(user.uid)/\(currentUID)" : NSNull(),
                          "\(Constants.FirDB.following)/\(currentUID)/\(user.uid)" : NSNull()]
        
        let ref = DatabaseReference.toLocation(.root)
        ref.updateChildValues(followData) { (error, ref) in
            if let error = error {
                print(error.localizedDescription)
                return success(false)
            }
            
            let dispatchGroup = DispatchGroup()
//            
//            dispatchGroup.enter()
//            let followingCountRef = DatabaseReference.toLocation(.followingCount(uid: currentUID))
//            followingCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
//                let currentCount = mutableData.value as? Int ?? 0
//                mutableData.value = currentCount - 1
//                
//                return TransactionResult.success(withValue: mutableData)
//                dispatchGroup.leave()
//            })
//            
//            dispatchGroup.enter()
//            let followerCountRef = DatabaseReference.toLocation(.followerCount(uid: user.uid))
//            followerCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
//                let currentCount = mutableData.value as? Int ?? 0
//                mutableData.value = currentCount - 1
//                dispatchGroup.leave()
//                return TransactionResult.success(withValue: mutableData)
//            })
            
            dispatchGroup.enter()
            UserService.posts(for: user, completion: { (posts) in
                var unfollowData = [String : Any]()
                let postsKeys = posts.flatMap { $0.key }
                postsKeys.forEach {
                    unfollowData["timeline/\(currentUID)/\($0)"] = NSNull()
                }
                
                ref.updateChildValues(unfollowData, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    dispatchGroup.leave()
                })
            })
            
            dispatchGroup.notify(queue: .main) {
                success(true)
            }
        }
    }
}




