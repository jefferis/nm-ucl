#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Statistical Analysis Tab
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 22 June 2007
//
//	NM tab entry "Stats"
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsPrefix(objName) // tab prefix identifier
	String objName
	
	return "ST_" + objName
	
End // StatsPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsDF() // package full-path folder name

	return PackDF("Stats")
	
End // StatsDF

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats(enable)
	Variable enable // (0) disable (1) enable tab

	if (enable == 1)
		CheckPackage("Stats", 1) // declare globals if necessary
		StatsChanCheck()
		StatsDragCheck() // display drag waves
		StatsAmpBegin()
		MakeStats(0) // make controls if necessary
		StatsChanControlsEnableAll(1)
		ChanGraphUpdate(-1, 1)
		NMAutoStats() // compute Stats
	else
		StatsChanControlsEnableAll(0)
		ChanGraphUpdate(-1, 1)
	endif
	
	StatsDisplay(-1, enable) // display/remove stat waves on active channel graph
	
End // Stats

//****************************************************************
//****************************************************************
//****************************************************************

Function KillStats(what)
	String what
	String df = StatsDF()
	
	strswitch(what)
	
		case "waves":
			break
			
		case "folder":
			if (DataFolderExists(df) == 1)
				KillDataFolder $df
			endif 
			break
			
	endswitch
	
End // KillStats

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsConfigEdit() // called from NM_Configurations

	StatsTableParams("inputs")

End // StatsConfigEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStats()
	
	Variable nwin = 10 // number of measurement windows - may be increased
	
	String df = StatsDF()
	
	if (DataFolderExists(df) == 0)
		return -1
	endif
	
	// waves to store all the stat window input/output parameters

	CheckNMtwave(df+"AmpSlct", nwin, "")
	CheckNMwave(df+"AmpB", nwin, 0)
	CheckNMwave(df+"AmpE", nwin, 0)
	CheckNMwave(df+"AmpY", nwin, Nan)
	CheckNMwave(df+"AmpX", nwin, Nan)
	
	CheckNMwave(df+"Bflag", nwin, 0)
	CheckNMtwave(df+"BslnSlct", nwin, "")
	CheckNMwave(df+"BslnB", nwin, 0)
	CheckNMwave(df+"BslnE", nwin, 0)
	CheckNMwave(df+"BslnY", nwin, Nan)
	CheckNMwave(df+"BslnX", nwin, Nan)
	CheckNMwave(df+"BslnSubt", nwin, 0)
	CheckNMwave(df+"BslnRflct", nwin, Nan)
	
	CheckNMwave(df+"Rflag", nwin, 0)
	CheckNMwave(df+"RiseBP", nwin, 10)
	CheckNMwave(df+"RiseEP", nwin, 90)
	CheckNMwave(df+"RiseBX", nwin, Nan)
	CheckNMwave(df+"RiseEX", nwin, Nan)
	CheckNMwave(df+"RiseTm", nwin, Nan)
	
	CheckNMwave(df+"Dflag", nwin, 0)
	CheckNMwave(df+"DcayP", nwin, 37)
	CheckNMwave(df+"DcayX", nwin, Nan)
	CheckNMwave(df+"DcayT", nwin, Nan)
	
	CheckNMwave(df+"dtFlag", nwin, 0)
	CheckNMwave(df+"SmthNum", nwin, 0)
	CheckNMtwave(df+"SmthAlg", nwin, "")
	
	CheckNMwave(df+"WinSelect", nwin, 0)
	CheckNMwave(df+"ChanSelect", nwin, 0)
	
	CheckNMtwave(df+"OffsetW", nwin, "")
	
	// variables for Stats1 display controls
	
	CheckNMvar(df+"AmpNV", 0) // current window number
	CheckNMvar(df+"AmpBV", 0)
	CheckNMvar(df+"AmpEV", 0)
	CheckNMvar(df+"AmpYV", Nan)
	CheckNMvar(df+"AmpXV", Nan)
	CheckNMvar(df+"BslnYV", Nan)
	CheckNMvar(df+"RiseTV", Nan)
	CheckNMvar(df+"DcayTV", Nan)
	
	// variables for channel graph controls
	
	CheckNMvar(df+"Ft", 0)
	CheckNMvar(df+"SmoothN", 0)
	CheckNMstr(df+"SmoothA", "")
	
	// misc variables
	
	CheckNMvar(df+"TablesOn", 1)
	
	CheckNMstr(df+"AmpColor", "65535,0,0")
	CheckNMstr(df+"BaseColor", "0,39168,0")
	CheckNMstr(df+"RiseColor", "0,0,65535")
	
	// waves for display graphs
	
	CheckNMwave(df+"ST_PntX", 1, Nan)
	CheckNMwave(df+"ST_PntY", 1, Nan)
	CheckNMwave(df+"ST_WinX", 2, Nan)
	CheckNMwave(df+"ST_WinY", 2, Nan)
	CheckNMwave(df+"ST_BslnX", 2, Nan)
	CheckNMwave(df+"ST_BslnY", 2, Nan)
	CheckNMwave(df+"ST_RDX", 3, Nan)
	CheckNMwave(df+"ST_RDY", 3, Nan)
	
	if (numpnts(ST_PntX) > 1) // these are old stat waves, need to redimension
		Redimension /N=1 $(df+"ST_PntX"), $(df+"ST_PntY")
		Redimension /N=2 $(df+"ST_WinX"), $(df+"ST_WinY")
		Redimension /N=2 $(df+"ST_BslnX"), $(df+"ST_BslnY")
		Redimension /N=3 $(df+"ST_RDX"), $(df+"ST_RDY")
	endif
	
	// Stats2 variables
	
	CheckNMstr(df+"ST_2WaveSlct", "")
	CheckNMstr(df+"ST_2StrMatch", "ST_*")
	CheckNMstr(df+"ST_2MatchSlct", "Stats1")
	
	//CheckNMvar(df+"WavSelectOn", 0)
	CheckNMvar(df+"AutoPlot", 1)
	
	CheckNMvar(df+"ST_2AVG", Nan)
	CheckNMvar(df+"ST_2SDV", Nan)
	CheckNMvar(df+"ST_2SEM", Nan)
	CheckNMvar(df+"ST_2CNT", Nan)
	
	CheckNMwave(df+"ST_Stats2Wave", 0, 0)
	
	return 0
	
End // CheckStats

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWavesCopy(fromDF, toDF)
	String fromDF // data folder copy from
	String toDF // data folder copy to
	
	String wlist, wlist2, sdf = StatsDF()
	
	fromDF = LastPathColon(fromDF, 1)
	toDF = LastPathColon(toDF, 1)
	
	if (WaveExists($(fromDF+"AmpE")) == 0)
		return -1 // not a Stats folder
	endif
	
	if (DataFolderExists(GetPathName(toDF,1)) == 0)
		return -1 // parent directory doesnt exist
	endif
	
	if (DataFolderExists(toDF) == 0)
		NewDataFolder $LastPathColon(toDF, 0) // make "to" data folder
	endif
	
	wlist = WaveListFolder(sdf, "*", ";", "")
	wlist2 = WaveListFolder(sdf, "ST_*", ";", "")
	
	wlist = RemoveFromList(wlist2, wlist) // remove display waves
	wlist = RemoveFromList("AmpX;BslnX;BslnY;RiseBX;RiseEX;RiseTm;DcayX;DcayT;WinSelect;", wlist)
	
	CopyWavesTo(fromDF, toDF, "", -inf, inf, wlist, 0)

End // StatsWavesCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAutoStats() // compute Stats of currently selected channel/wave
	String wName, sdf = StatsDF()
	
	StatsDisplayClear()
	StatsComputeWin(-1, CurrentChanDisplayWave(), 1)
	StatsDragSetY()
	UpdateStats()
	
End // NMAutoStats

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTableCall()
	String sdf = StatsDF()
	Variable select = NumVarOrDefault(sdf+"StatsTableSelect", 1)
	Prompt select, "", popup "Input Parameter Table;Output Parameter Table;Auto Tables On;Auto Tables Off;"
	
	DoPrompt "Stats Tables", select
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	switch(select)
		case 1:
			NMCmdHistory("StatsEdit", NMCmdStr("inputs", ""))
			return StatsTableParams("inputs")
		case 2:
			NMCmdHistory("StatsEdit", NMCmdStr("outputs", ""))
			return StatsTableParams("outputs")
		case 3:
			NMCmdHistory("StatsTablesOn", NMCmdNum(1, ""))
			return StatsTablesOn(1)
		case 4:
			NMCmdHistory("StatsTablesOn", NMCmdNum(0, ""))
			return StatsTablesOn(0)
	endswitch
	
	SetNMvar(sdf+"StatsTableSelect", select)

End // StatsTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTablesOn(on)
	Variable on // (0) no (1) yes
	
	SetNMVar(StatsDF()+"TablesOn", BinaryCheck(on))
	
End // StatsTablesOn

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTableParams(select)
	String select // ("inputs") input params ("outputs") output params
	
	String tname, title, df = StatsDF()
	
	strswitch(select)
		case "inputs":
			 tname = "ST_InputParams"
			 title = "Stats1 Window Inputs"
			 break
		case "outputs":
			tname = "ST_OutputParams"
			title = "Stats1 Window Outputs"
			break
		default:
			return -1
	endswitch
	
	if (WinType(tname) == 0)
		DoWindow /K $tname
		Edit /K=1/W=(0,0,0,0)
		DoWindow /C $tName
		SetCascadeXY(tName)
		DoWindow /T $tName, title
		Execute "ModifyTable title(Point)= \"Window\""
	else
		DoWindow /F $tname
	endif
	
	strswitch(select)
	
		case "inputs":
		
			AppendToTable $(df+"AmpSlct"), $(df+"AmpB"), $(df+"AmpE")
			AppendToTable $(df+"Bflag"), $(df+"BslnSlct"), $(df+"BslnB"), $(df+"BslnE"), $(df+"BslnSubt"), $(df+"BslnRflct")
			AppendToTable $(df+"Rflag"), $(df+"RiseBP"), $(df+"RiseEP")
			AppendToTable $(df+"Dflag"), $(df+"DcayP")
			AppendToTable $(df+"dtFlag"), $(df+"SmthNum"), $(df+"SmthAlg")
			
			if (WaveExists($(df+"OffsetW")) == 1)
				AppendToTable $(df+"OffsetW")
			endif
			
			SetWindow $tName hook=StatsTableParamsHook
			
			break
			
		case "outputs":
			AppendToTable $(df+"AmpX"), $(df+"AmpY")
			AppendToTable $(df+"BslnX"), $(df+"BslnY")
			AppendToTable $(df+"RiseBX"), $(df+"RiseEX"), $(df+"RiseTm")
			AppendToTable $(df+"DcayX"), $(df+"DcayT")
			break
			
	endswitch
	
	return 0

End // StatsTableParams

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTableParamsHook(infoStr)
	string infoStr
	
	string event = StringByKey("EVENT",infoStr)
	string win = StringByKey("WINDOW",infoStr)
	
	if (StringMatch(win, "ST_InputParams") == 0)
		return 0 // wrong window
	endif

	strswitch(event)
		case "deactivate":
		case "kill":
			//UpdateNM(0)
			NMAutoStats()
			break
	endswitch

End // StatsTableParamsHook
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeStats(force) // create Stats tab controls
	Variable force
	
	Variable x0, y0, xinc, yinc
	String df = StatsDF()
	
	if (IsCurrentNMTab("Stats") == 0)
		return 0
	endif
	
	ControlInfo /W=NMPanel ST_AmpSelect
	
	if ((V_Flag != 0) && (force == 0))
		return 0 // Stats tab controls exist
	endif
	
	if (DataFolderExists(StatsDF()) == 0)
		return 0 // stats has not been initialized yet
	endif
	
	DoWindow /F NMPanel
	
	x0 = 35
	xinc = 160
	y0 = 215
	yinc = 25
	
	GroupBox ST_Group, title="Stats1", pos={x0-15,y0-30}, size={260,240}, win=NMPanel
	
	PopupMenu ST_AmpSelect, pos={x0+85,y0-5}, bodywidth=135
	PopupMenu ST_AmpSelect, value =StatsAmpList(), proc=StatsPopup, win=NMPanel
	
	PopupMenu ST_WinSelect, pos={x0+180,y0-5}, bodywidth=85
	PopupMenu ST_WinSelect, value = StatsWinList(0), proc=StatsPopup, win=NMPanel
	
	SetVariable ST_AmpBSet, title="t_bgn", pos={x0+18,y0+1*yinc}, size={90,50}, limits={-inf,inf,1}
	SetVariable ST_AmpBSet, value=$(df+"AmpBV"), format="%.2f", proc=StatsSetVariable, win=NMPanel
	
	SetVariable ST_AmpESet, title="t_end", pos={x0+18,y0+2*yinc}, size={90,50}, limits={-inf,inf,1}
	SetVariable ST_AmpESet, value=$(df+"AmpEV"), format="%.2f", proc=StatsSetVariable, win=NMPanel
	
	SetVariable ST_AmpYSet, title="y =", pos={x0+xinc,y0+1*yinc}, size={80,50}, limits={-inf,inf,0}
	SetVariable ST_AmpYSet, value=$(df+"AmpYV"), format="%.3f", frame=0, proc=StatsSetVariable, win=NMPanel
	
	SetVariable ST_AmpXSet, title="t =", pos={x0+xinc,y0+2*yinc}, size={80,50}, limits={-inf,inf,0}
	SetVariable ST_AmpXSet, value=$(df+"AmpXV"), format="%.3f", frame=0, win=NMPanel
	
	Checkbox ST_Baseline, title="Baseline", pos={x0,y0+3*yinc}, size={200,50}, value=0, proc=StatsCheckBox, win=NMPanel
	SetVariable ST_BslnSet, title="b =", pos={x0+xinc,y0+3*yinc}, size={80,20}, limits={-inf,inf,0}
	SetVariable ST_BslnSet, value=$(df+"BslnYV"), format="%.3f", frame=0, win=NMPanel
	
	Checkbox ST_RiseTime, title="Rise Time", pos={x0,y0+4*yinc}, size={200,50}, value=0, proc=StatsCheckBox, win=NMPanel
	SetVariable ST_RiseTSet, title="t =", pos={x0+xinc,y0+4*yinc}, size={80,50}, limits={0,inf,0}
	SetVariable ST_RiseTSet, value=$(df+"RiseTV"), format="%.3f", frame=0, win=NMPanel
	
	Checkbox ST_DecayTime, title="Decay Time", pos={x0,y0+5*yinc}, size={200,50}, value=0, proc=StatsCheckBox, win=NMPanel
	SetVariable ST_DcayTSet, title="t =", pos={x0+xinc,y0+5*yinc}, size={80,50}, limits={0,inf,0}
	SetVariable ST_DcayTSet, limits={0,inf,0}, value=$(df+"DcayTV"), format="%.3f", frame=0, win=NMPanel
	
	Checkbox ST_Offset, title="Offset Time", pos={x0,y0+6*yinc}, size={200,50}, value=0, proc=StatsCheckBox, win=NMPanel
	
	y0 += 3
	
	Button ST_Edit, title="Tables", pos={x0+35,y0+7*yinc}, size={70,20}, proc=StatsButton, win=NMPanel
	
	Button ST_AllWaves, title="All Waves", pos={x0+120,y0+7*yinc}, size={80,20}, proc=StatsButton, win=NMPanel
	
	xinc = 135
	y0 = 475
	yinc = 25
	
	GroupBox ST_2Group, title="Stats2", pos={x0-15,y0-30}, size={260,140}, win=NMPanel
	
	PopupMenu ST_2WaveList, value="Select Wave", bodywidth=230, pos={x0+180,y0-5}, proc=StatsPopup, win=NMPanel
	
	SetVariable ST_2AvgSet, title="AVG: ", pos={x0,y0+1*yinc}, size={100,50}
	SetVariable ST_2AvgSet, value=$(df+"ST_2AVG"), limits={-inf,inf,0}, format="%.3f", frame=0, win=NMPanel
	
	SetVariable ST_2CNTSet, title="NUM: ", pos={x0+xinc,y0+1*yinc}, size={100,50}
	SetVariable ST_2CNTSet, value=$(df+"ST_2CNT"), limits={0,inf,0}, format="%.0f", frame=0, win=NMPanel
	
	SetVariable ST_2SDVSet, title="SDV: ", pos={x0,y0+2*yinc}, size={100,50}
	SetVariable ST_2SDVSet, value=$(df+"ST_2SDV"), limits={0,inf,0}, format="%.3f", frame=0, win=NMPanel
	
	SetVariable ST_2SEMSet, title="SEM: ", pos={x0+xinc,y0+2*yinc}, size={100,50}
	SetVariable ST_2SEMSet, value=$(df+"ST_2SEM"), limits={-inf,inf,0}, format="%.3f", frame=0, win=NMPanel
	
	y0 += 3
	
	PopupMenu ST_2FXN, pos={x0+40,y0+3*yinc}, bodywidth = 90
	PopupMenu ST_2FXN, value="Function...;---;Plot;Edit;Histogram;Sort Wave;Stability;Delete NANs;Auto Plot On;Auto Plot Off;---;Table;Print Names;Kill Waves;", proc=StatsPopup, win=NMPanel
	
	Button ST_2Save, title="Save", pos={135,y0+3*yinc}, size={50,20}, proc=StatsButton, win=NMPanel
	Button ST_2AllWaves, title="All Waves", pos={195,y0+3*yinc}, size={70,20}, proc=StatsButton, win=NMPanel

End // MakeStats

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateStats()

	if (IsCurrentNMTab("Stats") == 1)
		UpdateStats1()
		UpdateStats2()
	endif

