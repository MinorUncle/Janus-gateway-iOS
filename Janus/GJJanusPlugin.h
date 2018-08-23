//
//  GJJanusPlugin.h
//  GJJanusDemo
//
//  Created by melot on 2018/3/14.
//

#import <Foundation/Foundation.h>
#import "GJJanus.h"

@class GJJanusPlugin;
@protocol GJJanusPluginDelegate<NSObject>
@end

@interface Jesp:NSObject

@end
typedef void(^AttchResult)(NSError* error);
typedef void(^DetachedResult)(void);

@interface GJJanusPlugin : NSObject<GJJanusPluginHandleProtocol>
@property(nonatomic,copy)NSString* opaqueId;
@property(nonatomic,copy)NSString* pluginName;
@property(nonatomic,retain)NSNumber* handleId;
@property(nonatomic,weak)id<GJJanusPluginDelegate> delegate;
@property(nonatomic,strong,readonly)GJJanus* janus;
@property(nonatomic,retain)NSMutableDictionary* transactions;
@property(nonatomic,assign)BOOL attached;


-(instancetype)initWithJanus:(GJJanus*)janus delegate:(id<GJJanusPluginDelegate>)delegate;
-(BOOL)attachWithCallback:(AttchResult)resultCallback;
-(void)detachWithCallback:(DetachedResult)resultCallback;

-(void)sendMessage:(NSDictionary*)msg callback:(PluginRequestCallback)resultCallback;
-(void)sendMessage:(NSDictionary*)msg jsep:(NSDictionary*)jsep callback:(PluginRequestCallback)callback;
-(void)sendTrickleCandidate:(NSDictionary*)candidate;
@end
