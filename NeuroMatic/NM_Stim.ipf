#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Stim Protocol Functions
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
//
//	Stim Directory Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimParent() // directory of stim folders

	return "root:Stims:"
	
End // StimParent

//****************************************************************
//****************************************************************
//****************************************************************

Function StimParentCheckDF()

	if (DataFolderExists("root:Stims:") == 0)
		NewDataFolder root:Stims
	endif

End // StimParentCheckDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimDF() // full-path name of current stim folder

	String cdf = PackDF("Clamp")
	String sdf = StimParent() + StrVarOrDefault(cdf+"CurrentStim", "") + ":"
	
	if (DataFolderExists(sdf) == 1)
		return sdf
	endif

	return "" // error
	
End // StimDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckStimDF(sdf)
	String sdf
	
	if (strlen(sdf) == 0)
		return StimDF() // return current stim
	endif
	
	if (IsNMFolder(sdf, "NMStim") == 1)
		return LastPathColon(sdf, 1) // OK
	endif
	
	return "" // error
	
End // CheckStimDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimBoardDF(sdf) // sub-folder where board configs are saved
	String sdf
	
	String bdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif

	return sdf + "BoardConfigs:"

End // StimBoardDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimList()

	return NMFolderList(StimParent(),"NMStim")

End // StimList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimAcqModeList()

	return "continuous;episodic;epic precise;triggered;"
	
End // StimAcqModeList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimAcqModeStr(acqModeNum)
	Variable acqModeNum
	
	switch(acqModeNum)
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
	
End // StimAcqModeStr

//****************************************************************
//****************************************************************
//****************************************************************

Function StimIntervalGet(sdf, boardNum)
	String sdf // stim data folder path
	Variable boardNum
	
	Variable sampleInterval
	String varName
	
	sdf = CheckStimDF(sdf)
	
	sampleInterval = NumVarOrDefault(sdf+"SampleInterval", 1) // default driver value

	varName = sdf + "SampleInterval_" + num2str(boardNum) // board-specific sample interval
	
	if (exists(varName) == 2)
		sampleInterval = NumVarOrDefault(varName, sampleInterval)
	endif
	
	return StimIntervalCheck(sampleInterval)
		
End // StimIntervalGet

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
//
//	Stim Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWavesCheck(sdf, forceUpdate)
	String sdf // stim data folder
	Variable forceUpdate

	Variable icnt, config, npnts, ORflag, new
	String io, wName, wPrefix, klist, plist, ulist, wlist = ""
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	plist = StimPrefixListAll(sdf)
	
	Variable numWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	
	for (icnt = 0; icnt < ItemsInList(plist); icnt += 1)
	
		wPrefix = StringFromList(icnt, plist)
		io = StimPrefix(wPrefix)
		config = StimConfigNum(wPrefix)
		
		if (StringMatch(io, "TTL") == 1)
			ORflag = 1
		else
			ORflag = 0
		endif
		
		wlist = WaveListFolder(sdf, wPrefix + "*", ";", "")
		ulist = WaveListFolder(sdf, "u"+wPrefix + "*", ";", "") // unscaled waves for display
		
		if (ItemsInLIst(ulist) == 0)
			ulist = WaveListFolder(sdf, "My"+wPrefix + "*", ";", "") // try "My" waves
		endif
		
		wlist = RemoveFromList(wPrefix + "_pulse", wlist)
		
		if ((forceUpdate) || (ItemsInList(wlist) < numWaves) || (ItemsInList(ulist) < numWaves))
			wlist += StimWavesMake(sdf, io, config, ORflag)
			new = 1
		endif
		
	endfor
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
	
		wName = StringFromList(icnt, wlist)
		
		if (WaveExists($sdf+wName) == 0)
			continue
		endif
		
		Wave wtemp = $sdf+wName
		
		npnts = numpnts(wtemp)
		
		wtemp[npnts-1] = 0 // make sure last points are set to zero
		wtemp[npnts-2] = 0
		
	endfor
	
	if (new == 1)
		klist = WaveListFolder(sdf, "ITCoutWave*", ";", "")
		for (icnt = 0; icnt < ItemsInList(klist); icnt += 1)
			KillWaves /Z $StringFromList(icnt, klist)
		endfor
	endif
	
	return wlist

End // StimWavesCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWavesMake(sdf, io, config, ORflag)
	String sdf // stim data folder
	String io // "DAC" or "TTL"
	Variable config // config number
	Variable ORflag // (0) add pulses (1) OR pulses
	
	Variable wcnt, dt, scale, alert
	String wPrefix, wname, wlist = "", bdf = StimBoardDF(sdf)
	
	Variable numWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable wLength = NumVarOrDefault(sdf+"WaveLength", 0)
	Variable pgOff = NumVarOrDefault(sdf+"PulseGenOff", 0)
	
	if (DataFolderExists(sdf) == 0)
		return ""
	endif
	
	if ((StringMatch(io, "DAC") == 0) && (StringMatch(io, "TTL") == 0))
		return ""
	endif
	
	if (WaveExists($bdf+io+"board") == 1) // new board configs
		
		Wave OUTboard = $bdf+io+"board"
		Wave OUTscale = $bdf+io+"scale"
		
	elseif (WaveExists($sdf+io+"board") == 1) // old board configs
	
		Wave OUTboard = $sdf+io+"board"
		Wave OUTscale = $sdf+io+"scale"
	
	else
	
		return ""
	
	endif
	
	scale = 1 / OUTscale[config]
	
	dt = StimIntervalGet(sdf, OUTboard[config])
	
	wPrefix = StimWaveName(io, config, -1)
	
	PulseWavesKill(sdf, wPrefix)
	PulseWavesKill(sdf, "u"+wPrefix)
	
	wlist = PulseWavesMake(sdf, wPrefix, numWaves, floor(wLength/dt), dt, scale, ORflag)
		
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
	
		wname = StringFromList(wcnt, wlist)
		
		if (WaveExists($sdf+wname) == 1) // create display wave
		
			Duplicate /O $(sdf+wname) $(sdf+"u"+wname)
			
			Wave wtemp = $sdf+"u"+wname
			
			wtemp /= scale // remove scaling
		
		endif
		
	endfor
	
	if (pgOff == 1) // use "My" waves, such as MyDAC_0_0, MyDac_0_1, etc.
	
		for (wcnt = 0; wcnt < numWaves; wcnt += 1)
		
			wname = wPrefix + "_" + num2str(wcnt)
			
			if (WaveExists($sdf+"My"+wname) == 1)
			
				//if ((deltax($sdf+"My"+wname) != dt) && (alert == 0))
					//DoAlert 0, "Error: encountered incorrect sample interval for wave: " + sdf + "My" + wname + " : " + num2str(deltax($sdf+"My"+wname)) + " , " + num2str(dt)
 					//alert = 1
					//continue
				//endif
			
				Duplicate /O $(sdf+"My"+wname) $(sdf+wname) // copy existing "My" wave
				
				wlist = AddListItem(wname, wlist, ";", inf)
				
				Wave wtemp = $sdf+wname
				
				wtemp *= scale
				
				KillWaves /Z $sdf+"u"+wname
				
				//print "Updated " + wname
	
			endif
			
		endfor
		
	endif
	
	Execute /Z "ITCkillWaves()"
	
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
	
	Variable pgOff = NumVarOrDefault(sdf+"PulseGenOff", 0)
	
	if (pgOff == 1)
		//DoAlert 0, "Pulse Generator was turned off for this stimulus."
		//return -1
	endif
	
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
			StimTable(sdf, sdf+pName, sdf, prefix)
		endfor

	else
	
		prefix = pName[0,0] + pName[4,4] + "_"
		StimTable(sdf, sdf+pName, sdf, prefix)
		
	endif

End // StimTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimTable(sdf, pName, df, prefix)
	String sdf // stim data folder
	String pName // pulse wave name (full-path)
	String df // data folder where pulse waves are located
	String prefix // prefix of table waves
	
	String tName = prefix + "StimTable"
	String wname = df + prefix + "Shape"
	
	String ioName = StimConfigStr(sdf, pName, "name")
		
	String title = GetPathName(pName,0) + " : " + ioName
	
	if (WaveExists($pname) == 0)
		return ""
	endif
	
	StimTableWavesUpdate(pName, df, prefix)
	
	DoWindow /K $tName
	
	Edit /K=1/N=$tName/W=(0,0,0,0) $(wname) as title
	
	SetCascadeXY(tName)
	
	AppendToTable $df+prefix+"WaveN"
	AppendToTable $df+prefix+"ND"
	AppendToTable $df+prefix+"Amp"
	AppendToTable $df+prefix+"AD"
	AppendToTable $df+prefix+"Onset"
	AppendToTable $df+prefix+"OD"
	AppendToTable $df+prefix+"Width"
	AppendToTable $df+prefix+"WD"
	AppendToTable $df+prefix+"Tau2"
	AppendToTable $df+prefix+"TD"
	
	Execute /Z "ModifyTable title(Point)= \"Config\""
	
	Execute /Z "ModifyTable width=55"
	Execute /Z "ModifyTable width("+df+prefix+"ND)=40"
	Execute /Z "ModifyTable width("+df+prefix+"OD)=40"
	Execute /Z "ModifyTable width("+df+prefix+"AD)=40"
	Execute /Z "ModifyTable width("+df+prefix+"WD)=40"
	Execute /Z "ModifyTable width("+df+prefix+"TD)=40"
	
	return tName

