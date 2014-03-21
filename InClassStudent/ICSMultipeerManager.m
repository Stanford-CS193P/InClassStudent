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
// TODO: make able to connect to multiple teacher apps
@property (nonatomic, strong) MCPeerID *serverPeerID;
@property (nonatomic) BOOL serverIsConnected;
@property (nonatomic, strong) MCSession *session;

@end

@implementation ICSMultipeerManager

static NSString * const XXServiceType = @"InClass-service";

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
        [self advertise];
    }
    return self;
}

- (MCPeerID *)localPeerID
{
    if (!_localPeerID) {
        _localPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    }
    return _localPeerID;
}

- (MCNearbyServiceAdvertiser *)advertiser
{
    if (!_advertiser) {
        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.localPeerID
                                                        discoveryInfo:nil
                                                          serviceType:XXServiceType];
        _advertiser.delegate = self;
    }
    return _advertiser;
}

- (MCSession *)session
{
    if (!_session) {
        _session = [[MCSession alloc] initWithPeer:self.localPeerID];
        _session.delegate = self;
    }
    return _session;
}

// Used for debugging check mark.
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
        [self disconnectPeer];
    }
    self.serverPeerID = peerID;
    
    invitationHandler(YES, self.session);
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate
       fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL))certificateHandler
{
    NSLog(@"INFO: didReceiveCertificate %@", peerID.displayName);
    if (certificateHandler) certificateHandler(YES);
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected) {
        NSLog(@"MCSessionStateConnected %@", peerID.displayName);
        
        if (peerID == self.serverPeerID) {
            NSLog(@"Server connected");
            self.serverIsConnected = YES;
        }
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"MCSessionStateNotConnected %@", peerID.displayName);
        
        if (peerID == self.serverPeerID) {
            NSLog(@"Server disconnected");
            [self disconnectPeer];
        }
    } else if (state == MCSessionStateConnecting) {
        NSLog(@"MCSessionStateConnecting %@", peerID.displayName);
    }
}

- (void)sendDict:(NSDictionary *)dict
{
    NSLog(@"====> Sending data");
    
    if (!self.session) return;
    if (!self.serverPeerID) return;
    if (!self.serverIsConnected) return;
    
    // Append bookkeeping fields
    NSMutableDictionary *dictMod = [[NSMutableDictionary alloc] initWithDictionary:dict];
    [dictMod setObject:[NSDate date] forKey:@"time"];
    [dictMod setObject:[[NSUUID UUID] UUIDString] forKey:@"uuid"];
    [dictMod setObject:self.localPeerID.displayName forKey:@"peerIDDisplayName"];
    
    NSLog(@"INFO: sendDict %@", dictMod);
    
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dictMod];
    
    NSError *error = nil;
    BOOL result = [self.session sendData:data
                                 toPeers:@[self.serverPeerID]
                                withMode:MCSessionSendDataReliable
                                   error:&error];
    if (!result) NSLog(@"ERROR: %@", error);
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    if (peerID != self.serverPeerID) {
        NSLog(@"WARN: didReceiveData, but not from server. Ignoring.");
        return;
    }
    
    NSString *message = [[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding];
    NSLog(@"INFO: didReceiveData from peer %@", message);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDataReceivedFromServerNotification
                                                        object:self
                                                      userInfo:@{kDataKey: data}];
}

- (void)advertise
{
    NSLog(@"advertising self...");
    [self.advertiser startAdvertisingPeer];
}

- (void)disconnect
{
    NSLog(@"disconnecting self...");
    
    [self.advertiser stopAdvertisingPeer];
    self.advertiser = nil;
    
    [self disconnectPeer];
}

- (void)disconnectPeer
{
    [self.session disconnect];
    self.session = nil;
    
    self.serverPeerID = nil;
    self.serverIsConnected = NO;
}

#pragma mark - Unused Delegate Methods

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID { }

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress { }

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error { }

@end
