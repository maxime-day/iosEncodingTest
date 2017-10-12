//
// Created by mdaymard on 11/10/2017.
// Copyright (c) 2017 AVCL. All rights reserved.
//

#import "GLScene.h"

#import "GLColor.h"
#import "GLRectangle.h"
#import "CC3GLMatrix.h"
#import "GLSize.h"
#import "GLUtils.h"
#import "RectangleF.h"
#import "GLTexture.h"

static NSString *TAG = @"GLScene";

@interface GLScene () {
    GLuint fbo, fboBuffer, fboTexture;
}

@property (nonatomic, strong)GLSize *size;
@property (nonatomic, strong)CC3GLMatrix *viewMatrix, *projMatrix, *mvpMatrix;

@property (nonatomic, strong)GLColor *whiteColor;
@property (nonatomic, strong)GLRectangle *rectangle;

@property (nonatomic, strong)GLTexture *fboGLTexture;

@end

@implementation GLScene {

}

- (instancetype)init {
    self.whiteColor = [GLColor colorWithR:1 g:1 b:1 a:1];
    return self;
}

- (void)setupWithSize:(GLSize *)size {
    self.size = size;

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    [self drawBackground];
    [self setupCamera];
    [self setupModel];
    [self setupFBO];

    [GLUtils checkGLError:@"setupWithSize"];
}

- (void)setRectangleColor:(GLColor *)color {
    [self.rectangle setColor:color];
}

- (void)setupCamera {
    int width = self.size.width;
    int height = self.size.height;

    glViewport(0, 0, width, height);

    self.projMatrix = [CC3GLMatrix matrix];
    float ratio = (float) width / (float) height;

    if(width > height)
        [self.projMatrix populateFromFrustumLeft:-ratio
                                        andRight:ratio
                                       andBottom:-1
                                          andTop:1
                                         andNear:1
                                          andFar:10];
    else
        [self.projMatrix populateFromFrustumLeft:-1
                                        andRight:1
                                       andBottom:-1/ratio
                                          andTop:1/ratio
                                         andNear:1
                                          andFar:10];


    float useForOrtho = (float)fmin(width, height);
    float halfScreen = useForOrtho / 2.f;

    self.viewMatrix = [CC3GLMatrix matrix];
    [self.viewMatrix populateOrthoWithLeft:-halfScreen
                                  andRight:halfScreen
                                 andBottom:-halfScreen
                                    andTop:halfScreen
                                   andNear:0.001f
                                    andFar:100.f];

    self.mvpMatrix = [CC3GLMatrix multiplyMat:self.projMatrix.glMatrix
                                     byMatrix:self.viewMatrix.glMatrix];

    [GLUtils checkGLError:@"setupMatrices"];
}

- (void)setupModel {
    int size = self.size.width / 2;

    RectangleF *rec = [RectangleF rectangleWithX:0
                                               y:0
                                               w:size
                                               h:size];

    self.rectangle = [[GLRectangle alloc] initWithRectangle:rec color:self.whiteColor];
}

- (void)setupFBO {
    GLint maxRenderBufferSize;
    glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &maxRenderBufferSize);

    GLuint textureWidth = (GLuint)self.size.width;
    GLuint textureHeight = (GLuint)self.size.height;

    if(maxRenderBufferSize <= (GLint)textureWidth || maxRenderBufferSize <= (GLint)textureHeight)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"FBO cannot allocate that much space"
                                     userInfo:nil];

    glGenFramebuffers(1, &fbo);
    glGenRenderbuffers(1, &fboBuffer);

    glBindFramebuffer(GL_FRAMEBUFFER, fbo);

    glGenTextures(1, &fboTexture);
    glBindTexture(GL_TEXTURE_2D, fboTexture);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fboTexture, 0);

    glBindRenderbuffer(GL_RENDERBUFFER, fboBuffer);

    GLuint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if(status != GL_FRAMEBUFFER_COMPLETE)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Failed to initialize fbo"
                                     userInfo:nil];

    RectangleF *fboRectangle = [RectangleF rectangleWithX:-1 // -1
                                                        y:-1 // -1
                                                        w:2.f//2.f//textureWidth
                                                        h:2.f];//2.f];//textureHeight];

    self.fboGLTexture = [GLTexture textureWithRectangle:fboRectangle
                                                  color:self.whiteColor
                                              glTexture:fboTexture
                                               inverted:YES];
}

- (void)drawBackground {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    [GLUtils checkGLError:@"drawBackground"];
}

- (void)updateAndDraw {

    [self.rectangle rotateZ:0.5];
    
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);

    [self drawBackground];
    [self.rectangle draw:self.mvpMatrix.glMatrix];

    [GLUtils checkGLError:@"updateAndDraw"];
}

- (void)drawFBO {
    CC3GLMatrix *matrix = [CC3GLMatrix identity];
    [self.fboGLTexture draw:matrix.glMatrix];
}

- (void)free {
    [self.rectangle free];
    [GLUtils checkGLError:@"free"];
}

- (uint)getFBOHook {
    return fbo;
}

@end
