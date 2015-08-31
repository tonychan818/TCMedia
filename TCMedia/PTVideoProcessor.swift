
import AssetsLibrary


import SVProgressHUD
import SCRecorder

class PTVideoProcessor {
    enum TransformType{
        case left
        case right
        case up
        case down
    }
    var asset: AVURLAsset?
    var videoWidth: CGFloat?
    var videoHeight: CGFloat?
    var cropOffsetX: CGFloat?
    var cropOffsetY: CGFloat?
//    var indicator: UIActivityIndicatorView?
    var offset: NSTimeInterval?
    var framesPerSecond: Int32?
    var initialPlaybackTime: NSTimeInterval?
    var endingPlaybackTime: NSTimeInterval?
    
    var processVideoCB:((Void) -> (Void))!
    
    func getTransForm(txf:CGAffineTransform,size:CGSize,cropOffsetX:CGFloat,cropOffsetY:CGFloat,resizeWidthFactor:CGFloat,resizeHeightFactor:CGFloat,track:AVAssetTrack,type:TransformType) -> CGAffineTransform{
        var t1 = CGAffineTransformIdentity
        var t2 = CGAffineTransformIdentity
        switch(type){
        case TransformType.left:
            println("Left Transform performed!")
            t1 = CGAffineTransformMakeTranslation(track.naturalSize.width - (cropOffsetX * resizeWidthFactor), track.naturalSize.height - (cropOffsetY * resizeHeightFactor) )
            t2 = CGAffineTransformRotate(t1, CGFloat(M_PI) )
        case TransformType.right:
            println("Right Transform performed!")
            t1 = CGAffineTransformMakeTranslation(0 - (cropOffsetX * resizeWidthFactor), 0 - (cropOffsetY * resizeHeightFactor))
            t2 = CGAffineTransformRotate(t1, 0)
        case TransformType.up:
            println("Up Transform performed!")
            t1 = CGAffineTransformMakeTranslation(track.naturalSize.height - (cropOffsetX * resizeWidthFactor) , 0 - (cropOffsetY * resizeHeightFactor))
            t2 = CGAffineTransformRotate(t1, CGFloat(M_PI_2))
        case TransformType.down:
            println("Down Transform performed!")
            t1 = CGAffineTransformMakeTranslation(0 - (cropOffsetX * resizeWidthFactor), track.naturalSize.width - (cropOffsetY * resizeHeightFactor) )
            t2 = CGAffineTransformRotate(t1, CGFloat(-M_PI_2))
        default:
            println("default")
        }
        return t2
    }
    
    
    func cropVideo(cb:((Void) -> (Void))) {
        self.processVideoCB = cb
        
        var clipVideoTrack = asset!.tracksWithMediaType(AVMediaTypeVideo)
        
        var track = clipVideoTrack[0] as! AVAssetTrack
        var videoComposition = AVMutableVideoComposition(propertiesOfAsset: asset!)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        var resizeWidthFactor = CGFloat(1)
        var resizeHeightFactor = CGFloat(1)
        var cropOffsetX = self.cropOffsetX
        var cropOffsetY = self.cropOffsetY
        var cropWidth = CGFloat(0)
        var cropHeight = CGFloat(0)
        if(videoHeight > videoWidth) {
            println("video type 1")
            resizeWidthFactor = track.naturalSize.height / videoWidth!
            resizeHeightFactor = track.naturalSize.width / videoHeight!
            cropWidth = UIScreen.mainScreen().bounds.width * resizeHeightFactor
            cropHeight = UIScreen.mainScreen().bounds.width * resizeHeightFactor
            
        } else if(videoWidth > videoHeight) {
            println("video type 2")
            resizeWidthFactor = track.naturalSize.height / videoHeight!
            resizeHeightFactor = track.naturalSize.width / videoWidth!
            cropWidth = UIScreen.mainScreen().bounds.width * resizeWidthFactor
            cropHeight = UIScreen.mainScreen().bounds.width * resizeWidthFactor
            
        } else {
            println("video type 3")
            cropWidth = track.naturalSize.width
            cropHeight = track.naturalSize.height
        }
        println("crop width: \(cropWidth) , cropHeight: \(cropHeight)")
        
        cropWidth = ceil(cropWidth) - 1
        cropHeight = ceil(cropHeight) - 1
        
        videoComposition.renderSize = CGSizeMake(cropWidth, cropHeight)
        var instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30))
        var transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack[0] as! AVAssetTrack)
        var t1 = CGAffineTransformIdentity
        var t2 = CGAffineTransformIdentity
        var size = track.naturalSize
        var txf = track.preferredTransform
        println("prefered transform.tx: \(txf.tx), ty: \(txf.ty) a: \(txf.a), b: \(txf.b), c: \(txf.c), d:\(txf.d)")
        // check for the video orientation
        if (size.width == txf.tx && size.height == txf.ty) {
            println("video left")
            //left
            t2 = getTransForm(txf, size: size, cropOffsetX: self.cropOffsetX!, cropOffsetY: self.cropOffsetY!, resizeWidthFactor: resizeWidthFactor, resizeHeightFactor: resizeHeightFactor, track: track, type: TransformType.left)
            
        } else if (txf.tx == 0 && txf.ty == 0) {
            println("video right")
            //right
            if(txf.a == 0 && txf.b == 1 && txf.c == -1 && txf.d == 0){
                t2 = getTransForm(txf, size: size, cropOffsetX: self.cropOffsetX!, cropOffsetY: self.cropOffsetY!, resizeWidthFactor: resizeWidthFactor, resizeHeightFactor: resizeHeightFactor, track: track, type: TransformType.up)
            }
            else if(txf.a == -1 && txf.b == 0 && txf.c == 0 && txf.d == -1){
                t2 = getTransForm(txf, size: size, cropOffsetX: self.cropOffsetX!, cropOffsetY: self.cropOffsetY!, resizeWidthFactor: resizeWidthFactor, resizeHeightFactor: resizeHeightFactor, track: track, type: TransformType.left)
            }
            else{
                t2 = getTransForm(txf, size: size, cropOffsetX: self.cropOffsetX!, cropOffsetY: self.cropOffsetY!, resizeWidthFactor: resizeWidthFactor, resizeHeightFactor: resizeHeightFactor, track: track, type: TransformType.right)
            }
            
        } else if (txf.tx == 0 && txf.ty == size.width) {
            println("video down")
            //down
            t2 = getTransForm(txf, size: size, cropOffsetX: self.cropOffsetX!, cropOffsetY: self.cropOffsetY!, resizeWidthFactor: resizeWidthFactor, resizeHeightFactor: resizeHeightFactor, track: track, type: TransformType.down)
            
        } else {
            println("video up")
            //up
            t2 = getTransForm(txf, size: size, cropOffsetX: self.cropOffsetX!, cropOffsetY: self.cropOffsetY!, resizeWidthFactor: resizeWidthFactor, resizeHeightFactor: resizeHeightFactor, track: track, type: TransformType.up)
        }
        
        var finalTransform = t2;
        transformer.setTransform(t2, atTime: kCMTimeZero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        self.trimVideo(videoComposition)
        
    }
    
    func trimVideo(videoComposition: AVMutableVideoComposition) {
        
        let fileManager = NSFileManager.defaultManager()
        let documentsPath : String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true)[0] as! String
        let destinationPath: String = documentsPath + "/mergeVideo-\(arc4random()%1000).mov"
        let videoPath: NSURL = NSURL(fileURLWithPath: destinationPath as String)!
        let exporter: AVAssetExportSession = AVAssetExportSession(asset: asset!, presetName:AVAssetExportPresetHighestQuality)
        exporter.videoComposition = videoComposition
        exporter.outputURL = videoPath
//        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.outputFileType = AVFileTypeMPEG4
        exporter.shouldOptimizeForNetworkUse = true
        exporter.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(Float64(initialPlaybackTime!), framesPerSecond!), CMTimeMakeWithSeconds(Float64(offset!),framesPerSecond!))
        exporter.exportAsynchronouslyWithCompletionHandler({
            
            dispatch_async(dispatch_get_main_queue(),{
                self.exportDidFinish(exporter)
            })
        })
    }
    
    func exportDidFinish(session: AVAssetExportSession) {
        
        var outputURL: NSURL = session.outputURL
        var library: ALAssetsLibrary = ALAssetsLibrary()
        if(library.videoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL)) {
            println("outputURL size: \(NSData(contentsOfURL: outputURL)?.length)")
            library.writeVideoAtPathToSavedPhotosAlbum(outputURL, completionBlock: {(url, error) in
                println("save done url: \(url), error: \(error)")
                self.processVideoCB()
//                var alert = UIAlertView(title: "Success", message: "Video Saved Successfully!", delegate: nil, cancelButtonTitle: "Sweet")
//                alert.show()
            })
        }
    }
}
