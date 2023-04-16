//
//  ESPJUtils.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//


#import "ESPJUtils.h"
#import<CoreTelephony/CTTelephonyNetworkInfo.h>
#import<CoreTelephony/CTCarrier.h>

#import <pjsip/sip_transport_tls.h>
#import <pjsip/sip_multipart.h>
#import <pjsua-lib/pjsua.h>
#import <pj/types.h>
#import <pj/string.h>
#import <pjsip/sip_errno.h>
#import <pjmedia/format.h>
#import <pjsip/sip_endpoint.h>
#import <pj/types.h>

static NSString * const CHINAUNICOM = @"";
static NSString * const CHINAMOBILE = @"";
static NSString * const CHINANET = @"";

const char* getBundleId() {
    return [[[NSBundle mainBundle] bundleIdentifier] cStringUsingEncoding:NSUTF8StringEncoding];
}

@implementation ESPJUtils


+(pj_str_t)fromNSString:(NSString *)str
{
    return pj_str((char *)[str cStringUsingEncoding:NSUTF8StringEncoding]);
}

+(NSString *)fromPJString:(const pj_str_t *)pjString
{
    NSString *result = [NSString alloc];
    result = [result initWithBytesNoCopy:pjString->ptr
                                  length:pjString->slen
                                encoding:NSUTF8StringEncoding
                            freeWhenDone:NO];
    return result;
}

//将status中的状态转化成Error
+ (NSError *)errorWithSIPStatus:(pj_status_t)status {
    int errNumber = PJSIP_ERRNO_FROM_SIP_STATUS(status);
    
    pj_size_t bufferSize = sizeof(char) * 255;
    NSMutableData *data = [NSMutableData dataWithLength:bufferSize];
    char *buffer = (char*)[data mutableBytes];
    pj_strerror(status, buffer, bufferSize);
    
    NSString *errorStr = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            errorStr, NSLocalizedDescriptionKey,
            [NSNumber numberWithInt:status], @"pj_status_t",
            [NSNumber numberWithInt:errNumber], @"PJSIP_ERRNO_FORM_SIP_STATUS", nil];
    
    NSError *err = nil;
    err = [NSError errorWithDomain:@"pjsip.org"
                              code:PJSIP_ERRNO_FROM_SIP_STATUS(status)
                          userInfo:info];
    
    return err;
}


//将pj_str_t转化成NSString
//+ (NSString *)stringWithPJString:(const pj_str_t *)pjString {
+ (NSString *)stringWithPJString:(const void *)pjStringValue {
    const pj_str_t * pjString = (const pj_str_t *)pjStringValue;
    NSString *result = [NSString alloc];
    result = [result initWithBytesNoCopy:pjString->ptr
                                  length:pjString->slen
                                encoding:NSASCIIStringEncoding
                            freeWhenDone:NO];
    
    return result;
}

//将NSString转化成pj_str_t
//+ (pj_str_t)PJStringWithString:(NSString *)string {
+ (void)PJStringWithString:(NSString *)string out:(void*)pjStr {
    const char *cStr = [string cStringUsingEncoding:NSASCIIStringEncoding]; // TODO: UTF8?
    
//    pj_str_t result;
//    pj_cstr(&result, cStr);
    pj_cstr((pj_str_t *)pjStr, cStr);
}

//在指定的字符串前增加sip
//+ (pj_str_t)PJAddressWithString:(NSString *)string {
+ (void)PJAddressWithString:(NSString *)string out:(void*)pjStr {
    [self PJStringWithString:[@"sip:" stringByAppendingString:string] out:pjStr];
//    return [self PJStringWithString:[@"sip:" stringByAppendingString:string]];
}

//判定当前的字符串是否为null
+ (BOOL) isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

//判断当前的运营商
+ (NSString*)checkCarrier{
    
    NSString *ret = CHINAUNICOM;
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    if ( carrier == nil )
    {
        return(ret);
    }
    NSString *code = [carrier mobileNetworkCode];
    NSLog(@"----------------mobileNetworkCode:%@----------------", code);
    if ([ESPJUtils isBlankString:code])
    {
        return(ret);
    }
    
    if ( [code isEqualToString:@"00"] || [code isEqualToString:@"02"] || [code isEqualToString:@"07"] )
    {
        ret = CHINAMOBILE;
    }
    
    if ( [code isEqualToString:@"01"] || [code isEqualToString:@"06"] )
    {
        ret = CHINAUNICOM;
    }
    
    if ( [code isEqualToString:@"03"] || [code isEqualToString:@"05"] )
    {
        ret = CHINANET;
    }
    
    return(ret);
    
}

@end

