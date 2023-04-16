//
//  ESSIPLib.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESSIPLib.h"

//! Project version number for ESSIPLibCore.
double SIPSDKVersionNumber = 1.0;

//! Project version string for ESSIPLibCore.
const unsigned char SIPSDKVersionString[] = "1.0.0";

#import "ESPJUtils.h"
#import "ESDtmf.h"
#import "ESConstants.h"


#import <pjsua-lib/pjsua.h>
#import <pjsua-lib/pjsua_internal.h>
#import <pjsip/sip_msg.h>
#import "ESPayloadTypes.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <net/if_dl.h>

#import <AVFoundation/AVFoundation.h>
 
#define THIS_FILE   "esphone.c"

//心跳配置
#define KEEP_ALIVE_INTERVAL 600

ESSIPLib * _instance;//pjsip 调用状态

static pj_status_t status;

static pjsip_endpoint*  g_endpoint;        /* SIP endpoint.        */

static pjsua_acc_id acc_id;
static pjsua_config cfg;
static pjsua_logging_config log_cfg;
//udp
static pjsua_transport_config transport_cfg;

static pjsua_transport_config tcp_transport_cfg;
static pjsua_transport_config tls_transport_cfg;

static pjsua_media_config media_cfg;

static pjsua_acc_config acc_cfg;
static pjsua_acc_info acc_info;
static pjsua_call_info call_info;
static pjsua_call_id call_id;

//文本日志模块
extern pjsip_module mod_file_logger_handler;

static FILE *s_sipLogFile = NULL;
static int s_sipLogSocket = -1;

bool isCalling = false;


uint64_t _lastBytes_CheckNetWorkBytes;
uint64_t _lastIncomingBytes_CheckNetWorkBytes;
uint64_t _lastOutgoingBytes_CheckNetWorkBytes;

#define PRODUCT_NAME "ESPhone-iOS"
#define PRODUCT_VER "2.0"

#pragma mark Private Decleration
@interface ESSIPLib ()

@property (nonatomic, strong) ESAccount* softPhoneInfo;
@property (nonatomic, strong) ESCallInfo* voipCallInfo;

@property (atomic) BOOL isSoundEnabled;
@property (atomic) BOOL isInited;
@property (atomic) BOOL isAddedAccount;
@property (atomic) BOOL isRegistered;
@property (atomic) BOOL isLogged;
@property (atomic) int logLevel;
@property (atomic) int natType;
@property (atomic) BOOL natIceEnable;
@property (atomic) BOOL natTurnEnable;
@property (atomic) int natRewriteUse;
@property (strong, nonatomic) NSTimer* statusTimer;

@property (strong, nonatomic) NSString* transType;


@property (strong, nonatomic) NSString* routerNumber;
@property (strong, nonatomic) NSString* mediaTransportAddress;
@property (strong, nonatomic) NSString* appDirectory;
@property (strong, nonatomic) NSString* logFilepath;
@property (strong, nonatomic) NSString* licensePath;
@property (atomic) int mediaTransportPort;
@property (atomic) int srtpUse;
@property (atomic) int contactRewriteUse;
@property (atomic) int viaRewriteUse;
@property (atomic) BOOL vad;
@property (weak, nonatomic) NSTimer* netSpeedTimer;

@property (nonatomic, retain, getter=callingDictinary) NSMutableDictionary* callingDictinary;
@property (nonatomic, retain, getter=accountConfigDictionary) NSMutableDictionary* accountConfigDictionary;


- (void) putCallingId:(pjsua_call_id)callId forCallingInfo:(NSString *)callInfo;
- (pjsua_call_id) callingIdForCallingInfo:(NSString *)callInfo;
- (void) removeCallingIdForCallingInfo:(NSString *)callInfo;
- (void) clearCallingDictionary;

- (void) putAccountConfig:(pjsua_acc_config*)config forAccountId:(pjsua_acc_id)accountId;
- (void) removeAccountId:(pjsua_acc_id)accountId;
- (void) clearAccountConfigDictionary;

- (void) setCodecPriority:(NSArray*)codecs;

- (void) raiseError:(int)code reason:(NSString*)reason;
- (void) raiseCallStateChangedHandler:(NSString*)callState number:(NSString*)number callId:(int)callId callType:(int)callType userData:(NSDictionary*)userData startTime:(NSDate*) startTime endTime:(NSDate*) endTime durationTime:(long) durationTime;
- (void) raiseAgentStateChangedHandler:(int)accountID registrationStateCode:(int)registrationStateCode;

@end

static void on_reg_state(pjsua_acc_id acc_id);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void on_call_media_state(pjsua_call_id call_id);
static void on_reg_info_changed(pjsua_acc_id acc_id, pjsua_reg_info *info);

#pragma mark -

@implementation ESSIPLib

@synthesize callingDictinary = _callingDictinary;
@synthesize accountConfigDictionary = _accountConfigDictionary;
@synthesize microphoneMuted = microphoneMuted_;
@synthesize autoRecord = _autoRecord;
 

@synthesize routerNumber, mediaTransportAddress;
@synthesize netSpeedTimer = _netSpeedTimer;

#pragma mark Static Methods
//+ (NSString *)requestLicense {
//    XLicense sn;
//    sn.SetProductInfo(PRODUCT_NAME, PRODUCT_VER);
//    sn.SetMacAddrType(0);
//    sn.Create();
//    sn.encrypt();
//    string strSn = sn.ToString();
//    NSString* requestContent = [[NSString alloc] initWithCString:strSn.c_str() encoding:NSUTF8StringEncoding];
//    requestContent = [NSString stringWithFormat:@"%@ %@ %@", @PRODUCT_NAME, @PRODUCT_VER, requestContent];
//    return requestContent;
//}

+ (ESSIPLib *) getInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(_instance == nil) {
            _instance = [[ESSIPLib alloc] initPrivate];
        }
    });
    return _instance;
}

 
#pragma mark -
#pragma mark Properties

- (NSMutableDictionary*) callingDictinary {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (self->_callingDictinary == NULL) {
            self->_callingDictinary = [[NSMutableDictionary alloc] init];
        }
    });
    //    NSUbiquitousKeyValueStoreDidChangeExternallyNotification
    return _callingDictinary;
}

- (void) putCallingId:(pjsua_call_id)callId forCallingInfo:(NSString *)callInfo {
    [self.callingDictinary setObject:[NSNumber numberWithInt:callId] forKey:callInfo];
}

- (pjsua_call_id) callingIdForCallingInfo:(NSString *)callInfo {
    NSNumber* callId = (NSNumber*)[self.callingDictinary objectForKey:callInfo];
    if (callId) {
        return callId.intValue;
    }
    return PJSUA_INVALID_ID;
}


- (void) removeCallingIdForCallingInfo:(NSString *)callInfo {
    [self.callingDictinary removeObjectForKey:callInfo];
}

- (void) clearCallingDictionary {
    [self.callingDictinary removeAllObjects];
}

- (NSMutableDictionary*) _accountConfigDictionary {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (self->_accountConfigDictionary == NULL) {
            self->_accountConfigDictionary = [[NSMutableDictionary alloc] init];
        }
    });
    
    return _accountConfigDictionary;
}

- (void) putAccountConfig:(pjsua_acc_config*)config forAccountId:(pjsua_acc_id)accountId {
    [self._accountConfigDictionary setValue:[NSValue valueWithPointer:config] forKey:[NSNumber numberWithInt:accountId].stringValue];
}

- (void) removeAccountId:(pjsua_acc_id)accountId {
    [self->_accountConfigDictionary removeObjectForKey:[NSNumber numberWithInt:accountId].stringValue];
}

- (void) clearAccountConfigDictionary {
    [self._accountConfigDictionary removeAllObjects];
}

