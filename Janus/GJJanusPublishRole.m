//
//  GJJanusPublishRole.m
//  GJJanus
//
//  Created by melot on 2018/4/3.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "GJJanusPublishRole.h"
#import "GJJanusListenRole.h"
#import "GJJanusMediaConstraints+private.h"
#import "RTCFactory.h"
//#import "GJLog.h"
static NSString * const kARDMediaStreamId = @"ARDAMS";
static NSString * const kARDAudioTrackId = @"ARDAMSa0";
static NSString * const kARDVideoTrackId = @"ARDAMSv0";
static NSString * const kARDVideoTrackKind = @"video";
@interface GJJanusPublishRole(){
}
@end
@implementation GJJanusPublishRole
@synthesize mediaConstraints = _mediaConstraints;
@synthesize localCamera = _localCamera;
//@dynamic mediaConstraints;
+(instancetype)roleWithDic:(NSDictionary*)dic janus:(GJJanus*)janus delegate:(id<GJJanusRoleDelegate>)delegate{
    GJJanusPublishRole* publish = [[GJJanusPublishRole alloc]initWithJanus:janus delegate:delegate];
    publish.ID = [dic[@"id"] integerValue];
    publish.display = dic[@"display"];
    publish.audioCode = dic[@"audio_codec"];
    publish.videoCode = dic[@"video_codec"];
    return publish;
}

-(instancetype)initWithJanus:(GJJanus *)janus delegate:(id<GJJanusPluginDelegate>)delegate{
    self = [super initWithJanus:janus delegate:delegate];
    if (self) {
        self.pType = kPublishTypePublish;
//        if (self.janus.sessionID != 0) {
//            [self attachWithCallback:nil];
//        }
    }
    return self;
}

-(void)setMediaConstraints:(GJJanusPushlishMediaConstraints *)mediaConstraints{
    _mediaConstraints = mediaConstraints;
    
    CGSize pushSize = mediaConstraints.pushSize;
    GJPixelFormat format = {.mType = GJPixelType_YpCbCr8BiPlanar_Full,.mWidth = pushSize.width,.mHeight = pushSize.height};
    self.localCamera.pixelFormat = format;
    self.localCamera.frameRate = mediaConstraints.fps;
}

-(KKRTCVideoCapturer *)localCamera{
    if (_localCamera == nil) {
        _localCamera = [[KKRTCVideoCapturer alloc]initWithDelegate:self.videoSource];
        if (self.mediaConstraints) {
            CGSize pushSize = self.mediaConstraints.pushSize;
            GJPixelFormat format = {GJPixelType_YpCbCr8Planar_Full,pushSize.width,pushSize.height};
            _localCamera.pixelFormat = format;
            _localCamera.frameRate = self.mediaConstraints.fps;
        }
    }
    return _localCamera;
}

-(GJImageView *)renderView{
    return self.localCamera.previewView;
}

-(RTCVideoSource *)videoSource{
    if (_videoSource == nil) {
        _videoSource = [[RTCFactory shareFactory].peerConnectionFactory videoSource];
    }
    return _videoSource;
}

-(RTCAudioSource*)audioSource{
    if (_audioSource == nil) {
        _audioSource = [[RTCFactory shareFactory].peerConnectionFactory audioSourceWithConstraints:[self.mediaConstraints getAudioConstraints]];
    }
    return _audioSource;
}
- (RTCRtpSender *)createAudioSender {
    RTCAudioSource *source = self.audioSource;
    RTCAudioTrack *track = [[RTCFactory shareFactory].peerConnectionFactory audioTrackWithSource:source
                                                  trackId:kARDAudioTrackId];
    RTCRtpSender *sender = [self.peerConnection senderWithKind:kRTCMediaStreamTrackKindAudio streamId:kARDMediaStreamId];
    sender.track = track;
    return sender;
}

- (RTCRtpSender *)createVideoSender {
    RTCRtpSender *sender =
    [self.peerConnection senderWithKind:kRTCMediaStreamTrackKindVideo streamId:kARDMediaStreamId];
    RTCVideoTrack* localVideoTrack = [[RTCFactory shareFactory].peerConnectionFactory videoTrackWithSource:self.videoSource trackId:kARDVideoTrackId];
    sender.track = localVideoTrack;
    return sender;
}

-(void)startPreview{
    [self.localCamera startPreview];
}

-(void)stopPreview{
    [self.localCamera stopPreview];
}

-(void)joinRoomWithRoomID:(NSInteger)roomID userName:(NSString *)userName block:(RoleJoinRoomCallback)block{
    NSAssert(roomID > 0 && userName.length > 3,@"参数有误");
    if (self.attached == NO) {
        WK_SELF;
        [self attachWithCallback:^(NSError *error) {
            if (error == nil) {
                if (wkSelf) {
                    [wkSelf joinRoomWithRoomID:roomID userName:userName block:^(NSError *error) {
                        block(error);
                    }];
                }else{
                    block(errorWithCode(-1, @"已经释放"));
                }
            }else{
                block(error);
            }
            
        }];
        return;
    }
    
    [self.localCamera startProduce];
    WK_SELF;
    [super joinRoomWithRoomID:roomID userName:userName block:^(NSError* error){
        if (error == nil) {
            [wkSelf sendOffer];
        }
        if (block){
            block(error);
        }
    }];
    
    if (self.mediaConstraints.videoEnalbe) {
        [self createVideoSender];
    }
    if (self.mediaConstraints.audioEnable) {
        [self createAudioSender];
    }
}

