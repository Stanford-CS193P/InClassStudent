//
//  ICSRemoteObjectQueue.m
//  InClassStudent
//
//  Created by Brie Bunge on 4/7/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSRemoteObjectQueue.h"
#import "ICSRemoteClient.h"

@interface ICSRemoteObjectQueue()

@property (nonatomic, strong) NSMutableArray *outgoingRemoteObjects; // of id<ICSRemoteObject>

@end

@implementation ICSRemoteObjectQueue

+ (ICSRemoteObjectQueue *)sharedQueue
{
    static ICSRemoteObjectQueue *sharedQueue = nil;
    @synchronized(self) {
        if (sharedQueue == nil) {
            sharedQueue = [[self alloc] init];
            
            [[NSNotificationCenter defaultCenter] addObserver:sharedQueue
                                                     selector:@selector(serverDidDisconnect)
                                                         name:kServerDisconnected
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:sharedQueue
                                                     selector:@selector(serverDidConnect)
                                                         name:kServerConnected
                                                       object:nil];
        }
    }
    return sharedQueue;
}

- (NSMutableArray *)outgoingRemoteObjects
{
    if (!_outgoingRemoteObjects) {
        _outgoingRemoteObjects = [[NSMutableArray alloc] init];
    }
    return _outgoingRemoteObjects;
}

- (void)addOutgoingRemoteObject:(id<ICSRemoteObject>)object
{
    if ([[ICSRemoteClient sharedManager] serverIsConnected]) {
        [object send];
    } else {
        [self.outgoingRemoteObjects addObject:object];
    }
}

- (void)serverDidConnect
{
    [self.outgoingRemoteObjects makeObjectsPerformSelector:@selector(send)];
    [self.outgoingRemoteObjects removeAllObjects];
}

- (void)serverDidDisconnect { }

// TODO: handle socket sendEvent on error

@end
