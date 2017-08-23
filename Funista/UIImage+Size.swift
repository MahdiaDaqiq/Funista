//
//  UIImage+Size.swift
//  Makestagram
//
//  Created by Mahdia Daqiq on 7/11/17.
//  Copyright © 2017 Mahdia Daqiq. All rights reserved.
//
import UIKit

extension UIImage {
    var aspectHeight: CGFloat {
        let heightRatio = size.height / 736
        let widthRatio = size.width / 414
        let aspectRatio = fmax(heightRatio, widthRatio)
        
        return size.height / aspectRatio
    }
}
