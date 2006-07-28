#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Statistical Analysis Tab
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 08 June 2006
//
//	NM tab entry "Stats"
//
//	Wave statistics package - min, max, mean, slope, level detection, baseline, 
//	rise and decay times.
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
	
	StatsChanSave(enable)

	if (enable == 1)
		CheckPackage("Stats", 0) // declare globals if necessary
		StatsDefaults()
		MakeStats(0) // make controls if necessary
		StatsAmpInit(-1, 1)
		DoUpdate // this is necessary for drag waves to appear
		NMAutoStats() // compute Stats
	endif
	
	if (DataFolderExists(StatsDF()) == 0)
		return 0 // Stats tab has not been created yet
	endif
	
	StatsChanControls(enable)
	StatsDisplay(enable) // display/remove stat waves on active channel graph
	CheckStatsDrag()
	
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

	StatsEdit("inputs")

End // StatsConfigEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStats()
	
	Variable NumAmps = 10 // number of measurements windows - may be increased
	
	String df = StatsDF(), cdf = ChanDF(-1)
	
	if (DataFolderExists(df) == 0)
		return -1
	endif

	Variable smthn = NumVarOrDefault(cdf+"smthNum", 0)
	String smtha = ChanSmthAlg(-1)
	Variable dt = NumVarOrDefault(cdf+"DTflag", 0)
	
	// waves to store all the stat window input/output parameters

	CheckNMtwave(df+"AmpSlct", NumAmps, "Off")
	CheckNMwave(df+"AmpB", NumAmps, 0)
	CheckNMwave(df+"AmpE", NumAmps, 0)
	CheckNMwave(df+"AmpY", NumAmps, Nan)
	CheckNMwave(df+"AmpX", NumAmps, Nan)
	
	CheckNMwave(df+"Bflag", NumAmps, 0)
	CheckNMtwave(df+"BslnSlct", NumAmps, "Avg")
	CheckNMwave(df+"BslnB", NumAmps, 0)
	CheckNMwave(df+"BslnE", NumAmps, 0)
	CheckNMwave(df+"BslnY", NumAmps, Nan)
	CheckNMwave(df+"BslnX", NumAmps, Nan)
	CheckNMwave(df+"BslnSubt", NumAmps, 0)
	CheckNMwave(df+"BslnRflct", NumAmps, Nan)
	
	CheckNMwave(df+"Rflag", NumAmps, 0)
	CheckNMwave(df+"RiseBP", NumAmps, 10)
	CheckNMwave(df+"RiseEP", NumAmps, 90)
	CheckNMwave(df+"RiseBX", NumAmps, Nan)
	CheckNMwave(df+"RiseEX", NumAmps, Nan)
	CheckNMwave(df+"RiseTm", NumAmps, Nan)
	
	CheckNMwave(df+"Dflag", NumAmps, 0)
	CheckNMwave(df+"DcayP", NumAmps, 37)
	CheckNMwave(df+"DcayX", NumAmps, Nan)
	CheckNMwave(df+"DcayT", NumAmps, Nan)
	
	CheckNMwave(df+"dtFlag", NumAmps, dt)
	CheckNMwave(df+"Dsply", NumAmps, 2)
	
	CheckNMwave(df+"SmthNum", NumAmps, smthn)
	CheckNMtwave(df+"SmthAlg", NumAmps, "binomial")
	
	CheckNMtwave(df+"OffsetW", NumAmps, "") // new
	
	CheckNMwave(df+"WinSelect", NumAmps, 0) // new
	
	CheckNMwave(df+"ChanSelect", NumAmps, 0) // new
	
	// variables for display controls, Stats1
	
	CheckNMvar(df+"AmpNV", 0) 				// current amplitude number
	CheckNMvar(df+"AmpBV", 0)
	CheckNMvar(df+"AmpEV", 0)
	CheckNMvar(df+"AmpYV", Nan)
	CheckNMvar(df+"AmpXV", Nan)
	CheckNMvar(df+"BslnYV", Nan)
	CheckNMvar(df+"RiseTV", Nan)
	CheckNMvar(df+"DcayTV", Nan)
	CheckNMvar(df+"SmthNV", 0)
	CheckNMstr(df+"SmthAV", "binomial")
	
	// misc variables
	
	CheckNMvar(df+"DragOn", 1)
	CheckNMvar(df+"TablesOn", 1)
	CheckNMvar(df+"AutoStats2", 1)
	CheckNMvar(df+"AllWinOn", 1)
	
	CheckNMstr(df+"AmpColor", "65535,0,0")
	CheckNMstr(df+"BaseColor", "0,39168,0")
	CheckNMstr(df+"RiseColor", "0,0,65535")
	
	// waves for display graphs
	
	CheckNMwave(df+"ST_PntX", NumAmps*2, Nan)
	CheckNMwave(df+"ST_PntY", NumAmps*2, Nan)
	CheckNMwave(df+"ST_WinX", NumAmps*3, Nan)
	CheckNMwave(df+"ST_WinY", NumAmps*3, Nan)
	CheckNMwave(df+"ST_BslnX", NumAmps*3, Nan)
	CheckNMwave(df+"ST_BslnY", NumAmps*3, Nan)
	CheckNMwave(df+"ST_RDX", NumAmps*4, Nan)
	CheckNMwave(df+"ST_RDY", NumAmps*4, Nan)
	
	// variables for Stats2
	
	CheckNMstr(df+"ST_2WaveSlct", "")
	CheckNMstr(df+"ST_2StrMatch", "ST_*")
	CheckNMstr(df+"ST_2MatchSlct", "Stats1")
	
	CheckNMvar(df+"WavSelectOn", 0)
	CheckNMvar(df+"AutoPlot", 1)
	
	CheckNMvar(df+"ST_2AVG", Nan)
	CheckNMvar(df+"ST_2SDV", Nan)
	CheckNMvar(df+"ST_2SEM", Nan)
	CheckNMvar(df+"ST_2CNT", Nan)
	
	CheckNMwave(df+"ST_Stats2Wave", 0, 0)
	
	CheckStatsDrag() // new display drag waves
	
	return 0
	
End // CheckStats

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStatsDrag()

	String df = StatsDF()
	String wdf = "root:WinGlobals:"
	String cdf = "root:WinGlobals:" + CurrentChanGraphName() + ":"
	
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
	
	if (DataFolderExists(wdf) == 0)
		NewDataFolder $(LastPathColon(wdf,0))
	endif
	
	if (DataFolderExists(cdf) == 0)
		NewDataFolder $(LastPathColon(cdf,0))
	endif
	
	CheckNMstr(cdf+"S_TraceOffsetInfo", "")
	CheckNMvar(cdf+"HairTrigger", 0)
	
	SetFormula $(cdf+"HairTrigger"),"StatsDragTrigger(" + cdf + "S_TraceOffsetInfo)"

End // CheckStatsDrag

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWavesCopy(fromDF, toDF)
	String fromDF // data folder copy from
	String toDF // data folder copy to
	
	Variable icnt
	
	fromDF = LastPathColon(fromDF, 1)
	toDF = LastPathColon(toDF, 1)
	
	if (WaveExists($(fromDF+"AmpE")) == 0)
		return -1 // not a Stats folder
	endif
	
	if (DataFolderExists(GetPathName(toDF,1)) == 0)
		return -1
	endif
	
	if (DataFolderExists(toDF) == 0)
		NewDataFolder $LastPathColon(toDF, 0)
	endif
	
	StatsWavesCopy2(fromDF+"AmpE", toDF+"AmpE")
	
	StatsWavesCopy2(fromDF+"AmpSlct", toDF+"AmpSlct")
	
	StatsWavesCopy2(fromDF+"AmpB", toDF+"AmpB")
	StatsWavesCopy2(fromDF+"AmpE", toDF+"AmpE")
	
	if (WaveExists($(fromDF+"AmpY")) == 1)
		StatsWavesCopy2(fromDF+"AmpY", toDF+"AmpY")
	endif
	
	StatsWavesCopy2(fromDF+"Bflag", toDF+"Bflag")
	StatsWavesCopy2(fromDF+"BslnSlct", toDF+"BslnSlct")
	StatsWavesCopy2(fromDF+"BslnB", toDF+"BslnB")
	StatsWavesCopy2(fromDF+"BslnE", toDF+"BslnE")
	
	StatsWavesCopy2(fromDF+"BslnSubt", toDF+"BslnSubt")
	StatsWavesCopy2(fromDF+"BslnRflct", toDF+"BslnRflct")
	
	StatsWavesCopy2(fromDF+"Rflag", toDF+"Rflag")
	StatsWavesCopy2(fromDF+"RiseBP", toDF+"RiseBP")
	StatsWavesCopy2(fromDF+"RiseEP", toDF+"RiseEP")
	
	StatsWavesCopy2(fromDF+"Dflag", toDF+"Dflag")
	StatsWavesCopy2(fromDF+"DcayP", toDF+"DcayP")
	
	StatsWavesCopy2(fromDF+"dtFlag", toDF+"dtFlag")
	StatsWavesCopy2(fromDF+"Dsply", toDF+"Dsply")
	
	StatsWavesCopy2(fromDF+"SmthNum", toDF+"SmthNum")
	StatsWavesCopy2(fromDF+"SmthAlg", toDF+"SmthAlg")
	
	StatsWavesCopy2(fromDF+"ChanSelect", toDF+"ChanSelect")
	
	Wave /T AmpSlct = $(toDF+"AmpSlct")
	Wave /T BslnSlct = $(toDF+"BslnSlct")
	Wave /T SmthAlg = $(toDF+"SmthAlg")
	
	Wave SmthNum = $(toDF+"SmthNum")
	Wave RiseBP = $(toDF+"RiseBP")
	Wave RiseEP = $(toDF+"RiseEP")
	Wave DcayP = $(toDF+"DcayP")
	
	for (icnt = 0; icnt < numpnts(AmpSlct); icnt += 1)
		
		if (strlen(AmpSlct[icnt]) == 0)
			AmpSlct[icnt] = "Off"
		endif
		
		if (strlen(AmpSlct[icnt]) == 0)
			BslnSlct[icnt] = "Avg"
		endif
		
		if ((strlen(AmpSlct[icnt]) == 0) && (SmthNum[icnt] > 0))
			SmthAlg[icnt] = "binomial"
		endif
		
		if (RiseBP[icnt] == 0)
			RiseBP[icnt] = 10
		endif
		
		if (RiseEP[icnt] == 0)
			RiseEP[icnt] = 90
		endif
		
		if (DcayP[icnt] == 0)
			DcayP[icnt] = 37
		endif
	
	endfor

End // StatsWavesCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWavesCopy2(from, to)
	String from // from wave
	String to // to wave
	
	Variable npnts = 10
	
	if (WaveExists($from) == 1)
		Duplicate /O $from, $to
		Redimension /N=(npnts) $to // preserve dimensions
	endif

End // StatsWavesCopy2

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDefaults()

	Variable tbgn = 15, tend = floor(rightx($CurrentChanDisplayWave()))
	String amp, df = StatsDF(), mdf = MainDF() 
	
	if (NumVarOrDefault(df+"StatsDefaultsSet", 0) == 1)
		return 0 // already set
	endif
	
	NVAR AmpNV = $(df+"AmpNV")
	
	Wave /T AmpSlct = $(df+"AmpSlct")
	
	AmpNV = 0
	amp = AmpSlct[AmpNV]
	
	if ((numtype(tend) > 0) || (tend == 0))
		tbgn = 15
		tend = 30
	else
		tend /= 2
	endif
	
	if ((strlen(amp) == 0) || (StringMatch(amp, "Off") == 1))
	
		SetNMtwave(df+"AmpSlct", AmpNV, "Max")
		SetNMwave(df+"AmpB", AmpNV, tbgn)
		SetNMwave(df+"AmpE", AmpNV, tend)
		
		tbgn = NumVarOrDefault(mdf+"Bsln_Bgn", 0)
		tend = NumVarOrDefault(mdf+"Bsln_End", 10)

		SetNMwave(df+"Bflag", AmpNV, 1)
		SetNMtwave(df+"BlsnSlct", AmpNV, "Avg")
		SetNMwave(df+"BslnB", AmpNV, tbgn)
		SetNMwave(df+"BslnE", AmpNV, tend)
		SetNMwave(df+"BslnSub", AmpNV, 0)
		SetNMwave(df+"BslnRflct", AmpNV, Nan)
	
	endif
	
	SetNMvar(df+"StatsDefaultsSet", 1)

End // StatsDefaults

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsEditCall()
	String select
	Prompt select, "select parameter type:", popup "input parameters;output parameters;"
	
	DoPrompt "Stats1 Window Parameter Table", select
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	strswitch(select)
		case "input parameters":
			select = "inputs"
			break
		case "output parameters":
			select = "outputs"
			break
	endswitch
	
	NMCmdHistory("StatsEdit", NMCmdStr(select, ""))
	
	return StatsEdit(select)

End // StatsEditCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsEdit(select)
	String select // ("inputs") input params ("outputs") output params
	
	String tname, title, df = StatsDF()
	
	strswitch(select)
		case "inputs":
			 tname = "ST_InputParams"
			 title = "Stats1 Input Parameters"
			 break
		case "outputs":
			tname = "ST_OutputParams"
			title = "Stats1 Output Parameters"
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
	endif
	
	strswitch(select)
	
		case "inputs":
		
			AppendToTable $(df+"AmpSlct"), $(df+"AmpB"), $(df+"AmpE")
			AppendToTable $(df+"Bflag"), $(df+"BslnSlct"), $(df+"BslnB"), $(df+"BslnE"), $(df+"BslnSubt"), $(df+"BslnRflct")
			AppendToTable $(df+"Rflag"), $(df+"RiseBP"), $(df+"RiseEP")
			AppendToTable $(df+"Dflag"), $(df+"DcayP")
			AppendToTable $(df+"dtFlag"), $(df+"SmthNum"), $(df+"SmthAlg"), $(df+"Dsply")
			
			if (WaveExists($(df+"OffsetW")) == 1)
				AppendToTable $(df+"OffsetW")
			endif
			
			SetWindow $tName hook=StatsTableHook
			
			break
			
		case "outputs":
			AppendToTable $(df+"AmpX"), $(df+"AmpY")
			AppendToTable $(df+"BslnX"), $(df+"BslnY")
			AppendToTable $(df+"RiseBX"), $(df+"RiseEX"), $(df+"RiseTm")
			AppendToTable $(df+"DcayX"), $(df+"DcayT")
			break
			
	endswitch
	
	return 0

End // StatsEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTableHook(infoStr)
	string infoStr
	
	string event = StringByKey("EVENT",infoStr)
	string win = StringByKey("WINDOW",infoStr)
	
	if (StringMatch(win, "ST_InputParams") == 0)
		return 0 // wrong window
	endif

	strswitch(event)
		case "deactivate":
		case "kill":
			UpdateNM(0)
			break
	endswitch

End // StatsTableHook
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeStats(force) // create Stats tab controls
	Variable force
	
	Variable x0, y0, xinc, yinc
	String df = StatsDF()
	
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
	y0 = 205
	yinc = 25
	
	GroupBox ST_Group, title="Stats1", pos={x0-15,y0-25}, size={260,255}
	
	PopupMenu ST_AmpSelect, pos={x0+85,y0-5}, bodywidth=135
	PopupMenu ST_AmpSelect, value =StatsAmpList(), proc=StatsPopup
	
	PopupMenu ST_WinSelect, pos={x0+180,y0-5}, bodywidth=85
	PopupMenu ST_WinSelect, value = StatsWinList(0), proc=StatsPopup
	
	SetVariable ST_AmpBSet, title="t_bgn", pos={x0+15,y0+1*yinc}, size={90,50}, limits={-inf,inf,1}
	SetVariable ST_AmpBSet, value=$(df+"AmpBV"), format="%.2f", proc=StatsSetVariable
	SetVariable ST_AmpESet, title="t_end", pos={x0+15,y0+2*yinc}, size={90,50}, limits={-inf,inf,1}
	SetVariable ST_AmpESet, value=$(df+"AmpEV"), format="%.2f", proc=StatsSetVariable
	SetVariable ST_SmthNSet, title="Smooth", pos={x0+15,y0+3*yinc}, size={90,50}, limits={0,inf,1}
	SetVariable ST_SmthNSet, value=$(df+"SmthNV"), proc=StatsSetVariable
	
	Checkbox ST_Baseline, title="Baseline", pos={x0,y0+4*yinc}, size={200,50}, value=0, proc=StatsCheckBox
	Checkbox ST_RiseTime, title="Rise Time", pos={x0,y0+5*yinc}, size={200,50}, value=0, proc=StatsCheckBox
	Checkbox ST_DecayTime, title="Decay Time", pos={x0,y0+6*yinc}, size={200,50}, value=0, proc=StatsCheckBox
	
	Checkbox ST_Ft, title="F(t)", pos={x0,y0+7*yinc}, size={200,50}, value=0, proc=StatsCheckBox
	Checkbox ST_Display, title="Display", pos={x0+75,y0+7*yinc}, size={200,50}, value=0, proc=StatsCheckBox
	Checkbox ST_Offset, title="t_offset", pos={x0+155,y0+7*yinc}, size={200,50}, value=0, proc=StatsCheckBox
	
	SetVariable ST_AmpYSet, title="y:", pos={x0+xinc,y0+1*yinc}, size={80,50}, limits={-inf,inf,0}
	SetVariable ST_AmpYSet, value=$(df+"AmpYV"), format="%.3f", frame=0, proc=StatsSetVariable
	SetVariable ST_AmpXSet, title="t:", pos={x0+xinc,y0+2*yinc}, size={80,50}, limits={-inf,inf,0}
	SetVariable ST_AmpXSet, value=$(df+"AmpXV"), format="%.3f", frame=0
	SetVariable ST_SmthASet, title="s:", pos={x0+xinc,y0+3*yinc}, size={80,50}
	SetVariable ST_SmthASet, value=$(df+"SmthAV"), frame=0, proc=StatsSetVariable
	SetVariable ST_BslnSet, title="b:", pos={x0+xinc,y0+4*yinc}, size={80,20}, limits={-inf,inf,0}
	SetVariable ST_BslnSet, value=$(df+"BslnYV"), format="%.3f", frame=0
	SetVariable ST_RiseTSet, title="rt:", pos={x0+xinc,y0+5*yinc}, size={80,50}, limits={0,inf,0}
	SetVariable ST_RiseTSet, value=$(df+"RiseTV"), format="%.3f", frame=0
	SetVariable ST_DcayTSet, title="dt:", pos={x0+xinc,y0+6*yinc}, size={80,50}, limits={0,inf,0}
	SetVariable ST_DcayTSet, limits={0,inf,0}, value=$(df+"DcayTV"), format="%.3f", frame=0
	
	Button ST_Edit, title="Edit", pos={x0,y0+8*yinc}, size={70,20}, proc=StatsButton
	Button ST_AllWaves, title="All Waves", pos={120,y0+8*yinc}, size={78,20}, proc=StatsButton
	
	Checkbox ST_AllWin, title="All Win", pos={x0+175,y0+8*yinc+3}, size={200,50}, value=0, proc=StatsCheckBox
	
	xinc = 135
	y0 = 480
	yinc = 25
	
	GroupBox ST_2Group, title="Stats2", pos={x0-15,y0-30}, size={260,155}
	
	PopupMenu ST_2WaveList, value="Select Wave", bodywidth=150, pos={x0+100,y0-5}, proc=StatsPopup
	
	PopupMenu ST_2ListFilter, bodywidth=70, pos={x0+180,y0-5}, proc=StatsPopup
	PopupMenu ST_2ListFilter, value="Wave List Filter"
	
	y0 -= 5
	
	Checkbox ST_2PlotAuto, title="Plot", pos={x0+10,y0+1*yinc+3}, size={200,50}, value=0, proc=StatsCheckBox
	Checkbox ST_2WaveSelect, title="Wave Select On", pos={x0+70,y0+1*yinc+3}, size={200,50}, value=0, proc=StatsCheckBox
	
	SetVariable ST_2AvgSet, title="AVG: ", pos={x0,y0+2*yinc}, size={100,50}
	SetVariable ST_2AvgSet, value=$(df+"ST_2AVG"), limits={-inf,inf,0}, format="%.3f", frame=0
	SetVariable ST_2CNTSet, title="NUM: ", pos={x0+xinc,y0+2*yinc}, size={100,50}
	SetVariable ST_2CNTSet, value=$(df+"ST_2CNT"), limits={0,inf,0}, format="%.0f", frame=0
	SetVariable ST_2SDVSet, title="SDV: ", pos={x0,y0+3*yinc}, size={100,50}
	SetVariable ST_2SDVSet, value=$(df+"ST_2SDV"), limits={0,inf,0}, format="%.3f", frame=0
	SetVariable ST_2SEMSet, title="SEM: ", pos={x0+xinc,y0+3*yinc}, size={100,50}
	SetVariable ST_2SEMSet, value=$(df+"ST_2SEM"), limits={-inf,inf,0}, format="%.3f", frame=0
	
	PopupMenu ST_2FXN, pos={x0+40,y0+4*yinc}, bodywidth = 90
	PopupMenu ST_2FXN, value="Function...;---;Plot;Histogram;Sort Wave;Stability;Delete NANs;", proc=StatsPopup
	Button ST_2Save, title="Save", pos={135,y0+4*yinc}, size={50,20}, proc=StatsButton
	Button ST_2AllWaves, title="All Waves", pos={195,y0+4*yinc}, size={70,20}, proc=StatsButton

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

Function UpdateStats1() // update/display current amp result values

	Variable off, offset, modeNum
	String ttl, ampstr, df = StatsDF(), cdf = ChanDF(-1)

	if (DataFolderExists(df) == 0)
		return 0 // stats has not been initialized yet
	endif

	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	
	NVAR AmpNV = $(df+"AmpNV")
	NVAR AmpBV = $(df+"AmpBV"); NVAR AmpEV = $(df+"AmpEV")
	NVAR AmpYV = $(df+"AmpYV"); NVAR AmpXV = $(df+"AmpXV")
	NVAR BslnYV = $(df+"BslnYV"); NVAR RiseTV = $(df+"RiseTV")
	NVAR DcayTV = $(df+"DcayTV"); NVAR SmthNV = $(df+"SmthNV")
	
	Wave /T AmpSlct = $(df+"AmpSlct")
	Wave AmpB = $(df+"AmpB"); Wave AmpE = $(df+"AmpE")
	Wave AmpY = $(df+"AmpY"); Wave AmpX = $(df+"AmpX")
	
	Wave /T BslnSlct = $(df+"BslnSlct")
	Wave Bflag = $(df+"Bflag"); Wave BslnY = $(df+"BslnY")
	Wave BslnB = $(df+"BslnB"); Wave BslnE = $(df+"BslnE")
	
	Wave Rflag = $(df+"Rflag"); Wave RiseTm = $(df+"RiseTm")
	Wave RiseBP = $(df+"RiseBP"); Wave RiseEP = $(df+"RiseEP")
	
	Wave Dflag = $(df+"Dflag");
	Wave DcayP = $(df+"DcayP"); Wave DcayT = $(df+"DcayT")
	
	Wave dtFlag = $(df+"dtFlag"); Wave Dsply = $(df+"Dsply")
	
	Wave SmthNum = $(df+"SmthNum"); Wave /T SmthAlg = $(df+"SmthAlg")
	
	Wave ST_PntX = $(df+"ST_PntX"); Wave ST_PntY = $(df+"ST_PntY")
	Wave ST_WinX = $(df+"ST_WinX"); Wave ST_WinY = $(df+"ST_WinY")
	Wave ST_BslnX = $(df+"ST_BslnX"); Wave ST_BslnY = $(df+"ST_BslnY")
	Wave ST_RDX = $(df+"ST_RDX"); Wave ST_RDY = $(df+"ST_RDY")
	
	Wave ChanSelect = $(df+"ChanSelect")
	
	if (ChanSelect[0] != CurrentChan)
		StatsChanCall(CurrentChan)
	endif
	
	if (strlen(AmpSlct[AmpNV]) == 0)
		 AmpSlct[AmpNV] = "Off"
	endif
	
	if (StringMatch(AmpSlct[AmpNV], "Off") == 1)
		off = 1
	endif
	
	AmpBV = AmpB[AmpNV]
	AmpEV = AmpE[AmpNV]
	
	AmpYV = AmpY[AmpNV]; AmpXV = AmpX[AmpNV]
	BslnYV = BslnY[AmpNV]; RiseTV = RiseTm[AmpNV]
	DcayTV = DcayT[AmpNV]
	
	SetNMvar(df+"SmthNV", SmthNum[AmpNV])
	SetNMstr(df+"SmthAV", SmthAlg[AmpNV])
	
	// update channel smooth and f(t) flags
	
	SetNMVar(cdf+"smthNum", SmthNum[AmpNV])
	SetNMStr(cdf+"smthAlg", SmthAlg[AmpNV])
	
	ChanFunc(CurrentChan, dtFlag[AmpNV])
	
	// update Stats controls
	
	if (SmthNV == 0)
		SetVariable ST_SmthASet, disable=1, win=NMPanel
	else
		SetVariable ST_SmthASet, disable=0, win=NMPanel
	endif
	
	if (Bflag[AmpNV] == 1)
		sprintf ttl, "Bsln (" + BslnSlct[AmpNV] + ": %.2f - %.2f)", BslnB[AmpNV], BslnE[AmpNV]
		Checkbox ST_Baseline, disable=0, value=1, win=NMPanel, title= ttl
		SetVariable ST_BslnSet, disable=off, win=NMPanel
	else
		Checkbox ST_Baseline, disable=0, value=0, title="Baseline", win=NMPanel
		SetVariable ST_BslnSet, disable=1, win=NMPanel
	endif
	
	if (Rflag[AmpNV] == 1)
		Checkbox ST_RiseTime, disable=0, value=1, win=NMPanel, title="Rise Time (" + num2str(RiseBP[AmpNV]) + " - " + num2str(RiseEP[AmpNV]) + "%)"
		SetVariable ST_RiseTSet, disable=off, win=NMPanel
	else
		Checkbox ST_RiseTime, disable=0, value =0, title="Rise Time", win=NMPanel
		SetVariable ST_RiseTSet, disable=1, win=NMPanel
	endif
	
	if (Dflag[AmpNV] == 1)
		Checkbox ST_DecayTime, disable=0, value=1, win=NMPanel, title="Decay Time (" + num2str(DcayP[AmpNV]) + "%)"
		SetVariable ST_DcayTSet, disable=off, win=NMPanel
	else
		Checkbox ST_DecayTime, disable=0, value=0, title="Decay Time", win=NMPanel
		SetVariable ST_DcayTSet, disable=1, win=NMPanel
	endif
	
	switch(dtFlag[AmpNV])
		default:
			Checkbox ST_Ft, disable=0, value=0, win=NMPanel, title="F(t)"
			break
		case 1:
			Checkbox ST_Ft, disable=0, value=1, win=NMPanel, title="d/dt"
			break
		case 2:
			Checkbox ST_Ft, disable=0, value=1, win=NMPanel, title="dd/dt*dt"
			break
		case 3:
			Checkbox ST_Ft, disable=0, value=1, win=NMPanel, title="integral"
			break
		case 4:
			Checkbox ST_Ft, disable=0, value=1, win=NMPanel, title="normalize"
			break
	endswitch
	
	if (Dsply[AmpNV] == 0)
		Checkbox ST_Display, disable=0, value=0, win=NMPanel
	else
		Checkbox ST_Display, disable=0, value=1, win=NMPanel
	endif
	
	offset = StatsOffsetValue(AmpNV)
	
	if (offset == -1)
		Checkbox ST_Offset, disable=0, value=0, win=NMPanel, title="t_offset"
	else
		offset = max(0,offset)
		Checkbox ST_Offset, disable=0, value=1, win=NMPanel, title="t_offset: " + num2str(offset) + ""
	endif
	
	Checkbox ST_AllWin, win=NMPanel, value=NumVarOrDefault(df+"AllWinOn", 1)
	
	SetVariable ST_AmpYSet, title="y:", frame=0, disable=0, win=NMPanel
	SetVariable ST_AmpXSet, title="t:", disable=0, win=NMPanel
	
	ampstr = AmpSlct[AmpNV]
		
	strswitch(ampstr)
		case "Max":
		case "Min":
			break
		case "Avg":
		case "SDev":
		case "Var":
		case "RMS":
		case "Area":
			SetVariable ST_AmpXSet, disable=1, win=NMPanel
			break
		case "Slope":
		case "RTSlope+":
		case "RTSlope-":
			SetVariable ST_AmpYSet, title = "m:", win=NMPanel
			SetVariable ST_AmpXSet, title = "b:", win=NMPanel
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
	
	modenum = 1 + WhichListItemLax(ampstr, StatsAmpList(), ";")
	
	PopupMenu ST_AmpSelect, mode = modeNum, win=NMPanel // reset menu display mode
	
	PopupMenu ST_WinSelect, mode=(AmpNV+1), win=NMPanel
	
	DoWindow /F NMpanel // brings back to front for more input

