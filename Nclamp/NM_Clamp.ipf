#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.98

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
//	Last modified 9 April 2007
//
//	NM tab entry "Clamp"
//
//	Requires:
//	NM_ClampTab.ipf			creates Tab control interface
//	NM_ClampLog.ipf			Notes/Log functions
//	NM_ClampStim.ipf		stim protocol folder manager
//	NM_ClampUtility.ipf		misc functions
//	NM_PulseGen.ipf			creates stim pulses
//
//	Also:
//	NM_ClampNIDAQ.ipf		acquires data using NIDAQ boards
//	NIM_ClampITC.ipf			acquires data using ITC boards
//
//	Note: this software is best run with ProgWin XOP.
//	Download from ftp site www.wavemetrics.com/Support/ftpinfo.html
//	(IgorPro/User_Contributions/)
//
//****************************************************************
//****************************************************************
//****************************************************************

Menu "NeuroMatic", dynamic

	Submenu "Clamp Hot Keys"
		"Preview/4", ClampButton("CT_StartPreview")
		"Record/5", ClampButton("CT_StartRecord")
		"Add Note/6", NotesAddNote()
		"Auto Scale/7", ClampAutoScale()
	End

End

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampPrefix(objName) // tab prefix identifier
	String objName

	return "CT_" + objName
	
End // ClampPrefix


//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampDF() // package full-path folder name

	return PackDF("Clamp")
	
End // ClampDF

//****************************************************************
//****************************************************************
//****************************************************************

Function Clamp(enable)
	Variable enable // (0) disable (1) enable
	
	Variable statsOn, spikeOn
	
	Variable CurrentWave = NMCurrentWave()

	if (enable == 1)
	
		CheckPackage("Stats", 0) // necessary for auto-stats
		CheckPackage("Spike", 0) // necessary for auto-spike
		CheckPackage("Clamp", 0) // create clamp global variables
		CheckPackage("Notes", 0) // create Notes folder
		
		//LogParentCheck()
		StimParentCheck()
		
		ClampSetPrefs() // set data paths, open stim files, test board config
		
		//if (statsOn == 1)
		//	StatsCompute("", -1, -1, -1, 0, 1)
		//endif
		
		ClampStats(StimStatsOn())
		ClampSpike(StimSpikeOn())
		
	else
	
		ClampStats(0)
		ClampSpike(0)
		
	endif
	
	ClampTabEnable(enable) // (NM_ClampTab.ipf)
	
	SetNMVar(StimDF()+"CurrentChan", NMCurrentChan()) // update current channel

End // Clamp

//****************************************************************
//****************************************************************
//****************************************************************

Function KillClamp(what)
	String what // to kill
	String cdf = ClampDF()

	strswitch(what)
		case "waves":
			break
		case "globals":
			if (DataFolderExists(cdf) == 1)
				KillDataFolder $cdf
			endif 
			break
	endswitch

