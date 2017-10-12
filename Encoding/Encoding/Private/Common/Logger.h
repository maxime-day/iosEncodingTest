
#import <Foundation/Foundation.h>


@interface Logger : NSObject

+ (void)dbg:(NSString *)name message:(NSString *)msg;

+ (void)info:(NSString *)name message:(NSString *)msg;

+ (void)err:(NSString *)name message:(NSString *)msg;

+ (void)warn:(NSString *)name message:(NSString *)msg;

@end