End // StimTable

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStimTableWaves(sdf, prefix, npnts)
	String sdf // where table waves are located
	String prefix // prefix of table waves
	Variable npnts // number of points
	
	CheckNMwave(sdf+prefix+"Shape", npnts, Nan)
	CheckNMwave(sdf+prefix+"WaveN", npnts, Nan)
	CheckNMwave(sdf+prefix+"ND", npnts, Nan)
	CheckNMwave(sdf+prefix+"Onset", npnts, Nan)
	CheckNMwave(sdf+prefix+"OD", npnts, Nan)
	CheckNMwave(sdf+prefix+"Amp", npnts, Nan)
	CheckNMwave(sdf+prefix+"AD", npnts, Nan)
	CheckNMwave(sdf+prefix+"Width", npnts, Nan)
	CheckNMwave(sdf+prefix+"WD", npnts, Nan)
	CheckNMwave(sdf+prefix+"Tau2", npnts, Nan)
	CheckNMwave(sdf+prefix+"TD", npnts, Nan)

End // CheckStimTableWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTableWavesUpdate(pName, sdf, prefix)
	String pName // pulse wave name (full-path)
	String sdf // where waves are located
	String prefix // prefix of table waves
	
	Variable icnt, index, ilmt, pNumVar = 12

	if (WaveExists($pname) == 0)
		return 0
	endif
	
	Wave Pulse = $pname
	
	ilmt = numpnts(Pulse) / pNumVar
	
	CheckStimTableWaves(sdf, prefix, ilmt)
	
	Wave Shape = $sdf+prefix+"Shape"
	Wave WaveN = $sdf+prefix+"WaveN"
	Wave WaveND = $sdf+prefix+"ND"
	Wave Onset = $sdf+prefix+"Onset"
	Wave OnsetD = $sdf+prefix+"OD"
	Wave Amp = $sdf+prefix+"Amp"
	Wave AmpD = $sdf+prefix+"AD"
	Wave Width = $sdf+prefix+"Width"
	Wave WidthD = $sdf+prefix+"WD"
	Wave Tau2 = $sdf+prefix+"Tau2"
	Wave Tau2D = $sdf+prefix+"TD"
	
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

Function StimBoardConfigTable(sdf, io, wlist, hook)
	String sdf // stim data folder path
	String io // "ADC", "DAC" or "TTL"
	String wlist // wave name list ("") for all
	Variable hook // (0) no update (1) updateNM
	
	Variable icnt
	String wName, tName, title, bdf = StimBoardDF(sdf)
	
	String stim = GetPathName(sdf, 0)
	
	tName = CheckGraphName(io + "_" + stim)
	
	if (WinType(tName) == 2)
		DoWindow /F $tName
		return 0
	endif
	
	title = io + " Input Configs : " + stim
	
	if (ItemsInList(wlist) == 0)
	
		wlist = "name;units;board;chan;scale;"
		
		if (StringMatch(io, "ADC") == 1)
			wlist = AddListItem("mode;gain;", wlist, ";", inf)
		endif
		
	endif
	
	DoWindow /K $tName
	Edit /N=$tName/W=(0,0,0,0)/K=1 as title[0,30]
	SetCascadeXY(tName)
	Execute "ModifyTable title(Point)= \"Config\""
	
	if (hook == 1)
		SetWindow $tName
	endif
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
	
		if (DataFolderExists(bdf) == 1)
			wName = bdf + io + StringFromList(icnt,wlist)
		else
			wName = sdf + io + StringFromList(icnt,wlist)
		endif
		
		if (WaveExists($wName) == 1)
			AppendToTable $wName
		endif
	
	endfor

End // StimBoardConfigTable

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

Function /S StimPrefixList(sdf, io)
	String sdf // stim data folder
	String io // "DAC" or "TTL"
	
	Variable icnt
	String wName, wlist = "", bdf = StimBoardDF(sdf)
	
	if ((StringMatch(io, "DAC") == 0) && (StringMatch(io, "TTL") == 0))
		return ""
	endif
	
	wname = bdf + io + "name"
	
	if (WaveExists($wname) == 1)
	
		Wave /T name = $wname // new stim board config wave
		
		for (icnt = 0; icnt < numpnts(name); icnt += 1)
			if (strlen(name[icnt]) > 0)
				wlist = AddListItem(io + "_" + num2str(icnt), wlist, ";", inf)
			endif
		endfor
		
		return wlist
	
	endif
	
	wname = sdf + io + "on"

	if (WaveExists($wname) == 1)
	
		Wave wTemp = $wname // old stim board config wave
	
		for (icnt = 0; icnt < numpnts(wTemp); icnt += 1)
			if (wTemp[icnt] == 1)
				wlist = AddListItem(io + "_" + num2str(icnt), wlist, ";", inf)
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

