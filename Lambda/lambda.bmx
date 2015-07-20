
' Lambda extension for BLitzMax
' Functions as expressions, forming closures over real BlitzMax locals

Import "lambda.o"
Import "../Interface/interface_allocprotect.c"	'Shared with TInterface

SuperStrict

Type TLambda
	Field start:Byte Ptr, ret:Byte Ptr, esp:Byte Ptr, ebp:Byte Ptr, frame:Int Ptr
	Field argofs:Int[], argc:Int, ready:Int, rType:Int, argTypes:String, _rei:Byte Ptr
	Field i:Int, f:Float, o:Object, s:String	'Result fields
	
'	Function FN:TLambda()
'		Local _:Int ; Return FN_Make(AllocFrame(FRAMESIZE), 0, Varptr _, Varptr _)
'	End Function
	Function FN_Int:TLambda(a0:Int Var)
		Return FN_Make(AllocFrame(FRAMESIZE), 1, Varptr a0, Varptr a0, "I")	'These constructors are carefully calibrated to not use callee-save registers
	End Function
	Function FN_Float:TLambda(a0:Float Var)
		Return FN_Make(AllocFrame(FRAMESIZE), 1, Varptr a0, Varptr a0, "F")	'...so don't change them without examining the resulting asm
	End Function
	Function FN_String:TLambda(a0:String Var)
		Return FN_Make(AllocFrame(FRAMESIZE), 1, Varptr a0, Varptr a0, "S")
	End Function
	Function FN_Object:TLambda(a0:Object Var)
		Return FN_Make(AllocFrame(FRAMESIZE), 1, Varptr a0, Varptr a0, "O")
	End Function
	Function FN_IntInt:TLambda(a0:Int Var, a1:Int Var)
		Return FN_Make(AllocFrame(FRAMESIZE), 2, Varptr a0, Varptr a1, "II")
	End Function
	Function FN_FloatFloat:TLambda(a0:Float Var, a1:Float Var)
		Return FN_Make(AllocFrame(FRAMESIZE), 2, Varptr a0, Varptr a1, "FF")
	End Function
	Function FN_StringString:TLambda(a0:String Var, a1:String Var)
		Return FN_Make(AllocFrame(FRAMESIZE), 2, Varptr a0, Varptr a1, "SS")
	End Function
	Function FN_ObjectObject:TLambda(a0:Object Var, a1:Object Var)
		Return FN_Make(AllocFrame(FRAMESIZE), 2, Varptr a0, Varptr a1, "OO")
	End Function
	
	Method asInt:TLambda(val:Int)
		Return FN_As(Self, val, 0.0, "", Null)
	End Method
	Method asFloat:TLambda(val:Float)
		Return FN_As(Self, 0, val, "", Null)
	End Method
	Method asString:TLambda(val:String)
		Return FN_As(Self, 0, 0.0, val, val)
	End Method
	Method asObject:TLambda(val:Object)
		Return FN_As(Self, 0, 0.0, "", val)
	End Method
	
	Method callI:TLambda(arg0:Int)
		Return FN_Call(Self, 1, [arg0], "I")
	End Method
	Method callF:TLambda(arg0:Float)
		Return FN_Call(Self, 1, [Int Ptr(Varptr arg0)[0]], "F")
	End Method
	Method callS:TLambda(arg0:String)
		Return FN_Call(Self, 1, [Int(Byte Ptr(Object(arg0)) - 8)], "S")
	End Method
	Method callO:TLambda(arg0:Object)
		Return FN_Call(Self, 1, [Int(Byte Ptr(arg0) - 8)], "O")
	End Method
	Method callII:TLambda(arg0:Int, arg1:Int)
		Return FN_Call(Self, 2, [arg0, arg1], "II")
	End Method
	Method callFF:TLambda(arg0:Float, arg1:Float)
		Return FN_Call(Self, 2, [Int Ptr(Varptr arg0)[0], Int Ptr(Varptr arg1)[0]], "FF")
	End Method
	Method callSS:TLambda(arg0:String, arg1:String)
		Return FN_Call(Self, 2, [Int(Byte Ptr(Object(arg0)) - 8), Int(Byte Ptr(Object(arg1)) - 8)], "SS")
	End Method
	Method callOO:TLambda(arg0:Object, arg1:Object)
		Return FN_Call(Self, 2, [Int(Byte Ptr(arg0) - 8), Int(Byte Ptr(arg1) - 8)], "OO")
	End Method
	
	Global Reify:Byte Ptr(_self:TLambda, rType:String) = FN_Reify		'This "method" is not thread safe, so...
	
	Method Delete()
		MemFree frame
	End Method
	
	Global _init:Int = _initf()
End Type


Private
Extern
	Function GetStart:Byte Ptr(fr:Byte Ptr, _t1:Int Ptr, _t2:Int Ptr) = "TLAMBDA_GetStart"
	Function DoCall:Int(fr:Byte Ptr, st:Byte Ptr, _self:Object, ret:Byte Ptr, ebp:Byte Ptr, esp:Byte Ptr) = "TLAMBDA_DoCall"
	Function EndCall(ret:Byte Ptr, ebp:Byte Ptr, esp:Byte Ptr, fr:Byte Ptr) = "TLAMBDA_EndCall"
	Function GetHostESP:Int() = "TLAMBDA_GetHostESP"
	Function AllocFrame:Int Ptr(size:Int) = "TLAMBDA_AllocFrame"
	
	Function JitAlloc:Byte Ptr(sz:Int) = "tinterface_alloc"
	Function JitRePro:Int(p:Byte Ptr, sz:Int) = "tinterface_reprotect"
End Extern

Const FRAMESIZE:Int = 256

