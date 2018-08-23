//
//  GJJanus.m
//  GJJanusDemo
//
//  Created by melot on 2018/3/14.
//
/*

*/
#import "GJJanus.h"
#import "GJJanusVideoRoom.h"
#import "Tools.h"
#import "GJJanusWebSocket.h"
#import "GJJanusPlugin.h"
#import "GJJanusResultModel.h"
//#import "GJLog.h"
#import "Tools.h"
typedef enum _JanusMessageId{
    kJanusCreateSession ,
    kJanusAttach ,
    kJanusDetach ,
    kJanusDestroy,
}GJJanusMessageId;

static NSString* janus_Message[] = {
    @"create",
    @"attach",
    @"detach",
    @"destroy",
};



@interface GJJanusMessage:NSObject
@property(nonatomic,retain) NSDictionary* message;
@property(nonatomic,retain) NSNumber* handleID;
@property(nonatomic,assign) GJJanusMessageId messageType;
+(instancetype)messageWithMessage:(NSDictionary*)message messageType:(GJJanusMessageId)type handleId:(NSNumber*)handleID;
@end

@implementation GJJanusMessage

+(instancetype)messageWithMessage:(NSDictionary*)message messageType:(GJJanusMessageId)type handleId:(NSNumber*)handleID{
    GJJanusMessage* msg = [[GJJanusMessage alloc]init];
    msg.handleID = handleID;
    msg.message = message;
    msg.messageType = type;
    return msg;
}
@end

@interface GJJanus()<TransportDelegate>
{
    
    NSInteger _maxev;
    NSString* _token;
    NSString* _apisecret;
    NSInteger _retries;
    GJJanusWebSocket* _transport;
    
    NSRecursiveLock*    _lock;//

    NSMutableDictionary<NSString*,GJJanusRequestCallback>* _janusTransactions;
    
}
@property(nonatomic,retain) NSMutableDictionary<NSNumber*,id<GJJanusPluginHandleProtocol>>* pluginHandles;
@property(nonatomic,retain) NSTimer* keepAliveTimer;
@property(nonatomic,assign) NSInteger keepAliveInerval;
@property(nonatomic,retain) NSMutableArray<NSMutableDictionary*> *delayReq;;


@end
@implementation GJJanus

- (instancetype)initWithServer:(NSURL*)server delegate:(id<GJJanusDelegate>) delegate
{
    self = [super init];
    if (self) {
        _pluginHandles = [NSMutableDictionary dictionaryWithCapacity:1];
        _janusTransactions = [NSMutableDictionary dictionaryWithCapacity:2];
        _delayReq = [NSMutableArray arrayWithCapacity:1];
        _server = server;
        _delegate = delegate;
        _transport = [[GJJanusWebSocket alloc]initWithServer:server];
        _transport.delegate = self;
        _lock = [[NSRecursiveLock alloc]init];
        [_transport start];
        
        _keepAliveInerval = 30000;
    }
    return self;
}

-(void)createSession{
    AUTO_LOCK(_lock)
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithCapacity:2];
    dic[@"janus"] = janus_Message[kJanusCreateSession];
    NSString* transaction = randomString(12);
    dic[@"transaction"] = transaction;
    WK_SELF;
    GJJanusRequestCallback calllback = ^(NSDictionary* msg){
        if ([msg[@"janus"] isEqualToString:@"success"]) {

            
            NSDictionary* sessionData = msg[@"data"];
            if (sessionData != nil) {
                wkSelf.sessionID = [sessionData[@"id"] unsignedIntegerValue];
                if (wkSelf.keepAliveInerval > 0) {
                    runAsyncInMainDispatch(^{
                        wkSelf.keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:wkSelf.keepAliveInerval/1000.0 target:wkSelf selector:@selector(sessionKeepAlive:) userInfo:nil repeats:YES];
                    });
                }
                for (NSMutableDictionary* request in wkSelf.delayReq) {
                    [wkSelf sendDelayReq:request];
                }
                [wkSelf.delegate janus:wkSelf createComplete:nil];

            }else{
                [wkSelf.delegate janus:wkSelf createComplete:errorWithCode(kJanusResult_JsonErr, @"json error")];
            }
        }else{
            [wkSelf.delegate janus:wkSelf createComplete:errorWithCode(kJanusResult_FuncErr, @"janus session创建失败")];
        }
    };
    _janusTransactions[transaction] = calllback;
    [_transport sendMessage:dic];
}

