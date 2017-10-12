

#import <Foundation/Foundation.h>


@interface RectangleF : NSObject

@property (nonatomic, assign)float x, y, w, h;

- (instancetype)initWithX:(float)x y:(float)y w:(float)w h:(float)h;

+ (instancetype)rectangleWithX:(float)x y:(float)y w:(float)w h:(float)h;

+ (instancetype)copyRectangle:(RectangleF *)other;

@end