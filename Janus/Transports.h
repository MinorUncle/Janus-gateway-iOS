//
//  Transports.h
//  GJJanusDemo
//
//  Created by melot on 2018/3/14.
//

#import <Foundation/Foundation.h>

@class Transport;

@protocol TransportDelegate <NSObject>
-(void)transportDidOpen:(Transport*)transport;
-(void)transportDidClose:(Transport*)transport;
-(void)transport:(Transport*)transport didReceiveMessage:(NSDictionary*)msg;
-(void)transport:(Transport*)transport didFailWithError:(NSError*)error;

@end
typedef enum : NSUInteger {
    kTransportStatusOpening,
    kTransportStatusOpened,
    kTransportStatusCloseing,
    kTransportStatusClosed,
} TransportStatus;

@interface Transport : NSObject
@property(nonatomic,weak)id<TransportDelegate> delegate;
@property(nonatomic,readonly)TransportStatus status;

@property(nonatomic,retain)NSURL* serverUrl;
- (instancetype)initWithServer:(NSURL*)url;
-(BOOL)start;
-(void)stop;
-(void)sendMessage:(NSDictionary*)msg;
@end
