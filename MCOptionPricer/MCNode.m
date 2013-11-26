//
//  MCNode.m
//  MCOptionPricer
//
//  Created by Joe Loftus on 11/5/13.
//  Copyright (c) 2013 Joe Loftus. All rights reserved.
//

#import "MCNode.h"

@implementation MCNode

- (MCNode *)initWithPrice:(float)price andDay:(float)day {
    self = [super init];
    if (self) {
        self.simulatedPrice = price;
        self.day = day;
    }
    return self;
}

// Lazy Instantiation
- (NSMutableArray *)branches {
    if (!_branches) _branches = [[NSMutableArray alloc] init];
    return _branches;
}

@end
