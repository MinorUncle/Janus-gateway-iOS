//
//  JanusVideoRoom.m
//  JanusDemo
//
//  Created by melot on 2018/3/14.
//

#import "JanusVideoRoom.h"
#import "Tools.h"
#import "JanusListenRole.h"
#import "JanusPublishRole.h"
#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/WebRTC.h>
#import <WebRTC/RTCCameraVideoCapturer.h>
#import <WebRTC/RTCCameraPreviewView.h>
#import <WebRTC/RTCLogging.h>
#import <UIKit/UIView.h>
#import "KKRTCDefine+private.h"
#import "KKRTCVideoCapturer.h"
typedef enum VideoRoomMessageId{
    kVideoRoomJoin = 10 ,
}VideoRoomMessageId;

#define GOOGLE_ICE @"stun:stun.l.google.com:19302"



static NSString* vidoeRoomMessage[] = {
    @"join",
};


@implementation JanusView
+(Class)layerClass{
    return [RTCCameraPreviewView class];
}
@end

@interface AutoLock:NSObject
{
    NSRecursiveLock* _lock;
}
@end
@implementation AutoLock
- (instancetype)initWithLock:(NSRecursiveLock*)lock
{
    self = [super init];
    if (self) {
        _lock = lock;
        [_lock lock];
    }
    return self;
}
-(void)dealloc{
    [_lock unlock];
}
+(instancetype) local:(NSRecursiveLock*)lock{
    return [[AutoLock alloc]initWithLock:lock];
}
@end

#define AUTO_LOCK(lock) AutoLock* a=[AutoLock local:lock];

@interface JanusVideoRoom()<JanusDelegate,JanusRoleDelegate,RTCEAGLVideoViewDelegate>
{
    NSInteger _userID;
    NSString* _userName;

    NSString* _myID;
    NSString* _myPvtId;
    NSInteger _roomID;
    
    RTCCameraVideoCapturer* _hideCamera;
    NSRecursiveLock*    _lock;//
    
}
@property(nonatomic,strong)NSMutableDictionary<NSNumber*,JanusListenRole*>* remotes;
@property(nonatomic,strong,readonly)Janus* janus;
@property(nonatomic,retain)JanusPublishRole* publlisher;
@property(nonatomic,retain)RTCVideoTrack* localVideoTrack;
@property(nonatomic,readonly)RTCCameraVideoCapturer* localCamera;
@property(nonatomic,retain)NSMutableDictionary<NSNumber*,KKRTCCanvas*>* canvas;
@property(nonatomic,retain)NSMutableDictionary<NSNumber*,RTCMediaStream*>* rtcStreams;

//@property(nonatomic, stromg)
@end

@implementation JanusVideoRoom


- (AVCaptureDevice *)findDeviceForPosition:(AVCaptureDevicePosition)position {
    NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
    for (AVCaptureDevice *device in captureDevices) {
        if (device.position == position) {
            return device;
        }
    }
    return captureDevices[0];
}

- (AVCaptureDeviceFormat *)selectFormatForDevice:(AVCaptureDevice *)device {
    NSArray<AVCaptureDeviceFormat *> *formats =
    [RTCCameraVideoCapturer supportedFormatsForDevice:device];
    int targetWidth = 360;
    int targetHeight = 640;
    AVCaptureDeviceFormat *selectedFormat = nil;
    int currentDiff = INT_MAX;
    
    for (AVCaptureDeviceFormat *format in formats) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        int diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height);
        if (diff < currentDiff) {
            selectedFormat = format;
            currentDiff = diff;
        }
    }
    
    NSAssert(selectedFormat != nil, @"No suitable capture format found.");
    return selectedFormat;
}


-(instancetype)initWithServer:(NSURL *)server delegate:(id<JanusVideoRoomDelegate>)delegate{
    if (self = [super init]) {
        _delegate = delegate;
        _janus = [[Janus alloc]initWithServer:server delegate:self];
        _remotes = [NSMutableDictionary dictionaryWithCapacity:1];
        _canvas = [NSMutableDictionary dictionaryWithCapacity:2];
        _publlisher = [[JanusPublishRole alloc]initWithDelegate:self];
        _cameraPosition = AVCaptureDevicePositionFront;
        _rtcStreams = [NSMutableDictionary dictionaryWithCapacity:2];
        _lock = [[NSRecursiveLock alloc]init];
        RTCSetMinDebugLogLevel(RTCLoggingSeverityInfo);
    }
    return self;
}

