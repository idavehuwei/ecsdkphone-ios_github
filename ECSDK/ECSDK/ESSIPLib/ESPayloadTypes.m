//
//  ESPayloadTypes.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESPayloadTypes.h"


@implementation ESParameters

@synthesize fmtp = _fmtp;
@synthesize contentDic;

- (id) initWithDictionary:(NSDictionary*)dictionary {
    if (self = [super init]) {
        self.contentDic = dictionary;
    }
    
    return self;
}

- (NSArray*) fmtp {
    if (!_fmtp) {
        _fmtp = [[NSArray alloc] initWithArray:[self.contentDic objectForKey:@"fmtp"]];
    }
    return _fmtp;
}

@end


@implementation ESPayloadTypes

@synthesize parameters = _parameters;
@synthesize contentDic;

- (id) initWithDictionary:(NSDictionary*)dictionary {
    if (self = [super init]) {
        self.contentDic = dictionary;
    }
    
    return self;
}

- (int) identify {
    return [[self.contentDic objectForKey:@"id"] intValue];
}

- (NSString*) name {
    return [self.contentDic objectForKey:@"name"];
}

- (int) clockrate {
    return [[self.contentDic objectForKey:@"clockrate"] intValue];
}

- (int) channels {
    return [[self.contentDic objectForKey:@"channels"] intValue];
}

- (ESParameters*) parameters {
    if (!_parameters) {
        _parameters = [[ESParameters alloc] initWithDictionary:[self.contentDic objectForKey:@"parameters"]];
    }
    return _parameters;
}

- (NSString *) codeId {
    return [NSString stringWithFormat:@"%@/%d/%d", self.name, self.clockrate, self.channels == 0 ? 1 : self.channels];
}

@end
