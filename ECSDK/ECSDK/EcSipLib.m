//
//  EcSipLib.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "EcSipLib.h"
#import "ESSIPLib/ESSIPLib.h"
#import "Networking/ESNetStatusManager.h"
#import "Third/ESNumberPoolResult.h"
#import "ESConfig.h"

#import "Third/ESLocationResult.h"
#import "Third/ESDeptResult.h"
#import "Third/ESContactResult.h"


#import "Utils/NSData+JXEncrypt.h"
#import "Utils/NSString+Encrypt.h"


#import "AFNetworking/AFNetworking.h"

/**
 *  注册主服务器
 */
#define REGISTER_DOMAIN_SBCMAIN     0
/**
 *  注册备服务器
 */
#define REGISTER_DOMAIN_SBCBACK     1

#define REGISTER_RETRY_MAX  2

@interface EcSipLib() <ESSIPLibDelegate>
//定义ESPJSIP栈对象
@property (nonatomic, strong) ESSIPLib         *essipLib;
//定义登陆用户属性
@property (nonatomic, strong) ESAccount *accountInfo;
@property (nonatomic, strong) ESCallInfo  *voipCallInfo;

@property (nonatomic, retain) ESNumberPoolReturn* numberPoolResult;

//网络状态监控组件
@property (nonatomic, strong) ESNetStatusManager *netManager;
@property (nonatomic, strong) ESConfig* config;
@property (nonatomic, readwrite) int serverState; // 以 REGISTER_DOMAIN_ 开头的常量
@property (nonatomic, readwrite) int retryCount;

//号码池心跳定时器
@property (nonatomic, retain) NSTimer* numberPoolHeartbeatTimer;
@property (nonatomic, retain) NSURLSessionDataTask* numberPoolRequestTask;

//回调
@property (nonatomic, copy) void(^loginResultBlock)(BOOL resultFlag,NSString *error);

//将界面对象传入
@property (weak) UIViewController *uvController;

@end


@implementation EcSipLib

@synthesize externalAppObserver = _externalAppObserver;
@synthesize numberPoolResult, numberPoolHeartbeatTimer, serverState, retryCount;

//初始化单例
+ (EcSipLib *)getInstance {
    static EcSipLib *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[EcSipLib alloc] init];
        instance.externalAppObserver = nil;
    });
    return instance;
}

//初始化EcSipLib对象 根据 输入的信息初始化后同时完成一个位置查询回调
- (int)initSDK:(NSString *)extNo extPwd:(NSString *)extPwd domain:(NSString *)domain{
    // 初始化属性
    self.isCallingFlag = NO;
    self.serverState = REGISTER_DOMAIN_SBCMAIN;
    self.retryCount = 0;
    self.netManager = [ESNetStatusManager sharedInstance];
    
    [self.netManager startObserveNetworkStatus];
    
    // 加载配置文件
    NSString* path = [[NSBundle mainBundle] pathForResource:@"ecsdk_config" ofType:@"json"];
    
    if(path == nil) {
        NSLog(@"Config file not found");
        return -1;
    }
    
    NSData* jsonData = [NSData dataWithContentsOfFile:path];
    NSError* error = nil;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:(NSJSONReadingMutableContainers) error:&error];
    self.config = [[ESConfig alloc] initWithDictionary:jsonObject];
    NSLog(@"Read config: version: %@", [self.config version]);
    
    // 查询位置信息
    [self queryLocation:extNo extPwd:extPwd domain:domain];
    
    // 初始化 ESSIPLib 对象
    if (!self.essipLib) {
        // 配置 ESSIPLib 的设置项
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [paths objectAtIndex:0];
        
        NSDictionary* settings = @{
            SETTINGS_APP_OBSERVER: self,
            SETTINGS_APP_LOG_LEVEL: [NSNumber numberWithInt:4],
            SETTINGS_APP_DIRECTORY: docDir,
            SETTINGS_OWN_WORKER_THREAD: [NSNumber numberWithBool:false],
            SETTINGS_PROTOCOL: self.config.eslib.transType,
            SETTINGS_VAD: [NSNumber numberWithBool:self.config.eslib.vad],
            SETTINGS_MEDIA_TRANSPORT_ADDRESS: self.config.eslib.mediaTransportAddress,
            SETTINGS_MEDIA_TRANSPORT_PORT: [NSNumber numberWithInt:self.config.eslib.mediaTransportPort],
            SETTINGS_NAT_TYPE: [NSNumber numberWithInt:self.config.eslib.natType],
            SETTINGS_NAT_ICE_ENABLE: [NSNumber numberWithBool:self.config.eslib.natIceEnable],
            SETTINGS_NAT_TURN_ENABLE: [NSNumber numberWithBool:self.config.eslib.natTurnEnable],
            SETTINGS_NAT_REWRITE_USE: [NSNumber numberWithInt:self.config.eslib.natRewriteUse],
            SETTINGS_SRTP_USE: [NSNumber numberWithInt:self.config.eslib.srtpUse],
            SETTINGS_AUTO_RECORD: [NSNumber numberWithBool:NO],
            SETTINGS_PAYLOADTYPES: self.config.payloadTypes,
            SETTINGS_CONTACT_REWRITE_USE: [NSNumber numberWithInt:self.config.eslib.contactRewriteUse],
            SETTINGS_VIA_REWRITE_USE: [NSNumber numberWithInt:self.config.eslib.viaRewriteUse],
        };
        
        // 初始化 ESSIPLib
        self.essipLib = [ESSIPLib getInstance];
        
        error = nil;
        if (![self.essipLib init:settings error:&error]){
            return -1;
        }
    }
    
    return 0;
}

