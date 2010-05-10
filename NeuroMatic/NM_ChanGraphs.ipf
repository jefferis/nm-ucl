#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Channel Graph Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	Began 5 May 2002
//
//	Functions for displaying and maintaining channel graphs
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDF( chanNum ) // channel folder path
	Variable chanNum // ( -1 ) for current channel
	
	String cdf = ChanDFname( chanNum )
	
	if ( ( strlen( cdf ) == 0 ) || ( DataFolderExists( cdf ) == 0 ) )
		return ""
	endif
	
	return cdf
	
End // ChanDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDFname( chanNum )
	Variable chanNum
	
	String prefixFolder = CurrentNMPrefixFolder()
	String gname = ChanGraphName( chanNum )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	return prefixFolder + gname + ":"
	
End // ChanDFname

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanGraphPrefix()

	return "Chan"

End // ChanGraphPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentChanGraphName()

	return ChanGraphName( -1 )
	
End // CurrentChanGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanGraphName( chanNum )
	Variable chanNum
	
	chanNum = ChanNumCheck( chanNum )
	
	return GetGraphName( ChanGraphPrefix(),  chanNum)
	
End // ChanGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function IsChanGraph( gname )
	String gname
	
	if ( ( strlen( gname ) > 0 ) && ( strsearch( gname, ChanGraphPrefix(), 0, 2 ) == 0 ) )
		return 1
	endif

	return 0
	
End // IsChanGraph

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDisplayWave( chanNum )
	Variable chanNum
	
	return ChanDisplayWaveName( 1, chanNum, 0 )
	
End // ChanDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDisplayWaveName( directory, chanNum, wavNum )
	Variable directory // ( 0 ) no directory ( 1 ) include directory
	Variable chanNum
	Variable wavNum
	
	String df = ""
	
	if ( directory == 1 )
		df = NMDF()
	endif
	
	
	return df + GetWaveName( "Display", ChanNumCheck( chanNum ), wavNum )
	
End // ChanDisplayWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckChanSubFolder( chanNum )
	Variable chanNum // ( -1 ) for all
	
	Variable snum, ccnt, cbgn = chanNum, cend = chanNum
	String cdf
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanDFname( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		if ( DataFolderExists( cdf ) == 0 )
			NewDataFolder $RemoveEnding( cdf, ":" )
		endif
		
		CheckNMvar( cdf+"SmoothN",  0 )
		CheckNMvar( cdf+"Overlay", 0 )
	
	endfor

End // CheckChanSubFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSubFolderDefaultsSet( chanNum )
	Variable chanNum // ( -1 ) for all
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String cdf
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanDFname( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		if ( DataFolderExists( cdf ) == 0 )
			NewDataFolder $RemoveEnding( cdf, ":" )
		endif
		
		SetNMvar( cdf+"SmoothN", 0 ) // Smooth and Filter parameter number
		SetNMstr( cdf+"SmoothA", "" ) // Smooth and Filter algorithm
		SetNMvar( cdf+"Overlay", 0 )
		SetNMvar( cdf+"Ft", 0 )
		SetNMvar( cdf+"AutoScale", 1 )
		SetNMvar( cdf+"AutoScaleX", 0 )
		SetNMvar( cdf+"AutoScaleY", 0 )
	
	endfor

End // ChanSubFolderDefaultsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFolderCopy( chanNum, fromDF, toDF, saveScales )
	Variable chanNum // ( -1 ) for all
	String fromDF, toDF
	Variable saveScales
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
		
		if ( DataFolderExists( fromDF+ChanGraphName( ccnt ) ) == 0 )
			continue
		endif
	
		if ( DataFolderExists( toDF+ChanGraphName( ccnt ) ) == 1 )
			KillDataFolder $( toDF+ChanGraphName( ccnt ) )
		endif
		
		if ( saveScales == 1 )
			ChanScaleSave( ccnt )
		endif
		
		DuplicateDataFolder $( fromDF+ChanGraphName( ccnt ) ), $( toDF+ChanGraphName( ccnt ) )
		
	endfor

End // ChanFolderCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphMake( chanNum ) // create channel display graph
	Variable chanNum // channel number

	Variable scale, grid, y0 = 8
	Variable gx0, gy0, gx1, gy1
	String cdf, tcolor
	
	Variable r = NMPanelRGB( "r" )
	Variable g = NMPanelRGB( "g" )
	Variable b = NMPanelRGB( "b" )
	
	chanNum = ChanNumCheck( chanNum )
	
	String cc = num2istr( chanNum )
	
	String computer = NMComputerType()
	
	String gname = ChanGraphName( chanNum )
	String wname = ChanDisplayWave( chanNum )
	String xWave = NMXwave()
	
	CheckChanSubFolder( chanNum )
	cdf = ChanDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	tcolor = StrVarOrDefault( cdf+"TraceColor", "0,0,0" )
	
	ChanGraphSetCoordinates( chanNum )
	
	gx0 = NumVarOrDefault( cdf+"GX0", Nan )
	gy0 = NumVarOrDefault( cdf+"GY0", Nan )
	gx1 = NumVarOrDefault( cdf+"GX1", Nan )
	gy1 = NumVarOrDefault( cdf+"GY1", Nan )
	
	if ( numtype( gx0 * gy1 * gx1 * gy1 ) > 0 )
		return 0
	endif
	
	Make /O $wname = Nan
	
	// kill waves that conflict with graph name
	
	if ( WinType( gname ) != 0 )
		DoWindow /K $gname
	endif
	
	if ( WaveExists( $Xwave ) == 1 )
		Display /N=$gname/W=( gx0,gy0,gx1,gy1 )/K=1 $wname vs $xWave
	else
		Display /N=$gname/W=( gx0,gy0,gx1,gy1 )/K=1 $wname
	endif
		
	ModifyGraph /W=$gname standoff( left )=0, standoff( bottom )=0
	ModifyGraph /W=$gname margin( left )=55, margin( right )=0, margin( top )=22, margin( bottom )=0
	Execute /Z "ModifyGraph /W=" + gname + " rgb=(" + tcolor + ")"
	ModifyGraph /W=$gname wbRGB = ( r, g, b ), cbRGB = ( r, g, b ) // set margins gray
	
	if ( StringMatch( computer, "mac" ) == 1 )
		y0 = 4
	endif
	
	PopupMenu $( "PlotMenu"+cc ), pos={0,0}, size={15,0}, bodyWidth= 20, mode=1, value=NMChanPopupList(), proc=NMChanPopup, win=$gname
	SetVariable $( "Overlay"+cc ), title="Overlay", pos={90,y0-1}, size={90,50}, limits={0,10,1}, value=$( cdf+"Overlay" ), proc=NMChanSetVariable, win=$gname
	SetVariable $( "SmoothSet"+cc ), title="Filter", pos={210,y0-1}, size={90,50}, limits={0,inf,1}, value=$( cdf+"SmoothN" ), proc=NMChanSetVariable, win=$gname
	CheckBox $( "FtCheck"+cc ), title="Transform", pos={330,y0}, size={16,18}, value=0, proc=NMChanCheckbox, win=$gname
	CheckBox $( "ScaleCheck"+cc ), title="Autoscale", pos={430,y0}, size={16,18}, value=1, proc=NMChanCheckbox, win=$gname
	CheckBox $( "ToFront"+cc ), title="To Front", pos={530,y0}, size={16,18}, value=0, proc=NMChanCheckbox, win=$gname
	
End // ChanGraphMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsUpdate() // update channel display graphs

	Variable ccnt, numChannels = NMNumChannels()
	
	for ( ccnt = 0; ccnt < numChannels; ccnt+=1 )
		ChanGraphUpdate( ccnt, 1 )
		ChanGraphControlsUpdate( ccnt )
	endfor
	
	KillVariables /Z $( NMDF()+"ChanScaleSaveBlock" )

End // ChanGraphsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanGraphUpdate( chanNum, makeWave ) // update channel display graphs
	Variable chanNum // ( -1 ) for current chan
	Variable makeWave // ( 0 ) no ( 1 ) yes
	
	Variable autoscale, count, grid, ft, toFront
	String sName, dname, ddname, gname, fName, info, cdf
	
	Variable scaleblock = NumVarOrDefault( NMDF()+"ChanScaleSaveBlock", 0 )
	
	fname = NMFolderListName( "" )
	
	chanNum = ChanNumCheck( chanNum )
	
	gname = ChanGraphName( chanNum )
	dname = ChanDisplayWave( chanNum ) // display wave
	ddname = GetPathName( dname, 0 )
	sName = NMChanWaveName( chanNum, -1 ) // source wave
	
	CheckChanSubFolder( chanNum )
	cdf = ChanDF( chanNum )
	
	autoscale = NumVarOrDefault( cdf+"AutoScale", 1 )
	toFront = NumVarOrDefault( cdf+"ToFront", 1 )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	if ( NumVarOrDefault( cdf+"On", 1 ) == 0 )
		ChanGraphClose( chanNum, 0 )
		return ""
	endif

	if ( Wintype( gname ) == 0 )
		ChanGraphMake( chanNum )
		scaleblock = 1
	endif
	
	if ( Wintype( gname ) == 0 )
		return ""
	endif
	
	if ( scaleblock == 0 )
		ChanScaleSave( chanNum )
	endif
	
	if ( strlen( fName ) > 0 )
		DoWindow /T $gname, fname + " : Ch " + ChanNum2Char( chanNum ) + " : " + sName
	else
		DoWindow /T $gname, "Ch " + ChanNum2Char( chanNum ) + " : " + sName
	endif

	if ( NumVarOrDefault( cdf+"Overlay", 0 ) > 0 )
		ChanOverlayUpdate( chanNum )
	endif
	
	if ( makeWave == 1 )
		ChanWaveMake( chanNum, sName, dname )
	endif
	
	//ChanGraphControlsUpdate( chanNum )
	
	//if ( numpnts( $dname ) < 0 ) // if waves have Nans, change mode to line+symbol
		
	//	WaveStats /Q $dname
		
	//	count = ( V_numNaNs * 100 / V_npnts )

	//	if ( ( numtype( count ) == 0 ) && ( count > 25 ) )
	//		ModifyGraph /W=$gname mode( $ddname )=4
	//	else
	//		ModifyGraph /W=$gname mode( $ddname )=0
	//	endif
	
	//endif
	
	if ( autoscale == 1 )
		SetAxis /A/W=$gname
	else
		ChanGraphAxesSet( chanNum )
	endif
	
	info = AxisInfo( gname, "bottom" )
	
	if ( strlen( info ) > 0 )
		Label /W=$gname bottom NMChanLabel( chanNum, "x", sName )
	endif
	
	info = AxisInfo( gname, "left" )
	
	if ( strlen( info ) > 0 )
	
		ft = ChanFuncGet( chanNum )
		
		switch( ft )
			case 1:
			case 2:
			case 3:
			case 4:
			case 5:
				Label /W=$gname left ChanFuncNum2Name( ft )
				break
			default:
				Label /W=$gname left NMChanLabel( chanNum, "y", sName )
		endswitch
		
		grid = NumVarOrDefault( cdf+"GridFlag", 1 )
		
		ModifyGraph /W=$gname grid( bottom )=grid, grid( left )=grid, gridRGB=( 24576,24576,65535 )
	
	endif
	
	ChanGraphMove( chanNum )
	
	if ( toFront == 1 )
		DoWindow /F $gname
	endif
	
	return gname

End // ChanGraphsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsRemoveWaves()

	Variable ccnt, numChannels = NMNumChannels()
	
	for ( ccnt = 0; ccnt < numChannels; ccnt+=1 )
		ChanGraphRemoveWaves( ccnt )
	endfor

End // ChanGraphsRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphRemoveWaves( chanNum )
	Variable chanNum
	
	Variable wcnt
	String wname, wList, gname = ChanGraphName( chanNum )
	
	if ( WinType( gname ) != 1 )
		return -1
	endif
	
	wList = TraceNameList( gname, ";", 1 )
	
	for ( wcnt = 0; wcnt < ItemsInlist( wList ); wcnt += 1 )
		wname = StringFromList( wcnt, wList )
		RemoveFromGraph /W=$gname $wname
	endfor
	
	return 0

End // ChanGraphRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsAppendDisplayWave()

	Variable ccnt, numChannels = NMNumChannels()
	
	for ( ccnt = 0; ccnt < numChannels; ccnt+=1 )
		ChanGraphAppendDisplayWave( ccnt )
	endfor

End // ChanGraphsAppendDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphAppendDisplayWave( chanNum )
	Variable chanNum
	
	String cdf = ChanDF( chanNum )
	String gname = ChanGraphName( chanNum )
	String wname = ChanDisplayWave( chanNum )
	String xWave = NMXWave()
	String tcolor = StrVarOrDefault( cdf+"TraceColor", "0,0,0" )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gname ) != 1 ) || ( WaveExists( $wname ) == 0 ) )
		return -1
	endif
	
	if ( WaveExists( $xWave ) == 1 )
		AppendToGraph /W=$gname $wname vs $xWave
	else
		AppendToGraph /W=$gname $wname
	endif
	
	Execute /Z "ModifyGraph /W=" + gname + " rgb=(" + tcolor + ")"

End // ChanGraphAppendDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphControlsUpdate( chanNum )
	Variable chanNum
	
	Variable tofront, autoscale
	
	chanNum = ChanNumCheck( chanNum )
	
	String gname = ChanGraphName( chanNum )
	String cdf = ChanDF( chanNum )
	String cc = num2istr( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	tofront = NumVarOrDefault( cdf+"ToFront", 1 )
	autoscale = NumVarOrDefault( cdf+"AutoScale", 1 )
	
	if ( ( strlen( cdf ) == 0 ) || ( winType( gname ) == 0 ) )
		return 0
	endif
	
	//ChanControlsDisable( chanNum, "000000" ) // turn controls back on
		
	SetVariable $( "Overlay"+cc ), value=$( cdf+"Overlay" ), win=$gname, proc=NMChanSetVariable
	
	CheckBox $( "ScaleCheck"+cc ), value=autoscale, win=$gname, proc=NMChanCheckbox
	CheckBox $( "ToFront"+cc ), value=tofront, win=$gname, proc=NMChanCheckbox
	
	ChanFilterUpdate( chanNum )
	ChanFuncUpdate( chanNum )
	
End // ChanGraphControlsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsReset()

	ChanGraphClose( -2, 0 ) // close unecessary windows
	ChanOverlayKill( -1 ) // kill unecessary waves
	ChanGraphClear( -1 )
	ChanGraphsRemoveWaves()
	ChanGraphsAppendDisplayWave()
	ChanGraphTagsKill( -1 )
	
	SetNeuroMaticVar( "ChanScaleSaveBlock", 1 )

End // ChanGraphsReset

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphTagsKill( chanNum )
	Variable chanNum // ( -1 ) for all
	
	Variable icnt, ccnt, cbgn = chanNum, cend = chanNum
	String gname, aName, aList
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		gname = ChanGraphName( ccnt )
		
		if ( Wintype( gname ) == 0 )
			continue
		endif
		
		alist = AnnotationList( gname ) // list of tags
			
		for ( icnt = 0; icnt < ItemsInList( alist ); icnt += 1 )
			aName = StringFromList( icnt, alist )
			Tag /W=$gname /N=$aName /K // kill tags
		endfor
		
	endfor
	
End // ChanGraphTagsKill

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsToFront()

	Variable ccnt, cbgn, cend = NMNumChannels() - 1
	String gname, cdf
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt+=1 )
		
		cdf = ChanDF( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		if ( NumVarOrDefault( cdf+"ToFront", 1 ) == 1 )
		
			gname = ChanGraphName( ccnt )
			
			if ( WinType( gname ) == 1 )
				DoWindow /F $gname
			endif
			
		endif
		
	endfor
	
End // ChanGraphsToFront

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphAxesSet( chanNum ) // set channel graph size and placement
	Variable chanNum // channel number
	
	chanNum = ChanNumCheck( chanNum )
	
	String gname = ChanGraphName( chanNum )
	String wname = ChanDisplayWave( chanNum )
	String cdf = ChanDF( chanNum )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gname ) != 1 ) )
		return -1
	endif
	
	Variable autoX = NumVarOrDefault( cdf+"AutoScaleX", 0 )
	Variable autoY = NumVarOrDefault( cdf+"AutoScaleY", 0 )
	
	Variable xmin = NumVarOrDefault( cdf+"Xmin", 0 )
	Variable xmax = NumVarOrDefault( cdf+"Xmax", 1 )
	Variable ymin = NumVarOrDefault( cdf+"Ymin", 0 )
	Variable ymax = NumVarOrDefault( cdf+"Ymax", 1 )
	
	if ( autoX == 1 )
		SetAxis /W=$gname/A
		SetAxis /W=$gname left ymin, ymax
		return 0
	elseif ( autoY == 1 )
		WaveStats /Q/R=( xmin,xmax ) $wname
		ymin = V_min
		ymax = V_max
	endif
	
	SetAxis /W=$gname bottom xmin, xmax
	SetAxis /W=$gname left ymin, ymax
		
End // ChanGraphAxesSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsMove()

	Variable ccnt
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt+=1 )
		ChanGraphMove( ccnt )
	endfor

End // ChanGraphsMove

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphMove( chanNum ) // set channel graph size and placement
	Variable chanNum // channel number
	
	chanNum = ChanNumCheck( chanNum )
	
	String cdf = ChanDF( chanNum )
	String gname = ChanGraphName( chanNum )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType ( gname ) != 1 ) )
		return -1
	endif
	
	Variable x0 = NumVarOrDefault( cdf+"GX0", Nan )
	Variable y0 = NumVarOrDefault( cdf+"GY0", Nan )
	Variable x1 = NumVarOrDefault( cdf+"GX1", Nan )
	Variable y1 = NumVarOrDefault( cdf+"GY1", Nan )
	
	if ( ( numtype( x0 * y0 * x1 * y1 ) == 0 ) && ( x1 > x0 ) && ( y0 < y1 ) ) 
		MoveWindow /W=$gname x0, y0, x1, y1
	endif

End // ChanGraphMove

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsResetCoordinates()

	Variable ccnt
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt+=1 )
		ChanGraphResetCoordinates( ccnt )
	endfor

End // ChanGraphsResetCoordinates

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphResetCoordinates( chanNum ) // reset channel graph placement variables
	Variable chanNum // channel number
	
	String cdf = ChanDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	SetNMvar( cdf+"GX0", Nan )
	SetNMvar( cdf+"GY0", Nan )
	SetNMvar( cdf+"GX1", Nan )
	SetNMvar( cdf+"GY1", Nan )
	
	ChanGraphSetCoordinates( chanNum )
	
	ChanGraphMove( chanNum )

End // ChanGraphResetCoordinates

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphSetCoordinates( chanNum ) // set channel graph placement variables
	Variable chanNum // channel number
	
	Variable yinc, width, height, numchan, ccnt, where
	Variable xoffset, yoffset // default offsets
	
	chanNum = ChanNumCheck( chanNum )
	
	String  cdf = ChanDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	Variable x0 = NumVarOrDefault( cdf+"GX0", Nan )
	Variable y0 = NumVarOrDefault( cdf+"GY0", Nan )
	Variable x1 = NumVarOrDefault( cdf+"GX1", Nan )
	Variable y1 = NumVarOrDefault( cdf+"GY1", Nan )
	
	Variable yPixels =  NMComputerPixelsY()
	String Computer = NMComputerType()
	
	numchan = NMNumChannels()
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt+=1 )
	
		cdf = ChanDF( ccnt )
		
		if ( ( strlen( cdf ) > 0 ) && ( NumVarOrDefault( cdf+"On", 1 ) == 0 ) )
			numchan -= 1
		endif
		
	endfor
	
	for ( ccnt = 0; ccnt < chanNum; ccnt+=1 )
		
		cdf = ChanDF( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		if ( NumVarOrDefault( cdf+"On", 1 ) == 1 )
			where += 1
		endif
		
	endfor
	
	cdf = ChanDF( chanNum )
	
	if ( numtype( x0 * y0 * x1 * y1 ) > 0 ) // compute graph coordinates
	
		strswitch( Computer )
			case "pc":
				x0 = 5
				y0 = 37
				width = 522
				height = yPixels / ( numchan + 2 )
				yinc = height + 20
				break
			default:
				x0 = 10
				y0 = 44
				width = 690
				height = yPixels / ( numchan + 2 )
				yinc = height + 25
				break
		endswitch
		
		x0 += xoffset
		y0 += yoffset + yinc*where
		x1 = x0 + width
		y1 = y0 + height
		
		SetNMvar( cdf+"GX0", x0 )
		SetNMvar( cdf+"GY0", y0 )
		SetNMvar( cdf+"GX1", x1 )
		SetNMvar( cdf+"GY1", y1 )
	
	endif

End // ChanGraphSetCoordinates

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphClose( chanNum, KillFolders )
	Variable chanNum // ( -1 ) for all ( -2 ) all unecessary
	Variable KillFolders // to kill global variables

	Variable ccnt, cbgn = chanNum, cend = chanNum
	String gname, wname, cdf, ndf = NMDF()
	
	if ( NumVarOrDefault( ndf+"ChanGraphCloseBlock", 0 ) == 1 )
		//KillVariables /Z $( ndf+"ChanGraphCloseBlock" )
		return 0
	endif
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = 9
	elseif ( chanNum == -2 )
		cbgn = NMNumChannels()
		cend = cbgn + 10
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanDF( ccnt )
		gname = ChanGraphName( ccnt )
		wname = ChanDisplayWave( ccnt )
		
		if ( WinType( gname ) == 1 )
			DoWindow /K $gname
		endif
		
		if ( ( KillFolders == 1 ) && ( strlen( cdf ) > 0 ) && ( DataFolderExists( cdf ) == 1 ) )
			KillDataFolder $RemoveEnding( cdf, ":" )
		endif
		
	endfor
	
	return 0

End // ChanGraphClose

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphClear( chanNum )
	Variable chanNum // ( -1 ) for all
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String wname
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = 9
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		wname = ChanDisplayWave( ccnt )
		
		ChanOverlayClear( ccnt )
		
		if ( WaveExists( $wname ) == 1 )
			Wave wtemp = $wname
			wtemp = Nan
		endif
		
	endfor

End // ChanGraphClear

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanControlsDisable( chanNum, select )
	Variable chanNum // ( -1 ) for all
	String select // Overlay, Filter, Transform, autoscale, PlotMenu, ToFront ( e.g. "11111" for all )
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String cc, gname
	
	select += "000000"
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
		
		cc = num2istr( ccnt )
		gname = ChanGraphName( ccnt )
		
		if ( WinType( gname ) != 1 )
			continue
		endif
	
		SetVariable $( "Overlay"+cc ), disable=binarycheck( str2num( select[0,0] ) ), win=$gname
		SetVariable $( "SmoothSet"+cc ), disable=binarycheck( str2num( select[1,1] ) ), win=$gname
		CheckBox $( "FtCheck"+cc ), disable=binarycheck( str2num( select[2,2] ) ), win=$gname
		CheckBox $( "ScaleCheck"+cc ), disable=binarycheck( str2num( select[3,3] ) ), win=$gname
		PopupMenu $( "PlotMenu"+cc ), disable=binarycheck( str2num( select[4,4] ) ), win=$gname
		CheckBox $( "ToFront"+cc ), disable=binarycheck( str2num( select[5,5] ) ), win=$gname
		
	endfor
	
	return 0

End // ChanControlsDisable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanControlPrefix( ctrlName )
	String ctrlName
	
	Variable icnt
	
	for ( icnt = strlen( ctrlName )-1; icnt > 0; icnt -= 1 )
		if ( numtype( str2num( ctrlName[icnt,icnt] ) ) > 0 )
			break
		endif
	endfor
	
	return ctrlName[0,icnt]

End // ChanControlPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanPopup( ctrlName, popNum, popStr ) : PopupMenuControl // display graph menu
	String ctrlName; Variable popNum; String popStr
	
	Variable chanNum
	
	sscanf ctrlName, "PlotMenu%f", chanNum // determine chan number
	
	PopupMenu $ctrlName, mode=1 // reset the drop-down menu
	
	ChanCall( popStr, chanNum, "" )

End // NMChanPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanPopupList()
	Variable chanNum

	return " ;Grid;Drag;XLabel;YLabel;FreezeX;FreezeY;Reset Position;Off;"

End // NMChanPopupList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanCheckbox( ctrlName, checked ) : CheckBoxControl // change differentiation flag
	String ctrlName; Variable checked
	
	Variable chanNum, rvalue
	String numstr = num2istr( checked )
	String cname = ChanControlPrefix( ctrlName )
	
	sscanf ctrlName, cname + "%f", chanNum // determine chan number
	
	return ChanCall( cname, chanNum, numstr )

End // NMChanCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	Variable chanNum, rvalue
	
	strswitch( ChanControlPrefix( ctrlName ) )
	
		case "SmoothSet":
			sscanf ctrlName, "SmoothSet%f", chanNum // determine chan number
			return ChanCall( "Filter", chanNum, varStr )

		case "Overlay":
			sscanf ctrlName, "Overlay%f", chanNum // determine chan number
			return ChanCall( "Overlay", chanNum, varStr )
	
	endswitch
	
End // NMChanSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanCall( fxn, chanNum, select )
	String fxn
	Variable chanNum
	String select
	
	Variable snum = str2num( select )

	strswitch( fxn )
	
		case "Grid":
			return ChanGridToggle( chanNum )
			
		case "XLabel":
			return ChanLabelCall( chanNum, "x" )
			
		case "YLabel":
			return ChanLabelCall( chanNum, "y" )
			
		case "FreezeX":
			return ChanAutoScaleY( chanNum, 1 )
		
		case "FreezeY":
			return ChanAutoScaleX( chanNum, 1 )
			
		case "Reset Position":
			return ChanGraphResetCoordinates( chanNum )
			
		case "Drag":
			return ChanDragToggle()

		case "Off":
			return ChanOnCall( chanNum, 0 )
			
		case "Overlay":
			return ChanOverlayCall( chanNum, snum )
			
		case "Filter":
			return ChanFilterNumCall( chanNum, snum )
			
		case "AutoScale":
		case "ScaleCheck":
			return ChanAutoScaleCall( chanNum, snum )
			
		case "ToFront":
			return ChanToFrontCall( chanNum, snum )
			
		case "F(t)":
		case "F( t )":
		case "FtCheck":
		case "Transform":
			return ChanFuncCall( chanNum, -snum )
			
		default:
			NMDoAlert( "ChanCall: unrecognized function call: " + fxn )
	
	endswitch
	
End // ChanCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFuncDF( chanNum )
	Variable chanNum
	
	chanNum = ChanNumCheck( chanNum )
	
	return StrVarOrDefault( NMDF() + "ChanFuncDF" + num2istr( chanNum ), ChanDF( chanNum ) )

End // ChanFuncDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFuncProc( chanNum )
	Variable chanNum
	
	chanNum = ChanNumCheck( chanNum )
	
	return StrVarOrDefault( NMDF() + "ChanFuncProc" + num2istr( chanNum ), "NMChanCheckbox" )

End // ChanFuncProc

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncCall( chanNum, ft )
	Variable chanNum // channel number
	Variable ft
	
	String vlist = ""
	
	if ( ft < 0 )
		ft = ChanFuncAsk( chanNum )
	endif
	
	switch( ft )
	
		case 0:
		case 1:
		case 2:
		case 3:
	
			vlist = NMCmdNum( chanNum, vlist )
			vlist = NMCmdNum( ft, vlist )
			NMCmdHistory( "ChanFunc", vlist )
			
			return ChanFunc( chanNum, ft )
		
		case 4:
		case 5:
		case 6:
			return ft
		
	endswitch
	
	ChanGraphsUpdate()
	
	return -1

End // ChanFuncCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncAsk( chanNum ) // request chan transform function
	Variable chanNum
	
	chanNum = ChanNumCheck( chanNum )
	
	Variable ft = ChanFuncGet( chanNum )
	
	Prompt ft, "choose function:", popup ChanFuncList()
	DoPrompt "Channel Wave Transform", ft
	
	if ( V_flag == 1 )
		ft = -1 // cancel
	endif
	
	switch( ft )
		case 4:
			ft = NMChanFuncNormalizeCall( chanNum )
			break
		case 5:
			ft = NMChanFuncDFOFCall( chanNum )
			break
		case 6:
			ft = NMChanFuncBaselineCall( chanNum )
			break
	endswitch
	
	return ft

End // ChanFuncAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFunc( chanNum, ft ) // set chan transform function
	Variable chanNum // channel number
	Variable ft // ( 0 ) none ( 1 ) d/dt ( 2 ) dd/dt*dt ( 3 ) integral ( 4 ) norm ( 5 ) dF/Fo ( 6 ) baseline
	
	String cdf, thisfxn = "ChanFunc"
	String fxnList = ChanFuncList()
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ( numtype( ft ) > 0 ) || ( ft < 0 ) || ( ft > ItemsInList( fxnList ) ) )
		return -1
	endif
	
	switch( ft )
		case 4:
			NMDoAlert( "ChanFunc Error: please use " + NMQuotes( "NMChanFuncNormalize" ) + " for this channel transformation." )
			return -1
		case 5:
			NMDoAlert( "ChanFunc Error: please use " + NMQuotes( "NMChanFuncDFOF" ) + " for this channel transformation." )
			return -1
		case 6:
			NMDoAlert( "ChanFunc Error: please use " + NMQuotes( "NMChanFuncBaseline" ) + " for this channel transformation." )
			return -1
	endswitch
	
	cdf =  ChanFuncDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	SetNMVar( cdf+"Ft", ft )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return 0

