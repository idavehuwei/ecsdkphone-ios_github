//
//  ESPayloadTypes.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESParameters : NSObject

@property(nonatomic, retain) NSDictionary* contentDic;
@property(readonly) NSArray* fmtp;

- (id) initWithDictionary:(NSDictionary*)dictionary;

- (NSArray*) fmtp;

@end

@interface ESPayloadTypes : NSObject

@property(nonatomic, retain) NSDictionary* contentDic;
@property(readonly) ESParameters* parameters;

- (id) initWithDictionary:(NSDictionary*)dictionary;

- (int) identify;
- (NSString*) name;
- (int) clockrate;
- (int) channels;
- (ESParameters*) parameters;

- (NSString *) codeId;

@end

NS_ASSUME_NONNULL_END
