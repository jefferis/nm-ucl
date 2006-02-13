#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Spike Analysis
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 10 March 2005
//
//	NM tab entry "Spike"
//
//	Compute spike rasters, averages, PST histograms,
//	interspike interval histograms and hazard functions.
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

Function Spike(enable)
	Variable enable // (0) disable (1) enable tab
	
	if (enable == 1)
		CheckPackage("Spike", 0) // declare globals if necessary
		MakeSpike(0) // make controls if necessary
		UpdateSpike()
		AutoSpike()
	endif
	
	if (DataFolderExists(SpikeDF()) == 1)
		DisplaySpikeWaves(enable)
	endif

End // Spike

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
	
	CheckNMvar(df+"Thresh", 20)				// threshold detection level
	CheckNMvar(df+"WinB", -inf)				// analysis window begin time
	CheckNMvar(df+"WinE", inf)				// analysis window end time
	CheckNMvar(df+"Events", 0) 				// number of events detected
	
	CheckNMvar(df+"AvgCh", 0)				// channel to compute triggered average
	CheckNMvar(df+"AvgWin", 10)				// avg time window size
	CheckNMvar(df+"SaveWin", 0)				// save windows of individual waves (1 - yes; 0 - no)
	
	CheckNMvar(df+"PSTHD", 1)				// PSTH bin width
	CheckNMstr(df+"PSTHY", "Spikes / bin")	// PSTH y-axis mode (Spikes / bin, Spikes / sec, Probability)
	
	CheckNMvar(df+"ISImin", 0)				// minimum ISI limit
	CheckNMvar(df+"ISImax", inf)				// maximum ISI limit
	CheckNMvar(df+"ISIHD", 1)				// ISIH bin width
	CheckNMstr(df+"ISIHY", "Intvls / bin")		// ISIH y-axis mode (Intvls / bin, Intvls / sec)
	
	// waves for display graphs
	
	CheckNMwave(df+"SP_SpikeX", 0, Nan)
	CheckNMwave(df+"SP_SpikeY", 0, Nan)
	
	return 0
	
End // CheckSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckSpikeWindows()
	String df = SpikeDF()
	
	Variable tend = rightx($CurrentChanDisplayWave())

	if (numtype(NumVarOrDefault(df+"WinB", Nan)) > 0)
		SetNMvar(df+"WinB", -inf)
	endif
	
	if (numtype(NumVarOrDefault(df+"WinE", Nan)) > 0)
		SetNMvar(df+"WinE", inf)
	endif
	
	if (numtype(NumVarOrDefault(df+"ISImin", Nan)) > 0)
		SetNMvar(df+"ISImin", 0)
	endif
	
	if (numtype(NumVarOrDefault(df+"ISImax", Nan)) > 0)
		SetNMvar(df+"ISImax", inf)
	endif

End // CheckSpikeWindows

//****************************************************************
//****************************************************************
//****************************************************************

Function DisplaySpikeWaves(appnd) // append/remove spike wave from channel graph
	Variable appnd // 1- append wave; 0 - remove wave
	
	Variable ccnt
	String gName, df = SpikeDF()
	
	if (DataFolderExists(df) == 0)
		return 0 // spike has not been initialized yet
	endif
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable numChannels = NumVarOrDefault("NumChannels", 0)
	
	if (appnd == 0)
		SetNMwave(df+"SP_SpikeX", -1, Nan)
		SetNMwave(df+"SP_SpikeY", -1, Nan)
	endif
	
	for (ccnt = 0; ccnt < numChannels; ccnt += 1)
	
		gName = GetGraphName("Chan", ccnt)
	
		if (Wintype(gName) == 0)
			continue // window does not exist
		endif
	
		RemoveFromGraph /Z/W=$gName SP_SpikeY
		
		if ((appnd == 1) && (ccnt == CurrentChan))
			AppendToGraph /W=$gName $(df+"SP_SpikeY") vs $(df+"SP_SpikeX")
			ModifyGraph /W=$gName mode(SP_SpikeY)=3, marker(SP_SpikeY)=9
			ModifyGraph /W=$gName mrkThick(SP_SpikeY)=2, rgb(SP_SpikeY)=(65535,0,0)
		endif
		
	endfor