End // ChanFunc

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanFuncNormalizeCall( chanNum )
	Variable chanNum
	
	chanNum = ChanNumCheck( chanNum )
	
	String vlist = ""
	String cdf = ChanFuncDF( chanNum ) 
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	if ( NMNormalizeCall( cdf ) < 0 )
		return -1 // cancel
	endif
	
	String fxn1 = StrVarOrDefault( cdf+"Norm_Fxn1", "Avg" )
	
	Variable tbgn1 = NumVarOrDefault( cdf+"Norm_Tbgn1", 0 )
	Variable tend1 = NumVarOrDefault( cdf+"Norm_Tend1", 5 )
	
	String fxn2 = StrVarOrDefault( cdf+"Norm_Fxn2", "Max" )
	
	Variable tbgn2 = NumVarOrDefault( cdf+"Norm_Tbgn2", -inf )
	Variable tend2 = NumVarOrDefault( cdf+"Norm_Tend2", inf )
	
	vList = NMCmdNum( chanNum, vList )
	vList = NMCmdStr( fxn1, vList )
	vList = NMCmdNum( tbgn1, vList )
	vList = NMCmdNum( tend1, vList )
	vList = NMCmdStr( fxn2, vList )
	vList = NMCmdNum( tbgn2, vList )
	vList = NMCmdNum( tend2, vList )
	NMCmdHistory( "NMChanFuncNormalize", vList )
	
	return NMChanFuncNormalize( chanNum, fxn1, tbgn1, tend1, fxn2, tbgn2, tend2 )

End // NMChanFuncNormalizeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanFuncNormalize( chanNum, fxn1, tbgn1, tend1, fxn2, tbgn2, tend2 )
	Variable chanNum // channel number
	String fxn1 // function to compute min value, "avg" or "min" or "minavg"
	Variable tbgn1, tend1 // time begin and end, use ( -inf, inf ) for all time
	String fxn2 // function to compute max value, "avg" or "max" or "maxavg"
	Variable tbgn2, tend2 // time begin and end, use ( -inf, inf ) for all time
	
	Variable win1, win2, fxnNum = 4
	String cdf, thisfxn = "NMChanFuncNormalize"
	
	chanNum = ChanNumCheck( chanNum )
	
	cdf = ChanFuncDF( chanNum )
	
	win1 = GetNumFromStr( fxn1, "MinAvg" )
	win2 = GetNumFromStr( fxn2, "MaxAvg" )
	
	strswitch( fxn1 )
		case "Min":
		case "Avg":
			break
		default:
			if ( numtype( win1 ) > 0 )
				return NMError( 20, thisfxn, "fxn1", fxn1 )
			endif
	endswitch
	
	if ( numtype( tbgn1 ) > 0 )
		tbgn1 = -inf
	endif
	
	if ( numtype( tend1 ) > 0 )
		tend1 = inf
	endif
	
	strswitch( fxn2 )
		case "Max":
		case "Avg":
			break
		default:
			if ( numtype( win2 ) > 0 )
				return NMError( 20, thisfxn, "fxn2", fxn2 )
			endif
	endswitch
	
	if ( numtype( tbgn2 ) > 0 )
		tbgn2 = -inf
	endif
	
	if ( numtype( tend2 ) > 0 )
		tend2 = inf
	endif
	
	SetNMVar( cdf+"Ft", fxnNum )
	
	SetNMstr( cdf+"Norm_Fxn1", fxn1 )
	SetNMvar( cdf+"Norm_Tbgn1", tbgn1 )
	SetNMvar( cdf+"Norm_Tend1", tend1 )
	
	SetNMstr( cdf+"Norm_Fxn2", fxn2 )
	SetNMvar( cdf+"Norm_Tbgn2", tbgn2 )
	SetNMvar( cdf+"Norm_Tend2", tend2 )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return fxnNum
	
