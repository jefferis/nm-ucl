#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Pulse Generator Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began March 2001
//	Last modified 02 March 2006
//
//	Functions for creating/displaying "pulse" waves
//
//	pulse shapes: square, ramp, alpha, 2-exp, or user-defined
//	trains: fixed or random intervals
//
//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraphMake()

	String gName = "PG_PulseGraph"
	
	String ndf = "root:Packages:NeuroMatic:"
	
	Variable pw=500, ph=300
	
	String computer = StrVarOrDefault(ndf + "Computer", "mac")
	
	if (StringMatch(computer, "mac") == 1)
		pw = 600
	endif
	
	Variable x0 = ceil((NumVarOrDefault(ndf+"xPixels", 1000) - pw)/4)
	Variable y0 = ceil((NumVarOrDefault(ndf+"yPixels", 700) - ph)/4)
	
	Make /O/N=0 PG_DumWave
	
	DoWindow /K $gName
	Display /K=1/W=(x0,y0,x0+pw,y0+ph) PG_DumWave as "Pulse Generator"
	DoWindow /C $gName
	
	Label /W=$gName bottom, "msec"
	
	RemoveFromGraph /Z/W=PG_PulseGraph PG_DumWave
	
	KillWaves /Z PG_DumWave
	
End // PulseGraphMake

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraphUpdate(df, wlist)
	String df // data folder
	String wlist // wave list
	
	Variable icnt, madeGraph
	String rlist, gName = "PG_PulseGraph"

	if (WinType(gName) == 0)
		PulseGraphMake()
		madeGraph = 1
	endif
	
	if (WinType(gName) == 0)
		return -1
	endif
	
	rlist = TraceNameList(gName,";",1)
	
	for (icnt = 0; icnt < ItemsInList(rlist); icnt += 1) // remove all waves first
		RemoveFromGraph /Z/W=$gName $StringFromList(icnt, rlist)
	endfor
	
	if (ItemsInList(wlist) > 0)
	
		PulseGraphAppend(df, wlist)
		
		ModifyGraph /W=$gName mode=6, standoff=0
		ModifyGraph /W=$gName wbRGB = (43690,43690,43690), cbRGB = (43690,43690,43690)
		
		GraphRainbow(gName) // set waves to raindow colors
	
	endif
	
	return madeGraph

End // PulseGraphUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraphRemove(wlist)
	String wlist // wave list
	
	String wname
	Variable icnt

	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		wname = StringFromList(icnt, wlist)
		Execute /Z "RemoveFromGraph /Z/W=PG_PulseGraph " + wname
	endfor
	
End // PulseGraphRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraphAppend(df, wlist)
	String df // data folder
	String wlist // wave list
	
	String wname
	Variable icnt

	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		wname = StringFromList(icnt, wlist)
		Execute /Z "AppendToGraph /W=PG_PulseGraph " + df + wname
	endfor
	
End // PulseGraphAppend

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseWavesKill(df, wPrefix)
	String df // directory folder
	String wPrefix // wave prefix
	
	Variable icnt
	
	String thisDF = GetDataFolder(1)		// save current directory

	SetDataFolder $df
	
	String wlist = WaveList(wPrefix + "*", ";", "")
	String wlist2 = WaveList("*_Pulse*", ";", "")

	for (icnt = 0; icnt < ItemsInList(wlist2); icnt += 1)
		wlist = RemoveFromList(StringFromList(icnt, wlist2), wlist)
	endfor
	
	if (strlen(wlist) > 0)
	
		PulseGraphRemove(wlist)
		
		for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
			KillWaves $StringFromList(icnt, wlist)
		endfor
		
	endif
	
	SetDataFolder $thisDF					// back to original data folder
	
End // PulseWavesKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseWavesMake(df, wPrefix, numWaves, npnts, dt, scale, ORflag)
	String df // data folder where waves are to be made
	String wPrefix // wave prefix
	Variable numWaves, npnts, dt, scale
	Variable ORflag // (0) add (1) OR

	Variable i, j, k, klmt
	String wlist = ""

	if (DataFolderExists(df) == 0)
		NewDataFolder $LastPathColon(df, 0) // create data folder if it does not exist
	endif
	
	String wname = PulseWaveName(df, wPrefix)

	if (WaveExists($wname) == 0)
		Make /N=0 $(wname) // make pulse parameter wave
	endif

	Variable pNumVar = 12
	
	Wave pv = $wname

	for (i = 0; i < numWaves; i += 1) // loop through waves
	
		wname = df + wPrefix + "_" + num2str(i)
	
		if (WaveExists($wname) == 0)
			Make /N=(npnts) $wname  = 0
		elseif (numpnts($wname) != npnts)
			Redimension /N=(npnts) $wname
		endif
		
		Setscale /P x 0, dt, $wname
		
		wlist = AddListItem(wPrefix + "_" + num2str(i), wlist, ";", inf)
	
		Wave pwave =  $wname
		
		pwave = 0
	
		for (j = 0; j < numpnts(pv); j += pNumVar) // loop through pulses
		
		 	if (pv[j + 3] > 0) // WaveNumD
		 		klmt = numWaves
		 	else
		 		klmt = 1
		 	endif
		 	
			for (k = 0; k < klmt; k += 1)
			
				if (pv[j + 2] + k*pv[j + 3] == i)
				
					PulseCompute(df,npnts,dt,pv[j+1],pv[j+4]+i*pv[j+5],pv[j+6]+i*pv[j+7],pv[j+8]+i*pv[j+9],pv[j+10]+i*pv[j+11])
					
					Wave PG_PulseWave = $(df+"PG_PulseWave")
					
					if (ORflag == 1)
						pwave = pwave || PG_PulseWave // OR pulses
					else
						pwave += PG_PulseWave // add pulses
					endif
					
				endif
			endfor
			
		endfor
		
		pwave *= scale
	
	endfor
	
	KillWaves /Z PG_PulseWave
	
	return wlist
	
End // PulseWavesMake

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseCompute(df, npnts, dt, shape, onset, amp, tau1, tau2) // create pulse shape wave
	String df // data folder
	Variable npnts, dt
	Variable shape, onset, amp, tau1, tau2
	
	String wname
	
	Make /O/N=(npnts) $(df+"PG_PulseWave")  // the output wave
	
	Wave PG_PulseWave = $(df+"PG_PulseWave")
	
	PG_PulseWave = 0

	if (tau1 > 0)
	
		switch(shape)
		
			case 1: // square
				PG_PulseWave[(onset/dt), ((onset+tau1)/dt)] = 1
				break
				
			case 2: // ramp
				PG_PulseWave[(onset/dt), ((onset+tau1)/dt)] = (x*dt - onset)/tau1
				break
				
			case 3: // alpha wave
				PG_PulseWave = (x*dt-onset)*exp((onset-x*dt)/tau1)
				break
				
			case 4: // 2-exp
				PG_PulseWave = (1 - exp((onset-x*dt)/tau1)) * exp((onset-x*dt)/tau2)
				break
				
			case 5: // other
			
				wname = StrVarOrDefault(df+"UserPulseName", "")
				
				if (WaveExists($(df+wname)) == 1)
					Wave yourpulse = $(df+wname)
					yourpulse[inf,inf] = 0 // make sure last point is zero
					PG_PulseWave = yourpulse
					Rotate (onset/dt), PG_PulseWave
				endif
				
				break
				
		endswitch
		
		if (onset/dt > 1)
			PG_PulseWave[0,(onset/dt)] = 0 // zero before onset time
		endif
		
	endif
	
	Wavestats /Q PG_PulseWave
	
	if (V_max != 0)
		PG_PulseWave *= amp / V_max // set amplitude
	endif
	
	Setscale /P x 0, dt, PG_PulseWave

End // PulseCompute

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseSave(df, wPrefix, pulseNum, sh, wn, wnd, on, ond, am, amd, wd, wdd, t2, t2d)
	String df // data folder
	String wPrefix // wave prefix
	Variable pulseNum // (-1) dont care, append
	Variable sh, wn, wnd, on, ond, am, amd, wd, wdd, t2, t2d
	
	Variable pNumVar = 12

	String wname = PulseWaveName(df, wPrefix)

	if (WaveExists($wname) == 0)
		Make /N=0 $(wname) // make pulse parameter wave
	endif
	
	Wave Pulse = $wname
	
	if (pulseNum == -1)
		pulseNum = numpnts(Pulse) / pNumVar
	endif
		
	if ((pulseNum+1)*pNumVar > numpnts(Pulse))
		Redimension /N=((pulseNum+1)*pNumVar) Pulse
	endif
	
	Pulse[PulseNum*pNumVar+1]=sh // shape
	Pulse[PulseNum*pNumVar+2]=wn // wave num
	Pulse[PulseNum*pNumVar+3]=wnd // wave num delta
	Pulse[PulseNum*pNumVar+4]=on // onset
	Pulse[PulseNum*pNumVar+5]=ond // onset delta
	Pulse[PulseNum*pNumVar+6]=am // amplitude
	Pulse[PulseNum*pNumVar+7]=amd // amp delta
	Pulse[PulseNum*pNumVar+8]=wd // width
	Pulse[PulseNum*pNumVar+9]=wdd // width delta
	Pulse[PulseNum*pNumVar+10]=t2 // tau2
	Pulse[PulseNum*pNumVar+11]=t2d // tau2 delta
	
	Pulse[0,;pNumVar] = -x/pNumVar // set delimiters
	
