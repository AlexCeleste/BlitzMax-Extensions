
' AspectMax: an aspect-oriented programming extension

' This extension adds the ability to apply advice to join points in BlitzMax.
' Define pointcuts that describe join points, define advice that applies across pointcuts, and apply advice
' and extension methods to whole groups of Max types at a time.

' Usage:
' - define an aspect as a BlitzMax type extending TAspect
' - define pointcuts as fields initialized with a pointcut expression
'   it's OK to set pointcuts in the aspect constructor for complicated combinations
' - join points are method calls, so pointcuts are expressions describing boolean operations on method and
'   containing-type names (must be non-final: TAspect will check)
' - define advice as methods with the naming convention "Advice_Position_Pointcut" (e.g. "Advice_After_Set")
'   you can also add additional position/pointcut combinations in the metadata (it isn't an error if the
'   method name doesn't match; if you use metadata you can name it anything)
' - define extension methods as sole methods of a brand new type (TAspect will check that you do this!)
'   use ExtMethod.Make with the name of this container type to add it as an extension method (assign it to a
'   field in the aspect); use reflection within the method to read fields on Self
'   the method will be visible through reflection or TInterface

' See also the examples.


Import BRL.Reflection
Import "aspect_memory.c"

SuperStrict


Type TAspect Abstract
	Function Weave(tgts:String[], asps:String[])
		?Not x86
		RuntimeError "The Aspect module is VERY tied to x86 at the moment, as it involves some amount of JIT compilation"
		?
		Local TAspID:TTypeId = TTypeId.ForName("TAspect"), PCutID:TTypeId = TTypeId.ForName("Pointcut"), ExtMeID:TTypeId = TTypeId.ForName("ExtMethod")
		For Local tn:String = EachIn tgts
			Local tl:TList = CreateList()
			If tn[tn.Length - 1] = "*"[0]
				tn = tn[..tn.Length - 1]
				For Local ct:TTypeId = EachIn TTypeId.EnumTypes()
					If ct.Name()[..tn.Length] = tn
						If Not ct.ExtendsType(TAspId) And Not ct.ExtendsType(PCutID) And Not ct.ExtendsType(ExtMeID) Then tl.AddLast(ct)
					EndIf
				Next
			Else
				Local ct:TTypeId = TTypeId.ForName(tn)
				Assert ct Else "no such target type as '" + tn + "'"
				tl.AddLast(ct)
			EndIf
			For Local tt:TTypeId = EachIn tl
				For Local an:String = EachIn asps
					Local at:TTypeId = TTypeId.ForName(an)
					Assert at Else "no such aspect type as '" + an + "'"
					Assert at.ExtendsType(TAspID) Else "'" + an + "' is not a valid aspect"
					_WeaveAspect(tt, at)
				Next
			Next
		Next
	End Function
	
	Function _WeaveAspect(typ:TTypeId, asp:TTypeId)
		Extern
			Function bbRefMethodPtr:Byte Ptr(obj:Object, index:Int)
			Function bbObjectRegisterType(clas:Byte Ptr)
		End Extern
		
		Local aspect:TAspect = TAspect(asp.NewObject())
		
		'go over extension methods
		Local exts:TList = CreateList()
		For Local e:TField = EachIn asp.EnumFields()
			Local ex:ExtMethod = ExtMethod(e.Get(aspect))
			If ex
				If typ.FindMethod(e.Name()) Then RuntimeError "cannot add extension method '" + e.Name() + "' to type '" + typ.Name() + "'; method already exists"
				ex._name = e.Name()
				exts.AddLast(ex)
			EndIf
		Next
		
		Local clas:Byte Ptr Ptr = Byte Ptr Ptr(typ._class), dbg:Int Ptr = Int Ptr(clas[2])
		Local mems:Int = 0, funs:Int = 0, decl:Int Ptr = dbg + 2
		While decl[0]
			If decl[0] = 6 Or decl[0] = 7 Then funs :+ 1
			mems :+ 1
			decl :+ 4
		Wend
		
		Local newdbgsz:Int = (2 + 4 * (mems + exts.Count()) + 1) * 4, newdbg:Int Ptr = Int Ptr(malloc_(newdbgsz))
		memcpy_(newdbg, dbg, (2 + 4 * mems) * 4)
		
		Local newclassz:Int = (12 + funs + exts.Count()) * 4, newclas:Byte Ptr Ptr = Byte Ptr Ptr(malloc_(newclassz))
		memcpy_(newclas, clas, (12 + funs) * 4)
		newclas[0] = clas  'if the new class isn't a subtype of the old, downcasting instances to the old name won't work!
		newclas[2] = newdbg
		
		Local funp:Byte Ptr Ptr = newclas + 12 + funs
		decl = newdbg + 2 + mems * 4
		For Local m:ExtMethod = EachIn exts
			Local decl2:Int Ptr = Int Ptr Ptr(m._clas._class)[2] + 2, name2:Byte Ptr = m._name.ToCString()
			While decl2[0]    'find the last method in the extension's method table
				decl2 :+ 4
			Wend
			Repeat
				decl2 :- 4
			Until decl2[0] = 6
			decl[0] = 6
			decl[1] = Int(name2)  'with the field name, not the method name
			decl[2] = decl2[2]
			decl[3] = Int(funp) - Int(newclas)
			decl :+ 4
			
			Local meth:TMethod = TMethod(m._clas.Methods().Last())
			If meth._index > 65535 Then RuntimeError "extension method in '" + m._clas.Name() + "' must not be final"
			funp[0] = bbRefMethodPtr(m._clas.NewObject(), meth._index)
			funp :+ 1
		Next
		decl[0] = 0
		
		Global ext_jitstub:Int[] = [..
			$8b, $44, $24, $04,..           'mov    eax,DWORD Ptr [esp+0x4]
			$83, $ec, $0c,..                'sub    esp,0xc
			$89, $04, $24,..                'mov    DWORD Ptr [esp],eax
			$e8, $00, $00, $00, $00,..      'call   0x00000000
			$83, $c4, $0c,..                'add    esp,0xc
			$8b, $44, $24, $04,..           'mov    eax,DWORD Ptr [esp+0x4]
			$c7, $00, $aa, $aa, $aa, $aa,.. 'mov    DWORD PTR [eax], 0xaaaaaaaa
			$c3..                           'ret
		]
		
		Local codep:Byte Ptr = _getJitBuf(ext_jitstub)	'JIT up a patch for New that sets the right class on created objects
		Int Ptr(codep + 11)[0] = clas[4] - (codep + 15)
		Byte Ptr Ptr(codep + 24)[0] = newclas
		
		newclas[4] = codep ; clas[4] = codep	'patch the original too, so that New works as expected
		
		'next find those methods that are chosen by pointcuts
		Local joins:TList = CreateList(), pointtype:TTypeId = TTypeId.ForName("Pointcut")
		For Local f:TField = EachIn asp.EnumFields()
			If f._typeid = pointtype
				Local p:Pointcut = Pointcut(f.Get(aspect)), pname:String = f.Name()
				For Local m:TMethod = EachIn typ.EnumMethods()
					If p._Run(m.Name(), typ.Name())
						If m._index > 65535 Then RuntimeError "join method in '" + typ.Name() + "' must not be final; cannot weave advice"
						Local adv:TMethod = asp.FindMethod("Advice_Instead_" + pname)
						If adv Then _adviseInstead(clas, newclas, m, typ, adv, asp)
						adv = asp.FindMethod("Advice_Before_" + pname)
						If adv Then _adviseBefore(clas, newclas, m, typ, adv, asp)
						adv = asp.FindMethod("Advice_After_" + pname)
						If adv Then _adviseAfter(clas, newclas, m, typ, adv, asp)
					EndIf
				Next
			EndIf
		Next
		
		bbObjectRegisterType(newclas)
		typ._Update()
	End Function
	
	Function _adviseBefore(oldclas:Byte Ptr, newclas:Byte Ptr, meth:TMethod, objTyp:TTypeId, advice:TMethod, aspTyp:TTypeId)
		Global before_jitstub:Int[] = [..
			$8b, $44, $24, $04, ..      'mov    eax,DWORD Ptr [esp+0x4]
			$83, $ec, $0c, ..           'sub    esp,0xc
			$89, $44, $24, $04, ..      'mov    DWORD PTR [esp+0x4],eax  -> make Self available as first argument
			$e8, $05, $00, $00, $00, .. 'call   0x00000000
			$83, $c4, $0c, ..           'add    esp,0xc
			$e9, $00, $00, $00, $00  .. 'jmp    0x00000000
		]
		Local codep:Byte Ptr = _getJitBuf(before_jitstub)
		Int Ptr(codep + 12)[0] = Byte Ptr Ptr(aspTyp._class + advice._index)[0] - (codep + 16)  'call to the advice
		Int Ptr(codep + 20)[0] = Byte Ptr Ptr(objTyp._class + meth._index)[0] - (codep + 24)  'jump to the original method
		Byte Ptr Ptr(newclas + meth._index)[0] = codep
		Byte Ptr Ptr(oldclas + meth._index)[0] = codep
	End Function
	Function _adviseAfter(oldclas:Byte Ptr, newclas:Byte Ptr, meth:TMethod, objTyp:TTypeId, advice:TMethod, aspTyp:TTypeId)
		Global after_jitstub:Int[] = [..
			$8d, $44, $24, $04, ..                     'lea    eax,DWORD Ptr [esp+0x4]
			$83, $ec, $1c, ..                          'sub    esp,0x1c
			$89, $04, $24, ..                          'mov    DWORD Ptr [esp],eax
			$c7, $44, $24, $04, $aa, $aa, $aa, $aa, .. 'mov    DWORD Ptr [esp+0x4],0xaaaaaaaa
			$c7, $44, $24, $08, $bb, $bb, $bb, $bb, .. 'mov    DWORD Ptr [esp+0x8],0xbbbbbbbb
			$e8, $05, $00, $00, $00, ..                'call   25 <point>
			$83, $c4, $1c, ..                          'add    esp,0x1c
			$c3  ..                                    'ret
		]
		Local codep:Byte Ptr = _getJitBuf(after_jitstub)
		Byte Ptr Ptr(codep + 14)[0] = Byte Ptr Ptr(objTyp._class + meth._index)[0]
		Byte Ptr Ptr(codep + 22)[0] = Byte Ptr Ptr(aspTyp._class + advice._index)[0]
		Int Ptr(codep + 27)[0] = Byte Ptr(_afterImpl) - (codep + 31)
		Byte Ptr Ptr(newclas + meth._index)[0] = codep
		Byte Ptr Ptr(oldclas + meth._index)[0] = codep
	End Function
	Function _adviseInstead(oldclas:Byte Ptr, newclas:Byte Ptr, meth:TMethod, objTyp:TTypeId, advice:TMethod, aspTyp:TTypeId)
		Global instead_jitstub:Int[] = [..
			$8b, $44, $24, $04, ..      'mov    eax,DWORD Ptr [esp+0x4]
			$83, $ec, $0c, ..           'sub    esp,0xc
			$89, $44, $24, $04, ..      'mov    DWORD PTR [esp+0x4],eax  -> make Self available as first argument
			$e8, $05, $00, $00, $00, .. 'call   0x00000000
			$83, $c4, $0c, ..           'add    esp,0xc
			$c3  ..                     'ret
		]
		Local codep:Byte Ptr = _getJitBuf(instead_jitstub)
		Int Ptr(codep + 12)[0] = Byte Ptr Ptr(aspTyp._class + advice._index)[0] - (codep + 16)
		Byte Ptr Ptr(newclas + meth._index)[0] = codep
		Byte Ptr Ptr(oldclas + meth._index)[0] = codep
	End Function
	
	Function _afterImpl:Int(args:Int Ptr, meth:Byte Ptr, advice:Byte Ptr)
		Local f:Int(a:Int, b:Int, c:Int, d:Int, e:Int, f:Int, g:Int, h:Int) = meth
		Local ret:Int = f(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7])
		Local g(me:Int) = advice
		g(args[0])
		Return ret
	End Function
	
	Global _execbuf:Byte Ptr, _execofs:Int
	Const MAX_STUB_SZ:Int = 40
	
	Function _getJitBuf:Byte Ptr(template:Int[])
		Extern
			Function aspect_mmap:Byte Ptr(sz:Int)
			Function aspect_mprotect_rwx:Int(p:Byte Ptr, sz:Int)
		End Extern
		If _execbuf = Null
			_execbuf = aspect_mmap(4096) ; aspect_mprotect_rwx(_execbuf, 4096)
		EndIf
		Local ret:Byte Ptr = _execbuf + _execofs
		_execofs :+ template.Length
		If _execofs > 4096 - MAX_STUB_SZ
			_execbuf = aspect_mmap(4096) ; aspect_mprotect_rwx(_execbuf, 4096) ; _execofs = 0
		EndIf
		For Local i:Int = 0 Until template.Length
			ret[i] = Byte(template[i])
		Next
		Return ret
	End Function
