#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Main Tab Functions 
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	NM tab entry "Main"
//
//	Note, most functions on this tab call utility
//	functions in "NM_Utility.ipf".
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S MainPrefix(objName)
	String objName
	
	return "MN_" + objName
	
End // MainPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S MainDF() // return Main full-path folder name

	return PackDF("Main")
	
End // MainDF

//****************************************************************
//****************************************************************
//****************************************************************

Function MainTab(enable)
	Variable enable // (0) disable (1) enable tab
	
	if (enable == 1)
		CheckPackage("Main", 0) // declare folder/globals if necessary
		MakeMainTab() // create controls if necessary
		ChanControlsDisable(-1, "000000")
	endif

End // MainTab

//****************************************************************
//****************************************************************
//****************************************************************

Function MainConfigs()
	String fname = "Main"

	NMConfigVar(fname, "Bsln_Method", 1, "(1) subtract wave's individual mean (2) subtract mean of all waves")
	NMConfigVar(fname, "Bsln_Bgn", 0, "Baseline window begin (ms)")
	NMConfigVar(fname, "Bsln_End", 10, "Baseline window end (ms)")
	
End // MainConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function KillMain(what)
	String what
	String df = MainDF()
	
	strswitch(what)
	
		case "waves":
			KillGlobals(GetDataFolder(1), "Avg*", "001")
			KillGlobals(GetDataFolder(1), "Sum*", "001")
			break
			
		case "folder":
			if (DataFolderExists(df) == 1)
				KillDataFolder $df
			endif
			break
			
	endswitch

End // KillMain

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckMain()
	
	String df = MainDF()
	
	if (DataFolderExists(df) == 0)
		return -1
	endif
	
	// nothing to check
	
	return 0
	
End // CheckMain

//****************************************************************
//****************************************************************
//****************************************************************

Function MakeMainTab() // create Main tab controls
	Variable x0 = 40, xinc = 120, y0 = 190, yinc = 45, fs = NMPanelFsize()
	Variable taby = NMPanelTabY()
	
	y0 = taby + 50

	ControlInfo /W=NMPanel $MainPrefix("Plot")
	
	if (V_Flag != 0) 
		return 0 // main tab controls already exist
	endif
	
	DoWindow /F NMPanel // bring NMPanel to front
	
	Button $MainPrefix("Plot"), pos={x0,y0}, title = "Plot", size={100,20}, proc=MainTabButton, fsize=fs, win=NMpanel
	Button $MainPrefix("Copy"), pos={x0+xinc,y0}, title = "Copy", size={100,20}, proc=MainTabButton, fsize=fs, win=NMpanel
	
	Button $MainPrefix("Baseline"), pos={x0,y0+1*yinc}, title="Baseline", size={100,20}, proc=MainTabButton, fsize=fs, win=NMpanel
	Button $MainPrefix("Average"), pos={x0+xinc,y0+1*yinc}, title="Average", size={100,20}, proc=MainTabButton, fsize=fs, win=NMpanel
	
	Button $MainPrefix("YScale"), pos={x0,y0+2*yinc}, title="Scale", size={100,20}, proc=MainTabButton, fsize=fs, win=NMpanel
	Button $MainPrefix("XAlign"), pos={x0+xinc,y0+2*yinc}, title="Align", size={100,20}, proc=MainTabButton, fsize=fs, win=NMpanel
	
	Button $MainPrefix("ReOrder"), pos={x0+xinc/2,y0+3*yinc}, title="Order Waves", size={100,20}, proc=MainTabButton, fsize=fs, win=NMpanel
	
	y0 += 210
	
	GroupBox $MainPrefix("Group"), title = "More...", pos={x0-20,y0-35}, size={260,130}, fsize=fs, win=NMpanel
	
	PopupMenu $MainPrefix("DisplayMenu"), pos={x0+100,y0+0*yinc}, size={0,0}, bodyWidth=100, fsize=fs, proc=MainTabPopup, win=NMpanel
	PopupMenu $MainPrefix("DisplayMenu"), value="Display;---;Plot ;Table;XLabel;YLabel;Print Names;Print Notes;Order Waves;", win=NMpanel
	
	PopupMenu $MainPrefix("EditMenu"), pos={x0+100+xinc,y0+0*yinc}, size={0,0}, bodyWidth=100, fsize=fs, proc=MainTabPopup, win=NMpanel
	PopupMenu $MainPrefix("EditMenu"), value="Edit;---;Copy;Rename;Kill;", win=NMpanel
	
	PopupMenu $MainPrefix("TScaleMenu"), pos={x0+100,y0+1*yinc}, size={0,0}, bodyWidth=100, fsize=fs, proc=MainTabPopup, win=NMpanel
	PopupMenu $MainPrefix("TScaleMenu"), value="Time Scale;---;Align;Time Begin;Time Step;Resample;Decimate;Interpolate;Redimension;XLabel;Xwave;---;Continuous;Episodic;---;sec;msec;usec;", win=NMpanel
	
	PopupMenu $MainPrefix("FxnMenu"), pos={x0+100+xinc,y0+1*yinc}, size={0,0}, bodyWidth=100, fsize=fs, proc=MainTabPopup, win=NMpanel
	PopupMenu $MainPrefix("FxnMenu"), value="Operations;---;Scale by Num;Scale by Wave;Baseline;Normalize;Smooth;Blank;Integrate;Differentiate;2-Differentiate;Reverse;Sort;Delete NANs;NAN > 0;0 > Nan;---;Average;Sum;Concatenate;2D wave;IV;", win=NMpanel
	
End // MakeMainTab

//****************************************************************
//****************************************************************
//****************************************************************

Function MainTabPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu $ctrlName, win=NMpanel, mode=1 // force menus back to title
		
	NMMainCall(popStr)
			
End // MainTabPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function MainTabButton(ctrlName) : ButtonControl
	String ctrlName
	
	NMMainCall(ctrlName[3,inf])

End // MainTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainCall(fxn)
	String fxn
	String df = MainDF()
	String outList = ""
	
	if (CheckCurrentFolder() == 0)
		return ""
	endif
	
	if (ChanWavesCount(-1) <= 0)
		DoAlert 0, "No waves selected!"
		return ""
	endif
	
	strswitch(fxn)
	
		// Display Functions
		
		case "Plot":
		case "Graph":
			return NMPlotCall(StrVarOrDefault(df+"PlotColor", "rainbow"))
			
		case "Plot ":
			return NMPlotCall("")
		
		case "Plot Black":
			return NMPlotCall("black")

		case "Plot Red":
			return NMPlotCall("red")
			
		case "Rainbow":
		case "Plot Rainbow":
			return NMPlotCall("rainbow")
			
		case "Edit":
		case "Table":
			return NMEditWavesCall()
		
		case "Names":
		case "List Names":
		case "Print Names":
			outList = NMPrintWaveListCall()
			break
			
		case "Notes":
		case "Print Notes":
			outList = NMPrintWaveNotesCall()
			break
			
		case "XLabel":
		case "Time Label":
			outList = NMXLabelCall()
			break
			
		case "YLabel":
			outList = NMYLabelCall()
			break
		
		// Edit Functions
			
		case "Copy":
		case "Copy To":
			outList = NMCopyWavesToCall()
			break
			
		case "Kill":
		case "Delete":
			outList = NMDeleteWavesCall()
			break
			
		case "Rename":
			outList = NMRenameWavesCall("Selected")
			break
			
		//case "Renumber":
		//	return NMRenumWavesCall()
			
		// Time Scale Functions
		
		case "Xwave":
			return NMXwaveCall()
		
		case "Align":
		case "XAlign":
			outList = NMAlignWavesCall()
			break
			
		case "Time Begin":
			outList = NMStartXCall()
			break
		
		case "Delta":
		case "Time Step":
			outList = NMDeltaXCall()
			break
			
		case "Redimension":
			outList = NMNumPntsCall()
			break
			
		case "Resample":
			outList = NMResampleWavesCall()
			break
			
		case "Decimate":
			outList = NMDecimate2DeltaXCall()
			break
			
		case "Interpolate":
			outList = NMInterpolateWavesCall()
			break
			
		case "Reverse":
		case "Reflect":
			outList = NMReverseWavesCall()
			break
			
		case "Sort":
			NMSortWavesByKeyWaveCall()
			break
			
		case "Continuous":
			return NMTimeScaleModeCall(1)
		
		case "Episodic":
			return NMTimeScaleModeCall(0)
			
		case "sec":
		case "msec":
		case "usec":
			return NMXUnitsChangeCall("x", fxn)
			
		// Operations
		
		case "Baseline":
			outList = NMBaselineCall()
			break
		
		case "YScale":
			outList = NMScaleWaveCall()
			break
		
		case "Scale By Num":
		case "Scale By Number":
			outList = NMScaleWaveCall()
			break
			
		case "Scale By Wave":
			outList = NMScaleByWaveCall()
			break
			
		case "Normalize":
			outList = NMNormalizeWavesCall()
			break
			
		case "Blank":
			NMBlankWavesCall()
			return ""
			
		case "d/dt":
		case "Differentiate":
			outList = NMDiffWavesCall(1)
			break
			
		case "dd/dt*dt":
		case "2-Differentiate":
			outList = NMDiffWavesCall(2)
			break
			
		case "integral":
		case "Integrate":
			outList = NMDiffWavesCall(3)
			break
			
		case "Smooth":
			outList = NMSmoothWavesCall()
			break
			
		case "Delete NANs":
			outList = NMDeleteNANsCall()
			break
			
		case "NAN > 0":
			outList = NMReplaceNanZeroCall(1)
			break
			
		case "0 > Nan":
			outList = NMReplaceNanZeroCall(-1)
			break
			
		// Misc Functions
			
		case "Average":
			outList = NMAvgWavesCall()
			break
			
		case "Sum":
			outList = NMSumWavesCall()
			break
		
		case "IV":
			return NMIVCall()
			
		case "Concat":
		case "Concatenate":
			outList = NMConcatWavesCall()
			break
			
		case "2D Wave":
			outList = NM2DWaveCall()
			break
		
		case "ReOrder":
		case "Order Waves":
			NMOrderWavesCall()
			break

	endswitch
	
	if (ItemsInList(outList) == 0)
		//DoAlert 0, "Alert: no waves passed through \"" + fxn + "\" function."
	endif
	
End // NMMainCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainHistory(mssg, chanNum, wavList, namesFlag)
	String mssg
	Variable chanNum
	String wavList
	Variable namesFlag // (0) no (1) yes, print wave names
	
	String wSelect = NMWaveSelectGet()
	
	strswitch(wSelect)
		case "This Wave":
			wSelect = "Wave " + num2str(NumVarOrDefault("CurrentWave", 0))
			break
	endswitch
	
	if (strlen(mssg) == 0)
		mssg = "Chan " + ChanNum2Char(chanNum) + " : " + wSelect + " : N = " + num2str(ItemsInlist(wavList))
	else
		mssg += " : Chan " + ChanNum2Char(chanNum) + " : " + wSelect + " : N = " + num2str(ItemsInlist(wavList))
	endif
	
	if (namesFlag == 1)
		mssg += " : " + wavList
	endif
	
	NMHistory(mssg)
	
	return mssg

End // NMMainHistory

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintWaveListCall()
	
	if (NMAllGroups() == 1)
		NMCmdHistory("NMPrintGroupWaveList", "")
		return NMPrintGroupWaveList()
	else
		NMCmdHistory("NMPrintWaveList", "")
		return NMPrintWaveList()
	endif

End // NMPrintWaveListCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintGroupWaveList()
	Variable gcnt
	String gList, wList = ""
	
	String saveSelect = NMWaveSelectGet()
	String grpList = NMGroupList(1)
		
	for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
		NMWaveSelect(StringFromList(gcnt, grpList))
		gList = NMPrintWaveList()
		wList += gList
	endfor
	
	NMWaveSelect(saveSelect)
	
	return wList

End // NMPrintGroupWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintWaveList()
	Variable ccnt, wcnt
	String cList, wList = ""
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1)
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		cList = NMChanWaveList(ccnt)
		wList += cList
		
		NMMainHistory("", ccnt, cList, 0)
		NMHistory(cList)
		
		//for (wcnt = 0; wcnt < ItemsInList(cList); wcnt += 1)
		//	NMHistory(StringFromList(wcnt, cList))
		//endfor

	endfor
	
	return wList

End // NMPrintWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintWaveNotesCall()

	NMCmdHistory("NMPrintWaveNotes", "")
	return NMPrintWaveNotes()

End // NMPrintWaveNotesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintWaveNotes()
	Variable ccnt, wcnt
	String wName, cList = "", wList = ""
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		for (wcnt = 0; wcnt < NMNumWaves(); wcnt += 1) // loop thru waves
		
			wName = NMWaveSelected(ccnt, wcnt)
			
			if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			NMHistory("\r" + wName + " Notes:\r" + note($wName))
			
			cList = AddListItem(wName, cList, ";", inf)
			
		endfor
		
		wList += cList

	endfor
	
	return wList

End // NMPrintWaveNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDiffWavesCall(dtFlag)
	Variable dtFlag
	
	String df = MainDF()
	
	if (dtFlag < 0)
		dtFlag = NumVarOrDefault(df+"dtFlag", 1)
	endif
	
	switch(dtFlag)
		case 1:
		case 2:
		case 3:
			break
		default:
			dtFlag = 1
	endswitch
		
	Prompt dtFlag, "choose operation:", popup "d/dt;dd/dt*dt;integrate"
	DoPrompt NMPromptStr("Differentiate/Integrate"), dtFlag
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMvar(df+"dtFlag", dtFlag)
	
	NMCmdHistory("NMDiffWaves", NMCmdNum(dtFlag,""))
	
	return NMDiffWaves(dtFlag)

End // NMDiffWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDiffWaves(dtFlag)
	Variable dtFlag // (1) d/dt (2) dd/dt*dt (3) integral
	
	Variable ccnt
	String fxn, cList, wList = ""
	
	switch(dtFlag)
		case 1:
			fxn = "d/dt"
			break
		case 2:
			fxn = "dd/dt*dt"
			break
		case 3:
			fxn = "integrate"
			break
		default:
			DoAlert 0, "Abort NMDiffWaves : bad function parameter"
			return ""
	endswitch
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = DiffWaves(cList, dtFlag) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory(fxn, ccnt, cList, 0)
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMDiffWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeleteWavesCall()

	NMCmdHistory("NMDeleteWaves", "")

	return NMDeleteWaves()

End // NMDeleteWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeleteWaves()
	Variable ccnt
	String cList, wList = "", df = NMDF()
	
	if (NumVarOrDefault(df+"NMDeleteWavesNoAlert", 0) == 1)
	
		SetNMvar(df+"NMDeleteWavesNoAlert", 0) // reset flag
	
	else
	
		DoAlert 1, "Warning: NMDeleteWaves will attempt to permanently delete all of your currently selected waves. Do you want to continue?"
		
		if (V_Flag != 1)
			return "" // cancel
		endif
	
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = DeleteWaves(cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Deleted", ccnt, cList, 0)
		
	endfor
	
	//NMPrefixSelect( "" )
	ChanGraphsUpdate()
	
	return wList

End // NMDeleteWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeleteNANsCall()

	DoAlert 1, "Delete NAN's from selected waves?"
	
	if (V_flag != 1)
		return ""
	endif

	NMCmdHistory("NMDeleteNANs", "")

	return NMDeleteNANs()

End // NMDeleteNANsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeleteNANs()

	Variable ccnt, wcnt, error
	String wname, cList = "", wList = "", badList = ""
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1)
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		for (wcnt = 0; wcnt < NMNumWaves(); wcnt += 1)
		
			wName = NMWaveSelected(ccnt, wcnt)
			
			if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
				continue // wave not selected, or does not exist... go to next wave
			endif
		
			error = DeleteNANs(wname, "U_TempWave", 0) // NM_Utility.ipf
			
			if ((error == 0) && (WaveExists(U_TempWave) == 1))
				Duplicate /O U_TempWave $wname
				cList = AddListItem(wName, cList, ";", inf)
			else
				badList = AddListItem(wName, badList, ";", inf)
			endif
			
		endfor
		
		NMMainHistory("Deleted NANs", ccnt, cList, 0)
		
		wList += cList
		
	endfor
	
	ChanGraphsUpdate()
	
	KillWaves /Z U_TempWave
	
	return wList

End // NMDeleteNANs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReplaceNanZeroCall(direction)
	Variable direction
	
	if (direction == 1)
		DoAlert 1, "Replace NAN's with 0's in selected waves?"
	elseif (direction == -1)
		DoAlert 1, "Replace 0's with NAN's in selected waves?"
	else
		return ""
	endif
	
	if (V_flag != 1)
		return ""
	endif

	NMCmdHistory("NMReplaceNanZero", NMCmdNum(direction, ""))

	return NMReplaceNanZero(direction)

End // NMReplaceNanZeroCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReplaceNanZero(direction)
	Variable direction // (1) Nan > 0 (-1) 0 > Nan
	
	Variable ccnt, wcnt, error
	String wname, cList = "", wList = ""
	
	if ((direction != 1) && (direction != -1))
		return ""
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		for (wcnt = 0; wcnt < NMNumWaves(); wcnt += 1) // loop thru waves
		
			wName = NMWaveSelected(ccnt, wcnt)
			
			if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			Wave wtemp = $wname
			wtemp = Nan2Zero(wtemp) // NM_Utility.ipf
			cList = AddListItem(wName, cList, ";", inf)
			
		endfor
		
		wList += cList
		
		switch(direction)
			case 1:
				NMMainHistory("Converted NANs > 0s", ccnt, cList, 0)
				break
			case -1:
				NMMainHistory("Converted 0s > NANs", ccnt, cList, 0)
				break
		endswitch
		
	endfor
	
	return wList

End // NMReplaceNanZero

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWavesCall()
	String wList, vList = "", df = MainDF()
	
	String cPrefix = NMCurrentWavePrefix()
	String newPrefix = StrVarOrDefault(df+"CopyPrefix", "C_")
	
	Variable tbgn = NumVarOrDefault(df+"CopyTbgn", -inf)
	Variable tend = NumVarOrDefault(df+"CopyTend", inf)
	Variable select = 1 + NumVarOrDefault(df+"CopySelect", 1)
	
	Prompt newPrefix, "enter new prefix name to attach to copied waves:"
	Prompt tbgn, "copy source waves from (ms):"
	Prompt tend, "copy source waves to (ms):"
	Prompt select, "select as current waves?", popup "no;yes;"
	
	DoPrompt NMPromptStr("Copy"), newPrefix, tbgn, tend, select
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	select -= 1
	
	wList = WaveList(newPrefix + cPrefix + "*", ";", "")
	
	if (ItemsInList(wList) > 0)
		DoAlert 0, "Abort NMCopyWaves: waves with prefix name \"" + newPrefix + cPrefix + "\" already exist in this folder. Please choose a different prefix."
		return ""
	endif
	
	SetNMstr(df+"CopyPrefix", newPrefix)
	SetNMvar(df+"CopyTbgn", tbgn)
	SetNMvar(df+"CopyTend", tend)
	SetNMvar(df+"CopySelect", select)
	
	vList = NMCmdStr(newPrefix, vList)
	vList = NMCmdNum(tbgn, vList)
	vList = NMCmdNum(tend, vList)
	vList = NMCmdNum(select, vList)
	
	NMCmdHistory("NMCopyWaves", vList) 
	
	return NMCopyWaves(newPrefix, tbgn, tend, select)
	
End // NMCopyWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWaves(newPrefix, tbgn, tend, select)
	String newPrefix // new wave prefix
	Variable tbgn, tend // copy data from, to
	Variable select // select as current prefix (0) no (1) yes
	
	Variable ccnt
	String cList, wList = ""
	
	String cPrefix = NMCurrentWavePrefix()
	
	if (StringMatch(newPrefix, cPrefix) == 1)
		DoAlert 0, "Abort NMCopyWaves : this function is not to over-write currently active waves."
		return ""
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = CopyWaves(newPrefix, tbgn, tend, cList) // NM_Utility.ipf
		wList += cList
	
		NMMainHistory("Copied to " + newPrefix + "*", ccnt, cList, 0)
		
	endfor
	
	if (ItemsInList(wList) > 0)
	
		NMPrefixAdd(newPrefix + cPrefix)
		
		if (select == 1)
			NMPrefixSelectSilent(newPrefix + cPrefix)
		endif
		
	endif
	
	return wList
	
End // NMCopyWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWavesToCall()

	String fList, wList, vList = "", df = MainDF()
	
	String cPrefix = NMCurrentWavePrefix()
	
	String newPrefix = StrVarOrDefault(df+"Copy2Prefix", "C_")
	Variable tbgn = NumVarOrDefault(df+"Copy2Tbgn", -inf)
	Variable tend = NumVarOrDefault(df+"Copy2Tend", inf)
	String toFolder = StrVarOrDefault(df+"Copy2Folder", "this folder")
	Variable select = 1 + NumVarOrDefault(df+"Copy2Select", 1)
	
	fList = NMDataFolderList()
	fList = RemoveFromList(GetDataFolder(0), fList)
	
	fList = "This Folder;" + fList
	
	Prompt newPrefix, "new prefix for copied waves:"
	Prompt tbgn, "copy from time (ms):"
	Prompt tend, "copy to time (ms):"
	Prompt toFolder, "copy selected waves to:", popup fList
	Prompt select, "select as current waves?", popup "no;yes;"
	
	DoPrompt NMPromptStr("Copy"), newPrefix, tbgn, tend, toFolder, select
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	select -= 1
	
	SetNMstr(df+"Copy2Prefix", newPrefix)
	SetNMvar(df+"Copy2Tbgn", tbgn)
	SetNMvar(df+"Copy2Tend", tend)
	SetNMstr(df+"Copy2Folder", toFolder)
	SetNMvar(df+"Copy2Select", select)
	
	if (StringMatch(toFolder, "this folder") == 1)
		toFolder = ""
	elseif (StringMatch(toFolder[0,3], "root") == 0)
		toFolder = "root:" + toFolder
	endif
	
	wList = WaveListFolder(toFolder, newPrefix + cPrefix + "*", ";", "")
	
	if (ItemsInList(wList) > 0)
		if (strlen(toFolder) == 0)
			toFolder = GetDataFolder(0)
		endif
		DoAlert 0, "Abort NMCopyWavesTo: waves with that prefix name \"" + newPrefix + cPrefix + "\" already exist in folder \"" + toFolder + "\". Please choose a different prefix."
		return ""
	endif
	
	vList = NMCmdStr(toFolder, "")
	vList = NMCmdStr(newPrefix, vList)
	vList = NMCmdNum(tbgn, vList)
	vList = NMCmdNum(tend, vList)
	vList = NMCmdNum(1, vList)
	vList = NMCmdNum(select, vList)
	NMCmdHistory("NMCopyWavesTo", vList)
	
	return NMCopyWavesTo(toFolder, newPrefix, tbgn, tend, 1, select)
	
End // NMCopyWavesToCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWavesTo(toFolder, newPrefix, tbgn, tend, alert, select)
	String toFolder // where to copy selected waves, ("") for current folder
	String newPrefix // new wave prefix, ("") for current prefix
	Variable tbgn, tend // copy data from, to
	Variable alert // (0) no copy alert (1) alert if over-writing
	Variable select // select as current prefix (0) no (1) yes
	
	Variable ccnt
	String txt, cList, wList = ""
	
	String cPrefix = NMCurrentWavePrefix()
	
	String thisFolder = GetDataFolder(1)
	
	if (strlen(toFolder) == 0)
		toFolder = GetDataFolder(1)
	endif
	
	if (DataFolderExists(toFolder) == 0)
		DoAlert 0, "NMCopyWavesTo Error: folder does not exist: " + toFolder
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = CopyWavesTo(thisFolder, toFolder, newPrefix, tbgn, tend, cList, alert) // NM_Utility.ipf
		wList += cList
		
		//NMHistory("Copied to " + newPrefix + "* : " + NMMainHistory(ccnt, cList))

	endfor
	
	if (ItemsInList(wList) > 0)
	
		if (strlen(newPrefix) > 0)
			NMPrefixAdd(newPrefix + cPrefix)
		endif
		
		if (select == 1)
			if (StringMatch(thisFolder, toFolder) == 0)
				NMFolderChange(toFolder)
			endif
			NMPrefixSelectSilent(newPrefix + cPrefix)
		endif
		
	endif
	
	return wList
	
End // NMCopyWavesTo

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenameWavesCall(select)
	String select // ("All") search all waves ("Selected" or "") search selected waves
	
	String ptitle = "", vList = "", df = MainDF()
	
	String findstr = StrVarOrDefault(df+"RenameFind", "")
	String repstr = StrVarOrDefault(df+"RenameReplace", "")
	
	Prompt findstr, "search string:"
	Prompt repstr, "replace string:"
	
	strswitch(select)
		case "All":
			ptitle = "Rename Waves : folder " + GetDataFolder(0)
			break
		case "":
		case "Wave Select":
		case "Selected":
			ptitle = NMPromptStr("Rename Waves")
			break
		default:
			return ""
	endswitch
	
	DoPrompt ptitle, findstr, repstr
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"RenameSelect", select)
	SetNMstr(df+"RenameFind", findstr)
	SetNMstr(df+"RenameReplace", repstr)
	
	vList = NMCmdStr(findstr, vList)
	vList = NMCmdStr(repstr, vList)
	vList = NMCmdStr(select, vList)
	NMCmdHistory("NMRenameWaves", vList)
	
	return NMRenameWaves(findstr, repstr, select)

End // NMRenameWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenameWaves(findstr, repstr, select)
	String findstr, repstr // find string, replace string
	String select // ("All") search all waves ("Selected" or "") search selected waves
	
	Variable ccnt
	String cList, wList = ""
	
	if (strlen(findstr) <= 0)
		DoAlert 0, "Abort NMRenameWaves : bad search string parameter."
		return ""
	endif
	
	strswitch(select)
	
		case "All":
			wList = RenameWaves(findstr, repstr, WaveList("*",";","")) // NM_Utility.ipf
			NMHistory("Renamed \"" + findstr + "*\" waves to : " + wList)
			return wList
			
		case "":
		case "Wave Select":
		case "Selected":
	
			for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
				if (NMChanSelected(ccnt) != 1)
					continue // channel not selected
				endif
			
				cList = NMChanWaveList(ccnt)
				
				if (strlen(cList) == 0)
					continue
				endif
				
				cList = RenameWaves(findstr, repstr, cList) // NM_Utility.ipf
				wList += cList
				
				NMMainHistory("Renamed *" + findstr + "* waves to *" + repstr + "*", ccnt, cList, 0)
			
			endfor
			
			break
			
		default:
		
			DoAlert 0, "Abort NMRenameWaves : bad wave select parameter."
			return ""
	
	endswitch
	
	if (strlen(wList) > 0)
		DoAlert 0, "Alert: renamed waves may no longer be recognized by NeuroMatic. Use wave prefix popup to select appropriate waves."
	endif
	
	return wList

End // NMRenameWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenumWavesCall()
	String vList = "", df = MainDF()

	Variable from = NumVarOrDefault(df+"RenumFrom", 0)
	
	Prompt from, "renumber selected waves from:"
	DoPrompt NMPromptStr("Renumber Waves"), from
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMvar(df+"RenumFrom", from)
	
	vList = NMCmdNum(from, vList)
	vList = NMCmdNum(1, vList)
	NMCmdHistory("NMRenumWaves", vList)
	
	return NMRenumWaves(from, 1)

End // NMRenumWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenumWaves(from, alert)
	Variable from // start sequence number
	Variable alert // (0) no (1) yes
	
	Variable ccnt
	String cList, wList = ""
	
	DoAlert 0, "Alert: NMRenumWaves has been deprecated."
	
	return ""
	
	if ((from < 0) || (numtype(from) > 0))
		DoAlert 0, "Abort NMRenumWaves : bad sequence number parameter."
		return ""
	endif
	
	for (ccnt = 0; ccnt <  NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = RenumberWaves(from, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Renumbered waves from " + num2str(from), ccnt, cList, 0)
	
	endfor
	
	if (alert == 1)
		DoAlert 0, "Alert: renumbered waves may no longer be recognized by NeuroMatic. Use wave prefix popup to select appropriate waves."
	endif
	
	return wList

End // NMRenumWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSmoothWavesCall()
	String vList = "", df = MainDF()
	
	String smthAlg = ChanSmthAlgGet(-1)
	Variable smthNum = ChanSmthNumGet(-1)
	
	smthNum = NumVarOrDefault(df+"SmoothNum", smthNum)
	
	Prompt smthAlg, "choose smoothing algorithm:", popup "binomial;boxcar;polynomial"
	Prompt smthNum, "number of smoothing points/operations:"
	
	DoPrompt NMPromptStr("Smooth"), smthAlg, smthNum
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"SmoothAlg", smthAlg)
	SetNMvar(df+"SmoothNum", smthNum)
	
	vList = NMCmdStr(smthAlg, vList)
	vList = NMCmdNum(smthNum, vList)
	NMCmdHistory("NMSmoothWaves", vList)
	
	return NMSmoothWaves(smthAlg, smthNum)
	
End // NMSmoothWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSmoothWaves(smthAlg, avgN)
	String smthAlg // "binomial", "boxcar" or "polynomial"
	Variable avgN
	
	Variable ccnt
	String cList, wList = ""
	
	strswitch(smthAlg)
		case "binomial":
		case "boxcar":
		case "polynomial":
		break
		default:
			DoAlert 0, "Abort NMSmoothWaves : bad method string."
			return ""
	endswitch
	
	if ((avgN < 1) || (numtype(avgN) != 0))
		DoAlert 0, "Abort NMSmoothWaves : number of points must be greater than zero."
		return ""
	endif
	
	if ((StringMatch(smthAlg, "polynomial") == 1) && ((avgN < 5) || (avgN > 25)))
		DoAlert 0, "Abort NMSmoothWaves : number of points must be greater than 5 and less than 25 for polynomial smoothing."
		return ""
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = SmoothWaves(smthAlg, avgN, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Smoothed " + num2str(avgN) + " pnt(s) " + smthAlg, ccnt, cList, 0)
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMSmoothWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMResampleWavesCall()

	String vlist = "", df = MainDF()
	
	Variable dx = GetXStats("deltax", NMChanWaveList(-1))
	
	Variable upPnts = 1
	Variable downPnts = 1
	Variable oldrate = 1/dx
	Variable rate = oldrate
	
	Prompt upPnts, "resample UP by x number of points: "
	Prompt downPnts, "resample DOWN by x number of points: "
	Prompt rate, "or specify a new sample rate (kHz): "
	DoPrompt NMPromptStr("Resample"), upPnts, downPnts, rate
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	if ((upPnts > 1) || (downPnts > 1))
		rate = Nan
	elseif (rate == oldrate)
		return ""
	endif
	
	vList = NMCmdNum(rate, vList)
	vList = NMCmdNum(upPnts, vList)
	vList = NMCmdNum(downPnts, vList)
	NMCmdHistory("NMResampleWaves", vList)
	
	return NMResampleWaves(upPnts, downPnts, rate)

End // NMResampleWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMResampleWaves(upPnts, downPnts, rate)
	Variable upPnts // interpolate points
	Variable downPnts // decimate points
	Variable rate // kHz
	
	Variable ccnt, rateflag
	String cList, wList = ""
	
	if ((numtype(rate) == 0) && (rate > 0))
		rateflag = 1
		upPnts = 1
		downPnts = 1
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = ResampleWaves(upPnts, downPnts, rate, cList) // NM_Utility.ipf
		wList += cList
		
		if (rateflag == 1)
			NMMainHistory("Resampled " + num2str(rate) + " kHz", ccnt, cList, 0)
		else
			NMMainHistory("Resampled " + num2str(upPnts) + " upPnts, " + num2str(downPnts)  + " downPnts", ccnt, cList, 0)
		endif
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMResampleWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDecimateWavesCall()
	String df = MainDF()
	
	Variable ipnts = NumVarOrDefault(df+"DecimateN", 4)
	
	Prompt ipnts, "decimate waves by x number of points: "
	DoPrompt NMPromptStr("Decimate"), ipnts
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMvar(df+"DecimateN", ipnts)
	
	NMCmdHistory("NMDecimateWaves", NMCmdNum(ipnts,""))
	
	return NMDecimateWaves(ipnts)

End // NMDecimateWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDecimateWaves(ipnts)
	Variable ipnts // number of points
	
	Variable ccnt
	String cList, wList = ""
	
	if ((ipnts < 0) || (numtype(ipnts) != 0))
		DoAlert 0, "Abort NMDecimateWaves : bad number of points."
		return ""
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = DecimateWaves(ipnts, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Decimated " + num2str(ipnts) + " pnts", ccnt, cList, 0)
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMDecimateWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDecimate2DeltaXCall()
	
	String df = MainDF()
	
	Variable oldDelta = NumVarOrDefault("SampleInterval", 1)
	Variable newDelta = NumVarOrDefault(df+"DecimateDeltaX", oldDelta)
	
	Prompt newDelta, "new sample interval < " + num2str(oldDelta) + " : "
	DoPrompt NMPromptStr("Decimate Waves"), newDelta
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMvar(df+"DecimateDeltaX", newDelta)
	
	NMCmdHistory("NMDecimate2DeltaX", NMCmdNum(newDelta,""))
	
	return NMDecimate2DeltaX(newDelta)

End // NMDecimate2DeltaXCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDecimate2DeltaX(newDelta)
	Variable newDelta // new deltax
	
	Variable ccnt
	String cList, wList = ""
	
	if ((newDelta < 0) || (numtype(newDelta) != 0))
		DoAlert 0, "Abort NMDecimateWaves : bad sample interval."
		return ""
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = Decimate2DeltaX(newDelta, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Decimated to " + num2str(newDelta) + " sample interval", ccnt, cList, 0)
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMDecimate2DeltaX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMInterpolateWavesCall()
	String wList, vList = "", df = MainDF()
	
	Variable alg = NumVarOrDefault(df+"InterpAlg", 1)
	Variable xmode = NumVarOrDefault(df+"InterpXMode", 1)
	String xwave = StrVarOrDefault(df+"InterpXWave", "")
	
	wList = CurrentChanWaveList()
	
	Variable npnts = numpnts($StringFromList(0, wList)) // size of first selected wave
	
	wList = WaveListOfSize(npnts, "*")
	
	Prompt alg, "interpolation method: ", popup "linear;cubic spline;"
	Prompt xmode, "choose x-axis for interpolation:" popup "use common x-axis computed by NeuroMatic;use x-axis of a selected wave;use data values of a selected wave;"
	Prompt xwave, "select wave to supply data values for interpolation: ", popup wList
	
	DoPrompt NMPromptStr("Interpolate"), alg, xmode
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	switch(xmode)
		case 2:
			wList = WaveList("*", ";", "")
			Prompt xwave, "select wave to supply x-axis for interpolation: ", popup wList
		case 3:
			DoPrompt NMPromptStr("Interpolate"), xwave
	endswitch
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMvar(df+"InterpAlg", alg)
	SetNMvar(df+"InterpXMode", xmode)
	SetNMstr(df+"InterpXWave", xwave)
	
	vList = NMCmdNum(alg, vList)
	vList = NMCmdNum(xmode, vList)
	vList = NMCmdStr(xwave, vList)
	
	if (NMAllGroups() == 1)
		NMCmdHistory("NMInterpolateGroups", vList)
		return NMInterpolateGroups(alg, xmode, xwave)
	else
		NMCmdHistory("NMInterpolateWaves", vList)
		return NMInterpolateWaves(alg, xmode, xwave)
	endif

End // NMInterpolateWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMInterpolateGroups(alg, xmode, xwave)
	Variable alg // (1) linear (2) cubic spline
	Variable xmode // (1) find common x-axis (2) use x-axis scale of xwave (3) use values of xwave as x-scale
	String xwave // wave for xmode 2 or 3
	
	Variable gcnt
	String cList, wList = ""
	
	String saveSelect = NMWaveSelectGet()
	String grpList = NMGroupList(1)
		
	for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
		NMWaveSelect(StringFromList(gcnt, grpList))
		cList = NMInterpolateWaves(alg, xmode, xwave)
		wList += cList
	endfor
	
	NMWaveSelect(saveSelect)
	
	return wList

End // NMInterpolateGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMInterpolateWaves(alg, xmode, xwave)
	Variable alg // (1) linear (2) cubic spline
	Variable xmode // (1) find common x-axis (2) use x-axis scale of xwave (3) use values of xwave as x-scale
	String xwave // wave for xmode 2 or 3
	
	Variable ccnt
	String cList, wList = ""
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
			
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif

		cList = InterpolateWaves(alg, xmode, xwave, cList) // NM_Utility.ipf
		wList += cList

		if (xmode == 1)
			NMMainHistory("Interpolated to common x-axis", ccnt, cList, 0)
		elseif (xmode == 2)
			NMMainHistory("Interpolated to x-scale of " + xwave, ccnt, cList, 0)
		elseif (xmode == 3)
			NMMainHistory("Interpolated to data values of " + xwave, ccnt, cList, 0)
		endif
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMInterpolateWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlotCall(color)
	String color
	
	String gName, vList = "", df = MainDF()
	
	Variable samePlot = 1 + NumVarOrDefault(df+"GroupsSamePlot", 1)
	Variable xOffset = NumVarOrDefault(df+"PlotXoffset", 0)
	Variable yOffset = NumVarOrDefault(df+"PlotYoffset", 0)
	
	Prompt color, "choose wave color:", popup NMPlotColorList()
	Prompt samePlot, "plot all groups in the same plot?", popup "no;yes;"
	Prompt xOffset, "x-offset increment:"
	Prompt yOffset, "y-offset increment:"
	
	if (NMAllGroups() == 1)
	
		color = StrVarOrDefault(df+"PlotColor", "rainbow")
	
		DoPrompt "Plot All Groups", color, samePlot, xOffset, yOffset
		
		if (V_flag == 1)
			return "" // cancel
		endif
	
		samePlot -= 1
		
		SetNMvar(df+"GroupsSamePlot", samePlot)
		
		vList = NMCmdStr(color, vList)
		vList = NMCmdNum(samePlot, vList)
		vList = NMCmdNum(1, vList) // plot backwards
		vList = NMCmdNum(xOffset, vList)
		vList = NMCmdNum(yOffset, vList)
		
		NMCmdHistory("NMPlotGroups", vList)
		
		gName = NMPlotGroups(color, samePlot, 1, xOffset, yOffset)
		
	else
	
		if (strlen(color) == 0)
		
			color = StrVarOrDefault(df+"PlotColor", "rainbow")
		
			DoPrompt "Plot Waves", color, xOffset, yOffset
			
			if (V_flag == 1)
				return "" // cancel
			endif
			
		else
		
			xOffset = 0
			yOffset = 0
			
		endif
		
		vList = NMCmdStr(color, vList)
		vList = NMCmdNum(xOffset, vList)
		vList = NMCmdNum(yOffset, vList)
	
		NMCmdHistory("NMPlotOffset", vList)
		
		gName = NMPlotOffset(color, xOffset, yOffset)
		
	endif
	
	SetNMstr(df+"PlotColor", color)
	SetNMvar(df+"PlotXoffset", xOffset)
	SetNMvar(df+"PlotYoffset", yOffset)
	
	return gName

End // NMPlotCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlotGroups(color, samePlot, backwards, xOffset, yOffset)
	String color
	Variable samePlot // (0) no (1) yes
	Variable backwards // (0) no (1) yes
	Variable xOffset, yOffset
	
	Variable wcnt, gcnt, pcnt, chan, cnum, gxoffset, gyoffset
	
	String saveSelect = NMWaveSelectGet()
	String gName, wList, plotList = "", grpList = NMGroupList(1)
	String xwave = NMXwave()
	
	String colorList = "red;blue;green;purple;yellow;"
	
	if (samePlot == 0)
		
		for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
			NMWaveSelect(StringFromList(gcnt, grpList))
			gName = NMPlotOffset(color, xOffset, yOffset)
			plotList = AddListItem(gName, plotList, ";", inf)
		endfor
		
	else
	
		if (backwards == 1)
			grpList = ReverseList(grpList, ";")
		endif
	
		NMWaveSelect(StringFromList(0, grpList))
		plotList = NMPlotOffset("black", gxoffset, gyoffset)
		
		for (pcnt = 0; pcnt < ItemsInList(plotList); pcnt += 1)
		
			gName = StringFromList(pcnt, plotList)
			
			chan = ChanNumGet(gName)
			
			cnum = 0
		
			for (gcnt = 1; gcnt < ItemsInList(grpList); gcnt += 1)
			
				gxoffset += xOffset
				gyoffset += yOffset
			
				NMWaveSelect(StringFromList(gcnt, grpList))
				wList = NMChanWaveList(chan)
				color = StringFromList(cnum, colorList)
				NMPlotAppend(gName, color, xwave, wList, gxoffset, 0, gyoffset, 0)
				
				cnum += 1
			
				if (cnum >= ItemsInList(colorList))
					cnum = 0
				endif
				
			endfor
			
		endfor
	
	endif
	
	NMWaveSelect(saveSelect)
	
	return plotList

End // NMPlotGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlotColorList()

	return "rainbow;black;red;green;blue;purple;yellow;"

End // NMPlotColorList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlot(color)
	String color // "black", "red", "green", "blue", "yellow", "purple", or ("") default

	return NMPlotOffset(color, 0, 0)
	
End // NMPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlotOffset(color, xoffset, yoffset)
	String color // "black", "red", "green", "blue", "yellow", "purple", or ("") default
	Variable xoffset, yoffset
	
	Variable ccnt, error, r, g, b
	String xl, yl, cList, gPrefix, gName, gTitle, gList = "", df = MainDF()
	String xwave = NMXwave()
	
	String prefix = NMCurrentWavePrefix()
	
	if (strlen(color) == 0)
		color = StrVarOrDefault(df+"PlotColor", "rainbow")
	endif
	
	strswitch(color)
		case "red":
			r = 65535
			break
		case "yellow":
			r = 65535
			g = 65535
			break
		case "green":
			g = 65535
			break
		case "blue":
			b = 65535
			break
		case "purple":
			r = 65535
			b = 65535
			break
		case "rainbow":
			r = -1
			break
		default: // black
			r = 0
			g = 0
			b = 0
	endswitch
	
	SetNMstr(df+"PlotColor", color)

	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
			
		gPrefix = MainPrefix("") + NMFolderPrefix("") + NMWaveSelectStr() + "_Plot_"
		gName = NextGraphName(gPrefix, ccnt, NMOverWrite())
		gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : " + prefix + " : " + NMWaveSelectGet()

		cList = NMChanWaveList(ccnt)
		xl = ChanLabel(ccnt, "x", cList)
		yl = ChanLabel(ccnt, "y", cList)
		
		error = NMPlotWavesOffset(gName, gTitle, xl, yl, xwave, cList, xoffset, 1, yoffset, 1) // NM_Utility.ipf
		
		if (error == 0)
		
			if (ItemsInList(gList) == 0)
				gList = gName
			else
				gList += ";"
				gList = AddListItem(gName, gList, ";", inf)
			endif
			
			if (r == -1)
				GraphRainbow(gName)
			else
				ModifyGraph /W=$gName rgb=(r,g,b)
			endif
			
		endif
		
	endfor
	
	return gList

End // NMPlotOffset

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEditWavesCall()
	
	if (NMAllGroups() == 1)
		NMCmdHistory("NMEditGroups", "")
		return NMEditGroups()
	else
		NMCmdHistory("NMEditWaves", "")
		return NMEditWaves()
	endif

End // NMEditWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEditGroups()
	Variable gcnt
	String tList, wList = ""
	
	String saveSelect = NMWaveSelectGet()
	String grpList = NMGroupList(1)
		
	for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
		NMWaveSelect(StringFromList(gcnt, grpList))
		tlist = NMEditWaves()
		wList += tlist
	endfor
	
	NMWaveSelect(saveSelect)
	
	return wList

End // NMEditGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEditWaves()
	Variable ccnt, error
	String tPrefix, tName, tTitle, cList, tList = ""
	
	String prefix = NMCurrentWavePrefix()
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
			
		tPrefix = MainPrefix("") + NMFolderPrefix("") + NMWaveSelectStr() + "_Table_"
		tName = NextGraphName(tPrefix, ccnt, NMOverWrite())
		tTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : " + prefix + " : " + NMWaveSelectGet()
		
		cList = NMChanWaveList(ccnt)

		error = EditWaves(tName, tTitle, cList) // NM_Utility.ipf
		
		if (error == 0)
			if (ItemsInList(tList) == 0)
				tList = tName
			else
				tList = AddListItem(tName, tList, ";", inf)
			endif
		endif
	
	endfor
	
	return tList

End // NMEditWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReverseWavesCall()

	DoAlert 1, "Reverse points of selected waves?"
	
	if (V_flag != 1)
		return ""
	endif

	NMCmdHistory("NMReverseWaves", "")
	
	return NMReverseWaves()

End // NMReverseWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReverseWaves()

	Variable ccnt, wcnt
	String cList, wList = ""
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		for (wcnt = 0; wcnt < ItemsInList(cList); wcnt += 1)
			Reverse /P $StringFromList(wcnt, cList)
		endfor
		
		//cList = ReverseWaves(cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Reversed", ccnt, cList, 0)
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMReverseWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSortWavesByKeyWaveCall()

	String df = NMDF(), keyWaveName = StrVarOrDefault(df+"SortByWName", "")
	String wList, wList2 = CurrentChanWaveList()
	
	Variable npnts = numpnts($StringFromList(0, wList2)) // size of first selected wave
	
	wList2 = " ;" + WaveListOfSize(npnts, "*")
	
	Prompt keyWaveName, "choose a wave of key values to sort selected wave(s) against:", popup wList2
	DoPrompt NMPromptStr("Sort Waves"), keyWaveName
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"SortByWName", keyWaveName)
	
	NMCmdHistory("NMSortWaves", NMCmdStr(keyWaveName, "") )

	return NMSortWavesByKeyWave(keyWaveName)

End // NMSortWavesByKeyWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSortWavesByKeyWave(keyWaveName)
	String keyWaveName // name of wave that
	
	Variable ccnt
	String cList, wList = ""
	
	if (WaveExists($keyWaveName) == 0)
		return ""
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = SortWavesByKeyWave(keyWaveName, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Sorted", ccnt, cList, 0)
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMSortWavesByKeyWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAlignWavesCall()
	Variable error

	String wList, vList = "", df = MainDF()
	
	String wname = StrVarOrDefault(df+"AlignWName", "")
	Variable postime = NumVarOrDefault(df+"AlignPosTime", 1)
	Variable intrp = NumVarOrDefault(df+"AlignInterp", 0)
	
	wList = WaveListOfSize(NumVarOrDefault("NumWaves",0), "!" + StrVarOrDefault("WavePrefix","") + "*")
	wList = RemoveFromList("WavSelect", wList)
	wList = RemoveFromList("Group", wList)
	wList = AddListItem(" ", wList, ";", -inf) // add space to beginning
	wList = RemoveListFromList(NMSetsList(1), wList, ";")

	postime += 1
	intrp += 1
	
	Prompt wname, "choose a wave of alignment values:", popup wList
	Prompt postime, "allow only positive time values?", popup "no;yes"
	Prompt intrp, "make alignments permanent by interpolation?", popup "no;yes"
	DoPrompt NMPromptStr("Time Scale Alignment"), wname, postime, intrp
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	postime -= 1
	intrp -= 1
	
	SetNMstr(df+"AlignWName", wname)
	SetNMvar(df+"AlignPosTime", postime)
	SetNMvar(df+"AlignInterp", intrp)

	vList = NMCmdStr(wname, vList)
	vList = NMCmdNum(postime, vList)
	NMCmdHistory("NMAlignWaves", vList)
	
	wList = NMAlignWaves(wname, postime)
	
	if (intrp == 1)
	
		vList = NMCmdNum(1, "")
		vList = NMCmdNum(1, vList)
		vList = NMCmdStr("", vList)
		
		NMCmdHistory("NMInterpolateWaves", vList)
		
		NMInterpolateWaves(1, 1, "")
		
	endif
	
	return wList

End // NMAlignWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAlignWaves(xwname, postime)
	String xwname // wave name of x align values
	Variable postime // allow only positive time values? (0) no (1) yes
	
	return NMXAlignWaves(xwname, postime)
	
End

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXAlignWaves(xwname, postime)
	String xwname // wave name of x align values
	Variable postime // allow only positive time values? (0) no (1) yes
	
	Variable ccnt, wcnt, error, offset, maxoffset
	String wName, cList = "", wList = "", badList = ""
	
	if (WaveExists($xwname) == 0)
		return ""
	endif
		
	Wave offsetWave = $xwname
		
	if (postime == 1)
		WaveStats /Q/Z offsetWave
		maxoffset = V_max
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		for (wcnt = 0; wcnt < NMNumWaves(); wcnt += 1) // loop thru waves
		
			wName = NMWaveSelected(ccnt, wcnt)
			
			if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
				continue // wave not selected, or does not exist... go to next wave
			endif
				
			if (postime == 1)
				offset = offsetWave[ChanWaveNum(wName)] - maxoffset
			else
				offset = offsetWave[ChanWaveNum(wName)]
			endif

			error = AlignByNum(offset, wName) // NM_Utility.ipf
			
			if (error == -1)
				badList = AddListItem(wName, badList, ";", inf)
			else
				cList = AddListItem(wName, cList, ";", inf)
			endif
		
		endfor
		
		wList += cList
			
		if (postime == 1)
			NMMainHistory("X-Aligned at " + num2str(maxoffset) + " ms (offset wave:" + xwname + ")", ccnt, cList, 0)
		else
			NMMainHistory("X-Aligned at 0 ms (offset wave:" + xwname + ")", ccnt, cList, 0)
		endif
		
	endfor
	
	ChanGraphsUpdate()
	
	if (ItemsInlist(badList) > 0)
		DoAlert 0, "Warning: x-alignment not performed on the following waves due to bad input values : " + badList
	endif
	
	return wList

End // NMXAlignWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXwaveCall()
	Variable ccnt
	
	String xwave = NMXwave()
	
	Variable npnts = numpnts($NMWaveSelected(0, 0))
	
	String wList = WaveListOfSize(npnts, "*")
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1)
		wList = RemoveFromList(NMChanWaveList(ccnt), wList, ";")
	endfor
	
	wList = "No Xwave;---;" + wList
	
	Prompt xwave, "choose a wave that contains the x-values for the currently selected waves:", popup wList
	DoPrompt NMPromptStr("Set Xwave"), xwave
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	NMCmdHistory("NMXwaveSet", NMCmdStr(xwave, ""))
	
	return NMXwaveSet(xwave)
	
End // NMXwaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStartXCall()
	String df = MainDF()
	Variable startx = NumVarOrDefault(df+"StartX", 0)
	
	Prompt startx, "time begin (ms):"
	DoPrompt NMPromptStr("Set Time Scale"), startx
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMvar(df+"StartX", startx)
	
	NMCmdHistory("NMStartX", NMCmdNum(startx, ""))
	
	return NMStartX(startx)
	
End // NMStartXCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeltaXCall()
	Variable dx
	String wname = "", wList = CurrentChanWaveList()
	
	if (ItemsInList(wList) > 0)
		wname = StringFromList(0, wList)
	endif

	if (WaveExists($wname) == 1)
		dx = deltax($wname)
	else
		dx = NumVarOrDefault("SampleInterval", 1)
	endif
	
	if (dx <= 0)
		dx = 1
	endif
	
	Prompt dx, "time step (ms):"
	DoPrompt NMPromptStr("Set Time Scale"), dx
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	NMCmdHistory("NMDeltaX", NMCmdNum(dx, ""))
	
	return NMDeltaX(dx)
	
End // NMDeltaXCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNumPntsCall()
	Variable npnts
	
	String wname = "", wList = CurrentChanWaveList()
	
	if (ItemsInList(wList) > 0)
		wname = StringFromList(0, wList)
	endif
	
	if (WaveExists($wname) == 1)
		npnts = numpnts($wname)
	else
		npnts = NumVarOrDefault("SamplesPerWave", 1)
	endif
	
	Prompt npnts, "wave points:"
	DoPrompt NMPromptStr("Set Time Scale"), npnts
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	NMCmdHistory("NMNumPnts", NMCmdNum(npnts, ""))
	
	return NMNumPnts(npnts)
	
End // NMNumPntsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStartX(startx)
	Variable startx // time begin
	
	return NMXScaleWaves(startx, -1, -1)
	
End // NMStartX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeltaX(dx)
	Variable dx // time step
	
	return NMXScaleWaves(Nan, dx, -1)
	
End // NMDeltaX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNumPnts(npnts)
	Variable npnts // number of points
	
	return NMXScaleWaves(Nan, -1, npnts)
	
End // NMNumPnts

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMYLabelCall()

	String vList = ""
	String yLabel = ChanLabel(-1, "y", "")
	
	Prompt yLabel, "label:"
	DoPrompt "Set Y-Axis Label", yLabel
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	vList = NMCmdStr("y", vList)
	vList = NMCmdStr(yLabel, vList)
	
	NMCmdHistory("NMLabel", vList)
	
	return NMLabel("y", yLabel)
	
End // NMYLabelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXLabelCall()

	String vList = ""
	String xLabel = ChanLabel(-1, "x", "")
	
	Prompt xLabel, "label:"
	DoPrompt "Set Time Axis Label", xLabel
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	vList = NMCmdStr("x", vList)
	vList = NMCmdStr(xLabel, vList)
	
	NMCmdHistory("NMLabel", vList)
	
	return NMLabel("x", xLabel)
	
End // NMXLabelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLabel(xy, labelStr)
	String xy // "x" or "y"
	String labelStr
	
	Variable ccnt
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		ChanLabelSet(ccnt, 1, xy, labelStr)
		
	endfor
	
	ChanGraphsUpdate()
	
	return labelStr
	
End // NMLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXUnitsChangeCall(xy, newUnits)
	String xy // "x" or "y"
	String newUnits
	
	NMCmdHistory("NMLabel", NMCmdStr(newUnits, ""))
	
	return NMXUnitsChange(xy, newUnits)

End // NMXUnitsChangeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXUnitsChange(xy, newUnits)
	String xy // "x" or "y"
	String newUnits
	
	Variable ccnt, wcnt, scale = 1
	String units, wname
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		for (wcnt = 0; wcnt < NMNumWaves(); wcnt += 1) // loop thru waves
		
			wName = NMWaveSelected(ccnt, wcnt)
			
			if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			units = GetWaveUnits("x", wName, "")
			
			scale = 1
		
			strswitch(units)
			
				case "s":
				case "sec":
				
					strswitch(newUnits)
						case "s":
						case "sec":
							break
						case "ms":
						case "msec":
							scale = 1000
							break
						case "us":
						case "usec":
							scale = 1000000
							break
					endswitch
					
					break
				
				case "ms":
				case "msec":
				
					strswitch(newUnits)
						case "s":
						case "sec":
							scale = 0.001
							break
						case "ms":
						case "msec":
							break
						case "us":
						case "usec":
							scale = 1000
							break
					endswitch
					
					break
					
				case "us":
				case "usec":
				
					strswitch(newUnits)
						case "s":
						case "sec":
							scale = 0.000001
							break
						case "ms":
						case "msec":
							scale = 0.001
							break
						case "us":
						case "usec":
							break
					endswitch
					
					break
					
				default:
				
					continue
					
			endswitch
			
			if (scale == 1)
				continue // nothing to do
			endif
		
			NMNoteStrReplace(wName, "xLabel", newUnits)
			SetXScale(Nan, scale*deltax($wName), -1, wName)
		
		endfor
		
	endfor
	
	ChanGraphsUpdate()
	
	return newUnits
	
End // NMXUnitsChange

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXScaleWaves(startx, dx, npnts)
	Variable startx // time begin (Nan) dont change
	Variable dx // time step (-1) dont change
	Variable npnts // number of points (-1) dont change

	Variable ccnt
	String paramstr = "", cList, wList = ""
	
	if (numtype(dx*npnts) != 0)
		DoAlert 0, "Abort NMXScaleWaves : bad input parameters."
		return ""
	endif
	
	if (numtype(startx) == 0)
		paramstr += "t0=" + num2str(startx)
	endif
	
	if (dx > 0)
		if (strlen(paramstr) > 0)
			paramstr += ", "
		endif
		paramstr += "dt=" + num2str(dx) + " ms"
	endif
	
	if (npnts > 0)
		if (strlen(paramstr) > 0)
			paramstr += ", "
		endif
		paramstr += "npnts=" + num2str(npnts)
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
	
		cList = SetXScale(startx, dx, npnts, cList) // NM_Utility.ipf
		wList += cList
	
		NMMainHistory("X-scale (" + paramstr + ")", ccnt, cList, 0)
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMXScaleWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByNumCall()
	Variable npnts
	String vList = "", df = MainDF()
	
	String alg = StrVarOrDefault(df+"ScaleByNumAlg", "x")
	Variable value = NumVarOrDefault(df+"ScaleByNumVal", 1)
		
	Prompt alg, "function:", popup "x;/;+;-"
	Prompt value, "scale value:"
	
	DoPrompt NMPromptStr("Scale By Number"), alg, value
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"ScaleByNumAlg", alg)
	SetNMvar(df+"ScaleByNumVal", value)
	
	vList = NMCmdStr(alg, vList)
	vList = NMCmdNum(value, vList)
	NMCmdHistory("NMScaleByNum", vList)
	
	return NMScaleByNum(alg, value)

End // NMScaleByNumCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByNum(alg, value)
	String alg // "x" multiply; "/" divide; "+" add; "-" substract
	Variable value // scale by value
	
	Variable ccnt, wcnt
	String cList, wList = ""
	
	strswitch(alg)
		case "*":
		case "x":
		case "/":
		case "+":
		case "-":
			break
		default:
			DoAlert 0, "Abort NMScaleByNum : bad algorithm : " + alg
			return ""
	endswitch
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = ScaleByNum(alg, value, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Y-scale (" + alg + num2str(value) + ")", ccnt, cList, 0)
	
	endfor
	
	ChanGraphsUpdate()
	
	KillWaves /Z U_ScaleWave
	
	return wList

End // NMScaleByNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleWaveCall()
	Variable npnts
	String vList = "", df = MainDF()
	
	String alg = StrVarOrDefault(df+"ScaleWaveAlg", "x")
	Variable value = NumVarOrDefault(df+"ScaleWaveVal", 1)
	Variable tbgn = NumVarOrDefault(df+"ScaleWaveTbgn", -inf)
	Variable tend = NumVarOrDefault(df+"ScaleWaveTend", inf)
		
	Prompt alg, "function:", popup "x;/;+;-"
	Prompt value, "scale value:"
	Prompt tbgn, "time begin:"
	Prompt tend, "time end:"
	
	DoPrompt NMPromptStr("Scale Wave By Number"), alg, value, tbgn, tend
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"ScaleWaveAlg", alg)
	SetNMvar(df+"ScaleWaveVal", value)
	SetNMvar(df+"ScaleWaveTbgn", tbgn)
	SetNMvar(df+"ScaleWaveTend", tend)
	
	if ((numtype(tbgn) == 1) && (numtype(tend) == 1))
	
		vList = NMCmdStr(alg, vList)
		vList = NMCmdNum(value, vList)
		NMCmdHistory("NMScaleByNum", vList)
		
		return NMScaleByNum(alg, value)
	
	else
	
		vList = NMCmdStr(alg, vList)
		vList = NMCmdNum(value, vList)
		vList = NMCmdNum(tbgn, vList)
		vList = NMCmdNum(tend, vList)
		NMCmdHistory("NMScaleWave", vList)
		
		return NMScaleWave(alg, value, tbgn, tend)
	
	endif
	
End // NMScaleWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleWave(alg, value, tbgn, tend)
	String alg // "x", "/", "+" or "-"
	Variable value // scale by value
	Variable tbgn, tend
	
	Variable ccnt, wcnt
	String cList, wList = ""
	
	strswitch(alg)
		case "*":
		case "x":
		case "/":
		case "+":
		case "-":
			break
		default:
			DoAlert 0, "Abort NMScaleWave : bad algorithm : " + alg
			return ""
	endswitch
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = ScaleWave(alg, value, tbgn, tend, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Y-scale (" + alg + num2str(value) + "; t=" + num2str(tbgn) + "," + num2str(tend) + ")", ccnt, cList, 0)
	
	endfor
	
	ChanGraphsUpdate()
	
	KillWaves /Z U_ScaleWave
	
	return wList

End // NMScaleWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByWaveCall()
	Variable npnts
	String wList, wList2, vList = "", sname, df = MainDF()
	
	Variable method = NumVarOrDefault(df+"ScaleByWaveMthd", 0)
	String alg = StrVarOrDefault(df+"ScaleByWaveAlg", "x")
	String wSelect =  StrVarOrDefault(df+"ScaleByWaveSelect", "")
	String wSelect2 =  StrVarOrDefault(df+"ScaleByWaveSelect2", "")
	
	wList = " ;" + WaveListOfSize(numpnts(WavSelect), "!" + StrVarOrDefault("WavePrefix","") + "*")

	wList = RemoveFromList("WavSelect", wList)
	wList = RemoveFromList("Group", wList)
	wList = RemoveListFromList(NMSetsList(1), wList, ";")
	
	wList2 = CurrentChanWaveList()
	
	npnts = numpnts($StringFromList(0, wList2)) // size of first selected wave
	
	wList2 = " ;" + WaveListOfSize(npnts, "*")
	
	Prompt alg, "function:", popup "x;/;+;-"
	Prompt wSelect, "choose a wave of scale values:", popup wList
	Prompt wSelect2, "or choose a wave to scale by:", popup wList2
	
	DoPrompt NMPromptStr("Scale by Wave"), alg, wSelect, wSelect2
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	if (StringMatch(wSelect, " ") == 0)  // scale by wave of values
		method = 1
		sname = wSelect
		wSelect2 = ""
	elseif (StringMatch(wSelect2, " ") == 0) // scale by wave
		method = 2
		sname = wSelect2
		wSelect = ""
	else
		return ""
	endif
	
	SetNMvar(df+"ScaleByWaveMthd", method)
	SetNMstr(df+"ScaleByWaveAlg", alg)
	SetNMstr(df+"ScaleByWaveSelect", wSelect)
	SetNMstr(df+"ScaleByWaveSelect2", wSelect2)
	
	vList = NMCmdNum(method, vList)
	vList = NMCmdStr(alg, vList)
	vList = NMCmdStr(sname, vList)
	NMCmdHistory("NMScaleByWave", vList)
	
	return NMScaleByWave(method, alg, sname)

End // NMScaleByWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByWave(method, alg, swname)
	Variable method // (1) scale by wave of values (2) scale by wave
	String alg // "x", "/", "+" or "-"
	String swname // scale wave name

	Variable ccnt, wcnt
	String wName, cList = "", wList = ""
	
	switch(method)
	
		case 1:
		
			if (WaveExists($swname) == 0)
				DoAlert 0, "Abort NMScaleWaves : scale wave does not appear to exist."
				return ""
			endif
			
			Wave scalewave = $swname
			
			break
			
		case 2:
		
			if (WaveExists($swname) == 0)
				DoAlert 0, "Abort NMScaleWaves : scale wave does not appear to exist."
				return ""
			endif
			
			Duplicate /O $swname U_ScaleWave
			
			break
			
		default:
		
			DoAlert 0, "Abort NMScaleWaves : bad method parameters."
			return ""
			
	endswitch
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		for (wcnt = 0; wcnt < NMNumWaves(); wcnt += 1) // loop thru waves
		
			wName = NMWaveSelected(ccnt, wcnt)
			
			if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
				continue // wave not selected, or does not exist... go to next wave
			endif
		
			if (method == 1)

				wName = ScaleByNum(alg, scalewave[ChanWaveNum(wName)], wName) // NM_Utility.ipf
				
			elseif (method == 2)
			
				wName = ScaleByWave(alg, "U_ScaleWave", wName) // NM_Utility.ipf
				
			endif
			
			if (strlen(wName) > 0)
				cList = AddListItem(wName, cList, ";", inf)
			endif
		
		endfor
		
		wList += cList
		
		if (method == 1)
			NMMainHistory("Y-scale (" + alg + swname + ")", ccnt, cList, 0)
		elseif (method == 2)
			NMMainHistory("Y-scale (" + alg + swname + ")", ccnt, cList, 0)
		endif
	
	endfor
	
	ChanGraphsUpdate()
	
	KillWaves /Z U_ScaleWave
	
	return wList

End // NMScaleByWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTimeScaleModeCall(mode)
	Variable mode // (0) episodic (1) continuous

	NMCmdHistory("NMTimeScaleMode", NMCmdNum(mode, ""))
	
	return NMTimeScaleMode(mode)

End // NMTimeScaleModeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTimeScaleMode(mode)
	Variable mode // (0) episodic (1) continuous
	
	Variable ccnt, wcnt, dx, tbgn
	String wname
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		tbgn = Nan
		
		for (wcnt = 0; wcnt < NMNumWaves(); wcnt += 1) 
		
			wName = ChanWaveName(ccnt, wcnt)
			
			if (exists(wName) == 0)
				continue // wave does not exist, go to next wave
			endif
			
			if (numtype(tbgn) > 0)
				tbgn = leftx($wName)
			endif
			
			if (mode == 0) // episodic
				dx = deltax($wName)
				Setscale /P x tbgn, dx, $wName
			elseif (mode == 1) // continuous
				dx = deltax($wName)
				Setscale /P x tbgn, dx, $wName
				tbgn = rightx($wName)
			endif
			
		endfor
		
	endfor
	
	ChanGraphsUpdate()
	
	return ""
	
End // NMTimeScaleContinuous

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBaselineCall()
	String vList = "", df = MainDF()
	
	Variable method = NumVarOrDefault(df+"Bsln_Method", 1)
	Variable tbgn = NumVarOrDefault(df+"Bsln_Bgn", 0)
	Variable tend = NumVarOrDefault(df+"Bsln_End", 5)
	
	Prompt tbgn, "compute baseline FROM (ms):"
	Prompt tend, "compute baseline TO (ms):"
	Prompt method, "subtract from each wave:", popup "its individual baseline;average baseline of selected waves"
	
	DoPrompt NMPromptStr("Subtract Baseline"), tbgn, tend, method
	
	if (V_flag == 1)
		return ""  // cancel
	endif
	
	SetNMvar(df+"Bsln_Method", method)
	SetNMvar(df+"Bsln_Bgn", tbgn)
	SetNMvar(df+"Bsln_End", tend)
	
	vList = NMCmdNum(tbgn, vList)
	vList = NMCmdNum(tend, vList)
	
	if (method == 1)
		NMCmdHistory("NMBslnWaves", vList)
		return NMBslnWaves(tbgn, tend)
	elseif (method == 2)
		NMCmdHistory("NMBslnAvgWaves", vList)
		return NMBslnAvgWaves(tbgn, tend)
	endif
	
	return ""

End // NMBaselineCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBslnWaves(tbgn, tend)
	Variable tbgn, tend
	
	return NMBaselineWaves(1, tbgn, tend)
	
End // NMBslnWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBslnAvgWaves(tbgn, tend)
	Variable tbgn, tend
	
	return NMBaselineWaves(2, tbgn, tend)
	
End // NMBslnAvgWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBaselineWaves(method, tbgn, tend)
	Variable method // (1) subtract wave's individual mean (2) subtract mean of all waves
	Variable tbgn, tend
	
	Variable ccnt, wcnt, avg, mn, sd, cnt
	String mnsd, cList, wName, oName, wList = ""
	
	Variable nwaves = NMNumWaves()
	
	if ((method < 0) || (method > 2) || (tend <= tbgn) || (numtype(tend*tbgn) == 2))
		DoAlert 0, "Abort NMBaselineWaves : bad input parameters."
		return ""
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		if (method == 2) // subtract mean of all waves
	
			mnsd = MeanStdv(tbgn, tend, cList) // compute mean and stdv of waves
			
			avg = str2num(StringByKey("mean", mnsd, "="))
			sd = str2num(StringByKey("stdv", mnsd, "="))
			cnt = str2num(StringByKey("count", mnsd, "="))
		 
			DoAlert 1, "Baseline mean = " + num2str(avg) + " ± " + num2str(sd) + ".    Subtract mean from selected waves?"
		
			if (V_Flag != 1)
				return "" // cancel
			endif
	
		endif
		
		cList = ""
		
		oName = GetWaveName(MainPrefix("") + "Bsln" + NMWaveSelectStr() + "_", ccnt, 0)
		
		Make /O/N=(nwaves) $oName
		
		Wave otempwave = $oName
		
		for (wcnt = 0; wcnt < nwaves; wcnt += 1) // loop thru waves
		
			wName = NMWaveSelected(ccnt, wcnt)
			
			if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			Wave tempWave = $wName // create local reference to wave
			
			if (method == 1)
				mn = mean(tempwave, tbgn, tend)
			else
				mn = avg
			endif
	
			tempwave -= mn
			
			otempwave[wcnt] = mn
			
			Note tempwave, "Func:BaselineWaves"
			Note tempwave, "Bsln Value:" + num2str(mn) + ";Bsln Tbgn:" + num2str(tbgn) + ";Bsln Tend:" + num2str(tend) + ";"
			
			cList = AddListItem(wName, cList, ";", inf)
			
		endfor
		
		//cList = BaselineWaves(method, tbgn, tend, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Baselined (t=" + num2str(tbgn) + "," + num2str(tend) + ")", ccnt, cList, 0)
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMBaselineWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAvgWavesCall()

	Variable AskAllGrps = 0
	
	String vList = "", df = MainDF(), ndf = NMDF()
	
	String wselect = NMWaveSelectGet()
	
	Variable grpsOn = NumVarOrDefault(ndf+"GroupsOn", 0)
	
	Variable smthn = ChanSmthNumGet(-1)
	Variable ft = ChanFuncGet(-1)
	
	Variable nanOrInf = NMWavesHaveNanOrInf()
	
	Variable mode = NumVarOrDefault(df+"AvgMode", 1)
	Variable dsply = BinaryCheck(NumVarOrDefault(df+"AvgDisplay", 1))
	Variable chanFlag = NumVarOrDefault(df+"AvgChanFlag", 0)
	Variable allGrps = NumVarOrDefault(df+"AvgAllGrps", 0)
	Variable grpDsply = NumVarOrDefault(df+"AvgGrpDisplay", 1)
	Variable pntByPnt = BinaryCheck(NumVarOrDefault(df+"AvgPntByPnt", 0))
	
	dsply += 1
	chanFlag += 1
	allGrps += 1
	grpDsply += 1
	pntByPnt += 1

	Prompt mode, "compute:", popup "avg;avg + stdv;avg + var;avg + sem"
	Prompt dsply, "display data with results?", popup "no;yes;"
	Prompt chanFlag, "use channel smooth and F(t)?", popup "no;yes;"
	Prompt allGrps, "average all groups?", popup "no;yes;"
	Prompt pntByPnt, "Alert: your waves contain Nan's or Inf's. Do you want to average point by point?", popup "no;yes (slow);"
	
	if (StringMatch(wselect, "All Groups") == 1)
	
		allGrps = 1
		
		Prompt grpDsply, "display groups in same plot?", popup, "no;yes;"
	
		if (smthn + ft > 0)
			DoPrompt NMPromptStr("Average"), mode, dsply, chanFlag, grpDsply
			chanFlag -= 1
			SetNMvar(df+"AvgChanFlag", chanFlag)
		else
			DoPrompt NMPromptStr("Average"), mode, dsply, grpDsply
			chanFlag = 0
		endif
		
		grpDsply -= 1
		SetNMvar(df+"AvgGrpDisplay", grpDsply)
		
	else
	
		if (AskAllGrps && (grpsOn == 1) && (StringMatch(wselect, "*group*") == 0))
		
			Prompt grpDsply, "if yes, display group averages in same plot?", popup, "no;yes;"
		
			if (smthn + ft > 0)
				DoPrompt NMPromptStr("Average"), mode, dsply, chanFlag, allGrps, grpDsply
				chanFlag -= 1
				SetNMvar(df+"AvgChanFlag", chanFlag)
			else
				DoPrompt NMPromptStr("Average"), mode, dsply, allGrps, grpDsply
				chanFlag = 0
			endif
		
			allGrps -= 1
			grpDsply -= 1
			SetNMvar(df+"AvgAllGrps", allGrps)
			SetNMvar(df+"AvgGrpDisplay", grpDsply)
		
		else
	
			if (smthn + ft > 0)
				DoPrompt NMPromptStr("Average"), mode, dsply, chanFlag
				chanFlag -= 1
				SetNMvar(df+"AvgChanFlag", chanFlag)
			else
				DoPrompt NMPromptStr("Average"), mode, dsply
				chanFlag = 0
			endif
			
			allGrps = 0
			grpDsply = 0
		
		endif
		
	endif
	
	if (V_flag == 1)
		return ""  // cancel
	endif
	
	dsply -= 1
	
	if (nanOrInf == 1)
	
		DoPrompt NMPromptStr("Average"), pntByPnt
		
		if (V_flag == 1)
			return ""  // cancel
		endif
		
		pntByPnt -= 1
		
	else
	
		pntByPnt = 0
		
	endif
	
	
	
	if ((pntByPnt == 1) && (chanFlag == 1))
		DoAlert 0, "Sorry, point-by-point averaging is not allowed with channel smoothing and F(t) operations."
		return "" // not allowed
	endif
	
	SetNMvar(df+"AvgMode", mode)
	SetNMvar(df+"AvgPntByPnt", pntByPnt)
	SetNMvar(df+"AvgDisplay", dsply)
	
	vList = NMCmdNum(mode, vList)
	vList = NMCmdNum(pntByPnt, vList)
	vList = NMCmdNum(dsply, vList)
	vList = NMCmdNum(chanFlag, vList)
	vList = NMCmdNum(allGrps, vList)
	vList = NMCmdNum(grpDsply, vList)
	NMCmdHistory("NMAvgWaves", vList)
	
	return NMAvgWaves2(mode, pntByPnt, dsply, chanFlag, allGrps, grpDsply)

End // NMAvgWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAvgWaves(mode, dsply, chanFlag, allGrps, grpDsply) // OLDER FUNCTION
	Variable mode // (1) avg (2) avg + stdv (3) avg + var (4) avg + sem
	Variable dsply // display data waves? (0) no (1) yes
	Variable chanFlag // use channel F(t) and smooth? (0) no (1) yes
	Variable allGrps // average all groups? (0) no (1) yes
	Variable grpDsply // display groups together? (0) no (1) yes
	
	NMCmdHistory("NMAvgWaves", "DEPRECATED. Please change your code to use NMAvgWaves2.")
	
	return NMAvgWaves2(mode, 0, dsply, chanFlag, allGrps, grpDsply)
	
End // NMAvgWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAvgWaves2(mode, pntByPnt, dsply, chanFlag, allGrps, grpDsply)
	Variable mode // (1) avg (2) avg + stdv (3) avg + var (4) avg + sem
	Variable pntByPnt // point by point average? (0) no (1) yes (use this option if your data contains NAN's)
	Variable dsply // display data waves? (0) no (1) yes
	Variable chanFlag // use channel F(t) and smooth? (0) no (1) yes
	Variable allGrps // average all groups? (0) no (1) yes
	Variable grpDsply // display groups together? (0) no (1) yes
	
	Variable markerLimit = 200 // limit for number of points to use "lines + markers"

	Variable nwaves, ccnt, gcnt, grpbeg, grpend, wcnt, overwrite
	String gPrefix, gName, gList = "", gTitle, sName, pName = ""
	String cList, wList = ""
	String avgPrefix = "", avgName = "", sdPrefix = "", sdName = "", sdpName = "", sdmName = ""
	String xwave = NMXwave()
	
	String df = MainDF(), ndf = NMDF()
	
	Variable NameFormat = NumVarOrDefault(ndf+"NameFormat", 1)
	
	String wselect = NMWaveSelectGet()
	String saveSelect = wselect
	
	if (allgrps == 1)
		grpbeg = NMGroupFirst()
		grpend = NMGroupLast()
		NameFormat = 1 // force long name format
	endif
	
	if (StringMatch(wselect, "All Groups") == 1)
		allgrps = 2
	endif
	
	if ((StringMatch(wselect, "All") == 1) && (allgrps == 1))
		allgrps = 2
	endif
	
	if (allgrps > 0)
		NameFormat = 1 // force long wave names
	else
		grpDsply = 0
	endif
	
	avgPrefix = "Avg_" // average prefix name
	
	switch(mode)
		case 1:
			break
		case 2:
			sdPrefix = "Stdv"
			break
		case 3:
			sdPrefix = "Var"
			break
		case 4:
			sdPrefix = "Sem"
			break
		default:
			DoAlert 0, "Abort NMAvgWaves : bad mode selection."
			return ""
	endswitch
	
	overwrite = NMOverWrite()
	
	if ((strlen(xWave) > 0) && (WaveExists($xWave) == 0))
		xWave = ""
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif

		for (gcnt = grpbeg; gcnt <= grpend; gcnt += 1)
	
			if ((allgrps > 0) && (NMGroupCheck(gcnt) == 1))
				
				if (allgrps == 1)
					NMWaveSelect(wselect + " x Group" + num2str(gcnt))
				elseif (allgrps == 2)
					NMWaveSelect("Group" + num2str(gcnt))
				endif
				
			endif
			
			cList = NMChanWaveList(ccnt)
			
			nwaves = ItemsInList(cList)
			
			if (nwaves < 2)
				DoAlert 0, "NMAvgWaves: Channel " + ChanNum2Char(ccnt) + ": not enough waves."
				continue
			endif
			
			if (chanFlag == 1)
				cList = AvgChanWaves(ccnt, cList) // NM_Utility.ipf
			elseif (pntByPnt == 1)
				cList = AvgWavesPntByPnt(cList) // NM_Utility.ipf
			else
				cList = AvgWaves(cList) // NM_Utility.ipf
			endif
			
			wList += cList
			
			if ((wcnt < 0) || (WaveExists(U_Avg) == 0))
				break
			endif
			
			gPrefix= MainPrefix("") + NMFolderPrefix("") + "Avg_" + NMWaveSelectStr() + "_"
			
			if (NameFormat == 1)
				pName = NMWaveSelectStr() + "_"
			endif
			
			gName = NextGraphName(gPrefix, ccnt, overwrite)
			avgName = NextWaveName2("", avgPrefix+pName, ccnt, overwrite)
			sdName = NextWaveName2("", sdPrefix + "_Avg_" + pName, ccnt, overwrite)
			sdpName = NextWaveName2("", sdPrefix + "P_Avg_" + pName, ccnt, overwrite)
			sdmName = NextWaveName2("", sdPrefix + "N_Avg_" + pName, ccnt, overwrite)
			
			Duplicate /O U_Avg $avgName // save average wave
	
			if (grpDsply == 1) // all Groups in one display
			
				if (gcnt == grpbeg)
				
					gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : All Groups"
					
					if (dsply == 1)
					
						NMPlotWaves(gName, gTitle, "", "", xwave, cList)
						
						if (strlen(xwave) > 0)
							AppendToGraph /W=$gName $avgName vs $xwave
						else
							AppendToGraph /W=$gName $avgName
						endif
						
					else
					
						NMPlotWaves(gName, gTitle, "", "", xwave, avgName)
						ModifyGraph /W=$gName rgb=(65535,0,0)
						
					endif
					
				else
				
					if (strlen(xwave) > 0)
						AppendToGraph /W=$gName $avgName vs $xwave
					else
						AppendToGraph /W=$gName $avgName
					endif
					
				endif
				
			else
			
				gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : " + avgName
				
				if (dsply == 1)
				
					NMPlotWaves(gName, gTitle, "", "", xwave, cList)
					
					if (strlen(xwave) > 0)
						AppendToGraph /W=$gName $avgName vs $xwave
					else
						AppendToGraph /W=$gName $avgName
					endif
					
				else
					NMPlotWaves(gName, gTitle, "", "", xwave, avgName)
					ModifyGraph /W=$gName rgb=(65535,0,0)
				endif
				
			endif
			
			ModifyGraph /W=$gName lsize($avgName)=1.5
			
			if (numpnts($avgName) < markerLimit)
				ModifyGraph /W=$gName mode($avgName)=4,marker($avgName)=19
			endif
			
			if (mode > 1)
			
				Duplicate /O U_Sdv $sdName
				Duplicate /O U_Sdv $sdpName
				Duplicate /O U_Sdv $sdmName
				
				Wave avg = $avgName
				Wave sdv = $sdName
				Wave sdvp = $sdpName
				Wave sdvn = $sdmName
				
				if (mode == 3)
				
					sdv *= sdv // variance
					sdvp = Nan
					sdvn = Nan
					
				elseif (mode == 4)
				
					if ((pntByPnt == 1) && (WaveExists(U_Pnts) == 1))
						Wave npnts = U_Pnts
						sdv /= sqrt(npnts)
					else
						sdv /= sqrt(nwaves) // standard error
					endif
					
					sdvp = sdv
					sdvn = sdv
					
				endif
			
				sdvp = avg + sdvp
				sdvn = avg - sdvn
				
				if (mode == 3)
				
					KillWaves /Z $sdpName, $sdmName
					
				else
				
					if (numpnts($sdName) < markerLimit)
					
						ErrorBars /W=$gName $avgName Y, wave=($sdName,$sdName)
						
					else
				
						if (strlen(xwave) > 0)
							AppendToGraph /W=$gName/C=(1,16019,65535) $sdpName, $sdmName vs $xwave
						else
							AppendToGraph /W=$gName/C=(1,16019,65535) $sdpName, $sdmName
						endif
					
					endif
					
				endif
				
			endif
			
			if (ItemsInList(gList) == 0)
				gList = gName
			else
				gList = AddListItem(gName, gList, ";", inf)
			endif
			
			NMMainHistory(avgName, ccnt, cList, 0)
		
		endfor // groups
		
	endfor // channels
	
	if (allgrps > 0)
		NMWaveSelect(saveSelect)
	endif
	
	NMNoteStrReplace(avgName, "Source", avgName)
	NMNoteStrReplace(sdName, "Source", sdName)
	NMNoteStrReplace(sdpName, "Source", sdpName)
	NMNoteStrReplace(sdmName, "Source", sdmName)
	
	Killwaves /Z U_Avg, U_Sdv
	
	return wList

End // NMAvgWaves2

//****************************************************************
//
//	SumChanWaves()
//	compute sum of waves based on channel smooth and F(t) parameters
//	results stored in U_Sum
//
//****************************************************************

Function /S SumChanWaves(chanNum, wList)
	Variable chanNum
	String wList // wave list (seperator ";")
	
	Variable wcnt, icnt, items
	String xl, yl, txt, wName, dName, cList = "", badList = wList
	
	if ((chanNum < 0) || (chanNum >= NumVarOrDefault("NumChannels", 0)))
		return "" // out of range
	endif
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	Variable dx = GetXStats("deltax", wList)
	Variable lftx = GetXStats("maxleftx", wList)
	Variable rghtx = GetXStats("minrightx", wList)
	Variable npnts = GetXStats("numpnts", wList)
	
	if (numtype(dx*npnts) > 0)
	
		DoAlert 1, "Alert : waves have different x-scaling. Do you want to continue?"
		
		if (V_flag != 1)
			return ""
		endif
		
	endif
	
	Variable ft = ChanFuncGet(chanNum)
	Variable smthNum = ChanSmthNumGet(chanNum)
	String smthAlg = ChanSmthAlgGet(chanNum)
	
	items = ItemsInList(wList)
	
	NMProgressStr("Summing Channel Waves...")
	
	for (wcnt = 0; wcnt < items; wcnt += 1)
		
		if (CallNMProgress(wcnt, items) == 1)
			wcnt = -1
			break
		endif
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		dName = "U_waveCopy"
		ChanWaveMake(chanNum, wname, dName) 
		
		if (WaveExists($dname) == 0)
			continue
		endif
		
		if (icnt == 0) // first wave
			Duplicate /O/R=(lftx,rghtx)  $dName U_Sum
		else
			Wave wtemp = $dname
			U_Sum += wtemp
		endif
		
		icnt += 1
		
		cList = AddListItem(wName, cList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	if (wcnt > 1)
		Setscale /P x lftx, dx, U_Sum
	endif
	
	xl = NMNoteLabel("x", wList, "")
	yl = NMNoteLabel("y", wList, "")
	
	NMNoteType("U_Sum", "NMSum", xl, yl, "Func:SumChanWaves")
	
	switch(ft)
		case 1:
			Note U_Sum, "F(t):d/dt;"
			break
		case 2:
			Note U_Sum, "F(t):dd/dt*dt;"
			break
		case 3:
			Note U_Sum, "F(t):integrate;"
			break
		case 4:
			Note U_Sum, "F(t):norm2max;"
			break
		case 5:
			Note U_Sum, "F(t):norm2min;"
			break
		case 6:
			Note U_Sum, "F(t):norm2avg;"
			break
		case 7:
			Note U_Sum, "F(t):dF/Fo;"
			break
	endswitch
	
	if (smthNum > 0)
		txt = "Smth Alg:" + smthAlg + ";Smth Num:" + num2str(smthNum) + ";"
		Note U_Sum, txt
	endif
	
	txt = "Wave List:" + ChangeListSep(wList, ",")
	
	Note U_Sum, txt
	
	KillWaves /Z U_waveCopy
	
	NMUtilityAlert("SumChanWaves", badList)
	
	return cList

End // SumChanWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSumWavesCall()
	String vList = "", df = MainDF(), ndf = NMDF()
	
	String wselect = NMWaveSelectGet()
	
	Variable grpsOn = NumVarOrDefault(ndf+"GroupsOn", 0)
	
	Variable smthn = ChanSmthNumGet(-1)
	Variable ft = ChanFuncGet(-1)
	
	Variable dsply = NumVarOrDefault(df+"SumDisplay", 1)
	Variable chanFlag = NumVarOrDefault(df+"SumChanFlag", 0)
	Variable allGrps = NumVarOrDefault(df+"SumAllGrps", 0)
	Variable grpDsply = NumVarOrDefault(df+"SumGrpDisplay", 1)
	
	dsply += 1
	chanFlag += 1
	allGrps += 1
	grpDsply += 1

	Prompt dsply, "display data with results?", popup, "no;yes;"
	Prompt chanFlag, "use channel smooth and F(t)?", popup "no;yes;"
	Prompt allGrps, "sum all groups?", popup, "no;yes;"
	
	if (StringMatch(wselect, "All Groups") == 1)
	
		allGrps = 1
		
		Prompt grpDsply, "display groups in same plot?", popup, "no;yes;"
	
		if (smthn + ft > 0)
			DoPrompt NMPromptStr("Sum Waves"), dsply, chanFlag, grpDsply
			chanFlag -= 1
			SetNMvar(df+"SumChanFlag", chanFlag)
		else
			DoPrompt NMPromptStr("Sum Waves"), dsply, grpDsply
			chanFlag = 0
		endif
		
		grpDsply -= 1
		SetNMvar(df+"SumGrpDisplay", grpDsply)
		
	else
	
		if ((grpsOn == 1) && (StringMatch(wselect, "All") == 0) && (StringMatch(wselect, "*group*") == 0))
		
			Prompt grpDsply, "if yes, display group averages in same plot?", popup, "no;yes;"
		
			if (smthn + ft > 0)
				DoPrompt NMPromptStr("Sum Waves"), dsply, chanFlag, allGrps, grpDsply
				chanFlag -= 1
				SetNMvar(df+"SumChanFlag", chanFlag)
			else
				DoPrompt NMPromptStr("Sum Waves"), dsply, allGrps, grpDsply
				chanFlag = 0
			endif
		
			allGrps -= 1
			grpDsply -= 1
			SetNMvar(df+"SumAllGrps", allGrps)
			SetNMvar(df+"SumGrpDisplay", grpDsply)
		
		else
	
			if (smthn + ft > 0)
				DoPrompt NMPromptStr("Sum Waves"), dsply, chanFlag
				chanFlag -= 1
				SetNMvar(df+"SumChanFlag", chanFlag)
			else
				DoPrompt NMPromptStr("Sum Waves"), dsply
				chanFlag = 0
			endif
			
			allGrps = 0
			grpDsply = 0
		
		endif
		
	endif
	
	if (V_flag == 1)
		return ""  // cancel
	endif
	
	dsply -= 1
	
	SetNMvar(df+"SumDisplay", dsply)
	
	vList = NMCmdNum(dsply, vList)
	vList = NMCmdNum(chanFlag, vList)
	vList = NMCmdNum(allGrps, vList)
	vList = NMCmdNum(grpDsply, vList)
	NMCmdHistory("NMSumWaves", vList)
	
	return NMSumWaves(dsply, chanFlag, allGrps, grpDsply)

End // NMSumWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSumWaves(dsply, chanFlag, allGrps, grpDsply)
	Variable dsply // display data waves? (0) no (1) yes
	Variable chanFlag // use channel F(t) and smooth? (0) no (1) yes
	Variable allGrps // average all groups? (0) no (1) yes
	Variable grpDsply // display groups together? (0) no (1) yes

	Variable nwaves, ccnt, gcnt, grpbeg, grpend, wcnt, overwrite
	String gPrefix, gName, gList = "", gTitle, sName, pName = ""
	String cList, wList = ""
	String sumPrefix, sumName
	String xwave = NMXwave()
	
	String df = MainDF(), ndf = NMDF()
	
	Variable NameFormat = NumVarOrDefault(ndf+"NameFormat", 1)
	
	String wselect = NMWaveSelectGet()
	String saveSelect = wselect
	
	if (allgrps == 1)
		grpbeg = NMGroupFirst()
		grpend = NMGroupLast()
		NameFormat = 1 // force long name format
	endif
	
	if (StringMatch(wselect, "All Groups") == 1)
		allgrps = 2
	endif
	
	if (allgrps > 0)
		NameFormat = 1 // force long wave names
	else
		grpDsply = 0
	endif
	
	sumPrefix = "Sum_" // prefix name
	
	overwrite = NMOverWrite()
	
	if ((strlen(xWave) > 0) && (WaveExists($xWave) == 0))
		xWave = ""
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif

		for (gcnt = grpbeg; gcnt <= grpend; gcnt += 1)
	
			if ((allgrps > 0) && (NMGroupCheck(gcnt) == 1))
				
				if (allgrps == 1)
					NMWaveSelect(wselect + " x Group" + num2str(gcnt))
				elseif (allgrps == 2)
					NMWaveSelect("Group" + num2str(gcnt))
				endif
				
			endif
			
			cList = NMChanWaveList(ccnt)
			
			nwaves = ItemsInList(cList)
			
			if (nwaves == 0)
				continue
			endif
			
			if (chanFlag == 1)
				cList = SumChanWaves(ccnt, cList) // NM_Utility.ipf
			else
				cList = SumWaves(cList) // NM_Utility.ipf
			endif
			
			wList += cList
			
			if (wcnt < 0)
				break
			endif
			
			gPrefix= MainPrefix("") + NMFolderPrefix("") + "Sum_" + NMWaveSelectStr() + "_"
			
			if (NameFormat == 1)
				pName = NMWaveSelectStr() + "_"
			endif
			
			gName = NextGraphName(gPrefix, ccnt, overwrite)
			sumName = NextWaveName2("", sumPrefix+pName, ccnt, overwrite)
			
			Duplicate /O U_Sum $sumName // save output wave
	
			if (grpDsply == 1) // all Groups in one display
			
				if (gcnt == grpbeg)
				
					gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : All Groups"
					
					if (dsply == 1)
					
						NMPlotWaves(gName, gTitle, "", "", xwave, cList)
						
						if (strlen(xwave) > 0)
							AppendToGraph $sumName vs $xwave
						else
							AppendToGraph $sumName
						endif
						
					else
						NMPlotWaves(gName, gTitle, "", "", xwave, sumName)
						ModifyGraph rgb=(65535,0,0)
					endif
					
				else
				
					if (strlen(xwave) > 0)
						AppendToGraph $sumName vs $xwave
					else
						AppendToGraph $sumName
					endif
					
				endif
				
			else
			
				gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : " + sumName
				
				if (dsply == 1)
				
					NMPlotWaves(gName, gTitle, "", "", xwave, cList)
					
					if (strlen(xwave) > 0)
						AppendToGraph $sumName vs $xwave
					else
						AppendToGraph $sumName
					endif
						
				else
					NMPlotWaves(gName, gTitle, "", "", xwave, sumName)
					ModifyGraph rgb=(65535,0,0)
				endif
				
			endif
			
			if (ItemsInList(gList) == 0)
				gList = gName
			else
				gList = AddListItem(gName, gList, ";", inf)
			endif
			
			NMMainHistory(sumName, ccnt, cList, 0)
		
		endfor // groups
		
	endfor // channels
	
	if (allgrps > 0)
		NMWaveSelect(saveSelect)
	endif
	
	NMNoteStrReplace(sumName, "Source", sumName)
	
	Killwaves /Z U_Sum
	
	return wList

End // NMSumWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMIVCall()
	Variable nchans = NumVarOrDefault("NumChannels", 1)
	
	if (nchans < 2)
		DoAlert 0, "Abort NMIVCall : this function requires two or more data channels."
		return ""
	endif
	
	String vList = "", df = MainDF()
	
	Variable rx = rightx($ChanDisplayWave(-1))
	
	String fxnX = StrVarOrDefault(df+"IVFxnX", "Avg")
	String fxnY = StrVarOrDefault(df+"IVFxnY", "Avg")
	
	Variable chX = NumVarOrDefault(df+"IVChX", 1)
	Variable chY = NumVarOrDefault(df+"IVChY", 0)
	Variable tbgnX = NumVarOrDefault(df+"IVTbgnX", 0)
	Variable tendX = NumVarOrDefault(df+"IVTendX", rx)
	Variable tbgnY = NumVarOrDefault(df+"IVTbgnY", 0)
	Variable tendY = NumVarOrDefault(df+"IVTendY", rx)
	
	chX += 1
	chY += 1

	Prompt chX, "select channel for x-data:", popup, ChanCharList(nchans, ";")
	Prompt fxnX, "wave statistic for x-data:", popup, "Max;Min;Avg;Slope"
	Prompt tbgnX, "x-time window begin:"
	Prompt tendX, "x-time window end:"
	
	DoPrompt NMPromptStr("IV : X Data"), chX, fxnX, tbgnX, tendX
	
	if (V_flag == 1)
		return ""  // cancel
	endif
	
	tbgnY = tbgnX
	tendY = tendX
	
	Prompt chY, "channel for y-data:", popup, ChanCharList(nchans, ";")
	Prompt fxnY, "wave statistic for y-data:", popup, "Max;Min;Avg;Slope;"
	Prompt tbgnY, "y-time window begin:"
	Prompt tendY, "y-time window end:"
	
	DoPrompt NMPromptStr("IV : Y Data"), chY, fxnY, tbgnY, tendY
	
	if (V_flag == 1)
		return ""  // cancel
	endif
	
	chY -= 1
	chX -= 1
	
	SetNMvar(df+"IVChY", chY)
	SetNMvar(df+"IVChX", chX)
	SetNMstr(df+"IVFxnY", fxnY)
	SetNMstr(df+"IVFxnX", fxnX)
	SetNMvar(df+"IVTbgnY", tbgnY)
	SetNMvar(df+"IVTendY", tendY)
	SetNMvar(df+"IVTbgnX", tbgnX)
	SetNMvar(df+"IVTendX", tendX)
	
	vList = NMCmdNum(chX, vList)
	vList = NMCmdStr(fxnX, vList)
	vList = NMCmdNum(tbgnX, vList)
	vList = NMCmdNum(tendX, vList)
	vList = NMCmdNum(chY, vList)
	vList = NMCmdStr(fxnY, vList)
	vList = NMCmdNum(tbgnY, vList)
	vList = NMCmdNum(tendY, vList)
	NMCmdHistory("NMIV", vList)
	
	return NMIV(chX, fxnX, tbgnX, tendX, chY, fxnY, tbgnY, tendY)
	
End // NMIVCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMIV(chX, fxnX, tbgnX, tendX, chY, fxnY, tbgnY, tendY)
	Variable chx // channel for x data
	String fxnX // "min", "max", "avg", "slope"
	Variable tbgnX, tendX // x measure window
	Variable chy // channel for y data
	String fxnY // "min", "max", "avg", "slope"
	Variable tbgnY, tendY // y measure window
	
	Variable error, overwrite
	String xl, yl, wList, wName1, wName2, gPrefix, gName, gTitle, aName, uName
	
	Variable NumChannels = NumVarOrDefault("NumChannels", 1)
	
	if ((chX >= numChannels) || (chY >= numChannels))
		DoAlert 0, "Abort NMIV : bad channel numbers."
		return ""
	endif
	
	if ((tbgnY >= tendY) || (tbgnX >= tendX) || (numtype(tbgnY*tbgnX) != 0))
		DoAlert 0, "Abort NMIV : bad time window."
		return ""
	endif
	
	aName = fxnY
	uName = "U_AmpY"
	
	if (StringMatch(aName, "Slope") == 1)
		aName = "Slp"
		uName = "U_AmpX"
	endif
	
	overwrite = NMOverWrite()
	
	wList = NMChanWaveList(chY)
	error = WaveListStats(fxnY, tbgnY, tendY, wList) // NM_Utility.ipf
	yl = NMNoteLabel("y", wList, "")
	
	wName1 = NextWaveName2("", MainPrefix("") + aName + "_", chY, overwrite)
	Duplicate /O $uName $wName1
	
	NMNoteStrReplace(wName1, "Source", wName1)
	
	aName = fxnX
	uName = "U_AmpY"
	
	if (StringMatch(aName, "Slope") == 1)
		aName = "Slp"
		uName = "U_AmpX"
	endif
	
	wList = NMChanWaveList(chX)
	error = WaveListStats(fxnX, tbgnX, tendX, wList) // NM_Utility.ipf
	xl = NMNoteLabel("y", wList, "")
	
	wName2 = NextWaveName2("", MainPrefix(aName + "_"), chX, overwrite)
	Duplicate /O $uName $wName2
	
	NMNoteStrReplace(wName2, "Source", wName2)
	
	KillWaves /Z U_AmpX, U_AmpY
	
	gPrefix = MainPrefix("") + NMFolderPrefix("") + NMWaveSelectStr() + "_IV" + aName
	gName = NextGraphName(gPrefix, -1, overwrite)
	gTitle = NMFolderListName("") + " : IV : " + wName2
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=(0,0,0,0) $wName1 vs $wName2 as gTitle
	SetCascadeXY(gName)
	
	ModifyGraph mode=3,marker=19,rgb=(65535,0,0)
	Label left yl
	Label bottom xl
	ModifyGraph standoff=0
	ShowInfo
	SetAxis /A
	
	return gName
	
End // NMIV

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNormalizeWavesCall()
	String vList = "", df = MainDF()
	
	Variable bbgn = NumVarOrDefault(df+"Norm_Bgn", NumVarOrDefault(df+"Bsln_Bgn", 0))
	Variable bend = NumVarOrDefault(df+"Norm_End", NumVarOrDefault(df+"Bsln_End", 5))
	
	String fxn1 = StrVarOrDefault(df+"Norm_Fxn1", "avg")
	
	Variable tbgn1 = NumVarOrDefault(df+"Norm_Tbgn1", bbgn)
	Variable tend1 = NumVarOrDefault(df+"Norm_Tend1", bend)
	
	String fxn2 = StrVarOrDefault(df+"Norm_Fxn2", StrVarOrDefault(df+"Norm_Fxn", "max"))
	
	Variable tbgn2 = NumVarOrDefault(df+"Bsln_Bgn2", NumVarOrDefault(df+"Norm_Tbgn", -inf))
	Variable tend2 = NumVarOrDefault(df+"Bsln_End2", NumVarOrDefault(df+"Norm_Tbgn", inf))
	
	if (numtype(tbgn1) == 2)
		tbgn1 = 0
	endif
	
	if (numtype(tend1) == 2)
		tend2 = 5
	endif
	
	if (numtype(tbgn2) == 2)
		tbgn2 = -inf
	endif
	
	if (numtype(tend2) == 2)
		tend2 = -inf
	endif
	
	Prompt fxn1, "y-min measurement - window 1:", popup "max;min;avg;"
	Prompt tbgn1, "window 1 time begin (ms):"
	Prompt tend1, "window 1 time end (ms):"
	Prompt fxn2, "y-max measurement - window 2:", popup "max;min;avg;"
	Prompt tbgn2, "window 2 time begin (ms):"
	Prompt tend2, "window 2 time end (ms):"
	
	DoPrompt NMPromptStr("Normalize"), fxn1, fxn2, tbgn1, tbgn2, tend1, tend2
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"Norm_Fxn1", fxn1)
	SetNMvar(df+"Norm_Tbgn1", tbgn1)
	SetNMvar(df+"Norm_Tend1", tend1)
	SetNMstr(df+"Norm_Fxn2", fxn2)
	SetNMvar(df+"Norm_Tbgn2", tbgn2)
	SetNMvar(df+"Norm_Tend2", tend2)
	
	vList = NMCmdStr(fxn1, vList)
	vList = NMCmdNum(tbgn1, vList)
	vList = NMCmdNum(tend1, vList)
	vList = NMCmdStr(fxn2, vList)
	vList = NMCmdNum(tbgn2, vList)
	vList = NMCmdNum(tend2, vList)
	NMCmdHistory("NMNormalizeWaves", vList)
	
	return NMNormalizeWaves(fxn1, tbgn1, tend1, fxn2, tbgn2, tend2)
	
End // NMNormalizeWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNormWaves(fxn, tbgn, tend, bbgn, bend)
	String fxn // "max" or "min"
	Variable tbgn, tend
	Variable bbgn, bend
	
	Variable ccnt
	String cList, wList = ""
	
	if ((tend <= tbgn) || (bend <= bbgn))
		DoAlert 0, "Abort NMNormWaves : bad input parameters."
		return ""
	endif
	
	strswitch(fxn)
		case "min":
		case "max":
		case "avg":
			break
		default:
			DoAlert 0, "Abort NMNormWaves : bad function parameter."
			return ""
	endswitch
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = NormalizeWaves("avg", bbgn, bend, fxn, tbgn, tend, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Normalized waves to baseline", ccnt, cList, 0)
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMNormWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNormalizeWaves(fxn1, tbgn1, tend1, fxn2, tbgn2, tend2)
	String fxn1 // "max" or "min" or "avg"
	Variable tbgn1, tend1
	String fxn2 // "max" or "min" or "avg"
	Variable tbgn2, tend2
	
	Variable ccnt
	String cList, wList = ""
	
	if ((tend1 <= tbgn1) || (tend2 <= tbgn2))
		DoAlert 0, "Abort NMNormWaves : bad input parameters."
		return ""
	endif
	
	strswitch(fxn1)
		case "min":
		case "max":
		case "avg":
			break
		default:
			DoAlert 0, "Abort NMNormWaves : bad function parameter."
			return ""
	endswitch
	
	strswitch(fxn2)
		case "min":
		case "max":
		case "avg":
			break
		default:
			DoAlert 0, "Abort NMNormWaves : bad function parameter."
			return ""
	endswitch
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = NormalizeWaves(fxn1, tbgn1, tend1, fxn2, tbgn2, tend2, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Normalized waves to baseline", ccnt, cList, 0)
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMNormalizeWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBlankWavesCall()
	String wList, vList = "", df = MainDF()
	
	String wname = StrVarOrDefault(df+"Blank_WName", "")
	Variable tbefore = NumVarOrDefault(df+"Blank_Tbefore", 0)
	Variable tafter = NumVarOrDefault(df+"Blank_Tafter", 0)
	
	wList = " ;" + WaveList("*",";","TEXT:0")
	wList = RemoveFromList("WavSelect;ChanSelect;Group;", wList)
	wList = RemoveFromList(NMSetsList(0), wList)
	wList = RemoveFromList(NMSetsDataList(), wList)
	
	Prompt wname, "wave of event times:", popup wList
	Prompt tbefore, "blank before event time (ms):"
	Prompt tafter, "blank after event time (ms):"
	
	DoPrompt NMPromptStr("Normalize"), wname, tbefore, tafter
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"Blank_WName", wname)
	SetNMvar(df+"Blank_Tbefore", tbefore)
	SetNMvar(df+"Blank_Tafter", tafter)
	
	vList = NMCmdStr(wname, vList)
	vList = NMCmdNum(tbefore, vList)
	vList = NMCmdNum(tafter, vList)
	NMCmdHistory("NMNormWaves", vList)
	
	return NMBlankWaves(wname, tbefore, tafter)
	
End // NMBlankWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBlankWaves(waveOfEventTimes, tbefore, tafter)
	String waveOfEventTimes
	Variable tbefore, tafter
	
	Variable ccnt
	String cList = "", wList = ""
	
	if (WaveExists($waveOfEventTimes) == 0)
		DoAlert 0, "Abort NMBlankWaves : wave " + waveOfEventTimes + " does not exist."
		return ""
	endif
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		cList = BlankWaves(waveOfEventTimes, tbefore, tafter, Nan, cList) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("blanked waves using event times " + waveOfEventTimes, ccnt, cList, 0)
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMBlankWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConcatWavesCall()
	String df = MainDF()
	
	String wprefix = StrVarOrDefault(df+"ConcatPrefix", "C_"+NMCurrentWavePrefix())
		
	Prompt wprefix, "output wave name prefix:"
	DoPrompt "Concatenate Waves", wprefix
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"ConcatPrefix", wprefix)
	
	NMCmdHistory("NMConcatWaves", NMCmdStr(wprefix, ""))
	
	return NMConcatWaves(wprefix)

End // NMConcatWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConcatWaves(wprefix)
	String wprefix // output wave prefix
	
	Variable ccnt
	String wname, cList, wList = ""
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		wname = NextWaveName2("", wprefix, ccnt, NMOverWrite())
		Concatenate /O/NP cList, $wname
		//cList = ConcatWaves(cList, wname) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Concatenate " + wname, ccnt, cList, 0)
		
	endfor
	
	NMPrefixAdd(wprefix)
	ChanGraphsUpdate()
	
	return wList

End // NMConcatWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NM2DWaveCall()
	String df = MainDF()
	
	String wprefix = StrVarOrDefault(df+"Wave2DPrefix", MainPrefix(NMCurrentWavePrefix() + "2D"))
		
	Prompt wprefix, "2D output wave name prefix:"
	DoPrompt "Convert Selected 1D Waves to 2D Wave", wprefix
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"Wave2DPrefix", wprefix)
	
	NMCmdHistory("NM2DWave", NMCmdStr(wprefix, ""))
	
	return NM2DWave(wprefix)

End // NM2DWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NM2DWave(wprefix)
	String wprefix // output wave prefix
	
	Variable ccnt
	String wname, cList, wList = ""
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
	
		cList = NMChanWaveList(ccnt)
		
		if (strlen(cList) == 0)
			continue
		endif
		
		wname = NextWaveName2("", wprefix + "_", ccnt, NMOverWrite())
		cList = Make2DWave(cList, wname) // NM_Utility.ipf
		wList += cList
		
		NMMainHistory("Concatenate " + wname, ccnt, cList, 0)
		
	endfor
	
	NMPrefixAdd(wprefix)
	ChanGraphsUpdate()
	
	return wList

End // NM2DWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMOrderWavesCall()
	String wList, df = MainDF()

	Variable order = NumVarOrDefault(df+"OrderWaves", 2)

	String tname = NMChanWaveListTableName()
		
	if (WinType(tname) == 2)
		DoWindow /F $tname
		wList = WaveList("*", ";","WIN:"+ tname)
		NMChanWaveListOrder(wList)
		ChanWaves2WaveList()
		return ""
	endif
	
	Prompt order, "order waves by:", popup "creation date;alpha-numerically;user-input table;"
	DoPrompt NMPromptStr("Order Waves"), order
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMvar(df+"OrderWaves", order)
	
	switch(order)
		case 1:
			NMCmdHistory("NMOrderWavesByCreation", "")
			NMOrderWavesByCreation()
			break
		case 2:
			NMCmdHistory("NMOrderWavesAlphaNum", "")
			NMOrderWavesAlphaNum()
			break
		case 3:
			NMCmdHistory("NMOrderWavesByTable", "")
			NMOrderWavesByTable()
			break
	endswitch

End // NMOrderWavesCall()

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesByCreation()
	Variable ccnt

	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
		if (NMChanSelected(ccnt) == 1)
			ChanWaveListSet(ccnt, 1)
		endif
	endfor
	
	ChanGraphsUpdate()

End // NMOrderWavesByCreation

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesAlphaNum()
	Variable ccnt

	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
		if (NMChanSelected(ccnt) == 1)
			ChanWaveListSortAlphaNum(ccnt)
		endif
	endfor
	
	ChanGraphsUpdate()

End // NMOrderWavesAlphaNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesByTable()
	
	if (NMChanSelectedAll() == 1)
		NMChanWaveListOrderTable(-1)
	else
		NMChanWaveListOrderTable(NMCurrentChan())
	endif

End // NMOrderWavesByTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWavesHaveNanOrInf()
	
	Variable ccnt, wcnt, type
	String wName
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		for (wcnt = 0; wcnt < NMNumWaves(); wcnt += 1) // loop thru waves
		
			wName = NMWaveSelected(ccnt, wcnt)
			
			if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			WaveStats /Q/Z $wName
			
			if (V_npnts != numpnts($wName))
				type = 1
			endif
			
		endfor
		
	endfor
	
	return type
	
End // NMWavesHaveNanOrInf

//****************************************************************
//****************************************************************
//****************************************************************



