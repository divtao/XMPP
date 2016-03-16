
//https://www.cocoanetics.com/2012/07/you-dont-need-the-xcode-command-line-tools/

//http://akinliu.github.io/2014/05/03/cocoapods-specs-/

//  ViewController.m
//  XMPP
//
//  Created by DivTao on 16/3/6.
//  Copyright © 2016年 HT. All rights reserved.
//
//导入XMPP文件
#import <XMPP.h> //基本类在这个里面
#import <XMPPRoster.h>//好友管理类
#import <XMPPRosterCoreDataStorage.h>//管理好友数据库存储
#import "ViewController.h"

#define HOST @"1000phone.net"//千峰遵循XMPP协议的域名服务器


@interface ViewController ()<XMPPStreamDelegate>
//数据流 数据通道 用来 接收和发送数据
@property (nonatomic, strong) XMPPStream * stream;
//好友管理类
@property (nonatomic, strong) XMPPRoster * roster;


@property (weak, nonatomic) IBOutlet UITextField *zhaohaoText;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *friendText;
@property (weak, nonatomic) IBOutlet UITextField *messageText;
@property (weak, nonatomic) IBOutlet UITextView *allMessage;



@end

@implementation ViewController
//登陆方法
- (IBAction)login:(id)sender {
    if (_stream.isConnected){
        [self geOffLine];//不允许本地同时登陆二个账号。
    }
    //用户名@服务器名
    XMPPJID * jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@", _zhaohaoText.text, HOST]];
    //绑定账号
    [_stream setMyJID:jid];
    //在代理中区分连接类型标记
    _stream.tag = @"登陆";
    //发起连接
    [_stream connectWithTimeout:10 error:nil];
    
}
//注册点击方法
- (IBAction)registure:(id)sender {
    
    
    if (_stream.isConnected) {
        [self geOffLine];//下线 断开连接
    }
    
    // 用户名 指定 用户名@服务器域名( 统一的规定，用来区分不同服务器中的相同用户名)
    //注册账号
    XMPPJID * jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@", _zhaohaoText.text, HOST]];
    
    //设置账号
    [_stream setMyJID:jid];
    
    _stream.tag = @"注册";//用来区分当前发送类型的请求
    //连接服务器  会通过代理告诉是否连接成功
    [_stream connectWithTimeout:-1 error:nil];
    
}
//添加好友
- (IBAction)addFriend:(id)sender {
    
    //添加好友
    [_roster subscribePresenceToUser:[XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@", _friendText.text, HOST]]];
}
//
- (IBAction)sendMessage:(id)sender {
    //给好友发送信息，首先要知道好友是谁
    XMPPJID * jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@", _friendText.text, HOST]];
    //chat 单聊
    //room 群组聊天
    
    //创建消息对象
    XMPPMessage * message = [XMPPMessage messageWithType:@"chat" to:jid];
    //创建消息体
    DDXMLElement * body = [XMPPElement elementWithName:@"body" stringValue:_messageText.text];
    [message addChild:body];//添加子节点
    
    //发送消息
    [_stream sendElement:message];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    创建流
    [self createStream];
    
}

- (void)createStream{
    //创建流对象
    _stream = [[XMPPStream alloc] init];
    
    //设置代理
    [_stream addDelegate:self delegateQueue:dispatch_get_main_queue()];//指定代理方法 在哪个队列中执行
    XMPPRosterCoreDataStorage * storage = [[XMPPRosterCoreDataStorage alloc] init];
    
    //创建好友管理类需要存储 XMPPRosterStorger
    _roster = [[XMPPRoster alloc] initWithRosterStorage:storage];
    
    //绑定好友管理类到流中
    [_roster activate:_stream];
    
    
}
#pragma mark--上线
- (void) getOnline{
    /**
     type 用户的状态
     
     available 上线
     unavailable 离线
     away 离开
     do not disturb 忙碌
     */
    XMPPPresence * pressence = [XMPPPresence presenceWithType:@"available"];
    //通过流 来发起上线请求
    [_stream sendElement:pressence];
}

#pragma mark--下线
- (void)geOffLine{
    XMPPPresence * pressence = [XMPPPresence presenceWithType:@"unavailable"];
    //发起下线请求
    [_stream sendElement:pressence];
    //断开与服务器的连接
    [_stream disconnect];
}
#pragma mark--注册成功 代理
- (void)xmppStreamDidRegister:(XMPPStream *)sender{
    NSLog(@"注册成功");
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error{
    NSLog(@"注册失败%@", error);
}

#pragma mark--登陆成功 代理
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    NSLog(@"登陆成功");
    //登陆成功， 用户处于上线状态
    [self getOnline];
}
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error{
    NSLog(@"登陆失败");
}

#pragma mark--连接服务器 代理
//连接到了服务器
- (void)xmppStreamDidConnect:(XMPPStream *)sender{
    NSLog(@"已经连接到服务器");
    if ([sender.tag isEqualToString:@"注册"]) {
        //进行注册
        [_stream registerWithPassword:_password.text error:nil];
    }else if ([sender.tag isEqualToString:@"登陆"]){
        
        //进行登陆操作
        [_stream authenticateWithPassword:_password.text error:nil];
    }
}

//
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error{
    NSLog(@"已经断开连接 错误信息%@", error);
}

#pragma mark--收到好友请求  用户登陆也会调用此方法
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence{
    NSLog(@"收到了谁的好友请求%@", presence.from.user);
    
    //添加对方为好友
    [_roster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];//Yes ，把你添加到我的好友列表中， NO， 不添加到我的好友列表
    
    //拒绝添加好友
//    [_roster rejectPresenceSubscriptionRequestFrom:presence.from];
    
    self.allMessage.text = [self.allMessage.text stringByAppendingFormat:@"\n 收到好友请求%@", presence.from.user];
}

#pragma mark--收到消息
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    NSLog(@"收到了消息%@", message);//message 是xml格式的
    //取节点的值
//    NSString * mm = [NSString stringWithFormat:@"来自：%@\n 内容：%@\n", message.from.user, message.body];
    NSString * mm = [NSString stringWithFormat:@"来自：%@\n 内容：%@\n", message.from.user, [message.children[0] stringValue]];
    self.allMessage.text = [self.allMessage.text stringByAppendingString:mm];
    
//    另外一种解析格式
//    [message.children[0] stringValue];
    /*
     
     */
    NSString * typeStr = [message attributeStringValueForName:@"type"];//获取属性值
    
    //获取第一子节点的值
    NSString * body = [message.children[0] stringValue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
