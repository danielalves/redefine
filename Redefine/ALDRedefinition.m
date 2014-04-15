//
//  ALDRedefinition.m
//  Redefine
//
//  Created by Daniel L. Alves on 14/4/14.
//  Copyright (c) 2014 Daniel L. Alves. All rights reserved.
//

#import "ALDRedefinition.h"

// objc
#import <objc/runtime.h>

#pragma mark - Class Extension

@interface ALDRedefinition()
{
    SEL targetSelector;
    Class targetClass;
    
    IMP redefinedImplementation;
    IMP originalImplementation;
    
    BOOL usingRedefinition;
}
@end

#pragma mark - Implementation

@implementation ALDRedefinition

#pragma mark - Accessors

-( BOOL )usingRedefinition
{
    return usingRedefinition;
}

#pragma mark - Ctors & Dtor

+( instancetype )redefineClass:( Class )aClass selector:( SEL )selector withImplementation:(id(^)(id object, SEL selector, ...))newImplementation
{
    return [[ALDRedefinition alloc] initWithClass: aClass
                                       selector: selector
                              newImplementation: newImplementation
                                isClassSelector: YES];
}

+( instancetype )redefineClassInstances:( Class )aClass selector:( SEL )selector withImplementation:(id(^)(id object, SEL selector, ...))newImplementation
{
    return [[ALDRedefinition alloc] initWithClass: aClass
                                       selector: selector
                              newImplementation: newImplementation
                                isClassSelector: NO];
}

-( instancetype )initWithClass:( Class )aClass
                      selector:( SEL )selector
             newImplementation:( id(^)(id object, SEL selector, ...) )newImplementation
               isClassSelector:( BOOL )isClassSelector
{
    if( aClass == nil || selector == nil || newImplementation == nil )
        [NSException raise: NSInvalidArgumentException
                    format: @"All parameters must not be nil"];
    
    self = [super init];
    if( self )
    {
        targetSelector = selector;
        
        if( isClassSelector )
        {
            targetClass = objc_getMetaClass(class_getName(aClass));
            
            if( !class_getClassMethod( targetClass, selector ))
                [NSException raise: NSInvalidArgumentException
                            format: @"%s does not respond to %s", class_getName(targetClass), sel_getName(selector)];
        }
        else
        {
            targetClass = aClass;
            
            if( !class_getInstanceMethod( targetClass, selector ))
                [NSException raise: NSInvalidArgumentException
                            format: @"%s instances do not respond to %s", class_getName(targetClass), sel_getName(selector)];
        }
        
        redefinedImplementation = imp_implementationWithBlock(newImplementation);
        
        [self startUsingRedefinition];
    }
    return self;
}

-( void )dealloc
{
    [self stopUsingRedefinition];
}

#pragma mark - Redefinition Management

-( void )startUsingRedefinition
{
    if( !usingRedefinition )
    {
        originalImplementation = class_replaceMethod( targetClass, targetSelector, redefinedImplementation, NULL );
        usingRedefinition = YES;
    }
}

-( void )stopUsingRedefinition
{
    if( usingRedefinition )
    {
        class_replaceMethod( targetClass, targetSelector, originalImplementation, NULL );
        usingRedefinition = NO;
    }
}

@end
