#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp ITC Acquisition Functions (ITC16/ITC18)
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
//	Began 1 July 2003
//	Last modified 10 March 2008
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ITCconfig(aboard)
	String aboard
	
	String cdf = ClampDF()
	
	Execute /Z aboard + "Reset" // attemp to reset ITC board

	if (V_flag != 0)
		//ClampError("unrecognized board : " + aboard)
		return -1
	else
		SetNMVar(cdf+"BoardDriver", 0)
		SetNMStr(cdf+"BoardList", aboard + ";")
	endif
	
	return 0
	
End // ITCconfig

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCdebug()

	String cdf = ClampDF()
	
	Variable ITC18_SeqExtraParameter = 1 // (0) no (1) yes
	Variable ITC_ResetDuringAcquisition = 0 // (0) no (1) yes
	Variable ITC_SetRange = 1 // (0) no (1) yes
	
	SetNMvar(cdf+"ITC18_SeqExtraParameter", ITC18_SeqExtraParameter)
	SetNMvar(cdf+"ITC_ResetDuringAcquisition", ITC_ResetDuringAcquisition)
	SetNMvar(cdf+"ITC_SetRange", ITC_SetRange)

End // ITCdebug

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCerror(alertStr, errorStr)
	String alertStr, errorStr
	
	String cdf = ClampDF()
	
	SetNMstr(cdf+"ClampErrorStr", errorStr)
	SetNMvar(cdf+"ClampError", -1)
	DoUpdate
	DoAlert 0, alertStr + " : " + errorStr
	ClampAcquireFinish(-2, 0)

End // ITCerror

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCacquire(mode, savewhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime)
	Variable mode // (0) preview (1) record (-1) test timers
	Variable savewhen // (0) never (1) after (2) while
	Variable WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime
	
	Variable sizeFIFO = 256000
	
	String cdf = ClampDF(), sdf = StimDF()
	
	String aboard = StrVarOrDefault(cdf+"AcqBoard", "")
	
	Variable acqMode = NumVarOrDefault(sdf+"AcqMode", 0)
	Variable SampleInterval = NumVarOrDefault(sdf+"SampleInterval", 0)
	
	Make /I/O/N=1 $(cdf+"Avail2Read"), $(cdf+"Avail2Write")
	
	Wave Avail2Read = $cdf+"Avail2Read"
	Wave Avail2Write = $cdf+"Avail2Write"
	
	if (ITCupdateLists(NumStimWaves) == -1)
		return -1 // bad input/output configuration
	endif
	
	String seqstr = ITCseqStr()
	
	Variable outs = strlen(StringFromList(0, seqstr))
	Variable ins = strlen(StringFromList(1, seqstr))
	
	if (outs != ins) // double check
		ITCError("ITC Config Error", "configuration error.")
		return -1
	endif
	
	//Execute aboard + "Reset"
	//Execute aboard + "WriteAvailable " + cdf + "Avail2Write"
	//sizeFIFO = Avail2Write[0]
	
	Variable pnts = ceil((WaveLength + InterStimTime) * ins / SampleInterval)
	
	if (acqMode == 0) // test to see if short mode is possible
	
		if (pnts > sizeFIFO/2) // must be able to load at least two for fast episodic
			ITCError("ITC Config Error", "epic precise mode not feasible. Please use episodic mode instead.")
			return -1
		endif
		
	endif
	
	SetNMvar(cdf+"AcqMode", acqMode) // set temporary variable in ClampDF
	
	SetNMvar(cdf+"InterStimTime", InterStimTime)
	SetNMvar(cdf+"InterRepTime", InterRepTime)
	
	switch(acqMode)
		case 0: // epic precise
		case 1: // continuous
			ITCAcqPrecise(mode, savewhen)
			break
		case 2: // episodic
		case 3: // triggered
			ITCAcqLong(mode, savewhen)
			break
	endswitch 
	
