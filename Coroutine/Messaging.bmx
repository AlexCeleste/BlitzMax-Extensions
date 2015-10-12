
' Inter-component messaging system

' There are two main ways controller components can communicate: by event, or by coroutine

' Events work similarly to Max's native events: an event is emitted and any subscribers out
' there can respond to it. However instead of hooking function pointers to event types, this
' system hooks object+method pairs (allowing for local state) to event IDs (since all of the
' events are EmitEventHook anyway). This reduces the amount of dispatch within receiving
' classes and allows for non-global subscription. Events are also tied to a given manager
' so in theory more than one event system could exist in parallel within the program.

' Coroutines are targeted calls to a specific object+method, not available to all listening
' subscribers. They are intended to be used to break up a long, potentially-blocking task
' across several frames, by pausing and coming back to it, or by deferring a call to another
' object+method. Coroutines cannot return a value directly; if they need to do so they are
' advised to package a "returnTo" coroutine in the arguments to post back. Coroutines are a
' great alternative to threading for achieving asynchronous operation.

' Coroutines are only enqueued; events can be emitted directly or enqueued.


Import BRL.Reflection

SuperStrict


Type EventManager Final
	Method Subscribe(o:Object, m:String, id:Int)
		Local meth:TMethod = TTypeId.ForObject(o).FindMethod(m)
		If meth
			Local idx:Int = IDReg.all.Length
			For Local r:Int = 0 Until IDReg.all.Length
				If IDReg.all[r].id = id
					idx = r ; Exit
				EndIf
			Next
			If idx = IDReg.all.Length Then IDReg.all :+ [New IDReg]
			Local reg:IDReg = IDReg.all[idx]
			reg.id = id ; reg.freq :+ 1
			reg.recv :+ [o] ; reg.meth :+ [meth] ; reg.mngr :+ [Self]
			If reg.freq > 1 Then IDReg.all.Sort()	'put more popular ids at the start of the list
		Else
			RuntimeError "nonexistent method '" + m + "' for object '" + o.ToString() + "'"
		EndIf
		
		If Not IDReg.Hooked
			AddHook(EmitEventHook, IDReg.HookF) ; IDReg.Hooked = True
		EndIf
	End Method
	Method Unsub(o:Object, id:Int)
		For Local r:Int = 0 Until IDReg.all.Length
			Local reg:IDReg = IDReg.all[r]
			If reg.id = id
				If reg.RemoveObj(o, Self)
					IDReg.all[r] = IDReg.all[IDReg.all.Length - 1]
					IDReg.all = IDReg.all[..IDReg.all.Length - 1]
				EndIf
				Return
			EndIf
		Next
	End Method
	Method UnsubAll(o:Object)
		Local ct:Int = 0
		For Local r:Int = 0 Until IDReg.all.Length
			Local reg:IDReg = IDReg.all[r]
			If reg.RemoveObj(o, Self)
				ct :+ 1
				IDReg.all[r] = IDReg.all[IDReg.all.Length - ct]
			EndIf
		Next
		If ct Then IDReg.all = IDReg.all[..IDReg.all.Length - ct]
	End Method
	
	Method CreateEvent:TEvent(id:Int, source:Object = Null, data:Int = 0, mods:Int = 0, x:Int = 0, y:Int = 0, extra:Object = Null) NoDebug
		Local e:ManagedEvent = New ManagedEvent
		e.id = id ; e.source = source ; e.data = data ; e.mods = mods ; e.x = x ; e.y = y ; e.extra = extra
		e.manager = Self
		Return e
	End Method
End Type

Function CreateEvent:TEvent(id:Int, source:Object = Null, data:Int = 0, mods:Int = 0, x:Int = 0, y:Int = 0, extra:Object = Null)
	RuntimeError "Code error: global CreateEvent is disabled. Please use BRL.Event.CreateEvent or EventManager.CreateEvent manually."
End Function

