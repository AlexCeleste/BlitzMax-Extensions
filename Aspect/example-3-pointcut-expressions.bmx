
' AspectMax example 3: Pointcut expressions

' more powerful join point matching

Import "Aspect.bmx"
SuperStrict

' Once again, our old friend Vector2
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

' We want to apply advice... but some of Vector2's methods are logically quite similar.
' We don't want to have to repeat ourselves for Add and Sub, given that they're both
' sum-type operations and have similar properties.
Type VecAspect Extends TAspect
	' ...so we define a more general pointcut that matches either Add or Sub join points,
	' by combining the basic pointcuts into a compound pointcut with "Any"
	Field sumops:Pointcut = Pointcut.Any(Pointcut.MName("Add"), Pointcut.MName("Sub"))
	
	' (The other available compound operation is "All". "Any" is an Or operation, "All"
	' is an And operation. And-ing two method names together wouldn't make sense, but
	' we'll see it used in the next example.)
	
	Method Advice_Before_Sumops()
		Print "preparing to compute a sum-type operation"
	End Method
End Type

TAspect.Weave(["Vector2"], ["VecAspect"])

' Create some objects...
Local v1:Vector2 = New Vector2, v2:Vector2 = New Vector2
v1.x = 6 ; v1.y = 8 ; v2.x = 5 ; v2.y = 9

' ...and we see that two completely different method join points have been advised,
' needing only a single piece of advice code in the aspect
Local v3:Vector2 = v1.Add(v2), v4:Vector2 = v1.Sub(v2)

Print "~ndone."
End