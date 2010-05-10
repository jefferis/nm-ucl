#pragma rtGlobals = 1
#pragma IgorVersion = 6.1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Utility Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMUtilityWaveTest( wList )
	String wList // wave list ( seperator ";" )
	
	Variable wcnt
	String wName
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
	
		if ( ( WaveExists( $wName ) == 0 ) || ( WaveType( $wName ) == 0 ) )
			return -1
		endif
		
	endfor
	
	return 0
	
End // NMUtilityWaveTest

//****************************************************************
//****************************************************************
//****************************************************************

Function NMUtilityAlert( fxn, badList )
	String fxn
	String badList

	if ( ItemsInList( badList ) <= 0 )
		return 0
	endif
	
	String alert = fxn + " Alert : the following waves failed to pass sucessfully through function execution : " + badList
	
	NMHistory( alert )
	
End // NMUtilityAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMUtilityWaveListShort( wList )
	String wList
	
	Variable wcnt
	String prefix, wName, tempList = "", foundList = "", oList = ""
	
	prefix = FindCommonPrefix( wList )
	
	if ( strlen( prefix ) == 0 )
		return wList
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( strsearch( wName, prefix, 0 ) == 0 )
			foundList = AddListItem( wName, foundList, ";", inf )
			tempList = AddListItem( ReplaceString( prefix, wName, "" ), tempList, ";", inf )
		endif
	
	endfor
	
	if ( ItemsInList( tempList ) > 1 )
	
		tempList = SequenceToRangeStr( tempList, "-" )
		
		oList = AddListItem( prefix + "," + ReplaceString( ";", tempList, "," ), oList, ";", inf )
	
	endif
	
	return ReplaceString( ",;", oList, ";" ) + RemoveFromList( foundList, wList )
	
End // NMUtilityWaveListShort

//****************************************************************
//****************************************************************
//****************************************************************

Function BinaryCheck( n )
	Variable n
	
	if ( n == 0 )
		return 0
	else
		return 1
	endif

End // BinaryCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function BinaryInvert( n )
	Variable n
	
	if ( n == 0 )
		return 1
	else
		return 0
	endif

End // BinaryInvert

//****************************************************************
//****************************************************************
//****************************************************************

Function Zero2Nan( n )
	Variable n
	
	if ( n == 0 )
		return Nan
	else
		return n
	endif
	
End // Zero2Nan

//****************************************************************
//****************************************************************
//****************************************************************

Function Nan2Zero( n )
	Variable n
	
	if ( numtype( n ) == 2 )
		return 0
	else
		return n
	endif
	
End // Nan2Zero

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave utility functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function WaveValOrDefault( wName, rowNum, defaultVal )
	String wName // wave name
	Variable rowNum // wave row number to retrive value
	Variable defaultVal // default value if everything values
	
	if ( ( WaveExists( $wName ) == 1 ) && ( WaveType( $wName ) > 0 ) )
		if ( ( rowNum >= 0 ) && ( rowNum < numpnts( $wName ) ) )
			Wave wtemp = $wName
			return wtemp[rowNum]
		endif
	endif
	
	return defaultVal

End // WaveValOrDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function /S WaveStrOrDefault( wName, rowNum, defaultStr )
	String wName // wave name
	Variable rowNum // wave row number to retrieve string
	String defaultStr // default value if does not exist
	
	if ( ( WaveExists( $wName ) == 1 ) && ( WaveType( $wName ) == 0 ) )
		if ( ( rowNum >= 0 ) && ( rowNum < numpnts( $wName ) ) )
			Wave /T wtemp = $wName
			return wtemp[rowNum]
		endif
	endif
	
	return defaultStr

End // WaveStrOrDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function /S WhichWavesDontExist( wList )
	String wList // wave list ( seperator ";" )
	
	Variable wcnt
	String wName, outList = ""
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( WaveExists( $wName ) == 0 )
			outList = AddListItem( wName, outList, ";", inf )
		endif
		
	endfor
	
	return outList // those that dont exist

End // WhichWavesDontExist

//****************************************************************
//****************************************************************
//****************************************************************

Function WavesExist( wList )
	String wList // wave list ( seperator ";" )
	
	Variable wcnt
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		if ( WaveExists( $StringFromList( wcnt, wList ) ) == 0 )
			return 0
		endif
	endfor
	
	return 1 // yes, all exist

End // WavesExist

//****************************************************************
//
//	NMWaveListOptions
//	use this for optionsStr in Igor function WaveList
//
//****************************************************************

Function /S NMWaveListOptions( numRows, wType )
	Variable numRows // number of rows in 1-dimensional wave
	Variable wType // waveType ( 0 ) not text ( 1 ) numeric
	
	return "DIMS:1,MAXROWS:" + num2istr( numRows ) + ",MINROWS:" + num2istr( numRows ) + ",TEXT:" + num2istr( BinaryCheck( wType ) )
	
End // NMWaveListOptions

//****************************************************************
//
//	NMFolderWaveList
//	return WaveList for a given folder (see Igor WaveList function)
//
//****************************************************************

Function /S NMFolderWaveList( folder, matchStr, separatorStr, optionsStr, fullPath )
	String folder // ( "" ) for current folder
	String matchStr, separatorStr, optionsStr // see Igor WaveList
	Variable fullPath // ( 0 ) no, just wave name ( 1 ) yes, directory + wave name
	
	Variable icnt
	String wList, wName, oList = "", thisfxn = "NMFolderWaveList"
	String saveDF = GetDataFolder( 1 ) // save current directory
	
	if ( strlen( folder ) == 0 )
		folder = GetDataFolder( 1 )
	endif
	
	if ( DataFolderExists( folder ) == 0 )
		//return NMErrorStr( 30, thisfxn, "folder", folder )
		return ""
	endif
	
	folder = NMCheckFullPath( folder )
	
	SetDataFolder $RemoveEnding( folder, ":" )
	
	wList = WaveList( matchStr, separatorStr, optionsStr )
	
	SetDataFolder $saveDF // back to original data folder
	
	if ( fullPath == 1 )
	
		for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
			wName = StringFromList( icnt, wList )
			oList = AddListItem( folder + wName , oList, separatorStr, inf ) // full-path names
		endfor
		
		wList = oList
	
	endif
	
	return wList

End // NMFolderWaveList

//****************************************************************
//
//	NMFolderStringList
//	return StringList for a given folder (see Igor StringList function)
//
//****************************************************************

Function /S NMFolderStringList( folder, matchStr, separatorStr, fullPath )
	String folder // ( "" ) for current folder
	String matchStr, separatorStr // see Igor StringList
	Variable fullPath // ( 0 ) no, just variable name ( 1 ) yes, directory + variable name
	
	Variable icnt
	String sList, sName, oList = "", thisfxn = "NMFolderStringList"
	String saveDF = GetDataFolder( 1 ) // save current directory
	
	if ( strlen( folder ) == 0 )
		folder = GetDataFolder( 1 )
	endif
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	SetDataFolder $RemoveEnding( folder, ":" )
	
	sList = StringList( matchStr, separatorStr )
	
	SetDataFolder $saveDF // back to original data folder
	
	if ( fullPath == 1 )
	
		for ( icnt = 0 ; icnt < ItemsInList( sList ) ; icnt += 1 )
			sName = StringFromList( icnt, sList )
			oList = AddListItem( folder+sName, oList, separatorStr, inf ) // full-path names
		endfor
		
		sList = oList
	
	endif
	
	return sList

End // NMFolderStringList

//****************************************************************
//
//	Wave2List()
//	convert wave items to list items
//
//****************************************************************

Function /S Wave2List( wName )
	String wName // wave name
	
	Variable icnt, npnts, numObj
	String strObj, strList = ""
	
	if ( WaveExists( $wName ) == 0 )
		return NMErrorStr( 1, "Wave2List", "wName", wName )
	endif
	
	if ( WaveType( $wName ) == 0 ) // text wave
	
		Wave /T wtext = $wName
		
		npnts = numpnts( wtext )
		
		for ( icnt = 0; icnt < npnts; icnt += 1 )
			
			strObj = wtext[icnt]
			
			if ( strlen( strObj ) > 0 )
				strList = AddListItem( strObj, strList, ";", inf )
			endif
			
		endfor
		
	else // numeric wave
	
		Wave wtemp = $wName
		
		npnts = numpnts( wtemp )
	
		for ( icnt = 0; icnt < npnts; icnt += 1 )
			strList = AddListItem( num2str( wtemp[icnt] ), strList, ";", inf )
		endfor
	
	endif
	
	return strList

End // Wave2List

//****************************************************************
//
//	List2Wave()
//	convert list items to text wave items
//
//****************************************************************

Function List2Wave( strList, wName )
	String strList // string list
	String wName // output wave name
	
	Variable icnt
	String item
	
	Variable items = ItemsInList( strList )
	
	if ( items == 0 )
		return 0 // nothing to do
	endif
	
	if ( WaveExists( $wName ) == 1 )
		return NMError( 2, "List2Wave", "wName", wName )
	endif
	
	Make /T/N=( items ) $wName
	
	Wave /T wtemp = $wName
	
	for ( icnt = 0; icnt < items; icnt += 1 )
		wtemp[icnt] = StringFromList( icnt, strList )
	endfor
	
	return 0

End // List2Wave

//****************************************************************
//
//	NMPlotWavesOffset()
//	plot a list of waves
//
//****************************************************************

Function NMPlotWavesOffset( gName, gTitle, xLabel, yLabel, xWave, wList, xoffset, xoffsetInc, yoffset, yoffsetInc )
	String gName // graph name
	String gTitle // graph title
	String xLabel // x axis label, or ( "" ) from wave notes
	String yLabel // y axis label, or ( "" ) from wave notes
	String xWave // wave of x-values, or ( "" ) to use x-scale of y-waves
	String wList // wave list ( seperator ";" )
	Variable xoffset, xoffsetInc // 0 for none
	Variable yoffset, yoffsetInc // 0 for none

	Variable wcnt, xinc = 1, yinc = 1, gmode, first = 1
	String wName, badList = wList, thisfxn = "NMPlotWavesOffset"
	
	if ( strlen( gName ) == 0 )
		return NMError( 21, thisfxn, "gName", gName )
	endif
	
	if ( strlen( xLabel ) == 0 )
		xLabel = NMNoteLabel( "x", wList, "" )
	endif
	
	if ( strlen( yLabel ) == 0 )
		yLabel = NMNoteLabel( "y", wList, "" )
	endif
	
	if ( ( strlen( xWave ) > 0 ) && ( NMUtilityWaveTest( xWave ) < 0 ) )
		return NMError( 1, thisfxn, "xWave", xWave )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	if ( numtype( xoffset ) > 0 )
		xoffset = 0
		xoffsetInc = 0
	endif
	
	if ( numtype( yoffset ) > 0 )
		yoffset = 0
		yoffsetInc = 0
	endif
	
	if ( ( numtype( xoffsetInc ) == 0 ) && ( xoffsetInc > 0 ) )
		xinc = 0
	endif
	
	if ( ( numtype( yoffsetInc ) == 0 ) && ( yoffsetInc > 0 ) )
		yinc = 0
	endif
	
	DoWindow /K $gName // kill window if it already exists

	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )

		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		badList = RemoveFromList( wName, badList )
		
		WaveStats /Q/Z $wName
		
		if ( ( V_numNaNs > 2 ) && ( V_npnts > 0 ) && ( V_npnts < 1000 ) )
			//gmode = 4
		endif
	
		if ( first == 1 )
		
			first = 0
			
			if ( strlen( xWave ) > 0 )
				Display /K=1/N=$gName/W=( 0,0,0,0 ) $wName vs $xWave as gTitle
			else
				Display /K=1/N=$gName/W=( 0,0,0,0 ) $wName as gTitle
			endif
			
			SetCascadeXY( gName )
			
			if ( xoffsetInc > 0 )
				xinc += xoffsetInc
			endif
			
			if ( yoffsetInc > 0 )
				yinc += yoffsetInc
			endif
		
			continue
			
		endif
		
		if ( first == 0 )
			if ( strlen( xWave ) > 0 )
				AppendToGraph /W=$gName $wName vs $xWave
			else
				AppendToGraph /W=$gName $wName
			endif
		endif
		
		ModifyGraph /W=$gName offset( $wName )={xoffset*xinc, yoffset*yinc}
		
		if ( xoffsetInc > 0 )
			xinc += xoffsetInc
		endif
		
		if ( yoffsetInc > 0 )
			yinc += yoffsetInc
		endif

	endfor
	
	if ( first == 1 )
		return -1 // nothing plotted
	endif
	
	ModifyGraph /W=$gName rgb=( 0,0,0 ), mode=gmode
	Label /W=$gName left yLabel
	Label /W=$gName bottom xLabel
	ModifyGraph /W=$gName standoff=0
	SetAxis /A
	//ShowInfo /W=$gName
	
	NMUtilityAlert( thisfxn, badList )
	
	return 0

End // NMPlotWavesOffset

//****************************************************************
//
//	NMPlotAppend()
//	append waves to a graph
//
//****************************************************************

Function NMPlotAppend( gName, color, xWave, wList, xoffset, xoffsetInc, yoffset, yoffsetInc )
	String gName // graph name
	String color // "black", "red", "green", "blue", "yellow", "purple", or ( "" ) default
	String xWave // optional, plot against this xWave, or ( "" ) for no xWave
	String wList // wave list ( seperator ";" )
	Variable xoffset, xoffsetInc
	Variable yoffset, yoffsetInc

	Variable r, g, b, wcnt, xinc = 1, yinc = 1
	String wName, thisfxn = "NMPlotAppend"
	
	if ( WinType( gName ) != 1 )
		return NMError( 40, thisfxn, "gName", gName )
	endif
	
	strswitch( color )
		case "black":
		case "red":
		case "green":
		case "blue":
		case "yellow":
		case "purple":
			break
		default:
			color = "black"
	endswitch
	
	if ( ( strlen( xWave ) > 0 ) && ( NMUtilityWaveTest( xWave ) < 0 ) )
		return NMError( 1, thisfxn, "xWave", xWave )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	r = NMPlotRGB( color, "r" )
	g = NMPlotRGB( color, "g" )
	b = NMPlotRGB( color, "b" )
	
	if ( ( strlen( xWave ) > 0 ) && ( NMUtilityWaveTest( xWave ) < 0 ) )
		xWave = ""
	endif
	
	if ( xoffsetInc > 0 )
		xinc = 0
	endif
	
	if ( yoffsetInc > 0 )
		yinc = 0
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		if ( strlen( xWave ) > 0 )
			AppendToGraph /W=$gName/C=( r,g,b ) $wName vs $xWave
		else
			AppendToGraph /W=$gName/C=( r,g,b ) $wName
		endif
		
		ModifyGraph /W=$gName offset( $wName )={xOffset*xinc, yOffset*yinc}
		
		if ( xoffsetInc > 0 )
			xinc += xoffsetInc
		endif
		
		if ( yoffsetInc > 0 )
			yinc += yoffsetInc
		endif
		
	endfor
	
	return 0
	
End // NMPlotAppend

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPlotRGB( color, rgb )
	String color
	String rgb // "r" or "g" or "b"
	
	Variable r, g, b
	
	strswitch( color )
	
		case "red":
		
			strswitch( rgb )
				case "r":
					return 65535
			endswitch
			
			break
			
		case "yellow":
		
			strswitch( rgb )
				case "r":
				case "g":
					return 65535
			endswitch
			
			break
			
		case "green":
		
			strswitch( rgb )
				case "g":
					return 65535
			endswitch
			
			break
			
		case "blue":
		
			strswitch( rgb )
				case "b":
					return 65535
			endswitch
			
			break
			
		case "purple":
		
			strswitch( rgb )
				case "r":
				case "b":
					return 65535
			endswitch
			
			break
			
	endswitch
	
	return 0

End // NMPlotRGB

//****************************************************************
//
//	EditWaves()
//	edit a list of waves ( create a table )
//
//****************************************************************

Function EditWaves( tName, tTitle, wList )
	String tName // table name
	String tTitle // table title
	String wList // wave list ( seperator ";" )

	Variable wcnt, first = 1
	String wName, badList = wList, thisfxn = "EditWaves"
	
	if ( strlen( tName ) == 0 )
		return NMError( 21, thisfxn, "tName", tName )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	if ( WinType( tName ) > 0 )
	
		if ( WinType( tName ) != 2 )
			return NMError( 90, thisfxn, "window already exists with the name " + NMQuotes( tName ), "" )
		endif
	
		DoAlert 2, "Warning: table " + NMQuotes( tName ) + " already exists. Do you want to overwrite it?"
		
		if ( V_flag == 1 ) // yes
		
			DoWindow /K $tName // kill window
			
		elseif ( V_flag == 2 ) // no
			
			tName += "_0"
			
			Prompt tName, "enter new name for table:"
			DoPrompt "Edit Waves", tName
			
			if ( V_flag == 1 )
				return -1 // cancel
			endif
		
		elseif ( V_flag == 3 ) // cancel
		
			return - 1
			
		endif
	
	endif

	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )

		if ( WaveExists( $wName ) == 0 )
			continue
		endif
		
		badList = RemoveFromList( wName, badList )
	
		if ( first == 1 )
			first = 0
			Edit /K=1/N=$tName/W=( 0,0,0,0 ) $wName as tTitle
			SetCascadeXY( tName )
			continue
		endif
		
		if ( first == 0 )
			AppendToTable $wName
		endif
		
	endfor
	
	if ( first == 1 )
		return -1 // nothing plotted
	endif
	
	NMUtilityAlert( thisfxn, badList )
	
	return 0

End // EditWaves

//****************************************************************
//
//	DeleteWaves()
//	delete a list of waves
//
//****************************************************************

Function /S DeleteWaves( wList )
	String wList // wave list ( seperator ";" )
	
	String wName, outList = "", badList = wList
	Variable wcnt, move
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( WaveExists( $wName ) == 0 )
			continue
		endif
		
		KillWaves /Z $wName
		
		if ( WaveExists( $wName ) == 0 )
			outList = AddListItem( wName, outList, ";", inf )
			badList = RemoveFromList( wName, badList )
		endif
	
	endfor
	
	//NMUtilityAlert( thisfxn, badList )
	
	return outList

End // DeleteWaves

//****************************************************************
//
//	CopyWaves()
//	duplicate a list of waves - giving them a new prefix name
//
//****************************************************************

Function /S CopyWaves( newPrefix, tbgn, tend, wList )
	String newPrefix // new wave prefix of duplicated waves
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, alert
	String wName, newName, newList = "", badList = ""
	String thisfxn = "CopyWaves"
	
	if ( strlen( newPrefix ) == 0 )
		return NMErrorStr( 21, thisfxn, "newPrefix", newPrefix )
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -2
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		newName = newPrefix + wName
		
		if ( StringMatch( wName, newName ) == 1 )
			return ""
		endif
		
		if ( WaveExists( $newName ) == 1 )
			alert = 1
		endif
		
	endfor
	
	if ( alert == 1 )
	
		DoAlert 2, "CopyWaves Alert: wave(s) with prefix " + NMQuotes( newPrefix ) + " already exist. Do you want to over-write them?"
		
		if ( V_flag != 1 )
			return "" // cancel
		endif
		
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		newName = newPrefix + wName
		
		if ( WaveExists( $wName ) == 0 )
			continue
		endif
		
		if ( ( numtype( tbgn ) == 0 ) && ( numtype( tend ) == 0 ) )
			Duplicate /O/R=( tbgn,tend ) $wName $newName
		else
			Duplicate /O $wName $newName
		endif
		
		badList = RemoveFromList( wName, badList )
		newList += newName + ";"
		
		Note $newName, "Func:" + thisfxn
		Note $newName, "Copy From:" + num2str( tbgn ) + ";Copy To:" + num2str( tend ) + ";"
		
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return newList

