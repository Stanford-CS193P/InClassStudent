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

@end

@implementation ICSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveData:)
                                                 name:kDataReceivedFromServerNotification
                                               object:nil];
}

- (void)didReceiveData:(NSNotification *)notification
{
    NSData *data = [[notification userInfo] valueForKey:kDataKey];
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", dataStr);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *aTouch = [touches anyObject];
    CGPoint currentTouchPosition = [aTouch locationInView:self.view];
    
    CGFloat yLoc = currentTouchPosition.y;
    CGFloat yMid = self.view.center.y;
    CGFloat per = (yLoc - yMid) / yMid;
    
    CGFloat red = 0.5 + per;
    CGFloat green = 0.5 - per;
    self.view.backgroundColor = [UIColor colorWithRed:red green:green blue:0 alpha:1];
    
    self.red = red;
    self.green = green;
    self.blue = 0;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSString *message = [NSString stringWithFormat:@"%f,%f,%f", self.red, self.green, self.blue];
    NSLog(@"Sending message: %@", message);
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    ICSMultipeerManager *manager = [ICSMultipeerManager sharedManager];
    [manager sendData:data];
}

@end
