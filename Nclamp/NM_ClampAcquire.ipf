#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Acquisition Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	Created in the Laboratory of Dr. Angus Silver
//	Department of Physiology, University College London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Began 1 July 2003
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireCall( mode )
	Variable mode // ( 0 ) preview ( 1 ) record 
	
	String cdf = ClampDF()
	Variable error
	
	String aboard = StrVarOrDefault( cdf+"BoardSelect", "" )
	
	if ( StimChainOn( "" ) == 1 )
		error = ClampAcquireChain( aboard, mode )
	else
		error = ClampAcquire( aboard, mode )
	endif
	
	if ( error < 0 )
		ClampAutoBackupNM_Start()
	endif
	
	return error
	
End // ClampAcquireCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquire( board, mode )
	String board
	Variable mode // ( 0 ) preview ( 1 ) record
	
	Variable error
	String prefixFolder
	String cdf = ClampDF(), sdf = StimDF(), ldf = LogDF()
	
	Variable saveWhen = NumVarOrDefault( cdf+"SaveWhen", 0 )
	Variable AcqMode = NumVarOrDefault( sdf+"AcqMode", 0 )
	String path = StrVarOrDefault( cdf+"ClampPath", "" )
	
	Variable continuous = ( acqMode == 1 ) || ( acqMode == 4 )

	ClampError( 0, "" )
	
	ClampDataFolderSaveCheckAll() // make sure older data files have been saved
	
	if ( strlen( path ) == 0 )
		if ( strlen( ClampPathSet( "" ) ) == 0 )
			ClampError( 1, "Please specify " + NMQuotes( "save to" ) + " path on Clamp File tab." )
			return -1
		endif
	endif
	
	ClampAcquireCleanup() // kill previously made Clamp waves/variables in existing data folder
	
	if ( WinType( NotesTableName() ) == 2 )
		NotesTable( 1 ) // update notes if table is open
	endif
	
	ClampSaveSubPath()
	
	LogCheckFolder( ldf ) // check Log folder is OK
	
	if ( ClampConfigCheck() == -1 )
		ClampError( 1, "ClampConfigCheck" )
		return -1
	endif
	
	if ( ( continuous == 1 ) && ( saveWhen == 2 ) && ( mode == 1 ) )
		ClampError( 1, "Save While Recording is not allowed with continuous acquisition." )
		return -1
	endif
	
	StimWavesCheck( "", 0 )
	ClampPNcheckwaves() // update P \ N subtraction waves
	
	if ( ClampDataFolderCheck() == -1 )
		ClampError( 1, "ClampDataFolderCheck" )
		return -1
	endif
	
	if ( ( mode == 1 ) && ( ClampSaveTest( GetDataFolder( 0 ) ) == -1 ) )
		ClampError( 1, "Folder name conflicts with previously saved data: " + GetDataFolder( 0 ) )
		return -1
	endif
	
	StimBoardConfigsUpdateAll( "" )
	
	// no longer test timers
	//if ( NumVarOrDefault( cdf+"TestTimers", 1 ) == 1 )
	//if ( ClampAcquireManager( AcqBoard, -1, 0 ) == -1 ) // test timers
	//	return -1 
	//endif
	//endif
	
	prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
		SetNMvar( prefixFolder+"CurrentChan", 0 )
		SetNMvar( prefixFolder+"CurrentWave", 0 )
		SetNMvar( prefixFolder+"CurrentGrp", 0 )
		SetNMvar( prefixFolder+"NumWaves", 0 )
		SetNMstr( prefixFolder+"WaveSelect", "All" )
	endif
	
	SetNeuroMaticVar( "NumActiveWaves", 0 )
	SetNeuroMaticVar( "CurrentWave", 0 )
	SetNeuroMaticVar( "CurrentGrp", 0 )
	
	ClampStatsInit()
	ClampSpikeInit()

	if ( ( mode == 1 ) && ( ClampSaveBegin() == -1 ) )
	
		if ( strlen( prefixFolder ) > 0 )
			SetNMvar( prefixFolder+"NumWaves", 0 )
		endif

		ClampError( 1, "ClampSaveBegin" )
		
		return -1
		
	endif
	
	if ( NMMultiClampTelegraphsConfig( sdf ) != 0 )
		return -1
	endif
	
	DoUpdate
	
	error = ClampAcquireManager( board, mode, saveWhen )
	
	if ( ( error == -1 ) || ( NumVarOrDefault( cdf+"ClampError", -1 ) == -1 ) )
		
		if ( strlen( prefixFolder ) > 0 )
			SetNMvar( prefixFolder+"NumWaves", 0 )
		endif
		
		//ClampError( 1, "ClampAcquireManager" )
		
		return -1
		
	endif
	
	DoWindow /F NMPanel
	
	return 0
	