End // DisplaySpikeWaves
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeSpike(force) // create Spike tab controls
	Variable force

	Variable x0 = 40, y0 = 195, xinc = 120, yinc = 35
	String df = SpikeDF()
	
	ControlInfo /W=NMPanel SP_Thresh
	
	if ((V_Flag != 0) && (force == 0))
		return 0 // Spike tab has already been created, return here
	endif
	
	if (DataFolderExists(df) == 0)
		return 0 // spike has not been initialized yet
	endif
	
	DoWindow /F NMPanel
	
	GroupBox SP_Grp1, title = "Spike Detection", pos={20,y0}, size={260,150}
	
	SetVariable SP_Thresh, title="Threshold: ", pos={x0,y0+1*yinc}, limits={-inf,inf,0}, size={100,20}, frame=1, value=$(df+"Thresh"), proc=SpikeSetVariable
	SetVariable SP_Count, title="Spikes: ", pos={x0,y0+2*yinc}, limits={0,inf,0}, size={100,20}, frame=0, value=$(df+"Events")
	SetVariable SP_WinB, title="t_beg: ", pos={x0+xinc,y0+1*yinc}, limits={-inf,inf,0}, size={100,20}, frame=1, value=$(df+"WinB"), proc=SpikeSetVariable
	SetVariable SP_WinE, title="t_end: ", pos={x0+xinc,y0+2*yinc}, limits={-inf,inf,0}, size={100,20}, frame=1, value=$(df+"WinE"), proc=SpikeSetVariable
	
	y0 += 4
	
	//Button SP_Save, title = "Save", pos={95,y0+2*yinc}, size={50,20}, proc = SpikeButton
	//Button SP_Clear, title = "Clear", pos={155,y0+2*yinc}, size={50,20}, proc = SpikeButton
	
	Button SP_All, title = "All Waves", pos={x0,y0+3*yinc}, size={100,20}, proc = SpikeButton
	Button SP_Table, title = "Table", pos={x0+xinc,y0+3*yinc}, size={100,20}, proc = SpikeButton
	
	y0 = 380; yinc = 35
	
	GroupBox SP_Grp2, title = "Spike Analysis", pos={20,y0}, size={260,200}
	
	PopupMenu SP_WaveSlct, pos={x0+120,y0+1*yinc}, bodywidth=125
	PopupMenu SP_WaveSlct, value="Select Wave;---;Other...;", proc=SpikePopup
	
	yinc = 40
	
	Button SP_Raster, title="Raster Plot", pos={x0,y0+2*yinc}, size={100,20}, proc=SpikeButton
	Button SP_Rate, title="Avg Rate", pos={x0+xinc,y0+2*yinc}, size={100,20}, proc=SpikeButton
	Button SP_PSTH, title="PST Histo", pos={x0,y0+3*yinc}, size={100,20}, proc=SpikeButton
	Button SP_ISIH, title="ISI Histo", pos={x0+xinc,y0+3*yinc}, size={100,20}, proc=SpikeButton
	Button SP_Average, title="Average", pos={x0,y0+4*yinc}, size={100,20}, proc=SpikeButton
	Button SP_2Waves, title="Spikes 2 Waves", pos={x0+xinc,y0+4*yinc}, size={100,20}, proc=SpikeButton
	
End // MakeSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateSpike()
	
	Variable md
	String wlist, wSelect, df = SpikeDF()
	
	wlist = SpikeWaveList()
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

	PopupMenu SP_WaveSlct, win=NMPanel, mode=md, value="Select Wave;---;" + SpikeWaveList() + "---;Other...;"

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
			return SpikeAllWavesCall()
			
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
			return SpikeAvgCall()
			
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
	
	String df = SpikeDF()
	
	if (tbgn >= tend)
		tbgn = -inf // not allowed
		tend = inf
		return -1
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
		t = leftx($CurrentChanDisplayWave())
	endif
	
	return t

End // SpikeWinBgn

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWinEnd()

	Variable t = NumVarOrDefault(SpikeDF()+"WinE", inf)

	if (numtype(t) > 0)
		t = rightx($CurrentChanDisplayWave())
	endif
	
	return t

End // SpikeWinEnd

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeWaveList()

	String wSelect = StrVarOrDefault(SpikeDF()+"RasterWaveX", "")
	
	String opstr = WaveListText0()

	String wlist = WaveList("SP_RasterX_*", ";", opstr) + WaveList("SP_RX_*", ";", opstr)
	
	if ((WhichListItemLax(wSelect, wList, ";") < 0) && (exists(wSelect) == 1))
		wlist += wSelect + ";"
	endif

	return wlist

End // SpikeWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterSelectCall(xRaster)
	String xRaster
	
	Variable inum
	String vlist = "", df = SpikeDF()
	String yRaster = xRaster
	
	if (WaveExists($xRaster) == 0)
		return -1
	endif
	
	inum = strsearch(xRaster, "RasterX", 0)
	
	if (inum > 0)
		inum += 6
		yRaster[inum,inum] = "Y"
		inum = -1
	else
		inum = strsearch(xRaster, "RX", 0)
	endif
	
	if (inum > 0)
		inum += 1
		yRaster[inum,inum] = "Y"
	endif
	
	SetNMstr(df+"RasterWaveX", xRaster)
	SetNMstr(df+"RasterWaveY", yRaster)
	
	if (SpikeCheckRasterWaves() == 0)
	
		xRaster = StrVarOrDefault(df+"RasterWaveX", "")
		yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
		vlist = NMCmdStr(xRaster, vlist)
		vlist = NMCmdStr(yRaster, vlist)
		NMCmdHistory("SpikeRasterSelect", vlist)
		
		return SpikeRasterSelect(xRaster, yRaster)
		
	else
	
		SetNMstr(df+"RasterWaveX", "")
		SetNMstr(df+"RasterWaveY", "")
		
		UpdateSpike()
		
		return -1
	
	endif
	
End // SpikeRasterSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterSelect(xRaster, yRaster)
	String xRaster, yRaster

	String df = SpikeDF()

	if ((WaveExists($xRaster) == 0) || (WaveExists($yRaster) == 0))
		return -1
	endif
	
	if (numpnts($xRaster) == numpnts($yRaster))
		return -1
	endif
	
	SetNMstr(df+"RasterWaveX", xRaster)
	SetNMstr(df+"RasterWaveY", yRaster)
	
	UpdateSpike()

End // SpikeRasterSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeCheckRasterWaves()

	String df = SpikeDF()
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	String opstr = WaveListText0()
	
	if ((WaveExists($xRaster) == 1) && (WaveExists($yRaster) == 1))
		if (numpnts($xRaster) == numpnts($yRaster))
			return 0
		endif
	endif
	
	Prompt xRaster, "select x-raster of spike times (i.e. SP_RasterX_A0):", popup WaveList("*", ";", opstr)
	Prompt yRaster, "select corresponding y-raster of wave numbers (i.e. SP_RasterY_A0):", popup WaveList("*", ";", opstr)
	DoPrompt "Spike Raster Plot", xRaster, yRaster
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	if (numpnts($xRaster) != numpnts($yRaster))
		return -1
	endif
	
	SetNMstr(df+"RasterWaveX", xRaster)
	SetNMstr(df+"RasterWaveY", yRaster)
	
	return 0

End // SpikeCheckRasterWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoSpike() // compute threshold crossings on currently selected channel/wave; display on graph

	Variable index, ncnt, slope, events
	Variable dtWin = 1 // window to compute slope
	Variable eventLimit = 2000 // limit of number of events before warning
	
	String df = SpikeDF()
	
	CheckSpikeWindows()
	
	Variable winB = NumVarOrDefault(df+"WinB", -inf)
	Variable winE = NumVarOrDefault(df+"WinE", inf)
	Variable thresh = NumVarOrDefault(df+"Thresh", 0)
	
	if (WaveExists($(df+"SP_SpikeY")) == 0)
		return -1
	endif
	
	Wave SP_SpikeX = $(df+"SP_SpikeX")
	Wave SP_SpikeY = $(df+"SP_SpikeY")
	
	String wName = CurrentWaveName()
	
	events = SpikeRaster(Thresh, winB, winE, "SP_RasterX", "SP_RasterY", wName)
	
	SP_SpikeY = Nan
	
	if ((events > 0) && (WavesExist("SP_RasterX;SP_RasterY;") == 1))
	
		Wave SP_RasterX, SP_RasterY
	
		if (Events > eventlimit)
			DoAlert 1, "Warning:  " + num2str(Events) + " events detected. Do you want to plot each event?"
			if (V_Flag != 1)
				return 0
			endif
		endif
		
		Redimension /N=(Events) SP_SpikeX, SP_SpikeY
		
		SP_SpikeY = Thresh
		SP_SpikeX = SP_RasterX
		
	else
	
		events = 0
	
	endif
	
	SetNMvar(df+"Events", events)
	
	KillWaves /Z SP_RasterX, SP_RasterY

End // AutoSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeAllWavesCall()

	if (NMAllGroups() == 1)
		SpikeAllGroups()
	else
		SpikeAllWaves()
	endif

End // SpikeAllWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeAllGroups()
	Variable grpcnt
	String gName
	
	String saveSelect = NMWaveSelectGet()
	String grpList = NMGroupList(1)
	
	for (grpcnt = 0; grpcnt < ItemsInList(grpList); grpcnt += 1)
		NMWaveSelect(StringFromList(grpcnt, grpList))
		gName = SpikeAllWaves()
	endfor
	
	NMWaveSelect(saveSelect)
	
	return 0

End // SpikeAllGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllWaves()

	Variable ccnt, spikes, overwrite = NMOverWrite()
	String pName, gName, xName, yName, vlist, df = SpikeDF()
	
	Variable Nameformat = NumVarOrDefault(NMDF() + "NameFormat", 1)
	
	Variable winB = NumVarOrDefault(df+"WinB", -inf)
	Variable winE = NumVarOrDefault(df+"WinE", inf)
	Variable thresh = NumVarOrDefault(df+"Thresh", 0)
	
	Variable saveChan = NumVarOrDefault("CurrentChan", 0)
	
	Wave  ChanSelect
	
	if (NameFormat == 1)
		pName = NMWaveSelectStr() + "_"
	endif
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
		
		SetNMvar("CurrentChan", ccnt)

		xName = NextWaveName("SP_RX_" + pName, ccnt, overwrite)
		yName = NextWaveName("SP_RY_" + pName, ccnt, overwrite)
		
		vlist = ""
		vlist = NMCmdNum(thresh, vlist)
		vlist = NMCmdNum(WinB, vlist)
		vlist = NMCmdNum(WinE, vlist)
		vlist = NMCmdStr(xName, vlist)
		vlist = NMCmdStr(yName, vlist)
		vlist = NMCmdStr("All", vlist)
		NMCmdHistory("SpikeRaster", vlist)
		
		spikes = SpikeRaster(thresh, WinB, WinE, xName, yName, "All")
		
		SetNMstr(df+"RasterWaveX", xName)
		SetNMstr(df+"RasterWaveY", yName)
		
		gName = SpikeRasterPlot(xName, yName, SpikeWinBgn(), SpikeWinEnd())
		
	endfor
	
	SetNMvar("CurrentChan", saveChan)
	
	UpdateSpike()
	
	return gName
	
End // SpikeAllWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterPlotCall()
	String gName, vlist = "", df = SpikeDF()
	
	if (SpikeCheckRasterWaves() == -1)
		return -1
	endif
	
	String dName = CurrentChanDisplayWave()
	
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	Variable winB = NMNoteVarByKey(xRaster, "Spike Tbgn")
	Variable winE = NMNoteVarByKey(xRaster, "Spike Tend")
	
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
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable NumWaves = NumVarOrDefault("NumWaves", 0)
	
	String wPrefix = StrVarOrDefault("WavePrefix", "")
	String df = SpikeDF()
	
	String gPrefix = xRaster + "_" + NMFolderPrefix("") + "Raster"
	String gName = NextGraphName(gPrefix, -1, NMOverWrite())
	String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(CurrentChan) + " : " + yRaster

	DoWindow /K $gName
	Display /K=1/W=(0,0,0,0) $yRaster vs $xRaster as gTitle
	DoWindow /C $gName
	SetCascadeXY(gName)
	ModifyGraph mode=3, marker=10, standoff=0, rgb=(65535,0,0)
	
	Label left NMNoteLabel("y", yRaster, wPrefix+"#")
	Label bottom NMNoteLabel("y", xRaster, "msec")
	
	WaveStats /Q $yRaster
	
	SetAxis left 0, V_max+1
	
	if (numtype(winB*winE) == 0)
		SetAxis bottom winB, winE
	endif
	
	return gName

End // SpikeRasterPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeAvgCall()

	String wName, vlist = "", df = SpikeDF()
	
	if (SpikeCheckRasterWaves() == -1)
		return -1
	endif
	
	Variable NumChannels = NumVarOrDefault("NumChannels", 0)
	
	Variable avgCh = NumVarOrDefault(df+"AvgCh", 0) + 1
	Variable avgWin = NumVarOrDefault(df+"AvgWin", 10)
	Variable saveWin = NumVarOrDefault(df+"SaveWin", 0) + 1

	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	Prompt avgCh, "channel to compute triggered average: ", popup ChanCharList(NumChannels, ";")
	Prompt avgWin, "average time window to compute: "
	Prompt saveWin, "save/display triggered events with average?", popup "no;yes"
	DoPrompt "Spike Triggered Average", avgCh, avgWin, saveWin
	
	if (V_flag == 1)
		return -1
	endif
	
	avgCh -= 1
	saveWin -= 1
	
	SetNMvar(df+"AvgCh", avgCh)
	SetNMvar(df+"AvgWin", avgWin)
	SetNMvar(df+"SaveWin", saveWin)
	
	vlist = NMCmdStr(xRaster, vlist)
	vlist = NMCmdStr(yRaster, vlist)
	vlist = NMCmdNum(avgCh, vlist)
	vlist = NMCmdNum(avgWin, vlist)
	vlist = NMCmdNum(saveWin, vlist)
	NMCmdHistory("SpikeAvg", vlist)

	wName = SpikeAvg(xRaster, yRaster, avgCh, avgWin, saveWin)
	
	return NMReturnStr2Num(wName)

End // SpikeAvgCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAvg(xRaster, yRaster, AvgCh, AvgWin, SaveWin)
	String xRaster, yRaster
	Variable AvgCh
	Variable AvgWin
	Variable SaveWin
	
	if ((WaveExists($xRaster) == 0) || (WaveExists($yRaster) == 0))
		return ""
	endif
	
	Variable spkcnt
	String wlist, sname, prefix
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable overWrite = NMOverWrite()

	String wName = NextWaveName("SP_AvgCh" + ChanNum2Char(AvgCh) + "_", CurrentChan, overWrite)
	String gPrefix = xRaster + "_" + NMFolderPrefix("") + "A" + ChanNum2Char(AvgCh)
	String gName = NextGraphName(gPrefix, -1, overWrite)
	String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(AvgCh) + " : Spike Avg"
	
	prefix = TrigAvg(xRaster, yRaster, AvgCh, AvgWin, SaveWin) // results saved in wave SP_TrgAvg
	
	if (WaveExists(SP_TrgAvg) == 0)
		return ""
	endif
	
	Duplicate /O SP_TrgAvg $wName
	
	DoWindow /K $gName
	Display /K=1/W=(0,0,0,0) $wName as gTitle
	DoWindow /C $gName
	
	SetCascadeXY(gName)
	
	Label bottom NMNoteLabel("x", wName, "msec")
	Label left NMNoteLabel("y", wName, "avg")
	
	if (SaveWin == 1)
	
		wList = WaveList(prefix + "*", ";", WaveListText0())
		
		if (ItemsInList(wList) > 0)
		
			NMPrefixAdd(prefix)
		
			if (DataFolderExists(gName) == 1)
				KillDataFolder $gName
			endif
			
			for (spkcnt = 0; spkcnt < ItemsInList(wList); spkcnt += 1)
				sName = StringFromList(spkcnt, wList)
				AppendToGraph $sName
			endfor
			
			ModifyGraph zero(bottom)=1, standoff = 0, rgb=(0,0,0)
			RemoveFromGraph $wName
			AppendToGraph $wName
			
		endif
		
	endif

	KillWaves /Z SP_TrgAvg
	
	return wName

