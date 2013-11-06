//
//  MCNode.h
//  MCOptionPricer
//
//  Created by Joe Loftus on 11/5/13.
//  Copyright (c) 2013 Joe Loftus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCNode : NSObject

@property (nonatomic) float similatedPrice; // Simulated Price at this node
@property (nonatomic) int day;  // The time in days of the node
@property (strong, nonatomic) MCNode *parent;
@property (strong, nonatomic) NSMutableArray *branches; // The simulated nodes after this node

@property (nonatomic) float highEstimate; // Broadie High Estimate Value of the Node
@property (nonatomic) float lowEstimate; // Broadie Low Estimate Value of the Node

- (MCNode *)initWithPrice:(float)price andDay:(int)day;

@end