End // KillClamp

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckClamp()
	
	Variable saveformat = 1 // NM binary
	Variable first = 0
	
	String cdf = ClampDF()

	if (DataFolderExists(cdf) == 0)
		return -1
	endif
	
	if (FileBinType() == 1)
		saveformat = 2 // Igor binary
	endif
	
	CheckNMstr(cdf+"ClampErrorStr", "No Error")		// error message
	CheckNMvar(cdf+"ClampError", 0)					// error number (0) no error (-1) error
	
	// Config variables
	
	CheckNMstr(cdf+"AcqBoard", "Demo")				// interface board
	CheckNMstr(cdf+"BoardList", "0, Demo;")			// acquisition board list
	CheckNMvar(cdf+"BoardDriver", 0)					// main board driver number
	
	CheckNMvar(cdf+"AcqBackGrnd", 0)				// background acq flag (0) no (1) yes
	
	CheckNMvar(cdf+"LogDisplay", 1)					// auto save log notes flag
	CheckNMvar(cdf+"LogAutoSave", 1)					// auto save log notes flag
	
	CheckNMstr(cdf+"TGainList", "")					// telegraph gain ADC channel list
	CheckNMstr(cdf+"ClampInstrument", "")				// clamp instrument name
	
	// data folder variables
	
	CheckNMstr(cdf+"CurrentFolder", "")				// current data file
	
	SetNMstr(cdf+"FolderPrefix", ClampDateName())		// data file prefix name
	
	CheckNMstr(cdf+"StimTag", "")						// stim tag name
	CheckNMstr(cdf+"ClampPath", "")					// external save data path
	CheckNMstr(cdf+"DataPrefix", "Record"	)			// default data prefix name
	
	CheckNMvar(cdf+"DataFileCell", first)				// data file cell number
	CheckNMvar(cdf+"DataFileSeq", first)				// data file sequence number
	CheckNMvar(cdf+"SeqAutoZero", 1)					// auto zero seq number after cell increment
	
	CheckNMvar(cdf+"SaveWhen", 1)					// (0) never (1) after recording (2) while recording
	CheckNMvar(cdf+"SaveFormat", saveformat)			// (1) NM binary file (2) Igor binary file (3) both
	CheckNMvar(cdf+"SaveWithDialogue", 0)			// (0) no dialogue (1) save with dialogue
	CheckNMvar(cdf+"SaveInSubfolder", 1)				// save data in subfolders (0) no (1) yes
	CheckNMvar(cdf+"AutoCloseFolder", 1)				// auto delete data folder flag (0) no (1) yes
	CheckNMvar(cdf+"CopyStim2Folder", 1)				// copy stim to data folder flag (0) no (1) yes
	
	// stim protocol variables
	
	CheckNMstr(cdf+"StimPath", "")					// external save stim path
	CheckNMstr(cdf+"OpenStimList", "")				// external stim files to open
	CheckNMstr(cdf+"CurrentStim", "") 					// current stimulus protocol
	
	return 0
	
End // CheckClamp

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSetPrefs()

	Variable test
	String cdf = ClampDF()
	
	if (NumVarOrDefault(cdf+"ClampSetPreferences", 0) == 1)
		return 0 // already set
	endif

	String ClampPathStr = StrVarOrDefault(cdf+"ClampPath", "")
	String StimPathStr = StrVarOrDefault(cdf+"StimPath", "")
	String sList = StrVarOrDefault(cdf+"OpenStimList", "")
	
	if (strlen(ClampPathStr) > 0)
		NewPath /Z/O/Q ClampPath ClampPathStr
		if (V_flag != 0)
			DoAlert 0, "Failed to create external path to: " + ClampPathStr
			SetNMstr(cdf+"ClampPath", "")
		endif
	endif
	
	if (strlen(StimPathStr) > 0)
		NewPath /Z/O/Q StimPath StimPathStr
		if (V_flag != 0)
			DoAlert 0, "Failed to create external path to: " + StimPathStr
			SetNMstr(cdf+"StimPath", "")
		endif
	endif
	
	if ((strlen(StimPathStr) > 0) && (strlen(sList) > 0))
		StimOpenList(sList)
	endif
	
	test = ClampAcquireManager(StrVarOrDefault(cdf+"AcqBoard","Demo"), -2, 0) // test configuration
	
	if (test < 0)
		SetNMstr(cdf+"AcqBoard","Demo")
	endif
	
	ClampProgress() // make sure progress display is OK
	
	SetNMvar(cdf+"ClampSetPreferences", 1)
	
	SetIgorHook IgorQuitHook = ClampExitHook // runs this fxn before quitting Igor

End // ClampSetPrefs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampDateName()
	String name = "", d = Date()
	
	Variable icnt
	
	for (icnt = 0; icnt < strlen(d); icnt += 1)
		if ((StringMatch(d[icnt,icnt], " ") == 0) && (StringMatch(d[icnt,icnt], ".") == 0) && (StringMatch(d[icnt,icnt], ",") == 0))
			name += d[icnt,icnt]
		endif
	endfor
	
	icnt = strsearch(name, "200", 0) // look for year 200x
	
	if (icnt >= 0)
		name = name[0,icnt-1] + name[icnt+2,inf] // abbreviate
	endif

	if (numtype(str2num(name[0,0])) == 0)
		name = StrVarOrDefault(NMDF()+"FolderPrefix", "nm") + name
	endif
	
	return name

