//
//  ESNumberPoolResult.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESNumberPoolResult.h"

@implementation ESNumberPoolBase

- (id) initWithDictionary:(NSDictionary*)dictionary {
    if (self = [super init]) {
        self.contentDic = dictionary;
    }
    
    return self;
}

@end


@implementation NumberPoolDns

- (NSString*) dnsid {
    return [self.contentDic objectForKey:@"dnsid"];
}
- (NSString*) siteIpAddr {
    return [self.contentDic objectForKey:@"siteIpAddr"];
}
- (NSString*) groupid {
    return [self.contentDic objectForKey:@"groupid"];
}
- (NSString*) dnsnumber {
    return [self.contentDic objectForKey:@"dnsnumber"];
}
- (NSString*) dntype {
    return [self.contentDic objectForKey:@"dntype"];
}
- (NSString*) dnsstatus {
    return [self.contentDic objectForKey:@"dnsstatus"];
}
- (NSString*) dnpassword {
    return [self.contentDic objectForKey:@"dnpassword"];
}
- (NSString*) createdat {
    return [self.contentDic objectForKey:@"createdat"];
}

@end

@implementation NumberPoolBinding


- (NSString*)  bindingid {
    return [self.contentDic objectForKey:@"bindingid"];
}
- (NSString*)  bindingSession {
    return [self.contentDic objectForKey:@"bindingSession"];
}
- (NSString*)  userid {
    return [self.contentDic objectForKey:@"userid"];
}
- (NSString*)  token {
    return [self.contentDic objectForKey:@"token"];
}
- (NSString*)  osdevice {
    return [self.contentDic objectForKey:@"osdevice"];
}
- (NSString*)  osversion {
    return [self.contentDic objectForKey:@"osversion"];
}
- (NSString*)  apptype {
    return [self.contentDic objectForKey:@"apptype"];
}
- (NSString*)  appversion {
    return [self.contentDic objectForKey:@"appversion"];
}
- (NSString*)  bindingStatus {
    return [self.contentDic objectForKey:@"bindingStatus"];
}

@end

@implementation ESNumberPoolResult

@synthesize numberPoolBinding;

- (int)  code {
    return [[self.contentDic objectForKey:@"code"] intValue];
}
- (NumberPoolBinding*) data {
    if (!self.numberPoolBinding) {
        self.numberPoolBinding = [[NumberPoolBinding alloc] initWithDictionary:[self.contentDic objectForKey:@"data"]];
    }
    return self.numberPoolBinding;
}
- (NSString*) msg {
    return [self.contentDic objectForKey:@"msg"];
}

@end


@implementation ESNumberPoolReturn

@synthesize numberPoolResult;

- (BOOL) status {
    return [[self.contentDic objectForKey:@"status"] boolValue];
}
- (ESNumberPoolResult*) data {
    if (!self.numberPoolResult) {
        self.numberPoolResult = [[ESNumberPoolResult alloc] initWithDictionary:[self.contentDic objectForKey:@"data"]];
    }
    return self.numberPoolResult;
}
- (NSString*) msg {
    return [self.contentDic objectForKey:@"msg"];
}

@end