End // ITCacquire

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCAcqPrecise(mode, savewhen)
	Variable mode // (0) preview (1) record (-1) test timers
	Variable savewhen // (0) never (1) after (2) while

	Variable nwaves, rcnt, ccnt, wcnt, icnt, period, pipe
	Variable stimcnt, stimtotal, sampcnt, samptotal, savecnt
	Variable outpnts, inpnts, npnts, scale, config
	Variable gain, tgain, tgainavg, tgainv, cancel, outs, ins
	Variable flip, flipread, flipsave
	Variable firstread = 1, firstwrite = 1
	
	String wname, dname, inName, outName, saveName, alist, dlist, tlist
	String item, chanstr, seqstr, ITCoutList, ITCinList, instr
	
	String cdf = ClampDF(), sdf = StimDF(), bdf = StimBoardDF(sdf)
	
	NVAR CurrentWave
	
	String aboard = StrVarOrDefault(cdf+"AcqBoard", "")
	
	Variable NumStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable NumStimReps = NumVarOrDefault(sdf+"NumStimReps", 0)
	
	NVAR InterStimTime = $cdf+"InterStimTime"
	NVAR InterRepTime = $cdf+"InterRepTime"
	
	Variable SampleInterval = NumVarOrDefault(sdf+"SampleInterval", 0)
	Variable acqMode = NumVarOrDefault(cdf+"AcqMode", 0)
	
	strswitch(aboard)
		case "ITC16":
		case "ITC18":
			break
		default:
			ITCError("ITC Config Error", "unrecognized board : " + aboard)
			return -1
	endswitch
	
	nwaves = NumStimWaves * NumStimReps // total number of waves
	
	//Make /I/O/N=1 $(cdf+"Avail2Read"), $(cdf+"Avail2Write")
	
	Wave Avail2Read = $cdf+"Avail2Read"
	Wave Avail2Write = $cdf+"Avail2Write"

	//if (ITCupdateLists(NumStimWaves) == -1)
	//	return -1 // bad input/output configuration
	//endif
	
	Wave ADCscale = $bdf+"ADCscale"
	Wave ADCchan = $bdf+"ADCchan"
	Wave /T ADCmode = $bdf+"ADCmode"
	
	Wave stimPnts = $cdf+"StimNumpnts"
	
	Wave /T ADClist = $cdf+"ADClist"
	Wave /T DAClist = $cdf+"DAClist"
	Wave /T TTLlist = $cdf+"TTLlist"
	Wave /T preADClist = $cdf+"preADClist"
	
	Variable tGainConfig = NumVarOrDefault(cdf+"TGainConfig", 0)
	//String instr = StrVarOrDefault(cdf+"ClampInstrument", "")
	
	Variable ITC18_SeqExtraParameter = NumVarOrDefault(cdf+"ITC18_SeqExtraParameter", 1)
	Variable ITC_ResetDuringAcquisition = NumVarOrDefault(cdf+"ITC_ResetDuringAcquisition", 0)
	Variable ITC_SetRange = NumVarOrDefault(cdf+"ITC_SetRange", 0)
	
	seqstr = ITCseqStr()
	
	ITCoutList = StringFromList(0, seqstr)
	ITCinList = StringFromList(1, seqstr)
	
	outs = strlen(ITCoutList)
	ins = strlen(ITCinList)
	
	pipe = ITCpipeDelay(ins)
	
	if (outs != ins) // double check
		ITCError("ITC Config Error", "configuration error.")
		return -1
	endif
	
	period = ITCperiod(SampleInterval, outs)

	if (period == -1)
		return -1 // bad sample interval
	endif
	
	if (ClampAcquireStart(mode, nwaves) == -1)
		return -1
	endif
	
	if (ITCmakeWaves(outs, NumStimWaves, InterStimTime, NumStimReps, InterRepTime, acqMode) == -1)
		return -1
	endif
	
	if (ITCprescan() == -1)
		ITCError("ITC Acq Fast Error", "prescan error.")
		return -1
	endif
	
	// set up telegraph gains
	
	if (tGainConfig == 1)
	
		if (WaveExists($bdf+"ADCtgain") == 1)
	
			Wave ADCtgain = $bdf+"ADCtgain"
			
			for (config = 0; config < numpnts(ADCtgain); config += 1) // loop thru configs
			
				if (numtype(ADCtgain[config]) == 0)
				
					tgain = ClampTgainValue(GetDataFolder(1), config, -1)
					
					if (tgain == -1)
						tGainConfig = 0 // bad value
					else
						SetNMvar("CT_Tgain"+num2str(config)+"_avg", tgain) // save in data folder
					endif
					
				endif
				
			endfor
		
		endif
		
	else
	
		tGainConfig = 0
		
	endif
	
	// now do normal acquisition
	
	outName = sdf + "ITCoutWave0"
	inName = sdf + "ITCinWave0"
	saveName = sdf + "ITCinWave0"
	
	alist = ADClist[0]
	
	outpnts = numpnts($outName)
	inpnts = numpnts($inName)
	npnts = numpnts($saveName)
	
	Wave savetemp = $saveName
	savetemp = Nan
	
	if ((NumStimWaves == 1) && (NumStimReps > 1))
		// must have more than one input wave
		// so create a copy and flip back and forth
		Duplicate /O savetemp $(sdf+"ITCinWave")
		flip = 1 
	endif
	
	if (ITC_ResetDuringAcquisition == 1)
		Execute aboard + "Reset"
	endif
	
	for (icnt = 0; icnt < ItemsInList(ADClist[0]); icnt += 1)
	
		item = StringFromList(icnt, ADClist[0])
		chanstr = StringFromList(1,item,",")
		gain = str2num(StringFromList(2,item,","))
		
		if (ITC_SetRange == 1)
			Execute aboard + "SetADCRange " + chanstr + "," + ITCrangeStr(gain)
		endif
		
	endfor
	
	strswitch(aboard)
		case "ITC16":
			Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\""
			break
		case "ITC18":
			if (ITC18_SeqExtraParameter == 1)
				Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\",1"
			else
				Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\""
			endif
			break
	endswitch
	
	do // preload output waves
		
		Execute aboard + "WriteAvailable " + cdf + "Avail2Write"
		
		if ((firstwrite == 1) && (Avail2Write[0] <= outpnts))
			ITCError("ITC Acq Fast Error", "not enough FIFO space.")
			return -1
		endif
		
		if ((stimtotal < nwaves) && (Avail2Write[0] >= outpnts))
			
			if (firstwrite == 1)
				Execute aboard + "Stim " + outName
				firstwrite = 0
			else
				Execute aboard + "StimAppend " + outName
			endif
			
			stimcnt += 1
			stimtotal += 1
			
			if (stimcnt >= NumStimWaves)
				stimcnt = 0
			endif
			
			outName = sdf + "ITCoutWave" + num2str(stimcnt)
			
			outpnts = numpnts($outName)
			
		else
		
			break
			
		endif
		
	while (1)
	
	strswitch(aboard)
		case "ITC16":
			Execute aboard + "StartAcq " + num2str(period) + ", 2"
			break
		case "ITC18":
			Execute aboard + "StartAcq " + num2str(period) + ", 2, 0"
			break
	endswitch
	
	do
		
		Execute aboard + "WriteAvailable " + cdf + "Avail2Write"
		
		if ((stimtotal < nwaves) && (Avail2Write[0] > outpnts))
			
			Execute aboard + "StimAppend " + outName
			
			stimcnt += 1
			stimtotal += 1
			
			if (stimcnt >= NumStimWaves)
				stimcnt = 0
			endif
			
			outName = sdf + "ITCoutWave" + num2str(stimcnt)
			outpnts = numpnts($outName)
			
		endif
		
		Execute aboard + "ReadAvailable " + cdf + "Avail2Read"
		
		if ((samptotal < nwaves) && (Avail2Read[0] > inpnts))

			if (firstread == 1)
				Execute aboard + "Samp " + inName
				firstread = 0
			else
				Execute aboard + "SampAppend " + inName
			endif
				
			sampcnt += 1
			samptotal += 1
			
			if (sampcnt >= NumStimWaves)
				sampcnt = 0
			endif
			
			if ((flip == 0) || (flipread == 1))
				inName = sdf + "ITCinWave"+ num2str(sampcnt)
				flipread = 0
			else
				inName = sdf + "ITCinWave" 
				flipread = 1
			endif
			
			inpnts = numpnts($inName)

			Wave wtemp = $inName
			
			if (samptotal < nwaves)
				wtemp = Nan
			endif
			
		endif
		
		if (numtype(savetemp[npnts-1]) == 0)
		
			if ((acqMode == 1) && (mode == 0))
				savetemp[0,pipe-1] = Nan // delete pipedelay points if in continuous preview
			endif
	
			ITCmixWaves(saveName, ins, alist, "", stimPnts[savecnt], 0, -1, pipe) // unmix waves, shift
			
			for (ccnt = 0; ccnt < ItemsInList(alist); ccnt += 1) // save waves
				
				item = StringFromList(ccnt,alist)
				dname = StringFromList(0,item,",")
				//chan = str2num(StringFromList(1,item,","))
				config = str2num(StringFromList(3,item,","))
		
				if (mode == 1)
					wname = GetWaveName("default", ccnt, CurrentWave)
				else
					wname = GetWaveName("default", ccnt, 0)
				endif
				
				scale = ADCscale[config]
				
				if ((tGainConfig == 1) && (tgain > 0) && (numtype(ADCtgain[config]) == 0))
					instr = ClampTgainInstrument(ADCmode[ADCtgain[config]])
					tgainv = ClampTgainValue(GetDataFolder(1), ADCchan[config], CurrentWave)
					scale = MyTelegraphGain(tgainv, scale, instr)
				endif

				Wave wtemp = $dname
				wtemp /= scale

				Duplicate /O wtemp $wname
				
				if (acqMode != 1)
					ChanWaveMake(ccnt, wName, dName) // update display wave (smooth, dt, etc)
				endif
				
				if (NumVarOrDefault(ChanDF(ccnt)+"overlay", 0) > 0)
					ChanOverlayUpdate(ccnt)
				endif
				
				if ((mode == 1) && (saveWhen == 2))
					ClampNMbinAppend(wname) // update waves in saved folder
				endif
			
			endfor
			
			cancel = ClampAcquireNext(mode, nwaves)
			
			savecnt += 1
			
			if (savecnt >= NumStimWaves)
				savecnt = 0
				rcnt += 1
			endif
			
			if (rcnt >= NumStimReps)
				break
			endif
			
			if ((flip == 0) || (flipsave == 1))
				saveName = sdf + "ITCinWave" + num2str(savecnt)
				flipsave = 0
			else
				saveName = sdf + "ITCinWave"
				flipsave = 1
			endif
			
			alist = ADClist[savecnt]
			npnts = numpnts($saveName)
	
			Wave savetemp = $saveName
			
			if (cancel == 1)
				break
			endif
			
		endif
		
	while (1)
	
	Execute aboard + "stopacq"
	
	if ((acqMode == 1) && (mode == 1)) // fix pipeline delay
		
		pipe = pipe/ins
		
		for (wcnt = 0; wcnt < nwaves; wcnt += 1)
		
			alist = ADClist[wcnt]
			
			for (ccnt = 0; ccnt < ItemsInList(alist); ccnt += 1) // save waves
			
				wname = GetWaveName("default", ccnt, wcnt) // current wave
				dname = GetWaveName("default", ccnt, wcnt+1) // next wave
		
				if (WaveExists($wname) == 1)
					Wave wtemp = $wname
					npnts = Numpnts(wtemp)
					wtemp[npnts-pipe, inf] = Nan
				else
					continue
				endif
				
				if (WaveExists($dname) == 1)
					Wave dtemp = $dname
					for (icnt = 0; icnt < pipe; icnt += 1)
						wtemp[npnts-pipe+icnt] = dtemp[npnts-pipe+icnt]
					endfor
				endif
			
			endfor
		endfor
		
	endif
	
	for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1)
		KillWaves /Z $sdf+"ITCoutWave"+num2str(wcnt)
		KillWaves /Z $sdf+"ITCinWave"+num2str(wcnt)
	endfor
	
	KillWaves /Z $(sdf+"ITCinWave"), $(sdf+"ITCmix"), $(sdf+"ITCTTLOUT")
	
	ClampAcquireFinish(mode, savewhen)

