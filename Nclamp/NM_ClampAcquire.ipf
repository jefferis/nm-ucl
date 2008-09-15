#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Acquisition Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Created in the Laboratory of Dr. Angus Silver
//	Department of Physiology, University College London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Began 1 July 2003
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireCall(mode)
	Variable mode // (0) preview (1) record
	
	String cdf = ClampDF()
	
	String aboard = StrVarOrDefault(cdf+"BoardSelect", "")
	
	if (StimChainOn("") == 1)
		ClampAcquireChain(aboard, mode)
	else
		ClampAcquire(aboard, mode)
	endif
	
	ClampAutoBackupNM()

End // ClampAcquireCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquire(board, mode)
	String board
	Variable mode // (0) preview (1) record
	
	Variable error
	String cdf = ClampDF(), sdf = StimDF(), ldf = LogDF()
	
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	Variable AcqMode = NumVarOrDefault(sdf+"AcqMode", 0)
	String path = StrVarOrDefault(cdf+ "ClampPath", "")

	ClampError("")
	
	ClampDataFolderSaveCheckAll() // make sure older data files have been saved
	
	if (strlen(path) == 0)
		ClampError("Please specify \"save to\" path on CF tab.")
		return -1
	endif
	
	ClampStatsInit()
	ClampSpikeInit()
	
	if (WinType(NotesTableName()) == 2)
		NotesTable(1) // update notes if table is open
	endif
	
	ClampSaveSubPath()
	
	LogCheckFolder(ldf) // check Log folder is OK
	
	if (ClampConfigCheck() == -1)
		return -1
	endif
	
	if ((AcqMode == 1) && (saveWhen == 2) && (mode == 1))
		ClampError("Save While Recording is not allowed with continuous acquisition.")
		return -1
	endif
	
	StimWavesCheck("", 0)
	
	if (ClampDataFolderCheck() == -1)
		return -1
	endif
	
	if ((mode == 1) && (ClampSaveTest(GetDataFolder(0)) == -1))
		return -1
	endif
	
	StimBoardConfigsUpdateAll("")
	
	// no longer test timers
	
	//if (NumVarOrDefault(cdf+"TestTimers", 1) == 1)
	//if (ClampAcquireManager(AcqBoard, -1, 0)  == -1) // test timers
	//	return -1 
	//endif
	//endif
	
	SetNMvar("NumWaves", 0)
	SetNMvar("NumActiveWaves", 0)
	SetNMvar("CurrentWave", 0)
	SetNMvar("CurrentGrp", NMGroupFirstDefault())

	if ((mode == 1) && (ClampSaveBegin() == -1))
		SetNMvar("NumWaves", 0)
		return -1
	endif
	
	DoUpdate
	
	error = ClampAcquireManager(board, mode, saveWhen)
	
	if ((error == -1) || (NumVarOrDefault(cdf+"ClampError", -1) == -1))
		SetNMvar("NumWaves", 0)
		return -1
	endif
	
	DoWindow /F NMPanel
	
	return 0
	
