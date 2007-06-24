#pragma rtGlobals = 1
#pragma IgorVersion = 4
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Acquisition Utility Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro 4
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
//	Last modified 8 Feb 2006
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampUtilityPreList()
	return "TModeCheck;ReadTemp;"
End

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampUtilityInterList()
	return "OnlineAvg;Rstep;RCstep;TempRead;"
End

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampUtilityPostList()
	return ""
End

//****************************************************************
//
//	OnlineAvg()
//	computes online average of channel graphs
//	add this function to inter-stim fxn execution list
//
//****************************************************************

Function OnlineAvg(mode)
	Variable mode // (0) run fxn (1) config fxn (-1) kill fxn
	
	Variable ccnt, cbeg, cend
	String wname, avgname, gname, sdf = StimDF()
	
	Variable chan = NumVarOrDefault(sdf+"OnlineAvgChan", -1)
	
	if (mode == 1)
		OnlineAvgConfig()
		return 0
	elseif (mode == -1)
		KillVariables /Z $(sdf+"OnlineAvgChan")
		return 0
	endif
	
	NVAR CurrentWave, NumChannels
	
	if (chan == -1)
		cbeg = 0
		cend = NumChannels - 1
	else
		cbeg = chan
		cend = chan
	endif
	
	for (ccnt = cbeg; ccnt <= cend; ccnt += 1)
	
		wname = ChanDisplayWave(ccnt)
		avgname = GetWaveName("CT_Avg", ccnt, 0)
		gName = ChanGraphName(ccnt)
		
		if (WaveExists($wname) == 0)
			continue
		endif
		
		Wave wtemp = $wname
		
		if (CurrentWave == 0)
			Duplicate /O $wname $avgname
			RemoveFromGraph /Z/W=$gname $avgname
			AppendToGraph /W=$gname $avgname
		else
			Wave avgtemp = $avgname
			avgtemp = ((avgtemp * CurrentWave) + wtemp) / (CurrentWave + 1)
		endif
		
	endfor
	
End // OnlineAvg

//****************************************************************
//****************************************************************
//****************************************************************

Function OnlineAvgConfig()
	String sdf = StimDF()

	Variable numchan = StimOnCount(sdf, "ADC")
	String chanList = ChanCharList(numchan, ";")
	
	if (numchan == 1)
		return 0
	endif
	
	Variable chan = NumVarOrDefault(sdf+"OnlineAvgChan", -1)
	
	if (numchan > 1)
		chanList += "All"
	endif
	
	if (chan == -1) // All
		chan = ItemsInList(chanList)
	else
		chan += 1
	endif
	
	Prompt chan, "channel to average:", popup chanList
	DoPrompt "Online Average Configuration", chan
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	chan -= 1
	
	if (chan >= numchan)
		chan = -1
	endif
	
	SetNMvar(sdf+"OnlineAvgChan", chan)

End // OnlineAvgConfig

//****************************************************************
//
//	TModeCheck()
//	check acquisition telegraph mode is set correctly
//	currently configured for Axopatch200B
//
//
//****************************************************************

Function TModeCheck(mode)
	Variable mode // (0) run fxn (1) config fxn (-1) kill fxn
	
	Variable telValue
	String tmode, cdf = ClampDF(), sdf = StimDF()
	
	if (mode == 1)
		TModeCheckConfig()
		return 0
	elseif (mode == -1)
		return 0
	endif
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
	Variable chan = NumVarOrDefault(cdf+"TModeChan", -1)
	String amode = StrVarOrDefault(sdf+"TModeStr", "")
	String instr = StrVarOrDefault(cdf+"ClampInstrument", "")
	
	if (chan < 0)
		return -1
	endif
	
	telValue = ClampReadManager(StrVarOrDefault(cdf+"AcqBoard", ""), driver, chan, 1, 5)
	tmode = TModeAxo200B(telValue)
	
	strswitch(instr)
	
		case "Axopatch200B":
		
			if (StringMatch(amode, "I-clamp") == 1)
				if (StringMatch(tmode[0,0], "I") == 1)
					tmode = "I-clamp"
				endif
			endif
			
			if (StringMatch(amode, tmode) == 0)
				ClampError("acquisition mode should be " + amode)
				return -1
			endif
			
			break
			
	endswitch
	
	String /G TModeStr = amode
	
End // TModeCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function TModeCheckConfig()
	String cdf = ClampDF(), sdf = StimDF()
	
	Variable chan = NumVarOrDefault(cdf+"TModeChan", -1) + 1
	String amode = StrVarOrDefault(sdf+"TModeStr", "")
	String instr = StrVarOrDefault(cdf+"ClampInstrument", "")
	
	String mlist = "V-clamp;I-clamp;I-clamp Normal;I-clamp Fast;"
	
	Prompt chan, "select ACD input that reads telegraph mode:", popup "0;1;2;3;4;5;6;7;"
	Prompt amode, "choose mode required for this protocol:", popup mlist
	Prompt instr, "telegraphed instrument:", popup "Axopatch200B;"
	
	DoPrompt "Check Telegraph Mode", chan, amode, instr
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMvar(cdf+"TModeChan", chan-1)
	SetNMstr(sdf+"TModeStr", amode)

End // TModeCheckConfig

//****************************************************************
//
//	ReadTemp()
//	read temperature from ADC input (read once)
//
//
//****************************************************************

Function ReadTemp(mode)
	Variable mode // (0) run fxn (1) config fxn (-1) kill fxn
	
	Variable telValue
	String cdf = ClampDF(), sdf = StimDF()
	
	if (mode == 1)
		ReadTempConfig()
	elseif (mode == -1)
		return 0
	endif
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	Variable chan = NumVarOrDefault(cdf+"TempChan", -1)
	Variable slope = NumVarOrDefault(cdf+"TempSlope", Nan)
	Variable offset = NumVarOrDefault(cdf+"TempOffset", Nan)
	
	if ((chan < 0) || (numtype(chan*slope*offset) > 0))
		return -1
	endif
	
	telValue = ClampReadManager(StrVarOrDefault(cdf+"AcqBoard", ""), driver, chan, 1, 50)
	
	telValue = telValue * slope + offset
	
	NMHistory("\rTemperature: " + num2str(telValue))
	
	NotesFileVar("F_Temp", telValue)
	
End // ReadTemp

//****************************************************************
//
//	TempRead()
//	read temperature from ADC input (saves to a wave)
//
//
//****************************************************************

Function TempRead(mode)
	Variable mode // (0) run fxn (1) config fxn (-1) kill fxn
	
	Variable telValue
	String cdf = ClampDF(), sdf = StimDF()
	
	if (mode == 1)
		ReadTempConfig()
	elseif (mode == -1)
		return 0
	endif
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	Variable chan = NumVarOrDefault(cdf+"TempChan", -1)
	Variable slope = NumVarOrDefault(cdf+"TempSlope", Nan)
	Variable offset = NumVarOrDefault(cdf+"TempOffset", Nan)
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	Variable currentWave = NumVarOrDefault("CurrentWave", 0)
	
	if ((chan < 0) || (numtype(chan*slope*offset) > 0))
		return -1
	endif
	
	telValue = ClampReadManager(StrVarOrDefault(cdf+"AcqBoard", ""), driver, chan, 1, 50)
	
	telValue = telValue * slope + offset
	
	if (WaveExists(CT_Temp) == 0)
		Make /N=(nwaves) CT_Temp = Nan
	endif
	
	if (numpnts(CT_Temp) != nwaves)
		Redimension /N=(nwaves) CT_Temp
	endif
	
	if (currentWave >= nwaves)
		Redimension /N=(currentWave+1) CT_Temp
	endif
	
	Wave CT_Temp
	
	CT_Temp = Zero2Nan(CT_Temp)
	
	if (currentWave == 0)
		CT_Temp = Nan
	endif
	
	CT_Temp[currentWave] = telValue
	
	WaveStats /Q CT_Temp
	
	NotesFileVar("F_Temp", V_avg)
	
End // TempRead

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadTempConfig()
	String cdf = ClampDF(), sdf = StimDF()
	
	Variable chan = NumVarOrDefault(cdf+"TempChan", -1) + 1
	Variable slope = NumVarOrDefault(cdf+"TempSlope", 1)
	Variable offset = NumVarOrDefault(cdf+"TempOffset", 0)
	
	Prompt chan, "select ADC input to acquire temperature:", popup "0;1;2;3;4;5;6;7;"
	Prompt slope, "enter slope conversion factor (degrees / V) :"
	Prompt offset, "enter offset factor (degrees) :"
	DoPrompt "Read Temperature", chan, slope, offset
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMvar(cdf+"TempChan", chan-1)
	SetNMvar(cdf+"TempSlope", slope)
	SetNMvar(cdf+"TempOffset", offset)

