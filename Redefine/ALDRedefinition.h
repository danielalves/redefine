/**
 *  @header ALDRedefinition.h
 *  Declares Redefine's main class: ALDRedefinition
 *
 *  @author Created by Daniel L. Alves on 14/4/14.
 *  @copyright Copyright (c) 2014 Daniel L. Alves. All rights reserved.
 */

#import <Foundation/Foundation.h>

/**
 *  Describes a polymorphic reimplementation. That is, a new implementation that may call
 *  the original implementation of a method
 */
typedef id( ^ALDRedefinitionPolymorphicBlock )( SEL selectorBeingRedefined, IMP originalImplementation );

/**
 *  Represents a runtime method redefinition of a class or instance method. It also makes possible to switch back and forth
 *  through implementations, the original and the new one. ALDRedefinition uses the C++ concept of RAII, so the user just have
 *  to make sure to mantain a reference to the redefinition object for it to take place. When it is deallocated, everything
 *  goes back to normal.
 *
 *  Main features are:
 *
 *  - Swizzle class and instance methods
 *  - Create more than one redefinition for the same class/instance method
 *  - Start/stop a redefinition at will
 *  - Call original selector implementations from redefined implementations
 *  - Thread safety
 */
@interface ALDRedefinition : NSObject

/**
 *  Returns if the redefinition is in place.
 *
 *  Since version 1.0.2, this property is KVO compliant.
 *
 *  @see startUsingRedefinition
 *  @see stopUsingRedefinition
 */
@property( nonatomic, readonly )BOOL usingRedefinition;

/**
 *  Creates a redefinition for a class method and calls startUsingRedefinition to set it in place.
 *
 *  @param aClass                 The class whose method we want to redefine
 *
 *  @param selector               The class method we want to redefine
 *
 *  @param newImplementationBlock The new implementation of selector. Its signature should be:
 *                                method_return_type ^(id self, method_args...)
 *
 *  @return An ALDRedefinition object that can control the selector redefinition
 *
 *  @throws NSInvalidArgumentException If any argument is nil or if aClass does not respond to selector
 *
 *  @see startUsingRedefinition
 *  @see redefineClass:selector:withPolymorphicImplementation:
 *  @see redefineClassInstances:selector:withImplementation:
 *  @see redefineClassInstances:selector:withPolymorphicImplementation:
 */
+( instancetype )redefineClass:( Class )aClass selector:( SEL )selector withImplementation:( id )newImplementationBlock;

/**
 *  Creates a redefinition for a class method and calls startUsingRedefinition to set it in place.
 *
 *  @param aClass                            The class whose method we want to redefine
 *
 *  @param selector                          The class method we want to redefine
 *
 *  @param newPolymorphicImplementationBlock A block that must return another block that represents the new implementation of 
 *                                           selector. This way, it is possible to call the original implementation of selector
 *                                           inside the redefined implementation. The new implementation block signature should be:
 *                                           method_return_type ^(id self, method_args...)
 *
 *  @return An ALDRedefinition object that can control the selector redefinition
 *
 *  @throws NSInvalidArgumentException If any argument is nil, if aClass does not respond to selector or if newPolymorphicImplementationBlock
 *                                     returns nil
 *
 *  @see startUsingRedefinition
 *  @see redefineClass:selector:withImplementation:
 *  @see redefineClassInstances:selector:withImplementation:
 *  @see redefineClassInstances:selector:withPolymorphicImplementation:
 */
+( instancetype )redefineClass:( Class )aClass selector:( SEL )selector withPolymorphicImplementation:( ALDRedefinitionPolymorphicBlock )newPolymorphicImplementationBlock;

/**
 *  Creates an instance method redefinition for all instances of a class and calls startUsingRedefinition to set it in place.
 *
 *  @param aClass                 The class whose instance method we want to redefine
 *
 *  @param selector               The instance method we want to redefine
 *
 *  @param newImplementationBlock The new implementation of selector. Its signature should be:
 *                                method_return_type ^(id self, method_args...)
 *
 *  @return An ALDRedefinition object that can control the selector redefinition
 *
 *  @throws NSInvalidArgumentException If any argument is nil or if instances of aClass do not respond to selector
 *
 *  @see startUsingRedefinition
 *  @see redefineClass:selector:withImplementation:
 *  @see redefineClass:selector:withPolymorphicImplementation:
 *  @see redefineClassInstances:selector:withPolymorphicImplementation:
 */
+( instancetype )redefineClassInstances:( Class )aClass selector:( SEL )selector withImplementation:( id )newImplementationBlock;

/**
 *  Creates an instance method redefinition for all instances of a class and calls startUsingRedefinition to set it in place.
 *
 *  @param aClass                            The class whose instance method we want to redefine
 *
 *  @param selector                          The instance method we want to redefine

 *  @param newPolymorphicImplementationBlock A block that must return another block that represents the new implementation of
 *                                           selector. This way, it is possible to call the original implementation of selector
 *                                           inside the redefined implementation. The new implementation block signature should be:
 *                                           method_return_type ^(id self, method_args...)
 *
 *  @return An ALDRedefinition object that can control the selector redefinition
 *
 *  @throws NSInvalidArgumentException If any argument is nil, if instances of aClass do not respond to selector or if newPolymorphicImplementationBlock
 *                                     returns nil
 *
 *  @see startUsingRedefinition
 *  @see redefineClass:selector:withImplementation:
 *  @see redefineClass:selector:withPolymorphicImplementation:
 *  @see redefineClassInstances:selector:withImplementation:
 */
+( instancetype )redefineClassInstances:( Class )aClass selector:( SEL )selector withPolymorphicImplementation:( ALDRedefinitionPolymorphicBlock )newPolymorphicImplementationBlock;

/**
 *  Sets the redefinition represented by this object in place. That is, replaces the original implementation of the selector by the
 *  new implementation.
 *
 *  Since version 1.0.2, this method is synchronized and stops a previous redefinition on the same target.
 *
 *  @see stopUsingRedefinition
 *  @see usingRedefinition
 */
-( void )startUsingRedefinition;

/**
 *  Stops the redefinition represented by this object. That is, takes the original selector implementation back.
 *
 *  Since version 1.0.2, this method is synchronized.
 *
 *  @see startUsingRedefinition
 *  @see usingRedefinition
 */
-( void )stopUsingRedefinition;

@end
