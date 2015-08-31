//
//  Log.swift
//  TripAlive
//
//  Created by Tony on 13/7/15.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import UIKit

class Log: NSObject {
    static let shareInstance = Log()
    var startTime:NSTimeInterval = NSDate().timeIntervalSince1970
    var endTime:NSTimeInterval!
    func p(str:String, caller:AnyObject?){
        self.endTime = NSDate().timeIntervalSince1970
        let timeDiff = String.localizedStringWithFormat("%.02f", (self.endTime - self.startTime))
        println("(TimeUsed:\(timeDiff)) \(caller.dynamicType) - \(str)")
        self.startTime = self.endTime
    }
}
