#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Board Configuration Functions
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
//	Began 24 March 2008
//	Last modified 24 March 2008
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardNumConfigs()

	return 16

End // ClampBoardNumConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampIOcheck(io)
	String io // "ADC", "DAC" or "TTL"
	
	strswitch(io)
		case "ADC":
		case "DAC":
		case "TTL":
			return io
	endswitch
	
	return ""
	
End // ClampIOcheck

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardConfigs()
	String fname = "Clamp"
	Variable numIO = ClampBoardNumConfigs()

	NMConfigTWave(fname, "ADCname", numIO, "", "ADC channel name")
	NMConfigTWave(fname, "ADCunits", numIO, "V", "ADC channel units")
	NMConfigWave(fname, "ADCboard", numIO, 0, "ADC board number")
	NMConfigWave(fname, "ADCchan", numIO, -1, "ADC board channel")
	NMConfigWave(fname, "ADCscale", numIO, 1, "ADC scale factor")
	NMConfigTWave(fname, "ADCmode", numIO, "", "ADC input mode")
	NMConfigWave(fname, "ADCgain", numIO, 1, "ADC channel gain")
	
	NMConfigTWave(fname, "DACname", numIO, "", "DAC channel name")
	NMConfigTWave(fname, "DACunits", numIO, "V", "DAC channel units")
	NMConfigWave(fname, "DACboard", numIO, 0, "DAC board number")
	NMConfigWave(fname, "DACchan", numIO, -1, "DAC board channel")
	NMConfigWave(fname, "DACscale", numIO, 1, "DAC scale factor")
	
	NMConfigTWave(fname, "TTLname", numIO, "", "TTL channel name")
	NMConfigTWave(fname, "TTLunits", numIO, "V", "TTL channel units")
	NMConfigWave(fname, "TTLboard", numIO, 0, "TTL board number")
	NMConfigWave(fname, "TTLchan", numIO, -1, "TTL board channel")
	NMConfigWave(fname, "TTLscale", numIO, 1, "TTL scale factor")
	
End // ClampBoardConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardWavesCheckAll()

	ClampBoardWavesCheck("ADC")
	ClampBoardWavesCheck("DAC")
	ClampBoardWavesCheck("TTL")

End // ClampBoardWavesCheckAll

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardWavesCheck(io)
	String io // "ADC", "DAC" or "TTL"
	
	Variable numIO = ClampBoardNumConfigs()
	String cdf = ClampDF()
	
	if (strlen(ClampIOcheck(io)) == 0)
		return -1
	endif
	
	if (WaveExists($cdf+io+"name") == 0)
	
		if (WaveExists($cdf+io+"name") == 0)
			CheckNMtwave(cdf+io+"name", numIO,"")		// config name
			CheckNMtwave(cdf+io+"units", numIO, "V")		// config units
			CheckNMwave(cdf+io+"board", numIO, 0)		// board number
			CheckNMwave(cdf+io+"chan", numIO, -1)		// board channel
			CheckNMwave(cdf+io+"scale", numIO, 1)		// scale factor
		endif
		
		if (StringMatch(io, "ADC") == 1)
			CheckNMtwave(cdf+io+"mode", numIO, "")		// input mode
			CheckNMwave(cdf+io+"gain", numIO, 1)			// channel gain
		endif
	
	endif
	
	ClampBoardWavesCheckValues(io)

End // ClampBoardWavesCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardWavesCheckValues(io)
	String io // "ADC", "DAC" or "TTL"
	
	Variable icnt
	String cdf = ClampDF()
	
	if (strlen(ClampIOcheck(io)) == 0)
		return -1
	endif
	
	if ((WaveExists($cdf+io+"name") == 0) || (WaveExists($cdf+io+"board") == 0))
		return -1
	endif
	
	Wave /T name = $cdf+io+"name"
	Wave /T units = $cdf+io+"units"
	Wave board = $cdf+io+"board"
	Wave chan = $cdf+io+"chan"
	Wave scale = $cdf+io+"scale"
	
	for (icnt = 0; icnt < numpnts(name); icnt += 1)
	
		if ((board[icnt] < 0) || (numtype(board[icnt]) > 0))
			board[icnt] = 0
		endif
	
		if ((chan[icnt] < 0) || (numtype(chan[icnt]) > 0))
			chan[icnt] = icnt
		endif
		
		if ((scale[icnt] == 0) || (numtype(scale[icnt]) > 0))
			scale[icnt] = 1
		endif
		
		if (strlen(name[icnt]) == 0)
			name[icnt] = io + num2str(icnt)
		endif
		
		if (strlen(units[icnt]) == 0)
			units[icnt] = "V"
		endif
	
	endfor
	
	if (StringMatch(io, "ADC") == 1)
	
		Wave gain = $cdf+io+"gain"
	
		for (icnt = 0; icnt < numpnts(gain); icnt += 1)
		
			if ((gain[icnt] == 0) || (numtype(gain[icnt]) > 0))
				gain[icnt] = 1
			endif
		
		endfor
	
	endif