#pragma mark -
#pragma mark Instance Methods
// Private instance initiator
- (id) initPrivate {
    self = [super init];
    if(self) {
        self.isSoundEnabled = NO;
        self.isRegistered = NO;
        self.isInited = NO;
        self.isAddedAccount = NO;
        self.isLogged = NO;
        self.logLevel = 4;
        
        self.contactRewriteUse = 0;
        self.viaRewriteUse = 0;
        self.licensePath = nil;
//        self.contactCentreNumber = TEST_SIP_ACCOUNT; // @"9010086";
//        self.agentNumber = TEST_SIP_ACCOUNT;    // @"500817002";
//        self.agentPasscode = TEST_SIP_PWD;      // @"000000";
//        self.sipDomain = TEST_SIP_SERVER;       // @"106.14.215.45:10550";
//        self.sipUser = TEST_SIP_ACCOUNT;        // @"500817002";
//        self.sipPasscode = TEST_SIP_PWD;        // @"000000";
        
        //定义默认的账号信息
//        self.softPhoneInfo.userName = TEST_SIP_ACCOUNT; // @"500817002";
//        self.softPhoneInfo.password = TEST_SIP_PWD;     // @"000000";
//        self.softPhoneInfo.domain = TEST_SIP_SERVER;    // @"106.14.215.45:10550";
//        self.softPhoneInfo.domainPort = TEST_SIP_SERVER_PORT;
        
//        NSError *error = nil;
//        [self init:@{} error:&error];
    }
    return self;
}


//初始化
- (BOOL)init:(NSDictionary*)settings error:(NSError **)error {
    NSLog(@"init");
    
//    if ([settings objectForKey:SETTINGS_APP_OBSERVER])
    NSString* settingKey = nil;
    NSEnumerator* enumerator = settings.keyEnumerator;
    while ((settingKey = (NSString*)enumerator.nextObject)) {
        if ([SETTINGS_APP_OBSERVER isEqualToString:settingKey]) {
            self.delegate = [settings objectForKey:settingKey];
        }
        if ([SETTINGS_PROTOCOL isEqualToString:settingKey]) {
            self.transType = [settings objectForKey:settingKey];
        }
        if ([SETTINGS_APP_LOG_LEVEL isEqualToString:settingKey]) {
            self.logLevel = [[settings objectForKey:settingKey] intValue];
        }
        if ([SETTINGS_APP_DIRECTORY isEqualToString:settingKey]) {
            self.appDirectory = [settings objectForKey:settingKey];
        }
        if ([SETTINGS_APP_LOG_FILEPATH isEqualToString:settingKey]) {
            self.logFilepath = [settings objectForKey:settingKey];
        }
        if ([SETTINGS_VAD isEqualToString:settingKey]) {
            self.vad = [[settings objectForKey:settingKey] boolValue];
        }
        if ([SETTINGS_NAT_TYPE isEqualToString:settingKey]) {
            self.natType = [[settings objectForKey:settingKey] intValue];
        }
        if ([SETTINGS_NAT_ICE_ENABLE isEqualToString:settingKey]) {
            self.natIceEnable = [[settings objectForKey:settingKey] boolValue];
        }
        if ([SETTINGS_NAT_TURN_ENABLE isEqualToString:settingKey]) {
            self.natTurnEnable = [[settings objectForKey:settingKey] boolValue];
        }
        if ([SETTINGS_NAT_REWRITE_USE isEqualToString:settingKey]) {
            self.natRewriteUse = [[settings objectForKey:settingKey] intValue];
        }
        if ([SETTINGS_MEDIA_TRANSPORT_ADDRESS isEqualToString:settingKey]) {
            self.mediaTransportAddress = [settings objectForKey:settingKey];
        }
        if ([SETTINGS_MEDIA_TRANSPORT_PORT isEqualToString:settingKey]) {
            self.mediaTransportPort = [[settings objectForKey:settingKey] intValue];
        }
        if ([SETTINGS_AUTO_RECORD isEqualToString:settingKey]) {
            self.autoRecord = [[settings objectForKey:settingKey] boolValue];
        }
        if ([SETTINGS_AUTO_RECORD isEqualToString:settingKey]) {
            self.autoRecord = [[settings objectForKey:settingKey] boolValue];
        }
        if ([SETTINGS_SRTP_USE isEqualToString:settingKey]) {
            self.srtpUse = [[settings objectForKey:settingKey] intValue];
        }
        if ([SETTINGS_ROUTER_NUMBER isEqualToString:settingKey]) {
            self.routerNumber = [settings objectForKey:settingKey];
        }
        if ([SETTINGS_CONTACT_REWRITE_USE isEqualToString:settingKey]) {
            self.contactRewriteUse = [[settings objectForKey:settingKey] intValue];
        }
        if ([SETTINGS_VIA_REWRITE_USE isEqualToString:settingKey]) {
            self.viaRewriteUse = [[settings objectForKey:settingKey] intValue];
        }
        
        
        
        
        
    }
    
    status = pjsua_create();
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d @status = pjsua_create()\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        [self raiseError:ES_CODE_SIP_INIT_FAIL reason:[NSString stringWithFormat:@"Library Created Failed: %d", status]];
        return NO;
    }
    
    NSLog(@"Init SIPLib");
    
    pjsua_config_default(&cfg);
    
    pjsua_logging_config_default(&log_cfg);
    log_cfg.console_level = self.logLevel;
    log_cfg.level = self.logLevel;
    log_cfg.log_file_flags = PJ_O_APPEND;

    if (self.logFilepath != nil) {
        [ESPJUtils PJStringWithString:self.logFilepath out:&log_cfg.log_filename];
        NSLog(@"%s - %d  log_path = %@", __PRETTY_FUNCTION__, __LINE__, self.logFilepath);
    } else if (self.appDirectory != nil) {
        _logFilepath = [self.appDirectory stringByAppendingString:@"/essip.log"];
        NSLog(@"%s - %d  log_path = %@", __PRETTY_FUNCTION__, __LINE__, self.logFilepath);
        [ESPJUtils PJStringWithString:self.logFilepath out:&log_cfg.log_filename];
    } else {
//        [[[NSBundle mainBundle] folder]
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [paths objectAtIndex:0];
        
        _logFilepath = [docDir stringByAppendingString: @"/essip.log"];
        NSLog(@"%s - %d  log_path = %@", __PRETTY_FUNCTION__, __LINE__, self.logFilepath);
        [ESPJUtils PJStringWithString:self.logFilepath out:&log_cfg.log_filename];
    }

    
    pjsua_media_config_default(&media_cfg);
    
    //媒体配置
    if (self.vad) {
        media_cfg.no_vad = !self.vad;
    }
    
    //调整
    media_cfg.clock_rate = 8000;
    media_cfg.audio_frame_ptime = 40;
    media_cfg.ec_tail_len = 0;
    media_cfg.quality = 3;
    media_cfg.thread_cnt = 2;
    media_cfg.snd_auto_close_time  = 0;
    media_cfg.ilbc_mode = 30;
    
    media_cfg.jb_init = 200;
    media_cfg.jb_min_pre = 80;
    media_cfg.jb_max_pre = 330;
    media_cfg.jb_max = 400;
    