Type CoroutineQueue Final
	Field _queue:TList = CreateList()
	
	' push a coroutine to the queue of things to do
	' note that this doesn't "yield" in the conventional sense of ending the caller's execution - use sensibly
	Method Yield(c:Coroutine, args:Object[]) NoDebug
		_queue.AddLast(CoroInvocation.Make(c, args, MilliSecs() - 1))
	End Method
	Method YieldIn(c:Coroutine, wait:Int, args:Object[]) NoDebug
		_queue.AddLast(CoroInvocation.Make(c, args, MilliSecs() + wait))
	End Method
	
	' pop coroutine invocations off the queue until the duration is exceeded or there are no more
	' this is to support load balancing, to give the host a chance to interleave some event processing
	Method Run(duration:Int = 10) NoDebug
		Local i:CoroInvocation, target:Int = MilliSecs() + duration, skip:CoroInvocation = Null
		Repeat
			i = CoroInvocation(_queue.RemoveFirst())
			If skip And i = skip
				_queue.AddLast(i) ; Return
			ElseIf i <> Null
				If i.after < MilliSecs()
					i.coro.m.Invoke(i.coro.o, i.args)
				Else
					If skip = Null Then skip = i
					_queue.AddLast(i)
				EndIf
			Else
				Return
			EndIf
		Until MilliSecs() > target
	End Method
	
	Method Clear(c:Coroutine) NoDebug
		For Local ci:CoroInvocation = EachIn _queue
			If ci.coro = c Then _queue.Remove(ci)
		Next
	End Method
End Type

Type Coroutine Final
	Function Make:Coroutine(o:Object, m:String) NoDebug	'bind an object/method name pair into a callable object
		Local c:Coroutine = New Self
		c.o = o ; c.m = TTypeId.ForObject(o).FindMethod(m)
		If c.m Then Return c Else Return Null
	End Function
	Field o:Object, m:TMethod
End Type

Private

Type IDReg Final	'helper class for events
	Global all:IDReg[]
	Field id:Int, freq:Int, recv:Object[], meth:TMethod[], mngr:EventManager[]
	Method Compare:Int(with:Object) NoDebug
		Local w:IDReg = IDReg(with)
		If w = Null Then Return Super.Compare(with)
		If freq < w.freq Then Return -1 Else If freq = w.freq Then Return 0 Else Return 1
	End Method
	Method RemoveObj:Int(o:Object, m:EventManager)	'returns true if this registry is now empty
		Local ct:Int = 0
		For Local i:Int = 0 Until freq
			If recv[i] = o And mngr[i] = m
				ct :+ 1
				recv[i] = recv[freq - ct]
				meth[i] = meth[freq - ct]
				mngr[i] = mngr[freq - ct]
			EndIf
		Next
		If ct
			freq :- ct
			recv = recv[..freq]
			meth = meth[..freq]
			mngr = mngr[..freq]
		EndIf
		Return freq = 0
	End Method
	
	Global Hooked:Int = False	'message all objects subscribed to the emitted event ID
	Function HookF:Object(id:Int, data:Object, context:Object) NoDebug
		Local managed:ManagedEvent = ManagedEvent(data), manager:EventManager
		If managed Then manager = managed.manager
		id = TEvent(data).id	'want the event id, not the passed id
		Local arr:Object[] = [data]
		For Local i:Int = 0 Until all.Length
			Local reg:IDReg = all[i]
			If reg.id = id
				Local r:Int = 0
				While r < reg.freq  'can change mid-loop
					Local recv:Object = reg.recv[r]
					If reg.mngr[r] = manager Or manager = Null Then reg.meth[r].Invoke(recv, arr)
					r :+ (recv = reg.recv[r])
				Wend
				Exit
			EndIf
		Next
		Return data
	End Function
End Type

Type ManagedEvent Extends TEvent	'contains a tag so that only the originating manager attempts to respond to it
	Field manager:EventManager
End Type

Type CoroInvocation Final	'helper class representing a complete coroutine invocation (+ args and returnTo)
	Field coro:Coroutine, args:Object[], after:Int
	Function Make:CoroInvocation(c:Coroutine, a:Object[], after:Int) NoDebug
		Local i:CoroInvocation = New Self
		i.coro = c ; i.args = a ; i.after = after
		Return i
	End Function
End Type

Public