End // ReadTempConfig

//****************************************************************
//
//	Rstep()
//	measure resistance of voltage/current step
//
//****************************************************************

Function Rstep(mode)
	Variable mode // (0) run fxn (1) config fxn (-1) kill fxn
	
	Variable chan, base, output, input, tscale = 1
	Variable /G CT_Rstep
	String outName, inName, gname
	String cdf = ClampDF(), sdf = StimDF()
	
	if (mode == 1)
		RstepConfig()
		return 0
	elseif (mode == -1)
		return 0
	endif
	
	Variable ADCconfig = NumVarOrDefault(sdf+"RstepADC", Nan)
	Variable DACconfig = NumVarOrDefault(sdf+"RstepDAC", Nan)
	Variable tbgn = NumVarOrDefault(sdf+"RstepTbgn", Nan)
	Variable tend = NumVarOrDefault(sdf+"RstepTend", Nan)
	Variable scale = NumVarOrDefault(sdf+"RstepScale", Nan)
	
	String board = StrVarOrDefault(cdf+"AcqBoard", "")
	
	if (numtype(ADCconfig*DACconfig*tbgn*tend*scale) > 0)
		return 0
	endif
	
	String ADClist = StimOnList(sdf, "ADC")
	
	Variable grp = NumVarOrDefault("CurrentGrp", 0)
	
	outName = sdf + "DAC_" + num2str(DACconfig) + "_" + num2str(grp)
	
	chan = WhichListItem(num2str(ADCconfig), ADClist, ";")
	
	inName = GetWaveName("default", chan, 0)
	
	if ((WaveExists($outName) == 0) || (WaveExists($inName) == 0))
		return -1
	endif
	
	if (StringMatch(board, "NIDAQ") == 1)
		tscale = 0.001 // convert to seconds for NIDAQ boards
	endif
	
	WaveStats /Q/R=(0*tscale,2*tscale) $outName
	
	base = V_avg
	
	WaveStats /Q/R=(tbgn*tscale, tend*tscale) $outName
	
	output = abs(V_avg - base)
	
	WaveStats /Q/R=(0,1) $inName
	
	base = V_avg
	
	WaveStats /Q/R=(tbgn, tend) $inName
	
	input = abs(V_avg - base)
	
	if (scale < 0)
		CT_Rstep = -1 * output * scale / input
	else
		CT_Rstep = input * scale / output
	endif
	
	CT_Rstep = round(CT_Rstep * 100) / 100
	
	gName = ChanGraphName(chan)
	outName = GetWaveName("Display", chan, 0)
	
	Tag /C/W=$gname/N=Rtag bottom, tend, num2str(CT_Rstep) + " Mohms"
	
End // Rstep

//****************************************************************
//****************************************************************
//****************************************************************

