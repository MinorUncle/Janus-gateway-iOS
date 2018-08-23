//
//  KKRTCVideoCapturer.m
//  GJJanus
//
//  Created by melot on 2018/4/19.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "KKRTCVideoCapturer.h"

//#import "GJLog.h"
#import "GJImageFilters.h"

#import <stdlib.h>
typedef enum { //filter深度
    kFilterCamera = 0,
    kFilterFaceSticker,
    kFilterBeauty,
    kFilterTrack,
    kFilterSticker,
} GJFilterDeep;


BOOL getCaptureInfoWithSize(CGSize size, CGSize *captureSize, NSString **sessionPreset) {
    *captureSize   = CGSizeZero;
    *sessionPreset = nil;
    return YES;
}

CGSize getCaptureSizeWithSize(CGSize size) {
    CGSize captureSize;
    if (size.width <= 352 && size.height <= 288) {
        captureSize = CGSizeMake(352, 288);
    } else if (size.width <= 640 && size.height <= 480) {
        captureSize = CGSizeMake(640, 480);
    } else if (size.width <= 1280 && size.height <= 720) {
        captureSize = CGSizeMake(1280, 720);
    } else if (size.width <= 1920 && size.height <= 1080) {
        captureSize = CGSizeMake(1920, 1080);
    } else {
        captureSize = CGSizeMake(3840, 2160);
    }
    return captureSize;
}

static NSString *getCapturePresetWithSize(CGSize size) {
    NSString *capturePreset;
    if (size.width <= 353 && size.height <= 289) {
        capturePreset = AVCaptureSessionPreset352x288;
    } else if (size.width <= 641 && size.height <= 481) {
        capturePreset = AVCaptureSessionPreset640x480;
    } else if (size.width <= 1281 && size.height <= 721) {
        capturePreset = AVCaptureSessionPreset1280x720;
    } else {
        capturePreset = AVCaptureSessionPreset1920x1080;
    }
    return capturePreset;
}

NSString *getSessionPresetWithSizeType(GJCaptureSizeType sizeType) {
    NSString *preset = nil;
    switch (sizeType) {
        case kCaptureSize352_288:
            preset = AVCaptureSessionPreset352x288;
            break;
        case kCaptureSize640_480:
            preset = AVCaptureSessionPreset640x480;
            break;
        case kCaptureSize1280_720:
            preset = AVCaptureSessionPreset1280x720;
            break;
        case kCaptureSize1920_1080:
            preset = AVCaptureSessionPreset1920x1080;
            break;
        default:
            preset = AVCaptureSessionPreset640x480;
            break;
    }
    return preset;
}

AVCaptureDevicePosition getPositionWithCameraPosition(GJCameraPosition cameraPosition) {
    AVCaptureDevicePosition position = AVCaptureDevicePositionUnspecified;
    switch (cameraPosition) {
        case GJCameraPositionFront:
            position = AVCaptureDevicePositionBack;
            break;
        case GJCameraPositionBack:
            position = AVCaptureDevicePositionBack;
            break;
        default:
            position = AVCaptureDevicePositionUnspecified;
            break;
    }
    return position;
}

@interface KKRTCVideoCapturer (){
}
@property (nonatomic, strong) GPUImageOutput<GJCameraProtocal>*    camera;
@property (nonatomic, strong) GPUImageCropFilter *    cropFilter;
@property (nonatomic, strong) GPUImageBeautifyFilter *beautifyFilter;
@property (nonatomic, strong) GPUImageFilter *        videoSender;
@property (nonatomic, strong) id<GJImageARScene>      scene;
@property (nonatomic, strong) UIView*                 captureView;
@property (nonatomic, assign) GRational               dropStep;
@property (nonatomic, assign) long                  captureCount;
@property (nonatomic, assign) long                  dropCount;
@property (nonatomic, strong) GJImagePictureOverlay * sticker;
@property (nonatomic, strong) GJImageTrackImage *     trackImage;
@property (nonatomic, assign) GJCaptureType           captureType;

