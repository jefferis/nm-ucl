#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Channel Graph Functions
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last Modified 16 March 2005
//
//	Functions for displaying and maintaining channel graphs
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDF(chanNum) // return Channel graph full-path folder name
	Variable chanNum // (-1) for current channel
	
	if (chanNum == -1)
		chanNum = NumVarOrDefault("CurrentChan", 0)
	endif
	
	return GetDataFolder(1) + ChanGraphName(chanNum) + ":"
	
End // ChanDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanGraphName(chanNum)
	Variable chanNum
	
	return GetGraphName("Chan", chanNum)
	
End // ChanGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentChanGraphName()

	return ChanGraphName(NumVarOrDefault("CurrentChan", 0))
	
End // CurrentChanGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDisplayWave(chanNum) // display waves are in NMDF()
	Variable chanNum
	
	return NMDF() + GetWaveName("Display", chanNum, 0)
	
End // ChanDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentChanDisplayWave() 
	
	return ChanDisplayWave(NumVarOrDefault("CurrentChan", 0))
	
End // ChanDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckChan() // check chan package globals

	String df = PackDF("Chan")
	
	if (DataFolderExists(df) == 0)
		return -1
	endif
	
	CheckNMvar(df+"ToFront", 1)		// graph to front (0) off (1) on
	CheckNMvar(df+"GridFlag", 1)		// graph grid display (0) off (1) on
	CheckNMvar(df+"Overlay", 0)		// number of waves to overlay (0) none
	CheckNMvar(df+"DTflag", 0)		// F(t) (0) none (1) d/dt (2) dd/dt*dt (3) integral (4) normalize
	CheckNMvar(df+"SmthNum", 0)	// wave smooth number (0) none
	
	CheckNMstr(df+"SmthAlg", "")		// wave smooth algorithm
	
	CheckNMvar(df+"AutoScale", 1)	// auto scale (0) off (1) on
	CheckNMvar(df+"Xmin", 0)			// x-min scale value
	CheckNMvar(df+"Xmax", 1)		// x-max scale value
	CheckNMvar(df+"Ymin", 0)			// y-min scale value
	CheckNMvar(df+"Ymax", 1)		// y-max scale value
	
	CheckNMvar(df+"GX0", Nan)		// graph left position
	CheckNMvar(df+"GY0", Nan)		// graph top position
	CheckNMvar(df+"GX1", Nan)		// graph right position
	CheckNMvar(df+"GY1", Nan)		// graph bottom position
	
	CheckNMstr(df+"TraceColor", "0,0,0") // rgb
	CheckNMstr(df+"OverlayColor", "34816,34816,34816") // rgb
	
	return 0

End // CheckChan

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanConfigHook()

	Variable ccnt, cbgn, cend = NumVarOrDefault("NumChannels", 0)-1
	String df, ndf = NMDF(), pdf = PackDF("Chan")
	
	String event = StrVarOrDefault(ndf+"ConfigHookEvent", "")
	
	if (StringMatch(event, "kill") == 0)
		return 0 // run function only on "kill" table event
	endif

	DoAlert 1, "Update current displays with your new channel configurations?"
	
	if (V_flag != 1)
		return 0
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		df = ChanDF(ccnt)
		
		if (DataFolderExists(df) == 1)
			KillDataFolder $df
		endif
		
		DuplicateDataFolder $LastPathColon(pdf, 0), $LastPathColon(df, 0)
		
	endfor
	
	ChanGraphsUpdate(1)
	
End // ChanConfigHook

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckChanSubFolder(chanNum)
	Variable chanNum // (-1) for all
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String df, pdf = PackDF("Chan")
	
	CheckPackage("Chan", 0) // defaults package folder
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		df = ChanDF(ccnt)
		
		if (DataFolderExists(df) == 1)
			continue
		endif
		
		DuplicateDataFolder $LastPathColon(pdf, 0) $LastPathColon(df, 0)
	
	endfor

End // CheckChanSubFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFolderCopy(chanNum, fromDF, toDF, saveScales)
	Variable chanNum // (-1) for all
	String fromDF, toDF
	Variable saveScales
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
		
		if (DataFolderExists(fromDF+ChanGraphName(ccnt)) == 0)
			continue
		endif
	
		if (DataFolderExists(toDF+ChanGraphName(ccnt)) == 1)
			KillDataFolder $(toDF+ChanGraphName(ccnt))
		endif
		
		if (saveScales == 1)
			ChanScaleSave(ccnt)
		endif
		
		DuplicateDataFolder $(fromDF+ChanGraphName(ccnt)), $(toDF+ChanGraphName(ccnt))
		
	endfor