-(void)destorySession{
    AUTO_LOCK(_lock)

    if (_keepAliveTimer) {
        [_keepAliveTimer invalidate];
        _keepAliveTimer = nil;
    }
    NSString* transaction = randomString(12);
    NSDictionary* r = @{ @"janus": @"destroy", @"transaction": transaction,@"session_id":@(_sessionID) };
    NSMutableDictionary* request = [NSMutableDictionary dictionaryWithDictionary:r];
    if (_token != nil) {
        request[@"token"] = _token;
    }
    if (_apisecret != nil) {
        request[@"apisecret"] = _apisecret;
    }
    WK_SELF;
    
    GJJanusRequestCallback calllback = ^(NSDictionary* msg){
        wkSelf.sessionID = 0;
        [wkSelf.delegate janusDestory:wkSelf];
    };
    _janusTransactions[transaction] = calllback;
    [_transport sendMessage:request];
}

-(void)attachPlugin:(id<GJJanusPluginHandleProtocol>)plugin callback:(AttachCallback)pluginCallback{
    //attach是第一个信息，所以如果session没有激活则等待激活再发送，先保存callback;
    AUTO_LOCK(_lock)

    NSString* transaction = randomString(12);
    while ([_janusTransactions.allKeys containsObject:transaction]) {
        transaction = randomString(12);
    }
    
    NSDictionary* r = @{ @"janus": janus_Message[kJanusAttach], @"plugin": plugin.pluginName, @"opaque_id": plugin.opaqueId, @"transaction": transaction,@"session_id":@(_sessionID) };
    NSMutableDictionary* request = [NSMutableDictionary dictionaryWithDictionary:r];
    if (_token != nil) {
        request[@"token"] = _token;
    }
    if (_apisecret != nil) {
        request[@"apisecret"] = _apisecret;
    }
    WK_SELF;
    GJJanusRequestCallback calllback = ^(NSDictionary* msg){
        if ([msg[@"janus"] isEqualToString:@"success"]) {
            NSDictionary* data = msg[@"data"];
            NSNumber* handleId;
            if (data && (handleId = data[@"id"])) {
                wkSelf.pluginHandles[handleId] = plugin;
                plugin.handleId = handleId;
                pluginCallback(handleId,nil);
            }else{
                NSAssert(0, @"not handle");
            }
        }else if([msg[@"janus"] isEqualToString:@"error"]){
            NSDictionary* error = msg[@"error"];
            pluginCallback(0,errorWithCode([error[@"code"] intValue], error[@"reason"]));
        }else{
            NSAssert(0, @"not handle");
        }
    };
    _janusTransactions[transaction] = calllback;
    
    if (_sessionID == 0) {
        [_delayReq addObject:request];
        if (_transport == nil) {
            _transport = [[GJJanusWebSocket alloc]initWithServer:_server];
            _transport.delegate = self;
            [_transport start];
        }
    }else{
        [_transport sendMessage:request];
    }
}

-(void)sendDelayReq:(NSMutableDictionary*)request{
    AUTO_LOCK(_lock)

    NSAssert(_sessionID !=0 , @"session error");
    request[@"session_id"] = @(_sessionID);
    [_transport sendMessage:request];
}

-(void)detachPlugin:(id<GJJanusPluginHandleProtocol>)plugin callback:(DetachCallback)pluginCallback{
    AUTO_LOCK(_lock)

    [self.pluginHandles removeObjectForKey:plugin.handleId];
    if (_sessionID == 0 || !plugin.attached || _transport) {
        if(pluginCallback){
            pluginCallback();
        }
        return;
    }
    
    NSString* transaction = randomString(12);
    while ([_janusTransactions.allKeys containsObject:transaction]) {
        transaction = randomString(12);
    }
    
    NSDictionary* r = @{ @"janus": janus_Message[kJanusDetach],@"handle_id":plugin.handleId, @"transaction": transaction,@"session_id":@(_sessionID) };
    NSMutableDictionary* request = [NSMutableDictionary dictionaryWithDictionary:r];
    if (_token != nil) {
        request[@"token"] = _token;
    }
    if (_apisecret != nil) {
        request[@"apisecret"] = _apisecret;
    }
    
    GJJanusRequestCallback calllback = ^(NSDictionary* msg){
        if (pluginCallback) {
            if ([msg[@"janus"] isEqualToString:@"success"]) {
                pluginCallback();
            }else if([msg[@"janus"] isEqualToString:@"error"]){
                pluginCallback();
            }else{
                NSAssert(0, @"not handle");
            }
        }
    };
    _janusTransactions[transaction] = calllback;
    [_transport sendMessage:request];
}


