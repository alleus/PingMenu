//
//  MTLXMLAdapter.h
//  Mantle
//
//  Created by Matthew Baranowski on 6/5/13.
//  Copyright (c) 2013 Matthew Baranowski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDXML.h"
#import "DDXMLNode.h"

@class MTLModel;

@protocol MTLXMLSerializing
@required
+ (NSDictionary *)XMLKeyPathsByPropertyKey;
+ (NSString*)XPathPrefix;
@optional
+ (Class)classForParsingXML:(DDXMLNode *)xmlNode;
+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key;

// used for manual reverse serializing
- (DDXMLElement *)serializeToXMLElement;

@end

@interface MTLXMLAdapter : NSObject

@property (nonatomic, strong, readonly) MTLModel<MTLXMLSerializing> *model;

+ (id)modelOfClass:(Class)modelClass fromXMLNode:(DDXMLNode *)xmlNode error:(NSError **)error;

+ (DDXMLElement *)XMLElementFromModel:(MTLModel<MTLXMLSerializing> *)model;

- (id)initWithXMLNode:(DDXMLNode*)node modelClass:(Class)modelClass error:(NSError **)error;

- (id)initWithModel:(MTLModel<MTLXMLSerializing> *)model;

- (DDXMLElement *)XMLElement;

@end
