

#import "Logger.h"


@implementation Logger

+ (void)dbg:(NSString *)name message:(NSString *)msg {
    NSLog(@"%@ : Debug : %@", name, msg);
}

+ (void)info:(NSString *)name message:(NSString *)msg {
    NSLog(@"%@ : Info : %@", name, msg);
}

+ (void)err:(NSString *)name message:(NSString *)msg {
    NSLog(@"%@ : ❗Error❗ : %@", name, msg);
}

+ (void)warn:(NSString *)name message:(NSString *)msg {
    NSLog(@"%@ : 🚧 Warning 🚧 : %@", name, msg);
}


@end