End // ITCAcqPrecise

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCAcqLong(mode, savewhen)
	Variable mode // (0) preview (1) record (-1) test timers
	Variable savewhen // (0) never (1) after (2) while
	
	Variable nwaves, rcnt, ccnt, wcnt, icnt, period, pipe
	Variable stimcnt, stimtotal, sampcnt, samptotal
	Variable scale, config
	Variable gain, tgain, tgainv, cancel, outs, ins
	Variable flip, flipread, flipsave
	Variable firstread, firstwrite, firstsave, acqflag = 2
	
	String wname, dname, inName, outName, alist, instr
	String item, chanstr, seqstr, ITCoutList, ITCinList
	
	String cdf = ClampDF(), sdf = StimDF(), bdf = StimBoardDF(sdf)
	
	NVAR CurrentWave
	
	String aboard = StrVarOrDefault(cdf+"AcqBoard", "")
	
	Variable NumStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable NumStimReps = NumVarOrDefault(sdf+"NumStimReps", 0)
	
	NVAR InterStimTime = $cdf+"InterStimTime"
	NVAR InterRepTime = $cdf+"InterRepTime"
	
	Variable SampleInterval = NumVarOrDefault(sdf+"SampleInterval", 0)
	Variable acqMode = NumVarOrDefault(cdf+"AcqMode", 0)
	
	strswitch(aboard)
		case "ITC16":
		case "ITC18":
			break
		default:
			ITCError("ITC Config Error", "unrecognized board : " + aboard)
			return -1
	endswitch
	
	nwaves = NumStimWaves * NumStimReps // total number of waves
	
	//Make /I/O/N=1 $(cdf+"Avail2Read"), $(cdf+"Avail2Write")
	
	Wave Avail2Read = $cdf+"Avail2Read"
	Wave Avail2Write = $cdf+"Avail2Write"

	//if (ITCupdateLists(NumStimWaves) == -1)
	//	return -1 // bad input/output configuration
	//endif
	
	Wave stimPnts = $cdf+"StimNumpnts"
	
	Wave ADCscale = $bdf+"ADCscale"
	Wave ADCchan = $bdf+"ADCchan"
	Wave /T ADCmode = $bdf+"ADCmode"
	
	Wave /T ADClist = $cdf+"ADClist"
	
	Variable tGainConfig = NumVarOrDefault(cdf+"TGainConfig", 0)
	
	Variable ITC18_SeqExtraParameter = NumVarOrDefault(cdf+"ITC18_SeqExtraParameter", 1)
	Variable ITC_ResetDuringAcquisition = NumVarOrDefault(cdf+"ITC_ResetDuringAcquisition", 0)
	Variable ITC_SetRange = NumVarOrDefault(cdf+"ITC_SetRange", 0)
	
	seqstr = ITCseqStr()
	ITCoutList = StringFromList(0, seqstr)
	ITCinList = StringFromList(1, seqstr)
	
	outs = strlen(ITCoutList)
	ins = strlen(ITCinList)
	
	pipe = ITCpipeDelay(ins)
	
	if (outs != ins) // double check
		ITCError("ITC Config Error", "configuration error.")
		return -1
	endif
	
	period = ITCperiod(SampleInterval, outs)

	if (period == -1)
		return -1 // bad sample interval
	endif
	
	if (ClampAcquireStart(mode, nwaves) == -1)
		return -1
	endif
	
	if (ITCmakeWaves(outs, NumStimWaves, InterStimTime, NumStimReps, InterRepTime, acqMode) == -1)
		return -1
	endif
	
	if (ITCprescan() == -1)
		ITCError("ITC Acq Slow Error", "prescan error.")
		return -1
	endif
	
	if (acqMode == 3)
		acqflag = 3 // external trigger
	endif
	
	// set up telegraph gains
	
	if ((tGainConfig == 1) && (WaveExists($bdf+"ADCtgain") == 1))
	
		Wave ADCtgain = $bdf+"ADCtgain"
		
		for (config = 0; config < numpnts(ADCtgain); config += 1)
		
			if (numtype(ADCtgain[config]) == 0)
			
				tgain = ClampTgainValue(GetDataFolder(1), config, -1)
				
				if (tgain == -1)
					tGainConfig = 0 // bad value
				else
					SetNMvar("CT_Tgain"+num2str(config)+"_avg", tgain) // save in data folder
				endif
				
			endif
			
		endfor
		
	else
	
		tGainConfig = 0
		
	endif
	
	// start acquisition
	
	if (ITC_ResetDuringAcquisition == 1)
		Execute aboard + "Reset"
	endif
	
	for (icnt = 0; icnt < ItemsInList(ADClist[0]); icnt += 1)
	
		item = StringFromList(icnt, ADClist[0])
		chanstr = StringFromList(1,item,",")
		gain = str2num(StringFromList(2,item,","))
		
		if (ITC_SetRange == 1)
			Execute aboard + "SetADCRange " + chanstr + "," + ITCrangeStr(gain)
		endif
		
	endfor
	
	strswitch(aboard)
		case "ITC16":
			Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\""
			break
		case "ITC18":
			if (ITC18_SeqExtraParameter == 1)
				Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\",1"
			else
				Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\""
			endif
			break
	endswitch
	
	for (rcnt = 0; rcnt < NumStimReps; rcnt += 1) // loop thru reps

		for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1) // loop thru stims
			
			outName = sdf + "ITCoutWave" + num2str(wcnt)
			inName = sdf + "ITCinWave"+ num2str(wcnt)
			alist = ADClist[wcnt]
			
			Wave wtemp = $inName
				
			wtemp = Nan
			
			firstwrite = 1
			firstread = 1
			firstsave = 1
			
			do
			
				Execute aboard + "WriteAvailable " + cdf + "Avail2Write"
			
				if ((firstwrite == 1) && (Avail2Write[0] > numpnts($outName)))
					Execute aboard + "Stim " + outName
					firstwrite = 0
				endif
				
			while (firstwrite == 1)
			
			strswitch(aboard)
				case "ITC16":
					Execute aboard + "StartAcq " + num2str(period) + ", " + num2str(acqflag)
					break
				case "ITC18":
					Execute aboard + "StartAcq " + num2str(period) + ", " + num2str(acqflag) + ", 0"
					break
			endswitch
			
			do
				
				Execute aboard + "ReadAvailable " + cdf + "Avail2Read"
				
				if ((firstread == 1) && (firstwrite == 0) && (Avail2Read[0] > 10+numpnts($inName)))
					Execute aboard + "Samp " + inName
					firstread = 0
				endif
				
			while (firstread == 1)
			
			do
				
				if ((firstread == 0) && (firstwrite == 0) && (numtype(wtemp[numpnts(wtemp)-1]) == 0))
				
					Execute aboard + "stopacq"
		
					ITCmixWaves(inName, ins, alist, "", stimPnts[wcnt], 0, -1, pipe) // unmix waves, shift
					
					for (ccnt = 0; ccnt < ItemsInList(alist); ccnt += 1) // save waves
						
						item = StringFromList(ccnt,alist)
						dname = StringFromList(0,item,",")
						//chan = str2num(StringFromList(1,item,","))
						config = str2num(StringFromList(3,item,","))
				
						if (mode == 1)
							wname = GetWaveName("default", ccnt, CurrentWave)
						else
							wname = GetWaveName("default", ccnt, 0)
						endif
						
						scale = ADCscale[config]
						
						if ((tGainConfig == 1) && (tgain > 0) && (numtype(ADCtgain[config]) == 0))
							instr = ClampTgainInstrument(ADCmode[ADCtgain[config]])
							tgainv = ClampTgainValue(GetDataFolder(1), ADCchan[config], CurrentWave)
							scale = MyTelegraphGain(tgainv, scale, instr)
						endif
		
						Wave wtemp = $dname
						wtemp /= scale
		
						Duplicate /O wtemp $wname
						
						ChanWaveMake(ccnt, wName, dName) // update display wave (smooth, dt, etc)
						
						if (NumVarOrDefault(ChanDF(ccnt)+"overlay", 0) > 0)
							ChanOverlayUpdate(ccnt)
						endif
						
						if ((mode == 1) && (saveWhen == 2))
							ClampNMbinAppend(wname) // update waves in saved folder
						endif
					
					endfor
					
					cancel = ClampAcquireNext(mode, nwaves)
					
					firstsave = 0
					
				endif
			
			while (firstsave == 1)
			
			ClampWait(InterStimTime) // inter-wave time
			
			if (ClampAcquireCancel() == 1)
				break
			endif
			
		endfor
		
		if (rcnt < NumStimReps - 1)
			ClampWait(InterRepTime) // inter-rep time
		endif
		
		if (ClampAcquireCancel() == 1)
			break
		endif
		
	endfor
	
	Execute aboard + "stopacq"
	
	for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1)
		KillWaves /Z $sdf+"ITCoutWave"+num2str(wcnt)
		KillWaves /Z $sdf+"ITCinWave"+num2str(wcnt)
	endfor
	
	KillWaves /Z $(sdf+"ITCinWave"), $(sdf+"ITCmix"), $(sdf+"ITCTTLOUT")
	
	ClampAcquireFinish(mode, savewhen)

