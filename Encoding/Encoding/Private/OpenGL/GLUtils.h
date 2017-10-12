

#import <Foundation/Foundation.h>
#include <OpenGLES/ES2/gl.h>
#import <OpenGLES/EAGL.h>

@interface GLUtils : NSObject

+ (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType;

+ (GLuint)compileProgram:(GLuint)vertexShader fragmentShader:(GLuint)fragmentShader;

+ (void)checkGLError:(NSString *)name;

+ (void)releaseProgram:(GLuint)program vertexShader:(GLuint)vertexShader fragmentShader:(GLuint)fragmentShader;

+ (void)removeGLContext;

+ (BOOL)contextIsCurrent:(EAGLContext *)context;
+ (void)setGLContext:(EAGLContext *)context;

+ (GLuint)getGLTextureFromResource:(NSString *)resourceName;

@end
