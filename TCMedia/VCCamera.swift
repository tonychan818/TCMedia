//
//  VCCamera.swift
//  TCMedia
//
//  Created by Tony on 24/8/15.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import UIKit


import SVProgressHUD
import SCRecorder


class VCCamera: UIViewController,SCRecorderDelegate,UIImagePickerControllerDelegate,UIScrollViewDelegate,PTVideoDelegate {
    let CAPTURE_BTN_NORMAL = "#81F781"
    let CAPTURE_BTN_TOUCH_DOWN = "#04B404"
    let CAPTURE_BTN_CANCEL = "#DF0101"
    let ANIMATION_TIME = 0.1
    
    var screenWidth = 0.0
    var recorder:SCRecorder!
    var recordSession:SCRecordSession!
    
    var recorderForPic:SCRecorder!
    var currentPageNum = 0
    var lastFrameWidth = CGFloat(-1.0)
    
    var isAppBegin = false
    var isPreviewEnabled = false
    
    @IBOutlet weak var constraintOptionLabel:NSLayoutConstraint!
    @IBOutlet weak var constraintTopSpacingForBlurView:NSLayoutConstraint!
    @IBOutlet weak var loadingView:UIView!
    @IBOutlet weak var loadingBlurView:UIVisualEffectView!
    
    @IBOutlet weak var scrollView:UIScrollView!
    
    var focusView:SCRecorderToolsView!
    
    @IBOutlet weak var previewView:UIView!
    @IBOutlet weak var previewForTakePicView:UIView!
    @IBOutlet weak var btnCapture:UIButton!
    @IBOutlet weak var btnTakePic:UIButton!
    @IBOutlet weak var btnNext:UIButton!
    
    //options
    @IBOutlet weak var btnImage: UIButton!
    @IBOutlet weak var btnVideo: UIButton!
    @IBOutlet weak var btnAlbum: UIButton!
    
    var viewProgress:UIView!
    
    var viewTempCamera:UIImageView!
    
    @IBOutlet weak var viewAlbumTool:PTVideoPickerView!
    @IBOutlet weak var viewCameraTool:UIView!
    @IBOutlet weak var viewTakePhotoTool:UIView!
    
    deinit{
        println("VCCamera deinit")
    }
    
    @IBAction func btnNextClicked(){
        if(self.currentPageNum == 1){
            self.recorderForPic.pause()
            self.recorder.pause { () -> Void in
                if let session = self.recorder.session{
                    self.recordSession = session
                    self.recordSession.mergeSegmentsUsingPreset(AVAssetExportPresetHighestQuality, completionHandler: { (url, error) -> Void in
                        println("toTrimVC with recorded session")
                        self.toTrimVC(url!, videoWidth: self.view.frame.size.width, videoHeight: self.view.frame.size.width)
                    })
                    
                }
            }
        }
        else if(self.currentPageNum == 2){
            println("toTrimVC with album record")
            self.toTrimVC(self.viewAlbumTool.currentMovieURL!, videoWidth: self.viewAlbumTool.currentVideoWidth!, videoHeight: self.viewAlbumTool.currentVideoHeight!)
            //            self.toTrimVC(self.viewAlbumTool.currentMovieURL!,self.viewAlbumTool.currentVideoWidth,self.viewAlbumTool.currentVideoHeight)
        }
    }
    
    func toTrimVC(url:NSURL,videoWidth:CGFloat,videoHeight:CGFloat){
        
        var vcTrim = VCTrim(nibName:"VCTrim",bundle:nil)
        vcTrim.setup(url, videoWidth: videoWidth, videoHeight: videoHeight)
        self.navigationController?.pushViewController(vcTrim, animated: true)
        
    }
    
