#import "APCTrafficStatistics.h"
#import "NSValueTransformer+MTLXMLTransformerAdditions.h"

@implementation APCTrafficStatistics

+ (NSString*)XPathPrefix {
    return @"./response/";
}

+ (NSDictionary *)XMLKeyPathsByPropertyKey {
    return @{@"currentDownloadRate":    @"CurrentDownloadRate",
             @"currentUploadRate":      @"CurrentUploadRate"};
}

+ (NSValueTransformer*)XMLTransformerForKey:(NSString*)key
{
    return [NSValueTransformer mtl_XMLTransformerForUnsignedLongLong];
}


@end