Function RstepConfig()
	String cdf = ClampDF(), sdf = StimDF()
	
	Variable ADCconfig, DACconfig, tbgn, tend, scale
	String ADCstr, DACstr, ADCunit, DACunit
	
	String ADClist = StimOnList(sdf, "ADC")
	String DAClist = StimOnList(sdf, "DAC")
	
	Variable ADCcount = ItemsInList(ADClist)
	Variable DACcount = ItemsInList(DAClist)
	
	if (ADCcount == 0)
		ClampError("No ADC input channels to measure.")
		return 0
	endif
	
	if (DACcount == 0)
		ClampError("No DAC output channels to measure.")
		return 0
	endif
	
	ADCconfig = str2num(StringFromList(0, ADClist))
	DACconfig = str2num(StringFromList(0, DAClist))
	
	ADCconfig = NumVarOrDefault(sdf+"RstepADC", ADCconfig)
	DACconfig = NumVarOrDefault(sdf+"RstepDAC", DACconfig)
	tbgn = NumVarOrDefault(sdf+"RstepTbgn", 0)
	tend = NumVarOrDefault(sdf+"RstepTend", 5)
	scale = NumVarOrDefault(sdf+"RstepScale", 1)
	
	ADCstr = num2str(ADCconfig)
	DACstr = num2str(DACconfig)

	Prompt ADCstr, "ADC input configuration to measure:", popup ADClist
	Prompt DACstr, "DAC output configuration to measure:", popup DAClist
	Prompt tbgn, "measure time begin:"
	Prompt tend, "measure time end:"
	DoPrompt "Compute Rstepance", ADCstr, DACstr, tbgn, tend
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	ADCconfig = str2num(ADCstr)
	DACconfig = str2num(DACstr)
	
	SetNMvar(sdf+"RstepADC", ADCconfig)
	SetNMvar(sdf+"RstepDAC", DACconfig)
	SetNMvar(sdf+"RstepTbgn", tbgn)
	SetNMvar(sdf+"RstepTend", tend)
	
	Wave DACscale = $(sdf+"DACscale")
	
	Wave /T ADCunits = $(sdf+"ADCunits")
	Wave /T DACunits = $(sdf+"DACunits")
	
	ADCstr = ADCunits[ADCconfig]
	DACstr = DACunits[DACconfig]
	
	ADCunit = ADCstr[strlen(ADCstr)-1,inf]
	DACunit = DACstr[strlen(DACstr)-1,inf]
	
	if ((StringMatch(ADCunit,"A") == 1) && (StringMatch(DACunit,"V") == 1))
		scale = -1
	elseif ((StringMatch(ADCunit,"V") == 1) && (StringMatch(DACunit,"A") == 1))
		scale = 1
	else
		SetNMvar(sdf+"RstepScale", 1) // unfamiliar units
		return 0
	endif
	
	ADCunit = ADCstr[0,strlen(ADCstr)-2]
	DACunit = DACstr[0,strlen(DACstr)-2]
	
	if (scale == 1) // compute appropriate scale to get Mohms
		scale *= 1e-6 * MetricValue(ADCunit) / (MetricValue(DACunits) * DACscale[DACconfig])
	else
		scale *= 1e-6 * MetricValue(DACunits) *  DACscale[DACconfig] / MetricValue(ADCunits)
	endif
	
	SetNMvar(sdf+"RstepScale", scale)

End // RstepConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function MetricValue(prefix)
	String prefix
	Variable cprefix = char2num(prefix)
	
	switch(cprefix)
		case 71: // "G"
			return 1e9
		case 77: // "M"
			return 1e6
		case 107: // "k"
			return 1e3
		case 99: // "c"
			return 1e-2
		case 109: // "m"
			return 1e-3
		case 117: // "u"
			return 1e-6
		case 110: // "n"
			return 1e-9
		case 112: // "p"
			return 1e-12
		default:
			return 0
	endswitch
	
End // MetricValue

//****************************************************************
//
//	RCstep()
//	measure resistance and capacitence of cell membrane
//
//****************************************************************

