//
//  ESAudioUtil.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import "ESAudioUtil.h"


@implementation ESAudioUtil

static ESAudioUtil *util=nil;

+ (ESAudioUtil *)sharedManager{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        util=[[self alloc]init];
    });
    
    return util;
}

- (id)init {
    self = [super init];
    if (self) {
        audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [audioSession setActive:YES error:nil];
        
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"adrianro_09b" ofType:@"mp3"];
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundPath];
        self.player = [[AVAudioPlayer alloc]  initWithContentsOfURL:fileURL error:nil];
        vibrateTimer = nil;
    }
    return self;
}

- (void)playSoundOnce {
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.player.numberOfLoops = 0;
    [self.player play];
}

- (void)playSoundConstantly {
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.player.numberOfLoops = -1;
    [self.player play];
}

- (void)playVibrateOnce {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

- (void)playVibrateConstantly {
    [self playVibrateOnce];
    vibrateTimer = [NSTimer scheduledTimerWithTimeInterval:3.5 target:self selector:@selector(playVibrateOnce) userInfo:nil repeats:YES];
}

- (void)stop {
    [self.player stop];
    [self.player setCurrentTime:0];
    [vibrateTimer invalidate];
    vibrateTimer = nil;
}

- (void)setSpeaker {
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
}

- (void)setHeadphone {
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
}

@end
