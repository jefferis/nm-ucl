#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Spike Analysis
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 16 April 2008
//
//	NM tab entry "Spike"
//
//	Compute spike rasters, averages and histograms
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikePrefix(objName) // tab prefix identifier
	String objName
	
	return "SP_" + objName
	
End // SpikePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeDF() // package full-path folder name

	return PackDF("Spike")
	
End // SpikeDF

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTab(enable)
	Variable enable // (0) disable (1) enable tab
	
	if (enable == 1)
		CheckPackage("Spike", 0) // declare globals if necessary
		SpikeDragCheck() // display drag waves
		CheckSpikeThresh()
		CheckSpikeWindows()
		MakeSpike(0) // make controls if necessary
		UpdateSpike()
		ChanControlsDisable(-1, "000000")
		AutoSpike()
	endif
	
	if (DataFolderExists(SpikeDF()) == 1)
		SpikeDisplay(-1, enable)
	endif
	
	SpikeChanControlsEnable(-1, enable)

End // SpikeTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillSpike(what)
	String what
	String df = SpikeDF()
	
	strswitch(what)
	
		case "waves":
			break
			
		case "folder":
			if (DataFolderExists(df) == 1)
				KillDataFolder $df
			endif
			break
			
	endswitch

End // KillSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckSpike()
	
	String df = SpikeDF()
	
	if (DataFolderExists(df) == 0)
		return -1
	endif
	
	CheckNMvar(df+"Thresh", Nan)				// threshold detection level
	CheckNMvar(df+"WinB", -inf)				// analysis window begin time
	CheckNMvar(df+"WinE", inf)				// analysis window end time
	CheckNMvar(df+"ChanSelect", 0) 			// channel to measure
	CheckNMvar(df+"Events", 0) 				// number of spikes detected in current wave
	CheckNMvar(df+"Spikes", 0) 				// total number of spikes detected
	CheckNMvar(df+"Rate", 0) 					// spike rate within detected window
	
	// waves for display graphs
	
	CheckNMwave(df+"SP_SpikeX", 0, Nan)
	CheckNMwave(df+"SP_SpikeY", 0, Nan)
	
	return 0
	
End // CheckSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckSpikeThresh()
	
	String df = SpikeDF()
	String wname = ChanDisplayWave(-1)
	
	Variable thresh = NumVarOrDefault(df+"Thresh", Nan)
	
	if ((numtype(thresh) == 0) || (WaveExists($wname) == 0))
		return 0
	endif
	
	Wavestats /Q/Z $wname
	
	thresh = ceil(V_max - 0.2*abs(V_max - V_avg))
	
	if (V_avg < 20)
		thresh = max(thresh, 20)
	endif
	
	SetNMvar(df+"Thresh", thresh)
	
End // CheckSpikeThresh

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckSpikeWindows()
	String df = SpikeDF()

	if (numtype(NumVarOrDefault(df+"WinB", Nan)) > 0)
		SetNMvar(df+"WinB", -inf)
	endif
	
	if (numtype(NumVarOrDefault(df+"WinE", Nan)) > 0)
		SetNMvar(df+"WinE", inf)
	endif

End // CheckSpikeWindows

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeChanSelect()
	
	return NumVarOrDefault(SpikeDF()+"ChanSelect", NMCurrentChan())

End // SpikeChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeChanControlsEnable(chanNum, enable)
	Variable chanNum
	Variable enable
	
	String ndf = NMDF()
	
	chanNum = ChanNumCheck(chanNum)
	
	if (enable == 1)
		SetNMstr(ndf + "ChanPopupList" + num2str(chanNum), " ;Spike Drag;" + ChanPopupListDefault())
		SetNMstr(ndf + "ChanPopupProc" + num2str(chanNum), "SpikeChanPopup")
	else
		KillStrings /Z $(ndf + "ChanPopupList" + num2str(chanNum))
		KillStrings /Z $(ndf + "ChanPopupProc" + num2str(chanNum))
	endif
	
	ChanGraphControlsUpdate(chanNum)
	
End // SpikeChanControlsEnable

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDisplay(chan, appnd) // append/remove spike wave from channel graph
	Variable chan // channel number (-1) for current channel
	Variable appnd // 1 - append wave; 0 - remove wave
	
	Variable ccnt, drag = 1, dragstyle = 3
	//Variable r = 65535, g = 65535, b = 65535
	String gName, df = SpikeDF()
	
	if (DataFolderExists(df) == 0)
		return 0 // spike has not been initialized yet
	endif
	
	if ((WaveExists($(df+"SP_DragWYB")) == 0) || (StringMatch(NMTabCurrent(), "Spike") == 0))
		drag = 0
	endif
	
	Variable numChannels = NMNumChannels()
	
	if (appnd == 0)
		SetNMwave(df+"SP_SpikeX", -1, Nan)
		SetNMwave(df+"SP_SpikeY", -1, Nan)
	endif
	
	chan = ChanNumCheck(chan)
	
	for (ccnt = 0; ccnt < numChannels; ccnt += 1)
	
		gName = GetGraphName("Chan", ccnt)
	
		if (Wintype(gName) == 0)
			continue // window does not exist
		endif
	
		RemoveFromGraph /Z/W=$gName SP_SpikeY
		RemoveFromGraph /Z/W=$gName SP_DragWYB, SP_DragWYE
		
		if ((appnd == 1) && (ccnt == chan))
		
			AppendToGraph /W=$gName $(df+"SP_SpikeY") vs $(df+"SP_SpikeX")
			ModifyGraph /W=$gName mode(SP_SpikeY)=3, marker(SP_SpikeY)=9
			ModifyGraph /W=$gName mrkThick(SP_SpikeY)=2, rgb(SP_SpikeY)=(65535,0,0)
			
			if ((drag == 1) || (WaveExists($(df+"SP_DragWYB")) == 0))
			
				AppendToGraph /W=$gName $(df+"SP_DragWYB") vs $(df+"SP_DragWXB")
				AppendToGraph /W=$gName $(df+"SP_DragWYE") vs $(df+"SP_DragWXE")
				
				ModifyGraph /W=$gName lstyle(SP_DragWYB)=dragstyle//, rgb(SP_DragWYB)=(r,g,b)
				ModifyGraph /W=$gName lstyle(SP_DragWYE)=dragstyle//, rgb(SP_DragWYE)=(r,g,b)
				ModifyGraph /W=$gName quickdrag(SP_DragWYB)=1,live(SP_DragWYB)=1, offset(SP_DragWYB)={0,0}
				ModifyGraph /W=$gName quickdrag(SP_DragWYE)=1,live(SP_DragWYE)=1, offset(SP_DragWYE)={0,0}
			
			endif
		
		endif
		
	endfor
	
	SpikeChanControlsEnable(chan, appnd)

End // SpikeDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDisplayClear()
	String df = SpikeDF()

	SetNMwave(df+"SP_SpikeX", -1, Nan)
	SetNMwave(df+"SP_SpikeY", -1, Nan)

End // SpikeDisplayClear

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDragCheck()

	String df = SpikeDF()
	String wdf = "root:WinGlobals:"
	String cdf = "root:WinGlobals:" + ChanGraphName(-1) + ":"
	
	if (WaveExists($(df+"SP_DragWXB")) == 0)
		
		CheckNMwave(df+"SP_DragWXB", 2, -1) // window drag
		CheckNMwave(df+"SP_DragWYB", 2, -1)
		CheckNMwave(df+"SP_DragWXE", 2, -1)
		CheckNMwave(df+"SP_DragWYE", 2, -1)
	
	endif
	
	Redimension /N=2 $(df+"SP_DragWXB"), $(df+"SP_DragWXE"), $(df+"SP_DragWYB"), $(df+"SP_DragWYE")
	
	if (DataFolderExists(wdf) == 0)
		NewDataFolder $(LastPathColon(wdf,0))
	endif
	
	if (DataFolderExists(cdf) == 0)
		NewDataFolder $(LastPathColon(cdf,0))
	endif
	
	CheckNMstr(cdf+"S_TraceOffsetInfo", "")
	CheckNMvar(cdf+"HairTrigger", 0)
	
	SetFormula $(cdf+"HairTrigger"),"SpikeDragTrigger(" + cdf + "S_TraceOffsetInfo)"

End // SpikeDragCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDragCall(on)
	Variable on // (0) no (1) yes
	
	NMCmdHistory("SpikeDrag", NMCmdNum(on,""))
	
	return SpikeDrag(on)
	
End // SpikeDragCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDrag(on)
	Variable on // (0) no (1) yes
	
	SetNMVar(SpikeDF()+"DragOn", BinaryCheck(on))
	//NMAutoSpike()
	
	return on
	
End // SpikeDrag

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDragToggle()
	String df = SpikeDF()
	Variable on = NumVarOrDefault(df+"DragOn", 1)
	
	if (on == 1)
		on = 0
	else
		on = 1
	endif
	
	SetNMVar(df+"DragOn", on)
	//NMAutoSpike()
	
	return on
	
End // SpikeDragToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDragTrigger(offsetStr)
	String offsetStr
	
	if (strlen(offsetStr) == 0)
		return -1
	endif
	
	Variable tbgn, tend, tt, chan
	String dwave, vname, df = SpikeDF()
	
	String gname = StringByKey("GRAPH", offsetStr)
	String wname = StringByKey("TNAME", offsetStr)
	Variable offset = str2num(StringByKey("XOFFSET", offsetStr))
	
	if ((WinType(gname) == 0) || (offset == 0))
		return -1
	endif
	
	chan = ChanChar2Num(gname[4, inf])
	dwave = ChanDisplayWave(chan)
	
	strswitch(wname)
	
		case "SP_DragWYB":
		
			tt = NumVarOrDefault(df+"WinB", -inf)
			
			if (numtype(tt) == 0)
				SetNMvar(df+"WinB", tt + offset)
			else
				SetNMvar(df+"WinB", NMLeftX(dwave) + offset)
			endif
			
			break
			
		case "SP_DragWYE":
		
			tt = NumVarOrDefault(df+"WinE", -inf)
			
			if (numtype(tt) == 0)
				SetNMvar(df+"WinE", tt + offset)
			else
				SetNMvar(df+"WinE", NMRightX(dwave) + offset)
			endif
			
			break
			
	endswitch
	
	ModifyGraph /W=$gname offset($wname)={0,0} // remove offset
	
	SetNMvar(df+"AutoDoUpdate", 0) // prevent DoUpdate in AutoSpike
	
	AutoSpike()
	
	SetNMvar(df+"AutoDoUpdate", 1) // reset update flag
	
	//SpikeTimeStamp(df)
	
	DoWindow /F $gname
	
End // SpikeDragTrigger

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDragSetY() // Note, this must be called AFTER graphs have been auto scaled

	String df = SpikeDF()
	String gName = ChanGraphName(-1)

	Variable drag = NumVarOrDefault(df+"DragOn", 1)
	
	if (WaveExists($(df+"SP_DragWYB")) == 0)
		return -1
	endif

	Wave SP_DragWYB = $(df+"SP_DragWYB")
	Wave SP_DragWXB = $(df+"SP_DragWXB")
	Wave SP_DragWYE = $(df+"SP_DragWYE")
	Wave SP_DragWXE = $(df+"SP_DragWXE")

	if (drag == 0)
		
		SP_DragWXB = Nan
		SP_DragWXE = Nan
		SP_DragWYB = Nan
		SP_DragWYE = Nan
	
	elseif (WinType(gName) == 1)
	
		if (NumVarOrDefault(df+"AutoDoUpdate", 1) == 1)
			DoUpdate
		endif
	
		GetAxis /W=$gName/Q left
		
		SP_DragWYB[0] = V_min
		SP_DragWYB[1] = V_max
		SP_DragWYE[0] = V_min
		SP_DragWYE[1] = V_max
	
	endif

End // SpikeDragSetY
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeSpike(force) // create Spike tab controls
	Variable force

	Variable x0 = 40, y0 = 195, xinc = 120, yinc = 35, fs = NMPanelFsize()
	Variable taby = NMPanelTabY()
	String df = SpikeDF()
	
	y0 = taby + 45
	
	ControlInfo /W=NMPanel SP_Thresh
	
	if ((V_Flag != 0) && (force == 0))
		return 0 // Spike tab has already been created, return here
	endif
	
	if (DataFolderExists(df) == 0)
		return 0 // spike has not been initialized yet
	endif
	
	DoWindow /F NMPanel
	
	GroupBox SP_Grp1, title = "Spike Detection", pos={20,y0}, size={260,150}, fsize=fs
	
	xinc = 145
	yinc = 26
	
	SetVariable SP_Thresh, title="Threshold", pos={x0,y0+1*yinc}, limits={-inf,inf,1}, size={120,20}, frame=1, value=$(df+"Thresh"), proc=SpikeSetVariable, fsize=fs
	
	SetVariable SP_WinB, title="t_beg", pos={x0,y0+2*yinc}, limits={-inf,inf,1}, size={120,20}, frame=1, value=$(df+"WinB"), proc=SpikeSetVariable, fsize=fs
	SetVariable SP_WinE, title="t_end", pos={x0,y0+3*yinc}, limits={-inf,inf,1}, size={120,20}, frame=1, value=$(df+"WinE"), proc=SpikeSetVariable, fsize=fs
	
	SetVariable SP_Count, title="Spikes : ", pos={x0+xinc,y0+2*yinc}, limits={0,inf,0}, size={90,20}, frame=0, value=$(df+"Events"), fsize=fs
	SetVariable SP_WRate, title="Hertz : ", pos={x0+xinc,y0+3*yinc}, limits={0,inf,0}, size={90,20}, frame=0, value=$(df+"Rate"), fsize=fs
	
	yinc = 35
	
	y0 += 10
	
	//Button SP_Save, title = "Save", pos={95,y0+2*yinc}, size={50,20}, proc = SpikeButton
	//Button SP_Clear, title = "Clear", pos={155,y0+2*yinc}, size={50,20}, proc = SpikeButton
	
	Button SP_Table, title = "Table", pos={x0+20,y0+3*yinc}, size={80,20}, proc = SpikeButton, fsize=fs
	Button SP_All, title = "All Waves", pos={x0+120,y0+3*yinc}, size={80,20}, proc = SpikeButton, fsize=fs
	
	y0 = 380; yinc = 35
	
	GroupBox SP_Grp2, title = "Spike Analysis", pos={20,y0}, size={260,200}, fsize=fs
	
	PopupMenu SP_WaveSlct, pos={x0+120,y0+1*yinc}, bodywidth=125, fsize=fs
	PopupMenu SP_WaveSlct, value="Select Wave;---;Other...;", proc=SpikePopup
	
	SetVariable SP_Spikes, title=": ", pos={x0+175,y0+1*yinc+2}, limits={0,inf,0}, size={60,20}, frame=0, value=$(df+"Spikes"), fsize=fs
	
	xinc = 120
	yinc = 40
	
	Button SP_Raster, title="Raster Plot", pos={x0,y0+2*yinc}, size={100,20}, proc=SpikeButton, fsize=fs
	Button SP_Rate, title="Avg Rate", pos={x0+xinc,y0+2*yinc}, size={100,20}, proc=SpikeButton, fsize=fs
	Button SP_PSTH, title="PST Histo", pos={x0,y0+3*yinc}, size={100,20}, proc=SpikeButton, fsize=fs
	Button SP_ISIH, title="ISI Histo", pos={x0+xinc,y0+3*yinc}, size={100,20}, proc=SpikeButton, fsize=fs
	//Button SP_Average, title="Average", pos={x0,y0+4*yinc}, size={100,20}, proc=SpikeButton, fsize=fs
	Button SP_2Waves, title="Spikes 2 Waves", pos={x0+xinc/2,y0+4*yinc}, size={100,20}, proc=SpikeButton, fsize=fs
	
End // MakeSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateSpike()
	
	Variable md
	String wlist, wSelect, df = SpikeDF()
	
	wlist = SpikeRasterList()
	wSelect = StrVarOrDefault(df+"RasterWaveX", "")
	
	md = WhichListItemLax(wSelect, wList, ";")
	
	if (WaveExists($wSelect) == 0)
		SetNMstr(df+"RasterWaveX", "")
		wSelect = ""
	endif
	
	if (strlen(wSelect) == 0)
		md = 1
	else
		md = WhichListItem(wSelect, wlist) + 3
	endif

	PopupMenu SP_WaveSlct, win=NMPanel, mode=md, value="Select Wave;---;" + SpikeRasterList() + "---;Other...;"
	
	SpikeRasterCountSpikes("")
	
	SetNMvar(df+"ChanSelect", NMCurrentChan())

End // UpdateSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	SpikeCall(ctrlName[3,inf], varStr)

End // SpikeSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikePopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	SpikeCall(ctrlName[3,inf], popStr)
	
End // SpikePopup

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeButton(ctrlName) : ButtonControl
	String ctrlName
	
	SpikeCall(ctrlName[3,inf], "")
	
