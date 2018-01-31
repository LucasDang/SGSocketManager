//
//  SGSocketConfigM.h
//  SGChat_iOS
//
//  Created by ShangGuo on 2018/1/30.
//  Copyright © 2018年 Seocoo. All rights reserved.
//

#import <Foundation/Foundation.h>

#warning -需要填写ip以及port

#define SG_Socket_Ip_Debug @""
#define SG_Socket_Port_Debug
#define SG_Socket_UdpPort_Debug

#define SG_Socket_Ip @""
#define SG_Socket_Port
#define SG_Socket_UdpPort

#define SG_Socket_Timeout 5
#define SG_Socket_PingTimeInterval 30
#define SG_Socket_ReconnectTime 10
#define SG_Socket_ReconnectTimeInterval 5


@interface SGSocketConfigM : NSObject

/**
 <#Description#>
 */
@property(nonatomic,readonly)NSString * ip;
/**
 <#Description#>
 */
@property(nonatomic,readonly)uint16_t port;
/**
 超时时间
 默认为5s;
 */
@property(nonatomic,readonly)NSTimeInterval timeout;
/**
 连接错误
 */
@property(nonatomic,readonly)NSError * connectError;
/**
 发送心跳开启定时器的时间间隔
 默认为30s发一次;
 */
@property(nonatomic,readonly)float pingTimeInterval;
/**
 断线之后重连次数
 默认为10次;
 */
@property(nonatomic,readonly)int reconnectTime;
/**
 断线之后重连的间隔时间
 默认为5s;
 */
@property(nonatomic,readonly)float reconnectTimeInterval;

/**
 <#Description#>

 @return <#return value description#>
 */
+ (instancetype)ShareInstance;

/**
 测试地址的ip和port
 
 @return <#return value description#>
 */
+ (instancetype)DebugShareInstance;


/**
 工厂模式自定义初始化

 @param ip <#ip description#>
 @param port <#port description#>
 @return <#return value description#>
 */
+ (instancetype)ConfigWithSocketIp:(NSString*)ip port:(uint16_t)port;

+ (instancetype)ConfigWithSocketIp:(NSString*)ip port:(uint16_t)port timeout:(NSTimeInterval)timeout;

+ (instancetype)ConfigWithSocketIp:(NSString*)ip port:(uint16_t)port timeout:(NSTimeInterval)timeout pingTimeInterval:(float)pingTimeInterval reconnectTime:(int)reconnectTime reconnectTimeInterval:(float)reconnectTimeInterval;

@end
