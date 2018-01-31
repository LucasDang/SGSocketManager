//
//  SGSocketBusiness.m
//  SGChat_iOS
//
//  Created by ShangGuo on 2018/1/30.
//  Copyright © 2018年 Seocoo. All rights reserved.
//

#import "SGSocketBusiness.h"
#import "SGSocketConfigM.h"
#import "SGSocketManager.h"

@interface SGSocketBusiness()<SGSocketManagerDelegate>

@property(nonatomic,copy)SocketLoginResponseBlock loginStateBlock;

@property(nonatomic,copy)NSString * appendString;///有时候发送来的数据太长，需要几次发送的一起拼接才是一个正确的格式

@property(nonatomic,copy)NSString * channelId;
@property(nonatomic,copy)NSString * userCode;

@property(nonatomic,retain)SGSocketManager * socketManage;
@end

static SGSocketBusiness * _instance = nil;

@implementation SGSocketBusiness

#pragma mark - 发送消息
/**
 单聊发送消息
 
 @param msgType 消息类型
 @param msgContent 消息内容
 @param msgSaveContent 消息保存在本地数据库的内容 - 文本存文字，图片存为yyimage的key，语音和视频存路径
 @param transactionID 消息id
 @param target 发送对象
 @param msgTime 消息发送时间  如果为0则获取当前时间即可
 */
+ (void) PushSingleMsgWithMsgType:(NSString *)msgType msgContent:(NSString*)msgContent msgSaveContent:(NSString*)msgSaveContent transactionID:(NSString *)transactionID toTarget:(NSString *)target MsgTime:(double)msgTime extraPro:(NSString*)extraPro{
    
    NSDictionary *dic = @{@"SvcCont" :
                              @{@"message" : @{@"data" : msgContent,
                                               @"messageType" : msgType,
                                               @"senderName": SG_UserName,
                                               @"extraPro":extraPro
                                               }},
                          @"TcpCont" : @{@"ServiceType" : @"message",
                                         @"MsgSender" : _instance.userCode,
                                         @"MsgReceiver" : target,
                                         @"TransactionID" : transactionID,
                                         @"ChannelId" : _instance.channelId,
                                         @"SendTime" : msgTimeStr,
                                         @"TargetType" : @"single",
                                         }
                          };
    
    [self SendDataWithData:dic];
    
}


/**
 群聊发送消息
 
 @param msgType 消息类型
 @param msgContent 消息内容
 @param msgSaveContent 消息保存在本地数据库的内容 - 文本存文字，图片存为yyimage的key，语音和视频存路径
 @param transactionID 消息id
 @param target 群编码
 @param groupName 发送方昵称
 @param msgTime 消息发送时间
 
 */
+ (void) PushGroupMsgWithMsgType:(NSString *)msgType msgContent:(NSString*)msgContent msgSaveContent:(NSString*)msgSaveContent transactionID:(NSString *)transactionID toTarget:(NSString *)target groupName:(NSString*)groupName MsgTime:(double)msgTime extraPro:(NSString*)extraPro{
    
    NSDictionary *dic = @{@"SvcCont" : @{@"message" : @{@"data" : msgContent,
                                                        @"messageType" : msgType,
                                                        @"groupName": groupName,
                                                        @"extraPro":extraPro
                                                        }},
                          @"TcpCont" : @{@"ServiceType" : @"message",
                                         @"MsgSender" : SG_UserCode,
                                         @"MsgReceiver" : target,
                                         @"TransactionID" : transactionID,
                                         @"ChannelId" : SG_ChannelId,
                                         @"SendTime" : msgTimeStr,
                                         @"TargetType" : @"group",
                                         @"GroupCode" : target
                                         }};
    
    
    [self SendDataWithData:dic];
    
}



/**
 发送回执
 
 @param trahsId 消息标识
 @param target 发送人
 @param messageType 消息类型
 */
+ (void) requestToPushBackWithtrahsId:(NSString *)trahsId target:(NSString *)target messageType:(NSString *)messageType{
    
    NSDictionary *dic = @{@"SvcCont" : @{@"message" : @{@"resultCode" : @"SUCCESS",
                                                        @"transactionID" : trahsId,
                                                        @"messageType" : messageType,
                                                        @"resultMsg":@"消息已接收",
                                                        @"serverDate":[NSDate getStringTimeTamp]
                                                        }},
                          @"TcpCont" : @{@"ServiceType" : @"back",
                                         @"MsgSender" : SG_UserCode,
                                         @"MsgReceiver" : target,
                                         @"TransactionID" : trahsId,
                                         @"ChannelId" : SG_ChannelId,
                                         }};
    
    [self SendDataWithData:dic];
}

