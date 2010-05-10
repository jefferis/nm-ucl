#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Auto Spike Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Created in the Laboratory of Dr. Angus Silver
//	Department of Physiology, University College London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Began 1 April 2007
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimSpikeDF()

	String sdf = StimDF()
	
	if (strlen(sdf) > 0)
		return sdf + "Spike:"
	else
		return ""
	endif

End // NMStimSpikeDF

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpike(enable)
	Variable enable // (0) no (1) yes
	
	if (DataFolderExists(StimDF()) == 0)
		return -1
	endif
	
	SpikeDisplay(-1, enable)
	
	return 0
	
End // ClampSpike

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimSpikeOn()
	
	return BinaryCheck(NumVarOrDefault(NMStimSpikeDF()+"SpikeOn", 0))
	
End // NMStimSpikeOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimSpikeOnSet(on)
	Variable on // (0) no (1) yes
	
	String ssdf = NMStimSpikeDF()
	
	on = BinaryCheck(on)
	
	if ((on == 1) && (DataFolderExists(ssdf) == 0))
		NewDataFolder $RemoveEnding( ssdf, ":" )
		SetNMvar(ssdf+"SpikeOn", 1)
		ClampSpikeSaveToStim()
	endif
	
	if ( DataFolderExists( ssdf ) == 1 )
		SetNMvar(ssdf+"SpikeOn", on)
	endif
	
	ClampSpike(on)
	
	return on

End // NMStimSpikeOnSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeSaveToStim() // save Spike variables to stim folder
	
	String spdf = SpikeDF()
	String ssdf = NMStimSpikeDF()
	
	if ( DataFolderExists(ssdf) == 0 )
		NewDataFolder $RemoveEnding( ssdf, ":" )
	endif
	
	if ( DataFolderExists(ssdf) == 1 )
		SetNMvar(ssdf+"Thresh", NumVarOrDefault(spdf+"Thresh", 20))
		SetNMvar(ssdf+"WinB", NumVarOrDefault(spdf+"WinB", -inf))
		SetNMvar(ssdf+"WinE", NumVarOrDefault(spdf+"WinE", inf))
		SetNMvar(ssdf+"ChanSelect", NumVarOrDefault(spdf+"ChanSelect", 0))
	endif
	
	return 0

End // ClampSpikeSaveToStim

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeRetrieveFromStim() // retrieve Spike variables from stim folder
	
	String spdf = SpikeDF()
	String ssdf = NMStimSpikeDF()
	
	if ( NMStimSpikeOn() == 0 )
		return 0
	endif
	
	if ( DataFolderExists( spdf ) == 1 )
		SetNMvar(spdf+"Thresh", NumVarOrDefault(ssdf+"Thresh", 20))
		SetNMvar(spdf+"WinB", NumVarOrDefault(ssdf+"WinB", -inf))
		SetNMvar(spdf+"WinE", NumVarOrDefault(ssdf+"WinE", inf))
		SetNMvar(spdf+"ChanSelect", NumVarOrDefault(ssdf+"ChanSelect", 0))
	endif
		
	return 0

End // ClampSpikeRetrieveFromStim

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeInit()

	if (NMStimSpikeOn() == 1)
		ClampSpikeSaveAsk()
		ClampSpikeRetrieveFromStim() // get Spike from new stim
		SpikeDisplayClear()
		ClampSpikeDisplaySavePosition()
		NMChanSelect( num2istr( NMSpikeVar( "ChanSelect" ) ) )
	else
		ClampSpikeRemoveWaves(1)
	endif
	
	ClampSpikeDisplaySetPosition()

End // ClampSpikeInit()

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeStart()
	
	ClampSpikeDisplay(0) // clear display
	ClampSpikeRemoveWaves(1) // kill waves
	
	if (NMStimSpikeOn() == 1)
		ClampSpikeRasterMake()
		ClampSpikeDisplay(1)
	endif

End // ClampSpikeStart

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeCompute(mode, currentWave, nwaves)
	Variable mode, currentWave, nwaves
	
	String xname = "SP_RasterX", yname = "SP_RasterY"
	String df = SpikeDF()
	
	Variable winB = NumVarOrDefault(df+"WinB", -inf)
	Variable winE = NumVarOrDefault(df+"WinE", inf)
	Variable thresh = NumVarOrDefault(df+"Thresh", 0)
	
	Variable currentChan = CurrentNMChannel()
	
	String chanWaveName = ChanDisplayWave( currentChan )
	
	if (NMStimSpikeOn() == 1)
	
		Make /O/N=0 SP_xtimes=Nan
		
		//SpikeRaster(CurrentNMChannel(), 0, Thresh, winB, winE, xname, yname, 1, 0)
		
		Findlevels /Q/R=( winB, winE )/D=SP_xtimes/Edge=1 $chanWaveName, thresh
		
		ClampSpikeRasterUpdate(currentWave)
		
		KillWaves /Z SP_xtimes
		
		ClampSpikeDisplayUpdate(currentWave, nwaves)
		
	endif