End // ClampBoardWavesCheckValues

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardWavesRedimen(io, npnts)
	String io // "ADC", "DAC" or "TTL"
	Variable npnts // number of points
	
	String cdf = ClampDF()
	
	if (WaveExists($cdf+io+"chan") == 0)
		return 0
	endif
	
	//if (npnts == numpnts($cdf+io+"name"))
	//	return 0
	//endif
	
	npnts = max(npnts, ClampBoardNumConfigs())
	
	CheckNMtwave(cdf+io+"name", npnts, "")
	CheckNMtwave(cdf+io+"units", npnts, "V")
	CheckNMwave(cdf+io+"board", npnts, 0)
	CheckNMwave(cdf+io+"chan", npnts, -1)
	CheckNMwave(cdf+io+"scale", npnts, 1)
	
	if (StringMatch(io, "ADC") == 1)
		CheckNMtwave(cdf+io+"mode", npnts, "")
		CheckNMwave(cdf+io+"gain", npnts, 1)
	endif
	
	ClampBoardWavesCheckValues(io)
	
End // ClampBoardWavesRedimen

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardWavesReset(io, config)
	String io // "ADC", "DAC" or "TTL"
	Variable config // (-1) for all
	
	Variable icnt, ibgn, iend
	String cdf = ClampDF()
	
	if ((WaveExists($cdf+io+"name") == 0) || (WaveExists($cdf+io+"board") == 0))
		return -1
	endif
	
	Wave /T name = $cdf+io+"name"
	Wave /T units = $cdf+io+"units"
	Wave board = $cdf+io+"board"
	Wave chan = $cdf+io+"chan"
	Wave scale = $cdf+io+"scale"
	
	if (config < 0)
		ibgn = 0
		iend = numpnts(name) - 1
	else
		ibgn = config
		iend = config
	endif
	
	for (icnt = ibgn; icnt <= iend; icnt += 1)
	
		name[icnt] = io + num2str(icnt)
		units[icnt] = "V"
		board[icnt] = 0
		chan[icnt] = icnt
		scale[icnt] = 1
		
		if (StringMatch(io, "ADC") == 1)
		
			Wave /T mode = $cdf+io+"mode"
			Wave gain = $cdf+io+"gain"
			
			mode[icnt] = ""
			gain[icnt] = 1
			
		endif
	
	endfor
	
	if (config < 0)
		ClampBoardWavesRedimen(io, ClampBoardNumConfigs())
	endif
	
	return 0
	
End // ClampBoardWavesReset

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardConfigFind(io, configName)
	String io // "ADC", "DAC" or "TTL"
	String configName
	
	Variable icnt
	String cdf = ClampDF()
	
	if (strlen(ClampIOcheck(io)) == 0)
		return Nan
	endif
	
	if (WaveExists($cdf+io+"name") == 0)
		return Nan
	endif
	
	Wave /T name = $cdf+io+"name"
	
	for (icnt = 0; icnt < numpnts(name); icnt += 1)
		if (StringMatch(name[icnt], configName) == 1)
			return icnt
		endif
	endfor
	
	return Nan
	
