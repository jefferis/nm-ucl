#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Statistical Analysis Tab
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	NM tab entry "Stats"
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsPrefix( objName ) // tab prefix identifier
	String objName
	
	return "ST_" + objName
	
End // StatsPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsDF() // package full-path folder name

	return PackDF( "Stats" )
	
End // StatsDF

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab

	if ( enable == 1 )
		CheckPackage( "Stats", 1 ) // declare globals if necessary
		StatsChanCheck()
		StatsAmpWinBegin()
		DisableNMPanel( 0 )
		MakeStats( 0 ) // make controls if necessary
	endif
	
	StatsChanControlsEnableAll( enable )
	ChanGraphUpdate( -1, 1 )
	StatsDisplay( -1, enable ) // display/remove stat waves on active channel graph
	
	if ( enable == 1 )
		NMAutoStats()
	endif
	
End // StatsTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillStats( what )
	String what
	
	String sdf = StatsDF()
	
	strswitch( what )
	
		case "waves":
			return 0
			
		case "folder":
		
			if ( DataFolderExists( sdf ) == 1 )
			
				KillDataFolder $sdf
				
				if ( DataFolderExists( sdf ) == 1 )
					return -1 // failed to kill
				else
					return 0
				endif
				
			endif
			
			return 0
			
	endswitch
	
	return -1
	
End // KillStats

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Variables, Strings, Waves and folders
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsNumWindowsDefault()

	Variable numWindows = StatsNumWindows()
	
	if ( numWindows > 0 )
		return numWindows
	else
		return NMStatsVar( "NumWindows" )
	endif

End // NMStatsNumWindowsDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsNumWindows()

	String wName = StatsDF() + "AmpSlct"
	
	if ( WaveExists( $wName ) == 1 )
		return numpnts( $wName )
	endif
	
	return 0

End // StatsNumWindows

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMStatsWin( fxnName, win )
	String fxnName // function Name
	Variable win // Stats window number

	if ( win == -1 )
		win = NMStatsVar( "AmpNV" ) // currently selected Stats1 window
	endif

	if ( ( numtype( win ) > 0 ) || ( win < 0 ) || ( win >= StatsNumWindows() ) )
		NMError( 10, fxnName, "win", num2istr( win ) )
		return Nan
	endif
	
	return win

End // CheckNMStatsWin

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStats()
	
	return CheckNMStatsWaves( 0 ) 
	
End // CheckStats

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMStatsWaves( reset )
	Variable reset
	
	String sdf = StatsDF()
	
	if ( DataFolderExists( sdf ) == 0 )
		return NMError( 30, "CheckStatsWaves", "StatsDF", sdf )
	endif
	
	// waves to store all the stat window input/output parameters

	CheckNMStatsWaveT( "AmpSlct", "Off", reset )
	CheckNMStatsWave( "AmpB", -inf, reset )
	CheckNMStatsWave( "AmpE", inf, reset )
	
	CheckNMStatsWave( "AmpY", Nan, reset )
	CheckNMStatsWave( "AmpX", Nan, reset )
	
	CheckNMStatsWave( "Bflag", 0, reset )
	CheckNMStatsWaveT( "BslnSlct", "", reset )
	CheckNMStatsWave( "BslnB", 0, reset )
	CheckNMStatsWave( "BslnE", 0, reset )
	CheckNMStatsWave( "BslnSubt", 0, reset )
	
	CheckNMStatsWave( "BslnY", Nan, reset )
	CheckNMStatsWave( "BslnX", Nan, reset )
	
	CheckNMStatsWave( "RiseBP", 10, reset )
	CheckNMStatsWave( "RiseEP", 90, reset )
	
	CheckNMStatsWave( "RiseBX", Nan, reset )
	CheckNMStatsWave( "RiseEX", Nan, reset )
	CheckNMStatsWave( "RiseTm", Nan, reset )
	
	CheckNMStatsWave( "DcayP", 37, reset )
	
	CheckNMStatsWave( "DcayX", Nan, reset )
	CheckNMStatsWave( "DcayT", Nan, reset )
	
	CheckNMStatsWave( "dtFlag", 0, reset )
	CheckNMStatsWave( "SmthNum", 0, reset ) // filter/smooth number
	CheckNMStatsWaveT( "SmthAlg", "", reset ) // filter/smooth algorithm
	
	CheckNMStatsWaveT( "OffsetW", "", reset )
	
	CheckNMStatsWave( "ChanSelect", 0, reset )
	
	// waves for display graphs
	
	CheckNMWaveOfType( sdf+"ST_PntX", 1, Nan, "R" )
	CheckNMWaveOfType( sdf+"ST_PntY", 1, Nan, "R" )
	CheckNMWaveOfType( sdf+"ST_WinX", 2, Nan, "R" )
	CheckNMWaveOfType( sdf+"ST_WinY", 2, Nan, "R" )
	CheckNMWaveOfType( sdf+"ST_BslnX", 2, Nan, "R" )
	CheckNMWaveOfType( sdf+"ST_BslnY", 2, Nan, "R" )
	CheckNMWaveOfType( sdf+"ST_RDX", 2, Nan, "R" )
	CheckNMWaveOfType( sdf+"ST_RDY", 2, Nan, "R" )
	
	return 0

End // CheckNMStatsWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMStatsWave( wName, value, reset )
	String wName // wave name
	Variable value
	Variable reset
	
	String thisfxn = "CheckNMStatsWave", sdf = StatsDF()
	
	if ( strlen( wName ) == 0 )
		return NMError( 21, thisfxn, "wName", wName )
	endif
	
	if ( DataFolderExists( sdf ) == 0 )
		return NMError( 30, thisfxn, "StatsDF", sdf )
	endif
	
	if ( reset == 1 )
		return SetNMwave( sdf + wName, -1, value )
	else
		return CheckNMWaveOfType( sdf + wName, NMStatsNumWindowsDefault(), value, "R" )
	endif
	
End // CheckNMStatsWave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMStatsWaveT( wName, strvalue, reset )
	String wName // wave name
	String strvalue
	Variable reset
	
	String thisfxn = "CheckNMStatsWaveT", sdf = StatsDF()
	
	if ( strlen( wName ) == 0 )
		return NMError( 21, thisfxn, "wName", wName )
	endif
	
	if ( DataFolderExists( sdf ) == 0 )
		return NMError( 30, thisfxn, "StatsDF", sdf )
	endif
	
	if ( reset == 1 )
		return SetNMtwave( sdf + wName, -1, strvalue )
	else
		return CheckNMtwave( sdf + wName, NMStatsNumWindowsDefault(), strvalue )
	endif
	
End // CheckNMStatsWaveT

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsConfigEdit() // called from NM_Configurations

	String tName = NMStatsWinTable( "inputs" )

End // StatsConfigEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsConfigs() // called from NM_Configurations
	
	NMStatsConfigVar( "UseSubfolders", "use subfolders when creating Stats waves ( 0 ) no ( 1 ) yes ( use 0 for previous NM formatting )" )
	
	NMStatsConfigStr( "WaveNamingFormat", "attach new wave identifier as \"prefix\" or \"suffix\" ( use \"suffix\" for previous NM formatting )" )
	
	NMStatsConfigVar( "WaveLengthFormat", "Stats wave length matches number of ( 0 ) waves per channel ( 1 ) currently selected waves ( use 0 for previous NM formatting )" )
	
	NMStatsConfigVar( "AutoTable", "All Waves auto table ( 0 ) off ( 1 ) on" )
	NMStatsConfigVar( "AutoPlot", "All Waves auto plot ( 0 ) off ( 1 ) on" )
	NMStatsConfigVar( "AutoStats2", "All Waves auto Stats2 ( 0 ) off ( 1 ) on" )
	
	NMStatsConfigVar( "GraphLabelsOn", "Channel Stats number display ( 0 ) off ( 1 ) on" )
	
	NMStatsConfigStr( "AmpColor", "Amp display rgb color" )
	NMStatsConfigStr( "BaseColor", "Baseline display rgb color" )
	NMStatsConfigStr( "RiseColor", "Rise/decay display rgb color" )
	
	NMStatsConfigWaveT( "AmpSlct", "Off", "Measurement" )
	NMStatsConfigWave( "AmpB", 0, "Window begin time (ms)" )
	NMStatsConfigWave( "AmpE", 0, "Window end time (ms)" )
	
	NMStatsConfigWave( "Bflag", 0, "Compute baseline ( 0 ) no ( 1 ) yes" )
	NMStatsConfigWaveT( "BslnSlct", "Avg", "Baseline measurement" )
	NMStatsConfigWave( "BslnB", 0, "Baseline begin time (ms)" )
	NMStatsConfigWave( "BslnE", 0, "Baseline end time (ms)" )
	NMStatsConfigWave( "BslnSubt", 0, "Baseline auto subtract ( 0 ) no ( 1 ) yes" )
	
	NMStatsConfigWave( "RiseBP", 10, "Rise-time begin %" )
	NMStatsConfigWave( "RiseEP", 90, "Rise-time end %" )
	
	NMStatsConfigWave( "DcayP", 37, "Decay %" )
	
	NMStatsConfigWave( "dtFlag", 0, "channel transform ( 0 ) none ( 1 ) d/dt ( 2 ) dd/dt*dt ( 3 ) integral ( 4 ) normalize ( 5 ) dF/F0 ( 6 ) baseline" )
	
	NMStatsConfigWaveT( "SmthAlg", "binomial", "smooth/filter algorithm: binomial, boxcar, low-pass, high-pass" )
	NMStatsConfigWave( "SmthNum", 0, "Filter parameter number" )
	
	NMStatsConfigWave( "ChanSelect", 0, "Channel to analyze" )
	
	NMStatsConfigWaveT( "OffsetW", "", "Offset wave name ( /g for group num, /w for wave num )" )

End // StatsConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsConfigVar( varName, description )
	String varName
	String description
	
	return NMConfigVar( "Stats", varName, NMStatsVar( varName ), description )
	
End // NMStatsConfigVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsConfigStr( varName, description )
	String varName
	String description
	
	return NMConfigStr( "Stats", varName, NMStatsStr( varName ), description )
	
End // NMStatsConfigStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsConfigWave( wName, value, description )
	String wName // wave name
	Variable value
	String description

	return NMConfigWave( "Stats", wName, StatsNumWindows(), value, description )

End // NMStatsConfigWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsConfigWaveT( wName, strValue, description )
	String wName // wave name
	String strValue
	String description

	return NMConfigTWave( "Stats", wName, StatsNumWindows(), strValue, description )

End // NMStatsConfigWaveT

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsVar( varName )
	String varName
	
	String sdf = StatsDF()
	
	Variable defaultVal = Nan
	
	strswitch( varName )
	
		case "NumWindows":
			defaultVal = 10
			break
	
		case "UseSubfolders":
			defaultVal = 1
			break
			
		case "DisplayPrecision":
			defaultVal = 2 // decimal places
			break
			
		case "WaveLengthFormat":
			defaultVal = 1
			break
			
		case "ComputeAllWin":
			defaultVal = 1
			break
			
		case "ComputeAllDisplay":
			defaultVal = 1
			break
			
		case "ComputeAllSpeed":
			defaultVal = 0
			break
		
		case "AutoTable": // Compute All
			defaultVal = NumVarOrDefault( sdf+"TablesOn", 1 ) // ( 0 ) off ( 1 ) on
			break
			
		case "AutoPlot": // Compute All
			defaultVal = 1 // ( 0 ) off ( 1 ) on
			break
			
		case "AutoStats2": // Compute All
			defaultVal = 0 // ( 0 ) off ( 1 ) on
			break
			
		case "GraphLabelsOn":
			defaultVal = 1 // ( 0 ) off ( 1 ) on
			break
			
		case "Stats2DisplaySEM":
			defaultVal = 0 // ( 0 ) STDV ( 1 ) SEM
			break
			
		case "AmpNV":
			defaultVal = 0
			break
			
		case "AmpBV":
			defaultVal = 0
			break
			
		case "AmpEV":
			defaultVal = 0
			break
			
		case "AmpYV":
			defaultVal = Nan
			break
			
		case "AmpXV":
			defaultVal = Nan
			break
			
		case "BslnYV":
			defaultVal = Nan
			break
			
		case "Transform":
			defaultVal = 0
			break
			
		case "SmoothN":
			defaultVal = 0
			break
			
		case "OffsetSelect":
			defaultVal = 1
			break
			
		case "OffsetType":
			defaultVal = 1
			break
			
		case "OffsetBsln":
			defaultVal = 1
			break
			
		case "HistoBinSize":
			defaultVal = Nan
			break
			
		case "SortMethod":
			defaultVal = 1
			break
			
		case "SortCreateSet":
			defaultVal = 0
			break
			
		case "AlignAtTimeZero":
			defaultVal = 1
			break
			
		case "KSdsply":
			defaultVal = 1
			break
			
		case "WaveStatsTableOption":
			defaultVal = 1
			break
			
		case "EditAllOption":
			defaultVal = 1
			break
			
		case "PrintStatsOption":
			defaultVal = 1
			break
			
		case "PrintNotesOption":
			defaultVal = 1
			break
			
		case "PrintNamesOption":
			defaultVal = 1
			break
		
		case "PrintNamesFullpath":
			defaultVal = 0
			break
			
		case "ST_2AVG":
			defaultVal = Nan
			break
			
		case "ST_2SDV":
			defaultVal = Nan
			break
			
		case "ST_2SEM":
			defaultVal = Nan
			break
			
		case "ST_2CNT":
			defaultVal = Nan
			break
			
		case "ST_2Min":
			defaultVal = Nan
			break
			
		case "ST_2Max":
			defaultVal = Nan
			break
			
		default:
			NMDoAlert( "NMStatsVar Error: no variable called " + NMQuotes( varName ) )
			return Nan
	
	endswitch
	
	return NumVarOrDefault( sdf+varName, defaultVal )
	
End // NMStatsVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsStr( varName )
	String varName
	
	String defaultStr = ""
	
	strswitch( varName )
	
		case "WaveNamingFormat":
			defaultStr = "prefix"
			break
			
		case "WaveScaleAlg":
			defaultStr = "x"
			break
	
		case "AmpYVS":
			defaultStr = ""
			break
			
		case "BslnXVS":
			defaultStr = ""
			break
			
		case "SmoothA":
			defaultStr = ""
			break
			
		case "AmpColor":
			defaultStr = "65535,0,0"
			break
			
		case "BaseColor":
			defaultStr = "0,39168,0"
			break
			
		case "RiseColor":
			defaultStr = "0,0,65535"
			break
			
		case "OffsetWName":
			defaultStr = ""
			break
			
		default:
			NMDoAlert( "NMStatsStr Error: no variable called " + NMQuotes( varName ) )
			return ""
	
	endswitch
	
	return StrVarOrDefault( StatsDF() + varName, defaultStr )
			
End // NMStatsStr

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMStatsVar( varName, value )
	String varName
	Variable value
	
	String thisfxn = "SetNMStatsVar", sdf = StatsDF()
	
	if ( strlen( varName ) == 0 )
		return NMError( 21, thisfxn, "varName", varName )
	endif
		
	if ( DataFolderExists( sdf ) == 0 )
		return NMError( 30, thisfxn, "StatsDF", sdf )
	endif
	
	Variable /G $sdf+varName = value
	
	return 0
	
End // SetNMStatsVar

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMStatsStr( varName, strValue )
	String varName
	String strValue
	
	String thisfxn = "SetNMStatsStr", sdf = StatsDF()
	
	if ( strlen( varName ) == 0 )
		return NMError( 21, thisfxn, "varName", varName )
	endif
		
	if ( DataFolderExists( sdf ) == 0 )
		return NMError( 30, thisfxn, "StatsDF", sdf )
	endif
	
	String /G $sdf+varName = strValue
	
	return 0
	
End // SetNMStatsStr

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMStatsVar( varName )
	String varName
	
	if ( strlen( varName ) == 0 )
		return NMError( 21, "CheckNMStatsVar", "varName", varName )
	endif
	
	return SetNMStatsVar( varName, NMStatsVar( varName ) )

End // CheckNMStatsVar

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMStatsStr( varName )
	String varName
	
	if ( strlen( varName ) == 0 )
		return NMError( 21, "CheckNMStatsStr", "varName", varName )
	endif
	
	return SetNMStatsStr( varName, NMStatsStr( varName ) )

End // CheckNMStatsStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesCopy( fromDF, toDF )
	String fromDF // data folder copy from
	String toDF // data folder copy to
	
	String parent, wList, wList2, outList, sdf = StatsDF()
	String thisfxn = "StatsWavesCopy"
	
	fromDF = LastPathColon( fromDF, 1 )
	toDF = LastPathColon( toDF, 1 )
	
	if ( DataFolderExists( fromDF ) == 0 )
		return NMErrorStr( 30, thisfxn, "fromDF", fromDF )
	endif
	
	if ( WaveExists( $fromDF+"AmpE" ) == 0 )
		return NMErrorStr( 1, thisfxn, "AmpE", fromDF+"AmpE" )
	endif
	
	parent = GetPathName( toDF,1 )
	
	if ( DataFolderExists( parent ) == 0 )
		return NMErrorStr( 30, thisfxn, "toDF", parent ) // parent directory doesnt exist 
	endif
	
	if ( DataFolderExists( toDF ) == 0 )
		NewDataFolder $RemoveEnding( toDF, ":" ) // make "to" data folder
	endif
	
	wList = NMFolderWaveList( sdf, "*", ";", "", 0 )
	wList2 = NMFolderWaveList( sdf, "ST_*", ";", "",0 )
	
	wList = RemoveFromList( wList2, wList ) // remove display waves
	wList = RemoveFromList( "AmpX;BslnX;BslnY;RiseBX;RiseEX;RiseTm;DcayX;DcayT;WinSelect;", wList )
	
	return CopyWavesTo( fromDF, toDF, "", -inf, inf, wList, 0 )

End // StatsWavesCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMStatsFolderPath( folder )
	String folder
	
	String fName
	
	if ( strlen( folder ) == 0 )
		return CurrentNMFolder( 1 ) // current data folder
	endif
	
	if ( StringMatch( folder, "_subfolder_" ) == 1 )
		folder = CurrentNMStatsSubfolder()
		CheckNMStatsSubfolder( folder )
		return folder
	endif
	
	if ( StringMatch( folder, "_selected_" ) == 1 )
		return CurrentNMStats2FolderSelect( 1 )
	endif
	
	fName = GetPathName( folder, 0 )
	
	if ( StringMatch( fName, CurrentNMFolder( 0 ) ) == 1 )
		return CurrentNMFolder( 1 )
	elseif ( DataFolderExists( folder ) == 1 ) // subfolder exists
		return CurrentNMFolder( 1 ) + fName + ":"
	else
		return folder // DOES NOT SEEM TO EXIST
	endif
	
End // CheckNMStatsFolderPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMStatsWavePath( wName )
	String wName // wave name
	
	if ( ( strlen( wName ) == 0 ) || ( StringMatch( wName, "_selected_" ) == 1 ) )
		return CurrentNMStats2WaveSelect( 1 )
	endif
	
	if ( WaveExists( $wName ) == 1 )
		return wName
	endif
	
	wName = GetDataFolder( 1 ) + wName // try subfolder
	
	if ( WaveExists( $wName ) == 1 )
		return wName
	endif
	
	return ""
	
End // CheckNMStatsWavePath

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Tab Panel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeStats( force ) // create Stats tab controls
	Variable force
	
	Variable x0, y0, xinc, yinc, fs = NMPanelFsize(), taby = NMPanelTabY()
	String sdf = StatsDF()
	
	if ( IsCurrentNMTab( "Stats" ) == 0 )
		return 0
	endif
	
	ControlInfo /W=NMPanel ST_AmpSelect
	
	if ( ( V_Flag != 0 ) && ( force == 0 ) )
		return 0 // Stats tab controls exist
	endif
	
	if ( DataFolderExists( sdf ) == 0 )
		return 0 // stats has not been initialized yet
	endif
	
	CheckNMStatsVar( "AmpBV" )
	CheckNMStatsVar( "AmpEV" )
	CheckNMStatsVar( "AmpXV" )
	CheckNMStatsStr( "AmpYVS" )
	
	CheckNMStatsStr( "BslnXVS" )
	CheckNMStatsVar( "BslnYV" )
	
	CheckNMStatsVar( "SmoothN" )
	CheckNMStatsStr( "SmoothA" )
	
	CheckNMStatsVar( "ST_2AVG" )
	CheckNMStatsVar( "ST_2SDV" )
	CheckNMStatsVar( "ST_2SEM" )
	CheckNMStatsVar( "ST_2CNT" )
	
	DoWindow /F NMPanel
	
	x0 = 35
	xinc = 160
	y0 = taby + 60
	yinc = 24
	
	GroupBox ST_Group, title="Stats1", pos={x0-15, y0-30}, size={260,255}, win=NMPanel, fsize=fs
	
	PopupMenu ST_AmpSelect, pos={x0+85,y0-5}, bodywidth=135, win=NMPanel, fsize=fs
	PopupMenu ST_AmpSelect, value =StatsAmpDisplayList(), proc=NMStatsAmpPopup, win=NMPanel
	
	PopupMenu ST_WinSelect, pos={x0+180,y0-5}, bodywidth=85, win=NMPanel, fsize=fs
	PopupMenu ST_WinSelect, value="", proc=NMStatsWinPopup, win=NMPanel
	
	SetVariable ST_AmpBSet, title="t_bgn", pos={x0+18,y0+1*yinc}, size={115,50}, limits={-inf,inf,1}, win=NMPanel
	SetVariable ST_AmpBSet, value=$( sdf+"AmpBV" ), proc=NMStatsSetVariable, win=NMPanel, fsize=fs
	
	SetVariable ST_AmpESet, title="t_end", pos={x0+18,y0+2*yinc}, size={115,50}, limits={-inf,inf,1}, win=NMPanel
	SetVariable ST_AmpESet, value=$( sdf+"AmpEV" ), proc=NMStatsSetVariable, win=NMPanel, fsize=fs
	
	SetVariable ST_AmpYSet, title="y =", pos={x0+xinc,y0+1*yinc}, size={80,50}, limits={-inf,inf,0}, win=NMPanel
	SetVariable ST_AmpYSet, value=$( sdf+"AmpYVS" ), frame=0, proc=NMStatsSetVariable, win=NMPanel, fsize=fs
	
	SetVariable ST_AmpXSet, title="t =", pos={x0+xinc,y0+2*yinc}, size={80,50}, limits={-inf,inf,0}, win=NMPanel
	SetVariable ST_AmpXSet, value=$( sdf+"AmpXV" ), frame=0, proc=NMStatsSetVariable, win=NMPanel, fsize=fs
	
	SetVariable ST_FilterNSet, title="Filter", pos={x0+18,y0+3*yinc}, size={115,50}, limits={0,inf,1}, win=NMPanel
	SetVariable ST_FilterNSet, value=$( sdf+"SmoothN" ), proc=NMStatsSetVariable, win=NMPanel, fsize=fs
	
	SetVariable ST_FilterASet, title=" ", pos={x0+xinc,y0+3*yinc}, size={80,50}, win=NMPanel, fsize=fs, noedit=1
	SetVariable ST_FilterASet, value=$( sdf+"SmoothA" ), frame=0, proc=NMStatsSetVariable, win=NMPanel
	
	CheckBox ST_Baseline, title="Baseline", pos={x0,y0+4*yinc}, size={200,50}, value=0, proc=NMStatsCheckBox, win=NMPanel, fsize=fs
	SetVariable ST_BslnWin, title="b =", pos={x0+16,y0+4*yinc}, size={140,20}, win=NMPanel, proc=NMStatsSetVariable
	SetVariable ST_BslnWin, value=$( sdf+"BslnXVS" ), frame=0, win=NMPanel, fsize=fs, title = " "
	SetVariable ST_BslnSet, title="b =", pos={x0+xinc,y0+4*yinc}, size={80,20}, limits={-inf,inf,0}, win=NMPanel
	SetVariable ST_BslnSet, value=$( sdf+"BslnYV" ), frame=0, win=NMPanel, fsize=fs
	
	CheckBox ST_Transform, title="Transform", pos={x0,y0+5*yinc}, size={200,50}, value=0, proc=NMStatsCheckBox, win=NMPanel, fsize=fs
	
	CheckBox ST_Offset, title="Offset Time", pos={x0,y0+6*yinc}, size={200,50}, value=0, proc=NMStatsCheckBox, win=NMPanel, fsize=fs
	
	CheckBox ST_More, title="Auto", pos={x0,y0+7*yinc}, size={200,50}, value=0, proc=NMStatsCheckBox, win=NMPanel, fsize=fs
	
	y0 += 25
	
	Button ST_AllWaves, title="All Waves", pos={x0+65,y0+7*yinc}, size={100,20}, proc=NMStatsButton, win=NMPanel, fsize=fs
	
	xinc = 135
	y0 = taby + 320
	yinc = 25
	
	GroupBox ST_2Group, title="Stats2", pos={x0-15,y0-25}, size={260,135}, win=NMPanel, fsize=fs
	
	PopupMenu ST_2FolderSelect, value="Folder Select", bodywidth=230, pos={x0+180,y0}, proc=NMStats2FolderSelectPopup, win=NMPanel, fsize=fs
	
	PopupMenu ST_2WaveSelect, value="Wave Select", bodywidth=230, pos={x0+180,y0+1*yinc}, proc=NMStats2WaveSelectPopup, win=NMPanel, fsize=fs
	
	PopupMenu ST_2FxnSelect, value="Functions", bodywidth=230, pos={x0+180,y0+2*yinc}, proc=NMStats2FxnSelectPopup, win=NMPanel, fsize=fs
	
	x0 += 5
	y0 += 10 + 3 * yinc
	xinc = 80
	
	SetVariable ST_2AvgSet, title="\F'Symbol'm  =", pos={x0,y0}, size={85,50}, win=NMPanel, fsize=fs
	SetVariable ST_2AvgSet, value=$( sdf+"ST_2AVG" ), limits={-inf,inf,0}, frame=0, win=NMPanel
	
	SetVariable ST_2SDVSet, title="± ", pos={x0+85,y0}, size={75,50}, win=NMPanel, fsize=fs
	SetVariable ST_2SDVSet, value=$( sdf+"ST_2SDV" ), limits={0,inf,0}, frame=0, win=NMPanel
	
	//SetVariable ST_2SEMSet, title="± ", pos={x0+85,y0}, size={75,50}, win=NMPanel, fsize=fs, disable=1
	//SetVariable ST_2SEMSet, value=$( sdf+"ST_2SEM" ), limits={0,inf,0}, frame=0, win=NMPanel
	
	SetVariable ST_2CNTSet, title="n  =", pos={x0+165,y0}, size={70,50}, win=NMPanel, fsize=fs
	SetVariable ST_2CNTSet, value=$( sdf+"ST_2CNT" ), limits={0,inf,0}, format="%.0f", frame=0, win=NMPanel
	
	UpdateStats()
	
	return 0

End // MakeStats

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateStats()

	UpdateStats1()
	UpdateStats2()

