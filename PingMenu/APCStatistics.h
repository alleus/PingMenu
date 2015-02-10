#import <Foundation/Foundation.h>
@class APCMonthStatistics, APCTrafficStatistics;

@interface APCStatistics : NSObject

@property (nonatomic, strong) APCMonthStatistics *monthStatistics;
@property (nonatomic, strong) APCTrafficStatistics *trafficStatistics;

- (void)fetchStatistics;

@end
