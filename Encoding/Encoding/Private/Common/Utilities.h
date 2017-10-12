
#import <Foundation/Foundation.h>
#import "BlockRunnable.h"


@interface Utilities : NSObject

+ (BOOL)fileExistsAtPath:(NSString *)path;
+ (void)executeOnMainThread:(BlockRunnable)block;
+ (void)executeOnBackgroundThread:(BlockRunnable)block;
+ (void)deleteFileIfExists:(NSString *)path;
+ (void)createDirectoryAtPath:(NSString *)path;
@end