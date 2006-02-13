#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Acquisition Stim Protocol Functions
//	To be run with NeuroMatic, v1.91
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
//	Last modified 04 March 2005
//
//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Global Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStim(dp, sname, numADC, numDAC, numTTL) // declare stim global variables
	String dp // path
	String sname // stim name
	Variable numADC, numDAC, numTTL
	
	String df = dp + sname + ":"
	
	Variable numStimWaves = 1
	Variable waveLength = 100
	Variable sampleInterval = 0.2
	Variable interStimTime = 900
	Variable interRepTime = 0
	Variable stimRate = 1000 / (waveLength + interStimTime)
	Variable repRate = 1000 / (interRepTime + numStimWaves * (waveLength + interStimTime))
	Variable samplesPerWave = floor(waveLength/sampleInterval)
	
	if (DataFolderExists(df) == 0)
		NewDataFolder $LastPathColon(df, 0) 				// make new stim folder
	endif
	
	CheckNMstr(df+"FileType", "NMStim")					// type of data file
	
	CheckNMvar(df+"Version", NumVarOrDefault(NMDF()+"NMversion",-1))
	
	CheckNMstr(df+"WavePrefix", "Record")					// wave prefix name
	
	CheckNMvar(df+"AcqMode", 0)							// acquisition mode (0) epic precise (1) continuous (2) episodic (3) triggered
	
	CheckNMvar(df+"CurrentChan", 0)						// channel select
	
	CheckNMvar(df+"WaveLength", waveLength)				// wave length (ms)
	CheckNMvar(df+"SampleInterval", sampleInterval)			// time sample interval (ms)
	CheckNMvar(df+"SamplesPerWave", samplesPerWave)
	
	CheckNMvar(df+"NumStimWaves", numStimWaves)		// stim waves per channel
	CheckNMvar(df+"InterStimTime", interStimTime)			// time between stim waves (ms)
	CheckNMvar(df+"NumStimReps", 1)					// repitions of stimulus
	CheckNMvar(df+"InterRepTime", interRepTime)			// time between stimulus repititions (ms)
	CheckNMvar(df+"StimRate", stimRate)
	CheckNMvar(df+"RepRate", repRate)
	CheckNMvar(df+"TotalTime", 1/repRate)
	
	CheckNMvar(df+"NumPulseVar", 12)					// number of variables in pulse waves
	
	CheckNMstr(df+"InterStimFxnList", "")					// during acquisition run function list
	CheckNMstr(df+"PreStimFxnList", "")					// pre-acquisition run function list
	CheckNMstr(df+"PostStimFxnList", "")					// post-acquisition run function list
	
	// IO Channels
	
	CheckNMwave(df+"ADCon", numADC, 0)				// ADC input selector
	CheckNMtwave(df+"ADCname", numADC,"ADC")			// ADC channel name
	CheckNMtwave(df+"ADCunits", numADC, "V")			// ADC channel units
	CheckNMwave(df+"ADCscale", numADC, 1)				// ADC scale factors
	CheckNMwave(df+"ADCboard", numADC, 0)				// ADC board number
	CheckNMwave(df+"ADCchan", numADC, 0)				// ADC board chan
	CheckNMwave(df+"ADCmode", numADC, 0)				// ADC input mode
	CheckNMwave(df+"ADCgain", numADC, 1)				// ADC channel gains
	
	CheckNMwave(df+"DACon", numDAC, 0)				// DAC output selector
	CheckNMtwave(df+"DACname", numDAC,"DAC")			// DAC channel name
	CheckNMtwave(df+"DACunits", numDAC, "V")			// DAC channel units
	CheckNMwave(df+"DACscale", numDAC, 1)				// DAC scale factors
	CheckNMwave(df+"DACboard", numDAC, 0)				// DAC board number
	CheckNMwave(df+"DACchan", numDAC, 0)				// DAC board chan
	
	CheckNMwave(df+"TTLon", numTTL, 0)					// TTL output selector
	CheckNMtwave(df+"TTLname", numTTL,"TTL")			// TTL channel name
	CheckNMtwave(df+"TTLunits", numTTL, "V")				// TTL channel units
	CheckNMwave(df+"TTLscale", numTTL, 1)				// TTL scale factors
	CheckNMwave(df+"TTLboard", numTTL, 0)				// TTL board number
	CheckNMwave(df+"TTLchan", numTTL, 0)				// TTL board chan
	
