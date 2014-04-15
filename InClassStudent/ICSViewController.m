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
#import "ICSAuthViewController.h"
#import "ICSRemoteObjectQueue.h"

#define FONT_SIZE 20.0
#define FONT_NAME @"AvenirNext-Medium"
#define LABEL_PADDING 32
#define LABEL_MARGIN_X 8

@interface ICSViewController ()

@property (weak, nonatomic) IBOutlet UILabel *conceptLabel;
@property (weak, nonatomic) IBOutlet UIImageView *connectedIndicator;
@property (weak, nonatomic) IBOutlet UIView *conceptRegion;

@property (nonatomic, strong) IBOutlet ICSUnderstandingIndicator *understandingIndicator;

@property (nonatomic, strong) NSString *currentConceptName;
@property (nonatomic, strong) NSString *currentConceptID;
@property (nonatomic, strong) NSDictionary *questionData;

@property (nonatomic, strong) NSString *identifierForVendor;

@end

@implementation ICSViewController

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
                                             selector:@selector(handleAuthRequired:)
                                                 name:kAuthRequiredNotification
                                               object:nil];
}

#pragma mark - Touch

- (IBAction)understandingIndicatorTap:(UITapGestureRecognizer *)sender
{
    self.understandingIndicator.isVisible = YES;
    self.understandingIndicator.touchLocation = [sender locationInView:self.understandingIndicator];
    [self hideUnderstandingIndicator];
    [self sendFeedback];
}

- (IBAction)understandingIndicatorPan:(UIPanGestureRecognizer *)sender
{
    self.understandingIndicator.isVisible = YES;
    self.understandingIndicator.touchLocation = [sender locationInView:self.understandingIndicator];
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self hideUnderstandingIndicator];
        [self sendFeedback];
    }
}

- (void)hideUnderstandingIndicator
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.understandingIndicator.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         self.understandingIndicator.isVisible = NO;
                         self.understandingIndicator.alpha = 1.0;
                     }];
}

#pragma mark - Server notifications

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
        // TODO: queue up questions that come in that are not segued to
        if ([self shouldPerformSegueWithIdentifier:@"ToQuestion" sender:self]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"ToQuestion" sender:self];
            });
        }
    }
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"segue.destinationViewController %@", [segue.destinationViewController class]);
    
    UIViewController *vc = nil;
    
    if ([segue.identifier isEqualToString:@"ToQuestion"]) {
        ICSQuestionViewController *questionVC = segue.destinationViewController;
        questionVC.questionData = self.questionData;
        self.questionData = nil;
        vc = questionVC;
    } else if ([segue.identifier isEqualToString:@"ToAuthWebView"]) {
        ICSAuthViewController *authVC = segue.destinationViewController;
        authVC.identifierForVendor = self.identifierForVendor;
        self.identifierForVendor = nil;
        vc = authVC;
    }
    
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:vc animated:YES completion:NULL];
        }];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([self.presentedViewController class] == [ICSAuthViewController class]) {
        return NO;
    }
    return YES;
}

- (void)sendFeedback
{
    // Only allow users to send feedback when there is a word on screen
    if (!self.currentConceptID) return;
    
    TaggedTimestampedDouble *ttd = [[TaggedTimestampedDouble alloc] initWithDouble:self.understandingIndicator.touchFraction
                                                                            andTag:self.currentConceptName
                                                                             andID:self.currentConceptID];
    [[ICSRemoteObjectQueue sharedQueue] addOutgoingRemoteObject:ttd];
}

- (void)handleAuthRequired:(NSNotification *)notification
{
    self.identifierForVendor = [[notification userInfo] valueForKey:@"identifierForVendor"];
    [self performSegueWithIdentifier:@"ToAuthWebView" sender:self];
}

@end
