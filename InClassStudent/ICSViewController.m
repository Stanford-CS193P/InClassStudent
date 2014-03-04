//
//  ViewController.m
//  InClassStudent
//
//  Created by Brie Bunge on 2/26/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSViewController.h"
#import "ICSMultipeerManager.h"


@interface ICSViewController ()

@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, strong) UILabel *currLabel;

@property (weak, nonatomic) IBOutlet UIView *level1;
@property (weak, nonatomic) IBOutlet UIView *level2;
@property (weak, nonatomic) IBOutlet UIView *level3;
@property (weak, nonatomic) IBOutlet UIView *level4;
@property (weak, nonatomic) IBOutlet UIView *level5;
@property (nonatomic, strong) NSArray *levels;

@property (nonatomic) BOOL stopLevelAnimation;

@end

@implementation ICSViewController

- (NSMutableArray *)labels
{
    if (!_labels) {
        _labels = [[NSMutableArray alloc] init];
    }
    return _labels;
}

- (NSArray *)levels
{
    if (!_levels) {
        _levels = @[self.level1, self.level2, self.level3, self.level4, self.level5];
    }
    return _levels;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [ICSMultipeerManager sharedManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveData:)
                                                 name:kDataReceivedFromServerNotification
                                               object:nil];
    
    
    dispatch_queue_t queue = dispatch_queue_create("simulate word messages", NULL);
    dispatch_async(queue, ^{
        while (YES) {
            NSData *data = [@"hello there" dataUsingEncoding:NSUTF8StringEncoding];
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataReceivedFromServerNotification
                                                                object:self
                                                              userInfo:@{kServerPeerID: @"", kDataKey: data}];
            [NSThread sleepForTimeInterval:5];
        }
    });
}

- (void)didReceiveData:(NSNotification *)notification
{
    NSString *name = [notification name];
    
    // TODO: generalize to other notifications as necessary
    assert([name isEqualToString:kDataReceivedFromServerNotification]);
    
    NSData *data = [[notification userInfo] valueForKey:kDataKey];
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", dataStr);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startMessageAnimation:dataStr];
    });
}

- (void)startMessageAnimation:(NSString *)message
{
    UILabel *label = [[UILabel alloc] init];
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor whiteColor],
                                  NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Medium" size:20.0] };
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:message
                                                                                       attributes:attributes];
    label.attributedText = attributedText;
    label.userInteractionEnabled = YES;
    [label sizeToFit];
    
    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y,
                             label.frame.size.width + 32, self.level1.frame.size.height);
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.05];
    
    CGFloat x = self.view.bounds.origin.x + self.view.bounds.size.width;
    CGFloat y = (self.view.bounds.origin.y + self.view.bounds.size.height / 2) - (label.frame.size.height / 2);
    label.frame = CGRectMake(x, y, label.frame.size.width, label.frame.size.height);
    NSLog(@"%@", NSStringFromCGRect(label.frame));
    
    [self.view addSubview:label];
    [self.labels addObject:label];
    [self animateLabel:label];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UIView *label in self.levels) {
        [label.layer removeAllAnimations];
        self.stopLevelAnimation = YES;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.view];
    for (UILabel *label in self.labels) {
        if ([[label.layer presentationLayer] hitTest:currentTouchPosition]) {
            self.currLabel = label;
        }
    }
}

- (UIView *)nearestLevelToPoint:(CGPoint)point
{
    UIView *level = nil;
    for (UIView *currLevel in self.levels) {
        if (CGRectContainsPoint(currLevel.frame, point)) {
            level = currLevel;
            break;
        }
    }
    return level;
}

- (void)updateLabelPosition:(CGPoint)position
{
    if (!self.currLabel) return;
    UIView *level = [self nearestLevelToPoint:position];
    if (!level)
        self.currLabel.center = CGPointMake(self.currLabel.center.x, position.y);
    else
        self.currLabel.center = CGPointMake(self.currLabel.center.x,
                                            level.frame.origin.y + level.frame.size.height/2);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self updateLabelPosition:[[touches anyObject] locationInView:self.view]];
}