End // CheckStim

//****************************************************************
//****************************************************************
//****************************************************************

Function StimInitWaves(dp, sname) // set initial values
	String dp // path
	String sname // stim name
	
	String df = dp + sname + ":"
	
	if (DataFolderExists(df) == 0)
		return -1
	endif
	
	Wave ADCchan = $(df+"ADCchan")
	Wave DACchan = $(df+"DACchan")
	Wave TTLchan = $(df+"TTLchan")
	
	Wave /T ADCname = $(df+"ADCname")
	Wave /T DACname = $(df+"DACname")
	Wave /T TTLname = $(df+"TTLname")
	
	ADCchan = x; DACchan = x; TTLchan = x
	
	ADCname = "ADC" + num2str(x)
	DACname = "DAC" + num2str(x)
	TTLname = "TTL" + num2str(x)

End // StimInitWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function StimRedimenWaves(sdf, io, npnts)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	Variable npnts
	
	if (DataFolderExists(sdf) == 0)
		return -1
	endif
	
	if (npnts < numpnts($(sdf+io+"on")))
		return 0
	endif
	
	Redimension /N=(npnts) $(sdf+io+"on")
	Redimension /N=(npnts) $(sdf+io+"name")
	Redimension /N=(npnts) $(sdf+io+"units")
	Redimension /N=(npnts) $(sdf+io+"scale")
	Redimension /N=(npnts) $(sdf+io+"board")
	Redimension /N=(npnts) $(sdf+io+"chan")
	
	if (StringMatch(io, "ADC") == 1)
		Redimension /N=(npnts) $(sdf+"ADCmode")
		Redimension /N=(npnts) $(sdf+"ADCgain")
	endif
	
End // StimRedimenWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function StimWaveVar(sdf, io, select, config)
	String sdf
	String io
	String select
	Variable config
	
	String wName = sdf + io + select
	
	if ((WaveExists($wName) == 0) || (WaveType($wName) == 0))
		return inf
	endif
	
	Wave wTemp = $wName
	
	return wTemp[config]

End // StimWaveVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWaveStr(sdf, io, select, config)
	String sdf
	String io
	String select
	Variable config
	
	String wName = sdf + io + select
	
	if ((WaveExists($wName) == 0) || (WaveType($wName) != 0))
		return "error"
	endif
	
	Wave /T wTemp = $wName
	
	return wTemp[config]

End // StimWaveStr

//****************************************************************
//****************************************************************
//****************************************************************

Function StimInterval(sdf, boardNum)
	String sdf // stim data folder path
	Variable boardNum
	
	String varName
	Variable SampleInterval = NumVarOrDefault(sdf+"SampleInterval", 1) // default driver value

	varName = sdf + "SampleInterval_" + num2str(boardNum) // board-specific sample interval
	
	if (exists(varName) == 2)
		SampleInterval = NumVarOrDefault(varName, SampleInterval)
	endif
	
	return StimIntervalCheck(SampleInterval)
		
End // StimInterval

//****************************************************************
//****************************************************************
//****************************************************************

Function StimIntervalCheck(intvl)
	Variable intvl
	
	return (round(1e6*intvl)/1e6)
	
End // StimIntervalCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function StimOnCount(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	return ItemsInList(StimOnList(sdf, io))
	
End // StimOnCount

//****************************************************************
//****************************************************************
//****************************************************************

Function StimNumChannels(sdf)
	String sdf // stim data folder
	
	Variable config, ccnt
	
	Wave ADCon = $(sdf+"ADCon")
	Wave ADCmode = $(sdf+"ADCmode")

	for (config = 0; config < numpnts(ADCon); config += 1)
		if ((ADCon[config] == 1) && (ADCmode[config] <= 0))
			ccnt += 1
		endif
	endfor

	return ccnt

End // StimNumChannels

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimAcqStr(acqMode)
	Variable acqMode
	
	switch(acqMode)
		case 0:
			return "episodic"
		case 1:
			return "continuous"
		case 2:
			return "epic precise"
		case 3:
			return "triggered"
		default:
			return ""
	endswitch
	
End // StimAcqStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimOnList(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	sdf = LastPathColon(sdf, 1)
	
	Variable config, count
	String list = "", wname = sdf + io + "on"
	
	if (WaveExists($wname) == 0)
		return ""
	endif
	
	Wave on = $wname
	
	strswitch(io)
	
		case "ADC":
		
			Wave ADCmode = $(sdf+"ADCmode")
	
			for (config = 0; config < numpnts(on); config += 1)
				if ((on[config] == 1) && (ADCmode[config] == 0))
					list = AddListItem(num2str(config), list, ";", inf)
				endif
			endfor
			
			break
	
		case "DAC":
		case "TTL":
		
			for (config = 0; config < numpnts(on); config += 1)
				if (on[config] == 1)
					list = AddListItem(num2str(config), list, ";", inf)
				endif
			endfor
			
	endswitch
	
	return list
	
End // StimOnList

//****************************************************************
//****************************************************************
//****************************************************************

Function StimConfigTable(sdf, io, hook)
	String sdf // stim data folder path
	String io // "ADC", "DAC" or "TTL"
	Variable hook // (0) no update (1) updateNM
	
	Variable icnt
	String wlist, wName, tName, title
	
	String stim = GetPathName(sdf,0)
	
	tName = io + "_" + stim
	
	if (WinType(tName) == 2)
		DoWindow /F $tName
		return 0
	endif
	
	strswitch(io)
	
		case "ADC":
			wlist = "ADCon;ADCname;ADCunits;ADCscale;ADCboard;ADCchan;ADCmode;ADCgain"
			title = "ADC Input Configuration : " + stim
			break
			
		case "DAC":
			wlist = "DACon;DACname;DACunits;DACscale;DACboard;DACchan;"
			title = "DAC Output Configuration : " + stim
			break
			
		case "TTL":
			wlist = "TTLon;TTLname;TTLunits;TTLscale;TTLboard;TTLchan;"
			title = "TTL Output Configuration : " + stim
			break
			
		default:
			return -1
			
	endswitch
	
	DoWindow /K $tName
	Edit /W=(0,0,0,0)/K=1
	DoWindow /C $tName
	SetCascadeXY(tName)
	DoWindow /T $tName, title
	Execute "ModifyTable title(Point)= \"Config\""
	
	if (hook == 1)
		SetWindow $tName hook=StimConfigTableHook
	endif
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
	
		wName = sdf + StringFromList(icnt,wlist)
		
		if (WaveExists($wName) == 1)
			AppendToTable $wName
		endif
	
	endfor

End // StimConfigTable

//****************************************************************
//****************************************************************
//****************************************************************

Function StimConfigTableHook(infoStr)
	string infoStr
	
	string event= StringByKey("EVENT",infoStr)
	string win= StringByKey("WINDOW",infoStr)
	
	strswitch(event)
		case "deactivate":
		case "kill":
			UpdateNM(0)
	endswitch

End // StimConfigTableHook

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function StimWavesMove(from, to)
	String from, to // paths

	Variable icnt
	String wname, wlist, wlist2
	
	String thisDF = GetDataFolder(1) // save current directory
	
	SetDataFolder $from
	
	wlist = WaveList("DAC_*", ";", "") + WaveList("TTL_*", ";", "")
	wlist2 = WaveList("*_pulse*", ";", "") // pulse gen waves
	
	for (icnt = 0; icnt < ItemsInList(wlist2); icnt += 1)
		wlist = RemoveFromList(StringFromList(icnt, wlist2), wlist)
	endfor
	
	SetDataFolder $thisDF // back to original data folder
	
	if (ItemsInList(wlist) == 0)
		return 0
	endif
	
	if (DataFolderExists(to) == 0)
		NewDataFolder $LastPathColon(to, 0)
	endif
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
	
		wname = StringFromList(icnt, wlist)

		if (WaveExists($(from+wname)) == 1)
			MoveWave $(from+wname), $(to+wname)
		endif
		
	endfor

End // StimWavesMove

//****************************************************************
//****************************************************************
//****************************************************************

Function StimWavesKill(df, plist)
	String df // data folder where waves are located
	String plist // wave prefix list
	
	Variable icnt
	
	for (icnt = 0; icnt < ItemsInList(plist); icnt += 1)
		PulseWavesKill(df, StringFromList(icnt, plist)) // NM_PulseGen.ipf
	endfor

End // StimWavesKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWavesMakeAll(sdf, df, plist, scale)
	String sdf // stim data folder
	String df // where to make waves
	String plist // stim prefix list
	Variable scale // (-1) for user defined scale factor in stim folder

	Variable icnt, config, ORflag
	String outName, wPrefix, wlist = ""
	
	for (icnt = 0; icnt < ItemsInList(plist); icnt += 1)
	
		wPrefix = StringFromList(icnt, plist)
		outName = StimPrefix(wPrefix)
		config = StimConfigNum(wPrefix)
		
		if (StringMatch(outName, "TTL") == 1)
			ORflag = 1
		else
			ORflag = 0
		endif
		
		wlist += StimWavesMake(sdf, df, outName, config, scale, ORflag)
		
	endfor
	
	return wlist

End // StimWavesMakeAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWavesMake(sdf, df, outName, config, scale, ORflag)
	String sdf // stim data folder
	String df // where to make waves
	String outName // "DAC" or "TTL"
	Variable config // config number
	Variable scale // (-1) for user defined scale factor in stim folder
	Variable ORflag // (0) add pulses (1) OR pulses
	
	Variable wcnt, dt
	String wPrefix, wname, wlist = ""
	
	Variable numWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable wLength = NumVarOrDefault(sdf+"WaveLength", 0)
	
	if (WaveExists($(sdf+outName+"board")) == 0)
		return ""
	endif
	
	Wave OUTboard = $(sdf+outName+"board")
	Wave OUTscale = $(sdf+outName+"scale")
	
	if (scale == -1)
		scale = 1/OUTscale[config]
	endif
	
	dt = StimInterval(sdf, OUTboard[config])
	
	wPrefix = StimWaveName(outName, config, -1)
	
	if (NumVarOrDefault(sdf+"PulseGenOff", 0) == 0)
	
		wlist = PulseWavesMake(df, wPrefix, numWaves, floor(wLength/dt), dt, scale, ORflag) // NM_PulseGen.ipf
	
	else
	
		for (wcnt = 0; wcnt < numWaves; wcnt += 1) // copy existing "My" waves
		
			wname = wPrefix + "_" + num2str(wcnt)
			
			if (WaveExists($(sdf+"My"+wname)) == 1)
			
				Duplicate /O $(sdf+"My"+wname) $(df+wname)
				
				wlist = AddListItem(wname, wlist, ";", inf)
				
				Wave wtemp = $(df+wname)
				
				wtemp *= scale
				
			endif
			
		endfor
		
	endif
	
	return wlist

End // StimWavesMake

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function StimTableCall(sdf, pName)
	String sdf // stim data folder
	String pName // pulse wave name or "All"
	
	Variable icnt
	String plist = StimPulseList(sdf)
	String prefix
	
	if (strlen(pName) == 0)
		
		switch(ItemsInList(plist))
		
			case 0:
			
				DoAlert 0, "This folder has no stimulus configuration."
				return -1
			
			case 1:
			
				pName = StringFromList(0, plist)
				break
			
			default:
		
				Prompt pName, "choose stim pulse configuration:", popup plist
				DoPrompt "Stim Pulse Table", pName
				
				if (V_flag == 1)
					return 0 // cancel
				endif
				
		endswitch
	
	endif
	
	if (StringMatch(pName, "All") == 1)
	
		if (ItemsInList(plist) == 0)
			DoAlert 0, "Found no stim pulse configurations."
			return 0
		endif
	
		for (icnt = 0; icnt < ItemsInList(plist); icnt += 1)
			pName = StringFromList(icnt, plist)
			prefix = pName[0,0] + pName[4,4] + "_"
			StimTable(sdf+pName, sdf, prefix)
		endfor

	else
	
		prefix = pName[0,0] + pName[4,4] + "_"
		StimTable(sdf+pName, sdf, prefix)
		
	endif

End // StimTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimTable(pName, df, prefix)
	String pName // pulse wave name (full-path)
	String df // where to create table waves
	String prefix // prefix of table waves
	
	String tName = prefix + "StimTable"
	
	if (WaveExists($pname) == 0)
		return ""
	endif
	
	StimTableWavesUpdate(pName, df, prefix)
	
	DoWindow /K $tName
	
	Edit /K=1/W=(0,0,0,0) $(df+prefix+"Shape")
	DoWindow /C $tName
	DoWindow /T $tName, StimConfigStr(df, pName, "name") + " : " + GetPathName(pName,0)
	SetCascadeXY(tName)
	
	AppendToTable $(df+prefix+"WaveN")
	AppendToTable $(df+prefix+"ND")
	AppendToTable $(df+prefix+"Amp")
	AppendToTable $(df+prefix+"AD")
	AppendToTable $(df+prefix+"Onset")
	AppendToTable $(df+prefix+"OD")
	AppendToTable $(df+prefix+"Width")
	AppendToTable $(df+prefix+"WD")
	AppendToTable $(df+prefix+"Tau2")
	AppendToTable $(df+prefix+"TD")
	
	Execute /Z "ModifyTable title(Point)= \"Config\""
	
	Execute /Z "ModifyTable width=55"
	Execute /Z "ModifyTable width("+df+prefix+"ND)=40"
	Execute /Z "ModifyTable width("+ df+prefix+"OD)=40"
	Execute /Z "ModifyTable width("+ df+prefix+"AD)=40"
	Execute /Z "ModifyTable width("+ df+prefix+"WD)=40"
	Execute /Z "ModifyTable width("+ df+prefix+"TD)=40"
	
	return tName

End // StimTable

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStimTableWaves(df, prefix, npnts)
	String df // where table waves are located
	String prefix // prefix of table waves
	Variable npnts // number of points
	
	CheckNMwave(df+prefix+"Shape", npnts, Nan)
	CheckNMwave(df+prefix+"WaveN", npnts, Nan)
	CheckNMwave(df+prefix+"ND", npnts, Nan)
	CheckNMwave(df+prefix+"Onset", npnts, Nan)
	CheckNMwave(df+prefix+"OD", npnts, Nan)
	CheckNMwave(df+prefix+"Amp", npnts, Nan)
	CheckNMwave(df+prefix+"AD", npnts, Nan)
	CheckNMwave(df+prefix+"Width", npnts, Nan)
	CheckNMwave(df+prefix+"WD", npnts, Nan)
	CheckNMwave(df+prefix+"Tau2", npnts, Nan)
	CheckNMwave(df+prefix+"TD", npnts, Nan)

End // CheckStimTableWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTableWavesUpdate(pName, df, prefix)
	String pName // pulse wave name (full-path)
	String df // where to create table waves
	String prefix // prefix of table waves
	
	Variable icnt, index, ilmt, pNumVar = 12

	if (WaveExists($pname) == 0)
		return 0
	endif
	
	Wave Pulse = $pname
	
	ilmt = numpnts(Pulse) / pNumVar
	
	CheckStimTableWaves(df, prefix, ilmt)
	
	Wave Shape = $(df+prefix+"Shape")
	Wave WaveN = $(df+prefix+"WaveN")
	Wave WaveND = $(df+prefix+"ND")
	Wave Onset = $(df+prefix+"Onset")
	Wave OnsetD = $(df+prefix+"OD")
	Wave Amp = $(df+prefix+"Amp")
	Wave AmpD = $(df+prefix+"AD")
	Wave Width = $(df+prefix+"Width")
	Wave WidthD = $(df+prefix+"WD")
	Wave Tau2 = $(df+prefix+"Tau2")
	Wave Tau2D = $(df+prefix+"TD")
	
	Shape = Nan; WaveN = Nan; WaveND = Nan
	Onset = Nan; OnsetD = Nan; Amp = Nan; AmpD = Nan
	Width = Nan; WidthD = Nan; Tau2 = Nan; Tau2D = Nan
	
	for (icnt = 0; icnt < ilmt; icnt += 1)
		
		index = icnt*pNumVar
			
		Shape[icnt] = Pulse[index + 1]
		WaveN[icnt] = Pulse[index + 2]
		WaveND[icnt] = Pulse[index + 3]
		Onset[icnt] = Pulse[index + 4]
		OnsetD[icnt] = Pulse[index + 5]
		Amp[icnt] = Pulse[index + 6]
		AmpD[icnt] = Pulse[index + 7]
		Width[icnt] = Pulse[index + 8]
		WidthD[icnt] = Pulse[index + 9]
		Tau2[icnt] = Pulse[index + 10]
		Tau2D[icnt] = Pulse[index + 11]
		
	endfor

