框架说明
====
+ 基于 **Openresty**，适用于业务逻辑比较复杂的 web 应用。   
+ 基于 HTTP 协议，使用 **Nginx Push Stream Module** 实现了消息推送。     
+ 实现了基于 **Redis** 的会话身份认证。
+ 实现了请求重试处理。
+ 实现了上行数据 Gzip 压缩。
+ 实现了上下行数据加密。
+ 实现了静态数据的模块化缓存。
+ 实现了统一可定制的错误处理。
+ 实现了用户数据修改的监控和自动下发。
+ 框架目前有 **Redis**、**Memcache**、**MySQL** 三种数据驱动，均实现了请求级别单例，并支持连接池特性。  
+ 框架目前已应用于线上的手机游戏项目《小小兽人》，较同等 PHP 项目负载能力有本质性提升。 

功能示例
====
> zOpenLua 默认的返回数据格式为 JSON，为了正常调试接口，请安装 JsonView 浏览器插件。   
> 除注册和登录以外的请求，需要传递认证参数 token，其值由注册或登录接口返回。

接口文档及接口测试工具，请由 [> zDocs <](http://zlua.zivn.me/docs/) 进入。

高级特性
====
## 1. 基于 Redis 的会话身份认证
zOpenLua 实现了基于 Redis 的会话身份认证，详见 **core.session** 模块。    

> 在登录或注册时，生成唯一的会话验证密钥，并以密钥为键名将会话信息存储到 **Redis** 中。   
> 会话验证密钥会返回给客户端，后续请求中都需要传递会话验证密钥，以便服务端进行身份认证。   
> 原理和传统的 session 验证机制一致，只是 session_id 通过请求参数提交而不是 cookie。   

使用 **Redis** 存储会话信息是出于分布式的考虑。   
哪怕应用被分布到多个 WebServer，但如果它们使用同一个 **Redis**，认证机制依然是可用的。      
如果没有分布式需求，可修改代码将 **Redis** 替换为 **ngx.shared.DICT**。   
在性能上，**ngx.shared.DICT** 应该会比 **Redis** 更优秀一些。  

*会话身份认证机制实现了重复登录检测。同一用户重复登录，将导致之前登录的会话信息失效。*   

## 2. 请求重试处理
zOpenLua 实现了请求重试处理，详见 **core.app** 和 **core.response** 模块。   

由于手机网络状况往往不理想，时常会发送了请求却没有收到服务端的返回，此时客户端需要进行请求重试。   
但服务端其实已经接收到了前一次的请求，并进行了处理，再次发送请求会导致服务端重复处理。  
这时，实现合理的请求重试处理机制，就非常必要了。  

> 服务端将会存储用户最后一次请求的参数和返回数据。   
> 当某次用户请求被判定为重试时，将直接返回缓存的上次请求的返回数据，而略过请求处理。   
>   
> 为了实现此机制，客户端需要在每次请求时传递请求随机数 r。   
> 每个非重试的请求都应有不同的 r 值，重试时发送相同的 r 值。   
> 当服务端发现请求动作和 r 值与缓存的上次请求数据一致，则判定为请求重试，直接返回缓存数据。    

## 3. 上行数据 Gzip 压缩
zOpenLua 实现了上行消息 Gzip 压缩，详见 **core.request** 模块。

某些请求需要上行大量数据，由于手机网络不稳定，这种请求极易失败。   
上行数据压缩，将大大减少传输数据量，从而降低请求失败机率。    

> 上行数据 Gzip 压缩仅适用于 **POST** 数据。   
> 客户端需要将 **POST** 数据 Gzip 压缩，并在 header 中发送 **Content-Encoding: gzip**。   
> 服务端在接收到上行数据后，根据 header 判断是否需要先解压。   

## 4. 上下行数据加密
zOpenLua 实现了上下行数据加密，详见 **core.request** 和 **core.response** 模块。

> 上下行数据均可加密，加密采用较简单的对称加密算法。   
> 在 **config.system** 中有独立的上下行加密开关。   
> 上行加密启用时，会先对上行 **POST** 数据解密后再进一步解析。   
> 下行加密启用时，会对下行数据加密后再返回。

## 5. 静态数据的模块化缓存
zOpenLua 实现了静态数据的模块化缓存，详见 **core.base.staticDao** 模块。  

在继承于 **staticDao** 的静态数据（类型数据）Dao 中，可定义缓存策略。   
静态数据 Dao 模块加载时，会查询出数据库中的所有记录。   
然后根据 Dao 中定义的缓存策略，组织缓存数据，再以模块属性方式保存。   

> 当 lua_code_cache 开启时，同一个 nginx worker 只具有一个 Lua VM。   
> 当模块首次加载后，就被保存到内存里，对同一个 worker 的所有请求来说，已加载模块是共享的。     
> 利用这一点，在 Dao 模块加载并生成缓存数据后，缓存数据作为模块属性，也被存储到内存中。   
> 后续请求均可通过模块属性读取缓存数据，相当于使用内存缓存了静态数据。

静态数据缓存保存在内存中，如果需要更新数据，可使用以下两种方式： 
  
1. `nginx -s reload`   
2. ``kill -HUP `cat nginx/logs/nginx.pid` ``   

## 6. 统一错误处理
zOpenLua 实现了统一错误处理，详见 **core.exception** 模块。     

> 可在程序任意处使用 `exception:raise(errCode, errData)` 抛出异常，中断当前代码的执行。   
> exception 是对 error 的封装，增加了错误代码和异常数据，方便 debug。   
> 在 **config.system** 中的 **DEBUG_MODE** 启用时，exception 还将获取并记录错误栈信息。

> exception 所使用的所有 errCode 都需要在 **config.error** 里定义说明，方便国际化时进行翻译。   
> 未在 **config.error** 定义的 errCode 会在下发给客户端时转化为 **core.unknowErr**。    
> errCode 一般使用 ***[module].[message]*** 格式，方便区分和定位，同一错误应复用 errCode。    

## 7. 用户数据修改监控和自动下发
zOpenLua 实现了用户数据修改监控和自动下发，详见 **core.changes** 和 **core.base.dyncDao** 模块。 

对于游戏应用来说，一般会在首次进入时载入用户的所有主要数据。   
并后续的请求中，通过返回的数据改变维护本地的用户数据缓存。

> **changes** 会在获取会话信息时初始化。
> **changes** 的主要处理机制封装在 **core.base.dyncDao** 中。   
> 启用数据的 **changes** 特性，需要在 **config.changes** 中定义监控规则。
> 启用数据的 **changes** 特性，需要在继承于 dyncDao 的动态数据 Dao 中，定义 **logChangeKey**。   

根据 Dao 中定义的监控规则，每次对应的动态数据新增、更新、删除时，都会分析并记录数据更改。   
在请求应答被返回时，**core.response** 会提取 **changes** 数据，并通过请求应答返回给客户端。   

> **config.changes** 用于定义数据改变监控规则。   
> **config.changes** 的 key 应和对应 Dao 的 **logChangeKey** 相同，也是返回给客户端的改变数据的 key。
>   
> 每条规则均需定义 **matchkey**、**matchAttr**、**primaryKey**、**single** 四个属性。   
> 当会话信息中的 **matchkey** 和数据的 **matchAttr** 属性的值相同时，数据改表将会被记录。   
> **primaryKey** 是数据的主键，也是客户端用户数据缓存的唯一性识别的标志属性。      
> **single** 标识此类数据每个用户是否只有一条数据（user），还是会有多条（userHero、userEquip）。

初次理解可能比较难，请看两个例子：   

### 购买英雄

以下是购买英雄的返回： 
  
    {
        op: 201,
        error: null,
        data: {
            ok: true
        },
        changes: {
            updates: {
                user: {
                    gold: 9950010,
                    id: 4
                },
                heros: [
                    {
                        level: 1,
                        price: 1220,
                        id: 21,
                        hp: 344,
                        heroId: 1,
                        dodge: 20,
                        crit: 20,
                        exp: 0,
                        userId: 4,
                        hit: 80,
                        def: 25,
                        att: 43
                    }
                ]
            }
        }
    }

此返回中，标识了两个请求造成的数据修改。   
1. *id 为 4 的 user 的 gold 变成了 9950010。*   
2. *id 为 21 的 hero 更新了所有属性。*

> changes 的 updates 中不仅标识数据更新，也标识数据新增。   

客户端发现本地没有存储 id 为 21 的 hero 时，认定为新增了一个 id 为 21 的 hero。

### 吞噬英雄

以下是吞噬英雄的返回：   

    {
        op: 203,
        error: null,
        data: {
            ok: true
        },
        changes: {
            removes: {
                heros: [
                    17,
                    19,
                    18
                ]
            },
            updates: {
                user: {
                    gold: 9949710,
                    id: 4
                },
                heros: [
                    {
                        exp: 200,
                        id: 4
                    }
                ]
            }
        }
    }

此返回中，标识了请求造成的两个数据修改和一个数据删除。   
1. *id 为 17、18、19 的 hero 被删除。*      
2. *id 为 4 的 user 的 gold 变成了 9949710。*  
3. *id 为 4 的 hero 的 exp 变成了 200。*  

## 8. 消息推送
zOpenLua 使用 **Nginx Push Stream Module** 实现了消息推送，详见 **core.push** 模块。     
_通过消息推送，可以实现简单的聊天室，详见 **code.ctrl.Chat** 模块。_    

> **Nginx Push Stream Module** 是一个 **Comet** 解决方案，支持 **WebSocket**、**Long Polling** 等多种模式。  
> [Nginx Push Stream Module](https://github.com/wandenberg/nginx-push-stream-module) 的文档请自行参阅其 Github。   
> 
> 客户端需要监听频道的 HTTP 链接，并在连接断开时重连。   
> 服务端会定时（60s）向客户端发送心跳消息，如规定时间内未收到心跳，也应重新连接。   

> 此链接将处于持续加载状态，服务端一旦推送信息，则客户端自链接收到新的数据，直至链接超时断开。   
> **Polling** 的原理请自行阅读 **Comet** 的相关文章了解具体细节。 

频道名字目前采用 **SERVER_MARK** + ***channelPrefix*** + *[extendId]*。    

目前有 3 个频道，分别为世界、心跳、用户，假设用户 ID 是 1，**SERVER_MARK** 是 dev。   
则应监听链接为：`http://zlua.zivn.me/sub/devworld.b20/devping/devuser1.b20`。   
> **.b20** 代表获取频道最后 20 条消息。   

以下是监听频道的示例返回:  

    {
        op : 3,
        data : {
            zoneOffset: 0,
            serverTime: 1404293281,
            v: 1408,
            channel: 2
        },
        error: null
    }
    {
        op: 2,
        data: {
            zoneOffset: 0,
            serverTime: 1404293290,
            fromId: 4,
            fromName: "zivn",
            content: "test",
            v: 1409,
            channel: 1
        },
        error: null
    }
    {
        op : 3,
        data : {
            zoneOffset: 0,
            serverTime: 1404293341,
            v: 1410,
            channel: 2
        },
        error: null
    } 


_共收到了 2 次 **ping** 消息和一次世界频道聊天消息。_

> 由于频繁重连，并设置了连接时获取最后数条消息，可能造成客户端接收到重复消息，并导致重复处理。  
> 为此，我们在消息中增加了版本号 **v**，每次服务端推送消息 **v** 都会递增，并在消息中下发给客户端。  
> 
> 客户端收到推送消息时，先比对本地 **v** 值和消息 **v** 值，如消息的 **v** 值较大，则处理，否则忽略消息。   
> 如消息被处理，则处理完成后，将消息 **v** 值赋给本地 **v** 值。
>      
> 用户登录和注册后会接收到 **pushVer** 属性，即当前最新推送消息版本，此时客户端应重置本地 **v** 值。   
> 通过推送消息版本管理，可保证同一消息哪怕被多次接收，也只会处理一次。  

系统要求
====
## 软件需求
* [Openresty](http://www.openresty.org/): ≥ 1.51    
* [Nginx Push Stream Module](https://github.com/wandenberg/nginx-push-stream-module): ≥ 0.4    
* [Redis](http://redis.io/download): ≥ 2.6    
* [Lua-zlib](https://github.com/brimworks/lua-zlib): ≥ 0.2     

## 软件安装
*   实现 MySQL 驱动的 **JSON_KEYSET** 支持需替换 **OpenResty** 的 MySQL 驱动。   
   
    > 拷贝 **soft/mysql.lua** 至 **OpenResty** 对应目录即可。    
    > `cp -f ./soft/mysql.lua /usr/local/openresty/lualib/resty/`  
    
*   实现推送消息支持，需安装 **Nginx Push Stream Module**。   

    > 编译 **OpenResty** 时需要增加对应编译参数。    
    > `./configure --with-luajit --add-module=../nginx-push-stream-module-0.4.0`    
       
*   实现上行消息 Gzip 支持，需要安装 **Lua-zlib**。   
 
    > 编译时需要链接 **OpenResty** 的 **libluajit-5.1.so.2**。    
    > `ln -fs /usr/local/openresty/luajit/lib/libluajit-5.1.so.2 /usr/lib64/ziblua.so`   

    > 编译时需要修改 **Lua-zlib** 的 **MakeFile** 中的 **INCDIR**。   
    `INCDIR   = -I/usr/local/openresty/luajit/include/luajit-2.1`   

_如果是 64 位 **CentOS** 系统，可用 **soft/soft.sh** 安装上述软件。_

## Nginx 配置
框架运作需要在 **Nginx** 的 **http** 和 **server** 中增加相关配置：    

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


核心模块说明
====
# main
> _对应 **main.lua** 文件。_   
 
**main** 是整个项目的入口文件，定义了一些全局函数，并从此处启动应用。   

### _G.loadMod(namespace)
**loadMod** 用于替代 **require** 函数，配合 **lua_package_path** 和 **SERVER_DIR** 实现无障碍加载文件。   
**loadMod** 实现了各个 **nginx server** 加载模块的隔离，可在同一 **nginx** 上定义多个不同版本的 **server**。      

> 在项目中加载 **core\util.lua**，可用 `local util = loadMod("core.util")`。   
> 实际 **require** 参数为 **zlua_zivn_me.lua.core.util**，对应路径为 **zlua_zivn_me\lua\core\util.lua**。

注意，**loadMod** 仅限于加载项目内模块，对与系统级的模块，如 **cjson** 等，还是应该用 **require** 加载。   

### _G.saveMod(namespace, model)
用于保存数据为已加载模块，原理是构造模块名，并将数据存入 **package.loaded** 表。     

# core.app
> _对应 **core\app.lua** 文件。_   

主应用模块，主要作用是应用初始化、请求路由和处理、应用清理。   
外部仅限调用 **app:run()**，其他方法均为内部使用。

### app:init()
应用初始化。定义项目跟路径，初始化随机数种子（用于解决随机数不平均问题）。

### app:clean()
应用清理。用户会话锁解锁（见 **core.session** 模块）、关闭数据驱动（见 __core.driver.*__ 模块）。

### app:route()
请求路由分发。请求重试机制处理（见 **core.response** 模块）、请求路由分发、请求执行。   

> 当请求被判定为非重试请求时，会将请求分发给对应的控制器。    
> 请求执行时，会先执行对应控制器的 **filter** 方法，用于控制器通用的前置条件过滤判断。       
> 再执行对应的控制器的请求对应方法，以处理业务逻辑。      
> 最后执行对应控制器的 **cleaner** 方法，用于控制器通用的结束清理。      
> 详见 **core.base.ctrl** 模块中的对应说明。       

# core.request
> _对应 **core\request.lua** 文件。_
   
请求处理模块，主要作用是请求数据分析、处理和获取请求参数。

>请求参数中，有几个关键参数：   
#### **act**   
  **act** 是请求动作定义参数，格式是 **module.method**。   
  **act** 用于请求的路由和分发，应用根据 **act** 将请求分发给对应控制器（**module**）的方法（**method**）。 
>  
#### **op**   
  **op** 是请求操作码定义参数，**op** 与 **act** 一一对应，对应关系定义在 **config.action** 中。  
  在应用内部 **op** 会被转化为 **act**，再根据 **act** 进行请求的路由和分发。 
>
#### **token**   
  **token** 是请求认证密钥定义参数，用于认证使用者的身份，机制原理在 [基于 Redis 的会话身份认证](#1-基于-Redis-的会话身份认证) 中有介绍。   
  **token** 的值来自于登录和注册接口的返回数据，是一个 32 个字符的字符串。   
  **token** 的参数名可以自定义，如需修改请自行调整 **config.system** 里的 **SESSION_TOKEN_NAME**。

>    
#### **r**   
  **r** 是请求随机数定义参数，用于请求重试处理，机制原理在 [请求重试处理机制](#2-请求重试处理) 中有介绍。   
  如果请求没有发送 **r** 值，将不会进行请求重试处理。     
  **r** 的参数名可以自定义，如需修改请自行调整 **config.system** 里的 **RETRY_RANDOM_PARAM**。 

### parseArgs(args, data)
局部函数，用于格式化请求数据，其中包含了对请求动作参数的处理。

### parseRequestData()
局部函数，用于分析请求数据，并存储到 **ngx.ctx**。   
包括对 **GET** 和 **POST** 数据的解析（包括解压、解密）、对 **Cookie** 数据的解析、**op** 转换为 **act** 等，具体细节请阅读代码。   

### getRequestData()
局部函数，获取请求数据，返回解析后的请求数据。如请求未被解析，则会先解析并保存后再返回。

### request:getOp()
获取请求操作码，返回整形的请求操作码。   

### request:getAction()
获取请求动作，返回表 `{ module, method }`。

### request:getCookie(key)
获取Cookie中指定键名的值，返回 Cookie 中对应键名的字符串值。

### request:getTime()
获取请求发起时间，返回请求发起的时间戳。

### request:getIp()
获取请求发起IP，返回请求发起客户端的字符串 IP 地址。

### request:isLocal()
是否为本机请求，返回请求是否由本机发起的布尔值。

### request:getNumParam(name, abs, nonzero)
获取请求参数中的数字参数，将返回请求参数中对应参数名的数字值。   
abs 指定是否需要对数值进行绝对值操作。  
nonzero 指定是否在数值为 0 或未指定时抛出异常。

### request:getStrParam(name, nonempty, trim)
获取请求参数中的字符串参数，将返回请求参数中对应参数名的字符串值。   
trim 指定是否需要对字符串值进行去掉头尾空格操作。  
nonempty 指定是否在字符串值为 "" 或未指定时抛出异常。

### request:getNumsParam(name, abs, nonempty)
获取请求参数中的数字序列参数，将返回请求参数中对应参数名的数字值序列。   
上行参数需要是用同一非数字字符隔开的多个数字组成的字符串，例如 `1,2,3` 或 `1;2;3`。   
abs 指定是否需要对数字值序列中的数值进行绝对值操作。  
nonempty 指定是否在数字值序列为空或未指定时抛出异常。







