#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spearman Rank-Order Stability Test
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 18 Nov 2004
//
//	Original code from Dr. Angus Silver and Simon Mitchell
//	Department of Physiology, University College London
//	Spearman Rank-Order macro from Numerical Recipes
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StabDF() // package full-path folder name

	return PackDF("Stats")
	
End // StabDF()

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStabilityCall0()

	NMStabilityCall("", 1)

End // NMStabilityCall0

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStabilityCall(wName, resultsWave)
	String wName // wave name or ("") for prompt
	Variable resultsWave // (0) no (1) yes
	
	String wlist, vlist = "", df = StabDF()
	Variable refine = 1, startPnt, endPnt, minArray, sig, win2Frac, pnts
	
	CheckPackage("Stats", 0) // create Stats folder if necessary
	
	wlist = WaveList("*", ";", WaveListText0()) // get list of waves in current directory
	
	if (strlen(wName) == 0)
	
		refine = NumVarOrDefault(df+"StbRefine", 1) + 1
		
		Prompt wName, "select wave:", popup wlist
		Prompt refine, "perform second pass refinement?", popup "no;yes;"
		DoPrompt "Stability Analysis", wName, refine
		
		if (V_flag == 1)
			return "" // cancel
		endif
		
		refine -= 1
		
		SetNMvar(df+"StbRefine", refine)
		
		NMStabilityPlot(wName)
		
	endif
	
	pnts = numpnts($wName)
	endPnt = pnts - 1
	minArray = NumVarOrDefault(df+"StbMinArray", 10)
	sig = NumVarOrDefault(df+"StbSig", 0.05)
	win2Frac = NumVarOrDefault(df+"StbWin2Frac", 0.5)
	
	Prompt startPnt, "start wave point:"
	Prompt endPnt, "end wave point:"
	Prompt sig, "significance level:"
	Prompt win2Frac, "refinement window fraction (2nd pass):"
	
	if (refine == 0)
		Prompt minArray, "min search window in points:"
		DoPrompt "Spearman Stability Analysis", startPnt, endPnt, minArray, sig
		win2Frac = 1
	else
		Prompt minArray, "min search window in points (1st pass):"
		DoPrompt "Spearman Stability Analysis", startPnt, endPnt, minArray, win2Frac, sig
	endif

	if (V_flag == 1)
		return ""  // user cancelled
	endif
	
	SetNMvar(df+"StbMinArray", minArray)
	SetNMvar(df+"StbSig", sig)
	
	if (refine == 1)
		SetNMvar(df+"StbWin2Frac", win2Frac)
	endif
	
	if (endPnt == pnts - 1)
		endPnt = inf
	endif
	
	vlist = NMCmdStr(wName, vlist)
	vlist = NMCmdNum(startPnt, vlist)
	vlist = NMCmdNum(endPnt, vlist)
	vlist = NMCmdNum(minArray, vlist)
	vlist = NMCmdNum(sig, vlist)
	vlist = NMCmdNum(win2Frac, vlist)
	NMCmdHistory("NMStability", vlist)
	
	return NMStability(wName, startPnt, endPnt, minArray, sig, win2Frac)
	
End // NMStabilityCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStabilityStats(wName, wSelect)
	String wName
	Variable wSelect
	
	String gName, gTitle, df = StabDF()
	
	if (wSelect == 0)
		gName = NMStabilityCall(wName, 0)
		gTitle = "Stability : " + wName
	else
		gName = NMStabilityCall(df+"ST_Stats2Wave", 0)
		gTitle = "Stability : " + wName + " : " +  NMWaveSelectGet()
	endif
	
	if (strlen(gName) == 0)
		return ""
	endif
	
	DoWindow /T $gName, gTitle
	
	return gName
	