End // ClampBoardConfigFind

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardNamesCheck(io)
	String io // "ADC", "DAC" or "TTL"
	
	Variable icnt, jcnt
	String cname, clist = "", cdf = ClampDF()
	
	if (strlen(ClampIOcheck(io)) == 0)
		return -1
	endif
	
	if (WaveExists($cdf+io+"name") == 0)
		return -1
	endif
	
	Wave /T name = $cdf+io+"name"
	
	for (icnt = 0; icnt < numpnts(name); icnt += 1)
	
		cname = name[icnt]
		
		for (jcnt = 0; jcnt < numpnts(name); jcnt += 1)
		
			if (icnt == jcnt)
				continue
			endif
			
			if ((StringMatch(cname, name[jcnt]) == 1) && (WhichListItem(cname, clist) < 0))
			
				name[jcnt] = cname + "_" + num2str(jcnt)
				clist = AddListItem(cname, clist, ";", inf)
				
				Print "Warning: found matching board config names. Changed " + io + " config #" + num2str(jcnt) + " \"" + cname +"\" to \"" + cname + "_" + num2str(jcnt) + "\"."
				//DoAlert 0, "Warning: found matching " + io + " config name \"" + cname +"\". Please enter unique names for " + io + " configs #" + num2str(icnt) + " and " + num2str(jcnt) + "."
			
			endif
			
		endfor
		
	endfor

End // ClampBoardNamesCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampBoardNameSet(io, config, nameStr)
	String io
	Variable config
	String nameStr
	
	Variable icnt, found
	String cdf = ClampDF()
	String wname = cdf + io + "name"
	
	if (WaveExists($wname) == 0)
		return ""
	endif
	
	if ((strlen(nameStr) == 0) || (config < 0))
		return ""
	endif
	
	Wave /T name = $wname
	
	if (config >= numpnts(name))
		ClampBoardWavesRedimen(io, config+1)
	endif
	
	for (icnt = 0; icnt < numpnts(name); icnt += 1)
				
		if (icnt == config)
			continue
		endif
		
		if (StringMatch(name[icnt], nameStr) == 1)
			found = 1
			break
		endif
		
	endfor
	
	if (found == 0)
		if (config < numpnts(name))
			name[config] = nameStr
			return nameStr
		endif
	else
		ClampError(io + " board config name \"" + nameStr + "\" is already in use.")
	endif
	
	return ""
	
End // ClampBoardNameSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampBoardUnitsSet(io, config, unitsStr)
	String io
	Variable config
	String unitsStr
	
	String cdf = ClampDF()
	String wname = cdf + io + "units"
	
	if (WaveExists($wname) == 0)
		return ""
	endif
	
	if ((strlen(unitsStr) == 0) || (config < 0))
		return ""
	endif
	
	Wave /T units = $wname
	
	if (config >= numpnts(units))
		ClampBoardWavesRedimen(io, config+1)
	endif
	
	if (config < numpnts(units))
		units[config] = unitsStr
		return unitsStr
	endif
	
	return ""
	
End // ClampBoardUnitsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampBoardModeSet(config, modeStr)
	Variable config
	String modeStr
	
	String cdf = ClampDF()
	String io = "ADC"
	String wname = cdf + io + "mode"
	
	if (WaveExists($wname) == 0)
		return ""
	endif
	
	if (config < 0)
		return ""
	endif
	
	Wave /T mode = $wname
	
	if (config >= numpnts(mode))
		ClampBoardWavesRedimen(io, config+1)
	endif
	
	if (config < numpnts(mode))
		mode[config] = modeStr
		return modeStr
	endif
	
	return ""
	
End // ClampBoardModeSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampBoardTgainFind(board, chan)
	Variable board, chan
	
	Variable icnt, tboard
	String modeStr
	
	String cdf = ClampDF()
	String io = "ADC"
	String wname = cdf + io + "mode"
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
	if (WaveExists($wname) == 0)
		return ""
	endif
	
	Wave /T wtemp = $wname
	
	if (board == 0)
		board = driver
	endif
	
	for (icnt = 0; icnt < numpnts(wtemp); icnt += 1)
		
		modeStr = wtemp[icnt]
		
		if (StringMatch(modeStr[0, 5], "Tgain=") == 0)
			continue
		endif
		
		tboard = ClampTgainBoard(modeStr)
		
		if (tboard == 0)
			tboard = driver
		endif
		
		if ((tboard == board) && (ClampTgainChan(modeStr) == chan))
			return WaveStrOrDefault(cdf + io + "name", icnt, "")
		endif
		
	endfor
	
	return ""
	
