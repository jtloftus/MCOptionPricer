//
//  MCNode.h
//  MCOptionPricer
//
//  Created by Joe Loftus on 11/5/13.
//  Copyright (c) 2013 Joe Loftus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCNode : NSObject

@property (nonatomic) float similatedPrice;
@property (nonatomic) int day;
@property (strong, nonatomic) MCNode *parent;
@property (strong, nonatomic) NSMutableArray *branches;

@property (nonatomic) float highEstimate;
@property (nonatomic) float lowEstimate;

- (MCNode *)initWithPrice:(float)price andDay:(int)day;

@end
