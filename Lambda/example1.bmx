
' Lambda example 1
' functions as expressions, closures, etc.

Import "lambda.bmx"

SuperStrict

'Shorten the constructor names into something manageable
Global FN_i:TLambda(_:Int Var) = TLambda.FN_Int, FN_ii:TLambda(_0:Int Var, _1:Int Var) = TLambda.FN_IntInt

Local x:Int, y:Int, z:Int	'Parameters need to exist as local variable names... otherwise unremarkable

Local f0:TLambda = FN_i(x).asInt( x + 6 )	'Simple functions
Print f0.callI(15).i
Local f1:TLambda = FN_ii(x, y).asInt( x * 2 + y * 3 )
Print f1.callII(9, 5).i


Local f0func:Int(x:Int) = TLambda.Reify(f0, "i")	'Simple functions (not closures, below) can be reified into real function pointers
Print f0func(13)	'Normal call syntax!


For Local i:Int = 5 To 7		'Closures over real locals
	Local f2:TLambda = MakeAdder(i)
	Print "Adder " + i + " plus 10 = " + f2.callI(10).i
Next
Function MakeAdder:TLambda(n:Int)
	Local x:Int		'Still need a local to be the parameter
	Return FN_i(x).asInt( n + x )	'Closes over n - a real BlitzMax local!
End Function


Local f3:TLambda = FN_i(x).asInt( SideEffects(42) )	'Because the body runs, this will print now, even though we don't want it to yet
Print f3.callI(0).i	'Still prints again OK though

Print UseLam( FN_i(x).asInt( x + 13 ) )	'Use a lambda as part of an expression

Function SideEffects:Int(n:Int)	'Used with f3: this function has a side effect
	Print "function is running!"
	Return n + 1
End Function
Function UseLam:Int(f:TLambda)		'Pass a lambda to a higher-order function
	Return f.callI(4).i
End Function


Local u:Float, v:Float
Print TLambda.FN_FloatFLoat(u, v).asFloat( ..
	u + v ..
).callFF(16.5, 3.75).f


Local s:String, t:String
Local f4:TLambda = TLambda.FN_String(s).asInt( s.Length )
Print f4.callS("four").i
Print TLambda.FN_StringString(s, t).asString( ..
	t.ToLower() + s.ToUpper() ..
).callSS("Foo", "Bar").s


Print "~ndone."

