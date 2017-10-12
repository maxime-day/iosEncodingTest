

#import <Foundation/Foundation.h>

@class GLSize;

@protocol GLEncoderListener
- (void)onEncodingProgress:(float)progress; // from 0 to 100
- (void)onEncodingFinished;
@end

@interface GLEncoderManager : NSObject

- (instancetype)initWithListener:(id<GLEncoderListener>)listener;

- (void)prepareWithSize:(GLSize *)size
               duration:(int)durationInSecs;

- (void)encode:(NSString *)outputFilePath; // starts encoding

@end
