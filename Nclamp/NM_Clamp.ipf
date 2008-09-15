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

End // Neuromatic menu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampPrefix(objName) // tab prefix identifier
	String objName

	return "CT0_" + objName
	
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

Function ClampTab(enable)
	Variable enable // (0) disable (1) enable

	if (enable == 1)
	
		CheckPackage("Stats", 0) // necessary for auto-stats
		CheckPackage("Spike", 0) // necessary for auto-spike
		CheckPackage("Clamp", 0) // create clamp global variables
		CheckPackage("Notes", 0) // create Notes folder
		
		//LogParentCheck()
		StimParentCheckDF()
		
		ClampConfigsUpdate() // set data paths, open stim files, test board config
		
		ChanControlsDisable(-1, "000000")
		
		ClampStats(StimStatsOn())
		ClampSpike(StimSpikeOn())
		
	else
	
		ClampStats(0)
		ClampSpike(0)
		
	endif
	
	ClampTabEnable(enable) // NM_ClampTab.ipf
	
	StimCurrentChanSet("", NMCurrentChan()) // update current channel

End // ClampTab

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

Function ClampExitHook()

	// nothing to do

End // ClampExitHook

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckClamp()
	
	Variable saveformat = 1 // NM binary
	
	String cdf = ClampDF()

	if (DataFolderExists(cdf) == 0)
		return -1
	endif
	
	if (FileBinType() == 1)
		saveformat = 2 // Igor binary
	endif
	
	CheckNMstr(cdf+"ClampErrorStr", "")				// error message
	CheckNMvar(cdf+"ClampError", 0)					// error number (0) no error (-1) error
	
	CheckNMvar(cdf+"BoardDriver", 0)					// main board driver number
	
	CheckNMvar(cdf+"LogDisplay", 1)					// log notes display flag
	CheckNMvar(cdf+"LogAutoSave", 1)					// auto save log notes flag
	
	//CheckNMstr(cdf+"TGainList", "")					// telegraph gain ADC channel list // DEPRECATED
	//CheckNMstr(cdf+"ClampInstrument", "")			// clamp instrument name // DEPRECATED
	
	// data folder variables
	
	CheckNMstr(cdf+"CurrentFolder", "")				// current data file
	
	SetNMstr(cdf+"FolderPrefix", ClampDateName())		// data file prefix name
	
	CheckNMstr(cdf+"ClampPath", "")					// external save data path
	CheckNMstr(cdf+"DataPrefix", "Record"	)			// default data prefix name
	CheckNMstr(cdf+"WavePrecision", "D"	)			// wave precision ("D") double ("S") single
	
	CheckNMvar(cdf+"DataFileCell", 0)					// data file cell number
	CheckNMvar(cdf+"DataFileSeq", 0)					// data file sequence number
	CheckNMvar(cdf+"SeqAutoZero", 1)					// auto zero seq number after cell increment
	
	CheckNMvar(cdf+"Backup", 20)					// time to back up NM (minutes)
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
	
	ClampBoardWavesCheckAll()						// board configuration waves
	
	return 0
	
