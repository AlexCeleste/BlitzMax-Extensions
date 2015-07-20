
' Lambda example 2
' Function reification

Import "lambda.bmx"
SuperStrict

Local x:Int
Global FN_i:TLambda(_:Int Var) = TLambda.FN_Int

' Define a bunch of functions as lambda objects...
Local actions:TLambda[] = [..
	FN_i(x).asInt( x + 26 ), ..
	FN_i(x).asInt( x + 12 ), ..
	FN_i(x).asInt( x + 18 ), ..
	FN_i(x).asInt( x + 93 ), ..
	FN_i(x).asInt( x + 17 ), ..
	FN_i(x).asInt( x + 40 ) ..
]
Local funcs:Int(x:Int)[actions.Length]

' Because none of them form closures, we can safely convert them into function pointers...
For Local a:Int = 0 Until actions.Length
	funcs[a] = TLambda.Reify(actions[a], "i")
Next

' ...and use native call syntax!
For Local f:Int(x:Int) = EachIn funcs
	Print f(1)
Next

Print "~ndone."
End
