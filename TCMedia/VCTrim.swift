//
//  VCTrim.swift
//  TCMedia
//
//  Created by Tony on 26/8/15.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import UIKit
import MediaPlayer

import SVProgressHUD
import SCRecorder

protocol PTFrameWindowControlDelegate:class{
    func PTFrameWindowControlVideoShouldReset(isSetFront:Bool)
}

class PTFrameWindowControl: UIControl,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    
    weak var delegate:PTFrameWindowControlDelegate?
    var slider = UIView()
    var sliderMovementConstraint = CGFloat(0)
//    var blockedPortion = CALayer()
    var blockedView = UIView()
    var blockedLineView = UIView()
    
    var framesView = UICollectionView(frame: CGRectZero, collectionViewLayout: PTFrameWindowControl.defaultLayout(CGSize(width: 0, height: 0)))
    var offset: NSTimeInterval = Double(C.MAX_DURATION)
    
    var numOfFrames: Int = 0
    var framesPerSecond: Int32 = 0
    var frames = [UIImage]()
    var videoURL:NSURL!
    
    var lastFrameWidth = CGFloat(0.0)
    var lastNumOfFrames: Int = -1
    var slideBegin = false
    
    let frameWindowPadding = CGFloat(20)
    let frameWindowHeight = CGFloat(40)
    
    var durationInSeconds: Float64!
    
    var imgPointer:UIImageView!
    
    func resetPointer(){
        var pointerSize = CGFloat(20)
        if(self.imgPointer != nil){
            self.imgPointer.frame = CGRectMake(frameWindowPadding - pointerSize/2, 0, pointerSize, pointerSize)
        }
        println("resetPointer")
    }
    func correctEndPointerPosition(){
        self.imgPointer.frame = CGRectMake(self.blockedLineView.frame.origin.x - self.imgPointer.frame.size.width/2, self.imgPointer.frame.origin.y, self.imgPointer.frame.size.width, self.imgPointer.frame.size.width)
    }
    
    func setSliderAndLineEndPosition(){
        let indicatorSize = CGFloat(26)
        slider.clipsToBounds = true
        slider.layer.cornerRadius = indicatorSize/2.0
        
        slider.frame = CGRect(x: self.sliderMovementConstraint,
            y: self.frame.height - indicatorSize
            , width:indicatorSize, height: indicatorSize)
        println("setSliderAndLineEndPosition slider: \(self.slider.frame.origin.x) blockLineVie: \(self.blockedLineView.frame.origin.x)")
        
        self.blockedLineView.frame = CGRectMake(slider.frame.origin.x + slider.frame.size.width/2, 0, 1, self.frame.size.height)
        
        println("setSliderAndLineEndPosition done")
    }
    
    func reloadLayoutSubviews(){
        self.lastFrameWidth = -1
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        if(self.lastFrameWidth != self.frame.size.width){
            println("layoutSubViews!!")
            framesView.frame = CGRectMake(frameWindowPadding, frameWindowPadding, self.frame.size.width - frameWindowPadding * 2, frameWindowHeight)
            
            if(self.sliderMovementConstraint == 0){
                self.sliderMovementConstraint = self.framesView.frame.origin.x + self.framesView.frame.size.width - slider.frame.size.width/2
            }
            self.lastFrameWidth = self.frame.size.width
            self.setSliderAndLineEndPosition()
            
        }
        var maxX = self.framesView.frame.origin.x + self.framesView.frame.size.width - self.slider.frame.size.width
        if(self.slider.frame.origin.x > maxX && !self.slideBegin){
            self.slider.frame = CGRectMake(maxX + self.slider.frame.size.width/2,
                self.slider.frame.origin.y,
                self.slider.frame.size.width,
                self.slider.frame.size.height)
            
            self.blockedLineView.frame = CGRectMake(slider.frame.origin.x + slider.frame.size.width/2, 0, 1, self.self.frame.size.height)
        }
    }
    
    func updatePointerSizeWithProgress(p:CGFloat){
        var pointerPosition = self.framesView.frame.origin.x + (self.blockedLineView.frame.origin.x - self.framesView.frame.origin.x) * p - self.imgPointer.frame.size.width/2
        if(pointerPosition < self.imgPointer.frame.size.width/2){
            self.resetPointer()
        }
        else{
            self.imgPointer.frame = CGRectMake(pointerPosition, self.imgPointer.frame.origin.y, self.imgPointer.frame.size.width, self.imgPointer.frame.size.height)
        }
//        println("updatePointer frame: \(self.imgPointer.frame)")
        
    }
    
    class func defaultLayout(headerSize: CGSize) -> UICollectionViewFlowLayout {
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsZero
        layout.headerReferenceSize = headerSize
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        return layout
    }
    
    func getVideoStartEnd() -> (videoStart:CGFloat,videoEnd:CGFloat,frameStartX:CGFloat,frameEndX:CGFloat){
        //maually calculate contentFull Width
//        var contentFullWidth = self.framesView.contentSize.width
        var contentFullWidth = self.framesView.frame.size.width/CGFloat(C.MAX_DURATION) * CGFloat(numOfFrames)
        
        var contentOffsetX = self.framesView.contentOffset.x
        
        var lineX = self.blockedLineView.frame.origin.x - self.framesView.frame.origin.x
        var realLineX = contentOffsetX + lineX
        println("getVideoEnd contentOffsetX: \(contentOffsetX), contentFullWidth: \(contentFullWidth), frame X: \(self.framesView.frame.origin.x)")
        var s = contentOffsetX/contentFullWidth * CGFloat(self.durationInSeconds)
        var e = realLineX / contentFullWidth * CGFloat(self.durationInSeconds)
        println("getVIdeoEnd frameWidth:\(self.framesView.frame.size.width), numOfFrame: \(self.numOfFrames)")
        println("getVideoEnd realLineX: \(realLineX), fullWidth: \(contentFullWidth), duration: \(self.durationInSeconds)")
        return (s,e,self.framesView.frame.origin.x - self.imgPointer.frame.size.width/2,
            self.blockedLineView.frame.origin.x - self.imgPointer.frame.size.width/2)
        
    }
    
    func setupViews(setupDoneHandler:(Void)->(Void)) {
        self.framesView.dataSource = self
        self.framesView.delegate = self
        self.framesView.bounces = false
        self.framesView.showsHorizontalScrollIndicator = false
        
        framesView.backgroundColor = UIColor.clearColor()
        framesView.layer.borderWidth = 1
        framesView.layer.borderColor = UIColor.orangeColor().CGColor
        addSubview(framesView)
        
        
        slider.backgroundColor = UIColor.redColor()
//        slider.layer.cornerRadius = 6.0
        var panGesture = UIPanGestureRecognizer(target: self, action: "moveSlider:")
        slider.userInteractionEnabled = true
        slider.addGestureRecognizer(panGesture)
        addSubview(slider)
        
        self.blockedLineView.backgroundColor = slider.backgroundColor
        addSubview(self.blockedLineView)
        
        self.framesView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        self.framesView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "LoadingCell")
        
        self.blockedView = UIView()
        self.addSubview(self.blockedView)
        
        self.blockedView.backgroundColor = UIColor(red: 18/255, green: 17/255, blue: 17/255, alpha: 0.5)
        
        self.imgPointer = UIImageView(image: UIImage(named: "pointer"))
        self.imgPointer.tintColor = UIColor.whiteColor()
        self.addSubview(self.imgPointer)
        self.resetPointer()
        
        self.fetchFrames { (Void) -> (Void) in
            setupDoneHandler()
        }
    }
    
    func moveSlider(recognizer: UIPanGestureRecognizer) {
        self.slideBegin = true
        if(recognizer.state == UIGestureRecognizerState.Changed) {
            var currentLocation = recognizer.locationInView(self)
            var minX = self.framesView.frame.origin.x + CGFloat(C.MIN_DURATION) * self.framesView.frame.size.width
            var maxX = self.framesView.frame.origin.x + self.framesView.frame.size.width - self.slider.frame.size.width/2
            var finalX = currentLocation.x
            if(currentLocation.x < minX){
                finalX = minX
            }
            else if(currentLocation.x > maxX){
                finalX = maxX
            }
            
            self.slider.frame = CGRectMake(finalX,
                self.slider.frame.origin.y,
                self.slider.frame.size.width,
                self.slider.frame.size.height)
            
            self.blockedLineView.frame = CGRectMake(slider.frame.origin.x + slider.frame.size.width/2, 0, 1, self.self.frame.size.height)
            
            self.blockedView.frame = CGRect(x: self.slider.frame.origin.x + self.slider.frame.size.width/2,
                y: self.framesView.frame.origin.y,
                width: self.framesView.frame.size.width - (self.slider.frame.origin.x - self.framesView.frame.origin.x + self.slider.frame.width/2),
                
                height: self.framesView.frame.size.height)
            
//            var numOfSelectedFrames = (self.blockedView.frame.origin.x / (bounds.width / 8))
            var numOfSelectedFrames = (self.blockedView.frame.origin.x - self.framesView.frame.origin.x) / (self.framesView.frame.size.width / CGFloat(C.MAX_DURATION))
            offset = NSTimeInterval(numOfSelectedFrames)
            
            self.delegate?.PTFrameWindowControlVideoShouldReset(false)
        } else if(recognizer.state == UIGestureRecognizerState.Ended) {
            sendActionsForControlEvents(UIControlEvents.ValueChanged)
        }
    }
    
    func fetchFrames(durationTimeGotHandler:(Void)->(Void)) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            
            var asset = AVURLAsset(URL: self.videoURL, options: nil)
            var movieTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] as! AVAssetTrack
            var imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            var maxSize = CGSizeMake(320, 180);
            imageGenerator.maximumSize = maxSize
            self.durationInSeconds = CMTimeGetSeconds(asset.duration)
            println("video duration : \(self.durationInSeconds)")
            
            self.framesPerSecond = Int32(movieTrack.nominalFrameRate)
            var timePerFrame = 1.0 / Float64(movieTrack.nominalFrameRate)
            var totalFrames = self.durationInSeconds * Float64(movieTrack.nominalFrameRate)
            self.numOfFrames = Int(ceil(self.durationInSeconds))
            
            var isCallbackCalled = false
            var intDurationInSeconds = round(self.durationInSeconds)
            for var i:Float64 = 0; i < intDurationInSeconds ; i++ {
                
                var time = CMTimeMakeWithSeconds(i, Int32(movieTrack.nominalFrameRate))
                var image = imageGenerator.copyCGImageAtTime(time, actualTime: nil, error: nil)
                if(image != nil) {
                    
                    self.frames.append(UIImage(CGImage:image!)!)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.framesView.reloadData()
                    })
                    
                }
                if(((i == intDurationInSeconds - 1) || (Int(i) > C.MAX_DURATION)) && !isCallbackCalled){
                    //if it is last one
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        durationTimeGotHandler()
                    })
                    isCallbackCalled = true
                }
            }
            
        })
        
    }
    
    
    //Collection View Delegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.delegate?.PTFrameWindowControlVideoShouldReset(true)
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        println("collectionView numOfFrames: \(numOfFrames)")
        if(self.lastNumOfFrames != self.numOfFrames) {
            if(numOfFrames < C.MAX_DURATION && frames.count == numOfFrames){
                self.sliderMovementConstraint = self.framesView.frame.origin.x + self.framesView.frame.size.width - slider.frame.size.width/2
            }
            else{
                self.sliderMovementConstraint = self.framesView.frame.origin.x - slider.frame.size.width/2 + CGFloat(numOfFrames) * (collectionView.bounds.width / CGFloat(C.MAX_DURATION))
            }
            self.reloadLayoutSubviews()
            
            self.lastNumOfFrames = numOfFrames
        }
        
        return frames.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as? UICollectionViewCell
        var videoThumbnail =  frames[indexPath.row]
        var sx = cell!.bounds.width / videoThumbnail.size.width
        var sy = cell!.bounds.height / videoThumbnail.size.height
        var cellThumbnail = UIImageView(image:videoThumbnail)
        cellThumbnail.transform = CGAffineTransformScale(cellThumbnail.transform, sx, sy)
        cellThumbnail.frame.origin.x = 0
        cellThumbnail.frame.origin.y = 0
        cell!.addSubview(cellThumbnail)
        return cell!
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
//        let itemSize = CGSize(width: floor(collectionView.bounds.width / 8), height: floor(collectionView.bounds.height))
        let itemSize = CGSizeMake(self.framesView.frame.size.width/CGFloat(C.MAX_DURATION), frameWindowHeight)
        
        return itemSize
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // do something
        
    }
}