End // CheckClamp

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigs()
	String fname = "Clamp"

	//NMConfigVar(fname, "TestTimers", 1, "Test acquisition timers (0) no (1) yes")
			
	NMConfigVar(fname, "LogDisplay", 1, "Clamp log display (0) none (1) notebook (2) table")
	NMConfigVar(fname, "LogAutoSave", 1, "Log folder auto save (0) no (1) yes")
	
	//NMConfigVar(fname, "PulseDisplay", 1, "Pulse Gen graph display (0) off (1) on")
	
	NMConfigVar(fname, "BoardDriver", 0, "Board driver number (NIDAQ only)")
	NMConfigStr(fname, "DataPrefix", "Record", "Data wave prefix name")
	NMConfigStr(fname, "WavePrecision", "D", "Data wave Precision (D) double (S) single")
	
	//NMConfigStr(fname, "FolderPrefix", "", "Folder name prefix")
	NMConfigStr(fname, "StimPath", "C:Jason:TestStims:", "Directory where stim protocols are saved")
	NMConfigStr(fname, "OpenStimList", "iv;", "List of stim files to open")
	
	NMConfigStr(fname, "ClampPath", "C:Jason:TestData:", "Directory where data is to be saved")
	
	NMConfigVar(fname, "SeqAutoZero", 1, "Auto zero seq num after cell increment (0) no (1) yes")
	
	NMConfigVar(fname, "Backup", 20, "backup time for current Igor experiment (minutes)")
	NMConfigVar(fname, "SaveFormat", 3, "Save data format (1) NM binary file (2) Igor binary file (3) both")
	NMConfigVar(fname, "SaveWhen", 2, "Save data when (0) never (1) after recording (2) while recording")
	NMConfigVar(fname, "SaveWithDialogue", 0, "Save with dialogue prompt? (0) no (1) yes")
	NMConfigVar(fname, "SaveInSubfolder", 1, "Save data in subfolders? (0) no (1) yes")
	NMConfigVar(fname, "AutoCloseFolder", 1, "Close previous data folder before creating new one? (0) no (1) yes")
	
	NMConfigVar(fname, "StatsBslnDsply", 1, "Display Stats baseline values? (0) no (1) yes")
	NMConfigVar(fname, "StatsTauDsply", 2, "Display Stats time constants? (0) no (1) yes, same window (2) yes, seperate window")
	
	//NMConfigStr(fname, "ClampInstrument", "", "Amplifier name (for telegraph functions)")
	
	//NMConfigStr(fname, "TGainList", "", "Telegraph gain list string (ADC tgain chan, ADC input chan to scale")
	
	NMConfigVar(fname, "TModeChan", Nan, "ADC input channel for telegraph mode")
	
	NMConfigVar(fname, "TempChan", Nan, "ADC input channel for temperature")
	NMConfigVar(fname, "TempSlope", 1, "Temp slope factor (100 degreesC/Volts)")
	NMConfigVar(fname, "TempOffset", 0, "Temp offset (degreesC)")
	
	ClampBoardConfigs()

End // ClampConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigsUpdate()

	Variable test
	String cdf = ClampDF()
	
	if (NumVarOrDefault(cdf+"ClampSetPreferences", 0) == 1)
		return 0 // already set
	endif

	String ClampPathStr = StrVarOrDefault(cdf+"ClampPath", "")
	String StimPathStr = StrVarOrDefault(cdf+"StimPath", "")
	String sList = StrVarOrDefault(cdf+"OpenStimList", "")
	
	ClampPathsCheck()
	
	if ((strlen(StimPathStr) > 0) && (strlen(sList) > 0))
		StimOpenList(StimPathStr, sList)
	endif
	
	ClampConfigBoard()
	
	test = ClampAcquireManager(StrVarOrDefault(cdf+"AcqBoard","Demo"), -2, 0) // test configuration
	
	if (test < 0)
		SetNMstr(cdf+"AcqBoard","Demo")
	endif
	
	ClampProgressInit() // make sure progress display is OK
	
	SetNMvar(cdf+"ClampSetPreferences", 1)
	
	ClampDataFolderName(0)
	
	SetIgorHook IgorQuitHook = ClampExitHook // runs this fxn before quitting Igor

End // ClampConfigsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampConfigBoard()

	String blist = "", board = "Demo", cdf = ClampDF()
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
	Execute /Z "NidaqBoardList()"
	
	if (V_flag == 0)
		blist = StrVarOrDefault(cdf+"BoardList", "")
		board = "NIDAQ"
		driver = ClampBoardDriverPrompt()
	endif
	
	if (strlen(blist) == 0)
	
		Execute /Z "ITC16stopacq"
		
		if (V_flag == 0)
			driver = 0
			blist = "ITC16"
			board = "ITC16"
		endif
		
	endif
	
	if (strlen(blist) == 0)
		
		Execute /Z "ITC18stopacq"

		if (V_flag == 0)
			driver = 0
			blist = "ITC18"
			board = "ITC18"
		endif
	
	endif
	
	if (strlen(blist) == 0)
		blist = "None"
	endif
		
	SetNMstr(cdf+"BoardList", blist)
	SetNMstr(cdf+"AcqBoard", board)
	SetNMstr(cdf+"BoardSelect", board)
	SetNMvar(cdf+"BoardDriver", driver)
	
	return blist

