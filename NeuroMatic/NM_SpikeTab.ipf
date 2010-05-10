#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Spike Analysis
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	NM tab entry "Spike"
//
//	Compute spike rasters, PST histograms, interspike interval histograms, avg rates
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikePrefix( objName ) // tab prefix identifier
	String objName
	
	return "SP_" + objName
	
End // SpikePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeDF() // package full-path folder name

	return PackDF( "Spike" )
	
End // SpikeDF

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable == 1 )
		CheckPackage( "Spike", 0 ) // declare globals if necessary
		CheckSpikeThresh()
		CheckSpikeWindows()
		DisableNMPanel( 0 )
		MakeSpike( 0 ) // make controls if necessary
		UpdateSpike()
		ChanControlsDisable( -1, "000000" )
	endif
	
	SpikeDisplay( -1, enable )
	
	if ( enable == 1 )
		AutoSpike()
	endif

End // SpikeTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillSpike( what )
	String what
	
	String sdf = SpikeDF()
	
	strswitch( what )
	
		case "waves":
			return 0
			
		case "folder":
		
			if ( DataFolderExists( sdf ) == 1 )
			
				KillDataFolder $sdf
				
				if ( DataFolderExists( sdf ) == 1 )
					return -1
				else
					return 0
				endif
				
			endif
			
	endswitch
	
	return -1

End // KillSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckSpike()
	
	String sdf = SpikeDF()
	
	if ( DataFolderExists( sdf ) == 0 )
		return NMError( 30, "CheckSpike", "SpikeDF", sdf )
	endif

	CheckNMwave( sdf+"SP_SpikeX", 0, Nan ) // waves for display graphs
	CheckNMwave( sdf+"SP_SpikeY", 0, Nan )
	
	return 0
	
End // CheckSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSpikeVar( varName )
	String varName
	
	return CheckNMvar( SpikeDF()+varName, NMSpikeVar( varName ) )

End // CheckNMSpikeVar

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeConfigs()

	NMSpikeConfigVar( "UseSubfolders", "use subfolders when creating Spike waves ( 0 ) no ( 1 ) yes ( use 0 for previous NM formatting )" )
	
	NMSpikeConfigStr( "WaveNamingFormat", "attach new wave identifier as \"prefix\" or \"suffix\" ( use \"suffix\" for previous NM formatting )" )
	
End // SpikeConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeConfigVar( varName, description )
	String varName
	String description
	
	return NMConfigVar( "Spike", varName, NMSpikeVar( varName ), description )
	
End // NMSpikeConfigVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeConfigStr( varName, description )
	String varName
	String description
	
	return NMConfigStr( "Spike", varName, NMSpikeStr( varName ), description )
	
End // NMSpikeConfigStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeVar( varName )
	String varName
	
	Variable defaultVal = Nan
	String sdf = SpikeDF()
	
	strswitch( varName )
	
		case "UseSubfolders":
			defaultVal = 1
			break
			
		case "Thresh":
			defaultVal = Nan
			break
			
		case "Tbgn":
			defaultVal = NumVarOrDefault( sdf+"WinB", -inf )
			break
			
		case "Tend":
			defaultVal = NumVarOrDefault( sdf+"WinE", inf )
			break
			
		case "ChanSelect":
			defaultVal = 0
			break
			
		case "Spikes":
			defaultVal = 0
			break
			
		case "Rate":
			defaultVal = 0
			break
			
		case "ComputeAllDisplay":
			defaultVal = 1
			break
			
		case "ComputeAllSpeed":
			defaultVal = 0
			break
			
		case "ComputeAllFormat":
			defaultVal = 0
			break
			
		case "ComputeAllPlot":
			defaultVal = 1
			break
			
		case "ComputeAllTable":
			defaultVal = 0
			break
			
		case "PSTHdelta":
			defaultVal = 1
			break
			
		case "ISIHdelta":
			defaultVal = 1
			break
			
		case "S2W_TimeBefore":
			defaultVal = 2
			break
			
		case "S2W_TimeAfter":
			defaultVal = 5
			break
			
		case "S2W_StopAtNextSpike":
			defaultVal = 0
			break
			
		case "S2W_chan":
			defaultVal = CurrentNMChannel()
			break
			
		default:
			NMDoAlert ( "NMSpikeVar Error: no variable called " + NMQuotes( varName ) )
			return Nan
	
	endswitch
	
	return NumVarOrDefault( sdf+varName, defaultVal )
	
End // NMSpikeVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeStr( varName )
	String varName
	
	String defaultStr = ""
	
	strswitch( varName )
	
		case "WaveNamingFormat":
			defaultStr = "prefix"
			break
			
		case "PSTHyaxis":
			defaultStr = "Spikes / bin"
			break
			
		case "ISIHyaxis":
			defaultStr = "Intvls / bin"
			break
			
		case "S2W_WavePrefix":
			//defaultStr = "SP_Rstr"
			defaultStr = "Spike"
			break
			
		default:
			NMDoAlert( "NMSpikeStr Error: no variable called " + NMQuotes( varName ) )
			return ""
	
	endswitch
	
	return StrVarOrDefault( SpikeDF() + varName, defaultStr )
			
End // NMSpikeStr

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMSpikeVar( varName, value )
	String varName
	Variable value
	
	String thisfxn = "SetNMSpikeVar", sdf = SpikeDF()
	
	if ( strlen( varName ) == 0 )
		return NMError( 21, thisfxn, "varName", varName )
	endif
	
	if ( DataFolderExists( sdf ) == 0 )
		return NMError( 30, thisfxn, "SpikeDF", sdf )
	endif
	
	Variable /G $sdf+varName = value
	
	return 0
	
End // SetNMSpikeVar

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMSpikeStr( varName, strValue )
	String varName
	String strValue
	
	String thisfxn = "SetNMSpikeStr", sdf = SpikeDF()
	
	if ( strlen( varName ) == 0 )
		return NMError( 21, thisfxn, "varName", varName )
	endif
	
	if ( DataFolderExists( sdf ) == 0 )
		return NMError( 30, thisfxn, "SpikeDF", sdf )
	endif
	
	String /G $sdf+varName = strValue
	
	return 0
	
End // SetNMSpikeStr

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMSpikeWave( wName, pnt, value )
	String wName
	Variable pnt // point to set, or ( -1 ) all points
	Variable value
	
	String thisfxn = "SetNMSpikeWave", sdf = SpikeDF()
	
	if ( strlen( wName ) == 0 )
		return NMError( 21, thisfxn, "wName", wName )
	endif
	
	if ( DataFolderExists( sdf ) == 0 )
		return NMError( 30, thisfxn, "SpikeDF", sdf )
	endif
	
	return SetNMwave( SpikeDF()+wName, pnt, value )
	
End // SetNMSpikeWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeObjectName( oName )
	String oName
	
	return SpikeDF() + oName
	
End // NMSpikeObjectName

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckSpikeThresh()
	
	Variable minThresh = 5
	
	String wname = ChanDisplayWave( -1 )
	
	Variable thresh = NMSpikeVar( "Thresh" )
	
	if ( ( numtype( thresh ) == 0 ) || ( WaveExists( $wname ) == 0 ) )
		return 0
	endif
	
	WaveStats /Q/Z $wname
	
	thresh = ( V_max - 0.2*abs( V_max - V_avg ) )
	thresh = ceil( 10 * thresh ) / 10
	
	if ( V_avg < minThresh )
		thresh = max( thresh, minThresh )
	endif
	
	SetNMSpikeVar( "Thresh", thresh )
	
	return 0
	
End // CheckSpikeThresh

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckSpikeWindows()

	if ( numtype( NMSpikeVar( "Tbgn" ) ) > 0 )
		SetNMSpikeVar( "Tbgn", -inf )
	endif
	
	if ( numtype( NMSpikeVar( "Tend" ) ) > 0 )
		SetNMSpikeVar( "Tend", inf )
	endif

End // CheckSpikeWindows

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDisplay( chanNum, appnd ) // append/remove spike wave from channel graph
	Variable chanNum // channel number ( -1 ) for current channel
	Variable appnd // 1 - append wave; 0 - remove wave
	
	Variable ccnt, drag = appnd
	String gName, sdf = SpikeDF()
	
	if ( DataFolderExists( sdf ) == 0 )
		return 0 // spike has not been initialized yet
	endif
	
	if ( ( NeuroMaticVar( "DragOn" ) == 0 ) || ( StringMatch( CurrentNMTabName(), "Spike" ) == 0 ) )
		drag = 0
	endif 
	
	if ( appnd == 0 )
		SetNMSpikeWave( "SP_SpikeX", -1, Nan )
		SetNMSpikeWave( "SP_SpikeY", -1, Nan )
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue // window does not exist
		endif
	
		RemoveFromGraph /Z/W=$gName SP_SpikeY
		RemoveFromGraph /Z/W=$gName DragTbgnY, DragTendY
		
	endfor
	
	gName = ChanGraphName( chanNum )
	
	if ( ( appnd == 1 ) && ( WinType( gName ) == 1 ) )
		AppendToGraph /W=$gName $NMSpikeObjectName( "SP_SpikeY" ) vs $NMSpikeObjectName( "SP_SpikeX" )
		ModifyGraph /W=$gName mode( SP_SpikeY )=3, marker( SP_SpikeY )=9
		ModifyGraph /W=$gName mrkThick( SP_SpikeY )=2, rgb( SP_SpikeY )=( 65535,0,0 )
	endif
	
	NMDragEnable( drag, "DragTbgn", "", sdf+"Tbgn", "", gName, "bottom", "min", 65535, 0, 0 )
	NMDragEnable( drag, "DragTend", "", sdf+"Tend", "", gName, "bottom", "max", 65535, 0, 0 )

End // SpikeDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDisplayClear()

	SetNMSpikeWave( "SP_SpikeX", -1, Nan )
	SetNMSpikeWave( "SP_SpikeY", -1, Nan )
	
	NMDragClear( "DragTbgn" )
	NMDragClear( "DragTend" )

