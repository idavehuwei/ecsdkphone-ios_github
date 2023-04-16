//
//  ESConfig.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESConfigBase  : NSObject
@property(nonatomic, retain) NSDictionary* contentDic;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end

// ESApiConfig类用于处理ES API配置
@interface ESApiConfig : ESConfigBase

- (NSString*) location; //获取ES API的位置信息
- (NSString*) deptList; //获取ES API的部门列表信息
- (NSString*) contactList; //获取ES API的联系人列表信息
- (NSString*) log; //获取ES API的日志信息
- (NSString*) key; //获取ES API的密钥
- (NSString*) iv; //获取ES API的IV
- (int) timeout; //获取ES API的超时时长

@end

// ESSipLibConfig类用于处理ES SIP库配置
@interface ESSipLibConfig : ESConfigBase
- (BOOL) vad; //判断是否使用语音活动检测（VAD）
- (NSString*) transType; //获取传输类型
- (int) natType; //获取NAT类型
- (BOOL) mediaHasIoqueue; //判断是否开启媒体I/O队列
- (int) mediaClockRate; //获取媒体时钟频率
- (int) mediaQuality; //获取媒体质量
- (int) mediaEcOptions; //获取媒体EC选项
- (int) mediaEcTailLen; //获取媒体EC尾长度
- (int) mediaThreadCnt; //获取媒体线程数量
- (NSString*) mediaTransportAddress; //获取媒体传输地址
- (int) mediaTransportPort; //获取媒体传输端口号
- (BOOL) natIceEnable; //判断是否启用NAT ICE
- (BOOL) natTurnEnable; //判断是否启用NAT TURN
- (int) natRewriteUse; //获取NAT重写选项
- (int) contactRewriteUse; //获取联系人重写选项
- (int) viaRewriteUse; //获取VIA重写选项
- (int) srtpUse; //获取SRTP选项
- (int) sndCloseTime; //获取发送者关闭时间
- (int) registerHeart; //获取注册心跳
- (int) registerTimeout; //获取注册超时时长
- (int) dtmfType; //获取DTMF类型

@end

// ESConfig类用于处理ES配置
@interface ESConfig : ESConfigBase

@property(readonly) ESSipLibConfig* eslib; //ES SIP库配置
@property(readonly) ESApiConfig* esapi; //ES API配置
@property(readonly) NSArray* payloadTypes; //载荷类型

- (NSString*) version; //获取版本号
- (NSString*) video; //获取视频信息
- (ESSipLibConfig*) eslib; //获取ES SIP库配置
- (ESApiConfig*) esapi; //获取ES API配置
- (NSArray *) payloadTypes; //获取载荷类型


@end

NS_ASSUME_NONNULL_END
