#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Acquisition Stim Protocol Functions
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
//	Last modified 25 Feb 2007
//
//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Directory Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimParent() // directory of stim folders

	return "root:Stims:"
	
End // StimParent

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimDF() // return full-path name of current stim folder

	return StimParent() + StimCurrent() + ":"
	
End // StimDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimList()

	return NMFolderList(StimParent(),"NMStim")

End // StimList

//****************************************************************
//****************************************************************
//****************************************************************

Function StimParentCheck()

	if (DataFolderExists("root:Stims:") == 0)
		NewDataFolder root:Stims
	endif

End // StimParentCheck

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Global Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStim(dp, sname, numADC, numDAC, numTTL) // declare stim global variables
	String dp // path
	String sname // stim name
	Variable numADC, numDAC, numTTL
	
	String df = dp + sname + ":"
	
	Variable numStimWaves = 1
	Variable waveLength = 100
	Variable sampleInterval = 0.2
	Variable interStimTime = 900
	Variable interRepTime = 0
	Variable stimRate = 1000 / (waveLength + interStimTime)
	Variable repRate = 1000 / (interRepTime + numStimWaves * (waveLength + interStimTime))
	Variable samplesPerWave = floor(waveLength/sampleInterval)
	
	if (DataFolderExists(df) == 0)
		NewDataFolder $LastPathColon(df, 0) 				// make new stim folder
	endif
	
	CheckNMstr(df+"FileType", "NMStim")					// type of data file
	
	CheckNMvar(df+"Version", NumVarOrDefault(NMDF()+"NMversion",-1))
	
	CheckNMstr(df+"WavePrefix", "Record")					// wave prefix name
	
	CheckNMvar(df+"AcqMode", 0)							// acquisition mode (0) epic precise (1) continuous (2) episodic (3) triggered
	
	CheckNMvar(df+"CurrentChan", 0)						// channel select
	
	CheckNMvar(df+"WaveLength", waveLength)				// wave length (ms)
	CheckNMvar(df+"SampleInterval", sampleInterval)			// time sample interval (ms)
	CheckNMvar(df+"SamplesPerWave", samplesPerWave)
	
	CheckNMvar(df+"NumStimWaves", numStimWaves)		// stim waves per channel
	CheckNMvar(df+"InterStimTime", interStimTime)			// time between stim waves (ms)
	CheckNMvar(df+"NumStimReps", 1)					// repitions of stimulus
	CheckNMvar(df+"InterRepTime", interRepTime)			// time between stimulus repititions (ms)
	CheckNMvar(df+"StimRate", stimRate)
	CheckNMvar(df+"RepRate", repRate)
	CheckNMvar(df+"TotalTime", 1/repRate)
	
	CheckNMvar(df+"NumPulseVar", 12)					// number of variables in pulse waves
	
	CheckNMstr(df+"InterStimFxnList", "")					// during acquisition run function list
	CheckNMstr(df+"PreStimFxnList", "")					// pre-acquisition run function list
	CheckNMstr(df+"PostStimFxnList", "")					// post-acquisition run function list
	
	// IO Channels
	
	CheckNMwave(df+"ADCon", numADC, 0)				// ADC input selector
	CheckNMtwave(df+"ADCname", numADC,"ADC")			// ADC channel name
	CheckNMtwave(df+"ADCunits", numADC, "V")			// ADC channel units
	CheckNMwave(df+"ADCscale", numADC, 1)				// ADC scale factors
	CheckNMwave(df+"ADCboard", numADC, 0)				// ADC board number
	CheckNMwave(df+"ADCchan", numADC, 0)				// ADC board chan
	CheckNMwave(df+"ADCmode", numADC, 0)				// ADC input mode
	CheckNMwave(df+"ADCgain", numADC, 1)				// ADC channel gains
	
	CheckNMwave(df+"DACon", numDAC, 0)				// DAC output selector
	CheckNMtwave(df+"DACname", numDAC,"DAC")			// DAC channel name
	CheckNMtwave(df+"DACunits", numDAC, "V")			// DAC channel units
	CheckNMwave(df+"DACscale", numDAC, 1)				// DAC scale factors
	CheckNMwave(df+"DACboard", numDAC, 0)				// DAC board number
	CheckNMwave(df+"DACchan", numDAC, 0)				// DAC board chan
	
	CheckNMwave(df+"TTLon", numTTL, 0)					// TTL output selector
	CheckNMtwave(df+"TTLname", numTTL,"TTL")			// TTL channel name
	CheckNMtwave(df+"TTLunits", numTTL, "V")				// TTL channel units
	CheckNMwave(df+"TTLscale", numTTL, 1)				// TTL scale factors
	CheckNMwave(df+"TTLboard", numTTL, 0)				// TTL board number
	CheckNMwave(df+"TTLchan", numTTL, 0)				// TTL board chan
	
