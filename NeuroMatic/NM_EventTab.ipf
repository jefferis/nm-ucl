#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spontaneous Event Detection
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	Began 5 May 2002
//
//	NM tab entry "Event"
//
//	Spontaneous event detection
//	Threshold search algorithm based on Kudoh and Taguchi,
//	Biosensors and Bioelectronics 17, 2002, pp. 773 - 782
//	"A simple exploratory algorithm for accurate detection of 
//	spontaneous synaptic events"
//
//	Template-Matching Algorithm by Clements and Bekkers,
//	Biophysical Journal, 1997, pp. 220-229
//	"Detection of spontaneous synaptic events with an
//	optimally scaled template"
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventPrefix( objName ) // tab prefix identifier
	String objName
	
	return "EV_" + objName
	
End // EventPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventDF() // package full-path folder name

	return PackDF( "Event" )
	
End // EventDF

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTab( enable ) // enable/disable Event Tab
	Variable enable // ( 1 ) enable ( 0 ) disable

	if ( enable == 1 )
		CheckPackage( "Event", 0 ) // create globals if necessary
		DisableNMPanel( 1 )
		MakeEventTab( 0 ) // create controls if necessary
		UpdateEventDisplay()
		UpdateEventTab()
		ChanControlsDisable( -1, "000000" )
		MatchTemplateCall( 0 )
	endif
	
	if ( DataFolderExists( EventDF() ) == 0 )
		return 0 // Event Tab not created yet
	endif
	
	EventDisplay( enable )
	EventCursors( enable )

End // EventTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillEvent( what )
	String what
	
	String df = EventDF()
	
	strswitch( what )
		case "waves":
			break
		case "globals":
			if ( DataFolderExists( df ) == 1 )
				KillDataFolder $df
			endif 
			break
	endswitch

End // KillEvent

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventOverWrite()

	return 1 // NMOverWrite()
	
End // NMEventOverWrite

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Variables, Strings and Waves
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckEvent()
	
	if ( DataFolderExists( EventDF() ) == 0 )
		return -1
	endif
	
	CheckNMwave( NMEventDisplayWaveName( "ThreshT" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "ThreshY" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "OnsetT" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "OnsetY" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "PeakT" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "PeakY" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "BaseT" ), 2, 0 )
	CheckNMwave( NMEventDisplayWaveName( "BaseY" ), 2, Nan )
	CheckNMwave( NMEventDisplayWaveName( "ThisT" ), 1, 0 )
	CheckNMwave( NMEventDisplayWaveName( "ThisY" ), 1, Nan )
	
	return 0
	
End // CheckEvent

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMEventVar( varName )
	String varName
	
	return CheckNMvar( EventDF()+varName, NMEventVar( varName ) )

End // CheckNMEventVar

//****************************************************************
//****************************************************************
//****************************************************************

Function EventConfigs()
	
	NMEventConfigVar( "UseSubfolders", "use subfolders when creating Event result waves (0) no (1) yes ( use 0 for previous NM formatting )")

	NMEventConfigVar( "SearchMethod", "(1) level+ (2) level- (3) threshold+ (4) threshold-" )
	NMEventConfigVar( "SearchBgn", "Seach begin time (ms)" )
	NMEventConfigVar( "SearchEnd", "Search end time (ms)" )
	NMEventConfigVar( "Thrshld", "Threshold value" )
	
	NMEventConfigVar( "BaseFlag", "Compute baseline (0) no (1) yes" )
	NMEventConfigVar( "BaseWin", "Baseline avg window (ms)" )
	NMEventConfigVar( "BaseDT", "Mid-base to threshold crossing (ms)" )
	
	NMEventConfigVar( "OnsetFlag", "Compute onset (0) no (1) yes" )
	NMEventConfigVar( "OnsetWin", "Onset search limit (ms)" )
	NMEventConfigVar( "OnsetAvg", "Avg window (ms)" )
	NMEventConfigVar( "OnsetNstdv", "Num stdv's above avg" )
	
	NMEventConfigVar( "PeakFlag", "Compute peak (0) no (1) yes" )
	NMEventConfigVar( "PeakWin", "Peak search limit (ms)" )
	NMEventConfigVar( "PeakAvg", "Avg window (ms)" )
	NMEventConfigVar( "PeakNstdv", "Num stdv's above avg" )
	
	NMEventConfigVar( "DsplyWin", "Channel display window size (ms)" )
	NMEventConfigVar( "DsplyFraction", "Fraction of display window to view current event" )
	
	NMEventConfigVar( "FindNextAfterSaving", "Automatically search for next event after saving (0) no (1) yes" )
	NMEventConfigVar( "SearchWaveAdvance", "Automatically advance to next/previous wave when searching (0) no (1) yes" )
	NMEventConfigVar( "ReviewWaveAdvance", "Automatically advance to next/previous wave when reviewing (0) no (1) yes" )
			
End // EventConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventConfigVar( varName, description )
	String varName
	String description
	
	return NMConfigVar( "Event", varName, NMEventVar( varName ), description )
	
End // NMEventConfigVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventVar( varName )
	String varName
	
	Variable defaultVal = Nan
	String df = EventDF()
	
	strswitch( varName )
	
		case "UseSubfolders":
			defaultVal = 1
			break
			
		case "Positive":
			defaultVal = Nan
			break
	
		case "SearchMethod":
			defaultVal = 3
			break
			
		case "Thrshld":
			defaultVal = 10
			break
			
		case "Level":
			defaultVal = Nan
			break
			
		case "MatchLevel":
			defaultVal = Nan
			break
			
		case "ThreshLevel":
			defaultVal = Nan
			break
	
		case "DsplyWin":
			defaultVal = 50
			break
			
		case "DsplyFraction":
			defaultVal = 0.25
			break
			
		case "SearchFlag":
			defaultVal = 0
			break
			
		case "SearchBgn":
			defaultVal = -inf
			break
			
		case "SearchEnd":
			defaultVal = inf
			break
			
		case "SearchTime":
			defaultVal = 0
			break
			
		case "BaseFlag":
			defaultVal = 0
			break
			
		case "BaseWin":
			defaultVal = 2
			break
			
		case "BaseDT":
			defaultVal = NumVarOrDefault( df+"BaseWin", 2 )
			break
			
		case "ThreshX":
			defaultVal = Nan
			break
			
		case "ThreshY":
			defaultVal = Nan
			break
			
		case "MatchFlag":
			defaultVal = 0
			break
			
		case "MatchTau1":
			defaultVal = 2
			break
			
		case "MatchTau2":
			defaultVal = 3
			break
			
		case "MatchBsln":
			defaultVal = Nan
			break
			
		case "MatchWform":
			defaultVal = 8
			break
			
		case "OnsetFlag":
			defaultVal = 1
			break
			
		case "OnsetWin":
			defaultVal = 2
			break
			
		case "OnsetAvg":
			defaultVal = 0.5
			break
			
		case "OnsetNstdv":
			defaultVal = 1
			break
			
		case "OnsetY":
			defaultVal = Nan
			break
			
		case "OnsetX":
			defaultVal = Nan
			break
			
		case "PeakFlag":
			defaultVal = 1
			break
	
		case "PeakWin":
			defaultVal = 3
			break
			
		case "PeakAvg":
			defaultVal = 0.5
			break
			
		case "PeakNstdv":
			defaultVal = 1
			break
			
		case "PeakY":
			defaultVal = Nan
			break
			
		case "PeakX":
			defaultVal = Nan
			break
			
		case "BaseY":
			defaultVal = Nan
			break
			
		//case "EventNum":
		//	defaultVal = 0
		//	break
	
		case "NumEvents":
			defaultVal = 0
			break
			
		//case "TableNum":
		//	defaultVal = -1
		//	break
			
		case "FindNextAfterSaving":
			defaultVal = 1
			break
			
		case "SearchWaveAdvance":
			defaultVal = 1
			break
			
		case "ReviewWaveAdvance":
			defaultVal = 1
			break
			
		case "ReviewFlag":
			defaultVal = 0
			break
			
		case "ReviewAlert":
			defaultVal = 1
			break
			
		case "AutoTSelect":
			defaultVal = 1
			break
			
		case "AutoTZero":
			defaultVal = 1
			break
			
		case "AutoDsply":
			defaultVal = 1
			break
			
		case "E2W_before":
			defaultVal = 2
			break
			
		case "E2W_after":
			defaultVal = 10
			break
			
		case "E2W_stopAtNextEvent":
			defaultVal = 0
			break
			
		default:
			NMDoAlert( "NMEventVar Error: no variable called " + NMQuotes( varName ) )
			return Nan
	
	endswitch
	
	return NumVarOrDefault( df+varName, defaultVal )
	
End // NMEventVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventStr( varName )
	String varName
	
	String defaultStr = ""
	
	strswitch( varName )
	
		case "Template":
			defaultStr = ""
			break
			
		case "E2W_chan":
			defaultStr = CurrentNMChanChar()
			break
			
		case "S2W_WavePrefix":
			defaultStr = "Event"
			break
			
		case "HistoSelect":
			defaultStr = "interval"
			break
			
		default:
			NMDoAlert( "NMEventStr Error: no variable called " + NMQuotes( varName ) )
			return ""
	
	endswitch
	
	return StrVarOrDefault( EventDF() + varName, defaultStr )
			
End // NMEventStr

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMEventVar( varName, value )
	String varName
	Variable value
	
	String thisfxn = "SetNMEventVar", df = EventDF()
	
	if ( strlen( varName ) == 0 )
		return NMError( 21, thisfxn, "varName", varName )
	endif
	
	if ( DataFolderExists( df ) == 0 )
		return NMError( 30, thisfxn, "EventDF", df )
	endif
	
	Variable /G $df+varName = value
	
	return 0
	
End // SetNMEventVar

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMEventStr( varName, strValue )
	String varName
	String strValue
	
	String thisfxn = "SetNMEventStr", df = EventDF()
	
	if ( strlen( varName ) == 0 )
		return NMError( 21, thisfxn, "varName", varName )
	endif
	
	if ( DataFolderExists( df ) == 0 )
		return NMError( 30, thisfxn, "EventDF", df )
	endif
	
	String /G $df+varName = strValue
	
	return 0
	
End // SetNMEventStr

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMEventVariables()

	Variable tbgn, tend
	
	Variable positive = NMEventVar( "Positive" )
	Variable searchFlag = NMEventVar( "SearchFlag" )
	Variable searchMethod = NMEventVar( "SearchMethod" )
	Variable searchTime = NMEventVar( "SearchTime" )
	Variable matchFlag = NMEventVar( "MatchFlag" )
	Variable thrshld = NMEventVar( "Thrshld" )
	
	if ( numtype( positive ) > 0 ) // set new pos/neg flag
		
		switch( searchMethod )
		
			case 1:
			case 3:
				SetNMEventVar( "Positive", 1 )
				break
			
			case 2:
			case 4:
				SetNMEventVar( "Positive", 0 )
				break
		
		endswitch
		
		EventThreshold( thrshld )
	
	endif
	
	SetNMEventVar( "ThreshLevel",  NMEventThresholdLevel() ) // update display variable

	if ( searchMethod > 2 ) 
		SetNMEventVar( "BaseFlag", 1 )
	else
		SetNMEventVar( "BaseFlag", 0 )
	endif
	
	if ( matchFlag > 0 )
		SetNMEventVar( "OnsetFlag", 1 )
		SetNMEventVar( "BaseFlag", 0 )
	endif
	
	if ( searchFlag == 0 )
		SetNMEventVar( "SearchBgn", -inf )
		SetNMEventVar( "SearchEnd", inf )
	endif
	
	tbgn = EventSearchBgn()
	tend = EventSearchEnd()
	
	if ( searchTime < tbgn )
		SetNMEventVar( "SearchTime", tbgn )
	endif
	
	if ( searchTime > tend )
		SetNMEventVar( "SearchTime", tend )
	endif

End // CheckNMEventVariables

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchBgn()

	Variable t = NMEventVar( "SearchBgn" )

	if ( numtype( t ) > 0 )
		t = leftx( $ChanDisplayWave( CurrentNMChannel() ) )
	endif
	
	return t

End // EventSearchBgn

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchEnd()

	Variable t = NMEventVar( "SearchEnd" )

	if ( numtype( t ) > 0 )
		t = rightx( $ChanDisplayWave( CurrentNMChannel() ) )
	endif
	
	return t

End // EventSearchEnd

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Channel Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventDisplayWaveName( wName )
	String wName
	
	return EventDF() + "EV_" + wName
	
End // NMEventDisplayWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function EventDisplay( appnd ) // append/remove event display waves from channel graph
	Variable appnd // ( 0 ) remove wave ( 1 ) append wave 
	Variable icnt
	
	Variable ccnt, found
	String gName, xName, yName, df = EventDF()
	
	Variable chan = CurrentNMChannel()
	
	if ( DataFolderExists( df ) == 0 )
		return 0 // event tab has not been initialized yet
	endif
	
	Variable matchFlag = NMEventVar( "MatchFlag" )
	
	for ( ccnt = 0; ccnt < 10; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue
		endif
	
		DoWindow /F $gName
		
		found = WhichListItem( "EV_ThreshY", TraceNameList( gName, ";", 1 ), ";", 0, 0 )
	
		RemoveFromGraph /Z/W=$gName EV_BaseY, EV_ThisY, EV_ThreshY, EV_OnsetY, EV_PeakY, EV_MatchTmplt
	
		if ( ( appnd == 0 ) || ( ccnt != chan ) )
		
			ChanAutoScale( chan , 1 )
			
			SetAxis /A/W=$gName
			HideInfo /W=$gName
			
			if ( found != -1 ) // remove cursors
				Cursor /K/W=$gName A
				Cursor /K/W=$gName B
			endif
		
			continue
			
		endif
	
		if ( ( matchFlag > 0 ) && ( exists( NMEventDisplayWaveName( "MatchTmplt" ) ) == 1 ) )
		
			yName = NMEventDisplayWaveName( "MatchTmplt" )
		
			AppendToGraph /R=match /W=$gName $yName
			
			yName = GetPathName( yName, 0 )
			
			ModifyGraph rgb( $yName )=( 0,0,65535 )
			ModifyGraph axRGB( match )=( 0,0,65535 )
			
			xName = NMEventDisplayWaveName( "ThisT" )
			yName = NMEventDisplayWaveName( "ThisY" )
			
			AppendToGraph /R=match /W=$gName $yName vs $xName
			
			yName = GetPathName( yName, 0 )
			
			ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=9, msize( $yName )=6
			ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=( 65535,0,0 )
			
			xName = NMEventDisplayWaveName( "ThreshT" )
			yName = NMEventDisplayWaveName( "ThreshY" )
			
			AppendToGraph /R=match /W=$gName $yName vs $xName
			
			yName = GetPathName( yName, 0 )
			
			ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=9, msize( $yName )=6
			ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=( 65535,0,0 )
			
			Label match "Detection Criteria"
			
		endif
		
		if ( exists( NMEventDisplayWaveName( "ThreshY" ) ) == 1 )
		
			xName = NMEventDisplayWaveName( "BaseT" )
			yName = NMEventDisplayWaveName( "BaseY" )
			
			AppendToGraph /W=$gName $yName vs $xName
			
			yName = GetPathName( yName, 0 )
		
			ModifyGraph /W=$gName mode( $yName )=0
			ModifyGraph /W=$gName lsize( $yName )=2, rgb( $yName )=( 65280,43520,0 )
			
			if ( matchFlag == 0 )
			
				xName = NMEventDisplayWaveName( "ThisT" )
				yName = NMEventDisplayWaveName( "ThisY" )
			
				AppendToGraph /W=$gName $yName vs $xName
				
				yName = GetPathName( yName, 0 )
				
				ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=9, msize( $yName )=4
				ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=( 0,52224,0 )
				
				xName = NMEventDisplayWaveName( "ThreshT" )
				yName = NMEventDisplayWaveName( "ThreshY" )
				
				AppendToGraph /W=$gName $yName vs $xName
				
				yName = GetPathName( yName, 0 )
				
				ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=9, msize( $yName )=4
				ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=( 65535, 0, 0 )
				
			endif
			
			xName = NMEventDisplayWaveName( "OnsetT" )
			yName = NMEventDisplayWaveName( "OnsetY" )
			
			AppendToGraph /W=$gName $yName vs $xName
			
			yName = GetPathName( yName, 0 )
			
			ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=19, msize( $yName )=4
			ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=( 65535, 0, 0 )
			
			xName = NMEventDisplayWaveName( "PeakT" )
			yName = NMEventDisplayWaveName( "PeakY" )
			
			AppendToGraph /W=$gName $yName vs $xName
			
			yName = GetPathName( yName, 0 )
			
			ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=16, msize( $yName )=3
			ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=( 65535, 0, 0 )
			
			ShowInfo /W=$gName
			
		endif
		
	endfor

End // EventDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateEventDisplay() // update event display waves from table wave values

	Variable icnt, npntsDisplay, npntsTable

	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	if ( WaveExists( $NMEventDisplayWaveName( "ThreshT" ) ) == 0 )
		return -1
	endif

	Wave ThreshT = $NMEventDisplayWaveName( "ThreshT" )
	Wave ThreshY = $NMEventDisplayWaveName( "ThreshY" )
	Wave OnsetT = $NMEventDisplayWaveName( "OnsetT" )
	Wave OnsetY = $NMEventDisplayWaveName( "OnsetY" )
	Wave PeakT = $NMEventDisplayWaveName( "PeakT" )
	Wave PeakY = $NMEventDisplayWaveName( "PeakY" )
	
	if ( WaveExists( $NMEventTableWaveName( "ThreshT" ) ) == 0 )
		Redimension /N=0 ThreshT, ThreshY, OnsetT, OnsetY, PeakT, PeakY
		return 0
	endif
	
	Wave waveN = $NMEventTableWaveName( "WaveN" )
	
	Duplicate /O $NMEventTableWaveName( "ThreshT" ) ThreshT
	Duplicate /O $NMEventTableWaveName( "ThreshY" ) ThreshY
	Duplicate /O $NMEventTableWaveName( "OnsetT" ) OnsetT
	Duplicate /O $NMEventTableWaveName( "OnsetY" ) OnsetY
	Duplicate /O $NMEventTableWaveName( "PeakT" ) PeakT
	Duplicate /O $NMEventTableWaveName( "PeakY" ) PeakY
	
	if ( numpnts( waveN ) > 0 )
	
		MatrixOp /O EV_WaveSelectTemp = 1.0 * equal( waveN, currentWave )
		MatrixOp /O EV_WaveSelectTemp = EV_WaveSelectTemp / EV_WaveSelectTemp
	
		ThreshT *= EV_WaveSelectTemp
		ThreshY *= EV_WaveSelectTemp
		OnsetT *= EV_WaveSelectTemp
		OnsetY *= EV_WaveSelectTemp
		PeakT *= EV_WaveSelectTemp
		PeakY *= EV_WaveSelectTemp
		
		KillWaves /Z EV_WaveSelectTemp
	
	endif
	
	DoUpdate /W=$ChanGraphName( currentChan )
	
End // UpdateEventDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function EventCursors( enable ) // place cursors on onset and peak times
	Variable enable // ( 0 ) remove ( 1 ) add
	
	Variable tbgn, tend
	
	Variable dsplyWin = NMEventVar( "DsplyWin" )
	Variable dsplyFraction = NMEventVar( "DsplyFraction" )
	Variable threshX = NMEventVar( "ThreshX" )
	Variable onsetX = NMEventVar( "OnsetX" )
	Variable peakX = NMEventVar( "PeakX" )
	
	Variable currentChan = CurrentNMChannel()
	
	String gName = ChanGraphName( currentChan )
	String chanWave = ChanDisplayWave( currentChan )
	String dName = GetPathName( chanWave, 0 )
	
	Variable tmid = threshX

	if ( ( numtype( tmid ) > 0 ) || ( tmid == 0 ) )
		tmid = leftx( $chanWave )
	endif
	
	tbgn = tmid - dsplyWin * dsplyFraction
	tend = tmid + dsplyWin * ( 1 - dsplyFraction )

	if ( ( enable == 1 ) && ( WinType( gName ) == 1 ) )
		Cursor /W=$gName A, $dName, onsetX
		Cursor /W=$gName B, $dName, peakX
		SetAxis /W=$gName bottom tbgn, tend
	endif
	
	DoUpdate
	
End // EventCursors

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Tab Panel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeEventTab( force ) // create controls
	Variable force
	
	Variable x0, y0, yinc, fs = NMPanelFsize(), taby = NMPanelTabY()
	String df = EventDF()
	
	ControlInfo /W=NMPanel EV_Grp1
	
	if ( ( V_Flag != 0 ) && ( force == 0 ) )
		return 0 // Event tab controls exist
	endif
	
	if ( DataFolderExists( df ) == 0 )
		return 0 // Event tab has not been initialized yet
	endif
	
	CheckNMEventVar( "ThreshLevel" )
	CheckNMEventVar( "DsplyWin" )
	CheckNMEventVar( "SearchTime" )
	CheckNMEventVar( "NumEvents" )

	DoWindow /F NMPanel
	
	x0 = 35
	y0 = taby + 55
	yinc = 23
	
	GroupBox EV_Grp1, title = "Criteria", pos={x0-15,y0-25}, size={260,205}, fsize=fs
	
	PopupMenu EV_SearchMethod, pos={x0+125,y0}, bodywidth=175, mode=1, proc=NMEventPopupSearch
	PopupMenu EV_SearchMethod, value ="", fsize=fs
	
	SetVariable EV_Threshold, title=" ", pos={x0+185,y0+0*yinc+2}, limits={-inf,inf,0}, size={50,20}
	SetVariable EV_Threshold, value=$( df+"ThreshLevel" ), proc=NMEventSetVariable, fsize=fs
	
	y0 += 12
	
	Checkbox EV_PosNegCheck, title="positive events", pos={x0,y0+1*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_SearchCheck, title="search", pos={x0,y0+2*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_BaseCheck, title="baseline", pos={x0,y0+3*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_OnsetCheck, title="onset", pos={x0,y0+4*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_PeakCheck, title="peak", pos={x0,y0+5*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_MatchCheck, title="template matching", pos={x0,y0+6*yinc}, size={200,20}, value=0, proc=NMEventCheckBox, fsize=fs
	
	Button EV_Match, pos={x0+180,y0+ 6*yinc-2}, title="Match", size={50,20}, disable=1, proc=NMEventButton, fsize=fs
	
	y0 = 440
	
	GroupBox EV_Grp2, title = "Search", pos={x0-15,y0-25}, size={260,170}, fsize=fs
	
	PopupMenu EV_TableMenu, value = "Table", bodywidth = 175, pos={x0+125, y0}, proc=NMEventPopupTable, fsize=fs
	
	SetVariable EV_NumEvents, title=":", pos={x0+185,y0+2}, limits={0,inf,0}, size={55,20}
	SetVariable EV_NumEvents, value=$( df+"NumEvents" ), frame=0, fsize=fs, noedit=1
	
	y0 += 10
	
	SetVariable EV_DsplyWin, title="display win (ms):", pos={x0,y0+1*yinc}, limits={0.1,inf,5}, size={175,20}
	SetVariable EV_DsplyWin, format = "%.1f", value=$( df+"DsplyWin" ), proc=NMEventSetVariable, fsize=fs
	
	SetVariable EV_DsplyTime, title="search time (ms):", pos={x0,y0+2*yinc}, limits={0,inf,1}, size={175,20}
	SetVariable EV_DsplyTime, format = "%.1f", value=$( df+"SearchTime" ), proc=NMEventSetVariable, fsize=fs
	
	Button EV_Tzero, pos={220,y0+2*yinc-2}, title="t = 0", size={45,20}, proc=NMEventButtonSearch, fsize=fs
	
	y0 += 5
	
	Button EV_Last, pos={35,y0+ 3*yinc}, title="<", size={25,20}, proc=NMEventButtonSearch, fsize=(fs+2)
	Button EV_Next, pos={70,y0+ 3*yinc}, title=">", size={25,20}, proc=NMEventButtonSearch, fsize=(fs+2)
	Button EV_Save, pos={110,y0+ 3*yinc}, title="Save", size={45,20}, proc=NMEventButtonSearch, fsize=fs
	Button EV_Delete, pos={165,y0+ 3*yinc}, title="Delete", size={45,20}, proc=NMEventButtonSearch, fsize=fs
	Button EV_Auto, pos={220,y0+ 3*yinc}, title="Auto", size={45,20}, proc=NMEventButtonSearch, fsize=fs
	
	y0 += 10
	
	Checkbox EV_Review, title="review", pos={x0+12,y0+4*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_AutoAdvance, title="auto advance (<>,Save)", pos={x0+85,y0+4*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	
	y0 = 600
	
	Button EV_E2W, pos={x0,y0}, title="Events 2 Waves", size={110,20}, proc=NMEventButtonTable, fsize=fs
	Button EV_Histo, pos={x0+130,y0}, title="Histogram", size={100,20}, proc=NMEventButtonTable, fsize=fs
	
	UpdateEventTab()

End // MakeEventTab

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateEventTab() // update event tab display

	Variable md, dis, basedis, advanceFlag
	String tableTitle
	
	String threshstr = "threshold:", searchstr, onsetstr = "onset", peakstr = "peak", basestr = "baseline"
	String matchstr = "template matching", grp2str = "Search", nextstr = "\K(65535,0,0)>"
	String advancestr = "auto advance", posnegstr = "positive events"
	
	Variable currentChan = CurrentNMChannel()
	
	String dname = ChanDisplayWave( currentChan )
	
	CheckNMEventVariables()
	
	String tableSelect = CheckNMEventTableSelect()
	
	Variable positive = NMEventVar( "Positive" )

	Variable searchFlag = NMEventVar( "SearchFlag" )
	Variable searchMethod = NMEventVar( "SearchMethod" )
	Variable searchBgn = NMEventVar( "SearchBgn" )
	Variable searchEnd = NMEventVar( "SearchEnd" )
	
	Variable matchFlag = NMEventVar( "MatchFlag" )
	Variable matchTau1 = NMEventVar( "MatchTau1" )
	Variable matchTau2 = NMEventVar( "MatchTau2" )
	
	Variable onsetFlag = NMEventVar( "OnsetFlag" )
	Variable onsetWin = NMEventVar( "OnsetWin" )
	Variable onsetAvg = NMEventVar( "OnsetAvg" )
	Variable onsetNstdv = NMEventVar( "OnsetNstdv" )
	
	Variable peakFlag = NMEventVar( "PeakFlag" )
	Variable peakWin = NMEventVar( "PeakWin" )
	Variable peakAvg = NMEventVar( "PeakAvg" )
	Variable peakNstdv = NMEventVar( "PeakNstdv" )
	
	Variable baseFlag = NMEventVar( "BaseFlag" )
	Variable baseWin = NMEventVar( "BaseWin" )
	Variable baseDT = NMEventVar( "BaseDT" )
	
	Variable reviewFlag = NMEventVar( "ReviewFlag" )
	
	Variable FindNextAfterSaving = NMEventVar( "FindNextAfterSaving" )
	Variable SearchWaveAdvance = NMEventVar( "SearchWaveAdvance" )
	Variable ReviewWaveAdvance = NMEventVar( "ReviewWaveAdvance" )
	
	String template = NMEventStr( "Template" )
	
	Variable tbgn = EventSearchBgn()
	Variable tend = EventSearchEnd()
	
	String searchMethodString = EventSearchMethodString()
	
	advanceFlag = SearchWaveAdvance || FindNextAfterSaving || ReviewWaveAdvance
	
	if ( advanceFlag == 1 )
		
		if ( ReviewWaveAdvance == 1 )
			advancestr += " <"
		endif
		
		if ( SearchWaveAdvance == 1 )
			advancestr += " >"
		endif
		
		if ( FindNextAfterSaving == 1 )
			advancestr += " Save"
		endif
		
	endif
	
	if ( matchFlag > 0 )
		threshstr = "matched"
		onsetstr += " (auto)"
	endif
	
	if ( searchMethod < 3 )
		threshstr = "level:"
		basedis = 2
	endif
	
	if ( reviewFlag == 1 )
	
		grp2str = "Review"
		nextstr = "\K(0,0,0)>"
		dis = 2
		
		if ( reviewWaveAdvance == 1 )
			advanceFlag = 1
			advancestr = "auto advance < >"
		else
			advanceFlag = 0
			advancestr = "auto advance"
		endif
		
	endif
	
	if ( positive == 0 )
		posnegstr = "negative events"
	endif

	searchstr = "search time (t=" + num2str( searchBgn ) + ", " + num2str( searchEnd ) + " ms)"
	
	if ( baseFlag == 1 )
		basestr += " (avg=" + num2str( baseWin ) + " ms, dt=" + num2str( baseDT ) + " ms)"
	endif
	
	if ( ( onsetFlag == 1 ) && ( matchFlag == 0 ) )
		onsetstr += " (avg=" + num2str( onsetAvg ) + " ms, Nsdv=" + num2str( onsetNstdv ) + ", limit=" + num2str( onsetWin ) + " ms)"
	endif
	
	if ( peakFlag == 1 )
		peakstr += " (avg=" + num2str( peakAvg ) + " ms, Nsdv=" + num2str( peakNstdv ) + ", limit=" + num2str( peakWin ) + " ms)"
	endif
	
	if ( matchFlag == 1 )
		matchstr = "template (tau1=" + num2str( matchTau1 ) + ", tau2=" + num2str( matchTau2 ) + ")"
	elseif ( matchFlag == 2 )
		matchstr = "template (tau1=" + num2str( matchTau1 ) + ")"
	elseif ( matchFlag == 3 )
		matchstr = "template (" + template + ")"
	endif
	
	md = WhichListItem( searchMethodString, NMEventSearchMenu(), ";", 0, 0 ) + 1
	md = max( md, 1 )
	
	if ( strlen( searchMethodString ) == 0 )
		md = 1
	endif
	
	PopupMenu EV_SearchMethod, win=NMPanel, value=NMEventSearchMenu(), mode=( md )
	
	threshstr = " "
	SetVariable EV_Threshold, win=NMPanel, title=threshstr
	
	Checkbox EV_PosNegCheck, win=NMPanel, value=1, title=posnegstr
	Checkbox EV_SearchCheck, win=NMPanel, value=BinaryCheck(searchFlag ), title=searchstr
	Checkbox EV_BaseCheck, win=NMPanel, value=BinaryCheck( baseFlag ), title=basestr, disable=basedis
	Checkbox EV_OnsetCheck, win=NMPanel, value=BinaryCheck( onsetFlag ), title=onsetstr
	Checkbox EV_PeakCheck, win=NMPanel, value=BinaryCheck( peakFlag ), title=peakstr
	Checkbox EV_MatchCheck, win=NMPanel, value=BinaryCheck( matchFlag ), title=matchstr
	
	Button EV_Match, win=NMPanel, disable=( !matchFlag )
	
	GroupBox EV_Grp2, win=NMPanel, title=grp2str
	
	md = WhichListItem( tableSelect, NMEventTableMenu(), ";", 0, 0 ) + 1
	md = max( md, 1 )
	
	if ( strlen( tableSelect ) == 0 )
		md = 1
	endif
	
	PopupMenu EV_TableMenu, win=NMPanel, value=NMEventTableMenu(), mode=( md )
	
	SetVariable EV_DsplyTime, win=NMPanel, limits={searchBgn,searchEnd,1}
	
	Button EV_Next, win=NMPanel, title=nextstr
	Button EV_Save, win=NMPanel, disable=dis
	Button EV_Auto, win=NMPanel, disable=dis
	
	Checkbox EV_Review, win=NMPanel, value=reviewFlag
	
	Checkbox EV_AutoAdvance, win=NMPanel, value=advanceFlag
	Checkbox EV_AutoAdvance, win=NMPanel, title=advancestr
	
	EventCount()
	
End // UpdateEventTab

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSearchMenu()

	Variable positive = NMEventVar( "Positive" )
	Variable matchFlag = NMEventVar( "MatchFlag" )

	if ( NMEventVar( "MatchFlag" ) > 0 )
	
		if ( positive == 1 )
			return "level cross (+slope);"
		else
			return "level cross (-slope);"
		endif
		
	else
	
		if ( positive == 1 )
			return "threshold > baseline;level detect (+slope);"
		else
			return "threshold < baseline;level detect (-slope)"
		endif
		
	endif

End // NMEventSearchMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableMenu()

	if ( NMEventTableOldExists() == 1 )
		return "Event Table;---;" + NMEventTableOldList( CurrentNMChannel() ) + "---;New;Clear;kill;"
	else
		return "Event Table;---;" + CurrentNMEventTableSelect() + ";---;Clear;"
	endif

End // EventTableMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	EventCall( fxn, "" )
	
End // NMEventButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventButtonSearch( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	EventSearchCall( fxn )
	
End // NMEventButtonSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventButtonTable( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	EventTableCall( fxn )
	
End // NMEventButtonTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	EventCall( fxn, varStr )

End // NMEventSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName
	Variable checked
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	EventCall( fxn, num2istr( checked ) )

End // NMEventCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventPopupSearch( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	Variable method = EventSearchMethodNumber( popStr )
	
	if ( numtype( method ) == 0 )
		EventCall( fxn, num2str( method ) )
	else
		UpdateEventTab()
	endif
	
End // NMEventPopupSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventPopupTable( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	strswitch( popStr )
	
		case "Event Table":
		case "---":
			UpdateEventTab()
			break
		
		
		case "New":
		case "Clear":
		case "Kill":
			EventTableCall( popStr )
			break
			
		default:
			NMEventTableSelectCall( popStr )
			
	endswitch
	
End // NMEventPopupTable

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Set Global Variables, Strings and Waves
//
//****************************************************************
//****************************************************************
//****************************************************************

Function EventCall( fxn, select )
	String fxn, select
	
	Variable format, snum = str2num( select )
	
	strswitch( fxn )
	
		case "SearchMethod":
			return EventSearchMethodCall( snum )
	
		case "Threshold":
			return EventThresholdCall( snum )
			
		case "PosNegCheck":
			return NMEventPositiveCall()
	
		case "SearchCheck":
			return EventSearchWindowCall( snum )
	
		case "BaseCheck":
			return EventBslnCall( snum )
			
		case "OnsetCheck":
			return EventOnsetCall( snum )
			
		case "PeakCheck":
			return EventPeakCall( snum )
			
		case "MatchCheck":
			return MatchTemplateOnCall( snum )
			
		case "Match":
			MatchTemplateCall( 1 )
			EventDisplay( 1 )
			break
			
		case "DsplyWin":
			return EventDisplayWinCall( snum )
			
		case "DsplyTime":
			return EventSearchTimeCall( snum )
			
		case "Review":
			NMEventReviewCall( snum )
			break
			
		case "AutoAdvance":
			EventAutoAdvanceCall()
			break
			
		default:
			NMDoAlert( "EventCall: unrecognized function call: " + fxn )
	
	endswitch
	
End // EventCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchMethodCall( method )
	Variable method
	
	NMCmdHistory( "EventSearchMethod", NMCmdNum( method, "" ) )
	
	return EventSearchMethod( method )
	
End // EventSearchMethodCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchMethod( method )
	Variable method
	
	switch( method )
		case 1: // level detect (+slope)
		case 2: // level detect (-slope)
		case 3: // threshold > baseline
		case 4: //  threshold < baseline
			break
		default:
			method = 3
	endswitch

	SetNMEventVar( "SearchMethod", method )
	UpdateEventTab()
	
	return method
	
End // EventSearchMethod

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventSearchMethodString()

	Variable searchMethod = NMEventVar( "SearchMethod" )

	switch( searchMethod )
		case 1:
			return "level detect (+slope)"
		case 2:
			return "level detect (-slope)"
		case 3:
			return "threshold > baseline"
		case 4:
			return "threshold < baseline"
		default:
			return ""
	endswitch

End // EventSearchMethodString

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchMethodNumber( methodStr )
	String methodStr
	
	String thisfxn = "EventSearchMethodNumber"
	
	strswitch( methodStr )
		case "level detect (+slope)":
			return 1
		case "level detect (-slope)":
			return 2
		case "threshold > baseline":
			return 3
		case "threshold < baseline":
			return 4
		default:
			return NMError( 20, thisfxn, "methodStr", methodStr )
	endswitch
	
End // EventSearchMethodNumber

//****************************************************************
//****************************************************************
//****************************************************************

Function EventThresholdCall( threshLevel )
	Variable threshLevel
	
	NMCmdHistory( "EventThreshold", NMCmdNum( threshLevel, "" ) )
	
	return EventThreshold( threshLevel )
	
End // EventThresholdCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventThreshold( threshLevel )
	Variable threshLevel // event detection threshold level
	
	String thisfxn = "EventThreshold"
	
	Variable searchMethod = NMEventVar( "SearchMethod" )
	Variable matchFlag = NMEventVar( "MatchFlag" )
	
	if ( numtype( threshLevel ) > 0 )
		return NMError( 10, thisfxn, "threshLevel", num2str( threshLevel ) )
	endif
	
	if ( MatchFlag == 1 )
	
		switch( searchMethod )
		
			case 1:
			case 2:
				SetNMEventVar( "MatchLevel", threshLevel )
				break
				
			default:
				return NMError( 10, thisfxn, "searchMethod", num2str( searchMethod ) )
				
		endswitch

	else
	
		switch( searchMethod )
		
			case 1:
			case 2:
				SetNMEventVar( "Level", threshLevel )
				break
				
			case 3:
			case 4:
				SetNMEventVar( "Thrshld", threshLevel )
				break
				
			default:
				return NMError( 10, thisfxn, "searchMethod", num2str( searchMethod ) )
		
		endswitch
	
	endif
	
	return threshLevel
	
End // EventThreshold

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventThresholdLevel()

	Variable v

	Variable positive = NMEventVar( "Positive" )
	Variable searchMethod = NMEventVar( "SearchMethod" )
	Variable matchFlag = NMEventVar( "MatchFlag" )
	
	String cdname = ChanDisplayWave( CurrentNMChannel() )
	
	if ( MatchFlag == 1 )
	
		switch( searchMethod )
		
			case 1:
			case 2:
			
				v = NMEventVar( "MatchLevel" )
				
				if ( numtype( v )== 0 )
					return v
				endif
				
			default:
			
				if ( positive == 1 )
					return 4
				else
					return -4
				endif
		
		endswitch
		
	else
	
		switch( searchMethod )
		
			case 1:
			case 2:
			
				v = NMEventVar( "Level" )
				
				if ( numtype( v ) > 0 )
				
					WaveStats /Q $cdname
					
					if ( positive == 1 )
						v = V_avg + 0.5 * abs( V_avg - V_max )
					else
						v = V_avg - 0.5 * abs( V_avg - V_min )
					endif
					
					if ( abs( v ) > 1 )
						v = floor( v )
					endif
				
				endif
				
				return v
				
			case 3:
			case 4:
			
				v = abs( NMEventVar( "Thrshld" ) )
				
				if ( numtype( v ) == 0 )
					return v
				else
					return 10
				endif
		
		endswitch
	
	endif
	
	return 10

End // NMEventThresholdLevel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventPositiveCall()

	Variable on = BinaryInvert( NMEventVar( "Positive" ) )
	
	NMCmdHistory( "NMEventPositive", NMCmdNum( on, "" ) )
	
	return NMEventPositive( on )
	
End // NMEventPositiveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventPositive( on )
	Variable on // ( 0 ) search for negative events ( 1 ) search for positive events
	
	String thisfxn = "NMEventPositive"
	
	Variable searchMethod = NMEventVar( "SearchMethod" )
	
	on = BinaryCheck( on )
	
	SetNMEventVar( "Positive", on )
	
	switch( searchMethod )
	
		case 1:
			SetNMEventVar( "SearchMethod", 2 )
			break
			
		case 2:
			SetNMEventVar( "SearchMethod", 1 )
			break
			
		case 3:
			SetNMEventVar( "SearchMethod", 4 )
			break
			
		case 4:
			SetNMEventVar( "SearchMethod", 3 )
			break
			
		default:
			return NMError( 10, thisfxn, "searchMethod", num2str( searchMethod ) )
	
	endswitch
	
	UpdateEventTab()
	
	return on
	
End // NMEventPositive

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchWindowCall( on )
	Variable on

	String vlist = ""
	String cdname = ChanDisplayWave( CurrentNMChannel() )
	
	Variable tbgn = NMEventVar( "SearchBgn" )
	Variable tend = NMEventVar( "SearchEnd" )
	
	if ( on == 1 )
	
		if ( numtype( tbgn ) > 0 ) 
			tbgn = leftx( $cdname )
		endif
		
		if ( numtype( tend ) > 0 )
			tend = rightx( $cdname )
		endif
		
		Prompt tbgn, "time window begin (ms):"
		Prompt tend, "time window end (ms):"
		DoPrompt "Event Search or Review", tbgn, tend
		
		if ( V_flag == 1 )
			UpdateEventTab()
			return 0
		endif
		
	else
	
		tbgn = -inf
		tend = inf
	
	endif
	
	vlist = NMCmdNum( on, vlist )
	vlist = NMCmdNum( tbgn, vlist )
	vlist = NMCmdNum( tend, vlist )
	NMCmdHistory( "EventSearchWindow", vlist )
	
	return EventSearchWindow( on, tbgn, tend )

End // EventSearchWindowCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchWindow( on, tbgn, tend )
	Variable on // ( 0 ) off ( 1 ) on
	Variable tbgn, tend // search time begin and end, ( -inf / inf ) for all possible time
	
	on = BinaryCheck( on )
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	SetNMEventVar( "SearchFlag", on )
	SetNMEventVar( "SearchBgn", tbgn )
	SetNMEventVar( "SearchEnd", tend )
	
	UpdateEventTab()
	
	return on

End // EventSearchWindow

//****************************************************************
//****************************************************************
//****************************************************************

Function EventBslnCall( on )
	Variable on
	
	Variable baseWin = Nan, baseDT = Nan
	String vlist = ""
	
	Variable matchFlag = NMEventVar( "MatchFlag" )
	Variable searchMethod = NMEventVar( "SearchMethod" )
	
	if ( matchFlag == 1 )
		on = 0
	endif
	
	if ( ( on == 1 ) || ( searchMethod > 2 ) )
	
		on = 1
		baseWin = NMEventVar( "BaseWin" )
		baseDT = NMEventVar( "BaseDT" )
		
		Prompt baseWin, "average window (ms):"
		Prompt baseDT, "delta time (dt) between mid-baseline and threshold crossing (ms):"
		DoPrompt "Baseline Parameters", baseWin, baseDT
		
		if ( V_flag == 1 )
			on = 0
			baseWin = Nan
			baseDT = Nan
		endif
	
	endif
	
	vlist = NMCmdNum( on, vlist )
	vlist = NMCmdNum( baseWin, vlist )
	vlist = NMCmdNum( baseDT, vlist )
	NMCmdHistory( "EventBsln", vlist )
	
	return EventBsln( on, baseWin, baseDT )
	
End // EventBslnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventBsln( on, baseWin, baseDT )
	Variable on // ( 0 ) off ( 1 ) on
	Variable baseWin // baseline average window (ms)
	Variable baseDT // delta time between mid-baseline and threshold crossing (ms)
	
	String thisfxn = "EventBsln"
	
	on = BinaryCheck( on )
	
	if ( on == 1 )
		
		if ( ( numtype( baseWin ) == 0 ) && ( baseWin > 0 ) )
			SetNMEventVar( "BaseWin", baseWin )
		else
			return NMError( 10, thisfxn, "baseWin", num2str( baseWin ) )
		endif
		
		if ( ( numtype( baseDT ) == 0 ) && ( baseDT > 0 ) )
			SetNMEventVar( "BaseDT", baseDT )
		else
			return NMError( 10, thisfxn, "baseDT", num2str( baseDT ) )
		endif
			
	endif
			
	SetNMEventVar( "BaseFlag", on )
	
	NMEventTableManager( CurrentNMEventTableName(), "update" )
	UpdateEventTab()
	
	return on
			
End // EventBsln

//****************************************************************
//****************************************************************
//****************************************************************

Function EventOnsetCall( on )
	Variable on
	
	Variable avgWin = Nan, nSTDV = Nan, searchLimit = Nan
	String vlist = ""
	
	Variable matchFlag = NMEventVar( "MatchFlag" )
	
	if ( ( on == 1 ) && ( matchFlag == 0 ) )
			
		avgWin = NMEventVar( "OnsetAvg" )
		nSTDV = NMEventVar( "OnsetNstdv" )
		searchLimit = NMEventVar( "OnsetWin" )
		
		Prompt avgWin, "sliding average window (ms):"
		Prompt nSTDV, "define onset as number of stdv's above average:"
		Prompt searchLimit, "search window limit (ms):"
		DoPrompt "Onset Time Search", avgWin, nSTDV, searchLimit
		
		if ( V_flag == 1 )
			on = 0
			avgWin = Nan
			nSTDV = Nan
			searchLimit = Nan
		endif
		
	endif
	
	vlist = NMCmdNum( on, vlist )
	vlist = NMCmdNum( avgWin, vlist )
	vlist = NMCmdNum( nSTDV, vlist )
	vlist = NMCmdNum( searchLimit, vlist )
	NMCmdHistory( "EventOnset", vlist )

	return EventOnset( on, avgWin, nSTDV, searchLimit )

End // EventOnsetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventOnset( on, avgWin, nSTDV, searchLimit )
	Variable on // ( 0 ) off ( 1 ) on
	Variable avgWin // sliding average window (ms)
	Variable nSTDV// number of stdv's above average
	Variable searchLimit // search window limit (ms)
	
	String thisfxn = "EventOnset"
	
	on = BinaryCheck( on )
	
	if ( on == 1 )
		
		if ( ( numtype( avgWin ) == 0 ) && ( avgWin > 0 ) )
			SetNMEventVar( "OnsetAvg", avgWin )
		else
			return NMError( 10, thisfxn, "avgWin", num2str( avgWin ) )
		endif
		
		if ( ( numtype( nSTDV ) == 0 ) && ( nSTDV > 0 ) )
			SetNMEventVar( "OnsetNstdv", nSTDV )
		else
			return NMError( 10, thisfxn, "nSTDV", num2str( nSTDV ) )
		endif
		
		if ( ( numtype( searchLimit ) == 0 ) && ( searchLimit > 0 ) )
			SetNMEventVar( "OnsetWin", searchLimit )
		else
			return NMError( 10, thisfxn, "searchLimit", num2str( searchLimit ) )
		endif
			
	endif
	
	SetNMEventVar( "OnsetFlag", on )
	
	NMEventTableManager( CurrentNMEventTableName(), "update" )
	UpdateEventTab()
	
	return on
			
End // EventOnset

//****************************************************************
//****************************************************************
//****************************************************************

Function EventPeakCall( on )
	Variable on
	
	Variable avgWin = Nan, nSTDV = Nan, searchLimit = Nan
	String vlist = ""
	
	if ( on == 1 )
			
		avgWin = NMEventVar( "PeakAvg" )
		nSTDV = NMEventVar( "PeakNstdv" )
		searchLimit = NMEventVar( "PeakWin" )
		
		Prompt avgWin, "sliding average window (ms):"
		Prompt nSTDV, "define peak as number of stdv's above average:"
		Prompt searchLimit, "search window limit (ms):"
		DoPrompt "Peak Time Search", avgWin, nSTDV, searchLimit
		
		if ( V_flag == 1 )
			on = 0
			avgWin = Nan
			nSTDV = Nan
			searchLimit = Nan
		endif
		
	endif
	
	vlist = NMCmdNum( on, vlist )
	vlist = NMCmdNum( avgWin, vlist )
	vlist = NMCmdNum( nSTDV, vlist )
	vlist = NMCmdNum( searchLimit, vlist )
	NMCmdHistory( "EventPeak", vlist )
			
	return EventPeak( on, avgWin, nSTDV, searchLimit )
	
End // EventPeakCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventPeak( on, avgWin, nSTDV, searchLimit )
	Variable on // ( 0 ) off ( 1 ) on
	Variable avgWin // sliding average window (ms)
	Variable nSTDV // number of stdv's above average
	Variable searchLimit // search window limit (ms)
	
	String thisfxn = "EventPeak"
	
	on = BinaryCheck( on )
	
	if ( on == 1 )
			
		if ( ( numtype( avgWin ) == 0 ) && ( avgWin > 0 ) )
			SetNMEventVar( "PeakAvg", avgWin )
		else
			return NMError( 10, thisfxn, "avgWin", num2str( avgWin ) )
		endif
		
		if ( ( numtype( nSTDV ) == 0 ) && ( nSTDV > 0 ) )
			SetNMEventVar( "PeakNstdv", nSTDV )
		else
			return NMError( 10, thisfxn, "nSTDV", num2str( nSTDV ) )
		endif
		
		if ( ( numtype( searchLimit ) == 0 ) && ( searchLimit > 0 ) )
			SetNMEventVar( "PeakWin", searchLimit )
		else
			return NMError( 10, thisfxn, "searchLimit", num2str( searchLimit ) )
		endif
			
	endif
	
	SetNMEventVar( "PeakFlag", on )
	
	NMEventTableManager( CurrentNMEventTableName(), "update" )
	UpdateEventTab()
	
	return on
			
End // EventPeak

//****************************************************************
//****************************************************************
//****************************************************************

Function EventDisplayWinCall( win ) // display window size
	Variable win
	
	NMCmdHistory( "EventDisplayWin", NMCmdNum( win, "" ) )
	
	return EventDisplayWin( win )
	
End // EventDisplayWinCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventDisplayWin( win )
	Variable win // display window size ( ms )
	
	if ( ( numtype( win ) > 0 ) || ( win <= 0 ) )
		win = 50
	endif
	
	SetNMEventVar( "DsplyWin", win )
	
	EventCursors( 1 )
	
	return win
	
End // EventDisplayWin

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchTimeCall( t )
	Variable t
	
	NMCmdHistory( "EventSearchTime", NMCmdNum( t, "" ) )
	
	return EventSearchTime( t )
	
End // EventSearchTimeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchTime( t ) // set current search time
	Variable t // current time ( ms )
	
	if ( numtype( t ) > 0 )
		t = leftx( $ChanDisplayWave( CurrentNMChannel() ) )
	endif
	
	SetNMEventVar( "SearchTime", t )
	
	SetNMEventVar( "ThreshX", t )
	SetNMEventVar( "ThreshY", Nan )
	
	SetNMEventVar( "OnsetX", t )
	SetNMEventVar( "OnsetY", Nan )
	SetNMEventVar( "PeakX", t )
	SetNMEventVar( "PeakY", Nan )
	
	SetNMwave( NMEventDisplayWaveName( "ThisT" ), -1, Nan )
	SetNMwave( NMEventDisplayWaveName( "ThisY" ), -1, Nan )
	SetNMwave( NMEventDisplayWaveName( "BaseT" ), -1, Nan )
	SetNMwave( NMEventDisplayWaveName( "BaseY" ), -1, Nan )
	
	EventCursors( 1 )
	
	return t
	
End // EventSearchTime

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventReviewCall( on )
	Variable on

	NMCmdHistory( "NMEventReview", NMCmdNum( on, "" ) )
	
	return NMEventReview( on )

End // NMEventReviewCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventReview( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	on = BinaryCheck( on )
	
	SetNMEventVar( "ReviewFlag", on )
	
	UpdateEventTab()
	
	return on

End // NMEventReview

//****************************************************************
//****************************************************************
//****************************************************************

Function EventAutoAdvanceCall()

	Variable findNextSelect, searchSelect, reviewSelect
	
	Variable reviewFlag = NMEventVar( "ReviewFlag" )
	
	Variable findNext = NMEventVar( "FindNextAfterSaving" )
	Variable search = NMEventVar( "SearchWaveAdvance" )
	Variable review = NMEventVar( "ReviewWaveAdvance" )
	
	findNextSelect = findNext + 1
	searchSelect = search + 1
	reviewSelect = review + 1
	
	Prompt findNextSelect, "Automatically search for next event after saving?", popup "no;yes;"
	Prompt searchSelect, "Automatically advance to next/previous wave when searching?", popup "no;yes;"
	Prompt reviewSelect, "Automatically advance to next/previous wave when reviewing?", popup "no;yes;"
	
	if ( reviewFlag == 0 )
		DoPrompt "Event Auto Advance", findNextSelect, searchSelect, reviewSelect
	else
		DoPrompt "Event Auto Advance", reviewSelect
	endif

	if ( V_flag == 1 )
		UpdateEventTab()
		return 0 // cancel
	endif
	
	findNextSelect -= 1
	searchSelect -= 1
	reviewSelect -= 1
	
	if ( findNextSelect != findNext )
		NMCmdHistory( "NMEventFindNextAfterSaving", NMCmdNum( findNextSelect, "" ) )
		NMEventFindNextAfterSaving( findNextSelect )
	endif
	
	if ( searchSelect != search )
		NMCmdHistory( "NMEventSearchWaveAdvance", NMCmdNum( searchSelect, "" ) )
		NMEventSearchWaveAdvance( searchSelect )
	endif
	
	if ( reviewSelect != review )
		NMCmdHistory( "NMEventReviewWaveAdvance", NMCmdNum( reviewSelect, "" ) )
		NMEventReviewWaveAdvance( reviewSelect )
	endif
	
	return 0
	
End // EventAutoAdvanceCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventFindNextAfterSaving( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	on = BinaryCheck( on )
	
	SetNMEventVar( "FindNextAfterSaving", on )
	
	UpdateEventTab()
	
	return on

End // NMEventFindNextAfterSaving

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventSearchWaveAdvance( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	on = BinaryCheck( on )
	
	SetNMEventVar( "SearchWaveAdvance", on )
	
	UpdateEventTab()
	
	return on

End // NMEventSearchWaveAdvance

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventReviewWaveAdvance( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	on = BinaryCheck( on )
	
	SetNMEventVar( "ReviewWaveAdvance", on )
	
	UpdateEventTab()
	
	return on

End // NMEventReviewWaveAdvance

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Template Matching Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateOnCall( on )
	Variable on
	
	NMCmdHistory( "MatchTemplateOn", NMCmdNum( on, "" ) )
	
	return MatchTemplateOn( on )
	
End // MatchTemplateOnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateOn( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	Variable searchMethod, level
	
	Variable positive = NMEventVar( "Positive" )
	
	if ( on == 1 )
	
		on = MatchTemplateSelect()
		
		if ( on > 0 )
		
			if ( positive == 1 )
				SetNMEventVar( "SearchMethod", 1 )
			else
				SetNMEventVar( "SearchMethod", 2 )
			endif
		
			MatchTemplateCall( 0 )
			
		endif
		
	else
	
		MatchTemplateKill()
		on = 0
		
	endif
	
	SetNMEventVar( "MatchFlag", on )
	
	EventDisplay( 1 )
	UpdateEventTab()
	
	return on
	
End // MatchTemplateOn

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateSelect()

	Variable v1, v2, v3, v4, v5, dx
	String tname, vlist = ""
	
	Variable currentChan = CurrentNMChannel()

	Prompt v1, "choose template:", popup "2-exp;alpha wave;your wave;"
	DoPrompt "Template Matching Search", v1
	
	if ( V_flag == 1 )
		return 0
	endif
	
	v2 = NMEventVar( "MatchTau1" )
	v3 = NMEventVar( "MatchTau2" )
	v4 = NMEventVar( "MatchBsln" )
	v5 = NMEventVar( "MatchWform" )
	
	tname = NMEventStr( "Template" )
	
	if ( numtype( v4 ) > 0 )
		v4 = NMEventVar( "BaseWin" )
	endif
	
	Prompt v2, "rise time (ms):"
	Prompt v3, "decay time (ms):"
	Prompt v4, "baseline time before waveform (ms):"
	Prompt v5, "template waveform time (ms):"
	
	switch( v1 )
	
		case 1:
		
			DoPrompt "Create 2-exp Template", v2, v3, v4, v5
			
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			SetNMEventVar( "MatchTau1", v2 )
			SetNMEventVar( "MatchTau2", v3 )
			SetNMEventVar( "MatchBsln", v4 )
			SetNMEventVar( "MatchWform", v5 )
			break
		
		case 2:
	
			Prompt v2, "tau (ms):"
			DoPrompt "Create Alpha-Wave Template", v2, v4, v5
			
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			v3 = 0
			SetNMEventVar( "MatchTau1", v2 )
			SetNMEventVar( "MatchBsln", v4 )
			SetNMEventVar( "MatchWform", v5 )
			break
		
		case 3:
	
			v4 = 0
			Prompt tname, "choose your pre-defined template wave:", popup WaveList( "*", ";", "Text:0" )
			Prompt v4, "baseline of your pre-defined template wave (ms):"
			DoPrompt "Template Matching Search", tname, v4
			
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			SetNMEventVar( "MatchBsln", v4 )
			
			WaveStats /Q/Z $tname
			
			if ( V_max > 1 )
				NMDoAlert( "Match Template Warning: your template waveform should be normalized to one and have zero baseline." )
			endif
			
			break
		
	endswitch
	
	if ( ( v1 == 1 ) || ( v1 == 2 ) )
	
		dx = deltax( $ChanDisplayWave( currentChan ) )
		
		vlist = NMCmdNum( v1, vlist )
		vlist = NMCmdNum( v2, vlist )
		vlist = NMCmdNum( v3, vlist )
		vlist = NMCmdNum( v4, vlist )
		vlist = NMCmdNum( v5, vlist )
		vlist = NMCmdNum( dx, vlist )
		NMCmdHistory( "MatchTemplateMake", vlist )
		
		tname = MatchTemplateMake( v1, v2, v3, v4, v5, dx )
		
	endif
	
	if ( strlen( tname ) > 0 )
		SetNMEventVar( "MatchFlag", v1 )
		SetNMEventStr( "Template", tname )
	endif
	
	return v1

End // MatchTemplateSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S MatchTemplateMake( fxn, tau1, tau2, bslnTime, wformTime, dt )
	Variable fxn // ( 1 ) 2-exp ( 2 ) alpha
	Variable tau1 // first exp time constant, or alpha ( ms )
	Variable tau2 // second exp time constant ( ms )
	Variable bslnTime // baseline time ( ms )
	Variable wformTime // waveform time ( ms )
	Variable dt // time step ( ms )
	
	String thisfxn = "MatchTemplateMake"
	
	if ( ( numtype( tau1 ) > 0 ) || ( tau1 <= 0 ) )
		return NMErrorStr( 10, thisfxn, "tau1", num2str( tau1 ) )
	endif
	
	if ( ( numtype( tau2 ) > 0 ) || ( tau2 <= 0 ) )
		return NMErrorStr( 10, thisfxn, "tau2", num2str( tau2 ) )
	endif
	
	if ( ( numtype( bslnTime ) > 0 ) || ( bslnTime < 0 ) )
		return NMErrorStr( 10, thisfxn, "bslnTime", num2str( bslnTime ) )
	endif
	
	if ( ( numtype( wformTime ) > 0 ) || ( wformTime <= 0 ) )
		return NMErrorStr( 10, thisfxn, "wformTime", num2str( wformTime ) )
	endif
	
	if ( ( numtype( dt ) > 0 ) || ( dt <= 0 ) )
		return NMErrorStr( 10, thisfxn, "dt", num2str( dt ) )
	endif

	String wName = EventDF() + "TemplateWave"
	
	Make /D/O/N=( ( bslnTime + wformTime ) / dt ) $wName
	SetScale /P x, 0, dt, $wName
	
	Wave pulse = $wName
	
	if ( fxn == 2 ) // alpha
		pulse = ( x - bslnTime )*exp( ( bslnTime - x )/tau1 )
	else // 2-exp
		pulse = ( 1 - exp( ( bslnTime - x )/tau1 ) ) * exp( ( ( bslnTime - x ) )/tau2 )
	endif
	
	pulse[ 0, x2pnt( pulse, bslnTime ) ] = 0
	
	Wavestats /Q/Z pulse
	pulse /= v_max
	
	NMPlotWavesOffset( "EV_Tmplate", "Event Template", "msec", "", "", wName, 0, 0, 0, 0 )
	
	NMHistory( "Created Template Wave " + NMQuotes( wName ) )

	return wName

End // MatchTemplateMake

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateCall( force )
	Variable force
	
	String vlist = ""
	
	Variable matchFlag = NMEventVar( "MatchFlag" )
	
	String Template = NMEventStr( "Template" )
	
	String wName = CurrentNMWaveName()
	String tname = "EV_" + wName + "_matched"
	String mtname = NMEventDisplayWaveName( "MatchTmplt" )
	
	if ( ( matchFlag == 0 ) || ( WaveExists( $wName ) == 0 ) )
		return 0
	endif
	
	if ( force == 0 )
	
		if ( WaveExists( $tname ) == 1 )
			Duplicate /O $tname $mtname
			return 0
		endif
		
		//DoAlert 2, "Match template to " + NMQuotes( wName ) + "? ( This may take a few minutes... )"
		
		//if ( V_Flag != 1 )
		//	if ( WaveExists( $mtname ) == 1 )
		//		Wave temp = $mtname
		//		temp = Nan
		//	endif
		//	return 0
		//endif
		
	endif
	
	vlist = NMCmdStr( wName, vlist )
	vlist = NMCmdStr( Template, vlist )
	NMCmdHistory( "MatchTemplateCompute", vlist )

	MatchTemplateCompute( wName, Template )
	
	Duplicate /O $mtname $tname

End // MatchTemplateCall

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateKill()
	Variable icnt

	String wName, wlist = WaveList( "*_matched",";","" )
	
	for ( icnt = 0; icnt < ItemsInList( wlist ); icnt += 1 )
		wName = StringFromList( icnt, wlist )
		KillWaves /Z $wName
	endfor

End // MatchTemplateKill

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateCompute( wName, templateName ) // match template to wave
	String wName // wave name
	String templateName // template name
	
	String oName, thisfxn = "MatchTemplateCompute"
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	if ( WaveExists( $templateName ) == 0 )
		return NMError( 1, thisfxn, "templateName", templateName )
	endif
	
	if ( deltax( $wName ) != deltax( $templateName ) )
		return NMError( 90, thisfxn, "template wave delta-x does not match that of wave to measure", "" )
	endif
	
	if ( numtype( sum( $templateName, -inf, inf ) ) > 0 )
	
		DoAlert 2, "Match Template Alert: template wave contains one or more non-numbers (NANs). Do you want NM to convert these to zero?"
		
		if ( V_flag != 1 )
			return -1
		endif
		
		NMReplaceValue( Nan, 0, templateName )
		
	endif
	
	SetNeuroMaticStr( "ProgressStr", "Matching Template..." )
	
	CallProgress( -1 )
	DoUpdate
	
	oName = NMEventDisplayWaveName( "MatchTmplt" )
	
	Duplicate /O $wName $oName
	
	Execute /Z "MatchTemplate /C " + templateName + " " + oName
	
	if ( V_flag != 0 )
	
		Execute /Z "MatchTemplate /C " + templateName + ", " + oName // NEW FORMAT
		
		if ( V_flag != 0 )
			NMError( 90, thisfxn, "MatchTemplate XOP execution error", "" )
		endif
		
	endif
	
	CallProgress( 1 )
	
	if ( V_flag > 0 )
		NMDoAlert("Match Template XOP error.")
	endif
	
End // MatchTemplateCompute

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Event Search Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchCall( func )
	String func
	
	Variable v1
	
	Variable currentWave = CurrentNMWave()
	
	Variable threshX = NMEventVar( "ThreshX" )
	Variable reviewFlag = NMEventVar( "ReviewFlag" )
	Variable FindNextAfterSaving = NMEventVar( "FindNextAfterSaving" )

	strswitch( func )
	
		case "Next":
		
			if ( reviewFlag == 1 )
				EventRetrieveNextCall()
			else
				EventFindNextCall()
			endif
			
			break
			
		case "Last":
			EventRetrieveLastCall()
			break
			
		case "Save":
			EventSaveCall()
			break
			
		case "Delete":
			EventDelete( currentWave, threshX )
			break
		
		case "All":
		case "Auto":
			EventFindAllCall()
			break
			
		case "T0":
		case "Tzero":
			v1 = EventSearchBgn()
			NMCmdHistory( "EventSearchTime", NMCmdNum( v1, "" ) )
			EventSearchTime( v1 )
			break
			
		default:
			NMError( 20, "EventSearchCall", "func", func )
			
	endswitch
	
	Dowindow /F NMPanel
	
End // EventSearchCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveNextCall()

	Variable next, alert, waveNum
	
	Variable numWaves = NMNumWaves()
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	Variable t = NMEventVar( "SearchTime" )
	Variable auto = NMEventVar( "ReviewWaveAdvance" )
	
	next = EventRetrieveNext( currentWave, t )
			
	if ( ( auto == 1 ) && ( next < 0 ) )
	
		waveNum = EventRetrieveNextWaveNum( currentWave )
		
		if ( ( waveNum >= 0 ) && ( waveNum < numWaves ) )
		
			NMCurrentWaveSet( waveNum )
			next = EventRetrieveNext( waveNum, -inf )
			
			if ( next < 0 )
				alert = 1
			endif
			
		else
		
			alert = 1
			
		endif
			
	endif
	
	if ( alert == 1 )
		NMDoAlert( "There are no more saved events." )
	endif
	
	return next
				
End // EventRetrieveNextCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveLastCall()

	variable last, alert, waveNum
	
	Variable numWaves = NMNumWaves()
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	Variable t = NMEventVar( "SearchTime" )
	Variable auto = NMEventVar( "ReviewWaveAdvance" )
	
	last = EventRetrieveLast( currentWave, t )

	if ( ( auto == 1 ) && ( last < 0 ) )
				
		waveNum = EventRetrieveLastWaveNum( currentWave )
			
		if ( ( waveNum >= 0 ) && ( waveNum < numWaves ) )
		
			NMCurrentWaveSet( waveNum )
			last = EventRetrieveLast( waveNum, inf )
			
			if ( last < 0 )
				alert = 1
			endif
			
		else
		
			alert = 1
			
		endif
		
	endif
	
	if ( alert == 1 )
		NMDoAlert( "There are no more saved events." )
	endif

	return last
	
End // EventRetrieveLastCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindNextCall()

	Variable next, alert, waveNum
	
	Variable numWaves = NMNumWaves()
	Variable currentChan = CurrentNMChannel()
	
	Variable auto = NMEventVar( "SearchWaveAdvance" )
	
	next = EventFindNext( 1 )

	if ( next == -1 )
				
		if ( auto == 1 )
		
			waveNum = EventFindNextActiveWave( currentChan, CurrentNMWave() )
			
			if ( ( waveNum >= 0 ) && ( waveNum < numWaves ) )
			
				NMCurrentWaveSet( waveNum )
				EventSearchTime( EventSearchBgn() )
				next = EventFindNext( 1 )
				
				if ( next == -1 )
					alert = 1
				endif
				
			else
			
				alert = 1
				
			endif
			
		else
			
			alert = 1
			
		endif
		
	endif
	
	if ( alert == 1 )
		
		NMDoAlert( "Found no more events in " + CurrentNMWaveName() )
		
		waveNum = EventFindNextActiveWave( currentChan, -1 )
		
		if ( waveNum < 0 )
			NMEventReviewAlert()
		endif
		
	endif
	
	return next

End // EventFindNextCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventReviewAlert()

	if ( NMEventVar( "ReviewAlert" ) == 1 )
	
		NMDoAlert( "To review the current event detection results, click the " + NMQuotes( "review" ) + " checkbox." )
		
		SetNMEventVar( "ReviewAlert", 0 ) // alert once
		
	endif
	
End // NMEventReviewAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoEvent() // called when user changes CurrentWave
	
	EventSearchTime( NMEventVar( "SearchBgn" ) )
	UpdateEventDisplay()
	MatchTemplateCall( 0 )

End // AutoEvent

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindAllCall()

	Variable wselect = 1
	String vlist = ""

	String wlist = NMWaveSelectList( CurrentNMChannel() )
	Variable nwaves = ItemsInList( wlist )
	
	Variable tableNum = NMEventTableOldNum()
	
	if ( nwaves == 0 )
		NMDoAlert( "No waves selected." )
		return 0
	endif

	Variable tselect = NMEventVar( "AutoTSelect" )
	Variable tzero = 1+ NMEventVar( "AutoTZero" )
	Variable dsply = 1 + NMEventVar( "AutoDsply" )
	
	if ( EventCount() == 0 )
		tselect = 2 // current table
	endif
	
	Prompt tselect, "save events where?", popup "new table;current table;"
	Prompt tzero, "search from time zero?", popup "no;yes;"
	Prompt dsply, "display results while detecting?", popup "no;yes;"
	
	if ( tableNum == -1 )
	
		DoPrompt "Auto Event Detection", tzero, dsply
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
	
	else
	
		DoPrompt "Auto Event Detection", tselect, tzero, dsply
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		SetNMEventVar( "AutoTSelect", tselect )
	
	endif
	
	tzero -= 1
	dsply -= 1
	
	SetNMEventVar( "AutoTZero", tzero )
	SetNMEventVar( "AutoDsply", dsply )
	
	if ( tselect == 0 )
		EventTableNew()
	endif
	
	if ( tzero == 1 )
		EventSearchTime( EventSearchBgn() )
	endif
	
	vlist = NMCmdNum( wselect, vlist )
	vlist = NMCmdNum( dsply, vlist )
	
	NMCmdHistory( "EventFindAll", vlist )
	
	return EventFindAll( wselect, dsply )

End // EventFindAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindAll( wselect, dsply ) // find events until end of trace
	Variable wselect // ( 0 ) current wave ( 1 ) all waves
	Variable dsply // ( 0 ) no ( 1 ) yes, update display

	Variable pflag, pflag2
	Variable wcnt, ecnt, events
	String wName, setName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	if ( NMNumActiveWaves() <= 0 )
		NMDoAlert( "No Waves Selected!" )
		return -1
	endif
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	Variable tableNum = NMEventTableOldNum()
	
	Variable searchTime = NMEventVar( "SearchTime" )
	
	Wave ThreshT = $NMEventDisplayWaveName( "ThreshT" )
	
	Variable wbgn = currentWave
	Variable wend = currentWave
	Variable savewave = currentWave
	Variable savetime = searchTime
	
	String tableName = CurrentNMEventTableName()

	if ( strlen( tableName ) == 0 )
		EventTableNew()
	endif
	
	if ( wselect == 1 )
		wbgn = 0
		wend = NMNumWaves() - 1
	endif
	
	DoWindow /F $ChanGraphName( currentChan )
	
	//Print ""
	//Print "Auto event detection for Ch " + ChanNum2Char( chan ) + " saved in Table " + num2istr( tableNum )
	
	SetNeuroMaticStr( "ProgressStr", "Detecting Events..." )

	for ( wcnt = wbgn; wcnt <= wend; wcnt += 1 )
	
		if ( ( wselect == 0 ) || ( ( wselect == 1 ) && ( NMWaveIsSelected( currentChan, wcnt ) == 1 ) ) )
		
			if ( wselect == 1 ) // all waves
				currentWave = wcnt
				NMCurrentWaveSet( wcnt )
				UpdateEventDisplay()
			endif
			
			ecnt = 0
			
			SetNeuroMaticStr( "ProgressStr", "Detecting Events..." )
			CallProgress( -1 )
			
			do
			
				pflag = CallProgress( -2 )
			
				if ( pflag == 1 ) // cancel
					break
				endif
				
				if ( EventFindNext( dsply ) == 0 )
				
					pflag2 = EventSaveCurrent( 0 )
				
					if ( pflag2 == -3 )
						break
					endif
					
					ecnt += 1
					
				else
				
					break // no more events
					
				endif
				
			while ( 1 )
			
			if ( pflag2 == -3 )
				break
			endif
			
			Print "Located " + num2istr( ecnt ) + " event(s) in wave " + CurrentNMWaveName()
			
		endif
		
		if ( pflag == 1 ) // cancel
			break
		endif
	
	endfor
	
	CallProgress( 1 )
	
	if ( pflag == 0 )
		
		if ( currentWave != saveWave )
			NMCurrentWaveSet( saveWave )
		endif
		
		EventSearchTime( savetime )
	
	endif
	
	UpdateEventTab()
	NMEventReviewAlert()
	
	DoWindow /F $tableName

End // EventFindAll

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindNext( dsply ) // find next event
	Variable dsply // ( 0 ) no ( 1 ) yes, update display
	
	Variable wbgn, wend, nstdv, posneg = -1, jcnt, jlimit = 20, dxskip = 1
	Variable tbgn, tend, dx, first = 1
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	if ( NMWaveIsSelected( currentChan, currentWave ) == 0 )
		NMDoAlert( "Event Find Next Abort: the current wave is not selected for analysis." )
		NMWaveSelectStr()
		return -2
	endif
	
	Variable searchMethod = NMEventVar( "SearchMethod" )
	Variable searchTime =  NMEventVar( "SearchTime" )
	//Variable thrshld = NMEventVar( "Thrshld" )
	Variable threshLevel = NMEventVar( "ThreshLevel" )
	
	Variable onsetFlag = NMEventVar( "OnsetFlag" )
	Variable onsetNstdv = NMEventVar( "OnsetNstdv" )
	Variable onsetWin = NMEventVar( "OnsetWin" )
	Variable onsetAvg = NMEventVar( "OnsetAvg" )
	
	Variable peakFlag = NMEventVar( "PeakFlag" )
	Variable peakNstdv = NMEventVar( "PeakNstdv" )
	Variable peakWin = NMEventVar( "PeakWin" )
	Variable peakAvg = NMEventVar( "PeakAvg" )
	
	Variable matchFlag = NMEventVar( "MatchFlag" )
	Variable matchBsln = NMEventVar( "MatchBsln" )
	
	Variable threshX = NMEventVar( "ThreshX" )
	Variable threshY = NMEventVar( "ThreshY" )
	Variable onsetX = NMEventVar( "OnsetX" )
	Variable onsetY = NMEventVar( "OnsetY" )
	Variable peakX = NMEventVar( "PeakX" )
	Variable peakY = NMEventVar( "PeakY" )
	
	Variable baseFlag = NMEventVar( "BaseFlag" )
	Variable baseDT = NMEventVar( "BaseDT" )
	Variable baseWin = NMEventVar( "BaseWin" )
	
	Wave ThreshT = $NMEventDisplayWaveName( "ThreshT" )
	Wave BaseT = $NMEventDisplayWaveName( "BaseT" )
	Wave BaseY = $NMEventDisplayWaveName( "BaseY" )
	Wave ThisT = $NMEventDisplayWaveName( "ThisT" )
	Wave ThisY = $NMEventDisplayWaveName( "ThisY" )
	
	String wName = ChanDisplayWave( currentChan )
	
	if ( WaveExists( $wName ) == 0 )
		return -2
	endif
	
	Wave eWave = $wName
	
	String wName2 = wName
	
	if ( matchFlag > 0 )
		wName2 = NMEventDisplayWaveName( "MatchTmplt" )
	endif
	
	dx = deltax( $wName )
	
	BaseY = Nan
	threshY = threshLevel
	
	tbgn = EventSearchBgn()
	tend = EventSearchEnd()
	
	if ( numtype( searchTime ) == 0 )
		tbgn = searchTime
	endif
	
	do // search for next event
	
		if ( matchFlag > 0 )
		
			if ( ( peakFlag == 1 ) && ( numtype( peakX ) == 0 ) )
				tbgn = peakX + dxskip*dx
			elseif ( numtype( onsetX ) == 0 )
				tbgn = onsetX + dxskip*dx
			elseif ( first == 0 )
				return -1
			endif
			
		else
		
			if ( ( peakFlag == 1 ) && ( numtype( peakX ) == 0 ) )
				tbgn = peakX + dxskip*dx
			elseif ( numtype( threshX ) == 0 ) 
				tbgn = threshX + dxskip*dx
			elseif ( first == 0 )
				return -1
			endif
			
		endif
	
		switch( searchMethod )
		
			case 1: // Level+
				FindLevel /EDGE=1/Q/R=( tbgn, tend ) $wName2, threshLevel
				threshX = V_LevelX
				posneg = 1
				break
				
			case 2: // Level-
				FindLevel /EDGE=2/Q/R=( tbgn, tend ) $wName2, threshLevel
				threshX = V_LevelX
				break
				
			case 3: // thresh > base
				posneg = 1
				
			case 4: // thresh < base
				threshX = EventFindThresh( wName2, tbgn, tend, baseWin/dx, baseDT/dx, threshLevel, posneg )
				break
				
		endswitch
		
		first = 0
		
		if ( numtype( threshX ) > 0 ) // no event found
			threshX = ThisT[ 0 ]
			return -1
		endif
		
		Wave eWave2 = $wName2
		
		threshY = eWave2[ x2pnt( eWave2, threshX ) ]
		
		// find onsets and peaks
	
		if ( matchFlag > 0 )
		
			WaveStats /Q/Z/R=( threshX, threshX+peakWin ) $wName2
			
			if ( searchMethod == 1 )
				onsetX = V_maxloc + matchBsln
			elseif ( searchMethod == 2 )
				onsetX = V_minloc + matchBsln
			else
				onsetX = Nan
			endif
			
			onsetY = eWave[ x2pnt( eWave, onsetX ) ]
	
			if ( peakFlag == 1 )
				peakX = NMFindPeak( wName, onsetX, onsetX+peakWin, floor( peakAvg/dx ), peakNstdv, posneg )
				peakY = eWave[ x2pnt( eWave, peakX ) ]
			else
				peakX = Nan
				peakY = Nan
			endif
			
		else
		
			if ( onsetFlag == 1 ) // search backward from ThreshX
				onsetX = NMFindOnset( wName, threshX-onsetWin, threshX, floor( onsetAvg/dx ), onsetNstdv, posneg, -1 )
				onsetY = eWave[ x2pnt( eWave, onsetX ) ]
			else
				onsetX = Nan
				onsetY = Nan
			endif
			
			if ( peakFlag == 1 )
				peakX = NMFindPeak( wName, threshX, threshX+peakWin, floor( peakAvg/dx ), peakNstdv, posneg )
				peakY = eWave[ x2pnt( eWave, peakX ) ]
			else
				peakX = Nan
				peakY = Nan
			endif
			
		endif
		
		jcnt += 1
		
		if ( jcnt > jlimit )
			threshX = Nan
			peakX = Nan
			onsetX = Nan
			break
		endif
		
		if ( ( searchMethod == 3 ) || ( searchMethod == 4 ) ) // threshold/baseline method
			tbgn = threshX - baseDT
		else
			tbgn = threshX + dx
		endif

		if ( ( onsetFlag == 1 ) && ( numtype( onsetX ) > 0 ) )
			continue // bad event
		endif
		
		if ( ( peakFlag == 1 ) && ( numtype( peakX ) > 0 ) )
			continue // bad event
		endif
		
		break // found event
	
	while ( 1 )
	
	if ( ( searchMethod > 2 ) && ( baseFlag == 1 ) ) // compute baseline display
	
		wbgn = threshX - baseDT - baseWin/2
		wend = threshX - baseDT + baseWin/2
		
		WaveStats /Q/Z/R=( wbgn,wend ) $wName
		
		BaseY = V_avg
		BaseT[ 0 ] = wbgn
		BaseT[ 1 ] = wend
		
	endif
	
	ThisT[ 0 ] = threshX
	ThisY[ 0 ] = threshY
	
	SetNMEventVar( "SearchTime", threshX )
	SetNMEventVar( "ThreshX", threshX )
	SetNMEventVar( "ThreshY", threshY )
	
	SetNMEventVar( "OnsetX", onsetX )
	SetNMEventVar( "OnsetY", onsetY )
	SetNMEventVar( "PeakX", peakX )
	SetNMEventVar( "PeakY", peakY )
	
	SetNMEventVar( "BaseY", BaseY[ 0 ] )
	
	EventFindSaved( NMEventTableWaveName( "WaveN" ), NMEventDisplayWaveName( "ThreshT" ), threshX, 0.01, currentWave )
	
	if ( dsply == 1 )
		EventCursors( 1 )
	endif
	
	return 0 // success

End // EventFindNext

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindNextActiveWave( chanNum, currentWave )
	Variable chanNum
	Variable currentWave
	
	Variable wcnt
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ( numtype( currentWave ) > 0 ) || ( currentWave < 0 ) )
		currentWave = CurrentNMWave()
	endif
	
	for ( wcnt = currentWave + 1 ; wcnt < NMNumWaves() ; wcnt += 1 )
		if ( NMWaveIsSelected( chanNum, wcnt ) == 1 )
			return wcnt
		endif
	endfor
	
	return -1
	
End // EventFindNextActiveWave

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindThresh( wName, tbgn, tend, bslnPnts, deltaPnts, thresh, posneg ) // locate threshold above baseline
	String wName // wave name
	Variable tbgn, tend // search time begin and end, ( -inf / inf ) for all possible time
	Variable bslnPnts // baseline average points
	Variable deltaPnts // points between mid-baseline and threshold crossing point
	Variable thresh // threshold level value
	Variable posneg // ( -1 ) negative events ( 1 ) positive events
	
	Variable icnt, ibgn, iend, level, xpnt, avg
	String thisfxn = "EventFindThresh"
	
	if ( WaveExists( $wName ) == 0 )
		NMError( 1, thisfxn, "wName", wName )
		return Nan
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( ( numtype( bslnPnts ) > 0 ) || ( bslnPnts <= 0 ) )
		NMError( 10, thisfxn, "bslnPnts", num2istr( bslnPnts ) )
		return Nan
	endif
	
	if ( ( numtype( deltaPnts ) > 0 ) || ( deltaPnts <= 0 ) )
		NMError( 10, thisfxn, "deltaPnts", num2istr( deltaPnts ) )
		return Nan
	endif
	
	if ( numtype( thresh ) > 0 )
		NMError( 10, thisfxn, "thresh", num2str( thresh ) )
		return Nan
	endif
	
	Wave eWave = $wName
	Variable dx = deltax( eWave )
	
	ibgn = x2pnt( eWave, tbgn )
	
	iend = x2pnt( eWave, tend ) - deltaPnts

	// search forward from tbgn until right-most data point falls above ( below ) threshold value
	
	for ( icnt = ibgn; icnt < iend; icnt+=1 )
	
		if ( bslnPnts > 0 )
			WaveStats /Q/Z/R=[ icnt - bslnPnts/2, icnt + bslnPnts/2 ] eWave
			avg = V_avg
		else
			avg = eWave[ icnt ]
		endif
		
		level = avg + abs( thresh ) * posneg
		
		xpnt = icnt + deltaPnts
		
		if ( ( posneg > 0 ) && ( eWave[ xpnt ] >= level ) )
			return pnt2x( eWave, xpnt )
		elseif ( ( posneg < 0 ) && ( eWave[ xpnt ] <= level ) )
			return pnt2x( eWave, xpnt )
		endif
		
	endfor
	
	return Nan

End // EventFindThresh

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveNext( waveNum, currentTime )
	Variable waveNum
	Variable currentTime
	
	Variable ecnt, t
	String wname
	
	Variable tbgn = NMEventVar( "SearchBgn" )
	Variable tend = NMEventVar( "SearchEnd" )
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	if ( ( numtype( currentTime ) > 0 ) || ( currentTime < 0 ) )
		currentTime = NMEventVar( "ThreshX" )
	endif
	
	wname = NMEventTableWaveName( "ThreshT" )
	
	if ( WaveExists( $wname ) == 0 )
		NMDoAlert( "No events to retrieve." )
		return 0
	endif
	
	Wave threshT = $wname
	Wave waveN = $NMEventTableWaveName( "WaveN" )
	
	for ( ecnt = 0 ; ecnt < numpnts( waveN ) ; ecnt += 1 )
		
		if ( waveN[ ecnt ] != waveNum )
			continue
		endif
		
		t = threshT[ ecnt ]
		
		if ( ( t > currentTime ) && ( t >= tbgn ) && ( t <= tend ) )
			EventRetrieve( ecnt )
			return ecnt
		endif
	
	endfor
	
	return -1
	
End // EventRetrieveNext

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveLast( waveNum, currentTime )
	Variable waveNum
	Variable currentTime
	
	Variable ecnt, t
	String wname
	
	Variable tbgn = NMEventVar( "SearchBgn" )
	Variable tend = NMEventVar( "SearchEnd" )
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	if ( ( numtype( currentTime ) > 0 ) || ( currentTime < 0 ) )
		currentTime = NMEventVar( "ThreshX" )
	endif
	
	wname = NMEventTableWaveName( "ThreshT" )
	
	if ( WaveExists( $wname ) == 0 )
		NMDoAlert( "No events to retrieve." )
		return 0
	endif
	
	Wave threshT = $wname
	Wave waveN = $NMEventTableWaveName( "WaveN" )
	
	for ( ecnt = numpnts( waveN ) - 1 ; ecnt >= 0  ; ecnt -= 1 )
		
		if ( waveN[ ecnt ] != waveNum )
			continue
		endif
		
		t = threshT[ ecnt ] 
		
		if ( ( t < currentTime ) && ( t >= tbgn ) && ( t <= tend ) )
			EventRetrieve( ecnt )
			return ecnt
		endif
	
	endfor
	
	return -1
	
End // EventRetrieveLast

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveLastWaveNum( currentWave )
	Variable currentWave
	
	Variable ecnt, wnum
	String wname
	
	if ( ( numtype( currentWave ) > 0 ) || ( currentWave < 0 ) )
		currentWave = CurrentNMWave()
	endif
	
	wname = NMEventTableWaveName( "WaveN" )
	
	if ( WaveExists( $wname ) == 0 )
		NMDoAlert( "No events to retrieve." )
		return 0
	endif
	
	Wave waveN = $wname
	
	for ( ecnt = numpnts( waveN ) - 1 ; ecnt >= 0  ; ecnt -= 1 )
	
		wnum = waveN[ ecnt ]
	
		if ( wnum < currentWave )
			return wnum
		endif
	
	endfor
	
	return -1
	
End // EventRetrieveLastWaveNum

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveNextWaveNum( currentWave )
	Variable currentWave
	
	Variable ecnt, wnum
	String wname
	
	if ( currentWave < 0 )
		currentWave = CurrentNMWave()
	endif
	
	wname = NMEventTableWaveName( "WaveN" )
	
	if ( WaveExists( $wname ) == 0 )
		NMDoAlert( "No events to retrieve." )
		return 0
	endif
	
	Wave waveN = $wname
	
	for ( ecnt = 0 ; ecnt < numpnts( waveN ) ; ecnt += 1 )
	
		wnum = waveN[ ecnt ]
	
		if ( wnum > currentWave )
			return wnum
		endif
	
	endfor
	
	return -1
	
End // EventRetrieveNextWaveNum

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieve( event ) // retrieve event times from wave
	Variable event // event number
	
	Variable wbgn, wend, threshx
	
	String wname = NMEventDisplayWaveName( "ThreshT" )
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif
	
	Variable baseFlag = NMEventVar( "BaseFlag" )
	Variable baseWin = NMEventVar( "BaseWin" )
	Variable baseDT = NMEventVar( "BaseDT" )
	
	Wave ThreshT = $NMEventDisplayWaveName( "ThreshT" )
	Wave ThreshY = $NMEventDisplayWaveName( "ThreshY" )
	Wave OnsetT = $NMEventDisplayWaveName( "OnsetT" )
	Wave PeakT = $NMEventDisplayWaveName( "PeakT" )
	Wave ThisT = $NMEventDisplayWaveName( "ThisT" )
	Wave ThisY = $NMEventDisplayWaveName( "ThisY" )
	Wave BaseT = $NMEventDisplayWaveName( "BaseT" )
	Wave BaseY = $NMEventDisplayWaveName( "BaseY" )
	
	if ( ( numtype( event ) > 0 ) || ( event < 0 ) || ( event >= numpnts( ThreshT ) ) )
		return -1 // out of range
	endif
	
	threshx = ThreshT[ event ]
	
	SetNMEventVar( "ThreshX", threshx )
	SetNMEventVar( "ThreshY", Nan )
	SetNMEventVar( "OnsetX", OnsetT[ event ] )
	SetNMEventVar( "OnsetY", Nan )
	SetNMEventVar( "PeakX", PeakT[ event ] )
	SetNMEventVar( "PeakY", Nan )
	SetNMEventVar( "SearchTime", threshx )
	
	ThisT = ThreshT[ event ]
	ThisY = ThreshY[ event ]
	
	if ( baseFlag == 1 ) // compute baseline display
	
		wbgn = threshx - baseDT - baseWin/2
		wend = threshx - baseDT + baseWin/2
		
		WaveStats /Q/Z/R=( wbgn,wend ) $ChanDisplayWave( -1 )
		
		BaseY = V_avg
		BaseT[ 0 ] = wbgn
		BaseT[ 1 ] = wend
		
	endif
	
	EventCursors( 1 )
	
	Return 0

End // EventRetrieve

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSaveCall()

	Variable esave = EventSave()

	if ( esave == 0 )
		if ( NMEventVar( "FindNextAfterSaving" ) == 1 )
			EventFindNextCall()
		endif
	endif

	return esave

End // EventSaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSave()

	Variable success = EventSaveCurrent( 1 )
	
	UpdateEventTab()
	
	return success
	
End // EventSave

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSaveCurrent( cursors ) // save event times to table
	Variable cursors // ( 0 ) save computed values ( 1 ) save values from cursors A, B
	
	Variable event, npnts, tolerance = 0.01
	String wname
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	String gName = ChanGraphName( currentChan )
	
	String currentTable = CurrentNMEventTableName()
	
	Variable tbgn = EventSearchBgn()
	Variable tend = EventSearchEnd()
	
	Variable onsetX = NMEventVar( "OnsetX" )
	Variable onsetY = NMEventVar( "OnsetY" )
	Variable peakX = NMEventVar( "PeakX" )
	Variable peakY = NMEventVar( "PeakY" )
	Variable threshX = NMEventVar( "ThreshX" )
	Variable threshY = NMEventVar( "ThreshY" )
	Variable baseY = NMEventVar( "BaseY" )
	
	if ( numtype( threshX * threshY ) > 0 )
		NMDoAlert( "No event to save." )
		return -1
	endif
	
	NMEventTableManager( currentTable, "make" )
	
	wname = NMEventTableWaveName( "ThreshT" )
	
	if ( WaveExists( $wname ) == 0 )
		NMDoAlert( "Event Save Abort: cannot locate current table wave: " + wname)
		return -1
	endif
	
	Wave wvN = $NMEventTableWaveName( "WaveN" )
	Wave bsY = $NMEventTableWaveName( "BaseY" )
	Wave thT = $NMEventTableWaveName( "ThreshT" )
	Wave thY = $NMEventTableWaveName( "ThreshY" )
	Wave onT = $NMEventTableWaveName( "onsetT" )
	Wave onY = $NMEventTableWaveName( "onsetY" )
	Wave pkT = $NMEventTableWaveName( "peakT" )
	Wave pkY = $NMEventTableWaveName( "peakY" )
	
	if ( cursors == 1 ) // get cursor points from graph ( allows user to move onset/peak cursors )
		onsetX = xcsr( A, gName )
		onsetY = vcsr( A, gName )
		peakX = xcsr( B, gName )
		peakY = vcsr( B, gName )
	endif
	
	if ( ( numtype( onsetX*onsetY ) > 0 ) || ( onsetX <= tbgn ) || ( onsetX >= tend ) )
		onsetX = Nan
		onsetY = Nan
	endif
	
	if ( ( numtype( peakX*peakY ) > 0 ) || ( peakX <= tbgn ) || ( peakX >= tend ) )
		peakX = Nan
		peakY = Nan
	endif

	event = EventFindSaved( NMEventTableWaveName( "WaveN" ), wname, threshX, tolerance, currentWave )

	if ( event != -1 )
	
		DoAlert 2, "Alert: a similar event already exists. Do you want to replace it?"
		
		if ( V_flag == 1 )
			DeletePoints event, 1, wvN, thT, thY, onT, onY, pkT, pkY, bsY
		else
			return -3 // cancel
		endif
		
	endif
	 
	npnts = numpnts( thT )

	Redimension /N=( npnts+1 ) wvN, thT, thY, onT, onY, pkT, pkY, bsY
	
	wvN[ npnts ] = currentWave
	thT[ npnts ] = threshX
	thY[ npnts ] = threshY
	onT[ npnts ] = onsetX
	onY[ npnts ] = onsetY
	pkT[ npnts ] = peakX
	pkY[ npnts ] = peakY
	bsY[ npnts ] = baseY
	
	Sort { wvN, thT }, wvN, thT, thY, onT, onY, pkT, pkY, bsY
	
	WaveStats /Q/Z thT
	
	if ( ( V_numNans > 0 ) && ( V_npnts != numpnts( wvN ) ) )
		Redimension /N=( V_npnts ) wvN, thT, thY, onT, onY, pkT, pkY, bsY // remove NANs if they exist
	endif
	
	SetNMEventVar( "ThreshY", Nan ) // Null existing event
	SetNMEventVar( "OnsetY", Nan )
	SetNMEventVar( "PeakY", Nan )
	SetNMEventVar( "BaseY", Nan )
	
	UpdateEventDisplay()
	EventCount()
	
	return 0
	
End // EventSaveCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindSaved( nwName, ewName, eventTime, tolerance, waveNum ) // locate saved event time
	String nwName // wave of record numbers
	String ewName // wave of event times
	Variable eventTime // ms
	Variable tolerance // tolerance window
	Variable waveNum // record number
	
	Variable ecnt
	
	if ( WaveExists( $nwName ) == 0 )
		//NMDoAlert( "EventFindSaved Abort: cannot locate wave " + nwName )
		return -1
	endif
	
	if ( WaveExists( $ewName ) == 0 )
		//NMDoAlert( "EventFindSaved Abort: cannot locate wave " + ewName )
		return -1
	endif
	
	Wave waveN = $nwName
	Wave waveE = $ewName
	
	for ( ecnt = 0 ; ecnt < numpnts( waveE ) ; ecnt += 1 )
	
		if ( waveN[ ecnt ] != waveNum )
			continue
		endif
		
		if ( ( waveE[ ecnt ] > eventTime - tolerance ) && ( waveE[ ecnt ] < eventTime + tolerance )  )
			return ecnt
		endif
		
	endfor

	return -1

End // EventFindSaved

//****************************************************************
//****************************************************************
//****************************************************************

Function EventDelete( waveNum, eventTime ) // delete saved event from table/display waves
	Variable waveNum
	Variable eventTime
	
	Variable event
	
	if ( WaveExists( $NMEventTableWaveName( "ThreshY" ) ) == 0 )
		return -1
	endif
	 
	Wave wvN = $NMEventTableWaveName( "WaveN" )
	Wave thT = $NMEventTableWaveName( "ThreshT" )
	Wave thY = $NMEventTableWaveName( "ThreshY" )
	Wave onT = $NMEventTableWaveName( "onsetT" )
	Wave onY = $NMEventTableWaveName( "onsetY" )
	Wave pkT = $NMEventTableWaveName( "peakT" )
	Wave pkY = $NMEventTableWaveName( "peakY" )
	Wave bsY = $NMEventTableWaveName( "BaseY" )
	
	event = EventFindSaved( NMEventTableWaveName( "WaveN" ), NMEventTableWaveName( "ThreshT" ), eventTime, 0.01, waveNum )
	
	if ( event == -1 )
		NMDoAlert( "Delete Alert: no event exists with threshold time " + num2str( eventTime ) + " ms." )
		return 0 // event does not exist
	endif
	
	if ( ( numtype( event ) > 0 ) || ( event < 0 ) || ( event >= numpnts( wvN ) ) )
		return -1
	endif
	
	DeletePoints event, 1, wvN, thT, thY, onT, onY, pkT, pkY, bsY
	
	UpdateEventDisplay()
	EventCount()
	
	return 0

End // EventDelete

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Event Subfolder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSubfolderPrefix()

	return "Event_"

End //NMEventSubfolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSubfolder( wavePrefix, waveSelect )
	String wavePrefix
	String waveSelect
	
	if ( NMEventVar( "UseSubfolders" ) == 0 )
		return ""
	endif
	
	return NMSubfolder( NMEventSubfolderPrefix(), wavePrefix, CurrentNMChannel(), waveSelect )

End // NMEventSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMEventSubfolder()

	return NMEventSubfolder( CurrentNMWavePrefix(), NMWaveSelectShort() )
	
End // CurrentNMEventSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMEventSubfolder()
	
	String subfolder = CurrentNMEventSubfolder()
	
	if ( strlen( subfolder ) > 0 )
		return CheckNMSubfolder( subfolder )
	else
		return 0
	endif
	
End // CheckNMEventSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSubfolderList( folder, fullPath, restrictToCurrentPrefix )
	String folder
	Variable fullPath // ( 0 ) no ( 1 ) yes
	Variable restrictToCurrentPrefix
	
	Variable icnt
	String folderName, tempList = ""
	
	String currentPrefix = CurrentNMWavePrefix()
	
	String folderList = NMSubfolderList( NMEventSubfolderPrefix(), folder, fullPath )
	
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

End // NMEventSubfolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSubfolderWaveName( subfolder, type )
	String subfolder
	String type // e.g. "ThreshT" or "OnsetY"
	
	Variable icnt
	String wname

	String wList = NMFolderWaveList( subfolder, "*", ";", "", 1 )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wname = StringFromList( icnt, wList )
		
		if ( strsearch( wname, type, 0 ) > 0 )
			return wname
		endif
	
	endfor
	
	return ""
	
End // NMEventSubfolderWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSubfolderTableName( subfolder )
	String subfolder
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMEventSubfolder()
	endif
	
	return NMSubfolderTableName( subfolder, "EV_" )
	
End // NMEventSubfolderTableName

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Event Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableCall( fxn )
	String fxn
	
	String tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	String tableName = CurrentNMEventTableName()

	strswitch( fxn )
	
		case "New": // for old table formats only
			EventTableNewCall()
			return 0
			
		case "Clear":
			return NMEventTableClearCall()
			
		case "Kill":
			return NMEventTableKillCall()
			
		case "E2W":
		case "Events2Waves":
			return Event2WaveCall()
			
		case "Histo":
			return EventHistoCall()
			
		default:
			NMDoAlert( "EventTableCall Error: unrecognized function call: " + fxn )
		
	endswitch
	
End // EventTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventTableList()
	
	if ( NMEventTableOldExists() == 1 )
		return NMEventTableOldList( CurrentNMChannel() )
	else
		return NMEventSubfolderList( "", 0, 0 )
	endif

End // EventTableList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMEventTableSelect()

	String tableList, tableSelect
	
	if ( NMEventTableOldExists() == 0 )
		return CurrentNMEventTableSelect()
	endif
	
	tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	
	if ( strlen( tableSelect ) > 0 )
		return tableSelect
	endif
	
	tableList = NMEventTableOldList( CurrentNMChannel() )
		
	if ( ItemsInList( tableList ) == 1 )
	
		tableSelect = StringFromList( 0, tableList )
		
		SetNMstr( "EventTableSelected", tableSelect )
		
		return tableSelect
	
	elseif ( ItemsInList( tableList ) > 1 )

		Prompt tableSelect, "please choose current Event table:" popup tableList
		DoPrompt "Current Event Table", tableSelect
		
		if ( V_flag == 1 )
			return ""
		endif
		
		SetNMstr( "EventTableSelected", tableSelect )
		
		return tableSelect
	
	endif
	
	return ""

End // CheckNMEventTableSelect

///****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableSelectCall( tableSelect )
	String tableSelect
	
	NMCmdHistory( "NMEventTableSelect", NMCmdStr( tableSelect, "" ) )
	
	return NMEventTableSelect( tableSelect )

End // NMEventTableSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableSelect( tableSelect )
	String tableSelect
	
	Variable tableNum
	String tableName
	
	Variable currentChan = CurrentNMChannel()
	
	SetNMstr( "EventTableSelected", tableSelect )
	
	if ( NMEventTableOldFormat( tableSelect ) == 1 )
		
		tableNum = EventNumFromName( tableSelect )
		tableName = NMEventTableOldName( currentChan, tableNum )
		
	else
	
		tableName = CurrentNMEventTableName()
		
	endif
	
	if ( strlen( tableName ) > 0 )
		NMEventTableManager( tableName, "make" )
		DoWindow /F $tableName
	endif
	
	EventCount()
	UpdateEventDisplay()
	UpdateEventTab()
	
	return tableName
	
End // NMEventTableSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMEventTableSelect()
	
	if ( NMEventTableOldExists() == 1 )
		return NMEventTableOldSelect( CurrentNMChannel(), NMEventTableOldNum() )
	else
		return ParseFilePath(0, CurrentNMEventSubfolder(), ":", 1, 0)
	endif

End // CurrentNMEventTableSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMEventTableName()

	Variable tableNum
	String tableName = NMEventSubfolderTableName( "" )
	
	Variable currentChan = CurrentNMChannel()
	
	String tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	
	if ( NMEventTableOldFormat( tableSelect ) == 1 )
		
		tableNum = EventNumFromName( tableSelect )
	
		if ( tableNum >= 0 )
			tableName = NMEventTableOldName( currentChan, tableNum )
		endif
	
	endif
	
	return tableName

End // CurrentNMEventTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableClearCall()

	String tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	String tableName = CurrentNMEventTableName()

	if ( strlen( tableName ) == 0 )
		NMDoAlert( "No event table to clear." )
		return -1
	endif
	
	DoAlert 1, "Are you sure you want to clear table " + NMQuotes( tableSelect ) + "?"
	
	if ( V_flag != 1 )
		return -1
	endif
	
	NMCmdHistory( "NMEventTableClear", NMCmdStr( tableName, "" ) )
	
	return NMEventTableClear( tableName )

End // NMEventTableClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableClear( tableName )
	String tableName
	
	if ( strlen( tableName ) == 0 )
		tableName = CurrentNMEventTableName()
	endif

	NMEventTableManager( tableName, "clear" )
	EventCount()
	UpdateEventDisplay()
	UpdateEventTab()
	
	return 0

End // NMEventTableClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableKillCall()

	String tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	String tableName = CurrentNMEventTableName()

	if ( strlen( tableName ) == 0 )
		NMDoAlert( "No event table to kill." )
		return -1
	endif
	
	DoAlert 1, "Are you sure you want to kill table " + NMQuotes( tableSelect ) + "?"
	
	if ( V_flag != 1 )
		return -1
	endif
	
	NMCmdHistory( "NMEventTableKill", NMCmdStr( tableName,"" ) )
	
	return NMEventTableKill( tableName )
			
End // NMEventTableKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableKill( tableName )
	String tableName
	
	Variable items
	String tableList
	
	if ( strlen( tableName ) == 0 )
		tableName = CurrentNMEventTableName()
	endif
	
	NMEventTableManager( tableName, "kill" )
	
	tableList = EventTableList()
	
	items = ItemsInList( tableList )
	
	if ( items > 0 )
		tableName = StringFromList( items-1, tableList )
	else
		tableName = ""
	endif
	
	SetNMstr( "EventTableSelected", tableName )
	
	EventCount()
	UpdateEventDisplay()
	UpdateEventTab()
	
	return 0
	
End // NMEventTableKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableManager( tableName, option )
	String tableName
	String option // "make" or "update" or "clear" or "kill"
	
	String thisfxn = "NMEventTableManager"
	
	if ( NMEventTableOldExists() == 0 )
		CheckNMEventSubfolder()
	endif
	
	SetNMstr( "EventTableSelected", CurrentNMEventTableSelect() )
	
	strswitch( option )
	
		case "make":
		
			if ( WinType( tableName ) == 2 )
				//DoWindow /F $tableName
				return 0 // table already exists
			endif
			
			Make /O/N=0 EV_DumWave
			DoWindow /K $tableName
			Edit /K=1/N=$tableName/W=( 0,0,0,0 ) EV_DumWave as NMEventTableTitle()
			ModifyTable /W=$tableName title( Point )="Event"
			RemoveFromTable /W=$tableName EV_DumWave
			KillWaves /Z EV_DumWave
			
			SetCascadeXY( tableName )
			
			break
			
		case "update":
		case "clear":
			DoWindow /F $tableName
			break
			
		case "kill":
			DoWindow /K $tableName
			break
			
		default:
			return NMError( 20, thisfxn, "option", option )
	
	endswitch 
	
	NMEventTableWaveManager( option, "WaveN", tableName )
	NMEventTableWaveManager( option, "ThreshT", tableName )
	NMEventTableWaveManager( option, "ThreshY", tableName )
	NMEventTableWaveManager( option, "OnsetT", tableName )
	NMEventTableWaveManager( option, "OnsetY", tableName )
	NMEventTableWaveManager( option, "PeakT", tableName )
	NMEventTableWaveManager( option, "PeakY", tableName )
	NMEventTableWaveManager( option, "BaseY", tableName )
	
	strswitch( option )
	
		case "make":
		case "update":
	
			NMEventTableWaveManager( "remove", "WaveN", tableName )
			NMEventTableWaveManager( "remove", "ThreshT", tableName )
			NMEventTableWaveManager( "remove", "ThreshY", tableName )
			NMEventTableWaveManager( "remove", "OnsetT", tableName )
			NMEventTableWaveManager( "remove", "OnsetY", tableName )
			NMEventTableWaveManager( "remove", "PeakT", tableName )
			NMEventTableWaveManager( "remove", "PeakY", tableName )
			NMEventTableWaveManager( "remove", "BaseY", tableName )
			
			NMEventTableWaveManager( "append", "WaveN", tableName )
			
			NMEventTableWaveManager( "append", "ThreshT", tableName )
			NMEventTableWaveManager( "append", "ThreshY", tableName )
			
			if ( NMEventVar( "OnsetFlag" ) == 1 )
				NMEventTableWaveManager( "append", "OnsetT", tableName )
				NMEventTableWaveManager( "append", "OnsetY", tableName )
			endif
			
			if ( NMEventVar( "PeakFlag" ) == 1 )
				NMEventTableWaveManager( "append", "PeakT", tableName )
				NMEventTableWaveManager( "append", "PeakY", tableName )
			endif
			
			if ( NMEventVar( "BaseFlag" ) == 1 )
				NMEventTableWaveManager( "append", "BaseY", tableName )
			endif
		
	endswitch

End // NMNMEventTableManager

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableTitle()
	
	return NMFolderListName("") + " : Events : Ch " + CurrentNMChanChar() + " : " + CurrentNMWavePrefix() + " : " + NMWaveSelectGet()

End // NMEventTableTitle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableWaveManager( option, wtype, tableName )
	String option // "make" or "clear" or "kill" or "append" or "remove"
	String wtype // e.g. "ThreshY" or "PeakY"
	String tableName
	
	String thisfxn = "NMEventTableWaveManager"
	
	String wName = NMEventTableWaveName( wtype )
	
	strswitch( option )
	
		case "make":
		
			if ( WaveExists( $wName ) == 0 )
				Make /D/O/N=0 $wName
				NMEventTableWaveNote( wName, wtype )
				return 0
			else
				return -1
			endif
			
		case "clear":
		
			if ( WaveExists( $wName ) == 1 )
				Wave evWave = $wName
				Redimension /N=0 evWave
				return 0
			else
				return -1
			endif
			
		case "kill":
			KillWaves /Z $wName
			return 0
			
		case "append":
		
			if ( ( WaveExists( $wName ) == 1 ) && ( WinType( tableName ) == 2 ) )
				AppendToTable /W=$tableName $wName
				return 0
			else
				return -1
			endif
			
		case "remove":
		
			if ( ( WaveExists( $wName ) == 1 ) && ( WinType( tableName ) == 2 ) )
				RemoveFromTable /W=$tableName $wName
				return 0
			else
				return -1
			endif
			
		case "update":
			return 0
			
		default:
			return NMError( 20, thisfxn, "option", option )
			
	endswitch

End // NMEventTableWaveManager

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableWaveName( prefix ) // return appropriate event wave name
	String prefix // name prefix
	
	String wPrefix, wname, subfolder
	
	Variable currentChan = CurrentNMChannel()
	
	if ( strlen( prefix ) == 0 )
		return ""
	endif
	
	if ( CurrentNMEventTableOldFormat() == 1 )
	
		wname = NMEventTableOldWaveName( prefix, currentChan, NMEventTableOldNum() )
		
		return wname[ 0,30 ]
	
	else
	
		subfolder = CurrentNMEventSubfolder()
		 wPrefix = "EV_" + prefix + "_" + NMWaveSelectStr() + "_"
		 wname = NextWaveName2( subfolder, wPrefix, currentChan, NMEventOverWrite() )
		 
		 return subfolder + wname[ 0,30 ]
	
	endif
	
End // NMEventTableWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableWaveNote( wName, wtype )
	String wName
	String wtype
	
	if ( WaveExists( $wName ) == 0 )
		return -1
	endif
	
	String yl, xl = "Event#", txt = ""
	
	String wavePrefix = CurrentNMWavePrefix()
	
	String chX = NMChanLabel( -1, "x", "" )
	String chY = NMChanLabel( -1, "y", "" )
	
	Variable tbgn = EventSearchBgn()
	Variable tend = EventSearchEnd()
	
	Variable searchMethod = NMEventVar( "SearchMethod" )
	//Variable thrshld = NMEventVar( "Thrshld" )
	Variable threshLevel = NMEventVar( "ThreshLevel" )
	
	Variable baseWin = NMEventVar( "BaseWin" )
	Variable baseDT = NMEventVar( "BaseDT" )
	
	Variable onsetNstdv = NMEventVar( "OnsetNstdv" )
	Variable onsetWin = NMEventVar( "OnsetWin" )
	Variable onsetAvg = NMEventVar( "OnsetAvg" )
	
	Variable peakNstdv = NMEventVar( "PeakNstdv" )
	Variable peakWin = NMEventVar( "PeakWin" )
	Variable peakAvg = NMEventVar( "PeakAvg" )
	
	Variable matchFlag = NMEventVar( "MatchFlag" )
	Variable matchWform = NMEventVar( "MatchWform" )
	Variable matchTau1 = NMEventVar( "MatchTau1" )
	Variable matchTau2 = NMEventVar( "MatchTau2" )
	Variable matchBsln = NMEventVar( "MatchBsln" )
	
	String template = NMEventStr( "Template" )
	
	txt = "Event Prefix:" + wavePrefix
	txt += "\rEvent Method:" + EventSearchMethodString() + ";Event Thresh:" + num2str( threshLevel ) + ";"
	txt += "\rEvent Tbgn:" + num2str( tbgn ) + ";Event Tend:" + num2str( tend ) + ";"
	txt += "\rBase Avg:" + num2str( baseWin ) + ";Base DT:" + num2str( baseDT ) + ";"
	txt += "\rOnset Limit:" + num2str( onsetWin ) + ";Onset Avg:" + num2str( onsetAvg ) + ";"
	txt += "Onset Nstdv:" + num2str( onsetNstdv ) + ";"
	txt += "\rPeak Limit:" + num2str( peakWin ) + ";Peak Avg:" + num2str( peakAvg ) + ";"
	txt += "Peak Nstdv:" + num2str( peakNstdv ) + ";"
	
	switch( matchFlag )
		case 1:
			txt += "\rMatch Template: 2-exp;Match Tau1:" + num2str( matchTau1 ) + ";Match Tau2:" + num2str( matchTau2 ) + ";"
			txt += "\rMatch Bsln:" + num2str( matchBsln ) + ";Match Win:" + num2str( matchWform ) + ";"
			break
		case 2: // tau1
			txt += "\rMatch Template: alpha;Match Tau1:" + num2str( matchTau1 ) + ";"
			txt += "\rMatch Bsln:" + num2str( matchBsln ) + ";Match Win:" + num2str( matchWform ) + ";"
			break
		case 3: // template
			txt += "\rMatch Template:" + template + ";"
			break
	endswitch
	
	strswitch( wtype )
	
		case "WaveN":
			yl = wavePrefix + "#"
			break
			
		case "OnsetT":
			yl = chX
			break
			
		case "OnsetY":
			yl = chY
			break
			
		case "ThreshT":
			yl = chX
			break
			
		case "ThreshY":
			yl = chY
			break
			
		case "PeakT":
			yl = chX
			break
			
		case "PeakY":
			yl = chY
			break
			
		case "BaseY":
			yl = chY
			break
			
	endswitch
	
	NMNoteType( wName, "Event "+wtype, xl, yl, txt )
	
End // NMEventTableWaveNote

//****************************************************************
//****************************************************************
//****************************************************************

Function EventCount()

	Variable events
	String wname = NMEventTableWaveName( "ThreshT" )
	
	if ( WaveExists( $wname ) == 1 )
		events = numpnts( $wname )
	endif
	
	SetNMEventVar( "NumEvents", events )
	
	return events

End // EventCount

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRepsCount( waveN )
	String waveN
	
	Variable icnt, jcnt, rcnt
	
	if ( WaveExists( $waveN ) == 0 )
		return 0
	endif
	
	Wave yWave = $waveN
	
	for ( icnt = 0 ; icnt < NMNumWaves() ; icnt += 1 )
	
		for ( jcnt = 0 ; jcnt < numpnts( yWave ) ; jcnt += 1 )
		
			if ( yWave[ jcnt ] == icnt )
				rcnt += 1
				break
			endif
			
		endfor
	
	endfor
	
	return rcnt
	
End // EventRepsCount

//****************************************************************
//****************************************************************
//****************************************************************

Function EventNumFromName( wName )
	String wName
	
	Variable num, foundNum, icnt, slength = strlen( wName )
	
	if ( slength == 0 )
		return Nan
	endif
	
	for ( icnt = slength-1; icnt >= 0; icnt -= 1 )
	
		num = str2num( wName[ icnt ] )
		
		if ( numtype( num ) == 0 )
			foundNum = 1
		else
			break // found letter
		endif
		
	endfor
	
	if ( foundNum == 1 )
		return str2num( wName[ icnt+1, slength-1 ] )
	else
		return Nan
	endif
	
End // EventNumFromName

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Old Format Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableOldExists()

	String wList = WaveList( "EV_ThreshT_*" , ";", "Text:0" ) // old wave names that reside in current data folder
	
	if ( ItemsInList( wList ) > 0 )
		return 1
	endif

	return 0
	
End // NMEventTableOldExists

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldName( chanNum, tableNum )
	Variable chanNum
	Variable tableNum
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ( numtype( tableNum ) == 0 ) && ( tableNum >= 0 ) )
		return "EV_" + NMFolderPrefix("") + "Table" + "_" + ChanNum2Char( chanNum ) + num2istr( tableNum )
	endif
	
	return ""

End // NMEventTableOldName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldSelectPrefix()

	return "Event Table "

End // NMEventTableOldSelectPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldSelect( chanNum, tableNum ) // e.g. "Event Table A0"
	Variable chanNum
	Variable tableNum
	
	chanNum = ChanNumCheck( chanNum )

	if ( ( numtype( tableNum ) > 0 ) || ( tableNum < 0 ) )
		return ""
	endif

	return NMEventTableOldSelectPrefix() + ChanNum2Char( chanNum ) + num2istr( tableNum )

End // NMEventTableOldSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function CurrentNMEventTableOldFormat()
	
	return NMEventTableOldFormat( StrVarOrDefault( "EventTableSelected", "" ) )

End // CurrentNMEventTableOldFormat

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableOldFormat( tableTitle )
	String tableTitle
	
	if ( StrSearch( tableTitle, NMEventTableOldSelectPrefix(), 0 ) == 0 )
		return 1
	else
		return 0
	endif
	
End // NMEventTableOldFormat

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableOldNum()

	Variable tableNum, items
	String tableSelect, tableName, tableList
	
	if ( NMEventTableOldExists() == 1 )
	
		tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	
		if ( NMEventTableOldFormat( tableSelect ) == 1 )
		
			tableNum = EventNumFromName( tableSelect )
			
			if ( ( numtype( tableNum ) == 0 ) && ( tableNum >= 0 ) )
				return tableNum
			endif
			
		endif
		
	endif
	
	return -1

End // NMEventTableOldNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableOldNumNext()

	Variable icnt, jcnt, tableNum, found

	String tableList = NMEventTableOldNumList( CurrentNMChannel() )
	
	if ( ItemsInList( tableList ) == 0 )
		return 0
	endif
	
	for ( icnt = 0 ; icnt < 50 ; icnt += 1 )
	
		found = 0
	
		for ( jcnt = 0 ; jcnt < ItemsInList( tableList ) ; jcnt += 1 )
		
			tableNum = str2num( StringFromList( jcnt, tableList ) )
			
			if ( tableNum == icnt )
				found = 1
				break
			endif
		
		endfor
		
		if ( found == 0 )
			return icnt
		endif
	
	endfor

End // NMEventTableOldNumNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldListAll() // e.g. "Event Table A0;Event Table A1;"
	
	Variable ccnt, cbgn, cend = NMNumChannels()
	String tableList = ""
	
	for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		tableList = NMAddToList( NMEventTableOldList( ccnt ), tableList, ";" )
	endfor
	
	return tableList
	
End // NMEventTableOldListAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldList( chanNum ) // e.g. "Event Table A0;Event Table A1;"
	Variable chanNum // -1 for all
	
	Variable icnt
	String wName, wList, suffix, tableList = ""
	
	String prefix = "EV_ThreshT_"
	
	chanNum = ChanNumCheck( chanNum )
	
	wList = WaveList( prefix +  ChanNum2Char( chanNum ) + "*" , ";", "Text:0" )
		
	for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
		wName = StringFromList( icnt, wList )
		suffix = ReplaceString( prefix, wName, "" )
		tableList = AddListItem( NMEventTableOldSelectPrefix() + suffix, tableList, ";", inf )
	endfor
	
	return tableList

End // NMEventTableOldList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldNumList( chanNum ) // e.g. "0;1;2;"
	Variable chanNum
	
	Variable icnt
	String prefix, wName, wList, tableNumStr, tableList = ""
	
	chanNum = ChanNumCheck( chanNum )
	
	prefix = "EV_ThreshT_" + ChanNum2Char( chanNum )
	
	wList = WaveList( prefix + "*" , ";", "Text:0" )
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		tableNumStr = ReplaceString( prefix, wName, "" )
		
		if ( numtype( str2num( tableNumStr ) ) == 0 )
			tableList = AddListItem( tableNumStr, tableList, ";", inf )
		endif
		
	endfor
	
	return tableList

End // NMEventTableOldNumList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldWaveName( prefix, chanNum, tableNum ) // e.g. ""
	String prefix // name prefix
	Variable chanNum
	Variable tableNum
	
	if ( strlen( prefix ) == 0 )
		return ""
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ( numtype( tableNum ) > 0 ) || ( tableNum < 0 ) )
		return ""
	endif
	
	String wname = "EV_" + prefix + "_" + ChanNum2Char( chanNum ) + num2istr( tableNum )
		
	return wname[ 0,30 ]
	
End // NMEventTableOldWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventTableNewCall()
	
	NMCmdHistory( "EventTableNew", "" )
	
	return EventTableNew()

End // EventTableNewCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventTableNew()
	
	Variable tableNum
	String tableSelect, tableName
	
	if ( NMEventTableOldExists() == 1 ) // create old format table only
	
		tableNum = NMEventTableOldNumNext()
		tableSelect = NMEventTableOldSelect( CurrentNMChannel(), tableNum )
		
		tableName = NMEventTableSelect( tableSelect )
		
		return tableName
	
	endif
	
	return ""

End // EventTableNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldWaveList()

	Variable wcnt
	String wname, outList = ""

	String wList = WaveList( "EV_ThreshT_*", ";", "Text:0" )
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wname = StringFromList( wcnt, wList )
		
		if ( ( strsearch( wname, "intvl", 0 ) < 0 ) && ( strsearch( wname, "hist", 0 ) < 0 ) )
			outList = AddListItem( wname, outList, ";", inf )
		endif
		
	endfor
	
	return outList

End // NMEventTableOldWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventWaveList( tableNum ) // DEPRECATED
	Variable tableNum

	Variable icnt
	String wName, wList, wRemove, tableNumStr = num2istr( tableNum )
	
	if ( tableNum == -1 )
		tableNumStr = ""
	endif
	
	wList = WaveList( "EV_*T_*" + tableNumStr, ";", "Text:0" )
	wRemove = WaveList( "EV_Evnt*", ";", "Text:0" )
	wRemove += WaveList( "EV_*intvl*", ";", "Text:0" )
	wRemove += WaveList( "EV_*hist*", ";", "Text:0" )
	
	for ( icnt = 0; icnt < ItemsInList( wRemove ); icnt += 1 )
		wName = StringFromList( icnt, wRemove )
		wList = RemoveFromList( wName, wList )
	endfor

	for ( icnt = ItemsInList( wList ) - 1; icnt >= 0; icnt -= 1 )
	
		wName = StringFromList( icnt, wList )
		
		WaveStats /Q/Z $wName
		
		if ( V_numNans == numpnts( $wName ) )
			wList = RemoveFromList( wName, wList )
		endif
		
	endfor
	
	return wList

End // EventWaveList

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Misc Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function Event2WaveCall()

	Variable ccnt, cbgn, cend, jcnt, found, slen, askwhichwave, waveSelect, chanNum, stopyesno = 2
	
	String tableList, tableSelect, fname, xl, yl, shortstr
	String wName, wName1, wName2, wName3
	String wlist, suffix, subfolder, vlist = ""
	String gPrefix, gName, gTitle
	
	Variable tableNum = NMEventTableOldNum()
	
	Variable currentChan = CurrentNMChannel()
	Variable numChannels = NMNumChannels()
	
	String wavePrefix = CurrentNMWavePrefix()
	
	Variable before = NMEventVar( "E2W_before" )
	Variable after = NMEventVar( "E2W_after" )
	Variable stop = NMEventVar( "E2W_stopAtNextEvent" )
	String chanStr = NMEventStr( "E2W_chan" )
	
	String defaultPrefix = NMEventStr( "S2W_WavePrefix" )
	String outputWavePrefix = NMPrefixUnique( defaultPrefix )
	
	tableList = NMEventSubfolderList( "", 0, 0 ) + NMEventTableOldListAll()
	
	if ( ItemsInList( tableList ) == 0 )
	
		NMDoAlert( "Detected no event table waves." )
		return -1
		
	else
	
		tableSelect = CurrentNMEventTableSelect()
		
		if ( WhichListItem( tableSelect, tableList ) < 0 )
			tableSelect = StringFromList( 0, tableList )
		endif
	
	endif
	
	if ( stop < 0 )
		stopyesno = 1
	endif
	
	Prompt tableSelect, "event table:", popup tableList
	Prompt before, "time before event (ms):"
	Prompt after, "time after event (ms):"
	Prompt stopyesno, "limit data to time before next event?", popup "no;yes;"
	Prompt stop, "additional time to limit before next occuring event (ms):"
	Prompt chanStr, "channel waves to copy:", popup "All;" + NMChanList( "CHAR" )
	Prompt waveSelect, "choose wave of event times:", popup ""
	Prompt outputWavePrefix, "prefix name of new event waves:"
	
	if ( numChannels > 1 )
	
		DoPrompt "Events to Waves", tableSelect, before, after, stopyesno, chanStr
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		cbgn = ChanChar2Num( chanStr )
		cend = ChanChar2Num( chanStr )
		
		SetNMEventStr( "E2W_chan", chanStr )
		
	else
	
		DoPrompt "Events to Waves", tableSelect, before, after, stopyesno
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		cbgn = currentChan
		cend = currentChan
		
	endif
	
	SetNMEventVar( "E2W_before", before )
	SetNMEventVar( "E2W_after", after )
	
	if ( NMEventTableOldFormat( tableSelect ) == 1 )
	
		suffix = ReplaceString( NMEventTableOldSelectPrefix(), tableSelect, "" )
		wName1 = "EV_ThreshT_" + suffix
		wName2 = "EV_OnsetT_" + suffix
		wName3 = "EV_WaveN_" + suffix
		tableNum = EventNumFromName( wName1 )
		
	else
	
		subfolder = GetDataFolder(1) + tableSelect + ":"
		
		wName1 = NMEventSubfolderWaveName( subfolder, "ThreshT" )
		wName2 = NMEventSubfolderWaveName( subfolder, "OnsetT" )
		wName3 = NMEventSubfolderWaveName( subfolder, "WaveN" )
		
		tableNum = -1
	
	endif
	
	if ( WaveExists( $wName1 ) == 0 )
		NMDoAlert( "Event2Wave Abort: cannot locate wave of event times " + NMQuotes( wName1 ) )
		return -1
	endif
	
	if ( WaveExists( $wName2 ) == 0 )
		NMDoAlert( "Event2Wave Abort: cannot locate wave of event times " + NMQuotes( wName2 ) )
		return -1
	endif
	
	if ( WaveExists( $wName3 ) == 0 )
		NMDoAlert( "Event2Wave Abort: cannot locate wave of wave numbers " + NMQuotes( wName3 ) )
		return -1
	endif
	
	if ( StringMatch( wavePrefix, NMNoteStrByKey( wName1, "Event Prefix" ) ) == 0 )
	
		wName = GetPathName( wName1, 0 )
		
		DoAlert 1, "The current wave prefix does not match that of " + NMQuotes( wName ) + ". Do you want to continue?"
		
		if ( V_Flag != 1 )
			return 0
		endif
		
	endif
	
	if ( strlen( NMNoteStrByKey( wname2, "Match Template" ) ) > 0 )
		wName1 = "" // use OnsetT wave instead of ThreshT
	endif
	
	WaveStats /Q/Z $wName1
	
	if ( V_npnts == 0 )
		wName1 = ""
	endif
	
	WaveStats /Q/Z $wName2
	
	if ( V_npnts == 0 )
		wName2 = ""
	endif
	
	if ( ( strlen( wName1 ) == 0 ) && ( strlen( wName2 ) == 0 ) ) 
	
		NMDoAlert( "Event2Wave Abort: detected no events in wave " + wName1 + " or wave " + wName2 )
		return -1
		
	elseif ( ( strlen( wName1 ) > 0 ) && ( strlen( wName2 ) > 0 ) )
	
		wName = wName1
		askwhichwave = 1
		
		wList = AddListItem( GetPathName( wName1, 0 ), "", ";", inf )
		wList = AddListItem( GetPathName( wName2, 0 ), wList, ";", inf )
		
		waveSelect = 1
		
		Prompt waveSelect, "choose wave of event times:", popup wList
	
	elseif ( strlen( wName1 ) > 0 )
	
		wName = wName1
	
	elseif ( strlen( wName2 ) > 0 )
	
		wName = wName2
	
	else
		
		NMDoAlert( "Event2Wave Abort: detected no events in wave " + wName1 + " or wave " + wName2 )
		return -1 // should not reach this point
		
	endif
	
	if ( StringMatch( chanStr, "All" ) == 1 )
		cbgn = 0
		cend = numChannels - 1
		chanNum = -1
	else
		chanNum = ChanChar2Num( chanStr )
	endif
	
	if ( tableNum >= 0 )
		outputWavePrefix = defaultPrefix + num2istr( tableNum )
	else
		outputWavePrefix = NMPrefixUnique( defaultPrefix )
	endif
	
	outputWavePrefix = CheckNMPrefixUnique( outputWavePrefix, defaultPrefix, chanNum )
	
	if ( askwhichwave == 0 )
	
		if ( stopyesno == 2 )
		
			if ( stop < 0 )
				stop = 0
			endif
			
			DoPrompt "Events to Waves", stop, outputWavePrefix
			
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			SetNMEventVar( "E2W_stopAtNextEvent", stop )
			
		else
		
			stop = -1
			
		endif
	
	else
	
		if ( stopyesno == 2 )
		
			if ( stop < 0 )
				stop = 0
			endif
			
			DoPrompt "Events to Waves", stop, waveSelect, outputWavePrefix
			
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			SetNMEventVar( "E2W_stopAtNextEvent", stop )
			
			if ( waveSelect == 1 )
				wName = wName1
			else
				wName = wName2
			endif
			
		else
		
			stop = -1
			
		endif
	
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
		
		vlist = NMCmdStr( wName3, vlist )
		vlist = NMCmdStr( wName, vlist )
		vlist = NMCmdNum( before, vlist )
		vlist = NMCmdNum( after, vlist )
		vlist = NMCmdNum( stop, vlist )
		vlist = NMCmdNum( ccnt, vlist )
		vlist = NMCmdStr( outputWavePrefix, vlist )
		
		NMCmdHistory( "Event2Wave", vlist )
	
		wlist = NMEvent2Wave( wName3, wName, before, after, stop, 1, ccnt, outputWavePrefix )
		
		wname = outputWavePrefix + "Times"
		
		if ( WaveExists( $wname ) == 1 )
		
			wname2 = "EV_Times_" + outputWavePrefix
			
			Duplicate /O $wname, $wname2
			KillWaves /Z $wname
			
		endif
		
		if ( strlen( wlist ) == 0 )
			return 0
		endif
		
		xl = NMChanLabel( ccnt, "x", "" )
		yl = NMChanLabel( ccnt, "y", "" )
		
		if ( tableNum >= 0 )
		
			gPrefix = outputWavePrefix + "_" + NMFolderPrefix( "" ) + ChanNum2Char( ccnt ) + num2istr( tableNum ) 
			gName = CheckGraphName( gPrefix )
			gTitle = NMFolderListName( "" ) + " : Ch " + ChanNum2Char( ccnt ) + " : " + tableSelect
		
		else
		
			gPrefix = outputWavePrefix + "_" + NMFolderPrefix( "" ) + ChanNum2Char( ccnt ) + num2istr( 0 ) 
			gName = CheckGraphName( gPrefix )
			gTitle = NMFolderListName( "" ) + " : Ch " + ChanNum2Char( ccnt ) + " : " + tableSelect
		
		endif
	
		NMPlotWavesOffset( gName, gTitle, xl, yl, "", wlist, 0, 0, 0, 0 )
		
	endfor

End // Event2WaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventHistoCall()
	
	String yl, subfolder, suffix, wName = "", wName2 = "", vlist = ""
	String tableList, tableSelect
	
	Variable tableNum = NMEventTableOldNum()
	
	String histoType = NMEventStr( "HistoSelect" )
	
	Variable reps = 0
	Variable dx = 1
	Variable v1 = -inf
	Variable v2 = inf
	Variable v3 = 0
	Variable v4 = inf
	
	tableList = NMEventSubfolderList( "", 0, 0 ) + NMEventTableOldListAll()
	
	if ( ItemsInList( tableList ) == 0 )
	
		NMDoAlert( "Detected no event table waves." )
		return -1
		
	else
	
		tableSelect = CurrentNMEventTableSelect()
		
		if ( WhichListItem( tableSelect, tableList ) < 0 )
			tableSelect = StringFromList( 0, tableList )
		endif
	
	endif
	
	Prompt tableSelect, "event table:", popup tableList
	Prompt histoType, "historgram type:", popup "time;interval;"
	
	Prompt v1, "include events from (ms):"
	Prompt v2, "include events to (ms):"
	Prompt v3, "minimum interval allowed (ms):"
	Prompt v4, "maximum interval allowed (ms):"
	
	Prompt dx, "histogram bin size (ms):"
	
	DoPrompt "Event Histogram", tableSelect, histoType
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	SetNMEventStr( "HistoSelect", histoType )
	
	if ( NMEventTableOldFormat( tableSelect ) == 1 )
	
		suffix = ReplaceString( NMEventTableOldSelectPrefix(), tableSelect, "" )
		wName = "EV_ThreshT_" + suffix
		wName2 = "EV_WaveN_" + suffix
		tableNum = EventNumFromName( wName )
		
	else
	
		subfolder = GetDataFolder(1) + tableSelect + ":"
		
		wname = NMEventSubfolderWaveName( subfolder, "ThreshT" )
		wname2 = NMEventSubfolderWaveName( subfolder, "WaveN" )
		
		tableNum = -1
	
	endif
	
	if ( WaveExists( $wName ) == 0 )
		NMDoAlert( "Event2Wave Abort: cannot locate wave of event times " + NMQuotes( wName ) )
		return -1
	endif
	
	if ( WaveExists( $wName2 ) == 0 )
		NMDoAlert( "Event2Wave Abort: cannot locate wave of wave numbers " + NMQuotes( wName2 ) )
		return -1
	endif
	
	strswitch( histoType )
			
		case "time":
		
			yl = "Events / bin"
			
			Prompt yl, "y-axis:" popup "Events / bin;Events / sec;Probability;"
			Prompt reps, "verifiy events were collected from this number of waves:"
			
			DoPrompt "Event Histogram", dx, v1, v2, yl
			
			if ( V_flag == 1 )
				break
			endif
			
			strswitch( yl )
			
				case "Events / sec":
				case "Probability":
			
					if ( WaveExists( $wName2 ) == 1 ) 
						reps = EventRepsCount( wName2 ) // get number of waves
					endif
					
					DoPrompt "Event Time Histogram", reps
					
					if ( V_flag == 1 )
						break
					endif
					
					if ( reps < 1 )
						NMDoAlert( "Bad number of waves." )
						return -1
					endif
				
			endswitch
			
			vlist = NMCmdStr( wName, vlist )
			vlist = NMCmdNum( reps, vlist )
			vlist = NMCmdNum( dx, vlist )
			vlist = NMCmdNum( v1, vlist )
			vlist = NMCmdNum( v2, vlist )
			vlist = NMCmdStr( yl, vlist )
			NMCmdHistory( "EventHisto", vlist )
			
			EventHisto( wName, reps, dx, v1, v2, yl )
			
			break
			
		case "interval":
			
			DoPrompt "Event Interval Histogram", dx, v1, v2, v3, v4
			
			if ( V_flag == 1 )
				break
			endif
			
			vlist = NMCmdStr( wName, vlist )
			vlist = NMCmdNum( dx, vlist )
			vlist = NMCmdNum( v1, vlist )
			vlist = NMCmdNum( v2, vlist )
			vlist = NMCmdNum( v3, vlist )
			vlist = NMCmdNum( v4, vlist )
			
			NMCmdHistory( "EventHistoIntvl", vlist )
			
			EventHistoIntvl( wName, dx, v1, v2, v3, v4 )
			
			break
			
	endswitch

End // EventHistoCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventHisto( wName, reps, bin, winB, winE, yl )
	String wName // wave name
	Variable reps // number of repititions ( number of waves )
	Variable bin // histo bin size
	Variable winB, winE // begin, end time
	String yl // y-axis dimensions ( see switch below )
	
	Variable nbins
	String hName, gPrefix, gName, gTitle, sName, path
	
	String xl = NMNoteLabel( "y", wName, "msec" )
	
	sName = GetPathName( wName, 0 )
	path = GetPathName( wName, 1 )
	hName = NextWaveName2( "", sName + "_hist", -1, NMEventOverWrite() )
	gPrefix = sName + "_" + NMFolderPrefix( "" ) + "PSTH"
	gName = NextGraphName( gPrefix, -1, 0 ) // no overwrite, due to long name
	gTitle = NMFolderListName( "" ) + " : " + sName + " Histogram"
	
	hName = path + hName
	
	Make /D/O/N=1 $hName
	
	WaveStats /Q/Z $wName
	
	nbins = ceil( ( V_max - V_min ) / bin )
	
	Histogram /B={V_min, bin, nbins} $wName, $hName
	
	if ( WaveExists( $hName ) == 0 )
		return -1
	endif
	
	wave histo = $hName
	
	strswitch( yl )
		case "Events / bin":
			break
		case "Events / sec":
			histo /= reps * bin * 0.001
			break
		case "Probability":
			histo /= reps
			break
	endswitch
	
	NMPlotWavesOffset( gName, gTitle, xl, yl, "", hName, 0, 0, 0, 0 )
	
	ModifyGraph mode=5, hbFill=2
	
	NMNoteType( hName, "Event Histogram", xl, yl, "Func:EventHisto" )
	
	Note $hName, "Histo Bin:" + num2str( bin ) + ";Histo Tbgn:" + num2str( winB ) + ";Histo Tend:" + num2str( winE ) + ";"
	Note $hName, "Histo Source:" + wName
	
End // EventHisto
	
//****************************************************************
//****************************************************************
//****************************************************************

Function EventHistoIntvl( wName, bin, winB, winE, isiMin, isiMax )
	String wName // wave name
	Variable bin // histo bin size
	Variable winB, winE
	Variable isiMin, isiMax
	
	Variable icnt, nbins
	String hName, gPrefix, gName, gTitle, sName, path
	
	String yl = "Intvls / bin"
	String xl = NMNoteLabel( "y", wName, "msec" )
	
	if ( numtype( winE ) > 0 )
		winE = NMEventVar( "SearchEnd" )
	endif
	
	if ( numtype( isiMax ) > 0 )
		isiMax = NMEventVar( "SearchEnd" )
	endif
	
	Variable events = Time2Intervals( wName, winB, winE, isiMin, isiMax ) // results saved in U_INTVLS ( function in Utility.ipf )

	if ( events <= 0 )
		NMDoAlert( "No inter-event intervals detected." )
		return -1
	endif
	
	sName = GetPathName( wName, 0 )
	path = GetPathName( wName, 1 )
	hName = NextWaveName2( "", sName + "_intvl", -1, NMEventOverWrite() )
	gPrefix = sName + "_" + NMFolderPrefix( "" ) + "ISIH"
	gName = NextGraphName( gPrefix, -1, 0 ) // no overwrite, due to long name
	gTitle = NMFolderListName( "" ) + " : " + sName + " Interval Histogram"
	
	hName = path + hName

	Make /D/O/N=1 $hName
	
	WaveStats /Q/Z U_INTVLS
	
	nbins = ceil( ( V_max - isiMin ) / bin )
	
	Histogram /B={isiMin, bin, nbins} U_INTVLS, $hName
	
	if ( WaveExists( $hName ) == 0 )
		return -1
	endif
	
	Wave histo = $hName
	
	for ( icnt = numpnts( histo ) - 1; icnt >= 0; icnt -= 1 )
		if ( histo[ icnt ] > 0 )
			break
		elseif ( histo[ icnt ] == 0 )
			histo[ icnt ] = Nan
		endif
	endfor
	
	WaveStats /Q/Z histo
	
	Redimension /N=( V_npnts ) histo
	
	NMPlotWavesOffset( gName, gTitle, xl, yl, "", hName, 0, 0, 0, 0 )
	
	ModifyGraph mode=5, hbFill=2
	
	WaveStats /Q/Z U_INTVLS
	
	SetAxis bottom 0, ( V_max*1.1 )
	
	NMNoteType( hName, "Event Intvl Histogram", xl, yl, "Func:EventHistoIntvl" )
	
	Note $hName, "Intvl Bin:" + num2str( bin ) + ";Intvl Tbgn:" + num2str( winB ) + ";Intvl Tend:" + num2str( winE ) + ";"
	Note $hName, "Intvl Min:" + num2str( isiMin ) + ";Intvl Max:" + num2str( isiMax ) + ";"
	Note $hName, "Intvl Source:" + wName
	
	Print "\rIntervals stored in wave U_INTVLS"

End // EventHistoIntvl

//****************************************************************
//****************************************************************
//****************************************************************