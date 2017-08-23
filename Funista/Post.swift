//
//  Post.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/7/17.
//  Copyright © 2017 Mahdia Mahdia. All rights reserved.
//

import UIKit
import FirebaseDatabase.FIRDataSnapshot

class Post : MGKeyed{
    var likeCount: Int
    var key: String?
    var isLiked = false
    let poster: User
    let imageURL: String
    let imageHeight: CGFloat
    let creationDate: Date
    var dictValue: [String : Any] {
        let createdAgo = creationDate.timeIntervalSince1970
        let userDict = [Constants.FirPost.uid : poster.uid,
                        Constants.FirPost.username : poster.username]
        return [Constants.FirPost.imageURL : imageURL,
                Constants.FirPost.imageHeight : imageHeight,
                Constants.FirPost.createdAgo : createdAgo,
                Constants.FirPost.likeCount : likeCount,
                Constants.FirPost.poster : userDict]
    }
    
    init(imageURL: String, imageHeight: CGFloat) {
        self.imageURL = imageURL
        self.imageHeight = imageHeight
        self.creationDate = Date()
        self.likeCount = 0
        self.poster = User.current
    }
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let imageURL = dict[Constants.FirPost.imageURL] as? String,
            let imageHeight = dict[Constants.FirPost.imageHeight] as? CGFloat,
            let createdAgo = dict[Constants.FirPost.createdAgo] as? TimeInterval,
            let likeCount = dict[Constants.FirPost.likeCount] as? Int,
            let userDict = dict[Constants.FirPost.poster] as? [String : Any],
            let uid = userDict[Constants.FirPost.uid] as? String,
            let username = userDict[Constants.FirPost.username] as? String
            else { return nil }
        
        self.likeCount = likeCount
        self.poster = User(uid: uid, username: username)
        self.key = snapshot.key
        self.imageURL = imageURL
        self.imageHeight = imageHeight
        self.creationDate = Date(timeIntervalSince1970: createdAgo)
    }
}