End // NMChanFuncNormalize

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanFuncDFOFCall( chanNum )
	Variable chanNum
	
	Variable tbgn, tend
	String vlist = "", cdf, mdf = MainDF()
	
	chanNum = ChanNumCheck( chanNum )
	
	cdf = ChanFuncDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	tbgn = NumVarOrDefault( mdf+"Bsln_Bgn", 0 )
	tend = NumVarOrDefault( mdf+"Bsln_End", 5 )
	
	tbgn = NumVarOrDefault( cdf+"DFOF_Bbgn", tbgn )
	tend = NumVarOrDefault( cdf+"DFOF_Bend", tend )
	
	Prompt tbgn, "compute baseline from (ms):"
	Prompt tend, "compute baseline to (ms):"
	
	DoPrompt "dF/Fo", tbgn, tend
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	SetNMvar( cdf+"DFOF_Bbgn", tbgn )
	SetNMvar( cdf+"DFOF_Bend", tend )
	
	vList = NMCmdNum( chanNum, vList )
	vList = NMCmdNum( tbgn, vList )
	vList = NMCmdNum( tend, vList )
	NMCmdHistory( "NMChanFuncDFOF", vList )
	
	return NMChanFuncDFOF( chanNum, tbgn, tend )

End // NMChanFuncDFOFCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanFuncDFOF( chanNum, tbgn, tend )
	Variable chanNum // channel number
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	
	Variable fxnNum = 5
	String cdf, thisfxn = "NMChanFuncDFOF"
	
	chanNum = ChanNumCheck( chanNum )
	
	cdf = ChanFuncDF( chanNum )
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	SetNMVar( cdf+"Ft", fxnNum )
	SetNMvar( cdf+"DFOF_Bbgn", tbgn )
	SetNMvar( cdf+"DFOF_Bend", tend )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return fxnNum
	
End // NMChanFuncDFOF

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanFuncBaselineCall( chanNum )
	Variable chanNum
	
	Variable tbgn, tend
	String vlist = "", cdf, mdf = MainDF()
	
	chanNum = ChanNumCheck( chanNum )
	cdf = ChanFuncDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	tbgn = NumVarOrDefault( mdf+"Bsln_Bgn", 0 )
	tend = NumVarOrDefault( mdf+"Bsln_End", 5 )
	
	tbgn = NumVarOrDefault( cdf+"Bsln_Bbgn", tbgn )
	tend = NumVarOrDefault( cdf+"Bsln_Bend", tend )
	
	Prompt tbgn, "compute baseline from (ms):"
	Prompt tend, "compute baseline to (ms):"
	
	DoPrompt "Baseline", tbgn, tend
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	SetNMvar( cdf+"Bsln_Bbgn", tbgn )
	SetNMvar( cdf+"Bsln_Bend", tend )
	
	vList = NMCmdNum( chanNum, vList )
	vList = NMCmdNum( tbgn, vList )
	vList = NMCmdNum( tend, vList )
	NMCmdHistory( "NMChanFuncBaseline", vList )
	
	return NMChanFuncBaseline( chanNum, tbgn, tend )

End // NMChanFuncBaselineCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanFuncBaseline( chanNum, tbgn, tend )
	Variable chanNum // channel number
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	
	Variable fxnNum = 6
	String cdf, thisfxn = "NMChanFuncBaseline"
	
	chanNum = ChanNumCheck( chanNum )
	
	cdf = ChanFuncDF( chanNum )
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	SetNMVar( cdf+"Ft", fxnNum )
	SetNMvar( cdf+"Bsln_Bbgn", tbgn )
	SetNMvar( cdf+"Bsln_Bend", tend )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return fxnNum
	
End // NMChanFuncBaseline

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncGet( chanNum )
	Variable chanNum
	
	String cdf = ChanFuncDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return 0
	endif
	
	return NumVarOrDefault( cdf+"Ft", 0 )
	
End // ChanFuncGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFuncGetName( chanNum )
	Variable chanNum

	return ChanFuncNum2Name( ChanFuncGet( chanNum ) )

End // ChanFuncGetName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFuncNum2Name( select )
	Variable select

	switch( select )
		case 0:
			return "Transform"
		case 1:
			return "d/dt"
		case 2:
			return "dd/dt*dt"
		case 3:
			return "Integral"
		case 4:
			return "Normalize"
		case 5:
			return "dF/Fo"
		case 6:
			return "Baseline"
	endswitch
	
	return ""
	
End // ChanFuncNum2Name

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFuncList()

	Variable icnt
	String fxn, fList = ""
	
	for ( icnt = 1 ; icnt < 20 ; icnt += 1 )
	
		fxn =  ChanFuncNum2Name( icnt )
		
		if ( strlen( fxn ) == 0 )
			break
		endif
	
		fList += fxn + ";"
		
	endfor
	
	return fList

End // ChanFuncList

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncUpdate( chanNum )
	Variable chanNum
	
	Variable v = 0
	String t = "Transform"
	
	chanNum = ChanNumCheck( chanNum )
	
	String gname = ChanGraphName( chanNum )
	String cc = num2istr( chanNum )
	
	Variable ft = ChanFuncGet( chanNum )
	
	if ( WinType( gname ) != 1 )
		return -1
	endif
	
	ControlInfo /W=$gname $( "FtCheck"+cc )
	
	if ( V_flag == 0 )
		return 0
	endif
	
	if ( ft > 0 )
		v = 1
		t = ChanFuncNum2Name( ft )
	endif
	
	if ( strlen( t ) == 0 )
		v = 0
		t = "Transform"
	endif
	
	CheckBox $( "FtCheck"+cc ), value=v, title=t, win=$gname, proc=$ChanFuncProc( chanNum )
	
End // ChanFuncUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFilterDF( chanNum )
	Variable chanNum
	
	chanNum = ChanNumCheck( chanNum )
	
	return StrVarOrDefault( NMDF() + "ChanSmthDF" + num2istr( chanNum ), ChanDF( chanNum ) )

End // ChanFilterDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFilterProc( chanNum )
	Variable chanNum
	
	chanNum = ChanNumCheck( chanNum )
	
	return StrVarOrDefault( NMDF() + "ChanSmthProc" + num2istr( chanNum ), "NMChanSetVariable" )

End // ChanFilterProc

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFilterNumGet( chanNum )
	Variable chanNum
	
	String cdf = ChanFilterDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return 0
	endif
	
	return NumVarOrDefault( cdf+"SmoothN", 0 ) // filter number saved as old smooth number
	
End // ChanFilterNumGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFilterFxnList()

	return "binomial;boxcar;low-pass;high-pass;"

End // ChanFilterFxnList

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFilterNumCall( chanNum, filterNum )
	Variable chanNum, filterNum
	
	Variable rvalue
	
	String alg = "", vlist = ""
	String filterAlg = ChanFilterAlgGet( chanNum )
	
	if ( ( strlen( filterAlg ) == 0 ) && ( filterNum > 0 ) )
	
		alg = ChanFilterAlgAsk( chanNum )
		
		strswitch( alg )
			case "binomial":
			case "boxcar":
			case "low-pass":
			case "high-pass":
				filterAlg = alg
				break
			default: // cancel
				filterNum = 0
		endswitch
		
	endif
	
	if ( filterNum <= 0 )
		filterAlg = ""
	endif
	
	vlist = NMCmdNum( chanNum, "" )
	vlist = NMCmdStr( filterAlg, vlist )
	vlist = NMCmdNum( filterNum, vlist )
	NMCmdHistory( "ChanFilter", vlist )
		
	rvalue = ChanFilter( chanNum, filterAlg, filterNum )
	
	NMAutoTabCall()
	
	return rvalue

End // ChanFilterNumCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFilter( chanNum, filterAlg, filterNum ) // set channel filter function
	Variable chanNum
	String filterAlg
	Variable filterNum
	
	String cdf = ChanFilterDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	strswitch( filterAlg )
	
		case "binomial": // smooth
		case "boxcar": // smooth
			break
			
		case "low-pass": // filter FIR
		case "high-pass": // filter FIR
			break
			
		default:
			filterAlg = ""
			
	endswitch
	
	if ( filterNum == 0 )
		filterAlg = ""
	endif
	
	SetNMvar( cdf+"SmoothN", filterNum ) // save as Smooth
	SetNMstr( cdf+"SmoothA", filterAlg )
	
	ChanGraphsUpdate()
	
	return 0

