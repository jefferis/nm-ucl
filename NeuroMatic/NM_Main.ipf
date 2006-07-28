#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Main Functions, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	First release: 05 May 2002
//	Last modified: 31 Jan 2006
//
//	Data Analyses Software
//
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

Function CheckNM(force) // check NM Package folders
	Variable force

	Variable madeFolder
	String df = NMDF()
	
	SetIgorHook AfterFileOpenHook = FileBinOpenHook
	//SetIgorHook IgorQuitHook = MyIgorQuitHook
	
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
		CheckPackage("Import", 1)
		CheckPackage("Chan", 1)
		CheckNMPaths()
		CheckFileOpen("")
		
	endif
	
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

Function CheckNMversion()

	if (NumVarOrDefault(NMDF()+"NMversion", 0) != 1.91)
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

Function CheckCurrentFolder() // check if current NM folder is OK

	String df = NMDF()
	String currentFolder = StrVarOrDefault(df+"CurrentFolder", GetDataFolder(1))
	String thisFolder = GetDataFolder(1)
	
	if (NumVarOrDefault(df+"NMOn", 1) == 0)
		return 1
	endif

	if ((StringMatch(CurrentFolder, thisFolder) == 0) && (IsNMDataFolder("") == 1))
		
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
	
	UpdateNMPanelTitle()
	
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
	
	SetNMvar(df+"CurrentTab", 0) // set Main as current tab
	
	CheckNMDataFolders()
	CheckNMFolderList()
	ChanWaveListSet(0)
	
	SetNMvar(df+"NMversion", 1.91)
	
	MakeNMpanel()
	
	if (IsNMDataFolder("") == 1)
		UpdateCurrentWave()
	endif
	
	NMHistory("\rUpdated to NeuroMatic Version 1.91")
	
	return 0

End // ResetNM

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoStartNM()
	String df = NMDF()

	if (NumVarOrDefault(df+"AutoStart", 0) == 0)
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
		SetNMvar(df+"UpdateNMBlock", 0)
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
	ChanGraphsUpdate(0)
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

Function CheckNeuroMatic() // check NeuroMatic globals
	String df = NMDF()
	
	if (DataFolderExists(df) == 0)
		return -1
	endif
	
	CheckNMvar(df+"NMversion", 1.91)	// NeuroMatic version
	
	CheckNMvar(df+"NMOn", 1)			// NueorMatic (0) off (1) on
	CheckNMvar(df+"AutoStart", 1)			// auto-start NeuroMatic (0) no (1) yes
	CheckNMvar(df+"AutoPlot", 1)			// auto plot data upon loading file (0) no (1) yes
	CheckNMvar(df+"CountFrom", 0)		// first number to count from (0 or 1)
	CheckNMvar(df+"NameFormat", 1)		// wave name format (0) short (1) long
	CheckNMvar(df+"ProgFlag", 1)			// progress display (0) off (1) WinProg XOP of Kevin Boyce
	CheckNMvar(df+"OverWrite", 1)			// over-write (0) off (1) on
	CheckNMvar(df+"WriteHistory", 1)		// analysis history (0) off (1) Igor History (2) notebook (3) both
	CheckNMvar(df+"CmdHistory", 1)		// command history (0) off (1) Igor History (2) notebook (3) both
	CheckNMvar(df+"GroupsOn", 0)		// groups (0) on (1) off")
	CheckNMvar(df+"Cascade", 0)			// window cascade counter
	
	CheckNMstr(df+"PrefixList", "Record;Avg_;ST_;")
	CheckNMstr(df+"NMTabList", "Main;Stats;Spike;Event;MyTab;")
	
	CheckNMstr(df+"OpenDataPath", "")	// open data file path (i.e. C:Jason:TestData:)
	CheckNMstr(df+"SaveDataPath", "")	// save data file path (i.e. C:Jason:TestData:)
	
	CheckNMtwave(df+"FolderList", 0, "")	// wave of NM folder names

End // CheckNeuroMatic

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
			NewPath /Q/O OpenDataPath opath
		endif
	endif
	
	if (strlen(spath) > 0)
		PathInfo SaveDataPath
		if (StringMatch(spath, S_path) == 0)
			NewPath /Q/O SaveDataPath spath
		endif
	endif

