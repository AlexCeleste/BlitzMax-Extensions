
 Aspects
=========

This is a language extension for BlitzMax that provides some features of AspectJ-style aspect-oriented programming. Aspects allow you to centralize the definition of cross-cutting concerns that would otherwise tangle their implementation code into separately-defined classes, adding a "horizontal" dimension to code reuse, in addition to the "vertical" dimension provided by inheritance.

Aspects are pretty complicated, but extremely powerful. Getting used to this might take a while, but the payoff is worth it.

Since this is a dynamic (runtime) weaving implementation, the only available join points are method calls. This is plenty though.

Aspects are defined as types extending TAspect. The advice they provide is determined by their fields and methods, which are interpreted by AspectMax as pointcuts, advice, or extension methods.

Pointcuts are assigned to fields. Pointcuts may be defined to match against method names or containing type names. Matches may use a wildcard ending (`"AddTo*"` is a valid wildcard match, `"*ToVector"` is not; `"*"` is also valid, and is a universal match). Pointcut expressions may be `and`-ed and `or`-ed together with `All` and `Any` operations, e.g.

    Field p:Pointcut = Pointcut.Any(..
	                     Pointcut.All(Pointcut.TName("Foo"), Pointcut.MName("Bar*")), ..
						 Pointcut.All(Pointcut.MName("ToString"), Pointcut.TName("Vec*")))

matches any method in `Foo` beginning `Bar`, or `ToString` in any type beginning with `Vec`.

Advice is provided by defining methods with a distinct name pattern: `Advice_{Position}_{Pointcut}`, where `Position` is one of `Before`, `After`, or `Instead`, and `Pointcut` is the name of one of the fields containing a pointcut expression. The advice will be applied to target object's methods matching that pointcut. Multiple advice methods can apply to one pointcut and will stack.

Finally, extension methods are defined by assigning an ExtMethod object to an ExtMethod field. The ExtMethod object is initialized with the name of a dedicated container type holding the new method's definition. Once added, extension methods are available through reflection, and can also count towards an interface implementation if combined with the Interface extension (providing easy-access syntax).

An aspect can combine any or all of these elements in whatever combination is appropriate. Unused elements are ignored.

To actually apply aspects to types, the `TAspect.Weave` command must be called at least once, at the start of your program. It applies the list of aspects (on the right) to the list of types (on the left). The list of types may contain wildcards. Ignore the temptation to use `"*"` in the type list, unless you like total overkill (this will kick in *everywhere*, as BlitzMax uses a lot of objects in the runtime).

    TAspect.Weave(["Vector*", "Matrix*"], ["MulitplyAspect", "PrintExtension"])

Method extension and replacement is implemented by dynamic class generation: new classes (with new debug info) are allocated and populated with stub methods built by a mini-JIT, that handle dispatch between advice and original code.

`TAspect.Weave` itself is not thread-safe, but everything else should be. Since the weaver should only run at program start, this isn't considered a bug.

Examples are included.


Be aware that aspect-oriented programming is [patented in the US, by Xerox Corporation](http://www.google.com/patents/US6467086). This appears to be a [mostly-defensive patent](https://en.wikipedia.org/wiki/Defensive_patent_aggregation), as [AspectJ's licence](http://www.eclipse.org/legal/epl-v10.html) explicitly grants users "a non-exclusive, worldwide, royalty-free patent license" to users who do not themselves litigate against Xerox. There are [many other AOP implementations](https://en.wikipedia.org/wiki/Aspect-oriented_programming#Implementations) in the wild, as well as substantial prior art, and nobody has ever been sued over the patent. Use caution and good judgement, but I believe this is safe.


This extension is dedicated to the public domain, by author Alex "Yasha" Gilding.