-(void)sendMessage:(NSDictionary*)msg handleId:(NSNumber*)handleId callback:(PluginRequestCallback)callback{
    AUTO_LOCK(_lock)

    return [self sendMessage:msg jsep:nil handleId:handleId callback:callback];
}

-(void)sendMessage:(NSDictionary*)msg jsep:(NSDictionary*)jsep handleId:(NSNumber*)handleId callback:(PluginRequestCallback)reqCallback{
    AUTO_LOCK(_lock)
    if (_sessionID == 0 || _transport == nil) {
        NSDictionary* data=@{@"error_code":@(-1),@"error":@"_sessionID 和 _transport没有初始化"};
        reqCallback(data,nil);
        return;
    }
    NSAssert(_sessionID != 0, @"unactive janus session");
    NSAssert(msg != nil, @"send nil msg");

    NSString* transaction = randomString(12);
    while ([_janusTransactions.allKeys containsObject:transaction]) {
        transaction = randomString(12);
    }

    NSDictionary* r ;
    if (jsep) {
        r = @{ @"janus": @"message", @"body": msg,@"jsep":jsep, @"transaction": transaction,@"session_id":@(_sessionID),@"handle_id":handleId};
    }else{
        r = @{ @"janus": @"message", @"body": msg, @"transaction": transaction,@"session_id":@(_sessionID),@"handle_id":handleId};
    }
    NSMutableDictionary* request = [NSMutableDictionary dictionaryWithDictionary:r];
    if (_token != nil) {
        request[@"token"] = _token;
    }
    if (_apisecret != nil) {
        request[@"apisecret"] = _apisecret;
    }
    
    GJJanusRequestCallback callback = ^(NSDictionary* msg){
        if([msg[@"janus"] isEqualToString:@"error"]){
            NSDictionary* error = msg[@"error"];
            NSDictionary* data=@{@"error_code":error[@"code"],@"error_reason":error[@"reason"]};
            reqCallback(data,nil);
        }else{
            NSDictionary* plugindata = msg[@"plugindata"];
            NSAssert(plugindata != nil, @"接受的json格式错误：%s",msg.description.UTF8String);
            
            NSDictionary* jsep = msg[@"jsep"];
            NSDictionary* data = plugindata[@"data"];
            reqCallback(data,jsep);
        }
    };
    _janusTransactions[transaction] = callback;
    [_transport sendMessage:request];
}

-(void)sendTrickleCandidate:(NSDictionary*)candidate handleId:(NSNumber*)handleId{
    AUTO_LOCK(_lock)
    if (_sessionID == 0 || _transport == nil) {
        return;
    }

    NSString* transaction = randomString(12);
    while ([_janusTransactions.allKeys containsObject:transaction]) {
        transaction = randomString(12);
    }
    
    NSDictionary* request = @{ @"janus": @"trickle", @"candidate": candidate, @"transaction": transaction,@"session_id":@(_sessionID),@"handle_id":handleId};
    [_transport sendMessage:request];
    
}

-(void)sessionKeepAlive:(NSTimer*)timer{
    AUTO_LOCK(_lock)

    if (_sessionID && _transport) {
        NSDictionary* request = @{ @"janus": @"keepalive", @"session_id": @(_sessionID), @"transaction": randomString(12) };
        [_transport sendMessage:request];
    }
}

-(void)dealloc{
    [_transport stop];
}