-(void)joinRoomWithRoomID:(NSInteger)roomID userName:(NSString*)userName completeCallback:(CompleteCallback)callback{
    AUTO_LOCK(_lock)
    _roomID = roomID;
    _userName = userName;
    [_publlisher joinRoomWithRoomID:roomID userName:userName];
    AVCaptureDevice* device = [self findDeviceForPosition:AVCaptureDevicePositionBack];
    [self.localCamera startCaptureWithDevice:device format:[self selectFormatForDevice:device] fps:15];
//    [self.localCamera startProduce];
}

-(void)levaeRoom{
    AUTO_LOCK(_lock)
    [_publlisher leaveRoom];
    
}

-(void)setLocalConfig:(JanusPushlishMediaConstraints *)localConfig{
    AUTO_LOCK(_lock)
    [_publlisher setMediaConstraints:localConfig];
    CGSize pushSize = self.localConfig.pushSize;
    GJPixelFormat format = {.mType = GJPixelType_YpCbCr8BiPlanar_Full,.mWidth = pushSize.width,.mHeight = pushSize.height};
//    self.localCamera.pixelFormat = format;
//    self.localCamera.frameRate = self.localConfig.fps;
}

-(JanusPushlishMediaConstraints *)localConfig{
    AUTO_LOCK(_lock)
    return _publlisher.mediaConstraints;
}

-(KKRTCVideoCapturer *)localCamera{
    AUTO_LOCK(_lock)
    if (_hideCamera == nil) {
        _hideCamera = [[RTCCameraVideoCapturer alloc]initWithDelegate:_publlisher.videoSource]; //[[KKRTCVideoCapturer alloc]initWithDelegate:_publlisher.videoSource];
        if (self.localConfig) {
            CGSize pushSize = self.localConfig.pushSize;
            GJPixelFormat format = {GJPixelType_YpCbCr8Planar_Full,pushSize.width,pushSize.height};
//            _hideCamera.pixelFormat = format;
//            _hideCamera.frameRate = self.localConfig.fps;
        }
    }
    return _hideCamera;
}
-(BOOL)startPrewViewWithCanvas:(KKRTCCanvas*)canvas{
    AUTO_LOCK(_lock)
    NSAssert(canvas != nil && canvas.view != nil, @"param error");
    BOOL needAdd = NO;
    if (canvas.uid == 0 || canvas.uid == _publlisher.ID) {
//        [self.localCamera startPreview];
        needAdd = YES;
//        canvas.renderView = (UIView<RTCVideoRenderer>*)self.localCamera.previewView;
        _canvas[@(canvas.uid)] = canvas;
        self.previewView.frame = canvas.view.bounds;
        [canvas.view addSubview:self.previewView];
    }else{
        RTCMediaStream* stream = _rtcStreams[@(canvas.uid)];
        if (stream && stream.videoTracks.count) {
            RTCVideoTrack* videoTrack = stream.videoTracks[0];
            needAdd = YES;
#if defined(RTC_SUPPORTS_METAL)
            RTCMTLVideoView* remoteVideoView = [[RTCMTLVideoView alloc] initWithFrame:CGRectZero];
#else
            RTCEAGLVideoView *remoteView = [[RTCEAGLVideoView alloc] initWithFrame:canvas.view.bounds];
            remoteView.delegate = self;
            canvas.renderView = remoteView;
            [canvas.view addSubview:remoteView];
            _canvas[@(canvas.uid)] = canvas;
            [videoTrack addRenderer:remoteView];
#endif
        }
    }
    return needAdd;
}
-(void)stopPrewViewWithUid:(NSUInteger)uid{
    AUTO_LOCK(_lock)
    if (uid == 0 || uid == _publlisher.ID) {
//        [self.localCamera stopPreview];
//        [self.localCamera stopProduce];
    }else{
        KKRTCCanvas* canvas = _canvas[@(uid)];
        RTCMediaStream* stream = _rtcStreams[@(uid)];
        RTCVideoTrack* videoTrack = stream.videoTracks.firstObject;
        if (videoTrack) {
            [videoTrack removeRenderer:canvas.renderView];
        }
        [_canvas removeObjectForKey:@(uid)];
    }
}


-(UIView *)previewView{
    AUTO_LOCK(_lock)
    return nil;
}

//-(void)startPrewView{
//    if (_localCamera) {
//        AVCaptureDevice *device = [self findDeviceForPosition:_cameraPosition];
//        AVCaptureDeviceFormat *format = [self selectFormatForDevice:device];
//        int fps = [self selectFpsForFormat:format];
//
//        [_localCamera startCaptureWithDevice:device format:format fps:fps];
//    }
//}
//-(void)stopPrewView{
//    [_localCamera stopCapture];
//}



