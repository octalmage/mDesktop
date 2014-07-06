; Initially created by Jason Stallings
; Updated by IamTheFij
; Source available https://github.com/octalmage/mDesktop


#NoEnv
#SingleInstance force

SetTitleMatchMode, 2

SetTitleMatchMode, slow
SetWorkingDir, %A_ScriptDir%\


SetBatchLines , -1
SetWinDelay , -1
WinClose, ahk_class SysShadow

#include Win.ahk

;Set this varible here to 0 to turn the gestures off.
gest=0


;These two have to do with the graphic desktop picker.

;Setting this varible to 0 will turn the switcher off.
;Having this on adds about 100% more mem usage.  (around 600k to 6000k)
switcher=0
;This is the amount of pixels between each window in the switcher.
spacing=25


;this is for the new api I'm working on.
api=0

/*

This is for having all windows show up in the taskbar/alt+tab.
This almost works, but is still having some major issues, I believe with the shellhook, and possible my "finddesktop_byid" function.
I need to find a quicker way to detect which desktop a window is on, maybe a new array? So instead of searching I can just do:

desktop:=win_desktop%win_id%

This might work.

*/
taskbar=0


; actual desktop switcher
;DO NOT ENABLE. Not working yet.
desktopswitcher=0



ABM_SETSTATE    := 10

ABS_NORMAL      := 0x0
ABS_AUTOHIDE    := 0x1
ABS_ALWAYSONTOP := 0x2

VarSetCapacity( APPBARDATA , 36, 0 ) 
Off :=  NumPut(  36, APPBARDATA    ) 
Off :=  NumPut( WinExist("ahk_class Shell_TrayWnd"), Off+0 )

 

;0x00000004 ABM_GETSTATE 




rc4key=[insertrc4key]

If switcher
{
	If !pToken := Gdip_Startup()
	{
		MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
		ExitApp
	}
}


If api
{
	hScript := WinExist() + 0
	IPC_SetHandler("OnData")
	gui 99: default
	gui, -caption +toolwindow
	gui, show, x0 y0 hide w0 h0,mDesktop_api
	gui 1: default
}

numDesktops := 4

gesttime:=800



onexit , cleanup
If !fileexist("swipe.ini")
{
	IniWrite , !^m, swipe.ini, Settings, unhide
	IniWrite , ^#RIGHT, swipe.ini, Settings, switchnext
	IniWrite , ^#LEFT, swipe.ini, Settings, switchprev
	IniWrite , 4, swipe.ini, Settings, numdesks
	IniWrite , !, swipe.ini, Settings, switchMod
	IniWrite , ^!, swipe.ini, Settings, sendmod
	IniWrite , 0, swipe.ini, Settings, crash
	IniWrite , %a_space%, swipe.ini, Settings, windowsOnAll
	IniWrite , 1, swipe.ini, Settings, desktopcircle
	
	
	
	
	

}

IniRead , unhidehotkey, swipe.ini, settings, unhide, !^s
IniRead , nexthotkey, swipe.ini, settings, switchnext, ^#RIGHT
IniRead , prevhotkey, swipe.ini, settings, switchprev, ^#LEFT
IniRead , numDesktops, swipe.ini, Settings, numdesks, 4
IniRead , switchModifier, swipe.ini, Settings, switchmod, !
IniRead , sendModifier, swipe.ini, Settings, sendmod, ^!
IniRead , crash, swipe.ini, Settings, crash
IniRead , windowsOnAll, swipe.ini, Settings, windowsOnAll
IniRead , desktopcircle, swipe.ini, Settings, desktopcircle


IniRead , theswitchmod, swipe.ini, Settings, theswitchmod,1
IniRead , thesendmod, swipe.ini, Settings, thesendmod,1
IniRead , thenextmod, swipe.ini, Settings, thenextmod,1
IniRead , thepremod, swipe.ini, Settings, thepremod,1
IniRead , rightaltkey, swipe.ini, Settings, rightaltkey,1


SysGet, VirtualScreenWidth, 78
SysGet, VirtualScreenHeight, 79
SysGet, MonitorCount, MonitorCount





If crash
{
	MsgBox, 4, , mDesktop crashed. Would you like to restore lost windows?

	IfMsgBox yes
	{
		FileRead, oldwindows, crash.dat
		Loop, Parse, oldwindows, |
		{
			winshow, ahk_id %A_LoopField%
		}
	}

}





filedelete, crash.dat

WinGet , backup, List,,, Program Manager

Loop, %backup%
{
	id := backup%A_Index%
	fileappend,%id%|, crash.dat
}
FileSetAttrib, +h , crash.dat
IniWrite , 1, swipe.ini, Settings, crash
crash=1

IniRead , runatstartup, swipe.ini, Settings, runatstartup, 0
Loop %numDesktops%
{
	IniRead , desktop%A_Index%, swipe.ini, Settings, desktop%A_Index%, Desktop %A_Index%
}

Hotkey , %unhidehotkey% , unhide
Hotkey , %unhidehotkey% , off

VarSetCapacity(wallpaper, 260)
DllCall("SystemParametersInfo", "Uint", 115, "Uint", 260, "str", wallpaper, "Uint", 0)

icons=0
curDesktop := 1

;TODO: Allow custom hotkeys.
If switcher
{
	Hotkey, f10, switcher
}


gosub buildmenu

PostMessage , 0x111, 28931,,, ahk_class Progman


;Gui 89: -Caption +ToolWindow +LastFound +AlwaysOnTop
;Gui 89: Add, Picture, x0 y0, banner.png
;Gui 89: Add, Text, x15 y5 w70 +BackgroundTrans vString

gosub sethotkeys

;!0::exitapp


PID := DllCall("GetCurrentProcessId")
EmptyMem(pid)


settimer, cleanmem, 450


;settimer, wait, -1

if taskbar
	SetTimer, checkactive, 250


GetCurrentWindows(1)


return



ShellMessage( wParam,lParam ) {
critical
		If (wParam=5) ;  HSHELL_WINDOWCREATED := 1
		{
		wID := NumGet( lParam+0 )         ; firstmember  ( DWord ) of SHELLHOOKINFO structure is hWnd
			WinGet, mState, MinMax, ahk_id %wID%
	
			
			
		SetFormat, Integer, Hex
; +0 ensures that temp will hold a hex integer value
lParam += 0
wID+=0
		
			switch:= win_desktop%wID%
					SetFormat, Integer, D
					StringTrimLeft, switch, switch, 2
				
					if not switch
						return
			SwitchToDesktop(switch)
			winactivate, ahk_id %wID%
			
		

		}
		return
	}
	
	
	
dec2hex(n) {
   oIF := A_FormatInteger
   SetFormat,Integer, hex
   n := StrLen(n+0) ? n+0 : n
   SetFormat,Integer, % oIF
   return n
}


OnData(Hwnd, Data, Port, Size) {
		IfInString, Data, SwitchToDesktop
		{
			StringRight, apiDesktop, Data, 1
			If apiDesktop is number
				SwitchToDesktop(apiDesktop)
		}
	}