End // SpikeDisplayClear

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Tab Controls Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeSpike( force ) // create Spike tab controls
	Variable force

	Variable x0 = 40, y0 = 195, xinc = 120, yinc = 35, fs = NMPanelFsize()
	Variable taby = NMPanelTabY()
	String sdf = SpikeDF()
	
	y0 = taby + 45
	
	ControlInfo /W=NMPanel SP_Thresh
	
	if ( ( V_Flag != 0 ) && ( force == 0 ) )
		return 0 // Spike tab has already been created, return here
	endif
	
	if ( DataFolderExists( sdf ) == 0 )
		return 0 // spike has not been initialized yet
	endif
	
	CheckNMSpikeVar( "Thresh" )
	CheckNMSpikeVar( "Tbgn" )
	CheckNMSpikeVar( "Tend" )
	CheckNMSpikeVar( "Spikes" )
	CheckNMSpikeVar( "Rate" )
	
	DoWindow /F NMPanel
	
	GroupBox SP_Grp1, title = "Spike Detection", pos={20,y0}, size={260,150}, fsize=fs
	
	xinc = 145
	yinc = 26
	
	SetVariable SP_Thresh, title="Threshold", pos={x0,y0+1*yinc}, limits={-inf,inf,1}, size={120,20}, frame=1, value=$( sdf+"Thresh" ), proc=NMSpikeSetVariable, fsize=fs
	
	SetVariable SP_Tbgn, title="t_bgn", pos={x0,y0+2*yinc}, limits={-inf,inf,1}, size={120,20}, frame=1, value=$( sdf+"Tbgn" ), proc=NMSpikeSetVariable, fsize=fs
	SetVariable SP_Tend, title="t_end", pos={x0,y0+3*yinc}, limits={-inf,inf,1}, size={120,20}, frame=1, value=$( sdf+"Tend" ), proc=NMSpikeSetVariable, fsize=fs
	
	SetVariable SP_Count, title="Spikes : ", pos={x0+xinc,y0+2*yinc}, limits={0,inf,0}, size={90,20}, frame=0, value=$( sdf+"Spikes" ), fsize=fs
	SetVariable SP_WRate, title="Hertz : ", pos={x0+xinc,y0+3*yinc}, limits={0,inf,0}, size={90,20}, frame=0, value=$( sdf+"Rate" ), fsize=fs
	
	yinc = 35
	
	y0 += 10
	
	Button SP_All, title = "All Waves", pos={x0+60,y0+3*yinc}, size={100,20}, proc = NMSpikeButton, fsize=fs
	
	y0 = 380; yinc = 35
	
	GroupBox SP_Grp2, title = "Spike Analysis", pos={20,y0}, size={260,200}, fsize=fs
	
	PopupMenu SP_RasterSelect, pos={x0+170,y0+1*yinc}, bodywidth=220, fsize=fs
	PopupMenu SP_RasterSelect, value="Spike Raster Select", proc=NMSpikeRasterPopup
	
	xinc = 120
	yinc = 40
	
	Button SP_Raster, title="Raster Plot", pos={x0,y0+2*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs
	Button SP_Table, title = "Table", pos={x0+xinc,y0+2*yinc}, size={100,20}, proc = NMSpikeAnalysisButton, fsize=fs
	Button SP_PSTH, title="PST Histo", pos={x0,y0+3*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs
	Button SP_Rate, title="Avg Rate", pos={x0+xinc,y0+3*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs
	Button SP_ISIH, title="ISI Histo", pos={x0,y0+4*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs
	Button SP_2Waves, title="Spikes 2 Waves", pos={x0+xinc,y0+4*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs
	
	return 0
	
End // MakeSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateSpike()
	
	String spikeMenu = NMSpikeRasterSelectMenu()
	String xWaveOrFolder = NMxWaveOrFolder()
	
	Variable md = 1 + WhichListItem( xWaveOrFolder, SpikeMenu, ";", 0, 0 )

	PopupMenu SP_RasterSelect, win=NMPanel, mode=max(md,1), value=NMSpikeRasterSelectMenu()
	
	SetNMSpikeVar( "ChanSelect", CurrentNMChannel() )

End // UpdateSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeRasterSelectMenu()

	String menuStr = "Spike Raster Select;"
	String folderList = NMSpikeSubfolderList( "", 0, 1 )
	String xWaveOrFolder = NMxWaveOrFolder()
	
	String oldRasterList = SpikeRasterList()
	
	if ( ItemsInList( folderList ) > 0 )
		menuStr += "---;" + folderList
	endif
	
	if ( ItemsInList( oldRasterList ) > 0 )
		menuStr += "---;" + oldRasterList
	endif

	menuStr += "---;Other...;"
	
	if ( WhichListItem( xWaveOrFolder, folderList ) >= 0 )
		menuStr += "Delete Spike Subfolder;"
	endif
	
	return menuStr

End // NMSpikeRasterSelectMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ReplaceString( "SP_", ctrlName, "" )
	
	SpikeCall( ctrlName, varStr )

End // NMSpikeSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeRasterPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "SP_", ctrlName, "" )
	
	String xWaveOrFolder = popStr
	
	strswitch( popStr )
	
		case "---":
			break
			
		case "Delete Spike Subfolder":
			NMSpikeAnalysisCall( popStr )
			break
	
		case "Other...":
		
			xWaveOrFolder = NMSpikeRasterXSelectPrompt()
			
		default:
		
			if ( NMSpikeRasterXSelectCall( xWaveOrFolder ) == 0 )
				return 0
			endif
	
	endswitch
	
	UpdateSpike()
	
End // NMSpikeRasterPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ReplaceString( "SP_", ctrlName, "" )
	
	SpikeCall( ctrlName, "" )
	
End // NMSpikeButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeAnalysisButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ReplaceString( "SP_", ctrlName, "" )
	
	NMSpikeAnalysisCall( ctrlName )
	
End // NMSpikeAnalysisButton

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeCall( fxn, select )
	String fxn, select
	
	Variable snum = str2num( select )
	
	strswitch( fxn )
	
		case "Thresh":
			return num2str( SpikeThresholdCall( snum ) )
			
		case "WinB":
		case "Tbgn":
			return num2str( SpikeWindowCall( snum, Nan ) )
		
		case "WinE":
		case "Tend":
			return num2str( SpikeWindowCall( Nan, snum ) )
			
		case "All":
		case "All Waves":
			return NMSpikeComputeAllCall()
			
		default:
			NMDoAlert( "SpikeCall: unrecognized function call: " + fxn )
			
	endswitch
	
	return ""
	
End // SpikeCall

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Global Variable Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeThresholdCall( thresh )
	Variable thresh
	
	NMCmdHistory( "SpikeThreshold", NMCmdNum( thresh,"" ) )
	
	return SpikeThreshold( thresh )
	
End // SpikeThresholdCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeThreshold( thresh )
	Variable thresh
	
	if ( numtype( thresh ) > 0 )
		return NMError( 10, "SpikeThreshold", "thresh", num2str( thresh ) )
	endif
	
	SetNMSpikeVar( "Thresh", thresh )
	AutoSpike()
	
	return 0
	
End // SpikeThreshold

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWindowCall( tbgn, tend )
	Variable tbgn, tend // time begin and end
	
	String vlist = ""
	
	if ( numtype( tbgn ) > 0 )
		tbgn = NMSpikeVar( "Tbgn" )
	endif
	
	if ( numtype( tend ) > 0 )
		tend = NMSpikeVar( "Tend" )
	endif
	
	vlist = NMCmdNum( tbgn, vlist )
	vlist = NMCmdNum( tend, vlist )
	NMCmdHistory( "SpikeWindow", vlist )
	
	return SpikeWindow( tbgn, tend )
	
End // SpikeWindowCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWindow( tbgn, tend )
	Variable tbgn, tend // time begin and end
	
	Variable te
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	te = tend
	
	if ( tbgn > tend )
		tend = tbgn
		tbgn = te
	endif
	
	SetNMSpikeVar( "Tbgn", tbgn )
	SetNMSpikeVar( "Tend", tend )
	
	AutoSpike()
	
	return 0

End // SpikeWindow

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWinBgn()

	Variable t = NMSpikeVar( "Tbgn" )

	if ( numtype( t ) > 0 )
		t = leftx( $ChanDisplayWave( -1 ) )
	endif
	
	return t

End // SpikeWinBgn

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWinEnd()

	Variable t = NMSpikeVar( "Tend" )

	if ( numtype( t ) > 0 )
		t = rightx( $ChanDisplayWave( -1 ) )
	endif
	
	return t

End // SpikeWinEnd

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike Raster Subfolder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeSubfolderPrefix()

	return "Spike_"

End // NMSpikeSubfolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMSpikeSubfolder()

	return NMSpikeSubfolder( CurrentNMWavePrefix(), CurrentNMChannel() )
	
End // CurrentNMSpikeSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeSubfolder( wavePrefix, chanNum )
	String wavePrefix
	Variable chanNum
	
	if ( NMSpikeVar( "UseSubfolders" ) == 0 )
		return ""
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = CurrentNMWavePrefix()
	endif
	
	return NMSubfolder( NMSpikeSubfolderPrefix(), wavePrefix, chanNum, NMWaveSelectShort() )

End // NMSpikeSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSpikeSubfolder( subfolder )
	String subfolder // ( "" ) for current
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMSpikeSubfolder()
	endif
	
	return CheckNMSubfolder( subfolder )
	
End // CheckNMSpikeSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeSubfolderList( folder, fullPath, restrictToCurrentPrefix )
	String folder
	Variable fullPath // ( 0 ) no ( 1 ) yes
	Variable restrictToCurrentPrefix // ( 0 ) no ( 1 ) yes
	
	Variable icnt
	String folderName, tempList = ""
	
	String currentPrefix = CurrentNMWavePrefix()
	
	String folderList = NMSubfolderList( NMSpikeSubfolderPrefix(), folder, fullPath )
	
	if ( restrictToCurrentPrefix == 1 )
		
		for ( icnt = 0 ; icnt < ItemsInList( folderList ) ; icnt += 1 )
			
			folderName = StringFromList( icnt, folderList )
			
			if ( strsearch( folderName, currentPrefix, 0, 2 ) > 0 )
				tempList = AddListItem( folderName, tempList, ";", inf )
			endif
			
		endfor
		
		folderList = tempList
	
	endif
	
	return folderList

End // NMSpikeSubfolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeSubfolderRasterList( subfolder, fullPath, includeRasterY )
	String subfolder
	Variable fullPath // ( 0 ) no ( 1 ) yes
	Variable includeRasterY // ( 0 ) no ( 1 ) yes

	Variable icnt
	String xList, xRaster, yRaster, xyList = ""
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMSpikeSubfolder()
	endif
	
	if ( DataFolderExists( subfolder ) == 0 )
		return ""
	endif
	
	xList = NMFolderWaveList( subfolder, "SP_RX*", ";", "", fullPath )
	
	xList = SpikeRasterListStrict( xList )
	
	if ( includeRasterY == 0 )
		return xList
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( xList ) ; icnt += 1 )
		
		xRaster = StringFromList( icnt, xList )
		
		yRaster = SpikeRasterNameY( xRaster )
		
		if ( WaveExists( $yRaster ) == 1 )
			xyList = AddListItem( xRaster, xyList, ";", inf )
			xyList = AddListItem( yRaster, xyList, ";", inf )
		endif
		
	endfor
	
	return xyList

End // NMSpikeSubfolderRasterList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeSubfolderTableCall()

	String subfolder, folderList, vlist = ""
	
	String xWaveOrFolder = NMxWaveOrFolder()
	
	if ( DataFolderExists( xWaveOrFolder ) == 1 )
	
		subfolder = xWaveOrFolder
		
	else
		
		folderList = NMSpikeSubfolderList( "", 0, 0 )
		
		if ( ItemsInList( folderList ) == 0 )
			NMDoAlert( "NMSpikeSubfolderTable Abort: located no Spike subfolders." )
			return ""
		endif
		
		subfolder = StringFromList( 0, folderList )
		
		Prompt subfolder, "choose Spike subfolder:", popup folderList
		DoPrompt "Spike Subfolder Table", subfolder
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	endif
	
	subfolder = CurrentNMFolder( 1 ) + subfolder + ":"
	
	vlist = NMCmdStr( subfolder , vlist )
	NMCmdHistory( "NMSpikeSubfolderTable", vlist )
	
	return NMSpikeSubfolderTable( subfolder )

End // NMSpikeSubfolderTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeSubfolderTable( subfolder )
	String subfolder
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMSpikeSubfolder()
	endif
	
	return NMSubfolderTable( subfolder, "SP_" )
	
End // NMSpikeSubfolderTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeSubfolderClear( subfolder )
	String subfolder
	
	String failureList
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMSpikeSubfolder()
	endif
	
	return NMSubfolderClear( subfolder )

End // NMSpikeSubfolderClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeSubfolderKill( subfolder )
	String subfolder
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMSpikeSubfolder()
	endif
	
	return NMSubfolderKill( subfolder )

End // NMSpikeSubfolderKill

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike Raster Computation Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function AutoSpike() // compute raster on currently selected channel/wave, display on channel graph

	Variable spikes, rate
	
	String xRaster = NMSpikeObjectName( "SP_RasterX_Auto" )
	String yRaster = NMSpikeObjectName( "SP_RasterY_Auto" )
	
	Variable tbgn = NMSpikeVar( "Tbgn" )
	Variable tend = NMSpikeVar( "Tend" )
	Variable thresh = NMSpikeVar( "Thresh" )
	
	SpikeDisplayClear()

	spikes = SpikeRaster( CurrentNMChannel(), CurrentNMWave(), Thresh, tbgn, tend, xRaster, yRaster, 1, 0 )
	
	if ( spikes >= 0 )
		rate = 1000 * spikes / ( SpikeTmax( xRaster ) - SpikeTmin( xRaster ) )
		rate = round( rate * 100 ) / 100
	else
		spikes = Nan
		rate = Nan
	endif
	
	SetNMSpikeVar( "Spikes", spikes )
	SetNMSpikeVar( "Rate", rate )
	
	NMDragUpdate( "DragTbgn" )
	NMDragUpdate( "DragTend" )
	
End // AutoSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeComputeAllCall()

	Variable FORMAT_ON = 0
	
	String vlist = ""
	
	if ( NMNumActiveWaves() <= 0 )
		NMDoAlert( "No waves selected!" )
		return ""
	endif

	Variable dsplyFlag = 1 + NMSpikeVar( "ComputeAllDisplay" )
	Variable speed = NMSpikeVar( "ComputeAllSpeed" )
	Variable format = 1 + NMSpikeVar( "ComputeAllFormat" )
	Variable plot = 1 + NMSpikeVar( "ComputeAllPlot" )
	Variable table = 1 + NMSpikeVar( "ComputeAllTable" )
	Variable useSubfolders = 1 + NMSpikeVar( "UseSubfolders" )
	
	Prompt dsplyFlag, "display results while computing?", popup "no;yes;yes, with accept/reject prompt;"
	Prompt speed, "optional display update delay ( seconds ):"
	Prompt format, "save spike times to:", popup "one output wave;one output wave per input wave;"
	Prompt plot, "display final raster plot?", popup "no;yes;"
	Prompt table, "display final raster table?", popup "no;yes;"
	Prompt useSubfolders, "save raster waves in a subfolder?", popup "no;yes;"
	
	if ( FORMAT_ON && ( NMNumWaves() > 1 ) )
	
		DoPrompt "Spike Compute All", dsplyFlag, speed, format, plot, table, useSubfolders
		
		format -= 1
		SetNMSpikeVar( "ComputeAllFormat", format )
	
	else
	
		DoPrompt "Spike Compute All", dsplyFlag, speed, plot, table, useSubfolders
		
		format = 0
		
	endif
	
	dsplyFlag -= 1
	plot -= 1
	table -= 1
	useSubfolders -= 1
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMSpikeVar( "ComputeAllDisplay", dsplyFlag )
	SetNMSpikeVar( "ComputeAllSpeed", speed )
	SetNMSpikeVar( "ComputeAllPlot", plot )
	SetNMSpikeVar( "ComputeAllTable", table )
	SetNMSpikeVar( "UseSubfolders" , useSubfolders )

	vlist = NMCmdNum( dsplyFlag, vlist )
	vlist = NMCmdNum( speed, vlist )
	vlist = NMCmdNum( format, vlist )
	vlist = NMCmdNum( plot, vlist )
	vlist = NMCmdNum( table, vlist )
	NMCmdHistory( "NMSpikeComputeAll", vlist )
	
	return NMSpikeComputeAll( dsplyFlag, speed, format, plot, table )

End // NMSpikeComputeAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeComputeAll( dsplyFlag, speed, format, plot, table )
	Variable dsplyFlag // display results while computing ( 0 ) no ( 1 ) yes ( 2 ) yes, accept/reject prompt
	Variable speed // update display speed in sec ( 0 ) for fastest
	Variable format // save spike times to ( 0 ) one wave ( 1 ) one wave per input wave
	Variable plot // automatically display raster plot? ( 0 ) no ( 1 ) yes
	Variable table // automatically display raster table? ( 0 ) no ( 1 ) yes
	
	// NOTE, format is currently under construction

	Variable icnt, ccnt, wcnt, spikes, changeChan
	String pName, gName, gList = ""
	String xRaster, yRaster, xRasterList = "", yRasterList = ""
	String subFolder, folderList = "", folderSelect = ""
	String thisfxn = "NMSpikeComputeAll"
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	Variable overwrite = NeuroMaticVar( "OverWrite" )
	
	Variable tbgn = NMSpikeVar( "Tbgn" )
	Variable tend = NMSpikeVar( "Tend" )
	Variable thresh = NMSpikeVar( "Thresh" )
	
	Variable drag = NeuroMaticVar( "DragOn" )
	
	Variable saveCurrentChan = CurrentNMChannel()
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	String wavePrefix = CurrentNMWavePrefix()
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	String allList = NMWaveSelectAllList()
	Variable allListItems = ItemsInList( allList )
	
	if ( ( numtype( dsplyFlag ) > 0 ) || ( dsplyFlag < 0 ) )
		dsplyFlag = 1
	endif
	
	if ( ( numtype( speed ) > 0 ) || ( speed < 0 ) )
		speed = 0
	endif
	
	if ( dsplyFlag == 0 )
		drag = 0
	endif
	
	if ( drag == 1 )
		NMDragOn( 0 )
		NMDragClear( "DragTbgn" )
		NMDragClear( "DragTend" )
	endif
	
	for ( icnt = 0 ; icnt < max( allListItems, 1 ) ; icnt += 1 )
		
		if ( allListItems > 0 )
			waveSelect = StringFromList( icnt, allList )
			NMWaveSelect( waveSelect )
		endif
		
		if ( NMNumActiveWaves() <= 0 )
			continue
		endif
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 ) // loop thru channels
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue // channel not selected
			endif
			
			subFolder = NMSpikeSubfolder( wavePrefix, ccnt )
			
			CheckNMSpikeSubfolder( subFolder )
			folderList = AddListItem( GetPathName( subFolder, 0 ), folderList, ";", inf )
			
			if ( strlen( folderSelect ) == 0 )
				folderSelect = subFolder
			endif
			
			SetNMvar( prefixFolder+"CurrentChan", ccnt )
			
			if ( dsplyFlag > 0 )
			
				if ( ccnt != saveCurrentChan )
					SpikeDisplay( -1, 0 ) // remove spike display waves
					SpikeDisplay( ccnt, 1 ) // add spike display waves
					changeChan = 1
				endif
				
				//ChanControlsDisable( ccnt, "111111" )
				DoWindow /F $ChanGraphName( ccnt )
				DoUpdate
				
			endif
			
			if ( format == 1 )
			
				for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
				
					if ( NMWaveIsSelected( ccnt, wcnt ) == 0 )
						continue
					endif
				
					pName = "R" + num2istr( wcnt ) + "_"
					xRaster = subFolder + NextWaveName2( subFolder, "SP_RX_" + pName, ccnt, overwrite )
					yRaster = subFolder + NextWaveName2( subFolder, "SP_RY_" + pName, ccnt, overwrite )
				
					spikes = SpikeRaster( ccnt, wcnt, thresh, tbgn, tend, xRaster, yRaster, dsplyFlag, speed * 1000 )
					
					if ( WavesExist( xRaster + ";" + yRaster + ";" ) == 1 )
						xRasterList = AddListItem( xRaster, xRasterList, ";", inf )
						yRasterList = AddListItem( yRaster, yRasterList, ";", inf )
					endif
				
				endfor
				
				gName = SpikeRasterPlot( xRasterList, yRasterList, tbgn, tend )
			
			else
			
				pName = NMWaveSelectStr() + "_"
				xRaster = subFolder + NextWaveName2( subFolder, "SP_RX_" + pName, ccnt, overwrite )
				yRaster = subFolder + NextWaveName2( subFolder, "SP_RY_" + pName, ccnt, overwrite )
			
				spikes = SpikeRaster( ccnt, -1, thresh, tbgn, tend, xRaster, yRaster, dsplyFlag, speed * 1000 )
				
				if ( plot == 1 )
					gName = SpikeRasterPlot( xRaster, yRaster, tbgn, tend )
				endif
			
			endif
			
			gList = AddListItem( gName, gList, ";", inf )
			
		endfor
		
	endfor
	
	if ( drag == 1 )
		NMDragOn( 1 )
		NMDragUpdate( "DragTbgn" )
		NMDragUpdate( "DragTend" )
	endif
	
	if ( allListItems > 0 )
		NMWaveSelect( saveWaveSelect )
	endif
		
	if ( changeChan > 0 ) // back to original channel
		SpikeDisplay( ccnt, 0 ) // remove display waves
		SpikeDisplay( saveCurrentChan, 1 ) // add display waves
		SetNMvar( prefixFolder+"CurrentChan", saveCurrentChan )
	endif
	
	NMSpikeRasterXSelect( xRaster )
	
	ChanGraphsUpdate()
	AutoSpike()
	UpdateSpike()
	
	for ( icnt = 0 ; icnt < ItemsInList( gList ) ; icnt += 1 )
	
		gName = StringFromList( icnt, gList )
	
		if ( ( strlen( gName ) > 0 ) && ( WinType( gName ) == 1 ) )
			DoWindow /F $gName
		endif
	
	endfor
	
	return folderList
	
End // NMSpikeComputeAll

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRaster( chanNum, waveNum, thresh, tbgn, tend, xRaster, yRaster, dsplyFlag, speed )
	Variable chanNum // channel number ( -1 ) for current channel
	Variable waveNum // wave number ( -1 ) for all
	Variable thresh // threshold trigger level
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	String xRaster // output raster x-wave name
	String yRaster // output raster y-wave name
	Variable dsplyFlag // display results while computing ( 0 ) no ( 1 ) yes ( 2 ) yes, accept/reject prompt
	Variable speed // display speed delay
	
	Variable wcnt, ncnt, scnt, spkcnt, found, event, dx, pwin, slope, allFlag, wbgn, wend, nwaves = 1
	Variable tbgn1, tend1, tbgn2, tend2, tmin = inf, tmax = -inf
	Variable eventLimit = 2000
	
	String wName, wList = "", aName = ""
	String xl = "Spike Event", yl = ""
	String copy = "SP_WaveTemp"
	String thisfxn = "SpikeRaster"
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable saveCurrentWave = CurrentNMWave()
	Variable currentChan = CurrentNMChannel()
	
	String wavePrefix = CurrentNMWavePrefix()
	
	if ( strlen( prefixFolder ) == 0 )
		//NMError( 30, thisfxn, "PrefixFolder", prefixFolder )
		return -1
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum >= NMNumWaves() ) )
		NMError( 10, thisfxn, "waveNum", num2istr( waveNum ) )
		return -1
	endif
	
	if ( waveNum < 0 )
		nwaves = NMNumWaves()
		allFlag = 1
		wbgn = 0
		wend = nwaves - 1
	else
		wbgn = waveNum
		wend = waveNum
	endif
	
	if ( numtype( thresh ) > 0 )
		NMError( 10, thisfxn, "thresh", num2str( thresh ) )
		return -1
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( strlen( xRaster ) == 0 )
		NMError( 21, thisfxn, "xRaster", xRaster )
		return -1
	endif
	
	if ( strlen( yRaster ) == 0 )
		NMError( 21, thisfxn, "yRaster", yRaster )
		return -1 // not allowed
	endif
	
	Make /O/N=0 SP_xtimes=Nan
	Make /O/N=0 $xRaster=Nan
	Make /O/N=0 $yRaster=Nan
	
	Wave xWave = $xRaster
	Wave yWave = $yRaster
	
	for ( wcnt = wbgn ; wcnt <= wend ; wcnt += 1 )
	
		wName = NMChanWaveName( chanNum, wcnt )
	
		if ( allFlag == 1 )
		
			if ( NMWaveIsSelected( chanNum, wcnt ) == 0 )
				continue
			endif
			
			NMCurrentWaveSetNoUpdate( wcnt )
			
			if ( dsplyflag > 0 )
				ChanGraphUpdate( chanNum, 1 )
				aName = ChanDisplayWave( chanNum )
			else
				ChanWaveMake( currentChan, wName, copy )
				aName = copy
			endif
			
		else
		
			ChanWaveMake( chanNum, wName, copy )
			aName = copy
			
		endif
		
		if ( strlen( yl ) == 0 )
			yl = NMNoteLabel( "x", aName, "msec" )
		endif
		
		if ( WaveExists( $aName ) == 0 )
			continue // wave does not exist
		endif
		
		if ( numtype( tbgn ) == 0 )
			tbgn1 = tbgn
		else
			tbgn1 = NMLeftX( aName )
		endif
		
		if ( numtype( tend ) == 0 )
			tend1 = tend
		else
			tend1 = NMRightX( aName )
		endif
		
		if ( numtype( tbgn1 ) > 0 )
			tbgn1 = leftx( $aName )
		endif
		
		if ( numtype( tend1 ) > 0 )
			tend1 = rightx( $aName )
		endif
		
		if ( tbgn1 < tmin )
			tmin = tbgn1
		endif
		
		if ( tend1 > tmax )
			tmax = tend1
		endif
		
		tbgn2 = NMXvalueTransform( aName, tbgn1, -1, 1 )
		tend2 = NMXvalueTransform( aName, tend1, -1, -1 )
		
		if ( tend2 < tbgn2 + 2*deltax( $aName ) )
			//NMHistory( "SpikeRaster: out of range: ", tbgn2, tend2
			//continue // out of range
		endif
		
		Findlevels /Q/R=( tbgn2, tend2 )/D=SP_xtimes/Edge=1 $aName, thresh
		
		pwin = 1
		
		if ( V_LevelsFound > 0 )
		
			if ( V_LevelsFound > 1 )
				dx = deltax( $aName )
				pwin = floor( ( SP_xtimes[1] - SP_xtimes[0] ) / ( dx * 2 ) )
				pwin = max( pwin, 1 )
				pwin = min( pwin, 3 )
			endif
		
			for ( scnt = 0 ; scnt < V_LevelsFound ; scnt += 1 )
				SP_xtimes[scnt] = NMXvalueTransform( aName, SP_xtimes[scnt], 1, 0 )
			endfor
			
			WaveStats /Q/Z SP_xtimes
				
			found = V_npnts
				
		else
		
			found = 0
		
		endif
		
		if ( dsplyFlag > 0 )
		
			if ( V_LevelsFound > 0 )
		
				WaveStats /Q/Z SP_xtimes
				
				if ( V_npnts < eventlimit )
					Duplicate /O SP_xtimes $NMSpikeObjectName( "SP_SpikeX" )
					Duplicate /O SP_xtimes $NMSpikeObjectName( "SP_SpikeY" )
					SetNMSpikeWave( "SP_SpikeY", -1, thresh )
				endif
				
			else
			
				SetNMSpikeWave( "SP_SpikeX", -1, Nan )
				SetNMSpikeWave( "SP_SpikeY", -1, Nan )
			
			endif
			
			if ( NeuroMaticVar( "AutoDoUpdate" ) == 1 )
				DoUpdate
			endif
			
			if ( ( dsplyFlag == 1 ) && ( numtype( speed ) == 0 ) && ( speed > 0 ) )
			
				NMwaitMSTimer( speed )
				
			elseif ( ( dsplyFlag == 2 ) && ( found > 0 ) )
			
				DoAlert 2, "Accept results?"
				
				if ( V_flag == 1 )
					
				elseif ( V_flag == 2 )
					continue
				elseif ( V_flag == 3 )
					break
				endif
				
			endif
			
		endif
		
		ncnt = numpnts( xWave )
		
		if ( found == 0 )
		
			Redimension /N=( ncnt+1 ) xWave, yWave
			xWave[ncnt] = Nan
			yWave[ncnt] = wcnt
			
		else
		
			Redimension /N=( ncnt+found ) xWave, yWave
			
			for ( scnt = 0 ; scnt < V_LevelsFound ; scnt += 1 )
			
				event = SP_xtimes[scnt]
				
				if ( numtype( event ) == 0 )
					xWave[ncnt] = event
					yWave[ncnt] = wcnt
					spkcnt += 1
					ncnt += 1
				endif
			
			endfor
		
		endif
		
		ncnt = numpnts( xWave )
			
		Redimension /N=( ncnt + 1 ) xWave, yWave
			
		xWave[ncnt] = Nan // add extra row for Nan's
		yWave[ncnt] = Nan
		
		wList = AddListItem( wName, wList, ";", inf )
		
	endfor
	
	NMNoteType( xRaster, "Spike RasterX", xl, yl, "Func:SpikeRaster" )
	Note $xRaster, "Spike Thresh:" + num2str( thresh ) + ";Spike Tbgn:" + num2str( tbgn ) + ";Spike Tend:" + num2str( tend ) + ";"
	Note $xRaster, "Spike Tmin:" + num2str( tmin ) + ";Spike Tmax:" + num2str( tmax ) + ";"
	Note $xRaster, "Spike Prefix:" + wavePrefix
	Note $xRaster, "Wave List:" + NMUtilityWaveListShort( wList )
	Note $xRaster, "Spike RasterY:" + yRaster
	
	xl = "Spike Event"
	yl = wavePrefix + " #"
	
	NMNoteType( yRaster, "Spike RasterY", xl, yl, "Func:SpikeRaster" )
	Note $yRaster, "Spike Thresh:" + num2str( thresh ) + ";Spike Tbgn:" + num2str( tbgn ) + ";Spike Tend:" + num2str( tend ) + ";"
	Note $yRaster, "Spike Tmin:" + num2str( tmin ) + ";Spike Tmax:" + num2str( tmax ) + ";"
	Note $yRaster, "Spike Prefix:" + wavePrefix
	Note $yRaster, "Wave List:" + NMUtilityWaveListShort( wList )
	Note $yRaster, "Spike RasterX:" + xRaster
	
	KillWaves /Z SP_xtimes
	KillWaves /Z $copy
	
	NMCurrentWaveSetNoUpdate( saveCurrentWave )
	
	return spkcnt // return spike count

End // SpikeRaster

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike Raster Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTmin( xRaster )
	String xRaster
	
	Variable tmin
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	tmin = NMNoteVarByKey( xRaster, "Spike Tmin" )
	
	if ( numtype( tmin ) == 0 )
		return tmin
	endif
	
	tmin = NMNoteVarByKey( xRaster, "Spike Tbgn" )
	
	if ( numtype( tmin ) == 0 )
		return tmin
	endif
	
	return leftx( $ChanDisplayWave( -1 ) )

End // SpikeTmin

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTmax( xRaster )
	String xRaster
	
	Variable tmax
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	tmax = NMNoteVarByKey( xRaster, "Spike Tmax" )
	
	if ( numtype( tmax ) == 0 )
		return tmax
	endif
	
	tmax = NMNoteVarByKey( xRaster, "Spike Tend" )
	
	if ( numtype( tmax ) == 0 )
		return tmax
	endif
	
	return rightx( $ChanDisplayWave( -1 ) )

End // SpikeTmax

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterCountSpikes( xRaster )
	String xRaster
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	if ( ( WaveExists( $xRaster ) == 1 ) && ( numpnts( $xRaster ) > 0 ) )
		WaveStats /Q/Z $xRaster
		return V_npnts
	else
		return 0
	endif
	
End // SpikeRasterCountSpikes

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterCountReps( yRaster )
	String yRaster
	
	Variable icnt, jcnt, rcnt
	
	if ( WaveExists( $yRaster ) == 0 )
		return 0
	endif
	
	WaveStats /Q/Z $yRaster
	
	Wave yWave = $yRaster
	
	for ( icnt = V_min ; icnt <= V_max ; icnt += 1 )
		for ( jcnt = 0 ; jcnt < numpnts( yWave ) ; jcnt += 1 )
			if ( yWave[jcnt] == icnt )
				rcnt += 1
				break
			endif
		endfor
	endfor
	
	return rcnt
	
End // SpikeRasterCountReps

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterNameX( yRaster )
	String yRaster
	
	String xRaster
	
	if ( WaveExists( $yRaster ) == 0 )
		NMError( 1, "SpikeRasterNameX", "yRaster", yRaster )
		return ""
	endif
	
	xRaster = NMNoteStrByKey( yRaster, "Spike RasterX" )
	
	if ( WaveExists( $xRaster ) == 1 )
		return xRaster
	endif
	
	if ( strsearch( xRaster, "SP_RY_", 0, 2 ) >= 0 )
	
		xRaster = ReplaceString( "SP_RY_", yRaster, "SP_RX_" )
		
		if ( WaveExists( $xRaster ) == 1 )
			return xRaster
		endif
		
	endif
	
	if ( strsearch( xRaster, "SP_RasterY_", 0, 2 ) >= 0 )
	
		xRaster = ReplaceString( "SP_RasterY_", yRaster, "SP_RasterX_" )
		
		if ( WaveExists( $xRaster ) == 1 )
			return xRaster
		endif
	
	endif
	
	return ""
	
End // SpikeRasterNameX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterNameY( xRaster )
	String xRaster
	
	String yRaster = ""
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	if ( WaveExists( $xRaster ) == 0 )
		NMError( 1, "SpikeRasterNameY", "xRaster", xRaster )
		return ""
	endif
	
	yRaster = NMNoteStrByKey( xRaster, "Spike RasterY" )
	
	if ( WaveExists( $yRaster ) == 1 )
		return yRaster
	endif
	
	if ( strsearch( xRaster, "SP_RX_", 0, 2 ) >= 0 )
	
		yRaster = ReplaceString( "SP_RX_", xRaster, "SP_RY_" )
	
		if ( WaveExists( $yRaster ) == 1 )
			return yRaster
		endif
		
	endif
	
	if ( strsearch( xRaster, "SP_RasterX_", 0, 2 ) >= 0 )
	
		yRaster = ReplaceString( "SP_RasterX_", xRaster, "SP_RasterY_" )
		
		if ( WaveExists( $yRaster ) == 1 )
			return yRaster
		endif
	
	endif
	
	return ""
	
End // SpikeRasterNameY

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterListStrict( rasterList )
	String rasterList
	
	Variable icnt
	String rasterName, wList = ""
	
	for ( icnt = 0 ; icnt < ItemsInList( rasterList ) ; icnt += 1 )
		
		rasterName = StringFromList( icnt, rasterList )
		
		if ( strsearch( rasterName, "_Rate", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "Rate_", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "_PSTH", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "PSTH_", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "_ISIH", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "ISIH_", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "_Intvls", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "Intvls_", 0, 2 ) > 0 )
			continue
		endif
		
		wList = AddListItem( rasterName, wList, ";", inf )
		
	endfor
	
	return wList
	
End // SpikeRasterListStrict

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterList() // old spike raster waves that DO NOT reside in spike subfolder

	String wList = WaveList( "SP_RasterX_*", ";", "Text:0" ) + WaveList( "SP_RX_*", ";", "Text:0" )
	
	return SpikeRasterListStrict( wList )

End // SpikeRasterList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike Raster Select Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMxWaveOrFolder()

	return StrVarOrDefault( CurrentNMPrefixFolder() + "SpikeRasterXSelect", "" )

End // NMxWaveOrFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMxWaveOrFolderSet( xWaveOrFolder )
	String xWaveOrFolder

	SetNMstr( CurrentNMPrefixFolder() + "SpikeRasterXSelect", xWaveOrFolder )
	
End // NMxWaveOrFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeRasterXSelectPrompt()

	String xRaster = NMxWaveOrFolder()
	
	if ( WaveExists( $xRaster ) == 0 )
		xRaster = " "
	endif
	
	Prompt xRaster, "select wave of spike times ( e.g. SP_RX_RAll_A0 ):", popup " ;" + WaveList( "*", ";", "Text:0" )
	DoPrompt "Spike Raster Plot", xRaster
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return xRaster

End // NMSpikeRasterXSelectPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeRasterXSelectCall( xWaveOrFolder )
	String xWaveOrFolder
	
	String vlist = ""
	
	String currentWaveOrFolder = NMxWaveOrFolder()
	
	if ( StringMatch( xWaveOrFolder, currentWaveOrFolder ) == 1 )
		return -1 // already selected
	endif
	
	if ( ( WaveExists( $xWaveOrFolder ) == 0 ) && ( DataFolderExists( xWaveOrFolder ) == 0 ) )
		return -1
	endif
	
	vlist = NMCmdStr( xWaveOrFolder, vlist )
	NMCmdHistory( "NMSpikeRasterXSelect", vlist )
		
	return NMSpikeRasterXSelect( xWaveOrFolder )
	
End // NMSpikeRasterXSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeRasterXSelect( xWaveOrFolder )
	String xWaveOrFolder
	
	String wName, path
	String subfolder = ParseFilePath( 0, xWaveOrFolder, ":", 1, 1 )
	
	if ( ( strlen( subfolder ) > 0 ) && ( DataFolderExists( subfolder ) == 1 ) )
	
		wName = ParseFilePath( 0, xWaveOrFolder, ":", 1, 0 )
		path = ParseFilePath( 1, xWaveOrFolder, ":", 1, 0 )
		
		SetNMstr( path + "RasterXSelect", wName )
		
		xWaveOrFolder = subfolder
		
	elseif ( ( DataFolderExists( xWaveOrFolder ) == 0 ) && ( WaveExists( $xWaveOrFolder ) == 0 ) )
	
		return -1
		
	endif
	
	NMxWaveOrFolderSet( xWaveOrFolder )
	UpdateSpike()
	
	return 0

End // NMSpikeRasterXSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMSpikeRasterXSelect()

	String wName, path

	String xWaveOrFolder = NMxWaveOrFolder()
	
	if ( DataFolderExists( xWaveOrFolder ) == 1 )
	
		path = GetDataFolder( 1 ) + xWaveOrFolder + ":"
		wName = StrVarOrDefault( path + "RasterXSelect", "" )
		
		if ( WaveExists( $path+wName ) == 1 )
			return path+wName
		endif
	
	elseif ( WaveExists( $xWaveOrFolder ) == 1 )
	
		return xWaveOrFolder
		
	endif

	return ""
	
End // CurrentNMSpikeRasterXSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMSpikeRasterXPath( xRaster )
	String xRaster
	
	if ( ( strlen( xRaster ) == 0 ) || ( StringMatch( xRaster, "_selected_" ) == 1 ) )
		return CurrentNMSpikeRasterXSelect()
	endif
	
	if ( WaveExists( $xRaster ) == 1 )
		return xRaster
	endif
	
	xRaster = GetDataFolder( 1 ) + xRaster // try subfolder
	
	if ( WaveExists( $xRaster ) == 1 )
		return xRaster
	endif
	
	return ""
	
End // CheckNMSpikeRasterXPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMSpikeRasterYPath( xRaster, yRaster )
	String xRaster, yRaster
	
	if ( strlen( yRaster ) == 0 )
		return SpikeRasterNameY( xRaster )
	endif
	
	if ( StringMatch( yRaster, "_selected_" ) == 1 )
		return SpikeRasterNameY( "_selected_" )
	endif
	
	if ( WaveExists( $yRaster ) == 1 )
		return yRaster
	endif
	
	yRaster = GetDataFolder( 1 ) + yRaster // try subfolder
	
	if ( WaveExists( $yRaster ) == 1 )
		return yRaster
	endif
	
	return ""
	
End // CheckNMSpikeRasterYPath

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike Analysis Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeAnalysisCall( fxn )
	String fxn
	
	strswitch( fxn )
			
		case "Raster":
			return SpikeRasterPlotCall()
	
		case "PSTH":
			return SpikePSTHCall()
			
		case "ISIH":
			return SpikeISIHCall()
			
		case "Rate":
			return SpikeRateCall()
			
		case "2Waves":
		case "Spike2Waves":
			return NMSpikes2WavesCall()
			
		case "Table":
			return SpikeTableCall()
			
		case "Delete Spike Subfolder":
			return NMSpikeFolderKillCall()
			
		default:
			NMDoAlert( "NMSpikeAnalysisCall: unrecognized function call: " + fxn )
			
	endswitch
	
	return ""
	
End // NMSpikeAnalysisCall

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSpikeAnalysisWaves( fxnName, xRaster, yRaster, yMustExist )
	String fxnName // function name
	String xRaster, yRaster
	Variable yMustExist // ( 0 ) no ( 1 ) yes
	
	Variable xpnts, ypnts
	String txt
	
	if ( WaveExists( $xRaster ) == 0 )
		NMErrorStr( 1, fxnName, "xRaster", xRaster )
		return -1
	endif
	
	if ( WaveExists( $yRaster ) == 1 )
	
		xpnts = numpnts( $xRaster )
		ypnts = numpnts( $yRaster )
		
		if ( xpnts != ypnts )
			NMDoAlert( fxnName + " Error: x- and y-raster waves have different length: " + num2istr( xpnts ) + " and " + num2istr( ypnts ) )
			return -1
		endif
	
	else
	
		txt = fxnName + " Alert: failed to find corresponding y-raster wave for " + NMQuotes( xRaster )
	
		if ( yMustExist == 1 )
			NMDoAlert( txt )
			return -1
		else
			NMHistory( txt )
			return 0
		endif
		
	endif
	
	return 0
	
End // CheckNMSpikeAnalysisWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeAnalysisTbgn( xRaster )
	String xRaster
	
	Variable tbgn = -inf
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	if ( WaveExists( $xRaster ) == 1 )

		tbgn = SpikeTmin( xRaster )
	
		if ( numtype( tbgn ) > 0 )
			return -inf
		endif
	
	endif
	
	return tbgn

End // NMSpikeAnalysisTbgn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeAnalysisTend( xRaster )
	String xRaster
	
	Variable tend = inf
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	if ( WaveExists( $xRaster ) == 1 )

		tend = SpikeTmax( xRaster )
		
		if ( numtype( tend ) > 0 )
			return inf
		endif
	
	endif
	
	return tend

End // NMSpikeAnalysisTend

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterPlotCall()
	
	String subfolder, xRasterSelect, xRasterList = "", vlist = ""
	
	String xRaster = "_selected_"
	String yRaster = ""
	
	String xWaveOrFolder = NMxWaveOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is currently no Spike Raster selection." )
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) == 1 )
		subfolder = CurrentNMFolder( 1 ) + xWaveOrFolder + ":"
		xRasterList = NMSpikeSubfolderRasterList( subfolder, 0, 0 )
	elseif ( WaveExists( $xWaveOrFolder ) == 0 )
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist." )
		return ""
	endif
	
	Variable tbgn = NMSpikeAnalysisTbgn( xRaster )
	Variable tend = NMSpikeAnalysisTend( xRaster )
	
	Prompt tbgn, "window begin time ( ms ):"
	Prompt tend, "window end time ( ms ):"
	
	if ( ItemsInList( xRasterList ) > 1 )

		xRaster = StrVarOrDefault( subfolder+"RasterXSelect", " " )
		xRasterSelect = xRaster

		Prompt xRasterSelect, "choose spike raster:", popup " ;" + xRasterList
		DoPrompt "Spike Raster Plot", xRasterSelect, tbgn, tend
		
		if ( ( V_flag == 1 ) || ( StringMatch( xRasterSelect, " " ) == 1 ) )
			return ""
		endif
		
		if ( StringMatch( xRasterSelect, xRaster ) == 1 )
			xRaster = "_selected_"
		else
			SetNMstr( subfolder+"RasterXSelect", xRaster )
			xRaster = xWaveOrFolder + ":" + xRaster
		endif
	
	else
	
		DoPrompt "Spike Raster Plot", tbgn, tend
		
		if ( V_flag == 1 )
			return ""
		endif
		
	endif
	
	vlist = NMCmdStr( xRaster, vlist )
	vlist = NMCmdStr( yRaster, vlist )
	vlist = NMCmdNum( tbgn, vlist )
	vlist = NMCmdNum( tend, vlist )
	NMCmdHistory( "SpikeRasterPlot", vlist )

	return SpikeRasterPlot( xRaster, yRaster, tbgn, tend )

End // SpikeRasterPlotCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterPlot( xRasterList, yRasterList, tbgn, tend )
	String xRasterList // x-raster wave list, ( "_selected_" ) for current selection
	String yRasterList // y-raster wave list, ( "" ) for automatic search based on x-raster
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	
	Variable wcnt, vertical, xpnts, ypnts, ymin = inf, ymax = -inf
	Variable yAxisOffset = 0.25
	
	String xRaster, yRaster, wName, gName, gTitle, eList, yl
	String thisfxn = "SpikeRasterPlot"
	
	Variable chan = CurrentNMChannel()
	Variable NumWaves = NMNumWaves()
	
	String wavePrefix = CurrentNMWavePrefix()
	
	if ( ItemsInList( xRasterList ) == 0 )
		return NMErrorStr( 21, thisfxn, "xRasterList", xRasterList )
	endif
	
	xRaster = StringFromList( 0, xRasterList )
	yRaster = StringFromList( 0, yRasterList )
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
	
	if ( CheckNMSpikeAnalysisWaves( thisfxn, xRaster, yRaster, 0 ) )
		return ""
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = SpikeTmin( xRaster )
	endif
	
	if ( numtype( tend ) > 0 )
		tend = SpikeTmax( xRaster )
	endif
	
	wName = GetPathName( xRaster, 0 )
	gName = "SP_" + NMFolderPrefix( "" ) + wName
	gTitle = NMFolderListName( "" ) + " : " + wName
	
	gName = ReplaceString( "SP_RX_", gName, "Rstr_" )
	gName = ReplaceString( "SP_RasterX_", gName, "Rstr_" )

	DoWindow /K $gName
	
	if ( ( strlen( yRaster ) > 0 ) && ( WaveExists( $yRaster ) == 1 ) )
	
		Display /K=1/N=$gName/W=( 0,0,0,0 ) $yRaster vs $xRaster as gTitle
		
		WaveStats /Q/Z $yRaster
		
		if ( V_min < ymin )
			ymin = V_min
		endif
		
		if ( V_max > ymax )
			ymax = V_max
		endif
		
		yl = NMNoteLabel( "y", yRaster, wavePrefix+" #" )
	
	else
	
		yRaster = ""
	
		Display /K=1/N=$gName/W=( 0,0,0,0 )/VERT $xRaster as gTitle
		vertical = 1
		
		yl = ""
		
	endif
	
	SetCascadeXY( gName )
	
	for ( wcnt = 1 ; wcnt < ItemsInList( xRasterList ) ; wcnt += 1 )
	
		xRaster = StringFromList( wcnt, xRasterList )
		yRaster = StringFromList( wcnt, yRasterList )
		
		xRaster = CheckNMSpikeRasterXPath( xRaster )
		yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
		
		if ( vertical == 1 )
		
			AppendToGraph /W=$gName/VERT $xRaster
		
		else
		
			if ( WaveExists( $yRaster ) == 0 )
				continue
			endif
			
			AppendToGraph /W=$gName $yRaster vs $xRaster
			
			WaveStats /Q/Z $yRaster
			
			if ( V_min < ymin )
				ymin = V_min
			endif
			
			if ( V_max > ymax )
				ymax = V_max
			endif
		
		endif
		
	endfor
	
	if ( numtype( tbgn * tend ) == 0 )
		SetAxis /W=$gName bottom tbgn, tend
	endif
	
	Label /W=$gName bottom NMNoteLabel( "y", xRaster, "msec" )
	
	ModifyGraph /W=$gName mode=3, marker=10, standoff=0, rgb=( 65535,0,0 )
	
	if ( vertical == 0 )
		SetAxis /W=$gName left ymin-yAxisOffset, ymax+yAxisOffset
		ModifyGraph /W=$gName manTick( left )={0,1,0,0},manMinor( left )={0,0}
		Label /W=$gName left yl
	else
		Label /W=$gName left yl
	endif
	
	return gName

End // SpikeRasterPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikePSTHCall()
	
	String subfolder, xRasterSelect, xRasterList = "", vlist = ""
	
	String xRaster = "_selected_"
	String yRaster = ""
	
	String xWaveOrFolder = NMxWaveOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is currently no Spike Raster selection." )
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) == 1 )
		subfolder = CurrentNMFolder( 1 ) + xWaveOrFolder + ":"
		xRasterList = NMSpikeSubfolderRasterList( subfolder, 0, 0 )
	elseif ( WaveExists( $xWaveOrFolder ) == 0 )
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist." )
		return ""
	endif
	
	Variable tbgn = NMSpikeAnalysisTbgn( xRaster )
	Variable tend = NMSpikeAnalysisTend( xRaster )
	
	Variable PSTHdelta = NMSpikeVar( "PSTHdelta" )
	String PSTHyaxis = NMSpikeStr( "PSTHyaxis" )
	
	Prompt tbgn, "window begin time ( ms ):"
	Prompt tend, "window end time ( ms ):"
	Prompt PSTHdelta, "histogram bin size ( ms ):"
	Prompt PSTHyaxis, "y-axis dimensions:", popup "Spikes / bin;Spikes / sec;Probability;"
	
	if ( ItemsInList( xRasterList ) > 1 )

		xRaster = StrVarOrDefault( subfolder+"RasterXSelect", " " )
		xRasterSelect = xRaster

		Prompt xRasterSelect, "choose spike raster:", popup " ;" + xRasterList
		DoPrompt "Compute Peri-Stimulus Time Histogram", xRasterSelect, tbgn, tend, PSTHdelta, PSTHyaxis
		
		if ( ( V_flag == 1 ) || ( StringMatch( xRasterSelect, " " ) == 1 ) )
			return ""
		endif
		
		if ( StringMatch( xRasterSelect, xRaster ) == 1 )
			xRaster = "_selected_"
		else
			SetNMstr( subfolder+"RasterXSelect", xRaster )
			xRaster = xWaveOrFolder + ":" + xRaster
		endif
	
	else
	
		DoPrompt "Compute Peri-Stimulus Time Histogram", tbgn, tend, PSTHdelta, PSTHyaxis
		
		if ( V_flag == 1 )
			return ""
		endif
		
	endif
	
	SetNMSpikeVar( "PSTHdelta", PSTHdelta )
	SetNMSpikeStr( "PSTHyaxis", PSTHyaxis )
	
	vlist = NMCmdStr( xRaster, vlist )
	vlist = NMCmdStr( yRaster, vlist )
	vlist = NMCmdNum( tbgn, vlist )
	vlist = NMCmdNum( tend, vlist )
	vlist = NMCmdNum( PSTHdelta, vlist )
	vlist = NMCmdStr( PSTHyaxis, vlist )
	NMCmdHistory( "SpikePSTH", vlist )
	
	return SpikePSTH( xRaster, yRaster, tbgn, tend, PSTHdelta, PSTHyaxis )

End // SpikePSTHCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikePSTH( xRaster, yRaster, tbgn, tend, PSTHdelta, PSTHyaxis )
	String xRaster // x-raster wave name, ( "_selected_" ) for current selection
	String yRaster // y-raster wave name, ( "" ) for automatic search based on x-raster
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	Variable PSTHdelta // histogram bin size
	String PSTHyaxis // "Spikes / bin" or "Spikes / sec" or "Probability"
	
	Variable npnts, reps, yMustExist
	String wName, subfolder, psthName, gName, gTitle, xl, thisfxn = "SpikePSTH"
	
	strswitch( PSTHyaxis )
		case "Probability":
		case "Spikes / sec":
		case "Spikes/sec":
			yMustExist = 1
	endswitch
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
	
	if ( CheckNMSpikeAnalysisWaves( thisfxn, xRaster, yRaster, yMustExist ) )
		return ""
	endif
	
	if ( ( numtype( PSTHdelta ) > 0 ) || ( PSTHdelta <= 0 ) )
		return NMErrorStr( 10, thisfxn, "PSTHdelta", num2str( PSTHdelta ) )
	endif
	
	xl = NMNoteLabel( "y", xRaster, "msec" )
	
	wName = GetPathName( xRaster, 0 )
	subfolder = GetPathName( xRaster, 1 )
	
	if ( StringMatch( NMSpikeStr( "WaveNamingFormat" ), "suffix" ) == 1 )
		psthName = wName + "_PSTH"
	else
		psthName = "PSTH_" + wName
	endif
	
	gName = "SP_" + NMFolderPrefix( "" ) + psthName
	gTitle = NMFolderListName( "" ) + " : " + psthName
	
	if ( numtype( tbgn ) > 0 )
		tbgn = SpikeTmin( xRaster )
	endif
	
	if ( numtype( tend ) > 0 )
		tend = SpikeTmax( xRaster )
	endif
	
	npnts = ceil( ( tend - tbgn ) / PSTHdelta )
	
	if ( strlen( subfolder ) > 0 )
		psthName = subfolder + psthName
	endif
	
	Make /O/N=1 $psthName
	
	Histogram /B={ tbgn, PSTHdelta, npnts } $xRaster, $psthName
	
	if ( WaveExists( $psthName ) == 0 )
		return "" // failed to create histogram
	endif
	
	Wave PSTH = $psthName
	
	strswitch( PSTHyaxis )
	
		case "Probability":
			
			reps = SpikeRasterCountReps( yRaster )
			
			if ( ( numtype( reps ) == 0 ) && ( reps > 0 ) )
				PSTH /= reps
			else
				PSTHyaxis = "Spikes / bin"
			endif
		
			break
		
		case "Spikes / sec":
		case "Spikes/sec":
			
			reps = SpikeRasterCountReps( yRaster )
			
			if ( ( numtype( reps ) == 0 ) && ( reps > 0 ) )
				PSTH /= reps * PSTHdelta * 0.001 // convert to seconds
			else
				PSTHyaxis = "Spikes / bin"
			endif
			
			break
			
		default:
		
			PSTHyaxis = "Spikes / bin"
			
	endswitch
	
	NMNoteType( psthName, "Spike PSTH", xl, PSTHyaxis, "Func:SpikePSTH" )
	Note $psthName, "PSTH Bin:" + num2str( PSTHdelta ) + ";PSTH Tbgn:" + num2str( tbgn ) + ";PSTH Tend:" + num2str( tend ) + ";"
	Note $psthName, "PSTH xRaster:" + xRaster
	Note $psthName, "PSTH yRaster:" + yRaster
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=( 0,0,0,0 ) PSTH as gTitle
	
	SetCascadeXY( gName )
	
	SetAxis /W=$gName bottom tbgn, tend
	ModifyGraph /W=$gName standoff=0, rgb=( 0,0,0 ), mode=5, hbFill=2
	
	Label /W=$gName bottom xl
	Label /W=$gName left PSTHyaxis
	
	return psthName