End // ChanFolderCopy

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Chan graph functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphMake(chanNum) // create channel display graph
	Variable chanNum // channel number

	Variable scale, grid, y0 = 5
	String cc = num2str(chanNum), df = ChanDF(chanNum)
	
	String Computer = StrVarOrDefault(NMDF()+"Computer", "mac")
	
	String gName = ChanGraphName(chanNum)
	String wName = ChanDisplayWave(chanNum)
	
	String tcolor = StrVarOrDefault(df+"TraceColor", "0,0,0")
	
	CheckChanSubFolder(chanNum)
	
	Make /O $wName = Nan
	
	// kill waves that conflict with graph name
	
	DoWindow /K $gName
	Display /W=(0,0,0,0) $wName
	DoWindow /C $gName
		
	ModifyGraph standoff(left)=0, standoff(bottom)=0
	ModifyGraph margin(left)=60, margin(right)=0, margin(top)=19, margin(bottom)=0
	Execute /Z "ModifyGraph rgb=(" + tcolor + ")"
	ModifyGraph wbRGB = (43690,43690,43690), cbRGB = (43690,43690,43690) // set margins gray
	
	if (StringMatch(computer, "mac") == 1)
		y0 = 3
	endif
	
	PopupMenu $("PlotMenu"+cc), pos={0,0}, size={15,0}, bodyWidth= 20, mode=1, value=" ;Grid;XLabel;YLabel;FreezeX;FreezeY;Off;", proc=ChanPopup
	SetVariable $("Overlay"+cc), title="Overlay", pos={50,y0-1}, size={90,50}, limits={0,10,1}, value=$(df+"Overlay"), proc=ChanSetVariable
	SetVariable $("SmoothSet"+cc), title="Smooth", pos={200,y0-1}, size={90,50}, limits={0,inf,1}, value=$(df+"SmthNum"), proc=ChanSetVariable
	CheckBox $("FtCheck"+cc), title="F(t)", pos={360,y0}, size={16,18}, value=0, proc=ChanCheckbox
	CheckBox $("ToFront"+cc), title="To Front", pos={460,y0}, size={16,18}, value=0, proc=ChanCheckbox
	CheckBox $("ScaleCheck"+cc), title="Autoscale", pos={580,y0}, size={16,18}, value=1, proc=ChanCheckbox
	
	ChanOverlay(chanNum, NumVarOrDefault(df+"Overlay", 0))
	
	//ChanGraphMove(chanNum)
	ChanGraphsMove() // resize all windows
	
End // ChanGraphMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsUpdate(updateControls) // update channel display graphs
	Variable updateControls // (0) no (1) yes
	
	String sName, dName, ddName, gName, fName, df, ndf = NMDF()
	Variable ccnt, autoscale, makeFlag, count
	
	Variable scaleblock = NumVarOrDefault(ndf+"ChanScaleSaveBlock", 0)
	Variable numChannels = NumVarOrDefault("NumChannels", 0)
	Variable currentWave = NumVarOrDefault("CurrentWave", 0)
	
	fname = NMFolderListName("")
	
	for (ccnt = 0; ccnt < numChannels; ccnt+=1)
	
		df = ChanDF(ccnt)
		gName = ChanGraphName(ccnt)
		dName = ChanDisplayWave(ccnt) // display wave
		ddName = GetPathName(dName,0)
		sName = ChanWaveName(ccnt, currentWave) // source wave
		
		CheckChanSubFolder(ccnt)
		
		if (NumVarOrDefault(df+"On", 1) == 0)
			ChanGraphClose(ccnt, 0)
			continue
		endif
	
		if (Wintype(gName) == 0)
			updateControls = 0
			ChanGraphMake(ccnt)
			ChanGraphControlsUpdate(ccnt)
			scaleblock = 1
		endif
		
		autoscale = NumVarOrDefault(df+"AutoScale", 1)
		
		if (scaleblock == 0)
			ChanScaleSave(ccnt)
		endif
		
		ChanGraphMove(ccnt)
		
		if (strlen(fName) > 0)
			DoWindow /T $gName, fName + " : " + sName
		else
			DoWindow /T $gName,  sName
		endif
	
		if (NumVarOrDefault(df+"Overlay", 0) > 0)
			ChanOverlayUpdate(ccnt)
		endif
		
		if ((ChanWaveMake(ccnt, sName, dName) < 0) && (WaveExists($dName) == 1))
			Wave Dsply = $dName
			Dsply = Nan
		endif
		
		if (updateControls == 1)
			ChanGraphControlsUpdate(ccnt)
		endif
		
		//if (numpnts($dName) < 0) // if waves have Nans, change mode to line+symbol
			
		//	WaveStats /Q $dName
			
		//	count = (V_numNaNs * 100 / V_npnts)
	
		//	if ((numtype(count) == 0) && (count > 25))
		//		ModifyGraph /W=$gName mode($ddName)=4
		//	else
		//		ModifyGraph /W=$gName mode($ddName)=0
		//	endif
		
		//endif
		
		if (autoscale == 1)
		
			SetAxis /A/W=$gName
			
		else
		
			ChanGraphAxesSet(ccnt)
			
			if (makeFlag == 1)
				ChanScaleSave(ccnt)
			endif
			
		endif
	
	endfor
	
	KillVariables /Z $(ndf+"ChanScaleSaveBlock")

End // ChanGraphsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphControlsUpdate(chanNum)
	Variable chanNum
	
	String gName = ChanGraphName(chanNum)
	String df = ChanDF(chanNum)
	String cc = num2str(chanNum)
	
	Variable ft = NumVarOrDefault(df+"DTflag", 0)
	Variable tofront = NumVarOrDefault(df+"ToFront", 1)
	Variable autoscale = NumVarOrDefault(df+"AutoScale", 1)
	Variable grid = NumVarOrDefault(df+"GridFlag", 1)
	
	Variable currentWave = NumVarOrDefault("CurrentWave", 0)
	
	String sName = ChanWaveName(chanNum, currentWave) // source wave
	
	Label /W=$gName bottom ChanLabel(chanNum, "x", sName)
		
	SetVariable $("Overlay"+cc), value=$(df+"Overlay"), win=$gName
	SetVariable $("SmoothSet"+cc), value=$(df+"SmthNum"), win=$gName
	
	switch(ft)
		default:
			Label /W=$gName left ChanLabel(chanNum, "y", sName)
			CheckBox $("FtCheck"+cc), value=0, title = "F(t)", win=$gName
			break
		case 1:
			Label /W=$gName left "d/dt"
			CheckBox $("FtCheck"+cc), value=1, title = "d/dt", win=$gName
			break
		case 2:
			Label /W=$gName left "dd/dt*dt"
			CheckBox $("FtCheck"+cc), value=1, title = "dd/dt*dt", win=$gName
			break
		case 3:
			Label /W=$gName left "integral"
			CheckBox $("FtCheck"+cc), value=1, title = "Integral", win=$gName
			break
		case 4:
			Label /W=$gName left "normalized"
			CheckBox $("FtCheck"+cc), value=1, title = "normalize", win=$gName
			break
	endswitch
	
	CheckBox $("ScaleCheck"+cc), value=autoscale, win=$gName
	CheckBox $("ToFront"+cc), value=tofront, win=$gName
	
	ModifyGraph /W=$gName grid(bottom)=grid, grid(left)=grid, gridRGB=(24576,24576,65535)
	
End // ChanGraphControlsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsReset()

	ChanGraphClose(-2, 0) // close unecessary windows
	ChanOverlayKill(-1) // kill unecessary waves
	ChanOverlayClear(-1)
	ChanGraphTagsKill(-1)
	SetNMvar(NMDF()+"ChanScaleSaveBlock", 1)

End // ChanGraphsReset

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphTagsKill(chanNum)
	Variable chanNum // (-1) for all
	
	Variable icnt, ccnt, cbgn = chanNum, cend = chanNum
	String gName, aName, aList
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		gName = ChanGraphName(ccnt)
		
		if (Wintype(gName) == 0)
			continue
		endif
		
		alist = AnnotationList(gName) // list of tags
			
		for (icnt = 0; icnt < ItemsInList(alist); icnt += 1)
			aName = StringFromList(icnt, alist)
			Tag /W=$gName /N=$aName /K // kill tags
		endfor
		
	endfor
	
End // ChanGraphTagsKill

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsToFront()

	Variable ccnt, cbgn, cend = (NumVarOrDefault("NumChannels", 0) - 1)
	String df, gName
	
	for (ccnt = cbgn; ccnt <= cend; ccnt+=1)
		df = ChanDF(ccnt)
		if (NumVarOrDefault(df+"ToFront", 1) == 1)
			gName = ChanGraphName(ccnt)
			DoWindow /F $gName
		endif
	endfor
	
End // ChanGraphsToFront

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphAxesSet(chanNum) // set channel graph size and placement
	Variable chanNum // channel number
	
	if (IsChanGraph(chanNum) == 0)
		return 0
	endif
	
	String gName = ChanGraphName(chanNum)
	String wName = ChanDisplayWave(chanNum)
	String df = ChanDF(chanNum)
	
	Variable autoX = NumVarOrDefault(df+"AutoScaleX", 0)
	Variable autoY = NumVarOrDefault(df+"AutoScaleY", 0)
	
	Variable xmin = NumVarOrDefault(df+"Xmin", 0)
	Variable xmax = NumVarOrDefault(df+"Xmax", 1)
	Variable ymin = NumVarOrDefault(df+"Ymin", 0)
	Variable ymax = NumVarOrDefault(df+"Ymax", 1)
	
	if (autoX == 1)
		SetAxis /W=$gName/A
		SetAxis /W=$gName left ymin, ymax
		return 0
	elseif (autoY == 1)
		WaveStats /Q/R=(xmin,xmax) $wName
		ymin = V_min
		ymax = V_max
	endif
	
	SetAxis /W=$gName bottom xmin, xmax
	SetAxis /W=$gName left ymin, ymax
		
End // ChanGraphAxesSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsMove()

	Variable ccnt
	Variable numChannels = NumVarOrDefault("NumChannels", 0)
	
	for (ccnt = 0; ccnt < numChannels; ccnt+=1)
		ChanGraphMove(ccnt)
	endfor

End // ChanGraphsMove

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphMove(chanNum) // set channel graph size and placement
	Variable chanNum // channel number
	
	if (IsChanGraph(chanNum) == 0)
		return 0
	endif
	
	Variable yinc, width, height, numchan, ccnt, where
	Variable xoffset, yoffset // default offsets
	
	String ndf = NMDF(), cdf = ChanDF(chanNum)
	
	Variable x0 = NumVarOrDefault(cdf+"GX0", Nan)
	Variable y0 = NumVarOrDefault(cdf+"GY0", Nan)
	Variable x1 = NumVarOrDefault(cdf+"GX1", Nan)
	Variable y1 = NumVarOrDefault(cdf+"GY1", Nan)
	
	Variable yPixels = NumVarOrDefault(ndf+"yPixels", 700)
	String Computer = StrVarOrDefault(ndf+"Computer", "mac")
	
	String gName = ChanGraphName(chanNum)
	
	numchan = NumChanGraphs() // counts on/off
	
	for (ccnt = 0; ccnt < chanNum; ccnt+=1)
		if (NumVarOrDefault(ChanDF(ccnt)+"On", 1) == 1)
			where += 1
		endif
	endfor
	
	if (numtype(x0 * y0 * x1 * y1) > 0) // compute graph coordinates
	
		strswitch(Computer)
			case "pc":
				x0 = 8
				y0 = 37
				width = 522
				height = yPixels / (numchan + 2)
				yinc = height + 20
				break
			default:
				x0 = 10
				y0 = 44
				width = 690
				height = yPixels / (numchan + 1)
				yinc = height + 30
				break
		endswitch
		
		x0 += xoffset
		y0 += yoffset + yinc*where
		x1 = x0 + width
		y1 = y0 + height
		
		SetNMvar(cdf+"GX0", x0)
		SetNMvar(cdf+"GY0", y0)
		SetNMvar(cdf+"GX1", x1)
		SetNMvar(cdf+"GY1", y1)
	
	endif
	
	MoveWindow /W=$gName x0, y0, x1, y1

