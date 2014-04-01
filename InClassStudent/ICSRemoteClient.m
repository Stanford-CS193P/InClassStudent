//
//  ICSMultipeerManager.m
//  InClassStudent
//
//  Created by Brie Bunge on 3/3/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSRemoteClient.h"
#import "SocketIO.h"
#import "SocketIOPacket.h"
#import "SocketIO+SailsIO.h"

@interface ICSRemoteClient()<SocketIODelegate, NSURLConnectionDelegate>

@property (nonatomic, strong) SocketIO *socketIO;
@property (nonatomic, strong) NSURL *serverURL;
@property (nonatomic, strong) NSDictionary *eventToURLMap;
@property (nonatomic) int numRetries;
@property (nonatomic) BOOL shouldReconnect;

@end

@implementation ICSRemoteClient

+ (id)sharedManager
{
    static ICSRemoteClient *sharedManager = nil;
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
        // Make a request to the homepage, so that future requests have a cookie
        // TODO(brie): look into the cookie expiring
        NSURLRequest *request = [NSURLRequest requestWithURL:self.serverURL];
        [NSURLConnection connectionWithRequest:request delegate:self];
    }
    return self;
}

#pragma mark - Getters and setters

- (NSURL *)serverURL
{
    if (!_serverURL) {
        _serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d", kServer, kServerPort]];
    }
    return _serverURL;
}

- (NSDictionary *)eventToURLMap
{
    if (!_eventToURLMap) {
        _eventToURLMap = @{
                           @"CreateRating": @"/InClassStudentResponse/create"
                           };
    }
    return _eventToURLMap;
}

#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self connect];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"connection did fail with error: %@", error);
}

#pragma mark - socketIO delegate methods

// Possible delegate methods:
//- (void) socketIODidConnect:(SocketIO *)socket;
//- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error;
//- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet;
//- (void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet;
//- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet;
//- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet;
//- (void) socketIO:(SocketIO *)socket onError:(NSError *)error;

- (void)socketIODidConnect:(SocketIO *)socket
{
    self.serverIsConnected = YES;
}

- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    NSLog(@"socketIODidDisconnect with error: %@", error);
    self.serverIsConnected = NO;
    [self reconnect];
}

- (void)socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet
{
    NSDictionary *packetData = [packet dataAsJSON];
    NSLog(@"didReceiveJSON %@", packetData);
    
    NSString *model = [packetData objectForKey:@"model"];
    NSString *verb = [packetData objectForKey:@"verb"];
    NSDictionary *data = [packetData objectForKey:@"data"];
    
    if ([model isEqualToString:@"inclassconcept"] && [verb isEqualToString:@"create"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kConceptReceivedFromServerNotification
                                                            object:self
                                                          userInfo:@{kDataKey: data}];
    }
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

- (void)sendEvent:(NSString *)event withData:(NSDictionary *)dict andCallback:(void (^)(id response))callback
{
    if (![[self.eventToURLMap allKeys] containsObject:event]) {
        NSLog(@"event %@ not valid", event);
        return;
    }
    
    if (!self.serverIsConnected) return;
    
    // Append bookkeeping fields
    NSMutableDictionary *dictMod = [[NSMutableDictionary alloc] initWithDictionary:dict];
    [dictMod setObject:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"identifierForVendor"];
    
    NSLog(@"INFO: sendDict %@", dictMod);
    NSString *url = self.eventToURLMap[event];
    
    [self.socketIO get:url
              withData:dictMod
              callback:^(id response) {
                  if (callback) callback(response);
                  NSLog(@"%@ response: %@", url, response);
              }];
}

- (void)reconnect
{
    if (!self.shouldReconnect) return;
    
    dispatch_queue_t queue = dispatch_queue_create("server reconnection queue", NULL);
    dispatch_async(queue, ^{
        [self connect];
        for (self.numRetries = 1; self.numRetries < kMaxNumRetries; self.numRetries++) {
            if (self.serverIsConnected) break;
            [NSThread sleepForTimeInterval:kRetryIntervalInSecs];
            [self connect];
        }
    });
}

- (void)connect
{
    self.shouldReconnect = YES;
    if (self.serverIsConnected) return;
    NSLog(@"attempting to connect");
    
    NSArray *oldCookies = [[ NSHTTPCookieStorage sharedHTTPCookieStorage ]
                           cookiesForURL:self.serverURL];
    NSLog(@"oldCookies %@", oldCookies);
    
    self.socketIO = [[SocketIO alloc] initWithDelegate:self];
    // The password field is used (as a first pass!) to prevent random people
    // (but of course anyone can see this on github) from connecting to the server.
    // The server checks this password before creating the socket.
    // TODO(brie): better way to ensure valid user than plain text password
    [self.socketIO connectToHost:kServer onPort:kServerPort
                      withParams:@{@"user_type": @"student", @"password": @"cs193pisawesome"}];
}

- (void)disconnect
{
    self.shouldReconnect = NO;
    [self.socketIO disconnect];
}

@end
