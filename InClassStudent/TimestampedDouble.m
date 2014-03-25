//
//  TimestampedNumber.m
//  LiveGraph
//
//  Created by Paul Hegarty on 3/15/14.
//  Copyright (c) 2014 CS193p. All rights reserved.
//

#import "TimestampedDouble.h"

@interface TimestampedDouble()
@property (readwrite, nonatomic) double doubleValue;
@property (readwrite, nonatomic, strong) NSDate *dateCreated;
@end

@implementation TimestampedDouble

- (instancetype)initWithCreationDate:(NSDate *)date
                           andDouble:(double)value
{
    self = [super init];
    if (self) {
        _dateCreated = date;
        _doubleValue = value;
    }
    return self;
}

- (instancetype)initWithDouble:(double)value
{
    self = [self initWithCreationDate:[NSDate date]
                            andDouble:value];
    return self;
}

- (NSTimeInterval)age
{
    return [self.dateCreated timeIntervalSinceNow] * -1;
}

- (NSComparisonResult)compare:(id)object
{
    if ([object respondsToSelector:@selector(doubleValue)]) {
        double otherValue = [object doubleValue];
        if (otherValue > self.doubleValue) {
            return NSOrderedAscending;
        } else if (otherValue < self.doubleValue) {
            return NSOrderedDescending;
        }
    } else {
        NSLog(@"[%@ %@] invalid comparison with %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), object);
    }

    return NSOrderedSame;
}

@end
