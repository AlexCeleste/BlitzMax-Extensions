
' AspectMax example 1: join points and advice

' adding behaviour around methods

Import "Aspect.bmx"
SuperStrict

' The first thing we need is a simple class to do experiments on:
Type Vector2
	Field x:Float, y:Float
	
	Method Length:Float()
		Return Sqr(x * x + y * y)
	End Method
	Method Add:Vector2(r:Vector2)
		Local res:Vector2 = New Self
		res.x = x + r.x ; res.y = y + r.y
		Return res
	End Method
	Method Sub:Vector2(r:Vector2)
		Local res:Vector2 = New Self
		res.x = x - r.x ; res.y = y - r.y
		Return res
	End Method
End Type

' That's nice, but what if we want to insert a bunch of notification messages whenever someone
' touches our object? Or what if we decide it needs to check permissions before engaging an
' action? We need to be able to "advise" the class by adding extra behaviour, but don't want
' to complicate the definition with things that aren't really related to vectors.

' An Aspect lets us define such behaviours separately and attach them to the original type at
' its "join points" (method calls).
' Let's define an aspect to modify Vector2:
Type VecAspect Extends TAspect
	' First we need to define where the join points we want to hook onto are
	' A "pointcut" is a specification for one or more join points
	' Right now we'll specify method names. These just match 1:1 with the join points we want
	' Pointcuts are defined by assigning to fields of Pointcut type
	Field length:Pointcut = Pointcut.MName("Length")  'match calls to Length
	Field add:Pointcut = Pointcut.MName("Add"), sub:Pointcut = Pointcut.MName("Sub")  'match calls to Add and Sub
	
	' Now we have defined where advice can be given, we can actually define some advice to give
	' Advice is defined using methods with a particular naming scheme:
	'  "Advice_{Position}_{Pointcut}"
	' where {Position} is one of Before/After/Instead, and {Pointcut} is the name of one of the
	' pointcut fields we defined above
	
	' Let's start by putting a warning before all calls to Length, so that we can keep track of
	' this action in our logs
	Method Advice_Before_Length()
		Print "Preparing to retrieve length..."
	End Method
	' ...and a notification that we successfully got the length
	Method Advice_After_Length()
		Print "retrieved length!"
	End Method
	
	' Adding two vectors is a high-security operation. We'd better chyeck credentials before allowing
	' the object to try this!
	Method Advice_Before_Add(me:Vector2)  'all advice optionally has access to the original Self object via the first parameter
		Print "checking credentials before adding..."
		Assert me.x + me.y = me.y + me.x
		Print "...granted!"
	End Method
	
	' Subtracting two vectors is just inappropriate. We're not going to allow that
	Method Advice_Instead_Sub:Object()
		Print "sorry, subtracting vectors is currently unavailable, please try later"
		Return Null
	End Method
End Type

' At the start of our main program, we use one or more Weave commands to apply the aspects to our types
' Each of the aspects in the array on the right are applied to each of the types in the array on the left
' You can call Weave more than once with different combinations
' It's also possible to match more flexible patterns, which we'll see in a later example
' Right now we'll just apply one aspect to one type
TAspect.Weave(["Vector2"], ["VecAspect"])

Local v1:Vector2 = New Vector2, v2:Vector2 = New Vector2
v1.x = 6 ; v1.y = 8 ; v2.x = 5 ; v2.y = 9

' Let's see what happens when we call methods on Vector2 objects:

' Add runs a credential check
Local v3:Vector2 = v1.Add(v2)
' Length is surrounded by notifications
' notice how we were able to stack both advisements
Print "v3.Length(): " + v3.Length()
' Sub refuses to return a result
Local v4:Vector2 = v1.Sub(v2)
If v4 = Null Then Print "no result"

Print "~ndone."
End