End // CheckStim

//****************************************************************
//****************************************************************
//****************************************************************

Function StimInitWaves(dp, sname) // set initial values
	String dp // path
	String sname // stim name
	
	String df = dp + sname + ":"
	
	if (DataFolderExists(df) == 0)
		return -1
	endif
	
	Wave ADCchan = $(df+"ADCchan")
	Wave DACchan = $(df+"DACchan")
	Wave TTLchan = $(df+"TTLchan")
	
	Wave /T ADCname = $(df+"ADCname")
	Wave /T DACname = $(df+"DACname")
	Wave /T TTLname = $(df+"TTLname")
	
	ADCchan = x; DACchan = x; TTLchan = x
	
	ADCname = "ADC" + num2str(x)
	DACname = "DAC" + num2str(x)
	TTLname = "TTL" + num2str(x)

End // StimInitWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function StimRedimenWaves(sdf, io, npnts)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	Variable npnts
	
	if (DataFolderExists(sdf) == 0)
		return -1
	endif
	
	if (npnts < numpnts($(sdf+io+"on")))
		return 0
	endif
	
	Redimension /N=(npnts) $(sdf+io+"on")
	Redimension /N=(npnts) $(sdf+io+"name")
	Redimension /N=(npnts) $(sdf+io+"units")
	Redimension /N=(npnts) $(sdf+io+"scale")
	Redimension /N=(npnts) $(sdf+io+"board")
	Redimension /N=(npnts) $(sdf+io+"chan")
	
	if (StringMatch(io, "ADC") == 1)
		Redimension /N=(npnts) $(sdf+"ADCmode")
		Redimension /N=(npnts) $(sdf+"ADCgain")
	endif
	
End // StimRedimenWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function StimWaveVar(sdf, io, select, config)
	String sdf
	String io
	String select
	Variable config
	
	String wName = sdf + io + select
	
	if ((WaveExists($wName) == 0) || (WaveType($wName) == 0))
		return inf
	endif
	
	Wave wTemp = $wName
	
	return wTemp[config]

End // StimWaveVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWaveStr(sdf, io, select, config)
	String sdf
	String io
	String select
	Variable config
	
	String wName = sdf + io + select
	
	if ((WaveExists($wName) == 0) || (WaveType($wName) != 0))
		return "error"
	endif
	
	Wave /T wTemp = $wName
	
	return wTemp[config]

End // StimWaveStr

//****************************************************************
//****************************************************************
//****************************************************************

