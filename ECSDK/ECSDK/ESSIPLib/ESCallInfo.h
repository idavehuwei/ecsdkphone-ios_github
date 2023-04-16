//
//  ESCallInfo.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ES_CALL_STATE) {
    ES_CALL_STATE_NULL,                //呼叫发起前
    ES_CALL_STATE_REGISTERED,          //已注册
    ES_CALL_STATE_UNREGISTED,          //未注册
    ES_CALL_STATE_CALLING,             //发起呼叫
    ES_CALL_STATE_INCOMNG,             //来电
    ES_CALL_STATE_EARLY,               //响铃
    ES_CALL_STATE_CONNECTING,          //通话
    ES_CALL_STATE_CONFIRMED,           //ack确认应答
    ES_CALL_STATE_DISCONNCTD,          //挂机,
    ES_CALL_STATE_BUSY,                //通话中
};

#define INVALID_CALL_ID -1

FOUNDATION_EXPORT NSString* const ESLicense;                    //许可证
FOUNDATION_EXPORT NSString* const ESCallStateInited;            //初始化完毕
FOUNDATION_EXPORT NSString* const ESCallStateRegistered;        //已注册
FOUNDATION_EXPORT NSString* const ESCallStateUnregistered;      //已注销
FOUNDATION_EXPORT NSString* const ESCallStateDialing;           //发起呼叫
FOUNDATION_EXPORT NSString* const ESCallStateIncoming;          //来电
FOUNDATION_EXPORT NSString* const ESCallStateRinging;           //响铃
FOUNDATION_EXPORT NSString* const ESCallStateConnecting;        //通话
FOUNDATION_EXPORT NSString* const ESCallStateEstablished;       //已接通
FOUNDATION_EXPORT NSString* const ESCallStateEarly;             //彩铃
FOUNDATION_EXPORT NSString* const ESCallStateHeld;              //保持
FOUNDATION_EXPORT NSString* const ESCallStateRetrieved;         //取回
FOUNDATION_EXPORT NSString* const ESCallStateReleased;          //挂机
FOUNDATION_EXPORT NSString* const ESCallStateMuteOn;            //静音开
FOUNDATION_EXPORT NSString* const ESCallStateMuteOff;           //静音关
FOUNDATION_EXPORT NSString* const ESCallStateSingleStepConference;  //单步会议
FOUNDATION_EXPORT NSString* const ESCallStateSingleStepTransfer;    //单步转接

@interface ESCallInfo : NSObject<NSCopying>
@property (nonatomic, retain) NSString* localInfo;                           //呼出号码
@property (nonatomic, retain) NSString* remoteInfo;                          //被叫号码
@property (nonatomic, assign) int                            callID;         //该次呼叫的唯一标识
//@property (nonatomic, copy, readonly)   NSString*            callState;      //呼叫状态
//@property (nonatomic, assign, readonly) ES_CALL_STATE        stateCode;      //状态码
//@property (nonatomic, assign, readonly) NSInteger            callType;       //呼叫类型
//@property (nonatomic, readonly, getter=callInfoKey) NSString*                    callInfoKey;    // Call instance key for dictionary
@property (nonatomic, retain) NSDictionary* userData;

+ (ESCallInfo*)newLocalInfo:(NSString*)localInfo remoteInfo:(NSString*)remoteInfo;

@end

NS_ASSUME_NONNULL_END
