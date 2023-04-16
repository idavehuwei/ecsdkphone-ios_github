//
//  ESNetStatusManager.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ESNetStatus) {
    ESNetStatusNotReach = 0,
    ESNetStatusWiFi,
    ESNetStatusWWAN,
};

@interface ESNetStatusManager : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, copy) void(^netStatusBlock)(ESNetStatus netStatus);
@property (nonatomic, assign, readonly) ESNetStatus currentNetStatus;

- (void)startObserveNetworkStatus;
- (void)stopObserveNetworkStatus;

@end
