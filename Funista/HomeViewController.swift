//
//  HomeViewController.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/12/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//
import UIKit
import Kingfisher
import FirebaseStorage
import FirebaseDatabase
import Firebase



class HomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var posts = [Post]() {
        didSet {
            tableView.reloadData()
        }
    }
    let refreshControl = UIRefreshControl()
    let timestampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        return dateFormatter
    }()
    let paginationHelper = MGPaginationHelper<Post>(serviceMethod: UserService.timeline)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        reloadTimeline()
    }
    
    
    func reloadTimeline() {
        self.paginationHelper.reloadData(completion: { [unowned self] (posts) in
            self.posts = posts
            
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }

        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureTableView() {
        // remove separators for empty cells
        tableView.tableFooterView = UIView()
        // remove separators from cells
        tableView.separatorStyle = .none
        refreshControl.addTarget(self, action: #selector(reloadTimeline), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    func handleOptionsButtonTap(from cell: PostHeaderCell) {
        // 1
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        // 2
        let post = posts[indexPath.section]
        let poster = post.poster
        let postKey = post.key
        let uid = poster.uid
        let rootRef = Database.database().reference()

        // 3
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 4
        if poster.uid != User.current.uid {
            // flag
            let flagAction = UIAlertAction(title: "Report as Inappropriate", style: .default) { _ in
                PostService.flag(post)
                
                let flaggedPostRef = Database.database().reference().child("flaggedPosts").child(postKey!)
                let flaggedDict = ["image_url": post.imageURL,
                                   "poster_uid": post.poster.uid,
                                   "reporter_uid": User.current.uid]
                
                flaggedPostRef.updateChildValues(flaggedDict)
                
                let flagCountRef = flaggedPostRef.child("flag_count")
                flagCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                    
                    let currentCount = mutableData.value as? Int ?? 0
                    mutableData.value = currentCount
                    
                    if mutableData.value as! Int >= 2 {
                        
                        Database.database().reference().child("posts").child(uid).child(postKey!).removeValue()
                        
                        print("Delete case: mutableData.value = \(String(describing: mutableData.value))")
                        UserService.followers(for: poster) { (followerUIDs) in
                            
                            var updatedData: [String : Any] = ["timeline/\(uid)/\(postKey!)" : NSNull()]
                            
                            for uid in followerUIDs {
                                updatedData["timeline/\(uid)/\(postKey!)"] = NSNull()
                            }
                            
                            updatedData["posts/\(uid)/\(postKey!)"] = NSNull()
                            
                            rootRef.updateChildValues(updatedData)
                            
                        }
                        DispatchQueue.main.async {
                            self.reloadTimeline()

                        }

                        
                    } else {
                        // filter from timeline
                        let blah = ["timeline/\(User.current.uid)/\(postKey!)" : NSNull()]
                        
                        rootRef.updateChildValues(blah, withCompletionBlock: { (error, _) in
                            DispatchQueue.main.async {
                                self.reloadTimeline()
                            }
                        })
                        print("Case not met. Either not equal to 2 or not able to cast as Integer type. The value of the casted in is \(String(describing: mutableData.value as? Int))")
                    }
                    
                    mutableData.value = currentCount + 1
                    return TransactionResult.success(withValue: mutableData)
                })
                
                let okAlert = UIAlertController(title: nil, message: "The post has been flagged.", preferredStyle: .alert)
                okAlert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(okAlert, animated: true)
            }
            
            alertController.addAction(flagAction)
        } else {
            // delete
            let flagAction = UIAlertAction(title: "Delete post", style: .default) { _ in
                
                UserService.followers(for: poster) { (followerUIDs) in
                    var updatedData: [String : Any] = ["timeline/\(uid)/\(postKey!)" : NSNull()]
                    for uid in followerUIDs {
                        updatedData["timeline/\(uid)/\(postKey!)"] = NSNull()
                    }
                    updatedData["posts/\(uid)/\(postKey!)"] = NSNull()
                    rootRef.updateChildValues(updatedData)
                }
                
                Database.database().reference().child("posts").child(uid).child(postKey!).removeValue()
                let okAlert = UIAlertController(title: nil, message: "The post has been deleted.", preferredStyle: .alert)
                okAlert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(okAlert, animated: true)
                DispatchQueue.main.async {
                    self.reloadTimeline()
                    
                }
            }
            
            alertController.addAction(flagAction)
            
            
        }
        // block
        if poster.uid != User.current.uid {
            let blockAction = UIAlertAction(title: "Block this User", style: .default) { _ in
                
                let currentUID = User.current.uid
                
                UserService.block(myself: currentUID, posterUID : poster.uid)
                
                let followData = ["followers/\(uid)/\(currentUID)" : NSNull(),
                                  "following/\(currentUID)/\(uid)" : NSNull(),
                                  "followers/\(currentUID)/\(uid)" : NSNull(),
                                  "following/\(uid)/\(currentUID)" : NSNull()]
                
                let ref = Database.database().reference()
                ref.updateChildValues(followData) { (error, ref) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    
                }
                
                UserService.posts(for: poster, completion: { (posts) in
                    var unfollowData = [String : Any]()
                    let postsKeys = posts.flatMap { $0.key }
                    postsKeys.forEach {
                        unfollowData["timeline/\(currentUID)/\($0)"] = NSNull()
                    }
                    
                    ref.updateChildValues(unfollowData, withCompletionBlock: { (error, ref) in
                        DispatchQueue.main.async {
                            self.reloadTimeline()
                        }

                        if let error = error {
                            print(error.localizedDescription)
                        }
                        
                    })
                })
                
                DispatchQueue.main.async {
                    self.reloadTimeline()
                }
                
                let okAlert = UIAlertController(title: nil, message: "The user has been blocked.", preferredStyle: .alert)
                okAlert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(okAlert, animated: true)
                
                
            }
            
            alertController.addAction(blockAction)
        }
        
        //filter
        if poster.uid != User.current.uid {
            let blockAction = UIAlertAction(title: "Filter this post", style: .default) { _ in
                
                let blah = ["timeline/\(User.current.uid)/\(postKey!)" : NSNull()]
                
                rootRef.updateChildValues(blah, withCompletionBlock: { (error, _) in
                    DispatchQueue.main.async {
                        self.reloadTimeline()
                    }
                })
                
                let okAlert = UIAlertController(title: nil, message: "The user has been filtered.", preferredStyle: .alert)
                okAlert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(okAlert, animated: true)
                
            }
            
            alertController.addAction(blockAction)
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
        
    }
    }

extension HomeViewController: PostActionCellDelegate {
    func didTapLikeButton(_ likeButton: UIButton, on cell: PostActionCell) {
        // 1
        guard let indexPath = tableView.indexPath(for: cell)
            else { return }
        
        // 2
        likeButton.isUserInteractionEnabled = false
        // 3
        let post = posts[indexPath.section]
        
        // 4
        LikeService.setIsLiked(!post.isLiked, for: post) { (success) in
            // 5
            defer {
                likeButton.isUserInteractionEnabled = true
            }
            
            // 6
            guard success else { return }
            
            // 7
            post.likeCount += !post.isLiked ? 1 : -1
            post.isLiked = !post.isLiked
            
            // 8
            guard let cell = self.tableView.cellForRow(at: indexPath) as? PostActionCell
                else { return }
            
            // 9
            DispatchQueue.main.async {
                self.configureCell(cell, with: post)
            }
        }
    }
}


extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section >= posts.count - 1 {
            paginationHelper.paginate(completion: { [unowned self] (posts) in
                self.posts.append(contentsOf: posts)
                
                DispatchQueue.main.async {
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostHeaderCell") as! PostHeaderCell
            cell.usernameLabel.text = post.poster.username
            cell.didTapOptionsButtonForCell = handleOptionsButtonTap(from:)
            return cell
            
        case 1:
            let cell: PostImageCell = tableView.dequeueReusableCell()
            let imageURL = URL(string: post.imageURL)
            cell.postImageView.kf.setImage(with: imageURL)
            
            return cell
            
        case 2:
            let cell: PostActionCell = tableView.dequeueReusableCell()
            cell.delegate = self
            configureCell(cell, with: post)
            
            return cell
            
        default:
            fatalError("Error: unexpected indexPath.")
        }
    }
    
    func configureCell(_ cell: PostActionCell, with post: Post) {
        cell.timeAgoLabel.text = timestampFormatter.string(from: post.creationDate)
        cell.likeButton.isSelected = post.isLiked
        cell.likeCountLabel.text = "\(post.likeCount) Laughs"
    }
    

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return PostHeaderCell.height
            
        case 1:
            let post = posts[indexPath.section]
            return post.imageHeight
            
        case 2:
            return PostActionCell.height
            
        default:
            fatalError()
        }
    }
}
