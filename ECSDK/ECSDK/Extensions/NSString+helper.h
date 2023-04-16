//
//  NSString+helper.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Helper)

- (NSString *)trim;
- (BOOL)containString:(NSString *)string;
- (BOOL)isEmpty;
- (NSString *)detectLanguage;
- (BOOL)isEmojiString;
- (NSString *)stringWithoutEmoji;
- (NSString *)stringByReplacingChineseMark;

- (BOOL)isArabic;

@end

NS_ASSUME_NONNULL_END
