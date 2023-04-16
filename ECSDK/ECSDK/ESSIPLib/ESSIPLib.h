//
//  ESSIPLib.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ESAccount.h"
#import "ESCallInfo.h"
#import "ESConstants.h"


NS_ASSUME_NONNULL_BEGIN


/**
 控制台是否打印日志
 0 打印 1 不打印
 */
#define RELEASE_VERSION 0

/**
 以下内容制定了srtp的传输特性 用于安全性处理
 - ES_SRTP_USE_DIAABLE:   使用该选项将会禁止使用SRTP,并且拒绝RTP/SAVP请求
 - ES_SRTP_USE_OPITION:   使用该选项将会使SRTP变更为可选项，当有SRTP加密请求时将对接收到/发送
 - ES_SRTP_USE_MANDATORY: 使用该选项将会强制使用SRTP加密
 */
typedef NS_ENUM(NSUInteger, ES_SRTP_USE) {
    ES_SRTP_USE_DISABLE,
    ES_SRTP_USE_OPITION,
    ES_SRTP_USE_MANDATORY,
};

/**
 错误类型
 */
typedef NS_ENUM(NSInteger, ES_CODE_ERR) {
    ES_CODE_OK                          = 0,    // 无错
    
    ES_CODE_SIP_INIT_FAIL               = 1000, // 初始化失败
    ES_CODE_REGISTER_FAIL               = 1001, // 注册失败
    ES_CODE_NOT_FOUND_CALL_ERROR        = 1002, // 未找到呼叫信息
    ES_CODE_SIP_NOT_REGISTER            = 1003, // sip账号没有注册
    ES_CODE_SIP_UNREGISTER_ERROR        = 1004, // sip账号注销失败
    ES_CODE_SIP_CODEC_PRIORITY_ERROR    = 1005, // sip设置编码优先级失败
    ES_CODE_SIP_SENDDTMF_FAIL           = 1006, // sip电话发送DTMF数据失败
    ES_CODE_SIP_MODIFY_ACC_CFG_FAIL     = 1007, // sip电话修改账号配置信息失败
    ES_CODE_HOLD_CALL_ERROR             = 1008, // sip电话保持失败
    ES_CODE_UNHOLD_CALL_ERROR           = 1009, // sip电话取回失败
    ES_CODE_HANGUP_CALL_ERROR           = 1010, // sip电话挂断失败
    ES_CODE_REJECT_CALL_ERROR           = 1011, // sip电话拒绝失败
    ES_CODE_BUSY_CALL_ERROR             = 1012, // sip电话返回忙音失败
    ES_CODE_ANSWER_CALL_ERROR           = 1013, // sip电话接听失败
    
    ES_CODE_SERVICE_UNAVAILABLE         = 1503, // 无法连接sip服务器
    ES_CODE_SERVER_TIMEOUT              = 1504, // 连接Sip服务器超时
    
    ES_CODE_NUMBER_POOL_ERROR           = 2001, // 号码池错误
    ES_CODE_NUMBER_POOL_RECYCLED        = 2002, // 号码池已回收错误，心跳返回500
    
    ES_CODE_OBSERVER_ONCALLSTATE_ERROR  = 3001,  // 观察者ONCALLSTATE时错误
    
    ES_CODE_REGISTER_SERVER_TIMEOUT     = 5001,  // 注册服务端超时
    ES_CODE_REGISTER_SERVER_TIMEOUT_MAX_RETRY_NUMBER = 5002,  // 注册服务端超时，达到最大次数
    
    ES_CODE_LICENSE_READ_UNKNOW_ERROR   = 6001,
    ES_CODE_LICENSE_READ_HARDWARE_ERROR = 6002,
    ES_CODE_LICENSE_READ_LICENSE_ERROR  = 6003,
    ES_CODE_LICENSE_LICENSE_NOT_FOUND   = 6004,
    ES_CODE_LICENSE_LICENSE_ERROR       = 6005,
    ES_CODE_LICENSE_LICENSE_SERVER_ERROR= 6006,
};

/**
 * ESSIPLib delegate for receive phone call state callback
 */
@protocol ESSIPLibDelegate <NSObject>

/**
 * When call state changed, this method will be invoked.
 *
 * @param callState call state: Registered/Unregistered/Ringing/Dialing/Established/Released/Held/Retrieved
 * @param number the target phone/DN number
 * @param callType which type of call type None/OutBound/InBound
 * @param userData  the associate data
 * @param startTime when call started time.
 * @param endTime   when call end time.
 * @param durationTime the call duration.
 */
-(void) onCallStateChangedHandler:(NSString*)callState number:(NSString*)number callId:(int)callId callType:(int)callType userData:(NSDictionary*)userData startTime:(NSDate*) startTime endTime:(NSDate*) endTime durationTime:(long) durationTime;





