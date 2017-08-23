//
//  NewChatViewController.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/12/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//

import UIKit

class NewChatViewController: UIViewController {
    
    var following = [User]()
    var selectedUser: User?
    var existingChat: Chat?

    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.isEnabled = false
        tableView.tableFooterView = UIView()
        
        UserService.following { [weak self] (following) in
            self?.following = following
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func nextClicked(_ sender: UIBarButtonItem) {
        guard let selectedUser = selectedUser else { return }
        
        sender.isEnabled = false
        ChatService.checkForExistingChat(with: selectedUser) { (chat) in
            sender.isEnabled = true
            self.existingChat = chat
            
            self.performSegue(withIdentifier: "toChat", sender: self)
        }
    }
}

extension NewChatViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "toChat", let destination = segue.destination as? ChatViewController, let selectedUser = selectedUser {
            let members = [selectedUser, User.current]
            destination.chat = existingChat ?? Chat(members: members)
        }
    }
}

extension NewChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return following.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : NewChatUserCell = tableView.dequeueReusableCell()
        configureCell(cell, at: indexPath)
        
        return cell
    }
    
    func configureCell(_ cell: NewChatUserCell, at indexPath: IndexPath) {
        let follower = following[indexPath.row]
        cell.textLabel?.text = follower.username
        
        if let selectedUser = selectedUser, selectedUser.uid == follower.uid {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
}

extension NewChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        selectedUser = following[indexPath.row]
        cell.accessoryType = .checkmark
        
        nextButton.isEnabled = true
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        cell.accessoryType = .none
    }
}
