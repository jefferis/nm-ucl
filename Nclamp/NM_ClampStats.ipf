#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Auto Stats Functions
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
//	Last modified 9 April 2007
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimStatsDF()
	String sdf = StimDF()
	
	if (strlen(sdf) > 0)
		return sdf + "Stats:"
	else
		return ""
	endif

End // StimStatsDF

//****************************************************************
//****************************************************************
//****************************************************************

Function StimStatsOn()
	
	return BinaryCheck(NumVarOrDefault(StimStatsDF()+"StatsOn", 0))
	
End // StimStatsOn

//****************************************************************
//****************************************************************
//****************************************************************

Function StimStatsOnSet(on)
	Variable on // (0) no (1) yes
	
	String ssdf = StimStatsDF()
	
	on = BinaryCheck(on)
	
	if ((on == 1) && (DataFolderExists(ssdf) == 0))
		NewDataFolder $LastPathColon(ssdf, 0)
		SetNMvar(ssdf+"StatsOn", 1)
		StimStatsUpdate()
	endif
	
	SetNMvar(ssdf+"StatsOn", on)
	
	ClampStats(on)
	
	return on

End // StimStatsOnSet

//****************************************************************
//****************************************************************
//****************************************************************

Function StimStatsUpdateAsk()
	
	if (StatsTimeStampCompare(StatsDF(), StimStatsDF()) == 0)
	
		DoAlert 1, "Your Stats configuration has changed. Do you want to update the current stimulus configuration to reflect these changes?"
		
		if (V_flag == 1)
			StimStatsUpdate()
			return 1
		endif
	
	endif
	
	return 0

End // StimStatsUpdateAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function StimStatsUpdate() // save Stats waves to stim folder
	
	String stdf = StatsDF()
	String ssdf = StimStatsDF()
	
	if (StimStatsOn() == 1)
		StatsWavesCopy(stdf, ssdf)
		SetNMvar(ssdf+"AmpNV", NumVarOrDefault(stdf+"AmpNV", 0)) // copy current stats window
	endif

End // StimStatsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsRetrieveFromStim() // retrieve Stats waves from stim folder
	String sdf // stim data folder
	
	String stdf = StatsDF()
	String ssdf = StimStatsDF()
	
	if ((StimStatsOn() == 0) || (DataFolderExists(ssdf) == 0))
		return -1
	endif
	
	StatsWavesCopy(ssdf, stdf)
	
	if (WaveExists($(stdf+"ChanSelect")) == 1)
		Wave chan = $(stdf+"ChanSelect")
		CurrentChanSet(chan[0])
	endif
	
	SetNMvar(stdf+"AmpNV", NumVarOrDefault(ssdf+"AmpNV", 0))
		
	return 0

End // ClampStatsRetrieveFromStim

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStats(enable)
	Variable enable // (0) no (1) yes
	
	if (DataFolderExists(StimDF()) == 0)
		return -1
	endif
	
	if (enable == 1)
		StatsChanControlsEnableAll(1)
		ChanGraphUpdate(-1, 1)
	else
		StatsChanControlsEnableAll(0)
	endif
	
	StatsDisplay(-1, enable)
	
	return 0
	
End // ClampStats

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsInit()

	if (StimStatsOn() == 1)
	
		if (StimStatsUpdateAsk() == 0)
			ClampStatsRetrieveFromStim() // get Stats from new stim
		endif
		
		StatsDisplayClear()
		ClampStatsDisplaySavePosition()
		CurrentChanSet(StatsChanSelect(-1))
		
	else
	
		ClampStatsRemoveWaves(1)
		
	endif
	
	ClampStatsDisplaySetPosition("amp")
	ClampStatsDisplaySetPosition("tau")

End // ClampStatsInit()

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsStart()
	
	ClampStatsDisplay(0) // clear display
	ClampStatsRemoveWaves(1) // kill waves
	
	if (StimStatsOn() == 1)
		StatsWinSelectUpdate()
		StatsWavesMake(StatsChanSelect(-1))
		ClampStatsDisplay(1)
	endif