//    cfg.cb.on_reg_state = &on_reg_state;
    cfg.cb.on_call_state = &on_call_state;
    cfg.cb.on_call_media_state = &on_call_media_state;
    cfg.cb.on_incoming_call = &on_incoming_call;
    cfg.cb.on_reg_state2 = &on_reg_info_changed;
    
    pj_str_t ver;
    
    [ESPJUtils PJStringWithString:[NSString stringWithFormat:@"EcSipSdk-EasyCallTech %s", "1.0.0"] out:&ver];
    cfg.user_agent = ver;
    
    status = pjsua_init(&cfg, &log_cfg, &media_cfg);
    if(status != PJ_SUCCESS)
    {
        NSLog(@"%s - %d @pjsua_init(&cfg, &log_cfg, NULL)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        [self raiseError:ES_CODE_SIP_INIT_FAIL reason:[NSString stringWithFormat:@"Library init Failed: %d", status]];
        return NO;
    }
    
    NSLog(@"pjsua_init succeed");
    //创建pjsip的udp传输端口
    
    if ([@"udp" isEqualToString:self.transType]) {
        pjsua_transport_config_default(&transport_cfg);
        
        transport_cfg.port = DEFAULT_SIP_PORT;
        
        transport_cfg.qos_type=PJ_QOS_TYPE_VOICE;
        transport_cfg.qos_params.flags=PJ_QOS_PARAM_HAS_DSCP;
        transport_cfg.qos_params.dscp_val=0x18;
        
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &transport_cfg, NULL);
        if (status != PJ_SUCCESS) {
            NSLog(@"transport_create error");
            [self raiseError:ES_CODE_SIP_INIT_FAIL reason:[NSString stringWithFormat:@"Library creates transports failed: %d", status]];
            return NO;
        }
    } else if ([@"tcp" isEqualToString:self.transType]) {
        //tcp
        
        pjsua_transport_config_default(&tcp_transport_cfg);
        
        tcp_transport_cfg.port = DEFAULT_SIP_PORT+1;
        
        tcp_transport_cfg.qos_type=PJ_QOS_TYPE_VOICE;
        tcp_transport_cfg.qos_params.flags=PJ_QOS_PARAM_HAS_DSCP;
        tcp_transport_cfg.qos_params.dscp_val=0x18;
        
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &tcp_transport_cfg, NULL);
        if (status != PJ_SUCCESS) {
            NSLog(@"tcp_transport_create error");
            [self raiseError:ES_CODE_SIP_INIT_FAIL reason:[NSString stringWithFormat:@"Library creates transports failed: %d", status]];
            return NO;
        }
    }
    else if ([@"tls" isEqualToString:self.transType]) {
        //tls
        
        pjsua_transport_config_default(&tls_transport_cfg);
        
        tls_transport_cfg.port = DEFAULT_SIP_PORT+2;
        
        tls_transport_cfg.qos_type=PJ_QOS_TYPE_VOICE;
        tls_transport_cfg.qos_params.flags=PJ_QOS_PARAM_HAS_DSCP;
        tls_transport_cfg.qos_params.dscp_val=0x18;
        
        status = pjsua_transport_create(PJSIP_TRANSPORT_TLS, &tls_transport_cfg, NULL);
        if (status != PJ_SUCCESS) {
            NSLog(@"tls_transport_create error");
            [self raiseError:ES_CODE_SIP_INIT_FAIL reason:[NSString stringWithFormat:@"Library creates transports failed: %d", status]];
            return NO;
        }
    }
    else {
        NSLog(@"transport config error, transType must be one of udp,tcp,tls");
        [self raiseError:ES_CODE_SIP_INIT_FAIL reason:@"Library creates transports failed: transType must be one of udp,tcp,tls"];
        return NO;
    }
    
    NSLog(@" Initialization is done, now start pjsua ");
    
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d @pjsua_start()\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        [self raiseError:ES_CODE_SIP_INIT_FAIL reason:[NSString stringWithFormat:@"Library start failed: %d", status]];
        return NO;
    }
    
    NSLog(@"pjsua_start succeed");
    
    //注册logger module
    status = pjsip_endpt_register_module( pjsua_get_pjsip_endpt(), &mod_file_logger_handler);
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d @pjsip_endpt_register_module()\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        [self raiseError:ES_CODE_SIP_INIT_FAIL reason:[NSString stringWithFormat:@"Library register module failed: %d", status]];
        return NO;
    }
    
    NSLog(@"pjsip_endpt_register_module succeed");
    
    [self setCodecPriority:[settings objectForKey:SETTINGS_PAYLOADTYPES]];
    
    self.netSpeedTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(getInternetface2) userInfo:nil repeats:YES];
    //初始化流量计算器
    
    [self initCheck];
    
    [self.netSpeedTimer fireDate];
    
    [self raiseCallStateChangedHandler:ESCallStateInited number:nil callId:INVALID_CALL_ID callType:0 userData:nil startTime:nil endTime:nil durationTime:0];
    
    
    [self.delegate stackStatusEventHandler:0];
    
    return YES;
};

//释放
- (BOOL) destroy:(NSError **)error{
    NSLog(@"destory");
    @try {
        [self.netSpeedTimer invalidate];
    } @catch (NSException *exception) {
        
    } @finally {
        self.netSpeedTimer = nil;
    }
    
    [self unregisterFromSipServer];
    
    [self.delegate stackStatusEventHandler:-1];
    return YES;
};

- (void)getInternetface2 {
    NSDictionary* perSecond = [self getNetWorkBytesPerSecond]; //获取当前秒流量
//    NSString *reslut = [NSString stringWithFormat:@"bandwidth:%@/s",[self convertStringWithbyte:perSecond]];
//    NSLog(@"%@",reslut);
    NSString* sendRate = [self convertStringWithbyte:[[perSecond objectForKey:@"tx"] longLongValue]];
    NSString* recieveRate = [self convertStringWithbyte:[[perSecond objectForKey:@"rx"] longLongValue]];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onNetworkChangeHandler:sendRate:recieveRate:)]) {
        @try {
            [self.delegate onNetworkChangeHandler:@"" sendRate:sendRate recieveRate:recieveRate];
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
        } @finally {
            
        }
    }
}

- (int) registerUser:(NSString *)user password:(NSString*)password domain:(NSString*)domain  error:(NSError**)error {
    return [self registerUser:user password:password domain:domain sipHost:domain sipPort:5060 error:error];
}

