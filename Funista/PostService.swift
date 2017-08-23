//
//  PostService.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/10/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase

struct PostService {
    private static func create(forURLString urlString: String, aspectHeight: CGFloat) {
        let currentUser = User.current
        let post = Post(imageURL: urlString, imageHeight: aspectHeight)
        
        let rootRef = DatabaseReference.toLocation(.root)
        let newPostRef = DatabaseReference.toLocation(.posts(uid: currentUser.uid)).childByAutoId()
        let newPostKey = newPostRef.key
        
        UserService.followers(for: currentUser) { (followerUIDs) in
            let timelinePostDict = [Constants.FirDB.posterUID : currentUser.uid]
            
            var updatedData: [String : Any] = ["\(Constants.FirDB.timeline)/\(currentUser.uid)/\(newPostKey)" : timelinePostDict]
            
            for uid in followerUIDs {
                updatedData["\(Constants.FirDB.timeline)/\(uid)/\(newPostKey)"] = timelinePostDict
            }
            
            let postDict = post.dictValue
            updatedData["\(Constants.FirDB.posts)/\(currentUser.uid)/\(newPostKey)"] = postDict
            
            rootRef.updateChildValues(updatedData, withCompletionBlock: { (error, ref) in
                let postCountRef = DatabaseReference.toLocation(.postCount(uid: currentUser.uid))
                
                postCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                    let currentCount = mutableData.value as? Int ?? 0
                    
                    mutableData.value = currentCount + 1
                    
                    return TransactionResult.success(withValue: mutableData)
                })
            })
        }
    }
    
    static func create(for image: UIImage) {
        let imageRef = StorageReference.newPostImageReference()
        StorageService.uploadImage(image, at: imageRef) { (downloadURL) in
            guard let downloadURL = downloadURL else {
                return
            }
            
            let urlString = downloadURL.absoluteString
            let aspectHeight = image.aspectHeight
            create(forURLString: urlString, aspectHeight: aspectHeight)
        }
    }
    
    static func showLike(forKey postKey: String, posterUID: String, completion: @escaping (Post?) -> Void) {
        let ref = Database.database().reference().child("posts").child(posterUID).child(postKey)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let post = Post(snapshot: snapshot) else {
                return completion(nil)
            }
            
            LikeService.isPostLiked(post) { (isLiked) in
                post.isLiked = isLiked
                completion(post)
            }
        })
    }
    
    static func flag(_ post: Post) {
        // 1
        guard var postKey = post.key else { return }
        
        // 2
        
    }

}
