#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Main Menu Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	Began 5 May 2002
//
//****************************************************************
//****************************************************************
//****************************************************************

Menu "NeuroMatic", dynamic // define main NeuroMatic drop-down menu

	Submenu NMMenuOnStr() + "Data Folder"
		NMMenuOnStr() + "New", NMFolderCall( "New" )
		NMMenuOnStr() + "Open", NMFolderCall( "Open" )
		NMMenuOnStr() + "Close", NMFolderCall( "Close" )
		NMMenuOnStr() + "Save", NMFolderCall( "Save" )
		NMMenuOnStr() + "Duplicate", NMFolderCall( "Duplicate" )
		NMMenuOnStr() + "Rename", NMFolderCall( "Rename" )
		NMMenuOnStr() + "Change", NMFolderCall( "Change" )
		//NMMenuOnStr() + "Merge", NMFolderCall( "Merge" )
		NMMenuOnStr() + "Convert", NMFileCall( "Convert" )
		"-"
		NMMenuOnStr() + "Open All", NMFolderCall( "Open All" )
		NMMenuOnStr() + "Import All", NMFolderCall( "Import All" )
		NMMenuOnStr() + "Save All", NMFolderCall( "Save All" )
		NMMenuOnStr() + "Close All", NMFolderCall( "Close All" )
		"-"
		NMMenuOnStr() + "Set Open Path", NMFolderCall( "Open Path" )
		NMMenuOnStr() + "Set Save Path", NMFolderCall( "Save Path" )
	End
	
	Submenu NMMenuStimOnStr() + "Stim Folder"
		NMMenuStimOnStr() + NMStimSubmenuName(), SubStimCall( "Details" )
		"-"
		NMMenuStimOnStr() + "Pulse Table", SubStimCall( "Pulse Table" )
		NMMenuStimOnStr() + "ADC Table", SubStimCall( "ADC Table" )
		NMMenuStimOnStr() + "DAC Table", SubStimCall( "DAC Table" )
		NMMenuStimOnStr() + "TTL Table", SubStimCall( "TTL Table" )
		NMMenuStimOnStr() + "Stim Waves", SubStimCall( "Stim Waves" )
	End
	
	Submenu NMMenuOnStr() + NMChanGraphSubmenu()
		NMMenuOnStr() + "Display All", NMCall( "Chan Graphs On" )
		NMMenuOnStr() + "Reposition", NMCall( "Chan Graphs Reposition" )
	End

	Submenu NMMenuOnStr() + "Data Waves"
		NMMenuOnStr() + "Import Pclamp or Axograph", NMFileCall( "Import" )
		NMMenuOnStr() + "Load all data waves from a folder on disk", NMFileCall( "Load All Waves" )
		NMMenuOnStr() + "Rename", NMFolderCall( "Rename Waves" )
		NMMenuOnStr() + "Reload", NMFileCall( "Reload Waves" )
	End
	
	Submenu NMMenuOnStr() + "Analysis"
		NMMenuOnStr() + "Stability | Stationarity", NMCall( "Stability" )
		NMMenuOnStr() + "Significant Difference", NMCall( "KSTest" )
	End
	
	Submenu NMMenuOnStr() + "Tabs"
		NMMenuOnStr() + "Add", NMCall( "Add Tab" )
		NMMenuOnStr() + "Remove", NMCall( "Remove Tab" )
		NMMenuOnStr() + "Kill", NMCall( "Kill Tab" )
	End
	
	Submenu NMMenuOnStr() + "Configs"
		NMMenuOnStr() + "Edit", NMConfigCall( "Edit" )
		NMMenuOnStr() + "Open", NMConfigCall( "Open" )
		NMMenuOnStr() + "Save", NMConfigCall( "Save" )
		NMMenuOnStr() + "Kill", NMConfigCall( "Kill" )
	End
	
	"-"
	
	NMMenuOnStr() + "Set Progress Position", NMCall( "Progress XY" )
	NMMenuOnStr() + "Reset Window Cascade", NMCall( "Reset Cascade" )
	NMMenuOnStr() + "Make NeuroMatic Panel", NMCall( "Main Panel" )
	NMMenuOnStr() + "Re-initialize NeuroMatic", NMCall( "Update" )
	"NeuroMatic Help Webpage", NMCall( "Webpage" )
	NMOnMenu(), NMCall( "Off" )
	NMOffMenu(), NMCall( "On" )
	//AboutNM()
	
	"-"
	
	Submenu NMMenuOnStr() + "Main Hot Keys"
		NMMenuOnStr() + NMHotKeysMenu( "Next" ), NMCall( "Next" )
		NMMenuOnStr() + NMHotKeysMenu( "Previous" ), NMCall( "Last" )
		NMMenuOnStr() + NMHotKeysMenu( "Set0" ), NMCall( "Set0 Toggle" )
		NMMenuOnStr() + NMHotKeysMenu( "Set1" ), NMCall( "Set1 Toggle" )
		NMMenuOnStr() + NMHotKeysMenu( "Set2" ), NMCall( "Set2 Toggle" )
	End

