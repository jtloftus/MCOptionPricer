//
//  MCViewController.m
//  MCOptionPricer
//
//  Created by Joe Loftus on 11/3/13.
//  Copyright (c) 2013 Joe Loftus. All rights reserved.
//

#import "MCViewController.h"

@interface MCViewController ()

@property (weak, nonatomic) IBOutlet UITextField *tickerTextField;
@property (weak, nonatomic) IBOutlet UILabel *invalidTickerLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UITextView *disclaimerTextView;


@property (strong, nonatomic) APYahooDataPuller *dataPuller;
@property (strong, nonatomic) NSString *tickerString;
@property (strong, nonatomic) NSString *spotPrice;

@property (strong, nonatomic) UITextField *activeField;

@end

@implementation MCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.disclaimerTextView.editable = NO;
    self.disclaimerTextView.scrollEnabled = NO;
    
    self.activityIndicator.hidesWhenStopped = YES;
    
    [self.invalidTickerLabel setText:@""];
    self.tickerTextField.delegate = self;
}


- (void)checkTicker {
    if ([self containsNonWhitespaceCharacters:self.tickerTextField.text]) {
        // Trim the leading and trailing whitespace from the comment
        NSString *trimmedTicker = [self.tickerTextField.text stringByTrimmingCharactersInSet:
                                    [NSCharacterSet whitespaceCharacterSet]];
        NSLog(@"Trimmed Ticker: %@", trimmedTicker);
        if (![self isValidTicker:trimmedTicker]) {
            [self.invalidTickerLabel setText:@"That's not a valid Ticker!"];
        }
        else {
            self.tickerString = trimmedTicker;
            
            // Data puller
            NSDate *start         = [NSDate dateWithTimeIntervalSinceNow:-60.0 * 60.0 * 24.0 * 7.0 * 12.0]; // 13 weeks ago
            NSDate *end           = [NSDate date];
            self.dataPuller = [[APYahooDataPuller alloc] initWithTargetSymbol:trimmedTicker targetStartDate:start targetEndDate:end];
            [self.dataPuller setDelegate:self];
            [self.activityIndicator startAnimating];
        }
    }
    else {
        [self.invalidTickerLabel setText:@"Please enter a ticker."];
    }
}

- (void)dataPullerDidFinishFetch:(APYahooDataPuller *)dp {
    [self.activityIndicator stopAnimating];
    [self performSegueWithIdentifier:@"inputOption" sender:self];
}

#define QUOTE_QUERY_PREFIX @"http://query.yahooapis.com/v1/public/yql?q=select%20symbol%2C%20BidRealtime%20from%20yahoo.finance.quotes%20where%20symbol%20in%20("
#define QUOTE_QUERY_SUFFIX @")&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="

