//
//  ALDRedefinitionTests.m
//  Redefine
//
//  Created by Daniel Alves on 14/4/14.
//  Copyright (c) 2014 Daniel L. Alves. All rights reserved.
//

#import <XCTest/XCTest.h>

// Redefine
#import "ALDRedefinition.h"

// objc
#import <objc/runtime.h>

#pragma mark - Defines

#define SuppressUnusedVariableWarning_Init                  \
_Pragma("clang diagnostic push")                            \
_Pragma("clang diagnostic ignored \"-Wunused-variable\"")

#define SuppressUnusedVariableWarning_End                   \
_Pragma("clang diagnostic pop")

#define SuppressUnusedVariableWarning(commands)             \
do                                                          \
{                                                           \
SuppressUnusedVariableWarning_Init                          \
commands;                                                   \
SuppressUnusedVariableWarning_End                           \
} while(0)

#pragma mark - Conts

static NSString * const kUsingRedefinitionPropertyKeyPath = @"usingRedefinition";

#pragma mark - Globals

static NSUInteger kvoCounter = 0;
static NSString *kvoContext = nil;

#pragma mark - Class Declaration

@interface ALDRedefinitionTests : XCTestCase
{
    NSArray *testArray;
    NSBundle *originalMainBundle;
    NSBundle *mockedMainBundle;
}
@end

#pragma mark - Implementation

@implementation ALDRedefinitionTests

#pragma mark - XCTest Suite

-( void )setUp
{
    testArray = @[ @1, @2, @3 ];

    XCTAssertNotEqual( testArray.firstObject, testArray.lastObject );
    
    originalMainBundle = [NSBundle mainBundle];
    mockedMainBundle = [NSBundle bundleForClass: [self class]];
    XCTAssertNotEqual( originalMainBundle, mockedMainBundle );
}

#pragma mark - Class Selector Redefinitions Tests

-( void )test_Redefines_Zero_Argument_Class_Methods
{
    SuppressUnusedVariableWarning(
        // Compiling for 64 bits, the instance returned by the method below would
        // be deallocated just after its creation, that's why we MUST keep a reference to it.
        // On 32 bits it would be released after the method, so there would be no reason
        // for it
        ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                              selector: @selector( mainBundle )
                    withImplementation: ^id( id object, ... ) {
                        return mockedMainBundle;
                    }];

        XCTAssertEqual( [NSBundle mainBundle], mockedMainBundle );
    );
}

-( void )test_Redefines_Class_Methods_With_Arguments
{
    NSString *mockedResult = @"some/thing/string.txt";
    NSArray *components = @[ @"something", @"different", @"from_above.txt" ];

    SuppressUnusedVariableWarning(
        // Compiling for 64 bits, the instance returned by the method below would
        // be deallocated just after its creation, that's why we MUST keep a reference to it.
        // On 32 bits it would be released after the method, so there would be no reason
        // for it
        ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSString class]
                                                            selector: @selector( pathWithComponents: )
                                                  withImplementation: ^id( id object, ... ) {
                                                      return mockedResult;
                                                  }];

        XCTAssertNotEqualObjects( [NSString pathWithComponents: components], @"something/different/from_above.txt" );
        
        XCTAssertEqualObjects( [NSString pathWithComponents: components], mockedResult );
    );
}

-( void )test_Redefines_Class_Methods_Using_Original_Implementation
{
    NSString *mockedResult = @"some/thing/string.txt";
    NSArray *components = @[ @"something", @"different", @"from_above.txt" ];

    NSString *expected = [NSString stringWithFormat: @"%@%@", [NSString pathWithComponents: components], mockedResult];

    SuppressUnusedVariableWarning_Init
    {
        // Compiling for 64 bits, the instance returned by the method below would
        // be deallocated just after its creation, that's why we MUST keep a reference to it.
        // On 32 bits it would be released after the method, so there would be no reason
        // for it
        ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSString class]
                                                            selector: @selector( pathWithComponents: )
                                                  withPolymorphicImplementation: ^id( SEL selectorBeingRedefined, IMP originalImplementation ) {

                                                      return ^id( id object, ... ) {
                                                          va_list args;
                                                          va_start( args, object );
                                                          NSArray *components = va_arg( args, NSArray * );
                                                          va_end( args );

                                                          NSString *original = originalImplementation( object, selectorBeingRedefined, components );
                                                          return [NSString stringWithFormat: @"%@%@", original, mockedResult];
                                                      };
                                                  }];

        XCTAssertNotEqualObjects( [NSString pathWithComponents: components], @"something/different/from_above.txt" );

        XCTAssertEqualObjects( [NSString pathWithComponents: components], expected );
    }
    SuppressUnusedVariableWarning_End
}

