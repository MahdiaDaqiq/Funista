//
//  Constants.swift
//  Makestagram
//
//  Created by Mariano Montori on 7/6/17.
//  Copyright © 2017 Mariano Montori. All rights reserved.
//

import Foundation

struct Constants {
    struct Segue {
        static let toCreateUsername = "toCreateUsername"
    }
    struct FirDB {
        static let username = "username"
        static let users = "users"
        static let posts = "posts"
        static let postLikes = "postLikes"
        static let posterUID = "poster_uid"
        static let timeline = "timeline"
        static let followers = "followers"
        static let following = "following"
        static let followerCount = "follower_count"
        static let followingCount = "following_count"
        static let postCount = "post_count"
        
    }
    struct FirPost {
        static let likeCount = "like_count"
        static let poster = "poster"
        static let uid = "uid"
        static let username = "username"
        static let imageURL = "image_url"
        static let imageHeight = "image_height"
        static let createdAgo = "created_at"
    }
    struct UserDefaults {
        static let currentUser = "currentUser"
        static let uid = "uid"
        static let username = "username"
    }
}