End // SpikeButton

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeChanPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr 
	
	strswitch(popStr)
		case "Spike Drag":
			SpikeDragToggle()
			break
		default:
			ChanPopup(ctrlName, popNum, popStr)
	endswitch

End //  SpikeChanPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeCall(fxn, select)
	String fxn, select
	
	Variable snum = str2num(select)
	
	strswitch(fxn)
	
		case "Thresh":
			return SpikeThresholdCall(snum)
			
		case "WinB":
			return SpikeWindowCall(snum, Nan)
		
		case "WinE":
			return SpikeWindowCall(Nan, snum)
			
		case "Table":
			return SpikeTableCall()
		
		case "All":
			SpikeAllWavesCall()
			return 0
			
		case "WaveSlct":
			return SpikeRasterSelectCall(select)
			
		case "Raster":
			return SpikeRasterPlotCall()
			
		case "PSTH":
			return SpikePSTHCall()
			
		case "ISIH":
			return SpikeISIHCall()
			
		case "Rate":
			return SpikeRateCall()
			
		case "Average":
			return SpikeAvgAlert()
			
		case "2Waves":
			return Spike2WavesCall()
			
	endswitch
	
End // SpikeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeThresholdCall(thresh)
	Variable thresh
	
	NMCmdHistory("SpikeThreshold", NMCmdNum(thresh,""))
	return SpikeThreshold(thresh)
	
End // SpikeThresholdCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeThreshold(thresh)
	Variable thresh
	
	if (numtype(thresh) == 0)
		SetNMvar(SpikeDF()+"Thresh", thresh)
		AutoSpike()
		return 0
	else
		return -1
	endif
	
End // SpikeThreshold

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWindowCall(tbgn, tend)
	Variable tbgn, tend
	
	String vlist = "", df = SpikeDF()
	
	if (numtype(tbgn) > 0)
		tbgn = NumVarOrDefault(df+"WinB", 0)
	endif
	
	if (numtype(tend) > 0)
		tend = NumVarOrDefault(df+"WinE", 0)
	endif
	
	vlist = NMCmdNum(tbgn, vlist)
	vlist = NMCmdNum(tend, vlist)
	NMCmdHistory("SpikeWindow", vlist)
	
	return SpikeWindow(tbgn, tend)
	
End // SpikeWindowCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWindow(tbgn, tend)
	Variable tbgn, tend
	
	Variable te = tend
	String df = SpikeDF()
	
	if (tbgn > tend)
		tend = tbgn
		tbgn = te
	endif
	
	if (numtype(tbgn) > 0)
		tbgn = -inf
	endif
	
	if (numtype(tend) > 0)
		tend = inf
	endif
	
	SetNMvar(df+"WinB", tbgn)
	SetNMvar(df+"WinE", tend)
	
	AutoSpike()
	
	return 0

End // SpikeWindow

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWinBgn()

	Variable t = NumVarOrDefault(SpikeDF()+"WinB", -inf)

	if (numtype(t) > 0)
		t = leftx($ChanDisplayWave(-1))
	endif
	
	return t

End // SpikeWinBgn

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWinEnd()

	Variable t = NumVarOrDefault(SpikeDF()+"WinE", inf)

	if (numtype(t) > 0)
		t = rightx($ChanDisplayWave(-1))
	endif
	
	return t

End // SpikeWinEnd

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterList()

	String wSelect = StrVarOrDefault(SpikeDF()+"RasterWaveX", "")
	
	String opstr = WaveListText0()

	String wlist = WaveList("SP_RasterX_*", ";", opstr) + WaveList("SP_RX_*", ";", opstr)
	String wlist1 = WaveList("SP_*Rate*", ";", WaveListText0())
	String wlist2 = WaveList("SP_*PSTH*", ";", WaveListText0())
	String wlist3 = WaveList("SP_*ISIH*", ";", WaveListText0())
	String wlist4 = WaveList("SP_*Intvls*", ";", WaveListText0())
	
	wlist = RemoveFromList(wlist1+wlist2+wlist3+wlist4, wlist)
	
	if ((WhichListItemLax(wSelect, wList, ";") < 0) && (WaveExists($wSelect) == 1))
		wlist += wSelect + ";"
	endif

	return wlist

End // SpikeRasterList

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterSelectCall(xRaster)
	String xRaster
	
	Variable inum
	String vlist = "", df = SpikeDF()
	String yRaster = xRaster
	
	if ((WaveExists($xRaster) == 0) && (strsearch(xRaster, "Other", 0) < 0))
		SetNMvar(df + "Spikes", 0)
		return -1
	endif
	
	inum = strsearch(xRaster, "RasterX", 0)
	
	if (inum >= 0)
		inum += 6
		yRaster[inum,inum] = "Y"
		inum = -1
	else
		inum = strsearch(xRaster, "RX", 0)
	endif
	
	if (inum >= 0)
		inum += 1
		yRaster[inum,inum] = "Y"
	endif
	
	vlist = NMCmdStr(xRaster, vlist)
	vlist = NMCmdStr(yRaster, vlist)
	NMCmdHistory("SpikeRasterSelect", vlist)
		
	return SpikeRasterSelect(xRaster, yRaster)
	
End // SpikeRasterSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterSelect(xRaster, yRaster)
	String xRaster, yRaster

	String df = SpikeDF()

	if ((WaveExists($xRaster) == 0) || (WaveExists($yRaster) == 0))
		return SpikeRasterSelectWaves()
	endif
	
	SetNMstr(df+"RasterWaveX", xRaster)
	SetNMstr(df+"RasterWaveY", yRaster)
	
	SpikeRasterCheckWaves()
	UpdateSpike()
	
	return 0

End // SpikeRasterSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterSelectWaves()

	String xRaster = "", yRaster = "", df = SpikeDF()
	
	String opstr = WaveListText0()
	
	Prompt xRaster, "select x-raster of spike times (i.e. SP_RasterX_A0):", popup WaveList("*", ";", opstr)
	Prompt yRaster, "select corresponding y-raster of wave numbers (i.e. SP_RasterY_A0):", popup WaveList("*", ";", opstr)
	DoPrompt "Spike Raster Plot", xRaster, yRaster
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMstr(df+"RasterWaveX", xRaster)
	SetNMstr(df+"RasterWaveY", yRaster)
	
	SpikeRasterCheckWaves()
	UpdateSpike()
	
	return 0

End // SpikeRasterSelectWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterCheckWaves()
	
	String df = SpikeDF()
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")

	if (WaveExists($xRaster) == 0)
		DoAlert 0, "Error: Raster wave " + xRaster + "does not exist."
		SetNMstr(df+"RasterWaveX", "")
		SetNMstr(df+"RasterWaveY", "")
		return -1
	endif
	
	if (WaveExists($yRaster) == 0)
		DoAlert 0, "Error: Raster wave " + yRaster + "does not exist."
		SetNMstr(df+"RasterWaveX", "")
		SetNMstr(df+"RasterWaveY", "")
		return -1
	endif
	
	if (numpnts($xRaster) != numpnts($yRaster))
		DoAlert 0, "Error: Raster x and y waves are not the same length."
		SetNMstr(df+"RasterWaveX", "")
		SetNMstr(df+"RasterWaveY", "")
		return -1
	endif
	
	return 0
	
End // SpikeRasterCheckWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterCountSpikes(xRaster)
	String xRaster
	
	Variable spikes = 0
	String df = SpikeDF()
	
	if (strlen(xRaster) == 0)
		xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	endif
	
	if ((WaveExists($xRaster) == 1) && (numpnts($xRaster) > 0))
		WaveStats /Q/Z $xRaster
		spikes = V_npnts
	else
		spikes = 0
	endif
	
	SetNMvar(df + "Spikes", spikes)
	
	return spikes
	
End // SpikeRasterCountSpikes

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterCountReps(yRaster)
	String yRaster
	
	Variable icnt, jcnt, rcnt
	String df = SpikeDF()
	
	if (strlen(yRaster) == 0)
		yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	endif
	
	if (WaveExists($yRaster) == 0)
		return 0
	endif
	
	WaveStats /Q/Z $yRaster
	
	Wave yWave = $yRaster
	
	for (icnt = V_min; icnt <= V_max; icnt += 1)
		for (jcnt = 0; jcnt < numpnts(yWave); jcnt += 1)
			if (yWave[jcnt] == icnt)
				rcnt += 1
				break
			endif
		endfor
	endfor
	
	return rcnt
	
