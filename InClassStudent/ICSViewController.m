//
//  ViewController.m
//  InClassStudent
//
//  Created by Brie Bunge on 2/26/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSViewController.h"
#import "ICSMultipeerManager.h"
#import "ICSConceptRating.h"

#define FONT_SIZE 20.0
#define FONT_NAME @"AvenirNext-Medium"
#define LABEL_PADDING 32
#define LABEL_MARGIN_X 8

@interface ICSViewController ()

@property (nonatomic, weak) UILabel *movingLabel;

@property (weak, nonatomic) IBOutlet UIView *level1;
@property (weak, nonatomic) IBOutlet UIView *level2;
@property (weak, nonatomic) IBOutlet UIView *level3;
@property (weak, nonatomic) IBOutlet UIView *level4;
@property (weak, nonatomic) IBOutlet UIView *level5;
@property (nonatomic, strong) NSArray *levels;

@property (weak, nonatomic) IBOutlet UIImageView *connectedIndicator;
@property (weak, nonatomic) IBOutlet UIView *conceptRegion;
@property (weak, nonatomic) IBOutlet UIView *generalRegion;
@property (weak, nonatomic) IBOutlet UIImageView *understandingIndicator;
@property (weak, nonatomic) NSLayoutConstraint *generalUnderstandingLevelLayoutConstraint;

@property (nonatomic, strong) NSMutableArray *outgoingQueue;
@property (nonatomic, strong) NSMutableArray *conceptRatings; // of ICSConceptRating

@end

@implementation ICSViewController

- (NSArray *)levels
{
    if (!_levels) {
        _levels = @[self.level1, self.level2, self.level3, self.level4, self.level5];
    }
    return _levels;
}

- (NSMutableArray *)outgoingQueue
{
    if (!_outgoingQueue) {
        _outgoingQueue = [[NSMutableArray alloc] init];
    }
    return _outgoingQueue;
}

- (NSMutableArray *)conceptRatings
{
    if (!_conceptRatings) {
        _conceptRatings = [[NSMutableArray alloc] init];
    }
    return _conceptRatings;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    [self updateGeneralUnderstandingLevelLayoutConstraint];
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
    
    if ([name isEqualToString:kDataReceivedFromServerNotification]) {
        NSData *data = [[notification userInfo] valueForKey:kDataKey];
        if (!data) return;
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"dataStr %@", dataStr);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showNewConcept:dataStr];
        });
    }
}

- (IBAction)generalRegionTap:(UITapGestureRecognizer *)sender
{
    CGPoint gesturePoint = [sender locationInView:self.generalRegion];
    [self onFinishIndicatingGeneralUnderstandingAtLocation:gesturePoint];
}

- (IBAction)generalRegionPan:(UIPanGestureRecognizer *)sender
{
    CGPoint gesturePoint = [sender locationInView:self.generalRegion];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint center = self.understandingIndicator.center;
        center = CGPointMake(center.x, gesturePoint.y);
        self.understandingIndicator.center = center;
    }
    
    CGPoint center = self.understandingIndicator.center;
    center = CGPointMake(center.x, center.y + [sender translationInView:self.generalRegion].y);
    self.understandingIndicator.center = center;
    [sender setTranslation:CGPointZero inView:self.generalRegion];
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self onFinishIndicatingGeneralUnderstandingAtLocation:gesturePoint];
    }
}

// TODO: better name
- (void)onFinishIndicatingGeneralUnderstandingAtLocation:(CGPoint)location
{
    [self updateViewLocation:self.understandingIndicator
            forTouchPosition:location];
    [self pulseView:self.understandingIndicator];
    
    [[ICSMultipeerManager sharedManager] sendDict:@{@"type": @"GeneralRating",
                                                    @"rating": @([self levelRatingOfUnderstandingIndicator])}];
 
    [self updateGeneralUnderstandingLevelLayoutConstraint];
}

- (IBAction)conceptRegionTap:(UITapGestureRecognizer *)sender
{
    NSLog(@"conceptRegionTap");
    CGPoint gesturePoint = [sender locationInView:self.conceptRegion];
    
    // Check for match vertically
    for (ICSConceptRating *cR in self.conceptRatings) {
        if (!cR.label) continue;
        if (CGRectContainsPoint(CGRectMake(cR.label.frame.origin.x, gesturePoint.y, cR.label.frame.size.width, 1),
                                gesturePoint)) {
            self.movingLabel = cR.label;
            break;
        }
    }
    [self onFinishIndicatingConceptualUnderstandingAtLocation:gesturePoint];
}

- (IBAction)conceptRegionPan:(UIPanGestureRecognizer *)sender
{
    CGPoint gesturePoint = [sender locationInView:self.conceptRegion];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.movingLabel = nil;
        
        for (UIView *label in self.levels) {
            [label.layer removeAllAnimations];
        }
        
        for (ICSConceptRating *cR in self.conceptRatings) {
            if (CGRectContainsPoint(cR.label.frame, gesturePoint)) {
                self.movingLabel = cR.label;
                break;
            }
        }
    }
    
    if (self.movingLabel) {
        [self updateViewLocation:self.movingLabel forTouchPosition:gesturePoint];
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self onFinishIndicatingConceptualUnderstandingAtLocation:gesturePoint];
    }
}

