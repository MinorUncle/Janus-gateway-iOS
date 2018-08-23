//
//  GJJanusRole.h
//  GJJanus
//
//  Created by melot on 2018/4/3.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>
#import "GJJanusPlugin.h"
#import "GJJanusMediaConstraints.h"
#import "Tools.h"


@class GJJanusRole;
@class GJJanusListenRole;
@protocol GJJanusRoleDelegate<GJJanusPluginDelegate>
-(void)GJJanusRole:(GJJanusRole*)role joinRoomWithResult:(NSError*)error;
-(void)GJJanusRole:(GJJanusRole*)role leaveRoomWithResult:(NSError*)error;

-(void)GJJanusRole:(GJJanusRole*)role didJoinRemoteRole:(GJJanusListenRole*)remoteRole;
-(void)GJJanusRole:(GJJanusRole*)role didLeaveRemoteRoleWithUid:(NSUInteger)uid;
-(void)GJJanusRole:(GJJanusRole*)role remoteUnPublishedWithUid:(NSUInteger)uid;
-(void)GJJanusRole:(GJJanusRole*)role remoteDetachWithUid:(NSUInteger)uid;
@end

typedef enum _PublishType{
    kPublishTypeLister,
    kPublishTypePublish,
}PublishType;

typedef enum {
    kJanusRoleStatusDetached,
    kJanusRoleStatusDetaching,
    kJanusRoleStatusAttaching,
    kJanusRoleStatusAttached,
    kJanusRoleStatusJoining,
    kJanusRoleStatusJoined,
    kJanusRoleStatusLeaveing,
    kJanusRoleStatusLeaved,
}GJJanusRoleStatus;

typedef void(^RoleJoinRoomCallback)(NSError* error);
typedef void(^RoleLeaveRoomCallback)(void);

@interface GJJanusRole:GJJanusPlugin <RTCPeerConnectionDelegate>
@property(nonatomic,assign)NSUInteger ID;
@property(nonatomic,assign)NSInteger roomID;
@property(nonatomic,copy)NSNumber* privateID;
@property(nonatomic,strong)GJJanusMediaConstraints* mediaConstraints;
@property(nonatomic,weak)id<GJJanusRoleDelegate> delegate;

@property(nonatomic,copy)NSString* display;
@property(nonatomic,assign)PublishType pType;
@property(nonatomic,readonly)GJJanusRoleStatus status;

@property(nonatomic,copy)NSString* audioCode;
@property(nonatomic,copy)NSString* videoCode;

@property(nonatomic,strong)RTCPeerConnection* peerConnection;


+(instancetype)roleWithDic:(NSDictionary*)dic janus:(GJJanus*)janus delegate:(id<GJJanusRoleDelegate>)delegate;
//-(instancetype)initWithDelegate:(id<GJJanusRoleDelegate>)delegate;

-(void)joinRoomWithRoomID:(NSInteger)roomID userName:(NSString*)userName block:(RoleJoinRoomCallback)block;
-(void)leaveRoom:(RoleLeaveRoomCallback)leaveBlock;



-(void)handleRemoteJesp:(NSDictionary*)jsep;
-(void)prepareLocalJesp:(NSDictionary*)jsep;
@end


