//
//  OptionPickerVC.h
//  MCOptionPricer
//
//  Created by Joe Loftus on 11/4/13.
//  Copyright (c) 2013 Joe Loftus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptionPickerVC : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (strong, nonatomic) NSString *ticker;
@property (strong, nonatomic) NSString *spotPrice;

@end
