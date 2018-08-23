//
//  GJJanusVideoRoom.h
//  GJJanusDemo
//
//  Created by melot on 2018/3/14.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "GJJanusMediaConstraints.h"
#import "GJOverlayAttribute.h"
#import "KKRTCDefine.h"

@class UIView;
@class GJJanusVideoRoom;

@protocol GJJanusVideoRoomDelegate<NSObject>

-(void)GJJanusVideoRoom:(GJJanusVideoRoom*)plugin didJoinRoomWithID:(NSUInteger)clientID;
-(void)GJJanusVideoRoomDidLeaveRoom:(GJJanusVideoRoom*)plugin;
-(void)GJJanusVideoRoom:(GJJanusVideoRoom*)plugin newRemoteJoinWithID:(NSUInteger)clientID;
-(void)GJJanusVideoRoom:(GJJanusVideoRoom*)plugin remoteLeaveWithID:(NSUInteger)clientID;

-(void)GJJanusVideoRoom:(GJJanusVideoRoom*)plugin firstFrameDecodeWithSize:(CGSize)size uid:(NSUInteger)uid;
-(void)GJJanusVideoRoom:(GJJanusVideoRoom*)plugin renderSizeChangeWithSize:(CGSize)size uid:(NSUInteger)uid;

-(void)GJJanusVideoRoom:(GJJanusVideoRoom*)plugin fatalErrorWithID:(KKRTCErrorCode)errorCode;
-(void)GJJanusVideoRoom:(GJJanusVideoRoom*)plugin netBrokenWithID:(KKRTCNetBrokenReason)reason;

@end
typedef void(^CompleteCallback)(BOOL isSuccess, NSError* error);




@interface GJJanusView: UIView
@end;
@interface GJJanusVideoRoom : NSObject
@property(nonatomic,weak)id<GJJanusVideoRoomDelegate> delegate;
@property(nonatomic,strong)GJJanusPushlishMediaConstraints* localConfig;


@property (nonatomic,assign         ) BOOL                   videoMute;

#pragma mark video
@property (nonatomic,assign         ) AVCaptureDevicePosition       cameraPosition;

@property (nonatomic,assign         ) BOOL       previewMirror;//预览镜像，不镜像流

@property (nonatomic,assign         ) BOOL       streamMirror;//流镜像，不影响预览

@property (nonatomic,assign         ) BOOL       cameraMirror;//相机镜像，影响预览和流

@property (nonatomic,assign         ) UIInterfaceOrientation outOrientation;

@property (nonatomic,strong,readonly) UIView                 * _Nonnull previewView;


//只读，根据pushConfig中的push size自动选择最优.outOrientation 和 pushsize会改变改值，
@property (nonatomic,assign,readonly) CGSize                 captureSize;

#pragma mark audio
@property (nonatomic,assign         ) BOOL                   audioMute;

@property (nonatomic,assign         ) BOOL                   measurementMode;

@property (nonatomic,assign         ) BOOL                   enableAec;//default NO

@property (nonatomic,assign         ) float                  inputVolume;

@property (nonatomic,assign         ) float                  mixVolume;

@property (nonatomic,assign         ) float                  masterOutVolume;

@property (nonatomic,assign,setter=enableReverb:) BOOL       reverb;

@property (nonatomic,assign,setter=enableAudioInEarMonitoring:) BOOL audioInEarMonitoring;

@property (nonatomic,assign         ) BOOL                   mixFileNeedToStream;


#pragma mark 美颜参数设置，请先开启任意一种美颜
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



//-(instancetype)initWithServer:(NSURL *)server delegate:(id<GJJanusVideoRoomDelegate>)delegate;
+(instancetype)shareInstanceWithServer:(NSURL*)server delegate:(id<GJJanusVideoRoomDelegate>)delegate;
-(void)joinRoomWithRoomID:(NSInteger)roomID userName:(NSString*)userName completeCallback:(CompleteCallback)callback;
-(void)leaveRoom:(void(^_Nullable )(void))leaveBlock;
-(BOOL)startPrewViewWithCanvas:(KKRTCCanvas*)canvas;
-(KKRTCCanvas*)stopPrewViewWithUid:(NSUInteger)uid;

/**
 贴图，如果存在则取消已存在的
 
 @param images 需要贴的图片集合
 @param fps 贴图更新的帧率
 @param updateBlock 每次更新的回调，index表示当前更新的图片，ioFinish表示是否结束，输入输出值。
 @return 是否成功
 */
- (BOOL)startStickerWithImages:(NSArray<GJOverlayAttribute*>* _Nonnull)images fps:(NSInteger)fps updateBlock:(OverlaysUpdate _Nullable )updateBlock;

/**
 主动停止贴图。也可以通过addStickerWithImages的updateBlock，赋值ioFinish true来停止，不过该方法只能在更新的时候使用，可能会有延迟，fps越小延迟越大。
 */
- (void)chanceSticker;


#pragma mark 虹软视图效果
-(BOOL)prepareVideoEffectWithBaseData:(NSString *)baseDataPath;
-(void)chanceVideoEffect;
/**
 配置虹软贴图
 
 @param path 模板路径，如果为nil则表示去除贴图
 @return return value description
 */
-(BOOL)updateFaceStickerWithTemplatePath:(NSString*)path;
@end