End // ClampAcquire

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireStart( mode, nwaves ) // update folders and graphs, start timers
	Variable mode // ( 0 ) preview ( 1 ) record
	Variable nwaves
	
	String cdf = ClampDF()
	String gtitle = "Clamp Acquire"
	String wPrefix = StrVarOrDefault( "WavePrefix", "Record" )
	String currentStim = StimCurrent()

	ClampDataFolderUpdate( nwaves, mode )
	ClampGraphsUpdate( mode )
	UpdateNMPanel( 0 )
	ClampButtonDisable( mode )
	
	ClampStatsStart()
	ClampSpikeStart()
	
	ClampPNinit()
	
	if ( mode >= 0 )
	
		ClampFxnExecute( "pre", 2 ) // init functions
		ClampFxnExecute( "inter", 2 )
		ClampFxnExecute( "post", 2 )
		
		ClampFxnExecute( "pre", 0 ) // compute pre-stim functions
		
	endif
	
	if ( NumVarOrDefault( cdf+"ClampError", -1 ) == -1 )
		return -1
	endif
	
	CallProgress( 0 )
	
	DoUpdate
	
	Variable tref = stopMSTimer( 0 )
	
	SetNMvar( cdf+"TimerRef", startMSTimer )
	
	return 0

End // ClampAcquireStart

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireNext( mode, nwaves ) // increment counters, online analyses
	Variable mode // ( 0 ) preview ( 1 ) record
	Variable nwaves
	
	Variable tstamp, tintvl, cancel, ccnt, chan
	
	String cdf = ClampDF(), sdf = StimDF()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	Variable numChannels = NumVarOrDefault( prefixFolder+"NumChannels", 0 )
	Variable currentWave = NumVarOrDefault( prefixFolder+"CurrentWave", 0 )
	Variable currentGrp = NumVarOrDefault( prefixFolder+"CurrentGrp", 0 )
	
	Variable numGrps = NumVarOrDefault( sdf+"NumStimWaves", 1 )
	
	Wave CT_TimeStamp, CT_TimeIntvl
	
	Variable tref = NumVarOrDefault( cdf+"TimerRef", 0 )
	
	String gtitle = StrVarOrDefault( cdf+"ChanTitle", "Clamp Acquire" )
	String gName = ChanGraphName( 0 )
	
	cancel = CallProgress( ( currentWave + 1 ) / nwaves )
	
	if ( WinType( gName ) == 1 )
		gtitle = NMFolderListName( "" ) + " : Ch A : " + num2istr( currentWave )
		DoWindow /T $gName, gtitle
	endif
	
	for ( ccnt = 0; ccnt < NumChannels; ccnt += 1 )
		if ( NumVarOrDefault( ChanDF( ccnt )+"AutoScale", 1 ) == 0 )
			ChanGraphAxesSet( ccnt )
		endif
	endfor
	
	ClampStatsCompute( mode, currentWave, nwaves )
	ClampSpikeCompute( mode, currentWave, nwaves )
	
	if ( mode >= 0 )
		ClampFxnExecute( "inter", 0 )
	endif
	
	tintvl = stopMSTimer( tref )/1000
	tref = startMSTimer
	tstamp = tintvl
	
	SetNMvar( cdf+"TimerRef", tref )
	
	if ( currentWave == 0 )
		tintvl = Nan
	else
		tstamp += CT_TimeStamp[currentWave-1]
	endif
	
	CT_TimeStamp[currentWave] = tstamp
	CT_TimeIntvl[currentWave] = tintvl
	
	currentWave += 1
	currentGrp += 1
	
	if ( currentGrp >= numGrps )
		currentGrp = 0
	endif
	
	SetNMvar( prefixFolder+"CurrentWave", currentWave )
	SetNMvar( prefixFolder+"CurrentGrp", currentGrp )
	
	SetNeuroMaticVar( "CurrentWave", currentWave )
	SetNeuroMaticVar( "CurrentGrp", currentGrp )
	
	DoUpdate
	
	return cancel

