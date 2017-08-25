//
//  LikeService.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/10/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct LikeService {
    
    static func setIsLiked(_ isLiked: Bool, for post: Post, success: @escaping (Bool) -> Void) {
        if isLiked {
            create(for: post, success: success)
        } else {
            delete(for: post, success: success)
        }
    }
    
    
    
    static func create(for post: Post, success: @escaping (Bool) -> Void) {
        // 1
        guard let key = post.key else {
            return success(false)
        }
        
        // 2
        let currentUID = User.current.uid
        
        let likesRef = Database.database().reference().child("postLikes").child(key).child(currentUID)
        likesRef.setValue(true) { (error, _) in
            if let error = error {
                print(error.localizedDescription)
                return success(false)
            }
            
            let likeCountRef = Database.database().reference().child("posts").child(post.poster.uid).child(key).child("like_count")
            likeCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                
                mutableData.value = currentCount + 1
                
                return TransactionResult.success(withValue: mutableData)
            }, andCompletionBlock: { (error, _, _) in
                if let error = error {
                    print(error.localizedDescription)
                    success(false)
                } else {
                    success(true)
                }
            })
        }        // 3 code to like a post
    }
    
    
    static func isPostLiked(_ post: Post,  byCurrentUserWithCompletion completion: @escaping (Bool) -> Void) {
        guard let postKey = post.key else {
            print("Error: post must have key.")
            return completion(false)
        }
        
        
        let likesRef = Database.database().reference().child("postLikes").child(postKey)
        likesRef.queryEqual(toValue: nil, childKey: User.current.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? [String : Bool] {
                completion(true)
            } else {
                completion(false)
            }
        })
        
    }
    static func delete(for post: Post, success: @escaping (Bool) -> Void) {
        guard let key = post.key else {
            return success(false)
        }
        
        let currentUID = User.current.uid
        
        
        let likesRef = Database.database().reference().child("postLikes").child(key).child(currentUID)
        likesRef.setValue(nil) { (error, _) in
            if let error = error {
                print(error.localizedDescription)
                return success(false)
            }
            
            let likeCountRef = Database.database().reference().child("posts").child(post.poster.uid).child(key).child("like_count")
            likeCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                
                mutableData.value = currentCount - 1
                
                return TransactionResult.success(withValue: mutableData)
            }, andCompletionBlock: { (error, _, _) in
                if let error = error {
                    print(error.localizedDescription)
                    success(false)
                } else {
                    success(true)
                }
            })
        }
    }
    
 
}