End // ClampConfigBoard

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPathsCheck()

	String cdf = ClampDF()
	String ClampPathStr = StrVarOrDefault(cdf+"ClampPath", "")
	String StimPathStr = StrVarOrDefault(cdf+"StimPath", "")
	
	PathInfo /S ClampSaveDataPath
	
	if ((strlen(S_path) == 0) && (strlen(ClampPathStr) > 0))
	
		NewPath /Z/O/Q ClampSaveDataPath ClampPathStr
		
		if (V_flag != 0)
			DoAlert 0, "Failed to create external path to: " + ClampPathStr
			SetNMstr(cdf+"ClampPath", "")
		endif
		
	endif
	
	PathInfo ClampStimPath
	
	if ((strlen(S_path) == 0) && (strlen(StimPathStr) > 0))
	
		NewPath /Z/O/Q ClampStimPath StimPathStr
		
		if (V_flag != 0)
			DoAlert 0, "Failed to create external path to: " + StimPathStr
			SetNMstr(cdf+"StimPath", "")
		endif
		
	endif

End // ClampPathsCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampPathSet(pathStr)
	String pathStr
	
	if (strlen(pathStr) == 0)
		pathStr = "c:x"
	endif
			
	NewPath /Q/O ClampSaveDataPath pathStr
	
	if (V_flag == 0)
		PathInfo ClampSaveDataPath
		pathStr = S_path
		SetNMstr(ClampDF()+"ClampPath", S_path)
	else
		ClampError("Failed to create external path to: " + pathStr)
		pathStr = ""
	endif
	
	return pathStr
	
End // ClampPathSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampFolderPrefix()

	return StrVarOrDefault(ClampDF()+"FolderPrefix", ClampDateName())

End // ClampFolderPrefix

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

Function /S ClampFileNamePrefixSet(prefix)
	String prefix
	
	if (strlen(prefix) == 0)
		prefix = ClampDateName()
	endif
	
	SetNMStr(ClampDF()+"FolderPrefix", prefix)
	
	return prefix
	
End // ClampFileNamePrefixSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampError(errorStr)
	String errorStr
	String cdf = ClampDF()
	
	if (strlen(errorStr) == 0)
		SetNMstr(cdf+"ClampErrorStr", "")
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

Function ClampProgressInit() // use ProgWin XOP display to allow cancel of acquisition
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

Function ClampFolderAutoCloseSet(on)
	Variable on // (0) off (1) on
	
	SetNMVar(ClampDF()+"AutoCloseFolder", on)
	
End // ClampFolderAutoCloseSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampLogAutoSaveSet(on)
	Variable on // (0) off (1) on
	
	SetNMvar(ClampDF()+"LogAutoSave", on)

End // ClampLogAutoSaveSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampLogDisplaySet(selectStr)
	String selectStr // "None", "Both", "Text" or "Table"
	
	Variable nb, table, select
	
	String cdf = ClampDF(), ldf = LogDF()
	
	String nbName = LogNoteBookName(ldf)
	String tName = LogTableName(ldf)
	
	strswitch(selectStr)
	
		case "None":
			break
			
		case "Text":
			nb = 1
			select = 1
			break
		
		case "Table":
			table = 1
			select = 2
			break
			
		case "Both":
			nb = 1
			table = 1
			select = 3
			break
			
		default:
			return -1
			
	endswitch
	
	SetNMvar(cdf+"LogDisplay", select)
	
	if (nb == 0)
		DoWindow /K $nbName
	elseif (WinType(nbName) == 5)
		DoWindow /F $nbName
	else
		LogNoteBook(ldf)
	endif
	
	if (table == 0)
		DoWindow /K $tName
	elseif (WinType(tName) == 2)
		DoWindow /F $tName
	else
		LogTable(ldf)
	endif
	
	return select
	
End // ClampLogDisplaySet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStimPathAsk()

	String cdf = ClampDF()
	
	NewPath /Q/O/M="Stim File Directory" ClampStimPath
	
	if (V_flag == 0)
	
		PathInfo ClampStimPath
		
		if (strlen(S_path) > 0)
			SetNMstr(cdf+"StimPath", S_path)
			DoAlert 0, "Don't forget to save changes by saving your Configurations (NeuroMatic > Configs > Save)."
		endif
		
	endif

End // ClampStimPathSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStimListAsk()

	String cdf = ClampDF()
	String openList = StrVarOrDefault(cdf+"OpenStimList", "")
	
	//if (strlen(openList) == 0)
		openList = StimList()
	//endif
	
	Prompt openList, "list of stim files to open when starting Nclamp:"
	DoPrompt "Set Stim List", openList
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMstr(cdf+"OpenStimList", openList)
	
	DoAlert 0, "Don't forget to save changes by saving your Configurations (NeuroMatic > Configs > Save)."

End // ClampStimListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveAsk()
	String cdf = ClampDF()
	
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 1) + 1
	Variable savePrompt = NumVarOrDefault(cdf+"SaveWithDialogue", 1) + 1
	Variable saveFormat = NumVarOrDefault(cdf+"SaveFormat", 1)
	
	Variable bintype = FileBinType()
	
	Prompt saveWhen, "save data when?", popup "never;after recording;while recording;"
	Prompt savePrompt, "save with dialogue prompt?", popup "no;yes;"
	Prompt saveFormat, "save as file format:", popup "NeuroMatic Binary;Igor Binary;Both;"
	
	DoPrompt "Save Data Configuration", saveWhen, savePrompt, saveFormat
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	if ((saveWhen == 3) && (saveFormat == 2))
		saveFormat = 3 // save both if save while recording
	endif
	
	if ((saveWhen == 2) && (bintype == 1) && (saveFormat != 2))
		saveFormat = 2
		DoPrompt "Please Check File Format", saveFormat
		if (V_flag == 1)
			return -1 // cancel
		endif
	endif

	if (saveWhen == 3)
		DoAlert 0, "Warning: depending on the speed of your computer, Save While Recording option may slow acquisition. Please use with caution."
	endif
	
	SetNMVar(cdf+"SaveWhen", saveWhen - 1)
	SetNMVar(cdf+"SaveWithDialogue", savePrompt - 1)
	SetNMVar(cdf+"SaveFormat", saveFormat)

End // ClampSaveAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAutoBackupNM()
	
	String fname, cdf = ClampDF()
	Variable minutes = DateTime / 60
	Variable backup = NumVarOrDefault(cdf+"BackUp", 20) // minutes
	Variable lastbackup = NumVarOrDefault(cdf+"LastBackUp", Nan) // minutes
	String path = StrVarOrDefault(cdf+"ClampPath", "")
	String folderPrefix = ClampFolderPrefix()
	
	ClampPathsCheck()
	
	PathInfo ClampSaveDataPath
	
	if ((strlen(S_path) == 0) || (strlen(folderPrefix) == 0))
		return 0 // nowhere to save
	endif
	
	if ((numtype(backup) > 0) || (backup <= 0))
		return 0
	endif
	
	if ((numtype(lastbackup) > 0) || (minutes >= lastbackup + backup))
		fname = folderPrefix + "_backup.pxp"
		SaveExperiment /P=ClampSaveDataPath as fname
		Print "Backed up the current experiment in file " + S_path + fname
		SetNMvar(cdf+"LastBackUp", minutes)
	endif

End // ClampAutoBackupNM

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
	
	String cdf = ClampDF()
	String CurrentStim = StimCurrent()
	String sList = StimList()
	
	if (strlen(CurrentStim+sList) == 0) // nothing is open
	
		CurrentStim = "Stim0"
		StimNew(CurrentStim) // begin with blank stim
		StimCurrentSet(CurrentStim)
		
	elseif (WhichListItem(UpperStr(CurrentStim), UpperStr(sList)) == -1)
	
		StimCurrentSet(StringFromList(0, sList))
		
	endif

End // StimCurrentCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimCurrentSet(fname) // set current stim
	String fname // stimulus name
	
	Variable update1, update2, update3
	String sdf, dp = StimParent(), cdf = ClampDF()
	
	Variable lastMode = NumVarOrDefault("CT_RecordMode", 0)
	
	if (strlen(fname) == 0)
		SetNMstr(cdf+"CurrentStim", "")
		return ""
	endif
	
	if (stringmatch(fname, StimCurrent()) == 1)
		//return 0 // already current stim
	endif
	
	if (DataFolderExists(dp+fname) == 0)
		return ""
	endif
	
	if (IsStimFolder(dp, fname) == 0)
		ClampError("\"" + fname + "\" is not a NeuroMatic stimulus folder.")
		return ""
	endif
	
	ClampSpikeDisplaySavePosition()
	ClampStatsDisplaySavePosition()
	
	sdf = dp + fname + ":"
	
	SetNMstr(cdf+"CurrentStim", fname)
	
	if (StimChainOn("") == 1)
		StimChainEdit("")
		//ClampTabUpdate()
		return fname
	endif
	
	if (lastmode == 0) // empty folder
		SetNMvar("CurrentChan", NumVarOrDefault(sdf+"CurrentChan", 0))
		SetNMvar("NumChannels", StimBoardNumADCchan(sdf))
	endif
	
	StimBoardConfigsOld2NewAll("")
	StimBoardConfigsUpdateAll("")
	
	ClampStatsRetrieveFromStim() // get Stats from new stim
	ClampStats(StimStatsOn())
	ClampGraphsCopy(-1, -1) // get Chan display variables
	ChanGraphsReset()
	ClampStatsDisplaySetPosition("amp")
	ClampStatsDisplaySetPosition("tau")
	ClampSpikeDisplaySetPosition()
	
	//UpdateNMPanel(0)
	//ClampTabUpdate()
	//ChanGraphsUpdate()
	
	StatsDisplayClear()
	
	return fname
	
End // StimCurrentSet

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

	String stim = StimCurrent(), sdf = StimDF(), gdf = GetDataFolder(1)
	
	if (direction == 1)
		if (StringMatch(stim, StrVarOrDefault(gdf+"CT_Stim", "")) == 1)
			ChanFolderCopy(-1, gdf, sdf, 1)
		endif
	elseif (direction == -1)
		ChanFolderCopy(-1, sdf, gdf, 0)
		SetNMstr(gdf+"CT_Stim", stim)
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
//
//
//	Acquisition board configuration functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampBoardName(boardNum)
	Variable boardNum // (0) driver (> 0) for name from BoardList
	
	String cdf = ClampDF()
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
	String bList = StrVarOrDefault(cdf+"BoardList", "")
	
	if (boardNum == 0)
		boardNum = driver
	endif
	
	if (ItemsInList(bList) == 1)
	
		return StringFromList(0, bList)
		
	elseif (ItemsInList(bList) > 1)
	
		if (boardNum <= 0)
			return StringFromList(0, bList)
		elseif ((boardNum > 0) && (boardNum <= ItemsInList(bList)))
			return StringFromList(boardNum-1, bList)
		endif
		
	endif
	
	return ""

End // ClampBoardName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardSet(select)
	String select
	
	Variable driver
	String cdf = ClampDF()
	String blist = StrVarOrDefault(cdf+"BoardList", "")
	
	strswitch(select)
	
		case "ITC16":
		case "ITC18":
			SetNMvar(cdf+"BoardDriver", 0)
			break
			
		case "NIDAQ":
			driver = ClampBoardDriverPrompt()
			SetNMvar(cdf+"BoardDriver", driver)
			break
			
		default:
			select = "Demo"
			
	endswitch
	
	ClampAcquireManager(select, -2, 0) // test interface board
	
	if (NumVarOrDefault(cdf+"ClampError", -1) == 0)
		SetNMStr(cdf+"BoardSelect", select)
	endif
	
End // ClampBoardSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardDriverPrompt()

	String cdf = ClampDF()
	String blist = StrVarOrDefault(cdf + "BoardList", "")
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)

	if (ItemsInList(blist) > 1)
		
		Prompt driver, "please select your default board:", popup blist
		DoPrompt "NIDAQ board configuration", driver
		
		if (V_flag == 1)
			driver = 1
		endif
			
	endif
	
	return driver

End // ClampBoardDriverPrompt

//****************************************************************
//****************************************************************
//****************************************************************