End // ClampDateName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampError(errorStr)
	String errorStr
	String cdf = ClampDF()
	
	if (strlen(errorStr) == 0)
		SetNMstr(cdf+"ClampErrorStr", "No Error")
		SetNMvar(cdf+"ClampError", 0)
	else
		SetNMstr(cdf+"ClampErrorStr", errorStr)
		SetNMvar(cdf+"ClampError", -1)
		DoAlert 0, "Clamp Error: " + errorStr
		ClampButtonDisable(-1)
	endif
	
End // ClampError

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampProgress() // use ProgWin XOP display to allow cancel of acquisition
	String ndf = NMDF()

	Variable pflag = NumVarOrDefault(ndf+"ProgFlag", 0)
	Variable xPixels = NumVarOrDefault(ndf+"xPixels", 1000)
	Variable yPixels = NumVarOrDefault(ndf+"yPixels", 700)
	
	Variable xProgress = NumVarOrDefault(ndf+"xProgress", -1)
	Variable yProgress = NumVarOrDefault(ndf+"yProgress", -1)
	
	String txt = "Alert: Clamp Tab requires ProgWin XOP to cancel acquisition."
	txt += "Download from ftp site www.wavemetrics.com/Support/ftpinfo.html (IgorPro/User_Contributions/)."
	
	if (pflag != 1)
	
		Execute /Z "ProgressWindow kill" // try to use ProgWin function
	
		if (V_flag == 0)
			SetNMVar(ndf+"ProgFlag", 1)
		else
			DoAlert 0, txt
		endif
	
	endif
	
	if ((pflag == 1) && ((xProgress < 0) || (yProgress < 0)))
		SetNMVar(ndf+"xProgress", xPixels - 500)
		SetNMVar(ndf+"yProgress", yPixels/2)
	endif

End // ClampProgress

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardNum(boardListStr)
	String boardListStr // such as "1,PCI-6052E"
	
	return str2num(StringFromList(0, boardListStr, ","))
	
End // ClampBoardNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampBoardName(boardListStr)
	String boardListStr // such as "1,PCI-6052E"
	
	return StringFromList(1, boardListStr, ",")
	
End // ClampBoardName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardListNum(boardNum) // return list number of given board
	Variable boardNum
	
	String cdf = ClampDF()
	
	String boardList = StrVarOrDefault(cdf+"BoardList", "")
	
	Variable icnt
	String item
	
	for (icnt = 0; icnt < ItemsInList(boardList); icnt += 1)
		item = StringFromList(icnt, boardList, ";")
		item = StringFromList(0, item, ",")
		if (str2num(item) == boardNum)
			return icnt
		endif
	endfor
	
	return -1

End // ClampBoardListNum

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp aquisition/manager functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireCall(mode)
	Variable mode // (0) preview (1) record
	
	String cdf = ClampDF()
	
	String aboard = StrVarOrDefault(cdf+"AcqBoard", "")
	
	if (StimChainOn() == 1)
		ClampAcquireChain(aboard, mode)
	else
		ClampAcquire(aboard, mode)
	endif

End // ClampAcquireCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquire(AcqBoard, mode)
	String AcqBoard
	Variable mode // (0) preview (1) record
	
	Variable error
	String cdf = ClampDF(), sdf = StimDF(), ldf = LogDF()
	
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	Variable AcqMode = NumVarOrDefault(sdf+"AcqMode", 0)
	String path = StrVarOrDefault(cdf+ "ClampPath", "")
	
	Variable statsOn = StimStatsOn()
	Variable spikeOn = StimSpikeOn()
	
	ClampError("")
	
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
	
	StimWavesCheck(sdf, 0)
	
	if (ClampDataFolderCheck() == -1)
		return -1
	endif
	
	if ((mode == 1) && (ClampSaveTest(GetDataFolder(0)) == -1))
		return -1
	endif
	
	ClampTgainUpdate()
	
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
	
	error = ClampAcquireManager(acqboard, mode, saveWhen)
	
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
	
	Variable nwaves, rcnt, wcnt, config, chan, chanCount, npnts
	String wname, gdf, cdf = ClampDF(), sdf = StimDF()
	
	if (NumVarOrDefault(sdf+"AcqMode", 0) == 1) // continuous
		InterStimTime = 0
		InterRepTime = 0
	endif
	
	NVAR CurrentWave
	
	Variable pulseOff = NumVarOrDefault(sdf+"PulseGenOff", 0)
	Variable SampleInterval = NumVarOrDefault(sdf+"SampleInterval", 0)
	Variable SamplesPerWave = WaveLength / SampleInterval
	
	Wave DACon = $(sdf+"DACon")
	Wave TTLon = $(sdf+"TTLon")
	Wave ADCon = $(sdf+"ADCon")
	Wave ADCscale = $(sdf+"ADCscale")
	Wave ADCmode = $(sdf+"ADCmode")
	
	Make /O/N=(SamplesPerWave) CT_OutTemp
	Setscale /P x 0, SampleInterval, CT_OutTemp
	
	nwaves = NumStimWaves * NumStimReps // total number of waves

	ClampAcquireStart(mode, nwaves)
	
	for (rcnt = 0; rcnt < NumStimReps; rcnt += 1) // loop thru reps
	
	ClampWait(InterRepTime) // inter-rep time

	for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1) // loop thru stims
	
		ClampWait(InterStimTime) // inter-wave time
		
		CT_OutTemp = 0
		npnts = numpnts(DACon)
		
		for (config = 0; config < npnts; config += 1)
		
			if (DACon[config] == 1)
			
				chan = StimWaveVar(sdf, "DAC", "chan", config)
			
				//if (pulseOff == 0)
					wname = sdf + StimWaveName("DAC", config, wcnt)
				//else
				//	wname = sdf + StimWaveName("MyDAC", config, wcnt)
				//endif
				
				if (WaveExists($wname) == 1)
					Wave wtemp = $wname
					CT_OutTemp += wtemp
				endif
				
			endif
			
		endfor
		
		npnts = numpnts(TTLon)
		
		for (config = 0; config < npnts; config += 1)
		
			if (TTLon[config] == 1)
			
				chan = StimWaveVar(sdf, "TTL", "chan", config)
				
				//if (pulseOff == 0)
					wname = sdf + StimWaveName("TTL", config, wcnt)
				//else
				//	wname = sdf + StimWaveName("MyTTL", config, wcnt)
				//endif
				
				if (WaveExists($wname) == 1)
					Wave wtemp = $wname
					CT_OutTemp += wtemp
				endif
				
			endif
			
		endfor
		
		ClampWait(WaveLength) // simulates delay in acquisition
		
		chanCount = 0
		npnts = numpnts(ADCon)

		for (config = 0; config < npnts; config += 1)
		
			if ((ADCon[config] == 1) && (ADCmode[config] == 0)) // stim/samp
			
				gdf = ChanDF(chanCount)
				
				if (NumVarOrDefault(gdf+"overlay", 0) > 0)
					ChanOverlayUpdate(chanCount)
				endif
				
				if (mode == 1) // record
					wname = GetWaveName("default", chanCount, CurrentWave)
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
		ClampFxnExecute("pre") // compute pre-stim analyses
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
		ClampFxnExecute("inter")
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
	
	String file, cdf = ClampDF()
	
	NVAR NumWaves, CurrentWave, NumActiveWaves
	
	SetNMstr("FileFinish", time())
	
	CallProgress(1) // close progress window
	
	ClampStatsFinish(currentWave)
	
	NumWaves = CurrentWave
	CurrentWave = 0
	
	ClampGraphsFinish()
	CheckNMDataFolder()
	ChanWaveListSet(1) // set channel wave names
	NMGroupSeqDefault()
	UpdateNMPanel(0)
	ClampTgainConvert()
	
	if (mode >= 0)
		ClampFxnExecute("post") // compute post-stim analyses
	endif
	
	if (mode <= 0) // preview, test, error
	
		NumWaves = 0 // back to zero
		NumActiveWaves = 0
		
	elseif (mode == 1) // record and update Notes and Log variables
	
		if (strlen(StrVarOrDefault(NotesDF()+"H_Name", "")) == 0)
			NotesEditHeader()
		endif
		
		NotesBasicUpdate()
		NotesCopyVars(LogDF(),"H_") // update header Notes
		NotesCopyFolder(GetDataFolder(1)+"Notes") // copy Notes to data folder
		ClampAcquireNotes()
		ClampSaveFinish() // save data folder
		NotesBasicUpdate() // do again, this includes new external file name
		NotesCopyFolder(LogDF()+StrVarOrDefault(cdf+"CurrentFolder","nofolder")) // save log notes
		
		if (NumVarOrDefault(cdf+"LogAutoSave", 1) == 1)
			LogSave()
		endif
		
		LogDisplay2(LogDF(), NumVarOrDefault(cdf+"LogDisplay", 1))
		
		NotesClearFileVars() // clear file note vars before next recording
		
	endif
	
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