End // SpikeAvg

//****************************************************************
//****************************************************************
//****************************************************************

Function Spike2WavesCall()

	Variable icnt, ccnt, cbgn, cend, seq
	String prefix, fname, wlist, xl, yl, vlist = "", df = SpikeDF()
	
	String opstr = WaveListText0()
	
	if (SpikeCheckRasterWaves() == -1)
		return -1
	endif
	
	Variable currChan = NumVarOrDefault("CurrentChan", 0)
	Variable nChan = NumVarOrDefault("NumChannels", 1)
	
	String wPrefix = StrVarOrDefault("CurrentPrefix", "")
	
	Variable before = NumVarOrDefault(df+"S2Wbefore", 2)
	Variable after = NumVarOrDefault(df+"S2Wafter", 10)
	String chan = StrVarOrDefault(df+"S2Wchan", ChanNum2Char(currChan))

	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	Prompt before, "copy data from time before spike (ms):"
	Prompt after, "copy data to time after spike (ms):"
	Prompt prefix, "enter new prefix name:"
	
	if (nChan > 1)
	
		Prompt chan, "channel waves to copy:", popup "All;"+ChanCharList(-1, ";")
		DoPrompt "Spikes to Waves", before, after, chan
		
	else
	
		DoPrompt "Spikes to Waves", before, after
		
		cbgn = currChan
		cend = currChan
		
	endif
	
	if (V_flag == 1)
		return -1
	endif
	
	SetNMstr(df+"S2Wchan", chan)
	SetNMvar(df+"S2Wafter", after)
	SetNMvar(df+"S2Wbefore", before)
	
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
		vlist = NMCmdNum(ccnt, vlist)
		vlist = NMCmdStr(prefix, vlist)
		
		NMCmdHistory("Event2Wave", vlist)
	
		wlist = Event2Wave(yRaster, xRaster, before, after, ccnt, prefix)
		
		if (strlen(wlist) == 0)
			return 0
		endif
		
		xl = ChanLabel(ccnt, "x", "")
		yl = ChanLabel(ccnt, "y", "")
		
		String gPrefix = prefix + "_" + NMFolderPrefix("") + ChanNum2Char(ccnt) + num2str(seq) 
		String gName = CheckGraphName(gPrefix)
		String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : Spikes"
	
		NMPlotWaves(gName, gTitle, xl, yl, wlist)
		
	endfor

