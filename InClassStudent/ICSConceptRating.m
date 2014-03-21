//
//  ICSConceptRating.m
//  InClassStudent
//
//  Created by Brie Bunge on 3/20/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSConceptRating.h"

@implementation ICSConceptRating

- (id)initWithConceptName:(NSString *)conceptName andLabel:(UILabel *)label
{
    self = [super init];
    if (self) {
        self.conceptName = conceptName;
        self.label = label;
        self.rating = 0;
    }
    return self;
}

@end
