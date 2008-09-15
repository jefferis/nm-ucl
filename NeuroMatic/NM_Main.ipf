#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Main Functions
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	First release: 05 May 2002
//	Last modified: 15 May 2007
//
//	Data Analyses Software
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMVersionNum()

	return 2.00

End // NMVersionNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMVersionStr()

	return "2.00"

End // NMVersionStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMwebpage()

	BrowseURL /Z  "http://www.neuromatic.thinkrandom.com/"

End // NMwebpage

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PackDF(fname) // return Package path/subpath
	String fname
	
	// note, NM tabs are treated as individual 'packages'
	
	String df = "root:Packages:"

	if (strlen(fname) > 0)
		df += fname
	endif
	
	return LastPathColon(df, 1)
	
End // PackDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckPackDF(fname) // check Package data folder exists
	String fname // data folder
	
	String pdf = PackDF("") // parent
	String df = PackDF(fname) // sub
	
	if (DataFolderExists(pdf) == 0)
		NewDataFolder $LastPathColon(pdf, 0)
	endif

	if (DataFolderExists(df) == 0)
		NewDataFolder $LastPathColon(df, 0)
		return 1 // yes, made the folder
	endif
	
	return 0 // did not make folder

End // CheckPackDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckPackage(package, force) // check folder/globals
	String package // package folder name
	Variable force // force variable check (0) no (1) yes
	
	String df = PackDF(package)
	
	Variable made = CheckPackDF(package) // check folder
	
	if ((made == 0) && (force == 0))
		return 0
	endif
	
	// check package folder variables, i.e. "CheckStats()"

	Execute /Z "Check" + package + "()"
	
	// check package config folder and globals
	
	if (made == 1)
		NMConfig(package, -1) // copy configs to new folder
	else
		NMConfig(package, 1) // copy folder vars to configs
	endif
	
	// check old preferences
	
	strswitch(package)
	
		case "NeuroMatic":
			package = "NM"
			break
			
	endswitch
	
	if (made == 1)
		Execute /Z "NMPrefs(\"" + package + "\")"
	endif
	
	return made
	
End // CheckPackage

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Package Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefix(objName) // prefix ID
	String objName
	
	return "NM_" + objName

End NMPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDF() // return NeuroMatic's full-path folder

	return PackDF("NeuroMatic")
	
End // NMDF

//****************************************************************
//****************************************************************
//****************************************************************

Function NeuroMaticConfigHook() // called from NMConfigEditHook

	CheckNMPaths() // set paths if they have changed

End // NeuroMaticConfigHook

//****************************************************************
//****************************************************************
//****************************************************************

Static Function IgorStartOrNewHook(igorApplicationNameStr)
	String igorApplicationNameStr
	
	CheckNMVersionNum()
	
	return 0
	
End // IgorStartOrNewHook

//****************************************************************
//****************************************************************
//****************************************************************

Static Function BeforeExperimentSaveHook(refNum, fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr, fileKind )
	Variable refNum
	String fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr
	Variable fileKind
	
	KillPath /Z NMpath
	KillPath /Z OpenDataPath
	KillPath /Z SaveDataPath
	KillPath /Z ClampPath
	KillPath /Z StimPath
	KillPath /Z OpenAllPath
	
	return 0

End // BeforeExperimentSaveHook

//****************************************************************
//****************************************************************
//****************************************************************

Static Function AfterFileOpenHook(refNum, fileName, path, type, creator, kind)
	Variable refNum,kind
	String fileName,path,type,creator
	
	CheckNMVersionNum()
	
	if (StringMatch(type,"IGsU") == 1) // Igor Experiment, packed
		CheckFileOpen(fileName)
	endif
	
	if (CheckComputerXYpixels() == 1) // check screen dimensions are OK
		MakeNMpanel()
	endif
	
	return 0
	
End // AfterFileOpenHook

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNM(force) // check NM Package folders
	Variable force

	Variable madeFolder
	String df = NMDF()
	
	SetNMvar(df+"NMOK", 0)
	
	if (NumVarOrDefault(df+"NMOn", 1) == 0)
		return 1
	endif
	
	if (DataFolderExists("root:WinGlobals:") == 0)
		NewDataFolder root:WinGlobals // new folder for Stats drag wave variables
	endif
	
	CheckPackDF("Configurations") // places Config folder first
	
	madeFolder = CheckPackage("NeuroMatic", force)
	
	if ((force == 1) || (madeFolder == 1))

		if (numtype(NumVarOrDefault(df+"xPixels", Nan)) > 0)
			NMComputerCall(0) // set Computer type and screen dimensions
		endif
		
		NMProgressOn(NumVarOrDefault(df+"ProgFlag", 1)) // test progress window
		//CheckPackage("Chan", 1)
		CheckNMPaths()
		CheckFileOpen("")
		
	endif
	
	SetNMvar(df+"NMOK", 1)
	
	if (madeFolder == 1)
		NMConfigOpenAuto()
		CheckNMPaths()
		AutoStartNM()
		KillGlobals("root:", "V_*", "110") // clean root
		KillGlobals("root:", "S_*", "110")
	endif
	
	return madeFolder

End // CheckNM

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMVersionNum()

	if (NumVarOrDefault(NMDF() + "NMversion", 0) != NMVersionNum())
		ResetNM(0)
	endif

End // CheckNMversion

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFolderList()

	Variable icnt, folders
	String folder, flist = NMDataFolderList(), df = NMDF()
	
	folders = ItemsInList(flist)
	
	if (strlen(NMFolderListName("")) > 0)
		if (folders == NumVarOrDefault(df+"NumFolders", 0))
			return 0 // no change in folders
		endif
	endif

	CheckNMtwave(df+"FolderList", -1, "")
	
	Wave /T list = $(df+"FolderList")
	
	for (icnt = 0; icnt < numpnts(list); icnt += 1)
	
		folder = list[icnt]
		
		if (IsNMDataFolder(folder) == 0)
			NMFolderListRemove(folder)
		endif
		
	endfor
	
	for (icnt = 0; icnt < folders; icnt += 1)
		NMFolderListAdd(StringFromList(icnt, flist))
	endfor
	
	SetNMvar(df+"NumFolders", folders)
	
End // CheckNMFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCurrentFolder()

	return CurrentNMFolder(0)

End // NMCurrentFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMFolder(path)
	Variable path // (0) no path (1) with path
	
	String folder = StrVarOrDefault(NMDF()+"CurrentFolder", "")
	
	if (path == 1)
		return "root:" + folder + ":"
	endif

	return folder

End // CurrentNMFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckCurrentFolder() // check if current NM folder is OK

	String df = NMDF()
	String currentFolder = NMCurrentFolder()
	String thisFolder = GetDataFolder(1)
	
	if (NumVarOrDefault(df+"NMOn", 1) == 0)
		return 1
	endif

	if ((StringMatch(currentFolder, thisFolder) == 0) && (IsNMDataFolder("") == 1))
		
		DoAlert 1, "The current data folder has changed. Do you want NeuroMatic to change to this folder?"
		
		if (V_Flag == 1)
			SetNMstr(df+"CurrentFolder", thisFolder)
			CurrentFolder = thisFolder
			UpdateNM(0)
		endif
		
	endif
	
	if (DataFolderExists(CurrentFolder) == 1)
		SetDataFolder CurrentFolder
	else
		NMFolderChangeToFirst()
	endif
	
	//UpdateNMPanelTitle()
	
	return 1

End // CheckCurrentFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function ResetNMCall()

	NMCmdHistory("ResetNM", NMCmdNum(0,""))
	
	return ResetNM(0)

End // ResetNMCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ResetNM(killFirst) // use this function to re-initialize neuromatic
	Variable killfirst // kill variables first flag

	String df = NMDF()
	
	Variable version = NMVersionNum()
	
	if (killfirst == 1)
	
		DoAlert 1, "Warning: this function will re-initialize all of NeuroMatic global variables. Do you want to continue?"
	
		if (V_Flag != 1)
			return -1
		endif
	
	endif
	
	CheckCurrentFolder() // must set this here, otherwise Igor is at root directory
	NMTabListGet()
	ChanGraphClose(-1,1)
	
	if (killfirst == 1)
		NMKill() // this is hard kill, and will reset previous global variables to default values
	endif
	
	CheckNM(1)
	
	SetNMvar(df+"CurrentTab", 0) // set Main Tab as current tab
	
	CheckNMDataFolders()
	CheckNMFolderList()
	ChanWaveListSet(-1, 0)
	
	SetNMvar(df+"NMversion", version)
	
	MakeNMpanel()
	
	if (IsNMDataFolder("") == 1)
		UpdateCurrentWave()
	endif
	
	NMHistory("\rStarted NeuroMatic Version " + NMVersionStr())
	
	return 0

End // ResetNM

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoStartNM()
	String df = NMDF()

	if (NumVarOrDefault(df+"AutoStart", 1) == 0)
		return 0
	endif
	
	if (IsNMDataFolder("") == 0)
		NMFolderNew("")
	else
		UpdateNM(1)
	endif

End // AutoStartNM

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNM(force)
	Variable force
	
	String df = NMDF()

	if (NumVarOrDefault(df+"UpdateNMBlock", 0) == 1)
		KillVariables /Z $(df+"UpdateNMBlock")
		return 0
	endif
	
	if (WinType("NMpanel") == 0)
	
		if (force == 0)
			return 0 // nothing to update
		endif
		
		MakeNMpanel()
		
	else
	
		UpdateNMPanel(1)
		
	endif
	
	if (IsNMDataFolder("") == 1)
		UpdateCurrentWave()
	endif
	