- (void)snapLabelToNearestLevel:(UILabel *)label
{
    if (!label) return;
    CALayer *labelLayer = [label.layer presentationLayer];
    CGPoint labelCenter = CGPointMake(labelLayer.frame.origin.x + labelLayer.frame.size.width / 2,
                                      labelLayer.frame.origin.y + labelLayer.frame.size.height / 2);
    UIView *level = [self nearestLevelToPoint:labelCenter];
    if (!level) return;
    
    [UIView animateWithDuration:0.2 animations:^{
        label.frame = CGRectMake(label.frame.origin.x,
                                 level.frame.origin.y + level.frame.size.height/2 - label.frame.size.height/2,
                                 label.frame.size.width,
                                 label.frame.size.height);
    }];
    
    [self animateLevel:level];
}

- (void)animateLevel:(UIView *)level
{
    UIColor *originalBGColor = level.backgroundColor;
    
    __block NSMutableArray* animationBlocks = [NSMutableArray new];
    typedef void(^animationBlock)(BOOL);
    
    animationBlock (^getNextAnimation)() = ^{
        if (self.stopLevelAnimation) {
            NSLog(@"stopLevelAnimation");
            self.stopLevelAnimation = NO;
            animationBlock block = (animationBlock)[animationBlocks lastObject];
            animationBlocks = nil;
            return block;
        }
        
        if ([animationBlocks count] > 0){
            animationBlock block = (animationBlock)[animationBlocks objectAtIndex:0];
            [animationBlocks removeObjectAtIndex:0];
            return block;
        } else {
            return ^(BOOL finished){
                animationBlocks = nil;
            };
        }
    };
    
    void (^brighter)(BOOL) = ^(BOOL finished){
        CGFloat hue, saturation, brightness, alpha;
        if ([originalBGColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
            UIColor *brighterColor = [UIColor colorWithHue:hue
                                                saturation:MAX(saturation - 0.05, 0.0)
                                                brightness:MIN(brightness + 0.075, 1.0)
                                                     alpha:alpha];
            
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationOptionCurveLinear|UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 level.backgroundColor = brighterColor;
                             } completion:getNextAnimation()];
        }
    };
    
    void (^darker)(BOOL) = ^(BOOL finished){
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear|UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             level.backgroundColor = originalBGColor;
                         } completion:getNextAnimation()];
    };
    
    [animationBlocks addObject:brighter];
    [animationBlocks addObject:darker];
    [animationBlocks addObject:brighter];
    [animationBlocks addObject:darker];
    
    if (self.stopLevelAnimation) self.stopLevelAnimation = NO;
    getNextAnimation()(YES);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self updateLabelPosition:[[touches anyObject] locationInView:self.view]];
    UILabel *label = self.currLabel;
    self.currLabel = nil;
    [self snapLabelToNearestLevel:label];
}

- (void)animateLabel:(UILabel *)label
{
    [UIView animateWithDuration:10
                          delay:0
                        options:(UIViewAnimationOptionCurveLinear|
                                 UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         label.transform = CGAffineTransformMakeTranslation(-1 * self.view.bounds.size.width - label.frame.size.width, 0);
                     }  completion:^(BOOL finished) {
                     }];
}

//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *aTouch = [touches anyObject];
//    CGPoint currentTouchPosition = [aTouch locationInView:self.view];
//    
//    CGFloat yLoc = currentTouchPosition.y;
//    CGFloat yMid = self.view.center.y;
//    CGFloat per = (yLoc - yMid) / yMid;
//    
//    CGFloat red = 0.5 + per;
//    CGFloat green = 0.5 - per;
//    self.view.backgroundColor = [UIColor colorWithRed:red green:green blue:0 alpha:1];
//    
//    self.red = red;
//    self.green = green;
//    self.blue = 0;
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    NSString *message = [NSString stringWithFormat:@"%f,%f,%f", self.red, self.green, self.blue];
//    NSLog(@"Sending message: %@", message);
//    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
//    ICSMultipeerManager *manager = [ICSMultipeerManager sharedManager];
//    [manager sendData:data];
//}

@end
