
' Simple example of using generators

Import "generator.bmx"
SuperStrict

Type Count Extends TGenerator
	Function From:TGenerator(n:Int)
		Local g:Count = New Count ; g.n = n ; Return g
	End Function
	
	Field n:Int
	Method Run:Object()
	'	Print "starting run"
		Local x:Int = n		'Notice how we're not updating the field within the loop
		Repeat
		'	Print "loop top"
			Yield String(x)
		'	Print "restored"
			x :+ 1
		Forever
	End Method
End Type


Print "~nLooping:"
For Local i:String = EachIn Count.From(10)
'	Print "enum loop top"
	Print i
'	Print "enum loop bottom"
	If Int(i) > 15 Then Exit
Next

Print "~nManual resumption:"
Local g:TGenerator = Count.From(5)
Print g.Resume().ToString()
Print g.Resume().ToString()
Print g.Resume().ToString()

Print "~ndone."
