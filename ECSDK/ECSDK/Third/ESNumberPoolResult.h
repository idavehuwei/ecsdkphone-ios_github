//
//  ESNumberPoolResult.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface ESNumberPoolBase  : NSObject
@property(nonatomic, retain) NSDictionary* contentDic;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end

@interface NumberPoolDns : ESNumberPoolBase

- (NSString*) dnsid;       //分机ID
- (NSString*) siteIpAddr;  //站点ID
- (NSString*) groupid;     //组织ID
- (NSString*) dnsnumber;   //分机名称
- (NSString*) dntype;      //分机类型（1:分机，2:Trunk）
- (NSString*) dnsstatus;   //激活（1：激活，0：未激活）
- (NSString*) dnpassword;   //分机密码
- (NSString*) createdat;   //创建时间

@end

@interface NumberPoolBinding : NumberPoolDns

- (NSString*)  bindingid;       //分机绑定id
- (NSString*)  bindingSession;  //会话ID
- (NSString*)  userid;          //用户ID
- (NSString*)  token;           //token
- (NSString*)  osdevice;        //绑定终端设备
- (NSString*)  osversion;       //绑定终端版本
- (NSString*)  apptype;          //应用类型
- (NSString*)  appversion;       //应用版本
- (NSString*)  bindingStatus;   //绑定状态

@end

@interface ESNumberPoolResult : ESNumberPoolBase

@property(nonatomic, retain) NumberPoolBinding* numberPoolBinding;

- (int)  code;
- (NumberPoolBinding*) data;
- (NSString*) msg;

@end

@interface ESNumberPoolReturn : ESNumberPoolBase

@property(nonatomic, retain) ESNumberPoolResult* numberPoolResult;

- (BOOL) status;
- (ESNumberPoolResult*) data;
- (NSString*) error;

@end

NS_ASSUME_NONNULL_END

