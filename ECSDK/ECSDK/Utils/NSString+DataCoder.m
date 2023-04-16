//
//  NSString+DataCoder.m
//  ECSDK
//
//  Created by 高翔 on 2022/8/1.
//

#import "NSString+DataCoder.h"

@implementation NSString (DataCoder)

- (void) decodeData:(NSString *)data toDictionary:(NSMutableDictionary *)dictionary {
    data = [data stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]];
    NSArray<NSString *>* components = [data componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
    NSString* tmpData = nil;
    for (NSString* component in components) {
        tmpData = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([tmpData rangeOfString:@"="].location != NSNotFound) {
            NSArray<NSString *>* dataComponents = [tmpData componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
            if ([dataComponents count] == 2) {
                [dictionary setObject:[dataComponents objectAtIndex:1] forKey:[dataComponents objectAtIndex:0]];
            }
        } else {
            NSLog(@"WARNING: Unknow data format: %@", tmpData);
        }
    }
}

- (void) decodeData:(NSString *)data toArray:(NSMutableArray *)array {
    data = [data stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[] "]];
    
    unichar endToken = '\0';
    NSUInteger dataLength = [data length];// [data lengthOfBytesUsingEncoding:NSUTF8StringEncoding]; 
    for (NSUInteger i = 0; i < dataLength; i++) {
        if ([data characterAtIndex:i] == '[') {
            endToken = ']';
        }
        if ([data characterAtIndex:i] == '{') {
            endToken = '}';
        }
        NSRange searchRange = [data rangeOfString:[NSString stringWithFormat:@"%c", endToken] options:(NSLiteralSearch) range:NSMakeRange(i + 1, dataLength - i - 1)];
        if (searchRange.location != NSNotFound) {
            NSString* token = [data substringWithRange:NSMakeRange(i, searchRange.location - i + 1)];
            token = [token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,"]];
            id result = [token decodeData];
            [array addObject:result];
            i = searchRange.location;
            continue;
        }
    }
    
}

- (id) decodeData {
    NSString* data = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([data characterAtIndex:0] == '[') {
        // 解析数组
        NSMutableArray* array = [NSMutableArray array];
        [self decodeData:data toArray:array];
        return array;
    }
    else if ([data characterAtIndex:0] == '{') {
        // 解析数组
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
        [self decodeData:data toDictionary:dictionary];
        return dictionary;
    }
    
    return nil;
}

@end