End // ClampSpikeCompute()

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeSaveAsk()
	
	Variable change
	
	String spdf = SpikeDF()
	String df = NMStimSpikeDF()
	
	if (NumVarOrDefault(spdf+"Thresh", 20) != NumVarOrDefault(df+"Thresh", 20))
		change = 1
	endif
	
	if (NumVarOrDefault(spdf+"WinB", -inf) != NumVarOrDefault(df+"WinB", -inf))
		change = 1
	endif
	
	if (NumVarOrDefault(spdf+"WinE", -inf) != NumVarOrDefault(df+"WinE", -inf))
		change = 1
	endif
	
	if (NumVarOrDefault(spdf+"ChanSelect", 0) != NumVarOrDefault(df+"ChanSelect", 0))
		change = 1
	endif
	
	if (change == 1)
	
		DoAlert 1, "Your Spike configuration has changed. Do you want to update the current stimulus configuration to reflect these changes?"
		
		if (V_flag == 1)
			ClampSpikeSaveToStim()
		endif
	
	endif

End // ClampSpikeSaveAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampSpikeRaster()

	return "CT_SpikeRaster"

End // ClampSpikeRaster

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeRasterMake()

	String df = NMStimSpikeDF()
	Variable chan = NMSpikeVar( "ChanSelect" )

	String xName = NextWaveName2("", "SP_RX_RAll_", chan, 1)
	String yName = NextWaveName2("", "SP_RY_RAll_", chan, 1)
	
	Make /O/N=0 $xName=Nan
	Make /O/N=0 $yName=Nan
	
	SetNMstr(df+"RasterWaveX", xName)
	SetNMstr(df+"RasterWaveY", yName)
	
	SetNMstr(SpikeDF()+"RasterWaveX", xName)
	SetNMstr(SpikeDF()+"RasterWaveY", yName)

End // ClampSpikeRasterMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeRasterUpdate(currentWave)
	Variable currentWave
	
	Variable nspikes, nraster, icnt, jcnt
	String df = NMStimSpikeDF()
	String spdf = SpikeDF()

	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	
	String spikeX = "SP_xtimes" //spdf+"SP_SpikeX"
	//String spikeY = "SP_RasterY" //spdf+"SP_SpikeY"
	
	if (WaveExists($spikeX) == 0)
		return 0
	endif
	
	if ((WaveExists($xRaster) == 0) || (WaveExists($yRaster) == 0))
		return 0
	endif
	
	Wave spkX = $spikeX
	//Wave spkY = $spikeY
	
	Wave rasterX = $xRaster
	Wave rasterY = $yRaster
	
	nraster = numpnts(rasterX)
	
	WaveStats /Q/Z spkX
	
	nspikes = V_npnts
	
	if (nspikes > 0)
	
		CheckNMwave(xRaster, nraster+nspikes+1, Nan)
		CheckNMwave(yRaster, nraster+nspikes+1, Nan)
		
		jcnt = nraster
		
		for (icnt = 0; icnt < numpnts(spkX); icnt += 1)
			
			if (numtype(spkX[icnt]) == 0)
				rasterX[jcnt] = spkX[icnt]
				rasterY[jcnt] = currentWave
				jcnt += 1
			endif
		
		endfor
	
	else
	
		CheckNMwave(xRaster, nraster+1, Nan)
		CheckNMwave(yRaster, nraster+1, Nan)
	
		rasterY[nraster] = currentWave
	
	endif

End // ClampSpikeRasterUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeDisplay(enable)
	Variable enable
	
	String wlist, wname
	String df = NMStimSpikeDF()
	Variable wcnt, winE = StimWaveLength("", 0)
	Variable nwaves = StimNumWavesTotal("")
	
	String gName = ClampSpikeRaster()
	String xRaster = StrVarOrDefault(df+"RasterWaveX", "")
	String yRaster = StrVarOrDefault(df+"RasterWaveY", "")
	String wPrefix = StrVarOrDefault("WavePrefix", "")
	
	Variable gexists = WinType(gName)
	
	//String folder = CurrentNMSpikeSubfolder()
	
	if (gexists == 1) // remove waves
	
		//wlist = NMFolderWaveList( folder, "*", ";", "WIN:"+gName, 0)
		wlist = WaveList( "*", ";", "WIN:"+gName )
		
		for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
			wname = StringFromList(wcnt, wlist)
			RemoveFromGraph /Z/W=$gName $wname
		endfor
		
	endif
	
	if ((NMStimSpikeOn() == 0) || (enable == 0))
		return 0
	endif
	
	if (gexists == 0)
		Make /O/N=0 CT_DummyWave
		DoWindow /K $gName
		Display /K=1/N=$gName/W=(0,0,200,100) CT_DummyWave as "NM Online Spike Analysis"
		RemoveFromGraph /Z CT_DummyWave
		KillWaves /Z CT_DummyWave
		ClampSpikeDisplaySetPosition()
	endif
	
	DoWindow /F $gName
	
	if ((WaveExists($xRaster) == 1) && (WaveExists($yRaster) == 1))
		AppendToGraph /W=$gName $yRaster vs $xRaster
		Label left NMNoteLabel("y", yRaster, wPrefix+"#")
		Label bottom NMNoteLabel("y", xRaster, "msec")
	endif
	
	ModifyGraph mode=3, marker=10, standoff=0, rgb=(65535,0,0)
	
	SetAxis left 0, 10
	SetAxis bottom 0, winE
	
End // ClampSpikeDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeDisplayUpdate(currentWave, numWaves) // resize spike display x-scale
	Variable currentWave
	Variable numWaves
	
	String raster = ClampSpikeRaster()
	
	Variable inc = 10
	Variable num = inc * (1 + floor(currentWave / inc))
	
	num = min(numWaves, num)

	if (WinType(raster) == 1)
		SetAxis /Z/W=$raster left 0, num
	endif
	
End // ClampSpikeDisplayUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeDisplaySavePosition()
	
	String raster = ClampSpikeRaster()
	String sdf = NMStimSpikeDF()
	
	if ( ( WinType(raster) == 1 ) && ( DataFolderExists( sdf ) == 1 ) )
	
		GetWindow $raster wsize
		
		if ((V_right > V_left) && (V_top < V_bottom))
			SetNMvar(sdf+"CSR_X0", V_left)
			SetNMvar(sdf+"CSR_Y0", V_top)
			SetNMvar(sdf+"CSR_X1", V_right)
			SetNMvar(sdf+"CSR_Y1", V_bottom)
		endif
		
	endif

End // ClampSpikeDisplaySavePosition

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeDisplaySetPosition()

	Variable x0, y0, x1, y1
	
	Variable xPixels = NMComputerPixelsX()
	Variable yPixels = NMComputerPixelsY()

	String raster = ClampSpikeRaster()
	String df = NMStimSpikeDF()
	
	Variable spikeOn = NMStimSpikeOn()
	
	if ( WinType(raster) == 0 )
		return 0
	endif
	
	if (spikeOn == 1)
	
		x0 = NumVarOrDefault(df+"CSR_X0", xPixels * 0.2)
		y0 = NumVarOrDefault(df+"CSR_Y0", yPixels * 0.5)
		x1 = NumVarOrDefault(df+"CSR_X1", x0 + 260)
		y1 = NumVarOrDefault(df+"CSR_Y1", y0 + 170)
		
		if (numtype(x0 * y0 * x1 * y1) == 0)
			MoveWindow /W=$raster x0, y0, x1, y1
			DoWindow /hide=0 $raster
		endif
		
	else
	
	DoWindow /hide=1 $raster
	
	endif
			
End // ClampSpikeDisplaySetPosition

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSpikeRemoveWaves(kill)
	Variable kill // (0) dont kill waves (1) kill waves
	
	Variable icnt
	String wname, wlist
	
	String raster = ClampSpikeRaster()
	//String folder = CurrentNMSpikeSubfolder()
	
	if ( WinType(raster) == 1 )
	
		//wlist = NMFolderWaveList( folder, "*", ";", "WIN:"+raster, 0 )
		wlist = WaveList( "*", ";", "WIN:"+raster )
		
		for ( icnt = 0; icnt < ItemsInList(wlist); icnt += 1 )
			wname = StringFromList(icnt, wlist)
			RemoveFromGraph /Z/W=$raster $wname
		endfor
		
	endif
	
	if ( kill == 1 )
		KillGlobals( "", "SP_*", "001" ) // kill Spike waves in current folder
	endif

End // ClampSpikeRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************