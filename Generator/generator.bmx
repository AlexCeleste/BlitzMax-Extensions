
' Generator implementation for BlitzMax

Import "generator.o"
SuperStrict

Type TGenerator Abstract
	Field _frame:Byte Ptr, _ins:Byte Ptr, _st:Int
	
	Method Yield(val:Object) Final
		GEN_Yield2 _frame, Varptr _ins, val
	End Method
	Method Done() Final
		_st = 0
	End Method
	Method Resume:Object() Final
		If _st = -1 Or _ins = Byte Ptr(0)
			_st = 1
			GEN_CalleeSave _frame ; Return Run()	'It is IMPERATIVE that nothing come between these two commands - sensitive to register allocation
		Else
			Return GEN_Resume(_frame, _ins)
		EndIf
	End Method
	Method Reset() Final
		_st = -1
	End Method
	Method Run:Object() Abstract
	
	Method New()
		_frame = MemAlloc(256)	'Technically not safe but I think it's enough (better than BRL.Reflection can manage)
		_st = -1 ; _ins = Byte Ptr(0)
	End Method
	Method Delete()
		MemFree _frame
	End Method
	Method ObjectEnumerator:TGeneratorEnumerator() Final
		Local e:TGeneratorEnumerator = New TGeneratorEnumerator ; e.this = Self ; Return e
	End Method
End Type

Type TGeneratorEnumerator Final
	Field this:TGenerator
	Method HasNext:Int() Final
		Return this._st <> 0
	End Method
	Method NextObject:Object() Final
		Return this.Resume()
	End Method
End Type

Private
Extern
Function GEN_Yield2(fr:Byte Ptr, ins:Byte Ptr, val:Object) = "GENERATOR_Yield2"
Function GEN_Resume:Object(fr:Byte Ptr, ins:Byte Ptr) = "GENERATOR_Resume"
Function GEN_CalleeSave(fr:Byte Ptr) = "GENERATOR_CalleeSave"
'Function bbRefMethodPtr:Byte Ptr(o:Object, i:Int)	'Reminder: may want to use this to bolster CalleeSave
End Extern

Global _gen:Int = _init()
Function _init:Int()
?Not x86
	RuntimeError "TGenerator does not support non-x86 platforms"
?
	Return 0
End Function
Public