End Type

Type Pointcut Final
	Function MName:Pointcut(name:String)
		Local p:Pointcut = New Self
		p._op = _MNAME ; p._name = name
		Return p
	End Function
	Function TName:Pointcut(name:String)
		Local p:Pointcut = New Self
		p._op = _TNAME ; p._name = name
		Return p
	End Function
	Function Any:Pointcut(p0:Pointcut, p1:Pointcut, p2:Pointcut = Null, p3:Pointcut = Null, p4:Pointcut = Null, p5:Pointcut = Null, p6:Pointcut = Null, p7:Pointcut = Null)
		Local p:Pointcut = New Self
		p._op = _ANY
		p._children = [p0, p1, p2, p3, p4, p5, p6, p7]
		Return p
	End Function
	Function All:Pointcut(p0:Pointcut, p1:Pointcut, p2:Pointcut = Null, p3:Pointcut = Null, p4:Pointcut = Null, p5:Pointcut = Null, p6:Pointcut = Null, p7:Pointcut = Null)
		Local p:Pointcut = New Self
		p._op = _ALL
		p._children = [p0, p1, p2, p3, p4, p5, p6, p7]
		Return p
	End Function
	
	Field _op:Int, _name:String, _children:Pointcut[]
	Const _MNAME:Int = 1, _TNAME:Int = 2, _ANY:Int = 3, _ALL:Int = 4
	
	Method _Run:Int(meth:String, typ:String)
		Local res:Int = (_op = _ALL)
		Select _op
			Case _MNAME
				res = matchName(_name, meth)
			Case _TNAME
				res = matchName(_name, typ)
			Case _ANY
				For Local p:Pointcut = EachIn _children
					If p = Null Then Exit
					res = (res Or p._Run(meth, typ))
				Next
			Case _ALL
				For Local p:Pointcut = EachIn _children
					If p = Null Then Exit
					res = (res And p._Run(meth, typ))
				Next
		End Select
		Return res
		
		Function matchName:Int(l:String, r:String)
			If l[l.Length - 1] = "*"[0]
				l = l[..l.Length - 1] ; r = r[..l.Length]
			EndIf
			Return l = r
		End Function
	End Method
End Type

Type ExtMethod
	Function Make:ExtMethod(fun:String)
		Local e:ExtMethod = New Self
		e._clas = TTypeId.ForName(fun)
		If Not e._clas Then RuntimeError "extension method type '" + fun + "' not found"
		If e._clas.SuperType() <> ObjectTypeId Then RuntimeError "Extension methods must be in a dedicated toplevel type: '" + fun + "' does not directly extend Object"
		Return e
	End Function
	Field _clas:TTypeId, _name:String
End Type

