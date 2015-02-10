#import <Mantle/Mantle.h>
#import "MTLXMLAdapter.h"

@interface APCMonthStatistics : MTLModel <MTLXMLSerializing>

/**
 *  Current monthly download ammount, in bytes.
 */
@property (nonatomic, assign) unsigned long long currentMonthDownload;

/**
 *  Current monthly upload ammount, in bytes.
 */
@property (nonatomic, assign) unsigned long long currentMonthUpload;

@end