End // CopyWaves

//****************************************************************
//
//	CopyWavesTo()
//	copy waves from one folder to another
//
//****************************************************************

Function /S CopyWavesTo( fromFolder, toFolder, newPrefix, tbgn, tend, wList, alert )
	String fromFolder // copy waves from
	String toFolder // copy waves to
	String newPrefix // new wave prefix, ( "" ) for same as source waves
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	String wList // wave list, or ( "_All_" ) for all waves
	Variable alert // ( 0 ) no alert ( 1 ) alert if overwriting
	
	Variable wcnt, overwrite, first = 1
	String wName, dname, fName, outList = "", badList = wList
	String thisfxn = "CopyWavesTo"
	
	if ( DataFolderExists( fromFolder ) == 0 )
		return NMErrorStr( 30, thisfxn, "fromFolder", fromFolder )
	endif
	
	if ( DataFolderExists( toFolder ) == 0 )
		return NMErrorStr( 30, thisfxn, "toFolder", toFolder )
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( StringMatch( wList, "_All_" ) == 1 )
		wList = NMFolderWaveList( fromFolder, "*", ";", "", 0 )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	fromFolder = ParseFilePath( 2, fromFolder, ":", 0, 0 )
	toFolder = ParseFilePath( 2, toFolder, ":", 0, 0 )
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
	
		dname = toFolder + newPrefix + wName
		
		if ( ( WaveExists( $dname ) == 1 ) && ( alert == 1 ) && ( first == 1 ) )
		
			fName = GetPathName( toFolder, 0 )
		
			DoAlert 1, "CopyWavesTo Alert: wave(s) with the same name already exist in folder " + fName + ". Do you want to over-write them?"
			
			first = 0
			
			if ( V_flag == 1 )
				overwrite = 1
			endif
			
		endif
		
		if ( ( WaveExists( $dname ) == 1 ) && ( alert == 1 ) && ( overwrite == 0 ) )
			continue
		endif
		
		if ( WaveExists( $( fromFolder+wName ) ) == 0 )
			continue
		endif
		
		Wave wtemp = $( fromFolder+wName )
		
		Duplicate /O/R=( tbgn, tend ) wtemp $dname
		
		outList = AddListItem( dname, outList, ";", inf )
		
		badList = RemoveFromList( wName, badList )
		
	endfor
	
	//NMUtilityAlert( thisfxn, badList )
	
	return outList

End // CopyWavesTo

//****************************************************************
//
//	RenameWaves()
//	string replace name
//
//****************************************************************

Function /S RenameWaves( findStr, repStr, wList )
	String findStr // search string
	String repStr // replace string
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, first = 1, kill
	String wName, newName = "", outList = "", badList = wList
	String thisfxn = "RenameWaves"
	
	if ( strlen( findStr ) == 0 )
		return NMErrorStr( 21, thisfxn, "findStr", findStr )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		newName = ReplaceString( findStr, wName, repStr )
		
		if ( StringMatch( newName, wName ) == 1 )
			continue // no change
		endif
		
		if ( ( WaveExists( $newName ) == 1 ) && ( first == 1 ) )
		
			DoAlert 1, "Name Conflict: wave(s) already exist with new name. Do you want to over-write them?"
			
			first = 0
			
			if ( V_Flag == 1 )
				kill = 1
			endif
			
		endif
		
		if ( ( WaveExists( $newName ) == 1 ) && ( kill == 1 ) && ( first == 0 ) )
			KillWaves /Z $newName
		endif
		
		if ( ( WaveExists( $wName ) == 0 ) || ( WaveExists( $newName ) == 1 ) )
			continue
		endif

		Rename $wName $newName
		
		outList = AddListItem( newName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
	endfor
	
	//NMUtilityAlert( thisfxn, badList )
	
	return outList

End // RenameWaves

//****************************************************************
//
//	RenumberWaves()
//
//****************************************************************

Function /S RenumberWaves( from, wList )
	Variable from // renumber from
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, icnt, jcnt, found, nwaves
	String wName, newName, outList = "", badList = wList
	String oldList = "", newList = "", thisfxn = "RenumberWaves"
	
	if ( ( numtype( from ) > 0 ) || ( from < 0 ) )
		return ""
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	nwaves = ItemsInList( wList )
	
	jcnt = from + nwaves - 1
	
	for ( wcnt = nwaves - 1; wcnt >= 0; wcnt -= 1 ) // must renumber backwards
	
		wName = StringFromList( wcnt, wList )
		
		found = 0
		
		for ( icnt = strlen( wName ) - 1; icnt > 0; icnt -= 1 )
		
			if ( numtype( str2num( wName[ icnt, icnt ] ) ) > 0 )
				found = 1
				break
			endif
		
		endfor
		
		if ( found == 1 )
			newName = wname[ 0, icnt ] + num2istr( jcnt )
		else
			newName = wname + num2istr( jcnt )
		endif
		
		if ( StringMatch( newName, wName ) == 1 )
			continue // no change
		endif
		
		if ( ( WhichListItem( newName, wList ) == -1 ) && ( WaveExists( $newName ) == 1 ) )
			return NMErrorStr( 90, thisfxn, "name conflict: wave already exists with the name " + NMQuotes( newName ), "" )
		endif
		
		oldList += wName + ";"
		newList += newName + ";"
		
		jcnt -= 1
		
	endfor
	
	if ( ItemsInList( oldList ) == 0 )
		return ""
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( oldList ) ; icnt += 1 )
	
		wName = StringFromList( icnt, oldList )
		newName = StringFromList( icnt, newList )
		
		if ( ( WaveExists( $wName ) == 0 ) || ( WaveExists( $newName ) == 1 ) )
			continue
		endif

		Rename $wName $newName
		
		outList = AddListItem( newName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
	endfor
	
	NMUtilityAlert( "RenumberWaves", badList )
	
	return outList

End // RenumberWaves

//****************************************************************
//
//	SplitWave()
//	break a wave into several waves
//
//****************************************************************

Function /S SplitWave( wName, outPrefix, chanNum, npnts )
	String wName // wave to break up
	String outPrefix // output wave prefix
	Variable chanNum // ( -1 ) for none
	Variable npnts // points of output waves
	
	Variable nwaves, wcnt, ibgn, iend
	String xl, yl, outName, wList = "", thisfxn = "SplitWave"
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NMErrorStr( 1, thisfxn, "wName", wName )
	endif
	
	if ( strlen( outPrefix ) == 0 )
		return NMErrorStr( 21, thisfxn, "outPrefix", outPrefix )
	endif
	
	if ( ( numtype( npnts ) > 0 ) || ( npnts <= 0 ) )
		return NMErrorStr( 10, thisfxn, "npnts", num2istr( npnts ) )
	endif
	
	nwaves = numpnts( $wName ) / npnts
	
	if ( nwaves <= 1 )
		return ""
	endif

	for ( wcnt = 0; wcnt < nwaves; wcnt += 1 )
	
		if ( wcnt > 0 )
			ibgn = iend + 1
		endif
		
		iend = ibgn + npnts - 1
		
		//print wName, ibgn, iend
		
		outName = GetWaveName( outPrefix, chanNum, wcnt )
		
		if ( strlen( outName ) == 0 )
			return NMErrorStr( 21, thisfxn, "outName", outName )
		endif
		
		if ( WaveExists( $outName ) == 1 )
		
			DoAlert 1, "Split wave alert: output wave name " + outName + " is already in use. Do you want to continue?"
			
			if ( V_flag == 2 )
				return wList
			endif
			
		endif
		
		Duplicate /O/R=[ibgn, iend] $wName $outName
		
		wList = AddListItem( outName, wList, ";", inf )
		
	endfor
	
	return wList

End // SplitWave

//****************************************************************
//
//	DiffWaves()
//	differentiate a list of waves
//
//****************************************************************

Function /S DiffWaves( wList, dtFlag )
	String wList // wave list ( seperator ";" )
	Variable dtFlag  // ( 1 ) single d/dt ( 2 ) double d/dt ( 3 ) integrate
	
	Variable wcnt, count
	String wName, outList = "", badList = wList
	String thisfxn = "DiffWaves"
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Note $wName, "Func:" + thisfxn
		
		switch( dtFlag  )
			case 1:
				Differentiate $wName
				Note $wName, "F( t ):d/dt;"
				break
			case 2:
				Differentiate $wName
				Differentiate $wName
				Note $wName, "F( t ):dd/dt*dt;"
				break
			case 3:
				Integrate $wName
				Note $wName, "F( t ):integrate;"
				break
			default:
				return NMErrorStr( 10, thisfxn, "dtFlag", num2str( dtFlag ) )
		endswitch
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // DiffWaves

//****************************************************************
//
//	SmoothWaves()
//	smooth a list of waves, using Smooth function
//
//****************************************************************

Function /S SmoothWaves( smthAlg, AvgN, wList )
	String smthAlg // smoothing algorithm
	Variable AvgN // smooth number ( see 'Smooth' help )
	String wList // wave list ( seperator ";" )
	
	Variable wcnt
	String wName, outList = "", badList = wList
	String thisfxn = "SmoothWaves"
	
	if ( ( numtype( avgN ) > 0 ) || ( avgN < 1 )  )
		return NMErrorStr( 10, thisfxn, "avgN", num2istr( avgN ) )
	endif
	
	if ( ( StringMatch( smthAlg, "polynomial" ) == 1 ) && ( ( avgN < 5 ) || ( avgN > 25 ) ) )
		return NMErrorStr( 90, thisfxn, "number of points must be greater than 5 and less than 25 for polynomial smoothing.", "" )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Note $wName, "Func:" + thisfxn
		
		strswitch( smthAlg )
			case "binomial":
				Smooth AvgN, $wName
				Note $wName, "Smth Alg:binomial;Smth Num:" + num2istr( AvgN ) + ";"
				break
			case "boxcar":
				Smooth /B AvgN, $wName
				Note $wName, "Smth Alg:boxcar;Smth Num:" + num2istr( AvgN ) + ";"
				break
			case "polynomial":
				Smooth /S=2 AvgN, $wName
				Note $wName, "Smth Alg:polynomial;Smth Num:" + num2istr( AvgN ) + ";"
				break
			default:
				return NMErrorStr( 20, thisfxn, "smthAlg", smthAlg )
		endswitch
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
	
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // SmoothWaves

//****************************************************************
//
//	FilterFIRwaves()
//	filter a list of waves, using Igor FilterFIR function
//
//****************************************************************

Function /S FilterFIRwaves( alg, f1, f2, n, wList )
	String alg // "low-pass","high-pass" or "notch"
	Variable f1, f2, n // see FilterFIR
	String wList // wave list ( seperator ";" )
	
	Variable wcnt
	String wName, outList = "", badList = wList
	String thisfxn = "FilterFIRwaves"
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	if ( ( numtype( f1 ) > 0 ) || ( f1 <= 0 ) || ( f1 > 0.5) )
		return NMErrorStr( 90, thisfxn, "f1 is out of range: " + num2str( f1 ), "" )
	endif
	
	if ( ( numtype( f2 ) > 0 ) || ( f2 <= 0 ) || ( f2 > 0.5) )
		return NMErrorStr( 90, thisfxn, "f2 is out of range: " + num2str( f2 ), "" )
	endif
	
	strswitch( alg )
	
		case "low-pass":
		case "high-pass":
		
			if ( f1 >= f2 )
				return NMErrorStr( 90, thisfxn, "filter f1 > f2", "" )
			endif
			
			if ( ( numtype( n ) > 0 ) || ( n <= 0 ) )
				return NMErrorStr( 10, thisfxn, "n", num2str( n ) )
			endif
			
			break
			
		case "notch":
		
			if ( f2 < 0.0079 )
				//return NMErrorStr( 90, thisfxn, "f2 is out of range: " + num2str( f2 ), "" )
			endif
			
			break
			
		default:
			return NMErrorStr( 20, thisfxn, "alg", alg )
			
	endswitch
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Note $wName, "Func:" + thisfxn
		
		strswitch( alg )
			case "low-pass":
				FilterFIR /LO={f1, f2, n} $wName
				Note $wName, "FilterFIR Alg:" + alg + ";f1:" + num2str( f1 ) + ";f2:" + num2str( f2 ) + ";n:" + num2str( n ) + ";"
				break
			case "high-pass":
				FilterFIR /HI={f1, f2, n } $wName
				Note $wName, "FilterFIR Alg:" + alg + ";f1:" + num2str( f1 ) + ";f2:" + num2str( f2 ) + ";n:" + num2str( n ) + ";"
				break
			case "notch":
				FilterFIR /NMF={f1, f2} $wName
				Note $wName, "FilterFIR Alg:" + alg + ";fc:" + num2str( f1 ) + ";fw:" + num2str( f2 ) + ";"
				break
			default:
				return ""
		endswitch
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
	
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // FilterFIRwaves

//****************************************************************
//
//	FilterIIRwaves()
//	filter a list of waves, using Igor FilterIIR function
//
//****************************************************************

Function /S FilterIIRwaves( alg, freqFraction, notchQ, wList )
	String alg // "low-pass","high-pass" or "notch"
	Variable freqFraction, notchQ // see Igor FilterIIR function ( freqFraction = fHigh or fLow or fNotch )
	String wList // wave list ( seperator ";" )
	
	Variable wcnt
	String wName, outList = "", badList = wList
	String thisfxn = "FilterIIRwaves"
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	if ( ( numtype( freqFraction ) > 0 ) || ( freqFraction <= 0 ) || ( freqFraction > 0.5) )
		return NMErrorStr( 10, thisfxn, "freqFraction", num2str( freqFraction ) )
	endif
	
	strswitch( alg )
	
		case "low-pass":
		case "high-pass":
			break
	
		case "notch":
			
			if ( ( numtype( notchQ ) > 0 ) || ( notchQ <= 1 ) )
				return NMErrorStr( 10, thisfxn, "notchQ", num2str( notchQ ) )
			endif
			
			break
			
		default:
			return NMErrorStr( 20, thisfxn, "alg", alg )
			
	endswitch
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Note $wName, "Func:" + thisfxn
		
		strswitch( alg )
			case "low-pass":
				FilterIIR /LO=( freqFraction ) $wName
				Note $wName, "FilterIIR Alg:" + alg + ";freq:" + num2str( freqFraction ) + ";"
				break
			case "high-pass":
				FilterIIR /HI=( freqFraction ) $wName
				Note $wName, "FilterIIR Alg:" + alg + ";freq:" + num2str( freqFraction ) + ";"
				break
			case "notch":
				FilterIIR /N={freqFraction,notchQ} $wName
				Note $wName, "FilterIIR Alg:" + alg + ";fNotch:" + num2str( freqFraction ) + ";notchQ:" + num2str( notchQ ) + ";"
				break
		endswitch
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
	
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // FilterIIRwaves

//****************************************************************
//
//	ResampleWaves()
//	resample a list of waves ( see Igor Resample function )
//
//****************************************************************

Function /S ResampleWaves( upSamples, downSamples, rate, wList )
	Variable upSamples // interpolate points, enter 1 for no change
	Variable downSamples // decimate points, enter 1 for no change
	Variable rate // kHz
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, npnts, tdelta, rateflag
	String wName, oldnote, outList = "", badList = wList
	String thisfxn = "ResampleWaves"
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	if ( ( numtype( rate ) == 0 ) && ( rate > 0 ) )
	
		rateflag = 1
		upSamples = 1
		downSamples = 1
		
	else
	
		if ( ( numtype( upSamples ) > 0 ) || ( upSamples < 1 ) )
			upSamples = 1
		endif
		
		if ( ( numtype( downSamples ) > 0 ) || ( downSamples < 1 ) )
			downSamples = 1
		endif
		
		if ( ( upSamples == 1 ) && ( downSamples == 1 ) )
			return "" // nothing to do
		endif
	
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		if ( rateflag == 1 )
			Resample /RATE=( rate ) $wName
		else
			Resample /UP=( upSamples ) /DOWN=( downSamples ) $wName
		endif
		
		Note $wName, "Func:" + thisfxn
		
		if ( rateflag == 1 )
			Note $wName, "Resample rate:" + num2str( rate )
		else
			Note $wName, "Resample upSamples:" + num2istr( upSamples )
			Note $wName, "Resample downSamples:" + num2istr( downSamples )
		endif
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
	endfor
	
	KillWaves /Z U_InterpY
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // ResampleWaves

//****************************************************************
//
//	DecimateWaves()
//	decimate a list of waves - ie. reduce the number of points by linear interp
//
//****************************************************************

Function /S DecimateWaves( ipnts, wList )
	Variable ipnts // number of points to reduce waves by
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, npnts, tdelta
	String wName, oldnote, outList = "", badList = wList
	String thisfxn = "DecimateWaves"
	
	if ( ( numtype( ipnts ) > 0 ) || ( ipnts < 1 )  )
		return NMErrorStr( 10, thisfxn, "ipnts", num2istr( ipnts ) )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		npnts = floor( numpnts( $wName ) / ipnts )
		tdelta = deltax( $wName )
		
		if ( npnts <= 1 )
			continue
		endif

		Interpolate2 /T=1 /N=( npnts )/Y=U_InterpY $wName
		
		oldnote = note( $wName )
		
		Duplicate /O U_InterpY, $wName
		Setscale /P x 0, ( tdelta*ipnts ), $wName
		
		Note /K $wName
		Note $wName, oldnote
		Note $wName, "Func:" + thisfxn
		Note $wName, "Decimate Pnts:" + num2istr( ipnts )
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
	endfor
	
	KillWaves /Z U_InterpY
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // DecimateWaves

//****************************************************************
//
//	Decimate2DeltaX()
//	decimate a list of waves - ie. reduce the number of points by linear interp
//
//****************************************************************

Function /S Decimate2DeltaX( newDeltaX, wList )
	Variable newDeltaX // new sample interval
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, npnts
	String wName, oldnote, outList = "", badList = wList
	String thisfxn = "Decimate2DeltaX"
	
	if ( ( numtype( newDeltaX ) > 0 ) || ( newDeltaX <= 0 ) )
		return NMErrorStr( 10, thisfxn, "newDeltaX", num2str( newDeltaX ) )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		if ( newDeltaX >= deltax( $wName ) )
			continue // nothing to do
		endif
		
		npnts = abs( ( rightx( $wName ) - leftx( $wName ) ) / newDeltaX )
		
		if ( ( numtype( npnts ) > 0 ) || ( npnts <= 0 ) )
			continue // not allowed
		endif

		Interpolate2 /T=1 /N=( npnts )/Y=U_InterpY $wName
		
		if ( WaveExists( U_InterpY ) == 1 )
		
			oldnote = note( $wName )
			
			Duplicate /O U_InterpY, $wName
			Setscale /P x 0, ( newDeltaX ), $wName
			
			Note /K $wName
			Note $wName, oldnote
			Note $wName, "Func:" + thisfxn
			Note $wName, "Decimate Pnts:" + num2istr( npnts )
		
			outList = AddListItem( wName, outList, ";", inf )
			badList = RemoveFromList( wName, badList )
		
		endif
		
	endfor
	
	KillWaves /Z U_InterpY
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // Decimate2DeltaX

//****************************************************************
//
//	InterpolateWaves()
//	x-interpolate a list of waves
//
//	Warning: interpolation will change the noise characteristics of your data.
//
//****************************************************************

Function /S InterpolateWaves( alg, xmode, xwave, wList )
	Variable alg // ( 1 ) linear ( 2 ) cubic spline
	Variable xmode	// ( 1 ) compute a common x-axis for input waves
					// ( 2 ) use x-axis scale of xwave
					// ( 3 ) use values of xwave as x-scale
	String xwave // wave to derive x-values from
	String wList // wave list ( seperator ";" )

	Variable wcnt, npnts, dx, lftx, lx, rghtx, rx, p1, p2
	String wName, oldnote, outList = "", badList = wList
	String thisfxn = "InterpolateWaves"
	
	switch( alg )
		case 1:
		case 2:
			break
		default:
			return NMErrorStr( 10, thisfxn, "alg", num2istr( alg ) )
	endswitch
	
	switch( xmode )
	
		case 1:
		
			dx = GetXstats( "deltax", wList )
			lftx = GetXstats( "minLeftx", wList )
			rghtx = GetXstats( "maxRightx", wList )
			npnts = ( rghtx-lftx )/dx
			
			if ( ( numtype( npnts ) > 0 ) || ( npnts <= 0 ) )
				return NMErrorStr( 10, thisfxn, "npnts", num2istr( npnts ) )
			endif
			
			Make /O/N=( npnts ) U_InterpX
			
			U_InterpX = lftx + x*dx
			
			break
			
		case 2:
		
			if ( NMUtilityWaveTest( xwave ) < 0 )
				NMError( 1, thisfxn, "xwave", xwave )
			endif
			
			dx = deltax( $xwave )
			lftx = leftx( $xwave )
			rghtx = rightx( $xwave )
			npnts = numpnts( $xwave )
			
			Duplicate /O $xwave U_InterpX
			
			U_InterpX = x
			
			break
			
		case 3:
		
			if ( NMUtilityWaveTest( xwave ) < 0 )
				NMError( 1, thisfxn, "xwave", xwave )
			endif
			
			Duplicate /O $xwave U_InterpX
			
			npnts = numpnts( U_InterpX )
			lftx = U_InterpX[0]
			rghtx = U_InterpX[npnts-1]
			dx = U_InterpX[1] - U_InterpX[0] // ( assuming equal intervals )
			
			break
			
		default:
			return NMErrorStr( 10, thisfxn, "xmode", num2istr( xmode ) )
			
	endswitch
	
	if ( ( numtype( npnts ) > 0 ) || ( npnts <= 0 ) )
		return NMErrorStr( 10, thisfxn, "npnts", num2istr( npnts ) )
	endif
	
	if ( ( numtype( dx ) > 0 ) || ( dx <= 0 ) )
		return NMErrorStr( 10, thisfxn, "dx", num2str( dx ) )
	endif
	
	if ( numtype( lftx ) > 0 )
		return NMErrorStr( 10, thisfxn, "lftx", num2str( lftx ) )
	endif
	
	if ( numtype( rghtx ) > 0 )
		return NMErrorStr( 10, thisfxn, "rghtx", num2str( rghtx ) )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		lx = leftx( $wName )
		rx = rightx( $wName )

		Interpolate2 /T=( alg )/I=3/Y=U_InterpY /X=U_interpX $wName
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
		oldnote = note( $wName )
		Duplicate /O U_InterpY, $wName
		
		Wave wtemp = $wName
		
		Setscale /P x lftx, dx, wtemp
		
		p1 = x2pnt( wtemp, lftx )
		p2 = x2pnt( wtemp, lx )
		
		if ( ( numtype( p1 * p2 ) == 0 ) && ( p2 > p1 ) )
			wtemp[p1, p2] = Nan
		endif
		
		p1 = x2pnt( wtemp, rx )
		p2 = x2pnt( wtemp, rghtx )
		
		if ( ( numtype( p1 * p2 ) == 0 ) && ( p2 > p1 ) )
			wtemp[p1, p2] = Nan
		endif
		
		Note /K $wName
		Note $wName, oldnote
		
		Note $wName, "Func:" + thisfxn
		
		switch( xmode )
			case 1:
				Note $wName, "Interp Leftx:" + num2str( lftx ) + ";Interp Rightx:" + num2str( rghtx ) + ";Interp dx:" + num2str( dx ) + ";"
				break
			case 2:
				Note $wName, "Interp xScale:" + xwave
				break
			case 3:
				Note $wName, "Interp xValues:" + xwave
				break
		endswitch
		
	endfor
	
	KillWaves /Z U_InterpX, U_InterpY
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // InterpolateWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNormalizeCall( df )
	String df // data folder where normalize variables are stored

	Variable win1, win2, tbgn1, tend1, tbgn2, tend2
	String fxn1, fxn2, mdf = MainDF()
	
	fxn1 = StrVarOrDefault( mdf+"Norm_Fxn1", "Avg" )
	fxn1 = StrVarOrDefault( df+"Norm_Fxn1", fxn1 )
	
	tbgn1 = NumVarOrDefault( mdf+"Bsln_Bgn", 0 ) // Main baseline window
	tend1 = NumVarOrDefault( mdf+"Bsln_End", 5 )
	
	tbgn1 = NumVarOrDefault( mdf+"Norm_Tbgn1", tbgn1 )
	tend1 = NumVarOrDefault( mdf+"Norm_Tend1", tend1 )
	
	tbgn1 = NumVarOrDefault( df+"Norm_Tbgn1", tbgn1 )
	tend1 = NumVarOrDefault( df+"Norm_Tend1", tend1 )
	
	fxn2 = StrVarOrDefault( mdf+"Norm_Fxn2", "Max" )
	fxn2 = StrVarOrDefault( df+"Norm_Fxn2", fxn2 )
	
	tbgn2 = NumVarOrDefault( mdf+"Norm_Tbgn2", -inf )
	tend2 = NumVarOrDefault( mdf+"Norm_Tend2", inf )
	
	tbgn2 = NumVarOrDefault( df+"Norm_Tbgn2", tbgn2 )
	tend2 = NumVarOrDefault( df+"Norm_Tend2", tend2 )
	
	win1 = GetNumFromStr( fxn1, "MinAvg" )
	win2 = GetNumFromStr( fxn2, "MaxAvg" )
	
	if ( ( numtype( win1 ) == 0 ) && ( win1 > 0 ) )
		fxn1 = "MinAvg"
	endif
	
	strswitch( fxn1 )
		case "Avg":
		case "Min":
		case "MinAvg":
			break
		default:
			fxn1 = "Avg"
	endswitch
	
	if ( numtype( tbgn1 ) > 0 )
		tbgn1 = -inf
	endif
	
	if ( numtype( tend1 ) > 0 )
		tend2 = inf
	endif
	
	if ( ( numtype( win2 ) == 0 ) && ( win2 > 0 ) )
		fxn2 = "MaxAvg"
	endif
	
	strswitch( fxn2 )
		case "Avg":
		case "Max":
		case "MaxAvg":
			break
		default:
			fxn2 = "Max"
	endswitch
	
	if ( numtype( tbgn2 ) > 0 )
		tbgn2 = -inf
	endif
	
	if ( numtype( tend2 ) > 0 )
		tend2 = -inf
	endif
	
	Prompt fxn1, "algorithm to compute y-minimum:", popup "Avg;Min;MinAvg;"
	Prompt tbgn1, "time begin (ms):"
	Prompt tend1, "time end (ms):"
	
	DoPrompt NMPromptStr( "Normalize Minimum Computation" ), fxn1, tbgn1, tend1
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( fxn1, "MinAvg" ) == 1 )
	
		if ( numtype( win1 ) > 0 )
			win1 = 1
		endif
		
		Prompt win1, "window to average around detected min value (ms):"
		DoPrompt "Normalize MinAvg Computation", win1
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		if ( ( numtype( win1 ) > 0 ) || ( win1 <= 0 ) )
			return -1 // cancel
		endif
		
		fxn1 += num2str( win1 )
		
	endif
	
	SetNMstr( df+"Norm_Fxn1", fxn1 )
	SetNMvar( df+"Norm_Tbgn1", tbgn1 )
	SetNMvar( df+"Norm_Tend1", tend1 )
	
	SetNMstr( mdf+"Norm_Fxn1", fxn1 )
	SetNMvar( mdf+"Norm_Tbgn1", tbgn1 )
	SetNMvar( mdf+"Norm_Tend1", tend1 )
	
	Prompt fxn2, "algorithm to compute y-maximum:", popup "Avg;Max;MaxAvg;"
	Prompt tbgn2, "time begin (ms):"
	Prompt tend2, "time end (ms):"
	
	DoPrompt NMPromptStr( "Normalize Maximum Computation" ), fxn2, tbgn2, tend2
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( fxn2, "MaxAvg" ) == 1 )
	
		if ( numtype( win2 ) > 0 )
			win1 = 2
		endif
		
		Prompt win2, "window to average around detected max value (ms):"
		DoPrompt "Normalize MaxAvg Computation", win2
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		if ( ( numtype( win2 ) > 0 ) || ( win2 <= 0 ) )
			return -1 // cancel
		endif
		
		fxn2 += num2str( win2 )
		
	endif
	
	SetNMstr( df+"Norm_Fxn2", fxn2 )
	SetNMvar( df+"Norm_Tbgn2", tbgn2 )
	SetNMvar( df+"Norm_Tend2", tend2 )
	
	SetNMstr( mdf+"Norm_Fxn2", fxn2 )
	SetNMvar( mdf+"Norm_Tbgn2", tbgn2 )
	SetNMvar( mdf+"Norm_Tend2", tend2 )
	
	return 0
	
