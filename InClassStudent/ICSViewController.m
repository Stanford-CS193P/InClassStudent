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
#import "ICSQuestionViewController.h"

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

@property (nonatomic, strong) NSString *currentConceptName;
@property (nonatomic, strong) NSString *currentConceptID;
@property (nonatomic, strong) NSDictionary *questionData;

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
                                             selector:@selector(didReceiveData:)
                                                 name:kQuestionReceivedFromServerNotification
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
    [self.outgoingRatingsQueue removeAllObjects];
}

- (void)didReceiveData:(NSNotification *)notification
{
    NSString *name = [notification name];
    
    if ([name isEqualToString:kConceptReceivedFromServerNotification]) {
        NSDictionary *data = [[notification userInfo] valueForKey:kDataKey];
        NSString *conceptName = [data objectForKey:@"conceptName"];
        NSString *conceptID = [data objectForKey:@"id"];
        
        self.currentConceptName = conceptName;
        self.currentConceptID = conceptID;
        
        NSLog(@"conceptName %@", conceptName);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.conceptLabel.text = conceptName;
        });
    }
    
    if ([name isEqualToString:kQuestionReceivedFromServerNotification]) {
        NSDictionary *data = [[notification userInfo] valueForKey:kDataKey];
        self.questionData = data;
        NSLog(@"questionData %@", data);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"ToQuestion" sender:self];
        });
    }
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"ToQuestion"]) {
        NSLog(@"segue.destinationViewController %@", [segue.destinationViewController class]);
        
        ICSQuestionViewController *questionVC = segue.destinationViewController;
        questionVC.questionData = self.questionData;
        self.questionData = nil;
        
        if (self.presentedViewController) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self presentViewController:questionVC animated:YES completion:NULL];
            }];
        }
    }
}

- (void)sendFeedback
{
    // Only allow users to send feedback when there is a word on screen
    if (!self.currentConceptID) return;
    
    TaggedTimestampedDouble *ttd = [[TaggedTimestampedDouble alloc] initWithDouble:self.understandingIndicator.touchFraction
                                                                            andTag:self.currentConceptName
                                                                             andID:self.currentConceptID];
    if ([[ICSRemoteClient sharedManager] serverIsConnected])
        [ttd send];
    else
        [self.outgoingRatingsQueue addObject:ttd];
}

@end
