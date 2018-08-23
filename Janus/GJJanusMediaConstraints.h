//
//  GJJanusMediaConstraints.h
//  GJJanus
//
//  Created by melot on 2018/4/3.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


@interface GJJanusMediaConstraints:NSObject
@property(nonatomic,assign)BOOL videoEnalbe;
@property(nonatomic,assign)BOOL audioEnable;
//可选
@property(nonatomic,copy)NSString* videoCode;
@property(nonatomic,assign)BOOL shouldUseLevelControl;


@end

@interface GJJanusPushlishMediaConstraints:GJJanusMediaConstraints
@property(nonatomic,assign)CGSize pushSize;
@property(nonatomic,assign)NSInteger fps;
@property(nonatomic,assign)NSInteger frequency;
@property(nonatomic,assign)NSInteger videoBitrate;
@property(nonatomic,assign)NSInteger audioBitrate;
//可选
@property(nonatomic,assign)BOOL shouldUseLevelControl;


@end

