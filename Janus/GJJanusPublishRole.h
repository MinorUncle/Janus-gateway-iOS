//
//  GJJanusPublishRole.h
//  GJJanus
//
//  Created by melot on 2018/4/3.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "GJJanusRole.h"
#import "GJJanusMediaConstraints.h"
#import <WebRTC/RTCCameraPreviewView.h>
#import "KKRTCVideoCapturer.h"
@class GJImageView;
@interface GJJanusPublishRole : GJJanusRole
@property(nonatomic,strong)GJJanusPushlishMediaConstraints* mediaConstraints;
@property(nonatomic,retain)GJImageView* renderView;
@property(nonatomic,readonly)KKRTCVideoCapturer* localCamera;

@property(nonatomic,strong)RTCAudioSource* audioSource;
@property(nonatomic,strong)RTCVideoSource* videoSource;

-(void)startPreview;
-(void)stopPreview;
@end