End // ClampAcquireNext

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireFinish( mode, savewhen, background )
	Variable mode // ( 0 ) preview ( 1 ) record ( -1 ) test timers ( -2 ) error
	Variable savewhen // ( 0 ) never ( 1 ) after ( 2 ) while
	Variable background // start background save function ( 0 ) no ( 1 ) yes
	
	Variable nwaves
	String file, cdf = ClampDF(), sdf = StimDF()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable currentWave = CurrentNMWave()
	Variable nchans = NMNumChannels()
	
	Variable numGrps = NumVarOrDefault( sdf+"NumStimWaves", 0 )
	
	SetNMstr( "FileFinish", time() )
	
	CallProgress( 1 ) // close progress window
	
	ClampStatsFinish( currentWave )
	
	nwaves = currentWave
	
	if ( mode < 0 ) // test, error
		nwaves = 0
	elseif ( mode == 0 ) // preview
		nwaves = 1
	endif
	
	SetNMvar( prefixFolder+"NumWaves", nwaves )
	
	SetNMvar( prefixFolder+"CurrentChan", 0 )
	SetNMvar( prefixFolder+"CurrentWave", 0 )
	setNMvar( prefixFolder+"CurrentGrp", 0 )
	
	SetNeuroMaticVar( "CurrentWave", 0 )
	SetNeuroMaticVar( "CurrentGrp", 0 )
	SetNeuroMaticVar( "NumActiveWaves", nchans * nwaves )
	
	ClampGraphsFinish()
	CheckNMDataFolder( "" )
	NMChanWaveListSet( 1 ) // set channel wave names
	UpdateNMPanel( 0 )
	ClampTgainConvert()
	
	if ( NumVarOrDefault( sdf+"MultiClamp700", 0 ) == 1 )
		NMMultiClampTelegraphsSave( "" )
	endif
	
	ClampAcquireNotes()
	
	if ( mode >= 0 )
		ClampFxnExecute( "post", 0 ) // compute post-stim analyses
	endif
	
	if ( mode == 1 ) // record and update Notes and Log variables
	
		if ( strlen( StrVarOrDefault( NotesDF()+"H_Name", "" ) ) == 0 )
			NotesEditHeader()
		endif
		
		NotesBasicUpdate()
		NotesCopyVars( LogDF(),"H_" ) // update header Notes
		NotesCopyFolder( GetDataFolder( 1 )+"Notes" ) // copy Notes to data folder
		
		NMGroupsSequenceBasic( numGrps )
		NMPrefixSelectSilent( StrVarOrDefault( "WavePrefix", "Record" ) )
		
		NMChanSelect( "A" )
		NMWaveSelect( "All" )
		
		ClampSaveFinish( "" ) // save data folder
		NotesBasicUpdate() // do again, this includes new external file name
		NotesCopyFolder( LogDF()+StrVarOrDefault( cdf+"CurrentFolder","nofolder" ) ) // save log notes
		
		if ( NumVarOrDefault( cdf+"LogAutoSave", 1 ) == 1 )
			LogSave()
		endif
		
		LogDisplay2( LogDF(), NumVarOrDefault( cdf+"LogDisplay", 1 ) )
		
		NotesClearFileVars() // clear file note vars before next recording
		
	endif
	
	ClampButtonDisable( -1 )
	
	ClampAvgInterval()
	
	if ( background == 1 )
		ClampAutoBackupNM_Start()
	endif
	
	//if ( ( mode == 1 ) && ( NMvar( "AutoPlot" ) == 1 ) )
	//	ResetCascade()
	//	NMPlot( "" )
	//endif
	
	return 0

End // ClampAcquireFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireChain( board, mode )
	String board
	Variable mode //  // ( 0 ) preview ( 1 ) record
	
	Variable scnt, npnts
	String sname, cdf = ClampDF(), sdf = StimDF()

	if ( WaveExists( $( sdf+"Stim_Name" ) ) == 0 )
		return -1
	endif
	
	String aboard = StrVarOrDefault( cdf+"AcqBoard", "" )
	String saveStim = StimCurrent()
	
	Wave /T Stim_Name = $( sdf+"Stim_Name" )
	Wave Stim_Wait = $( sdf+"Stim_Wait" )
	
	if ( numpnts( Stim_Name ) == 0 )
		ClampError( 1, "Alert: no stimulus protocols in Run Stim List." )
		return -1
	endif
	
	npnts = numpnts( Stim_Name )
	
	for ( scnt = 0; scnt < npnts; scnt += 1 )
	
		sname = Stim_Name[scnt]
		
		if ( strlen( sname ) == 0 )
			continue
		endif
		
		if ( IsStimFolder( StimParent(), sname ) == 0 )
			DoAlert 0, "Alert: stimulus protocol " + NMQuotes( sname ) + " does not appear to exist."
			continue
		endif
		
		if ( strlen( StimCurrentSet( sname ) ) > 0 )
			ClampTabUpdate()
			ClampAcquire( board, mode )
			ClampWait( Stim_Wait[scnt] ) // delay in acquisition
		endif
		
		if (NMProgressCancel() == 1 )
			break
		endif
		
	endfor
	
	StimCurrentSet( saveStim )
	ClampTabUpdate()

End // ClampAcquireChain

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireNotes()

	Variable ccnt, wcnt, config, scale
	String wName, wNote, yl, modeStr, type = "NMData"
	String sdf = StimDF(), bdf = StimBoardDF( sdf ), onList = StimBoardOnList( sdf, "ADC" )
	
	String stim = StimCurrent()
	String folder = GetDataFolder( 0 )
	String fdate = StrVarOrDefault( "FileDate", "" )
	String ftime = StrVarOrDefault( "FileTime", "" )
	String xl = StrVarOrDefault( "xLabel", "msec" )
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable nchans = NumVarOrDefault( prefixFolder+"NumChannels", 0 )
	Variable nwaves = NumVarOrDefault( prefixFolder+"NumWaves", 0 )
	
	wName = bdf + "ADCname"
	
	if ( WaveExists( $wName ) == 0 )
		return 0
	endif
	
	if ( WaveExists( CT_TimeStamp ) == 0 )
		return 0
	endif
	
	Wave /T ADCname = $bdf+"ADCname"
	Wave /T ADCunits = $bdf+"ADCunits"
	Wave /T ADCmode = $bdf+"ADCmode"
	Wave ADCboard = $bdf+"ADCboard"
	Wave ADCchan = $bdf+"ADCchan"
	Wave ADCgain = $bdf+"ADCgain"
	Wave ADCscale = $bdf+"ADCscale"
	
	Wave CT_TimeStamp
	Wave /T yLabel
	
	for ( ccnt = 0; ccnt < nchans ; ccnt += 1 )
	
		yl = yLabel[ccnt]
		
		config = -1
		
		if ( ccnt < ItemsInList( onList ) )
			config = str2num( StringFromList( ccnt, onList ) )
		endif
	
		for ( wcnt = 0; wcnt < nwaves; wcnt += 1 )
	
			wName = GetWaveName( "default", ccnt, wcnt )
			
			if ( WaveExists( $wName ) == 0 )
				continue
			endif
			
			scale = NMNoteVarByKey( wName, "Scale Factor" ) // saved during acquisition
			
			NMNoteType( wName, type, xl, yl, "Stim:" + stim )
			
			Note $wName, "Folder:" + folder
			Note $wName, "Date:" + NMNoteCheck( fdate )
			Note $wName, "Time:" + NMNoteCheck( ftime )
			Note $wName, "Time Stamp:" + num2strLong( CT_TimeStamp[ wcnt ], 3 ) + " msec"
			Note $wName, "Chan:" + ChanNum2Char( ccnt )
			
			if ( numtype( scale ) == 0 )
				Note $wName, "ADCscale:" + num2str( scale )
			endif
			
			if ( config >= 0 )
			
				modeStr = ADCmode[ config ]
				
				if ( strlen( modeStr ) == 0 )
					modestr = "Normal"
				else
					Note $wName, "ADCmode:" + modeStr
				endif
				
				if ( NMMultiClampTelegraphMode( modeStr ) == 1 )
				
					NMMultiClampWaveNotes( wName, modeStr )
				
				else
			
					Note $wName, "ADCname:" + ADCname[ config ]
					Note $wName, "ADCunits:" + ADCunits[ config ]
					Note $wName, "ADCunitsX:msec" + ADCunits[ config ]
					Note $wName, "ADCboard:" + num2istr( ADCboard[ config ] )
					Note $wName, "ADCchan:" + num2istr( ADCchan[ config ] )
					Note $wName, "ADCgain:" + num2str( ADCgain[ config ] )
					
				endif
				
			endif
		
		endfor
		
	endfor
	
End // ClampAcquireNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireDemo( mode, savewhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime )
	Variable mode // ( 0 ) preview ( 1 ) record
	Variable savewhen // ( 0 ) never ( 1 ) after ( 2 ) while
	Variable WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime // msec
	
	Variable nwaves, rcnt, wcnt, config, chan, chanCount, scale
	String wname, modeStr, gdf, cdf = ClampDF(), sdf = StimDF(), bdf = StimBoardDF( sdf )
	
	Variable currentWave = CurrentNMWave()
	
	Variable acqMode = NumVarOrDefault( sdf+"AcqMode", 0 )
	
	if ( ( acqMode  == 1 ) || ( acqMode  == 4 ) ) // continuous
		InterStimTime = 0
		InterRepTime = 0
	endif
	
	Variable pulseOff = NumVarOrDefault( sdf+"PulseGenOff", 0 )
	Variable SampleInterval = NumVarOrDefault( sdf+"SampleInterval", 0 )
	Variable SamplesPerWave = WaveLength / SampleInterval
	
	if ( WaveExists( $bdf+"ADCname" ) == 0 )
		return -1
	endif
	
	Wave /T ADCname = $( bdf+"ADCname" )
	Wave ADCscale = $( bdf+"ADCscale" )
	Wave /T ADCmode = $( bdf+"ADCmode" )
	
	Wave /T DACname = $( bdf+"DACname" )
	Wave DACchan = $( bdf+"DACchan" )
	
	Wave /T TTLname = $( bdf+"TTLname" )
	Wave TTLchan = $( bdf+"TTLchan" )
	
	Make /O/N=( SamplesPerWave ) CT_OutTemp
	Setscale /P x 0, SampleInterval, CT_OutTemp
	
	nwaves = NumStimWaves * NumStimReps // total number of waves

	if ( ClampAcquireStart( mode, nwaves ) == -1 )
		return -1
	endif
	
	for ( rcnt = 0; rcnt < NumStimReps; rcnt += 1 ) // loop thru reps
	
		if ( NMProgressCancel() == 1 )
			break
		endif
	
		for ( wcnt = 0; wcnt < NumStimWaves; wcnt += 1 ) // loop thru stims
		
			if ( NMProgressCancel() == 1 )
				break
			endif
			
			CT_OutTemp = 0
			
			for ( config = 0; config < numpnts( DACname ); config += 1 )
			
				if ( strlen( DACname[config] ) > 0 )
				
					chan = DACchan[config]
				
					//if ( pulseOff == 0 )
						wname = sdf + StimWaveName( "DAC", config, wcnt )
					//else
					//	wname = sdf + StimWaveName( "MyDAC", config, wcnt )
					//endif
					
					if ( WaveExists( $wname ) == 1 )
						Wave wtemp = $wname
						if ( numpnts( CT_OutTemp ) != numpnts( wtemp ) )
							Redimension /N=( numpnts( wtemp ) ) CT_OutTemp
						endif
						CT_OutTemp += wtemp
					endif
					
				endif
				
			endfor
			
			for ( config = 0; config < numpnts( TTLname ); config += 1 )
			
				if ( strlen( TTLname[config] ) > 0 )
				
					chan = TTLchan[config]
					
					//if ( pulseOff == 0 )
						wname = sdf + StimWaveName( "TTL", config, wcnt )
					//else
					//	wname = sdf + StimWaveName( "MyTTL", config, wcnt )
					//endif
					
					if ( WaveExists( $wname ) == 1 )
						Wave wtemp = $wname
						if ( numpnts( CT_OutTemp ) != numpnts( wtemp ) )
							Redimension /N=( numpnts( wtemp ) ) CT_OutTemp
						endif
						CT_OutTemp += wtemp
					endif
					
				endif
				
			endfor
			
			ClampWaitMSTimer( WaveLength ) // simulates delay in acquisition
			
			chanCount = 0
	
			for ( config = 0; config < numpnts( ADCname ); config += 1 )
			
				modeStr = ADCmode[ config ]
			
				if ( ( strlen( ADCname[config] ) > 0 ) && ( StimADCmodeNormal( modeStr ) == 1 ) ) // stim/samp
				
					gdf = ChanDF( chanCount )
					
					if ( NumVarOrDefault( gdf+"overlay", 0 ) > 0 )
						ChanOverlayUpdate( chanCount )
					endif
					
					if ( mode == 1 ) // record
						wname = GetWaveName( "default", chanCount, wcnt )
					else // preview
						wname = GetWaveName( "default", chanCount, 0 )
					endif
					
					if ( NMMultiClampTelegraphMode( modeStr ) == 1 )
					
						if ( NMMultiClampTelegraphWhile() == 1 )
							scale = NMMultiClampScaleCall( modeStr )
						else
							scale = NMMultiClampADCNum( sdf, config, "scale" )
						endif
						
					else
					
						scale = ADCscale[ config ]
						
					endif
					
					if ( ( numtype( scale ) > 0 ) || ( scale <= 0 ) )
						scale = 1
					endif
					
					CT_OutTemp /= scale
					
					Duplicate /O CT_OutTemp $wname
					
					Note $wname, "Scale Factor:" + num2str( scale )
	
					ChanWaveMake( chanCount, wName, ChanDisplayWave( chanCount ) ) // make display wave
			
					if ( ( mode == 1 ) && ( saveWhen == 2 ) )
						ClampNMbinAppend( wname ) // update waves in saved folder
					endif
					
					chanCount += 1
					
				endif
				
			endfor
			
			ClampAcquireNext( mode, nwaves )
			
			ClampWaitMSTimer( InterStimTime ) // inter-wave time
	
		endfor
		
		ClampWaitMSTimer( InterRepTime ) // inter-rep time
		
	endfor
	
	KillWaves /Z CT_OutTemp
	
	ClampAcquireFinish( mode, savewhen, 1 )
	
	return 0

