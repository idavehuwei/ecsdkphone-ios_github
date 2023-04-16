//
//  ESNetStatusManager.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESNetStatusManager.h"
#import "ESReachability.h"

@interface ESNetStatusManager ()

@property (nonatomic) ESReachability *reachability;
@property (nonatomic, assign) ESNetStatus currentNetStatus;

@end

@implementation ESNetStatusManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static ESNetStatusManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[ESNetStatusManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateCurrentNetStatus];
    }
    return self;
}

- (void)startObserveNetworkStatus {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kESReachabilityChangedNotification object:nil];
    self.reachability = [ESReachability reachabilityForInternetConnection];
    [self.reachability startNotifier];
    [self updateCurrentNetStatus];
}

- (void)reachabilityChanged:(NSNotification *)notification {
    ESReachability *reachability = (ESReachability *)notification.object;
    [self updateCurrentNetStatusWithReachability:reachability];
    if (self.netStatusBlock) {
        self.netStatusBlock(self.currentNetStatus);
    }
}

- (void)stopObserveNetworkStatus {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kESReachabilityChangedNotification object:nil];
    [self.reachability stopNotifier];
}

- (void)updateCurrentNetStatusWithReachability:(ESReachability *)reachability {
    ESNetworkStatus networkStatus = [reachability currentReachabilityStatus];
    switch (networkStatus) {
        case NotReachable:
            self.currentNetStatus = ESNetStatusNotReach;
            break;
        case ReachableViaWiFi:
            self.currentNetStatus = ESNetStatusWiFi;
            break;
        case ReachableViaWWAN:
            self.currentNetStatus = ESNetStatusWWAN;
            break;
    }
}

- (void)updateCurrentNetStatus {
    ESReachability *reachability = [ESReachability reachabilityForInternetConnection];
    [self updateCurrentNetStatusWithReachability:reachability];
}

@end
