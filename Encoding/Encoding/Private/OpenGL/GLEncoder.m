//
// Created by mdaymard on 22/08/2017.
// Copyright (c) 2017 Sharalike. All rights reserved.
//

#import "GLEncoder.h"
#import "Logger.h"
#include <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <Photos/Photos.h>

static NSString* TAG = @"GLEncoder";
static BOOL verbose = NO;

@interface GLEncoder () {
    CVOpenGLESTextureCacheRef _coreVideoTextureCache;
    CVPixelBufferRef _renderTarget;
    int frameCpt;

    //dispatch_queue_t videoWriterQueue;
}

@property (nonatomic, assign) GLuint fboHook;
@property (nonatomic, assign) GLuint fboTexture;
@property (nonatomic, assign) int videoWidth;
@property (nonatomic, assign) int videoHeight;
@property (nonatomic, assign) int FPS;
@property (nonatomic, assign) BOOL isEncodingFrame;
@property (nonatomic, assign) BOOL hasFinishedEncoding;
@property (nonatomic, strong) NSString * videoFilePath;
@property (nonatomic, strong) EAGLContext * eaglContext;
@property (nonatomic, strong) NSString * fileType;
@property (nonatomic, strong) NSURL * videoFileURL;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *inputPixelBufferAdapter;

@property (nonatomic, strong) id<GLEncoderDelegate> _delegate;

@end

@implementation GLEncoder {

}

- (id)initWithWidth:(int)videoWidth andHeight:(int)videoHeight andFPS:(int)FPS andEAGLContext:(EAGLContext *)context {
    self.videoWidth = videoWidth;
    self.videoHeight = videoHeight;
    self.FPS = FPS;
    self.eaglContext = context;
    self.fileType = AVFileTypeMPEG4;

    frameCpt = 0;

    //videoWriterQueue = dispatch_queue_create("com.avincel.v360.encoderQueue", NULL);

    return self;
}

- (void)setupEncoding:(nonnull NSString *)oVideoFilePath fboHook:(GLuint)fboHook {
    [Logger dbg:TAG message:@"Initializing video encoder"];

    self.fboHook = fboHook;
    self.videoFilePath = oVideoFilePath;
    self.videoFileURL = [NSURL fileURLWithPath:oVideoFilePath];
    self.isEncodingFrame = NO;
    self.hasFinishedEncoding = NO;

    if(! [self.videoFileURL isFileURL])
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Output file is not a valid URL"
                                     userInfo:nil];

    if ([[NSFileManager defaultManager] fileExistsAtPath:self.videoFilePath ])
        [[NSFileManager defaultManager] removeItemAtPath:self.videoFilePath  error:nil];

    NSError *error = nil;
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.videoFileURL
                                                 fileType:self.fileType
                                                    error:&error];
    if (error)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Error initializing AVAssetWriter"
                                     userInfo:nil];

    NSDictionary *outputSettingsDictionary = @{AVVideoCodecKey:
            AVVideoCodecH264,
            AVVideoWidthKey:
            @(self.videoWidth),
            AVVideoHeightKey:
            @(self.videoHeight)};

    self.assetWriterInput = [AVAssetWriterInput
            assetWriterInputWithMediaType:AVMediaTypeVideo
                           outputSettings:outputSettingsDictionary];

    //self.assetWriterInput.expectsMediaDataInRealTime = YES;

    if(!self.assetWriterInput)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Error initializing AVAssetWriterInput"
                                     userInfo:nil];

    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
            @(kCVPixelFormatType_32BGRA),
            kCVPixelBufferPixelFormatTypeKey,
            @(self.videoWidth),
            kCVPixelBufferWidthKey,
            @(self.videoHeight),
            kCVPixelBufferHeightKey,
                    nil];

    self.inputPixelBufferAdapter = [AVAssetWriterInputPixelBufferAdaptor
            assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.assetWriterInput
                                       sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];

    if(!self.inputPixelBufferAdapter)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Error initializing AVAssetWriterInputPixelBufferAdaptor"
                                     userInfo:nil];

    if (![self.assetWriter canAddInput:self.assetWriterInput])
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Impossible to add input to AVAssetWriter"
                                     userInfo:nil];

    [self.assetWriter addInput:self.assetWriterInput];

    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:CMTimeMake(0, self.FPS)];

    _coreVideoTextureCache = NULL;
    _renderTarget = NULL;

    // PIXEL BUFFER POOL / TEXTURE CACHE
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
            NULL,
            self.eaglContext,
            NULL,
            &_coreVideoTextureCache);

    if (err)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"Impossible to create the texture cache"
                                     userInfo:nil];


    CVPixelBufferPoolCreatePixelBuffer(NULL,
            [self.inputPixelBufferAdapter pixelBufferPool],
            &_renderTarget);

    CVOpenGLESTextureRef renderTexture;
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            _coreVideoTextureCache,
            _renderTarget,
            NULL,
            GL_TEXTURE_2D,
            GL_RGBA,
            self.videoWidth,
            self.videoHeight,
            GL_BGRA,
            GL_UNSIGNED_BYTE,
            0,
            &renderTexture);

    // Then fboTexture parameter is useless ?
    self.fboTexture = CVOpenGLESTextureGetName(renderTexture);
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), self.fboTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glBindFramebuffer(GL_FRAMEBUFFER, self.fboHook);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self.fboTexture, 0);
}