End // CheckNMPaths

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCountFrom() // return value of CountFrom

	return NumVarOrDefault(NMDF() + "CountFrom", 0)

End // NMCountFrom

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

Function NMNameFormatToggle() // long name format toggle
	
	Variable format = !NumVarOrDefault(NMDF()+"NameFormat",1)
	
	NMCmdHistory("NMNameFormat", NMCmdNum(format,""))
	
	NMNameFormat(format)

End // NMNameFormatToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNameFormat(format)
	Variable format // (0) short (1) long
	
	SetNMvar(NMDF()+"NameFormat", BinaryCheck(format))

End // NMNameFormat

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
	Variable icnt
	
	for (icnt = strlen(wName)-1; icnt >= 0; icnt -= 1)
		if (numtype(str2num(wName[icnt])) != 0)
			break // found Channel letter
		endif
	endfor
	
	return (char2num(wName[icnt]) - 64 - 1) // return chan number, given wave name

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
		numchans = NumVarOrDefault("NumChannels", 0)
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
	
	NMCmdHistory("NMChanSelect", NMCmdStr(chanStr, ""))
	
	return NMChanSelect(chanStr)
	
End // NMChanSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelect(chanStr) // set current channel
	String chanStr // "A", "B", "C"... or "All" or ("") for current channel
	
	Variable chanNum
	
	if (strlen(chanStr) == 0)
		chanNum = NumVarOrDefault("CurrentChan", 0)
	elseif (StringMatch(chanStr, "All") == 1)
		chanNum = -1
	else
		chanNum = ChanChar2Num(chanStr)
	endif
	
	if (numtype(chanNum) > 0)
		return -1
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
	Variable currChan = NumVarOrDefault("CurrentChan", 0)
	
	if (WaveExists(ChanSelect) == 0)
		return 0
	endif
	
	Wave ChanSelect
	
	if (chanNum == -1)
		changeto = 0
	else
		changeto = chanNum
	endif
	
	if (changeto != currChan)
		changeto = -1
	endif
	
	if (chanNum == -1) // "All"
		currChan = 0
		ChanSelect = 1
	else
		currChan = chanNum
		ChanSelect = 0
		ChanSelect[chanNum] = 1
	endif
	
	SetNMvar("CurrentChan", currChan)
	
	if (changeto == -1)
		ChangeTab(currTab, currTab, TabList) // updates tab display waves
		ChanGraphsToFront()
	endif
	
	return currChan

End // CurrentChanSet

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
		chanNum = NumVarOrDefault("CurrentChan", 0)
	endif
	
	if (ItemsInList(wList) == 0)
		wList = NMChanWaveList(chanNum)
	endif

	return NMNoteLabel(xy, wList, defaultStr) // new Note Labels
	
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
		chanNum = NumVarOrDefault("CurrentChan", 0)
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
				break
				
			default:
				return -1
		
		endswitch
	
	endfor
	
	ChanGraphsUpdate(1)
	
	return 0

End // ChanLabelSet

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Chan Wave List Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveListSet(set) // update the list of wave names (ChanWaveList)
	Variable set // (0) check (1) set
	
	Variable ccnt, wcnt, nwaves, nmax, strict
	String wname, wList = "", allList = "", sList = ""
	
	String opstr = WaveListText0()
	
	Variable numChannels = NumVarOrDefault("NumChannels", 0)
	Variable numWaves = NumVarOrDefault("NumWaves", 0)
	
	String wPrefix = StrVarOrDefault("WavePrefix", "")
	String cPrefix = StrVarOrDefault("CurrentPrefix", wPrefix)
	
	CheckNMtwave("ChanWaveList", numChannels, "")
	
	Wave /T ChanWaveList
	
	if (numChannels == 0)
		return 0
	endif
	
	if (set == 1)
		ChanWaveList = ""
	endif
	
	for (ccnt = 0; ccnt < numChannels; ccnt += 1)

		if ((set == 0) && (ItemsInList(ChanWaveList[ccnt]) > 0))
			continue
		endif
			
		if (numChannels == 1)
			wList = WaveList(cPrefix + "*", ";", opstr)
		else
			wList = ChanWaveListSearch(cPrefix, ccnt)
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
			//DoAlert 0, "Warning: no waves located for channel " + ChanNum2Char(ccnt) + "."
			continue
		elseif (nwaves != NumWaves)
			//DoAlert 0, "Warning: located only " + num2str(nwaves) + " waves for channel " + ChanNum2Char(ccnt) + "."
		endif
		
		strict = ChanWaveListStrict(wList, ccnt)
		
		slist = SortListAlphaNum(wList, cPrefix)
		
		//if ((strict == 1) && (StringMatch(wList, slist) == 0))
		if (StringMatch(wList, slist) == 0)
		
			DoAlert 1, "Warning: waves beginning with prefix \"" + cPrefix + "\" are not listed in numerical order. Do you want to order them?"
			
			if (V_Flag == 1)
				wList = slist
			endif
			
		endif
	
		ChanWaveList[ccnt] = wList
		allList += wList
		
	endfor
	
	NumWaves = nmax

End // ChanWaveListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanWaveListSearch(wPrefix, chanNum) // return list of waves appropriate for channel
	String wPrefix // wave prefix
	Variable chanNum
	
	Variable wcnt, icnt, jcnt, seqnum
	String wList, wname, seqstr, olist = ""
	
	String chanstr = ChanNum2Char(chanNum)

	wList = WaveList(wPrefix + "*" + chanstr + "*", ";", WaveListText0())
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wname = StringFromList(wcnt, wList)
		
		for (icnt = strlen(wname)-1; icnt >= 0; icnt -= 1)
		
			if (StringMatch(wname[icnt,icnt], chanstr) == 1)
			
				seqstr = wname[icnt+1,inf]
				
				for (jcnt = 0; jcnt < strlen(seqstr); jcnt += 1)
					if (numtype(str2num(seqstr[jcnt])) > 0)
						return "" // not a sequence number
					endif
				endfor
			
				olist = AddListItem(wname, olist, ";", inf) // matches criteria
					
				break
				
			endif
			
		endfor
		
	endfor
	
	return olist

End // ChanWaveListSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveListStrict(wList, chan) // determine if strict NM ordering (e.g. RecordA0, RecordA1...)
	String wList // list of wave names
	Variable chan // channel number
	
	String wname, chanstr
	Variable wcnt, icnt, strict = 1, strict2 = 1, found, seqnum, lastnum
	
	if (ItemsInList(wList) == 0)
		return 0
	endif
	
	wname = StringFromList(0, wList)
	
	for (icnt = strlen(wname)-2; icnt >= 0; icnt -= 1)
		if (StringMatch(wname[icnt,icnt], ChanNum2Char(chan)) == 1)
			seqnum = str2num(wname[icnt+1,inf])
			if (numtype(seqnum) == 0)
				found = 1
				break
			endif
		endif
	endfor

	if (found == 0)
		return 0
	elseif (ItemsInList(wList) == 1)
		return 2
	endif
	
	chanstr = wname[icnt,icnt]
	
	lastnum = seqnum // first sequence number
	
	for (wcnt = 1; wcnt < ItemsInList(wList); wcnt += 1)
	
		wname = StringFromList(wcnt, wList)
		seqnum = str2num(wname[icnt+1,inf])
		
		if (StringMatch(wname[icnt,icnt], chanstr) == 0)
			strict = 0
		endif
		
		if (numtype(seqnum) != 0)
			strict = 0
			strict2 = 0
		endif
		
		if (seqnum <= lastnum)
			strict2 = 0
		endif
		
		lastnum = seqnum
		
	endfor

	return (strict + strict2) // (0) not strict (1) strict but unordered (2) strict and ordered

End // ChanWaveListStrict

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
		chanNum = NumVarOrDefault("CurrentChan", 0)
	endif
	
	if (chanNum >= numpnts(ChanWaveList))
		return ""
	endif
	
	if (waveNum == -1)
		waveNum = NumVarOrDefault("CurrentWave", 0)
	endif
	
	return StringFromList(waveNum, ChanWaveList[chanNum])

End // ChanWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveNum(wName) // return wave number, given name and channel
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
	
	if ((exists("WavSelect") != 1) || (exists("ChanSelect") != 1))
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

