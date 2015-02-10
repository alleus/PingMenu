#import <Mantle/Mantle.h>
#import "MTLXMLAdapter.h"

@interface APCTrafficStatistics : MTLModel <MTLXMLSerializing>

/**
 *  Current downstream traffic rate in bytes per second.
 */
@property (nonatomic, assign) unsigned long long currentDownloadRate;

/**
 *  Current upstream traffic rate in bytes per second.
 */
@property (nonatomic, assign) unsigned long long currentUploadRate;

@end