End // NMNormalizeCall

//****************************************************************
//
//	NormalizeWaves()
//
//****************************************************************

Function /S NormalizeWaves( fxn1, tbgn1, tend1, fxn2, tbgn2, tend2, wList )
	String fxn1 // function to compute min value, "Avg" or "Min" or "minavg"
	Variable tbgn1, tend1 // window to compute fxn1, use ( -inf, inf ) for all time
	String fxn2 // function to compute max value, "Avg" or "Max" or "maxavg"
	Variable tbgn2, tend2 // window to compute fxn2, use ( -inf, inf ) for all time
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, amp1, amp2, lftx, dx, scaleNum, t1, t2, items = ItemsInList( wList )
	String wName, saveNote, outList = "", badList = wList
	String thisfxn = "NormalizeWaves"
	
	Variable win1 = GetNumFromStr( fxn1, "MinAvg" )
	Variable win2 = GetNumFromStr( fxn2, "MaxAvg" )
	
	if ( numtype( win1 ) == 0 )
		fxn1 = "MinAvg"
	endif
	
	strswitch( fxn1 )
		case "Avg":
		case "Min":
		case "MinAvg":
			break
		default:
			if ( numtype( win1 ) > 0 )
				return NMErrorStr( 20, thisfxn, "fxn1", fxn1 )
			endif
	endswitch
	
	if ( numtype( tbgn1 ) == 2 )
		return NMErrorStr( 10, thisfxn, "tbgn1", num2str( tbgn1 ) )
	endif
	
	if ( numtype( tend1 ) ==  2 )
		return NMErrorStr( 10, thisfxn, "tend1", num2str( tend1 ) )
	endif
	
	if ( numtype( win2 ) == 0 )
		fxn2 = "MaxAvg"
	endif
	
	strswitch( fxn2 )
		case "Avg":
		case "Max":
		case "MaxAvg":
			break
		default:
			if ( numtype( win2 ) > 0 )
				return NMErrorStr( 20, thisfxn, "fxn2", fxn2 )
			endif
	endswitch
	
	if ( numtype( tbgn2 ) == 2 )
		return NMErrorStr( 10, thisfxn, "tbgn2", num2str( tbgn2 ) )
	endif
	
	if ( numtype( tend2 ) ==  2 )
		return NMErrorStr( 10, thisfxn, "tend2", num2str( tend2 ) )
	endif
	
	if ( items == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Wave wtemp = $wName
		
		lftx = leftx( wtemp )
		dx = deltax( wtemp )
		saveNote = note( wtemp )
		
		amp1 = Nan
		amp2 = Nan
		
		strswitch( fxn1 )
		
			case "Avg":
				amp1 = mean( wtemp, tbgn1, tend1 )
				break
				
			case "Min":
				amp1 = WaveMin( wtemp, tbgn1, tend1 )
				break
				
			case "MinAvg":
			
				WaveStats /Q/R=(tbgn1, tend1) wtemp
				
				if ( numtype( V_minloc ) == 0 )
				
					t1 = V_minloc - win1 / 2
					t2 = V_minloc + win1 / 2
					
					WaveStats /Q/R=( t1, t2 ) wtemp
					
					amp1 = V_avg
					
				endif
				
				break
				
		endswitch
		
		if ( numtype( amp1 ) > 0 )
			NMHistory( thisfxn + " encountered bad amp1 value, skipped wave: " + wName )
			continue
		endif
		
		strswitch( fxn2 )
		
			case "Avg":
				amp2 = mean( wtemp, tbgn2, tend2 )
				break
				
			case "Max":
				amp2 = WaveMax( wtemp, tbgn2, tend2 )
				break
				
			case "MaxAvg":
			
				WaveStats /Q/R=(tbgn2, tend2) wtemp
				
				if ( numtype( V_maxloc ) == 0 )
				
					t1 = V_maxloc - win2 / 2
					t2 = V_maxloc + win2 / 2
					
					WaveStats /Q/R=( t1, t2 ) wtemp
					
					amp2 = V_avg
					
				endif
				
				break
				
		endswitch
		
		if ( numtype( amp2 ) > 0 )
			NMHistory( thisfxn + " encountered bad amp2 value, skipped wave: " + wName )
			continue
		endif
		
		scaleNum = 1 / ( amp2 - amp1 )
		
		if ( ( scaleNum == 0 ) || ( numtype( scaleNum ) > 0 ) )
			NMHistory( thisfxn + " encountered bad scaleNum value, skipped wave: " + wName )
			continue
		else
			MatrixOp /O wtemp = scaleNum * ( wtemp - amp1 )
			Setscale /P x lftx, dx, wtemp
		endif
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
		Note wtemp, saveNote
		Note wtemp, "Func:" + thisfxn
		Note wtemp, "Norm Fxn1:" + fxn1 + ";Norm Tbgn1:" + num2str( tbgn1 ) + ";Norm Tend1:" + num2str( tend1 )
		Note wtemp, "Norm Fxn2:" + fxn2 + ";Norm Tbgn2:" + num2str( tbgn2 ) + ";Norm Tend2:" + num2str( tend2 )
	
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // NormalizeWaves

//****************************************************************
//
//	BlankWaves()
//	blank waves using a wave of event times
//
//****************************************************************

Function /S BlankWaves( waveOfBlankTimes, beforeTime, afterTime, blankValue, wList )
	String waveOfBlankTimes // wave of event/blank times
	Variable beforeTime // blank time before event
	Variable afterTime // blank time after event
	Variable blankValue // blank value ( try Nan )
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, icnt, t, tbgn, tend, pbgn, pend, nwaves = ItemsInList( wList )
	String wName, outList = "", badList = wList, thisfxn = "BlankWaves"
	
	if ( NMUtilityWaveTest( waveOfBlankTimes ) < 0 )
		return NMErrorStr( 1, thisfxn, "waveOfBlankTimes", waveOfBlankTimes )
	endif
	
	if ( numtype( beforeTime ) > 0 )
		return NMErrorStr( 10, thisfxn, "beforeTime", num2str( beforeTime ) )
	endif
	
	if ( numtype( afterTime ) > 0 )
		return NMErrorStr( 10, thisfxn, "afterTime", num2str( afterTime ) )
	endif
	
	if ( nwaves == 0 )
		return ""
	endif
	
	Wave events = $waveOfBlankTimes
	
	for ( wcnt = 0; wcnt < nwaves; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Wave wtemp = $wName
		
		for ( icnt = 0; icnt < numpnts( events ); icnt += 1 )
		
			t = events[icnt]
			
			if ( numtype( t ) > 0 )
				continue
			endif	
			
			tbgn = t - abs( beforeTime )
			tend = t + abs( afterTime )
			
			if ( tbgn < leftx( wtemp ) )
				tbgn = leftx( wtemp )
			endif
			
			if ( tend > rightx( wtemp ) )
				tend = rightx( wtemp )
			endif
			
			pbgn = x2pnt( wtemp, tbgn )
			pend = x2pnt( wtemp, tend )
			
			wtemp[pbgn, pend] = blankValue
			
		endfor
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
		Note wtemp, "Func:" + thisfxn
		Note wtemp, "Blank Event Times:" + waveOfBlankTimes + ";Blank Before:" + num2str( beforeTime ) + ";Blank After:" + num2str( afterTime ) + ";"
	
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // BlankWaves

//****************************************************************
//
//	DFOFWaves()
//	compute DF/Fo
//
//****************************************************************

Function /S DFOFWaves( bbgn, bend, wList )
	Variable bbgn, bend // baseline window begin / end time, use ( -inf, inf ) for all time
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, value, amp, base, scale = 1, lftx, dx, items = ItemsInList( wList )
	String wName, saveNote, outList = "", badList = wList
	String thisfxn = "DFOFWaves"
	
	if ( numtype( bbgn ) == 2 )
		return NMErrorStr( 10, thisfxn, "bbgn", num2str( bbgn ) )
	endif
	
	if ( numtype( bend ) ==  2 )
		return NMErrorStr( 10, thisfxn, "bend", num2str( bend ) )
	endif
	
	if ( items == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Wave wtemp = $wName
		
		base = mean( wtemp, bbgn, bend )
		
		lftx = leftx( wtemp )
		dx = deltax( wtemp )
		saveNote = note( wtemp )
		
		if ( numtype( base ) > 0 )
			NMHistory( "dF/Fo baseline computation error, skipped wave:" + wName )
			continue
		else
			MatrixOp /O wtemp = ( wtemp - base ) / base
			Setscale /P x lftx, dx, wtemp
		endif
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
		Note wtemp, saveNote
		Note wtemp, "Func:" + thisfxn
		Note wtemp, "dFoF Bsln Value:" + num2str( base ) + ";dFoF BaseBgn:" + num2str( bbgn ) + ";dFoF BaseEnd:" + num2str( bend ) + ";"
	
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // DFOFWaves

//****************************************************************
//
//	ReverseWaves()
//
//****************************************************************

Function /S ReverseWaves( wList )
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, icnt, npnts, items = ItemsInList( wList )
	String wName, outList = "", badList = wList
	String thisfxn = "ReverseWaves"
	
	if ( items == 0 )
		return ""
	endif
	
	items = ItemsInList( wList )
	
	for ( wcnt = 0; wcnt < items; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		WaveTransform /O flip $wName
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
		Note inWave, "Func:" + thisfxn
		
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // ReverseWaves

//****************************************************************
//
//	SortWavesByKeyWave
//
//****************************************************************

Function /S SortWavesByKeyWave( keyWaveName, wList )
	String keyWavename
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, npnts
	String wName, outList = "", badList = wList
	String thisfxn = "SortWavesByKeyWave"
	
	if ( WaveExists( $keyWaveName ) == 0 )
		return NMErrorStr( 1, thisfxn, "keyWaveName", keyWaveName )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	npnts = numpnts( $keyWaveName )
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		if ( numpnts( $keyWavename ) != numpnts( $wName ) )
			continue
		endif
		
		if ( StringMatch( keyWavename, wName ) == 1 )
		
			DoAlert 1, "Warning: you are about to sort wave " + NMQuotes( wName ) + " with itself. Do you want to continue?"
			
			if ( V_flag != 1 )
				continue
			endif
			
		endif
	
		Sort $keyWavename, $wName
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
		Note $wName, "Func:" + thisfxn
		Note $wName, "SortKeyWave:" + keyWaveName
		
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // SortWavesByKeyWave

//****************************************************************
//
//	AlignByNum()
//	align x-zero point of a list of waves at a single offset value
//
//****************************************************************

Function AlignByNum( setZeroAt, wList )
	Variable setZeroAt // wave leftx value
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, dx
	String wName, badList = wList, thisfxn = "AlignByNum"
	
	if ( numtype( setZeroAt ) > 0 )
		return NMError( 10, thisfxn, "setZeroAt", num2str( setZeroAt ) )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		dx = deltax( $wName )
	
		Setscale /P x -setZeroAt, dx, $wName
		
		badList = RemoveFromList( wName, badList )
	
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return 0

End // AlignByNum

//****************************************************************
//
//	NMReplaceValue
//
//****************************************************************

Function /S NMReplaceValue( findVal, replacementVal, wList )
	Variable findVal // wave value to find
	Variable replacementVal // replacement value
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, lftx, dx
	String wName, saveNote, outList = "", badList = wList
	String thisfxn = "NMReplaceValue"
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Wave wtemp = $wName
		
		lftx = leftx( wtemp )
		dx = deltax ( wtemp )
		saveNote = note( wtemp )
		
		MatrixOp /O wtemp = Replace(wtemp, findVal, replacementVal)
		
		Setscale /P x lftx, dx, wtemp
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
		Note wtemp, saveNote
		Note wtemp, "Func:" + thisfxn
		Note wtemp, "Replace FindValue:" + num2str( findVal )+ ";Replace ReplacementVal:" + num2str( replacementVal )
		
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList
	
End // NMReplaceValue

//****************************************************************
//
//	NMScaleWaves()
//	scale a list of waves ( x, /, +, - ) by a single number
//
//****************************************************************

Function /S NMScaleWaves( alg, scaleValue, tbgn, tend, wList )
	String alg // arhithmatic symbol ( x, /, +, - )
	Variable scaleValue // scale value
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, lftx, dx, pbgn, pend, pntbypnt = 1
	String wName, saveNote, outList = "", badList = wList
	String thisfxn = "NMScaleWaves"
	
	if ( strsearch( "x*/+-", alg, 0 ) == -1 )
		return NMErrorStr( 20, thisfxn, "alg", alg )
	endif
	
	if ( numtype( scaleValue ) == 1 )
		return NMErrorStr( 10, thisfxn, "scaleValue", num2str( scaleValue ) ) // inf not allowed
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	if ( ( numtype( tbgn ) == 1 ) && ( numtype( tend ) ==  1 ) )
		pntbypnt = 0
	endif
	
	if ( StringMatch( alg, "/" ) == 1 )
	
		if ( scaleValue == 0 )
			return NMErrorStr( 90, thisfxn, "cannot divide by zero", "" )
		endif
		
		scaleValue = 1 / scaleValue
		alg = "x" // FASTER
		
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Wave wtemp = $wName
		
		lftx = leftx( wtemp )
		dx = deltax ( wtemp )
		saveNote = note( wtemp )
		
		if ( pntbypnt == 0 )
		
			strswitch( alg )
				case "*":
				case "x":
					MatrixOp /O wtemp = wtemp * scaleValue
					break
				case "/":
					MatrixOp /O wtemp = wtemp / scaleValue
					break
				case "+":
					MatrixOp /O wtemp = wtemp + scaleValue
					break
				case "-":
					MatrixOp /O wtemp = wtemp - scaleValue
					break
				default:
					return NMErrorStr( 20, thisfxn, "alg", alg )
			endswitch
			
			Setscale /P x lftx, dx, wtemp
			
			Note wtemp, saveNote
		
		else
		
			if ( numtype( tbgn ) == 1 )
				pbgn = 0
			else
				pbgn = x2pnt( $wName, tbgn )
			endif
			
			if ( numtype( tend ) == 1 )
				pend = numpnts( $wName ) - 1
			else
				pend = x2pnt( $wName, tend )
			endif
			
			if ( ( pbgn < 0 ) || ( pend >= numpnts( $wName ) ) )
				continue
			endif
				
			strswitch( alg )
				case "*":
				case "x":
					wtemp[pbgn, pend] *= scaleValue
					break
				case "/":
					wtemp[pbgn, pend] /= scaleValue
					break
				case "+":
					wtemp[pbgn, pend] += scaleValue
					break
				case "-":
					wtemp[pbgn, pend] -= scaleValue
					break
				default:
					return NMErrorStr( 20, thisfxn, "alg", alg )
			endswitch
			
		endif
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
		Note $wName, "Func:" + thisfxn
		Note $wName, "Scale Alg:" + alg + ";Scale Value:" + num2str( scaleValue ) + ";Scale Tbgn:" + num2str( tbgn ) + ";Scale Tend:" + num2str( tend )
		
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // NMScaleWaves

//****************************************************************
//
//	ScaleByWave()
//	scale a list of waves ( x, /, +, - ) by another wave of equal points
//
//****************************************************************

Function /S ScaleByWave( alg, scaleWave, wList ) // all input waves should have same number of points
	String alg // arhithmatic symbol ( x, /, +, - )
	String scaleWave // wave to scale by
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, npnts, lftx, dx
	String wName, saveNote, outList = "", badList = wList
	String thisfxn = "ScaleByWave"

	if ( strsearch( "x*/+-", alg, 0 ) == -1 )
		return NMErrorStr( 20, thisfxn, "alg", alg )
	endif
	
	if ( NMUtilityWaveTest( scaleWave ) < 0 )
		return NMErrorStr( 1, thisfxn, "scaleWave", scaleWave )
	endif
	
	npnts = GetXstats( "numpnts", wList )
	
	if ( npnts != numpnts( $scaleWave ) )
		return NMErrorStr( 90, thisfxn, "dimensions of scaleWave does not match that of those in your input wave list", "" )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Wave wtemp = $wName
		Wave stemp = $scaleWave
		
		lftx = leftx( wtemp )
		dx = deltax( wtemp )
		saveNote = note( wtemp )
		
		strswitch( alg )
			case "*":
			case "x":
				MatrixOp /O wtemp = wtemp * stemp
				break
			case "/":
				MatrixOp /O wtemp = wtemp / stemp
				break
			case "+":
				MatrixOp /O wtemp = wtemp + stemp
				break
			case "-":
				MatrixOp /O wtemp = wtemp - stemp
				break
			default:
				return NMErrorStr( 20, thisfxn, "alg", alg )
		endswitch
		
		Setscale /P x lftx, dx, wtemp
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
		Note wtemp, saveNote
		Note $wName, "Func:" + thisfxn
		Note $wName, "Scale Alg:" + alg + ";Scale Wave:" + scaleWave + ";"
		
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // ScaleByWave

//****************************************************************
//
//	SetXScale()
//	set the x-scaling of a list of waves
//
//****************************************************************

Function /S SetXScale( lftx, dx, npnts, wList )
	Variable lftx // time of first x-point, pass ( Nan ) to not change
	Variable dx // time step value, pass ( Nan ) to not change
	Variable npnts // number of points, pass ( Nan ) to not change
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, somethingtodo, t_lftx, t_dx
	String wName, outList = "", badList = wList
	String thisfxn = "SetXScale"
	
	if ( numtype( lftx ) == 0 )
		somethingtodo = 1
	endif
	
	if ( dx == -1 )
		dx = Nan
	endif
	
	if ( numtype( dx ) == 0 )
	
		somethingtodo = 1
		
		if ( dx <= 0 )
			return NMErrorStr( 10, thisfxn, "dx", num2str( dx ) )
		endif
		
	endif
	
	if ( npnts == -1 )
		npnts = Nan
	endif
	
	if ( numtype( npnts ) == 0 )
	
		somethingtodo = 1
		
		if ( npnts <= 0 )
			return NMErrorStr( 10, thisfxn, "npnts", num2istr( npnts ) )
		endif
		
	endif
	
	if ( somethingtodo == 0 )
		return ""
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		if ( ( numtype( npnts ) == 0 ) && ( npnts > 0 ) && ( npnts != numpnts( $wName ) ) )
			CheckNMwave( wName, npnts, Nan ) // Redimension
		endif
		
		if ( numtype( lftx ) == 0 )
			t_lftx = lftx
		else
			t_lftx = leftx( $wName )
		endif
		
		if ( ( numtype( dx ) == 0 ) && ( dx > 0 ) )
			t_dx = dx
		else
			t_dx = deltax( $wName )
		endif
		
		Setscale /P x t_lftx, t_dx, $wName
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
		
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList
	
End // SetXScale

//****************************************************************
//
//	BaselineWaves()
//	subtract mean baseline value from a list of waves
//
//****************************************************************

Function /S BaselineWaves( method, tbgn, tend, wList )
	Variable method // ( 1 ) subtract wave's individual mean, ( 2 ) subtract mean of all waves
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, mn, sd, cnt, lftx, dx
	String wName, saveNote, mnsd, outList = "", badList = wList
	String thisfxn = "BaselineWaves"
	
	//String wPrefix = "MN_Bsln_" + NMWaveSelectStr()
	//String outName = NextWaveName( wPrefix, CurrentNMChan(), 1 )
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	switch( method )
	
		case 1:
			break
			
		case 2: // subtract mean of all waves
	
			mnsd = MeanStdv( tbgn, tend, wList ) // compute mean and stdv of waves
			
			mn = str2num( StringByKey( "mean", mnsd, "=" ) )
			sd = str2num( StringByKey( "stdv", mnsd, "=" ) )
			cnt = str2num( StringByKey( "count", mnsd, "=" ) )
		 
			DoAlert 1, "Baseline mean = " + num2str( mn ) + " ± " + num2str( sd ) + ".  Subtract mean from selected waves?"
		
			if ( V_Flag != 1 )
				return "" // cancel
			endif
			
			break
		
		default:
			return NMErrorStr( 10, thisfxn, "method", num2istr( method ) )
	
	endswitch
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
	
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
	
		Wave wtemp = $wName
		
		lftx = leftx( wtemp )
		dx = deltax( wtemp )
		saveNote = note( wtemp )
		
		if ( method == 1 )
			mn = mean( wtemp, tbgn, tend )
		endif
		
		MatrixOp /O wtemp = wtemp - mn
		Setscale /P x lftx, dx, wtemp
		
		Note wtemp, saveNote
		Note wtemp, "Func:" + thisfxn
		Note wtemp, "Bsln Value:" + num2str( mn ) + ";Bsln Tbgn:" + num2str( tbgn ) + ";Bsln Tend:" + num2str( tend ) + ";"
		
		outList = AddListItem( wName, outList, ";", inf )
		badList = RemoveFromList( wName, badList )
	
	endfor
	
	NMUtilityAlert( thisfxn, badList )
	
	return outList

End // BaselineWaves

//****************************************************************
//
//	NMWavesStatistics
//	compute avg, stdv, sum, sumsqr, npnts of a list of waves
//	also can create a 2D matrix wave from the input wave list
//
//    Output waves: U_Avg, U_Sdv, U_Pnts, U_Sum, U_SumSqr
//    Optional output wave: U_2Dmatrix
//
//****************************************************************

Function /S NMWavesStatistics( wList, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix )
	String wList // wave list ( seperator ";" )
	Variable useChannelTransforms // pass channel number to use its Transform and smoothing/filtering settings, or (-1) for none 
	Variable ignoreNANs // ignore NANs in computation ( 0 ) no ( 1 ) yes
	Variable truncateToCommonTimeScale // ( 0 ) no, if necessary, waves are expanded to fit all min and max times ( 1 ) yes, waves are truncated to a common time base 
	Variable interpToSameTimeScale // interpolate waves to the same x-scale (0) no (1) yes ( generally one should use interp ONLY if waves have different sample intervals )
	Variable saveMatrix // save list of waves as a 2D matrix called U_2Dmatrix ( 0 ) no ( 1 ) yes
	
	Variable minNumOfDataPoints = NumVarOrDefault("U_minNumOfDataPoints", 2) // min number of data points to include in average

	Variable wcnt, icnt, p1, p2, ipnts, imax, val, error, nwaves = ItemsInList( wList )
	String xl, yl, txt, wName, tName, oList, thisfxn = "NMWavesStatistics"
	
	String waveprefix = CurrentNMWavePrefix()
	
	Variable nchan = NMNumChannels()
	
	Variable npnts = GetXstats( "numpnts", wList )
	Variable dx = GetXstats( "deltax", wList )
	Variable mindx = GetXstats( "minDeltax", wList )
	
	Variable lftx = GetXstats( "leftx", wList )
	Variable minLeftx = GetXstats( "minLeftx", wList )
	Variable maxLeftx = GetXstats( "maxLeftx", wList )
	
	Variable rghtx = GetXstats( "rightx", wList )
	Variable minRightx = GetXstats( "minRightx", wList )
	Variable maxRightx = GetXstats( "maxRightx", wList )
	
	if ( nwaves < 2 )
		return NMErrorStr( 90, thisfxn, "number of input waves is less than 2", "" )
	endif
	
	if ( WavesExist( wList ) == 0 )
		return NMErrorStr( 90, thisfxn, "one or more input waves do not exist", "" )
	endif
	
	if ( ( numtype( dx ) != 0 ) && ( interpToSameTimeScale != 1 ) )
		return NMErrorStr( 90, thisfxn, "waves do not have the same sample interval. Use interpToSameTimeScale=1 instead.", "" )
	endif
	
	if ( ( truncateToCommonTimeScale == 1 ) && ( maxLeftx >= minRightx) )
		return NMErrorStr( 90, thisfxn, "waves have no common time base for AND computation.", "" )
	endif
	
	if ( ( truncateToCommonTimeScale == 0 ) && ( minLeftx >= maxRightx) )
		return NMErrorStr( 90, thisfxn, "waves have no common time base for OR computation", "" )
	endif
	
	Make /O/N=1 U_WaveTemp1, U_WaveTemp2, U_WaveTemp3
	
	if ( ( numtype( lftx ) == 0 ) && ( numtype( npnts ) ==  0 ) && ( numtype( dx ) ==  0 ) )
	
		Make /O/N=( npnts ) U_Sum = 0
		Make /O/N=( npnts ) U_SumSqr = 0
		Make /O/N=( npnts ) U_Pnts = 0
	
		for ( wcnt = 0 ; wcnt < nwaves; wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			if ( wcnt == 0 )
				tName = "U_WaveTemp1"
			else
				tName = "U_WaveTemp2"
			endif
			
			if ( ( useChannelTransforms >= 0 ) && ( useChannelTransforms < nchan ) )
				ChanWaveMake( useChannelTransforms, wName, tName ) 
			else
				Duplicate /O $wName $tName
			endif
			
			Wave wtemp = $tName
			
			MatrixOp /O U_PntsTemp = replace(wtemp, 0, 1) // to avoid 0/0 division
			MatrixOp /O U_PntsTemp = U_PntsTemp/U_PntsTemp
			
			if ( ignoreNANs == 1 )
				MatrixOp /O U_Sum = U_Sum + replaceNaNs(wtemp, 0)
				MatrixOp /O U_SumSqr = U_SumSqr + replaceNaNs(powR(wtemp, 2), 0)
				MatrixOp /O U_Pnts = U_Pnts + replaceNaNs(U_PntsTemp, 0)
			else
				MatrixOp /O U_Sum = U_Sum + wtemp
				MatrixOp /O U_SumSqr = U_SumSqr + powR(wtemp, 2)
				MatrixOp /O U_Pnts = U_Pnts + U_PntsTemp
			endif
			
			if ( ( saveMatrix == 1 ) && ( wcnt > 0 ) )
			
				if ( DimSize( U_WaveTemp1, 0 ) != numpnts( U_WaveTemp2 ) )
					error = 1
					break // something went wrong creating matrix
				endif
			
				Concatenate /O { U_WaveTemp1, U_WaveTemp2 }, U_2Dmatrix
			
				Duplicate /O U_2Dmatrix U_WaveTemp1
			
			endif
			
		endfor
		
	elseif ( interpToSameTimeScale == 1 )
	
		if ( truncateToCommonTimeScale == 1 ) // contract
		
			npnts = floor( ( minRightx - maxLeftx ) / mindx )
			
			Make /O/N=( npnts ) U_wScaleX = Nan // create new time base for interpolation
			Setscale /P x maxLeftx, mindx, U_wScaleX
			
		else //  expand
		
			npnts = floor( ( maxRightx - minLeftx ) / mindx )
			
			Make /O/N=( npnts ) U_wScaleX = Nan // create new time base for interpolation
			Setscale /P x minLeftx, mindx, U_wScaleX
			
		endif
		
		Make /O/N=( npnts ) U_Sum = 0
		Make /O/N=( npnts ) U_SumSqr = 0
		Make /O/N=( npnts ) U_Pnts = 0
		
		lftx = leftx(U_wScaleX)
		dx = mindx
		
		for ( wcnt = 0 ; wcnt < nwaves; wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			if ( wcnt == 0 )
				tName = "U_WaveTemp1"
			else
				tName = "U_WaveTemp2"
			endif
			
			if ( ( useChannelTransforms >= 0 ) && ( useChannelTransforms < nchan ) )
				ChanWaveMake( useChannelTransforms, wName, tName ) 
			else
				Duplicate /O $wName $tName
			endif
		
			InterpolateWaves( 2, 2, "U_wScaleX", tName )
			
			Wave wtemp = $tName
			
			MatrixOp /O U_PntsTemp = replace(wtemp, 0, 1) // to avoid 0/0 division
			MatrixOp /O U_PntsTemp = U_PntsTemp/U_PntsTemp
			
			if ( ignoreNANs == 1 )
				MatrixOp /O U_Sum = U_Sum + replaceNaNs(wtemp, 0)
				MatrixOp /O U_SumSqr = U_SumSqr + replaceNaNs(powR(wtemp, 2), 0)
				MatrixOp /O U_Pnts = U_Pnts + replaceNaNs(U_PntsTemp, 0)
			else
				MatrixOp /O U_Sum = U_Sum + wtemp
				MatrixOp /O U_SumSqr = U_SumSqr + powR(wtemp, 2)
				MatrixOp /O U_Pnts = U_Pnts + U_PntsTemp
			endif
			
			if ( ( saveMatrix == 1 ) && ( wcnt > 0 ) )
			
				if ( DimSize( U_WaveTemp1, 0 ) != numpnts( U_WaveTemp2 ) )
					error = 1
					break // something went wrong creating matrix
				endif
			
				Concatenate /O { U_WaveTemp1, U_WaveTemp2 }, U_2Dmatrix
			
				Duplicate /O U_2Dmatrix U_WaveTemp1
			
			endif
	
		endfor
		
	elseif ( truncateToCommonTimeScale == 1 ) // AND waves (trim loose ends)
		
		npnts = floor( ( minRightx - maxLeftx ) / dx )
		
		lftx = maxLeftx
		
		Make /O/N=( npnts ) U_Sum = 0
		Make /O/N=( npnts ) U_SumSqr = 0
		Make /O/N=( npnts ) U_Pnts = 0
	
		for ( wcnt = 0 ; wcnt < nwaves; wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
		
			if ( wcnt == 0 )
				tName = "U_WaveTemp1"
			else
				tName = "U_WaveTemp2"
			endif
			
			p1 = x2pnt( $wName, maxLeftx )
			p2 = p1 + npnts - 1
			
			if ( ( useChannelTransforms >= 0 ) && ( useChannelTransforms < nchan ) )
				ChanWaveMake( useChannelTransforms, wName, "U_WaveTemp3" )
				Duplicate /O/R=[p1, p2] U_WaveTemp3 $tName
			else
				Duplicate /O/R=[p1, p2] $wName $tName
			endif
			
			Wave wtemp = $tName
			
			MatrixOp /O U_PntsTemp = replace(wtemp, 0, 1) // to avoid 0/0 division
			MatrixOp /O U_PntsTemp = U_PntsTemp/U_PntsTemp
			
			if ( ignoreNANs == 1 )
				MatrixOp /O U_Sum = U_Sum + replaceNaNs(wtemp, 0)
				MatrixOp /O U_SumSqr = U_SumSqr + replaceNaNs(powR(wtemp, 2), 0)
				MatrixOp /O U_Pnts = U_Pnts + replaceNaNs(U_PntsTemp, 0)
			else
				MatrixOp /O U_Sum = U_Sum + wtemp
				MatrixOp /O U_SumSqr = U_SumSqr + powR(wtemp, 2)
				MatrixOp /O U_Pnts = U_Pnts + U_PntsTemp
			endif
			
			if ( ( saveMatrix == 1 ) && ( wcnt > 0 ) )
			
				if ( DimSize( U_WaveTemp1, 0 ) != numpnts( U_WaveTemp2 ) )
					error = 1
					break // something went wrong creating matrix
				endif
				
				Concatenate /O { U_WaveTemp1, U_WaveTemp2 }, U_2Dmatrix
			
				Duplicate /O U_2Dmatrix U_WaveTemp1
			
			endif
		
		endfor
		
	else // OR waves (pad loose ends)
	
		npnts = 1 + floor( ( maxRightx - minLeftx ) / dx )
		
		lftx = minLeftx
		
		Make /O/N=( npnts ) U_Sum = 0
		Make /O/N=( npnts ) U_SumSqr = 0
		Make /O/N=( npnts ) U_Pnts = 0
		
		for ( wcnt = 0 ; wcnt < nwaves; wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			val = x2pnt( $wName, maxLeftx )
			
			if ( val > imax )
				imax = val
			endif
		
		endfor
		
		for ( wcnt = 0 ; wcnt < nwaves; wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			val = x2pnt( $wName, maxLeftx )
			
			ipnts = round( ( leftx($wName) - minLeftx ) / dx )
			
			ipnts = imax - val
			
			if ( wcnt == 0 )
				tName = "U_WaveTemp1"
			else
				tName = "U_WaveTemp2"
			endif
			
			if ( ( useChannelTransforms >= 0 ) && ( useChannelTransforms < nchan ) )
				ChanWaveMake( useChannelTransforms, wName, tName ) 
			else
				Duplicate /O $wName $tName
			endif
			
			Duplicate /O $wName, U_wIdentity
		
			U_wIdentity = 1
			
			Wave wtemp = $tName
			
			Redimension /N=( npnts ) wtemp, U_wIdentity // this inserts 0's at end of wave
			
			MatrixOp /O wtemp=wtemp/U_wIdentity // convert new 0's to NAN's
			
			if ( ipnts > 0)
				WaveTransform /O/P={ipnts, Nan} shift wtemp // shift points to align
			endif
			
			MatrixOp /O U_PntsTemp = replace(wtemp, 0, 1) // to avoid 0/0 division
			MatrixOp /O U_PntsTemp = U_PntsTemp/U_PntsTemp
			
			if ( ignoreNANs == 1 )
				MatrixOp /O U_Sum = U_Sum + replaceNaNs(wtemp, 0)
				MatrixOp /O U_SumSqr = U_SumSqr + replaceNaNs(powR(wtemp, 2), 0)
				MatrixOp /O U_Pnts = U_Pnts + replaceNaNs(U_PntsTemp, 0)
			else
				MatrixOp /O U_Sum = U_Sum + wtemp
				MatrixOp /O U_SumSqr = U_SumSqr + powR(wtemp, 2)
				MatrixOp /O U_Pnts = U_Pnts + U_PntsTemp
			endif
			
			if ( ( saveMatrix == 1 ) && ( wcnt > 0 ) )
			
				if ( DimSize( U_WaveTemp1, 0 ) != numpnts( U_WaveTemp2 ) )
					error = 1
					break // something went wrong creating matrix
				endif
			
				Concatenate /O { U_WaveTemp1, U_WaveTemp2 }, U_2Dmatrix
			
				Duplicate /O U_2Dmatrix U_WaveTemp1
			
			endif
			
			
		endfor
		
	endif
	
	MatrixOp /O U_Pnts2 = U_Pnts * greater( U_Pnts, minNumOfDataPoints - 1 ) // reject rows with not enough data points
	MatrixOp /O U_Pnts2 = U_Pnts2 * ( U_Pnts2 / U_Pnts2 ) // converts 0's to NAN's
	
	MatrixOp /O U_Avg = U_Sum / U_Pnts2
	MatrixOp /O U_Sdv = sqrt( ( U_SumSqr - ( ( powR( U_Sum, 2 ) ) / U_Pnts2 ) ) / ( U_Pnts2 - 1 ) )
	
	if ( WaveExists( U_2Dmatrix ) == 1 )
		Setscale /P x lftx, dx, U_2Dmatrix
	endif
	
	Setscale /P x lftx, dx, U_Avg, U_Sdv, U_Sum, U_SumSqr, U_Pnts
	
	if ( error == 1 )
		KillWaves /Z U_Avg, U_Sdv, U_Sum, U_SumSqr, U_Pnts, U_2Dmatrix
	endif
	
	if ( ( saveMatrix == 1) && ( DimSize( U_2Dmatrix, 1 ) != nwaves ) )
		KillWaves /Z U_2Dmatrix
		return NMErrorStr( 90, thisfxn, "error in creating 2D matrix : wrong dimensions", "" )
	endif
	
	xl = NMNoteLabel( "x", wList, "" )
	yl = NMNoteLabel( "y", wList, "" )
	
	NMNoteType( "U_Avg", "NMAvg", xl, yl, "Func:" + thisfxn )
	NMNoteType( "U_Sdv", "NMSdv", xl, yl, "Func:" + thisfxn )
	NMNoteType( "U_Sum", "NMSum", xl, yl, "Func:" + thisfxn )
	NMNoteType( "U_SumSqr", "NMSumSqr", xl, yl, "Func:" + thisfxn )
	NMNoteType( "U_Pnts", "NMPnts", xl, yl, "Func:" + thisfxn )
	
	Note U_Avg, "Input Waves:" + num2istr( nwaves )
	Note U_Sdv, "Input Waves:" + num2istr( nwaves )
	Note U_Sum, "Input Waves:" + num2istr( nwaves )
	Note U_SumSqr, "Input Waves:" + num2istr( nwaves )
	Note U_Pnts, "Input Waves:" + num2istr( nwaves )
	
	oList = NMUtilityWaveListShort( wList )
	
	Note U_Avg, "WaveList:" + oList
	Note U_Sdv, "WaveList:" + oList
	Note U_Sum, "WaveList:" + oList
	Note U_SumSqr, "WaveList:" + oList
	Note U_Pnts, "WaveList:" + oList
	
	KillWaves /Z U_WaveTemp1, U_WaveTemp2, U_WaveTemp3, U_wIdentity, U_wScaleX, U_Pnts2, U_PntsTemp
	
	if ( saveMatrix == 1 )
	
		NMNoteType( "U_2Dmatrix", "NM2Dwave", xl, yl, "Func:" + thisfxn )
		Note U_2Dmatrix, "WaveList:" + oList
		
		return "U_Avg;U_Sdv;U_Sum;U_SumSqr;U_Pnts;U_2Dmatrix;"
		
	else
	
		return "U_Avg;U_Sdv;U_Sum;U_SumSqr;U_Pnts;"
		
	endif
	
End // NMWavesStatistics

//****************************************************************
//****************************************************************
//****************************************************************

Function /S BinAndAverage( xWave, yWave, xbgn, binSize )
	String xWave // x-wave name, ( "" ) enter null-string to use x-scale of y-wave
	String yWave // y-wave name
	Variable xbgn // beginning xvalue
	Variable binSize // bin size
	
	Variable x0 = xbgn, x1 = xbgn + binSize
	Variable sumy, count, nbins, icnt, jcnt, savex
	String thisfxn = "BinAndAverage"
	
	String outputWave = yWave + "_binned"
	
	if ( numtype( xbgn ) > 0 )
		return NMErrorStr( 10, thisfxn, "xbgn", num2str( xbgn ) )
	endif
	
	if ( ( numtype( binSize ) > 0 ) || ( binsize <= 0 ) )
		return NMErrorStr( 10, thisfxn, "binSize", num2str( binSize ) )
	endif
	
	If ( NMUtilityWaveTest( yWave ) < 0 )
		return NMErrorStr( 1, thisfxn, "yWave", yWave )
	endif
	
	If ( ( strlen( xWave ) > 0 ) && ( NMUtilityWaveTest( xWave ) < 0 ) )
		return NMErrorStr( 1, thisfxn, "xWave", xWave )
	endif
	
	if ( strlen( xWave ) == 0 )
		Duplicate /O $yWave U_BinAvg_x
		Wave xtemp = U_BinAvg_x
		xtemp = x
	else
		Duplicate /O $xWave U_BinAvg_x
	endif
	
	Duplicate /O $yWave U_BinAvg_y
	
	Sort U_BinAvg_x U_BinAvg_y, U_BinAvg_x
	
	nbins = ceil( ( WaveMax( U_BinAvg_x ) - xbgn ) / binSize )
	
	Make /O/N=( nbins ) $outputWave
	Wave outy = $outputWave
	
	Setscale /P x xbgn, binSize, outy
	
	for ( icnt = 0; icnt < nbins; icnt += 1 )
	
		sumy = 0
		count = 0
	
		for ( jcnt = 0; jcnt < numpnts( U_BinAvg_x ); jcnt += 1 )
			if ( ( U_BinAvg_x[jcnt] > x0 ) && ( U_BinAvg_x[jcnt] <= x1 ) )
				sumy += U_BinAvg_y[jcnt]
				count += 1
			endif
		endfor
		
		outy[icnt] = sumy / count
		
		x0 += binSize
		x1 += binSize
		
	endfor
	
	KillWaves /Z U_BinAvg_x, U_BinAvg_y
	
	return outputWave
	
End // BinAndAverage

//****************************************************************
//
//	NMFindOnset()
//	find onset time of when signal rises above baseline noise
//
//****************************************************************

Function NMFindOnset( wName, tbgn, tend, avgN, Nstdv, negpos, direction )
	String wName // wave name
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	Variable avgN // avg points
	Variable Nstdv // number of stdv's above baseline
	Variable negpos // ( 1 ) pos onset ( -1 ) neg onset
	Variable direction // ( 1 ) forward search ( -1 ) backward search
	
	Variable icnt, ibgn, iend, level
	String thisfxn = "NMFindOnset"
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( ( numtype( avgN ) > 0 ) || ( avgN <= 0 ) )
		return NMError( 10, thisfxn, "avgN", num2istr( avgN ) )
	endif
	
	if ( ( numtype( Nstdv ) > 0 ) || ( Nstdv <= 0 ) )
		return NMError( 10, thisfxn, "Nstdv", num2istr( Nstdv ) )
	endif
	
	Wave eWave = $wName
	
	Variable dx = deltax( eWave )
	
	if ( direction == 1 )
	
		// search forward from tbgn until right-most data point falls above ( Avg + N*Stdv ), the baseline
	
		if ( tbgn < leftx( eWave ) )
			tbgn = leftx( eWave )
		endif
		
		if ( tend + avgN*dx >= rightx( eWave ) )
			tend = rightx( eWave ) - AvgN*dx
		endif
		
		ibgn = x2pnt( eWave, tbgn )
		iend = x2pnt( eWave, tend ) - AvgN
		
		if ( ibgn >= iend )
			return Nan
		endif
	
		for ( icnt = ibgn; icnt < iend; icnt += 1 )
			
			WaveStats /Q/Z/R=[icnt, icnt + avgN] eWave
			
			if ( negpos > 0 )
			
				level = V_avg + Nstdv * V_sdev
				
				if ( eWave[icnt+AvgN] >= level )
					return pnt2x( eWave, ( icnt+AvgN ) )
				endif
				
			else
			
				level = V_avg - Nstdv * V_sdev
				
				if ( eWave[icnt+AvgN] <= level )
					return pnt2x( eWave, ( icnt+AvgN ) )
				endif
				
			endif
	
		endfor
	
	else
	
	// search backward from tend until right-most data point falls below ( Avg + N*Stdv ), the baseline
	
		if ( tbgn - avgN*dx <= leftx( eWave ) )
			tbgn = leftx( eWave ) + AvgN*dx
		endif
		
		if ( tend > rightx( eWave ) )
			tend = rightx( eWave )
		endif
		
		ibgn = x2pnt( eWave, tbgn )
		iend = x2pnt( eWave, tend ) //- AvgN
		
		if ( ibgn >= iend )
			return Nan
		endif
	
		for ( icnt = iend; icnt > ibgn; icnt -= 1 )
		
			WaveStats /Q/Z/R=[icnt - avgN, icnt] eWave
			
			if ( negpos > 0 )
			
				level = V_avg + Nstdv * V_sdev
				
				if ( eWave[icnt] <= level )
					return pnt2x( eWave, icnt )
				endif
				
			else
			
				level = V_avg - Nstdv * V_sdev
				
				if ( eWave[icnt] >= level )
					return pnt2x( eWave, icnt )
				endif
			
			endif
	
		endfor
	
	endif
	
	return Nan

End // NMFindOnset

//****************************************************************
//
//	NMFindPeak()
//	find time of peak y-value
//
//****************************************************************

Function NMFindPeak( wName, tbgn, tend, avgN, Nstdv, negpos )
	String wName // wave name
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	Variable avgN // avg points
	Variable Nstdv // number of stdv's above baseline
	Variable negpos // ( -1 ) neg peak ( 1 ) pos peak 

	Variable icnt, ibgn, iend, lbgn, level
	String thisfxn = "NMFindPeak"
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( ( numtype( avgN ) > 0 ) || ( avgN <= 0 ) )
		return NMError( 10, thisfxn, "avgN", num2istr( avgN ) )
	endif
	
	if ( ( numtype( Nstdv ) > 0 ) || ( Nstdv <= 0 ) )
		return NMError( 10, thisfxn, "Nstdv", num2istr( Nstdv ) )
	endif
	
	Wave eWave = $wName
	
	Variable dx = deltax( eWave )
	
	if ( tbgn < leftx( eWave ) )
		tbgn = leftx( eWave )
	endif
	
	if ( tend > rightx( eWave ) )
		tend = rightx( eWave )
	endif
	
	ibgn = x2pnt( eWave, tbgn )
	iend = x2pnt( eWave, tend ) - avgN
	lbgn = eWave[ibgn]
	
	if ( ibgn >= iend )
		return Nan
	endif
	
	// search forward from tbgn until left-most data point resides above ( Avg + N*Stdv )

	for ( icnt = ibgn+1; icnt < iend; icnt += 1 )
		
		WaveStats /Q/Z/R=[icnt, icnt + avgN] eWave
		
		if ( negpos > 0 )
		
			level = V_avg + Nstdv * V_sdev
			
			if ( ( V_avg > lbgn ) && ( eWave[icnt] >= level ) )
				return pnt2x( eWave, icnt )
			endif
			
		else
		
			level = V_avg - Nstdv * V_sdev
			
			if ( ( V_avg < lbgn ) && ( eWave[icnt] <= level ) )
				return pnt2x( eWave, icnt )
			endif
		
		endif
	
	endfor
	
	return Nan

End // NMFindPeak

//****************************************************************
//
//	GetXstats()
//	compute x stats of a group of waves
//
//****************************************************************

Function GetXstats( select, wList )
	String select // select which value to pass back ( see below )
	String wList // wave list ( seperator ";" )
	
	// select options:	"numPnts", "minNumPnts", "maxNumPnts"
	//					"deltax", "minDeltax", "maxDeltax"
	//					"leftx", "minLeftx", "maxLeftx"
	//					"rightx", "minRightx", "maxRightx",
	// note, if waves have different deltax or numpnts or leftx or rightx, this function returns Nan
	
	Variable wcnt, dumvar
	
	Variable pnts = -1, minNumPnts = inf, maxNumPnts = -inf
	Variable dx = -1, minDeltax = inf, maxDeltax = -inf
	Variable lftx = -inf, minLeftx = inf, maxLeftx = -inf
	Variable rghtx = inf, minRightx = inf, maxRightx = -inf
	
	String wName, badList = wList, thisfxn = "GetXstats"
	
	if ( ItemsInList( wList ) == 0 )
		return Nan
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		wName = StringFromList( 0, wName, "," ) // in case of sub-wavelist
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		dumvar = numpnts( $wName )
		
		if ( pnts < 0 )
			pnts = dumvar // first wave
		elseif ( dumvar != pnts )
			pnts = Nan // waves have different numpnts
		endif
		
		if ( dumvar < minNumPnts )
			minNumPnts = dumvar
		endif
		
		if ( dumvar > maxNumPnts )
			maxNumPnts = dumvar
		endif
		
		 dumvar = deltax( $wName )
		 
		if ( ( dx < 0 ) && ( numtype( dumvar ) == 0 )  )
			dx = dumvar // first wave
		elseif ( ( numtype( dx ) == 0 ) && ( abs( dumvar - dx ) > 0.001 ) )
			dx = Nan // waves have different deltax
		endif
		
		if ( dumvar < minDeltax )
			minDeltax = dumvar
		endif
		
		if ( dumvar > maxDeltax )
			maxDeltax = dumvar
		endif
		
		dumvar = leftx( $wName )
		
		if ( ( numtype( lftx ) == 1 ) && ( numtype( dumvar ) == 0 )  )
			lftx = dumvar // first value
		elseif ( ( numtype( lftx ) == 0 ) && ( dumvar != lftx ) )
			lftx = Nan // doesnt match first value
		endif
		
		if ( dumvar < minLeftx )
			minLeftx = dumvar
		endif
		
		if ( dumvar > maxLeftx )
			maxLeftx = dumvar
		endif
		
		dumvar = rightx( $wName )
		
		if ( ( numtype( rghtx ) == 1 ) && ( numtype( dumvar ) == 0 )  )
			rghtx = dumvar // first value
		elseif ( ( numtype( rghtx ) == 0 ) && ( dumvar != rghtx ) )
			rghtx = Nan // doesnt match first value
		endif
		
		if ( dumvar > maxRightx )
			maxRightx = dumvar
		endif
		
		if ( dumvar < minRightx )
			minRightx = dumvar
		endif
		
		badList = RemoveFromList( wName, badList )
		
	endfor
	
	if ( numtype( dx ) > 0 )
		dx = Nan
	endif
	
	if ( numtype( lftx ) > 0 )
		lftx = Nan
	endif
	
	if ( numtype( rghtx ) > 0 )
		rghtx = Nan
	endif
	
	strswitch( select )
	
		case "npnts":
		case "numpnts":
			return pnts
		case "minNumPnts":
			return minNumPnts
		case "maxNumPnts":
			return maxNumPnts
			
		case "dx":
		case "deltax":
			return dx
		case "mindx":
		case "minDeltax":
			return minDeltax
		case "maxdx":
		case "maxDeltax":
			return maxDeltax
			
		case "leftx":
			return lftx
		case "minLeftx":
			return minLeftx
		case "maxLeftx":
			return maxLeftx
			
		case "rightx":
			return rghtx
		case "minRightx":
			return minRightx
		case "maxRightx":
			return maxRightx
		
		default:
			NMError( 20, thisfxn, "select", select )
			return Nan
			
	endswitch

	NMUtilityAlert( thisfxn, badList )
	
End // GetXstats

//****************************************************************
//
//	WaveListStats()
//	compute stats of a list of waves
//	results returned in waves U_AmpX and U_AmpY
//	stats can be Max, Min, Avg or Slope.
//
//****************************************************************

Function WaveListStats( alg, tbgn, tend, wList )
	String alg // statistic to compute ( "Max", "Min", "Avg" or "Slope" )
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, ampy, ampx, nwaves
	String xl, yl, txt, wName, dumstr, badList = wList
	String thisfxn = "WaveListStats"
	
	nwaves = ItemsInList( wList )
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( nwaves == 0 )
		return 0
	endif
	
	Make /O/N=( nwaves ) U_AmpX
	Make /O/N=( nwaves ) U_AmpY
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		strswitch( alg )
		
			case "Max":
				WaveStats /Q/Z/R=( tbgn, tend ) $wName
				ampy = V_max
				ampx = V_maxloc
				break
				
			case "Min":
				WaveStats /Q/Z/R=( tbgn, tend ) $wName
				ampy = V_min
				ampx = V_minloc
				break
				
			case "Avg":
				ampy = mean( $wName, tbgn, tend )
				ampx = Nan
				break
				
			case "Slope":
				dumstr = FindSlope( tbgn, tend, wName )
				ampy = str2num( StringByKey( "b", dumstr, "=" ) )
				ampx = str2num( StringByKey( "m", dumstr, "=" ) )
				break
				
			default:
				return NMError( 20, thisfxn, "alg", alg )
				
		endswitch
	
		U_AmpY[wcnt] = ampy
		U_AmpX[wcnt] = ampx
		
		badList = RemoveFromList( wName, badList )
	
	endfor
	
	xl = NMNoteLabel( "x", wList, "" )
	yl = NMNoteLabel( "y", wList, "" )
	
	NMNoteType( "U_AmpX", "NMStatsX", xl, yl, "Func:" + thisfxn )
	NMNoteType( "U_AmpY", "NMStatsY", xl, yl, "Func:" + thisfxn )
	
	txt = "Stats Alg:" + alg + ";Stats Tbgn:" + num2str( tbgn ) + ";Stats Tend:" + num2str( tend ) + ";"
	
	Note U_AmpX, txt
	Note U_AmpY, txt
	
	txt = "WaveList:" + NMUtilityWaveListShort( wList )
	
	Note U_AmpX, txt
	Note U_AmpY, txt
	
	NMUtilityAlert( thisfxn, badList )
	
	return 0
	
End // WaveListStats

//****************************************************************
//
//	MeanStdv()
//	compute the mean and stdv of a list of waves.
//	results returned as a string list.
//
//****************************************************************

Function /S MeanStdv( tbgn, tend, wList )
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, cnt, num, avg, stdv
	String wName, badList = wList, thisfxn = "MeanStdv"
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		Wave wv = $wName
		
		num = mean( wv, tbgn, tend )
		
		avg += num
		stdv += num*num
		cnt += 1
		
		badList = RemoveFromList( wName, badList )
		
	endfor
	
	if ( cnt >= 2 )
	
		stdv = sqrt( ( stdv - ( ( avg^2 ) / cnt ) ) / ( cnt-1 ) )
		avg = avg / cnt
	
	else
	
		stdv = Nan
		avg = Nan
	
	endif
	
	NMUtilityAlert( thisfxn, badList )
	
	return "mean=" + num2str( avg ) + ";stdv=" + num2str( stdv ) + ";count=" + num2istr( cnt )+";"

End // MeanStdv

//****************************************************************
//
//	ComputeWaveStats()
//	compute wave statistics
//	options: Max, Min, Avg, SDev, Var, RMS, Area, Slope, Level, Level+, Level-
//
//****************************************************************

Function ComputeWaveStats( wv, tbgn, tend, fxn, level )
	Wave wv // wave to measure
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	String fxn // function ( Max, Min, Avg, SDev, Var, RMS, Area, Slope, Level, Level+, Level- )
	Variable level // level detection value
	
	String dumstr, thisfxn = "ComputeWaveStats"
	String wName = GetWavesDataFolder( wv, 2 )
	
	Variable ax = Nan, ay = Nan
	
	if ( numtype( tbgn ) > 0 )
		tbgn = leftx( wv )
	endif
	
	if ( numtype( tend ) > 0 )
		tend = rightx( wv )
	endif
	
	if ( ( tbgn < leftx( wv ) ) && ( tend < leftx( wv ) ) )
		fxn = ""
	endif
	
	if ( ( tbgn > rightx( wv ) ) && ( tend > rightx( wv ) ) )
		fxn = ""
	endif
	
	strswitch( fxn )
			
		case "Max":
		
			WaveStats /Q/Z/R=( tbgn, tend ) wv
			ay = V_max; ax = V_maxloc
			
			if ( numtype( ax * ay ) > 0 )
				ax = Nan
				ay = Nan
			endif
			
			break
			
		case "Min":
		
			WaveStats /Q/Z/R=( tbgn, tend ) wv
			ay = V_min; ax = V_minloc
			
			if ( numtype( ax * ay ) > 0 )
				ax = Nan
				ay = Nan
			endif
			
			break
			
		case "Avg":
			ay = mean( wv, tbgn, tend )
			ax = Nan
			break
			
		case "Sdev":
			WaveStats /Q/Z/R=( tbgn, tend ) wv
			ay = V_sdev; ax = Nan
			break
			
		case "Var":
			WaveStats /Q/Z/R=( tbgn, tend ) wv
			ay = V_sdev*V_sdev; ax = Nan
			break
			
		case "RMS":
			WaveStats /Q/Z/R=( tbgn, tend ) wv
			ay = V_rms; ax = Nan
			break
			
		case "Area":
			ay = area( wv,tbgn, tend ); ax = Nan
			break
			
		case "Sum":
			ay = sum( wv,tbgn, tend ); ax = Nan
			break
			
		case "Slope":
		
			dumstr = FindSlope( tbgn, tend, wName )
			
			ax = str2num( StringByKey( "b", dumstr, "=" ) )
			ay = str2num( StringByKey( "m", dumstr, "=" ) )
			
			if ( numtype( ax * ay ) > 0 )
				ax = Nan
				ay = Nan
			endif
			
			break
			
		case "Onset":
		
			dumstr = FindMaxCurvatures( tbgn, tend, wName )
			
			ax = str2num( StringByKey( "t1", dumstr, "=" ) ) // use the first time value
			
			if ( ( ax < tbgn ) || ( ax > tend ) )
				ax = Nan
			endif
			
			if ( numtype( ax ) == 0 )
				ay = wv[x2pnt( wv, ax )]
			endif
		
			break
			
		case "Level":
			FindLevel /Q/R=( tbgn, tend ) wv, level
			ax = V_LevelX
			ay = level
			break
			
		case "Level+":
			FindLevel /EDGE=1/Q/R=( tbgn, tend ) wv, level
			ax = V_LevelX
			ay = level
			break
			
		case "Level-":
			FindLevel /EDGE=2/Q/R=( tbgn, tend ) wv, level
			ax = V_LevelX
			ay = level
			break	
			
	endswitch
	
	SetNMvar( "U_ax", ax )
	SetNMvar( "U_ay", ay )
	
	KillVariables /Z V_Flag
	
End // ComputeWaveStats

//****************************************************************
//
//	FindSlope()
//	compute the slope of a wave. 
//	slope ( m ) and intercept ( b ) passed back as a string list.
//
//****************************************************************

Function /S FindSlope( tbgn, tend, wName )
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	String wName // wave name
	
	Variable m, b
	String rslts = "", thisfxn = "FindSlope"
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NMErrorStr( 1, thisfxn, "wName", wName )
	endif
	
	WaveStats /Q/Z/R=( tbgn, tend ) $wName
	
	if ( V_npnts < 2 )
		return ""
	endif
	
	Curvefit /Q/N line $wName ( tbgn, tend )
	
	Wave W_Coef
	
	m = W_Coef[1]
	b = W_Coef[0]
	
	if ( numtype( m * b ) > 0 )
		m = Nan
		b = Nan
	endif
	
	rslts = "m=" + num2str( m ) + ";b=" + num2str( b )+";"
	
	KillWaves /Z W_coef, W_sigma
	
	return rslts // return slope ( m ) and intercept ( b ) as a string list

End // FindSlope

//****************************************************************
//
//
//
//****************************************************************

Function SpikeSlope(wName, event, thresh, pwin) // compute slope via simple linear regression
	String wName
	Variable event
	Variable thresh
	Variable pwin
	
	Variable tbgn, tend, epnt, xpnt, dt
	Variable icnt, jcnt, xavg, yavg, xsum, ysum, xysum, sumsqr, slope, intercept
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return Nan
	endif
	
	Wave wtemp = $wName
	
	dt = deltax(wtemp)
	epnt = x2pnt(wtemp, event)
	xpnt = pnt2x(wtemp, epnt)
	
	Make /O/N=(1 + 2 * pWin) U_SlopeX, U_SlopeY
	
	if (xpnt == event) // unlikely
	
		jcnt = epnt - pwin
		
		for (icnt = 0; icnt < numpnts(U_SlopeX); icnt += 1)
			U_SlopeX[icnt] = pnt2x(wtemp, jcnt)
			U_SlopeY[icnt] = wtemp[jcnt]
			jcnt += 1
		endfor
		
	elseif (xpnt < event)
	
		U_SlopeX[0] = event
		U_SlopeY[0] = thresh
		
		jcnt = epnt - (pwin - 1)
	
		for (icnt = 1; icnt < numpnts(U_SlopeX); icnt += 1)
			U_SlopeX[icnt] = pnt2x(wtemp, jcnt)
			U_SlopeY[icnt] = wtemp[jcnt]
			jcnt += 1
		endfor
		
	else
	
		U_SlopeX[0] = event
		U_SlopeY[0] = thresh
		
		jcnt = epnt - pwin
	
		for (icnt = 1; icnt < numpnts(U_SlopeX); icnt += 1)
			U_SlopeX[icnt] = pnt2x(wtemp, jcnt)
			U_SlopeY[icnt] = wtemp[jcnt]
			jcnt += 1
		endfor
	
	endif
	
	Wavestats /Q/Z U_SlopeX
	
	xavg = V_avg
	xsum = sum(U_SlopeX)
	
	Wavestats /Q/Z U_SlopeY
	
	yavg = V_avg
	ysum = sum(U_SlopeY)
	
	for (icnt = 0; icnt < numpnts(U_SlopeX); icnt += 1)
		xysum += (U_SlopeX[icnt] - xavg) * (U_SlopeY[icnt] - yavg)
		sumsqr += (U_SlopeX[icnt] - xavg) ^ 2
	endfor
	
	slope = xysum / sumsqr
	intercept = (ysum - slope * xsum) / numpnts(U_SlopeX)
	
	KillWaves /Z U_SlopeY, U_SlopeX

	return slope

End // SpikeSlope

//****************************************************************
//
//	FindMaxCurvatures()
//	find maximum curvature by fitting sigmoidal function ( Boltzmann equation ) 
//   based on analysis of Fedchyshyn and Wang, J Physiol 2007 June, 581:581-602
//	returns three times t1, t2, t3, where max occurs
//
//****************************************************************

Function /S FindMaxCurvatures( tbgn, tend, wName )
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	String wName // wave name
	
	Variable tmid, tc, t1, t2, t3
	String rslts = "", thisfxn = "FindMaxCurvatures"
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NMErrorStr( 1, thisfxn, "wName", wName ) // bad input wave
	endif
	
	WaveStats /Q/Z/R=( tbgn, tend ) $wName
	
	if ( V_npnts <= 2 )
		return ""
	endif
	
	Curvefit /N/Q Sigmoid $wName ( tbgn, tend )
	
	Wave W_Coef
	
	tmid = W_Coef[2]
	tc = W_Coef[3]
	
	if ( numtype( tmid * tc ) > 0 )
		return ""
	endif
	
	t1 = tmid - ln( 5 + 2 * sqrt( 6 ) ) * tc
	t2 = tmid
	t3 = tmid - ln( 5 - 2 * sqrt( 6 ) ) * tc
	
	rslts = "t1=" + num2str( t1 ) + ";t2=" + num2str( t2 ) + ";t3=" + num2str( t3 ) + ";"
	
	KillWaves /Z W_coef, W_sigma
	
	return rslts

End // FindMaxCurvatures

//****************************************************************
//
//	NMSortWave()
//	sort successes ( "true" values ) of a wave, via one of six sorting algorithms
//
//****************************************************************

Function NMSortWave( wName, dName, method, xv, yv, nv )
	String wName // wave to sort
	String dName // destination sort wave, where 1's and 0's are stored
	Variable method // sorting method ( see switch cases 1-6 below )
	Variable xv // x value
	Variable yv // y value
	Variable nv // n value
	
	Variable scnt, lim1, lim2, testyv, testnv
	String alg, xl, yl, thisfxn = "NMSortWave"
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	if ( WaveExists( $dName ) == 1 )
		//return NMError( 2, thisfxn, "dName", dName )
	endif
	
	if ( numtype( xv ) > 0 )
		return NMError( 10, thisfxn, "xv", num2str( xv ) )
	endif
	
	switch( method )
	
		case 1:
		case 3:
			break
			
		case 2:
		case 4:
		case 6:
			testyv = 1
			testnv = 1
			break
		
		case 5:
			testyv = 1
			break
		
		default:
			return NMError( 10, thisfxn, "method", num2istr( method ) )
	
	endswitch
	
	if ( ( testyv == 1 ) && ( numtype( yv ) > 0 ) )
		return NMError( 10, thisfxn, "yv", num2str( yv ) )
	endif
	
	if ( ( testnv == 1 ) && ( numtype( nv ) > 0 ) )
		return NMError( 10, thisfxn, "nv", num2str( nv ) )
	endif
	
	Duplicate /O $wName $dName
	
	Wave wTemp = $wName
	Wave wSort = $dName
	
	wSort = 0
	
	switch( method )
	
		case 1:
		
			alg = "[a] > x"
			
			for ( scnt = 0; scnt < numpnts( wTemp ); scnt += 1 )
				if ( numtype( wTemp[scnt] ) > 0 )
					wSort[scnt] = Nan
				elseif ( wTemp[scnt] > xv )
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		case 2:
		
			alg = "[a] > x - n*y"
			
			for ( scnt = 0; scnt < numpnts( wTemp ); scnt += 1 )
				if ( numtype( wTemp[scnt] ) > 0 )
					wSort[scnt] = Nan
				elseif ( wTemp[scnt] > xv - ( nv * yv ) )
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		case 3:
		
			alg = "[a] < x"
			
			for ( scnt = 0; scnt < numpnts( wTemp ); scnt += 1 )
				if ( numtype( wTemp[scnt] ) > 0 )
					wSort[scnt] = Nan
				elseif ( wTemp[scnt] < xv )
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		case 4:
		
			alg = "[a] < x + n*y"
			
			for ( scnt = 0; scnt < numpnts( wTemp ); scnt += 1 )
				if ( numtype( wTemp[scnt] ) > 0 )
					wSort[scnt] = Nan
				elseif ( wTemp[scnt] < xv + ( nv * yv ) )
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		case 5:
		
			alg = "x < [a] < y"
			
			for ( scnt = 0; scnt < numpnts( wTemp ); scnt += 1 )
				if ( numtype( wTemp[scnt] ) > 0 )
					wSort[scnt] = Nan
				elseif ( ( wTemp[scnt] > xv ) && ( wTemp[scnt] < yv ) )
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		case 6:
		
			alg = "x - n*y < [a] < x + n*y"
			
			for ( scnt = 0; scnt < numpnts( wTemp ); scnt += 1 )
				if ( numtype( wTemp[scnt] ) > 0 )
					wSort[scnt] = Nan
				elseif ( ( wTemp[scnt] > xv - ( nv * yv ) ) && ( wTemp[scnt] < xv + ( nv * yv ) ) )
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
	endswitch
	
	xl = NMNoteLabel( "x", wName, "" )
	yl = "True ( 1 ) / False ( 0 )"
	
	NMNoteType( dName, "NMSet", xl, yl, "Func:" + thisfxn )
	
	Note wSort, "Sort Wave:" + wName
	Note wSort, "Sort Alg:" +alg + ";Sort xValue:" + num2str( xv ) + ";Sort yValue:" + num2str( yv )+ ";Sort nValue:" + num2str( nv ) + ";"
	
	return sum( wSort,0,inf ) // return number of successes

End // NMSortWave

//****************************************************************
//
//	NextWaveItem()
//	find next occurence of number within a wave
//
//****************************************************************

Function NextWaveItem( wName, item, from, direction ) // find next item in wave
	String wName // wave name
	Variable item // item number to find
	Variable from // start point number
	Variable direction // +1 forward; -1 backward
	
	Variable wcnt, wlmt, next, found, npnts, inc = 1

	if ( NMUtilityWaveTest( wName ) < 0 )
		return from
	endif
	
	Wave tWave = $wName
	
	npnts = numpnts( tWave )
	
	if ( direction < 0 )
		next = from - 1
		inc = -1
		wlmt = next + 1
	else
		next = from + 1
		wlmt = npnts - from
	endif
	
	if ( ( next > npnts - 1 ) || ( next < 0 ) )
		return from // next out of bounds
	endif
	
	found = from
	
	for ( wcnt = 0; wcnt < wlmt; wcnt += 1 )
	
		if ( tWave[next] == item )
			found = next
			break
		endif
		
		next += inc
		
	endfor
	
	return found

End // NextWaveItem

//****************************************************************
//****************************************************************
//****************************************************************

Function /S WaveSequence( wName, seqStr, pntBgn, pntEnd, pntBlocks )
	String wName // wave name
	String seqStr // seq string "0;1;2;3;" or "0,3" for range
	Variable pntBgn // starting wave number
	Variable pntEnd // ending wave number
	Variable pntBlocks // number of blocks in each group
	
	Variable index, last, icnt, jcnt
	String thisfxn = "WaveSequence"
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NMErrorStr( 1, thisfxn, "wName", wName )
	endif
	
	if ( strsearch( seqStr, ",", 0 ) > 0 )
		seqStr = RangeToSequenceStr( seqStr )
	endif
	
	if ( ( numtype( pntBgn ) > 0 ) || ( pntBgn < 0 ) )
		pntBgn = 0
	endif
	
	if ( ( numtype( pntEnd ) > 0 ) || ( pntEnd >= numpnts( $wName ) ) )
		pntEnd = numpnts( $wName ) - 1
	endif
	
	if ( ( numtype( pntBlocks ) > 0 ) || ( pntBlocks <= 0 ) )
		pntBlocks = 1
	endif
	
	if ( ItemsInList( seqStr ) == 0 )
		return "" // nothing to do
	endif
	
	Wave wTemp = $wName
		
	index = pntBgn
	
	for ( icnt = pntBgn; icnt <= pntEnd; icnt += pntBlocks )
	
		wTemp[icnt,icnt+pntBlocks-1] = str2num( StringFromList( jcnt,seqStr ) )
		
		jcnt += 1
		
		if ( jcnt >= ItemsInList( seqStr ) )
			jcnt = 0
		endif
		
	endfor
	
	return seqStr

End // WaveSequence

//****************************************************************
//****************************************************************
//****************************************************************

Function WaveCountValue( wName, valueToCount )
	String wName
	Variable valueToCount // value to count, or ( inf ) all positive numbers ( -inf ) all negative numbers
	
	Variable icnt, count

	if ( NMUtilityWaveTest( wName ) < 0 )
		return 0
	endif
	
	Wave wtemp = $wName
	
	if ( numtype( valueToCount ) == 0 )
	
		MatrixOp /O U_wCount = sum( equal( wtemp, valueToCount ) )
		
	elseif ( valueToCount == inf )
	
		MatrixOp /O U_wCount = sum( equal( wtemp/abs(wtemp), 1 ) )
	
	elseif ( valueToCount == -inf )
	
		MatrixOp /O U_wCount = sum( equal( wtemp/abs(wtemp), -1 ) )
	
	else
	
		return Nan
		
	endif
	
	count = U_wCount[0]
	
	KillWaves /Z U_wCount
	
	return count

End // WaveCountValue

//****************************************************************
//****************************************************************
//****************************************************************

Function Time2Intervals( wName, tbgn, tend, minIntvl, maxIntvl ) // compute inter-event intervals
	String wName // wName of event times
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	Variable minIntvl // min allowed interval ( use 0 for no limit )
	Variable maxIntvl // max allowed interval ( use inf for no limit )
	
	Variable isi, ecnt, icnt, event, last
	String xl, yl, thisfxn = "Time2Intervals"
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( ( numtype( minIntvl ) > 0 ) || ( minIntvl < 0 ) )
		minIntvl = 0
	endif
	
	if ( ( numtype( maxIntvl ) > 0 ) || ( maxIntvl <= 0 ) )
		maxIntvl = inf
	endif
	
	Wave wtemp = $wName

	Duplicate /O $wName U_INTVLS
	
	U_INTVLS = Nan
	
	for ( ecnt = 1; ecnt < numpnts( wtemp ); ecnt += 1 )
	
		last = wtemp[ecnt - 1]
		event = wtemp[ecnt]
		
		if ( ( numtype( last ) > 0 ) || ( numtype( event ) > 0 ) )
			continue
		endif
		
		if ( ( event >= tbgn ) && ( event <= tend ) && ( event >= last ) )
		
			isi = event - last
			
			if ( ( isi >= minIntvl ) && ( isi <= maxIntvl ) )
				U_INTVLS[ecnt] = isi
				icnt += 1
			endif
			
		endif
		
	endfor
	
	xl = NMNoteLabel( "x", wName, "" )
	yl = NMNoteLabel( "y", wName, "msec" )
	
	NMNoteType( "U_INTVLS", "NMIntervals", xl, yl, "Func:" + thisfxn )
	
	Note U_INTVLS, "Interval Source:" + wName
	
	return icnt

End // Time2Intervals

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEvent2Wave( waveNumWave, eventWave, beforeTime, afterTime, stopAtNextEvent, allowTruncatedEvents, chanNum, outputWavePrefix )
	String waveNumWave // wave of record numbers
	String eventWave // wave of event times
	Variable beforeTime, afterTime // save time before, after event time
	Variable stopAtNextEvent // ( < 0 ) no ( >= 0 ) yes... if greater than zero, use value to limit time before next event
	Variable allowTruncatedEvents // ( 0 ) no ( 1 ) yes
	Variable chanNum // channel number ( pass -1 for current )
	String outputWavePrefix // prefix name for new waves
	
	Variable icnt, tbgn, tend, npnts, event, eventNum
	Variable wnum, continuous, dx, intvl, pbgn, pend
	String xl, yl, wName1, wName2, wName3, lastWave, nextWave, wList = ""
	String thisfxn = "NMEvent2Wave"
	
	if ( NMUtilityWaveTest( waveNumWave ) < 0 )
		return NMErrorStr( 1, thisfxn, "waveNumWave", waveNumWave )
	endif
	
	if ( NMUtilityWaveTest( eventWave ) < 0 )
		return NMErrorStr( 1, thisfxn, "eventWave", eventWave )
	endif
	
	if ( numpnts( $waveNumWave ) != numpnts( $eventWave ) )
		return NMErrorStr( 5, thisfxn, "waveNumWave", waveNumWave )
	endif
	
	if ( ( numtype( beforeTime ) > 0 ) || ( beforeTime < 0 ) )
		return NMErrorStr( 10, thisfxn, "beforeTime", num2str( beforeTime ) )
	endif
	
	if ( ( numtype( afterTime ) > 0 ) || ( afterTime < 0 ) )
		return NMErrorStr( 10, thisfxn, "afterTime", num2str( afterTime ) )
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( strlen( outputWavePrefix ) == 0 )
		return NMErrorStr( 21, thisfxn, "outputWavePrefix", outputWavePrefix )
	endif
	
	Wave recordNum = $waveNumWave
	Wave eventTimes = $eventWave
	
	npnts = numpnts( recordNum )
	
	wName3 = outputWavePrefix + "Times"
	
	Make /O/N=( npnts ) $wName3 = Nan
	
	Wave st = $wName3
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
	
		wnum = recordNum[icnt]
		wName1 = NMChanWaveName( chanNum, wnum ) // source wave, raw data
		nextWave = NMChanWaveName( chanNum, wnum+1 )
		
		if ( wnum == 0 )
			lastWave = ""
		else
			lastWave = NMChanWaveName( chanNum, wnum-1 ) 
		endif
		
		continuous = 0
		
		if ( WaveExists( $wName1 ) == 0 )
			continue
		endif
		
		xl = NMNoteLabel( "x", wName1, "msec" )
		yl = NMNoteLabel( "y", wName1, "" )
		
		event = eventTimes[icnt]
		
		intvl = Nan
		
		if ( ( icnt < npnts - 1 ) && ( recordNum[icnt] == recordNum[icnt+1] ) )
			intvl = eventTimes[icnt+1] - eventTimes[icnt]
		endif
		
		if ( numtype( event ) > 0 )
			continue
		endif
		
		tbgn = event - beforeTime
		tend = event + afterTime
		
		if ( tbgn < leftx( $wName1 ) )
			if ( ( WaveExists( $lastWave ) == 1 ) && ( tbgn >= leftx( $lastWave ) ) && ( tbgn <= rightx( $lastWave ) ) ) // continuous
				continuous = 1
			elseif ( allowTruncatedEvents != 1 )
				NMHistory( "Event " + num2istr( icnt ) + " out of range on the left: " + wName1 )
				continue
			endif
		endif
		
		if ( tend > rightx( $wName1 ) )
			if ( ( WaveExists( $nextWave ) == 1 ) && ( tend >= leftx( $nextWave ) ) && ( tend <= rightx( $nextWave ) ) ) // continuous
				continuous = 2
			elseif ( allowTruncatedEvents != 1 )
				NMHistory( "Event " + num2istr( icnt ) + " out of range on the right: " + wName1 )
				continue
			endif
		endif
		
		wName2 = GetWaveName( outputWavePrefix + "_", chanNum, eventNum )
		
		dx = deltax( $wName1 )
		
		switch ( continuous )
		
			case 1:
			
				Duplicate /O/R=( tbgn,rightx( $lastWave ) ) $lastWave $( wName2 + "_last" )
				Duplicate /O/R=( leftx( $wName1 ),tend ) $wName1 $wName2
				
				Wave w1 = $( wName2 + "_last" )
				Wave w2 = $wName2
				
				Concatenate /KILL/NP/O {w1, w2}, U_EventConcat
				Duplicate /O U_EventConcat, $wName2
				KillWaves /Z U_EventConcat
				
				break
				
			case 2:
			
				Duplicate /O/R=( tbgn,rightx( $wName1 ) ) $wName1 $wName2
				Duplicate /O/R=( leftx( $nextWave ),tend ) $nextWave $( wName2 + "_next" )
				
				Wave w1 = $wName2
				Wave w2 = $( wName2 + "_next" )
				
				Concatenate /KILL/NP/O {w1, w2}, U_EventConcat
				Duplicate /O U_EventConcat, $wName2
				KillWaves /Z U_EventConcat
				
				break
				
			default:
			
				Duplicate /O/R=( tbgn, tend ) $wName1 $wName2
			
		endswitch
		
		Setscale /P x 0, dx, $wName2
		
		if ( ( stopAtNextEvent >= 0 ) && ( numtype( intvl ) == 0 ) && ( beforeTime + intvl - stopAtNextEvent < tend ) )
		
			Wave wtemp = $wName2
			
			tbgn = beforeTime + intvl - stopAtNextEvent
			
			pbgn = x2pnt( wtemp, tbgn )
			pend = inf
			
			wtemp[pbgn, pend] = Nan
			
		endif
		
		NMNoteType( wName2, "Event", xl, yl, "Func:" + thisfxn )
		Note $wName2, "Event Source:" + wName1 + ";Event Time:" + Num2StrLong( event, 3 ) + ";"
		
		st[ eventNum ] = event
		
		eventNum += 1
	
		wList = AddListItem( wName2, wList, ";", inf )
		
	endfor
	
	if ( eventNum == 0 ) 
		KillWaves /Z st
	else
		Redimension /N=( eventNum ) st
	endif
	
	NMPrefixAdd( outputWavePrefix + "_" )
	
	return wList

End // NMEvent2Wave

//****************************************************************
//****************************************************************
//****************************************************************
//
//	2D matrix functions defined below...
//
//****************************************************************
//****************************************************************
//****************************************************************

//****************************************************************
//
//	NMMatrixAvgRows()
//	compute avg and stdv of a matrix wave along its rows; results stored in U_Avg and U_Sdv and U_Pnts
//
//****************************************************************

Function /S NMMatrixAvgRows( matrixName, ignoreNANs )
	String matrixName // name of 2D matrix wave
	Variable ignoreNANs // ignore NANs in computation ( 0 ) no ( 1 ) yes
	
	Variable nrows, ncols, lftx, dx
	String thisfxn = "NMMatrixAvgRows"
	
	Variable minNumOfDataPoints = NumVarOrDefault("U_minNumOfDataPoints", 2) // min number of data points to include in average
	
	if ( WaveExists( $matrixName ) == 0 )
		return NMErrorStr( 1, thisfxn, "matrixName", matrixName )
	endif
	
	nrows = DimSize( $matrixName, 0 )
	ncols = DimSize( $matrixName, 1 )
	lftx = DimOffset( $matrixName, 0 )
	dx = DimDelta( $matrixName, 0 )
	
	if ( ( nrows < 1 ) || ( ncols < 2 ) )
		return ""
	endif
	
	Duplicate /O $matrixName U_cMatrix
	
	MatrixOp /O U_iMatrix = U_cMatrix / U_cMatrix // creates matrix with 1's where there are data points
	
	if ( ignoreNANs == 1 )
		MatrixOp /O U_iMatrix = ReplaceNaNs( U_iMatrix, 0 )
		MatrixOp /O U_cMatrix = ReplaceNaNs( U_cMatrix, 0 )
	endif
	
	MatrixOp /O U_Pnts = sumRows( U_iMatrix )
	MatrixOp /O U_Pnts = U_Pnts * greater( U_Pnts, minNumOfDataPoints - 1 ) // reject rows with not enough data points
	
	MatrixOp /O U_Pnts = U_Pnts * ( U_Pnts / U_Pnts ) // converts 0's to NAN's
	
	MatrixOp /O U_Sum = sumRows( U_cMatrix )
	MatrixOp /O U_SumSqr = sumRows( powR( U_cMatrix, 2 ) )
	
	MatrixOp /O U_Sdv = sqrt( ( U_SumSqr - ( ( powR( U_Sum, 2 ) ) / U_Pnts ) ) / ( U_Pnts - 1 ) )
	MatrixOp /O U_Avg = U_Sum / U_Pnts
	
	Setscale /P x lftx, dx, U_Avg, U_Sdv, U_Pnts
	
	KillWaves /Z U_cMatrix, U_iMatrix, U_Sum, U_SumSqr
	
	return "U_Avg;U_Sdv;U_Pnts;"
	
End // NMMatrixAvgRows

//****************************************************************
//
//	NMMatrixSumRows()
//	compute the sum of rows of a matrix wave; results stored in U_Sum and U_Pnts
//
//****************************************************************

Function /S NMMatrixSumRows( matrixName, ignoreNANs )
	String matrixName // name of 2D matrix wave
	Variable ignoreNANs // ignore NANs in computation ( 0 ) no ( 1 ) yes
	
	String thisfxn = "NMMatrixSumRows"
	
	if ( WaveExists( $matrixName ) == 0 )
		return NMErrorStr( 1, thisfxn, "matrixName", matrixName )
	endif
	
	Variable nrows = DimSize( $matrixName, 0 )
	Variable ncols = DimSize( $matrixName, 1 )
	
	Variable lftx = DimOffset( $matrixName, 0 )
	Variable dx = DimDelta( $matrixName, 0 )
	
	if ( ( nrows < 1 ) || ( ncols < 2 ) )
		return ""
	endif
	
	Duplicate /O $matrixName U_cMatrix
	
	MatrixOp /O U_iMatrix = U_cMatrix / U_cMatrix // creates matrix with 1's where there are data points
	
	if ( ignoreNANs == 1 )
		MatrixOp /O U_iMatrix = ReplaceNaNs( U_iMatrix, 0 )
		MatrixOp /O U_cMatrix = ReplaceNaNs( U_cMatrix, 0 )
	endif
	
	MatrixOp /O U_Sum = sumRows( U_cMatrix )
	MatrixOp /O U_Pnts = sumRows( U_iMatrix )
	
	Setscale /P x lftx, dx, U_Sum, U_Pnts
	
	KillWaves /Z U_cMatrix, U_iMatrix
	
	return "U_Sum;U_Pnts;"
	
End // NMMatrixSumRows

//****************************************************************
//
//	NMMatrixRow2Wave()
//	copy row of 2D wave to a new 1D wave
//
//****************************************************************

Function NMMatrixRow2Wave( matrixName, outputWaveName, rNum )
	String matrixName // 2D matrix wave name
	String outputWaveName // output wave name
	Variable rNum // row number
	
	Variable ccnt, columns, rows
	String thisfxn = "NMMatrixRow2Wave"
	
	if ( WaveExists( $matrixName ) == 0 )
		return NMError( 1, thisfxn, "matrixName", matrixName )
	endif
	
	if ( WaveExists( $outputWaveName ) == 1 )
		return NMError( 2, thisfxn, "outputWaveName", outputWaveName )
	endif

	rows = DimSize( $matrixName, 0 )
	columns = DimSize( $matrixName, 1 )
	
	if ( ( columns < 2 ) || ( rNum < 0 ) || ( rNum >= rows ) )
		return -1
	endif
	
	Wave m2D = $matrixName
	
	MatrixOp /O $outputWaveName = row( m2D, rNum )
	
	Setscale /P x DimOffset( $matrixName, 1), DimDelta( $matrixName, 1), $outputWaveName
	
	return 0

End // NMMatrixRow2Wave

//****************************************************************
//
//	NMMatrixColumn2Wave()
//	copy column of 2D wave to a new 1D wave
//
//****************************************************************

Function NMMatrixColumn2Wave( matrixName, outputWaveName, cNum )
	String matrixName // 2D matrix wave name
	String outputWaveName // output wave name
	Variable cNum // column  number
	
	Variable rcnt, rows, columns
	String thisfxn = "NMMatrixColumn2Wave"
	
	if ( WaveExists( $matrixName ) == 0 )
		return NMError( 1, thisfxn, "matrixName", matrixName )
	endif
	
	if ( WaveExists( $outputWaveName ) == 1 )
		return NMError( 2, thisfxn, "outputWaveName", outputWaveName )
	endif

	rows = DimSize( $matrixName, 0 )
	columns = DimSize( $matrixName, 1 )
	
	if ( ( rows < 1 ) || ( cNum < 0 ) || ( cNum >= columns ) )
		return -1
	endif
	
	Wave m2D = $matrixName
	
	MatrixOp /O $outputWaveName = col( m2D, cNum )
	
	Setscale /P x DimOffset( $matrixName, 0), DimDelta( $matrixName, 0), $outputWaveName
	
	return 0

End // NMMatrixColumn2Wave

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Window functions defined below...
//
//****************************************************************
//****************************************************************
//****************************************************************

//****************************************************************
//
//	CheckGraphName()
//	check graph name is correct format
//
//****************************************************************

Function /S CheckGraphName( gName )
	String gName
	
	Variable icnt
	
	for ( icnt = 0; icnt < strlen( gName ); icnt += 1 )
	
		strswitch( gName[icnt,icnt] )
			case ":":
			case ";":
			case ",":
			case ".":
			case " ":
				gName[icnt,icnt] = "_"
		endswitch
	endfor
	
	return gName[0,30]

End // CheckGraphName

//****************************************************************
//
//	SetGraphWaveColor()
//	change color of waves to raindow
//
//****************************************************************

Function GraphRainbow( gName, wList )
	String gName // graph name
	String wList // wave list ( seperator ";" ), or "" or "_All_" for all waves in the graph
	
	if ( Wintype( gName ) != 1 )
		return NMError( 40, "GraphRainbow", "gName", gName )
	endif
	
	Variable wcnt, inc = 800, cmax = 65280, cvalue
	String wName
	
	if ( ( StringMatch( wList, "_All_" ) == 1 ) || ( ItemsInList( wList ) == 0 ) )
		wList = TraceNameList( gName, ";", 1 )
	endif

	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		cvalue -= trunc( wcnt/6 ) * inc
		
		if ( cvalue <= 3000 )
			cvalue = cmax
		endif
		
		switch ( mod( wcnt,6 ) )
			case 0: // red
				ModifyGraph /W=$gName rgb( $wName )=( cvalue,0,0 )
				break
			case 1: // green
				ModifyGraph /W=$gName rgb( $wName )=( 0,cvalue,0 )
				break
			case 2: // blue
				ModifyGraph /W=$gName rgb( $wName )=( 0,0,cvalue )
				break
			case 3: // yellow
				cvalue = min( cvalue, 50000 )
				ModifyGraph /W=$gName rgb( $wName )=( cvalue,cvalue,0 )
				break
			case 4: // turqoise
				ModifyGraph /W=$gName rgb( $wName )=( 0,cvalue,cvalue )
				break
			case 5: // purple
				ModifyGraph /W=$gName rgb( $wName )=( cvalue,0,cvalue )
				break
		endswitch
		
	endfor
	
End // GraphRaindow

//****************************************************************
//
//	PrintMarqueeCoords()
//
//****************************************************************

Function PrintMarqueeCoords() : GraphMarquee

	GetMarquee left, bottom
	
	if ( V_Flag == 0 )
		Print "There is no marquee"
	else
		printf "marquee left : %g\r", V_left
		printf "marquee right: %g\r", V_right
		printf "marquee top: %g\r", V_top
		printf "marquee bottom: %g\r", V_bottom
	endif
	
End // PrintMarqueeCoords()

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTableWaveList( tName, fullPath )
	String tName
	Variable fullPath
	
	Variable icnt, columns
	String info, folder, wName, wList = ""
	
	if ( WinType( tName ) != 2 )
		return NMErrorStr( 50, "NMTableWaveList", "tName", tName )
	endif
	
	info = TableInfo( tName, -2 )
	
	columns = str2num( StringByKey("COLUMNS", info) )
	
	if ( ( numtype( columns ) > 0 ) || ( columns <= 0 ) )
		return ""
	endif
	
	for ( icnt = 0 ; icnt < columns ; icnt += 1 )
	
		if ( WaveExists( WaveRefIndexed( tName, icnt, 1 ) ) == 0 )
			continue
		endif
	
		Wave w = WaveRefIndexed( tName, icnt, 1 )
		
		if ( WaveExists( w ) == 0 )
			continue
		endif
		
		if ( fullPath == 1 )
			wName = GetWavesDataFolder( w, 2 )
		else
			wName = NameOfWave( w )
		endif
		
		if ( strlen( wName ) > 0 )
			wList += wName + ";"
		endif
		
	endfor

	return wList
	
End // NMTableWaveList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	String functions defined below...
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAddToList( itemOrListStr, listStr, listSepStr ) // add to list only if it is not in the list
	String itemOrListStr, listStr, listSepStr
	
	Variable icnt, items
	String itemStr
	
	strswitch( listSepStr )
		case ";":
		case ",":
			break
		default:
			return listStr
	endswitch
	
	items = ItemsInList( itemOrListStr, listSepStr )
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
	
		itemStr = StringFromList( icnt, itemOrListStr, listSepStr )
		
		if ( WhichListItem( itemStr, listStr, listSepStr ) < 0 )
			listStr += itemStr + listSepStr
		endif
		
	endfor
	
	return listStr

End // NMAddToList

//****************************************************************
//
//	NMAndLists()
//
//****************************************************************

Function /S NMAndLists( listStr1, listStr2, listSepStr )
	String listStr1, listStr2, listSepStr
	
	Variable icnt, items
	String itemStr, andList = ""
	
	items = ItemsInList( listStr1, listSepStr )
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
	
		itemStr = StringFromList( icnt, listStr1, listSepStr )
		
		if ( WhichListItem( itemStr, listStr2, listSepStr ) >= 0 )
			andList += itemStr + listSepStr
		endif
		
	endfor
	
	return andList

End // NMAndLists

//****************************************************************
//
//	RangeToSequenceStr()
//
//****************************************************************

Function /S RangeToSequenceStr( rangeStr )
	String rangeStr // e.g. "0,3" or "0-3"
	
	Variable first, last, icnt
	String seqStr = ""
	
	if ( strsearch( rangeStr, ",", 0 ) > 0 )
		// nothing to do
	elseif ( strsearch( rangeStr, "-", 0 ) > 0 )
		rangeStr = ReplaceString( "-", rangeStr, "," )
	else
		return rangeStr // unrecognized seperator
	endif
	
	if ( ItemsInList( rangeStr, "," ) != 2 )
		return rangeStr
	endif
	
	first = str2num( StringFromList( 0, rangeStr, "," ) )
	last = str2num( StringFromList( 1, rangeStr, "," ) )
	
	for ( icnt = first; icnt <= last; icnt += 1 )
		seqStr += num2istr( icnt ) + ";"
	endfor
		
	return seqStr // e.g. "0;1;2;3;"
	
End // RangeToSequenceStr

//****************************************************************
//
//	SequenceToRangeStr()
//
//****************************************************************

Function /S SequenceToRangeStr( seqList, seperator )
	String seqList // e.g. "0;1;2;3;5;6;7;"
	String seperator // "-" or ","
	
	Variable icnt, items, seqNum, first = Nan, last, next, foundRange
	String range, rangeList = ""
	
	items = ItemsInList( seqList )
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
		
		seqNum = str2num( StringFromList( icnt, seqList ) )
		
		if ( numtype( seqNum ) > 0 )
			return seqList // error
		endif
		
		if ( numtype( first ) > 0 )
		
			first = seqNum
			next = first + 1
			foundRange = 0
			
		else
			
			if ( seqNum == next )
			
				next += 1
				foundRange = 1
				last = seqNum
				
				if ( icnt < items - 1 )
					continue
				endif
				
			endif
			
			if ( ( foundRange == 1 ) && ( last > first + 1 ) )
				
				range = num2str( first ) + seperator + num2str( last )
				rangeList += range + ";"
				
			else
			
				rangeList += num2str( first ) + ";"
				
				if ( last != first )
					rangeList += num2str( last ) + ";"
				endif
				
			endif
			
			if ( ( seqNum != last ) && ( icnt == items - 1 ) )
				rangeList += num2str( seqNum ) + ";"
			endif
			
			first = seqNum
			next = first + 1
			foundRange = 0
			
		endif
		
		last = seqNum
	
	endfor
		
	return rangeList // e.g. "0-3;5-7;"
	
End // SequenceToRangeStr

//****************************************************************
//
//	Num2StrLong()
//
//****************************************************************

Function /S Num2StrLong( num, decimals )
	Variable num, decimals
	
	String ttl
	
	sprintf ttl, "%." + num2str( decimals ) + "f", num
	
	return ttl
	
End // Num2StrLong

//****************************************************************
//
//	StringAddToEnd()
//
//****************************************************************

Function /S StringAddToEnd( str, str2add )
	String str
	String str2add
	
	Variable slen = strlen( str )
	Variable alen = strlen( str2add )
	
	if ( StringMatch( str2add, str[ slen - alen , slen - 1 ] ) == 0 )
		str += str2add
	endif
	
	return str
	
End // StringAddToEnd

//****************************************************************
//
//	NMQuotes()
//	add string quotes "" around string
//
//****************************************************************

Function /S NMQuotes( istring )
	String istring

	return "\"" + istring + "\""

End // NMQuotes

//****************************************************************
//
//	FindCommonPrefix()
//
//****************************************************************

Function /S FindCommonPrefix( wList )
	String wList
	
	Variable icnt, jcnt, thesame
	String wname, wname2, prefix = ""
	
	wname = StringFromList( 0, wList )
	
	for ( icnt = 0 ; icnt < strlen( wname ) ; icnt += 1 )
	
		thesame = 1
		
		for ( jcnt = 1 ; jcnt < ItemsInList( wList ) ; jcnt += 1 )
		
			wname2 = StringFromList( jcnt, wList )
			
			if ( StringMatch( wname[icnt, icnt], wname2[icnt,icnt] ) == 0 )
				return prefix
			endif
		
		endfor
		
		prefix += wname[icnt, icnt]
	
	endfor
	
	return prefix
	
End // FindCommonPrefix

//****************************************************************
//
//	GetSeqNum()
//	return sequence number of wave name
//
//****************************************************************

Function GetSeqNum( strWithSeqNum )
	String strWithSeqNum
	
	Variable icnt, ibeg, iend, found, seqnum = Nan
	
	for ( icnt = strlen( strWithSeqNum )-1; icnt >= 0; icnt -= 1 )
		if ( numtype( str2num( strWithSeqNum[icnt] ) ) == 0 )
			found = 1
			break // first appearance of number, from right
		endif
	endfor
	
	if ( found == 0 )
		return Nan
	endif
	
	iend = icnt
	found = 0
	
	for ( icnt = iend; icnt >= 0; icnt -= 1 )
		if ( numtype( str2num( strWithSeqNum[icnt] ) ) == 2 )
			found = 1
			break // last appearance of number, from right
		endif
	endfor
	
	if ( found == 0 )
		return Nan
	endif
	
	ibeg = icnt+1
	
	seqnum = str2num( strWithSeqNum[ibeg, iend] )
	
	return seqnum

End // GetSeqNum

//****************************************************************
//
//	GetNumFromStr()
//	find number following a string value
//
//****************************************************************

Function GetNumFromStr( str, findStr )
	String str // string to search
	String findStr // string to find ( e.g. "marker( x )=" )
	
	Variable icnt, ibgn
	
	ibgn = strsearch( str, findStr, 0 )
	
	if ( ibgn < 0 )
		return Nan
	endif
	
	for ( icnt = ibgn+strlen( findStr ); icnt < strlen( str ); icnt += 1 )
		if ( numtype( str2num( str[icnt] ) ) == 0 )
			ibgn = icnt
			break
		endif
	endfor
	
	for ( icnt = ibgn; icnt < strlen( str ); icnt += 1 )
		if ( numtype( str2num( str[icnt] ) ) > 0 )
			break
		endif
	endfor
	
	return str2num( str[ibgn,icnt-1] )

End // GetNumFromStr

//****************************************************************
//
//	UnitsFromStr()
//	find units string from label string
//	units should be in parenthesis, i.e. "Vmem ( mV )"
//	or seperated by space, i.e. "Vmem mV"
//
//****************************************************************

Function /S UnitsFromStr( str )
	String str // string to search
	
	Variable icnt, jcnt
	String units = ""
	
	for ( icnt = strlen( str )-1; icnt >= 0; icnt -= 1 )
	
		if ( StringMatch( str[icnt], ")" ) == 1 )
		
			for ( jcnt = icnt-1; jcnt >= 0; jcnt -= 1 )
				if ( StringMatch( str[jcnt, jcnt], "(" ) == 1 )
					return str[jcnt+1, icnt-1]
				endif
			endfor
			
		endif
		
		if ( strlen( units ) > 0 )
			break
		endif
		
		strswitch( str[icnt, icnt] )
			case " ":
			case ":":
				return str[icnt+1, inf]
		endswitch
		
	endfor
	
	return str
	
End // UnitsFromStr

//****************************************************************
//
//	OhmsUnitsFromStr()
//	find units string from axis label string
//
//****************************************************************

Function /S OhmsUnitsFromStr( str )
	String str // string to search
	
	return CheckOhmsUnits( UnitsFromStr( str ) )
	
End // OhmsUnitsFromStr

//****************************************************************
//
//	CheckOhmsUnits()
//
//****************************************************************

Function /S CheckOhmsUnits( units )
	String units
	
	strswitch( units )
		case "V":
		case "mV":
		case "A":
		case "nA":
		case "pA":
		case "S":
		case "nS":
		case "pS":
		case "Ohms":
		case "MOhms":
		case "MegaOhms":
		case "GOhms":
		case "GigaOhms":
		case "sec":
		case "msec":
		case "ms":
		case "usec":
		case "us":
			break
		default:
			units = ""
	endswitch
	
	return units

End // CheckOhmsUnits

//****************************************************************
//
//	NMReverseList
//
//****************************************************************

Function /S NMReverseList( listStr, listSepStr )
	String listStr, listSepStr
	
	Variable icnt
	String item, outList = ""
	
	for ( icnt = ItemsInList( listStr, listSepStr )-1; icnt >= 0 ; icnt -= 1 )
		item = StringFromList( icnt, listStr, listSepStr )
		outList = AddListItem( item, outList, listSepStr, inf )
	endfor

	return outList

End // NMReverseList

//****************************************************************
//
//	SortWaveListByCreation()
//	Sort a list of waves by their creation date
//
//****************************************************************

Function /S SortWaveListByCreation( wList )
	String wList // wave list ( seperator ";" )
	
	Variable wcnt, creation, minCreation=inf, nwaves = ItemsInList( wList )
	String wName, outList = ""
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	Make /T/O/N=( nwaves ) U_SortWavesNames = ""
	Make /D/O/N=( nwaves ) U_SortWavesDate = inf
	
	for ( wcnt = 0 ; wcnt < nwaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		U_SortWavesNames[ wcnt ] = wName
		
		if ( WaveExists( $wName ) == 1 )
		
			creation = CreationDate( $wName )
			U_SortWavesDate[ wcnt ] = creation
			
			if ( creation < minCreation )
				minCreation = creation
			endif
			
		endif
		
	endfor
	
	U_SortWavesDate -= minCreation
	
	Sort U_SortWavesDate, U_SortWavesDate, U_SortWavesNames
	
	for ( wcnt = 0 ; wcnt < nwaves ; wcnt += 1 )
		outList = AddListItem( U_SortWavesNames[ wcnt ], outList, ";", inf )
	endfor
	
	KillWaves /Z U_SortWavesDate, U_SortWavesNames
	
	return outList

End // SortWaveListByCreation

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAddPathNamePrefix( wName, prefix )
	String wName
	String prefix
	
	if ( strlen( prefix ) == 0 )
		return wName
	endif
	
	String path = ParseFilePath( 1, wName, ":", 1, 0 )
	String wName2 = ParseFilePath( 0, wName, ":", 1, 0 )
	String lastCharacter = wName[ strlen( wName ) - 1 ]
	
	if ( StringMatch( lastCharacter, ":" ) == 0 )
		lastCharacter = ""
	endif
	
	return path + prefix + wName2 + lastCharacter
	
End // NMAddPathNamePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetPathName( fullpath, option )
	String fullpath // full-path name (i.e. "root:folder0:stats")
	Variable option // (0) return string containing folder or variable name (i.e. "stats") ( 1 ) return string containing path (i.e. "root:folder0:")
	
	if ( option == 1 )
		return ParseFilePath( 1, fullpath, ":", 1, 0 )
	else
		return ParseFilePath( 0, fullpath, ":", 1, 0 )
	endif

End // GetPathName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LastPathColon( fullpath, yes )
	String fullpath
	Variable yes // check path (0) has no trailing colon ( 1 ) has trailing colon
	
	if ( yes == 1 )
		return ParseFilePath( 2, fullpath, ":", 0, 0 )
	else
		return RemoveEnding( fullpath, ":" )
	endif

End // LastPathColon

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCheckFullPath( path )
	String path
	
	if ( StringMatch( path[0,4], "root:" ) == 0 )
		path = GetDataFolder( 1 ) + path
	endif
	
	return ParseFilePath( 2, path, ":", 0, 0 )
	
End // NMCheckFullPath

//****************************************************************
//
//	Igor-timed clock functions
//
//****************************************************************

Function NMWait( t )
	Variable t
	
	if ( ( numtype( t ) > 0 ) || ( t <= 0 ) )
		return 0
	endif
	
	return NMWaitMSTimer( t )
	
End // NMWait

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaitTicks( t ) // wait t msec ( only accurate to 17 msec )
	Variable t
	
	if ( ( numtype( t ) > 0 ) || ( t <= 0 ) )
		return 0
	endif
	
	Variable t0 = ticks
	
	t *= 60 / 1000

	do
	while ( ticks - t0 < t )
	
	return 0
	
End // NMWaitTicks

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaitMSTimer( t ) // wait t msec ( this is more accurate )
	Variable t
	
	if ( ( numtype( t ) > 0 ) || ( t <= 0 ) )
		return 0
	endif
	
	Variable t0 = stopMSTimer( -2 )
	
	t *= 1000 // convert to usec
	
	do
	while ( stopMSTimer( -2 ) - t0 < t )
	
	return 0
	
End // NMWaitMSTimer

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMakeTestWaves( nchan, nwaves, npnts, dx )
	Variable nchan
	Variable nwaves
	Variable npnts
	Variable dx

	Variable icnt, jcnt, offset, total = npnts * dx
	Variable delay = 0
	String wName
	
	//for (jcnt=0;jcnt<nwaves;jcnt+=1)
	for (jcnt=nwaves-1;jcnt>=0;jcnt-=1)
		
		for (icnt=0;icnt<nchan;icnt+=1)
		
			wName = GetWaveName( "Record", icnt, jcnt )
		
			Make /O/N=(npnts) $wName
			
			offset = total*gnoise(1) / 20
			
			Setscale /P x offset, dx, $wName
		
			Wave w = $wName
		
			w = gnoise(1)
			
		endfor
		
		//ClampWaitMSTimer( delay ) // inter-rep time
	
	endfor
	
	//NMPrefixSelect( "Record" )

End // NMMakeTestWaves

//****************************************************************
//
//	UNUSED FUNCTIONS - FUTURE DEPRECATION
//
//****************************************************************

Function DeleteNANs( wName, yname, xflag ) // NOT USED ANYMORE
	String wName // input wave name
	String yname // output wave name
	Variable xflag // ( 0 ) no x wave ( 1 ) compute x wave
	
	String thisfxn = "DeleteNANs"
	
	//NMDeprecated( "DeleteNANs", "WaveTransform" )
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return -1
	endif
	
	WaveStats /Q/Z $wName
	
	Variable numNans = V_numNaNs
	
	if ( numNans == 0 )
		return 0 // nothing to do
	endif
	
	String xname = yname + "_X"
	
	Duplicate /O $wName $yname, $xname
	
	Wave xwave = $xname
	Wave ywave = $yname
	
	xwave = x * ( ( ywave + 1 ) / ( ywave + 1 ) )
	
	Sort xwave ywave, xwave
	
	WaveStats /Q/Z xwave
	
	Redimension /N=( V_maxloc+1 ) xwave, ywave // eliminate NANs
	
	Note $xname, "Func:" + thisfxn
	
	if ( xflag == 0 )
		KillWaves /Z $xname
	endif
	
	Note $yname, "Func:" + thisfxn
	
	return 0

End // DeleteNANs

//****************************************************************
//
//	FindStim()
//	find stimulus artifact times
//
//****************************************************************

Function FindStim( wName, tbin, conf ) // NOT USED
	String wName // wave name
	Variable tbin // time bin size ( e.g. 1 ms )
	Variable conf // % confidence from max value ( e.g. 95 )
	
	Variable tlimit = 0.1 // limit of stim width
	Variable absmax, absmin, icnt, jcnt
	String thisfxn = "FindStim"
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return -1
	endif
	
	if ( ( tbin < 0 ) || ( conf <= 0 ) || ( conf > 100 ) || ( numtype( tbin*conf ) != 0 ) )
		return -1
	endif
	
	Duplicate /O $wName U_WaveTemp
	Differentiate U_WaveTemp
	WaveStats /Q/Z U_WaveTemp
	
	absmax = abs( V_max - V_avg )
	absmin = abs( V_min - V_avg )
	
	if ( absmax > absmin )
		Findlevels /Q U_WaveTemp, ( V_avg + absmax*conf/100 )
	else
		Findlevels /Q U_WaveTemp, ( V_avg - absmin*conf/100 )
	endif
	
	if ( V_Levelsfound == 0 )
		return -1
	endif
	
	Wave W_FindLevels
	
	Make /O/N=( V_Levelsfound/2 ) U_StimTimes
	
	for ( icnt = 0; icnt < V_Levelsfound-1;icnt += 2 )
		if ( W_FindLevels[1] - W_FindLevels[0] <= tlimit )
			U_StimTimes[jcnt] = floor( W_FindLevels[icnt]/tbin ) * tbin
			jcnt += 1
		endif
	endfor
	
	Note U_StimTimes, "Func:" + thisfxn
	Note U_StimTimes, "Source:" + wName
	
	KillWaves /Z U_WaveTemp, W_FindLevels
	
	return 0

End // FindStim

//****************************************************************
//****************************************************************
//****************************************************************