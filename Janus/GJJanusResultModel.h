//
//  GJJanusResultModel.h
//  GJJanus
//
//  Created by melot on 2018/4/23.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, GJJanusResultErrorCode) {
    kJanusResult_NoErr = 0,
    kJanusResult_JsonErr = -1,
    kJanusResult_FuncErr = -2,

};

@interface GJJanusResultModel:NSObject
@property(nonatomic,assign)NSInteger errorCode;
@property(nonatomic,copy)NSString* errorDesc;

-(instancetype)initWithDic:(NSDictionary*)dic;
+(instancetype)modelWithDic:(NSDictionary*)dic;
@end

//"janus": "success",
//"transaction": "UNT3q7ioAovW",
//"data": {
//"id": 8039766217379867
//}
@interface GJJanusSessionModel : GJJanusResultModel
@property(nonatomic,copy)NSString* transaction;
@property(nonatomic,copy)NSNumber* sessionID;
@end