/**
 * Error handler.
 *
 * @param errorCode error code
 * @param errorMessage error message
 */
-(void) onErrorHandler:(int)errorCode errorMessage:(NSString*)errorMessage;

/**
 * When network is changed, this method will be invoked
 *
 * @param networkType  3G/4G/Wifi
 */
-(void) onNetworkChangeHandler:(NSString*) networkType;

/**
 * When network and speed are changed, this method will be invoked
 *
 * @param networkType  3G/4G/Wifi
 */
@optional
-(void) onNetworkChangeHandler:(NSString*) networkType sendRate:(NSString*)sendRate recieveRate:(NSString*)recieveRate;

-(void) accountRegisterEventHandler:(int)accountID registrationStateCode:(int)registrationStateCode;

-(void) callComingEventHandler:(int)accountID callID:(int)callID displayName:(NSString*)displayName; 

-(void) callDisconnectedEventHandler:(int)accountID callID:(int)callID callStateCode:(int)callStateCode callStatusCode:(int)callStatusCode connectTimestamp:(int)connectTimestamp isLocalHold:(int)isLocalHold isLocalMute:(int)isLocalMute;


-(void) callConfirmedEventHandler:(int)callID;

-(void) callEarlyEventHandler:(int)callID;

-(void) callOutEventHandler:(int)callID;

-(void) stackStatusEventHandler:(int)started;

-(void) locationEventHandler:(NSMutableArray*)locationList;

-(void) deptEventHandler:(NSMutableArray*)deptList;

-(void) contactEventHandler:(NSMutableArray*)contactList;

@end

/**
 *
 */
@interface ESSIPLib : NSObject

@property (nonatomic, retain) NSString *sipState;
@property (nonatomic, retain) NSString *agentName;
@property (nonatomic, retain) NSString *agentPassword;
@property (nonatomic, retain) NSString *agentNumber;
@property (nonatomic, retain) NSString *agentPasscode;
@property (nonatomic, retain) NSString *sipUser;
@property (nonatomic, retain) NSString *sipPasscode;
@property (nonatomic, retain) NSString *contactCentre;
@property (nonatomic, retain) NSString *contactCentreNumber;
@property (nonatomic, retain) NSString *sipDomain;
@property (nonatomic, retain) id<ESSIPLibDelegate> delegate;

@property(nonatomic, assign, getter=isMicrophoneMuted) BOOL microphoneMuted;
@property(nonatomic, assign, getter=isAutoRecord, setter=setAutoRecord:) BOOL autoRecord;

+(ESSIPLib *) getInstance;

/**
 *  初始化sip栈
 *
 *  @param error 错误信息
 */
- (BOOL)init:(NSDictionary*)settings error:(NSError **)error;

/**
 *  释放sip栈资源
 *
 *  @param error 错误信息
 */
- (BOOL)destroy:(NSError **)error;

/**
 * 注册账号
 * @param user user dn number
 * @param password user password
 * @param domain server
 * @param error 错误信息
 */
- (int) registerUser:(NSString *)user password:(NSString*)password domain:(NSString*)domain error:(NSError**)error;

- (int) registerUser:(NSString *)user password:(NSString*)password domain:(NSString*)domain sipHost:(NSString*)sipHost sipPort:(int)sipPort error:(NSError**)error;


/**
 * 检查账户状态
 */
- (BOOL) checkAccountStatus;

/**
 * 注销账号
 */
- (void) unregister;

/**
 * 获取当前账户信息
 */
- (NSDictionary*) getAccountInfo;

/**
 *  拨打电话
 *
 *  @param destUrl         目标号码
 *  @param userData        随路数据
 *  @return call id, -1 means make call failed.
 */
- (int) makeCall:(NSString *)destUrl userData:(NSDictionary*)userData error:(NSError**)error;

/**
 *  拨打电话
 *
 *  @param destUrl  目标号码
 *  @return call id, -1 means make call failed.
 */
- (int) makeCall:(NSString *)destUrl error:(NSError**)error;


/**
 *  接通电话
 *
 *  @param callId       call Id
 *  @param code         应答码
 *  @param error        错误信息
 */
- (void) answerCall:(int)callId code:(int)code error:(NSError **)error;

/**
 *  拒绝来电
 *
 *  @param callId       call Id
 *  @param error        错误信息
 */
- (void) rejectCall:(int)callId error:(NSError **)error;

/**
 *  忙来电
 *
 *  @param callId       call Id
 *  @param error        错误信息
 @  @return ES_SUCCESS, ES_FAILED
 */
- (int) busyCall:(int)callId error:(NSError **)error;

/**
 *  挂断电话
 *
 *  @param error 错误信息
 */
- (void) hangUp:(int)callId error:(NSError **)error;

/**
 *  挂断所有的电话
 *
 *  @param error 错误信息
 */
