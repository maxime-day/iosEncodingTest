

#import "GLColor.h"

@interface GLColor () {

}

@end

@implementation GLColor {

}

- (instancetype)initWithR:(float)r G:(float)g B:(float)b A:(float)a {
    self.r = r;
    self.g = g;
    self.b = b;
    self.a = a;
    return self;
}

- (instancetype)initWithRGBAarray:(NSArray<NSNumber *> *)rgbaArray {
    self.r = [rgbaArray[0] floatValue];
    self.g = [rgbaArray[1] floatValue];
    self.b = [rgbaArray[2] floatValue];
    if([rgbaArray count] > 3)
        self.a = [rgbaArray[3] floatValue];
    else
        self.a = 1.f;
    return self;
}

- (instancetype)initWithHex:(NSString *)hexColor {
    hexColor = [hexColor stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([hexColor length] == 6)
        hexColor = [hexColor stringByAppendingString:@"ff"];

    unsigned int baseValue;
    [[NSScanner scannerWithString:hexColor] scanHexInt:&baseValue];

    self.r = ((baseValue >> 24) & 0xFF)/255.f;
    self.g = ((baseValue >> 16) & 0xFF)/255.f;
    self.b = ((baseValue >> 8) & 0xFF)/255.f;
    self.a = ((baseValue >> 0) & 0xFF)/255.f;

    return self;
}

+ (instancetype)colorWithR:(float)r g:(float)g b:(float)b a:(float)a {
    return [[self alloc] initWithR:r G:g B:b A:a];
}


- (NSArray<NSNumber *> *)toRGBAarray {
    NSArray *array = @[@(self.r), @(self.g), @(self.b), @(self.a)];
    return array;
}
/*
- (float *)toRGBArray {
    float *array = new float[4];
    array[0] = self.r;
    array[1] = self.g;
    array[2] = self.b;
    array[3] = self.a;
    return array;
}*/

+ (instancetype)copyColor:(GLColor *)other {
    return [[GLColor alloc] initWithRGBAarray:[other toRGBAarray]];
}

- (void)setColorToArray:(float *)array {
    array[0] = self.r;
    array[1] = self.g;
    array[2] = self.b;
    array[3] = self.a;
}

@end