End // ClampStatsStart

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsCompute(mode, currentWave, numWaves)
	Variable mode // (0) preview (1) record
	Variable currentWave
	Variable numWaves
	Variable chan
	
	String wName = ""

	if (StimStatsOn() == 0)
		return 0
	endif
	
	chan = StatsChanSelect(-1)
	
	if (mode == 0)
		wName = ChanWaveName(chan, 0)
	endif
	
	StatsCompute(wName, chan, currentWave, -1, 1, 1)
	
	ClampStatsDisplayUpdate(currentWave, numWaves)

End // ClampStatsCompute()

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsFinish(currentWave)
	Variable currentWave
	
	if (StimStatsOn() == 0)
		return 0
	endif
	
	String stdf = StatsDF()
	Variable saveAuto = NumVarOrDefault(stdf+"AutoPlot", 0)
	
	ClampStatsResize(CurrentWave)
	
	SetNMvar(stdf+"AutoPlot", 0) // temporarily turn off auto-plot
	Stats2WSelectDefault()
	SetNMvar(stdf+"AutoPlot", saveAuto)
	
End // ClampStatsFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsResize(npnts)
	Variable npnts
	
	Variable icnt
	String wname, wlist = WaveList("ST_*", ";", "")
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		wname = StringFromList(icnt, wlist)
		Redimension /N=(npnts) $wname
	endfor

End // ClampStatsResize

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampStatsDisplayAmp()

	return "ClampStatsAmp"

End // ClampStatsDisplayAmp

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampStatsDisplayTau()

	return "ClampStatsTau"

