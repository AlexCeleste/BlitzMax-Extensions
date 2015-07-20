
' AspectMax example 4: wildcards

' partial name matching for maximum flexibility

Import "Aspect.bmx"
SuperStrict

' Aspects on a single type are all very well, but really demonstrate nothing we can't do already
' So let's raise the "dimension" of the code now, and show how aspects can cut "across" the class
' structure ("cross-cutting concerns" means that you often want to impose the same logging/
' security/whatever framework across multiple unrelated types)

' Here are three types, not connected by type hierarchy:

Type Vector2
	Field x:Float, y:Float
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

Type Vector3
	Field x:Float, y:Float, z:Float
	Method Add:Vector3(r:Vector3)
		Local res:Vector3 = New Self
		res.x = x + r.x ; res.y = y + r.y ; res.z = z + r.z
		Return res
	End Method
	Method Sub:Vector3(r:Vector3)
		Local res:Vector3 = New Self
		res.x = x - r.x ; res.y = y - r.y ; res.z = z - r.z
		Return res
	End Method
End Type

Type Matrix4x4
	Field m:Float[16]
	Method Add:Matrix4x4(r:Matrix4x4)
		Local res:Matrix4x4 = New Self
		For Local i:Int = 0 Until 15
			res.m[i] = m[i] + r.m[i]
		Next
		Return res
	End Method
	Method Sub:Matrix4x4(r:Matrix4x4)
		Local res:Matrix4x4 = New Self
		For Local i:Int = 0 Until 15
			res.m[i] = m[i] - r.m[i]
		Next
		Return res
	End Method
	Method AddScalar:Matrix4x4(s:Float)
		Local res:Matrix4x4 = New Self
		For Local i:Int = 0 Until 15
			res.m[i] = m[i] + s
		Next
		Return res
	End Method
End Type

' But their operations are so similar... can't we apply concerns all at once somehow?
Type TensorAspect Extends TAspect
	' We can roll up both Add and AddScalar (and any hypothetical others like AddMatrix) into
	' a single pointcut by using a wildcard name
	' A name that ends (only the end) in a star will match any method or type name that begins
	' with all of the characters leading up to the star
	Field AddOp:Pointcut = Pointcut.MName("Add*")  'match both Add methods
	
	' We can do the same for type names
	' So here we're And-ing against any Vect* types, so exclude Matrix4x4
	Field VecSum:Pointcut = Pointcut.All(Pointcut.TName("Vect*"), PointCut.Any(Pointcut.MName("Add"), Pointcut.MName("Sub")))
	
	' If we really want, we can match globally, and annoy ourselves even
	' when constructing and destructing objects. This will match *every* join point for Vector3,
	' including New:
	Field Vec3Everything:Pointcut = Pointcut.All(Pointcut.TName("Vector3"), Pointcut.MName("*"))
	
	' Apply some advice
	Method Advice_Before_AddOp()
		Print "preparing to add two things"
	End Method
	Method Advice_Before_VecSum()
		Print "preparing to do something with two vectors"
	End Method
	Method Advice_Before_Vec3Everything()
		Print "preparing to take some action on a Vector3"
	End Method
End Type

' Wildcards can also appear in the Weave statement, although only in the target list (left)
TAspect.Weave(["Vector*", "Matrix*"], ["TensorAspect"])

' Create some objects...
Print "Vector2:"
Local v1:Vector2 = New Vector2, v2:Vector2 = New Vector2
v1.x = 6 ; v1.y = 8 ; v2.x = 5 ; v2.y = 9
Local v3:Vector2 = v1.Add(v2), v4:Vector2 = v1.Sub(v2)

Print "Matrix4x4:"
Local m1:Matrix4x4 = New Matrix4x4, m2:Matrix4x4 = m1.AddScalar(6)
Local m3:Matrix4x4 = m1.Add(m2)

' Since Vector3 was advised globally, even New will annoy us
Print "Vector3 (new):"
Local v5:Vector3 = New Vector3, v6:Vector3 = New Vector3
' This is a lot of stacked advisements!
Print "Vector3:"
v5.x = 6 ; v5.y = 8 ; v5.z = 10 ; v6.x = 5 ; v6.y = 9 ; v6.z = 13
Local v7:Vector3 = v5.Add(v6), v8:Vector3 = v5.Sub(v6)

Print "~ndone."
End

