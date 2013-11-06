//
//  OptionPickerVC.h
//  MCOptionPricer
//
//  Created by Joe Loftus on 11/4/13.
//  Copyright (c) 2013 Joe Loftus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <math.h>
#import "MCNode.h"

#define R .001
#define D .000011106

@interface OptionPickerVC : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (strong, nonatomic) NSString *ticker;
@property (strong, nonatomic) NSString *spotPrice;
@property (nonatomic) float volatilityParameter;

@end