End // ChanGraphMove

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphClose(chanNum, KillFolders)
	Variable chanNum // (-1) for all (-2) all unecessary
	Variable KillFolders // to kill global variables

	Variable ccnt, cbgn = chanNum, cend = chanNum
	String gName, ndf = NMDF()
	
	if (NumVarOrDefault(ndf+"ChanGraphCloseBlock", 0) == 1)
		KillVariables /Z $(ndf+"ChanGraphCloseBlock")
		return -1
	endif
	
	if (chanNum == -1)
		cbgn = 0
		cend = 9
	elseif (chanNum == -2)
		cbgn = NumVarOrDefault("NumChannels", 0)
		cend = cbgn + 5
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		gName = ChanGraphName(ccnt)
		
		DoWindow /K $gName
		
		if ((KillFolders == 1) && (DataFolderExists(gName) == 1))
			KillDataFolder $gName
		endif
		
	endfor
	
	return 0

End // ChanGraphClose

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphClear(chanNum)
	Variable chanNum // (-1) for all
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String wName
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		wName = ChanDisplayWave(ccnt)
		
		ChanOverlayClear(ccnt)
		
		if (WaveExists($wName) == 1)
			Wave wtemp = $wName
			wtemp = Nan
		endif
		
	endfor

End // ChanGraphClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NumChanGraphs()
	Variable ccnt, count

	for (ccnt = 0; ccnt < NumVarOrDefault("NumChannels", 0); ccnt+=1)
		if (NumVarOrDefault(ChanDF(ccnt)+"On", 1) == 1)
			count += 1
		endif
	endfor
	
	return count

End // NumChanGraphs

//****************************************************************
//****************************************************************
//****************************************************************

Function IsChanGraph(chanNum)
	Variable chanNum
	
	if (Wintype(ChanGraphName(chanNum)) == 1)
		return 1
	else
		return 0
	endif

End // IsChanGraph

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Chan graph control functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ChanControlsDisable(chanNum, select)
	Variable chanNum // (-1) for all
	String select // Overlay, Smooth, F(t), autoscale, PlotMenu, ToFront (e.g. "11111" for all)
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String cc, gname
	
	select += "000000"
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
		
		if (IsChanGraph(ccnt) == 0)
			continue
		endif
		
		cc = num2str(ccnt)
		gName = ChanGraphName(ccnt)
	
		SetVariable $("Overlay"+cc), disable=binarycheck(str2num(select[0,0])), win=$gName
		SetVariable $("SmoothSet"+cc), disable=binarycheck(str2num(select[1,1])), win=$gName
		CheckBox $("FtCheck"+cc), disable=binarycheck(str2num(select[2,2])), win=$gName
		CheckBox $("ScaleCheck"+cc), disable=binarycheck(str2num(select[3,3])), win=$gName
		PopupMenu $("PlotMenu"+cc), disable=binarycheck(str2num(select[4,4])), win=$gName
		CheckBox $("ToFront"+cc), disable=binarycheck(str2num(select[5,5])), win=$gName
		
	endfor
	
	return 0

End // ChanControlsDisable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanControlPrefix(ctrlName)
	String ctrlName
	
	Variable icnt
	
	for (icnt = strlen(ctrlName)-1; icnt > 0; icnt -= 1)
		if (numtype(str2num(ctrlName[icnt,icnt])) > 0)
			break
		endif
	endfor
	
	return ctrlName[0,icnt]

End // ChanControlPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanPopup(ctrlName, popNum, popStr) : PopupMenuControl // display graph menu
	String ctrlName; Variable popNum; String popStr
	
	Variable chanNum
	
	sscanf ctrlName, "PlotMenu%f", chanNum // determine chan number
	
	PopupMenu $ctrlName, mode=1 // reset the drop-down menu
	
	ChanCall(popStr, chanNum, "")

End // ChanPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanCheckbox(ctrlName, checked) : CheckBoxControl // change differentiation flag
	String ctrlName; Variable checked
	
	Variable chanNum
	String numstr = num2str(checked)
	String cname = ChanControlPrefix(ctrlName)
	
	sscanf ctrlName, cname + "%f", chanNum // determine chan number
	
	return ChanCall(cname, chanNum, numstr)

End // ChanCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	Variable chanNum
	
	strswitch(ChanControlPrefix(ctrlName))
	
		case "SmoothSet":
			sscanf ctrlName, "SmoothSet%f", chanNum // determine chan number
			return ChanCall("Smooth", chanNum, varStr)

		case "Overlay":
			sscanf ctrlName, "Overlay%f", chanNum // determine chan number
			return ChanCall("Overlay", chanNum, varStr)
	
	endswitch
	
