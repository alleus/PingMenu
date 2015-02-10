    //
//  MTLXMLAdapter.m
//  Mantle
//
//  Created by Matthew Baranowski on 6/5/13.
//  Copyright (c) 2013 Matthew Baranowski. All rights reserved.
//

#import "MTLXMLAdapter.h"
#import "MTLModel.h"
#import "MTLReflection.h"
#import "DDXMLNode.h"
#import "NSString+DDXML.h"
#import "MTLValueTransformer.h"

NSString * const MTLXMLAdapterErrorDomain = @"MTLXMLAdapterErrorDomain";
const NSInteger MTLXMLAdapterErrorNoClassFound = 2;

// An exception was thrown and caught.
static const NSInteger MTLXMLAdapterErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
static NSString * const MTLXMLAdapterThrownExceptionErrorKey = @"MTLXMLAdapterThrownException";

@interface MTLXMLAdapter ()

@property (nonatomic, strong, readonly) Class modelClass;
@property (nonatomic, copy, readonly) NSDictionary *XMLKeyPathsByPropertyKey;

@end


@implementation MTLXMLAdapter

+ (id)modelOfClass:(Class)modelClass fromXMLNode:(DDXMLNode *)xmlNode error:(NSError **)error
{
	MTLXMLAdapter *adapter = [[self alloc] initWithXMLNode:xmlNode modelClass:modelClass error:error];
	return adapter.model;
}

+ (DDXMLElement *)XMLElementFromModel:(MTLModel<MTLXMLSerializing> *)model
{
	MTLXMLAdapter *adapter = [[self alloc] initWithModel:model];
	return [adapter XMLElement];
}

- (id)initWithXMLNode:(DDXMLNode*)xmlNode modelClass:(Class)modelClass error:(NSError **)error
{
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass isSubclassOfClass:MTLModel.class]);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLXMLSerializing)]);
    
	if (xmlNode == nil) return nil;

	if ([modelClass respondsToSelector:@selector(classForParsingXML:)]) {
		modelClass = [modelClass classForParsingXML:xmlNode];
		if (modelClass == nil) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(@"Could not parse XML", @""),
                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No model class could be found to parse XML.", @"")
                               };
                
				*error = [NSError errorWithDomain:MTLXMLAdapterErrorDomain code:MTLXMLAdapterErrorNoClassFound userInfo:userInfo];
			}
            
			return nil;
		}
        
		NSAssert([modelClass isSubclassOfClass:MTLModel.class], @"Class %@ returned from +classForParsingXML: is not a subclass of MTLModel", modelClass);
		NSAssert([modelClass conformsToProtocol:@protocol(MTLXMLSerializing)], @"Class %@ returned from +classForParsingXML: does not conform to <MTLXMLSerializing>", modelClass);
	}
    
	self = [super init];
	if (self == nil) return nil;
    
	_modelClass = modelClass;
	_XMLKeyPathsByPropertyKey = [[modelClass XMLKeyPathsByPropertyKey] copy];

    NSSet* propertyKeys = [self.modelClass propertyKeys];
    
    // Verify that the root XPath exists.  If it does not then do not return an object.
    NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];

    NSString *rootPath = [[modelClass XPathPrefix] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    NSArray *nodes = [xmlNode nodesForXPath:rootPath error:error];
    
    if (nodes == nil || [nodes count] == 0)
    {
        // The root node doesn't exist return nil
        return nil;
    }

	for (NSString *propertyKey in [self.modelClass propertyKeys]) {
		NSString *keyPath = [self XMLKeyPathForKey:propertyKey];
		if (keyPath == nil) continue;
        keyPath = [[modelClass XPathPrefix] stringByAppendingString:keyPath];

		NSArray* nodes = [xmlNode nodesForXPath:keyPath error:error];
        if (nodes == nil || [nodes count] == 0) continue;
        

        
        @try {
            id value = nil;
            DDXMLNode* node = nodes[0];
            NSValueTransformer *transformer = [self XMLTransformerForKey:propertyKey];
            if (transformer != nil) {
                value = [transformer transformedValue:nodes] ?: NSNull.null;
            } else {
                value = [node stringValue];
            }
            
            dictionaryValue[propertyKey] = value;

        } @catch (NSException* ex) {
			NSLog(@"*** Caught exception %@ parsing XML key path \"%@\" from: %@", ex, keyPath, xmlNode);
            
			// Fail fast in Debug builds.
#if DEBUG
			@throw ex;
#else
			if (error != NULL) {
				NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: ex.description,
                               NSLocalizedFailureReasonErrorKey: ex.reason,
                               MTLXMLAdapterThrownExceptionErrorKey: ex
                               };
                
				*error = [NSError errorWithDomain:MTLXMLAdapterErrorDomain code:MTLXMLAdapterErrorExceptionThrown userInfo:userInfo];
			}
            
			return nil;
#endif

        }
    }
    
	_model = [self.modelClass modelWithDictionary:dictionaryValue error:error];
	if (_model == nil) return nil;
    
    return self;
}

- (id)initWithModel:(MTLModel<MTLXMLSerializing> *)model {
	NSParameterAssert(model != nil);
    
	self = [super init];
	if (self == nil) return nil;
    
	_model = model;
	_modelClass = model.class;
	_XMLKeyPathsByPropertyKey = [[model.class XMLKeyPathsByPropertyKey] copy];
    
	return self;
}

- (NSString *)XMLKeyPathForKey:(NSString *)key {
	NSParameterAssert(key != nil); 
    
	id keyPath = self.XMLKeyPathsByPropertyKey[key];
	if ([keyPath isEqual:NSNull.null]) return nil;
    
	if (keyPath == nil) {
		return key;
	} else {
		return keyPath;
	}
}

- (DDXMLElement *)XMLElement
{
    // completely abdicate responsibility and assume each model object serializes itself to proper html
	if ([self.model respondsToSelector:@selector(serializeToXMLElement)]) {
		return [self.model serializeToXMLElement];
    }
    
    return nil;
}


- (NSValueTransformer*)XMLTransformerForKey:(NSString*)key
{
	NSParameterAssert(key != nil);
    
	SEL selector = MTLSelectorWithKeyPattern(key, "XMLTransformer");
	if ([self.modelClass respondsToSelector:selector]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self.modelClass methodSignatureForSelector:selector]];
		invocation.target = self.modelClass;
		invocation.selector = selector;
		[invocation invoke];
        
		__unsafe_unretained id result = nil;
		[invocation getReturnValue:&result];
		return result;
	}
    
	if ([self.modelClass respondsToSelector:@selector(XMLTransformerForKey:)]) {
		return [self.modelClass XMLTransformerForKey:key];
	}
    
	return nil;
}
@end