- (void)hangUpAll:(NSError **)error;

/**
 *  保持电话
 *
 *  @param callId 呼叫ID
 *  @param error 错误信息
 */
- (void)holdCall:(int)callId error:(NSError **)error;

/**
 *  取回电话
 *
 *  @param callId 呼叫ID
 *  @param error 错误信息
 */
- (void)retrieveCall:(int)callId error:(NSError **)error;
/**
 *  添加到指定的会议中
 *
 *  @param callSrcId 源呼叫ID
 *  @param callDestId 目标呼叫ID
 *  @param error 错误信息
 */
- (BOOL)addCallToConference:(int)callSrcId callDest:(int)callDestId error:(NSError **)error;

/**
 *  从会议中删除
 *
 *  @param callSrcId 源呼叫ID
 *  @param callDestId 目标呼叫ID
 *  @param error 错误信息
 */
- (BOOL)removeCallFromConference:(int)callSrcId callDest:(int)callDestId error:(NSError **)error;

/**
 *  转移呼叫
 *
 *  @param callId  呼叫ID
 *  @param destUrl 目标呼叫号码
 *  @param error 错误信息
 */
- (int) redirectCall:(int)callId destUrl:(NSString*)destUrl error:(NSError **)error;

/**
 * 获取指定的呼叫信息
 *
 * @param callId 呼叫Id
 * @return 呼叫信息
 */
- (NSDictionary*) getCallInfo:(int)callId;

/**
 *  发送DTMF数据
 *
 *  @param callId  call id
 *  @param dtmf  dtmf信息
 *  @param error 错误信息
 */
- (void)sendDTMFDigits:(int)callId DTMFDigits:(NSString *)dtmf error:(NSError **)error;
/**
 *  调节麦克风音量
 *
 *  @param microLevel 麦克风声音强度级别，默认为1，取值范围0~2; 0~1减小音量,1~2增加音量
 *  @param error      错误信息
 */
- (void)adjustSipMicroLevel:(float)microLevel error:(NSError **)error;

- (void) setSoundSignal:(float)soundLevel callId:(int)call_id;
- (void) setMicSignal:(float)micLevel callId:(int)call_id;
- (float) getSignalLevels:(int)call_id;
- (int) getCodecPriority:(NSString*)codec;
- (void) setCodecPriority:(NSString*)codec newPriority:(int)priority;

// Mutes microphone.
- (void)muteCall;

// Unmutes microphone.
- (void)unmuteCall;

// Toggles microphone mute.
- (void)toggleCallMute;


/**
 *  切换到听筒或者扬声器
 *
 *  @param isSpeaker true 切换到扬声器。 false切换到听筒
 */
- (void) setSpeakerphoneOn:(BOOL)isSpeaker;

/**
 *  调节听筒或扬声器音量
 *
 *  @param speakerLevel 听筒声音强度级别，默认为1，取值范围0~2; 0~1减小音量,1~2增加音量
 *  @param error        错误信息
 */
- (void) adjustSipSpeakerLevel:(float)speakerLevel error:(NSError **)error;

/**
 是否使用扬声器通话
 @return 是否成功
 */
- (BOOL) enableLoudSpeaker:(BOOL)enable;

/**
 获取所有本地日志信息
 @param error 错误信息，如果成功为nil
 @return 日志内容
 */
- (NSString *) getLog:(NSError **)error;

/**
 删除本地日志文件
 @param error 错误信息，如果成功为nil
 */
- (void)destroyLog:(NSError **)error;

/**
 使用iOS系统内部的铃声，详细请参考
 http://iphonedevwiki.net/index.php/AudioServices
 默认使用system sound id 1005
 @param soundID SystemSoundID
 */
- (void)setSoundID:(SystemSoundID)soundID;

/**
 使用指定的音频文件作为铃声，铃声文件需要caf格式并且不超过30s
 并且copy到bundle中
 @param path 文件名路径
 */
- (void)setSoundName:(NSString *)path;


/**
 *  获取sip电话信息
 *
 *  @return CMSoftPhoneInfo实例
 */
- (ESAccount *)softPhoneInfo;

/**
 *  获取当前通话的信息
 *
 *  @return 当前通话信息的实例
 */
- (ESCallInfo *)voipCallInfo;

/**
 * 自动录音
 * @return 自动录音
 */
- (BOOL) isAutoRecord;

/**
 * 自动录音
 * @param autoRecord 自动录音
 */
- (void) setAutoRecord:(BOOL) autoRecord;



- (void )initCheck;

- (NSDictionary*)getNetWorkBytesPerSecond;

- (long long )getGprsWifiFlowIOBytes:(NSDictionary*)detailInfo;

- (NSString *)convertStringWithbyte:(long long)bytes;



@end


NS_ASSUME_NONNULL_END
