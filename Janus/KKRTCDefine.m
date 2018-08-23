//
//  KKRTCDefine.m
//  GJJanus
//
//  Created by melot on 2018/4/16.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "KKRTCDefine.h"
#import "KKRTCDefine+private.h"

@implementation KKRTCCanvas
+ (instancetype)canvasWithUid:(NSUInteger)uid view:(UIView*)view renderMode:(KKRTCRenderMode)mode
{
    KKRTCCanvas* canvas = [[KKRTCCanvas alloc]init];
    canvas.uid = uid;
    canvas.view = view;
    canvas.renderMode = mode;
    return canvas;
}


@end
