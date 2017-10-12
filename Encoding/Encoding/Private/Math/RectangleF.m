

#import "RectangleF.h"


@implementation RectangleF {

}
- (instancetype)initWithX:(float)x y:(float)y w:(float)w h:(float)h {
    self = [super init];
    if (self) {
        self.x = x;
        self.y = y;
        self.w = w;
        self.h = h;
    }

    return self;
}

+ (instancetype)rectangleWithX:(float)x y:(float)y w:(float)w h:(float)h {
    return [[self alloc] initWithX:x y:y w:w h:h];
}

+ (instancetype)copyRectangle:(RectangleF *)other {
    return [[RectangleF alloc] initWithX:other.x y:other.y w:other.w h:other.h];
}


@end