//
//  ESlocationResult.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface ESLocationBase  : NSObject
@property(nonatomic, retain) NSDictionary* contentDic;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end


@interface LocationBinding : ESLocationBase
- (NSArray*)  locationList;
@end

@interface ESLocationResult : ESLocationBase

@property(nonatomic, retain) LocationBinding* locationBinding;

- (int)  resCode;
- (LocationBinding*) data;
- (NSString*) resMsg;

@end
 

NS_ASSUME_NONNULL_END