End // ClampStatsDisplayTau

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplay(enable)
	Variable enable
	
	Variable red, green, blue, wcnt, acnt, askbsln, asktau, foundtau
	String wlist, wname, xy, amp, tbox = "", tbox2 = ""
	
	String gName = ClampStatsDisplayAmp(), gName2 = ClampStatsDisplayTau()
	
	String cdf = ClampDF(), stdf = StatsDF()
	
	Variable gexists = WinType(gName)
	Variable texists = WinType(gName2)
	
	Variable numAmps = StatsWinCount()
	Variable numWaves = NumVarOrDefault("NumWaves", 0)
	
	Variable bsln = NumVarOrDefault(cdf+"StatsBslnDsply", 1)
	Variable tau = NumVarOrDefault(cdf+"StatsTauDsply", 2)
	
	String ampColor = StrVarOrDefault(stdf+"AmpColor", "65535,0,0")
	String baseColor = StrVarOrDefault(stdf+"BaseColor", "16386,65535,16385")
	String riseColor = StrVarOrDefault(stdf+"RiseColor", "0,0,65535")
	String dcayColor = StrVarOrDefault(stdf+"DcayColor", "0,0,65535")
	
	if (WaveExists($(stdf+"AmpSlct")) == 0)
		return -1
	endif
	
	Wave /T AmpSlct = $(stdf+"AmpSlct")
	Wave BslnSubt = $(stdf+"BslnSubt")
	
	if (gexists == 1) // remove waves
	
		wlist = WaveList("*", ";", "WIN:"+gName)
		
		for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
			wname = StringFromList(wcnt, wlist)
			RemoveFromGraph /Z/W=$gName $wname
		endfor
		
		TextBox /K/N=text0/W=$gName
		
	endif
	
	if (texists == 1) // remove tau waves
	
		wlist = WaveList("*", ";", "WIN:"+gName2)
		
		for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
			wname = StringFromList(wcnt, wlist)
			RemoveFromGraph /Z/W=$gName2 $wname
		endfor
		
		TextBox /K/N=text0/W=$gName2
		
	endif
	
	if ((StimStatsOn() == 0) || (enable == 0))
		return 0
	endif
	
	wlist = WaveList("ST_*",";","")
	
	foundtau = (StringMatch(wlist, "*ST_RiseT*") == 1) || (StringMatch(wlist, "*ST_DcayT*") == 1)
	foundtau = foundtau || (StringMatch(wlist, "*ST_FwhmT*") == 1)
	
	if ((gexists == 0) || (texists == 0))
	
		if ((gexists == 0) && (StringMatch(wlist, "*ST_Bsln*") == 1))
			askbsln = 1
		endif
		
		if (foundtau == 1)
		if ((gexists == 0) || ((texists == 0) && (tau == 2)))
			asktau = 1
		endif
		endif
	
		bsln += 1
		tau += 1
	
		Prompt bsln, "Display baseline values?", popup "no;yes;"
		Prompt tau, "Display time constants?", popup "no;yes, same window;yes, seperate window;"
		
		if (askbsln && asktau)
			DoPrompt "Clamp Online Stats Display", bsln, tau
		elseif (askbsln && !asktau)
			DoPrompt "Clamp Online Stats Display", bsln
		elseif (!askbsln && asktau)
			DoPrompt "Clamp Online Stats Display", tau
		endif
	
		bsln -= 1
		tau -= 1
		
		SetNMvar(cdf+"StatsBslnDsply", bsln)
		SetNMvar(cdf+"StatsTauDsply", tau)
	
	endif
	
	if (gexists == 0)
		Make /O/N=0 CT_DummyWave
		DoWindow /K $gName
		Display /K=1/N=$gName/W=(0,0,200,100) CT_DummyWave as "NClamp Stats"
		RemoveFromGraph /Z CT_DummyWave
		KillWaves /Z CT_DummyWave
		ClampStatsDisplaySetPosition("amp")
	endif
	
	DoWindow /F $gName
	
	tau *= foundtau
	
	if (tau == 2)
	
		if (texists == 0)
			Make /O/N=0 CT_DummyWave
			DoWindow /K $gName2
			Display /K=1/N=$gName2/W=(20,50,220,150) CT_DummyWave as "Clamp Stats Time Constants"
			RemoveFromGraph /Z CT_DummyWave
			KillWaves /Z CT_DummyWave
			ClampStatsDisplaySetPosition("tau")
		endif
		
		DoWindow /F $gName2
		
	elseif (tau == 1)
	
		DoWindow /K $gName2
		gName2 = gName
		
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
	
		wname = StringFromList(wcnt, wlist)
		
		if ((StringMatch(wname, "ST_Bsln*") == 1) && (bsln == 1))
		
			acnt = str2num(wname[7,7])
			
			red = str2num(StringFromList(0,baseColor,","))
			green = str2num(StringFromList(1,baseColor,","))
			blue = str2num(StringFromList(2,baseColor,","))
		
			AppendToGraph /W=$gName $wname
			ModifyGraph /W=$gName rgb($wname)=(red,green,blue)
			ModifyGraph /W=$gName marker($wname)=ClampStatsMarker(acnt)
			
			tbox += "\rbsln" + num2str(acnt) + " \\s(" + wname + ")"
			
		elseif ((StringMatch(wname, "ST_RiseT*") == 1) && (tau > 0))
		
			acnt = str2num(wname[8,8])
				
			red = str2num(StringFromList(0,riseColor,","))
			green = str2num(StringFromList(1,riseColor,","))
			blue = str2num(StringFromList(2,riseColor,","))
			
			if (tau == 1)
				AppendToGraph /R=tau /W=$gName2 $wname
				ModifyGraph axRGB(tau)=(red,green,blue)
				tbox += "\rriseT" + num2str(acnt) + " \\s(" + wname + ")"
			elseif (tau == 2)
				AppendToGraph /W=$gName2 $wname
				tbox2 += "\rriseT" + num2str(acnt) + " \\s(" + wname + ")"
			endif
			
			ModifyGraph /W=$gName2 rgb($wname)=(red,green,blue)
			ModifyGraph /W=$gName2 marker($wname)=ClampStatsMarker(acnt)
			
		elseif ((StringMatch(wname, "ST_DcayT*") == 1) && (tau > 0))
		
			acnt = str2num(wname[8,8])
		
			red = str2num(StringFromList(0,dcayColor,","))
			green = str2num(StringFromList(1,dcayColor,","))
			blue = str2num(StringFromList(2,dcayColor,","))
			
			if (tau == 1)
				AppendToGraph /R=tau /W=$gName2 $wname
				ModifyGraph axRGB(tau)=(red,green,blue)
				tbox += "\rdecayT" + num2str(acnt) + " \\s(" + wname + ")"
			elseif (tau == 2)
				AppendToGraph /W=$gName2 $wname
				tbox2 += "\rdecayT" + num2str(acnt) + " \\s(" + wname + ")"
			endif
			
			ModifyGraph /W=$gName2 rgb($wname)=(red,green,blue)
			ModifyGraph /W=$gName2 marker($wname)=ClampStatsMarker(acnt)
			
		elseif ((StringMatch(wname, "ST_FwhmT*") == 1) && (tau > 0))
		
			acnt = str2num(wname[8,8])
				
			red = str2num(StringFromList(0,riseColor,","))
			green = str2num(StringFromList(1,riseColor,","))
			blue = str2num(StringFromList(2,riseColor,","))
			
			if (tau == 1)
				AppendToGraph /R=tau /W=$gName2 $wname
				ModifyGraph axRGB(tau)=(red,green,blue)
				tbox += "\rfwhm" + num2str(acnt) + " \\s(" + wname + ")"
			elseif (tau == 2)
				AppendToGraph /W=$gName2 $wname
				tbox2 += "\rfwhm" + num2str(acnt) + " \\s(" + wname + ")"
			endif
			
			ModifyGraph /W=$gName2 rgb($wname)=(red,green,blue)
			ModifyGraph /W=$gName2 marker($wname)=ClampStatsMarker(acnt)
			
		else
		
			for (acnt = 0; acnt < numAmps; acnt += 1) // loop through stats amp windows
			
				amp = AmpSlct[acnt]
				xy = "*Y" + num2str(acnt) + "*"
				
				if (StringMatch(amp, "Level*") == 1)
					xy = "*X" + num2str(acnt) + "*"
				endif
			
				if (StringMatch(wname, xy) == 1)
				
					red = str2num(StringFromList(0,ampColor,","))
					green = str2num(StringFromList(1,ampColor,","))
					blue = str2num(StringFromList(2,ampColor,","))
			
					AppendToGraph /W=$gName $wname
					ModifyGraph /W=$gName rgb($wname)=(red,green,blue)
					ModifyGraph /W=$gName marker($wname)=ClampStatsMarker(acnt)
					
					tbox += "\r" + amp + num2str(acnt) + " \\s(" + wname + ")"
					
				endif
				
			endfor
		
		endif
		
	endfor
	
	ModifyGraph /W=$gName mode=4, msize=4, standoff=0 
	
	if (strlen(tbox) > 0)
		tbox = tbox[1,inf] // remove carriage return at beginning
		Label /W=$gName bottom StrVarOrDefault("WavePrefix", "Wave")
		TextBox /E/C/N=text0/A=MT/W=$gName tbox
		
		if (numWaves > 0)
			SetAxis /W=$gName bottom 0,(min(numWaves,10))
		endif
	
	endif
	
	if (tau == 1)
	
		Label /W=$gName2 tau StrVarOrDefault("xLabel", "msec")
		
	elseif (tau == 2)
	
		ModifyGraph /W=$gName2 mode=4, msize=4, standoff=0
		
		if (strlen(tbox2) > 0)
			tbox2 = tbox2[1,inf] // remove carriage return at beginning
			Label /W=$gName2 bottom StrVarOrDefault("WavePrefix", "Wave")
			Label /W=$gName2 left StrVarOrDefault("xLabel", "msec")
			TextBox /E/C/N=text0/A=MT/W=$gName2 tbox2
			
			if (numWaves > 0)
				SetAxis /W=$gName bottom 0,(min(numWaves,10))
			endif
			
		else
		
			TextBox /K/W=$gName2
		
		endif
		
	endif

End // ClampStatsDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplayUpdate(currentWave, numwaves) // resize stats display x-scale
	Variable currentWave
	Variable numwaves
	
	String amp = ClampStatsDisplayAmp()
	String tau = ClampStatsDisplayTau()
	
	Variable inc = 10
	Variable num = inc * (1 + floor(currentWave / inc))
	
	num = min(numwaves, num)

	if (WinType(amp) == 1)
		SetAxis /Z/W=$amp bottom 0, num
	endif
	
	if (WinType(tau) == 1)
		SetAxis /Z/W=$tau bottom 0, num
	endif
	
End // ClampStatsDisplayUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplaySavePosition()
	
	String amp = ClampStatsDisplayAmp()
	String tau = ClampStatsDisplayTau()
	String ssdf = StimStatsDF()
	
	if (WinType(amp) == 1)
		GetWindow $amp wsize	
		SetNMvar(ssdf+"CSA_X0", V_left)
		SetNMvar(ssdf+"CSA_Y0", V_top)
		SetNMvar(ssdf+"CSA_X1", V_right)
		SetNMvar(ssdf+"CSA_Y1", V_bottom)
	endif
	
	if (WinType(tau) == 1)
		GetWindow $tau wsize	
		SetNMvar(ssdf+"CST_X0", V_left)
		SetNMvar(ssdf+"CST_Y0", V_top)
		SetNMvar(ssdf+"CST_X1", V_right)
		SetNMvar(ssdf+"CST_Y1", V_bottom)
	endif