Function /S StimNameList(sdf, io)
	String sdf // stim data folder
	String io // "DAC" or "TTL"
	
	Variable icnt
	String txt, wname, wname2, wlist = "", bdf = StimBoardDF(sdf)
	
	if ((StringMatch(io, "DAC") == 0) && (StringMatch(io, "TTL") == 0))
		return ""
	endif
	
	wname = bdf + io + "name"
	
	if (WaveExists($wname) == 1)
	
		Wave /T name = $wname // new stim board config wave
		
		for (icnt = 0; icnt < numpnts(name); icnt += 1)
			if (strlen(name[icnt]) > 0)
				txt = io + "_" + num2str(icnt) + " : " + name[icnt]
				wlist = AddListItem(txt, wlist, ";", inf)
			endif
		endfor
		
		return wlist
		
	endif
	
	wname = sdf + io + "on"
	wname2 = sdf + io + "name"
	
	if ((WaveExists($wname) == 1) && (WaveExists($wname2) == 1))
	
		Wave wTemp = $wname
		Wave /T wTemp2 = $wname2
	
		for (icnt = 0; icnt < numpnts(wTemp); icnt += 1)
			if (wTemp[icnt] == 1)
				txt = io + "_" + num2str(icnt) + " : " + wTemp2[icnt]
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

Function /S StimWaveList(sdf, prefixList, waveNum)
	String sdf // stim data folder
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
			
			if (WaveExists($sdf+wname) == 1) 
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

Function /S StimConfigStr(sdf, wName, what)
	String sdf
	String wName
	String what
	
	Variable config
	String ioName, io, df = sdf, bdf = StimBoardDF(sdf)
	
	if (DataFolderExists(bdf) == 1)
		df = bdf
	endif
	
	wName = GetPathName(wName, 0)
	
	config = StimConfigNum(wName)
	io = StimPrefix(wName)
	
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
			return StimBoardConfigTable(SubStimDF(), "ADC", "", 0)
			
		case "DAC Table":
			return StimBoardConfigTable(SubStimDF(), "DAC", "", 0)
			
		case "TTL Table":
			return StimBoardConfigTable(SubStimDF(), "TTL", "", 0)
			
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
	NMHistory("Acquisition Mode: " + StimAcqModeStr(acqMode))
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
	Variable asChan // as channel waves (0) no (1) yes
	
	Variable icnt, wcnt
	String prefix, newprefix, pname, dpName, ioName, ioUnits, wname, wList = ""
	String gName, gTitle
	
	if (WaveExists(yLabel) == 0)
		return 0
	endif
	
	String sdf = SubStimDF(), bdf = StimBoardDF(sdf), df = GetDataFolder(1)
	
	Variable chanNum = NumVarOrDefault("NumChannels", 0)
	
	String wPrefix = StrVarOrDefault("WavePrefix", "Record")
	
	Variable pgOff = NumVarOrDefault(sdf+"PulseGenOff", 0)
	
	Wave /T yLabel
	
	for (icnt = 0; icnt < ItemsInList(plist); icnt += 1)
		
		prefix = StringFromList(icnt, plist)
		pname = prefix + "_pulse"
		dpname = df + pname
		
		StimWavesCheck(sdf, 0)
		
		wlist = ""
		
		if (pgOff == 1)
			newPrefix = "My" + prefix
			wlist = WaveListFolder(sdf, newPrefix + "*", ";", "") // user "My" waves
		endif
		
		if (ItemsInList(wlist) == 0)
			newPrefix = "u" + prefix
			wlist = WaveListFolder(sdf, newPrefix + "*", ";", "") // unscaled waves for display
		endif
		
		for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
			wname = StringFromList(wcnt, wlist)
			Duplicate /O $(sdf + wname) $wname
		endfor
		
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
			NMPlotWaves(gName, gTitle, "msec", ioUnits, "", wList)
			GraphRainbow(gName)
			NMPrefixAdd(newPrefix)
		
		endif
		
	endfor
	
	if (asChan == 1)
		NMPrefixSelectSilent(wPrefix)
	endif

End // SubStimWavesRetrieve

//****************************************************************
//****************************************************************
//****************************************************************

Function StimWavesToChannel(io, config, chanNum)
	String io // DAC or TTL
	Variable config // output config number
	Variable chanNum
	
	Variable wcnt, icnt
	String prefix, wName, oName, olist

	Variable nWaves = NumVarOrDefault("NumWaves", 0)
	
	String wPrefix = StrVarOrDefault("WavePrefix", "Record")
	
	prefix = io + "_" + num2str(config)
	
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