End // UpdateStats1

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateStats2()
	Variable md, icnt
	String wList, titlestr

	String df = StatsDF()
	
	Variable wSelect = NumVarOrDefault(df+"WavSelectOn", 0)
	Variable plotOn = NumVarOrDefault(df+"AutoPlot", 0)
	
	String ST_2WaveSlct = StrVarOrDefault(df+"ST_2WaveSlct", "")
	String ST_2MatchSlct = StrVarOrDefault(df+"ST_2MatchSlct", "")
	
	wlist = "Wave List Filter;---;All;Stats1;Stats2;" + StatsWinList(1) + "Any;Other;"
	
	md = WhichListItem(ST_2MatchSlct, wlist)
	
	if (md == -1)
		md = 1
		SetNMstr(df+"ST_2MatchSlct", "Stats1")
		SetNMstr(df+"ST_2StrMatch", "ST_*")
	else
		md += 1
	endif
	
	PopupMenu ST_2ListFilter, win=NMPanel, value = "Wave List Filter;---;All;Stats1;Stats2;" + StatsWinList(1) + "Any;Other;"
	PopupMenu ST_2ListFilter, win=NMPanel, mode=md
	
	wList = Stats2List()
	
	if (WaveExists($ST_2WaveSlct) == 0)
		ST_2WaveSlct = ""
		SetNMstr(df+"ST_2WaveSlct", "")
	endif
	
	if (strlen(ST_2WaveSlct) == 0)
		md = 1
	else
		md = WhichListItem(ST_2WaveSlct, wlist) + 3
	endif
	
	PopupMenu ST_2WaveList, win=NMPanel, value = "Select Wave;---;" + Stats2List() //+ "---;Update this list;Other Wave..."
	PopupMenu ST_2WaveList, win=NMPanel, mode=md
	
	titleStr = "Wave Select Filter : Off"
	
	if (wSelect == 1)
		titleStr = "Wave Select Filter : " + NMWaveSelectGet()
	endif
	
	Checkbox ST_2WaveSelect, title=titleStr, value=wSelect, win=NMPanel
	Checkbox ST_2PlotAuto, win=NMPanel, value=plotOn
	
	PopupMenu ST_2FXN, mode=1, win=NMpanel

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

Function StatsSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	StatsCall(ctrlName[3,inf], varStr)
	
End // StatsSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsCall(fxn, select)
	String fxn, select
	
	Variable snum = str2num(select)
	String txt
	
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
			return StatsFxnCall(snum)
			
		case "Display":
		case "Label":
			return StatsLabelCall(snum)
	
		case "Offset":
			return StatsOffsetCall(snum)
			
		case "AllWin":
		case "All Win":
			return StatsAllWinCall(snum)
			
		case "Edit":
			return StatsEditCall()
			
		case "AllWaves":
		case "All Waves":
			return StatsAllWavesCall()
			
		case "2PlotAuto":
		case "Plot Auto":
			return StatsPlotAutoCall(snum)
			
		case "2WaveSelect":
		case "Wave Select":
			return Stats2WSelectFilterCall(snum)
			
		case "2WaveList":
		case "Wave List":
			return Stats2WSelectCall(select)
			
		case "2ListFilter":
		case "List Filter":
			return Stats2FilterSelectCall(select)
			
		case "2Save":
			return Stats2SaveCall()
			
		case "2AllWaves":
			return Stats2AllCall()
			
		case "2FXN":
			txt = Stats2Call(select)
			UpdateStats2()
			if (strlen(txt) > 0)
				return 0
			else
				return -1
			endif
			
	endswitch
	
	if (StringMatch(fxn[0,5], "DragOn") == 1)
		return StatsDragCall(snum)
	endif
	
End // StatsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2Call(fxn)
	String fxn
	
	strswitch(fxn)
	
		case "Plot":
			return StatsPlotCall()
			
		case "Histogram":
			return StatsHistoCall()
			
		case "Sort Wave":
			return StatsSortCall()
			
		case "Stability":
		case "Stationarity":
			return StatsStabilityCall()
			
		case "Delete NANs":
			return StatsDeleteNANsCall()
			
	endswitch
	
	return ""

End // Stats2Call

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTimeStamp() // place time stamp on AmpSlct
	String df = StatsDF()
	
	Note /K $(df+"AmpSlct")
	Note $(df+"AmpSlct"), "Stats Date:" + date()
	Note $(df+"AmpSlct"), "Stats Time:" + time()

End // StatsTimeStamp

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTimeStampCompare(df1, df2)
	String df1, df2
	
	df1 = LastPathColon(df1, 1)
	df2 = LastPathColon(df2, 1)
	
	String d1 = NMNoteStrByKey(df1+"AmpSlct", "Stats Date")
	String d2 = NMNoteStrByKey(df2+"AmpSlct", "Stats Date")
	String t1 = NMNoteStrByKey(df1+"AmpSlct", "Stats Time")
	String t2 = NMNoteStrByKey(df2+"AmpSlct", "Stats Time")
	
	if ((strlen(d1) == 0) || (strlen(d2) == 0) || (strlen(t1) == 0) || (strlen(t1) == 0))
		return -1 // time stamp doesnt exist
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
	
	if (numtype(chan) > 0)
		return -1
	endif
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	//SetNMwave(wname, win, chan)
	
	// for now, only allow one channel to be selected
	
	Wave temp = $wname
	temp = chan
	
	NMAutoStats()
	UpdateStats1()
	StatsTimeStamp()
	
	return 0

End // StatsChan

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
	
	String df = StatsDF()
	String wname = df + "AmpB"
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)
	
	String StatWaveName = CurrentWaveName() // source wave name
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	SetNMvar(df+"AmpNV", win)
	StatsAmpInit(win, 0)
	
	StatsComputeAmps(StatWaveName, CurrentChan, CurrentWave, -1, 0, 1)
	UpdateStats1() // this updates dt flags
	ChanGraphsUpdate(0)
	
	return 0

End // StatsWinSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmp(win, ampStr)
	Variable win
	String ampStr
	
	DoAlert 0, "Alert: function StatsAmp() has been deprecated. Please use StatsWin() in NM_StatsTab.ipf instead."
	return -1

End // StatsAmp

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWindow(win, tbgn, tend)
	Variable win, tbgn, tend
	
	DoAlert 0, "Alert: function StatsWindow() has been deprecated. Please use StatsWin() in NM_StatsTab.ipf instead."
	return -1

End // StatsWindow

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinCall(tbgn, tend, ampStr)
	Variable tbgn, tend
	String ampStr
	
	Variable rx, lx
	String vlist = "", df = StatsDF()
	
	NVAR AmpNV = $(df+"AmpNV")
	
	Wave AmpB = $(df+"AmpB")
	Wave AmpE = $(df+"AmpE")
	
	Wave /T AmpSlct = $(df+"AmpSlct")
	
	if ((numtype(tbgn) == 0) && (numtype(tend) > 0))
	
		rx = rightx($CurrentChanDisplayWave())
	
		if (tbgn > AmpE[AmpNV])
			tend = tbgn + abs(AmpE[AmpNV] - AmpB[AmpNV])
		endif
		
		if (tend > rx)
			tend = rx
		endif
		
	endif
	
	if ((numtype(tbgn) > 0) && (numtype(tend) == 0))
	
		lx = leftx($CurrentChanDisplayWave())
	
		if (tend < AmpB[AmpNV])
			tbgn = tend - abs(AmpE[AmpNV] - AmpB[AmpNV])
		endif
		
		if (tbgn < lx)
			tbgn = lx
		endif
		
	endif
	
	if (numtype(tbgn) > 0)
		tbgn = AmpB[AmpNV]
	endif
	
	if (numtype(tend) > 0)
		tend = AmpE[AmpNV]
	endif
	
	if (strlen(ampStr) == 0)
		ampStr = AmpSlct[AmpNV]
	endif
	
	vlist = NMCmdNum(AmpNV, vlist)
	vlist = NMCmdNum(tbgn, vlist)
	vlist = NMCmdNum(tend, vlist)
	vlist = NMCmdStr(ampStr, vlist)
	NMCmdHistory("StatsWin", vlist)
	
	return StatsWin(AmpNV, tbgn, tend, ampStr)

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
		return -1
	endif
	
	if ((win < 0) || (win > numpnts($(df+"AmpB"))))
		return -1
	endif
	
	SetNMwave(df+"AmpB", win, tbgn)
	SetNMwave(df+"AmpE", win, tend)
	SetNMtwave(df+"AmpSlct", win, ampStr)
	
	StatsBslnReflectUpdate(win) // recompute reflected baseline if on
	
	NMAutoStats()
	//UpdateStats1()
	StatsTimeStamp()
	
	return 0

End // StatsWin

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
	UpdateStats1()
	StatsTimeStamp()
	
	return 0

