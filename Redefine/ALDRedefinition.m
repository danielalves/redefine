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

#pragma mark - ALDRedefinition Class Extension

@interface ALDRedefinition()
{
    IMP redefinedImplementation;
    IMP originalImplementation;
}

@property( nonatomic, readonly )Class targetClass;
@property( nonatomic, readonly )SEL targetSelector;
@property( nonatomic, readonly )BOOL redefiningMetaClass;
@property( nonatomic, readwrite )BOOL usingRedefinition;

@end

#pragma mark - ALDRedefinition Implementation

@implementation ALDRedefinition

#pragma mark - Ctors & Dtor

+( instancetype )redefineClass:( Class )aClass selector:( SEL )selector withImplementation:( id )newImplementationBlock
{
    return [self redefineClass: aClass
                      selector: selector
 withPolymorphicImplementation: ^id( SEL selectorBeingRedefined, IMP originalImplementation ){ return newImplementationBlock; }];
}

+( instancetype )redefineClass:( Class )aClass selector:( SEL )selector withPolymorphicImplementation:( ALDRedefinitionPolymorphicBlock )newPolymorphicImplementationBlock;
{
    ALDRedefinition *temp =  [[ALDRedefinition alloc] initWithClass: aClass
                                         selector: selector
                     newPolymorphicImplementation: newPolymorphicImplementationBlock
                                  isClassSelector: YES];
    return temp;
}

+( instancetype )redefineClassInstances:( Class )aClass selector:( SEL )selector withImplementation:( id )newImplementationBlock
{
    return [self redefineClassInstances: aClass
                               selector: selector
          withPolymorphicImplementation: ^id( SEL selectorBeingRedefined, IMP originalImplementation ){ return newImplementationBlock; }];
}


+( instancetype )redefineClassInstances:( Class )aClass selector:( SEL )selector withPolymorphicImplementation:( ALDRedefinitionPolymorphicBlock )newPolymorphicImplementationBlock;
{
    ALDRedefinition *temp = [[ALDRedefinition alloc] initWithClass: aClass
                                         selector: selector
                     newPolymorphicImplementation: newPolymorphicImplementationBlock
                                  isClassSelector: NO];
    return temp;
}

-( instancetype )initWithClass:( Class )aClass
                      selector:( SEL )selector
  newPolymorphicImplementation:( ALDRedefinitionPolymorphicBlock )newPolymorphicImplementationBlock
               isClassSelector:( BOOL )isClassSelector
{
    if( !aClass || !selector || !newPolymorphicImplementationBlock )
        [NSException raise: NSInvalidArgumentException
                    format: @"All parameters must not be nil"];

    self = [super init];
    if( self )
    {
        _targetSelector = selector;
        _redefiningMetaClass = isClassSelector;

        Method currentMethod = NULL;
        if( isClassSelector )
        {
            _targetClass = objc_getMetaClass( class_getName( aClass ));
            currentMethod = class_getClassMethod( _targetClass, selector );

            if( !currentMethod )
                [NSException raise: NSInvalidArgumentException
                            format: @"%s does not respond to %s", class_getName( _targetClass ), sel_getName( selector )];
        }
        else
        {
            _targetClass = aClass;
            currentMethod = class_getInstanceMethod( _targetClass, selector );

            if( !currentMethod )
                [NSException raise: NSInvalidArgumentException
                            format: @"%s instances do not respond to %s", class_getName( _targetClass ), sel_getName( selector )];
        }

        IMP currentImplementation = method_getImplementation( currentMethod );
        id newImplementationBlock = newPolymorphicImplementationBlock( selector, currentImplementation );
        if( !newImplementationBlock )
            [NSException raise: NSInvalidArgumentException
                        format: @"New implementation must not be nil"];


        redefinedImplementation = imp_implementationWithBlock( newImplementationBlock );

        [self startUsingRedefinition];
    }
    return self;
}

-( void )dealloc
{
    [self stopUsingRedefinition];

    if( redefinedImplementation )
    {
        imp_removeBlock( redefinedImplementation );
        redefinedImplementation = nil;
    }
}

#pragma mark - Redefinition Object Management

-( void )startUsingRedefinition
{
    @synchronized( self.class )
    {
        if( !_usingRedefinition )
        {
            [ALDRedefinition stopPreviousRedefinitionWithSameTargetAndRegisterRedefinition: self];

            originalImplementation = class_replaceMethod( _targetClass, _targetSelector, redefinedImplementation, NULL );

            self.usingRedefinition = YES;
        }
    }
}

-( void )stopUsingRedefinition
{
    @synchronized( self.class )
    {
        if( _usingRedefinition )
        {
            class_replaceMethod( _targetClass, _targetSelector, originalImplementation, NULL );
            self.usingRedefinition = NO;
        }
    }
}

#pragma mark - Global Redefinition Management

+( void )stopPreviousRedefinitionWithSameTargetAndRegisterRedefinition:( ALDRedefinition * )redefinition
{
    @synchronized( self )
    {
        ALDRedefinition *sameTargetRedefinition = [self currentRedefinitionForSelector: redefinition.targetSelector
                                                                               ofClass: redefinition.targetClass
                                                                       isClassSelector: redefinition.redefiningMetaClass];
        if( sameTargetRedefinition )
            [sameTargetRedefinition stopUsingRedefinition];

        NSString *key = [self keyFromSelector: redefinition.targetSelector
                                      ofClass: redefinition.targetClass
                              isClassSelector: redefinition.redefiningMetaClass];

        [[self currentRedefinitions] setObject: redefinition forKey: key];
    }
}

+( ALDRedefinition * )currentRedefinitionForSelector:( SEL )selector ofClass:( Class )aClass isClassSelector:( BOOL )isClassSelector
{
    @synchronized( self )
    {
        NSString *key = [self keyFromSelector: selector ofClass: aClass isClassSelector: isClassSelector];
        return [[self currentRedefinitions] objectForKey: key];
    }
}

+( NSMapTable * )currentRedefinitions
{
    @synchronized( self )
    {
        static NSMapTable *currentRedefinitions = nil;

        // If we do not hold weak references to the redefinitions, they'll never be dealocated. Hence we would
        // never bring the original implementations back
        if( !currentRedefinitions )
            currentRedefinitions = [NSMapTable strongToWeakObjectsMapTable];

        return currentRedefinitions;
    }
}

#pragma mark - Helpers

+( NSString * )keyFromSelector:( SEL )selector ofClass:( Class )aClass isClassSelector:( BOOL )isClassSelector
{
    return [NSString stringWithFormat: @"%s_%s_%s", class_getName( aClass ),
            sel_getName( selector ),
            isClassSelector ? "CL" : "AI"];
}

@end