End // StimTableWavesUpdate

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Utility Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function IsStimFolder(dp, sname)
	String dp // path
	String sname // stim name
	
	return IsNMFolder(LastPathColon(dp, 1) + sname + ":", "NMStim")
	
End // IsStimFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimPrefixListAll(sdf)
	String sdf // stim data folder
	
	return StimPrefixList(sdf, "DAC") + StimPrefixList(sdf, "TTL")

End // StimPrefixListAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimPrefixList(sdf, type)
	String sdf // stim data folder
	String type // "DAC" or "TTL"
	
	Variable icnt
	String wName, wlist = ""
	
	wname = sdf + type + "on"
	
	if (WaveExists($wname) == 1)
	
		Wave wTemp = $wname
	
		for (icnt = 0; icnt < numpnts(wTemp); icnt += 1)
			if (wTemp[icnt] == 1)
				wlist = AddListItem(type + "_" + num2str(icnt), wlist, ";", inf)
			endif
		endfor
	
	endif

	return wlist

End // StimPrefixList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimNameListAll(sdf)
	String sdf // stim data folder
	
	return StimNameList(sdf, "DAC") + StimNameList(sdf, "TTL")

End // StimNameListAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimNameList(sdf, type)
	String sdf // stim data folder
	String type // "DAC" or "TTL"
	
	Variable icnt
	String txt, wlist = ""
	
	String wname = sdf + type + "on"
	String wname2 = sdf + type + "name"
	
	if ((WaveExists($wname) == 1) && (WaveExists($wname2) == 1))
	
		Wave wTemp = $wname
		Wave /T wTemp2 = $wname2
	
		for (icnt = 0; icnt < numpnts(wTemp); icnt += 1)
			if (wTemp[icnt] == 1)
				txt = type + "_" + num2str(icnt) + " : " + wTemp2[icnt]
				wlist = AddListItem(txt, wlist, ";", inf)
			endif
		endfor
	
	endif

	return wlist

End // StimNameList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimPulseList(sdf)
	String sdf
	
	String wlist = FolderObjectList(sdf, 5)
	
	return MatchStrList(wlist, "*_pulse")
	
End // StimPulseList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWaveList(sdf, df, prefixList, waveNum)
	String sdf // stim data folder
	String df // data folder where waves are located
	String prefixList // wave prefix name list
	Variable waveNum // (-1) all
	
	Variable icnt, wcnt, wbgn = waveNum, wend = waveNum
	String wname, wPrefix, wlist = ""
	
	Variable NumStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	
	if (waveNum == -1)
		wbgn = 0
		wend = NumStimWaves - 1
	endif
	
	for (icnt = 0; icnt < ItemsInList(prefixList); icnt += 1)
	
		wPrefix = StringFromList(icnt,prefixList)

		for (wcnt = wbgn; wcnt <= wend; wcnt += 1)
		
			wname = StimWaveName(wPrefix, -1, wcnt)
			
			if (WaveExists($(df+wname)) == 1) 
				wlist = AddListItem(wname,wlist,";",inf)
			endif
			
		endfor
	
	endfor

	return wlist

End // StimWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWaveName(prefix, config, waveNum)
	String prefix // wave prefix name ("DAC" or "TTL")
	Variable config // (-1) for none
	Variable waveNum // (-1) for none
	
	if (config >= 0)
		prefix += "_" + num2str(config)
	endif
	
	if (waveNum >= 0)
		prefix += "_" + num2str(waveNum)
	endif
	
	return prefix // e.g. "DAC_0_1"

End // StimWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimPrefix(wName)
	String wName
	
	String io = wName[0,2]
	
	strswitch(io)
		case "ADC":
		case "DAC":
		case "TTL":
			break
		default:
			return ""
	endswitch
	
	return io

End // StimPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function StimConfigNum(wName) // determine config num from wave name
	String wName
	
	Variable icnt, found1, found2, config = -1
	
	for (icnt = strlen(wName)-1; icnt > 0; icnt -= 1)
		if (StringMatch(wName[icnt,icnt],"_") == 1)
			if (found2 == 0)
				found2 = icnt
			else
				found1 = icnt
				break
			endif
		endif
	endfor
	
	if (found1 > 0)
		config = str2num(wName[found1+1,found2-1])
	elseif (found2 > 0)
		config = str2num(wName[found2+1, inf])
	endif
	
	return config

End // StimConfigNum

//****************************************************************
//****************************************************************
//****************************************************************

Function StimConfigVar(df, wName, what)
	String df
	String wName
	String what
	
	Variable config = StimConfigNum(wName)
	String dfName, io = StimPrefix(wName)
	
	dfName = df + io + what
	
	if (WaveExists($dfName) == 0)
		return -1
	endif
	
	if ((config < 0) || (config >= numpnts($dfName)))
		return -1
	endif
	
	Wave wTemp = $dfName
	
	return wTemp[config]
	
End // StimConfigVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimConfigStr(df, wName, what)
	String df
	String wName
	String what
	
	wName = GetPathName(wName, 0)
	
	Variable config = StimConfigNum(wName)
	String ioName, io = StimPrefix(wName)
	
	ioName = df + io + what
	
	if (WaveExists($ioName) == 0)
		return ""
	endif
	
	if ((config < 0) || (config >= numpnts($ioName)))
		return ""
	endif
	
	Wave /T wTemp = $ioName
	
	return wTemp[config]
	
End // StimConfigStr

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Sub-folder Stim Retrieve Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SubStimCall(fxn)
	String fxn
	
	String df = SubStimDF()
	
	if (strlen(df) == 0)
		DoAlert 0, "The current data folder contains no stimulus configuration."
		return 0
	endif
	
	strswitch(fxn)
	
		case "Details":
			return SubStimDetails()
	
		case "Pulse Table":
			return StimTableCall(SubStimDF(), "All")
			
		case "ADC Table":
			return StimConfigTable(SubStimDF(), "ADC", 0)
			
		case "DAC Table":
			return StimConfigTable(SubStimDF(), "DAC", 0)
			
		case "TTL Table":
			return StimConfigTable(SubStimDF(), "TTL", 0)
			
		case "Stim Waves":
			return SubStimWavesRetrieveCall()
			
	endswitch

End // SubStimCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SubStimDF()

	String sName = SubStimName("")

	if (strlen(sName) > 0)
		return GetDataFolder(1) + sName + ":"
	else
		return ""
	endif

End // SubStimDF

//****************************************************************
//****************************************************************
//****************************************************************

Function SubStimDetails()

	String acqStr, sdf = SubStimDF()
	
	Variable acqMode = NumVarOrDefault(sdf+"AcqMode", 0)
	
	NMHistory("\rStim: " + LastPathColon(sdf, 0))
	NMHistory("Acquisition Mode: " + StimAcqStr(acqMode))
	NMHistory("Waves/Groups: " + num2str(NumVarOrDefault(sdf+"NumStimWaves", 0)))
	NMHistory("Wave Length (ms): " + num2str(NumVarOrDefault(sdf+"WaveLength", 0)))
	NMHistory("Samples per Wave: " + num2str(NumVarOrDefault(sdf+"SamplesPerWave", Nan)))
	NMHistory("Sample Interval (ms): " + num2str(NumVarOrDefault(sdf+"SampleInterval", Nan)))
	NMHistory("Stim Interlude (ms): " + num2str(NumVarOrDefault(sdf+"InterStimTime", Nan)))
	//NMHistory("Stim Rate (ms): " + num2str(NumVarOrDefault(sdf+"StimRate", Nan)))
	
	NMHistory("Repetitions: " + num2str(NumVarOrDefault(sdf+"NumStimReps", Nan)))
	NMHistory("Rep Interlude (ms): " + num2str(NumVarOrDefault(sdf+"InterRepTime", Nan)))
	//NMHistory("Rep Rate (ms): " + num2str(NumVarOrDefault(sdf+"RepRate", Nan)))

End // SubStimDetails

//****************************************************************
//****************************************************************
//****************************************************************

