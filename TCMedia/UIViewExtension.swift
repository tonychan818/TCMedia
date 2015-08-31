//
//  StringExtension.swift
//  TripAlive
//
//  Created by Tony on 9/7/15.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import Foundation

extension UIView {
    
    func imageFromView() -> UIImage{
        if UIScreen.mainScreen().respondsToSelector("scale"){
            UIGraphicsBeginImageContextWithOptions(self.frame.size, false, UIScreen.mainScreen().scale)
        }
        else{
            UIGraphicsBeginImageContext(self.frame.size)
        }
        self.layer.renderInContext(UIGraphicsGetCurrentContext())
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    class func loadFromNibNamed(nibNamed: String, bundle : NSBundle? = nil) -> UIView? {
        return UINib(
            nibName: nibNamed,
            bundle: bundle
            ).instantiateWithOwner(nil, options: nil)[0] as? UIView
    }
}