- (int) registerUser:(NSString *)user password:(NSString*)password domain:(NSString*)domain sipHost:(NSString*)sipHost sipPort:(int)sipPort error:(NSError**)error {
 
    NSLog(@"Register setSipUser:%@ withPassword:* andRealm:%@ onHost:%@ andSipPort:%d withTCPTransport:%@",
          user, domain, sipHost, sipPort, self.transType);
    
    NSString *userId = [NSString stringWithFormat:@"sip:%@@%@", user, domain];
    NSString *host = [NSString stringWithFormat:@"sip:%@:%d", sipHost, sipPort];
    
    pjsua_acc_config_default(&acc_cfg);
    
    pj_str_t realmStr  = pj_str("*");
    
//    self.transType = @"tls";
    
    if ([self.transType isEqual: @"tcp"]) {
        NSString *proxyString = [NSString stringWithFormat:@"sip:%@:%d;transport=tcp", sipHost, sipPort];
        acc_cfg.proxy_cnt = 1;
        acc_cfg.proxy[0] = [ESPJUtils fromNSString:proxyString];
        realmStr = [ESPJUtils fromNSString:domain];
    }
    else  if ([self.transType isEqual: @"tls"]){
        NSString *proxyString = [NSString stringWithFormat:@"sip:%@:%d;transport=tls", sipHost, sipPort];
        acc_cfg.proxy_cnt = 1;
        acc_cfg.proxy[0] = [ESPJUtils fromNSString:proxyString];
        realmStr = [ESPJUtils fromNSString:domain];
    }
    else {
        NSString *proxyString = [NSString stringWithFormat:@"sip:%@:%d", sipHost, sipPort];
        acc_cfg.proxy_cnt = 1;
        acc_cfg.proxy[0] = [ESPJUtils fromNSString:proxyString];
    }
    
    acc_cfg.id = [ESPJUtils fromNSString:userId];
    acc_cfg.reg_uri = [ESPJUtils fromNSString:host];
    acc_cfg.cred_count = 1;
  
    acc_cfg.cred_info[0].realm = realmStr;
    acc_cfg.cred_info[0].scheme = pj_str("digest");
    acc_cfg.cred_info[0].username = [ESPJUtils fromNSString:user];
    acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    acc_cfg.cred_info[0].data = [ESPJUtils fromNSString:password];
   
    // 指定传入的视频是否自动显示在屏幕上
    acc_cfg.vid_in_auto_show = PJ_FALSE;
    acc_cfg.vid_out_auto_transmit = PJ_FALSE;

    acc_cfg.reg_timeout = 180;//600
    acc_cfg.unreg_timeout = 1600;//1.6sec

    acc_cfg.allow_contact_rewrite = self.contactRewriteUse ? PJ_TRUE : PJ_FALSE;
    acc_cfg.allow_via_rewrite = self.viaRewriteUse ? PJ_TRUE : PJ_FALSE;
    
    acc_cfg.ice_cfg.enable_ice = self.natIceEnable ? PJ_TRUE : PJ_FALSE;
    acc_cfg.turn_cfg.enable_turn = self.natTurnEnable ? PJ_TRUE : PJ_FALSE;
    acc_cfg.allow_sdp_nat_rewrite = self.natRewriteUse > 0 ? PJ_TRUE : PJ_FALSE;
    
    
    // 17 default: 0
//    acc_cfg.allow_via_rewrite = PJ_TRUE;
 
//    acc_cfg.allow_sdp_nat_rewrite = acc_cfg.allow_via_rewrite;
//    acc_cfg.allow_contact_rewrite = acc_cfg.allow_via_rewrite ? 2 : PJ_FALSE;
    
    /* TODO: to translate to pjsua & Objective-C
    if (mediaTransportAddress != null && mediaTransportAddress.trim().length() != 0) {
        accountConfig.accountConfig.getMediaConfig().getTransportConfig().setBoundAddress(mediaTransportAddress);
    }
    if (mediaTransportPort > 1024 && mediaTransportPort < 65535) {
        accountConfig.accountConfig.getMediaConfig().getTransportConfig().setPort(mediaTransportPort);
    }
     */
    
    acc_cfg.use_srtp=PJMEDIA_SRTP_DISABLED;
    
    if (self.srtpUse == 1) {
        acc_cfg.use_srtp = PJMEDIA_SRTP_OPTIONAL;
        acc_cfg.srtp_secure_signaling = 0;
    }
    if (self.srtpUse == 2) {
        acc_cfg.use_srtp = PJMEDIA_SRTP_MANDATORY;
        acc_cfg.srtp_secure_signaling = 0;
    }
     
    status = pjsua_acc_add(&acc_cfg, PJ_SUCCESS, &acc_id);
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d pjsua_acc_add(&acc_cfg, PJ_SUCCESS, &acc_id)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        
        [self raiseError:ES_CODE_REGISTER_FAIL reason:[NSString stringWithFormat:@"Register failed: %d", status]];
    }
    else {
        self.sipUser = user;
        self.sipPasscode = password;
        self.sipDomain = domain;
        
        [self putAccountConfig:&acc_cfg forAccountId:acc_id];
    }
    NSLog(@"pjsua_acc_add succeed");
    return 0;
}

- (BOOL) checkAccountStatus {
    BOOL registered = NO;
    
    pjsua_acc_info acc_info;
    for (NSNumber* accountId in self.accountConfigDictionary) {
        status = pjsua_acc_get_info(accountId.intValue, &acc_info);
        status = acc_info.status;
        if(status == PJSIP_SC_OK || status == PJSIP_SC_ACCEPTED) {
            NSLog(@"%s - %d @pjsua_acc_get_info(acc_id, &acc_info)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
            
            registered = YES;
            break;
        }
    }
    
    return registered;
}

// 注销
- (void) unregister {
    NSLog(@"ESSPLib unregister");
    
    if (self.callingDictinary.count > 0) {
        [self hangUpAll:nil];
    }
    
    if(self.accountConfigDictionary.count > 0) {
//        pjsua_acc_modify(acc_id, const pjsua_acc_config *acc_cfg)
        status = pjsua_acc_del(acc_id);
        if(status != PJ_SUCCESS) {
            NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
            
            [self raiseError:ES_CODE_SIP_UNREGISTER_ERROR reason:[NSString stringWithFormat:@"Unregister failed: %d", status]];
        }
        [self clearAccountConfigDictionary];
    }
    
    [self raiseRegStateChangedHandler:acc_id registrationStateCode:201];
    
    //[self raiseCallStateChangedHandler:ESCallStateUnregistered number:nil callId:INVALID_CALL_ID callType:0 userData:nil startTime:nil endTime:nil durationTime:0];
}

- (NSDictionary*) getAccountInfo {
    return nil;
}

// 发起呼叫
- (int) makeCall:(NSString *)destUrlRemote userData:(NSDictionary*)userData error:(NSError**)error {
    
    NSLog(@"%s - %d @makeCall(%@, &[%@])\n", __PRETTY_FUNCTION__, __LINE__, destUrlRemote, userData);

    if (!self.sipDomain) {
        *error = [[NSError alloc] initWithDomain:NSArgumentDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"Not registered"}];
        return -1;
    }
    
    char* sipUrl = NULL;
    //发起一个呼叫
    if (!self.routerNumber || [self.routerNumber isEqualToString:@""]) {
        if (![destUrlRemote hasPrefix:@"sip:"]) {
            NSString* destUrl = [NSString stringWithFormat:@"sip:%@@%@", destUrlRemote, self.sipDomain];
            sipUrl = (char*)[destUrl cStringUsingEncoding:NSUTF8StringEncoding];
        }
    }
    else {
        NSString* destUrl = [NSString stringWithFormat:@"sip:%@@%@", routerNumber, self.sipDomain];
        
        sipUrl = (char*)[destUrl cStringUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSLog(@"%s - %d @makeCall dist: %s\n", __PRETTY_FUNCTION__, __LINE__, sipUrl);
    
    /*添加自定义头部*/
    pj_caching_pool cp;
    pj_pool_t *pool;
    pj_status_t status = PJ_SUCCESS;
    
    pjsua_msg_data msg_data;
    pjsua_msg_data_init(&msg_data);
    
    
    pj_caching_pool_init(&cp, &pj_pool_factory_default_policy, 0);
    pool= pj_pool_create(&cp.factory, "header", 1000, 1000, NULL);
    
    for(NSString *key in [userData allKeys]){
        
        NSLog(@"Call.m key value in call %@,%@",key,[userData objectForKey:key] );
        pj_str_t hname = pj_str((char *)[key UTF8String]);
        char * headerValue=(char *)[(NSString *)[userData objectForKey:key] UTF8String];
        pj_str_t hvalue = pj_str(headerValue);
        pjsip_generic_string_hdr* add_hdr = pjsip_generic_string_hdr_create(pool, &hname, &hvalue);
        pj_list_push_back(&msg_data.hdr_list, add_hdr);
    }
    
    pj_str_t uri = pj_str(sipUrl);
    
    //    pj_str_t uri = [ESPJU]
    pjsua_call_id call_id = PJSUA_INVALID_ID;
    
    pjsua_call_setting setting;
    pjsua_call_setting_default(&setting);
    setting.aud_cnt = 1;
    setting.vid_cnt = 0;
    setting.flag = PJSUA_CALL_UPDATE_CONTACT;
    //    setting.flag = pjsua_call_flag
    
    status = pjsua_call_make_call(acc_id, &uri, &setting, NULL, &msg_data, &call_id);
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d @pjsua_call_make_call(acc_id, &[%s], 0, NULL, NULL, NULL)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, sipUrl, status);
        
        *error = [NSError errorWithDomain:@"呼叫失败，请稍候再试" code:9999 userInfo:nil];
        
        return -1;
    }
    
    [self putCallingId:call_id forCallingInfo:[NSString stringWithFormat:@"%d", call_id]];
    
    return call_id;
}

- (int) makeCall:(NSString *)destUrl error:(NSError**)error {
    return [self makeCall:destUrl userData:[NSDictionary dictionary] error:error];
}


