#pragma rtGlobals = 1
#pragma IgorVersion = 6.1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Main Functions
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//	Data Analyses Software
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	First release: 05 May 2002
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMVersion()

	return 2.5

End // NMVersion

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWebpage()

	BrowseURL /Z "http://www.neuromatic.thinkrandom.com/"

End // NMWebpage

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Package Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefix( objName ) // prefix ID
	String objName
	
	return "NM_" + objName

End NMPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDF() // return NeuroMatic's full-path folder

	return PackDF( "NeuroMatic" )
	
End // NMDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PackDF( fname ) // return Package path/subpath
	String fname
	
	// note, NM tabs are treated as individual packages
	
	String df = "root:Packages:"

	if ( strlen( fname ) > 0 )
		df += fname
	endif
	
	return LastPathColon( df, 1 )
	
End // PackDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckPackDF( fname ) // check Package data folder exists
	String fname // data folder
	
	String pdf = PackDF( "" ) // parent
	String df = PackDF( fname ) // sub
	
	if ( DataFolderExists( pdf ) == 0 )
		NewDataFolder $RemoveEnding( pdf, ":" )
	endif

	if ( DataFolderExists( df ) == 0 )
		NewDataFolder $RemoveEnding( df, ":" )
		return 1 // yes, made the folder
	endif
	
	return 0 // did not make folder

End // CheckPackDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckPackage( package, force ) // check folder/globals
	String package // package folder name
	Variable force // force variable check ( 0 ) no ( 1 ) yes
	
	String df = PackDF( package )
	
	Variable made = CheckPackDF( package ) // check folder
	
	if ( ( made == 0 ) && ( force == 0 ) )
		return 0
	endif
	
	// check package folder variables, i.e. "CheckStats()"

	Execute /Z "Check" + package + "()"
	
	// check package config folder and globals
	
	if ( made == 1 )
		NMConfig( package, -1 ) // copy configs to new folder
	else
		NMConfig( package, 1 ) // copy folder vars to configs
	endif
	
	// check old preferences
	
	strswitch( package )
	
		case "NeuroMatic":
			package = "NM"
			break
			
	endswitch
	
	if ( made == 1 )
		Execute /Z "NMPrefs(" + NMQuotes( package ) + ")"
	endif
	
	return made
	
End // CheckPackage

//****************************************************************
//****************************************************************
//****************************************************************

Function NeuroMaticConfigHook() // called from NMConfigEditHook

	CheckNMPaths() // set paths if they have changed

End // NeuroMaticConfigHook

//****************************************************************
//****************************************************************
//****************************************************************

Function IgorStartOrNewHook(igorApplicationNameStr)
	String igorApplicationNameStr

	CheckNMVersion()
	
End // IgorStartOrNewHook

//****************************************************************
//****************************************************************
//****************************************************************

Static Function BeforeExperimentSaveHook( refNum, fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr, fileKind )
	Variable refNum
	String fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr
	Variable fileKind
	
	KillNMPaths()
	
	return 0

End // BeforeExperimentSaveHook

//****************************************************************
//****************************************************************
//****************************************************************

Static Function AfterFileOpenHook( refNum, fileName, path, type, creator, kind )
	Variable refNum
	String fileName,path,type,creator
	Variable kind
	
	CheckNMVersion()
	
	if ( StringMatch( type,"IGsU" ) == 1 ) // Igor Experiment, packed
		CheckFileOpen( fileName )
	endif
	
	//MakeNMpanel()
	
	return 0
	
End // AfterFileOpenHook

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMVersion()

	if ( NumVarOrDefault( NMDF() + "NMversion", 0 ) != NMVersion() )
		ResetNM( 0 )
	endif

End // CheckNMVersion

//****************************************************************
//****************************************************************
//****************************************************************

Function ResetNMCall()

	NMCmdHistory( "ResetNM", NMCmdNum( 0,"" ) )
	
	return ResetNM( 0 )

End // ResetNMCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ResetNM( killFirst ) // use this function to re-initialize neuromatic
	Variable killfirst // kill variables first flag
	
	Variable version = NMVersion()
	
	if ( killfirst == 1 )
	
		DoAlert 1, "Warning: this function will re-initialize all of NeuroMatic global variables. Do you want to continue?"
	
		if ( V_Flag != 1 )
			return -1
		endif
	
	endif
	
	//CheckCurrentFolder() // must set this here, otherwise Igor is at root directory
	NMTabControlList()
	ChanGraphClose( -1, 0 )
	
	if ( killfirst == 1 )
		NMKill() // this is hard kill, and will reset previous global variables to default values
	endif
	
	CheckNM()
	
	SetNeuroMaticVar("CurrentTab", 0 ) // set Main Tab as current tab
	
	CheckNMDataFolders()
	CheckNMFolderList()
	NMChanWaveListSet( 0 )
	
	SetNeuroMaticVar("NMversion", version )
	
	MakeNMpanel()
	
	if ( IsNMDataFolder( "" ) == 1 )
		UpdateCurrentWave()
	endif
	
	NMHistory( "\rStarted NeuroMatic Version " + num2str( NMVersion() ) )
	
	return 0

End // ResetNM

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNM() // check NM Package folders

	Variable madeFolder, force = 1
	
	if ( NeuroMaticVar( "NMon" ) == 0 )
		return 1
	endif
	
	CheckPackDF( "Configurations" ) // places Config folder first
	
	madeFolder = CheckPackage( "NeuroMatic", force )
	
	NMProgressOn( NMProgFlagDefault() ) // test progress window

	CheckNMPaths()
	CheckFileOpen( "" )
	
	if ( madeFolder == 1 )
		NMConfigOpenAuto()
		CheckNMPaths()
		AutoStartNM()
		KillGlobals( "root:", "V_*", "110" ) // clean root
		KillGlobals( "root:", "S_*", "110" )
	endif
	
	return madeFolder

End // CheckNM

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoStartNM()

	if ( NeuroMaticVar( "AutoStart" ) == 0 )
		return 0
	endif
	
	if ( IsNMDataFolder( "" ) == 0 )
		NMFolderNew( "" )
	else
		UpdateNM( 1 )
	endif

End // AutoStartNM

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNM( force )
	Variable force
	
	String df = NMDF()
	
	Variable isNMfolder = IsNMDataFolder( GetDataFolder( 1 ) )

	if ( NumVarOrDefault( df+"UpdateNMBlock", 0 ) == 1 )
		KillVariables /Z $( df+"UpdateNMBlock" )
		return 0
	endif
	
	if ( WinType( "NMpanel" ) == 0 )
	
		if ( force == 0 )
			return 0 // nothing to update
		endif
		
		MakeNMpanel()
		
	else
	
		UpdateNMPanel( 1 )
		
	endif
	
	CheckNMFolderList()
	
	if ( isNMfolder == 1 )
		UpdateCurrentWave()
	endif
	
End // UpdateNM

//****************************************************************
//****************************************************************
//****************************************************************

Function NMKill() // use this with caution!

	String df = NMDF()

	DoWindow /K NMpanel

	KillTabs( NMTabControlList() ) // kill tab plots, tables and globals
	
	ChanGraphClose( -1, 0 ) // kill graphs
	
	if ( DataFolderExists( df ) == 1 )
		KillDataFolder $df
	endif
	
	df = PackDF( "Chan" )
	
	if ( DataFolderExists( df ) == 1 )
		KillDataFolder $df
	endif

End // NMKill

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Global Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNeuroMatic() // check main NeuroMatic globals

	CheckNMtwave( NMDF()+"FolderList", 0, "" )	// wave of NM folder names

End // CheckNeuroMatic

//****************************************************************
//****************************************************************
//****************************************************************

Function NeuroMaticVar( varName )
	String varName
	
	Variable defaultVal = Nan
	String df = NMDF()
	
	strswitch( varName )
	
		case "AutoStart":
			defaultVal = 1
			break
			
		case "AutoPlot":
			defaultVal = 0
			break
			
		case "AlertUser":
			defaultVal = 1
			break

		case "DeprecationAlert":
			defaultVal = 1
			break
			
		case "WriteHistory":
			defaultVal = 1
			break
		
		case "CmdHistory":
			defaultVal = 1
			break
			
		case "OverWrite":
			defaultVal = 1
			break
			
		case "ImportPrompt":
			defaultVal = 1
			break
			
		case "LockFolders":
			defaultVal = 1
			break
			
		case "WaveSkip":
			defaultVal = 1
			break
			
		case "NMon":
			defaultVal = 1
			break
	
		case "NMversion":
			defaultVal = NMVersion()
			break
			
		case "CurrentTab":
			defaultVal = 0
			break
			
		case "Cascade":
			defaultVal = 0
			break
			
		case "NumActiveWaves":
			defaultVal = 0
			break
			
		case "CurrentWave":
			defaultVal = 0
			break
			
		case "CurrentGrp":
			defaultVal = 0
			break
			
		case "GroupsOn":
			defaultVal = 1
			break
			
		case "SumSet0":
			defaultVal = 0
			break
			
		case "SumSet1":
			defaultVal = 0
			break
			
		case "SumSet2":
			defaultVal = 0
			break
			
		case "ProgFlag":
			defaultVal = 1
			break
			
		case "xProgress":
			defaultVal = Nan // will be computed in NMProgressX
			break
			
		case "yProgress":
			defaultVal = Nan // will be computed in NMProgressY
			break
			
		case "NMProgressCancel":
			defaultVal = 0
			break
			
		case "SetsAutoAdvance":
			defaultVal = 0
			break
			
		case "StimRetrieveAs":
			defaultVal = 1
			break
			
		case "NMDeleteWavesNoAlert":
			defaultVal = 0
			break
			
		case "ChangePrefixPrompt":
			defaultVal = 1
			break
			
		case "OrderWaves":
			defaultVal = 2
			break
			
		case "DragOn":
			defaultVal = 1
			break
			
		case "AutoDoUpdate":
			defaultVal = 1
			break
			
		default:
			NMDoAlert( "NeuroMaticVar Error: no variable called " + NMQuotes( varName ) )
			return Nan
	
	endswitch
	
	return NumVarOrDefault( df+varName, defaultVal )
	
End // NeuroMaticVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NeuroMaticStr( varName )
	String varName
	
	String defaultStr = "", ndf = NMDF()
	
	strswitch( varName )
	
		case "OrderWavesBy":
			defaultStr = "name"
			break
			
		case "FolderPrefix":
			defaultStr = "nm"
			break
			
		case "PrefixList":
			defaultStr = "Record;Avg;"
			break
			
		case "NMTabList":
			defaultStr = "Main;Stats;Spike;Event;Fit;"
			break
			
		case "TabControlList":
			defaultStr = ""
			break
			
		case "OpenDataPath":
			defaultStr = ""
			break
			
		case "SaveDataPath":
			defaultStr = ""
			break
			
		case "CurrentFolder":
			defaultStr = ""
			break
			
		case "WaveSelectAdded":
			defaultStr = ""
			break
			
		case "ProgressStr":
			defaultStr = ""
			break
			
		case "ErrorStr":
			defaultStr = ""
			
		default:
			NMDoAlert( "NeuroMaticStr Error: no variable called " + NMQuotes( varName ) )
			return ""
	
	endswitch
	
	return StrVarOrDefault( ndf + varName, defaultStr )
			
End // NeuroMaticStr

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNeuroMaticVar( varName, value )
	String varName
	Variable value
	
	return SetNMvar( NMDF()+varName, value )
	
End // SetNeuroMaticVar

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNeuroMaticStr( varName, strValue )
	String varName
	String strValue
	
	return SetNMstr( NMDF()+varName, strValue )
	
End // SetNeuroMaticStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NeuroMaticConfigs()

	String fname = "NeuroMatic"

	NeuroMaticConfigVar( "AutoStart", "Auto-start NM ( 0 ) no ( 1 ) yes" )
	NeuroMaticConfigVar( "AutoPlot", "Auto plot data upon loading file ( 0 ) no ( 1 ) yes" )
	
	NeuroMaticConfigVar( "WriteHistory", "Analysis history ( 0 ) off ( 1 ) Igor History ( 2 ) notebook ( 3 ) both" )
	NeuroMaticConfigVar( "CmdHistory", "Command history ( 0 ) off ( 1 ) Igor History ( 2 ) notebook ( 3 ) both" )
	
	NeuroMaticConfigVar( "ImportPrompt", "Import prompt ( 0 ) off ( 1 ) on" )
	NeuroMaticConfigVar( "AlertUser", "Alert user ( 0 ) never ( 1 ) by DoAlert Prompt ( 2 ) by NM history" )
	NeuroMaticConfigVar( "DeprecationAlert", "Deprecated function alert ( 0 ) off ( 1 ) on" )
	
	NeuroMaticConfigVar( "xProgress", "progress window x pixel position, ( Nan ) for automatic placement" )
	NeuroMaticConfigVar( "yProgress", "progress window y pixel position, ( Nan ) for automatic placement" )
	
	NeuroMaticConfigVar( "LockFolders", "Lock folders to prevent accidental deletion? ( 0 ) no ( 1 ) yes" )
	
	NeuroMaticConfigStr( "OrderWavesBy", "Order waves by \"name\" or creation \"date\"" )
	NeuroMaticConfigStr( "FolderPrefix", "NM folder prefix" )
	NeuroMaticConfigStr( "PrefixList", "List of wave prefix names" )
	NeuroMaticConfigStr( "NMTabList", "List of NM tabs" )
	
	NeuroMaticConfigStr( "OpenDataPath", "Open data file path ( i.e. C:Jason:TestData: )" )
	NeuroMaticConfigStr( "SaveDataPath", "Save data file path ( i.e. C:Jason:TestData: )" )
			
End // NeuroMaticConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function NeuroMaticConfigVar( varName, description )
	String varName
	String description
	
	return NMConfigVar( "NeuroMatic", varName, NeuroMaticVar( varName ), description )
	
End // NeuroMaticConfigVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NeuroMaticConfigStr( varName, description )
	String varName
	String description
	
	return NMConfigStr( "NeuroMatic", varName, NeuroMaticStr( varName ), description )
	
End // NeuroMaticConfigStr

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMPaths()
	
	String opath = NeuroMaticStr( "OpenDataPath" )
	String spath = NeuroMaticStr( "SaveDataPath" )
	
	if ( strlen( opath ) > 0 )
	
		PathInfo OpenDataPath
		
		if ( StringMatch( opath, S_path ) == 0 )
			NewPath /O/Q/Z OpenDataPath opath
		endif
		
	endif
	
	if ( strlen( spath ) > 0 )
	
		PathInfo SaveDataPath
		
		if ( StringMatch( spath, S_path ) == 0 )
			NewPath /O/Q/Z SaveDataPath spath
		endif
		
	endif

End // CheckNMPaths

//****************************************************************
//****************************************************************
//****************************************************************

Function KillNMPaths()
	
	PathInfo igor
	
	if (V_flag == 0)
		return -1
	endif
	
	PathInfo NMPath
	
	if ( V_flag == 1 )
		NewPath /O/Q NMPath, S_path
		KillPath /Z NMPath
	endif
	
	PathInfo OpenDataPath
	
	if ( V_flag == 1 )
		NewPath /O/Q OpenDataPath, S_path
		KillPath /Z OpenDataPath
	endif
	
	PathInfo SaveDataPath
	
	if ( V_flag == 1 )
		NewPath /O/Q SaveDataPath, S_path
		KillPath /Z SaveDataPath
	endif
	
	PathInfo ClampPath
	
	if ( V_flag == 1 )
		NewPath /O/Q ClampPath, S_path
		KillPath /Z ClampPath
	endif
	
	PathInfo StimPath
	
	if ( V_flag == 1 )
		NewPath /O/Q StimPath, S_path
		KillPath /Z StimPath
	endif
	
	PathInfo OpenAllPath
	
	if ( V_flag == 1 )
		NewPath /O/Q OpenAllPath, S_path
		KillPath /Z OpenAllPath
	endif

End // KillNMPaths

//****************************************************************
//****************************************************************
//****************************************************************

Function NMon( on )
	Variable on // ( 0 ) off ( 1 ) on ( -1 ) toggle
	
	if ( on == -1 )
		on = BinaryInvert( NeuroMaticVar( "NMon" ) )
	else
		on = BinaryCheck( on )
	endif
	
	SetNeuroMaticVar("NMon", on )
	
	if ( on == 0 )
		DoWindow /K NMpanel
	else
		MakeNMpanel()
	endif
	
	return on

End // NMon

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Tab Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabsPossible()

	return "Main;Stats;Spike;MyTab;Event;Clamp;RiseT;PairP;MPFA;Art;Fit;EPSC;"
	
End // NMTabsPossible

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabsAvailable()

	Variable icnt
	String tname, aList = ""

	String tabList = NMTabsPossible()
	
	for (icnt = 0; icnt < ItemsInList(tabList); icnt += 1)
	
		tname = StringFromList(icnt, tabList)
		
		if ((exists(tname) == 6) || (exists(tname+"Tab") == 6))
			aList = AddListItem(tname, aList, ";", inf)
		endif
		
	endfor
	
	return aList

End // NMTabsAvailable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabsMake(force)
	Variable force // (0) check (1) make

	Variable icnt, tnum
	String tabName
	
	String tabCntrlList =  NeuroMaticStr( "TabControlList" )
	String currentList = NMTabListConvert(tabCntrlList)
	String defaultList =  NeuroMaticStr( "NMTabList" )
	
	if ((force == 1) || (StringMatch(currentList, defaultList) == 0))
	
		for (icnt = 0; icnt < ItemsInList(currentList); icnt += 1)
		
			tabName = StringFromList(icnt, currentList)
			
			if (WhichListItem(tabName, defaultList, ";", 0, 0) < 0)
				tnum = WhichListItem(tabName, currentList, ";", 0, 0)
				KillTabControls(tnum, tabCntrlList)
			endif
			
		endfor
		
		ClearTabs(tabCntrlList) // clear old tabs
		SetNeuroMaticStr( "TabControlList", "" ) // clear old list
		tabCntrlList = NMTabControlList() // update control list
		MakeTabs(tabCntrlList)
		CheckNMTabs(1)
		
	endif
	
End // NMTabsMake

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabControlList()
	
	Variable icnt
	String tabName, prefix
	
	String tabCntrlList = NeuroMaticStr( "TabControlList" ) // current list of tabs in TabManager format
	String currentList = NMTabListConvert(tabCntrlList)
	String defaultList =  NeuroMaticStr( "NMTabList" )
	
	String win = TabWinName(tabCntrlList)
	String tab = TabCntrlName(tabCntrlList)
	
	if ( DataFolderExists( NMDF() ) == 0 )
		return "" // nothing to do yet
	endif
	
	if ( (StringMatch(win, "NMPanel") == 1) && (StringMatch(tab, "NM_Tab") == 1) )
		
		if ( StringMatch(defaultList, currentList) == 0 )
			SetNeuroMaticStr( "NMTabList", currentList ) // defaultList has inappropriately changed
		endif
		
		return tabCntrlList // OK format
		
	endif
	
	// need to create tabCntrlList from defaultList
	
	if (ItemsInList(defaultList) == 0)
	
		if (ItemsInList(currentList) > 0)
			defaultList = currentList
		else
			defaultList = "Main;"
		endif
	
	endif
	
	tabCntrlList = ""
	
	for (icnt = 0; icnt < ItemsInList(defaultList); icnt += 1)
	
		tabName = StringFromList(icnt, defaultList)
		prefix = NMTabPrefix(tabName)
		
		if (strlen(prefix) > 0)
			tabCntrlList = AddListItem(tabName + "," + prefix, tabCntrlList, ";", inf)
		else
			NMHistory("NM Tab Entry Failure : " + tabName)
		endif
		
	endfor
	
	tabCntrlList = AddListItem("NMPanel,NM_Tab", tabCntrlList, ";", inf)
	
	SetNeuroMaticStr( "TabControlList", tabCntrlList )

	return tabCntrlList

End // NMTabListGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabPrefix(tabName)
	String tabName
	
	String df = NMDF()
	String prefix = StrVarOrDefault(df+tabName+"Prefix", "")
	
	// tab prefix string should reside in NMDF()
	// i.e. for Stats tab, StatsPrefix = "ST_"
	
	if (strlen(prefix) > 0)
		return prefix
	endif
	
	// attemp to create tab prefix name by calling new function (i.e. StatsPrefix())
	
	Execute /Z "SetNMstr(" + NMQuotes( df + tabName + "Prefix" ) + ", " + tabName + "Prefix("+NMQuotes("") + "))"
		
	return StrVarOrDefault(df+tabName+"Prefix", "")

End // NMTabPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabListConvert(tabCntrlList)
	String tabCntrlList // ('') for current
	Variable icnt
	
	String simpleList = ""
	
	if (strlen(tabCntrlList) == 0)
		tabCntrlList = NeuroMaticStr( "TabControlList" )
	endif
	
	for (icnt = 0; icnt < ItemsInList(tabCntrlList)-1; icnt += 1)
		simpleList = AddListItem(TabName(icnt, tabCntrlList), simpleList, ";", inf)
	endfor
	
	return simpleList
	
End // NMTabListConvert

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMTabs(force)
	Variable force
	Variable icnt
	
	String tabList = NMTabControlList()
	
	for (icnt = 0; icnt < NumTabs(tabList); icnt += 1) // go through each tab and check variables
		SetNeuroMaticVar( "UpdateNMBlock", 1 ) // block UpdateNM()
		CheckPackage(TabName(icnt, tabList), force)
		SetNeuroMaticVar( "UpdateNMBlock", 0 ) // unblock UpdateNM()
	endfor

End // CheckNMTabs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAutoTabCall()
	
	String TabList = NMTabControlList()
	
	Variable thisTab = NeuroMaticVar( "CurrentTab" )

	Variable error = CallTabFunction("Auto", thisTab, TabList)
	
	if (error != 0) // error occurred. try another tab function
		CallTabFunction("NMAuto", thisTab, TabList)
	endif

End // NMAutoTabCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTab(tabName) // change NMpanel tab
	String tabName
	
	String tabList = NMTabControlList()
	
	Variable tab = TabNumber(tabName, tabList) // NM_TabManager.ipf
	
	if (tab < 0)
		return -1
	endif
	
	Variable lastTab = NeuroMaticVar( "CurrentTab" )
	
	CheckCurrentFolder()
	
	if (tab != lastTab)
		SetNeuroMaticVar("CurrentTab", tab )
		ChangeTab(lastTab, tab, tabList) // NM_TabManager.ipf
		ChanGraphsUpdate()
	endif

End // NMTab

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMTabName()

	return TabName(NeuroMaticVar( "CurrentTab" ), NMTabControlList())

End // CurrentNMTabName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabKillCall()

	String tabList = NMTabControlList()
	
	if (strlen(tabList) == 0)
		return -1
	endif
	
	String tabName
	Prompt tabName, "choose tab:", popup TabNameList(tabList)
	DoPrompt "Kill Tab", tabName
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	NMCmdHistory("NMTabKill", NMCmdStr(tabName,""))
	
	return NMTabKill(tabName)

End // NMTabKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabKill(tabName)
	String tabName

	String tabList = NMTabControlList()
	
	Variable tabnum = TabNumber(tabName, tabList)
	String prefix = TabPrefix(tabnum, tabList) + "*"
	
	if (tabnum == -1)
		return -1
	endif
	
	KillTab(tabnum, tabList, 1)
	
	Execute /Z "Kill" + tabName + "(" + NMQuotes( "globals" ) + ")" // execute user-defined kill function, if it exists
	
	//DoAlert 1, "Kill " + NMQuotes( tabName ) + " controls?"
	
	//if (V_Flag == 1)
	//	KillControls(TabWinName(tabList), prefix) // kill controls
	//endif
	
	return 0

End // NMTabKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabAddCall()

	String vlist = "", tabName = "", newName = "", tabprefix = ""

	Prompt tabName, "choose tab to add:", popup NMTabsAvailable()
	Prompt newName, "or enter new tab name (e.g. \"Stats\"):"
	Prompt tabprefix, "and the tab's prefix signature (e.g. \"ST_\"):"
	DoPrompt "Add Tab", tabName, newName, tabprefix
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	if ((strlen(newName) > 0) && (strlen(tabprefix) > 0))
	
		tabName = newName
		
		// save prefix string to NMDF()
		// before calling NMTabAdd
		
		SetNMstr(NMDF()+newName+"Prefix", tabprefix) 
		
	elseif (StringMatch(tabName, " ") == 0)
	
		tabprefix = "" // auto-detected
		
	endif
	
	vlist = NMCmdStr(tabName, vlist)
	vlist = NMCmdStr(tabprefix, vlist)
	NMCmdHistory("NMTabAdd", vlist)
	
	return NMTabAdd(tabName, tabprefix)

End // NMTabAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabAdd(tabName, tabprefix)
	String tabName, tabprefix
	
	String tabList = NeuroMaticStr( "NMTabList" )
	
	if (strlen(tabprefix) == 0)
		tabprefix = NMTabPrefix(tabName)
	endif
	
	if ((strlen(tabName) == 0) || (strlen(tabprefix) == 0))
		return -1
	endif
	
	if (WhichListItem(tabName, tabList, ";", 0, 0) == -1)
		tabList = AddListItem(tabName, tabList, ";", inf)
		SetNeuroMaticStr( "NMTabList", tabList )
		UpdateNMTab()
	endif
	
	return 0

End // NMTabAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabRemoveCall()
	
	String tabList = NMTabControlList()
	
	if (StringMatch(tabList, "") == 1)
		return -1
	endif

	String tabName
	Prompt tabName, "choose tab:", popup TabNameList(tabList)
	DoPrompt "Kill Tab", tabName
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	NMCmdHistory("NMTabRemove", NMCmdStr(tabName,""))
	
	return NMTabRemove(tabName)

End // NMTabRemoveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabRemove(tabName)
	String tabName
	
	String tabList = NeuroMaticStr( "NMTabList" )
	
	if ((strlen(tabName) == 0) || (strlen(tabList) == 0))
		return -1
	endif
	
	Variable tabnum = WhichListItem(tabName, tabList, ";", 0, 0)
	
	if (tabnum < 0)
		return -1
	elseif (tabnum == NeuroMaticVar( "CurrentTab" ))
		SetNeuroMaticVar("CurrentTab", 0 )
	endif
	
	tabList = RemoveFromList(tabName, tabList, ";")
	SetNeuroMaticStr( "NMTabList", tabList )
	
	UpdateNMTab()
	
	return 0
	
End // NMTabRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function IsCurrentNMTab(tName)
	String tName
	
	String tabList = NMTabControlList()
	String ctab = TabName(NeuroMaticVar( "CurrentTab" ), tabList)
	
	if (StringMatch(tName, ctab) == 1)
		return 1
	else
		return 0
	endif
	
End // IsCurrentNMTab

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave Increment / Skip Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveIncCall(select)
	String select

	Variable inc = 1
	
	strswitch(select) // set appropriate WaveSkip flag
	
		case "Wave Increment = 1":
			break
			
		case "Wave Increment > 1":
			inc = 2
				
			Prompt inc, "set wave increment to:"
			DoPrompt "Change Wave Increment", inc // call for user input
				
			if (V_flag == 1)
				return 0
			endif
				
			if (inc < 1)
				inc = 1
			endif
			
			break
			
		case "As Wave Select":
			inc = 0
			break
			
		default:
			return 0

	endswitch
	
	NMCmdHistory("NMWaveInc", NMCmdNum(inc, ""))
	
	return NMWaveInc(inc)

End // NMWaveIncCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveInc(value)
	Variable value // increment value or (0) for "As Wave Select"
	
	if ((numtype(value) > 0) || (value < 0))
		value = 1
	endif
	
	SetNeuroMaticVar("WaveSkip", value )
	
	return value
	
End // NMWaveInc

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel and Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanNum2Char( chanNum )
	Variable chanNum
	
	if ( ( numtype( chanNum ) > 0 ) || ( chanNum < 0 ) )
		return ""
	endif
	
	return num2char( 65+chanNum )

End // ChanNum2Char

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanChar2Num( chanChar )
	String chanChar
	
	return char2num( UpperStr( chanChar ) ) - 65

End // ChanChar2Num

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanCharGet( wName )
	String wName // wave name
	Variable icnt
	
	for ( icnt = strlen( wName )-1; icnt >= 0; icnt -= 1 )
		if ( numtype( str2num( wName[icnt] ) ) != 0 )
			break // found Channel letter
		endif
	endfor
	
	return wName[icnt] // return channel character, given wave name

End // ChanCharGet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanNumGet( wName )
	String wName // wave name
	
	return ( char2num( ChanCharGet( wName ) ) - 65 ) // return chan number, given wave name

End // ChanNumGet

//****************************************************************
//
//	GetWaveName()
//	return NM wave name string, given prefix, channel and wave number
//
//****************************************************************

Function /S GetWaveName( prefix, chanNum, waveNum )
	String prefix // wave prefix name ( pass "default" to use data's WavePrefix )
	Variable chanNum // channel number ( pass -1 for none )
	Variable waveNum // wave number
	
	String name
	
	if ( ( StringMatch( prefix, "default" ) == 1 ) || ( StringMatch( prefix, "Default" ) == 1 ) )
		prefix = StrVarOrDefault( "WavePrefix", "Wave" )
	endif
	
	if ( chanNum == -1 )
		name = prefix + num2istr( waveNum )
	else
		name = prefix + ChanNum2Char( chanNum ) + num2istr( waveNum )
	endif
	
	return name[0,30]

End // GetWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetWaveNamePadded( prefix, chanNum, waveNum, maxNum )
	String prefix // wave prefix name ( pass "default" to use data's WavePrefix )
	Variable chanNum // channel number ( pass -1 for none )
	Variable waveNum // wave number
	Variable maxNum
	
	Variable pad, icnt
	String name, snum
	
	pad = strlen( ( num2istr( maxNum ) ) )
	
	if ( ( StringMatch( prefix, "default" ) == 1 ) || ( StringMatch( prefix, "Default" ) == 1 ) )
		prefix = StrVarOrDefault( "WavePrefix", "Wave" )
	endif
	
	snum = num2istr( waveNum )
	
	for ( icnt = strlen( snum ); icnt < pad; icnt += 1 )
		snum = "0" + snum
	endfor
	
	if ( chanNum == -1 )
		name = prefix + snum
	else
		name = prefix + ChanNum2Char( chanNum ) + snum
	endif
	
	return name[0,30]

End // GetWaveNamePadded

//****************************************************************
//
//	NextWaveNum()
//
//****************************************************************

