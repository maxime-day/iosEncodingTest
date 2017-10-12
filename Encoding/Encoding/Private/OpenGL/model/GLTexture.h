

#import <Foundation/Foundation.h>
#import "GLDrawable.h"
#include <OpenGLES/ES2/gl.h>

@class RectangleF;


@interface GLTexture : NSObject<GLDrawable>

+ (instancetype)textureWithRectangle:(RectangleF *)rectangle
                               color:(GLColor *)color
                          glTexture:(GLuint)glTexture
                            inverted:(BOOL)inverted;

- (void)setX:(float)x;

@end
