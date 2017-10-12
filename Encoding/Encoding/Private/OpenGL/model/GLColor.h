

#import <Foundation/Foundation.h>


@interface GLColor : NSObject

@property(nonatomic, assign)float r;
@property(nonatomic, assign)float g;
@property(nonatomic, assign)float b;
@property(nonatomic, assign)float a;

- (instancetype)initWithR:(float)r
                        G:(float)g
                        B:(float)b
                        A:(float)a;

- (instancetype)initWithRGBAarray:(NSArray<NSNumber *> *)rgbaArray;

- (instancetype)initWithHex:(NSString *)hexColor;


+ (instancetype)colorWithR:(float)r g:(float)g b:(float)b a:(float)a;


- (NSArray<NSNumber *> *)toRGBAarray;
//- (float *)toRGBArray;

+ (instancetype)copyColor:(GLColor *)other;

- (void)setColorToArray:(float *)array;


@end