End // ClampBoardTgainFind

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardBoardSet(io, config, boardNum)
	String io
	Variable config
	Variable boardNum
	
	String cdf = ClampDF()
	String wname = cdf + io + "board"
	
	if (WaveExists($wname) == 0)
		return Nan
	endif
	
	if ((numtype(boardNum) > 0) || (boardNum < 0) || (config < 0))
		return Nan
	endif
	
	Wave board = $wname
	
	if (config >= numpnts(board))
		ClampBoardWavesRedimen(io, config+1)
	endif
	
	if (config < numpnts(board))
		board[config] = boardNum
		return boardNum
	endif
	
	return Nan
	
End // ClampBoardBoardSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardChanSet(io, config, chanNum)
	String io
	Variable config
	Variable chanNum
	
	String cdf = ClampDF()
	String wname = cdf + io + "chan"
	
	if (WaveExists($wname) == 0)
		return Nan
	endif
	
	if ((numtype(chanNum) > 0) || (chanNum < 0) || (config < 0))
		return Nan
	endif
	
	Wave chan = $wname
	
	if (config >= numpnts(chan))
		ClampBoardWavesRedimen(io, config+1)
	endif
	
	if (config < numpnts(chan))
		chan[config] = chanNum
		return chanNum
	endif
	
	return Nan
	
End // ClampBoardChanSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardScaleSet(io, config, scaleNum)
	String io
	Variable config
	Variable scaleNum
	
	String cdf = ClampDF()
	String wname = cdf + io + "scale"
	
	if (WaveExists($wname) == 0)
		return Nan
	endif
	
	if ((numtype(scaleNum) > 0) || (scaleNum <= 0) || (config < 0))
		return Nan
	endif
	
	Wave scale = $wname
	
	if (config >= numpnts(scale))
		ClampBoardWavesRedimen(io, config+1)
	endif
	
	if (config < numpnts(scale))
		scale[config] = scaleNum
		return scaleNum
	endif
	
	return Nan
	
End // ClampBoardScaleSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardConfigsFromStimsAll()
	String slist = StimList()

	ClampBoardWavesCheckAll()

	ClampBoardConfigsFromStims("ADC", slist)
	ClampBoardConfigsFromStims("DAC", slist)
	ClampBoardConfigsFromStims("TTL", slist)

End // ClampBoardConfigsFromStimsAll

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardConfigsFromStims(io, slist)
	String io // "ADC", "DAC" or "TTL"
	String slist // stimulus list
	
	Variable bcnt, ccnt, icnt, config, modeNum
	String cstr, clist, cdf = ClampDF()
	
	if (strlen(ClampIOcheck(io)) == 0)
		return -1
	endif
	
	if (WaveExists($cdf+io+"name") == 0)
		return -1
	endif
	
	ClampBoardWavesReset(io, -1)
	
	Wave /T name = $cdf+io+"name"
	Wave /T units = $cdf+io+"units"
	
	Wave scale = $cdf+io+"scale"
	Wave board = $cdf+io+"board"
	Wave chan = $cdf+io+"chan"
	
	if (StringMatch(io, "ADC") == 1)
		Wave /T mode = $cdf+io+"mode"
		Wave gain = $cdf+io+"gain"
	endif
	
	config = 0
	
	for (bcnt = 0; bcnt < 10; bcnt += 1) // loop thru boards
	
		for (ccnt = 0; ccnt < 50; ccnt += 1) // loop thru channels

			clist = ClampBoardConfigsFromStimsList(io, slist, bcnt, ccnt)
			
			for (icnt = 0; icnt < ItemsInList(clist); icnt += 1)
			
				if (config >= numpnts(name))
				
					Redimension /N=(config+1) name, units, scale, board, chan
					
					if (StringMatch(io, "ADC") == 1)
						Redimension /N=(config+1) mode, gain
					endif
					
				endif
				
				cstr = StringFromList(icnt, clist)
				name[config] = StringFromList(0, cstr, ",")
				units[config] = StringFromList(1, cstr, ",")
				scale[config] = str2num(StringFromList(2, cstr, ","))
				board[config] = bcnt
				chan[config] = ccnt
				
				if (StringMatch(io, "ADC") == 1)
					
					modeNum = str2num(StringFromList(5, cstr, ","))
					
					if ((numtype(modeNum) == 0) && (modeNum > 0))
						mode[config] = "PreSamp=" + num2str(modeNum)
					else
						mode[config] = ""
					endif
					
					gain[config] = str2num(StringFromList(6, cstr, ","))
					
				endif
				
				config += 1
				
			endfor
			
		endfor
		
	endfor
			
	ClampBoardNamesCheck(io)
	