End // ClampAcquireDemo

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAvgInterval()
	Variable rcnt, wcnt, wwe, we, wn, rre, re, rn, dr, icnt, isi
	String txt, sdf = StimDF()
	
	Variable acqMode = NumVarOrDefault( sdf + "AcqMode", -1 )
	Variable WaveLength = NumVarOrDefault( sdf+"WaveLength", 0 )
	Variable NumStimWaves = NumVarOrDefault( sdf+"NumStimWaves", 0 )
	Variable interStimTime = NumVarOrDefault( sdf+"InterStimTime", 0 )
	Variable NumStimReps = NumVarOrDefault( sdf+"NumStimReps", 0 )
	Variable interRepTime = NumVarOrDefault( sdf+"InterRepTime", 0 )
	
	if ( ( acqMode != 2 ) || ( WaveExists( CT_TimeIntvl ) == 0 ) )
		return 0
	endif
	
	wwe = WaveLength + interStimTime
	rre = wwe + interRepTime
	
	Wave CT_TimeIntvl
	
	for ( rcnt = 0; rcnt < NumStimReps; rcnt += 1 ) // loop thru reps
	
		for ( wcnt = 0; wcnt < NumStimWaves; wcnt += 1 ) // loop thru stims
			
			//dw = WaveLength + interStimTime + dr
			isi = CT_TimeIntvl[icnt]
			
			if ( numtype( isi ) == 0 )
				if ( dr == 0 ) // clock controlling inter-stim times
					we += isi
					wn += 1
				else // clock controlling inter-rep times
					re += isi
					rn += 1
				endif
			endif
			
			dr = 0
			icnt += 1
			
		endfor
		
		dr = interRepTime
		
	endfor
	
	if ( wn > 0 )
		we /= wn
		Print "Average episodic wave interval:", we//, " ms; error = ", ( we - wwe ), " ms"
	endif
	
	if ( rn > 0 )
		re /= rn
		Print "Average episodic rep interval:", re//, " ms; error = ", ( re - rre ), " ms"
	endif

