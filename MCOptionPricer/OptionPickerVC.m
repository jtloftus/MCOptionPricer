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
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) IBOutlet UILabel *highEstimate;
@property (strong, nonatomic) IBOutlet UILabel *lowEstimate;

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
    
    for (int i=1; i<=15; i++) {
        [self.days addObject:[NSNumber numberWithInt:i]];
    }
    for (int i=20; i<=60; i+=5) {
        [self.days addObject:[NSNumber numberWithInt:i]];
    }
    
    int spotPriceInt = [self.spotPrice intValue];
    float strikeSpread;
    if (spotPriceInt > 500) {
        strikeSpread = 5;
    }
    else if (spotPriceInt > 100) {
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
    
    self.selectedStrike = currentStrike;
    self.selectedDay = 1;
    
    for (int i=0; i<11; i++) {
        [self.strikes addObject:[NSNumber numberWithFloat:currentStrike]];
        currentStrike += strikeSpread;
    }
    
    self.activityIndicator.hidesWhenStopped = YES;
    
    self.optionPickerView.delegate = self;
    self.optionPickerView.dataSource = self;

}


// This function generates a Random price over an interval of days
// Given the Method described by Broadie
- (float)generateRandomPrice:(float)prevPrice withT:(int)days
{
    // risk-free rate minus volatility ^ 2 divided by 2
    double first = R-pow(self.volatilityParameter * sqrt(days), 2)/2;
    // Generate a Standard Normal Variable
    float randGaus = [self rand_gauss];
    // The second part of the exponent is the volatility parameter, times the number of days times
    // A standard normal variable
    double second = self.volatilityParameter * days * randGaus;
    double exponent = first * days + second;
    // Return previous price * e ^ exponent
    return prevPrice * pow(M_E, exponent);
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
        if (row<15) {
            self.selectedDay = row + 1;
        }
        else {
            self.selectedDay = 15 + 5 * (row - 14);
        }
        NSLog(@"Selected Day: %d", self.selectedDay);
    }
    else {
        self.selectedStrike = [[self.strikes objectAtIndex:row] floatValue];
        NSLog(@"Selected Strike: %f", self.selectedStrike);
    }
}

// *** Method Derived From ***
// Knuth's 2nd volume of TAOCP 3rd edition page 122.
// Generates a Standard Normal Variable
- (float)rand_gauss {
    float v1,v2,s;
    
    do {
        v1 = 2.0 * ((float) rand()/RAND_MAX) - 1;
        v2 = 2.0 * ((float) rand()/RAND_MAX) - 1;
        
        s = v1*v1 + v2*v2;
    } while ( s >= 1.0 );
    
    if (s == 0.0)
        return 0.0;
    else
        return (v1*sqrt(-2.0 * log(s) / s));
}

// Get the Intrinsic value given current price (St)
- (float)getIntrinsicValue:(float)currentPrice
{
    // This is the Case for Call (St - K)
    if ([self.segmentedControl selectedSegmentIndex] == 0) {
        return MAX(currentPrice - self.selectedStrike, 0);
    }
    // This is the Case for a Put (K - St)
    return MAX(self.selectedStrike - currentPrice, 0);
}

- (float)getIntrinsicValueOfNode:(MCNode *)node
{
    return [self getIntrinsicValue:node.similatedPrice];
}

- (MCNode *)generateTreeWithT:(int)days {
    // How many days until expiry
    int d = [self selectedDay];
    int B;
    
    // How many branches we create
    if (self.selectedDay <= 1) {
        B = 15000;
    }
    else if (self.selectedDay <= 2) {
        B = 800;
    }
    else if (self.selectedDay <= 3) {
        B = 100;
    }
    else if (self.selectedDay <= 4) {
        B = 35;
    }
    else if (self.selectedDay <= 5) {
        B = 15;
    }
    else if (self.selectedDay <= 6) {
        B = 10;
    }
    else if (self.selectedDay <= 7) {
        B = 8;
    }
    else if (self.selectedDay <= 8) {
        B = 6;
    }
    else if (self.selectedDay <= 10) {
        B = 4;
    }
    else if (self.selectedDay <= 13) {
        B = 3;
    }
    else if (self.selectedDay <= 15) {
        B = 2;
    }
    else if (self.selectedDay <= 50) {
        B = 4;
    }
    else {
        B = 3;
    }
    NSLog(@"B = %d", B);
    
    // Add nodes that need branches to this array
    NSMutableArray *nodesNeedingBranches = [[NSMutableArray alloc] init];
    
    // Bootstrap the root node
    MCNode *root = [[MCNode alloc] initWithPrice:[self.spotPrice floatValue] andDay:0];
    root.parent = Nil;
    [nodesNeedingBranches addObject:root];
    
    MCNode *currentNode, *newNode;
    // Continue until each node that needs branches gets them
    while ([nodesNeedingBranches count] > 0) {
        // Pop from the front
        currentNode = nodesNeedingBranches[0];
        [nodesNeedingBranches removeObjectAtIndex:0];
        // Only add branches if we haven't gotten to expiry date yet
        if (currentNode.day < d) {
            // Add B branches (defined in .h file)
            for (int i=0; i < B; i++) {
                // Generate a random price and increment the day by one
                float simPrice = [self generateRandomPrice:currentNode.similatedPrice withT:days];
                int newDay = currentNode.day + days;
                // Create the new node with simulated price, updated day, and parent pointer
                newNode = [[MCNode alloc] initWithPrice:simPrice andDay:newDay];
                newNode.parent = currentNode;
                // Add the new node to the parent's branches
                [currentNode.branches addObject:newNode];
                // Now the new node needs branches
                [nodesNeedingBranches addObject:newNode];
            }
        }
    }
    return root;
}