class VCTrim: UIViewController,PTFrameWindowControlDelegate {
    @IBOutlet weak var scrollView:UIScrollView!
    @IBOutlet weak var viewHeader:UIView!
    
    @IBOutlet weak var frameWindow:PTFrameWindowControl!
    
    var mediaPlayer = MPMoviePlayerController()
    
    var videoURL = NSURL()
    var videoHeight = CGFloat(0)
    var videoWidth = CGFloat(0)
    var initialPlaybackTime: NSTimeInterval = 0
    var endingPlaybackTime: NSTimeInterval = Double(C.MAX_DURATION)
    
    var cropLine1 = CALayer()
    var cropLine2 = CALayer()
    var cropLine3 = CALayer()
    var cropLine4 = CALayer()
    var cropLayer = CALayer()
    
    var videoMonitorTimer = NSTimer()
    var videoFrameObj:(videoStart:CGFloat,videoEnd:CGFloat,frameStartX:CGFloat,frameEndX:CGFloat)!
    var indicatorUpdateInterval = 0.05
    
    @IBOutlet weak var btnDone:UIButton!
    
    deinit{
        println("viewTrim deinit");
    }
    
    func stopMediaPlayer(){
        self.frameWindow.resetPointer()
        if(self.mediaPlayer.playbackState == MPMoviePlaybackState.Playing){
            self.mediaPlayer.pause()
        }
        if(self.videoMonitorTimer.valid){
            self.videoMonitorTimer.invalidate()
        }
    }
    func updatePlayTime(){
        var progress = (CGFloat(self.mediaPlayer.currentPlaybackTime)-self.videoFrameObj.videoStart)/(self.videoFrameObj.videoEnd-self.videoFrameObj.videoStart)
        //update indicator
//        println("updatePlayTime currentTime: \(self.mediaPlayer.currentPlaybackTime), start: \(self.videoFrameObj.videoStart) end: \(self.videoFrameObj.videoEnd), p: \(progress)")
        
        self.frameWindow.updatePointerSizeWithProgress(progress)
        
        if(self.mediaPlayer.currentPlaybackTime >= self.mediaPlayer.endPlaybackTime - indicatorUpdateInterval){
//            println("movie end!!")
            self.mediaPlayer.pause()
            self.videoMonitorTimer.invalidate()
            self.frameWindow.correctEndPointerPosition()
            
        }
    }
    