End // ChanFilter

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFilterAlgAsk( chanNum ) // request chan smooth or filter alrgorithm
	Variable chanNum // ( -1 ) for current channel
	
	String cdf, alg, gname
	
	String s1 = "smooth binomial"
	String s2 = "smooth boxcar"
	String f1 = "low-pass Butterworth filter (kHz)"
	String f2 = "high-pass Butterworth filter (kHz)"
	String slist = s1 + ";" + s2 + ";"
	
	chanNum = ChanNumCheck( chanNum )
	cdf = ChanFilterDF( chanNum )
	
	alg = ChanFilterAlgGet( chanNum )
	gname = ChanGraphName( chanNum )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gname ) != 1 ) )
		return ""
	endif
	
	strswitch( alg )
		case "binomial":
			alg = s1
			break
		case "boxcar":
			alg = s2
			break
		case "low-pass":
			alg = f1
			break
		case "high-pass":
			alg = f2
			break
		default:
			alg = s1
	endswitch
	
	slist = s1 + ";" + s2 + ";" + f1 + ";" + f2 + ";"
	
	Prompt alg, " ", popup slist
	
	DoPrompt "Select Algorithm", alg
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( StringMatch( alg, s1 ) == 1 )
		alg = "binomial"
	elseif ( StringMatch( alg, s2 ) == 1 )
		alg = "boxcar"
	elseif ( StringMatch( alg, f1 ) == 1 )
		alg = "low-pass"
	elseif ( StringMatch( alg, f2 ) == 1 )
		alg = "high-pass"
	else
		alg = ""
	endif
	
	return alg

End // ChanFilterAlgAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFilterAlgGet( chanNum ) // get chan smooth/filter alrgorithm
	Variable chanNum // ( -1 ) for current channel
	
	String alg
	
	String cdf = ChanFilterDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif

	alg = StrVarOrDefault( cdf+"SmoothA", "" )
	
	strswitch( alg )
	
		case "binomial": // smooth
		case "boxcar": // smooth
			break
			
		case "low-pass": // Filter IIR
		case "high-pass": // Filter IIR
			break
			
		default:
			alg = ""
			
	endswitch
	
	return alg

End // ChanFilterAlgGet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFilterUpdate( chanNum )
	Variable chanNum
	
	chanNum = ChanNumCheck( chanNum )
	
	String gname = ChanGraphName( chanNum )
	String cc = num2istr( chanNum )
	String titlestr = "Filter"
	
	String cdf = ChanDF( chanNum )
	
	//Variable filterExists = ChanFilterFxnExists()
	
	String filterAlg = ChanFilterAlgGet( chanNum )
	
	ControlInfo /W=$gname $( "SmoothSet"+cc )
	
	if ( V_flag == 0 )
		return 0
	endif
	
	strswitch( filterAlg )
		case "binomial":
		case "boxcar":
			titlestr = "Smooth"
			break
		case "low-pass":
			titlestr = "Low"
			break
		case "high-pass":
			titlestr = "High"
			break
		default:
			titlestr = "Filter"
	endswitch
	
	SetVariable $( "SmoothSet"+cc ), win=$gname, title=titlestr, proc=$ChanFilterProc( chanNum ), value=$( cdf+"SmoothN" )
	
	return 0
	
End //  ChanFilterUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanLabelCall( chanNum, xy ) // set channel labels
	Variable chanNum
	String xy // "x" or "y"
	
	String vlist = ""
	
	String labelStr = NMChanLabel( chanNum, xy, "" )
	
	Prompt labelStr, xy + " label:"
	
	DoPrompt "Set Channel Label", labelStr
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	vlist = NMCmdNum( chanNum, vlist )
	vlist = NMCmdNum( 2, vlist )
	vlist = NMCmdStr( xy, vlist )
	vlist = NMCmdStr( labelStr, vlist )
	
	NMCmdHistory( "NMChanLabelSet", vlist )
		
	NMChanLabelSet( chanNum, 2, xy, labelStr )
	
	return 0

End // ChanLabelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGridToggle( chanNum )
	Variable chanNum // channel number
	
	String vlist = ""
	String cdf = ChanDF( chanNum )
	String gname = ChanGraphName( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	Variable on = NumVarOrDefault( cdf+"GridFlag", 1 )
	
	on = BinaryInvert( on )
	
	vlist = NMCmdNum( chanNum, vlist )
	vlist = NMCmdNum( on, vlist )
	NMCmdHistory( "ChanGrid", vlist )
	
	ChanGrid( chanNum, on )
	
End // ChanGridToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGrid( chanNum, on )
	Variable chanNum // channel number
	Variable on // ( 0 ) no ( 1 ) yes
	
	String cdf = ChanDF( chanNum )
	String gname = ChanGraphName( chanNum )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gname ) != 1 ) )
		return -1
	endif
	
	SetNMvar( cdf+"GridFlag", on )
	
	ModifyGraph /W=$gname grid=on
	
	ChanGraphsUpdate()
	
End // ChanGrid

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanDragToggle()
	
	Variable on = NeuroMaticVar( "DragOn" )
	
	on = BinaryInvert( on )
	
	NMCmdHistory( "ChanDragOn", NMCmdNum( on, "" ) )
	
	return ChanDragOn( on )
	
End // ChanDragToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanDragOn( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	on = NMDragOn( on )
	
	if ( on == 1 )
		Execute /Z  CurrentNMTabName() + "Tab( 1 )" // should append drag waves for specific tab
	else
		ChanDragUtility( "remove" )
	endif
	
	return on
	
End // ChanDragOn

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanDragUtility( select )
	String select // "clear" or "remove" or "update"

	Variable ccnt, numChannels = NMNumChannels()
	String gname
	
	for ( ccnt = 0; ccnt < numChannels; ccnt+=1 )
		gname = ChanGraphName( ccnt )
		NMDragGraphUtility( gName, select )
	endfor

End // ChanDragRemoveAll

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOnAllCall()

	NMCmdHistory( "ChanOnAll","" )
	
	return ChanOnAll()

End // ChanOnAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOnAll()

	ChanOn( -1, 1 )
	ChanGraphsToFront()

	return 0

End // ChanOnAll

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOnCall( chanNum, on )
	Variable chanNum // channel number, or ( -1 ) all
	Variable on // ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	
	vlist = NMCmdNum( chanNum, vlist )
	vlist = NMCmdNum( on, vlist )
	NMCmdHistory( "ChanOn", vlist )
	
	return ChanOn( chanNum, on )
	
End // ChanOnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOn( chanNum, on )
	Variable chanNum // channel number, or ( -1 ) all
	Variable on // ( 0 ) no ( 1 ) yes
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String cdf
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanDF( ccnt )
		
		if ( strlen( cdf ) > 0 )
			SetNMvar( cdf+"On", on )
		endif
		
	endfor
	
	ChanGraphsUpdate()
	
	return 0
	
End // ChanOn

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAutoScaleCall( chanNum, on )
	Variable chanNum // channel number
	Variable on // ( 0 ) on ( 1 ) yes
	
	String vlist = ""
	
	vlist = NMCmdNum( chanNum, vlist )
	vlist = NMCmdNum( on, vlist )
	NMCmdHistory( "ChanAutoScale", vlist )
	
	return ChanAutoScale( chanNum, on )
	
End // ChanAutoScaleCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAutoScale( chanNum, on )
	Variable chanNum // channel number
	Variable on // ( 0 ) on ( 1 ) yes
	
	String gname = ChanGraphName( chanNum )
	String cdf = ChanDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	if ( ( on == 1 ) && ( WinType( gname ) == 1 ) )
		SetAxis /A/W=$gname
	else
		ChanScaleSave( chanNum )
	endif
	
	SetNMVar( cdf+"AutoScale", on )
	SetNMVar( cdf+"AutoScaleX", 0 )
	SetNMVar( cdf+"AutoScaleY", 0 )
	
	ChanGraphsUpdate()
	
	return 0

End // ChanAutoScale

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAutoScaleX( chanNum, on )
	Variable chanNum // channel number
	Variable on // ( 0 ) on ( 1 ) yes
	
	String cdf = ChanDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	SetNMVar( cdf+"AutoScaleX", on )
	
	if ( on == 1 )
		SetNMVar( cdf+"AutoScale", 0 )
		SetNMVar( cdf+"AutoScaleY", 0 )
	endif
	
	ChanGraphsUpdate()
	
	return 0

