#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Folder Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last modified 02 April 2007
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderCall(select)
	String select
	
	strswitch(select)
	
		case "New":
			NMFolderNewCall()
			break
			
		case "Open":
			NMFolderOpen()
			break
			
		case "Open All":
			NMFolderOpenAll()
			break
		
		case "Append All":
			NMFolderAppendAll()
			break
			
		case "Append":
		case "Open | Append":
			NMFolderAppend()
			break
		
		case "Merge":
			NMFolderMerge()
			break
			
		case "Save":
			NMFolderSave()
			break
			
		case "Save":
			NMFolderSaveAll()
			break
		
		case "Kill":
		case "Close":
			NMFolderCloseCurrent()
			break
			
		case "Kill All":
		case "Close All":
			DoAlert 1, "Are you sure you want to close all NeuroMatic data folders?"
			if (V_Flag != 1)
				break
			endif
			NMCmdHistory("NMFolderCloseAll", "")
			NMFolderCloseAll()
			break
			
		case "Duplicate":
			NMFolderDuplicateCall()
			break
			
		case "Rename":
			NMFolderRenameCall()
			break
			
		case "Change":
			NMFolderChangeCall()
			break
			
		case "Import":
		case "Import Data":
		case "Import Waves":
			NMImportFileCall()
			break
			
		case "Reload":
		case "Reload Data":
		case "Reload Waves":
			NMCmdHistory("NMDataReload", "")
			NMDataReload()
			break
			
		case "Rename Waves":
			NMRenameWavesCall("All") // NM_MainTab.ipf
			break
			
		case "Convert":
			NMBin2IgorCall()
			break
			
		case "Open Path":
			SetOpenDataPathCall()
			break
			
		case "Save Path":
			SetSaveDataPathCall()
			break
			
	endswitch
	
End // NMFolderCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderPath(df)
	String df // folder name, or ("") for current
	
	if (strlen(df) == 0)
		df = GetDataFolder(1)
	elseif (StringMatch(df[0,4], "root:") == 0)
		df = "root:" + df
	endif
	
	return LastPathColon(df, 1)
	
End // NMFolderPath

//****************************************************************
//****************************************************************
//****************************************************************

Function SetOpenDataPathCall()

	NMCmdHistory("SetOpenDataPath", "")
	SetOpenDataPath()

End // SetOpenDataPathCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SetOpenDataPath()

	String df = NMDF()
	
	NewPath /Q/O/M="Stim File Directory" OpenDataPath
	
	if (V_flag == 0)
		PathInfo OpenDataPath
		SetNMstr(df+"OpenDataPath", S_Path)
		//DoAlert 0, "Don't forget to save changes by saving your Configurations (NeuroMatic > Configs > Save)."
	endif
	
	return V_flag

End // SetOpenDataPath

//****************************************************************
//****************************************************************
//****************************************************************

Function SetSaveDataPathCall()

	NMCmdHistory("SetSaveDataPath", "")
	SetSaveDataPath()

End // SetSaveDataPathCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SetSaveDataPath()

	String df = NMDF()
	
	NewPath /Q/O/M="Stim File Directory" SaveDataPath
	
	if (V_flag == 0)
		PathInfo SaveDataPath
		SetNMstr(df+"SaveDataPath", S_Path)
		//DoAlert 0, "Don't forget to save changes by saving your Configurations (NeuroMatic > Configs > Save)."
	endif
	
	return V_flag

End // SetSaveDataPath

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMDataFolders() // check all NM Data folders
	Variable icnt

	String saveDF = GetDataFolder(1)
	String fList = NMDataFolderList()
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		SetDataFolder $("root:" + StringFromList(icnt, flist))
		CheckNMDataFolder()
	endfor
	
	SetDataFolder $saveDF

