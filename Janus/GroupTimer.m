//
//  GroupTimer.m
//  GJJanus
//
//  Created by melot on 2018/4/18.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "GroupTimer.h"

@implementation TimerMessage
+(instancetype)messageWithDelay:(NSTimeInterval)delay userData:(id)userdata{
    TimerMessage* message = [[TimerMessage alloc]init];
    message.fireDate = [NSDate dateWithTimeIntervalSinceNow:delay];
    message.userData = userdata;
    return message;
}
@end

@interface GroupTimer()
{
    NSTimer* _timer;
}
@property(nonatomic,assign)NSMutableArray<TimerMessage*>* timeMessages;
@end
@implementation GroupTimer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timeMessages = [NSMutableArray arrayWithCapacity:10];
        _timer = [[NSTimer alloc]initWithFireDate:[NSDate distantFuture] interval:INT_MAX target:self selector:@selector(timeFire:) userInfo:nil repeats:YES];
    }
    return self;
}
-(void)start{
    if ([NSThread isMainThread]) {
        [[NSRunLoop currentRunLoop]addTimer:_timer forMode:NSDefaultRunLoopMode];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSRunLoop currentRunLoop]addTimer:_timer forMode:NSDefaultRunLoopMode];
        });
    }
}
-(void)stop{
    [_timer invalidate];
}
-(void)addMessage:(TimerMessage*)message{
    @synchronized(self){
        if (_timeMessages.count == 0) {
            [_timeMessages addObject:message];
            [_timer setFireDate:message.fireDate];
        }else{
            for (int i = (int)(_timeMessages.count) - 1; i >= -1; i--) {
                if (i > -1) {
                    if ([message.fireDate laterDate:_timeMessages[i].fireDate]) {
                        [_timeMessages insertObject:message atIndex:i+1];
                        break;
                    }
                }else{
                    [_timeMessages insertObject:message atIndex:0];
                    [_timer setFireDate:message.fireDate];
                }

            }
        }
    };
}
-(void)timeFire:(NSTimer*)timer{
    @synchronized(self){
        NSDate* now = [NSDate date];
        for (int i = 0; i<_timeMessages.count; i++) {
            if ([now laterDate:_timeMessages[i].fireDate]) {
                [self.delegate groupTimer:self fireWithMessage:_timeMessages[i]];
                [_timeMessages removeObjectAtIndex:i];
                i--;
            }else{
                [_timer setFireDate:_timeMessages[i].fireDate];
                break;
            }
        }
    }
}
@end