Function /S GetChanWaveList(chanNum)
	Variable chanNum // channel number (pass -1 for all currently selected channels)
	
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
//
//	Display Functions (Computer Stats and Window Cascade)
//
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
	
	NewNotebook /F=0/N=trythis/W=(0,0,0,0) as "NeuroMatic Results Notebook"
	DoWindow /C $nbName
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
	
	NewNotebook /F=0/N=trythis/W=(400,100,800,400) as "NeuroMatic Command Notebook"
	DoWindow /C $nbName
	
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
	NoteBook $nbName text="\r***\t\t\tNMPlot( \"\" )"
	NoteBook $nbName text="\r***\t\t\tNMBslnWaves( 0 , 15 )"
	NoteBook $nbName text="\r***\t\t\tNMAvgWaves( 2 , 1 , 0 , 0, 0 )"
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
			endif
			
			if (fraction >= 0)
				Execute /Z "ProgressWindow frac=" + num2str(fraction)
			endif
			
			if (fraction >= 1)
				Execute /Z "ProgressWindow kill"
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
	NewPanel /K=1/W=(xProgress,yProgress,x2,y2) as "Set Progress Location"
	DoWindow /C ProgPanel
	
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

	if (exists(varName) == 2)
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

	if (exists(varName) == 2)
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

Function CheckNMwave(wList, npnts, dflt)
	String wList // wave list
	Variable npnts // (-1) dont care
	Variable dflt
	
	String wName, path
	Variable wcnt, npnts2, error = 0
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		npnts2 = numpnts($wName)
		
		path = GetPathName(wName, 1)
		
		if ((StringMatch(path, "") == 0) && (DataFolderExists(path) == 0))
			error = -1
		endif
		
		if (exists(wName) == 0)
		
			if (npnts < 0)
				Make $wName = dflt
			else
				Make /N=(npnts) $wName = dflt
			endif
			
		elseif ((exists(wName) == 1) && (npnts >= 0))
		
			npnts2 = numpnts($wName)
		
			if (npnts > npnts2)
				Redimension /N=(npnts) $wName
				Wave wtemp = $wName
				wtemp[npnts2,inf] = dflt
			elseif (npnts < npnts2)
				Redimension /N=(npnts) $wName
			endif
			
		endif
	
	endfor
	
	return error
	
End // CheckNMwave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMtwave(wName, npnts, dflt)
	String wName
	Variable npnts // (-1) dont care
	String dflt
	
	Variable npnts2
	
	String path = GetPathName(wName, 1)
	
	if ((StringMatch(path, "") == 0) && (DataFolderExists(path) == 0))
		return -1
	endif
	
	if (exists(wName) == 0)
	
		if (npnts < 0)
			npnts = 0
		endif
		
		Make /T/N=(npnts) $wName = dflt
		
	elseif ((exists(wName) == 1) && (npnts >= 0))
	
		npnts2 = numpnts($wName)
		
		if (npnts > npnts2)
			Redimension /N=(npnts) $wName
			Wave /T wtemp = $wName
			wtemp[npnts2,inf] = dflt
		elseif (npnts < npnts2)
			Redimension /N=(npnts) $wName
		endif
		
	endif
	
	return 0
	
End // CheckNMtwave

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
	
	String xyLabel = ""
	
	if (WaveExists($wName) == 1)
	
		Note /K $wName
		Note $wName, "Source:" + GetPathName(wName, 0)
		
		if (strlen(wType) > 0)
			Note $wName, "Type:" + wType
		endif
		
		if (strlen(yLabel) > 0)
			xyLabel = "YLabel:" + yLabel
		endif
		
		if (strlen(xLabel) > 0)
			if (strlen(xyLabel) > 0)
				xyLabel += ";XLabel:" + xLabel + ";"
			else
				xyLabel = "XLabel:" + xLabel
			endif
		endif
		
		if (strlen(xyLabel) > 0)
			Note $wName, xyLabel
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

	return ctrlName[strlen(prefix), inf] // (i.e. "AddTab")

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
		wPrefix = StrVarOrDefault("CurrentPrefix", "")
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

