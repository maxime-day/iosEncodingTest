
#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

@interface GLSize : NSObject

@property(nonatomic, assign)int width;
@property(nonatomic, assign)int height;

- (instancetype)initWithWidth:(int)width height:(int)height;

+ (instancetype)sizeWithWidth:(int)width height:(int)height;

+ (instancetype)fromCGSize:(CGSize)size;

@end
