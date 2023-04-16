//
//  EcSipLib.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ESConfig.h"
#import "ESSIPLib.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VoipState) {
    /** 1.发起语音 */
    VoipStateCalling = 1,
    /** 2.语音来电 */
    VoipStateIncoming   ,
    /** 3.响铃中 */
    VoipStateEarly      ,
    /** 4.正连接通话 */
    VoipStateConnecting ,
    /** 5.正通话中 */
    VoipStateConfirm    ,
    /** 6.挂断通话 */
    VoipStateDisconnect ,
    /** 7.对方无应答 */
    VoipStateNoResponse ,
    /** 8.dtmf回调 */
    VoipStateDtmf       ,
};

@interface EcSipLib : NSObject

/** 初始化单例 **/
+ (EcSipLib *)getInstance;

/** 语音是否接入正常 **/
@property (nonatomic, assign)BOOL isVoipNormal;

/** 上次通话是否存在 **/
@property (nonatomic, assign)BOOL isCallingFlag;

/** 语音通话状态回调 **/
@property (nonatomic, copy)void(^voipBlock)(VoipState state);

@property (weak) id<ESSIPLibDelegate> externalAppObserver;


/**
 * 初始化essdk对象
 * 调用ESPJLIB初始化
 */

- (int) initSDK: (NSString *)extNo extPwd:(NSString *)extPwd domain:(NSString *)domain;


/**
 * 销毁essdk对象
 */
- (int) destory;



/**
 *  登陆语音账号
 *
 *  @param extNo          用户名
 *  @param extPwd          密码
 *  @param domain            域名
 */
 - (int)register:(NSString *)extNo extPwd:(NSString *)extPwd domain:(NSString *)domain sipHost:(NSString *)sipHost sipPort:(int)sipPort ;


 - (int)unRegister;

/**
 * 呼叫指定的用户
 */
- (int)makeCall:(NSString *)destUrl;

/**
 * 呼叫指定的用户
 */
- (int)makeCall:(NSString *)remoteNumber userData:(NSDictionary*)userData;

/**
 * 挂断语音
 * 挂断后，注销当前的账号
 */
- (int)hangup:(int)callID;


- (int)hangupAll;

/**
 * 接通指定的callID的语音
 */
- (int)answerCall:(int)callID;
/**
 * 接通语音
 */
- (int)answerCall;

/**
 拒接当前电话
 */
- (int)rejectCall:(int)callID;

/**
 * 发送DTMF数据
 **/
- (int)sendDTMF:(int)callID digits: (NSString *)digits;


- (int)sendDTMF:(NSString *)digits;
/**
 * 语音通讯播放路径 YES:扬声器 NO:听筒
 **/
- (void)changeVoiceWithLoudSpeaker:(BOOL)flag;

/**
 * 语音通讯静音操作
 */
- (void)changeIsSilenceWithFlag:(BOOL)flag;

/**
 *  手动调节麦克风音量
 *
 *  @param microVolume        音量大小(0~1 减小, 1~2 放大)
 */
- (void)adjustMicroVolume:(CGFloat)microVolume;

/**
 *  手动调节语音音量
 *
 *  @param speakerVolume   音量大小(0~1 减小, 1~2 放大)
 */
- (void)adjustSpeakerVolume:(CGFloat)speakerVolume;

/**
 * 提示用户授权
 */
- (void)showSetAlertView:(UIViewController *) vc;


/**
 * 查询服务器信息
 */
- (void) queryLocation:(NSString *)extNo extPwd:(NSString *)extPwd domain:(NSString *)domain;

/**
 * 查询部门信息
 */
- (void) queryDeptList:(NSString *)extNo extPwd:(NSString *)extPwd domain:(NSString *)domain;

/**
 * 查询通讯录信息
 */
- (void) queryContactList:(NSString *)extNo extPwd:(NSString *)extPwd domain:(NSString *)domain deptId:(NSString *)deptId;

@end

NS_ASSUME_NONNULL_END