End // SpikeRasterCountReps

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoSpike() // compute threshold crossings on currently selected channel/wave; display on graph

	Variable events, rate
	String xname = "SP_RasterX", yname = "SP_RasterY"
	String df = SpikeDF()
	
	Variable winB = NumVarOrDefault(df+"WinB", -inf)
	Variable winE = NumVarOrDefault(df+"WinE", inf)
	Variable thresh = NumVarOrDefault(df+"Thresh", 0)
	
	events = SpikeRaster(NMCurrentChan(), NMCurrentWave(), Thresh, winB, winE, xname, yname, 1, 0)
	
	SetNMvar(df+"Events", events)
	
	rate = 1000 * events / (SpikeTmax(xname) - SpikeTmin(xname))
	
	SetNMvar(df+"Rate", rate)
	
	KillWaves /Z $xname, $yname
	
	SpikeDragSetY()

End // AutoSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllWavesCall()
	String vlist = "", df = SpikeDF()
	
	Variable nwaves = ChanWavesCount(-1)
	
	if (nwaves <= 0)
		DoAlert 0, "No waves selected!"
		return ""
	endif

	Variable dsplyFlag = 1 + NumVarOrDefault(df+"AllWavesDisplay", 1)
	Variable speed = NumVarOrDefault(df+"AllWavesSpeed", 0)
	Variable format = 1 + NumVarOrDefault(df+"SpikeTableFormat", 0)
	
	Prompt dsplyFlag, "display results while computing?", popup "no;yes;yes, with accept/reject prompt;"
	Prompt speed, "display delay (sec):"
	Prompt format, "save spike times to:", popup "one output wave;one output wave per input wave;"
	
	if (0) // (nwaves > 1)
	
		DoPrompt "Spike All Waves", dsplyFlag, speed, format
		
		format -= 1
		
		SetNMvar(df+"SpikeTableFormat", format)
	
	else
	
		DoPrompt "Spike All Waves", dsplyFlag, speed
		
		format = 0
		
	endif
	
	dsplyFlag -= 1
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMvar(df+"AllWavesDisplay", dsplyFlag)
	SetNMvar(df+"AllWavesSpeed", speed)

	if (NMAllGroups() == 1)
	
		vlist = NMCmdNum(dsplyFlag, vlist)
		vlist = NMCmdNum(speed, vlist)
		vlist = NMCmdNum(format, vlist)
		NMCmdHistory("SpikeAllGroupsDelayFormat", vlist)
	
		return SpikeAllGroupsDelayFormat(dsplyFlag, speed, format)
		
	else
	
		vlist = NMCmdNum(dsplyFlag, vlist)
		vlist = NMCmdNum(speed, vlist)
		vlist = NMCmdNum(format, vlist)
		NMCmdHistory("SpikeAllWavesDelayFormat", vlist)
		
		return SpikeAllWavesDelayFormat(dsplyFlag, speed, format)
		
	endif

End // SpikeAllWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllGroups() // OLD

	return SpikeAllGroupsDelayFormat(0, 0, 0)

End // SpikeAllGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllGroupsDelay(dsplyFlag, speed)
	Variable dsplyFlag // display results while computing (0) no (1) yes (2) yes, accept/reject prompt
	Variable speed // update display speed in sec (0) for none
	
	return SpikeAllGroupsDelayFormat(dsplyFlag, speed, 0)

End // SpikeAllGroupsDelay

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllGroupsDelayFormat(dsplyFlag, speed, format)
	Variable dsplyFlag // display results while computing (0) no (1) yes (2) yes, accept/reject prompt
	Variable speed // update display speed in sec (0) for none
	Variable format // save spike times to (0) one wave (1) one wave per input wave
	
	Variable gcnt
	String gName = ""
	
	String saveSelect = NMWaveSelectGet()
	String grpList = NMGroupList(1)
	
	for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
		NMWaveSelect(StringFromList(gcnt, grpList))
		gName = SpikeAllWavesDelayFormat(dsplyFlag, speed, format)
	endfor
	
	NMWaveSelect(saveSelect)
	
	return gName

End // SpikeAllGroupsDelayFormat

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllWaves()

	return SpikeAllWavesDelayFormat(0, 0, 0)

End // SpikeAllWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllWavesDelay(dsplyFlag, speed)
	Variable dsplyFlag // display results while computing (0) no (1) yes (2) yes, accept/reject prompt
	Variable speed // update display speed in sec (0) for fastest
	
	return SpikeAllWavesDelayFormat(dsplyFlag, speed, 0)
	
End // SpikeAllWavesDelay

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllWavesDelayFormat(dsplyFlag, speed, format)
	Variable dsplyFlag // display results while computing (0) no (1) yes (2) yes, accept/reject prompt
	Variable speed // update display speed in sec (0) for fastest
	Variable format // save spike times to (0) one wave (1) one wave per input wave
	
	// NOTE, "format" is currently under construction

	Variable ccnt, wcnt, spikes, changeChan, overwrite = NMOverWrite()
	String pName, gName = "", xName, yName, df = SpikeDF()
	
	Variable Nameformat = NumVarOrDefault(NMDF() + "NameFormat", 1)
	
	Variable winB = NumVarOrDefault(df+"WinB", -inf)
	Variable winE = NumVarOrDefault(df+"WinE", inf)
	Variable thresh = NumVarOrDefault(df+"Thresh", 0)
	
	Variable saveCurrentChan = NMCurrentChan()
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	if (NameFormat == 1)
		pName = NMWaveSelectStr() + "_"
	endif
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
		
		SetNMvar("CurrentChan", ccnt)

		xName = NextWaveName2("", "SP_RX_" + pName, ccnt, overwrite)
		yName = NextWaveName2("", "SP_RY_" + pName, ccnt, overwrite)
		
		if (dsplyFlag > 0)
		
			if (ccnt != saveCurrentChan)
				SpikeDisplay(-1, 0) // remove stats display waves
				SpikeDisplay(ccnt, 1) // add stats display waves
				changeChan = 1
			endif
			
			//ChanControlsDisable(ccnt, "111111")
			DoWindow /F $ChanGraphName(ccnt)
			DoUpdate
			
		endif
		
		spikes = SpikeRaster(ccnt, -1, thresh, WinB, WinE, xName, yName, dsplyFlag, speed * 1000)
		
		SetNMstr(df+"RasterWaveX", xName)
		SetNMstr(df+"RasterWaveY", yName)
		
		gName = SpikeRasterPlot(xName, yName, WinB, WinE)
		
	endfor
	
	if (changeChan > 0) // back to original channel
		SpikeDisplay(ccnt, 0) // remove display waves
		SpikeDisplay(saveCurrentChan, 1) // add display waves
		SetNMvar("CurrentChan", saveCurrentChan)
	endif
	
	ChanGraphsUpdate()
	AutoSpike()
	UpdateSpike()
	
	if (WinType(gName) == 1)
		DoWindow /F $gName
	endif
	
	return gName
	