- (NSDictionary *)fetchQuotesFor:(NSArray *)tickers
{
    [self.activityIndicator startAnimating];
    
    NSMutableDictionary *quotes;
    if (tickers && [tickers count] > 0) {
        NSMutableString *query = [[NSMutableString alloc] init];
        [query appendString:QUOTE_QUERY_PREFIX];
        for (int i = 0; i < [tickers count]; i++) {
            NSString *ticker = [tickers objectAtIndex:i];
            [query appendFormat:@"%%22%@%%22", ticker];
            if (i != [tickers count] - 1) [query appendString:@"%2C"];
        }
        [query appendString:QUOTE_QUERY_SUFFIX];
        NSLog(@"Query: %@", query);
        NSData *jsonData = [[NSString stringWithContentsOfURL:[NSURL URLWithString:query] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSDictionary *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error] : nil;
        if (error) NSLog(@"[%@ %@] JSON error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription);
        NSLog(@"[%@ %@] received %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), results);
        NSArray *quoteEntries = [results valueForKeyPath:@"query.results.quote"];
        quotes = [[NSMutableDictionary alloc] initWithCapacity:[tickers count]];
        for (NSDictionary *quoteEntry in quoteEntries) {
            [quotes setValue:[quoteEntry valueForKey:@"BidRealtime"] forKey:[quoteEntry valueForKey:@"symbol"]];
        }
    }
    [self.activityIndicator stopAnimating];
    
    return quotes;
}

- (BOOL)isValidTicker:(NSString *)ticker
{
    // Make sure the ticker only contains alpha Characters
    NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
    if (![[ticker stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""]) {
        return NO;
    }
    
    // Make sure this ticker returns a spot price
    // If it does -- then it's a valid ticker
    NSArray *tickers = @[ticker, @"dummy"];
    NSDictionary *quotes = [self fetchQuotesFor:tickers];
    if ([quotes valueForKey:[ticker uppercaseString]] != [NSNull null]) {
        self.spotPrice = [quotes valueForKey:[ticker uppercaseString]];
        [self.invalidTickerLabel setText:@""];
        NSLog(@"Valid Ticker!");
        return YES;
    }
    return NO;
}

// Computing the Volatility Parameter according to the Broadie Method for a given number of days
- (float)computeDailyVolatilityParameter:(NSArray *)financialData
{
    // Get the closing prices and daily returns
    NSArray *closingPrices = [self retrieveClosingPrices:financialData];
    NSArray *dailyReturns = [self retrieveDailyReturns:closingPrices];
    // Get the standard deviation of the daily returns for daily volatility parameter
    return [[self standardDeviationOf:dailyReturns] floatValue];
}

- (NSArray *)retrieveClosingPrices:(NSArray *)financialData {
    NSMutableArray *closingPrices = [[NSMutableArray alloc] init];
    for (int i=0; i<[financialData count]; i++) {
        NSDictionary *dailyData = financialData[i];
        float close = [[dailyData objectForKey:@"close"] floatValue];
        NSNumber *roundedClose = [NSNumber numberWithFloat:[self customRounding:close]];
        [closingPrices addObject:roundedClose];
    }
    return closingPrices;
}

- (NSArray *)retrieveDailyReturns:(NSArray *)closingPrices
{
    NSMutableArray *dailyReturns = [[NSMutableArray alloc] init];
    for (int i=0; i<([closingPrices count]-1); i++) {
        float currentPrice = [closingPrices[i] floatValue];
        float prevPrice = [closingPrices[i+1] floatValue];
        NSNumber *dailyReturn = [NSNumber numberWithFloat:((currentPrice - prevPrice) / prevPrice)];
        [dailyReturns addObject:dailyReturn];
    }
    return dailyReturns;
}

- (NSNumber *)meanOf:(NSArray *)array
{
    double runningTotal = 0.0;
    
    for(NSNumber *number in array)
    {
        runningTotal += [number doubleValue];
    }
    
    return [NSNumber numberWithDouble:(runningTotal / [array count])];
}

- (NSNumber *)standardDeviationOf:(NSArray *)array
{
    if(![array count]) return nil;
    
    double mean = [[self meanOf:array] doubleValue];
    double sumOfSquaredDifferences = 0.0;
    
    for(NSNumber *number in array)
    {
        double valueOfNumber = [number doubleValue];
        double difference = valueOfNumber - mean;
        sumOfSquaredDifferences += difference * difference;
    }
    
    return [NSNumber numberWithDouble:sqrt(sumOfSquaredDifferences / [array count])];
}

- (float) customRounding:(float)value {
    const float roundingValue = 0.01;
    int mulitpler = floor(value / roundingValue);
    return mulitpler * roundingValue;
}
    
// Checks if a string contains any non whitespace characters
- (BOOL)containsNonWhitespaceCharacters:(NSString *)string
{
    NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
    return ([[string stringByTrimmingCharactersInSet: set] length] != 0);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"inputOption"]) {
        NSString *formattedTicker = [self.tickerString uppercaseString];
        OptionPickerVC *opvc = (OptionPickerVC *)[segue destinationViewController];
        opvc.ticker = formattedTicker;
        opvc.spotPrice = self.spotPrice;
        
        opvc.volatilityParameter = [self computeDailyVolatilityParameter:self.dataPuller.financialData];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Hide the keyboard
    [self hideKeyboard];
    
    [self checkTicker];
    
    return YES;
}

- (void)hideKeyboard {
    [self.activeField resignFirstResponder];
}

- (IBAction)done:(UIStoryboardSegue *)segue
{
    // Done is our "cancel" unwind segue.
    // Whenever we want the user to return to the map without any actions,
    // This is the unwind segue we call
}

@end