End // ITCAcqLong

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCprescan()

	Variable icnt, gain, config, npnts, period, scale
	String item, inName, chanstr
	
	String cdf = ClampDF(), sdf = StimDF(), bdf = StimBoardDF(sdf)
	
	String aboard = StrVarOrDefault(cdf+"AcqBoard", "")
	
	Variable ITC18_SeqExtraParameter = NumVarOrDefault(cdf+"ITC18_SeqExtraParameter", 1)
	Variable ITC_ResetDuringAcquisition = NumVarOrDefault(cdf+"ITC_ResetDuringAcquisition", 0)
	Variable ITC_SetRange = NumVarOrDefault(cdf+"ITC_SetRange", 0)
	
	Wave ADCscale = $bdf+"ADCscale"
	
	Wave /T preADClist = $cdf+"preADClist"
	
	period = ITCperiod(0.01, 1)
	
	if (ITC_ResetDuringAcquisition == 1)
		Execute aboard + "Reset"
	endif
	
	for (icnt = 0; icnt < ItemsInList(preADClist[0]); icnt += 1)

		item = StringFromList(icnt, preADClist[0])
		inName = StringFromList(0,item,",")
		chanstr = StringFromList(1,item,",")
		gain = str2num(StringFromList(2,item,","))
		config = str2num(StringFromList(4,item,","))
		
		if (WaveExists($inName) == 0)
			continue
		endif
		
		Wave tempWave = $inName
		
		npnts = numpnts(tempWave)
		
		Redimension /N=(6+npnts) tempWave
		
		tempWave = 0
		
		if (ITC_SetRange == 1)
			Execute aboard + "SetADCRange " + chanstr + "," + ITCrangeStr(gain)
		endif
	
		strswitch(aboard)
			case "ITC16":
				Execute aboard + "Seq \"0\",\"" + chanstr + "\""
				Execute aboard + "StartAcq " + num2str(period) + ", 2"
				break
			case "ITC18":
				if (ITC18_SeqExtraParameter == 1)
					Execute aboard + "Seq \"0\",\"" + chanstr + "\",1"
				else
					Execute aboard + "Seq \"0\",\"" + chanstr + "\""
				endif
				Execute aboard + "StartAcq " + num2str(period) + ", 2, 0"
				break
		endswitch
		
		Execute aboard + "Stim " + inName
		Execute aboard + "Samp " + inName
		Execute aboard + "stopacq"
		
		Rotate -6, tempWave
		
		Redimension /N=(npnts) tempWave
		
		tempWave /= (32768 / ITCrange(gain)) // convert to volts
		
		if ((numtype(config) == 0) && (config >= 0))
		
			scale = ADCscale[config]
			
			if ((numtype(scale) == 0) && (scale > 0))
				tempWave /= scale
			endif
			
		endif
	
	endfor
	
