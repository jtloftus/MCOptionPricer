//
//  OptionPickerVC.h
//  MCOptionPricer
//
//  Created by Joe Loftus on 11/4/13.
//  Copyright (c) 2013 Joe Loftus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "APYahooDataPuller.h"
#import "MCViewController.h"

@interface OptionPickerVC : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (strong, nonatomic) NSString *ticker;
@property (strong, nonatomic) NSString *spotPrice;
@property (strong, nonatomic) APYahooDataPuller *dataPuller;

@end
