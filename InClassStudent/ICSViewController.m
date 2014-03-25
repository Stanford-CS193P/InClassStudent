//
//  ViewController.m
//  InClassStudent
//
//  Created by Brie Bunge on 2/26/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSViewController.h"
#import "ICSRemoteClient.h"
#import "ICSConceptRating.h"
#import "ICSUnderstandingIndicator.h"

#define FONT_SIZE 20.0
#define FONT_NAME @"AvenirNext-Medium"
#define LABEL_PADDING 32
#define LABEL_MARGIN_X 8

@interface ICSViewController ()

@property (weak, nonatomic) IBOutlet UILabel *conceptLabel;
@property (weak, nonatomic) IBOutlet UIImageView *connectedIndicator;
@property (weak, nonatomic) IBOutlet UIView *conceptRegion;

@property (nonatomic, strong) ICSUnderstandingIndicator *understandingIndicator;

@property (nonatomic, strong) NSMutableArray *outgoingQueue;
@property (nonatomic, strong) NSMutableArray *conceptRatings; // of ICSConceptRating

@end

@implementation ICSViewController

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
    
    [self setUpUnderstandingIndicator];
}

- (void)setUpUnderstandingIndicator
{
    self.understandingIndicator = [[ICSUnderstandingIndicator alloc] init];
    [self.conceptRegion addSubview:self.understandingIndicator];
    [self.understandingIndicator viewHasSuperView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(understandingIndicatorTap:)];
    [self.understandingIndicator addGestureRecognizer:tapGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(understandingIndicatorPan:)];
    [self.understandingIndicator addGestureRecognizer:panGesture];
}

- (void)understandingIndicatorTap:(UITapGestureRecognizer *)sender
{
    self.understandingIndicator.touchLocation = [sender locationInView:self.understandingIndicator];
    [[ICSRemoteClient sharedManager] sendEvent:@"CreateRating"
                                      withData:@{@"rating": @(self.understandingIndicator.touchFraction)}];

}

- (void)understandingIndicatorPan:(UIPanGestureRecognizer *)sender
{
    self.understandingIndicator.touchLocation = [sender locationInView:self.understandingIndicator];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        [[ICSRemoteClient sharedManager] sendEvent:@"CreateRating"
                                          withData:@{@"rating": @(self.understandingIndicator.touchFraction)}];
    }
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
    
    if ([name isEqualToString:kConceptReceivedFromServerNotification]) {
        NSString *dataStr = [[notification userInfo] valueForKey:kDataKey];
        if (!dataStr) return;
        NSLog(@"dataStr %@", dataStr);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.conceptLabel.text = dataStr;
        });
    }
}

@end