//接听呼叫
- (void) answerCall:(int)callId code:(int)code error:(NSError **)error{

    NSLog(@"answerCall");
    
//    *error = [NSError errorWithDomain:@"接听失败，请稍候再试" code:9999 userInfo:nil];
    pj_status_t result = pjsua_call_answer(callId, code, NULL, NULL);
    if (result != PJ_SUCCESS) {
        *error = [NSError errorWithDomain:@"接听失败，请稍候再试" code:result userInfo:nil];
        [self raiseError:ES_CODE_ANSWER_CALL_ERROR reason:[NSString stringWithFormat:@"Answer failed: %d", status]];
    }
}

//挂断呼叫
- (void) hangUp:(int)call_Id error:(NSError **)error{
    NSLog(@"hangup call %d", call_id);
    
    *error = NULL;
    
    pjsua_call_id callId = [self callingIdForCallingInfo:[NSString stringWithFormat:@"%d", call_Id]];
    status = pjsua_call_hangup(callId, 0, NULL, NULL);
    if (status != PJ_SUCCESS) {
        *error = [NSError errorWithDomain:@"挂断失败，请稍候再试" code:9999 userInfo:nil];
        
        [self raiseError:ES_CODE_HANGUP_CALL_ERROR reason:[NSString stringWithFormat:@"HangUp failed: %d", status]];
    }
    
    [self removeCallingIdForCallingInfo:[NSString stringWithFormat:@"%d", call_id]];
}

//挂断所有呼叫
- (void) hangUpAll:(NSError **)error{
    NSLog(@"hangup all");
    
    pjsua_call_hangup_all();
    [self clearCallingDictionary];
}


//发送DTMF信号
- (void)sendDTMFDigits:(int)call_Id DTMFDigits:(NSString *)digitsStr error:(NSError **)error{
    NSLog(@"sendDTMFDigits %d", call_id);
    
    *error = NULL;
    
    pjsua_call_id callId = [self callingIdForCallingInfo:[NSString stringWithFormat:@"%d", call_Id]];
    
    const pj_str_t pjDigits = pj_str((char *)digitsStr.UTF8String);
    pj_status_t dtmfStatus = pjsua_call_dial_dtmf(callId, &pjDigits);
    
    if (dtmfStatus != PJ_SUCCESS) {
        NSLog(@"error ,send dtmf digits");
        
        [self raiseError:ES_CODE_SIP_SENDDTMF_FAIL reason:[NSString stringWithFormat:@"Send DTMF failed: %d", status]];
    } else {
        NSLog(@"dtmf digits sending");
    }
}


//拒绝来电
- (void) rejectCall:(int)call_Id error:(NSError **)error{
    NSLog(@"rejectCall %d", call_id);
    
    *error = NULL;
    
    pjsua_call_id callId = [self callingIdForCallingInfo:[NSString stringWithFormat:@"%d", call_Id]];
   
    pj_status_t status = pjsua_call_hangup(callId, 0, NULL, NULL);
    
    if (status != PJ_SUCCESS) {
        const pj_str_t *statusText =  pjsip_get_status_text(status);
        NSLog(@"拒绝来电, 错误信息:%d(%s) !", status, statusText->ptr);
        
        [self raiseError:ES_CODE_REJECT_CALL_ERROR reason:[NSString stringWithFormat:@"Send DTMF failed: %d(%@)", status, [ESPJUtils stringWithPJString:statusText->ptr]]];
    }
}

//忙来电
- (int) busyCall:(int)callId error:(NSError **)error {
    NSLog(@"busyCall %d", callId);
    
    pj_status_t result = pjsua_call_answer(call_id, PJSIP_SC_BUSY_HERE, NULL, NULL);
    if (result != PJ_SUCCESS) {
        *error = [NSError errorWithDomain:@"占线失败" code:result userInfo:nil];
        
        [self raiseError:ES_CODE_BUSY_CALL_ERROR reason:[NSString stringWithFormat:@"Busy Call failed: %d", status]];
        return ES_FAILED;
    }
    
    return ES_SUCCESS;
}

//添加到指定的会议中
- (BOOL)addCallToConference:(int)callSrcId callDest:(int)callDestId error:(NSError **)error {
    
    NSLog(@"addCallToConference");
    return NO;
}

//从会议中删除
- (BOOL)removeCallFromConference:(int)callSrcId callDest:(int)callDestId error:(NSError **)error {
    
    NSLog(@"removeCallFromConference");
    return NO;
}

- (int) redirectCall:(int)callId destUrl:(NSString*)destUrl error:(NSError **)error {
    
    NSLog(@"redirectCall");
    if ([self getCallInfo:callId]) {
        pj_str_t dest;
        [ESPJUtils PJStringWithString:destUrl out:&dest];
        pjsua_call_xfer(callId, &dest, NULL);
    }
    
    return ES_FAILED;
}

- (NSDictionary*) getCallInfo:(int)callId {
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    NSString *callInfo = nil;
    for (NSNumber* key in [self callingDictinary]) {
        if ([key intValue] == callId) {
            callInfo = [[self callingDictinary] objectForKey:key];
            break;
        }
    }
    if (callInfo) {
        [dicInfo setObject:@"callInfo" forKey:callInfo];
        
        return dicInfo;
    }
    return nil;
}

- (void) unregisterFromSipServer {
    NSLog(@"unregisterFromSipServer");
    
    pjsip_endpt_unregister_module(pjsua_get_pjsip_endpt(), &mod_file_logger_handler);
    
    //非debug下使用文件
    if (s_sipLogFile) {
        fclose(s_sipLogFile);
        s_sipLogFile = NULL;
    }
    
    if(self.accountConfigDictionary.count > 0) {
        status = pjsua_acc_del(acc_id);
        if(status != PJ_SUCCESS) {
            NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        }
        [self clearAccountConfigDictionary];
    }
    
    status = pjsua_destroy();
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
    }
    
    self.sipUser = nil;
    self.sipPasscode = nil;
    self.sipDomain = nil;
}

// send DTMF
- (void) sendDTMF:(char)digit {
    NSLog(@"dtmf digit: %c", digit);
  
    int dtmfType = 2;
    
    pjsua_call_send_dtmf_param param;
    pjsua_call_send_dtmf_param_default(&param);
    param.digits = pj_str(digit);
    param.method = dtmfType;
    
    pjsua_call_send_dtmf (call_id, &param);
 
}



- (void) endcall{
    @try {
        pjsua_call_hangup_all();
    } @catch(NSException *theException) {
        NSError* error = nil;
        [self destroy:&error];
    } @finally {
        
    }
}


//调节麦克风音量
- (void)adjustSipMicroLevel:(float)microLevel error:(NSError **)error{
    
    NSLog(@"adjustSipMicroLevel");
    
}

//调节听筒或扬声器音量
- (void)adjustSipSpeakerLevel:(float)speakerLevel error:(NSError **)error{
    NSLog(@"adjustSipSpeakerLevel");
}

- (void) setSoundSignal:(float)soundLevel callId:(int)call_id {
    
    NSLog(@"setSoundSignal");
}

- (void) setMicSignal:(float)micLevel callId:(int)call_id {
    
    NSLog(@"setMicSignal");
}

- (float) getSignalLevels:(int)call_id {
    NSLog(@"getSignalLevels");
    return 0;
}

- (int) getCodecPriority:(NSString*)codec {
    NSLog(@"getCodecPriority");
    
    unsigned count = 0;
    pjsua_codec_info* codec_info = nil;
    pj_status_t result = pjsua_enum_codecs(codec_info, &count);
    if (result == PJ_SUCCESS) {
        for (int i = 0; i < count; i++) {
            NSString* codecId = [ESPJUtils stringWithPJString:&codec_info[i].codec_id];
            NSLog(@"get codec priority: %@@@%d", codecId, codec_info[i].priority);
            if ([codec isEqualToString:codecId]) {
                return codec_info[i].priority;
            }
        }
    }
    
    return 0;
}

