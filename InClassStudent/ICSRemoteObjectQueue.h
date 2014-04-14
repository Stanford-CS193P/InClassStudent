//
//  ICSRemoteObjectQueue.h
//  InClassStudent
//
//  Created by Brie Bunge on 4/7/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICSRemoteObject.h"

@interface ICSRemoteObjectQueue : NSObject

+ (ICSRemoteObjectQueue *)sharedQueue;

- (void)addOutgoingRemoteObject:(id<ICSRemoteObject>)object;

@end