End // Spike2WavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikePSTHCall()
	String wName, vlist = "", df = SpikeDF()
	
	if (SpikeCheckRasterWaves() == -1)
		return -1
	endif
	
	String dName = CurrentChanDisplayWave()
	
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	Variable winB = NMNoteVarByKey(xRaster, "Spike Tbgn")
	Variable winE = NMNoteVarByKey(xRaster, "Spike Tend")
	Variable psthD = NumVarOrDefault(df+"PSTHD", 1)
	String psthY = StrVarOrDefault(df+"PSTHY", "")
	
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
	
	Variable reps = SpikeRepsCount(yRaster)
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable overWrite = NMOverWrite()

	String wName = NextWaveName(xRaster + "_PSTH", -1, overWrite)
	String gPrefix = xRaster + "_" + NMFolderPrefix("") + "PSTH"
	String gName = NextGraphName(gPrefix, -1, overWrite)
	String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(CurrentChan) + " : " + wName
	
	WaveStats /Q $xRaster
	
	if (numtype(winB) > 0)
		winB = V_min
	endif
	
	if (numtype(winE) > 0)
		winE = V_max
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
	Display /K=1/W=(0,0,0,0) PSTH as gTitle
	DoWindow /C $gName
	
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
	
	if (SpikeCheckRasterWaves() == -1)
		return -1
	endif
	
	String dName = CurrentChanDisplayWave()
	
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	Variable winB = NMNoteVarByKey(xRaster, "Spike Tbgn")
	Variable winE = NMNoteVarByKey(xRaster, "Spike Tend")
	Variable isiMin = NumVarOrDefault(df+"ISImin", 0)
	Variable isiMax = NumVarOrDefault(df+"ISImax", inf)
	Variable isihD = NumVarOrDefault(df+"ISIHD", 1)
	String isihY = StrVarOrDefault(df+"ISIHY", "")
	
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
	
	String xl = NMNoteLabel("y", xRaster, "msec")
	
	Variable events = Time2Intervals(xRaster, winB, winE, isiMin, isiMax) // results saved in U_INTVLS
		
	if (events <= 0)
		DoAlert 0, "No interspike intervals detected."
		return ""
	endif
	
	Variable reps = SpikeRepsCount(yRaster)
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable overWrite = NMOverWrite()
	
	String wName = NextWaveName(xRaster + "_ISIH", -1, overWrite)
	String gPrefix = xRaster + "_" + NMFolderPrefix("") + "ISIH"
	String gName = NextGraphName(gPrefix, -1, overWrite)
	String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(CurrentChan) + " : " + wName
	
	WaveStats /Q $xRaster
	
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
	
	Make /O/N=1 $wName
	
	Histogram /B={isiMin, isihD, npnts} U_INTVLS, $wName
	
	Wave ISIH = $wName
	
	NMNoteType(wName, "Spike ISIH", xl, isihY, "Func:SpikeISIH")
	
	Note $wName, "ISIH Bin:" + num2str(isihD) + ";ISIH Tbgn:" + num2str(winB) + ";ISIH Tend:" + num2str(winE) + ";"
	Note $wName, "ISIH Min:" + num2str(isiMin) + ";ISIH Max:" + num2str(isiMax) + ";"
	Note $wName, "ISIH xRaster:" + xRaster + ";ISIH yRaster:" + yRaster + ";"
	
	for (icnt = numpnts(ISIH) - 1; icnt >= 0; icnt -= 1) // remove trailing zeros
		if (ISIH[icnt] > 0)
			break
		elseif (ISIH[icnt] == 0)
			ISIH[icnt] = Nan
		endif
	endfor
	
	WaveStats /Q ISIH
	
	Redimension /N=(V_npnts) ISIH
	
	if (StringMatch(isihY, "Intvls / sec") == 1)
		ISIH /= isihD*0.001
	endif
	
	DoWindow /K $gName
	Display /K=1/W=(0,0,0,0) ISIH as gTitle
	DoWindow /C $gName
	
	SetCascadeXY(gName)
	
	ModifyGraph standoff=0, rgb=(0,0,0), mode=5, hbFill=2
	Label bottom xl
	Label left isihY
	SetAxis/A
	
	Print "\rIntervals stored in wave U_INTVLS"
	
	return wName
	
End // SpikeISIH

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRateCall()
	String gName, vlist = "", df = SpikeDF()
	
	if (SpikeCheckRasterWaves() == -1)
		return -1
	endif
	
	String dName = CurrentChanDisplayWave()
	
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	Variable winB = NMNoteVarByKey(xRaster, "Spike Tbgn")
	Variable winE = NMNoteVarByKey(xRaster, "Spike Tend")
	
	if (numtype(winB) > 0)
		winB = -inf
	endif
	
	if (numtype(winE) > 0)
		winE = inf
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
	
	if ((WaveExists($xRaster) == 0) || (WaveExists($yRaster) == 0))
		return ""
	endif
	
	if (numtype(winB*winE) > 0)
		return ""
	endif
	
	Variable icnt, npnts, wnum
	String xl, yl
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable overWrite = NMOverWrite()
	
	String wPrefix = StrVarOrDefault("WavePrefix", "")
	String wName = NextWaveName(xRaster + "_Rate", -1, overWrite)
	String gPrefix = xRaster + "_" + NMFolderPrefix("") + "Rate"
	String gName = NextGraphName(gPrefix, -1, overWrite)
	String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(CurrentChan) + " : " + wName
	
	Wave xr = $xRaster
	Wave yr = $yRaster
	
	WaveStats /Q yr
	
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
	Display /K=1/W=(0,0,0,0) $wName as gTitle
	DoWindow /C $gName
	SetCascadeXY(gName)
	ModifyGraph standoff=0, rgb=(65280,0,0), mode=4, marker=19
	Label bottom xl
	Label left yl
	
	WaveStats /Q $wName
	
	SetAxis left 0, V_max
	
	NMNoteType(wName, "Spike Rate", xl, yl, "Func:SpikeRate")
	
	Note $wName, "Rate Tbgn:" + num2str(winB) + ";Rate Tend:" + num2str(winE) + ";"
	Note $wName, "Rate xRaster:" + xRaster + ";Rate yRaster:" + yRaster + ";"
	
	return wName

End // SpikeRate

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike result waves/table functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRepsCount(yRaster)
	String yRaster
	
	if (WaveExists($yRaster) == 0)
		return Nan
	endif
	
	Variable icnt, jcnt, rcnt
	
	Variable NumWaves = NumVarOrDefault("NumWaves", 0)
	
	Wave yWave = $yRaster
	
	for (icnt = 0; icnt < NumWaves; icnt += 1)
		for (jcnt = 0; jcnt < numpnts(yWave); jcnt += 1)
			if (yWave[jcnt] == icnt)
				rcnt += 1
				break
			endif
		endfor
	endfor
	
	return rcnt
	
