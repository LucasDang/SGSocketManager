//
//  SGSocketBusiness.h
//  SGChat_iOS
//
//  Created by ShangGuo on 2018/1/30.
//  Copyright © 2018年 Seocoo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SGSocketManager.h"

typedef void(^SocketLoginResponseBlock)(BOOL ifLoginSuccess,id data);

@interface SGSocketBusiness : NSObject


/**
 获取连接状态
 
 @return <#return value description#>
 */
+ (SGSocketConnectState)SocketConnectState;

/**
 用户登录

 @param userCode 用户唯一识别
 @param channelId 登录通道
 @param complation <#complation description#>
 */
+ (void)RequestToLoginWithUserCode:(NSString*)userCode ChannelId:(NSString*)channelId Complation:(SocketLoginResponseBlock)complation;

/**
 用户退出
 */
+ (void)RequestToLoginOut;

/**
 发送数据
 
 @param dic <#dic description#>
 */
+ (void)SendDataWithData:(NSDictionary*)dic;

/**
 单聊发送消息
 
 @param msgType 消息类型
 @param msgContent 消息内容
 @param msgSaveContent 消息保存在本地数据库的内容 - 文本存文字，图片存为yyimage的key，语音和视频存路径
 @param transactionID 消息id
 @param target 发送对象
 @param msgTime 消息发送时间
 */
+ (void) PushSingleMsgWithMsgType:(NSString *)msgType msgContent:(NSString*)msgContent msgSaveContent:(NSString*)msgSaveContent transactionID:(NSString *)transactionID toTarget:(NSString *)target MsgTime:(double)msgTime extraPro:(NSString*)extraPro;


/**
 群聊发送消息
 
 @param msgType 消息类型
 @param msgContent 消息内容
 @param msgSaveContent 消息保存在本地数据库的内容 - 文本存文字，图片存为yyimage的key，语音和视频存路径
 @param transactionID 消息id
 @param target 群编码
 @param groupName 发送方昵称
 @param msgTime 消息发送时间
 @param extraPro 额外的添加内容 - 现在只有发视频的时候，视频路径传过去
 */
+ (void) PushGroupMsgWithMsgType:(NSString *)msgType msgContent:(NSString*)msgContent msgSaveContent:(NSString*)msgSaveContent transactionID:(NSString *)transactionID toTarget:(NSString *)target groupName:(NSString*)groupName MsgTime:(double)msgTime extraPro:(NSString*)extraPro;

/**
 发送消息回执
 
 @param trahsId 消息标识
 @param target 发送人
 @param messageType 消息类型
 */
+ (void) requestToPushBackWithtrahsId:(NSString *)trahsId target:(NSString *)target messageType:(NSString *)messageType;


@end