End // NMStabilityStats

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStability(wName, startPnt, endPnt, minArray, sig, win2Frac)
	String wName // input wave name
	Variable startPnt // begin search point
	Variable endPnt // end search point (inf) for all
	Variable minArray // min sliding search window size
	Variable sig // significance level (0.05)
	Variable win2Frac // fraction of minArray for 2nd refinement pass, (1) for no refinement
	
	Variable sf, sg, npnts, numArr, arrPnts, acnt, passes, prob, regrs, stableFrom, stableTo
	Variable pcnt, plast, pfirst = -1, pmax = 0
	Variable thispoint, lastpoint, counter
	
	String xl, yl, txt, gName, sName, df = StabDF()
	
	String pName = GetPathName(wName, 0)
	
	String probGraph = "ST_Probs_all_Plot" // probability graph name
	String regGraph = "ST_Regrs_all_Plot" // regression graph name
	
	DoWindow /K $probGraph
	DoWindow /K $regGraph
	
	if ((WaveExists($wName) == 0) || (WaveType($wName) == 0))
		Abort "Abort: bad wave name."
	endif
	
	if (numtype(endPnt) > 0)
		endPnt = numpnts($wName) - 1
	endif
	
	CheckPackage("Stats", 0) // create Stats folder if necessary
	
	if (endPnt > 999)
		DoAlert 1, "Warning: this is a large wave. Stability analysis may take a long time. Do you want to continue?"
		if (V_Flag == 2)
			return ""
		endif
	endif
	
	Duplicate /O $wName $(df+"STBL_Sig1")
	Duplicate /O $wName $(df+"STBL_FitLine")
	
	Wave data = $wName
	Wave STBL_Sig1 = $(df+"STBL_Sig1")
	Wave Stb_fitLine = $(df+"STBL_FitLine")
	
	Stb_fitLine = Nan
	
	NMHistory("\rStability analyses of " + wName)
	
	npnts = endPnt - startPnt + 1
	
	Make /D/O/N=(npnts) ST_inWaveY
	Make /D/O/N=(npnts) ST_inWaveX
	
	ST_inWaveY = data[p + startPnt]
	ST_inWaveX = p + startPnt
	
	for (pcnt = 0; pcnt < npnts; pcnt += 1)
		if (numtype(ST_inWaveY[pcnt]) != 0)
			ST_inWaveX[pcnt] = Nan
		endif
	endfor
	
	Sort ST_inWaveY ST_inWaveY, ST_inWaveX // sort according to y-values
	
	//
	// initial check for ties (equal y-values)
	//
	
	for (pcnt = 0; pcnt < npnts-1; pcnt+=1) 
		if (ST_inWaveY[pcnt] == ST_inWaveY[pcnt+1])
			Print "Alert: located data tie @ points " + num2str(ST_inWaveX[pcnt]) + " and " + num2str(ST_inWaveX[pcnt+1])
		endif
	endfor
	
	Sort ST_inWaveX ST_inWaveY, ST_inWaveX // back to original
	
	WaveStats /Q ST_inWaveX // count the number of points, excluding NANs
	
	npnts = V_maxloc+1
	
	Redimension /N=(npnts) ST_inWaveX, ST_inWaveY // eliminate NANs
	Redimension /N=(npnts) STBL_Sig1, Stb_fitLine
	
	STBL_Sig1 = ST_inWaveY
	
	//
	// find largest section of data that gives StbProbs > sig
	//
	
	numArr = npnts - minArray + 1 // number of possible arrays, given minArray
	
	for (acnt = 0; acnt < numArr; acnt+=1) // loop thru arrays, from largest to smallest
	
		arrPnts = npnts - acnt
		passes = npnts - arrPnts + 1
		
		Make /D/O/N=(arrPnts) ST_xArray
		Make /D/O/N=(arrPnts) ST_yArray
		
		for (pcnt = 0; pcnt < passes; pcnt+=1) // slide array thru data points
		
			ST_xArray = ST_inWaveX[pcnt+p]
			ST_yArray = ST_inWaveY[pcnt+p]
			
			Sort ST_yArray ST_yArray, ST_xArray
			sf = NMStabilityRank(ST_yArray)
			
			Sort ST_xArray ST_yArray, ST_xArray
			sg = NMStabilityRank(ST_xArray)
			
			NMStabilityCorr(ST_xArray, ST_yArray, sf, sg)
			
			prob = NumVarOrDefault(df+"StbProbs", 0)
			regrs = NumVarOrDefault(df+"StbRegrs", 0)
			
			if ((prob > sig) && (prob > pmax)) // stable region, save values
				pfirst = pcnt
				pmax = prob
			endif
			
		endfor
	
		if (pfirst >= 0)
			break
		endif
	
	endfor
	
	if (pfirst < 0) // no stable region detected
	
		STBL_Sig1 = Nan
		DoAlert 0, "Abort: no stable region detected during first stability test. Try using smaller analysis window."
		NMStabilityKill()
		return ""
		
	else // first pass through stability analyses, displayed by STBL_Sig1
	
		plast = pfirst + arrPnts - 1
	
		stableFrom = ST_inWaveX[pfirst]
		stableTo = ST_inWaveX[plast]
		
		NMHistory("First pass successful (" + num2str(arrPnts) + " point window): stable from point " + num2str(StableFrom) + " to " + num2str(StableTo))
		
	 	if (pfirst > 0)
			STBL_Sig1[0,(pfirst-1)] = NaN
		endif
		
		if (plast + 1 <= npnts - 1)
			STBL_Sig1[plast + 1, npnts - 1] = NaN
		endif
		
		NMStabilityReplaceNANs(ST_inWaveX, STBL_Sig1)
		
	endif
	
	//
	// pass through selected array again with smaller window
	// save results to Probs and Regres waves
	//
	
	if (win2Frac < 1)
	
		Duplicate /O $wName $(df+"STBL_Sig2")
		Duplicate /O $wName $(df+"STBL_AllProbs")
		Duplicate /O $wName $(df+"STBL_SigProbs")
		Duplicate /O $wName $(df+"STBL_AllRegrs")
		Duplicate /O $wName $(df+"STBL_SigRegrs")
		Duplicate /O $wName $(df+"STBL_SigLine")
		
		Wave STBL_Sig2 = $(df+"STBL_Sig2")
		Wave STBL_AllProbs = $(df+"STBL_AllProbs")
		Wave STBL_SigProbs = $(df+"STBL_SigProbs")
		Wave STBL_AllRegrs = $(df+"STBL_AllRegrs")
		Wave STBL_SigRegrs = $(df+"STBL_SigRegrs")
		Wave STBL_SigLine = $(df+"STBL_SigLine")
		
		Redimension /N=(npnts) STBL_AllProbs, STBL_SigProbs, STBL_AllRegrs, STBL_SigRegrs
		Redimension /N=(npnts) STBL_Sig2, STBL_SigLine
		
		STBL_Sig2 = ST_inWaveY
	
		arrPnts = round(arrPnts*win2Frac)
		passes = (plast - pfirst + 1) - arrPnts + 1
	
		Make /D/O/N=(arrPnts) ST_yArray
		Make /D/O/N=(arrPnts) ST_xArray
		
		STBL_AllProbs = Nan
		STBL_AllRegrs = Nan
		
		for (pcnt = pfirst; pcnt < pfirst + passes; pcnt+=1)
		
			ST_yArray = ST_inWaveY[p+pcnt]
			ST_xArray = ST_inWaveX[p+pcnt]
			
			Sort ST_yArray ST_yArray, ST_xArray
			sf = NMStabilityRank(ST_yArray)
			
			Sort ST_xArray ST_yArray, ST_xArray
			sg = NMStabilityRank(ST_xArray)
			
			NMStabilityCorr(ST_xArray, ST_yArray, sf, sg)
			
			STBL_AllProbs[pcnt] = NumVarOrDefault(df+"StbProbs", 0)
			STBL_AllRegrs[pcnt] = NumVarOrDefault(df+"StbRegrs", 0)
			
		endfor
		
		STBL_SigProbs = STBL_AllProbs
		STBL_SigRegrs = STBL_AllRegrs
		
		//
		// now locate stretch where Prob > sig
		//
		
		for (pcnt = pfirst; pcnt < npnts; pcnt+=1)
		
			lastpoint = thispoint
			thispoint = STBL_AllProbs[pcnt]
			
			if (numtype(thispoint) != 0)
				break
			endif
			
			if (thispoint >= sig)
			
				if (lastpoint < sig)
					pfirst = pcnt
					counter = 1 // transition from sig to non-sig
					continue
				else 	
					counter+=1 // continuation of non-sig region
				endif
				
			else
			
				if (lastpoint >= sig)
					break // end of significant region
				endif
			
			endif
			
		endfor
		
		if (pfirst > 0)
			STBL_SigProbs[0, pfirst - 1] = NaN
			STBL_SigRegrs[0, pfirst- 1] = NaN
		endif
		
		plast = pfirst + counter - 1
		
		if (plast + 1 <= npnts - 1)
			STBL_SigProbs[plast + 1, npnts - 1] = NaN
			STBL_SigRegrs[plast + 1, npnts - 1] = NaN
		endif
		
		plast = plast + arrPnts - 1
		
		stableFrom = ST_inWaveX[pfirst]
		stableTo = ST_inWaveX[plast]
		
		NMHistory("Second pass successful (" + num2str(arrPnts) + " point window): stable from point " + num2str(stableFrom) + " to " + num2str(stableTo))
		
		if (pfirst > 0)
			STBL_Sig2[0, pfirst - 1] = NaN
		endif
		
		if (plast + 1 <= npnts - 1)
			STBL_Sig2[plast + 1, npnts - 1] = NaN
		endif
		
		//
		// put NANs back in display waves
		//
		
		NMStabilityReplaceNANs(ST_inWaveX, STBL_Sig2)
		NMStabilityReplaceNANs(ST_inWaveX, STBL_AllProbs)
		NMStabilityReplaceNANs(ST_inWaveX, STBL_SigProbs)
		NMStabilityReplaceNANs(ST_inWaveX, STBL_SigLine)
		NMStabilityReplaceNANs(ST_inWaveX, STBL_AllRegrs)
		NMStabilityReplaceNANs(ST_inWaveX, STBL_SigRegrs)
	
		//
		// display results
		//
		
		STBL_SigLine = sig
		
		plast = pfirst + counter - 1
		
		Display /M/K=1/W=(1,11.3,20,20.3) STBL_AllRegrs, STBL_SigRegrs as "Stability Analysis : Regression"	 
		Dowindow /C $regGraph
		Label /Z Bottom "First point of " + num2str(Arrpnts) + " point window (second pass)"
		Label /Z Left "Regression Coefficent"
		ModifyGraph mode(STBL_AllRegrs)=4, marker(STBL_AllRegrs)=19, rgb(STBL_AllRegrs)=(0,0,0)
		ModifyGraph mode(STBL_SigRegrs)=4, marker(STBL_SigRegrs)=0, rgb(STBL_SigRegrs)=(65535,0,0)
		SetAxis bottom pfirst, plast
		SetCascadeXY(regGraph)
		
		Display /M/K=1/W=(1,21.3,20,30.3) STBL_AllProbs, STBL_SigProbs,  STBL_SigLine as "Stability Analysis : Probability"
		Dowindow /C $probGraph
		Label /Z Bottom "First point of " + num2str(Arrpnts) + " point window (second pass)"
		Label /Z Left "Probability"
		ModifyGraph mode(STBL_AllProbs)=4, marker(STBL_AllProbs)=19, rgb(STBL_AllProbs)=(0,0,0)
		ModifyGraph mode(STBL_SigProbs)=4, marker(STBL_SigProbs)=0, rgb(STBL_SigProbs)=(65535,0,0)
		ModifyGraph rgb(STBL_SigLine)=(65535,0,0)
		Setaxis left 0,1
		SetAxis bottom pfirst, plast
		SetCascadeXY(probGraph)
	
	endif
	
	gName = NMStabilityPlot(wName)
	
	AppendtoGraph /C=(0,0,65535) STBL_Sig1
	Appendtograph /C=(0,0,0) Stb_fitLine
	ModifyGraph mode(STBL_Sig1)=4, marker(STBL_Sig1)=1
	
	Redimension /N=(numpnts(STBL_Sig1)) Stb_fitLine
	
	Stb_fitLine = Nan
	
	if (win2Frac == 1)
		CurveFit /Q line STBL_Sig1 /D=Stb_fitLine
		//NMHistory("WaveStats of STBL_Sig1:")
		//Wavestats STBL_Sig1
	else
		Appendtograph /C=(65535,0,0) STBL_Sig2
		ModifyGraph mode(STBL_Sig2)=4, marker(STBL_Sig2)=0
		CurveFit /Q line STBL_Sig2 /D=Stb_fitLine
		//NMHistory("WaveStats of STBL_Sig2:")
		//Wavestats STBL_Sig2
	endif
	
	SetNMvar(df+"StableFrom", stableFrom)
	SetNMvar(df+"StableTo", stableTo)
	
	DrawText 0.1,0.1,"Stable from point " + num2str(stableFrom) + " to " + num2str(stableTo)
	
	sName = wName + "_Stable"
	
	Duplicate /O $wName, $sName
	
	xl = NMNoteLabel("x", wName, "Wave#")
	
	txt = "Stbl Pbgn:" + num2str(startPnt) + ";Stbl Pend:" + num2str(endPnt) + ";Stbl MinArray:" + num2str(minArray)
	txt += ";Stbl Sig:" + num2str(sig) + ";Stbl Win2Frac:" + num2str(win2Frac) + ";"
	
	NMNoteType(sName, "NMSet", xl, "Stable Region (1)", "Func:NMStability")
	Note $sName, "Stbl Wave:" + wName
	Note $sName, txt
	
	Wave wtemp = $sName
	
	wtemp = 0
	wtemp[stableFrom,stableTo] = 1
	
	NMHistory("Stability results stored in wave: " + wName + "_Stable")
	
	UpdateNMWaveSelect()
	
	NMStabilityKill()
	
	return gName
	