End // SpikeRepsCount

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
	
	String tname = SpikePrefix("") + NMFolderPrefix("") + "Table"
	String wlist = WaveList("SP_R*", ";", WaveListText0())
	
	wlist = RemoveFromList("SP_RasterX", wlist)
	wlist = RemoveFromList("SP_RasterY", wlist)

	if (ItemsInList(wlist) == 0)
		DoAlert 0, "Detected no Spike waves."
		return -1
	endif
	
	tname = NextGraphName(tname, -1, NMOverWrite())
	
	DoWindow /K $tname
	Edit /K=1/W=(0,0,0,0) as "Spike Waves"
	DoWindow /C $tname
	SetCascadeXY(tname)
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		AppendToTable $StringFromList(icnt, wlist)
	endfor
	
	return 0

End // SpikeTable

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Spike computational functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRaster(thresh, WinB, WinE, xName, yName, wList) // compute spike raster
	Variable thresh // threshold trigger level
	Variable WinB // begin window time
	Variable WinE // end window time
	String xName // output raster x-wave name
	String yName // output raster y-wave name
	String wList // wave list or ("All") current selected waves
	
	String wName, dName, dumstr, xl, yl
	Variable wcnt, ncnt, spkcnt, dimcnt, event, slope
	Variable wnum, plmt, pflag, dtWin, npnts, items
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	
	if (StringMatch(wList, "All") == 1)
		wList = NMChanWaveList(CurrentChan)
	endif
	
	items = ItemsInList(wList)
	
	if (items <= 0)
		return -1
	endif
	
	String wPrefix = StrVarOrDefault("CurrentPrefix", "Wave")
	
	Make /O/N=0 Xtimes=Nan
	Make /O/N=0 $xName=Nan
	Make /O/N=0 $yName=Nan
	
	Wave xWave = $xName
	Wave yWave = $yName
	
	if (numtype(thresh) > 0)
		return -1 // not allowed
	endif
	
	plmt = items - 1
	
	dName = "DumWave"
	
	NMProgressStr("Computing Spike Raster...")
	
	for (wcnt = 0; wcnt < items; wcnt += 1)
	
		if (plmt > 0)
	
			pflag = CallProgress(wcnt/plmt)
			
			if (pflag == 1)
				spkcnt = -1
				break
			endif
		
		endif
	
		wName = StringFromList(wcnt, wList)
		wnum = ChanWaveNum(wName)
		
		if (exists(wName) == 0)
			continue // wave does not exist
		endif
		
		ChanWaveMake(CurrentChan, wName, dName)
		
		Findlevels /Q/R=(WinB,WinE)/D=Xtimes $dName, thresh
		
		ncnt = numpnts(xWave)
		
		if (V_LevelsFound == 0)
			Redimension /N=(ncnt+1) xWave, yWave
			xWave[ncnt] = Nan
			yWave[ncnt] = wnum
			dimcnt += 1
			continue
		endif
		
		Redimension /N=(dimcnt+V_LevelsFound) xWave, yWave
		
		dtWin = deltax($dName)
		
		for (ncnt = 0; ncnt < V_LevelsFound; ncnt += 1)
		
			event = Xtimes[ncnt]
	
			dumstr = FindSlope(event - dtWin, event + dtWin, dName)
			slope = str2num(StringByKey("m", dumstr, "="))
		
			if (slope > 0)
				xWave[dimcnt] = event
				yWave[dimcnt] = wnum
				spkcnt += 1
				dimcnt += 1
			endif
		
		endfor
		
		dimcnt += 1 // add extra row for Nan's
		
		Redimension /N=(dimcnt) xWave, yWave
		
		xWave[dimcnt] = Nan
		yWave[dimcnt] = Nan
		
	endfor
	
	winB = GetXStats("minleftx", wList)
	winE = GetXStats("maxrightx", wList)
	
	xl = "Spike Event"
	yl = NMNoteLabel("x", wList, "msec")
	
	NMNoteType(xName, "Spike RasterX", xl, yl, "Func:SpikeRaster")
	
	Note $xName, "Spike Thresh:" + num2str(thresh) + ";Spike Tbgn:" + num2str(WinB) + ";Spike Tend:" + num2str(WinE) + ";"
	Note $xName, "Spike Prefix:" + wPrefix
	Note $xName, "Wave List:" + ChangeListSep(wList, ",")
	
	xl = "Spike Event"
	yl = wPrefix + "#"
	
	NMNoteType(yName, "Spike RasterY", xl, yl, "Func:SpikeRaster")
	
	Note $yName, "Spike Thresh:" + num2str(thresh) + ";Spike Tbgn:" + num2str(WinB) + ";Spike Tend:" + num2str(WinE) + ";"
	Note $xName, "Spike Prefix:" + wPrefix
	Note $yName, "Wave List:" + ChangeListSep(wList, ",")
	
	KillWaves /Z Xtimes, DumWave
	
	return spkcnt // return spike count

