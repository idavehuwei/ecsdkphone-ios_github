//
//  ESIPTools.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESIPTools.h"

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

//域名转IP
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <err.h>
//获取IP
#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <dlfcn.h>
#import <SystemConfiguration/SystemConfiguration.h>
@implementation ESIPTools

+ (BOOL)isIpv6{
    NSArray *searchArray =
    @[ IOS_VPN @"/" IP_ADDR_IPv6,
       IOS_VPN @"/" IP_ADDR_IPv4,
       IOS_WIFI @"/" IP_ADDR_IPv6,
       IOS_WIFI @"/" IP_ADDR_IPv4,
       IOS_CELLULAR @"/" IP_ADDR_IPv6,
       IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block BOOL isIpv6 = NO;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         
         NSLog(@"---%@---%@---",key, addresses[key] );
         
         if ([key rangeOfString:@"ipv6"].length > 0  && ![[NSString stringWithFormat:@"%@",addresses[key]] hasPrefix:@"(null)"] ) {
             
             if ( ![addresses[key] hasPrefix:@"fe80"]) {
                 isIpv6 = YES;
             }
         }
         
     } ];
    
    return isIpv6;
}


+ (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                        
                        NSLog(@"ipv4 %@",name);
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                        NSLog(@"ipv6 %@",name);
                        
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}





// 域名转IP:需有网络才能进行
+ (NSString *)queryIpWithDomain:(NSString *)domain
{
    struct hostent *hs;
    struct sockaddr_in server;
    if ((hs = gethostbyname([domain UTF8String])) != NULL)
    {
        server.sin_addr = *((struct in_addr*)hs->h_addr_list[0]);
        return [NSString stringWithUTF8String:inet_ntoa(server.sin_addr)];
    }
    return nil;
}

// 通过查询网址，解析html得到ip地
+ (NSString *)whatismyipdotcom
{
    NSError *error;
    NSURL *ipURL = [NSURL URLWithString:@"http://iframe.ip138.com/ic.asp"];
    NSString *ip = [NSString stringWithContentsOfURL:ipURL encoding:1 error:&error];
    
    NSRange range = [ip rangeOfString:@"<center>ÄúµÄIPÊÇ£º["];
    NSString *str = @"<center>ÄúµÄIPÊÇ£º[";
    if (range.location > 0 && range.location < ip.length)
    {
        range.location += str.length ;
        range.length = 17;
        ip = [ip substringWithRange:range];
        
        range = [ip rangeOfString:@"]"];
        range.length = range.location;
        range.location = 0;
        ip = [ip substringWithRange:range];
    }
    
    return ip ? ip : nil;
}

// 查询内网地址ip方法1
+ (NSString *)queryIPAddress
{
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            // the second test keeps from picking up the loopback address
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"])  // Wi-Fi adapter
                    return [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return nil;
}

// 查询内网地址ip方法2
+ (NSString *)localIPAddress
{
    char baseHostName[256] = {0}; // Thanks, Gunnar Larisch
    int success = gethostname(baseHostName, 255);
    if (success != 0) return nil;
    //    baseHostName[255] = '0';
    NSString *hostname=nil;
#if TARGET_IPHONE_SIMULATOR
    hostname=[NSString stringWithFormat:@"%s", baseHostName];
#else
    hostname=[NSString stringWithFormat:@"%s.local", baseHostName];
#endif
    
    struct hostent *host = gethostbyname([hostname UTF8String]);
    if (!host) {herror("resolv"); return nil;}
    struct in_addr **list = (struct in_addr **)host->h_addr_list;
    return [NSString stringWithCString:inet_ntoa(*list[0]) encoding:NSUTF8StringEncoding];
}

#define CopyString(temp) (temp != NULL)? strdup(temp):NULL
+ (NSString *)getIPAddress:(NSString *)ipAddress {
    if (!ipAddress) {
        return @"";
    }
    
    struct addrinfo hints, *res, *res0;
    int error;
    
    const char *ipv4_str = [ipAddress UTF8String];
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_DEFAULT;
    error = getaddrinfo(ipv4_str, "http", &hints, &res0);
    if (error) {
        errx(1, "%s", gai_strerror(error));
        return @"";
    }
    
    struct sockaddr_in6* addr6;
    struct sockaddr_in * addr;
    const char* pszTemp;
    
    for (res = res0; res; res = res->ai_next) {
        char buf[32];
        if(res->ai_family == AF_INET6) {
            addr6 = (struct sockaddr_in6*)res->ai_addr;
            pszTemp = inet_ntop(AF_INET6, &addr6->sin6_addr, buf, sizeof(buf));
        } else {
            addr = (struct sockaddr_in*)res->ai_addr;
            pszTemp = inet_ntop(AF_INET, &addr->sin_addr, buf, sizeof(buf));
        }
        
        break;
    }
    
    freeaddrinfo(res0);
    printf("getaddrinfo ok %s\n", pszTemp);
    return [NSString stringWithFormat:@"%s",CopyString(pszTemp)];
}


@end
