//
//  GJJanusListenRole.h
//  GJJanus
//
//  Created by melot on 2018/4/3.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "GJJanusRole.h"
#import <WebRTC/RTCEAGLVideoView.h>
@class GJJanusListenRole;
@protocol GJJanusListenRoleDelegate<GJJanusRoleDelegate>
-(void)janusListenRole:(GJJanusListenRole*)role firstRenderWithSize:(CGSize)size;
-(void)janusListenRole:(GJJanusListenRole*)role renderSizeChangeWithSize:(CGSize)size;

@end
@interface GJJanusListenRole : GJJanusRole<RTCEAGLVideoViewDelegate>
@property(nonatomic,retain)RTCEAGLVideoView* renderView;
@property(nonatomic,weak)id<GJJanusListenRoleDelegate> delegate;
@end