- (int)destory {
    NSError *error = nil;
    if (self.essipLib) {
        [self.essipLib destroy:&error];
        self.essipLib = nil;
    }
    return 0;
}

//登陆语音账号
- (int)register:(NSString *)extNo extPwd:(NSString *)extPwd domain:(NSString *)domain sipHost:(NSString *)sipHost sipPort:(int)sipPort  {
    // 检查参数
    if (extNo.length == 0 || extPwd.length == 0 || domain.length == 0 || sipHost.length == 0) {
        return -1;
    }
    
    //将登陆的参数赋值给softphone进行登录后续操作
    if (!self.accountInfo) {
        self.accountInfo = [[ESAccount alloc] init];
    }
    self.accountInfo.userName   = extNo;
    self.accountInfo.password   = extPwd;
    self.accountInfo.domain     = domain;
    self.accountInfo.sipHost     = sipHost;
    self.accountInfo.sipPort     = sipPort;
    
    //启动网络监听服务
    [_netManager startObserveNetworkStatus];
    
    // 使用ESLib库的registerUser方法进行注册
    NSError* error = nil;
    [self.essipLib registerUser:self.accountInfo.userName password:self.accountInfo.password domain:self.accountInfo.domain sipHost:self.accountInfo.sipHost sipPort:self.accountInfo.sipPort  error:&error];
    // 返回结果
    return error ? -1 : 0; // 注册失败返回 -1，否则返回 0
    
}

// 注销语音账号
- (int)unRegister {
    // 挂断所有电话
    [self hangupAll];
    
    // 使用 ESLib 库的 unregister 方法进行注销
    [self.essipLib unregister];
    
    // 返回结果
    return 0; // 返回成功状态
}

#pragma mark 语音操作


//呼叫用户
- (int)makeCall:(NSString *)destUrl
{
    return [self makeCall:destUrl userData:nil];
}