MailslotRead(SlotHandle) ;reads one message at a time
	{
		global ReadBuffer  ;could/should be passed as ByRef parameter

		BytesToRead := 500

		DLLCall("ReadFile"
		        ,UInt, slotHandle   ;the handle from CreateMailSlot
		        ,str , readBuffer   ;see AHK DLLCall Help for why str used here
		        ,UInt, BytesToRead
		        ,UIntP, BytesActuallyRead
		        ,UInt, 0)   ;pointer to Overlapped structure, not used, so null

		If errorlevel
			Msgbox Error in ReadFile operation`nErrorLevel: %errorlevel%
		Else
			return BytesActuallyRead
	}



buildmenu:

	Ifexist , icons\%curDesktop%.ico
	{
		If numDesktops <=4
		{
			Menu, tray ,icon,icons\%curDesktop%o.ico
		}
		Else{
			Menu, tray ,icon,icons\%curDesktop%.ico
		}

	}
	menu ,tray, DeleteAll
	menu ,tray, NoStandard
	menu ,tray, NoStandard
	menu ,tray,add,Hide Icon,hideicon
	menu ,tray,add,
	menu ,tray,add,About,about
	menu ,tray,add,Settings,settings
	menu ,tray,add,
	Loop %numDesktops%
	{
		index = %A_Index%
		tempDesktop := desktop%A_Index%
		If StrLen(tempDesktop) < 1
		{
			tempDesktop = Desktop %A_Index%
			desktop%A_Index% := tempDesktop
		}
		menu , tray , add , %tempDesktop% , switchMenu
		If A_Index = %curDesktop%
		{
			menu ,tray,Check, %tempDesktop%
		}
	}
	menu ,tray,add,
	menu ,tray,add,Exit,CleanUp


return

checkactive:
hwnd := WinExist("A")

WinGetTitle, title , ahk_id %hwnd%

if (hwnd=active)
	return

	Loop, Parse, windowsOnAll, |,%A_Space%
			{
				If instr(title,a_loopfield)
				{
					return
					
				}
			}
	
active:=hwnd

switch:= win_desktop%active%
				;msgbox  %switch%
				
					if not switch
						return
						checkactive:=hwnd
			SwitchToDesktop(switch)
				winactivate, ahk_id %checkactive%
				checkactive:=

return


;This was added in to allow the user to click off of the picker, making it goaway.
;Need to find a better way to do this.
/*
~lbutton::
	sleep 200
	If switchergui
	{
		return
	}
	If switcheropen
	{
		gui 2: destroy
		gui 3: destroy
		gui 4: destroy
		gui 5: destroy
	}

return
*/

cleanmem:

	EmptyMem(pid)
return


usercanhazaccess(desk)
	{
		global rc4key
		If islocked(desk)
		{
			InputBox, password, This desktop is locked, Please enter your password:, HIDE, , , , , , 5
			iniread, dpassword, swipe.ini, Settings, passhex
			If not Password{
				return 0
			}

			dpassword:= RC4hex2txt(dpassword,rc4key)

			If (password=dpassword)
			{
				return 1
			}
			Else
			{
				msgbox Incorrect password!
				return 0
			}
		}
		Else
		{
			return 1
		}
	}



islocked(desk)
	{
		IniRead, locked, swipe.ini, Settings, locked%desk%, 0

		return 	locked
	}


sethotkeys:
#MaxThreadsPerHotkey 6
	Loop 10
	{
		If A_Index = 10
			index = 0
		Else
			index = %A_Index%

		Hotkey , %switchModifier%%index% , switch
		


		If A_Index <= %numDesktops%
			Hotkey , %switchModifier%%index% , on
		Else
			Hotkey , %switchModifier%%index% , off
	}
	Hotkey , %nexthotkey% , snext
	Hotkey , %prevhotkey% , sprev
#MaxThreadsPerHotkey 1
	Loop %numDesktops%
	{
		If A_Index = 10
			index = 0
		Else
			index = %A_Index%

		Hotkey , ~%sendModifier%%index% , sendTo

		If A_Index <= %numDesktops%
			Hotkey , ~%sendModifier%%index% , on
		Else
			Hotkey , ~%sendModifier%%index% , off
	}
return

hideicon:
	menu ,tray,NoIcon
	Hotkey , %unhidehotkey% , on
	StringReplace , DisplayKey, unhidehotkey, ^ , Control%a_space% , All
	StringReplace , DisplayKey, DisplayKey, ! , Alt%a_space% , All
	StringReplace , DisplayKey, DisplayKey, + ,Shift%a_space% , All
	msgbox The icon will now be hidden, press %DisplayKey% to unhide.
return

unhide:
	menu ,tray,Icon
	Hotkey , %unhidehotkey% , off
return

switch:


if (rightaltkey)
{
If getkeystate("ralt")
	{
		return
	}

}
		length := StrLen(A_ThisHotkey) - 1
		theDesk := SubStr(A_ThisHotkey, %length%)
		If theDesk = 0
			theDesk = 10
		SwitchToDesktop(theDesk)
	
return

sendTo:
	If getkeystate("ralt")
	{
		
		return
	}
		length := StrLen(A_ThisHotkey) - 1
		theDesk := SubStr(A_ThisHotkey, %length%)
		If theDesk = 0
			theDesk = 10
		SendActiveToDesktop(theDesk, curDesktop)

return

switchMenu:
	theDesk := A_ThisMenuItemPos - 5
	SwitchToDesktop(theDesk)
return

snext:
	SwitchToNextDesktop()
return

sprev:
	SwitchToPrevDesktop()
return

settings:
	Hotkey , %nexthotkey% , off
	Hotkey , %prevhotkey% , off
	ctrlKey = ^
	altKey = !
	winKey = #
	shiftKey = +

	Gui 7: Add, Tab2,h400, General|Desktop Names|Windows
	Gui 7: Tab, 1

	; Number of Desktops
	gui 7: add,text,,Number of Desktops (Max 10):
	gui 7: add,edit,w25 number vnewnumdesktops, %numDesktops%
	;gui 7: add,updown, Range1-10 vnewnumdesktops, %numDesktops%

	; Hide Tray icon
	gui 7: add,text,,Select a hotkey to unhide mDesktop's tray icon.
	gui 7: add,hotkey,vnewunhidehotkey, %unhidehotkey%
	Gui 7: Tab, 1
	; Modifiers for switch desktop
	gui 7: add,text,,To switch directly to a desktop:

	gui, 7: Tab, 1
	gui, 7: add, DropDownList ,w150 Choose%theswitchmod% vtheswitchmod altsubmit, Alt+Desktop Number|Ctrl+Desktop Number|Shift+Desktop Number|
	gui, 7: add, CheckBox,vrightaltkey checked%rightaltkey%, Ignore right alt key?

	gui, 7: add,text, yp+25 xm+12 ,To send an active window to a desktop:
	
	
	gui, 7: add, DropDownList,Choose%thesendmod% vthesendmod w150 altsubmit , Alt+Ctrl+Desktop Number|Shift+Alt+Desktop Number|Ctrl+Shift+Desktop Number|


	; Switch Next Hotkeys
	nexthaswin=UnChecked
	If InStr(nexthotkey, winKey)
	{
		nexthaswin=Checked
		StringReplace , cleannexthotkey, nexthotkey, # , , All
	}
	Else
	{
		cleannexthotkey := nexthotkey
	}
	gui 7: add,text,xm+12 yp+25 ,To switch to the next desktop:
	Gui 7: Add, DropDownList,altsubmit vthenextmod Choose%thenextmod% w150, Ctrl+Right Arrow|Shift+Right Arrow|Alt+Right Arrow|

	; Switch Prev Hotkeys
	prevhaswin=UnChecked
	If InStr(prevhotkey, winKey)
	{
		prevhaswin=Checked
		StringReplace , cleanprevhotkey, prevhotkey, # , , All
	}
	Else
	{
		cleanprevhotkey := prevhotkey
	}
	gui 7: add,text,xm+12 yp+25 ,To switch to the previous desktop:
	Gui 7: Add, DropDownList, vthepremod w150 altsubmit Choose%thepremod%, Ctrl+Left Arrow|Shift+Left Arrow|Alt+Left Arrow|
	If runatstartup
	{
		gui 7: add,checkbox,vrunatstartup checked, Run at Startup?
	}
	Else
	{
		gui 7: add,checkbox,vrunatstartup, Run at Startup?
	}
	If desktopcircle
	{
		gui 7: add,checkbox,vdesktopcircle checked, Desktop Cycling
	}
	Else
	{
		gui 7: add,checkbox,vdesktopcircle, Desktop Cycling
	}


	Gui 7: Tab, 2
	; Desktop Names

	gui 7: add,text,ym+26 xm+12,Name your desktops.


	namex=25
	namey=52
	locky:=52+4
	lockx=128
	Loop %numDesktops%
	{
		tempDesktop := desktop%A_Index%
		gui 7: add,edit,w100 x%namex% y%namey% vnewdesktop%A_Index% , %tempDesktop%
		namey+=25
	}
/*
	Loop %numDesktops%
	{
		If % locked%A_Index%
		{
			gui 7: add,Checkbox,y%locky% checked x%lockx% vlocked%A_Index%, Locked
		}
		Else
		{
			gui 7: add,Checkbox,y%locky%  x%lockx% vlocked%A_Index%, Locked
		}
		locky+=25

	}
	namey:=namey+10
	;Password Section
	gui 7: add,text,x%namex% y%namey%,Desktop Passowrd:
	namey+=20
	gui 7: add,edit,x%namex% w100 password y%namey% center vdpassword,  mdesktopwins
*/



	Gui 7: Tab, 3
	;Windows on all desktops
	Gui 7: Add, Text,,Windows on all desktops
	Gui 7: Add, ListView, -multi vwindowlist, Title

	Gui 7: Add, Button,gadd_window, Add
	Gui 7: Add, Button,yp xp+35 gselect, Select
	Gui 7: Add, Button,yp xp+46 gwindow_delete, Delete



	Gui 7: Tab, 1


	Gui 7: Tab,
	ControlGetPos , xx, yy, , hh, SysTabControl321,Settings
	buttony:=yy+hh+400
	gui 7: add,button, y418  x10 gsavesettings,Save
	gui +lastfound
	gui 7: show,, Settings
	settingid:=WinExist()
	gui 7: default
	Loop, Parse, windowsOnAll, |,%A_Space%
	{
		LV_Add("", a_loopfield)
	}
	gui 1: default






return

7guiclose:
	Hotkey, %nexthotkey% , on
	Hotkey, %prevhotkey% , on
	gui 7: destroy
return


select:
	sleep 100
	gui 97: default
	gui, -caption +toolwindow +alwaysontop
	gui,color,red
	gui, Add,text,,Please click a window to add to the list.
	gui,show,x25 y25

	KeyWait, lbutton,d

	wingetactivetitle, activetitle
	If not activetitle
		return
	gui 7: default
	LV_Add("", activetitle)
	gui 1: default
	gui 97: destroy
	WinActivate , ahk_id %settingid%
	activetitle=
return

window_delete:
	row:=LV_GetNext()
	LV_Delete(row)

return

savesettings:

	gui 7: submit

	; Save window on all desktops section.
	windowsOnAll=
	count:=LV_GetCount()
	Loop %count%
	{
		LV_GetText(RetrievedTitle, A_Index)
		windowsOnAll=%RetrievedTitle%|%windowsOnAll%
	}

	StringTrimRight, windowsonall, windowsonall, 1


	IniWrite , %windowsonall%, swipe.ini, Settings, windowsOnAll




	gui 7: destroy


IniWrite , %theswitchmod%, swipe.ini, settings, theswitchmod
IniWrite , %thesendmod%, swipe.ini, settings, thesendmod
IniWrite , %thenextmod%, swipe.ini, settings, thenextmod
IniWrite , %thepremod%, swipe.ini, settings, thepremod
IniWrite , %rightaltkey%, swipe.ini, settings, rightaltkey


if (thenextmod=1)
{
	newnexthotkey=^RIght
}
else if (thenextmod=2)
{
	newnexthotkey=+RIght
}
else if (thenextmod=3)
{
	newnexthotkey=!RIght
}


if (thepremod=1)
{
	newprevhotkey=^Left
}
else if (thepremod=2)
{
	newprevhotkey=+Left
}
else if (thepremod=3)
{
	newprevhotkey=!Left
}



; Set Switch Desktop Modifiers
if (theswitchmod=1)
{
	newSwitchModifier=!
}
else if (theswitchmod=2)
{
	newSwitchModifier=^
}
else if (theswitchmod=3)
{
	newSwitchModifier=+
}


If newSwitchModifier != %switchModifier%
{
	
	Loop 10
	{
		If A_Index = 10
			index = 0
		Else
			index = %A_Index%

	

			Hotkey , %switchModifier%%index% , off
	}
	

	switchModifier := newSwitchModifier
	IniWrite , %switchModifier%, swipe.ini, Settings, switchmod
}



; Set Send to Desktop Modifiers
if (thesendmod=1)
{
	newSendModifier=!^
}
else if (thesendmod=2)
{
	newSendModifier=+!
}
else if (thesendmod=3)
{
	newSendModifier=^+
}

	If newSendModifier != %SendModifier%
	{
		sendModifier := newSendModifier
		IniWrite , %sendModifier%, swipe.ini, Settings, sendmod
	}

	; Save unhide hotkey
	If newunhidehotkey!= %unhidehotkey%
	{
		Hotkey , %newunhidehotkey% , unhide
		Hotkey , %newunhidehotkey% , off
		unhidehotkey= %newunhidehotkey%
		IniWrite , %unhidehotkey%, swipe.ini, settings, unhide
	}

	; Rename desktops
	Loop %numDesktops%
	{
		newDesktop := newdesktop%A_Index%
		oldDesktop := desktop%A_Index%
		If newDesktop != %oldDesktop%
		{
			menu , tray, rename,  %oldDesktop%, %newDesktop%
			desktop%A_Index% := newDesktop
			IniWrite , %newDesktop%, swipe.ini, Settings, desktop%A_Index%
		}
	}

	; Set number of desktops
	If newnumdesktops > 10
		newnumdesktops := 10
	If newnumdesktops < 1
		newnumdesktops := 1
	If newnumdesktops != %numDesktops%
	{
		If newnumdesktops < %numDesktops%
		{
			If curDesktop > %newnumdesktops%
				SwitchToDesktop(newnumdesktops)

			index := (numDesktops - newnumdesktops)
			Loop , %index%
			{
				theDesk := numDesktops - A_Index + 1
				MoveAllWindows(theDesk, curDesktop)
			}
		}
		numDesktops = %newnumdesktops%
		IniWrite , %numDesktops%, swipe.ini, Settings , numdesks
		
	
		
		menu , tray , deleteall
		gosub buildmenu
	}


	
	If newnexthotkey!= %nexthotkey%
	{
		
		nexthotkey = %newnexthotkey%
		Hotkey , %nexthotkey% , snext
		IniWrite , %nexthotkey%, swipe.ini, settings, switchnext
	}

	If newprevhotkey!=%prevhotkey%
	{
		prevhotkey = %newprevhotkey%
		Hotkey , %prevhotkey% , sprev
		IniWrite , %prevhotkey%, swipe.ini, settings, switchprev
	}


	; Save run at startup
	If runatstartup=1
	{
		RegWrite, REG_SZ,HKCU,Software\Microsoft\Windows\CurrentVersion\Run,mDesktop, "%A_ScriptFullPath%"
	}
	Else
	{
		RegDelete, HKCU,Software\Microsoft\Windows\CurrentVersion\Run,mDesktop
	}
	iniwrite, %runatstartup%, swipe.ini, Settings, runatstartup
	iniwrite, %desktopcircle%, swipe.ini, Settings, desktopcircle



	
	Hotkey, %nexthotkey% , on
	Hotkey, %prevhotkey% , on


	gosub sethotkeys


return

add_window:
	InputBox, window , Add a window, Please type in part of the window title you would like to remain on all desktops.
	If not window
		return
	LV_Add("", window)


	window=
return

SwitchToNextDesktop()
	{
		global

		If (curDesktop < numDesktops)
		{
			SwitchToDesktop(curDesktop + 1)
		}
		Else
		{
			If desktopcircle
				SwitchToDesktop(1)
		}
		return
	}

SwitchToPrevDesktop()
	{
		global

		If (curDesktop > 1)
		{
			SwitchToDesktop(curDesktop - 1)
		}
		Else
		{
			If desktopcircle
				SwitchToDesktop(numDesktops)
		}
		return
	}

CheckDesktop(newDesktop)
	{
		global

		Loop %numDesktops%
		{
			tempDesktop := desktop%A_Index%
			If newDesktop = %A_Index%
				menu ,tray,Check, %tempDesktop%
			Else
				menu ,tray,Uncheck, %tempDesktop%
		}
		return
	}

SwitchToDesktop(newDesktop)
	{
		global
		activate_window :=
		If not usercanhazaccess(newDesktop)
		{
			return
		}
		

		Loop %numDesktops%
		{
			If A_Index = 10
				index = 0
			Else
				index = %A_Index%

			Hotkey , %switchModifier%%index% , off
		}

		If (curDesktop <> newDesktop)
		{
			;pBitmap%curDesktop% := Gdip_BitmapFromScreen(0)

			;sc_CaptureScreen(0, false, curDesktop . ".jpg", "20")

			CheckDesktop(newDesktop)
			GetCurrentWindows(curDesktop)
			
		
			WinGet, aid, ID, A
			if not (checkactive)
			{
				if not aid
					active_id%curDesktop%:=winexist("Program Manager")
				else
					active_id%curDesktop%:=aid
			}
			
			ShowHideWindows(curDesktop, false)
			ShowHideWindows(newDesktop, true)
			
			
			If desktopswitcher
			{
			showdesktop:=deskshow%newDesktop%
			showdesktopOLD:=deskshow%curDesktop%
			taskshow:=taskshow%newDesktop%
			recshow:=recshow%newDesktop%
			autohidetask:=autohidetask%newDesktop%
			if taskshow
				WinShow ahk_class Shell_TrayWnd
			else
				WinHide ahk_class Shell_TrayWnd
			
			autohidetask%curDesktop%:=DllCall("Shell32.dll\SHAppBarMessage", UInt,0x00000004 , UInt,&APPBARDATA ) 
			
			showdesktopname=showdesktop%curDesktop%
			
			
			ControlGet, showing, Visible , , SysListView321, ahk_class Progman
		showdesktop%curDesktop%:=showing
		showdesktopOLD:=deskshow%curDesktop%

			if recshow
					hiderecycle(0)
			else
				hiderecycle(1)
		
			
			if autohidetask=3
			{
				NumPut( ABS_AUTOHIDE|ABS_ALWAYSONTOP, Off+24 )
				DllCall("Shell32.dll\SHAppBarMessage", UInt,ABM_SETSTATE, UInt,&APPBARDATA )
			}
			else if autohidetask=2
			{
				NumPut( ABS_ALWAYSONTOP, Off+24 )
				DllCall("Shell32.dll\SHAppBarMessage", UInt,ABM_SETSTATE, UInt,&APPBARDATA ) 
			}
			
		
	
			if  not showdesktop
			{
				
				Control, Hide,, SysListView321, ahk_class Progman
			}
			else
			{
				Control, Show,, SysListView321, ahk_class Progman
			}
			
			
			
			
		
				
				If newdesktop=1
				{
					newpath := "`%USERPROFILE`%\Desktop"
				}
				Else
				{
					newpath := "`%USERPROFILE`%\Desktop"newdesktop
					tpath=C:\Documents and Settings\%A_Username%\Desktop%newdesktop%
		
					if not fileexist(tpath)
						filecreatedir, %tpath%
				}
				
				deskicon%curDesktop%:=DeskIcons()
				ChangeDesktop(newpath)
				newiconset:=deskicon%newdesktop%
			
				DeskIcons(newiconset)
			}
			
			
			

			activate_window := active_id%newDesktop%
			if not checkactive
			{
				if activate_window
					winactivate, ahk_id %activate_window%
				else
					winactivate, Program Manager
			}

			curDesktop := newDesktop

			;WinClose , ahk_class SysShadow
			; ShowBanner("Desktop: " newDesktop)
		}
		Loop %numDesktops%
		{
			If A_Index = 10
				index = 0
			Else
				index = %A_Index%

			Hotkey , %switchModifier%%index% , on
		}
		gosub buildmenu
		gosub, trashshadows
		sleep 100
	
		return
	}



ChangeDesktop(newPath)
	{
		Critical
		global tpath
		tpath := newPath




		hModule := DllCall("GetModuleHandle", "Str", "Shell32.dll")

		fAddress := DllCall("GetProcAddress", "uint", hModule, "uint", 231)

		r := DllCall(fAddress, "uint", 0x0010, "uint", 0, "uInt", 0, "ptr", &newPath)



		;DllCall("Shell32\SHChangeNotify",uint,0x8000000,uint,0x1000,uint,0,uint,0)

		DllCall("shell32\SHGetSpecialFolderLocation","uint",0,"uint", 0x0000, "uintP",ppidl)
		VarSetCapacity(name , 228)
		name=
		DllCall("shell32\SHGetPathFromIDList","uint",ppidl,"str",name)
		;DllCall("Shell32\SHChangeNotify",uint,0x00001000,uint,0,uint,ppidl,uint,0)


			DllCall("Shell32\SHChangeNotify",uint,0x8000000,uint,0x1000,uint,0,uint,0)
			;SendMessage, 0x1A, 42,,, ahk_id 0xFFFF
			
	}
	
	hiderecycle(status=1)
{
	rbStatNew = %status%
    rbStatClas = %status%
    RegWrite, REG_DWORD, HKCU, Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu, {645FF040-5081-101B-9F08-00AA002F954E}, %rbStatClas%
    RegWrite, REG_DWORD, HKCU, Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel, {645FF040-5081-101B-9F08-00AA002F954E}, %rbStatNew%
    PostMessage, 0x111, 28931,,, ahk_class Progman
	}


DeskIcons(coords="")
	{
		Critical
		static MEM_COMMIT := 0x1000, PAGE_READWRITE := 0x04, MEM_RELEASE := 0x8000
		static LVM_GETITEMPOSITION := 0x00001010, LVM_SETITEMPOSITION := 0x0000100F, WM_SETREDRAW := 0x000B

		ControlGet, hwWindow, HWND,, SysListView321, ahk_class Progman
		If !hwWindow ; #D mode
			ControlGet, hwWindow, HWND,, SysListView321, A
		IfWinExist ahk_id %hwWindow% ; last-found window set
			WinGet, iProcessID, PID
		hProcess := DllCall("OpenProcess"   , "UInt",   0x438         ; PROCESS-OPERATION|READ|WRITE|QUERY_INFORMATION
		        , "Int",   FALSE         ; inherit = false
		        , "UInt",   iProcessID)
		If hwWindow and hProcess
		{
			ControlGet, list, list,Col1
			If !coords
			{
				VarSetCapacity(iCoord, 8)
				pItemCoord := DllCall("VirtualAllocEx", "UInt", hProcess, "UInt", 0, "UInt", 8, "UInt", MEM_COMMIT, "UInt", PAGE_READWRITE)
				Loop, Parse, list, `n
				{
					SendMessage, %LVM_GETITEMPOSITION%, % A_Index-1, %pItemCoord%
					DllCall("ReadProcessMemory", "UInt", hProcess, "UInt", pItemCoord, "UInt", &iCoord, "UInt", 8, "UIntP", cbReadWritten)
					ret .= A_LoopField ":" (NumGet(iCoord) & 0xFFFF) | ((Numget(iCoord, 4) & 0xFFFF) << 16) "`n"
				}
				DllCall("VirtualFreeEx", "UInt", hProcess, "UInt", pItemCoord, "UInt", 0, "UInt", MEM_RELEASE)
			}
			Else
			{
				SendMessage, %WM_SETREDRAW%,0,0
				Loop, Parse, list, `n
					If RegExMatch(coords,"\Q" A_LoopField "\E:\K.*",iCoord_new)
						SendMessage, %LVM_SETITEMPOSITION%, % A_Index-1, %iCoord_new%
				SendMessage, %WM_SETREDRAW%,1,0
				ret := true
			}
		}
		DllCall("CloseHandle", "UInt", hProcess)
		return ret
	}


SendToDesktop(windowID, oldDesktop, newDesktop)
	{
		global

		WinGetClass , windowClass, ahk_id %windowID%

		If windowClass != "Shell_TrayWnd"
		{
			Loop %numDesktops%
			{
				If A_Index = 10
					index = 0
				Else
					index = %A_Index%

				Hotkey , %sendModifier%%index% , off
			}

			if(newDesktop!=oldDesktop)
			{
				RemoveWindowID(oldDesktop, windowID)

				windows%newDesktop% += 1
				i := windows%newDesktop%
				win_desktop%windowID%:=newDesktop
				windows%newDesktop%%i% := windowID
				If taskbar
				{
					 WinGetPos , tx, ty, tw, th, ahk_id %windowID%
					%windowID%x:=tx
					%windowID%y:=ty
					%windowID%w:=tw
					%windowID%h:=th
					 WinSet, Disable,, ahk_id %windowID%
					 WinSet, Transparent, 0, ahk_id %windowID%
					 Win_Move(windowID, 0, 0, 0, 0)
				}
				Else
				{
					WinHide , ahk_id %windowID%
				}
				;Send, {ALT DOWN}{TAB}{ALT UP}
			}
			winshow , Start

		Loop %numDesktops%
		{
			If A_Index = 10
				index = 0
			Else
				index = %A_Index%

			Hotkey , %sendModifier%%index% , on
		}


	}

}

SendActiveToDesktop(newDesktop,curDesktop)
	{
		WinGet , id, ID, A
		SendToDesktop(id, curDesktop, newDesktop)
	}

RemoveWindowID(desktopIdx, ID)
	{
		global
		Loop , % windows%desktopIdx%
		{
			If (windows%desktopIdx%%A_Index% = ID)
			{
				RemoveWindowID_byIndex(desktopIdx, A_Index)
				windows%desktopIdx%%A_Index%=
				Break
			}
		}
	}


FindDesktop_byId(ID)
	{
		global

		Loop %numdesktops%
		{
			this_index:=a_index
			Loop , % windows%this_index%
			{
				com_id:= % windows%this_index%%A_Index%

				If (id=com_id)
					return this_index

			}

		}


	}

RemoveWindowID_byIndex(desktopIdx, ID_idx)
	{
		global
		Loop , % windows%desktopIdx% - ID_idx
		{
			idx1 := % A_Index + ID_idx - 1
			idx2 := % A_Index + ID_idx
			windows%desktopIdx%%idx1% := windows%desktopIdx%%idx2%
		}
		windows%desktopIdx% -= 1
	}

GetCurrentWindows(index)
	{
		global
		
		
		emptyString =
		StringSplit, windows%index%, emptyString

		WinGet , windows%index%, List,,, Program Manager

		Loop, % windows%index%
		{
			id := % windows%index%%A_Index%
			
			fileappend, %id%`n, test.txt
			win_desktop%id%:=index
			
		   
	
			WinGetClass, windowClass, ahk_id %id%
			WinGetTitle, windowTitle, ahk_id %id%
			WinGet, minmax , minmax, ahk_id %id%
			testx:=%id%x
			If (testx and taskbar)
			{
				
				windows%index%%A_Index%=
				win_desktop%id%:=
			}
			If (windowClass = "Shell_TrayWnd")
			{
				windows%index%%A_Index%=
				win_desktop%id%:=
			}

			if (windowClass="Shell_SecondaryTrayWnd")
			{
				windows%index%%A_Index%=
				win_desktop%id%:=				
			}
			If (windowTitle = "Start" and windowClass="Button")
			{
				windows%index%%A_Index%=
				win_desktop%id%:=
			}
			
			
			;1BAD Day 1
			;Issue 43
			;Bring window to new desktop while dragging it.
			if (GetKeyState("LButton"))
			{
				MouseGetPos, , , MoveWin
				if (id=MoveWin)
				{
					windows%index%%A_Index%=
					win_desktop%id%:=
				}
			}
			
			
			this_idx:= A_Index
			
			Loop, Parse, windowsOnAll, |,%A_Space%
			{
				If instr(windowTitle,a_loopfield)
				{
					windows%index%%this_idx%=
					;win_desktop%id%:=
				}
			}
		}
	}

