
' Interface example 1
' translated from Java, original: http://www.wideskills.com/java-tutorial/java-abstract-class-and-interface

Import "Interface.bmx"

SuperStrict


' Declare interfaces by extending TInterface, or another interface
Type I1 Extends TInterface
	Method methodI1() Abstract
End Type

Type I2 Extends I1
	Method methodI2() Abstract
End Type


Type A1
	Method methodA1:String()
		Return "I am in methodA1 of class A1"
	End Method
	Method ToString:String()
		Return "toString() method of class A1"
	End Method
End Type

' Notice we don't use Implements statements in Max - checking happens at runtime
Type B1 Extends A1
	Method methodI1()
		Print "I am in methodI1 of class B1"
	End Method
	Method methodI2()
		Print "I am in methodI2 of class B1"
	End Method
End Type

Type C1
	Method methodI1()
		Print "I am in methodI1 of class C1"
	End Method
	Method methodI2()
		Print "I am in methodI2 of class C1"
	End Method
End Type

' We can't just assign to interface types, but need the long-form cast (wrapping this in a function would be sensible)
Local if1:I1 = I1(TInterface.Interface(New B1, "I1"))
' casting up to a derived interface type is fine
Local if2:I1 = I1(TInterface.Interface(New B1, "I2"))

if1.methodI1() ' OK as methodI1 is present in B1
' if1.methodI2() ' Compilation error as methodI2 not present in I1

' Downcasting is long-form if we didn't create the interface as the lower type initially
I2(TInterface.Interface(if1.baseObject, "I2")).methodI2()
' but if we did, it works fine. So remember to check for Null
I2(if2).methodI2()

' Does not compile as methodA1() not present in interface reference I1
' Local s:String = if1.methodA1();
' To invoke methodA1 the object itself must be extracted and cast
Local s:String = A1(if1.baseObject).methodA1()
Print "s: " + s

Local t:String = if1.ToString()
Print "t: " + t
Local u:String = if2.ToString()
Print "u: " + u


Local if3:I1 = I1(TInterface.Interface(New C1, "I1"))
Local v:String = if3.ToString()
Print "v: " + v ' prints the object ToString() method

Local o1:Object = New B1
' o1.methodI1(); does not compile as Object does not define methodI1()
' to solve the probelm we need to downcast o1 reference. We can do it
' in the following 4 ways:
I1(TInterface.Interface(o1, "I1")).methodI1() ' 1
I2(TInterface.Interface(o1, "I2")).methodI1() ' 2
B1(o1).methodI1() ' 3

' B1 does not have any relationship with C1 except they are "siblings".
' Well, you can't cast siblings into one another.
' C1(o1).methodI1()  ' produces a null reference exception

Print "~ndone."
End