-(void)leaveRoom:(RoleLeaveRoomCallback)leaveBlock{
//    [super leaveRoom:^() {
//        leaveBlock();
//    }];
    [self.localCamera stopProduce];
    [self detachWithCallback:^{
        if (leaveBlock) {
            leaveBlock();
        }
    }];
}

-(void)handleRemoteJesp:(NSDictionary *)jsep{
    RTCSdpType sdpType = RTCSdpTypeAnswer;
    if ([jsep[@"type"] isEqualToString:@"answer"]) {
        sdpType = RTCSdpTypeAnswer;
    }else if ([jsep[@"type"] isEqualToString:@"offer"]){
        sdpType = RTCSdpTypeOffer;
        NSAssert(0, @"not handle");
    }else{
        NSAssert(0, @"not handle");
    }
    RTCSessionDescription* sessionDest = [[RTCSessionDescription alloc]initWithType:sdpType sdp:jsep[@"sdp"]];
    [self.peerConnection setRemoteDescription:sessionDest completionHandler:^(NSError * _Nullable error) {
        NSAssert(error == nil,@"%@",error.localizedDescription);
    }];
}

-(void)pluginHandleMessage:(NSDictionary *)msg jsep:(NSDictionary *)jsep transaction:(NSString*)transaction{
    
    NSString* event = msg[@"videoroom"];
    if([event isEqualToString:@"event"]){
        if (msg[@"publishers"] != nil) {
            NSArray* list = msg[@"publishers"];
            for (NSDictionary* item in list) {
                GJJanusListenRole* listener = [GJJanusListenRole roleWithDic:item janus:self.janus delegate:self.delegate];
                listener.privateID = self.privateID;
                listener.opaqueId = self.opaqueId;
                [self.delegate GJJanusRole:self didJoinRemoteRole:listener];
            }
        }else if(msg[@"leaving"] != nil){
            id leave = msg[@"leaving"];
            if ([leave isKindOfClass:[NSString class]]) {
                assert(0);
            }else{
                NSInteger leaveId = [leave unsignedIntegerValue];
                [self.delegate GJJanusRole:self didLeaveRemoteRoleWithUid:leaveId];
            }
        }else if(msg[@"error"] != nil){
            NSAssert(0, @"not handle");
        }else if(msg[@"unpublished"] != nil){
            NSUInteger unpubId = [msg[@"unpublished"] unsignedIntegerValue];
            [self.delegate GJJanusRole:self remoteUnPublishedWithUid:unpubId];
        }else{
            NSAssert(0, @"not handle");
        }
    }else if([event isEqualToString:@"destroyed"]){
        NSAssert(0, @"The room has been destroyed!");
    }else if([event isEqualToString:@"slow_link"]){
    }else{
        NSAssert(0, @"not handle");
    }
}

-(void)configBitrate{
    if (self.mediaConstraints.videoBitrate > 0) {
        NSArray<RTCRtpSender *> *senders = self.peerConnection.senders;
        for (RTCRtpSender *sender in senders) {
            if (sender.track != nil) {
                if ([sender.track.kind isEqualToString:kARDVideoTrackKind]) {
                    RTCRtpParameters *parametersToModify = sender.parameters;
                    for (RTCRtpEncodingParameters *encoding in parametersToModify.encodings) {
                        encoding.maxBitrateBps = @(self.mediaConstraints.videoBitrate);
                    }
                    [sender setParameters:parametersToModify];
                }
            }
        }
    }
}

-(void)sendOffer{
    RTCMediaConstraints* constraints = [self.mediaConstraints getOfferConstraints];
    __weak GJJanusPublishRole* wkself = self;
    [self.peerConnection offerForConstraints:constraints
                           completionHandler:^(RTCSessionDescription *sdp,
                                               NSError *error) {
                               if (error == nil) {
                                   
                                   RTCSessionDescription *sdpPreferringCodec =
                                   [Tools descriptionForDescription:sdp preferredVideoCodec:[wkself.mediaConstraints videoCode]];
//                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [wkself.peerConnection setLocalDescription:sdpPreferringCodec completionHandler:^(NSError * _Nullable error) {
                                           assert(error == nil);
                                           
                                           NSDictionary* jsep = @{@"type":@"offer",@"sdp":sdpPreferringCodec.sdp};
                                           NSDictionary* msg =  @{@"request":@"configure",@"audio": wkself.audioSource != nil ? @(YES):@(NO) , @"video": wkself.videoSource != nil?@(YES):@(NO),@"bitrate":@(wkself.mediaConstraints.videoBitrate)};
                                           [wkself.janus sendMessage:msg jsep:jsep handleId:wkself.handleId callback:^(NSDictionary *msg, NSDictionary *jsep) {
                                               if ([msg[@"configured"] isEqualToString:@"ok"]) {
                                                   if (jsep) {
                                                       [wkself handleRemoteJesp:jsep];
                                                   }else{
                                                       assert(0);
                                                   }
                                               }else{
                                                   assert(0);
                                               }
                                           }];
                                       }];
                                       [wkself configBitrate];
//                                   });
                                
                               }
                           }];
}

-(void)dealloc{
    NSLog(@"delloc:%p",self);
//    GJLOG(GNULL, GJ_LOGINFO,"%s",self.description.UTF8String);
}

@end