MoveAllWindows(oldDesktop, newDesktop)
	{
		global

		numWins := windows%oldDesktop%
		Loop , %numwins%
		{
			id := % windows%oldDesktop%%A_Index%
			SendToDesktop(id, oldDesktop, newDesktop)
		}

		ShowHideWindows(curDesktop, true)

		return
	}

ShowHideWindows(index, show)
	{
		global

		Loop , % windows%index%
		{	
			
			id := % windows%index%%A_Index%
			If show
			{
				If taskbar
				{
					WinSet, Enable,, ahk_id %id%
					Win_Move(id, %id%x, %id%y, %id%w, %id%h)
					%id%x:=
					%id%y:=
					%id%w:=
					%id%h:=
					WinSet, Transparent, off, ahk_id %id%
				}
				Else
				{
					WinShow , ahk_id %id%
				}

			}
			Else
			{
				If taskbar
				{
					 WinGetPos , tx, ty, tw, th, ahk_id %id%
					%id%x:=tx
					%id%y:=ty
					%id%w:=tw
					%id%h:=th
					 WinSet, Disable,, ahk_id %id%
					 WinSet, Transparent, 0, ahk_id %id%
					 
					Win_Move(id, 0, 0, 0, 0)
					
				}
				Else
				{
				
					WinHide , ahk_id %id%
					
				}
			}
		}
		return
	}

ActivateTopmost()
{
   WinGet, id, List
   Loop, %id%
   {
      id := id%A_Index%
      WinGet, a, Transparent, ahk_id %id%

      if a is not Integer
         a := "255"
      if (a!=0)
         break
   }
	
   ;WinActivate, ahk_id %id%
}


wait:
	{

		CoordMode, Pixel, Screen

		CoordMode, Mouse, Screen
		screenwidth:=A_ScreenWidth-1
		Loop
		{
			sleep 100
			MouseGetPos,xx
			If (xx=0)
			{
				ss=%ss%1
				StartTime1 := A_TickCount
				;loop
				{
					MouseGetPos,xx
					If xx<>0
						break
				}
		}
		Else If (xx=>screenwidth)
		{
			ss=%ss%2
			starttime2:=A_TickCount
			Loop
			{
				MouseGetPos,xx
				If xx<>%screenwidth%
					break
			}
		}
		StringRight, check, ss, 2
		If check=12
		{
			If not gest=0
			{

				timelapse:=A_TickCount- starttime1

				If timelapse<%gesttime%
				{
					SwitchToNextDesktop()
				}

			}
			check=
			ss=

		}
		Else If check=21
		{

			If not gest=0
			{
				timelapse:=  A_TickCount-starttime2

				If timelapse<%gesttime%
				{

					SwitchToPrevDesktop()

				}
			}
			check=
			ss=

		}
	}
check=
ss=

}
return

change:
	{
		PostMessage , 0x111, 28931,,, ahk_class Progman
		SetTimer , change, Off
	}
return

CleanUp:
	;IniWrite , %hidinglevel%, swipe.ini, Settings, level
	IniWrite , 0, swipe.ini, Settings, crash
	filedelete, crash.dat
	Loop , %numDesktops%
	{
		if desktopswitcher
		{
			logiconset:=deskicon%a_index%
			logiconsetname=deskicon%a_index%
			logiconset:=inize(logiconset)
			IniWrite , %logiconset%, swipe.ini, Settings, %logiconsetname%
			logdeskshow:=deskshow%a_index%
			logdeskshowname=deskshow%a_index%
			IniWrite , %logdeskshow%, swipe.ini, Settings, %logdeskshowname%
			logtaskshow:=taskshow%a_index%
			logtaskshowname=taskshow%a_index%
			IniWrite , %logtaskshow%, swipe.ini, Settings, %logtaskshowname%
			logautohidetask:=autohidetask%a_index%
			logautohidetaskname=autohidetask%a_index%
			IniWrite , %logautohidetask%, swipe.ini, Settings, %logautohidetaskname%
			logrecshow:=recshow%a_index%
			logrecshowname=recshow%a_index%
			IniWrite , %logrecshow%, swipe.ini, Settings, %logrecshowname%
			
			
		}
		ShowHideWindows(A_Index, true)
	
	}
	ExitApp

about:
	gui 2:add,text,,mDesktop
	gui 2:add,text,,Version: 1.6 Beta 4
	gui 2:add,text,,By: Jason Stallings
	gui 2:add,text,cblue ggourl,code.google.com/p/mdesktop/
	gui 2:add,text,,Enhancements by: Ian Fijolek
	gui 2:show
return

gourl:
	run http://code.google.com/p/mdesktop/
return

ShowBanner(Text)
	{
		Gui 89: hide
		SysGet, Workspace, MonitorWorkArea
		Trans := 255
		Gui 89: -Caption +ToolWindow +LastFound +AlwaysOnTop +Border
		Gui 89: Show, Hide
		Global GUI_ID ;Is this the proper way to use Global? I need it for TP_Fade...
		GUI_ID := WinExist()
		WinGetPos, GUIX, GUIY, GUIWidth, GUIHeight, ahk_id %GUI_ID%
		NewX := WorkSpaceRight-GUIWidth-5
		NewY := WorkspaceBottom-GUIHeight-5



		GuiControl , Text, String, %Text%

		Gui 89:  Show,x%NewX% y%NewY% h24 w92 NoActivate, MyTransparentBanner
		WinSet , Transparent, %Trans%, MyTransparentBanner
		Sleep 500

		Loop
		{
			if(Trans <= 0)
			{
				Trans := 0
				WinSet , Transparent, %Trans%, MyTransparentBanner
				break
			}

			WinSet , Transparent, %Trans%, MyTransparentBanner
		Trans := Trans - 5
		Sleep , 10
	}

return
}

trashshadows:
	Loop
	{
		If not WinExist("ahk_class SysShadow")
		{
			break
		}
		winkill,ahk_class SysShadow
	}

return

EmptyMem(pid){
		pid:=(pid) ? DllCall("GetCurrentProcessId") : pid
		h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
		DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
		DllCall("CloseHandle", "Int", h)
	}

; Uncomment for quick reload while programing

/*
#r::
	Reload
return
*/





;This is making the required guis for the Switcher, could probably combine these into one in my new fuction.
switchermake:

	Gui, 2: -Caption +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
	Gui, 2: Show, NA
	hwnd2 := WinExist()
	Gui, 3: -Caption +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
	Gui, 3: Show, NA
	hwnd3 := WinExist()

	Gui, 4: -Caption +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
	Gui, 4: Show, NA
	hwnd4 := WinExist()
	Gui, 5: -Caption +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
	Gui, 5: Show, NA
	hwnd5 := WinExist()

	SysGet, VirtualScreenHeight, 79
	SysGet, VirtualScreenWidth, 78

	Ratio := VirtualScreenWidth/VirtualScreenHeight
	Width := 600, Height := Width*(1/Ratio)

	y1:=(A_ScreenHeight/2) - height - spacing
	y1:=Round(y1)
	x1:=(A_Screenwidth/2) - width - spacing
	x1:=Round(x1)


return

switcher:
	pBitmap%curDesktop% := Gdip_BitmapFromScreen(0)
	;sc_CaptureScreen(0, false, curDesktop . ".jpg", "20")
	gosub switchermake

	pBitmap1:= drawonwallpaper(wallpaper,1)
	Gui, 2: hide
	Gui, 3: hide
	Gui, 4: hide
	Gui, 5: hide
	drawscreenshot(1, x1, y1,hwnd2,pBitmap1)

	pBitmap2:= drawonwallpaper(wallpaper,2)
	drawscreenshot(2, x1+width+spacing, y1,hwnd3,pBitmap2)

	pBitmap3:= drawonwallpaper(wallpaper,3)
	drawscreenshot(3, x1, y1+height+spacing,hwnd4,pBitmap3)

	pBitmap4:= drawonwallpaper(wallpaper,4)
	drawscreenshot(4, x1+width+spacing, y1+height+spacing,hwnd5,pBitmap4)
	Gui, 2: show
	Gui, 3: show
	Gui, 4: show
	Gui, 5: show
	OnMessage(0x201, "WM_LBUTTONDOWN")
	switcheropen=1

return



drawscreenshot(desk,shot_x, shot_y,hwnd2,pBitmap)
	{
		;file=%A_ScriptDir%\%desk%.jpg


		OriginalWidth := Gdip_GetImageWidth(pBitmap), OriginalHeight := Gdip_GetImageHeight(pBitmap)
		Ratio := OriginalWidth/OriginalHeight

		Width := 600, Height := Width*(1/Ratio)
		hbm := CreateDIBSection(600, 600)

		hdc := CreateCompatibleDC()


		obm := SelectObject(hdc, hbm)

		G := Gdip_GraphicsFromHDC(hdc), Gdip_SetInterpolationMode(G, 7)

		Gdip_DrawImage(G, pBitmap, 0, 0, Width, Height, 0, 0, OriginalWidth, OriginalHeight)
		DetectHiddenWindows, on
		UpdateLayeredWindow(hwnd2, hdc, shot_x, shot_y, Width, Height)
		DetectHiddenWindows, off
		SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)

		Gdip_DeleteGraphics(G)
		Gdip_DisposeImage(pBitmap)

		return
	}


drawonwallpaper(wallpaper,desktop)
	{
		global windows1
		global windows2
		global windows3
		global windows4
		global windowsonall
		global MonitorCount
		global VirtualScreenHeight
		global VirtualScreenWidth
		global curdesktop





		desktopshot := Gdip_CreateBitmap(VirtualScreenWidth, VirtualScreenHeight)
		G := Gdip_GraphicsFromImage(desktopshot)

		;wallfile := Gdip_CreateBitmapFromFile(wallpaper)




		If (desktop=curdesktop)
			pBrush3 := Gdip_BrushCreateSolid(0xff666666)
		Else
			pBrush3 := Gdip_BrushCreateSolid(0xff333333)

		Gdip_FillRectangle(G, pBrush3, 0, 0, a_screenwidth, a_screenheight)

		Gdip_FillRectangle(G, pBrush3, 0, 0, VirtualScreenWidth, VirtualScreenHeight)

		;wallfile := Gdip_BitmapFromHWND(hwnd)
		Width := Gdip_GetImageWidth(wallfile), Height := Gdip_GetImageHeight(wallfile)

		;loop %monitorcount%
		;{

		;wallx:=A_ScreenWidth*(a_index-1)
		;Gdip_DrawImage(G, wallfile, wallx, 0, a_screenwidth, a_screenheight, 0, 0, Width, Height)
		;	}




		Font = Arial

		If !hFamily := Gdip_FontFamilyCreate(Font)
		{
			MsgBox, 48, Font error!, The font you have specified does not exist on the system
			ExitApp
		}
		; Delete font family as we now know the font does exist
		Gdip_DeleteFontFamily(hFamily)

		pBrush := Gdip_BrushCreateSolid(0xffc0c0c0)
		pBrush2 := Gdip_BrushCreateSolid(0xff000000)

		pPen := Gdip_CreatePen(0xff000000, 5)


		thistime=0
		times:=% windows%desktop%
		Loop , %times%
		{

			id := % windows%desktop%%times%
			DetectHiddenWindows, On
			;win1 := sGdip_BitmapFromHWND(id)
			WinGetPos , wx, wy, ww, wh, ahk_id %id%

			WinGettitle, title, ahk_id %id%


			If title=""
			{
				continue
			}
			DetectHiddenWindows, off
			pw:=ww-5
			;Gdip_DrawImage(G, win1, wx, wy, ww, wh, 0, 0, ww, wh)
			Gdip_FillRectangle(G, pBrush, wx, wy, ww, wh)
			Gdip_FillRectangle(G, pBrush2, wx, wy, ww, 30)
			Gdip_DrawRectangle(G, pPen, wx, wy, pw, wh)
			tx:=wx+5
			ty:=wy+5
			Options = x%tx% y%ty%   cffffffff r1 s20
			Gdip_TextToGraphics(G, title, Options, Font, ww, wh)
			Gdip_DisposeImage(win1)
			times--
		}

		Loop, Parse, windowsOnAll, |,%A_Space%
		{

			DetectHiddenWindows, On
			WinGet, id , id, %a_loopfield%
			;win1 := sGdip_BitmapFromHWND(id)
			WinGetPos , wx, wy, ww, wh, ahk_id %id%

			WinGettitle, title, ahk_id %id%

			If ww=0
			{
				continue
			}
			DetectHiddenWindows, off
			pw:=ww-5
			;Gdip_DrawImage(G, win1, wx, wy, ww, wh, 0, 0, ww, wh)
			Gdip_FillRectangle(G, pBrush, wx, wy, ww, wh)
			Gdip_FillRectangle(G, pBrush2, wx, wy, ww, 30)
			Gdip_DrawRectangle(G, pPen, wx, wy, pw, wh)
			tx:=wx+5
			ty:=wy+5
			Options = x%tx% y%ty%   cff000000 r1 s20
			Gdip_TextToGraphics(G, title, Options, Font, ww, wh)
			Gdip_DisposeImage(win1)
			times--
		}
		;Gdip_SaveBitmapToFile(desktopshot, "FinalImage.png")
		return desktopshot
	}

inize(var, flag=0)
{
	if not flag
	{
		StringReplace, var, var, `r`n , |, All
		StringReplace, var, var, `n , |, All
	}
	else
	{
		StringReplace, var, var, |,`n , All
	}

	return %var%

}

