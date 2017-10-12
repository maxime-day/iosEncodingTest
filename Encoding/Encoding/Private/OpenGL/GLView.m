

#import "GLView.h"

static NSString* TAG = @"GLView";

@interface GLView ()

@property(nonatomic, strong) CAEAGLLayer *caeaglLayer;

- (void)setupEAGLLayer;

@end

@implementation GLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupEAGLLayer];
}

- (void)setupEAGLLayer {
    self.caeaglLayer = (CAEAGLLayer *) self.layer;
    self.caeaglLayer.opaque = YES;
    self.caeaglLayer.drawableProperties = @{
            kEAGLDrawablePropertyRetainedBacking: @YES,
            kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
}

- (CAEAGLLayer *)getCAEAGLLayer {
    if(!self.caeaglLayer)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"CAEAGLLayer is null"
                                     userInfo:nil];

    return self.caeaglLayer;
}


@end