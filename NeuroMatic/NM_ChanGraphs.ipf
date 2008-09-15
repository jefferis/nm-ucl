#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Channel Graph Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last Modified 15 May 2007
//
//	Functions for displaying and maintaining channel graphs
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDF(chanNum) // channel folder path
	Variable chanNum // (-1) for current channel
	
	chanNum = ChanNumCheck(chanNum)
	
	return GetDataFolder(1) + ChanGraphName(chanNum) + ":"
	
End // ChanDF

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanNumCheck(chanNum)
	Variable chanNum
	
	if (chanNum < 0)
		chanNum = NMCurrentChan()
	endif
	
	return chanNum
	
End // ChanNumCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanGraphName(chanNum)
	Variable chanNum
	
	return GetGraphName("Chan", ChanNumCheck(chanNum))
	
End // ChanGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentChanGraphName()

	return ChanGraphName(-1)
	
End // CurrentChanGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDisplayWave(chanNum)
	Variable chanNum
	
	return ChanDisplayWaveName(1, chanNum, 0)
	
End // ChanDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentChanDisplayWave() 
	
	return ChanDisplayWave(-1)
	
End // CurrentChanDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDisplayWaveName(directory, chanNum, wavNum)
	Variable directory // (0) no directory (1) include directory
	Variable chanNum
	Variable wavNum
	
	String df = ""
	
	if (directory == 1)
		df = NMDF()
	endif
	
	chanNum = ChanNumCheck(chanNum)
	
	return df + GetWaveName("Display", chanNum, wavNum)
	
End // ChanDisplayWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckChanSubFolder(chanNum)
	Variable chanNum // (-1) for all
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String df, pdf = PackDF("Chan")
	
	if (chanNum == -1)
		cbgn = 0; cend = NMNumChannels() - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		df = ChanDF(ccnt)
		
		if (DataFolderExists(df) == 0)
			NewDataFolder $LastPathColon(df, 0)
		endif
		
		CheckNMvar(df+"SmoothN", NumVarOrDefault(df+"SmthNum", 0))
		CheckNMstr(df+"SmoothA", StrVarOrDefault(df+"SmthAlg", ""))
		CheckNMvar(df+"Overlay", 0)
		CheckNMvar(df+"Ft", NumVarOrDefault(df+"DTflag", 0))
	
	endfor

End // CheckChanSubFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSubFolderDefaultsSet(chanNum)
	Variable chanNum // (-1) for all
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String df, pdf = PackDF("Chan")
	
	if (chanNum == -1)
		cbgn = 0; cend = NMNumChannels() - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		df = ChanDF(ccnt)
		
		if (DataFolderExists(df) == 0)
			NewDataFolder $LastPathColon(df, 0)
		endif
		
		SetNMvar(df+"SmoothN", 0)
		SetNMstr(df+"SmoothA", "")
		SetNMvar(df+"Overlay", 0)
		SetNMvar(df+"Ft", 0)
		SetNMvar(df+"AutoScale", 1)
		SetNMvar(df+"AutoScaleX", 0)
		SetNMvar(df+"AutoScaleY", 0)
	
	endfor

End // ChanSubFolderDefaultsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFolderCopy(chanNum, fromDF, toDF, saveScales)
	Variable chanNum // (-1) for all
	String fromDF, toDF
	Variable saveScales
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	
	if (chanNum == -1)
		cbgn = 0; cend = NMNumChannels() - 1;
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
	Variable gx0, gy0, gx1, gy1
	
	Variable r = NMPanelRGB("r")
	Variable g = NMPanelRGB("g")
	Variable b = NMPanelRGB("b")
	
	chanNum = ChanNumCheck(chanNum)
	
	String cc = num2str(chanNum), df = ChanDF(chanNum)
	
	String Computer = StrVarOrDefault(NMDF()+"Computer", "mac")
	
	String gName = ChanGraphName(chanNum)
	String wName = ChanDisplayWave(chanNum)
	String xWave = NMXwave()
	
	String tcolor = StrVarOrDefault(df+"TraceColor", "0,0,0")
	
	CheckChanSubFolder(chanNum)
	
	ChanGraphsSetCoordinates()
	
	gx0 = NumVarOrDefault(df+"GX0", Nan)
	gy0 = NumVarOrDefault(df+"GY0", Nan)
	gx1 = NumVarOrDefault(df+"GX1", Nan)
	gy1 = NumVarOrDefault(df+"GY1", Nan)
	
	if (numtype(gx0 * gy1 * gx1 * gy1) > 0)
		return 0
	endif
	
	Make /O $wName = Nan
	
	// kill waves that conflict with graph name
	
	DoWindow /K $gName
	
	if (WaveExists($Xwave) == 1)
		Display /N=$gName/W=(gx0,gy0,gx1,gy1)/K=1 $wName vs $xWave
	else
		Display /N=$gName/W=(gx0,gy0,gx1,gy1)/K=1 $wName
	endif
		
	ModifyGraph /W=$gName standoff(left)=0, standoff(bottom)=0
	ModifyGraph /W=$gName margin(left)=55, margin(right)=0, margin(top)=19, margin(bottom)=0
	Execute /Z "ModifyGraph /W=" + gName + " rgb=(" + tcolor + ")"
	ModifyGraph /W=$gName wbRGB = (r, g, b), cbRGB = (r, g, b) // set margins gray
	
	if (StringMatch(computer, "mac") == 1)
		y0 = 3
	endif
	
	PopupMenu $("PlotMenu"+cc), pos={0,0}, size={15,0}, bodyWidth= 20, mode=1, value=ChanPopupListDefault(), proc=ChanPopup, win=$gName
	SetVariable $("Overlay"+cc), title="Overlay", pos={90,y0-1}, size={90,50}, limits={0,10,1}, value=$(df+"Overlay"), proc=ChanSetVariable, win=$gName
	SetVariable $("SmoothSet"+cc), title="Smooth", pos={230,y0-1}, size={90,50}, limits={0,inf,1}, value=$(df+"SmoothN"), proc=ChanSetVariable, win=$gName
	CheckBox $("FtCheck"+cc), title="F(t)", pos={375,y0}, size={16,18}, value=0, proc=ChanCheckbox, win=$gName
	CheckBox $("ToFront"+cc), title="To Front", pos={475,y0}, size={16,18}, value=0, proc=ChanCheckbox, win=$gName
	CheckBox $("ScaleCheck"+cc), title="Autoscale", pos={590,y0}, size={16,18}, value=1, proc=ChanCheckbox, win=$gName
	
End // ChanGraphMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsUpdate() // update channel display graphs
	Variable ccnt, numChannels = NMNumChannels()
	
	for (ccnt = 0; ccnt < numChannels; ccnt+=1)
		ChanGraphUpdate(ccnt, 1)
		ChanGraphControlsUpdate(ccnt)
	endfor
	
	//ChanGraphsToFront()
	
	KillVariables /Z $(NMDF()+"ChanScaleSaveBlock")

End // ChanGraphsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanGraphUpdate(chanNum, makeWave) // update channel display graphs
	Variable chanNum // (-1) for current chan
	Variable makeWave // (0) no (1) yes
	
	String sName, dName, ddName, gName, fName, df
	Variable autoscale, count, grid, ft, toFront
	
	Variable scaleblock = NumVarOrDefault(NMDF()+"ChanScaleSaveBlock", 0)
	
	fname = NMFolderListName("")
	
	chanNum = ChanNumCheck(chanNum)
	
	df = ChanDF(chanNum)
	gName = ChanGraphName(chanNum)
	dName = ChanDisplayWave(chanNum) // display wave
	ddName = GetPathName(dName, 0)
	sName = ChanWaveName(chanNum, -1) // source wave
	
	autoscale = NumVarOrDefault(df+"AutoScale", 1)
	toFront = NumVarOrDefault(df+"ToFront", 1)
	
	CheckChanSubFolder(chanNum)
	
	if (NumVarOrDefault(df+"On", 1) == 0)
		ChanGraphClose(chanNum, 0)
		return ""
	endif

	if (Wintype(gName) == 0)
		ChanGraphMake(chanNum)
		scaleblock = 1
	endif
	
	if (Wintype(gName) == 0)
		return ""
	endif
	
	if (scaleblock == 0)
		ChanScaleSave(chanNum)
	endif
	
	if (strlen(fName) > 0)
		DoWindow /T $gName, fName + " : " + sName
	else
		DoWindow /T $gName,  sName
	endif

	if (NumVarOrDefault(df+"Overlay", 0) > 0)
		ChanOverlayUpdate(chanNum)
	endif
	
	if (makeWave == 1)
		ChanWaveMake(chanNum, sName, dName)
	endif
	
	//ChanGraphControlsUpdate(chanNum)
	
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
		ChanGraphAxesSet(chanNum)
	endif
	
	Label /W=$gName bottom ChanLabel(chanNum, "x", sName)
	
	ft = ChanFuncGet(chanNum)
	
	switch(ft)
		default:
			Label /W=$gName left ChanLabel(chanNum, "y", sName)
			break
		case 1:
			Label /W=$gName left "d/dt"
			break
		case 2:
			Label /W=$gName left "dd/dt*dt"
			break
		case 3:
			Label /W=$gName left "integral"
			break
		case 4:
			Label /W=$gName left "normalized"
			break
		case 5:
			Label /W=$gName left "dF/Fo"
			break 
	endswitch
	
	grid = NumVarOrDefault(df+"GridFlag", 1)
	
	ModifyGraph /W=$gName grid(bottom)=grid, grid(left)=grid, gridRGB=(24576,24576,65535)
	
	if (toFront == 1)
		ChanGraphMove(chanNum)
		DoWindow /F $gName
	endif
	
	return gName

End // ChanGraphsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsUpdateWaves()

	ChanGraphsRemoveWaves()
	ChanGraphsAppendDisplayWave()

End // ChanGraphsUpdateWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsRemoveWaves()
	Variable ccnt, numChannels = NMNumChannels()
	
	for (ccnt = 0; ccnt < numChannels; ccnt+=1)
		ChanGraphRemoveWaves(ccnt)
	endfor

End // ChanGraphsRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphRemoveWaves(chanNum)
	Variable chanNum
	
	Variable wcnt
	String gName = ChanGraphName(chanNum)
	
	String wName, wList = TraceNameList(gName, ";", 1)
	
	for (wcnt = 0; wcnt < ItemsInlist(wList); wcnt += 1)
		wName = StringFromList(wcnt, wList)
		RemoveFromGraph /W=$gName $wName
	endfor

End // ChanGraphRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsAppendDisplayWave()
	Variable ccnt, numChannels = NMNumChannels()
	
	for (ccnt = 0; ccnt < numChannels; ccnt+=1)
		ChanGraphAppendDisplayWave(ccnt)
	endfor

End // ChanGraphsAppendDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphAppendDisplayWave(chanNum)
	Variable chanNum
	
	String cdf = ChanDF(chanNum)
	String gName = ChanGraphName(chanNum)
	String wName = ChanDisplayWave(chanNum)
	String xWave = NMXWave()
	String tcolor = StrVarOrDefault(cdf+"TraceColor", "0,0,0")
	
	if ((WinType(gName) == 0) || (WaveExists($wName) == 0))
		return -1
	endif
	
	if (WaveExists($xWave) == 1)
		AppendToGraph /W=$gName $wName vs $xWave
	else
		AppendToGraph /W=$gName $wName
	endif
	
	Execute /Z "ModifyGraph /W=" + gName + " rgb=(" + tcolor + ")"

End // ChanGraphAppendDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphControlsUpdate(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	String gName = ChanGraphName(chanNum)
	String df = ChanDF(chanNum)
	String cc = num2str(chanNum)
	
	Variable tofront = NumVarOrDefault(df+"ToFront", 1)
	Variable autoscale = NumVarOrDefault(df+"AutoScale", 1)
	
	if (winType(gName) == 0)
		return 0
	endif
	
	//ChanControlsDisable(chanNum, "000000") // turn controls back on
		
	SetVariable $("Overlay"+cc), value=$(df+"Overlay"), win=$gName, proc=ChanSetVariable
	
	CheckBox $("ScaleCheck"+cc), value=autoscale, win=$gName, proc=ChanCheckbox
	CheckBox $("ToFront"+cc), value=tofront, win=$gName, proc=ChanCheckbox
	
	ChanPopupUpdate(chanNum)
	ChanSmthUpdate(chanNum)
	ChanFuncUpdate(chanNum)
	
End // ChanGraphControlsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsReset()

	ChanGraphClose(-2, 0) // close unecessary windows
	ChanOverlayKill(-1) // kill unecessary waves
	ChanGraphClear(-1)
	ChanGraphsUpdateWaves()
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
		cbgn = 0; cend = NMNumChannels() - 1;
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

	Variable ccnt, cbgn, cend = NMNumChannels() - 1
	
	for (ccnt = cbgn; ccnt <= cend; ccnt+=1)
		if (NumVarOrDefault(ChanDF(ccnt)+"ToFront", 1) == 1)
			DoWindow /F $ChanGraphName(ccnt)
		endif
	endfor
	
End // ChanGraphsToFront

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphAxesSet(chanNum) // set channel graph size and placement
	Variable chanNum // channel number
	
	chanNum = ChanNumCheck(chanNum)
	
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
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt+=1)
		ChanGraphMove(ccnt)
	endfor

End // ChanGraphsMove

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphMove(chanNum) // set channel graph size and placement
	Variable chanNum // channel number
	
	chanNum = ChanNumCheck(chanNum)
	
	if (IsChanGraph(chanNum) == 0)
		return 0
	endif
	
	String cdf = ChanDF(chanNum)
	String gName = ChanGraphName(chanNum)
	
	Variable x0 = NumVarOrDefault(cdf+"GX0", Nan)
	Variable y0 = NumVarOrDefault(cdf+"GY0", Nan)
	Variable x1 = NumVarOrDefault(cdf+"GX1", Nan)
	Variable y1 = NumVarOrDefault(cdf+"GY1", Nan)
	
	if ((numtype(x0 * y0 * x1 * y1) == 0) && (x1 > x0) && (y0 < y1)) 
		MoveWindow /W=$gName x0, y0, x1, y1
	endif

End // ChanGraphMove

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsSetCoordinates()

	Variable ccnt
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt+=1)
		ChanGraphSetCoordinates(ccnt)
	endfor

End // ChanGraphsSetCoordinates

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphSetCoordinates(chanNum) // set channel graph placement variables
	Variable chanNum // channel number
	
	Variable yinc, width, height, numchan, ccnt, where
	Variable xoffset, yoffset // default offsets
	
	chanNum = ChanNumCheck(chanNum)
	
	String ndf = NMDF(), cdf = ChanDF(chanNum)
	
	Variable x0 = NumVarOrDefault(cdf+"GX0", Nan)
	Variable y0 = NumVarOrDefault(cdf+"GY0", Nan)
	Variable x1 = NumVarOrDefault(cdf+"GX1", Nan)
	Variable y1 = NumVarOrDefault(cdf+"GY1", Nan)
	
	Variable yPixels = NumVarOrDefault(ndf+"yPixels", 700)
	String Computer = StrVarOrDefault(ndf+"Computer", "mac")
	
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

