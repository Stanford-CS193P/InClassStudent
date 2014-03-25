//
//  ViewController.m
//  InClassStudent
//
//  Created by Brie Bunge on 2/26/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSViewController.h"
#import "ICSRemoteClient.h"
#import "TaggedTimestampedDouble.h"
#import "ICSUnderstandingIndicator.h"

#define FONT_SIZE 20.0
#define FONT_NAME @"AvenirNext-Medium"
#define LABEL_PADDING 32
#define LABEL_MARGIN_X 8

@interface ICSViewController ()

@property (weak, nonatomic) IBOutlet UILabel *conceptLabel;
@property (weak, nonatomic) IBOutlet UIImageView *connectedIndicator;
@property (weak, nonatomic) IBOutlet UIView *conceptRegion;

@property (nonatomic, strong) IBOutlet ICSUnderstandingIndicator *understandingIndicator;

@property (nonatomic, strong) NSMutableArray *outgoingRatingsQueue; //of TaggedTimestampDouble

@end

@implementation ICSViewController

- (NSMutableArray *)outgoingRatingsQueue
{
    if (!_outgoingRatingsQueue) {
        _outgoingRatingsQueue = [[NSMutableArray alloc] init];
    }
    return _outgoingRatingsQueue;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveData:)
                                                 name:kConceptReceivedFromServerNotification
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

#pragma mark - Touch

- (IBAction)understandingIndicatorTap:(UITapGestureRecognizer *)sender
{
    self.understandingIndicator.touchLocation = [sender locationInView:self.understandingIndicator];
    [self sendFeedback];
}

- (IBAction)understandingIndicatorPan:(UIPanGestureRecognizer *)sender
{
    self.understandingIndicator.touchLocation = [sender locationInView:self.understandingIndicator];
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self sendFeedback];
    }
}

#pragma mark - Server notifications

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
    
    [self.outgoingRatingsQueue makeObjectsPerformSelector:@selector(send)];
}

- (void)didReceiveData:(NSNotification *)notification
{
    NSString *name = [notification name];
    
    if ([name isEqualToString:kConceptReceivedFromServerNotification]) {
        NSString *dataStr = [[notification userInfo] valueForKey:kDataKey];
        if (!dataStr) return;
        NSLog(@"dataStr %@", dataStr);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.conceptLabel.text = dataStr;
        });
    }
}

- (void)sendFeedback
{
    TaggedTimestampedDouble *ttd = [[TaggedTimestampedDouble alloc] initWithDouble:self.understandingIndicator.touchFraction
                                                                            andTag:self.conceptLabel.text];
    if ([[ICSRemoteClient sharedManager] serverIsConnected])
        [ttd send];
    else
        [self.outgoingRatingsQueue addObject:ttd];
}

@end