WM_LBUTTONDOWN()
	{
		switchergui=1
		desktopp:=A_Gui-1


		gui 2: destroy
		gui 3: destroy
		gui 4: destroy
		gui 5: destroy

		SwitchToDesktop(desktopp)
		switcheropen=0
		switchergui=0
	}




; Gdip standard library v1.38 by tic (Tariq Porter) 28/08/10
;
;#####################################################################################
;#####################################################################################
; STATUS ENUMERATION
; Return values for functions specified to have status enumerated return type
;#####################################################################################
;
; Ok =						= 0
; GenericError				= 1
; InvalidParameter			= 2
; OutOfMemory				= 3
; ObjectBusy				= 4
; InsufficientBuffer		= 5
; NotImplemented			= 6
; Win32Error				= 7
; WrongState				= 8
; Aborted					= 9
; FileNotFound				= 10
; ValueOverflow				= 11
; AccessDenied				= 12
; UnknownImageFormat		= 13
; FontFamilyNotFound		= 14
; FontStyleNotFound			= 15
; NotTrueTypeFont			= 16
; UnsupportedGdiplusVersion	= 17
; GdiplusNotInitialized		= 18
; PropertyNotFound			= 19
; PropertyNotSupported		= 20
; ProfileNotFound			= 21
;
;#####################################################################################
;#####################################################################################
; FUNCTIONS
;#####################################################################################
;
; UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255)
; BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster="")
; StretchBlt(dDC, dx, dy, dw, dh, sDC, sx, sy, sw, sh, Raster="")
; SetImage(hwnd, hBitmap)
; Gdip_BitmapFromScreen(Screen=0, Raster="")
; CreateRectF(ByRef RectF, x, y, w, h)
; CreateSizeF(ByRef SizeF, w, h)
; CreateDIBSection
;
;#####################################################################################

; Function:     			UpdateLayeredWindow
; Description:  			Updates a layered window with the handle to the DC of a gdi bitmap
;
; hwnd        				Handle of the layered window to update
; hdc           			Handle to the DC of the GDI bitmap to update the window with
; Layeredx      			x position to place the window
; Layeredy      			y position to place the window
; Layeredw      			Width of the window
; Layeredh      			Height of the window
; Alpha         			Default = 255 : The transparency (0-255) to set the window transparency
;
; return      				If the function succeeds, the return value is nonzero
;
; notes						If x or y omitted, then layered window will use its current coordinates
;							If w or h omitted then current width and height will be used

UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255)
	{
		If ((x != "") && (y != ""))
			VarSetCapacity(pt, 8), NumPut(x, pt, 0), NumPut(y, pt, 4)

		If (w = "") ||(h = "")
			WinGetPos,,, w, h, ahk_id %hwnd%

		return DllCall("UpdateLayeredWindow", "uint", hwnd, "uint", 0, "uint", ((x = "") && (y = "")) ? 0 : &pt
		        , "int64*", w|h<<32, "uint", hdc, "int64*", 0, "uint", 0, "uint*", Alpha<<16|1<<24, "uint", 2)
	}

;#####################################################################################

; Function				BitBlt
; Description			The BitBlt function performs a bit-block transfer of the color data corresponding to a rectangle
;						of pixels from the specified source device context into a destination device context.
;
; dDC					handle to destination DC
; dx					x-coord of destination upper-left corner
; dy					y-coord of destination upper-left corner
; dw					width of the area to copy
; dh					height of the area to copy
; sDC					handle to source DC
; sx					x-coordinate of source upper-left corner
; sy					y-coordinate of source upper-left corner
; Raster				raster operation code
;
; return				If the function succeeds, the return value is nonzero
;
; notes					If no raster operation is specified, then SRCCOPY is used, which copies the source directly to the destination rectangle
;
; BLACKNESS				= 0x00000042
; NOTSRCERASE			= 0x001100A6
; NOTSRCCOPY			= 0x00330008
; SRCERASE				= 0x00440328
; DSTINVERT				= 0x00550009
; PATINVERT				= 0x005A0049
; SRCINVERT				= 0x00660046
; SRCAND				= 0x008800C6
; MERGEPAINT			= 0x00BB0226
; MERGECOPY				= 0x00C000CA
; SRCCOPY				= 0x00CC0020
; SRCPAINT				= 0x00EE0086
; PATCOPY				= 0x00F00021
; PATPAINT				= 0x00FB0A09
; WHITENESS				= 0x00FF0062
; CAPTUREBLT			= 0x40000000
; NOMIRRORBITMAP		= 0x80000000

BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster="")
	{
		return DllCall("gdi32\BitBlt", "uint", dDC, "int", dx, "int", dy, "int", dw, "int", dh
		        , "uint", sDC, "int", sx, "int", sy, "uint", Raster ? Raster : 0x00CC0020)
	}

;#####################################################################################

; Function				StretchBlt
; Description			The StretchBlt function copies a bitmap from a source rectangle into a destination rectangle,
;						stretching or compressing the bitmap to fit the dimensions of the destination rectangle, if necessary.
;						The system stretches or compresses the bitmap according to the stretching mode currently set in the destination device context.
;
; ddc					handle to destination DC
; dx					x-coord of destination upper-left corner
; dy					y-coord of destination upper-left corner
; dw					width of destination rectangle
; dh					height of destination rectangle
; sdc					handle to source DC
; sx					x-coordinate of source upper-left corner
; sy					y-coordinate of source upper-left corner
; sw					width of source rectangle
; sh					height of source rectangle
; Raster				raster operation code
;
; return				If the function succeeds, the return value is nonzero
;
; notes					If no raster operation is specified, then SRCCOPY is used. It uses the same raster operations as BitBlt

StretchBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, sw, sh, Raster="")
	{
		return DllCall("gdi32\StretchBlt", "uint", ddc, "int", dx, "int", dy, "int", dw, "int", dh
		        , "uint", sdc, "int", sx, "int", sy, "int", sw, "int", sh, "uint", Raster ? Raster : 0x00CC0020)
	}

;#####################################################################################

; Function				SetStretchBltMode
; Description			The SetStretchBltMode function sets the bitmap stretching mode in the specified device context
;
; hdc					handle to the DC
; iStretchMode			The stretching mode, describing how the target will be stretched
;
; return				If the function succeeds, the return value is the previous stretching mode. If it fails it will return 0
;
; STRETCH_ANDSCANS 		= 0x01
; STRETCH_ORSCANS 		= 0x02
; STRETCH_DELETESCANS 	= 0x03
; STRETCH_HALFTONE 		= 0x04

SetStretchBltMode(hdc, iStretchMode=4)
	{
		return DllCall("gdi32\SetStretchBltMode", "uint", hdc, "int", iStretchMode)
	}

;#####################################################################################

; Function				SetImage
; Description			Associates a new image with a static control
;
; hwnd					handle of the control to update
; hBitmap				a gdi bitmap to associate the static control with
;
; return				If the function succeeds, the return value is nonzero

SetImage(hwnd, hBitmap)
	{
		SendMessage, 0x172, 0x0, hBitmap,, ahk_id %hwnd%
		E := ErrorLevel
		DeleteObject(E)
		return E
	}

;#####################################################################################

; Function				SetSysColorToControl
; Description			Sets a solid colour to a control
;
; hwnd					handle of the control to update
; SysColor				A system colour to set to the control
;
; return				If the function succeeds, the return value is zero
;
; notes					A control must have the 0xE style set to it so it is recognised as a bitmap
;						By default SysColor=15 is used which is COLOR_3DFACE. This is the standard background for a control
;
; COLOR_3DDKSHADOW				= 21
; COLOR_3DFACE					= 15
; COLOR_3DHIGHLIGHT				= 20
; COLOR_3DHILIGHT				= 20
; COLOR_3DLIGHT					= 22
; COLOR_3DSHADOW				= 16
; COLOR_ACTIVEBORDER			= 10
; COLOR_ACTIVECAPTION			= 2
; COLOR_APPWORKSPACE			= 12
; COLOR_BACKGROUND				= 1
; COLOR_BTNFACE					= 15
; COLOR_BTNHIGHLIGHT			= 20
; COLOR_BTNHILIGHT				= 20
; COLOR_BTNSHADOW				= 16
; COLOR_BTNTEXT					= 18
; COLOR_CAPTIONTEXT				= 9
; COLOR_DESKTOP					= 1
; COLOR_GRADIENTACTIVECAPTION	= 27
; COLOR_GRADIENTINACTIVECAPTION	= 28
; COLOR_GRAYTEXT				= 17
; COLOR_HIGHLIGHT				= 13
; COLOR_HIGHLIGHTTEXT			= 14
; COLOR_HOTLIGHT				= 26
; COLOR_INACTIVEBORDER			= 11
; COLOR_INACTIVECAPTION			= 3
; COLOR_INACTIVECAPTIONTEXT		= 19
; COLOR_INFOBK					= 24
; COLOR_INFOTEXT				= 23
; COLOR_MENU					= 4
; COLOR_MENUHILIGHT				= 29
; COLOR_MENUBAR					= 30
; COLOR_MENUTEXT				= 7
; COLOR_SCROLLBAR				= 0
; COLOR_WINDOW					= 5
; COLOR_WINDOWFRAME				= 6
; COLOR_WINDOWTEXT				= 8

SetSysColorToControl(hwnd, SysColor=15)
	{
		WinGetPos,,, w, h, ahk_id %hwnd%
		bc := DllCall("GetSysColor", "Int", SysColor)
		pBrushClear := Gdip_BrushCreateSolid(0xff000000 | (bc >> 16 | bc & 0xff00 | (bc & 0xff) << 16))
		pBitmap := Gdip_CreateBitmap(w, h), G := Gdip_GraphicsFromImage(pBitmap)
		Gdip_FillRectangle(G, pBrushClear, 0, 0, w, h)
		hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
		SetImage(hwnd, hBitmap)
		Gdip_DeleteBrush(pBrushClear)
		Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
		return 0
	}

;#####################################################################################

; Function				Gdip_BitmapFromScreen
; Description			Gets a gdi+ bitmap from the screen
;
; Screen				0 = All screens
;						Any numerical value = Just that screen
;						x|y|w|h = Take specific coordinates with a width and height
; Raster				raster operation code
;
; return      			If the function succeeds, the return value is a pointer to a gdi+ bitmap
;						-1:		one or more of x,y,w,h not passed properly
;
; notes					If no raster operation is specified, then SRCCOPY is used to the returned bitmap

Gdip_BitmapFromScreen(Screen=0, Raster="")
	{
		If (Screen = 0)
		{
			Sysget, x, 76
			Sysget, y, 77
			Sysget, w, 78
			Sysget, h, 79
		}
		Else If (Screen&1 != "")
		{
			Sysget, M, Monitor, %Screen%
			x := MLeft, y := MTop, w := MRight-MLeft, h := MBottom-MTop
		}
		Else
		{
			StringSplit, S, Screen, |
			x := S1, y := S2, w := S3, h := S4
		}

		If (x = "") || (y = "") || (w = "") || (h = "")
			return -1

		chdc := CreateCompatibleDC(), hbm := CreateDIBSection(w, h, chdc), obm := SelectObject(chdc, hbm), hhdc := GetDC()
		BitBlt(chdc, 0, 0, w, h, hhdc, x, y, Raster)
		ReleaseDC(hhdc)

		pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
		SelectObject(hhdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
		return pBitmap
	}

;#####################################################################################

; Function				Gdip_BitmapFromHWND
; Description			Uses PrintWindow to get a handle to the specified window and return a bitmap from it
;
; hwnd					handle to the window to get a bitmap from
;
; return				If the function succeeds, the return value is a pointer to a gdi+ bitmap
;
; notes					Window must not be not minimised in order to get a handle to it's client area

Gdip_BitmapFromHWND(hwnd)
	{
		WinGetPos,,, Width, Height, ahk_id %hwnd%
		hbm := CreateDIBSection(Width, Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
		PrintWindow(hwnd, hdc)
		pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
		SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
		return pBitmap
	}
;#####################################################################################

; Function    			CreateRectF
; Description			Creates a RectF object, containing a the coordinates and dimensions of a rectangle
;
; RectF       			Name to call the RectF object
; x            			x-coordinate of the upper left corner of the rectangle
; y            			y-coordinate of the upper left corner of the rectangle
; w            			Width of the rectangle
; h            			Height of the rectangle
;
; return      			No return value

CreateRectF(ByRef RectF, x, y, w, h)
	{
		VarSetCapacity(RectF, 16)
		NumPut(x, RectF, 0, "float"), NumPut(y, RectF, 4, "float"), NumPut(w, RectF, 8, "float"), NumPut(h, RectF, 12, "float")
	}
;#####################################################################################

; Function		    	CreateSizeF
; Description			Creates a SizeF object, containing an 2 values
;
; SizeF         		Name to call the SizeF object
; w            			w-value for the SizeF object
; h            			h-value for the SizeF object
;
; return      			No Return value

CreateSizeF(ByRef SizeF, w, h)
	{
		VarSetCapacity(SizeF, 8)
		NumPut(w, SizeF, 0, "float"), NumPut(h, SizeF, 4, "float")
	}
;#####################################################################################

; Function		    	CreatePointF
; Description			Creates a SizeF object, containing an 2 values
;
; SizeF         		Name to call the SizeF object
; w            			w-value for the SizeF object
; h            			h-value for the SizeF object
;
; return      			No Return value

CreatePointF(ByRef PointF, x, y)
	{
		VarSetCapacity(PointF, 8)
		NumPut(x, PointF, 0, "float"), NumPut(y, PointF, 4, "float")
	}
;#####################################################################################

; Function				CreateDIBSection
; Description			The CreateDIBSection function creates a DIB (Device Independent Bitmap) that applications can write to directly
;
; w						width of the bitmap to create
; h						height of the bitmap to create
; hdc					a handle to the device context to use the palette from
; bpp					bits per pixel (32 = ARGB)
; ppvBits				A pointer to a variable that receives a pointer to the location of the DIB bit values
;
; return				returns a DIB. A gdi bitmap
;
; notes					ppvBits will receive the location of the pixels in the DIB

CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0)
	{
		hdc2 := hdc ? hdc : GetDC()
		VarSetCapacity(bi, 40, 0)
		NumPut(w, bi, 4), NumPut(h, bi, 8), NumPut(40, bi, 0), NumPut(1, bi, 12, "ushort"), NumPut(0, bi, 16), NumPut(bpp, bi, 14, "ushort")
		hbm := DllCall("CreateDIBSection", "uint" , hdc2, "uint" , &bi, "uint" , 0, "uint*", ppvBits, "uint" , 0, "uint" , 0)

		If !hdc
			ReleaseDC(hdc2)
		return hbm
	}

;#####################################################################################

; Function				PrintWindow
; Description			The PrintWindow function copies a visual window into the specified device context (DC), typically a printer DC
;
; hwnd					A handle to the window that will be copied
; hdc					A handle to the device context
; Flags					Drawing options
;
; return				If the function succeeds, it returns a nonzero value
;
; PW_CLIENTONLY			= 1

PrintWindow(hwnd, hdc, Flags=0)
	{
		return DllCall("PrintWindow", "uint", hwnd, "uint", hdc, "uint", 0)
	}

;#####################################################################################

; Function				DestroyIcon
; Description			Destroys an icon and frees any memory the icon occupied
;
; hIcon					Handle to the icon to be destroyed. The icon must not be in use
;
; return				If the function succeeds, the return value is nonzero

DestroyIcon(hIcon)
	{
		return DllCall("DestroyIcon", "uint", hIcon)
	}

;#####################################################################################

PaintDesktop(hdc)
	{
		return DllCall("PaintDesktop", "uint", hdc)
	}

;#####################################################################################

CreateCompatibleBitmap(hdc, w, h)
	{
		return DllCall("gdi32\CreateCompatibleBitmap", "uint", hdc, "int", w, "int", h)
	}

;#####################################################################################

; Function				CreateCompatibleDC
; Description			This function creates a memory device context (DC) compatible with the specified device
;
; hdc					Handle to an existing device context
;
; return				returns the handle to a device context or 0 on failure
;
; notes					If this handle is 0 (by default), the function creates a memory device context compatible with the application's current screen

CreateCompatibleDC(hdc=0)
	{
		return DllCall("CreateCompatibleDC", "uint", hdc)
	}

;#####################################################################################

; Function				SelectObject
; Description			The SelectObject function selects an object into the specified device context (DC). The new object replaces the previous object of the same type
;
; hdc					Handle to a DC
; hgdiobj				A handle to the object to be selected into the DC
;
; return				If the selected object is not a region and the function succeeds, the return value is a handle to the object being replaced
;
; notes					The specified object must have been created by using one of the following functions
;						Bitmap - CreateBitmap, CreateBitmapIndirect, CreateCompatibleBitmap, CreateDIBitmap, CreateDIBSection (A single bitmap cannot be selected into more than one DC at the same time)
;						Brush - CreateBrushIndirect, CreateDIBPatternBrush, CreateDIBPatternBrushPt, CreateHatchBrush, CreatePatternBrush, CreateSolidBrush
;						Font - CreateFont, CreateFontIndirect
;						Pen - CreatePen, CreatePenIndirect
;						Region - CombineRgn, CreateEllipticRgn, CreateEllipticRgnIndirect, CreatePolygonRgn, CreateRectRgn, CreateRectRgnIndirect
;
; notes					If the selected object is a region and the function succeeds, the return value is one of the following value
;
; SIMPLEREGION			= 2 Region consists of a single rectangle
; COMPLEXREGION			= 3 Region consists of more than one rectangle
; NULLREGION			= 1 Region is empty

SelectObject(hdc, hgdiobj)
	{
		return DllCall("SelectObject", "uint", hdc, "uint", hgdiobj)
	}

;#####################################################################################

; Function				DeleteObject
; Description			This function deletes a logical pen, brush, font, bitmap, region, or palette, freeing all system resources associated with the object
;						After the object is deleted, the specified handle is no longer valid
;
; hObject				Handle to a logical pen, brush, font, bitmap, region, or palette to delete
;
; return				Nonzero indicates success. Zero indicates that the specified handle is not valid or that the handle is currently selected into a device context

DeleteObject(hObject)
	{
		return DllCall("DeleteObject", "uint", hObject)
	}

;#####################################################################################

; Function				GetDC
; Description			This function retrieves a handle to a display device context (DC) for the client area of the specified window.
;						The display device context can be used in subsequent graphics display interface (GDI) functions to draw in the client area of the window.
;
; hwnd					Handle to the window whose device context is to be retrieved. If this value is NULL, GetDC retrieves the device context for the entire screen
;
; return				The handle the device context for the specified window's client area indicates success. NULL indicates failure

GetDC(hwnd=0)
	{
		return DllCall("GetDC", "uint", hwnd)
	}

;#####################################################################################

; Function				ReleaseDC
; Description			This function releases a device context (DC), freeing it for use by other applications. The effect of ReleaseDC depends on the type of device context
;
; hdc					Handle to the device context to be released
; hwnd					Handle to the window whose device context is to be released
;
; return				1 = released
;						0 = not released
;
; notes					The application must call the ReleaseDC function for each call to the GetWindowDC function and for each call to the GetDC function that retrieves a common device context
;						An application cannot use the ReleaseDC function to release a device context that was created by calling the CreateDC function; instead, it must use the DeleteDC function.

ReleaseDC(hdc, hwnd=0)
	{
		return DllCall("ReleaseDC", "uint", hwnd, "uint", hdc)
	}

;#####################################################################################

; Function				DeleteDC
; Description			The DeleteDC function deletes the specified device context (DC)
;
; hdc					A handle to the device context
;
; return				If the function succeeds, the return value is nonzero
;
; notes					An application must not delete a DC whose handle was obtained by calling the GetDC function. Instead, it must call the ReleaseDC function to free the DC

DeleteDC(hdc)
	{
		return DllCall("DeleteDC", "uint", hdc)
	}
;#####################################################################################

; Function				Gdip_LibraryVersion
; Description			Get the current library version
;
; return				the library version
;
; notes					This is useful for non compiled programs to ensure that a person doesn't run an old version when testing your scripts

Gdip_LibraryVersion()
	{
		return 1.38
	}

;#####################################################################################

; Function:    			Gdip_BitmapFromBRA
; Description: 			Gets a pointer to a gdi+ bitmap from a BRA file
;
; BRAFromMemIn			The variable for a BRA file read to memory
; File					The name of the file, or its number that you would like (This depends on alternate parameter)
; Alternate				Changes whether the File parameter is the file name or its number
;
; return      			If the function succeeds, the return value is a pointer to a gdi+ bitmap
;						-1 = The BRA variable is empty
;						-2 = The BRA has an incorrect header
;						-3 = The BRA has information missing
;						-4 = Could not find file inside the BRA

Gdip_BitmapFromBRA(ByRef BRAFromMemIn, File, Alternate=0)
	{
		If !BRAFromMemIn
			return -1
		Loop, Parse, BRAFromMemIn, `n
		{
			If (A_Index = 1)
			{
				StringSplit, Header, A_LoopField, |
				If (Header0 != 4 || Header2 != "BRA!")
					return -2
			}
			Else If (A_Index = 2)
			{
				StringSplit, Info, A_LoopField, |
				If (Info0 != 3)
					return -3
			}
			Else
				break
		}
		If !Alternate
			StringReplace, File, File, \, \\, All
		RegExMatch(BRAFromMemIn, "mi`n)^" (Alternate ? File "\|.+?\|(\d+)\|(\d+)" : "\d+\|" File "\|(\d+)\|(\d+)") "$", FileInfo)
		If !FileInfo
			return -4

		hData := DllCall("GlobalAlloc", "uint", 2, "uint", FileInfo2)
		pData := DllCall("GlobalLock", "uint", hData)
		DllCall("RtlMoveMemory", "uint", pData, "uint", &BRAFromMemIn+Info2+FileInfo1, "uint", FileInfo2)
		DllCall("GlobalUnlock", "uint", hData)
		DllCall("ole32\CreateStreamOnHGlobal", "uint", hData, "int", 1, "uint*", pStream)
		DllCall("gdiplus\GdipCreateBitmapFromStream", "uint", pStream, "uint*", pBitmap)
		DllCall(NumGet(NumGet(1*pStream)+8), "uint", pStream)
		return pBitmap
	}

