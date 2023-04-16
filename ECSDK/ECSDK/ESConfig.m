//
//  ESConfig.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//


#import "ESConfig.h"
#import "ESPayloadTypes.h"

@implementation ESConfigBase

@synthesize contentDic;

- (id) initWithDictionary:(NSDictionary*)dictionary {
    if (self = [super init]) {
        self.contentDic = dictionary;
    }
    
    return self;
}

@end

 
@implementation ESApiConfig

- (NSString*) location {
    return [self.contentDic objectForKey:@"location"];
}

- (NSString*) deptList {
    return [self.contentDic objectForKey:@"deptList"];
}

- (NSString*) contactList {
    return [self.contentDic objectForKey:@"contactList"];
}

- (NSString*) log {
    return [self.contentDic objectForKey:@"log"];
}

- (NSString*) key {
    return [self.contentDic objectForKey:@"key"];
}

- (NSString*) iv {
    return [self.contentDic objectForKey:@"iv"];
}

- (int) timeout {
    return [[self.contentDic objectForKey:@"timeout"] intValue];
}
 

@end

@implementation ESSipLibConfig


- (BOOL) vad {
    return [[self.contentDic objectForKey:@"vad"] boolValue];
}

- (NSString*) transType {
    return [self.contentDic objectForKey:@"transType"];
    
}
- (int) natType {
    return [[self.contentDic objectForKey:@"natType"] intValue];
}

- (BOOL) mediaHasIoqueue {
    return [[self.contentDic objectForKey:@"mediaHasIoqueue"] boolValue];
}
- (int) mediaClockRate {
    return [[self.contentDic objectForKey:@"mediaClockRate"] intValue];
}
- (int) mediaQuality {
    return [[self.contentDic objectForKey:@"mediaQuality"] intValue];
}
- (int) mediaEcOptions {
    return [[self.contentDic objectForKey:@"mediaEcOptions"] intValue];
}
- (int) mediaEcTailLen {
    return [[self.contentDic objectForKey:@"mediaEcTailLen"] intValue];
}
- (int) mediaThreadCnt {
    return [[self.contentDic objectForKey:@"mediaThreadCnt"] intValue];
}
- (NSString*)  mediaTransportAddress {
    return [self.contentDic objectForKey:@"mediaTransportAddress"];
}
- (int) mediaTransportPort {
    return [[self.contentDic objectForKey:@"mediaTransportPort"] intValue];
}

- (BOOL) natIceEnable {
    return [[self.contentDic objectForKey:@"natIceEnable"] boolValue];
}
- (BOOL) natTurnEnable {
    return [[self.contentDic objectForKey:@"natTurnEnable"] boolValue];
}
- (int) natRewriteUse {
    return [[self.contentDic objectForKey:@"natRewriteUse"] intValue];
}

- (int) contactRewriteUse {
    return [[self.contentDic objectForKey:@"contactRewriteUse"] intValue];
}
- (int) viaRewriteUse {
    return [[self.contentDic objectForKey:@"viaRewriteUse"] intValue];
}

- (int) srtpUse {
    return [[self.contentDic objectForKey:@"srtpUse"] intValue];
}

- (int) sndCloseTime {
    return [[self.contentDic objectForKey:@"sndCloseTime"] intValue];
}
- (int) registerHeart {
    return [[self.contentDic objectForKey:@"registerHeart"] intValue];
}
- (int) registerTimeout {
    return [[self.contentDic objectForKey:@"registerTimeout"] intValue];
}
- (int) dtmfType {
    return [[self.contentDic objectForKey:@"dtmfType"] intValue];
}


@end


@implementation ESConfig

@synthesize eslib = _eslib, esapi = _esapi, payloadTypes = _payloadTypes;

- (NSString*) version {
    return [self.contentDic objectForKey:@"version"];
}

- (NSString*) video {
    return [self.contentDic objectForKey:@"video"];
}

- (ESSipLibConfig*) eslib {
    if (!_eslib) {
        _eslib = [[ESSipLibConfig alloc] initWithDictionary:[self.contentDic objectForKey:@"eslib"]];
    }
    return _eslib;
}

- (ESApiConfig*)esapi {
    if (!_esapi) {
        _esapi = [[ESApiConfig alloc] initWithDictionary:[self.contentDic objectForKey:@"esapi"]];
    }
    return _esapi;
} 
 
- (NSArray *) payloadTypes {
    if (!_payloadTypes) {
        NSMutableArray* array = [[NSMutableArray alloc] init];
        _payloadTypes = array;
        NSArray* pts = [self.contentDic objectForKey:@"payloadTypes"];
        for (NSDictionary* item in pts) {
            ESPayloadTypes* payloadType = [[ESPayloadTypes alloc] initWithDictionary:item];
            [array addObject:payloadType];
        }
    }
    return _payloadTypes;
}


@end