End // UpdateNM

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateCurrentWave() // set current wave and group number, update displays
	
	NMGroupUpdate()
	UpdateNMSets(0)
	ChanGraphsUpdate()
	NMWaveSelect("update")
	NMAutoTabCall()

End // UpdateCurrentWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMKill() // use this with caution!
	String df = NMDF()

	DoWindow /K NMpanel

	KillTabs(NMTabListGet()) // kill tab plots, tables and globals
	
	ChanGraphClose(-1,1) // kill graphs
	
	if (DataFolderExists(df) == 1)
		KillDataFolder $df
	endif
	
	df = PackDF("Chan")
	
	if (DataFolderExists(df) == 1)
		KillDataFolder $df
	endif

End // NMKill

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Neuromatic Global Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNeuroMatic() // check main NeuroMatic globals

	String df = NMDF()
	
	if (DataFolderExists(df) == 0)
		return -1
	endif
	
	CheckNMvar(df+"NMversion", NMVersionNum())	// NeuroMatic version
	
	CheckNMvar(df+"NMOn", 1)			// NueorMatic (0) off (1) on
	CheckNMvar(df+"AutoStart", 1)			// auto-start NeuroMatic (0) no (1) yes
	CheckNMvar(df+"AutoPlot", 0)			// auto plot data upon loading file (0) no (1) yes
	CheckNMvar(df+"ProgFlag", 1)			// progress display (0) off (1) WinProg XOP of Kevin Boyce
	CheckNMvar(df+"OverWrite", 1)			// over-write (0) off (1) on
	CheckNMvar(df+"WriteHistory", 1)		// analysis history (0) off (1) Igor History (2) notebook (3) both
	CheckNMvar(df+"CmdHistory", 1)		// command history (0) off (1) Igor History (2) notebook (3) both
	CheckNMvar(df+"GroupsOn", 0)		// groups (0) on (1) off
	CheckNMvar(df+"Cascade", 0)			// window cascade counter
	CheckNMvar(df+"ImportPrompt", 1)		// display import prompt panel (0) no (1) yes
	
	CheckNMstr(df+"OrderWavesBy", "name")	// order waves by "name" or creation "date"
	CheckNMstr(df+"FolderPrefix", "nm")
	CheckNMstr(df+"PrefixList", "Record;Avg_;")
	CheckNMstr(df+"NMTabList", "Main;Stats;Spike;Event;Fit;")
	
	CheckNMstr(df+"OpenDataPath", "")	// open data file path (i.e. C:Jason:TestData:)
	CheckNMstr(df+"SaveDataPath", "")	// save data file path (i.e. C:Jason:TestData:)
	
	CheckNMtwave(df+"FolderList", 0, "")	// wave of NM folder names

End // CheckNeuroMatic

//****************************************************************
//****************************************************************
//****************************************************************

Function NeuroMaticConfigs()
	String fname = "NeuroMatic"

	NMConfigVar(fname, "AutoStart", 1, "Auto-start NM (0) no (1) yes")
	NMConfigVar(fname, "AutoPlot", 0, "Auto plot data upon loading file (0) no (1) yes")
	NMConfigVar(fname, "NameFormat", 1, "Wave name format (0) short (1) long")
	//NMConfigVar(fname, "ProgFlag", 1, "Progress display (0) off (1) WinProg XOP of Kevin Boyce")
	
	NMConfigVar(fname, "WriteHistory", 1, "Analysis history (0) off (1) Igor History (2) notebook (3) both")
	NMConfigVar(fname, "CmdHistory", 1, "Command history (0) off (1) Igor History (2) notebook (3) both")
	
	//NMConfigVar(fname, "xPixels", 1000, "Screen x-pixels") // auto-detected
	//NMConfigVar(fname, "yPixels", 800, "Screen y-pixels") // auto-detected
	//NMConfigStr(fname,"Computer", "mac", "Computer type (mac or pc)") // auto-detected
	
	NMConfigVar(fname, "ImportPrompt", 1, "Import prompt (0) off (1) on")
	
	NMConfigVar(fname, "OverWrite", 1, "Over-write (0) off (1) on")
	
	NMConfigStr(fname, "OrderWavesBy", "name", "Order waves by \"name\" or creation \"date\"")
	NMConfigStr(fname, "FolderPrefix", "nm", "NM folder prefix")
	NMConfigStr(fname, "PrefixList", "Record;Avg_;ST_;", "List of wave prefix names")
	NMConfigStr(fname, "NMTabList", "Main;Stats;Spike;MyTab;", "List of NM tabs")
	
	NMConfigStr(fname, "OpenDataPath", "", "Open data file path (i.e. C:Jason:TestData:)")
	NMConfigStr(fname, "SaveDataPath", "", "Save data file path (i.e. C:Jason:TestData:)")
			
End // NeuroMaticConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMPaths()
	String df = NMDF()
	
	String opath = StrVarOrDefault(df+"OpenDataPath", "")
	String spath = StrVarOrDefault(df+"SaveDataPath", "")
	
	if (strlen(opath) > 0)
		PathInfo OpenDataPath
		if (StringMatch(opath, S_path) == 0)
			NewPath /O/Q/Z OpenDataPath opath
		endif
	endif
	
	if (strlen(spath) > 0)
		PathInfo SaveDataPath
		if (StringMatch(spath, S_path) == 0)
			NewPath /O/Q/Z SaveDataPath spath
		endif
	endif

End // CheckNMPaths

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOverWrite() // return status of OverWrite flag

	return NumVarOrDefault(NMDF() + "OverWrite", 1)

End // NMOverWrite

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOverWriteOn(on)
	Variable on // (0) no (1) yes
		
	SetNMvar(NMDF()+"OverWrite", BinaryCheck(on))

End // NMOverWriteOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOn(on)
	Variable on // (-1) toggle (0) off (1) on
	
	String df = NMDF()
	Variable nmon = NumVarOrDefault(df+"NMOn", 1)
	
	if (on == -1)
		on = !nmon
	endif
	
	SetNMvar(df+"NMOn", on)
	
	if (on == 0)
		DoWindow /K NMpanel
	else
		MakeNMpanel()
	endif
	
	return 1

End // NMOn

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMOrderWavesPref()

	return StrVarOrDefault(NMDF() + "OrderWavesBy", "name")

End // NMOrderWavesPref()

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesPrefCall()
	
	String order = NMOrderWavesPref()
	
	Prompt order, "Order selected waves by:", popup "name;date;"
	DoPrompt "Order Waves Preference", order
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	NMCmdHistory("NMOrderWavesPrefSet", NMCmdStr(order,""))
	
	return NMOrderWavesPrefSet(order)

End // NMOrderWavesPreferenceCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesPrefSet(order)
	String order // order waves (0) by creation date (1) alpha-numerically
	
	strswitch(order)
		case "name":
		case "date":
			SetNMstr(NMDF() + "OrderWavesBy", order)
			break
		default:
			DoAlert 0, "Unrecognized order waves preference: " + order
			return -1
	endswitch
	
	return 0
	
End // NMOrderWavesPrefSet

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanNum2Char(chanNum)
	Variable chanNum
	
	return num2char(65+chanNum)

End // ChanNum2Char

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanChar2Num(chanChar)
	String chanChar
	
	return char2num(UpperStr(chanChar)) - 65

End // ChanChar2Num

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanCharGet(wName)
	String wName // wave name
	Variable icnt
	
	for (icnt = strlen(wName)-1; icnt >= 0; icnt -= 1)
		if (numtype(str2num(wName[icnt])) != 0)
			break // found Channel letter
		endif
	endfor
	
	return wName[icnt] // return channel character, given wave name

End // ChanCharGet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanNumGet(wName)
	String wName // wave name
	
	return (char2num(ChanCharGet(wName)) - 65) // return chan number, given wave name

End // ChanNumGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanCharList(numchans, seperator)
	Variable numchans
	String seperator
	
	String chanlist = ""
	Variable ccnt
	
	if (numchans == -1)
		numchans = NMNumChannels()
	endif
	
	for (ccnt = 0; ccnt < numchans; ccnt += 1)
		chanlist += ChanNum2Char(ccnt) + seperator
	endfor
	
	return chanlist // returns chan list (i.e. "A;B;C;")

End // ChanCharList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelectCall(chanStr)
	String chanStr
	
	strswitch(chanStr)
		case "Channel":
		case "---":
			UpdateNMChanSelect()
			return Nan
			
	endswitch
	
	NMCmdHistory("NMChanSelect", NMCmdStr(chanStr, ""))
	NMChanSelect(chanStr)
	
End // NMChanSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelect(chanStr) // set current channel
	String chanStr // "A", "B", "C"... or "All" or ("") for current channel
	
	Variable chanNum
	String chanList = ChanCharList(-1, ";")
	
	if ((StringMatch(chanStr, "All") == 0) && (WhichListItem(chanStr, chanList) < 0))
		DoAlert 0, "NMChanSelect Error: channel selected is out of range: " + chanStr
		return Nan
	endif
	
	if (strlen(chanStr) == 0)
		chanNum = NMCurrentChan()
	elseif (StringMatch(chanStr, "All") == 1)
		chanNum = -1
	else
		chanNum = ChanChar2Num(chanStr)
	endif
	
	if ((numtype(chanNum) > 0) || (chanNum < -1))
		return Nan
	endif
	
	return CurrentChanSet(chanNum)

End // NMChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function CurrentChanSet(chanNum) // set current channel
	Variable chanNum // 0, 1, 2... (-1 for all)
	
	Variable changeto
	
	String df = NMDF(), TabList = NMTabListGet()
	
	Variable currTab = NumVarOrDefault(df+"CurrentTab", 0)
	Variable currChan = NMCurrentChan()
	Variable nchan = NMNumChannels()
	
	if ((WaveExists(ChanSelect) == 0) || (nchan == 0))
		return Nan
	endif
	
	Wave ChanSelect
	
	if ((chanNum < -1) || (chanNum >= NMNumChannels()))
		DoAlert 0, "CurrentChanSet Error: channel selected is out of range: " + num2str(chanNum)
		return Nan
	endif
	
	if (chanNum == -1)
		changeto = 0
	else
		changeto = chanNum
	endif
	
	if (changeto != currChan)
		changeto = -1
	endif
	
	Note /K ChanSelect
	
	if (chanNum == -1) // "All"
		currChan = 0
		ChanSelect = 1
		Note ChanSelect, "All"
	else
		currChan = chanNum
		ChanSelect = 0
		ChanSelect[chanNum] = 1
		Note ChanSelect, num2str(chanNum)
	endif
	
	SetNMvar("CurrentChan", currChan)
	
	if (changeto == -1)
		ChangeTab(currTab, currTab, TabList) // updates tab display waves
		//ChanGraphsToFront()
	endif
	
	NMWaveSelectCount()
	UpdateNMChanSelect()
	
	return currChan

End // CurrentChanSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelected(chanNum)
	Variable chanNum
	
	if (WaveExists(ChanSelect) == 0)
		return 0
	endif
	
	Wave ChanSelect
	
	if (ChanSelect[chanNum] == 1)
		return 1
	else
		return 0
	endif
	
End // NMChanSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelectedAll()
	Variable ccnt

	if (WaveExists(ChanSelect) == 0)
		return 0
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
		if (chanSelect[ccnt] == 0)
			return 0
		endif
	endfor
	
	return 1

End // NMChanSelectedAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelected(chanNum, wavNum)
	Variable chanNum
	Variable wavNum
	
	String wName, wList
	
	if (WaveExists(WavSelect) == 0)
		return ""
	endif
	
	if (NMChanSelected(chanNum) != 1)
		return ""
	endif
	
	Wave WavSelect
	
	if (WavSelect[wavNum] != 1)
		return ""
	endif
	
	wList = NMChanWaveListGet(chanNum)
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	wName = StringFromList(wavNum, wList)
	
	if (NMUtilityWaveTest(wName) < 0)
		return ""
	endif
	
	return wName
	
End // NMWaveSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanLabel(chanNum, xy, wList)
	Variable chanNum // (-1) for current chan
	String xy // "x" or "y"
	String wList // ("") for current chan wave list
	
	String xyLabel = "", defaultStr = ""
	
	strswitch(xy)
		case "x":
			defaultStr = StrVarOrDefault("xLabel", "msec")
			break
		case "y":
			if ((WaveExists(yLabel) == 1) && (numpnts(yLabel) > 0))
				Wave /T yLabel
				defaultStr = yLabel[chanNum]
			endif
			break
	endswitch
	
	if (chanNum == -1)
		chanNum = NMCurrentChan()
	endif
	
	if (ItemsInList(wList) == 0)
		wList = NMChanWaveList(chanNum)
	endif

	return GetWaveUnits(xy, wList, defaultStr) // new Note Labels
	
End // ChanLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanLabelSet(chanNum, wSelect, xy, labelStr)
	Variable chanNum // (-1) for current selected chan waves
	Variable wSelect // (1) selected waves (2) all chan waves
	String xy // "x" or "y"
	String labelStr
	
	Variable wcnt
	String wName, wList
	
	if (chanNum == -1)
		chanNum = NMCurrentChan()
	endif
	
	switch(wSelect)
	
		case 1:
			wList = NMChanWaveList(chanNum)
			break
			
		case 2:
		
			if (WaveExists(ChanWaveList) == 0)
				return -1
			endif
			
			Wave /T ChanWaveList
			
			wList = ChanWaveList[chanNum]
			
			break
			
	endswitch
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		strswitch(xy)
			case "x":
			case "y":
				NMNoteStrReplace(wName, xy+"Label", labelStr)
				RemoveWaveUnits(wName)
				break
				
			default:
				return -1
		
		endswitch
	
	endfor
	
	ChanGraphsUpdate()
	
	return 0

End // ChanLabelSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanUnits2Labels()
	Variable ccnt
	String wName, s, x, y
	
	Variable nwaves = NMNumWaves()
	
	if (nwaves <= 0)
		return 0
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
		
		wName = ChanWaveName(ccnt, 0)
		s = WaveInfo($wName, 0)
		x = StringByKey("XUNITS", s)
		y = StringByKey("DUNITS", s)
		
		if (strlen(x) > 0)
			ChanLabelSet(ccnt, 2, "x", x)
		endif
		
		if (strlen(y) > 0)
			ChanLabelSet(ccnt, 2, "y", y)
		endif

	endfor

End // ChanUnits2Labels

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Chan Wave List Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

//****************************************************************
//
//	NMChanWaveList()
//	returns a list of all currently selected waves in a channel.
//	Note, this function requires the existance of NM waves WavSelect and ChanSelect.
//	Note, this function replaces GetWaveList() and GetChanWaveList()
//
//****************************************************************

Function /S NMChanWaveList(chanNum)
	Variable chanNum // channel number (-1) for all currently selected channels
	
	Variable wcnt, ccnt, cbgn, cend
	String wName, wList = ""
	
	if ((WaveExists(WavSelect) != 1) || (WaveExists(ChanSelect) != 1))
		DoAlert 0, "ChanWaveList Abort : cannot locate NeuroMatic waves WavSelect and/or ChanSelect."
		return ""
	endif
	
	Wave WavSelect, ChanSelect
	
	if (chanNum < 0)
		cbgn = 0
		cend = numpnts(ChanSelect) - 1
	else
		cbgn = chanNum
		cend = chanNum
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1) // loop thru channels
	
		if ((chanNum < 0) && (ChanSelect[ccnt] != 1)) 
			continue
		endif
	
		for (wcnt = 0; wcnt < numpnts(WavSelect); wcnt += 1) // loop thru waves
	
			if (WavSelect[wcnt] != 1)
				continue
			endif
			
			wName = ChanWaveName(ccnt, wcnt)
		
			if (WaveExists($wName) == 1)
				wList = AddListItem(wName, wList, ";", inf)
			endif
		
		endfor
		
	endfor
	
	return wList

End // NMChanWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanWaveListGet(chanNum)
	Variable chanNum // channel number (pass -1 for all currently selected channels)
	
	return NMChanWaveList(chanNum)
	
End // ChanWaveListGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetWaveList()

	return NMChanWaveList(NumVarOrDefault("CurrentChan", -1))
	
End // GetWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetChanWaveList(chanNum)
	Variable chanNum // channel number

	return NMChanWaveList(chanNum)
	
End // GetChanWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentChanWaveList()

	return NMChanWaveList(NumVarOrDefault("CurrentChan", -1))

End // CurrentChanWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWavesCount(chanNum) // count number of currently active waves in a channel
	Variable chanNum // channel number

	return ItemsInList(NMChanWaveList(chanNum))

End // ChanWavesCount

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveListSet(chanNum, force) // update the list of wave names (ChanWaveList)
	Variable chanNum // channel number (-1) for all channels
	Variable force // (0) no (1) yes
	
	Variable icnt, jcnt = -1, ccnt, cbgn = chanNum, cend = chanNum
	Variable wcnt, nwaves, nmax, strict
	String wname, wList = "", allList = "", sList = ""
	
	String order = NMOrderWavesPref()
	
	String opstr = WaveListText0()
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	String cPrefix = NMCurrentWavePrefix()
	
	CheckNMtwave("ChanWaveList", numChannels, "")
	
	Wave /T ChanWaveList
	
	if (numChannels == 0)
		return 0
	endif
	
	DoWindow /K $NMChanWaveListTableName()
	
	if (chanNum < 0)
		cbgn = 0
		cend = numChannels - 1
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		if (force == 1)
			ChanWaveList[ccnt] = ""
		elseif (ItemsInList(ChanWaveList[ccnt]) > 0)
			continue
		endif
		
		wList = ""
			
		if (numChannels == 1)
		
			wList = WaveList(cPrefix + "*", ";", opstr)
			
		else
		
			if (jcnt < 0)
				wList = ChanWaveListSearch(cPrefix, ccnt)
			endif
			
			if (ItemsInList(wList) == 0)
			
				jcnt = max(jcnt, ccnt)
		
				for (icnt = jcnt; icnt < 10; icnt += 1)
				
					wList = ChanWaveListSearch(cPrefix, icnt)
					
					if (ItemsInList(wList) > 0)
						jcnt = icnt + 1
						break
					endif
					
				endfor
				
			endif
			
		endif

		if (ItemsInList(wList) == 0) // if none found, try most general name
			wList = WaveList(cPrefix + "*", ";", opstr)
		endif
		
		for (wcnt = 0; wcnt < ItemsInList(allList); wcnt += 1) // remove waves already used
			wname = StringFromList(wcnt, allList)
			wList = RemoveFromList(wname, wList)
		endfor
		
		nwaves = ItemsInList(wList)
		
		if (nwaves > nmax)
			nmax = nwaves
		endif
		
		if (nwaves == 0)
			continue
		elseif (nwaves != NumWaves)
			//DoAlert 0, "Warning: located only " + num2str(nwaves) + " waves for channel " + ChanNum2Char(ccnt) + "."
		endif
		
		//strict = ChanWaveListStrict(wList, ccnt)
		
		slist = SortListAlphaNum(wList, cPrefix)
		
		if ((StringMatch(order, "name") == 1) && (StringMatch(wList, slist) == 0))
			wList = slist
		endif
		
		//Print "Chan" + ChanNum2Char(ccnt) + ": " + wList
	
		ChanWaveList[ccnt] = wList
		allList += wList
		
	endfor
	
	//SetNMvar("NumWaves", nmax)
	
	ChanWaveList2Waves()

End // ChanWaveListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveListSortAlphaNum(chanNum)
	Variable chanNum // channel number (-1) for all currently selected channels
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String wlist, slist
	
	String cPrefix = NMCurrentWavePrefix()
	
	Wave /T ChanWaveList
	
	DoWindow /K $NMChanWaveListTableName()
	
	if (chanNum < 0)
		cbgn = 0
		cend = numpnts(ChanWaveList)
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
		wlist = ChanWaveList[ccnt]
		slist = SortListAlphaNum(wList, cPrefix)
		ChanWaveList[ccnt] = slist
		//Print "Chan" + ChanNum2Char(ccnt) + ": " + sList
	endfor
	
	ChanWaveList2Waves()

End // ChanWaveListSortAlphaNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanWaveListSearch(wPrefix, chanNum) // return list of waves appropriate for channel
	String wPrefix // wave prefix
	Variable chanNum
	
	Variable wcnt, icnt, jcnt, seqnum, foundLetter
	String wList, wname, seqstr, olist = ""
	
	String chanstr = ChanNum2Char(chanNum)

	wList = WaveList(wPrefix + "*" + chanstr + "*", ";", WaveListText0())
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wname = StringFromList(wcnt, wList)
		
		for (icnt = strlen(wname)-2; icnt > 0; icnt -= 1)
		
			if (StringMatch(wname[icnt,icnt], chanstr) == 1)
			
				seqstr = wname[icnt+1,inf]
				foundLetter = 0
				
				for (jcnt=0; jcnt < strlen(seqstr); jcnt += 1)
					if (numtype(str2num(seqstr[jcnt, jcnt])) > 0)
						foundLetter = 1
					endif
				endfor
				
				if (foundLetter == 0)
					olist = AddListItem(wname, olist, ";", inf) // matches criteria
				endif
				
				break
				
			endif
			
		endfor
		
	endfor
	
	return olist

End // ChanWaveListSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListGet(chanNum)
	Variable chanNum
	
	if (WaveExists(ChanWaveList) == 0)
		return ""
	endif
	
	Wave /T ChanWaveList
	
	if ((chanNum >= 0) && (chanNum < numpnts(ChanWaveList)))
		return ChanWaveList[chanNum]
	endif
	
	return ""
	
End // NMChanWaveListGet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaves2WaveList()
	Variable ccnt, numChannels = NMNumChannels()
	String wName, wList
	
	CheckNMtwave("ChanWaveList", numChannels, "")

	if (WaveExists(ChanWaveList) == 0)
		return -1
	endif
	
	Wave /T ChanWaveList
	
	for (ccnt = 0; ccnt < numpnts(ChanWaveList); ccnt += 1)
		wName = "wNames_" + ChanNum2Char(ccnt)
		ChanWaveList[ccnt] = Wave2List(wName)
	endfor

End // ChanWaves2WaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveList2Waves()
	Variable ccnt, nwaves = NMNumWaves()
	String wName, wList

	if (WaveExists(ChanWaveList) == 0)
		return -1
	endif
	
	Wave /T ChanWaveList
	
	for (ccnt = 0; ccnt < 10; ccnt += 1)
		wList = ChanWaveList[ccnt]
		wName = "wNames_" + ChanNum2Char(ccnt)
		KillWaves /Z $wName
	endfor
	
	for (ccnt = 0; ccnt < numpnts(ChanWaveList); ccnt += 1)
		wList = ChanWaveList[ccnt]
		wName = "wNames_" + ChanNum2Char(ccnt)
		List2Wave(wList, wName)
		if ((WaveExists($wName) == 1) && (numpnts($wName) != nwaves))
			Redimension /N=(nwaves) $wName
		endif
	endfor

End // ChanWaveList2Waves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentChanWaveListName()

	return "wNames_" + ChanNum2Char(NMCurrentChan())

End // CurrentChanWaveListName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanWaveListName(chanNum)
	Variable chanNum // (-1) for current
	
	if (chanNum < 0)
		chanNum = NMCurrentChan()
	endif

	return "wNames_" + ChanNum2Char(chanNum)

End // ChanWaveListName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListTableName()

	return NMPrefix(NMFolderPrefix("")+"OrderWaveNames")

End // NMChanWaveListTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListOrderTable(chanNum)
	Variable chanNum // (-1) for All
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	
	String wname = ChanWaveListName(ccnt)
	String wname2 = "wNames_Order"
	
	String tName = NMChanWaveListTableName()
	
	if (WinType(tName) > 0)
		DoWindow /F $tName
		return 0
	endif
	
	if (chanNum < 0)
		cbgn = 0
		cend = NMNumChannels()
	endif
	
	Make /O/N=(numpnts($wname)) $wname2
	Wave wtemp = $wname2
	wtemp = x
	
	Edit /K=1/N=$tName $wname2 as "Click \"Order Waves\" to re-order"
	SetWindow $tName hook=NMChanWaveListTableHook
	Execute /Z "ModifyTable title(Point)= \"Order\""
	
	SetCascadeXY(tName)
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		wname = ChanWaveListName(ccnt)
		
		if (WaveExists($wname) == 1)
			AppendToTable /W=$tName $wname
		endif
		
	endfor
	
	RemoveFromTable /W=$tName $wname2
	
	AppendToTable /W=$tName $wname2

End // NMChanWaveListOrderTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListTableHook(infoStr)
	String infoStr
	
	String event= StringByKey("EVENT", infoStr)
	String win= StringByKey("WINDOW", infoStr)
	
	String wList = WaveList("*", ";","WIN:"+ win)
	
	if (ItemsInList(wList) <= 1)
		return -1
	endif

	strswitch(event)
		case "kill":
			NMChanWaveListOrder(wList)
	endswitch

End // NMChanWaveListTableHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListOrder(wList)
	String wList

	Variable wcnt
	String wname, wname2 = "wNames_Order"
	
	if (WaveExists($wname2) == 0)
		return -1
	endif
	
	wList = RemoveFromList(wname2, wList)
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wname = StringFromList(wcnt, wList)
		
		if ((WaveExists($wname) == 0) || (numpnts($wname) != numpnts($wname2)))
			Print "Failed to order waves."
			continue
		endif
		
		Sort $wname2, $wname
		
	endfor
	
	Sort $wname2, $wname2
	
	Wave wtemp = $wname2
	
	wtemp = x
	
	ChanWaves2WaveList()

End // NMChanWaveListOrder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentWaveName()

	return ChanWaveName(-1, -1)

End // CurrentWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanWaveName(chanNum, waveNum)
	Variable chanNum // channel number (pass -1 for current)
	Variable waveNum // wave number (pass -1 for current)
	
	// return name of wave from wave ChanWaveList, given channel and wave number
	
	if (WaveExists(ChanWaveList) == 0) // new wave implemented in version 1.6
		return ""
	endif
	
	Wave /T ChanWaveList
	
	if (chanNum == -1)
		chanNum = NMCurrentChan()
	endif
	
	if (chanNum >= numpnts(ChanWaveList))
		return ""
	endif
	
	if (waveNum == -1)
		waveNum = NMCurrentWave()
	endif
	
	return StringFromList(waveNum, ChanWaveList[chanNum])

End // ChanWaveName

//****************************************************************
//
//	GetWaveName()
//	return NM wave name string, given prefix, channel and wave number
//
//****************************************************************

Function /S GetWaveName(prefix, chanNum, waveNum)
	String prefix // wave prefix name (pass "default" to use data's WavePrefix)
	Variable chanNum // channel number (pass -1 for none)
	Variable waveNum // wave number
	
	String name
	
	if ((StringMatch(prefix, "default") == 1) || (StringMatch(prefix, "Default") == 1))
		prefix = StrVarOrDefault("WavePrefix", "Wave")
	endif
	
	if (chanNum == -1)
		name = prefix + num2str(waveNum)
	else
		name = prefix + ChanNum2Char(chanNum) + num2str(waveNum)
	endif
	
	return name

End // GetWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetWaveNamePadded(prefix, chanNum, waveNum, maxNum)
	String prefix // wave prefix name (pass "default" to use data's WavePrefix)
	Variable chanNum // channel number (pass -1 for none)
	Variable waveNum // wave number
	Variable maxNum
	
	Variable pad, icnt
	String name, snum
	
	pad = strlen((num2str(maxNum)))
	
	if ((StringMatch(prefix, "default") == 1) || (StringMatch(prefix, "Default") == 1))
		prefix = StrVarOrDefault("WavePrefix", "Wave")
	endif
	
	snum = num2str(waveNum)
	
	for (icnt = strlen(snum); icnt < pad; icnt += 1)
		snum = "0" + snum
	endfor
	
	if (chanNum == -1)
		name = prefix + snum
	else
		name = prefix + ChanNum2Char(chanNum) + snum
	endif
	
	return name

