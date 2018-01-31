//
//  SGSocketManager.h
//  SGChat_iOS
//
//  Created by ShangGuo on 2018/1/30.
//  Copyright © 2018年 Seocoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGSocketConfigM.h"

/**
 *  连接状态
 */
typedef NS_ENUM(NSInteger, SGSocketConnectState) {
    SGSocketConnectState_NotConnect = 1,     ///未连接
    SGSocketConnectState_ConnectSuccess = 2, ///连接成功
    SGSocketConnectState_ConnectFail = 3,    ///连接失败
    SGSocketConnectState_Connecting = 4,     ///正在连接
    SGSocketConnectState_ReConnecting = 5,   ///正在重新连接中
    
};

typedef void(^SocketConnectResponseBlock)(NSError * error);

@protocol SGSocketManagerDelegate <NSObject>

@required
/**
 心跳事件，需实现此代理方法，自己组装心跳报文发送
 
 */
-(void)socketManagerPingTimerAction;

@optional

/**
 连接成功

 @param configM <#configM description#>
 */
-(void)socketManagerSuccessToConnectWithConfigM:(SGSocketConfigM*)configM;

/**
 连接失败

 @param configM <#configM description#>
 @param error <#err description#>
 */
-(void)socketManagerFailToDisconnectWithConfigM:(SGSocketConfigM*)configM error:(NSError *)error;

/**
 发送数据成功

 @param tag <#tag description#>
 */
-(void)socketManagerSuccessToWriteDataWithTag:(long)tag;

/**
 收到数据

 @param data <#data description#>
 @param tag <#tag description#>
 */
-(void)socketManagerSuccessToReceiveMsg:(NSData *)data withTag:(long)tag;

@end

@interface SGSocketManager : NSObject

@property (nonatomic,weak)id delegate;

+ (instancetype)shareInstance;

/**
 获取连接状态

 @return <#return value description#>
 */
+ (SGSocketConnectState)SocketConnectState;

/**
 连接

 @param configM <#configM description#>
 */
+ (void)ConnectSocketWithConfigM:(SGSocketConfigM*)configM complation:(SocketConnectResponseBlock)complation;

/**
 断开连接

 */
+ (void)DisConnectSocket;

/**
 发送数据

 @param dic <#dic description#>
 */
+ (void)SendDataWithData:(NSDictionary*)dic;


/**
 开启心跳定时器
 */
- (void)startPingTimer;
@end
