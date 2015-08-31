//
//  UITableViewExtension.swift
//  TripAlive
//
//  Created by Tony on 27/7/15.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import UIKit

extension UICollectionView{
    func reloadData(completion: ()->()) {
        UIView.animateWithDuration(0, animations: { self.reloadData() })
            { _ in completion() }
    }
}