;#####################################################################################

; Function				Gdip_DrawRectangle
; Description			This function uses a pen to draw the outline of a rectangle into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; x						x-coordinate of the top left of the rectangle
; y						y-coordinate of the top left of the rectangle
; w						width of the rectanlge
; h						height of the rectangle
;
; return				status enumeration. 0 = success
;
; notes					as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width

Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
	{
		return DllCall("gdiplus\GdipDrawRectangle", "uint", pGraphics, "uint", pPen, "float", x, "float", y, "float", w, "float", h)
	}

;#####################################################################################

; Function				Gdip_DrawRoundedRectangle
; Description			This function uses a pen to draw the outline of a rounded rectangle into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; x						x-coordinate of the top left of the rounded rectangle
; y						y-coordinate of the top left of the rounded rectangle
; w						width of the rectanlge
; h						height of the rectangle
; r						radius of the rounded corners
;
; return				status enumeration. 0 = success
;
; notes					as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width

Gdip_DrawRoundedRectangle(pGraphics, pPen, x, y, w, h, r)
	{
		Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
		Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
		Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
		Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
		E := Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
		Gdip_ResetClip(pGraphics)
		Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
		Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
		Gdip_DrawEllipse(pGraphics, pPen, x, y, 2*r, 2*r)
		Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y, 2*r, 2*r)
		Gdip_DrawEllipse(pGraphics, pPen, x, y+h-(2*r), 2*r, 2*r)
		Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
		Gdip_ResetClip(pGraphics)
		return E
	}

;#####################################################################################

; Function				Gdip_DrawEllipse
; Description			This function uses a pen to draw the outline of an ellipse into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; x						x-coordinate of the top left of the rectangle the ellipse will be drawn into
; y						y-coordinate of the top left of the rectangle the ellipse will be drawn into
; w						width of the ellipse
; h						height of the ellipse
;
; return				status enumeration. 0 = success
;
; notes					as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width

Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h)
	{
		return DllCall("gdiplus\GdipDrawEllipse", "uint", pGraphics, "uint", pPen, "float", x, "float", y, "float", w, "float", h)
	}

;#####################################################################################

; Function				Gdip_DrawBezier
; Description			This function uses a pen to draw the outline of a bezier (a weighted curve) into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; x1					x-coordinate of the start of the bezier
; y1					y-coordinate of the start of the bezier
; x2					x-coordinate of the first arc of the bezier
; y2					y-coordinate of the first arc of the bezier
; x3					x-coordinate of the second arc of the bezier
; y3					y-coordinate of the second arc of the bezier
; x4					x-coordinate of the end of the bezier
; y4					y-coordinate of the end of the bezier
;
; return				status enumeration. 0 = success
;
; notes					as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width

Gdip_DrawBezier(pGraphics, pPen, x1, y1, x2, y2, x3, y3, x4, y4)
	{
		return DllCall("gdiplus\GdipDrawBezier", "uint", pgraphics, "uint", pPen
		        , "float", x1, "float", y1, "float", x2, "float", y2
		        , "float", x3, "float", y3, "float", x4, "float", y4)
	}

;#####################################################################################

; Function				Gdip_DrawArc
; Description			This function uses a pen to draw the outline of an arc into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; x						x-coordinate of the start of the arc
; y						y-coordinate of the start of the arc
; w						width of the arc
; h						height of the arc
; StartAngle			specifies the angle between the x-axis and the starting point of the arc
; SweepAngle			specifies the angle between the starting and ending points of the arc
;
; return				status enumeration. 0 = success
;
; notes					as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width

Gdip_DrawArc(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle)
	{
		return DllCall("gdiplus\GdipDrawArc", "uint", pGraphics, "uint", pPen, "float", x
		        , "float", y, "float", w, "float", h, "float", StartAngle, "float", SweepAngle)
	}

;#####################################################################################

; Function				Gdip_DrawPie
; Description			This function uses a pen to draw the outline of a pie into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; x						x-coordinate of the start of the pie
; y						y-coordinate of the start of the pie
; w						width of the pie
; h						height of the pie
; StartAngle			specifies the angle between the x-axis and the starting point of the pie
; SweepAngle			specifies the angle between the starting and ending points of the pie
;
; return				status enumeration. 0 = success
;
; notes					as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width

Gdip_DrawPie(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle)
	{
		return DllCall("gdiplus\GdipDrawPie", "uint", pGraphics, "uint", pPen, "float", x, "float", y, "float", w, "float", h, "float", StartAngle, "float", SweepAngle)
	}

;#####################################################################################

; Function				Gdip_DrawLine
; Description			This function uses a pen to draw a line into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; x1					x-coordinate of the start of the line
; y1					y-coordinate of the start of the line
; x2					x-coordinate of the end of the line
; y2					y-coordinate of the end of the line
;
; return				status enumeration. 0 = success

Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2)
	{
		return DllCall("gdiplus\GdipDrawLine", "uint", pGraphics, "uint", pPen
		        , "float", x1, "float", y1, "float", x2, "float", y2)
	}

;#####################################################################################

; Function				Gdip_DrawLines
; Description			This function uses a pen to draw a series of joined lines into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; Points				the coordinates of all the points passed as x1,y1|x2,y2|x3,y3.....
;
; return				status enumeration. 0 = success

Gdip_DrawLines(pGraphics, pPen, Points)
	{
		StringSplit, Points, Points, |
		VarSetCapacity(PointF, 8*Points0)
		Loop, %Points0%
		{
			StringSplit, Coord, Points%A_Index%, `,
			NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
		}
		return DllCall("gdiplus\GdipDrawLines", "uint", pGraphics, "uint", pPen, "uint", &PointF, "int", Points0)
	}

;#####################################################################################

; Function				Gdip_FillRectangle
; Description			This function uses a brush to fill a rectangle in the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pBrush				Pointer to a brush
; x						x-coordinate of the top left of the rectangle
; y						y-coordinate of the top left of the rectangle
; w						width of the rectanlge
; h						height of the rectangle
;
; return				status enumeration. 0 = success

Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
	{
		return DllCall("gdiplus\GdipFillRectangle", "uint", pGraphics, "int", pBrush
		        , "float", x, "float", y, "float", w, "float", h)
	}

;#####################################################################################

; Function				Gdip_FillRoundedRectangle
; Description			This function uses a brush to fill a rounded rectangle in the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pBrush				Pointer to a brush
; x						x-coordinate of the top left of the rounded rectangle
; y						y-coordinate of the top left of the rounded rectangle
; w						width of the rectanlge
; h						height of the rectangle
; r						radius of the rounded corners
;
; return				status enumeration. 0 = success

Gdip_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, r)
	{
		Region := Gdip_GetClipRegion(pGraphics)
		Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
		Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
		Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
		Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
		E := Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
		Gdip_SetClipRegion(pGraphics, Region, 0)
		Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
		Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
		Gdip_FillEllipse(pGraphics, pBrush, x, y, 2*r, 2*r)
		Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y, 2*r, 2*r)
		Gdip_FillEllipse(pGraphics, pBrush, x, y+h-(2*r), 2*r, 2*r)
		Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
		Gdip_SetClipRegion(pGraphics, Region, 0)
		Gdip_DeleteRegion(Region)
		return E
	}

;#####################################################################################

; Function				Gdip_FillPolygon
; Description			This function uses a brush to fill a polygon in the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pBrush				Pointer to a brush
; Points				the coordinates of all the points passed as x1,y1|x2,y2|x3,y3.....
;
; return				status enumeration. 0 = success
;
; notes					Alternate will fill the polygon as a whole, wheras winding will fill each new "segment"
; Alternate 			= 0
; Winding 				= 1

Gdip_FillPolygon(pGraphics, pBrush, Points, FillMode=0)
	{
		StringSplit, Points, Points, |
		VarSetCapacity(PointF, 8*Points0)
		Loop, %Points0%
		{
			StringSplit, Coord, Points%A_Index%, `,
			NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
		}
		return DllCall("gdiplus\GdipFillPolygon", "uint", pGraphics, "uint", pBrush, "uint", &PointF, "int", Points0, "int", FillMode)
	}

;#####################################################################################

; Function				Gdip_FillPie
; Description			This function uses a brush to fill a pie in the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pBrush				Pointer to a brush
; x						x-coordinate of the top left of the pie
; y						y-coordinate of the top left of the pie
; w						width of the pie
; h						height of the pie
; StartAngle			specifies the angle between the x-axis and the starting point of the pie
; SweepAngle			specifies the angle between the starting and ending points of the pie
;
; return				status enumeration. 0 = success

Gdip_FillPie(pGraphics, pBrush, x, y, w, h, StartAngle, SweepAngle)
	{
		return DllCall("gdiplus\GdipFillPie", "uint", pGraphics, "uint", pBrush
		        , "float", x, "float", y, "float", w, "float", h, "float", StartAngle, "float", SweepAngle)
	}

;#####################################################################################

; Function				Gdip_FillEllipse
; Description			This function uses a brush to fill an ellipse in the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pBrush				Pointer to a brush
; x						x-coordinate of the top left of the ellipse
; y						y-coordinate of the top left of the ellipse
; w						width of the ellipse
; h						height of the ellipse
;
; return				status enumeration. 0 = success

Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h)
	{
		return DllCall("gdiplus\GdipFillEllipse", "uint", pGraphics, "uint", pBrush, "float", x, "float", y, "float", w, "float", h)
	}

;#####################################################################################

; Function				Gdip_FillRegion
; Description			This function uses a brush to fill a region in the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pBrush				Pointer to a brush
; Region				Pointer to a Region
;
; return				status enumeration. 0 = success
;
; notes					You can create a region Gdip_CreateRegion() and then add to this

Gdip_FillRegion(pGraphics, pBrush, Region)
	{
		return DllCall("gdiplus\GdipFillRegion", "uint", pGraphics, "uint", pBrush, "uint", Region)
	}

;#####################################################################################

; Function				Gdip_FillPath
; Description			This function uses a brush to fill a path in the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pBrush				Pointer to a brush
; Region				Pointer to a Path
;
; return				status enumeration. 0 = success

Gdip_FillPath(pGraphics, pBrush, Path)
	{
		return DllCall("gdiplus\GdipFillPath", "uint", pGraphics, "uint", pBrush, "uint", Path)
	}

;#####################################################################################