End // ChanGraphSetCoordinates

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphClose(chanNum, KillFolders)
	Variable chanNum // (-1) for all (-2) all unecessary
	Variable KillFolders // to kill global variables

	Variable ccnt, cbgn = chanNum, cend = chanNum
	String gName, wName, ndf = NMDF()
	
	if (NumVarOrDefault(ndf+"ChanGraphCloseBlock", 0) == 1)
		KillVariables /Z $(ndf+"ChanGraphCloseBlock")
		return -1
	endif
	
	if (chanNum == -1)
		cbgn = 0
		cend = 9
	elseif (chanNum == -2)
		cbgn = NMNumChannels()
		cend = cbgn + 5
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		gName = ChanGraphName(ccnt)
		wName = ChanDisplayWave(ccnt)
		
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
		cbgn = 0; cend = 9;
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

	for (ccnt = 0; ccnt < NMNumChannels(); ccnt+=1)
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
		cbgn = 0; cend = NMNumChannels() - 1;
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

Function /S ChanPopupList(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)

	return StrVarOrDefault(NMDF() + "ChanPopupList" + num2str(chanNum), ChanPopupListDefault())

End // ChanPopupList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanPopupListDefault()
	
	return " ;Grid;XLabel;YLabel;FreezeX;FreezeY;Off;"

End // ChanPopupList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanPopupProc(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)

	return StrVarOrDefault(NMDF() + "ChanPopupProc" + num2str(chanNum), "ChanPopup")

End // ChanPopupProc

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

