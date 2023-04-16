//
//  ESContactResult.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESContactResult.h"

#import "../Utils/NSData+JXEncrypt.h"
#import "../Utils/NSString+Encrypt.h"
#import "../Utils/NSString+DataCoder.h"
 
@implementation ESContactBase

- (id) initWithDictionary:(NSDictionary*)dictionary {
    if (self = [super init]) {
        self.contentDic = dictionary;
    }
    
    return self;
}

@end


@implementation ContactBinding

 

- (NSDictionary*)  contactList {
    return self.contentDic;
}
@end

@implementation ESContactResult

@synthesize contactBinding;

- (int)  resCode {
    return [self.contentDic objectForKey:@"resCode"];
}
- (ContactBinding*) data {
    if (!self.contactBinding) {
        //TODO AES

        NSString *AES_KEY = @"1vF3r3Uo6al0u2OX";
        NSString *AES_IV = @"bfGuA9cL6i0aA9C2";
        
   
        //jStr    __NSCFString *    @"g5pYrFFxZYJ9Q4nkI2F4EeZa1lnVrR1Wr9Tz079aJOm4gUWsT7UG7le8Kz5zTNqD75YkjsLU0NOHT4nA5jac%2BTFbg9dHvxC72qHyGB5dHkRQLaY4ydC03h3WmL19iDeR17xfkv1Kr4Li9nlrxKFEEZIx4XAsUdNBEZZZR6FkmNDYuwoHXB8B5T56WtyF5quve2u9m8X8J9F5qUJJLLYHfnn9ua9cC00btjWeuEItfBdRuRJMA%2BbEjRR%2BAvU3LDVJU%2BkWyWX0sAd%2FIBPxP674ZZp0buYEZNORbHFNvMhaTyKpYhx8q%2B2tQ15KyTS%2B%2BC86665WK897bwKa2Yt5DvoVHJwBa2q5uo58MM5e0Tfwf7FzIMUo4B4KRMEyjtaE4u0hvV0okBVEgPOW598%2Bl3%2BUXxFm3IULL3i92a2hkSakyY0BftBHoBF%2FDiulvRfLskkyz6KHbH8PsgCxVoNjxcr9nLJdrMF17N7071XW%2BrfFA66hBvVMsheekRampiJFecoVrime5%2FuHzLM1JTcfdQTMcLCMW%2Bk0uNOpPFASwmZrlz9WUOt0zUz%2BKujbG96icNjzqLQcdgdqTouFCWLkn5by%2BA%3D%3D"    0x00007fc78b123720
        
        //decryptedString    __NSCFString *    @"[{extNo=321, deptID=1, extName=null}, {extNo=90000000, deptID=1, extName=null}, {extNo=10000, deptID=1, extName=10000}, {extNo=321321, deptID=1, extName=null}, {extNo=321321, deptID=1, extName=null}, {extNo=5555555555555, deptID=1, extName=null}, {extNo=184540550059140, deptID=1, extName=184540550059140}, {extNo=12345678, deptID=1, extName=12345678}, {extNo=12345679, deptID=1, extName=12345679}, {extNo=12345679, deptID=1, extName=12345679}]"    0x00007fc78b425180
        
        NSString *jStr = [self.contentDic objectForKey:@"data"];
        
        NSString *decryptedURLString = [jStr jx_URLDecode];
        
        NSString *decryptedString = [decryptedURLString jx_decryptWithType:JXStringCryptTypeAES128 key:AES_KEY iv:AES_IV base64Handle:TRUE];
        
        NSDictionary *dic = [decryptedString decodeData];
        
        self.contactBinding = [[ContactBinding alloc] initWithDictionary:dic];
    }
    return self.contactBinding;
}
- (NSString*) resMsg {
    return [self.contentDic objectForKey:@"resMsg"];
}

@end
 
