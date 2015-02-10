#import "APCStatistics.h"

#import <KissXML/DDXML.h>

#import "MTLXMLAdapter.h"
#import "APCTrafficStatistics.h"
#import "APCMonthStatistics.h"

@implementation APCStatistics

- (void)fetchStatistics
{
    __weak APCStatistics *statistcs = self;

    NSURL *URL = [NSURL URLWithString:@"http://10.0.30.1/api/monitoring/traffic-statistics"];

    NSURLSession *URLSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [URLSession dataTaskWithURL:URL
                                           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                               if (error) {
                                                   NSLog(@"Error: %@", error);
                                                   return;
                                               }

                                               NSString *XMLString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                               NSError *decodeError = nil;
                                               DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:XMLString
                                                                                                     options:0
                                                                                                       error:&decodeError];

                                               if (decodeError) {
                                                   statistcs.trafficStatistics = nil;
                                                   NSLog(@"XML Error: %@", decodeError);
                                                   return;
                                               }

                                               NSError *parseError = nil;
                                               statistcs.trafficStatistics = [MTLXMLAdapter modelOfClass:[APCTrafficStatistics class]
                                                                                             fromXMLNode:doc
                                                                                                   error:&parseError];

                                               if (parseError) {
                                                   NSLog(@"Parse Error: %@", parseError);
                                                   return;
                                               }
                                           }];
    [task resume];

    URL = [NSURL URLWithString:@"http://10.0.30.1/api/monitoring/month_statistics"];

    task = [URLSession dataTaskWithURL:URL
                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                         if (error) {
                             NSLog(@"Error: %@", error);
                             return;
                         }

                         NSString *XMLString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                         NSError *decodeError = nil;
                         DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:XMLString
                                                                               options:0
                                                                                 error:&decodeError];

                         if (decodeError) {
                             statistcs.monthStatistics = nil;
                             NSLog(@"XML Error: %@", decodeError);
                             return;
                         }

                         NSError *parseError = nil;
                         statistcs.monthStatistics = [MTLXMLAdapter modelOfClass:[APCMonthStatistics class]
                                                                     fromXMLNode:doc
                                                                           error:&parseError];
                         
                         if (parseError) {
                             NSLog(@"Parse Error: %@", parseError);
                             return;
                         }
                     }];
    [task resume];
}

@end