End // SpikeRaster

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TrigAvg(xRaster, yRaster, avgCh, avgWin, saveWin) // compute average around RasterX spike times (results saved in SP_TrgAvg)
	String xRaster // rasterX wave name
	String yRaster // rasterY wave name
	Variable avgCh // channel to compute average
	Variable avgWin // time window to compute average (ms)
	Variable saveWin // save wave window flag (windows saved to SP_TrgWin_A0...)
	
	Variable event, spkcnt, npnts, dx, t, pnt1, pnt2, icnt, jcnt
	String wName, sName, wList, prefix, xl, yl, seq = ""
	
	if ((WaveExists($xRaster) == 0) || (WaveExists($yRaster) == 0))
		return ""
	endif
	
	if (numpnts($xRaster) != numpnts($yRaster))
		DoAlert 0, "Abort: rasterX and rasterY waves are of different size."
		return "" // x-y waves are of different size
	endif
	
	if (avgWin == 0)
		return "" // not allowed
	endif
	
	xl = ChanLabel(avgCh, "x", "")
	yl = ChanLabel(avgCh, "y", "")
	
	Wave rstrx = $xRaster
	Wave rstry = $yRaster
	
	npnts = numpnts(rstrx)
	
	for (icnt = strlen(xRaster) - 1; icnt > 0; icnt -=1)
		if (StringMatch(xRaster[icnt], "_") == 1)
			seq = xRaster[icnt+2,inf]
			break
		endif
	endfor
	
	prefix = "SP_Rstr" + seq + "_" + ChanNum2Char(avgCh)
	
	if (saveWin == 1)
	
		DoAlert 1, "Warning: this function will create " + num2str(npnts) + "  waves beginning with \"" + prefix +  "\" in the current directory. Do you want to continue?"
		
		if (V_flag != 1)
			return ""
		endif
	
	endif
	
	wList = WaveList(prefix + "*", ";", WaveListText0())
	
	if (ItemsInList(wList) > 0) // clean up
		for (spkcnt = 0; spkcnt < ItemsInList(wList); spkcnt += 1)
			Execute /Z "KillWaves /Z " + StringFromList(spkcnt, wList)
		endfor
	endif
	
	for (spkcnt = 0; spkcnt < numpnts(rstrx); spkcnt += 1)
	
		event = rstrx[spkcnt]
		
		if (numtype(event) > 0)
			continue
		endif
		
		wName = ChanWaveName(avgCh, rstry[spkcnt])
		
		if (saveWin == 1)
			sName = GetWaveName(prefix, -1, jcnt)
		else
			sName = "AvgTemp"
		endif
		
		if (exists(wName) == 0)
			continue // wave does not exist
		endif
		
		dx = deltax($wName)
		npnts = (AvgWin / dx) + 1

		Make /O/N=(npnts) $sName = Nan
		Setscale /P x (avgwin/-2), deltax($wName), $sName
		
		Wave DatWin = $wName
		Wave TrgWin = $sName
		
		for (t = event-(avgWin/2); t <= event+(avgWin/2); t += dx)
		
			pnt1 = x2pnt(DatWin, t)
			pnt2 = x2pnt(TrgWin, t-event)
			
			if ((pnt1 >= 0) && (pnt1 < numpnts(DatWin)))
				if ((pnt2 >= 0) && (pnt2 < numpnts(TrgWin)))
					TrgWin[pnt2] = DatWin[pnt1]
				endif
			endif
			
		endfor
		
		if (jcnt == 0)
			Duplicate /O $sName SP_TrgAvg
		else
			SP_TrgAvg += TrgWin
		endif
		
		if (saveWin == 1)
			
			NMNoteType(sName, "Spike Event", xl, yl, "Func:TrigAvg")
			
			Note $sname, "TrigAvg Wave:" + wName
			Note $sname, "TrigAvg Time:" + Num2StrLong(event, 3)
			Note $sname, "TrigAvg Chan:" + num2str(avgCh) + ";TrigAvg Win:" + num2str(avgWin) + ";"
			Note $sname, "TrigAvg xRaster:" + xRaster
			Note $sname, "TrigAvg yRaster:" + yRaster
			
		endif
		
		jcnt += 1
		
	endfor
	
	SP_TrgAvg /= spkcnt
	
	NMNoteType("SP_TrgAvg", "Spike Avg", xl, yl, "Func:TrigAvg")
	
	Note SP_TrgAvg, "TrigAvg Chan:" + num2str(avgCh) + ";TrigAvg Win:" + num2str(avgWin) + ";"
	Note $sname, "TrigAvg xRaster:" + xRaster
	Note $sname, "TrigAvg yRaster:" + yRaster
	
	KillWaves /Z AvgTemp
	
	return "SP_Rstr" + seq

End // TrigAvg

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
	
	HZD*=1000

End // Hazard

//****************************************************************
//****************************************************************
//****************************************************************