-( void )test_redefineClass_Multiple_Redefinitions_With_Same_Target_Keep_Consistency_Between_All_Redefinitions
{
    NSString *originalValue = @"original value";
    
    ALDRedefinition *firstRedefinition = [ALDRedefinition redefineClass: [NSString class]
                                                               selector: @selector( stringWithString: )
                                                     withImplementation: ^id( id object, ... ) {
                                                         return @"first";
                                                     }];
    
    NSString *temp = [NSString stringWithString: originalValue];
    XCTAssertEqualObjects( temp, @"first" );
    
    ALDRedefinition *secondRedefinition = [ALDRedefinition redefineClass: [NSString class]
                                                                selector: @selector( stringWithString: )
                                                      withImplementation: ^id( id object, ... ) {
                                                          return @"second";
                                                      }];
    
    temp = [NSString stringWithString: originalValue];
    XCTAssertEqualObjects( temp, @"second" );
    XCTAssertFalse( firstRedefinition.usingRedefinition );
    
    [firstRedefinition startUsingRedefinition];
    
    temp = [NSString stringWithString: originalValue];
    XCTAssertEqualObjects( temp, @"first" );
    XCTAssertFalse( secondRedefinition.usingRedefinition );
    
    [firstRedefinition stopUsingRedefinition];
    
    temp = [NSString stringWithString: originalValue];
    XCTAssertEqualObjects( temp, @"original value" );
    
    XCTAssertFalse( firstRedefinition.usingRedefinition );
    XCTAssertFalse( secondRedefinition.usingRedefinition );
}

-( void )test_redefineClass_Throws_NSInvalidArgumentException_On_Nil_Class
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClass: nil
                                                        selector: @selector( mainBundle )
                                              withImplementation: ^id( id object, ... ) {
                                                  return mockedMainBundle;
                                              }],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_redefineClass_Throws_NSInvalidArgumentException_On_Nil_Selector
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClass: [NSBundle class]
                                                        selector: nil
                                              withImplementation: ^id( id object, ... ) {
                                                  return mockedMainBundle;
                                              }],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_redefineClass_Throws_NSInvalidArgumentException_On_Nil_Implementation
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClass: [NSBundle class]
                                                        selector: @selector( mainBundle )
                                              withImplementation: nil],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_redefineClass_Throws_NSInvalidArgumentException_On_Invalid_Selector
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClass: [NSBundle class]
                                                        selector: @selector( lowercaseString /* Any non-NSBundle method */ )
                                              withImplementation: ^id( id object, ... ) {
                                                  return mockedMainBundle;
                                              }],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_Undo_Class_Method_Redefines_On_Dealloc
{
    @autoreleasepool
    {
        SuppressUnusedVariableWarning(
            // Compiling for 64 bits, the instance returned by the method below would
            // be deallocated just after its creation, that's why we MUST keep a reference to it.
            // On 32 bits it would be released after the method, so there would be no reason
            // for it
            ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                                                                  selector: @selector( mainBundle )
                                                        withImplementation: ^id( id object, ... ) {
                                                            return mockedMainBundle;
                                                        }];
        );
    }
    
    XCTAssertEqual( [NSBundle mainBundle], originalMainBundle );
}

