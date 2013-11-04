//
//  MCViewController.m
//  MCOptionPricer
//
//  Created by Joe Loftus on 11/3/13.
//  Copyright (c) 2013 Joe Loftus. All rights reserved.
//

#import "MCViewController.h"

@interface MCViewController ()

@property (strong, nonatomic) APYahooDataPuller *dataPuller;

@end

@implementation MCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Data puller
    NSDate *start         = [NSDate dateWithTimeIntervalSinceNow:-60.0 * 60.0 * 24.0 * 7.0 * 12.0]; // 12 weeks ago
    NSDate *end           = [NSDate date];
    self.dataPuller = [[APYahooDataPuller alloc] initWithTargetSymbol:@"AAPL" targetStartDate:start targetEndDate:end];
    
}


- (IBAction)printData:(id)sender {
    //NSLog(@"%@", [self.dataPuller.financialData[0] objectForKey:@"close"]);
    //NSLog(@"%@", self.dataPuller.financialData);
    
    NSLog(@"%@",[self fetchQuotesFor:@[@"AAPL", @"hello"]]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        quotes = [[NSMutableDictionary alloc] initWithCapacity:[quoteEntries count]];
        for (NSDictionary *quoteEntry in quoteEntries) {
            [quotes setValue:[quoteEntry valueForKey:@"BidRealtime"] forKey:[quoteEntry valueForKey:@"symbol"]];
        }
    }
    return quotes;
}

@end