Function ClampAcquireChain(AcqBoard, mode)
	String AcqBoard
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
		
		if (StimCurrentSet(sname) == 0)
			ClampTabUpdate()
			ClampAcquire(AcqBoard, mode)
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
	Variable ccnt, wcnt
	String wName, wNote, yl, type = "NMData"
	
	String stim = StimCurrent()
	String folder = GetDataFolder(0)
	String fdate = StrVarOrDefault("FileDate", "")
	String ftime = StrVarOrDefault("FileTime", "")
	String xl = StrVarOrDefault("xLabel", "")
	
	NVAR NumChannels, NumWaves
	
	Wave CT_TimeStamp
	Wave /T yLabel
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
	
		yl = yLabel[ccnt]
	
		for (wcnt = 0; wcnt < NumWaves; wcnt += 1)
	
			wName = GetWaveName("default", ccnt, wcnt)
			
			wNote = "Stim:" + stim
			wNote += "\rFolder:" + folder
			wNote += "\rDate:" + NMNoteCheck(fdate)
			wNote += "\rTime:" + NMNoteCheck(ftime)
			wNote += "\rTime Stamp:" + num2strLong(CT_TimeStamp[wcnt], 3) + " msec"
			wNote += "\rChan:" + ChanNum2Char(ccnt)
			
			NMNoteType(wName, type, xl, yl, wNote)
		
		endfor
		
	endfor
	
End // ClampAcquireNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAvgInterval()
	Variable rcnt, wcnt, we, wn, re, rn, dr, icnt, isi
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
		Print "Average episodic wave interval:", we, " msec"
	endif
	
	if (rn > 0)
		re /= rn
		//Print "Average episodic rep interval:", re, " msec"
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
			break
		
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

Function ClampFxnExecute(select)
	String select
	
	String flist, fxn, sdf = StimDF()
	Variable icnt
	
	strswitch(select)
	
		case "pre":
		case "pre-stim":
			flist = StrVarOrDefault(sdf+"PreStimFxnList","")
			break
			
		case "inter":
		case "inter-stim":
			flist = StrVarOrDefault(sdf+"InterStimFxnList","")
			break
			
		case "post":
		case "post-stim":
			flist = StrVarOrDefault(sdf+"PostStimFxnList","")
			break
			
	endswitch
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		fxn = StringFromList(icnt, flist)
		
		if (StringMatch(fxn[strlen(fxn)-3,strlen(fxn)-1],"(0)") == 0)
			fxn += "(0)" // run function
		endif
		
		Execute /Z fxn
		
	endfor

