
import UIKit
import AVFoundation
import MobileCoreServices
import AssetsLibrary
import MediaPlayer

protocol PTVideoDelegate:class{
    func PTMediaDidSelect()
    func PTVideoDidExpend()
}

class PTPhotoCell: UICollectionViewCell {
    
    var videoThumbnail = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        videoThumbnail.frame = self.bounds
    }
    
    func setupViews() {
        addSubview(videoThumbnail)
    }
    
    override var selected: Bool {
        willSet(newValue) {
        }
        
        didSet {
            videoThumbnail.layer.borderWidth = selected ? 2.0 : 0.0
            videoThumbnail.layer.borderColor = UIColor.whiteColor().CGColor
        }
    }
    
}

class PTVideoCell: UICollectionViewCell {
    
    var videoThumbnail = UIImageView()
    var videoDuration = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        videoThumbnail.frame = self.bounds
    }
    
    func setupViews() {
        
        addSubview(videoThumbnail)
        
        videoDuration.sizeToFit()
        addSubview(videoDuration)
    }
    
    override var selected: Bool {
        willSet(newValue) {
        }
        
        didSet {
            videoThumbnail.layer.borderWidth = selected ? 2.0 : 0.0
            videoThumbnail.layer.borderColor = UIColor.whiteColor().CGColor
        }
    }
    
}

class PTVideoPickerView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,UIGestureRecognizerDelegate {
    
    var isUp = false
    var lastScrollViewY = CGFloat(0)
    var isAtBoundary = false
    var lastContentOffset = CGPointZero
    var originalFrame = CGRectZero
    
    var mediaPlayer = MPMoviePlayerController()
    var photoPreview = UIImageView()
    weak var delegate:PTVideoDelegate?
    
    var assetLibrary = ALAssetsLibrary()
    var medias = [ALAsset]()
    var currentMovieURL: NSURL?
    
    var shouldShowFirstMedia: Bool = true
    var currentVideoHeight: CGFloat?
    var currentVideoWidth: CGFloat?
    
    var selectedIndex = 0
    
    @IBOutlet weak var mediaCollection:UICollectionView!
    
    func setup(vc:UIViewController){
        
        self.photoPreview.contentMode = UIViewContentMode.ScaleAspectFill
        
        self.mediaPlayer.movieSourceType = MPMovieSourceType.File
        self.mediaPlayer.controlStyle = MPMovieControlStyle.None
        self.mediaPlayer.repeatMode = MPMovieRepeatMode.One
        self.mediaPlayer.scalingMode = MPMovieScalingMode.AspectFill
        self.mediaPlayer.view.backgroundColor = UIColor.clearColor()
        
        self.mediaCollection.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        self.mediaCollection.delegate = self
        self.mediaCollection.dataSource = self
        self.mediaCollection.registerClass(PTVideoCell.self, forCellWithReuseIdentifier: "PTVideoCell")
        self.mediaCollection.registerClass(PTPhotoCell.self, forCellWithReuseIdentifier: "PTPhotoCell")
        loadMedias()
        self.originalFrame = self.frame
        
        
        var tap = UITapGestureRecognizer(target: self, action: "tapOnImageOrVideo")
        self.photoPreview.addGestureRecognizer(tap)
        self.photoPreview.userInteractionEnabled = true
        
    }
    
    func tapOnImageOrVideo(){
        self.closeAlbumView()
    }
    
