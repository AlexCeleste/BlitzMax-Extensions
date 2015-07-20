
' Interfaces: a language extension providing protocol-based programming

' This extension allows the use of Java-style interfaces (AKA protocols).
' Define types that describe an interface as a set of methods, then cast
' objects that match that protocol to the shared interface type without
' any need for shared base classes.

' Usage:
' - define an interface as a BlitzMax type extending TInterface, populated
'   only with abstract methods (constructor/cast functions are OK)
' - cast implementing objects to the interface type with TInterface.Interface
' - call methods on the boxed objects

' See also the examples.


Import BRL.Reflection
Import "interface_allocprotect.c"

SuperStrict


Type TInterface Abstract
	Function Interface:TInterface(o:Object, iName:String)
		Extern
			Function bbObjectNew:Object(t:Int)
		End Extern
		If TInterface(o) Then RuntimeError "TInterface: do not create an interface over" ..
			+ " another interface - use the .base instead"
		Local it:TTypeId = TTypeId.ForName(iName), ot:TTypeId = TTypeId.ForObject(o)
		If it = Null Then RuntimeError "Interface '" + iName + "' does not exist"
		If Not it.ExtendsType(TTypeId.ForName("TInterface")) Then ..
			RuntimeError "TInterface: '" + iName + "' does not derive TInterface"
		
		Local templ:ITemplate = ITemplate.Get(it, ot)
		If Not templ Then templ = ITemplate.Build(it, ot, o)
		
		Local i:TInterface = TInterface(bbObjectNew(it._class))
		i.baseObject = o
		Int Ptr(Byte Ptr(i) - 8)[0] = Int(templ.clas)
		Return i
	End Function
	
	Field baseObject:Object
End Type

Private