End // StatsLevel

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsSmoothCall(smthN, smthA)
	Variable smthN
	String smthA
	String vlist = "", df = StatsDF()
	
	NVAR AmpNV = $(df+"AmpNV")
	
	Wave SmthNum = $(df+"SmthNum")
	Wave /T SmthAlg = $(df+"SmthAlg")
	
	if (smthN == -1)
		smthN = SmthNum[AmpNV]
	endif
	
	strswitch(smthA)
		case "old":
			smthA = SmthAlg[AmpNV]
			break
		case "binomial":
		case "boxcar":
			break
		default:
			smthA = ChanSmthAlgAsk(-1)
	endswitch
	
	vlist = NMCmdNum(AmpNV, vlist)
	vlist = NMCmdNum(smthN, vlist)
	vlist = NMCmdStr(smthA, vlist)
	NMCmdHistory("StatsSmooth", vlist)
	
	return StatsSmooth(AmpNV, smthN, smthA)
	
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
		return -1
	endif
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	strswitch(smthAlg)
		case "":
		case "none":
			smthAlg = "binomial"
		case "binomial":
		case "boxcar":
			break
		default:
			smthAlg = StrVarOrDefault(cdf+"smthAlg", "binomial")
	endswitch
	
	if (WhichListItemLax(smthAlg, "binomial;boxcar;", ";") == -1)
		return -1
	endif
	
	SetNMtwave(wname, win, smthAlg)
	SetNMwave(df+"SmthNum", win, smthNum)

	SetNMVar(cdf+"smthNum", smthNum) // set current channel smooth vars
	SetNMStr(cdf+"smthAlg", smthAlg)
	
	ChanGraphsUpdate(0)
	NMAutoStats()
	UpdateStats1()
	StatsTimeStamp()
	
	return 0

End // StatsSmooth

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBslnCall(on)
	Variable on // (0) no (1) yes
	
	Variable tbgn, tend, twin, subtract
	Variable reflect, bgstart, bgend, bgcntr = Nan
	String vlist = "", fxn = "", df = StatsDF()
	
	NVAR AmpNV = $(df+"AmpNV")
	
	Wave AmpB= $(df+"AmpB"); Wave AmpE= $(df+"AmpE")
	Wave BslnB = $(df+"BslnB"); Wave BslnE = $(df+"BslnE")
	Wave BslnSubt = $(df+"BslnSubt"); Wave BslnRflct = $(df+"BslnRflct")
	Wave Bflag = $(df+"Bflag"); Wave Rflag = $(df+"Rflag"); Wave Dflag  = $(df+"Dflag")
	
	Wave /T AmpSlct = $(df+"AmpSlct"); Wave /T BslnSlct = $(df+"BslnSlct")
	
	if ((on == 0) && ((Rflag[AmpNV] == 1) || (Dflag[AmpNV] == 1)))
		on = 1 // baseline must be on
	endif
	
	if (on == 1)
	
		tbgn = BslnB[AmpNV]
		tend = BslnE[AmpNV]
		twin = tend - tbgn
		subtract = BslnSubt[AmpNV] + 1
		reflect = 1 // no
		
		if (numtype(BslnRflct[AmpNV]) == 0)
			reflect = 2 // yes
			tbgn = BslnRflct[AmpNV] - twin/2
			tend = BslnRflct[AmpNV] + twin/2
		endif
		
		strswitch(AmpSlct[AmpNV])
			case "SDev":
			case "Var":
			case "RMS":
			case "Area":
			case "Slope":
				fxn = AmpSlct[AmpNV]
				break
			default:
				fxn = "Avg"
		endswitch
		
		Prompt tbgn, "begin time (ms):"
		Prompt tend, "end time (ms):"
		Prompt fxn, "baseline measurement:", popup, "Max;Min;Avg;SDev;Var;RMS;Area;Slope"
		Prompt subtract, "subtract baseline from y-measurement?", popup, "no;yes"
		Prompt reflect, "compute reflected baseline from t_bgn and t_end?", popup, "no;yes"
		DoPrompt "Baseline Window", tbgn, tend, fxn, subtract, reflect
	
		if (V_Flag == 1)
			UpdateStats1()
			return 0
		endif
		
		subtract -= 1
		
		if (reflect == 2) // yes, reflect baseline window
		
			// recompute baseline time window based on Amp window
		
			twin = BslnB[AmpNV] + BslnE[AmpNV]
			bgcntr = twin/2 // center of baseline window
			bgstart = 2*bgcntr - AmpE[AmpNV] // reflect back
			bgend = 2*bgcntr - AmpB[AmpNV]
	
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
	
		vlist = NMCmdNum(AmpNV, vlist)
		vlist = NMCmdNum(on, vlist)
		vlist = NMCmdNum(tbgn, vlist)
		vlist = NMCmdNum(tend, vlist)
		vlist = NMCmdStr(fxn, vlist)
		vlist = NMCmdNum(subtract, vlist)
		vlist = NMCmdNum(bgcntr, vlist)
		NMCmdHistory("StatsBslnReflect", vlist)
		
		return StatsBslnReflect(AmpNV, on, tbgn, tend, fxn, subtract, bgcntr)
		
	else
	
		vlist = NMCmdNum(AmpNV, vlist)
		vlist = NMCmdNum(on, vlist)
		vlist = NMCmdNum(tbgn, vlist)
		vlist = NMCmdNum(tend, vlist)
		vlist = NMCmdStr(fxn, vlist)
		vlist = NMCmdNum(subtract, vlist)
		NMCmdHistory("StatsBsln", vlist)
		
		return StatsBsln(AmpNV, on, tbgn, tend, fxn, subtract)
		
	endif
	
End // StatsBslnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBsln(win, on, tbgn, tend, fxn, subtract)
	Variable win, on, tbgn, tend
	String fxn // Max,Min,Avg,SDev,Var,RMS,Area,Slope
	Variable subtract // (0) no (1) yes
	
	String df = StatsDF()
	String wname = df + "Bflag"
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	SetNMwave(wname, win, on)
	
	if (on == 1)
		SetNMwave(df + "BslnB", win, tbgn)
		SetNMwave(df + "BslnE", win, tend)
		SetNMtwave(df+"BslnSlct", win, fxn)
		SetNMwave(df+"BslnSubt", win, subtract)
	else
		SetNMwave(df + "BslnRflct", win, Nan) // turn of reflection
	endif
	
	NMAutoStats()
	UpdateStats1()
	StatsTimeStamp()
	
	return 0

End // StatsBsln

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBslnReflect(win, on, tbgn, tend, fxn, subtract, center)
	Variable win, on, tbgn, tend
	String fxn // Max,Min,Avg,SDev,Var,RMS,Area,Slope
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
	
	StatsTimeStamp()
	
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
	
	NVAR AmpNV = $(df+"AmpNV")
	
	Wave RiseBP = $(df+"RiseBP"); Wave RiseEP = $(df+"RiseEP")
	Wave Bflag = $(df+"Bflag"); Wave Rflag = $(df+"Rflag")
	
	if (Bflag[AmpNV] == 0)
		Doalert 0, "This function requires computation of a baseline."
		on = 0
	endif

	if (on == 1)
	
		pbgn = RiseBP[AmpNV]
		pend = RiseEP[AmpNV]
		
		Prompt pbgn, "% begin:"
		Prompt pend, "% end:"
		DoPrompt "Percent Rise Time", pbgn, pend
		
		if (V_Flag == 1)
			UpdateStats1()
			return 0
		endif
		
	endif
	
	vlist = NMCmdNum(AmpNV, vlist)
	vlist = NMCmdNum(on, vlist)
	vlist = NMCmdNum(pbgn, vlist)
	vlist = NMCmdNum(pend, vlist)
	NMCmdHistory("StatsRiseTime", vlist)
	
	return StatsRiseTime(AmpNV, on, pbgn, pend)
	
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
	endif
	
	NMAutoStats()
	UpdateStats1()
	StatsTimeStamp()
	
	return 0

End // StatsRiseTime

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDecayTimeCall(on)
	Variable on // (0) no (1) yes
	
	Variable pend
	String vlist = "", df = StatsDF()
	
	NVAR AmpNV = $(df+"AmpNV")
	
	Wave Bflag = $(df+"Bflag")
	Wave Dflag = $(df+"Dflag")
	Wave DcayP = $(df+"DcayP")
	
	if (Bflag[AmpNV] == 0)
		Doalert 0, "This function requires computation of a baseline."
		on = 0
	endif
	
	if (on == 1)
	
		pend = DcayP[AmpNV]
		Prompt pend, "% decay:"
		DoPrompt "Percent Decay Time", pend
		
		if (V_Flag == 1)
			UpdateStats1()
			return 0
		endif
		
	endif
	
	vlist = NMCmdNum(AmpNV, vlist)
	vlist = NMCmdNum(on, vlist)
	vlist = NMCmdNum(pend, vlist)
	NMCmdHistory("StatsDecayTime", vlist)
	
	return StatsDecayTime(AmpNV, on, pend)
	
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
	endif
	
	NMAutoStats()
	UpdateStats1()
	StatsTimeStamp()
	
	return 0

End // StatsDecayTime

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFxnCall(on)
	Variable on // (0) no (1) yes
	
	Variable win, fxn
	String vlist = "", df = StatsDF()
	
	if (on == 1)
		fxn = ChanFuncAsk(NumVarOrDefault("CurrentChan", 0))
	endif
	
	if (fxn == -1)
		UpdateStats1() // cancel
		return 0
	endif
	
	win = NumVarOrDefault(df+"AmpNV", 0)
	
	vlist = NMCmdNum(win, vlist)
	vlist = NMCmdNum(fxn, vlist)
	NMCmdHistory("StatsFxn", vlist)
	
	return StatsFxn(win, fxn)

End // StatsFxnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFxn(win, fxn)
	Variable win
	Variable fxn // (0) none (1) d/dt (2) dd/dt*dt (3) integral (4) normalize
	
	String wname = StatsDF() + "dtFlag"
	
	if ((fxn < 0) || (fxn > 4))
		return -1
	endif
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	SetNMwave(wname, win, fxn)
	
	ChanFunc(NumVarOrDefault("CurrentChan", 0), fxn)
	
	NMAutoStats()
	ChanGraphsUpdate(0)
	UpdateStats1()
	StatsTimeStamp()
	
	return 0
	
End // StatsFxn

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLabelCall(on)
	Variable on
	
	Variable win, select
	String vlist = "", df = StatsDF()
	
	if (on == 1)
	
		select = 2
		Prompt select "display label:", popup "no text;window number + y-value;window number;y-value"
		DoPrompt "Stats Graph Display", select
		
		if (V_flag == 1)
			UpdateStats1()
			return 0
		endif
		
	endif
	
	win = NumVarOrDefault(df+"AmpNV", 0)
	
	vlist = NMCmdNum(win, vlist)
	vlist = NMCmdNum(select, vlist)
	NMCmdHistory("StatsLabel", vlist)
	
	return StatsLabel(win, select)

End // StatsLabelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLabel(win, select)
	Variable win
	Variable select // (0) off (1) no text (2) win + y-value (3) win (4) y-value
	
	String wname = StatsDF() + "Dsply"
	
	if ((select < 0) || (select > 4))
		return -1
	endif
	
	if ((win < 0) || (win > numpnts($wname)))
		return -1
	endif
	
	SetNMwave(wname, win, select)
	
	StatsDisplay(1)
	//StatsDisplayUpdate(win)
	UpdateStats1()
	StatsTimeStamp()
	
	return 0
	
End // StatsLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffsetCall(on)
	Variable on // (0) no (1) yes
	
	Variable create
	String txt, tName, vlist = "", wlist = "", rlist = "", typestr = "/g"
	
	String ndf = NMDF(), df = StatsDF()
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	Variable ngrps = NumVarOrDefault("NumGrps", 0)
	
	Variable select = NumVarOrDefault(df+"OffsetSelect", 1)
	Variable wtype = NumVarOrDefault(df+"OffsetType", 1)
	Variable bsln = 1+NumVarOrDefault(df+"OffsetBsln", 1)
	String wname = StrVarOrDefault(df+"OffsetWName", "")
	
	NVAR AmpNV = $(df+"AmpNV")
	
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
		vlist = NMCmdNum(AmpNV, "")
		vlist = NMCmdStr(typestr+wname, vlist)
		NMCmdHistory("StatsOffset", vlist)
	endif

	return StatsOffset(AmpNV, typestr+wname)

End // StatsOffsetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffset(win, offName)
	Variable win // stats win num
	String offName // offset type ("/w" or "/g") + wave name, or ("") for no offset
	
	String type = ""
	String wname = StatsDF() + "OffsetW"
	
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
	UpdateStats1()
	StatsTimeStamp()
	
	return 0
	
End // StatsOffset

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffsetWave(wname, wtype) // create offset (time-shift) wave
	String wname
	Variable wtype // (1) group time offset (2) wave time offset
	
	String tName
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
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

Function StatsAllWinCall(on)
	Variable on // (0) no (1) yes
	
	NMCmdHistory("StatsAllWin", NMCmdNum(on,""))
	
	return StatsAllWin(on)
	
End // StatsAllWinCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAllWin(on)
	Variable on // (0) no (1) yes
	
	SetNMVar(StatsDF()+"AllWinOn", BinaryCheck(on))
	
	UpdateStats1()
	
	return on
	
End // StatsAllWin

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
	StatsDisplay(1)
	NMAutoStats()
	
	return on
	
End // StatsDrag

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2WSelectFilterCall(on)
	Variable on // (0) no (1) yes
	
	NMCmdHistory("Stats2WSelectFilter", NMCmdNum(on,""))
	
	return Stats2WSelectFilter(on)
	
End // Stats2WSelectFilterCall

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2WSelectFilter(on)
	Variable on // (0) no (1) yes
	
	SetNMVar(StatsDF()+"WavSelectOn", BinaryCheck(on))
	
	Stats2Display()
	Stats2Compute()
	UpdateStats2()
	
	return on
	
End // Stats2WSelectFilter

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2WSelectCall(wName)
	String wName
	
	NMCmdHistory("Stats2WSelect", NMCmdStr(wName, ""))
	
	return Stats2WSelect(wName)
	
End // Stats2WSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2WSelect(wName)
	String wName

	String df = StatsDF()
	
	Variable plotOn = NumVarOrDefault(df+"AutoPlot", 0)
	Variable wSelect = NumVarOrDefault(df+"WavSelectOn", 0)
	
	if ((strlen(wName) > 0) && (WaveExists($wName) == 0))
		wName = ""
	endif
	
	SetNMstr(df+"ST_2WaveSlct", wName)
	
	Stats2Compute()
	
	if ((strlen(wName) > 0) && (plotOn == 1))
		if (wSelect == 0)
			StatsPlot(wName)
		else
			Stats2Display()
		endif
	endif
	
	UpdateStats2()
	
	return 0
	
End // Stats2WSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2FilterSelectCall(select)
	String select
	
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
		
			Prompt strmatch, "enter new wave prefix match string:"
			DoPrompt "Change Stats2 Wave Select", strmatch
			
			if (V_flag == 1)
				return 0 // cancel
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
	
	UpdateStats2()
	
	return 0
	
End // Stats2FilterSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmpInit(win, force)
	Variable win // stats window or (-1) for current
	Variable force // force init (1 - yes; 0 - no)
	
	String df = StatsDF(), cdf = ChanDF(-1)
	
	Wave AmpB = $(df+"AmpB"); Wave AmpE = $(df+"AmpE");
	Wave BslnB = $(df+"BslnB"); Wave BslnE = $(df+"BslnE")
	
	Wave /T AmpSlct = $(df+"AmpSlct")
	
	if (win < 0)
		win = NumVarOrDefault(df+"AmpNV", 0)
	endif
	
	if ((StringMatch(AmpSlct[win], "Off") == 1) || (force == 1))
		if ((AmpE[win] == 0) && (win > 0))
			AmpB[win] = AmpB[win - 1]
			AmpE[win] = AmpE[win - 1]
		endif
		if ((BslnE[win] == 0) && (win > 0))
			BslnB[win] = BslnB[win - 1]
			BslnE[win] = BslnE[win - 1]
		endif
	endif

End // StatsAmpInit

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmpUpdate() // update current amp window result values

	String df = StatsDF()
	
	if (DataFolderExists(df) == 0)
		return 0 // stats has not been initialized yet
	endif
	
	NVAR AmpNV = $(df+"AmpNV")
	NVAR AmpBV = $(df+"AmpBV"); NVAR AmpEV = $(df+"AmpEV")
	NVAR AmpYV = $(df+"AmpYV"); NVAR AmpXV = $(df+"AmpXV")
	NVAR BslnYV = $(df+"BslnYV"); NVAR RiseTV = $(df+"RiseTV")
	NVAR DcayTV = $(df+"DcayTV"); NVAR SmthNV = $(df+"SmthNV")
	
	Wave AmpB = $(df+"AmpB"); Wave AmpE = $(df+"AmpE")
	Wave AmpY = $(df+"AmpY"); Wave AmpX = $(df+"AmpX")
	Wave BslnY = $(df+"BslnY"); Wave RiseTm = $(df+"RiseTm")
	Wave DcayT = $(df+"DcayT"); Wave SmthNum = $(df+"SmthNum")
	
	Wave /T SmthAlg = $(df+"SmthAlg")
	
	AmpBV = AmpB[AmpNV]; AmpEV = AmpE[AmpNV]
	AmpYV = AmpY[AmpNV]; AmpXV = AmpX[AmpNV]
	BslnYV = BslnY[AmpNV]; RiseTV = RiseTm[AmpNV]
	DcayTV = DcayT[AmpNV]; SmthNV = SmthNum[AmpNV]
	
	SetNMstr(df+"SmthAV", SmthAlg[AmpNV])

End // StatsAmpUpdate

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
//
//		Stats display graph functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDisplay(appnd) // append/remove display waves to current channel graph
	Variable appnd // (0) remove (1) append
	
	String df = StatsDF()
	
	if (DataFolderExists(df) == 0)
		return 0 // stats has not been initialized yet
	endif
	
	Variable acnt, anum, xy, icnt, ccnt, dragstyle = 5
	Variable r, g, b, br, bg, bb, rr, rg, rb
	String gName, wname = "", bname = ""
	
	Variable currentChan = NumVarOrDefault("CurrentChan", 0)
	
	Variable ampNV = NumVarOrDefault(df+"AmpNV", 0)
	Variable drag = NumVarOrDefault(df+"DragOn", 1)
	
	Wave AmpX = $(df+"AmpX")
	Wave AmpY = $(df+"AmpY")
	Wave Dsply = $(df+"Dsply")
	
	if (WaveExists($(df+"ST_DragBYB")) == 0)
		drag = 0
	endif
	
	if (StringMatch(NMTabCurrent(), "Stats") == 0)
		drag = 0
	endif
	
	for (ccnt = 0; ccnt < 10; ccnt += 1)
	
		gName = GetGraphName("Chan", ccnt)
	
		if (Wintype(gName) == 0)
			continue
		endif
		
		RemoveFromGraph /Z/W=$gName ST_BslnY, ST_WinY, ST_PntY, ST_RDY
		RemoveFromGraph /Z/W=$gName ST_DragBYB, ST_DragBYE, ST_DragWYB, ST_DragWYE
		
		if ((appnd == 0) || (ccnt != CurrentChan))
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
		
		if (drag == 1)
		
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
		
		// label tabs
		
		for (acnt = 1; acnt < numpnts(AmpX); acnt += 3)
			wname = "w" + num2str(anum) // window number
			bname = "b" + num2str(anum)
			if (Dsply[anum] == 1)
				// no tag label
			elseif (Dsply[anum] == 2)
				Tag /W=$gName/N=$wname/G=(r,g,b)/I=1/F=0/L=0/X=6.0/Y=0.00 ST_WinY, acnt, wname + " \\{\"(%.3g)\",TagVal(2)}"
				Tag /W=$gName/N=$bname/G=(br,bg,bb)/I=1/F=0/L=0/X=1.80/Y=0.00 ST_BslnY, acnt, bname + " \\{\"(%.3g)\",TagVal(2)}"
			elseif (Dsply[anum] == 3)
				Tag /W=$gName/N=$wname/G=(r,g,b)/I=1/F=0/L=0/X=1.80/Y=0.00 ST_WinY, acnt, wname
				Tag /W=$gName/N=$bname/G=(br,bg,bb)/I=1/F=0/L=0/X=1.80/Y=0.00 ST_BslnY, acnt, bname
			elseif (Dsply[anum] == 4)
				Tag /W=$gName/N=$wname/G=(r,g,b)/I=1/F=0/L=0/X=6.0/Y=0.00 ST_WinY, acnt, "\\{\"%.3g\",TagVal(2)}"
				Tag /W=$gName/N=$bname/G=(br,bg,bb)/I=1/F=0/L=0/X=1.80/Y=0.00 ST_BslnY, acnt, "\\{\"%.3g\",TagVal(2)}"
			endif
			anum += 1
		endfor
	
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
	
	if (DataFolderExists(df) == 0)
		return 0 // stats has not been initialized yet
	endif
	
	SetNMwave(df+"ST_BslnY", -1, Nan)
	SetNMwave(df+"ST_WinY", -1, Nan)
	SetNMwave(df+"ST_PntY", -1, Nan)
	SetNMwave(df+"ST_RDY", -1, Nan)
	
	SetNMwave(df+"ST_DragBYB", -1, Nan)
	SetNMwave(df+"ST_DragBYE", -1, Nan)
	SetNMwave(df+"ST_DragWYB", -1, Nan)
	SetNMwave(df+"ST_DragWYE", -1, Nan)

End // StatsDisplayClear

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
	
	if ((offset == 0) || (win < 0))
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
	
	SetNMvar(df+"AutoDoUpdate", 0)
	
	NMAutoStats()
	StatsTimeStamp()
	
	DoWindow /F $gname
	
End // StatsDragTrigger

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanControls(enable)
	Variable enable
	
	Variable drag, dragExists, ccnt
	String gName, cName, cdf, df = StatsDF()
	
	Variable currentChan = NumVarOrDefault("CurrentChan", 0)
	Variable numChan = NumVarOrDefault("NumChannels", 0)
	
	for (ccnt = 0; ccnt < numChan; ccnt += 1)
	
		cdf = ChanDF(ccnt)
		gName = ChanGraphName(ccnt)
		cName = "ST_DragOn" + num2str(ccnt)
	
		if (IsChanGraph(ccnt) == 0)
			continue
		endif
		
		ControlInfo /W=$gName $cName
		
		if (V_Flag == 2)
			dragExists = 1
		endif
		
		if ((ccnt == currentChan) && (enable == 1))
		
			ChanControlsDisable(ccnt, "011000")
			drag = NumVarOrDefault(df+"DragOn", 1)
		
			CheckBox $cName, win=$gName, title="stats drag", pos={340,3}, size={16,18}, value=drag, disable=0, proc=StatsCheckBox
	
		else
		
			ChanControlsDisable(ccnt, "000000")
			
			if (dragExists == 1)
				CheckBox $cName, win=$gName, disable=1
			endif
			
		endif
		
	endfor

End // StatsChanControls

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanSave(enable)
	Variable enable
	
	Variable ccnt, smthN, dt
	String smthA, cdf, df = StatsDF()
	
	Variable numChannels =  NumVarOrDefault("NumChannels", 0)
	
	for (ccnt = 0; ccnt < numChannels; ccnt += 1)
	
		cdf = ChanDF(ccnt)
	
		if (enable == 1)
				
			SetNMvar(df+"DTflag"+num2str(ccnt), NumVarOrDefault(cdf+"DTflag", 0))
			SetNMvar(df+"SmthNum"+num2str(ccnt), NumVarOrDefault(cdf+"SmthNum", 0))
			SetNMstr(df+"SmthAlg"+num2str(ccnt), StrVarOrDefault(cdf+"SmthAlg", ""))
			
		else
		
			dt = NumVarOrDefault(df+"DTflag"+num2str(ccnt), Nan)
			smthN = NumVarOrDefault(df+"SmthNum"+num2str(ccnt), Nan)
			smthA = StrVarOrDefault(df+"SmthAlg"+num2str(ccnt), "")
		
			if (numtype(dt) == 0)
				SetNMvar(cdf+"DTflag", dt)
				SetNMvar(df+"DTflag"+num2str(ccnt), Nan)
			endif
			
			if (numtype(smthN) == 0)
				SetNMvar(cdf+"SmthNum", smthN)
				SetNMstr(cdf+"SmthAlg", smthA)
				SetNMvar(df+"SmthNum"+num2str(ccnt), Nan)
				SetNMstr(df+"SmthAlg"+num2str(ccnt), "")
			endif
			
		endif
	
	endfor

End // StatsChanSave

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
	String df = StatsDF()
	
	if (StatsWinCount() == 0)
		return -1
	endif
	
	Wave /T AmpSlct = $(df+"AmpSlct")
	
	Variable allwin = NumVarOrDefault(df+"AllWinOn", 1)
	
	Variable winNum = -1 // all windows
	
	if (allwin == 0)
		winNum = NumVarOrDefault(StatsDF()+"AmpNV", 0)
		if (StringMatch(AmpSlct[winNum], "Off") == 1)
			DoAlert 0, "Current Stats window is off."
			return -1
		endif
	endif
	
	if (NMAllGroups() == 1)
	
		NMCmdHistory("StatsAllGroups", NMCmdNum(winNum,""))
		return StatsAllGroups(winNum)
		
	else
	
		NMCmdHistory("StatsAllWaves", NMCmdNum(winNum,""))
		return StatsAllWaves(winNum)
		
	endif

End // StatsAllWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAllWaves(winNum)
	Variable winNum // stats1 window number (-1 for all)

	Variable ccnt, wcnt, pflag, forcenew
	String wList, sName, tName, df = StatsDF()
	
	Variable NumWaves = NumVarOrDefault("NumWaves", 0)
	Variable saveCurrentWave = NumVarOrDefault("CurrentWave", 0)
	
	CheckNMwave(df+"WinSelect", 10, 0)
	SetNMwave(df+"WinSelect", -1, 0)
	SetNMwave(df+"WinSelect", winNum, 1)
	
	Wave  ChanSelect, WavSelect
	
	WaveStats /Q WavSelect
	
	if (V_max != 1)
		DoAlert 0, "No Waves Selected!"
		return -1
	endif
	
	if (winNum == -1)
		forcenew = 1
	endif
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
		
		tName = StatsWavesTables(ccnt, forcenew)
	
		for (wcnt = 0; wcnt <  NumWaves; wcnt += 1)
		
			pflag = CallProgress(wcnt/(NumWaves-1))
			
			if (pflag == 1)
				break
			endif
			
			if (WavSelect[wcnt] == 1)
				SetNMvar("CurrentWave", wcnt)
				setNMvar("CurrentGrp", NMGroupGet(wcnt))
				sName = ChanWaveName(ccnt, wcnt)
				StatsComputeAmps(sName, ccnt, wcnt, winNum, 1, 0)
			endif
				
		endfor
		
	endfor
	
	SetNMvar("CurrentWave", saveCurrentWave)
	setNMvar("CurrentGrp", NMGroupGet(saveCurrentWave))
	
	NMAutoStats()
	
	if (WinType(tName) == 2)
		DoWindow /F $tName
	endif
	
	if (NumVarOrDefault(df+"AutoStats2", 0) == 1)
		Stats2WSelectDefault()
		UpdateStats2()
	endif
	
	return 0

End // StatsAllWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAllGroups(winNum)
	Variable winNum // stats1 window number (-1 for all)
	
	Variable gcnt
	String df = NMDF()
	
	Variable saveNameformat = NumVarOrDefault(df+"NameFormat", 1)
	
	String saveSelect = NMWaveSelectGet()
	String grpList = NMGroupList(1)
	
	SetNMVar(df+"NameFormat", 1) // force long name format
	
	for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
		NMWaveSelect(StringFromList(gcnt, grpList))
		StatsAllWaves(winNum)
	endfor

	NMWaveSelect(saveSelect) // back to original wave select
	SetNMVar(df+"NameFormat", saveNameFormat) // back to original format
	
	return 0

End // StatsAllGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAutoStats() // compute Stats of currently selected channel/wave
	String df = StatsDF(), cdf = ChanDF(-1)

	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)
	
	String StatWaveName = CurrentWaveName() // source wave name
	
	Variable drag = NumVarOrDefault(df+"DragOn", 1)
	
	if (StringMatch(NMTabCurrent(), "Stats") == 0)
		drag = 0
	endif
	
	if (WaveExists($StatWaveName) == 0)
		return 0
	endif
	
	if (drag == 1)
		if (NumVarOrDefault(df+"AutoDoUpdate", 0) == 1) // new for drag waves to work
			if (NumVarOrDefault(cdf+"AutoScale", 1) == 1)
				StatsDisplayClear() // must clear waves first to get autoscale to work
				//ChanGraphsUpdate()
				DoUpdate
			endif
		endif
	endif
	
	StatsComputeAmps(StatWaveName, CurrentChan, CurrentWave, -1, 0, 1)
	Stats2Compute()
	StatsAmpUpdate()
	UpdateStats()
	SetNMvar(df+"AutoDoUpdate", 1)

End // NMAutoStats

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsComputeAmps(sName, chnNum, wavNum, win, saveflag, dsplyflag) // compute amps of given wave
	String sName // wave name to measure
	Variable chnNum // channel number
	Variable wavNum // wave number
	Variable win // stat window (-1) all
	Variable saveflag // save to table waves
	Variable  dsplyflag // update display waves

	Variable acnt, afirst, alast, smthn, error
	String smtha, dName = "WaveCopy", df = StatsDF()
	
	Wave dtFlag = $(df+"dtFlag")
	Wave SmthNum = $(df+"SmthNum")
	Wave /T SmthAlg = $(df+"SmthAlg")
	Wave /T AmpSlct = $(df+"AmpSlct")
	
	if (win == -1)
		afirst = 0; alast = numpnts(SmthNum)
	else
		afirst = win; alast = win+1
	endif

	for (acnt = afirst; acnt < alast; acnt += 1)
		
		if (StringMatch(AmpSlct[acnt], "Off") == 1)
		
			StatsAmpCompute(acnt, "Set1", dsplyflag) // this will set variables to Nan
			
		else
		
			error = MakeWave(sName, dName, dtFlag[acnt], SmthNum[acnt], SmthAlg[acnt]) // function located in "Utility.ipf"
			
			if (error < 0)
				continue
			endif
			
			StatsAmpCompute(acnt, dName, dsplyflag)
		
			if (saveflag == 1)
				StatsAmpSave(sName, chnNum, wavNum, acnt, 0)
			endif
			
		endif
			
	endfor
	
	KillWaves /Z $dName
		
End // StatsComputeAmps

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmpCompute(win, wName, dsplyflag) // compute the amp stats
	Variable win // amplitude number
	String wName // wave to measure
	Variable dsplyflag
	
	Variable tbgn, tend, ay, ax, aybsln, by, bx, dumvar
	Variable offset, displayOff, nset, vbgn, vend
	String slct, dumstr
	
	String df = StatsDF()
	String gName = CurrentChanGraphName()
	
	Variable drag = NumVarOrDefault(df+"DragOn", 1)
	Variable offsetBsln = NumVarOrDefault(df+"OffsetBsln", 1)
	Variable ampNV = NumVarOrDefault(df+"AmpNV", 0)
	
	if (DataFolderExists(df) == 0)
		return 0 // stats has not been initialized yet
	endif
	
	if (WaveExists($wName) == 0)
		return 0
	endif
	
	Wave wtemp = $wName
	
	Wave /T AmpSlct = $(df+"AmpSlct");
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
	Wave Dsply = $(df+"Dsply")
	
	Wave ST_PntX = $(df+"ST_PntX"); Wave ST_PntY = $(df+"ST_PntY")
	Wave ST_WinX = $(df+"ST_WinX"); Wave ST_WinY = $(df+"ST_WinY")
	Wave ST_BslnX = $(df+"ST_BslnX"); Wave ST_BslnY = $(df+"ST_BslnY")
	Wave ST_RDX = $(df+"ST_RDX"); Wave ST_RDY = $(df+"ST_RDY")
	
	if (drag == 1)
		Wave ST_DragBYB = $(df+"ST_DragBYB"); Wave ST_DragBXB = $(df+"ST_DragBXB")
		Wave ST_DragBYE = $(df+"ST_DragBYE"); Wave ST_DragBXE = $(df+"ST_DragBXE") 
		Wave ST_DragWYB = $(df+"ST_DragWYB"); Wave ST_DragWXB = $(df+"ST_DragWXB")
		Wave ST_DragWYE = $(df+"ST_DragWYE"); Wave ST_DragWXE = $(df+"ST_DragWXE")
	endif
	
	offset = max(0, StatsOffsetValue(win))
	
	slct = AmpSlct[win]
	
	displayOff = ((Dsply[win] == 0) || (StringMatch(slct[0,4], "Off") == 1))
	
	strswitch(slct)
		case "Level":
		case "Level+":
		case "Level-":
			break
		default:
			AmpY[win] = Nan
	endswitch
	
	AmpX[win] = Nan; BslnY[win] = Nan
	RiseBX[win] = Nan; RiseEX[win] = Nan; RiseTm[win] = Nan
	DcayX[win] = Nan; DcayT[win] = Nan
	
	// compute baseline stats
	
	if (Bflag[win] == 1)
	
		if (BslnB[win] > BslnE[win])
			dumvar = BslnE[win] // switch
			BslnE[win] = BslnB[win]
			BslnB[win] = dumvar
		endif
	
		slct = BslnSlct[win]
		tbgn = BslnB[win] + offset
		tend = BslnE[win] + offset
		by = Nan; bx = Nan
	
		if (tbgn < tend)
			ComputeWaveStats(wtemp, tbgn, tend, slct, 0)
			by = NumVarOrDefault("U_ay", Nan)
			bx = NumVarOrDefault("U_ax", Nan)
		endif
		
		BslnY[win] = by
		BslnX[win] = bx
	
	endif
	
	// baseline display waves
	
	if (dsplyflag == 1)
	
		nset = win*3
		
		if (displayOff == 1)
		
			ST_BslnX[nset] = Nan
			ST_BslnX[nset+1] = Nan
		
			if ((drag == 1) && (win == AmpNV))
				ST_DragBXB = Nan
				ST_DragBXE = Nan
			endif
			
		else
		
			vbgn = BslnB[win] + offset*offsetBsln
			vend = BslnE[win] + offset*offsetBsln
			
			ST_BslnX[nset] = vbgn
			ST_BslnX[nset+1] = vend
			
			if ((drag == 1) && (win == AmpNV))
				ST_DragBXB = vbgn
				ST_DragBXE = vend
			endif
			
		endif
		
		ST_BslnY[nset] = by
		ST_BslnY[nset+1] = by
	
	endif
	
	// compute amplitude stats
	
	if (AmpB[win] > AmpE[win])
		dumvar = AmpE[win] // switch
		AmpE[win] = AmpB[win]
		AmpB[win] = dumvar
	endif
	
	tbgn = AmpB[win] + offset
	tend = AmpE[win] + offset
	slct = AmpSlct[win]
	
	ComputeWaveStats(wtemp, tbgn, tend, slct, AmpY[win])
	
	ay = NumVarOrDefault("U_ay", Nan)
	ax = NumVarOrDefault("U_ax", Nan)
	
	// amp display waves
	
	if (dsplyflag == 1)
	
		nset = win*2
		
		ST_PntX[nset] = ax
		ST_PntY[nset] = ay
		
		strswitch(slct)
			case "Slope":
			case "RTSlope+":
			case "RTSlope-":
				ST_PntX[nset] = Nan
				ST_PntY[nset] = Nan
		endswitch
		
	endif
	
	// compute rise/decay time stats
	
	strswitch(slct)
		case "SDev":
		case "Var":
		case "RMS":
		case "Area":
		case "Slope":
			break
		default:
	
		if (Rflag[win] == 1)
		
			dumvar = ((RiseBP[win]/100)*(ay-by)) + by
			FindLevel /Q/R=(ax, tbgn) wtemp, dumvar
		
			if (V_Flag == 0)
				RiseBX[win] =  V_LevelX
			endif
		
			dumvar = ((RiseEP[win]/100)*(ay-by)) + by
			FindLevel /Q/R=(ax, tbgn) wtemp, dumvar
			
			if (V_Flag == 0)
				RiseEX[win] =  V_LevelX
			endif
			
			RiseTm[win] = RiseEX[win] - RiseBX[win]
		
		endif
		
		// compute decay time stats
		
		if ((Dflag[win] == 1) && (StringMatch(slct, "Avg") == 0))
			
			dumvar = ((DcayP[win]/100)*(ay-by)) + by
			FindLevel /Q/R=(ax, tend) wtemp, dumvar
			
			if (V_Flag == 0)
				DcayX[win] = V_LevelX
			endif
			
			DcayT[win] = DcayX[win] - ax
			
		endif
	
	endswitch
	
	// rise/decay display waves
	
	if (dsplyflag == 1)
	
		nset = win*4
		
		if (displayOff == 1)
			ST_RDX[nset] = Nan
			ST_RDX[nset+1] = Nan
			ST_RDX[nset+2] = Nan
		else
			ST_RDX[nset] = RiseBX[win]
			ST_RDX[nset+1] = RiseEX[win]
			ST_RDX[nset+2] = DcayX[win]
		endif
		
		ST_RDY[nset] = ((RiseBP[win]/100)*(ay-by)) + by
		ST_RDY[nset+1] = ((RiseEP[win]/100)*(ay-by)) + by
		ST_RDY[nset+2] = ((DcayP[win]/100)*(ay-by)) + by
		
		ST_RDY[nset] *= (ST_RDX[nset]/ST_RDX[nset]) // becomes Nan if X = Nan
		ST_RDY[nset+1] *= (ST_RDX[nset+1]/ST_RDX[nset+1])
		ST_RDY[nset+2] *= (ST_RDX[nset+2]/ST_RDX[nset+2])
	
	endif
	
	// new rise-time slope functions
	
	strswitch(slct)
		case "RTSlope+":
		case "RTSlope-":
			dumstr = FindSlope(RiseBX[win], RiseEX[win], wName) // function located in "Utility.ipf"
			ax = str2num(StringByKey("b", dumstr, "="))
			ay = str2num(StringByKey("m", dumstr, "="))
			break
	endswitch
	
	// subtract baseline values
	
	aybsln = ay
	
	if ((BslnSubt[win] == 1) && (StringMatch(slct[0,4], "Level") == 0) && (StringMatch(slct[0,4], "Slope") == 0))
		aybsln -= by
	endif
	
	// save final results
	
	if (tbgn >= tend)
		aybsln = Nan
		ax = Nan
	endif
	
	AmpY[win] = aybsln
	AmpX[win] = ax
	
	// amp window display line
	
	if (dsplyflag == 1)
		
		nset = win*3
		
		if (displayOff == 1)
		
			ST_WinX[nset] = Nan
			ST_WinX[nset+1] = Nan
			
			if ((drag == 1) && (win == AmpNV))
				ST_DragWXB = Nan
				ST_DragWXE = Nan
			endif
			
		else
		
			strswitch(slct)
				case "RTSlope+":
				case "RTSlope-":
					vbgn = RiseBX[win] + offset
					vend = RiseEX[win] + offset
					break
				
				default:
					vbgn = AmpB[win] + offset
					vend = AmpE[win] + offset
			endswitch
		
			ST_WinX[nset] = vbgn
			ST_WinX[nset+1] = vend
			
			ST_WinX[nset] = vbgn
			ST_WinX[nset+1] = vend
			
			if ((drag == 1) && (win == AmpNV))
				ST_DragWXB = AmpB[win] + offset
				ST_DragWXE = AmpE[win] + offset
			endif
			
		endif
		
		strswitch(slct)
		
			case "Slope":
				vbgn = AmpB[win]*ay + ax
				vend = AmpE[win]*ay + ax
				ST_WinY[nset] = vbgn
				ST_WinY[nset+1] = vend
				break
				
			case "RTSlope+":
			case "RTSlope-":
				vbgn = RiseBX[win]*ay + ax
				vend = RiseEX[win]*ay + ax
				ST_WinY[nset] = vbgn
				ST_WinY[nset+1] = vend
				break
				
			default:
				ST_WinY[nset] = ay
				ST_WinY[nset+1] = ay
				break
				
		endswitch
		
		// drag waves
	
		if ((win == ampNV) && (drag == 1) && (WinType(gName) == 1))
		
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
	
	endif
	
	KillVariables /Z U_ax, U_ay

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