-( void )test_Undo_Class_Method_Redefines_On_stopUsingRedefinition
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                                                          selector: @selector( mainBundle )
                                                withImplementation: ^id( id object, ... ) {
                                                    return mockedMainBundle;
                                                }];
    
    [redefinition stopUsingRedefinition];
    
    XCTAssertEqual( [NSBundle mainBundle], originalMainBundle );
}

-( void )test_Redo_Class_Method_Redefines_On_startUsingRedefinition_After_stopUsingRedefinition
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                                                          selector: @selector( mainBundle )
                                                withImplementation: ^id( id object, ... ) {
                                                    return mockedMainBundle;
                                                }];
    
    [redefinition stopUsingRedefinition];
    [redefinition startUsingRedefinition];
    
    XCTAssertEqual( [NSBundle mainBundle], mockedMainBundle );
}

-( void )test_startUsingRedefinition_For_Class_Does_Not_Affect_Current_Redefinition
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                                                          selector: @selector( mainBundle )
                                                withImplementation: ^id( id object, ... ) {
                                                    return mockedMainBundle;
                                                }];
    [redefinition startUsingRedefinition];
    
    XCTAssertEqual( [NSBundle mainBundle], mockedMainBundle );
}

-( void )test_Double_stopUsingRedefinition_For_Class_Has_No_Side_Effects
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                                                          selector: @selector( mainBundle )
                                                withImplementation: ^id( id object, ... ) {
                                                    return mockedMainBundle;
                                                }];
    [redefinition stopUsingRedefinition];
    [redefinition stopUsingRedefinition];
    
    XCTAssertEqual( [NSBundle mainBundle], originalMainBundle );
}

-( void )test_Redefinition_For_Class_usingRedefinition_Property_Is_Working
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                                                          selector: @selector( mainBundle )
                                                withImplementation: ^id( id object, ... ) {
                                                    return mockedMainBundle;
                                                }];
    XCTAssertTrue( redefinition.usingRedefinition );
    
    [redefinition stopUsingRedefinition];
    
    XCTAssertFalse( redefinition.usingRedefinition );
    
    [redefinition startUsingRedefinition];
    
    XCTAssertTrue( redefinition.usingRedefinition );
}

-( void )test_redefineClass_Supports_KVO_On_usingRedefinition_Property
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                                                          selector: @selector( mainBundle )
                                                withImplementation: ^id( id object, ... ) {
                                                    return mockedMainBundle;
                                                }];
    
    kvoContext = [NSString stringWithUTF8String: __PRETTY_FUNCTION__];
    
    @try
    {
        [redefinition addObserver: self
                       forKeyPath: kUsingRedefinitionPropertyKeyPath
                          options: NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                          context: ( void * )kvoContext];
        
        kvoCounter = 0;
        
        [redefinition stopUsingRedefinition];
        
        XCTAssertEqual( kvoCounter, 1 );
        
        [redefinition startUsingRedefinition];
        
        XCTAssertEqual( kvoCounter, 2 );
    }
    @finally
    {
        [redefinition removeObserver: self forKeyPath: kUsingRedefinitionPropertyKeyPath context: ( void * )kvoContext];
    }
}

#pragma mark - Class Instance Selector Redefinitions Tests

-( void )test_Redefines_Zero_Arguments_Class_Instances_Methods
{
    SuppressUnusedVariableWarning(
        // Compiling for 64 bits, the instance returned by the method below would
        // be deallocated just after its creation, that's why we MUST keep a reference to it.
        // On 32 bits it would be released after the method, so there would be no reason
        // for it
        ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                     selector: @selector( firstObject )
                                                           withImplementation: ^id( id object, ... ) {
                                                               return testArray.lastObject;
                                                           }];

        XCTAssertEqual( testArray.firstObject, testArray.lastObject );

    );
}

-( void )test_Redefines_Class_Instances_Methods_With_Arguments
{
    SuppressUnusedVariableWarning(
        // Compiling for 64 bits, the instance returned by the method below would
        // be deallocated just after its creation, that's why we MUST keep a reference to it.
        // On 32 bits it would be released after the method, so there would be no reason
        // for it
        ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [testArray class]
                                                                     selector: @selector( objectAtIndex: )
                                                           withImplementation: ^id( id object, ... ) {
                                                               return @"Mock";
                                                           }];

        for( NSUInteger i = 0 ; i < testArray.count ; i++ )
            XCTAssertEqualObjects( @"Mock", [testArray objectAtIndex: i] );

    );
}


