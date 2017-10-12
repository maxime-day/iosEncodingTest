

#import <Foundation/Foundation.h>
#include <OpenGLES/ES2/gl.h>
#import <OpenGLES/EAGL.h>
#import "BlockRunnable.h"

@protocol GLEncoderDelegate
- (void) updateAndDrawForEncoder;
@end

@interface GLEncoder : NSObject

- (instancetype)init __attribute__((unavailable("init not available")));

- (id)initWithWidth:(int)videoWidth
          andHeight:(int)videoHeight
             andFPS:(int)FPS
     andEAGLContext:(EAGLContext *)context;

- (void)setupEncoding:(nonnull NSString *)oVideoFilePath
             fboHook:(GLuint)fboHook;

- (BOOL)isReady;

- (BOOL)encodedFrameAtIndex:(int32_t)index;

- (void)finishEncoding:(BlockRunnable)completionHandler;

- (void)setDelegate:(id<GLEncoderDelegate>)delegate;

- (void)releaseEncoder;

@end