Function RCstep(mode)
	Variable mode // (0) run fxn (1) config fxn (-1) kill fxn
	
	Variable toffset = 0.02 // time after step to start curve fit
	
	Variable fbgn, fend
	Variable chan, base, vstep, input, tbase, tscale = 1, negstep = 0
	Variable Ipeak, Iss, tau, Rp, Rm, Cm
	
	String outName, inName, inName2, gname
	String cdf = ClampDF(), sdf = StimDF()
	
	if (mode == 1)
		RCstepConfig()
		//return 0
	elseif (mode == -1)
		return 0
	endif
	
	Variable currentWave = NumVarOrDefault("CurrentWave", 0)
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	Variable grp = NumVarOrDefault("CurrentGrp", 0)
	
	Variable ADCconfig = NumVarOrDefault(sdf+"RCstepADC", Nan)
	Variable DACconfig = NumVarOrDefault(sdf+"RCstepDAC", Nan)
	Variable tbgn = NumVarOrDefault(sdf+"RCstepTbgn", Nan)
	Variable tend = NumVarOrDefault(sdf+"RCstepTend", Nan)
	Variable scale = NumVarOrDefault(sdf+"RCstepScale", Nan)
	
	Variable dsply = NumVarOrDefault(sdf+"RCstepDisplay", 1)
	
	String ADClist = StimOnList(sdf, "ADC")
	String board = StrVarOrDefault(cdf+"AcqBoard", "")
	
	if (numtype(ADCconfig*DACconfig*tbgn*tend*scale) > 0)
		return 0 // bad parameters
	endif
	
	if (StringMatch(board, "NIDAQ") == 1)
		tscale = 0.001 // convert to seconds for NIDAQ boards
	endif
	
	if (CurrentWave == 0)
		Make /O/N=(nwaves) CT_Cm
		Make /O/N=(nwaves) CT_Rm
		Make /O/N=(nwaves) CT_Rp
		CT_Cm = Nan
		CT_Rm = Nan
		CT_Rp = Nan
	else
		Wave CT_Cm, CT_Rm, CT_Rp
	endif
	
	outName = sdf + "DAC_" + num2str(DACconfig) + "_" + num2str(grp)
	
	chan = WhichListItem(num2str(ADCconfig), ADClist, ";")
	
	inName = ChanDisplayWave(chan)
	
	if ((WaveExists($outName) == 0) || (WaveExists($inName) == 0))
		return -1
	endif
	
	tbase = tbgn - 0.5
	
	WaveStats /Q/R=(0, tbase) $outName // baseline
	
	base = V_avg // should be zero
	
	WaveStats /Q/R=(tbgn*tscale, tend*tscale) $outName
	
	vstep = abs(V_avg - base)
	
	if (V_avg < base)
		negstep = 1
	endif
	
	WaveStats /Q/R=(tbgn*tscale, tend*tscale) $inName
	
	//fbgn = tbgn
	
	if (negstep == 1)
		fbgn = V_minloc + toffset
	else
		fbgn = V_maxloc + toffset
	endif
	
	fend = tend
	
	gName = ChanGraphName(chan)
	inName2 = GetWaveName("Display", chan, 0)
	
	// prepare graph and do curve fit
	
	DoWindow /F $gName
	
	if (CurrentWave == 0)
		ShowInfo /W=$gName
		Cursor /W=$gName A, $inName2, fbgn
		Cursor /W=$gName B, $inName2, fend
	endif
	
	Wave wtemp = $ChanDisplayWave(chan)
	
	WaveStats /Q/R=(0, tbase) wtemp // baseline
	
	base = V_avg
	
	if (WaveExists(RCparams) == 0)
		Make /N=4 RCparams
	endif
	
	Wave RCparams
	
	RCparams[0] = tbgn
	RCparams[1] = V_avg
	RCparams[3] = (fend - fbgn)  / 4
	
	if (negstep == 1)
		RCparams[2] = V_min // probably a negative transient
	else
		RCparams[2] = V_max // probably a positive transient
	endif
	
	FuncFit /Q/W=0/H="1000"/N RCfit RCparams wtemp(fbgn, fend) /D
	
	// save results 
	
	Ipeak = abs(RCparams[1] + RCparams[2] - base)
	Iss = abs(RCparams[1] - base)
	tau = 1 / RCparams[3]
	
	Rp = Vstep * scale / Ipeak // recording pipette
	Rm = (Vstep * scale / Iss) - Rp // membrane resistance
	Cm = (tau / 0.001) * ( 1 / Rp + 1 / Rm) // membrane cap
	
	CT_Rp[CurrentWave] = Rp
	CT_Rm[CurrentWave] = Rm
	CT_Cm[CurrentWave] = Cm
	
	if (dsply == 1)
		Print "\r" + inName
		//Print "Ipeak = " + num2str(Ipeak)
		//Print "Iss = " + num2str(Iss)
		//Print "Tau = " + num2str(tau)
		Print "Rp = " + num2str(Rp)
		Print "Rm = " + num2str(Rm)
		Print "Cm = " + num2str(Cm)
	elseif (dsply == 2)
		RCstepDisplay()
	endif
	
End // RCstep

//****************************************************************
//****************************************************************
//****************************************************************