End // GetWaveNamePadded

//****************************************************************
//
//	NextWaveNum()
//
//****************************************************************

Function NextWaveNum(df, prefix, chanNum, overwrite)
	String df // data folder
	String prefix // wave prefix name
	Variable chanNum // channel number (pass -1 for none)
	Variable overwrite // overwrite flag: (1) return last name in sequence (0) return next name in sequence
	
	Variable count
	String wName
	
	if (strlen(df) > 0)
		df = LastPathColon(df, 1)
	endif
	
	for (count = 0; count <= 9999; count += 1) // search thru sequence numbers
	
		if (chanNum == -1)
			wName = df + prefix + num2str(count)
		else
			wName = df + prefix+ ChanNum2Char(chanNum) + num2str(count)
		endif
		
		if (WaveExists($wName) == 0)
			break
		endif
		
	endfor
	
	if ((overwrite == 0) || (count == 0))
		return count
	else
		return (count-1)
	endif

End // NextWaveNum

//****************************************************************
//
//	NextWaveName()
//	return wave name in a sequence, given prefix and channel number
//
//****************************************************************

Function /S NextWaveName(prefix, chanNum, overwrite) 
	String prefix // wave prefix name
	Variable chanNum // channel number (pass -1 for none)
	Variable overwrite // overwrite flag: (1) return last name in sequence (0) return next name in sequence
	
	NMCmdHistory("NextWaveName", "DEPRECATED. Please change your code to use NextWaveName2.")
	
	return NextWaveName2("", prefix, chanNum, overwrite) 
	
End // NextWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NextWaveName2(df, prefix, chanNum, overwrite) 
	String df // data folder (enter "" for current data folder)
	String prefix // wave prefix name
	Variable chanNum // channel number (pass -1 for none)
	Variable overwrite // overwrite flag: (1) return last name in sequence (0) return next name in sequence
	
	Variable waveNum = NextWaveNum(df, prefix, chanNum, overwrite)
	
	return GetWaveName(prefix, chanNum, waveNum)
	
End // NextWaveName2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NextWaveNamePadded(df, prefix, chanNum, overwrite, maxNum) 
	String df // data folder
	String prefix // wave prefix name
	Variable chanNum // channel number (pass -1 for none)
	Variable overwrite // overwrite flag: (1) return last name in sequence (0) return next name in sequence
	Variable maxNum
	
	Variable waveNum = NextWaveNum(df, prefix, chanNum, overwrite)
	
	return GetWaveNamePadded(prefix, chanNum, waveNum, maxNum)
	
End // NextWaveNamePadded

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveNum(wName) // return wave number, given name
	String wName // wave name
	
	Variable ccnt, found
	
	if (WaveExists(ChanWaveList) == 0)
		return -1
	endif
	
	Wave /T ChanWaveList
	
	for (ccnt = 0; ccnt < numpnts(ChanWaveList); ccnt += 1)
	
		found = WhichListItemLax(wName, ChanWaveList[ccnt], ";")
		
		if (found >= 0)
			return found
		endif
		
	endfor
	
	return -1

End // ChanWaveNum

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Display Functions (Computer Stats and Window Cascade)
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckComputerXYpixels()

	String df = NMDF()
	
	Variable v1, v2, xpix = 900, ypix = 700, new
	
	Variable xp = NumVarOrDefault(df+"xPixels", -1)
	Variable yp = NumVarOrDefault(df+"yPixels", -1)
	
	String s0 = IgorInfo(0)
	
	s0 = StringByKey("SCREEN1", s0, ":")
	
	sscanf s0, "%*[DEPTH=]%d%*[,RECT=]%d%*[,]%d%*[,]%d%*[,]%d", v1, v1, v1, v1, v2
	
	if ((numtype(v1) == 0) && (v1 > 200))
		xpix = v1
	endif
	
	if ((numtype(v2) == 0) && (v2 > 100))
		ypix = v2
	endif
	
	if (xp > xpix)
		SetNMvar(df+"xPixels", xpix)
		new = 1
	endif
	
	if (yp > ypix)
		SetNMvar(df+"yPixels", ypix)
		new = 1
	endif
	
	return new

End // CheckComputerXYpixels

//****************************************************************
//****************************************************************
//****************************************************************

Function NMComputerCall(dialogue) // set computer type and display screen dimensions
	Variable dialogue // (0) no (1) yes
	
	Variable v1, v2, xpix = 900, ypix = 700
	String vlist = "", comp  = "pc", df = NMDF()
	
	String s0 = IgorInfo(2)
	
	strswitch(s0)
		case "Macintosh":
			comp = "mac"
			break
	endswitch
	
	s0 = IgorInfo(0)
	s0 = StringByKey("SCREEN1", s0, ":")
	
	sscanf s0, "%*[DEPTH=]%d%*[,RECT=]%d%*[,]%d%*[,]%d%*[,]%d", v1, v1, v1, v1, v2
	
	if (v1 > 200)
		xpix = v1
	endif
	
	if (v2 > 100)
		ypix = v2
	endif
	
	if (dialogue == 1)
	
		Prompt xpix, "number of x pixels:"
		Prompt ypix, "number of y pixels:"
		Prompt comp, " ", popup "mac;pc"
		DoPrompt "Auto Detection Results", xpix, ypix, comp
		
		if (V_flag == 1)
			return 0 // cancel
		endif
		
		vlist = NMCmdStr(comp, vlist)
		vlist = NMCmdNum(xpix, vlist)
		vlist = NMCmdNum(ypix, vlist)
		NMCmdHistory("NMComputerStats", vlist)
		
	endif
	
	return NMComputerStats(comp, xpix, ypix)

End // NMComputerCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMComputerStats(compType, xPixels, yPixels)
	String compType // computer type ("mac" or "pc")
	Variable xPixels, yPixels // screen dimensions
	
	String df = NMDF()
	
	strswitch(compType)
		case "macintosh":
		case "mac":
			SetNMstr(df+"Computer", "mac")
			break
		case "pc":
			SetNMstr(df+"Computer", "pc")
			break
	endswitch
	
	if ((numtype(xPixels) == 0) && (xPixels > 0))
		SetNMvar(df+"xPixels", xPixels)
	endif
	
	if ((numtype(yPixels) == 0) && (yPixels > 0))
		SetNMvar(df+"yPixels", yPixels)
	endif
	
	return 0

End // NMComputerStats

//****************************************************************
//****************************************************************
//****************************************************************

Function SetCascadeXY(gName) // set cascade graph size and placement
	String gName // graph name to move
	
	Variable wx1, wy1, width, height
	String df = NMDF()
	
	Variable xPixels = NumVarOrDefault(df+"xPixels", 1000)
	Variable yPixels = NumVarOrDefault(df+"yPixels", 700)
	Variable Cascade = NumVarOrDefault(df+"Cascade", 0)
	
	String Computer = StrVarOrDefault(df+"Computer", "mac")
	
	if (WinType(gName) == 0)
		return -1
	endif
	
	strswitch(Computer)
		case "pc":
			wx1 = 75 +15*Cascade
			wy1 = 75 +15*Cascade
			width = 425
			height = 275
			break
		default:
			wx1 = 50 + 28*Cascade
			wy1 = 50 + 28*Cascade
			width = 525
			height = 340
	endswitch
	
	MoveWindow /W=$gname wx1, wy1, (wx1+width), (wy1+height)
	
	if ((wx1 > xPixels * 0.4) || (wy1 > yPixels * 0.4))
		Cascade = 0 // reset Cascade counter
	else
		Cascade += 1 // increment Cascade counter
	endif
	
	SetNMvar(df+"Cascade", cascade)

End // SetCascadeXY

//****************************************************************
//****************************************************************
//****************************************************************

Function ResetCascadeCall()

	NMCmdHistory("ResetCascade","")
	
	return ResetCascade()

End // ResetCascadeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ResetCascade() // reset Cascade graph counter

	SetNMvar(NMDF() + "Cascade", 0)
	
	return 0
	
End // ResetCascade

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NM history/notebook functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMHistoryCall()
	String df = NMDF()
	
	Variable history = NumVarOrDefault(df+"WriteHistory",1) + 1
	
	Prompt history, "print function results to:", popup "nowhere;Igor history;Igor notebook;both;"
	DoPrompt "NeuroMatic Results History", history
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	history -= 1
	
	NMCmdHistory("NMHistorySelect", NMCmdNum(history, ""))
	
	return NMHistorySelect(history)

End // NMHistoryCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMHistorySelect(history)
	Variable history
	
	SetNMvar(NMDF()+"WriteHistory", history)
	
	return history
	
End // NMHistorySelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCmdHistoryCall()
	String df = NMDF()
	
	Variable cmdhistory = NumVarOrDefault(df+"CmdHistory", 1) + 1
	
	Prompt cmdhistory "print function commands to:", popup "nowhere;Igor history;Igor notebook;both;"
	DoPrompt "NeuroMatic Commands History", cmdhistory
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	cmdhistory -= 1
	
	NMCmdHistory("NMCmdHistorySelect", NMCmdNum(cmdhistory, ""))
	
	return NMCmdHistorySelect(cmdhistory)

End // NMCmdHistoryCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCmdHistorySelect(cmdhistory)
	Variable cmdhistory
	
	SetNMvar(NMDF()+"CmdHistory", cmdhistory)
	
	return cmdhistory
	
End // NMCmdHistorySelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMHistoryManager(message, where) // print notes to Igor history and/or notebook
	String message
	Variable where // use negative numbers for command history
	
	String nbName
	
	if (where == 0)
		return 0
	endif
	
	if ((abs(where) == 1) || (abs(where) == 3))
		Print message // Igor History
	endif
	
	if ((where == 2) || (where == 3)) // results notebook
		nbName = NMNotebookName("results")
		NMNotebookResults()
		Notebook $nbName selection={endOfFile, endOfFile}
		NoteBook $nbName text="\r" + message
	elseif ((where == -2) || (where == -3)) // command notebook
		nbName = NMNotebookName("commands")
		NMNotebookCommands()
		Notebook $nbName selection={endOfFile, endOfFile}
		NoteBook $nbName text="\r" + message
	endif

End // NMHistoryManager

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNotebookName(select)
	String select // "results" or "commands"
	
	strswitch(select)
		case "results":
			return NMPrefix("ResultsHistory")
		case "commands":
			return NMPrefix("CommandHistory")
	endswitch
	
	return ""

End // NMNotebookName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotebookResults()

	String nbName = NMNotebookName("results")
		
	if (WinType(nbName) == 5) // create new notebook
		return 0
	endif
	
	NewNotebook /F=0/N=$nbName/W=(0,0,0,0) as "NeuroMatic Results Notebook"
	SetCascadeXY(nbName)
	
	NoteBook $nbName text="Date: " + date()
	NoteBook $nbName text="\rTime: " + time()
	NoteBook $nbName text="\r"

End // NMNotebookResults

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotebookCommands()

	String nbName = NMNotebookName("commands")

	if (WinType(nbName) == 5) // create new notebook
		return 0
	endif
	
	NewNotebook /F=0/N=$nbName/W=(400,100,800,400) as "NeuroMatic Command Notebook"
	
	NoteBook $nbName text="Date: " + date()
	NoteBook $nbName text="\rTime: " + time()
	NoteBook $nbName text="\r\r**************************************************************************************"
	NoteBook $nbName text="\r**************************************************************************************"
	NoteBook $nbName text="\r***\tNote: the following commands can be copied to an Igor procedure file"
	NoteBook $nbName text="\r***\t(such as NM_MyTab.ipf) and used in your own macros or functions."
	NoteBook $nbName text="\r***\tFor example:"
	NoteBook $nbName text="\r***"
	NoteBook $nbName text="\r***\t\tMacro MyMacro()"
	NoteBook $nbName text="\r***\t\t\tNMChanSelect( \"A\" )"
	NoteBook $nbName text="\r***\t\t\tNMWaveSelect( \"Set1\" )"
	NoteBook $nbName text="\r***\t\t\tNMPlot( \"rainbow\" , 0 , 0 )"
	NoteBook $nbName text="\r***\t\t\tNMBslnWaves( 0 , 15 )"
	NoteBook $nbName text="\r***\t\t\tNMAvgWaves( 1 , 0 , 1 , 0 , 0 , 0 )"
	NoteBook $nbName text="\r***\t\tEnd"
	NoteBook $nbName text="\r***"
	NoteBook $nbName text="\r**************************************************************************************"
	NoteBook $nbName text="\r**************************************************************************************"

End // NMNotebookCommands

//****************************************************************
//****************************************************************
//****************************************************************

Function NMHistory(message) // print notes to Igor history and/or notebook
	String message
	
	NMHistoryManager(message, NumVarOrDefault(NMDF()+"WriteHistory", 1))

End // NMHistory

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCmdHistory(funcName, varList) // print NM command to history
	String funcName // e.g. "NMCmdHistory"
	String varList // "5;8;10;\stest;" (\s for string)
	
	Variable icnt, comma
	String bullet, cmd, varStr, df = NMDF()
	
	Variable history = NumVarOrDefault(df+"WriteHistory", 1)
	Variable cmdhistory = NumVarOrDefault(df+"CmdHistory", 1)
	
	strswitch(StrVarOrDefault(df+"Computer", ""))
		case "pc":
			bullet = "•"
			break
		default:
			bullet = "¥"
	endswitch
	
	switch(cmdhistory)
		default:
			return 0
		case 1:
			cmd = "\r" + bullet + funcName + "("
			break
		case 2:
		case 3:
			cmd = "\r" + funcName + "("
			break
	endswitch
	
	for (icnt = 0; icnt < ItemsInList(varList); icnt += 1)
	
		varStr = StringFromList(icnt, varList)
		
		if (StringMatch(varStr[0,1], "\s") == 1) // string variable
			varStr = "\"" + varStr[2,inf] + "\"" 
		elseif (StringMatch(varStr[0,1], "\l") == 1) // string list
			varStr = "\"" + ChangeListSep(varStr[2,inf], ";") + "\""
		endif
		
		if (comma == 1)
			cmd += ","
		endif
		
		cmd += " " + varStr + " "
		
		comma = 1
		
	endfor
	
	cmd += ")"
	
	NMHistoryManager(cmd, -1*cmdhistory)
	
End // NMCmdHistory

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCmdStr(strVar, varList)
	String strVar, varList

	return AddListItem("\s"+strVar, varList, ";", inf)

End // NMCmdStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCmdList(strList, varList) // for ";" lists
	String strList, varList
	
	if (ItemsInList(strList) == 1)
		return NMCmdStr(StringFromList(0,strList), varList)
	endif

	return AddListItem("\l"+ChangeListSep(strList, ","), varList, ";", inf)

End // NMCmdStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCmdNum(numVar, varList)
	Variable numVar
	String varList

	return AddListItem(num2str(numVar), varList, ";", inf)

End // NMCmdNum

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Progress functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressToggle()
	
	Variable on = !NumVarOrDefault(NMDF()+"ProgFlag",0)
	
	NMCmdHistory("NMProgressOn", NMCmdNum(on,""))
	
	NMProgressOn(on)

End // NMProgressToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressOn(on) // set Progress flag
	Variable on // (0) no (1) yes, use ProgWin XOP
	
	if (on == 1)
		Execute /Z "ProgressWindow kill"
		if (V_flag != 0)
			DoAlert 0, "NeuroMatic Alert: ProgWin XOP cannot be located. This XOP can be downloaded from www.wavemetrics.com/Support/ftpinfo.html."
			on = 0
		endif
	else
		on = 0
	endif
	
	SetNMvar(NMDF()+"ProgFlag",  on)

End // NMProgressOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressCancel()

	return NumVarOrDefault("V_Progress", 0)

End // NMProgressCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function CallNMProgress(count, maxCount)
	Variable count, maxCount
	
	return CallProgress(count / (maxCount - 1))
	
End // CallNMProgress

//****************************************************************
//****************************************************************
//****************************************************************

Function CallProgress(fraction)
	Variable fraction // fraction of progress (0) create (1) kill prog window (-1) create candy (-2) spin
	
	// returns the value of V_Progress (WinProg XOP), or 0 if it does not exist
	
	String df = NMDF()
	
	Variable progflag = NumVarOrDefault(df+"ProgFlag",1)
	
	String ProgressStr = StrVarOrDefault(df+"ProgressStr", "")
	
	Variable xPixels = NumVarOrDefault(df+"xPixels", 1000)
	Variable yPixels = NumVarOrDefault(df+"yPixels", 700)
	Variable xProgress = NumVarOrDefault(df+"xProgress", xPixels/4)
	Variable yProgress = NumVarOrDefault(df+"yProgress", yPixels/4)
	
	String win, txt
	
	switch(ProgFlag)
	
		case 1: // ProgWin XOP (must be installed in Extensions folder)
		
			// Note, if cancel is selected, V_Progress = 1
		
			win = "win=(" + num2str(xProgress) + "," + num2str(yProgress) + ")"
			txt = "text=\"" + ProgressStr + "\""
		
			if (fraction == -1)
				Execute /Z "ProgressWindow open=candy, button=\"cancel\", buttonProc=NMProgCancel," + win + "," + txt
			elseif (fraction == -2)
				Execute /Z "ProgressWindow spin"
			elseif (fraction == 0)
				Execute /Z "ProgressWindow open, button=\"cancel\", buttonProc=NMProgCancel," + win + "," + txt
				KillVariables /Z V_Progress
			endif
			
			if (fraction >= 0)
				Execute /Z "ProgressWindow frac=" + num2str(fraction)
			endif
			
			if (fraction >= 1)
				Execute /Z "ProgressWindow kill"
				KillVariables /Z V_Progress
			endif
			
			break
			
		default:
			return 0
			
	endswitch
	
	Variable pflag = NumVarOrDefault("V_Progress", 0) // progress flag, set to 1 if user hits "cancel" on ProgWin
	
	if (pflag == 1)
		Execute /Z "ProgressWindow kill"
	endif
	
	NMProgressStr("")
	
	return pflag

End // CallProgress

//****************************************************************
//****************************************************************
//****************************************************************

Function ResetProgress()

	Execute /Z "ProgressWindow kill"
	KillVariables /Z V_Progress
	
End // ResetProgress

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgCancel(buttonNum, buttonName)
	Variable buttonNum
	String buttonName
	
	Execute /Z "ProgressWindow kill"
	
End // NMProgCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressStr(progStr)
	String progStr // progress message string

	SetNMstr(NMDF() + "ProgressStr", progStr)

End // NMProgressStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXYPanel() // set Progress X,Y location
	
	String df = NMDF()
	
	Variable xPixels = NumVarOrDefault(df+"xPixels", 1000)
	Variable yPixels = NumVarOrDefault(df+"yPixels", 700)
	Variable xProgress = NumVarOrDefault(df+"xProgress", xPixels/4)
	Variable yProgress = NumVarOrDefault(df+"yProgress", yPixels/4)
	
	Variable x2 = xProgress + 265
	Variable y2 = yProgress + 100
	
	DoWindow /K ProgPanel
	NewPanel /K=1/N=ProgPanel/W=(xProgress,yProgress,x2,y2) as "Set Progress Location"
	
	DrawText 10,25,"Move window to desired location and click..."
	
	Button ProgButton, pos={75,40}, title = "Save Location", size={100,20}, proc=NMProgressXYButton

End // NMProgressXYPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXYButton(ctrlName) : ButtonControl
	String ctrlName
	
	Variable x, y, scale = 1 // (4/3)
	
	GetWindow ProgPanel, wsize
	
	x = round(V_left*scale)
	y = round(V_top*scale)
	
	NMProgressXYCall(x, y)
	
	DoWindow /K ProgPanel
	
End // NMProgressXYButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXYCall(xpixels, ypixels)
	Variable xpixels, ypixels
	
	String vlist = ""

	vlist = NMCmdNum(xpixels, vlist)
	vlist = NMCmdNum(ypixels, vlist)
	NMCmdHistory("NMProgressXY", vlist)
	
	return NMProgressXY(xpixels, ypixels)

End // NMProgressXYCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXY(xpixels, ypixels)
	Variable xpixels, ypixels
	
	String df = NMDF()
	
	SetNMvar(df+"xProgress", xpixels)
	SetNMvar(df+"yProgress",ypixels)
	
	return 0

End // NMProgressXY

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Misc Utility Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMvar(varName, value) // set variable to passed value within folder
	String varName
	Variable value
	
	if (strlen(varName) == 0)
		return -1
	endif
	
	String path = GetPathName(varName, 1)

	if ((StringMatch(path, "") == 0) && (DataFolderExists(path) == 0))
		return -1
	endif

	if ((WaveExists($varName) == 1) && (WaveType($varName) > 0))
		NVAR tempVar = $varName
		tempVar = value
	else
		Variable /G $varName = value
	endif
	
	return 0

End // SetNMvar

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMstr(varName, strvalue) // set string to passed value within NeuroMatic folder
	String varName,  strvalue
	
	if (strlen(varName) == 0)
		return -1
	endif
	
	String path = GetPathName(varName, 1)
	
	if ((StringMatch(path, "") == 0) && (DataFolderExists(path) == 0))
		return -1
	endif

	if ((WaveExists($varName) == 1) && (WaveType($varName) == 0))
		SVAR tempStr = $varName
		tempStr = strvalue
	else
		String /G $varName = strvalue
	endif
	
	return 0

End // SetNMstr

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMwave(wavName, pnt, value)
	String wavName
	Variable pnt // point to set, or (-1) all points
	Variable value
	
	if (strlen(wavName) == 0)
		return -1
	endif
	
	String path = GetPathName(wavName, 1)
	
	if ((StringMatch(path, "") == 0) && (DataFolderExists(path) == 0))
		return -1
	endif
	
	if (WaveExists($wavName) == 0)
		CheckNMwave(wavName, pnt+1, Nan)
	endif
	
	Wave tempWave = $wavName
	
	if (pnt < 0)
		tempWave = value
	elseif (pnt < numpnts(tempWave))
		tempWave[pnt] = value
	endif
	
	return 0

End // SetNMwave

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMtwave(wavName, pnt, strvalue)
	String wavName
	Variable pnt // point to set, or (-1) all points
	String strvalue
	
	if (strlen(wavName) == 0)
		return -1
	endif
	
	String path = GetPathName(wavName, 1)
	
	if ((StringMatch(path, "") == 0) && (DataFolderExists(path) == 0))
		return -1
	endif
	
	if (WaveExists($wavName) == 0)
		CheckNMtwave(wavName, pnt+1, strvalue)
	endif
	
	Wave /T tempWave = $wavName
	
	if (pnt < 0)
		tempWave = strvalue
	elseif (pnt < numpnts(tempWave))
		tempWave[pnt] = strvalue
	endif
	
	return 0

End // SetNMtwave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMvar(varName, dflt)
	String varName
	Variable dflt
	
	SetNMvar(varName, NumVarOrDefault(varName, dflt))
	
End // CheckNMvar

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMstr(varName, dflt)
	String varName
	String dflt
	
	SetNMstr(varName, StrVarOrDefault(varName, dflt))
	
End // CheckNMstr

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMwave(wList, nPoints, defaultValue)
	String wList // wave list
	Variable nPoints // (-1) dont care
	Variable defaultValue
	
	CheckNMwaveOfType(wList, nPoints, defaultValue, "R")
	
End // CheckNMwave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMtwave(wList, nPoints, defaultValue)
	String wList
	Variable nPoints // (-1) dont care
	String defaultValue // NOT LONGER USED
	
	Variable wcnt, init
	String wname
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
		
		wname = StringFromList(wcnt, wList)
		init = 0
		
		if (WaveExists($wname) == 0)
			init = 1
		endif
		
		CheckNMwaveOfType(wname, nPoints, 0, "T")
		
		if ((init == 1) && (WaveType($wname) == 0))
			Wave /T wtemp = $wname
			wtemp = defaultValue
		endif
	
	endfor
	
End // CheckNMtwave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMwaveOfType(wList, nPoints, defaultValue, wType) // returns (0) did not make wave (1) did make wave
	String wList // wave list
	Variable nPoints // (-1) dont care
	Variable defaultValue
	String wType // (B) 8-bit signed integer (C) complex (D) double precision (I) 32-bit signed integer (R) single precision real (W) 16-bit signed integer
	// (UB, UI or UW) unsigned integers
	
	String wName, path
	Variable wcnt, nPoints2, makeFlag, error = 0
	
	if (nPoints < 0)
		nPoints = 128
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		nPoints2 = numpnts($wName)
		
		path = GetPathName(wName, 1)
		
		if ((StringMatch(path, "") == 0) && (DataFolderExists(path) == 0))
			error = -1
		endif
		
		makeFlag = 0
		
		if (WaveExists($wName) == 0)
		
			strswitch(wType)
				case "B":
					if ((WaveType($wName) & 0x08) != 1)
						makeFlag = 1
					endif
					break
				case "UB":
					if (((WaveType($wName) & 0x08) != 1) && ((WaveType($wName) & 0x40) != 1))
						makeFlag = 1
					endif
					break
				case "C":
					if ((WaveType($wName) & 0x01) != 1)
						makeFlag = 1
					endif
					break
				case "D":
					if ((WaveType($wName) & 0x04) != 1)
						makeFlag = 1
					endif
					break
				case "I":
					if ((WaveType($wName) & 0x20) != 1)
						makeFlag = 1
					endif
					break
				case "UI":
					if (((WaveType($wName) & 0x20) != 1) && ((WaveType($wName) & 0x40) != 1))
						makeFlag = 1
					endif
					break
				case "T":
					if (WaveType($wName) != 0)
						makeFlag = 1
					endif
					break
				case "W":
					if ((WaveType($wName) & 0x10) != 1)
						makeFlag = 1
					endif
					break
				case "UW":
					if (((WaveType($wName) & 0x10) != 1) && ((WaveType($wName) & 0x40) != 1))
						makeFlag = 1
					endif
					break
				case "R":
				default:
					if ((WaveType($wName) & 0x02) != 1)
						makeFlag = 1
					endif
			endswitch
		
		endif
			
		if ((WaveExists($wName) == 0) || makeFlag)
		
			strswitch(wType)
				case "B":
					Make /B/O/N=(nPoints) $wName = defaultValue
					break
				case "UB":
					Make /B/U/O/N=(nPoints) $wName = defaultValue
					break
				case "C":
					Make /C/O/N=(nPoints) $wName = defaultValue
					break
				case "D":
					Make /D/O/N=(nPoints) $wName = defaultValue
					break
				case "I":
					Make /I/O/N=(nPoints) $wName = defaultValue
					break
				case "T":
					Make /T/O/N=(nPoints) $wName = ""
					break
				case "UI":
					Make /I/U/O/N=(nPoints) $wName = defaultValue
					break
				case "W":
					Make /W/O/N=(nPoints) $wName = defaultValue
					break
				case "UW":
					Make /W/U/O/N=(nPoints) $wName = defaultValue
					break
				case "R":
				default:
					Make /O/N=(nPoints) $wName = defaultValue
			endswitch
			
		elseif ((WaveExists($wName) == 1) && (nPoints > 0))
		
			strswitch(wType)
			
				case "T":
				
					nPoints2 = numpnts($wName)
		
					if (nPoints > nPoints2)
						Redimension /N=(nPoints) $wName
						Wave /T wtemp = $wName
						wtemp[nPoints2,inf] = ""
					elseif (nPoints < nPoints2)
						Redimension /N=(nPoints) $wName
					endif
				
					break
			
				default:
		
					nPoints2 = numpnts($wName)
				
					if (nPoints > nPoints2)
						Redimension /N=(nPoints) $wName
						Wave wtemp2 = $wName
						wtemp2[nPoints2,inf] = defaultValue
					elseif (nPoints < nPoints2)
						Redimension /N=(nPoints) $wName
					endif
				
			endswitch
			
		endif
	
	endfor
	
	return error
	
