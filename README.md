##iOS-Socket基于CocoaAsyncSocket的再次封装

---

此文是针对于我当前在公司的项目而写，因为每个公司服务器使用的报文格式不用，所以不具有通用性，各位需要的话看看逻辑就行。切勿直接拿去使用。

###响应过程

- 根据IP和Port连接上Socket
- 与服务器商定一个报文协议，发送一个登录报文
- 接收到服务器返回的登录成功报文后开启定时器发送心跳报文
- 因为服务器可能有别人发送的暂存消息，这里也可以发送收取暂存消息的报文来接收暂存数据
- 由于登录可能会出现失败的情况，或者出现掉线的情况，这个时候需要一个重连机制

###文件用处

- **SGSocketConfigM**
- 单例类来存储连接socket的一些配置信息

- **SGSocketManager**
- 实现了socket的连接，断开，重连，消息发送，消息读取功能

- **SGSocketBusiness**
- **这是我自己项目的一个业务处理类，也可以算是一个demo，千万不要往自己项目里直接拖**

**所以各位可以根据自己的报文格式来实现自己的业务处理类**

###细节提示

#####1.工具类中由于类方法比较多，所以涉及到代理的地方需要使用对象，而不能只是单纯的使用self，

+(instancetype)allocWithZone:(struct _NSZone *)zone{
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


#####2.如下方代码，注意这里的流程，先根据ip和port连接上socket，然后使用**[self LoginSeviceMessage]**发送登录报文

/**用户登录*/
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

最后需要在接受数据这里进行处理，接受到服务器发送的登录成功报文后开启心跳，接收未读消息，并且回调，

if ([messageType isEqualToString:@"bind"] && [resultCode isEqualToString:@"SUCCESS"]) {
if (_instance.loginStateBlock) {
_instance.loginStateBlock(YES,@"登录socket成功");
}
///接收到登录成功的回执,拉去未读消息
NSLog(@"开始心跳");
[[SGSocketManager shareInstance]startPingTimer];///开始心跳连接
[SGSocketBusiness ReceiveSeviceStashMessages];///接受服务器消息
}

所以我的项目在需要的时候调用**SGSocketBusiness**的**RequestToLoginWithUserCode**这个方法即可，这里的**userCode**是用户在服务器上的的唯一标识，服务器根据这个标识来推送消息，channelId则是通道号，通常每次登录之后需要存储，以后发送消息的时候都要用到**channelId**。

#####3.关于appendString这个字段

NSString *receiverStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
///大文件因为是分段发送的所以这里进行拼接
self.appendString = [NSString stringWithFormat:@"%@%@",self.appendString,receiverStr];

因为socket一次传递的数据是有字节限制的，所以会出现发送图片或者视频的base64编码的时候会出现传递来的数据格式不对，所以需要使用全局变量存储此处的数据与下次的数据拼接直到出现正确的数据格式为止。

###最终

只是简单的做了一个封装，可以应用在简单场景。需要更复杂的话可以看看[GCDAsyncSocketManager](https://github.com/Yuzeyang/GCDAsyncSocketManager)

###联系方式
- **github：** [大猫传说中的gitHud地址](https://github.com/LucasDang/SGSocketManager)
- **邮箱：** [1030472953@qq.com](1030472953@qq.com)
