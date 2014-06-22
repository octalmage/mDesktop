#SingleInstance,force
Gui Add, ActiveX, x0 y0 h440 w680 vWB, Shell.Explorer
ComObjConnect(WB, WB_events) ; Connect WB's events to the WB_events class object.
Gui ,Show , w680 h440, mDesktop
path=file:///%A_ScriptDir%\settings.html
WB.Navigate(path)

return
 
class WB_events
{
	BeforeNavigate2(dsp , url, Flags, TargetFrameName , PostData, Headers, cancel, pw)
	{
		if (url == "event:test")
		{
			MsgBox test pressed
         if (ComObjType(Cancel) = 0x400B)  ; Safety check
			    NumPut(-1, ComObjValue(Cancel), "short")
		}
		return
	}
}
 
GuiClose:
ExitApp
