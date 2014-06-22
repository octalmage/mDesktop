#SingleInstance,force
global WB
Gui Add, ActiveX, x0 y0 h440 w680 vWB, Shell.Explorer
ComObjConnect(WB, WB_events) ; Connect WB's events to the WB_events class object.
Gui ,Show , w680 h440, mDesktop
path=file:///%A_ScriptDir%\index.html
WB.Navigate(path)

return
 
class WB_events
{
	NavigateComplete2(wb, NewURL)
	{
	}
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
 
 
ComVar(Type=0xC){
static base := { __Get: "ComVarGet", __Set: "ComVarSet", __Delete: "ComVarDel" }
; Create an array of 1 VARIANT. This method allows built-in code to take
; care of all conversions between VARIANT and AutoHotkey internal types.
arr := ComObjArray(Type, 1)
; Lock the array and retrieve a pointer to the VARIANT.
DllCall("oleaut32\SafeArrayAccessData", "ptr", ComObjValue(arr), "ptr*", arr_data)
; Store the array and an object which can be used to pass the VARIANT ByRef.
return { ref: ComObjParameter(0x4000|Type, arr_data), _: arr, base: base }
}
ComVarGet(cv, p*) { ; Called when script accesses an unknown field.
if p.MaxIndex() = "" ; No name/parameters, i.e. cv[]
return cv._[0]
}
ComVarSet(cv, v, p*) { ; Called when script sets an unknown field.
if p.MaxIndex() = "" ; No name/parameters, i.e. cv[]:=v
return cv._[0] := v
}
ComVarDel(cv) { ; Called when the object is being freed.
; This must be done to allow the internal array to be freed.
DllCall("oleaut32\SafeArrayUnaccessData", "ptr", ComObjValue(cv._))
}