End // UpdateStats

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateStats1() // update/display current window result values

	Variable off, offset, v1, v2, modeNum
	String ttl, select, df = StatsDF(), cdf = ChanDF(-1)

	if ((DataFolderExists(df) == 0) || (IsCurrentNMTab("Stats") == 0))
		return 0
	endif

	Variable CurrentChan = NMCurrentChan()
	
	NVAR AmpNV = $(df+"AmpNV")
	NVAR AmpBV = $(df+"AmpBV"); NVAR AmpEV = $(df+"AmpEV")
	NVAR AmpYV = $(df+"AmpYV"); NVAR AmpXV = $(df+"AmpXV")
	NVAR BslnYV = $(df+"BslnYV"); NVAR RiseTV = $(df+"RiseTV")
	NVAR DcayTV = $(df+"DcayTV");
	
	Wave AmpB = $(df+"AmpB"); Wave AmpE = $(df+"AmpE")
	Wave AmpY = $(df+"AmpY"); Wave AmpX = $(df+"AmpX")
	
	Wave /T BslnSlct = $(df+"BslnSlct")
	Wave Bflag = $(df+"Bflag"); Wave BslnY = $(df+"BslnY")
	Wave BslnB = $(df+"BslnB"); Wave BslnE = $(df+"BslnE")
	
	Wave Rflag = $(df+"Rflag"); Wave RiseTm = $(df+"RiseTm")
	Wave RiseBP = $(df+"RiseBP"); Wave RiseEP = $(df+"RiseEP")
	
	Wave Dflag = $(df+"Dflag");
	Wave DcayP = $(df+"DcayP"); Wave DcayT = $(df+"DcayT")
	
	Wave ST_PntX = $(df+"ST_PntX"); Wave ST_PntY = $(df+"ST_PntY")
	Wave ST_WinX = $(df+"ST_WinX"); Wave ST_WinY = $(df+"ST_WinY")
	Wave ST_BslnX = $(df+"ST_BslnX"); Wave ST_BslnY = $(df+"ST_BslnY")
	Wave ST_RDX = $(df+"ST_RDX"); Wave ST_RDY = $(df+"ST_RDY")
	
	select = StatsAmpSelectGet(AmpNV)
	
	if (StringMatch(select, "Off") == 1)
		off = 1
	endif
	
	AmpBV = AmpB[AmpNV]
	AmpEV = AmpE[AmpNV]
	AmpYV = AmpY[AmpNV]
	AmpXV = AmpX[AmpNV]
	BslnYV = BslnY[AmpNV]
	RiseTV = RiseTm[AmpNV]
	DcayTV = DcayT[AmpNV]
	
	if (Bflag[AmpNV] == 1)
		sprintf ttl, "Bsln (" + BslnSlct[AmpNV] + ": %.1f - %.1f)", BslnB[AmpNV], BslnE[AmpNV]
		Checkbox ST_Baseline, disable=0, value=1, win=NMPanel, title= ttl
		SetVariable ST_BslnSet, disable=0, win=NMPanel
	else
		Checkbox ST_Baseline, disable=0, value=0, title="Baseline", win=NMPanel
		SetVariable ST_BslnSet, disable=1, win=NMPanel
	endif
	
	if (Rflag[AmpNV] == 1)
	
		strswitch(select)
			case "FWHM+":
			case "FWHM-":
				Checkbox ST_RiseTime, disable=0, value=1, win=NMPanel, title="FWHM (" + num2str(50) + " - " + num2str(50) + "%)"
				break
			default:
				Checkbox ST_RiseTime, disable=0, value=1, win=NMPanel, title="Rise Time (" + num2str(RiseBP[AmpNV]) + " - " + num2str(RiseEP[AmpNV]) + "%)"
		endswitch
		
		SetVariable ST_RiseTSet, disable=0, win=NMPanel
		
	else
		Checkbox ST_RiseTime, disable=0, value =0, title="Rise Time", win=NMPanel
		SetVariable ST_RiseTSet, disable=1, win=NMPanel
	endif
	
	if (Dflag[AmpNV] == 1)
		Checkbox ST_DecayTime, disable=0, value=1, win=NMPanel, title="Decay Time (" + num2str(DcayP[AmpNV]) + "%)"
		SetVariable ST_DcayTSet, disable=0, win=NMPanel
	else
		Checkbox ST_DecayTime, disable=0, value=0, title="Decay Time", win=NMPanel
		SetVariable ST_DcayTSet, disable=1, win=NMPanel
	endif
	
	offset = StatsOffsetValue(AmpNV)
	
	if (offset == -1)
		Checkbox ST_Offset, disable=0, value=0, win=NMPanel, title="Offset Time"
	else
		offset = max(0,offset)
		Checkbox ST_Offset, disable=0, value=1, win=NMPanel, title="Offset Time = " + num2str(offset) + " ms"
	endif
	
	SetVariable ST_AmpYSet, title="y =", frame=0, disable=0, win=NMPanel
	SetVariable ST_AmpXSet, title="t =", disable=0, win=NMPanel
		
	strswitch(select)
		case "Max":
		case "Min":
			break
		case "Avg":
		case "SDev":
		case "Var":
		case "RMS":
		case "Area":
		case "Sum":
			SetVariable ST_AmpXSet, disable=1, win=NMPanel
			break
		case "Slope":
		case "RTSlope+":
		case "RTSlope-":
			SetVariable ST_AmpYSet, title = "m =", win=NMPanel
			SetVariable ST_AmpXSet, title = "b =", win=NMPanel
			break
		case "Level":
		case "Level+":
		case "Level-":
			SetVariable ST_AmpYSet, frame=1, win=NMPanel
			break
		case "Off":
			SetVariable ST_AmpYSet, disable=1, win=NMPanel
			SetVariable ST_AmpXSet, disable=1, win=NMPanel
	endswitch
	
	modenum = 1 + WhichListItemLax(select, StatsAmpList(), ";")
	
	PopupMenu ST_AmpSelect, mode = modeNum, win=NMPanel // reset menu display mode
	
	PopupMenu ST_WinSelect, mode=(AmpNV+1), win=NMPanel
	
	DoWindow /F NMpanel // brings back to front for more input

End // UpdateStats1

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateStats2()
	Variable md
	String wList

	String df = StatsDF()
	
	if ((DataFolderExists(df) == 0) || (IsCurrentNMTab("Stats") == 0))
		return 0
	endif
	
	//Variable wSelect = NumVarOrDefault(df+"WavSelectOn", 0)
	
	String ST_2WaveSlct = StrVarOrDefault(df+"ST_2WaveSlct", "")
	
	wlist = Stats2WSelectList("")
	
	if ((strlen(ST_2WaveSlct) == 0) || (WhichListItem(ST_2WaveSlct, wlist) < 0))
		md = -1
		SetNMstr(df+"ST_2WaveSlct", "")
	else
		md = WhichListItem(ST_2WaveSlct, wlist)
	endif
	
	PopupMenu ST_2WaveList, win=NMPanel, value = "Change This List;---;" + Stats2WSelectList("")
	PopupMenu ST_2WaveList, win=NMPanel, mode=(md+3)
	
	//titleStr = "Wave Select Filter : Off"
	
	//if (wSelect == 1)
	//	titleStr = "Wave Select Filter : " + NMWaveSelectGet()
	//endif
	
	//Checkbox ST_2WaveSelect, title=titleStr, value=wSelect, win=NMPanel
	
	PopupMenu ST_2FXN, mode=1, win=NMpanel
	
	Stats2Compute()
	
	DoWindow /F NMpanel // brings back to front for more input

End // UpdateStats2

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsButton(ctrlName) : ButtonControl
	String ctrlName
	
	StatsCall(ctrlName[3,inf], "")
	
End // StatsButton

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	StatsCall(ctrlName[3,inf], num2str(checked))
	
End // StatsCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr 
	
	StatsCall(ctrlName[3,inf], popStr)

End // StatsPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr 
	
	strswitch(popStr)
		case "Stats Drag":
			StatsDragToggle()
			break
		case "Stats Labels":
			StatsLabelsToggle()
			break
		default:
			ChanPopup(ctrlName, popNum, popStr)
	endswitch

End // StatsChanPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	StatsCall(ctrlName[3,inf], varStr)
	
End // StatsSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsSetSmooth(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	StatsCall("SmthNSet", varStr)
	
End // StatsSetSmooth

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsCall(fxn, select)
	String fxn, select
	
	Variable snum = str2num(select)
	
	strswitch(fxn)
	
		case "WinSelect":
		case "Win Select":
			snum = str2num(select[3,inf])
			return StatsWinSelectCall(snum)
			
		case "AmpSelect":
		case "Amp Select":
			return StatsWinCall(Nan, Nan, select)
			
		case "AmpBSet":
			StatsWinCall(snum, Nan, "")
			break
			
		case "AmpESet":
			StatsWinCall(Nan, snum, "")
			break
			
		case "AmpYSet":
			StatsLevelCall(snum)
			break
			
		case "SmthNSet":
			StatsSmoothCall(snum, "old")
			break
			
		case "SmthASet":
			StatsSmoothCall(-1, select)
			break
	
		case "Baseline":
			return StatsBslnCall(snum)
			
		case "RiseTime":
		case "Rise Time":
			return StatsRiseTimeCall(snum)
			
		case "DecayTime":
		case "Decay Time":
			return StatsDecayTimeCall(snum)
			
		case "Ft":
		case "dtFxn":
			return StatsFuncCall(snum)
			
		case "Display":
		case "Label":
			return 0
	
		case "Offset":
			return StatsOffsetCall(snum)
			
		case "Edit":
		case "Table":
			return StatsTableCall()
			
		case "AllWaves":
		case "All Waves":
			return StatsAllWavesCall()
			
		case "2WaveList":
			Stats2WSelectCall(select)
			UpdateStats2()
			return 0
			
		case "2FXN":
			Stats2Call(select)
			UpdateStats2()
			return 0
			
	endswitch
	
	Stats2Call(fxn)
	
	//if (StringMatch(fxn[0,5], "DragOn") == 1)
	//	return StatsDragCall(snum)
	//endif
	
End // StatsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2Call(fxn)
	String fxn
	
	strswitch(fxn)
	
		case "2Save":
		case "Save":
			return Stats2SaveCall()
			
		case "2AllWaves":
		case "AllWaves":
			return Stats2AllCall()
	
		case "Plot":
			return StatsPlotCall()
			
		case "Auto Plot":
			StatsPlotAutoCall()
			return ""
			
		case "Auto Plot On":
			StatsPlotAuto(1)
			return ""
			
		case "Auto Plot Off":
			StatsPlotAuto(0)
			return ""
			
		case "Edit":
			return StatsEditCall()
			
		case "Table":
			StatsWavesEditCall()
			return " "
			
		case "Histogram":
			return StatsHistoCall()
			
		case "Sort Wave":
			return StatsSortCall()
			
		case "Stability":
		case "Stationarity":
			return StatsStabilityCall()
			
		case "Delete NANs":
			return StatsDeleteNANsCall()
			
		case "Kill Waves":
			return StatsWavesKillCall()
			
		case "Print Names":
			return StatsPrintNamesCall()
			
		default:
			UpdateStats2()
			
	endswitch
	
	return ""

End // Stats2Call

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTimeStamp(df) // place time stamp on AmpSlct
	String df
	
	Note /K $(df+"AmpSlct")
	Note $(df+"AmpSlct"), "Stats Date:" + date()
	Note $(df+"AmpSlct"), "Stats Time:" + time()

End // StatsTimeStamp

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTimeStampCompare(df1, df2)
	String df1, df2
	Variable ok
	
	df1 = LastPathColon(df1, 1)
	df2 = LastPathColon(df2, 1)
	
	String d1 = NMNoteStrByKey(df1+"AmpSlct", "Stats Date")
	String d2 = NMNoteStrByKey(df2+"AmpSlct", "Stats Date")
	String t1 = NMNoteStrByKey(df1+"AmpSlct", "Stats Time")
	String t2 = NMNoteStrByKey(df2+"AmpSlct", "Stats Time")
	
	if ((strlen(d1) == 0) || (strlen(t1) == 0))
		StatsTimeStamp(df1)
		ok = 1
		//return -1 // time stamp doesnt exist
	endif
	
	if ((strlen(d2) == 0) || (strlen(t2) == 0))
		StatsTimeStamp(df2)
		ok = 1
		//return -1 // time stamp doesnt exist
	endif
	
	if (ok == 1)
		return 1
	endif
	
	if ((StringMatch(d1,d2) == 1) && (StringMatch(t1,t2) == 1))
		return 1 // yes, equal
	endif
	
	return 0 // no, not equal

End // StatsTimeStampCompare

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanCall(chan)
	Variable chan
	String vlist = ""
	
	Variable win = NumVarOrDefault(StatsDF()+"AmpNV", 0)
	
	vlist = NMCmdNum(win, vlist)
	vlist = NMCmdNum(chan, vlist)
	NMCmdHistory("StatsChan", vlist)
	
	return StatsChan(win, chan)
	
End // StatsChanCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChan(win, chan)
	Variable win, chan
	
	String df = StatsDF()
	String wname = df + "ChanSelect"
	
	CheckNMwave(df+"ChanSelect", 10, NMCurrentChan())
	
	if ((WaveExists($wname) == 0) || (numtype(chan) > 0))
		return -1
	endif
	
	if ((win < 0) || (win >= numpnts($wname)))
		return -1
	endif
	
	//SetNMwave(wname, win, chan)
	Wave wtemp = $wname
	wtemp = chan // for now, only allow one channel to be selected
	
	NMAutoStats()
	StatsTimeStamp(df)
	
	return 0

End // StatsChan

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanSelect(win)
	Variable win
	
	Variable chan = NMCurrentChan()
	
	String sdf = StatsDF()
	String wname = sdf + "ChanSelect"
	
	if (WaveExists($wname) == 0)
		return chan
	endif
	
	if (win < 0)
		win = NumVarOrDefault(sdf+"AmpNV", 0)
	endif
	
	Wave wtemp = $wname
	
	return wtemp[0] // for now, return only first channel
	
	if ((win >= 0) && (win < numpnts(wtemp)))
		return wtemp[win]
	endif
	
	return chan

End // StatsChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanCheck() // check to see if current channel has changed

	String sdf = StatsDF()
	Variable chan = NMCurrentChan()
	
	Wave chanSelect = $(sdf + "ChanSelect")

	if (ChanSelect[0] != chan)
		StatsChanCall(chan)
	endif
	
End // StatsChanCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinSelectCall(win)
	Variable win
	
	NMCmdHistory("StatsWinSelect", NMCmdNum(win, ""))
	
	return StatsWinSelect(win)
	
End // StatsWinSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinSelect(win)
	Variable win
	
	String sdf = StatsDF()
	String wname = sdf + "AmpB"
	
	Variable CurrentChan = NMCurrentChan()
	Variable CurrentWave = NMCurrentWave()
	Variable ampnv = NumVarOrDefault(sdf+"AmpNV", 0)
	
	String StatWaveName = CurrentWaveName() // source wave name
	
	if ((win == ampnv) || (win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	SetNMvar(sdf+"AmpNV", win)
	StatsAmpInit(win)
	StatsChanControlsUpdate(-1, -1, 1)
	ChanGraphUpdate(-1, 1)
	NMAutoStats()
	
	return 0

End // StatsWinSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinCall(tbgn, tend, ampStr)
	Variable tbgn, tend
	String ampStr
	
	Variable rx, lx
	String vlist = "", df = StatsDF()
	
	Variable win = NumVarOrDefault(df+"AmpNV", 0)
	
	Wave AmpB = $(df+"AmpB")
	Wave AmpE = $(df+"AmpE")
	
	Wave /T AmpSlct = $(df+"AmpSlct")
	
	if ((numtype(tbgn) == 0) && (numtype(tend) == 2))
	
		rx = rightx($ChanDisplayWave(-1))
	
		if (tbgn > AmpE[win])
			tend = tbgn + abs(AmpE[win] - AmpB[win])
		endif
		
		if (tend > rx)
			tend = rx
		endif
		
	endif
	
	if ((numtype(tbgn) == 2) && (numtype(tend) == 0))
	
		lx = leftx($ChanDisplayWave(-1))
	
		if (tend < AmpB[win])
			tbgn = tend - abs(AmpE[win] - AmpB[win])
		endif
		
		if (tbgn < lx)
			tbgn = lx
		endif
		
	endif
	
	if (numtype(tbgn) == 2)
		tbgn = AmpB[win]
	endif
	
	if (numtype(tend) == 2)
		tend = AmpE[win]
	endif
	
	if (strlen(ampStr) == 0)
		ampStr = AmpSlct[win]
	endif
	
	vlist = NMCmdNum(win, vlist)
	vlist = NMCmdNum(tbgn, vlist)
	vlist = NMCmdNum(tend, vlist)
	vlist = NMCmdStr(ampStr, vlist)
	NMCmdHistory("StatsWin", vlist)
	
	return StatsWin(win, tbgn, tend, ampStr)

End // StatsWinCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWin(win, tbgn, tend, ampStr)
	Variable win, tbgn, tend
	String ampStr
	
	String df = StatsDF()
	
	if (WhichListItemLax(ampStr, StatsAmpList(), ";") == -1)
		return -1
	endif
	
	if (numtype(tbgn*tend) > 0)
		//return -1
	endif
	
	if ((win < 0) || (win > numpnts($(df+"AmpB"))))
		return -1
	endif
	
	SetNMwave(df+"AmpB", win, tbgn)
	SetNMwave(df+"AmpE", win, tend)
	SetNMtwave(df+"AmpSlct", win, ampStr)
	
	strswitch(ampStr)
		case "RTSlope+":
		case "RTSlope-":
		case "FWHM+":
		case "FWHM-":
			SetNMwave(df+"Rflag", win, 1) // turn on rise-time computation
			SetNMwave(df+"Bflag", win, 1) // turn on baseline computation
			break
	endswitch
	
	StatsBslnReflectUpdate(win) // recompute reflected baseline if on
	
	NMAutoStats()
	StatsTimeStamp(df)
	
	return 0

End // StatsWin

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWinList(kind)
	Variable kind // (0) all available (1) not off
	
	Variable icnt
	String select, wlist = "", df = StatsDF()
	
	Variable npnts = numpnts($(df+"AmpY"))
	
	for (icnt = 0; icnt < npnts; icnt += 1)
	
		select = StatsAmpSelectGet(icnt)
	
		if (kind == 0)
			wlist = AddListItem("Win"+num2str(icnt), wlist, ";", inf)
		elseif ((strlen(select) > 0) && (StringMatch(select, "Off") == 0))
			wlist = AddListItem("Win"+num2str(icnt), wlist, ";", inf)
		endif
		
	endfor
	
	if (ItemsInList(wlist) == 1)
		//wlist = ""
	endif
	
	return wlist
	
End // StatsWinList

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinCount()
	Variable count, icnt
	
	return ItemsInList(StatsWinList(1))

End // StatsWinCount

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinNum(wName) // return the amplitude/window number, given wave name
	String wName
	
	Variable win = str2num(wName[strlen(wName)-4,strlen(wName)-4])
	
	if ((win >= 0) && (win < 10))
		return win
	else
		return -1
	endif
	
End // StatsWinNum

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinSelectUpdate()
	Variable acnt
	String df = StatsDF()
	
	Wave WinSelect = $(df+"WinSelect")
	
	WinSelect = 0
	
	for (acnt = 0; acnt < NumPnts(WinSelect); acnt += 1)
		if (StringMatch(StatsAmpSelectGet(acnt), "Off") == 0)
			WinSelect[acnt] = 1
		endif
	endfor

End // StatsWinSelectUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLevelCall(level)
	Variable level
	String vlist = ""
	
	Variable win = NumVarOrDefault(StatsDF()+"AmpNV", 0)
	
	vlist = NMCmdNum(win, vlist)
	vlist = NMCmdNum(level, vlist)
	NMCmdHistory("StatsLevel", vlist)
	
	return StatsLevel(win, level)
	
End // StatsLevelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLevel(win, level)
	Variable win, level
	
	String df = StatsDF()
	String wname = df + "AmpY"
	
	if (numtype(level) > 0)
		return -1
	endif
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	SetNMwave(wname, win, level)
	
	NMAutoStats()
	StatsTimeStamp(df)
	
	return 0

End // StatsLevel

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsSmoothCall(smthN, smthA)
	Variable smthN
	String smthA
	
	String vlist = "", df = StatsDF()
	
	Variable win = NumVarOrDefault(df+"AmpNV", 0)
	
	Wave SmthNum = $(df+"SmthNum")
	Wave /T SmthAlg = $(df+"SmthAlg")
	
	if (smthN == -1)
		smthN = SmthNum[win]
	endif
	
	strswitch(smthA)
		case "old":
			smthA = SmthAlg[win]
			break
		case "binomial":
		case "boxcar":
			break
		default:
			smthA = ChanSmthAlgAsk(-1)
	endswitch
	
	vlist = NMCmdNum(win, vlist)
	vlist = NMCmdNum(smthN, vlist)
	vlist = NMCmdStr(smthA, vlist)
	NMCmdHistory("StatsSmooth", vlist)
	
	return StatsSmooth(win, smthN, smthA)
	
End // StatsSmoothCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsSmooth(win, smthNum, smthAlg)
	Variable win
	Variable smthNum
	String smthAlg
	
	String df = StatsDF(), cdf = ChanDF(-1)
	String wname = df + "SmthAlg"
	
	if ((numtype(smthNum) > 0) || (smthNum < 0))
		smthNum = 0
	endif
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	strswitch(smthAlg)
		case "binomial":
		case "boxcar":
			break
		default:
			if (smthNum > 0)
				smthAlg = ChanSmthAlgAsk(-1)
			endif
	endswitch
	
	if (WhichListItemLax(smthAlg, "binomial;boxcar;", ";") == -1)
		return -1
	endif
	
	if (smthNum == 0)
		smthAlg = ""
	endif
	
	SetNMtwave(wname, win, smthAlg)
	SetNMwave(df+"SmthNum", win, smthNum)
	
	StatsChanControlsUpdate(-1, -1, 1)
	ChanGraphUpdate(-1, 1)
	NMAutoStats()
	StatsTimeStamp(df)
	
	return 0

End // StatsSmooth

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBslnCall(on)
	Variable on // (0) no (1) yes
	
	Variable tbgn, tend, twin, subtract
	Variable reflect, bgstart, bgend, bgcntr = Nan
	String select, vlist = "", fxn = "", df = StatsDF()
	
	Variable win = NumVarOrDefault(df+"AmpNV", 0)
	
	Wave AmpB= $(df+"AmpB"); Wave AmpE= $(df+"AmpE")
	Wave BslnB = $(df+"BslnB"); Wave BslnE = $(df+"BslnE")
	Wave BslnSubt = $(df+"BslnSubt"); Wave BslnRflct = $(df+"BslnRflct")
	Wave Bflag = $(df+"Bflag"); Wave Rflag = $(df+"Rflag"); Wave Dflag  = $(df+"Dflag")
	
	Wave /T BslnSlct = $(df+"BslnSlct")
	
	if ((on == 0) && ((Rflag[win] == 1) || (Dflag[win] == 1)))
		on = 1 // baseline must be on
	endif
	
	if (on == 1)
	
		tbgn = BslnB[win]
		tend = BslnE[win]
		twin = tend - tbgn
		subtract = BslnSubt[win] + 1
		reflect = 1 // no
		
		if (numtype(BslnRflct[win]) == 0)
			reflect = 2 // yes
			tbgn = BslnRflct[win] - twin/2
			tend = BslnRflct[win] + twin/2
		endif
		
		select = StatsAmpSelectGet(win)
		
		strswitch(select)
			case "SDev":
			case "Var":
			case "RMS":
			case "Area":
			case "Sum":
			case "Slope":
				fxn = select
				break
			default:
				fxn = "Avg"
		endswitch
		
		Prompt tbgn, "begin time (ms):"
		Prompt tend, "end time (ms):"
		Prompt fxn, "baseline measurement:", popup, "Max;Min;Avg;SDev;Var;RMS;Area;Sum;Slope"
		Prompt subtract, "subtract baseline from y-measurement?", popup, "no;yes"
		Prompt reflect, "compute reflected baseline from t_bgn and t_end?", popup, "no;yes"
		DoPrompt "Baseline Window", tbgn, tend, fxn, subtract, reflect
	
		if (V_Flag == 1)
			UpdateStats1()
			return 0
		endif
		
		subtract -= 1
		
		if (reflect == 2) // yes, reflect baseline window
		
			// recompute baseline time window based on AmpB and AmpE
		
			twin = BslnB[win] + BslnE[win]
			bgcntr = twin/2 // center of baseline window
			bgstart = 2*bgcntr - AmpE[win] // reflect back
			bgend = 2*bgcntr - AmpB[win]
	
			if ((bgstart < leftx($CurrentWaveName())) || (bgend <= bgstart))
				DoAlert 0, "Alert: error in computing time window of reflected background window."
				reflect = 1 // cancel reflect
			else
				tbgn = bgstart
				tend = bgend
			endif
		
		endif
	
	endif
	
	if ((on == 1) && (reflect == 2))
	
		vlist = NMCmdNum(win, vlist)
		vlist = NMCmdNum(on, vlist)
		vlist = NMCmdNum(tbgn, vlist)
		vlist = NMCmdNum(tend, vlist)
		vlist = NMCmdStr(fxn, vlist)
		vlist = NMCmdNum(subtract, vlist)
		vlist = NMCmdNum(bgcntr, vlist)
		NMCmdHistory("StatsBslnReflect", vlist)
		
		return StatsBslnReflect(win, on, tbgn, tend, fxn, subtract, bgcntr)
		
	else
	
		vlist = NMCmdNum(win, vlist)
		vlist = NMCmdNum(on, vlist)
		vlist = NMCmdNum(tbgn, vlist)
		vlist = NMCmdNum(tend, vlist)
		vlist = NMCmdStr(fxn, vlist)
		vlist = NMCmdNum(subtract, vlist)
		NMCmdHistory("StatsBsln", vlist)
		
		return StatsBsln(win, on, tbgn, tend, fxn, subtract)
		
	endif
	
End // StatsBslnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBsln(win, on, tbgn, tend, fxn, subtract)
	Variable win, on, tbgn, tend
	String fxn // Max,Min,Avg,SDev,Var,RMS,Area,Sum,Slope
	Variable subtract // (0) no (1) yes
	
	String sdf = StatsDF()
	String wname = sdf + "Bflag"
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	SetNMwave(wname, win, on)
	
	if (on == 1)
		SetNMwave(sdf + "BslnB", win, tbgn)
		SetNMwave(sdf + "BslnE", win, tend)
		SetNMtwave(sdf + "BslnSlct", win, fxn)
		SetNMwave(sdf + "BslnSubt", win, subtract)
	else
		SetNMwave(sdf + "BslnRflct", win, Nan) // turn of reflection
	endif
	
	NMAutoStats()
	StatsTimeStamp(sdf)
	
	return 0

End // StatsBsln

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBslnReflect(win, on, tbgn, tend, fxn, subtract, center)
	Variable win, on, tbgn, tend
	String fxn // Max,Min,Avg,SDev,Var,RMS,Area,Sum,Slope
	Variable subtract // (0) no (1) yes
	Variable center // baseline center
	
	String df = StatsDF()
	String wname = df + "BslnRflct"
	
	if (numtype(center) > 0)
		return -1
	endif
	
	SetNMwave(wname, win, center)
	
	if (StatsBsln(win, on, tbgn, tend, fxn, subtract) == -1)
		return -1
	endif
	
	StatsTimeStamp(df)
	
	return 0

End // StatsBslnReflect

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBslnReflectUpdate(win)
	Variable win
	
	String df = StatsDF()
	
	Wave AmpB = $(df+"AmpB"); Wave AmpE = $(df+"AmpE")
	Wave BslnB = $(df+"BslnB"); Wave BslnE = $(df+"BslnE")
	Wave BslnRflct = $(df+"BslnRflct")
	
	if (numtype(BslnRflct[win]) == 0)
		BslnB[win] = 2*BslnRflct[win] - AmpE[win] // reflect back
		BslnE[win] = 2*BslnRflct[win] - AmpB[win]
	endif

End // StatsBslnReflectUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsRiseTimeCall(on)
	Variable on // (0) no (1) yes
	
	Variable pbgn, pend
	String vlist = "", df = StatsDF()
	
	Variable win = NumVarOrDefault(df+"AmpNV", 0)
	
	Wave RiseBP = $(df+"RiseBP"); Wave RiseEP = $(df+"RiseEP")
	Wave Bflag = $(df+"Bflag"); Wave Rflag = $(df+"Rflag")

	if (on == 1)
	
		pbgn = RiseBP[win]
		pend = RiseEP[win]
		
		if (pbgn == pend)
			pbgn = 10
			pend = 90
		endif
		
		Prompt pbgn, "% begin:"
		Prompt pend, "% end:"
		DoPrompt "Percent Rise Time", pbgn, pend
		
		if (V_Flag == 1)
			UpdateStats1()
			return 0
		endif
		
	endif
	
	vlist = NMCmdNum(win, vlist)
	vlist = NMCmdNum(on, vlist)
	vlist = NMCmdNum(pbgn, vlist)
	vlist = NMCmdNum(pend, vlist)
	NMCmdHistory("StatsRiseTime", vlist)
	
	return StatsRiseTime(win, on, pbgn, pend)
	
End //  StatsRiseTimeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsRiseTime(win, on, pbgn, pend)
	Variable win, on, pbgn, pend
	
	String df = StatsDF()
	String wname = df + "Rflag"
	
	if ((pbgn < 0) || (pend > 100) || (pbgn < 0) || (pend > 100))
		return -1
	endif
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	SetNMwave(wname, win, on)
	
	if (on == 1)
		SetNMwave(df + "RiseBP", win, pbgn)
		SetNMwave(df + "RiseEP", win, pend)
		SetNMwave(df+"Bflag", win, 1) // turn on baseline computation
	endif
	
	NMAutoStats()
	StatsTimeStamp(df)
	
	return 0

End // StatsRiseTime

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDecayTimeCall(on)
	Variable on // (0) no (1) yes
	
	Variable pend
	String vlist = "", df = StatsDF()
	
	Variable win = NumVarOrDefault(df+"AmpNV", 0)
	
	Wave Bflag = $(df+"Bflag")
	Wave Dflag = $(df+"Dflag")
	Wave DcayP = $(df+"DcayP")
	
	if (on == 1)
	
		pend = DcayP[win]
		Prompt pend, "% decay:"
		DoPrompt "Percent Decay Time", pend
		
		if (V_Flag == 1)
			UpdateStats1()
			return 0
		endif
		
	endif
	
	vlist = NMCmdNum(win, vlist)
	vlist = NMCmdNum(on, vlist)
	vlist = NMCmdNum(pend, vlist)
	NMCmdHistory("StatsDecayTime", vlist)
	
	return StatsDecayTime(win, on, pend)
	
End // StatsDecayTimeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDecayTime(win, on, pend)
	Variable win, on, pend
	
	String df = StatsDF()
	String wname = df + "Dflag"
	
	if ((pend < 0) || (pend > 100))
		return -1
	endif
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	SetNMwave(wname, win, on)
	
	if (on == 1)
		SetNMwave(df+"DcayP", win, pend)
		SetNMwave(df+"Bflag", win, 1) // turn on baseline computation
	endif
	
	NMAutoStats()
	StatsTimeStamp(df)
	
	return 0

End // StatsDecayTime

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFuncCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	StatsCall("Ft", num2str(checked))
	
End // StatsFuncCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFuncCall(on)
	Variable on // (0) no (1) yes
	
	Variable win, fxn
	String vlist = "", df = StatsDF()
	
	if (on == 1)
		fxn = ChanFuncAsk(NMCurrentChan())
	endif
	
	if (fxn == -1)
		UpdateStats1() // cancel
		return 0
	endif
	
	win = NumVarOrDefault(df+"AmpNV", 0)
	
	vlist = NMCmdNum(win, vlist)
	vlist = NMCmdNum(fxn, vlist)
	NMCmdHistory("StatsFunc", vlist)
	
	return StatsFunc(win, fxn)

End // StatsFuncCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFunc(win, fxn)
	Variable win
	Variable fxn // (0) none (1) d/dt (2) dd/dt*dt (3) integral (4) norm2max (5) norm2min
	
	String sdf = StatsDF()
	String wname = sdf + "dtFlag"
	
	if ((fxn < 0) || (fxn > 5))
		return -1
	endif
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	SetNMwave(wname, win, fxn)
	
	StatsChanControlsUpdate(-1, -1, 1)
	ChanGraphUpdate(-1, 1)
	NMAutoStats()
	StatsTimeStamp(sdf)
	
	return 0
	
End // StatsFunc

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffsetCall(on)
	Variable on // (0) no (1) yes
	
	Variable create
	String txt, tName, vlist = "", wlist = "", rlist = "", typestr = "/g"
	
	String ndf = NMDF(), df = StatsDF()
	
	Variable nwaves = NMNumWaves()
	Variable ngrps = NumVarOrDefault("NumGrps", 0)
	
	Variable select = NumVarOrDefault(df+"OffsetSelect", 1)
	Variable wtype = NumVarOrDefault(df+"OffsetType", 1)
	Variable bsln = 1+NumVarOrDefault(df+"OffsetBsln", 1)
	String wname = StrVarOrDefault(df+"OffsetWName", "")
	
	Variable win = NumVarOrDefault(df+"AmpNV", 0)
	
	switch(on)
	
		default:
			break
			
		case 1:
		
			if (NumVarOrDefault(ndf+"GroupsOn", 0) == 0)
				wtype = 2
			endif
			
			Prompt select, "choose option:", popup "create a wave of time-offset values;select a wave of time-offset values;"
			Prompt wtype, "these time-offset values will pertain to what?", popup "individual groups;individual waves;"
			Prompt bsln, "apply offsets to baseline windows as well?", popup "no;yes;"
			
			DoPrompt "Stats Window Time Offset", select, wtype, bsln
			
			if (V_flag == 1)
				on = -1
				break
			endif
			
			bsln -= 1
			
			txt = "A time-offset wave name should contain the string sequence \"Offset\"."
			
			if (select == 2)
			
				wlist = WaveList("*Offset*", ";", WaveListText0())
				
				if (ItemsInList(wlist) == 0)
					DoAlert 0, "Detected no time-offset waves. " + txt
					on = -1
					break
				endif
				
			endif
				
			if ((select == 1) && (wtype == 1))
			
				wname = "ST_GroupOffset"
				Prompt wname, "enter name for new time-offset wave (should contain \"Offset\") :"
				DoPrompt "Create Group Time-Offset Wave", wname
				create = 1
				
				if (StringMatch(wname, "*Offset*") == 0)
					DoAlert 0, "Bad time-offset wave name. " + txt
					on = -1
					break
				endif
			
			elseif ((select == 1) && (wtype == 2))
			
				wname = "ST_WaveOffset"
				Prompt wname, "enter name for new time-offset wave:"
				DoPrompt "Create Wave Time-Offset Wave", wname
				create = 1
			
			elseif ((select == 2) && (wtype == 1))
			
				Prompt wname, "choose a wave of time-offset values:", popup wlist
				DoPrompt "Select Group Time-Offset Wave", wname
			
			elseif ((select == 2) && (wtype == 2))
			
				Prompt wname, "choose a wave of time-offset values:", popup wlist
				DoPrompt "Select Wave Time-Offset Wave", wname
				
				if ((V_flag == 0) && (numpnts($wname) != nwaves))
					DoAlert 0, "Warning: time-offset wave length does not match the number of data waves."
				endif
			
			endif
			
			if (V_flag == 1)
				on = -1
				break
			endif
			
			if (create == 1)
			
				vlist = NMCmdStr(wname, vlist)
				vlist = NMCmdNum(wtype, vlist)
				NMCmdHistory("StatsOffsetWave", vlist)
			
				if (StatsOffsetWave(wname, wtype) < 0)
					on = -1
					break
				endif
				
			endif
			
			SetNMvar(df+"OffsetSelect", select)
			SetNMvar(df+"OffsetType", wtype)
			SetNMvar(df+"OffsetBsln", bsln)
			SetNMstr(df+"OffsetWName", wname)
		
	endswitch
	
	if (wtype == 1)
		typestr = "/g"
	else
		typestr = "/w"
	endif
	
	if (on <= 0)
		typestr = ""
		wname = ""
	endif
	
	if (on >= 0)
		vlist = NMCmdNum(win, "")
		vlist = NMCmdStr(typestr+wname, vlist)
		NMCmdHistory("StatsOffset", vlist)
	endif

	return StatsOffset(win, typestr+wname)

End // StatsOffsetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffset(win, offName)
	Variable win // stats win num
	String offName // offset type ("/w" or "/g") + wave name, or ("") for no offset
	
	String type = "", sdf = StatsDF()
	String wname = sdf + "OffsetW"
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	if (strlen(offName) > 0) 
		
		type = offName[0,1]
		offName = offName[2,inf]
		
		if (WaveExists($offName) == 0)
			return -1
		endif
		
		strswitch(type)
			default:
				return -1
			case "/w":
			case "/g":
				break
		endswitch
		
	endif
	
	SetNMtwave(wname, win, type+offName)
	
	NMAutoStats()
	StatsTimeStamp(sdf)
	
	return 0
	
End // StatsOffset

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffsetWave(wname, wtype) // create offset (time-shift) wave
	String wname
	Variable wtype // (1) group time offset (2) wave time offset
	
	String tName
	
	Variable nwaves = NMNumWaves()
	Variable ngrps = NumVarOrDefault("NumGrps", 0)
	
	if (StringMatch(wname, "*Offset*") == 0)
		DoAlert 0, "Bad time-offset wave name. A time-offset wave name should contain the string sequence \"Offset\"."
		return -1
	endif
	
	if (WaveExists($wname) == 1)
	
		DoAlert 1, "Warning: wave \"" + wname + "\" already exists. Do you want to overwrite this wave?"
		
		if (V_Flag != 1)
			return -1
		endif
		
	endif
	
	if (wtype == 1)
		Make /O/N=(ngrps) $wName
	else
		Make /O/N=(nwaves) $wName
	endif
	
	if (StringMatch(wName[0,2], StatsPrefix("")) == 1)
		tName = wName + "_Table"
	else
		tName = StatsPrefix(wName)
	endif
	
	DoWindow /K $tName
	Edit /K=1/W=(0,0,0,0) $wName as "Stats Time-Offset Wave"
	DoWindow /C $tName
	SetCascadeXY(tName)
	
	if (wtype == 1)
		Execute "ModifyTable title(Point)= \"Group\""
	else
		Execute "ModifyTable title(Point)= \"Wave\""
	endif
	
	return 0

End // StatsOffsetWave

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffsetValue(win) // will return time-offset value, or (-1) time-offset inactivated
	Variable win
	
	String wname, type, df = StatsDF()
	Variable select
	
	Variable currentWave = NumVarOrDefault("CurrentWave", -1)
	
	if (WaveExists($(df+"OffsetW")) == 0)
		return -1
	endif
	
	Wave /T OffsetW = $(df+"OffsetW")
	
	wname = OffsetW[win]
	
	if (strlen(wname) == 0)
		return -1
	endif
	
	type = wname[0,1]
	wname = wname[2,inf]
	
	if (WaveExists($wname) == 0)
		return -1
	endif
	
	strswitch(type)
		case "/w":
			select = currentWave
			break
		case "/g":
			select = NMGroupGet(currentWave)
			break
		default:
			return -1
	endswitch
	
	Wave wtemp = $wname
	
	if ((numtype(select) > 0) || (select < 0) || (select >= numpnts(wtemp)))
		return 0
	endif
	
	return wtemp[select]

End // StatsOffsetValue

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLabelsCall(on)
	Variable on // (0) no (1) yes
	
	NMCmdHistory("StatsLabels", NMCmdNum(on,""))
	
	return StatsLabels(on)
	
End // StatsLabelsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLabels(on)
	Variable on // (0) no (1) yes
	
	SetNMVar(StatsDF()+"WinYOn", BinaryCheck(on))
	NMAutoStats()
	
	return on
	
End // StatsLabels

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLabelsToggle()
	String df = StatsDF()
	Variable on = NumVarOrDefault(df+"WinYOn", 1)
	
	if (on == 1)
		on = 0
	else
		on = 1
	endif
	
	SetNMVar(df+"WinYOn", on)
	
	StatsDisplay(-1, 1)
	NMAutoStats()
	
	return on
	
End // StatsLabelsToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsAmpList()

	return "Max;Min;Avg;SDev;Var;RMS;Area;Sum;Slope;RTSlope+;RTSlope-;Level;Level+;Level-;FWHM+;FWHM-;Onset;Off;"

End // StatsAmpList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsAmpSelectGet(win)
	Variable win
	
	String select, sdf = StatsDF()
	
	if (WaveExists($(sdf+"AmpSlct")) == 0)
		return ""
	endif
	
	Wave /T AmpSlct = $(sdf+"AmpSlct")
	
	if ((win >= 0) && (win < numpnts(AmpSlct)))
		
		select = AmpSlct[win]
		
		if ((strlen(select) == 0) || (StringMatch(select[0,2], "Off") == 1))
			AmpSlct[win] = "Off"
			return "Off"
		else
			return AmpSlct[win]
		endif
		
	else
	
		return ""
		
	endif
	
End // StatsAmpSelectGet

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmpBegin()

	Variable icnt, tbgn, tend, chan
	String df = StatsDF() 
	
	Variable win = NumVarOrDefault(df+"AmpNV", 0)
	
	if (StringMatch(StatsAmpSelectGet(win), "Off") == 0)
		return 0 // stats window has be defined
	endif
	
	for (icnt = 0; icnt < numpnts($(df+"AmpSlct")); icnt += 1) // look for next available
		
		if (StringMatch(StatsAmpSelectGet(icnt), "Off") == 0)
			SetNMvar(df+"AmpNV", icnt)
			return 0
		endif
		
	endfor
	
	// nothing defined yet, set default values for first window
	
	chan = NMCurrentChan()
	tend = floor(rightx($ChanDisplayWave(-1)))
	
	if ((numtype(tend) > 0) || (tend == 0))
		tbgn = -inf	
		tend = inf
	else
		tbgn = floor(tend / 4)
		tend = floor(tend / 2)
	endif
	
	win = 0 // start at first window
	SetNMvar(df+"AmpNV", win)
		
	//SetNMwave(df+"ChanSelect", win, chan)
	SetNMwave(df+"dtFlag", win, ChanFuncGet(chan))
	SetNMwave(df+"SmthNum", win, ChanSmthNumGet(chan))
	SetNMtwave(df+"SmthAlg", win, ChanSmthAlgGet(chan))
	
	SetNMtwave(df+"AmpSlct", win, "Max")
	SetNMwave(df+"AmpB", win, tbgn)
	SetNMwave(df+"AmpE", win, tend)
	
	tbgn = NumVarOrDefault(MainDF()+"Bsln_Bgn", 0)
	tend = NumVarOrDefault(MainDF()+"Bsln_End", floor(tend / 5))

	SetNMwave(df+"Bflag", win, 1)
	SetNMtwave(df+"BslnSlct", win, "Avg")
	SetNMwave(df+"BslnB", win, tbgn)
	SetNMwave(df+"BslnE", win, tend)
	SetNMwave(df+"BslnSubt", win, 0)
	SetNMwave(df+"BslnRflct", win, Nan)

End // StatsAmpBegin

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmpInit(win)
	Variable win // stats window or (-1) for current
	
	Variable winLast
	String select, wlist, last, df = StatsDF(), cdf = ChanDF(-1)
	
	if (WaveExists($(df+"AmpB")) == 0)
		return -1
	endif
	
	//Wave ChanSelect = $(df+"ChanSelect")
	Wave AmpB = $(df+"AmpB"); Wave AmpE = $(df+"AmpE");
	Wave BslnB = $(df+"BslnB"); Wave BslnE = $(df+"BslnE")
	Wave BslnSubt = $(df+"BslnSubt"); Wave BslnRflct = $(df+"BslnRflct")
	Wave /T BslnSlct = $(df+"BslnSlct")
	
	Wave dtFlag = $(df+"dtFlag")
	Wave smthNum = $(df+"SmthNum")
	Wave /T smthAlg = $(df+"SmthAlg")
	
	if (win < 0)
		win = NumVarOrDefault(df+"AmpNV", 0)
	endif
	
	select = StatsAmpSelectGet(win)
	
	wlist = StatsWinList(1)
	
	if (ItemsInList(wlist) == 0)
		return 0 // nothing to do
	else
		last = StringFromList(ItemsInList(wlist)-1, wlist)
		winLast = str2num(last[3,inf])
	endif
	
	if ((winLast < 0) || (winLast >= numpnts(AmpB)) || (win == winLast))
		return 0 // something wrong
	endif
	
	if (StringMatch(select, "Off") == 1) // copy previous window values to new window
		
		//ChanSelect[win] = ChanSelect[winLast]
		dtFlag[win] = dtFlag[winLast]
		smthNum[win] = smthNum[winLast]
		smthAlg[win] = smthAlg[winLast]
		
		if ((AmpE[win] == 0) && (win > 0))
			AmpB[win] = AmpB[winLast]
			AmpE[win] = AmpE[winLast]
		endif
		
		if ((BslnE[win] == 0) && (win > 0))
			BslnB[win] = BslnB[winLast]
			BslnE[win] = BslnE[winLast]
			BslnSlct[win] = BslnSlct[winLast]
			BslnSubt[win] = BslnSubt[winLast]
			BslnRflct[win] = BslnRflct[winLast]
		endif
		
	endif

End // StatsAmpInit

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Stats display graph functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanControlsEnableAll(enable)
	Variable enable
	
	Variable ccnt
	String gName, df = StatsDF()
	
	Variable currentChan = NMCurrentChan()
	Variable numChan = NMNumChannels()
	
	if (enable == 1)
		SetNMwave(df+"ChanSelect", -1, currentChan)
	endif
	
	for (ccnt = 0; ccnt < numChan; ccnt += 1)
	
		gName = ChanGraphName(ccnt) 
	
		if (IsChanGraph(ccnt) == 0)
			continue
		endif
		
		KillControl /W=$gName $("ST_DragOn" + num2str(ccnt)) // NO LONGER USED
		
		if ((ccnt == currentChan) && (enable == 1))
			StatsChanControlsUpdate(ccnt, -1, 1)
		else
			StatsChanControlsUpdate(ccnt, -1, 0)
		endif
		
	endfor

End // StatsChanControlsEnableAll

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanControlsUpdate(chanNum, win, enable)
	Variable chanNum
	Variable win
	Variable enable
	
	StatsChanControlsEnable(chanNum, win, enable)
	ChanGraphControlsUpdate(chanNum)

End // StatsChanControlsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanControlsEnable(chanNum, win, enable)
	Variable chanNum
	Variable win
	Variable enable
	
	String sdf = StatsDF(), ndf = NMDF()
	
	Wave AmpB = $(sdf+"AmpB")
	Wave AmpE = $(sdf+"AmpE")
	Wave BslnB = $(sdf+"BslnB")
	Wave BslnE = $(sdf+"BslnE")
	
	Wave dtFlag = $(sdf+"dtFlag")
	Wave smthNum = $(sdf+"SmthNum")
	Wave /T smthAlg = $(sdf+"SmthAlg")
	
	chanNum = ChanNumCheck(chanNum)
	
	if (win < 0)
		win = NumVarOrDefault(sdf+"AmpNV", 0)
	endif
	
	if (enable == 1)
	
		SetNMvar(sdf+"Ft", dtFlag[win]) // for channel graph display
		SetNMvar(sdf+"SmoothN", SmthNum[win]) // for channel graph display
		SetNMstr(sdf+"SmoothA", SmthAlg[win]) // for channel graph display
		
		if (dtFlag[win] > 3)
			SetNMvar(sdf+"Norm_Tbgn", AmpB[win])
			SetNMvar(sdf+"Norm_Tend", AmpE[win])
			SetNMvar(sdf+"Norm_Bbgn", BslnB[win])
			SetNMvar(sdf+"Norm_Bend", BslnE[win])
		endif
		
		SetNMstr(ndf + "ChanPopupList" + num2str(chanNum), " ;Stats Drag;Stats Labels;" + ChanPopupListDefault())
		SetNMstr(ndf + "ChanPopupProc" + num2str(chanNum), "StatsChanPopup")
		
		SetNMstr(ndf + "ChanSmthDF" + num2str(chanNum), sdf)
		SetNMstr(ndf + "ChanSmthProc" + num2str(chanNum), "StatsSetSmooth")
		
		SetNMstr(ndf + "ChanFuncDF" + num2str(chanNum), sdf)
		SetNMstr(ndf + "ChanFuncProc" + num2str(chanNum), "StatsFuncCheckBox")
		
	else
	
		KillStrings /Z $(ndf + "ChanPopupList" + num2str(chanNum))
		KillStrings /Z $(ndf + "ChanPopupProc" + num2str(chanNum))
		
		KillStrings /Z $(ndf + "ChanSmthDF" + num2str(chanNum))
		KillStrings /Z $(ndf + "ChanSmthProc" + num2str(chanNum))
		
		KillStrings /Z $(ndf + "ChanFuncDF" + num2str(chanNum))
		KillStrings /Z $(ndf+ "ChanFuncProc" + num2str(chanNum))
	
	endif
	
End // StatsChanControlsEnable

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDisplay(chan, appnd) // append/remove display waves to current channel graph
	Variable chan // channel number (-1) for current channel
	Variable appnd // (0) remove (1) append
	
	String df = StatsDF()
	
	Variable anum, xy, icnt, ccnt, drag = 1, dragstyle = 3
	Variable r, g, b, br, bg, bb, rr, rg, rb
	String gName
	
	Variable winY = NumVarOrDefault(StatsDF()+"WinYOn", 1)
	
	Variable ampNV = NumVarOrDefault(df+"AmpNV", 0)
	
	if ((WaveExists($(df+"ST_DragBYB")) == 0) || (StringMatch(NMTabCurrent(), "Stats") == 0))
		drag = 0
	endif
	
	chan = ChanNumCheck(chan)
	
	for (ccnt = 0; ccnt < 10; ccnt += 1)
	
		gName = ChanGraphName(ccnt)
	
		if (Wintype(gName) == 0)
			continue
		endif
		
		RemoveFromGraph /Z/W=$gName ST_BslnY, ST_WinY, ST_PntY, ST_RDY
		RemoveFromGraph /Z/W=$gName ST_DragBYB, ST_DragBYE, ST_DragWYB, ST_DragWYE
		
		if ((appnd == 0) || (ccnt != chan) || (WaveExists($(df+"ST_BslnY")) == 0))
			continue
		endif
		
		r = StatsDisplayColor("Amp", "r")
		g = StatsDisplayColor("Amp", "g")
		b = StatsDisplayColor("Amp", "b")
		
		br = StatsDisplayColor("Base", "r")
		bg = StatsDisplayColor("Base", "g")
		bb = StatsDisplayColor("Base", "b")
		
		rr = StatsDisplayColor("Rise", "r")
		rg = StatsDisplayColor("Rise", "g")
		rb = StatsDisplayColor("Rise", "b")

		AppendToGraph /W=$gName $(df+"ST_BslnY") vs $(df+"ST_BslnX")
		AppendToGraph /W=$gName $(df+"ST_WinY") vs $(df+"ST_WinX")
		AppendToGraph /W=$gName $(df+"ST_PntY") vs $(df+"ST_PntX")
		AppendToGraph /W=$gName $(df+"ST_RDY") vs $(df+"ST_RDX")
		
		ModifyGraph /W=$gName lsize(ST_BslnY)=1.1, rgb(ST_BslnY)=(br,bg,bb)
		ModifyGraph /W=$gName mode(ST_PntY)=3, marker(ST_PntY)=19, rgb(ST_PntY)=(r,g,b)
		ModifyGraph /W=$gName lsize(ST_WinY)=1.1, rgb(ST_WinY)=(r,g,b)
		ModifyGraph /W=$gName mode(ST_RDY)=3, marker(ST_RDY)=9, mrkThick(ST_RDY)=2
		ModifyGraph /W=$gName msize(ST_RDY)=4, rgb(ST_RDY)=(rr,rg,rb)
		
		if ((drag == 1) || (WaveExists($(df+"ST_DragBYB")) == 0))
		
			AppendToGraph /W=$gName $(df+"ST_DragBYB") vs $(df+"ST_DragBXB")
			AppendToGraph /W=$gName $(df+"ST_DragBYE") vs $(df+"ST_DragBXE")
			AppendToGraph /W=$gName $(df+"ST_DragWYB") vs $(df+"ST_DragWXB")
			AppendToGraph /W=$gName $(df+"ST_DragWYE") vs $(df+"ST_DragWXE")
			
			ModifyGraph /W=$gName lstyle(ST_DragWYB)=dragstyle, rgb(ST_DragWYB)=(r,g,b)
			ModifyGraph /W=$gName lstyle(ST_DragWYE)=dragstyle, rgb(ST_DragWYE)=(r,g,b)
			ModifyGraph /W=$gName quickdrag(ST_DragWYB)=1,live(ST_DragWYB)=1, offset(ST_DragWYB)={0,0}
			ModifyGraph /W=$gName quickdrag(ST_DragWYE)=1,live(ST_DragWYE)=1, offset(ST_DragWYE)={0,0}
			
			ModifyGraph /W=$gName lstyle(ST_DragBYB)=dragstyle, rgb(ST_DragBYB)=(br,bg,bb)
			ModifyGraph /W=$gName lstyle(ST_DragBYE)=dragstyle, rgb(ST_DragBYE)=(br,bg,bb)
			ModifyGraph /W=$gName quickdrag(ST_DragBYB)=1,live(ST_DragBYB)=1, offset(ST_DragBYB)={0,0}
			ModifyGraph /W=$gName quickdrag(ST_DragBYE)=1,live(ST_DragBYE)=1, offset(ST_DragBYE)={0,0}
		
		endif
		
		Tag /W=$gName/N=ST_Win_Tag/G=(r,g,b)/I=1/F=0/L=0/X=5.0/Y=0.00/V=(winY) ST_WinY, 1, " \\{\"%.2f\",TagVal(2)}"
		Tag /W=$gName/N=ST_Bsln_Tag/G=(br,bg,bb)/I=1/F=0/L=0/X=5.0/Y=0.00/V=(winY) ST_BslnY, 1, " \\{\"%.2f\",TagVal(2)}"
			
	endfor

End // StatsDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDisplayColor(select, rgb)
	String select // (a) Amp (b) Base (r) Rise
	String rgb // r, g or b
	
	String color, df = StatsDF()
	
	strswitch(select)
		case "amp":
			color = StrVarOrDefault(df+"AmpColor", "65535,0,0")
			break
		case "base":
			color = StrVarOrDefault(df+"BaseColor", "0,39168,0")
			break
		case "rise":
			color = StrVarOrDefault(df+"RiseColor", "0,0,65535")
			break
	endswitch

	return str2num(StringFromList(WhichListItem(rgb, "r;g;b;"),color,","))

End // StatsDisplayColor

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDisplayClear()

	String df = StatsDF()
	
	SetNMwave(df+"ST_BslnY", -1, Nan)
	SetNMwave(df+"ST_WinY", -1, Nan)
	SetNMwave(df+"ST_PntY", -1, Nan)
	SetNMwave(df+"ST_RDY", -1, Nan)
	
	SetNMwave(df+"ST_DragBXB", -1, Nan)
	SetNMwave(df+"ST_DragBXE", -1, Nan)
	SetNMwave(df+"ST_DragBYB", -1, Nan)
	SetNMwave(df+"ST_DragBYE", -1, Nan)
	SetNMwave(df+"ST_DragWXB", -1, Nan)
	SetNMwave(df+"ST_DragWXE", -1, Nan)
	SetNMwave(df+"ST_DragWYB", -1, Nan)
	SetNMwave(df+"ST_DragWYE", -1, Nan)

End // StatsDisplayClear

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDragCheck()

	String df = StatsDF()
	String wdf = "root:WinGlobals:"
	String cdf = "root:WinGlobals:" + ChanGraphName(-1) + ":"
	
	if (WaveExists($(df+"ST_DragBXB")) == 0)

		CheckNMwave(df+"ST_DragBXB", 2, -1) // baseline drag
		CheckNMwave(df+"ST_DragBYB", 2, -1)
		CheckNMwave(df+"ST_DragBXE", 2, -1)
		CheckNMwave(df+"ST_DragBYE", 2, -1)
		
		CheckNMwave(df+"ST_DragWXB", 2, -1) // window drag
		CheckNMwave(df+"ST_DragWYB", 2, -1)
		CheckNMwave(df+"ST_DragWXE", 2, -1)
		CheckNMwave(df+"ST_DragWYE", 2, -1)
	
	endif
	
	Redimension /N=2 $(df+"ST_DragBXB"), $(df+"ST_DragBXE"), $(df+"ST_DragBYB"), $(df+"ST_DragBYE")
	Redimension /N=2 $(df+"ST_DragWXB"), $(df+"ST_DragWXE"), $(df+"ST_DragWYB"), $(df+"ST_DragWYE")
	
	if (DataFolderExists(wdf) == 0)
		NewDataFolder $(LastPathColon(wdf,0))
	endif
	
	if (DataFolderExists(cdf) == 0)
		NewDataFolder $(LastPathColon(cdf,0))
	endif
	
	CheckNMstr(cdf+"S_TraceOffsetInfo", "")
	CheckNMvar(cdf+"HairTrigger", 0)
	
	SetFormula $(cdf+"HairTrigger"),"StatsDragTrigger(" + cdf + "S_TraceOffsetInfo)"

End // StatsDragCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDragCall(on)
	Variable on // (0) no (1) yes
	
	NMCmdHistory("StatsDrag", NMCmdNum(on,""))
	
	return StatsDrag(on)
	
End // StatsDragCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDrag(on)
	Variable on // (0) no (1) yes
	
	SetNMVar(StatsDF()+"DragOn", BinaryCheck(on))
	NMAutoStats()
	
	return on
	
End // StatsDrag

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDragToggle()
	String df = StatsDF()
	Variable on = NumVarOrDefault(df+"DragOn", 1)
	
	if (on == 1)
		on = 0
	else
		on = 1
	endif
	
	SetNMVar(df+"DragOn", on)
	NMAutoStats()
	
	return on
	
End // StatsDragToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDragTrigger(offsetStr)
	String offsetStr
	
	if (strlen(offsetStr) == 0)
		return -1
	endif
	
	String wname2, df = StatsDF()
	
	String gname = StringByKey("GRAPH", offsetStr)
	String wname = StringByKey("TNAME", offsetStr)
	Variable offset = str2num(StringByKey("XOFFSET", offsetStr))

	Variable win = NumVarOrDefault(df+"AmpNV", -1)
	
	if ((WinType(gname) == 0) || (offset == 0) || (win < 0))
		return -1
	endif
	
	strswitch(wname)
		case "ST_DragBYB":
			wname2 = df+"BslnB"
			break
		case "ST_DragBYE":
			wname2 = df+"BslnE"
			break
		case "ST_DragWYB":
			wname2 = df+"AmpB"
			break
		case "ST_DragWYE":
			wname2 = df+"AmpE"
			break
	endswitch
	
	if (WaveExists($wname2) == 0)
		return -1
	endif
	
	Wave wtemp = $wname2
	
	wtemp[win] = wtemp[win] + offset
	
	ModifyGraph /W=$gname offset($wname)={0,0} // remove offset
	
	SetNMvar(df+"AutoDoUpdate", 0) // prevent DoUpdate in NMAutoStats
	
	NMAutoStats()
	
	SetNMvar(df+"AutoDoUpdate", 1) // reset update flag
	
	StatsTimeStamp(df)
	
	DoWindow /F $gname
	
End // StatsDragTrigger

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDragSetY() // Note, this must be called AFTER graphs have been auto scaled

	String df = StatsDF()
	String gName = ChanGraphName(-1)

	Variable ampNV = NumVarOrDefault(df+"AmpNV", 0)
	Variable drag = NumVarOrDefault(df+"DragOn", 1)
	
	if (WaveExists($(df+"ST_DragBYB")) == 0)
		return -1
	endif
	
	Wave Bflag = $(df+"Bflag")

	Wave ST_DragBYB = $(df+"ST_DragBYB"); Wave ST_DragBXB = $(df+"ST_DragBXB")
	Wave ST_DragBYE = $(df+"ST_DragBYE"); Wave ST_DragBXE = $(df+"ST_DragBXE") 
	Wave ST_DragWYB = $(df+"ST_DragWYB"); Wave ST_DragWXB = $(df+"ST_DragWXB")
	Wave ST_DragWYE = $(df+"ST_DragWYE"); Wave ST_DragWXE = $(df+"ST_DragWXE")

	if (drag == 0)
		
		ST_DragBXB = Nan
		ST_DragBXE = Nan
		ST_DragBYB = Nan
		ST_DragBYE = Nan
		
		ST_DragWXB = Nan
		ST_DragWXE = Nan
		ST_DragWYB = Nan
		ST_DragWYE = Nan
	
	elseif (WinType(gName) == 1)
	
		if (NumVarOrDefault(df+"AutoDoUpdate", 1) == 1)
			DoUpdate
		endif
	
		GetAxis /W=$gName/Q left
		
		ST_DragWYB[0] = V_min
		ST_DragWYB[1] = V_max
		ST_DragWYE[0] = V_min
		ST_DragWYE[1] = V_max
		
		if (Bflag[AmpNV] == 0)
			ST_DragBYB = Nan
			ST_DragBYE = Nan
		else
			ST_DragBYB[0] = V_min
			ST_DragBYB[1] = V_max
			ST_DragBYE[0] = V_min
			ST_DragBYE[1] = V_max
		endif
	
	endif

End // StatsDragSetY

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Stats computation functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAllWavesCall()

	Variable allwin, numWin = StatsWinCount()
	String vlist = "", select, df = StatsDF()
	
	Variable dsplyFlag = 1 + NumVarOrDefault(df+"AllWavesDisplay", 1)
	Variable speed = NumVarOrDefault(df+"AllWavesSpeed", 0)
	Variable winNum = NumVarOrDefault(df+"AmpNV", 0)
	
	if (numWin <= 0)
		DoAlert 0, "All Stats windows are off."
		return -1
	elseif (numWin == 1)
		allwin = 1
	elseif (numWin > 1)
		allwin = 1 + NumVarOrDefault(df+"AllWavesWin", 1)
	endif
	
	Prompt allwin, "compute:", popup "current window;all windows;"
	Prompt dsplyFlag, "display results while computing?", popup "no;yes;"
	Prompt speed, "display update delay (msec):"
	
	if (numWin > 1)
		DoPrompt "Stats All Waves", allwin, dsplyFlag, speed
		allwin -= 1
	else
		DoPrompt "Stats All Waves", dsplyFlag, speed
	endif
	
	dsplyFlag -= 1
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMvar(df+"AllWavesWin", allwin)
	SetNMvar(df+"AllWavesDisplay", dsplyFlag)
	SetNMvar(df+"AllWavesSpeed", speed)
	
	select = StatsAmpSelectGet(winNum)
	
	if ((allwin == 0) && (StringMatch(select, "Off") == 1))
		DoAlert 0, "Current Stats window is off."
		return -1
	endif
		
	if (allwin == 1)
		winNum = -1
	endif
	
	vlist = NMCmdNum(winNum, vlist)
	vlist = NMCmdNum(dsplyFlag, vlist)
	vlist = NMCmdNum(speed, vlist)

	if (NMAllGroups() == 1)
	
		NMCmdHistory("StatsAllGroups", vlist)
		return StatsAllGroups(winNum, dsplyFlag, speed)
		
	else
	
		NMCmdHistory("StatsAllWaves", vlist)
		return StatsAllWaves(winNum, dsplyFlag, speed)
		
	endif

End // StatsAllWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAllGroups(winNum, dsplyFlag, speed)
	Variable winNum // stats1 window number (-1 for all)
	Variable dsplyFlag // display results while computing (0) no (1) yes
	Variable speed // update display speed in msec (0) for none
	
	Variable gcnt
	String df = NMDF()
	
	Variable saveNameformat = NumVarOrDefault(df+"NameFormat", 1)
	
	String saveSelect = NMWaveSelectGet()
	String grpList = NMGroupList(1)
	
	SetNMVar(df+"NameFormat", 1) // force long name format
	
	for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
		NMWaveSelect(StringFromList(gcnt, grpList))
		StatsAllWaves(winNum, dsplyFlag, speed)
	endfor

	NMWaveSelect(saveSelect) // back to original wave select
	SetNMVar(df+"NameFormat", saveNameFormat) // back to original format
	
	return 0

End // StatsAllGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAllWaves(winNum, dsplyFlag, speed)
	Variable winNum // stats1 window number (-1 for all)
	Variable dsplyFlag // update channel graphs while computing (0) no (1) yes
	Variable speed // update display speed in msec (0) for fastest

	Variable ccnt, wcnt, pflag, forcenew, cancel, changeChan, saveDrag = -1
	String wName, gName, wlist = "", tName = "", df = StatsDF()
	
	Variable saveCurrentWave = NMCurrentWave()
	Variable saveCurrentChan = NMCurrentChan()
	
	CheckNMwave(df+"WinSelect", 10, 0)
	SetNMwave(df+"WinSelect", -1, 0) // set all to zero
	SetNMwave(df+"WinSelect", winNum, 1)
	
	Variable nwaves = NMNumWaves()
	
	WaveStats /Q WavSelect
	
	if (V_max != 1)
		DoAlert 0, "No Waves Selected!"
		return -1
	endif
	
	if (winNum == -1)
		forcenew = 1
	endif
	
	if (dsplyFlag == 1)
		saveDrag = NumVarOrDefault(df+"DragOn", 1)
		SetNMvar(df+"DragOn", 0)
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		tName = StatsWavesTables(ccnt, forcenew)
		wlist = AddListItem(tName, wlist, ";", inf)
		
		if (dsplyFlag == 1)
		
			if (ccnt != saveCurrentChan)
				StatsDisplay(-1, 0) // remove stats display waves
				StatsDisplay(ccnt, 1) // add stats display waves
				changeChan = 1
			endif
			
			StatsDisplayClear()
			ChanControlsDisable(ccnt, "111111")
			DoWindow /F $ChanGraphName(ccnt)
			DoUpdate
			
		endif
		
		NMProgressStr("Stats Chan " + ChanNum2Char(ccnt))
	
		for (wcnt = 0; wcnt <  nwaves; wcnt += 1)
			
			if (CallNMProgress(wcnt, nwaves) == 1)
				break
			endif
			
			wName = NMWaveSelected(ccnt, wcnt)
			
			if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			SetNMvar("CurrentWave", wcnt)
			SetNMvar("CurrentGrp", NMGroupGet(wcnt))
			
			if (dsplyFlag == 1)
				ChanGraphUpdate(ccnt, 1)
				SetNMvar("CurrentWave", wcnt)
			endif
	
			StatsCompute(wName, ccnt, wcnt, winNum, 1, dsplyFlag)
			
			if ((dsplyFlag == 1) && (speed > 0))
				NMWait(speed)
			endif
				
		endfor
		
		if (NMProgressCancel() == 1)
			break
		endif
		
	endfor
	
	ResetProgress()
	
	if (changeChan > 0) // back to original channel
		StatsDisplay(ccnt, 0) // remove display waves
		StatsDisplay(saveCurrentChan, 1) // add display waves
	endif
	
	if (dsplyFlag == 1)
		SetNMvar(df+"DragOn", saveDrag)
	endif
	
	SetNMvar("CurrentWave", saveCurrentWave)
	setNMvar("CurrentGrp", NMGroupGet(saveCurrentWave))
	
	StatsChanControlsEnableAll(1)
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
	
		tName = StringFromList(wcnt, wlist)
	
		if (WinType(tName) == 2)
			DoWindow /F $tName
		endif
	
	endfor
	
	Stats2FilterSelect( "Stats1" )
	
	Stats2WSelectDefault()
	
	NMAutoStats()
	
	return 0

End // StatsAllWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsCompute(wName, chanNum, wavNum, win, saveflag, dsplyflag) // compute amps of given wave
	String wName // source wave name ("") for current display wave
	Variable chanNum // channel number (-1) current channel
	Variable wavNum // wave number (-1) current wave
	Variable win // (-1) for all
	Variable saveflag // save to table waves
	Variable  dsplyflag // update channel display graph
	
	Variable acnt, afirst, alast, dFlag, dtFlagLast, smthNumLast, newWave
	String smthAlgLast, waveLast, select, dName, df = StatsDF()
	
	String tName = "ST_WaveTemp"
	
	Variable ampNV = NumVarOrDefault(df+"AmpNV", 0)
	
	Wave dtFlag = $(df+"dtFlag")
	Wave smthNum = $(df+"SmthNum")
	Wave /T smthAlg = $(df+"SmthAlg")
	
	if (chanNum < 0)
		chanNum = NMCurrentChan()
	endif
	
	if (wavNum < 0)
		wavNum = NMCurrentWave()
	endif
	
	if (strlen(wName) == 0)
		wName = ChanWaveName(-1, -1)
	endif
	
	if (win == -1)
		afirst = 0
		alast = numpnts($(df+"AmpSlct"))
	else
		afirst = win
		alast = win + 1
	endif
	
	dtFlagLast = ChanFuncGet(chanNum)
	smthNumLast = ChanSmthNumGet(chanNum)
	smthAlgLast = ChanSmthAlgGet(chanNum)
	waveLast = CurrentChanDisplayWave()

	for (acnt = afirst; acnt < alast; acnt += 1)
	
		select = StatsAmpSelectGet(acnt)
		
		if (StringMatch(select, "Off") == 1)
			continue
		endif
		
		if (dsplyflag == 1)
			dName = CurrentChanDisplayWave()
		else
			dName = tName
		endif
		
		StatsChanControlsEnable(-1, acnt, 1)
		
		newWave = 0
		
		if ((WaveExists($dName) == 0) || (StringMatch(dName, waveLast) == 0))
			newWave = 1
		elseif ((dtFlag[acnt] != dtFlagLast) || (smthNum[acnt] != smthNumLast))
			newWave = 1
		elseif ((smthNum[acnt] > 0) && (StringMatch(smthAlg[acnt], smthAlgLast) == 0))
			newWave = 1
		endif
		
		if (newWave == 1)
			smthNumLast = smthNum[acnt]
			smthAlgLast = smthAlg[acnt]
			dtFlagLast = dtFlag[acnt]
		endif
		
		if ((newWave == 1) && (ChanWaveMake(chanNum, wName, dName) < 0))
			continue
		endif
		
		if (acnt == AmpNV)
			dFlag = 1
		else
			dFlag = 0
		endif
		
		if (StatsComputeWin(acnt, dName, dsplyflag * dFlag) < 0)
			continue // error
		endif
		
		if ((dsplyflag == 1) && (acnt == AmpNV) && (NumVarOrDefault(df+"AutoDoUpdate", 1) == 1))
			DoUpdate // THIS SEEMS TO CAUSE IGOR ERROR: "UpdtDisplay: recursion attempted"
			// fixed with AutoDoUpdate
		endif
	
		if (saveflag == 1)
			StatsAmpSave(chanNum, wavNum, acnt, 0)
		endif
			
	endfor
	
	KillWaves /Z $tName
	
	return 0
		
End // StatsCompute

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsComputeWin(win, wName, dsplyflag) // compute window stats
	Variable win // window number
	String wName // wave to measure
	Variable dsplyflag // update channel display graph
	
	Variable tbgn, tend, ay, ax, by, bx, aybsln, dumvar, offset, off
	String select, dumstr
	
	String df = StatsDF()
	
	Variable drag = NumVarOrDefault(df+"DragOn", 1)
	Variable offsetBsln = NumVarOrDefault(df+"OffsetBsln", 1)
	Variable ampNV = NumVarOrDefault(df+"AmpNV", 0)
	
	if (win < 0)
		win = NumVarOrDefault(df+"AmpNV", 0)
	endif
	
	if (DataFolderExists(df) == 0)
		//DoAlert 0, "StatsComputeWin Error: Stats data folder does not exist."
		return -1 // stats has not been initialized yet
	endif
	
	if (WaveExists($wName) == 0)
		//DoAlert 0, "StatsComputeWin Error: wave " + wName + " does not exist."
		return -1
	endif
	
	if (WavesExist(df+"AmpB;" + df + "ST_DragBYB;") == 0)
		//DoAlert 0, "StatsComputeWin Error: Stats waves do not exist."
		return -1
	endif
	
	Wave AmpB = $(df+"AmpB"); Wave AmpE = $(df+"AmpE")
	Wave AmpY = $(df+"AmpY"); Wave AmpX = $(df+"AmpX")
	
	Wave /T BslnSlct = $(df+"BslnSlct"); Wave Bflag = $(df+"Bflag")
	Wave BslnB = $(df+"BslnB"); Wave BslnE = $(df+"BslnE")
	Wave BslnY = $(df+"BslnY"); Wave BslnX = $(df+"BslnX")
	Wave BslnSubt = $(df+"BslnSubt")
	
	Wave Rflag = $(df+"Rflag"); Wave RiseTm = $(df+"RiseTm")
	Wave RiseBP = $(df+"RiseBP"); Wave RiseEP = $(df+"RiseEP")
	Wave RiseBX = $(df+"RiseBX"); Wave RiseEX = $(df+"RiseEX")
	
	Wave Dflag = $(df+"Dflag"); Wave DcayT = $(df+"DcayT")
	Wave DcayP = $(df+"DcayP"); Wave DcayX = $(df+"DcayX")
	
	Wave ST_PntX = $(df+"ST_PntX"); Wave ST_PntY = $(df+"ST_PntY")
	Wave ST_WinX = $(df+"ST_WinX"); Wave ST_WinY = $(df+"ST_WinY")
	Wave ST_BslnX = $(df+"ST_BslnX"); Wave ST_BslnY = $(df+"ST_BslnY")
	Wave ST_RDX = $(df+"ST_RDX"); Wave ST_RDY = $(df+"ST_RDY")
	
	Wave ST_DragBYB = $(df+"ST_DragBYB"); Wave ST_DragBXB = $(df+"ST_DragBXB")
	Wave ST_DragBYE = $(df+"ST_DragBYE"); Wave ST_DragBXE = $(df+"ST_DragBXE") 
	Wave ST_DragWYB = $(df+"ST_DragWYB"); Wave ST_DragWXB = $(df+"ST_DragWXB")
	Wave ST_DragWYE = $(df+"ST_DragWYE"); Wave ST_DragWXE = $(df+"ST_DragWXE")
	
	offset = max(0, StatsOffsetValue(win))
	
	select = StatsAmpSelectGet(win)
	
	strswitch(select)
		case "Level":
		case "Level+":
		case "Level-":
			break
		default:
			AmpY[win] = Nan
	endswitch
	
	BslnX[win] = Nan; BslnY[win] = Nan;
	AmpX[win] = Nan;
	RiseBX[win] = Nan; RiseEX[win] = Nan;
	RiseTm[win] = Nan;
	DcayX[win] = Nan; DcayT[win] = Nan;
	
	if (StringMatch(select[0,2], "Off") == 1)
		off = 1
	endif
	
	if (dsplyflag == 1)
		ST_BslnX = Nan; ST_BslnY = Nan;
		ST_WinX = Nan; ST_WinY = Nan;
		ST_PntX = Nan; ST_PntY = Nan;
		ST_RDX = Nan; ST_RDY = Nan;
		
		ST_DragBXB = Nan; ST_DragBYB = Nan;
		ST_DragBXE = Nan; ST_DragBYE = Nan;
		ST_DragWXB = Nan; ST_DragWXE = Nan;
	endif
	
	Wave wtemp = $wName
	
	bx = Nan
	by = Nan
	
	// baseline stats
	
	if (Bflag[win] == 1)
	
		if (BslnB[win] > BslnE[win])
			dumvar = BslnE[win] // switch
			BslnE[win] = BslnB[win]
			BslnB[win] = dumvar
		endif
	 
		tbgn = BslnB[win] + offset
		tend = BslnE[win] + offset
		
		if (tbgn < tend)
			ComputeWaveStats(wtemp, tbgn, tend, BslnSlct[win], 0)
			by = NumVarOrDefault("U_ay", Nan)
			bx = NumVarOrDefault("U_ax", Nan)
		endif
		
		BslnY[win] = by
		BslnX[win] = bx
	
	endif
	
	// compute amplitude stats
	
	ax = Nan
	ay = Nan
	
	if (off == 0)
	
		if (AmpB[win] > AmpE[win])
			dumvar = AmpE[win] // switch
			AmpE[win] = AmpB[win]
			AmpB[win] = dumvar
		endif
		
		tbgn = AmpB[win] + offset
		tend = AmpE[win] + offset
		
		ComputeWaveStats(wtemp, tbgn, tend, select, AmpY[win])
		
		ay = NumVarOrDefault("U_ay", Nan)
		ax = NumVarOrDefault("U_ax", Nan)
		
		aybsln = ay - by
	
	endif
	
	// compute rise/decay time stats
	
	strswitch(select)
	
		case "Off":
		case "Avg":
		case "SDev":
		case "Var":
		case "RMS":
		case "Area":
		case "Sum":
		case "Slope":
			break // NOT ALLOWED
		default:
	
		if ((Rflag[win] == 1) && (Bflag[win] == 1))
		
			dumvar = ((RiseBP[win]/100)*aybsln) + by
			FindLevel /Q/R=(ax, tbgn) wtemp, dumvar
		
			if (V_Flag == 0)
				RiseBX[win] =  V_LevelX
			endif
		
			dumvar = ((RiseEP[win]/100)*aybsln) + by
			FindLevel /Q/R=(ax, tbgn) wtemp, dumvar
			
			if (V_Flag == 0)
				RiseEX[win] =  V_LevelX
			endif
			
			RiseTm[win] = RiseEX[win] - RiseBX[win]
		
		endif
		
		// compute decay time stats
		
		if ((Dflag[win] == 1) && (Bflag[win] == 1))
			
			dumvar = ((DcayP[win]/100)*aybsln) + by
			FindLevel /Q/R=(ax, tend) wtemp, dumvar
			
			if (V_Flag == 0)
				DcayX[win] = V_LevelX
			endif
			
			DcayT[win] = DcayX[win] - ax
			
		endif
	
	endswitch
	
	// new FWHM slope functions
	
	strswitch(select)
	
		case "FWHM+":
		case "FWHM-":
		
			if (Bflag[win] == 1)
		
				RiseBX[win] = Nan
			      dumvar = 0.5 * aybsln + by
			      
				FindLevel /Q/R=(ax, tbgn) wtemp, dumvar
			
				if (V_Flag == 0) // use rise-time waves for now
					RiseBX[win] = V_LevelX
				endif
			
				RiseEX[win] =  Nan
				FindLevel /Q/R=(ax, tend) wtemp, dumvar
				
				if (V_Flag == 0)
					RiseEX[win] = V_LevelX
				endif
				
				RiseTm[win] = RiseEX[win] - RiseBX[win]
			
			else
			
				ax = Nan
				ay = Nan
			
			endif
			
	endswitch
	
	// rise-time slope function
	
	if ((Rflag[win] == 1) && (Bflag[win] == 1))
		strswitch(select)
			case "RTSlope+":
			case "RTSlope-":
				dumstr = FindSlope(RiseBX[win], RiseEX[win], wName) // function located in "Utility.ipf"
				ax = str2num(StringByKey("b", dumstr, "="))
				ay = str2num(StringByKey("m", dumstr, "="))
				break
		endswitch
	endif
	
	// save final amp values
	
	if (off == 0)
	
		if ((Bflag[win] == 1) && (BslnSubt[win] == 1))
			AmpY[win] = aybsln
		else
			AmpY[win] = ay
		endif
		
		AmpX[win] = ax
		
		KillVariables /Z U_ax, U_ay
		
		if (win != AmpNV)
			return 0 // do not update display waves
		endif
	
	endif
	
	if (dsplyflag == 0)
		return 0 // no more to do
	endif
	
	// baseline display waves
	
	if (Bflag[win] == 1)
	
		ST_BslnX[0] = BslnB[win] + offset * offsetBsln
		ST_BslnX[1] = BslnE[win] + offset * offsetBsln
		ST_BslnY = by
		
		if (drag == 1)
			ST_DragBXB = ST_BslnX[0]
			ST_DragBXE = ST_BslnX[1]
		endif
	
	endif
	
	if (off == 1)
		return 0 // no more to do
	endif
	
	// amplitude display waves
	
	strswitch(select)
		case "Slope":
		case "RTSlope+":
		case "RTSlope-":
			ST_PntX = Nan
			ST_PntY = Nan
			break
		default:
			ST_PntX = ax
			ST_PntY = ay
	endswitch
	
	// rise/decay time display waves (and FWHM)
	
	if ((Rflag[win] == 1) || (Dflag[win] == 1))
			
		ST_RDX[0] = RiseBX[win]
		ST_RDX[1] = RiseEX[win]
		
		ST_RDX[2] = DcayX[win]
		ST_RDY[2] = ((DcayP[win]/100)*aybsln) + by
		
		strswitch(select)
		
			case "FWHM+":
			case "FWHM-":
				ST_RDY[0] = 0.5 * aybsln + by
				ST_RDY[1] = 0.5 * aybsln + by
				break
				
			default:
				ST_RDY[0] = ((RiseBP[win]/100)*aybsln) + by
				ST_RDY[1] = ((RiseEP[win]/100)*aybsln) + by
				
		endswitch
	
	endif
	
	// update window display line
	
	ST_WinX[0] = AmpB[win] + offset
	ST_WinX[1] = AmpE[win] + offset
	ST_WinY = ay
		
	strswitch(select)
	
		case "Slope":
			ST_WinY[0] = AmpB[win]*ay + ax
			ST_WinY[1] = AmpE[win]*ay + ax
			break
			
		case "RTSlope+":
		case "RTSlope-":
			ST_WinX[0] = RiseBX[win] + offset
			ST_WinX[1] = RiseEX[win] + offset
			ST_WinY[0] = RiseBX[win]*ay + ax
			ST_WinY[1] = RiseEX[win]*ay + ax
			break
			
	endswitch
	
	// update drag waves (ONLY THE X values)
	
	if (drag == 1)
		ST_DragWXB = AmpB[win] + offset
		ST_DragWXE = AmpE[win] + offset
	endif
	
	return 0

End // StatsAmpCompute

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stats result waves/table functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesTables(chanNum, forcenew) // create waves/table where Stats are stored
	Variable chanNum // channel number
	Variable forcenew // force new waves
	
	Variable wcnt
	String tprefix, wname, wlist, title, slctStr = "", tname = ""
	String df = StatsDF(), ndf = NMDF()
	
	Variable NumWaves = NMNumWaves()
	Variable format = NumVarOrDefault(ndf+"NameFormat", 1)
	
	Variable tables = NumVarOrDefault(df+"TablesOn", 1)
	
	Variable overwrite = NMOverWrite()
	
	if (format == 1)
		slctStr = NMWaveSelectStr() + "_"
	endif

	tprefix = StatsPrefix(NMFolderPrefix("") + slctStr + "Table_")
	
	wName = StatsWaveName(Nan, "wName_", chanNum, overwrite)
	
	if ((forcenew == 1) || (WaveExists($wName) == 0))
	
		Make /T/O/N=(NumWaves) $wName
		
		NMNoteType(wName, "Stats Wave Name", "", "", "")
		
		Wave /T tempWave = $wName
		Wave /T ChanWaveList
		
		tempWave = ""
		wlist = ChanWaveList(chanNum)
		
		for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
			tempWave[wcnt] = StringFromList(wcnt,wlist)
		endfor
		
	endif
	
	if (WaveExists($wName) == 1)
		Wave wtemp = $wName
		wtemp = Nan
	endif
	
	wlist = StatsWavesMake(chanNum)
	
	if (tables == 1)
	
		tName = NextGraphName(tprefix, chanNum, overwrite)
	
		if (WinType(tName) == 0)
		
			title = NMFolderListName("") + " : Ch " + ChanNum2Char(chanNum) + " : Stats : " + NMWaveSelectGet()
			
			if (WaveExists($wname) == 1)
		
				DoWindow /K $tName
				Edit /K=1/N=$tName/W=(0,0,0,0) $wName as title
				SetCascadeXY(tName)
				Execute "ModifyTable title(Point)= \"Wave\""
				
			endif
			
		else
		
			DoWindow /F $tName
		
		endif
		
		if (WinType(tName) == 2)
			for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
				wname = StringFromList(wcnt, wlist)
				if (WaveExists($wname) == 1)
					AppendToTable $wname
				endif
			endfor
		endif
	
	endif
	
	return tName

End // StatsWavesTables

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesMake(chanNum)
	Variable chanNum // channel number

	Variable acnt, wselect, offset, xwave = 1
	String wname, header, statsnote, wnote, xl, yl, select, wlist = "", rf = "Rise"
	
	String df = StatsDF()
	
	Variable CurrentChan = NMCurrentChan()
	
	String wPrefix = StrVarOrDefault("CurrentPrefix", "Wave")
	
	String xLabel = ChanLabel(-1, "x", CurrentWaveName())
	String yLabel = ChanLabel(-1, "y", CurrentWaveName())
	
	String xUnits = UnitsFromStr(xLabel)
	String yUnits = UnitsFromStr(yLabel)
	
	if (WaveExists($(df+"WinSelect")) == 1)
		wselect = 1
		Wave WinSelect = $(df+"WinSelect")
	endif

	Wave AmpB = $(df+"AmpB"); Wave AmpE = $(df+"AmpE")
	
	Wave /T BslnSlct = $(df+"BslnSlct")
	Wave Bflag = $(df+"Bflag"); Wave BslnSubt = $(df+"BslnSubt")
	Wave BslnB = $(df+"BslnB"); Wave BslnE = $(df+"BslnE")
	
	Wave Rflag = $(df+"Rflag")
	Wave RiseBP = $(df+"RiseBP"); Wave RiseEP = $(df+"RiseEP")
	
	Wave Dflag = $(df+"Dflag"); Wave DcayP = $(df+"DcayP")
	
	Wave SmthNum = $(df+"SmthNum")
	Wave /T SmthAlg = $(df+"SmthAlg")
	Wave dtFlag = $(df+"dtFlag")
	
	xl = wPrefix + "#"

	for (acnt = 0; acnt < numpnts(AmpB); acnt += 1)
		
		if ((wselect == 1) && (WinSelect[acnt] == 0))
			continue
		endif
		
		select = StatsAmpSelectGet(acnt)
	
		if (StringMatch(select, "Off") == 1)
			continue
		endif
		
		offset = max(0, StatsOffsetValue(acnt))
		
		header = "WPrefix:" + wPrefix
		header += "\rChanSelect:" + ChanNum2Char(chanNum)
		header += "\rWaveSelect:" + NMWaveSelectGet()
		
		statsnote = "\rStats Win:" + num2str(acnt) + ";Stats Alg:" + select + ";"
		statsnote += "Stats Tbgn:" + num2str(AmpB[acnt]+offset) + ";Stats Tend:" + num2str(AmpE[acnt]+offset) + ";"
		
		if (BslnSubt[acnt] == 1)
			statsnote += "\rStats Baselined:yes"
		else
			statsnote += "\rStats Baselined:no"
		endif
		
		if (SmthNum[acnt] > 0)
			statsnote += "\rSmth Alg:" + SmthAlg[acnt] + ";Smth Num:" + num2str(SmthNum[acnt]) + ";"
		endif
		
		if (dtFlag[acnt] == 1)
			statsnote += "\rF(t):d/dt"
		elseif (dtFlag[acnt] == 2)
			statsnote += "\rF(t):dd/dt*dt"
		elseif (dtFlag[acnt] == 3)
			statsnote += "\rF(t):integrate"
		elseif (dtFlag[acnt] == 4)
			statsnote += "\rF(t):norm2max"
		elseif (dtFlag[acnt] == 5)
			statsnote += "\rF(t):norm2min"
		endif
		
		yl = StatsYLabel(select)
		
		wname = StatsWaveMake("AmpY", acnt, chanNum)
		NMNoteType(wName, "NMStats Yvalues", xl, yl, header + statsnote)
		wlist = AddListItem(wname, wlist, ";", inf)
		
		yl = xLabel
		
		strswitch(select)
			case "Avg":
			case "SDev":
			case "Var":
			case "RMS":
			case "Area":
			case "Sum":
				xwave = 0
				break
			case "Slope":
				yl = yLabel // intercept value
				break
		endswitch
		
		if (xwave == 1)
			wname = StatsWaveMake("AmpX", acnt, chanNum)
			NMNoteType(wName, "NMStats Xvalues", xl, yl, header + statsnote)
			wlist = AddListItem(wname, wlist, ";", inf)
		endif
		
		yl = StatsYLabel(BslnSlct[acnt])
		
		if (Bflag[acnt] == 1)
			wname = StatsWaveMake("Bsln", acnt, chanNum)
			wnote = "\rBsln Alg:" + BslnSlct[acnt] + ";Bsln Tbgn:" + num2str(BslnB[acnt]+offset) + ";Bsln Tend:" + num2str(BslnE[acnt]+offset) + ";"
			NMNoteType(wName, "NMStats Bsln", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
		endif
		
		if (Rflag[acnt] == 1)
		
			if (StringMatch(select[0,3], "FWHM") == 1)
				rf = "Fwhm"
			endif
		
			yl = num2str(RiseBP) + " - " + num2str(RiseEP) + "% " + rf + " Time (" + xUnits + ")"

			wname = StatsWaveMake(rf+"T", acnt, chanNum)
			wnote = "\r" + rf + " %bgn:" + num2str(RiseBP) + ";" + rf + " %end:" + num2str(RiseEP) + ";"
			NMNoteType(wName, "NMStats " + rf + " Time", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
			
			yl = num2str(RiseBP) + "% " + rf + " Pnt (" + xUnits + ")"
			
			wname = StatsWaveMake(rf+"BX", acnt, chanNum)
			wnote = "\rRise %bgn:" + num2str(RiseBP)
			NMNoteType(wName, "NMStats " + rf + " Tbgn", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
			
			yl = num2str(RiseEP) + "% " + rf + " Pnt (" + xUnits + ")"
			
			wname = StatsWaveMake(rf+"EX", acnt, chanNum)
			wnote = "\r" + rf + " %end:" + num2str(RiseBP)
			NMNoteType(wName, "NMStats " + rf + " Tend", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
			
		endif
		
		if (Dflag[acnt] == 1)
		
			yl = num2str(DcayP) + "% Decay Time (" + xUnits + ")"
		
			wname = StatsWaveMake("DcayT", acnt, chanNum)
			wnote = "\r%Decay:" + num2str(DcayP)
			NMNoteType(wName, "NMStats DecayTime", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
			
			yl = num2str(DcayP) + "% Decay Pnt (" + xUnits + ")"
			
			wname = StatsWaveMake("DcayX", acnt, chanNum) 
			wnote = "\r%Decay:" + num2str(DcayP)
			NMNoteType(wName, "NMStats DecayPoint", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
			
		endif
		
	endfor
	
	return wlist

End // StatsWavesMake

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWaveMake(fxn, win, chanNum) // create appropriate stats wave
	String fxn
	Variable win
	Variable chanNum
	Variable forcenew // force new waves

	Variable nwaves = NMNumWaves()
	
	String wName = StatsWaveName(win, fxn, chanNum, NMOverWrite())
	
	Make /O/N=(nwaves) $wName = NaN
	
	return wname

End // StatsWaveMake

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWaveName(win, fxn, chanNum, overWrite)
	Variable win
	String fxn
	Variable chanNum
	Variable overWrite
	
	String chanStr = "", slctStr = ""
	
	Variable format=NumVarOrDefault(NMDF() + "NameFormat", 1)
	
	if (numtype(win) == 0)
		chanStr = num2str(win) + "_"
	endif
	
	strswitch(fxn)
		case "AmpX":
			fxn = StatsAmpName(win) + "X"
			break
		case "AmpY":
			fxn = StatsAmpName(win)+ "Y"
			break
	endswitch
	
	if (format == 1)
		slctStr = NMWaveSelectStr() + "_"
	endif
	
	String wPrefix = StatsPrefix(fxn + chanStr + slctStr)
	
	return NextWaveName("", wPrefix, chanNum, overWrite)

End // StatsWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsAmpName(win)
	Variable win
	
	String fxn = StatsAmpSelectGet(win)
	
	strswitch(fxn)
		case "Level":
		case "Level+":
		case "Level-":
			fxn = "Lvl"
			break
		case "Slope":
		case "RTSlope+":
		case "RTSlope-":
			fxn = "Slp"
			break
		case "FWHM+":
			fxn = "Max"
			break
		case "FWHM-":
			fxn = "Min"
			break
		case "Off":
			return ""
	endswitch
	
	return fxn

End // StatsAmpName

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmpSave(chanNum, wavNum, win, clear) // save results to appropriate Stat waves
	Variable chanNum // channel number
	Variable wavNum // wave number
	Variable win // stats window
	Variable clear // clear option (0 - save; 1 - clear)
	
	//print chanNum, wavNum, win, clear
	
	String wName
	String select, wselect = NMWaveSelectGet(), rf = "Rise"
	String df = StatsDF()
	
	Variable Nameformat=NumVarOrDefault(NMDF() + "NameFormat", 1)
	
	Wave AmpY = $(df+"AmpY"); Wave AmpX = $(df+"AmpX")
	
	Wave BslnY = $(df+"BslnY"); Wave Bflag = $(df+"Bflag")
	
	Wave RiseBX = $(df+"RiseBX"); Wave RiseEX = $(df+"RiseEX")
	Wave RiseTm = $(df+"RiseTm"); Wave Rflag = $(df+"Rflag")
	
	Wave DcayX = $(df+"DcayX"); Wave DcayT = $(df+"DcayT")
	Wave Dflag = $(df+"Dflag")
	
	select = StatsAmpSelectGet(win)
	
	if (StringMatch(select, "Off") == 1)
		return 0
	endif
	
	if (clear == 1)
		clear = Nan
	else
		clear = 1
	endif
	
	wName = StatsWaveName(win, "AmpY", chanNum, 1)
	
	if (WaveExists($wName) == 1)
		Wave ST_AmpY = $wName
		ST_AmpY[wavNum] = AmpY[win]*clear
	endif
	
	wName = StatsWaveName(win, "AmpX", chanNum, 1)

	if (WaveExists($wName) == 1)
		Wave ST_AmpX = $wName
		ST_AmpX[wavNum] = AmpX[win]*clear
	endif

	if (Bflag[win] == 1)
	
		wName = StatsWaveName(win, "Bsln", chanNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_Bsln = $wName 
			ST_Bsln[wavNum] = BslnY[win]*clear
		endif
		
	endif
		
	if (Rflag[win] == 1)
	
		if (StringMatch(select[0,3], "FWHM") == 1)
			rf = "Fwhm"
		endif
	
		wName = StatsWaveName(win, rf + "BX", chanNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_RiseBX = $wName
			ST_RiseBX[wavNum] = RiseBX[win]*clear
		endif
		
		wName = StatsWaveName(win, rf + "EX", chanNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_RiseEX = $wName
			ST_RiseEX[wavNum] = RiseEX[win]*clear
		endif
		
		wName = StatsWaveName(win, rf + "T", chanNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_RiseT = $wName
			ST_RiseT[wavNum] = RiseTm[win]*clear
		endif
		
	endif
		
	if (Dflag[win] == 1)
	
		wName = StatsWaveName(win, "DcayX", chanNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_DcayX = $wName
			ST_DcayX[wavNum] = DcayX[win]*clear
		endif
		
		wName = StatsWaveName(win, "DcayT", chanNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_DcayT = $wName
			ST_DcayT[wavNum] = DcayT[win]*clear
		endif
		
	endif

End // StatsAmpSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsYLabel(select)
	String select
	
	String yl = ChanLabel(-1, "y", CurrentWaveName())
	String xl = ChanLabel(-1, "x", CurrentWaveName())
	
	String yunits = UnitsFromStr(yl)
	String xunits = UnitsFromStr(xl)
	
	strswitch(select)
		case "SDev":
			return "Stdv (" + yunits + ")"
		case "Var":
			return "Variance (" + yunits + "^2)"
		case "RMS":
			return "RMS (" + yunits + ")"
		case "Area":
			return "Area (" + yunits + " * " + xunits + ")"
		case "Sum":
			return "Sum (" + yunits + " * " + xunits + ")"
		case "Slope":
			return "Slope (" + yunits + " / " + xunits + ")"
	endswitch
	
	return yl
	
End // StatsYLabel

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Stats2 Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2WSelectDefault()
	String wname, df = StatsDF()
	
	//if (strlen(StrVarOrDefault(df+"ST_2WaveSlct", "")) > 0)
		//return 0
	//endif
	
	Variable cChan = NMCurrentChan()
	Variable win = NumVarOrDefault(df+"AmpNV", 0)
	
	wname = StatsWaveName(win, "AmpY", cChan, 1)
	
	String wlist = WaveList(wname, ";", WaveListText0())
	
	Stats2WSelect(StringFromList(0,wlist))

End // Stats2WSelectDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2AllCall()

	NMCmdHistory("Stats2All", "")
	return Stats2All()

End // Stats2AllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2All()
	Variable icnt, nwaves
	String saveName, tName, wList = Stats2WSelectList(""), df = StatsDF()
	
	SVAR ST_2WaveSlct = $(df+"ST_2WaveSlct")
	
	saveName = ST_2WaveSlct
	
	nwaves = ItemsInList(wList)
	tName = Stats2Table(1)
	
	for (icnt = 0; icnt < nwaves; icnt += 1)
		ST_2WaveSlct = StringFromList(icnt, wList)
		Stats2Compute()
		Stats2Save()
	endfor
	
	// back to original wave
	
	ST_2WaveSlct = saveName
	UpdateStats2()
	
	return tName
	
End // Stats2All

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2Compute() // compute AVG, SDV and SEM of Stats2 wave
	Variable icnt
	
	String df = StatsDF()
	
	if (DataFolderExists(StatsDF()) == 0)
		return 0 // stats has not been initialized yet
	endif
	
	NVAR ST_2AVG = $(df+"ST_2AVG")
	NVAR ST_2SDV = $(df+"ST_2SDV")
	NVAR ST_2SEM = $(df+"ST_2SEM")
	NVAR ST_2CNT = $(df+"ST_2CNT")
	
	SVAR ST_2WaveSlct = $(df+"ST_2WaveSlct")
	
	ST_2CNT = Nan
	ST_2AVG = Nan
	ST_2SDV = Nan
	ST_2SEM = Nan
	
	SetNMvar(df+"ST_2Min", Nan)
	SetNMvar(df+"ST_2Max", Nan)
	
	if (WaveExists($ST_2WaveSlct) == 0)
		return 0 // wave does not exist
	endif
	
	Wave ST_Stats2Wave = $(df+"ST_Stats2Wave")
	Wave tempWave = $ST_2WaveSlct
	Wave WavSelect
	
	Redimension /N=(numpnts(tempWave)) ST_Stats2Wave
	
	ST_Stats2Wave = tempWave
	
	Note /K ST_Stats2Wave
	Note ST_Stats2Wave, note(tempWave)
	
	WaveStats /Q ST_Stats2Wave
		
	ST_2CNT = V_npnts
		
	if (ST_2CNT > 0)
		ST_2AVG = V_avg
		ST_2SDV = V_sdev
		ST_2SEM = V_sdev/sqrt(V_npnts)
		SetNMvar(df+"ST_2Min", V_min)
		SetNMvar(df+"ST_2Max", V_max)
	endif

End // Stats2Compute

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2WSelectCall(wName)
	String wName
	
	strswitch(wName)
		case "---":
			return wName
		case "Change This List":
			Stats2FilterSelectCall()
			return wName
	endswitch
	
	NMCmdHistory("Stats2WSelect", NMCmdStr(wName, ""))
	
	return Stats2WSelect(wName)
	
End // Stats2WSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2WSelect(wName)
	String wName

	String df = StatsDF()
	
	Variable plotOn = NumVarOrDefault(df+"AutoPlot", 0)
	
	if ((strlen(wName) > 0) && (WaveExists($wName) == 0))
		wName = ""
	endif
	
	SetNMstr(df+"ST_2WaveSlct", wName)
	
	if ((strlen(wName) > 0) && (plotOn == 1))
		StatsPlot(wName)
	endif
	
	UpdateStats2()
	
	return wName
	
End // Stats2WSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2WSelectList(select) // create Stats2 wave list
	String select // ("") for current selection

	Variable icnt, wnum = -1
	String numstr, wName, remList = "", wList = "", wList2 = ""
	String df = StatsDF()
	
	String opstr = WaveListText0()
	
	if (strlen(select) == 0)
		select = StrVarOrDefault(df+"ST_2StrMatch", "ST_*")
	endif
	
	remList = WaveList("*Offset*", ";", opstr)
	
	strswitch(select[0,2])
	
		case "All":
			wList = WaveList("ST_*", ";", opstr) + WaveList("ST2_*", ";", opstr)
			wnum = -2
			break
			
		case "Win":
			
			wnum = str2num(select[3,inf])
		
			if (numtype(wnum) > 0)
				return "" // error
			endif
			
			break
			
		case "":
			return ""
	
	endswitch
	
	if (wnum == -1)
	
		wList = WaveList(select, ";", opstr)
	
	elseif (wnum >= 0)
	
		wList = WaveList("ST_*", ";", opstr)
	
		numstr = num2str(wnum) + "_*"
		
		for (icnt = 0; icnt < ItemsInList(wList); icnt += 1)
		
			wName = StringFromList(icnt, wList)
			
			if (StringMatch(wname, "ST_Bsln"+numstr) == 1)
				wList2 = AddListItem(wname, wList2, ";", inf)
			elseif (StringMatch(wname, "ST_*X"+numstr) == 1)
				wList2 = AddListItem(wname, wList2, ";", inf)
			elseif (StringMatch(wname, "ST_*Y"+numstr) == 1)
				wList2 = AddListItem(wname, wList2, ";", inf)
			elseif (StringMatch(wname, "ST_RiseT"+numstr) == 1)
				wList2 = AddListItem(wname, wList2, ";", inf)
			elseif (StringMatch(wname, "ST_DcayT"+numstr) == 1)
				wList2 = AddListItem(wname, wList2, ";", inf)
			endif
			
		endfor
		
		wList = wList2

	endif
	
	strswitch(select[0,2])
		case "Win":
		case "ST_":
			remList += WaveList("ST_*Hist*", ";", opstr) + WaveList("ST_*Sort*", ";", opstr)
			remList += WaveList("ST_*Stb*", ";", opstr) + WaveList("ST_*Stable*", ";", opstr)
			break
		case "ST2":
			wList += WaveList("ST_*Hist*", ";", opstr) + WaveList("ST_*Sort*", ";", opstr)
			wList += WaveList("ST_*Stb*", ";", opstr) + WaveList("ST_*Stable*", ";", opstr)
			break
	endswitch
	
	wList = RemoveListFromList(remList, wlist, ";")
	
	//if ((WhichListItem(ST_2WaveSlct, wList) < 0) && (WaveExists($ST_2WaveSlct) == 1))
	//	wList += ST_2WaveSlct + ";"
	//endif
	
	return wList
	
End // Stats2WSelectList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2FilterSelectList()

	return "All;Stats1;Stats2;" + StatsWinList(1) + "Any;Other;"

End // Stats2FilterSelectList

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2FilterSelectCall()
	String sdf = StatsDF()
	String select = StrVarOrDefault(sdf+"Stats2WaveSelect", "Stats1")
	
	Prompt select, "", popup Stats2FilterSelectList()
	DoPrompt "Stats2 Wave Select", select
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMstr(sdf+"Stats2WaveSelect", select)
	
	NMCmdHistory("Stats2FilterSelect", NMCmdStr(select, ""))
	
	return Stats2FilterSelect(select)

End // Stats2FilterSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2FilterSelect(select)
	String select
	
	String df = StatsDF()
	
	String strmatch = StrVarOrDefault(df+"ST_2StrMatch", "ST_*")
	
	strswitch(select)
	
		case "All":
			SetNMstr(df+"ST_2StrMatch", "All")
			break
	
		case "Stats1":
			SetNMstr(df+"ST_2StrMatch", "ST_*")
			break
			
		case "Stats2":
			SetNMstr(df+"ST_2StrMatch", "ST2_*")
			break
			
		case "Hist":
			SetNMstr(df+"ST_2StrMatch", "ST_*Hist*")
			break
			
		case "Sort":
			SetNMstr(df+"ST_2StrMatch", "ST_*Sort*")
			break
			
		case "Any":
			SetNMstr(df+"ST_2StrMatch", "*")
			break
			
		case "Other":
		
			Prompt strmatch, "enter new wave match string:"
			DoPrompt "Stats2 Wave Select", strmatch
			
			if (V_flag == 1)
				return 0 // cancel
			endif
			
			if (strsearch(strmatch, "*", 0) < 0)
				strmatch += "*" // put "*" at end of string
			endif
			
			SetNMstr(df+"ST_2StrMatch", strmatch)
			
			break
			
		default:
		
			if (StringMatch(select[0,2], "Win") == 1)
				SetNMstr(df+"ST_2StrMatch", select)
			else
				select = "Stats1"
				SetNMstr(df+"ST_2StrMatch", "ST_*")
			endif
			
	endswitch
	
	SetNMstr(df+"ST_2MatchSlct", select)
	
	//UpdateStats2()
	
	return 0
	
End // Stats2FilterSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2Display() // NO LONGER USED

	String df = StatsDF()
	
	String ggName, gName = "ST_Stats2Wave_Plot"

	String ST_2WaveSlct = StrVarOrDefault(df+"ST_2WaveSlct", "")
	
	String gTitle = "Stats2 : " + ST_2WaveSlct
	
	if (WinType(gName) == 0)
		StatsPlot(df+"ST_Stats2Wave")
	endif
	
	DoWindow /F $gName
	DoWindow /C $gName
	DoWindow /T $gName, gTitle

End // Stats2Display

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2SaveCall()

	NMCmdHistory("Stats2Save", "")
	return Stats2Save()

End // Stats2SaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2Save()
	Variable npnts
	String tName, df = StatsDF()

	NVAR ST_2AVG =  $(df+"ST_2AVG")
	NVAR ST_2SDV =  $(df+"ST_2SDV")
	NVAR ST_2SEM =  $(df+"ST_2SEM")
	NVAR ST_2CNT =  $(df+"ST_2CNT")
	
	SVAR ST_2WaveSlct = $(df+"ST_2WaveSlct")
	
	if (StringMatch(ST_2WaveSlct, "Off") == 1)
		return ""
	endif

	tName = Stats2Table(0)
	
	Wave ST2_AVG, ST2_SDV, ST2_SEM, ST2_CNT, ST2_Min, ST2_Max
	Wave /T ST2_wName
	
	npnts = numpnts(ST2_wName) + 1
	
	Redimension /N=(npnts) ST2_wName, ST2_AVG, ST2_SDV, ST2_SEM, ST2_CNT, ST2_Min, ST2_Max
	
	ST2_wName[npnts-1] = ST_2WaveSlct
	ST2_AVG[npnts-1] = ST_2AVG
	ST2_SDV[npnts-1] = ST_2SDV
	ST2_SEM[npnts-1] = ST_2SEM
	ST2_CNT[npnts-1] = ST_2CNT
	ST2_Min[npnts-1] = NumVarOrDefault(df+"ST_2Min", Nan)
	ST2_Max[npnts-1] = NumVarOrDefault(df+"ST_2Max", Nan)
	
	return tName
	
End // Stats2Save

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2Table(force) // create waves/table where Stats2 are stored
	Variable force // force make table
	
	String df = StatsDF()
	
	String filter = StrVarOrDefault(df+"ST_2MatchSlct", "")
	
	String tPrefix = "ST2_" + NMFolderPrefix("") + filter + "_Table"
	String tName = NextGraphName(tPrefix, -1, NMOverWrite())
	String titlestr = NMFolderListName("") + " : Stats2 Table"
	
	if ((WinType(tName) == 2) && (force == 0))
		DoWindow /F $tName
		return tName // table already exists
	endif
	
	Make /T/O/N=0 ST2_wName
	Make /O/N=0 ST2_AVG = Nan
	Make /O/N=0 ST2_SDV = Nan
	Make /O/N=0 ST2_SEM = Nan
	Make /O/N=0 ST2_CNT = Nan
	Make /O/N=0 ST2_Min = Nan
	Make /O/N=0 ST2_Max = Nan
	
	NMNoteType("ST2_wName", "Stats2 Wave Name", "", "", "")
	NMNoteType("ST2_AVG", "Stats2 Avg", "", "", "")
	NMNoteType("ST2_SDV", "Stats2 Sdv", "", "", "")
	NMNoteType("ST2_SEM", "Stats2 SEM", "", "", "")
	NMNoteType("ST2_CNT", "Stats2 Count", "", "", "")
	NMNoteType("ST2_Min", "Stats2 Min", "", "", "")
	NMNoteType("ST2_Max", "Stats2 Max", "", "", "")

	DoWindow /K $tName
	Edit /K=1/W=(0,0,0,0) ST2_wName, ST2_AVG, ST2_SDV, ST2_SEM, ST2_CNT, ST2_Min, ST2_Max as titlestr
	DoWindow /C $tName
	SetCascadeXY(tName)
	Execute "ModifyTable title(Point)= \"Save\""
	Execute "ModifyTable width(ST2_wName)=110"
	
	return tName
	
End // Stats2Table

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsPlotAutoCall()
	String sdf = StatsDF()
	Variable on = 1 + NumVarOrDefault(sdf+"AutoPlot", 1)
	
	Prompt on, "", popup "off;on;"
	DoPrompt "Stats2 Auto Plot", on
			
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	on -= 1
	
	NMCmdHistory("StatsPlotAuto", NMCmdNum(on,""))
	
	return StatsPlotAuto(on)
	
End // StatsPlotAutoCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsPlotAuto(on)
	Variable on // (0) no (1) yes
	
	SetNMVar(StatsDF()+"AutoPlot", BinaryCheck(on))
	UpdateStats2()
	
	return on
	
End // StatsPlotAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsPlotCall() // plot a Stats1 wave

	String wName = StrVarOrDefault(StatsDF()+"ST_2WaveSlct", "")
	
	NMCmdHistory("StatsPlot", NMCmdStr(wName,""))
	
	return StatsPlot(wName)
	
End // StatsPlotCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsPlot(wName) // plot a Stats1 wave
	String wName // stats wave name
	
	if (WaveExists($wName) == 0)
		return ""
	endif
	
	Variable tbgn, tend
	String alg = "", txt = ""
	
	String pName = GetPathName(wName, 0)
	String gTitle = NMFolderListName("") + " : " + pName
	String gPrefix = pName + "_" + NMFolderPrefix("") + "Plot"
	String gName = NextGraphName(gPrefix, -1, NMOverWrite())
	
	String type = NMNoteStrByKey(wName, "Type")
	String ft = NMNoteStrByKey(wName, "F(t)")
	String smtha = NMNoteStrByKey(wName, "Smth Alg")
	Variable smthn = NMNoteVarByKey(wName, "Smth Num")
	
	String xLabel = NMNoteStrByKey(wName, "XLabel")
	String yLabel = NMNoteStrByKey(wName, "YLabel")
	
	if (strlen(xLabel) == 0)
		xLabel = "Wave#"
	endif
	
	if (strlen(yLabel) == 0)
		yLabel = wName
	endif
	
	strswitch(type)
	
		default:
			alg = NMNoteStrByKey(wName, "Stats Alg")
			tbgn = NMNoteVarByKey(wName, "Stats Tbgn")
			tend = NMNoteVarByKey(wName, "Stats Tend")
			break
			
		case "NMStats Bsln":
			alg = "Bsln " + NMNoteStrByKey(wName, "Bsln Alg")
			tbgn = NMNoteVarByKey(wName, "Bsln Tbgn")
			tend = NMNoteVarByKey(wName, "Bsln Tend")
			break
			
	endswitch
	
	txt = alg + " ("
	
	txt += num2str(tbgn) + " to " + num2str(tend) + " ms"
	
	if (strlen(ft) > 0)
		txt += ";" + ft
	endif
	
	if (strlen(smtha) > 0)
		txt += ";" + smtha + " smooth,N=" + num2str(smthn)
	endif
	
	txt += ")"
	
	if (WinType(gName) == 0)
		Display /K=1/W=(0,0,0,0) $wName as gTitle
		DoWindow /C $gName
		SetCascadeXY(gName)
	endif
	
	if (WinType(gName) == 0)
		return ""
	endif
	
	DoWindow /F $gName
	
	Label bottom xLabel
	Label left yLabel
	ModifyGraph mode=4,marker=19, standoff=0, rgb=(0,0,0)
	
	if (strlen(txt) > 3)
		TextBox /C/N=stats2title/F=2/E=1/A=MT txt
	endif
	
	return gName

End // StatsPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsEditCall()

	String wName = StrVarOrDefault(StatsDF()+"ST_2WaveSlct", "")
	
	NMCmdHistory("StatsEdit", NMCmdStr(wName,""))
	
	return StatsEdit(wName)
	
End // StatsEditCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsEdit(wName) // edit a Stats1 wave
	String wName // stats wave name
	
	if (WaveExists($wName) == 0)
		return ""
	endif
	
	String pName = GetPathName(wName, 0)
	String title = NMFolderListName("") + " : " + pName
	String tPrefix = pName + "_" + NMFolderPrefix("") + "Table"
	String tName = NextGraphName(tPrefix, -1, NMOverWrite())
	
	if (WinType(tName) == 0)
		Edit /K=1/W=(0,0,0,0) $wName as title
		DoWindow /C $tName
		SetCascadeXY(tName)
	endif
	
	return tName

End // StatsEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsSortCall()
	String vlist = "", df = StatsDF()
	
	String wName = StrVarOrDefault(df+"ST_2WaveSlct", "")
	
	vlist = NMCmdStr(wName, vlist)
	NMCmdHistory("StatsSort", vlist)
	
	return StatsSortWave(wName)
	
End // StatsSortCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsSort(wName, wSelect) // NO LONGER USED
	String wName // stats wave name
	Variable wSelect // wave select (0) off (1) on
	
	String gName, sName, ssName, gTitle, df = StatsDF()
	
	Variable overWrite = NMOverWrite()
	
	if (wSelect == 0)
		return StatsSortWave(wName)
	endif
	
	gName = StatsSortWave(df+"ST_Stats2Wave")
	
	if ((strlen(gName) == 0) || (WinType(gName) == 0))
		return ""
	endif
	
	sName = NextWaveName("", "ST_Stats2Wave_Sort", -1, 1)
	ssName = NextWaveName("", wName + "_Sort", -1, overWrite)
	gTitle = "Sort : " + wName + " : " +  NMWaveSelectGet()
	
	DoWindow /T $gName, gTitle
	Duplicate /O $sName, $ssName
	AppendToGraph $ssName
	RemoveFromGraph $sName
	ModifyGraph mode=3,marker=19, nticks(left)=2
	KillWaves /Z $sName
	NMHistory("Sort results saved in wave '" + ssName + "'")
	
	return gName

End // StatsSort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsSortWave(wName)
	String wName // stats wave name
	
	String gPrefix, gName, gtitle, df = StatsDF()
	String mthd, dName, pName = GetPathName(wname, 0)
	Variable method, xv, nv, yv, success
	Variable overwrite = NMOverWrite()
	
	NVAR ST_2AVG =  $(df+"ST_2AVG")
	NVAR ST_2SDV =  $(df+"ST_2SDV")
	
	SVAR ST_2WaveSlct = $(df+"ST_2WaveSlct")
	
	if (WaveExists($wName) == 0)
		Abort "Abort: wave \"" +  wName + "\" does not exist."
	endif
	
	Prompt method, "choose sorting method for wave value [a] defined as 'true' (1):", popup "[a] > x;[a] > x - n*y;[a] < x;[a] < x + n*y;x < [a] < y;x - n*y < [a] < x + n*y"
	Prompt xv, "x value: "
	Prompt yv, "y value:"
	Prompt nv, "n value:"
	
	DoPrompt "Sort wave: " + pName, method
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	xv = ST_2AVG
	yv = ST_2SDV
	nv = 1
	
	switch(method)
		case 1:
			DoPrompt "[a] > x", xv
			mthd = "[a] > x; x = " + num2str(xv)
			break
		case 2:
			DoPrompt "[a] > x - n*y", xv, nv, yv
			mthd = "[a] > x - n*y; x = " + num2str(xv) + "; y = " + num2str(yv) + "; n = " + num2str(nv)
			break
		case 3:
			DoPrompt "[a] < x", xv
			mthd = "[a] < x; x = " + num2str(xv)
			break
		case 4:
			DoPrompt "[a] < x + n*y", xv, nv, yv
			mthd = "[a] < x + n*y; x = " + num2str(xv) + "; y = " + num2str(yv) + "; n = " + num2str(nv)
			break
		case 5:
			DoPrompt "x < [a] < y", xv, yv
			mthd = "x < [a] < y; x = " + num2str(xv) + "; y = " + num2str(yv)
			break
		case 6:
			DoPrompt "x - n*y < [a] < x + n*y", xv, nv, yv
			mthd = "x - n*y < [a] < x + n*y; x = " + num2str(xv) + "; y = " + num2str(yv) + "; n = " + num2str(nv)
			break
	endswitch
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	dName = NextWaveName("", pName + "_Sort", -1, overwrite)
	gPrefix = pName + "_" + NMFolderPrefix("") + "Sort"
	gName = NextGraphName(gPrefix, -1, overwrite)
	gTitle = NMFolderListName("") + " : " + wName + " : " + mthd
	
	success = SortWave(wName, dName, method, xv, yv, nv) // function located in "Utility.ipf"
	
	DoWindow /K $gName
	
	Display /K=1/W=(0,0,0,0) $dName as gtitle
	DoWindow /C $gName
	SetCascadeXY(gName)
	ModifyGraph mode=3,marker=19, nticks(left)=2, standoff=0
	Label bottom NMNoteLabel("x", dName, "Wave#")
	Label left NMNoteLabel("y", dName, "True(1) / False(0)")
	
	SetAxis left 0,1
	
	NMHistory(mthd + "; successes = " + num2str(success))
	
	NMWaveSelectAdd(dName)
	
	return gName

End // StatsSortWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsHistoCall()
	String vlist = "", df = StatsDF()
	
	String wName = StrVarOrDefault(df+"ST_2WaveSlct", "")
	//Variable wSelect = NumVarOrDefault(df+"WavSelectOn", 0)
	
	vlist = NMCmdStr(wName, vlist)
	//vlist = NMCmdNum(wSelect, vlist)
	NMCmdHistory("StatsHistogram", vlist)
	
	return StatsHisto(wName)
	
End // StatsHistoCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsHistogram(wname, wSelect) // NO LONGER USED
	String wname
	Variable wSelect // wave select (0) off (1) on
	
	String xl, yl, gName, ggTitle, hhName, hName, oldnote, df = StatsDF()
	
	Variable overWrite = NMOverWrite()
	
	if (wSelect == 0)
		return StatsHisto(wName)
	endif 
	
	gName = StatsHisto(df+"ST_Stats2Wave")
	
	if ((strlen(gName) == 0) || (WinType(gName) == 0))
		return ""
	endif
	
	hName = NextWaveName("", "ST_Stats2Wave_Hist", -1, 1)
	hhName = NextWaveName("", wName + "_Hist", -1, overWrite)
	ggTitle = "Histo" + " : " + wName + " : " +  NMWaveSelectGet()
	
	Duplicate /O $hName, $hhName
	
	xl = NMNoteLabel("y", wName, "")
	yl = "Count"
	
	NMNoteType(hhName, "Stats Histo", xl, yl, "Func:StatsHistogram")
	Note $hhName, "Histo Wave:" + wName
	
	AppendToGraph /W=$gName $hhName
	RemoveFromGraph /W=$gName $hName
	ModifyGraph /W=$gName standoff=0, rgb=(0,0,0), mode=5, hbFill=2
	DoWindow /T $gName, ggTitle
	KillWaves /Z $hName
	
	return gName

End // StatsHistogram

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsHisto(wName)
	String wName // stats wave name
	
	Variable range, npnts, vmin, binsize = 1
	String xl, yl, dName, gPrefix, gName, gTitle, pName = GetPathName(wname, 0)
	
	Variable overWrite = NMOverWrite()
	
	if (WaveExists($wName) == 0)
		Abort "Abort: wave \"" +  wName + "\" does not exist."
	endif
	
	Wavestats /Q $wName
	
	range = abs(V_max - V_min)
	
	if (range > 100)
		binsize = 10
	elseif (range > 10)
		binsize = 1
	elseif (range > 1)
		binsize = 0.1
	elseif (range > 0.1)
		binsize = 0.01
	else
		binsize = 0.001
	endif
	
	Prompt binsize, "enter bin size:"
	DoPrompt "Compute Histogram", binsize
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	gPrefix = pName + "_" + NMFolderPrefix("") + "Histo"
	gName = NextGraphName(gPrefix, -1, overWrite)
	dName = NextWaveName("", pName+"_Hist", -1, overWrite)
	gTitle = NMFolderListName("") + " : " + wName + " Histogram"
	
	Wavestats /Q $wName
	
	if (V_npnts < 1)
		return ""
	endif
	
	npnts = ceil(range/binsize) + 4
	vmin = floor(V_min/binsize)*binsize - 2*binsize
	
	Make /O/N=1 $dName
	
	xl = NMNoteLabel("y", wName, "")
	yl = "Count"
	
	NMNoteType(dName, "Stats Histo", xl, yl, "Func:StatsHisto")
	Note $dName, "Histo Wave:" + wName
	
	Histogram /B={vmin,binsize,npnts} $wName, $dName
	
	DoWindow /K $gName
	Display /K=1/W=(0,0,0,0) $dName as gTitle
	DoWindow /C $gName
	SetCascadeXY(gName)
	Label bottom xl
	Label left yl
	ModifyGraph standoff=0, rgb=(0,0,0), mode=5, hbFill=2
	
	return gName

End // StatsHisto

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsStabilityCall()
	String vlist = "", df = StatsDF()
	
	String wName = StrVarOrDefault(df+"ST_2WaveSlct", "")
	Variable wSelect = 0 // NumVarOrDefault(df+"WavSelectOn", 0)
	
	vlist = NMCmdStr(wName, vlist)
	vlist = NMCmdNum(wSelect, vlist)
	NMCmdHistory("StatsStability", vlist)
	
	Execute "NMStabilityStats(\"" + wName + "\"," + num2str(wSelect) + ")"
	
	return ""
	
End // StatsStabilityCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsDeleteNANsCall()
	String wName = StrVarOrDefault(StatsDF()+"ST_2WaveSlct", "")
	
	NMCmdHistory("StatsDeleteNANs", NMCmdStr(wName,""))
	return StatsDeleteNANs(wName)

End // StatsDeleteNANsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsDeleteNANs(wName)
	String wName

	String df = StatsDF(), oname = "ST2_" + wName
			
	if (StringMatch(wName[0,2], "ST_") == 1)
		oname = "ST2_" + wName[3,inf]
	elseif (StringMatch(wName[0,3], "ST2_") == 1)
		oname = "ST3_" + wName[4,inf]
	else
		oname = "ST2_" + wName
	endif
	
	DeleteNANs(df+"ST_Stats2Wave", oname, 0)
	
	NMHistory("Delete NANs output wave: " + oname)
	
	return oname
	
End // StatsDeleteNANs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesEditCall()
	String sdf = StatsDF()
	String select = StrVarOrDefault(sdf+"StatsWavesEdit", "Stats1")
	
	Prompt select, "select Stats waves to edit:", popup "All;Stats1;Stats2;" + StatsWinList(1)
	DoPrompt "Stat Waves Table", select
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(sdf+"StatsWavesEdit", select)
	
	NMCmdHistory("StatsWavesEdit", NMCmdStr(select, ""))
	
	return StatsWavesEdit(select)

End // StatsWavesEditCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesEdit(select)
	String select
	String wList = "", tName = "", title = ""

	strswitch(select)
		case "Current":
			wList = Stats2WSelectList("")
			break
		case "Stats1":
			wList = Stats2WSelectList("ST_*")
			break
		case "Stats2":
			wList = Stats2WSelectList("ST2_*")
			break
		default:
			wList = Stats2WSelectList(select)
	endswitch
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
		
	title = NMFolderListName("") + " : Stats Waves : " + select
	
	tName = NextGraphName("ST_Table_" + select, -1, 1)
	
	EditWaves(tName, title, wList)
	
	return wList

End // StatsWavesEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesKillCall()
	String sdf = StatsDF()
	String select = StrVarOrDefault(sdf+"StatsWavesKill", "Stats1")
	
	Prompt select, "select Stats waves to kill:", popup "All;Stats1;Stats2;" + StatsWinList(1)
	DoPrompt "Kill Stat Waves", select
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(sdf+"StatsWavesKill", select)
	
	NMCmdHistory("StatsWavesKill", NMCmdStr(select, ""))
	
	return StatsWavesKill(select)

End // StatsWavesKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesKill(select)
	String select
	String wlist = ""

	strswitch(select)
		case "Current":
			wlist = Stats2WSelectList("")
			break
		case "Stats1":
			wlist = Stats2WSelectList("ST_*")
			break
		case "Stats2":
			wlist = Stats2WSelectList("ST2_*")
			break
		default:
			wlist = Stats2WSelectList(select)
	endswitch
	
	if (ItemsInList(wlist) == 0)
		return ""
	endif
	
	DeleteWaves(wList)
	
	return wList

End // StatsWavesKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsPrintNamesCall()
	String sdf = StatsDF()
	String select = StrVarOrDefault(sdf+"StatsPrintNames", "Stats1")
	
	Prompt select, "select Stats waves:", popup "All;Stats1;Stats2;" + StatsWinList(1)
	DoPrompt "Print Wave Names", select
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(sdf+"StatsPrintNames", select)
	
	NMCmdHistory("StatsPrintNames", NMCmdStr(select, ""))
	
	return StatsPrintNames(select)

End // StatsPrintNamesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsPrintNames(select)
	String select
	String wlist = ""

	strswitch(select)
		case "Current":
			wlist = Stats2WSelectList("")
			break
		case "Stats1":
			wlist = Stats2WSelectList("ST_*")
			break
		case "Stats2":
			wlist = Stats2WSelectList("ST2_*")
			break
		default:
			wlist = Stats2WSelectList(select)
	endswitch
	
	if (ItemsInList(wlist) == 0)
		return ""
	endif
	
	NMHistory(wList)
	
	return wList

End // StatsPrintNames

//****************************************************************
//****************************************************************
//****************************************************************

Function XTimes2Stats() : GraphMarquee // use marquee x-values for stats t_beg and t_end
	String df = StatsDF()
	
	if ((DataFolderExists(df) == 0) || (IsCurrentNMTab("Stats") == 0))
		return 0 
	endif

	GetMarquee left, bottom
	
	if (V_Flag == 0)
		return 0
	endif
	
	Variable win = NumVarOrDefault(df+"AmpNV", 0)
	
	Wave AmpB = $(df+"AmpB")
	Wave AmpE = $(df+"AmpE")
	
	AmpB[win] = V_left
	AmpE[win] = V_right
	
	NMAutoStats()

End // XTimes2Stats

//****************************************************************
//****************************************************************
//****************************************************************