End // ClampAcquire

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireDemo(mode, savewhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime)
	Variable mode // (0) preview (1) record (-1) test timers
	Variable savewhen // (0) never (1) after (2) while
	Variable WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime // msec
	
	Variable nwaves, rcnt, wcnt, config, chan, chanCount
	String wname, gdf, cdf = ClampDF(), sdf = StimDF(), bdf = StimBoardDF(sdf)
	
	Variable cWave = NumVarOrDefault("CurrentWave", 0)
	
	if (NumVarOrDefault(sdf+"AcqMode", 0) == 1) // continuous
		InterStimTime = 0
		InterRepTime = 0
	endif
	
	Variable pulseOff = NumVarOrDefault(sdf+"PulseGenOff", 0)
	Variable SampleInterval = NumVarOrDefault(sdf+"SampleInterval", 0)
	Variable SamplesPerWave = WaveLength / SampleInterval
	
	if (WaveExists($bdf+"ADCname") == 0)
		return -1
	endif
	
	Wave /T ADCname = $(bdf+"ADCname")
	Wave ADCscale = $(bdf+"ADCscale")
	Wave /T ADCmode = $(bdf+"ADCmode")
	
	Wave /T DACname = $(bdf+"DACname")
	Wave DACchan = $(bdf+"DACchan")
	
	Wave /T TTLname = $(bdf+"TTLname")
	Wave TTLchan = $(bdf+"TTLchan")
	
	Make /O/N=(SamplesPerWave) CT_OutTemp
	Setscale /P x 0, SampleInterval, CT_OutTemp
	
	nwaves = NumStimWaves * NumStimReps // total number of waves

	ClampAcquireStart(mode, nwaves)
	
	for (rcnt = 0; rcnt < NumStimReps; rcnt += 1) // loop thru reps
	
	ClampWait(InterRepTime) // inter-rep time

	for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1) // loop thru stims
	
		ClampWait(InterStimTime) // inter-wave time
		
		CT_OutTemp = 0
		
		for (config = 0; config < numpnts(DACname); config += 1)
		
			if (strlen(DACname[config]) > 0)
			
				chan = DACchan[config]
			
				//if (pulseOff == 0)
					wname = sdf + StimWaveName("DAC", config, wcnt)
				//else
				//	wname = sdf + StimWaveName("MyDAC", config, wcnt)
				//endif
				
				if (WaveExists($wname) == 1)
					Wave wtemp = $wname
					if (numpnts(CT_OutTemp) != numpnts(wtemp))
						Redimension /N=(numpnts(wtemp)) CT_OutTemp
					endif
					CT_OutTemp += wtemp
				endif
				
			endif
			
		endfor
		
		for (config = 0; config < numpnts(TTLname); config += 1)
		
			if (strlen(TTLname[config]) > 0)
			
				chan = TTLchan[config]
				
				//if (pulseOff == 0)
					wname = sdf + StimWaveName("TTL", config, wcnt)
				//else
				//	wname = sdf + StimWaveName("MyTTL", config, wcnt)
				//endif
				
				if (WaveExists($wname) == 1)
					Wave wtemp = $wname
					if (numpnts(CT_OutTemp) != numpnts(wtemp))
						Redimension /N=(numpnts(wtemp)) CT_OutTemp
					endif
					CT_OutTemp += wtemp
				endif
				
			endif
			
		endfor
		
		ClampWait(WaveLength) // simulates delay in acquisition
		
		chanCount = 0

		for (config = 0; config < numpnts(ADCname); config += 1)
		
			if ((strlen(ADCname[config]) > 0) && (strlen(ADCmode[config]) == 0)) // stim/samp
			
				gdf = ChanDF(chanCount)
				
				if (NumVarOrDefault(gdf+"overlay", 0) > 0)
					ChanOverlayUpdate(chanCount)
				endif
				
				if (mode == 1) // record
					wname = GetWaveName("default", chanCount, wcnt)
				else // preview
					wname = GetWaveName("default", chanCount, 0)
				endif
				
				CT_OutTemp /= ADCscale[config]
				
				Duplicate /O CT_OutTemp $wname

				ChanWaveMake(chanCount, wName, ChanDisplayWave(chanCount)) // make display wave
		
				if ((mode == 1) && (saveWhen == 2))
					ClampNMbinAppend(wname) // update waves in saved folder
				endif
				
				chanCount += 1
				
			endif
			
		endfor
		
		ClampAcquireNext(mode, nwaves)
		
		if (ClampAcquireCancel() == 1)
			break
		endif

	endfor
	
		if (ClampAcquireCancel() == 1)
			break
		endif
		
	endfor
	
	KillWaves /Z CT_OutTemp
	
	ClampAcquireFinish(mode, savewhen)
	
	return 0

End // ClampAcquireDemo

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireStart(mode, nwaves) // update folders and graphs, start timers
	Variable mode, nwaves
	
	String cdf = ClampDF()
	String gtitle = "Clamp Acquire"
	String wPrefix = StrVarOrDefault("WavePrefix", "Record")
	String currentStim = StimCurrent()

	ClampDataFolderUpdate(nwaves, mode)
	ClampGraphsUpdate(mode)
	UpdateNMPanel(0)
	ClampButtonDisable(mode)
	
	ClampStatsStart()
	ClampSpikeStart()
	
	if (mode >= 0)
	
		ClampFxnExecute("pre", 2) // init functions
		ClampFxnExecute("inter", 2)
		ClampFxnExecute("post", 2)
		
		ClampFxnExecute("pre", 0) // compute pre-stim functions
		
	endif
	
	if (NumVarOrDefault(cdf+"ClampError", -1) == -1)
		return -1
	endif
	
	CallProgress(0)
	
	DoUpdate
	
	Variable tref = stopMSTimer(0)
	
	SetNMvar(cdf+"TimerRef", startMSTimer)
	
	return 0

