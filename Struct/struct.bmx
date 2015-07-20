
Import "struct_reprotect.c"
Import "struct_alloca.o"
SuperStrict

'Structs/value objects/stack allocation

' - locally "stack" allocated instances
' - aggregate objects with "inlined" components
' - flat arrays with "inlined" elements
' - flat "vectors" that save on the pointers but can't use indexing
' - "stack" allocated small arrays/vectors

'NOT PERMITTED:
' - recursive structs
' - assigning struct references to other objects
' - returning struct references
' - native slices
' - assigning to flat arrays
' - reflection on aggregates/flat arrays/vectors (same reason as with TInterface)
' - assigning between different types; assignment is not polymorphic
' - no finalizable/reference values inside a NoFinalize object
' - casting a flat Object[] to any other typed array (sadly this won't work)


Type Struct Final
	Const MANYREFS:Int = $40000000
	
	Function Alloca:Object(tn:String, el:Int = -1)	'Allocate an instance of the requested type in the current stack frame, or a Vector
		Local d:StructData = StructData.Get(tn)
		If d.finalize Then RuntimeError "Type '" + d.typeID.Name() + "' cannot be stack allocated as it requires a finalizer"
		If el < 0
			Local p:Int Ptr = Int Ptr(ShadowStack.Alloca(d.sz)) ; p[0] = Int(d.clas) ; p[1] = MANYREFS ; InvokeInitializer p
			Local o:Object ; Int Ptr(Varptr o)[0] = Int(p) ; Return o
		Else
			Global v:StructData ; If v = Null Then v = StructData.Get("SVector")	'Not thread safe here either
			Local p:Int Ptr = Int Ptr(ShadowStack.Alloca(8 + SizeOf(SVector) + el * d.sz)) ; p[0] = Int(v.clas) ; p[1] = MANYREFS
			Local vec:SVector, vecp:Byte Ptr ; Int Ptr(Varptr vec)[0] = Int(p) ; vecp = Byte Ptr(vec)
			For Local i:Int = 0 Until el
				Local ep:Int Ptr = Int Ptr(vecp + SizeOf(SVector) + i * d.sz)
				ep[0] = Int(d.clas) ; ep[1] = MANYREFS ; InvokeInitializer ep
			Next
			vec._es = d.sz ; vec._ec = el ; vec._fin = 0 ; Return vec
		EndIf
	End Function
	
	Function Array:Object[](tn:String, size:Int)	'Allocate an array of instances of the requested type, using flat memory (kinda useless)
		Local t:TTypeId = TTypeId.ForName(tn), at:TTypeId = t.ArrayType(1), atsz:Int = 14
		Local d:StructData = StructData.Get(tn)
		If d = Null Then RuntimeError "Flat array creation error: '" + tn + "' is not a valid struct type"
		
	'	Local ret:Object = bbGCAllocObject(24 + 4 * size + d.sz * size, clas, 0)
		'Sneaky way to avoid reimplementing the allocator (clas is the last 14*4 bytes, saves a separate allocation)
		Local ret:Object[] = Object[](at.NewArray(size + size * (d.sz / 4) + atsz)), rp:Byte Ptr = Byte Ptr(Object(ret)) - 8
		
		Local clas:Int Ptr = Int Ptr(rp + 24 + 4 * size + d.sz * size)
		MemCopy Byte Ptr(clas), Byte Ptr(at._class), atsz * 4
		If d.finalize	'replace FREE with either a simplified version or one that finalizes but does not free elements
			clas[1] = Int(Byte Ptr(FreeArrayFinal))
		Else
			clas[1] = Int(Byte Ptr(FreeArraySimple))
		EndIf
		
		Int Ptr(rp)[0] = Int(clas) ; Int Ptr(rp)[4] :- size * d.sz ; Int Ptr(rp)[5] = size
		For Local i:Int = 0 Until size	'initialize elements and point indices at memory
			Local el:Int Ptr = Int Ptr(rp + 24 + 4 * size + d.sz * i)
			el[0] = t._class ; el[1] = MANYREFS
			Int Ptr(rp + 24 + 4 * i)[0] = Int(el)
			InvokeInitializer Int Ptr(el)
		Next
		Return ret
	End Function
	
	Function Vector:SVector(tn:String, size:Int)	'Allocate a vector of instances of the requested type (indexed by methods)
		Local t:TTypeId = TTypeId.ForName(tn), ed:StructData = StructData.Get(tn), vd:StructData = StructData.Get("SVector")
		Local clasSz:Int = (12 + 3) * 4, totSz:Int = 8 + SizeOf(SVector) + size * ed.sz + clasSz
		Local v:SVector = SVector(bbGCAllocObject(totSz, vd.clas, 2))	'2 is the GC constant for normal objects
		Int Ptr(vd.clas)[1] = Int(Byte Ptr(FreeVector))	'Cannot use the normal bbObjectFree for this
		Int Ptr(Byte Ptr(v) - 8)[0] = Int((Byte Ptr(v) + totSz) - (clasSz + 8))	'Point the class field to the extra space at the end
		Local clasPtr:Int Ptr = Int Ptr(Int Ptr(Byte Ptr(v) - 8)[0])
		MemCopy Byte Ptr(clasPtr), Byte Ptr(vd.clas), clasSz ; clasPtr[3] = totSz
		For Local i:Int = 0 Until size
			Local ep:Int Ptr = Int Ptr(Byte Ptr(v) + SizeOf(SVector) + i * ed.sz)
			ep[0] = Int(ed.clas) ; ep[1] = MANYREFS ; InvokeInitializer ep
		Next
		v._es = ed.sz ; v._ec = size ; v._fin = ed.finalize
		Return v
	End Function
	
	Function Assign(L:Object, R:Object)		'Copy the contents of one struct to another
		AssignByValue L, R
	End Function
	
	Function Initialize()	'Needs to be called before any use of Struct
		StructData.GenAllData
	End Function