#pragma mark - 接收数据并处理
/**
 处理收到的消息
 
 @param data 消息体
 */
+(void)HandleMessageReceiveMsg:(NSDictionary *)data{
    //NSLog(@"收到信息==%@",data);
    

}

/**
 收到发送消息的回执
 
 @param data <#data description#>
 */
+(void)ReceiveSendDataBack:(NSDictionary *)data{
 
}

/**
 收到服务器的推送
 
 @param data <#data description#>
 */
+(void)ReceiveSeviceNotice:(NSDictionary *)data{
    
    NSLog(@"接收到通知--%@",data);
    
}


#pragma mark - 业务方法
/**
 获取连接状态
 
 @return <#return value description#>
 */
+ (SGSocketConnectState)SocketConnectState{
    return [SGSocketManager SocketConnectState];
}

/**
 用户登录
 */
+ (void)RequestToLoginWithUserCode:(NSString*)userCode ChannelId:(NSString*)channelId Complation:(SocketLoginResponseBlock)complation{
    
    [SGSocketManager ConnectSocketWithConfigM:[SGSocketConfigM DebugShareInstance] complation:^(NSError *error) {
        if (error) {
            if (complation) {
                complation(NO,error);
            }
        }else{
            [SGSocketBusiness shareInstance].loginStateBlock = complation;
            [SGSocketBusiness shareInstance].userCode = userCode;
            [SGSocketBusiness shareInstance].channelId = channelId;
            [self LoginSeviceMessage];
        }
    }];

}

/**
 用户退出
 */
+ (void)RequestToLoginOut{
    [SGSocketManager DisConnectSocket];
}

/**
 发送数据
 
 @param dic <#dic description#>
 */
+ (void)SendDataWithData:(NSDictionary*)dic{
    [SGSocketManager  SendDataWithData:dic];
}


#pragma mark - SGSocketManagerDelegate

/**
 心跳事件，需实现此代理方法，自己组装心跳报文发送
 
 */
-(void)socketManagerPingTimerAction{
    [SGSocketBusiness PingSeviceMessage];
}

/**
 连接成功
 
 @param configM <#configM description#>
 */
-(void)socketManagerSuccessToConnectWithConfigM:(SGSocketConfigM*)configM{
    self.appendString = @"";
    NSLog(@"连接成功");
}

/**
 连接失败
 
 @param configM <#configM description#>
 @param error <#err description#>
 */
-(void)socketManagerFailToDisconnectWithConfigM:(SGSocketConfigM*)configM error:(NSError *)error{
    NSLog(@"连接失败");
}

/**
 发送数据成功
 
 @param tag <#tag description#>
 */
-(void)socketManagerSuccessToWriteDataWithTag:(long)tag{
    
}

/**
 收到数据
 
 @param data <#data description#>
 @param tag <#tag description#>
 */