End // SpikeAllWavesDelayFormat

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRaster(chanNum, waveNum, thresh, WinB, WinE, xName, yName, dsplyFlag, speed)
	Variable chanNum // channel number (-1) for current channel
	Variable waveNum // wave number (-1) for all
	Variable thresh // threshold trigger level
	Variable WinB // begin window time
	Variable WinE // end window time
	String xName // output raster x-wave name
	String yName // output raster y-wave name
	Variable dsplyFlag // display results while computing (0) no (1) yes (2) yes, accept/reject prompt
	Variable speed // display speed delay
	
	Variable wcnt, ncnt, scnt, spkcnt, found, event, dx, pwin, slope, allFlag, wbgn, wend, nwaves = 1
	Variable tmin = inf, tmax = -inf
	Variable eventLimit = 2000
	String wName, aName = "", xl, yl, df = SpikeDF()
	String copy = "SP_WaveTemp"
	
	Variable saveCurrentWave = NMCurrentWave()
	Variable currentChan = NMCurrentChan()
	
	String wPrefix = NMCurrentWavePrefix()
	
	Wave ST_DragWXB = $(df+"SP_DragWXB")
	Wave ST_DragWXE = $(df+"SP_DragWXE")
	
	Variable drag = NumVarOrDefault(df+"DragOn", 1)
	
	if (waveNum < 0)
		nwaves = NMNumWaves()
		allFlag = 1
		wbgn = 0
		wend = nwaves - 1
	else
		wbgn = waveNum
		wend = waveNum
	endif
	
	if ((numtype(thresh) > 0) || (strlen(xName) == 0) || (strlen(yName) == 0))
		return -1 // not allowed
	endif
	
	Make /O/N=0 Xtimes=Nan
	Make /O/N=0 $xName=Nan
	Make /O/N=0 $yName=Nan
	
	Wave xWave = $xName
	Wave yWave = $yName
	
	Wave WavSelect
	
	for (wcnt = wbgn; wcnt <= wend; wcnt += 1)
	
		if (allFlag == 1)
		
			if (WavSelect[wcnt] != 1)
				continue
			endif
			
			SetNMvar("CurrentWave", wcnt)
			SetNMvar("CurrentGrp", NMGroupGet(wcnt))
			
			if (dsplyflag > 0)
				ChanGraphUpdate(currentChan, 1)
				aName = ChanDisplayWave(currentChan)
			else
				ChanWaveMake(currentChan, ChanWaveName(currentChan, wcnt), copy)
				aName = copy
			endif
			
		else
		
			ChanWaveMake(currentChan, ChanWaveName(currentChan, wcnt), copy)
			aName = copy
			
		endif
		
		if (WaveExists($aName) == 0)
			continue // wave does not exist
		endif
		
		if (numtype(winB) == 0)
			tmin = winB
		elseif (NMLeftX(aName) < tmin)
			tmin = NMLeftX(aName)
		endif
		
		if (numtype(winE) == 0)
			tmax = winE
		elseif (NMRightX(aName) > tmax)
			tmax = NMRightX(aName)
		endif
		
		Variable tmin2 = NMXvalueTransform(aName, tmin, -1, 1)
		Variable tmax2 = NMXvalueTransform(aName, tmax, -1, -1)
		
		Findlevels /Q/R=(tmin2, tmax2)/D=Xtimes $aName, thresh
		
		pwin = 1
		
		if (V_LevelsFound > 0)
		
			if (V_LevelsFound > 1)
				dx = deltax($aName)
				pwin =  floor((Xtimes[1] - Xtimes[0]) / (dx * 2))
				pwin = max(pwin, 1)
				pwin = min(pwin, 3)
			endif
		
			for (scnt = 0; scnt < V_LevelsFound; scnt += 1)
			
				event = Xtimes[scnt]
				
				slope = SpikeSlope(aName, event, thresh, pwin)
			
				if (slope <= 0) // only accept levels with positive slope
					Xtimes[scnt] = Nan
				endif
				
				Xtimes[scnt] = NMXvalueTransform(aName, Xtimes[scnt], 1, 0)
			
			endfor
			
			WaveStats /Q/Z Xtimes
				
			found = V_npnts
				
		else
		
			found = 0
		
		endif
		
		if (dsplyFlag > 0)
		
			if (V_LevelsFound > 0)
		
				WaveStats /Q/Z Xtimes
				
				if (V_npnts < eventlimit)
					Duplicate /O Xtimes $(df+"SP_SpikeX")
					Duplicate /O Xtimes $(df+"SP_SpikeY")
					SetNMwave(df+"SP_SpikeY", -1, thresh)
				endif
				
			else
			
				SetNMwave(df+"SP_SpikeX", -1, Nan)
				SetNMwave(df+"SP_SpikeY", -1, Nan)
			
			endif
			
			if (NumVarOrDefault(df+"AutoDoUpdate", 1) == 1)
				DoUpdate
			endif
			
			if ((dsplyFlag == 1) && (speed > 0))
				NMWait(speed)
			elseif ((dsplyFlag == 2) && (found > 0))
			
				DoAlert 2, "Accept results?"
				
				if (V_flag == 1)
					
				elseif (V_flag == 2)
					continue
				elseif (V_flag == 3)
					break
				endif
				
			endif
			
		endif
		
		ncnt = numpnts(xWave)
		
		if (found == 0)
		
			Redimension /N=(ncnt+1) xWave, yWave
			xWave[ncnt] = Nan
			yWave[ncnt] = wcnt
			
		else
		
			Redimension /N=(ncnt+found) xWave, yWave
			
			for (scnt = 0; scnt < V_LevelsFound; scnt += 1)
			
				event = Xtimes[scnt]
				
				if (numtype(event) == 0)
					xWave[ncnt] = event
					yWave[ncnt] = wcnt
					spkcnt += 1
					ncnt += 1
				endif
			
			endfor
			
			
		
		endif
		
		ncnt = numpnts(xWave)
			
		Redimension /N=(ncnt + 1) xWave, yWave
			
		xWave[ncnt] = Nan // add extra row for Nan's
		yWave[ncnt] = Nan
		
	endfor
	
	//winB = GetXStats("minleftx", wList)
	//winE = GetXStats("maxrightx", wList)
	
	xl = "Spike Event"
	yl = "msec" // NMNoteLabel("x", wList, "msec")
	
	NMNoteType(xName, "Spike RasterX", xl, yl, "Func:SpikeRaster")
	
	Note $xName, "Spike Thresh:" + num2str(thresh) + ";Spike Tbgn:" + num2str(WinB) + ";Spike Tend:" + num2str(WinE) + ";"
	Note $xName, "Spike Tmin:" + num2str(tmin) + ";Spike Tmax:" + num2str(tmax) + ";"
	Note $xName, "Spike Prefix:" + wPrefix
	//Note $xName, "Wave List:" + ChangeListSep(wList, ",")
	
	xl = "Spike Event"
	yl = wPrefix + "#"
	
	NMNoteType(yName, "Spike RasterY", xl, yl, "Func:SpikeRaster")
	
	Note $yName, "Spike Thresh:" + num2str(thresh) + ";Spike Tbgn:" + num2str(WinB) + ";Spike Tend:" + num2str(WinE) + ";"
	Note $yName, "Spike Tmin:" + num2str(tmin) + ";Spike Tmax:" + num2str(tmax) + ";"
	Note $yName, "Spike Prefix:" + wPrefix
	//Note $yName, "Wave List:" + ChangeListSep(wList, ",")
	
	KillWaves /Z Xtimes
	KillWaves /Z $copy
	
	SetNMvar("CurrentWave", saveCurrentWave)
	setNMvar("CurrentGrp", NMGroupGet(saveCurrentWave))
	
	// update drag waves (ONLY THE X values)
	
	if (drag == 1)
		ST_DragWXB = tmin
		ST_DragWXE = tmax
	endif
	
	return spkcnt // return spike count

End // SpikeRaster

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeSlope(wName, event, thresh, pwin) // compute slope via simple linear regression
	String wName
	Variable event
	Variable thresh
	Variable pwin
	
	Variable tbgn, tend, epnt, xpnt, dt
	Variable icnt, jcnt, xavg, yavg, xsum, ysum, xysum, sumsqr, slope, intercept
	
	if (WaveExists($wName) == 0)
		return Nan
	endif
	
	Wave wtemp = $wName
	
	dt = deltax(wtemp)
	epnt = x2pnt(wtemp, event)
	xpnt = pnt2x(wtemp, epnt)
	
	Make /O/N=(1 + 2 * pWin) U_SlopeX, U_SlopeY
	
	if (xpnt == event) // unlikely
	
		jcnt = epnt - pwin
		
		for (icnt = 0; icnt < numpnts(U_SlopeX); icnt += 1)
			U_SlopeX[icnt] = pnt2x(wtemp, jcnt)
			U_SlopeY[icnt] = wtemp[jcnt]
			jcnt += 1
		endfor
		
	elseif (xpnt < event)
	
		U_SlopeX[0] = event
		U_SlopeY[0] = thresh
		
		jcnt = epnt - (pwin - 1)
	
		for (icnt = 1; icnt < numpnts(U_SlopeX); icnt += 1)
			U_SlopeX[icnt] = pnt2x(wtemp, jcnt)
			U_SlopeY[icnt] = wtemp[jcnt]
			jcnt += 1
		endfor
		
	else
	
		U_SlopeX[0] = event
		U_SlopeY[0] = thresh
		
		jcnt = epnt - pwin
	
		for (icnt = 1; icnt < numpnts(U_SlopeX); icnt += 1)
			U_SlopeX[icnt] = pnt2x(wtemp, jcnt)
			U_SlopeY[icnt] = wtemp[jcnt]
			jcnt += 1
		endfor
	
	endif
	
	Wavestats /Q/Z U_SlopeX
	
	xavg = V_avg
	xsum = sum(U_SlopeX)
	
	Wavestats /Q/Z U_SlopeY
	
	yavg = V_avg
	ysum = sum(U_SlopeY)
	
	for (icnt = 0; icnt < numpnts(U_SlopeX); icnt += 1)
		xysum += (U_SlopeX[icnt] - xavg) * (U_SlopeY[icnt] - yavg)
		sumsqr += (U_SlopeX[icnt] - xavg) ^ 2
	endfor
	
	slope = xysum / sumsqr
	intercept = (ysum - slope * xsum) / numpnts(U_SlopeX)
	
	KillWaves /Z U_SlopeY, U_SlopeX

	return slope

