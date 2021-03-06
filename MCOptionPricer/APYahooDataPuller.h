#import <Foundation/Foundation.h>

@class APYahooDataPuller;

@protocol APYahooDataPullerDelegate <NSObject>

@required

-(void)dataPullerDidFinishFetch:(APYahooDataPuller *)dp;

@end

@interface APYahooDataPuller : NSObject {
    NSString *symbol;
    NSDate *startDate;
    NSDate *endDate;

    NSDate *targetStartDate;
    NSDate *targetEndDate;
    NSString *targetSymbol;

    id delegate;
    NSDecimalNumber *overallHigh;
    NSDecimalNumber *overallLow;
    NSDecimalNumber *overallVolumeHigh;
    NSDecimalNumber *overallVolumeLow;

    @private
    NSString *csvString;
    NSArray *financialData; // consists of dictionaries

    BOOL loadingData;
    NSMutableData *receivedData;
    NSURLConnection *connection;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, copy) NSString *targetSymbol;
@property (nonatomic, retain) NSDate *targetStartDate;
@property (nonatomic, retain) NSDate *targetEndDate;
@property (nonatomic, readonly, strong) NSArray *financialData;
@property (nonatomic, readonly, strong) NSDecimalNumber *overallHigh;
@property (nonatomic, readonly, strong) NSDecimalNumber *overallLow;
@property (nonatomic, readonly, strong) NSDecimalNumber *overallVolumeHigh;
@property (nonatomic, readonly, strong) NSDecimalNumber *overallVolumeLow;

-(id)initWithTargetSymbol:(NSString *)aSymbol targetStartDate:(NSDate *)aStartDate targetEndDate:(NSDate *)anEndDate;

@end
