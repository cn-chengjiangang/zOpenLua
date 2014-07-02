zOpenLua
====
一个基于Openresty的轻量级web应用框架。

框架说明
====
zOpenLua 一个基于 Openresty 的轻量级 web 应用框架，适用于业务逻辑比较复杂的 web 应用。   
zOpenLua 基于 HTTP 协议，并使用 Push Stream Module 实现了消息推送，足以满足一般非 ARPG 手游页游需求。     
zOpenLua 还实现了基于 Redis 的 Session、请求重试处理机制、上行消息 Gzip 压缩、通讯消息加密、静态数据模块缓存、统一错误处理、数据修改自动记录下发等高级特性。   
zOpenLua 目前有 redis、memcache、mysql 三种数据驱动，所有数据驱动均实现了请求级单例，并支持连接池特性。  
zOpenLua 目前以应用于线上的手机游戏项目《小小兽人》，负载能力较传统 PHP 实现有明显的大幅提升。    
使用 zOpenLua 和 PHP 实现相同的简单测试业务逻辑，并进行 AB 测试，zOpenLua 的效率大约是 PHP 代码的 3-5 倍以上，而且错误率极低。

功能示例
====
请自行替换示例中的参数，目前 zOpenLua 返回的数据格式为 Json。    
要正确解析示例返回，请安装 JsonView 浏览器插件。
除注册和登录以外的请求，需要传递认证参数 token，其值由注册或登录接口返回。

### 用户注册
* http://zlua.zivn.me/lua?op=101&name=str{4,12}&passwd=str{6,12}&icon=int[1,10]&heroId=int[1,10]
* http://zlua.zivn.me/lua?act=User.register&name=str{4,12}&passwd=str{6,12}&icon=int[1,10]&heroId=int[1,10]

### 用户登录
* http://zlua.zivn.me/lua?op=102&name=str{4,12}&passwd=str{6,12}
* http://zlua.zivn.me/lua?act=User.login&name=str{4,12}&passwd=str{6,12}

### 修改头像
* http://zlua.zivn.me/lua?op=103&icon=int[1,10]&token=str{32}    
* http://zlua.zivn.me/lua?act=User.changeIcon&icon=int[1,10]&token=str{32}    

### 购买英雄
* http://zlua.zivn.me/lua?op=201&heroId=int[1,10]&token=str{32}    
* http://zlua.zivn.me/lua?act=Hero.buy&heroId=int[1,10]&token=str{32}    

### 出售英雄
* http://zlua.zivn.me/lua?op=202&sellIds=int[1,10],int[1,10],int[1,10]...&token=str{32}    
* http://zlua.zivn.me/lua?act=Hero.sell&sellIds=int[1,10],int[1,10],int[1,10]...&token=str{32}    

### 英雄吞噬升级
* http://zlua.zivn.me/lua?op=203&heroId=int[1,10]&devourIds=int[1,10],int[1,10],int[1,10]...&token=str{32}        
* http://zlua.zivn.me/lua?act=Hero.devour&heroId=int[1,10]&devourIds=int[1,10],int[1,10],int[1,10]...&token=str{32}        

### 购买装备
* http://zlua.zivn.me/lua?op=301&equipId=int[1,10]&token=str{32}    
* http://zlua.zivn.me/lua?act=Equip.buy&equipId=int[1,10]&token=str{32}    

### 出售装备
* http://zlua.zivn.me/lua?op=302&sellIds=int[1,10],int[1,10],int[1,10]...&token=str{32}    
* http://zlua.zivn.me/lua?act=Equip.sell&sellIds=int[1,10],int[1,10],int[1,10]...&token=str{32}    

### 装备装备
* http://zlua.zivn.me/lua?op=303&heroId=int[1,10]&position=int[1,10]&equipId=int[1,10]&token=str{32}    
* http://zlua.zivn.me/lua?act=Equip.equip&heroId=int[1,10]&position=int[1,10]&equipId=int[1,10]&token=str{32}    

### 装备升级
* http://zlua.zivn.me/lua?op=304&equipId=int[1,10]&token=str{32}    
* http://zlua.zivn.me/lua?act=Equip.refine&equipId=int[1,10]&token=str{32}    

高级特性
====
### 基于 Redis 的 Session
zOpenLua 实现了一套基于 Redis 的会话验证机制，详见 core.session 模块。   
在登录后，生成唯一的会话验证密钥，并以密钥为键名将会话信息存储到 Redis 中。   
会话验证密钥会返回给客户端，后续请求中都需要传递会话验证密钥 token 参数，以便身份认证。   

使用 Redis 存储是出于分布式的考虑，多个 WebServer 时，使用相同的 redis server，认证机制依然是可用的。      
如果没有分布式需求，可修改代码将 redis 替换为 ngx.shared.DICT。   

会话验证机制实现了重复登录处理机制。同一用户重复登录时，会使之前登录的会话信息失效。   

### 请求重试处理机制
zOpenLua 实现了请求重试处理机制，详见 core.app 和 core.response 模块。   


、上行消息 Gzip 压缩、通讯消息加密、静态数据模块缓存、统一错误处理、数据修改自动记录下发等高级特性