End // ClampFxnExecute

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigCheck()
	String sdf = StimDF()
	
	if (WaveExists($(sdf+"ADCon")) == 0)
		ClampError("ADC input has not been configured.")
		return -1
	endif
	
	if (StimOnCount(sdf, "ADC") == 0)
		ClampError("ADC input has not been configured.")
		return -1
	endif
	
	return StimCheckChannels()
	
End // ClampConfigCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigDemo()

	String cdf = ClampDF()
	
	ClampError("")
	
	SetNMStr(cdf+"AcqBoard", "Demo")
	SetNMVar(cdf+"BoardDriver", 0)
	SetNMStr(cdf+"BoardList", "0, Demo;")
	
	return 0

End // ClampConfigDemo

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Telegraph gain functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainConfig()
	Variable icnt, achan, gchan, on, mode, ibgn, iend
	String item, tlist = ""
	
	String cdf = ClampDF()
	
	String blist = StrVarOrDefault(cdf+"BoardList", "")
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
	String instr = StrVarOrDefault(cdf+"ClampInstrument", "")
	String tGainList = StrVarOrDefault(cdf+"TGainList", "")
	
	Prompt mode, " ", popup "edit existing config;add new config;"
	Prompt gchan, "ADC input channel to read telegraph gain:"
	Prompt achan, "ADC input channel to scale:"
	Prompt instr, "telegraphed instrument:", popup "Axopatch200B;"
	Prompt on, " ", popup "off;on;"
	
	if (ItemsInList(tGainList) > 0)
	
		DoPrompt "ADC Telegraph Gain Config", mode
	
		if (V_flag == 1)
			return -1 // cancel
		endif
		
	else
	
		mode = 2 // nothing to edit
		
	endif
	
	if (mode == 1)
		ibgn = 0; iend = ItemsInList(tGainList) - 1
	elseif (mode == 2)
		ibgn = ItemsInList(tGainList); iend = ItemsInList(tGainList)
		tlist = TGainList
		tGainList = ""
	endif
	
	for (icnt = ibgn; icnt <= iend; icnt += 1)
	
		if (icnt < ItemsInList(tGainList))
			item = StringFromList(icnt, tGainList)
			gchan = str2num(StringFromList(0, item, ","))
			achan = str2num(StringFromList(1, item, ","))
		else
			gchan = 1
			achan = 0
		endif
		
		on = 2
		
		DoPrompt "ADC Telegraph Gain Config " + num2str(icnt), on, gchan, achan, instr
		
		if (V_flag == 1)
			return -1 // cancel
		endif
		
		item = num2str(gchan) + "," + num2str(achan)
		
		if ((on == 2) && (WhichListItem(item, tlist) == -1))
			tlist = AddListItem(item, tlist, ";", inf)
		endif
		
	endfor
	
	SetNMstr(cdf+"TGainList", tlist)
	SetNMstr(cdf+"ClampInstrument", instr)

End // ClampTgainConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainUpdate()
	Variable icnt, config, aChan, gChan, npnts
	String item
	
	String cdf = ClampDF(), sdf = StimDF()
	
	String tGainList = StrVarOrDefault(cdf+"TGainList", "")

	Wave ADCon = $(sdf+"ADCon")
	Wave ADCchan = $(sdf+"ADCchan")

	if (strlen(tGainList) > 0)
	
		npnts = numpnts(ADCon)
		
		Make /O/N=(npnts) $(cdf+"ADCtgain") = Nan
		
		Wave ADCtgain = $(cdf+"ADCtgain")
	
		for (icnt = 0; icnt < ItemsInList(tGainList); icnt += 1)
		
			item = StringFromList(icnt, tGainList)
			gChan = str2num(StringFromList(0, item, ",")) // corresponding telegraph ADC input channel
			aChan = str2num(StringFromList(1, item, ",")) // ADC input channel
			
			for (config = 0; config < npnts; config += 1)
			
				if ((ADCon[config] == 1) && (ADCchan[config] == achan))
					ADCtgain[config] = gChan
					break
				endif
				
			endfor
			
		endfor
		
	endif

End // ClampTgainUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainValue(df, chanNum, waveNum)
	String df // data folder
	Variable chanNum
	Variable waveNum
	
	Variable npnts
	
	String wname = df + "CT_Tgain" + num2str(chanNum) // telegraph gain wave
	
	if (WaveExists($wname) == 0)
		return -1
	endif
	
	Wave temp = $wname

	if (waveNum == -1) // return avg of wave
		temp = Zero2Nan(temp) // remove possible 0's
		WaveStats /Q temp
		return V_avg
	else
		return temp[waveNum]
	endif

End // ClampTgainValue

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainConvert() // convert final tgain values to scale values
	Variable ocnt, icnt, tvalue, npnts
	String olist, oname
	
	olist = WaveList("CT_Tgain*", ";", "") // created by NIDAQ code
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
	
		oname = StringFromList(ocnt, olist)
		
		Wave wtemp = $oname
		
		npnts = numpnts(wtemp)
		
		for (icnt = 0; icnt < npnts; icnt += 1)
		
			tvalue = wtemp[icnt]
			
			if (numtype(tvalue) == 0)
				wtemp[icnt] = MyTelegraphGain(tvalue, tvalue)
			endif
			
		endfor
	
	endfor
	
	olist = VariableList("Tgain*",";",4+2) // created by ITC code
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
	
		oname = StringFromList(ocnt, olist)
		
		tvalue = NumVarOrDefault(oname, -1)
		
		if (tvalue == -1)
			continue
		endif
		
		SetNMvar(oname, MyTelegraphGain(tvalue, tvalue))
		
	endfor

End // ClampTgainConvert

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Igor-timed clock functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWait(t)
	Variable t
	
	if (IgorVersion() >= 5)
		return ClampWaitMSTimer(t)
	else
		return ClampWaitTicks(t)
	endif
	
End // ClampWait

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWaitTicks(t) // wait t msec (only accurate to 17 msec)
	Variable t
	
	if (t == 0)
		return 0
	endif
	
	Variable t0 = ticks
	
	t *= 60 / 1000

	do
	while ((ClampAcquireCancel() == 0) && (ticks - t0 < t ))
	
	return 0
	
End // ClampWaitTicks

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWaitMSTimer(t) // wait t msec (this is more accurate)
	Variable t
	
	if (t == 0)
		return 0
	endif
	
	Variable t0 = stopMSTimer(-2)
	
	t *= 1000 // convert to usec
	
	do
	while ((ClampAcquireCancel() == 0) && (stopMSTimer(-2) - t0 < t ))
	
	return 0
	
End // ClampWaitMSTimer

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Channel graph functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampGraphsCopy(chanNum, direction)
	Variable chanNum // (-1) for all
	Variable direction // (1) data folder to clamp data folder (-1) visa versa

	Variable ccnt
	String cdf = ClampDF(), sdf = StimDF(), gdf = GetDataFolder(1)
	
	String currFolder = StrVarOrDefault(cdf + "CurrentFolder", "")
	
	if (direction == 1)
		ChanFolderCopy(-1, gdf, sdf, 1)
	elseif (direction == -1)
		ChanFolderCopy(-1, sdf, gdf, 0)
	endif

End // ClampGraphsCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampGraphsUpdate(mode)
	Variable mode
	
	Variable ccnt, icnt
	String gName, wlist, wname, cdf = ClampDF()
	
	Variable numChannels = NumVarOrDefault("NumChannels", 0)
	Variable GetChanConfigs = NumVarOrDefault(cdf+"GetChanConfigs", 0)
	
	if (GetChanConfigs == 1)
		ClampGraphsCopy(-1, -1)
		SetNMVar(cdf+"GetChanConfigs", 0)
	else
		ClampGraphsCopy(-1, 1)
	endif
	
	ChanGraphsUpdate() // set scales
	ChanWavesClear(-1) // clear all display waves
	
	for (ccnt = 0; ccnt < numChannels; ccnt += 1)
	
		gName = ChanGraphName(ccnt)
	
		if (Wintype(gName) == 0)
			continue
		endif
		
		ChanControlsDisable(ccnt, "111111") // turn off controls (eliminates flashing)
		
		wlist = WaveList("*", ";", "WIN:" + gName)
		
		for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
			wname = StringFromList(icnt, wlist)
			RemoveFromGraph /Z/W=$gName $wname // remove extra waves
		endfor
		
		ChanGraphTagsKill(ccnt)
		
		DoWindow /T $gName, NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt)
		
		DoWindow /F $gName
		
		HideInfo /W=$gName
		
		// kill cursors in case they exist
		Cursor /K/W=$gName A // kill cursor A
		Cursor /K/W=$gName B // kill cursor B
		
	endfor
	
	if (NumChannels > 0)
		ChanGraphClose(-2, 1) // close unecessary windows (kills Chan DF)
	endif
	
	StatsDisplay(-1, StimStatsOn())

End // ClampGraphsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampGraphsFinish()
	Variable ccnt
	
	for (ccnt = 0; ccnt < NumVarOrDefault("NumChannels", 0); ccnt += 1)
		ChanControlsDisable(ccnt, "000000")
	endfor

End // ClampGraphsFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAutoScale()
	Variable chan
	
	String gName = WinName(0,1) // top graph
	
	if (StringMatch(gName[0,3], "Chan") == 1)
		chan = ChanNumGet(gName)
	else
		chan = 0
		gName = "ChanA"
	endif
	
	SetAxis /A/W=$gName
	
	ChanAutoScale(chan, 1)

End // ClampAutoScale

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampZoom(xzoom, yzoom, xshift, yshift)
	Variable xzoom, yzoom, xshift, yshift
	Variable chan, xmin, xmax, ymin, ymax, ydelta, xdelta
	
	Variable zfactor = 0.1 // zoom factor
	
	String gName = WinName(0,1) // top graph
	String cdf = ClampDF()
	
	if (StringMatch(gName[0,3], "Chan") == 1)
		chan = ChanNumGet(gName)
	else
		chan = 0
		gName = "ChanA"
	endif
	
	String wName = ChanDisplayWave(chan) // display wave
	
	GetAxis /Q/W=$gName bottom
	xmin = V_min; xmax = V_max
		
	GetAxis /Q/W=$gName left
	ymin = V_min; ymax = V_max
	
	ydelta = abs(ymax - ymin)
	xdelta = abs(xmax - xmin)
	
	ymin -= yzoom * zfactor * ydelta
	ymax += yzoom * zfactor * ydelta
	
	ymin += yshift * zfactor * ydelta
	ymax += yshift * zfactor * ydelta
	
	xmin -= xzoom * zfactor * xdelta
	xmax += xzoom * zfactor * xdelta
	
	xmin += xshift * zfactor * xdelta
	xmax += xshift * zfactor * xdelta
	
	SetAxis /W=$gName bottom xmin, xmax
	SetAxis /W=$gName left ymin, ymax
	
	ChanAutoScale(chan, 0)
	
	SetNMVar(cdf+"AutoScale" + num2str(chan), 0)
	SetNMVar(cdf+"xAxisMin" + num2str(chan), xmin)
	SetNMVar(cdf+"xAxisMax" + num2str(chan), xmax)
	SetNMVar(cdf+"yAxisMin" + num2str(chan), ymin)
	SetNMVar(cdf+"yAxisMax" + num2str(chan), ymax)

End // ClampZoom

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampExitHook()

	String board = StrVarOrDefault(ClampDF()+"AcqBoard","")
	
	DoAlert 0, "Clamp Exit"
	
	strswitch(board) // Reset boards
		case "ITC16":
		case "ITC18":
			Execute /Z "ITCconfig(\"" + board + "\")" 
			break
		case "NIDAQ":
			Execute /Z "NidaqResetHard()"
			break
	endswitch

End // ClampExitHook

//****************************************************************
//****************************************************************
//****************************************************************










