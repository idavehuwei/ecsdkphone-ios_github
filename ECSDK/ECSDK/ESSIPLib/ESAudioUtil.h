//
//  ESAudioUtil.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface ESAudioUtil : NSObject{
    AVAudioSession *audioSession;
    NSTimer *vibrateTimer;
}

@property (strong, nonatomic) AVAudioPlayer *player;

+ (ESAudioUtil *) sharedManager; //获取单例对象
- (void)playSoundOnce;
- (void)playSoundConstantly;
- (void)playVibrateOnce;
- (void)playVibrateConstantly;
- (void)stop;
//设置
- (void)setSpeaker;
- (void)setHeadphone;

@end

NS_ASSUME_NONNULL_END
