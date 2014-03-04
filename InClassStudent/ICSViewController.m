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
    NSError *error = nil;
    if (self.currSession && ![self.currSession sendData:data
                            toPeers:@[self.serverPeerID]
                           withMode:MCSessionSendDataReliable
                              error:&error]) {
        NSLog(@"[Error] %@", error);
    }
}

@end