End // ClampAvgInterval

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireManager( atype, callmode, savewhen ) // call appropriate aquisition function
	String atype // acqusition board ( "Demo", "ITC", "NIDAQ" )
	Variable callmode // ( 0 ) preview ( 1 ) record ( -2 ) config test
	Variable savewhen // ( 0 ) never ( 1 ) after ( 2 ) while
	
	String cdf = ClampDF(), sdf = StimDF() 
	
	Variable WaveLength = NumVarOrDefault( sdf+"WaveLength", 0 )
	Variable NumStimWaves = NumVarOrDefault( sdf+"NumStimWaves", 0 )
	Variable interStimTime = NumVarOrDefault( sdf+"InterStimTime", 0 )
	Variable NumStimReps = NumVarOrDefault( sdf+"NumStimReps", 0 )
	Variable interRepTime = NumVarOrDefault( sdf+"InterRepTime", 0 )
	
	String currentStim = StimCurrent()
	
	ClampError( 0, "" )
	
	KillBackground
	
	switch( callmode )
		case 0: // preview
			SetNeuroMaticStr( "ProgressStr", "Preview : " + currentStim )
			break
		case 1: // record
			SetNeuroMaticStr( "ProgressStr", "Record : " + currentStim )
			break
		default:
			SetNeuroMaticStr( "ProgressStr", "" )
			break
	endswitch

	strswitch( atype )
	
		case "Demo":
		
			switch( callmode )
			
				case -2: // test config
					ClampConfigDemo()
					break
					
				case 0: // preview
				case 1: // record
					ClampAcquireDemo( callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime )
					break
					
				default:
					ClampError( 1, "demo acquire mode " + num2istr( callmode ) + " not supported." )
					return -1
					
			endswitch
			
			break
		
		case "NIDAQ":
			
			switch( callmode )
			
				case -2: // config
					//SetNMvar( cdf+"BoardDriver", -1 )
					Execute /Z "NIDAQconfig()"
					if ( V_flag != 0 )
						ClampError( 1, "cannot locate function in NM_ClampNIDAQ.ipf" )
						return -1
					endif
					break
					
				case 0: // preview
				case 1: // record
					Execute /Z "NIDAQacquire" + ClampParameterList( callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime )
					if ( V_flag != 0 )
						ClampError( 1, "cannot locate function in NM_ClampNIDAQ.ipf" )
						return -1
					endif
					break
					
				default:
					ClampError( 1, "NIDAQ acquire mode " + num2istr( callmode ) + " not supported." )
					return -1
					
			endswitch
			
			break
			
		case "ITC16":
		case "ITC18":
		
			switch( callmode )
				case -2: // config
					Execute /Z "ITCconfig( " + NMQuotes( atype ) + " )"
					if ( V_flag != 0 )
						ClampError( 1, "cannot locate function in NM_ClampITC.ipf" )
						return -1
					endif
					break
					
				case 0: // preview
				case 1: // record
					Execute /Z "ITCacquire" + ClampParameterList( callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime )
					if ( V_flag != 0 )
						ClampError( 1, "cannot locate function in NM_ClampITC.ipf" )
						return -1
					endif
					break
					
				default:
					ClampError( 1, "ITC acquire mode " + num2istr( callmode ) + " not supported" )
					return -1
					
			endswitch
			
			break
			
		default:
			ClampError( 1, "interface " + atype + " is not supported." )
			return -1
			break
		
	endswitch

	return NumVarOrDefault( cdf+"ClampError", -1 )

