//
//  GroupTimer.h
//  GJJanus
//
//  Created by melot on 2018/4/18.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GroupTimer;
typedef void(^GroupTimerFireCallback)(GroupTimer* timer,id userData);

@interface TimerMessage:NSObject
@property(nonatomic,retain)NSDate* fireDate;
@property(nonatomic,assign)id userData;
+(instancetype)messageWithDelay:(NSTimeInterval)delay userData:(id)userdata;

@end

@protocol GroupTimerDelegate<NSObject>
-(void)groupTimer:(GroupTimer*)timer fireWithMessage:(TimerMessage*)message;
@end

@interface GroupTimer : NSObject
@property(nonatomic,weak)id<GroupTimerDelegate> delegate;

-(void)addMessage:(TimerMessage*)message;

-(void)start;
-(void)stop;
@end
