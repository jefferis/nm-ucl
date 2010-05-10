#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Groups Functions
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

Function NMGroupsOK()

	if ( strlen( CurrentNMPrefixFolder() ) > 0 )
		return 1
	endif
	
	NMDoAlert( "No Groups. You may need to select " + NMQuotes( "Wave Prefix" ) + " first." )
	
	return 0

End // NMGroupsOK

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsAreOn()
	
	if ( NMGroupsNumCount() <= 0 )
		return 0
	elseif ( NeuroMaticVar( "GroupsOn" ) == 0 )
		return 0
	endif
	
	return 1
	
End // NMGroupsAreOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsOnToggle()

	Variable on = BinaryInvert( NMGroupsAreOn() )
	
	NMCmdHistory( "NMGroupsOn", NMCmdNum( on, "" ) )
	
	return NMGroupsOn( on )
	
End // NMGroupsOnToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsOn( on )
	Variable on // ( 0 ) no ( 1 ) yes
	
	on = BinaryCheck( on )
	
	if ( on == NeuroMaticVar( "GroupsOn" ) )
		return on
	endif
	
	SetNeuroMaticVar( "GroupsOn", on )
	
	UpdateNMGroups()
	
	return on
	
End // NMGroupsOn

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMGroups()

	String prefixFolder = CurrentNMPrefixFolder()
	String gwName = NMGroupsWaveName()
	
	if ( WaveExists( $gwName ) == 1 )

		if ( NMGroupsWaveToLists( gwName ) >= 0 )
			KillWaves /Z $gwName
		endif
	
	endif
	
End // CheckNMGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMGroups()

	UpdateNMWaveSelectLists()
	UpdateNMPanel( 0 )
	NMCurrentWaveSetNoUpdate( Nan )
		
End // UpdateNMGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsCall( fxn, select )
	String fxn
	String select
	
	Variable snum = str2num( select )
	
	if ( NMGroupsOK() == 0 )
		return -1
	endif

	strswitch( fxn )
	
		case "On":
			NMGroupsOn( 1 )
			break
			
		case "Off":
			NMGroupsOn( 0 )
			break
			
		case "On/Off":
			return NMGroupsOnToggle()
			
		case "Define":
			return NMGroupsDefineCall()
	
		case "Clear":
		case "Kill":
			return NMGroupsClearCall()
			
		case "Convert":
			return NMGroupsConvertCall()
			
		case "Table":
		case "Panel":
		case "Edit":
			return NMGroupsPanelCall()
			
		default:
		
			snum = str2num( fxn[7,inf] )
			
			if ( numtype( snum ) > 0 )
				break
			endif
		
			if ( StringMatch( fxn[0,6], "Groups=" ) == 1 )
				NMGroupsSequence( "0,"+num2istr( snum-1 ), 0, inf, 1, 1 )
			elseif ( StringMatch( fxn[0,6], "Blocks=" ) == 1 )
				NMGroupsSequence( "0,"+num2istr( snum-1 ), 0, inf, snum, 1 )
			else
				NMDoAlert( "NMGroupsCall: unrecognized function call: " + fxn )
			endif
			
	endswitch
	
	return -1
	
End // NMGroupsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsName( grpNum )
	Variable grpNum
		
	if ( numtype( grpNum ) == 0 )
		return "Group" + num2istr( grpNum )
	endif
	
	return ""

End // NMGroupsName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsWaveList( grpNum, chanNum )
	Variable grpNum // group number
	Variable chanNum // channel number
	
	return NMSetsWaveList( NMGroupsName( grpNum ), chanNum )
	
End // NMGroupsWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsRemove( waveNum )
	Variable waveNum
	
	Variable gcnt, ccnt
	String grpList, wName, grpName, thisfxn = "NMGroupsRemove"
	
	if ( NMGroupsOK() == 0 )
		return -1
	endif
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	if ( ( waveNum < 0 ) || ( waveNum >= NMNumWaves() ) )
		return NMError( 1, thisfxn, "waveNum", num2istr( waveNum ) )
	endif
	
	grpList = NMGroupsList(1)
	
	for ( gcnt = 0 ; gcnt < ItemsInList( grpList ) ; gcnt += 1 )
		
		grpName = StringFromList( gcnt, grpList )
		
		for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
		
			wName = NMChanWaveName( ccnt, waveNum )
			NMSetsWaveListRemove( wName, grpName, ccnt )
			
		endfor
		
	endfor
	
	return 0
	
End // NMGroupsRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsRemoveWaveList( wList )
	String wList
	
	Variable gcnt, ccnt
	String grpList, grpName
	
	if ( NMGroupsOK() == 0 )
		return -1
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	grpList = NMGroupsList(1)
	
	for ( gcnt = 0 ; gcnt < ItemsInList( grpList ) ; gcnt += 1 )
		
		grpName = StringFromList( gcnt, grpList )
		
		for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
			NMSetsWaveListRemove( wList, grpName, ccnt )
		endfor
		
	endfor
	
	return 0
	
End // NMGroupsRemoveWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsAssignCall( grpNum )
	Variable grpNum // group number
	
	Variable currentWave = CurrentNMWave()
	String vlist = ""
	
	vlist = NMCmdNum( currentWave, vlist )
	vlist = NMCmdNum( grpNum, vlist )
	NMCmdHistory( "NMGroupsAssign", vlist )
	
	return NMGroupsAssign( currentWave, grpNum )
	
End // NMGroupsAssignCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsAssign( waveNum, grpNum )
	Variable waveNum // wave number ( -1 ) for current
	Variable grpNum // group number
	
	Variable gcnt, ccnt
	String grpList, wName, thisfxn = "NMGroupsAssign"
	
	String grpName = NMGroupsName( grpNum )
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMGroupsOK() == 0 )
		return -1
	endif
	
	if ( strlen( grpName ) == 0 )
		return -1
	endif
	
	SetNeuroMaticVar( "GroupsOn", 1 )
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	if ( ( waveNum < 0 ) || ( waveNum >= NMNumWaves() ) )
		return NMError( 1, thisfxn, "waveNum", num2istr( waveNum ) )
	endif
	
	NMGroupsRemove( waveNum )
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
		wName = NMChanWaveName( ccnt, waveNum )
		NMSetsWaveListAdd( wName, grpName, ccnt )
	endfor
	
	UpdateNMGroups()
		
	return 0

End // NMGroupsAssign

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsList( type )
	Variable type // ( 0 ) e.g. "0;1;2;" ( 1 ) e.g. "Group0;Group1;Group2;"
	
	Variable scnt
	String setName, grpList = ""
	
	String setList = NMSetsListAll()
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( StringMatch( setName[0,4], "Group" ) == 1 )
		
			if ( type == 1 )
				grpList = AddListItem( setName, grpList, ";", inf )
			else
				grpList = AddListItem( setName[5,inf], grpList, ";", inf )
			endif
			
		endif
		
	endfor
	
	if ( type == 1 )
		return SortList( grpList, ";", 16 )
	else
		return SortList( grpList, ";", 2 )
	endif

End // NMGroupsList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupCheck( grpNum )
	Variable grpNum
	
	if ( WhichListItem( num2istr( grpNum ), NMGroupsList( 0 ) ) >= 0 )
		return 1
	else
		return 0
	endif

End // NMGroupCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsNumCount()

	return ItemsInList( NMGroupsList( 0 ) )

End // NMGroupsNumCount

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsFirst( grpSeqStr ) // first group number
	String grpSeqStr // e.g. "0;1;2;" or ( "" ) for current grpSeqStr

	Variable gcnt, grpNum, firstGrp = inf
	
	if ( ItemsInList( grpSeqStr ) == 0 )
		grpSeqStr = NMGroupsList( 0 )
	endif
	
	for ( gcnt = 0 ; gcnt < ItemsInList( grpSeqStr ) ; gcnt += 1 )
	
		grpNum = str2num( StringFromList( gcnt, grpSeqStr ) )
		
		if ( ( numtype( grpNum ) == 0 ) && ( grpNum < firstGrp ) )
			firstGrp = grpNum
		endif
		
	endfor
	
	return firstGrp // e.g. "0"

End // NMGroupsFirst

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsLast( grpSeqStr ) // last group number
	String grpSeqStr // e.g. "0;1;2;" or ( "" ) for current grpSeqStr

	Variable gcnt, grpNum, lastGrp = 0
	
	if ( ItemsInList( grpSeqStr ) == 0 )
		grpSeqStr = NMGroupsList( 0 )
	endif
	
	for ( gcnt = 0 ; gcnt < ItemsInList( grpSeqStr ) ; gcnt += 1 )
	
		grpNum = str2num( StringFromList( gcnt, grpSeqStr ) )
		
		if ( ( numtype( grpNum ) == 0 ) && ( grpNum > lastGrp ) )
			lastGrp = grpNum
		endif
		
	endfor
	
	return lastGrp // e.g. "2"

