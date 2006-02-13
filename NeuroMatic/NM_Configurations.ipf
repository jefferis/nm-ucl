#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Configuration Functions
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last Modified 08 Nov 2005
//
//	New Configurations
//
//	Unlike old Preferences.ipf, pref variables cannot be set here
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigDF(fname) // return Configurations full-path folder name
	String fname // config folder name (i.e. "NeuroMatic", "Main", "Stats")
	
	return PackDF("Configurations:" + fname)
	
End // ConfigDF

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfig(fName, copyConfigs) // wrapper for old NMPrefs function
	String fName // package folder name
	Variable copyConfigs // (-1) copy configs to folder (0) no copy (1) copy folder to configs
	
	CheckNMConfig(fName) // create new config folder and variables
	
	if (copyConfigs != 0)
		NMConfigCopy(fname, copyConfigs)
	endif
	
End // NMConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMConfig(fname)
	String fname // config folder name ("NeuroMatic", "Chan", "Stats"...)
	
	CheckNMConfigDF(fname) // check config folder exists
	
	strswitch(fname)
	
		default:
			return -1
	
		case "NeuroMatic": // Neuromatic Main Configurations
		
			NMConfigVar(fname, "AutoStart", 1, "Auto-start NeuroMatic (0) no (1) yes")
			NMConfigVar(fname, "AutoPlot", 1, "Auto plot data upon loading file (0) no (1) yes")
			NMConfigVar(fname, "CountFrom", 0, "First number to count from (0 or 1)")
			NMConfigVar(fname, "NameFormat", 1, "Wave name format (0) short (1) long")
			NMConfigVar(fname, "ProgFlag", 1, "Progress display (0) off (1) WinProg XOP of Kevin Boyce")
			NMConfigVar(fname, "OverWrite", 1, "Over-write (0) off (1) on")
			NMConfigVar(fname, "WriteHistory", 1, "Analysis history (0) off (1) Igor History (2) notebook (3) both")
			NMConfigVar(fname, "CmdHistory", 1, "Command history (0) off (1) Igor History (2) notebook (3) both")
			
			NMConfigVar(fname, "GroupsOn", 0, "Groups (0) off (1) on")
			NMConfigVar(fname, "GroupsAutoClear", 1, "Groups auto clear (0) off (1) on")
			
			NMConfigVar(fname, "SetsAutoAdvance", 0, "Auto-advance wave number (0) off (1) on")
			NMConfigVar(fname, "SetsAutoClear", 1, "Sets auto clear (0) off (1) on")
			
			//NMConfigVar(fname, "xPixels", 1000, "Screen x-pixels") // auto-detected
			//NMConfigVar(fname, "yPixels", 800, "Screen y-pixels") // auto-detected
			//NMConfigStr(fname,"Computer", "mac", "Computer type (mac or pc)") // auto-detected
			
			NMConfigVar(fname, "ChangePrefixPrompt", 1, "Prefix select num channel prompt (0) off (1) on")
			
			NMConfigStr(fname, "PrefixList", "Record;Avg_;ST_;", "List of wave prefix names")
			NMConfigStr(fname, "NMTabList", "Main;", "List of NeuroMatic tabs")
			
			NMConfigStr(fname, "OpenDataPath", "", "Open data file path (i.e. C:Jason:TestData:)")
			NMConfigStr(fname, "SaveDataPath", "", "Save data file path (i.e. C:Jason:TestData:)")
		
			break
			
		case "Main": // Main Tab Configurations
		
			NMConfigStr(fname, "PlotColor", "rainbow", "Plot wave color (black, red, blue, yellow, green, purple, rainbow)")
		
			NMConfigVar(fname, "Bsln_Method", 1, "(1) subtract wave's individual mean (2) subtract mean of all waves")
			NMConfigVar(fname, "Bsln_Bgn", 0, "Baseline window begin (ms)")
			NMConfigVar(fname, "Bsln_End", 10, "Baseline window end (ms)")
			
			NMConfigVar(fname, "AvgMode", 2, "(1) mean (2) mean + stdv (3) mean + var (4) mean + sem")
			NMConfigVar(fname, "AvgDisplay", 1, "display data waves with results? (0) no (1) yes")
			NMConfigVar(fname, "AvgChanFlag", 0, "use channel smooth and F(t)? (0) no (1) yes")
			NMConfigVar(fname, "AvgAllGrps", 0, "average all groups? (0) no (1) yes")
			NMConfigVar(fname, "AvgGrpDisplay", 1, "display groups in same plot? (0) no (1) yes")
			
			NMConfigVar(fname, "SmoothNum", 1, "Number of smoothing points/operations")
			NMConfigStr(fname, "SmoothAlg", "binomial", "Smoothing algorithm (binomial, boxcar, polynomial)")
			
			NMConfigVar(fname, "CopySelect", 1, "Select copied waves as current? (0) no (1) yes")
			
			NMConfigStr(fname, "RenameFind", "", "Wave rename find string")
			NMConfigStr(fname, "RenameReplace", "", "Wave rename replace string")
			
			NMConfigVar(fname, "RenumFrom", 0, "Renumber waves from")
			
			NMConfigVar(fname, "DecimateN", 4, "Decimate number of points")
			
			NMConfigVar(fname, "XAlignPosTime", 1, "During alignment, allow only positive time values? (0) no (1) yes")
			NMConfigVar(fname, "XAlignInterp", 0, "Make alignments permanent by interpolation? (0) no (1) yes")
			
			NMConfigStr(fname, "ScaleByNumAlg", "*", "Scale by number algorithm (*, /, +, -)")
			NMConfigVar(fname, "ScaleByNumVal", 1, "Scale by number value")
			
			NMConfigVar(fname, "ScaleByWaveMthd", 0, "(0) none (1) scale by wave of values (2) scale by wave")
			NMConfigStr(fname, "ScaleByWaveAlg", "*", "Scale by wave algorithm (*, /, +, -)")
			NMConfigVar(fname, "ScaleByWaveVal", 1, "Scale by wave value")
			
			NMConfigStr(fname, "NormFxn", "*", "Normalize by measurement (min, max, avg)")
			NMConfigVar(fname, "NormTbgn", 0, "Normalize measure time begin")
			//NMConfigVar(fname, "NormTend", 0, "Normalize measure time end")
			
			NMConfigStr(fname, "IVFxnX", "Avg", "IV x-data algorithm (min, max, avg, slope)")
			NMConfigStr(fname, "IVFxnY", "Avg", "IV y-data algorithm (min, max, avg, slope)")
			NMConfigVar(fname, "IVChX", 1, "IV x-data channel select")
			NMConfigVar(fname, "IVChY", 0, "IV y-data channel select")
			NMConfigVar(fname, "IVTbgnX", 0, "IV x-data time begin")
			//NMConfigVar(fname, "IVTendX", 10, "IV x-data time end")
			NMConfigVar(fname, "IVTbgnY", 0, "IV y-data time begin")
			//NMConfigVar(fname, "IVTendY", 10, "IV y-data time end")
			
			break
			
		case "Chan": // Channel Graph Configurations
			
			NMConfigVar(fname, "GridFlag", 1, "Graph grid display (0) off (1) on")
			NMConfigVar(fname, "Overlay", 0, "Number of waves to overlay (0) none")
			NMConfigVar(fname, "DTflag", 0, "F(t) (0) none (1) d/dt (2) dd/dt*dt (3) integral (4) normalize")
			NMConfigVar(fname, "SmthNum", 0, "Wave smooth number (0) none")
			
			NMConfigStr(fname, "SmthAlg", "", "Smooth algorithm (binomial, boxcar)")
			
			NMConfigVar(fname, "AutoScale", 1, "Auto scale (0) off (1) on")
			NMConfigVar(fname, "Xmin", 0, "X-min scale value")
			NMConfigVar(fname, "Xmax", 1, "X-max scale value")
			NMConfigVar(fname, "Ymin", 0, "Y-min scale value")
			NMConfigVar(fname, "Ymax", 1, "Y-max scale value")
			
			NMConfigStr(fname, "TraceColor", "0,0,0", "Trace rgb color")
			NMConfigStr(fname, "OverlayColor", "34816,34816,34816", "Overlay trace rgb color")
			
			break
			
		case "Import": // Import File Configurations
		
			NMConfigVar(fname, "ImportPrompt", 1, "Import prompt (0) off (1) on")
			NMConfigStr(fname, "xLabel", "", "X-axis label")
		
			NMConfigTWave(fname, "yLabel", 10, "", "Channel y-axis label")
			NMConfigWave(fname, "MyScaleFactors", 10, 1, "Post-import channel scale factor")
		
			break
			
		case "Stats": // Stats Tab Configurations
		
			Variable win, numwin = 10
			
			NMConfigVar(fname, "DragOn", 1, "Display drag waves (0) no (1) yes")
			NMConfigVar(fname, "TablesOn", 1, "Display Stats1 results in tables? (0) no (1) yes")
			NMConfigVar(fname, "AllWinOn", 1, "Compute all Stats windows (0) no (1) yes")
			NMConfigVar(fname, "AutoStats2", 1, "Auto select Stats2 for All Waves (0) no (1) yes")
			
			NMConfigVar(fname, "WavSelectOn", 0, "Stats2 wave select filter (0) off (1) on")
			NMConfigVar(fname, "AutoPlot", 1, "Stats2 auto plot (0) off (1) on")
			
			NMConfigStr(fname, "AmpColor", "65535,0,0", "Amp display rgb color")
			NMConfigStr(fname, "BaseColor", "0,39168,0", "Baseline display rgb color")
			NMConfigStr(fname, "RiseColor", "0,0,65535", "Rise/decay display rgb color")
			
			NMConfigTWave(fname, "AmpSlct", numwin, "Off", "Measurement")
			NMConfigWave(fname, "AmpB", numwin, 0, "Window begin time (ms)")
			NMConfigWave(fname, "AmpE", numwin, 0, "Window end time (ms)")
			
			NMConfigWave(fname, "Bflag", numwin, 0, "Compute baseline (0) no (1) yes")
			NMConfigTWave(fname, "BslnSlct", numwin, "Avg", "Baseline measurement")
			NMConfigWave(fname, "BslnB", numwin, 0, "Baseline begin time (ms)")
			NMConfigWave(fname, "BslnE", numwin, 0, "Baseline end time (ms)")
			NMConfigWave(fname, "BslnSub", numwin, 0, "Baseline auto subtract (0) no (1) yes")
			NMConfigWave(fname, "BslnRflct", numwin, Nan, "Baseline reflected window (0) off (1) on")
			
			NMConfigWave(fname, "Rflag", numwin, 0, "Compute rise-time (0) no (1) yes")
			NMConfigWave(fname, "RiseBP", numwin, 10, "Rise-time begin %")
			NMConfigWave(fname, "RiseEP", numwin, 90, "Rise-time end %")
			
			NMConfigWave(fname, "Dflag", numwin, 0, "Compute decay-time (0) no (1) yes")
			NMConfigWave(fname, "DcayP", numwin, 37, "Decay %")
			
			NMConfigWave(fname, "dtFlag", numwin, 0, "F(t) (0) none (1) d/dt (2) dd/dt*dt (3) integral")
			NMConfigWave(fname, "Dsply", numwin, 2, "Display tags (0) off (1) no text (2) win + value (3) win (4) value")
			
			NMConfigWave(fname, "SmthNum", numwin, 0, "Smooth number")
			NMConfigTWave(fname, "SmthAlg", numwin, "binomial", "Smooth algorithm")
			
			NMConfigTWave(fname, "OffsetW", numwin, "", "Offset wave name (/g for group num, /w for wave num)")
			
			break
			
		case "Spike": // Spike Tab Configurations
			
			NMConfigVar(fname, "Thresh", 20, "Spike threshold trigger level")
			NMConfigVar(fname, "WinB", 0, "Search begin time (ms)")
			NMConfigVar(fname, "WinE", 10, "Search end time (ms)")
			
			break
			
		case "Event": // Event Tab Configurations
		
			NMConfigVar(fname, "Thrshld", 5, "Threshold or level value")
			NMConfigVar(fname, "SearchBgn", 0, "Seach begin time (ms)")
			NMConfigVar(fname, "SearchEnd", 100, "Search end time (ms)")
			
			NMConfigVar(fname, "BaseFlag", 1, "Compute baseline (0) no (yes) 1")
			NMConfigVar(fname, "BaseWin", 2, "Baseline avg window (ms)")
			NMConfigVar(fname, "BaseDT", 2, "Mid-base to threshold crossing (ms)")
			
			NMConfigVar(fname, "OnsetFlag", 1, "Compute onset (0) no (1) yes")
			NMConfigVar(fname, "OnsetWin", 2, "Onset search limit (ms)")
			NMConfigVar(fname, "OnsetAvg", 10, "Avg window (ms)")
			NMConfigVar(fname, "OnsetNstdv", 1, "Num stdv's above avg")
			
			NMConfigVar(fname, "PeakFlag", 1, "Compute peak (0) no (1) yes")
			NMConfigVar(fname, "PeakWin", 10, "Peak search limit (ms)")
			NMConfigVar(fname, "PeakAvg", 10, "Avg window (ms)")
			NMConfigVar(fname, "PeakNstdv", 1, "Num stdv's above avg")
			
			NMConfigVar(fname, "DsplyWin", 50, "Channel display window size (ms)")
			
			break
			
		case "MyTab":
			
			NMConfigVar(fname, "MyVar", 44, "This is my variable")
			
			break
			
		case "Clamp": // Clamp Tab Configurations
			
			NMConfigVar(fname, "TestTimers", 1, "Test acquisition timers (0) no (1) yes")
			
			NMConfigVar(fname, "LogDisplay", 1, "Clamp log display (0) none (1) notebook (2) table")
			NMConfigVar(fname, "LogAutoSave", 1, "Log folder auto save (0) no (1) yes")
			
			NMConfigVar(fname, "PulseDisplay", 1, "Pulse Gen graph display (0) off (1) on")
			
			NMConfigVar(fname, "BoardDriver", 0, "Board driver number (NIDAQ only)")
			NMConfigStr(fname, "AcqBoard", "Demo", "Acquisition board (NIDAQ, ITC18, ITC16, Demo)")
			NMConfigStr(fname, "DataPrefix", "Record", "Data wave prefix name")
			
			NMConfigStr(fname, "StimPath", "C:Jason:TestStims:", "Directory where stim protocols are saved")
			NMConfigStr(fname, "OpenStimList", "iv;", "List of stim files to open")
			
			NMConfigStr(fname, "ClampPath", "C:Jason:TestData:", "Directory where data is to be saved")
			
			NMConfigVar(fname, "SeqAutoZero", 1, "Auto zero seq num after cell increment (0) no (1) yes")
			
			NMConfigVar(fname, "SaveFormat", 3, "Save data format (1) NM binary file (2) Igor binary file (3) both")
			NMConfigVar(fname, "SaveWhen", 2, "Save data when (0) never (1) after recording (2) while recording")
			NMConfigVar(fname, "SaveWithDialogue", 0, "Save with dialogue prompt? (0) no (1) yes")
			NMConfigVar(fname, "SaveInSubfolder", 1, "Save data in subfolders? (0) no (1) yes")
			NMConfigVar(fname, "AutoCloseFolder", 1, "Close previous data folder before creating new one? (0) no (1) yes")
			
			NMConfigVar(fname, "StatsBslnDsply", 1, "Display Stats baseline values? (0) no (1) yes")
			NMConfigVar(fname, "StatsTauDsply", 2, "Display Stats time constants? (0) no (1) yes, same window (2) yes, seperate window")
			
			NMConfigStr(fname, "ClampInstrument", "", "Amplifier name (for telegraph functions)")
			
			NMConfigStr(fname, "TGainList", "", "Telegraph gain list string (ADC tgain chan, ADC input chan to scale")
			
			NMConfigVar(fname, "TModeChan", Nan, "ADC input channel for telegraph mode")
			
			NMConfigVar(fname, "TempChan", Nan, "ADC input channel for temperature")
			NMConfigVar(fname, "TempSlope", 1, "Temp slope factor (100 degreesC/Volts)")
			NMConfigVar(fname, "TempOffset", 0, "Temp offset (degreesC)")
			
			break
			
		case "Notes": // Clamp Notebook Variables (add as many as you wish)
			
			//
			// Header Notes: use name prefix "H_"
			// File Notes: use name prefix "F_"
			// Create your own by copying and pasting
			//
			
			// Header Strings:
			
			NMConfigStr(fname, "H_Name", "Jason Rothman", "Your name")
			NMConfigStr(fname, "H_Lab", "Silver Lab, UCL Physiology", "Your lab/address")
			NMConfigStr(fname, "H_Title", "LTP", "Experiment title")
				
			// Header Variables:
			
			//NMConfigVar(fname, "H_Age", Nan, "Age")
			
			// File Variables:
			
			NMConfigVar(fname, "F_Temp", Nan, "Temperature")
			NMConfigVar(fname, "F_Ra", Nan, "Access resistance")
			NMConfigVar(fname, "F_Cm", Nan, "Cell capacitance")
			
			// File Strings:
			
			//NMConfigStr(fname, "F_Drug", "", "Experimental drugs")
		
			break
			
		default:
		
			return -1
				
	endswitch
	
	return 0
	
End // CheckNMConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMConfigDF(fname)
	String fname // config folder name
	
	String df = ConfigDF("") // main config folder
	String sub =df + fname + ":" // sub-folder to check
	
	Variable makeDF
	
	CheckPackDF("Configurations")
	makeDF = CheckPackDF("Configurations:"+fname)
	
	SetNMstr(df+"FileType", "NMConfig")
	SetNMstr(sub+"FileType", "NMConfig")
	
	return makeDF // (0) already made (1) yes, made
	
End // CheckNMConfigDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConfigList()

	String flist = FolderObjectList(ConfigDF(""), 4)
	
	flist = RemoveFromList("NeuroMatic", flist)
	flist = AddListItem("NeuroMatic", flist, ";", 0)

	return flist
	
End // NMConfigList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigCall(select)
	String select

	strswitch(select)
	
		case "Edit":
			return NMConfigEditCall("")
			
		case "Update":
			return NMConfigKillCall("")
		
		case "Open":
			return NMConfigOpenCall()
		
		case "Save":
			return NMReturnStr2Num(NMConfigSaveCall(""))
			
		case "Kill":
			return NMConfigKillCall("")
	
	endswitch

End // NMConfigCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigCopy(flist, direction) // set configurations
	String flist // config folder name list or "All"
	Variable direction // (-1) config to package folder (1) package folder to config
	
	Variable icnt, fcnt
	String fname, objName, cdf, df, objList
	
	if (StringMatch(flist, "All") == 1)
		flist = NMConfigList()
	endif
	
	for (fcnt = 0; fcnt < ItemsInList(flist); fcnt += 1)
	
		fname = StringFromList(fcnt, flist)
		
		cdf = ConfigDF(fname) // config data folder
		df = PackDF(fname) // package data folder
		
		if (DataFolderExists(cdf) == 0)
			continue
		endif
		
		if (direction == -1)
			CheckPackDF(fname)
		endif
		
		objList = NMConfigVarList(fname, 2) // numbers
		
		for (icnt = 0; icnt < ItemsInList(objList); icnt += 1)
		
			objName = StringFromList(icnt, objList)
			
			if ((direction == 1) && (exists(df+objName) == 2))
				SetNMvar(cdf+objName, NumVarOrDefault(df+objName, Nan))
			elseif (direction == -1)
				SetNMvar(df+objName, NumVarOrDefault(cdf+objName, Nan))
			endif
			
		endfor
		
		objList = NMConfigVarList(fname, 3) // strings
		
		for (icnt = 0; icnt < ItemsInList(objList); icnt += 1)
		
			objName = StringFromList(icnt, objList)
			
			if ((direction == 1) && (exists(df+objName) == 2))
				SetNMstr(cdf+objName, StrVarOrDefault(df+objName, ""))
			elseif (direction == -1)
				SetNMstr(df+objName, StrVarOrDefault(cdf+objName, ""))
			endif
			
		endfor
		
		objList = NMConfigVarList(fname, 5) // numeric waves
		
		for (icnt = 0; icnt < ItemsInList(objList); icnt += 1)
		
			objName = StringFromList(icnt, objList)
			
			if ((direction == 1) && (WaveExists($(df+objName)) == 1))
				Duplicate /O $(df+objName), $(cdf+objName)
			elseif (direction == -1)
				Duplicate /O $(cdf+objName), $(df+objName)
			endif
			
		endfor
		
		objList = NMConfigVarList(fname, 6) // text waves
		
		for (icnt = 0; icnt < ItemsInList(objList); icnt += 1)
		
			objName = StringFromList(icnt, objList)
			
			if ((direction == 1) && (WaveExists($(df+objName)) == 1))
				Duplicate /O $(df+objName), $(cdf+objName)
			elseif (direction == -1)
				Duplicate /O $(cdf+objName), $(df+objName)
			endif
			
		endfor
	
	endfor
	
	if (direction == -1)
		UpdateNM(0)
	endif
	
	return 0

End // NMConfigCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConfigSaveCall(fname)
	String fname // config folder name

	String flist = NMConfigList()
	
	if ((strlen(fname) == 0) || (FindListItem(fname, flist) < 0))
	
		fname = "All"
	
		if (ItemsInList(flist) == 0)
			DoAlert 0, "No Configurations to save."
			return ""
		endif
		
		if (ItemsInList(flist) > 1)
			flist += "All;"
		endif
	
		Prompt fname, "choose configuration to save:", popup flist
		DoPrompt "Save Configuration", fname
		
		if (V_flag == 1)
			return "" // cancel
		endif
	
	endif
	
	NMCmdHistory("NMConfigSave", NMCmdStr(fname, ""))
	
	return NMConfigSave(fname)

End // NMConfigSaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConfigSave(fname) // save config folder
	String fname // config folder fname, or "All"
	
	if (StringMatch(fname, "All") == 1)
		return NMConfigSaveAll()
	endif

	String folder, tdf, df = ConfigDF("")
	
	String file = "NMConfig" + fname

	if (StringMatch(StrVarOrDefault(df+"FileType", ""), "NMConfig") == 0)
		DoAlert 0, "NMConfigSave Error: folder is not a NM configuration file."
		return ""
	endif
	
	NMConfigCopy(fname, 1) // get current configuration values
	
	tdf = "root:" + file + ":" // temp folder
	
	if (DataFolderExists(tdf) == 1)
		KillDataFolder $tdf // kill temp folder if already exists
	endif
	
	NewDataFolder $LastPathColon(tdf, 0)
	
	SetNMstr(tdf+"FileType", "NMConfig")
	
	DuplicateDataFolder $(df+fname), $(tdf+fname)
	
	CheckNMPath()
	
	folder = FileBinSave(1, 1, tdf, "NMPath", file, 1, -1) // new file
	
	if (DataFolderExists(tdf) == 1)
		KillDataFolder $tdf // kill temp folder
	endif
	
	return folder
	
End // NMConfigSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConfigSaveAll()
	
	String df =  ConfigDF("")
	String file = StrVarOrDefault(df+"CurrentFile", "")
	
	if (strlen(file) == 0)
		file = "NMConfigs"
	endif

	if (StringMatch(StrVarOrDefault(df+"FileType", ""), "NMConfig") == 0)
		DoAlert 0, "NMConfigSave Error: folder is not a NM configuration file."
		return ""
	endif
	
	NMConfigCopy("All", 1) // get current configuration values
	
	CheckNMPath()
	
	return FileBinSave(1, 1, df, "NMPath", file, 1, -1) // new file

End // NMConfigSaveAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigOpenCall()

	NMCmdHistory("NMConfigOpen", NMCmdStr("", ""))
	
	return NMConfigOpen("")

End // NMConfigOpenCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigOpen(file)
	String file
	
	String flist, fname, odf, cdf, df = ConfigDF("")
	Variable icnt, dialogue, error = -1
	
	CheckNMPath()
	
	if (strlen(file) == 0)
		dialogue = 1
	endif
	
	String folder = FileBinOpen(dialogue, 0, "", "NMPath", file, 0) // NM_FileManager.ipf

	if (strlen(folder) == 0)
		return error // cancel
	endif
	
	if (IsNMFolder(folder, "NMConfig") == 1)
	
		flist = FolderObjectList(folder, 4) // sub-folder list
		
		for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		
			fname = StringFromList(icnt, flist)
			
			odf = folder + ":" + fname
			cdf = df + fname
		
			if (DataFolderExists(cdf) == 1)
				KillDataFolder $cdf // kill config folder
			endif
			
			DuplicateDataFolder $odf, $cdf
			
			NMConfigCopy(fname, -1) // set config values
		
		endfor
		
		
		error = 0
		
	else
	
		DoAlert 0, "Open File Error: file is not a NeuroMatic configuration file."
		
	endif
	
	if (DataFolderExists(folder) == 1)
		KillDataFolder $folder
	endif
	
	return error

End // NMConfigOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigOpenAuto()

	Variable icnt, error = -1
	String fname, ext = FileBinExt()
	
	if (IgorVersion() < 5)
		return -1 // does not seem to work with earlier Igor
	endif

	CheckNMPath()
	
	PathInfo NMPath
	
	if (V_flag == 0)
		return 0 // cannot open config file
	endif
	
	String path = S_path
	
	String flist = IndexedFile(NMPath, -1, "????")
	
	flist = RemoveFromList("NMConfigs.pxp", flist)
	flist = AddListItem("NMConfigs.pxp", flist, ";", 0) // open NMConfigs first
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		fname = StringFromList(icnt, flist)
		
		if (StrSearchLax(fname, ".ipf", 0) >= 0)
			continue // skip procedure files
		endif
		
		if (StrSearchLax(fname, ext, 0) >= 0)
			
			strswitch(ext)
				case ".nmb":
					if (StringMatch(NMBinFileType(path+fname), "NMConfig") == 0)
						continue
					endif
				case ".pxp":
					error = NMConfigOpen(fname)
			endswitch
			
		endif
		
	endfor
	
	PathInfo /S Igor // reset path to Igor

End // NMConfigOpenAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigKillCall(fname)
	String fname // config folder name
	
	String flist = NMConfigList()
	
	if ((strlen(fname) == 0) || (FindListItem(fname, flist) < 0))
	
		if (ItemsInList(flist) == 0)
			DoAlert 0, "No Configurations to kill."
			return 0
		endif
		
		if (ItemsInList(flist) > 1)
			flist += "All;"
		endif
	
		Prompt fname, "choose configuration to kill:", popup flist
		DoPrompt "Kill Configuration", fname
		
		if (V_flag == 1)
			return 0 // cancel
		endif
	
	endif
	
	NMCmdHistory("NMConfigKill", NMCmdStr(fname, ""))
	
	return NMConfigKill(fname)

End // NMConfigKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigKill(flist) // kill config folder
	String flist // config folder list, or "All"
	
	if (StringMatch(flist, "All") == 1)
		flist = NMConfigList()
	endif
	
	Variable icnt
	String fname, cdf, df = ConfigDF("")
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		
		fname = StringFromList(icnt, flist)
		
		cdf = df + fname
	
		if (DataFolderExists(cdf) == 1)
			KillDataFolder $cdf // kill config folder
		endif
	
	endfor
	
End // NMConfigKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigVar(fname, vName, value, infoStr)
	String fname, vName
	Variable value
	String infoStr
	
	String df = ConfigDF(fname)
	String pf = PackDF(fname)
	
	CheckNMvar(df+vname, NumVarOrDefault(pf+vName, value))
	CheckNMstr(df+"D_"+vName, infoStr)
	
End // NMConfigVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigStr(fname, vName, strValue, infoStr)
	String fname, vName, strValue, infoStr
	
	String df = ConfigDF(fname)
	String pf = PackDF(fname)
	
	CheckNMstr(df+vName, StrVarOrDefault(pf+vName, strValue))
	CheckNMstr(df+"D_"+vName, infoStr)
	
End // NMConfigStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigWave(fname, wName, npnts, value, infoStr)
	String fname, wName
	Variable npnts
	Variable value
	String infoStr
	
	String cw = ConfigDF(fname) + wName
	String pw = PackDF(fname) + wName
	
	infoStr = NMNoteCheck(infoStr)
	
	if ((WaveExists($pw) == 1) && (WaveExists($cw) == 0))
		Duplicate /O $pw $cw
	else
		CheckNMwave(cw, npnts, value)
	endif
	
	NMNoteType(cw, "NM"+fname, "", "", "Description:" + infoStr)
	
End // NMConfigWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigTWave(fname, wName, npnts, strValue, infoStr)
	String fname, wName
	Variable npnts
	String strValue
	String infoStr
	
	String cw = ConfigDF(fname) + wName
	String pw = PackDF(fname) + wName
	
	infoStr = NMNoteCheck(infoStr)
	
	if ((WaveExists($pw) == 1) && (WaveExists($cw) == 0))
		Duplicate /O $pw $cw
	else
		CheckNMtwave(cw, npnts, strValue)
	endif
	
	NMNoteType(cw, "NM"+fname, "", "", "Description:" + infoStr)
	
End // NMConfigTWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConfigVarList(fname, objType)
	String fname // config folder name
	Variable objType // (1) waves (2) variables (3) strings (4) data folders (5) numeric wave (6) text wave
	
	Variable ocnt
	String objName, rlist = ""
	
	String objList = FolderObjectList(ConfigDF(fname), objType)
	
	if (objType == 3) // strings
	
		for (ocnt = 0; ocnt < ItemsInList(objList); ocnt += 1)
		
			objName = StringFromList(ocnt, objList)
			
			if (StringMatch(objName[0,1], "D_") == 0) // do not include "Description" strings
				rlist = AddListItem(objName, rlist, ";", inf)
			endif
			
		endfor
		
		objList = rlist
		
	endif
	
	objList = RemoveFromList("FileType", objList)
	objList = RemoveFromList("VarName", objList)
	objList = RemoveFromList("StrValue", objList)
	objList = RemoveFromList("NumValue", objList)
	objList = RemoveFromList("Description", objList)
	
	return objList

End // NMConfigVarList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Configuration Edit/Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigEditCall(fname)
	String fname // config folder name
	
	String flist = NMConfigList()
	
	if ((strlen(fname) == 0) || (FindListItem(fname, flist) < 0))
	
		if (ItemsInList(flist) == 0)
			DoAlert 0, "No Configurations to edit."
			return 0
		endif
		
		if (ItemsInList(flist) > 1)
			flist += "All;"
		endif
	
		Prompt fname, "choose configuration to edit:", popup flist
		DoPrompt "Edit Configurations", fname
		
		if (V_flag == 1)
			return 0 // cancel
		endif
	
	endif
	
	NMCmdHistory("NMConfigEdit", NMCmdStr(fname, ""))
	
	return NMConfigEdit(fname)

End // NMConfigEditCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigEdit(flist) // create table to edit config vars
	String flist // config folder name list, or "All"
	
	Variable fcnt, ocnt, icnt, items, numItems, strItems
	Variable x1, x2, y1, y2
	
	String fname, objName, tName, tTitle, varList, strList
	String df, ndf = NMDF()
	
	String blankStr = ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
	
	Variable xPixels = NumVarOrDefault(ndf+"xPixels", 1000)
	
	if (StringMatch(flist, "All") == 1)
		flist = NMConfigList()
	endif
	
	for (fcnt = 0; fcnt < ItemsInList(flist); fcnt += 1)
	
		fname = StringFromList(fcnt, flist)
		df = ConfigDF(fname)
	
		tName = "Config_" + fname
		tTitle = fname + " Configurations"
	
		varList = NMConfigVarList(fname, 2)
		strList = NMConfigVarList(fname, 3)
	
		if ((ItemsInList(varList) == 0) && (ItemsInList(strList) == 0))
			//DoAlert 0, "Located no  \"" + fname + "\" configurations."
			Execute /Z fname + "ConfigEdit()" // run particular edit tab config if exists
			continue
		endif
		
		numItems = ItemsInList(varList)
		strItems = ItemsInList(strList)
		items = numItems + strItems
		
		if ((numItems > 0) && (strItems > 0))
			items += 1 // for seperator
		endif
		
		Make /O/T/N=(items) $(df+"Description") = ""
		Make /O/T/N=(items) $(df+"VarName") = ""
		Make /O/T/N=(items) $(df+"StrValue") = ""
		
		Make /O/N=(items) $(df+"NumValue") = Nan
		
		Wave /T Description = $(df+"Description")
		Wave /T VarName = $(df+"VarName")
		Wave /T StrValue = $(df+"StrValue")
		
		Wave NumValue = $(df+"NumValue")
		
		if (WinType(tName) == 0)
		
			Edit /K=1/W=(x1,y1,x2,y2) VarName
			DoWindow /C $tName
			DoWindow /T $tName, tTitle
			
			SetCascadeXY(tName)
			
			if (numItems > 0)
				AppendToTable NumValue
				Execute /Z "ModifyTable width(" + df + "NumValue)=60"
			endif
			
			if (strItems > 0)
				AppendToTable StrValue
				Execute /Z "ModifyTable alignment(" + df + "StrValue)=0, width(" + df + "StrValue)=150"
			endif
			
			AppendToTable Description
			
			Execute /Z "ModifyTable title(Point)= \"Entry\""
			Execute /Z "ModifyTable alignment(" + df + "VarName)=0, width(" + df + "VarName)=100"
			Execute /Z "ModifyTable alignment(" + df + "Description)=0, width(" + df + "Description)=500"
			
			SetWindow $tName hook=NMConfigEditHook
			
		endif
		
		DoWindow /F $tName
		
		NMConfigCopy(fname, 1) // get current configuration values
		
		icnt = 0
	
		for (ocnt = 0; ocnt < ItemsInList(varList); ocnt += 1)
			objName = StringFromList(ocnt, varList)
			VarName[icnt] = objName
			NumValue[icnt] = NumVarOrDefault(df+objName, Nan)
			StrValue[icnt] = blankStr
			Description[icnt] = StrVarOrDefault(df+"D_"+objName, "")
			icnt += 1
		endfor
		
		icnt += 1
		
		for (ocnt = 0; ocnt < ItemsInList(strList); ocnt += 1)
			objName = StringFromList(ocnt, strList)
			VarName[icnt] = objName
			StrValue[icnt] = StrVarOrDefault(df+objName,"")
			Description[icnt] = StrVarOrDefault(df+"D_"+objName, "")
			icnt += 1
		endfor
		
		Execute /Z fname + "ConfigEdit()" // run particular edit tab config if exists
		
	endfor
	
	return 0

End // NMConfigEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigEditHook(infoStr)
	String infoStr
	
	Variable runhook
	String df = NMDF()
	
	String event = StringByKey("EVENT",infoStr)
	String win = StringByKey("WINDOW",infoStr)
	String prefix = "Config_"
	
	Variable icnt = StrSearchLax(win, prefix, 0)
	
	if (icnt < 0)
		return 0
	endif
	
	String fname = win[icnt+strlen(prefix),inf]

	strswitch(event)
		case "deactivate":
			runhook = 1
			SetNMstr(df+"ConfigHookEvent", "deactivate")
			break
		case "kill":
			runhook = 1
			SetNMstr(df+"ConfigHookEvent", "kill")
			break
	endswitch
	
	if (runhook == 1)
		NMConfigEdit2Vars(fname)
		NMConfigCopy(fname, -1) // now save these to appropriate folder
		Execute /Z fname + "ConfigHook()" // run particular tab hook if exists
	endif

End // NMConfigEditHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigEdit2Vars(fname) // save table values to config vars
	String fname // config folder name

	String objName, df = ConfigDF(fname)
	
	Variable icnt, jcnt, items, objNum
	String objStr, objList, vList
	
	String tName = "Config_" + fname

	if (WinType(tName) != 2)
		return 0 // table doesnt exist
	endif
	
	if (WaveExists($(df+"VarName")) == 0)
		return 0
	endif
	
	Wave /T VarName = $(df+"VarName")
	Wave /T Description = $(df+"Description")
	
	vList = Wave2List(df+"VarName")
	
	// save numeric variables
	
	objList = NMConfigVarList(fname, 2)
	
	if (WaveExists($(df+"NumValue")) == 1)
	
		Wave NumValue = $(df+"NumValue")
		
		items = numpnts(NumValue)
	
		for (icnt = 0; icnt < items; icnt += 1)
		
			objName = VarName[icnt]
	
			if ((strlen(objName) == 0) || (FindListItem(objName, objList) < 0))
				continue
			endif
			
			SetNMvar(df+objName, NumValue[icnt])
			
			vList = RemoveFromList(objName, vList)
			
		endfor
	
	endif
	
	// save string variables
	
	objList = NMConfigVarList(fname, 3)
	
	if (WaveExists($(df+"StrValue")) == 1)
	
		Wave /T StrValue = $(df+"StrValue")
		
		items = numpnts(NumValue)
	
		for (icnt = 0; icnt < items; icnt += 1)
		
			objName = VarName[icnt]
			
			if ((strlen(objName) == 0) || (FindListItem(objName, objList) < 0))
				continue
			endif
			
			SetNMstr(df+objName, StrValue[icnt])
			
			vList = RemoveFromList(objName, vList)
			
		endfor
	
	endif
	
	// check for remaining variables
	
	for (icnt = 0; icnt < ItemsInList(vlist); icnt += 1)
	
		objName = StringFromList(icnt, vlist)
		
		if (exists(df+objName) > 0)
			continue
		endif
		
		for (jcnt = 0; jcnt < numpnts(VarName); jcnt += 1)
		
			if (StringMatch(objName, VarName[jcnt]) == 1)
			
				objStr = StrValue[jcnt]
				objNum = NumValue[jcnt]
				
				if (numtype(objNum) == 0)
					SetNMvar(df+objName, objNum)
				else
					SetNMstr(df+objName, objStr)
				endif
				
				SetNMstr(df+"D_"+objName, Description[jcnt])
				
			endif
		
		endfor
		
	endfor
	
End // NMConfigEdit2Vars

//****************************************************************
//****************************************************************
//****************************************************************