End // PulseSave

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseClear(df, wPrefix, pulseNum) // clear pulse waves
	String df // data folder
	String wPrefix // wave prefix
	Variable pulseNum // (-1) for all
	
	Variable pNumVar = 12
	String wname = PulseWaveName(df, wPrefix)

	if (WaveExists($wname) == 0)
		return 0 // "pulse" wave does not exist
	endif
	
	Wave Pulse = $wname
	
	if (pulseNum == -1) // clear all
		Redimension /N=0 Pulse
	else
		DeletePoints PulseNum*pNumVar,pNumVar, Pulse
	endif
	
	Pulse[0,;pNumVar] = -x/pNumVar // reset delimiters

End // PulseClear

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTrain(df, wPrefix, wbgn, wend, winc, tbgn, tend, type, intvl, refrac, shape, amp, width, tau2, continuous, wName)
	String df // data folder
	String wPrefix // wave prefix

	Variable wbgn, wend // wave number begin, end
	Variable winc // wave increment
	Variable tbgn, tend // window begin/end time
	Variable type // (1) fixed (2) random (3) from wave
	Variable intvl // inter-pulse interval
	Variable refrac // refractory period for random train
	Variable shape // pulse shape
	Variable amp // pulse amplitude
	Variable width // pulse width or time constant
	Variable tau2 // decay time constant for 2-exp
	Variable continuous // if waves are to be treated as continuous (0) no (1) yes
	
	String wName // wave name, for type 3
	
	Variable onset, tlast, wcnt, pcnt, hold, plimit = 99999
	
	if ((type == 3) && (WaveExists($wName) == 0))
		return -1
	endif
	
	if (type == 3)
		Wave wtemp = $wName
		plimit = numpnts(wtemp)
	endif
	
	for (wcnt = wbgn; wcnt <= wend; wcnt += 1)
		
		if (continuous == 0)
			tlast = tbgn
		elseif (wcnt == wbgn)
			tlast = tbgn
		else
			tlast = 0
		endif
	
		do // add pulses
	
			if (hold > 0)
				onset = tlast + hold
				hold = 0
			elseif (type == 1) // fixed intervals
				onset = tbgn + intvl * (pcnt + 1)
			elseif (type == 2) // random intervals
				onset = tlast - ln(abs(enoise(1))) * intvl
			elseif (type == 3) // user wave of intervals
				if (numtype(wtemp[pcnt]) == 0)
					onset = tlast + wtemp[pcnt]
				else
					pcnt = plimit
					onset = tend
				endif
			endif
			
			if (onset == tlast)
				pcnt += 1
			elseif ((onset > tlast + refrac) && (onset < tend))
				PulseSave(df, wPrefix, -1, shape, wcnt, winc, onset, 0, amp, 0, width, 0, tau2, 0)
				tlast = onset
				pcnt += 1
			elseif (continuous == 1)
				hold = onset - tend
			endif
			
		while ((hold == 0) && (onset < tend) && (pcnt < plimit))
	
	endfor

End // PulseTrain

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseWaveName(df, wPrefix) // count number of pulse configs
	String df // data folder
	String wPrefix // wave prefix
	
	return df + wPrefix + "_pulse"
	
End // PulseWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseShape(df, shapeNum) // convert shape number to name
	String df // data folder
	Variable shapeNum
	
	switch(shapeNum)
		case 1:
			return "Square"
		case 2:
			return "Ramp"
		case 3:
			return "Alpha"
		case 4:
			return "2-Exp"
		case 5: // Other
			return StrVarOrDefault(df+"UserPulseName", "")
	endswitch
	
	return ""
	
End // PulseShape

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseCount(df, wPrefix) // count number of pulse configs
	String df // data folder
	String wPrefix // wave prefix
	
	String wname = PulseWaveName(df, wPrefix)
	
	Variable pNumVar = 12
	
	if (WaveExists($wname) == 0)
		return 0
	endif
	
	return numpnts($wname) / pNumVar
	
End // PulseCount

//****************************************************************
//****************************************************************
//****************************************************************




