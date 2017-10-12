

#import "GLEncoder.h"
#import "GLEncoderManager.h"
#import "GLSize.h"
#import "Logger.h"
#import "GLUtils.h"
#import "GLScene.h"
#import "Utilities.h"

static NSString* TAG = @"GLEncoderDemo";
static int FPS = 30;

@interface GLEncoderManager () <GLEncoderDelegate> {
}

@property(nonatomic, strong) id <GLEncoderListener> listener;
@property(nonatomic, strong) NSString *outputFilePath;
@property(nonatomic, strong) GLSize *size;
@property(nonatomic, assign) int nbSeconds;
@property(nonatomic, strong) GLScene *scene;
@property(nonatomic, assign) int frameCpt;
@property (nonatomic, strong)EAGLContext* context;
@property(nonatomic, strong)GLEncoder *encoder;

@end

@implementation GLEncoderManager {

}

- (instancetype)initWithListener:(id <GLEncoderListener>)listener {
    self.listener = listener;
    return self;
}

- (void)prepareWithSize:(GLSize *)size duration:(int)durationInSecs {
    self.size = size;
    self.nbSeconds = durationInSecs;
}

- (void)encode:(NSString *)outputFilePath {
    self.outputFilePath = outputFilePath;

    [Utilities executeOnBackgroundThread:^ {
        [Logger dbg:TAG message:@"Started GLEncoder "];
        [self initEncoding];
        [self encodeInternal:^ {
            [Utilities executeOnMainThread:^ {
                [self.listener onEncodingFinished];
            }];
        }];
    }];
}

- (void)initEncoding {
    [self initGLContext];
    [self initGLScene];
    [self initEncoder];
    self.frameCpt = 0;
}

- (void)initGLContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    self.context = [[EAGLContext alloc] initWithAPI:api];
    self.context.multiThreaded = YES;

    if (!self.context)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Failed to initialize OpenGLES 2.0 context"
                                     userInfo:nil];

    [GLUtils setGLContext:self.context];
}

- (void)initGLScene {
    self.scene = [[GLScene alloc] init];
    [self.scene setupWithSize:self.size];
}

- (void)encodeInternal:(BlockRunnable)completionHandler {

    int nbFramesNeeded = self.nbSeconds * FPS;
    
    [self.encoder setDelegate:self];
    
    [Logger dbg:TAG message:@"Starting encoding"];

    while(self.frameCpt < nbFramesNeeded) {
        
        // Brandi
        // This line (95, refreshProgress) is increasing CPU usage on purpose. It deeply affects the result video quality.
        // CPU usage should not impact the result video quality obviously.
        // On realtors, the refresh is on line 102, see line 102.
        [self refreshProgress:((float)self.frameCpt / (float)nbFramesNeeded)];
    
        if([self.encoder isReady]) {
            if([self.encoder encodedFrameAtIndex:self.frameCpt]) {
                self.frameCpt++;
                // Brandi
                // This is the real place where progress updates are on realtors
                //[self refreshProgress:((float)self.frameCpt / (float)nbFramesNeeded)];
            }
            else
                NSLog(@"error encoding frame ");
        }
        else
            NSLog(@"not ready ");
    }

    [self.encoder finishEncoding:^ {
        [self free];
        completionHandler();
    }];
}

- (void)updateAndDrawForEncoder {
    [self.scene updateAndDraw];
    glFlush();
}

- (void)refreshProgress:(float) progress {
    [Utilities executeOnMainThread:^ {
        [self.listener onEncodingProgress:progress];
    }];
}

- (void)initEncoder {
    self.encoder = [[GLEncoder alloc] initWithWidth:self.size.width
                                          andHeight:self.size.height
                                             andFPS:FPS
                                     andEAGLContext:self.context];

    [self.encoder setupEncoding:self.outputFilePath
                       fboHook:[self.scene getFBOHook]];
}

- (void)free {
    [self.scene free];
    [GLUtils setGLContext:nil];
    self.context = nil;
}

@end
