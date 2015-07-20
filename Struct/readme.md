
 Structs
=========

This language extension attempts to provide C-style "value types" in BlitzMax. Some hand-written assembly is used to work this into shape (and must be compiled separately with `gcc -m32 -c struct_alloca.S -o struct_alloca.o` before you begin).

it allows you to define "flat" data structures with the objects inlined after the fashion of C's structs. You can:

 - define an object type with struct members, by simply placing `{ Struct }` after the field declaration you want to inline (see `Foo` in the example; magic takes care of making the host object big enough)
 - create "flat" arrays whose objects are allocated in the same single block of memory
 - create "flat" vectors, which are slightly more cumbersome to index but may save some space (and are iterable)
 - allocate types and objects (not arrays) on a shadow stack (not *the* stack, but close enough), so they are automatically lost when a function returns
 - assign whole structures by value instead of by reference

The last one of these is not thread safe (it should still work in MT mode, but you can't use it from two threads at once. A clever person could probably fix this.)

You need to call `Struct.Initialize` before beginning. I would hide this in a global initializer somewhere, but those can't be counted on to run after all types are registered with the reflection system, so sadly it needs to be done manually. (Unless someone has a solution to this.) This is shown in the example.

You cannot / must not:

 - create recursive struct definitions (if a struct is inlined, it can't contain more of itself)
 - resize or slice flat arrays
 - assign to a struct slot (either a `{Struct}` field or a flat array element) using the `=` operator (you may update fields normally if appropriate, of course)
 - expect reflection to work (ha!)
 - cast flat arrays to a type other than `Object[]` (unless you use the dirty pointer cast hack seen a few times in `struct.bmx`) - you can cast their members up from `Object` though, so this is no problem in practice
 - let references escape (if you don't know why, or what this means, stay away from this until you've learned some C)

You can mark some plain-old-data types as `{ NoFinalize }` (capitalization of metadata is important) and then their finalizers won't run when the containing aggregate or vector is garbage collected, which is handy as it might speed things up. Only types marked `{NoFinalize}` may be "stack" allocated, because there's no way to run finalizers (or, there is, but it would be slow).

"Stack" allocation uses a second "shadow stack", because manipulating the main program stack is actually pretty much impossible due to unpredictable layouts. You actually need to call an empty `Alloca` (`ShadowStack.Alloca`) after some functions return in order to "GC" it, or memory leaks may ensue (this is because it only pops when it detects a lower call level - if you return, go up again, and call from the same level even though you returned in between, it won't have seen that happen).

Amusingly, this implementation is so awful that stack allocation is actually **measurably slower** than GC allocation. Still, the flat vectors might make sense from a memory usage perspective, who knows.

This extension is dedicated to the public domain, by author Alex "Yasha" Gilding.

