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
@property (strong, nonatomic) APYahooDataPuller *dataPuller;
@property (strong, nonatomic) NSString *tickerString;
@property (strong, nonatomic) NSString *spotPrice;

@end

@implementation MCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.invalidTickerLabel setText:@""];
}


- (IBAction)printData:(id)sender {
    //NSLog(@"%@", [self.dataPuller.financialData[0] objectForKey:@"close"]);
    //NSLog(@"%@", self.dataPuller.financialData);
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
            [self performSegueWithIdentifier:@"inputOption" sender:self];
        }
    }
    else {
        [self.invalidTickerLabel setText:@"Please enter a ticker."];
    }
}

#define QUOTE_QUERY_PREFIX @"http://query.yahooapis.com/v1/public/yql?q=select%20symbol%2C%20BidRealtime%20from%20yahoo.finance.quotes%20where%20symbol%20in%20("
#define QUOTE_QUERY_SUFFIX @")&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="

- (NSDictionary *)fetchQuotesFor:(NSArray *)tickers
{
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
    return quotes;
}

- (BOOL)isValidTicker:(NSString *)ticker
{
    NSArray *tickers = @[ticker, @"dummy"];
    NSDictionary *quotes = [self fetchQuotesFor:tickers];
    if ([quotes valueForKey:[ticker uppercaseString]] != [NSNull null]) {
        self.spotPrice = [quotes valueForKey:[ticker uppercaseString]];
        return YES;
    }
    return NO;
}

- (float)computeVolatilityParameter:(NSArray *)financialData forNumberOfDays:(int)days
{
    NSArray *closingPrices = [self retrieveClosingPrices:financialData];
    NSArray *dailyReturns = [self retrieveDailyReturns:closingPrices];
    float volatility = [[self standardDeviationOf:dailyReturns] floatValue];
    NSLog(@"Volatility: %f", volatility);
    return volatility;
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
    NSLog(@"daily returns: %@", dailyReturns);
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
        
        // Data puller
        NSDate *start         = [NSDate dateWithTimeIntervalSinceNow:-60.0 * 60.0 * 24.0 * 7.0 * 12.0]; // 13 weeks ago
        NSDate *end           = [NSDate date];
        self.dataPuller = [[APYahooDataPuller alloc] initWithTargetSymbol:formattedTicker targetStartDate:start targetEndDate:end];
        opvc.dataPuller = self.dataPuller;
        
        NSLog(@"Data Puller: %@", self.dataPuller.financialData);
    }
}

- (IBAction)done:(UIStoryboardSegue *)segue
{
    // Done is our "cancel" unwind segue.
    // Whenever we want the user to return to the map without any actions,
    // This is the unwind segue we call
}

@end