Type ITemplate
	Global map:TMap = CreateMap(), ICounter:Int = 0
	
	Field clas:Int Ptr
	
	Method Delete()
		If clas
			If clas[2] Then MemFree Byte Ptr(clas[2])
			MemFree clas
		EndIf
	End Method
	
	Function Get:ITemplate(it:TTypeId, ot:TTypeId)
		Local m2:TMap = TMap(map.ValueForKey(it))
		If m2 Then Return ITemplate(m2.ValueForKey(ot)) Else Return Null
	End Function
	
	Function Set(it:TTypeId, ot:TTypeId, v:ITemplate)
		Local m2:TMap = TMap(map.ValueForKey(it))
		If Not m2 Then m2 = CreateMap() ; map.Insert it, m2
		m2.Insert ot, v
	End Function
	
	Function Build:ITemplate(it:TTypeId, ot:TTypeId, base:Object)
		Local iml:TList = it.EnumMethods(), oml:TList = ot.EnumMethods()
		iml.Reverse
		For Local im:TMethod = EachIn iml	'Verify methods are present and correctly typed
			If BaseMethod(im.Name()) Then Continue	'Ignore Object's methods as they are not vtabled
			
			Local om:TMethod = ot.FindMethod(im.Name())
			If Not om Then RuntimeError "TInterface: type '" + ot.Name() + ..
				"' does not support method '" + it.Name() + "." + im.Name() + "'"
			'Due to limitations in BRL.Reflection we can only really check argument number ATM
			If im.ArgTypes().Length <> om.ArgTypes().Length Then RuntimeError "TInterface: method '" ..
				+ ot.Name() + "." + om.Name() + "' has wrong number of arguments to match '" ..
				+ it.Name() + "." + im.Name() + "'"
		Next
		
		'Should correspond to VTable layout
		Local oms:TList = UniqueMethods(ot), ims:TList = UniqueMethods(it)
		
		ICounter :+ 1
		Local tem:ITemplate = New ITemplate ; Const IFC_SIZE:Int = 13	'12 + constructor
		tem.clas = Int Ptr(MemAlloc(IFC_SIZE * 4 + ims.Count() * 4))
		For Local e:Int = 0 Until IFC_SIZE	'Blindly copy the class definition
			tem.clas[e] = Int Ptr(it._class)[e]
		Next
		For Local e:Int = 0 Until ims.Count()	'Replace methods with trampolines
			tem.clas[e + IFC_SIZE] = Int(GenTrampoline(base, GetMatchingMethod(ims, oms, e)))
		Next
		'Replace builtin methods as well (if they exist)
		If ot.FindMethod("ToString") Then ..
			tem.clas[6] = Int(GenTrampoline(base, ot.FindMethod("ToString")))
		If ot.FindMethod("Compare") Then ..
			tem.clas[7] = Int(GenTrampoline(base, ot.FindMethod("Compare")))
		If ot.FindMethod("SendMessage") Then ..
			tem.clas[8] = Int(GenTrampoline(base, ot.FindMethod("SendMessage")))
		'Replace New so that this object can't be copied
		tem.clas[4] = Int(Byte Ptr(NewError))
		
		tem.clas[0] = it._class		'Set the new class to be a child of the interface
		
		' Need to work out some way to update the debug information so reflection works
	'	Extern
	'		Function bbObjectRegisterType(c:Byte Ptr)
	'	End Extern
	'	bbObjectRegisterType tem.clas		' This makes reflection work but boots the original class
		
		Set it, ot, tem
		Return tem
	End Function
	
	Function BaseMethod:Int(n:String)	'Check against builtin method names
		n = n.ToLower()
		Return n = "new" Or n = "delete" Or n = "tostring" Or n = "compare" Or n = "sendmessage"
	End Function
	
	Function UniqueMethods:TList(t:TTypeId)	'Overrides only; no supers, no ctors or dtors
		Local ret:TList = CreateList(), ml:TList = t.EnumMethods()
		ml.Reverse
		For Local m:TMethod = EachIn ml
			If BaseMethod(m.Name()) Then Continue
			Local exists:Int, n:String; exists = 0 ; n = m.Name().ToLower()
			For Local m2:TMethod = EachIn ret
				If m2.Name().ToLower() = n Then exists = 1; Exit
			Next
			If Not exists Then ret.AddFirst m
		Next
		Return ret
	End Function
	
	Function GetMatchingMethod:TMethod(ims:TList, oms:TList, idx:Int)
		Local n:String = TMethod(ims.ValueAtIndex(idx)).Name().ToLower()
		For Local om:TMethod = EachIn oms
			If om.Name().ToLower() = n Then Return om
		Next
		Throw "TInterface BUG: something went wrong matching method '" + n + "'"
	End Function
End Type

Extern
	Function IfcAlloc:Byte Ptr(sz:Int) = "tinterface_alloc"
	Function IfcRePro:Int(p:Byte Ptr, sz:Int) = "tinterface_reprotect"
End Extern

Function GenTrampoline:Byte Ptr(o:Object, m:TMethod)
	Extern
		Function bbRefMethodPtr:Int(o:Object, i:Int)
	End Extern
	Const BLOCKSIZE:Int = 4096 * 5
	Global block:Byte Ptr, bytes:Int = 0
	
	?Not X86
	RuntimeError "TInterface: only x86 targets supported at this time"
	?
	
	Local mp:Int = bbRefMethodPtr(o, m._index), pp:Byte Ptr = Varptr(mp)
	Local vec:Int[] = [$8B, $44, $24, $04, $8B, $40, $08, $89, $44, $24, $04,..
					$B8, Int(pp[0]), Int(pp[1]), Int(pp[2]), Int(pp[3]), $FF, $E0]
	
	If bytes < vec.Length + 2
		If block Then IfcRePro(block, 2)	'Remove write capability on old block
		block = IfcAlloc(BLOCKSIZE)
		If Not block Then Throw "TInterface: unable to allocate memory for trampoline"
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

Function NewError()
	RuntimeError "TInterface: do not attempt to call New on an object through its interface; use New on the underlying instance"
End Function

Public