- (void) setCodecPriority:(NSString*)codec newPriority:(int)priority {
    NSLog(@"setCodecPriority: codec: %@, priority: %d", codec, priority);
    unsigned count = 16;
    pjsua_codec_info codec_info[16];
    pj_status_t result = pjsua_enum_codecs(codec_info, &count);
    if (result == PJ_SUCCESS) {
        for (int i = 0; i < count; i++) {
            NSString* codecId = [ESPJUtils stringWithPJString:&codec_info[i].codec_id];
            if ([codec isEqualToString:codecId]) {
                NSLog(@"set codec priority: %@@@%d", codecId, codec_info[i].priority);
                pjsua_codec_set_priority(&codec_info[i].codec_id, priority);
                break;
            }
        }
    }
    pj_str_t codec_s;
    pjsua_codec_set_priority(pj_cstr(&codec_s, "speex/16000/1"), PJMEDIA_CODEC_PRIO_DISABLED);
    pjsua_codec_set_priority(pj_cstr(&codec_s, "speex/8000/1"), PJMEDIA_CODEC_PRIO_DISABLED);
    pjsua_codec_set_priority(pj_cstr(&codec_s, "speex/32000/1"), PJMEDIA_CODEC_PRIO_DISABLED);
    pjsua_codec_set_priority(pj_cstr(&codec_s, "iLBC/8000/1"), PJMEDIA_CODEC_PRIO_DISABLED);
    pjsua_codec_set_priority(pj_cstr(&codec_s, "GSM/8000/1"), PJMEDIA_CODEC_PRIO_DISABLED);
    pjsua_codec_set_priority(pj_cstr(&codec_s, "G722/16000/1"), PJMEDIA_CODEC_PRIO_DISABLED);
    pjsua_codec_set_priority(pj_cstr(&codec_s, "opus/48000/2"), PJMEDIA_CODEC_PRIO_DISABLED);
    pjsua_codec_set_priority(pj_cstr(&codec_s, "G729/8000/1"), PJMEDIA_CODEC_PRIO_DISABLED);
    pjsua_codec_set_priority(pj_cstr(&codec_s, "PCMU/8000/1"), PJMEDIA_CODEC_PRIO_DISABLED); 
    
}

- (void) muteCall{
    NSLog(@"make mute call");
    status = pjsua_conf_disconnect(0, call_info.conf_slot);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        self.isSoundEnabled = YES;
        return;
    }
    
    status = pjsua_conf_disconnect(call_info.conf_slot, 0);
    if(status != PJ_SUCCESS) {
        self.isSoundEnabled = YES;
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        return;
    }
}


- (void) unmuteCall{
    NSLog(@"make unmute call");
    status = pjsua_conf_connect(0, call_info.conf_slot);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        return;
    }
    
    status = pjsua_conf_connect(call_info.conf_slot, 0);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        // If outbound channel creation fails, destroy inbound channel
        pjsua_conf_disconnect(0, call_info.conf_slot);
        return;
    }
    
    self.isSoundEnabled = YES;
}

// Toggles microphone mute.
- (void)toggleCallMute{
    if ([self isSoundEnabled])
        [self muteCall];
    else
        [self unmuteCall];
   
}


//保持呼叫 Places the call on hold.
- (void) holdCall:(int)call_Id error:(NSError **)error{
    NSLog(@"holdCall %d", call_id);
    
    *error = NULL;
    
    pjsua_call_id callId = [self callingIdForCallingInfo:[NSString stringWithFormat:@"%d", call_Id]];
    
    pj_status_t status = pjsua_call_set_hold(callId,NULL);
    
    if (status != PJ_SUCCESS) {
        const pj_str_t *statusText =  pjsip_get_status_text(status);
        NSLog(@"保持来电, 错误信息:%d(%s) !", status, statusText->ptr);
        
        [self raiseError:ES_CODE_HOLD_CALL_ERROR reason:[NSString stringWithFormat:@"Hold Call failed: %d", status]];
    }
}

//取回呼叫 Releases the call from hold
- (void) retrieveCall:(int)call_Id error:(NSError **)error{
    
    NSLog(@"retrieveCall %d", call_id);
    
    *error = NULL;
    
    pjsua_call_id callId = [self callingIdForCallingInfo:[NSString stringWithFormat:@"%d", call_Id]];
    
    pj_status_t status = pjsua_call_reinvite(callId, PJ_TRUE, NULL);
    if (status != PJ_SUCCESS) {
        const pj_str_t *statusText =  pjsip_get_status_text(status);
        NSLog(@"取回来电, 错误信息:%d(%s) !", status, statusText->ptr);
        
        [self raiseError:ES_CODE_UNHOLD_CALL_ERROR reason:[NSString stringWithFormat:@"UnHold Call failed: %d", status]];
    }
}

// Toggles call hold.
- (void)toggleHold{
    if ([self isSoundEnabled])
        [self muteCall];
    else
        [self unmuteCall];
    
}

- (void)setSpeakerphoneOn:(BOOL)isSpeaker{
    if (!isSpeaker) {
        NSLog(@"切换到听筒");
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    } else {//speaker
        NSLog(@"切换到扬声器");
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        
    }
}


//调节听筒或扬声器音量
- (BOOL)enableLoudSpeaker:(BOOL)enable{
    
    NSLog(@"adjustSipSpeakerLevel");
    return TRUE;
}


//获取本地的日志
- (NSString *)getLog:(NSError **)error{
    
    NSLog(@"adjustSipSpeakerLevel");
    
    return @"1";
}

//删除本地的日志
- (void)destroyLog:(NSError **)error{
    
    NSLog(@"adjustSipSpeakerLevel");
    
}

//调节听筒或扬声器音量
- (void)setSoundID:(SystemSoundID)soundID{
    
    NSLog(@"adjustSipSpeakerLevel");
    
}

//调节听筒或扬声器音量
- (void)setSoundName:(NSString *)path{
    
    NSLog(@"adjustSipSpeakerLevel");
    
}

- (void) setCodecPriority:(NSArray*)codecs {

    for (ESPayloadTypes* playloadTypes in codecs) {
        [self setCodecPriority:playloadTypes.codeId newPriority:playloadTypes.identify];
    }
    
    unsigned count = 0;
    pjsua_codec_info* codec_info = nil;
    pj_status_t result = pjsua_enum_codecs(codec_info, &count);
    if (result == PJ_SUCCESS) {
        for (int i = 0; i < count; i++) {
            NSLog(@"codec : %@@@%d", [ESPJUtils stringWithPJString:&codec_info[i].codec_id], codec_info[i].priority);
        }
    }
}

- (BOOL) isAutoRecord {
    return _autoRecord;
}

- (void) setAutoRecord:(BOOL) autoRecord {
    _autoRecord = autoRecord;
}

- (ESAccount *)softPhoneInfo{
    
    NSLog(@"ESAccount");
    
    return _softPhoneInfo;
}