End // CheckNMDataFolders

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMDataFolder() // check data folder globals
 
	String wPrefix = StrVarOrDefault("WavePrefix", "")
	
	// file stats
	
	CheckNMvar("FileFormat", NumVarOrDefault(NMDF()+"NMversion",-1))
	CheckNMvar("FileDateTime", DateTime)
	
	CheckNMstr("FileName", GetDataFolder(0))	// file name, excluding directory extension
	CheckNMstr("CurrentFile", "")				// file name, including directory extension
	CheckNMstr("FileType", "NMData")			// NM data folder
	CheckNMstr("AcqMode", "")				// file acquisition mode
	CheckNMstr("FileDate", date())
	CheckNMstr("FileTime", time())
	
	// about waves
	
	CheckNMvar("NumWaves", 0) 				// waves per channel
	CheckNMvar("TotalNumWaves", 0) 			// NumWaves*NumChannels
	CheckNMvar("SamplesPerWave", 0) 		// sample points per wave
	CheckNMvar("SampleInterval", 1)			// time sample interval (ms)
	CheckNMvar("CurrentWave", 0)				// current wave to display
	CheckNMvar("NumActiveWaves", 0) 		// number of active waves to analyze
	CheckNMvar("WaveSkip", 1) 				// wave increment flag
	
	CheckNMstr("WavePrefix", "Record")		// data wave prefix name
	CheckNMstr("CurrentPrefix", wPrefix)		// current WavePrefix
	CheckNMstr("xLabel", "msec")				// x-axis label
	
	// channels
	
	CheckNMvar("NumChannels", 0)			// number of channels
	CheckNMvar("CurrentChan", 0)				// current active channel
	
	// groups
	
	CheckNMvar("NumGrps", 0)				// number of wave groups 
	CheckNMvar("CurrentGrp", 0)				// current group number				
	
	// sets
	
	CheckNMvar("SumSet1", 0)				// Set counters
	CheckNMvar("SumSet2", 0)
	CheckNMvar("SumSetX", 0)
	
	// more checks
	
	CheckNMDataFolderWaves() // check/create waves
	
	if ((NumVarOrDefault("NumGrps", 0) == 0) && (exists("NumStimWaves") == 2))
		SetNMvar("NumGrps", NumVarOrDefault("NumStimWaves", 0))
		SetNMvar("CurrentGrp", Nan)
		NMGroupSeqDefault() // set Groups for Nclamp data
	endif
	
	return 0
	
End // CheckNMDataFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMDataFolderWaves() // check data folder waves
	
	Variable nchans = NumVarOrDefault("NumChannels", 1)
	Variable nwaves = NumVarOrDefault("NumWaves", 0)

	CheckWavSelectWave()
	
	CheckNMwave("WavSelect", nwaves, 1)
	CheckNMwave("ChanSelect", nchans, 0)
	
	CheckNMtwave("ChanWaveList", nchans, "")
	CheckNMtwave("yLabel", nchans, "")				// channel y-axis labels
	
	CheckNMwave("Group", nwaves, Nan)
	
	CheckNMwave("Set1;Set2;SetX;", nwaves, 0)
	
	NMSetsTagDefaults() // check Set tags
	
	//CheckNMwave("FileScaleFactors",  nchans, 1)		// file scale factors, read from data file header
	//CheckNMwave("MyScaleFactors", nchans, 1)		// user channel scale factors
	
	CheckNMDataNotes()
	
	return 0
	
End // CheckNMDataFolderWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckWavSelectWave() // check new WavSelect wave

	if ((WaveExists(WavSelect) == 0) && (WaveExists(WaveSelect) == 1))
		Rename WaveSelect WavSelect
	endif

End // CheckWavSelectWave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMDataNotes() // check data notes
	
	Variable ccnt, wcnt
	String wName, wList, wNote, yl
	
	String df = GetDataFolder(1)

	if (WaveExists(ChanWaveList) == 0)
		return -1
	endif
	
	String type = StrVarOrDefault("DataFileType", "")
	String wPrefix = StrVarOrDefault("WavePrefix", "")
	String file = StrVarOrDefault("CurrentFile", "")
	String fdate = StrVarOrDefault("FileDate", "")
	String ftime = StrVarOrDefault("FileTime", "")
	String xl = StrVarOrDefault("xLabel", "")
	String folder = GetPathName(df, 0)
	
	String stim = SubStimName(df)
	
	if (strlen(wPrefix) == 0)
		return -1
	endif
	
	Wave /T ChanWaveList
	Wave /T yLabel
	
	strswitch(type)
		case "IgorBin":
		case "NMBin":
			type = "NMData"
	endswitch
	
	for (ccnt = 0; ccnt < numpnts(ChanWaveList); ccnt += 1)
	
		wList = ChanWaveList[ccnt]
		yl = yLabel[ccnt]
		
		for (wcnt = 0; wcnt < ItemsInlist(wList); wcnt += 1)
		
			wName = StringFromList(wcnt, wList)
			
			if (WaveExists($wName) == 0)
				continue
			endif
			
			//if (strsearch(wName, wPrefix, 0, 2) < 0)
			if (strsearch(wName, wPrefix, 0) < 0)
				continue
			endif
			
			if (strlen(NMNoteStrByKey(wName, "Type")) == 0)
				wNote = "Stim:" + stim
				wNote += "\rFolder:" + folder
				wNote += "\rDate:" + NMNoteCheck(fdate)
				wNote += "\rTime:" + NMNoteCheck(ftime)
				wNote += "\rChan:" + ChanNum2Char(ccnt)
				NMNoteType(wName, type, xl, yl, wNote)
			endif
			
			if (strlen(NMNoteStrByKey(wName, "File")) == 0)
				Note $wName, "File:" + NMNoteCheck(file)
			endif
			
		endfor
	
	endfor
	
End // CheckNMDataNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFolderType(df)
	String df
	
	df = NMFolderPath(df)
	
	if (exists(df+"FileType") == 0)
		return 0
	endif

	String ftype = StrVarOrDefault(df+"FileType", "")
	
	if (StringMatch(ftype, "pclamp") == 1)
	
		SetNMstr(df+"DataFileType", "pclamp")
		SetNMstr(df+"FileType", "NMData")
		
	elseif (StringMatch(ftype, "axograph") == 1)
	
		SetNMstr(df+"DataFileType", "axograph")
		SetNMstr(df+"FileType", "NMData")
		
	elseif (StringMatch(ftype, "") == 1)
	
		SetNMstr(df+"FileType", "NMData")
		
	endif

End // CheckNMFolderType

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNumChannels()

	return NumVarOrDefault("NumChannels", 0)

End // NMNumChannels

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentChan()

	return NumVarOrDefault("CurrentChan", 0)

End // NMCurrentChan

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNumWaves()

	return NumVarOrDefault("NumWaves", 0)

End // NMNumWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentWave()

	return NumVarOrDefault("CurrentWave", 0)

End // NMCurrentWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderGlobalsReset()

	if (WavesExist("Set1;Set2;SetX;Group;") == 1)
		Wave Group, Set1, Set2, SetX
		Set1 = 0
		Set2 = 0
		SetX = 0
		Group = Nan
	endif
	
	SetNMvar("CurrentChan", 0)
	SetNMvar("CurrentWave", 0)
	SetNMvar("CurrentGrp", 0)
	SetNMvar("WaveSkip", 1)
	
	NMWaveSelect("All")

End // NMFolderGlobalsReset

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderGlobalsSave(wPrefix) // save globals to a folder. called when switching between wave prefixes
	String wPrefix // wave prefix name
	
	Variable icnt
	String setList, setName
	
	if (WavesExist("Set1;Set2;SetX;Group;WavSelect;ChanSelect;") == 0)
		return 0
	endif
	
	String df = GetDataFolder(1)
	
	if (strlen(wPrefix) == 0)
		return 0
	endif
	
	NewDataFolder /O $wPrefix // create folder to save globals
	
	SetNMvar(df + wPrefix + ":NumChannels", NumVarOrDefault("NumChannels", 0))
	SetNMvar(df + wPrefix + ":NumGrps", NumVarOrDefault("NumGrps", 0))
	
	Duplicate /O Group $(df + wPrefix + ":Group")
	Duplicate /O WavSelect $(df + wPrefix + ":WavSelect")
	Duplicate /O ChanSelect $(df + wPrefix + ":ChanSelect")
	
	setList = NMSetsList(1) // strict Set list
	NMSetsTable(-1) // remove Set waves
	NMGroupsTable(-1) // remove Group waves
	
	for (icnt = 0; icnt < ItemsInlist(setList); icnt += 1)
		setName = StringFromList(icnt, setList)
		Duplicate /O $setName $(df + wPrefix + ":" + setName)
		KillWaves /Z $setName
	endfor

End // NMFolderGlobalsSave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderGlobalsGet(wPrefix) // get saved globals from folder
	String wPrefix // wave prefix name
	
	//Variable killFolder = 0 // kill folder when finished
	
	Variable ocnt
	String objName, oList
	
	String setList, setName, oldSet
	
	String df = GetDataFolder(1)
	String subFolder = df + wPrefix + ":"
	
	if (DataFolderExists(wPrefix) == 0)
		return -1
	endif
	
	olist = FolderObjectList(subFolder, 1) // waves
	
	for (ocnt = 0; ocnt < ItemsInlist(olist); ocnt += 1)
		objName = StringFromList(ocnt, olist)
		Duplicate /O $(subFolder+objName) $objName
	endfor
	
	olist = FolderObjectList(subFolder, 2) // variables
	
	for (ocnt = 0; ocnt < ItemsInlist(olist); ocnt += 1)
		objName = StringFromList(ocnt, olist)
		SetNMvar(objName, NumVarOrDefault(subFolder+objName, Nan))
	endfor
	
	olist = FolderObjectList(subFolder, 3) // strings
	
	for (ocnt = 0; ocnt < ItemsInlist(olist); ocnt += 1)
		objName = StringFromList(ocnt, olist)
		SetNMstr(objName, StrVarOrDefault(subFolder+objName, ""))
	endfor
	
	//if (killFolder == 1)
	//	KillDataFolder $(df + wPrefix)
	//endif
	
	return 0

End // NMFolderGlobalsGet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderNewCall()

	String folder = FolderNameNext("")
	
	Prompt folder, "enter new folder name:"
	DoPrompt "Create New NeuroMatic Folder", folder
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	NMCmdHistory("NMFolderNew", NMCmdStr(folder,""))
	
	NMFolderNew(folder)

End // NMFolderNewCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderNew(folder) // create a new NM data folder
	String folder // name of folder ("") for next default name
	
	if (strlen(folder) == 0)
		folder = FolderNameNext("")
	endif
	
	folder =NMFolderPath(folder)
	
	folder = CheckFolderName(folder)
	
	if (strlen(folder) == 0)
		return ""
	endif

	if (DataFolderExists(folder) == 1)
		return "" // already exists
	endif
	
	NMSetsTable(-1) // remove Set waves
	NMGroupsTable(-1) // remove Group waves
	
	NewDataFolder /S $LastPathColon(folder, 0)
	
	SetNMstr(NMDF() + "CurrentFolder", GetDataFolder(1))
	
	CheckNMDataFolder()
	NMFolderListAdd(folder)
	ChanGraphsReset()
	UpdateNM(1)
	
	return folder // return folder name

End // NMFolderNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderChangeCall() // change the active folder
	String folder, flist = NMDataFolderList()
	
	folder = StringFromList(0, flist)
	
	folder = GetPathName(folder, 0)
	
	flist = RemoveFromList(GetDataFolder(0), flist) // remove active folder from list

	If (ItemsInList(flist) == 0)
		DoAlert 0, "Abort NMFolderChange: no folders to change to."
		return ""
	endif
	
	Prompt folder, "choose folder:", popup flist
	DoPrompt "Change NeuroMatic Folder", folder
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	NMCmdHistory("NMFolderChange", NMCmdStr(folder,""))
	
	return NMFolderChange(folder)

End // NMFolderChangeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderChange(folder) // change the active folder
	String folder
	
	String df = NMDF()
	
	if (strlen(folder) == 0)
		return ""
	endif
	
	folder =NMFolderPath(folder)
	
	if (IsNMFolder(folder, "NMLog") == 1)
		Execute "LogDisplayCall(\"" + folder + "\")"
		return ""
	endif
	
	if (IsNMDataFolder(folder) == 0)
		return ""
	endif
	
	if (DataFolderExists(folder) == 0)
		DoAlert 0, "Abort NMFolderChange: folder does not exist."
		return ""
	endif
	
	NMSetsTable(-1) // remove Set waves
	NMGroupsTable(-1) // remove Group waves
	
	if (strlen(NMFolderListName(folder)) == 0)
		NMFolderListAdd(folder)
	endif
	
	ChanScaleSave(-1)
	
	SetDataFolder folder
	
	SetNMstr(df+"CurrentFolder", GetDataFolder(1))
	ChanGraphsReset()
	ChanWaveListSet(0) // check channel wave names
	UpdateNM(1)
	
	return folder

End // NMFolderChange

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderChangeToFirst()

	String flist = NMDataFolderList()
		
	if (ItemsInList(flist) > 0)
		return NMFolderChange(StringFromList(0,flist)) // change to first data folder
	else
		NMFolderNew("")
	endif
		
End // NMFolderChangeToFirst

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderCloseAll()
	Variable icnt
	String fname
	
	String flist = NMDataFolderList() + NMFolderList("root:","NMLog")
	
	if (ItemsInList(flist) == 0)
		return 0
	endif
	
	for (icnt = 0; icnt < ItemsInlist(flist); icnt += 1)
		NMFolderClose(StringFromList(icnt,flist))
	endfor
	
	SetNMstr(NMDF()+"CurrentFolder", "")
	
	NMFolderChangeToFirst()
	
	//UpdateNMPanelTitle()

End // NMFolderCloseAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderCloseCurrent()
	String txt, nfolder = "", folder = GetDataFolder(0)
	Variable inum
	
	String flist = NMDataFolderList()
	
	inum = WhichListItem(folder, flist)
	
	if (inum < 0)
		return ""
	endif
	
	nfolder = StringFromList(inum+1, flist)
	
	txt = "Are you sure you want to kill the current NeuroMatic data folder?"
	txt += " This will kill all graphs, tables and waves associated with this folder."
	
	DoAlert 1, txt
	
	if (V_flag != 1)
		return ""
	endif
	
	NMCmdHistory("NMFolderClose", NMCmdStr(folder,""))

	if (NMFolderClose(folder) == -1)
		return ""
	endif
	
	if (IsNMDataFolder(folder) == 1)
		return ""
	endif
	
	SetNMstr(NMDF() + "CurrentFolder", "")
	
	if (strlen(nfolder) > 0)
		return NMFolderChange(nfolder) // change to next data folder
	else
		return NMFolderChangeToFirst()
	endif
	
	//UpdateNMPanelTitle()
	
	return ""
	
End // NMFolderCloseCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderClose(folder) // close/kill a data folder
	String folder // folder path
	
	String thisFolder = GetDataFolder(1)
	
	if (strlen(folder) == 0)
		return -1
	endif
	
	folder =NMFolderPath(folder)
	
	NMKillWindows(folder) // old kill method
	NMFolderWinKill(folder) // new FolderList function
	
	if (StringMatch(thisFolder, folder) == 1)
		ChanGraphClose(-1,1)
		NMSetsTable(-1) // remove Set waves
		NMGroupsTable(-1) // remove Group waves
	endif

	if (DataFolderExists(folder) == 1)
		KillDataFolder $folder
	endif
	
	if (DataFolderExists(folder) == 0)
		NMFolderListRemove(folder)
	endif
	
	return 0