End // CheckNMwaveOfType

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNoteString(wname)
	String wname // wave name with note
	
	Variable icnt
	String txt, txt2 = ""

	if (WaveExists($wname) == 0)
		return ""
	endif
	
	txt = note($wname)
	
	for (icnt = 0; icnt < strlen(txt); icnt += 1)
		if (char2num(txt[icnt]) == 13) // remove carriage return
			txt2 += ";"
		else
			txt2 += txt[icnt]
		endif
	endfor
	
	return txt2
	
End // NMNoteString

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNoteExists(wname, key)
String wname // wave name with note
	String key // "thresh", "tbgn", "tend", etc...

	if (WaveExists($wname) == 0)
		return 0
	endif
	
	if (numtype(NMNoteVarByKey(wname, key)) == 0)
		return 1
	endif
	
	if (strlen(NMNoteStrByKey(wname, key)) > 0)
		return 1
	endif
	
	return 0
	
End // NMNoteExists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNoteVarByKey(wname, key)
	String wname // wave name with note
	String key // "thresh", "tbgn", "tend", etc...

	if (WaveExists($wname) == 0)
		return Nan
	endif
	
	return str2num(StringByKey(key, NMNoteString(wname)))

End // NMNoteVarByKey

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNoteStrByKey(wname, key)
	String wname // wave name with note
	String key // "thresh", "tbgn", "tend", etc...

	if (WaveExists($wname) == 0)
		return ""
	endif
	
	return StringByKey(key, NMNoteString(wname))

End // NMNoteStrByKey

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNoteVarReplace(wname, key, replace)
	String wname // wave name with note
	String key // "thresh", "tbgn", "tend", etc...
	Variable replace // replace string
	
	NMNoteStrReplace(wname, key, num2str(replace))
	
End // NMNoteVarReplace

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNoteStrReplace(wname, key, replace)
	String wname // wave name with note
	String key // "thresh", "tbgn", "tend", etc...
	String replace // replace string
	
	Variable icnt, jcnt, found, sl = strlen(key)
	String txt
	
	if (WaveExists($wname) == 0)
		return -1
	endif
	
	txt = note($wname)
	
	for (icnt = 0; icnt < strlen(txt); icnt += 1)
		if (StringMatch(txt[icnt,icnt+sl-1], key) == 1)
			found = 1
			break
		endif
	endfor
	
	if (found == 0)
		Note $wname, key + ":" + replace
		return -1
	endif
	
	found = 0
	
	for (icnt = icnt+sl; icnt < strlen(txt); icnt += 1)
	
		if (StringMatch(txt[icnt,icnt], ":") == 1)
			found = icnt
			break
		endif
		
		if (StringMatch(txt[icnt,icnt], "=") == 1)
			found = icnt
			break
		endif
		
	endfor
	
	if (found == 0)
		return -1
	endif
	
	for (jcnt = icnt+1; jcnt < strlen(txt); jcnt += 1)
	
		if (StringMatch(txt[jcnt,jcnt], ";") == 1)
			found = jcnt
			break
		endif
		
		if (char2num(txt[jcnt]) == 13)
			found = jcnt
			break
		endif
		
	endfor
	
	txt = txt[0, icnt] + replace + txt[jcnt, inf]
	
	Note /K $wname
	Note $wname, txt

End // NMNoteStrReplace

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNoteDelete(wname, key)
	String wname // wave name with note
	String key // find line with this key
	
	Variable icnt, jcnt, found, replace, ibgn, iend, sl, kl = strlen(key)
	String txt
	
	if (WaveExists($wname) == 0)
		return -1
	endif
	
	txt = note($wname)
	
	do 
	
		sl = strlen(txt)
		found = 0
	
		for (icnt = sl-kl; icnt >= 0 ; icnt -= 1)
			if (StringMatch(txt[icnt,icnt+kl-1], key) == 1)
				found = 1
				break
			endif
		endfor
		
		if (found == 1)
		
			ibgn = Nan
			iend = Nan
		
			for (jcnt = icnt; jcnt >= 0; jcnt -= 1)
			
				if (StringMatch(txt[jcnt,jcnt], ";") == 1)
					ibgn = jcnt
					break
				endif
				
				if (char2num(txt[jcnt]) == 13)
					ibgn = jcnt
					break
				endif
				
			endfor
			
			if (numtype(ibgn) > 0)
				break
			endif
			
			for (jcnt = icnt; jcnt < sl; jcnt += 1)
			
				if (StringMatch(txt[jcnt,jcnt], ";") == 1)
					iend = jcnt+1
					break
				endif
				
				if (char2num(txt[jcnt]) == 13)
					iend = jcnt+1
					break
				endif
				
			endfor
			
			if (numtype(iend) > 0)
				txt = txt[0, ibgn]
			else
				txt = txt[0, ibgn] + txt[iend, inf]
			endif
			
			replace = 1
			
		else
		
			break
			
		endif
	
	
	while (1)
	
	
	if (replace == 0)
		return -1
	endif
	
	Note /K $wname
	Note $wname, txt

End // NMNoteDelete

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNoteLabel(xy, wList, defaultStr)
	String xy // "x" or "y"
	String wList
	String defaultStr
	
	Variable icnt
	String wName, xyLabel = ""
	
	if (ItemsInList(wList) == 0)
		return defaultStr
	endif
	
	for (icnt = 0; icnt < ItemsInList(wList); icnt += 1)
	
		wName = StringFromList(0, wList)
		xyLabel = NMNoteStrByKey(wName, xy+"Label")
		
		if (strlen(xyLabel) > 0)
			return xyLabel // returns first finding of label
		endif
	
	endfor
	
	return defaultStr

End // NMNoteLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNoteType(wName, wType, xLabel, yLabel, wNote)
	String wName, wType, xLabel, yLabel, wNote
	
	if (WaveExists($wName) == 1)
	
		Note /K $wName
		Note $wName, "Source:" + GetPathName(wName, 0)
		
		if (strlen(wType) > 0)
			Note $wName, "Type:" + wType
		endif
		
		if (strlen(yLabel) > 0)
			Note $wName, "YLabel:" + yLabel
		endif
		
		if (strlen(xLabel) > 0)
			Note $wName, "XLabel:" + xLabel
		endif
		
		if (strlen(wNote) > 0)
			Note $wName, wNote
		endif
		
	endif

End // NMNoteType

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNoteCheck(noteStr)
	String noteStr
	
	noteStr = NMReplaceChar(":", noteStr, ",")
	
	return noteStr
	
End // NMNoteCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPromptStr(title)
	String title
	
	return title + " : " + NMWaveSelectGet() + " : n=" + num2str(NumVarOrDefault("NumActiveWaves", 0))

End // NMPromptStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMReturnStr2Num(returnStr)
	String returnStr
	
	if (strlen(returnStr) > 0)
		return 1
	else
		return 0
	endif
	
End // NMReturnStr2Num

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCtrlName(prefix, ctrlName)
	String prefix // object prefix (i.e. "NM_")
	String ctrlName // control name (i.e. "NM_AddTab")
	
	Variable icnt = strsearch(ctrlName, prefix, 0, 2)
	
	if (icnt < 0)
		return ctrlName
	endif
	
	icnt += strlen(prefix)

	return ctrlName[icnt, inf] // (i.e. "AddTab")

End // NMCtrlName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixNext(pPrefix, wPrefix)
	String pPrefix // pre-prefix (i.e. "MN" or "ST")
	String wPrefix // wave prefix or ("") for current
	
	Variable icnt
	String newPrefix, wlist
	
	if (strlen(wPrefix) == 0)
		wPrefix = NMCurrentWavePrefix()
	endif
	
	if (StringMatch(wPrefix[0,1], pPrefix) == 1)
		icnt = strsearch(wPrefix, "_", 0)
		wPrefix = wPrefix[icnt+1,inf]
	endif
	
	newPrefix = pPrefix + "_" + wPrefix
	
	wlist = WaveList(newPrefix + "*", ";", "")
	
	if (ItemsInlist(wlist) == 0)
		return newPrefix
	endif
	
	for (icnt = 0; icnt < 99; icnt += 1)
	
		newPrefix = pPrefix + num2str(icnt) + "_" + wPrefix
		wlist = WaveList(newPrefix + "*", ";", "")
		
		if (ItemsInList(wlist) == 0)
			return newPrefix
		endif
		
	endfor
	
	return ""

End // NMPrefixNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetWaveUnits(xy, wName, defaultLabel)
	String xy // "x" or "y"
	String wName
	String defaultLabel
	
	if (ItemsInList(wName) > 0)
		wName = StringFromList(0, wName)
	endif
	
	if (WaveExists($wName) == 0)
		return defaultLabel
	endif
	
	String s = WaveInfo($wName, 0)
	
	if (StringMatch(xy, "x") == 1)
		s = StringByKey("XUNITS", s)
	elseif (StringMatch(xy, "y") == 1)
		s = StringByKey("DUNITS", s)
	else
		s = ""
	endif
	
	if (strlen(s) == 0)
		return NMNoteLabel(xy, wName, defaultLabel)
	endif
	
	return s
	
End // GetWaveUnits

//****************************************************************
//****************************************************************
//****************************************************************

Function RemoveWaveUnits(wName)
	String wName
	
	Variable xstart, dx
	
	if (WaveExists($wName) == 0)
		return -1
	endif
	
	dx = deltax($wName)
	xstart = leftx($wName)
	
	SetScale /P x, xstart, dx, "", $wName
	SetScale y, 0, 0, "", $wName

End // RemoveWaveUnits

//****************************************************************
//****************************************************************
//****************************************************************

