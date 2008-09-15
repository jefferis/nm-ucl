#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Kolmogorov-Smirnov Test
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 18 Nov 2004
//
//	Original code from Dr. Angus Silver
//	Department of Physiology, University College London
//	Based on Numerical Recipes
//
//	This macro impliments the Kolmogorov-Smirnov 
//	test for two sets of unbinned, unsorted data. The 
//	test finds the maximum value of the absolute 
//	difference D between two cumulative distributions. 
//	This implimentation outputs a global variable for 
//	the absolute difference (ST_KSd) and the probability 
//	that D is significant (ST_KSprob).
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S KSTestDF() // package full-path folder name

	return PackDF("Stats")
	
End // KSTestDF

//****************************************************************
//****************************************************************
//****************************************************************

Function KSTestCall()
	String vlist = "", df = KSTestDF()
	
	String opstr = WaveListText0()
	
	CheckPackage("Stats", 0) // create Stats folder if necessary
	
	String wName1 = StrVarOrDefault(df+"KSwname1", "")
	String wName2 = StrVarOrDefault(df+"KSwname2", "")
	Variable dsply = 1 + NumVarOrDefault(df+"KSdsply", 1)
	
	Prompt wName1,"select first data wave:",popup, Wavelist("*", ";", opstr)
	Prompt wName2,"select second data wave for comparison:",popup, Wavelist("*", ";", opstr)
	Prompt dsply,"display cumulative distributions?",popup,"no;yes"
	
	DoPrompt "Kolmogorov-Smirnov Test For Significant Difference", wName1, wName2, dsply
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	dsply -= 1
	
	SetNMstr(df+"KSwname1", wName1)
	SetNMstr(df+"KSwname2", wName1)
	SetNMvar(df+"KSdsply", dsply)
	
	vlist = NMCmdStr(wName1, vlist)
	vlist = NMCmdStr(wName2, vlist)
	vlist = NMCmdNum(dsply, vlist)
	NMCmdHistory("KSTest", vlist)
	
	KSTest(wName1, wName2, dsply)

End // KSTestCall

//****************************************************************
//****************************************************************
//****************************************************************

function KSTest(wName1, wName2, dsply)
	String wName1, wName2 // input wave names
	Variable dsply // display output graph (1- yes;0 - no)
	
	if ((WaveExists($wName1) == 0) || (WaveType($wName1) == 0))
		Abort "Abort: bad input wave 1."
	endif
	
	if ((WaveExists($wName2) == 0) || (WaveType($wName2) == 0))
		Abort "Abort: bad input wave 2."
	endif
	
	Duplicate /O $wName1 temp1
	Duplicate /O $wName2 temp2
	
	Variable /G ST_KSd = 0, ST_KSprob = 0
	Variable j1, j2, d1, d2, dt, en, fn1, fn2
	String message
	
	Variable npnts1 = numpnts(temp1)
	Variable npnts2 = numpnts(temp2)
	
	Sort temp1 temp1
	Sort temp2 temp2
	
	WaveStats /Q/Z temp1
	npnts1 = V_npnts
	
	Redimension /N=(npnts1) temp1 // remove Nans
	
	WaveStats /Q/Z temp2
	npnts2 = V_npnts
	
	Redimension /N=(npnts2) temp2 // remove Nans
	
	Do
	
		d1 = temp1[j1]
		d2 = temp2[j2]
		
		if (d1 <= d2)
			fn1 = j1/npnts1
			j1 += 1
		endif
		
		if (d2 <= d1)
			fn2 = j2/npnts2
			j2 += 1
		endif
		
		dt = abs(fn2-fn1)
		
		if (dt > ST_KSd)
			ST_KSd = dt
		endif
		
	While ((j1 < npnts1) && (j2 < npnts2))
	
	en = sqrt((npnts1*npnts2)/(npnts1+npnts2))
	
	ST_KSprob = KSprob(ST_KSd*(en + 0.12 + (0.11/en)))
	
	//ST_KSd = ((round(ST_KSd*(10^(pres)))/(10^(pres))))
	//ST_KSprob=((round(prob*(10^(pres)))/(10^(pres))))
	
	if (ST_KSprob <= 0.05)
		message="The two data sets are probably from different populations"
	else
		message="The two data sets are probably from the same population"
	endif
	
	Print "Kolmogorov-Smirnov test for waves " + wName1 + " and " + wName2 + ":"
	Print "D =", ST_KSd
	Print "Pks =", ST_KSprob
	Print message
	
	if (dsply == 1)
		KSPlotCumulatives(wName1, wName2)
	endif
	
	KillWaves /Z temp1, temp2
	
End // KSTest

//****************************************************************
//****************************************************************
//****************************************************************

