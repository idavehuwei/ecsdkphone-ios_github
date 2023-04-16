//
//  ESCallInfo.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESCallInfo.h"

NSString* const ESLicense                   = @"License";             //许可证
NSString* const ESCallStateInited           = @"Inited";             //初始化完毕
NSString* const ESCallStateRegistered       = @"Registered";         //已注册
NSString* const ESCallStateUnregistered     = @"Unregistered";       //已注销
NSString* const ESCallStateDialing          = @"Dialing";            //发起呼叫
NSString* const ESCallStateIncoming         = @"Incoming";           //来电
NSString* const ESCallStateRinging          = @"Ringing";            //响铃
NSString* const ESCallStateConnecting       = @"Connecting";         //通话
NSString* const ESCallStateEstablished      = @"Established";        //已接通

NSString* const ESCallStateEarly            = @"Early";              //彩铃

NSString* const ESCallStateHeld             = @"Held";               //保持
NSString* const ESCallStateRetrieved        = @"Retrieved";          //取回
NSString* const ESCallStateReleased         = @"Released";           //挂断
NSString* const ESCallStateMuteOn           = @"MuteOn";             //静音开
NSString* const ESCallStateMuteOff          = @"MuteOff";            //静音关
NSString* const ESCallStateSingleStepConference  = @"SingleStepConference";   //单步会议
NSString* const ESCallStateSingleStepTransfer    = @"SingleStepTransfer";     //单步转接

@implementation ESCallInfo

@synthesize localInfo,remoteInfo;
@synthesize callID, userData = _userData;
//@dynamic callState;
//@dynamic stateCode;
//@dynamic callType;

+ (ESCallInfo*)newLocalInfo:(NSString*)localInfo remoteInfo:(NSString*)remoteInfo
{
    ESCallInfo* info = [[ESCallInfo alloc] init];
    info.localInfo = localInfo;
    info.remoteInfo = remoteInfo;
    
    return info;
}

- (NSDictionary*) userData {
    if (!_userData) {
        _userData = [[NSMutableDictionary alloc] init];
    }
    
    return _userData;
}

#pragma mark -
#pragma Instance Methods

- (NSString*) callInfoKey {
    return [NSString stringWithFormat:@"%@-%@", self.localInfo, self.remoteInfo];
}

#pragma mark -
#pragma NSCopying

- (id)copyWithZone:(nullable NSZone *)zone; {
    return [ESCallInfo newLocalInfo:self.localInfo remoteInfo:self.remoteInfo];
}

@end