-( void )test_Redefines_Class_Instances_Methods_Using_Original_Implementation
{
    SuppressUnusedVariableWarning_Init
    {
        // Compiling for 64 bits, the instance returned by the method below would
        // be deallocated just after its creation, that's why we MUST keep a reference to it.
        // On 32 bits it would be released after the method, so there would be no reason
        // for it
        ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [testArray class]
                                                                       selector: @selector( objectAtIndex: )
                                                  withPolymorphicImplementation: ^id( SEL selectorBeingRedefined, IMP originalImplementation ) {

                                             return ^id( id object, ... ) {
                                                 va_list args;
                                                 va_start( args, object );
                                                 NSUInteger index = va_arg( args, NSUInteger );
                                                 va_end( args );

                                                 id original = originalImplementation( object, selectorBeingRedefined, index );
                                                 return [NSString stringWithFormat: @"Mock%@", original];
                                             };
                                         }];

        for( NSUInteger i = 0 ; i < testArray.count ; i++ )
        {
            NSString *expected = [NSString stringWithFormat: @"Mock%@", @(i+1)];
            XCTAssertEqualObjects( expected, [[testArray objectAtIndex: i] description] );
        }
    }
    SuppressUnusedVariableWarning_End
}

-( void )test_redefineClassInstances_Multiple_Redefinitions_With_Same_Target_Keep_Consistency_Between_All_Redefinitions
{
    NSString *test = @"original value";
    
    ALDRedefinition *firstRedefinition = [ALDRedefinition redefineClassInstances: [NSString class]
                                                                        selector: @selector( description )
                                                              withImplementation: ^id( id object, ... ) {
                                                                  return @"first";
                                                              }];
    
    XCTAssertEqualObjects( [test description], @"first" );
    
    ALDRedefinition *secondRedefinition = [ALDRedefinition redefineClassInstances: [NSString class]
                                                                         selector: @selector( description )
                                                               withImplementation: ^id( id object, ... ) {
                                                                   return @"second";
                                                               }];
    
    XCTAssertEqualObjects( [test description], @"second" );
    XCTAssertFalse( firstRedefinition.usingRedefinition );
    
    [firstRedefinition startUsingRedefinition];
    
    XCTAssertEqualObjects( [test description], @"first" );
    XCTAssertFalse( secondRedefinition.usingRedefinition );
    
    [firstRedefinition stopUsingRedefinition];
    
    XCTAssertEqualObjects( [test description], @"original value" );
    
    XCTAssertFalse( firstRedefinition.usingRedefinition );
    XCTAssertFalse( secondRedefinition.usingRedefinition );
}

-( void )test_redefineClassInstances_Throws_NSInvalidArgumentException_On_Nil_Class
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClassInstances: nil
                                                                 selector: @selector( firstObject )
                                                       withImplementation: ^id( id object, ... ) {
                                                           return testArray.lastObject;
                                                       }],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_redefineClassInstances_Throws_NSInvalidArgumentException_On_Nil_Selector
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                 selector: nil
                                                       withImplementation: ^id( id object, ... ) {
                                                           return testArray.lastObject;
                                                       }],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_redefineClassInstances_Throws_NSInvalidArgumentException_On_Nil_Implementation
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                 selector: @selector( firstObject )
                                                       withImplementation: nil],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_redefineClassInstances_Throws_NSInvalidArgumentException_On_Invalid_Selector
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                 selector: @selector( lowercaseString /* Any non-NSArray instance method */ )
                                                       withImplementation: ^id( id object, ... ) {
                                                           return testArray.lastObject;
                                                       }],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_Undo_Class_Instance_Method_Redefines_On_Dealloc
{
    @autoreleasepool
    {
        SuppressUnusedVariableWarning(
            // Compiling for 64 bits, the instance returned by the method below would
            // be deallocated just after its creation, that's why we MUST keep a reference to it.
            // On 32 bits it would be released after the method, so there would be no reason
            // for it
            ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                         selector: @selector( firstObject )
                                                               withImplementation: ^id( id object, ... ) {
                                                                   return testArray.lastObject;
                                                               }];
        );
    }
    
    XCTAssertNotEqual( testArray.firstObject, testArray.lastObject );
}

