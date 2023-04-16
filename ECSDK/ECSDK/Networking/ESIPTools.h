//
//  ESIPTools.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESIPTools : NSObject

+ (BOOL)isIpv6;
+ (NSDictionary *)getIPAddresses;

// 域名转IP:需有网络才能进行
+ (NSString *)queryIpWithDomain:(NSString *)domain;
+ (NSString *)getIPAddress:(NSString *)ipAddress;

@end

NS_ASSUME_NONNULL_END