系统要求
====
## 软件需求
* [Openresty](http://www.openresty.org/): ≥ 1.51    
* [Nginx Push Stream Module](https://github.com/wandenberg/nginx-push-stream-module): ≥ 0.4    
* [Redis](http://redis.io/download): ≥ 2.6    
* [Lua-zlib](https://github.com/brimworks/lua-zlib): ≥ 0.2     

## 软件安装
*   实现 MySQL 的 JsonField 支持需替换 OpenResty 的 mysql 驱动。   
 
    拷贝 soft 中的 mysql.lua 至 OpenResty 对应目录即可。    
    `cp -f ./soft/mysql.lua /usr/local/openresty/lualib/resty/`

*   实现推送消息支持，需安装 Nginx Push Stream Module。  
  
    编译 OpenResty 时需要增加对应编译参数。    
    `./configure --with-luajit --add-module=../nginx-push-stream-module-0.4.0`    

*   实现上行消息 Gzip 支持，需要安装 Lua-zlib。   
 
    编译时需要链接 OpenResty 的 libluajit-5.1.so。    
    `ln -fs /usr/local/openresty/luajit/lib/libluajit-5.1.so.2 /usr/lib64/ziblua.so`   

    并修改 Lua-zlib 的 MakeFile 中的 INCDIR。   
    `INCDIR   = -I/usr/local/openresty/luajit/include/luajit-2.1`   

如果是 64 位 CentOS 系统，可用 soft/soft.sh 安装上述软件。

## Nginx 配置
框架运作需要在 Nginx 的 http 和 server 中增加相关配置。    

    http    
    {    
        # Push Stream 共享内存大小    
        push_stream_shared_memory_size 256m;    

        # Push Stream 频道无活动后被回收的时间    
        push_stream_channel_inactivity_time 30m;    

        # Push Stream 消息生存时间
        push_stream_message_ttl 30m;

        # lua 文件包含基础路径
        lua_package_path '/data/web/?.lua;;';

        # lua C扩展包含基础路径
        lua_package_cpath '/data/web/?.so;;';

        server
        {
            listen 80;
            server_name zlua.zivn.me;
            access_log /data/log/nginx.zlua.log;

            # 服务器目录名（不可用 "."，否则包含文件时会被 Lua 替换为目录分隔符）
            set $SERVER_DIR zlua_zivn_me;

            # 项目根目录
            set $ROOT_PATH /data/web/$SERVER_DIR;

            # Lua 文件根目录
            set $LUA_PATH $ROOT_PATH/lua;

            # 定义 Web 目录
            root $ROOT_PATH/webroot;
            index index.html index.htm index.php;

            # lua 请求路径
            location = /lua {
                # 打开代码缓存
                lua_code_cache on;

                # 程序入口
                content_by_lua_file $LUA_PATH/main.lua;
            }

            # 发布推送消息路径
            location /pub {
                internal;

                # 发布者身份
                push_stream_publisher admin;

                # 频道路径参数
                push_stream_channels_path $arg_id;

                # 保存频道消息
                push_stream_store_messages on;

                # 发送消息后不返回频道信息
                push_stream_channel_info_on_publish off;

                # 最近接收频道消息的时间（用于滤除旧消息）
                push_stream_last_received_message_time $arg_time;
            }
            
            # 订阅推送消息路径
            location ~ /sub/(.*) {
                # 消息订阅者
                push_stream_subscriber;

                # 频道路径参数
                push_stream_channels_path $1;
            }
        }    
    }   

## Crontab 配置
项目的计划任务功能，需要在 Crontab 中进行相关配置才能实现。
`echo "* * * * * root curl http://zlua.zivn.me/lua?act=Schedule.run >> /data/log/schedule-zlua.log" >> /etc/cron.d/zlua.cron`



模块说明
====
## main.lua
整个项目的入口文件，由此进入 Lua 代码控制，以实现复杂的业务逻辑功能。
main.lua 定义了一些全局函数，并启动应用。

### _G.loadMod
用于替代 require 函数，配合 lua_package_path 和 SERVER_DIR 实现文件的无障碍加载，并可隔离每个 server 加载的模块，实现同机多服。

例如，在项目中加载 core\util.lua：
`local util = loadMod("core.util")`
实际 require 参数为 **zlua_zivn_me.lua.core.util**，对应路径为 **zlua_zivn_me\lua\core\util.lua**。

### _G.saveMod
用于保存数据为已加载模块，原理是构造模块名，并将数据存入 **package.loaded** 表。

## core.app
对应 core\app.lua 文件，主应用模块，主要作用是应用初始化、请求路由和处理、应用清理。
外部只需调用 **app:run()** 即可，其他方法均为内部使用。

### app:init()
应用初始化。定义项目跟路径，初始化随机数种子（用于解决随机数不平均问题）。

### app:clean()
应用清理。用户会话锁解锁（见 core.session 模块）、关闭数据驱动（见 core.driver.* 模块）。

### app:route()
请求路由分发。请求重试机制处理（见 core.response 模块）、请求路由、请求执行。

请求执行时，会先执行对应控制器的 **filter** 方法，用于控制器通用的前置条件过滤判断。
再执行请求对应的控制器方法，以处理业务逻辑。
最后执行对应控制器的 **cleaner** 方法，用于控制器通用的结束清理。
详见 core.base.ctrl 模块中的对应说明。

## core.response 
对应 core\response.lua 文件，主要用于请求数据处理、分析请求参数。

### parseArgs(args, data)
局部函数，用于格式化请求数据，其中包含了对请求路由




