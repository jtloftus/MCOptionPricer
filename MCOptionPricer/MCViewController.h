//
//  MCViewController.h
//  MCOptionPricer
//
//  Created by Joe Loftus on 11/3/13.
//  Copyright (c) 2013 Joe Loftus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "APYahooDataPuller.h"
#import "OptionPickerVC.h"

@interface MCViewController : UIViewController <UITextFieldDelegate>

- (float)computeVolatilityParameter:(NSArray *)financialData forNumberOfDays:(int)days;

@end
