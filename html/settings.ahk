#SingleInstance,force
Gui Add, ActiveX,  x0 y0 h440 w680 vWB, Shell.Explorer
ComObjConnect(WB, WB_events)  ; Connect WB's events to the WB_events class object.
Gui ,Show , w680 h440, mDesktop
path=file:///%A_ScriptDir%\index.html
WB.Navigate(path)
;WB.document.parentwindow.execScript("alert('Hello, world!')")
return

class WB_events
{
    NavigateComplete2(wb, NewURL)
    {
		
    }
	BeforeNavigate2(pDisp , url, Flags, TargetFrameName , Headers, cancel*  )
	{
		test := prams[6]
		cancel:=true
		return
	}
}

GuiClose:
ExitApp