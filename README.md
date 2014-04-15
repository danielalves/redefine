redefine
========

Redefine makes easier to overwrite methods implementations during runtime using the objc runtime. It also makes possible to switch back and forth through implementations, the original and the new one. It uses the C++ concept of [RAII](http://en.wikibooks.org/wiki/C%2B%2B_Programming/RAII "RAII"), so the user just have to make sure to mantain a reference to the redefinition object for it to take place. When it is deallocated, everything goes back to normal.

The obvious use for it is unit tests. You don't have to prepare your code specifically for tests using factories, interfaces and etc, since it's possible to redefine any class or instance method. But, of course, you can do a lot of crazy stuffs if you want to =D

Examples
--------

**1) Redefining a class method**

Let's say you want to test a behavior for a given signed user, which is managed by ```UserManager```:

```objc
-( void )test_Greetings
{
    [ALDRedefinition redefineClass: [UserManager class]
                          selector: @selector( currentUsername )
                withImplementation: ^id(id object, SEL selector, ...) {
                    return @"Jhon Doe";
                }];
             
    XCTAssertEqualObjects( [UserManager greetings], @"Hello, Jhon Doe!" )
}

// ...

@implementation UserManager 
// ...
+( NSString* )greetings
{
    return [NSString stringWithFormat: @"Hello, %@!", [self currentUsername]];
}
// ...
@end
```

You don't have to worry about setting the original implementation of ```currentUsername:``` back, since it will be done automatically when ```ALDRedefinition``` is deallocated.

**2) Redefining an instance method**

Let's say you want to test a specific behavior that only happens when a value is set on your ```NSUserDefaults```:

```objc
-( void )test_When_Value_Is_Set_On_Standard_Defaults
{
    [ALDRedefinition redefineClassInstances: [NSUserDefaults class]
                                   selector: @selector( objectForKey: )
                         withImplementation: ^id(id object, SEL selector, ...) {
                             return @"Value";
                         }];
    
    NSString* valueIWantToTest = [[NSUserDefaults standardUserDefaults] objectForKey: kMyAwsomeKey];
    XCTAssertEqualObjects( valueIWantToTest, @"Value" );
}
```

As said before, you don't have to worry about setting the original implementation of ```objectForKey:``` back, since it will be done automatically when ```ALDRedefinition``` is deallocated.

The reason ```redefineClassInstances:selector:withImplementation:``` is plural is because all instances of ```NSUserDefaults``` class will have its ```objectForKey:``` redefined while the redefinition is alive.

**3) Beware of [class clusters](https://developer.apple.com/library/ios/documentation/general/conceptual/CocoaEncyclopedia/ClassClusters/ClassClusters.html "Class Cluster") like NSArray:**

The code below will not work because NSArray is a class cluster, so it returns other classes which override ```objectForIndex:``` method:

```objc
-( void )test_backward
{
    NSArray *testArray = @[ @1, @2, @3 ];

    // ERROR! THIS WILL NOT WORK AS EXPECTED!!!
    [ALDRedefinition redefineClassInstances: [NSArray class]
                                   selector: @selector( objectAtIndex: )
                         withImplementation:^id(id object, SEL selector, ...) {
                             return @"Mock";
                         }];
    
    for( NSUInteger i = 0 ; i < testArray.count ; i++ )
        XCTAssertEqualObjects( @"Mock", [testArray objectAtIndex: i] );
}
```

For it to work, we would need to use ```testArray``` real class. So, the correct code is:

```objc
-( void )test_backward
{
    NSArray *testArray = @[ @1, @2, @3 ];

    // Ah-ha! Now everything is fine =)
    [ALDRedefinition redefineClassInstances: [testArray class]
                                   selector: @selector( objectAtIndex: )
                         withImplementation:^id(id object, SEL selector, ...) {
                             return @"Mock";
                         }];
    
    for( NSUInteger i = 0 ; i < testArray.count ; i++ )
        XCTAssertEqualObjects( @"Mock", [testArray objectAtIndex: i] );
}
```

**4) Stop and Restart using a redefinition at will and checking if a redefinition is in place**

Of course you don't need to deallocate a redefinition object to make it uneffective:

```objc
ALDRedefinition *redefinition = [ALDRedefinition redefineClassInstances: [NSArray class]
                                                               selector: @selector( firstObject )
                                                     withImplementation:^id(id object, SEL selector, ...) {
                                                         return testArray.lastObject;
                                                     }];
                                                     
// From now on, firstObject will return lastObject
// ...

// Let's bring the original implementation back
[redefinition stopUsingRedefinition];

// From now on, firstObject will return firstObject
// ...

// Nah, let's redefine it again
[redefinition startUsingRedefinition];

// ...

// Checks if a redefinition is in place
BOOL isRedefinitionInPlace = redefinition.usingRedefinition
```

License
-------

Redefine is available under the MIT license. See the LICENSE file for more info.
