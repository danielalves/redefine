/**
 *  @header ALDRedefinition.h
 *  Declares Redefine's main class: ALDRedefinition
 *
 *  @author Created by Daniel L. Alves on 14/4/14.
 *  @copyright Copyright (c) 2014 Daniel L. Alves. All rights reserved.
 */

#import <Foundation/Foundation.h>

/**
 *  Represents a runtime method redefinition of a class or instance method. It also makes possible to switch back and forth
 *  through implementations, the original and the new one. ALDRedefinition uses the C++ concept of RAII, so the user just have
 *  to make sure to mantain a reference to the redefinition object for it to take place. When it is deallocated, everything
 *  goes back to normal.
 *
 *  <B> Since version 1.0.2 </B>
 *
 *  Setting a redefinition in place stops a previous redefition of the same target. Hence, it it possible to create multiple
 *  redefinitions of the same class/instance selector and use them at will.
 *
 *  Starting and stoping to use a redefinition are atomic operations, what makes ALDRedefinition thread safe.
 */
@interface ALDRedefinition : NSObject

/**
 *  Returns if the redefinition is in place
 *  @see startUsingRedefinition
 *  @see stopUsingRedefinition
 */
@property( nonatomic, readonly )BOOL usingRedefinition;

/**
 *  Creates a redefinition for a class method and sets it in place. Thus, there is no need to call startUsingRedefinition after this method.
 *
 *  @param aClass            The class whose method we want to redefine
 *  @param selector          The class method we want to redefine
 *  @param newImplementation The new implementation of selector
 *
 *  @return An ALDRedefinition object that can control the selector redefinition
 *
 *  @throws NSInvalidArgumentException If any argument is null or if aClass does not respond to selector
 *
 *  @see redefineClassInstances:selector:withImplementation:
 */
+( instancetype )redefineClass:( Class )aClass selector:( SEL )selector withImplementation:(id(^)(id object, SEL selector, ...))newImplementation;

/**
 *  Creates a redefinition for a instance method of a class and sets it in place. Thus, there is no need to call startUsingRedefinition after this method.
 *
 *  @param aClass            The class whose instance method we want to redefine
 *  @param selector          The instance method we want to redefine
 *  @param newImplementation The new implementation of selector
 *
 *  @return An ALDRedefinition object that can control the selector redefinition
 *
 *  @throws NSInvalidArgumentException If any argument is null or if instances of aClass do not respond to selector
 *
 *  @see redefineClass:selector:withImplementation:
 */
+( instancetype )redefineClassInstances:( Class )aClass selector:( SEL )selector withImplementation:(id(^)(id object, SEL selector, ...))newImplementation;

/**
 *  Sets the redefinition represented by this object in place. That is, replaces the original implementation of the selector by the new implementation.
 *
 *  @see stopUsingRedefinition
 *  @see usingRedefinition
 */
-( void )startUsingRedefinition;

/**
 *  Stops the redefinition represented by this object. That is, takes the original selector implementation back.
 *
 *  @see startUsingRedefinition
 *  @see usingRedefinition
 */
-( void )stopUsingRedefinition;

@end
