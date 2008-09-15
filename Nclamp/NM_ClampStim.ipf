#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

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
//	Last modified 1 April 2008
//
//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Globals Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStim(dp, sname) // declare stim global variables
	String dp // path
	String sname // stim name
	
	String sdf = LastPathColon(dp, 1) + sname + ":"
	String cdf = ClampDF()
	
	Variable numStimWaves = 1
	Variable waveLength = 100
	Variable sampleInterval = 0.2
	Variable interStimTime = 900
	Variable interRepTime = 0
	Variable stimRate = 1000 / (waveLength + interStimTime)
	Variable repRate = 1000 / (interRepTime + numStimWaves * (waveLength + interStimTime))
	Variable samplesPerWave = floor(waveLength/sampleInterval)
	
	if (DataFolderExists(sdf) == 0)
		NewDataFolder $LastPathColon(sdf, 0) 				// make new stim folder
	endif
	
	CheckNMstr(sdf+"FileType", "NMStim")					// type of data file
	
	CheckNMvar(sdf+"Version", NumVarOrDefault(NMDF()+"NMversion",-1))
	
	CheckNMstr(sdf+"StimTag", "")							// stimulus file suffix tag
	
	CheckNMstr(sdf+"WavePrefix", "Record")				// wave prefix name
	
	CheckNMvar(sdf+"AcqMode", 0)						// acquisition mode (0) epic precise (1) continuous (2) episodic (3) triggered
	
	CheckNMvar(sdf+"CurrentChan", 0)						// channel select
	
	CheckNMvar(sdf+"WaveLength", waveLength)			// wave length (ms)
	CheckNMvar(sdf+"SampleInterval", sampleInterval)		// time sample interval (ms)
	CheckNMvar(sdf+"SamplesPerWave", samplesPerWave)
	
	CheckNMvar(sdf+"NumStimWaves", numStimWaves)		// stim waves per channel
	CheckNMvar(sdf+"InterStimTime", interStimTime)			// time between stim waves (ms)
	CheckNMvar(sdf+"NumStimReps", 1)					// repitions of stimulus
	CheckNMvar(sdf+"InterRepTime", interRepTime)			// time between stimulus repititions (ms)
	CheckNMvar(sdf+"StimRate", stimRate)
	CheckNMvar(sdf+"RepRate", repRate)
	CheckNMvar(sdf+"TotalTime", 1/repRate)
	
	CheckNMvar(sdf+"NumPulseVar", 12)					// number of variables in pulse waves
	
	CheckNMstr(sdf+"InterStimFxnList", "")					// during acquisition run function list
	CheckNMstr(sdf+"PreStimFxnList", "")					// pre-acquisition run function list
	CheckNMstr(sdf+"PostStimFxnList", "")					// post-acquisition run function list
	
	// IO Channels
	
	CheckNMvar(sdf+"UseGlobalBoardConfigs", 1)			// use global board configs (0) no (1) yes
	
	StimBoardWavesCheckAll(sdf)
	
	return 0
	
End // CheckStim

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWavePrefix(sdf) // return stim wave prefix name if it exists
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif

	return StrVarOrDefault(sdf+"WavePrefix", StrVarOrDefault(ClampDF()+"DataPrefix", "Record"))
	
End // StimWavePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function StimWaveLength(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	return NumVarOrDefault(sdf+"WaveLength", 0)

End // StimWaveLength

//****************************************************************
//****************************************************************
//****************************************************************