- (void)startListenRemote:(JanusListenRole*)remoteRole{
    AUTO_LOCK(_lock)
    _remotes[@(remoteRole.ID)] = remoteRole;
    [remoteRole attachToJanus:self.janus];
}

-(void)stopListernRemote:(JanusListenRole*)remoteRole{
    AUTO_LOCK(_lock)
    [_remotes removeObjectForKey:@(remoteRole.ID)];
}


-(void)janus:(Janus *)janus createComplete:(NSError *)error{
    AUTO_LOCK(_lock)
    if (error == nil) {
        [_publlisher attachToJanus:janus];
    }else{
        assert(0);
    }
}

-(void)janusDestory:(Janus*)janus{
    NSLog(@"janus:%p,destory",janus);
}

-(void)janusPlugin:(JanusPlugin *)plugin attachWithResult:(NSError *)error{
    AUTO_LOCK(_lock)
    if (error == nil) {
        if ([_publlisher.handleId isEqualToNumber:plugin.handleId]) {
            [self.delegate JanusVideoRoomDidCreateSession:self];
        }else{
            for (JanusRole* remote in _remotes.allValues) {
                if ([remote.handleId isEqualToNumber:plugin.handleId]) {
                    [remote joinRoomWithRoomID:_roomID userName:nil];
                }
            }
        }
    }else{
        assert(0);
    }
}

-(void)JanusRole:(JanusRole *)role joinRoomWithResult:(NSError *)error{
    if (role.ID == _publlisher.ID) {
        [self.delegate JanusVideoRoom:self didJoinRoomWithID:role.ID];
    }else{
        
    }
}

-(void)JanusRole:(JanusRole*)role leaveRoomWithResult:(NSError*)error{
    if (role.ID == _publlisher.ID) {
        [self.janus destorySession];
    }
}

- (void)JanusRole:(JanusRole *)role didJoinRemoteRole:(JanusListenRole *)remoteRole { 
    for (JanusRole* remote in _remotes.allValues) {
        if (remote.ID == remoteRole.ID) {
            return;
        }
    }
    [self.delegate JanusVideoRoom:self newRemoteJoinWithID:role.ID];
    [self startListenRemote:remoteRole];
}

- (void)JanusRole:(JanusRole *)role didLeaveRemoteRoleWithUid:(NSUInteger)uid{
    JanusListenRole* leaveRole = _remotes[@(uid)];
    if (leaveRole) {
        [_remotes removeObjectForKey:@(uid)];
        [self.delegate JanusVideoRoom:self remoteLeaveWithID:uid];
    }
}

-(void)JanusRole:(JanusRole *)role didReceiveStream:(RTCMediaStream *)stream{
    _rtcStreams[@(role.ID)] = stream;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (stream.videoTracks.count && [self.delegate respondsToSelector:@selector(JanusVideoRoom:addVideoTrackWithUid:)]) {
            [self.delegate JanusVideoRoom:self addVideoTrackWithUid:role.ID];
        }
        
        if (stream.audioTracks.count && [self.delegate respondsToSelector:@selector(JanusVideoRoom:addAudioTrackWithUid:)]) {
            [self.delegate JanusVideoRoom:self addAudioTrackWithUid:role.ID];
        }
    });

    
}

-(void)JanusRole:(JanusRole*)role didRemoveStream:(RTCMediaStream*)stream{
    [_rtcStreams removeObjectForKey:@(role.ID)];
    if (stream.videoTracks.count && [self.delegate respondsToSelector:@selector(JanusVideoRoom:delVideoTrackWithUid:)]) {
        [self.delegate JanusVideoRoom:self delVideoTrackWithUid:role.ID];
    }
    
    if (stream.audioTracks.count && [self.delegate respondsToSelector:@selector(JanusVideoRoom:delAudioTrackWithUid:)]) {
        [self.delegate JanusVideoRoom:self delAudioTrackWithUid:role.ID];
    }
}


#pragma mark janus delegate
-(void)pluginWebrtcState:(BOOL)on{

}

-(void)pluginMediaState:(BOOL)on type:(NSString *)media{
    
}

-(void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size{
    for (KKRTCCanvas* canvas in _canvas.allValues) {
        if (canvas.renderView == videoView) {
            if ([self.delegate respondsToSelector:@selector(JanusVideoRoom:renderSizeChangeWithSize:view:uid:)]) {
                [self.delegate JanusVideoRoom:self renderSizeChangeWithSize:size view:canvas.view uid:canvas.uid];
            }
            break;
        }
    }
}

-(void)dealloc{
//    [self.janus destorySession];
}

@end