End // UpdateStats

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateStats1() // update/display current window result values

	Variable off, v1, v2, modeNum, dis2, dis, xdis, yframe, xframe
	Variable displayPrecision = NMStatsVar( "DisplayPrecision" )
	
	String tstr, xtl, ytl, select, moreList = ""
	String cdf, df = StatsDF()

	if ( ( WaveExists( $df+"AmpB" ) == 0 ) || ( IsCurrentNMTab( "Stats" ) == 0 ) )
		return 0
	endif

	Variable currentChan = CurrentNMChannel()
	
	String formatStr = NMStatsPrecisionStr()
	
	cdf =  ChanFuncDF( currentChan )
	
	CheckStatsWindowSelect()
	
	Variable ampNV = NMStatsVar( "AmpNV" )
	Variable ampBV = NMStatsVar( "AmpBV" )
	Variable ampEV = NMStatsVar( "AmpEV" )
	Variable ampYV = NMStatsVar( "AmpYV" )
	Variable ampXV = NMStatsVar( "AmpXV" )
	Variable bslnYV = NMStatsVar( "BslnYV" )
	Variable filterN = NMStatsVar( "SmoothN" )
	
	String filterA = NMStatsStr( "SmoothA" )
	String ampYVS = NMStatsStr( "AmpYVS" )
	
	Wave AmpB = $df+"AmpB"
	Wave AmpE = $df+"AmpE"
	Wave AmpY = $df+"AmpY"
	Wave AmpX = $df+"AmpX"
	
	Wave /T BslnSlct = $df+"BslnSlct"
	Wave Bflag = $df+"Bflag"
	Wave BslnY = $df+"BslnY"
	Wave BslnB = $df+"BslnB"
	Wave BslnE = $df+"BslnE"
	
	Wave RiseBP = $df+"RiseBP"
	Wave RiseEP = $df+"RiseEP"
	
	Wave DcayP = $df+"DcayP"
	Wave DcayT = $df+"DcayT"
	
	Wave dtFlag = $df+"dtFlag"
	Wave FilterNum = $df+"SmthNum"
	Wave /T FilterAlg = $df+"SmthAlg"
	
	select = StatsAmpSelectGet( ampNV )
	
	if ( StringMatch( select, "Off" ) == 1 )
		off = 1
		dis2 = 2
	endif
	
	SetVariable ST_AmpBSet, win=NMPanel, disable=dis2, format=formatStr
	SetVariable ST_AmpESet, win=NMPanel, disable=dis2, format=formatStr
	
	select =	StatsAmpMenuSwitch( select )
	
	ampBV = AmpB[ ampNV ]
	ampEV = AmpE[ ampNV ]
	ampYV = AmpY[ ampNV ]
	ampXV = AmpX[ ampNV ]
	bslnYV = BslnY[ ampNV ]
	
	sprintf ampYVS, formatStr, ampYV
	
	filterN = FilterNum[ ampNV ]
	filterA = FilterAlg[ ampNV ]
	
	tstr = " "
	
	if ( filterN > 0 )
		tstr = "s ="
	endif
	
	SetVariable ST_FilterASet, win=NMPanel, title=tstr, disable=dis2
	
	tstr = "Filter"
	
	strswitch( filterA )
	
		case "binomial":
		case "boxcar":
			tstr = "Smooth"
			break
			
		case "low-pass":
		case "high-pass":
			tstr = "Filter"
			break
			
	endswitch
	
	SetVariable ST_FilterNSet, win=NMPanel, title=tstr, disable=dis2, format=formatStr
	
	if ( ( Bflag[ ampNV ] == 1 ) && ( off == 0 ) )
		sprintf tstr, "Bsln (" + BslnSlct[ ampNV ] + ", %.1f, %.1f)", BslnB[ ampNV ], BslnE[ ampNV ]
		SetNMStatsStr( "BslnXVS", tstr )
		CheckBox ST_Baseline, win=NMPanel, disable=0, value=1, title= " "
		SetVariable ST_BslnWin, win=NMPanel, disable=0
		SetVariable ST_BslnSet, win=NMPanel, disable=0, format=formatStr
	else
		
		SetNMStatsStr( "BslnXVS", "Baseline" )
		CheckBox ST_Baseline, win=NMPanel, disable=dis2, value=0, title=" "
		SetVariable ST_BslnWin, win=NMPanel, disable=dis2
		SetVariable ST_BslnSet, win=NMPanel, disable=1, format=formatStr
	endif
	
	if ( strlen( cdf ) > 0 )
		SetNMVar( cdf+"Ft", dtFlag[ ampNV ] ) // set channel Transform fxn
	endif
	
	if ( dtFlag[ ampNV ] <= 0 )
		CheckBox ST_Transform, win=NMPanel, value=0, disable=dis2, title="Transform"
	else
		CheckBox ST_Transform, win=NMPanel, value=1, disable=dis2, title=ChanFuncNum2Name( dtFlag[ ampNV ] )
	endif
	
	if ( WaveExists( $NMStatsOffsetWaveName( ampNV ) ) == 1 )
		CheckBox ST_Offset, win=NMPanel, value=1, disable=dis2, title="Offset Time = " + num2str( StatsOffsetValue( ampNV ) )
	else
		CheckBox ST_Offset, win=NMPanel, value=0, disable=dis2, title="Offset Time"
	endif
	
	if ( NMStatsVar( "AutoTable" ) == 1 )
		moreList += " table,"
	endif
	
	if ( NMStatsVar( "AutoPlot" ) == 1 )
		moreList += " plot,"
	endif
	
	if ( NMStatsVar( "AutoStats2" ) == 1 )
		moreList += " stats2,"
	endif
	
	if ( NMStatsVar( "UseSubfolders" ) == 1 )
		moreList += " subfolders,"
	endif
	
	if ( ItemsInList( moreList, "," ) == 0 )
		CheckBox ST_More, win=NMPanel, value=0, disable=dis2, title="More"
	else
		moreList = "(" + moreList + ")"
		moreList = ReplaceString( ",)", moreList, " )" )
		CheckBox ST_More, win=NMPanel, value=1, disable=dis2, title="More " + moreList
	endif
	
	xtl = "t ="
	ytl = "y ="
		
	strswitch( select )
	
		case "Max":
		case "Min":
			break
			
		case "Avg":
		case "SDev":
		case "Var":
		case "RMS":
		case "Area":
		case "Sum":
			xdis = 1
			break
			
		case "Level":
		case "Level+":
		case "Level-":
			yframe = 1
			break
			
		case "Slope":
		case "RTslope":
		case "RTslope ":
			xtl = "b ="
			ytl = "m ="
			break
			
		case "RiseTime":
		case "RiseTime ":
			ampYVS = num2str( RiseBP[ ampNV ] ) + " - " + num2str( RiseEP[ ampNV ] ) + "%"
			yframe = 1
			break
			
		case "DecayTime":
		case "DecayTime ":
			ampYVS = num2str( DcayP[ ampNV ] ) + "%"
			yframe = 1
			break
			
		case "FWHM":
		case "FWHM ":
			ampYVS = "50 - 50%"
			break
			
		case "Off":
			dis = 1
			break
			
		default:
		
			if ( ( StringMatch( select[ 0,5 ], "MaxAvg" ) == 1 ) || ( StringMatch( select[ 0,5 ], "MinAvg" ) == 1 ) )
				select = select[ 0,5 ]
				ampXV = StatsMaxMinWinGet( ampNV )
				xtl = "w ="
				xframe = 1
			endif
			
	endswitch
	
	SetVariable ST_AmpYSet, win=NMPanel, title=ytl, frame=yframe, disable=dis
	SetVariable ST_AmpXSet, win=NMPanel, title=xtl, frame=xframe, format=formatStr, disable=(dis||xdis)
	
	modenum = 1 + WhichListItem( select, StatsAmpDisplayList(), ";", 0, 0 )
	
	PopupMenu ST_AmpSelect, win=NMPanel, mode = modeNum // reset menu display mode
	
	UpdateNMStatsWinSelect()
	
	DoWindow /F NMpanel // brings back to front for more input
	
	SetNMStatsVar( "AmpNV", AmpNV )
	SetNMStatsVar( "AmpBV", AmpBV )
	SetNMStatsVar( "AmpEV", AmpEV )
	SetNMStatsVar( "AmpYV", AmpYV )
	SetNMStatsVar( "AmpXV", AmpXV )
	SetNMStatsVar( "BslnYV", BslnYV )
	SetNMStatsVar( "SmoothN", FilterN )
	
	SetNMStatsStr( "SmoothA", FilterA )
	SetNMStatsStr( "AmpYVS", AmpYVS )
	
	return 0

End // UpdateStats1

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMStatsWinSelect()

	Variable ampNV = NMStatsVar( "AmpNV" )

	PopupMenu ST_WinSelect, value=NMStatsWinMenu(), mode=( ampNV+1 ), win=NMPanel

End // UpdateNMStatsWinSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsWinMenu()

	return NMStatsWinList( 0, "Win" ) + ";---;More / Less;Reset All;Edit All Inputs;Edit All Outputs;"

End // NMStatsWinMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsPrecisionStr()

	Variable precision = NMStatsVar( "DisplayPrecision" )
	
	precision = max( precision, 1 )
	precision = min( precision, 5 )

	return "%." + num2istr( precision ) + "f"

End // NMStatsPrecisionStr

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateStats2()

	Variable md
	String wName, folder, sdf = StatsDF()
	
	CheckNMStats2FolderWaveSelect()

	folder = CurrentNMStats2FolderSelect( 0 )
	wName = CurrentNMStats2WaveSelect( 0 )
	
	if ( ( DataFolderExists( sdf ) == 0 ) || ( IsCurrentNMTab( "Stats" ) == 0 ) )
		return 0
	endif
	
	md = 1 + WhichListItem( folder, NMStats2FolderMenu() )
	
	PopupMenu ST_2FolderSelect, win=NMPanel, value=NMStats2FolderMenu(), mode=max(1,md)
	
	md = 1 + WhichListItem( wName, NMStats2WaveMenu() )
		
	PopupMenu ST_2WaveSelect, win=NMPanel, value = NMStats2WaveMenu(), mode=max(1,md)
	
	PopupMenu ST_2FxnSelect, win=NMPanel, value = NMStats2FunctionMenu(), mode=1
	
	SetVariable ST_2AvgSet, win=NMPanel, format=NMStatsPrecisionStr()
	
	if ( NMStatsVar( "Stats2DisplaySEM" ) == 1 )
		SetVariable ST_2SDVSet, win=NMPanel, format=NMStatsPrecisionStr(), value=$( sdf+"ST_2SEM" )
	else
		SetVariable ST_2SDVSet, win=NMPanel, format=NMStatsPrecisionStr(), value=$( sdf+"ST_2SDV" )
	endif
	
	NMStats2WaveStats( "_selected_", 0 )
	
	DoWindow /F NMpanel // brings back to front for more input
	
	return 0

End // UpdateStats2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2FolderMenu()

	String folderMenu = "Folder Select;---;" + NMStats2FolderList( 1 )
	
	if ( StringMatch( CurrentNMStats2FolderSelect( 0 ), GetDataFolder( 0 ) ) == 0 )
		folderMenu += "---;Delete Stats Subfolder;"
	endif
	
	return folderMenu

End // NMStats2FolderMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveMenu()

	String wList = NMStats2WaveSelectList( 0 )
	
	if ( ItemsInList( wList ) == 0 )
		return "No Stats Waves;---;Change This List;"
	endif
	
	return "Wave Select;---;" + NMStats2WaveSelectList( 0 ) + "---;Change This List;"

End // NMStats2WaveMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2FunctionMenu()
	
	String menuList = "Functions;---;Plot;Edit;Print Stats;Print Note;Print Name;Histogram;Sort Wave;Stability;Significant Difference;Use For Wave Scaling;Use For Wave Alignment;"
	
	menuList += "---;Stats Table All;Edit All;Print Stats All;Print Notes All;Print Names All;"

	return menuList

End // NMStats2FunctionMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
	
	StatsCall( ctrlName, "" )
	
End // NMStatsButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
	
	StatsCall( ctrlName, num2istr( checked ) )
	
End // NMStatsCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsTransformCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	StatsCall( "Transform", num2istr( checked ) )
	
End // NMStatsTransformCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
	
	StatsCall( ctrlName, varStr )
	
End // NMStatsSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsSetFilter( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	StatsCall( "FilterNSet", varStr )
	
End // NMStatsSetFilter

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsAmpPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	strswitch( popStr )
	
		case "---":
		case " ":
		case "--- Pos Peaks ---":
		case "--- Neg Peaks ---":
			return UpdateStats1()
			
		default:
		
			popStr = StatsAmpMenuSwitch( popStr )
			
			return NMStatsAmpSelectCall( Nan, Nan, popStr )
	
	endswitch

End // NMStatsAmpPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsWinPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	Variable win
	
	strswitch( popStr )
	
		case "---":
			return UpdateNMStatsWinSelect()
	
		case "Edit All Inputs":
			NMStatsWinTable( "inputs" )
			return UpdateNMStatsWinSelect()
			
		case "Edit All Outputs":
			NMStatsWinTable( "outputs" )
			return UpdateNMStatsWinSelect()
			
		case "Reset All":
			CheckNMStatsWaves( 1 )
			return UpdateStats1()
			
			
		case "More / Less":
			if ( StatsNumWindowsCall() < 0 )
				UpdateStats1()
			endif
			return 0
			
		default:
		
			win = str2num( popStr[ 3,inf ] )
			
			if ( numtype( win ) > 0 )
				UpdateStats1()
				return 0
			endif
			
			return StatsWinSelectCall( win )
			
	endswitch
	
End // NMStatsWinPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStats2FolderSelectPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
		
	strswitch( popStr )

		case "Folder Select":
		case "---":
			break
		
		case "Clear Stats Subfolder":
		case "Delete Stats Subfolder":
			NMStats2Call( popStr, "" )
			break
			
		default:
			NMStats2Call( ctrlName, popStr )
			
	endswitch
	
	UpdateStats2()

End // NMStats2FolderSelectPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStats2WaveSelectPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
	
	strswitch( popStr )

		case "Wave Select":
		case "No Stats Waves":
		case "---":
			break
			
		case "Change This List":
			NMStats2WaveSelectFilterCall()
			return 0
			
		default:
			NMStats2Call( ctrlName, popStr )
			
	endswitch		
	
	UpdateStats2()

End // NMStats2WaveSelectPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStats2FxnSelectPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
		
	PopupMenu ST_2FxnSelect, win=NMPanel, mode=1

	strswitch( popStr )
	
		case "---":
			break
			
		default:
			NMStats2Call( popStr, "" )
			
	endswitch
	
	UpdateStats2()

End // NMStats2FxnSelectPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsAmpMenuSwitch( select )
	String select
	Variable direction

	strswitch( select )
	
		case "RiseTime+":
			return "RiseTime"
		case "RiseTime-":
			return "RiseTime "
		case "RTslope+":
			return "RTslope"
		case "RTslope-":
			return "RTslope "
		case "DecayTime+":
			return "DecayTime"
		case "DecayTime-":
			return "DecayTime "
		case "FWHM+":
			return "FWHM"
		case "FWHM-":
			return "FWHM "
			
		case "RiseTime":
			return "RiseTime+"
		case "RiseTime ": // extra space at end
			return "RiseTime-"
		case "RTslope":
			return "RTslope+"
		case "RTslope ": // extra space at end
			return "RTslope-"
		case "DecayTime":
			return "DecayTime+"
		case "DecayTime ": // extra space at end
			return "DecayTime-"
		case "FWHM":
			return "FWHM+"
		case "FWHM ": // extra space at end
			return "FWHM-"
			
	endswitch
	
	return select
	
End // StatsAmpMenuSwitch

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Set Global Variables, Strings and Waves
//
//****************************************************************
//****************************************************************
//****************************************************************

Function StatsCall( fxn, select )
	String fxn, select
	
	Variable error
	Variable snum = str2num( select )
	
	strswitch( fxn )
			
		case "AmpBSet":
			error = NMStatsAmpSelectCall( snum, Nan, "" )
			break
			
		case "AmpESet":
			error = NMStatsAmpSelectCall( Nan, snum, "" )
			break
			
		case "AmpYSet":
			error = StatsLevelCall( snum )
			break
			
		case "AmpXSet":
			error = StatsMaxMinWinSetCall( snum )
			break
			
		case "SmthNSet":
		case "FilterNSet":
			error = StatsFilterCall( "old", snum )
			break
			
		case "SmthASet":
		case "FilterASet":
			error = StatsFilterCall( select, -1 )
			break
	
		case "Baseline":
			error = StatsBslnCall( snum, Nan, Nan )
			break
			
		case "BslnWin":
			error = StatsBslnCallStr( select )
			break
			
		case "RiseTime":
		case "Rise Time":
			error = StatsRiseTimeCall( snum )
			break
			
		case "DecayTime":
		case "Decay Time":
			error = StatsDecayTimeCall( snum )
			break
			
		case "Ft":
		case "Transform":
			error = NMStatsTransformCall( snum )
			break
	
		case "Offset":
			error = StatsOffsetWinCall( snum )
			break
		
		case "More":
			error = NMStatsAutoCall()
			break
			
		case "AllWaves":
		case "All Waves":
			error = NMStatsComputeAllCall()
			break
			
		default:
			error = 20
			NMError( error, "StatsCall", "fxn", fxn )
			
	endswitch
	
	if ( error != 0 )
		UpdateStats1()
	endif
	
	return error
	
End // StatsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTimeStamp( df ) // place time stamp on AmpSlct
	String df
	
	String thisfxn = "StatsTimeStamp"
	String wName = df + "AmpSlct"
	
	if ( DataFolderExists( df ) == 0 )
		return NMError( 30, thisfxn, "df", df )
	endif
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	Note /K $wName
	Note $wName, "Stats Date:" + date()
	Note $wName, "Stats Time:" + time()
	
	return 0

End // StatsTimeStamp

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTimeStampCompare( df1, df2 )
	String df1, df2
	Variable ok
	
	String d1, d2, t1, t2, thisfxn = "StatsTimeStampCompare"
	
	String wName1 = df1 + "AmpSlct"
	String wName2 = df2 + "AmpSlct"
	
	if ( DataFolderExists( df1 ) == 0 )
		return 0
	endif
	
	if ( DataFolderExists( df2 ) == 0 )
		return 0
	endif
	
	if ( WaveExists( $wName1 ) == 0 )
		return 0
	endif
	
	if ( WaveExists( $wName2 ) == 0 )
		return 0
	endif
	
	df1 = LastPathColon( df1, 1 )
	df2 = LastPathColon( df2, 1 )
	
	d1 = NMNoteStrByKey( df1+"AmpSlct", "Stats Date" )
	d2 = NMNoteStrByKey( df2+"AmpSlct", "Stats Date" )
	t1 = NMNoteStrByKey( df1+"AmpSlct", "Stats Time" )
	t2 = NMNoteStrByKey( df2+"AmpSlct", "Stats Time" )
	
	if ( ( strlen( d1 ) == 0 ) || ( strlen( t1 ) == 0 ) )
		StatsTimeStamp( df1 )
		ok = 1
	endif
	
	if ( ( strlen( d2 ) == 0 ) || ( strlen( t2 ) == 0 ) )
		StatsTimeStamp( df2 )
		ok = 1
	endif
	
	if ( ok == 1 )
		return 1
	endif
	
	if ( ( StringMatch( d1, d2 ) == 1 ) && ( StringMatch( t1, t2 ) == 1 ) )
		return 1 // yes, equal
	endif
	
	return 0 // no, not equal

End // StatsTimeStampCompare

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanCheck() // check to see if current channel has changed

	Variable currentChan = CurrentNMChannel()
	
	String wName = StatsDF() + "ChanSelect"
	
	if ( WaveExists( $wName ) == 0 )
		return 0 // nothing to do
	endif
	
	Wave wtemp = $wName

	if ( wtemp[ 0 ] != currentChan )
		StatsChanCall( currentChan )
	endif
	
	return 0
	
End // StatsChanCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanCall( chanNum )
	Variable chanNum // channel number
	
	String vlist = ""
	
	Variable win = NMStatsVar( "AmpNV" )
	
	vlist = NMCmdNum( win, vlist )
	vlist = NMCmdNum( chanNum, vlist )
	NMCmdHistory( "StatsChan", vlist )
	
	return StatsChan( win, chanNum )
	
End // StatsChanCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChan( win, chanNum )
	Variable win // Stats window number ( -1 ) for currently selected window
	Variable chanNum // channel number
	
	String df = StatsDF()
	String thisfxn = "StatsChan", wName = df + "ChanSelect"
	
	CheckNMWaveOfType( wName, NMStatsNumWindowsDefault(), CurrentNMChannel(), "R" )
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0  )
		return -1
	endif
	
	if ( ( numtype( chanNum ) > 0 ) || ( chanNum < 0 ) || ( chanNum >= NMNumChannels() ) )
		//return NMError( 10, thisfxn, "chanNum", num2istr( chanNum ) )
		return -1
	endif
	
	//SetNMwave( wName, win, chan )
	Wave wtemp = $wName
	
	wtemp = chanNum // for now, only allow one channel to be selected
	
	NMAutoStats()
	StatsTimeStamp( df )
	
	return 0