End // ClampAcquireStart

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireNext(mode, nwaves) // increment counters, online analyses
	Variable mode, nwaves
	
	Variable tstamp, tintvl, cancel, ccnt, chan
	
	String cdf = ClampDF()
	
	NVAR CurrentChan, CurrentWave, CurrentGrp, NumGrps, NumChannels
	
	Wave CT_TimeStamp, CT_TimeIntvl
	
	Variable firstGrp = NMGroupFirstDefault()
	Variable tref = NumVarOrDefault(cdf+"TimerRef", 0)
	
	String gtitle = StrVarOrDefault(cdf+"ChanTitle", "Clamp Acquire")
	
	if (WinType("ChanA") == 1)
		gtitle = NMFolderListName("") + " : Ch A : " + num2str(CurrentWave)
		DoWindow /T ChanA, gtitle
	endif
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		if (NumVarOrDefault(ChanDF(ccnt)+"AutoScale", 1) == 0)
			ChanGraphAxesSet(ccnt)
		endif
	endfor
	
	ClampStatsCompute(mode, CurrentWave, nwaves)
	ClampSpikeCompute(mode, CurrentWave, nwaves)
	
	if (mode >= 0)
		ClampFxnExecute("inter", 0)
	endif
	
	tintvl = stopMSTimer(tref)/1000
	tref = startMSTimer
	tstamp = tintvl
	
	SetNMvar(cdf+"TimerRef", tref)
	
	if (CurrentWave == 0)
		tintvl = Nan
	else
		tstamp += CT_TimeStamp[CurrentWave-1]
	endif
	
	CT_TimeStamp[CurrentWave] = tstamp
	CT_TimeIntvl[CurrentWave] = tintvl
	
	CurrentWave += 1
	CurrentGrp += 1
	
	if (CurrentGrp - firstGrp == NumGrps)
		CurrentGrp = firstGrp
	endif
	
	cancel = CallProgress(CurrentWave/nwaves)
	
	DoUpdate
	
	return cancel

End // ClampAcquireNext

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireFinish(mode, savewhen)
	Variable mode // (0) preview (1) record (-1) test timers (-2) error
	Variable savewhen // (0) never (1) after (2) while
	
	Variable nwaves, nawaves
	String file, cdf = ClampDF()
	
	Variable cWave = NumVarOrDefault("CurrentWave", 0)
	
	SetNMstr("FileFinish", time())
	
	CallProgress(1) // close progress window
	
	ClampStatsFinish(cWave)
	ClampSpikeFinish()
	
	nwaves = cWave
	SetNMvar("CurrentWave", 0)
	
	ClampGraphsFinish()
	CheckNMDataFolder()
	ChanWaveListSet(-1, 1) // set channel wave names
	NMGroupSeqDefault()
	UpdateNMPanel(0)
	ClampTgainConvert()
	ClampAcquireNotes()
	
	if (mode >= 0)
		ClampFxnExecute("post", 0) // compute post-stim analyses
	endif
	
	if (mode < 0) // test, error
	
		nwaves = 0
		nawaves = 0
	
	elseif (mode == 0) // preview
	
		nwaves = 1
		nawaves = 1
		
	elseif (mode == 1) // record and update Notes and Log variables
	
		if (strlen(StrVarOrDefault(NotesDF()+"H_Name", "")) == 0)
			NotesEditHeader()
		endif
		
		NotesBasicUpdate()
		NotesCopyVars(LogDF(),"H_") // update header Notes
		NotesCopyFolder(GetDataFolder(1)+"Notes") // copy Notes to data folder
		ClampSaveFinish("") // save data folder
		NotesBasicUpdate() // do again, this includes new external file name
		NotesCopyFolder(LogDF()+StrVarOrDefault(cdf+"CurrentFolder","nofolder")) // save log notes
		
		if (NumVarOrDefault(cdf+"LogAutoSave", 1) == 1)
			LogSave()
		endif
		
		LogDisplay2(LogDF(), NumVarOrDefault(cdf+"LogDisplay", 1))
		
		NotesClearFileVars() // clear file note vars before next recording
		
	endif
	
	SetNMvar("NumWaves", nwaves)
	SetNMvar("NumActiveWaves", nwaves)
	
	ClampButtonDisable(-1)
	
	ClampAvgInterval()
	
	//if ((mode == 1) && (NumVarOrDefault(NMDF()+"AutoPlot", 0) == 1))
	//	ResetCascade()
	//	NMPlot( "" )
	//endif
	
	return 0

End // ClampAcquireFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireCancel()
	
	return (NumVarOrDefault("V_Progress", 0) == 1)

End // ClampAcquireCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireChain(board, mode)
	String board
	Variable mode // (0) preview (1) record (-1) test timers
	
	Variable scnt, npnts
	String sname, cdf = ClampDF(), sdf = StimDF()

	if (WaveExists($(sdf+"Stim_Name")) == 0)
		return -1
	endif
	
	String aboard = StrVarOrDefault(cdf+"AcqBoard", "")
	String saveStim = StimCurrent()
	
	Wave /T Stim_Name = $(sdf+"Stim_Name")
	Wave Stim_Wait = $(sdf+"Stim_Wait")
	
	if (numpnts(Stim_Name) == 0)
		ClampError("Alert: no stimulus protocols in Run Stim List.")
		return -1
	endif
	
	npnts = numpnts(Stim_Name)
	
	for (scnt = 0; scnt < npnts; scnt += 1)
	
		sname = Stim_Name[scnt]
		
		if (strlen(sname) == 0)
			continue
		endif
		
		if (IsStimFolder(StimParent(), sname) == 0)
			DoAlert 0, "Alert: stimulus protocol \"" + sname + "\" does not appear to exist."
			continue
		endif
		
		if (strlen(StimCurrentSet(sname)) > 0)
			ClampTabUpdate()
			ClampAcquire(board, mode)
			ClampWait(Stim_Wait[scnt]) // delay in acquisition
		endif
		
		if (ClampAcquireCancel() == 1)
			break
		endif
		
	endfor
	
	StimCurrentSet(saveStim)
	ClampTabUpdate()

End // ClampAcquireChain

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireNotes()

	Variable ccnt, wcnt, config
	String wName, wNote, yl, type = "NMData", bdf = StimBoardDF("")
	String modestr, onList = StimBoardOnList("", "ADC")
	
	String stim = StimCurrent()
	String folder = GetDataFolder(0)
	String fdate = StrVarOrDefault("FileDate", "")
	String ftime = StrVarOrDefault("FileTime", "")
	String xl = StrVarOrDefault("xLabel", "")
	
	Variable nchans = NumVarOrDefault("NumChannels", 0)
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	
	wName = bdf + "ADCname"
	
	if (WaveExists($wName) == 0)
		return 0
	endif
	
	if (WaveExists(CT_TimeStamp) == 0)
		return 0
	endif
	
	Wave CT_TimeStamp
	Wave /T yLabel
	
	for (ccnt = 0; ccnt < nchans; ccnt += 1)
	
		yl = yLabel[ccnt]
		
		config = -1
		
		if (ccnt < ItemsInList(onList))
			config = str2num(StringFromList(ccnt, onList))
		endif
	
		for (wcnt = 0; wcnt < nwaves; wcnt += 1)
	
			wName = GetWaveName("default", ccnt, wcnt)
			
			if (WaveExists($wName) == 0)
				continue
			endif
			
			NMNoteType(wName, type, xl, yl, "Stim:" + stim)
			
			Note $wName, "Folder:" + folder
			Note $wName, "Date:" + NMNoteCheck(fdate)
			Note $wName, "Time:" + NMNoteCheck(ftime)
			Note $wName, "Time Stamp:" + num2strLong(CT_TimeStamp[wcnt], 3) + " msec"
			Note $wName, "Chan:" + ChanNum2Char(ccnt)
			
			if (config >= 0)
				Note $wName,  "ADCname:" + WaveStrOrDefault(bdf+"ADCname", config, "")
				Note $wName,  "ADCunits:" + WaveStrOrDefault(bdf+"ADCunits", config, "")
				Note $wName,  "ADCboard:" + num2str(WaveValOrDefault(bdf+"ADCboard", config, Nan))
				Note $wName,  "ADCchan:" + num2str(WaveValOrDefault(bdf+"ADCchan", config, Nan))
				Note $wName,  "ADCgain:" + num2str(WaveValOrDefault(bdf+"ADCgain", config, 1))
				Note $wName,  "ADCscale:" + num2str(WaveValOrDefault(bdf+"ADCscale", config, 1))
				
				modestr = WaveStrOrDefault(bdf+"ADCmode", config, "")
				
				if (strlen(modestr) == 0)
					modestr = "Normal"
				endif
				
				Note $wName,  "ADCmode:" + modestr
				
			endif
		
		endfor
		
	endfor
	
End // ClampAcquireNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAvgInterval()
	Variable rcnt, wcnt, wwe, we, wn, rre, re, rn, dr, icnt, isi
	String txt, sdf = StimDF()
	
	Variable amode = NumVarOrDefault(sdf + "AcqMode", -1)
	Variable WaveLength = NumVarOrDefault(sdf+"WaveLength", 0)
	Variable NumStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable interStimTime = NumVarOrDefault(sdf+"InterStimTime", 0)
	Variable NumStimReps = NumVarOrDefault(sdf+"NumStimReps", 0)
	Variable interRepTime = NumVarOrDefault(sdf+"InterRepTime", 0)
	
	if ((amode != 2) || (WaveExists(CT_TimeIntvl) == 0))
		return 0
	endif
	
	wwe = WaveLength + interStimTime
	rre = wwe + interRepTime
	
	Wave CT_TimeIntvl
	
	for (rcnt = 0; rcnt < NumStimReps; rcnt += 1) // loop thru reps
	
		for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1) // loop thru stims
			
			//dw = WaveLength + interStimTime + dr
			isi = CT_TimeIntvl[icnt]
			
			if (numtype(isi) == 0)
				if (dr == 0) // clock controlling inter-stim times
					we += isi
					wn += 1
				else // clock controlling inter-rep times
					re += isi
					rn += 1
				endif
			endif
			
			dr = 0
			icnt += 1
			
		endfor
		
		dr = interRepTime
		
	endfor
	
	if (wn > 0)
		we /= wn
		Print "Average episodic wave interval:", we//, " ms; error = ", (we - wwe), " ms"
	endif
	
	if (rn > 0)
		re /= rn
		Print "Average episodic rep interval:", re//, " ms; error = ", (re - rre), " ms"
	endif

End // ClampAvgInterval

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireManager(atype, callmode, savewhen) // call appropriate aquisition function
	String atype // acqusition board ("Demo", "ITC", "NIDAQ")
	Variable callmode // (0) preview (1) record (-2) config test
	Variable savewhen // (0) never (1) after (2) while
	
	String cdf = ClampDF(), sdf = StimDF() 
	
	Variable WaveLength = NumVarOrDefault(sdf+"WaveLength", 0)
	Variable NumStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable interStimTime = NumVarOrDefault(sdf+"InterStimTime", 0)
	Variable NumStimReps = NumVarOrDefault(sdf+"NumStimReps", 0)
	Variable interRepTime = NumVarOrDefault(sdf+"InterRepTime", 0)
	
	String currentStim = StimCurrent()
	
	ClampError("")
	
	switch(callmode)
		case 0: // preview
			NMProgressStr("Preview : " + currentStim)
			break
		case 1: // record
			NMProgressStr("Record : " + currentStim)
			break
		default:
			NMProgressStr("")
			break
	endswitch

	strswitch(atype)
	
		case "Demo":
		
			switch(callmode)
			
				case -2: // test config
					ClampConfigDemo()
					break
					
				case 0: // preview
				case 1: // record
					ClampAcquireDemo(callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime)
					break
					
				default:
					ClampError("demo acquire mode " + num2str(callmode) + " not supported.")
					return -1
					
			endswitch
			
			break
		
		case "NIDAQ":
			
			switch(callmode)
			
				case -2: // config
					//SetNMvar(cdf+"BoardDriver", -1)
					Execute /Z "NIDAQconfig()"
					if (V_flag != 0)
						ClampError("cannot locate function in NM_ClampNIDAQ.ipf")
						return -1
					endif
					break
					
				case 0: // preview
				case 1: // record
					Execute /Z "NIDAQacquire" + ClampParameterList(callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime)
					if (V_flag != 0)
						ClampError("cannot locate function in NM_ClampNIDAQ.ipf")
						return -1
					endif
					break
					
				default:
					ClampError("NIDAQ acquire mode " + num2str(callmode) + " not supported.")
					return -1
					
			endswitch
			
			break
			
		case "ITC16":
		case "ITC18":
		
			switch(callmode)
				case -2: // config
					Execute /Z "ITCconfig(\"" + atype + "\")"
					if (V_flag != 0)
						ClampError("cannot locate function in NM_ClampITC.ipf")
						return -1
					endif
					break
					
				case 0: // preview
				case 1: // record
					Execute /Z "ITCacquire" + ClampParameterList(callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime)
					if (V_flag != 0)
						ClampError("cannot locate function in NM_ClampITC.ipf")
						return -1
					endif
					break
					
				default:
					ClampError("ITC acquire mode " + num2str(callmode) + " not supported")
					return -1
					
			endswitch
			
			break
			
		default:
			ClampError("interface " + atype + " is not supported.")
			return -1
			break
		
	endswitch

	return NumVarOrDefault(cdf+"ClampError", -1)