End // NMStability

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStabilityKill()

	KillWaves /Z  ST_inWaveX, ST_inWaveY, ST_yArray, ST_xArray, W_coef, W_sigma

End // NMStabilityKill

//****************************************************************
//****************************************************************
//****************************************************************
Function /S NMStabilityPlot(wName)
	String wName
	
	String pName = GetPathName(wname, 0)
	String gPrefix = pName + "_" + NMFolderPrefix("") + "_Stable"
	String gName = NextGraphName(gPrefix, -1, NMOverWrite())
	String gTitle = NMFolderListName("") + " : Stability Analysis : " + GetPathName(wName,0)
	
	Dowindow /K $gName
	Display /M/K=1/W=(1,1,20,10) $wName as gTitle
	Dowindow /C $gName
	ModifyGraph mode=4, marker=19, rgb=(500,500,500)
	Label /Z Bottom NMNoteLabel("x", wName, "")
	Label /Z Left NMNoteLabel("y", wName, "")
	SetCascadeXY(gName)
	
	DoUpdate
	
	return gName
	
End // NMStabilityPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStabilityRank(sortedWave)
	Wave sortedWave // sorted input wave name
	
	Variable j, ji, jt, ntie, s, rank
	
	Variable npnts = numpnts(sortedWave)
	
	for (j = 0; j < npnts-1; j+=1)
	
		if (sortedWave[j] == sortedWave[j+1]) // found tie
		
			jt = j+1
			ntie = 1
			
			for (jt = j+1; jt < npnts; jt+=1) // find more ties
				if (sortedWave[jt] == sortedWave[j])
					ntie += 1
				else
					jt -= 1
					break
				endif
			endfor
			
			rank = 0.5*(j + jt) // mean rank of the tie
			
			for (ji = j; ji <= jt; ji+=1)
				sortedWave[ji] = rank
			endfor
			
			s+=(ntie*ntie*ntie)-ntie
			
			j = jt
		
		else
		
			sortedWave[j] = j
			
		endif
		
	endfor
	
	if (j == npnts - 1)
		sortedWave[j] = j
	endif
	
	return s // if no ties, s = 0
	
