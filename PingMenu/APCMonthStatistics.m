#import "APCMonthStatistics.h"
#import "NSValueTransformer+MTLXMLTransformerAdditions.h"

@implementation APCMonthStatistics

+ (NSString*)XPathPrefix {
    return @"./response/";
}

+ (NSDictionary *)XMLKeyPathsByPropertyKey {
    return @{@"currentMonthDownload":   @"CurrentMonthDownload",
             @"currentMonthUpload":     @"CurrentMonthUpload"};
}

+ (NSValueTransformer*)XMLTransformerForKey:(NSString*)key
{
    return [NSValueTransformer mtl_XMLTransformerForUnsignedLongLong];
}

@end
