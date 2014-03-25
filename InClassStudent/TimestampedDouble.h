//
//  TimestampedNumber.h
//  LiveGraph
//
//  Created by Paul Hegarty on 3/15/14.
//  Copyright (c) 2014 CS193p. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimestampedDouble : NSObject

- (instancetype)initWithCreationDate:(NSDate *)date
                           andDouble:(double)value;
- (instancetype)initWithDouble:(double)value;

@property (readonly, nonatomic) double doubleValue;
@property (readonly, nonatomic) NSDate *dateCreated;
@property (readonly, nonatomic) NSTimeInterval age;

@end
