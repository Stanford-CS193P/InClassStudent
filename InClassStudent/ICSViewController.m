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
@property (nonatomic, weak) UILabel *movingLabel;
@property (nonatomic, strong) NSMutableArray *labelRatings;

@property (weak, nonatomic) IBOutlet UIView *level1;
@property (weak, nonatomic) IBOutlet UIView *level2;
@property (weak, nonatomic) IBOutlet UIView *level3;
@property (weak, nonatomic) IBOutlet UIView *level4;
@property (weak, nonatomic) IBOutlet UIView *level5;
@property (nonatomic, strong) NSArray *levels;
@property (weak, nonatomic) IBOutlet UIImageView *connectedIndicator;

@property (nonatomic) BOOL stopLevelAnimation;

@property (nonatomic) BOOL crawl;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(serverDidDisconnect)
                                                 name:kServerDisconnected
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(serverDidConnect)
                                                 name:kServerConnected
                                               object:nil];
}

- (void)serverDidDisconnect
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.connectedIndicator.hidden = YES;
    });
}

- (void)serverDidConnect
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.connectedIndicator.hidden = NO;
    });
}

- (void)didReceiveData:(NSNotification *)notification
{
    NSString *name = [notification name];
    
    // TODO: generalize to other notifications as necessary
    assert([name isEqualToString:kDataReceivedFromServerNotification]);
    
    NSData *data = [[notification userInfo] valueForKey:kDataKey];
    if (data == nil) return;
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"dataStr %@", dataStr);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startMessageAnimation:dataStr];
    });
}

#define FONT_SIZE 20.0
#define FONT_NAME @"AvenirNext-Medium"
#define LABEL_PADDING 32

- (void)startMessageAnimation:(NSString *)message
{
    if (!message) return;
    
    UILabel *label = [[UILabel alloc] init];
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor whiteColor],
                                  NSFontAttributeName: [UIFont fontWithName:FONT_NAME size:FONT_SIZE] };
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:message
                                                                                       attributes:attributes];
    label.attributedText = attributedText;
    label.userInteractionEnabled = YES;
    [label sizeToFit];
    
    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y,
                             label.frame.size.width + LABEL_PADDING, self.level1.frame.size.height);
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.05];
    
    CGFloat x = self.view.bounds.origin.x + self.view.bounds.size.width;
    CGFloat y = (self.view.bounds.origin.y + self.view.bounds.size.height / 2) - (label.frame.size.height / 2);
    label.frame = CGRectMake(x, y, label.frame.size.width, label.frame.size.height);
    
    // this next line of code prevents support for multiple labels
    // we have to disable this for now because we don't support it in the UI on the Teacher side
    for (UIView *existingLabel in self.labels) [existingLabel removeFromSuperview];

    [self.view addSubview:label];
    [self.labels addObject:label];
    
    if (self.crawl) {
        [self animateLabel:label];
    } else {
        for (UIView *otherLabel in self.labels) {
            CGRect frame = otherLabel.frame;
            frame.origin.x -= label.frame.size.width;
            otherLabel.frame = frame;
        }
        [self resetLabelRatings];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // should just use autolayout for this!
    CGFloat x = self.view.bounds.origin.x + self.view.bounds.size.width;
    for (int i = [self.labels count]-1; i >= 0; i--) {
        UIView *label = self.labels[i];
        CGRect frame = label.frame;
        x -= frame.size.width;
        frame.origin.x = x;
        label.frame = frame;
        if ([self.labelRatings count] == [self.labels count]) {
            CGPoint center = label.center;
            CGFloat height = self.view.bounds.size.height - label.frame.size.height;
            CGFloat offset = height * ([self.labelRatings[i] doubleValue] / 5);
            center.y = self.view.bounds.origin.y + self.view.bounds.size.height - label.frame.size.height / 2 - offset;
            label.center = center;
        }
    }
}