-(void)socketManagerSuccessToReceiveMsg:(NSData *)data withTag:(long)tag{
    
    NSString *receiverStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    ///大文件因为是分段发送的所以这里进行拼接
    self.appendString = [NSString stringWithFormat:@"%@%@",self.appendString,receiverStr];
    
    ///数据按照固定格式进行解析
    if ([self.appendString rangeOfString:@"##@@"].length > 0) {
        ///接受到消息立即读取下一个消息
        
        NSArray *backStrings = [self.appendString componentsSeparatedByString:@"##@@"];
        NSString *lastString = [backStrings lastObject];
        self.appendString = [self.appendString stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
        if ([lastString isEqualToString:@"\n"] || lastString.length == 0 || [lastString isEqualToString:@"(null)"]){
            self.appendString = @"";
        }else{
            self.appendString = lastString;
        }
        //逐条读取
        for (int i = 0; i < backStrings.count; i++) {
            NSString *backStr = backStrings[i];
            //筛选
            if ([backStr isEqualToString:@"\n"] || backStr.length == 0) {
                return;
            }
            NSData *JSONData = [backStr dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingMutableLeaves error:nil];
            //取数据
            NSString *serviceType = responseJSON[@"TcpCont"][@"ServiceType"];//消息类型
            NSString *messageType = responseJSON[@"SvcCont"][@"message"][@"messageType"];//文本类型
            NSString *resultCode = responseJSON[@"SvcCont"][@"message"][@"resultCode"];
            
            if (!serviceType) {
                return;
            }
            NSString * operCode = responseJSON[@"SvcCont"][@"message"][@"operCode"];
            if(!messageType && !operCode){
                NSLog(@"无效的消息传递==%@",responseJSON);
                return;
            }
            if(!messageType || [messageType isEqualToString:@""] || [messageType isEqualToString:@"null"]){
                NSLog(@"错误的消息传递==%@",responseJSON);
            }
            
            if ([serviceType isEqualToString:@"back"]) {
                
                if ([messageType isEqualToString:@"bind"] && [resultCode isEqualToString:@"SUCCESS"]) {
                    if (_instance.loginStateBlock) {
                        _instance.loginStateBlock(YES,@"登录socket成功");
                    }
                    ///接收到登录成功的回执,拉去未读消息
                    NSLog(@"开始心跳");
                    [[SGSocketManager shareInstance]startPingTimer];///开始心跳连接
                    [SGSocketBusiness ReceiveSeviceStashMessages];///接受服务器消息
                }else if ([messageType isEqualToString:@"ping"]){
                    ///接收到心跳的回执
                    
                }else{
                    ///接收到发送消息的回执
                    if([responseJSON[@"SvcCont"][@"message"][@"resultMsg"] isEqualToString:@"��Ϣ�ѽ���"]){
                        return;
                    }
                    [SGSocketBusiness ReceiveSendDataBack:responseJSON];
                }
            }else if([serviceType isEqualToString:@"notice"]){
                ///接收到通知
                [SGSocketBusiness ReceiveSeviceNotice:responseJSON];
            }else{
                ///接收消息
                [SGSocketBusiness HandleMessageReceiveMsg:responseJSON];
            }
        }
    }
    
}


#pragma mark - 心跳，登录，接收暂存消息报文格式
/**
 登录服务器的报文格式
 */
+ (void)LoginSeviceMessage{
    
    [[NSUserDefaults standardUserDefaults] setObject:[self getStringTimeTamp] forKey:@"SG_ChannelId"];
    NSDictionary *dic = @{@"SvcCont" : @{@"message" : @{@"channelId" : _instance.channelId}},
                          @"TcpCont" : @{@"ServiceType" : @"bind",
                                         @"MsgSender" : _instance.userCode,
                                         @"TransactionID" : [self getUniqueNumberOrMessageID],
                                         @"ChannelId" : _instance.channelId,
                                         @"SendTime" : [self getStringTimeTamp]
                                         }};
    [self  SendDataWithData:dic];
}

/**
 接收服务器上暂存的消息的报文格式
 */
+ (void)ReceiveSeviceStashMessages{
    NSDictionary *dic = @{@"SvcCont" : @{@"message" : @{}},
                          @"TcpCont" : @{@"ServiceType" : @"receive",
                                         @"MsgSender" : _instance.userCode,
                                         @"TransactionID" : [self getUniqueNumberOrMessageID],
                                         @"ChannelId" : _instance.channelId,
                                         @"SendTime" : [self getStringTimeTamp]
                                         }};
    
    [self SendDataWithData:dic];
}

/**
 Ping服务器的报文格式
 */
+ (void)PingSeviceMessage{
    
    NSDictionary *dic = @{@"SvcCont" : @{@"message" : @{@"channelId" : _instance.channelId}},
                          @"TcpCont" : @{@"ServiceType" : @"ping",
                                         @"MsgSender" : _instance.userCode,
                                         @"TransactionID" : [self getUniqueNumberOrMessageID],
                                         @"ChannelId" : _instance.channelId,
                                         @"SendTime" : [self getStringTimeTamp]
                                         }};
    [self SendDataWithData:dic];
}

#pragma mark - 对象实例化
+ (instancetype)shareInstance{
    if(_instance){///之所以多次一举是觉得每次都调用allocWithZone方法会浪费时间
        return _instance;
    }else{
        return  [[self alloc]init];
    }
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [super allocWithZone:zone];
            _instance.socketManage = [SGSocketManager shareInstance];
            _instance.socketManage.delegate = _instance;
        }
    });
    return _instance;
}


#pragma mark - 帮助方法

///根据时间生成后四位随机的一大串数字
+(NSString *)getUniqueNumberOrMessageID{
    NSString *string = @"11";
    NSDate * senddate = [NSDate date];
    //创建一个日期，然后拿到时间戳
    NSDateFormatter * dateformatter = [[NSDateFormatter alloc]init];
    [dateformatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString *dataTime = [dateformatter stringFromDate:senddate];
    string= [string stringByAppendingString:dataTime];
    
    NSString * x = @"";
    for (int i = 0; i < 4; i ++){
        int a = arc4random()%9;
        x = [x stringByAppendingString:[NSString stringWithFormat:@"%d",a]];
    }
    string = [string stringByAppendingString:x];
    return string;
}

///获取字符串类型时间戳
+(NSString *)getStringTimeTamp{
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
    NSString *string = [NSString stringWithFormat:@"%.f",interval];
    return string;
}

@end