End Type

Type SVector Final
	Field _es:Int, _ec:Int, _fin:Int
	Method Get:Object(index:Int)
		If index < 0 Or index >= _ec Then Throw "Struct.Vector index out of bounds (indexing " + index + " on vector of size " + _ec + ")"
		Local ret:Object ; Int Ptr(Varptr ret)[0] = Int(Byte Ptr(Self) + SizeOf(SVector) + _es * index) ; Return ret
	End Method
	Method Set:Object(index:Int, val:Object)
		Local e:Object = Get(index) ; AssignByValue val, e ; Return e
	End Method
	Method Delete()
		If _fin
			For Local i:Int = 0 Until _ec
				Local ep:Int Ptr = Int Ptr(Byte Ptr(Self) + SizeOf(SVector) + i * _es)
				InvokeFinalizer ep
			Next
		EndIf
	End Method
	Method ObjectEnumerator:SVectorEnumerator()
		Local e:SVectorEnumerator = New SVectorEnumerator'SVectorEnumerator(Struct.Alloca("SVectorEnumerator"))
		e.i = 0 ; e.tgt = Self ; Return e
	End Method
End Type

Type SVectorEnumerator Final
	Field tgt:SVector, i:Int
	Method HasNext:Int()
		Return i < tgt._ec
	End Method
	Method NextObject:Object()
		Local ret:Object = tgt.Get(i) ; i :+ 1 ; Return ret
	End Method
End Type

Type ShadowStack	'Secondary stack for object allocation, because using the first is hard (this doesn't work with threading yet - need multiple stacks)
	Const StackSize:Int = 1048576 * 20, MinSize:Int = 64, FrSize:Int = 2, Base:Int = (StackSize / MinSize) * (FrSize * 4)
	Field data:Int Ptr, dpos:Int, spos:Int
	Method New()
		data = Int Ptr(MemAlloc(StackSize + Base)) ; dpos = Base ; spos = 0 ; data[1] = Base
	End Method
	Method Delete()
		MemFree data
	End Method

	Function Alloca:Byte Ptr(size:Int = 0)	'Allocate space on the shadow stack
	'	?Threaded
	'	RuntimeError "Alloca cannot be used in threaded mode yet"	'Yes it can, it's just unsafe and should be limited to the main thread
	'	?
		Global stk:ShadowStack = New ShadowStack
		
		Local ebp:Int = ShowEbp()
		While stk.spos > 0 And ebp > stk.data[stk.spos]		'Frames are [EBP|dataoffset]
			stk.spos :- FrSize
		Wend
		If ebp < Int Ptr(stk.data)[stk.spos]' Or stk.spos = 0	'Create a new frame if we're further along than the latest one
			Local top:Int = stk.data[stk.spos + 1] ; stk.spos :+ FrSize
			stk.data[stk.spos] = ebp ; stk.data[stk.spos + 1] = top
		EndIf
		Local p:Byte Ptr = Byte Ptr(stk.data) + stk.data[stk.spos + 1]
		stk.data[stk.spos + 1] :+ size
		Return p
	End Function
End Type


Private

Extern
Function bbGCAllocObject:Object(size:Int, class:Int Ptr, flags:Int)
Function bbGCDeallocObject(o:Byte Ptr, size:Int)
Function bbObjectNew:Object(t:Int)

Function Struct_RePro:Int(p:Byte Ptr, sz:Int, prot:Int) = "struct_reprotect"
Function Struct_ProtRead:Int() = "struct_protread"
Function Struct_ProtReadWrite:Int() = "struct_protreadwrite"

Function ShowEbp:Int() = "STRUCT_CheckEbp"
End Extern