//该函数是一个发起 VoIP 电话呼叫的方法，其功能如下：
//如果当前正在通话中，则先挂断所有电话；
//设置当前状态为呼叫中；
//打开近距离传感器，使界面变亮；
//注册 UIApplicationWillTerminateNotification 通知，该通知会在应用程序即将终止时挂断音频通话；
//监听网络状态变化，如果网络状态无法连接则进行挂断和释放操作；
//定义 VoIP 电话呼叫的信息，包括呼叫的 ID 和对方电话号码以及用户数据等；
//调用 ESLib 库的 makeCall 方法进行呼叫；
//返回呼叫的 ID。
//总的来说，该函数实现了对 VoIP 电话的呼叫处理，其中对网络状态变化的判断以及通话的状态控制等都是比较重要的。
- (int)makeCall:(NSString *)remoteNumber userData:(NSDictionary *)userData {
    // 如果当前正在通话中，先挂断所有电话
    if (self.isCallingFlag) {
        [self hangupAll];
    }
    //设置当前为呼叫中的状态
    self.isCallingFlag = YES;
    
    //打开近距离传感器，使界面变亮
    dispatch_async(dispatch_get_main_queue(), ^{
        [self changeProximityMonitorEnableState:YES];
    });
    
    // 注册UIApplicationWillTerminateNotification通知，用于在应用程序即将终止时挂断语音
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    
    __weak typeof(self) weakSelf = self;
    
    __block BOOL isNotReachable = NO;
    //如果网络状态无法可达，进入挂断和释放操作
    self.netManager.netStatusBlock = ^(ESNetStatus netStatus) {
        if (netStatus == ESNetStatusNotReach) {
            NSLog(@"makecall ESNetStatusNotReach");
            isNotReachable = YES;
            if (weakSelf && isNotReachable) {
                [weakSelf hangupAll];
            }
        }
    };
    
    //定义当前的呼叫信息
    if (!self.voipCallInfo) {
        self.voipCallInfo = [[ESCallInfo alloc] init];
        self.voipCallInfo.callID = INVALID_CALL_ID;
    }
    
    self.voipCallInfo.remoteInfo = remoteNumber;
    
    // 将用户数据添加到呼叫信息中
    if (userData) {
        NSMutableDictionary* targetUserData = (NSMutableDictionary*)self.voipCallInfo.userData;
        for (id key in userData) {
            if (!key || ![userData objectForKey:key])
                continue;
            [targetUserData setObject:[userData objectForKey:key] forKey:key];
        }
    }
    // 调用ESLib库的makeCall方法进行呼叫
    NSError *error = nil;
    int callID = [self.essipLib makeCall:self.voipCallInfo.remoteInfo error:&error];
    // 返回呼叫ID
    
    if (callID > 0) {
        return callID;
    } else {
        return isNotReachable ? -2 : -1;
    }
}

- (void)callUserAfterRegistered {
    if (self.voipCallInfo) {
        NSError *error = nil;
        //        int callId = [self.essipLib makeCall:self.voipCallInfo.remoteInfo error:&error];
        
        NSMutableDictionary* userData = (NSMutableDictionary*)self.voipCallInfo.userData;
        [userData setObject:self.numberPoolResult.data.data.dnsnumber forKey:@"ESSIPLIB_NP_ANI"];
        [userData setObject:self.voipCallInfo.remoteInfo forKey:@"ESSIPLIB_NP_DNIS"];
        
        int callId = [self.essipLib makeCall:self.voipCallInfo.remoteInfo userData:self.voipCallInfo.userData error:&error];
        self.voipCallInfo.callID = callId;
    }
}

//挂断当前的呼叫
- (int)hangupAll{
    //修改当前的标记
    self.isCallingFlag = NO;
    
    // 如果网络状态无法可达，进入挂断和释放操作
    if (self.netManager.currentNetStatus == ESNetStatusNotReach) {
        // 直接返回成功状态，不挂断电话
        NSLog(@"hangupAll ESNetStatusNotReach -2");
        return -2;
    }
    
    NSError *error = nil;
    //挂断电话
    [self.essipLib hangUpAll:&error];
    
    self.voipCallInfo = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self changeProximityMonitorEnableState:NO];
    });
    
    //消息通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (error) {
        NSLog(@"%@",error);
        return -1;
    }
    return 0;
}


//挂断当前的呼叫
- (int)hangup:(int)callID{
    //修改当前的标记
    self.isCallingFlag = NO;
    
    // 如果网络状态无法可达，进入挂断和释放操作
    if (self.netManager.currentNetStatus == ESNetStatusNotReach) {
        // 直接返回成功状态，不挂断电话
        NSLog(@"hangup ESNetStatusNotReach -2");
        return -2;
    }
    
    NSError *error = nil;
    //挂断电话
    [self.essipLib hangUp:callID error:&error];
    
    self.voipCallInfo = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self changeProximityMonitorEnableState:NO];
    });
    
    //消息通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (error) {
        NSLog(@"%@",error);
        return -1;
    }
    
    return 0;
    
}

