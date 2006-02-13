#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Acquisition Stim Protocol Functions
//	To be run with NeuroMatic, v1.91
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
//	Last modified 11 April 2004
//
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
		StimWavesUpdate(1) // create stim waves
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
	String file, sname, dp = ClampDF()
	
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
			sname = StimOpen(0, dp, file)
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
	
	StimWavesMove(folder, temp) // move stim waves before saving

	file = FileBinSave(dialogue, new, dp+sname, path, file, 1, -1) // NM_FileManager
	
	if (DataFolderExists(temp) == 1)
		StimWavesMove(temp, folder) // replace stim waves
		KillDataFolder $(temp)
	endif

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
//	Current Stim functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimDF() // return full-path name of current stim folder
	String cdf = ClampDF()
	
	return cdf + StrVarOrDefault(cdf+"CurrentStim", "") + ":"
	
End // StimDF

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
	
	String cdf = ClampDF()
	String CurrentStim = StimCurrent()
	String sList = NMFolderList(cdf,"NMStim")
	
	if (strlen(CurrentStim+sList) == 0) // nothing is open
	
		CurrentStim = "Stim0"
		StimNew(cdf, CurrentStim) // begin with blank stim
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
	
	String sdf, cdf = ClampDF()
	
	if (strlen(fname) == 0)
		SetNMstr(cdf+"CurrentStim", "")
		return -1
	endif
	
	if (stringmatch(fname, StimCurrent()) == 1)
		//return 0 // already current stim
	endif
	
	if (DataFolderExists(cdf+fname) == 0)
		return -1
	endif
	
	if (IsStimFolder(cdf, fname) == 0)
		ClampError("\"" + fname + "\" is not a NeuroMatic stimulus folder.")
		return -1
	endif
	
	sdf = cdf + fname + ":"
	
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
	
	ClampStatsRetrieve(sdf) // get Stats from new stim
	ClampGraphsCopy(-1, -1) // get Chan display variables
	ChanGraphsReset()
	
	UpdateNMPanel(0)
	ClampTabUpdate()
	ChanGraphsUpdate(1)
	
	StatsDisplayClear()
	
	return 0
	
End // StimCurrentSet

//****************************************************************
//****************************************************************
//****************************************************************

Function StimWavesUpdate(force) // update stim waves
	Variable force
	
	Variable icnt, outNum, ORflag
	String out, wprefix, plist, sdf = StimDF()
	
	Variable update = NumVarOrDefault(sdf+"UpdateStim", 1)

	if ((force == 1) || (update == 1))
		plist = StimPrefixListAll(sdf)
		StimWavesMakeAll(sdf, sdf, plist, -1)
		SetNMvar(sdf+"UpdateStim", 0)
	endif

End // StimWavesUpdate

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
	return NumVarOrDefault(StimDF()+"StatsOn", 0)
End // StimStatsOn

//****************************************************************
//****************************************************************
//****************************************************************

Function StimChainOn()
	return NumVarOrDefault(StimDF()+"AcqStimChain", 0)
End // StimChainOn

//****************************************************************
//****************************************************************
//****************************************************************