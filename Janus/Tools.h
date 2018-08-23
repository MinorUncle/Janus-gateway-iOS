//
//  Tools.h
//  GJJanusDemo
//
//  Created by melot on 2018/3/14.
//

#import <Foundation/Foundation.h>
@class RTCSessionDescription;

NSString* randomString(NSInteger len);
static inline NSString* messageIdToString(uint16_t x){
    return [NSString stringWithFormat:@"%016d",(uint16_t)x];
}
static inline uint16_t stringToMessageId(NSString* x){
    return (uint16_t)(x.intValue);
}

static inline void runAsyncInMainDispatch(void(^ block)(void) ){
    if ([NSThread isMainThread]) {
        block();
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

NSError* errorWithCode(NSInteger code,NSString* tip);


@interface Tools : NSObject
+ (RTCSessionDescription *)
descriptionForDescription:(RTCSessionDescription *)description
preferredVideoCodec:(NSString *)codec;
@end


@interface AutoLock:NSObject
{
    NSRecursiveLock* _lock;
}
+(instancetype) local:(NSRecursiveLock*)lock;
@end

#define AUTO_LOCK(lock) AutoLock* a=[AutoLock local:lock];a=a;
