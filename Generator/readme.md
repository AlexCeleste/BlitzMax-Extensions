
 Generators
============

This is a minimal implementation of generators for BlitzMax. The example should be fairly self-explanatory if you understand the concept from other languages (https://en.wikipedia.org/wiki/Generator_%28computer_programming%29).

A generator is implemented as the `Run` method of a type extending `TGenerator`. Within this method, you can use the `Yield` command instead of `Return`, to give the appearance of inverted control flow compared to a regular stream enumerator. You'll notice that TGenerator supports ObjectEnumerator and can be used as the stream source for `For` loops very easily.

Any other methods in the type are optional; implement constructor functions if thats convenient, or don't.

This extension depends on some hand-written assembly which must be compiled for your system with GCC before you can run it. Run `gcc -m32 -c generator.S` to build `generator.o` and you can then use the module.

This extension is dedicated to the public domain, by author Alex "Yasha" Gilding.

