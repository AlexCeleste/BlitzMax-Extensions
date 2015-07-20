
' Interface example 3
' translated from Java, original: http://www.wideskills.com/java-tutorial/java-abstract-class-and-interface/p/0/1

' further examples of polymorphic method calls

Import "Interface.bmx"
SuperStrict


Type IShape Extends TInterface
	Method Area:Float() Abstract
	Method Volume:Float() Abstract
	
	Function Cast:IShape(o:Object)
		Return IShape(TInterface.Interface(o, "IShape"))
	End Function
End Type


' No common base class between these shapes
Type Cube
	Field width:Float
	Method New()
		width = Rnd(1, 10)
	End Method
	Method Area:Float()
		Return 6 * width * width
	End Method
	Method Volume:Float()
		Return width * width * width
	End Method
	Method ToString:String()
		Return "<Cube " + width + ">"
	End Method
End Type

Type Circle
	Field radius:Float
	Method New()
		radius = Rnd(1, 10)
	End Method
	Method Area:Float()
		Return Pi * radius * radius
	End Method
	Method Volume:Float()
		Return 0
	End Method
	Method ToString:String()
		Return "<Circle " + radius + ">"
	End Method
End Type

' ...yet they can be put in a polymorphic list
Local shapes:IShape[] = [..
	IShape.Cast(New Cube), IShape.Cast(New Circle), IShape.Cast(New Cube), ..
	IShape.Cast(New Circle), IShape.Cast(New Cube), IShape.Cast(New Circle) ..
]
For Local s:IShape = EachIn shapes
	Print "The area and volume of " + s.ToString() + " are " + s.Area() + " and " + s.Volume() + "."
Next

Print "~ndone."
End