@property (nonatomic, strong) ARCSoftFaceHandle *     faceHandle;
@property (nonatomic, strong) ARCSoftFaceSticker *    faceSticker;
@end
@implementation KKRTCVideoCapturer
@synthesize previewView = _previewView;


-(instancetype)initWithDelegate:(id<RTCVideoCapturerDelegate>)delegate{
    self = [super initWithDelegate:delegate];
    if (self) {
        
        _frameRate         = 15;
        _cameraPosition    = AVCaptureDevicePositionFront;
        _outputOrientation = UIInterfaceOrientationPortrait;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
    }
    return self;
}

-(void)receiveNotification:(NSNotification* )notic{
    if ([notic.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
        self.previewView.disable = YES;
    }else if ([notic.name isEqualToString:UIApplicationWillEnterForegroundNotification]) {
        self.previewView.disable = NO;
    }
}


-(void)setSkinRuddy:(NSInteger)skinRuddy{
    _faceHandle.skinRuddy = skinRuddy;
}
-(NSInteger)skinRuddy{
    return _faceHandle.skinRuddy;
}

-(void)setSkinSoften:(NSInteger)skinSoften{
    _faceHandle.skinSoftn = skinSoften;
}
-(NSInteger)skinSoften{
    return _faceHandle.skinSoftn;
}

-(void)setSkinBright:(NSInteger)skinBright{
    _faceHandle.skinBright = skinBright;
}
-(NSInteger)skinBright{
    return _faceHandle.skinBright;
}

-(void)setEyeEnlargement:(NSInteger)eyeEnlargement{
    _faceHandle.eyesEnlargement = eyeEnlargement;
}
-(NSInteger)eyeEnlargement{
    return _faceHandle.eyesEnlargement;
}

-(void)setFaceSlender:(NSInteger)faceSlender{
    _faceHandle.faceSlender = faceSlender;
}
-(NSInteger)faceSlender{
    return _faceHandle.faceSlender;
}

-(void)setPixelFormat:(GJPixelFormat)pixelFormat{
    _pixelFormat = pixelFormat;
    self.destSize = CGSizeMake((CGFloat) pixelFormat.mWidth, (CGFloat) pixelFormat.mHeight);
}

-(void)setScene:(id<GJImageARScene>)scene{
    _captureView = nil;
    _scene = scene;
}

-(void)setCaptureView:(UIView *)captureView{
    _scene = nil;
    _captureView = captureView;
}

-(void)setCaptureType:(GJCaptureType)captureType{
    if(_camera != nil){
        NSLog(@"setCaptureType 无效，请先停止预览和推流");
    }
    _captureType = captureType;
}

- (void)dealloc {
    if (_sticker) {
        [_sticker stop];
    }
    if (_trackImage) {
        [_trackImage stop];
    }
    if (_camera) {
        [_camera stopCameraCapture];
        [self deleteCamera];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    GJLOG(GNULL, GJ_LOGDEBUG, "%s",self.description.UTF8String);
}

-(void)deleteCamera{
    if ([_camera isKindOfClass:[GJPaintingCamera class]]) {
        [_camera removeObserver:self forKeyPath:@"captureSize"];
    }
    _camera = nil;
}
- (GPUImageOutput<GJCameraProtocal>*)camera {
    @synchronized (self) {
        if (_camera == nil) {
            
            CGSize size = _destSize;
            
            switch (_captureType) {
                case kGJCaptureTypeCamera:
                {
                    if (_outputOrientation == UIInterfaceOrientationPortrait ||
                        _outputOrientation == UIInterfaceOrientationPortraitUpsideDown) {
                        size.height += size.width;
                        size.width  = size.height - size.width;
                        size.height = size.height - size.width;
                    }
                    NSString *preset               = getCapturePresetWithSize(size);
                    _camera                        = [[GPUImageVideoCamera alloc] initWithSessionPreset:preset cameraPosition:_cameraPosition];
                }
                    break;
                case kGJCaptureTypeView:{
                    NSAssert(_captureView != nil, @"请先设置直播的视图");
                    _camera = [[GJImageUICapture alloc]initWithView:_captureView];
                    break;
                }
                case kGJCaptureTypePaint:{
                    _camera = [[GJPaintingCamera alloc]init];
                    [_camera addObserver:self forKeyPath:@"captureSize" options:NSKeyValueObservingOptionNew context:nil];
                    break;
                }
                case kGJCaptureTypeAR:{
                    NSAssert(_scene != nil, @"请先设置ARScene");
                    _camera = [[GJImageARCapture alloc]initWithScene:_scene captureSize:size];
                    break;
                }
                default:
                    break;
            }
            if (_scene != nil) {
                //            [self.previewView addSubview:_scene.scene];
            }else if(_captureView != nil){
            }else{
                
                //        [self.beautifyFilter addTarget:self.cropFilter];
            }
            
            self.frameRate          = _frameRate;
            self.outputOrientation  = _outputOrientation;
            self.horizontallyMirror = _horizontallyMirror;
            self.cameraPosition     = _cameraPosition;
            GPUImageOutput *sonFilter = [self getSonFilterWithDeep:kFilterCamera];
            if (sonFilter) {
                [_camera addTarget:(id<GPUImageInput>)sonFilter];
            }
            [self updateCropSize];
        }
    }
    return _camera;
}

-(void)deleteShowImage{
    [_previewView removeObserver:self forKeyPath:@"frame"];
    _previewView = nil;
}
- (GJImageView *)previewView {
    if (_previewView == nil) {
        @synchronized(self) {
            if (_previewView == nil) {
                if (_captureType != kGJCaptureTypePaint) {
                    _previewView = [[GJImageView alloc] init];
                }else{
                    _previewView = ((GJPaintingCamera*)self.camera).paintingView;
                }
                [_previewView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
                if (_previewMirror) {
                    [self setPreviewMirror:_previewMirror];
                }
            }
        }
    }
    return _previewView;
}


- (GPUImageBeautifyFilter *)beautifyFilter {
    if (_beautifyFilter == nil) {
        _beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    }
    return _beautifyFilter;
}

/**
 获取deep对应的filter，如果不存在则获取父filter,则递归继续向上，直到获取到为止
 
 @param deep deep放回获取到的层次
 @return return value description
 */
- (GPUImageOutput *)getParentFilterWithDeep:(GJFilterDeep)deep {
    GPUImageOutput *outFiter = nil;
    switch (deep) {
        case kFilterSticker:
            if(_trackImage){
                outFiter = _trackImage;
                break;
            }
        case kFilterTrack:
            if (_beautifyFilter) {
                outFiter = _beautifyFilter;
                break;
            }
        case kFilterBeauty:
            if (_faceSticker) {
                outFiter = _faceSticker;
                break;
            }
        case kFilterFaceSticker:
            outFiter = self.camera;
            break;
        default:
            NSAssert(0, @"错误");
            break;
    }
    return outFiter;
}

- (GPUImageOutput *)getFilterWithDeep:(GJFilterDeep)deep {
    GPUImageOutput *outFiter = nil;
    switch (deep) {
        case kFilterSticker:
            outFiter = _sticker;
            break;
        case kFilterTrack:
            outFiter = _trackImage;
            break;
        case kFilterBeauty:
            outFiter = _beautifyFilter;
            break;
        case kFilterFaceSticker:
            outFiter = _faceSticker;
            break;
        case kFilterCamera:
            NSAssert(_camera != nil, @"需要优化");
            outFiter = _camera;
            break;
        default:
            NSAssert(0, @"错误");
            break;
    }
    return outFiter;
}

//一直获取子滤镜，直到获取到为止
- (GPUImageOutput *)getSonFilterWithDeep:(GJFilterDeep)deep {
    GPUImageOutput *outFiter = nil;
    switch (deep) {
        case kFilterCamera:
            if (_faceSticker) {
                outFiter = _faceSticker;
                break;
            }
        case kFilterFaceSticker:
            if (_beautifyFilter) {
                outFiter = _beautifyFilter;
                break;
            }
        case kFilterBeauty:
            if (_trackImage) {
                outFiter    = _trackImage;
                break;
            }
        case kFilterTrack:
            if (_sticker) {
                outFiter    = _sticker;
                break;
            }
            break;//可能为空
        default:
            NSAssert(0, @"错误");
            break;
    }
    return outFiter;
}
- (void)removeFilterWithdeep:(GJFilterDeep)deep {
    GPUImageOutput *deleteFilter = [self getFilterWithDeep:deep];
    if (deleteFilter) {
        if (deep > 0) {
            GPUImageOutput *parentFilter = [self getParentFilterWithDeep:deep];
            if (parentFilter) {
                for (id<GPUImageInput> input in deleteFilter.targets) {
                    [parentFilter addTarget:input];
                }
                [parentFilter removeTarget:(id<GPUImageInput>) deleteFilter];
                [deleteFilter removeAllTargets];
            }
        }else{
            [_camera removeAllTargets];
        }
        
    }
}
- (void)addFilter:(GPUImageFilter *)filter deep:(GJFilterDeep)deep {
    GPUImageOutput *parentFilter = [self getParentFilterWithDeep:deep];
    if (parentFilter) {
        for (id<GPUImageInput> input in parentFilter.targets) {
            [filter addTarget:input];
        }
        [parentFilter removeAllTargets];
        [parentFilter addTarget:filter];
    }else{
        [[self getSonFilterWithDeep:deep] addTarget:filter];
    }
}

- (BOOL)startStickerWithImages:(NSArray<GJOverlayAttribute *> *)images fps:(NSInteger)fps updateBlock:(OverlaysUpdate)updateBlock {
    
    if (_camera != nil) {
        runAsynchronouslyOnVideoProcessingQueue(^{
            if (_sticker) {
                [self chanceSticker];
            }
            GJImagePictureOverlay *newSticker = [[GJImagePictureOverlay alloc] init];
            [self addFilter:newSticker deep:kFilterSticker];
            self.sticker = newSticker;
            if (updateBlock) {
                [newSticker startOverlaysWithImages:images fps:fps updateBlock:^(NSInteger index, GJOverlayAttribute * _Nonnull ioAttr, BOOL * _Nonnull ioFinish) {
                    updateBlock(index,ioAttr, ioFinish);
                }];
                
            } else {
                [newSticker startOverlaysWithImages:images fps:fps updateBlock:nil];
            }
        });
        return YES;
    }else{
        return NO;
    }
    
}
- (void)chanceSticker {
    //使用同步线程，防止chance后还会有回调
    runSynchronouslyOnVideoProcessingQueue(^{
        if (self.sticker == nil) { return; }
        [self removeFilterWithdeep:kFilterSticker];
        [self.sticker stop];
        self.sticker = nil;
    });
}

- (BOOL)startTrackingImageWithImages:(NSArray<GJOverlayAttribute*>*)images{
    if (_camera == nil) {
        return NO;
    }
    
    runAsynchronouslyOnVideoProcessingQueue(^{
        if (_trackImage) {
            [self stopTracking];
        }
        GJImageTrackImage *newTrack = [[GJImageTrackImage alloc] init];
        [self addFilter:newTrack deep:kFilterTrack];
        self.trackImage = newTrack;
        [newTrack startOverlaysWithImages:images fps:-1 updateBlock:nil];
        
    });
    return YES;
}

- (void)stopTracking{
    [self.trackImage stop];
    runSynchronouslyOnVideoProcessingQueue(^{
        if (self.trackImage == nil) { return; }
        [self removeFilterWithdeep:kFilterTrack];
        self.trackImage = nil;
    });
}


-(BOOL)prepareVideoEffectWithBaseData:(NSString *)baseDataPath{
    //创建camera不要放在videoprocess线程
    if (_faceHandle) {
        return YES;
    }
    _faceHandle = [[ARCSoftFaceHandle alloc]initWithDataPath:baseDataPath];
    self.camera.delegate = _faceHandle;
    _faceSticker = [[ARCSoftFaceSticker alloc]init];
    _faceSticker.faceStatus = _faceHandle.faceStatus;
    _faceSticker.faceInformation = _faceHandle.faceInformation;
    runAsynchronouslyOnVideoProcessingQueue(^{
        [self addFilter:_faceSticker deep:kFilterFaceSticker];
    });
    return YES;
}
/**
 取消视频处理
 */
-(void)chanceVideoEffect{
    self.camera.delegate = nil;
    _faceHandle = nil;
    runSynchronouslyOnVideoProcessingQueue(^{
        [self removeFilterWithdeep:kFilterFaceSticker];
    });
}

-(BOOL)updateFaceStickerWithTemplatePath:(NSString*)path{
    _faceHandle.forceFaceDetect = (path != nil);
    return [_faceSticker updateTemplatePath:path];
}

- (GPUImageCropFilter *)cropFilter {
    if (_cropFilter == nil) {
        _cropFilter = [[GPUImageCropFilter alloc] init];
        if (_streamMirror) {
            [self setStreamMirror:_streamMirror];
        }
    }
    return _cropFilter;
}

/**
 根据原图片大小，限制在previewView的比例之内，再缩放到targetSize，保证获得的图片一定全部限制在显示视图的中间上，
 
 @param originSize 原图片大小
 @param targetSize 目标图片大小
 @return 裁剪的比例
 */
-(CGRect) getCropRectWithSourceSize:(CGSize) originSize target:(CGSize)targetSize {
    CGSize sourceSize = originSize;
    CGSize previewSize = _previewView.bounds.size;
    CGRect region =CGRectZero;
    
    if (_previewView && _previewView.superview != nil) {
        switch (_previewView.contentMode) {
            case UIViewContentModeScaleAspectFill://显示在显示视图内
            {
                float scaleX =  sourceSize.width / previewSize.width;
                float scaleY =  sourceSize.height / previewSize.height;
                if (scaleX <= scaleY) {
                    float scale = scaleX;
                    CGSize scaleSize = CGSizeMake(previewSize.width * scale, previewSize.height * scale);
                    region.origin.x = 0;
                    region.origin.y = (sourceSize.height - scaleSize.height)/2;
                    sourceSize.height -= region.origin.y*2;
                }else{
                    float scale = scaleY;
                    CGSize scaleSize = CGSizeMake(previewSize.width * scale, previewSize.height * scale);
                    region.origin.x = (sourceSize.width - scaleSize.width)/2;
                    region.origin.y = 0;
                    sourceSize.width -= region.origin.x*2;
                }
            }
                break;
                
            default:
                break;
        }
    }
    
    
    float scaleX =  sourceSize.width / targetSize.width;
    float scaleY =  sourceSize.height / targetSize.height;
    if (scaleX <= scaleY) {
        float scale = scaleX;
        CGSize scaleSize = CGSizeMake(targetSize.width * scale, targetSize.height * scale);
        region.origin.y += (sourceSize.height - scaleSize.height)/2;
    }else{
        float scale = scaleY;
        CGSize scaleSize = CGSizeMake(targetSize.width * scale, targetSize.height * scale);
        region.origin.x += (sourceSize.width - scaleSize.width)/2;
    }
    if (region.origin.y < 0) {
        if (region.origin.y > -0.0001) {
            region.origin.y = 0;
        }
    }
    if (region.origin.x < 0) {
        if (region.origin.x > -0.0001) {
            region.origin.x = 0;
        }
    }
    region.origin.x /= originSize.width;
    region.origin.y /= originSize.height;
    region.size.width = 1-2*region.origin.x;
    region.size.height = 1-2*region.origin.y;
    
    //    //裁剪，
    //    CGSize targetSize = sourceSize;
    //    float  scaleX     = targetSize.width / destSize.width;
    //    float  scaleY     = targetSize.height / destSize.height;
    //    CGRect region     = CGRectZero;
    //    if (scaleX <= scaleY) {
    //        float  scale       = scaleX;
    //        CGSize scaleSize   = CGSizeMake(destSize.width * scale, destSize.height * scale);
    //        region.origin.x    = 0;
    //        region.size.width  = 1.0;
    //        region.origin.y    = (targetSize.height - scaleSize.height) * 0.5 / targetSize.height;
    //        region.size.height = 1 - 2 * region.origin.y;
    //    } else {
    //        float  scale       = scaleY;
    //        CGSize scaleSize   = CGSizeMake(destSize.width * scale, destSize.height * scale);
    //        region.origin.y    = 0;
    //        region.size.height = 1.0;
    //        region.origin.x    = (targetSize.width - scaleSize.width) * 0.5 / targetSize.width;
    //        region.size.width  = 1 - 2 * region.origin.x;
    //    }
    
    return region;
}

- (BOOL)startProduce {
    __weak KKRTCVideoCapturer *wkSelf = self;
    _dropCount = 0;
    _captureCount = 0;
    runSynchronouslyOnVideoProcessingQueue(^{
        GPUImageOutput *parentFilter = _sticker;
        if (parentFilter == nil) {
            parentFilter = [self getParentFilterWithDeep:kFilterSticker];
        }
        [parentFilter addTarget:self.cropFilter];
        self.cropFilter.frameProcessingCompletionBlock = ^(GPUImageOutput *imageOutput, CMTime time) {
            
//            [[imageOutput framebufferForOutput] lockForReading];
//            GLubyte * rawImagePixels = (GLubyte *)CVPixelBufferGetBaseAddress([imageOutput framebufferForOutput].pixelBuffer);
//            [[imageOutput framebufferForOutput] unlockAfterReading];
//            NSLog(@"%s",rawImagePixels);
            
            CVPixelBufferRef pixel_buffer = [imageOutput framebufferForOutput].newPixelBufferFromFramebufferContents;
//            R_GJPixelFrame *frame                                   = (R_GJPixelFrame *) GJRetainBufferPoolGetData(wkSelf.bufferPool);
//            R_BufferWrite(&frame->retain, (GUInt8*)&pixel_buffer, sizeof(CVPixelBufferRef));
//            frame->height                                           = (GInt32) wkSelf.destSize.height;
//            frame->width                                            = (GInt32) wkSelf.destSize.width;
//            frame->pts = GTimeMake(time.value, time.timescale);

            if (wkSelf.captureCount++ % wkSelf.dropStep.den >= wkSelf.dropStep.num) {
                RTCVideoFrame* frame = [[RTCVideoFrame alloc]initWithPixelBuffer:pixel_buffer rotation:RTCVideoRotation_0 timeStampNs:time.value*1000000000/time.timescale];
                [wkSelf.delegate capturer:wkSelf didCaptureVideoFrame:frame];
            }else{
                wkSelf.dropCount ++;
            }
            CVBufferRelease(pixel_buffer);
        };
        [self updateCropSize];
    });
    if (![self.camera isRunning]) {
        [self.camera startCameraCapture];
    }
    return YES;
}

- (void)stopProduce {
    //主要重复stop导致新创建camera;
    if (_cropFilter.frameProcessingCompletionBlock == nil) {
        return;
    }
    NSAssert(_camera != nil, @"camera管理待优化");

    GPUImageOutput *parentFilter = _sticker;
    if (parentFilter == nil) {
        parentFilter = [self getParentFilterWithDeep:kFilterSticker];
    }
    if (![parentFilter.targets containsObject:_previewView]) {
        [_camera stopCameraCapture];
//        [self deleteCamera];
        if (_trackImage) {
            [self stopTracking];
        }
    }
    runAsynchronouslyOnVideoProcessingQueue(^{
        [parentFilter removeTarget:_cropFilter];
        _cropFilter.frameProcessingCompletionBlock = nil;
    });
}

- (void)setDestSize:(CGSize)destSize {
    _destSize = destSize;
    if (_camera) {
        [self updateCropSize];
    }
}

- (void)updateCropSize {
    runSynchronouslyOnVideoProcessingQueue(^{
        if(_camera == nil)return ;
        CGSize size = _destSize;
        CGSize capture = self.camera.captureSize;
        if (capture.height < 2 || capture.width < 2) {
            return;
        }
        if (capture.height - size.height > 0.001 ||
            size.height - capture.height > 0.001 ||
            capture.width - size.width > 0.001 ||
            size.width - capture.width > 0.001) {
            if (![self.camera isKindOfClass:[GJPaintingCamera class]]) {
                self.camera.captureSize = size;
            }
            capture = self.camera.captureSize;
        }
        
        CGRect region              = [self getCropRectWithSourceSize:capture target:_destSize];
        self.cropFilter.cropRegion = region;
        [_cropFilter forceProcessingAtSize:_destSize];
    });
}

- (void)setOutputOrientation:(UIInterfaceOrientation)outputOrientation {
    _outputOrientation             = outputOrientation;
    if (_camera) {
        self.camera.outputImageOrientation = outputOrientation;
        [self updateCropSize];
    }
}

- (void)setHorizontallyMirror:(BOOL)horizontallyMirror {
    _horizontallyMirror                            = horizontallyMirror;
    if (_camera) {
        self.camera.horizontallyMirrorRearFacingCamera = self.camera.horizontallyMirrorFrontFacingCamera = _horizontallyMirror;
    }
}

- (void)setPreviewMirror:(BOOL)previewMirror{
    _previewMirror                            = previewMirror;
    if (_previewView) {
        [_previewView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    }
}

-(void)setStreamMirror:(BOOL)streamMirror{
    _streamMirror = streamMirror;
    if (_cropFilter) {
        [_cropFilter setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    }
}

- (void)setFrameRate:(NSUInteger)frameRate {
    _frameRate        = frameRate;
    if (_camera) {
        self.camera.frameRate = (int)frameRate;
    }
}

- (void)setCameraPosition:(AVCaptureDevicePosition)cameraPosition {
    _cameraPosition = cameraPosition;
    if (_camera && self.camera.cameraPosition != _cameraPosition) {
        [_camera rotateCamera];
    }
}

- (BOOL)startPreview {
    if (![self.camera isRunning]) {
        [self.camera startCameraCapture];
    }
    runSynchronouslyOnVideoProcessingQueue(^{
        
        GPUImageOutput *parentFilter = _sticker;
        if (parentFilter == nil) {
            parentFilter = [self getParentFilterWithDeep:kFilterSticker];
        }
        [parentFilter addTarget:self.previewView];
        
    });
    return YES;
}
- (void)stopPreview {
    if (_previewView == nil) {
        return;
    }
    NSAssert(_camera != nil, @"camera管理待优化");

    if (_cropFilter.frameProcessingCompletionBlock == nil && [_camera isRunning]) {
        [_camera stopCameraCapture];
//        [self deleteCamera];
        if (_trackImage) {
            [self stopTracking];
        }
    }
    runAsynchronouslyOnVideoProcessingQueue(^{
        GPUImageOutput *parentFilter = _sticker;
        if (parentFilter == nil) {
            parentFilter = [self getParentFilterWithDeep:kFilterSticker];
        }
        
        [parentFilter removeTarget:_previewView];
        [self deleteShowImage];
    });
}


- (UIView *)getPreviewView {
    return self.previewView;
}

-(UIImage*)getFreshDisplayImage{
    return [((GJImageView*)self.previewView) captureFreshImage];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == _previewView) {
        if ([keyPath isEqualToString:@"frame"]) {
            [self updateCropSize];
        }
    }else if (object == _camera){
        if ([keyPath isEqualToString:@"captureSize"]) {
            [self updateCropSize];
        }
    }
}

@end