End // ClampAcquireManager

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampReadManager( atype, board, ADCchan, gain, npnts ) // call appropriate read function
	String atype // acqusition board ( "Demo", "ITC", "NIDAQ" )
	Variable board
	Variable ADCchan // ADC input channel to read
	Variable gain
	Variable npnts // number of points to average
	
	String cdf = ClampDF(), vlist = ""
	
	SetNMvar( cdf+"ClampReadValue", Nan )
	
	if ( numtype( board * ADCchan * gain * npnts ) > 0 )
		return Nan
	endif
	
	strswitch( atype )
	
		case "Demo":
			return Nan
		
		case "NIDAQ":
		
			vlist = AddListItem( num2istr( board ), vlist, ",", inf )
			vlist = AddListItem( num2istr( ADCchan ), vlist, ",", inf )
			vlist = AddListItem( num2str( gain ), vlist, ",", inf )
			vlist += num2istr( npnts ) 
			
			Execute /Z "NIDAQread( " + vlist + " )"
			
			if ( V_flag != 0 )
				ClampError( 1, "cannot locate function in NM_ClampNIDAQ.ipf" )
				return Nan
			endif
			
			break
			
		case "ITC16":
		case "ITC18":
		
			vlist = AddListItem( num2istr( ADCchan ), vlist, ",", inf )
			vlist = AddListItem( num2str( gain ), vlist, ",", inf )
			vlist += num2istr( npnts ) 
			
			Execute /Z "ITCread( " + vlist + " )"
			
			if ( V_flag != 0 )
				ClampError( 1, "cannot locate function in NM_ClampITC.ipf" )
				return Nan
			endif
			
			break
			
		default:
			ClampError( 1, "interface " + atype + " is not supported." )
			return Nan
			
	endswitch

	return NumVarOrDefault( cdf+"ClampReadValue", Nan )
	
End // ClampReadManager

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampParameterList( callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime )
	Variable callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime

	String paramstr = "("+num2istr( callmode )+","+num2str( savewhen )+","+num2str( WaveLength )+","+num2istr( NumStimWaves )+","
	paramstr += num2str( interStimTime )+","+num2str( NumStimReps )+","+num2str( interRepTime )+")"
	
	return paramstr

End // ClampParameterList

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampFxnExecute( select, mode )
	String select
	Variable mode // ( 0 ) preview ( 1 ) record 
	
	Variable icnt
	String flist, fxn
	
	flist = StimFxnList( "", select )
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
	
		fxn = StringFromList( icnt, flist )
		
		if ( StringMatch( fxn[strlen( fxn )-3,strlen( fxn )-1],"(0)" ) == 0 )
			fxn += "(" + num2istr( mode ) + ")" // run function
		endif
		
		Execute /Z fxn
		
	endfor

End // ClampFxnExecute

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigCheck()
	
	if ( StimBoardOnCount( "", "ADC" ) == 0 )
		ClampError( 1, "ADC input has not been configured." )
		return -1
	endif
	
	if ( StimBoardConfigsCheckDuplicates( "" ) < 0 )
		return -1
	endif
	
	return 0
	
End // ClampConfigCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigDemo()
	
	SetNMStr( ClampDF()+"BoardSelect", "Demo" )

End // ClampConfigDemo

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWavesNumpnts( DAClist, TTLlist, defaultNpnts )
	String dacList, ttlList
	Variable defaultNpnts
	
	Variable icnt, npnts = defaultNpnts
	String item, wname, list = DAClist
	
	list = AddListItem( TTLlist, DAClist, ";", inf )
	
	for ( icnt = 0; icnt < ItemsInList( list ); icnt += 1 )
			
		item = StringFromList( icnt, list )
		wname = StringFromList( 0, item, "," )

		if ( WaveExists( $wname ) == 1 )
			npnts = numpnts( $wname )
		endif
		
	endfor

	return npnts

End // ClampWavesNumpnts

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireCleanup()

	Variable icnt
	String vname, vlist = VariableList("CT_*",";",6)
	
	for ( icnt = 0 ; icnt < ItemsInList( vlist ) ; icnt += 1 )
		vname = StringFromList( icnt, vlist )
		KillVariables /Z $vname
	endfor
	
	vlist = StringList("CT_*",";")

	for ( icnt = 0 ; icnt < ItemsInList( vlist ) ; icnt += 1 )
		vname = StringFromList( icnt, vlist )
		KillStrings /Z $vname
	endfor
	
	vlist = WaveList("CT_*",";", "")
	
	for ( icnt = 0 ; icnt < ItemsInList( vlist ) ; icnt += 1 )
		vname = StringFromList( icnt, vlist )
		KillWaves /Z $vname
	endfor

End // ClampAcquireCleanup

//****************************************************************
//****************************************************************
//****************************************************************