Function ChanPopupUpdate(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	String gName = ChanGraphName(chanNum)
	String cc = num2str(chanNum)
	
	ControlInfo /W=$gName $("PlotMenu"+cc)
	
	if (V_flag == 0)
		return 0
	endif
	
	Execute "PopupMenu PlotMenu"+cc+", mode=1, value=\"" + ChanPopupList(chanNum) + "\", win=" + gName + ", proc=" + ChanPopupProc(chanNum)
	
End // ChanPopupUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanCheckbox(ctrlName, checked) : CheckBoxControl // change differentiation flag
	String ctrlName; Variable checked
	
	Variable chanNum, rvalue
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
	
	Variable chanNum, rvalue
	
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

Function /S ChanFuncDF(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	return StrVarOrDefault(NMDF() + "ChanFuncDF" + num2str(chanNum), ChanDF(chanNum))

End // ChanFuncDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFuncProc(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	return StrVarOrDefault(NMDF() + "ChanFuncProc" + num2str(chanNum), "ChanCheckbox")

End // ChanFuncProc

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncAsk(chanNum) // request chan F(t) function
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	Variable ft =ChanFuncGet(chanNum)
	
	Prompt ft, "choose function:", popup "d/dt;dd/dt*dt;integral;norm;dF/Fo;baseline;"
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
	Variable ft
	
	Variable rvalue
	String vlist = ""
	
	if (ft < 0)
		ft = ChanFuncAsk(chanNum)
	endif
	
	vlist = NMCmdNum(chanNum, vlist)
	vlist = NMCmdNum(ft, vlist)
	NMCmdHistory("ChanFunc", vlist)
	
	rvalue = ChanFunc(chanNum, ft)
	
	NMAutoTabCall()
	
	return rvalue

End // ChanFuncCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFunc(chanNum, ft) // set chan F(t) function
	Variable chanNum // channel number
	Variable ft // (0) none (1) d/dt (2) dd/dt*dt (3) integral (4) norm (5) dF/Fo (6) baseline
	
	chanNum = ChanNumCheck(chanNum)
	
	switch(ft)
		case 4:
			if (ChanFuncNormAsk(chanNum) < 0)
				ft = 0
			endif
			break
		case 5:
			if (ChanFuncDFOFAsk(chanNum) < 0)
				ft = 0
			endif
			break
		case 6:
			if (ChanFuncDFOFAsk(chanNum) < 0)
				ft = 0
			endif
			break
	endswitch
	
	SetNMVar(ChanFuncDF(chanNum)+"Ft", ft)
	ChanGraphsUpdate()
	
	return 0

End // ChanFunc

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncNormAsk(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	String mdf = MainDF()
	String cdf = ChanDF(chanNum)
	
	Variable bbgn = NumVarOrDefault(cdf+"Norm_Bgn", NumVarOrDefault(mdf+"Bsln_Bgn", 0))
	Variable bend = NumVarOrDefault(cdf+"Norm_End", NumVarOrDefault(mdf+"Bsln_End", 5))
	
	String fxn1 = StrVarOrDefault(cdf+"Norm_Fxn1", "avg")
	
	Variable tbgn1 = NumVarOrDefault(cdf+"Norm_Tbgn1", bbgn)
	Variable tend1 = NumVarOrDefault(cdf+"Norm_Tend1", bend)
	
	String fxn2 = StrVarOrDefault(cdf+"Norm_Fxn2", StrVarOrDefault(mdf+"Norm_Fxn", "max"))
	
	Variable tbgn2 = NumVarOrDefault(cdf+"Bsln_Bgn2", NumVarOrDefault(mdf+"Norm_Tbgn", -inf))
	Variable tend2 = NumVarOrDefault(cdf+"Bsln_End2", NumVarOrDefault(mdf+"Norm_Tbgn", inf))
	
	if (numtype(tbgn1) == 2)
		tbgn1 = 0
	endif
	
	if (numtype(tend1) == 2)
		tend2 = 5
	endif
	
	if (numtype(tbgn2) == 2)
		tbgn2 = -inf
	endif
	
	if (numtype(tend2) == 2)
		tend2 = -inf
	endif
	
	Prompt fxn1, "y-min measurement - window 1:", popup "max;min;avg;"
	Prompt tbgn1, "window 1 time begin (ms):"
	Prompt tend1, "window 1 time end (ms):"
	Prompt fxn2, "y-max measurement - window 2:", popup "max;min;avg;"
	Prompt tbgn2, "window 2 time begin (ms):"
	Prompt tend2, "window 2 time end (ms):"
	
	DoPrompt NMPromptStr("Normalize"), fxn1, fxn2, tbgn1, tbgn2, tend1, tend2
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMstr(cdf+"Norm_Fxn1", fxn1)
	SetNMvar(cdf+"Norm_Tbgn1", tbgn1)
	SetNMvar(cdf+"Norm_Tend1", tend1)
	SetNMstr(cdf+"Norm_Fxn2", fxn2)
	SetNMvar(cdf+"Norm_Tbgn2", tbgn2)
	SetNMvar(cdf+"Norm_Tend2", tend2)
	
	return 0

End // ChanFuncNormAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncDFOFAsk(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	String mdf = MainDF()
	String cdf = ChanDF(chanNum)
	
	Variable bbgn = NumVarOrDefault(mdf+"Bsln_Bgn", 0)
	Variable bend = NumVarOrDefault(mdf+"Bsln_End", 5)
	
	bbgn = NumVarOrDefault(cdf+"DFOF_Bbgn", bbgn)
	bend = NumVarOrDefault(cdf+"DFOF_Bend", bend)
	
	Prompt bbgn, "compute baseline from (ms):"
	Prompt bend, "compute baseline to (ms):"
	
	DoPrompt NMPromptStr("dF/Fo"), bbgn, bend
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMvar(cdf+"DFOF_Bbgn", bbgn)
	SetNMvar(cdf+"DFOF_Bend", bend)
	
	return 0

End // ChanFuncDFOFAsk
//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncBslnAsk(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	String mdf = MainDF()
	String cdf = ChanDF(chanNum)
	
	Variable bbgn = NumVarOrDefault(mdf+"Bsln_Bgn", 0)
	Variable bend = NumVarOrDefault(mdf+"Bsln_End", 5)
	
	bbgn = NumVarOrDefault(cdf+"Bsln_Bbgn", bbgn)
	bend = NumVarOrDefault(cdf+"Bsln_Bend", bend)
	
	Prompt bbgn, "compute baseline from (ms):"
	Prompt bend, "compute baseline to (ms):"
	
	DoPrompt NMPromptStr("Baseline"), bbgn, bend
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMvar(cdf+"Bsln_Bbgn", bbgn)
	SetNMvar(cdf+"Bsln_Bend", bend)
	
	return 0

End // ChanFuncBslnAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncGet(chanNum)
	Variable chanNum
	
	return NumVarOrDefault(ChanFuncDF(chanNum)+"Ft", 0)
	
End // ChanFuncGet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncUpdate(chanNum)
	Variable chanNum
	
	Variable v = 1
	String t = "F(t)"
	
	chanNum = ChanNumCheck(chanNum)
	
	String gName = ChanGraphName(chanNum)
	String cc = num2str(chanNum)
	
	Variable ft = ChanFuncGet(chanNum)
	
	ControlInfo /W=$gName $("FtCheck"+cc)
	
	if (V_flag == 0)
		return 0
	endif
	
	switch(ft)
		case 1:
			t = "d/dt"
			break
		case 2:
			t = "dd/dt*dt"
			break
		case 3:
			t = "integral"
			break
		case 4:
			t = "norm"
			break
		case 5:
			t = "dF/Fo"
			break
		case 6:
			t = "baseline"
			break
		default:
			v = 0
			t = "F(t)"
	endswitch
	
	CheckBox $("FtCheck"+cc), value=v, title=t, win=$gName, proc=$ChanFuncProc(chanNum)
	
End // ChanFuncUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanSmthDF(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	return StrVarOrDefault(NMDF() + "ChanSmthDF" + num2str(chanNum), ChanDF(chanNum))

End // ChanSmthDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanSmthProc(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	return StrVarOrDefault(NMDF() + "ChanSmthProc" + num2str(chanNum), "ChanSetVariable")

End // ChanSmthProc

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSmthNumCall(chanNum, smthNum)
	Variable chanNum, smthNum
	
	Variable rvalue
	String vlist = ""
	
	vlist = NMCmdNum(chanNum, vlist)
	vlist = NMCmdNum(smthNum, vlist)
	NMCmdHistory("ChanSmthNum", vlist)
	
	rvalue = ChanSmthNum(chanNum, smthNum)
	
	NMAutoTabCall()
	
	return rvalue

End // ChanSmthNumCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSmthNum(chanNum, smthNum) // set chan smooth num
	Variable chanNum, smthNum
	
	String df = ChanSmthDF(chanNum)
	String alg = ChanSmthAlgGet(chanNum)
	
	strswitch(alg)
		case "binomial":
		case "boxcar":
			break
		default:
			alg = ""
	endswitch
	
	if ((strlen(alg) == 0) && (smthNum > 0))
	
		alg = ChanSmthAlgAsk(chanNum)
		
		if (strlen(alg) == 0)
			smthNum = 0
		endif
		
	endif
	
	if (smthNum == 0)
		alg = ""
	endif
	
	SetNMvar(df+"SmoothN", smthNum)
	SetNMstr(df+"SmoothA", alg)
	
	ChanGraphsUpdate()
	
	return 0

End // ChanSmthNum

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSmthNumGet(chanNum)
	Variable chanNum
	
	return NumVarOrDefault(ChanSmthDF(chanNum)+"SmoothN", 0)
	
End // ChanSmthNumGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanSmthAlgAsk(chanNum) // request chan smooth alrgorithm
	Variable chanNum // (-1) for current channel
	
	chanNum = ChanNumCheck(chanNum)
	
	if (IsChanGraph(chanNum) == 0)
		return ""
	endif
	
	String alg = ChanSmthAlgGet(chanNum)
	
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

Function /S ChanSmthAlgGet(chanNum) // get chan smooth alrgorithm
	Variable chanNum // (-1) for current channel

	String alg = StrVarOrDefault(ChanSmthDF(chanNum)+"SmoothA", "")
	
	strswitch(alg)
		case "binomial":
		case "boxcar":
			break
		default:
		alg = ""
	endswitch
	
	return alg

End // ChanSmthAlgGet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSmthUpdate(chanNum)
	Variable chanNum
	
	chanNum = ChanNumCheck(chanNum)
	
	String gName = ChanGraphName(chanNum)
	String df = ChanSmthDF(chanNum)
	String cc = num2str(chanNum)
	
	ControlInfo /W=$gName $("SmoothSet"+cc)
	
	if (V_flag == 0)
		return 0
	endif
	
	SetVariable $("SmoothSet"+cc), value=$(df+"SmoothN"), win=$gName, proc=$ChanSmthProc(chanNum)
	
End // ChanSmthUpdate

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
	
	Variable on = !NumVarOrDefault(df+"GridFlag", 1)
	
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
	
	SetNMvar(df+"GridFlag", on)
	
	if (WinType(gName) == 1)
		ModifyGraph /W=$gName grid=on
	endif
	
	ChanGraphsUpdate()
	
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
		cbgn = 0; cend = NMNumChannels() - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
		SetNMvar(ChanDF(ccnt)+"On", on)
	endfor
	
	ChanGraphsUpdate()
	
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
	
	String gName = ChanGraphName(chanNum)
	String df = ChanDF(chanNum)
	
	if ((on == 1) && (WinType(gName) == 1))
		SetAxis /A/W=$gName
	else
		ChanScaleSave(chanNum)
	endif
	
	SetNMVar(df+"AutoScale", on)
	SetNMVar(df+"AutoScaleX", 0)
	SetNMVar(df+"AutoScaleY", 0)
	
	ChanGraphsUpdate()
	
	return 0

End // ChanAutoScale

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAutoScaleX(chanNum, on)
	Variable chanNum // channel number
	Variable on // (0) on (1) yes
	
	String df = ChanDF(chanNum)
	
	SetNMVar(df+"AutoScaleX", on)
	
	if (on == 1)
		SetNMVar(df+"AutoScale", 0)
		SetNMVar(df+"AutoScaleY", 0)
	endif
	
	ChanGraphsUpdate()
	
	return 0

End // ChanAutoScaleX

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAutoScaleY(chanNum, on)
	Variable chanNum // channel number
	Variable on // (0) on (1) yes
	
	String df = ChanDF(chanNum)
	
	SetNMVar(df+"AutoScaleY", on)
	
	if (on == 1)
		SetNMVar(df+"AutoScale", 0)
		SetNMVar(df+"AutoScaleX", 0)
	endif
	
	ChanGraphsUpdate()
	
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
		cbgn = 0; cend = NMNumChannels() - 1;
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
			
			if ((V_right > V_left) && (V_top < V_bottom))
				SetNMvar(df+"GX0", V_left)
				SetNMvar(df+"GY0", V_top)
				SetNMvar(df+"GX1", V_right)
				SetNMvar(df+"GY1", V_bottom)
			endif
			
		endif
	
	endfor
	
	return 0
	
End // ChanScaleSave

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanXYSet(chanNum, left, right, bottom, top)
	Variable chanNum, left, right, bottom, top
	
	chanNum = ChanNumCheck(chanNum)
	
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
	ChanGraphsUpdate()
	
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
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1)
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
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1)
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
	
	chanNum = ChanNumCheck(chanNum)
	
	if (IsChanGraph(chanNum) == 0)
		return -1
	endif
	String xWave = NMXWave()
	
	String cdf = ChanDF(chanNum)
	
	Variable overlay = NumVarOrDefault(cdf+"Overlay", 0)
	Variable ocnt = NumVarOrDefault(cdf+"OverlayCount", 0)
	
	String tcolor = StrVarOrDefault(cdf+"TraceColor", "0,0,0")
	String ocolor = StrVarOrDefault(cdf+"OverlayColor", "34816,34816,34816")
	
	if (overlay == 0)
		return -1
	endif
	
	if (ocnt == 0)
		SetNMvar(cdf+"OverlayCount", 1)
		return 0
	endif
	
	String gName = ChanGraphName(chanNum)
	String dName = ChanDisplayWave(chanNum)
	
	String oName = ChanDisplayWaveName(0, chanNum, ocnt)
	String odName = ChanDisplayWaveName(1, chanNum, ocnt)
	
	String wList = TraceNameList(gName,";",1)
	
	if (StringMatch(dName, odName) == 1)
		return -1
	endif
	
	Duplicate /O $dName $odName
	
	RemoveWaveUnits(odName)
	
	if (WhichListItemLax(oName, wList, ";") < 0)
	
		if (WaveExists($xWave) == 1)
			AppendToGraph /W=$gName $odName vs $xWave
		else
			AppendToGraph /W=$gName $odName
		endif
	
		Execute /Z "ModifyGraph /W=" + gName + " rgb(" + oName + ")=(" + ocolor + ")"
		
		oName = ChanDisplayWaveName(0, chanNum, 0)
		odName = ChanDisplayWaveName(1, chanNum, 0)
		
		RemoveFromGraph /W=$gName/Z $oName
		
		if (WaveExists($xWave) == 1)
			AppendToGraph /W=$gName $odName vs $xWave
		else
			AppendToGraph /W=$gName $odName
		endif
		
		Execute /Z "ModifyGraph /W=" + gName + " rgb(" + oName + ")=(" + tcolor + ")"
		
	endif

	ocnt += 1
	
	if (ocnt > overlay)
		ocnt = 1
	endif
	
	SetNMvar(cdf+"OverlayCount", ocnt)
	
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
		cbgn = 0; cend = NMNumChannels() - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		wName = ChanDisplayWave(ccnt)
		xName = ChanDisplayWaveName(0, ccnt, 0)
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

Function ChanOverlayKill(chanNum)
	Variable chanNum // (-1) all chan

	Variable cbgn = chanNum, cend = chanNum
	
	Variable wcnt, ccnt, overlay
	String wName, wList
	
	if (chanNum == -1)
		cbgn = 0; cend = NMNumChannels() - 1;
	endif

	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		wList = WaveListFolder(ChanDF(ccnt), "Display" + ChanNum2Char(ccnt) + "*", ";", "")
	
		overlay = NumVarOrDefault(ChanDF(ccnt)+"Overlay", 0)
	
		for (wcnt = 0; wcnt <= overlay; wcnt += 1)
			wName = ChanDisplayWaveName(0, ccnt, wcnt)
			wList = RemoveFromList(wName, wList)
		endfor
		
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
			wName = ChanDF(ccnt) + StringFromList(wcnt, wList)
			KillWaves /Z $wName
		endfor
		
	endfor

End // ChanOverlayKill

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
	Variable ft, smthNum, tbgn1, tend1, tbgn2, tend2
	String df, smthAlg, fxn1, fxn2
	
	Variable bbgn = NumVarOrDefault(MainDF()+"Bsln_Bgn", 0)
	Variable bend = NumVarOrDefault(MainDF()+"Bsln_End", 2)
	
	if (StringMatch(srcName, dstName) == 1)
		return -1 // not to over-write source wave
	endif
	
	if (WaveExists($dstName) == 1)
		Wave wtemp = $dstName
		wtemp = Nan
	endif
		
	if (WaveExists($srcName) == 0)
		return -1 // source wave does not exist
	endif

	if (WaveType($srcName) == 0)
		return -1 // text wave
	endif
	
	if (chanNum < -1)
		cbgn = 0; cend = NMNumChannels() - 1;
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		df = ChanFuncDF(ccnt)
		ft = ChanFuncGet(ccnt)
		smthNum = ChanSmthNumGet(ccnt)
		smthAlg = ChanSmthAlgGet(ccnt)
		
		Duplicate /O $srcName, $dstName
		
		RemoveWaveUnits(dstName)
	
		if (smthNum > 0)
			SmoothWaves(smthAlg,  smthNum, dstName)
		endif
		
		switch(ft)
			default:
				break
			case 1:
			case 2:
			case 3:
				DiffWaves(dstName, ft)
				break
			case 4:
				fxn1 = StrVarOrDefault(df+"Norm_Fxn1", "avg")
				tbgn1 = NumVarOrDefault(df+"Norm_Tbgn1", -inf)
				tend1 = NumVarOrDefault(df+"Norm_Tend1", inf)
				fxn2 = StrVarOrDefault(df+"Norm_Fxn2", "max")
				tbgn2 = NumVarOrDefault(df+"Norm_Tbgn2", bbgn)
				tend2 = NumVarOrDefault(df+"Norm_Tend2", bend)
				NormalizeWaves(fxn1, tbgn1, tend1, fxn2, tbgn2, tend2, dstName)
				break
			case 5:
				bbgn = NumVarOrDefault(df+"DFOF_Bbgn", bbgn)
				bend = NumVarOrDefault(df+"DFOF_Bend", bend)
				DFOFWaves(bbgn, bend, dstName)
				break
			case 6:
				bbgn = NumVarOrDefault(df+"Bsln_Bbgn", bbgn)
				bend = NumVarOrDefault(df+"Bsln_Bend", bend)
				BaselineWaves(1, bbgn, bend, dstName)
				break
		endswitch
		
	endfor

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
		cbgn = 0; cend = NMNumChannels() - 1;
	endif

	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		df = ChanDF(ccnt)
		overlay = NumVarOrDefault(df+"Overlay", 0)
		
		for (wcnt = 0; wcnt <= overlay; wcnt += 1) // Nan display waves
			wName = ChanDisplayWaveName(1, ccnt, wcnt)
			if (WaveExists($wName) == 1)
				Wave wtemp = $wName
				wtemp = Nan
			endif
		endfor
	
	endfor

End // ChanWavesClear

//****************************************************************
//
//	AvgChanWaves()
//	compute avg and stdv of waves based on channel smooth and F(t) parameters
//	results stored in U_Avg and U_Sdv
//
//****************************************************************

Function /S AvgChanWaves(chanNum, wList)
	Variable chanNum
	String wList // wave list (seperator ";")
	
	Variable wcnt, icnt, items
	String xl, yl, txt, wName, dName, outList = "", badList = wList
	String df = ChanDF(chanNum)
	
	if ((chanNum < 0) || (chanNum >= NumVarOrDefault("NumChannels", 0)))
		return "" // out of range
	endif
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	Variable dx = GetXStats("deltax", wList)
	Variable lftx = GetXStats("maxleftx", wList)
	Variable rghtx = GetXStats("minrightx", wList)
	
	if (numtype(dx) != 0)
		DoAlert 0, "AvgWaves Abort : waves do not have the same deltax values."
		return ""
	endif
	
	Variable ft = ChanFuncGet(chanNum)
	Variable smthNum = ChanSmthNumGet(chanNum)
	String smthAlg = ChanSmthAlgGet(chanNum)
	
	items = ItemsInList(wList)
	
	NMProgressStr("Averaging Channel Waves...")
	
	for (wcnt = 0; wcnt < items; wcnt += 1)
		
		if (CallProgress(wcnt/(items-1)) == 1)
			wcnt = -1
			break
		endif
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		dName = "U_waveCopy"
		ChanWaveMake(chanNum, wname, dName) 
		
		if (WaveExists($dname) == 0)
			continue
		endif
		
		if (icnt == 0) // first wave
			Duplicate /O/R=(lftx,rghtx)  $dName U_Avg, U_Sdv
			U_Sdv *= U_Sdv
		else
			Wave wtemp = $dname
			U_Avg += wtemp
			U_Sdv += wtemp^2
		endif
		
		icnt += 1
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	if (wcnt > 1)
		U_Sdv = sqrt((U_Sdv - ((U_Avg^2) / icnt)) / (icnt - 1))
		U_Avg = U_Avg / icnt
		Setscale /P x lftx, dx, U_Avg, U_Sdv
	endif
	
	xl = NMNoteLabel("x", wList, "")
	yl = NMNoteLabel("y", wList, "")
	
	NMNoteType("U_Avg", "NMAvg", xl, yl, "Func:AvgChanWaves")
	NMNoteType("U_Sdv", "NMSdv", xl, yl, "Func:AvgChanWaves")
	
	switch(ft)
		case 1:
			Note U_Avg, "F(t):d/dt;"
			Note U_Sdv, "F(t):d/dt;"
			break
		case 2:
			Note U_Avg, "F(t):dd/dt*dt;"
			Note U_Sdv, "F(t):dd/dt*dt;"
			break
		case 3:
			Note U_Avg, "F(t):integrate;"
			Note U_Sdv, "F(t):integrate;"
			break
		case 4:
			Note U_Avg, "F(t):norm;"
			Note U_Sdv, "F(t):norm;"
			break
		case 5:
			Note U_Avg, "F(t):dF/Fo;"
			Note U_Sdv, "F(t):dF/Fo;"
			break
		case 5:
			Note U_Avg, "F(t):baseline;"
			Note U_Sdv, "F(t):baseline;"
			break
	endswitch
	
	if (smthNum > 0)
		txt = "Smth Alg:" + smthAlg + ";Smth Num:" + num2str(smthNum) + ";"
		Note U_Avg, txt
		Note U_Sdv, txt
	endif
	
	txt = "Wave List:" + ChangeListSep(wList, ",")
	
	Note U_Avg, txt
	Note U_Sdv, txt
	
	KillWaves /Z U_waveCopy
	
	NMUtilityAlert("AvgChanWaves", badList)
	
	return outList

End // AvgChanWaves

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
