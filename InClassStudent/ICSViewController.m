//
//  ViewController.m
//  InClassStudent
//
//  Created by Brie Bunge on 2/26/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>


@interface ICSViewController ()<MCNearbyServiceAdvertiserDelegate, MCSessionDelegate>

//@property (nonatomic, strong) MCBrowserViewController *browserVC;
//@property (nonatomic, strong) MCAdvertiserAssistant *advertiser;
//@property (nonatomic, strong) MCSession *mySession;
//@property (nonatomic, strong) MCPeerID *myPeerID;
//
//@property (nonatomic, strong) UIButton *browserButton;
//@property (nonatomic, strong) UITextView *textBox;
//@property (nonatomic, strong) UITextField *chatBox;

@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCPeerID *localPeerID;
@property (nonatomic, strong) MCPeerID *serverPeerID;
@property (nonatomic, strong) MCSession *currSession;

@property (nonatomic) CGFloat red;
@property (nonatomic) CGFloat green;
@property (nonatomic) CGFloat blue;

@end

@implementation ICSViewController

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"didStartReceivingResourceWithName");
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"didReceiveStream");
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

/*
 - (void) setUpUI{
 //  Setup the browse button
 self.browserButton = [UIButton buttonWithType:UIButtonTypeSystem];
 [self.browserButton setTitle:@"Browse" forState:UIControlStateNormal];
 self.browserButton.frame = CGRectMake(130, 20, 60, 30);
 [self.view addSubview:self.browserButton];
 
 //  Setup TextBox
 self.textBox = [[UITextView alloc] initWithFrame: CGRectMake(40, 150, 240, 270)];
 self.textBox.editable = NO;
 self.textBox.backgroundColor = [UIColor lightGrayColor];
 [self.view addSubview: self.textBox];
 
 //  Setup ChatBox
 self.chatBox = [[UITextField alloc] initWithFrame: CGRectMake(40, 60, 240, 70)];
 self.chatBox.backgroundColor = [UIColor lightGrayColor];
 self.chatBox.returnKeyType = UIReturnKeySend;
 [self.view addSubview:self.chatBox];
 
 [self.browserButton addTarget:self action:@selector(showBrowserVC) forControlEvents:UIControlEventTouchUpInside];
 }
 
 - (void) setUpMultipeer{
 //  Setup peer ID
 self.myPeerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
 
 //  Setup session
 self.mySession = [[MCSession alloc] initWithPeer:self.myPeerID];
 
 //  Setup BrowserViewController
 self.browserVC = [[MCBrowserViewController alloc] initWithServiceType:@"chat" session:self.mySession];
 
 //  Setup Advertiser
 self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:@"chat" discoveryInfo:nil session:self.mySession];
 
 self.browserVC.delegate = self;
 
 [self.advertiser start];
 }
 
 - (void) showBrowserVC{
 [self presentViewController:self.browserVC animated:YES completion:nil];
 }
 
 - (void) dismissBrowserVC{
 [self.browserVC dismissViewControllerAnimated:YES completion:nil];
 }
 
 #pragma marks MCBrowserViewControllerDelegate
 
 // Notifies the delegate, when the user taps the done button
 - (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
 [self dismissBrowserVC];
 }
 
 // Notifies delegate that the user taps the cancel button.
 - (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
 [self dismissBrowserVC];
 }
 
 - (void)viewDidLoad
 {
 [super viewDidLoad];
 // Do any additional setup after loading the view, typically from a nib.
 //    [self setUpUI];
 //    [self setUpMultipeer];
 }
 */


static NSString * const XXServiceType = @"InClass-service";


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.localPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.localPeerID
                                                        discoveryInfo:nil
                                                          serviceType:XXServiceType];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"Got invited");
    self.currSession = [[MCSession alloc] initWithPeer:self.localPeerID
                                        securityIdentity:nil
                                    encryptionPreference:MCEncryptionNone];
    self.currSession.delegate = self;
    invitationHandler(YES, self.currSession);
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@\n%@", peerID, message );
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"didChangeState %ld", state);
    if (state ==  MCSessionStateConnected) {
        self.serverPeerID = peerID;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *aTouch = [touches anyObject];
    CGPoint currentTouchPosition = [aTouch locationInView:self.view];
//    NSLog(@"%f,%f", currentTouchPosition.x, currentTouchPosition.y);
    
    CGFloat yLoc = currentTouchPosition.y;
    CGFloat yMid = self.view.center.y;
    CGFloat per = (yLoc - yMid) / yMid;
//    NSLog(@"yLoc %f perc %f", yLoc, per);
    
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
    NSError *error = nil;
    if (self.currSession && ![self.currSession sendData:data
                            toPeers:@[self.serverPeerID]
                           withMode:MCSessionSendDataReliable
                              error:&error]) {
        NSLog(@"[Error] %@", error);
    }
}

@end
