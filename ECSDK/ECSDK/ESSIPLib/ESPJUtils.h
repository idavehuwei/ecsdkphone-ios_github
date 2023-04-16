//
//  ESPJUtils.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>
#import <pjsua.h>

NS_ASSUME_NONNULL_BEGIN

struct pj_str_t;


@interface ESPJUtils : NSObject

+(pj_str_t)fromNSString:(NSString *)str;

+(NSString *)fromPJString:(const pj_str_t *)pjString;

/// Creates an NSError from the given PJSIP status using PJSIP macros and functions.
+ (NSError *)errorWithSIPStatus:(int)status;

/// 将pj_str_t转化成NSString
+ (NSString *)stringWithPJString:(const void *)pjString;

/// 将NSString转化成pj_str_t
+ (void)PJStringWithString:(NSString *)string out:(void*)pjStr;

/// Creates pj_str_t from NSString prefixed with "sip:". Instance lifetime depends on the NSString instance.
+ (void)PJAddressWithString:(NSString *)string out:(void*)pjStr;

/// 判断当前的字符串是否为Blank
+ (BOOL) isBlankString:(NSString *)string;

/// 判断当前的运营商
+ (NSString*)checkCarrier;


@end

NS_ASSUME_NONNULL_END
