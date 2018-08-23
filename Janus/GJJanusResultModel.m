//
//  GJJanusResultModel.m
//  GJJanus
//
//  Created by melot on 2018/4/23.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "GJJanusResultModel.h"
@implementation GJJanusResultModel
+(instancetype)modelWithDic:(NSDictionary*)dic{
    return [[self alloc]initWithDic:dic];
}
-(instancetype)initWithDic:(NSDictionary *)dic{
    assert(0);
}
-(void)setErrorCode:(NSInteger)errorCode{
    NSAssert(errorCode != kJanusResult_JsonErr, @"服务器返回格式错误");
    _errorCode = errorCode;
}
@end

@implementation GJJanusSessionModel
- (instancetype)initWithDic:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        if ([dic[@"janus"] isEqualToString:@"success"]) {
            NSDictionary* sessionData = dic[@"data"];
            if (sessionData != nil) {
                self.transaction = dic[@"transaction"];
                self.sessionID = sessionData[@"id"];
            }else{
                self.errorCode = kJanusResult_JsonErr;
            }

        }else{
            self.errorCode = kJanusResult_FuncErr;
            self.errorDesc = @"创建失败";
        }
    }
    return self;
}

@end
