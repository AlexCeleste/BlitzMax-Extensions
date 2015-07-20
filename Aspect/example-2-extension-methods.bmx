
' AspectMax example 2: Extension methods

' adding a method to a type after declaration

Import "Aspect.bmx"
SuperStrict

' We'll use Vector2 again for this example
' Notice that we can add and subtract vectors, but we can't multiply them elementwise
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

' Let's change that.
' First implement the method on its own in a brand new type (Aspect will check!)
' Notice that Self in the extension method will hold the object when called on it - this
' is why it's important to use a brand new type, with no fields to distract you
Type VecExtension
	Method multiply_impl:Vector2(r:Vector2)
		Local res:Vector2 = New Vector2, myT:TTypeId = TTypeId.ForObject(Self)
		res.x = myT.FindField("x").GetFloat(Self) * r.x	'get the fields out of Self with reflection
		res.y = myT.FindField("y").GetFloat(Self) * r.y
		Return res
	End Method
End Type

' Now declare an aspect to apply the extension method to the original type
' Do this by declaring a field with the name you want the new method to have
' and assigning to it with ExtMethod.Make and the name of the extension method's
' container type. (The name you used to define the method isn't important, and is
' not used.)
Type VecAspect Extends TAspect
	Field Mul:ExtMethod = ExtMethod.Make("VecExtension")
End Type

' Activate the aspect with the aspect weaver command
TAspect.Weave(["Vector2"], ["VecAspect"])

Local v1:Vector2 = New Vector2, v2:Vector2 = New Vector2
v1.x = 6 ; v1.y = 8 ; v2.x = 5 ; v2.y = 9

' We can invoke the extension method with reflection just like all the native methods
Local vectype:TTypeId = TTypeId.ForObject(v1)
Local v3:Vector2 = Vector2(vectype.FindMethod("Mul").Invoke(v1, [v2]))

' ...and see that it worked:
Print "v3.x: " + v3.x + ", v3.y: " + v3.y
Print "v3.Length(): " + v3.Length()

' We can prove that it's there by inspecting all available methods of Vector2
' it comes up just as it should
Print "~nMethods of Vector2:"
For Local m:TMethod = EachIn vectype.Methods()
	Print "  " + m.Name()
Next

Print "~ndone."
End

