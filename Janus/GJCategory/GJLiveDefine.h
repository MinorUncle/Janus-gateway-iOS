//
//  GJLiveDefine.h
//  GJCaptureTool
//
//  Created by mac on 17/2/23.
//  Copyright © 2017年 MinorUncle. All rights reserved.
//

#ifndef GJLiveDefine_h
#define GJLiveDefine_h
#import <CoreGraphics/CGGeometry.h>
#import <CoreVideo/CVPixelBuffer.h>
#import "GJPlatformHeader.h"
//延迟收集，只有在同一收集同时推拉流才准确，

#define NETWORK_DELAY
//#define USE_KCP

#ifdef USE_KCP
extern long kcpOnceToken;
#endif

static GBool NeedTestNetwork = GTrue;

//#define GJVIDEODECODE_TEST
typedef struct GSize {
    GFloat32 width;
    GFloat32 height;
}GSize;
typedef struct GPoint {
    GFloat32 x;
    GFloat32 y;
}GPoint;

typedef struct GCRect {
    GPoint center;
    GSize size;
}GCRect;
#define makeGCRectToCGRect(gc) ((CGRect){(gc).center.x,(gc).center.y,(gc).size.width,(gc).size.height})
#define makeCGRectToGCRect(cg) ((GCRect){(cg).origin.x,(cg).origin.y,(cg).size.width,(cg).size.height})

typedef struct GRect {
    GPoint origin;
    GSize size;
}GRect;
typedef struct GRational{
    GInt32 num; ///< numerator
    GInt32 den; ///< denominator
} GRational;
#define GSizeEqual(a,b) (((a).height - (b).height > -0.00001 && (a).height - (b).height < 0.000001 && (a).width - (b).width > -0.00001 && (a).width - (b).width < 0.000001))


typedef GHandle GView;

typedef enum _GJCaptureType{
    kGJCaptureTypeCamera,
    kGJCaptureTypeView,
    kGJCaptureTypePaint,
    kGJCaptureTypeAR,
}GJCaptureType;
typedef enum _GJCaptureSizeType
{
    kCaptureSize352_288,
    kCaptureSize640_480,
    kCaptureSize1280_720,
    kCaptureSize1920_1080,
    kCaptureSize3840_2160
}GJCaptureSizeType;
typedef enum _GJCaptureDevicePosition
{
    GJCameraPositionUnspecified         = 0,
    GJCameraPositionBack                = 1,
    GJCameraPositionFront               = 2
} GJCameraPosition;

typedef enum _GJInterfaceOrientation
{
    kGJInterfaceOrientationUnknown            ,
    kGJInterfaceOrientationPortrait           ,
    kGJInterfaceOrientationPortraitUpsideDown ,
    kGJInterfaceOrientationLandscapeLeft      ,
    kGJInterfaceOrientationLandscapeRight     ,
} GJInterfaceOrientation;

//视频流的翻转角度
typedef enum LiveStreamFlipDirection {
    kLiveStreamFlipDirection_Default = 0x1 << 0,  //恢复默认状态
    kLiveStreamFlipDirection_Horizontal = 0x1 << 1,
    kLiveStreamFlipDirection_Vertical = 0x1 << 2
}GJLiveStreamFlipDirection;

//消息类型
typedef enum _LiveInfoType{
    kLivePushUnknownInfo = 0,
    
    kLivePushCloseSuccess,
   kLivePushConnectSuccess , //推流成功，
    //推流信息
    //(GJPushStatus*)
    kLivePushUpdateStatus,
    kLivePushDecodeFristFrame,
    
    kLivePullCloseSuccess,
    kLivePullConnectSuccess , //推流成功，
    kLivePullDecodeFristFrame,
    //拉流信息
    //(GJPullStatus*)
    kLivePullUpdateStatus,
}GJLiveInfoType;

typedef enum _LiveErrorType{
    kLivePushUnknownError = 0,
    
    kLivePushConnectError,//推流失败                    info:nsstring or nil
    kLivePushWritePacketError,

    kLivePullConnectError,//拉流连接失败                    
    kLivePullReadPacketError,//
}GJLiveErrorType;


