
#import <Foundation/Foundation.h>
#import "GLDrawable.h"

@class RectangleF;


@interface GLRectangle : NSObject<GLDrawable>

- (instancetype)initWithRectangle:(RectangleF *)rectangle
                            color:(GLColor *)color;

- (void)setX:(float)x;

- (void)rotateZ:(float)degrees;

@end
