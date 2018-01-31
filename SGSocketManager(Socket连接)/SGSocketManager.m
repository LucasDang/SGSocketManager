//
//  SGSocketManager.m
//  SGChat_iOS
//
//  Created by ShangGuo on 2018/1/30.
//  Copyright © 2018年 Seocoo. All rights reserved.
//

#import "SGSocketManager.h"
#import "GCDAsyncSocket.h"

@interface SGSocketManager()<GCDAsyncSocketDelegate>

@property (nonatomic,strong)GCDAsyncSocket * socket;
@property(nonatomic ,strong)NSTimer  * pingTimer;///心跳定时器
@property(nonatomic ,strong)NSTimer  * reconnectTimer;///断线重连定时器
@property(nonatomic ,assign)int reconnectNum;///当前重连的连接次数
@property(nonatomic,strong)SGSocketConfigM * configM;
@property(nonatomic,assign)SGSocketConnectState connectState;

@property(nonatomic,copy)SocketConnectResponseBlock connectBlock;
@end

static SGSocketManager * _instance = nil;

@implementation SGSocketManager

#pragma mark - 业务方法
+ (SGSocketConnectState)SocketConnectState{
    if (!_instance) {
        return SGSocketConnectState_NotConnect;
    }else{
        return _instance.connectState;
    }
}

+ (void)ConnectSocketWithConfigM:(SGSocketConfigM*)configM complation:(SocketConnectResponseBlock)complation{
    [SGSocketManager shareInstance].configM = configM;
    [SGSocketManager shareInstance].connectBlock = complation;
    if ([SGSocketManager shareInstance].connectState == SGSocketConnectState_NotConnect ||
        [SGSocketManager shareInstance].connectState == SGSocketConnectState_ConnectFail) {
        _instance.connectState = SGSocketConnectState_Connecting;
        
        NSError *error;
        if (![SGSocketManager shareInstance].socket) {
            [SGSocketManager shareInstance].socket = [[GCDAsyncSocket alloc] initWithDelegate:_instance delegateQueue:dispatch_get_main_queue()];
        }
        if(![[SGSocketManager shareInstance].socket connectToHost:configM.ip onPort:configM.port withTimeout:configM.timeout error:&error]){
            complation(error);
        }
    }
}

+ (void)DisConnectSocket{
    if ([SGSocketManager shareInstance].connectState == SGSocketConnectState_Connecting ||
        [SGSocketManager shareInstance].connectState == SGSocketConnectState_ConnectSuccess ||
        [SGSocketManager shareInstance].connectState == SGSocketConnectState_ReConnecting) {
        
        [[SGSocketManager shareInstance].socket disconnect];
        [SGSocketManager shareInstance].connectState = SGSocketConnectState_NotConnect;
        ///关闭定时器
        [[SGSocketManager shareInstance] stopPingTimer];
        
    }
}

/**
 *  写入数据
 *    这里注意需要将请求体以##@@\n结果，这是与后台约定好的数据格式
 *  @param dic 请求体
 */
+ (void)SendDataWithData:(NSMutableArray*)dic{
    NSData *endStringData = [@"##@@\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *sendData = [[NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil] mutableCopy];
    [sendData appendBytes:endStringData.bytes length:endStringData.length];
    [[SGSocketManager shareInstance].socket writeData:sendData withTimeout:-1 tag:0];
}


#pragma mark GCDAsyncSocketDelegate
/**
 *  连接成功
 *
 *  @param sock  socket
 *  @param host   host
 *  @param port   port
 */
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    [_socket readDataWithTimeout:-1 tag:0];
    _instance.connectState = SGSocketConnectState_ConnectSuccess;
    if(_reconnectTimer){
        [self stopReconnectTimer];
    }
    
    if (self.connectBlock) {
        self.connectBlock(nil);
    }
    if ([self.delegate respondsToSelector:@selector(socketManagerSuccessToConnectWithConfigM:)]) {
        [self.delegate socketManagerSuccessToConnectWithConfigM:self.configM];
    }
}