End // NMFolderClose

//****************************************************************
//****************************************************************
//****************************************************************

Function NMKillWindows(folder)
	String folder
	
	Variable wcnt
	
	if ((strlen(folder) == 0) || (IsNMDataFolder(folder) == 0))
		return -1
	endif
	
	folder = GetPathName(folder, 0)
	
	String wlist = WinList("*" + folder + "*", ";", "")
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
		DoWindow /K $StringFromList(wcnt,wlist)
	endfor
	
	return 0
	
End // NMKillWindows

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderWinKill(folder)
	String folder
	
	String wName
	Variable wcnt
	
	if (IsNMDataFolder(folder) == 0)
		return -1
	endif
	
	String wlist = WinList("*" + NMFolderPrefix(folder) + "*", ";", "")
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
		
		wName = StringFromList(wcnt,wlist)
		
		if (WinType(wName) == 0)
			continue
		endif
		
		DoWindow /K $wName
		
	endfor
	
	return 0
	
End // NMFolderWinKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderDuplicateCall()

	String folder = GetDataFolder(0)
	String newname = FolderNameNext(folder + "_copy0")
	String vlist = ""
	
	Prompt newName, "enter new folder name:"
	DoPrompt "Duplicate NeuroMatic Data Folder", newname
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	if (StringMatch(folder, newname) == 1)
		return -1 // not allowed
	endif
	
	//if (DataFolderExists(NMFolderPath(newName)) == 1)
	//	DoAlert 0, "Abort NMFolderDuplicate: folder name already in use."
	//	return -1
	//endif
	
	vlist = NMCmdStr(folder, vlist)
	vlist = NMCmdStr(newName, vlist)
	NMCmdHistory("NMFolderDuplicate", vlist)
	
	NMFolderDuplicate(folder, newName)
	
	return 0

End // NMFolderDuplicateCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderDuplicate(folder, newName) // duplicate NeuroMatic data folder
	String folder // folder to copy
	String newname
	
	String df = LastPathColon(NMFolderPath(newname), 0)
	
	df = CheckFolderName(df)
	
	if (strlen(df) == 0)
		return ""
	endif
	
	folder = LastPathColon(NMFolderPath(folder), 0)
	
	DuplicateDataFolder $folder, $df
	
	NMFolderListAdd(newName)
	
	return newName

End // NMFolderDuplicate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderRenameCall()

	String oldname = GetDataFolder(0)
	String newname = oldname
	String vlist = ""
	
	Prompt newName, "rename \"" + oldname + "\" as:"
	DoPrompt "Rename NeuroMatic Data Folder", newname
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	if (StringMatch(oldname, newname) == 1)
		return -1 // nothing new
	endif
	
	//if (DataFolderExists(NMFolderPath(newName)) == 1)
	//	DoAlert 0, "Abort NMFolderRename: folder name already in use."
	//	return -1
	//endif
	
	vlist = NMCmdStr(oldName, vlist)
	vlist = NMCmdStr(newName, vlist)
	NMCmdHistory("NMFolderRename", vlist)
	
	NMFolderRename(oldName, newName)
	
	return 0

End // NMFolderRenameCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderRename(oldName, newName) // rename NeuroMatic data folder
	String oldname
	String newname
	
	String df = NMFolderPath(newName)
	
	// note, this function does NOT change graph or table names
	// associated with the old folder name
	
	df = CheckFolderName(df)
	
	if (strlen(df) == 0)
		return ""
	endif
	
	if (DataFolderExists(df) == 1)
		//DoAlert 0, "Abort NMFolderRename: folder name already in use."
		return ""
	endif
	
	oldName =NMFolderPath(oldName)
	
	RenameDataFolder $oldName, $newName
	
	NMFolderListChange(oldName, newName)
	
	SetNMstr(NMDF() + "CurrentFolder", GetDataFolder(1))
	UpdateNM(0)
	
	return newName

End // NMFolderRename

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderOpen()
	
	String fname = FileBinOpen(1, 1, "root:", "OpenDataPath", "", 1)
	
	NMTab("Main") // force back to Main tab
	UpdateNM(1)
	
	return fname

End // NMFolderOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderOpenAll()

	String fname, flist

	flist = FileBinOpenAll(1, "root:", "OpenDataPath")
	
	if (ItemsInList(flist) == 0)
		return ""
	else
		fname = StringFromList(0, flist)
		NMFolderChange(fname) 
	endif
	
	NMTab("Main") // force back to Main tab
	UpdateNM(1)

	return flist

End // NMFolderOpenAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderAppendAll()
	
	
	DoAlert 0, "Alert: NMFolderAppendAll has been deprecated."
	
	return ""

End // NMFolderAppendAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDataReloadCall()

	DoAlert 1, "Warning: reloading will over-write existing data. Do you want to continue?"
	
	if (V_Flag != 1)
		return 0
	endif

	NMCmdHistory("NMDataReload", "")
	NMDataReload()

End // NMDataReloadCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDataReload()

	String file = StrVarOrDefault("CurrentFile", "")
	String temp = NMFolderPath("reload_temp")
	String folder, saveDF = GetDataFolder(1)
	
	String wPrefix = StrVarOrDefault("WavePrefix", "")
	
	if (FileExists(file) == 0)
		return -1
	endif
	
	if (DataFolderExists(temp) == 1)
		KillDataFolder temp // shouldnt be here
	endif
	
	strswitch(StrVarOrDefault("DataFileType",""))
		case "Pclamp":
		case "Axograph":
			//NMImportFile(temp, file)
			return 0
		case "NMBin":
			folder = NMBinOpen(temp, file, "1111", 1)
			break
		case "IgorBin":
			folder = IgorBinOpen(temp, file, 1) // Igor 5 LoadData
			break
		default:
			return -1
	endswitch
	
	if (strlen(folder) == 0)
		SetDataFolder $saveDF // failure, back to original folder
		return -1
	endif
	
	NMChanSelect( "All" )
	
	NMCopyWavesTo(saveDF, "", -inf, inf, 0, 0)
	
	NMFolderChange(saveDF)
	
	if (DataFolderExists(temp) == 1)
		//KillDataFolder temp
		NMFolderClose(temp)
	endif
	
	NMPrefixSelectSilent(wPrefix)
	
	return 0

End // NMDataReload

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderAppend()

	DoAlert 0, "Alert: NMFolderAppend has been deprecated."

End // NMFolderAppend

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderMerge()

	DoAlert 0, "Alert: NMFolderMerge has been deprecated."

End // NMFolderMerge

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderAppendWaves(fromFolder, toFolder, wavePrefix)
	String fromFolder // folder to concatenate
	String toFolder // to this folder
	String wavePrefix // wave prefix of BOTH folders (i.e. "Record")
	
	DoAlert 0, "Alert: NMFolderAppendWaves has been deprecated."

End // NMFolderAppendWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderSave() // save current NM folder
	
	return FileBinSave(1, 1, "", "SaveDataPath", "", 1, -1)
	
End // NMFolderSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderSaveAll()

	Variable icnt
	String folder, file, slist = "", flist = NMDataFolderList()
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		folder = NMFolderPath(StringFromList(icnt, flist))
		
		file = FileBinSave(1, 1, folder, "SaveDataPath", "", 1, -1)
		
		slist = AddListItem(file, slist, ";", inf)
		
	endfor
	
	return slist
	
End // NMFolderSaveAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderList(df, type)
	String df // data folder to look in ("") for current
	String type // "NMData", "NMStim", "NMLog", ("") any
	
	Variable index
	String objName, folderlist = ""
	
	if (strlen(df) == 0)
		df = GetDataFolder(1)
	endif
	
	do
		objName = GetIndexedObjName(df, 4, index)
		
		if (strlen(objName) == 0)
			break
		endif
		
		CheckNMFolderType(objName)
		
		if (IsNMFolder(df+objName, type) == 1)
			folderlist = AddListItem(objName, folderlist, ";", inf)
		endif
		
		index += 1
		
	while(1)
	
	return folderlist

End // NMFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDataFolderList()

	return NMFolderList("root:","NMData")
	
End // NMDataFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDataFolderListLong() // includes Folder list name (i.e. "F0")
	Variable icnt
	
	String fname, flist2 = "", flist = NMFolderList("root:","NMData")
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		fname = StringFromList(icnt, flist)
		fname = NMFolderListName(fname) + " : " + fname
		flist2 = AddListItem(fname, flist2, ";", inf)
	endfor

	return flist2
	
End // NMDataFolderListLong

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLogFolderListLong()
	Variable icnt
	
	String fname, flist2 = "", flist = NMFolderList("root:","NMLog")
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		fname = StringFromList(icnt, flist)
		fname = "L" + num2str(icnt) + " : " + fname
		flist2 = AddListItem(fname, flist2, ";", inf)
	endfor

	return flist2
	
End // NMLogFolderListLong

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListAdd(folder)
	String folder
	
	Variable icnt, found, npnts
	String df = NMDF()
	
	String wName = df + "FolderList"
	
	if (WaveExists($wName) == 0)
		return -1
	endif
	
	Wave /T list = $wname
	
	folder = GetPathName(folder, 0)
	
	npnts = numpnts(list)
	
	for (icnt = 0; icnt < npnts; icnt += 1)
		if (StringMatch(folder, list[icnt]) == 1)
			return 0 // already exists
		endif
	endfor
	
	for (icnt = npnts-1; icnt >= 0; icnt -=1)
		if (strlen(list[icnt]) > 0)
			found = 1
			break
		endif
	endfor
	
	icnt = icnt + 1
	
	if (icnt < npnts)
		list[icnt] = folder
	else
		Redimension /N=(icnt+1) list
		list[icnt] = folder
	endif
	
End // NMFolderListAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListRemove(folder)
	String folder
	
	Variable icnt, found, npnts
	String df = NMDF()
	
	String wName = df + "FolderList"
	
	if (WaveExists($wName) == 0)
		return -1
	endif
	
	Wave /T list = $wName
	
	folder = GetPathName(folder, 0)
	
	npnts = numpnts(list)
	
	for (icnt = 0; icnt < npnts; icnt += 1)
		if (StringMatch(folder, list[icnt]) == 1)
			list[icnt] = ""
			return 1
		endif
	endfor
	
	return 0
	
End // NMFolderListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListChange(oldName, newName)
	String oldName, newName
	
	Variable icnt, found, npnts
	String df = NMDF()
	
	String wName = df + "FolderList"
	
	if (WaveExists($wName) == 0)
		return -1
	endif
	
	Wave /T list = $wName
	
	oldName = GetPathName(oldName, 0)
	
	npnts = numpnts(list)
	
	for (icnt = 0; icnt < npnts; icnt += 1)
		if (StringMatch(oldName, list[icnt]) == 1)
			list[icnt] = GetPathName(newName, 0)
			return 1
		endif
	endfor
	
	return 0
	
End // NMFolderListChange

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListNum(folder)
	String folder
	
	Variable icnt, found, npnts
	String df = NMDF()
	
	String wName = df + "FolderList"
	
	if (WaveExists($wName) == 0)
		return -1
	endif
	
	if (strlen(folder) == 0)
		folder = StrVarOrDefault(df+"CurrentFolder", "")
	endif
	
	if (IsNMDataFolder(folder) == 0)
		return Nan
	endif
	
	Wave /T list = $wName
	
	folder = GetPathName(folder, 0)
	
	npnts = numpnts(list)
	
	for (icnt = 0; icnt < npnts; icnt += 1)
		if (StringMatch(folder, list[icnt]) == 1)
			return icnt
		endif
	endfor
	
	return Nan
	
End // NMFolderListNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderListName(folder)
	String folder // folder name ("") for current
	String prefix = "F"
	
	if (strlen(folder) == 0)
		folder = StrVarOrDefault(NMDF() + "CurrentFolder", "")
	endif
	
	Variable id = NMFolderListNum(folder)
	
	if (numtype(id) == 0)
		return prefix + num2str(id)
	else
		return ""
	endif

End // NMFolderListName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderPrefix(folder)
	String folder // folder name ("") for current
	
	return NMFolderListName(folder) + "_"

End // NMFolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMFolder(folder, type)
	String folder // full-path folder name
	String type // "NMData", "NMStim", "NMLog", ("") any
	
	Variable yes, s
	String ftype
	
	if (strlen(folder) == 0)
		folder = GetDataFolder(1)
	endif
	
	s = strlen(folder)
	
	folder =NMFolderPath(folder)
	
	if (DataFolderExists(folder) == 1)
	
		ftype = StrVarOrDefault(folder+"FileType", "No")
	
		if (StringMatch(type, ftype) == 1)
			yes = 1
		elseif ((strlen(type) == 0) && (StringMatch(ftype, "No") == 0))
			yes = 1
		endif
	
	endif
	
	return yes

End // IsNMFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMDataFolder(folder)
	String folder // full-path folder name
	
	return IsNMFolder(folder,"NMData")
	
End // IsNMDataFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SubStimName(df) // sub folder stim name
	String df // data folder or ("") for current

	return StringFromList(0, NMFolderList(df, "NMStim"))

End // SubStimName

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Folder utility functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S FolderNameCreate(file) // create a folder name based on a given file name
	String file // file name
	
	Variable icnt
	
	file = GetPathName(file, 0) // remove path if it exists
	file = FileExtCheck(file, ".*", 0) // remove extension if it exists
	
	if (numtype(str2num(file[0,0])) == 0)
		file = "nm_" + file // begin file name with "nm_" if name begins with number
	endif
	
	file = CheckFolderNameChar(file)
	
	return file

