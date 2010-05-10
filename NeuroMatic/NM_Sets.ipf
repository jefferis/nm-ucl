#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Sets Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsOK()

	if ( strlen( CurrentNMPrefixFolder() ) > 0 )
		return 1
	endif
	
	NMDoAlert( "No Sets. You may need to select " + NMQuotes( "Wave Prefix" ) + " first." )
	
	return 0

End // NMSetsOK

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAutoAdvanceCall( on ) // auto advance wave increment
	Variable on
	
	if ( ( on != 0 ) && ( on != 1 ) )
	
		on = 1 + NeuroMaticVar( "SetsAutoAdvance" )
	
		Prompt on, "auto-advance wave number after each checkbox selection?", popup "no;yes;"
		DoPrompt "Sets Auto Advance Mode", on
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		on -= 1
		
	endif
	
	on = BinaryCheck( on )
	
	NMCmdHistory( "NMSetsAutoAdvance", NMCmdNum( on,"" ) )
	
	return NMSetsAutoAdvance( on )
	
End // NMSetsAutoAdvanceCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAutoAdvance( on ) // auto advance wave increment
	Variable on // ( 0 ) no ( 1 ) yes
	
	on = BinaryCheck( on )
	
	SetNeuroMaticVar( "SetsAutoAdvance", on )
	
	return on
	
End // NMSetsAutoAdvance

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSets()

	Variable scnt
	String setList, setName, setDataList = ""

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	setList = NMSetsWavesList( prefixFolder, 0 )
	
	if ( ItemsInList( setList ) > 0 )
	
		for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
		
			setName = StringFromList( scnt, setList )
			
			if ( StringMatch( setName[0,7], "Set_Data" ) == 1 )
				setDataList = AddListItem( setName, setDataList, ";", inf )
			endif
			
		endfor
		
		if ( ItemsInList( setDataList ) == 1 )
		
			setName = StringFromList( 0, setDataList )
			
			if ( StringMatch( setName, "Set_Data0" ) == 1 )
				
				Wave wtemp = $prefixFolder+setName
				
				if ( sum( wtemp ) == numpnts( wtemp ) )
					KillWaves /Z $prefixFolder+setName // this wave is unecessary
					setList = RemoveFromList( setName, setList )
				endif
				
			endif
			
		endif
	
		OldNMSetsWavesToLists( setList )
		
	endif
	
	CheckNMSetsExist( NMSetsDefaultList() )

	return 0

End // CheckNMSets

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsCall( fxn, select )
	String fxn, select
	
	Variable snum = str2num( select )
	
	if ( NMSetsOK() == 0 )
		return -1
	endif
	
	strswitch( fxn )
	
		case "Define":
			return NMSetsDefineCall()
		
		case "Equation":
		case "Function":
			return NMSetsEquationCall()
			
		case "Table":
		case "Edit":
		case "Panel":
			return NMSetsPanelCall()
			
		case "Convert":
			return NMSetsConvertCall()
			
		case "Invert":
			return NMSetsInvertCall( "" )
			
		case "Clear":
			return NMSetsClearCall( "" )
			
		case "New":
			return NMReturnStr2Num( NMSetsNewCall( "" ) )
			
		case "Copy":
			return NMReturnStr2Num( NMSetsCopyCall( "" ) )
			
		case "Rename":
			return NMReturnStr2Num( NMSetsRenameCall( "" ) )
			
		case "Kill":
			return NMSetsKillCall( "" )
		
		case "Set0Check":
			return NMSetsAssignCall( NMSetsDisplayName( 0 ), snum )

		case "Set1Check":
			return NMSetsAssignCall( NMSetsDisplayName( 1 ), snum )

		case "Set2Check":
			return NMSetsAssignCall( NMSetsDisplayName( 2 ), snum )
			
		case "Exclude SetX?":
			return NMSetXCall( Nan )
			
		case "Auto Advance":
			return NMSetsAutoAdvanceCall( Nan )
			
		case "Display":
		case "SetsDisplay":
			return NMSetsDisplayCall()
			
		default:
			NMDoAlert( "NMSetsCall: unrecognized function call: " + fxn )
			
	endswitch
	
	return -1

End // NMSetsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsStrVarPrefix( setName )
	String setName
	
	return setName + "_SetList"
	
End // NMSetsStrVarPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsStrVarName( setName, chanNum )
	String setName
	Variable chanNum

	return NMPrefixFolderVarName( NMSetsStrVarPrefix( setName ), chanNum )

End // NMSetsStrVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNameGet( strVarName )
	String strVarName // e.g. "TTX_SetWaveListA"
	
	Variable icnt = strsearch( strVarName, NMSetsStrVarPrefix( "" ), 0 )
		
	if ( icnt <= 0 )
		return ""
	endif
		
	return strVarName[0,icnt-1] // e.g. "TTX"
	
End // NMSetsNameGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsStrVarSearch( setName, fullPath )
	String setName
	Variable fullPath

	return NMPrefixFolderStrVarSearch( NMSetsStrVarPrefix( setName ), fullPath )
	
End // NMSetsStrVarSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsWaveList( setName, chanNum )
	String setName
	Variable chanNum
	
	String strVarName = NMSetsStrVarName( setName, chanNum )
	
	if ( strlen( strVarName ) == 0 )
		return ""
	endif
	
	return StrVarOrDefault( strVarName, "" )
	
End // NMSetsWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsWaveListAdd( waveListToAdd, setName, chanNum )
	String waveListToAdd
	String setName
	Variable chanNum
	
	String strVarName = NMSetsStrVarName( setName, chanNum )
	
	return NMPrefixFolderStrVarListAdd( waveListToAdd, strVarName, chanNum )
	
End // NMSetsWaveListAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsWaveListRemove( waveListToRemove, setName, chanNum )
	String waveListToRemove
	String setName
	Variable chanNum
	
	if ( NMSetsOK() == 0 )
		return ""
	endif
	
	String strVarName = NMSetsStrVarName( setName, chanNum )
	
	return NMPrefixFolderStrVarListRemove( waveListToRemove, strVarName, chanNum )
	
End // NMSetsWaveListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsListAll() // all sets + all groups
	
	Variable scnt
	String matchStr, setName, strVarName, strVarList, outList = ""
	
	String defaultList = NMSetsDefaultList()
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( defaultList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, defaultList )
		
		if ( ( strlen( setName ) > 0 ) && ( AreNMSets( setName ) == 1 ) )
			outList += setName + ";"
		endif
		
	endfor
	
	matchStr = "*" + NMSetsStrVarPrefix( "" ) + "*"
	
	strVarList = NMFolderStringList( prefixFolder, matchStr, ";", 0 )
	
	for ( scnt = 0 ; scnt < ItemsInList( strVarList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, strVarList )
		setName = NMSetsNameGet( setName )
		
		if ( strlen( setName ) > 0 )
			outList = NMAddToList( setName, outList, ";" )
		endif
		
	endfor
	
	return outList

End // NMSetsListAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsList()

	Variable scnt
	String setName, setList = ""
	
	String allList = NMSetsListAll()
	
	for ( scnt = 0 ; scnt< ItemsInList( allList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, allList )
		
		if ( StringMatch( setName[0,4], "Group" ) == 0 ) // remove Groups
			setList = AddlistItem( setName, setList, ";", inf )
		endif
		
	endfor
	
	if ( ( NMSetXType() == 1 ) && ( WhichListItem( "SetX", setList ) > 1 ) )
		setList = RemoveFromList( "SetX", setList )
		setList = AddListItem( "SetX", setList, ";", inf ) // place SetX at end of list
	endif
	
	return setList

End // NMSetsList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsListXclude()

	String setList = NMSetsList()
	
	if ( NMSetXType() == 1 )
		return RemoveFromList( "SetX", setList )
	endif
	
	return setList

End // NMSetsListXclude

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsListCheck( fxnName, setList, alert )
	String fxnName // calling function name for alert
	String setList // list to check
	Variable alert // ( 0 ) no ( 1 ) yes
	
	Variable scnt
	String setName, badList = ""
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( ItemsInList( NMSetsStrVarSearch( setName, 0 ) ) == 0 )
			badList += setName + ";" 
		endif
		
	endfor
	
	if ( ( alert == 1 ) && ( ItemsInList( badList ) > 0 ) )
		NMDoAlert( fxnName + " Error: the following set(s) do not exist: " + badList )
	endif
	
	return badList

End // NMSetsListCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function AreNMSets( setList )
	String setList
	
	Variable scnt
	String setName
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( ItemsInList( NMSetsStrVarSearch( setName, 0 ) ) == 0 )
			return 0
		endif
		
	endfor
	
	return 1
	
End // AreNMSets

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSetsExist( setList )
	String setList

	Variable scnt
	String setName
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( AreNMSets( setName ) == 0 )
			NMSetsNewNoUpdate( setName )
		endif
		
	endfor
	
	return 0

End // CheckNMSetsExist

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNameNext()

	Variable icnt, currentChan = CurrentNMChannel()
	String setName, setList, strVarName
	
	if ( NMSetsOK() == 0 )
		return ""
	endif
	
	for ( icnt = 1; icnt < 99; icnt += 1 )
	
		setName = "Set" + num2istr( icnt )
		
		if ( AreNMSets( setName ) == 0 )
			return setName
		endif
		
	endfor

	return ""
	
End // NMSetsNameNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsDefaultList()
	
	return "Set1;Set2;SetX;"

End // NMSetsDefaultList

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMSetsDefault( setName )
	String setName
	
	if ( WhichListItem( setName, NMSetsDefaultList() ) >= 0 )
		return 1
	endif
	
	return 0
	
End // IsNMSetsDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMSetsItem( setName, chanNum, wName )
	String setName
	Variable chanNum
	String wName
	
	String wList
	
	if ( chanNum < 0 )
		chanNum = CurrentNMChannel()
	endif
	
	if ( strlen( wName ) == 0 )
		wName = CurrentNMWaveName()
	endif
	
	wList = NMSetsWaveList( setName, chanNum )
	
	if ( WhichListItem( wName, wList ) >= 0 )
		return 1
	endif
	
	return 0

End // IsNMSetsItem

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNewNameAsk()

	String setName = NMSetsNameNext()
	
	Prompt setName, "enter new set name:"
	DoPrompt "New Sets", setName

	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return setName
	
End // NMSetsNewNameAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNewCall( setName )
	String setName
	
	if ( strlen( setName ) == 0 )
		setName = NMSetsNewNameAsk()
	endif
	
	if ( strlen( setName ) == 0 )
		return "" // cancel
	endif
	
	NMCmdHistory( "NMSetsNew", NMCmdStr( setName, "" ) )
	
	return NMSetsNew( setName )

End // NMSetsNewCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNew( setList )
	String setList
	
	String rvalue = NMSetsNewNoUpdate( setList )
	
	if ( strlen( rvalue ) > 0 )
		UpdateNMWaveSelectLists()
		UpdateNMPanelSets( 1 )
	endif
	
	return rvalue
	
End // NMSetsNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNewNoUpdate( setList )
	String setList
	
	Variable scnt, ccnt, numChannels = NMNumChannels()
	String setName, strVarName, strVarList
	
	if ( NMSetsOK() == 0 )
		return ""
	endif
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( AreNMSets( setName ) == 1 )
			continue // already exists
		endif
		
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			strVarName = NMSetsStrVarName( setName, ccnt )
			
			SetNMstr( strVarName, "" )
		
		endfor
		
	endfor
	
	return setList
	
End // NMSetsNewNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsClearCall( setName )
	String setName
	
	if ( strlen( setName ) == 0 )

		Prompt setName, " ", popup NMSetsList()
		DoPrompt "Clear Sets", setName
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
	endif
	
	NMCmdHistory( "NMSetsClear", NMCmdList( setName,"" ) )
	
	return NMSetsClear( setName )

End // NMSetsClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsClear( setList )
	String setList // set name list
	
	Variable rvalue = NMSetsClearNoUpdate( setList )

	if ( rvalue >= 0 )
		UpdateNMWaveSelectLists()
		UpdateNMPanelSets( 1 )
	endif
	
	return rvalue
	
End // NMSetsClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsClearNoUpdate( setList )
	String setList // set name list
	
	Variable scnt, icnt
	String setName, strVarList, eList

	if ( NMSetsOK() == 0 )
		return -1
	endif
	
	eList = NMSetsListCheck( "NMSetsClear", setList, 1 )
	
	if ( ItemsInList( eList ) > 0 )
		return -1
	endif
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		strVarList = NMSetsStrVarSearch( setName, 1 )
		
		for ( icnt = 0 ; icnt < ItemsInList( strVarList ) ; icnt += 1 ) 
			SetNMstr( StringFromList( icnt, strVarList ) , "" )
		endfor
	
	endfor
	
	return 0

End // NMSetsClearNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsKillCall( setName )
	String setName

	String wlist 
	
	if ( strlen( setName ) == 0 )
	
		wlist = NMSetsList()
		
		if ( ItemsInlist( wlist ) == 0 )
			NMDoAlert( "No Sets to kill!")
			return -1
		endif
		
		wlist = " ;" + wlist
	
		Prompt setName, "select Set to kill:", popup wlist
		DoPrompt "Kill Sets", setName
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
	endif
	
	NMCmdHistory( "NMSetsKill", NMCmdList( setName, "" ) )
	
	return NMSetsKill( setName )

End // NMSetsKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsKill( setList )
	String setList
	
	Variable rvalue = NMSetsKillNoUpdate( setList )
	
	if ( rvalue >= 0 )
		UpdateNMWaveSelectLists()
		UpdateNMPanelSets( 1 )
	endif
	
	return rvalue
	
End // NMSetsKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsKillNoUpdate( setList )
	String setList
	
	Variable scnt, killedsomething
	String setName
	
	if ( NMSetsOK() == 0 )
		return -1
	endif
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( AreNMSets( setName ) == 0 )
			//NMDoAlert( "Abort NMSetsKill: " + setName + " is not a Set." )
			//return -1
			continue
		endif
		
		if ( StringMatch( setName, NMWaveSelectGet() ) == 1 )
			NMDoAlert( "NMSetsKill Alert: " + setName + " is the current Wave Select and cannot be killed." )
			continue
		endif
		
	endfor
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
		setName = StringFromList( scnt, setList )
		killedsomething += NMPrefixFolderStrVarKill( NMSetsStrVarPrefix( setName ) )
	endfor
	
	return 0

End // NMSetsKillNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsCopyCall( setName )
	String setName
	
	Variable icnt
	String vlist = "", newName = NMSetsNameNext()
	
	Prompt setName, "select Set to copy:", popup NMSetsList()
	Prompt newName, "enter new set name:"
	
	if ( strlen( setName ) > 0 )
		DoPrompt "Copy Sets", newName
	else
		DoPrompt "Copy Sets", setName, newName
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	vlist = NMCmdStr( setName, vlist )
	vlist = NMCmdStr( newName, vlist )
	NMCmdHistory( "NMSetsCopy", vlist )
	
	return NMSetsCopy( setName, newName )

End // NMSetsCopyCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsCopy( setName, newName )
	String setName, newName
	
	String rvalue = NMSetsCopyNoUpdate( setName, newName )
	
	if ( strlen( rvalue ) > 0 )
		UpdateNMPanelWaveSelect()
	endif
	
	return rvalue
	
End // NMSetsCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsCopyNoUpdate( setName, newName )
	String setName, newName
	
	Variable vcnt
	String strVarName, strVarList, strVarNameNew, wList
	String thisfxn = "NMSetsCopy"
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( StringMatch( setName, newName ) == 1 )
		return "" // nothing to do
	endif
	
	if ( AreNMSets( setName ) == 0 )
		NMDoAlert( thisfxn + " Abort: " + setName + " is not a Set." )
		return ""
	endif
	
	if ( AreNMSets( newName ) == 1 )
	
		DoAlert 1, "Copy Alert: " + newName + " already exists. Do you want to overwrite it?"
		
		if ( V_Flag != 1 )
			return "" // cancel
		endif
		
		strVarList = NMSetsStrVarSearch( setName, 1 )
	
		for ( vcnt = 0 ; vcnt < ItemsInList( strVarList ) ; vcnt += 1 )
			KillStrings /Z $StringFromList( vcnt, strVarList )
		endfor
		
	endif
	
	strVarList = NMSetsStrVarSearch( setName, 0 )
	
	for ( vcnt = 0 ; vcnt < ItemsInList( strVarList ) ; vcnt += 1 )
	
		strVarName = StringFromList( vcnt, strVarList )
		strVarNameNew = ReplaceString( setName, strVarName, newName )
		wList = StrVarOrDefault( prefixFolder+strVarName, "" )
		
		SetNMstr( prefixFolder+strVarNameNew, wList )

	endfor
	
	return newName

End // NMSetsCopyNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsRenameCall( setName )
	String setName
	
	Variable icnt
	String vlist = ""
	
	String newName = NMSetsNameNext()
	String wlist = NMSetsList()
	
	wlist = RemoveFromList( NMSetsDefaultList(), wlist, ";" )
	wlist = RemoveFromList( NMSetsDisplayList(), wlist )
	
	if ( ItemsInList( wlist ) == 0 )
		NMDoAlert( "No Sets to rename." )
		return ""
	endif
	
	Prompt setName, "select wave to rename:", popup wlist
	Prompt newName, "enter new set name:"
	
	if ( strlen( setName ) > 0 )
		DoPrompt "Rename Sets", newName
	else
		DoPrompt "Rename Sets", setName, newName
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	vlist = NMCmdStr( setName, vlist )
	vlist = NMCmdStr( newName, vlist )
	NMCmdHistory( "NMSetsRename", vlist )
	
	return NMSetsRename( setName, newName )

End // NMSetsRenameCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsRename( setName, newName )
	String setName
	String newName
	
	String rvalue = NMSetsRenameNoUpdate( setName, newName )
	
	if ( strlen( rvalue ) > 0 )
		UpdateNMPanelWaveSelect()
	endif
	
	return rvalue
	
End // NMSetsRename

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsRenameNoUpdate( setName, newName )
	String setName
	String newName
	
	String thisfxn = "NMSetsRename"
	
	if ( NMSetsOK() == 0 )
		return ""
	endif
	
	if ( AreNMSets( setName ) == 0 )
		NMDoAlert( thisfxn + " Abort: " + setName + " is not a Set." )
		return ""
	endif
	
	if ( IsNMSetsDefault( setName ) == 1 )
		NMDoAlert( thisfxn + " Abort: " + setName + " is a default Set and cannot be renamed." )
		return ""
	endif
	
	if ( IsNMSetsDisplay( setName ) == 1 )
		NMDoAlert( thisfxn + " Abort: " + setName + " is a display Set and cannot be renamed." )
		return ""
	endif
	
	if ( AreNMSets( newName ) == 1 )
		NMDoAlert( thisfxn + " Abort: " + newName + " already exists." )
		return ""
	endif
	
	NMSetsCopyNoUpdate( setName, newName )
	
	if ( AreNMSets( newName ) == 1 )
		NMSetsKillNoUpdate( setName )
	endif
	
	return newName

End // NMSetsRenameNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDefineCall()
	
	Variable wlimit
	String vlist = ""
	
	String setList = NMSetsList()
	
	setList = NMAddToList( NMSetsDefaultList(), setList, ";" )
	
	Variable numWaves = NMNumWaves()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wlimit = NMNumWaves() - 1
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	Variable first = NumVarOrDefault( prefixFolder+"SetsFromWave", 0 )
	Variable last = NumVarOrDefault( prefixFolder+"SetsToWave", wlimit )
	Variable skip = NumVarOrDefault( prefixFolder+"SetsSkipWaves", 0 )
	Variable value = 1 //+ NumVarOrDefault( prefixFolder+"SetsDefineValue", 1 )
	Variable clearFirst = 1 + NumVarOrDefault( prefixFolder+"SetsDefineClear", 1 )
	
	Prompt setName, " ", popup setList
	Prompt first, "FROM wave:"
	Prompt last, "TO wave:"
	Prompt skip, "SKIP every other:"
	//Prompt value, "Define as:", popup "0;1;"
	Prompt clearFirst, "clear Set first?", popup "no;yes"
	
	//DoPrompt "Define Sets", setName, value, first, skip, last, clearFirst
	DoPrompt "Define Sets as True ( 1 )", setName, first, last, skip, clearFirst
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	//value -= 1
	clearFirst -= 1
	
	SetNMstr( prefixFolder+"SetsDefineSelect", setName )
	SetNMvar( prefixFolder+"SetsFromWave", first )
	SetNMvar( prefixFolder+"SetsToWave", last )
	SetNMvar( prefixFolder+"SetsSkipWaves", skip )
	//SetNMvar( prefixFolder+"SetsDefineValue", value )
	SetNMvar( prefixFolder+"SetsDefineClear", clearFirst )
	
	first = max( first, 0 )
	first = min( first, wlimit )
	
	last = max( last, 0 )
	last = min( last, wlimit )
	
	skip = max( skip, 0 )
	skip = min( skip, wlimit )
	
	if ( numtype( skip ) > 0 )
		skip = 0
	endif
	
	vlist = NMCmdList( setName, vlist )
	vlist = NMCmdNum( value, vlist )
	vlist = NMCmdNum( first, vlist )
	vlist = NMCmdNum( last, vlist )
	vlist = NMCmdNum( skip, vlist )
	vlist = NMCmdNum( clearFirst, vlist )
	NMCmdHistory( "NMSetsDefine", vlist )
	
	return NMSetsDefine( setName, value, first, last, skip, clearFirst )

End // NMSetsDefineCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDefine( setList, value, first, last, skip, clearFirst )
	String setList
	Variable value // ( 0 ) remove from set ( 1 ) add to set
	Variable first // from wave num
	Variable last // to wave num
	Variable skip // skip wave increment ( 0 ) for none
	Variable clearFirst // zero wave first ( 0 ) no ( 1 ) yes
	
	Variable rvalue = NMSetsDefineNoUpdate( setList, value, first, last, skip, clearFirst )
	
	if ( rvalue >= 0 )
		UpdateNMWaveSelectLists()
		UpdateNMPanelSets( 1 )
	endif
	
	return rvalue
	
End // NMSetsDefine

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDefineNoUpdate( setList, value, first, last, skip, clearFirst )
	String setList
	Variable value // ( 0 ) remove from set ( 1 ) add to set
	Variable first // from wave num
	Variable last // to wave num
	Variable skip // skip wave increment ( 0 ) for none
	Variable clearFirst // zero wave first ( 0 ) no ( 1 ) yes
	
	Variable scnt, ccnt, wcnt, wlimit
	String wname, setName, wList = ""
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	Variable currentWave = CurrentNMWave()
	
	if ( NMSetsOK() == 0 )
		return -1
	endif
	
	wlimit = numWaves - 1
	
	if ( ( numtype( first ) > 0 ) || ( first < 0 ) )
		first = currentWave
	endif
	
	if ( ( numtype( last ) > 0 ) || ( last < 0 ) )
		last = currentWave
	endif
	
	if ( ( numtype( skip ) > 0 ) || ( skip < 0 ) )
		skip = 0
	endif
	
	first = max( first, 0 )
	first = min( first, wlimit )
	
	last = max( last, 0 )
	last = min( last, wlimit )
	
	skip = max( skip, 0 )
	skip = min( skip, wlimit )
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( ( clearFirst == 1 ) && ( AreNMSets( setName ) == 1 ) )
			NMSetsClearNoUpdate( setName )
		endif
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
			
			for ( wcnt = first ; wcnt <= last ; wcnt += 1+skip )
			
				wname = NMChanWaveName( ccnt, wcnt )
				wList += wname + ";"

			endfor
			
			if ( ItemsInList( wList ) == 0 )
				continue
			endif
			
			if ( value == 1 )
				NMSetsWaveListAdd( wList, setName, ccnt )
			else
				NMSetsWaveListRemove( wList, setName, ccnt )
			endif
			
		endfor
			
	endfor
	
	return 0

End // NMSetsDefineNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAssignCall( setName, value )
	String setName
	Variable value
	
	String vlist = ""
	
	Variable currentWave = CurrentNMWave()
	
	vlist = NMCmdStr( setName, vlist )
	vlist = NMCmdNum( currentWave, vlist )
	vlist = NMCmdNum( value, vlist )
	NMCmdHistory( "NMSetsAssign", vlist )
	
	return NMSetsAssign( setName, currentWave, value )

End // NMSetsAssignCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAssign( setList, waveNum, value )
	String setList
	Variable waveNum // wave number ( -1 ) for current
	Variable value // ( 0 ) remove from set ( 1 ) add to set
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	NMSetsDefine( setList, value, waveNum, waveNum, 0, 0 )
	
	if ( NeuroMaticVar( "SetsAutoAdvance" ) == 1 )
		NMNextWave( 1 )
	endif
	
	return value
	
End // NMSetsAssign

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsToggleCall( setName )
	String setName
	
	NMCmdHistory( "NMSetsToggle", NMCmdStr( setName,"" ) )
	
	return NMSetsToggle( setName )

End // NMSetsToggleCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsToggle( setName )
	String setName
	
	Variable ccnt, rvalue, value = 1
	String wname, wList
	
	Variable numChannels = NMNumChannels()
	Variable currentWave = CurrentNMWave()
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		wname = NMChanWaveName( ccnt, currentWave )
		wList = NMSetsWaveList( setName, ccnt )

		if ( WhichListItem( wname, wList ) >= 0 )
			value = 0 // remove from list
		endif
		
	endfor
	
	rvalue = NMSetsDefineNoUpdate( setName, value, currentWave, currentWave, 0, 0 )
	
	if ( rvalue >= 0 )
		UpdateNMWaveSelectLists()
		UpdateNMPanelSets( 1 )
	endif
	
	if ( NeuroMaticVar( "SetsAutoAdvance" ) == 1 ) 
		NMNextWave( 1 )
	endif
	
	return 0

End // NMSetsToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsInvertCall( setName )
	String setName
	
	if ( strlen( setName ) == 0 )

		Prompt setName, " ", popup NMSetsList()
		DoPrompt "Invert Sets", setName
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
	endif
	
	NMCmdHistory( "NMSetsInvert", NMCmdList( setName,"" ) )
	
	return NMSetsInvert( setName )

End // NMSetsInvertCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsInvert( setList )
	String setList // set name list
	
	Variable rvalue = NMSetsInvertNoUpdate( setList )
	
	if ( rvalue >= 0 )
		UpdateNMWaveSelectLists()
		UpdateNMPanelSets( 1 )
	endif
	
	return rvalue
	
End // NMSetsInvert

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsInvertNoUpdate( setList )
	String setList // set name list
	
	Variable scnt, ccnt, numChannels = NMNumChannels()
	String setName, strVarName, wList, chanList, eList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( NMSetsOK() == 0 )
		return -1
	endif
	
	eList = NMSetsListCheck( "NMSetsInvert", setList, 1 )
	
	if ( ItemsInList( eList ) > 0 )
		return -1
	endif
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( strlen( setName ) == 0 )
			continue
		endif
		
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			chanList = NMChanWaveList( ccnt )
		
			strVarName = NMSetsStrVarName( setName, ccnt )
			
			if ( exists( strVarName ) != 2 )
				continue
			endif
			
			wList = StrVarOrDefault( strVarName, "" )
			
			chanList = RemoveFromList( wList, chanList )
			
			SetNMstr( strVarName, chanList )
			
		endfor
	
	endfor
	
	return 0

End // NMSetsInvertNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsConvertCall()

	String wName = " ", wList, setName, vlist = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wList = " ;" + WaveList( "*", ";", "Text:0" )
	
	Prompt wName, "choose a wave containing 1's and 0's:", popup wList
	Prompt setName, "this wave will be converted to:", popup NMSetsList()
	DoPrompt "Sets Conversion", wName, setName

	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	vlist = NMCmdStr( wName, vlist )
	vlist = NMCmdStr( setName, vlist )
	NMCmdHistory( "NMSetsConvert", vlist )
	
	return NMSetsConvert( wName, setName )

End // NMSetsConvertCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsConvert( wName, setName )
	String wName
	String setName
	
	Variable rValue = NMSetsConvertNoUpdate( wName, setName )
	
	if ( rvalue >= 0 )
		UpdateNMWaveSelectLists()
		UpdateNMPanelSets( 1 )
	endif
	
	return rvalue
	
End // NMSetsConvert

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsConvertNoUpdate( wName, setName )
	String wName
	String setName
	
	if ( NMSetsOK() == 0 )
		return -1
	endif
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, "NMSetsConvert", "wName", wName )
	endif
	
	NMSetsKillNoUpdate( setName )
	NMPrefixFolderWaveToLists( wName, NMSetsStrVarPrefix( setName ) )

	return 0

End // NMSetsConvertNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEquationCall()
	
	String vlist = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsFxnName", "Set1" )
	String arg1 = StrVarOrDefault( prefixFolder+"SetsFxnArg1", " " )
	String op = StrVarOrDefault( prefixFolder+"SetsFxnOp", " " )
	String arg2 = StrVarOrDefault( prefixFolder+"SetsFxnArg2", " " )
	
	String setList = NMSetsList() + NMGroupsList( 1 )
	
	if ( StringMatch( op, " " ) == 1 )
		arg2 = " "
	endif
	
	Prompt setName, " ", popup setList
	Prompt arg1, " = ", popup " ;" + setList
	Prompt op, " ", popup " ;AND;OR;"
	Prompt arg2, " ", popup " ;" + setList
	
	DoPrompt "Sets Equation", setName, arg1, op, arg2
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( arg1, " " ) == 1 )
		arg1 = ""
	endif
	
	if ( StringMatch( arg2, " " ) == 1 )
		arg2 = ""
	endif
	
	SetNMstr( prefixFolder+"SetsFxnName", setName )
	SetNMstr( prefixFolder+"SetsFxnArg1", arg1 )
	SetNMstr( prefixFolder+"SetsFxnOp", op )
	SetNMstr( prefixFolder+"SetsFxnArg2", arg2 )
	
	vlist = NMCmdList( setName, vlist )
	vlist = NMCmdStr( arg1, vlist )
	vlist = NMCmdStr( op, vlist )
	vlist = NMCmdStr( arg2, vlist )
	NMCmdHistory( "NMSetsEquation", vlist )
	
	return NMSetsEquation( setName, arg1, op, arg2 )

End // NMSetsEquationCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEquation( setName, arg1, operation, arg2 )
	String setName // e.g. "Set1"
	String arg1 // argument #1 ( e.g. "Set1" or "Group2" )
	String operation // operator ( "AND", "OR", "" )
	String arg2 // argument #1 ( e.g. "Set2" or "Group2" or "" )
	
	Variable rvalue = NMSetsEquationNoUpdate( setName, arg1, operation, arg2 )
	
	if ( rvalue >= 0 )
		UpdateNMWaveSelectLists()
		UpdateNMPanelSets( 1 )
	endif
	
	return rvalue
	
End // NMSetsEquation

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEquationNoUpdate( setName, arg1, operation, arg2 ) // Set = arg1 AND arg2
	String setName // e.g. "Set1"
	String arg1 // argument #1 ( e.g. "Set1" or "Group2" )
	String operation // operator ( "AND", "OR", "" )
	String arg2 // argument #1 ( e.g. "Set2" or "Group2" or "" )
	
	Variable ccnt, grp1 = Nan, grp2 = Nan
	String wList1, wList2, thisfxn = "NMSetsEquation"
	
	Variable numChannels = NMNumChannels()
	
	if ( NMSetsOK() == 0 )
		return -1
	endif
	
	if ( numChannels <= 0 )
		NMDoAlert( thisfxn + " Abort: no channels: " + num2istr( numChannels ) )
		return -1
	endif
	
	if ( strlen( setName ) == 0 )
		NMDoAlert( thisfxn + " Abort: parameter setName is undefined." )
		return -1
	endif
	
	if ( strlen( arg1 ) == 0 )
		NMDoAlert( thisfxn + " Abort: parameter arg1 is undefined." )
		return -1
	endif
	
	strswitch( operation )
	
		case "AND":
		case "&":
		case "&&":
			operation = "AND"
			break
			
		case "OR":
		case "|":
		case "||":
			operation = "OR"
			break
			
		default:
			operation = ""
			arg2 = ""
	
	endswitch
	
	if ( StringMatch( arg1[0,4], "Group" ) == 1 )
		grp1 = str2num( arg1[5,inf] )
	elseif ( AreNMSets( arg1 ) == 0 )
		NMDoAlert( thisfxn + " Abort: " + arg1 + " does not exist." )
		return -1
	endif
	
	if ( StringMatch( arg2[0,4], "Group" ) == 1 )
		grp2 = str2num( arg2[5,inf] )
	elseif ( ( strlen( arg2 ) > 0 ) && ( AreNMSets( arg2 ) == 0 ) )
		NMDoAlert( thisfxn + " Abort: " + arg2 + " does not exist." )
		return -1
	endif
	
	if ( AreNMSets( setName ) == 1 )
		NMSetsClearNoUpdate( setName )
	endif
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		wList1 = ""
		wList2 = ""
	
		if ( numtype( grp1 ) == 0 )
			wList1 = NMGroupsWaveList( grp1, ccnt )
		else
			wList1 = NMSetsWaveList( arg1, ccnt )
		endif
		
		if ( strlen( arg2 ) > 0 )
		
			if ( numtype( grp2 ) == 0 )
				wList2 = NMGroupsWaveList( grp2, ccnt )
			else
				wList2 = NMSetsWaveList( arg2, ccnt )
			endif
			
			strswitch( operation )
				
				case "AND":
					wList1 = NMAndLists( wList2, wList1, ";" )
					break
		
				case "OR":
					wList1 = NMAddToList( wList2, wList1, ";" )
					break
			
				default:
					return -1
	
			endswitch
		
		endif
		
		NMSetsWaveListAdd( wList1, setName, ccnt )
		
	endfor
	
	return 0

End // NMSetsEquationNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEquationAll( outName, operation )
	String outName // output set name
	String operation // "AND" or "OR"
	
	Variable scnt, ccnt, numChannels = NMNumChannels()
	String setName, wList1, wList2
	
	String setList = NMSetsList()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	strswitch( operation )
				
		case "AND":
		case "&":
		case "&&":
			operation = "AND"
			break

		case "OR":
		case "|":
		case "||":
			operation = "OR"
			break
	
		default:
			return -1
			
	endswitch
	
	if ( NMSetXType() == 1 )
		setList = RemoveFromList( "SetX", setList )
	endif
	
	CheckNMSetsExist( outName )
	NMSetsClearNoUpdate( outName )
	
	if ( ItemsInList( setList ) <= 0 )
		return 0
	endif
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
			setName = StringFromList( scnt, setList )
			wList2 = NMSetsWaveList( setName, ccnt )
			
			if ( scnt == 0 )
				wList1 = wList2
				continue
			endif
			
			strswitch( operation )
				
				case "AND":
					wList1 = NMAndLists( wList1, wList2, ";" )
					break
		
				case "OR":
					wList1 = NMAddToList( wList2, wList1, ";" )
					break
					
			endswitch
	
		endfor
		
		NMSetsWaveListAdd( wList1, outName, ccnt )
		
	endfor
	
	return 0
	
End // NMSetsEquationAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsDisplayList()

	String setList = ""

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
		setList = StrVarOrDefault( prefixFolder+"SetsDisplayList", "" )
	endif
	
	if ( ItemsInList( setList ) > 0 )
		return setList
	else
		return NMSetsDefaultList()
	endif

End // NMSetsDisplayList

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMSetsDisplay( setName )
	String setName
	
	if ( WhichListItem( setName, NMSetsDisplayList() ) >= 0 )
		return 1
	endif
	
	return 0
	
End // IsNMSetsDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsDisplayName( setListNum )
	Variable setListNum
	
	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
		return ""
	endif
	
	return StringFromList( setListNum, NMSetsDisplayList() )

End // NMSetsDisplayName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDisplayCall()

	Variable on
	
	String setList = NMSetsDisplayList()
	
	String s1 = StringFromList( 0, setList )
	String s2 = StringFromList( 1, setList )
	String s3 = StringFromList( 2, setList )
	
	Prompt s1, "first checkbox:", popup NMSetsList()
	Prompt s2, "second checkbox:", popup NMSetsList()
	Prompt s3, "third checkbox:", popup NMSetsList()
	DoPrompt "Main Panel Sets Display", s1, s2, s3
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	setList = AddListItem( s1, "", ";", inf )
	setList = AddListItem( s2, setList, ";", inf )
	setList = AddListItem( s3, setList, ";", inf )
	
	NMCmdHistory( "NMSetsDisplaySet", NMCmdList( setList, "" ) )
	
	return NMSetsDisplaySet( setList )
	
End // NMSetsDisplayCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDisplaySet( setList )
	String setList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( ItemsInList( setList ) != 3 )
		return -1
	endif
	
	String eList = NMSetsListCheck( "NMSetsDisplaySet", setList, 1 ) 
	
	if ( ItemsInList( eList) > 0 )
		return -1
	endif
	
	SetNMstr( prefixFolder +"SetsDisplayList", setList )
	
	UpdateNMPanelSets( 1 )
	
	return 0
	
End // NMSetsDisplaySet

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMSetsDisplayCount() // udpate count number for display Sets

	Variable scnt, count
	String setName
	
	Variable currentChan = CurrentNMChannel()
	
	for ( scnt = 0 ; scnt < 3 ; scnt += 1 )
	
		setName = NMSetsDisplayName( scnt )
		count = ItemsInList( NMSetsWaveList( setName, currentChan ) )
		
		SetNeuroMaticVar( "SumSet"+num2istr(scnt), count )
		
	endfor

End // UpdateNMSetsDisplayCount

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetXCall( exclude )
	Variable exclude
	
	if ( ( exclude != 0 ) && ( exclude != 1 ) )
	
		exclude = 1 + NMSetXType()
	
		Prompt exclude, "waves checked as SetX are to be excluded from analysis?", popup "no;yes"
		DoPrompt "Define SetX", exclude
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		exclude -= 1
		
	endif
	
	NMCmdHistory( "NMSetXclude", NMCmdNum( exclude,"" ) )
	
	return NMSetXclude( exclude )
	
End // NMSetXCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetXclude( excluding )
	Variable excluding // ( 0 ) normal Set ( 1 ) excluding Set
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	excluding = BinaryCheck( excluding )
	
	SetNMvar( prefixFolder+"SetXclude", excluding )
	
	UpdateNMWaveSelectLists()
	UpdateNMPanelSets( 1 )
	
	return excluding
	
End // NMSetXclude

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetXType() // determine if SetX is excluding

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( AreNMSets( "SetX" ) == 0 ) )
		return 1
	endif
	
	if ( NumVarOrDefault( prefixFolder+"SetXclude", 1 ) == 1 )
		return 1
	endif

	return 0

End // NMSetXType

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetXcludeWaveList( wList, chanNum )
	String wList
	Variable chanNum
	
	if ( NMSetXType() == 0 )
		return wList
	endif
	
	String strVarName = NMSetsStrVarName( "SetX", chanNum )
	
	String wListX = StrVarOrDefault( strVarName, "" )
	
	return RemoveFromList( wListX, wList )
	
