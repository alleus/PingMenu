//
//  NSValueTransformer+MTLXMLTransformerAdditions.h
//  Mantle
//
//  Created by Matthew Baranowski on 6/26/13.
//  Copyright (c) 2013 Matthew Baranowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSValueTransformer (MTLXMLTransformerAdditions)

+ (NSValueTransformer *)mtl_XMLTransformerForInteger;
+ (NSValueTransformer *)mtl_XMLTransformerForUnsignedLongLong;
+ (NSValueTransformer *)mtl_XMLTransformerForURL;
+ (NSValueTransformer *)mtl_XMLTransformerForDateWithFormat:(NSString*)dateFormat;

+ (NSValueTransformer *)mtl_XMLTransformerWithModelClass:(Class)modelClass;
+ (NSValueTransformer *)mtl_XMLArrayTransformerWithModelClass:(Class)modelClass;
+ (NSValueTransformer *)mtl_XMLNonUniformObjectArrayTransformerWithModelClass:(Class)modelClass;

@end
