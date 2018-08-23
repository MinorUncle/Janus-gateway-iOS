//
//  GJJanusHttp.m
//  GJJanus
//
//  Created by melot on 2018/3/15.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "GJJanusHttp.h"
#import <AFNetworking.h>

@implementation GJJanusHttp
-(void)sendMessage:(NSDictionary *)msg{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //申明返回的结果是json类型
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 60.f;
    [manager GET:self.serverUrl.absoluteString parameters:msg progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary* dic = responseObject;
        [self.delegate transport:self didReceiveMessage:dic];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.delegate transport:self didFailWithError:error];
    }];
}

@end