Function RCstepDisplay()
	
	Variable num, inc = 10
	Variable currentWave = NumVarOrDefault("CurrentWave", 0)
	Variable numWaves = NumVarOrDefault("NumWaves", 0)
	
	String gName = "ClampRC"
	
	String cdf = ClampDF(), stdf = StatsDF()
	
	if (WinType(gName) == 0)
	
		Display /K=1/W=(0,0,200,100) CT_Rp, CT_Rm as "Nclamp RC Estimation"
		DoWindow /C $gName
		
		AppendToGraph /R=Cm /W=$gName CT_Cm
		
		Label /W=$gName bottom StrVarOrDefault("WavePrefix", "Wave")
		Label /W=$gName left "MOhm"
		Label /W=$gName Cm "pF"
		
		SetAxis /W=$gName bottom 0,10
		
		ModifyGraph /W=$gName mode=4
		ModifyGraph /W=$gName marker(CT_Rp)=5, rgb(CT_Rp)=(0,0,39168)
		ModifyGraph /W=$gName marker(CT_Rm)=16, rgb(CT_Rm)=(0,0,39168)
		ModifyGraph /W=$gName marker(CT_Cm)=19, rgb(CT_Cm)=(65280,0,0)
		
		ModifyGraph axRGB(Cm)=(65280,0,0),alblRGB(Cm)=(65280,0,0)
		
		Legend/C/N=text0/A=LT
			
	endif
	
	if ((currentWave > 0) && (WinType(gName) == 1))
		num = inc * (1 + floor(currentWave / inc))
		num = min(numwaves, num)
		SetAxis /Z/W=$gName bottom 0, num
	endif

End // RCstepDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function RCfit(w,x) : FitFunc
	Wave w
	Variable x
	Variable y
	
	if (numpnts(w) !=4)
		return Nan
	endif
	
	// w[0] = t0
	// w[1] = Yss
	// w[2] = Y0
	// w[3] = invTau
	
	y = w[1] + w[2] * exp(-(x - w[0]) * w[3])
	
	if ((x < w[0]) || (numtype(y) > 0))
		return 0
	else
		return y
	endif
	
End // RCfit

//****************************************************************
//****************************************************************
//****************************************************************

Function RCstepConfig()
	String cdf = ClampDF(), sdf = StimDF()

	Variable scale = 1
	String ADCstr, DACstr, ADCunit, DACunit
	
	String ADClist = StimOnList(sdf, "ADC")
	String DAClist = StimOnList(sdf, "DAC")
	
	Variable ADCcount = ItemsInList(ADClist)
	Variable DACcount = ItemsInList(DAClist)
	
	if (ADCcount == 0)
		ClampError("No ADC input channels to measure.")
		return 0
	endif
	
	if (DACcount == 0)
		ClampError("No DAC output channels to measure.")
		return 0
	endif
	
	Variable ADCconfig = str2num(StringFromList(0, ADClist))
	Variable DACconfig = str2num(StringFromList(0, DAClist))
	
	ADCconfig = NumVarOrDefault(sdf+"RCstepADC", ADCconfig)
	DACconfig = NumVarOrDefault(sdf+"RCstepDAC", DACconfig)
	
	Variable tbgn = NumVarOrDefault(sdf+"RCstepTbgn", 0)
	Variable tend = NumVarOrDefault(sdf+"RCstepTend", 5)
	
	Variable dsply = NumVarOrDefault(sdf+"RCstepDisplay", 2)
	
	ADCstr = num2str(ADCconfig)
	DACstr = num2str(DACconfig)

	Prompt ADCstr, "ADC input configuration to measure (pA):", popup ADClist
	Prompt DACstr, "DAC output configuration to measure (mV):", popup DAClist
	Prompt tbgn, "DAC step time begin:"
	Prompt tend, "DAC step time end:"
	Prompt dsply, "display results in:", popup "Igor history;graph;"
	DoPrompt "Compute Membrane R and C", ADCstr, DACstr, tbgn, tend, dsply
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	ADCconfig = str2num(ADCstr)
	DACconfig = str2num(DACstr)
	
	SetNMvar(sdf+"RCstepADC", ADCconfig)
	SetNMvar(sdf+"RCstepDAC", DACconfig)
	SetNMvar(sdf+"RCstepTbgn", tbgn)
	SetNMvar(sdf+"RCstepTend", tend)
	SetNMvar(sdf+"RCstepDisplay", dsply)
	
	Wave DACscale = $(sdf+"DACscale")
	
	Wave /T ADCunits = $(sdf+"ADCunits")
	Wave /T DACunits = $(sdf+"DACunits")
	
	ADCstr = ADCunits[ADCconfig]
	DACstr = DACunits[DACconfig]
	
	ADCunit = ADCstr[strlen(ADCstr)-1,inf]
	DACunit = DACstr[strlen(DACstr)-1,inf]
	
	if ((StringMatch(ADCunit,"A") == 1) && (StringMatch(DACunit,"V") == 1))
		ADCunit = ADCstr[0,strlen(ADCstr)-2]
		DACunit = DACstr[0,strlen(DACstr)-2]
		scale = 1e-6 * MetricValue(DACunits) *  DACscale[DACconfig] / MetricValue(ADCunits)
	else
		DoAlert 0, "RCStep warning: input / output units do not appear to be correct. This function works only in voltage-clamp mode."
	endif
	
	SetNMvar(sdf+"RCstepScale", scale)

