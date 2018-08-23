//
//  GJJanusPlugin.m
//  GJJanusDemo
//
//  Created by melot on 2018/3/14.
//

#import "GJJanusPlugin.h"
#import "Tools.h"
@interface GJJanusPlugin()
{
}
@end
@implementation GJJanusPlugin

- (instancetype)initWithJanus:(GJJanus*)janus delegate:(id<GJJanusPluginDelegate>) delegate{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _transactions = [NSMutableDictionary dictionaryWithCapacity:4];
        _janus = janus;
    }
    return self;
}


-(void)sendMessage:(NSDictionary*)msg jsep:(NSDictionary*)jsep callback:(PluginRequestCallback)callback{
    [self.janus sendMessage:msg jsep:jsep handleId:self.handleId callback:callback];
}

-(void)sendMessage:(NSDictionary*)msg callback:(PluginRequestCallback)callback{
    return [self sendMessage:msg jsep:nil callback:callback];
}

-(void)sendTrickleCandidate:(NSDictionary*)candidate{
    [self.janus sendTrickleCandidate:candidate handleId:self.handleId];
}

-(BOOL)attachWithCallback:(AttchResult)resultCallback{
    WK_SELF;
    [_janus attachPlugin:self callback:^(NSNumber *handleID, NSError *error) {
        wkSelf.handleId = handleID;
        wkSelf.attached = (error == nil);
        resultCallback(error);
    }];
    return YES;
}

-(void)detachWithCallback:(DetachedResult)resultCallback{
    WK_SELF;
    [_janus detachPlugin:self callback:^(void) {
        wkSelf.attached = NO;//attached要在回调里面修改
        if (resultCallback) {
            resultCallback();
        }
    }];
}

-(void)pluginDetached{
    _attached = NO;
}

- (void)pluginHandleMessage:(NSDictionary *)msg jsep:(NSDictionary *)jsep transaction:(NSString *)transaction {
    assert(0);
}

- (void)pluginMediaState:(BOOL)on type:(NSString *)media {
    
}

- (void)pluginWebrtcState:(BOOL)on {
    
}

- (void)pluginHangup{
    
}
@end