// TODO: better name
- (void)onFinishIndicatingConceptualUnderstandingAtLocation:(CGPoint)location
{
    if (!self.movingLabel) return;
    
    [self updateViewLocation:self.movingLabel forTouchPosition:location];

    UILabel *label = self.movingLabel;
    self.movingLabel = nil;
    [self snapLabelToNearestLevel:label];
    
    ICSConceptRating *cR = [self conceptRatingForLabel:label];
    cR.rating = [self levelRatingOfLabel:label];
    
    [self updateLevelLayoutConstraint:cR];
    
    // TODO: queue up responses in case of network failure
    [[ICSMultipeerManager sharedManager] sendDict:@{@"type": @"ConceptRating",
                                                    @"text": cR.conceptName,
                                                    @"rating": @(cR.rating)}];
}

- (void)pulseView:(UIView *)view
{
    CABasicAnimation *anim;
    anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    anim.duration = 0.25;
    anim.repeatCount = 2;
    anim.autoreverses = YES;
    anim.fromValue = [NSNumber numberWithFloat:view.alpha];
    anim.toValue = [NSNumber numberWithFloat:0.85];
    [view.layer addAnimation:anim forKey:@"animateOpacity"];
}

- (void)showNewConcept:(NSString *)message
{
    if (!message) return;
    
    // this next line of code prevents support for multiple labels
    // we have to disable this for now because we don't support it in the UI on the Teacher side
    for (ICSConceptRating *cR in self.conceptRatings) {
        [cR.label removeFromSuperview];
        cR.label = nil;
    }
    
    UILabel *label = [[UILabel alloc] init];
    ICSConceptRating *conceptRating = [[ICSConceptRating alloc] initWithConceptName:message andLabel:label];
    [self.conceptRatings addObject:conceptRating];
    
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor whiteColor],
                                  NSFontAttributeName: [UIFont fontWithName:FONT_NAME size:FONT_SIZE] };
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:message
                                                                                       attributes:attributes];
    label.attributedText = attributedText;
    label.userInteractionEnabled = YES;
    [label sizeToFit];
    
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.05];
    
    
    // shift over if another concept is in view
//    for (ICSConceptRating *cR in self.conceptRatings) {
//        UILabel *otherLabel = cR.label;
//        if (otherLabel == label) continue;
//        CGRect frame = otherLabel.frame;
//        frame.origin.x -= label.frame.size.width + LABEL_MARGIN_X;
//        otherLabel.frame = frame;
//    }
    
    // Fade the label in
    label.alpha = 0;
    [self.conceptRegion addSubview:label];
    [UIView animateWithDuration:0.75 delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn)
                     animations:^{ label.alpha = 1; }
                     completion:^(BOOL finished){ }];
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.level1
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:label
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1
                                                           constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1
                                                           constant:label.frame.size.width + LABEL_PADDING]];
    
    // Center on screen for now because there is only one word
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.conceptRegion
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:label
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0]];
    
    // Start rating off in middle
    conceptRating.rating = 2;
    [self updateLevelLayoutConstraint:conceptRating];
}

- (void)updateLevelLayoutConstraint:(ICSConceptRating *)cR
{
    UIView *level = self.levels[cR.rating];
    if (cR.levelConstraint) {
        [self.view removeConstraint:cR.levelConstraint];
    }
    
    cR.levelConstraint = [NSLayoutConstraint constraintWithItem:level
                                                      attribute:NSLayoutAttributeCenterY
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:cR.label
                                                      attribute:NSLayoutAttributeCenterY
                                                     multiplier:1
                                                       constant:0];
    [self.view addConstraint:cR.levelConstraint];
}

- (void)updateGeneralUnderstandingLevelLayoutConstraint
{
    self.understandingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (self.generalUnderstandingLevelLayoutConstraint)
        [self.view removeConstraint:self.generalUnderstandingLevelLayoutConstraint];
    
    UIView *level = [self nearestLevelToPoint:self.understandingIndicator.center];
    if (!level) return;
    
    self.generalUnderstandingLevelLayoutConstraint = [NSLayoutConstraint
                                                      constraintWithItem:level
                                                      attribute:NSLayoutAttributeCenterY
                                                      relatedBy:NSLayoutRelationEqual
                                                      toItem:self.understandingIndicator
                                                      attribute:NSLayoutAttributeCenterY
                                                      multiplier:1
                                                      constant:0];
    [self.view addConstraint:self.generalUnderstandingLevelLayoutConstraint];
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

- (void)updateViewLocation:(UIView *)view forTouchPosition:(CGPoint)position
{
    if (!view) return;
    
    UIView *level = [self nearestLevelToPoint:position];
    if (!level) {
        view.center = CGPointMake(view.center.x, position.y);
    } else {
        view.center = CGPointMake(view.center.x, level.frame.origin.y + level.frame.size.height / 2);
    }
}

- (int)levelRatingOfLabel:(UILabel *)label
{
    UIView *level = [self nearestLevelToPoint:label.center];
    return (int)[self.levels indexOfObject:level];
}

- (int)levelRatingOfUnderstandingIndicator
{
    UIView *level = [self nearestLevelToPoint:self.understandingIndicator.center];
    return (int)[self.levels indexOfObject:level];
}

- (void)snapLabelToNearestLevel:(UILabel *)label
{
    if (!label) return;
    
    UIView *level = [self nearestLevelToPoint:label.center];
    if (!level) return;
    
    [UIView animateWithDuration:0.2 animations:^{
        label.frame = CGRectMake(label.frame.origin.x,
                                 level.frame.origin.y + level.frame.size.height/2 - label.frame.size.height/2,
                                 label.frame.size.width,
                                 label.frame.size.height);
    }];
    
    [self pulseView:level];
}

- (ICSConceptRating *)conceptRatingForLabel:(UILabel*)label
{
    for (ICSConceptRating *cR in self.conceptRatings) {
        if (cR.label == label) {
            return cR;
        }
    }
    return nil;
}

@end
