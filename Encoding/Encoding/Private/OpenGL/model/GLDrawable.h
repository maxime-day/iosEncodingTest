

#import <Foundation/Foundation.h>

@class GLColor;

@protocol GLDrawable

- (void)draw:(float[])mvpMatrix;
- (void)setColor:(GLColor *)color;
- (void)free;

@end