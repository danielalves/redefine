1.1.0
-----

- Added the possibility to call original implementations from redefined implementations.
- Fixed test cases for 64 bit compilation.
- Fixed test cases redefinition blocks signatures.
- Moving from xctool to xcodebuild.

1.0.4 and 1.0.5
---------------

- Removed some unnecessary files.
- Fixed project configurations.
- Fixed some mixed branches issues.

1.0.3
-----

- Fixed new implementation blocks signatures: because of an Apple documentation issue, we were using the wrong block signature for implementation redefinitions. Now you can use blocks with any signature, so you can redefine any type of methods, not only those returning pointers =)

1.0.2
-----

- Setting a redefinition in place stops a previous redefition of the same target. Hence, it it possible to create multiple redefinitions of the same class/instance selector and use them at will.
- The property usingRedefinition has become KVO compliant, so it is possible to listen to the changes above.
- Starting and stoping to use a redefinition are now synchronized operations, what makes ALDRedefinition thread safe.

1.0.0
-----

- Fixing bugs and documentation issues

1.0.0
-----

- Initial version
