
 Interfaces
============

This is a language extension for BlitzMax that provides Java-style interfaces (also known as protocols). Interfaces allow classes with a common set of methods to be treated as sharing a single type, for horizontally-polymorphic behaviour that doesn't rely on inheritance trees.

The extension allows you to define an interface as a regular BlitzMax type extending TInterface, with a set of abstract methods for implementors to provide. Typechecking happens at runtime, but errors are signaled with runtime errors, to indicate that the problem is with the design.

The implementation uses a mini-JIT to generate method stubs or trampolines, to forward method calls against the interface proxy objects to the encapsulated base object.

Because the extension implements interfaces as actual instantiated proxy objects, be sure to use `Compare` instead of `=`, do not attempt to typecast between object and interface types (use the long-form constructor cast, or wrap it in a convenience function; to get objects out of interface types, use the `baseObject` field), and do not attempt to cast from one interface type to another (extract the base, then construct-cast it again to the new type). Do not reflect on the proxy object either. In general, if you avoid using interface instances as general `Object` values, you won't have many problems; go back to the base object when it needs to be generic.

There may be some issues with thread-safety in `TInterface.Interface`, but only if new class/interface combinations are still used past program start (they're added to a shared global map on first use, but after that, are only read from it).

Examples are included.

This extension is dedicated to the public domain, by author Alex "Yasha" Gilding.

