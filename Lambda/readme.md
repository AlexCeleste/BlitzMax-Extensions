
 Lambdas
=========

This is a rather ambitious extension for BlitzMax that hacks in lambdas: inline function expressions with the ability to form closures.

If you already know about lambdas, the examples should be self-explanatory. If not, this is likely not the place to learn.

Lambdas are created with a combination of two constructors: the various `FN_` functions in `TLambda` are used to declare the argument list, and the lambda is the completed by calling an `as` method, which defines the return type and provides a space for the lambda's body (as its argument).

The implementation works by extracting the code that BlitzMax ran in between the two invocations of the constructors and treating it as a new function body. Some hand-written assembly is used to work this into shape (and must be compiled separately with `gcc -m32 -c lambda.S -o lambda.o` before you begin).

Lambdas may form closures over BlitzMax locals: this works by copying the local and storing its value in the created `TLambda` instance.

Due to lack of compiler-level support, this is fairly limited in several ways. It isn't posisble to define a syntax for creating new variables, so arguments must be predeclared as locals (syntactic issue). The lambda body "runs" when the function is created, which may cause a problem if it has side effects. `TLambda` is an object, and doesn't use native call syntax (unless *reified*, see below). The different constructors required for different type are also a nuisance, as well as having to package all return values into a single result type (return values are extracted from the result object as fields).

Lambdas that do not form closures over local variables may be *reified*, extracting their machine code to treat it as a regular BlitzMax function. This is much more convenient syntax-wise and eliminates some of the argument/result type issues. However, this should be used sparingly, as it does still require allocation of memory (a new code block has to be JITted up to provide the function header/footer), despite not supporting closures.

`oldversion/` is an earlier, less refined version of the same concept. It is retained for historical value only and its use is not recommended. It is much less usable.

Examples of several usage patterns are provided. Be warned that this might not have been tested sufficiently for production usage.

This extension is dedicated to the public domain, by author Alex "Yasha" Gilding.

