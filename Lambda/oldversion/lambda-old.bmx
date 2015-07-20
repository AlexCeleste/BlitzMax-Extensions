
Import "lambda-old.o"

SuperStrict

Private
Extern
	Function GetStart:Byte Ptr() = "TLAMBDA_GetStart"
	Function DoCall(_self:Object, f:Byte Ptr, r:Byte Ptr, b:Byte Ptr, s:Byte Ptr) = "TLAMBDA_DoCall"
	Function EndCall(r:Byte Ptr, b:Byte Ptr, s:Byte Ptr) = "TLAMBDA_EndCall"
'	Function GetEBP:Int() = "TLAMBDA_GetEBP"
'	Function GetESP:Int() = "TLAMBDA_GetESP"
End Extern
Public

Type TLambda
	Field args:TFnArg[], clos:TFnArg[], cval:TBoxVal[], val:TBoxVal
	Field start:Byte Ptr, ret:Byte Ptr, esp:Byte Ptr, ebp:Byte Ptr
	Global _SELF:TLambda
	
	Function FN:TLambda(args:TFnArg[])
		Local l:TLambda = New TLambda
		l.args = args ; l.start = GetStart()	'Own return IP -> start
		Return l
	End Function
	
	Method as:TLambda(term:TBoxVal)
		If _SELF	'This is actually the end of a call
			_SELF.val = term
			EndCall _SELF.ret, _SELF.ebp, _SELF.esp		'Forcibly reset the stack position to where we started from
			Return Null		'Never reach here
		Else	'Actually setting up - nothing to do
			Return Self
		EndIf
	End Method
	Method over:TLambda(cl:TFnArg[])
		If clos = Null
			clos = cl ; cval = New TBoxVal[cl.length]
		Else
			clos = clos[..(clos.length + cl.length)]
			cval = cval[..clos.length]
			For Local i:Int = 1 To cl.length
				clos[clos.length - i] = cl[cl.length - i]
			Next
		EndIf
		For Local i:Int = 1 To cl.length
			cval[cval.length - i] = cl[cl.length - i]._peek()
		Next
		Return Self
	End Method
	Method call:TBoxVal(a:TBoxVal[])
		Local rv:TBoxVal
		If a.length > args.length Then Throw "Too many arguments to TLambda " + ToString()
		For Local i:Int = 0 Until a.length	'Push down arg values onto arg objects
			args[i]._push a[i]
		Next
		If a.length < args.length	'Curry
			Local curry:TLambda = FN(args[a.length ..]).over(args[.. a.length])
			curry.start = start
			rv = TBoxVal.BO(curry)
		Else
			If clos		'Push down closed over values as well
				For Local i:Int = 0 Until clos.length
					clos[i]._push cval[i]
				Next
			EndIf
			
			_SELF = Self
			DoCall Self, start, Varptr ret, Varptr ebp, Varptr esp	'Post-jump -> ret ; Jump to start IP
			rv = val ; _SELF = Null
			
			If clos		'Pop closed over values
				For Local i:Int = 0 Until clos.length
					clos[i]._pop
				Next
			EndIf
		EndIf
		For Local i:Int = 0 Until a.length	'Pop arg values
			args[i]._pop
		Next
		Return rv
	End Method
	
	Function _init:Int()
?Not X86
		Throw "Error: TLambda is only designed for X86"
?
?Threaded
		Throw "Error: TLambda is not even remotely thread safe"
?
	End Function
	Global init:Int = TLambda._init()
End Type

Type TBoxVal
	Field i:Int, f:Float, d:Double, l:Long, o:Object
	Function BI:TBoxVal(v:Int)
		Local b:TBoxVal = New TBoxVal ; b.i = v ; Return b
	End Function
	Function BF:TBoxVal(v:Float)
		Local b:TBoxVal = New TBoxVal ; b.f = v ; Return b
	End Function
	Function BD:TBoxVal(v:Double)
		Local b:TBoxVal = New TBoxVal ; b.d = v ; Return b
	End Function
	Function BL:TBoxVal(v:Long)
		Local b:TBoxVal = New TBoxVal ; b.l = v ; Return b
	End Function
	Function BO:TBoxVal(v:Object)
		Local b:TBoxVal = New TBoxVal ; b.o = v ; Return b
	End Function
End Type

Type TFnArg Extends TBoxVal
	Field _stk:TList
	Method New()
		_stk = New TList
	End Method
	Method _push(v:TBoxVal)
		Local b:TBoxVal = New TBoxVal ; b.i = i ; b.f = f ; b.d = d ; b.l = l ; b.o = o ; _stk.AddLast b
		i = v.i ; f = v.f ; d = v.d ; l = v.l ; o = v.o
	End Method
	Method _pop()
		Local v:TBoxVal = TBoxVal(_stk.RemoveLast()) ; i = v.i ; f = v.f ; d = v.d ; l = v.l ; o = v.o
	End Method
	Method _peek:TBoxVal()
		Local b:TBoxVal = New TBoxVal ; b.i = i ; b.f = f ; b.d = d ; b.l = l ; b.o = o ; Return b
	End Method
End Type