    func videoDidPaused(){
        
    }
    func videoDidPlaying(){
        if(self.videoMonitorTimer.valid){
            self.videoMonitorTimer.invalidate()
        }
        self.videoMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(indicatorUpdateInterval, target: self, selector: "updatePlayTime", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(self.videoMonitorTimer, forMode: NSRunLoopCommonModes)
        
    }
    
    func playbackStateChanged(){
        switch(self.mediaPlayer.playbackState){
        case MPMoviePlaybackState.Stopped:
            println("Stopped")
            self.videoDidPaused()
        case MPMoviePlaybackState.Playing:
            println("Playing currentPlaybackTime: \(self.mediaPlayer.currentPlaybackTime)")
            self.videoDidPlaying()
            
        case MPMoviePlaybackState.Paused:
            println("Paused")
            self.videoDidPaused()
        case MPMoviePlaybackState.Interrupted:
            println("Interrupted")
        case MPMoviePlaybackState.SeekingForward:
            println("SeekingForward")
        case MPMoviePlaybackState.SeekingBackward:
            println("SeekingBackward")
        default:
            println("default")
        }
        
        println("playbackStateChanged: \(self.mediaPlayer.playbackState.rawValue)")
    }
    func playbackEnded(){
        println("playbackEnded: \(self.mediaPlayer.playbackState.rawValue)")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if(videoMonitorTimer.valid){
            videoMonitorTimer.invalidate()
        }
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerPlaybackStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
        self.mediaPlayer.stop()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playbackStateChanged", name: MPMoviePlayerPlaybackStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playbackEnded", name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.contentOffset = CGPointZero
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.bounces = false
        
        //media
        self.scrollView.addSubview(mediaPlayer.view)
        self.scrollView.contentSize = CGSizeMake(videoWidth, videoHeight)
        self.mediaPlayer.view.frame = CGRect(x: 0, y: 0, width:videoWidth, height: videoHeight)

        self.mediaPlayer.contentURL = self.videoURL
        self.mediaPlayer.shouldAutoplay = false
        self.mediaPlayer.prepareToPlay()
        self.mediaPlayer.movieSourceType = MPMovieSourceType.File
        self.mediaPlayer.controlStyle = MPMovieControlStyle.None
        self.mediaPlayer.scalingMode = MPMovieScalingMode.AspectFit
        self.mediaPlayer.initialPlaybackTime = self.initialPlaybackTime
        self.mediaPlayer.endPlaybackTime = self.endingPlaybackTime
        self.mediaPlayer.pause()
        
        self.addCropLine()
        self.frameWindow.videoURL = self.videoURL
        self.frameWindow.delegate = self
        self.frameWindow.setupViews { (Void) -> (Void) in
            println("frameWindow done!!")
            //for handle video bar not set yet problem
            NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "replay", userInfo: nil, repeats: false)
        }
        
        
    }
    func addCropLine(){
        cropLine1.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        cropLayer.addSublayer(cropLine1)
        cropLine2.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        cropLayer.addSublayer(cropLine2)
        cropLine3.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        cropLayer.addSublayer(cropLine3)
        cropLine4.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        cropLayer.addSublayer(cropLine4)
        self.view.layer.addSublayer(cropLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let paddingHeight = self.viewHeader.frame.size.height
        
        cropLayer.frame =  CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.width)
        cropLine1.frame = CGRect(x: 0, y: paddingHeight+cropLayer.bounds.height / 3, width: cropLayer.bounds.width, height: cropLayer.bounds.height * 0.005)
        cropLine2.frame = CGRect(x: 0, y: paddingHeight + 2 * cropLayer.bounds.height / 3, width: cropLayer.bounds.width, height: cropLayer.bounds.height * 0.005)
        cropLine3.frame = CGRect(x: cropLayer.bounds.width / 3, y: paddingHeight+0, width: self.view.bounds.width * 0.005, height: cropLayer.bounds.height)
        cropLine4.frame = CGRect(x: cropLine3.frame.origin.x + cropLayer.bounds.width / 3, y: paddingHeight+0, width: self.view.bounds.width * 0.005, height: cropLayer.bounds.height)
        
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func setup(url:NSURL,videoWidth:CGFloat,videoHeight:CGFloat){
        self.videoURL = url
        self.videoWidth = videoWidth
        self.videoHeight = videoHeight
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnReplayClicked(){
        self.replay()
    }
    
    func replay(){
        println("replay!")
        self.videoFrameObj = self.frameWindow.getVideoStartEnd()
        if(self.videoFrameObj.videoEnd == 0){
            //not ready
            println("not ready, call it later..")
            self.frameWindow.reloadLayoutSubviews()
            NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "replay", userInfo: nil, repeats: false)
        }
        else{
            println("start: \(self.videoFrameObj.videoStart), end: \(self.videoFrameObj.videoEnd)")
            self.mediaPlayer.currentPlaybackTime = Double(self.videoFrameObj.videoStart)
            
            self.mediaPlayer.endPlaybackTime = Double(self.videoFrameObj.videoEnd)
            self.initialPlaybackTime = Double(self.videoFrameObj.videoStart)
            self.endingPlaybackTime = Double(self.videoFrameObj.videoEnd)
            self.mediaPlayer.play()
            println("setted currentPlaybackTime: \(self.mediaPlayer.currentPlaybackTime)")
        }
    }
    
    @IBAction func btnBackClicked(){
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func btnDoneClicked(){
        self.trimVideoView()
    }
    
    func trimVideoView(){
        self.stopMediaPlayer()
        SVProgressHUD.show()
        
        var trimmedVideo = AVURLAsset(URL: videoURL, options: nil)
        
        var videoProcessor = PTVideoProcessor()
        
        //initialize videoProcessor
        videoProcessor.asset = trimmedVideo
        videoProcessor.videoHeight = videoHeight
        videoProcessor.videoWidth = videoWidth
//        videoProcessor.indicator = indicator
        videoProcessor.cropOffsetX = self.scrollView.contentOffset.x
        videoProcessor.cropOffsetY = self.scrollView.contentOffset.y
        videoProcessor.offset =  self.frameWindow.offset
        videoProcessor.initialPlaybackTime = initialPlaybackTime
        videoProcessor.endingPlaybackTime = endingPlaybackTime
        videoProcessor.framesPerSecond = self.frameWindow.framesPerSecond
        
        println("trim with:\nWidth: \(videoWidth)\nHeight: \(videoHeight)\n cropX: \(videoProcessor.cropOffsetX),\n cropY: \(videoProcessor.cropOffsetY),\n offset: \(videoProcessor.offset),\n initTime: \(videoProcessor.initialPlaybackTime), \n endTime: \(videoProcessor.endingPlaybackTime), \n framesPerSecond: \(videoProcessor.framesPerSecond)")
        
        //crop and trim video
        videoProcessor.cropVideo { (Void) -> (Void) in
            SVProgressHUD.dismiss()
        }
    }
    
    //Control Delegate
    func PTFrameWindowControlVideoShouldReset(isSetFront: Bool) {
//        println("delegate did call")
        self.stopMediaPlayer()
        self.videoFrameObj = self.frameWindow.getVideoStartEnd()
        if(isSetFront){
            self.mediaPlayer.currentPlaybackTime = Double(self.videoFrameObj.videoStart)
        }
        else{
            self.mediaPlayer.currentPlaybackTime = Double(self.videoFrameObj.videoEnd)
        }
        println("isSetFront: \(isSetFront), self.mediaPlayer: \(self.mediaPlayer)")
    }

    
}