End // SpikeSlope

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTmin(xRaster)
	String xRaster
	
	String wName = CurrentChanDisplayWave() 
	
	Variable winB = NMNoteVarByKey(xRaster, "Spike Tmin")
	
	if (numtype(winB) == 0)
		return winB
	endif
	
	winB = NMNoteVarByKey(xRaster, "Spike Tbgn")
	
	if (numtype(winB) == 0)
		return winB
	endif
	
	return leftx($wName)

End // SpikeTmin

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTmax(xRaster)
	String xRaster
	
	String wName = CurrentChanDisplayWave() 
	
	Variable winB = NMNoteVarByKey(xRaster, "Spike Tmax")
	
	if (numtype(winB) == 0)
		return winB
	endif
	
	winB = NMNoteVarByKey(xRaster, "Spike Tend")
	
	if (numtype(winB) == 0)
		return winB
	endif
	
	return rightx($wName)

End // SpikeTmax

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterPlotCall()
	String gName, vlist = "", df = SpikeDF()
	
	if (SpikeRasterCheckWaves() == -1)
		return -1
	endif
	
	String dName = ChanDisplayWave(-1)
	
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	Variable winB = SpikeTmin(xRaster)
	Variable winE = SpikeTmax(xRaster)
	
	if (numtype(winB) > 0)
		winB = -inf
	endif
	
	if (numtype(winE) > 0)
		winE = inf
	endif
	
	Prompt winB, "window begin time (ms):"
	Prompt winE, "window end time (ms):"
	DoPrompt "Spike Raster Plot", winB, winE
	
	if (V_flag == 1)
		return -1
	endif
	
	vlist = NMCmdStr(xRaster, vlist)
	vlist = NMCmdStr(yRaster, vlist)
	vlist = NMCmdNum(winB, vlist)
	vlist = NMCmdNum(winE, vlist)
	NMCmdHistory("SpikeRasterPlot", vlist)

	gName = SpikeRasterPlot(xRaster, yRaster, winB, winE)
	
	return NMReturnStr2Num(gName)

End // SpikeRasterPlotCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterPlot(xRaster, yRaster, winB, winE)
	String xRaster, yRaster // Raster x-y data
	Variable winB, winE
	
	if ((WaveExists($xRaster) == 0) || (WaveExists($yRaster) == 0))
		return ""
	endif
	
	if (numtype(winB) > 0)
		winB = SpikeTmin(xRaster)
	endif
	
	if (numtype(winE) > 0)
		winE = SpikeTmax(xRaster)
	endif
	
	Variable CurrentChan = NMCurrentChan()
	Variable NumWaves = NMNumWaves()
	
	String wPrefix = StrVarOrDefault("WavePrefix", "")
	String df = SpikeDF()
	
	String gPrefix = xRaster + "_" + NMFolderPrefix("") + "Raster"
	String gName = NextGraphName(gPrefix, -1, NMOverWrite())
	String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(CurrentChan) + " : " + yRaster

	DoWindow /K $gName
	Display /K=1/N=$gName/W=(0,0,0,0) $yRaster vs $xRaster as gTitle
	SetCascadeXY(gName)
	ModifyGraph mode=3, marker=10, standoff=0, rgb=(65535,0,0)
	ModifyGraph manTick(left)={0,1,0,0},manMinor(left)={0,0}
	
	Label left NMNoteLabel("y", yRaster, wPrefix+"#")
	Label bottom NMNoteLabel("y", xRaster, "msec")
	
	WaveStats /Q/Z $yRaster
	
	SetAxis left -0.25, V_max+1
	
	if (numtype(winB*winE) == 0)
		SetAxis bottom winB, winE
	endif
	
	return gName

End // SpikeRasterPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeAvgAlert()
	String s1 = "ALERT: this function produced incorrect averages in previous NM versions due to division by wrong number of spikes. "
	String s2 = "Please use 'Spike 2 Waves' option and compute average of 'SP_Rstr' waves using Main tab. "

	DoAlert 0, s1 + s2

End // SpikeAvgAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function Spike2WavesCall()

	Variable icnt, ccnt, cbgn, cend, seq, stopyesno = 2
	String prefix, prefix2, fname, wlist, xl, yl, vlist = "", df = SpikeDF()
	
	String opstr = WaveListText0()
	
	if (SpikeRasterCheckWaves() == -1)
		return -1
	endif
	
	Variable currChan = NMCurrentChan()
	Variable nChan = NMNumChannels()
	
	String wPrefix = NMCurrentWavePrefix()
	
	Variable before = NumVarOrDefault(df+"S2W_before", 2)
	Variable after = NumVarOrDefault(df+"S2W_after", 5)
	Variable stop = NumVarOrDefault(df+"S2W_stopAtNextEvent", 0)
	String chan = StrVarOrDefault(df+"S2W_chan", ChanNum2Char(currChan))

	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	if (stop < 0)
		stopyesno = 1
	endif
	
	Prompt before, "time before spike (ms):"
	Prompt after, "time after spike (ms):"
	Prompt stopyesno, "limit data to time before next spike?", popup "no;yes;"
	Prompt stop, "additional time to limit data before next spike (ms):"
	Prompt prefix, "new wave prefix name:"
	Prompt chan, "channel waves to copy from:", popup "All;"+ChanCharList(-1, ";")
	
	if (nChan > 1)
	
		
		DoPrompt "Copy Spikes to Waves", before, after, stopyesno, chan
		
		cbgn = ChanChar2Num(chan)
		cend = ChanChar2Num(chan)
		
	else
	
		DoPrompt "Spikes to Waves", before, after, stopyesno
		
		cbgn = currChan
		cend = currChan
		
	endif
	
	if (V_flag == 1)
		return -1
	endif
	
	if (stopyesno == 2)
	
		if (stop < 0)
			stop = 0
		endif
		
		DoPrompt "Spikes to Waves", stop
		
	else
	
		stop = -1
		
	endif
	
	if (V_flag == 1)
		return -1
	endif
	
	SetNMvar(df+"S2W_after", after)
	SetNMvar(df+"S2W_before", before)
	SetNMvar(df+"S2W_stopAtNextEvent", stop)
	SetNMstr(df+"S2W_chan", chan)
	
	if (StringMatch(wPrefix, NMNoteStrByKey(xRaster, "Spike Prefix")) == 0)
	
		DoAlert 1, "The current wave prefix does not match that of \"" + xRaster + "\". Do you want to continue?"
		
		if (V_Flag != 1)
			return 0
		endif
		
	endif
	
	seq = SeqNumFind(xRaster)
	
	prefix = "SP_Rstr" + num2str(seq)
	
	if (StringMatch(chan, "All") == 1)
		cbgn = 0
		cend = nChan - 1
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		do
		
			fname = prefix + "*" + ChanNum2Char(ccnt) + "*"
			
			wlist = WaveList(fname, ";", opstr)
			
			if (ItemsInList(wlist) == 0)
				break // no name conflict
			else
			
				DoAlert 2, "Warning: waves already exist with prefix name \"" + prefix + "\". Do you want to overwrite these waves?"
				
				if (V_flag == 1)
				
					KillGlobals(GetDataFolder(1), fname, "001") // kill waves that exist
					break
					
				elseif (V_flag == 2)
				
					seq += 1
					prefix = "SP_Rstr" + num2str(seq)
					
					DoPrompt "Event to Waves", prefix
					
					if (V_flag == 1)
						return 0
					endif
					
				else
				
					return 0
					
				endif
				
			endif
		
		while (1)
		
		vlist = NMCmdStr(yRaster, vlist)
		vlist = NMCmdStr(xRaster, vlist)
		vlist = NMCmdNum(before, vlist)
		vlist = NMCmdNum(after, vlist)
		vlist = NMCmdNum(stop, vlist)
		vlist = NMCmdNum(ccnt, vlist)
		vlist = NMCmdStr(prefix, vlist)
		
		NMCmdHistory("Event2Wave", vlist)
	
		wlist = Event2Wave(yRaster, xRaster, before, after, stop, ccnt, prefix)
		
		if (strlen(wlist) == 0)
			DoAlert 0, "Error: no spikes detected"
			return 0
		endif
		
		if (WaveExists($prefix + "Times") == 1)
		
			prefix2 = ReplaceString("SP_Rstr", prefix, "SP_Rr")
			
			if (WaveExists($prefix2 + "Times") == 0)
				Rename $(prefix + "Times"), $(prefix2 + "Times")
			endif
			
		endif
		
		xl = ChanLabel(ccnt, "x", "")
		yl = ChanLabel(ccnt, "y", "")
		
		String gPrefix = prefix + "_" + NMFolderPrefix("") + ChanNum2Char(ccnt) + num2str(seq) 
		String gName = CheckGraphName(gPrefix)
		String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : Spikes"
	
		NMPlotWaves(gName, gTitle, xl, yl, "", wlist)
		
	endfor