Function /S StatsWavesTables(chnNum, forcenew) // create waves/table where Stats are stored
	Variable chnNum // channel number
	Variable forcenew // force new waves
	
	Variable wcnt
	String tprefix, wname, wlist, title, slctStr = "", tname = ""
	String df = StatsDF(), ndf = NMDF()
	
	Variable NumWaves = NumVarOrDefault("NumWaves", 0)
	Variable format = NumVarOrDefault(ndf+"NameFormat", 1)
	
	Variable tables = NumVarOrDefault(df+"TablesOn", 1)
	
	Variable overwrite = NMOverWrite()
	
	if (format == 1)
		slctStr = NMWaveSelectStr() + "_"
	endif

	tprefix = StatsPrefix(NMFolderPrefix("") + slctStr + "Table_")
	
	wName = StatsWaveName(Nan, "wName_", chnNum, overwrite)
	
	if (forcenew == 1)
	
		Make /T/O/N=(NumWaves) $wName
		
		NMNoteType(wName, "Stats Wave Name", "", "", "")
		
		Wave /T tempWave = $wName
		Wave /T ChanWaveList
		
		tempWave = ""
		wlist = ChanWaveList(chnNum)
		
		for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
			tempWave[wcnt] = StringFromList(wcnt,wlist)
		endfor
		
	endif
	
	wlist = StatsWavesMake(chnNum, forcenew)
	
	if (tables == 1)
	
		tName = NextGraphName(tprefix, chnNum, overwrite)
	
		if (WinType(tName) == 0)
		
			title = NMFolderListName("") + " : Ch " + ChanNum2Char(chnNum) + " : Stats : " + NMWaveSelectGet()
		
			DoWindow /K $tName
			Edit /K=1/W=(0,0,0,0) $wName
			DoWindow /C $tName
			SetCascadeXY(tName)
			DoWindow /T $tName, title
			Execute "ModifyTable title(Point)= \"Wave\""
			
		endif
		
		DoWindow /F $tName
	
		for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
			wname = StringFromList(wcnt, wlist)
			if (WaveExists($wname) == 1)
				AppendToTable $wname
			endif
		endfor
	
	endif
	
	return tName

End // StatsWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesMake(chnNum, forcenew)
	Variable chnNum // channel number
	Variable forcenew // force new waves

	Variable acnt, wselect, offset, xwave = 1
	String wname, header, statsnote, wnote, xl, yl, wlist = ""
	
	String df = StatsDF()
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	
	String wPrefix = StrVarOrDefault("CurrentPrefix", "Wave")
	
	String xLabel = ChanLabel(-1, "x", CurrentWaveName())
	String yLabel = ChanLabel(-1, "y", CurrentWaveName())
	
	String xUnits = UnitsFromStr(xLabel)
	String yUnits = UnitsFromStr(yLabel)
	
	if (WaveExists($(df+"WinSelect")) == 1)
		wselect = 1
		Wave WinSelect = $(df+"WinSelect")
	endif

	Wave /T AmpSlct = $(df+"AmpSlct")
	Wave AmpB = $(df+"AmpB"); Wave AmpE = $(df+"AmpE")
	
	Wave /T BslnSlct = $(df+"BslnSlct")
	Wave Bflag = $(df+"Bflag"); Wave BslnSubt = $(df+"BslnSubt")
	Wave BslnB = $(df+"BslnB"); Wave BslnE = $(df+"BslnE")
	
	Wave Rflag = $(df+"Rflag")
	Wave RiseBP = $(df+"RiseBP"); Wave RiseEP = $(df+"RiseEP")
	
	Wave Dflag = $(df+"Dflag"); Wave DcayP = $(df+"DcayP")
	
	Wave SmthNum = $(df+"SmthNum"); Wave /T SmthAlg = $(df+"SmthAlg")
	Wave dtFlag = $(df+"dtFlag")
	
	xl = wPrefix + "#"

	for (acnt = 0; acnt < numpnts(AmpSlct); acnt += 1)
		
		if ((wselect == 1) && (WinSelect[acnt] == 0))
			continue
		endif
	
		if (StringMatch(AmpSlct[acnt], "Off") == 1)
			continue
		endif
		
		offset = max(0, StatsOffsetValue(acnt))
		
		header = "WPrefix:" + wPrefix
		header += "\rChanSelect:" + ChanNum2Char(chnNum)
		header += "\rWaveSelect:" + NMWaveSelectGet()
		
		statsnote = "\rStats Win:" + num2str(acnt) + ";Stats Alg:" + AmpSlct[acnt] + ";"
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
			statsnote += "\rF(t):normalize"
		endif
		
		yl = StatsYLabel(AmpSlct[acnt])
		
		wname = StatsWaveMake("AmpY", acnt, chnNum, forcenew)
		NMNoteType(wName, "NMStats Yvalues", xl, yl, header + statsnote)
		wlist = AddListItem(wname, wlist, ";", inf)
		
		yl = xLabel
		
		strswitch(AmpSlct[acnt])
			case "Avg":
			case "SDev":
			case "Var":
			case "RMS":
			case "Area":
				xwave = 0
				break
			case "Slope":
				yl = yLabel // intercept value
				break
		endswitch
		
		if (xwave == 1)
			wname = StatsWaveMake("AmpX", acnt, chnNum, forcenew)
			NMNoteType(wName, "NMStats Xvalues", xl, yl, header + statsnote)
			wlist = AddListItem(wname, wlist, ";", inf)
		endif
		
		yl = StatsYLabel(BslnSlct[acnt])
		
		if (Bflag[acnt] == 1)
			wname = StatsWaveMake("Bsln", acnt, chnNum, forcenew)
			wnote = "\rBsln Alg:" + BslnSlct[acnt] + ";Bsln Tbgn:" + num2str(BslnB[acnt]+offset) + ";Bsln Tend:" + num2str(BslnE[acnt]+offset) + ";"
			NMNoteType(wName, "NMStats Bsln", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
		endif
		
		if (Rflag[acnt] == 1)
		
			yl = num2str(RiseBP) + " - " + num2str(RiseEP) + "% Rise Time (" + xUnits + ")"

			wname = StatsWaveMake("RiseT", acnt, chnNum, forcenew)
			wnote = "\rRise %bgn:" + num2str(RiseBP) + ";Rise %end:" + num2str(RiseEP) + ";"
			NMNoteType(wName, "NMStats RiseTime", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
			
			yl = num2str(RiseBP) + "% Rise Pnt (" + xUnits + ")"
			
			wname = StatsWaveMake("RiseBX", acnt, chnNum, forcenew)
			wnote = "\rRise %bgn:" + num2str(RiseBP)
			NMNoteType(wName, "NMStats RiseTbgn", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
			
			yl = num2str(RiseEP) + "% Rise Pnt (" + xUnits + ")"
			
			wname = StatsWaveMake("RiseEX", acnt, chnNum, forcenew)
			wnote = "\rRise %end:" + num2str(RiseBP)
			NMNoteType(wName, "NMStats RiseTend", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
			
		endif
		
		if (Dflag[acnt] == 1)
		
			yl = num2str(DcayP) + "% Decay Time (" + xUnits + ")"
		
			wname = StatsWaveMake("DcayT", acnt, chnNum, forcenew)
			wnote = "\r%Decay:" + num2str(DcayP)
			NMNoteType(wName, "NMStats DecayTime", xl, yl, header + statsnote + wnote)
			wlist = AddListItem(wname, wlist, ";", inf)
			
			yl = num2str(DcayP) + "% Decay Pnt (" + xUnits + ")"
			
			wname = StatsWaveMake("DcayX", acnt, chnNum, forcenew) 
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
		case "Slope":
			return "Slope (" + yunits + " / " + xunits + ")"
	endswitch
	
	return yl
	
End // StatsYLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWaveMake(fxn, win, chnNum, forcenew) // create appropriate stats wave
	String fxn
	Variable win
	Variable chnNum
	Variable forcenew // force new waves

	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	
	String wName = StatsWaveName(win, fxn, chnNum, NMOverWrite())
	
	if ((WaveExists($wName) == 0) || (forcenew == 1))
		Make /O/N=(nwaves) $wName = NaN
	endif
	
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
	
	return NextWaveName(wPrefix, chanNum, overWrite)

End // StatsWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsAmpName(win)
	Variable win
	
	Wave /T AmpSlct = $(StatsDF()+"AmpSlct")
	
	String fxn = AmpSlct[win]
	
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
		case "Off":
			return ""
	endswitch
	
	return fxn

End // StatsAmpName

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinSelectUpdate()
	Variable acnt
	String df = StatsDF()
	
	Wave WinSelect = $(df+"WinSelect")

	Wave /T AmpSlct = $(df+"AmpSlct")
	
	WinSelect = 0
	
	for (acnt = 0; acnt < NumPnts(AmpSlct); acnt += 1)
		if (StringMatch(AmpSlct[acnt], "Off") == 0)
			WinSelect[acnt] = 1
		endif
	endfor

End // StatsWinSelectUpdate

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

Function /S StatsWinList(select)
	Variable select // (0) all available (1) not off
	Variable icnt
	String wlist = "", df = StatsDF()
	
	Wave /T AmpSlct = $(df+"AmpSlct")
	
	for (icnt = 0; icnt < numpnts(AmpSlct); icnt += 1)
		if (select == 0)
			wlist = AddListItem("Win"+num2str(icnt), wlist, ";", inf)
		elseif (StringMatch(AmpSlct[icnt], "Off") == 0)
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

Function /S StatsAmpList()

	return "Max;Min;Avg;SDev;Var;RMS;Area;Slope;RTSlope+;RTSlope-;Level;Level+;Level-;Off;"

End // StatsAmpList

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

Function StatsAmpSave(sName, chnNum, wavNum, win, clear) // save results to appropriate Stat waves
	String sName // wave name
	Variable chnNum // channel number
	Variable wavNum // wave number
	Variable win // stats window
	Variable clear // clear option (0 - save; 1 - clear)
	
	String wName
	String wselect = NMWaveSelectGet()
	String df = StatsDF()
	
	Variable Nameformat=NumVarOrDefault(NMDF() + "NameFormat", 1)
	
	Wave /T AmpSlct = $(df+"AmpSlct")
	Wave AmpY = $(df+"AmpY"); Wave AmpX = $(df+"AmpX")
	
	Wave BslnY = $(df+"BslnY"); Wave Bflag = $(df+"Bflag")
	
	Wave RiseBX = $(df+"RiseBX"); Wave RiseEX = $(df+"RiseEX")
	Wave RiseTm = $(df+"RiseTm"); Wave Rflag = $(df+"Rflag")
	
	Wave DcayX = $(df+"DcayX"); Wave DcayT = $(df+"DcayT")
	Wave Dflag = $(df+"Dflag")
	
	if (StringMatch(AmpSlct[win], "Off") == 1)
		return 0
	endif
	
	if (clear == 1)
		clear = Nan
	else
		clear = 1
	endif
	
	wName = StatsWaveName(win, "AmpY", chnNum, 1)
	
	if (WaveExists($wName) == 1)
		Wave ST_AmpY = $wName
		ST_AmpY[wavNum] = AmpY[win]*clear
	endif
	
	wName = StatsWaveName(win, "AmpX", chnNum, 1)

	if (WaveExists($wName) == 1)
		Wave ST_AmpX = $wName
		ST_AmpX[wavNum] = AmpX[win]*clear
	endif

	if (Bflag[win] == 1)
	
		wName = StatsWaveName(win, "Bsln", chnNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_Bsln = $wName 
			ST_Bsln[wavNum] = BslnY[win]*clear
		endif
		
	endif
		
	if (Rflag[win] == 1)
	
		wName = StatsWaveName(win, "RiseBX", chnNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_RiseBX = $wName
			ST_RiseBX[wavNum] = RiseBX[win]*clear
		endif
		
		wName = StatsWaveName(win, "RiseEX", chnNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_RiseEX = $wName
			ST_RiseEX[wavNum] = RiseEX[win]*clear
		endif
		
		wName = StatsWaveName(win, "RiseT", chnNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_RiseT = $wName
			ST_RiseT[wavNum] = RiseTm[win]*clear
		endif
		
	endif
		
	if (Dflag[win] == 1)
	
		wName = StatsWaveName(win, "DcayX", chnNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_DcayX = $wName
			ST_DcayX[wavNum] = DcayX[win]*clear
		endif
		
		wName = StatsWaveName(win, "DcayT", chnNum, 1)
		
		if (WaveExists($wName) == 1)
			Wave ST_DcayT = $wName
			ST_DcayT[wavNum] = DcayT[win]*clear
		endif
		
	endif

End // StatsAmpSave

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Stats2 functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2WSelectDefault()
	String wname, df = StatsDF()
	
	if (strlen(StrVarOrDefault(df+"ST_2WaveSlct", "")) > 0)
		//return 0
	endif
	
	Variable cChan = NumVarOrDefault("CurrentChan", 0)
	Variable win = NumVarOrDefault(df+"AmpNV", 0)
	
	wname = StatsWaveName(win, "AmpY", cChan, 1)
	
	String wlist = WaveList(wname, ";", WaveListText0())
	
	Stats2WSelect(StringFromList(0,wlist))

End // Stats2WSelectDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2AllCall()

	NMCmdHistory("Stats2All", "")
	return Stats2All()

End // Stats2AllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2All()
	Variable icnt, nwaves
	String saveName, wList = Stats2List(), df = StatsDF()
	
	SVAR ST_2WaveSlct = $(df+"ST_2WaveSlct")
	
	saveName = ST_2WaveSlct
	
	nwaves = ItemsInList(wList)
	Stats2Table(1)
	
	for (icnt = 0; icnt < nwaves; icnt += 1)
		ST_2WaveSlct = StringFromList(icnt, wList)
		Stats2Compute()
		Stats2Save()
	endfor
	
	// back to original wave
	
	ST_2WaveSlct = saveName
	Stats2Compute()
	
	return 0
	
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
	
	Variable wSelect = NumVarOrDefault(df+"WavSelectOn", 0)
	
	NVAR ST_2AVG = $(df+"ST_2AVG"); NVAR ST_2SDV = $(df+"ST_2SDV")
	NVAR ST_2SEM = $(df+"ST_2SEM"); NVAR ST_2CNT = $(df+"ST_2CNT")
	
	SVAR ST_2WaveSlct = $(df+"ST_2WaveSlct")
	
	ST_2CNT = Nan; ST_2AVG = Nan; ST_2SDV = Nan; ST_2SEM = Nan
	
	if (exists(ST_2WaveSlct) == 0)
		return 0 // wave does not exist
	endif
	
	Wave ST_Stats2Wave = $(df+"ST_Stats2Wave")
	Wave tempWave = $ST_2WaveSlct
	Wave WavSelect
	
	Redimension /N=(numpnts(tempWave)) ST_Stats2Wave
	
	ST_Stats2Wave = tempWave
	
	Note /K ST_Stats2Wave
	Note ST_Stats2Wave, note(tempWave)
	
	if (wSelect == 1)
		for (icnt = 0; icnt < numpnts(ST_Stats2Wave); icnt += 1)
			if (WavSelect[icnt] != 1)
				ST_Stats2Wave[icnt] = Nan
			endif
		endfor
	endif
	
	WaveStats /Q ST_Stats2Wave
		
	ST_2CNT = V_npnts
		
	if (ST_2CNT > 0)
		ST_2AVG = V_avg
		ST_2SDV = V_sdev
		ST_2SEM = V_sdev/sqrt(V_npnts)
	endif

End // Stats2Compute

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2List() // create Stats2 wave list

	Variable icnt, wnum = -1
	String numstr, wName, remList = "", wList = "", wList2 = ""
	String df = StatsDF()
	
	String opstr = WaveListText0()
	
	SVAR ST_2WaveSlct = $(df+"ST_2WaveSlct")
	SVAR ST_2StrMatch = $(df+"ST_2StrMatch")
	
	remList = WaveList("*Offset*", ";", opstr)
	
	if (StringMatch(ST_2StrMatch, "All") == 1)
	
		wList = WaveList("ST_*", ";", opstr) + WaveList("ST2_*", ";", opstr)
		wnum = -2
	
	elseif (StringMatch(ST_2StrMatch[0,2], "Win") == 1)
	
		wnum = str2num(ST_2StrMatch[3,inf])
		
		if (numtype(wnum) > 0)
			ST_2StrMatch = "ST_*"
			wnum = -1
		endif
	
	endif

	if (wnum == -1)
	
		wList = WaveList(ST_2StrMatch, ";", opstr)
	
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
	
	strswitch(ST_2StrMatch[0,2])
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
	
	if ((WhichListItem(ST_2WaveSlct, wList) < 0) && (exists(ST_2WaveSlct) == 1))
		wList += ST_2WaveSlct + ";"
	endif
	
	return wList
	
End // Stats2List

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2Display()

	String gTitle, df = StatsDF()
	
	String ggName, gName = "ST_Stats2Wave_Plot"

	String ST_2WaveSlct = StrVarOrDefault(df+"ST_2WaveSlct", "")
	
	Variable WavSelectOn = NumVarOrDefault(df+"WavSelectOn", 0)
	
	if (WavSelectOn == 1)
		gTitle = "Stats2 : " + ST_2WaveSlct + " : " +  NMWaveSelectGet()
	else
		gTitle = "Stats2 : " + ST_2WaveSlct
	endif
	
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

Function StatsPlotAutoCall(on)
	Variable on // (0) no (1) yes
	
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
	
	if (exists(wName) == 0)
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
	
	if (numtype(tbgn*tend) == 0)
		txt += num2str(tbgn) + " - " + num2str(tend) + " ms"
	endif
	
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

Function /S StatsSortCall()
	String vlist = "", df = StatsDF()
	
	String wName = StrVarOrDefault(df+"ST_2WaveSlct", "")
	Variable wSelect = NumVarOrDefault(df+"WavSelectOn", 0)
	
	vlist = NMCmdStr(wName, vlist)
	vlist = NMCmdNum(wSelect, vlist)
	NMCmdHistory("StatsSort", vlist)
	
	return StatsSort(wName, wSelect)
	
End // StatsSortCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsSort(wName, wSelect)
	String wName // stats wave name
	Variable wSelect // wave select (0) off (1) on
	
	String gName, sName, ssName, gTitle, df = StatsDF()
	
	Variable overWrite = NMOverWrite()
	
	if (wSelect == 0)
		return StatsSortWave(wName)
	endif
	
	gName = StatsSortWave(df+"ST_Stats2Wave")
	
	if (strlen(gName) == 0)
		return ""
	endif
	
	sName = NextWaveName("ST_Stats2Wave_Sort", -1, 1)
	ssName = NextWaveName(wName + "_Sort", -1, overWrite)
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
	
	if (exists(wName) == 0)
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
	
	dName = NextWaveName(pName + "_Sort", -1, overwrite)
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
	Variable wSelect = NumVarOrDefault(df+"WavSelectOn", 0)
	
	vlist = NMCmdStr(wName, vlist)
	vlist = NMCmdNum(wSelect, vlist)
	NMCmdHistory("StatsHistogram", vlist)
	
	return StatsHistogram(wname, wSelect)
	
End // StatsHistoCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsHistogram(wname, wSelect)
	String wname
	Variable wSelect // wave select (0) off (1) on
	
	String xl, yl, gName, ggTitle, hhName, hName, oldnote, df = StatsDF()
	
	Variable overWrite = NMOverWrite()
	
	if (wSelect == 0)
		return StatsHisto(wName)
	endif 
	
	gName = StatsHisto(df+"ST_Stats2Wave")
	
	if (strlen(gName) == 0)
		return ""
	endif
	
	hName = NextWaveName("ST_Stats2Wave_Hist", -1, 1)
	hhName = NextWaveName(wName + "_Hist", -1, overWrite)
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
	
	if (exists(wName) == 0)
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
	dName = NextWaveName(pName+"_Hist", -1, overWrite)
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
	Variable wSelect = NumVarOrDefault(df+"WavSelectOn", 0)
	
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

Function Stats2SaveCall()

	NMCmdHistory("Stats2Save", "")
	return Stats2Save()

End // Stats2SaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2Save()
	Variable npnts
	String df = StatsDF()

	NVAR ST_2AVG =  $(df+"ST_2AVG"); NVAR ST_2SDV =  $(df+"ST_2SDV")
	NVAR ST_2SEM =  $(df+"ST_2SEM"); NVAR ST_2CNT =  $(df+"ST_2CNT")
	
	SVAR ST_2WaveSlct = $(df+"ST_2WaveSlct")
	
	if (StringMatch(ST_2WaveSlct, "Off") == 1)
		return 0
	endif

	Stats2Table(0)
	
	Wave ST2_AVG, ST2_SDV, ST2_SEM, ST2_CNT
	Wave /T ST2_wName
	
	npnts = numpnts(ST2_wName) + 1
	
	Redimension /N=(npnts) ST2_wName, ST2_AVG, ST2_SDV, ST2_SEM, ST2_CNT
	
	ST2_wName[npnts-1] = ST_2WaveSlct
	ST2_AVG[npnts-1] = ST_2AVG
	ST2_SDV[npnts-1] = ST_2SDV
	ST2_SEM[npnts-1] = ST_2SEM
	ST2_CNT[npnts-1] = ST_2CNT
	
	return 0
	
End // Stats2Save

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2Table(force) // create waves/table where Stats2 are stored
	Variable force // force make table
	
	String df = StatsDF()
	
	String filter = StrVarOrDefault(df+"ST_2MatchSlct", "")
	
	String tPrefix = "ST2_" + NMFolderPrefix("") + filter + "_Table"
	String tName = NextGraphName(tPrefix, -1, NMOverWrite())
	String titlestr = NMFolderListName("") + " : Stats2 Table"
	
	if ((WinType(tName) == 2) && (force == 0))
		DoWindow /F $tName
		return 0 // table already exists
	endif
	
	Make /T/O/N=0 ST2_wName
	Make /O/N=0 ST2_AVG = Nan
	Make /O/N=0 ST2_SDV = Nan
	Make /O/N=0 ST2_SEM = Nan
	Make /O/N=0 ST2_CNT = Nan
	
	NMNoteType("ST2_wName", "Stats2 Wave Name", "", "", "")
	NMNoteType("ST2_AVG", "Stats2 Avg", "", "", "")
	NMNoteType("ST2_SDV", "Stats2 Sdv", "", "", "")
	NMNoteType("ST2_SEM", "Stats2 SEM", "", "", "")
	NMNoteType("ST2_CNT", "Stats2 Count", "", "", "")

	DoWindow /K $tName
	Edit /K=1/W=(0,0,0,0) ST2_wName, ST2_AVG, ST2_SDV, ST2_SEM, ST2_CNT as titlestr
	DoWindow /C $tName
	SetCascadeXY(tName)
	Execute "ModifyTable title(Point)= \"Save\""
	Execute "ModifyTable width(ST2_wName)=110"
	
End // Stats2Table

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
	
	NVAR AmpNV = $(df+"AmpNV")
	
	Wave AmpB = $(df+"AmpB"); Wave AmpE = $(df+"AmpE")
	
	AmpB[AmpNV] = V_left; AmpE[AmpNV] = V_right
	
	NMAutoStats()

End // XTimes2Stats

//****************************************************************
//****************************************************************
//****************************************************************