End // NeuroMatic Menu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S AboutNM() // executes every time NM menu is accessed

	CheckNMVersion()
	
	return ""
	//return "About NeuroMatic"
	
End // AboutNM

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMenuOnStr()

	if ( NeuroMaticVar( "NMOn" ) == 1 )
		return ""
	else
		return "("
	endif

End // NMMenuOnStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMenuStimOnStr()

	String sdf = SubStimName( "" )

	if ( ( NeuroMaticVar( "NMOn" ) == 1 ) && ( strlen( sdf ) > 0 ) && DataFolderExists( sdf ) )
		return ""
	else
		return "("
	endif

End // NMMenuStimOnStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimSubmenuName()

	String sdf = SubStimName( "" )
	
	if ( ( strlen( sdf ) > 0 ) && DataFolderExists( sdf ) )
		return sdf
	else
		return "None"
	endif

End // NMStimSubmenuName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMOnMenu()
	
	if ( NeuroMaticVar( "NMOn" ) == 1 )
		return "Turn NeuroMatic Off"
	else
		return ""
	endif

End // NMOnMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMOffMenu()
	
	if ( NeuroMaticVar( "NMOn" ) == 0 )
		return "Turn NeuroMatic On"
	else
		return ""
	endif

End // NMOnMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanGraphSubmenu() 
	
	if ( NMNumChannels() > 0 )
		return "Channel Graphs"
	else
		return "(Channel Graphs"
	endif

End // NMChanGraphSubmenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMHotKeysMenu( select )
	String select
	
	Variable setNum
	String setName
	
	strswitch( select )
	
		case "Next":
			return "Next Wave/0"
			
		case "Previous":
			return "Previous Wave/9"
	
		case "Set0":
		case "Set1":
		case "Set2":
		
			setNum = str2num( select[3,3] )
			setName = NMSetsDisplayName( setNum )
			
			if ( strlen( setName ) > 0 )
				return setName + " Checkbox/" + num2istr( setNum + 1 )
			else
				return ""
			endif
		
	endswitch
	
	
End // NMHotKeysMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCall( fxn )
	String fxn
	
	String setList = NMSetsDisplayList()
	
	strswitch( fxn )
			
		case "Stability":
		case "Stationarity":
			Execute "NMStabilityCall0()"
			return 0
		
		case "KSTest":
			Execute "KSTestCall()" // NM_Kolmogorov.ipf
			return 0
	
		case "Update":
			return ResetNMCall()
	
		case "Add Tab":
			return NMTabAddCall()
			
		case "Remove Tab":
			return NMTabRemoveCall()
			
		case "Kill Tab":
			return NMTabKillCall()
			
		case "Progress XY":
			return NMProgressXYPanel()
	
		case "History":
			return NMHistoryCall()
			
		case "CmdHistory":
			return NMCmdHistoryCall()
			
		case "Panel":
		case "Main Panel":
		case "Make Main Panel":
			return MakeNMpanelCall()
			
		case "Graphs On":
		case "Chan Graphs On":
			return ChanOnAllCall()
			
		case "Graphs Reset":
		case "Chan Graphs Reset":
		case "Chan Graphs Reposition":
			return ChanGraphsResetCoordinates()
			
		case "ResetCascade":
		case "Reset Cascade":
		case "Reset Window Cascade":
			return ResetCascadeCall()
			
		case "Next":
			return NMNextWaveCall( +1 )
			
		case "Last":
			return NMNextWaveCall( -1 )
		
		case "Set0 Toggle":
			return NMSetsToggleCall( StringFromList( 0, setList ) )
		
		case "Set1 Toggle":
			return NMSetsToggleCall( StringFromList( 1, setList ) )
		
		case "Set2 Toggle":
			return NMSetsToggleCall( StringFromList( 2, setList ) )
			
		case "Off":
			return NMOn( 0 )
			
		case "On":
			return NMOn( 1 )
			
		case "Webpage":
			return NMwebpage()
			
		default:
			NMDoAlert( "NMCall: unrecognized function call " + NMQuotes( fxn ) )
	
	endswitch
	
	return -1

End // NMCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigCall( select )
	String select

	strswitch( select )
	
		case "Edit":
			return NMConfigEditCall( "" )
			
		case "Update":
			return NMConfigKillCall( "" )
		
		case "Open":
			return NMConfigOpenCall()
		
		case "Save":
			return NMReturnStr2Num( NMConfigSaveCall( "" ) )
			
		case "Kill":
			return NMConfigKillCall( "" )
	
	endswitch

End // NMConfigCall

//****************************************************************
//****************************************************************
//****************************************************************