- (BOOL)isReady {
    return [self isReadyToEncodeNewFrame];
}

- (BOOL)encodedFrameAtIndex:(int32_t)frameIndex {

    if(verbose)
        [Logger dbg:TAG message:@"Trying to encode new frame"];

    __block BOOL success = NO;

    if (!self.hasFinishedEncoding) {
        self.isEncodingFrame = YES;

        if (self.assetWriterInput.readyForMoreMediaData) {

            if(self._delegate)
                [self._delegate updateAndDrawForEncoder];

            //glFinish();
            //dispatch_sync(videoWriterQueue, ^ {
                CVPixelBufferLockBaseAddress(_renderTarget, 0);
                success = [self encodeFrameInternal];
                CVPixelBufferUnlockBaseAddress(_renderTarget, 0);
            //});

            // This is here to prevent the output from being jerky
            // No workaround found yet
            //[NSThread sleepForTimeInterval:0.1];
        }
        else
            [Logger warn:TAG message:@"AVAssetWriter not ready to encode"];

        //CVOpenGLESTextureCacheFlush(_coreVideoTextureCache, 0);

        self.isEncodingFrame = NO;
    }
    else
        [Logger warn:TAG message:@"Already finished to encode"];

    return success;
}

- (BOOL)encodeFrameInternal {
    BOOL success = NO;
    //CMTime frameTime = CMTimeMake(frameIndex, self.FPS);
    CMTime frameTime = CMTimeMake(frameCpt, self.FPS);
    if ([_inputPixelBufferAdapter appendPixelBuffer:_renderTarget withPresentationTime:frameTime]) {
        //[Logger dbg:TAG message:[NSString stringWithFormat:@"Frame %i encoded",frameCpt]];
        frameCpt++;
        success = YES;
    }
    else {
        [Logger err:TAG message:@"Problem appending pixel buffer"];
        NSString *errorMessage;
        AVAssetWriterStatus status = self.assetWriter.status;

        if (status != AVAssetWriterStatusCompleted) {
            if (status == AVAssetWriterStatusFailed) {
                NSError *error = self.assetWriter.error;
                if (error)
                    errorMessage = [NSString stringWithFormat:@"AVAssetWriter error %@, user info : %@.", error, [error userInfo]];
                else
                    errorMessage = @"NULL AVAssetWriter error";
            }
            else
                errorMessage = [NSString stringWithFormat:@"AVAssetWriter status : %ld", (long) status];
        }
        else
            errorMessage = @"Error but AVAssetWriterStatusCompleted";

        [Logger err:TAG message:errorMessage];
    }
    return success;
}

- (void)finishEncoding:(BlockRunnable)completionHandler {
    self.hasFinishedEncoding = YES;
    // http://stackoverflow.com/questions/4149963/this-code-to-write-videoaudio-through-avassetwriter-and-avassetwriterinputs-is
    [self.assetWriterInput markAsFinished];
    // not necessary :
    //[self.assetWriter endSessionAtSourceTime:CMTimeMake((long long) frameIndex, _FPS)];
    [self.assetWriter finishWritingWithCompletionHandler:^{
        [self exportVideoToCameraRoll];
        [Logger dbg:TAG message:@"Encoding finished"];
        self.assetWriter = nil;
        completionHandler();
    }];
}

- (void)exportVideoToCameraRoll {
    __block PHObjectPlaceholder *placeholder;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:self.videoFilePath]];
        placeholder = [createAssetRequest placeholderForCreatedAsset];
    } completionHandler:^(BOOL success, NSError *error) {
        NSString *localIdentifier = nil;
        if(success) {
            localIdentifier = placeholder.localIdentifier;
        }
    }];
}

- (void)releaseEncoder {
    
}

- (BOOL)isReadyToEncodeNewFrame {
    return (self.assetWriterInput.readyForMoreMediaData && !self.isEncodingFrame);
}

- (void)setDelegate:(id<GLEncoderDelegate>)delegate {
    self._delegate = delegate;
}

@end