End // Spike2WavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikePSTHCall()
	String wName, vlist = "", df = SpikeDF()
	
	if (SpikeRasterCheckWaves() == -1)
		return -1
	endif
	
	String dName = ChanDisplayWave(-1)
	
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	Variable winB = SpikeTmin(xRaster)
	Variable winE = SpikeTmax(xRaster)
	Variable psthD = NumVarOrDefault(df+"PSTHD", 1)
	String psthY = StrVarOrDefault(df+"PSTHY", "Spikes / bin")
	
	if (numtype(winB) > 0)
		winB = -inf
	endif
	
	if (numtype(winE) > 0)
		winE = inf
	endif
	
	Prompt winB, "window begin time (ms):"
	Prompt winE, "window end time (ms):"
	Prompt psthD, "histogram bin size (ms):"
	Prompt psthY, "y-axis dimensions:", popup "Spikes / bin;Spikes / sec;Probability;"
	DoPrompt "Compute PeriStimulus Time Histogram", winB, winE, psthD, psthY
	
	if (V_flag == 1)
		return -1
	endif
	
	SetNMvar(df+"PSTHD", psthD)
	SetNMstr(df+"PSTHY", psthY)

	vlist = NMCmdStr(xRaster, vlist)
	vlist = NMCmdStr(yRaster, vlist)
	vlist = NMCmdNum(winB, vlist)
	vlist = NMCmdNum(winE, vlist)
	vlist = NMCmdNum(psthD, vlist)
	vlist = NMCmdStr(psthY, vlist)
	NMCmdHistory("SpikePSTH", vlist)
	
	wName = SpikePSTH(xRaster, yRaster, winB, winE, psthD, psthY)
	
	return NMReturnStr2Num(wName)

End // SpikePSTHCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikePSTH(xRaster, yRaster, winB, winE, psthD, psthY)
	String xRaster, yRaster
	Variable winB, winE
	Variable psthD
	String psthY
	
	String xl = NMNoteLabel("y", xRaster, "msec")
	
	if ((WaveExists($xRaster) == 0) || (WaveExists($yRaster) == 0))
		return ""
	endif
	
	Variable reps = SpikeRasterCountReps(yRaster)
	
	Variable CurrentChan = NMCurrentChan()
	Variable overWrite = NMOverWrite()

	String wName = NextWaveName2("", xRaster + "_PSTH", -1, overWrite)
	String gPrefix = xRaster + "_" + NMFolderPrefix("") + "PSTH"
	String gName = NextGraphName(gPrefix, -1, overWrite)
	String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(CurrentChan) + " : " + wName
	
	if (numtype(winB) > 0)
		winB = SpikeTmin(xRaster)
	endif
	
	if (numtype(winE) > 0)
		winE = SpikeTmax(xRaster)
	endif
	
	Variable npnts = ceil((winE - winB) / psthD)
	
	Make /O/N=1 $wName
	
	Histogram /B={winB, psthD, npnts} $xRaster, $wName
	
	Wave PSTH = $wName
	
	NMNoteType(wName, "Spike PSTH", xl, psthY, "Func:SpikePSTH")
	
	Note $wName, "PSTH Bin:" + num2str(psthD) + ";PSTH Tbgn:" + num2str(winB) + ";PSTH Tend:" + num2str(winE) + ";"
	Note $wName, "PSTH xRaster:" + xRaster + ";PSTH yRaster:" + yRaster + ";"
	
	strswitch(psthY)
		case "Probability":
			PSTH /= reps
			break
		case "Spikes / sec":
			PSTH /= reps*psthD*0.001 // convert to seconds
			break
	endswitch
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=(0,0,0,0) PSTH as gTitle
	
	SetCascadeXY(gName)
	
	SetAxis bottom winB, winE
	ModifyGraph standoff=0, rgb=(0,0,0), mode=5, hbFill=2
	
	Label bottom xl
	Label left psthY
	
	return wName

End // SpikePSTH

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeISIHCall()
	String wName, vlist = "", df = SpikeDF()
	
	if (SpikeRasterCheckWaves() == -1)
		return -1
	endif
	
	String dName = ChanDisplayWave(-1)
	
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	Variable winB = SpikeTmin(xRaster)
	Variable winE = SpikeTmax(xRaster)
	Variable isiMin = NumVarOrDefault(df+"ISImin", 0)
	Variable isiMax = NumVarOrDefault(df+"ISImax", inf)
	Variable isihD = NumVarOrDefault(df+"ISIHD", 1)
	String isihY = StrVarOrDefault(df+"ISIHY", "Intvls / bin")
	
	if (numtype(winB) > 0)
		winB = -inf
	endif
	
	if (numtype(winE) > 0)
		winE = inf
	endif
	
	if (numtype(ISImin) > 0)
		ISImin = 0
	endif
	
	if (numtype(ISImax) > 0)
		ISImax = winE
	endif
	
	Prompt winB, "window begin time (ms):"
	Prompt winE, "window end time (ms):"
	Prompt isiMin, "minimum allowed inter-spike interval:"
	Prompt isiMax, "maximum allowed inter-spike interval:"
	Prompt isihD, "histogram bin size (ms):"
	Prompt isihY, "y-axis dimensions:", popup "Intvls / bin;Intvls / sec;"
	
	DoPrompt "Compute InterSpike Interval Histogram", winB, winE, isiMin, isiMax, isihD, isihY
	
	if (V_flag == 1)
		return -1
	endif
	
	SetNMvar(df+"ISIHD", isihD)
	SetNMstr(df+"ISIHY", isihY)
	SetNMvar(df+"ISImin", isiMin)
	SetNMvar(df+"ISImax", isiMax)

	vlist = NMCmdStr(xRaster, vlist)
	vlist = NMCmdStr(yRaster, vlist)
	vlist = NMCmdNum(winB, vlist)
	vlist = NMCmdNum(winE, vlist)
	vlist = NMCmdNum(isiMin, vlist)
	vlist = NMCmdNum(isiMax, vlist)
	vlist = NMCmdNum(isihD, vlist)
	vlist = NMCmdStr(isihY, vlist)
	NMCmdHistory("SpikeISIH", vlist)
	
	wname = SpikeISIH(xRaster, yRaster, winB, winE, isiMin, isiMax, isihD, isihY)

	return NMReturnStr2Num(wName)

End // SpikeISIHCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeISIH(xRaster, yRaster, winB, winE, isiMin, isiMax, isihD, isihY)
	String xRaster, yRaster
	Variable winB, winE
	Variable isiMin, isiMax
	Variable isihD
	String isihY
	
	Variable icnt
	
	if ((WaveExists($xRaster) == 0) || (WaveExists($yRaster) == 0))
		return ""
	endif
	
	if (numtype(winB) > 0)
		winB = SpikeTmin(xRaster)
	endif
	
	if (numtype(winE) > 0)
		winE = SpikeTmax(xRaster)
	endif
	
	String xl = NMNoteLabel("y", xRaster, "msec")
	
	Variable events = Time2Intervals(xRaster, winB, winE, isiMin, isiMax) // results saved in U_INTVLS
		
	if ((events <= 0) || (WaveExists(U_INTVLS) == 0))
		DoAlert 0, "No interspike intervals detected."
		return ""
	endif
	
	Variable reps = SpikeRasterCountReps(yRaster)
	
	Variable CurrentChan = NMCurrentChan()
	Variable overWrite = NMOverWrite()
	
	String wName1 = NextWaveName2("", xRaster + "_Intvls", -1, overWrite)
	String wName2 = NextWaveName2("", xRaster + "_ISIH", -1, overWrite)
	String gPrefix = xRaster + "_" + NMFolderPrefix("") + "ISIH"
	String gName = NextGraphName(gPrefix, -1, overWrite)
	String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(CurrentChan) + " : " + wName2
	
	WaveStats /Q/Z $xRaster
	
	if (numtype(winB) > 0)
		winB = V_min
	endif
	
	if (numtype(winE) > 0)
		winE = V_max
	endif
	
	if (numtype(ISImin) > 0)
		ISImin = 0
	endif
	
	if (numtype(ISImax) > 0)
		ISImax = V_max - V_min
	endif
	
	Variable npnts = (isiMax - isiMin) / isihD
	
	Make /O/N=1 $wName2
	
	Histogram /B={isiMin, isihD, npnts} U_INTVLS, $wName2
	
	Wave ISIH = $wName2
	
	Duplicate /O U_INTVLS $wName1
	
	NMNoteType(wName1, "Spike Intervals", xl, isihY, "Func:SpikeISIH")
	Note $wName1, "ISIH Bin:" + num2str(isihD) + ";ISIH Tbgn:" + num2str(winB) + ";ISIH Tend:" + num2str(winE) + ";"
	Note $wName1, "ISIH Min:" + num2str(isiMin) + ";ISIH Max:" + num2str(isiMax) + ";"
	Note $wName1, "ISIH xRaster:" + xRaster + ";ISIH yRaster:" + yRaster + ";"
	
	NMNoteType(wName2, "Spike ISIH", xl, isihY, "Func:SpikeISIH")
	
	Note $wName2, "ISIH Bin:" + num2str(isihD) + ";ISIH Tbgn:" + num2str(winB) + ";ISIH Tend:" + num2str(winE) + ";"
	Note $wName2, "ISIH Min:" + num2str(isiMin) + ";ISIH Max:" + num2str(isiMax) + ";"
	Note $wName2, "ISIH xRaster:" + xRaster + ";ISIH yRaster:" + yRaster + ";"
	
	for (icnt = numpnts(ISIH) - 1; icnt >= 0; icnt -= 1) // remove trailing zeros
		if (ISIH[icnt] > 0)
			break
		elseif (ISIH[icnt] == 0)
			ISIH[icnt] = Nan
		endif
	endfor
	
	WaveStats /Q/Z ISIH
	
	Redimension /N=(V_npnts) ISIH
	
	if (StringMatch(isihY, "Intvls / sec") == 1)
		ISIH /= isihD*0.001
	endif
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=(0,0,0,0) ISIH as gTitle
	
	SetCascadeXY(gName)
	
	ModifyGraph standoff=0, rgb=(0,0,0), mode=5, hbFill=2
	Label bottom xl
	Label left isihY
	SetAxis/A
	
	Print "\rIntervals stored in wave " + wName1
	
	return wName2
	
End // SpikeISIH

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRateCall()
	String gName, vlist = "", df = SpikeDF()
	
	if (SpikeRasterCheckWaves() == -1)
		return -1
	endif
	
	String dName = ChanDisplayWave(-1)
	
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	Variable winB = SpikeTmin(xRaster)
	Variable winE = SpikeTmax(xRaster)
	
	if (numtype(winB) > 0)
		winB = leftx($dName)
	endif
	
	if (numtype(winE) > 0)
		winE = rightx($dName)
	endif
	
	Prompt winB, "window begin time (ms):"
	Prompt winE, "window end time (ms):"
	DoPrompt "Spike Rate", winB, winE
	
	if (V_flag == 1)
		return -1
	endif
	
	vlist = NMCmdStr(xRaster, vlist)
	vlist = NMCmdStr(yRaster, vlist)
	vlist = NMCmdNum(winB, vlist)
	vlist = NMCmdNum(winE, vlist)
	NMCmdHistory("SpikeRate", vlist)

	gName = SpikeRate(xRaster, yRaster, winB, winE)
	
	return NMReturnStr2Num(gName)

End // SpikeRateCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRate(xRaster, yRaster, winB, winE)
	String xRaster, yRaster // Raster x-y data
	Variable winB, winE
	
	Variable icnt, npnts, wnum
	String xl, yl
	
	Variable CurrentChan = NMCurrentChan()
	Variable overWrite = NMOverWrite()
	
	String wPrefix = StrVarOrDefault("WavePrefix", "")
	String wName = NextWaveName2("", xRaster + "_Rate", -1, overWrite)
	String gPrefix = xRaster + "_" + NMFolderPrefix("") + "Rate"
	String gName = NextGraphName(gPrefix, -1, overWrite)
	String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(CurrentChan) + " : " + wName
	
	if ((WaveExists($xRaster) == 0) || (WaveExists($yRaster) == 0))
		return ""
	endif
	
	if (numtype(winB) > 0)
		winB = SpikeTmin(xRaster)
	endif
	
	if (numtype(winE) > 0)
		winE = SpikeTmax(xRaster)
	endif
	
	if (numtype(winB*winE) > 0)
		return ""
	endif
	
	Wave xr = $xRaster
	Wave yr = $yRaster
	
	WaveStats /Q/Z yr
	
	npnts = V_max
	
	Make /O/N=(npnts+1) $wName
	
	Wave wtemp = $wName
	
	wtemp = Nan
	
	for (icnt = 0; icnt < numpnts(xr); icnt += 1)
	
		wnum = yr[icnt]
		
		if (numtype(wnum) > 0)
			continue
		endif
	
		if (numtype(wtemp[yr[icnt]]) > 0)
			wtemp[yr[icnt]] = 0
		endif
	
		if ((xr[icnt] >= winB) && (xr[icnt] <= winE))
			wtemp[yr[icnt]] += 1
		endif
		
	endfor
	
	wtemp *= 1000 / (winE - winB) // convert to rate
	
	xl = NMNoteLabel("y", yRaster, wPrefix+"#")
	yl = "Spikes / sec"
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=(0,0,0,0) $wName as gTitle
	SetCascadeXY(gName)
	ModifyGraph standoff=0, rgb=(65280,0,0), mode=4, marker=19
	Label bottom xl
	Label left yl
	
	WaveStats /Q/Z $wName
	
	SetAxis left 0, V_max
	
	NMNoteType(wName, "Spike Rate", xl, yl, "Func:SpikeRate")
	
	Note $wName, "Rate Tbgn:" + num2str(winB) + ";Rate Tend:" + num2str(winE) + ";"
	Note $wName, "Rate xRaster:" + xRaster + ";Rate yRaster:" + yRaster + ";"
	
	return wName

End // SpikeRate

//****************************************************************
//****************************************************************
//****************************************************************

Function Hazard(isiName) // compute hazard function from ISI data
	String isiName // interspike interval wave name (dimensions should be spikes/bin)
	
	if (WaveExists($isiName) == 0)
		return -1
	endif
	
	Variable icount, jcount, lmt, summ, delta
	
	Wave ISIH = $isiName
	
	delta = deltax(ISIH)
	
	Duplicate /O ISIH HZD
	
	lmt = numpnts(ISIH)
	
	for (icount = 0; icount < lmt; icount+=1)
	
		summ = 0
		
		for (jcount = icount; jcount < lmt; jcount += 1)
			summ += ISIH[jcount]
		endfor
		
		HZD[icount] /= delta*summ
		
	endfor
	
	HZD *= 1000

End // Hazard

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTableCall()
	
	NMCmdHistory("SpikeTable", "")
	return SpikeTable()

End // SpikeTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTable()
	Variable icnt
	
	String tname = "SP_" + NMFolderPrefix("") + "Table"
	String wlist = WaveList("SP_R*", ";", WaveListText0())
	String wlist2 = WaveList("SP_Rstr*", ";", WaveListText0())
	
	wlist = RemoveFromList("SP_RasterY", wlist)
	wlist = RemoveFromList("SP_RasterX", wlist)
	wlist = RemoveFromList(wlist2, wlist)

	if (ItemsInList(wlist) == 0)
		DoAlert 0, "Detected no Spike waves."
		return -1
	endif
	
	tname = NextGraphName(tname, -1, NMOverWrite())
	
	DoWindow /K $tname
	Edit /K=1/N=$tname/W=(0,0,0,0) as "Spike Waves"
	SetCascadeXY(tname)
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		AppendToTable $StringFromList(icnt, wlist)
	endfor
	
	return 0

End // SpikeTable

//****************************************************************
//****************************************************************
//****************************************************************

Function XTimes2Spike() : GraphMarquee // use marquee x-values for stats t_beg and t_end
	String df = SpikeDF()
	
	if ((DataFolderExists(df) == 0) || (IsCurrentNMTab("Spike") == 0))
		return 0 
	endif

	GetMarquee left, bottom
	
	if (V_Flag == 0)
		return 0
	endif
	
	SetNMvar(df+"WinB", V_left)
	SetNMvar(df+"WinE", V_right)
	
	AutoSpike()

End // XTimes2Spike

//****************************************************************
//****************************************************************
//****************************************************************