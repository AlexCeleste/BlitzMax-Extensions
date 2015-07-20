
' Stack allocation and flat vector usage example

Import "struct.bmx"
SuperStrict

Type Foo
	Field a:Byte, b:Short, c:Byte
	Field d:Bar { Struct }
	Method Delete()
		Print "bye foo!"
	End Method
	Method Show()
		Print "foo: " + d.x + ", " + d.y + ", " + d.z
	End Method
End Type

Type Bar { NoFinalize }
	Field x:Int, y:Int, z:Int
	Method New()
		Print "hi bar!"
		x = 42 ; y = 47 ; z = 64
	End Method
	Method Delete()
		Print "bye bar!"
	End Method
End Type

Struct.Initialize	'Need to call this at the start of a program (I would put it in a global but then it fires before some types are registered)

Print "~nAggregate object test"
Local f:foo = New Foo	'Allocating Foo with New automatically populates its { Struct } field .d
Local b:Bar = New Bar ; b.x = 128 ; b.y = 129 ; b.z = 130	'Nothing stopping you allocating Bar as normal, of course
Struct.Assign f.d, b		'Use this to update the value of a whole struct. DO NOT USE =, EVER
f.Show()

'Print "~nFlat array GC test"	'Uncomment to see loads of constructors and finalizers printing messages
'For Local i:Int = 1 To 1000
'	Local a:Object[] = Struct.Array("Foo", 50)	'Note that you can't cast the array to e.g. Foo[] (won't work) - but you can still cast elements
'	Print Foo(a[15]).d.x	'Access elements, but if you have to set, use Assign, NOT = (set element fields appropriately for their type)
'Next

'Print "~nStruct Vector GC test"
'For Local i:Int = 1 To 1000
'	Local sv:SVector = Struct.Vector("Foo", 50)		'Notice that "bye foo!" is printed (eventually) but "bye bar!" is not - { NoFinalize }
'Next

Print "~nStruct Vector element access"	'Vectors don't have the array's index table, so they save some space
Local sv1:SVector = Struct.Vector("Bar", 4)
Print Bar(sv1.Get(2)).y		'... at the cost of slightly more difficult update
sv1.Set(3, b)
Print Bar(sv1.Get(3)).y

Print "~nStruct Vector iteration"
Local sv2:SVector = Struct.Vector("Bar", 8)		'As you can see using For...EachIn with vectors is allowed
For Local b:Bar = EachIn sv2
	Print b.y
Next

Print "~nStack allocation"
Local b2:Bar = bar(Struct.Alloca("Bar"))	'Only types marked { NoFinalize } may be allocated this way (because they won't be)
Print b2.z

Print "~nVector stack allocation"
Local sv3:SVector = SVector(Struct.Alloca("Bar", 8))	'Adding a count >=0 to Alloca will create a Vector instead
For Local b:Bar = EachIn sv3		'...which works with iteration (iterators are still heap allocated)
	Print b.y
Next

ShadowStack.Alloca()		'After functions that have used Alloca return (so... not here), call this to clear fake-stack memory (or get leaks)

Print "~ndone."