- (IBAction)tap:(UITapGestureRecognizer *)sender
{
    CGPoint gesturePoint = [sender locationInView:self.view];
    for (UILabel *label in self.labels) {
        if (CGRectContainsPoint(label.frame, gesturePoint)) {
            return;
        }
    }
    int rating = ((self.view.bounds.size.height - [sender locationInView:self.view].y) / self.view.bounds.size.height) * 5;
    if (rating < 0) rating = 0;
    [[ICSMultipeerManager sharedManager] sendDict:@{@"type": @"PeerRating",
                                                    @"rating": @(rating)}];
}

- (void)resetLabelRatings
{
    NSMutableArray *labelRatings = [[NSMutableArray alloc] init];
    for (UIView *label in self.labels) {
        double rating = 5 - (((label.center.y - (label.frame.size.height/2)) / (self.view.bounds.size.height - label.frame.size.height)) * 5);
        [labelRatings addObject:@(rating)];
    }
    self.labelRatings = labelRatings;
}

- (IBAction)pan:(UIPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint gesturePoint = [sender locationInView:self.view];
        self.movingLabel = nil;
        for (UILabel *label in self.labels) {
            if (CGRectContainsPoint(label.frame, gesturePoint)) {
                self.movingLabel = label;
            }
        }
    }
    if (self.movingLabel) {
        CGPoint center = self.movingLabel.center;
        center = CGPointMake(center.x, center.y + [sender translationInView:self.view].y);
        self.movingLabel.center = center;
        [sender setTranslation:CGPointZero inView:self.view];
    }
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.movingLabel) {
            double rating = 5 - (((self.movingLabel.center.y - (self.movingLabel.frame.size.height/2)) / (self.view.bounds.size.height - self.movingLabel.frame.size.height)) * 5);
            if (rating < 0) rating = 0;
            [[ICSMultipeerManager sharedManager] sendDict:@{@"type": @"PeerRating",
                                                            @"text": self.movingLabel.text,
                                                            @"rating": @(rating)}];
            [self resetLabelRatings];
       } else {
           double rating = ((self.view.bounds.size.height - [sender locationInView:self.view].y) / self.view.bounds.size.height) * 5;
           if (rating < 0) rating = 0;
           [[ICSMultipeerManager sharedManager] sendDict:@{@"type": @"PeerRating",
                                                            @"rating": @(rating)}];
        }
        self.movingLabel = nil;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.crawl) {
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

// TODO: better way...this is gross...
- (int)nearestLevelValueToLabel:(UILabel *)label
{
    CALayer *labelLayer = [label.layer presentationLayer];
    CGPoint labelCenter = CGPointMake(0, labelLayer.frame.origin.y + labelLayer.frame.size.height / 2);
    UIView *level = [self nearestLevelToPoint:labelCenter];
    return (int)[self.levels indexOfObject:level];
}

- (void)updateLabelPosition:(CGPoint)position
{
    if (!self.currLabel) return;
    
    UIView *level = [self nearestLevelToPoint:position];
    if (!level) {
        self.currLabel.center = CGPointMake(self.currLabel.center.x, position.y);
    } else {
        self.currLabel.center = CGPointMake(self.currLabel.center.x,
                                            level.frame.origin.y + level.frame.size.height/2);
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.crawl) {
        [self updateLabelPosition:[[touches anyObject] locationInView:self.view]];
    }
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
    if (self.crawl) {
        [self updateLabelPosition:[[touches anyObject] locationInView:self.view]];
        UILabel *label = self.currLabel;
        self.currLabel = nil;
        [self snapLabelToNearestLevel:label];
    }
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
                         // TODO: queue up responses in case of network failure
                         int rating = [self nearestLevelValueToLabel:label];
                         [[ICSMultipeerManager sharedManager] sendDict:@{@"type": @"PeerRating",
                                                                         @"text": label.text,
                                                                         @"rating": @(rating)}];
                     }];
}

- (void)sendRatingToTeacher {

}

@end
