#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Prefix SubFolder Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//
//	Note, prefix subfolders reside in NM data folders ( see NM_Folders.ipf )
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMNumChannels()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif

	return NumVarOrDefault( prefixFolder+"NumChannels", 0 )

End // NMNumChannels

//****************************************************************
//****************************************************************
//****************************************************************

Function CurrentNMChannel()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return 0 // Nan
	endif

	//if ( NumVarOrDefault( prefixFolder+"NumChannels", 0 ) == 0 )
	//	return Nan
	//endif
	
	return NumVarOrDefault( prefixFolder+"CurrentChan", 0 )

End // CurrentNMChannel

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMChanChar()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	return ChanNum2Char( NumVarOrDefault( prefixFolder+"CurrentChan", 0 ))

End // CurrentNMChanChar

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanNumCheck( chanNum )
	Variable chanNum
	
	if ( ( numtype( chanNum ) > 0 ) || ( chanNum < 0 ) )
		chanNum = CurrentNMChannel()
	endif
	
	//if ( chanNum >= NMNumChannels() )
	//	return Nan
	//endif
	
	return chanNum
	
End // ChanNumCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNumWaves()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif

	return NumVarOrDefault( prefixFolder+"NumWaves", 0 )

End // NMNumWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function CurrentNMWave()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif

	return NumVarOrDefault( prefixFolder+"CurrentWave", 0 )

End // CurrentNMWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMWaveName()

	return NMChanWaveName( -1, -1 )

End // CurrentNMWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function CurrentNMGroup()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return Nan
	endif

	return NMGroupsNum( CurrentNMWave() )

End // CurrentNMGroup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNumActiveWaves()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	return NumVarOrDefault( prefixFolder+"NumActiveWaves", 0 )

End // NMNumActiveWaves

//****************************************************************
//****************************************************************
//****************************************************************
//
//	General Prefix Folder functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMPrefixFolder()

	String folder = NMPrefixFolderDF( CurrentNMFolder( 1 ), CurrentNMWavePrefix() )

	if ( DataFolderExists( folder ) == 1 )
		return folder
	endif
	
	return ""

End // CurrentNMPrefixFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderAlert()

	if ( strlen( CurrentNMPrefixFolder() ) > 0 )
		return 1
	endif
	
	NMDoAlert( "No waves. You may need to select " + NMQuotes( "Wave Prefix" ) + " first." )
	
	return 0

End // NMPrefixFolderOK

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderPrefix()
	
	return "NMprefix_"

End // NMPrefixFolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMPrefixFolderPath( prefixFolder )
	String prefixFolder
	
	String parent

	if ( strlen( prefixFolder ) == 0 )
		prefixFolder = CurrentNMPrefixFolder()
	endif
	
	if ( DataFolderExists( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( strsearch( prefixFolder, NMPrefixFolderPrefix(), 0 ) < 0 )
		return "" // wrong type of folder
	endif
	
	parent = GetPathName( prefixFolder, 1 )
	
	if ( strlen( parent ) == 0 )
		return LastPathColon( GetDataFolder( 1 ) + prefixFolder, 1 )
	endif
	
	return LastPathColon( prefixFolder, 1 )
	
End // CheckNMPrefixFolderPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderDF( parent, wavePrefix )
	String parent, wavePrefix
	
	String folder
	
	parent = CheckNMFolderPath( parent )
	
	if ( DataFolderExists( parent ) == 0 )
		return ""
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = CurrentNMWavePrefix()
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		return ""
	endif
	
	return parent + NMPrefixFolderPrefix() + wavePrefix + ":"

End // NMPrefixFolderDF

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderUtility( parent, select )
	String parent
	String select // "rename" or "check" or "lock" or "unlock"
	
	Variable icnt
	String flist, prefixFolder
	
	parent = CheckNMFolderPath( parent )
	
	if ( DataFolderExists( parent ) == 0 )
		return -1
	endif
	
	flist = FolderObjectList( parent , 4 )
	
	for ( icnt = 0 ; icnt < ItemsInList( flist ) ; icnt += 1 )
	
		prefixFolder = StringFromList( icnt, flist )
	
		strswitch( select )
		
			case "rename":
				NMPrefixFolderRename( prefixFolder )
				break
				
			case "check":
				CheckNMPrefixFolder( LastPathColon(parent+prefixFolder,1), Nan, Nan )
				break
				
			case "lock":
				NMPrefixFolderLock( LastPathColon(parent+prefixFolder,1), 1 )
				break
				
			case "unlock":
				NMPrefixFolderLock( LastPathColon(parent+prefixFolder,1), 0 )
				break
		
		endswitch
		
	endfor
	
	return 0

End // NMPrefixFolderUtility

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderMake( parent, wavePrefix, numChannels, numWaves )
	String parent, wavePrefix
	Variable numChannels, numWaves
	
	String prefixFolder = NMPrefixFolderDF( parent, wavePrefix )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( DataFolderExists( prefixFolder ) == 1 )
		return "" // already exists
	endif
	
	NewDataFolder $RemoveEnding( prefixFolder, ":" )
	
	CheckNMPrefixFolder( prefixFolder, numChannels, numWaves )
	
	return prefixFolder
	
End // NMPrefixFolderMake

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMPrefixFolder( prefixFolder, numChannels, numWaves ) // check prefix subfolder globals
	String prefixFolder
	Variable numChannels, numWaves
	
	String wname, waveSelect
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( numtype( numChannels ) == 0 )
		SetNMvar( prefixFolder + "NumChannels", numChannels )
	endif
	
	if ( numtype( numWaves ) == 0 )
		SetNMvar( prefixFolder + "NumWaves", numWaves )
	endif
	
	CheckNMChanWaveLists()
	
	CheckNMSets()
	CheckNMGroups()
	
	CheckNMChanSelect()
	CheckNMWaveSelect()
	
	NMPrefixFolderLock( prefixFolder, 1 )

End // CheckNMPrefixFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderRename( prefixFolder )
	String prefixFolder
	
	String fname, parent, newname, sprefix = NMPrefixFolderPrefix()
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( ( exists( prefixFolder+"CurrentChan" ) != 2 ) || ( exists( prefixFolder+"CurrentWave" ) != 2 ) )
		return -1 // wrong type of subfolder
	endif
	
	fname = GetPathName( prefixFolder, 0 )
	parent = GetPathName( prefixFolder, 1 )
	
	if ( ( strlen( sprefix ) > 0 ) && ( strsearch( fname, sprefix, 0 ) < 0 ) )
				
		newname = sprefix + fname
		
		if ( DataFolderExists( parent + newname ) == 0 )
			RenameDataFolder $RemoveEnding( prefixFolder, ":" ), $newname
		endif
				
	endif

End // NMPrefixFolderRename

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderLock( prefixFolder, lock )
	String prefixFolder
	Variable lock // ( 0 ) no ( 1 ) yes
	
	String wname
	
	Variable lockFolders = NeuroMaticVar( "LockFolders" )
	
	if ( ( lock == 1 ) && ( lockFolders == 0 ) )
		return -1
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wname = prefixFolder + "Lock"
				
	if ( lock == 1 )
	
		if ( WaveExists( $wname ) == 0 )
			Make /O/N=1 $wname
			Note $wname, "this NM wave is locked to prevent accidental deletion of NM data folders. Control click in the Data Browser to unlock this wave."
			SetWaveLock 1, $wname
		endif
		
	elseif ( WaveExists( $wname ) == 1 )

		SetWaveLock 0, $wname
		
	endif

End // NMPrefixFolderLock

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderVarName( strVarPrefix, chanNum )
	String strVarPrefix // prefix name
	Variable chanNum // channel number
	
	String chanStr = ""
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( chanNum < 0 )
		chanNum = NumVarOrDefault( prefixFolder+"CurrentChan", 0 )
	endif
	
	if ( ( chanNum >= 0 ) && ( chanNum < NMNumChannels() ) )
		chanStr = ChanNum2Char( chanNum )
	endif
	
	return prefixFolder + strVarPrefix + chanStr
	
End // NMPrefixFolderVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderStrVarSearch( strVarPrefix, fullPath )
	String strVarPrefix // prefix name
	Variable fullPath // return StrVarName with full path ( 0 ) no ( 1 ) yes

	String matchStr = strVarPrefix + "*"
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	return NMFolderStringList( prefixFolder, matchStr, ";", fullPath )

End // NMPrefixFolderStrVarSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderWaveSearch( wavePrefix, fullPath )
	String wavePrefix // prefix name
	Variable fullPath // return waveName with full path ( 0 ) no ( 1 ) yes

	String matchStr = wavePrefix + "*"
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	return NMFolderWaveList( prefixFolder, matchStr, ";", "", fullPath )

End // NMPrefixFolderWaveSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderStrVarKill( strVarPrefix )
	String strVarPrefix // prefix name

	Variable icnt, killedsomething
	String strVarName, strVarList
	
	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
		return 0
	endif
	
	strVarList = NMPrefixFolderStrVarSearch( strVarPrefix, 1 )
	
	for ( icnt = 0 ; icnt < ItemsInList( strVarList ) ; icnt += 1 )
	
		strVarName = StringFromList( icnt, strVarList )
		KillStrings /Z $strVarName
	
		if ( exists( strVarName ) == 0 )
			killedsomething = 1
		endif
		
	endfor
	
	return killedsomething

End // NMPrefixFolderStrVarKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderWaveKill( wavePrefix )
	String wavePrefix // prefix name

	Variable icnt, killedsomething
	String wname, wList
	
	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
		return 0
	endif
	
	wList = NMPrefixFolderWaveSearch( wavePrefix, 1 )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wname = StringFromList( icnt, wList )
		KillWaves /Z $wname
	
		if ( WaveExists( $wname ) == 0 )
			killedsomething = 1
		endif
		
	endfor
	
	return killedsomething

End // NMPrefixFolderWaveKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderWaveToLists( inputWaveName, outputStrVarPrefix )
	String inputWaveName
	String outputStrVarPrefix
	
	Variable icnt, ccnt, wcnt, numChannels = NMNumChannels()
	String wList, strVarName, strVarList, chanList, wname
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( WaveExists( $inputWaveName ) == 0 )
		return -1
	endif
	
	strVarList = NMPrefixFolderStrVarSearch( outputStrVarPrefix, 1 )
	
	if ( ItemsInList( strVarList ) > 0 )
	
		DoAlert 1, "Alert: wave lists with prefix " + NMQuotes( outputStrVarPrefix ) + " already exist. Do you want to overwrite them?"
		
		if ( V_flag != 1 )
			return -1 // cancel
		endif
		
		for ( icnt = 0 ; icnt < ItemsInList( strVarList ) ; icnt += 1 )
			KillStrings /Z $StringFromList( icnt, strVarList )
		endfor
	
	endif
	
	Wave input = $inputWaveName
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		strVarName = NMPrefixFolderVarName( outputStrVarPrefix, ccnt )
		
		wList = ""
		chanList = NMChanWaveList( ccnt )
	
		for ( wcnt = 0 ; wcnt < numpnts( input ) ; wcnt += 1 )
			
			if ( input[ wcnt ] == 1 )
				wname = StringFromList( wcnt, chanList )
				wList = AddListItem( wname, wList, ";", inf )
			endif
		
		endfor
		
		SetNMstr( strVarName, wList )
	
	endfor
	
	return 0
	
End // NMPrefixFolderWaveToLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderListsToWave( inputStrVarPrefix, outputWaveName )
	String inputStrVarPrefix
	String outputWaveName

	Variable ccnt, wcnt, wnum
	String wList, strVarName, chanList, wname
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( WaveExists( $outputWaveName ) == 1 )
	
		DoAlert 1, "Alert: wave " + NMQuotes( outputWaveName ) + " already exist. Do you want to overwrite it?"
		
		if ( V_flag != 1 )
			return -1 // cancel
		endif
		
		KillWaves /Z $outputWaveName // try to kill
		
	endif
	
	CheckNMWave( outputWaveName, numWaves, 0 )
	
	if ( WaveExists( $outputWaveName ) == 0 )
		return -1
	endif

	Wave output = $outputWaveName
	
	output = 0

	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		strVarName = NMPrefixFolderVarName( inputStrVarPrefix, ccnt )
		
		wList = StrVarOrDefault( strVarName, "" )
		chanList= NMChanWaveList( ccnt )
	
		for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
			
			wname = StringFromList( wcnt, wList )
			wnum = WhichListItem( wname, chanList )
			
			if ( ( wnum >= 0 ) && ( wnum < numWaves ) )
				output[ wnum ] = 1
			endif
		
		endfor
	
	endfor
	
	return 0

End // NMPrefixFolderListsToWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderStrVarListAdd( waveListToAdd, strVarName, chanNum )
	String waveListToAdd
	String strVarName
	Variable chanNum
	
	String wList, chanList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	chanList = NMChanWaveList( chanNum )
	wList = StrVarOrDefault( strVarName, "" )
	wList = NMAddToList( waveListToAdd, wList, ";" )
	wList = OrderToNMChanWaveList( wList, chanNum )
	
	SetNMstr( strVarName, wList )
	
	return wList
	
End // NMPrefixFolderStrVarListAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderStrVarListRemove( waveListToRemove, strVarName, chanNum )
	String waveListToRemove
	String strVarName
	Variable chanNum
	
	String wList, chanList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( exists( strVarName ) != 2 ) )
		return ""
	endif

	wList = StrVarOrDefault( strVarName, "" )
	wList = RemoveFromList( waveListToRemove, wList, ";" )
	
	SetNMstr( strVarName, wList )
	
	return wList
	
End // NMPrefixFolderStrVarListRemove

//****************************************************************
//****************************************************************
//****************************************************************
//
//	x-wave functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXwave()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	return StrVarOrDefault( prefixFolder+"Xwave", "" )

End // NMXwave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXwaveSetCall()

	Variable ccnt, npnts, numChannels = NMNumChannels()
	String optionsStr, wList = ""
	
	String xwave = NMXwave()
	
	npnts = NMChanXstats( "numpnts" )
	
	optionsStr = NMWaveListOptions( npnts, 0 )
	
	if ( numtype( npnts ) == 0 )
	
		wList = WaveList( "*", ";", optionsStr )
		
		for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
			wList = RemoveFromList( NMChanWaveList( ccnt ), wList, ";" )
		endfor
		
	endif
	
	wList = "No Xwave;---;" + wList
	
	Prompt xwave, "choose a wave that contains the x-values for the currently selected waves:", popup wList
	DoPrompt NMPromptStr( "Set Xwave" ), xwave
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	NMCmdHistory( "NMXwaveSet", NMCmdStr( xwave, "" ) )
	
	return NMXwaveSet( xwave )
	
End // NMXwaveSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXwaveSet( xwname )
	String xwname
	
	Variable ccnt, npnts
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( StringMatch( xwname, "No Xwave" ) == 1 )
	
		xwname = ""
		
	elseif ( WaveExists( $xwname ) == 0 )
	
		NMDoAlert( "Abort NMXwaveSet: " + xwname + " does not exist." )
		return ""
		
	else
	
		for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 )
		
			npnts = GetXstats( "numpnts", NMChanWaveList( ccnt ) )
		
			if ( numtype( npnts ) > 0 )
				NMDoAlert( "Abort NMXwaveSet: for this function to work, your waves must have the same dimension." )
				return ""
			endif
		
		endfor
	
	endif
	
	SetNMstr(prefixFolder+"Xwave", xwname)
	
	ChanGraphsReset()
	ChanGraphsUpdate()
	
	return xwname
	
End // NMXwaveSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMLeftX(ywave)
	String ywave
	
	String xwave = NMXwave()
	
	if (strlen(ywave) == 0)
		ywave = CurrentNMWaveName()
	endif
	
	if (WaveExists($ywave) == 0)
		return Nan
	endif
	
	if ( (WaveExists($xwave) == 1) && ( numpnts( $ywave ) == numpnts( $xwave ) ) )
	
		WaveStats /Q $xwave
		
		return V_min
		
	endif
	
	return leftx($ywave)
	
End // NMLeftX

//****************************************************************
//****************************************************************
//****************************************************************

Function NMRightX(ywave)
	String ywave
	
	String xwave = NMXwave()
	
	if (strlen(ywave) == 0)
		ywave = CurrentNMWaveName()
	endif
	
	if (WaveExists($ywave) == 0)
		return Nan
	endif
	
	if ( (WaveExists($xwave) == 1) && ( numpnts( $ywave ) == numpnts( $xwave ) ) )
	
		WaveStats /Q $xwave
		
		return V_max
	
	endif
	
	return rightx($ywave)
	
