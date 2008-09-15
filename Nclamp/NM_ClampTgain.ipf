#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Telegraph Gain Functions
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
//	Last modified 1 April 2008
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTgainInstrumentList()

	return "Axopatch200B;Dagan3900A;"

End // ClampTgainInstrumentList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTgainConfigNameList()

	Variable icnt
	String nlist = "", cdf = ClampDF()
	
	String tGainList = StrVarOrDefault(cdf+"TGainList", "")
	
	for (icnt = 0; icnt < ItemsInList(tGainList); icnt += 1)
		nlist = AddListItem("Tgain_" + num2str(icnt), nlist, ";", inf)
	endfor
	
	return nlist

End // ClampTgainConfigNameList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTgainModeStr(board, chan, instrument)
	Variable board
	Variable chan
	String instrument
	
	if ((numtype(board) > 0) || (board < 0))
		board = 0
	endif
	
	if ((numtype(chan) > 0) || (chan < 0))
		chan = Nan
	endif
	
	return "Tgain=B" + num2str(board) + "_C" + num2str(chan) + "_" + instrument
	
End // ClampTgainModeStr

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainModeCheck(modeStr)
	String modeStr
	
	return StringMatch(modeStr[0, 5], "Tgain=")
	
End // ClampTgainModeCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainBoard(modeStr)
	String modeStr
	
	if (ClampTgainModeCheck(modeStr) == 0)
		return 0
	endif
	
	if (StringMatch(modeStr[6, 6], "B") == 1)
		return str2num(modeStr[7, 7])
	endif
	
	return 0
	
End // ClampTgainBoard

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainChan(modeStr)
	String modeStr
	
	Variable icnt, jcnt
	
	if (ClampTgainModeCheck(modeStr) == 0)
		return Nan
	endif
	
	if (StringMatch(modeStr[6, 6], "B") == 1)
	
		icnt = strsearch(modeStr, "_C", 7)
		
		if ((icnt < 0) || (icnt > 9))
			return Nan
		endif
		
		icnt += 2
		
		jcnt = strsearch(modeStr, "_", icnt)
		
		if ((jcnt < 0) || (jcnt > icnt + 2))
			return Nan
		endif
		
		return str2num(modeStr[icnt, jcnt - 1])
	
	endif
	
	return Nan
	
End // ClampTgainChan

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTgainInstrument(modeStr)
	String modeStr
	
	Variable icnt
	
	if (ClampTgainModeCheck(modeStr) == 0)
		return ""
	endif
	
	icnt = strsearch(modeStr, "_C", 7)
	
	if (icnt < 0)
		return ""
	endif
		
	icnt = strsearch(modeStr, "_", icnt + 2)
		
	if (icnt < 0)
		return ""
	endif
		
	return modeStr[icnt + 1, inf]
	
End // ClampTgainInstrument

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTgainInstrumentFind(config)
	Variable config
	
	String modeStr
	
	String bdf = StimBoardDF("")

	if (WaveExists($bdf+"ADCmode") == 1)
	
		Wave /T ADCmode = $bdf+"ADCmode"
		
		modeStr = ADCmode[config]
		
		if (ClampTgainModeCheck(modeStr) == 1)
			return ClampTgainInstrument(modeStr)
		endif
		
	endif
	
	return ""

End // ClampTgainInstrumentFind

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainConfigEditOld(config)
	Variable config
	
	Variable gchan, achan, icnt, kill = 1
	String item, instr, newList = "", cdf = ClampDF()
	
	String tGainList = StrVarOrDefault(cdf+"TGainList", "")
	
	item = StringFromList(config, tGainList)
	
	if (strlen(item) == 0)
		return -1
	endif
	
	gchan = str2num(StringFromList(0, item, ","))
	achan = str2num(StringFromList(1, item, ","))
	instr = StringFromList(2, item, ",")
	
	Prompt gchan, "ADC input channel to read telegraph gain:"
	Prompt achan, "ADC input channel to scale:"
	Prompt instr, "telegraphed instrument:", popup "Axopatch200B;Dagan3900A;"
	Prompt kill, "or delete this telegraph configuration:", popup "no;yes;"
	
	DoPrompt "ADC Telegraph Gain Config " + num2str(config), gchan, achan, instr, kill
		
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	for (icnt = 0; icnt < ItemsInList(tGainList); icnt += 1)
		
		if (icnt == config)
		
			if (kill == 2)
				continue
			endif
			
			item = num2str(gchan) + "," + num2str(achan) + "," + instr
			
		else
		
			item = StringFromList(icnt, tGainList)
			
		endif
		
		newList = AddListItem(item, newList, ";", inf)
	
	endfor
	
	SetNMstr(cdf+"TGainList", newList)

