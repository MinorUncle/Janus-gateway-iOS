//
//  GJJanus__.h
//  GJJanus++
//
//  Created by melot on 2018/3/19.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#include <iostream>
#include <libwebsockets.h>
#include <string>
#include <thread>

using namespace std;
class GJJanusPlugin;
class GJJanus {

public:
    GJJanus(string wsServer);
    GJJanus(string ip,int port);

    void createSession();
    void attachPlugin(GJJanusPlugin* plugin);
    
private:
    int janusWsRunloop(void* arg);
    void setupWS();
    thread* _wsThread;
    string _ip;
    int _port;
    lws_context *wsc;
//    -(void)sendMessage:(NSDictionary*)msg transaction:(NSString*)transaction handleId:(NSNumber*)handleId;
};
