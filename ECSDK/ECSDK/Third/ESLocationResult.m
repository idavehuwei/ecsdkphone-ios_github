//
//  ESNumberPoolResult.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESLocationResult.h"

#import "../Utils/NSData+JXEncrypt.h"
#import "../Utils/NSString+Encrypt.h"
#import "../Utils/NSString+DataCoder.h"

@implementation ESLocationBase

- (id) initWithDictionary:(NSDictionary*)dictionary {
    if (self = [super init]) {
        self.contentDic = dictionary;
    }
    
    return self;
}

@end

 
@implementation LocationBinding
- (NSDictionary*)  locationList {
    return self.contentDic;
}
@end

@implementation ESLocationResult

@synthesize locationBinding;

- (int)  resCode {
    return [self.contentDic objectForKey:@"resCode"];
}
- (LocationBinding*) data {
    if (!self.locationBinding) {

        NSString *AES_KEY = @"1vF3r3Uo6al0u2OX";
        NSString *AES_IV = @"bfGuA9cL6i0aA9C2";
        
       //"dAsQGKxmrLw9im59%2Btz9zdUGhEaNjOCVVtnaRp91f2cWLN%2BTor7yfsmETfYhCHMt8mICbEWvBGXsFNJvttXvXc8TyE%2FrPvBD%2FCtzTVx3Yu3vXtkNuRcSOWDX3%2FnX9EnM1ynqR%2B0ubt8wLQL9qAdFzg%3D%3D"
      
       //{SIPProxyPort=60000, SIPIP=218.78.0.205, SIPProxyIP=218.78.0.205, DoMain=vorsbc.dictccyun.com, SIPPort=60000}
 
        NSString *jStr = [self.contentDic objectForKey:@"data"];
        
        NSString *decryptedURLString = [jStr jx_URLDecode];
        
        NSString *decryptedString = [decryptedURLString jx_decryptWithType:JXStringCryptTypeAES128 key:AES_KEY iv:AES_IV base64Handle:TRUE];
        
        NSDictionary *dic = [decryptedString decodeData];
        
        self.locationBinding = [[LocationBinding alloc] initWithDictionary:dic];
        
    }
    return self.locationBinding;
}
- (NSString*) resMsg {
    return [self.contentDic objectForKey:@"resMsg"];
}

@end
 
