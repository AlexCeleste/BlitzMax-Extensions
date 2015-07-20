
 Coroutines and messages
=========================

This module (it's not really an extension) provides a wrapper around BlitzMax events and reflection in order to make message-based programming cleaner and easier.

The `EventManager` type allows individual objects to "subscribe" to events. This is an improvement over having to register global hook functions. Events are instead dispatched straight to the right method of the individual receiving object, keeping state non-global and automatically handling some event type dispatching.

The `CoroutineQueue` type allows objects to package themselves along with a method and some arguments, to be executed at a later stage (either at the next available opportunity, using `Yield`, or after a delay, using `YieldIn`). The coroutine queue runs a number of coroutines from its internal list until a time threshold is reached, before returning control so that the surrounding loop can stay responsive and do other things.

If a method schedules itself to run again, this effectively forms a loop. Because the loop is managed externally by the coroutine queue, which makes sure that other objects also get a turn to execute, and periodically returns control to the surrounding program, multiple objects can appear to be executing their code simultaneuosly, interleaving their operations. This makes coroutines in particular an excellent and safe alternative to multithreading for asynchronous operations.

An example is provided, which may be somewhat opaque due to having no obvious control flow. Keep studying it and running it and the way the different loops interleave should become clear.

This extension is dedicated to the public domain, by author Alex "Yasha" Gilding.