End // FolderNameCreate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FolderNameNext(folder) // return next unused folder name
	String folder
	String gname, rname = ""
	Variable fcnt
	
	if (strlen(folder) == 0)
		folder = StrVarOrDefault(NMDF()+"FolderPrefix", "nm") + "_folder"
	endif
	
	Variable seqnum = SeqNumFind(folder)
	
	Variable iSeqBgn = NumVarOrDefault("iSeqBgn", 0)
	Variable iSeqEnd = NumVarOrDefault("iSeqEnd", 0)

	for (fcnt = 0; fcnt <= 99; fcnt += 1)
	
		if (numtype(seqnum) == 0)
			gname = SeqNumSet(folder, iSeqBgn, iSeqEnd, (seqnum+fcnt))
		else
			gname = folder + num2str(fcnt)
		endif
		
		if (DataFolderExists(NMFolderPath(gname)) == 0)
			rname = gname
			break
		endif
		
	endfor

	KillVariables /Z iSeqBgn, iSeqEnd
	
	return rname
	
End // FolderNameNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckFolderName(df) // if folder exists, request new folder name
	String df
	
	Variable icnt
	
	String path = GetPathName(df, 1)
	String folder = GetPathName(df, 0)
	String lastname, savename = folder
	
	folder = CheckFolderNameChar(folder)
	
	do // test whether data folder already exists
	
		if (DataFolderExists(path+folder) == 1)
			
			lastname = folder
			folder = savename + "_" + num2str(icnt)
			Prompt folder, "Folder \"" + lastname + "\" already exists! Please enter a different folder name:"
			DoPrompt "Folder Name Conflict", folder
			
			if (V_flag == 1)
				return "" // cancel
			endif

		else
			break // name OK
		endif
		
	while (1)
	
	return path+folder

End // CheckFolderName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckFolderNameChar(name)
	String name
	
	Variable icnt, ascii
	
	for (icnt = 0; icnt < strlen(name); icnt += 1)
	
		ascii = char2num(name[icnt,icnt])
		
		if ((ascii < 48) || ((ascii > 57) && (ascii < 65)) || ((ascii > 90) && (ascii < 97)) || (ascii > 127))
			name[icnt,icnt] = "_" // replace with underline
		endif
		
	endfor
	
	name = ReplaceString("__", name, "_")
	name = ReplaceString("__", name, "_")
	name = ReplaceString("__", name, "_")
	
	icnt = strlen(name) - 1
	
	if (StringMatch(name[icnt, icnt], "_") == 1)
		name = name[0, icnt - 1]
	endif
	
	return name

End // CheckFolderNameChar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LastPathColon(fullpath, yes)
	String fullpath
	Variable yes // check path (0) has no trailing colon (1) has trailing colon
	
	Variable n = strlen(fullpath) - 1
	
	switch(yes)
	
		case 0:
			if (StringMatch(fullpath[n,n], ":") == 1)
				return fullpath[0,n-1]
			endif
			break
			
		case 1:
			if (StringMatch(fullpath[n,n], ":") == 0)
				return fullpath + ":"
			endif
			break
			
		default:
			return ""
			
	endswitch
	
	return fullpath

End // LastPathColon

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetPathName(fullpath, option)
	String fullpath // full-path name (i.e. "root:folder0")
	Variable option // (0) return string containing folder or variable name (i.e. "Folder0") (1) returns string containing path (i.e. "root:")
	
	Variable icnt
	
	fullpath = LastPathColon(fullpath, 0) // remove trailing colon if it exists
	
	//icnt = strsearch(fullpath,":",Inf,1)
	
	for (icnt = strlen(fullpath) - 2; icnt >= 0; icnt -= 1)  
		if (StringMatch(fullpath[icnt], ":") == 1) // found right-most colon within path name
			break
		endif
	endfor
	
	switch(option)
		case 0:
			if (icnt > 0)
				return fullpath[icnt+1, inf]
			else
				return fullpath
			endif
			break
		case 1:
			if (icnt > 0)
				return fullpath[0, icnt]
			else
				return ""
			endif
			break
	endswitch
	
	return ""

End // GetPathName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FolderObjectList(df, objType)
	String df // data folder path ("") for current
	Variable objType // (1) waves (2) variables (3) strings (4) data folders (5) numeric wave (6) text wave
	
	Variable ocnt, otype, add
	String objName, olist = ""
	
	switch(objType)
		case 1:
		case 2:
		case 3:
		case 4:
			otype = objType
			break
		case 5:
		case 6:
			otype = 1
			break
		default:
			return ""
	endswitch
	
	do
	
		add = 0
		objName = GetIndexedObjName(df, oType, ocnt)
		
		if (strlen(objName) == 0)
			break
		endif
		
		switch(objType)
			case 1:
			case 2:
			case 3:
			case 4:
				add = 1
				break
			case 5:
				if (WaveType($(df+objName)) > 0)
					add = 1
				endif
				break
			case 6:
				if (WaveType($(df+objName)) == 0)
					add = 1
				endif
				break
		endswitch
		
		if (add == 1)
			olist = AddListItem(objName, olist, ";", inf)
		endif
		
		ocnt += 1
		
	while(1)
	
	return olist

End // FolderObjectList

//****************************************************************
//****************************************************************
//****************************************************************

