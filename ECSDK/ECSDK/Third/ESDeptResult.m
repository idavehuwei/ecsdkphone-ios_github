//
//  ESDeptResult.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESDeptResult.h"


#import "../Utils/NSData+JXEncrypt.h"
#import "../Utils/NSString+Encrypt.h"
#import "../Utils/NSString+DataCoder.h"
 
@implementation ESDeptBase

- (id) initWithDictionary:(NSDictionary*)dictionary {
    if (self = [super init]) {
        self.contentDic = dictionary;
    }
    
    return self;
}

@end


@implementation DeptBinding

- (NSDictionary*)  deptList {
    return self.contentDic;
}
  
@end

@implementation ESDeptResult

@synthesize deptBinding;

- (int)  resCode {
    return [self.contentDic objectForKey:@"resCode"];
}
- (DeptBinding*) data {
    if (!self.deptBinding) {
        //TODO AES
     
        //jStr    __NSCFString *    @"NosQOMVhd9H37o%2FZl%2F42ncLYXLbFCXd3fDw%2F9oKVCHRiai3QTkSU6LmFD9rWtiIY8eotMkF3LYFuf4Vf3pGM3FHl2iNjL82%2Bgo3b5ULtiXT1NrUJaNBDHAECUQHgQNHEHPfj%2Bp5re4a4RPEEN3rcxtZqiqdFmm6ZtF1TlfqeKwEZPJAdbEhaDIIWWKUCwsYTPTEkUUAb5E55Np2al6kbEQ5YtWPUXw7MSbQ9ax%2Fd9IbY6lNiiKTzZ0fX1iIL0m72TfQ8VYzQc%2BE9Xvlehm20UeBNjkeSa3F26kswwBwBCe8zZGBaJFmuI7V4MImhfnnSfPsqfmF%2BfjrZEj4yJUKx435NsbhKfnPaKmt0ibWSatpwAvePglICTyRF3o2Z4ZwfRWziHTlcMQsuIj4fhiuNSL7HBex40mnZqrkrHOOJmdRHmdyjuuZ3diwJYiWYBELgIL2XA5oTbp6%2BOUMLHQdeEecHvdlEsNGAPBNKE3MvudMQbrGuEOW%2BG6KgZ%2FeDXly43%2BzUB%2FZLPJfeVraqL0f%2FHw%3D%3D"    0x00007f9c7e925df0
        
//        decryptedString    __NSCFString *    @"[{deptName=部门组, deptID=1, deptParent=0}, {deptName=vorsbc, deptID=24, deptParent=1}, {deptName=开发组, deptID=29, deptParent=1}, {deptName=测试组, deptID=31, deptParent=1}, {deptName=负载测试组, deptID=39, deptParent=1}, {deptName=智家阿里测试, deptID=40, deptParent=1}, {deptName=测试, deptID=42, deptParent=1}, {deptName=雨天测试, deptID=49, deptParent=1}]"    0x00007f9c7e92dff0
        
        NSString *AES_KEY = @"1vF3r3Uo6al0u2OX";
        NSString *AES_IV = @"bfGuA9cL6i0aA9C2";
 
        NSString *jStr = [self.contentDic objectForKey:@"data"];
        
        NSString *decryptedURLString = [jStr jx_URLDecode];
        
        NSString *decryptedString = [decryptedURLString jx_decryptWithType:JXStringCryptTypeAES128 key:AES_KEY iv:AES_IV base64Handle:TRUE];
        
        NSDictionary *dic = [decryptedString decodeData];
        
        
        self.deptBinding = [[DeptBinding alloc] initWithDictionary:dic];
    }
    return self.deptBinding;
}
- (NSString*) resMsg {
    return [self.contentDic objectForKey:@"resMsg"];
}

@end
 
