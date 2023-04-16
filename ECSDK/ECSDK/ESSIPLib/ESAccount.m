//
//  ESAccount.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESAccount.h"

@implementation ESAccount

@synthesize state = _state;
@synthesize accessID = _accessID;

@synthesize userName= _userName;
@synthesize password= _password;
@synthesize domain= _domain;
@synthesize sipHost= _sipHost;
@synthesize sipPort= _sipPort;

- (instancetype)copyWithZone:(NSZone *)zone
{
    //调用NSObject的类方法allocWithZone创建一个新的对象
    ESAccount *softphone = [[self class] allocWithZone:zone];
    //使用mutableCopy获取一个可变的副本对象实现深拷贝
    //如果不调用mutableCopy而直接赋值，则是浅拷贝，另一个对象的修改会影响到当前对象的值
    softphone.userName = [self.userName mutableCopy];
   // softphone.state = self.state;
    
    //softphone.accessID = self.accessID;
    
    softphone.password = self.password;
    softphone.domain = self.domain;
    softphone.sipHost = self.sipHost;
    softphone.sipPort = self.sipPort;
    return softphone;
}

@end//

