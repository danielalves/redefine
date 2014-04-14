//
//  ALDRedefinition.h
//  Redefine
//
//  Created by Daniel L. Alves on 14/4/14.
//  Copyright (c) 2014 redefine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALDRedefinition : NSObject

/**
 *  @property Returns if the redefinition is in place
 */
@property( nonatomic, readonly )BOOL usingRedefinition;

/**
 *  Creates a redefinition for a class method and sets it in place. Thus, there is no need to call startUsingRedefinition after this method.
 *
 *  @param aClass            The class whose method we want to redefine
 *  @param selector          The class method we want to redefine
 *  @param newImplementation The new implementation of selector
 *
 *  @return An ALDSubstitute object that can control the selector redefinition
 */
+( instancetype )redefineClass:( Class )aClass selector:( SEL )selector withImplementation:(id(^)(id object, SEL selector, ...))newImplementation;

/**
 *  Creates a redefinition for a instance method of a class and sets it in place. Thus, there is no need to call startUsingRedefinition after this method.
 *
 *  @param aClass            The class whose instance method we want to redefine
 *  @param selector          The instance method we want to redefine
 *  @param newImplementation The new implementation of selector
 *
 *  @return An ALDSubstitute object that can control the selector redefinition
 */
+( instancetype )redefineClassInstances:( Class )aClass selector:( SEL )selector withImplementation:(id(^)(id object, SEL selector, ...))newImplementation;

/**
 *  Sets the redefinition represented by this object in place. That is, replaces the original implementation of the selector by the new implementation.
 */
-( void )startUsingRedefinition;

/**
 *  Stops the redefinition represented by this object. That is, takes the original selector implementation back.
 */
-( void )stopUsingRedefinition;

@end
