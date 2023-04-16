//
//  ESDeptResult.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface ESDeptBase  : NSObject
@property(nonatomic, retain) NSDictionary* contentDic;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end


@interface DeptBinding : ESDeptBase

- (NSArray*)  deptList;
@end
 
@interface ESDeptResult : ESDeptBase

@property(nonatomic, retain) DeptBinding* deptBinding;

- (int)  resCode;
- (DeptBinding*) data;
- (NSString*) resMsg;

@end
 

NS_ASSUME_NONNULL_END

