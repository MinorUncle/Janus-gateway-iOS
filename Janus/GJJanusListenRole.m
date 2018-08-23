//
//  GJJanusListenRole.m
//  GJJanus
//
//  Created by melot on 2018/4/3.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "GJJanusListenRole.h"
#import "GJJanusMediaConstraints+private.h"

@interface GJJanusListenRole()
{
    RTCVideoTrack* _videoTrack;
    CGSize  _renderSize;
}
@end
@implementation GJJanusListenRole
@dynamic delegate;
+(instancetype)roleWithDic:(NSDictionary*)dic janus:(GJJanus*)janus delegate:(id<GJJanusRoleDelegate>)delegate{
    GJJanusListenRole* publish = [[GJJanusListenRole alloc]initWithJanus:janus delegate:delegate];
    publish.ID = [dic[@"id"] integerValue];
    publish.display = dic[@"display"];
    publish.audioCode = dic[@"audio_codec"];
    publish.videoCode = dic[@"video_codec"];
    return publish;
}

-(instancetype)initWithJanus:(GJJanus *)janus delegate:(id<GJJanusPluginDelegate>)delegate{
    self = [super initWithJanus:janus delegate:delegate];
    if (self) {
        self.pType = kPublishTypeLister;
        self.mediaConstraints = [[GJJanusMediaConstraints alloc]init];
        self.mediaConstraints.audioEnable = YES;
        self.mediaConstraints.videoEnalbe = YES;
    }
    return self;
}

-(void)joinRoomWithRoomID:(NSInteger)roomID userName:(NSString *)userName block:(RoleJoinRoomCallback)block{
    NSAssert(roomID > 0,@"参数有误");
    if (self.attached == NO && self.status == kJanusRoleStatusDetached) {
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
    
    [super joinRoomWithRoomID:roomID userName:userName block:block];
}

-(void)leaveRoom:(RoleLeaveRoomCallback)leaveBlock{
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
        NSAssert(0, @"not handle");
    }else if ([jsep[@"type"] isEqualToString:@"offer"]){
        sdpType = RTCSdpTypeOffer;
    }else{
        NSAssert(0, @"not handle");
    }
    RTCSessionDescription* sessionDest = [[RTCSessionDescription alloc]initWithType:sdpType sdp:jsep[@"sdp"]];
    WK_SELF;
    [self.peerConnection setRemoteDescription:sessionDest completionHandler:^(NSError * _Nullable error) {
        if (error == nil) {
            [wkSelf.peerConnection answerForConstraints:[wkSelf.mediaConstraints getAnserConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
                if (error == nil) {
                    [wkSelf.peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            assert(0);
                        }
                    }];
                    NSDictionary* jsep = @{@"type":@"answer",@"sdp":sdp.sdp};
                    [wkSelf prepareLocalJesp:jsep];
                }else{
                    assert(0);
                }
            }];
        }else{
            assert(0);
        }
    }];
}

-(void)prepareLocalJesp:(NSDictionary *)jsep{
    NSDictionary* msg = @{@"request": @"start", @"room": @(self.roomID)};
    [self.janus sendMessage:msg jsep:jsep handleId:self.handleId  callback:^(NSDictionary *msg, NSDictionary *jsep) {
        if ([msg[@"started"] isEqualToString:@"ok"]) {
            //                            GJAssert([msg[@"room"] integerValue] == wkself.roomID,"应该是对方已经下线了，稍后会收到下线消息，忽略");
        }else{
            NSAssert(0,@"应该是对方已经下线了，稍后会收到下线消息，忽略");
        }
    }];
}

-(RTCEAGLVideoView *)renderView{
    if (_renderView == nil) {
        _renderView = [[RTCEAGLVideoView alloc] init];
        _renderView.userInteractionEnabled = NO;
        _renderView.delegate = self;
        if (_videoTrack) {
            [_videoTrack addRenderer:_renderView];
        }
    }

    return _renderView;
}

-(void)pluginHandleMessage:(NSDictionary *)msg jsep:(NSDictionary *)jsep transaction:(NSString*)transaction{
    NSLog(@"not handle:%@",msg);

    if (jsep != nil) {
        assert(0);
    }
}

-(void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream{
    runAsyncInMainDispatch(^{
        if(stream.videoTracks.count > 0){
            RTCVideoTrack* videoTrack = stream.videoTracks[0];
            [videoTrack addRenderer:self.renderView];
            _videoTrack = videoTrack;
        }
    });
}

-(void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream{
    _videoTrack = nil;
    _renderSize = CGSizeZero;
}

-(void)videoView:(id<RTCVideoRenderer>)videoView didChangeVideoSize:(CGSize)size{
    if (CGSizeEqualToSize(_renderSize, CGSizeZero)) {
        _renderSize = size;
        [self.delegate janusListenRole:self firstRenderWithSize:size];
    }else{
        [self.delegate janusListenRole:self renderSizeChangeWithSize:size];
    }
}

-(void)dealloc{
//    GJLOG(GNULL, GJ_LOGINFO,"%s",self.description.UTF8String);
}
@end