/** 发送DTMF数据 **/
- (int)sendDTMF:(int)callID digits: (NSString *)digits{
    
    // 如果网络状态无法可达，进入挂断和释放操作
    if (self.netManager.currentNetStatus == ESNetStatusNotReach) {
        // 直接返回成功状态，不挂断电话
        NSLog(@"sendDTMF ESNetStatusNotReach");
        return -2;
    }
    
    NSError *error = nil;
    //调用sdk进行DTMF发送
    [self.essipLib sendDTMFDigits:callID DTMFDigits:digits error:&error];
    if (error) {
        NSLog(@"%@",error);
        return -1;
    }
    return 0;
}


/** 发送DTMF数据 **/
- (int)sendDTMF:(NSString *)digits {
    
    // 如果网络状态无法可达，进入挂断和释放操作
    if (self.netManager.currentNetStatus == ESNetStatusNotReach) {
        // 直接返回成功状态，不挂断电话
        NSLog(@"sendDTMF ESNetStatusNotReach");
        return -2;
    }
    
    NSError *error = nil;
    //调用sdk进行DTMF发送
    [self.essipLib sendDTMFDigits:self.voipCallInfo.callID DTMFDigits:digits error:&error];
    if (error) {
        NSLog(@"%@",error);
        return -1;
    }
    return 0;
}

// 接通语音
- (int)answerCall:(int)callID {
    
    // 如果网络状态无法可达，进入挂断和释放操作
    if (self.netManager.currentNetStatus == ESNetStatusNotReach) {
        // 直接返回成功状态，不挂断电话
        NSLog(@"answerCall ESNetStatusNotReach -2");
        return -2;
    }
    
    //app被杀死挂断语音，释放资源
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    
    NSError *error = nil;
    [self.essipLib answerCall:callID code:1 error:&error];
    if (error) {
        NSLog(@"%@",error);
        return -1;
    }
    return 0;
}

// 接通语音
- (int)answerCall {
    // 如果网络状态无法可达，进入挂断和释放操作
    if (self.netManager.currentNetStatus == ESNetStatusNotReach) {
        // 直接返回成功状态，不挂断电话
        NSLog(@"answerCall ESNetStatusNotReach");
        return -2;
    }
    
    //app被杀死挂断语音，释放资源
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    
    NSError *error = nil;
    [self.essipLib answerCall:self.voipCallInfo.callID code:1 error:&error];
    if (error) {
        NSLog(@"%@",error);
        return -1;
    }
    return 0;
}

- (int)rejectCall:(int)callID{
    
    // 如果网络状态无法可达，进入挂断和释放操作
    if (self.netManager.currentNetStatus == ESNetStatusNotReach) {
        // 直接返回成功状态，不挂断电话
        NSLog(@"rejectCall ESNetStatusNotReach");
        return -2;
    }
    
    //app被杀死挂断语音，释放资源
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    
    NSError *error = nil;
    [self.essipLib rejectCall:callID error:&error];
    if (error) {
        NSLog(@"%@",error);
        return -1;
    }
    return 0;
    
}


//app被杀死挂断，后台关闭应用时处理
- (void)applicationWillTerminate:(UIApplication *)application {
    [self hangupAll];
}

//静音操作
- (void)changeIsSilenceWithFlag:(BOOL)flag {
    [self.essipLib adjustSipMicroLevel:flag?0:1 error:nil];
}


//麦克风音量
- (void)adjustMicroVolume:(CGFloat)microVolume {
    [self.essipLib adjustSipMicroLevel:microVolume error:nil];
}

//语音音量
- (void)adjustSpeakerVolume:(CGFloat)sipSpeakerVolume {
    [self.essipLib adjustSipSpeakerLevel:sipSpeakerVolume error:nil];
}

//检查声音
- (void)checkSoundStatus:(CGFloat)sipSpeakerVolume {
    [self.essipLib adjustSipSpeakerLevel:sipSpeakerVolume error:nil];
}