Function KSprob(lambda) // Kolmogorov-Smirnov probability function
	Variable lambda
	
	Variable a2 = -2*lambda*lambda
	Variable j, tsum, term, termbf, fac = 2
	
	for (j = 1;j <= 100; j += 1)
	
		term = fac * exp(a2*j*j)
		tsum += term
		
		if ((abs(term) <= 0.001*termbf) || (abs(term) <= 1e-08*tsum))
			return tsum // stop summation
		endif
		
		fac = -fac
		termbf = abs(term)
		
	endfor
	
	return 1 // failed to converge
	
End // KSprob

//****************************************************************
//****************************************************************
//****************************************************************

Function KSPlotCumulatives(wName1, wName2)
	String wName1, wName2
	
	String SKresults, txt
	String xl = NMNoteLabel("y", wName1, "")
	String yl = "Relative Frequency"
	
	String oName1 = wName1 + "_KSprob"
	String oName2 = wName2 + "_KSprob"
	
	String gtitle = NMFolderListName("") + " : KS Cumulative Distributions"
	String gPrefix = wName1 + "_" + NMFolderPrefix("") + "Kolmo"
	String gName = NextGraphName(gPrefix, -1, NMOverWrite())
	
	Variable bins = 500 // number of bins in output cumulative waves
	
	Variable dKS = NumVarOrDefault("ST_KSd", -1)
	Variable KSprob = NumVarOrDefault("ST_KSprob", -1)
	
	if ((dKS == -1) || (KSprob == -1))
		Abort "Abort: Kolmogorov-Smirnov output variables ST_KSd and ST_KSprob  do not exist."
	endif
	
	if ((WaveExists($wName1) == 0) || (WaveType($wName1) == 0))
		Abort "Abort: bad input wave 1."
	endif
	
	if ((WaveExists($wName2) == 0) || (WaveType($wName2) == 0))
		Abort "Abort: bad input wave 2."
	endif
	
	Variable NumChannels = NumVarOrDefault("NumChannels", 0)
	Variable chan = ChanNumGet(wName1)
	
	SKresults = "Kolmogorov-Smirnov Test"
	SKresults += "\r\\s(" + oName1 + ") " + wName1 + "\r\\s(" + oName2 + ") " + wName2
	SKresults += "\r   D = " + num2str(dKS) + "\r   Pks = " + num2str(KSprob)
	
	Dowindow /K $gName
	
	Make /O/N=4 params
	Make /O/N=(bins) $oName1, $oName2
	
	NMNoteType(oName1, "KSTest Probability", xl, yl, "Func:KSTest")
	NMNoteType(oName2, "KSTest Probability", NMNoteLabel("y", wName2, ""), yl, "Func:KSTest")
	
	Note $oName1, "KSTest Wave1:" + wName1
	Note $oName2, "KSTest Wave1:" + wName1
	
	Note $oName1, "KSTest Wave2:" + wName2
	Note $oName2, "KSTest Wave2:" + wName2
	
	Note $oName1, "KSTest D:" + num2str(dKS)
	Note $oName2, "KSTest D:" + num2str(dKS)
	
	Note $oName1, "KSTest Pks:" + num2str(KSprob)
	Note $oName2, "KSTest Pks:" + num2str(KSprob)
	
	if (KSprob <= 0.05)
		txt="different populations"
	else
		txt="same population"
	endif
	
	Note $oName1, "KSTest Results:" + txt
	Note $oName2, "KSTest Results:" + txt
	
	WaveStats /Q/Z $wName1
	params[0] = V_min-2
	params[1]=V_max+2
	
	WaveStats /Q/Z $wName2
	params[2] = V_min-2
	params[3]=V_max+2
	
	WaveStats /Q/Z params
	
	Histogram /B={V_min,((V_max-V_min)/bins),bins} $wName1, $oName1
	KSMakeCumulative(oName1)
	
	Histogram /B={V_min,((abs(V_max-V_min))/bins),bins} $wName2, $oName2
	KSMakeCumulative(oName2)
	
	Wave wtemp = $oName1
	
	WaveStats /Q/Z wtemp
	wtemp /= V_max // normalize
	
	Wave wtemp = $oName2
	
	WaveStats /Q/Z wtemp
	wtemp /= V_max // normalize
	
	Display /K=1/N=$gName $oName1, $oName2 as gtitle
	Label bottom xl
	Label left yl
	ModifyGraph mode=3,marker($oName1)=8,marker($oName2)=6,rgb($oName2)=(0,0,0)
	Textbox/N=text2/F=0/A=LT SKresults
	
	SetCascadeXY(gName)
	
	KillWaves /Z params
	
End // KSPlotCumulatives

//****************************************************************
//****************************************************************
//****************************************************************

Function KSMakeCumulative(inputwave)
	String inputwave

	Wave inwave = $inputwave
	
	Variable i, isum
	Variable npnts = numpnts($inputwave)
	
	Duplicate /O $inputwave tempculm
	
	for (i = 0; i < npnts;i += 1)
		isum += tempculm[i]
		inwave[i] = isum
	endfor
	
	KillWaves /Z tempculm
	
End // KSMakeCumulative

//****************************************************************
//****************************************************************
//****************************************************************

