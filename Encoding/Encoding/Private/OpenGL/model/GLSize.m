

#import "GLSize.h"


@implementation GLSize {

}
- (instancetype)initWithWidth:(int)width height:(int)height {
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
    }

    return self;
}

+ (instancetype)sizeWithWidth:(int)width height:(int)height {
    return [[self alloc] initWithWidth:width height:height];
}

+ (instancetype)fromCGSize:(CGSize)size {
    return [[self alloc] initWithWidth:size.width height:size.height];
}

@end