Function FN_Make:TLambda(frame:Int Ptr, nargs:Int, a0p:Byte Ptr, a1p:Byte Ptr, argTypes:String)', a2p:Byte Ptr, a3p:Byte Ptr)	'Can add more arguments if really necessary
	Local l:TLambda = New TLambda
	l.frame = frame ; Local _t1:Int, _t2:Int		'Callee-save registers (_t1 and _t2 are temporaries)
	l.start = GetStart(l.frame, Varptr _t1, Varptr _t2)	'Own return IP -> start, hosting stack frame -> frame
	l.argc = nargs ; l.argofs = New Int[nargs] ; l.argTypes = argTypes
	Local argps:Byte Ptr[] = [a0p, a1p]', a2p, a3p]	'Extend to match parameter list (again, if req'd)
	Local esp:Int = GetHostESP(), i:Int
	For Local v:Int = 0 Until nargs
		For i = 0 Until l.frame[6] Step 4
			If Int(argps[v]) = esp + i
				l.argofs[v] = 7 + (i / 4) ; Exit
			EndIf
		Next
		If i = l.frame[6] Then RuntimeError "Unable to locate local corresponding to TLambda parameter slot (check that it is not a field or global)"
	Next
	Return l
End Function

Function FN_As:TLambda(this:TLambda, vali:Int, valf:Float, vals:String, valo:Object)
	If this.ready	'This is actually the end of a call - reset the stack position to where we started from and jump home
		this.i = vali ; this.f = valf ; this.s = vals ; this.o = valo
		EndCall this.ret, this.ebp, this.esp, this.frame
	Else	'Actually setting up - nothing to do, return self
		this.ready = True
	EndIf
	Return this
End Function

Function FN_Call:TLambda(_s:TLambda, argc:Int, args:Int[], argTypes:String)
?Debug
	If _s.argc <> argc Then RuntimeError "Wrong number of arguments to TLambda: expected " + _s.argc + ", received " + argc
	If argTypes <> _s.argTypes Then RuntimeError "Wrong arguument types to TLambda: expected " + _s.argTypes + ", received " + argTypes
?
	For Local i:Int = 0 Until _s.argc
		_s.frame[_s.argofs[i]] = args[i]
	Next
	DoCall(_s.frame, _s.start, _s, Varptr _s.ret, Varptr _s.ebp, Varptr _s.esp)
	Return _s
End Function

Function FN_Reify:Byte Ptr(f:TLambda, rType:String)
	Global LMap:TMap = CreateMap()	'Keys = string form of f.start ; Vals = string form of JITted start ptr
	
	Local val:TLambda = TLambda(LMap.ValueForKey(String(Int(f.start))))
	If val Then Return val._rei
	
	f._rei = JIT_Reify(f, rType)
	LMap.Insert(String(Int(f.start)), f)
	
	Return f._rei
End Function

Function JIT_Reify:Byte Ptr(f:TLambda, rType:String)
	Extern
		Function bbRefMethodPtr:Byte Ptr(o:Object, i:Int)
		Function bbRefFieldPtr:Byte Ptr(o:Object, i:Int)
		Function bbGCRetain(obj:Object)
	End Extern
	Const BLOCKSIZE:Int = 4096 * 5
	Global block:Byte Ptr, bytes:Int = 0
	
	bbGCRetain f	'Marked forever!
	Local m:TMethod = TTypeId.ForObject(f).FindMethod("call" + f.argTypes)
	Local mp:Byte Ptr = bbRefMethodPtr(f, m._index), mpp:Byte Ptr = Varptr(mp)
	Local op:Byte Ptr = Byte Ptr(f) - 8, opp:Byte Ptr = Varptr(op)
	Local fld:TField = TTypeId.ForObject(f).FindField(rType)
	Local fofs:Int = bbRefFieldPtr(f, fld._index) - (Byte Ptr(f) - 8)
	
	Local vec:Int[] = ..
	[$b9, $20, $00, $00, $00,..  'mov $32, %ecx
	$8d, $54, $24, $dc,..        'lea -36(%esp), %edx
	$83, $f9, $00,..             'cmp $0, %ecx
	$74, $0b,..                  'je loopend
	..'looptop:
	$8b, $04, $0c,..             'mov (%esp, %ecx), %eax
	$89, $04, $0a,..             'mov %eax, (%edx, %ecx)
	$83, $e9, $04,..             'sub $4, %ecx
	$75, $f5,..                  'jnz looptop
	..'loopend:
	$89, $d4,..                  'mov %edx, %esp
	$ba, Int(opp[0]), Int(opp[1]), Int(opp[2]), Int(opp[3]),..   'mov {op}, %edx
	$b8, Int(mpp[0]), Int(mpp[1]), Int(mpp[2]), Int(mpp[3]),..   'mov {mp}, %eax
	$89, $14, $24, ..            'mov %edx, (%esp)
	$ff, $d0,..                  'call *%eax
	$83, $c4, $24,..             'add $36, %esp
	$8b, $40, fofs,..            'mov {fofs}(%eax), %eax
	$c3]                         'ret
	
	If bytes < vec.Length + 2
		If block Then JitRePro(block, 2)	'Remove write capability on old block
		block = JitAlloc(BLOCKSIZE)
		If Not block Then Throw "TLambda.Reify: unable to allocate memory for wrapper"
		bytes = BLOCKSIZE
	EndIf
	
	For Local c:Int = 0 Until vec.Length
		block[c] = vec[c]
	Next
	Local newP:Byte Ptr = block
	bytes :- vec.Length
	block :+ vec.Length
	Return newP
End Function

Function _initf:Int()
?Not X86
	RuntimeError "Error: TLambda is only designed for X86"
?
End Function
Public

