//
//  ICSMultipeerManager.m
//  InClassStudent
//
//  Created by Brie Bunge on 3/3/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSMultipeerManager.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ICSMultipeerManager()<MCNearbyServiceAdvertiserDelegate, MCSessionDelegate>

@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCPeerID *localPeerID;
// TODO: make able to connect to multiple servers?
@property (nonatomic, strong) MCPeerID *serverPeerID;
@property (nonatomic, strong) MCSession *serverSession;

@end

@implementation ICSMultipeerManager

+ (id)sharedManager {
    static ICSMultipeerManager *sharedManager = nil;
    @synchronized(self) {
        if (sharedManager == nil) {
            sharedManager = [[self alloc] init];
        }
    }
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // TODO: does this work properly?
        dispatch_queue_t queue = dispatch_queue_create("multipeer advertise queue", NULL);
        dispatch_async(queue, ^{
            static NSString * const XXServiceType = @"InClass-service";
            self.localPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
            
            self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.localPeerID
                                                                discoveryInfo:nil
                                                                  serviceType:XXServiceType];
            self.advertiser.delegate = self;
            [self.advertiser startAdvertisingPeer];
            NSLog(@"started advertiser");
        });
    }
    return self;
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    // TODO: does this work properly?
    dispatch_queue_t queue = dispatch_queue_create("accept invite queue", NULL);
    dispatch_async(queue, ^{
        // Keep a strong reference to the session
        self.serverSession = [[MCSession alloc] initWithPeer:self.localPeerID
                                            securityIdentity:nil
                                        encryptionPreference:MCEncryptionNone];
        self.serverSession.delegate = self;
        invitationHandler(YES, self.serverSession);
    });
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kDataReceivedFromServerNotification
                                                        object:self
                                                      userInfo:@{kServerPeerID: peerID, kDataKey: data}];
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected) {
        self.serverPeerID = peerID;
    }
}

- (void)sendData:(NSData *)data
{
    if (!self.serverSession) return;
    
    NSError *error = nil;
    BOOL result = [self.serverSession sendData:data
                                       toPeers:@[self.serverPeerID]
                                      withMode:MCSessionSendDataReliable
                                         error:&error];
    if (!result) NSLog(@"[Error] %@", error);
}

#pragma mark - Unused Delegate Methods


- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress { }

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName
       fromPeer:(MCPeerID *)peerID { }

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error { }

@end