End // ITCprescan

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCread(chan, gain, npnts)
	Variable chan // ADC channel to read
	Variable gain // input gain
	Variable npnts // number of points to read
	
	String chanstr = num2str(chan)
	
	String cdf = ClampDF()
	
	String aboard = StrVarOrDefault(cdf+"AcqBoard", "")
	
	Variable ITC18_SeqExtraParameter = NumVarOrDefault(cdf+"ITC18_SeqExtraParameter", 1)
	Variable ITC_ResetDuringAcquisition = NumVarOrDefault(cdf+"ITC_ResetDuringAcquisition", 0)
	Variable ITC_SetRange = NumVarOrDefault(cdf+"ITC_SetRange", 0)
	
	Variable period = ITCperiod(0.01, 1)
	
	Variable garbage = 15
	
	Make /O/N=(npnts+garbage) CT_ITCread = Nan
	
	if (ITC_ResetDuringAcquisition == 1)
		Execute aboard + "Reset"
	endif
	
	if (ITC_SetRange == 1)
		Execute aboard + "SetADCRange " + chanstr + "," + ITCrangeStr(gain)
	endif
	
	strswitch(aboard)
		case "ITC16":
			Execute aboard + "Seq \"0\",\"" + chanstr + "\""
			Execute aboard + "StartAcq " + num2str(period) + ", 2"
			break
		case "ITC18":
			if (ITC18_SeqExtraParameter == 1)
				Execute aboard + "Seq \"0\",\"" + chanstr + "\",1"
			else
				Execute aboard + "Seq \"0\",\"" + chanstr + "\""
			endif
			Execute aboard + "StartAcq " + num2str(period) + ", 2, 0"
			break
	endswitch
	
	Execute aboard + "Stim CT_ITCread"
	Execute aboard + "Samp CT_ITCread"
	Execute aboard + "stopacq"
	
	Wave CT_ITCread
		
	CT_ITCread /= (32768 / ITCrange(gain)) // convert to volts
	
	CT_ITCread[0,garbage-1] = Nan
	
	CT_ITCread = Zero2Nan(CT_ITCread) // remove possible 0's
	
	WaveStats /Q CT_ITCread
	
	KillWaves /Z CT_ITCread
	
	SetNMvar(cdf+"ClampReadValue", V_avg)
	
	return V_avg // return average of points

End // ITCread

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCperiod(sampleinterval, outs) // period in ITC18 clock intervals
	Variable sampleinterval, outs

	String cdf = ClampDF()

	Variable period = 1000 * sampleinterval / (1.25 * outs) // number of ticks
	Variable remain = mod(period, floor(period))
	Variable three = mod(outs, 3)
	
	if (remain >= 0.01)
	
		period = ceil(period)
		sampleinterval = 5 * floor(period / 5) * 1.25 * outs / 1000 // to nearest 5 usec
		
		if (three == 0)
			ITCError("ITC Config Error", "bad sample interval. Try multiple of 0.03 msec.")
		else
			ITCError("ITC Config Error", "bad sample interval. Try multiple of 0.01 msec.")
		endif
		
		return -1
		
	endif
	
	if (period <= 5)
		ITCError("ITC Config Error", "sample inteval too short")
		return -1
	endif
	
	if (period >= 82000)
		ITCError("ITC Config Error", "sample inteval too long")
		return -1
	endif
	
	return floor(period)

