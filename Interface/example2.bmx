
' Interface example 2
' it's much easier if you pack those long-form casts into functions
' defining static functions in an interface is perfectly OK

Import "Interface.bmx"
SuperStrict

Type Foo
	Field s:String
	Method act()
		Print "This Foo is fooping!"
	End Method
	Method show()
		Print "s is " + s
	End Method
	Method ToString:String()
		Return "Foo!"
	End Method
End Type

Type Bar
	Field x:Int
	Method show()
		Print "x is " + x
	End Method
	Method act()
		Print "This Bar is barping with " + x
	End Method
End Type


Type IFooBar Extends TInterface
	Method show() Abstract
	Method act() Abstract
	
	Function Cast:IFooBar(o:Object)
		Return IFooBar(TInterface.Interface(o, "IFooBar"))
	End Function
End Type


Local f:Foo = New Foo ; f.s = "FortyTwo"
Local g:Foo = New Foo ; g.s = "SixtyFour"
Local b:Bar = New Bar ; b.x = 42

Local i:IFooBar = IFooBar.Cast(f)	'much easier!
Local j:IFooBar = IFooBar.Cast(b)
Local k:IFooBar = IFooBar.Cast(g)

'Foo and Bar objects now run together and exhibit polymorphism, despite *no* common base class! Yay!
i.show()
j.show()
k.show()
i.act()
j.act()
k.act()

Print "~ndone."
End