End // RCstepConfig

//****************************************************************
//
//	MyTelegraphGain()
//	see NIDAQ code for example call
//
//****************************************************************

Function MyTelegraphGain(tgain, defaultGain)
	Variable tgain // telegraphed value
	Variable defaultGain // default gain value
	
	String cdf = ClampDF()
	
	String instr = StrVarOrDefault(cdf+"ClampInstrument", "")
	
	Variable scale, beta, alpha = -1
	
	strswitch(instr)
		case "Axopatch200B":
			alpha = TGainAxo200B(tgain)
			beta = 1 // whole cell
			scale = 0.001 * beta // V / mV
			break
	endswitch
	
	if ((alpha <= 0) || (numtype(alpha) != 0))
		return defaultGain
	else
		return (alpha * scale)
	endif
	
End // MyTelegraphGain

//****************************************************************
//
//	TGainAxo200B()
//	Axopatch 200B telegraph gain look-up table
//
//****************************************************************

Function TGainAxo200B(telValue)
	Variable telValue
	
	telValue = 5*round(10 * telValue / 5)
	
	switch(telValue)
		case 5:
			return 0.05
		case 10:
			return 0.1
		case 15:
			return 0.2
		case 20:
			return 0.5
		case 25:
			return 1
		case 30:
			return 2
		case 35:
			return 5
		case 40:
			return 10
		case 45:
			return 20
		case 50:
			return 50
		case 55:
			return 100
		case 60:
			return 200
		case 65:
			return 500
		default:
			Print "\rAxopatch 200B Telegraph Gain not recognized : " + num2str(telValue)
	endswitch
	
	return -1

End // TGainAxo200B

//****************************************************************
//
//	TFreqAxo200B()
//	Axopatch 200B telegraph frequency look-up table
//
//****************************************************************

Function TFreqAxo200B(telValue)
	Variable telValue
	
	telValue = 5*round(10 * telValue / 5)
	
	switch(telValue)
		case 20:
			return 1
		case 40:
			return 2
		case 60:
			return 5
		case 80:
			return 10
		case 100:
			return 100
		default:
			Print "\rAxopatch 200B Telegraph Frequency not recognized : " + num2str(telValue)
	endswitch
	
	return -1

End // TFreqAxo200B

//****************************************************************
//
//	TModeAxo200B()
//	Axopatch 200B telegraph mode look-up table
//
//****************************************************************

Function /S TModeAxo200B(telValue)
	Variable telValue
	
	telValue = 5*round(10 * telValue / 5)
	
	switch(telValue)
		case 40:
			return "Track"
		case 60:
			return "V-Clamp"
		case 30:
			return "I = 0"
		case 20:
			return "I-Clamp Normal"
		case 10:
			return "I-Clamp Fast"
		default:
			Print "\rAxopatch 200B Telegraph Mode not recognized : " + num2str(telValue)
	endswitch
	
	return ""

End // TModeAxo200B

//****************************************************************
//
//	TCapAxo200B()
//	Axopatch 200B telegraph cell capacitance look-up table
//
//****************************************************************

Function TCapAxo200B(telValue, beta)
	Variable telValue
	Variable beta
	
	if ((telValue < 0) || (telValue > 10))
		Print "\rAxopatch 200B Telegraph Capacitance not recognized : " + num2str(telValue)
		return -1
	endif
	
	if (beta == 1)
		return telValue * 10 // 0 - 100 pF
	elseif (beta == 0.1)
		return telValue * 100 // range 0 - 1000 pF
	else
		Print "\rAxopatch 200B Telegraph Capacitance not recognized : " + num2str(telValue)
		return -1
	endif

End // TCapAxo200B

//****************************************************************
//****************************************************************
//****************************************************************