End // ChanAutoScaleX

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAutoScaleY( chanNum, on )
	Variable chanNum // channel number
	Variable on // ( 0 ) on ( 1 ) yes
	
	String cdf = ChanDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	SetNMVar( cdf+"AutoScaleY", on )
	
	if ( on == 1 )
		SetNMVar( cdf+"AutoScale", 0 )
		SetNMVar( cdf+"AutoScaleX", 0 )
	endif
	
	ChanGraphsUpdate()
	
	return 0

End // ChanAutoScaleY

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanScaleSave( chanNum ) // save chan min, max scale values
	Variable chanNum // ( -1 ) for all
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	String gname, cdf
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
		
		cdf = ChanDF( ccnt )
		gname = ChanGraphName( ccnt )
		
		if ( ( strlen( cdf ) == 0 ) || ( WinType( gname ) != 1 ) )
			continue
		endif
		
		GetAxis /Q/W=$gname bottom
	
		SetNMvar( cdf+"Xmin", V_min )
		SetNMvar( cdf+"Xmax", V_max )
		
		GetAxis /Q/W=$gname left
		
		SetNMvar( cdf+"Ymin", V_min )
		SetNMvar( cdf+"Ymax", V_max )
		
		// save graph position
		
		GetWindow $gname wsize
		
		if ( ( V_right > V_left ) && ( V_top < V_bottom ) )
			SetNMvar( cdf+"GX0", V_left )
			SetNMvar( cdf+"GY0", V_top )
			SetNMvar( cdf+"GX1", V_right )
			SetNMvar( cdf+"GY1", V_bottom )
		endif
	
	endfor
	
	return 0
	
End // ChanScaleSave

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanXYSet( chanNum, left, right, bottom, top )
	Variable chanNum, left, right, bottom, top
	
	chanNum = ChanNumCheck( chanNum )
	
	String cdf = ChanDF( chanNum )
	String gname = ChanGraphName( chanNum )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gname ) != 1 ) )
		return -1
	endif
	
	if ( numtype( left*right ) == 0 )
		SetAxis /W=$gname bottom left, right
		SetNMVar( cdf+"AutoScaleX", 0 )
	else
		SetNMVar( cdf+"AutoScaleX", 1 )
	endif
	
	if ( numtype( top*bottom ) == 0 )
		SetAxis /W=$gname left bottom, top
		SetNMVar( cdf+"AutoScaleY", 0 )
	else
		SetNMVar( cdf+"AutoScaleY", 1 )
	endif
	
	SetNMVar( cdf+"AutoScale", 0 )
	
	ChanScaleSave( chanNum )
	ChanGraphsUpdate()
	
	return 0

End // ChanXYSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAllX( xmin, xmax )
	Variable xmin, xmax
	Variable ccnt
	
	if ( ( numtype( xmin*xmax ) > 0 ) || ( xmin >= xmax ) )
		return -1
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 )
		ChanXYSet( ccnt, xmin, xmax, Nan, NaN )
	endfor
	
	return 0
	
End // ChanAllX

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanAllY( ymin, ymax )
	Variable ymin, ymax
	Variable ccnt
	
	if ( ( numtype( ymin*ymax ) > 0 ) || ( ymin >= ymax ) )
		return -1
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 )
		ChanXYSet( ccnt, Nan, Nan, ymin, ymax )
	endfor
	
	return 0
	
End // ChanAllY

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayCall( chanNum, overlayNum )
	Variable chanNum, overlayNum
	
	String vlist = ""
	
	vlist = NMCmdNum( chanNum, vlist )
	vlist = NMCmdNum( overlayNum, vlist )
	NMCmdHistory( "ChanOverlay", vlist )
	
	return ChanOverlay( chanNum, overlayNum )
	
End // ChanOverlayCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlay( chanNum, overlayNum )
	Variable chanNum, overlayNum
	
	String cdf = ChanDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	if ( ( numtype( overlayNum ) > 0 ) || ( overlayNum < 0 ) )
		overlayNum = 0
	endif
	
	ChanOverlayClear( chanNum )
	
	SetNMvar( cdf+"Overlay", overlayNum )
	SetNMvar( cdf+"OverlayCount", 1 )
	
	ChanOverlayKill( chanNum )
	
	return overlayNum
	
End // ChanOverlay

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayUpdate( chanNum )
	Variable chanNum
	
	chanNum = ChanNumCheck( chanNum )
	
	String xWave = NMXWave()
	
	String cdf = ChanDF( chanNum )
	String gname = ChanGraphName( chanNum )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gname ) != 1 ) )
		return -1
	endif
	
	Variable overlay = NumVarOrDefault( cdf+"Overlay", 0 )
	Variable ocnt = NumVarOrDefault( cdf+"OverlayCount", 0 )
	
	String tcolor = StrVarOrDefault( cdf+"TraceColor", "0,0,0" )
	String ocolor = StrVarOrDefault( cdf+"OverlayColor", "34816,34816,34816" )
	
	if ( overlay == 0 )
		return -1
	endif
	
	if ( ocnt == 0 )
		SetNMvar( cdf+"OverlayCount", 1 )
		return 0
	endif
	
	String dname = ChanDisplayWave( chanNum )
	
	String oName = ChanDisplayWaveName( 0, chanNum, ocnt )
	String odname = ChanDisplayWaveName( 1, chanNum, ocnt )
	
	String wList = TraceNameList( gname,";",1 )
	
	if ( StringMatch( dname, odname ) == 1 )
		return -1
	endif
	
	Duplicate /O $dname $odname
	
	RemoveWaveUnits( odname )
	
	if ( WhichListItem( oName, wList, ";", 0, 0 ) < 0 )
	
		if ( WaveExists( $xWave ) == 1 )
			AppendToGraph /W=$gname $odname vs $xWave
		else
			AppendToGraph /W=$gname $odname
		endif
	
		Execute /Z "ModifyGraph /W=" + gname + " rgb(" + oName + ")=(" + ocolor + ")"
		
		oName = ChanDisplayWaveName( 0, chanNum, 0 )
		odname = ChanDisplayWaveName( 1, chanNum, 0 )
		
		RemoveFromGraph /W=$gname/Z $oName
		
		if ( WaveExists( $xWave ) == 1 )
			AppendToGraph /W=$gname $odname vs $xWave
		else
			AppendToGraph /W=$gname $odname
		endif
		
		Execute /Z "ModifyGraph /W=" + gname + " rgb(" + oName + ")=(" + tcolor + ")"
		
	endif

	ocnt += 1
	
	if ( ocnt > overlay )
		ocnt = 1
	endif
	
	SetNMvar( cdf+"OverlayCount", ocnt )
	
	return 0

End // ChanOverlayUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayClear( chanNum )
	Variable chanNum // ( -1 ) for all
	
	Variable wcnt, ccnt, cbgn = chanNum, cend = chanNum
	String gname, wname, xName, wList, cdf
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		wname = ChanDisplayWave( ccnt )
		xName = ChanDisplayWaveName( 0, ccnt, 0 )
		gname = ChanGraphName( ccnt )
		cdf = ChanDF( ccnt )
		
		if ( WinType( gname ) == 1 )
			
			wList = TraceNameList( gname,";",1 )
			wList = RemoveFromList( xName, wList )
			
			for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
				RemoveFromGraph /W=$gname/Z $StringFromList( wcnt, wList )
			endfor
		
		endif
		
		if ( strlen( cdf ) > 0 )
			SetNMvar( cdf+"OverlayCount", 0 )
		endif
		
	endfor