//是否免提
-(void)changeVoiceWithLoudSpeaker:(BOOL)flag {
    [self.essipLib setSpeakerphoneOn:flag];
}

//提示用户进行麦克风使用授权
- (void)showSetAlertView:(UIViewController *) vc{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"麦克风权限未开启" message:@"麦克风权限未开启，请进入系统【设置】>【隐私】>【麦克风】中打开开关,开启麦克风功能" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //跳入当前App设置界面
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    
    [alertVC addAction:setAction];
    
    [vc presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - 近距离传感器
- (void)changeProximityMonitorEnableState:(BOOL)enable {
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    if ([UIDevice currentDevice].proximityMonitoringEnabled == YES) {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:enable];
    }
}

#pragma mark - ESSIPLibDelegate
-(void)onCallStateChangedHandler:(NSString*)callState number:(NSString*)number callId:(int)callId callType:(int)callType userData:(NSDictionary*)userData startTime:(NSDate*) startTime endTime:(NSDate*) endTime durationTime:(long) durationTime {
    if ([ESCallStateRinging isEqualToString:callState]) {
        NSError *error = nil;
        [self.essipLib answerCall:callId code:CALL_CODE_RINGING error:&error];
    }
    
    if (self.externalAppObserver) {
        [self.externalAppObserver onCallStateChangedHandler:callState
                                                     number:number ? number: @""
                                                     callId:callId
                                                   callType:callType
                                                   userData:userData ? userData: [NSDictionary dictionary]
                                                  startTime:startTime ? startTime : [NSDate dateWithTimeIntervalSince1970:0]
                                                    endTime:endTime ? endTime : [NSDate dateWithTimeIntervalSince1970:0]
                                               durationTime:durationTime];
    }
    
    if ([ESCallStateRegistered isEqualToString:callState]) {
        self.retryCount = 0;
        if (self.voipCallInfo && self.numberPoolResult && self.voipCallInfo.callID == INVALID_CALL_ID) {
            [self callUserAfterRegistered];
        }
    }
    if ([ESCallStateEstablished isEqualToString:callState]) {
    }
    
    if ([ESCallStateReleased isEqualToString:callState]) { // 收到挂断事件的同时，释放号码池
        self.isCallingFlag = NO;
    }
    
    if ([ESCallStateUnregistered isEqualToString:callState]) { // 注销
        // 关闭感应器
        [self performSelectorOnMainThread:@selector(changeProximityMonitorEnableState:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO modes:nil];
    }
}


-(void)onErrorHandler:(int)errorCode errorMessage:(NSString*)errorMessage {
    
    if (ES_CODE_REGISTER_FAIL == errorCode) {
        
        if ([@"Request Timeout:PJSIP_SC_REQUEST_TIMEOUT" isEqualToString:errorMessage]) {
            //[self toggelServerStatus];
            
            if (self.retryCount < REGISTER_RETRY_MAX) {
                //[self registerAfterSwitchServer];
                self.retryCount ++;
                
                if (self.externalAppObserver) {
                    [self.externalAppObserver onErrorHandler:ES_CODE_REGISTER_SERVER_TIMEOUT
                                                errorMessage:[NSString stringWithFormat:@"注册服务器超时, 当前主服务是:%@ 重试次数:%d",
                                                              self.serverState == REGISTER_DOMAIN_SBCMAIN ? @"sbcMain" : @"sbcBackup",
                                                              self.retryCount]];
                }
            } else {
                if (self.externalAppObserver) {
                    [self.externalAppObserver onErrorHandler:ES_CODE_REGISTER_SERVER_TIMEOUT_MAX_RETRY_NUMBER
                                                errorMessage:[NSString stringWithFormat:@"注册服务器超时，已经达到最大次数, 当前主服务是:%@ 重试次数:%d",
                                                              self.serverState == REGISTER_DOMAIN_SBCMAIN ? @"sbcMain" : @"sbcBackup",
                                                              self.retryCount]];
                    
                    self.retryCount = 0;
                }
            }
        }
        else if ([@"Service Unavailable" isEqualToString:errorMessage]) {
            [self.externalAppObserver onErrorHandler:ES_CODE_SERVICE_UNAVAILABLE
                                        errorMessage:errorMessage];
        }
        else {
            if (self.externalAppObserver) {
                [self.externalAppObserver onErrorHandler:errorCode errorMessage:errorMessage];
            }
        }
    }
    else {
        if (self.externalAppObserver) {
            [self.externalAppObserver onErrorHandler:errorCode errorMessage:errorMessage];
        }
    }
}


-(void)onNetworkChangeHandler:(NSString*) networkType {
    if (self.externalAppObserver) {
        [self.externalAppObserver onNetworkChangeHandler:networkType];
    }
}


- (void)accountRegisterEventHandler:(int)accountID registrationStateCode:(int)registrationStateCode {
    if (self.externalAppObserver) {
        [self.externalAppObserver accountRegisterEventHandler:accountID registrationStateCode:registrationStateCode];
    }
}

-(void) callComingEventHandler:(int)accountID callID:(int)callID displayName:(NSString*)displayName{
    if (self.externalAppObserver) {
        [self.externalAppObserver callComingEventHandler:accountID callID:callID displayName:displayName];
    }
}

-(void) callDisconnectedEventHandler:(int)accountID callID:(int)callID callStateCode:(int)callStateCode callStatusCode:(int)callStatusCode connectTimestamp:(int)connectTimestamp isLocalHold:(int)isLocalHold isLocalMute:(int)isLocalMute{
    if (self.externalAppObserver) {
        [self.externalAppObserver callDisconnectedEventHandler:accountID callID:callID callStateCode:callStateCode callStatusCode:callStatusCode connectTimestamp:connectTimestamp isLocalHold:isLocalHold isLocalMute:isLocalMute];
    }
}


-(void) callEarlyEventHandler:(int)callID {
    if (self.externalAppObserver) {
        [self.externalAppObserver callEarlyEventHandler:callID];
    }
}


-(void) callConfirmedEventHandler:(int)callID {
    if (self.externalAppObserver) {
        [self.externalAppObserver callConfirmedEventHandler:callID];
    }
}


-(void) callOutEventHandler:(int) callID{
    if (self.externalAppObserver) {
        [self.externalAppObserver callOutEventHandler:callID];
    }
}



-(void) stackStatusEventHandler:(int) started{
    if (self.externalAppObserver) {
        [self.externalAppObserver stackStatusEventHandler:started];
    }
}

-(void) locationEventHandler:(NSObject*) location{
    if (self.externalAppObserver) {
        [self.externalAppObserver locationEventHandler:location];
    }
}


-(void) deptEventHandler:(NSMutableArray*) deptList{
    if (self.externalAppObserver) {
        [self.externalAppObserver deptEventHandler:deptList];
    }
}

-(void) contactEventHandler:(NSMutableArray*) contactList{
    if (self.externalAppObserver) {
        [self.externalAppObserver contactEventHandler:contactList];
    }
}



#pragma make -Location

//这段代码包含了三个方法用于查询位置信息、部门列表和联系人列表。核心代码通过 AFNetworking 进行了网络请求，请求方式都是 POST 请求，参数都传递为字典形式。
//以查询位置信息的方法 queryLocation:extPwd:domain 为例：
//首先构建 NSURLSessionConfiguration。
//通过 AFURLSessionManager 来管理请求。
//创建请求 URL，将 auth 后的访问地址和配置中的请求地址拼接起来。
//构建请求头参数，这里只需要 extNo、extPwd 和 domain 参数。
//通过 AFJSONRequestSerializer 请求序列化器的方法 requestWithMethod:URLString:parameters:error: 来构建出一个 POST 请求。
//调用 dataTaskWithRequest:completionHandler: 来执行请求任务，并在 completion block 中处理请求结果。

/**
 查询位置信息
 @param extNo 授权账号
 @param extPwd 授权密码
 @param domain 授权后的访问地址
 */
- (void) queryLocation:(NSString *)extNo extPwd:(NSString *)extPwd domain:(NSString *)domain {
    NSLog(@"queryLocation");
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", self.config.esapi.location]];
    
    
    NSMutableDictionary *para = [[NSMutableDictionary alloc] init];
    
    //参数
    [para setObject:extNo forKey:@"extNo"];
    [para setObject:extPwd forKey:@"extPwd"];
    [para setObject:domain forKey:@"domain"];
    
    NSURLRequest *request = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:[url absoluteString] parameters:para error:nil];
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        
        if (error) {
            
            NSLog(@"Error: %@", error);
            
            NSMutableArray* runsArray = [[NSMutableArray alloc] init];
            
            [runsArray addObject:error];
            
            [[EcSipLib getInstance] locationEventHandler:runsArray];
            
            
        } else {
            NSLog(@"%@-%@", response, responseObject);
            ESLocationResult *value = [[ESLocationResult alloc] initWithDictionary:responseObject];
            
            NSLog(@"%@", value.data);
            
            NSLog(@"%@", value.data.locationList);
            
            [[EcSipLib getInstance] locationEventHandler:value.data.locationList];
            
        }
        //return 0;
    }];
    //self.numberPoolRequestTask = dataTask;
    [dataTask resume];
    //return 0;
}