Function SubStimWavesRetrieveCall()

	String ndf = NMDF(), sdf = SubStimDF()

	String plist = StimPrefixListAll(sdf)
	String pSelect = "", vlist = ""
	
	Variable retrieveAs = NumVarOrDefault(ndf+"StimRetrieveAs", 1)
	
	Prompt retrieveAs, "retrieve as:", popup "DAC/TTL pulse waves;channel waves;"
	
	if (ItemsInlist(plist) > 1)
		Prompt pSelect, "choose stim configuration:", popup "All;" + plist
		DoPrompt "Retrieve Stim Waves To Current Folder", pSelect, retrieveAs
	else
		DoPrompt "Retrieve Stim Waves To Current Folder", retrieveAs
		pSelect = plist
	endif
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	if (StringMatch(pSelect, "All") == 1)
		pSelect = plist
	endif
	
	SetNMvar(ndf+"StimRetrieveAs", retrieveAs)
	
	retrieveAs -= 1
	
	vlist = NMCmdList(pSelect, vlist)
	vlist = NMCmdNum(retrieveAs, vlist)
	NMCmdHistory("SubStimWavesRetrieve", vlist)
	
	SubStimWavesRetrieve(pSelect, retrieveAs)

End // SubStimWavesRetrieveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SubStimWavesRetrieve(plist, asChan) // retrieve sub folder stim waves
	String plist // prefix list
	Variable asChan // (0) no (1) yes
	
	Variable icnt
	String prefix, pname, dpName, ioName, ioUnits, wList
	String gName, gTitle
	
	if (WaveExists(yLabel) == 0)
		return 0
	endif
	
	String sdf = SubStimDF(), df = GetDataFolder(1)
	
	Variable chanNum = NumVarOrDefault("NumChannels", 0)
	
	String wPrefix = StrVarOrDefault("WavePrefix", "Record")
	
	Wave /T yLabel
	
	for (icnt = 0; icnt < ItemsInList(plist); icnt += 1)
		
		prefix = StringFromList(icnt, plist)
		pname = prefix + "_pulse"
		dpname = df + pname
		
		if (WaveExists($(sdf + pname)) == 1)
			Duplicate /O $(sdf + pname) $dpname // copy pulse waves to data folder
		endif
		
		wList = StimWavesMakeAll(sdf, df, pname, 1)
		
		KillWaves /Z $dpname // kill pulse wave
		
		ioName = StimConfigStr(sdf, pname, "name")
		ioUnits = StimConfigStr(sdf, pname, "units")
		
		if (asChan == 1)
		
			StimWavesToChannel(StimPrefix(pname), StimConfigNum(pname), chanNum)
			Redimension /N=(chanNum+1) yLabel
			
			yLabel[chanNum] = ioName + " (" + ioUnits + ")"
			
			chanNum += 1
		
		else
		
			gName = MainPrefix("") + NMFolderPrefix("") + pname
			gTitle = ioName + " : " + pname
			NMPlotWaves(gName, gTitle, "msec", ioUnits, wList)
			GraphRainbow(gName)
			NMPrefixAdd(pname[0,4])
		
		endif
		
	endfor
	
	if (asChan == 1)
		NMPrefixSelectSilent(wPrefix)
	endif

End // SubStimWavesRetrieve

//****************************************************************
//****************************************************************
//****************************************************************

Function StimWavesToChannel(outName, config, chanNum)
	String outName // DAC or TTL
	Variable config // output config number
	Variable chanNum
	
	Variable wcnt, icnt
	String prefix, wName, oName, olist

	Variable nWaves = NumVarOrDefault("NumWaves", 0)
	
	String wPrefix = StrVarOrDefault("WavePrefix", "Record")
	
	prefix = outName + "_" + num2str(config)
	
	olist = WaveList(prefix + "*", ";", "")
	
	do
	
		for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		
			oName = StringFromList(icnt, olist)
			wName = GetWaveName("default", chanNum, wcnt)
			
			Duplicate /O $oName $wName
			
			wcnt += 1
			
			if (wcnt == nWaves)
				break
			endif
		
		endfor
	
	while (wcnt < nWaves)
	
	for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		
		oName = StringFromList(icnt, olist)
		
		if (WaveExists($oName) == 1)
			KillWaves /Z $oName // kill remaining stim waves
		endif
			
	endfor

End // StimWavesToChannel

//****************************************************************
//****************************************************************
//****************************************************************