End // SpikePSTH

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeISIHCall()
	
	String subfolder, xRasterSelect, xRasterList = "", vlist = ""
	
	String xRaster = "_selected_"
	String yRaster = ""
	
	String xWaveOrFolder = NMxWaveOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is currently no Spike Raster selection." )
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) == 1 )
		subfolder = CurrentNMFolder( 1 ) + xWaveOrFolder + ":"
		xRasterList = NMSpikeSubfolderRasterList( subfolder, 0, 0 )
	elseif ( WaveExists( $xWaveOrFolder ) == 0 )
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist." )
		return ""
	endif
	
	Variable tbgn = NMSpikeAnalysisTbgn( xRaster )
	Variable tend = NMSpikeAnalysisTend( xRaster )
	
	Variable minIntvl = 0
	Variable maxIntvl = inf
	Variable binSize = NMSpikeVar( "ISIHdelta" )
	String ISIHyaxis = NMSpikeStr( "ISIHyaxis" )
	
	Prompt tbgn, "window begin time ( ms ):"
	Prompt tend, "window end time ( ms ):"
	Prompt minIntvl, "minimum allowed interval:"
	Prompt maxIntvl, "maximum allowed interval:"
	Prompt binSize, "histogram bin size ( ms ):"
	Prompt ISIHyaxis, "y-axis dimensions:", popup "Intvls / bin;Intvls / sec;"
	
	if ( ItemsInList( xRasterList ) > 1 )

		xRaster = StrVarOrDefault( subfolder+"RasterXSelect", " " )
		xRasterSelect = xRaster

		Prompt xRasterSelect, "choose spike raster:", popup " ;" + xRasterList
		DoPrompt "Compute InterSpike Interval Histogram", xRasterSelect, tbgn, tend, binSize, ISIHyaxis
		
		if ( ( V_flag == 1 ) || ( StringMatch( xRasterSelect, " " ) == 1 ) )
			return ""
		endif
		
		if ( StringMatch( xRasterSelect, xRaster ) == 1 )
			xRaster = "_selected_"
		else
			SetNMstr( subfolder+"RasterXSelect", xRaster )
			xRaster = xWaveOrFolder + ":" + xRaster
		endif
	
	else
	
		DoPrompt "Compute InterSpike Interval Histogram", tbgn, tend, binSize, ISIHyaxis
		
		if ( V_flag == 1 )
			return ""
		endif
		
	endif
	
	DoPrompt "Compute InterSpike Interval Histogram", minIntvl, maxIntvl
		
	if ( V_flag == 1 )
		return ""
	endif
	
	SetNMSpikeVar( "ISIHdelta", binSize )
	SetNMSpikeStr( "ISIHyaxis", ISIHyaxis )
	
	vlist = NMCmdStr( xRaster, vlist )
	vlist = NMCmdStr( yRaster, vlist )
	vlist = NMCmdNum( tbgn, vlist )
	vlist = NMCmdNum( tend, vlist )
	vlist = NMCmdNum( minIntvl, vlist )
	vlist = NMCmdNum( maxIntvl, vlist )
	vlist = NMCmdNum( binSize, vlist )
	vlist = NMCmdStr( ISIHyaxis, vlist )
	NMCmdHistory( "SpikeISIH", vlist )
	
	return SpikeISIH( xRaster, yRaster, tbgn, tend, minIntvl, maxIntvl, binSize, ISIHyaxis )

End // SpikeISIHCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeISIH( xRaster, yRaster, tbgn, tend, minIntvl, maxIntvl, binSize, ISIHyaxis )
	String xRaster // x-raster wave name, ( "_selected_" ) for current selection
	String yRaster // NOT USED, pass any string
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	Variable minIntvl // minimum allowed interval ( 0 ) for no lower limit
	Variable maxIntvl // maximum allowed interval ( inf ) for no upper limit
	Variable binSize // histogram bin size
	String ISIHyaxis // "Intvls / bin" or "Intvls / sec"
	
	Variable icnt, events
	String xl, wName, subfolder, ISIHname, intvlsName, gName, gTitle, thisfxn = "SpikeISIH"
	
	yRaster = "" // NOT USED
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	if ( WaveExists( $xRaster ) == 0 )
		return NMErrorStr( 1, "thisfxn", "xRaster", xRaster )
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = SpikeTmin( xRaster )
	endif
	
	if ( numtype( tend ) > 0 )
		tend = SpikeTmax( xRaster )
	endif
	
	if ( ( numtype( binSize ) > 0 ) || ( binSize <= 0 ) )
		return NMErrorStr( 10, thisfxn, "binSize", num2str( binSize ) )
	endif
	
	if ( ( numtype( minIntvl ) > 0 ) || ( minIntvl < 0 ) )
		minIntvl = 0
	endif
	
	if ( ( numtype( maxIntvl ) > 0 ) || ( maxIntvl <= 0 ) )
		maxIntvl = inf
	endif
	
	xl = NMNoteLabel( "y", xRaster, "msec" )
	
	events = Time2Intervals( xRaster, tbgn, tend, minIntvl, maxIntvl ) // results saved in U_INTVLS
	
	wName = GetPathName( xRaster, 0 )
	subfolder = GetPathName( xRaster, 1 )
		
	if ( ( events <= 0 ) || ( WaveExists( U_INTVLS ) == 0 ) )
		NMDoAlert( thisfxn + " Alert: no interspike intervals detected for raster wave " + wName )
		return ""
	endif
	
	if ( StringMatch( NMSpikeStr( "WaveNamingFormat" ), "suffix" ) == 1 )
		intvlsName = wName + "_Intvls"
		ISIHname = wName + "_ISIH"
	else
		intvlsName = "Intvls_" + wName
		ISIHname = "ISIH_" + wName
	endif
	
	gName = "SP_" + NMFolderPrefix( "" ) + ISIHname
	gTitle = NMFolderListName( "" ) + " : " + ISIHname
	
	if ( strlen( subfolder ) > 0 )
		intvlsName = subfolder + intvlsName
		ISIHname = subfolder + ISIHname
	endif
	
	WaveStats /Q/Z U_INTVLS
	
	Variable npnts = 2 + ( V_max - V_min ) / binSize
	
	Make /O/N=1 $ISIHname
	
	Histogram /B={ minIntvl, binSize, npnts } U_INTVLS, $ISIHname
	
	Wave ISIH = $ISIHname
	
	Duplicate /O U_INTVLS $intvlsName
	
	strswitch( ISIHyaxis )
	
		case "Intvls / sec":
		case "intvls/sec":
			ISIH /= binSize * 0.001
			break
	
		default:
		
			ISIHyaxis = "Intvls / bin"
			
	endswitch
	
	NMNoteType( intvlsName, "Spike Intervals", xl, ISIHyaxis, "Func:SpikeISIH" )
	Note $intvlsName, "ISIH Bin:" + num2str( binSize ) + ";ISIH Tbgn:" + num2str( tbgn ) + ";ISIH Tend:" + num2str( tend ) + ";"
	Note $intvlsName, "ISIH Min:" + num2str( minIntvl ) + ";ISIH Max:" + num2str( maxIntvl ) + ";"
	Note $intvlsName, "ISIH xRaster:" + xRaster
	
	NMNoteType( ISIHname, "Spike ISIH", xl, ISIHyaxis, "Func:SpikeISIH" )
	Note $ISIHname, "ISIH Bin:" + num2str( binSize ) + ";ISIH Tbgn:" + num2str( tbgn ) + ";ISIH Tend:" + num2str( tend ) + ";"
	Note $ISIHname, "ISIH Min:" + num2str( minIntvl ) + ";ISIH Max:" + num2str( maxIntvl ) + ";"
	Note $ISIHname, "ISIH xRaster:" + xRaster
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=( 0,0,0,0 ) ISIH as gTitle
	
	SetCascadeXY( gName )
	
	ModifyGraph standoff=0, rgb=( 0,0,0 ), mode=5, hbFill=2
	Label bottom xl
	Label left ISIHyaxis
	SetAxis/A
	
	NMHistory( "Spike Intervals stored in wave " + intvlsName )
	
	KillWaves /Z U_INTVLS
	
	return ISIHname
	
End // SpikeISIH

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeHazard( ISIHname ) // compute hazard function from ISI histogram
	String ISIHname // interspike interval wave name ( dimensions should be spikes / bin )
	
	Variable icnt, jcnt, ilimit, summ, delta
	String wName, subfolder, hazard
	
	if ( WaveExists( $ISIHname ) == 0 )
		return NMErrorStr( 1, "NMSpikeHazard", "ISIHname", ISIHname )
	endif
	
	wName = GetPathName( ISIHname, 0 )
	subfolder = GetPathName( ISIHname, 1 )
	
	hazard = wName
	hazard = ReplaceString( "ISIH_", hazard, "" )
	hazard = ReplaceString( "_ISIH", hazard, "" )
	
	if ( StringMatch( NMSpikeStr( "WaveNamingFormat" ), "suffix" ) == 1 )
		hazard = wName + "_Hazard"
	else
		hazard = "Hazard_" + wName
	endif
	
	hazard = subfolder + hazard
	
	Duplicate /O $ISIHname $hazard
	
	Wave ISIH = $ISIHname
	Wave HZD = $hazard
	
	delta = deltax( ISIH )
	ilimit = numpnts( ISIH )
	
	for ( icnt = 0 ; icnt < ilimit ; icnt+=1 )
	
		summ = 0
		
		for ( jcnt = icnt ; jcnt < ilimit ; jcnt += 1 )
			summ += ISIH[ jcnt ]
		endfor
		
		HZD[ icnt ] /= delta * summ
		
	endfor
	
	HZD *= 1000
	
	return hazard

End // NMSpikeHazard

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRateCall()
	
	String subfolder, xRasterSelect, xRasterList = "", vlist = ""
	
	String xRaster = "_selected_"
	String yRaster = ""
	
	String xWaveOrFolder = NMxWaveOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is currently no Spike Raster selection." )
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) == 1 )
		subfolder = CurrentNMFolder( 1 ) + xWaveOrFolder + ":"
		xRasterList = NMSpikeSubfolderRasterList( subfolder, 0, 0 )
	elseif ( WaveExists( $xWaveOrFolder ) == 0 )
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist." )
		return ""
	endif
	
	Variable tbgn = NMSpikeAnalysisTbgn( xRaster )
	Variable tend = NMSpikeAnalysisTend( xRaster )
	
	Prompt tbgn, "window begin time ( ms ):"
	Prompt tend, "window end time ( ms ):"
	
	if ( ItemsInList( xRasterList ) > 1 )

		xRaster = StrVarOrDefault( subfolder+"RasterXSelect", " " )
		xRasterSelect = xRaster

		Prompt xRasterSelect, "choose spike raster:", popup " ;" + xRasterList
		DoPrompt "Compute Spike Rate", xRasterSelect, tbgn, tend
		
		if ( ( V_flag == 1 ) || ( StringMatch( xRasterSelect, " " ) == 1 ) )
			return ""
		endif
		
		if ( StringMatch( xRasterSelect, xRaster ) == 1 )
			xRaster = "_selected_"
		else
			SetNMstr( subfolder+"RasterXSelect", xRaster )
			xRaster = xWaveOrFolder + ":" + xRaster
		endif
	
	else
	
		DoPrompt "Compute Spike Rate", tbgn, tend
		
		if ( V_flag == 1 )
			return ""
		endif
		
	endif
	
	vlist = NMCmdStr( xRaster, vlist )
	vlist = NMCmdStr( yRaster, vlist )
	vlist = NMCmdNum( tbgn, vlist )
	vlist = NMCmdNum( tend, vlist )
	NMCmdHistory( "SpikeRate", vlist )

	return SpikeRate( xRaster, yRaster, tbgn, tend )

End // SpikeRateCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRate( xRaster, yRaster, tbgn, tend )
	String xRaster // x-raster wave name, ( "_selected_" ) for current selection
	String yRaster // y-raster wave name, ( "" ) for automatic search based on x-raster
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	
	Variable icnt, jcnt, npnts, wnum, count, spikeTime, yMustExist = 0
	String xl, yl, wName, subfolder, rateName, gName, gTitle, wavePrefix, thisfxn = "SpikeRate"
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
	
	if ( CheckNMSpikeAnalysisWaves( thisfxn, xRaster, yRaster, yMustExist ) )
		return ""
	endif
	
	wName = GetPathName( xRaster, 0 )
	subfolder = GetPathName( xRaster, 1 )
	
	if ( StringMatch( NMSpikeStr( "WaveNamingFormat" ), "suffix" ) == 1 )
		rateName = wName + "_Rate"
	else
		rateName = "Rate_" + wName
	endif
	
	gName = "SP_" + NMFolderPrefix( "" ) + rateName
	gTitle = NMFolderListName( "" ) + " : " + rateName
	
	wavePrefix = NMNoteStrByKey( xRaster, "Spike Prefix" )
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = "Wave"
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = SpikeTmin( xRaster )
	endif
	
	if ( numtype( tend ) > 0 )
		tend = SpikeTmax( xRaster )
	endif
	
	if ( strlen( subfolder ) > 0 )
		rateName = subfolder + rateName
	endif
	
	Wave xRasterWave = $xRaster
	
	WaveStats /Q/Z xRasterWave
	
	npnts = V_NumNans
	
	if ( WaveExists( $yRaster ) == 1 )
	
		Wave yRasterWave = $yRaster
		
		WaveStats /Q/Z yRasterWave
		
		if ( ( numtype( V_max ) == 0 ) && ( V_max > 1 ) )
			npnts = V_max
		endif
		
		Make /O/N=( npnts+1 ) $rateName = Nan
		
		Wave wtemp = $rateName
		
		for ( icnt = 0 ; icnt < numpnts( xRasterWave ) ; icnt += 1 )
		
			wnum = yRasterWave[ icnt ]
			
			if ( numtype( wnum ) > 0 )
				continue
			endif
			
			jcnt = yRasterWave[ icnt ]
		
			if ( numtype( wtemp[ jcnt ] ) > 0 )
				wtemp[ jcnt ] = 0
			endif
		
			if ( ( xRasterWave[ icnt ] >= tbgn ) && ( xRasterWave[ icnt ] <= tend ) )
				wtemp[ jcnt ] += 1
			endif
			
		endfor
		
		xl = NMNoteLabel( "y", yRaster, wavePrefix+" #" )
	
	else
	
		Make /O/N=( npnts+1 ) $rateName = Nan
		
		Wave wtemp = $rateName
		
		wnum = 0
		count = 0
		
		for ( icnt = 0 ; icnt < numpnts( xRasterWave ) ; icnt += 1 )
		
			spikeTime = xRasterWave[ icnt ]
			
			if ( numtype( spikeTime ) > 0 )
				
				if ( count > 0 )
					wnum += 1
					count = 0
				endif
				
				continue
				
			endif
			
			if ( numtype( wtemp[ wnum ] ) > 0 )
				wtemp[ wnum ] = 0
			endif
		
			if ( ( spikeTime >= tbgn ) && ( spikeTime <= tend ) )
				wtemp[ wnum ] += 1
				count += 1
			endif
			
		endfor
		
		xl = "Wave #"
		yRaster = ""
		
		Redimension /N=(wnum+1) wtemp
	
	endif
	
	wtemp *= 1000 / ( tend - tbgn ) // convert to rate
	
	yl = "Spikes / sec"
	
	NMNoteType( rateName, "Spike Rate", xl, yl, "Func:SpikeRate" )
	Note $rateName, "Rate Tbgn:" + num2str( tbgn ) + ";Rate Tend:" + num2str( tend ) + ";"
	Note $rateName, "Rate xRaster:" + xRaster
	Note $rateName, "Rate yRaster:" + yRaster
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=( 0,0,0,0 ) $rateName as gTitle
	SetCascadeXY( gName )
	ModifyGraph /W=$gName standoff=0, rgb=( 65280,0,0 ), mode=4, marker=19
	Label /W=$gName bottom xl
	Label /W=$gName left yl
	
	WaveStats /Q/Z $rateName
	
	SetAxis /W=$gName left 0, V_max
	
	return rateName