End // ITCperiod

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCupdateLists(NumStimWaves) // check input/output configurations and create sequence wave lists
	Variable NumStimWaves

	Variable wcnt, config, chan, gain, mode, outs, ins, tgain
	String wname, alist, dlist, tlist, alist2, item, modestr, nowave = ""
	
	String cdf = ClampDF(), sdf = StimDF(), bdf = StimBoardDF(sdf)
	
	Variable npnts = NumVarOrDefault(sdf+"SamplesPerWave", Nan)
	
	if (WaveExists($bdf+"ADCname") == 0)
		return -1
	endif
	
	Wave /T ADCname = $bdf+"ADCname"
	Wave /T DACname = $bdf+"DACname"
	Wave /T TTLname = $bdf+"TTLname"
	
	Wave ADCtgain = $bdf+"ADCtgain" // telegraph gain
	
	Make /O/N=(NumStimWaves) $(cdf+"StimNumpnts")
	Make /T/O/N=(NumStimWaves) $(cdf+"DAClist"), $(cdf+"TTLlist"), $(cdf+"ADClist"), $(cdf+"preADClist")
	
	Wave stimPnts = $cdf+"StimNumpnts"
	Wave /T DAClist = $cdf+"DAClist" // where lists are saved
	Wave /T TTLlist = $cdf+"TTLlist"
	Wave /T ADClist = $cdf+"ADClist"
	Wave /T preADClist = $cdf+"preADClist"
	
	//String tGainList = StrVarOrDefault(cdf+"TGainList", "")
	
	//if ((strlen(tGainList) > 0) && (WaveExists($cdf+"ADCtgain") == 1))
	//	Wave ADCtgain = $cdf+"ADCtgain" // telegraph gain
	//	tgain = 1
	//endif
	
	for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1)
	
		outs = 0
		ins = 0
		alist = ""
		alist2 = ""
		dlist = ""
		tlist = ""
		
		for (config = 0; config < numpnts(DACname); config += 1) // DAC sequence
		
			if (strlen(DACname[config]) > 0)
			
				outs += 1
				chan = WaveValOrDefault(bdf+"DACchan", config, 0)
				
				if ((chan < 0) || (chan > 3)) // 0123
					ITCError("ITC Config Error", "DAC chan out of range : " + num2str(chan))
					return -1
				endif
				
				wname = sdf + StimWaveName("DAC", config, wcnt)
				item = wname + "," + num2str(chan)
				dlist = AddListItem(item, dlist, ";", inf)
				
			endif
			
		endfor

		DAClist[wcnt] = dlist
		
		for (config = 0; config < numpnts(TTLname); config += 1) // TTL sequence
		
			if (strlen(TTLname[config]) > 0)
			
				chan = WaveValOrDefault(bdf+"TTLchan", config, 0)
				
				if ((chan < 0) || (chan > 15))
					ITCError("ITC Config Error", "TTL chan out of range : " + num2str(chan))
					return -1
				endif
				
				wname = sdf + StimWaveName("TTL", config, wcnt)
				item = wname + "," + num2str(chan)
				tlist = AddListItem(item, tlist, ";", inf)
				
			endif
			
		endfor
		
		TTLlist[wcnt] = tlist
		
		stimPnts[wcnt] = ClampWavesNumpnts(dlist, tlist, npnts)
		
		for (config = 0; config < numpnts(ADCname); config += 1) // ADC sequence
		
			if (strlen(ADCname[config]) > 0)
			
				chan = WaveValOrDefault(bdf+"ADCchan", config, 0)
				gain = WaveValOrDefault(bdf+"ADCgain", config, 1)
				modestr = WaveStrOrDefault(bdf+"ADCmode", config, "")
	
				if (ITCrange(gain) == -1)
					ITCError("ITC Config Error", "ADC gain value not allowed : " + num2str(gain))
					return -1
				endif
				
				if ((chan < 0) || (chan > 7))
					ITCError("ITC Config Error", "ADC chan out of range : " + num2str(chan))
					return -1
				endif
				
				if (strlen(modestr) == 0) // normal input
				
					wname = ChanDisplayWave(ins)
					item = wname + "," + num2str(chan) + "," + num2str(gain) + "," + num2str(config)
					alist = AddListItem(item, alist, ";", inf)
					ins += 1
					
					//if ((strlen(tGainList) > 0) && (numtype(ADCtgain[config]) == 0))
					//	gain = 1 // full scale
					//	wname = "CT_Tgain" + num2str(config)
					//	item = wname + "," + num2str(ADCtgain[config]) + "," + num2str(gain)+ "," + num2str(50) + "," + num2str(-1)
					//	alist2 = AddListItem(item, alist2, ";", inf) // save as pre-stim input
					//endif
				
				elseif (strsearch(modestr, "PreSamp=", 0) >= 0) // pre-sample
				
					wname = "CT_" + WaveStrOrDefault(bdf+"ADCname", config, "")
					mode = str2num(modestr[8, inf])
					item = wname + "," + num2str(chan) + "," + num2str(gain) + "," + num2str(mode) + "," + num2str(config)
					alist2 = AddListItem(item, alist2, ";", inf)
					
				elseif (strsearch(modestr, "Tgain=", 0) >= 0) // telegraph gain
				
					tgain = 1
					gain = 1 // full scale
					//mode = (-1 * mode - 100)
					wname = "CT_Tgain" + num2str(ClampTgainChan(modestr))
					item = wname + "," + num2str(chan) + "," + num2str(gain)+ "," + num2str(10) + "," + num2str(-1)
					alist2 = AddListItem(item, alist2, ";", inf) // save as pre-stim input
					
				endif
			
			endif
			
		endfor

		ADClist[wcnt] = alist
		preADClist[wcnt] = alist2
		
	endfor

	if (outs < ins) // extend output lists
	
		if (outs == 0)
			nowave = "NoOutput,-1;"
		endif
		
		for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1)
			DAClist[wcnt] = ITCextendList(nowave+DAClist[wcnt], ins, 1)
		endfor
		
	endif
	
	SetNMvar(cdf+"TGainConfig", tgain)
	
	return 0