End // ClampStatsDisplaySavePositionx

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplaySetPosition(gType)
	String gType // "amp" or "tau"
	
	Variable x0, y0, x1, y1
	String ndf = NMDF()
	
	Variable xPixels = NumVarOrDefault(ndf+"xPixels", 1000)
	Variable yPixels = NumVarOrDefault(ndf+"yPixels", 700)

	String amp = ClampStatsDisplayAmp()
	String tau = ClampStatsDisplayTau()
	String ssdf =StimStatsDF()
	
	Variable statsOn = StimStatsOn()
	
	strswitch(gType)
	
		case "amp":
	
			if (WinType(amp) == 1)
			
				if (statsOn == 1)
					x0 = NumVarOrDefault(ssdf+"CSA_X0", xPixels * 0.1)
					y0 = NumVarOrDefault(ssdf+"CSA_Y0", yPixels * 0.5)
					x1 = NumVarOrDefault(ssdf+"CSA_X1", x0 + 260)
					y1 = NumVarOrDefault(ssdf+"CSA_Y1", y0 + 170)
				else
					x0 = 0
					y0 = 0
					x1 = 0
					y1 = 0
				endif
				
				if (numtype(x0 * y0 * x1 * y1) == 0)
					MoveWindow /W=$amp x0, y0, x1, y1
				endif
				
			endif
			
			break
			
		case "tau":
	
			if (WinType(tau) == 1)
			
				if (statsOn == 1)
					x0 = NumVarOrDefault(ssdf+"CST_X0", xPixels * 0.1 + 270)
					y0 = NumVarOrDefault(ssdf+"CST_Y0", yPixels * 0.5)
					x1 = NumVarOrDefault(ssdf+"CST_X1", x0 + 260)
					y1 = NumVarOrDefault(ssdf+"CST_Y1", y0 + 170)
				else
					x0 = 0
					y0 = 0
					x1 = 0
					y1 = 0
				endif
				
				if (numtype(x0 * y0 * x1 * y1) == 0)
					MoveWindow /W=$tau x0, y0, x1, y1
				endif
				
			endif
			
			break
			
	endswitch

End // ClampStatsDisplaySetPosition

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsRemoveWaves(kill)
	Variable kill // (0) dont kill waves (1) kill waves
	
	Variable icnt
	String wname
	
	String amp = ClampStatsDisplayAmp()
	String tau = ClampStatsDisplayTau()
	
	if (WinType(amp) == 1)
	
		String wlist = WaveList("*", ";", "WIN:"+amp)
		
		for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
			wname = StringFromList(icnt, wlist)
			RemoveFromGraph /Z/W=$amp $wname
		endfor
		
	endif
	
	if (WinType(tau) == 1)
	
		wlist = WaveList("*", ";", "WIN:"+tau)
		
		for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
			wname = StringFromList(icnt, wlist)
			RemoveFromGraph /Z/W=$tau $wname
		endfor
		
	endif
	
	if (kill == 1)
		KillGlobals("", "ST_*", "001") // kill Stats waves in current folder
	endif

End // ClampStatsRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsMarker(select)
	Variable select

	switch(select)
		case 0:
			return 8
		case 1:
			return 6
		case 2:
			return 5
		case 3:
			return 2
		case 4:
			return 22
		case 5:
			return 4
		default:
			return 0
	endswitch

End // ClampStatsMarker

//****************************************************************
//****************************************************************
//****************************************************************
