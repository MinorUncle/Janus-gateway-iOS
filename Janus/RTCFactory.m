//
//  RTCFactory.m
//  GJJanus
//
//  Created by melot on 2018/4/3.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "RTCFactory.h"
static RTCFactory* rtcFactory;
@interface RTCFactory()
@end
@implementation RTCFactory
@synthesize peerConnectionFactory = _peerConnectionFactory;

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    if (rtcFactory == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            rtcFactory = [super allocWithZone:zone];
        });
    }
    
    return rtcFactory;
}

+(instancetype)shareFactory{
    if (rtcFactory) {
        return rtcFactory;
    }else{
        return [[self alloc]init];
    }
}

-(RTCPeerConnectionFactory *)peerConnectionFactory{
    if (_peerConnectionFactory == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _peerConnectionFactory = [[RTCPeerConnectionFactory alloc]init];
        });
    }
    return _peerConnectionFactory;
}
@end
