//
//  GJJanus.h
//  GJJanusDemo
//
//  Created by melot on 2018/3/14.
//

#import <Foundation/Foundation.h>
#import "KKRTCDefine.h"
@class GJJanusPlugin;
@class GJJanus;


typedef void(^SuccessCallback)(void);
typedef void(^FauilreCallback)(NSError* error);
typedef void(^CompleteCallback)(BOOL isSuccess, NSError* error);
typedef void(^AttachCallback)(NSNumber* handleID, NSError* error);
typedef void(^DetachCallback)(void);

typedef void(^PluginRequestCallback)(NSDictionary* msg, NSDictionary* jsep);
typedef void(^GJJanusRequestCallback)(NSDictionary* msg);


@protocol GJJanusPluginHandleProtocol<NSObject>
-(void)pluginHandleMessage:(NSDictionary *)msg jsep:(NSDictionary *)jsep transaction:(NSString*)transaction;
-(void)pluginWebrtcState:(BOOL)on;
-(void)pluginDetached;
-(void)pluginUpdateMediaState:(BOOL)on type:(KKRTCMediaType)media;
-(void)pluginDTLSHangupWithReson:(NSString*)reason;

@property(nonatomic,retain)NSNumber* handleId;
@property(nonatomic,copy)NSString* pluginName;
@property(nonatomic,copy)NSString* opaqueId;
@property(nonatomic,assign)BOOL attached;


@end
@protocol GJJanusDelegate <NSObject>
//-(void)janus:(GJJanus*)janus setupWithResult:(NSError*)error;
-(void)janus:(GJJanus*)janus createComplete:(NSError*)error;
-(void)janus:(GJJanus*)janus attachPlugin:(NSNumber*)handleID result:(NSError*)error;
-(void)janusDestory:(GJJanus*)janus;
-(void)janus:(GJJanus*)janus netBrokenWithID:(KKRTCNetBrokenReason)reason;


//-(void)janus:(GJJanus*)janus receiveMessage:(NSDictionary*)msg;
@end
@interface GJJanus : NSObject
@property (weak,nonatomic) id<GJJanusDelegate> delegate;
@property(nonatomic,strong)NSURL* server;
@property(nonatomic,strong)NSURL* iceServer;
@property(nonatomic,assign)NSUInteger sessionID;

- (instancetype)initWithServer:(NSURL*)server delegate:(id<GJJanusDelegate>) delegate;

-(void)attachPlugin:(id<GJJanusPluginHandleProtocol>)plugin callback:(AttachCallback)callback;
-(void)detachPlugin:(id<GJJanusPluginHandleProtocol>)plugin callback:(DetachCallback)callback;

-(void)destorySession;

//if return no,then change transaction and retry
-(void)sendMessage:(NSDictionary*)msg handleId:(NSNumber*)handleId callback:(PluginRequestCallback)callback;
-(void)sendMessage:(NSDictionary*)msg jsep:(NSDictionary*)jsep handleId:(NSNumber*)handleId callback:(PluginRequestCallback)callback;
-(void)sendTrickleCandidate:(NSDictionary*)candidate handleId:(NSNumber*)handleId;

//-(BOOL)sendMessage:(NSDictionary*)msg transaction:(NSString*)transaction handleId:(NSNumber*)handleId;
//-(BOOL)sendMessage:(NSDictionary*)msg transaction:(NSString*)transaction jsep:(NSDictionary*)jsep handleId:(NSNumber*)handleId;
//-(BOOL)sendTrickleCandidate:(NSDictionary*)candidate transaction:(NSString*)transaction handleId:(NSNumber*)handleId;
@end