End // ClampBoardConfigsFromStims

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampBoardConfigsFromStimsList(io, slist, boardNum, chanNum)
	String io // "ADC", "DAC" or "TTL"
	String slist // stimulus list
	Variable boardNum, chanNum
	
	Variable scnt, ccnt
	String sname, cname, sdf, cc, dc, clist = "", clist2 = ""
	
	if (strlen(ClampIOcheck(io)) == 0)
		return ""
	endif

	for (scnt = 0; scnt < ItemsInLIst(slist); scnt += 1)
	
		sname = StringFromList(scnt, slist)
		
		if (IsStimFolder(StimParent(), sname) == 0)
			continue
		endif
		
		sdf = StimParent() + sname + ":"
		
		if (WaveExists($sdf+io+"name") == 0)
			continue
		endif
		
		Wave /T name = $sdf+io+"name"
		Wave /T units = $sdf+io+"units"
		
		Wave scale = $sdf+io+"scale"
		Wave board = $sdf+io+"board"
		Wave chan = $sdf+io+"chan"
		
		if (StringMatch(io, "ADC") == 1)
			Wave mode = $sdf+io+"mode"
			Wave gain = $sdf+io+"gain"
		endif
		
		for (ccnt = 0; ccnt < numpnts(chan); ccnt += 1)
		
			if ((board[ccnt] == boardNum) && (chan[ccnt] == chanNum))
			
				dc = io + num2str(chanNum) + ",V," + num2str(1) + "," + num2str(0) + "," + num2str(chanNum) + ","  // default config
				
				if (StringMatch(io, "ADC") == 1)
					dc += num2str(0) + "," + num2str(1) + ","
				endif
				
				cc = name[ccnt] + "," + units[ccnt] + "," + num2str(scale[ccnt]) + "," + num2str(boardNum) + "," + num2str(chanNum) + "," // user config
				
				if (StringMatch(io, "ADC") == 1)
					cc += num2str(mode[ccnt]) + "," + num2str(gain[ccnt]) + ","
				endif
				
				if (StringMatch(cc, dc) == 0)
					clist = AddListItem(cc, clist, ";", inf)
				endif
				
			endif
		
		endfor
		
	endfor
	
	for (ccnt = 0; ccnt < ItemsInList(clist); ccnt += 1)
		cc = StringFromList(ccnt, clist)
		if (WhichListItemLax(cc, clist2, ";") < 0)
			clist2 = AddListItem(cc, clist2, ";", inf) // only unique configs
		endif
	endfor
	
	return clist2
	
End // ClampBoardConfigsFromStimsList

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardTables(hook)
	Variable hook // (0) no update (1) updateNM

	ClampBoardTable("ADC", "", hook)
	ClampBoardTable("DAC", "", hook)
	ClampBoardTable("TTL", "", hook)

End // ClampBoardTables

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardTable(io, wlist, hook)
	String io // "ADC", "DAC" or "TTL"
	String wlist // wave name list ("") for all
	Variable hook // (0) no update (1) updateNM
	
	Variable icnt
	String wName, tName, title, cdf = ClampDF()
	
	if (strlen(ClampIOcheck(io)) == 0)
		return Nan
	endif
	
	tName = CheckGraphName(io + "_BoardConfigs")
	
	if (WinType(tName) == 2)
		DoWindow /F $tName
		return 0
	endif
	
	title = "Global " + io + " Input Configurations"
	
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
		SetWindow $tName hook=ClampBoardTableHook
	endif
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
	
		wName = cdf + io + StringFromList(icnt,wlist)
		
		if (WaveExists($wName) == 1)
			AppendToTable $wName
		endif
	
	endfor

End // ClampBoardTable

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardTableHook(infoStr)
	string infoStr
	
	string event= StringByKey("EVENT",infoStr)
	string win= StringByKey("WINDOW",infoStr)
	
	strswitch(event)
		case "deactivate":
		case "kill":
			UpdateNM(0)
	endswitch

End // ClampBoardTableHook

//****************************************************************
//****************************************************************
//****************************************************************