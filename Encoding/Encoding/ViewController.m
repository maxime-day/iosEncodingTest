

#import "ViewController.h"
#import "CC3GLMatrix.h"

#import "GLView.h"
#import "GLScene.h"
#import "GLUtils.h"
#import "GLSize.h"
#import "GLEncoderManager.h"
#import "Utilities.h"
#import <MediaPlayer/MediaPlayer.h>

static NSString *TAG = @"ViewController";

@interface ViewController () <GLEncoderListener> {
    GLuint colorRenderBuffer, frameBuffer;
}

@property(strong, nonatomic) IBOutlet GLView *glView;
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, strong) NSRunLoop *runLoop;

@property(nonatomic, strong) EAGLContext *context;
@property(nonatomic, strong) GLScene *scene;
@property(nonatomic, strong) GLSize *size;

// encoding
@property(nonatomic, assign) BOOL isEncoding;
@property(nonatomic, strong) GLEncoderManager *encoderManager;
@property(nonatomic, strong) NSString *outputFilePath;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.isEncoding = NO;
    
    self.size = [GLSize sizeWithWidth:(int)self.glView.frame.size.width
                               height:(int)self.glView.frame.size.height];

    //[self startEncoding];
    
    
    [self setupOpenGL];
    [self setupDisplay];

    UITapGestureRecognizer *singleFingerTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(handleSingleTap:)];
    [self.glView addGestureRecognizer:singleFingerTap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    [self prepareForEncoding];
    [self startEncoding];
}

- (void)setupOpenGL {
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupGLScene];
}

- (void)setupContext {

    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    self.context = [[EAGLContext alloc] initWithAPI:api];
    if (!self.context)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Failed to initialize OpenGLES 2.0 context"
                                     userInfo:nil];

    [GLUtils setGLContext:self.context];

    [GLUtils checkGLError:@"setupContext"];
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:[self.glView getCAEAGLLayer]];

    [GLUtils checkGLError:@"setupRenderBuffer"];
}

- (void)setupFrameBuffer {
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
            GL_RENDERBUFFER, colorRenderBuffer);

    GLuint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Failed to initialize frame buffer"
                                     userInfo:nil];

    [GLUtils checkGLError:@"setupFrameBuffer"];
}

- (void)setupGLScene {
    self.scene = [[GLScene alloc] init];
    [self.scene setupWithSize:self.size];
}

- (void)setupDisplay {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    self.runLoop = [NSRunLoop currentRunLoop];
    [self.displayLink addToRunLoop:self.runLoop forMode:NSDefaultRunLoopMode];
}

- (void)render:(CADisplayLink *)displayLink {
    if(![GLUtils contextIsCurrent:self.context])
        [GLUtils setGLContext:self.context];

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);

    [self.scene updateAndDraw];

    [self fboToWindow];

    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    
    [GLUtils checkGLError:@"render"];
}

- (void)fboToWindow {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);

    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);

    glClearColor(0, 0, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    glViewport(0, 0, (int)self.glView.frame.size.width, (int)self.glView.frame.size.height);

    [self.scene drawFBO];
}

- (void)prepareForEncoding {
    if(![GLUtils contextIsCurrent:self.context])
        [GLUtils setGLContext:self.context];
    [self stopGLRendering];
    [GLUtils checkGLError:@"prepareForEncoding 1"];
    [self free];
    [GLUtils checkGLError:@"prepareForEncoding 2"];
}

- (void)stopGLRendering {
    [self.displayLink setPaused:YES];
}

- (void)free {
    [GLUtils setGLContext:self.context];
    [self.scene free];

    glDeleteRenderbuffers(1, &colorRenderBuffer);
    colorRenderBuffer = 0;

    glDeleteRenderbuffers(1, &frameBuffer);
    frameBuffer = 0;

    [GLUtils removeGLContext];

    [self.displayLink removeFromRunLoop:self.runLoop forMode:NSDefaultRunLoopMode];
    [self.displayLink invalidate];
    self.displayLink = nil;

    [GLUtils checkGLError:@"free"];
}

- (void)startEncoding {
    if(!self.isEncoding) {
        NSLog(@"encoding started !");

        self.outputFilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        [Utilities createDirectoryAtPath:self.outputFilePath];

        self.outputFilePath = [self.outputFilePath stringByAppendingPathComponent:@"Video"];
        [Utilities createDirectoryAtPath:self.outputFilePath];

        self.outputFilePath = [NSString stringWithFormat:@"%@/%@", self.outputFilePath, @"video.mp4"];
        [Utilities deleteFileIfExists:self.outputFilePath];

        GLSize *size = [[GLSize alloc] initWithWidth:1280 height:720];

        self.encoderManager = [[GLEncoderManager alloc] initWithListener:self];
        [self.encoderManager prepareWithSize:size duration:15];
        [self.encoderManager encode:self.outputFilePath];

    }
}

- (void)onEncodingProgress:(float)progress {
    NSLog(@"encoding progress : %f", progress);
}

- (void)onEncodingCanceled {
    NSLog(@"encoding canceled");
}

- (void)onEncodingFinished {
    NSLog(@"encoding finished !");
    
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:self.outputFilePath]];
    player.view.frame = CGRectMake(0, 0, self.size.width, self.size.height);
    [self.view addSubview:player.view];
    player.repeatMode = MPMovieRepeatModeOne;
    [player play];
}

@end