End // NMSetXcludeWaveList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Set Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsWavesList( folder, fullPath )
	String folder
	Variable fullPath // ( 0 ) no, just wave name ( 1 ) yes, directory + wave name
	
	Variable scnt
	String setName, type, outList = ""
	
	if ( strlen( folder ) == 0 )
		return ""
	endif
	
	Variable numWaves = NumVarOrDefault( folder+"NumWaves", 0 )
	
	String optionsStr = NMWaveListOptions( numWaves, 0 )
	
	String setList = NMFolderWaveList( folder, "*", ";", optionsStr, 0 )
	
	String remList = WaveList( "*TShift*", ";", "" )
	
	remList += "WavSelect;ChanSelect;Group;FileScaleFactors;MyScaleFactors;"
	
	setList = SortList( setList, ";", 16 )
	
	if ( WhichListItem( "SetX", setList ) >= 0 )
		setList = RemoveFromList( "SetX", setList, ";" )
		setList = AddListItem( "SetX", setList, ";", inf )
	endif
	
	setList = RemoveFromList( remList, setList, ";" )

	if ( ItemsInList( setList ) < 1 )
		return ""
	endif
	
	for ( scnt = 0; scnt < ItemsInList( setList); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		type = NMNoteStrByKey( folder+setName, "Type" )
		
		if ( ( StringMatch( type, "NMSet" ) == 1 ) || ( StringMatch( setName[0,2], "Set" ) == 1 ) )
		
			if ( fullPath == 1 )
				outList = AddListItem( folder + setName, outList, ";", inf )
			else
				outList = AddListItem( setName, outList, ";", inf )
			endif
			
		endif
		
	endfor
	
	return outList
	
End // NMSetsWavesList

//****************************************************************
//****************************************************************
//****************************************************************

Function AreNMSetsWaves( setList )
	String setList
	
	Variable scnt
	String setName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( WaveExists( $prefixFolder+setName ) == 0 )
			return 0
		endif
		
	endfor
	
	return 1
	
End // AreNMSetsWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsWavesKill()

	Variable scnt, killedsomething
	String setName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	String setList = NMSetsWavesList( prefixFolder, 0)
	
	for ( scnt = 0 ; scnt <ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( AreNMSets( setName ) == 1 )
			KillWaves /Z $prefixFolder+setName // kill only if Set string lists exist
		endif
		
		if ( WaveExists( $prefixFolder+setName ) == 0 )
			killedsomething = 1
		endif
		
	endfor

	return killedsomething

End // NMSetsWavesKill

//****************************************************************
//****************************************************************
//****************************************************************

Function OldNMSetsWavesToLists( setList )
	String setList
	
	Variable scnt, xtype
	String setName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
		
		setName = StringFromList( scnt, setList )
		
		if ( AreNMSets( setName ) == 0 )
			
			if ( StringMatch( setName, "SetX" ) == 1 )
			
				xtype = NMNoteVarByKey( prefixFolder+"SetX", "Excluding" )
			
				if ( xtype == 0 )
					SetNMvar( prefixFolder+"SetXclude", 0 )
				endif
				
			endif
			
			NMSetsWavesToLists( setName )
			
		endif
		
		if ( AreNMSets( setName ) == 1 )
			KillWaves /Z $prefixFolder+setName
		endif
		
	endfor
		
End // OldNMSetsWavesToLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsWaveToLists( setWaveName, newSetName )
	String setWaveName
	String newSetName
	
	if ( WaveExists( $setWaveName ) == 0 )
		NMDoAlert( "Abort NMSetsWaveToLists: wave does not exist: " + setWaveName )
		return -1
	endif
	
	return NMPrefixFolderWaveToLists( setWaveName, NMSetsStrVarPrefix( newSetName ) )
	
End // NMSetsWaveToLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsWavesToLists( setList )
	String setList
	
	Variable scnt
	String setName, inputWaveName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		inputWaveName = prefixFolder+setName
		
		NMPrefixFolderWaveToLists( inputWaveName, NMSetsStrVarPrefix( setName ) )
	
	endfor
	
	return 0
	
End // NMSetsWavesToLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsListsToWavesAll()

	String setList = NMSetsList()

	NMSetsListsToWaves( setList )
	
	NMSetsWavesTag( setList )

End // NMSetsListsToWavesAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsListsToWaves( setList )
	String setList

	Variable scnt
	String setName, outputWaveName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		outputWaveName = prefixFolder+setName
		
		NMPrefixFolderListsToWave( NMSetsStrVarPrefix( setName ), outputWaveName )
		
		NMSetsWavesTag( outputWaveName )
		
	endfor
	
	return 0

End // NMSetsListsToWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsWavesTag( setList )
	String setList
	
	Variable icnt
	String setName, wnote
	
	for ( icnt = 0; icnt < ItemsInList( setList ); icnt += 1 )
	
		setName = StringFromList( icnt, setList )
		
		if ( WaveExists( $setName ) == 0 )
			continue
		endif
		
		if ( StringMatch( NMNoteStrByKey( setName, "Type" ), "NMSet" ) == 1 )
			continue
		endif
		
		wnote = "WPrefix:" + StrVarOrDefault( "CurrentPrefix", StrVarOrDefault( "WavePrefix", "" ) )
		
		if ( StringMatch( setName, "SetX" ) == 1 )
			wnote += "\rExcluding:" + num2str( NMSetXType() )
		endif
		
		NMNoteType( setName, "NMSet", "Wave#", "True ( 1 ) / False ( 0 )", wnote )
		
		Note $setName, "DEPRECATED: Set waves are no longer utilized by NeuroMatic. Please use Set list string variables instead."
		
	endfor

End // NMSetsWavesTag

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsListsUpdateNewChannels()

	String setList = NMSetsList()
	
	NMSetsWavesKill()
	
	NMSetsListsToWaves( setList )
	
	NMSetsKillNoUpdate( setList )
	NMSetsWavesToLists( setList )
	
	NMSetsWavesKill()
	
End // NMSetsListsUpdateNewChannels

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Sets Panel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelName()

	return "NM_SetsPanel"

End // NMSetsPanelName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelList()

	String prefixFolder = CurrentNMPrefixFolder()

	if ( strlen( prefixFolder ) > 0 )
		return NMSetsWavesList( prefixFolder, 0 )
	endif
	
	return ""

End // NMSetsPanelList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelCall()

	NMCmdHistory( "NMSetsPanel", "" )
	
	return NMSetsPanel()

End // NMSetsPanelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanel()
	
	Variable x1, x2, y1, y2, width = 600, height = 415
	Variable x0 = 35, y0 = 15, xinc = 100, yinc = 35
	
	String firstSet, setName, setList
	
	String prefixFolder = CurrentNMPrefixFolder()
	String pname = NMSetsPanelName()
	String tname = pname + "Table"
	
	Variable numWaves = NMNumWaves()
	
	Variable fs = NMPanelFsize()
	Variable xPixels = NMComputerPixelsX()
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( NMSetsOK() == 0 ) )
		return -1
	endif
	
	if ( WinType( pname ) > 0 )
		DoWindow /F $pname
		return 0
	endif
	
	NMSetsWavesKill()
	NMSetsListsToWavesAll()
	
	setList = NMSetsPanelList()
	
	firstSet = StringFromList( 0, setList )
	
	x1 = ( xPixels - width ) /2
	y1 = 140
	x2 = x1 + width
	y2 = y1 + height
	
	setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	
	if ( strlen( setName ) == 0 )
		SetNMstr( prefixFolder+"SetsDefineSelect", firstSet )
	endif
	
	CheckNMvar( prefixFolder+"SetsFromWave", 0 )
	CheckNMvar( prefixFolder+"SetsToWave", max( numwaves-1, 0 ) )
	CheckNMvar( prefixFolder+"SetsSkipWaves", 0 )
	CheckNMvar( prefixFolder+"SetsDefineValue", 1 )
	
	DoWindow /K$pname
	NewPanel /K=1/N=$pname/W=( x1,y1,x2,y2 ) as "Edit Sets"
	SetWindow $pname hook=NMSetsHook
	
	PopupMenu NM_SetsMenu, title=" ", pos={x0+215,y0}, size={0,0}, bodyWidth=160, fsize=fs
	PopupMenu NM_SetsMenu, mode=1, value=" ", proc=NMSetsPanelPopup
	
	x0 = 35
	y0 += 65
	
	GroupBox NM_SetsPanelGrp, title = "Define ( 010101... )", pos={x0-20,y0-30}, size={310,135}, fsize=fs
	
	SetVariable NM_SetsFromWave, title="FROM wave: ", limits={0,numWaves-1,1}, pos={x0,y0+0*yinc}, size={145,50}
	SetVariable NM_SetsFromWave, value=$( prefixFolder+"SetsFromWave" ), fsize=fs, proc=NMSetsPanelVariable
	
	SetVariable NM_SetsToWave, title="TO wave: ", limits={0,numWaves-1,1}, pos={x0,y0+1*yinc}, size={145,50}
	SetVariable NM_SetsToWave, value=$( prefixFolder+"SetsToWave" ), fsize=fs, proc=NMSetsPanelVariable
	
	SetVariable NM_SetsSkipWaves, title="SKIP every other: ", limits={0,numWaves,1}, pos={x0,y0+2*yinc}, size={145,50}
	SetVariable NM_SetsSkipWaves, value=$( prefixFolder+"SetsSkipWaves" ), fsize=fs, proc=NMSetsPanelVariable
	
	PopupMenu NM_SetsDefineValue, title="value: ", pos={x0+260,y0+1*yinc}, size={0,0}, bodyWidth=50
	PopupMenu NM_SetsDefineValue, mode=1, value="0;1;", proc=NMSetsPanelPopup, fsize=fs
	
	y0 += 145
	
	GroupBox NM_SetsPanelGrp2, title = "Function", pos={x0-20,y0-25}, size={310,60}, fsize=fs
	
	PopupMenu NM_SetsArg1, title=" ", pos={x0+90,y0}, size={0,0}, bodyWidth=100, fsize=fs
	PopupMenu NM_SetsArg1, mode=1, value=" ", proc=NMSetsPanelPopup
	
	PopupMenu NM_SetsOp, title=" ", pos={x0+165,y0}, size={0,0}, bodyWidth=65, fsize=fs
	PopupMenu NM_SetsOp, mode=1, value=" ;AND;OR;", proc=NMSetsPanelPopup
	
	PopupMenu NM_SetsArg2, title=" ", pos={x0+275,y0}, size={0,0}, bodyWidth=100, fsize=fs
	PopupMenu NM_SetsArg2, mode=1, value=" ", proc=NMSetsPanelPopup
	
	x0 = 25
	y0 += 55
	yinc = 35
	
	Button NM_SetsPanelExecute, title="Execute", pos={x0,y0}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	Button NM_SetsPanelClear, title="Clear", pos={x0+1*xinc,y0}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	Button NM_SetsPanelInvert, title="Invert", pos={x0+2*xinc,y0}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	
	Button NM_SetsPanelNew, title="New", pos={x0,y0+1*yinc}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	Button NM_SetsPanelCopy, title="Copy", pos={x0+1*xinc,y0+1*yinc}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	Button NM_SetsPanelKill, title="Kill", pos={x0+2*xinc,y0+1*yinc}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	
	x0 += 50
	
	Button NM_SetsPanelCancel, title="Cancel", pos={x0,y0+2*yinc}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	Button NM_SetsPanelSaveClose, title="Save & Close", pos={x0+1*xinc,y0+2*yinc}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	Button NM_SetsPanelSaveClose, valueColor=(65535,0,0)
	
	NMSetsPanelUpdate( 1 )
	
End // NMSetsPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelUpdate( updateTable )
	Variable updateTable // ( 0 ) no ( 1 ) yes
	
	Variable md, dis
	
	String prefixFolder = CurrentNMPrefixFolder()
	String currentPrefix = CurrentNMWavePrefix()
	
	String setList = NMSetsPanelList()
	String pname = NMSetsPanelName()
	String displayList = NMSetsDisplayList()
	
	if ( ( WinType( pname ) != 7 ) || ( strlen( prefixFolder ) == 0 ) )
		return -1
	endif
	
	Variable numWaves = NMNumWaves()
	
	Variable grpsOn = NMGroupsAreOn()
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	
	Variable value = NumVarOrDefault( prefixFolder+"SetsDefineValue", 1 )
	
	String arg1 = StrVarOrDefault( prefixFolder+"SetsFxnArg1", "" )
	String op = StrVarOrDefault( prefixFolder+"SetsFxnOp", " " )
	String arg2 = StrVarOrDefault( prefixFolder+"SetsFxnArg2", "" )
	
	DoWindow /T $pname, "Edit Sets : " + CurrentNMFolder( 0 ) + " : " + currentPrefix
	
	md = WhichListItem( setName, NMSetsPanelSelectMenu() )
	
	if ( md >= 0 )
		md += 1
	endif
	
	PopupMenu NM_SetsMenu, win=$pname, mode=max(md,1), value=NMSetsPanelSelectMenu()
	
	if ( strlen( arg1 ) > 0 )
		dis = 2
	endif
	
	GroupBox NM_SetsPanelGrp, win=$pname, disable=dis
	
	SetVariable NM_SetsFromWave, win=$pname, disable=dis
	SetVariable NM_SetsToWave, win=$pname, disable=dis
	SetVariable NM_SetsSkipWaves, win=$pname, disable=dis
	
	md = WhichListItem( num2str( value ), "0;1;" )
	
	if ( md >= 0 )
		md += 1
	endif
	
	PopupMenu NM_SetsDefineValue, win=$pname, mode=max(md,1), value="0;1;", disable=dis
	
	dis = 2
	
	if ( strlen( arg1 ) > 0 )
		dis = 0
	endif
	
	GroupBox NM_SetsPanelGrp2, win=$pname, title = setName + " =", disable=dis
	
	md = WhichListItem( arg1, NMSetsPanelArgMenu() )
	
	if ( md >= 0 )
		md += 1
	endif
	
	PopupMenu NM_SetsArg1, win=$pname, mode=max(md,1), value=NMSetsPanelArgMenu()
	
	md = 1
	
	if ( dis == 0 )
	
		md = WhichListItem( op, " ;AND;OR;" )
		
		if ( md >= 0 )
			md += 1
		endif
		
	endif
	
	PopupMenu NM_SetsOp, win=$pname, mode=max(md,1), value=" ;AND;OR;", disable=dis
	
	md = 1
	
	if ( dis == 0 )
	
		md = WhichListItem( arg2, NMSetsPanelArgMenu() )
		
		if ( md >= 0 )
			md += 1
		endif
	
	endif
	
	PopupMenu NM_SetsArg2, win=$pname, mode=max(md,1), disable=dis, value=NMSetsPanelArgMenu()
	
	dis = 0
	
	if ( WhichListItem( setName, "Set1;Set2;SetX;All;" ) >= 0 )
		dis = 2
	endif
	
	if ( updateTable == 1 )
		NMSetsPanelTable( 1 )
	endif

End // NMSetsPanelUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelTable( addWavesToTable )
	Variable addWavesToTable // ( 0 ) no ( 1 ) yes
	
	Variable ccnt, wcnt, x1 = 350, x2 = 1500, y1 = 0, y2 = 1000
	String wlist, wname, txt, setList
	
	String prefixFolder = CurrentNMPrefixFolder()
	String currentPrefix = CurrentNMWavePrefix()
	
	String pname = NMSetsPanelName()
	String tname = pname + "Table"
	String child = pname + "#" + tname
	
	if ( ( WinType( pname ) != 7 ) || ( strlen( prefixFolder ) == 0 ) )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	String arg1 = StrVarOrDefault( prefixFolder+"SetsFxnArg1", "" )
	String arg2 = StrVarOrDefault( prefixFolder+"SetsFxnArg2", "" )
	
	String clist = ChildWindowList( pname )
	
	if ( WhichListItem( tname, clist ) < 0 )
	
		Edit /Host=$pname/N=$tname/W=( x1, y1, x2, y2 )
		ModifyTable title( Point )= currentPrefix
		
	else
	
		setList = NMFolderWaveList( prefixFolder, "*", ";","WIN:"+child, 1 )
	
		for ( wcnt = 0; wcnt < ItemsInList( setList ); wcnt += 1 )
			RemoveFromTable /W=$child $StringFromList( wcnt, setList )
		endfor
	
	endif
	
	if ( addWavesToTable == 0 )
		return 0
	endif
	
	setList = AddListItem( setName, "", ";", inf )
	
	if ( StringMatch( arg1[0,4], "Group" ) == 1 )
		arg1 = "" // "Group"
	elseif ( StringMatch( arg2[0,4], "Group" ) == 1 )
		arg2 = "" // "Group"
	endif
	
	if ( strlen( arg1 ) > 0 )
		setList = AddListItem( arg1, setList, ";", inf )
	endif
	
	if ( strlen( arg2 ) > 0 )
		setList = AddListItem( arg2, setList, ";", inf )
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( setList ) ; wcnt += 1 )
	
		setName = prefixfolder + StringFromList( wcnt, setList )
		
		if ( WaveExists( $setName ) == 1 )
			AppendToTable /W=$child $setName
		endif
	
	endfor
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
	
		wname = NMChanWaveListName( ccnt )
		
		if ( WaveExists( $wname ) == 1 )
			AppendToTable /W=$child $wname
			ModifyTable /W=$child width($wname)=100
		endif
	
	endfor
	
	return 0

End // NMSetsPanelTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelSelectMenu()

	String setList
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
	
		setList = NMSetsPanelList()
		
		if ( ItemsInList( setList ) > 0 )
			return " ;" + setList
		endif
	
	endif

	return "None"

End // NMSetsPanelSelectMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelArgMenu()

	String setList
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
	
		setList = NMSetsPanelList() + NMGroupsList( 1 )
	
		if ( ItemsInList( setList ) > 0 )
			return " ;" + setList
		endif
		
	endif

	return "None"

End // NMSetsPanelArgMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )
	
	NMSetsPanelFxnCall( fxn, "" )
	
End // NMSetsPanelVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelButton( ctrlName ) : ButtonControl
	String ctrlName
	
	if ( CheckCurrentFolder() == 0 )
		return 0
	endif
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )

	NMSetsPanelFxnCall( fxn, "" )
	
End // NMSetsPanelButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	if ( CheckCurrentFolder() == 0 )
		return 0
	endif
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )
	
	NMSetsPanelFxnCall( fxn, popStr )

End // NMSetsPanelPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	if ( CheckCurrentFolder() == 0 )
		return 0
	endif
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )
	
	NMSetsPanelFxnCall( fxn, num2istr( checked ) )

End // NMSetsPanelCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsHook( infoStr )
	String infoStr
	
	String event= StringByKey( "EVENT", infoStr )
	String win= StringByKey( "WINDOW", infoStr )
	
	if ( StringMatch( win, NMSetsPanelName() ) == 0 )
		return 0
	endif

	strswitch( event )
		case "kill":
			NMSetsWavesKill()
	endswitch

End // NMSetsHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelFxnCall( fxn, select )
	String fxn, select
	
	Variable snum = str2num( select )
	
	if ( NMSetsOK() == 0 )
		return -1
	endif
	
	strswitch( fxn )
	
		case "SetsMenu":
			return NMSetsPanelSelect( select )
		
		case "SetsFromWave":
		case "SetsToWave":
		case "SetsSkipWaves":
			break
	
		case "SetsDefineValue":
			return NMSetsPanelValue( snum )
			
		case "SetsOp":
			return NMSetsPanelOp( select )
			
		case "SetsArg1":
			return NMSetsPanelArg1( select )
			
		case "SetsArg2":
			return NMSetsPanelArg2( select )
			
		case "SetsPanelExecute":
			return SetsPanelExecute()
			
		case "SetsPanelClear":
			return NMSetsPanelClear()
			
		case "SetsPanelInvert":
			return NMSetsPanelInvert()
	
		case "SetsPanelNew":
			return strlen( NMSetsPanelNew( 0 ) )
			
		case "SetsPanelCopy":
			return strlen( NMSetsPanelNew( 1 ) )
			
		case "SetsPanelKill":
			return NMSetsPanelKill()
			
		case "SetsPanelCancel":
			return NMSetsPanelCancel()
			
		case "SetsPanelSaveClose":
			return NMSetsPanelSaveClose()
			
	endswitch
	
	return -1

End // NMSetsPanelFxnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelSelect( setName )
	String setName // ( "" ) for current
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	String pname = NMSetsPanelName()
	String setList = NMSetsPanelList()
	
	if ( ( WinType( pname ) != 7 ) || ( strlen( prefixFolder ) == 0 ) )
		return -1
	endif
	
	if ( WhichListItem( setName, setList ) < 0 )
		setName = ""
	endif
	
	SetNMstr( prefixFolder+"SetsDefineSelect", setName )
	
	NMSetsPanelUpdate( 1 )
	
End // NMSetsPanelSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelValue( value )
	Variable value
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
		SetNMvar( prefixFolder+"SetsDefineValue", value )
	endif
	
	NMSetsPanelUpdate( 0 )
	
End // NMSetsPanelValue

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelOp( op )
	String op
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
		SetNMstr( prefixFolder+"SetsFxnOp", op )
	endif
	
	NMSetsPanelUpdate( 0 )
	
End // NMSetsPanelOp

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelArg1( arg )
	String arg
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( StringMatch( arg, " " ) == 1 )
		arg = ""
	endif
	
	if ( strlen( prefixFolder ) > 0 )
		SetNMstr( prefixFolder+"SetsFxnArg1", arg )
	endif
	
	NMSetsPanelUpdate( 1 )
	