- (ESCallInfo *)voipCallInfo{
    
    NSLog(@"voipCallInfo");
    
    return _voipCallInfo;
    
}

 
- (void)onRegState:(pjsua_acc_id)accId info:(pjsua_reg_info *)info {
    acc_id = accId;
    if (pjsua_acc_is_valid(acc_id) == PJ_EINVAL) {
        NSLog(@"%s - %d onRegState:acc_id %d info: is invalid", __PRETTY_FUNCTION__, __LINE__, acc_id);
//        return;
        status = info->renew;
    }
//    else {
////        status = pjsua_acc_get_info(acc_id, &acc_info);
//        int code = info->cbparam->code;
//        if(code != PJ_SUCCESS) {
//            NSLog(@"%s - %d @pjsua_acc_get_info(acc_id, &acc_info)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
//            // TODO: handle error
//            [self raiseError:ES_CODE_REGISTER_FAIL reason:@""];
//            return;
//        }
//    }
    
    if(info->cbparam->code != PJSIP_SC_OK && info->cbparam->code != PJSIP_SC_ACCEPTED) {
        // TODO: handle status
        NSLog(@"%s - %d @acc_info\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, info->cbparam->code);
        if (info->cbparam->code == PJSIP_SC_REQUEST_TIMEOUT) {
            [self raiseError:ES_CODE_REGISTER_FAIL reason:@"Request Timeout:PJSIP_SC_REQUEST_TIMEOUT"];
        }
//        else if (info->cbparam->code == PJSIP_SC_SERVICE_UNAVAILABLE) {
//            [self raiseError:ES_CODE_SERVICE_UNAVAILABLE reason:@"PJSIP_SC_SERVICE_UNAVAILABLE"];
//        }
//        else if (info->cbparam->code == PJSIP_SC_SERVER_TIMEOUT) {
//            [self raiseError:ES_CODE_SERVER_TIMEOUT reason:@"PJSIP_SC_SERVER_TIMEOUT"];
//        }
        else {
            const pj_str_t* pjstr = pjsip_get_status_text(info->cbparam->code);
            NSString* reason = [ESPJUtils stringWithPJString:pjstr];
            [self raiseError:ES_CODE_REGISTER_FAIL reason:reason];
        }
        return;
    }
    
    NSLog(@"ESPJSP onRegState with state %d, renew %d", status, info->renew);
    
    NSString* call_state = ESCallStateRegistered;
    if (info->renew == 0) {
        call_state = ESCallStateUnregistered;
    } 
    
    [self raiseRegStateChangedHandler:accId registrationStateCode:status];
    
    //[self raiseCallStateChangedHandler:call_state number:nil callId:INVALID_CALL_ID callType:0 userData:nil startTime:nil endTime:nil durationTime:0];
}

- (void)onCallStateCallId:(pjsua_call_id)callId event:(pjsip_event *)e {
    // Assign parameter values to static variables
    call_id = callId;
    
    // Update call_info variable
    status = pjsua_call_get_info(call_id, &call_info);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
    }
    
    NSLog(@"Call %d state=%.*s", call_id, (int)call_info.state_text.slen, call_info.state_text.ptr);
    
    pjsip_inv_state call_inv_state = call_info.state;
    
    pjsip_status_code callStatus = call_info.last_status;
     
    
    NSString* callState = @"Unknow";
    int callType = 0;
    if (call_inv_state == PJSIP_INV_STATE_CALLING) {
        callState = ESCallStateDialing;
        callType = 1;
        
        [self.delegate callOutEventHandler:call_id];
    }
    if (call_inv_state == PJSIP_INV_STATE_EARLY) {
        callState = ESCallStateEarly;
        [self.delegate callEarlyEventHandler:call_id];
    }
    if (call_inv_state == PJSIP_INV_STATE_CONNECTING) {
        callState = ESCallStateConnecting;
    }
    if (call_inv_state == PJSIP_INV_STATE_CONFIRMED) {
        isCalling = true;
        callState = ESCallStateEstablished;
        [self.delegate callConfirmedEventHandler:call_id];
    }
    if (call_inv_state == PJSIP_INV_STATE_INCOMING) {
        callState = ESCallStateRinging;
       
        callType = 2;
    }
    if (call_inv_state == PJSIP_INV_STATE_DISCONNECTED) {
        isCalling = false;
        callState = ESCallStateReleased;
        [self.delegate callDisconnectedEventHandler:acc_id callID:call_id callStateCode:call_inv_state callStatusCode:callStatus connectTimestamp:0 isLocalHold:0 isLocalMute:0];
    }
    
    NSString* number = [ESPJUtils stringWithPJString:&call_info.remote_info];
    
    [self raiseCallStateChangedHandler:callState number:number callId:call_id callType:callType userData:nil startTime:nil endTime:nil durationTime:call_info.connect_duration.sec];

    
    
  
    //    PJ_LOG(3,(FILE, "Call %d state=%.*s", call_id, (int)call_info.state_text.slen, call_info.state_text.ptr));
    
    //    if(e->body.tsx_state.src.status != PJ_SUCCESS) {
    //        // TODO: handle error
    //        return;
    //    }
}

//媒体状态改变事件
- (void)onCallMediaState:(pjsua_call_id)callId {
    // Assign parameter values to static variables
    call_id = callId;
    
    // 获取当前的呼叫信息
    status = pjsua_call_get_info(callId, &call_info);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
    }
    
    //如果媒体激活，则激活声卡
    if(call_info.media_status==PJSUA_CALL_MEDIA_ACTIVE){
        pjsua_conf_connect(call_info.conf_slot,0);
        pjsua_conf_connect(0,call_info.conf_slot);
        //调整输入
        //pjsua_conf_adjuest_tx_level(0,1.5);
        //pjsua_conf_adjuest_rx_level(0,1.5);
        
        
//        pjsua_set_no_snd_dev();
//        pj_status_t status;
//        status = pjsua_set_snd_dev(PJMEDIA_AUD_DEFAULT_CAPTURE_DEV, PJMEDIA_AUD_DEFAULT_PLAYBACK_DEV);
//        if (status != PJ_SUCCESS) {
//           NSLog(@"Failed to active audio session");
//        }
        
        
        //Now set Echo cancellation
        pjsua_set_ec(PJSUA_DEFAULT_EC_TAIL_LEN,0);
        
        //判定媒体状态
        switch(call_info.media_status)
        {
            case PJSUA_CALL_MEDIA_ERROR:
            {
                pj_str_t reason = pj_str("call media error");
                pjsua_call_hangup(call_id,500 , &reason, NULL);
            }
            default:break;
        }
    }
    //打印媒体状态变化
    NSLog(@"Media %d state=%.*s", call_id, (int)call_info.state_text.slen, call_info.state_text.ptr);
}

// in coming call
- (void)onIncommingCallAccId:(pjsua_acc_id)accId callId:(pjsua_call_id)callId rxData:(pjsip_rx_data *)rdata {
    // Assign parameter values to static variables
    
    PJ_UNUSED_ARG(callId);
    PJ_UNUSED_ARG(rdata);
    
    acc_id = accId;
    call_id = callId;
    
    // Update call_info variable
    status = pjsua_call_get_info(call_id, &call_info);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
    }
    
    
    if (isCalling) {
        // Response 486: Busy here
        pjsua_call_answer(call_id, 486, NULL, NULL);
        NSLog(@"\nAnother incoming call...\n");
        return;
    }
    
    //PJ_LOG(3,(THIS_FILE, "Incoming call from %.*s!!", (int)call_info.remote_info.slen, call_info.remote_info.ptr));
    
    /* Do not Automatically answer incoming calls. UI or business layer to do it */
//    status = pjsua_call_answer(call_id, 200, NULL, NULL);
//    if(status != PJ_SUCCESS) {
//        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
//    }
    
    NSString* number = [ESPJUtils stringWithPJString:&call_info.remote_info];
    int callType = 2;
    
    [self putCallingId:call_id forCallingInfo:[NSString stringWithFormat:@"%d", call_id]];
    
    [self raiseCallStateChangedHandler:ESCallStateRinging number:number callId:call_id callType:callType userData:nil startTime:nil endTime:nil durationTime:call_info.total_duration.sec];
}

- (void) raiseError:(int)code reason:(NSString*)reason {
    if (self.delegate) {
        @try {
            [self.delegate onErrorHandler:code errorMessage:reason];
        } @catch (NSException *exception) {
            NSLog(@"%s - %d\nobserver onErrorHandler exception: %@", __PRETTY_FUNCTION__, __LINE__, exception.reason);
        } @finally {
        }
    }
}

- (void) raiseCallStateChangedHandler:(NSString*)callState number:(NSString*)number callId:(int)callId callType:(int)callType userData:(NSDictionary*)userData startTime:(NSDate*) startTime endTime:(NSDate*) endTime durationTime:(long) durationTime {
    if (self.delegate) {
        
        @try {
            [self.delegate onCallStateChangedHandler:callState number:number callId:callId callType:callType userData:userData
                                           startTime:startTime endTime:endTime durationTime:durationTime];
        } @catch (NSException *exception) {
            NSLog(@"%s - %d\nobserver on onCallStateChangedHandler exception: %@", __PRETTY_FUNCTION__, __LINE__, exception.reason);
            [self raiseError:ES_CODE_OBSERVER_ONCALLSTATE_ERROR reason:exception.reason];
        } @finally {
            
        }
    }
}


