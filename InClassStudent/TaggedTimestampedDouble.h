//
//  TaggedTimestampedDouble.h
//  InClassTeacher
//
//  Created by Johan Ismael on 3/20/14.
//  Copyright (c) 2014 Johan Ismael. All rights reserved.
//

#import "TimestampedDouble.h"

@interface TaggedTimestampedDouble : TimestampedDouble

- (instancetype)initWithDouble:(double)value
                        andTag:(NSString *)tag
                         andID:(NSString *)identifier;
- (void)send;

@property (strong, nonatomic, readonly) NSString *tag;
@property (strong, nonatomic, readonly) NSString *identifier;

@end