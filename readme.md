
 BlitzMax language extensions
==============================

This is a selection of "language extensions" that implement what are normally language-level features, missing from BlitzMax, using runtime operations only. While not all of them are as slick as they would be in languages with dedicated syntax, they open up much wider possibilities for BlitzMax-based program design.

Included are:

 - Aspects ([aspect-oriented programming](https://en.wikipedia.org/wiki/Aspect-oriented_programming))
 - Interfaces ([protocol](https://en.wikipedia.org/wiki/Protocol_%28object-oriented_programming%29))
 - Lambdas ([anonymous functions](https://en.wikipedia.org/wiki/Anonymous_function))
 - Generators ([generator](https://en.wikipedia.org/wiki/Generator_%28computer_programming%29))
 - Coroutines and messages ([coroutine](https://en.wikipedia.org/wiki/Coroutine))
 - Value types ([stack allocation and flat vectors](https://en.wikipedia.org/wiki/Value_type))
 - Preprocessing ([C preprocessor](https://en.wikipedia.org/wiki/C_preprocessor))

Most of these involve medding with code generation. There's a lot of hand-written assembly, and the Aspect, Interface and Lambda modules all also do small amounts of JIT compilation to generate method stubs or proxy classes. So be warned, even though these are dynamic, they're still tightly integrated with the compiled language.

Those modules that do involve assembly/JIT are x86-32 only at this time.

Aspects and Interfaces are considered the "flagship" modules in this collection, as they go a long way towards fixing BlitzMax's problems with deep inheritance chains (the base language is very reliant on inheritance as the basis of polymorphism, which is something of an antipattern these days).

Coroutines and Messages are something of a special case: these *don't* involve any JIT or custom machine code, and are actually pure, high-level, portable BlitzMax modules. However, the coding style they enable is so thoroughly different from vanilla BlitzMax, that I prefer to view them as language rather than library features anyway.

Examples for most cases are provided, some more complete than others.

Possible future candidates for language extension include [array programming](https://en.wikipedia.org/wiki/Array_programming) (K/APL-style fast vectorized composable operations), and [region-based memory management](https://en.wikipedia.org/wiki/Region-based_memory_management) (a fast alternative to GC in some circumstances).

These extensions are dedicated to the public domain, by author Alex "Yasha" Gilding.