Function NextWaveNum( df, prefix, chanNum, overwrite )
	String df // data folder
	String prefix // wave prefix name
	Variable chanNum // channel number ( pass -1 for none )
	Variable overwrite // overwrite flag: ( 1 ) return last name in sequence ( 0 ) return next name in sequence
	
	Variable count
	String wName
	
	if ( strlen( df ) > 0 )
		df = LastPathColon( df, 1 )
	endif
	
	for ( count = 0; count <= 9999; count += 1 ) // search thru sequence numbers
	
		if ( chanNum == -1 )
			wName = df + prefix + num2istr( count )
		else
			wName = df + prefix+ ChanNum2Char( chanNum ) + num2istr( count )
		endif
		
		if ( WaveExists( $wName ) == 0 )
			break
		endif
		
	endfor
	
	if ( ( overwrite == 0 ) || ( count == 0 ) )
		return count
	else
		return ( count-1 )
	endif

End // NextWaveNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NextWaveName2( datafolder, prefix, chanNum, overwrite ) 
	String datafolder // data folder ( enter "" for current data folder )
	String prefix // wave prefix name
	Variable chanNum // channel number ( pass -1 for none )
	Variable overwrite // overwrite flag: ( 1 ) return last name in sequence ( 0 ) return next name in sequence
	
	Variable waveNum = NextWaveNum( datafolder, prefix, chanNum, overwrite )
	
	return GetWaveName( prefix, chanNum, waveNum )
	
End // NextWaveName2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NextWaveNamePadded( df, prefix, chanNum, overwrite, maxNum ) 
	String df // data folder
	String prefix // wave prefix name
	Variable chanNum // channel number ( pass -1 for none )
	Variable overwrite // overwrite flag: ( 1 ) return last name in sequence ( 0 ) return next name in sequence
	Variable maxNum
	
	Variable waveNum = NextWaveNum( df, prefix, chanNum, overwrite )
	
	return GetWaveNamePadded( prefix, chanNum, waveNum, maxNum )
	
End // NextWaveNamePadded

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixUnique( wavePrefix )
	String wavePrefix
	
	Variable icnt
	String prefix, wList
	
	for ( icnt = 0 ; icnt < 9999 ; icnt += 1 )
	
		prefix = wavePrefix + num2istr( icnt )
		wList = WaveList( prefix + "*", ";", "" )
				
		if ( ItemsInList( wList ) == 0 )
			return prefix
		endif
	
	endfor
	
	return ""