; Function				Gdip_DrawImagePointsRect
; Description			This function draws a bitmap into the Graphics of another bitmap and skews it
;
; pGraphics				Pointer to the Graphics of a bitmap
; pBitmap				Pointer to a bitmap to be drawn
; Points				Points passed as x1,y1|x2,y2|x3,y3 (3 points: top left, top right, bottom left) describing the drawing of the bitmap
; sx					x-coordinate of source upper-left corner
; sy					y-coordinate of source upper-left corner
; sw					width of source rectangle
; sh					height of source rectangle
; Matrix				a matrix used to alter image attributes when drawing
;
; return				status enumeration. 0 = success
;
; notes					if sx,sy,sw,sh are missed then the entire source bitmap will be used
;						Matrix can be omitted to just draw with no alteration to ARGB
;						Matrix may be passed as a digit from 0 - 1 to change just transparency
;						Matrix can be passed as a matrix with any delimiter

Gdip_DrawImagePointsRect(pGraphics, pBitmap, Points, sx="", sy="", sw="", sh="", Matrix=1)
	{
		StringSplit, Points, Points, |
		VarSetCapacity(PointF, 8*Points0)
		Loop, %Points0%
		{
			StringSplit, Coord, Points%A_Index%, `,
			NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
		}

		If (Matrix&1 = "")
			ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
		Else If (Matrix != 1)
			ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")

		If (sx = "" && sy = "" && sw = "" && sh = "")
		{
			sx := 0, sy := 0
			sw := Gdip_GetImageWidth(pBitmap)
			sh := Gdip_GetImageHeight(pBitmap)
		}

		E := DllCall("gdiplus\GdipDrawImagePointsRect", "uint", pGraphics, "uint", pBitmap
		        , "uint", &PointF, "int", Points0, "float", sx, "float", sy, "float", sw, "float", sh
		        , "int", 2, "uint", ImageAttr, "uint", 0, "uint", 0)
		If ImageAttr
			Gdip_DisposeImageAttributes(ImageAttr)
		return E
	}

;#####################################################################################

; Function				Gdip_DrawImage
; Description			This function draws a bitmap into the Graphics of another bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pBitmap				Pointer to a bitmap to be drawn
; dx					x-coord of destination upper-left corner
; dy					y-coord of destination upper-left corner
; dw					width of destination image
; dh					height of destination image
; sx					x-coordinate of source upper-left corner
; sy					y-coordinate of source upper-left corner
; sw					width of source image
; sh					height of source image
; Matrix				a matrix used to alter image attributes when drawing
;
; return				status enumeration. 0 = success
;
; notes					if sx,sy,sw,sh are missed then the entire source bitmap will be used
;						Gdip_DrawImage performs faster
;						Matrix can be omitted to just draw with no alteration to ARGB
;						Matrix may be passed as a digit from 0 - 1 to change just transparency
;						Matrix can be passed as a matrix with any delimiter. For example:
;						MatrixBright=
;						(
;						1.5		|0		|0		|0		|0
;						0		|1.5	|0		|0		|0
;						0		|0		|1.5	|0		|0
;						0		|0		|0		|1		|0
;						0.05	|0.05	|0.05	|0		|1
;						)
;
; notes					MatrixBright = 1.5|0|0|0|0|0|1.5|0|0|0|0|0|1.5|0|0|0|0|0|1|0|0.05|0.05|0.05|0|1
;						MatrixGreyScale = 0.299|0.299|0.299|0|0|0.587|0.587|0.587|0|0|0.114|0.114|0.114|0|0|0|0|0|1|0|0|0|0|0|1
;						MatrixNegative = -1|0|0|0|0|0|-1|0|0|0|0|0|-1|0|0|0|0|0|1|0|0|0|0|0|1

Gdip_DrawImage(pGraphics, pBitmap, dx="", dy="", dw="", dh="", sx="", sy="", sw="", sh="", Matrix=1)
	{
		If (Matrix&1 = "")
			ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
		Else If (Matrix != 1)
			ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")

		If (sx = "" && sy = "" && sw = "" && sh = "")
		{
			If (dx = "" && dy = "" && dw = "" && dh = "")
			{
				sx := dx := 0, sy := dy := 0
				sw := dw := Gdip_GetImageWidth(pBitmap)
				sh := dh := Gdip_GetImageHeight(pBitmap)
			}
			Else
			{
				sx := sy := 0
				sw := Gdip_GetImageWidth(pBitmap)
				sh := Gdip_GetImageHeight(pBitmap)
			}
		}

		E := DllCall("gdiplus\GdipDrawImageRectRect", "uint", pGraphics, "uint", pBitmap
		        , "float", dx, "float", dy, "float", dw, "float", dh
		        , "float", sx, "float", sy, "float", sw, "float", sh
		        , "int", 2, "uint", ImageAttr, "uint", 0, "uint", 0)
		If ImageAttr
			Gdip_DisposeImageAttributes(ImageAttr)
		return E
	}

;#####################################################################################

; Function				Gdip_SetImageAttributesColorMatrix
; Description			This function creates an image matrix ready for drawing
;
; Matrix				a matrix used to alter image attributes when drawing
;						passed with any delimeter
;
; return				returns an image matrix on sucess or 0 if it fails
;
; notes					MatrixBright = 1.5|0|0|0|0|0|1.5|0|0|0|0|0|1.5|0|0|0|0|0|1|0|0.05|0.05|0.05|0|1
;						MatrixGreyScale = 0.299|0.299|0.299|0|0|0.587|0.587|0.587|0|0|0.114|0.114|0.114|0|0|0|0|0|1|0|0|0|0|0|1
;						MatrixNegative = -1|0|0|0|0|0|-1|0|0|0|0|0|-1|0|0|0|0|0|1|0|0|0|0|0|1

Gdip_SetImageAttributesColorMatrix(Matrix)
	{
		VarSetCapacity(ColourMatrix, 100, 0)
		Matrix := RegExReplace(RegExReplace(Matrix, "^[^\d-\.]+([\d\.])", "$1", "", 1), "[^\d-\.]+", "|")
		StringSplit, Matrix, Matrix, |
		Loop, 25
		{
			Matrix := (Matrix%A_Index% != "") ? Matrix%A_Index% : Mod(A_Index-1, 6) ? 0 : 1
			NumPut(Matrix, ColourMatrix, (A_Index-1)*4, "float")
		}
		DllCall("gdiplus\GdipCreateImageAttributes", "uint*", ImageAttr)
		DllCall("gdiplus\GdipSetImageAttributesColorMatrix", "uint", ImageAttr, "int", 1, "int", 1, "uint", &ColourMatrix, "int", 0, "int", 0)
		return ImageAttr
	}

;#####################################################################################

; Function				Gdip_GraphicsFromImage
; Description			This function gets the graphics for a bitmap used for drawing functions
;
; pBitmap				Pointer to a bitmap to get the pointer to its graphics
;
; return				returns a pointer to the graphics of a bitmap
;
; notes					a bitmap can be drawn into the graphics of another bitmap

Gdip_GraphicsFromImage(pBitmap)
	{
		DllCall("gdiplus\GdipGetImageGraphicsContext", "uint", pBitmap, "uint*", pGraphics)
		return pGraphics
	}

;#####################################################################################

; Function				Gdip_GraphicsFromHDC
; Description			This function gets the graphics from the handle to a device context
;
; hdc					This is the handle to the device context
;
; return				returns a pointer to the graphics of a bitmap
;
; notes					You can draw a bitmap into the graphics of another bitmap

Gdip_GraphicsFromHDC(hdc)
	{
		DllCall("gdiplus\GdipCreateFromHDC", "uint", hdc, "uint*", pGraphics)
		return pGraphics
	}

;#####################################################################################

; Function				Gdip_GetDC
; Description			This function gets the device context of the passed Graphics
;
; hdc					This is the handle to the device context
;
; return				returns the device context for the graphics of a bitmap

Gdip_GetDC(pGraphics)
	{
		DllCall("gdiplus\GdipGetDC", "uint", pGraphics, "uint*", hdc)
		return hdc
	}

;#####################################################################################

; Function				Gdip_ReleaseDC
; Description			This function releases a device context from use for further use
;
; pGraphics				Pointer to the graphics of a bitmap
; hdc					This is the handle to the device context
;
; return				status enumeration. 0 = success

Gdip_ReleaseDC(pGraphics, hdc)
	{
		return DllCall("gdiplus\GdipReleaseDC", "uint", pGraphics, "uint", hdc)
	}

;#####################################################################################

; Function				Gdip_GraphicsClear
; Description			Clears the graphics of a bitmap ready for further drawing
;
; pGraphics				Pointer to the graphics of a bitmap
; ARGB					The colour to clear the graphics to
;
; return				status enumeration. 0 = success
;
; notes					By default this will make the background invisible
;						Using clipping regions you can clear a particular area on the graphics rather than clearing the entire graphics

Gdip_GraphicsClear(pGraphics, ARGB=0x00ffffff)
	{
		return DllCall("gdiplus\GdipGraphicsClear", "uint", pGraphics, "int", ARGB)
	}

;#####################################################################################

; Function				Gdip_BlurBitmap
; Description			Gives a pointer to a blurred bitmap from a pointer to a bitmap
;
; pBitmap				Pointer to a bitmap to be blurred
; Blur					The Amount to blur a bitmap by from 1 (least blur) to 100 (most blur)
;
; return				If the function succeeds, the return value is a pointer to the new blurred bitmap
;						-1 = The blur parameter is outside the range 1-100
;
; notes					This function will not dispose of the original bitmap

Gdip_BlurBitmap(pBitmap, Blur)
	{
		If (Blur > 100) || (Blur < 1)
			return -1

		sWidth := Gdip_GetImageWidth(pBitmap), sHeight := Gdip_GetImageHeight(pBitmap)
		dWidth := sWidth//Blur, dHeight := sHeight//Blur

		pBitmap1 := Gdip_CreateBitmap(dWidth, dHeight)
		G1 := Gdip_GraphicsFromImage(pBitmap1)
		Gdip_SetInterpolationMode(G1, 7)
		Gdip_DrawImage(G1, pBitmap, 0, 0, dWidth, dHeight, 0, 0, sWidth, sHeight)

		Gdip_DeleteGraphics(G1)

		pBitmap2 := Gdip_CreateBitmap(sWidth, sHeight)
		G2 := Gdip_GraphicsFromImage(pBitmap2)
		Gdip_SetInterpolationMode(G2, 7)
		Gdip_DrawImage(G2, pBitmap1, 0, 0, sWidth, sHeight, 0, 0, dWidth, dHeight)

		Gdip_DeleteGraphics(G2)
		Gdip_DisposeImage(pBitmap1)
		return pBitmap2
	}

;#####################################################################################

; Function:     		Gdip_SaveBitmapToFile
; Description:  		Saves a bitmap to a file in any supported format onto disk
;
; pBitmap				Pointer to a bitmap
; sOutput      			The name of the file that the bitmap will be saved to. Supported extensions are: .BMP,.DIB,.RLE,.JPG,.JPEG,.JPE,.JFIF,.GIF,.TIF,.TIFF,.PNG
; Quality      			If saving as jpg (.JPG,.JPEG,.JPE,.JFIF) then quality can be 1-100 with default at maximum quality
;
; return      			If the function succeeds, the return value is zero, otherwise:
;						-1 = Extension supplied is not a supported file format
;						-2 = Could not get a list of encoders on system
;						-3 = Could not find matching encoder for specified file format
;						-4 = Could not get WideChar name of output file
;						-5 = Could not save file to disk
;
; notes					This function will use the extension supplied from the sOutput parameter to determine the output format

Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality=75)
	{
		SplitPath, sOutput,,, Extension
		If Extension not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
			return -1
		Extension := "." Extension

		DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
		VarSetCapacity(ci, nSize)
		DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, "uint", &ci)
		If !(nCount && nSize)
			return -2

		Loop, %nCount%
		{
			Location := NumGet(ci, 76*(A_Index-1)+44)
			If !A_IsUnicode
			{
				nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int",  0, "uint", 0, "uint", 0)
				VarSetCapacity(sString, nSize)
				DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "str", sString, "int", nSize, "uint", 0, "uint", 0)
				If !InStr(sString, "*" Extension)
					continue
			}
			Else
			{
				nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int",  0, "uint", 0, "uint", 0)
				sString := ""
				Loop, %nSize%
					sString .= Chr(NumGet(Location+0, 2*(A_Index-1), "char"))
				If !InStr(sString, "*" Extension)
					continue
			}
			pCodec := &ci+76*(A_Index-1)
			break
		}
		If !pCodec
			return -3

		If (Quality != 75)
		{
			Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
			If Extension in .JPG,.JPEG,.JPE,.JFIF
			{
				DllCall("gdiplus\GdipGetEncoderParameterListSize", "uint", pBitmap, "uint", pCodec, "uint*", nSize)
				VarSetCapacity(EncoderParameters, nSize, 0)
				DllCall("gdiplus\GdipGetEncoderParameterList", "uint", pBitmap, "uint", pCodec, "uint", nSize, "uint", &EncoderParameters)
				Loop, % NumGet(EncoderParameters)      ;%
				{
					If (NumGet(EncoderParameters, (28*(A_Index-1))+20) = 1) && (NumGet(EncoderParameters, (28*(A_Index-1))+24) = 6)
					{
						p := (28*(A_Index-1))+&EncoderParameters
						NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20)))
						break
					}
				}
			}
		}

		If !A_IsUnicode
		{
			nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &sOutput, "int", -1, "uint", 0, "int", 0)
			VarSetCapacity(wOutput, nSize*2)
			DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &sOutput, "int", -1, "uint", &wOutput, "int", nSize)
			VarSetCapacity(wOutput, -1)
			If !VarSetCapacity(wOutput)
				return -4
			E := DllCall("gdiplus\GdipSaveImageToFile", "uint", pBitmap, "uint", &wOutput, "uint", pCodec, "uint", p ? p : 0)
		}
		Else
			E := DllCall("gdiplus\GdipSaveImageToFile", "uint", pBitmap, "uint", &sOutput, "uint", pCodec, "uint", p ? p : 0)
		return E ? -5 : 0
	}

;#####################################################################################

; Function				Gdip_GetPixel
; Description			Gets the ARGB of a pixel in a bitmap
;
; pBitmap				Pointer to a bitmap
; x						x-coordinate of the pixel
; y						y-coordinate of the pixel
;
; return				Returns the ARGB value of the pixel

Gdip_GetPixel(pBitmap, x, y)
	{
		DllCall("gdiplus\GdipBitmapGetPixel", "uint", pBitmap, "int", x, "int", y, "uint*", ARGB)
		return ARGB
	}

;#####################################################################################

; Function				Gdip_SetPixel
; Description			Sets the ARGB of a pixel in a bitmap
;
; pBitmap				Pointer to a bitmap
; x						x-coordinate of the pixel
; y						y-coordinate of the pixel
;
; return				status enumeration. 0 = success

Gdip_SetPixel(pBitmap, x, y, ARGB)
	{
		return DllCall("gdiplus\GdipBitmapSetPixel", "uint", pBitmap, "int", x, "int", y, "int", ARGB)
	}

;#####################################################################################

; Function				Gdip_GetImageWidth
; Description			Gives the width of a bitmap
;
; pBitmap				Pointer to a bitmap
;
; return				Returns the width in pixels of the supplied bitmap

Gdip_GetImageWidth(pBitmap)
	{
		DllCall("gdiplus\GdipGetImageWidth", "uint", pBitmap, "uint*", Width)
		return Width
	}

;#####################################################################################

; Function				Gdip_GetImageHeight
; Description			Gives the height of a bitmap
;
; pBitmap				Pointer to a bitmap
;
; return				Returns the height in pixels of the supplied bitmap

Gdip_GetImageHeight(pBitmap)
	{
		DllCall("gdiplus\GdipGetImageHeight", "uint", pBitmap, "uint*", Height)
		return Height
	}

;#####################################################################################

; Function				Gdip_GetDimensions
; Description			Gives the width and height of a bitmap
;
; pBitmap				Pointer to a bitmap
; Width					ByRef variable. This variable will be set to the width of the bitmap
; Height				ByRef variable. This variable will be set to the height of the bitmap
;
; return				No return value
;						Gdip_GetDimensions(pBitmap, ThisWidth, ThisHeight) will set ThisWidth to the width and ThisHeight to the height

Gdip_GetDimensions(pBitmap, ByRef Width, ByRef Height)
	{
		Width := Gdip_GetImageWidth(pBitmap)
		Height := Gdip_GetImageHeight(pBitmap)
	}

;#####################################################################################

Gdip_GetImagePixelFormat(pBitmap)
	{
		DllCall("gdiplus\GdipGetImagePixelFormat", "uint", pBitmap, "uint*", Format)
		return Format
	}

;#####################################################################################

; Function				Gdip_GetDpiX
; Description			Gives the horizontal dots per inch of the graphics of a bitmap
;
; pBitmap				Pointer to a bitmap
; Width					ByRef variable. This variable will be set to the width of the bitmap
; Height				ByRef variable. This variable will be set to the height of the bitmap
;
; return				No return value
;						Gdip_GetDimensions(pBitmap, ThisWidth, ThisHeight) will set ThisWidth to the width and ThisHeight to the height

Gdip_GetDpiX(pGraphics)
	{
		DllCall("gdiplus\GdipGetDpiX", "uint", pGraphics, "float*", dpix)
		return Round(dpix)
	}

Gdip_GetDpiY(pGraphics)
	{
		DllCall("gdiplus\GdipGetDpiY", "uint", pGraphics, "float*", dpiy)
		return Round(dpiy)
	}

Gdip_GetImageHorizontalResolution(pBitmap)
	{
		DllCall("gdiplus\GdipGetImageHorizontalResolution", "uint", pBitmap, "float*", dpix)
		return Round(dpix)
	}

Gdip_GetImageVerticalResolution(pBitmap)
	{
		DllCall("gdiplus\GdipGetImageVerticalResolution", "uint", pBitmap, "float*", dpiy)
		return Round(dpiy)
	}

Gdip_CreateBitmapFromFile(sFile, IconNumber=1, IconSize="")
	{
		SplitPath, sFile,,, ext
		If ext in exe,dll
		{
			Sizes := IconSize ? IconSize : 256 "|" 128 "|" 64 "|" 48 "|" 32 "|" 16
			VarSetCapacity(buf, 40)
			Loop, Parse, Sizes, |
			{
				DllCall("PrivateExtractIcons", "str", sFile, "int", IconNumber-1, "int", A_LoopField, "int", A_LoopField, "uint*", hIcon, "uint*", 0, "uint", 1, "uint", 0)
				If !hIcon
					continue

				If !DllCall("GetIconInfo", "uint", hIcon, "uint", &buf)
				{
					DestroyIcon(hIcon)
					continue
				}
				hbmColor := NumGet(buf, 16)
				hbmMask  := NumGet(buf, 12)

				If !(hbmColor && DllCall("GetObject", "uint", hbmColor, "int", 24, "uint", &buf))
				{
					DestroyIcon(hIcon)
					continue
				}
				break
			}
			If !hIcon
				return -1

			Width := NumGet(buf, 4, "int"),  Height := NumGet(buf, 8, "int")
			hbm := CreateDIBSection(Width, -Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)

			If !DllCall("DrawIconEx", "uint", hdc, "int", 0, "int", 0, "uint", hIcon, "uint", Width, "uint", Height, "uint", 0, "uint", 0, "uint", 3)
			{
				DestroyIcon(hIcon)
				return -2
			}

			VarSetCapacity(dib, 84)
			DllCall("GetObject", "uint", hbm, "int", 84, "uint", &dib)
			Stride := NumGet(dib, 12), Bits := NumGet(dib, 20)

			DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", Stride, "int", 0x26200A, "uint", Bits, "uint*", pBitmapOld)
			pBitmap := Gdip_CreateBitmap(Width, Height), G := Gdip_GraphicsFromImage(pBitmap)
			Gdip_DrawImage(G, pBitmapOld, 0, 0, Width, Height, 0, 0, Width, Height)
			SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
			Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmapOld)
			DestroyIcon(hIcon)
		}
		Else
		{
			If !A_IsUnicode
			{
				VarSetCapacity(wFile, 1023)
				DllCall("kernel32\MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &sFile, "int", -1, "uint", &wFile, "int", 512)
				DllCall("gdiplus\GdipCreateBitmapFromFile", "uint", &wFile, "uint*", pBitmap)
			}
			Else
				DllCall("gdiplus\GdipCreateBitmapFromFile", "uint", &sFile, "uint*", pBitmap)
		}
		return pBitmap
	}

Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette=0)
	{
		DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "uint", hBitmap, "uint", Palette, "uint*", pBitmap)
		return pBitmap
	}

Gdip_CreateHBITMAPFromBitmap(pBitmap, Background=0xffffffff)
	{
		DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "uint", pBitmap, "uint*", hbm, "int", Background)
		return hbm
	}

Gdip_CreateBitmapFromHICON(hIcon)
	{
		DllCall("gdiplus\GdipCreateBitmapFromHICON", "uint", hIcon, "uint*", pBitmap)
		return pBitmap
	}

Gdip_CreateHICONFromBitmap(pBitmap)
	{
		DllCall("gdiplus\GdipCreateHICONFromBitmap", "uint", pBitmap, "uint*", hIcon)
		return hIcon
	}

Gdip_CreateBitmap(Width, Height, Format=0x26200A)
	{
		DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", 0, "int", Format, "uint", 0, "uint*", pBitmap)
		Return pBitmap
	}

Gdip_CreateBitmapFromClipboard()
	{
		If !DllCall("OpenClipboard", "uint", 0)
			return -1
		If !DllCall("IsClipboardFormatAvailable", "uint", 8)
			return -2
		If !hBitmap := DllCall("GetClipboardData", "uint", 2)
			return -3
		If !pBitmap := Gdip_CreateBitmapFromHBITMAP(hBitmap)
			return -4
		If !DllCall("CloseClipboard")
			return -5
		DeleteObject(hBitmap)
		return pBitmap
	}

Gdip_SetBitmapToClipboard(pBitmap)
	{
		hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
		DllCall("GetObject", "uint", hBitmap, "int", VarSetCapacity(oi, 84, 0), "uint", &oi)
		hdib := DllCall("GlobalAlloc", "uint", 2, "uint", 40+NumGet(oi, 44))
		pdib := DllCall("GlobalLock", "uint", hdib)
		DllCall("RtlMoveMemory", "uint", pdib, "uint", &oi+24, "uint", 40)
		DllCall("RtlMoveMemory", "Uint", pdib+40, "Uint", NumGet(oi, 20), "uint", NumGet(oi, 44))
		DllCall("GlobalUnlock", "uint", hdib)
		DllCall("DeleteObject", "uint", hBitmap)
		DllCall("OpenClipboard", "uint", 0)
		DllCall("EmptyClipboard")
		DllCall("SetClipboardData", "uint", 8, "uint", hdib)
		DllCall("CloseClipboard")
	}

Gdip_CloneBitmapArea(pBitmap, x, y, w, h, Format=0x26200A)
	{
		DllCall("gdiplus\GdipCloneBitmapArea", "float", x, "float", y, "float", w, "float", h
		        , "int", Format, "uint", pBitmap, "uint*", pBitmapDest)
		return pBitmapDest
	}

;#####################################################################################
; Create resources
;#####################################################################################

Gdip_CreatePen(ARGB, w)
	{
		DllCall("gdiplus\GdipCreatePen1", "int", ARGB, "float", w, "int", 2, "uint*", pPen)
		return pPen
	}

Gdip_CreatePenFromBrush(pBrush, w)
	{
		DllCall("gdiplus\GdipCreatePen2", "uint", pBrush, "float", w, "int", 2, "uint*", pPen)
		return pPen
	}

Gdip_BrushCreateSolid(ARGB=0x00000000)
	{
		DllCall("gdiplus\GdipCreateSolidFill", "int", ARGB, "uint*", pBrush)
		return pBrush
	}

; HatchStyleHorizontal = 0
; HatchStyleVertical = 1
; HatchStyleForwardDiagonal = 2
; HatchStyleBackwardDiagonal = 3
; HatchStyleCross = 4
; HatchStyleDiagonalCross = 5
; HatchStyle05Percent = 6
; HatchStyle10Percent = 7
; HatchStyle20Percent = 8
; HatchStyle25Percent = 9
; HatchStyle30Percent = 10
; HatchStyle40Percent = 11
; HatchStyle50Percent = 12
; HatchStyle60Percent = 13
; HatchStyle70Percent = 14
; HatchStyle75Percent = 15
; HatchStyle80Percent = 16
; HatchStyle90Percent = 17
; HatchStyleLightDownwardDiagonal = 18
; HatchStyleLightUpwardDiagonal = 19
; HatchStyleDarkDownwardDiagonal = 20
; HatchStyleDarkUpwardDiagonal = 21
; HatchStyleWideDownwardDiagonal = 22
; HatchStyleWideUpwardDiagonal = 23
; HatchStyleLightVertical = 24
; HatchStyleLightHorizontal = 25
; HatchStyleNarrowVertical = 26
; HatchStyleNarrowHorizontal = 27
; HatchStyleDarkVertical = 28
; HatchStyleDarkHorizontal = 29
; HatchStyleDashedDownwardDiagonal = 30
; HatchStyleDashedUpwardDiagonal = 31
; HatchStyleDashedHorizontal = 32
; HatchStyleDashedVertical = 33
; HatchStyleSmallConfetti = 34
; HatchStyleLargeConfetti = 35
; HatchStyleZigZag = 36
; HatchStyleWave = 37
; HatchStyleDiagonalBrick = 38
; HatchStyleHorizontalBrick = 39
; HatchStyleWeave = 40
; HatchStylePlaid = 41
; HatchStyleDivot = 42
; HatchStyleDottedGrid = 43
; HatchStyleDottedDiamond = 44
; HatchStyleShingle = 45
; HatchStyleTrellis = 46
; HatchStyleSphere = 47
; HatchStyleSmallGrid = 48
; HatchStyleSmallCheckerBoard = 49
; HatchStyleLargeCheckerBoard = 50
; HatchStyleOutlinedDiamond = 51
; HatchStyleSolidDiamond = 52
; HatchStyleTotal = 53
Gdip_BrushCreateHatch(ARGBfront, ARGBback, HatchStyle=0)
	{
		DllCall("gdiplus\GdipCreateHatchBrush", "int", HatchStyle, "int", ARGBfront, "int", ARGBback, "uint*", pBrush)
		return pBrush
	}

;GpStatus WINGDIPAPI GdipCreateTexture2I(GpImage *image, GpWrapMode wrapmode, INT x, INT y, INT width, INT height, GpTexture **texture)
;GpStatus WINGDIPAPI GdipCreateTexture2(GpImage *image, GpWrapMode wrapmode, REAL x, REAL y, REAL width, REAL height, GpTexture **texture)
;GpStatus WINGDIPAPI GdipCreateTexture(GpImage *image, GpWrapMode wrapmode, GpTexture **texture)

Gdip_CreateTextureBrush(pBitmap, WrapMode=1, x=0, y=0, w="", h="")
	{
		If !(w && h)
			DllCall("gdiplus\GdipCreateTexture", "uint", pBitmap, "int", WrapMode, "uint*", pBrush)
		Else
			DllCall("gdiplus\GdipCreateTexture2", "uint", pBitmap, "int", WrapMode, "float", x, "float", y, "float", w, "float", h, "uint*", pBrush)
		return pBrush
	}

; WrapModeTile = 0
; WrapModeTileFlipX = 1
; WrapModeTileFlipY = 2
; WrapModeTileFlipXY = 3
; WrapModeClamp = 4
Gdip_CreateLineBrush(x1, y1, x2, y2, ARGB1, ARGB2, WrapMode=1)
	{
		CreatePointF(PointF1, x1, y1), CreatePointF(PointF2, x2, y2)
		DllCall("gdiplus\GdipCreateLineBrush", "uint", &PointF1, "uint", &PointF2, "int", ARGB1, "int", ARGB2, "int", WrapMode, "uint*", LGpBrush)
		return LGpBrush
	}

; LinearGradientModeHorizontal = 0
; LinearGradientModeVertical = 1
; LinearGradientModeForwardDiagonal = 2
; LinearGradientModeBackwardDiagonal = 3
Gdip_CreateLineBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode=1, WrapMode=1)
	{
		CreateRectF(RectF, x, y, w, h)
		DllCall("gdiplus\GdipCreateLineBrushFromRect", "uint", &RectF, "int", ARGB1, "int", ARGB2, "int", LinearGradientMode, "int", WrapMode, "uint*", LGpBrush)
		return LGpBrush
	}

Gdip_CloneBrush(pBrush)
	{
		static pNewBrush
		VarSetCapacity(pNewBrush, 288, 0)
		DllCall("RtlMoveMemory", "uint", &pNewBrush, "uint", pBrush, "uint", 288)
		VarSetCapacity(pNewBrush, -1)
		return &pNewBrush
	}

;#####################################################################################
; Delete resources
;#####################################################################################

Gdip_DeletePen(pPen)
	{
		return DllCall("gdiplus\GdipDeletePen", "uint", pPen)
	}

Gdip_DeleteBrush(pBrush)
	{
		return DllCall("gdiplus\GdipDeleteBrush", "uint", pBrush)
	}

Gdip_DisposeImage(pBitmap)
	{
		return DllCall("gdiplus\GdipDisposeImage", "uint", pBitmap)
	}

Gdip_DeleteGraphics(pGraphics)
	{
		return DllCall("gdiplus\GdipDeleteGraphics", "uint", pGraphics)
	}

Gdip_DisposeImageAttributes(ImageAttr)
	{
		return DllCall("gdiplus\GdipDisposeImageAttributes", "uint", ImageAttr)
	}

Gdip_DeleteFont(hFont)
	{
		return DllCall("gdiplus\GdipDeleteFont", "uint", hFont)
	}

Gdip_DeleteStringFormat(hFormat)
	{
		return DllCall("gdiplus\GdipDeleteStringFormat", "uint", hFormat)
	}

Gdip_DeleteFontFamily(hFamily)
	{
		return DllCall("gdiplus\GdipDeleteFontFamily", "uint", hFamily)
	}

Gdip_DeleteMatrix(Matrix)
	{
		return DllCall("gdiplus\GdipDeleteMatrix", "uint", Matrix)
	}

;#####################################################################################
; Text functions
;#####################################################################################

Gdip_TextToGraphics(pGraphics, Text, Options, Font="Arial", Width="", Height="", Measure=0)
	{
		IWidth := Width, IHeight:= Height

		RegExMatch(Options, "i)X([\-\d\.]+)(p*)", xpos)
		RegExMatch(Options, "i)Y([\-\d\.]+)(p*)", ypos)
		RegExMatch(Options, "i)W([\-\d\.]+)(p*)", Width)
		RegExMatch(Options, "i)H([\-\d\.]+)(p*)", Height)
		RegExMatch(Options, "i)C(?!(entre|enter))([a-f\d]+)", Colour)
		RegExMatch(Options, "i)Top|Up|Bottom|Down|vCentre|vCenter", vPos)
		RegExMatch(Options, "i)R(\d)", Rendering)
		RegExMatch(Options, "i)S(\d+)(p*)", Size)

		If !Gdip_DeleteBrush(Gdip_CloneBrush(Colour2))
			PassBrush := 1, pBrush := Colour2

		If !(IWidth && IHeight) && (xpos2 || ypos2 || Width2 || Height2 || Size2)
			return -1

		Style := 0, Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"
		Loop, Parse, Styles, |
		{
			If RegExMatch(Options, "\b" A_loopField)
				Style |= (A_LoopField != "StrikeOut") ? (A_Index-1) : 8
		}

		Align := 0, Alignments := "Near|Left|Centre|Center|Far|Right"
		Loop, Parse, Alignments, |
		{
			If RegExMatch(Options, "\b" A_loopField)
				Align |= A_Index//2.1      ; 0|0|1|1|2|2
		}

		xpos := (xpos1 != "") ? xpos2 ? IWidth*(xpos1/100) : xpos1 : 0
		ypos := (ypos1 != "") ? ypos2 ? IHeight*(ypos1/100) : ypos1 : 0
		Width := Width1 ? Width2 ? IWidth*(Width1/100) : Width1 : IWidth
		Height := Height1 ? Height2 ? IHeight*(Height1/100) : Height1 : IHeight
		If !PassBrush
			Colour := "0x" (Colour2 ? Colour2 : "ff000000")
		Rendering := ((Rendering1 >= 0) && (Rendering1 <= 5)) ? Rendering1 : 4
		Size := (Size1 > 0) ? Size2 ? IHeight*(Size1/100) : Size1 : 12

		hFamily := Gdip_FontFamilyCreate(Font)
		hFont := Gdip_FontCreate(hFamily, Size, Style)
		hFormat := Gdip_StringFormatCreate(0x4000)
		pBrush := PassBrush ? pBrush : Gdip_BrushCreateSolid(Colour)
		If !(hFamily && hFont && hFormat && pBrush && pGraphics)
			return !pGraphics ? -2 : !hFamily ? -3 : !hFont ? -4 : !hFormat ? -5 : !pBrush ? -6 : 0

		CreateRectF(RC, xpos, ypos, Width, Height)
		Gdip_SetStringFormatAlign(hFormat, Align)
		Gdip_SetTextRenderingHint(pGraphics, Rendering)
		ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)

		If vPos
		{
			StringSplit, ReturnRC, ReturnRC, |

			If (vPos = "vCentre") || (vPos = "vCenter")
				ypos += (Height-ReturnRC4)//2
			Else If (vPos = "Top") || (vPos = "Up")
				ypos := 0
			Else If (vPos = "Bottom") || (vPos = "Down")
				ypos := Height-ReturnRC4

			CreateRectF(RC, xpos, ypos, Width, ReturnRC4)
			ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
		}

		If !Measure
			E := Gdip_DrawString(pGraphics, Text, hFont, hFormat, pBrush, RC)

		If !PassBrush
			Gdip_DeleteBrush(pBrush)
		Gdip_DeleteStringFormat(hFormat)
		Gdip_DeleteFont(hFont)
		Gdip_DeleteFontFamily(hFamily)
		return E ? E : ReturnRC
	}

Gdip_DrawString(pGraphics, sString, hFont, hFormat, pBrush, ByRef RectF)
	{
		If !A_IsUnicode
		{
			nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &sString, "int", -1, "uint", 0, "int", 0)
			VarSetCapacity(wString, nSize*2)
			DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &sString, "int", -1, "uint", &wString, "int", nSize)
			return DllCall("gdiplus\GdipDrawString", "uint", pGraphics
			        , "uint", &wString, "int", -1, "uint", hFont, "uint", &RectF, "uint", hFormat, "uint", pBrush)
		}
		Else
		{
			return DllCall("gdiplus\GdipDrawString", "uint", pGraphics
			        , "uint", &sString, "int", -1, "uint", hFont, "uint", &RectF, "uint", hFormat, "uint", pBrush)
		}
	}

Gdip_MeasureString(pGraphics, sString, hFont, hFormat, ByRef RectF)
	{
		VarSetCapacity(RC, 16)
		If !A_IsUnicode
		{
			nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &sString, "int", -1, "uint", 0, "int", 0)
			VarSetCapacity(wString, nSize*2)
			DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &sString, "int", -1, "uint", &wString, "int", nSize)
			DllCall("gdiplus\GdipMeasureString", "uint", pGraphics
			        , "uint", &wString, "int", -1, "uint", hFont, "uint", &RectF, "uint", hFormat, "uint", &RC, "uint*", Chars, "uint*", Lines)
		}
		Else
		{
			DllCall("gdiplus\GdipMeasureString", "uint", pGraphics
			        , "uint", &sString, "int", -1, "uint", hFont, "uint", &RectF, "uint", hFormat, "uint", &RC, "uint*", Chars, "uint*", Lines)
		}
		return &RC ? NumGet(RC, 0, "float") "|" NumGet(RC, 4, "float") "|" NumGet(RC, 8, "float") "|" NumGet(RC, 12, "float") "|" Chars "|" Lines : 0
	}

; Near = 0
; Center = 1
; Far = 2
Gdip_SetStringFormatAlign(hFormat, Align)
	{
		return DllCall("gdiplus\GdipSetStringFormatAlign", "uint", hFormat, "int", Align)
	}

Gdip_StringFormatCreate(Format=0, Lang=0)
	{
		DllCall("gdiplus\GdipCreateStringFormat", "int", Format, "int", Lang, "uint*", hFormat)
		return hFormat
	}

; Regular = 0
; Bold = 1
; Italic = 2
; BoldItalic = 3
; Underline = 4
; Strikeout = 8
Gdip_FontCreate(hFamily, Size, Style=0)
	{
		DllCall("gdiplus\GdipCreateFont", "uint", hFamily, "float", Size, "int", Style, "int", 0, "uint*", hFont)
		return hFont
	}

Gdip_FontFamilyCreate(Font)
	{
		If !A_IsUnicode
		{
			nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &Font, "int", -1, "uint", 0, "int", 0)
			VarSetCapacity(wFont, nSize*2)
			DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &Font, "int", -1, "uint", &wFont, "int", nSize)
			DllCall("gdiplus\GdipCreateFontFamilyFromName", "uint", &wFont, "uint", 0, "uint*", hFamily)
		}
		Else
			DllCall("gdiplus\GdipCreateFontFamilyFromName", "uint", &Font, "uint", 0, "uint*", hFamily)
		return hFamily
	}

;#####################################################################################
; Matrix functions
;#####################################################################################

Gdip_CreateAffineMatrix(m11, m12, m21, m22, x, y)
	{
		DllCall("gdiplus\GdipCreateMatrix2", "float", m11, "float", m12, "float", m21, "float", m22, "float", x, "float", y, "uint*", Matrix)
		return Matrix
	}

Gdip_CreateMatrix()
	{
		DllCall("gdiplus\GdipCreateMatrix", "uint*", Matrix)
		return Matrix
	}

;#####################################################################################
; GraphicsPath functions
;#####################################################################################

; Alternate = 0
; Winding = 1
Gdip_CreatePath(BrushMode=0)
	{
		DllCall("gdiplus\GdipCreatePath", "int", BrushMode, "uint*", Path)
		return Path
	}

Gdip_AddPathEllipse(Path, x, y, w, h)
	{
		return DllCall("gdiplus\GdipAddPathEllipse", "uint", Path, "float", x, "float", y, "float", w, "float", h)
	}

Gdip_AddPathPolygon(Path, Points)
	{
		StringSplit, Points, Points, |
		VarSetCapacity(PointF, 8*Points0)
		Loop, %Points0%
		{
			StringSplit, Coord, Points%A_Index%, `,
			NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
		}

		return DllCall("gdiplus\GdipAddPathPolygon", "uint", Path, "uint", &PointF, "int", Points0)
	}

