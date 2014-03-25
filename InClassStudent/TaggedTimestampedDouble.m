//
//  TaggedTimestampedDouble.m
//  InClassTeacher
//
//  Created by Johan Ismael on 3/20/14.
//  Copyright (c) 2014 Johan Ismael. All rights reserved.
//

#import "TaggedTimestampedDouble.h"
#import "ICSRemoteClient.h"

@interface TaggedTimestampedDouble()

@property (strong, nonatomic) NSString *tag;

@end

@implementation TaggedTimestampedDouble

- (instancetype)initWithCreationDate:(NSDate *)date
                           andDouble:(double)value
                              andTag:(NSString *)tag
{
    self = [super initWithCreationDate:date
                             andDouble:value];
    if (self) {
        _tag = tag;
    }
    return self;
}

- (instancetype)initWithDouble:(double)value
                        andTag:(NSString *)tag
{
    return [self initWithCreationDate:[NSDate date]
                            andDouble:value
                               andTag:tag];
}

#define kCreateRatingEventName @"CreateRating"
#define kRatingKey @"rating"
#define kConceptNameKey @"conceptName"

- (void)send
{
    [[ICSRemoteClient sharedManager] sendEvent:kCreateRatingEventName
                                      withData:@{ kRatingKey: @(self.doubleValue),
                                                  kConceptNameKey: self.tag}];
}

@end