End // NMGroupsLast

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsNum( waveNum ) // determine group number from wave number
	Variable waveNum // wave number, or ( -1 ) for current
	
	Variable gcnt, ccnt, grpNum, numChannels
	String grpList, wList, wName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return Nan
	endif
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	if ( ( waveNum < 0 ) || ( waveNum >= NMNumWaves() ) )
		return Nan
	endif
	
	grpList = NMGroupsList( 0 )
	
	if ( ItemsInList( grpList ) == 0 )
		return Nan
	endif
	
	numChannels = NMNumChannels()
	
	for ( gcnt = 0 ; gcnt < ItemsInList( grpList ) ; gcnt += 1 )
	
		grpNum = str2num( StringFromList( gcnt, grpList ) )
		
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			wList = NMGroupsWaveList( grpNum, ccnt )
			wName = NMChanWaveName( ccnt, waveNum )
			
			if ( WhichListItem( wName, wList ) >= 0 )
				return grpNum
			endif
			
		endfor
		
	endfor
	
	return Nan
	
End // NMGroupsNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsClearCall()

	DoAlert 2, "Are you sure you want to clear all Groups?"
	
	if ( V_Flag != 1 )
		return 0 // chancel
	endif

	NMCmdHistory( "NMGroupsClear", "" )
	
	return NMGroupsClear()

End // NMGroupsClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsClear()
	
	NMSetsKillNoUpdate( NMGroupsList(1) )
	UpdateNMGroups()
	
	return 0
			
End // NMGroupsClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsClearNoUpdate()
	
	NMSetsKillNoUpdate( NMGroupsList(1) )
	
	return 0
			
End // NMGroupsClearNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsDefineCall()

	String grpSeqStr
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMGroupsOK() == 0 )
		return -1
	endif
	
	Variable numWaves = NMNumWaves()
	
	Variable numGrps = NMGroupsNumCount()
	Variable firstGrp = NMGroupsFirst( "" )
	Variable fromWave = NumVarOrDefault( prefixFolder+"GroupsFromWave", 0 )
	Variable toWave = NumVarOrDefault( prefixFolder+"GroupsToWave", numWaves - 1 )
	Variable blocks = NumVarOrDefault( prefixFolder+"GroupsWaveBlocks", 1 )
	Variable clearFirst = 1 + NumVarOrDefault( prefixFolder+"GroupsClearFirst", 1 )
	
	if ( ( numtype( numGrps ) > 0 ) || ( numGrps < 1 ) )
		numGrps = NMGroupsNumDefault()
	endif
	
	if ( ( numtype( firstGrp ) > 0 ) || ( firstGrp < 0 ) )
		firstGrp = 0
	endif
	
	Prompt numGrps, "number of groups:"
	Prompt firstGrp, "first group number:"
	Prompt fromWave, "define sequence from wave:"
	Prompt toWave, "define sequence to wave:"
	Prompt blocks, "in blocks of:"
	Prompt clearFirst, "clear Groups first?", popup "no;yes"
	
	DoPrompt "Define Group Sequence", numGrps, firstGrp, fromWave, toWave, blocks, clearFirst
	
	if ( V_flag == 1 )
		return 0 // user cancelled
	endif
	
	clearFirst -= 1
	
	SetNMvar( prefixFolder+"NumGrps" , numGrps )
	SetNMvar( prefixFolder+"FirstGrp" , firstGrp )
	SetNMvar( prefixFolder+"GroupsFromWave" , fromWave )
	SetNMvar( prefixFolder+"GroupsToWave" , toWave )
	SetNMvar( prefixFolder+"GroupsWaveBlocks" , blocks )
	SetNMvar( prefixFolder+"GroupsClearFirst" , clearFirst )
	
	grpSeqStr = num2istr( firstGrp ) + "," + num2istr( firstGrp + numGrps - 1 )
	
	grpSeqStr = RangeToSequenceStr( grpSeqStr )
	
	NMGroupsSequenceCall( grpSeqStr, fromWave, toWave, blocks, clearFirst )
	
	return 0

End // NMGroupsDefineCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsSequenceCall( grpSeqStr, fromWave, toWave, blocks, clearFirst )
	String grpSeqStr
	Variable fromWave, toWave, blocks, clearFirst
	
	String vlist = ""
	
	vlist = NMCmdList( grpSeqStr, vlist )
	vlist = NMCmdNum( fromWave, vlist )
	vlist = NMCmdNum( toWave, vlist )
	vlist = NMCmdNum( blocks, vlist )
	vlist = NMCmdNum( clearFirst, vlist )
	NMCmdHistory( "NMGroupsSequence", vlist )
	
	return NMGroupsSequence( grpSeqStr, fromWave, toWave, blocks, clearFirst )
	
End // NMGroupsSequenceCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsSequence( grpSeqStr, fromWave, toWave, blocks, clearFirst )
	String grpSeqStr // seq string "0;1;2;3;" or "0,3" for range
	Variable fromWave // starting wave number
	Variable toWave // ending wave number, ( inf ) for all
	Variable blocks // number of blocks in each group ( default = 1 )
	Variable clearFirst // clear all groups before defining sequence ( 0 ) no ( 1 ) yes
	
	Variable bcnt, ccnt, wcnt, gcnt, gcnt2
	String grpNumStr, grpNumStr2, grpName
	String wName, wList = "", thisfxn = "NMGroupsSequence"
	
	Variable numWaves = NMNumWaves()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMGroupsOK() == 0 )
		return ""
	endif
	
	SetNeuroMaticVar( "GroupsOn", 1 )

	if ( ( numtype( fromWave ) > 0 ) || ( fromWave < 0 ) || ( fromWave > numWaves-1 ) )
		fromWave = 0
	endif
	
	if ( ( numtype( toWave ) > 0 ) || ( toWave < 0 ) || ( toWave > numWaves-1 ) )
		toWave = numWaves - 1
	endif
	
	blocks = max( blocks, 1 )
	
	if ( strsearch( grpSeqStr, ",", 0 ) > 0 )
		grpSeqStr = RangeToSequenceStr( grpSeqStr )
	endif
	
	if ( ItemsInList( grpSeqStr ) == 0 )
		return NMErrorStr( 90, thisfxn, "number of groups must be greater than zero", "" )
	endif
	
	if ( clearFirst == 1 )
		NMGroupsClearNoUpdate()
	endif
	
	for ( gcnt = 0 ; gcnt < ItemsInList( grpSeqStr ) ; gcnt += 1 )
	
		grpNumStr = StringFromList( gcnt, grpSeqStr )
		grpName = NMGroupsName( str2num( grpNumStr ) )
		
		for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )

			wList = ""
			gcnt2 = 0
			bcnt = 0
			
			for ( wcnt = fromWave; wcnt <= toWave; wcnt += 1 )
				
				grpNumStr2 = StringFromList( gcnt2, grpSeqStr )
				
				if ( StringMatch( grpNumStr, grpNumStr2 ) == 1 )
					//NMGroupsAssign( wcnt, str2num( grpNumStr ), 0 ) // SLOW
					wName = NMChanWaveName( ccnt, wcnt )
					wList += wName + ";"
				endif
				
				bcnt += 1
				
				if ( bcnt == blocks )
				
					bcnt = 0
					gcnt2 += 1
					
					if ( gcnt2 >= ItemsInList( grpSeqStr ) )
						gcnt2 = 0
					endif
				
				endif
				
			endfor
			
			NMGroupsRemoveWaveList( wList )
			NMSetsWaveListAdd( wList, grpName, ccnt )
		
		endfor
	
	endfor
	
	SetNMstr( prefixFolder+"GroupsSeqStr" , grpSeqStr )
	
	UpdateNMGroups()
	
	return grpSeqStr

End // NMGroupsSequence

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsSequenceBasic( numGrps )
	Variable numGrps

	Variable firstGrp = 0
	Variable fromWave = 0
	Variable toWave = inf
	Variable blocks = 1
	Variable clearFirst = 1
	String grpSeqStr, thisfxn = "NMGroupsSequenceBasic"
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMGroupsOK() == 0 )
		return ""
	endif
	
	if ( numtype( numGrps) > 0 )
		return NMErrorStr( 10, thisfxn, "numGrps", num2istr( numGrps ) )
	endif
	
	grpSeqStr = num2istr( firstGrp ) + "," + num2istr( firstGrp + numGrps - 1 )
	
	return NMGroupsSequence( grpSeqStr, fromWave, toWave, blocks, clearFirst )

End // NMGroupsSequenceBasic

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsConvertCall()

	String wName = " ", wList, vlist = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wList = " ;" + WaveList( "*", ";", "Text:0" )
	
	Prompt wName, "choose a wave containing your Group sequence:", popup wList
	DoPrompt "Convert a wave to Groups", wName

	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	vlist = NMCmdStr( wName, vlist )
	NMCmdHistory( "NMGroupsConvert", vlist )
	
	return NMGroupsConvert( wName )

End // NMGroupsConvertCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsConvert( wName )
	String wName
	
	String prefixFolder = CurrentNMPrefixFolder()
	String gwName = NMGroupsWaveName()
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, "NMGroupsConvert", "wName", wName )
	endif
	
	if ( NMGroupsOK() == 0 )
		return -1
	endif
	
	Duplicate /O $wName $gwName
	
	NMGroupsWaveToLists( gwName )
	
	KillWaves /Z $gwName
	
	UpdateNMGroups()

	return 0
	