End // ChanOverlayClear

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayKill( chanNum )
	Variable chanNum // ( -1 ) all chan

	Variable cbgn = chanNum, cend = chanNum
	
	Variable wcnt, ccnt, overlay
	String wname, wList, cdf
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif

	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanDF( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
	
		wList = NMFolderWaveList( cdf, "Display" + ChanNum2Char( ccnt ) + "*", ";", "", 0 )
	
		overlay = NumVarOrDefault( cdf+"Overlay", 0 )
	
		for ( wcnt = 0; wcnt <= overlay; wcnt += 1 )
			wname = ChanDisplayWaveName( 0, ccnt, wcnt )
			wList = RemoveFromList( wname, wList )
		endfor
		
		for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
			wname = cdf + StringFromList( wcnt, wList )
			KillWaves /Z $wname
		endfor
		
	endfor

End // ChanOverlayKill

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanToFrontCall( chanNum, toFront )
	Variable chanNum, toFront
	
	String vlist = ""
	
	vlist = NMCmdNum( chanNum, vlist )
	vlist = NMCmdNum( toFront, vlist )
	NMCmdHistory( "ChanToFront", vlist )
	
	return ChanToFront( chanNum, toFront )
	
End // ChanToFrontCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanToFront( chanNum, toFront )
	Variable chanNum
	Variable toFront // ( 0 ) no ( 1 ) yes
	
	String cdf = ChanDF( chanNum )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	if ( toFront != 0 )
		toFront = 1
	endif
	
	SetNMvar( cdf+"ToFront", toFront )
	
	return toFront
	
End // ChanToFront

//****************************************************************
//****************************************************************
//****************************************************************
//
//	channel display wave functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveMake( chanNum, srcName, dstName ) // create channel waves, based on smooth and dt flags
	Variable chanNum // ( -1 ) all chan
	String srcName, dstName // source and destination wave names
	
	Variable ccnt, cbgn = chanNum, cend = chanNum
	Variable ft, filterNum, tbgn1, tend1, tbgn2, tend2, sfreq, fratio
	
	String filterAlg, fxn1, fxn2, cdf, mdf = MainDF()
	
	Variable bbgn = NumVarOrDefault( mdf+"Bsln_Bgn", 0 )
	Variable bend = NumVarOrDefault( mdf+"Bsln_End", 2 )
	
	if ( StringMatch( srcName, dstName ) == 1 )
		return -1 // not to over-write source wave
	endif
	
	if ( WaveExists( $dstName ) == 1 )
		Wave wtemp = $dstName
		wtemp = Nan
	endif
		
	if ( WaveExists( $srcName ) == 0 )
		return -1 // source wave does not exist
	endif

	if ( WaveType( $srcName ) == 0 )
		return -1 // text wave
	endif
	
	if ( chanNum < -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	sfreq = 1/deltax( $srcName ) // kHz
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanFuncDF( ccnt )
		ft = ChanFuncGet( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		filterNum = ChanFilterNumGet( ccnt )
		filterAlg = ChanFilterAlgGet( ccnt )
		
		Duplicate /O $srcName, $dstName
		
		RemoveWaveUnits( dstName )
		
		if ( filterNum > 0 )
		
			strswitch( filterAlg )
			
				case "binomial":
				case "boxcar":
					SmoothWaves( filterAlg, filterNum, dstName )
					break
					
				case "low-pass":
				case "high-pass":
				
				fratio = filterNum / sfreq // kHz
			
				if ( ( numtype( fratio ) > 0 ) || ( fratio > 0.5 ) )
					NMHistory( "Channel " + ChanNum2Char( ccnt ) + " warning: filter frequency can not exceed " + num2str( sfreq * 0.5 ) + " kHz" )
				else
					FilterIIRwaves( filterAlg, fratio, 10, dstName )
				endif
				
					break
			endswitch
		
		endif
		
		switch( ft )
			default:
				break
			case 1:
			case 2:
			case 3:
				DiffWaves( dstName, ft )
				break
			case 4:
				fxn1 = StrVarOrDefault( cdf+"Norm_Fxn1", "Avg" )
				tbgn1 = NumVarOrDefault( cdf+"Norm_Tbgn1", bbgn )
				tend1 = NumVarOrDefault( cdf+"Norm_Tend1", bend )
				fxn2 = StrVarOrDefault( cdf+"Norm_Fxn2", "Max" )
				tbgn2 = NumVarOrDefault( cdf+"Norm_Tbgn2", -inf )
				tend2 = NumVarOrDefault( cdf+"Norm_Tend2", inf )
				NormalizeWaves( fxn1, tbgn1, tend1, fxn2, tbgn2, tend2, dstName )
				break
			case 5:
				bbgn = NumVarOrDefault( cdf+"DFOF_Bbgn", bbgn )
				bend = NumVarOrDefault( cdf+"DFOF_Bend", bend )
				DFOFWaves( bbgn, bend, dstName )
				break
			case 6:
				bbgn = NumVarOrDefault( cdf+"Bsln_Bbgn", bbgn )
				bend = NumVarOrDefault( cdf+"Bsln_Bend", bend )
				BaselineWaves( 1, bbgn, bend, dstName )
				break
		endswitch
		
	endfor

End // ChanWaveMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWavesClear( chanNum )
	Variable chanNum // ( -1 ) all chan
	
	Variable cbgn = chanNum, cend = chanNum
	Variable wcnt, ccnt, overlay
	String wname, cdf
	
	if ( chanNum == -1 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif

	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanDF( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		overlay = NumVarOrDefault( cdf+"Overlay", 0 )
		
		for ( wcnt = 0; wcnt <= overlay; wcnt += 1 ) // Nan display waves
		
			wname = ChanDisplayWaveName( 1, ccnt, wcnt )
			
			if ( WaveExists( $wname ) == 1 )
				Wave wtemp = $wname
				wtemp = Nan
			endif
			
		endfor
	
	endfor

End // ChanWavesClear

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Graph Marquee Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function FreezeChanXY() : GraphMarquee // freeze chan graph xy scales
	String vlist = ""

	GetMarquee left, bottom
	
	String gname = WinName( 0,1 )
	
	if ( ( V_Flag == 0 ) || ( IsChanGraph( gname ) == 1 ) )
		return -1
	endif
	
	Variable chanNum = ChanChar2Num( gname[4,4] )
	
	vlist = NMCmdNum( V_left, vlist )
	vlist = NMCmdNum( V_right, vlist )
	vlist = NMCmdNum( V_bottom, vlist )
	vlist = NMCmdNum( V_top, vlist )
	NMCmdHistory( "ChanXYSet", vlist )
	
	ChanXYSet( chanNum, V_left, V_right, V_bottom, V_top )
	
	DoWindow /F NMPanel // this removes marquee
	
	return 0

End // FreezeChanXY

//****************************************************************
//****************************************************************
//****************************************************************

Function FreezeChanX() : GraphMarquee // freeze chan graph x scale
	String vlist = ""

	GetMarquee left, bottom
	
	String gname = WinName( 0,1 )
	
	if ( ( V_Flag == 0 ) || ( IsChanGraph( gname ) == 1 ) )
		return -1
	endif
	
	Variable chanNum = ChanChar2Num( gname[4,4] )
	
	V_bottom = Nan
	V_top = Nan
	
	vlist = NMCmdNum( V_left, vlist )
	vlist = NMCmdNum( V_right, vlist )
	vlist = NMCmdNum( V_bottom, vlist )
	vlist = NMCmdNum( V_top, vlist )
	NMCmdHistory( "ChanXYSet", vlist )
	
	ChanXYSet( chanNum, V_left, V_right, V_bottom, V_top )
	
	DoWindow /F NMPanel // this removes marquee
	
	return 0

End // FreezeChanX

//****************************************************************
//****************************************************************
//****************************************************************

Function FreezeChanY() : GraphMarquee // freeze chan graph x scale
	String vlist = ""

	GetMarquee left, bottom
	
	String gname = WinName( 0,1 )
	
	if ( ( V_Flag == 0 ) || ( IsChanGraph( gname ) == 1 ) )
		return -1
	endif
	
	Variable chanNum = ChanChar2Num( gname[4,4] )
	
	V_left = Nan
	V_right = Nan
	
	vlist = NMCmdNum( V_left, vlist )
	vlist = NMCmdNum( V_right, vlist )
	vlist = NMCmdNum( V_bottom, vlist )
	vlist = NMCmdNum( V_top, vlist )
	NMCmdHistory( "ChanXYSet", vlist )
	
	ChanXYSet( chanNum, V_left, V_right, V_bottom, V_top )
	
	DoWindow /F NMPanel // this removes marquee
	
	return 0

End // FreezeChanY

//****************************************************************
//****************************************************************
//****************************************************************

Function FreezeAllChanX() : GraphMarquee
	String vlist = ""

	GetMarquee left, bottom
	
	String gname = WinName( 0,1 )
	
	if ( ( V_Flag == 0 ) || ( IsChanGraph( gname ) == 1 ) )
		return -1
	endif
	
	vlist = NMCmdNum( V_left, vlist )
	vlist = NMCmdNum( V_right, vlist )
	NMCmdHistory( "ChanAllX", vlist )
	ChanAllX( V_left, V_right )
	
	DoWindow /F NMPanel // this removes marquee
	
	return 0
	
End // FreezeAllChanX

//****************************************************************
//****************************************************************
//****************************************************************