Function StimOnCount(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	return ItemsInList(StimOnList(sdf, io))
	
End // StimOnCount

//****************************************************************
//****************************************************************
//****************************************************************

Function StimNumChannels(sdf)
	String sdf // stim data folder
	
	Variable config, ccnt
	
	Wave ADCon = $(sdf+"ADCon")
	Wave ADCmode = $(sdf+"ADCmode")

	for (config = 0; config < numpnts(ADCon); config += 1)
		if ((ADCon[config] == 1) && (ADCmode[config] <= 0))
			ccnt += 1
		endif
	endfor

	return ccnt

End // StimNumChannels

//****************************************************************
//****************************************************************
//****************************************************************

Function StimNumWaves(sdf)
	String sdf

	return NumVarOrDefault(sdf+"NumStimWaves", 0) * NumVarOrDefault(sdf+"NumStimReps", 0)

End // StimNumWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimOnList(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	sdf = LastPathColon(sdf, 1)
	
	Variable config, count
	String list = "", wname = sdf + io + "on"
	
	if (WaveExists($wname) == 0)
		return ""
	endif
	
	Wave on = $wname
	
	strswitch(io)
	
		case "ADC":
		
			Wave ADCmode = $(sdf+"ADCmode")
	
			for (config = 0; config < numpnts(on); config += 1)
				if ((on[config] == 1) && (ADCmode[config] == 0))
					list = AddListItem(num2str(config), list, ";", inf)
				endif
			endfor
			
			break
	
		case "DAC":
		case "TTL":
		
			for (config = 0; config < numpnts(on); config += 1)
				if (on[config] == 1)
					list = AddListItem(num2str(config), list, ";", inf)
				endif
			endfor
			
	endswitch
	
	return list
	
End // StimOnList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Folder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimNew(dp, sname) // create a new stimulus folder
	String dp // path
	String sname // stim name
	Prompt sname, "Stimulus name:"
	
	if (StringMatch(sname, "") == 1)
	
		sname = "Untitled"
		
		DoPrompt "New Stimulus", sname // prompt for user input if no name was passed
	
		if (V_flag == 1)
			return "" // cancel
		endif
		
	endif
	
	String df = dp + sname + ":"
	
	Variable init = 1
	
	do
	
		if (DataFolderExists(df) == 0)
		
			break
			
		else
		
			DoAlert 1, "Warning: stim protocol name '" + sname + "' is already in use. Do you want to overwrite the existing protocol?"
			
			if (V_Flag == 1)
				break
			elseif (V_flag == 2)
				sname = "Untitled"
				DoPrompt "New Stimulus", sname // prompt for user input if no name was passed
				if (V_flag == 1)
					init = 0 // cancel
				endif
			endif
			
		endif
		
	while(1)
	
	if (init == 1)
		CheckStim(dp, sname, 10, 10, 10)
		StimInitWaves(dp, sname)
	endif
	
	return sname

End // StimNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimCopy(dp, oldName, newName)
	String dp // path
	String oldName // old stim name
	String newName // new stim name
	
	if (IsStimFolder(dp, oldName) == 0)
		return ""
	endif
	
	if (DataFolderExists(dp+newName) == 1)
		DoAlert 2, "Stim protocol \"" + newName + "\" is already open. Do you want to replace it?"
		if (V_flag == 1)
			KillDataFolder $(dp+newName)
		else
			return ""
		endif
	endif
	
	if ((DataFolderExists(dp+oldName) == 1) && (DataFolderExists(dp+newName) == 0))
		DuplicateDataFolder $(dp+oldName), $(dp+newName)
	endif
	
	SetNMstr(LastPathColon(dp+newName,1)+"CurrentFile", "")
	
	return newName
	
End // StimCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function StimRename(dp, oldName, newName)
	String dp // path
	String oldName // old stim name
	String newName // new stim name
	
	if (IsStimFolder(dp, oldName) == 0)
		return -1
	endif

	oldName = dp + oldName
	
	if (DataFolderExists(dp + newName) == 1)
		DoAlert 0, "Abort: stim protocol name \"" + newName + "\" already in use."
		return -1
	endif
	
	RenameDataFolder $oldName, $newName
	
	SetNMstr(LastPathColon(dp + newName,1)+"CurrentFile","")
	
	return 0
	
End // StimRename

//****************************************************************
//****************************************************************
//****************************************************************

Function  StimClose(dp, slist)
	String dp // path
	String slist // stim list
	
	Variable icnt
	String sname
	
	for (icnt = 0; icnt < ItemsInlist(slist); icnt += 1)
	
		sname = StringFromList(icnt, slist)
	
		if (IsStimFolder(dp, sname) == 0)
			return -1
		endif
		
		String df = dp + sname
		
		if (DataFolderExists(df) == 0)
			DoAlert 0, "Error: stim protocol \"" + sname + "\" does not exist."
			return -1
		endif
		
		if (strlen(StrVarOrDefault(LastPathColon(df,1)+"CurrentFile","")) == 0)
			DoAlert 1, "Warning: stim protocol \"" + sname + "\" has not been saved. Do you want to close it anyway?"
			if (V_flag != 1)
				return -1
			endif
		endif
		
		DoWindow /K $(sname + "Chain")
		
		KillDataFolder $df
		
	endfor
	
	return 0

End // StimClose

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimOpen(dialogue, df, file)
	Variable dialogue // (0) no (1) yes
	String df // data folder path
	String file // external file name
	
	df = FileBinOpen(dialogue, 0, df, "StimPath", file, 0) // NM_FileManager.ipf
	
	if (strlen(df) == 0)
		return ""
	endif

	String sname = GetPathName(df, 0)

	if (IsStimFolder(GetPathName(df, 1), sname) == 0)
		DoAlert 0, "Open Stim Aborted: file \"" + file + "\" is not a NeuroMatic stim protocol."
		if (DataFolderExists(df) == 1)
			KillDataFolder $df
		endif
		return ""
	endif
	
	if (strlen(sname) > 0)
		StimCurrentSet(sname)
		StimWavesCheck(StimDF(), 0)
	endif
	
	return sname

End // StimOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimOpenAll(dialogue, df, pathName)
	Variable dialogue // (0) no (1) yes
	String df // data folder path
	String pathName // Igor path name
	
	Variable icnt
	String file, slist, cdf = ClampDF()
	
	String spath = StrVarOrDefault(cdf+"StimPath", "")
	
	if (dialogue == 1)
	
		file = FileDialogue(0, pathName, "", "")
		
		PathInfo $pathName
		
		if (V_Flag == 0)
			NewPath /Z/Q/O StimPath GetPathName(file, 1)
		endif
		
		if (strlen(file) == 0)
			return "" // cancel
		endif
	
	endif
	
	slist = IndexedFile($pathName,-1,"????")
	
	if (ItemsInList(slist) == 0)
		return ""
	endif
	
	StimOpenList(slist)
	
	return ""

End // StimOpenAll

//****************************************************************
//****************************************************************
//****************************************************************

Function StimOpenList(slist)
	String slist
	
	Variable icnt, bintype = FileBinType()
	String file, sname, df = StimParent()
	
	if (ItemsInList(slist) == 0)
		return -1
	endif
	
	PathInfo /S StimPath
	
	if (V_Flag == 0)
		return 0
	endif
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1)
	
		sname = StringFromList(icnt, slist)
	
		file = S_path + sname
		
		if (bintype == 0)
			file = FileExtCheck(file, ".nmb", 1) // NM binary
		else
			file = FileExtCheck(file, ".pxp", 1) // Igor binary
			if (FileExists(file) == 0)
				file = FileExtCheck(file, ".nmb", 1) // try NM binary
			endif
		endif
		
		if (FileExists(file) == 1)
			sname = StimOpen(0, df, file)
		endif
		
	endfor
	
	StimCurrentSet(StringFromList(0, slist))