Gdip_DeletePath(Path)
	{
		return DllCall("gdiplus\GdipDeletePath", "uint", Path)
	}

;#####################################################################################
; Quality functions
;#####################################################################################

; SystemDefault = 0
; SingleBitPerPixelGridFit = 1
; SingleBitPerPixel = 2
; AntiAliasGridFit = 3
; AntiAlias = 4
Gdip_SetTextRenderingHint(pGraphics, RenderingHint)
	{
		return DllCall("gdiplus\GdipSetTextRenderingHint", "uint", pGraphics, "int", RenderingHint)
	}

; Default = 0
; LowQuality = 1
; HighQuality = 2
; Bilinear = 3
; Bicubic = 4
; NearestNeighbor = 5
; HighQualityBilinear = 6
; HighQualityBicubic = 7
Gdip_SetInterpolationMode(pGraphics, InterpolationMode)
	{
		return DllCall("gdiplus\GdipSetInterpolationMode", "uint", pGraphics, "int", InterpolationMode)
	}

; Default = 0
; HighSpeed = 1
; HighQuality = 2
; None = 3
; AntiAlias = 4
Gdip_SetSmoothingMode(pGraphics, SmoothingMode)
	{
		return DllCall("gdiplus\GdipSetSmoothingMode", "uint", pGraphics, "int", SmoothingMode)
	}

