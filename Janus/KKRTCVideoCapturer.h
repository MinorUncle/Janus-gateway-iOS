//
//  KKRTCVideoCapturer.h
//  GJJanus
//
//  Created by melot on 2018/4/19.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebRTC/RTCVideoCapturer.h>
#import "GJLiveDefine.h"
#import "GJImagePictureOverlay.h"

#import "GJImageView.h"
@interface KKRTCVideoCapturer : RTCVideoCapturer
@property (nonatomic, assign) GJPixelFormat           pixelFormat;
@property (nonatomic, assign) NSUInteger                     frameRate;
@property (nonatomic, readonly) GJImageView *           previewView;

@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;
@property (nonatomic, assign) UIInterfaceOrientation  outputOrientation;
@property (nonatomic, assign) CGSize                  destSize;
@property (nonatomic, assign) BOOL                    horizontallyMirror;
@property (nonatomic, assign) BOOL                    streamMirror;
@property (nonatomic, assign) BOOL                    previewMirror;

#pragma mark 美颜参数设置，请先调用prepareVideoEffect
/**
 美白：0-100
 */
@property(assign,nonatomic)NSInteger skinBright;

/**
 磨皮：0-100
 */
@property(assign,nonatomic)NSInteger skinSoften;

/**
 皮肤红润：0--100
 */
@property(nonatomic,assign)NSInteger skinRuddy;

/**
 瘦脸：0--100
 */
@property(nonatomic,assign)NSInteger faceSlender;     //

/**
 大眼：0--100
 */
@property(nonatomic,assign)NSInteger eyeEnlargement;  //


- (BOOL)startPreview ;
- (void)stopPreview ;

- (BOOL)startProduce ;
- (void)stopProduce ;

- (BOOL)startStickerWithImages:(NSArray<GJOverlayAttribute *> *)images fps:(NSInteger)fps updateBlock:(OverlaysUpdate)updateBlock;
- (void)chanceSticker;

-(BOOL)prepareVideoEffectWithBaseData:(NSString *)baseDataPath;
-(void)chanceVideoEffect;


/**
 配置虹软贴图

 @param path 模板路径，如果为nil则表示去除贴图
 @return return value description
 */
-(BOOL)updateFaceStickerWithTemplatePath:(NSString*)path;
@end