End // NMPrefixUnique

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMPrefixUnique( wavePrefix, defaultPrefix, chanNum )
	String wavePrefix // wave prefix to test
	String defaultPrefix // wave prefix to use if there is a conflict
	Variable chanNum // ( -1 ) for all
	
	Variable seq, icnt, ccnt, cbgn = chanNum, cend = chanNum, conflict
	String wNameMatch, wList, wName, prefix
	
	if ( chanNum < 0 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	do
	
		conflict = 0
	
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			wNameMatch = wavePrefix + "*" + ChanNum2Char( ccnt ) + "*"
				
			wList = WaveList( wNameMatch, ";", "" )
				
			if ( ItemsInList( wList ) > 0 )
				conflict = 1
				break
			endif
		
		endfor
		
		if ( conflict == 0 )
			return wavePrefix
		endif
					
		DoAlert 2, "Warning: waves already exist with prefix " + NMQuotes( wavePrefix ) + ". Do you want to overwrite these waves?"
		
		if ( V_flag == 1 )
		
			for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
				wNameMatch = wavePrefix + "*" + ChanNum2Char( ccnt ) + "*"
					
				wList = WaveList( wNameMatch, ";", "Text:0" )
					
				for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
					wName = StringFromList( icnt, wList )
					KillWaves /Z $wName
				endfor
				
				wList = WaveList( wNameMatch, ";", "Text:0" )
				
				if ( ItemsInList( wList ) > 0 )
					NMDoAlert( "New Wave Prefix Abort: failed to kill the following waves: " + wList )
					return ""
				endif
			
			endfor
			
		elseif ( V_flag == 2 )
		
			wavePrefix = NMPrefixUnique( defaultPrefix )
			
			Prompt wavePrefix, "enter new wave prefix name:"
			DoPrompt "New Wave Prefix", wavePrefix
			
			if ( V_flag == 1 )
				return ""
			endif
			
		else
		
			return ""
			
		endif
	
	while( 1 )
	
End // CheckNMPrefixUnique

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetGraphName( prefix, chanNum )
	String prefix
	Variable chanNum
	
	return CheckGraphName( prefix + ChanNum2Char( chanNum ) )

End // GetGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NextGraphName( prefix, chanNum, overwrite )
	String prefix // graph name prefix
	Variable chanNum // channel number ( pass -1 for none )
	Variable overwrite // overwrite flag: ( 1 ) return last name in sequence ( 0 ) return next name in sequence
	
	Variable count
	String gName
	
	for ( count = 0; count <= 99; count += 1 ) // search thru sequence numbers
	
		if ( chanNum == -1 )
			gName = prefix + num2istr( count )
		else
			gName = prefix + ChanNum2Char( chanNum ) + num2istr( count )
		endif
		
		if ( WinType( gName ) == 0 )
			break // found name not in use
		endif
		
	endfor
	
	if ( ( overwrite == 0 ) || ( count == 0 ) )
		return CheckGraphName( gName )
	elseif ( chanNum < 0 )
		return CheckGraphName( prefix + num2istr( count-1 ) )
	else
		return CheckGraphName( prefix + ChanNum2Char( chanNum ) + num2istr( count-1 ) )
	endif

End // NextGraphName

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Display Functions ( Computer Stats and Window Cascade )
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMComputerPixelsX()

	Variable v1, v2, xPixels = 1000

	String s0 = IgorInfo( 0 )
	
	s0 = StringByKey( "SCREEN1", s0, ":" )
	
	sscanf s0, "%*[DEPTH=]%d%*[,RECT=]%d%*[,]%d%*[,]%d%*[,]%d", v1, v1, v1, v1, v2
	
	if ( ( numtype( v1 ) == 0 ) && ( v1 > xPixels ) )
		xPixels = v1
	endif
	
	return xPixels

End // NMComputerPixelsX

//****************************************************************
//****************************************************************
//****************************************************************

Function NMComputerPixelsY()

	Variable v1, v2, yPixels = 800

	String s0 = IgorInfo( 0 )
	
	s0 = StringByKey( "SCREEN1", s0, ":" )
	
	sscanf s0, "%*[DEPTH=]%d%*[,RECT=]%d%*[,]%d%*[,]%d%*[,]%d", v1, v1, v1, v1, v2
	
	if ( ( numtype( v2 ) == 0 ) && ( v2 > yPixels ) )
		yPixels = v2
	endif
	
	return yPixels

End // NMComputerPixelsY

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMComputerType()

	String s0 = IgorInfo( 2 )
	
	strswitch( s0 )
		case "Macintosh":
			return "mac"
	endswitch
	
	return "pc"

End // NMComputerType

//****************************************************************
//****************************************************************
//****************************************************************

Function SetCascadeXY( gName ) // set cascade graph size and placement
	String gName // graph name to move
	
	Variable wx1, wy1, width, height
	
	Variable xPixels = NMComputerPixelsX()
	Variable yPixels =  NMComputerPixelsY()
	
	Variable cascade = NeuroMaticVar( "Cascade" )
	
	String computer = NMComputerType()
	
	if ( WinType( gName ) == 0 )
		return -1
	endif
	
	strswitch( computer )
		case "pc":
			wx1 = 75 +15*cascade
			wy1 = 75 +15*cascade
			width = 425
			height = 275
			break
		default:
			wx1 = 50 + 28*cascade
			wy1 = 50 + 28*cascade
			width = 525
			height = 340
	endswitch
	
	MoveWindow /W=$gname wx1, wy1, ( wx1+width ), ( wy1+height )
	
	if ( ( wx1 > xPixels * 0.4 ) || ( wy1 > yPixels * 0.4 ) )
		cascade = 0 // reset Cascade counter
	else
		cascade += 1 // increment Cascade counter
	endif
	
	SetNeuroMaticVar("Cascade", cascade )

End // SetCascadeXY

//****************************************************************
//****************************************************************
//****************************************************************

Function ResetCascadeCall()

	NMCmdHistory( "ResetCascade","" )
	
	return ResetCascade()

End // ResetCascadeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ResetCascade() // reset Cascade graph counter

	SetNeuroMaticVar("Cascade", 0 )
	
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
	
	Variable history = NeuroMaticVar( "WriteHistory" ) + 1
	
	Prompt history, "print function results to:", popup "nowhere;Igor history;Igor notebook;both;"
	DoPrompt "NeuroMatic Results History", history
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	history -= 1
	
	NMCmdHistory( "NMHistorySelect", NMCmdNum( history, "" ) )
	
	return NMHistorySelect( history )

End // NMHistoryCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMHistorySelect( history )
	Variable history
	
	SetNeuroMaticVar("WriteHistory", history )
	
	return history
	
End // NMHistorySelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCmdHistoryCall()
	
	Variable cmdhistory = NeuroMaticVar( "CmdHistory" ) + 1
	
	Prompt cmdhistory "print function commands to:", popup "nowhere;Igor history;Igor notebook;both;"
	DoPrompt "NeuroMatic Commands History", cmdhistory
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	cmdhistory -= 1
	
	NMCmdHistory( "NMCmdHistorySelect", NMCmdNum( cmdhistory, "" ) )
	
	return NMCmdHistorySelect( cmdhistory )

End // NMCmdHistoryCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCmdHistorySelect( cmdhistory )
	Variable cmdhistory
	
	SetNeuroMaticVar("CmdHistory", cmdhistory )
	
	return cmdhistory
	
End // NMCmdHistorySelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMHistoryManager( message, where ) // print notes to Igor history and/or notebook
	String message
	Variable where // use negative numbers for command history
	
	String nbName
	
	if ( where == 0 )
		return 0
	endif
	
	if ( ( abs( where ) == 1 ) || ( abs( where ) == 3 ) )
		Print message // Igor History
	endif
	
	if ( ( where == 2 ) || ( where == 3 ) ) // results notebook
		nbName = NMNotebookName( "results" )
		NMNotebookResults()
		Notebook $nbName selection={endOfFile, endOfFile}
		NoteBook $nbName text="\r" + message
	elseif ( ( where == -2 ) || ( where == -3 ) ) // command notebook
		nbName = NMNotebookName( "commands" )
		NMNotebookCommands()
		Notebook $nbName selection={endOfFile, endOfFile}
		NoteBook $nbName text="\r" + message
	endif

End // NMHistoryManager

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNotebookName( select )
	String select // "results" or "commands"
	
	strswitch( select )
		case "results":
			return "NM_ResultsHistory"
		case "commands":
			return "NM_CommandHistory"
	endswitch
	
	return ""

End // NMNotebookName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotebookResults()

	String nbName = NMNotebookName( "results" )
		
	if ( WinType( nbName ) == 5 ) // create new notebook
		return 0
	endif
	
	NewNotebook /F=0/N=$nbName/W=( 0,0,0,0 ) as "NeuroMatic Results Notebook"
	SetCascadeXY( nbName )
	
	NoteBook $nbName text="Date: " + date()
	NoteBook $nbName text="\rTime: " + time()
	NoteBook $nbName text="\r"

End // NMNotebookResults

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotebookCommands()

	String nbName = NMNotebookName( "commands" )

	if ( WinType( nbName ) == 5 ) // create new notebook
		return 0
	endif
	
	NewNotebook /F=0/N=$nbName/W=( 400,100,800,400 ) as "NeuroMatic Command Notebook"
	
	NoteBook $nbName text="Date: " + date()
	NoteBook $nbName text="\rTime: " + time()
	NoteBook $nbName text="\r\r**************************************************************************************"
	NoteBook $nbName text="\r**************************************************************************************"
	NoteBook $nbName text="\r***\tNote: the following commands can be copied to an Igor procedure file"
	NoteBook $nbName text="\r***\t( such as NM_MyTab.ipf ) and used in your own macros or functions."
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

Function NMHistory( message ) // print notes to Igor history and/or notebook
	String message
	
	NMHistoryManager( message, NeuroMaticVar( "WriteHistory" ) )

End // NMHistory

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCmdHistory( funcName, varList ) // print NM command to history
	String funcName // e.g. "NMCmdHistory"
	String varList // "5;8;10;\stest;" ( \s for string )
	
	Variable icnt, comma, extraReturn = 0
	String bullet="", cmd, varStr, returnStr=""
	
	Variable history = NeuroMaticVar( "WriteHistory" )
	Variable cmdhistory = NeuroMaticVar( "CmdHistory" )
	
	String computer = NMComputerType()
	
	if ( extraReturn == 1 )
		returnStr = "\r"
	endif
	
	strswitch( computer )
		case "pc":
			bullet = "•"
			break
		default:
			bullet = "¥"
	endswitch
	
	switch( cmdhistory )
		default:
			return 0
		case 1:
			cmd = returnStr + bullet + funcName + "( "
			break
		case 2:
		case 3:
			cmd = returnStr + funcName + "( "
			break
	endswitch
	
	for ( icnt = 0; icnt < ItemsInList( varList ); icnt += 1 )
	
		varStr = StringFromList( icnt, varList )
		
		if ( StringMatch( varStr[0,1], "\s" ) == 1 ) // string variable
			varStr = NMQuotes( varStr[2,inf] )
		elseif ( StringMatch( varStr[0,1], "\l" ) == 1 ) // string list
			varStr = NMQuotes( ReplaceString( ",", varStr[2,inf], ";" ) )
		endif
		
		if ( comma == 1 )
			cmd += ","
		endif
		
		cmd += " " + varStr + " "
		
		comma = 1
		
	endfor
	
	cmd += " )"
	
	cmd = ReplaceString( "   ", cmd, " " )
	cmd = ReplaceString( "  ", cmd, " " )
	cmd = ReplaceString( "( )", cmd, "()" )
	
	NMHistoryManager( cmd, -1*cmdhistory )
	
End // NMCmdHistory

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCmdStr( strVar, varList )
	String strVar, varList

	return AddListItem( "\s"+strVar, varList, ";", inf )

End // NMCmdStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCmdList( strList, varList ) // for ";" lists
	String strList, varList
	
	if ( ItemsInList( strList ) == 1 )
		return NMCmdStr( StringFromList( 0,strList ), varList )
	endif

	return AddListItem( "\l"+ReplaceString( ";", strList, "," ), varList, ";", inf )

End // NMCmdStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCmdNum( numVar, varList )
	Variable numVar
	String varList

	return AddListItem( num2str( numVar ), varList, ";", inf )

End // NMCmdNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDoAlert( promptStr )
	String promptStr
	
	Variable alert = NeuroMaticVar( "AlertUser" )
	
	if ( strlen( promptStr ) == 0 )
		return -1
	endif
	
	switch( alert )
		case 0: // none
			break
		case 1: // DoAlert
			DoAlert 0, promptStr
			break
		case 2: // NM history
			NMHistory( promptStr )
			break
	endswitch
	
	return 0

End // NMDoAlert

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Misc Utility Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMvar( varName, value ) // set variable to passed value within folder
	String varName
	Variable value
	
	String path = GetPathName( varName, 1 )
	String vName = GetPathName( varName, 0 )
	
	if ( strlen( varName ) == 0 )
		NMerror( 21, "SetNMvar", "varName", varName )
		return -1
	endif
	
	if ( strlen( vName ) > 31 )
		NMerror( 22, "SetNMvar", "varName", vName )
		return -1
	endif

	if ( ( strlen( path ) > 0 ) && ( DataFolderExists( path ) == 0 ) )
		NMerror( 30, "SetNMvar", "varName", varName )
		return -1
	endif

	if ( ( WaveExists( $varName ) == 1 ) && ( WaveType( $varName ) > 0 ) )
	
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

Function SetNMstr( varName, strValue ) // set string to passed value within NeuroMatic folder
	String varName, strValue
	
	String path = GetPathName( varName, 1 )
	String vName = GetPathName( varName, 0 )
	
	if ( strlen( varName ) == 0 )
		NMerror( 21, "SetNMstr", "varName", varName )
		return -1
	endif
	
	if ( strlen( vName ) > 31 )
		NMerror( 22, "SetNMstr", "varName", vName )
		return -1
	endif
	
	if ( ( strlen( path ) > 0 ) && ( DataFolderExists( path ) == 0 ) )
		NMerror( 30, "SetNMstr", "varName", varName )
		return -1
	endif

	if ( ( WaveExists( $varName ) == 1 ) && ( WaveType( $varName ) == 0 ) )
	
		SVAR tempStr = $varName
		
		tempStr = strValue
		
	else
	
		String /G $varName = strValue
		
	endif
	
	return 0

End // SetNMstr

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMwave( wname, pointNum, value )
	String wname
	Variable pointNum // point to set, or ( -1 ) all points
	Variable value
	
	String path = GetPathName( wname, 1 )
	String swname = GetPathName( wname, 0 )
	
	if ( strlen( wname ) == 0 )
		NMerror( 21, "SetNMwave", "wname", wname )
		return -1
	endif
	
	if ( strlen( swname ) > 31 )
		NMerror( 3, "SetNMwave", "wname", swname )
		return -1
	endif
	
	if ( numtype( pointNum ) > 0 )
		NMerror( 10, "SetNMwave", "pointNum", num2istr( pointNum ) )
		return -1
	endif
	
	if ( ( strlen( path ) > 0 ) && ( DataFolderExists( path ) == 0 ) )
		NMerror( 30, "SetNMwave", "wname", wname )
		return -1
	endif
	
	if ( WaveExists( $wname ) == 0 )
		CheckNMwave( wname, pointNum+1, Nan )
	endif
	
	Wave tempWave = $wname
	
	if ( pointNum < 0 )
		tempWave = value
	elseif ( pointNum < numpnts( tempWave ) )
		tempWave[pointNum] = value
	endif
	
	return 0

End // SetNMwave

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMtwave( wname, pointNum, strValue )
	String wname
	Variable pointNum // point to set, or ( -1 ) all points
	String strValue
	
	String path = GetPathName( wname, 1 )
	String swname = GetPathName( wname, 0 )
	
	if ( strlen( wname ) == 0 )
		NMerror( 21, "SetNMtwave", "wname", wname )
		return -1
	endif
	
	if ( strlen( swname ) > 31 )
		NMerror( 3, "SetNMtwave", "wname", swname )
		return -1
	endif
	
	if ( numtype( pointNum ) > 0 )
		NMerror( 10, "SetNMtwave", "pointNum", num2istr( pointNum ) )
		return -1
	endif
	
	if ( ( strlen( path ) > 0 ) && ( DataFolderExists( path ) == 0 ) )
		NMerror( 30, "SetNMtwave", "wname", wname )
		return -1
	endif
	
	if ( WaveExists( $wname ) == 0 )
		CheckNMtwave( wname, pointNum+1, strValue )
	endif
	
	Wave /T tempWave = $wname
	
	if ( pointNum < 0 )
		tempWave = strValue
	elseif ( pointNum < numpnts( tempWave ) )
		tempWave[pointNum] = strValue
	endif
	
	return 0

End // SetNMtwave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMvar( varName, defaultValue )
	String varName
	Variable defaultValue
	
	return SetNMvar( varName, NumVarOrDefault( varName, defaultValue ) )
	
End // CheckNMvar

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMstr( varName, defaultValue )
	String varName
	String defaultValue
	
	return SetNMstr( varName, StrVarOrDefault( varName, defaultValue ) )
	
End // CheckNMstr

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMwave( wList, nPoints, defaultValue )
	String wList // wave list
	Variable nPoints // ( -1 ) dont care
	Variable defaultValue
	
	return CheckNMwaveOfType( wList, nPoints, defaultValue, "R" )
	
End // CheckNMwave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMtwave( wList, nPoints, defaultValue )
	String wList
	Variable nPoints // ( -1 ) dont care
	String defaultValue
	
	Variable wcnt, init, error
	String wname, path
	
	if ( numtype( nPoints ) > 0 )
		return -1
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		
		wname = StringFromList( wcnt, wList )
		path = GetPathName( wName, 1 )
		
		if ( ( strlen( path ) > 0 ) && ( DataFolderExists( path ) == 0 ) )
			error = -1
			continue
		endif
		
		init = 0
		
		if ( ( WaveExists( $wname ) == 0 ) && ( strlen( defaultValue ) > 0 ) )
			init = 1
		endif
		
		CheckNMwaveOfType( wname, nPoints, 0, "T" )
		
		if ( ( init == 1 ) && ( WaveType( $wname ) == 0 ) )
			Wave /T wtemp = $wname
			wtemp = defaultValue
		endif
	
	endfor
	
	return error
	
End // CheckNMtwave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMWaveOfType( wList, nPoints, defaultValue, wType ) // returns ( 0 ) did not make wave ( 1 ) did make wave
	String wList // wave list
	Variable nPoints // ( -1 ) dont care
	Variable defaultValue
	String wType // ( B ) 8-bit signed integer ( C ) complex ( D ) double precision ( I ) 32-bit signed integer ( R ) single precision real ( W ) 16-bit signed integer ( T ) text
	// ( UB, UI or UW ) unsigned integers
	
	String wName, path
	Variable wcnt, nPoints2, makeFlag, error = 0
	
	if ( numtype( nPoints ) > 0 )
		return -1
	endif
	
	if ( nPoints < 0 )
		nPoints = 128
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		nPoints2 = numpnts( $wName )
		
		path = GetPathName( wName, 1 )
		
		if ( ( strlen( path ) > 0 ) && ( DataFolderExists( path ) == 0 ) )
			error = -1
			continue
		endif
		
		makeFlag = 0
		
		if ( WaveExists( $wName ) == 0 )
		
			strswitch( wType )
				case "B":
					if ( ( WaveType( $wName ) & 0x08 ) != 1 )
						makeFlag = 1
					endif
					break
				case "UB":
					if ( ( ( WaveType( $wName ) & 0x08 ) != 1 ) && ( ( WaveType( $wName ) & 0x40 ) != 1 ) )
						makeFlag = 1
					endif
					break
				case "C":
					if ( ( WaveType( $wName ) & 0x01 ) != 1 )
						makeFlag = 1
					endif
					break
				case "D":
					if ( ( WaveType( $wName ) & 0x04 ) != 1 )
						makeFlag = 1
					endif
					break
				case "I":
					if ( ( WaveType( $wName ) & 0x20 ) != 1 )
						makeFlag = 1
					endif
					break
				case "UI":
					if ( ( ( WaveType( $wName ) & 0x20 ) != 1 ) && ( ( WaveType( $wName ) & 0x40 ) != 1 ) )
						makeFlag = 1
					endif
					break
				case "T":
					if ( WaveType( $wName ) != 0 )
						makeFlag = 1
					endif
					break
				case "W":
					if ( ( WaveType( $wName ) & 0x10 ) != 1 )
						makeFlag = 1
					endif
					break
				case "UW":
					if ( ( ( WaveType( $wName ) & 0x10 ) != 1 ) && ( ( WaveType( $wName ) & 0x40 ) != 1 ) )
						makeFlag = 1
					endif
					break
				case "R":
				default:
					if ( ( WaveType( $wName ) & 0x02 ) != 1 )
						makeFlag = 1
					endif
			endswitch
		
		endif
			
		if ( ( WaveExists( $wName ) == 0 ) || makeFlag )
		
			strswitch( wType )
				case "B":
					Make /B/O/N=( nPoints ) $wName = defaultValue
					break
				case "UB":
					Make /B/U/O/N=( nPoints ) $wName = defaultValue
					break
				case "C":
					Make /C/O/N=( nPoints ) $wName = defaultValue
					break
				case "D":
					Make /D/O/N=( nPoints ) $wName = defaultValue
					break
				case "I":
					Make /I/O/N=( nPoints ) $wName = defaultValue
					break
				case "T":
					Make /T/O/N=( nPoints ) $wName = ""
					break
				case "UI":
					Make /I/U/O/N=( nPoints ) $wName = defaultValue
					break
				case "W":
					Make /W/O/N=( nPoints ) $wName = defaultValue
					break
				case "UW":
					Make /W/U/O/N=( nPoints ) $wName = defaultValue
					break
				case "R":
				default:
					Make /O/N=( nPoints ) $wName = defaultValue
			endswitch
			
		elseif ( ( WaveExists( $wName ) == 1 ) && ( nPoints > 0 ) )
		
			strswitch( wType )
			
				case "T":
				
					nPoints2 = numpnts( $wName )
		
					if ( nPoints > nPoints2 )
					
						Redimension /N=( nPoints ) $wName
						
						Wave /T wtemp = $wName
						
						wtemp[nPoints2,inf] = ""
						
					elseif ( nPoints < nPoints2 )
					
						Redimension /N=( nPoints ) $wName
						
					endif
				
					break
			
				default:
		
					nPoints2 = numpnts( $wName )
				
					if ( nPoints > nPoints2 )
					
						Redimension /N=( nPoints ) $wName
						
						Wave wtemp2 = $wName
						
						wtemp2[nPoints2,inf] = defaultValue
						
					elseif ( nPoints < nPoints2 )
					
						Redimension /N=( nPoints ) $wName
						
					endif
				
			endswitch
			
		endif
	
	endfor
	
	return error
	
End // CheckNMWaveOfType

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNoteString( wname )
	String wname // wave name with note
	
	Variable icnt
	String txt, txt2 = ""

	if ( WaveExists( $wname ) == 0 )
		return ""
	endif
	
	txt = note( $wname )
	
	for ( icnt = 0; icnt < strlen( txt ); icnt += 1 )
		if ( char2num( txt[icnt] ) == 13 ) // remove carriage return
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

Function NMNoteExists( wname, key )
String wname // wave name with note
	String key // "thresh", "tbgn", "tend", etc...

	if ( WaveExists( $wname ) == 0 )
		return 0
	endif
	
	if ( numtype( NMNoteVarByKey( wname, key ) ) == 0 )
		return 1
	endif
	
	if ( strlen( NMNoteStrByKey( wname, key ) ) > 0 )
		return 1
	endif
	
	return 0
	
End // NMNoteExists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNoteVarByKey( wname, key )
	String wname // wave name with note
	String key // "thresh", "tbgn", "tend", etc...

	if ( WaveExists( $wname ) == 0 )
		return Nan
	endif
	
	return str2num( StringByKey( key, NMNoteString( wname ) ) )

End // NMNoteVarByKey

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNoteStrByKey( wname, key )
	String wname // wave name with note
	String key // "thresh", "tbgn", "tend", etc...

	if ( WaveExists( $wname ) == 0 )
		return ""
	endif
	
	return StringByKey( key, NMNoteString( wname )  )

End // NMNoteStrByKey

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNoteVarReplace( wname, key, replace )
	String wname // wave name with note
	String key // "thresh", "tbgn", "tend", etc...
	Variable replace // replace string
	
	NMNoteStrReplace( wname, key, num2str( replace ) )
	
End // NMNoteVarReplace

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNoteStrReplace( wname, key, replace )
	String wname // wave name with note
	String key // "thresh", "tbgn", "tend", etc...
	String replace // replace string
	
	Variable icnt, jcnt, found, sl = strlen( key )
	String txt
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif
	
	txt = note( $wname )
	
	for ( icnt = 0; icnt < strlen( txt ); icnt += 1 )
		if ( StringMatch( txt[icnt,icnt+sl-1], key ) == 1 )
			found = 1
			break
		endif
	endfor
	
	if ( found == 0 )
		Note $wname, key + ":" + replace
		return -1
	endif
	
	found = 0
	
	for ( icnt = icnt+sl; icnt < strlen( txt ); icnt += 1 )
	
		if ( StringMatch( txt[icnt,icnt], ":" ) == 1 )
			found = icnt
			break
		endif
		
		if ( StringMatch( txt[icnt,icnt], "=" ) == 1 )
			found = icnt
			break
		endif
		
	endfor
	
	if ( found == 0 )
		return -1
	endif
	
	for ( jcnt = icnt+1; jcnt < strlen( txt ); jcnt += 1 )
	
		if ( StringMatch( txt[jcnt,jcnt], ";" ) == 1 )
			found = jcnt
			break
		endif
		
		if ( char2num( txt[jcnt] ) == 13 )
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

Function NMNoteDelete( wname, key )
	String wname // wave name with note
	String key // find line with this key
	
	Variable icnt, jcnt, found, replace, ibgn, iend, sl, kl = strlen( key )
	String txt
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif
	
	txt = note( $wname )
	
	do 
	
		sl = strlen( txt )
		found = 0
	
		for ( icnt = sl-kl; icnt >= 0 ; icnt -= 1 )
			if ( StringMatch( txt[icnt,icnt+kl-1], key ) == 1 )
				found = 1
				break
			endif
		endfor
		
		if ( found == 1 )
		
			ibgn = Nan
			iend = Nan
		
			for ( jcnt = icnt; jcnt >= 0; jcnt -= 1 )
			
				if ( StringMatch( txt[jcnt,jcnt], ";" ) == 1 )
					ibgn = jcnt
					break
				endif
				
				if ( char2num( txt[jcnt] ) == 13 )
					ibgn = jcnt
					break
				endif
				
			endfor
			
			if ( numtype( ibgn ) > 0 )
				break
			endif
			
			for ( jcnt = icnt; jcnt < sl; jcnt += 1 )
			
				if ( StringMatch( txt[jcnt,jcnt], ";" ) == 1 )
					iend = jcnt+1
					break
				endif
				
				if ( char2num( txt[jcnt] ) == 13 )
					iend = jcnt+1
					break
				endif
				
			endfor
			
			if ( numtype( iend ) > 0 )
				txt = txt[0, ibgn]
			else
				txt = txt[0, ibgn] + txt[iend, inf]
			endif
			
			replace = 1
			
		else
		
			break
			
		endif
	
	
	while ( 1 )
	
	
	if ( replace == 0 )
		return -1
	endif
	
	Note /K $wname
	Note $wname, txt

End // NMNoteDelete

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNoteLabel( xy, wList, defaultStr )
	String xy // "x" or "y"
	String wList
	String defaultStr
	
	Variable icnt
	String wName, xyLabel = ""
	
	if ( ItemsInList( wList ) == 0 )
		return defaultStr
	endif
	
	for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
	
		wName = StringFromList( 0, wList )
		xyLabel = NMNoteStrByKey( wName, xy+"Label" )
		
		if ( strlen( xyLabel ) == 0 )
			xyLabel = NMNoteStrByKey( wName, xy+"dim" )
		endif
		
		if ( strlen( xyLabel ) > 0 )
			return xyLabel // returns first finding of label
		endif
	
	endfor
	
	return defaultStr

End // NMNoteLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNoteType( wName, wType, xLabel, yLabel, wNote )
	String wName, wType, xLabel, yLabel, wNote
	
	if ( WaveExists( $wName ) == 1 )
	
		Note /K $wName
		Note $wName, "Source:" + GetPathName( wName, 0 )
		
		if ( strlen( wType ) > 0 )
			Note $wName, "Type:" + wType
		endif
		
		if ( strlen( yLabel ) > 0 )
			Note $wName, "YLabel:" + yLabel
		endif
		
		if ( strlen( xLabel ) > 0 )
			Note $wName, "XLabel:" + xLabel
		endif
		
		if ( strlen( wNote ) > 0 )
			Note $wName, wNote
		endif
		
	endif

End // NMNoteType

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNoteCheck( noteStr )
	String noteStr
	
	noteStr = ReplaceString( ":", noteStr, "," )
	
	return noteStr
	
End // NMNoteCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPromptStr( title )
	String title
	
	Variable numActiveWaves
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
		numActiveWaves = NeuroMaticVar( "NumActiveWaves" )
	endif
	
	return title + " : " + NMWaveSelectGet() + " : n=" + num2istr( numActiveWaves )

End // NMPromptStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMReturnStr2Num( returnStr )
	String returnStr
	
	if ( strlen( returnStr ) > 0 )
		return 1
	else
		return 0
	endif
	
End // NMReturnStr2Num

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixNext( pPrefix, wPrefix )
	String pPrefix // pre-prefix ( i.e. "MN" or "ST" )
	String wPrefix // wave prefix or ( "" ) for current
	
	Variable icnt
	String newPrefix, wlist
	
	if ( strlen( wPrefix ) == 0 )
		wPrefix = CurrentNMWavePrefix()
	endif
	
	if ( StringMatch( wPrefix[0,1], pPrefix ) == 1 )
		icnt = strsearch( wPrefix, "_", 0 )
		wPrefix = wPrefix[icnt+1,inf]
	endif
	
	newPrefix = pPrefix + "_" + wPrefix
	
	wlist = WaveList( newPrefix + "*", ";", "" )
	
	if ( ItemsInlist( wlist ) == 0 )
		return newPrefix
	endif
	
	for ( icnt = 0; icnt < 99; icnt += 1 )
	
		newPrefix = pPrefix + num2istr( icnt ) + "_" + wPrefix
		wlist = WaveList( newPrefix + "*", ";", "" )
		
		if ( ItemsInList( wlist ) == 0 )
			return newPrefix
		endif
		
	endfor
	
	return ""

End // NMPrefixNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetWaveUnits( xy, wList, defaultLabel )
	String xy // "x" or "y"
	String wList // wave list
	String defaultLabel
	
	Variable icnt
	String wName, s, u
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		
		if ( WaveExists( $wName ) == 0 )
			continue
		endif
		
		s = WaveInfo( $wName, 0 )
	
		if ( StringMatch( xy, "x" ) == 1 )
			u = StringByKey( "XUNITS", s ) // Igor wave x-units
		elseif ( StringMatch( xy, "y" ) == 1 )
			u = StringByKey( "DUNITS", s ) // Igor wave y-units
		else
			u = ""
		endif
		
		if ( strlen( u ) > 0 )
			return u
		endif
		
		if ( StringMatch( xy, "x" ) == 1 )
		
			u = NMNoteStrByKey( wName, "ADCunitsX" ) // NM acquisition units
			
			if ( strlen( u ) > 0 )
				return u
			endif
			
			u = NMNoteStrByKey( wName, "XUnits" ) // general NM units
			
			if ( strlen( u ) > 0 )
				return u
			endif
		
		elseif ( StringMatch( xy, "y" ) == 1 )
		
			u = NMNoteStrByKey( wName, "ADCunits" ) // NM acquisition units
			
			if ( strlen( u ) > 0 )
				return u
			endif
			
			u = NMNoteStrByKey( wName, "YUnits" ) // general NM units
			
			if ( strlen( u ) > 0 )
				return u
			endif
		
		endif
		
		s = NMNoteLabel( xy, wName, defaultLabel ) // try general NM xy-label
		
		if ( strlen( s ) > 0 )
		
			u = UnitsFromStr( s )
			
			if ( strlen( u ) > 0 )
				return u
			else
				return s
			endif
			
		endif
		
	endfor
	
	return defaultLabel
	
End // GetWaveUnits

//****************************************************************
//****************************************************************
//****************************************************************

Function RemoveWaveUnits( wName )
	String wName
	
	Variable xstart, dx
	
	if ( WaveExists( $wName ) == 0 )
		return -1
	endif
	
	dx = deltax( $wName )
	xstart = leftx( $wName )
	
	SetScale /P x, xstart, dx, "", $wName
	SetScale y, 0, 0, "", $wName

End // RemoveWaveUnits

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Graph Drag Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragOnCall( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	on = BinaryCheck( on )
	
	NMCmdHistory( "NMDragOn", NMCmdNum( on, "" ) )
	
	return NMDragOn( on )
	
End // NMDragOnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragOn( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	SetNeuroMaticVar( "DragOn", BinaryCheck( on ) )
	
	return on
	
End // NMDragOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragOnToggle()

	Variable on = BinaryInvert( NeuroMaticVar( "DragOn" ) )
	
	return NMDragOn(  on )
	
End // NMDragOnToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragEnable( enable, wPrefix, waveVarName, varName, fxnName, gName, graphAxis, graphMinMax, colorR, colorG, colorB )
	Variable enable // ( 0 ) remove from graph ( 1 ) append to graph
	String wPrefix // wave prefix name ( e.g. "DragTbgn" )
	String waveVarName // wave variable name
	String varName // variable name, where values are updated ( or point number of waveVarName )
	String fxnName // trigger function ( "" ) for NMDragTrigger
	String graphAxis // only "bottom" for now
	String gName // graph name
	String graphMinMax // "min" or "max"
	Variable colorR
	Variable colorG
	Variable colorB
	
	String ndf = NMDF()
	String xName = wPrefix + "X"
	String yName = wPrefix + "Y"
	String xNamePath = ndf + xName
	String yNamePath = ndf + yName
	
	graphAxis = "bottom"
	
	if ( WinType( gName ) != 1 )
		return -1
	endif
	
	strswitch( graphMinMax )
		case "max":
		case "min":
			break
		default:
			return -1
	endswitch
	
	RemoveFromGraph /Z/W=$gName $yName
	
	if ( ( NeuroMaticVar( "DragOn" ) == 1 ) && ( enable == 1 ) )
	
		NMDragFoldersCheck( gName, fxnName )
	
		CheckNMwave( xNamePath, 2, -1 )
		CheckNMwave( yNamePath, 2, -1 )
		
		NMNoteType( xNamePath, "Drag Wave X", "", "", "Func:NMDragEnable" )
		Note $xNamePath, "Wave Prefix:" + wPrefix
		Note $xNamePath, "WaveY:" + yNamePath
		Note $xNamePath, "Graph:" + gName
		Note $xNamePath, "Graph Axis:" + graphAxis
		Note $xNamePath, "Graph Axis MinMax:" + graphMinMax
		Note $xNamePath, "Wave Variable Name:" + waveVarName
		Note $xNamePath, "Variable Name:" + varName
		
		NMNoteType( yNamePath, "Drag Wave Y", "", "", "Func:NMDragEnable" )
		Note $yNamePath, "Wave Prefix:" + wPrefix
		Note $yNamePath, "WaveX:" + xNamePath
		Note $yNamePath, "Graph:" + gName
		Note $yNamePath, "Graph Axis:" + graphAxis
		Note $yNamePath, "Graph Axis MinMax:" + graphMinMax
		Note $yNamePath, "Wave Variable Name:" + waveVarName
		Note $yNamePath, "Variable Name:" + varName
		
		NMDragUpdate2( xNamePath, yNamePath )
		
		if ( WaveExists( $yNamePath ) == 1 )
			AppendToGraph /W=$gName $yNamePath vs $xNamePath
			ModifyGraph /W=$gName lstyle( $yName )=3, rgb( $yName )=( colorR, colorG, colorB )
			ModifyGraph /W=$gName quickdrag( $yName )=1, live( $yName )=1, offset( $yName )={0,0}
		endif
		
	else
	
		if ( WaveExists( $xNamePath ) == 1 )
			Note /K $xNamePath
		endif
		
		if ( WaveExists( $yNamePath ) == 1 )
			Note /K $yNamePath
		endif
		
	endif
			
End // NMDragEnable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragFoldersCheck( gName, fxnName )
	String gName
	String fxnName

	String ndf = NMDF()
	String wdf = "root:WinGlobals:"
	String cdf = "root:WinGlobals:" + gName + ":"
	
	if ( WinType( gName ) != 1 )
		return -1
	endif
	
	if ( exists( fxnName ) != 6 )
		fxnName = "NMDragTrigger"
	endif
	
	if ( DataFolderExists( wdf ) == 0 )
		NewDataFolder $( RemoveEnding( wdf, ":" ) )
	endif
	
	if ( DataFolderExists( cdf ) == 0 )
		NewDataFolder $( RemoveEnding( cdf, ":" ) )
	endif
	
	CheckNMstr( cdf+"S_TraceOffsetInfo", "" )
	CheckNMvar( cdf+"HairTrigger", 0 )
	
	SetFormula $( cdf+"HairTrigger" ), fxnName + "(" + cdf + "S_TraceOffsetInfo)"

End // NMDragCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragVariableGet( wName, defaultValue )
	String wName
	Variable defaultValue
	
	Variable pnt
	
	if ( WaveExists( $wName ) == 0 )
		return defaultValue
	endif
	
	String waveVarName = NMNoteStrByKey( wName, "Wave Variable Name" )
	String varName = NMNoteStrByKey( wName, "Variable Name" )
	
	if ( exists( varName ) != 2 )
		return defaultValue
	endif
	
	if ( WaveExists( $waveVarName ) == 1 )
	
		Wave wtemp = $waveVarName 
		
		pnt = NumVarOrDefault( varName, Nan )
		
		if ( ( pnt >= 0 ) && ( pnt < numpnts( wtemp ) ) )
			return wtemp[ pnt ]
		endif
	
	endif
	
	return NumVarOrDefault( varName, defaultValue )
	
End // NMDragVariableGet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragVariableSet( wName, value )
	String wName
	Variable value
	
	Variable pnt
	
	if ( WaveExists( $wName ) == 0 )
		return -1
	endif
	
	String waveVarName = NMNoteStrByKey( wName, "Wave Variable Name" )
	String varName = NMNoteStrByKey( wName, "Variable Name" )
	
	if ( exists( varName ) != 2 )
		return -1
	endif
	
	if ( WaveExists( $waveVarName ) == 1 )
	
		Wave wtemp = $waveVarName 
		
		pnt = NumVarOrDefault( varName, Nan )
		
		if ( ( pnt >= 0 ) && ( pnt < numpnts( wtemp ) ) )
			wtemp[ pnt ] = value
			return 0
		endif
		
		return -1
	
	endif
	
	Variable /G $varName = value
	
	return 0
	
End // NMDragVariableSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragTrigger( offsetStr )
	String offsetStr
	
	Variable tbgn, tend, tt, offset, pnt
	String gName, wName, xNamePath, yNamePath, graphMinMax, waveVarName, varName
	String ndf = NMDF()
	
	if ( strlen( offsetStr ) == 0 )
		return -1
	endif
	
	gname = StringByKey( "GRAPH", offsetStr )
	offset = str2num( StringByKey( "XOFFSET", offsetStr ) )
	wname = StringByKey( "TNAME", offsetStr )
	yNamePath = ndf + wName
	
	if ( ( WinType( gname ) != 1 ) || ( WaveExists( $yNamePath ) == 0 ) || ( offset == 0 ) )
		return -1
	endif
	
	xNamePath = NMNoteStrByKey( yNamePath, "WaveX" )
	graphMinMax = NMNoteStrByKey( yNamePath, "Graph Axis MinMax" )
	waveVarName = NMNoteStrByKey( yNamePath, "Wave Variable Name" )
	varName = NMNoteStrByKey( yNamePath, "Variable Name" )
	
	if ( StringMatch( graphMinMax, "min" ) == 1 )
		tt = -inf
	else
		tt = inf
	endif
	
	tt = NMDragVariableGet( yNamePath, tt )
	
	if ( numtype( tt ) == 0 )
	
		tt += offset
		
	else
	
		GetAxis /W=$gName/Q bottom
		
		if ( StringMatch( graphMinMax, "min" ) == 1 )
			tt = V_min + offset
		else
			tt = V_max + offset
		endif
		
	endif
	
	if ( WaveExists( $xNamePath ) == 1 )
	
		Wave xWave = $xNamePath
	
		xWave = tt
		
	endif
	
	NMDragVariableSet( yNamePath, tt )
	
	ModifyGraph /W=$gname offset( $wname )={0,0} // remove offset
	
	SetNeuroMaticVar( "AutoDoUpdate", 0 ) // prevent DoUpdate in Tab Auto functions
	
	NMAutoTabCall()
	
	SetNeuroMaticVar( "AutoDoUpdate", 1 ) // reset update flag
	
	DoWindow /F $gname
	
	return 0
	
End // NMDragTrigger

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragClear( wPrefix )
	String wPrefix

	String ndf = NMDF()
	String xNamePath = ndf + wPrefix + "X"
	String yNamePath = ndf + wPrefix + "Y"
	
	if ( WaveExists( $xNamePath ) == 0 )
		return -1
	endif
	
	Wave dragX = $xNamePath
	Wave dragY = $yNamePath
	
	dragX = Nan
	dragY = Nan

End // NMDragClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragUpdate( wPrefix )  // Note, this must be called AFTER graphs have been auto scaled
	String wPrefix
	
	String ndf = NMDF()
	String xNamePath = ndf + wPrefix + "X"
	String yNamePath = ndf + wPrefix + "Y"
	
	if ( WaveExists( $xNamePath ) == 0 )
		return -1
	endif
	
	String gName = NMNoteStrByKey( yNamePath, "Graph" )
	
	if ( WinType( gName ) != 1 )
		return -1
	endif
	
	return NMDragUpdate2( xNamePath, yNamePath )
	
End // NMDragUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragUpdate2( xNamePath, yNamePath )  // Note, this must be called AFTER graphs have been auto scaled
	String xNamePath, yNamePath 
	
	Variable value, pnt
	
	if ( WaveExists( $xNamePath ) == 0 )
		return -1
	endif
	
	String gName = NMNoteStrByKey( yNamePath, "Graph" )
	String graphMinMax = NMNoteStrByKey( yNamePath, "Graph Axis MinMax" )
	String waveVarName = NMNoteStrByKey( yNamePath, "Wave Variable Name" )
	String varName = NMNoteStrByKey( yNamePath, "Variable Name" )
	
	if ( WinType( gName ) != 1 )
		return -1
	endif

	Wave dragX = $xNamePath
	Wave dragY = $yNamePath
	
	if ( NeuroMaticVar( "DragOn" ) == 1 )
	
		if ( NeuroMaticVar( "AutoDoUpdate" ) == 1 )
			DoUpdate /W=$gName
		endif
		
		if ( StringMatch( graphMinMax, "min" ) == 1 )
			value = -inf
		else
			value = inf
		endif
		
		value = NMDragVariableGet( yNamePath, value )
		
		if ( numtype( value ) == 0 )
		
			dragX = value
			
		elseif ( numtype( value ) == 1 ) // inf
		
			GetAxis /W=$gName/Q bottom
			
			if ( StringMatch( graphMinMax, "min" ) == 1 )
				dragX = V_min
			else
				dragX = V_max
			endif
		
		endif
		
		GetAxis /W=$gName/Q left
		
		dragY[0] = V_min
		dragY[1] = V_max
	
	else
	
		dragX = Nan
		dragY = Nan
		
	endif

End // NMDragUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragExists( gName )
	String gName
	
	Variable icnt
	String wList, yNamePath, type, ndf = NMDF()
	
	if ( WinType( gName ) != 1 )
		return 0
	endif
	
	wList = TraceNameList(gName, ";", 1 )
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		yNamePath = ndf + StringFromList( icnt, wList )
		
		if ( WaveExists( $yNamePath ) == 0 )
			continue
		endif
		
		type = NMNoteStrByKey( yNamePath, "Type" )
		
		if ( StringMatch( type, "Drag Wave Y" ) == 1 )
			return 1
		endif
	
	endfor
	
	return 0
	
End // NMDragExists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragGraphUtility( gName, select )
	String gName
	String select // "clear" or "remove" or "update"
	
	Variable icnt
	String wList, yName, yNamePath, type, wPrefix, ndf = NMDF()
	
	if ( WinType( gName ) != 1 )
		return 0
	endif
	
	wList = TraceNameList(gName, ";", 1 )
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		yName = StringFromList( icnt, wList )
		yNamePath = ndf + yName
		
		type = NMNoteStrByKey( yNamePath, "Type" )
		wPrefix = NMNoteStrByKey( yNamePath, "Wave Prefix" )
		
		if ( StringMatch( type, "Drag Wave Y" ) == 0 )
			continue
		endif
		
		strswitch( select )
		
			case "clear":
				if ( strlen( wPrefix ) > 0 )
					NMDragClear( wPrefix )
				endif
				break
				
			case "remove":
				RemoveFromGraph /Z/W=$gName $yName
				break
				
			case "update":
				if ( strlen( wPrefix ) > 0 )
					NMDragUpdate( wPrefix )
				endif
				break
				
		endswitch
	
	endfor
	
	return 0
	
End // NMDragGraphUtility

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NM Error Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMError( errorNum, functionName, objectName, objectValue )
	Variable errorNum
	String functionName
	String objectName
	String objectValue
	
	String errorStr = "NM Error : " + functionName + " : " + objectName

	switch( errorNum )
	
		// case 0: // DO NOT USE, error 0 indicates there is no error
	
		// wave errors
	
		case 1:
			errorStr += " : wave " + NMQuotes( objectValue ) + " does not exist or is the wrong type."
			break
			
		case 2:
			errorStr += " : wave " + NMQuotes( objectValue ) + " already exists."
			break
			
		case 3:
			errorStr += " : wave name exceeds 31 characters : " + objectValue
			break
			
		case 4:
			errorStr += " : detected no waves to process."
			break
			
		case 5:
			errorStr += " : wave " + NMQuotes( objectValue ) + " has wrong dimensions."
			break
			
			
		// variable errors
		
		case 10:
			errorStr += " : variable has an unnacceptable value of " + objectValue
			break
			
		case 12:
			errorStr += " : variable name exceeds 31 characters : " + objectValue
			break
		
		
		// string errors
		
		case 20:
			errorStr += " : string has an unnacceptable value of " + NMQuotes( objectValue )
			break
			
		case 21:
			errorStr += " : string has no value."
			break
			
		case 22:
			errorStr += " : string name exceeds 31 characters : " + NMQuotes( objectValue )
			break
		
		
		// folder errors
		
		case 30:
			errorStr += " : folder " + NMQuotes( objectValue ) + " does not exist."
			break
			
		case 31:
			errorStr += " : folder " + NMQuotes( objectValue ) + " already exists."
			break
			
		case 32:
			errorStr += " : folder name exceeds 31 characters : " + objectValue
			break
			
		// graph errors
		
		case 40:
			errorStr += " : graph " + NMQuotes( objectValue ) + " does not exist."
			break
			
		// table errors
			
		case 50:
			errorStr += " : table " + NMQuotes( objectValue ) + " does not exist."
			break
			
		
		case 90: // generic error
			break
			
		default:
			errorStr = "NMerror: unrecognized error number " + num2istr( errorNum )
	
	endswitch
	
	SetNeuroMaticStr( "ErrorStr", errorStr )

	NMDoAlert( errorStr )
	
	return errorNum

End // NMError

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMErrorStr( errorNum, functionName, objectName, objectValue )
	Variable errorNum
	String functionName
	String objectName
	String objectValue
	
	NMError( errorNum, functionName, objectName, objectValue )
	
	//return "NMError " + num2istr( errorNum )
	return ""
	
End // NMErrorStr

//****************************************************************
//****************************************************************
//****************************************************************