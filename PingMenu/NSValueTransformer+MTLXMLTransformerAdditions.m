//
//  NSValueTransformer+MTLXMLTransformerAdditions.m
//  Mantle
//
//  Created by Matthew Baranowski on 6/26/13.
//  Copyright (c) 2013 Matthew Baranowski. All rights reserved.
//

#import "NSValueTransformer+MTLXMLTransformerAdditions.h"
#import "MTLModel.h"
#import "MTLValueTransformer.h"
#import "MTLXMLAdapter.h"


@implementation NSValueTransformer (MTLXMLTransformerAdditions)

+ (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter* _dateFormatter;
    if (!_dateFormatter)
    {
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setDateStyle:NSDateFormatterFullStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterFullStyle];
    }
    
    return _dateFormatter;
}

+ (NSValueTransformer *)mtl_XMLTransformerForDateWithFormat:(NSString*)dateFormat {
	return [MTLValueTransformer
            reversibleTransformerWithForwardBlock:^id(NSArray *nodes) {
                if (nodes == nil || nodes.count == 0) return nil;
                
                DDXMLNode* node = nodes[0];
                NSDateFormatter* formatter = [NSValueTransformer dateFormatter];
                [formatter setDateFormat:dateFormat];
                
                NSString* locale = @"en_US_POSIX";
                if ([node kind] == DDXMLElementKind) {
                    DDXMLElement* element = (DDXMLElement*)node;
                    DDXMLNode* node = [element attributeForName:@"locale"];
                    locale = [node stringValue];
                }
                
                [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:locale]];
                
                id myDate;
                NSError* error;
                if (![formatter getObjectValue:&myDate
                                     forString:[node stringValue]
                                         range:nil
                                         error:&error]) {
                    return nil;
                }
                
                return myDate;
            }
            reverseBlock:^(NSDate *date) {
                NSDateFormatter* formatter = [NSValueTransformer dateFormatter];
                [formatter setDateFormat:dateFormat];
                return [formatter stringFromDate:date];
            }];
}


+ (NSValueTransformer *)mtl_XMLTransformerForInteger {
	return [MTLValueTransformer
    reversibleTransformerWithForwardBlock:^ id (NSArray *nodes) {
                    if ([nodes[0] stringValue] != nil && ![[nodes[0] stringValue] isEqualToString:@""])
                    {
                        return @([nodes[0] stringValue].integerValue);
                    }
                    else
                    {
                        return nil;
                    }
           } 
            reverseBlock:^(NSNumber* num) {
                return [    num stringValue];
            }];
}

+ (NSValueTransformer *)mtl_XMLTransformerForUnsignedLongLong {
    return [MTLValueTransformer
            reversibleTransformerWithForwardBlock:^ id (NSArray *nodes) {
                if ([nodes[0] stringValue] != nil && ![[nodes[0] stringValue] isEqualToString:@""]) {
                    NSScanner *scanner = [[NSScanner alloc] initWithString:[nodes[0] stringValue]];
                    unsigned long long number = 0;
                    if ([scanner scanUnsignedLongLong:&number]) {
                        return @(number);
                    } else {
                        return nil;
                    }
                } else {
                    return nil;
                }
            }
            reverseBlock:^(NSNumber* num) {
                return [num stringValue];
            }];
}

+ (NSValueTransformer *)mtl_XMLTransformerForURL {
    return [MTLValueTransformer
            reversibleTransformerWithForwardBlock:^ id (NSArray *nodes) {
                if (nodes == nil || nodes.count == 0) return nil;
                DDXMLNode* node = nodes[0];
                return [NSURL URLWithString:node.stringValue];
            }
            reverseBlock:^ id (NSURL *URL) {
                if (![URL isKindOfClass:NSURL.class]) return nil;
                return URL.absoluteString;
            }];
}

