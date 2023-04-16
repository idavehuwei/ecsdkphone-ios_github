//
//  NSString+helper.m
//  ECSDK
//
//  Created by DerekHu on 2022/7/29.
//


#import "NSString+Helper.h"

@implementation NSString (Helper)

static NSLock *detectLanguageLock;
static NSLinguisticTagger *tagger;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        detectLanguageLock = [[NSLock alloc] init];
        NSArray *tagschemes = [NSArray arrayWithObjects:NSLinguisticTagSchemeLanguage, nil];
        tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:tagschemes options:0];
    });
}

- (NSString *)trim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)containString:(NSString *)string {
    if (!string || string.length <= 0) {
        return NO;
    }
    return ([self rangeOfString:string].location != NSNotFound);
}

- (BOOL)isEmpty {
    if (self.length <= 0 ) {
        return YES;
    }
    return [[self trim] length] > 0 ? NO : YES;
}


- (BOOL)isEmojiString {
    BOOL returnValue = NO;
    const unichar hs = [self characterAtIndex:0];
    // surrogate pair
    if (0xd800 <= hs && hs <= 0xdbff) {
        if (self.length > 1) {
            const unichar ls = [self characterAtIndex:1];
            const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
            if (0x1d000 <= uc && uc <= 0x1f77f) {
                returnValue = YES;
            }
        }
    } else if (self.length > 1) {
        const unichar ls = [self characterAtIndex:1];
        if (ls == 0x20e3) {
            returnValue = YES;
        }
        
    } else {
        // non surrogate
        if (0x2100 <= hs && hs <= 0x27ff) {
            returnValue = YES;
        } else if (0x2B05 <= hs && hs <= 0x2b07) {
            returnValue = YES;
        } else if (0x2934 <= hs && hs <= 0x2935) {
            returnValue = YES;
        } else if (0x3297 <= hs && hs <= 0x3299) {
            returnValue = YES;
        } else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 || hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
            returnValue = YES;
        }
    }
    
    return returnValue;
}

- (NSString *)stringWithoutEmoji {
    NSMutableString *bufferString = [NSMutableString string];
    
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                              if (![substring isEmojiString]) {
                                  [bufferString appendString:substring];
                              }
                          }];
    
    return bufferString;
}

- (NSString *)stringByReplacingChineseMark {
    NSString *string = nil;
    string = [self stringByReplacingOccurrencesOfString:@"。" withString:@"."];
    string = [string stringByReplacingOccurrencesOfString:@"，" withString:@","];
    string = [string stringByReplacingOccurrencesOfString:@"、" withString:@","];
    string = [string stringByReplacingOccurrencesOfString:@"！" withString:@"!"];
    string = [string stringByReplacingOccurrencesOfString:@"？" withString:@"?"];
    string = [string stringByReplacingOccurrencesOfString:@"；" withString:@";"];
    string = [string stringByReplacingOccurrencesOfString:@"：" withString:@":"];
    string = [string stringByReplacingOccurrencesOfString:@"～" withString:@"~"];
    
    string = [string stringByReplacingOccurrencesOfString:@"（" withString:@"("];
    string = [string stringByReplacingOccurrencesOfString:@"）" withString:@")"];
    string = [string stringByReplacingOccurrencesOfString:@"【" withString:@"["];
    string = [string stringByReplacingOccurrencesOfString:@"】" withString:@"]"];
    string = [string stringByReplacingOccurrencesOfString:@"《" withString:@"<"];
    string = [string stringByReplacingOccurrencesOfString:@"》" withString:@">"];
    string = [string stringByReplacingOccurrencesOfString:@"‘" withString:@"'"];
    string = [string stringByReplacingOccurrencesOfString:@"’" withString:@"'"];
    string = [string stringByReplacingOccurrencesOfString:@"“" withString:@"\""];
    string = [string stringByReplacingOccurrencesOfString:@"”" withString:@"\""];
    
    return string;
}

- (BOOL)isArabic {
    
    NSString *string = [self trim];
    
    if (string.length <= 0) {
        return NO;
    }
    
    NSString *language = (__bridge NSString *)CFStringTokenizerCopyBestStringLanguage((CFStringRef)string, CFRangeMake(0, MIN(string.length, 400)));
    
    if (!language) {
        return NO;
    }
    
    return [language isEqualToString:@"ar"];
}

@end
