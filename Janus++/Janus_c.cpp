//
//  GJJanus__.m
//  GJJanus++
//
//  Created by melot on 2018/3/19.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "GJJanus_c.hpp"

static int janus_websockets_callback(
                                     struct lws *wsi,
                                     enum lws_callback_reasons reason,
                                     void *user, void *in, size_t len);
static struct lws_protocols ws_protocols[] = {
    { "janus-protocol", janus_websockets_callback, sizeof(GJJanus), 0 },
    { NULL, NULL, 0 }
};

//static int janus_websockets_callback(
//                                     struct lws *wsi,
//                                     enum lws_callback_reasons reason,
//                                     void *user, void *in, size_t len)
//{
//    GJJanus* janus = static_cast<GJJanus*>(user);
//    return janus->janus_websockets_callback(wsi, reason, in, len);
//}
GJJanus::GJJanus(string ws){
    setupWS();
}
GJJanus::GJJanus(string ip,int port):_ip(ip),_port(port){
    setupWS();
}
int GJJanus::janusWsRunloop(void *arg){
    
    return 1;
}

void GJJanus::setupWS(){
    struct lws_context_creation_info wscinfo;
    memset(&wscinfo, 0, sizeof wscinfo);
    wscinfo.options |= LWS_SERVER_OPTION_EXPLICIT_VHOSTS;
    wscinfo.count_threads = 1;
    /* Create the base context */
    wsc = lws_create_context(&wscinfo);
    
    struct lws_context_creation_info info;
    memset(&info, 0, sizeof info);
    info.port = _port;
    info.iface = _ip.c_str();
    info.protocols = ws_protocols;
    info.extensions = NULL;
    info.ssl_cert_filepath = NULL;
    info.ssl_private_key_filepath = NULL;
    info.gid = -1;
    info.uid = -1;
    info.options = 0;
    /* Create the WebSocket context */
    struct lws_vhost *wss = lws_create_vhost(wsc, &info);
    thread t(std::bind(&GJJanus::janusWsRunloop,this));
    t.detach();
}
