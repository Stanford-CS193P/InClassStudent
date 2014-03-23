//
//  ICSMultipeerManager.m
//  InClassStudent
//
//  Created by Brie Bunge on 3/3/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSMultipeerManager.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ICSMultipeerManager()<MCNearbyServiceBrowserDelegate, MCSessionDelegate>

@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCPeerID *localPeerID;
// TODO: make able to connect to multiple teacher apps
@property (nonatomic, strong) NSMutableDictionary *serverPeerIDs; // of MCPeerID
@property (nonatomic) BOOL serverIsConnected;

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

- (MCNearbyServiceBrowser *)browser
{
    if (!_browser) {
        _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.localPeerID serviceType:XXServiceType];
        _browser.delegate = self;
    }
    return _browser;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self browse];
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

- (NSMutableDictionary *)serverPeerIDs
{
    if (!_serverPeerIDs) {
        _serverPeerIDs = [[NSMutableDictionary alloc] init];
    }
    return _serverPeerIDs;
}

#pragma mark - Multipeer browser delegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"==============> %@", @"peer found");
    
    MCSession *session = [[MCSession alloc] initWithPeer:self.localPeerID
                                        securityIdentity:nil
                                    encryptionPreference:MCEncryptionNone];
    session.delegate = self;
    NSLog(@"created session for peer %@", peerID.displayName);
    
    [self.serverPeerIDs setObject:session forKey:peerID];
    
    // TODO: prevent multiple sessions or invitations to same peer
    [browser invitePeer:peerID
              toSession:session
            withContext:nil
                timeout:0];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"==============> %@", @"peer lost");
    [self disconnectPeer:peerID];
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
        
            NSLog(@"Server connected");
            self.serverIsConnected = YES;
            //[self.browser stopBrowsingForPeers];
        
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"MCSessionStateNotConnected %@", peerID.displayName);
        

            NSLog(@"Server disconnected");
            [self disconnectPeer:peerID];
    } else if (state == MCSessionStateConnecting) {
        NSLog(@"MCSessionStateConnecting %@", peerID.displayName);
    }
}

- (void)sendDict:(NSDictionary *)dict
{
    NSLog(@"====> Sending data");
    
    if ([self.serverPeerIDs count] == 0) return;
    if (!self.serverIsConnected) return;
    
    // Append bookkeeping fields
    NSMutableDictionary *dictMod = [[NSMutableDictionary alloc] initWithDictionary:dict];
    [dictMod setObject:[NSDate date] forKey:@"time"];
    [dictMod setObject:[[NSUUID UUID] UUIDString] forKey:@"uuid"];
    [dictMod setObject:self.localPeerID.displayName forKey:@"peerIDDisplayName"];
    
    NSLog(@"INFO: sendDict %@", dictMod);
    
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dictMod];
    
    // TODO: one send data call to all using toPeers array
    for (MCPeerID *peerID in self.serverPeerIDs) {
        NSError *error = nil;
        MCSession *session = [self.serverPeerIDs objectForKey:peerID];
        BOOL result = [session sendData:data
                                toPeers:@[peerID]
                               withMode:MCSessionSendDataReliable
                                  error:&error];
        if (!result) NSLog(@"ERROR: %@", error);
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    if (![[self.serverPeerIDs allKeys] containsObject:peerID]) {
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

- (void)browse
{
    NSLog(@"==============> %@", @"started browser");
    [self.browser startBrowsingForPeers];
}

- (void)disconnect
{
    NSLog(@"disconnecting self...");
    
    [self.browser stopBrowsingForPeers];
    
    for (MCPeerID *peerID in self.serverPeerIDs) {
        [self disconnectPeer:peerID];
    }
}

- (void)disconnectPeer:(MCPeerID *)peerID
{
    if (![[self.serverPeerIDs allKeys] containsObject:peerID]) {
        return;
    }
    
    NSLog(@"disconnecting %@", peerID.displayName);
    MCSession *session = [self.serverPeerIDs objectForKey:peerID];
    
    [session disconnect];
    session.delegate = nil;
    
    [self.serverPeerIDs removeObjectForKey:peerID];
    self.serverIsConnected = NO;
    
    self.browser = nil;
    [self browse];
}

#pragma mark - Unused Delegate Methods

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID { }

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress { }

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error { }

@end