typedef enum _GJNetworkQuality{
    GJNetworkQualityExcellent=0,
    GJNetworkQualityGood,
    GJNetworkQualitybad,
    GJNetworkQualityTerrible,
}GJNetworkQuality;
typedef struct PushInfo{
    GFloat32 bitrate;//byte/s
    GFloat32 frameRate;//
    GLong  cacheTime;//in ms
    GLong  cacheCount;
}GJPushInfo;
typedef struct PullInfo{
    GFloat32 bitrate;//byte/s
    GFloat32 frameRate;//
    GLong  cacheTime;
    GLong  cacheCount;
    GTime  lastReceivePts;
}GJPullInfo;
typedef struct UnitBufferInfo{
    GFloat32 percent;//byte/s
    GLong  bufferDur;
    GLong  cachePts;
    GLong  cacheCount;
}UnitBufferInfo;

typedef struct PushSessionStatus{
    GJPushInfo videoStatus;
    GJPushInfo audioStatus;
    GJNetworkQuality netWorkQuarity;
   
}GJPushSessionStatus;
typedef struct PullSessionStatus{
    GJPullInfo videoStatus;
    GJPullInfo audioStatus;
}GJPullSessionStatus;
typedef struct _PushSessionInfo{
    GLong sendFrameCount;
    GLong dropFrameCount;
    GLong sessionDuring;
}GJPushSessionInfo;
typedef struct _VideoDynamicInfo{
    GFloat32 currentBitrate;
    GFloat32 currentFPS;
    GFloat32 sourceBitrate;
    GFloat32 sourceFPS;
}VideoDynamicInfo;
typedef enum _ConnentCloceReason{
    kConnentCloce_Active,//主动关闭
    kConnentCloce_Drop,//掉线
}GJConnentCloceReason;
typedef struct _PullSessionInfo{
    GLong pullFrameCount;
    GLong dropFrameCount;
    GLong sessionDuring;
    GLong buffingTimes;
    GLong buffingCount;
}GJPullSessionInfo;

typedef struct _PullFristFrameInfo{
    GSize size;
}GJPullFristFrameInfo;

typedef enum {
    GJPixelType_32BGRA         = kCVPixelFormatType_32BGRA          ,
    GJPixelType_YpCbCr8Planar  =kCVPixelFormatType_420YpCbCr8Planar ,                  //yyyyyyyyuuvv
    GJPixelType_YpCbCr8BiPlanar =kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange         ,      //yyyyyyyyuvuv
    GJPixelType_YpCbCr8Planar_Full=kCVPixelFormatType_420YpCbCr8PlanarFullRange ,         //yyyyyyyyuuvv
    GJPixelType_YpCbCr8BiPlanar_Full=kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ,       //yyyyyyyyuvuv
} GJPixelType;
typedef enum {
    GJAudioType_AAC,
    GJAudioType_PCM,
}GJAudioType;
typedef enum {
    GJVideoType_H264,
}GJVideoType;
typedef struct _GJAudioFormat{
    GJAudioType         mType;
    GUInt32             mSampleRate;
    GUInt32             mChannelsPerFrame;
    GUInt32             mBitsPerChannel;
    GUInt32             mFramePerPacket;
    GUInt32             mFormatFlags;
}GJAudioFormat;
typedef struct _GJAudioStreamFormat{
    GJAudioFormat         format;
    GInt32 bitrate;
}GJAudioStreamFormat;
typedef struct _GJPixelFormat{
    GJPixelType         mType;
    GUInt32             mWidth;
    GUInt32             mHeight;
}GJPixelFormat;
typedef struct _GJVideoFormat{
    GJVideoType         mType;
    GUInt32             mFps;
    GUInt32             mHeight;
    GUInt32             mWidth;
}GJVideoFormat;
typedef struct _GJVideoStreamFormat{
    GJVideoFormat         format;
    GInt32 bitrate;
}GJVideoStreamFormat;
typedef struct _GJPushConfig{
    GUInt32             mFps;
    GSize               mPushSize;
    GInt32              mVideoBitrate;//  bit/s
    
    GInt32              mAudioSampleRate;
    GInt32              mAudioChannel;
    GInt32              mAudioBitrate;
}GJPushConfig;
#endif /* GJLiveDefine_h */
