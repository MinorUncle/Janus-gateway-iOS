//
//  KKRTCDefine.h
//  GJJanus
//
//  Created by melot on 2018/4/16.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIView;

#define GATEWAY_P2P
#define WK_SELF __weak typeof(self) wkSelf = self;

typedef NS_ENUM(NSInteger, KKRTCVideoRoomErrorCode) {
    kKKRTCVideoRoomErrorCode_Unknown_Error = 499,
    kKKRTCVideoRoomErrorCode_No_Message = 421,
    kKKRTCVideoRoomErrorCode_Invalid_Json = 422,
    kKKRTCVideoRoomErrorCode_Invalid_request = 423,
    kKKRTCVideoRoomErrorCode_Join_Frist = 424,
    kKKRTCVideoRoomErrorCode_Already_joined = 425,
    kKKRTCVideoRoomErrorCode_No_Such_Room = 426,
    kKKRTCVideoRoomErrorCode_Room_Exists = 427,
    kKKRTCVideoRoomErrorCode_No_Such_Feed = 428,
    kKKRTCVideoRoomErrorCode_Missing_Element = 429,
    kKKRTCVideoRoomErrorCode_Invalid_Element = 430,
    kKKRTCVideoRoomErrorCode_Invalid_Sdp_Type = 431,
    kKKRTCVideoRoomErrorCode_Publishers_Full = 432,
    kKKRTCVideoRoomErrorCode_Unauthorized = 433,
    kKKRTCVideoRoomErrorCode_Already_Published = 434,
    kKKRTCVideoRoomErrorCode_Not_Published = 435,
    kKKRTCVideoRoomErrorCode_ID_Exists = 436,
    kKKRTCVideoRoomErrorCode_Invalid_Sdp = 437,
};

typedef NS_ENUM(NSInteger, KKRTCErrorCode) {
    KKRTCError_unknow = 0,
    KKRTCError_Server_Json_Err = -1,
    KKRTCError_Server_Error = -2,

};

typedef NS_ENUM(NSInteger, KKRTCNetBrokenReason) {
    KKRTCNetBroken_unknow = 0,
    KKRTCNetBroken_websocketFail = -1,
    KKRTCNetBroken_websocketClose = -2,

};

typedef NS_ENUM(NSInteger, KKRTCMediaType) {
    
    kKKRTCMediaVideoType = 0,
    kKKRTCMediaAudioType = 1,
    kKKRTCMediaDataType = 2,
};

typedef NS_ENUM(NSUInteger, KKRTCRenderMode) {
    /**
     Hidden(1): If the video size is different than that of the display window, crops the borders of the video (if the video is bigger) or stretch the video (if the video is smaller) to fit it in the window.
     */
    KKRTC_Render_Hidden = 1,
    
    /**
     AgoraRtc_Render_Fit(2): If the video size is different than that of the display window, resizes the video proportionally to fit the window.
     */
    KKRTC_Render_Fit = 2,
    
    /**
     AgoraRtc_Render_Adaptive(3)：If both callers use the same screen orientation, i.e., both use vertical screens or both use horizontal screens, the AgoraRtc_Render_Hidden mode applies; if they use different screen orientations, i.e., one vertical and one horizontal, the AgoraRtc_Render_Fit mode applies.
     */
    KKRTC_Render_Fill = 3,
};
@interface KKRTCCanvas : NSObject
@property (strong, nonatomic) UIView* view;
@property (assign, nonatomic) KKRTCRenderMode renderMode; // the render mode of view: hidden, fit and adaptive
@property (assign, nonatomic) NSUInteger uid; // the user id of view
+ (instancetype)canvasWithUid:(NSUInteger)uid view:(UIView*)view renderMode:(KKRTCRenderMode)mode;
@end