    func updateFrame(){
        self.originalFrame = self.frame
    }
    func loadMedias() {
        
        assetLibrary.enumerateGroupsWithTypes(ALAssetsGroupSavedPhotos, usingBlock: { (grp: ALAssetsGroup!, groupBool: UnsafeMutablePointer<ObjCBool>) -> Void in
            // do something here
            if ALAssetsFilter.allVideos() != nil && grp != nil {
//                grp.setAssetsFilter(ALAssetsFilter.allVideos())
                if grp != nil {
//                    grp.setAssetsFilter(ALAssetsFilter.allVideos())
                    grp.enumerateAssetsUsingBlock({ (asset: ALAsset?, index: Int, assetBool: UnsafeMutablePointer<ObjCBool>) -> Void in
                        
                        if asset != nil  {
                            
//                            self.videos.append(asset!)
                            self.medias.insert(asset!, atIndex: 0)
                            self.mediaCollection.reloadData({ () -> () in
                                println("reload table done")
                                self.mediaCollection.selectItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), animated: false, scrollPosition: UICollectionViewScrollPosition.None)
                            })
                            
                        }
                        
                    })
                }
            }
            
            
            }) { (error) -> Void in
                // Handle error
                println("error in fetching assets")
        }
        
    }
    
    func playMovie(url: NSURL) {
        
        self.mediaPlayer.contentURL = url
        self.mediaPlayer.prepareToPlay()
        self.mediaPlayer.play()
    }
    
    func setVideoAlbum(b:Bool){
        if(b){
            self.showMedia()
        }
        else{
            self.mediaPlayer.stop()
            self.mediaPlayer.view.hidden = true
        }
    }
    // Implement CollectionView Delegate
    
    func convertCfTypeToCGImage(cgValue: Unmanaged<CGImage>) -> CGImage{
        
        let value = Unmanaged.fromOpaque(
            cgValue.toOpaque()).takeUnretainedValue() as CGImage
        return value
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return medias.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var asset = medias[indexPath.row]
        
        if(asset.valueForProperty(ALAssetPropertyType).isEqualToString(ALAssetTypeVideo)){
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("PTVideoCell", forIndexPath: indexPath) as! PTVideoCell
            cell.backgroundColor = UIColor.blackColor()
            
            //set movie thumbnail
            var managedCGImage = convertCfTypeToCGImage(medias[indexPath.row].thumbnail())
            var videoThumbnail: UIImage = UIImage(CGImage: managedCGImage)!
            var sx = cell.bounds.width / videoThumbnail.size.width
            var sy = cell.bounds.height / videoThumbnail.size.height
            cell.videoThumbnail.image = videoThumbnail
            cell.videoThumbnail.transform = CGAffineTransformScale(cell.videoThumbnail.transform, sx, sy)
            cell.videoThumbnail.frame.origin.x = 0
            cell.videoThumbnail.frame.origin.y = 0
            
            var duration: AnyObject! = medias[indexPath.row].valueForProperty(ALAssetPropertyDuration)
            var seconds = duration as! Int % 60;
            var minutes = (duration as! Int / 60) % 60;
            var hours = duration as! Int / 3600;
            
            //display duration of movie
            var formattedDuration: String = "\(hours):\(minutes):\(seconds)"
            cell.videoDuration.text = formattedDuration
            cell.videoDuration.sizeToFit()
            cell.videoDuration.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
            cell.videoDuration.frame = CGRect(x: (cell.frame.width -  cell.videoDuration.frame.width) / 2.0, y: (cell.frame.height -  cell.videoDuration.frame.height) / 2.0, width:  cell.videoDuration.frame.width, height:  cell.videoDuration.frame.height)
            
            if(shouldShowFirstMedia == true && indexPath.row == 0) {
                
                self.collectionView(collectionView, didSelectItemAtIndexPath: NSIndexPath(forItem: 0, inSection: 0))
                shouldShowFirstMedia = false
            }
            return cell
        }
        else{
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("PTPhotoCell", forIndexPath: indexPath) as! PTPhotoCell
            cell.backgroundColor = UIColor.blackColor()
            
            //set movie thumbnail
            var managedCGImage = convertCfTypeToCGImage(medias[indexPath.row].thumbnail())
            var videoThumbnail: UIImage = UIImage(CGImage: managedCGImage)!
            var sx = cell.bounds.width / videoThumbnail.size.width
            var sy = cell.bounds.height / videoThumbnail.size.height
            cell.videoThumbnail.image = videoThumbnail
            cell.videoThumbnail.transform = CGAffineTransformScale(cell.videoThumbnail.transform, sx, sy)
            cell.videoThumbnail.frame.origin.x = 0
            cell.videoThumbnail.frame.origin.y = 0
            
            
            if(shouldShowFirstMedia == true && indexPath.row == 0) {
                self.collectionView(collectionView, didSelectItemAtIndexPath: NSIndexPath(forItem: 0, inSection: 0))
                shouldShowFirstMedia = false
            }
            
            return cell
        }
        
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let itemSize = CGSize(width: floor((collectionView.bounds.width - 30) / 4), height: floor((collectionView.bounds.width - 30) / 4))
        return itemSize
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10.0
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.PTMediaDidSelect()
        self.selectedIndex = indexPath.row
        
        showMedia()
        self.closeAlbumView()
    }
    
    func showMedia(){
        
        var currentAsset = self.medias[self.selectedIndex]
        
        if(currentAsset.valueForProperty(ALAssetPropertyType).isEqualToString(ALAssetTypeVideo)){
            
            self.mediaPlayer.view.hidden = false
            self.photoPreview.image = nil
            
            if(self.mediaPlayer.playbackState == MPMoviePlaybackState.Playing) {
                self.mediaPlayer.stop()
            }
            
            var videoRepresentation = medias[self.selectedIndex].defaultRepresentation()
            var path = videoRepresentation.url()
            
            var videoWidth = videoRepresentation.dimensions().width
            var videoHeight = videoRepresentation.dimensions().height
            var aspectRatio = videoWidth / videoHeight
            
            // check for Portrait mode or Landscape mode
            if(videoHeight > videoWidth) {
                
                println("portrait mode")
                var resizeHeight = round((UIScreen.mainScreen().bounds.width) / aspectRatio)
                currentVideoHeight = resizeHeight
                currentVideoWidth = UIScreen.mainScreen().bounds.width
                
            } else if(videoHeight < videoWidth) {
                
                println("Landscape mode")
                var resizeWidth = round((UIScreen.mainScreen().bounds.width) * aspectRatio)
                currentVideoHeight = UIScreen.mainScreen().bounds.width
                currentVideoWidth = resizeWidth
                
            } else {
                
                println("equal width and height")
                currentVideoHeight = UIScreen.mainScreen().bounds.width
                currentVideoWidth = UIScreen.mainScreen().bounds.width
            }
            
            currentMovieURL = path
            playMovie(path)

        }
        else{
            
            self.mediaPlayer.view.hidden = true
            
            var imgRepresentation = currentAsset.defaultRepresentation()
            
//            var managedCGImage = convertCfTypeToCGImage(currentAsset.thumbnail())
//            var imgThumbnail: UIImage = UIImage(CGImage: managedCGImage)!
//            var imgThumbnail:UIImage = UIImage(
            
            self.photoPreview.image = UIImage(CGImage: currentAsset.defaultRepresentation().fullScreenImage().takeUnretainedValue())
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var location = scrollView.panGestureRecognizer.locationInView(self)
        var locationInParent = scrollView.panGestureRecognizer.locationInView(self.superview)
        if(location.y < 0 && self.frame.size.height < self.originalFrame.size.height + 0.6 * self.frame.size.width){
            println("isAtBoundary: \(self.isAtBoundary) 1:\(self.frame.origin.y),2:\(self.originalFrame.origin.y)")
                self.frame = CGRectMake(self.frame.origin.x,self.frame.origin.y + location.y, self.mediaCollection.frame.size.width,self.frame.size.height - location.y)
            
            if(self.frame.origin.y < self.originalFrame.origin.y){
                if(!self.isAtBoundary){
                    self.lastContentOffset = scrollView.contentOffset
                    self.isAtBoundary = true
                }
                else{
                    self.mediaCollection.contentOffset = self.lastContentOffset
                }
            }
        }
        
        if(self.lastScrollViewY > scrollView.contentOffset.y){
            self.isUp = false
        }
        else{
            self.isUp = true
        }
        
        self.lastScrollViewY = scrollView.contentOffset.y
    }
    
    func expandAlbumView(){
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.delegate?.PTVideoDidExpend()
            self.frame = CGRectMake(self.frame.origin.x, self.originalFrame.origin.y - self.frame.size.width * 0.6, self.mediaCollection.frame.size.width, self.originalFrame.size.height + self.frame.size.width * 0.6)
            println("expand frame: \(self.mediaCollection.frame)")
        }) { (b) -> Void in
            
        }
    }
    func closeAlbumView(){
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.frame = CGRectMake(self.originalFrame.origin.x, self.originalFrame.origin.y, self.frame.size.width, self.frame.size.height)
            println("closeAlbumView frame: \(self.mediaCollection.frame)")
            }) { (b) -> Void in
                self.frame = self.originalFrame
        }
    }
    func finalizeAlbumView(){
        println("isBoundary : \(self.isAtBoundary) , isUp: \(self.isUp)")
        if(self.isAtBoundary){
            if(self.isUp){
                expandAlbumView()
            }
            self.isAtBoundary = false
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        println("scrollViewDidEndDragging");
        self.finalizeAlbumView()
    }
    
//    func singleTapGestureCaptured(gesture:UITapGestureRecognizer){
//        var touchPoint = gesture.locationInView(self.mediaCollection)
//        println("pt: \(touchPoint)")
//    }
    
}