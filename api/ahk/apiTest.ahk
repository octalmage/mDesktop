#SingleInstance, off	;allow multiple instances

	target := "mDesktop_api"
	stress := 1000,   x:=800
	;========================

	Gui, +LastFound	  +AlwaysOnTop
	hScript := WinExist() + 0

	Gui, Font, s10
	Gui, Add, Edit,		 vMyMsg  w200 , SwitchToDesktop2
	Gui, Add, Edit,  x+0 vMyPort w50, 100

	Gui, Font, s8
	Gui, Add, Button, x+5	gOnSend		  , Send

	Gui, Show, x%x%	AutoSize
	IPC_SetHandler("OnData")
return

OnData(Hwnd, Data, Port, Size) {
	global myLB

	if Size =
		 s = %Port%      Hwnd: %HWND%      Message: %Data%
	else {		  
		  x := NumGet(Data+0), y := NumGet(Data+4)
		  s = %Port%     Hwnd: %HWND%      Binary Data: POINT (%x%, %y%)      DataSize: %Size%
	}	
	GuiControl, , MyLB, %s%
}


OnSend:
detecthiddenwindows, on
	Gui, Submit, NoHide
	if !IPC_Send( WinExist( target ), MyMsg, MyPort)
		MsgBox Sending failed
return



GuiClose:
	ExitApp
return

#include IPC.ahk