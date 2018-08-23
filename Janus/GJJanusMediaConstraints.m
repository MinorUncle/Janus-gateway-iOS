//
//  GJJanusMediaConstraints.m
//  GJJanus
//
//  Created by melot on 2018/4/3.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "GJJanusMediaConstraints.h"
#import "GJJanusMediaConstraints+private.h"


@implementation GJJanusMediaConstraints
- (instancetype)init
{
    self = [super init];
    if (self) {
        _videoEnalbe = YES;
        _audioEnable = YES;
        _videoCode = @"H264";
    }
    return self;
}
-(RTCMediaConstraints*)getOfferConstraints{
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio" : _videoEnalbe?@"true":@"false",
                                           @"OfferToReceiveVideo" : _audioEnable?@"true":@"false",
                                           };
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
    return constraints;
}
-(RTCMediaConstraints*)getAudioConstraints{
//    NSString *valueLevelControl = _shouldUseLevelControl ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse;
//    NSDictionary *mandatoryConstraints = @{ kRTCMediaConstraintsLevelControl : valueLevelControl };
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
    return constraints;
}

-(RTCMediaConstraints*)getVideoConstraints{
    return nil;
}
-(RTCMediaConstraints*)getAnserConstraints{
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio" : _videoEnalbe?@"true":@"false",
                                           @"OfferToReceiveVideo" : _audioEnable?@"true":@"false",
                                           };
    return [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
}
-(RTCMediaConstraints*)getPeerConnectionConstraints{
    NSDictionary *optionalConstraints = @{ @"DtlsSrtpKeyAgreement" : @"true" };
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
     optionalConstraints:optionalConstraints];
    return constraints;
}
@end

@implementation GJJanusPushlishMediaConstraints

@end
