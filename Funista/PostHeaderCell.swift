//
//  PostHeaderCell.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/12/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//

import UIKit

class PostHeaderCell: UITableViewCell {
    static let height: CGFloat = 54
    var didTapOptionsButtonForCell: ((PostHeaderCell) -> Void)?

    @IBOutlet weak var usernameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func optionsClicked(_ sender: Any) {
        didTapOptionsButtonForCell?(self)
        print("optin tapped")
    }
}