End // NMRightX

//****************************************************************
//****************************************************************
//****************************************************************

Function NMXvalueTransform(ywave, xvalue, direction, lessORgreater)
	String ywave
	Variable xvalue
	Variable direction
	Variable lessORgreater // ( -1 ) less than ( 1 ) greater than
	
	Variable npnts, dx, xv, icnt
	
	String xwave = NMXwave()
	
	if (strlen(ywave) == 0)
		ywave = CurrentNMWaveName()
	endif
	
	if ((numtype(xvalue) > 0) || (WaveExists($ywave) == 0) || (WaveExists($xwave) == 0))
		return xvalue
	endif
	
	npnts = numpnts($ywave)
	
	Make /O/N=(npnts) NM_xWaveTemp
	
	WaveStats /Q $xwave
	
	dx = (V_max - V_min) / (npnts - 1)
	
	Setscale /P x V_min, dx, NM_xWaveTemp
	
	Wave xtemp = $xwave
	
	if (direction == 1)
	
		xv = x2pnt($ywave, xvalue)
		xv = xtemp[xv]
		
	else
	
		FindLevel /P/Q xtemp, xvalue
		
	 	xv = pnt2x($ywave, V_LevelX)
	 	
	 	if ((xv >= 0) && (xv < numpnts(xtemp)))
	 		
	 		switch(lessORgreater)
	 		
	 			case -1: // less than
	 			
	 				for (icnt = xv + 1; icnt < xv - 5; icnt -= 1)
	 					if ((icnt >= 0) && (icnt < numpnts(xtemp)) && (xtemp[icnt] <= xvalue))
	 						xv = icnt
	 						break
	 					endif
	 				endfor
	 				
	 				break
	 				
	 			case 1: // greater than
	 			
	 				for (icnt = xv - 1; icnt < xv + 5; icnt += 1)
	 					if ((icnt >= 0) && (icnt < numpnts(xtemp)) && (xtemp[icnt] >= xvalue))
	 						xv = icnt
	 						break
	 					endif
	 				endfor
	 				
	 				break
	 		
	 		endswitch
	 		
	 	endif
	 	
	endif
	
	KillWaves /Z NM_xWaveTemp
	 
	 return xv
	
End // NMXvalueTransform

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave Number Select Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentWaveSetCall(waveNum)
	Variable waveNum
	
	NMCmdHistory("NMCurrentWaveSet", NMCmdNum(waveNum,""))
	
	return NMCurrentWaveSet(waveNum)
	
End // NMCurrentWaveSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentWaveSet(waveNum)
	Variable waveNum
	
	waveNum = NMCurrentWaveSetNoUpdate( waveNum )
	
	UpdateCurrentWave()
	
	return waveNum
	
End // NMCurrentWaveSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentWaveSetNoUpdate( waveNum )
	Variable waveNum
	
	Variable grpNum, nwaves = NMNumWaves()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder) == 0 )
		return Nan
	endif
	
	if ( waveNum < 0 )
		waveNum = 0
	elseif (waveNum >= nwaves)
		waveNum = nwaves - 1
	endif
	
	if ( numtype( waveNum ) > 0 )
		waveNum = NumVarOrDefault( prefixFolder+"CurrentWave", 0 )
	endif
	
	grpNum = NMGroupsNum( waveNum )
	
	SetNMvar( prefixFolder+"CurrentWave", waveNum )
	SetNMvar( prefixFolder+"CurrentGrp", grpNum )
	SetNeuroMaticVar( "CurrentWave", waveNum )
	SetNeuroMaticVar( "CurrentGrp", grpNum )
	
	return waveNum
	
End // NMCurrentWaveSetNoUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateCurrentWave()

	//NMGroupUpdate()
	UpdateNMPanelSets( 0 )
	ChanGraphsUpdate()
	//NMWaveSelect( "update" )
	NMAutoTabCall()
	
End // UpdateCurrentWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNextWaveCall(direction)
	Variable direction
	
	NMCmdHistory("NMNextWave", NMCmdNum(direction,""))
	
	return NMNextWave(direction)
	
End // NMNextWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNextWave(direction) // set next wave number
	Variable direction
	
	Variable icnt, grpNum, next, found = -1
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	Variable numWaves = NMNumWaves()
	
	Variable wskip = NeuroMaticVar( "WaveSkip" )
	
	if ( numWaves == 0 )
		NMDoAlert("No waves to display.")
		return -1
	endif
	
	if ( wskip < 0 )
		wskip = 1
		SetNeuroMaticVar( "WaveSkip", wskip)
	endif

	if ( wskip > 0 )
	
		next = currentWave + direction*wskip
		
		if ((next >= 0) && (next < numWaves))
			found = next
		endif
		
	elseif ( wskip == 0 ) // As Wave Select
	
		if ( direction < 0 )
		
			for ( icnt = currentWave - 1 ; icnt >= 0 ; icnt -= 1 )
				
				if ( NMWaveIsSelected( currentChan, icnt ) == 1 )
					found = icnt
					break
				endif
			
			endfor
			
		else
		
			for ( icnt = currentWave + 1 ; icnt < numWaves ; icnt += 1 )
				
				if ( NMWaveIsSelected( currentChan, icnt ) == 1 )
					found = icnt
					break
				endif
			
			endfor
		
		endif
		
	endif

	if ((found >= 0) && (found != currentWave))
	
		found = NMCurrentWaveSetNoUpdate( found )
		
		if ( numtype( found ) == 0 )
			UpdateCurrentWave()
		endif
		
	endif
	
	return found

End // NMNextWave

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanList( type )
	String type // "NUM" or "CHAR"
	
	String chanList = ""
	Variable ccnt
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 )
	
		strswitch( type )
			case "NUM":
				chanList = AddListItem( num2istr( ccnt ) , chanList, ";", inf )
				break
			case "CHAR":
				chanList = AddListItem( ChanNum2Char( ccnt ) , chanList, ";", inf )
				break
			default:
				return ""
		endswitch
		
	endfor
	
	return chanlist // returns chan list ( e.g. "0;1;2;" or "A;B;C;" )

End // NMChanList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanLabel( chanNum, xy, wList )
	Variable chanNum // ( -1 ) for current chan
	String xy // "x" or "y"
	String wList // ( "" ) for current chan wave list
	
	String xyLabel, defaultStr = ""
	
	String currentFolder = CurrentNMFolder( 1 )
	String prefixFolder = CurrentNMPrefixFolder()
	String yname = currentFolder + "yLabel"
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( chanNum == -1 )
		chanNum = NumVarOrDefault( prefixFolder+"CurrentChan", 0 )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		wList = NMChanWaveList( chanNum )
	endif
	
	strswitch( xy )
	
		case "x":
			defaultStr = StrVarOrDefault( "xLabel", "" )
			defaultStr = StrVarOrDefault( prefixFolder+"xLabel", defaultStr )
			break
			
		case "y":
		
			if ( ( WaveExists( $yname ) == 1 ) && ( chanNum >= 0 ) && ( chanNum < numpnts( $yname ) ) )
			
				Wave /T ytemp = $yname
				
				defaultStr = ytemp[ chanNum ]
				
			endif
			
			break
			
	endswitch
	
	xyLabel = NMNoteLabel( xy, wList, defaultStr )
	
	if ( strlen( xyLabel ) > 0 )
		return xyLabel
	endif

	return GetWaveUnits( xy, wList, defaultStr )
	
End // NMChanLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanLabelSet( chanNum, wSelect, xy, labelStr )
	Variable chanNum // ( -1 ) for current selected chan
	Variable wSelect // ( 1 ) selected waves ( 2 ) all chan waves
	String xy // "x" or "y"
	String labelStr
	
	Variable wcnt
	String wname, wList, thisfxn = "NMChanLabelSet"
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable numChannels = NMNumChannels()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	if ( chanNum == -1 )
		chanNum = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	if ( numtype( chanNum ) > 0 )
		return NMError( 10, thisfxn, "chanNum", num2istr( chanNum ) )
	endif
	
	switch( wSelect )
	
		case 1:
			wList = NMWaveSelectList( chanNum )
			break
			
		case 2:
			wList = NMChanWaveList( chanNum )
			break
			
		default:
			return NMError( 10, thisfxn, "wSelect", num2istr( wSelect ) )
			
	endswitch
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wname = StringFromList( wcnt, wList )
		
		strswitch( xy )
		
			case "x":
			case "y":
				NMNoteStrReplace( wname, xy+"Label", labelStr )
				RemoveWaveUnits( wname )
				break
				
			default:
				return NMError( 20, thisfxn, "xy", xy )
		
		endswitch
	
	endfor
	
	ChanGraphsUpdate()
	
	return 0

End // NMChanLabelSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanUnits2Labels()

	Variable ccnt
	String wname, s, x, y
	
	Variable numWaves = NMNumWaves()
	Variable numChannels = NMNumChannels()
	
	if ( numWaves <= 0 )
		return 0
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
		
		wname = NMChanWaveName( ccnt, 0 )
		
		s = WaveInfo( $wname, 0 )
		x = StringByKey( "XUNITS", s )
		y = StringByKey( "DUNITS", s )
		
		if ( strlen( x ) > 0 )
			NMChanLabelSet( ccnt, 2, "x", x )
		endif
		
		if ( strlen( y ) > 0 )
			NMChanLabelSet( ccnt, 2, "y", y )
		endif

	endfor

End // NMChanUnits2Labels

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Select Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMChanSelect()

	Variable ccnt
	String waveSelect, chanList = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	String wname = prefixFolder + "ChanSelect"
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	if ( WaveExists( $wname ) == 1 )
		
		Wave wtemp = $wname

		for ( ccnt = 0 ; ccnt < numpnts( wtemp ) ; ccnt += 1 )
		
			if ( wtemp[ ccnt ] == 1 )
				chanList = AddListItem( num2istr( ccnt ), chanList, ";", inf )
			endif
		
		endfor
		
		KillWaves /Z $wname
		
	endif
	
	if ( ItemsInList( chanList ) == 0 )
	
		chanList = NMChanSelectList()
		
		if ( ItemsInList( chanList ) == 0 )
			chanList = "0;"
		else
			return 0
		endif
	
	endif
	
	SetNMstr( prefixFolder+NMChanSelectStrVarName(), chanList )

End // CheckNMChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanSelectStrVarName()

	return "ChanSelect_List"

End // NMChanSelectStrVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanSelectList()

	return StrVarOrDefault( CurrentNMPrefixFolder()+NMChanSelectStrVarName(), "" )
	
End // NMChanSelectList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanSelectCharList()

	Variable ccnt, chanNum
	String chan, charList = ""

	String chanList = StrVarOrDefault( CurrentNMPrefixFolder()+NMChanSelectStrVarName(), "" )
	
	for ( ccnt = 0 ; ccnt < ItemsInList( chanList ) ; ccnt += 1 )
		chanNum = str2num ( StringFromList( ccnt, chanList ) )
		charList = AddListItem( ChanNum2Char( chanNum ) , charList, ";", inf )
	endfor
	
	return charList
	
End // NMChanSelectCharList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelectCall( chanStr )
	String chanStr
	
	NMCmdHistory( "NMChanSelect", NMCmdStr( chanStr, "" ) )
	NMChanSelect( chanStr )
	
End // NMChanSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelect( chanStr ) // set current channel
	String chanStr // "A" or "B" or "C" or "All" or "0" or "1" or "2" or ( "" ) for current channel
	
	Variable chanNum
	String chanList = ""
	
	String chanCharList = NMChanList( "CHAR" )
	String chanNumList = NMChanList( "NUM" )
	
	chanStr = StringFromList( 0, chanStr )
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	if ( StringMatch( chanStr, "All" ) == 1 )
	
		chanList = chanNumList
		
	elseif ( strlen( chanStr ) == 0 )
	
		chanList = AddListItem( num2istr( CurrentNMChannel() ), "", ";", inf )
		
	elseif ( WhichListItem( chanStr, chanCharList ) >= 0 )
	
		chanNum = ChanChar2Num( chanStr )
		chanList = AddListItem( num2istr( chanNum ), "", ";", inf )
	
	elseif ( WhichListItem( chanStr, chanNumList ) >= 0 )
	
		chanList = AddListItem( chanStr, "", ";", inf )
		
	else
	
		NMDoAlert( "NMChanSelect Error: channel is out of range: " + chanStr )
		return Nan
		
	endif
	
	if ( ItemsInList( chanList ) == 0 )
		return Nan
	endif
	
	return NMChanSelectListSet( chanList )

End // NMChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelectListSet( chanList )
	String chanList // e.g. "0" or "0;1;2" or "0;2"
	
	Variable ccnt, chanNum
	String chanStr
	
	String TabList = NMTabControlList()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable currentTab = NeuroMaticVar( "CurrentTab" )
	Variable saveCurrentChan = CurrentNMChannel()
	Variable numChannels = NMNumChannels()
	
	String chanNumList = NMChanList( "NUM" )
	
	if ( ( NMPrefixFolderAlert() == 0 ) || ( numChannels == 0 ) || ( ItemsInList( chanList ) <= 0 ) )
		return Nan
	endif
	
	for ( ccnt = 0 ; ccnt < ItemsInList( chanList ) ; ccnt += 1 )
	
		chanStr = StringFromList( ccnt, chanList )
	
		if ( WhichListItem( chanStr , chanNumList ) < 0 )
			NMDoAlert( "Abort NMChanSelectListSet: channel is out of range: " + chanStr )
			return Nan
		endif
		
	endfor
	
	chanNum = str2num( StringFromList( 0, chanList ) )
	
	SetNMvar( prefixFolder+"CurrentChan", chanNum )
	SetNMstr( prefixFolder+NMChanSelectStrVarName(), chanList )
	
	UpdateNMWaveSelectLists()
	//UpdateNMPanelChannelSelect()
	
	UpdateNMPanel(1 )
	
	return chanNum

End // NMChanSelectListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelectListEdit()

	Variable ccnt, chanNum
	
	String chanNumList = ""
	String chanCharList = NMChanSelectCharList()
	
	Prompt chanCharList, " "
	DoPrompt "Edit Channel Select List", chanCharList
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	for ( ccnt = 0 ; ccnt < ItemsInList( chanCharList ) ; ccnt += 1 )
		chanNum = ChanChar2Num( StringFromList( ccnt, chanCharList ) )
		chanNumList = AddListItem( num2istr( chanNum ) , chanNumList, ";", inf )
	endfor
	
	if ( ItemsInList( chanNumList ) == 0 )
		return -1
	endif
	
	return NMChanSelectListSet( chanNumList )

End // NMChanSelectListEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelected( chanNum )
	Variable chanNum
	
	String prefixFolder = CurrentNMPrefixFolder()
	String chanList = NMChanSelectList()
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( numtype( chanNum ) > 0 ) )
		return 0
	endif
	
	if ( ItemsInList( chanList ) <= 0 )
		return 0
	endif
	
	if ( WhichListItem( num2istr( chanNum ) , chanList ) >= 0 )
		return 1
	endif
	
	return 0
	
End // NMChanSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelectedAll()

	Variable ccnt

	String prefixFolder = CurrentNMPrefixFolder()
	String chanList = NMChanSelectList()
	
	Variable numChannels = NMNumChannels()
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		if ( WhichListItem( num2istr( ccnt ) , chanList ) < 0 )
			return 0
		endif
		
	endfor
	
	return 1

End // NMChanSelectedAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanSelectStr()
	
	if ( ( NMNumChannels() > 1 ) && ( NMChanSelectedAll() == 1 ) )
		return "All"
	endif
	
	return CurrentNMChanChar()

End // NMChanSelectStr

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave Select Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMWaveSelect()

	String waveSelect = ""
	String prefixFolder = CurrentNMPrefixFolder()
	String wname = prefixFolder + "WavSelect"
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	if ( WaveExists( $wname ) == 1 )
	
		waveSelect = note( $wname )
		
		KillWaves /Z $wname
		
	endif
	
	if ( strlen( waveSelect ) == 0 )
	
		waveSelect = StrVarOrDefault( prefixFolder+"WaveSelect", "" )
		
		if ( strlen( waveSelect ) == 0 )
			waveSelect = "All"
		else
			return 0
		endif
		
	endif
	
	SetNMstr( prefixFolder+"WaveSelect", waveSelect )
	
	UpdateNMWaveSelectLists()
	
End // CheckNMWaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectGet()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	return StrVarOrDefault( prefixFolder+"WaveSelect", "" )

End // NMWaveSelectGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectStrVarPrefix()
	String setName
	
	return "WaveSelect_List"
	
End // NMWaveSelectStrVarPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectStrVarName( chanNum )
	Variable chanNum

	return NMPrefixFolderVarName( NMWaveSelectStrVarPrefix(), chanNum )

End // NMWaveSelectStrVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectCall( waveSelect )
	String waveSelect // wave select function (i.e. "All" or "Set1" or "Group1")
	
	Variable grpNum, error, andor, history = 1
	String wavname, wavList, grp, grpList
	
	strswitch( waveSelect )
	
		case "Clear List":
			NMCmdHistory("NMWaveSelectClear", "")
			NMWaveSelectClear()
			return 0
			
		case "Set x Group":
		
			grpList = NMGroupsList(1)
			grp = StringFromList( 0, grpList )
			
			if ( ItemsInList( grpList ) == 0 )
				error = 1
				break
			endif
	
			wavname = StringFromList(0, NMSetsList())
			
			Prompt wavname, " ", popup NMSetsList()
			Prompt andor, " ", popup "AND;OR"
			Prompt grp, " ", popup "All Groups;" + grpList
			DoPrompt "Select Wave Group", wavname, andor, grp
	
			if (V_flag == 1)
				error = 1
				break
			endif
			
			waveSelect = wavname
			
			if (andor == 1)
				waveSelect += " x "
			else
				waveSelect += " + "
			endif
			
			waveSelect += grp
			
			break
		
	endswitch
	
	if (error == 1) // set to "All"
		waveSelect = "All"
	endif
	
	if (history == 1)
		NMCmdHistory("NMWaveSelect", NMCmdStr(waveSelect,""))
	endif
	
	return NMWaveSelect( waveSelect )

End // NMWaveSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectAdd( waveSelect )
	String waveSelect
	
	String prefixFolder = CurrentNMPrefixFolder()
	String addedList = NeuroMaticStr( "WaveSelectAdded" )
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	addedList = NMAddToList( waveSelect, addedList, ";" )
	
	SetNeuroMaticStr( "WaveSelectAdded", addedList )
	
End // NMWaveSelectAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectClear()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
		SetNeuroMaticStr( "WaveSelectAdded", "" )
	endif
	
	UpdateNMPanelWaveSelect()

End // NMWaveSelectClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelect( waveSelect )
	String waveSelect // wave select function (e.g. "All" or "Set1" or "Group1")
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	String saveWaveSelect = StrVarOrDefault( prefixFolder+"WaveSelect", "All" )
	
	if ( ( strlen( waveSelect ) == 0 ) || ( StringMatch( waveSelect, "Update" ) ==  1 ) )
		waveSelect = StrVarOrDefault( prefixFolder+"WaveSelect", "" )
	else
		SetNMstr( prefixFolder+"WaveSelect", waveSelect )
	endif
	
	if ( UpdateNMWaveSelectLists() == 0 )
		SetNMstr( prefixFolder+"WaveSelect", saveWaveSelect ) // something went wrong
		NMDoAlert( "Abort NMWaveSelect: bad wave selection: " + waveSelect )
	endif
	
	UpdateNMPanel(1 )
	//UpdateNMPanelWaveSelect()
	//NMAutoTabCall()
	
	return 0

End // NMWaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMWaveSelectLists()

	Variable ccnt, icnt, OK
	Variable grpNum = Nan, and = -1, or = -1
	String strVarName, strVarList, wList, swList, gwList
	String chanList, setName, grpList
	
	Variable numChannels = NMNumChannels()
	Variable currentWave = CurrentNMWave()
	Variable grpsOn = NMGroupsAreOn()
	Variable setXclude = NMSetXType()

	String prefixFolder = CurrentNMPrefixFolder()
	
	String setList = NMSetsList()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif

	String waveSelect = StrVarOrDefault( prefixFolder+"WaveSelect", "NONE" )
	
	waveSelect = ReplaceString( " & ", waveSelect, " x " )
	waveSelect = ReplaceString( " && ", waveSelect, " x " )
	waveSelect = ReplaceString( " | ", waveSelect, " + " )
	waveSelect = ReplaceString( " || ", waveSelect, " + " )
	
	and = strsearch( waveSelect, " x ", 0 )
	or = strsearch( waveSelect, " + ", 0 )
	
	if ( grpsOn == 1 )
		grpNum = NMGroupsNumFromStr( waveSelect )
	endif
	
	NMPrefixFolderStrVarKill( NMWaveSelectStrVarPrefix() )
	
	if ( StringMatch( waveSelect, "This Wave" ) == 1 )
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue
			endif
			
			wList = NMChanWaveName( ccnt, currentWave ) + ";"
			wList = NMSetXcludeWaveList( wList, ccnt )
			SetNMstr( NMWaveSelectStrVarName( ccnt ), wList )

		endfor
		
		OK = 1
	
	elseif ( StringMatch( waveSelect, "All" ) == 1 )
		
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue
			endif
			
			wList = NMChanWaveList( ccnt )
			wList = NMSetXcludeWaveList( wList, ccnt )
			SetNMstr( NMWaveSelectStrVarName( ccnt ), wList )
			
		endfor
		
		OK = 1
		
	elseif ( WhichListItem( waveSelect, setList ) >= 0 )
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
			
			if ( NMChanSelected( ccnt ) != 1 )
				continue
			endif
			
			swList = NMSetsWaveList( waveSelect, ccnt )
			
			if ( StringMatch( waveSelect, "SetX" ) == 0 )
				swList = NMSetXcludeWaveList( swList, ccnt )
			endif
			
			SetNMstr( NMWaveSelectStrVarName( ccnt ), swList )
			
		endfor
		
		OK = 1
	
	elseif ( StringMatch( waveSelect, "All Sets") == 1 )
		
		if ( setXclude == 1 )
			setList = RemoveFromList( "SetX", setList )
		endif
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue
			endif
		
			swList = ""
		
			for ( icnt = 0 ; icnt < ItemsInList( setList ) ; icnt += 1 )
				setName = StringFromList( icnt, setList )
				swList = NMAddToList( NMSetsWaveList( setName, ccnt ) , swList, ";" )
			endfor
			
			swList = NMSetXcludeWaveList( swList, ccnt )
			swList = OrderToNMChanWaveList( swList, ccnt )
			SetNMstr( NMWaveSelectStrVarName( ccnt ), swList )
			
		endfor
		
		OK = 1
		
	elseif ( ( grpsOn == 0 ) && ( StringMatch( waveSelect, "*Group*" ) == 1 ) )
	
		// error, nothing to do
		
	elseif ( ( grpsOn == 1 ) && ( StringMatch( waveSelect[0,4], "Group" ) == 1 ) )
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue
			endif
			
			gwList = NMGroupsWaveList( grpNum, ccnt )
			gwList = NMSetXcludeWaveList( gwList, ccnt )
			SetNMstr( NMWaveSelectStrVarName( ccnt ), gwList )
			
		endfor
		
		OK = 1
		
	elseif ( ( grpsOn == 1 ) && ( StringMatch( waveSelect, "All Groups" ) == 1 ) )
	
		grpList = NMGroupsList( 0 )
		
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue
			endif
		
			gwList = ""
		
			for ( icnt = 0 ; icnt < ItemsInList( grpList ) ; icnt += 1 )
			
				grpNum = str2num( StringFromList( icnt, grpList ) )
				
				if ( numtype( grpNum ) > 0 )
					continue
				endif
				
				gwList = NMAddToList( NMGroupsWaveList( grpNum, ccnt ), gwList, ";" )
				
			endfor
			
			gwList = NMSetXcludeWaveList( gwList, ccnt )
			gwList = OrderToNMChanWaveList( gwList, ccnt ) 
			SetNMstr( NMWaveSelectStrVarName( ccnt ), gwList )
			
		endfor
		
		OK = 1
		
	elseif ( ( grpsOn == 1 ) && ( ( and > 0 ) || ( or > 0 ) ) ) // Set && Group, Set || Group
	
		setName = waveSelect[0, and-1]
		setName = ReplaceString( " ", setName, "" )
	
		if ( numtype( grpNum ) == 0 )
		
			grpList = num2istr( grpNum )
			
		elseif ( strsearch( waveSelect, "All Groups", 0 ) > 0 )
		
			grpList = NMGroupsList( 0 )
			
		endif
		
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue
			endif
			
			wList = ""
			swList = NMSetsWaveList( setName, ccnt )
		
			for ( icnt = 0 ; icnt < ItemsInList( grpList ) ; icnt += 1 )
			
				grpNum = str2num( StringFromList( icnt, grpList ) )
				
				if ( numtype( grpNum ) > 0 )
					continue
				endif
				
				gwList = NMGroupsWaveList( grpNum, ccnt )
				
				if ( and > 0 )
					gwList = NMAndLists( swList, gwList, ";" )
				elseif ( or > 0 )
					gwList = NMAddToList( swList, gwList, ";" )
				endif
				
				wList = NMAddToList( gwList, wList, ";" )
				
			endfor
			
			wList = NMSetXcludeWaveList( wList, ccnt )
			wList = OrderToNMChanWaveList( wList, ccnt ) 
			SetNMstr( NMWaveSelectStrVarName( ccnt ), wList )
			
		endfor
		
		NMWaveSelectAdd( waveSelect )
		
		OK = 1
		
	endif
	
	if ( OK == 1 )
		UpdateNMWaveSelectCount()
	endif
	
	return OK
	