End // StimOpenList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimSave(dialogue, new, dp, sname)
	Variable dialogue // (0) no prompt (1) prompt
	Variable new // (0) no (1) yes
	String dp // data folder path
	String sname // stim folder name

	String newname, folder, temp, path = "StimPath", file = ""
	
	if (IsStimFolder(dp, sname) == 0)
		return ""
	endif
	
 	folder = dp + sname + ":"
	temp = dp + "TempXYZ:"

	if (DataFolderExists(folder) == 0)
		return ""
	endif
	
	if (DataFolderExists(temp) == 1)
		KillDataFolder $(temp) // clean-up
	endif
	
	if ((strlen(file) == 0) && (new == 1))
		file = sname
		//path = "StimPath"
	endif

	file = FileBinSave(dialogue, new, dp+sname, path, file, 1, -1) // NM_FileManager

	if (strlen(file) > 0)
	
		newname = GetPathName(file, 0) // create stim folder name
		newname = FileExtCheck(newname, ".*", 0) // remove file extension if necesary
		newname = FolderNameCreate(newname)
		
		if (StringMatch(sname, newname) == 0)
			newname = StimCopy(dp, sname, newname)
		endif
		
		return newname
	
	else
	
		return ""
		
	endif

End // StimSave

//****************************************************************
//****************************************************************
//****************************************************************

Function StimSaveList(dialogue, new, dp, slist)
	Variable dialogue // (0) no prompt (1) prompt
	Variable new // (0) no (1) yes
	String dp // data folder path
	String slist // stim list
	
	Variable icnt
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1)
		StimSave(dialogue, new, dp, StringFromList(icnt, slist))
	endfor
	
End // StimSaveList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Current Stim Functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimCurrent()

	return StrVarOrDefault(ClampDF()+"CurrentStim", "")
	
End // StimCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function StimCurrentCheck() // check current stim is OK
	
	String df = StimParent()
	String cdf = ClampDF()
	String CurrentStim = StimCurrent()
	String sList = StimList()
	
	if (strlen(CurrentStim+sList) == 0) // nothing is open
	
		CurrentStim = "Stim0"
		StimNew(df, CurrentStim) // begin with blank stim
		StimCurrentSet(CurrentStim)
		
	elseif (WhichListItem(UpperStr(CurrentStim), UpperStr(sList)) == -1)
	
		StimCurrentSet(StringFromList(0, sList))
		
	endif

End // StimCurrentCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function StimCurrentSet(fname) // set current stim
	String fname // stimulus name
	
	String sdf, df = StimParent(), cdf = ClampDF()
	
	if (strlen(fname) == 0)
		SetNMstr(cdf+"CurrentStim", "")
		return -1
	endif
	
	if (stringmatch(fname, StimCurrent()) == 1)
		//return 0 // already current stim
	endif
	
	if (DataFolderExists(df+fname) == 0)
		return -1
	endif
	
	if (IsStimFolder(df, fname) == 0)
		ClampError("\"" + fname + "\" is not a NeuroMatic stimulus folder.")
		return -1
	endif
	
	ClampStatsDisplaySavePosition()
	
	sdf = df + fname + ":"
	
	SetNMstr(cdf+"CurrentStim", fname)
	SetNMstr(cdf+"StimTag", StrVarOrDefault(sdf+"StimTag", ""))
	
	if (StimChainOn() == 1)
		StimChainEdit()
		ClampTabUpdate()
		return 0
	endif
	
	if (NumVarOrDefault("NumWaves", 0) == 0) // empty folder
		SetNMvar("CurrentChan", NumVarOrDefault(sdf+"CurrentChan", 0))
		SetNMvar("NumChannels", StimNumChannels(sdf))
	endif
	
	ClampStatsRetrieveFromStim() // get Stats from new stim
	ClampStats(StimStatsOn())
	ClampGraphsCopy(-1, -1) // get Chan display variables
	ChanGraphsReset()
	ClampStatsDisplaySetPosition("amp")
	ClampStatsDisplaySetPosition("tau")
	
	UpdateNMPanel(0)
	ClampTabUpdate()
	ChanGraphsUpdate()
	
	StatsDisplayClear()
	
	return 0
	
End // StimCurrentSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWavePrefix() // return stim wave prefix name if it exists

	return StrVarOrDefault(StimDF()+"WavePrefix", StrVarOrDefault(ClampDF()+"DataPrefix", "Record"))
	
End // StimWavePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStimChanFolders()

	Variable ccnt, nchan
	String gName, df, ddf, cdf = ClampDF(), sdf = StimDF(), pdf = PackDF("Chan")
	String currFolder = StrVarOrDefault(cdf + "CurrentFolder", "")
	
	nchan = StimNumChannels(sdf)
	
	for (ccnt = 0; ccnt < nchan; ccnt += 1)
	
		gName = ChanGraphName(ccnt)
		
		df = sdf + gName + ":"
		
		if (DataFolderExists(df) == 1)
			continue
		endif
		
		// copy default channel graph settings to stim folder
		
		DuplicateDataFolder $LastPathColon(pdf, 0) $LastPathColon(df, 0)
		
		if (strlen(currFolder) == 0)
			continue
		endif
		
		df = "root:" + currFolder + ":" + gName + ":"
		
		if (DataFolderExists(df) == 1)
			KillDataFolder df
		endif
		
		// copy to current data folder as well
		
		DuplicateDataFolder $LastPathColon(pdf, 0) $LastPathColon(df, 0)
	
	endfor
		
End // CheckStimChanFolders

//****************************************************************
//****************************************************************
//****************************************************************

Function StimChainEdit()
	Variable npnts = -1

	String tName = StimCurrent() + "Chain"
	String tTitle = StimCurrent() + " Acquisition Table"
	String sdf = StimDF()
	
	if (DataFolderExists(sdf) == 0)
		return 0 // Clamp folder does not exist
	endif
	
	if (WaveExists($sdf+"Stim_Name") == 0)
		npnts = 5
	endif
	
	CheckNMtwave(sdf+"Stim_Name", npnts, "")
	CheckNMwave(sdf+"Stim_Wait", npnts, 0)
	
	if (WinType(tName) == 0)
		Edit /K=1/W=(0,0,0,0) $(sdf+"Stim_Name"), $(sdf+"Stim_Wait")
		DoWindow /C $tName
		DoWindow /T $tName, tTitle
		SetCascadeXY(tName)
	else
		DoWindow /F $tName
	endif

End // StimChainEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function StimStatsOn()
	String sdf = StimStatsDF()

	if (DataFolderExists(sdf) == 0)
		return 0
	endif

	return NumVarOrDefault(sdf+"StatsOn", 0)
	
End // StimStatsOn

//****************************************************************
//****************************************************************
//****************************************************************

Function StimSpikeOn()
	String sdf = StimSpikeDF()

	if (DataFolderExists(sdf) == 0)
		return 0
	endif

	return NumVarOrDefault(sdf+"SpikeOn", 0)
	
End // StimSpikeOn

//****************************************************************
//****************************************************************
//****************************************************************

Function StimChainOn()

	return NumVarOrDefault(StimDF()+"AcqStimChain", 0)
	
End // StimChainOn

//****************************************************************
//****************************************************************
//****************************************************************