class ReRebar
{
	var ctrlname
	var shellname
	var cWidth
	resize(ctrlname, shellname, cWidth)
	{

		ControlMove, %ctrlname%, ,, %cWidth%,  , ahk_class %shellname%
		return (cx+cWidth)
	}


}