End // ClampTgainConfigEditOld

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainValue(df, config, waveNum)
	String df // data folder
	Variable config
	Variable waveNum
	
	Variable npnts
	
	String wname = df + "CT_Tgain" + num2str(config) // telegraph gain wave
	
	if (WaveExists($wname) == 0)
		return -1
	endif
	
	Wave temp = $wname

	if (waveNum == -1) // return avg of wave
		temp = Zero2Nan(temp) // remove possible 0's
		WaveStats /Q temp
		return V_avg
	else
		return temp[waveNum]
	endif

End // ClampTgainValue

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainConvert() // convert final tgain values to scale values
	Variable ocnt, icnt, tvalue, npnts, chan, gchan, achan
	String olist, oname, item
	
	String instr, cdf = ClampDF()
	
	String tGainList = StrVarOrDefault(cdf+"TGainList", "")
	String instrOld = StrVarOrDefault(cdf+"ClampInstrument", "")
	
	olist = WaveList("CT_Tgain*", ";", "") // created by NIDAQ code
	
	if (ItemsInList(tGainList) <= 0)
		return 0
	endif
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
	
		oname = StringFromList(ocnt, olist)
		chan = str2num(oname[8,inf])
		
		instr = ""
		
		for (icnt = 0; icnt < ItemsInList(tGainList); icnt += 1)
		
			item = StringFromList(icnt, tGainList)
			gChan = str2num(StringFromList(0, item, ",")) // corresponding telegraph ADC input channel
			aChan = str2num(StringFromList(1, item, ",")) // ADC input channel
			
			if (chan == aChan)
				instr = StringFromList(2, item, ",")
			endif
			
		endfor
		
		if (strlen(instr) == 0)
			instr = instrOld
		endif
		
		Wave wtemp = $oname
		
		npnts = numpnts(wtemp)
		
		for (icnt = 0; icnt < npnts; icnt += 1)
		
			tvalue = wtemp[icnt]
			
			if (numtype(tvalue) == 0)
				wtemp[icnt] = MyTelegraphGain(tvalue, tvalue, instr)
			endif
			
		endfor
	
	endfor
	
	olist = VariableList("CT_Tgain*",";",4+2) // created by ITC code
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
	
		oname = StringFromList(ocnt, olist)
		
		tvalue = NumVarOrDefault(oname, -1)
		
		chan = str2num(oname[5,inf])
		
		instr = ""
		
		for (icnt = 0; icnt < ItemsInList(tGainList); icnt += 1)
		
			item = StringFromList(icnt, tGainList)
			gChan = str2num(StringFromList(0, item, ",")) // corresponding telegraph ADC input channel
			aChan = str2num(StringFromList(1, item, ",")) // ADC input channel
			
			if (chan == aChan)
				instr = StringFromList(2, item, ",")
			endif
			
		endfor
		
		if (strlen(instr) == 0)
			instr = instrOld
		endif
		
		if (tvalue == -1)
			continue
		endif
		
		SetNMvar(oname, MyTelegraphGain(tvalue, tvalue, instr))
		
	endfor

End // ClampTgainConvert

//****************************************************************
//
//	MyTelegraphGain()
//	see NIDAQ code for example call
//
//****************************************************************

Function MyTelegraphGain(tgain, defaultGain, instrument)
	Variable tgain // telegraphed value
	Variable defaultGain // default gain value
	String instrument // instrument name
	
	Variable scale, betaV, alpha = -1
	
	strswitch(instrument)
		case "Axopatch200B":
			alpha = TGainAxo200B(tgain)
			betaV = 1 // whole cell
			scale = 0.001 * betaV // V / mV
			break
		case "Dagan3900A":
			alpha = TGainDagan3900A(tgain)
			scale = 0.001
			break
		default:
			return defaultGain
	endswitch
	
	if ((alpha <= 0) || (numtype(alpha) != 0))
		return defaultGain
	else
		return (alpha * scale)
	endif
	
End // MyTelegraphGain

//****************************************************************
//
//	TGainDagan3900A()
//	Dagan 3900A telegraph gain look-up table
//
//****************************************************************

Function TGainDagan3900A(telValue)
	Variable telValue
	
	telValue = round( telValue / 0.405 )	
	
	switch(telValue)
		case 1:
			return 1
		case 2:
			return 2
		case 3:
			return 5
		case 4:
			return 10
		case 5:
			return 20
		case 6:
			return 50
		case 7:
			return 100
		case 8:
			return 500
		default:
			Print "\rDagan 3900A Telegraph Gain not recognized : " + num2str(telValue)
	endswitch
	
	return -1

End // TGainDagan3900A

//****************************************************************
//
//	TGainAxo200B()
//	Axopatch 200B telegraph gain look-up table
//
//****************************************************************

Function TGainAxo200B(telValue)
	Variable telValue
	
	telValue = 5 * round(10 * telValue / 5)
	
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
//	
//	
//
//****************************************************************