- (void) queryDeptList:(NSString *)extNo extPwd:(NSString *)extPwd domain:(NSString *)domain {
    NSLog(@"queryDeptList");
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", self.config.esapi.deptList]];
    
    NSMutableDictionary *para = [[NSMutableDictionary alloc] init];
    
    //参数
    [para setObject:extNo forKey:@"extNo"];
    [para setObject:extPwd forKey:@"extPwd"];
    [para setObject:domain forKey:@"domain"];
    
    NSURLRequest *request = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:[url absoluteString] parameters:para error:nil];
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        if (error) {
            
            NSLog(@"Error: %@", error);
            
            NSMutableArray* runsArray = [[NSMutableArray alloc] init];
            
            [runsArray addObject:error];
            
            [[EcSipLib getInstance] deptEventHandler:runsArray];
        } else {
            NSLog(@"%@-%@", response, responseObject);
            
            
            ESDeptResult *value = [[ESDeptResult alloc] initWithDictionary:responseObject];
            
            
            NSLog(@"%@", value.data);
            
            NSLog(@"%@", value.data.deptList);
            
            if (!value.resCode || !value.data ) {
                //没数据  返回  -1 的0数据
                //return -1;
            }
            [[EcSipLib getInstance] deptEventHandler:value.data.deptList];
        }
        //return 0;
    }];
    //self.numberPoolRequestTask = dataTask;
    [dataTask resume];
    //return 0;
}