/**
 *  连接失败回调
 *    这里判断错误类型，选择重新连接或者提示用户
 *  @param sock  socket
 *  @param error   error
 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error{
    
    if (error) {
        NSLog(@"连接失败 - 错误为：%@",error);
        
        _instance.connectState = SGSocketConnectState_ConnectFail;
        
        ///连接失败回调
        if (self.connectBlock) {
            self.connectBlock(error);
        }
        if([[SGSocketManager shareInstance].delegate respondsToSelector:@selector(socketManagerFailToDisconnectWithConfigM:error:)]){
            [[SGSocketManager shareInstance].delegate socketManagerFailToDisconnectWithConfigM:self.configM error:error];
        }
        
        ///开启重连
        [self startReconnectTimer];
    }else{
        ///主动断开连接
         _instance.connectState = SGSocketConnectState_NotConnect;
    }
    ///心跳删除
    if (_pingTimer) {
        [self stopPingTimer];
    }
    
}

/**
 *  接受数据
 *    这里如果收到的是消息回执则将数据直接传给业务层做处理，其他回执这里直接处理
 *  @param sock  socket
 *  @param data  data
 *  @param tag   tag
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    [_socket readDataWithTimeout:-1 tag:0];
    if ([self.delegate respondsToSelector:@selector(socketManagerSuccessToReceiveMsg:withTag:)]) {
        [self.delegate socketManagerSuccessToReceiveMsg:data withTag:tag];
    }
}

/**
 *  写入数据成功
 *    发送消息之后需要来这里判断消息是否发送成功,但是这里不弄那么复杂了。直接根据回执判断消息的发送情况
 *  @param sock  socket
 *  @param tag   tag
 */
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    if ([self.delegate respondsToSelector:@selector(socketManagerSuccessToWriteDataWithTag:)]) {
        [self.delegate socketManagerSuccessToWriteDataWithTag:tag];
    }
}

#pragma  mark - 对象单例初始化方法
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
            ///初始化管理对象的时候即初始化socket对象，这样可以保证永远只有一个管理对象和socket对象
            ///!注意这里delegate给的是_instance实例对象，不能是self
            _instance.socket = [[GCDAsyncSocket alloc] initWithDelegate:_instance delegateQueue:dispatch_get_main_queue()];
            _instance.connectState = SGSocketConnectState_NotConnect;
        }
    });
    return _instance;
}

#pragma  mark - 心跳定时器
- (void)startPingTimer{
    if (_instance) {
        _instance.pingTimer = [NSTimer scheduledTimerWithTimeInterval:_instance.configM.pingTimeInterval target:self selector:@selector(pingTimerAction) userInfo:nil repeats:true];
        /** 防止强引用 */
        [[NSRunLoop currentRunLoop] addTimer:_instance.pingTimer forMode:NSRunLoopCommonModes];
        [_instance.pingTimer fire];
    }
}

- (void)stopPingTimer{
    [_pingTimer invalidate];
    _pingTimer = nil;
}

- (void)pingTimerAction{
    if ([[SGSocketManager shareInstance].delegate respondsToSelector:@selector(socketManagerPingTimerAction)]) {
        [[SGSocketManager shareInstance].delegate socketManagerPingTimerAction];
    }
}

#pragma mark - socket重连

/**
 开启定时器发送重连
 */
- (void)startReconnectTimer{
    if(!_reconnectTimer){
        _reconnectNum = 0;
        _reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:_instance.configM.reconnectTimeInterval target:self selector:@selector(reconnectTimerAction) userInfo:nil repeats:true];
        /** 防止强引用 */
        [[NSRunLoop currentRunLoop] addTimer:_reconnectTimer forMode:NSRunLoopCommonModes];
        [_instance.pingTimer fire];
    }else{
        ///重连次数超过了限制，关闭重连定时器
        if(_reconnectNum > _configM.reconnectTime){
            [self stopReconnectTimer];
        }
    }
}

- (void)reconnectTimerAction{
    _reconnectNum ++;
    [SGSocketManager ConnectSocketWithConfigM:_configM complation:nil];
}

- (void)stopReconnectTimer{
    [_reconnectTimer invalidate];
    _reconnectTimer = nil;
    _reconnectNum = 0;
}
#pragma mark - 帮助方法

@end
