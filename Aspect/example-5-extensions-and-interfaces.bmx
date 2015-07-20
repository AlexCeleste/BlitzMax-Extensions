
' AspectMax example 5: extensions and interfaces

' combining extension methods with interfaces for naturalistic programming

Import "Aspect.bmx"
Import "../Interface/Interface.bmx"

SuperStrict

' Extension methods are all very well, but if Max isn't aware of them at compile-time,
' we can't use the dot-syntax, and that barely makes them worth the effort.
' Luckily, there's a second category of language feature that cuts horizontally "across"
' the class tree, and that's the "interface" extension! Interfaces allow completely
' unrelated types that rpesent the same methods to be used in the same way; extension
' methods allow you to add more methods to a class. So we can use interfaces to get a
' convenient syntax for using extension methods.

' You'll need the Interface BlitzMax extension (available separately) to try this example.

Type Vector2
	Field x:Float, y:Float
End Type

Type Vector3
	Field x:Float, y:Float, z:Float
End Type

' Define one length function
' (this is a bit of a bad example since Length really is two separate functions, as the
' mechanism is different for the two types of vector... but bear with it for the demonstration)
Type LengthExt
	Method Length:Float()
		Local myT:TTypeId = TTypeId.ForObject(Self)
		Local x:Float = myT.FindField("x").GetFloat(Self), y:Float = myT.FindField("y").GetFloat(Self)
		Local zf:TField = myT.FindField("z")
		If zf
			Local z:Float = zf.GetFloat(Self)
			Return Sqr(x * x + y * y + z * z)
		Else
			Return Sqr(x * x + y * y)
		EndIf
	End Method
End Type

' Apply it to both types
Type LengthExtAdvisor Extends TAspect
	Field Length:ExtMethod = ExtMethod.Make("LengthExt")
End Type
TAspect.Weave(["Vector*"], ["LengthExtAdvisor"])

Local v1:Vector2 = New Vector2, v2:Vector2 = New Vector2
v1.x = 6 ; v1.y = 8 ; v2.x = 5 ; v2.y = 9
Local v3:Vector3 = New Vector3, v4:Vector3 = New Vector3
v3.x = 6 ; v3.y = 8 ; v3.z = 10 ; v4.x = 5 ; v4.y = 9 ; v4.z = 13

' Now, we could use this via reflection, but it's not at all convenient:
Local vecs:Object[] = [Object(v1), Object(v2), Object(v3), Object(v4)]
Print "~nReflection (loop):"
For Local o:Object = EachIn vecs
	Local t:TTypeId = TTypeId.ForObject(o)
	Print "  length: " + String(t.FindMethod("Length").Invoke(o, Null)).ToFloat()
Next

' So let's define an interface that cleans it up a bit by providing a direct call
' to the Length method:
Type IVector Extends TInterface
	Method Length:Float() Abstract
	
	Function Cast:IVector(o:Object)
		Return IVector(TInterface.Interface(o, "IVector"))
	End Function
End Type

' Now we can pack all of our vector objects into a unified type and access Length directly:
Local ivecs:IVector[4]
Print "~nDirect (loop):"
For Local i:Int = 0 Until 4
	ivecs[i] = IVector.Make(vecs[i])
	Print "  length: " + ivecs[i].Length()
Next

Local iv1:Ivector = ivecs[0], iv2:Ivector = ivecs[1], iv3:Ivector = ivecs[2], iv4:Ivector = ivecs[3]
Print "~nDirect (variable access):"
Print "  v1 length: " + iv1.Length()
Print "  v2 length: " + iv2.Length()
Print "  v3 length: " + iv3.Length()
Print "  v4 length: " + iv4.Length()

Print "~ndone."
End