#pragma mark delegate
-(void)transport:(Transport *)transport didReceiveMessage:(NSDictionary *)msg{

    if([msg[@"janus"] isEqualToString:@"ack"]) {
        // Nothing happened
        NSLog(@"Got an ack on session:%@",@(_sessionID));
        return;
    }
    
    NSString* transaction = msg[@"transaction"];
    GJJanusRequestCallback callback = _janusTransactions[transaction];
    if(callback){
        [_janusTransactions removeObjectForKey:transaction];
        callback(msg);
        return;
    }
    do{
        if([msg[@"janus"] isEqualToString:@"keepalive"]) {
            // Nothing happened
            NSLog(@"Got a keepalive on session :%@", @(_sessionID));
            break;
        }else if([msg[@"janus"] isEqualToString:@"success"]) {
            // Nothing happened
            NSAssert(0, @"not handle");
            break;
        }else if([msg[@"janus"] isEqualToString:@"event"]){
            NSNumber* handleId = msg[@"sender"];
            if (handleId == nil) {
                NSLog(@"Missing handle...");
                break;
            }
            
            NSDictionary* jsep = msg[@"jsep"];
            NSDictionary* plugindata = msg[@"plugindata"];
            if (plugindata == nil) {
                NSLog(@"Missing plugindata...");
                break;
            }
            
            NSDictionary* data = plugindata[@"data"];
            assert(transaction == nil);
            id<GJJanusPluginHandleProtocol> pluginHandle = _pluginHandles[handleId];
            NSAssert(pluginHandle != nil, @"This handle:%d is not attached to this session:%d",handleId.integerValue,@(_sessionID).integerValue);
            [pluginHandle pluginHandleMessage:data jsep:jsep transaction:transaction];
            
        }else if([msg[@"janus"] isEqualToString:@"webrtcup"]){
            NSNumber* handleId = msg[@"sender"];
            if (handleId == nil) {
                NSLog(@"Missing handle...");
                break;
            }
            
            id<GJJanusPluginHandleProtocol> pluginHandle = _pluginHandles[handleId];
            if (pluginHandle == nil) {
                NSLog(@"This handle is not attached to this session");
                break;
            }
            
            [pluginHandle pluginWebrtcState:true];
            
        }else if([msg[@"janus"] isEqualToString:@"media"]){
            NSNumber* handleId = msg[@"sender"];
            if (handleId == nil) {
                NSLog(@"Missing handle...");
                break;
            }
            id<GJJanusPluginHandleProtocol> pluginHandle = _pluginHandles[handleId];
            if (pluginHandle == nil) {
                NSLog(@"This handle is not attached to this session");
                break;
            }
            KKRTCMediaType mediaType = kKKRTCMediaAudioType;
            if ([msg[@"type"] isEqualToString:@"video"]) {
                mediaType = kKKRTCMediaVideoType;
            }else if (![msg[@"type"] isEqualToString:@"audio"]){
                assert(0);
            }
            [pluginHandle pluginUpdateMediaState:[msg[@"receiving"] boolValue] type:mediaType];
        }else if([msg[@"janus"] isEqualToString:@"error"]){
            NSAssert(0, @"not handle");
            break;
        }else if([msg[@"janus"] isEqualToString:@"slowlink"]){
        }else if([msg[@"janus"] isEqualToString:@"hangup"]){
            NSNumber* handleId = msg[@"sender"];

            id<GJJanusPluginHandleProtocol> pluginHandle = _pluginHandles[handleId];
            if (pluginHandle != nil) {
                [pluginHandle pluginDTLSHangupWithReson:msg[@"reason"]];
            }
        }else if([msg[@"janus"] isEqualToString:@"detached"]){
            NSNumber* handleId = msg[@"sender"];
            id<GJJanusPluginHandleProtocol> pluginHandle = _pluginHandles[handleId];
            if (pluginHandle != nil) {
                [_pluginHandles removeObjectForKey:handleId];
                [pluginHandle pluginDetached];
            }

        }else if([msg[@"janus"] isEqualToString:@"timeout"]){
        }else{
            NSAssert(0, @"not handle");
        }
    }while(0);
}

-(void)transport:(Transport *)transport didFailWithError:(NSError *)error{
    AUTO_LOCK(_lock)

    if (_keepAliveTimer) {
        [_keepAliveTimer invalidate];
        _keepAliveTimer = nil;
    }
    _transport = nil;
    _sessionID = 0;
    NSDictionary* errDic = @{@"code":@(-1),@"reason":error.localizedDescription};
    NSDictionary* errorMsg = @{@"janus":@"error",@"error":errDic};
    for (GJJanusRequestCallback callback in _janusTransactions.allValues) {
        callback(errorMsg);
    }
    [_janusTransactions removeAllObjects];
    [_delayReq removeAllObjects];
    [self.delegate janus:self netBrokenWithID:KKRTCNetBroken_websocketFail];
}

-(void)transportDidOpen:(Transport *)transport{
    [self createSession];
}

-(void)transportDidClose:(Transport *)transport{
    AUTO_LOCK(_lock)
    if (_keepAliveTimer) {
        [_keepAliveTimer invalidate];
        _keepAliveTimer = nil;
    }
    _transport = nil;
    _sessionID = 0;
    NSDictionary* errorMsg = @{@"janus":@"error"};
    for (GJJanusRequestCallback callback in _janusTransactions.allValues) {
        callback(errorMsg);
    }
    [_janusTransactions removeAllObjects];
    [_delayReq removeAllObjects];
    [self.delegate janus:self netBrokenWithID:KKRTCNetBroken_websocketClose];
}
#pragma mark webrtc




@end