End // ChanSetVariable

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Chan global variable functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ChanCall(fxn, chanNum, select)
	String fxn
	Variable chanNum
	String select
	
	Variable snum = str2num(select)

	strswitch(fxn)
	
		case "Grid":
			return ChanGridToggle(chanNum)
			
		case "XLabel":
			return ChanLabelCall(chanNum, "x")
			
		case "YLabel":
			return ChanLabelCall(chanNum, "y")
			
		case "FreezeX":
			return ChanAutoScaleY(chanNum, 1)
		
		case "FreezeY":
			return ChanAutoScaleX(chanNum, 1)

		case "Off":
			return ChanOnCall(chanNum, 0)
			
		case "Overlay":
			return ChanOverlayCall(chanNum, snum)
			
		case "Smooth":
			return ChanSmthNumCall(chanNum, snum)
			
		case "AutoScale":
		case "ScaleCheck":
			return ChanAutoScaleCall(chanNum, snum)
			
		case "ToFront":
			return ChanToFrontCall(chanNum, snum)
			
		case "F(t)":
		case "FtCheck":
			return ChanFuncCall(chanNum, -snum)
	
	endswitch
	
End // ChanCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncAsk(chanNum) // request chan F(t) function
	Variable chanNum
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	
	Variable ft =NumVarOrDefault(ChanDF(chanNum)+"DTflag", 0)
	
	Prompt ft, "choose function:", popup "d/dt;dd/dt*dt;integral;normalize;"
	DoPrompt "Channel Function", ft
	
	if (V_flag == 1)
		ft = -1 // cancel
	endif
	
	return ft

End // ChanFuncAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncCall(chanNum, ft)
	Variable chanNum // channel number
	Variable ft // (0) none (1) d/dt (2) dd/dt*dt (3) integral (4) normalize
	
	String vlist = ""
	
	if (ft < 0)
		ft = ChanFuncAsk(chanNum)
	endif
	
	vlist = NMCmdNum(chanNum, vlist)
	vlist = NMCmdNum(ft, vlist)
	NMCmdHistory("ChanFunc", vlist)
	
	return ChanFunc(chanNum, ft)

End // ChanFuncCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFunc(chanNum, ft) // set chan F(t) function
	Variable chanNum // channel number
	Variable ft // (0) none (1) d/dt (2) dd/dt*dt (3) integral (4) normalize
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	
	SetNMVar(ChanDF(chanNum)+"DTflag", ft)
	ChanGraphsUpdate(1)
	
	return 0

End // ChanFunc

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSmthNumCall(chanNum, smthNum)
	Variable chanNum, smthNum
	
	String vlist = ""
	
	vlist = NMCmdNum(chanNum, vlist)
	vlist = NMCmdNum(smthNum, vlist)
	NMCmdHistory("ChanSmthNum", vlist)
	
	return ChanSmthNum(chanNum, smthNum)

End // ChanSmthNumCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSmthNum(chanNum, smthNum) // set chan smooth num
	Variable chanNum, smthNum
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	
	String df = ChanDF(chanNum)
	String alg = ChanSmthAlg(chanNum)
	
	strswitch(alg)
		case "binmomial":
		case "boxcar":
			break
		default:
			alg = ""
	endswitch
	
	if ((strlen(alg) == 0) && (smthNum > 0))
	
		alg = ChanSmthAlgAsk(chanNum)
		
		if (strlen(alg) == 0)
			setNMvar(df+"SmthNum", 0)
		endif
		
	endif
	
	if (smthNum == 0)
		alg = ""
	endif
	
	SetNMvar(df+"SmthNum", smthNum)
	SetNMstr(df+"SmthAlg", alg)
	
	ChanGraphsUpdate(1)
	
	return 0

End // ChanSmthNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanSmthAlgAsk(chanNum) // request chan smooth alrgorithm
	Variable chanNum // (-1) for current channel
	
	if (chanNum == -1)
		chanNum = NumVarOrDefault("CurrentChan", 0)
	endif
	
	if (IsChanGraph(chanNum) == 0)
		return ""
	endif
	
	String alg = ChanSmthAlg(chanNum)
	
	Prompt alg, "choose channel's smoothing algorithm:", popup "binomial;boxcar;none"
	DoPrompt "Change Smoothing Algorithm", alg
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	return alg

End // ChanSmthAlgAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanSmthAlg(chanNum) // request chan smooth alrgorithm
	Variable chanNum // (-1) for current channel
	
	if (chanNum == -1)
		chanNum = NumVarOrDefault("CurrentChan", 0)
	endif

	String alg = StrVarOrDefault(ChanDF(chanNum)+"SmthAlg", "")
	
	strswitch(alg)
		case "binomial":
		case "boxcar":
			break
		default:
		alg = ""
	endswitch
	
	return alg

End // ChanSmthAlg

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanLabelCall(chanNum, xy) // set channel labels
	Variable chanNum
	String xy // "x" or "y"
	
	String vlist = ""
	
	String labelStr = ChanLabel(chanNum, xy, "")
	
	Prompt labelStr, xy + " label:"
	
	DoPrompt "Set Channel Label", labelStr
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	vlist = NMCmdNum(chanNum, vlist)
	vlist = NMCmdNum(2, vlist)
	vlist = NMCmdStr(xy, vlist)
	vlist = NMCmdStr(labelStr, vlist)
	
	NMCmdHistory("ChanLabelSet", vlist)
		
	ChanLabelSet(chanNum, 2, xy, labelStr)
	
	return 0

End // ChanLabelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGridToggle(chanNum)
	Variable chanNum // channel number
	
	String vlist = "", df = ChanDF(chanNum)
	String gName = ChanGraphName(chanNum)
	
	Variable on = !NumVarOrDefault(df+"GridFlag", 0)
	
	vlist = NMCmdNum(chanNum, vlist)
	vlist = NMCmdNum(on, vlist)
	NMCmdHistory("ChanGrid", vlist)
	
	ChanGrid(chanNum, on)
	
End // ChanGridToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGrid(chanNum, on)
	Variable chanNum // channel number
	Variable on // (0) no (1) yes
	
	String df = ChanDF(chanNum)
	String gName = ChanGraphName(chanNum)
	
	if (on == 0)
		SetNMvar(df+"GridFlag", 0)
		ModifyGraph /W=$gName grid=0
	else
		SetNMvar(df+"GridFlag", 1)
		ModifyGraph /W=$gName grid=1
	endif
	
	ChanGraphsUpdate(1)
	
End // ChanGrid

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOnAllCall()

	NMCmdHistory("ChanOnAll","")
	return ChanOnAll()

End // ChanOnAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOnAll()

	ChanOn(-1, 1)
	ChanGraphsToFront()

	return 0

End // ChanOnAll

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOnCall(chanNum, on)
	Variable chanNum // channel number, or (-1) all
	Variable on // (0) no (1) yes
	
	String vlist = ""
	
	vlist = NMCmdNum(chanNum, vlist)
	vlist = NMCmdNum(on, vlist)
	NMCmdHistory("ChanOn", vlist)
	
	return ChanOn(chanNum, on)
	
End // ChanOnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOn(chanNum, on)
	Variable chanNum // channel number, or (-1) all
	Variable on // (0) no (1) yes
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
		SetNMvar(ChanDF(ccnt)+"On", on)
	endfor
	
	ChanGraphsUpdate(1)
	
	return 0
	
End // ChanOn

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAutoScaleCall(chanNum, on)
	Variable chanNum // channel number
	Variable on // (0) on (1) yes
	
	String vlist = ""
	
	vlist = NMCmdNum(chanNum, vlist)
	vlist = NMCmdNum(on, vlist)
	NMCmdHistory("ChanAutoScale", vlist)
	
	return ChanAutoScale(chanNum, on)
	
End // ChanAutoScaleCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAutoScale(chanNum, on)
	Variable chanNum // channel number
	Variable on // (0) on (1) yes
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	
	String gName = ChanGraphName(chanNum)
	
	if (on == 1)
		SetAxis /A/W=$gName
	else
		ChanScaleSave(chanNum)
	endif
	
	SetNMVar(ChanDF(chanNum)+"AutoScale", on)
	SetNMVar(ChanDF(chanNum)+"AutoScaleX", 0)
	SetNMVar(ChanDF(chanNum)+"AutoScaleY", 0)
	
	ChanGraphsUpdate(1)
	
	return 0

End // ChanAutoScale

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAutoScaleX(chanNum, on)
	Variable chanNum // channel number
	Variable on // (0) on (1) yes
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	
	String gName = ChanGraphName(chanNum)
	String df = ChanDF(chanNum)
	
	SetNMVar(df+"AutoScaleX", on)
	
	if (on == 1)
		SetNMVar(df+"AutoScale", 0)
		SetNMVar(df+"AutoScaleY", 0)
	endif
	
	ChanGraphsUpdate(1)
	
	return 0

End // ChanAutoScaleX

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAutoScaleY(chanNum, on)
	Variable chanNum // channel number
	Variable on // (0) on (1) yes
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	
	String gName = ChanGraphName(chanNum)
	String df = ChanDF(chanNum)
	
	SetNMVar(df+"AutoScaleY", on)
	
	if (on == 1)
		SetNMVar(df+"AutoScale", 0)
		SetNMVar(df+"AutoScaleX", 0)
	endif
	
	ChanGraphsUpdate(1)
	
	return 0

End // ChanAutoScaleY

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanScaleSave(chanNum) // save chan min, max scale values
	Variable chanNum // (-1) for all
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String gName, df, ndf = NMDF()
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)

		if (IsChanGraph(ccnt) == 0)
			continue
		endif
		
		df = ChanDF(ccnt)
		gName = ChanGraphName(ccnt)
		
		if (WinType(gName) == 1)
		
			GetAxis /Q/W=$gName bottom
		
			SetNMvar(df+"Xmin", V_min)
			SetNMvar(df+"Xmax", V_max)
			
			GetAxis /Q/W=$gName left
			
			SetNMvar(df+"Ymin", V_min)
			SetNMvar(df+"Ymax", V_max)
			
			// save graph position
			
			GetWindow $gName wsize
			
			SetNMvar(df+"GX0", V_left)
			SetNMvar(df+"GY0", V_top)
			SetNMvar(df+"GX1", V_right)
			SetNMvar(df+"GY1", V_bottom)
			
		endif
	
	endfor
	
	return 0
	
End // ChanScaleSave

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanXYSet(chanNum, left, right, bottom, top)
	Variable chanNum, left, right, bottom, top
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	
	String gName = ChanGraphName(chanNum)
	
	if (numtype(left*right) == 0)
		SetAxis /W=$gName bottom left, right
		SetNMVar(ChanDF(chanNum)+"AutoScaleX", 0)
	else
		SetNMVar(ChanDF(chanNum)+"AutoScaleX", 1)
	endif
	
	if (numtype(top*bottom) == 0)
		SetAxis /W=$gName left bottom, top
		SetNMVar(ChanDF(chanNum)+"AutoScaleY", 0)
	else
		SetNMVar(ChanDF(chanNum)+"AutoScaleY", 1)
	endif
	
	SetNMVar(ChanDF(chanNum)+"AutoScale", 0)
	
	ChanScaleSave(chanNum)
	ChanGraphsUpdate(1)
	
	return 0

End // ChanXYSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAllX(xmin, xmax)
	Variable xmin, xmax
	Variable ccnt
	
	if ((numtype(xmin*xmax) > 0) || (xmin >= xmax))
		return -1
	endif
	
	for (ccnt = 0; ccnt < NumVarOrDefault("NumChannels", 0); ccnt += 1)
		ChanXYSet(ccnt, xmin, xmax, Nan, NaN)
	endfor
	
	return 0
	
End // ChanAllX

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAllY(ymin, ymax)
	Variable ymin, ymax
	Variable ccnt
	
	if ((numtype(ymin*ymax) > 0) || (ymin >= ymax))
		return -1
	endif
	
	for (ccnt = 0; ccnt < NumVarOrDefault("NumChannels", 0); ccnt += 1)
		ChanXYSet(ccnt, Nan, Nan, ymin, ymax)
	endfor
	
	return 0
	
End // ChanAllY

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayCall(chanNum, overlayNum)
	Variable chanNum, overlayNum
	
	String vlist = ""
	
	vlist = NMCmdNum(chanNum, vlist)
	vlist = NMCmdNum(overlayNum, vlist)
	NMCmdHistory("ChanOverlay", vlist)
	
	return ChanOverlay(chanNum, overlayNum)
	
End // ChanOverlayCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlay(chanNum, overlayNum)
	Variable chanNum, overlayNum
	
	String df = ChanDF(chanNum)
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	
	if ((numtype(overlayNum) > 0) || (overlayNum < 0))
		overlayNum = 0
	endif
	
	ChanOverlayClear(chanNum)
	
	SetNMvar(df+"Overlay", overlayNum)
	SetNMvar(df+"OverlayCount", 1)
	
	ChanOverlayKill(chanNum)
	
	return overlayNum
	
End // ChanOverlay

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayUpdate(chanNum)
	Variable chanNum
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	
	String ndf = NMDF(), df = ChanDF(chanNum)
	
	Variable overlay = NumVarOrDefault(df+"Overlay", 0)
	Variable ocnt = NumVarOrDefault(df+"OverlayCount", 0)
	
	String tcolor = StrVarOrDefault(df+"TraceColor", "0,0,0")
	String ocolor = StrVarOrDefault(df+"OverlayColor", "34816,34816,34816")
	
	if (overlay == 0)
		return -1
	endif
	
	if (ocnt == 0)
		SetNMvar(df+"OverlayCount", 1)
		return 0
	endif
	
	String gName = ChanGraphName(chanNum)
	String dName = ChanDisplayWave(chanNum)
	
	String oName = GetWaveName("Display", chanNum, ocnt)
	String odName = ndf+oName
	
	String wList = TraceNameList(gName,";",1)
	
	if (StringMatch(dName, odName) == 1)
		return -1
	endif
	
	Duplicate /O $dName $odName
	
	if (WhichListItemLax(oName, wList, ";") < 0)
	
		AppendToGraph /W=$gName $odName
		Execute /Z "ModifyGraph /W=" + gName + " rgb(" + oName + ")=(" + ocolor + ")"
		
		oName = GetWaveName("Display", chanNum, 0)
		odName = ndf+oName
		
		RemoveFromGraph /W=$gName/Z $oName
		
		AppendToGraph /W=$gName $odName
		Execute /Z "ModifyGraph /W=" + gName + " rgb(" + oName + ")=(" + tcolor + ")"
		
	endif

	ocnt += 1
	
	if (ocnt > overlay)
		ocnt = 1
	endif
	
	SetNMvar(df+"OverlayCount", ocnt)
	
	return 0

End // ChanOverlayUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayClear(chanNum)
	Variable chanNum // (-1) for all
	
	Variable wcnt, ccnt, cbgn = chanNum, cend = chanNum
	String gName, wName, xName, wList
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		wName = ChanDisplayWave(ccnt)
		xName = GetWaveName("Display", ccnt, 0)
		gName = ChanGraphName(ccnt)
		
		wList = TraceNameList(gName,";",1)
		wList = RemoveFromList(xName, wList)
		
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
			RemoveFromGraph /W=$gName/Z $StringFromList(wcnt, wList)
		endfor
		
		SetNMvar(ChanDF(ccnt)+"OverlayCount", 0)
		
	endfor

End // ChanOverlayClear

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanToFrontCall(chanNum, toFront)
	Variable chanNum, toFront
	
	String vlist = ""
	
	vlist = NMCmdNum(chanNum, vlist)
	vlist = NMCmdNum(toFront, vlist)
	NMCmdHistory("ChanToFront", vlist)
	
	return ChanToFront(chanNum, toFront)
	
End // ChanToFrontCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanToFront(chanNum, toFront)
	Variable chanNum
	Variable toFront // (0) no (1) yes
	
	String df = ChanDF(chanNum)
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	
	if (toFront != 0)
		toFront = 1
	endif
	
	SetNMvar(df+"ToFront", toFront)
	
	return toFront
	
End // ChanToFront

//****************************************************************
//****************************************************************
//****************************************************************
//
//	channel display wave functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveMake(chanNum, srcName, dstName) // create channel waves, based on smooth and dt flags
	Variable chanNum // (-1) all chan
	String srcName, dstName // source and destination wave names
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	Variable ft, smthNum, error
	String smthAlg, df, wName
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
		df = ChanDF(ccnt)
		ft = NumVarOrDefault(df+"DTflag", 0)
		smthNum = NumVarOrDefault(df+"SmthNum", 0)
		smthAlg = ChanSmthAlg(ccnt)
		error += MakeWave(srcName, dstName, ft, smthNum, smthAlg)
	endfor
	
	return error

End // ChanWaveMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWavesClear(chanNum)
	Variable chanNum // (-1) all chan
	
	Variable cbgn = chanNum, cend = chanNum
	Variable wcnt, ccnt, overlay
	String wName, df
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif

	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		df = ChanDF(ccnt)
		overlay = NumVarOrDefault(df+"Overlay", 0)
		
		for (wcnt = 0; wcnt <= overlay; wcnt += 1) // Nan display waves
			wName = NMDF() + GetWaveName("Display", ccnt, wcnt)
			if (WaveExists($wName) == 1)
				Wave wtemp = $wName
				wtemp = Nan
			endif
		endfor
	
	endfor

End // ChanWavesClear

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayKill(chanNum)
	Variable chanNum // (-1) all chan

	Variable cbgn = chanNum, cend = chanNum
	
	Variable wcnt, ccnt, overlay
	String wName, wList, ndf = NMDF()
	
	if (chanNum == -1)
		cbgn = 0; cend = NumVarOrDefault("NumChannels", 0) - 1;
	endif
	
	String saveDF = GetDataFolder(1) // save current directory

	if (DataFolderExists(ndf) == 1)
		SetDataFolder $ndf
	endif

	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		wList = WaveList("Display" + ChanNum2Char(ccnt) + "*", ";", "")
	
		overlay = NumVarOrDefault(ChanDF(ccnt)+"Overlay", 0)
	
		for (wcnt = 0; wcnt <= overlay; wcnt += 1)
			wName = GetWaveName("Display", ccnt, wcnt)
			wList = RemoveFromList(wName, wList)
		endfor
		
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
			wName = StringFromList(wcnt, wList)
		endfor
		
	endfor
	
	SetDataFolder $saveDF // back to original data folder

End // ChanOverlayKill

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Graph Marquee Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function FreezeChanXY() : GraphMarquee // freeze chan graph xy scales
	String vlist = ""

	GetMarquee left, bottom
	
	String gName = WinName(0,1)
	
	if ((V_Flag == 0) || (StringMatch(gName[0,3], "Chan") == 0))
		return -1
	endif
	
	Variable chanNum = ChanChar2Num(gName[4,4])
	
	vlist = NMCmdNum(V_left, vlist)
	vlist = NMCmdNum(V_right, vlist)
	vlist = NMCmdNum(V_bottom, vlist)
	vlist = NMCmdNum(V_top, vlist)
	NMCmdHistory("ChanXYSet", vlist)
	
	ChanXYSet(chanNum, V_left, V_right, V_bottom, V_top)
	
	DoWindow /F NMPanel // this removes marquee
	
	return 0

End // FreezeChanXY

//****************************************************************
//****************************************************************
//****************************************************************

Function FreezeChanX() : GraphMarquee // freeze chan graph x scale
	String vlist = ""

	GetMarquee left, bottom
	
	String gName = WinName(0,1)
	
	if ((V_Flag == 0) || (StringMatch(gName[0,3], "Chan") == 0))
		return -1
	endif
	
	Variable chanNum = ChanChar2Num(gName[4,4])
	
	V_bottom = Nan
	V_top = Nan
	
	vlist = NMCmdNum(V_left, vlist)
	vlist = NMCmdNum(V_right, vlist)
	vlist = NMCmdNum(V_bottom, vlist)
	vlist = NMCmdNum(V_top, vlist)
	NMCmdHistory("ChanXYSet", vlist)
	
	ChanXYSet(chanNum, V_left, V_right, V_bottom, V_top)
	
	DoWindow /F NMPanel // this removes marquee
	
	return 0

End // FreezeChanX

//****************************************************************
//****************************************************************
//****************************************************************

Function FreezeChanY() : GraphMarquee // freeze chan graph x scale
	String vlist = ""

	GetMarquee left, bottom
	
	String gName = WinName(0,1)
	
	if ((V_Flag == 0) || (StringMatch(gName[0,3], "Chan") == 0))
		return -1
	endif
	
	Variable chanNum = ChanChar2Num(gName[4,4])
	
	V_left = Nan
	V_right = Nan
	
	vlist = NMCmdNum(V_left, vlist)
	vlist = NMCmdNum(V_right, vlist)
	vlist = NMCmdNum(V_bottom, vlist)
	vlist = NMCmdNum(V_top, vlist)
	NMCmdHistory("ChanXYSet", vlist)
	
	ChanXYSet(chanNum, V_left, V_right, V_bottom, V_top)
	
	DoWindow /F NMPanel // this removes marquee
	
	return 0

End // FreezeChanY

//****************************************************************
//****************************************************************
//****************************************************************

Function FreezeAllChanX() : GraphMarquee
	String vlist = ""

	GetMarquee left, bottom
	
	String gName = WinName(0,1)
	
	if ((V_Flag == 0) || (StringMatch(gName[0,3], "Chan") == 0))
		return -1
	endif
	
	vlist = NMCmdNum(V_left, vlist)
	vlist = NMCmdNum(V_right, vlist)
	NMCmdHistory("ChanAllX", vlist)
	ChanAllX(V_left, V_right)
	
	DoWindow /F NMPanel // this removes marquee
	
	return 0
	
End // FreezeAllChanX

//****************************************************************
//****************************************************************
//****************************************************************