Type StructData
	Global classMap:TMap = StructData.Init(), gen:Int = 0
	Field sz:Int, finalize:Int, clas:Int Ptr, csz:Int, typeID:TTypeId
	Field fdata_ofs:Int[], fptr_ofs:Int[], ftype:StructData[], ffld:TField[]
	
	Function Init:TMap()
	?Not x86
		RuntimeError "Struct: only x86 targets supported at this time"
	?
		Return New TMap
	End Function
	
	Function Get:StructData(n:String)
		Return StructData(classMap.ValueForKey(n))
	End Function
	
	Function GenAllData:Int()
		For Local t:TTypeId = EachIn TTypeId.EnumTypes()
			GenDataForType(t)
		Next
		gen = 1 ; Return 1
		Function GenDataForType:StructData(t:TTypeId)
			Local d:StructData = Get(t.Name())
			If d Then Return d
			d = New StructData ; classMap.Insert(t.Name(), d) ; d.typeID = t
			Local l:Int = t.EnumFields().Count() ; d.fdata_ofs = New Int[l] ; d.fptr_ofs = New Int[l]
			d.ftype = New StructData[l] ; d.ffld = New TField[l]
			d.sz = -1 ; Local idx:Int = 0, size:Int, pofs:Int = 0, isAggregate:Int = False
			If t._class
				If t.MetaData("NoFinalize") Then d.finalize = 0 Else d.finalize = 1
				size = RoundUp(Int Ptr(t._class)[3], 4)
				For Local f:TField = EachIn t.EnumFields()
					pofs = CalcFieldOffset(pofs, f.TypeID())
					If f.MetaData("Struct")
						Local fd:StructData = GenDataForType(f.TypeID())
						If fd.sz = -1 Then RuntimeError "Struct definition error: '" + t.Name() + "." + f.Name() + ..
							"' is structurally recursive (can't inline a '" + t.Name() + "' inside itself)"
						If fd.finalize = 1 And d.finalize = 0 Then RuntimeError "Struct definition error: '" + f.Name() + ..
							"' requires finalization but is a member of { NoFinalize } type '" + t.Name() + "'"
						If f.TypeID().Name().Find("[") > -1 Then RuntimeError "Struct definition error: '" + t.Name() + "." + f.Name() + ..
							"' is an array; cannot inline array objects into aggregates, only the stack"
						d.fdata_ofs[idx] = size - 8 ; d.ftype[idx] = fd ; d.fptr_ofs[idx] = pofs
						size :+ fd.sz ; isAggregate = True
					Else
						If IsObjectType(f.TypeID())
							If d.finalize = 0 Then RuntimeError "Struct definition error: '" + t.Name() + "' is marked { NoFinalize } " + ..
								"and cannot contain a reference to type '" + f.TypeID().Name() + "'"
							d.ffld[idx] = f
						EndIf
					EndIf
					idx :+ 1 ; pofs :+ FieldSize(f.TypeID())
				Next
				d.sz = size
				d.csz = VtableSize(Int Ptr(t._class)) + 12
			'	If isAggregate
				'	d.clas = Int Ptr(MemAlloc(4 * d.csz))
				'	MemCopy Byte Ptr(d.clas), Byte Ptr(t._class), 4 * d.csz
					d.clas = Int Ptr(t._class)
					Struct_RePro Byte Ptr(t._class), 4 * d.csz, Struct_ProtReadWrite()
					d.clas[9] = Int(Byte Ptr d) - 8
					d.clas[10] = d.clas[4]	'Move these to extra space at the end of the vtable?
					d.clas[11] = d.clas[5]
					If isAggregate
						d.clas[3] = size
						d.clas[4] = Int(Byte Ptr InitializeWrapper)
						d.clas[5] = Int(Byte Ptr FinalizeWrapper)
					EndIf
				'	Struct_RePro Byte Ptr(t._class), 4 * d.csz, Struct_ProtRead()
			'	EndIf
			EndIf
			Return d
		End Function
		Function CalcFieldOffset:Int(pofs:Int, t:TTypeId)
			Return RoundUp(pofs, FieldSize(t))
		End Function
		Function FieldSize:Int(t:TTypeId)
			Select t
				Case ByteTypeId ; Return 1
				Case ShortTypeId ; Return 2
				Case LongTypeId, DoubleTypeId ; Return 8
				Default ; Return 4
			End Select
		End Function
		Function IsObjectType:Int(t:TTypeId)
			If t = ByteTypeId Or t = ShortTypeId Or t = IntTypeId Or t = LongTypeId Or t = FloatTypeId ..
				Or t = DoubleTypeId Or t = StringTypeId Or t = ArrayTypeId Then Return False
			Return True
		End Function
	End Function
End Type

Function RoundUp:Int(i:Int, N:Int)	'Round up to the nearest N
	Return i + (N - i Mod N) * (i Mod N > 0)
End Function

