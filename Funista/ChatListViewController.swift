//
//  ChatListViewController.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/12/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//
import UIKit
import FirebaseDatabase

class ChatListViewController: UIViewController {
    
    var chats = [Chat]()
    var userChatsHandle: DatabaseHandle = 0
    var userChatsRef: DatabaseReference?

    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 71
        tableView.tableFooterView = UIView()
        userChatsHandle = UserService.observeChats { [weak self] (ref, chats) in
            self?.userChatsRef = ref
            self?.chats = chats
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    deinit {
        userChatsRef?.removeObserver(withHandle: userChatsHandle)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func dismissClicked(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
}

extension ChatListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toChat", sender: self)
    }
}

extension ChatListViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "toChat",
            let destination = segue.destination as? ChatViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            
            destination.chat = chats[indexPath.row]
        }
    }
}

extension ChatListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatListCell = tableView.dequeueReusableCell()
        
        let chat = chats[indexPath.row]
        cell.titleLabel.text = chat.title
        cell.lastMessageLabel.text = chat.lastMessage
        
        return cell
    }
}