End // StatsChan

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanSelect( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	Variable currentChan = CurrentNMChannel()
	
	String wName = StatsDF() + "ChanSelect"
	
	if ( WaveExists( $wName ) == 0 )
		return currentChan
	endif
	
	//win = CheckNMStatsWin( "StatsChanSelect", win )
	
	//if ( numtype( win ) > 0 )
		//return -1
	//endif
	
	Wave wtemp = $wName
	
	return wtemp[ 0 ] // for now, return only first channel
	
	//if ( ( win >= 0 ) && ( win < numpnts( wtemp ) ) )
	//	return wtemp[ win ]
	//endif
	
	//return currentChan

End // StatsChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsWinList( kind, prefix )
	Variable kind // ( 0 ) all available ( 1 ) all windows that are not "Off"
	String prefix // "Win" or ""
	
	Variable icnt
	String select, wList = ""
	
	for ( icnt = 0; icnt < StatsNumWindows(); icnt += 1 )
	
		select = StatsAmpSelectGet( icnt )
	
		if ( kind == 0 )
			wList = AddListItem( prefix + num2istr( icnt ), wList, ";", inf )
		elseif ( ( strlen( select ) > 0 ) && ( StringMatch( select, "Off" ) == 0 ) )
			wList = AddListItem( prefix + num2istr( icnt ), wList, ";", inf )
		endif
		
	endfor
	
	return wList
	
End // NMStatsWinList

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinCount()
	
	return ItemsInList( NMStatsWinList( 1, "" ) )

End // StatsWinCount

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStatsWindowSelect()
	
	Variable win = NMStatsVar( "AmpNV" )
	
	if ( ( win < 0 ) || ( win >= StatsNumWindows() ) )
		SetNMStatsVar( "AmpNV", 0 )
	endif

End // CheckStatsWindowSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsNumWindowsCall()

	Variable nwin = StatsNumWindows()
	
	Prompt nwin, "number of measurement windows:"
	DoPrompt "Stats1", nwin
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	return StatsNumWindowsSet( nwin )
	
End // StatsNumWindowsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsNumWindowsSet( numWindows )
	Variable numWindows
	
	if ( ( numtype( numWindows ) > 0 ) || ( numWindows <= 0 ) )
		return NMError( 10, "StatsNumWindowsSet", "numWindows", num2istr( numWindows ) )
	endif
	
	CheckNMtwave( StatsDF()+"AmpSlct", numWindows, "" ) // change AmpSlct length here
	CheckNMStatsWaves( 0 ) // this will change the length of the other waves
	UpdateStats()
	
	return 0
	
End // StatsNumWindowsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinSelectCall( win )
	Variable win // Stats window number
	
	NMCmdHistory( "StatsWinSelect", NMCmdNum( win, "" ) )
	
	return StatsWinSelect( win )
	
End // StatsWinSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinSelect( win )
	Variable win // Stats window number ( DO NOT PASS -1 )
	
	win = CheckNMStatsWin( "StatsWinSelect", win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( win == NMStatsVar( "AmpNV" ) )
		return 0 // nothing to do
	endif
	
	SetNMStatsVar( "AmpNV", win )
	//StatsAmpInit( win )
	StatsChanControlsUpdate( -1, -1, 1 )
	ChanGraphUpdate( -1, 1 )
	NMAutoStats()
	
	return 0

End // StatsWinSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsWinTable( select )
	String select // ( "inputs" ) input params ( "outputs" ) output params
	
	String tName, title, sdf = StatsDF()
	
	strswitch( select )
	
		case "inputs":
			 tName = "ST_InputParams"
			 title = "Stats1 Window Inputs"
			 break
			 
		case "outputs":
			tName = "ST_OutputParams"
			title = "Stats1 Window Outputs"
			break
			
		default:
			return NMErrorStr( 20, "", "select", select )
			
	endswitch
	
	if ( WinType( tName ) == 0 )
		Edit /K=1/N=$tName as title
		SetCascadeXY( tName )
		ModifyTable /W=$tName title( Point )="Window"
	else
		DoWindow /F $tName
	endif
	
	if ( WinType( tName ) == 0 )
		return ""
	endif
	
	strswitch( select )
	
		case "inputs":
		
			AppendToTable /W=$tName $( sdf+"AmpSlct" ), $( sdf+"AmpB" ), $( sdf+"AmpE" )
			AppendToTable /W=$tName $( sdf+"Bflag" ), $( sdf+"BslnSlct" ), $( sdf+"BslnB" ), $( sdf+"BslnE" ), $( sdf+"BslnSubt" )
			AppendToTable /W=$tName $( sdf+"RiseBP" ), $( sdf+"RiseEP" )
			AppendToTable /W=$tName $( sdf+"DcayP" )
			AppendToTable /W=$tName $( sdf+"dtFlag" ), $( sdf+"SmthNum" ), $( sdf+"SmthAlg" )
			
			if ( WaveExists( $( sdf+"OffsetW" ) ) == 1 )
				AppendToTable /W=$tName $( sdf+"OffsetW" )
			endif
			
			SetWindow $tName hook(StatsTableHook)=NMStatsWinTableHook
			
			break
			
		case "outputs":
			AppendToTable /W=$tName $( sdf+"AmpX" ), $( sdf+"AmpY" )
			AppendToTable /W=$tName $( sdf+"BslnX" ), $( sdf+"BslnY" )
			AppendToTable /W=$tName $( sdf+"RiseBX" ), $( sdf+"RiseEX" ), $( sdf+"RiseTm" )
			AppendToTable /W=$tName $( sdf+"DcayX" ), $( sdf+"DcayT" )
			break
			
	endswitch
	
	return tName

End // NMStatsWinTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsWinTableHook( s )
	STRUCT WMWinHookStruct &s
	
	switch( s.eventCode )
	
		case 1:
		case 2:
			CheckNMStatsWaves( 0 )
			break
			
		case 11:
		
			if ( s.keycode == 13 )
				Execute /P/Q/Z "NMStatsWinTableExecute()"
			endif
			
			break

	endswitch
	
	return 0

End // NMStatsWinTableHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsWinTableExecute()

	CheckNMStatsWaves( 0 )
	NMAutoStats()
	
	return 0

End // NMStatsWinTableExecute

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsAmpDisplayList() // for menu display

	String ampList = "Off;---;Max;Min;Avg;SDev;Var;RMS;Area;Sum;Slope;Onset;Level;Level+;Level-;MaxAvg;MinAvg;"
	
	ampList += " ;--- Pos Peaks ---;RiseTime;RTslope;DecayTime;FWHM;"
	
	ampList += " ;--- Neg Peaks ---;RiseTime ;RTslope ;DecayTime ;FWHM ;"

	return ampList

End // StatsAmpDisplayList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsAmpList() // actual list of possible functions

	String ampList = "Off;Max;Min;Avg;SDev;Var;RMS;Area;Sum;Slope;Onset;Level;Level+;Level-;MaxAvg;MinAvg;"
	
	ampList += "RiseTime+;DecayTime+;FWHM+;RTslope+;RiseTime-;DecayTime-;FWHM-;RTslope-;"

	return ampList

End // StatsAmpList

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmpWinBegin() // find a Stats window that is on

	Variable icnt, tbgn, tend, currentChan
	String select, sdf = StatsDF() 
	
	Variable win = NMStatsVar( "AmpNV" )
	
	select = StatsAmpSelectGet( win )
	
	if ( ( strlen( select ) > 0 ) && ( StringMatch( select, "Off" ) == 0 ) )
		return 0 // stats window has already been defined
	endif
	
	for ( icnt = 0; icnt < numpnts( $sdf+"AmpSlct" ); icnt += 1 ) // look for next available
		
		if ( StringMatch( StatsAmpSelectGet( icnt ), "Off" ) == 0 )
			SetNMStatsVar( "AmpNV", icnt )
			return 0
		endif
		
	endfor
	
	// nothing defined yet, set default values for first window
	
	currentChan = CurrentNMChannel()
	tend = floor( rightx( $ChanDisplayWave( -1 ) ) )
	
	//if ( ( numtype( tend ) > 0 ) || ( tend == 0 ) )
		tbgn = -inf	
		tend = inf
	//else
	//	tbgn = floor( tend / 4 )
	//	tend = floor( tend / 2 )
	//endif
	
	win = 0 // start at first window
	SetNMStatsVar( "AmpNV", win )
		
	//SetNMwave( df+"ChanSelect", win, chan )
	SetNMwave( sdf+"dtFlag", win, ChanFuncGet( currentChan ) )
	SetNMwave( sdf+"SmthNum", win, ChanFilterNumGet( currentChan ) )
	SetNMtwave( sdf+"SmthAlg", win, ChanFilterAlgGet( currentChan ) )
	
	SetNMtwave( sdf+"AmpSlct", win, "Max" )
	SetNMwave( sdf+"AmpB", win, tbgn )
	SetNMwave( sdf+"AmpE", win, tend )
	
	tbgn = NumVarOrDefault( MainDF()+"Bsln_Bgn", 0 )
	tend = NumVarOrDefault( MainDF()+"Bsln_End", floor( tend / 5 ) )

	SetNMwave( sdf+"Bflag", win, 0 )
	SetNMtwave( sdf+"BslnSlct", win, "Avg" )
	SetNMwave( sdf+"BslnB", win, tbgn )
	SetNMwave( sdf+"BslnE", win, tend )
	SetNMwave( sdf+"BslnSubt", win, 0 )

End // StatsAmpWinBegin

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmpInit( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	Variable winLast
	String select, windowList, last, thisfxn = "StatsAmpInit"
	String sdf = StatsDF()
	String wName = sdf + "AmpB"
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	Wave AmpB = $sdf+"AmpB"
	Wave AmpE = $sdf+"AmpE"
	Wave Bflag = $sdf+"Bflag"
	Wave BslnB = $sdf+"BslnB"
	Wave BslnE = $sdf+"BslnE"
	Wave BslnSubt = $sdf+"BslnSubt"
	Wave /T BslnSlct = $sdf+"BslnSlct"
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	select = StatsAmpSelectGet( win )
	
	windowList = NMStatsWinList( 1, "" )
	
	if ( ItemsInList( windowList ) == 0 )
		return 0 // nothing to do
	else
		last = StringFromList( ItemsInList( windowList )-1, windowList )
		winLast = str2num( last )
	endif
	
	if ( ( winLast < 0 ) || ( winLast >= numpnts( AmpB ) ) || ( win == winLast ) )
		return 0 // something wrong
	endif
	
	if ( StringMatch( select, "Off" ) == 1 ) // copy previous window values to new window
		
		if ( ( numtype( AmpB[ win ] ) > 0 ) && ( numtype( AmpE[ win ] ) > 0 ) && ( win > 0 ) )
		
			AmpB[ win ] = AmpB[ winLast ]
			AmpE[ win ] = AmpE[ winLast ]
			
			Bflag[ win ] = Bflag[ winLast ]
			BslnB[ win ] = BslnB[ winLast ]
			BslnE[ win ] = BslnE[ winLast ]
			BslnSlct[ win ] = BslnSlct[ winLast ]
			BslnSubt[ win ] = BslnSubt[ winLast ]
			
		endif
		
	endif

End // StatsAmpInit

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsAmpSelectGet( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	String select, thisfxn = "StatsAmpSelectGet"
	String wName = StatsDF() + "AmpSlct"
	
	if ( WaveExists( $wName ) == 0 )
		NMError( 1, thisfxn, "wName", wName )
		return "Off"
	endif
	
	Wave /T AmpSlct = $wName
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return "Off"
	endif
		
	select = AmpSlct[ win ]
	
	if ( strlen( select ) == 0 )
		AmpSlct[ win ] = "Off" // old format
		return "Off"
	endif
	
	if ( StringMatch( select[ 0, 2 ], "Off" ) == 1 )
		return "Off"
	else
		return select
	endif
	
End // StatsAmpSelectGet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsAmpSelectCall( tbgn, tend, fxn )
	Variable tbgn, tend // time begin and end, ( -inf / inf ) for all possible time
	String fxn // Stats function to measure ( e.g. "Max" or "Min" or "RiseTime+" )
	
	Variable error
	String vlist = "", df = StatsDF()
	
	String wName = df + "AmpSlct"
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, "NMStatsAmpSelectCall", "wName", wName )
	endif
	
	Variable win = NMStatsVar( "AmpNV" )
	
	Wave AmpB = $df+"AmpB"
	Wave AmpE = $df+"AmpE"
	
	Wave /T AmpSlct = $wName
	
	if ( numtype( tbgn ) == 2 )
		tbgn = AmpB[ win ]
	endif
	
	if ( numtype( tend ) == 2 )
		tend = AmpE[ win ]
	endif
	
	if ( strlen( fxn ) == 0 )
		fxn = AmpSlct[ win ]
	endif
	
	if ( StringMatch( fxn, "Off" ) == 1 )
	
		vlist = NMCmdNum( win, vlist )
		NMCmdHistory( "NMStatsAmpSelectOff", vlist )
		
		return NMStatsAmpSelectOff( win )
	
	else
	
		vlist = NMCmdNum( win, vlist )
		vlist = NMCmdNum( tbgn, vlist )
		vlist = NMCmdNum( tend, vlist )
		vlist = NMCmdStr( fxn, vlist )
		NMCmdHistory( "NMStatsAmpSelect", vlist )
		
		return NMStatsAmpSelect( win, tbgn, tend, fxn )
	
	endif

End // NMStatsAmpSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsAmpSelectOff( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	win = CheckNMStatsWin( "NMStatsAmpSelectOff", win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	return NMStatsAmpSelect( win, Nan, Nan, "Off" )
	
End // NMStatsAmpSelectOff

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsAmpSelect( win, tbgn, tend, fxn )
	Variable win // Stats window number ( -1 ) for currently selected window
	Variable tbgn, tend // time begin and end, ( -inf / inf ) for all possible time
	String fxn // Stats function to measure ( e.g. "Max" or "Min" or "RiseTime+" )
	
	Variable avgwin
	String thisfxn = "NMStatsAmpSelect", df = StatsDF()
	 
	String maxmin = fxn[ 0, 5 ]
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( ( StringMatch( maxmin, "MaxAvg" ) == 0 ) && ( StringMatch( maxmin, "MinAvg" ) == 0 ) )
		
		maxmin = ""
		
		if ( WhichListItem( fxn, StatsAmpList(), ";", 0, 0 ) == -1 )
			return NMError( 20, thisfxn, "fxn", fxn )
		endif
		
	endif
	
	if ( strlen( maxmin ) > 0 )
	
		avgwin = str2num( fxn[ 6, inf ] )
			
		if ( numtype( avgwin ) > 0 )
			avgwin = StatsMaxMinWinPrompt( fxn )
			fxn = maxmin + num2str( avgwin )
		endif
			
	endif
	
	if ( StringMatch( fxn, "Off" ) == 0 )
	
		if ( numtype( tbgn ) > 0 )
			tbgn = -inf
		endif
		
		if ( numtype( tend ) > 0 )
			tend = inf
		endif
		
		SetNMwave( df + "AmpB", win, tbgn )
		SetNMwave( df + "AmpE", win, tend )
	
	endif
	
	SetNMtwave( df + "AmpSlct", win, fxn )
	
	strswitch( fxn )
	
		case "Off":
			SetNMwave( df + "Bflag", win, 0 ) // turn off baseline computation
			break
	
		case "RiseTime+":
		case "RiseTime-":
		case "RTslope+":
		case "RTslope-":
		case "FWHM+":
		case "FWHM-":
			SetNMwave( df + "Bflag", win, 1 ) // turn on baseline computation
			break
			
		case "DecayTime+":
		case "DecayTime-":
			SetNMwave( df + "Bflag", win, 1 ) // turn on baseline computation
			break
	
	endswitch
	
	NMAutoStats()
	StatsTimeStamp( df )
	
	return 0

End // NMStatsAmpSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsMaxMinWinPrompt( select )
	String select // "MaxAvg" or "MinAvg"
	
	Variable win = NMStatsVar( "AmpNV" )
	Variable avgwin = StatsMaxMinWinGet( win )
	
	if ( strlen( select ) == 0 )
		select = StatsAmpSelectGet( win )
	endif
		
	if ( ( avgwin <= 0 ) || ( numtype( avgwin ) > 0 ) )
		avgwin = 1
	endif

	strswitch ( select )
	
		case "MaxAvg":
			Prompt avgwin, "window to average around detected max value (ms):"
			DoPrompt "Stats Max Average Computation", avgwin
			break
			
		case "MinAvg":
			Prompt avgwin, "window to average around detected min value (ms):"
			DoPrompt "Stats Min Average Computation", avgwin
			break
			
		default:
			return NMError( 20, "StatsMaxMinWinPrompt", "select", select )
			
	endswitch
	
	if ( numtype( avgwin ) > 0 )
		avgwin = 1
	endif
	
	return avgwin

End // StatsMaxMinWinPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsMaxMinWinSetCall( avgwin )
	Variable avgwin

	String vlist = ""
	Variable win = NMStatsVar( "AmpNV" )
	
	vlist = NMCmdNum( win, vlist )
	vlist = NMCmdNum( avgwin, vlist )
	NMCmdHistory( "StatsMaxMinWinSet", vlist )
	
	return StatsMaxMinWinSet( win, avgwin )

End // StatsMaxMinWinSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsMaxMinWinSet( win, avgWindow )
	Variable win // Stats window number ( -1 ) for currently selected window
	Variable avgWindow // average window length
	
	String select, maxmin, thisfxn = "StatsMaxMinWinSet", sdf = StatsDF()
	String wName = sdf + "AmpSlct"
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( ( numtype( avgWindow ) > 0 ) || ( avgWindow <= 0 ) )
		NMError( 10, thisfxn, "avgWindow", num2str( avgWindow ) )
	endif
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	select = StatsAmpSelectGet( win )
	maxmin = select[ 0, 5 ]
	
	strswitch( maxmin )
		case "MaxAvg":
		case "MinAvg":
			break
		default:
			return NMError( 20, thisfxn, "select", select )
	endswitch
	
	Wave /T wtemp = $wName
	
	wtemp[ win ] = maxmin + num2str( avgWindow )
	
	NMAutoStats()
	StatsTimeStamp( sdf )
	
	return 0
	
End // StatsMaxMinWinSet

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsMaxMinWinGet( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	String select, maxmin
	
	win = CheckNMStatsWin( "StatsMaxMinWinGet", win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	select = StatsAmpSelectGet( win )
	
	maxmin = select[ 0, 5 ]
	
	if ( ( StringMatch( maxmin, "MaxAvg" ) == 1 ) || ( StringMatch( maxmin, "MinAvg" ) == 1 ) )
		return str2num( select[ 6, inf ] )
	endif
	
	return Nan

End // StatsMaxMinWinGet

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLevelCall( level )
	Variable level
	
	String vlist = ""
	
	Variable win = NMStatsVar( "AmpNV" )
	
	vlist = NMCmdNum( win, vlist )
	vlist = NMCmdNum( level, vlist )
	NMCmdHistory( "StatsLevel", vlist )
	
	return StatsLevel( win, level )
	
End // StatsLevelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLevel( win, level )
	Variable win // Stats window number ( -1 ) for currently selected window
	Variable level // y-level crossing value
	
	String select, thisfxn = "StatsLevel", df = StatsDF()
	String wName = df + "AmpY"
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	select = StatsAmpSelectGet( win )
	
	strswitch( select )
	
		case "Level":
		case "Level+":
		case "Level-":
		
			if ( numtype( level ) > 0 )
				return NMError( 10, thisfxn, "level", num2str( level ) )
			endif
	
			SetNMwave( wName, win, level )
			
			break
			
		case "DecayTime+":
		case "DecayTime-":
			return StatsDecayTimeCall( 1 )
			
		case "RiseTime+":
		case "RiseTime-":
			return StatsRiseTimeCall( 1 )
			
		default:
			return NMError( 20, thisfxn, "select", select )
			
	endswitch
	
	NMAutoStats()
	StatsTimeStamp( df )
	
	return 0

End // StatsLevel

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFilterCall( filterAlg, filterNum )
	String filterAlg
	Variable filterNum
	
	String vlist, sdf = StatsDF()
	String wName = sdf+"SmthAlg"
	
	Variable win = NMStatsVar( "AmpNV" )
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, "StatsFilterCall", "wName", wName )
	endif
	
	Wave /T FilterAlgWave = $sdf+"SmthAlg" // smooth / filter waves
	Wave filterNumWave = $sdf+"SmthNum"
	
	if ( filterNum == -1 )
		filterNum = filterNumWave[ win ]
	endif
	
	strswitch( filterAlg )
	
		case "old":
			filterAlg = FilterAlgWave[ win ]
			break
			
		case "binomial":
		case "boxcar":
			break
			
		case "low-pass":
		case "high-pass":
			break
			
		default: // ERROR
			filterNum = 0
			filterAlg = ""
			
	endswitch
	
	if ( ( strlen( filterAlg ) == 0 ) && ( filterNum > 0 ) )
	
		filterAlg = ChanFilterAlgAsk( -1 )
		
		if ( strlen( filterAlg ) == 0 )
			filterNum = 0
		endif
		
	endif
	
	if ( filterNum > 0 )
	
		vlist = NMCmdNum( win, "" )
		vlist = NMCmdStr( filterAlg, vlist )
		vlist = NMCmdNum( filterNum, vlist )
		NMCmdHistory( "StatsFilter", vlist )
		
		return StatsFilter( win, filterAlg, filterNum )
	
	else
	
		vlist = NMCmdNum( win, "" )
		NMCmdHistory( "StatsFilterOff", vlist )
		
		return StatsFilterOff( win, filterAlg, filterNum )
	
	endif
	
End // StatsFilterCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFilterOff( win, filterAlg, filterNum )
	Variable win // Stats window number ( -1 ) for currently selected window
	String filterAlg // filter algorithm
	Variable filterNum // filter number
	
	win = CheckNMStatsWin( "StatsFilterOff", win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	return StatsFilter( win, "", 0 )
	
End // StatsFilterOff

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFilter( win, filterAlg, filterNum )
	Variable win // Stats window number ( -1 ) for currently selected window
	String filterAlg // filter algorithm
	Variable filterNum // filter number
	
	String thisfxn = "StatsFilter"
	String sdf = StatsDF()
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( ( numtype( filterNum ) > 0 ) || ( filterNum < 0 ) )
		filterNum = 0
	endif
	
	strswitch( filterAlg )
	
		case "binomial":
		case "boxcar":
		case "low-pass":
		case "high-pass":
			break
			
		default:
		
			if ( filterNum > 0 )
				filterAlg = ChanFilterAlgAsk( -1 )
			endif
			
	endswitch
	
	if ( filterNum == 0 )
	
		filterAlg = ""
		
	else
	
		if ( WhichListItem( filterAlg, ChanFilterFxnList(), ";", 0, 0 ) < 0 )
			return NMError( 1, thisfxn, "filterAlg", filterAlg )
		endif
		
	endif
	
	SetNMtwave( sdf + "SmthAlg", win, filterAlg )
	SetNMwave( sdf + "SmthNum", win, filterNum )
	
	StatsChanControlsUpdate( -1, -1, 1 )
	ChanGraphUpdate( -1, 1 )
	NMAutoStats()
	StatsTimeStamp( sdf )
	
	return 0

End // StatsFilter

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBslnCallStr( bslnStr )
	String bslnStr
	
	Variable icnt, jcnt, tbgn = Nan, tend = Nan, last = strlen( bslnStr ) - 1
	
	icnt = strsearch( bslnStr, ": ", 0 )
	jcnt = strsearch( bslnStr, " - ", 0 )
	
	if ( ( icnt < 0 ) || ( jcnt < 0 ) )
		return StatsBslnCall( 1, tbgn, tend )
	endif
	
	tbgn = str2num( bslnStr[ icnt+2, jcnt-1 ] )
	tend = str2num( bslnStr[ jcnt + 3, last ] )
	
	if ( numtype( tend ) > 0 )
	
		for ( icnt = last; icnt < 0; icnt -= 1 )
		
			tend = str2num( bslnStr[ jcnt + 3, icnt ] )
			
			if ( numtype( str2num( bslnStr[ icnt, icnt ] ) ) == 0 )
				break
			endif
			
		endfor
	
	endif
	
	return StatsBslnCall( 1, tbgn, tend )
	
End // StatsBslnCallStr

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBslnCall( on, tbgn, tend )
	Variable on // ( 0 ) off ( 1 ) on
	Variable tbgn, tend // time begin and end, ( -inf / inf ) for all possible time
	
	Variable twin, subtract
	Variable bstart, bend, bcntr = Nan
	String select, vlist = "", fxn = "", sdf = StatsDF()
	
	String wName = sdf + "BslnSlct"
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, "StatsBslnCall", "wName", wName )
	endif
	
	Variable win = NMStatsVar( "AmpNV" )
	
	Wave AmpB= $sdf+"AmpB"
	Wave AmpE= $sdf+"AmpE"
	Wave BslnB = $sdf+"BslnB"
	Wave BslnE = $sdf+"BslnE"
	Wave BslnSubt = $sdf+"BslnSubt"
	Wave Bflag = $sdf+"Bflag"
	
	Wave /T BslnSlct = $wName
	
	if ( ( on != 1 ) && ( ( StatsRiseTimeFlag( win ) == 1 ) || ( StatsDecayTimeFlag( win ) == 1 ) ) )
		on = 1 // baseline must be on
	endif
	
	if ( on == 0 )
	
		vlist = NMCmdNum( win, vlist )
		NMCmdHistory( "NMStatsBslnOff", vlist )
		
		return NMStatsBslnOff( win )
	
	else
	
		if ( numtype( tbgn ) == 2 )
			tbgn = BslnB[ win ]
		endif
		
		if ( numtype( tend ) == 2 )
			tend = BslnE[ win ]
		endif
		
		if ( ( tbgn == 0 ) && ( tend == 0 ) )
			tbgn = NumVarOrDefault( MainDF()+"Bsln_Bgn", 0 )
			tend = NumVarOrDefault( MainDF()+"Bsln_End", 10 )
		elseif ( tbgn == tend )
			tend = tbgn + 10
		endif
		
		twin = tend - tbgn
		subtract = BslnSubt[ win ] + 1
		
		select = StatsAmpSelectGet( win )
		
		strswitch( select )
			case "SDev":
			case "Var":
			case "RMS":
			case "Area":
			case "Sum":
			case "Slope":
				fxn = select
				break
			default:
				fxn = "Avg"
		endswitch
		
		Prompt tbgn, "begin time (ms):"
		Prompt tend, "end time (ms):"
		Prompt fxn, "baseline measurement:", popup, NMStatsBslnFxnList()
		Prompt subtract, "subtract baseline from y-measurement?", popup, "no;yes"
		DoPrompt "Stats Baseline Window", tbgn, tend, fxn, subtract
	
		if ( V_Flag == 1 )
			return -1 // cancel
		endif
		
		subtract -= 1
	
		vlist = NMCmdNum( win, vlist )
		vlist = NMCmdNum( on, vlist )
		vlist = NMCmdNum( tbgn, vlist )
		vlist = NMCmdNum( tend, vlist )
		vlist = NMCmdStr( fxn, vlist )
		vlist = NMCmdNum( subtract, vlist )
		NMCmdHistory( "StatsBsln", vlist )
		
		return StatsBsln( win, on, tbgn, tend, fxn, subtract )
	
	endif
	
End // StatsBslnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsBslnOff( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	win = CheckNMStatsWin( "NMStatsBslnOff", win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	return StatsBsln( win, 0, NaN, NaN, "", 0 )
	
End // NMStatsBslnOff

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBsln( win, on, tbgn, tend, fxn, subtract )
	Variable win // Stats window number ( -1 ) for currently selected window
	Variable on // ( 0 ) off ( 1 ) on
	Variable tbgn, tend // time begin and end, ( -inf / inf ) for all possible time
	String fxn // Max,Min,Avg,SDev,Var,RMS,Area,Sum,Slope
	Variable subtract // subtract baseline value from computed Stats y-value ( 0 ) no ( 1 ) yes
	
	Variable thold
	String thisfxn = "StatsBsln", sdf = StatsDF()
	String wName = sdf + "Bflag"
	
	on = BinaryCheck( on )
	subtract = BinaryCheck( subtract )
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( on == 1 )
	
		if ( numtype( tbgn ) > 0 )
			tbgn = -inf
		endif
		
		if ( numtype( tend ) > 0 )
			tend = inf
		endif
		
		if ( WhichListItem( fxn, NMStatsBslnFxnList() ) < 0 )
			return NMError( 20, thisfxn, "fxn", fxn )
		endif
		
		if ( tbgn > tend )
			thold = tbgn
			tbgn = tend
			tend = thold
		endif
		
		SetNMwave( sdf + "BslnB", win, tbgn )
		SetNMwave( sdf + "BslnE", win, tend )
		SetNMtwave( sdf + "BslnSlct", win, fxn )
		SetNMwave( sdf + "BslnSubt", win, subtract )
	
	endif
	
	SetNMwave( wName, win, on )
	
	NMAutoStats()
	StatsTimeStamp( sdf )
	
	return 0

End // StatsBsln

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsBslnFxnList()

	return "Max;Min;Avg;SDev;Var;RMS;Area;Sum;Slope"

End // NMStatsBslnFxnList

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsRiseTimeCall( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	Variable percentBgn, percentEnd
	String vlist = "", sdf = StatsDF()
	
	String wName = sdf + "RiseBP"
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, "StatsRiseTimeCall", "wName", wName )
	endif
	
	Variable win = NMStatsVar( "AmpNV" )
	
	Wave RiseBP = $sdf+"RiseBP"
	Wave RiseEP = $sdf+"RiseEP"
	Wave Bflag = $sdf+"Bflag"

	if ( on == 1 )
	
		percentBgn = RiseBP[ win ]
		percentEnd = RiseEP[ win ]
		
		if ( percentBgn == percentEnd )
			percentBgn = 10
			percentEnd = 90
		endif
		
		Prompt percentBgn, "% begin:"
		Prompt percentEnd, "% end:"
		DoPrompt "Stats Percent Rise Time", percentBgn, percentEnd
		
		if ( V_Flag == 1 )
			return -1 // cancel
		endif
		
	endif
	
	vlist = NMCmdNum( win, vlist )
	vlist = NMCmdNum( on, vlist )
	vlist = NMCmdNum( percentBgn, vlist )
	vlist = NMCmdNum( percentEnd, vlist )
	NMCmdHistory( "StatsRiseTime", vlist )
	
	return StatsRiseTime( win, on, percentBgn, percentEnd )
	
End // StatsRiseTimeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsRiseTime( win, on, percentBgn, percentEnd )
	Variable win // Stats window number ( -1 ) for currently selected window
	Variable on // ( 0 ) off ( 1 ) on
	Variable percentBgn, percentEnd // begin / end percentage point ( e.g. 10 and 90 )
	
	String thisfxn = "StatsRiseTime", sdf = StatsDF()
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( ( percentBgn < 0 ) || ( percentBgn > 100 ) )
		return NMError( 10, thisfxn, "percentBgn", num2str( percentBgn ) )
	endif
	
	if ( ( percentEnd < 0 ) || ( percentEnd > 100 ) )
		return NMError( 10, thisfxn, "percentEnd", num2str( percentEnd ) )
	endif
	
	on = BinaryCheck( on )
	
	if ( on == 1 )
		SetNMwave( sdf + "RiseBP", win, percentBgn )
		SetNMwave( sdf + "RiseEP", win, percentEnd )
		SetNMwave( sdf + "Bflag", win, 1 ) // turn on baseline computation
	endif
	
	NMAutoStats()
	StatsTimeStamp( sdf )
	
	return 0

End // StatsRiseTime

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsRiseTimeFlag( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	String wName = StatsDF() + "AmpSlct"
	
	if ( WaveExists( $wName ) == 0 )
		return 0
	endif
	
	win = CheckNMStatsWin( "StatsRiseTimeFlag", win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	Wave /T AmpSlct = $wName
	
	strswitch( AmpSlct[ win ] )
		case "RiseTime+":
		case "RiseTime-":
		case "RTslope+":
		case "RTslope-":
		case "FWHM+":
		case "FWHM-":
			return 1
	endswitch
	
	return 0
	
End // StatsRiseTimeFlag

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDecayTimeFlag( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	String sdf = StatsDF()
	String wName = StatsDF() + "AmpSlct"
	
	if ( WaveExists( $wName ) == 0 )
		return 0
	endif
	
	win = CheckNMStatsWin( "StatsDecayTimeFlag", win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	Wave /T AmpSlct = $wName
	
	strswitch( AmpSlct[ win ] )
		case "DecayTime+":
		case "DecayTime-":
			return 1
	endswitch
	
	return 0
	
End // StatsDecayTimeFlag

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDecayTimeCall( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	Variable percent
	String vlist = "", sdf = StatsDF()
	
	String wName = sdf + "DcayP"
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, "StatsDecayTimeCall", "wName", wName )
	endif
	
	Variable win = NMStatsVar( "AmpNV" )
	
	Wave Bflag = $sdf+"Bflag"
	Wave DcayP = $wName
	
	if ( on == 1 )
	
		percent = DcayP[ win ]
		
		Prompt percent, "% decay:"
		DoPrompt "Stats Percent Decay Time", percent
		
		if ( V_Flag == 1 )
			return -1 // cancel
		endif
		
	endif
	
	vlist = NMCmdNum( win, vlist )
	vlist = NMCmdNum( on, vlist )
	vlist = NMCmdNum( percent, vlist )
	NMCmdHistory( "StatsDecayTime", vlist )
	
	return StatsDecayTime( win, on, percent )
	
End // StatsDecayTimeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDecayTime( win, on, percent )
	Variable win // Stats window number ( -1 ) for currently selected window
	Variable on // ( 0 ) off ( 1 ) on
	Variable percent // percent decay ( e.g. 37 )
	
	String thisfxn = "StatsDecayTime", sdf = StatsDF()
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( ( numtype( percent ) > 0 ) || ( percent < 0 ) || ( percent > 100 ) )
		return NMError( 10, thisfxn, "percent", num2str( percent ) )
	endif
	
	on = BinaryCheck( on )
	
	if ( on == 1 )
		SetNMwave( sdf + "DcayP", win, percent )
		SetNMwave( sdf + "Bflag", win, 1 ) // turn on baseline computation
	endif
	
	NMAutoStats()
	StatsTimeStamp( sdf )
	
	return 0

End // StatsDecayTime

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsTransformCall( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	Variable win, fxn
	String vlist = ""
	
	if ( on == 1 )
		fxn = ChanFuncAsk( CurrentNMChannel() )
	endif
	
	if ( fxn == -1 )
		return -1 // cancel
	endif
	
	win = NMStatsVar( "AmpNV" )
	
	vlist = NMCmdNum( win, vlist )
	vlist = NMCmdNum( fxn, vlist )
	NMCmdHistory( "NMStatsTransform", vlist )
	
	return NMStatsTransform( win, fxn )

End // NMStatsTransformCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsTransform( win, fxn )
	Variable win // Stats window number ( -1 ) for currently selected window
	Variable fxn // ( 0 ) none ( 1 ) d/dt ( 2 ) dd/dt*dt ( 3 ) integral ( 4 ) norm ( 5 ) dF/F0 ( 6 ) baseline
	
	String fxnName, cdf, sdf = StatsDF()
	String thisfxn = "NMStatsTransform"
	String wName = sdf + "dtFlag"
	
	Variable chanNum = CurrentNMChannel()
	
	cdf =  ChanFuncDF( chanNum )
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	fxnName = ChanFuncNum2Name( fxn )
	
	if ( strlen( fxnName ) == 0 )
		return NMError( 10, thisfxn, "fxn", num2istr( fxn ) )
	endif
	
	SetNMwave( wName, win, fxn )
	
	SetNMVar( cdf+"Ft", fxn )
	
	StatsChanControlsUpdate( -1, -1, 1 )
	ChanGraphUpdate( -1, 1 )
	NMAutoStats()
	StatsTimeStamp( sdf )
	
	return 0
	
End // NMStatsTransform

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffsetWinCall( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	Variable create, table = 1
	String pName, vlist = "", wList = ""
	
	Variable numWaves = NMNumWaves()
	
	Variable select = NMStatsVar( "OffsetSelect" )
	Variable offsetType = NMStatsVar( "OffsetType" )
	Variable baseline = 1 + NMStatsVar( "OffsetBsln" )
	String wName = NMStatsStr( "OffsetWName" )
	String folder = "_subfolder_"
	
	Variable win = NMStatsVar( "AmpNV" )
	
	if ( on == 1 )
		
		if ( NMGroupsAreOn() == 0 )
			offsetType = 2
		endif
		
		Prompt select, "choose option:", popup "create a wave of x-axis offset values;select a wave of x-axis offset values;"
		Prompt offsetType, "these offset values will pertain to what?", popup "individual groups;individual waves;"
		Prompt baseline, "apply offsets to baseline windows as well?", popup "no;yes;"
		
		DoPrompt "Stats Window Time Offset", select, offsetType, baseline
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		baseline -= 1
		
		if ( select == 2 )
		
			wList = WaveList( "*Offset*", ";", "Text:0" )
			
			if ( ItemsInList( wList ) == 0 )
				NMDoAlert( "Stats Offset Error: detected no time-offset waves in the current data folder. " + NMStatsOffsetWaveNameAlert() )
				return -1
			endif
			
		endif
			
		if ( ( select == 1 ) && ( offsetType == 1 ) )
		
			wName = "ST_GroupOffset"
			Prompt wName, "enter name for new offset wave ( should contain " + NMQuotes( "Offset" ) + " ) :"
			DoPrompt "Create Offset Wave", wName
			create = 1
			
			if ( StringMatch( wName, "*Offset*" ) == 0 )
				NMDoAlert( "Stats Offset Error: bad offset wave name. " + NMStatsOffsetWaveNameAlert() )
				return -1
			endif
		
		elseif ( ( select == 1 ) && ( offsetType == 2 ) )
		
			wName = "ST_WaveOffset"
			Prompt wName, "enter name for new offset wave:"
			DoPrompt "Create Offset Wave", wName
			create = 1
		
		elseif ( ( select == 2 ) && ( offsetType == 1 ) )
		
			Prompt wName, "choose a wave of offset values:", popup wList
			DoPrompt "Select Offset Wave", wName
		
		elseif ( ( select == 2 ) && ( offsetType == 2 ) )
		
			Prompt wName, "choose a wave of offset values:", popup wList
			DoPrompt "Select Offset Wave", wName
			
			if ( ( V_flag == 0 ) && ( numpnts( $wName ) != numWaves ) )
				NMDoAlert( "Warning: offset wave length does not match the number of data waves." )
			endif
		
		endif
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		if ( create == 1 )
		
			vlist = NMCmdStr( folder, vlist )
			vlist = NMCmdStr( wName, vlist )
			vlist = NMCmdNum( offsetType, vlist )
			NMCmdHistory( "NMStatsOffsetWave", vlist )
			
			pName = NMStatsOffsetWave( folder, wName, offsetType )
		
			if ( WaveExists( $pName ) == 0 )
				return -1 // cancel
			endif
			
		endif
		
		SetNMStatsVar( "OffsetSelect", select )
		SetNMStatsVar( "OffsetType", offsetType )
		SetNMStatsVar( "OffsetBsln", baseline )
		SetNMStatsStr( "OffsetWName", wName )
		
	endif
	
	if ( on == 1 )
	
		vlist = NMCmdNum( win, "" )
		vlist = NMCmdStr( folder, vlist )
		vlist = NMCmdStr( wName, vlist )
		vlist = NMCmdNum( offsetType, vlist )
		vlist = NMCmdNum( baseline, vlist )
		vlist = NMCmdNum( table, vlist )
		NMCmdHistory( "NMStatsOffsetWin", vlist )
		
		return NMStatsOffsetWin( win, folder, wName, offsetType, baseline, table )
	
	else
	
		vlist = NMCmdNum( win, "" )
		NMCmdHistory( "NMStatsOffsetWinOff", vlist )
		
		return NMStatsOffsetWinOff( win )
	
	endif

End // StatsOffsetWinCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsOffsetWinOff( win )
	Variable win
	
	win = CheckNMStatsWin( "NMStatsOffsetWinOff", win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	return NMStatsOffsetWin( win, "", "", 1, 0, 0 )
	
End // NMStatsOffsetWinOff

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsOffsetWin( win, folder, wName, offsetType, baseline, table )
	Variable win // Stats window number ( -1 ) for currently selected window
	String folder // data folder, ( "" ) for current data folder or ( "_subfolder_" ) for current subfolder
	String wName // wave name, or ( "" ) for no offset
	Variable offsetType // ( 1 ) group time offset ( 2 ) wave time offset
	Variable baseline // offset shift includes baseline time window ( 0 ) no ( 1 ) yes
	Variable table // display wave in table ( 0 ) no ( 1 ) yes
	
	String tFlag, bFlag, xLabel, yLabel, thisfxn = "NMStatsOffsetWin", sdf = StatsDF()
	String owName = sdf + "OffsetW"
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		NMError( 30, thisfxn, "folder", folder )
	endif
	
	if ( ( offsetType != 1 ) && ( offsetType != 2 ) )
		return NMError( 10, thisfxn, "offsetType", num2str( offsetType ) )
	endif
	
	if ( ( baseline != 0 ) && ( baseline != 1 ) )
		return NMError( 10, thisfxn, "baseline", num2str( baseline ) )
	endif
	
	wName = folder + wName
	
	if ( ( strlen( wName ) > 0 ) && ( WaveExists( $wName ) == 0 ) )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	if ( offsetType == 1 )
		tFlag = "Stats Offset Type:Group"
		xLabel = "Group #"
	else
		tFlag = "Stats Offset Type:Wave"
		xLabel = "Wave #"
	endif
	
	if ( baseline == 1 )
		bFlag = "\rStats Offset Baseline:Yes"
	else
		bFlag = "\rStats Offset Baseline:No"
	endif
	
	yLabel = NMChanLabel( -1, "x", "" )
	
	if ( strlen( wName ) > 0 )
		NMNoteType( wName, "NMStats Offset", xLabel, yLabel, tFlag + bFlag )
	endif
	
	SetNMtwave( owName, win, wName )
	
	NMAutoStats()
	StatsTimeStamp( sdf )
	
	if ( table == 1 )
		NMStatsOffsetWaveEdit( wName )
	endif
	
	return 0
	
End // NMStatsOffsetWin

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsOffsetWave( folder, wName, offsetType ) // create offset ( time-shift ) wave
	String folder // data folder, ( "" ) for current data folder or ( "_subfolder_" ) for current subfolder
	String wName // wave name
	Variable offsetType // ( 1 ) group time offset ( 2 ) wave time offset
	
	Variable npnts
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, "NMStatsOffsetWave", "folder", folder )
	endif
	
	if ( StringMatch( wName, "*Offset*" ) == 0 )
		NMDoAlert( "Bad Stats offset wave name " + NMQuotes( wName ) + ". " + NMStatsOffsetWaveNameAlert() )
		return ""
	endif
	
	wName = folder + wName
	
	if ( offsetType == 1 )
		npnts = NMGroupsLast( "" ) + 1
	else
		npnts = NMNumWaves()
	endif
	
	CheckNMwave( wName, npnts, 0 )
	
	if ( WaveExists( $wName ) == 1 )
		return wName
	else
		return ""
	endif

End // NMStatsOffsetWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsOffsetWaveNameAlert()

	return "A Stats offset wave name should contain the string " + NMQuotes( "Offset" ) + "."
	
End // NMStatsOffsetWaveNameAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsOffsetWaveEdit( wName ) // display table
	String wName // stats offset wave name
	
	String offsetType, ttl, tName, thisfxn = "NMStatsOffsetWaveEdit"
	String sName = GetPathName( wName, 0 )
	
	if ( WaveExists( $wName ) == 0 )
		return NMErrorStr( 1, thisfxn, "wName", wName )
	endif
	
	offsetType = NMNoteStrByKey( wName, "Stats Offset Type" )
	
	strswitch( offsetType )
		case "Group":
		case "Wave":
			break
		default:
			return NMErrorStr( 20, thisfxn, "offsetType", offsetType )
	endswitch
	
	if ( StringMatch( sName[ 0,2 ], "ST_" ) == 1 )
		tName = sName + "_Table"
	else
		tName = "ST_" + sName
	endif
	
	DoWindow /K $tName
	Edit /K=1/N=$tName/W=( 0,0,0,0 ) $wName as "Stats Offset Wave"
	SetCascadeXY( tName )
	
	ModifyTable /W=$tName title( Point )=offsetType
	
	return tName

End // NMStatsOffsetWaveEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsOffsetWaveName( win ) // will return offset value
	Variable win // Stats window number ( -1 ) for currently selected window
	
	String thisfxn = "NMStatsOffsetWaveName"
	String wName = StatsDF() + "OffsetW"
	
	if ( WaveExists( $wName ) == 0 )
		return NMErrorStr( 1, thisfxn, "wName", wName )
	endif
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return ""
	endif
	
	Wave /T wTemp = $wName
	
	return wTemp[ win ]
	
End // NMStatsOffsetWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffsetValue( win ) // will return offset value
	Variable win // Stats window number ( -1 ) for currently selected window
	
	Variable select = -1
	String offsetType
	String wName = StatsDF() + "OffsetW"
	
	Variable currentWave = CurrentNMWave()
	
	if ( WaveExists( $wName ) == 0 )
		return Nan
	endif
	
	win = CheckNMStatsWin( "StatsOffsetValue", win )
	
	if ( numtype( win ) > 0 )
		return Nan
	endif
	
	Wave /T offsetW = $wName
	
	wName = offsetW[ win ]
	
	if ( strlen( wName ) == 0 )
		return Nan
	endif
	
	offsetType = wName[ 0,1 ] // Old Type Flag
	
	strswitch( offsetType )
	
		case "/w":
			select = currentWave
			wName = wName[ 2, inf ]
			break
			
		case "/g":
			select = NMGroupsNum( currentWave )
			wName = wName[ 2, inf ]
			break
			
	endswitch
	
	if ( WaveExists( $wName ) == 0 )
		return Nan
	endif
	
	if ( select < 0 )
	
		offsetType = NMNoteStrByKey( wName, "Stats Offset Type" )
		
		strswitch( offsetType )
	
			case "Wave":
				select = currentWave
				break
				
			case "Group":
				select = NMGroupsNum( currentWave )
				break
				
			default:
				return Nan

		endswitch
	
	endif
	
	Wave wtemp = $wName
	
	if ( ( numtype( select ) > 0 ) || ( select < 0 ) || ( select >= numpnts( wtemp ) ) )
		return 0
	endif
	
	return wtemp[ select ]

End // StatsOffsetValue

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsOffsetBaseline( win ) // get baseline flag
	Variable win // Stats window number ( -1 ) for currently selected window
	
	String bFlag, oldType
	String wName = StatsDF() + "OffsetW"
	
	Variable currentWave = CurrentNMWave()
	
	if ( WaveExists( $wName ) == 0 )
		return 0
	endif
	
	win = CheckNMStatsWin( "NMStatsOffsetBaseline", win )
	
	if ( numtype( win ) > 0 )
		return 0
	endif
	
	Wave /T offsetW = $wName
	
	wName = offsetW[ win ]
	
	if ( strlen( wName ) == 0 )
		return 0
	endif
	
	oldType = wName[ 0,1 ] // Old Type Flag
	
	strswitch( oldType )
	
		case "/w":
			wName = wName[ 2, inf ]
			break
			
		case "/g":
			wName = wName[ 2, inf ]
			break
			
	endswitch
	
	if ( WaveExists( $wName ) == 0 )
		return 0
	endif
	
	bFlag = NMNoteStrByKey( wName, "Stats Offset Baseline" )
	
	strswitch( bFlag )
	
		case "Yes":
			return 1
			
		case "No":
			return 0
			
		default:
			return NMStatsVar( "OffsetBsln" ) // OLD FLAG
		
	endswitch

End // NMStatsOffsetBaseline

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsAutoCall()

	Variable autoTable = 1 + NMStatsVar( "AutoTable" )
	Variable autoPlot = 1 + NMStatsVar( "AutoPlot" )
	Variable autoStats2 = 1 + NMStatsVar( "AutoStats2" )
	Variable useSubfolders = 1 + NMStatsVar( "UseSubfolders" )
	
	Prompt autoTable, "automatically create output table?", popup "no;yes;"
	Prompt autoPlot, "automatically plot default Stats wave?", popup "no;yes;"
	Prompt autoStats2, "automatically compute average/stdv of the output Stats waves?", popup "no;yes;"
	Prompt useSubfolders, "save Stats output waves in a subfolder?", popup "no;yes;"
	
	DoPrompt "Stats Compute All Configurations", autoTable, autoPlot, autoStats2, useSubfolders
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif

	autoTable -= 1
	autoPlot -= 1
	autoStats2 -= 1
	useSubfolders -= 1
	
	NMCmdHistory( "NMStatsAutoTable", NMCmdNum( autoTable, "" ) )
	NMCmdHistory( "NMStatsAutoPlot", NMCmdNum( autoPlot, "" ) )
	NMCmdHistory( "NMStatsAutoStats2", NMCmdNum( autoStats2, "" ) )
	
	//NMStatsAutoTable( autoTable )
	//NMStatsAutoPlot( autoPlot )
	//NMStatsAutoStats2( autoStats2 )
	
	SetNMStatsVar( "AutoTable", autoTable )
	SetNMStatsVar( "AutoPlot", autoPlot )
	SetNMStatsVar( "AutoStats2", autoStats2 )
	SetNMStatsVar( "UseSubfolders" , useSubfolders )
	
	UpdateStats1()
	
	return 0

End // NMStatsAutoCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsAutoTable( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	on = BinaryCheck( on )
	
	SetNMStatsVar( "AutoTable", on )
	
	UpdateStats1()
	
	return on
	
End // NMStatsAutoTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsAutoPlot( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	on = BinaryCheck( on )
	
	SetNMStatsVar( "AutoPlot", on )
	
	UpdateStats1()
	
	return on
	
End // NMStatsAutoPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsAutoStats2( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	on = BinaryCheck( on )
	
	SetNMStatsVar( "AutoStats2", on )
	
	UpdateStats1()
	
	return on
	
End // NMStatsAutoStats2

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Display Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanControlsEnableAll( enable )
	Variable enable
	
	Variable ccnt
	String gName
	
	Variable currentChan = CurrentNMChannel()
	Variable numChan = NMNumChannels()
	
	if ( enable == 1 )
		SetNMwave( StatsDF()+"ChanSelect", -1, currentChan )
	endif
	
	for ( ccnt = 0; ccnt < numChan; ccnt += 1 )
	
		gName = ChanGraphName( ccnt ) 
		
		if ( WinType( gname ) != 1 )
			continue
		endif
		
		if ( ( ccnt == currentChan ) && ( enable == 1 ) )
			StatsChanControlsUpdate( ccnt, -1, 1 )
			ChanControlsDisable( ccnt, "011000" )
		else
			StatsChanControlsUpdate( ccnt, -1, 0 )
			ChanControlsDisable( ccnt, "000000" )
		endif
		
	endfor

End // StatsChanControlsEnableAll

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanControlsUpdate( chanNum, win, enable )
	Variable chanNum // channel number
	Variable win // Stats window number
	Variable enable
	
	StatsChanControlsEnable( chanNum, win, enable )
	ChanGraphControlsUpdate( chanNum )

End // StatsChanControlsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsChanControlsEnable( chanNum, win, enable )
	Variable chanNum // channel number
	Variable win // Stats window number
	Variable enable
	
	String sdf = StatsDF(), ndf = NMDF()
	
	Wave AmpB = $sdf+"AmpB"
	Wave AmpE = $sdf+"AmpE"
	Wave BslnB = $sdf+"BslnB"
	Wave BslnE = $sdf+"BslnE"
	
	Wave dtFlag = $sdf+"dtFlag"
	Wave FilterNum = $sdf+"SmthNum"
	Wave /T FilterAlg = $sdf+"SmthAlg"
	
	chanNum = ChanNumCheck( chanNum )
	
	win = CheckNMStatsWin( "StatsChanControlsEnable", win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( enable == 1 )
	
		SetNMStatsVar( "Transform", dtFlag[ win ] ) // for channel graph display
		SetNMStatsVar( "SmoothN", FilterNum[ win ] ) // for channel graph display
		SetNMStatsStr( "SmoothA", FilterAlg[ win ] ) // for channel graph display
		
		if ( dtFlag[ win ] > 3 )
			SetNMStatsVar( "Norm_Tbgn", AmpB[ win ] )
			SetNMStatsVar( "Norm_Tend", AmpE[ win ] )
			SetNMStatsVar( "Norm_Bbgn", BslnB[ win ] )
			SetNMStatsVar( "Norm_Bend", BslnE[ win ] )
		endif
		
		SetNMstr( ndf + "ChanSmthDF" + num2istr( chanNum ), sdf )
		SetNMstr( ndf + "ChanSmthProc" + num2istr( chanNum ), "NMStatsSetFilter" )
		
		SetNMstr( ndf + "ChanFuncDF" + num2istr( chanNum ), sdf )
		SetNMstr( ndf + "ChanFuncProc" + num2istr( chanNum ), "NMStatsTransformCheckBox" )
		
	else
		
		KillStrings /Z $( ndf + "ChanSmthDF" + num2istr( chanNum ) )
		KillStrings /Z $( ndf + "ChanSmthProc" + num2istr( chanNum ) )
		
		KillStrings /Z $( ndf + "ChanFuncDF" + num2istr( chanNum ) )
		KillStrings /Z $( ndf+ "ChanFuncProc" + num2istr( chanNum ) )
	
	endif
	
	return 0
	
End // StatsChanControlsEnable

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDisplay( chanNum, appnd ) // append/remove display waves to current channel graph
	Variable chanNum // channel number ( -1 ) for current channel
	Variable appnd // ( 0 ) remove ( 1 ) append
	
	String sdf = StatsDF()
	
	Variable anum, xy, icnt, ccnt, drag = appnd
	Variable r, g, b, br, bg, bb, rr, rg, rb
	String gName
	
	Variable labelsOn = NMStatsVar( "GraphLabelsOn" )
	
	Variable ampNV = NMStatsVar( "AmpNV" )
	
	if ( ( NeuroMaticVar( "DragOn" ) == 0 ) || ( StringMatch( CurrentNMTabName(), "Stats" ) == 0 ) )
		drag = 0
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) != 1 )
			continue
		endif
		
		RemoveFromGraph /Z/W=$gName ST_BslnY, ST_WinY, ST_PntY, ST_RDY
		RemoveFromGraph /Z/W=$gName DragTbgnY, DragTendY
		RemoveFromGraph /Z/W=$gName DragBslnTbgnY, DragBslnTendY
		
	endfor
	
	gName = ChanGraphName( chanNum )
	
	if ( Wintype( gName ) != 1 )
		return 0
	endif
	
	r = StatsDisplayColor( "Amp", "r" )
	g = StatsDisplayColor( "Amp", "g" )
	b = StatsDisplayColor( "Amp", "b" )
	
	br = StatsDisplayColor( "Base", "r" )
	bg = StatsDisplayColor( "Base", "g" )
	bb = StatsDisplayColor( "Base", "b" )
	
	rr = StatsDisplayColor( "Rise", "r" )
	rg = StatsDisplayColor( "Rise", "g" )
	rb = StatsDisplayColor( "Rise", "b" )
	
	if ( appnd == 1 )

		AppendToGraph /W=$gName $( sdf+"ST_BslnY" ) vs $( sdf+"ST_BslnX" )
		AppendToGraph /W=$gName $( sdf+"ST_WinY" ) vs $( sdf+"ST_WinX" )
		AppendToGraph /W=$gName $( sdf+"ST_PntY" ) vs $( sdf+"ST_PntX" )
		AppendToGraph /W=$gName $( sdf+"ST_RDY" ) vs $( sdf+"ST_RDX" )
		
		ModifyGraph /W=$gName lsize( ST_BslnY )=1.1, rgb( ST_BslnY )=( br,bg,bb )
		ModifyGraph /W=$gName mode( ST_PntY )=3, marker( ST_PntY )=19, rgb( ST_PntY )=( r,g,b )
		ModifyGraph /W=$gName lsize( ST_WinY )=1.1, rgb( ST_WinY )=( r,g,b )
		ModifyGraph /W=$gName mode( ST_RDY )=3, marker( ST_RDY )=9, mrkThick( ST_RDY )=2
		ModifyGraph /W=$gName msize( ST_RDY )=4, rgb( ST_RDY )=( rr,rg,rb )
		
		Tag /W=$gName/N=ST_Win_Tag/G=( r,g,b )/I=1/F=0/L=0/X=5.0/Y=0.00/V=( labelsOn ) ST_WinY, 1, " \\{\"%.2f\",TagVal( 2 )}"
		Tag /W=$gName/N=ST_Bsln_Tag/G=( br,bg,bb )/I=1/F=0/L=0/X=5.0/Y=0.00/V=( labelsOn ) ST_BslnY, 1, " \\{\"%.2f\",TagVal( 2 )}"
			
	endif
		
	NMDragEnable( drag, "DragTbgn", sdf+"AmpB", sdf+"AmpNV", "NMStatsDragTrigger", gName, "bottom", "min", r, g, b )
	NMDragEnable( drag, "DragTend", sdf+"AmpE", sdf+"AmpNV", "NMStatsDragTrigger", gName, "bottom", "max", r, g, b )
	NMDragEnable( drag, "DragBslnTbgn", sdf+"BslnB", sdf+"AmpNV", "NMStatsDragTrigger", gName, "bottom", "min", br, bg, bb )
	NMDragEnable( drag, "DragBslnTend", sdf+"BslnE", sdf+"AmpNV", "NMStatsDragTrigger", gName, "bottom", "max", br, bg, bb )

	return 0

End // StatsDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsDragTrigger( offsetStr )
	String offsetStr
	
	if ( NMDragTrigger( offsetStr ) == 0 )
		StatsTimeStamp( StatsDF() )
	endif
	
End // NMStatsDragTrigger

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsDragUpdate()

	Variable ampDrag, bslnDrag
	String ampStr, sdf = StatsDF()
	
	Variable drag = NeuroMaticVar( "DragOn" )
	Variable ampNV = NMStatsVar( "AmpNV" )
	
	if ( WaveExists( $sdf+"AmpSlct" ) == 1 )
	
		Wave /T ampSlct = $sdf+"AmpSlct"
		
		if ( ( ampNV >= 0 ) && ( ampNV < numpnts( ampSlct ) ) )
			
			ampStr = ampSlct[ ampNV ]
			
			if ( ( strlen( ampStr ) == 0 ) || ( StringMatch( ampStr, "Off" ) == 1 ) )
				ampDrag = 0
			else
				ampDrag = 1
			endif
			
		endif
	
	endif
	
	if ( WaveExists( $sdf+"Bflag" ) == 1 )
	
		Wave bflag = $sdf+"Bflag"
		
		if ( ( ampNV >= 0 ) && ( ampNV < numpnts( bflag ) ) )
			bslnDrag = BinaryCheck( bflag[ ampNV ] )
		endif
		
	endif
	
	if ( ( drag == 1 ) && ( ampDrag == 1 ) )
		NMDragUpdate( "DragTbgn" )
		NMDragUpdate( "DragTend" )
	else
		NMDragClear( "DragTbgn" )
		NMDragClear( "DragTend" )
	endif
	
	if ( ( drag == 1 ) && ( bslnDrag == 1 ) )
		NMDragUpdate( "DragBslnTbgn" )
		NMDragUpdate( "DragBslnTend" )
	else
		NMDragClear( "DragBslnTbgn" )
		NMDragClear( "DragBslnTend" )
	endif

End // NMStatsDragUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsDragClear()
	
	NMDragClear( "DragTbgn" )
	NMDragClear( "DragTend" )
	NMDragClear( "DragBslnTbgn" )
	NMDragClear( "DragBslnTend" )
	
End // NMStatsDragClear

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDisplayColor( select, rgb )
	String select // ( a ) Amp ( b ) Base ( r ) Rise
	String rgb // r, g or b
	
	String color
	
	strswitch( select )
		case "amp":
			color = NMStatsStr( "AmpColor" )
			break
		case "base":
			color = NMStatsStr( "BaseColor" )
			break
		case "rise":
			color = NMStatsStr( "RiseColor" )
			break
	endswitch

	return str2num( StringFromList( WhichListItem( rgb, "r;g;b;" ),color,"," ) )

End // StatsDisplayColor

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDisplayClear()

	String sdf = StatsDF()
	
	SetNMwave( sdf+"ST_BslnY", -1, Nan )
	SetNMwave( sdf+"ST_WinY", -1, Nan )
	SetNMwave( sdf+"ST_PntY", -1, Nan )
	SetNMwave( sdf+"ST_RDY", -1, Nan )
	
	NMStatsDragClear()

End // StatsDisplayClear

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLabelsCall( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	NMCmdHistory( "StatsLabels", NMCmdNum( on,"" ) )
	
	return StatsLabels( on )
	
End // StatsLabelsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLabels( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	on = BinaryCheck( on )
	
	SetNMStatsVar( "GraphLabelsOn", on )
	NMAutoStats()
	
	return on
	
End // StatsLabels

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLabelsToggle()

	Variable on = NMStatsVar( "GraphLabelsOn" )
	
	on = BinaryInvert( on )
	
	SetNMStatsVar( "GraphLabelsOn", on )
	
	StatsDisplay( -1, 1 )
	NMAutoStats()
	
	return on
	
End // StatsLabelsToggle

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Stats1 Computation Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMAutoStats() // compute Stats of currently selected channel / wave

	String wName = ChanDisplayWave( -1 )
	
	StatsDisplayClear()
	
	if ( WaveExists( $wName ) == 1 )
		StatsComputeWin( -1, wName, 1 )
	endif
	
	UpdateStats()
	
	NMStatsDragUpdate()
	
End // NMAutoStats

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsComputeAllCall()

	Variable allwin, table, plot, stats2, numWin = StatsWinCount()
	String vlist = "", select
	
	Variable winNum = NMStatsVar( "AmpNV" )
	Variable dsplyFlag = 1 + NMStatsVar( "ComputeAllDisplay" )
	Variable speed = NMStatsVar( "ComputeAllSpeed" ) 
	
	if ( NMNumActiveWaves() <= 0 )
		NMDoAlert( "No waves selected!" )
		return -1
	endif
	
	if ( numWin <= 0 )
		NMDoAlert( "All Stats windows are off." )
		return -1
	elseif ( numWin == 1 )
		allwin = 1
	elseif ( numWin > 1 )
		allwin = 1 + NMStatsVar( "ComputeAllWin" )
	endif
	
	Prompt allwin, "compute:", popup "current stats window;all stats windows;"
	Prompt dsplyFlag, "display results while computing?", popup "no;yes;"
	Prompt speed, "optional display update delay ( seconds ):"
	
	if ( numWin > 1 )
		DoPrompt NMPromptStr( "Stats Compute All" ), allwin, dsplyFlag, speed
		allwin -= 1
	else
		DoPrompt NMPromptStr( "Stats Compute All" ), dsplyFlag, speed
	endif
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	dsplyFlag -= 1
	
	SetNMStatsVar( "ComputeAllWin", allwin )
	SetNMStatsVar( "ComputeAllDisplay", dsplyFlag )
	SetNMStatsVar( "ComputeAllSpeed", speed )
	
	select = StatsAmpSelectGet( winNum )
	
	if ( ( allwin == 0 ) && ( StringMatch( select, "Off" ) == 1 ) )
		NMDoAlert( "Current Stats window is off." )
		return -1
	endif
		
	if ( allwin == 1 )
		winNum = -1
	endif
	
	table = NMStatsVar( "AutoTable" )
	plot = NMStatsVar( "AutoPlot" )
	stats2 = NMStatsVar( "AutoStats2" )
	
	vlist = NMCmdNum( winNum, vlist )
	vlist = NMCmdNum( dsplyFlag, vlist )
	vlist = NMCmdNum( speed, vlist )
	vlist = NMCmdNum( table, vlist )
	vlist = NMCmdNum( plot, vlist )
	vlist = NMCmdNum( stats2, vlist )
	NMCmdHistory( "NMStatsComputeAll", vlist )
	
	return NMStatsComputeAll( winNum, dsplyFlag, speed, table, plot, stats2 )

End // NMStatsComputeAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsComputeAll( win, dsplyFlag, speed, table, plot, stats2 )
	Variable win // Stats window number ( -1 for all windows that are not "Off" )
	Variable dsplyFlag // display results in channel graphs while computing ( 0 ) no ( 1 ) yes
	Variable speed // update display speed in seconds ( 0 ) for fastest
	Variable table // automatically create output table? ( 0 ) no ( 1 ) yes
	Variable plot // automatically plot default Stats wave? ( 0 ) no ( 1 ) yes
	Variable stats2 // automatically compute average/stdv of the output Stats waves? ( 0 ) no ( 1 ) yes

	Variable icnt, ccnt, wcnt, pflag, cancel, waveNum, changeChan
	String wName, gName, wList, tList = "", tName = "", tName2 = "", deleteRowsList = ""
	String windowList, thisfxn = "NMStatsComputeAll", df = StatsDF()

	String prefixFolder = CurrentNMPrefixFolder()
	String subfolder = CurrentNMStatsSubfolder()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	Variable drag = NeuroMaticVar( "DragOn" )
	
	Variable saveCurrentChan = CurrentNMChannel()
	Variable saveCurrentWave = CurrentNMWave()
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	CheckNMStatsWaves( 0 )
	
	if ( win == -1 )
	
		windowList = NMStatsWinList( 1, "" ) // all windows
		
	else
	
		win = CheckNMStatsWin( thisfxn, win )
		
		if ( numtype( win ) > 0 )
			return -1
		endif
		
		windowList = num2istr( win )
		
	endif
	
	if ( dsplyFlag == 0 )
		drag = 0
	endif
	
	if ( drag == 1 )
		NMDragOn( 0 )
		NMStatsDragClear()
	endif
	
	Variable waveLengthFormat = NMStatsVar( "WaveLengthFormat" )
	
	String saveChanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	String allList = NMWaveSelectAllList()
	Variable allListItems = ItemsInList( allList )
	
	for ( icnt = 0; icnt < max( allListItems, 1 ) ; icnt += 1 ) // loop thru sets / groups
		
		if ( allListItems > 0 )
			waveSelect = StringFromList( icnt, allList )
			NMWaveSelect( waveSelect )
		endif
		
		if ( NMNumActiveWaves() <= 0 )
			continue
		endif
	
		for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue // channel not selected
			endif
			
			if ( table == 1 )
			
				tName = NMStatsWavesTable( "_subfolder_", ccnt, windowList )
				
				if ( WinType( tName ) == 2 )
					tList = AddListItem( tName, tList, ";", inf )
				endif
				
			else
			
				wList = StatsWavesMake( "_subfolder_", ccnt, windowList )
				
			endif
			
			DoWindow /Hide=1 $tName
			
			if ( dsplyFlag == 1 )
			
				if ( ccnt != saveCurrentChan )
					StatsDisplay( -1, 0 ) // remove stats display waves
					StatsDisplay( ccnt, 1 ) // add stats display waves
					changeChan = 1
				endif
				
				StatsDisplayClear()
				//ChanControlsDisable( ccnt, "111111" )
				DoWindow /F $ChanGraphName( ccnt )
				DoUpdate
				
			endif
			
			SetNeuroMaticStr( "ProgressStr", "Stats Chan " + ChanNum2Char( ccnt ) )
		
			for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
				
				if ( CallNMProgress( wcnt, numWaves ) == 1 )
					break
				endif
				
				wName = NMWaveSelected( ccnt, wcnt )
				
				if ( strlen( wName ) == 0 )
				
					if ( waveLengthFormat == 1 )
						deleteRowsList = AddListItem( num2istr( wcnt ), deleteRowsList, ";", 0 ) // PREPEND
					endif
					
					continue // wave not selected, or does not exist... go to next wave
					
				endif
				
				NMCurrentWaveSetNoUpdate( wcnt )
				
				if ( dsplyFlag == 1 )
					ChanGraphUpdate( ccnt, 1 )
				endif
		
				StatsCompute( wName, ccnt, wcnt, win, 1, dsplyFlag )
				
				if ( ( dsplyFlag == 1 ) && ( numtype( speed ) == 0 ) && ( speed > 0 ) )
					NMwaitMSTimer( speed * 1000 )
				endif
					
			endfor
			
			if ( waveLengthFormat == 1 )
			
				for ( wcnt = 0 ; wcnt < ItemsInList( deleteRowsList ) ; wcnt += 1 )
					waveNum = str2num( StringFromList( wcnt, deleteRowsList ) )
					NMStatsDelete( ccnt, waveNum )
				endfor
			
			endif
			
			if ( stats2 == 1 )
				subfolder = NMStatsSubfolder( "", ccnt )
				tName2 = NMStats2WaveStatsTable( subfolder, 0 )
				tList = AddListItem( tName2, tList, ";", inf )
				DoWindow /Hide=1 $tName2
			endif
			
			if ( NMProgressCancel() == 1 )
				break
			endif
			
		endfor
		
	endfor
	
	if ( allListItems > 0 )
		NMWaveSelect( saveWaveSelect )
	endif
	
	ResetProgress()
	
	if ( changeChan == 1 ) // back to original channel
		StatsDisplay( ccnt, 0 ) // remove display waves
		StatsDisplay( saveCurrentChan, 1 ) // add display waves
		SetNMvar( prefixFolder+"CurrentChan", saveCurrentChan )
	endif
	
	NMCurrentWaveSetNoUpdate( saveCurrentWave )
	
	StatsDisplayClear()	
	ChanGraphsUpdate()
	StatsCompute( "", -1, -1, -1, 0, 1 )
	
	if ( drag == 1 )
		NMDragOn( 1 )
		NMStatsDragUpdate()
	endif
	
	for ( icnt = 0; icnt < ItemsInList( tList ); icnt += 1 )
	
		tName = StringFromList( icnt, tList )
	
		if ( ( strlen( tName ) > 0 ) && ( WinType( tName ) == 2 ) )
			DoWindow /F/Hide=0 $tName
		endif
	
	endfor
	
	StatsChanControlsEnableAll( 1 )
	
	NMStats2WaveSelectFilter( "Stats1" )
	
	NMStats2WaveSelect( CurrentNMStatsSubfolder(), "" ) // set default values
	
	if ( plot == 1 )
		NMStats2Plot( "", "" )
	endif
	
	return 0

End // NMStatsComputeAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsDelete( chanNum, waveNum ) // compute amps of given wave
	Variable chanNum // channel number ( -1 ) current channel
	Variable waveNum // wave number ( -1 ) current wave
	
	Variable icnt
	String select, subfolder, wName, df = StatsDF()
	
	Variable ampNV = NMStatsVar( "AmpNV" )
	
	if ( chanNum < 0 )
		chanNum = CurrentNMChannel()
	endif
	
	if ( waveNum < 0 )
		waveNum = CurrentNMWave()
	endif
	
	subfolder = NMStatsSubfolder( "", chanNum )
	
	wName = NMStatsWaveNameForWName( subfolder, chanNum, 1 )
	
	StatsAmpSave2( wName, waveNum, Nan, 2 )

	for ( icnt = 0; icnt < numpnts( $df+"AmpSlct" ); icnt += 1 )
	
		select = StatsAmpSelectGet( icnt )
		
		if ( StringMatch( select, "Off" ) == 1 )
			continue
		endif
		
		StatsAmpSave( subfolder, chanNum, waveNum, icnt, 2 )
		
	endfor
	
	return 0
		
End // NMStatsDelete

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsCompute( wName, chanNum, waveNum, win, saveflag, dsplyflag ) // compute amps of given wave
	String wName // wave name, ( "" ) for current channel display wave
	Variable chanNum // channel number ( -1 ) current channel
	Variable waveNum // wave number ( -1 ) current wave
	Variable win // Stats window number ( -1 ) for all
	Variable saveflag // save to table waves
	Variable dsplyflag // update channel display graph
	
	Variable icnt, ifirst, ilast, dFlag, dtFlagLast, filterNumLast, newWave
	String filterAlgLast, waveLast, select, dName, subfolder, df = StatsDF()
	
	String tName = "ST_WaveTemp"
	
	Variable ampNV = NMStatsVar( "AmpNV" )
	
	Wave dtFlag = $df+"dtFlag"
	Wave FilterNum = $df+"SmthNum"
	Wave /T FilterAlg = $df+"SmthAlg"
	
	if ( chanNum < 0 )
		chanNum = CurrentNMChannel()
	endif
	
	if ( waveNum < 0 )
		waveNum = CurrentNMWave()
	endif
	
	if ( strlen( wName ) == 0 )
		wName = NMChanWaveName( chanNum, waveNum )
	endif
	
	if ( win == -1 )
	
		ifirst = 0
		ilast = numpnts( $df+"AmpSlct" )
		
	else
	
		win = CheckNMStatsWin( "StatsCompute", win )
		
		if ( numtype( win ) > 0 )
			return -1
		endif
		
		ifirst = win
		ilast = win + 1
		
	endif
	
	dtFlagLast = ChanFuncGet( chanNum )
	filterNumLast = ChanFilterNumGet( chanNum )
	filterAlgLast = ChanFilterAlgGet( chanNum )
	waveLast = ChanDisplayWave( chanNum )

	for ( icnt = ifirst; icnt < ilast; icnt += 1 )
	
		select = StatsAmpSelectGet( icnt )
		
		if ( StringMatch( select, "Off" ) == 1 )
			continue
		endif
		
		if ( dsplyflag == 1 )
			dName = ChanDisplayWave( chanNum )
		else
			dName = tName
		endif
		
		StatsChanControlsEnable( chanNum, icnt, 1 )
		
		newWave = 0
		
		if ( ( WaveExists( $dName ) == 0 ) || ( StringMatch( dName, waveLast ) == 0 ) )
			newWave = 1
		elseif ( ( dtFlag[ icnt ] != dtFlagLast ) || ( FilterNum[ icnt ] != filterNumLast ) )
			newWave = 1
		elseif ( ( FilterNum[ icnt ] > 0 ) && ( StringMatch( FilterAlg[ icnt ], filterAlgLast ) == 0 ) )
			newWave = 1
		endif
		
		if ( newWave == 1 )
			filterNumLast = FilterNum[ icnt ]
			filterAlgLast = FilterAlg[ icnt ]
			dtFlagLast = dtFlag[ icnt ]
		endif
		
		if ( ( newWave == 1 ) && ( ChanWaveMake( chanNum, wName, dName ) < 0 ) )
			continue
		endif
		
		if ( icnt == AmpNV )
			dFlag = 1
		else
			dFlag = 0
		endif
		
		if ( StatsComputeWin( icnt, dName, dsplyflag * dFlag ) < 0 )
			continue // error
		endif
		
		if ( ( dsplyflag == 1 ) && ( icnt == AmpNV ) )
			DoUpdate
		endif
	
		if ( saveflag == 1 )
			subfolder = NMStatsSubfolder( "", chanNum )
			StatsAmpSave( subfolder, chanNum, waveNum, icnt, 0 )
		endif
			
	endfor
	
	KillWaves /Z $tName
	
	return 0
		
End // StatsCompute

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsComputeWin( win, wName, dsplyflag ) // compute window stats
	Variable win // Stats window number
	String wName // name of wave to measure
	Variable dsplyflag // update channel display graph
	
	Variable ay, ax, ax2, by, bx, bx2, aybsln, dumvar, offset, off, bsln, avgwin
	Variable t1, t2, tbgn, tend, bbgn, bend, tbgn2, tend2, bbgn2, bend2
	Variable percentBgn, percentEnd
	String select, dumstr, thisfxn = "StatsComputeWin"
	
	String df = StatsDF()
	
	Variable ampNV = NMStatsVar( "AmpNV" )
	
	win = CheckNMStatsWin( thisfxn, win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( DataFolderExists( df ) == 0 )
		return NMError( 30, thisfxn, "StatsDF", df )
	endif
	
	if ( strlen( wName ) == 0 )
		return -1
	endif
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	if ( WaveExists( $df+"AmpB" ) == 0 )
		return NMError( 1, thisfxn, "AmpB", df+"AmpB" )
	endif
	
	Wave AmpB = $df+"AmpB"
	Wave AmpE = $df+"AmpE"
	Wave AmpY = $df+"AmpY"
	Wave AmpX = $df+"AmpX"
	
	Wave /T BslnSlct = $df+"BslnSlct"
	Wave Bflag = $df+"Bflag"
	Wave BslnB = $df+"BslnB"
	Wave BslnE = $df+"BslnE"
	Wave BslnY = $df+"BslnY"
	Wave BslnX = $df+"BslnX"
	Wave BslnSubt = $df+"BslnSubt"
	
	Wave RiseTm = $df+"RiseTm"
	Wave RiseBP = $df+"RiseBP"
	Wave RiseEP = $df+"RiseEP"
	Wave RiseBX = $df+"RiseBX"
	Wave RiseEX = $df+"RiseEX"
	
	Wave DcayT = $df+"DcayT"
	Wave DcayP = $df+"DcayP"
	Wave DcayX = $df+"DcayX"
	
	Wave ST_PntX = $df+"ST_PntX"
	Wave ST_PntY = $df+"ST_PntY"
	Wave ST_WinX = $df+"ST_WinX"
	Wave ST_WinY = $df+"ST_WinY"
	Wave ST_BslnX = $df+"ST_BslnX"
	Wave ST_BslnY = $df+"ST_BslnY"
	Wave ST_RDX = $df+"ST_RDX"
	Wave ST_RDY = $df+"ST_RDY"
	
	offset = StatsOffsetValue( win )
	
	if ( numtype( offset ) > 0 )
		offset = 0
	endif
	
	select = StatsAmpSelectGet( win )
	
	if ( ( StringMatch( select[ 0, 5 ], "MaxAvg" ) == 1 ) || ( StringMatch( select[ 0, 5 ], "MinAvg" ) == 1 ) )
	
		avgwin = str2num( select[ 6, inf ] )
		
		if ( numtype( avgwin ) == 0 )
			select = select[ 0, 5 ]
		endif
		
	endif
	
	strswitch( select )
	
		case "Level":
		case "Level+":
		case "Level-":
			break
			
		default:
			AmpY[ win ] = Nan
			
	endswitch
	
	BslnX[ win ] = Nan
	BslnY[ win ] = Nan
	AmpX[ win ] = Nan
	RiseBX[ win ] = Nan
	RiseEX[ win ] = Nan
	RiseTm[ win ] = Nan
	DcayX[ win ] = Nan
	DcayT[ win ] = Nan
	
	if ( Bflag[ win ] == 1 )
		bsln = 1
	endif
	
	strswitch( select )
	
		case "RiseTime+":
		case "DecayTime+":
		case "FWHM+":
		case "RTslope+":
		case "RiseTime-":
		case "DecayTime-":
		case "FWHM-":
		case "RTslope-":
			bsln = 1 // must compute baseline
			break
			
	endswitch
	
	if ( StringMatch( select[ 0,2 ], "Off" ) == 1 )
		off = 1
		bsln = 0
	endif
	
	if ( dsplyflag == 1 )
	
		ST_BslnX = Nan
		ST_BslnY = Nan
		ST_WinX = Nan
		ST_WinY = Nan
		ST_PntX = Nan
		ST_PntY = Nan
		ST_RDX = Nan
		ST_RDY = Nan
		
	endif
	
	Wave wtemp = $wName
	
	bx = Nan
	bx2 = Nan
	by = Nan
	
	// baseline stats
	
	if ( bsln == 1 )
	
		//if ( BslnB[ win ] > BslnE[ win ] )
		//	dumvar = BslnE[ win ] // switch
		//	BslnE[ win ] = BslnB[ win ]
		//	BslnB[ win ] = dumvar
		//endif
		
		if ( numtype( BslnB[ win ] ) == 0 )
			bbgn = BslnB[ win ]
		else
			bbgn = NMLeftX( wName )
		endif
		
		if ( numtype( BslnE[ win ] ) == 0 )
			bend = BslnE[ win ]
		else
			bend = NMRightX( wName )
		endif
	 
	 	if ( ( numtype( offset ) == 0 ) && ( NMStatsOffsetBaseline( win ) == 1 ) )
			bbgn += offset
			bend += offset
		endif
		
		if ( bbgn > bend )
			dumvar = bend // switch
			bend = bbgn
			bbgn = dumvar
		endif
		
		bbgn2 = NMXvalueTransform( wName, bbgn, -1, 1 )
		bend2 = NMXvalueTransform( wName, bend, -1, -1 )
		
		if ( bbgn < bend )
			ComputeWaveStats( wtemp, bbgn2, bend2, BslnSlct[ win ], 0 )
			by = NumVarOrDefault( "U_ay", Nan )
			bx2 = NumVarOrDefault( "U_ax", Nan )
			bx = NMXvalueTransform( wName, bx2, 1, 0 )
		endif
		
		BslnY[ win ] = by
		BslnX[ win ] = bx
	
	endif
	
	// compute amplitude stats
	
	ax = Nan
	ax2 = Nan
	ay = Nan
	
	if ( off == 0 )
		
		if ( numtype( AmpB[ win ] ) == 0 )
			tbgn = AmpB[ win ]
		else
			tbgn = NMLeftX( wName )
		endif
		
		if ( numtype( AmpE[ win ] ) == 0 )
			tend = AmpE[ win ]
		else
			tend = NMRightX( wName )
		endif
		
		if ( numtype( offset ) == 0 )
			tbgn += offset
			tend += offset
		endif
		
		if ( tbgn > tend )
			dumvar = tend // switch
			tend = tbgn
			tbgn = dumvar
		endif
		
		tbgn2 = NMXvalueTransform( wName, tbgn, -1, 1 )
		tend2 = NMXvalueTransform( wName, tend, -1, -1 )
		
		strswitch( select )
		
			case "RiseTime+":
			case "DecayTime+":
			case "FWHM+":
			case "RTslope+":
			case "MaxAvg":
				ComputeWaveStats( wtemp, tbgn2, tend2, "max", AmpY[ win ] )
				break
				
			case "RiseTime-":
			case "DecayTime-":
			case "FWHM-":
			case "RTslope-":
			case "MinAvg":
				ComputeWaveStats( wtemp, tbgn2, tend2, "min", AmpY[ win ] )
				break
			
			default:
				ComputeWaveStats( wtemp, tbgn2, tend2, select, AmpY[ win ] )
				
		endswitch
		
		ay = NumVarOrDefault( "U_ay", Nan )
		ax2 = NumVarOrDefault( "U_ax", Nan )
		ax = NMXvalueTransform( wName, ax2, 1, 0 )
		
		strswitch( select )
		
			case "MaxAvg":
			case "MinAvg":
				percentBgn = x2pnt( wtemp, ax2 - abs( avgwin/2 ) ) - 1
				percentEnd = x2pnt( wtemp, ax2 + abs( avgwin/2 ) )
				WaveStats /Q/Z/R=[ percentBgn, percentEnd ] wtemp
				ay = V_avg
				break
				
		endswitch
		
		aybsln = ay - by
	
	endif
	
	// compute rise time, decay time, fwhm
	
	strswitch( select )
		
		case "RiseTime+":
		case "RiseTime-":
		case "RTslope+":
		case "RTslope-":
	
			dumvar = ( ( RiseBP[ win ] / 100 ) * aybsln ) + by
			FindLevel /Q /R=( ax2, tbgn2 ) wtemp, dumvar
		
			if ( V_Flag == 0 )
				t1 = V_LevelX
				RiseBX[ win ] = NMXvalueTransform( wName, t1, 1, 0 )
			endif
		
			dumvar = ( ( RiseEP[ win ] / 100 ) * aybsln ) + by
			FindLevel /Q /R=( ax2, tbgn2 ) wtemp, dumvar
			
			if ( V_Flag == 0 )
				t2 = V_LevelX
				RiseEX[ win ] = NMXvalueTransform( wName, t2, 1, 0 )
			endif
			
			RiseTm[ win ] = RiseEX[ win ] - RiseBX[ win ]
			
			break
		
		case "DecayTime+":
		case "DecayTime-":
			
			dumvar = ( ( DcayP[ win ]/100 )*aybsln ) + by
			FindLevel /Q/R=( ax2, tend2 ) wtemp, dumvar
			
			if ( V_Flag == 0 )
				t1 = V_LevelX
				DcayX[ win ] = NMXvalueTransform( wName, t1, 1, 0 )
			endif
			
			DcayT[ win ] = DcayX[ win ] - ax
			
			break
			
		case "FWHM+":
		case "FWHM-":
		
			RiseBX[ win ] = Nan
			dumvar = 0.5 * aybsln + by

			FindLevel /Q/R=( ax2, tbgn2 ) wtemp, dumvar
		
			if ( V_Flag == 0 ) // use rise-time waves for now
				t1 = V_LevelX
				RiseBX[ win ] = NMXvalueTransform( wName, t1, 1, 0 )
			endif
		
			RiseEX[ win ] = Nan
			FindLevel /Q/R=( ax2, tend2 ) wtemp, dumvar
			
			if ( V_Flag == 0 )
				t2 = V_LevelX
				RiseEX[ win ] = NMXvalueTransform( wName, t2, 1, 0 )
			endif
			
			RiseTm[ win ] = RiseEX[ win ] - RiseBX[ win ]
			
			break
	
	endswitch
	
	// rise-time slope function
	
	strswitch( select )
	
		case "RTslope+":
		case "RTslope-":
			dumstr = FindSlope( t1, t2, wName )
			ay = str2num( StringByKey( "m", dumstr, "=" ) )
			ax2 = str2num( StringByKey( "b", dumstr, "=" ) )
			ax = NMXvalueTransform( wName, ax2, 1, 0 )
			break
			
	endswitch
	
	// save final amp values
	
	if ( off == 0 )
	
		if ( ( bsln == 1 ) && ( BslnSubt[ win ] == 1 ) )
			AmpY[ win ] = aybsln
		else
			AmpY[ win ] = ay
		endif
		
		strswitch( select )
		
			case "Slope":
			case "RTslope+":
			case "RTslope-":
				AmpX[ win ] = ax2
				break
		
			case "RiseTime+":
			case "RiseTime-":
			case "FWHM+":
			case "FWHM-":
				AmpY[ win ] = Nan
				AmpX[ win ] = RiseTm[ win ]
				break
				
			case "DecayTime+":
			case "DecayTime-":
				AmpY[ win ] = Nan
				AmpX[ win ] = DcayT[ win ]
				break
			
			default:
				AmpX[ win ] = ax
				
		endswitch
		
		KillVariables /Z U_ax, U_ay
		
		if ( win != AmpNV )
			return 0 // do not update display waves
		endif
	
	endif
	
	if ( ( dsplyflag == 0 ) || ( off == 1 ) )
		return 0 // no more to do
	endif
	
	// baseline display waves
	
	if ( bsln == 1 )
		ST_BslnX[ 0 ] = bbgn
		ST_BslnX[ 1 ] = bend
		ST_BslnY = by
	endif
	
	// amplitude display waves
	
	strswitch( select )
	
		case "SDev":
		case "Var":
		case "RMS":
		case "Area":
		case "Sum":
		case "Slope":
		case "RTslope+":
		case "RTslope-":
			ST_PntX = Nan
			ST_PntY = Nan
			break
			
		default:
			ST_PntX = ax
			ST_PntY = ay
			
	endswitch
	
	// rise/decay time display waves ( and FWHM )
	
	strswitch( select )
	
		case "RiseTime+":
		case "RiseTime-":
		case "RTslope+":
		case "RTslope-":
			ST_RDX[ 0 ] = RiseBX[ win ]
			ST_RDX[ 1 ] = RiseEX[ win ]
			ST_RDY[ 0 ] = ( ( RiseBP[ win ]/100 )*aybsln ) + by
			ST_RDY[ 1 ] = ( ( RiseEP[ win ]/100 )*aybsln ) + by
			break
			
		case "DecayTime+":
		case "DecayTime-":
			ST_RDX[ 0 ] = DcayX[ win ]
			ST_RDY[ 0 ] = ( ( DcayP[ win ]/100 )*aybsln ) + by
			break
		
		case "FWHM+":
		case "FWHM-":
			ST_RDX[ 0 ] = RiseBX[ win ]
			ST_RDX[ 1 ] = RiseEX[ win ]
			ST_RDY[ 0 ] = 0.5 * aybsln + by
			ST_RDY[ 1 ] = 0.5 * aybsln + by
			break
	
	endswitch
	
	// update window display line
	
	ST_WinX[ 0 ] = tbgn
	ST_WinX[ 1 ] = tend
	ST_WinY = ay
		
	strswitch( select )
	
		case "SDev":
		case "Var":
		case "RMS":
		case "Area":
		case "Sum":
			ST_WinY = Nan // set to NAN because these are usually of different scale
			break
	
		case "Slope":
			ST_WinY[ 0 ] = tbgn2*ay + ax2
			ST_WinY[ 1 ] = tend2*ay + ax2
			break
			
		case "RTslope+":
		case "RTslope-":
			ST_WinX[ 0 ] = RiseBX[ win ] + offset
			ST_WinX[ 1 ] = RiseEX[ win ] + offset
			ST_WinY[ 0 ] = NMXvalueTransform( wName, RiseBX[ win ], -1, 1 )*ay + ax2
			ST_WinY[ 1 ] = NMXvalueTransform( wName, RiseEX[ win ], -1, -1 )*ay + ax2
			break
			
		case "MaxAvg":
		case "MinAvg":
			ST_WinX[ 0 ] = ax - abs( avgwin/2 )
			ST_WinX[ 1 ] = ax + abs( avgwin/2 )
			break
			
	endswitch
	
	return 0

End // StatsAmpCompute

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stats result waves/table functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsWavesTable( folder, chanNum, windowList ) // create waves/table where Stats are stored
	String folder // data folder, ( "" ) for current data folder or ( "_subfolder_" ) for current subfolder
	Variable chanNum // channel number , ( -1 ) for current
	String windowList // list of windows to create ( "" ) for all currently active Stats windows
	
	Variable wcnt
	String wName, wList, wList2, title, tprefix, tName = ""
	String thisfxn = "NMStatsWavesTable"
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ItemsInlist( windowList ) == 0 )
		windowList = NMStatsWinList( 1, "" )
	endif
	
	if ( ItemsInlist( windowList ) == 0 )
		return NMErrorStr( 21, thisfxn, "windowList", windowList )
	endif
	
	wList = StatsWavesMake( folder, chanNum, windowList )
	
	if ( ItemsInList( wList ) == 0 )
		return "" // no waves were made
	endif
	
	tprefix = "ST_" + NMFolderPrefix( "" ) + NMWaveSelectStr() + "_Table_"
	tName = NextGraphName( tprefix, chanNum, NeuroMaticVar( "OverWrite" ) )

	if ( WinType( tName ) == 0 )
	
		title = NMFolderListName( "" ) + " : Ch " + ChanNum2Char( chanNum ) + " : Stats : " + NMWaveSelectGet()
	
		DoWindow /K $tName
		Edit /K=1/N=$tName/W=( 0,0,0,0 ) as title
		SetCascadeXY( tName )
		ModifyTable /W=$tName title( Point )="Wave"
		
		for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			if ( WaveExists( $wName ) == 1 )
				AppendToTable /W=$tName $wName
			endif
			
		endfor
		
		return tName
		
	elseif ( WinType( tName ) == 2 )
	
		DoWindow /F $tName
		
		wList2 = NMTableWaveList( tName, 1 )
	
		for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			if ( ( WaveExists( $wName ) == 1 ) && ( WhichListItem( wName, wList2 ) < 0 ) )
				AppendToTable /W=$tName $wName
			endif
			
		endfor
		
	endif
	
	return tName

End // NMStatsWavesTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesMake( folder, chanNum, windowList )
	String folder // data folder, ( "" ) for current data folder or ( "_subfolder_" ) for current subfolder
	Variable chanNum // channel number
	String windowList // list of windows to create ( "" ) for all currently active Stats windows

	Variable icnt, winNum, wselect, offset, xwave, ywave, setDefault
	String wName, wNames, header, statsnote, wnote, xl, yl, select, wList = "", rf = "Rise"
	String wNameDefault = "", thisfxn = "StatsWavesMake", df = StatsDF()
	
	String currentPrefix = CurrentNMWavePrefix()
	String currentWaveName = CurrentNMWaveName()
	
	String xLabel = NMChanLabel( -1, "x", currentWaveName )
	String yLabel = NMChanLabel( -1, "y", currentWaveName )
	
	String xUnits = UnitsFromStr( xLabel )
	String yUnits = UnitsFromStr( yLabel )
	
	Variable currentWin = NMStatsVar( "AmpNV" )
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ItemsInlist( windowList ) == 0 )
		windowList = NMStatsWinList( 1, "" )
	endif
	
	if ( ItemsInlist( windowList ) == 0 )
		return NMErrorStr( 21, thisfxn, "windowList", windowList )
	endif

	Wave AmpB = $df+"AmpB"
	Wave AmpE = $df+"AmpE"
	
	Wave /T BslnSlct = $df+"BslnSlct"
	Wave Bflag = $df+"Bflag"
	Wave BslnSubt = $df+"BslnSubt"
	Wave BslnB = $df+"BslnB"
	Wave BslnE = $df+"BslnE"
	
	Wave RiseBP = $df+"RiseBP"
	Wave RiseEP = $df+"RiseEP"
	Wave DcayP = $df+"DcayP"
	
	Wave FilterNum = $df+"SmthNum"
	Wave /T FilterAlg = $df+"SmthAlg"
	Wave dtFlag = $df+"dtFlag"
	
	xl = currentPrefix + " #"
	
	wNames = NMStatsWaveNameForWName( folder, chanNum, 1 )
	
	Make /T/O/N=( NMNumWaves() ) $wNames // create wave of wave names
	
	NMNoteType( wNames, "NMStats Wave Names", "", "", "" )
	
	Wave /T wtext = $wNames
	
	wtext = ""
	wList = NMChanWaveList( chanNum )
	
	for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
		wtext[ icnt ] = StringFromList( icnt, wList )
	endfor
	
	wList = AddListItem( wNames, "", ";", inf )

	for ( icnt = 0; icnt < ItemsInList( windowList ) ; icnt += 1 )
	
		winNum = str2num( StringFromList( icnt, windowList ) )
		
		select = StatsAmpSelectGet( winNum )
	
		if ( StringMatch( select, "Off" ) == 1 )
			continue
		endif
		
		xwave = 1
		ywave = 1
		
		offset = StatsOffsetValue( winNum )
		
		if ( numtype( offset ) > 0 )
			offset = 0
		endif
		
		header = "WPrefix:" + currentPrefix
		header += "\rChanSelect:" + ChanNum2Char( chanNum )
		header += "\rWaveSelect:" + NMWaveSelectGet()
		
		statsnote = "\rStats Wave Names:" + wNames
		statsnote += "\rStats Win:" + num2istr( winNum ) + ";Stats Alg:" + select + ";"
		statsnote += "\rStats Tbgn:" + num2str( AmpB[ winNum ]+offset ) + ";Stats Tend:" + num2str( AmpE[ winNum ]+offset ) + ";"
		
		if ( BslnSubt[ winNum ] == 1 )
			statsnote += "\rStats Baselined:yes"
		else
			statsnote += "\rStats Baselined:no"
		endif
		
		if ( FilterNum[ winNum ] > 0 )
			statsnote += "\rFilter Alg:" + FilterAlg[ winNum ] + ";Filter Num:" + num2str( FilterNum[ winNum ] ) + ";"
		endif
		
		if ( dtFlag[ winNum ] > 0 )
			statsnote += "\rTransform:" + ChanFuncNum2Name( dtFlag[ winNum ] )
		endif
		
		yl = StatsYLabel( select )
		
		strswitch( select )
			case "RiseTime+":
			case "RiseTime-":
			case "DecayTime+":
			case "DecayTime-":
			case "FWHM+":
			case "FWHM-":
				ywave = 0
				break
			
		endswitch
		
		if ( ywave == 1 )
		
			wName = StatsWaveMake( folder, "AmpY", winNum, chanNum )
			NMNoteType( wName, "NMStats Yvalues", xl, yl, header + statsnote )
			wList = AddListItem( wName, wList, ";", inf )
			
			if ( winNum == currentWin )
				wNameDefault = GetPathName( wName, 0 )
			endif
			
		endif
		
		yl = xLabel
		
		xwave = 1
		setDefault = 0
		
		strswitch( select )
		
			case "Avg":
			case "SDev":
			case "Var":
			case "RMS":
			case "Area":
			case "Sum":
				xwave = 0
				break
				
			case "Slope":
				yl = yLabel // intercept value
				break
			
			case "Onset":
			case "Level":
			case "Level+":
			case "Level-":
				setDefault = 1
				break
			
			case "RiseTime+":
			case "RiseTime-":
			case "DecayTime+":
			case "DecayTime-":
			case "FWHM+":
			case "FWHM-":
				xwave = 0
				break
		endswitch
		
		if ( xwave == 1 )
		
			wName = StatsWaveMake( folder, "AmpX", winNum, chanNum )
			NMNoteType( wName, "NMStats Xvalues", xl, yl, header + statsnote )
			wList = AddListItem( wName, wList, ";", inf )
			
			if ( ( setDefault == 1 ) && ( winNum == currentWin ) )
				wNameDefault = GetPathName( wName, 0 )
			endif
			
		endif
		
		if ( StatsRiseTimeFlag( winNum ) == 1 )
		
			if ( StringMatch( select[ 0,3 ], "FWHM" ) == 1 )
				rf = "Fwhm"
			endif
		
			yl = num2str( RiseBP ) + " - " + num2str( RiseEP ) + "% " + rf + " Time ( " + xUnits + " )"

			wName = StatsWaveMake( folder, rf+"T", winNum, chanNum )
			wnote = "\r" + rf + " %bgn:" + num2str( RiseBP ) + ";" + rf + " %end:" + num2str( RiseEP ) + ";"
			NMNoteType( wName, "NMStats " + rf + " Time", xl, yl, header + statsnote + wnote )
			wList = AddListItem( wName, wList, ";", inf )
			
			if ( winNum == currentWin )
				wNameDefault = GetPathName( wName, 0 )
			endif
			
			yl = num2str( RiseBP ) + "% " + rf + " Pnt ( " + xUnits + " )"
			
			wName = StatsWaveMake( folder, rf+"BX", winNum, chanNum )
			wnote = "\rRise %bgn:" + num2str( RiseBP )
			NMNoteType( wName, "NMStats " + rf + " Tbgn", xl, yl, header + statsnote + wnote )
			wList = AddListItem( wName, wList, ";", inf )
			
			yl = num2str( RiseEP ) + "% " + rf + " Pnt ( " + xUnits + " )"
			
			wName = StatsWaveMake( folder, rf+"EX", winNum, chanNum )
			wnote = "\r" + rf + " %end:" + num2str( RiseBP )
			NMNoteType( wName, "NMStats " + rf + " Tend", xl, yl, header + statsnote + wnote )
			wList = AddListItem( wName, wList, ";", inf )
			
		endif
		
		if ( StatsDecayTimeFlag( winNum ) == 1 )
		
			yl = num2str( DcayP ) + "% Decay Time ( " + xUnits + " )"
		
			wName = StatsWaveMake( folder, "DcayT", winNum, chanNum )
			wnote = "\r%Decay:" + num2str( DcayP )
			NMNoteType( wName, "NMStats DecayTime", xl, yl, header + statsnote + wnote )
			wList = AddListItem( wName, wList, ";", inf )
			
			if ( winNum == currentWin )
				wNameDefault = GetPathName( wName, 0 )
			endif
			
			yl = num2str( DcayP ) + "% Decay Pnt ( " + xUnits + " )"
			
			wName = StatsWaveMake( folder, "DcayX", winNum, chanNum ) 
			wnote = "\r%Decay:" + num2str( DcayP )
			NMNoteType( wName, "NMStats DecayPoint", xl, yl, header + statsnote + wnote )
			wList = AddListItem( wName, wList, ";", inf )
			
		endif
		
		yl = StatsYLabel( BslnSlct[ winNum ] )
		
		if ( Bflag[ winNum ] == 1 )
			wName = StatsWaveMake( folder, "Bsln", winNum, chanNum )
			wnote = "\rBsln Alg:" + BslnSlct[ winNum ] + ";Bsln Tbgn:" + num2str( BslnB[ winNum ]+offset ) + ";Bsln Tend:" + num2str( BslnE[ winNum ]+offset ) + ";"
			NMNoteType( wName, "NMStats Bsln", xl, yl, header + statsnote + wnote )
			wList = AddListItem( wName, wList, ";", inf )
		endif
		
	endfor
	
	SetNMstr( folder+"DefaultStats2Wave", wNameDefault )
	
	return wList

End // StatsWavesMake

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsWaveNoteByKey( wName, keyName )
	String wName // wave name
	String keyName // e.g. "Alg" or "YLabel"
	
	String noteStr
	
	if ( strlen( wName ) == 0 )
		return ""
	endif
	
	if ( WaveExists( $wName ) == 0 )
		return NMErrorStr( 1, "NMStatsWaveNoteByKey", "wName", wName )
	endif
	
	strswitch( keyName )
	
		case "Win":
		case "Alg":
		case "Tbgn":
		case "Tend":
		case "Baselined":
		case "Offset Type":
		case "Offset Baseline":
			return NMNoteStrByKey( wName, "Stats " + keyName)
	
		case "Xdim": // OLD
		case "XLabel":
		
			noteStr = NMNoteStrByKey( wName, "XLabel" )
			
			if ( strlen( noteStr ) == 0 )
				noteStr = NMNoteStrByKey( wName, "Xdim" )
			endif
	
			return noteStr
	
		case "Ydim": // OLD
		case "YLabel":
		
			noteStr = NMNoteStrByKey( wName, "YLabel" )
			
			if ( strlen( noteStr ) == 0 )
				noteStr = NMNoteStrByKey( wName, "Ydim" )
			endif
	
			return noteStr
		
		case "F(t)": // OLD
		case "Transform":
		
			noteStr = NMNoteStrByKey( wName, "Transform" )
			
			if ( strlen( noteStr ) == 0 )
				noteStr = NMNoteStrByKey( wName, "F(t)" )
			endif
	
			return noteStr
			
		case "Smooth Alg": // OLD
		case "Filter Alg":
		
			noteStr = NMNoteStrByKey( wName, "Filter Alg" )
			
			if ( strlen( noteStr ) == 0 )
				noteStr = NMNoteStrByKey( wName, "Smooth Alg" )
			endif
	
			return noteStr
			
		case "Smooth Num": // OLD
		case "Filter Num":
		
			noteStr = NMNoteStrByKey( wName, "Filter Num" )
			
			if ( strlen( noteStr ) == 0 )
				noteStr = NMNoteStrByKey( wName, "Smooth Num" )
			endif
	
			return noteStr
	
	endswitch
	
	return ""
	
End // NMStatsWaveNoteByKey

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWaveMake( folder, fxn, win, chanNum ) // create appropriate stats wave
	String folder
	String fxn
	Variable win // Stats window number
	Variable chanNum // channel number
	
	String wName = StatsWaveName( folder, win, fxn, chanNum, NeuroMaticVar( "OverWrite" ), 1 )
	
	if ( strlen( wName ) > 0 )
		Make /O/N=( NMNumWaves() ) $wName = NaN
	endif
	
	return wName

End // StatsWaveMake

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsWaveNameForWName( folder, chanNum, fullPath )
	String folder
	Variable chanNum // channel number
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname

	return StatsWaveName( folder, Nan, "wName_", chanNum, NeuroMaticVar( "OverWrite" ), fullPath )
	
End // NMStatsWaveNameForWName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsWaveNameForWNameFind( statsWaveName )
	String statsWaveName // e.g. "ST_MaxY0_RAll_A0"
	
	Variable icnt
	String folder, wList, wName, wName2
	
	wName = NMNoteStrByKey( statsWaveName, "Stats Wave Names" )
	
	if ( strlen( wName ) > 0 )
		return wName
	endif

	folder = GetPathName( statsWaveName, 1 )
	wList = NMFolderWaveList( folder, "ST_wName_*", ";", "TEXT:1", 0 )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		wName2 = ReplaceString( "ST_wName_", wName, "" )
		
		if ( strsearch( statsWaveName, wName2, 0, 2 ) > 0 )
			return folder + wName // found the corresponding text wave ( e.g. "ST_wName_RAll_A0" )
		endif
		
	endfor
	
	return ""
		
End // NMStatsWaveNameForWNameFind

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWaveName( folder, win, fxn, chanNum, overWrite, fullPath )
	String folder
	Variable win // Stats window number
	String fxn
	Variable chanNum // channel number
	Variable overWrite
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname
	
	String wavePrefix, winStr = "", slctStr = ""
	
	if ( numtype( win ) == 0 )
		winStr = num2istr( win ) + "_"
	endif
	
	strswitch( fxn )
		case "AmpX":
			fxn = StatsAmpName( win ) + "X"
			break
		case "AmpY":
			fxn = StatsAmpName( win )+ "Y"
			break
	endswitch
	
	slctStr = NMWaveSelectStr() + "_"
	
	wavePrefix = "ST_" + fxn + winStr + slctStr
	
	if ( fullPath == 1 )
		return folder + NextWaveName2( folder, wavePrefix, chanNum, overWrite )
	else
		return NextWaveName2( folder, wavePrefix, chanNum, overWrite )
	endif

End // StatsWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsAmpName( win )
	Variable win // Stats window number
	
	String fxn = StatsAmpSelectGet( win )
	
	strswitch( fxn )
		case "RiseTime+":
		case "RiseTime-":
			return "RiseT"
		case "DecayTime+":
		case "DecayTime-":
			return "DcayT"
		case "Level":
		case "Level+":
		case "Level-":
			return "Lev"
		case "Slope":
			return "Slp"
		case "RTslope+":
		case "RTslope-":
			return "RTslp"
		case "FWHM+":
		case "FWHM-":
			return "Fwhm"
		case "Off":
			return ""
	endswitch
	
	if ( StringMatch( fxn[0,5], "MaxAvg" ) == 1 )
		fxn = "MaxAvg"
	endif
	
	if ( StringMatch( fxn[0,5], "MinAvg" ) == 1 )
		fxn = "MinAvg"
	endif
	
	fxn = ReplaceString( ".", fxn, "p" )
	fxn = ReplaceString( "+", fxn, "p" )
	fxn = ReplaceString( "-", fxn, "n" )
	fxn = ReplaceString( " ", fxn, "" )
	
	return fxn

End // StatsAmpName

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmpSave( folder, chanNum, waveNum, win, option ) // save, clear or delete results to appropriate Stat waves
	String folder
	Variable chanNum // channel number
	Variable waveNum
	Variable win // Stats window number
	Variable option // clear option ( 0 - save; 1 - clear; 2 - delete )
	
	Variable clear = 1
	
	String wName, select, rf = "Rise"
	String df = StatsDF()
	
	String wselect = NMWaveSelectGet()
	
	Wave AmpY = $df+"AmpY"
	Wave AmpX = $df+"AmpX"
	
	Wave BslnY = $df+"BslnY"
	Wave Bflag = $df+"Bflag"
	
	Wave RiseBX = $df+"RiseBX"
	Wave RiseEX = $df+"RiseEX"
	Wave RiseTm = $df+"RiseTm"
	Wave DcayX = $df+"DcayX"
	Wave DcayT = $df+"DcayT"
	
	select = StatsAmpSelectGet( win )
	
	if ( StringMatch( select, "Off" ) == 1 )
		return 0
	endif
	
	win = CheckNMStatsWin( "StatsAmpSave", win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( option == 1 )
		clear = Nan
	else
		clear = 1
	endif
	
	wName = StatsWaveName( folder, win, "AmpY", chanNum, 1, 1 )
	StatsAmpSave2( wName, waveNum, AmpY[ win ], option )
	
	wName = StatsWaveName( folder, win, "AmpX", chanNum, 1, 1 )
	StatsAmpSave2( wName, waveNum, AmpX[ win ], option )

	if ( Bflag[ win ] == 1 )
		wName = StatsWaveName( folder, win, "Bsln", chanNum, 1, 1 )
		StatsAmpSave2( wName, waveNum, BslnY[ win ], option )
	endif
		
	if ( StatsRiseTimeFlag( win ) == 1 )
	
		if ( StringMatch( select[ 0,3 ], "FWHM" ) == 1 )
			rf = "Fwhm"
		endif
	
		wName = StatsWaveName( folder, win, rf + "BX", chanNum, 1, 1 )
		StatsAmpSave2( wName, waveNum, RiseBX[ win ], option )
		
		wName = StatsWaveName( folder, win, rf + "EX", chanNum, 1, 1 )
		StatsAmpSave2( wName, waveNum, RiseEX[ win ], option )
		
		wName = StatsWaveName( folder, win, rf + "T", chanNum, 1, 1 )
		StatsAmpSave2( wName, waveNum, RiseTm[ win ], option )
		
	endif
		
	if ( StatsDecayTimeFlag( win ) == 1 )
	
		wName = StatsWaveName( folder, win, "DcayX", chanNum, 1, 1 )
		StatsAmpSave2( wName, waveNum, DcayX[ win ], option )
		
		wName = StatsWaveName( folder, win, "DcayT", chanNum, 1, 1 )
		StatsAmpSave2( wName, waveNum, DcayT[ win ], option )
		
	endif

End // StatsAmpSave

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAmpSave2( wName, waveNum, value, option )
	String wName // wave name
	Variable waveNum
	Variable value
	Variable option // clear option ( 0 - save; 1 - clear; 2 - delete )
	
	Variable clear = 1
	
	if ( option == 1 )
		clear = Nan
	endif
	
	if ( WaveExists( $wName ) == 1 )
	
		if ( option == 2 ) // delete
		
			if ( waveNum < numpnts( $wName ) )
			
				DeletePoints waveNum, 1, $wName
				
				return 0
			
			endif
			
		else // save or clear
	
			Wave wtemp = $wName
			
			wtemp[ waveNum ] = value * clear
			
			return 0
		
		endif
		
	endif
	
	return -1
	
End // StatsAmpSave2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsYLabel( select )
	String select
	
	String currentWaveName = CurrentNMWaveName()
	
	String yl = NMChanLabel( -1, "y", currentWaveName )
	String xl = NMChanLabel( -1, "x", currentWaveName )
	
	String yunits = UnitsFromStr( yl )
	String xunits = UnitsFromStr( xl )
	
	strswitch( select )
		case "SDev":
			return "Stdv ( " + yunits + " )"
		case "Var":
			return "Variance ( " + yunits + "^2 )"
		case "RMS":
			return "RMS ( " + yunits + " )"
		case "Area":
			return "Area ( " + yunits + " * " + xunits + " )"
		case "Sum":
			return "Sum ( " + yunits + " * " + xunits + " )"
		case "Slope":
			return "Slope ( " + yunits + " / " + xunits + " )"
	endswitch
	
	return yl
	
End // StatsYLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsWaveTypeXY( wName )
	String wName // wave name
	
	String wtype
	
	wName = CheckNMStatsWavePath( wName )
	
	if ( WaveExists( $wName ) == 0 )
		return NMErrorStr( 1, "NMStatsWaveTypeXY", "wName", wName )
	endif

	wtype = NMNoteStrByKey( wName, "Type" )
	
	strswitch( wtype )
	
		case "NMStats Xvalues":
		case "NMStats Rise Tbgn":
		case "NMStats Rise Tend":
		case "NMStats FWHM Tbgn":
		case "NMStats FWHM Tend":
		case "NMStats DecayPoint":
			return "X"
	
	endswitch
	
	return "Y"
	
End // NMStatsWaveTypeXY

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinNum( wName ) // return the amplitude/window number, given wave name
	String wName // wave name
	
	Variable win, icnt, ibgn, iend
	String winStr
	
	if ( strlen( wName ) == 0 )
		return -1
	endif
	
	winStr = NMNoteStrByKey( wName, "Stats Win" )
	
	win = str2num( winStr )
	
	if ( ( strlen( winStr ) > 0 ) && ( numtype( win ) == 0 ) && ( win >= 0 ) )
		return win
	endif
	
	if ( ( StringMatch( wName[ 0,2 ], "ST_" ) == 0 ) && ( StringMatch( wName[ 0,2 ], "ST2_" ) == 0 ) )
		return -1 // not a Stats wave
	endif
	
	iend = strsearch( wName, "_", 4 ) - 1
	
	if ( iend < 0 )
		return -1
	endif
	
	if ( StringMatch( wName[ 0,6 ], "ST_Bsln" ) == 1 ) // baseline wave
	
		ibgn = 7
		
	else
	
		for ( icnt = iend - 1; icnt >= iend - 3; icnt -= 1 )
			if ( ( StringMatch( wName[ icnt, icnt ], "X" ) == 1 ) || ( StringMatch( wName[ icnt, icnt ], "Y" ) == 1 ) || ( StringMatch( wName[ icnt, icnt ], "T" ) == 1 ) )
				ibgn = icnt + 1
				break
			endif
		endfor
	
	endif
	
	win = str2num( wName[ ibgn, iend ] )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( win >= 0 )
		return win
	else
		return -1
	endif
	
End // StatsWinNum

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Stats Sub-Folder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsSubfolderPrefix()

	return "Stats_"

End // NMStatsSubfolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMStatsSubfolder()

	return NMStatsSubfolder( CurrentNMWavePrefix(), CurrentNMChannel() )
	
End // CurrentNMStatsSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsSubfolder( wavePrefix, chanNum )
	String wavePrefix
	Variable chanNum // channel number
	
	if ( NMStatsVar( "UseSubfolders" ) == 0 )
		return ""
	endif
	
	if ( strlen( wavePrefix ) ==0 )
		wavePrefix = CurrentNMWavePrefix()
	endif
	
	return NMSubfolder( NMStatsSubfolderPrefix(), wavePrefix, chanNum, NMWaveSelectShort() )

End // NMStatsSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMStatsSubfolder( subfolder )
	String subfolder // ( "" ) for current
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMStatsSubfolder()
	endif
	
	return CheckNMSubfolder( subfolder )
	
End // CheckNMStatsSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsSubfolderList( parentFolder, fullPath, restrictToCurrentPrefix )
	String parentFolder // ( "" ) for current data folder
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname
	Variable restrictToCurrentPrefix
	
	Variable icnt
	String folderName, tempList = ""
	
	String currentPrefix = CurrentNMWavePrefix()
	
	String folderList = NMSubfolderList( NMStatsSubfolderPrefix(), parentFolder, fullPath )
	
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

End // NMStatsSubfolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsSubfolderTable( subfolder )
	String subfolder
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMStatsSubfolder()
	endif
	
	return NMSubfolderTable( subfolder, "ST_" )
	
End // NMStatsSubfolderTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStatsSubfolderClear( subfolder )
	String subfolder
	
	String failureList
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMStatsSubfolder()
	endif
	
	return NMSubfolderClear( subfolder )

End // NMStatsSubfolderClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStatsSubfolderKill( subfolder )
	String subfolder
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMStatsSubfolder()
	endif
	
	return NMSubfolderKill( subfolder )

End // NMStatsSubfolderKill

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Stats2 Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2Call( fxn, select )
	String fxn
	String select
	
	String errorStr
	
	strswitch( fxn )
	
		case "2FolderSelect":
			errorStr = NMStats2WaveSelectCall( select, "" )
			break
			
		case "2WaveSelect":
			errorStr = NMStats2WaveSelectCall( "_selected_", select )
			break
			
		case "Plot":
			return NMStats2PlotCall()
			
		case "Edit":
			return NMStats2EditCall()
			
		case "Print Note":
			return NMStats2PrintNoteCall()
			
		case "Print Name":
			return NMStats2PrintName( "_selected_" )
			
		case "Print Stats":
			NMStats2WaveStats( "_selected_", 1 )
			return ""
			
		case "Histogram":
			return NMStats2HistogramCall( "" )
			
		case "Sort Wave":
			return NMStats2SortWaveCall()
			
		case "Stability":
		case "Stationarity":
			return NMStats2StabilityCall()
			
		case "Significant Difference":
			return NMStats2SigDiffCall()
			
		case "Use For Wave Scaling":
			return NMStats2WaveScaleCall()
			
		case "Use For Wave Alignment":
			return NMStats2WaveAlignmentCall()
	
		case "Delete Stats Subfolder":
			return NMStats2FolderKillCall()
			
		case "Clear Stats Subfolder":
			return NMStats2FolderClearCall()

		case "Stats Table All":
			return NMStats2WaveStatsTableCall()
			
		case "Edit All":
			return NMStats2EditAllCall()
			
		case "Print Stats All":
			return NMStats2WaveStatsPrintCall()
			
		case "Print Notes All":
			return NMStats2PrintNotesCall()
			
		case "Print Names All":
			return NMStats2PrintNamesCall()
			
		default:
			return NMErrorStr( 20, "NMStats2Call", "fxn", fxn )
			
	endswitch

End // NMStats2Call

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2FolderList( restrictToCurrentPrefix )
	Variable restrictToCurrentPrefix
	
	String folderList = AddListItem( CurrentNMFolder( 0 ), "", ";", inf )
	
	String statsFolderList = NMStatsSubfolderList( GetDataFolder( 1 ), 0, restrictToCurrentPrefix )
	String spikeFolderList = NMSpikeSubfolderList( GetDataFolder( 1 ), 0, restrictToCurrentPrefix )
	String eventFolderList = NMEventSubfolderList( GetDataFolder( 1 ), 0, restrictToCurrentPrefix )
	String fitFolderList = NMFitSubfolderList( GetDataFolder( 1 ), 0, restrictToCurrentPrefix )

	return folderList + statsFolderList + spikeFolderList + eventFolderList + fitFolderList

End // NMStats2FolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMStats2FolderWaveSelect()

	String wList, wName = ""

	String folder = StrVarOrDefault( "CurrentStats2Folder", "" )
	String folderList = NMStats2FolderList( 1 )
	
	if ( ( strlen( folder ) == 0 ) || ( WhichListItem( folder, folderList ) < 0 ) )
		folder = StringFromList( 0, folderList )
		SetNMstr( "CurrentStats2Folder", folder )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		folder = ""
		SetNMstr( "CurrentStats2Folder", "" )
	endif
	
	wList = NMStats2WaveSelectList( 0 )
	
	if ( ItemsInList( wList ) > 0 )
	
		wName = StrVarOrDefault( folder +"CurrentStats2Wave", "" )
		
		if ( ( strlen( wName ) > 0 ) && ( WhichListItem( wName, wList ) >= 0 ) )
			return wName // current selection is OK
		endif
		
		wName = StrVarOrDefault( folder +"DefaultStats2Wave", "" )
		
		if ( ( strlen( wName ) == 0 ) || ( WhichListItem( wName, wList ) < 0 ) )
			wName = StringFromList( 0, wList )
		endif
		
	endif
	
	SetNMstr( folder +"CurrentStats2Wave", wName )
	
	return wName

End // CheckNMStats2FolderWaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMStats2FolderSelect( fullPath )
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname

	String folder = StrVarOrDefault( "CurrentStats2Folder", "" )
	
	if ( StringMatch( folder, CurrentNMFolder( 0 ) ) == 1 )
		return CurrentNMFolder( fullPath )
	endif
	
	if ( ( strlen( folder ) == 0 ) || ( DataFolderExists( folder ) == 0 ) )
		return ""
	endif
	
	if ( fullPath == 1 )
		return CurrentNMFolder( 1 ) + folder + ":"
	else
		return folder
	endif

End // CurrentNMStats2FolderSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMStats2WaveSelect( fullPath )
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname
	
	String wName
	
	String folder = CurrentNMStats2FolderSelect( 1 )
	
	wName = StrVarOrDefault( folder+"CurrentStats2Wave", "" )
	
	if ( ( strlen( wName ) > 0 ) && ( WaveExists( $folder+wName ) == 1 ) )
	
		if ( fullPath == 1 )
			return folder + wName
		else
			return wName
		endif
	
	endif
	
	return ""

End // CurrentNMStats2WaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveSelectCall( folder, wName )
	String folder
	String wName // wave name
	
	String vlist = ""
	
	vlist = NMCmdStr( folder, vlist )
	vlist = NMCmdStr( wName, vlist )
	NMCmdHistory( "NMStats2WaveSelect", vlist )
	
	return NMStats2WaveSelect( folder, wName )

End // NMStats2WaveSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveSelect( folder, wName )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Stats2 folder
	String wName // wave name, ( "" ) for default wave selection
	
	String thisfxn = "NMStats2WaveSelect"
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	if ( ( strlen( wName ) > 0 ) && ( WaveExists( $folder+wName ) == 0 ) )
		return NMErrorStr( 1, thisfxn, "wName", wName )
	endif
	
	SetNMstr( "CurrentStats2Folder", GetPathName( folder, 0 ) )
	SetNMstr( folder+"CurrentStats2Wave", wName )
	
	UpdateStats2()
	
	return folder + wName

End // NMStats2WaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveSelectList( fullPath )
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname

	Variable icnt, wnum, removeMore
	String numstr, wName, removeList = "", wList = "", wList2 = ""
	
	String folder = CurrentNMStats2FolderSelect( 1 )
	
	String filter = StrVarOrDefault( folder+"WaveListFilter", "Stats1" )
	
	removeList = NMFolderWaveList( folder, "*Offset*", ";", "Text:0", fullPath )
	
	if ( StringMatch( filter, "All Stats" ) == 1 )
	
		wList = NMFolderWaveList( folder, "ST_*", ";", "Text:0", fullPath ) 
		wList += NMFolderWaveList( folder, "ST2_*", ";", "Text:0", fullPath )
		
	elseif ( StringMatch( filter, "Stats1" ) == 1 )
	
		wList = NMFolderWaveList( folder, "ST_*", ";", "Text:0", fullPath )
		removeMore = 1
	
	elseif ( StringMatch( filter, "Stats2" ) == 1 )
	
		wList = NMFolderWaveList( folder, "ST2_*", ";", "Text:0", fullPath )
		wList += NMFolderWaveList( folder, "ST_*Hist*", ";", "Text:0", fullPath )
		wList += NMFolderWaveList( folder, "ST_*Sort*", ";", "Text:0", fullPath )
		wList += NMFolderWaveList( folder, "ST_*Stb*", ";", "Text:0", fullPath )
		wList += NMFolderWaveList( folder, "ST_*Stable*", ";", "Text:0", fullPath )
		
	elseif ( StringMatch( filter, "Any" ) == 1 )
	
		wList = NMFolderWaveList( folder, "*", ";", "Text:0", fullPath )
		
	elseif ( StringMatch( filter[ 0, 2 ], "Win" ) == 1 )
		
		removeMore = 1
		wnum = str2num( filter[ 3,inf ] )
		
		if ( numtype( wnum ) > 0 )
			return "" // error
		endif
		
		wList = NMFolderWaveList( folder, "ST_*", ";", "Text:0", fullPath )
	
		numstr = num2istr( wnum ) + "_*"
		
		for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
		
			wName = StringFromList( icnt, wList )
			
			if ( StringMatch( wName, "*ST_Bsln"+numstr ) == 1 )
				wList2 = AddListItem( wName, wList2, ";", inf )
			elseif ( StringMatch( wName, "*ST_*X"+numstr ) == 1 )
				wList2 = AddListItem( wName, wList2, ";", inf )
			elseif ( StringMatch( wName, "*ST_*Y"+numstr ) == 1 )
				wList2 = AddListItem( wName, wList2, ";", inf )
			elseif ( StringMatch( wName, "*ST_RiseT"+numstr ) == 1 )
				wList2 = AddListItem( wName, wList2, ";", inf )
			elseif ( StringMatch( wName, "*ST_DcayT"+numstr ) == 1 )
				wList2 = AddListItem( wName, wList2, ";", inf )
			endif
			
		endfor
		
		wList = wList2
		
	else // user-defined "Other"
	
		wList = NMFolderWaveList( folder, filter, ";", "Text:0", fullPath )
	
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	if ( removeMore == 1 )
		removeList += NMFolderWaveList( folder, "ST_*Hist*", ";", "Text:0", fullPath )
		removeList += NMFolderWaveList( folder, "ST_*Sort*", ";", "Text:0", fullPath )
		removeList += NMFolderWaveList( folder, "ST_*Stb*", ";", "Text:0", fullPath )
		removeList += NMFolderWaveList( folder, "ST_*Stable*", ";", "Text:0", fullPath )
	endif
	
	wList = RemoveFromList( removeList, wList, ";" )
	
	return wList
	
End // NMStats2WaveSelectList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveSelectFilterCall()

	String folder = CurrentNMStats2FolderSelect( 1 )
	String filter = StrVarOrDefault( folder+"WaveListFilter", "Stats1" )
	String matchList = "All Stats;Stats1;Stats2;" + NMStatsWinList( 1, "Win" ) + "Any;Other;"
	
	if ( WhichListItem( filter, matchList ) < 0 )
		filter = "Stats1"
	endif
	
	Prompt filter, " ", popup matchList
	DoPrompt "Stats2 Wave List Filter", filter
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( StringMatch( filter, "Other" ) == 1 )
	
		filter = "ST_*"
		
		Prompt filter, "enter a wave list match string:"
		DoPrompt "Stats2 Wave List Match String", filter
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( strsearch( filter, "*", 0 ) < 0 )
			NMDoAlert( "Warning: your match string does not contain a star character " + NMQuotes( "*" ) )
		endif
			
	endif
	
	NMCmdHistory( "NMStats2WaveSelectFilter", NMCmdStr( filter, "" ) )
	
	return NMStats2WaveSelectFilter( filter )

End // NMStats2WaveSelectFilterCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveSelectFilter( filter )
	String filter // "All Stats" or "Stats1" or "Stats2" or "Any" or "Win0" or "Win1" or "ST_*"
	
	String wList, wName = ""
	String folder = CurrentNMStats2FolderSelect( 1 )
	
	if ( strlen( filter ) == 0 )
		filter = "Stats1"
	endif
	
	SetNMstr( folder+"WaveListFilter", filter )
	
	UpdateStats2()
	
	return filter
	
End // NMStats2WaveSelectFilter

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStats2WaveStats( wName, printToHistory ) // compute AVG, SDV and SEM
	String wName // wave name, ( "_selected_" ) for current Stats2 wave selection
	Variable printToHistory

	Variable cnt = Nan, avg = Nan, sdv = Nan, sem = Nan, vmin = Nan, vmax = Nan
	
	wName = CheckNMStatsWavePath( wName )
	
	if ( WaveExists( $wName ) == 1 )
	
		if ( printToHistory == 1 )
			Print "\rWaveStats " + wName
			WaveStats /Z $wName
		else
			WaveStats /Q/Z $wName
		endif
		
		if ( V_npnts > 0 )
			cnt = V_npnts
			avg = V_avg
			sdv = V_sdev
			sem = V_sdev / sqrt( V_npnts )
			vmin = V_min
			vmax = V_max
		endif
		
	endif
	
	SetNMStatsVar( "ST_2CNT", cnt )
	SetNMStatsVar( "ST_2AVG", avg )
	SetNMStatsVar( "ST_2SDV", sdv )
	SetNMStatsVar( "ST_2SEM", sem )
	
	SetNMStatsVar( "ST_2Min", vmin )
	SetNMStatsVar( "ST_2Max", vmax )
	
	return 0

End // NMStats2WaveStats

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2PlotCall()

	Variable npnts
	String optionStr = "", vList = "" 

	String folder = CurrentNMStats2FolderSelect( 1 )
	String fSelect = " "
	String folderList = NMStats2FolderList( 0 )
	
	String waveNameY = CurrentNMStats2WaveSelect( 1 )
	String ySelect = GetPathName( waveNameY, 0 )
	String yList = NMStats2WaveSelectList( 0 )
	
	String waveNameX = "_calculated_"
	String xSelect = waveNameX
	String xList = yList
	
	if ( WaveExists( $waveNameY ) == 1 )
		npnts = numpnts( $waveNameY )
		optionStr = NMWaveListOptions( npnts, 0 )
	endif
	
	xList = NMFolderWaveList( folder, "*", ";", optionStr, 0 )
	
	folderList = RemoveFromList( GetPathName( folder, 0 ), folderList )
	
	Prompt ySelect, "choose y-axis wave:", popup yList
	Prompt xSelect, "choose x-axis wave:", popup "_calculated_;" + xList
	Prompt fSelect, "or choose a folder to locate x-axis wave:", popup " ;" + folderList
	
	DoPrompt "Plot Stats Wave", ySelect, xSelect, fSelect
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( WaveExists( $folder+ySelect ) == 0 )
		return "" // something went wrong
	endif
	
	if ( StringMatch( xSelect, "_calculated_" ) == 0 )
		xSelect = GetPathName( folder, 0 ) + ":" + xSelect // short notation
	endif
	
	if ( StringMatch( fSelect, " " ) == 0 ) // folder has been selected
	
		fSelect = CheckNMStatsFolderPath( fSelect )
	
		npnts = numpnts( $folder+ySelect )
		optionStr = NMWaveListOptions( npnts, 0 )
	
		xList = NMFolderWaveList( fSelect, "*", ";", optionStr, 0 ) // look for waves of same dimension as ySelect
		
		waveNameX = "_calculated_"
		
		Prompt xSelect, "choose x-axis wave:", popup "_calculated_;" + xList
		DoPrompt "Plot Stats Wave", xSelect
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( StringMatch( fSelect, GetDataFolder( 1 ) ) == 1 )
			fSelect = ""
		endif
		
		if ( StringMatch( xSelect, "_calculated_" ) == 0 )
			
			if ( strlen( fSelect ) > 0 )
				xSelect = GetPathName( fSelect, 0 ) + ":" + xSelect // short notation
			endif
		endif
	
	endif
	
	if ( StringMatch( GetPathName( waveNameY, 0 ), ySelect ) == 1 )
		ySelect = "_selected_"
	else
		ySelect = GetPathName( folder, 0 ) + ":" + ySelect
	endif
	
	vlist = NMCmdStr( ySelect, vlist )
	vlist = NMCmdStr( xSelect, vlist )
	NMCmdHistory( "NMStats2Plot", vlist )
	
	return NMStats2Plot( ySelect, xSelect )
	
End // NMStats2PlotCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2Plot( waveNameY, waveNameX )
	String waveNameY // y-wave name, ( "_selected_" ) for current Stats2 wave select
	String waveNameX // x-axis wave name ( "" or "_calculated_" ) for none, use y-wave x-scaling
	
	Variable tbgn, tend
	String alg = "", txt = "", thisfxn = "NMStats2Plot"
	
	waveNameY = CheckNMStatsWavePath( waveNameY )
	
	if ( StringMatch( waveNameX, "_calculated_" ) == 1 )
		waveNameX = ""
	endif
	
	if ( strlen( waveNameX ) > 0 )
		waveNameX = CheckNMStatsWavePath( waveNameX )
	endif
	
	if ( ( WaveExists( $waveNameY ) == 0 ) || ( WaveType( $waveNameY ) == 0 ) )
		return NMErrorStr( 1, thisfxn, "waveNameY", waveNameY )
	endif
	
	if ( strlen( waveNameX ) > 0 )
		if ( ( WaveExists( $waveNameX ) == 0 ) || ( WaveType( $waveNameX ) == 0 ) )
			return NMErrorStr( 1, thisfxn, "waveNameX", waveNameX )
		endif
	endif
	
	String pName = GetPathName( waveNameY, 0 )
	String gTitle = NMFolderListName( "" ) + " : " + pName
	String gName = pName + "_" + NMFolderPrefix( "" ) + "Plot"
	
	String type = NMNoteStrByKey( waveNameY, "Type" )
	String transform = NMStatsWaveNoteByKey( waveNameY, "Transform" )
	
	String filterA = NMStatsWaveNoteByKey( waveNameY, "Filter Alg" )
	Variable filterN = str2num( NMStatsWaveNoteByKey( waveNameY, "Filter Num" ) )
	
	String xLabel = NMStatsWaveNoteByKey( waveNameY, "XLabel" )
	String yLabel = NMStatsWaveNoteByKey( waveNameY, "YLabel" )
	
	if ( strlen( xLabel ) == 0 )
		xLabel = "Wave #"
	endif
	
	if ( strlen( yLabel ) == 0 )
		yLabel = GetPathName( waveNameY, 0 )
	endif
	
	strswitch( type )
	
		default:
			alg = NMNoteStrByKey( waveNameY, "Stats Alg" )
			tbgn = NMNoteVarByKey( waveNameY, "Stats Tbgn" )
			tend = NMNoteVarByKey( waveNameY, "Stats Tend" )
			break
			
		case "NMStats Bsln":
			alg = "Bsln " + NMNoteStrByKey( waveNameY, "Bsln Alg" )
			tbgn = NMNoteVarByKey( waveNameY, "Bsln Tbgn" )
			tend = NMNoteVarByKey( waveNameY, "Bsln Tend" )
			break
			
	endswitch
	
	txt = alg + " ( "
	
	txt += num2str( tbgn ) + " to " + num2str( tend ) + " ms"
	
	if ( strlen( transform ) > 0 )
		txt += ";" + transform
	endif
	
	if ( strlen( filterA ) > 0 )
		txt += ";" + filterA + ",N=" + num2istr( filterN )
	endif
	
	txt += " )"
	
	DoWindow /K $gName
	
	if ( ( strlen( waveNameX ) > 0 ) && ( WaveExists( $waveNameX ) == 1 ) )
	
		gTitle += " vs " + GetPathName( waveNameX, 0 )
		xLabel = NMStatsWaveNoteByKey( waveNameX, "YLabel" )
		
		Display /K=1/N=$gName/W=( 0,0,0,0 ) $waveNameY vs $waveNameX as gTitle
		Label bottom xLabel
		
	else
	
		Display /K=1/N=$gName/W=( 0,0,0,0 ) $waveNameY as gTitle
		Label bottom xLabel
		
	endif
	
	if ( WinType( gName ) == 0 )
		return ""
	endif
	
	SetCascadeXY( gName )
	
	DoWindow /F $gName
	
	Label left yLabel
	ModifyGraph mode=4,marker=19, standoff=0, rgb=( 0,0,0 )
	
	if ( strlen( txt ) > 3 )
		TextBox /C/N=stats2title/F=2/E=1/A=MT txt
	endif
	
	return gName

End // NMStats2Plot

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2EditCall()

	String vlist = ""
	String folder = CurrentNMStats2FolderSelect( 1 )
	String wList = NMStats2WaveSelectList( 0 )
	String wName = CurrentNMStats2WaveSelect( 0 )
	String wSelect = wName
	
	Prompt wSelect, "choose wave:", popup wList
	
	Variable doWavePrompt = 0
	
	if ( doWavePrompt && ItemsInList( wList ) > 1 )
	
		DoPrompt "Edit Stats Wave", wSelect
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	endif
	
	if ( StringMatch( wName, wSelect ) == 1 )
		wSelect = "_selected_"
	else
		wSelect = GetPathName( folder, 0 ) + ":" + wSelect
	endif
	
	vlist = NMCmdStr( wSelect, vlist )
	NMCmdHistory( "NMStats2Edit", vlist )
	
	return NMStats2Edit( wSelect )
	
End // NMStats2EditCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2Edit( wName )
	String wName // wave name, ( "_selected_" ) for current Stats2 wave select
	
	wName = CheckNMStatsWavePath( wName )
	
	if ( WaveExists( $wName ) == 0 )
		return NMErrorStr( 1, "NMStats2Edit", "wName", wName )
	endif
	
	String pName = GetPathName( wName, 0 )
	String title = NMFolderListName( "" ) + " : " + pName
	String tName = pName + "_" + NMFolderPrefix( "" ) + "Table"
	
	if ( WinType( tName ) == 0 )
		Edit /K=1/N=$tName/W=( 0,0,0,0 ) $wName as title
		SetCascadeXY( tName )
	endif
	
	return tName

End // NMStats2Edit

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2PrintNoteCall()

	String wName = "_selected_"

	NMCmdHistory( "NMStats2PrintNote", NMCmdStr( wName, "" ) )
	
	return NMStats2PrintNote( wName )
	
End // NMStats2PrintNoteCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2PrintNote( wName )
	String wName // wave name, ( "_selected_" ) for current Stats2 wave select
	
	wName = CheckNMStatsWavePath( wName )
	
	if ( WaveExists( $wName ) == 0 )
		return NMErrorStr( 1, "NMStats2PrintNote", "wName", wName )
	endif
	
	NMHistory( "\r" + GetPathName( wName, 0 ) + " Notes:\r" + note( $wName ) )
	
	return wName
	
End // NMStats2PrintNote

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2PrintName( wName )
	String wName // wave name, ( "_selected_" ) for current Stats2 wave select
	
	wName = CheckNMStatsWavePath( wName )
	
	if ( WaveExists( $wName ) == 0 )
		return NMErrorStr( 1, "NMStats2PrintName", "wName", wName )
	endif
	
	NMHistory( "\r" + wName )
	
	return wName
	
End // NMStats2PrintName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2HistogramCall( wName )
	String wName // wave name, ( "" ) for prompt

	Variable range, wavePrompt
	
	String wSelect, vlist = ""
	String wList = NMStats2WaveSelectList( 0 )
	String folder = CurrentNMStats2FolderSelect( 1 )
	
	Variable binsize = NMStatsVar( "HistoBinSize" )
	
	if ( strlen( wName ) == 0 )
		wName = CurrentNMStats2WaveSelect( 1 )
		wavePrompt = 1
	endif
	
	if ( WaveExists( $wName ) == 0 )
		wName = " "
		wavePrompt = 1
	endif
	
	if ( ( WaveExists( $wName ) == 1 ) && ( numtype( binsize ) > 0 ) )
	
		Wavestats /Q/Z $wName
		
		range = abs( V_max - V_min )
		
		if ( range > 100 )
			binsize = 10
		elseif ( range > 10 )
			binsize = 1
		elseif ( range > 1 )
			binsize = 0.1
		elseif ( range > 0.1 )
			binsize = 0.01
		else
			binsize = 0.001
		endif
		
	endif
	
	Prompt binsize, "enter bin size:"
	
	if ( wavePrompt == 1 )
	
		wName = GetPathName( wName, 0 )
		wSelect = wName
	
		Prompt wSelect, "choose wave:", popup " ;" + wList
		DoPrompt "Stats Histogram", wSelect, binsize
		
		if ( StringMatch( wName, wSelect ) == 1 )
			wSelect = "_selected_"
		else
			wSelect = GetPathName( folder, 0 ) + ":" + wSelect
		endif
		
	else
	
		wSelect = wName
	
		DoPrompt "Stats Histogram", binsize
		
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif

	SetNMStatsVar( "HistoBinSize", binsize )
	
	vlist = NMCmdStr( wSelect, vlist )
	vlist = NMCmdNum( binsize, vlist )
	NMCmdHistory( "NMStats2Histogram", vlist )
	
	return NMStats2Histogram( wSelect, binsize )
	
End // NMStats2HistogramCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2Histogram( wName, binsize )
	String wName // wave name, ( "_selected_" ) for current Stats2 wave select
	Variable binsize // histogram bin size
	
	Variable range, npnts, vmin
	String xl, yl, dName, gName, gTitle, folder, pName, thisfxn = "NMStats2Histogram"
	
	Variable overWrite = NeuroMaticVar( "OverWrite" )
	
	wName = CheckNMStatsWavePath( wName )
	
	if ( ( WaveExists( $wName ) == 0 ) || ( WaveType( $wName ) == 0 ) )
		return NMErrorStr( 1, thisfxn, "wName", wName )
	endif
	
	if ( ( numtype( binsize ) > 0 ) || ( binsize <= 0 ) )
		return NMErrorStr( 10, thisfxn, "binsize", num2str( binsize ) )
	endif
	
	folder = GetPathName( wName, 1 )
	pName = GetPathName( wName, 0 )
	
	if ( StringMatch( NMStatsStr( "WaveNamingFormat" ), "suffix" ) == 1 )
		dName = pName + "_Histo"
	else
		dName = "Histo_" + pName
	endif
	
	gName = pName + "_" + NMFolderPrefix( "" ) + "Histo"
	gTitle = NMFolderListName( "" ) + " : " + dName
	
	Wavestats /Q/Z $wName
	
	if ( V_npnts < 1 )
		Abort "Abort StatsHisto: not enough data points: " + num2istr( V_npnts )
	endif
	
	range = abs( V_max - V_min )
	npnts = ceil( range/binsize ) + 4
	vmin = floor( V_min/binsize )*binsize - 2*binsize
	
	dName = folder + dName
	
	Make /O/N=1 $dName
	
	xl = NMNoteLabel( "y", wName, "" )
	yl = "Count"
	
	NMNoteType( dName, "Stats Histo", xl, yl, "Func:StatsHisto" )
	Note $dName, "Histo Wave:" + wName
	
	Histogram /B={vmin,binsize,npnts} $wName, $dName
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=( 0,0,0,0 ) $dName as gTitle
	SetCascadeXY( gName )
	Label bottom xl
	Label left yl
	ModifyGraph standoff=0, rgb=( 0,0,0 ), mode=5, hbFill=2
	
	return gName

End // NMStats2Histogram

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2SortWaveCall()
	
	Variable xvalue, yvalue, nvalue
	String setName = ""
 	
 	String wSelect, wTest, vlist = ""
	String wList = NMStats2WaveSelectList( 0 )
	String folder = CurrentNMStats2FolderSelect( 1 )
	String sList = "[ a ] > x;[ a ] > x - n*y;[ a ] < x;[ a ] < x + n*y;x < [ a ] < y;x - n*y < [ a ] < x + n*y;"
	
	Variable method = NMStatsVar( "SortMethod" )
	Variable createSet = 1 + NMStatsVar( "SortCreateSet" )
 	
	String wName = CurrentNMStats2WaveSelect( 1 )
	
	if ( WaveExists( $wName ) == 0 )
		return ""
	endif
	
	Prompt method, "choose sorting method for wave value [ a ] defined as 'true' ( 1 ):", popup sList
	Prompt xvalue, "x value: "
	Prompt yvalue, "y value:"
	Prompt nvalue, "n value:"
	Prompt createSet, "save results as a new Set?", popup "no;yes;"
	
	wName = GetPathName( wName, 0 )
	wSelect = wName

	Prompt wSelect, "choose wave:", popup wList
	DoPrompt "Sort Stats Wave", wSelect, method, createSet
	
	if ( StringMatch( wName, wSelect ) == 1 )
		wSelect = "_selected_"
	else
		wSelect = GetPathName( folder, 0 ) + ":" + wSelect
	endif
	
	wTest = folder + wName
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	createSet -= 1
	
	SetNMStatsVar( "SortMethod", method )
	SetNMStatsVar( "SortCreateSet", createSet )
	
	WaveStats /Q/Z $wTest
	
	xvalue = V_avg
	yvalue = V_sdev
	nvalue = 1
	
	switch( method )
		case 1:
			DoPrompt "[ a ] > x", xvalue
			break
		case 2:
			DoPrompt "[ a ] > x - n*y", xvalue, nvalue, yvalue
			break
		case 3:
			DoPrompt "[ a ] < x", xvalue
			break
		case 4:
			DoPrompt "[ a ] < x + n*y", xvalue, nvalue, yvalue
			break
		case 5:
			DoPrompt "x < [ a ] < y", xvalue, yvalue
			break
		case 6:
			DoPrompt "x - n*y < [ a ] < x + n*y", xvalue, nvalue, yvalue
			break
	endswitch
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( createSet == 1 )
	
		//setName = ReplaceString( "ST_", GetPathName( wTest, 0 ), "" )
		//setName = ReplaceString( "_", GetPathName( setName, 0 ), "" )
		//setName = "Sort_" + setName
		
		setName = NMSetsNameNext()
		
		Prompt setName, "output Set name:"
		DoPrompt "Sort Stats Wave", setName
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	endif
	
	vlist = NMCmdStr( wSelect, vlist )
	vlist = NMCmdNum( method, vlist )
	vlist = NMCmdNum( xvalue, vlist )
	vlist = NMCmdNum( yvalue, vlist )
	vlist = NMCmdNum( nvalue, vlist )
	vlist = NMCmdStr( setName, vlist )
	NMCmdHistory( "NMStats2SortWave", vlist )
	
	return NMStats2SortWave( wSelect, method, xvalue, yvalue, nvalue, setName )
	
End // NMStats2SortWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2SortWave( wName, method, xvalue, yvalue, nvalue, setName )
	String wName // wave name, ( "_selected_" ) for current Stats2 wave select
	Variable method // sorting method ( see NMSortWave )
	Variable xvalue
	Variable yvalue
	Variable nvalue
	String setName // optional output Set name, ( "" ) for none
	
	Variable success
	Variable overwrite = NeuroMaticVar( "OverWrite" )
	
	String gName, gtitle, df = StatsDF()
	String mthd, dName, folder, pName
	
	wName = CheckNMStatsWavePath( wName )
	
	if ( ( WaveExists( $wName ) == 0 ) || ( WaveType( $wName ) == 0 ) )
		return NMErrorStr( 1, "NMStats2SortWave", "wName", wName )
	endif
	
	folder = GetPathName( wName, 1 )
	pName = GetPathName( wName, 0 )
	
	if ( StringMatch( NMStatsStr( "WaveNamingFormat" ), "suffix" ) == 1 )
		dName = pName + "_Sort" + num2istr( method )
	else
		dName = "Sort" + num2istr( method ) + "_" + pName
	endif
	
	gName = pName + "_" + NMFolderPrefix( "" ) + "Sort"
	mthd = NMStats2SortMethodStr( method, xvalue, yvalue, nvalue )
	gTitle = NMFolderListName( "" ) + " : " + pName + " : " + mthd
	
	dName = folder + dName
	
	success = NMSortWave( wName, dName, method, xvalue, yvalue, nvalue )
	
	if ( WaveExists( $dName ) == 0 )
		return "" // something went wrong
	endif
	
	if ( strlen( setName ) > 0 )
		NMSetsWaveToLists( dName, setName )
	endif
	
	DoWindow /K $gName
	
	Display /K=1/N=$gName/W=( 0,0,0,0 ) $dName as gtitle
	SetCascadeXY( gName )
	ModifyGraph mode=3,marker=19, nticks( left )=2, standoff=0
	Label bottom NMNoteLabel( "x", dName, "Wave #" )
	Label left NMNoteLabel( "y", dName, "True(1) / False(0)" )
	
	SetAxis left 0,1
	
	NMHistory( mthd + "; successes = " + num2istr( success ) )
	
	return gName

End // NMStats2SortWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2SortMethodStr( method, xvalue, yvalue, nvalue )
	Variable method
	Variable xvalue, yvalue, nvalue
	
	switch( method )
		case 1:
			return "[ a ] > x; x = " + num2str( xvalue )
		case 2:
			return "[ a ] > x - n*y; x = " + num2str( xvalue ) + "; y = " + num2str( yvalue ) + "; n = " + num2istr( nvalue )
		case 3:
			return "[ a ] < x; x = " + num2str( xvalue )
		case 4:
			return "[ a ] < x + n*y; x = " + num2str( xvalue ) + "; y = " + num2str( yvalue ) + "; n = " + num2istr( nvalue )
		case 5:
			return "x < [ a ] < y; x = " + num2str( xvalue ) + "; y = " + num2str( yvalue )
		case 6:
			return "x - n*y < [ a ] < x + n*y; x = " + num2str( xvalue ) + "; y = " + num2str( yvalue ) + "; n = " + num2istr( nvalue )
		default:
			return NMErrorStr( 10, "NMStats2SortMethodStr", "method", num2istr( method ) )
	endswitch

End // NMStats2SortMethodStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2StabilityCall()

	Variable dumVar = 0
	
	String vlist = ""
	String folder = CurrentNMStats2FolderSelect( 1 )
	String wList = NMStats2WaveSelectList( 0 )
	String wName = CurrentNMStats2WaveSelect( 0 )
	String wSelect = wName
	
	Variable doWavePrompt = 0
	
	if ( doWavePrompt && ItemsInList( wList ) > 1 )
	
		Prompt wSelect, "choose wave:", popup wList
		DoPrompt "Stats Stability", wSelect
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	endif
	
	wSelect = folder + wSelect
	
	vlist = NMCmdStr( wSelect, vlist )
	vlist = NMCmdNum( dumVar, vlist )
	//NMCmdHistory( "NMStabilityStats", vlist )
	
	Execute "NMStabilityStats( " + NMQuotes( wSelect ) + "," + num2str( dumVar ) + " )"
	
	return ""
	
End // NMStats2StabilityCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2SigDiffCall()

	Variable error
	String vList = "" 

	String folder = CurrentNMStats2FolderSelect( 1 )
	String fSelect = " "
	String folderList = NMStats2FolderList( 0 )
	
	String waveName1 = CurrentNMStats2WaveSelect( 1 )
	String wSelect1 = GetPathName( waveName1, 0 )
	String wList1 = NMStats2WaveSelectList( 0 )
	
	String waveName2 = " "
	String wSelect2 = waveName2
	String wList2 = NMFolderWaveList( folder, "*", ";", "TEXT:0", 0 )
	
	Variable dsply = 1 + NMStatsVar( "KSdsply" )
	
	folderList = RemoveFromList( GetPathName( folder, 0 ), folderList )
	
	Prompt wSelect1, "select first data wave:", popup wList1
	Prompt wSelect2, "select second data wave for comparison:", popup " ;" + wList2
	Prompt fSelect, "or choose a folder to locate second data wave:", popup " ;" + folderList
	Prompt dsply,"display cumulative distributions?",popup,"no;yes"
	
	DoPrompt "Kolmogorov-Smirnov Test For Significant Difference", wSelect1, wSelect2, fSelect, dsply
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	dsply -= 1
	
	SetNMStatsVar( "KSdsply", dsply )
	
	if ( WaveExists( $folder+wSelect1 ) == 0 )
		return "" // something went wrong
	endif
	
	if ( StringMatch( folder, GetDataFolder( 1 ) ) == 1 )
		folder = ""
	endif
	
	if ( strlen( folder ) > 0 )
		wSelect1 = folder + wSelect1
	endif
	
	if ( ( strlen( folder ) > 0 ) && ( StringMatch( wSelect2, " " ) == 0 ) )
		wSelect2 = folder + wSelect2
	endif
	
	if ( StringMatch( fSelect, " " ) == 0 )
	
		fSelect = CheckNMStatsFolderPath( fSelect )
	
		wList2 = NMFolderWaveList( fSelect, "*", ";", "TEXT:0", 0 )
		waveName2 = " "
		
		Prompt wSelect2, "select second data wave for comparison:", popup " ;" + wList2
		DoPrompt "Kolmogorov-Smirnov Test For Significant Difference", wSelect2
		
		if ( ( V_flag == 1 ) || ( StringMatch( wSelect2, " " ) == 1 ) )
			return "" // cancel
		endif
		
		if ( StringMatch( fSelect, GetDataFolder( 1 ) ) == 1 )
			fSelect = ""
		endif
		
		if ( strlen( fSelect ) > 0 )
			wSelect2 = fSelect + wSelect2
		endif

	endif
	
	vlist = NMCmdStr( wSelect1, vlist )
	vlist = NMCmdStr( wSelect2, vlist )
	vlist = NMCmdNum(dsply, vlist)
	NMCmdHistory( "KSTest", vlist )
	
	error = KSTest( wSelect1, wSelect2, dsply )
	
	return num2str( error )
	
End // NMStats2SigDiffCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveScaleCall()

	Variable icnt
	String wtype, wName2, wList2 = "", chanList2, vlist = ""
	
	String folder = CurrentNMStats2FolderSelect( 1 )
	String wList = NMStats2WaveSelectList( 1 )
	String wName = CurrentNMStats2WaveSelect( 1 )
	String wSelect
	String chanSelect = NMChanSelectStr()
	String chanList = NMChanList( "CHAR" )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName2 = StringFromList( icnt, wList )
		wtype = NMStatsWaveTypeXY( wName2 )
		
		if ( StringMatch( wtype, "X" ) == 0 )
			wList2 += GetPathName( wName2, 0 ) + ";"
		endif
		
	endfor
	
	if ( ItemsInList( wList2 ) == 0 )
		NMDoAlert( "NMStats2WaveScaleCall Abort: there are no Stats X-value waves in the currently selected Stats2 folder " + folder )
		return ""
	endif
	
	wtype = NMStatsWaveTypeXY( wName )
	
	if ( StringMatch( wtype, "X" ) == 0 )
		wSelect = GetPathName( wName, 0 )
	else
		wSelect = " "
	endif
	
	if ( ItemsInList( chanList ) > 0 )
		chanList2 = "All;" + chanList
	else
		chanList2 = chanList
	endif
	
	String alg = NMStatsStr( "WaveScaleAlg" )
	
	Prompt wSelect, "choose wave of scale values:", popup " ;" + wList2
	Prompt alg, "scale function:", popup "x;/;+;-"
	Prompt chanSelect, "select channel(s) to apply wave scaling:", popup chanList2
	DoPrompt "Stats Wave Scaling", wSelect, alg, chanSelect
	
	if ( ( V_flag == 1 ) || ( StringMatch( wSelect, " " ) == 1 ) )
		return "" // cancel
	endif
	
	SetNMStatsStr( "WaveScaleAlg", alg )
	
	if ( StringMatch( GetPathName( wName, 0 ), wSelect ) == 1 )
		wSelect = "_selected_"
	else
		wSelect = GetPathName( folder, 0 ) + ":" + wSelect
	endif
	
	vlist = NMCmdStr( "", vlist )
	vlist = NMCmdStr( wSelect, vlist )
	vlist = NMCmdStr( alg, vlist )
	vlist = NMCmdStr( chanSelect, vlist )
	NMCmdHistory( "NMStats2WaveScale", vlist )
	
	return NMStats2WaveScale( "", wSelect, alg, chanSelect )

End // NMStats2WaveScaleCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveScale( waveOfWaveNames, waveOfScaleValues, alg, chanSelect )
	String waveOfWaveNames // text wave containing list of waves to scale (e.g. "ST_wName_RAll_A0" ), enter ( "" ) use default Stats wave
	String waveOfScaleValues // wave containing scale values, ( "_selected_" ) for current Stats2 wave select
	String alg // "x", "/", "+" or "-"
	String chanSelect // channel number character or "All"
	
	Variable icnt, waveNum, npnts1, npnts2
	String wName, wNameScale, saveChanSelect, outList = "", thisfxn = "NMStats2WaveScale"
	String sdf = StatsDF()
	
	Variable numWaves = NMNumWaves()
	
	waveOfScaleValues = CheckNMStatsWavePath( waveOfScaleValues )
	
	if ( ( WaveExists( $waveOfScaleValues ) == 0 ) || ( WaveType( $waveOfScaleValues ) == 0 ) )
		return NMErrorStr( 1, thisfxn, "waveOfScaleValues", waveOfScaleValues )
	endif
	
	if ( strlen( waveOfWaveNames ) == 0 )
	
		waveOfWaveNames = NMStatsWaveNameForWNameFind( waveOfScaleValues )
		
		if ( strlen( waveOfWaveNames ) == 0 )
			NMDoAlert( thisfxn + " Abort: could not locate corresponding Stat wave " + NMQuotes( "ST_wName..." ) + " for wave " + NMQuotes( GetPathName( waveOfScaleValues, 0 ) ) )
			return ""
		endif
		
	endif
	
	waveOfWaveNames = CheckNMStatsWavePath( waveOfWaveNames )
	
	if ( ( WaveExists( $waveOfWaveNames ) == 0 ) || ( WaveType( $waveOfWaveNames ) != 0 ) )
		return NMErrorStr( 1, thisfxn, "waveOfWaveNames", waveOfWaveNames )
	endif
	
	npnts1 = numpnts( $waveOfWaveNames )
	npnts2 = numpnts( $waveOfScaleValues )
	
	if ( npnts1 != npnts2 )
		NMDoAlert( thisfxn + " Error: input waves have different length: " + num2istr( npnts1 ) + " and " + num2istr( npnts2 ) )
		return ""
	endif
	
	if ( strsearch( "x*/+-", alg, 0 ) == -1 )
		return NMErrorStr( 20, thisfxn, "alg", alg )
	endif
	
	if ( WhichListItem( chanSelect, "All;" + NMChanList( "CHAR" ) ) < 0 )
		return NMErrorStr( 20, thisfxn, "chanSelect", chanSelect )
	endif
	
	wNameScale = sdf+"ST2_WaveScales"
	
	Make /O/N=( numWaves ) $wNameScale = Inf // create wave of appropriate length for function NMScaleByWave, set default to "inf" since this will be ignored by NMScaleByWave
	
	Wave /T wNames = $waveOfWaveNames
	Wave scaleValues = $waveOfScaleValues
	Wave newScaleValues = $wNameScale
	
	for ( icnt = 0 ; icnt < numpnts( wNames ) ; icnt += 1 )
		
		wName = wNames[ icnt ]
		
		waveNum = NMChanWaveNum( wName )
		
		if ( waveNum < 0 )
			NMDoAlert( thisfxn + " Error: could not locate wave number for wave " + NMQuotes( wName ) + "." )
			KillWaves /Z $wNameScale
			return ""
		endif
		
		newScaleValues[ waveNum ] = scaleValues[ icnt ]
	
	endfor
	
	saveChanSelect = NMChanSelectStr()
	
	if ( StringMatch( saveChanSelect, chanSelect ) == 0 )
		NMChanSelect( chanSelect )
	else
		saveChanSelect = ""
	endif
	
	outList = NMScaleByWave( 1, alg, wNameScale )
	
	if ( strlen( saveChanSelect ) > 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	KillWaves /Z $wNameScale
	
	NMAutoStats()
	
	return outList
	
End // NMStats2WaveScale

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveAlignmentCall()

	Variable icnt
	String wtype, wName2, wList2 = "", chanList2, vlist = ""
	
	String folder = CurrentNMStats2FolderSelect( 1 )
	String wList = NMStats2WaveSelectList( 1 )
	String wName = CurrentNMStats2WaveSelect( 1 )
	String wSelect
	String chanSelect = NMChanSelectStr()
	String chanList = NMChanList( "CHAR" )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName2 = StringFromList( icnt, wList )
		wtype = NMStatsWaveTypeXY( wName2 )
		
		if ( StringMatch( wtype, "X" ) == 1 )
			wList2 += GetPathName( wName2, 0 ) + ";"
		endif
		
	endfor
	
	if ( ItemsInList( wList2 ) == 0 )
		NMDoAlert( "NMStats2WaveAlignmentCall Abort: there are no Stats X-value waves in the currently selected Stats2 folder " + folder )
		return ""
	endif
	
	wtype = NMStatsWaveTypeXY( wName )
	
	if ( StringMatch( wtype, "X" ) == 1 )
		wSelect = GetPathName( wName, 0 )
	else
		wSelect = " "
	endif
	
	if ( ItemsInList( chanList ) > 0 )
		chanList2 = "All;" + chanList
	else
		chanList2 = chanList
	endif
	
	Variable atTimeZero = 1 + NMStatsVar( "AlignAtTimeZero" )
	
	Prompt wSelect, "choose wave of alignment values:", popup " ;" + wList2
	Prompt atTimeZero, "align at time zero?", popup "no, align at maximum alignment value;yes"
	Prompt chanSelect, "select channel(s) to apply wave alignment:", popup chanList2
	DoPrompt "Stats Wave Alignment", wSelect, atTimeZero, chanSelect
	
	if ( ( V_flag == 1 ) || ( StringMatch( wSelect, " " ) == 1 ) )
		return "" // cancel
	endif
	
	atTimeZero -= 1
	
	SetNMStatsVar( "AlignAtTimeZero", atTimeZero )
	
	if ( StringMatch( GetPathName( wName, 0 ), wSelect ) == 1 )
		wSelect = "_selected_"
	else
		wSelect = GetPathName( folder, 0 ) + ":" + wSelect
	endif
	
	vlist = NMCmdStr( "", vlist )
	vlist = NMCmdStr( wSelect, vlist )
	vlist = NMCmdNum( atTimeZero, vlist )
	vlist = NMCmdStr( chanSelect, vlist )
	NMCmdHistory( "NMStats2WaveAlignment", vlist )
	
	return NMStats2WaveAlignment( "", wSelect, atTimeZero, chanSelect )

End // NMStats2WaveAlignmentCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveAlignment( waveOfWaveNames, waveOfAlignments, atTimeZero, chanSelect )
	String waveOfWaveNames // text wave containing list of waves to align (e.g. "ST_wName_RAll_A0" ), enter ( "" ) use default Stats wave
	String waveOfAlignments // wave containing times for alignment, ( "_selected_" ) for current Stats2 wave select
	Variable atTimeZero // align at time zero? ( 0 ) no, align at maximum alignment value ( 1 ) yes
	String chanSelect // channel number character or "All"
	
	Variable icnt, waveNum, npnts1, npnts2
	String wName, wNameAlign, saveChanSelect, outList, thisfxn = "NMStats2WaveAlignment"
	String sdf = StatsDF()
	
	Variable numWaves = NMNumWaves()
	
	waveOfAlignments = CheckNMStatsWavePath( waveOfAlignments )
	
	if ( ( WaveExists( $waveOfAlignments ) == 0 ) || ( WaveType( $waveOfAlignments ) == 0 ) )
		return NMErrorStr( 1, thisfxn, "waveOfAlignments", waveOfAlignments )
	endif
	
	if ( strlen( waveOfWaveNames ) == 0 )
	
		waveOfWaveNames = NMStatsWaveNameForWNameFind( waveOfAlignments )
		
		if ( strlen( waveOfWaveNames ) == 0 )
			NMDoAlert( thisfxn + " Abort: could not locate corresponding Stat wave " + NMQuotes( "ST_wName..." ) + " for wave " + NMQuotes( GetPathName( waveOfAlignments, 0 ) ) )
			return ""
		endif
		
	endif
	
	waveOfWaveNames = CheckNMStatsWavePath( waveOfWaveNames )
	
	if ( ( WaveExists( $waveOfWaveNames ) == 0 ) || ( WaveType( $waveOfWaveNames ) != 0 ) )
		return NMErrorStr( 1, thisfxn, "waveOfWaveNames", waveOfWaveNames )
	endif
	
	npnts1 = numpnts( $waveOfWaveNames )
	npnts2 = numpnts( $waveOfAlignments )
	
	if ( npnts1 != npnts2 )
		NMDoAlert( thisfxn + " Error: input waves have different length: " + num2istr( npnts1 ) + " and " + num2istr( npnts2 ) )
		return ""
	endif
	
	if ( WhichListItem( chanSelect, "All;" + NMChanList( "CHAR" ) ) < 0 )
		return NMErrorStr( 20, thisfxn, "chanSelect", chanSelect )
	endif
	
	wNameAlign = sdf+"ST2_WaveAlignments"
	
	Make /O/N=( numWaves ) $wNameAlign = Nan // create wave of appropriate length for function NMAlignWaves
	
	Wave /T wNames = $waveOfWaveNames
	Wave alignments = $waveOfAlignments
	Wave newAlignments = $wNameAlign
	
	for ( icnt = 0 ; icnt < numpnts( wNames ) ; icnt += 1 )
		
		wName = wNames[ icnt ]
		
		waveNum = NMChanWaveNum( wName )
		
		if ( waveNum < 0 )
			NMDoAlert( thisfxn + " Error: could not locate wave number for wave " + NMQuotes( wName ) + "." )
			KillWaves /Z $wNameAlign
			return ""
		endif
		
		newAlignments[ waveNum ] = alignments[ icnt ]
	
	endfor
	
	saveChanSelect = NMChanSelectStr()
	
	if ( StringMatch( saveChanSelect, chanSelect ) == 0 )
		NMChanSelect( chanSelect )
	else
		saveChanSelect = ""
	endif
	
	outList = NMAlignWaves( wNameAlign, BinaryInvert( atTimeZero ) )
	
	if ( strlen( saveChanSelect ) > 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	KillWaves /Z $wNameAlign
	
	NMAutoStats()
	
	return outList
	
End // NMStats2WaveAlignment

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2FolderKillCall()
	
	String vlist = ""
	String folder = CurrentNMStats2FolderSelect( 0 )
	
	if ( StringMatch( folder, GetDataFolder( 0 ) ) ==1  )
		return "" // not allowed
	endif
	
	DoAlert 1, "Are you sure you want to delete subfolder " + NMQuotes( folder ) + "?"
	
	if ( V_flag != 1 )
		return "" // cancel
	endif
	
	folder = "_selected_"
	
	vlist = NMCmdStr( folder, vlist )
	NMCmdHistory( "NMStats2FolderKill", vlist )
	
	return NMStats2FolderKill( folder )
	
End // NMStats2FolderKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2FolderKill( folder )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Stats2 folder
	
	String thisfxn = "NMStats2FolderKill"
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	if ( StringMatch( folder, GetDataFolder( 1 ) ) ==1  )
		NMDoAlert( thisfxn + " Abort: cannot close the current data folder." )
		return "" // not allowed
	endif
	
	Variable error = NMStatsSubfolderKill( folder )
	
	UpdateStats2()
	
	if ( error == 0 )
		return folder
	else
		return ""
	endif

End // NMStats2FolderKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2FolderClearCall()
	
	String vlist = ""
	String folder = CurrentNMStats2FolderSelect( 0 )
	
	if ( StringMatch( folder, GetDataFolder( 0 ) ) ==1  )
		return "" // not allowed
	endif
	
	DoAlert 1, "Are you sure you want to kill all waves inside subfolder " + NMQuotes( folder ) + "?"
	
	if ( V_flag != 1 )
		return "" // cancel
	endif
	
	folder = "_selected_"
	
	vlist = NMCmdStr( folder, vlist )
	NMCmdHistory( "NMStats2FolderClear", vlist )
	
	return NMStats2FolderClear( folder )
	
End // NMStats2FolderClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2FolderClear( folder )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Stats2 folder
	
	String thisfxn = "NMStats2FolderClear"
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	if ( StringMatch( folder, GetDataFolder( 1 ) ) ==1  )
		NMDoAlert( "NMStats2FolderClear Abort: cannot clear the current data folder." )
		return "" // not allowed
	endif
	
	String failureList = NMStatsSubfolderClear( folder )
	
	if ( ItemsInList( failureList ) > 0 )
		NMDoAlert( thisfxn + " Alert: failed to kill the following waves: " + failureList )
	endif
	
	UpdateStats2()
	
	return failureList

End // NMStats2FolderClear

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2EditAllCall()

	Variable option = 1
	String vlist = ""
	
	String folder = CurrentNMStats2FolderSelect( 0 )
	
	if ( StringMatch( folder, GetDataFolder( 0 ) ) == 0 )
	
		folder = "_selected_"
		
		option = 1 + NMStatsVar( "EditAllOption" )
	
		Prompt option " ", popup "all waves inside currently selected Stats2 folder;all currently selected Stats2 waves;"
		DoPrompt "Edit Stats Waves", option
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		option -= 1
		
		SetNMStatsVar( "EditAllOption", option )
		
	endif
	
	vlist = NMCmdStr( folder, vlist )
	vlist = NMCmdNum( option, vlist )
	NMCmdHistory( "NMStats2EditAll", vlist )
	
	return NMStats2EditAll( folder, option )

End // NMStats2EditAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2EditAll( folder, option )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Stats2 folder
	Variable option // ( 0 ) all Stats waves inside folder ( 1 ) all currently selected Stats2 waves
	
	Variable wcnt
	String folderShort, wList = "", wName, tName = "", title = "", thisfxn = "NMStats2EditAll"
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	folderShort = GetPathName( folder, 0 )
	
	if ( option == 1 )
		wList = NMStats2WaveSelectList( 1 )
	else
		wList = NMFolderWaveList( folder, "ST_*", ";", "", 1 )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return NMErrorStr( 3, thisfxn, "wList", "" )
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( StringMatch( wName, "ST_wname*" ) == 1 )
			wList = RemoveFromList( wName, wList )
			wList = AddListItem( wName, wList, ";", 0 )
		endif
		
	endfor
		
	title = NMFolderListName( "" ) + " : " + folderShort
	tName = "ST_" + NMFolderPrefix( "" ) + folderShort
	
	EditWaves( tName, title, wList )
	
	return wList

End // NMStats2EditAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveStatsTableCall()
	
	Variable option = 1
	String vlist = ""
	
	String folder = CurrentNMStats2FolderSelect( 0 )
	
	if ( StringMatch( folder, GetDataFolder( 0 ) ) == 0 )
	
		folder = "_selected_"
	
		option = 1 + NMStatsVar( "WaveStatsTableOption" )
	
		Prompt option " ", popup "all waves inside currently selected Stats2 folder;all currently selected Stats2 waves;"
		DoPrompt "Wave Stats Table", option
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
		option -= 1
	
		SetNMStatsVar( "WaveStatsTableOption", option )
		
	endif
	
	vlist = NMCmdStr( folder, vlist )
	vlist = NMCmdNum( option, vlist )
	NMCmdHistory( "NMStats2WaveStatsTable", vlist )
	
	return NMStats2WaveStatsTable( folder, 1 )

End // NMStats2WaveStatsTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveStatsTable( folder, option )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Stats2 folder
	Variable option // ( 0 ) all Stats waves inside folder ( 1 ) all currently selected Stats2 waves

	Variable icnt
	String wName, wList, tName, thisfxn = "NMStats2WaveStatsTable"
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	if ( option == 1 )
		wList = NMStats2WaveSelectList( 0 )
	else
		wList = NMFolderWaveList( folder, "ST_*", ";", "TEXT:0", 0 )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return NMErrorStr( 3, thisfxn, "wList", "" )
	endif
	
	tName = NMStats2WaveStatsTableMake( folder, 1 )
	
	if ( WinType( tName ) == 2 )
		
		for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
			wName = StringFromList( icnt, wList )
			NMStats2WaveStatsTableSave( folder, wName )
		endfor
		
	else
	
		NMDoAlert( thisfxn + " Error: failed to make table." )
	
	endif
	
	UpdateStats2()
	
	return tName
	
End // NMStats2WaveStatsTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveStatsTableMake( folder, force )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Stats2 folder
	Variable force
	
	String wName, folderShort, tPrefix, tName, titlestr
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, "NMStats2WaveStatsTableMake", "folder", folder )
	endif
	
	folderShort = GetPathName( folder, 0 )
	
	tName = "ST2_" + NMFolderPrefix( "" ) + ReplaceString( "Stats_", folderShort, "" )
	tName = ReplaceString( "Stats", tName, "ST" )
	
	titlestr = NMFolderListName( "" ) + " : Stats2 : " + folderShort
	
	if ( ( WinType( tName ) == 2 ) && ( force == 0 ) )
		DoWindow /F $tName
		return tName // table already exists
	endif
	
	wName = folder + "ST2_wname"
	Make /T/O/N=0 $wName
	NMNoteType( wName, "Stats2 Wave Name", "", "", "" )
	
	DoWindow /K $tName
	Edit /K=1/N=$tName/W=( 0,0,0,0 ) $wName as titlestr
	ModifyTable /W=$tName width( $wName )=110
	
	wName = folder + "ST2_AVG"
	Make /O/N=0 $wName = Nan
	NMNoteType( wName, "Stats2 Avg", "", "", "" )
	AppendToTable /W=$tName $wName

	wName = folder + "ST2_SDV"
	Make /O/N=0 $wName = Nan
	NMNoteType( wName, "Stats2 Sdv", "", "", "" )
	AppendToTable /W=$tName $wName
	
	wName = folder + "ST2_SEM"
	Make /O/N=0 $wName = Nan
	NMNoteType( wName, "Stats2 SEM", "", "", "" )
	AppendToTable /W=$tName $wName
	
	wName = folder + "ST2_CNT"
	Make /O/N=0 $wName = Nan
	NMNoteType( wName, "Stats2 Count", "", "", "" )
	AppendToTable /W=$tName $wName
	
	wName = folder + "ST2_Min"
	Make /O/N=0 $wName = Nan
	NMNoteType( wName, "Stats2 Min", "", "", "" )
	AppendToTable /W=$tName $wName
	
	wName = folder + "ST2_Max"
	Make /O/N=0 $wName = Nan
	NMNoteType( wName, "Stats2 Max", "", "", "" )
	AppendToTable /W=$tName $wName

	SetCascadeXY( tName )
	ModifyTable /W=$tName title( Point ) = "Save"
	
	return tName
	
End // NMStats2WaveStatsTableMake

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveStatsTableSave( folder, wName )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Stats2 folder
	String wName // wave name

	String tName
	Variable npnts
	
	if ( strlen( wName ) == 0 )
		return ""
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	wName = folder + wName
	
	if ( ( WaveExists( $wName ) == 0 ) || ( WaveType( $wName ) == 0 ) )
		return NMErrorStr( 1, "NMStats2WaveStatsTableSave", "wName", wName )
	endif

	tName = NMStats2WaveStatsTableMake( folder, 0 )
	
	if ( WaveExists( $folder+"ST2_AVG" ) == 0 )
		return "" // something went wrong
	endif
	
	Wave ST2_AVG = $folder+"ST2_AVG"
	Wave ST2_SDV = $folder+"ST2_SDV"
	Wave ST2_SEM = $folder+"ST2_SEM"
	Wave ST2_CNT = $folder+"ST2_CNT"
	Wave ST2_Min = $folder+"ST2_Min"
	Wave ST2_Max = $folder+"ST2_Max"
	Wave /T ST2_wname = $folder+"ST2_wname"
	
	npnts = numpnts( ST2_wname ) + 1
	
	Redimension /N=( npnts ) ST2_wname, ST2_AVG, ST2_SDV, ST2_SEM, ST2_CNT, ST2_Min, ST2_Max
	
	WaveStats /Q/Z $wName
	
	ST2_wname[ npnts-1 ] = GetPathName( wName, 0 )
	ST2_AVG[ npnts-1 ] = V_avg
	ST2_SDV[ npnts-1 ] = V_sdev
	ST2_SEM[ npnts-1 ] = V_sdev / sqrt( V_npnts )
	ST2_CNT[ npnts-1 ] = V_npnts
	ST2_Min[ npnts-1 ] = V_min
	ST2_Max[ npnts-1 ] = V_max
	
	return tName
	
End // NMStats2WaveStatsTableSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveStatsPrintCall()

	Variable option = 1
	String vlist = ""
	
	String folder = CurrentNMStats2FolderSelect( 0 )
	
	if ( StringMatch( folder, GetDataFolder( 0 ) ) == 0 )
	
		folder = "_selected_"
	
		option = 1 + NMStatsVar( "PrintStatsOption" )
	
		Prompt option " ", popup "all waves inside currently selected Stats2 folder;all currently selected Stats2 waves;"
		DoPrompt "Print Wave Stats", option
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
		option -= 1
	
		SetNMStatsVar( "PrintStatsOption", option )
		
	endif
	
	vlist = NMCmdStr( folder, vlist )
	vlist = NMCmdNum( option, vlist )
	NMCmdHistory( "NMStats2WaveStatsPrint", vlist )
	
	return NMStats2WaveStatsPrint( folder, 1 )

End // NMStats2WaveStatsPrintCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2WaveStatsPrint( folder, option )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Stats2 folder
	Variable option // ( 0 ) all Stats waves inside folder ( 1 ) all currently selected Stats2 waves
	
	Variable icnt
	String wList, wName, wNote, thisfxn = "NMStats2WaveStatsPrint"
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	if ( option == 1 )
		wList = NMStats2WaveSelectList( 1 )
	else
		wList = NMFolderWaveList( folder, "ST_*", ";", "TEXT:0", 1 )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return NMErrorStr( 3, thisfxn, "wList", "" )
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		
		if ( WaveExists( $wName ) == 0 )
			continue
		endif
		
		Print "\rWaveStats " + wName
		WaveStats /Z $wName
	
	endfor
	
	return wList
	
End // NMStats2WaveStatsPrint

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2PrintNotesCall()

	Variable option = 1
	String vlist = ""
	
	String folder = CurrentNMStats2FolderSelect( 0 )
	
	if ( StringMatch( folder, GetDataFolder( 0 ) ) == 0 )
	
		folder = "_selected_"
	
		option = 1 + NMStatsVar( "PrintNotesOption" )
	
		Prompt option " ", popup "all waves inside currently selected Stats2 folder;all currently selected Stats2 waves;"
		DoPrompt "Print Stats Wave Notes", option
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
		option -= 1
	
		SetNMStatsVar( "PrintNotesOption", option )
		
	endif
	
	vlist = NMCmdStr( folder, vlist )
	vlist = NMCmdNum( option, vlist )
	NMCmdHistory( "NMStats2PrintNotes", vlist )
	
	return NMStats2PrintNotes( folder, 1 )

End // NMStats2PrintNotesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2PrintNotes( folder, option )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Stats2 folder
	Variable option // ( 0 ) all Stats waves inside folder ( 1 ) all currently selected Stats2 waves
	
	Variable icnt
	String wList, wName, wNote, thisfxn = "NMStats2PrintNotes"
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	if ( option == 1 )
		wList = NMStats2WaveSelectList( 1 )
	else
		wList = NMFolderWaveList( folder, "ST_*", ";", "TEXT:0", 1 )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return NMErrorStr( 3, thisfxn, "wList", "" )
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		
		if ( WaveExists( $wName ) == 0 )
			continue
		endif
		
		wNote = note( $wName )
				
		if ( strlen( wNote ) == 0 )
			continue
		endif
		
		NMHistory( "\r" + GetPathName( wName, 0 ) + " Notes:\r" + wNote )
	
	endfor
	
	return wList

End // NMStats2PrintNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2PrintNamesCall()

	Variable option = 1, fullPath = 0
	String vlist = ""
	
	String folder = CurrentNMStats2FolderSelect( 0 )
	
	if ( StringMatch( folder, GetDataFolder( 0 ) ) == 0 )
	
		folder = "_selected_"
		
		option = 1 + NMStatsVar( "PrintNamesOption" )
		fullPath = 1 + NMStatsVar( "PrintNamesFullpath" )
	
		Prompt option " ", popup "all waves inside currently selected Stats2 folder;all currently selected Stats2 waves;"
		Prompt fullPath " ", popup "print wave names only; print folder + wave names;"
		DoPrompt "Print Stats Wave Names", option, fullPath
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
		option -= 1
		fullPath -= 1
	
		SetNMStatsVar( "PrintNamesOption", option )
		SetNMStatsVar( "PrintNamesFullpath", fullPath )
		
	endif
	
	vlist = NMCmdStr( folder, vlist )
	vlist = NMCmdNum( option, vlist )
	vlist = NMCmdNum( fullPath, vlist )
	NMCmdHistory( "NMStats2PrintNames", vlist )
	
	return NMStats2PrintNames( folder, option, fullPath )

End // NMStats2PrintNamesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStats2PrintNames( folder, option, fullPath )
	String folder // data folder, ( "" ) for current data folder or ( "_selected_" ) for currently selected Stats2 folder
	Variable option // ( 0 ) all Stats waves inside folder ( 1 ) all currently selected Stats2 waves
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname
	
	String wList, thisfxn = "NMStats2PrintNames"
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return NMErrorStr( 30, thisfxn, "folder", folder )
	endif
	
	if ( option == 1 )
		wList = NMStats2WaveSelectList( fullPath )
	else
		wList = NMFolderWaveList( folder, "ST_*", ";", "TEXT:0", fullPath )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return NMErrorStr( 3, thisfxn, "wList", "" )
	endif
	
	NMHistory( wList )
	
	return wList

End // NMStats2PrintNames

//****************************************************************
//****************************************************************
//****************************************************************

Function XTimes2Stats() : GraphMarquee // use marquee x-values for stats t_beg and t_end

	String df = StatsDF()
	
	if ( ( DataFolderExists( df ) == 0 ) || ( IsCurrentNMTab( "Stats" ) == 0 ) )
		return 0 
	endif

	GetMarquee left, bottom
	
	if ( V_Flag == 0 )
		return 0
	endif
	
	Variable win = NMStatsVar( "AmpNV" )
	
	Wave AmpB = $df+"AmpB"
	Wave AmpE = $df+"AmpE"
	
	AmpB[ win ] = V_left
	AmpE[ win ] = V_right
	
	NMAutoStats()

End // XTimes2Stats
	
//****************************************************************
//****************************************************************
//****************************************************************