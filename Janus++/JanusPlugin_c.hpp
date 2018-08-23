//
//  GJJanusPlugin.hpp
//  GJJanus++
//
//  Created by melot on 2018/3/19.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#ifndef GJJanusPlugin_hpp
#define GJJanusPlugin_hpp

#include <string>
#include "GJJanus_c.hpp"
using namespace std;
class GJJanusPlugin{
    string name;
    string opaqueId;
    string handleId;
    shared_ptr<GJJanus*>  janus;
public:

};
#endif /* GJJanusPlugin_hpp */