End // ITCupdateLists

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ITCseqStr() // create ITC sequence output/input strings (i.e. "012D", "231D")

	Variable jcnt, outs, ins, seqnum
	String outseq = "", inseq = "", ttlseq = "", item
	
	String cdf = ClampDF()

	Wave /T DAClist = $cdf+"DAClist"
	Wave /T TTLlist = $cdf+"TTLlist"
	Wave /T ADClist = $cdf+"ADClist"
	
	for (jcnt = 0; jcnt < ItemsInList(ADClist[0]); jcnt += 1)
		item = StringFromList(jcnt, ADClist[0]) 
		inseq += StringFromList(1, item, ",")
	endfor
	
	if (strlen(inseq) == 0)
		inseq = "0" // dummy input
	endif
	
	for (jcnt = 0; jcnt < ItemsInList(DAClist[0]); jcnt += 1)
	
		item = StringFromList(jcnt, DAClist[0])
		seqnum = str2num(StringFromList(1, item, ","))
		
		if (seqnum >= 0)
			outseq += StringFromList(1, item, ",")
		endif
		
	endfor
	
	if (strlen(outseq) == 0)
		outseq = "0" // dummy input
	endif
	
	for (jcnt = 0; jcnt < ItemsInList(TTLlist[0]); jcnt += 1)
		ttlseq = "D"
	endfor
	
	outs = strlen(outseq)
	ins = strlen(inseq)
	
	if (outs > ins) // extend input lists
		inseq = ITCextendList(inseq, outs, 0)
	elseif (ins > outs)
		outseq = ITCextendList(outseq, ins, 0)
	endif
	
	return outseq + ttlseq + ";" + inseq + ttlseq 

End // ITCseqStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ITCextendList(list, extend2, listType)
	String list
	Variable extend2
	Variable listType // (0) string list "0121" (1) item list "item1;item2;"

	Variable ccnt, length
	String item
	
	if (listType == 0) // string list "012"
	
		 length = strlen(list)
	
		if ((length > 0) && (length < extend2))
		
			for (ccnt = 0; ccnt < extend2; ccnt += 1)
			
				list += list[ccnt, ccnt]
				length = strlen(list)
				
				if (length == extend2)
					break
				endif
				
			endfor
			
		endif
		
	elseif (listType == 1) // item list "wave0;wave1;wave2;"
	
		length = ItemsInlist(list)
		
		if ((length > 0) && (length < extend2))
		
			for (ccnt = 0; ccnt < extend2; ccnt += 1)
			
				item = StringFromList(ccnt, list)
				list = AddListItem(item, list, ";", inf)
				length = ItemsInlist(list)
				
				if (length == extend2)
					break
				endif
				
			endfor
			
		endif
	
	endif
	
	return list
	
End // ITCextendList

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCmakeWaves(NumOuts, NumStimWaves, InterStimTime, NumStimReps, InterRepTime, AcqMode)
	Variable NumOuts, NumStimWaves, InterStimTime, NumStimReps, InterRepTime, AcqMode
	
	Variable icnt, wcnt, stimN, repN, insertN, pipe, error, npnts
	String item, wname, wlist = "", tlist = ""
	
	String cdf = ClampDF(), sdf = StimDF()
	
	Variable SampleInterval = NumVarOrDefault(sdf+"SampleInterval", 0)
	String precision = StrVarOrDefault(cdf+"WavePrecision", "S") // ITC waves have to be single precision

	if (WaveExists($cdf+"DAClist") == 0)
		ITCError("ITC Config Error", "missing wave " + cdf + "DAClist")
		return -1
	endif
	
	if (WaveExists($cdf+"TTLlist") == 0)
		ITCError("ITC Config Error", "missing wave " + cdf + "TTLlist")
		return -1
	endif
	
	if (WaveExists($cdf+"ADClist") == 0)
		ITCError("ITC Config Error", "missing wave " + cdf + "ADClist")
		return -1
	endif
	
	Wave /T DAClist = $cdf+"DAClist"
	Wave /T TTLlist = $cdf+"TTLlist"
	Wave /T ADClist = $cdf+"ADClist"
	Wave /T preADClist = $cdf+"preADClist"
	Wave stimPnts = $cdf+"StimNumpnts"
	
	pipe = ITCpipeDelay(NumOuts)
	
	if (AcqMode == 0) // epic precise
	
		if (InterStimTime > 0)
			stimN = floor(InterStimTime / SampleInterval)
		endif
		
		if  ((NumStimReps > 1) && (InterRepTime > 0))
			repN = floor(InterRepTime / SampleInterval)
		endif
	
	endif
	
	for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1)
	
		wlist = DAClist[wcnt]
		tlist = TTLlist[wcnt]

		if (stimN > 0)
			InsertN = stimN
		else
			InsertN = 0
		endif
		
		if ((wcnt == 0) && (repN > 0))
			insertN += repN
		endif
		
		wname = sdf + "ITCoutWave" + num2str(wcnt)
		
		if (WaveExists($wname) == 0)
		
			switch(AcqMode)
			
				case 0: // epic precise
			
					if (insertN >= pipe)
						error = ITCmixWaves(wname, NumOuts, wlist, tlist, stimPnts[wcnt], insertN, 1, pipe) // mix output waves, shift
					else
						ITCError("ITC Episodic Error", "inter-wave or inter-rep time too short. Try continuous acquisition.")
						return -1
					endif
					
					break
					
				case 1: // continuous
					error = ITCmixWaves(wname, NumOuts, wlist, tlist, stimPnts[wcnt], insertN, 1, 0) // mix output waves, no shift
					break
					
				case 2: // episodic
				case 3: // triggered
					error = ITCmixWaves(wname, NumOuts, wlist, tlist, stimPnts[wcnt], insertN, 1, pipe)
					break
					
				default:
					error = -1
					
			endswitch
		
		endif
		
		if (error < 0)
			ITCError("ITC Config Error", "mix wave error")
			return -1
		endif
			
		npnts = numpnts($wname) // number of points made for ITCoutWave
		
		// make input waves
		
		wname = sdf + "ITCinWave" + num2str(wcnt)
		Make /O/N=(npnts) $wname = Nan
		
		for (icnt = 0; icnt < ItemsInList(ADClist[wcnt]); icnt += 1)
			item = StringFromList(icnt, ADClist[wcnt])
			wname = StringFromList(0, item, ",")
			Make /O/N=(stimPnts[wcnt]) $wname = Nan
			Setscale /P x 0, SampleInterval, $wname
		endfor
		
		for (icnt = 0; icnt < ItemsInList(preADClist[wcnt]); icnt += 1)
			item = StringFromList(icnt, preADClist[wcnt])
			wname = StringFromList(0, item, ",")
			npnts = str2num(StringFromList(3, item, ","))
			Make /O/N=(npnts) $wname = Nan
		endfor
		
	endfor

End // ITCmakeWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCkillWaves() // Kill ITC waves that may exist
	
	Variable icnt
	String sdf = StimDF()
	String wname, wlist = WaveListFolder(sdf, "ITC*", ";", "")
		
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		wname = StringFromList(icnt, wlist)
		KillWaves /Z $sdf+wname
	endfor

End // ITCkillWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCpipeDelay(seqnum)
	Variable seqnum // number of inputs in ITC sequence command
	Variable pipe = 3 // one input
	
	if (seqnum > 1)
		pipe = 2*seqnum // pipeline delay for more than one input
	endif
	
	return pipe

End // ITCpipeDelay

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCmixWaves(mixwname, nmix, wlist, tlist, npnts, ipnts, mixflag, pipedelay)
	String mixwname // the mixed wave to be made
	Variable nmix // number of waves in mixed wave
	String wlist // wave name list
	String tlist // TTL wave name list
	Variable npnts // points in waves
	Variable ipnts // points to insert
	Variable mixflag // (1) mix (-1) unmix
	Variable pipedelay // FIFO pipeline delay value

	Variable icnt, jcnt, kcnt, allpnts, numTTL, chan, gain, np
	String item, wname
	
	String cdf = ClampDF(), sdf = StimDF()
	
	numTTL = ItemsInList(tlist)
	
	if ((numtype(npnts) > 0) || (npnts <= 0))
		return -1
	endif
	
	if (mixflag == 1) // mix waves

		allpnts = npnts*nmix
		
		Make /O/N=(allpnts) $mixwname = 0
		Wave mixWave = $mixwname

		for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1) // mix DAC waves
			
			item = StringFromList(icnt, wlist)
			wname = StringFromList(0, item, ",")
			chan = str2num(StringFromList(1, item, ","))
	
			if ((WaveExists($wname) == 0) || (chan < 0))
				Make /O/N=(npnts) $wname = 0
			endif
			
			Wave tempWave = $wname

			kcnt = 0
			
			for (jcnt = icnt; jcnt < numpnts(mixWave); jcnt += nmix)
				mixWave[jcnt] = tempWave[kcnt]
				kcnt += 1
			endfor
			
		endfor
		
		mixWave *= 32768 / ITCrange(1) // convert DAC output to bits (32768 bits/10.24 volt)
		
		if (numTTL > 0)
		
			Make /O/N=(npnts) $(sdf+"ITCTTLOUT") = 0
			Wave TTLout = $sdf+"ITCTTLOUT"
		
			for (icnt = 0; icnt < numTTL; icnt += 1) // sum TTL output "D" together
			
				item = StringFromList(icnt, tlist)
				wname = StringFromList(0, item, ",")
				chan = str2num(StringFromList(1, item, ","))

				if ((WaveExists($wname) == 0) || (chan < 0))
					Make /O/N=(npnts) $wname = 0
				endif
				
				Wave tempwave = $wname
				
				Wavestats /Q tempwave
				
				tempwave /= V_max // normalize wave
				tempwave *= 2^(chan) // set channel bit value
				
				TTLout += tempwave
				
			endfor
			
			kcnt = 0
			
			for (jcnt = nmix-1; jcnt < numpnts(mixWave); jcnt += nmix)
				mixWave[jcnt] = TTLout[kcnt]
				kcnt += 1
			endfor
		
		endif
		
		InsertPoints 0, (ipnts*nmix), mixWave // insert delay points for episodic timing
		
		if (pipedelay > 0)
			Rotate -pipedelay, mixWave // shift for pipeline delay
		endif

	elseif (mixflag == -1) // unmix waves
	
		if (WaveExists($mixwname) == 0)
			return -1
		endif
	
		Wave mWave = $mixwname
		
		allpnts = numpnts($mixwname)
		
		ipnts = allpnts - npnts*nmix
		
		if (pipedelay > 0)
			Rotate -pipedelay, mWave
		endif
		
		Duplicate /O/R=[ipnts,ipnts+npnts*nmix-1] $mixwname $(sdf + "ITCmix")

		Wave mixWave = $sdf + "ITCmix"

		for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		
			item = StringFromList(icnt, wlist)
			wname = StringFromList(0, item, ",")
			chan = str2num(StringFromList(1, item, ","))
			gain = str2num(StringFromList(2, item, ","))

			if ((WaveExists($wname) == 0) || (chan < 0))
				continue
			endif
			
			Redimension /N=(npnts) $wname
			
			Wave tempWave = $wname
			
			tempWave = 0
			kcnt = 0

			for (jcnt = icnt; jcnt < numpnts(mixWave); jcnt += nmix)
				tempWave[kcnt] = mixWave[jcnt]
				kcnt += 1
			endfor
			
			tempWave /= (32768 / ITCrange(gain)) // convert to volts
			
		endfor
	
	endif
	
	KillWaves /Z NoOutput
	
	return 0

End // ITCmixWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCrange(scale)
	Variable scale

	switch(scale)
		default:
			return -1
		case 1:
			return 10.24 // mV
		case 2:
			return 5.12
		case 5:
			return 2.048
		case 10:
			return 1.024
	endswitch

End // ITCrange

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ITCrangeStr(scale)
	Variable scale

	switch(scale)
		default:
			return "error"
		case 1:
			return "10"
		case 2:
			return "5"
		case 5:
			return "2"
		case 10:
			return "1"
	endswitch
	
End // ITCrangeStr

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCSetDAC(chan, volts)
	Variable chan
	Variable volts
	
	String cdf = ClampDF(), sdf = StimDF()
	
	String aboard = StrVarOrDefault(cdf+"AcqBoard", "")
	
	Execute aboard + "SetDAC " + num2str(chan) + "," + num2str(volts)
	
End // ITCSetDAC

//****************************************************************
//****************************************************************
//****************************************************************





