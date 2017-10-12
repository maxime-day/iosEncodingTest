

#import "Utilities.h"

static NSString *TAG = @"Utilities";

@implementation Utilities {

}

+ (void)executeOnMainThread:(BlockRunnable)block {
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}

+ (void)executeOnBackgroundThread:(BlockRunnable)block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        block();
    });
}

+ (BOOL)fileExistsAtPath:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (NSString *)msg:(NSString *)message reason:(NSError *)reason {
    return [NSString stringWithFormat:@"message : %@ reason : %@" , message, [reason description]];
}

+ (void)deleteFileIfExists:(NSString *)path {
    if([Utilities fileExistsAtPath:path]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if(error != nil)
            @throw [NSException exceptionWithName:TAG
                                           reason:[Utilities msg:@"Cannot delete file" reason:error]
                                         userInfo:nil];
    }
}

+ (void)createDirectoryAtPath:(NSString *)path {
    if(![Utilities fileExistsAtPath:path]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];

        if(error)
            @throw [NSException exceptionWithName:TAG
                                           reason:[Utilities msg:@"Cannot create directory" reason:error]
                                         userInfo:nil];
        //[Utilities throwExceptionWithName:TAG andMessage:@"Cannot create directory" andReason:error];
        //[Logger err:TAG message:[error description]];
    }
    else
        NSLog(@"directory already exists");
}

@end
