//
//  SCRecordSessionManager.swift
//  TCMedia
//
//  Created by Tony on 1/9/15.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import UIKit

import SCRecorder

//#define kUserDefaultsStorageKey @"RecordSessions"
class SCRecordSessionManager2: NSObject {
    static let sharedInstance = SCRecordSessionManager2()
    func modifyMetadatas(block:((AnyObject?)->())){
        var metadatas: AnyObject? = self.saveRecordSessions()?.mutableCopy()
        if let md: AnyObject = metadatas{
            
        }
        else{
            metadatas = [AnyObject]()
        }
        
        block(metadatas)
        NSUserDefaults.standardUserDefaults().setObject(metadatas, forKey: "RecordSessions")
    }
    
    func saveRecordSession(recordSession:SCRecordSession){
        self.modifyMetadatas { (metadatas) -> () in
            var insertIndex = -1
//            for var index = 0; index < 3; ++index {
            var index = 0
            for otherRecordSessionMetadata in metadatas as! [AnyObject] {
                var key:String = otherRecordSessionMetadata[SCRecordSessionIdentifierKey] as! String
                if (key == recordSession.identifier){
                    insertIndex = index
                    break
                }
//                if(otherRecordSessionMetadata)
                index = index + 1
            }
            
            var metadata = recordSession.dictionaryRepresentation()
            if(insertIndex == -1){
                metadatas?.addObject(metadata)
            }
            else{
                metadatas?.replaceObjectAtIndex(insertIndex, withObject: metadata)
            }
        }
    }
    
    func isSaved(recordSession:SCRecordSession) -> Bool{
        var sessions: AnyObject? = self.saveRecordSessions()
        for session in sessions as! [AnyObject]{
            var key = session[SCRecordSessionIdentifierKey] as! String
            if(key == recordSession.identifier){
                return true
            }
        }
        return false
    }
    
    
    func saveRecordSessions()-> AnyObject?{
        return NSUserDefaults.standardUserDefaults().objectForKey("RecordSessions")
    }
}