- (void) queryContactList:(NSString *)extNo extPwd:(NSString *)extPwd domain:(NSString *)domain deptId:(NSString *)deptId {
    NSLog(@"queryContactList");
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", self.config.esapi.contactList]];
    
    NSMutableDictionary *para = [[NSMutableDictionary alloc] init];
    
    //参数
    [para setObject:extNo forKey:@"extNo"];
    [para setObject:extPwd forKey:@"extPwd"];
    [para setObject:domain forKey:@"domain"];
    [para setObject:deptId forKey:@"deptId"];
    
    NSURLRequest *request = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:[url absoluteString] parameters:para error:nil];
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        if (error) {
            
            NSLog(@"Error: %@", error);
            
            NSMutableArray* runsArray = [[NSMutableArray alloc] init];
            
            [runsArray addObject:error];
            
            [[EcSipLib getInstance] contactEventHandler:runsArray];
            
        } else {
            NSLog(@"%@-%@", response, responseObject);
            
            
            ESContactResult *value = [[ESContactResult alloc] initWithDictionary:responseObject];
            
            NSLog(@"%@", value.data);
            
            NSLog(@"%@", value.data.contactList);
            
            
            if (!value.resCode || !value.data) {
                //没数据  返回  -1 的0数据
                //return -1;
            }
            
            [[EcSipLib getInstance] contactEventHandler:value.data.contactList];
            
        }
        //return 0;
    }];
    //self.numberPoolRequestTask = dataTask;
    [dataTask resume];
    //return 0;
}

#pragma mark -

@end

