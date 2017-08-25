//
//  UserService.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/10/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//

import Foundation
import FirebaseAuth.FIRUser
import FirebaseDatabase

struct UserService {
    static func show(forUID uid: String, completion: @escaping (User?) -> Void) {
        // Read from database
        let ref = DatabaseReference.toLocation(.showUser(uid: uid))
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Retreive from database
            guard let user = User(snapshot: snapshot) else {
                return completion(nil)
            }
            
            completion(user)
        })
    }
    
    static func create(_ firUser: FIRUser, username: String, completion: @escaping (User?) -> Void) {
        let userAttrs: [String : Any] = [Constants.FirDB.username: username,
                                         Constants.FirDB.followerCount : 0,
                                         Constants.FirDB.followingCount : 0,
                                         Constants.FirDB.postCount : 0]
        
        let ref = DatabaseReference.toLocation(.showUser(uid: firUser.uid))
        ref.setValue(userAttrs) { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
            }
            
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                let user = User(snapshot: snapshot)
                completion(user)
            })
        }
    }
    
    
    static func posts(for user: User, completion: @escaping ([Post]) -> Void) {
        let ref = DatabaseReference.toLocation(.posts(uid: user.uid))
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                return completion([])
            }
            
            let dispatchGroup = DispatchGroup()
            
            let posts: [Post] =
                snapshot
                    .reversed()
                    .flatMap {
                        guard let post = Post(snapshot: $0)
                            else { return nil }
                        
                        dispatchGroup.enter()
                        
                        LikeService.isPostLiked(post) { (isLiked) in
                            post.isLiked = isLiked
                            
                            dispatchGroup.leave()
                        }
                        
                        return post
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                completion(posts)
            })
        })
    }
    
    static func usersExcludingCurrentUser(completion: @escaping ([User]) -> Void) {
        let currentUser = User.current
        let ref = Database.database().reference().child("users")
        
        //where we hold all teh blocked uerse dict
        // empty dict and
        // chhange teh block dict to be the return volue
        //
        var blockedDict = [String:Bool]()
        blockedUsers { (dict) in
            blockedDict = dict
            // start pulling all volues users
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let snapshot = snapshot.children.allObjects as? [DataSnapshot]
                    else { return completion([]) }
                //2.
                //
                let users =
                    snapshot
                        .flatMap(User.init)
                        .filter {
                            // if user part of block dict
                            let value : Bool = blockedDict[$0.uid] ?? false
                            return !value &&
                                $0.uid != currentUser.uid
                }
                
                let dispatchGroup = DispatchGroup()
                users.forEach { (user) in
                    dispatchGroup.enter()
                    
                    FollowService.isUserFollowed(user) { (isFollowed) in
                        user.isFollowed = isFollowed
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main, execute: {
                    completion(users)
                })
            })
        }
        
        
    }
    
    static func followers(for user: User, completion: @escaping ([String]) -> Void) {
        let followersRef = DatabaseReference.toLocation(.followers(uid: user.uid))
        
        followersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let followersDict = snapshot.value as? [String : Bool] else {
                return completion([])
            }
            
            let followersKeys = Array(followersDict.keys)
            completion(followersKeys)
        })
    }
    
    static func following(for user: User = User.current, completion: @escaping ([User]) -> Void) {
        let followingRef = DatabaseReference.toLocation(.following(uid: user.uid))

        followingRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let followingDict = snapshot.value as? [String : Bool] else {
                return completion([])
            }
            
            var following = [User]()
            let dispatchGroup = DispatchGroup()
            
            for uid in followingDict.keys {
                dispatchGroup.enter()
                
                show(forUID: uid) { user in
                    if let user = user {
                        following.append(user)
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(following)
            }
        })
    }

    
    static func timeline(pageSize: UInt, lastPostKey: String? = nil, completion: @escaping ([Post]) -> Void) {
        let currentUser = User.current
        
        let timelineRef = DatabaseReference.toLocation(.timeline(uid: currentUser.uid))
        var query = timelineRef.queryOrderedByKey().queryLimited(toLast: pageSize)
        if let lastPostKey = lastPostKey {
            query = query.queryEnding(atValue: lastPostKey)
        }
        query.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot]
                else { return completion([]) }
            
            let dispatchGroup = DispatchGroup()
            
            var posts = [Post]()
            
            for postSnap in snapshot {
                guard let postDict = postSnap.value as? [String : Any],
                    let posterUID = postDict[Constants.FirDB.posterUID] as? String
                    else { continue }
                
                dispatchGroup.enter()
                
                PostService.showLike(forKey: postSnap.key, posterUID: posterUID) { (post) in
                    if let post = post {
                        posts.append(post)
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                completion(posts.reversed())
            })
        })
    }
    
    static func observeProfile(for user: User, completion: @escaping (DatabaseReference, User?, [Post]) -> Void) -> DatabaseHandle {
        let userRef = DatabaseReference.toLocation(.showUser(uid: user.uid))
        return userRef.observe(.value, with: { snapshot in
            guard let user = User(snapshot: snapshot) else {
                return completion(userRef, nil, [])
            }
            
            posts(for: user, completion: { posts in
                completion(userRef, user, posts)
            })
        })
    }
    
    static func observeChats(for user: User = User.current, withCompletion completion: @escaping (DatabaseReference, [Chat]) -> Void) -> DatabaseHandle {
        let ref = DatabaseReference.toLocation(.userChats(uid: user.uid))
        
        return ref.observe(.value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                return completion(ref, [])
            }
            
            let chats = snapshot.flatMap(Chat.init)
            completion(ref, chats)
        })
    }
    
    static func blockedUsers(completion: @escaping ([String : Bool]) -> Void){
        
        let blockedUserRef = Database.database().reference().child("users").child((Auth.auth().currentUser?.uid)!).child("blockedUsers")
        blockedUserRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dict = snapshot.value as? [String:Bool] else {
                return completion([:])
            }
            completion(dict)
        })
        
        
        
    }
    
    static func block(myself: String, posterUID:  String){
        let blockedUserRef = Database.database().reference().child("users").child(myself).child("blockedUsers").child(posterUID)
        blockedUserRef.setValue(true)
        
        let blockedbyRef = Database.database().reference().child("users").child(posterUID).child("blockedUsers").child(myself)
        blockedbyRef.setValue(true)
        
    }
    

}
