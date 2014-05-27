redefine
========

[![Cocoapods](https://cocoapod-badges.herokuapp.com/v/Redefine/badge.png)](http://cocoapods.org/?q=redefine)
[![Platform](http://cocoapod-badges.herokuapp.com/p/Redefine/badge.png)](http://cocoadocs.org/docsets/Redefine)
[![TravisCI](https://travis-ci.org/danielalves/redefine.svg?branch=master)](https://travis-ci.org/danielalves/redefine)

**Redefine** makes easier to overwrite methods implementations during runtime using the objc runtime. It also makes possible to switch back and forth through implementations, the original and the new one. ```ALDRedefinition``` uses the C++ concept of [RAII](http://en.wikibooks.org/wiki/C%2B%2B_Programming/RAII "RAII"), so the user just have to make sure to mantain a reference to the redefinition object for it to take place. When it is deallocated, everything goes back to normal.

The obvious use for it is unit tests. You don't have to prepare your code specifically for tests using factories, interfaces and etc, since it's possible to redefine any class or instance method. But, of course, you can do a lot of other crazy stuffs if you want to =D

**What is new in version 1.0.3**

Fixed new implementation blocks signatures: because of an Apple documentation issue, we were using the wrong block signature for implementation redefinitions. Now you can use blocks with any signature, so you can redefine any type of methods, not only those returning pointers =)

**What is new in version 1.0.2**

Setting a redefinition in place stops a previous redefition of the same target. Hence, it it possible to create multiple redefinitions of the same class/instance selector and use them at will. The property ```usingRedefinition``` has become KVO compliant, so it is possible to listen to these changes.

Starting and stoping to use a redefinition are now synchronized operations, what makes ```ALDRedefinition``` thread safe.

Installation
------------

**Redefine** is available through [CocoaPods](http://cocoapods.org), to install it simply add the following line to your Podfile:

```ruby
pod "Redefine"
```

Examples
--------

**1) Redefining a class method**

Let's say you want to test a behavior for a given signed user, which is managed by ```UserManager```:

```objc
-( void )test_Greetings
{
    [ALDRedefinition redefineClass: [UserManager class]
                          selector: @selector( currentUsername )
                withImplementation: ^id(id object, ...) {
                    return @"John Doe";
                }];
             
    XCTAssertEqualObjects( [UserManager greetings], @"Hello, John Doe!" )
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

You don't have to worry about setting the original implementation of ```currentUsername``` back, since it will be done automatically when ```ALDRedefinition``` is deallocated.

**2) Redefining an instance method**

Let's say you want to test a specific behavior that only happens when a value is set on your ```NSUserDefaults```:

```objc
-( void )test_When_Value_Is_Set_On_Standard_Defaults
{
    [ALDRedefinition redefineClassInstances: [NSUserDefaults class]
                                   selector: @selector( objectForKey: )
                         withImplementation: ^id(id object, ...) {
                             return @"Value";
                         }];
    
    NSString* valueIWantToTest = [[NSUserDefaults standardUserDefaults] objectForKey: kMyAwsomeKey];
    XCTAssertEqualObjects( valueIWantToTest, @"Value" );
}
```

As said before, you don't have to worry about setting the original implementation of ```objectForKey:``` back, since it will be done automatically when ```ALDRedefinition``` is deallocated.

The reason ```redefineClassInstances:selector:withImplementation:``` is plural is because all instances of ```NSUserDefaults``` class will have its ```objectForKey:``` redefined while the redefinition is in place.

**3) Beware of [class clusters](https://developer.apple.com/library/ios/documentation/general/conceptual/CocoaEncyclopedia/ClassClusters/ClassClusters.html "Class Cluster") like NSArray:**

The code below will not work because ```NSArray``` is a class cluster, so it returns other classes which override ```objectForIndex:``` method:

```objc
-( void )test_backward
{
    // testArray is not really a NSArray
    NSArray *testArray = @[ @1, @2, @3 ];

    // ERROR! THIS WILL NOT WORK AS EXPECTED!!!
    [ALDRedefinition redefineClassInstances: [NSArray class]
                                   selector: @selector( objectAtIndex: )
                         withImplementation:^id(id object, ...) {
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
    // testArray is not really a NSArray
    NSArray *testArray = @[ @1, @2, @3 ];

    // Ah-ha! Now everything is fine =)
    [ALDRedefinition redefineClassInstances: [testArray class]
                                   selector: @selector( objectAtIndex: )
                         withImplementation:^id(id object, ...) {
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
                                                     withImplementation:^id(id object, ...) {
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

**5) Multiple redefinitions with the same target**

Since version 1.0.2, you can set multiple redefinitions for the same target. The previous redefinition will be stopped. If you want listen to theses changes, the ```usingRedefinition``` property is now KVO compliant:

```objc
NSString *test = @"original value";

// Creates a redefinition for NSString description
ALDRedefinition *firstRedefinition = [ALDRedefinition redefineClassInstances: [NSString class]
                                                                    selector: @selector( description )
                                                          withImplementation:^id(id object, ...) {
                                                              return @"first";
                                                          }];

// First redefinition is in place                                                          
assert( [[test description] isEqualToString: @"first"] );

// Creates another redefinition for NSString description
ALDRedefinition *secondRedefinition = [ALDRedefinition redefineClassInstances: [NSString class]
                                                                     selector: @selector( description )
                                                           withImplementation:^id(id object, ...) {
                                                               return @"second";
                                                           }];

// Second redefinition is in place...
assert( [[test description] isEqualToString: @"second"] );

// ... And the first redefinition has been stopped!
assert( firstRedefinition.usingRedefinition == NO );

// When we set firstRedefinition back...
[firstRedefinition startUsingRedefinition];
    
// ... The second redefinition is out!
assert( secondRedefinition.usingRedefinition == NO );
    
// Stopping the current redefinition...    
[firstRedefinition stopUsingRedefinition];

// Brings the original implementation back    
assert( [[test description] isEqualToString: @"original value"] );
    
// Hence, no redefinition is in use
assert( firstRedefinition.usingRedefinition == NO );
assert( secondRedefinition.usingRedefinition == NO );
```

Author
------

- [Daniel L. Alves](http://github.com/danielalves) ([@alveslopesdan](https://twitter.com/alveslopesdan))

Collaborators
--------------

- [Gustavo Barbosa](http://github.com/barbosa) ([@gustavocsb](https://twitter.com/gustavocsb))
- [Flavia Missi](http://github.com/flaviamissi) ([@flaviamissi](https://twitter.com/flaviamissi))

License
-------

**Redefine** is available under the MIT license. See the LICENSE file for more info.
