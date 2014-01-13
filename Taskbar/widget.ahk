#NoEnv
#include ReRebar.ahk
CoordMode, Mouse , Screen
taskbar := {}
taskbar.base := ReRebar

ctrlname:="ReBarWindow321"
shellname:="Shell_TrayWnd"
traytext:="Notification Area"
trayname:="ToolbarWindow321"
widgetwidth:=75
ToolbarName=mDesktopPager


SysGet, VirtualScreenWidth, 78
SysGet, VirtualScreenHeight, 79

WinWait, ahk_class %shellname%        ;Wiat for the TaskBar to exist incase this script is in startup
if ToolbarName <>                       ;ToolbarName is not blank, so find that toolbar
   hw_tray := FindToolbar(ToolbarName)  ;mod by jonib
else                                    ;otherwise, attach to the task bar (with the start button at 0,0)
   hw_tray := DllCall( "FindWindowEx", "uint",0, "uint",0, "str","Shell_TrayWnd", "uint",0 )



WinGetPos , bX, bY, , , ahk_class %shellname%


ControlGet, hwnd, Hwnd,,%ctrlname%, ahk_class %shellname%

ControlGetPos , cX, cY, cWidth, cHeight, %ctrlname%, ahk_class %shellname%

twidth:=round((cHeight*VirtualScreenWidth)/VirtualScreenHeight)

widgetwidth:=twidth*4


cWidth:=cWidth-widgetwidth
wx:=(cX+cWidth)+bx-4
wy:=cy+by
	
	
ControlGetPos , tX, tY, tWidth, tHeight, %trayname%, ahk_class %shellname%, %traytext%







If (!pToken := Gdip_Startup()){
  MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system!
  ExitApp
}

onexit cleanup
   Gui Margin, 0, 0 
gui, -caption +toolwindow +
gui, color, black
Gui, 1: Add, Picture,HWNDc1 section x0 y0 h%cHeight% w%widgetwidth%  0xE  vb1, %ToolbarName%

Gui, Show, x%wx% y%wy% h%cHeight% w%widgetwidth%, mDesktop Widget



  Process Exist
  WinGet GuiID, ID, ahk_pid %ErrorLevel%
DockIt(hw_tray,GuiID)

 Gui Show, x0 y0
drawdesktops(b1,4)

if not toolbarname
{
gosub rebar
settimer, rebar, 1000
}

ControlGetPos , tX, tY, tWidth, tHeight, ,ahk_id %hw_tray%
;ControlMove, , 200, , %widgetwidth%,  , ahk_id %hw_tray%

WM_MOUSEMOVE = 0x200 
OnMessage( WM_MOUSEMOVE, "HandleMessage" ) 
return 



 
 drawdesktops(ByRef Variable, number=1)
	{
		global ratio
		th=10
		GuiControlGet, Pos, Pos, Variable

		GuiControlGet, hwnd, hwnd, Variable

		pBrushFront := Gdip_BrushCreateSolid(0xff000000), pBrushBack := Gdip_BrushCreateSolid(0xff333333)
	pBrushWhite := Gdip_BrushCreateSolid(0xffFFFFFF)
	
	pPen := Gdip_CreatePen(0xff000000, 1)
		Font = Arial
		pBitmap := Gdip_CreateBitmap(Posw, Posh), G := Gdip_GraphicsFromImage(pBitmap), Gdip_SetSmoothingMode(G, 4)
			
SysGet, VirtualScreenWidth, 78
SysGet, VirtualScreenHeight, 79


		
		twidth:=(Posh*VirtualScreenWidth)/VirtualScreenHeight

		ratio:=VirtualScreenWidth/twidth
		
	sWidth:=Posw/number
	sx:=0

	swidth:=twidth
loop %number%
{	
	sx:=round(sWidth*(a_index-1))

	tx:=sx+(sWidth/2)
	Gdip_FillRectangle(G, pBrushBack, sx, 0, sWidth, Posh)
	
	if a_index=1
	{
	
	WinGet, id, list,,, Program Manager
	Loop, %id%
	{
		this_id := id%A_Index%
		WinGetPos , tX, tY, tW, tH, ahk_id %this_id% 
		if (tx>0 and tw>0)
		{
		
		
			MtX:=round(tx/ratio)
			MtY:=round(ty/ratio)
			MtW:=round(tw/ratio)
			MtH:=round(th/ratio)
			
		
			Gdip_FillRectangle(G, pBrushWhite, MtX, MtY, MtW, MtH)
			
			Gdip_DrawRectangle(G, pPen, MtX, MtY, MtW, MtH)
			
		}

		
		
		
	}


	
	
	
	}
	
	
	Options = x%sx% y5p w%sWidth%  Center cbbffffff r4 s20  Italic
	test:=Gdip_TextToGraphics(G,a_index, Options, Font, 20, 20,1)

	Gdip_TextToGraphics(G,a_index, Options, Font, 20, 20)
}

		hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
		; ... and set it to the hwnd we found for the picture control
		SetImage(hwnd, hBitmap)

		; We then must delete everything we created
		; So the 2 brushes must be deleted
		; Then we can delete the graphics, our gdi+ bitmap and the gdi bitmap
		Gdip_DeleteBrush(pBrushFront), Gdip_DeleteBrush(pBrushBack)
		Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
		Return, 0


	}
 
   

rebar:
 taskbar.resize(ctrlname, shellname, cWidth)
return



esc::
guiclose:
cleanup:

Gdip_Shutdown(pToken)
ExitApp



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

~lbutton::

MouseGetPos, mX, mY, mWin, mCtrl

ControlGetText, ctrl , %mCtrl%, ahk_id %mWin%
if (ctrl=ToolbarName)
{

mx:=(mx-wx)*ratio
my:=(my-wy)*ratio
test:=Win_FromPoint(25, 25) 
msgbox %test%
Win_Move(test, 0, 0)
}
return


HandleMessage( p_w, p_l, p_m, p_hw )
{
   global   WM_SETCURSOR, WM_MOUSEMOVE
   static   URL_hover, h_cursor_hand, h_old_cursor
  
	

}