    @IBAction func btnCloseClicked(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func btnTakePhotoClicked(){
        self.recorderForPic.capturePhoto { (error, image) -> Void in
            if let e = error{
                println("capture photo with error: \(e)")
            }
            else{
                if let img = image{
                    println("imageGot!")
                }
            }
        }
    }
    
    @IBAction func btnCaptureOnTouchDown(){
        UIView.animateWithDuration(ANIMATION_TIME, animations: { () -> Void in
            self.btnCapture.backgroundColor = UIColor(rgba: self.CAPTURE_BTN_TOUCH_DOWN)
        })
        self.record()
    }
    @IBAction func btnCaptureOnExit(){
        UIView.animateWithDuration(ANIMATION_TIME, animations: { () -> Void in
            self.btnCapture.backgroundColor = UIColor(rgba: self.CAPTURE_BTN_CANCEL)
        })
        self.pause()
    }
    @IBAction func btnCaptureOnEnter(){
        //        UIView.animateWithDuration(ANIMATION_TIME, animations: { () -> Void in
        //            self.btnCapture.backgroundColor = UIColor(rgba: self.CAPTURE_BTN_TOUCH_DOWN)
        //        })
    }
    @IBAction func btnCaptureOnTouchUpOutside(){
        UIView.animateWithDuration(ANIMATION_TIME, animations: { () -> Void in
            self.btnCapture.backgroundColor = UIColor(rgba: self.CAPTURE_BTN_NORMAL)
        })
        self.pause()
    }
    @IBAction func btnCaptureOnTouchUpInside(){
        UIView.animateWithDuration(ANIMATION_TIME, animations: { () -> Void in
            self.btnCapture.backgroundColor = UIColor(rgba: self.CAPTURE_BTN_NORMAL)
        })
        self.pause()
    }
    
    
    @IBAction func btnOptionsClicked(sender: AnyObject) {
        var btn = sender as! UIButton
        var pageToGo = 0
        if(self.btnImage === btn){
            self.constraintOptionLabel.constant = 0
            pageToGo = 0
        }
        else if(self.btnVideo === btn){
            self.constraintOptionLabel.constant = self.btnVideo.frame.origin.x
            pageToGo = 1
        }
        else if(self.btnAlbum === btn){
            self.constraintOptionLabel.constant = self.btnAlbum.frame.origin.x
            pageToGo = 2
        }
        
        self.scrollView.scrollRectToVisible(CGRectMake(self.scrollView.frame.size.width * CGFloat(pageToGo), self.scrollView.frame.origin.x, self.scrollView.frame.size.width, self.scrollView.frame.size.height), animated: true)
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }) { (b) -> Void in
                self.delay(0.2, closure: { () -> () in
                    self.scrollEnd()
                })
        }
        println("constraintOptionLabel.constant: \(self.constraintOptionLabel.constant)")
    }
    
    func pause(){
        self.recorder.pause()
    }
    
    func record(){
        self.recorder.record()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.prepareSession()
    }
    
    func prepareSession(){
        if(self.recorder.session == nil){
            var session = SCRecordSession()
            session.fileType = AVFileTypeQuickTimeMovie
            self.recorder.session = session
        }
        //update time record label
        self.updateTimeProgress()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if(!self.isAppBegin){
            self.recorder.previewViewFrameChanged()
            self.recorderForPic.previewViewFrameChanged()
            
            self.screenWidth = Double(self.view.frame.size.width)
            //            self.constraintProgressWidth.constant = CGFloat(0)
            
            self.viewAlbumTool.mediaPlayer.view.frame = self.focusView.frame
            self.viewAlbumTool.photoPreview.frame = self.viewAlbumTool.mediaPlayer.view.frame
            self.initPositions()
            self.viewAlbumTool.updateFrame()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        self.initRecorder()
        self.initAlbum()
        
        UIApplication.sharedApplication().statusBarHidden = true
        
        self.showToolPage(0)
        self.loadingView.hidden = true
        
    }
    
    
    func stopMedidPlayer(){
        println("stopMedidPlayer")
        self.viewAlbumTool.mediaPlayer.stop()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if(self.currentPageNum == 2){
            if(!self.viewAlbumTool.mediaPlayer.view.hidden){
                self.viewAlbumTool.mediaPlayer.play()
            }
        }
        else if(self.currentPageNum == 1){
            self.recorderReset()
            self.recorder.startRunning()
        }
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.recorder.stopRunning()
        self.recorderForPic.stopRunning()
        self.viewAlbumTool.mediaPlayer.stop()
    }
    func initRecorder(){
        
        self.viewTempCamera = UIImageView()
        self.viewTempCamera.contentMode = UIViewContentMode.ScaleAspectFill
        self.viewTempCamera.clipsToBounds = true
        self.view.addSubview(self.viewTempCamera)
        //for takepic
        self.recorderForPic = SCRecorder()
        
        self.recorderForPic.captureSessionPreset = AVCaptureSessionPresetPhoto
        self.recorderForPic.videoConfiguration.sizeAsSquare = true
        self.recorderForPic.previewView = self.previewForTakePicView
        
        self.recorderForPic.initializeSessionLazily = false
        self.scrollView.addSubview(self.previewForTakePicView)
        
        //for video
        self.recorder = SCRecorder()
        self.recorder.captureSessionPreset = SCRecorderTools.bestCaptureSessionPresetCompatibleWithAllDevices()
        self.recorder.maxRecordDuration = CMTimeMake(Int64(C.MAX_DURATION), 1)
        self.recorder.delegate = self
        self.recorder.videoConfiguration.sizeAsSquare = true
        self.recorder.previewView = self.previewView
        
        self.focusView = SCRecorderToolsView(frame: self.previewView.frame)
        self.focusView.recorder = self.recorder
        self.recorder.initializeSessionLazily = false
        
        self.viewProgress = UIView(frame: CGRectMake(0, 0, 0, 10))
        self.viewProgress.backgroundColor = UIColor.greenColor()
        
        self.scrollView.addSubview(self.viewProgress)
        self.scrollView.addSubview(self.previewView)
        self.previewView.addSubview(self.focusView)
        
        self.scrollView.addSubview(self.viewTakePhotoTool)
        self.scrollView.addSubview(self.viewCameraTool)
        
        self.btnCapture.layer.borderColor = UIColor.whiteColor().CGColor
        self.btnCapture.layer.borderWidth = 4.0
        self.btnCapture.backgroundColor = UIColor(rgba: CAPTURE_BTN_NORMAL)
        
        self.btnTakePic.layer.borderColor = UIColor.whiteColor().CGColor
        self.btnTakePic.layer.borderWidth = 4.0
        self.btnTakePic.backgroundColor = UIColor(rgba: CAPTURE_BTN_NORMAL)
        
    }
    func initAlbum(){
        self.viewAlbumTool.setup(self)
        self.viewAlbumTool.delegate = self
        self.scrollView.addSubview(self.viewAlbumTool.mediaPlayer.view)
        self.scrollView.addSubview(self.viewAlbumTool.photoPreview)
        self.scrollView.addSubview(self.viewAlbumTool)
    }
    func initPositions(){
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * 3, self.scrollView.frame.size.height)
        //11111111
        self.previewForTakePicView.frame = CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.width)
        
        self.viewTakePhotoTool.frame = CGRectMake(0, self.scrollView.frame.size.width, self.scrollView.frame.size.width, self.scrollView.frame.size.height - self.scrollView.frame.size.width)
        //2222222222
        //2 is reuse -.-
        self.viewProgress.frame = CGRectMake(self.scrollView.frame.size.width, 0, 0, 10)
        self.previewView.frame = CGRectMake(self.scrollView.frame.size.width, self.viewProgress.frame.size.height, self.scrollView.frame.size.width, self.scrollView.frame.size.width)
        self.focusView.frame = CGRectMake(self.scrollView.frame.size.width, 0, self.previewView.frame.size.width, self.previewView.frame.size.height)
        
        self.viewCameraTool.frame = CGRectMake(self.scrollView.frame.size.width, self.scrollView.frame.size.width, self.scrollView.frame.size.width, self.scrollView.frame.size.height - self.scrollView.frame.size.width)
        
        //temp preview
        
        self.viewTempCamera.frame = CGRectMake(0, self.scrollView.frame.origin.y, self.previewView.frame.size.width, self.previewView.frame.size.height)
        //333333333333
        
        self.viewAlbumTool.mediaPlayer.view.frame = CGRectMake(self.scrollView.frame.size.width * 2, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.width)
        
        self.viewAlbumTool.photoPreview.frame = CGRectMake(self.scrollView.frame.size.width * 2, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.width)
        
        self.viewAlbumTool.frame = CGRectMake(self.scrollView.frame.size.width * 2, self.viewAlbumTool.mediaPlayer.view.frame.size.height, self.viewCameraTool.frame.size.width,self.viewCameraTool.frame.size.height)
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateTimeProgress(){
        println("updateTimeProgress")
        var currentTime = kCMTimeZero
        if(self.recorder.session != nil){
            if let s = self.recorder.session{
                currentTime = s.duration
            }
        }
        var progress = Float(CMTimeGetSeconds(currentTime))/Float(C.MAX_DURATION)
        if(self.screenWidth != 0){
            println("currenttime: \(currentTime)")
            self.viewProgress.frame = CGRectMake(self.viewProgress.frame.origin.x, 0, self.view.frame.size.width * CGFloat(progress), self.viewProgress.frame.size.height)
            println("frame: \(self.viewProgress.frame)")
            //            self.constraintProgressWidth.constant = CGFloat(progress) * CGFloat(self.screenWidth)
        }
        if(progress == 0){
            self.btnNext.hidden = true
        }
        else{
            self.btnNext.hidden = false
        }
    }
    
    //recorder delegate
    func recorderReset(){
        println("recorderReset")
        if (recordSession != nil) {
            self.recorder.session = nil;
            if(SCRecordSessionManager2.sharedInstance.isSaved(recordSession)){
                self.recordSession.endSegmentWithInfo(nil, completionHandler: nil)
            }
            else{
                self.recordSession.cancelSession(nil)
            }
        }
        self.prepareSession()
    }
    
    func recorder(recorder: SCRecorder, didReconfigureVideoInput videoInputError: NSError?){
        
        self.loadingView.hidden = true
        self.stopMedidPlayer()
    }
    func recorderWillStartFocus(recorder: SCRecorder){
        println("recorderWillStartFocus")
    }
    func recorder(recorder: SCRecorder, didCompleteSession session: SCRecordSession) {
        println("record didCompleteSession")
        //save and show session
    }
    func recorder(recorder: SCRecorder, didInitializeVideoInSession session: SCRecordSession, error: NSError?) {
        if let e = error{
            println("failed to initialize video in record session  \(e.localizedDescription)")
        }
        else{
            println("record didInitializedVideo success")
            self.updateTimeProgress()
        }
    }
    func recorder(recorder: SCRecorder, didBeginSegmentInSession session: SCRecordSession, error: NSError?) {
        println("record Began record segment: \(error)")
    }
    func recorder(recorder: SCRecorder, didCompleteSegment segment: SCRecordSessionSegment?, inSession session: SCRecordSession, error: NSError?) {
        println("record Completed record segment at \(segment?.url) error: \(error), frameRate: \(segment?.frameRate)")
    }
    func recorder(recorder: SCRecorder, didAppendVideoSampleBufferInSession session: SCRecordSession) {
        println("record DidAppendVideoSample")
        self.updateTimeProgress()
    }
    
    //UIScrollViewDelegate
    func scrollEnd(){
        var pageNum = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        
        if(pageNum != self.currentPageNum){
            println("page Changed!")
            self.showToolPage(pageNum)
        }
        else{
            self.hidePreviews()
        }
        self.currentPageNum = pageNum
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        println("scrollViewDidEndDecelerating")
        self.scrollEnd()
    }
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        println("scrollViewDidEndDragging")
        if(!decelerate){
            self.scrollEnd()
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.isAppBegin = true
        self.showPreviews()
        
    }
    
    func setTempView(){
        //everytime it run set pic
        println("try to capture photo!!!")
        self.recorderForPic.capturePhoto { (error, image) -> Void in
            if let e = error{
                println("capture photo with error: \(e)")
            }
            else{
                if let img = image{
                    println("#####set preview image")
                    self.viewTempCamera.image = img
                }
            }
        }
    }
    
    func showPreviews(){
        if(!self.isPreviewEnabled){
            println("showPreview currentPageNum: \(self.currentPageNum)")
            //preview...
            self.isPreviewEnabled = true
            self.view.bringSubviewToFront(self.viewTempCamera)
            
            //get video snapshot
            self.viewTempCamera.hidden = false
            
            self.view.bringSubviewToFront(self.loadingBlurView)
            self.loadingBlurView.hidden = false
        }
    }
    func hidePreviews(){
        self.scrollView.scrollEnabled = true
        Log.shareInstance.p("### hidePreviews", caller: nil)
        self.viewTempCamera.hidden = true
        self.isPreviewEnabled = false
        self.loadingBlurView.hidden = true
    }
    
    func showToolPage(pageNum:Int){
        self.scrollView.scrollEnabled = false
        
        self.delay(0.4, closure: { () -> () in
            if(pageNum == 0){
                //                self.constraintTopSpacingForBlurView.constant = self.viewProgress.frame.size.height
                //                self.loadingBlurView.frame = CGRectMake(0, 0, self.loadingBlurView.frame.size.width, self.loadingBlurView.frame.size.height)
                //video capture
                self.btnNext.hidden = true
                self.setVideoAlbum(false)
                self.setVideoCapture(false,finishCB: nil)
                self.setTakePic(true, finishCB: { () -> () in
                    self.hidePreviews()
                })
                self.constraintOptionLabel.constant = 0
            }
                
            else if(pageNum == 1){
                //                self.constraintTopSpacingForBlurView.constant = 0
                //                self.loadingBlurView.frame = CGRectMake(0, self.viewProgress.frame.origin.y, self.loadingBlurView.frame.size.width, self.loadingBlurView.frame.size.height)
                //video selection
                self.btnNext.hidden = true
                self.updateTimeProgress()
                self.setVideoAlbum(false)
                self.setTakePic(false, finishCB: nil)
                self.setVideoCapture(true, finishCB: { () -> () in
                    self.hidePreviews()
                })
                self.constraintOptionLabel.constant = self.btnVideo.frame.origin.x
            }
            else if(pageNum == 2){
                self.btnNext.hidden = false
                self.setVideoCapture(false,finishCB:nil)
                self.setTakePic(false,finishCB:nil)
                self.setVideoAlbum(true)
                self.hidePreviews()
                self.constraintOptionLabel.constant = self.btnAlbum.frame.origin.x
            }
            
            
            println("record preview: \(self.previewView.frame)")
            
            
        })
        
    }
    
    func setViewWithPageNum(pageNum:Int){
        
    }
    
    
    func setTakePic(b:Bool,finishCB:(()->())?){
        if(b){
            finishCB?()
            self.recorderForPic.startRunning()
            //            self.recorderForPic.startRunning()
            self.previewForTakePicView.hidden = false
            self.setTempView()
        }
        else{
            self.recorderForPic.stopRunning()
            self.previewForTakePicView.hidden = true
            finishCB?()
        }
    }
    
    func setVideoCapture(b:Bool,finishCB:(()->())?){
        if(b){
            
            //            dispatch_async(dispatch_get_main_queue(), { () -> Void in
            //                self.recorder.captureSessionPreset = AVCaptureSessionPresetHigh
            finishCB?()
            //            })
            self.recorder.startRunning()
            self.previewView.hidden = false
        }
        else{
            self.recorder.stopRunning()
            self.previewView.hidden = true
            finishCB?()
        }
    }
    
    func setVideoAlbum(b:Bool){
        self.viewAlbumTool.setVideoAlbum(b)
    }
    
    //PTVideo Delegate
    func PTVideoDidExpend() {
        //        self.viewAlbumTool
    }
    func PTMediaDidSelect(){
        println("PTMediaDidSelect")
        if(self.currentPageNum == 2){
            self.btnNext.hidden = false
        }
    }
    
    //new function!!
    func captureVideoScreen(imageCapturedCB:((img:UIImage)->())){
        println("captureVideoScreen pagenum: \(self.currentPageNum)")
        
        var stillImageOutput = AVCaptureStillImageOutput()
        
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        var usedRecorder:SCRecorder?
        
        if(self.currentPageNum == 0){
            usedRecorder = self.recorderForPic
        }
        else if(self.currentPageNum == 1){
            usedRecorder = self.recorderForPic
        }
        
        if let ur = usedRecorder{
            
            if let cs = ur.captureSession{
                //remove still image output
                var targetOutput:AVCaptureStillImageOutput!
                for index in 0...cs.outputs.count - 1{
                    var output: AnyObject = cs.outputs[index]
                    if(output is AVCaptureStillImageOutput){
                        targetOutput = output as! AVCaptureStillImageOutput
                        break
                    }
                }
                cs.removeOutput(targetOutput)
                cs.addOutput(stillImageOutput)
                if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo){
                    cs.addOutput(stillImageOutput)
                    stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
                        (sampleBuffer, error) in
                        cs.addOutput(stillImageOutput)
                        var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                        var dataProvider = CGDataProviderCreateWithCFData(imageData)
                        var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
                        var image = UIImage(CGImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.Right)
                        if let img = image{
                            imageCapturedCB(img: img)
                        }
                        
                    })
                }
            }
        }
        
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
