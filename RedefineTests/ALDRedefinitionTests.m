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

#pragma mark - Class Selector Redefinitions

-( void )test_Redefines_Zero_Argument_Class_Methods
{
    [ALDRedefinition redefineClass: [NSBundle class]
                          selector: @selector( mainBundle )
                withImplementation:^id(id object, SEL selector, ...) {
                    return mockedMainBundle;
                }];
    
    XCTAssertEqual( [NSBundle mainBundle], mockedMainBundle );
}

-( void )test_Redefines_Class_Methods_With_Arguments
{
    NSString *mockedResult = @"some/thing/string.txt";
    
    [ALDRedefinition redefineClass: [NSString class]
                          selector: @selector( pathWithComponents: )
                withImplementation:^id(id object, SEL selector, ...) {
                    return mockedResult;
                }];
    
    NSArray *components = @[ @"something", @"different", @"from_above.txt" ];
    XCTAssertNotEqualObjects( [NSString pathWithComponents: components], @"something/different/from_above.txt" );
    
    XCTAssertEqualObjects( [NSString pathWithComponents: components], mockedResult );
}

-( void )test_redefineClass_Throws_NSInvalidArgumentException_On_Nil_Class
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClass: nil
                                                        selector: @selector( mainBundle )
                                              withImplementation:^id(id object, SEL selector, ...) {
                                                  return mockedMainBundle;
                                              }],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_redefineClass_Throws_NSInvalidArgumentException_On_Nil_Selector
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClass: [NSBundle class]
                                                        selector: nil
                                              withImplementation:^id(id object, SEL selector, ...) {
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
                                              withImplementation: ^id(id object, SEL selector, ...) {
                                                  return mockedMainBundle;
                                              }],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_Undo_Class_Method_Redefines_On_Dealloc
{
    @autoreleasepool
    {
        [ALDRedefinition redefineClass: [NSBundle class]
                              selector: @selector( mainBundle )
                    withImplementation:^id(id object, SEL selector, ...) {
                        return mockedMainBundle;
                    }];
    }
    
    XCTAssertEqual( [NSBundle mainBundle], originalMainBundle );
}

-( void )test_Undo_Class_Method_Redefines_On_stopUsingRedefinition
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                                                          selector: @selector( mainBundle )
                                                withImplementation:^id(id object, SEL selector, ...) {
                                                    return mockedMainBundle;
                                                }];
    
    [redefinition stopUsingRedefinition];
    
    XCTAssertEqual( [NSBundle mainBundle], originalMainBundle );
}

-( void )test_Redo_Class_Method_Redefines_On_startUsingRedefinition_After_stopUsingRedefinition
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                                                          selector: @selector( mainBundle )
                                                withImplementation:^id(id object, SEL selector, ...) {
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
                                                withImplementation:^id(id object, SEL selector, ...) {
                                                    return mockedMainBundle;
                                                }];
    [redefinition startUsingRedefinition];
    
    XCTAssertEqual( [NSBundle mainBundle], mockedMainBundle );
}

-( void )test_Double_stopUsingRedefinition_For_Class_Has_No_Side_Effects
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClass: [NSBundle class]
                                                          selector: @selector( mainBundle )
                                                withImplementation:^id(id object, SEL selector, ...) {
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
                                                withImplementation:^id(id object, SEL selector, ...) {
                                                    return mockedMainBundle;
                                                }];
    XCTAssertTrue( redefinition.usingRedefinition );
    
    [redefinition stopUsingRedefinition];
    
    XCTAssertFalse( redefinition.usingRedefinition );
    
    [redefinition startUsingRedefinition];
    
    XCTAssertTrue( redefinition.usingRedefinition );
}

#pragma mark - Class Instance Selector Redefinitions

-( void )test_Redefines_Zero_Arguments_Class_Instances_Methods
{
    [ALDRedefinition redefineClassInstances: [NSArray class]
                                   selector: @selector( firstObject )
                         withImplementation:^id(id object, SEL selector, ...) {
                             return testArray.lastObject;
                         }];
    
    XCTAssertEqual( testArray.firstObject, testArray.lastObject );
}

-( void )test_Redefines_Class_Instances_Methods_With_Arguments
{
    [ALDRedefinition redefineClassInstances: [testArray class]
                                   selector: @selector( objectAtIndex: )
                         withImplementation:^id(id object, SEL selector, ...) {
                             return @"Mock";
                         }];
    
    for( NSUInteger i = 0 ; i < testArray.count ; i++ )
        XCTAssertEqualObjects( @"Mock", [testArray objectAtIndex: i] );
}

-( void )test_redefineClassInstances_Throws_NSInvalidArgumentException_On_Nil_Class
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClassInstances: nil
                                                                 selector: @selector( firstObject )
                                                       withImplementation:^id(id object, SEL selector, ...) {
                                                           return testArray.lastObject;
                                                       }],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_redefineClassInstances_Throws_NSInvalidArgumentException_On_Nil_Selector
{
    XCTAssertThrowsSpecificNamed( [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                 selector: nil
                                                       withImplementation:^id(id object, SEL selector, ...) {
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
                                                       withImplementation: ^id(id object, SEL selector, ...) {
                                                           return testArray.lastObject;
                                                       }],
                                 NSException,
                                 NSInvalidArgumentException );
}

-( void )test_Undo_Class_Instance_Method_Redefines_On_Dealloc
{
    @autoreleasepool
    {
        [ALDRedefinition redefineClassInstances: [NSArray class]
                                       selector: @selector( firstObject )
                             withImplementation:^id(id object, SEL selector, ...) {
                                 return testArray.lastObject;
                             }];
    }
    
    XCTAssertNotEqual( testArray.firstObject, testArray.lastObject );
}

-( void )test_Undo_Class_Instance_Method_Redefines_On_stopUsingRedefinition
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                   selector: @selector( firstObject )
                                                         withImplementation:^id(id object, SEL selector, ...) {
                                                             return testArray.lastObject;
                                                         }];
    
    [redefinition stopUsingRedefinition];
    
    XCTAssertNotEqual( testArray.firstObject, testArray.lastObject );
}

-( void )test_Redo_Class_Instance_Method_Redefines_On_startUsingRedefinition_After_stopUsingRedefinition
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                   selector: @selector( firstObject )
                                                         withImplementation:^id(id object, SEL selector, ...) {
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
                                                         withImplementation:^id(id object, SEL selector, ...) {
                                                             return testArray.lastObject;
                                                         }];
    
    [redefinition startUsingRedefinition];
    
    XCTAssertEqual( testArray.firstObject, testArray.lastObject );
}

-( void )test_Double_stopUsingRedefinition_For_Class_Instance_Has_No_Side_Effects
{
    ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                                   selector: @selector( firstObject )
                                                         withImplementation:^id(id object, SEL selector, ...) {
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
                                                         withImplementation:^id(id object, SEL selector, ...) {
                                                             return testArray.lastObject;
                                                         }];
    XCTAssertTrue( redefinition.usingRedefinition );
    
    [redefinition stopUsingRedefinition];
    
    XCTAssertFalse( redefinition.usingRedefinition );
    
    [redefinition startUsingRedefinition];
    
    XCTAssertTrue( redefinition.usingRedefinition );
}

@end