Function StimNumStimWaves(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	return NumVarOrDefault(sdf+"NumStimWaves", 0)
	
End // StimNumStimWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function StimNumStimReps(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	return NumVarOrDefault(sdf+"NumStimReps", 0)
	
End // StimNumStimReps

//****************************************************************
//****************************************************************
//****************************************************************

Function StimNumWavesTotal(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif

	return NumVarOrDefault(sdf+"NumStimWaves", 0) * NumVarOrDefault(sdf+"NumStimReps", 0)

End // StimNumWavesTotal

//****************************************************************
//****************************************************************
//****************************************************************

Function StimCurrentChanSet(sdf, chan)
	String sdf
	Variable chan
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	SetNMVar(sdf+"CurrentChan", chan)
	
	return chan
	
End // StimCurrentChanSet

//****************************************************************
//****************************************************************
//****************************************************************

Function StimAcqMode(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	return NumVarOrDefault(sdf+"AcqMode", 0)
	
End  // StimAcqMode

//****************************************************************
//****************************************************************
//****************************************************************

Function StimAcqModeSet(sdf, select)
	String sdf
	String select
	
	Variable mode
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	strswitch(select)
		case "epic precise":
			mode = 0
			break
		case "continuous":
			mode = 1
			break
		case "episodic": // less precise
			mode = 2
			break
		case "triggered":
			mode = 3
			break
	endswitch
	
	SetNMVar(sdf+"AcqMode", mode)
	
	return mode
	
End // StimAcqModeSet

//****************************************************************
//****************************************************************
//****************************************************************

Function StimIntervalSet(sdf, boardNum, boardDriver, sampleInterval)
	String sdf // stim data folder bath
	Variable boardNum, boardDriver, sampleInterval
	
	Variable bcnt, driverSampleInterval
	String varName, boards, cdf = ClampDF()
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	driverSampleInterval = NumVarOrDefault(sdf+"SampleInterval", 1)
	boards = StrVarOrDefault(cdf+"BoardList", "")
	
	varName = sdf + "SampleInterval_" + num2str(boardNum)
	
	if (boardNum == boardDriver)
		SetNMVar(sdf+"SampleInterval", sampleInterval)
	elseif (sampleInterval == driverSampleInterval)
		KillVariables /Z $varName // no longer need variable
	else
		SetNMVar(varName, sampleInterval) // create new sample interval variable
	endif
	
	return sampleInterval
	
End // StimIntervalSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWavePrefixSet(sdf, prefix)
	String sdf
	String prefix
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	prefix = CheckFolderNameChar(prefix)
	
	SetNMstr(sdf+"WavePrefix", prefix)
	
	return prefix
	
End // StimWavePrefixSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimTagSet(sdf, suffix)
	String sdf
	String suffix
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	suffix = CheckFolderNameChar(suffix)
	
	SetNMstr(sdf+"StimTag", suffix)
	
	return suffix
	
End // StimTagSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimTag(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	return StrVarOrDefault(sdf+"StimTag", "")

End // StimTag

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimChainEdit(sdf)
	String sdf
	Variable npnts = -1

	String tName = StimCurrent() + "Chain"
	String tTitle = StimCurrent() + " Acquisition Table"
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	if (WaveExists($sdf+"Stim_Name") == 0)
		npnts = 5
	endif
	
	CheckNMtwave(sdf+"Stim_Name", npnts, "")
	CheckNMwave(sdf+"Stim_Wait", npnts, 0)
	
	if (WinType(tName) == 0)
		Edit /K=1/N=$tName/W=(0,0,0,0) $(sdf+"Stim_Name"), $(sdf+"Stim_Wait") as tTitle
		SetCascadeXY(tName)
	else
		DoWindow /F $tName
	endif
	
	return tName

End // StimChainEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function StimChainOn(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif

	return BinaryCheck(NumVarOrDefault(sdf+"AcqStimChain", 0))
	
End // StimChainOn

//****************************************************************
//****************************************************************
//****************************************************************

Function StimChainSet(sdf, on)
	String sdf
	Variable on // (0) off (1) on
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	on = BinaryCheck(on)
	
	SetNMvar(sdf+"AcqStimChain", on)
	
	if (on == 1)
		StimChainEdit(sdf)
	endif
	
	return on
	
End // StimChainSet

//****************************************************************
//****************************************************************
//****************************************************************

Function StimUseGlobalBoardConfigs(sdf)
	String sdf

	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	Variable on = NumVarOrDefault(sdf+"UseGlobalBoardConfigs", 0)
	
	if (WaveExists($sdf+"ADCname") == 0)
		on = 1
	endif
	
	return BinaryCheck(on)

End // StimUseGlobalBoardConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function StimUseGlobalBoardConfigsSet(sdf, on)
	String sdf
	Variable on // (0) off (1) on
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	on = BinaryCheck(on)
	
	if ((on == 0) && (WaveExists($sdf+"ADCname") == 0))
		DoAlert 0, "Alert: \"" + StimCurrent() + "\" does not contain its own board configs. You must use the global board configs which you can create using the Board tab."
		on = 1
	endif
	
	SetNMvar(sdf+"UseGlobalBoardConfigs", on)
	
	StimBoardConfigsUpdateAll(sdf)
	
	return on
	
End // StimUseGlobalBoardConfigsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimFxnList(sdf, select)
	String sdf, select
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif

	strswitch(select[0,2])
		case "Pre":
			return StrVarOrDefault(sdf+"PreStimFxnList", "")
		case "Int":
			return StrVarOrDefault(sdf+"InterStimFxnList", "")
		case "Pos":
			return StrVarOrDefault(sdf+"PostStimFxnList", "")
	endswitch
	
	return ""

End // StimFxnList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimFxnListSet(sdf, select, flist)
	String sdf, select, flist
	
	Variable icnt
	String fxn, alist = ""
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		fxn = StringFromlist(icnt, flist)
		
		if (exists(fxn) != 6)
			DoAlert 0, "Error: function " + fxn + "() does not appear to exist."
			return ""
		else
			alist = AddListItem(fxn, alist, ";", inf)
		endif
		
	endfor

	strswitch(select[0,2])
		case "Pre":
			SetNMstr(sdf+"PreStimFxnList", alist)
			break
		case "Int":
			SetNMstr(sdf+"InterStimFxnList", alist)
			break
		case "Pos":
			SetNMstr(sdf+"PostStimFxnList", alist)
			break
		default:
			return ""
	endswitch
	
	return alist

End // StimFxnListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimFxnListAddAsk(sdf, select)
	String sdf
	String select
	
	String fxn, otherfxn, flist, flist2
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	flist = StimFxnList(sdf, select)
	flist2 = ClampUtilityList(select)

	if (strlen(flist2) > 0)
		Prompt fxn, "choose utility function:", popup flist2
		Prompt otherfxn, "or enter function name, such as \"MyFunction\":"
		DoPrompt "Add Stim Function", fxn, otherfxn
	else
		Prompt otherfxn, "enter function name, such as \"MyFunction\":"
		DoPrompt "Add Stim Function", otherfxn
	endif
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	if (strlen(otherfxn) > 0)
		fxn = otherfxn
	endif
	
	return StimFxnListAdd(sdf, select, fxn)

End // StimFxnListAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimFxnListAdd(sdf, select, fxn)
	String sdf, select, fxn
	
	String listname, flist
	
	sdf = CheckStimDF(sdf)
	
	if ((strlen(sdf) == 0) || (strlen(fxn) == 0))
		return ""
	endif
	
	if (exists(fxn) != 6)
		ClampError("function " + fxn + "() does not appear to exist.")
		return ""
	endif
	
	Execute /Z fxn + "(1)" // call function config
	
	strswitch(select[0,2])
		case "Pre":
			listname = "PreStimFxnList"
			break
		case "Int":
			listname = "InterStimFxnList"
			break
		case "Pos":
			listname = "PostStimFxnList"
			break
		default:
			return ""
	endswitch
	
	flist = StimFxnList(sdf, select)
	
	if (WhichListItemLax(fxn, flist, ";") == -1)
		flist = AddListItem(fxn,StrVarOrDefault(sdf+listname,""),";",inf)
		SetNMStr(sdf+listname,flist)
	endif
	
	return fxn
	
End // StimFxnListAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimFxnListRemoveAsk(sdf, select)
	String sdf
	String select
	
	String fxn, flist
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	flist = StimFxnList(sdf, select)

	if (ItemsInlist(flist) == 0)
		DoAlert 0, "No funtions to remove."
		return ""
	endif
	
	Prompt fxn, "select function to remove:", popup flist
	DoPrompt "Remove Stim Function", fxn

	if (V_flag == 1)
		return ""
	endif
	
	return StimFxnListRemove(sdf, select, fxn)

End // StimFxnListRemoveAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimFxnListRemove(sdf, select, fxn)
	String sdf, select, fxn
	
	String flist
	
	sdf = CheckStimDF(sdf)
	
	if ((strlen(sdf) == 0) || (strlen(fxn) == 0))
		return ""
	endif
	
	Execute /Z fxn + "(-1)" // call function to kill variables
	
	flist = StimFxnList(sdf, select)
	flist = RemoveFromList(fxn, flist)
	StimFxnListSet(sdf, select, flist)
	
	return fxn
	
End // StimFxnListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function StimFxnListClear(sdf, select)
	String sdf, select
	
	Variable icnt
	String flist, fxn
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	flist = StimFxnList(sdf, select)
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		fxn = StringFromlist(icnt, flist)
		Execute /Z fxn + "(-1)" // call function to kill variables
	endfor
	
	StimFxnListSet(sdf, select, "")
	
	return 0

End // StimFxnListClear

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Folder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimNew(sname) // create a new stimulus folder
	String sname // stim name
	
	String dp = StimParent()
	
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
		CheckStim(dp, sname)
	endif
	
	return sname

End // StimNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimCopy(oldName, newName)
	String oldName // old stim name
	String newName // new stim name
	
	String dp = StimParent()
	
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

Function StimRename(oldName, newName)
	String oldName // old stim name
	String newName // new stim name
	
	String dp = StimParent()
	
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

Function  StimClose(slist)
	String slist // stim list
	
	Variable icnt
	String sname, dp = StimParent()
	
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
		
		PulseGraphRemoveWaves()
		
		KillDataFolder $df
		
	endfor
	
	return 0

End // StimClose

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimOpenAll(pathName)
	String pathName // Igor path name
	
	String file, slist, filepath
	
	file = FileDialogue(0, pathName, "", "")
	
	if (strlen(file) == 0)
		return "" // cancel
	endif
	
	filepath = GetPathName(file, 1) 
	
	NewPath /Z/Q/O TempPath filePath
	
	slist = IndexedFile(TempPath,-1,"????")
	
	KillPath /Z TempPath
		
	if (ItemsInList(slist) == 0)
		return ""
	endif
	
	StimOpenList(filepath, slist)
	
	return ""

End // StimOpenAll

//****************************************************************
//****************************************************************
//****************************************************************

Function StimOpenList(filepath, slist)
	String filepath // external folder where stim files exist
	String slist // list of stimulus file names
	
	Variable icnt
	
	if (ItemsInList(slist) == 0)
		return -1
	endif
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1)
		StimOpen(0, "", filepath+StringFromList(icnt, slist))
	endfor
	
	StimCurrentSet(StringFromList(0, slist))

End // StimOpenList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimOpen(dialogue, pathName, file)
	Variable dialogue // (0) no (1) yes
	String pathName
	String file // external file name
	
	String df, dp = StimParent()
	
	file = FileExtCheck(file, ".pxp", 1)
	
	df = FileBinOpen(dialogue, 0, dp, pathName, file, 0) // NM_FileManager.ipf
	
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
		StimWavesCheck("", 0)
	endif
	
	return sname

End // StimOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimSave(dialogue, new, sname)
	Variable dialogue // (0) no prompt (1) prompt
	Variable new // (0) no (1) yes
	String sname // stim folder name

	String newname = "", folder, temp, path = "ClampStimPath", file = ""
	String saveCurrentFile, saveCurrentFile2, dp = StimParent()
	
	if (IsStimFolder(dp, sname) == 0)
		return ""
	endif
	
 	folder = dp + sname + ":"
	temp = dp + "TempXYZ:"

	if (DataFolderExists(folder) == 0)
		return ""
	endif
	
	if (DataFolderExists(temp) == 1)
		KillDataFolder $temp // clean-up
	endif
	
	if ((strlen(file) == 0) && (new == 1))
		file = sname
		//path = "StimPath"
	endif
	
	saveCurrentFile = StrVarOrDefault(folder + "CurrentFile", "")

	file = FileBinSave(dialogue, new, dp+sname, path, file, 1, -1) // NM_FileManager

	if (strlen(file) > 0)
	
		newname = GetPathName(file, 0) // create stim folder name
		newname = FileExtCheck(newname, ".*", 0) // remove file extension if necesary
		newname = FolderNameCreate(newname)
		
		if (StringMatch(sname, newname) == 0)
		
			saveCurrentFile2 = StrVarOrDefault(folder + "CurrentFile", "")
			
			newname = StimCopy(sname, newname)
			
			SetNMstr(folder + "CurrentFile", saveCurrentFile)
			SetNMstr(dp+newname + ":" + "CurrentFile", saveCurrentFile2)
			
		endif
		
		return newname
	
	else
	
		return ""
		
	endif

End // StimSave

//****************************************************************
//****************************************************************
//****************************************************************

Function StimSaveList(dialogue, new, slist)
	Variable dialogue // (0) no prompt (1) prompt
	Variable new // (0) no (1) yes
	String slist // stim list
	
	Variable icnt
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1)
		StimSave(dialogue, new, StringFromList(icnt, slist))
	endfor
	
End // StimSaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function XXXXCheckStimChanFoldersXXXXX()

	Variable ccnt, nchan
	String gName, df, ddf, cdf = ClampDF(), sdf = StimDF(), pdf = PackDF("Chan")
	String currFolder = StrVarOrDefault(cdf + "CurrentFolder", "")
	
	nchan = StimBoardNumADCchan(sdf)
	
	for (ccnt = 0; ccnt < nchan; ccnt += 1)
	
		gName = ChanGraphName(ccnt)
		
		df = sdf + gName + ":"
		
		if (DataFolderExists(df) == 1)
			continue
		endif
		
		// copy default channel graph settings to stim folder
		
		//DuplicateDataFolder $LastPathColon(pdf, 0) $LastPathColon(df, 0) // no longer exists
		
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
//
//     Stim board config wave functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimBoardLookUpDF(sdf) // the directory where to find look-up table of existing configs
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if ((strlen(sdf) > 0) && (StimUseGlobalBoardConfigs(sdf) == 1))
		return ClampDF() // use new global board configs in Clamp folder
	endif
	
	return sdf // use old board configs saved in stim folder

End // StimBoardLookUpDF

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardWavesCheckAll(sdf)
	String sdf

	StimBoardWavesCheck(sdf, "ADC")
	StimBoardWavesCheck(sdf, "DAC")
	StimBoardWavesCheck(sdf, "TTL")

End // StimBoardWavesCheckAll

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardWavesCheck(sdf, io)	
	String sdf
	String io
	
	String bdf = StimBoardDF(sdf)

	Variable npnts = ClampBoardNumConfigs()
	
	if ((strlen(ClampIOcheck(io)) == 0) || (strlen(bdf) == 0))
		return -1
	endif
	
	if (DataFolderExists(bdf) == 0)
		NewDataFolder $LastPathColon(bdf, 0) 			// make new board config sub-folder
	endif
	
	CheckNMtwave(bdf+io+"name", npnts,"")			// config name
	CheckNMtwave(bdf+io+"units", npnts, "")			// config units
	CheckNMwave(bdf+io+"scale", npnts, Nan)			// scale factor
	CheckNMwave(bdf+io+"board", npnts, Nan)			// board number
	CheckNMwave(bdf+io+"chan", npnts, Nan)			// board chan
	
	if (StringMatch(io, "ADC") == 1)
		CheckNMtwave(bdf+io+"mode", npnts, "")		// input mode
		CheckNMwave(bdf+io+"gain", npnts, Nan)		// channel gain
		CheckNMwave(bdf+io+"tgain", npnts, Nan)		// telegraph gain
	endif

End // StimBoardWavesCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardConfigsOld2NewAll(sdf)
	String sdf
	
	String bdf = StimBoardDF(sdf)
	
	if ((DataFolderExists(bdf) == 1) || (strlen(bdf) == 0))
		return 0 // new board configs already exist
	endif

	Variable new1 = StimBoardConfigsOld2New(sdf, "ADC")
	Variable new2 = StimBoardConfigsOld2New(sdf, "DAC")
	Variable new3 = StimBoardConfigsOld2New(sdf, "TTL")
	
	if (new1 + new2 + new3 > 0)
		Print "Updated " + StimCurrent() + " to version " + NMVersionStr()
	endif
	
	return new1 + new2 + new3
	
End // StimBoardConfigsOld2NewAll

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardConfigsOld2New(sdf, io)
	String sdf
	String io

	Variable icnt, npnts
	String bdf
	
	sdf = CheckStimDF(sdf)
	bdf = StimBoardDF(sdf)
	
	if ((strlen(ClampIOcheck(io)) == 0) || (strlen(sdf) == 0))
		return 0
	endif
	
	if (WaveExists($sdf+io+"name") == 0)
		return 0 // nothing to do
	endif
	
	Variable numIO = numpnts($sdf+io+"name")

	StimBoardWavesCheckAll(sdf)
	
	if (WaveExists($bdf+io+"name") == 0)
		return 0 // something went wrong
	endif
	
	Wave /T nameN = $bdf+io+"name"
	Wave /T unitsN = $bdf+io+"units"
	Wave scaleN = $bdf+io+"scale"
	Wave boardN = $bdf+io+"board"
	Wave chanN = $bdf+io+"chan"
	
	Wave /T nameO = $sdf+io+"name"
	Wave /T unitsO = $sdf+io+"units"
	Wave scaleO = $sdf+io+"scale"
	Wave boardO = $sdf+io+"board"
	Wave chanO = $sdf+io+"chan"
	Wave onO = $sdf+io+"on"
	
	if (StringMatch(io, "ADC") == 1)
		Wave /T modeN = $bdf+io+"mode"
		Wave gainN = $bdf+io+"gain"
		Wave tgainN = $bdf+io+"tgain"
		Wave modeO = $sdf+io+"mode"
		Wave gainO = $sdf+io+"gain"
	endif
	
	npnts = numpnts(onO)
	
	if (numpnts(nameN) < npnts)
	
		npnts = max(npnts+5, ClampBoardNumConfigs())
	
		Redimension /N=(npnts) nameN, unitsN, scaleN, boardN, chanN
		
		if (StringMatch(io, "ADC") == 1)
			Redimension /N=(npnts) modeN, gainN, tgainN
		endif
		
	endif
	
	for (icnt = 0; icnt < numpnts(onO); icnt += 1)
	
		if (onO[icnt] == 1)
		
			nameN[icnt] = nameO[icnt]
			unitsN[icnt] = unitsO[icnt]
			scaleN[icnt] = scaleO[icnt]
			boardN[icnt] = boardO[icnt]
			chanN[icnt] = chanO[icnt]
			
			if (StringMatch(io, "ADC") == 1)
			
				gainN[icnt] = gainO[icnt]
				
				if (modeO[icnt] > 0)
					modeN[icnt] = "PreSamp=" + num2str(modeO[icnt])
				else
					modeN[icnt] = ""
				endif
				
			endif
			
		else
		
			nameN[icnt] = ""
			unitsN[icnt] = ""
			scaleN[icnt] = Nan
			boardN[icnt] = Nan
			chanN[icnt] = Nan
			
			if (StringMatch(io, "ADC") == 1)
				modeN[icnt] = ""
				gainN[icnt] = Nan
			endif
			
		endif
		
	endfor
	
	return 1

End // StimBoardConfigsOld2New

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardConfigsUpdateAll(sdf)
	String sdf
	
	Variable update1 = StimBoardConfigsUpdate(sdf, "ADC")
	Variable update2 = StimBoardConfigsUpdate(sdf, "DAC")
	Variable update3 = StimBoardConfigsUpdate(sdf, "TTL")
	
	if ((update2 == 1) || (update3 == 1))
		StimWavesCheck(sdf, 1)
	endif
	
End // StimBoardConfigsUpdateAll

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardConfigsUpdate(sdf, io)
	String sdf
	String io
	
	Variable icnt, jcnt, found, updated, board, chan, achan, gchan, npnts, board2
	String cname, modeStr, item, instr
	String cdf = ClampDF(), ludf = StimBoardLookUpDF(sdf), bdf = StimBoardDF(sdf)
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
	String tGainList = StrVarOrDefault(cdf+"TGainList", "")
	
	if (strlen(ClampIOcheck(io)) == 0)
		return 0
	endif
	
	if ((WaveExists($ludf+io+"name") == 0) || (WaveExists($bdf+io+"name") == 0))
		return 0
	endif
	
	Wave /T nameG = $ludf+io+"name"
	Wave /T unitsG = $ludf+io+"units"
	Wave scaleG = $ludf+io+"scale"
	Wave boardG = $ludf+io+"board"
	Wave chanG = $ludf+io+"chan"
	
	Wave /T nameS = $bdf+io+"name"
	Wave /T unitsS = $bdf+io+"units"
	Wave scaleS = $bdf+io+"scale"
	Wave boardS = $bdf+io+"board"
	Wave chanS = $bdf+io+"chan"
	
	if (StringMatch(io, "ADC") == 1)
		Wave /T modeG = $ludf+io+"mode"
		Wave gainG = $ludf+io+"gain"
		Wave /T modeS = $bdf+io+"mode"
		Wave gainS = $bdf+io+"gain"
		Wave tgainS = $bdf+io+"tgain"
	endif
	
	npnts = numpnts(nameG)
	
	if (numpnts(nameS) < npnts)
	
		npnts = max(npnts + 5, ClampBoardNumConfigs())
	
		Redimension /N=(npnts) nameS, unitsS, scaleS, boardS, chanS
		
		if (StringMatch(io, "ADC") == 1)
			Redimension /N=(npnts) modeS, gainS, tgainS
		endif
	
	endif
	
	if (StringMatch(io, "ADC") == 1)
	
		tgainS[icnt] = Nan
		
		for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
		
			cname = nameS[icnt]
			
			for (jcnt = 0; jcnt < 10; jcnt += 1)
				if (StringMatch(cname, "Tgain_" + num2str(jcnt)) == 1)
					nameS[icnt] = "" // clear old telegraph gain configs before updating
				endif
			endfor
			
		endfor
		
	endif
	
	for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
	
		cname = nameS[icnt]
	
		if (strlen(cname) == 0)
		
			unitsS[icnt] = ""
			scaleS[icnt] = Nan
			boardS[icnt] = Nan
			chanS[icnt] = Nan
	
			if (StringMatch(io, "ADC") == 1)
				modeS[icnt] = ""
				gainS[icnt] = Nan
			endif
			
			continue
	
		endif
		
		found = 0
		
		for (jcnt = 0; jcnt < numpnts(nameG); jcnt += 1)
		
			if (StringMatch(cname, nameG[jcnt]) == 1)
			
				found = 1
				
				if (StringMatch(unitsS[icnt], unitsG[jcnt]) == 0)
					unitsS[icnt] = unitsG[jcnt]
					updated = 1
				endif
				
				if (scaleS[icnt] != scaleG[jcnt])
					scaleS[icnt] = scaleG[jcnt]
					updated = 1
				endif
				
				if (boardS[icnt] != boardG[jcnt])
					boardS[icnt] = boardG[jcnt]
					updated = 1
				endif
				
				if (chanS[icnt] != chanG[jcnt])
					chanS[icnt] = chanG[jcnt]
					updated = 1
				endif
				
				if (StringMatch(io, "ADC") == 1)
				
					if (StringMatch(modeS[icnt], modeG[jcnt]) == 0)
						modeS[icnt] = modeG[jcnt]
						updated = 1
					endif
					
					if (gainS[icnt] != gainG[jcnt])
						gainS[icnt] = gainG[jcnt]
						updated = 1
					endif
					
				endif
				
				break
				
			endif
			
		endfor
		
		if (found == 0)
		
			unitsS[icnt] = ""
			scaleS[icnt] = Nan
			boardS[icnt] = Nan
			chanS[icnt] = Nan
	
			if (StringMatch(io, "ADC") == 1)
				modeS[icnt] = ""
				gainS[icnt] = Nan
			endif
		
		endif
		
	endfor
	
	//
	// BEGIN TELEGRAPH GAIN CONFIGS
	//
	
	if (StringMatch(io, "ADC") == 1)
	
		for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
		
			cname = nameS[icnt]
			
			if (StringMatch(cname[0,5], "Tgain_") == 1)
				nameS[icnt] = "" // remove pre-existing Tgain configs
			endif
			
		endfor
		
		// add new global Tgain configs if they exist
		
		for (icnt = 0; icnt < numpnts(nameG); icnt += 1)
		
			cname = nameG[icnt]
			
			if (StringMatch(cname[0,5], "Tgain_") == 1)
					
				modeStr = modeG[icnt]
				board = ClampTgainBoard(modeStr)
				chan = ClampTgainChan(modeStr)
				
				if (board == 0)
					board = driver
				endif
				
				found = 0
				
				for (jcnt = 0; jcnt < numpnts(nameS); jcnt += 1)
				
					board2 = boardS[jcnt]
					
					if (board2 == 0)
						board2 = driver
					endif
					
					if ((strlen(nameS[jcnt]) > 0) && (board2 == board) && (chanS[jcnt] == chan))
						found = 1
						break
					endif
					
				endfor
				
				if (found == 1)
	
					found = 0
					
					for (jcnt = 0; jcnt < numpnts(nameS); jcnt += 1)
						if (strlen(nameS[jcnt]) == 0)
							found = 1 // this is the first empty location
							break
						endif
					endfor
					
					if (found == 1)
						nameS[jcnt] = nameG[icnt]
					endif
				
				endif
			
			endif
			
		endfor
		
		if (ItemsInList(tGainList) > 0) // check for old telegraph-gain configs
		
			for (jcnt = 0; jcnt < ItemsInList(tGainList); jcnt += 1)
			
				cname = "Tgain_" + num2str(jcnt)
				item = StringFromList(jcnt, tGainList)
				board = 0 // default driver
				gchan = str2num(StringFromList(0, item, ",")) // telegraph gain ADC input channel
				achan = str2num(StringFromList(1, item, ",")) // ADC input channel to scale
				instr = StringFromList(2, item, ",") // amplifier instrument
				
				if (strlen(instr) == 0)
					instr = StrVarOrDefault(cdf+"ClampInstrument", "")
				endif
				
				if (strlen(instr) == 0)
					continue
				endif
				
				modeStr = "Tgain=B" + num2str(board) + "_C" + num2str(achan) + "_" + instr
				
				found = 0
				
				for (icnt = 0; icnt < numpnts(modeS); icnt += 1)
					if (StringMatch(modeS[icnt], modeStr) == 1)
						found = 1
						break
					endif
				endfor
				
				if (found == 1)
					continue // config already exists, go to next Tgain config
				endif
				
				board = driver
				
				for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
				
					board2 = boardS[icnt]
					
					if (board2 == 0)
						board2 = driver
					endif
					
					if ((strlen(nameS[icnt]) > 0) && (board2 == board) && (chanS[icnt] == achan))
						found = 1
						break
					endif
				endfor
				
				if (found == 1)
	
					found = 0
					
					for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
						if (strlen(nameS[icnt]) == 0)
							found = 1 // this is the first empty location
							break
						endif
					endfor
					
					if (found == 1)
						nameS[icnt] = "Tgain_" + num2str(jcnt)
						UnitsS[icnt] = "V"
						boardS[icnt] = 0
						chanS[icnt] = gchan
						scaleS[icnt] = 1
						modeS[icnt] = "Tgain=B0_C" + num2str(achan) + "_" + instr
						gainS[icnt] = 1
					endif
				
				endif
			
			endfor
		
		endif
		
		// udpate new telegraph-grain configs
	
		for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
		
			modeStr = modeS[icnt]
			
			if (ClampTgainModeCheck(modeStr) == 1)
			
				board = ClampTgainBoard(modeStr)
				chan = ClampTgainChan(modeStr)
				
				if (board == 0)
					board = driver
				endif
				
				if ((numtype(chan) == 0) || (numtype(board) == 0))
				
					for (jcnt = 0; jcnt < numpnts(nameS); jcnt += 1)
					
						board2 = boardS[jcnt]
						
						if (board2 == 0)
							board2 = driver
						endif
						
						if ((board == board2) && (chan == chanS[jcnt]))
							tgainS[jcnt] = icnt
						endif
						
					endfor
				
				endif
				
				//if ((numtype(chan) ==  0) && (chan >= 0) && (chan < numpnts(nameS)) && (strlen(nameS[chan]) > 0))
				//	tgainS[chan] = icnt
				//else
				
			endif
			
		endfor
		
	endif
	
	//
	// FINISH TELEGRAPH GAIN CONFIGS
	//
		
	return updated

End // StimBoardConfigsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardConfigsCheckDuplicates(sdf)
	String sdf

	Variable config, jcnt, test, on
	String bdf = StimBoardDF(sdf)
	
	sdf = CheckStimDF(sdf)
	
	if (WaveExists($bdf+"ADCname") == 0)
		return -1
	endif
	
	Wave /T ADCname = $bdf+"ADCname"
	Wave ADCchan = $bdf+"ADCchan"
	Wave /T ADCmode = $bdf+"ADCmode"
	Wave ADCboard = $bdf+"ADCboard"

	Wave /T DACname = $bdf+"DACname"
	Wave DACchan = $bdf+"DACchan"
	Wave DACboard = $bdf+"DACboard"
	
	Wave /T TTLname = $bdf+"TTLname"
	Wave TTLchan = $bdf+"TTLchan"
	Wave TTLboard = $bdf+"TTLboard"
	
	for (config = 0; config < numpnts(ADCname); config += 1)
	
		if (strlen(ADCname[config]) > 0)
		
			for (jcnt = 0; jcnt < numpnts(ADCname); jcnt += 1)
			
				test = 0
				
				if (strlen(ADCname[jcnt]) > 0)
					test = 1
				endif
			
				test = test && (ADCboard[jcnt] == ADCboard[config])
				test = test && (ADCchan[jcnt] == ADCchan[config]) && (StringMatch(ADCmode[jcnt], ADCmode[config]) == 1)
				
				if ((jcnt != config) && (test == 1))
					ClampError("duplicate ADC inputs for configs " + num2str(config) + " and " + num2str(jcnt))
					return -1
				endif
				
			endfor
			
		endif
		
	endfor
	
	for (config = 0; config < numpnts(DACname); config += 1)
	
		if (strlen(DACname[config]) > 0)
		
			for (jcnt = 0; jcnt < numpnts(DACname); jcnt += 1)
			
				test = 0
				
				if (strlen(DACname[jcnt]) > 0)
					test = 1
				endif
			
				test = test && (DACboard[jcnt] == DACboard[config]) && (DACchan[jcnt] == DACchan[config])
				
				if ((jcnt != config) && (test == 1))
					ClampError("duplicate DAC outputs for configs " + num2str(config) + " and " + num2str(jcnt))
					return -1
				endif
				
			endfor
			
		endif
		
	endfor
	
	for (config = 0; config < numpnts(TTLname); config += 1)
	
		if (strlen(TTLname[config]) > 0)
		
			for (jcnt = 0; jcnt < numpnts(TTLname); jcnt += 1)
			
				test = 0
				
				if (strlen(TTLname[jcnt]) > 0)
					test = 1
				endif
			
				test = test && (TTLboard[jcnt] == TTLboard[config]) && (TTLchan[jcnt] == TTLchan[config])
			
				if ((jcnt != config) && (test == 1))
					ClampError("duplicate TTL outputs for configs " + num2str(config) + " and " + num2str(jcnt))
					return -1
				endif
				
			endfor
			
		endif
		
	endfor
	
	return 0

End // ClampBoardWavesCheckDuplicates

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardConfigEdit(sdf, io, configName)
	String sdf
	String io
	String configName
	
	Variable icnt, board, chan, scale, config = -1
	String units, ludf = StimBoardLookUpDF(sdf)
	String unitsList = StrVarOrDefault(ClampTabDF()+"UnitsList", "")
	
	if (strlen(ClampIOcheck(io)) == 0)
		return -1
	endif
	
	if (WaveExists($ludf+io+"name") == 0)
		return -1
	endif
	
	Wave /T nameG = $ludf+io+"name"
	Wave /T unitsG = $ludf+io+"units"
	Wave scaleG = $ludf+io+"scale"
	Wave boardG = $ludf+io+"board"
	Wave chanG = $ludf+io+"chan"
	
	if (StringMatch(io, "ADC") == 1)
		Wave /T modeG = $ludf+io+"mode"
		Wave gainG = $ludf+io+"gain"
	endif
	
	for (icnt = 0; icnt < numpnts(nameG); icnt += 1)
		if (StringMatch(nameG[icnt], configName) == 1)
			config = icnt
			break
		endif
	endfor
	
	if ((config < 0) || (config >= numpnts(unitsG)))
		return -1
	endif
	
	units = unitsG[config]
	board = boardG[config]
	chan = chanG[config]
	scale = scaleG[config]
	
	prompt units, "units:", popup unitsList
	prompt board, "board:"
	prompt chan, "chan:"
	prompt scale, "scale:"
	
	DoPrompt io + " Config " + configName, units, board, chan, scale
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	unitsG[config] = units
	boardG[config] = board
	chanG[config] = chan
	scaleG[config] = scale
	
	return 0

End // StimBoardConfigEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardConfigActivate(sdf, io, config, configName)
	String sdf
	String io
	Variable config // (-1) next available
	String configName

	Variable icnt, npnts, configG = -1
	String tgain, wPrefix = StimWaveName(io, config, -1)
	String bdf = StimBoardDF(sdf), ludf = StimBoardLookUpDF(sdf)
	
	if (strlen(ClampIOcheck(io)) == 0)
		return -1
	endif
	
	if ((WaveExists($bdf+io+"name") == 0) || (WaveExists($ludf+io+"name") == 0))
		return -1
	endif
	
	Wave /T nameS = $bdf+io+"name"
	Wave /T unitsS = $bdf+io+"units"
	Wave scaleS = $bdf+io+"scale"
	Wave boardS = $bdf+io+"board"
	Wave chanS = $bdf+io+"chan"
	
	Wave /T nameG = $ludf+io+"name"
	Wave /T unitsG = $ludf+io+"units"
	Wave scaleG = $ludf+io+"scale"
	Wave boardG = $ludf+io+"board"
	Wave chanG = $ludf+io+"chan"
	
	if (StringMatch(io, "ADC") == 1)
		Wave modeS = $bdf+io+"mode"
		Wave gainS = $bdf+io+"gain"
		Wave modeG = $ludf+io+"mode"
		Wave gainG = $ludf+io+"gain"
	endif
	
	npnts = numpnts(nameS)
	
	if (config < 0)
	
		for (icnt = 0; icnt < npnts; icnt += 1)
			if (strlen(nameS[icnt]) == 0)
				config = icnt
				break
			endif
		endfor
	
	endif
	
	if (config < 0)
		return -1
	endif
	
	if (strlen(configName) > 0)
	
		for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
			if (StringMatch(nameS[icnt], configName) == 1)
				return -1 // already exists
			endif
		endfor
	
		for (icnt = 0; icnt < numpnts(nameG); icnt += 1)
			if (StringMatch(nameG[icnt], configName) == 1)
				configG = icnt
			endif
		endfor
		
	endif
		
	if ((configG >= 0) && (config >= 0) && (config < numpnts(nameS)))
	
		nameS[config] = configName
		unitsS[config] = unitsG[configG]
		scaleS[config] = scaleG[configG]
		boardS[config] = boardG[configG]
		chanS[config] = chanG[configG]
		
		if (StringMatch(io, "ADC") == 1)
		
			modeS[config] = modeG[configG]
			gainS[config] = gainG[configG]
			
			//CheckStimChanFolders()
			
		else // DAC and TTL
		
			PulseWaveCheck(io, config)
			StimWavesCheck(sdf, 1)// this creates waves
			
		endif
		
	else
	
		nameS[config] = ""
		unitsS[config] = ""
		scaleS[config] = Nan
		boardS[config] = Nan
		chanS[config] = Nan
		
		if (StringMatch(io, "ADC") == 1)
		
			modeS[config] = Nan
			gainS[config] = Nan
			
		else // DAC and TTL
		
			PulseWavesKill(sdf, wPrefix)
			PulseWavesKill(sdf, "u"+wPrefix)
			
		endif
		
	endif
	
	return 0

End // StimBoardConfigActivate

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardConfigIsActive(sdf, io, config)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	Variable config
	
	if (strlen(StimBoardConfigName(sdf, io, config)) > 0)
		return 1
	endif
	
	return 0
	
End // StimBoardConfigIsActive

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimBoardConfigActiveList(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	Variable icnt
	String alist = "", bdf = StimBoardDF(sdf)
	
	if (WaveExists($bdf+io+"name") == 0)
		return ""
	endif
	
	Wave /T name = $bdf+io+"name"
	
	for (icnt = 0; icnt < numpnts(name); icnt += 1)
		if (strlen(name[icnt]) > 0)
			alist = AddListItem(num2str(icnt), alist, ";", inf)
		endif
	endfor
	
	return alist
	
End // StimBoardConfigActiveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimBoardConfigName(sdf, io, config)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	Variable config
	
	String bdf = StimBoardDF(sdf)
	
	if (WaveExists($bdf+io+"name") == 0)
		return ""
	endif
	
	Wave /T name = $bdf+io+"name"
	
	if ((config >= 0) && (config < numpnts(name)) && (strlen(name[config]) > 0))
		return name[config]
	endif
	
	return ""

End // StimBoardConfigName

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardConfigExists(sdf, io, configName)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	String configName
	
	Variable icnt
	String bdf = StimBoardDF(sdf)
	
	if ((strlen(configName) == 0) || (WaveExists($bdf+io+"name") == 0))
		return 0
	endif
	
	Wave /T name = $bdf+io+"name"
	
	for (icnt = 0; icnt < numpnts(name); icnt += 1)
	
		if (StringMatch(name[icnt], configName) == 1)
			return 1
		endif
		
	endfor
	
	return 0

End // StimBoardConfigExists

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardNumADCchan(sdf)
	String sdf // stim data folder
	
	Variable config, ccnt
	String bdf = StimBoardDF(sdf)
	
	if ((WaveExists($bdf+"ADCname") == 0) || (WaveExists($bdf+"ADCmode") == 0))
		return 0
	endif
	
	Wave /T name = $bdf+"ADCname"
	Wave /T mode = $bdf+"ADCmode"

	for (config = 0; config < numpnts(name); config += 1)
		if ((strlen(name[config]) > 0) && (strlen(mode[config]) == 0))
			ccnt += 1
		endif
	endfor

	return ccnt

End // StimBoardNumADCchan

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimBoardOnList(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	Variable config
	String name, mode, list = ""
	String bdf = StimBoardDF(sdf)
	
	if (strlen(bdf) == 0)
		return ""
	endif
	
	strswitch(io)
	
		case "ADC":
	
			for (config = 0; config < numpnts($bdf+io+"name"); config += 1)
			
				name = WaveStrOrDefault(bdf+io+"name", config, "")
				mode = WaveStrOrDefault(bdf+io+"mode", config, "")
				
				if ((strlen(name) > 0) && (strlen(mode) == 0))
					list = AddListItem(num2str(config), list, ";", inf)
				endif
				
			endfor
			
			break
	
		case "DAC":
		case "TTL":
		
			for (config = 0; config < numpnts($bdf+io+"name"); config += 1)
				name = WaveStrOrDefault(bdf+io+"name", config, "")
				if (strlen(name) > 0)
					list = AddListItem(num2str(config), list, ";", inf)
				endif
			endfor
			
	endswitch
	
	return list
	
End // StimBoardOnList

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardOnCount(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	return ItemsInList(StimBoardOnList(sdf, io))
	
End // StimBoardOnCount

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimBoardNamesTable(sdf, hook)
	String sdf // stim data folder path
	Variable hook // (0) no update (1) updateNM
	
	String wName, tName, title, bdf
	
	sdf = CheckStimDF(sdf)
	bdf = StimBoardDF(sdf)
	
	String stim = GetPathName(sdf, 0)
	
	if (strlen(bdf) == 0)
		return ""
	endif
	
	tName = CheckGraphName(stim + "_config_names")
	
	if (WinType(tName) == 2)
		DoWindow /F $tName
		return tName
	endif
	
	title = "Stim config names : " + stim
	
	DoWindow /K $tName
	Edit /N=$tName/W=(0,0,0,0)/K=1 as title[0,30]
	SetCascadeXY(tName)
	Execute "ModifyTable title(Point)= \"Config\""
	
	if (hook == 1)
		SetWindow $tName hook=StimBoardNamesTableHook
	endif
	
	wName = bdf + "ADCname"
	
	if (WaveExists($wName) == 1)
		AppendToTable $wName
	endif
	
	wName = bdf + "DACname"
	
	if (WaveExists($wName) == 1)
		AppendToTable $wName
	endif
	
	wName = bdf + "TTLname"
	
	if (WaveExists($wName) == 1)
		AppendToTable $wName
	endif
	
	return tName

End // StimBoardNamesTable

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardNamesTableHook(infoStr)
	string infoStr
	
	string event= StringByKey("EVENT",infoStr)
	string win= StringByKey("WINDOW",infoStr)
	
	strswitch(event)
		case "deactivate":
		case "kill":
			UpdateNM(0)
	endswitch

End // StimBoardNamesTableHook

//****************************************************************
//****************************************************************
//****************************************************************