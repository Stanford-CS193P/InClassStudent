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

@property (nonatomic) CGFloat red;
@property (nonatomic) CGFloat green;
@property (nonatomic) CGFloat blue;

@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, strong) UILabel *currLabel;

@end

@implementation ICSViewController

- (NSMutableArray *)labels
{
    if (_labels == nil) {
        _labels = [[NSMutableArray alloc] init];
    }
    return _labels;
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
            [NSThread sleepForTimeInterval:2];
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
    CGFloat x = self.view.bounds.origin.x + self.view.bounds.size.width;
    CGFloat y = self.view.bounds.origin.y + self.view.bounds.size.height / 2;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 100, 100)];
    label.text = message;
    
    label.userInteractionEnabled = YES;
//    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(labelPan:)];
//    [panGesture setMinimumNumberOfTouches:1];
//    [panGesture setMaximumNumberOfTouches:1];
//    [label addGestureRecognizer:panGesture];
    label.backgroundColor = [UIColor blueColor];
    
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTap)];
//    [label addGestureRecognizer:tapGesture];
    
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressedLayer:)];
//    [label addGestureRecognizer:tapGesture];
    
    
    
//    CALayer * movingLayer = [CALayer layer];
//    [movingLayer setBounds: CGRectMake(0, 0, layerSize, layerSize)];
//    [movingLayer setBackgroundColor:[UIColor orangeColor].CGColor];
//    [movingLayer setPosition:CGPointMake(layerCenterInset, layerCenterInset)];
//    [[[self view] layer] addSublayer:movingLayer];
//    [self setMovingLayer:movingLayer];
    
//    CAKeyframeAnimation * moveLayerAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
//    [moveLayerAnimation setValues:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0, 100)], [NSValue valueWithCGPoint:CGPointMake(1000, 10)], nil]];
//    [moveLayerAnimation setDuration:10.0];
//    [moveLayerAnimation setRepeatCount:0];
//    [moveLayerAnimation setTimingFunction: [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
//    [label.layer addAnimation:moveLayerAnimation forKey:@"move"];
    
    [self.view addSubview:label];
        [self animateLabel:label];
    
    [self.labels addObject:label];

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.view];
    for (UILabel *label in self.labels) {
        if ([[label.layer presentationLayer] hitTest:currentTouchPosition]) {
            self.currLabel = label;
        }
    }
}

- (void)updateLabelPosition:(CGPoint)position
{
    if (!self.currLabel) return;
    self.currLabel.center = CGPointMake(self.currLabel.center.x, position.y);
    self.currLabel.backgroundColor = [UIColor redColor];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self updateLabelPosition:[[touches anyObject] locationInView:self.view]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self updateLabelPosition:[[touches anyObject] locationInView:self.view]];
    self.currLabel = nil;
}

- (IBAction)pressedLayer:(UIGestureRecognizer *)sender {
    NSLog(@"pressedLayer");
    CGPoint touchPoint = [sender locationInView:[self view]];
    
    if ([[sender.view.layer presentationLayer] hitTest:touchPoint]) {
        sender.view.backgroundColor = [UIColor yellowColor];
    }
    else if ([sender.view.layer hitTest:touchPoint]) {
        sender.view.backgroundColor = [UIColor redColor];
    }
}

- (void)animateLabel:(UILabel *)label
{
    [UIView animateWithDuration:10
                          delay:0
                        options:(UIViewAnimationOptionCurveLinear|
                                 UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         label.transform = CGAffineTransformMakeTranslation(-1 * self.view.bounds.size.width - 100, 0);
                     }  completion:^(BOOL finished) {
                     }];
}

- (void)labelTap {
    NSLog(@"labelTap");
}

- (void)labelPan:(UIPanGestureRecognizer *)sender
{
    NSLog(@"labelPan");
    [self.view bringSubviewToFront:sender.view];
    CGPoint newCenter = [sender locationInView:sender.view.superview];
    sender.view.center = CGPointMake(sender.view.center.x, newCenter.y);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
