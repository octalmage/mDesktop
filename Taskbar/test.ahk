;Test script to show how to attach a script to a custom toolbar on windows
;taskbar, that works even if separated from the taskbar.
;author jonib

;Here you define what folder the custom toolbar is attached to:
ToolbarName=mDesktopPager
;How often script is updated in ms.
UpdateTime=1000

;This initializes the toolbar code and runs custom MainInit.
gosub CreateWindow

return

;Here you define all controls you want to show on the toolbar.
MainInit:
   Gui Margin, 0, 0 
   Gui -Caption ToolWindow
   FormatTime, CurrentTime,,Time
   Gui Add, Text,vTheTime,%CurrentTime%
   FormatTime, CurrentDate,,ShortDate
   Gui Add, Text,vTheDate,%CurrentDate%
  
   
   
   Gui Show, x-639
return

;Here all controls you want to show gets updated using the timer.
MainUpdate:
   FormatTime, CurrentTime,,Time
   GuiControl,,TheTime ,%CurrentTime%
   FormatTime, CurrentDate,,ShortDate
   GuiControl,,TheDate ,%CurrentDate%
   gosub ProcUpdate

return

ProcUpdate:

return

;This gets the handle to the toolbar, creates the window and attaches it to the
;toolbar, and activates the timer.
CreateWindow:
   hw_tray:=FindToolbar(ToolbarName)
   gosub MainInit
  Process Exist
  WinGet GuiID, ID, ahk_pid %ErrorLevel%
   if Not DockIt(hw_tray,GuiID)
   {
      msgbox, Toolbar not found
      exitapp
   }
   Gui Show, x%tX% y%tY%
   SetTimer WindowUpdate, %UpdateTime%
return

;The timer runs this code that checks if the toolbar has changed and runs the
;MainUpdate routine
WindowUpdate:
   IfWinNotExist ,ahk_id %hw_tray%
   {
      gosub CreateWindow
;      reload
   }
   gosub MainUpdate
return

;This just attaches the toolbar
DockIt(Parent,Child)
{
   return DllCall("SetParent",UInt,Child,UInt,Parent)
}

;This function checks what kind the toolbar is and gets the windows handle
FindToolbar(Name)
{   
   global tX, tY
   loop
   {
      tX=5
      tY=5
      hwnd:=WinExist("ahk_class BaseBar",Name) ; Find Toolbar window
      if Not hwnd
      {
         tX=0
         tY=0
         WinExist("ahk_class Shell_TrayWnd") ; Find Systemtray
         WinGet, Controls ,ControlList ;Get list of all controls
         Loop, Parse, Controls, `n
         {
            ControlGetText, CurControl , %A_LoopField%
            if CurControl=%Name% ;Find the toolbar we want by comparing controls Text
               ControlGet, hwnd, Hwnd,,%A_LoopField% ;Get the handle for the toolbar
         }
      }
      if hwnd
         break
   }
   return hwnd
}