

#import "GLUtils.h"
#import "Logger.h"
#import <UIKit/UIKit.h>

static NSString *TAG = @"GLUtils";

@implementation GLUtils {

}

+ (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString || error)
        @throw [NSException exceptionWithName:TAG
                                       reason:error.localizedDescription
                                     userInfo:nil];

    GLuint shaderHandle = glCreateShader(shaderType);

    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);

    glCompileShader(shaderHandle);

    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        @throw [NSException exceptionWithName:TAG
                                       reason:[NSString stringWithUTF8String:messages]
                                     userInfo:nil];
    }

    return shaderHandle;
}

+ (GLuint)compileProgram:(GLuint)vertexShader fragmentShader:(GLuint)fragmentShader {
    GLuint programHandle = glCreateProgram();

    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        @throw [NSException exceptionWithName:TAG
                                       reason:[NSString stringWithUTF8String:messages]
                                     userInfo:nil];
    }
    return programHandle;
}

+ (void)checkGLError:(NSString *)name {
    GLenum err = glGetError();

    NSString *errorMessage = @"";

    while (err != GL_NO_ERROR) {
        switch (err) {
            case GL_INVALID_OPERATION:
                errorMessage = [errorMessage stringByAppendingString:@"INVALID_OPERATION "];
                break;
            case GL_INVALID_ENUM:
                errorMessage = [errorMessage stringByAppendingString:@"INVALID_ENUM "];
                break;
            case GL_INVALID_VALUE:
                errorMessage = [errorMessage stringByAppendingString:@"INVALID_VALUE "];
                break;
            case GL_OUT_OF_MEMORY:
                errorMessage = [errorMessage stringByAppendingString:@"OUT_OF_MEMORY "];
                break;
            case GL_INVALID_FRAMEBUFFER_OPERATION:
                errorMessage = [errorMessage stringByAppendingString:@"INVALID_FRAMEBUFFER_OPERATION "];
                break;
            default :
                errorMessage = [errorMessage stringByAppendingString:@"default "];
                break;
        }

        err = glGetError();
    }

    if([errorMessage length] > 0)
        @throw [NSException exceptionWithName:TAG
                                       reason:[NSString stringWithFormat:@"name : %@, error : %@", name, errorMessage]
                                     userInfo:nil];
}


+ (void)releaseProgram:(GLuint)program
          vertexShader:(GLuint)vertexShader
        fragmentShader:(GLuint)fragmentShader {
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    glDeleteProgram(program);
}

+ (void)removeGLContext {
    EAGLContext *currentContext = [EAGLContext currentContext];
    
    if(currentContext) {
        if (![EAGLContext setCurrentContext:nil])
            @throw [NSException exceptionWithName:TAG
                                           reason:@"Failed to remove current EAGL context"
                                         userInfo:nil];
        
        currentContext = [EAGLContext currentContext];
        
        if(currentContext)
            @throw [NSException exceptionWithName:TAG
                                           reason:@"Failed to apply no OpenGL context"
                                         userInfo:nil];
    }

    [GLUtils checkGLError:@"GLUtils removeCurrentContext"];
}

+ (BOOL)contextIsCurrent:(EAGLContext *)context {
    EAGLContext *currentContext = [EAGLContext currentContext];
    return currentContext == context;
}


+ (void)setGLContext:(EAGLContext *)context {

    if(!context)
        [GLUtils removeGLContext];
    else {
        EAGLContext *currentContext = [EAGLContext currentContext];
        if (currentContext)
            [Logger warn:TAG message:@"Will set a new EAGL context on an existant one"];

        if (![EAGLContext setCurrentContext:context])
            @throw [NSException exceptionWithName:TAG
                                           reason:@"Failed to set a new EAGL context"
                                         userInfo:nil];

        currentContext = [EAGLContext currentContext];

        if(currentContext != context)
            @throw [NSException exceptionWithName:TAG
                                           reason:@"Failed to apply a new EAGL context"
                                         userInfo:nil];
    }

    [GLUtils checkGLError:@"GLUtils setCurrentContext"];
}

+ (GLuint)getGLTextureFromResource:(NSString *)resourceName {
    UIImage *uiImage = [UIImage imageNamed:resourceName];
    if(!uiImage)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Failed to retrieve UIImage from resource"
                                     userInfo:nil];
    return [GLUtils getGLTextureFromUIImage:uiImage];
}

+ (GLuint) getGLTextureFromUIImage:(UIImage *)uIImage {
    CGImageRef cgiImage = uIImage.CGImage;
    if(!cgiImage)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Failed to retrieve CGImageRef from UIImage"
                                     userInfo:nil];

    return [GLUtils getGLTextureFromCGIImage:cgiImage];
}

+ (GLuint) getGLTextureFromCGIImage:(CGImageRef)cgiImage {
    size_t width = CGImageGetWidth(cgiImage);
    size_t height = CGImageGetHeight(cgiImage);

    GLubyte *spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef spriteContext = CGBitmapContextCreate(spriteData,
            width,
            height,
            bitsPerComponent,
            bytesPerRow,
            colorSpace,
            kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    CGColorSpaceRelease(colorSpace);

    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), cgiImage);
    CGContextRelease(spriteContext);

    return [GLUtils getGLTextureFromPixelsInFormat:GL_RGBA
                                                  width:(int)width
                                                 height:(int)height
                                                 pixels:spriteData];
}

+ (GLuint)getGLTextureFromPixelsInFormat:(GLenum)format
                                   width:(int)width
                                  height:(int)height
                                  pixels:(void *)pixels {
    GLuint texture;

    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &texture);

    glBindTexture(GL_TEXTURE_2D, texture);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    GLenum type = GL_UNSIGNED_BYTE;
    if(format == GL_RGB) // RGB565
        type = GL_UNSIGNED_SHORT_5_6_5;

    glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, type, pixels);

    free(pixels);

    [GLUtils checkGLError:@"GLMediaUtils getGLTextureFromPixelsInFormat"];

    return texture;
}

@end
