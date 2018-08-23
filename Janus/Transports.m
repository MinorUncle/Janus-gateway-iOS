//
//  Transports.m
//  GJJanusDemo
//
//  Created by melot on 2018/3/14.
//

#import "Transports.h"

@implementation Transport
- (instancetype)initWithServer:(NSURL*)url;
{
    self = [super init];
    if (self) {
        _serverUrl = url;
    }
    return self;
}
-(void)stop{}
-(BOOL)start{return YES;};
-(void)sendMessage:(NSDictionary *)msg{};
@end
