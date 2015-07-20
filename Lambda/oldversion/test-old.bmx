
Import "lambda-old.bmx"
SuperStrict


Global FN:TLambda(_:TFnArg[]) = TLambda.FN		'Shorten the constructor names into something manageable
Global I:TBoxVal(_:Int) = TBoxVal.BI, O:TBoxVal(_:Object) = TBoxVal.BO	'These will get a lot of use

Global X:TFnArg = New TFnArg, Y:TFnArg = New TFnArg, Z:TFnArg = New TFnArg	'Some "variable" objects


Local f:TLambda = FN([X, Y, Z]).as(I( X.i + Y.i * Z.i ))	'Simple function
Print f.call([I(4), I(5), I(6)]).i

Local f2:TLambda = TLambda(f.call([I(4)]).o)	'Calling with fewer arguments = currying
Print f2.call([I(5), I(6)]).i

X.i = 4 ; Local f3:TLambda = FN([Y]).as(I( X.i + Y.i )).over([X])	'Forming a closure needs to be done manually
Print f3.call([I(5)]).i

Local f4:TLambda = FN([X]).as( SideEffects(42) )	'Because the body runs, this will print now, even though we don't want it to yet
Print f4.call([I(0)]).i	'Still prints again OK though

Print UseLam( FN([X]).as(I( X.i + 13 )) )	'Use a lambda as part of an expression


Function SideEffects:TBoxVal(n:Int)	'Used with f4: this function has a side effect
	Print "function is running!"
	Return I(n + 1)
End Function

Function UseLam:Int(f:TLambda)		'Pass a lambda to a higher-order function
	Return f.call([I(4)]).i
End Function


Local lt:TLambda = FN([X, Y]).as(I( (X.i + Y.i) * (X.i - Y.i) ))
Function ft:Int(x:Int, y:Int)
	Return (x + y) * (x - y)
End Function

Local start:Int = MilliSecs(), res:Int
For Local j:Int = 1 To 10000000
	res = ft(4, 5)
Next
Print MilliSecs() - start

start = MilliSecs()
For Local j:Int = 1 To 1000000
	res = lt.call([I(4), I(5)]).i
Next
Print MilliSecs() - start
