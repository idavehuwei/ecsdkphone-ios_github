//
//  ESAccount.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>

//账号注册状态ENUM
typedef NS_ENUM(NSInteger, ES_ACCOUNT_STATE) {
    ES_SOFT_PHONE_STATE_NIL,             //未初始化状态
    ES_SOFT_PHONE_STATE_INIT,            //已初始化、未注册状态
    ES_SOFT_PHONE_STATE_REGISTERING,     //正在注册
    ES_SOFT_PHONE_STATE_REGISTERED       //已注册
};

@interface ESAccount : NSObject<NSCopying>
@property (nonatomic, assign,readonly)      ES_ACCOUNT_STATE state;      //用户状态
@property (nonatomic, assign,readonly)      int                 accessID;   //用户ID， 这里会又pjsip自动c生成，作为唯一的id进行维护
@property (nonatomic, copy) NSString        *userName;                      //用户名
@property (nonatomic, copy) NSString        *password;                      //密码
@property (nonatomic, copy) NSString        *sipHost;                       //sipHost
@property (nonatomic, assign) unsigned      sipPort;                        //sipPort
@property (nonatomic, copy) NSString        *domain;                        //sip域


@end