Function InitializeWrapper(o:Object)	'Invoke constructor of self, then all struct elements and update pointers to them
	Local op:Byte Ptr = Byte Ptr(o), clas:Int Ptr = Int Ptr(Int Ptr(op - 8)[0])
	Local f(o:Object) = Byte Ptr(clas[10]) ; f(o)	'Invoke the method in _reserved2_ (the original initializer)
	Local d:StructData ; Int Ptr(Varptr d)[0] = clas[9]
	For Local i:Int = 0 Until d.fdata_ofs.Length
		If d.fdata_ofs[i]
			Local fp:Int Ptr = Int Ptr(op + d.fdata_ofs[i])
			Int Ptr(op + d.fptr_ofs[i])[0] = Int(fp)		'Set the field pointing to the struct
			If Int(d.ftype[i].clas) Then fp[0] = Int(d.ftype[i].clas) Else fp[0] = d.ftype[i].typeID._class
			fp[1] = Struct.MANYREFS	'Break the refcounter
			InvokeInitializer Int Ptr(fp)
		EndIf
	Next
End Function

Function FinalizeWrapper(o:Object)	'Invoke finalizer of self, then all struct elements
	Local op:Byte Ptr = Byte Ptr(o), clas:Int Ptr = Int Ptr(Int Ptr(op - 8)[0])
	Local f(o:Object) = Byte Ptr(clas[11]) ; f(o)	'Invoke the method in _reserved3_ (the original finalizer)
	Local d:StructData ; Int Ptr(Varptr d)[0] = clas[9]
	For Local i:Int = 0 Until d.fdata_ofs.Length
		If d.fdata_ofs[i] And d.ftype[i].finalize
			Local fp:Int Ptr = Int Ptr(op + d.fdata_ofs[i]) ; InvokeFinalizer fp
		EndIf
	Next
End Function

Function FreeArraySimple(a:Object[])
	Local ap:Byte Ptr = Byte Ptr(Object(a)) - 8
?Not threaded
	bbGCDeallocObject ap, (Int Ptr(ap)[0] - Int(ap)) + 14 * 4	'This actually does make sense (ap marks the end of the array)
?
End Function

Function FreeArrayFinal(a:Object[])
	For Local i:Int = 0 Until a.Length	'finalize elements before freeing array
		InvokeFinalizer Int Ptr(Byte Ptr(a[i]) - 8)
	Next
	FreeArraySimple a
End Function

Function FreeVector(v:Int Ptr)
	InvokeFinalizer v
?Not threaded
	bbGCDeallocObject v, (v[0] - Int(v)) + (12 + 3) * 4		'See FreeArraySimple for reasoning
?
End Function

Function InvokeInitializer(o:Int Ptr)
	Local f(o:Int Ptr) = Byte Ptr(Int Ptr(o[0])[4]) ; f(o)
End Function

Function InvokeFinalizer(o:Int Ptr)
	Local f(o:Int Ptr) = Byte Ptr(Int Ptr(o[0])[5]) ; f(o)
End Function

Function VtableSize:Int(class:Int Ptr)
	Local p:Int Ptr = (Int Ptr(class[2])) + 2, count:Int
	While p[0]
		Select p[0]
		Case 6, 7
			count :+ 1
		End Select
		p:+4
	Wend
	Return count - 2
End Function

Function AssignByValue(_t:Object, _f:Object)
	Global AssignRecursive(_f:Byte Ptr, _t:Byte Ptr) = Byte Ptr(AssignByValue)	'Coerce types
	
	Local fp:Byte Ptr = Byte Ptr(_f) - 8, clas:Int Ptr = Int Ptr(Int Ptr(fp)[0]), tp:Byte Ptr = Byte Ptr(_t) - 8
	If clas <> Int Ptr(Int Ptr(tp)[0]) Then RuntimeError "Struct assignment error: assigning to struct from incompatible (sub?)type"
	Int Ptr(fp)[1] = Struct.MANYREFS ; MemCopy tp, fp, clas[3]	'Basic value copy
	Local d:StructData ; Int Ptr(Varptr d)[0] = clas[9]
	
	For Local i:Int = 0 Until d.ffld.Length
		If d.ffld[i]	'Reference values need to be copied properly
			d.ffld[i].Set _t, d.ffld[i].Get(_f)
		ElseIf d.fdata_ofs[i]	'Struct values need to be relinked and recursively assigned
			Local fldp:Byte Ptr = Int Ptr(tp + d.fdata_ofs[i] + 8)
			Int Ptr(tp + d.fptr_ofs[i] + 8)[0] = Int(fldp)		'Set the field pointing to the struct
			AssignRecursive fp + d.fdata_ofs[i] + 8, fldp		'Copy the struct proper
		EndIf
	Next
End Function

'Global gen1:Int = Structdata.genalldata()

Public

