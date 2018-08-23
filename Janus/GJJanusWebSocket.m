//
//  GJJanusWebSocket.m
//  GJJanusDemo
//
//  Created by melot on 2018/3/14.
//

#import "GJJanusWebSocket.h"
#import "SRWebSocket.h"
//#import "GJLog.h"
@interface GJJanusWebSocket()<SRWebSocketDelegate>
{
    SRWebSocket* _webSocket;
    dispatch_queue_t _webSocketQueue;
}
@end
@implementation GJJanusWebSocket
- (instancetype)initWithServer:(NSURL*)url
{
    self = [super initWithServer:url];
    if (self) {
        _webSocket = [[SRWebSocket alloc]initWithURL:url protocols:@[@"janus-protocol"]];
        _webSocketQueue = dispatch_queue_create("WebSocketQueue", DISPATCH_QUEUE_SERIAL);
        [_webSocket setDelegateDispatchQueue:_webSocketQueue];
        _webSocket.delegate = self;
    }
    return self;
}
-(BOOL)start{
    [_webSocket open];
    return YES;
}
-(void)stop{
    [_webSocket close];
}

-(TransportStatus)status{
    return (TransportStatus)_webSocket.readyState;
}
-(void)sendMessage:(NSDictionary*)message{
    
    NSLog(@"send data:%s",message.description.UTF8String);
    NSError* error;
    NSData* json = [NSJSONSerialization dataWithJSONObject:message options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        assert(0);
        return;
    }else{
        [_webSocket send:json];
    }
}


#pragma mark delegate
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    NSLog(@"receive data:%s",dic.description.UTF8String);
    if (dic) {
        [self.delegate transport:self didReceiveMessage:dic];
    }else{
        assert(0);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    [self.delegate transport:self didFailWithError:error];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    NSLog(@"webSocket didCloseWithCode:%ld reason:%s wasClean:%d",(long)code,reason.UTF8String,wasClean);
    [self.delegate transportDidClose:self];

}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload{
    NSLog(@"didReceivePong");
}

-(void)webSocketDidOpen:(SRWebSocket *)webSocket{
    [self.delegate transportDidOpen:self];
}

@end
