//
//  ICSMultipeerManager.m
//  InClassStudent
//
//  Created by Brie Bunge on 3/3/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSMultipeerManager.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ICSMultipeerManager()<MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, NSStreamDelegate>

@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCPeerID *localPeerID;
// TODO: make able to connect to multiple teacher apps
@property (nonatomic, strong) MCPeerID *serverPeerID;
@property (nonatomic) BOOL serverIsConnected;
@property (nonatomic, strong) MCSession *session;

@end

@implementation ICSMultipeerManager

+ (id)sharedManager
{
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
        static NSString * const XXServiceType = @"InClass-service";
        self.localPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        
        self.session = [[MCSession alloc] initWithPeer:self.localPeerID];
        self.session.delegate = self;
        
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.localPeerID
                                                            discoveryInfo:nil
                                                              serviceType:XXServiceType];
        self.advertiser.delegate = self;
        [self.advertiser startAdvertisingPeer];
    }
    return self;
}

- (void)setServerIsConnected:(BOOL)serverIsConnected
{
    _serverIsConnected = serverIsConnected;
    
    if (_serverIsConnected) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kServerConnected
                                                            object:self
                                                          userInfo:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kServerDisconnected
                                                            object:self
                                                          userInfo:nil];
    }
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"didReceiveInvitationFromPeer, %@", peerID.displayName);
    if (self.serverPeerID) {
        NSLog(@"Was already invited, so we'll overwrite...");
    }
    self.serverPeerID = peerID;
    
    invitationHandler(YES, self.session);
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL))certificateHandler
{
    NSLog(@"didReceiveCertificate %@", peerID.displayName);
    if (certificateHandler) certificateHandler(YES);
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected) {
        NSLog(@"MCSessionStateConnected %@", peerID.displayName);
        if (peerID == self.serverPeerID) {
            self.serverIsConnected = YES;
        }
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"MCSessionStateNotConnected %@", peerID.displayName);
        if (peerID == self.serverPeerID) {
            self.serverPeerID = nil;
            self.serverIsConnected = NO;
        }
    } else if (state == MCSessionStateConnecting) {
        NSLog(@"MCSessionStateConnecting %@", peerID.displayName);
    }
}

- (void)sendData:(NSData *)data
{
    if (!self.session) return;
    if (!self.serverPeerID) return;
    if (!self.serverIsConnected) return;
    
    NSError *error = nil;
    BOOL result = [self.session sendData:data
                                 toPeers:@[self.serverPeerID]
                                withMode:MCSessionSendDataReliable
                                   error:&error];
    if (!result) NSLog(@"[Error] %@", error);
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName
       fromPeer:(MCPeerID *)peerID
{
    assert(peerID == self.serverPeerID);
    
    stream.delegate = self;
    [stream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [stream open];
}

#define kBufSize 1024
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent
{
    // TODO: handle stream errors
    // TODO: Disposing of the Stream Object
    
    if (streamEvent == NSStreamEventHasBytesAvailable) {
        NSMutableData *data = [[NSMutableData alloc] init];

        while ([(NSInputStream *)stream hasBytesAvailable] ) {
            uint8_t buf[kBufSize]; // TODO: reuse same buffer?
            NSInteger len = [(NSInputStream *)stream read:buf maxLength:kBufSize];
            NSLog(@"num bytes read from stream: %d", len);
            if (len <= 0) break;
            
            [data appendBytes:(const void *)buf length:len];
        }
        
        NSString* str = [NSString stringWithUTF8String:[data bytes]];
        NSLog(@"DATA: %@", str);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDataReceivedFromServerNotification
                                                            object:self
                                                          userInfo:@{kDataKey: data}];
    }
}

#pragma mark - Unused Delegate Methods

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID { }

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress { }

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error { }

@end
