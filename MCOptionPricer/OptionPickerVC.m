//
//  OptionPickerVC.m
//  MCOptionPricer
//
//  Created by Joe Loftus on 11/4/13.
//  Copyright (c) 2013 Joe Loftus. All rights reserved.
//

#import "OptionPickerVC.h"

@interface OptionPickerVC ()

@property (weak, nonatomic) IBOutlet UIPickerView *optionPickerView;
@property (weak, nonatomic) IBOutlet UILabel *tickerLabel;
@property (weak, nonatomic) IBOutlet UILabel *spotPriceLabel;
@property (strong, nonatomic) NSMutableArray *days;
@property (strong, nonatomic) NSMutableArray *strikes;

@property (nonatomic) int selectedDay;
@property (nonatomic) float selectedStrike;

@end

@implementation OptionPickerVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// Lazy Instantiation
- (NSMutableArray *)days
{
    if (!_days) _days = [[NSMutableArray alloc] init];
    // Set the Image Picker Controller's delegate to the overlay view controller
    return _days;
    
}

// Lazy Instantiation
- (NSMutableArray *)strikes
{
    if (!_strikes) _strikes = [[NSMutableArray alloc] init];
    // Set the Image Picker Controller's delegate to the overlay view controller
    return _strikes;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.spotPriceLabel setText:self.spotPrice];
    [self.tickerLabel setText:self.ticker];
    
    for (int i=1; i<=60; i++) {
        [self.days addObject:[NSNumber numberWithInt:i]];
    }
    
    int spotPriceInt = [self.spotPrice integerValue];
    float strikeSpread;
    if (spotPriceInt > 100) {
        strikeSpread = 2;
    }
    else if (spotPriceInt > 50) {
        strikeSpread = 1;
    }
    else if (spotPriceInt > 10) {
        strikeSpread = .5;
    }
    else if (spotPriceInt > 10) {
        strikeSpread = .25;
    }
    else {
        strikeSpread = spotPriceInt / 50.0;
    }
    
    
    float currentStrike = spotPriceInt - 5 * strikeSpread;
    for (int i=0; i<11; i++) {
        [self.strikes addObject:[NSNumber numberWithFloat:currentStrike]];
        currentStrike += strikeSpread;
    }
    
    self.optionPickerView.delegate = self;
    self.optionPickerView.dataSource = self;
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component
{
    if (component == 0) {
        return [self.days count];
    }
    else {
        return [self.strikes count];
    }
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row   forComponent:(NSInteger)component
{
    if (component == 0) {
        return [NSString stringWithFormat:@"%@", [self.days objectAtIndex:row]];
    }
    else {
        return [NSString stringWithFormat:@"%@", [self.strikes objectAtIndex:row]];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row   inComponent:(NSInteger)component
{
    if (component == 0) {
        self.selectedDay = row + 1;
        NSLog(@"Selected Day: %d", self.selectedDay);
    }
    else {
        self.selectedStrike = [[self.strikes objectAtIndex:row] floatValue];
        NSLog(@"Selected Strike: %f", self.selectedStrike);
    }
}

@end
