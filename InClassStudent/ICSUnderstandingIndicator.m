//
//  ICSself.m
//  InClassStudent
//
//  Created by Brie Bunge on 3/24/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSUnderstandingIndicator.h"

#define BAR_HEIGHT 60.0

@implementation ICSUnderstandingIndicator

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)setTouchLocation:(CGPoint)touchLocation
{
    // Assumes in view's coordinate system
    CGFloat y = MIN(MAX(touchLocation.y, 0), self.bounds.origin.y + self.bounds.size.height);
    _touchLocation = CGPointMake(self.bounds.origin.x + self.bounds.size.width/2, y);
    
    // Subtract from 1, so that top is 1 and bottom is 0.
    self.touchFraction = 1.0 - (y - self.bounds.origin.y)/self.bounds.size.height;
    
    [self setNeedsDisplay];
}

- (void)viewHasSuperView
{
    [self.superview sendSubviewToBack:self];
}

- (void)drawRect:(CGRect)rect
{
    [self setClipsToBounds:YES];

    CGFloat colors [] = {
        134/255.0, 191/255.0, 60/255.0, 1.0,
//        176/255.0, 191/255.0, 62/255.0, 1.0,
//        238/255.0, 174/255.0, 59/255.0, 1.0,
//        238/255.0, 121/255.0, 44/255.0, 1.0,
        190/255.0,   0/255.0, 20/255.0, 1.0
    };
    
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient), gradient = NULL;
    
    CGContextRestoreGState(context);
 
    [[UIColor blackColor] setFill];
    
    CGFloat maxY = self.bounds.origin.y + self.bounds.size.height;
    
    
    if (self.touchLocation.y + BAR_HEIGHT/2 >= maxY) {
        UIRectFill(CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                              self.bounds.size.width, maxY - BAR_HEIGHT));
    } else if (self.touchLocation.y - BAR_HEIGHT/2 <= 0) {
        UIRectFill(CGRectMake(self.bounds.origin.x, BAR_HEIGHT,
                              self.bounds.size.width, maxY - BAR_HEIGHT));
    } else {
        CGFloat height1, height2, y2;
        height1 = self.touchLocation.y - BAR_HEIGHT/2;
        y2 = self.touchLocation.y + BAR_HEIGHT/2;
        height2 = maxY - y2;
        
        UIRectFill(CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, height1));
        UIRectFill(CGRectMake(self.bounds.origin.x, y2, self.bounds.size.width, height2));
    }
    
}

@end