// This calculates the high estimate of a node given the Broadie Method
- (float)getHighEstimate:(MCNode *)node withT:(int)days {
    float expectedContinuingValue = 0.0;
    // Sum up the ensuing node's high values
    for (MCNode *branch in node.branches) {
        expectedContinuingValue += branch.highEstimate;
    }
    // Discount the average of the continuing values
    return ((expectedContinuingValue / [node.branches count]) * pow(M_E, -days * D));
}

// This calculates the low estimate of a node given the Broadie Method
- (float)getLowEstimate:(MCNode *)node withT:(int)days {
    float expectedContinuingValue = 0.0;
    // We use one node as the value and the others to determine if we excercise
    for (MCNode *branch1 in node.branches) {
        float intermediateValue = 0.0;
        // Add up the other nodes to determine if we excercise
        for (MCNode *branch2 in node.branches) {
            if (![branch1 isEqual:branch2]) {
                intermediateValue += branch2.lowEstimate;
            }
        }
        intermediateValue = (intermediateValue / ([node.branches count] - 1)) * pow(M_E, -days * D);
        // If we shouldn't excercise based on the other nodes, we just add branch 1's low value
        if (intermediateValue > [self getIntrinsicValueOfNode:node]) {
            expectedContinuingValue += branch1.lowEstimate;
        }
        // Otherwise, use the stopping value of the node
        else {
            expectedContinuingValue += [self getIntrinsicValueOfNode:branch1];
        }
    }
    // Average the results of the above calculations and discount it
    return ((expectedContinuingValue / [node.branches count]) * pow(M_E, -days * D));
}

// Recursively Computes the value of an option using the Broadie Method
- (void)calculateOptionPriceWithRoot:(MCNode *)root withT:(int)days{
    // Find the intrinsic value of the option
    float intrinsicValue = [self getIntrinsicValueOfNode:root];
    // If we're at one of the terminal nodes, the high and low estimate is just
    // the intrinsic value
    if ([root.branches count] == 0) {
        root.highEstimate = intrinsicValue;
        root.lowEstimate = intrinsicValue;
    }
    // Otherwise, calculate the value recursively
    else {
        // Calculate the price of all of the node's branches
        for (MCNode *branch in root.branches) {
            [self calculateOptionPriceWithRoot:branch withT:days];
        }
        // The high estimate is the max of the intrinsic value and the high estimate
        root.highEstimate = MAX([self getHighEstimate:root withT:days], intrinsicValue);
        // The low estimate is the max of the intrinsic value and the low estimate
        root.lowEstimate = MAX([self getLowEstimate:root withT:days], intrinsicValue);
    }
}

- (IBAction)calculatePrice:(id)sender {
    dispatch_queue_t calculateQueue = dispatch_queue_create("option calculator", NULL);
    dispatch_async(calculateQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator startAnimating];
            
        });
        int days;
        
        if (self.selectedDay < 20) {
            days = 1;
        }
        
        else {
            days = 5;
        }
        
        MCNode *root = [self generateTreeWithT:days];
        
        [self calculateOptionPriceWithRoot:root withT:days];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            [self.highEstimate setText:[NSString stringWithFormat:@"%0.3f", root.highEstimate]];
            [self.lowEstimate setText:[NSString stringWithFormat:@"%0.3f", root.lowEstimate]];
        });
    });
}

@end
