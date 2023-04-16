//
//  ESContactResult.h
//  ECSDK
//
//  Created by DerekHu on 2022/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface ESContactBase  : NSObject
@property(nonatomic, retain) NSDictionary* contentDic;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end


@interface ContactBinding : ESContactBase
- (NSArray*)  contactList;
@end

@interface ESContactResult : ESContactBase

@property(nonatomic, retain) ContactBinding* contactBinding;

- (int)  resCode;
- (ContactBinding*) data;
- (NSString*) resMsg;

@end
 

NS_ASSUME_NONNULL_END