End // UpdateNMWaveSelectLists

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMWaveSelectCount()

	Variable ccnt, count
	String wList
	
	Variable numChannels = NMNumChannels()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	for ( ccnt = 0 ;  ccnt < numChannels ;  ccnt += 1 )

		if ( NMChanSelected( ccnt ) == 1 )
			wList = StrVarOrDefault( NMWaveSelectStrVarName( ccnt ), "" )
			count += ItemsInList( wList )
		endif
		
	endfor
	
	SetNeuroMaticVar( "NumActiveWaves",  count ) // for NM Panel
	SetNMvar( prefixFolder+"NumActiveWaves",  count )
	
	return count

End // UpdateNMWaveSelectCount

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectList( chanNum ) // returns a list of all currently selected waves in a channel
	Variable chanNum // channel number ( -1 ) for currently selected channel
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( chanNum < 0 )
		chanNum = NumVarOrDefault( prefixFolder+"CurrentChan", 0 )
	endif
	
	return StrVarOrDefault( NMWaveSelectStrVarName( chanNum ) , "" )

End // NMWaveSelectList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectCount( chanNum ) // count number of currently active waves in a channel
	Variable chanNum // channel number

	return ItemsInList( NMWaveSelectList( chanNum ) )

End // NMWaveSelectCount

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelected( chanNum, waveNum ) // return wave name if it is currently selected
	Variable chanNum // channel number or ( -1 ) for current
	Variable waveNum // wave number or ( -1 ) for current
	
	String wname, wList
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
		return ""
	endif
	
	if ( chanNum < 0 )
		chanNum = currentChan
	endif
	
	if ( waveNum < 0 )
		waveNum = currentWave
	endif
	
	if ( NMChanSelected( chanNum ) != 1 )
		return ""
	endif
	
	wname = NMChanWaveName( chanNum, waveNum )
	
	if ( StringMatch( NMWaveSelectGet(), "This Wave" ) == 1 )
	
		if ( ( chanNum == currentChan ) && ( waveNum == currentWave ) )
			return wname
		else
			return ""
		endif
	
	endif
	
	wList = NMWaveSelectList( chanNum )
	
	if ( ( WaveExists( $wname ) == 0 ) || ( WaveType( $wname ) == 0 ) )
		return ""
	endif
	
	if ( WhichListItem( wname, wList ) >= 0 )
		return wname
	endif
	
	return ""
	
End // NMWaveSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveIsSelected( chanNum, waveNum )
	Variable chanNum
	Variable waveNum
	
	if ( strlen( NMWaveSelected( chanNum, waveNum ) ) > 0 )
		return 1
	endif
	
	return 0
	
End // NMWaveIsSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectAllList() // return a list of sets or groups if  "All Sets" or "All Groups" is selected

	String item, set, grpList, iList = ""
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	String waveselect = NMWaveSelectGet()
	
	Variable icnt =  strsearch( waveselect, "All Groups", 0 )

	if ( StringMatch( waveselect, "All Sets" ) == 1 )
	
		return NMSetsListXclude()
		
	elseif ( StringMatch( waveselect, "All Groups" ) == 1 )
	
		return NMGroupsList( 1 )
		
	elseif ( icnt > 0 ) // "Set x All Groups"
	
		set = waveselect[0, icnt-1]
	
		grpList = NMGroupsList( 1 )
		
		for ( icnt = 0; icnt < ItemsInList( grpList ); icnt += 1 )
			item = set + StringFromList( icnt, grpList )
			iList = AddListItem( item, iList, ";", inf )
		endfor
		
		return iList
		
	endif
	
	return ""

End // NMWaveSelectAllList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAllSetsIsSelected() // determine if "All Sets" is selected

	if ( StringMatch( NMWaveSelectGet(), "All Sets" ) == 1 )
		return 1 // yes
	else
		return 0 // no
	endif

End // NMAllSetsIsSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAllGroupsIsSelected() // determine if "All Groups" is selected

	if ( StringMatch( NMWaveSelectGet(), "All Groups" ) == 1 )
		return 1 // yes
	else
		return 0 // no
	endif

End // NMAllGroupsIsSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectShort()

	String wselect= NMWaveSelectGet()
	
	wselect = ReplaceString("This Wave", wselect, num2istr( CurrentNMWave() ) )
	
	wselect = ReplaceString(" && ", wselect,"")
	wselect = ReplaceString(" & ", wselect,"")
	wselect = ReplaceString(" x ", wselect,"")
	wselect = ReplaceString(" || ", wselect,"")
	wselect = ReplaceString(" | ", wselect,"")
	wselect = ReplaceString(" + ", wselect,"")
	wselect = ReplaceString("_", wselect,"")
	wselect = ReplaceString(" ", wselect,"")
	wselect = ReplaceString(".", wselect,"")
	wselect = ReplaceString(",", wselect,"")
	
	return wselect
	
End // NMWaveSelectShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNameStrShort( nameStr )
	String nameStr
	
	nameStr = ReplaceString("Data", nameStr, "D")
	nameStr = ReplaceString("Record", nameStr, "R")
	nameStr = ReplaceString("Sweep", nameStr, "S")
	nameStr = ReplaceString("Wave", nameStr, "W")
	nameStr = ReplaceString("EV_Evnt", nameStr, "EV")
	nameStr = ReplaceString("Stats", nameStr, "ST")
	nameStr = ReplaceString("Spike", nameStr, "SP")
	nameStr = ReplaceString("Event", nameStr, "EV")
	
	nameStr = ReplaceString("Groups", nameStr,"G")
	nameStr = ReplaceString("Group", nameStr,"G")
	nameStr = ReplaceString("Sets", nameStr, "S")
	nameStr = ReplaceString("Set", nameStr, "S")
	
	nameStr = ReplaceString("_", nameStr,"")
	nameStr = ReplaceString(" ", nameStr,"")
	nameStr = ReplaceString(".", nameStr,"")
	nameStr = ReplaceString(",", nameStr,"")
	
	return nameStr
	
End // NMNameStrShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectStr()

	String prefixFolder = CurrentNMPrefixFolder()
	String wselect = CurrentNMWavePrefix() + NMWaveSelectShort()

	Variable currentWave = CurrentNMWave()
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( strlen( wselect ) == 0 ) )
		return ""
	endif
	
	wselect = NMNameStrShort( wselect )
	
	return wselect[0,11]
	
End // NMWaveSelectStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectXstats( select, chanNum )
	String select // see GetXstats
	Variable chanNum // channel number or ( -1 ) for all currently selected channels

	Variable ccnt, cbgn, cend
	String wList = ""
	
	Variable numChannels = NMNumChannels()
	
	if ( NMPrefixFolderAlert() == 0 )
		return Nan
	endif
	
	if ( chanNum < 0 )
	
		cbgn = 0
		cend = numChannels - 1
	
	elseif ( chanNum >= numChannels )
	
		return Nan
		
	else
	
		cbgn = chanNum
		cend = chanNum
	
	endif

	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		if ( NMChanSelected( ccnt ) == 1 )
			wList = NMAddToList( NMWaveSelectList( ccnt ), wList, ";" )
		endif
		
	endfor

	return GetXstats( select, wList )
	
End // NMWaveSelectXstats

//****************************************************************
//****************************************************************
//****************************************************************

Function CreateOldNMWavSelect( dataFolder )
	String dataFolder // where to create WavSelect ( "" for current folder )
	
	String wname
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif

	if ( strlen( dataFolder ) == 0 )
		dataFolder = CurrentNMFolder( 1 )
	endif
	
	wname = dataFolder+"WavSelect"
	
	if ( WaveExists( $wname ) == 1 )
		KillWaves /Z $wname // try to kill first
	endif
	
	NMPrefixFolderListsToWave( NMWaveSelectStrVarPrefix(), wname )

End // CreateOldNMWavSelect

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Wave List Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMChanWaveLists()

	Variable ccnt
	String strVarName
	
	String prefixFolder = CurrentNMPrefixFolder()
	String wname = prefixFolder+"ChanWaveList" // OLD WAVE
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( WaveExists( $wname ) == 0 ) )
		return 0
	endif

	Wave /T wtemp = $wname
	
	for ( ccnt = 0 ; ccnt < numpnts( wtemp ) ; ccnt += 1 )
		strVarName = NMChanWaveListStrVarName( ccnt )
		SetNMstr( strVarName, wtemp[ ccnt ] )
	endfor
	
	KillWaves /Z $wname
	
	NMPrefixFolderWaveKill( "wNames_" ) // kill old waves
	
	NMChanWaveList2Waves()

End // CheckNMChanWaveLists

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListStrVarPrefix()
	String setName
	
	return "Chan_WaveList"
	
End // NMChanWaveListStrVarPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListStrVarName( chanNum )
	Variable chanNum

	return NMPrefixFolderVarName( NMChanWaveListStrVarPrefix(), chanNum )

End // NMChanWaveListStrVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveList( chanNum )
	Variable chanNum // channel number or ( -1 ) for current channel
	
	String strVarName
	
	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
		return ""
	endif
	
	if ( chanNum < 0 )
		chanNum = CurrentNMChannel()
	endif
	
	if ( ( chanNum >= 0 ) && ( chanNum < NMNumChannels() ) )
	
		strVarName = NMChanWaveListStrVarName( chanNum )
		
		return StrVarOrDefault( strVarName, "" )
		
	endif
	
	return ""
	
End // NMChanWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveName( chanNum, waveNum )
	Variable chanNum // channel number ( pass -1 for current )
	Variable waveNum // wave number ( pass -1 for current )
	
	// return name of wave from wave ChanWaveList, given channel and wave number
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	if ( chanNum == -1 )
		chanNum = NumVarOrDefault(prefixFolder+"CurrentChan", 0)
	endif
	
	if ( waveNum == -1 )
		waveNum = NumVarOrDefault(prefixFolder+"CurrentWave", 0)
	endif
	
	return StringFromList( waveNum, NMChanWaveList( chanNum ) )

End // NMChanWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveNum( wName ) // return wave number, given name
	String wName // wave name
	
	Variable ccnt, found
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 )
	
		found = WhichListItem( wName, NMChanWaveList( ccnt ), ";", 0, 0 )
		
		if ( found >= 0 )
			return found
		endif
		
	endfor
	
	return -1

End // NMChanWaveNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListSet( force ) // update the list of channel wave names
	Variable force // ( 0 ) no ( 1 ) yes
	
	Variable ccnt, icnt, jcnt = -1
	Variable wcnt, nwaves, nmax, strict
	
	String wname, strVarName, wList = "", allList = "", sList = ""
	
	String order = NeuroMaticStr( "OrderWavesBy" )
	
	String currentPrefix = CurrentNMWavePrefix()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( numChannels == 0 )
		return 0
	endif
	
	DoWindow /K $NMChanWaveListTableName()
	
	if ( force == 1 )
		NMPrefixFolderStrVarKill( NMChanWaveListStrVarPrefix() ) // kill existing string variables
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
	
		strVarName = NMChanWaveListStrVarName( ccnt )
	
		if ( ( force != 1 ) && ( ItemsInList( StrVarOrDefault( strVarName, "" ) ) > 0 ) )
			continue
		endif
		
		wList = ""
			
		if ( numChannels == 1 )
		
			wList = WaveList( currentPrefix + "*", ";", "Text:0" )
			
		else
		
			if ( jcnt < 0 )
				wList = NMChanWaveListSearch( currentPrefix, ccnt )
			endif
			
			if ( ItemsInList( wList ) == 0 )
			
				jcnt = max( jcnt, ccnt )
		
				for ( icnt = jcnt; icnt < 10; icnt += 1 )
				
					wList = NMChanWaveListSearch( currentPrefix, icnt )
					
					if ( ItemsInList( wList ) > 0 )
						jcnt = icnt + 1
						break
					endif
					
				endfor
				
			endif
			
		endif

		if ( ItemsInList( wList ) == 0 ) // if none found, try most general name
			wList = WaveList( currentPrefix + "*", ";", "Text:0" )
		endif
		
		for ( wcnt = 0; wcnt < ItemsInList( allList ); wcnt += 1 ) // remove waves already used
			wname = StringFromList( wcnt, allList )
			wList = RemoveFromList( wname, wList )
		endfor
		
		nwaves = ItemsInList( wList )
		
		if ( nwaves > nmax )
			nmax = nwaves
		endif
		
		if ( nwaves == 0 )
			continue
		elseif ( nwaves != NumWaves )
			//NMDoAlert( "Warning: located only " + num2istr( nwaves ) + " waves for channel " + ChanNum2Char( ccnt ) + "." )
		endif
		
		//strict = ChanWaveListStrict( wList, ccnt )
		
		slist = SortList( wList, ";", 16 ) // SortListAlphaNum( wList, currentPrefix )
		
		if ( ( StringMatch( order, "name" ) == 1 ) && ( StringMatch( wList, slist ) == 0 ) )
			wList = slist
		endif
		
		//Print "Chan" + ChanNum2Char( ccnt ) + ": " + wList
	
		SetNMstr( strVarName, wList )
		
		allList += wList
		
	endfor
	
	NMChanWaveList2Waves()

End // NMChanWaveListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListSearch( wavePrefix, chanNum ) // return list of waves appropriate for channel
	String wavePrefix // wave prefix
	Variable chanNum
	
	Variable wcnt, icnt, jcnt, seqnum, foundLetter
	String wList, wname, seqstr, olist = ""
	
	String chanstr = ChanNum2Char( chanNum )

	wList = WaveList( wavePrefix + "*" + chanstr + "*", ";", "Text:0" )
	
	if ( ( strlen( wavePrefix ) == 0 ) || ( strlen( chanstr ) == 0 ) )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wname = StringFromList( wcnt, wList )
		
		for ( icnt = strlen( wname )-2; icnt > 0; icnt -= 1 )
		
			if ( StringMatch( wname[icnt,icnt], chanstr ) == 1 )
			
				seqstr = wname[icnt+1,inf]
				foundLetter = 0
				
				for ( jcnt=0; jcnt < strlen( seqstr ); jcnt += 1 )
					if ( numtype( str2num( seqstr[jcnt, jcnt] ) ) > 0 )
						foundLetter = 1
					endif
				endfor
				
				if ( foundLetter == 0 )
					olist = AddListItem( wname, olist, ";", inf ) // matches criteria
				endif
				
				break
				
			endif
			
		endfor
		
	endfor
	
	return olist

End // NMChanWaveListSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListSort( chanNum, sortOption )
	Variable chanNum // channel number ( -1 ) for all currently selected channels
	Variable sortOption // ( -1 ) sort by creation date ( >= 0 ) see Igor SortList function options
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String strVarName, wList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	String currentPrefix = CurrentNMWavePrefix()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	DoWindow /K $NMChanWaveListTableName()
	
	if ( chanNum < 0 )
		cbgn = 0
		cend = numpnts( wtemp )
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		strVarName = NMChanWaveListStrVarName( ccnt )
		wList = StrVarOrDefault( strVarName, "" )
		
		if ( ItemsInList( wList ) == 0 )
			continue
		endif
	
		switch( sortOption )
		
			case 0:
			case 1:
			case 2:
			case 4:
			case 8:
			case 16:
				wList = SortList( wList, ";", sortOption )
				SetNMstr( strVarName, wList )
				break
				
			case -1:
				wList = SortWaveListByCreation( wList )
				SetNMstr( strVarName, wList )
				break
				
			default:
				return -1
		
		endswitch
		
	endfor
	
	NMChanWaveList2Waves()

End // NMChanWaveListSort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMOrderWavesCall()

	String wList

	Variable order = NeuroMaticVar( "OrderWaves" )

	String tname = NMChanWaveListTableName()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
		
	if ( WinType( tname ) == 2 )
		DoWindow /F $tname
		wList = NMFolderWaveList( prefixFolder, "*", ";","WIN:"+ tname, 0 )
		NMChanWaveListOrder( wList )
		NMChanWaves2WaveList()
		return ""
	endif
	
	Prompt order, "order waves by:", popup "creation date;alpha-numerically;user-input table;"
	DoPrompt NMPromptStr( "Order Waves" ), order
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNeuroMaticVar( "OrderWaves", order )
	
	switch( order )
		case 1:
			NMCmdHistory( "NMOrderWavesByCreation", "" )
			NMOrderWavesByCreation()
			break
		case 2:
			NMCmdHistory( "NMOrderWavesAlphaNum", "" )
			NMOrderWavesAlphaNum()
			break
		case 3:
			NMCmdHistory( "NMOrderWavesByTable", "" )
			NMOrderWavesByTable()
			break
	endswitch

End // NMOrderWavesCall()

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesByCreation()

	Variable ccnt, numChannels = NMNumChannels()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif

	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
		if ( NMChanSelected( ccnt ) == 1 )
			NMChanWaveListSort( ccnt, -1 )
		endif
	endfor
	
	ChanGraphsUpdate()

End // NMOrderWavesByCreation

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesAlphaNum()

	Variable ccnt, numChannels = NMNumChannels()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif

	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
		if ( NMChanSelected( ccnt ) == 1 )
			NMChanWaveListSort( ccnt, 16 )
		endif
	endfor
	
	ChanGraphsUpdate()

End // NMOrderWavesAlphaNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesByTable()

	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	if ( NMChanSelectedAll() == 1 )
		NMChanWaveListOrderTable( -1 )
	else
		NMChanWaveListOrderTable( CurrentNMChannel() )
	endif

End // NMOrderWavesByTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListTableName()

	return "NM_" + NMFolderPrefix( "" ) + "OrderWaveNames"

End // NMChanWaveListTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListOrderTable( chanNum )
	Variable chanNum // ( -1 ) for All
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	String wname = NMChanWaveListName( ccnt )
	String wname2 = prefixFolder + "wnames_Order"
	
	String tName = NMChanWaveListTableName()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	if ( WinType( tName ) > 0 )
		DoWindow /F $tName
		return 0
	endif
	
	if ( chanNum < 0 )
		cbgn = 0
		cend = NMNumChannels()
	endif
	
	Make /O/N=( numpnts( $wname ) ) $wname2
	Wave wtemp = $wname2
	wtemp = x
	
	Edit /K=1/N=$tName $wname2 as "Click " + NMQuotes( "Order Waves" ) + " to re-order"
	SetWindow $tName hook=NMChanWaveListTableHook
	Execute /Z "ModifyTable title( Point )= " + NMQuotes( "Order" )
	
	SetCascadeXY( tName )
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		wname = NMChanWaveListName( ccnt )
		
		if ( WaveExists( $wname ) == 1 )
			AppendToTable /W=$tName $wname
		endif
		
	endfor
	
	RemoveFromTable /W=$tName $wname2
	
	AppendToTable /W=$tName $wname2

End // NMChanWaveListOrderTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListTableHook( infoStr )
	String infoStr
	
	String event= StringByKey( "EVENT", infoStr )
	String win= StringByKey( "WINDOW", infoStr )
	
	String wList = NMFolderWaveList( CurrentNMPrefixFolder(), "*", ";","WIN:"+ win, 0 )
	
	if ( ItemsInList( wList ) <= 1 )
		return -1
	endif

	strswitch( event )
		case "kill":
			NMChanWaveListOrder( wList )
	endswitch

End // NMChanWaveListTableHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListOrder( wList )
	String wList

	Variable wcnt
	String wname
	
	String prefixFolder = CurrentNMPrefixFolder()
	String wname2 = prefixFolder + "wnames_Order"
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	if ( WaveExists( $wname2 ) == 0 )
		NMDoAlert( "Abort NMChanWaveListOrder: missing wave wnames_Order" )
		return -1
	endif
	
	wList = RemoveFromList( wname2, wList )
	
	if ( ItemsInList( wList ) == 0 )
		NMDoAlert( "Abort NMChanWaveListOrder: no waves to order" )
		return -1
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wname = prefixFolder + StringFromList( wcnt, wList )
		
		if ( ( WaveExists( $wname ) == 0 ) || ( numpnts( $wname ) != numpnts( $wname2 ) ) )
			Print "Failed to order waves."
			continue
		endif
		
		Sort $wname2, $wname
		
	endfor
	
	Sort $wname2, $wname2
	
	Wave wtemp = $wname2
	
	wtemp = x
	
	NMChanWaves2WaveList()

End // NMChanWaveListOrder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S OrderToNMChanWaveList( wList, chanNum )
	String wList // wave list to order
	Variable chanNum
	
	Variable items, i
	String chanList, prefixFolder = CurrentNMPrefixFolder()
	String item, outList = ""
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return wList
	endif
	
	if ( ( chanNum < 0 ) || ( chanNum >= NMNumChannels() ) )
		return wList
	endif
	
	chanList = NMChanWaveList( chanNum )
	
	items = ItemsInList( chanList )
	
	for ( i = 0 ; i < items ; i += 1 )
		
		item = StringFromList( i, chanList )
		
		if ( WhichListItem( item, wList ) >= 0 )
			outList += item + ";"
		endif
		
	endfor
	
	return outList
	
End // OrderToNMChanWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListPrefix()
	String setName
	
	return "ChanWaveNames"
	
End // NMChanWaveListPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListName( chanNum )
	Variable chanNum

	return NMPrefixFolderVarName( NMChanWaveListPrefix(), chanNum )

End // NMChanWaveListName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveList2Waves()

	Variable ccnt, icnt
	String strVarName, wList, wname
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	NMPrefixFolderWaveKill( NMChanWaveListPrefix() )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		strVarName = NMChanWaveListStrVarName( ccnt )
		
		wList = StrVarOrDefault( strVarName, "" )
		
		wname = NMChanWaveListName( ccnt )
		
		Make /O/T/N=( numWaves ) $wname = ""
		
		Wave /T wtemp = $wname
		
		for ( icnt = 0 ; icnt < numWaves ; icnt += 1 )
		
			wtemp[ icnt ] = StringFromList( icnt, wList )
			
		endfor
		
	endfor

End // NMChanWaveList2Waves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaves2WaveList()

	Variable ccnt, icnt
	String strVarName, wname, wList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable numChannels = NMNumChannels()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	NMPrefixFolderStrVarKill( NMChanWaveListStrVarPrefix() )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
		strVarName = NMChanWaveListStrVarName( ccnt )
		wname = NMChanWaveListName( ccnt )
		
		if ( WaveExists( $wname ) == 0 )
			continue
		endif
		
		Wave /T wtemp = $wname
		
		wList = ""
		
		for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
			wList = AddListItem( wtemp[ icnt ], wList, ";", inf )
		endfor
		
		SetNMstr( strVarName, wList )
		
	endfor

End // NMChanWaves2WaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanXstats( select )
	String select // see GetXstats

	Variable ccnt
	String wList = ""
	
	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
		return Nan
	endif

	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 )
		wList = NMAddToList( NMChanWaveList( ccnt ), wList, ";" )
	endfor

	return GetXstats( select, wList )
	
End // NMChanXstats

//****************************************************************
//****************************************************************
//****************************************************************