End // ClampAcquireManager

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampReadManager(atype, board, ADCchan, gain, npnts) // call appropriate read function
	String atype // acqusition board ("Demo", "ITC", "NIDAQ")
	Variable board
	Variable ADCchan // ADC input channel to read
	Variable gain
	Variable npnts // number of points to average
	
	String cdf = ClampDF(), vlist = ""
	
	SetNMvar(cdf+"ClampReadValue", Nan)
	
	if (numtype(board * ADCchan * gain * npnts) > 0)
		return Nan
	endif
	
	strswitch(atype)
	
		case "Demo":
			return Nan
		
		case "NIDAQ":
		
			vlist = AddListItem(num2str(board), vlist, ",", inf)
			vlist = AddListItem(num2str(ADCchan), vlist, ",", inf)
			vlist = AddListItem(num2str(gain), vlist, ",", inf)
			vlist += num2str(npnts) 
			
			Execute /Z "NIDAQread(" + vlist + ")"
			
			if (V_flag != 0)
				ClampError("cannot locate function in NM_ClampNIDAQ.ipf")
				return Nan
			endif
			
			break
			
		case "ITC16":
		case "ITC18":
		
			vlist = AddListItem(num2str(ADCchan), vlist, ",", inf)
			vlist = AddListItem(num2str(gain), vlist, ",", inf)
			vlist += num2str(npnts) 
			
			Execute /Z "ITCread(" + vlist + ")"
			
			if (V_flag != 0)
				ClampError("cannot locate function in NM_ClampITC.ipf")
				return Nan
			endif
			
			break
			
		default:
			ClampError("interface " + atype + " is not supported.")
			return Nan
			
	endswitch

	return NumVarOrDefault(cdf+"ClampReadValue", Nan)
	
End // ClampReadManager

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampParameterList(callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime)
	Variable callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime

	String paramstr = "("+num2str(callmode)+","+num2str(savewhen)+","+num2str(WaveLength)+","+num2str(NumStimWaves)+","
	paramstr += num2str(interStimTime)+","+num2str(NumStimReps)+","+num2str(interRepTime)+")"
	
	return paramstr

End // ClampParameterList

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampFxnExecute(select, mode)
	String select
	Variable mode
	
	Variable icnt
	String flist, fxn
	
	flist = StimFxnList("", select)
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		fxn = StringFromList(icnt, flist)
		
		if (StringMatch(fxn[strlen(fxn)-3,strlen(fxn)-1],"(0)") == 0)
			fxn += "(" + num2str(mode) + ")" // run function
		endif
		
		Execute /Z fxn
		
	endfor

End // ClampFxnExecute

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigCheck()
	
	if (StimBoardOnCount("", "ADC") == 0)
		ClampError("ADC input has not been configured.")
		return -1
	endif
	
	if (StimBoardConfigsCheckDuplicates("") < 0)
		return -1
	endif
	
	return 0
	
End // ClampConfigCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigDemo()
	
	SetNMStr(ClampDF()+"BoardSelect", "Demo")

End // ClampConfigDemo

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWavesNumpnts(DAClist, TTLlist, defaultNpnts)
	String dacList, ttlList
	Variable defaultNpnts
	
	Variable icnt, npnts = defaultNpnts
	String item, wname, list = DAClist
	
	list = AddListItem(TTLlist, DAClist, ";", inf)
	
	for (icnt = 0; icnt < ItemsInList(list); icnt += 1)
			
		item = StringFromList(icnt, list)
		wname = StringFromList(0, item, ",")

		if (WaveExists($wname) == 1)
			npnts = numpnts($wname)
		endif
		
	endfor

	return npnts

End // ClampWavesNumpnts

//****************************************************************
//****************************************************************
//****************************************************************