End // NMGroupsConvert

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsNumDefault()

	String prefixFolder = CurrentNMPrefixFolder()
	String subStimFolder = SubStimDF()
	String grpList = NMGroupsList( 0 )

	Variable numGrps = ItemsInList( grpList )
	
	if ( ( numGrps == 0 ) && ( strlen( prefixFolder ) > 0 ) )
		numGrps = NumVarOrDefault( prefixFolder+"NumGrps", 0 )
	endif
	
	if ( ( numGrps == 0 ) && ( strlen( subStimFolder ) > 0 ) )
		numGrps = NumVarOrDefault( subStimFolder+"NumStimWaves", 0 )
	endif
	
	if ( numGrps == 0 )
		numGrps = 3
	endif
	
	return numGrps

End // NMGroupsNumDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsNumFromStr( grpStr )
	String grpStr // string containing group number (i.e. "Group0", or "Set1 x Group1" )
	
	Variable grpNum, icnt
	
	Variable ibgn = strsearch( grpStr, "Group", 0 )
	
	if ( strsearch( grpStr, "All Groups", 0 ) >= 0 )
		return Nan
	endif
	
	if ( ibgn < 0 )
		return Nan
	endif
	
	ibgn += 5
	
	for ( icnt = ibgn; icnt < strlen( grpStr ); icnt += 1 )
		if ( numtype( str2num( grpStr[ibgn,ibgn] ) ) > 0 )
			break
		endif
	endfor
	
	grpNum = str2num( grpStr[ ibgn, icnt-1 ] )
	
	return grpNum
	
End // NMGroupsNumFromStr

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Groups Wave Functions ( old "Group" wave )
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsWaveName()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	return prefixFolder + "Group"

End // NMGroupsWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsWaveToLists( gwName )
	String gwName

	Variable gcnt, ccnt, wcnt, grpNum
	String wName, grpName, grpList = "", wList = ""
	String thisfxn = "NMGroupsWaveToLists"
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( WaveExists( $gwName ) == 0 )
		return NMError( 10, thisfxn, "gwName", gwName )
	endif
	
	Wave wtemp = $gwName
	
	for ( wcnt = 0 ; wcnt < numpnts( $gwName ) ; wcnt += 1 )
	
		grpNum = wtemp[ wcnt ]
		
		if ( ( numtype( grpNum ) == 0 ) && ( grpNum >= 0 ) )
			grpList = NMAddToList( num2istr( grpNum ), grpList, ";" )
		endif
	
	endfor
	
	grpList = SortList( grpList, ";", 2 )
	
	NMGroupsClearNoUpdate()
	
	for ( gcnt = 0 ; gcnt < ItemsInList( grpList ) ; gcnt += 1 )
		
		grpNum = str2num( StringFromList( gcnt, grpList ) )
		grpName = NMGroupsName( grpNum )
		
		for ( ccnt = 0 ; ccnt < NMNumChannels(); ccnt += 1 )
		
			wList = ""
		
			for ( wcnt = 0 ; wcnt < numpnts( wtemp ) ; wcnt += 1 )
			
				if ( wtemp[ wcnt ] == grpNum )
					wName = NMChanWaveName( ccnt, wcnt )
					wList += wName + ";"
				endif
				
			endfor
			
			NMGroupsRemoveWaveList( wList )
			NMSetsWaveListAdd( wList, grpName, ccnt )
		
		endfor
	
	endfor
	
	return 0
	
End // NMGroupsWaveToLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsListsToWave( gwName )
	String gwName

	Variable wcnt, ccnt, gcnt, grpNum, found
	String wName2, grpList, wList, thisfxn = "NMGroupsListsToWave"

	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable numWaves = NMNumWaves()
	Variable numChannels = NMNumChannels()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( numWaves <= 0 )
		return -1
	endif
	
	if ( WaveExists( $gwName ) == 1 )
	
		DoAlert 1, "Alert: wave " + NMQuotes( gwName ) + " already exist. Do you want to overwrite it?"
		
		if ( V_flag != 1 )
			return -1 // cancel
		endif
		
		KillWaves /Z $gwName // try to kill
		
	endif

	grpList = NMGroupsList( 0 )
	
	Make /O/N=(numWaves) $gwName = Nan
	
	NMGroupsTag( gwName )
	
	if ( ItemsInList( grpList ) == 0 )
		return 0
	endif
	
	Wave wtemp = $gwName
	
	for ( wcnt = 0 ; wcnt < numWaves; wcnt += 1 )
	
		found = Nan
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
			wName2 = NMChanWaveName( ccnt, wcnt )
			
			for ( gcnt = 0 ; gcnt < ItemsInlist( grpList ) ; gcnt += 1 )
	
				grpNum = str2num( StringFromList( gcnt, grpList ) )
				wList = NMGroupsWaveList( grpNum, ccnt )
				
				if ( WhichListItem( wName2, wList ) >= 0 )
					found = grpNum
					break
				endif
				
			endfor
			
			if ( numtype( found ) == 0 )
				break
			endif
			
		endfor
		
		wtemp[ wcnt ] = found
		
	endfor
	
	return 0

End // NMGroupsListsToWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsTag( grpList )
	String grpList
	
	Variable icnt
	String wName, wnote
	
	for ( icnt = 0; icnt < ItemsInList( grpList ); icnt += 1 )
	
		wName = StringFromList( icnt, grpList )
		
		if ( WaveExists( $wName ) == 0 )
			continue
		endif
		
		if ( StringMatch( NMNoteStrByKey( wName, "Type" ), "NMGroup" ) == 1 )
			continue
		endif
		
		wnote = "WPrefix:" + StrVarOrDefault( "CurrentPrefix", StrVarOrDefault( "WavePrefix", "" ) )
		NMNoteType( wName, "NMGroup", "Wave#", "Group", wnote )
		
		Note $wName, "DEPRECATED: Group waves are no longer utilized by NeuroMatic. Please use Group list string variables instead."
		
	endfor

End // NMGroupsTag

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsListsUpdateNewChannels()

	String gwName = NMGroupsWaveName()

	KillWaves /Z $gwName
	
	NMGroupsListsToWave( gwName )
	
	NMGroupsWaveToLists( gwName )

	KillWaves /Z $gwName

End // NMGroupsListsUpdateNewChannels

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Groups Panel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsPanelName()

	return "NM_GroupsPanel"
	
End // NMGroupsPanelName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelCall()

	NMCmdHistory( "NMGroupsPanel", "" )

	return NMGroupsPanel()

End // NMGroupsPanelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanel()

	Variable ccnt, x1, x2, y1, y2
	Variable width = 600, height = 375
	Variable x0 = 44, y0 = 45, yinc = 35
	
	String wName
	
	if ( NMGroupsOK() == 0 )
		return -1
	endif
	
	Variable xPixels = NMComputerPixelsX()
	Variable fs = NMPanelFsize()
	
	String pname = NMGroupsPanelName()
	String tname = pname + "Table"
	String child = pname + "#" + tname
	
	String prefixFolder = CurrentNMPrefixFolder()
	String currentPrefix = CurrentNMWavePrefix()
	
	String gwName = NMGroupsWaveName()
	
	Variable numWaves = NMNumWaves()
	
	SetNeuroMaticVar( "GroupsOn", 1 )
	
	if ( WinType( pname ) == 7 )
		DoWindow /F $pname
		return 0
	endif
	
	KillWaves /Z $gwName
	
	NMGroupsListsToWave( gwName )
	
	NMGroupsPanelDefaults()
	
	x1 = 20 + ( xPixels - width ) / 2
	y1 = 140 + 40
	x2 = x1 + width
	y2 = y1 + height
	
	DoWindow /K $pname
	NewPanel /K=1/N=$pname/W=( x1,y1,x2,y2 ) as "Groups"
	SetWindow $pname hook=NMGroupsHook
	DoWindow /T $pname, "Edit Groups : " + CurrentNMFolder( 0 ) + " : " + currentPrefix
	
	GroupBox NM_GrpsPanelBox, title = "Sequence ( 01230123... )", pos={x0-20,y0-25}, size={245,300}, fsize=fs
	
	SetVariable NM_NumGroups, title="number of Groups: ", limits={1,inf,0}, pos={x0,y0}, size={200,50}, fsize=fs
	SetVariable NM_NumGroups, value=$( prefixFolder+"NumGrps" ), proc=NMGroupsPanelSetVariable
	
	SetVariable NM_FirstGroup, title="first Group: ", limits={0,inf,0}, pos={x0,y0+1*yinc}, size={200,50}, fsize=fs
	SetVariable NM_FirstGroup, value=$( prefixFolder+"FirstGrp" ), proc=NMGroupsPanelSetVariable
	
	SetVariable NM_SeqStr, title="sequence: ", pos={x0,y0+2*yinc}, size={200,50}, fsize=fs, frame=0
	SetVariable NM_SeqStr, value=$( prefixFolder+"GroupsSeqStr" ), proc=NMGroupsPanelSetVariable
	
	SetVariable NM_WaveStart, title="start at wave: ", limits={0,numWaves-1,0}, pos={x0,y0+3*yinc}, size={200,50}, fsize=fs
	SetVariable NM_WaveStart, value=$( prefixFolder+"GroupsFromWave" ), proc=NMGroupsPanelSetVariable
	
	SetVariable NM_WaveEnd, title="end at wave: ", limits={0,numWaves-1,0}, pos={x0,y0+4*yinc}, size={200,50}, fsize=fs
	SetVariable NM_WaveEnd, value=$( prefixFolder+"GroupsToWave" ), proc=NMGroupsPanelSetVariable
	
	SetVariable NM_WaveBlocks, title="in blocks of: ", limits={1,inf,0}, pos={x0,y0+5*yinc}, size={200,50}, fsize=fs
	SetVariable NM_WaveBlocks, value=$( prefixFolder+"GroupsWaveBlocks" ), proc=NMGroupsPanelSetVariable
	
	Button NM_Execute, title="Execute", pos={x0,y0+6*yinc}, size={90,20}, fsize=fs, proc=NMGroupsPanelButton
	Button NM_Clear, title="Clear", pos={150,y0+6*yinc}, size={90,20}, fsize=fs, proc=NMGroupsPanelButton
	
	Button NM_Cancel, title="Cancel", pos={x0,335}, size={90,20}, fsize=fs, proc=NMGroupsPanelButton
	
	Button NM_SaveClose, title="Save & Close", pos={150,335}, size={90,20}, fsize=fs, proc=NMGroupsPanelButton
	
	x1 = 0.5
	y1 = 0
	x2 = 1
	y2 = 1
	
	Edit /Host=$pname /N=$tname /W=(x1, y1, x2, y2)
	ModifyTable title( Point )= currentPrefix
	
	if ( WaveExists( $gwName ) == 1 )
		AppendToTable /W=$child $gwName
		ModifyTable /W=$child width($gwName)=60
	endif
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
	
		wName = NMChanWaveListName( ccnt )
		
		if ( WaveExists( $wName ) == 1 )
			AppendToTable /W=$child $wName
			ModifyTable /W=$child width($wName)=100
		endif
	
	endfor
	
End // NMGroupsPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelDefaults()

	Variable icnt
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	Variable numWaves = NumVarOrDefault( prefixFolder+"NumWaves", 0 )
	
	Variable numGrps = NMGroupsNumCount()
	Variable firstGrp = NMGroupsFirst( "" )
	Variable fromWave = NumVarOrDefault( prefixFolder+"GroupsFromWave", Nan )
	Variable toWave = NumVarOrDefault( prefixFolder+"GroupsToWave", Nan )
	Variable blocks = NumVarOrDefault( prefixFolder+"GroupsWaveBlocks", Nan )
	
	String grpSeqStr = StrVarOrDefault( prefixFolder+"GroupsSeqStr", "" )
	
	if ( ( numtype( numGrps ) > 0 ) || ( numGrps < 1 ) )
		numGrps = NMGroupsNumDefault()
		grpSeqStr = ""
	endif
	
	if ( ( numtype( firstGrp ) > 0 ) || ( firstGrp < 0 ) )
		firstGrp = 0
		grpSeqStr = ""
	endif
	
	if ( ( numtype( fromWave ) > 0 ) || ( fromWave < 0 ) || ( fromWave >= numWaves ) )
		fromWave = 0
	endif
	
	if ( ( numtype( toWave ) > 0 ) || ( toWave < 0 ) || ( toWave >= numWaves ) )
		toWave = numWaves - 1
	endif
	
	if ( ( numtype( blocks ) > 0 ) || ( blocks < 1 ) )
		blocks = 1
	endif
	
	if ( ItemsInList( grpSeqStr ) == 0 )
		grpSeqStr = num2istr( firstGrp ) + "," + num2istr( firstGrp + numGrps - 1 )
		grpSeqStr = RangeToSequenceStr( grpSeqStr )
	endif
	
	SetNMvar( prefixFolder+"NumGrps", numGrps )
	SetNMvar( prefixFolder+"FirstGrp", firstGrp )
	SetNMvar( prefixFolder+"GroupsFromWave", fromWave )
	SetNMvar( prefixFolder+"GroupsToWave", toWave )
	SetNMvar( prefixFolder+"GroupsWaveBlocks", blocks )
	
	SetNMstr( prefixFolder+"GroupsSeqStr", grpSeqStr )

End // NMGroupsPanelDefaults

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )

	NMGroupsPanelFxnCall( fxn, varStr )
	
End // NMGroupsPanelSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )
	
	NMGroupsPanelFxnCall( fxn, "" )
	
End // NMGroupsPanelButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )
	
	NMGroupsPanelFxnCall( fxn, num2istr( checked ) )

End // NMGroupsPanelCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsHook( infoStr )
	String infoStr
	
	String event= StringByKey( "EVENT",infoStr )
	String win= StringByKey( "WINDOW",infoStr )
	
	if ( StringMatch( win, NMGroupsPanelName() ) == 0 )
		return 0
	endif
	
	strswitch( event )
		case "kill":
			KillWaves /Z $NMGroupsWaveName()
	endswitch

End // NMGroupsHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelFxnCall( fxn, select )
	String fxn
	String select
	
	Variable snum = str2num( select )
	
	if ( NMGroupsOK() == 0 )
		return -1
	endif

	strswitch( fxn )
		
		case "NumGroups":
			return NMGroupsPanelSeqUpdate()
			
		case "FirstGroup":
			return NMGroupsPanelSeqUpdate()
	
		case "WaveStart":
		case "WaveEnd":
		case "WaveBlocks":
			return 0
		
		case "SeqStr":
			return NMGroupsPanelSeqSet()
			
		case "Execute":
			return NMGroupsPanelExecute()
			
		case "Clear":
			return NMGroupsPanelClear()
			
		case "Cancel":
			return NMGroupsPanelCancel()
		
		case "SaveClose":
			return NMGroupsPanelSaveClose()
			
		default:
			NMDoAlert( "NMGroupsPanelFxnCall: unrecognized function call: " + fxn )
			return -1
			
	endswitch
	
	return 0
	
End // NMGroupsPanelFxnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelSeqSet()

	Variable gcnt, grpNum, numGrps, firstGrp

	String prefixFolder = CurrentNMPrefixFolder()
	
	String grpSeqStr = StrVarOrDefault( prefixFolder+"GroupsSeqStr", "" )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numGrps = ItemsInList( grpSeqStr )
	
	firstGrp = NMGroupsFirst( grpSeqStr )
	
	if ( numGrps == 0 )
	
		return NMGroupsPanelSeqUpdate()
		
	else
	
		SetNMvar( prefixFolder+"NumGrps", numGrps )
		SetNMvar( prefixFolder+"FirstGrp", firstGrp )
		
	endif
	
	return 0

End // NMGroupsPanelSeqSet()

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelSeqUpdate()

	String grpSeqStr
	String prefixFolder = CurrentNMPrefixFolder()

	Variable numGrps = NumVarOrDefault( prefixFolder+"NumGrps", Nan )
	Variable firstGrp = NumVarOrDefault( prefixFolder+"FirstGrp", 0 )
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( numtype( numGrps * firstGrp ) > 0 ) )
		return -1
	endif
	
	grpSeqStr = num2istr( firstGrp ) + "," + num2istr( firstGrp + numGrps - 1 )
	
	grpSeqStr = RangeToSequenceStr( grpSeqStr )
	
	SetNMstr( prefixFolder+"GroupsSeqStr", grpSeqStr )
	
	return 0

End // NMGroupsPanelSeqUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelExecute()

	String prefixFolder = CurrentNMPrefixFolder()
	String gwName = NMGroupsWaveName()
	
	Variable fromWave = NumVarOrDefault( prefixFolder+"GroupsFromWave", 0 )
	Variable toWave = NumVarOrDefault( prefixFolder+"GroupsToWave", NMNumWaves() - 1 )
	Variable blocks = NumVarOrDefault( prefixFolder+"GroupsWaveBlocks", 1 )
	
	String grpSeqStr = StrVarOrDefault( prefixFolder+"GroupsSeqStr", "" )
	
	if ( ( ItemsInList( grpSeqStr ) > 0 ) && ( WaveExists( $gwName ) == 1 ) )
		WaveSequence( gwName, grpSeqStr, fromWave, toWave, blocks )
	endif

End // NMGroupsPanelExecute

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelClear()

	String gwName = NMGroupsWaveName()
	
	if ( WaveExists( $gwName ) == 1 )
		Wave wtemp = $gwName
		wtemp = Nan
	endif

End // NMGroupsPanelClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelCancel()

	DoWindow /K $NMGroupsPanelName()
	KillWaves /Z $NMGroupsWaveName()

End // NMGroupsPanelCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelSaveClose()

	String gwName = NMGroupsWaveName()

	NMGroupsWaveToLists( gwName )
	
	DoWindow /K $NMGroupsPanelName()
	KillWaves /Z $gwName
	
	UpdateNMGroups()

End // NMGroupsPanelSaveClose

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupFilter( n, grpNum ) // DEPRECATED, not used anymore
	Variable n
	Variable grpNum

	if ( ( grpNum == -1 ) && ( numtype( n ) == 0 ) )
		return 1 // All Groups
	elseif ( n == grpNum )
		return 1
	else
		return 0
	endif
	
End // NMGroupFilter

//****************************************************************
//****************************************************************
//****************************************************************