End // NMStabilityRank

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStabilityCorr(xWave, yWave, sf, sg) // compute correlation
	Wave xWave
	Wave yWave
	Variable sf, sg
	
	Variable i, t, d, npnts, n3n, dnum
	Variable top, bottom, prob, regrs
	String df = StabDF()
	
	npnts = numpnts(yWave)
	n3n = npnts^3 - npnts
	dnum = npnts - 2
	
	for (i = 0; i < npnts; i+=1)
		d += (xWave[i]-yWave[i])^2	// sum of squared differences
	endfor
	
	top = 1 - (6/n3n) * (d + (sf + sg)/12)
	bottom = sqrt(1-(sf/n3n)) * sqrt(1-(sg/n3n))
	regrs = top/bottom // regression
	
	bottom = (1 + regrs)*(1 - regrs)
	
	if (bottom > 0) // calculate Probability
		t = regrs * sqrt(dnum/bottom)						
		prob = betai((0.5*dnum), 0.5, (dnum/(dnum+t*t)))
	endif
	
	SetNMvar(df+"StbProbs", prob)
	SetNMvar(df+"StbRegrs", regrs)
	
End // NMStabilityCorr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStabilityReplaceNANs(xWave, yWave)
	Wave xWave, yWave
	
	Variable icnt, opnts, xpnt
	Variable npnts = numpnts(xWave)
	
	WaveStats /Q xWave
	
	opnts = V_max + 1
	
	if (opnts == npnts)
		return 0 // nothing to do
	endif
	
	Redimension /N=(opnts) yWave
	
	Duplicate /O yWave tempWave
	
	tempWave = Nan
	
	for (icnt = 0; icnt < npnts; icnt += 1)
		xpnt = xWave[icnt]
		tempWave[xpnt] = yWave[icnt]
	endfor
	
	yWave = tempWave
	
	KillWaves /Z tempWave
	
End // NMStabilityReplaceNANs

//****************************************************************
//****************************************************************
//****************************************************************