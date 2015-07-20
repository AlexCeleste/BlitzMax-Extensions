
' Coroutine/messaging example

' in this example, AppHost creates two worker objects and manages the message/coroutine pump
' the two objects gradually work through their tasks concurrently, and send each other messages
' at certain points
' they then signal AppHost when they are done; when both are finished, it returns

Import "Messaging.bmx"
SuperStrict

New AppHost.Run()
Print "~ndone."
End

' define two types that receive both regular pings, and update themselves asynchronously
' they ping each other periodically as well

Type Foo
	Function Make:Foo(eMgr:EventManager, cq:CoroutineQueue, ev:EventTypes)
		Local f:Foo = New Self
		f.eMgr = eMgr ; f.cq = cq ; f.ev = ev
		
		eMgr.Subscribe(f, "onStart", ev.START)
		eMgr.Subscribe(f, "onTick", ev.REFRESH_TICK)
		eMgr.Subscribe(f, "fromBar", ev.B_TO_F)
		
		Return f
	End Function
	
	Field eMgr:EventManager, cq:CoroutineQueue, ev:EventTypes
	
	Method onStart(e:TEvent)
		Print "starting up Foo"
		cq.Yield(Coroutine.Make(Self, "doWork"), ["a"])
	End Method
	Method onTick(e:TEvent)
	'	Print "Foo responding to timer tick"
	End Method
	Method fromBar(e:TEvent)
		Print "Foo received message (" + e.data + ") from Bar"
	End Method
	
	Method doWork(s:String)
		Print "Foo: " + s
		If s[s.Length - 1] = "m"[0] Then PostEvent(eMgr.CreateEvent(ev.F_TO_B))
		If s[s.Length - 1] = "z"[0]
			PostEvent(eMgr.CreateEvent(ev.QUIT))
		Else
			s :+ Chr(s[s.Length - 1] + 1)
			cq.YieldIn(Coroutine.Make(Self, "doWork"), 250, [s])
		EndIf
	End Method
End Type

Type Bar
	Function Make:Bar(eMgr:EventManager, cq:CoroutineQueue, ev:EventTypes)
		Local b:Bar = New Self
		b.eMgr = eMgr ; b.cq = cq ; b.ev = ev
		
		eMgr.Subscribe(b, "onStart", ev.START)
		eMgr.Subscribe(b, "onTick", ev.REFRESH_TICK)
		eMgr.Subscribe(b, "fromFoo", ev.F_TO_B)
		
		Return b
	End Function
	
	Field eMgr:EventManager, cq:CoroutineQueue, ev:EventTypes
	
	Method onStart(e:TEvent)
		Print "starting up Bar"
		cq.Yield(Coroutine.Make(Self, "doWork"), ["0"])
	End Method
	Method onTick(e:TEvent)
	'	Print "Bar responding to timer tick"
	End Method
	Method fromFoo(e:TEvent)
		Print "Bar received message from Foo"
	End Method
	
	Method doWork(num:Int)
		Print "Bar: " + num
		If num Mod 10 = 0 Then PostEvent(eMgr.CreateEvent(ev.B_TO_F, Self, num))
		If num = 33
			PostEvent(eMgr.CreateEvent(ev.QUIT))
		Else
			num :+ 1
			cq.YieldIn(Coroutine.Make(Self, "doWork"), 200,  [String(num)])
		EndIf
	End Method
End Type

' Shared event type ids
Type EventTypes
	Method New()
		REFRESH_TICK = AllocUserEventId()
		START = AllocUserEventId() ; QUIT = AllocUserEventId()
		F_TO_B = AllocUserEventId() ; B_TO_F = AllocUserEventId()
	End Method
	Field REFRESH_TICK:Int
	Field START:Int, F_TO_B:Int, B_TO_F:Int, QUIT:Int
End Type

' Main application run loop
' coordinates the async operations of its component objects
Type AppHost
	' runtime
	Field eventMgr:EventManager
	Field coroQue:CoroutineQueue
	Field ping:TTimer
	
	' ops objects
	Field f:Foo, b:Bar
	Field ets:EventTypes
	
	Const REFRESH_RATE:Int = 30
	Field done:Int = False
	
	Method New()	'#TODO access controls
		eventMgr = New EventManager
		coroQue = New CoroutineQueue
		ets = New EventTypes
		ping = CreateTimer(REFRESH_RATE, eventMgr.CreateEvent(ets.REFRESH_TICK))
		
		f = Foo.Make(eventMgr, coroQue, ets)
		b = Bar.Make(eventMgr, coroQue, ets)
		
		eventMgr.Subscribe(Self, "onQuit", ets.QUIT)
		
		PostEvent(eventMgr.CreateEvent(ets.START))
	End Method
	
	Method onQuit(e:TEvent)
		done :+ 1
		Print "Host received a done signal (" + done +")"
	End Method
	
	Method Run() Final
		' rate is in hertz, 2 is an arbitrary safety buffer because response is still more important than saving cycles
		Const BUFFER:Int = 2
		Local wait:Int = Floor(1000.0 / REFRESH_RATE) - BUFFER
		AddHook(EmitEventHook, consumer)	'eat events at the end of processing so PollEvent can return 0 when done
		
		Repeat
			Local t:Int = MilliSecs()
			While PollEvent()
				EmitEvent(CurrentEvent)
			Wend
			coroQue.Run(wait - BUFFER)	'also allow some buffer here
			Delay wait - (MilliSecs() - t)
		Until done = 2
		
		RemoveHook(EmitEventHook, consumer)
		Function consumer:Object(id:Int, data:Object, context:Object)
			Return Null  'this swallows the end of the event queue, if we don't do this it stacks forever and overflows
		End Function
	End Method
End Type

