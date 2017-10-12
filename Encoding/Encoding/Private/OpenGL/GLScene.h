//
// Created by mdaymard on 11/10/2017.
// Copyright (c) 2017 AVCL. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLSize;
@class GLColor;


@interface GLScene : NSObject

- (instancetype)init;
- (void)setupWithSize:(GLSize *)size;
- (void)setRectangleColor:(GLColor *)color;
- (void)updateAndDraw;
- (void)drawFBO;
- (void)free;

- (uint)getFBOHook;
@end