; CompositingModeSourceOver = 0 (blended)
; CompositingModeSourceCopy = 1 (overwrite)
Gdip_SetCompositingMode(pGraphics, CompositingMode=0)
	{
		return DllCall("gdiplus\GdipSetCompositingMode", "uint", pGraphics, "int", CompositingMode)
	}

;#####################################################################################
; Extra functions
;#####################################################################################

Gdip_Startup()
	{
		If !DllCall("GetModuleHandle", "str", "gdiplus")
			DllCall("LoadLibrary", "str", "gdiplus")
		VarSetCapacity(si, 16, 0), si := Chr(1)
		DllCall("gdiplus\GdiplusStartup", "uint*", pToken, "uint", &si, "uint", 0)
		return pToken
	}

Gdip_Shutdown(pToken)
	{
		DllCall("gdiplus\GdiplusShutdown", "uint", pToken)
		If hModule := DllCall("GetModuleHandle", "str", "gdiplus")
			DllCall("FreeLibrary", "uint", hModule)
		return 0
	}

; Prepend = 0; The new operation is applied before the old operation.
; Append = 1; The new operation is applied after the old operation.
Gdip_RotateWorldTransform(pGraphics, Angle, MatrixOrder=0)
	{
		return DllCall("gdiplus\GdipRotateWorldTransform", "uint", pGraphics, "float", Angle, "int", MatrixOrder)
	}

Gdip_ScaleWorldTransform(pGraphics, x, y, MatrixOrder=0)
	{
		return DllCall("gdiplus\GdipScaleWorldTransform", "uint", pGraphics, "float", x, "float", y, "int", MatrixOrder)
	}

Gdip_TranslateWorldTransform(pGraphics, x, y, MatrixOrder=0)
	{
		return DllCall("gdiplus\GdipTranslateWorldTransform", "uint", pGraphics, "float", x, "float", y, "int", MatrixOrder)
	}

Gdip_ResetWorldTransform(pGraphics)
	{
		return DllCall("gdiplus\GdipResetWorldTransform", "uint", pGraphics)
	}

Gdip_GetRotatedTranslation(Width, Height, Angle, ByRef xTranslation, ByRef yTranslation)
	{
		pi := 3.14159, TAngle := Angle*(pi/180)

		Bound := (Angle >= 0) ? Mod(Angle, 360) : 360-Mod(-Angle, -360)
		If ((Bound >= 0) && (Bound <= 90))
			xTranslation := Height*Sin(TAngle), yTranslation := 0
		Else If ((Bound > 90) && (Bound <= 180))
			xTranslation := (Height*Sin(TAngle))-(Width*Cos(TAngle)), yTranslation := -Height*Cos(TAngle)
		Else If ((Bound > 180) && (Bound <= 270))
			xTranslation := -(Width*Cos(TAngle)), yTranslation := -(Height*Cos(TAngle))-(Width*Sin(TAngle))
		Else If ((Bound > 270) && (Bound <= 360))
			xTranslation := 0, yTranslation := -Width*Sin(TAngle)
	}

Gdip_GetRotatedDimensions(Width, Height, Angle, ByRef RWidth, ByRef RHeight)
	{
		pi := 3.14159, TAngle := Angle*(pi/180)
		If !(Width && Height)
			return -1
		RWidth := Ceil(Abs(Width*Cos(TAngle))+Abs(Height*Sin(TAngle)))
		RHeight := Ceil(Abs(Width*Sin(TAngle))+Abs(Height*Cos(Tangle)))
	}

; Replace = 0
; Intersect = 1
; Union = 2
; Xor = 3
; Exclude = 4
; Complement = 5
Gdip_SetClipRect(pGraphics, x, y, w, h, CombineMode=0)
	{
		return DllCall("gdiplus\GdipSetClipRect", "uint", pGraphics, "float", x, "float", y, "float", w, "float", h, "int", CombineMode)
	}

Gdip_SetClipPath(pGraphics, Path, CombineMode=0)
	{
		return DllCall("gdiplus\GdipSetClipPath", "uint", pGraphics, "uint", Path, "int", CombineMode)
	}

Gdip_ResetClip(pGraphics)
	{
		return DllCall("gdiplus\GdipResetClip", "uint", pGraphics)
	}

Gdip_GetClipRegion(pGraphics)
	{
		Region := Gdip_CreateRegion()
		DllCall("gdiplus\GdipGetClip", "uint" pGraphics, "uint*", Region)
		return Region
	}

Gdip_SetClipRegion(pGraphics, Region, CombineMode=0)
	{
		return DllCall("gdiplus\GdipSetClipRegion", "uint", pGraphics, "uint", Region, "int", CombineMode)
	}

Gdip_CreateRegion()
	{
		DllCall("gdiplus\GdipCreateRegion", "uint*", Region)
		return Region
	}

Gdip_DeleteRegion(Region)
	{
		return DllCall("gdiplus\GdipDeleteRegion", "uint", Region)
	}



RC4txt2hex(Data,Pass) {
		Format := A_FormatInteger
		SetFormat Integer, Hex
		b := 0, j := 0
		VarSetCapacity(Result,StrLen(Data)*2)
		Loop 256
			a := A_Index - 1
		        ,Key%a% := Asc(SubStr(Pass, Mod(a,StrLen(Pass))+1, 1))
		        ,sBox%a% := a
		Loop 256
			a := A_Index - 1
		        ,b := b + sBox%a% + Key%a%  & 255
		        ,sBox%a% := (sBox%b%+0, sBox%b% := sBox%a%) ; SWAP(a,b)
		Loop Parse, Data
			i := A_Index & 255
		        ,j := sBox%i% + j  & 255
		        ,k := sBox%i% + sBox%j%  & 255
		        ,sBox%i% := (sBox%j%+0, sBox%j% := sBox%i%) ; SWAP(i,j)
		        ,Result .= SubStr(Asc(A_LoopField)^sBox%k%, -1, 2)
		StringReplace Result, Result, x, 0, All
		SetFormat Integer, %Format%
		Return Result
	}

RC4hex2txt(Data,Pass) {
		b := 0, j := 0, x := "0x"
		VarSetCapacity(Result,StrLen(Data)//2)
		Loop 256
			a := A_Index - 1
		        ,Key%a% := Asc(SubStr(Pass, Mod(a,StrLen(Pass))+1, 1))
		        ,sBox%a% := a
		Loop 256
			a := A_Index - 1
		        ,b := b + sBox%a% + Key%a%  & 255
		        ,sBox%a% := (sBox%b%+0, sBox%b% := sBox%a%) ; SWAP(a,b)
		Loop % StrLen(Data)//2
			i := A_Index  & 255
		        ,j := sBox%i% + j  & 255
		        ,k := sBox%i% + sBox%j%  & 255
		        ,sBox%i% := (sBox%j%+0, sBox%j% := sBox%i%) ; SWAP(i,j)
		        ,Result .= Chr((x . SubStr(Data,2*A_Index-1,2)) ^ sBox%k%)
		Return Result
	}




IPC_Send(Hwnd, Data="", Port=100, DataSize="") {
		static WM_COPYDATA = 74, INT_MAX=2147483647
		If Port not between 0 AND %INT_MAX%
			return A_ThisFunc "> Port number is not in a positive integer range: " Port

		If (DataSize = "")
			DataSize := StrLen(Data)+1, pData := &Data, Port := -Port			;use negative port for textual messages
		Else pData := Data

		VarSetCapacity(COPYDATA, 12)
		        , NumPut(Port,		COPYDATA, 0)
		        , NumPut(DataSize, COPYDATA, 4)
		        , NumPut(pData,	COPYDATA, 8)

		Gui, +LastFound
		SendMessage, WM_COPYDATA, WinExist(), &COPYDATA,, ahk_id %Hwnd%
		return ErrorLevel="FAIL" ? false : true
	}

/*
Function:	 SetHandler
Set the data handler.

Parameters:
Handler - Function that will be called when data is received.

Handler:
>			 Handler(Hwnd, Data, Port, DataSize)

Hwnd	- Handle of the window passing data.
Data	- Data that is received.
Port	- Data port.
DataSize - If DataSize is not empty, Data is pointer to the actuall data. Otherwise Data is textual message.
*/
IPC_SetHandler( Handler ){
		static WM_COPYDATA = 74

		If !IsFunc( Handler )
			return A_ThisFunc "> Invalid handler: " Handler

		OnMessage(WM_COPYDATA, "IPC_onCopyData")
		IPC_onCopyData(Handler, "")
	}


IPC_onCopyData(WParam, LParam) {
		static Handler
		If Lparam =
			return  Handler := WParam

		port := NumGet(Lparam+0, 0, "Int"), data := NumGet(Lparam+8)
		If port < 0
			data := DllCall("MulDiv", "Int", data, "Int",1, "Int", 1, "str"), port := -port
		Else size := NumGet(LParam+4)

		%handler%(WParam, data, port, size)
		return 1
	}