-( void )test_Undo_Class_Instance_Method_Redefines_On_stopUsingRedefinition
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                   selector: @selector( firstObject )
                                                         withImplementation: ^id( id object, ... ) {
                                                             return testArray.lastObject;
                                                         }];
    
    [redefinition stopUsingRedefinition];
    
    XCTAssertNotEqual( testArray.firstObject, testArray.lastObject );
}

-( void )test_Redo_Class_Instance_Method_Redefines_On_startUsingRedefinition_After_stopUsingRedefinition
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                   selector: @selector( firstObject )
                                                         withImplementation: ^id( id object, ... ) {
                                                             return testArray.lastObject;
                                                         }];
    
    [redefinition stopUsingRedefinition];
    [redefinition startUsingRedefinition];
    
    XCTAssertEqual( testArray.firstObject, testArray.lastObject );
}

-( void )test_startUsingRedefinition_For_Class_Instance_Does_Not_Affect_Current_Redefinition
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                   selector: @selector( firstObject )
                                                         withImplementation: ^id( id object, ... ) {
                                                             return testArray.lastObject;
                                                         }];
    
    [redefinition startUsingRedefinition];
    
    XCTAssertEqual( testArray.firstObject, testArray.lastObject );
}

-( void )test_Double_stopUsingRedefinition_For_Class_Instance_Has_No_Side_Effects
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                   selector: @selector( firstObject )
                                                         withImplementation: ^id( id object, ... ) {
                                                             return testArray.lastObject;
                                                         }];
    
    [redefinition stopUsingRedefinition];
    [redefinition stopUsingRedefinition];
    
    XCTAssertNotEqual( testArray.firstObject, testArray.lastObject );
}

-( void )test_Redefinition_For_Class_Instance_usingRedefinition_Property_Is_Working
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                   selector: @selector( firstObject )
                                                         withImplementation: ^id( id object, ... ) {
                                                             return testArray.lastObject;
                                                         }];
    XCTAssertTrue( redefinition.usingRedefinition );
    
    [redefinition stopUsingRedefinition];
    
    XCTAssertFalse( redefinition.usingRedefinition );
    
    [redefinition startUsingRedefinition];
    
    XCTAssertTrue( redefinition.usingRedefinition );
}

-( void )test_redefineClassInstances_Supports_KVO_On_usingRedefinition_Property
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                   selector: @selector( firstObject )
                                                         withImplementation: ^id( id object, ... ) {
                                                             return testArray.lastObject;
                                                         }];
    
    kvoContext = [NSString stringWithUTF8String: __PRETTY_FUNCTION__];

    @try
    {
        [redefinition addObserver: self
                       forKeyPath: kUsingRedefinitionPropertyKeyPath
                          options: NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                          context: ( void * )kvoContext];
        
        kvoCounter = 0;
        
        [redefinition stopUsingRedefinition];
        
        XCTAssertEqual( kvoCounter, 1 );
        
        [redefinition startUsingRedefinition];
        
        XCTAssertEqual( kvoCounter, 2 );
    }
    @finally
    {
        [redefinition removeObserver: self forKeyPath: kUsingRedefinitionPropertyKeyPath context: ( void * )kvoContext];
    }
}

#pragma mark - Helpers

-( void )observeValueForKeyPath:( NSString * )keyPath ofObject:( id )object change:( NSDictionary * )change context:( void * )context
{
    if( [keyPath isEqualToString: kUsingRedefinitionPropertyKeyPath]
        && [(( __bridge NSString * )context) isEqualToString: kvoContext] )
    {
        ++kvoCounter;
    }
}

@end