- (void) raiseRegStateChangedHandler:(int)accountID registrationStateCode:(int)registrationStateCode {
    if (self.delegate) {
        
        @try {
            [self.delegate accountRegisterEventHandler:accountID registrationStateCode:registrationStateCode];
        } @catch (NSException *exception) {
            NSLog(@"%s - %d\nobserver on onRegStateChangedHandler exception: %@", __PRETTY_FUNCTION__, __LINE__, exception.reason);
            //[self raiseError:ES_CODE_OBSERVER_ONCALLSTATE_ERROR reason:exception.reason];
        } @finally {
            
        }
    }
}


static void on_reg_info_changed(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    [[ESSIPLib getInstance] onRegState:acc_id info:info];
}

static void on_call_state(pjsua_call_id call_id, pjsip_event *e) {
    [[ESSIPLib getInstance] onCallStateCallId:call_id event:e];
}

static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    [[ESSIPLib getInstance] onIncommingCallAccId:acc_id callId:call_id rxData:rdata];
}

static void on_call_media_state(pjsua_call_id call_id) {
    [[ESSIPLib getInstance] onCallMediaState:call_id];
}

//文本日志模块，这里需要注意提供socket日志发送模式给server端
static pj_bool_t sip_log_message(BOOL isRx, BOOL isRequest, long len, const char *data)
{
    if (s_sipLogFile) {
        const char *header = (isRx ? "Incoming" : " Outgoing");
        fwrite(header, 1, strlen(header), s_sipLogFile);
        
        header = (isRequest ? " Request\n" : " Response\n");
        fwrite(header, 1, strlen(header), s_sipLogFile);
        
        fwrite(data, 1, len, s_sipLogFile);
        fwrite("\n", 1, 1, s_sipLogFile);
        fflush(s_sipLogFile);
    }
    
    return PJ_TRUE;
}

static pj_bool_t file_logger_mod_on_rx_message(pjsip_rx_data *rdata, BOOL isRequest)
{
    int len = rdata->msg_info.len;
    const char *data = rdata->msg_info.msg_buf;
    
    sip_log_message(YES, isRequest, len, data);
    return PJ_FALSE;
}

static pj_bool_t file_logger_mod_on_tx_message(pjsip_tx_data *tdata, BOOL isRequest)
{
    long len = (tdata->buf.cur - tdata->buf.start);
    const char *data = tdata->buf.start;
    
    sip_log_message(NO, isRequest, len, data);
    return PJ_FALSE;
}

static pj_bool_t file_logger_mod_on_rx_request(pjsip_rx_data *rdata)
{
    return file_logger_mod_on_rx_message(rdata, YES);
}

static pj_bool_t file_logger_mod_on_rx_response(pjsip_rx_data *rdata)
{
    return file_logger_mod_on_rx_message(rdata, NO);
}

static pj_bool_t file_logger_mod_on_tx_request(pjsip_tx_data *tdata)
{
    return file_logger_mod_on_tx_message(tdata, YES);
}

static pj_bool_t file_logger_mod_on_tx_response(pjsip_tx_data *tdata)
{
    return file_logger_mod_on_tx_message(tdata, NO);
}

pjsip_module mod_file_logger_handler =
{
    NULL, NULL,                /* prev, next.        */
    { "mod-file-logger", 15 },    /* Name.        */
    -1,                    /* Id            */
    PJSIP_MOD_PRIORITY_TRANSPORT_LAYER-1,    /* Priority            */
    NULL,                /* load()        */
    NULL,                /* start()        */
    NULL,                /* stop()        */
    NULL,                /* unload()        */
    file_logger_mod_on_rx_request,    /* on_rx_request()    */
    file_logger_mod_on_rx_response,                /* on_rx_response()    */
    file_logger_mod_on_tx_request,                /* on_tx_request.    */
    file_logger_mod_on_tx_response,                /* on_tx_response()    */
    NULL,                /* on_tsx_state()    */
};



- (void )initCheck {
    _lastBytes_CheckNetWorkBytes = 0;
}

- (NSDictionary*)getNetWorkBytesPerSecond {
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    long long newBytes = [self getGprsWifiFlowIOBytes:dic];
    long long currentBytes = 0;
    if ( _lastBytes_CheckNetWorkBytes > 0) {
        currentBytes = newBytes - _lastBytes_CheckNetWorkBytes;
    }
    _lastBytes_CheckNetWorkBytes = newBytes;
    
    long long newIBytes = [[dic objectForKey:@"rx"] longLongValue];
    long long newOBytes = [[dic objectForKey:@"tx"] longLongValue];
    long long currentIBytes = 0;
    long long currentOBytes = 0;
    if (_lastIncomingBytes_CheckNetWorkBytes > 0) {
        currentIBytes = newIBytes - _lastIncomingBytes_CheckNetWorkBytes;
    }
    _lastIncomingBytes_CheckNetWorkBytes = newIBytes;
    if (_lastOutgoingBytes_CheckNetWorkBytes > 0) {
        currentOBytes = newOBytes - _lastOutgoingBytes_CheckNetWorkBytes;
    }
    _lastOutgoingBytes_CheckNetWorkBytes = newOBytes;
    
    [dic setObject:[NSNumber numberWithLongLong:currentBytes] forKey:@"io"];
    [dic setObject:[NSNumber numberWithLongLong:currentIBytes] forKey:@"rx"];
    [dic setObject:[NSNumber numberWithLongLong:currentOBytes] forKey:@"tx"];
    return dic;
}


/*获取网络流量信息*/
- (long long )getGprsWifiFlowIOBytes:(NSDictionary*)detailInfo{
    struct ifaddrs *ifa_list = 0, *ifa;
    if (getifaddrs(&ifa_list) == -1) {
        return 0;
    }
    uint64_t iBytes = 0;
    uint64_t oBytes = 0;
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
        if (AF_LINK != ifa->ifa_addr->sa_family)
            continue;
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            continue;
        if (ifa->ifa_data == 0)
            continue;
        //Wifi
        if (strncmp(ifa->ifa_name, "lo", 2)) {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            iBytes += if_data->ifi_ibytes;
            oBytes += if_data->ifi_obytes;
        }
        //3G或者GPRS
        if (!strcmp(ifa->ifa_name, "pdp_ip0")){
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            iBytes += if_data->ifi_ibytes;
            oBytes += if_data->ifi_obytes;
        }
    }
    freeifaddrs(ifa_list);
    uint64_t bytes = 0;
    bytes = iBytes + oBytes;
    
    if (detailInfo) {
        NSMutableDictionary* dic = (NSMutableDictionary*) detailInfo;
        [dic setObject:[NSNumber numberWithLongLong:iBytes] forKey:@"rx"];
        [dic setObject:[NSNumber numberWithLongLong:oBytes] forKey:@"tx"];
    }
    
    return bytes;
}

//将bytes单位转换
- (NSString *)convertStringWithbyte:(long long)bytes{
    if(bytes < 1024){ // B
        return [NSString stringWithFormat:@"%lldB", bytes];
    }else if(bytes >= 1024 && bytes < 1024 * 1024){// KB
        return [NSString stringWithFormat:@"%.1fKB", (double)bytes / 1024];
    }else if(bytes >= 1024 * 1024 && bytes < 1024 * 1024 * 1024){// MB
        return [NSString stringWithFormat:@"%.2fMB", (double)bytes / (1024 * 1024)];
    }else{ // GB
        return [NSString stringWithFormat:@"%.3fGB", (double)bytes / (1024 * 1024 * 1024)];
    }
}



@end