+ (NSValueTransformer *)mtl_XMLTransformerWithModelClass:(Class)modelClass {
	NSParameterAssert([modelClass isSubclassOfClass:MTLModel.class]);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLXMLSerializing)]);
    
	return [MTLValueTransformer
            reversibleTransformerWithForwardBlock:^ id (NSArray *nodes) {
                if (nodes == nil || nodes.count == 0) return nil;
                NSAssert([nodes[0] isKindOfClass:DDXMLNode.class], @"Expected a DDXMLNode, got: %@", nodes[0]);
                return [MTLXMLAdapter modelOfClass:modelClass fromXMLNode:nodes[0] error:NULL];
            }
            reverseBlock:^ id (MTLModel<MTLXMLSerializing> *model) {
                if (model == nil) return nil;
                
                NSAssert([model isKindOfClass:MTLModel.class], @"Expected a MTLModel object, got %@", model);
                NSAssert([model conformsToProtocol:@protocol(MTLXMLSerializing)], @"Expected a model object conforming to <MTLXMLSerializing>, got %@", model);
                
                return @[ [MTLXMLAdapter XMLElementFromModel:model] ];
            }];
}

+ (NSValueTransformer *)mtl_XMLArrayTransformerWithModelClass:(Class)modelClass {
	NSValueTransformer *xmlTransformer = [self mtl_XMLTransformerWithModelClass:modelClass];
    
	return [MTLValueTransformer
            reversibleTransformerWithForwardBlock:^ id (NSArray *nodes) {
                if (nodes == nil) return nil;
                NSMutableArray *models = [NSMutableArray arrayWithCapacity:nodes.count];
                for (DDXMLNode *child in nodes) {
                    if ([child isKindOfClass:[DDXMLElement class]]) {
                        id model = [xmlTransformer transformedValue:@[child] ];
                        if (model == nil) continue;
                        [models addObject:model];
                    }
                }
                
                return models;
            }
            reverseBlock:^ id (NSArray *models) {
                if (models == nil) return nil;
                
                NSAssert([models isKindOfClass:NSArray.class], @"Expected a array of MTLModels, got: %@", models);
                
                NSMutableArray *xmlNodes = [NSMutableArray arrayWithCapacity:models.count];
                for (MTLModel *model in models) {
                    DDXMLNode *node = [xmlTransformer reverseTransformedValue:model];
                    if (node == nil) continue;
                    
                    [xmlNodes addObject:node];
                }
                
                return xmlNodes;
            }
            ];
}

+ (NSValueTransformer *)mtl_XMLNonUniformObjectArrayTransformerWithModelClass:(Class)modelClass {
    
	return [MTLValueTransformer
            reversibleTransformerWithForwardBlock:^ id (NSArray *nodes) {
                if (nodes == nil || nodes.count == 0) return nil;
                
                NSMutableArray *models = [NSMutableArray arrayWithCapacity:nodes.count];
                for (DDXMLNode *child in nodes) {
                    
                    Class classForNode = [modelClass classForParsingXML:child];
                    NSValueTransformer *xmlTransformer = [self mtl_XMLTransformerWithModelClass:classForNode];
                    id model = [xmlTransformer transformedValue:@[child]];
                    if (model == nil) continue;
                    [models addObject:model];
                }
                
                return models;
            }
            reverseBlock:^ id (NSArray *models) {
                if (models == nil) return nil;
                
                NSAssert([models isKindOfClass:NSArray.class], @"Expected a array of MTLModels, got: %@", models);
                
                NSMutableArray *xmlNodes = [NSMutableArray arrayWithCapacity:models.count];
                for (MTLModel *model in models) {
                    NSValueTransformer *xmlTransformer = [self mtl_XMLTransformerWithModelClass:[model class]];
                    DDXMLNode *node = [xmlTransformer reverseTransformedValue:model];
                    if (node == nil) continue;
                    
                    [xmlNodes addObject:node];
                }
                
                return xmlNodes;
            }
            ];
}

@end