End // SpikeRate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikes2WavesCall()

	Variable stop, moreTime
	String chanStr, chanList, wavePrefix
	String subfolder = "", xRasterSelect, xRasterList = "", vlist = ""
	
	Variable currentChan = CurrentNMChannel()
	Variable numChannels = NMNumChannels()
	
	String currentPrefix = CurrentNMWavePrefix()
	String defaultPrefix = NMSpikeStr( "S2W_WavePrefix" )
	
	String xRaster = "_selected_"
	String yRaster = ""
	
	String xWaveOrFolder = NMxWaveOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is currently no Spike Raster selection." )
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) == 1 )
		subfolder = CurrentNMFolder( 1 ) + xWaveOrFolder + ":"
		xRasterList = NMSpikeSubfolderRasterList( subfolder, 0, 0 )
	elseif ( WaveExists( $xWaveOrFolder ) == 0 )
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist." )
		return ""
	endif
	
	if ( ItemsInList( xRasterList ) > 1 )

		xRaster = StrVarOrDefault( subfolder+"RasterXSelect", " " )
		xRasterSelect = xRaster

		Prompt xRasterSelect, "choose spike raster:", popup " ;" + xRasterList
		DoPrompt "Copy Spikes to Waves", xRasterSelect
		
		if ( ( V_flag == 1 ) || ( StringMatch( xRasterSelect, " " ) == 1 ) )
			return ""
		endif
		
		if ( StringMatch( xRasterSelect, xRaster ) == 1 )
			xRaster = "_selected_"
		else
			SetNMstr( subfolder+"RasterXSelect", xRaster )
			xRaster = xWaveOrFolder + ":" + xRaster
		endif
	
	endif
	
	xRasterSelect = CheckNMSpikeRasterXPath( xRaster )
	wavePrefix = NMNoteStrByKey( xRasterSelect, "Spike Prefix" )
	subfolder = GetPathName( xRasterSelect, 1 )
	
	if ( StringMatch( currentPrefix, wavePrefix ) == 0 )
	
		xRasterSelect = GetPathName( xRasterSelect, 0 )
	
		DoAlert 1, "The current wave prefix does not match that of " + NMQuotes( xRasterSelect ) + ". Do you want to continue?"
		
		if ( V_Flag != 1 )
			return ""
		endif
		
	endif
	
	Variable beforeTime = NMSpikeVar( "S2W_TimeBefore" )
	Variable afterTime = NMSpikeVar( "S2W_TimeAfter" )
	Variable stopAtNextSpike = NMSpikeVar( "S2W_StopAtNextSpike" )
	Variable chanNum = NumVarOrDefault( subfolder+"S2W_ChanNum", currentChan )
	String outputWavePrefix = NMPrefixUnique( defaultPrefix )
	
	if ( chanNum >= numChannels )
		chanNum = currentChan
	endif
	
	if ( stopAtNextSpike < 0 )
		stop = 1 // No
	else
		stop = 2 // Yes
	endif
	
	Prompt beforeTime, "time before spike ( ms ):"
	Prompt afterTime, "time after spike ( ms ):"
	Prompt stop, "limit new waves to time before next spike?", popup "no;yes;"
	Prompt moreTime, "additional time to limit data before next spike ( ms ):"
	Prompt outputWavePrefix, "prefix name of new event waves:"
	
	if ( numChannels > 1 )
	
		if ( chanNum < 0 )
			chanStr = "All"
		else
			chanStr = ChanNum2Char( chanNum )
		endif
		
		chanList = "All;" + NMChanList( "CHAR" )
		
		Prompt chanStr, "channel waves to copy from:", popup chanList
		DoPrompt "Copy Spikes to Waves", chanStr, beforeTime, afterTime, stop, outputWavePrefix
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( StringMatch( chanStr, "All" ) == 1 )
			chanNum = -1
		else
			chanNum = ChanChar2Num( chanStr )
		endif
		
		SetNMvar( subfolder+"S2W_ChanNum", chanNum )
		
	else
	
		DoPrompt "Copy Spikes to Waves", beforeTime, afterTime, stop, outputWavePrefix
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		chanNum = currentChan
		
	endif
	
	SetNMSpikeVar( "S2W_TimeAfter", afterTime )
	SetNMSpikeVar( "S2W_TimeBefore", beforeTime )
	
	if ( stop == 2 ) // Yes
	
		if ( stopAtNextSpike < 0 )
			moreTime = 0
		else
			moreTime = stopAtNextSpike
		endif
		
		DoPrompt "Copy Spikes to Waves", moreTime
		
		if ( V_flag == 1 )
			return ""
		endif
		
		if ( ( numtype( moreTime ) == 0 ) && ( moreTime > 0 ) )
			stopAtNextSpike = moreTime
		else
			stopAtNextSpike = 0
		endif
		
	else // No
	
		stopAtNextSpike = -1
		
	endif
	
	SetNMSpikeVar( "S2W_StopAtNextSpike", stopAtNextSpike )
	
	outputWavePrefix = CheckNMPrefixUnique( outputWavePrefix, defaultPrefix, chanNum )
	
	if ( strlen( outputWavePrefix ) == 0 )
		return ""
	endif
	
	vlist = NMCmdStr( xRaster, vlist )
	vlist = NMCmdStr( yRaster, vlist )
	vlist = NMCmdNum( beforeTime, vlist )
	vlist = NMCmdNum( afterTime, vlist )
	vlist = NMCmdNum( stopAtNextSpike, vlist )
	vlist = NMCmdNum( chanNum, vlist )
	vlist = NMCmdStr( outputWavePrefix, vlist )
	
	NMCmdHistory( "NMSpikes2Waves", vlist )
	
	return NMSpikes2Waves( xRaster, yRaster, beforeTime, afterTime, stopAtNextSpike, chanNum, outputWavePrefix )
	
End // NMSpikes2WavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikes2Waves( xRaster, yRaster, beforeTime, afterTime, stopAtNextSpike, chanNum, outputWavePrefix )
	String xRaster // x-raster wave name, ( "_selected_" ) for current selection
	String yRaster // y-raster wave name, ( "" ) for automatic search based on x-raster
	Variable beforeTime, afterTime // save time before, after event time
	Variable stopAtNextSpike // ( < 0 ) no ( >= 0 ) yes... if greater than zero, use value to limit time before next spike
	Variable chanNum // channel number ( -1 ) for all
	String outputWavePrefix // prefix name for new waves
	
	Variable ccnt, cbgn, cend
	String wList, xl, yl, gPrefix, gName, gTitle, outList = ""
	String wname, wname2, thisfxn = "NMSpikes2Waves"
	
	Variable yMustExist = 1
	Variable allowTruncatedEvents = 1
	
	Variable numChannels = NMNumChannels()
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
	
	if ( CheckNMSpikeAnalysisWaves( thisfxn, xRaster, yRaster, yMustExist ) )
		return ""
	endif
	
	if ( ( numtype( beforeTime ) > 0 ) || ( beforeTime < 0 ) )
		return NMErrorStr( 10, thisfxn, "beforeTime", num2str( beforeTime ) )
	endif
	
	if ( ( numtype( afterTime ) > 0 ) || ( afterTime < 0 ) )
		return NMErrorStr( 10, thisfxn, "afterTime", num2str( afterTime ) )
	endif
	
	if ( ( numtype( stopAtNextSpike ) > 0 ) || ( stopAtNextSpike < 0 ) )
		stopAtNextSpike = 0
	endif
	
	if ( ( numtype( chanNum ) > 0 ) || ( chanNum >= numChannels ) )
		return NMErrorStr( 10, thisfxn, "chanNum", num2istr( chanNum ) )
	endif

	if ( chanNum < 0 )
		cbgn = 0
		cend = numChannels - 1
	else
		cbgn = chanNum
		cend = chanNum
	endif
	
	for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
	
		wList = NMEvent2Wave( yRaster, xRaster, beforeTime, afterTime, stopAtNextSpike, allowTruncatedEvents, ccnt, outputWavePrefix )
		
		if ( ItemsInList( wList ) == 0 )
			continue
		endif
		
		outList = NMAddToList( wList, outList, ";" )
		
		wname = outputWavePrefix + "Times"
		
		if ( WaveExists( $wname ) == 1 )
		
			wname2 = "SP_Times_" + outputWavePrefix
			
			Duplicate /O $wname, $wname2
			KillWaves /Z $wname
			
		endif
		
		xl = NMChanLabel( ccnt, "x", "" )
		yl = NMChanLabel( ccnt, "y", "" )
		
		gPrefix = outputWavePrefix + "_" + NMFolderPrefix( "" ) + ChanNum2Char( ccnt )
		gName = CheckGraphName( gPrefix )
		gTitle = NMFolderListName( "" ) + " : Ch " + ChanNum2Char( ccnt ) + " : " + outputWavePrefix
	
		NMPlotWavesOffset( gName, gTitle, xl, yl, "", wList, 0, 0, 0, 0 )
		
	endfor
	
	return outList

End // NMSpikes2Waves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeTableCall()

	String vlist = ""
	
	String xRaster = "_selected_"
	
	String xWaveOrFolder = NMxWaveOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is currently no Spike Raster selection." )
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) == 1 )
		return NMSpikeSubfolderTableCall()
	elseif ( WaveExists( $xWaveOrFolder ) == 0 )
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist." )
		return ""
	endif
	
	vlist = NMCmdStr( xRaster, vlist )
	NMCmdHistory( "SpikeTable", vlist )
	
	return SpikeTable( xRaster )

End // SpikeTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeTable( xRaster )
	String xRaster
	
	Variable icnt, yMustExist = 0
	String yRaster = "", wList = "", wList2, tname, title, thisfxn = "SpikeTable"
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
	
	if ( CheckNMSpikeAnalysisWaves( thisfxn, xRaster, yRaster, yMustExist ) )
		return ""
	endif
	
	tname = "SP_" + NMFolderPrefix( "" ) + ReplaceString( "SP_", xRaster, "" )
	title = NMFolderListName( "" ) + " : " + xRaster
	
	wList = AddListItem( xRaster, wList, ";", inf )
	
	if ( strlen( yRaster ) > 0 )
		wList= AddListItem( yRaster, wList, ";", inf )
	endif
	
	wList2 = WaveList( "*" + xRaster + "*", ";", "TEXT:0" )
	
	DoWindow /K $tname
	Edit /K=1/N=$tname/W=( 0,0,0,0 ) as title
	SetCascadeXY( tname )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
		AppendToTable $StringFromList( icnt, wList )
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( wList2 ) ; icnt += 1 )
		AppendToTable $StringFromList( icnt, wList2 )
	endfor
	
	return tname

End // SpikeTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeFolderKillCall()
	
	String vlist = ""
	String folder = "_selected_"
	
	String xWaveOrFolder = NMxWaveOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is currently no Spike Raster selection." )
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) == 0 )
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " is not a folder." )
		return ""
	endif
	
	DoAlert 1, "Are you sure you want to close subfolder " + NMQuotes( xWaveOrFolder ) + "?"
	
	if ( V_flag != 1 )
		return "" // cancel
	endif
	
	vlist = NMCmdStr( folder, vlist )
	NMCmdHistory( "NMSpikeFolderKill", vlist )
	
	return NMSpikeFolderKill( folder )

End // NMSpikeFolderKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeFolderKill( folder )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Spike folder
	
	String thisfxn = "NMSpikeFolderKill"
	
	if ( StringMatch( folder, "_selected_" ) == 1 )
		folder = CurrentNMFolder( 1 ) + NMxWaveOrFolder() + ":"
	endif
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	if ( StringMatch( folder, GetDataFolder( 1 ) ) ==1  )
		NMDoAlert( thisfxn + " Abort: cannot close the current data folder." )
		return "" // not allowed
	endif
	
	Variable error = NMSpikeSubfolderKill( folder )
	
	UpdateSpike()
	
	if ( error == 0 )
		return folder
	else
		return ""
	endif
	
End // NMSpikeFolderKill

//****************************************************************
//****************************************************************
//****************************************************************

Function XTimes2Spike() : GraphMarquee // use marquee x-values for spike t_bgn and t_end
	
	if ( ( DataFolderExists( SpikeDF() ) == 0 ) || ( IsCurrentNMTab( "Spike" ) == 0 ) )
		return 0 
	endif

	GetMarquee left, bottom
	
	if ( V_Flag == 0 )
		return 0
	endif
	
	SetNMSpikeVar( "Tbgn", V_left )
	SetNMSpikeVar( "Tend", V_right )
	
	AutoSpike()

End // XTimes2Spike

//****************************************************************
//****************************************************************
//****************************************************************