End // NMSetsPanelArg1

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelArg2( arg )
	String arg
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( StringMatch( arg, " " ) == 1 )
		arg = ""
	endif
	
	if ( strlen( prefixFolder ) > 0 )
		SetNMstr( prefixFolder+"SetsFxnArg2", arg )
	endif
	
	NMSetsPanelUpdate( 1 )
	
End // NMSetsPanelArg2

//****************************************************************
//****************************************************************
//****************************************************************

Function SetsPanelExecute()
	
	String prefixFolder = CurrentNMPrefixFolder()
	String arg1 = StrVarOrDefault( prefixFolder+"SetsFxnArg1", "" )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( strlen( arg1 ) > 0 )
		return NMSetsPanelFunction()
	else
		return NMSetsPanelDefine()
	endif

End // SetsPanelExecute

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelDefine()

	Variable wlimit = NMNumWaves() - 1
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	Variable first = NumVarOrDefault( prefixFolder+"SetsFromWave", Nan )
	Variable last = NumVarOrDefault( prefixFolder+"SetsToWave", Nan )
	Variable skip = NumVarOrDefault( prefixFolder+"SetsSkipWaves", 0 )
	Variable value = NumVarOrDefault( prefixFolder+"SetsDefineValue", 1 )
	
	if ( WaveExists( $prefixFolder+setName ) == 0 )
		return -1
	endif
	
	first = max( first, 0 )
	first = min( first, wlimit )
	
	last = max( last, 0 )
	last = min( last, wlimit )
	
	skip = max( skip, 0 )
	skip = min( skip, wlimit )
	
	if ( numtype( skip ) > 0 )
		skip = 0
	endif
	
	if ( numtype( first * last * skip ) > 0 )
		NMDoAlert( "Abort NMSetsPanelDefine: wave number out of bounds." )
		return -1
	endif
	
	Wave wtemp = $prefixFolder+setName
	
	wtemp[first,last;abs( skip )+1] = value

End // NMSetsPanelDefine

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelFunction()

	Variable wcnt, grp1 = Nan, grp2 = Nan
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	String arg1 = StrVarOrDefault( prefixFolder+"SetsFxnArg1", "" )
	String op = StrVarOrDefault( prefixFolder+"SetsFxnOp", " " )
	String arg2 = StrVarOrDefault( prefixFolder+"SetsFxnArg2", "" )
	
	if ( WaveExists( $prefixFolder+setName ) == 0 )
		return -1
	endif
	
	if ( StringMatch( arg1[0,4], "Group" ) == 1 )
		grp1 = str2num( arg1[5,inf] )
	endif
	
	if ( StringMatch( arg2[0,4], "Group" ) == 1 )
		grp2 = str2num( arg2[5,inf] )
	endif
	
	Wave wtemp = $prefixFolder+setName
	
	if ( StringMatch( setName, arg1 ) == 0 )
	
		if ( numtype( grp1 ) == 0 )
		
			for ( wcnt = 0 ; wcnt < numpnts( wtemp ) ; wcnt += 1 )
				wtemp[ wcnt ] = ( NMGroupsNum( wcnt ) == grp1 )
			endfor
	
		elseif ( WaveExists( $prefixFolder+arg1 ) == 1 )
	
			Wave warg = $prefixFolder+arg1
		
			wtemp = warg
			
		else
		
			return -1
			
		endif
		
	endif
	
	if ( strlen( arg2 ) > 0 ) 
	
		if ( numtype( grp2 ) == 0 )
		
			for ( wcnt = 0 ; wcnt < numpnts( wtemp ) ; wcnt += 1 )
			
				strswitch( op )
			
					case "AND":
						wtemp[ wcnt ] = ( wtemp[ wcnt ] && ( NMGroupsNum( wcnt ) == grp2 ) )
						break
				
					case "OR":
						wtemp[ wcnt ] = ( wtemp[ wcnt ] || ( NMGroupsNum( wcnt ) == grp2 ) )
						break
			
				endswitch
			
			endfor
		
		elseif  ( WaveExists( $prefixFolder+arg2 ) == 1 )
	
			Wave warg = $prefixFolder+arg2
		
			strswitch( op )
			
				case "AND":
					wtemp = wtemp && warg
					break
			
				case "OR":
					wtemp = wtemp || warg
					break
			
			endswitch
		
		else
		
			return -1
			
		endif
		
	endif
	
	return 0

End // NMSetsPanelFunction

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelClear()

	String prefixFolder = CurrentNMPrefixFolder()
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	
	setName = prefixFolder + setName
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( WaveExists( $setName ) == 0 ) )
		return -1
	endif
	
	Wave wtemp = $setName
	
	wtemp = 0

End // NMSetsPanelClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelInvert()

	String prefixFolder = CurrentNMPrefixFolder()
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	
	setName = prefixFolder + setName
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( WaveExists( $setName ) == 0 ) )
		return -1
	endif
	
	Wave wtemp = $setName
	
	wtemp = !wtemp

End // NMSetsPanelInvert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelNameNext()

	Variable icnt, currentChan = CurrentNMChannel()
	String setName, setList, strVarName
	
	if ( NMSetsOK() == 0 )
		return ""
	endif
	
	for ( icnt = 1; icnt < 99; icnt += 1 )
	
		setName = "Set" + num2istr( icnt )
		
		if ( ( AreNMSets( setName ) == 0 ) && ( AreNMSetsWaves( setName ) == 0 ) )
			return setName
		endif
		
	endfor

	return ""
	
End // NMSetsNamePanelNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelNewNameAsk()

	String setName = NMSetsPanelNameNext()
	
	Prompt setName, "enter new set name:"
	DoPrompt "New Sets", setName

	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return setName
	
End // NMSetsPanelNewNameAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelNew( copyFlag )
	Variable copyFlag // copy currently select Set to new Set ( 0 ) no ( yes )
	
	String setName, newName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	newName = NMSetsPanelNewNameAsk()
	
	if ( strlen( newName ) == 0 )
		return "" // cancel
	endif
	
	if ( WaveExists( $prefixFolder+newName ) == 1 )
		NMDoAlert( "Abort NMSetsPanelCopy: Set already exists: " + newName )
		return ""
	endif

	Make /B/U/O/N=( NMNumWaves() ) $prefixFolder+newName = 0
	
	NMSetsWavesTag( prefixFolder+newName )
	
	if ( copyFlag == 1 )
	
		setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
		
		if ( ( WaveExists( $prefixFolder+setName ) == 1 ) && ( WaveExists( $prefixFolder+newName ) == 1  ) )
		
			Wave newWave = $prefixFolder+newName
			Wave selectWave = $prefixFolder+setName
			
			newWave = selectWave
			
		endif
	
	endif
	
	SetNMstr( prefixFolder+"SetsDefineSelect", newName )
	
	NMSetsPanelUpdate( 1 )
	
	return newName

End // NMSetsPanelCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelKill()

	String firstSet
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	
	DoAlert 1, "Alert: this function will only delete " + setName + " from the Edit panel. Do you want to continue?"
		
	if ( V_flag != 1 )
		return 0
	endif
	
	NMSetsPanelTable( 0 )
	
	KillWaves /Z $prefixFolder+setName
	
	firstSet = StringFromList( 0, NMSetsPanelList() )
	
	SetNMstr( prefixFolder+"SetsDefineSelect", firstSet )
	
	NMSetsPanelUpdate( 1 )
	
End // NMSetsPanelKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelCancel()
	
	DoWindow /K $NMSetsPanelName()
	
	NMSetsWavesKill()

End // NMSetsPanelCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelSaveClose()
	
	String setList = NMSetsPanelList()
	
	NMSetsKillNoUpdate( setList )
	NMSetsWavesToLists( setList )
	
	DoWindow /K $NMSetsPanelName()
	
	NMSetsWavesKill()
	
	UpdateNMWaveSelectLists()
	UpdateNMPanelSets( 1 )

End // NMSetsPanelSaveClose

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsFxnFilter( n1, n2, grp, operation ) // DEPRECATED, not used anymore
	Variable n1, n2, grp
	String operation // see strswitch below
	
	//NMDeprecated( "NMSetsFxnFilter", "NMSetsEquationFilter" )
	
	strswitch( operation )
	
		case "AND":
		case "&":
		case "&&":
			if ( grp == -1 )
				return n1 && n2
			else
				return n1 && NMGroupFilter( n2, grp )
			endif
			break
			
		case "OR":
		case "|":
		case "||":
			if ( grp == -1 )
				return n1 || n2
			else
				return n1 || ( NMGroupFilter( n2, grp ) )
			endif
			break
			
		case "EQUALS":
		case "=":
			if ( grp == -1 )
				return n2
			else
				return NMGroupFilter( n2, grp )
			endif
			break
			
		default:
			return 0
	
	endswitch
	
End // NMSetsFxnFilter

//****************************************************************
//****************************************************************
//****************************************************************
