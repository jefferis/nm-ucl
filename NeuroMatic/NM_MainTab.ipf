#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Main Tab Functions 
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 26 July 2006
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

Function Main(enable)
	Variable enable // (0) disable (1) enable tab
	
	if (enable == 1)
		CheckPackage("Main", 0) // declare folder/globals if necessary
		MakeMainTab() // create controls if necessary
	endif

End // MainTab

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
	Variable x0 = 40, xinc = 120, y0 = 200, yinc = 50

	ControlInfo /W=NMPanel $MainPrefix("Plot")
	
	if (V_Flag != 0) 
		return 0 // main tab controls already exist
	endif
	
	DoWindow /F NMPanel // bring NMPanel to front
	
	Button $MainPrefix("Plot"), pos={x0,y0}, title = "Plot", size={100,20}, proc=MainTabButton
	Button $MainPrefix("Copy"), pos={x0+xinc,y0}, title = "Copy", size={100,20}, proc=MainTabButton
	
	Button $MainPrefix("Baseline"), pos={x0,y0+1*yinc}, title="Baseline", size={100,20}, proc=MainTabButton
	Button $MainPrefix("Average"), pos={x0+xinc,y0+1*yinc}, title="Average", size={100,20}, proc=MainTabButton
	
	Button $MainPrefix("YScale"), pos={x0,y0+2*yinc}, title="Scale", size={100,20}, proc=MainTabButton
	Button $MainPrefix("XAlign"), pos={x0+xinc,y0+2*yinc}, title="Align", size={100,20}, proc=MainTabButton
	
	y0 += 190
	
	GroupBox $MainPrefix("Group"), title = "More...", pos={x0-20,y0-35}, size={260,130}
	
	PopupMenu $MainPrefix("DisplayMenu"), pos={x0+100,y0+0*yinc}, size={0,0}, bodyWidth=100, fsize=14, proc=MainTabPopup
	PopupMenu $MainPrefix("DisplayMenu"), value="Display;---;Rainbow;Plot Black;Plot Red;Table;Print Names;Print Notes;XLabel;YLabel;"
	
	PopupMenu $MainPrefix("EditMenu"), pos={x0+100+xinc,y0+0*yinc}, size={0,0}, bodyWidth=100, fsize=14, proc=MainTabPopup
	PopupMenu $MainPrefix("EditMenu"), value="Edit;---;Copy;Copy To;Concatenate;kill;Rename;Renumber;"
	
	PopupMenu $MainPrefix("TScaleMenu"), pos={x0+100,y0+1*yinc}, size={0,0}, bodyWidth=100, fsize=14, proc=MainTabPopup
	PopupMenu $MainPrefix("TScaleMenu"), value="Time Scale;---;Align;Time Begin;Time Step;Redimension;Decimate;Interpolate;XLabel;"
	
	PopupMenu $MainPrefix("FxnMenu"), pos={x0+100+xinc,y0+1*yinc}, size={0,0}, bodyWidth=100, fsize=14, proc=MainTabPopup
	PopupMenu $MainPrefix("FxnMenu"), value="Operations;---;Scale by Num;Scale by Wave;Baseline;Normalize;Smooth;Integrate;Differentiate;2-Differentiate;Reverse;Delete NANs;NAN > 0;0 > Nan;---;Average;Sum;IV;"
	
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
	
	if (CheckCurrentFolder() == 0)
		return ""
	endif
	
	if (NumVarOrDefault("NumActiveWaves", 0) == 0)
		DoAlert 0, "No waves selected!"
		return ""
	endif
	
	strswitch(fxn)
	
		// Display Functions
		
		case "Plot":
		case "Graph":
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
			return NMPrintWaveListCall()
			
		case "Notes":
		case "Print Notes":
			return NMPrintWaveNotesCall()
			
		case "XLabel":
		case "Time Label":
			return NMXLabelCall()
			
		case "YLabel":
			return NMYLabelCall()
		
		// Edit Functions
			
		case "Copy":
			return NMCopyWavesCall()
		
		case "Copy To":
			return NMCopyWavesToCall()
			
		case "Kill":
		case "Delete":
			return NMDeleteWavesCall()
			
		case "Rename":
			return NMRenameWavesCall("Selected")
			
		case "Renumber":
			return NMRenumWavesCall()
			
		case "Concat":
		case "Concatenate":
			return NMConcatWavesCall()
			
		// Time Scale Functions
		
		case "Align":
		case "XAlign":
			return NMXAlignWavesCall()
			
		case "Time Begin":
			return NMStartXCall()
		
		case "Delta":
		case "Time Step":
			return NMDeltaXCall()
			
		case "Redimension":
			return NMNumPntsCall()
			
		case "Decimate":
			return NMDecimateWavesCall()
			
		case "Interpolate":
			return NMInterpolateWavesCall()
			
		case "Reverse":
		case "Reflect":
			return NMReverseWavesCall()
			
		// Operations
		
		case "Baseline":
			return NMBaselineCall()
		
		case "YScale":
			return NMScaleWaveCall()
		
		case "Scale By Num":
		case "Scale By Number":
			return NMScaleWaveCall()
			
		case "Scale By Wave":
			return NMScaleByWaveCall()
			
		case "Normalize":
			return NMNormWavesCall()
			
		case "d/dt":
		case "Differentiate":
			return NMDiffWavesCall(1)
			
		case "dd/dt*dt":
		case "2-Differentiate":
			return NMDiffWavesCall(2)
			
		case "integral":
		case "Integrate":
			return NMDiffWavesCall(3)
			
		case "Smooth":
			return NMSmoothWavesCall()
			
		case "Delete NANs":
			return NMDeleteNANsCall()
			
		case "NAN > 0":
			return NMReplaceNanZeroCall(1)
			
		case "0 > Nan":
			return NMReplaceNanZeroCall(-1)
			
		// Misc Functions
			
		case "Average":
			return NMAvgWavesCall()
			
		case "Sum":
			return NMSumWavesCall()
		
		case "IV":
			return NMIVCall()

	endswitch
	
End // NMMainCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainHistory(mssg, chanNum, wavList, namesFlag)
	String mssg
	Variable chanNum
	String wavList
	Variable namesFlag // (0) no (1) yes, print wave names
	
	if (strlen(mssg) == 0)
		mssg = "Chan " + ChanNum2Char(chanNum) + " : " + NMWaveSelectGet() + " : N = " + num2str(ItemsInlist(wavList))
	else
		mssg += " : Chan " + ChanNum2Char(chanNum) + " : " + NMWaveSelectGet() + " : N = " + num2str(ItemsInlist(wavList))
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

Function NMMainLoop() // example function that loops thru all currently selected channels and waves
	
	Variable wcnt, ccnt, items
	String wName, df = MyTabDF()
	
	if (WaveExists(ChanSelect) == 0)
		return -1 // this function requires this NM wave
	endif
	
	Wave ChanSelect
	
	NMProgressStr("My Demo Function...") // set progress title
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		String wList = NMChanWaveList(ccnt) // get a list of all currently selected waves
		
		items = ItemsInList(wList)
	
		if (items == 0)
			continue // no names in list
		endif
		
		//
		// loop thru selected waves (begins here)
		//
		// note, this loop can be replaced with a function call
		// that accepts a list of waves as input (see NMPrintWaveList())
		//
	
		for (wcnt = 0; wcnt < items; wcnt += 1) 
		
			if (CallProgress(wcnt/(items-1)) == 1) // progress display
				wcnt = -1
				break // cancel
			endif
		
			wName = StringFromList(wcnt, wList) // wave name
			
			if (exists(wName) == 0)
				continue // wave does not exist, go to next wave
			endif
			
			//Wave tempWave = $wName // create local reference to wave
			
			//TempWave *= 1 // do something to the wave
			
			Print wName
			
		endfor
		
		if (wcnt == -1)
			break // cancel
		endif
		
		//
		// loop thru selected waves (ends here)
		//
		
	endfor
	
	return 0

End // NMMainLoop

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
	String wList, allList = ""
	
	String saveSelect = NMWaveSelectGet()
	String grpList = NMGroupList(1)
		
	for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
		NMWaveSelect(StringFromList(gcnt, grpList))
		wList = NMPrintWaveList()
		allList += wList
	endfor
	
	NMWaveSelect(saveSelect)
	
	return allList

End // NMPrintGroupWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintWaveList()
	Variable ccnt, wcnt
	String wList, wName, allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
		
		wList = NMChanWaveList(ccnt)
		allList += wList
		
		NMMainHistory("", ccnt, wList, 0)
		
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
			NMHistory(StringFromList(wcnt, wList))
		endfor

	endfor
	
	return allList

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
	String wList, wName, allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
		
		wList = NMChanWaveList(ccnt)
		allList += wList
		
		for (wcnt = 0; wcnt < ItemsInlist(wList); wcnt += 1)
			wName = StringFromList(wcnt, wList)
			NMHistory("\r" + wName + " Notes:\r" + note($wName))
		endfor

	endfor
	
	return allList

End // NMPrintWaveNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDiffWavesCall(dtFlag)
	Variable dtFlag
	
	String df = MainDF()
	
	switch(dtFlag)
		case 1:
		case 2:
		case 3:
			break
		default:
			dtFlag = -1
	endswitch
	
	if (dtFlag < 0)
	
		dtFlag = NumVarOrDefault(df+"dtFlag", 1)
		
		Prompt dtFlag, "choose operation:", popup "d/dt;dd/dt*dt;integrate"
		DoPrompt NMPromptStr("Differentiate/Integrate"), dtFlag
		
		if (V_flag == 1)
			return "" // cancel
		endif
		
		SetNMvar(df+"dtFlag", dtFlag)
	
	endif
	
	NMCmdHistory("NMDiffWaves", NMCmdNum(dtFlag,""))
	
	return NMDiffWaves(dtFlag)

End // NMDiffWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDiffWaves(dtFlag)
	Variable dtFlag // (1) d/dt (2) dd/dt*dt (3) integral
	
	Variable ccnt
	String wList, fxn, outList, allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
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
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = DiffWaves(wList, dtFlag) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory(fxn, ccnt, outList, 0)
		
	endfor
	
	ChanGraphsUpdate(0)
	
	return allList

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
	String wList, outList, allList = ""
	
	DoAlert 1, "Warning: this function will permanently delete currently selected waves that are not in a table or graph. Do you want to continue?"
	
	if (V_Flag != 1)
		return "" // cancel
	endif
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = DeleteWaves(wList) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory("Deleted", ccnt, outList, 0)
		
	endfor
	
	ChanGraphsUpdate(0)
	
	return allList

End // NMDeleteWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeleteNANsCall()

	NMCmdHistory("NMDeleteNANs", "")

	return NMDeleteNANs()

End // NMDeleteNANsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeleteNANs()
	Variable ccnt, wcnt, error
	String wList, wname, outList = "", allList = "", badList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
		
			wname = StringFromList(wcnt, wList)
			error = DeleteNANs(wname, "U_TempWave", 0) // NM_Utility.ipf
			
			if ((error == 0) && (WaveExists(U_TempWave) == 1))
				Duplicate /O U_TempWave $wname
				outList = AddListItem(wName, outList, ";", inf)
			else
				badList = AddListItem(wName, badList, ";", inf)
			endif
			
		endfor
		
		allList += outList
		
		NMMainHistory("Deleted NANs", ccnt, outList, 0)
		
	endfor
	
	ChanGraphsUpdate(0)
	
	KillWaves /Z U_TempWave
	
	return allList

End // NMDeleteNANs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReplaceNanZeroCall(direction)
	Variable direction

	NMCmdHistory("NMReplaceNanZero", NMCmdNum(direction, ""))

	return NMReplaceNanZero(direction)

End // NMReplaceNanZeroCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReplaceNanZero(direction)
	Variable direction // (1) Nan > 0 (-1) 0 > Nan
	
	Variable ccnt, wcnt, error
	String wList, wname, outList = "", allList = "", badList = ""
	
	if ((direction != 1) && (direction != -1))
		return ""
	endif
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
		
			wname = StringFromList(wcnt, wList)
			
			if (WaveExists($wname) == 1)
				Wave wtemp = $wname
				wtemp = Nan2Zero(wtemp) // NM_Utility.ipf
				outList = AddListItem(wName, outList, ";", inf)
			else
				badList = AddListItem(wName, badList, ";", inf)
			endif
			
		endfor
		
		allList += outList
		
		switch(direction)
			case 1:
				NMMainHistory("Converted NANs > 0s", ccnt, outList, 0)
				break
			case -1:
				NMMainHistory("Converted 0s > NANs", ccnt, outList, 0)
				break
		endswitch
		
	endfor
	
	return allList

End // NMReplaceNanZero

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWavesCall()
	String vlist = "", df = MainDF()
	
	String newPrefix = "C_" + StrVarOrDefault(df + "CurrentPrefix", "Record")
	
	Variable select = 1 + NumVarOrDefault(df+"CopySelect", 1)
	Variable tbgn = -inf
	Variable tend = inf
	
	Prompt newPrefix, "enter new prefix name to attach to copied waves:"
	Prompt tbgn, "copy source waves from (ms):"
	Prompt tend, "copy source waves to (ms):"
	Prompt select, "select as current waves?", popup "no;yes;"
	
	DoPrompt NMPromptStr("Copy"), newPrefix, tbgn, tend, select
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	select -= 1
	
	SetNMvar(df+"CopySelect", select)
	
	vlist = NMCmdStr(newPrefix, vlist)
	vlist = NMCmdNum(tbgn, vlist)
	vlist = NMCmdNum(tend, vlist)
	vlist = NMCmdNum(select, vlist)
	
	NMCmdHistory("NMCopyWaves", vlist) 
	
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
	String wList, outList, allList = ""
	
	if (StringMatch(newPrefix, StrVarOrDefault("CurrentPrefix", "")) == 1)
		DoAlert 0, "Abort NMCopyWaves : this function is not to over-write currently active waves."
		return ""
	endif
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = CopyWaves(newPrefix+ "_" + ChanNum2Char(ccnt), tbgn, tend, wList) // NM_Utility.ipf
		allList += outList
	
		NMMainHistory("Copied to " + newPrefix + "*", ccnt, outList, 0)
		
	endfor
	
	if (ItemsInList(allList) > 0)
	
		NMPrefixAdd(newPrefix)
		
		if (select == 1)
			NMPrefixSelectSilent(newPrefix)
		endif
		
	endif
	
	return allList
	
End // NMCopyWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWavesToCall()
	String wList, vlist = "", df = MainDF()
	
	String cPrefix = StrVarOrDefault("CurrentPrefix", "")
	
	String newPrefix = cPrefix
	
	String toFolder = StrVarOrDefault(df+"Copy2Folder", "")
	Variable select = 0 + NumVarOrDefault(df+"Copy2Select", 1)
	
	Variable tbgn = -inf
	Variable tend = inf
		
	wList = NMDataFolderList()
	wList = RemoveFromList(GetDataFolder(0), wList)
	
	if (ItemsInlist(wList) <= 0)
		DoAlert 0, "No folders to copy to."
	endif
	
	Prompt toFolder, "copy selected waves to folder:", popup wList
	Prompt newPrefix, "prefix name for copied waves:"
	Prompt tbgn, "copy source waves from (ms):"
	Prompt tend, "copy source waves to (ms):"
	Prompt select, "select as current folder and waves?", popup "no;yes;"
	
	DoPrompt NMPromptStr("Copy"), toFolder, newPrefix, tbgn, tend//, select
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	if (StringMatch(toFolder[0,3], "root") == 0)
		toFolder = "root:" + toFolder
	endif
	
	select -= 1
	
	SetNMstr(df+"Copy2Folder", toFolder)
	SetNMvar(df+"Copy2Select", select)
	
	if (StringMatch(cPrefix, newPrefix) == 1)
		newPrefix = "" // use same prefix
	endif
	
	vlist = NMCmdStr(toFolder, "")
	vlist = NMCmdNum(tbgn, vlist)
	vlist = NMCmdNum(tend, vlist)
	vlist = NMCmdNum(1, vlist)
	vlist = NMCmdNum(select, vlist)
	NMCmdHistory("NMCopyWavesTo", vlist)
	
	return NMCopyWavesTo(toFolder, newPrefix, tbgn, tend, 1, select)
	
End // NMCopyWavesToCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWavesTo(toFolder, newPrefix, tbgn, tend, alert, select)
	String toFolder // where to move selected waves
	String newPrefix // new wave prefix, ("") for current prefix
	Variable tbgn, tend // copy data from, to
	Variable alert // (0) no copy alert (1) alert if over-writing
	Variable select // select as current prefix (0) no (1) yes
	
	Variable ccnt
	String wList, txt, outList, allList = ""
	
	String thisFolder = GetDataFolder(1)
	
	if (StringMatch(thisFolder, toFolder) == 1)
		return ""
	endif
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = CopyWavesTo(thisFolder, toFolder, newPrefix, tbgn, tend, wList, alert) // NM_Utility.ipf
		allList += outList
		
		//NMHistory("Copied to " + newPrefix + "* : " + NMMainHistory(ccnt, outList))

	endfor
	
	if (ItemsInList(allList) > 0)
	
		if (strlen(newPrefix) > 0)
			NMPrefixAdd(newPrefix)
		endif
		
		if (select == 1)
			NMFolderChange(toFolder) 
			NMPrefixSelectSilent(newPrefix)
		endif
		
	endif
	
	return allList
	
End // NMCopyWavesTo

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenameWavesCall(select)
	String select // ("All") search all waves ("Selected" or "") search selected waves
	
	String ptitle = "", vlist = "", df = MainDF()
	
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
	
	vlist = NMCmdStr(findstr, vlist)
	vlist = NMCmdStr(repstr, vlist)
	vlist = NMCmdStr(select, vlist)
	NMCmdHistory("NMRenameWaves", vlist)
	
	return NMRenameWaves(findstr, repstr, select)

End // NMRenameWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenameWaves(findstr, repstr, select)
	String findstr, repstr // find string, replace string
	String select // ("All") search all waves ("Selected" or "") search selected waves
	
	Variable ccnt
	String wList, outList, allList = ""
	
	if (strlen(findstr) <= 0)
		DoAlert 0, "Abort NMRenameWaves : bad search string parameter."
		return ""
	endif
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	strswitch(select)
	
		case "All":
			outList = RenameWaves(findstr, repstr, WaveList("*",";","")) // NM_Utility.ipf
			NMHistory("Renamed \"" + findstr + "*\" waves to : " + outList)
			return outList
			
		case "":
		case "Wave Select":
		case "Selected":
	
			for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
			
				if (ChanSelect[ccnt] != 1)
					continue
				endif
			
				wList = NMChanWaveList(ccnt)
				
				if (strlen(wList) == 0)
					continue
				endif
				
				outList = RenameWaves(findstr, repstr, wList) // NM_Utility.ipf
				allList += outList
				
				NMMainHistory("Renamed *" + findstr + "* waves to *" + repstr + "*", ccnt, outList, 0)
			
			endfor
			
			break
			
		default:
		
			DoAlert 0, "Abort NMRenameWaves : bad wave select parameter."
			return ""
	
	endswitch
	
	if (strlen(wList) > 0)
		DoAlert 0, "Alert: renamed waves may no longer be recognized by NeuroMatic. Use wave prefix popup to select appropriate waves."
	endif
	
	return allList

End // NMRenameWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenumWavesCall()
	String vlist = "", df = MainDF()

	Variable from = NumVarOrDefault(df+"RenumFrom", 0)
	
	Prompt from, "renumber selected waves from:"
	DoPrompt NMPromptStr("Renumber Waves"), from
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMvar(df+"RenumFrom", from)
	
	vlist = NMCmdNum(from, vlist)
	vlist = NMCmdNum(1, vlist)
	NMCmdHistory("NMRenumWaves", vlist)
	
	return NMRenumWaves(from, 1)

End // NMRenumWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenumWaves(from, alert)
	Variable from // start sequence number
	Variable alert // (0) no (1) yes
	
	Variable ccnt
	String wList = "", outList, allList = ""
	
	if ((from < 0) || (numtype(from) > 0))
		DoAlert 0, "Abort NMRenumWaves : bad sequence number parameter."
		return ""
	endif
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = RenumberWaves(from, wList) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory("Renumbered waves from " + num2str(from), ccnt, outList, 0)
	
	endfor
	
	if (alert == 1)
		DoAlert 0, "Alert: renumbered waves may no longer be recognized by NeuroMatic. Use wave prefix popup to select appropriate waves."
	endif
	
	return allList

End // NMRenumWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSmoothWavesCall()
	String vlist = "", df = MainDF()
	
	String smthAlg = StrVarOrDefault(df+"SmoothAlg", "binomial")
	Variable smthNum = NumVarOrDefault(df+"SmoothNum", 1)
	
	Prompt smthAlg, "choose smoothing algorithm:", popup "binomial;boxcar;polynomial"
	Prompt smthNum, "number of smoothing points/operations:"
	
	DoPrompt NMPromptStr("Smooth"), smthAlg, smthNum
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"SmoothAlg", smthAlg)
	SetNMvar(df+"SmoothNum", smthNum)
	
	vlist = NMCmdStr(smthAlg, vlist)
	vlist = NMCmdNum(smthNum, vlist)
	NMCmdHistory("NMSmoothWaves", vlist)
	
	return NMSmoothWaves(smthAlg, smthNum)
	
End // NMSmoothWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSmoothWaves(smthAlg, avgN)
	String smthAlg // "binomial", "boxcar" or "polynomial"
	Variable avgN
	
	Variable ccnt
	String wList, outList, allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
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
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
		
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = SmoothWaves(smthAlg, avgN, wList) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory("Smoothed " + num2str(avgN) + " pnt(s) " + smthAlg, ccnt, outList, 0)
		
	endfor
	
	ChanGraphsUpdate(0)
	
	return allList
	
End // NMSmoothWaves

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
	String wList, outList, allList = ""
	
	if ((ipnts < 0) || (numtype(ipnts) != 0))
		DoAlert 0, "Abort NMDecimateWaves : bad number of points."
		return ""
	endif
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
		
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = DecimateWaves(ipnts, wList) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory("Decimated " + num2str(ipnts) + " pnts", ccnt, outList, 0)
	
	endfor
	
	ChanGraphsUpdate(0)
	
	return allList

End // NMDecimateWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMInterpolateWavesCall()
	String wList, vlist = "", df = MainDF()
	
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
	
	vlist = NMCmdNum(alg, vlist)
	vlist = NMCmdNum(xmode, vlist)
	vlist = NMCmdStr(xwave, vlist)
	
	if (NMAllGroups() == 1)
		NMCmdHistory("NMInterpolateGroups", vlist)
		return NMInterpolateGroups(alg, xmode, xwave)
	else
		NMCmdHistory("NMInterpolateWaves", vlist)
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
	String outList, allList = ""
	
	String saveSelect = NMWaveSelectGet()
	String grpList = NMGroupList(1)
		
	for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
		NMWaveSelect(StringFromList(gcnt, grpList))
		outList = NMInterpolateWaves(alg, xmode, xwave)
		allList += outList
	endfor
	
	NMWaveSelect(saveSelect)
	
	return allList

End // NMInterpolateGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMInterpolateWaves(alg, xmode, xwave)
	Variable alg // (1) linear (2) cubic spline
	Variable xmode // (1) find common x-axis (2) use x-axis scale of xwave (3) use values of xwave as x-scale
	String xwave // wave for xmode 2 or 3
	
	Variable ccnt
	String wList, outList, allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)

		if (ChanSelect[ccnt] != 1)
			continue
		endif
			
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif

		outList = InterpolateWaves(alg, xmode, xwave, wList) // NM_Utility.ipf
		allList += outList

		if (xmode == 1)
			NMMainHistory("Interpolated to common x-axis", ccnt, outList, 0)
		elseif (xmode == 2)
			NMMainHistory("Interpolated to x-scale of " + xwave, ccnt, outList, 0)
		elseif (xmode == 3)
			NMMainHistory("Interpolated to data values of " + xwave, ccnt, outList, 0)
		endif
	
	endfor
	
	ChanGraphsUpdate(0)
	
	return allList

End // NMInterpolateWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlotCall(color)
	String color
	
	Variable samePlot
	String gName, vlist = "", df = MainDF()
	
	if (NMAllGroups() == 1)
	
		samePlot = 1 + NumVarOrDefault(df+"GroupsSamePlot", 1)
		
		Prompt samePlot, "plot all groups in the same plot?", popup "no;yes;"
		DoPrompt "Plot All Groups", samePlot
		
		if (V_flag == 1)
			return "" // cancel
		endif
	
		samePlot -= 1
		
		SetNMvar(df+"GroupsSamePlot", samePlot)
		
		vlist = NMCmdStr(color, vlist)
		vlist = NMCmdNum(samePlot, vlist)
		vlist = NMCmdNum(1, vlist) // plot backwards
		NMCmdHistory("NMPlotGroups", vlist)
		
		gName = NMPlotGroups(color, samePlot, 1)
		
	else
	
		NMCmdHistory("NMPlot", NMCmdStr(color, ""))
		
		gName = NMPlot(color)
		
	endif
	
	return gName

End // NMPlotCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlotGroups(color, samePlot, backwards)
	String color
	Variable samePlot // (0) no (1) yes
	Variable backwards // (0) no (1) yes
	
	Variable gcnt, pcnt, chan, cnum
	
	String saveSelect = NMWaveSelectGet()
	String gName, wList, plotList = "", grpList = NMGroupList(1)
	
	String colorList = "red;blue;green;purple;yellow;"
	
	if (samePlot == 0)
		
		for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
			NMWaveSelect(StringFromList(gcnt, grpList))
			gName = NMPlot(color)
			plotList = AddListItem(gName, plotList, ";", inf)
		endfor
		
	else
	
		if (backwards == 1)
			grpList = ReverseList(grpList, ";")
		endif
	
		NMWaveSelect(StringFromList(0, grpList))
		plotList = NMPlot("black")
		
		for (pcnt = 0; pcnt < ItemsInList(plotList); pcnt += 1)
		
			gName = StringFromList(pcnt, plotList)
			
			chan = ChanNumGet(gName)
			
			cnum = 0
		
			for (gcnt = 1; gcnt < ItemsInList(grpList); gcnt += 1)
			
				NMWaveSelect(StringFromList(gcnt, grpList))
				wList = NMChanWaveList(chan)
				color = StringFromList(cnum, colorList)
				NMPlotAppend(gName, color, wList)
				
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

Function /S NMPlot(color)
	String color // "black", "red", "green", "blue", "yellow", "purple", or ("") default

	Variable ccnt, error, r, g, b
	String xl, yl, wList, gPrefix, gName, gTitle, gList = "", df = MainDF()
	
	String prefix = StrVarOrDefault("CurrentPrefix", "")
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
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
	endswitch
	
	SetNMstr(df+"PlotColor", color)
	
	Wave ChanSelect

	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
			
		gPrefix = MainPrefix("") + NMFolderPrefix("") + NMWaveSelectStr() + "_Plot_"
		gName = NextGraphName(gPrefix, ccnt, NMOverWrite())
		gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : " + prefix + " : " + NMWaveSelectGet()

		wList = NMChanWaveList(ccnt)
		xl = ChanLabel(ccnt, "x", wList)
		yl = ChanLabel(ccnt, "y", wList)
		
		error = NMPlotWaves(gName, gTitle, xl, yl, wList) // NM_Utility.ipf
		
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
	
End // NMPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPlotAppend(gName, color, wList)
	String gName // graph Name
	String color // "black", "red", "green", "blue", "yellow", "purple", or ("") default
	String wList // wave list

	Variable r, g, b, wcnt
	String wname
	
	if (WinType(gName) != 1)
		return -1
	endif
	
	if (ItemsInList(wList) == 0)
		return 0
	endif
	
	if (strlen(color) == 0)
		color = "black"
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
	endswitch
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wname = StringFromList(wcnt, wList)
		
		if (WaveExists($wname) == 0)
			continue
		endif
		
		AppendToGraph /W=$gName/C=(r,g,b) $wname
		
	endfor
	
	return 0
	
End // NMPlotAppend

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
	String tList, allList = ""
	
	String saveSelect = NMWaveSelectGet()
	String grpList = NMGroupList(1)
		
	for (gcnt = 0; gcnt < ItemsInList(grpList); gcnt += 1)
		NMWaveSelect(StringFromList(gcnt, grpList))
		tlist = NMEditWaves()
		allList += tlist
	endfor
	
	NMWaveSelect(saveSelect)
	
	return allList

End // NMEditGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEditWaves()
	Variable ccnt, error
	String tPrefix, tName, tTitle, tList = ""
	
	String prefix = StrVarOrDefault("CurrentPrefix", "")
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
			
		tPrefix = MainPrefix("") + NMFolderPrefix("") + NMWaveSelectStr() + "_Table_"
		tName = NextGraphName(tPrefix, ccnt, NMOverWrite())
		tTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : " + prefix + " : " + NMWaveSelectGet()

		error = EditWaves(tName, tTitle, NMChanWaveList(ccnt)) // NM_Utility.ipf
		
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

	NMCmdHistory("NMReverseWaves", "")
	
	return NMReverseWaves()

End // NMReverseWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReverseWaves()

	Variable ccnt
	String wList, outList, allList = "", df = MainDF()
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = ReverseWaves(wList) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory("Reflected", ccnt, outList, 0)
	
	endfor
	
	ChanGraphsUpdate(0)
	
	return allList
	
End // NMReverseWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXAlignWavesCall()
	Variable startx, alignbywave, error

	String wList, vlist = "", df = MainDF()
	
	String xwname = StrVarOrDefault(df+"XAlignWName", "")
	Variable postime = NumVarOrDefault(df+"XAlignPosTime", 1)
	Variable intrp = NumVarOrDefault(df+"XAlignInterp", 0)
	
	wList = WaveListOfSize(NumVarOrDefault("NumWaves",0), "!" + StrVarOrDefault("WavePrefix","") + "*")
	wList = RemoveFromList("WavSelect", wList)
	wList = RemoveFromList("Group", wList)
	wList = AddListItem(" ", wList, ";", -inf) // add space to beginning
	wList = RemoveListFromList(NMSetsList(1), wList, ";")
	
	xwname = ""

	postime += 1
	intrp += 1
	
	Prompt startx, "align waves at time (ms):"
	Prompt xwname, "or choose a wave of alignment values:", popup wList
	Prompt postime, "if using a wave, allow only positive time values?", popup "no;yes"
	Prompt intrp, "if using a wave, make alignments permanent by interpolation?", popup "no;yes"
	
	if (ItemsInList(wList) == 1)
		DoPrompt NMPromptStr("Time Scale Alignment"), startx
	else
		DoPrompt NMPromptStr("Time Scale Alignment"), startx, xwname, postime, intrp
	endif
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	postime -= 1
	intrp -= 1
	
	if (strlen(xwname) > 1)
		alignbywave = 1
	endif
	
	if (alignbywave == 1)
	
		SetNMstr(df+"XAlignWName", xwname)
		SetNMvar(df+"XAlignPosTime", postime)
		SetNMvar(df+"XAlignInterp", intrp)
	
		vlist = NMCmdStr(xwname, vlist)
		vlist = NMCmdNum(postime, vlist)
		NMCmdHistory("NMXAlignWaves", vlist)
		
		wList = NMXAlignWaves(xwname, postime)
		
		if (intrp == 1)
		
			vlist = NMCmdNum(1, "")
			vlist = NMCmdNum(1, vlist)
			vlist = NMCmdStr("", vlist)
			
			NMCmdHistory("NMInterpolateWaves", vlist)
			
			NMInterpolateWaves(1, 1, "")
			
		endif
		
		return wList
	
	else
	
		NMCmdHistory("NMStartX", NMCmdNum(startx, ""))
		
		return NMStartX(startx)
	
	endif

End // NMXAlignWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXAlignWaves(xwname, postime)
	String xwname // wave name of x align values
	Variable postime // allow only positive time values? (0) no (1) yes
	
	Variable ccnt, wcnt, error, offset, maxoffset
	String wList, wName, outList = "", allList = "", badList = ""
	
	if ((WaveExists(ChanSelect) == 0) || (WaveExists($xwname) == 0))
		return ""
	endif
	
	Wave ChanSelect
		
	Wave offsetWave = $xwname
		
	if (postime == 1)
		WaveStats /Q offsetWave
		maxoffset = V_max
	endif
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
		
		wList = NMChanWaveList(ccnt)
		
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1) // align by wave of offset values
	
			wName = StringFromList(wcnt, wList)
			
			if (exists(wName) == 0)
				continue
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
				outList = AddListItem(wName, outList, ";", inf)
			endif
		
		endfor
		
		allList += outList
			
		if (postime == 1)
			NMMainHistory("X-Aligned at " + num2str(maxoffset) + " ms (offset wave:" + xwname + ")", ccnt, outList, 0)
		else
			NMMainHistory("X-Aligned at 0 ms (offset wave:" + xwname + ")", ccnt, outList, 0)
		endif
		
	endfor
	
	ChanGraphsUpdate(0)
	
	if (ItemsInlist(badList) > 0)
		DoAlert 0, "Warning: x-alignment not performed on the following waves due to bad input values : " + badList
	endif
	
	return allList

End // NMXAlignWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStartXCall()
	Variable startx
	
	Prompt startx, "time begin (ms):"
	DoPrompt NMPromptStr("Set Time Scale"), startx
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	NMCmdHistory("NMStartX", NMCmdNum(startx, ""))
	
	return NMStartX(startx)
	
End // NMXScaleWavesCall

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

	String vlist = ""
	String yLabel = ChanLabel(-1, "y", "")
	
	Prompt yLabel, "label:"
	DoPrompt "Set Y-Axis Label", yLabel
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	vlist = NMCmdStr("y", vlist)
	vlist = NMCmdStr(yLabel, vlist)
	
	NMCmdHistory("NMLabel", vlist)
	
	return NMLabel("y", yLabel)
	
End // NMYLabelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXLabelCall()

	String vlist = ""
	String xLabel = ChanLabel(-1, "x", "")
	
	Prompt xLabel, "label:"
	DoPrompt "Set Time Axis Label", xLabel
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	vlist = NMCmdStr("x", vlist)
	vlist = NMCmdStr(xLabel, vlist)
	
	NMCmdHistory("NMLabel", vlist)
	
	return NMLabel("x", xLabel)
	
End // NMXLabelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLabel(xy, labelStr)
	String xy // "x" or "y"
	String labelStr
	
	Variable ccnt
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		ChanLabelSet(ccnt, 1, xy, labelStr)
		
	endfor
	
	ChanGraphsUpdate(1)
	
	return labelStr
	
End // NMLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXScaleWaves(startx, dx, npnts)
	Variable startx // time begin (Nan) dont change
	Variable dx // time step (-1) dont change
	Variable npnts // number of points (-1) dont change

	Variable ccnt
	String wList, paramstr = "", outList, allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
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
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
		
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
	
		outList = SetXScale(startx, dx, npnts, wList) // NM_Utility.ipf
		allList += outList
	
		NMMainHistory("X-scale (" + paramstr + ")", ccnt, outList, 0)
		
	endfor
	
	ChanGraphsUpdate(0)
	
	return allList
	
End // NMXScaleWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByNumCall()
	Variable npnts
	String vlist = "", df = MainDF()
	
	String alg = StrVarOrDefault(df+"ScaleByNumAlg", "*")
	Variable value = NumVarOrDefault(df+"ScaleByNumVal", 1)
		
	Prompt alg, "function:", popup " *; /; +; -"
	Prompt value, "scale value:"
	
	DoPrompt NMPromptStr("Scale By Number"), alg, value
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	alg = alg[1] // remove space from beginning of alg string
	
	SetNMstr(df+"ScaleByNumAlg", alg)
	SetNMvar(df+"ScaleByNumVal", value)
	
	vlist = NMCmdStr(alg, vlist)
	vlist = NMCmdNum(value, vlist)
	NMCmdHistory("NMScaleByNum", vlist)
	
	return NMScaleByNum(alg, value)

End // NMScaleByNumCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByNum(alg, value)
	String alg // "*", "/", "+" or "-"
	Variable value // scale by value
	
	//if (numtype(value) != 0)
	//	DoAlert 0, "Abort NMScaleByNum : bad scale value : " + num2str(value)
	//	return ""
	//endif
	
	strswitch(alg)
		case "*":
		case "/":
		case "+":
		case "-":
			break
		default:
			DoAlert 0, "Abort NMScaleByNum : bad algorithm : " + alg
			return ""
	endswitch

	Variable ccnt, wcnt
	String wList, wName, outList, allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = ScaleByNum(alg, value, wList) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory("Y-scale (" + alg + num2str(value) + ")", ccnt, outList, 0)
	
	endfor
	
	ChanGraphsUpdate(0)
	
	KillWaves /Z U_ScaleWave
	
	return allList

End // NMScaleByNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleWaveCall()
	Variable npnts
	String vlist = "", df = MainDF()
	
	String alg = StrVarOrDefault(df+"ScaleWaveAlg", "*")
	Variable value = NumVarOrDefault(df+"ScaleWaveVal", 1)
	Variable tbgn = NumVarOrDefault(df+"ScaleWaveTbgn", -inf)
	Variable tend = NumVarOrDefault(df+"ScaleWaveTend", inf)
		
	Prompt alg, "function:", popup " *; /; +; -"
	Prompt value, "scale value:"
	Prompt tbgn, "time begin:"
	Prompt tend, "time end:"
	
	DoPrompt NMPromptStr("Scale Wave By Number"), alg, value, tbgn, tend
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	alg = alg[1] // remove space from beginning of alg string
	
	SetNMstr(df+"ScaleWaveAlg", alg)
	SetNMvar(df+"ScaleWaveVal", value)
	SetNMvar(df+"ScaleWaveTbgn", tbgn)
	SetNMvar(df+"ScaleWaveTend", tend)
	
	if ((numtype(tbgn) == 1) && (numtype(tend) == 1))
	
		vlist = NMCmdStr(alg, vlist)
		vlist = NMCmdNum(value, vlist)
		NMCmdHistory("NMScaleByNum", vlist)
		
		return NMScaleByNum(alg, value)
	
	else
	
		vlist = NMCmdStr(alg, vlist)
		vlist = NMCmdNum(value, vlist)
		vlist = NMCmdNum(tbgn, vlist)
		vlist = NMCmdNum(tend, vlist)
		NMCmdHistory("NMScaleWave", vlist)
		
		return NMScaleWave(alg, value, tbgn, tend)
	
	endif
	
End // NMScaleWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleWave(alg, value, tbgn, tend)
	String alg // "*", "/", "+" or "-"
	Variable value // scale by value
	Variable tbgn, tend
	
	//if (numtype(value) != 0)
	//	DoAlert 0, "Abort NMScaleWave : bad scale value : " + num2str(value)
	//	return ""
	//endif
	
	strswitch(alg)
		case "*":
		case "/":
		case "+":
		case "-":
			break
		default:
			DoAlert 0, "Abort NMScaleWave : bad algorithm : " + alg
			return ""
	endswitch

	Variable ccnt, wcnt
	String wList, wName, outList, allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = ScaleWave(alg, value, tbgn, tend, wList) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory("Y-scale (" + alg + num2str(value) + "; t=" + num2str(tbgn) + "," + num2str(tend) + ")", ccnt, outList, 0)
	
	endfor
	
	ChanGraphsUpdate(0)
	
	KillWaves /Z U_ScaleWave
	
	return allList

End // NMScaleWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByWaveCall()
	Variable npnts
	String wList, wList2, wSelect = "", wSelect2 = "", vlist = "", df = MainDF()
	
	Variable method = NumVarOrDefault(df+"ScaleByWaveMthd", 0)
	String alg = StrVarOrDefault(df+"ScaleByWaveAlg", "*")
	String swname =  StrVarOrDefault(df+"ScaleByWaveName", "")
	
	wList = " ;" + WaveListOfSize(numpnts(WavSelect), "!" + StrVarOrDefault("WavePrefix","") + "*")

	wList = RemoveFromList("WavSelect", wList)
	wList = RemoveFromList("Group", wList)
	wList = RemoveFromList("WavSelect", wList)
	wList = RemoveListFromList(NMSetsList(1), wList, ";")
	
	wList2 = CurrentChanWaveList()
	
	npnts = numpnts($StringFromList(0, wList2)) // size of first selected wave
	
	wList2 = " ;" + WaveListOfSize(npnts, "*")
	
	Prompt alg, "function:", popup " *; /; +; -"
	Prompt wSelect, "choose a wave of scale values:", popup wList
	Prompt wSelect2, "or choose a wave to scale by:", popup wList2
	
	DoPrompt NMPromptStr("Scale by Wave"), alg, wSelect, wSelect2
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	if ((StringMatch(wSelect, " ") == 0) && (StringMatch(wSelect2, " ") == 0))
		DoAlert 0, "Abort NMScaleWaves : more than one scale wave was chosen."
		return ""
	elseif (StringMatch(wSelect, " ") == 0)  // scale by wave of values
		method = 1
		swname = wSelect
	elseif (StringMatch(wSelect2, " ") == 0) // scale by wave
		method = 2
		swname = wSelect2
	endif
	
	alg = alg[1] // remove space from beginning of alg string
	
	SetNMvar(df+"ScaleByWaveMthd", method)
	SetNMstr(df+"ScaleByWaveAlg", alg)
	SetNMstr(df+"ScaleByWaveName", swname)
	
	vlist = NMCmdNum(method, vlist)
	vlist = NMCmdStr(alg, vlist)
	vlist = NMCmdStr(swname, vlist)
	NMCmdHistory("NMScaleByWave", vlist)
	
	return NMScaleByWave(method, alg, swname)

End // NMScaleByWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByWave(method, alg, swname)
	Variable method // (1) scale by wave of values (2) scale by wave
	String alg // "*", "/", "+" or "-"
	String swname // scale wave name

	Variable ccnt, wcnt
	String wList, wName, outList = "", allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
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
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1) // loop thru channels
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
			wName = StringFromList(wcnt, wList)
			
			if (exists(wName) == 0)
				continue
			endif
		
			if (method == 1)

				wName = ScaleByNum(alg, scalewave[ChanWaveNum(wName)], wName) // NM_Utility.ipf
				
			elseif (method == 2)
			
				wName = ScaleByWave(alg, "U_ScaleWave", wName) // NM_Utility.ipf
				
			endif
			
			if (strlen(wName) > 0)
				outList = AddListItem(wName, outList, ";", inf)
			endif
		
		endfor
		
		allList += outList
		
		if (method == 1)
			NMMainHistory("Y-scale (" + alg + swname + ")", ccnt, outList, 0)
		elseif (method == 2)
			NMMainHistory("Y-scale (" + alg + swname + ")", ccnt, outList, 0)
		endif
	
	endfor
	
	ChanGraphsUpdate(0)
	
	KillWaves /Z U_ScaleWave
	
	return allList

End // NMScaleByWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBaselineCall()
	String vlist = "", df = MainDF()
	
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
	
	vlist = NMCmdNum(tbgn, vlist)
	vlist = NMCmdNum(tend, vlist)
	
	if (method == 1)
		NMCmdHistory("NMBslnWaves", vlist)
		return NMBslnWaves(tbgn, tend)
	elseif (method == 2)
		NMCmdHistory("NMBslnAvgWaves", vlist)
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
	
	Variable ccnt
	String wList, outList, allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	if ((tend <= tbgn) || (numtype(tbgn*tend) != 0))
		DoAlert 0, "Abort NMBaselineWaves : bad input parameters."
		return ""
	endif
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
		
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = BaselineWaves(method, tbgn, tend, wList) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory("Baselined (t=" + num2str(tbgn) + "," + num2str(tend) + ")", ccnt, outList, 0)
		
	endfor
	
	ChanGraphsUpdate(0)
	
	return allList

End // NMBaselineWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAvgWavesCall()
	String vlist = "", df = MainDF(), ndf = NMDF(), cdf = ChanDF(-1)
	
	String wselect = NMWaveSelectGet()
	
	Variable grpsOn = NumVarOrDefault(ndf+"GroupsOn", 0)
	
	Variable smthn = NumVarOrDefault(cdf+"smthNum", 0)
	Variable dt = NumVarOrDefault(cdf+"DTflag", 0)
	
	Variable mode = NumVarOrDefault(df+"AvgMode", 2)
	Variable dsply = NumVarOrDefault(df+"AvgDisplay", 1)
	Variable chanFlag = NumVarOrDefault(df+"AvgChanFlag", 0)
	Variable allGrps = NumVarOrDefault(df+"AvgAllGrps", 0)
	Variable grpDsply = NumVarOrDefault(df+"AvgGrpDisplay", 1)
	
	dsply += 1
	chanFlag += 1
	allGrps += 1
	grpDsply += 1

	Prompt mode, "compute:", popup"mean;mean + stdv;mean + var;mean + sem"
	Prompt dsply, "display data with results?", popup, "no;yes;"
	Prompt chanFlag, "use channel smooth and F(t)?", popup "no;yes;"
	Prompt allGrps, "average all groups?", popup, "no;yes;"
	
	if (StringMatch(wselect, "All Groups") == 1)
	
		allGrps = 1
		
		Prompt grpDsply, "display groups in same plot?", popup, "no;yes;"
	
		if (smthn + dt > 0)
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
	
		if ((grpsOn == 1)  && (StringMatch(wselect, "*group*") == 0))
		
			Prompt grpDsply, "if yes, display group averages in same plot?", popup, "no;yes;"
		
			if (smthn + dt > 0)
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
	
			if (smthn + dt > 0)
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
	
	SetNMvar(df+"AvgMode", mode)
	SetNMvar(df+"AvgDisplay", dsply)
	
	vlist = NMCmdNum(mode, vlist)
	vlist = NMCmdNum(dsply, vlist)
	vlist = NMCmdNum(chanFlag, vlist)
	vlist = NMCmdNum(allGrps, vlist)
	vlist = NMCmdNum(grpDsply, vlist)
	NMCmdHistory("NMAvgWaves", vlist)
	
	return NMAvgWaves(mode, dsply, chanFlag, allGrps, grpDsply)

End // NMAvgWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAvgWaves(mode, dsply, chanFlag, allGrps, grpDsply)
	Variable mode // (1) mean (2) mean + stdv (3) mean + var (4) mean + sem
	Variable dsply // display data waves? (0) no (1) yes
	Variable chanFlag // use channel F(t) and smooth? (0) no (1) yes
	Variable allGrps // average all groups? (0) no (1) yes
	Variable grpDsply // display groups together? (0) no (1) yes

	Variable nwaves, ccnt, gcnt, grpbeg, grpend, wcnt, overwrite
	String gPrefix, gName, gList = "", gTitle, wList, sName, pName = ""
	String outList, allList = ""
	String avgPrefix, avgName, sdPrefix, sdName, sdpName, sdmName
	
	String df = MainDF(), ndf = NMDF()
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Variable NameFormat = NumVarOrDefault(ndf+"NameFormat", 1)
	
	Wave ChanSelect, WavSelect
	
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
	sdPrefix = "Avg"
	
	switch(mode)
		case 1:
		case 2:
			sdPrefix += "SDV"
			break
		case 3:
			sdPrefix += "VAR"
			break
		case 4:
			sdPrefix += "SEM"
			break
		default:
			DoAlert 0, "Abort NMAvgWaves : bad mode selection."
			return ""
	endswitch
	
	overwrite = NMOverWrite()
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)

		if (ChanSelect[ccnt] != 1)
			continue
		endif

		for (gcnt = grpbeg; gcnt <= grpend; gcnt += 1)
	
			if ((allgrps > 0) && (NMGroupCheck(gcnt) == 1))
				
				if (allgrps == 1)
					NMWaveSelect(wselect + " x Group" + num2str(gcnt))
				elseif (allgrps == 2)
					NMWaveSelect("Group" + num2str(gcnt))
				endif
				
			endif
			
			wList = NMChanWaveList(ccnt)
			
			nwaves = ItemsInList(wList)
			
			if (nwaves == 0)
				continue
			endif
			
			if (chanFlag == 1)
				outList = AvgChanWaves(ccnt, wList) // NM_Utility.ipf
			else
				outList = AvgWaves(wList) // NM_Utility.ipf
			endif
			
			allList += outList
			
			if (wcnt < 0)
				break
			endif
			
			gPrefix= MainPrefix("") + NMFolderPrefix("") + "Avg_" + NMWaveSelectStr() + "_"
			
			if (NameFormat == 1)
				pName = NMWaveSelectStr() + "_"
			endif
			
			gName = NextGraphName(gPrefix, ccnt, overwrite)
			avgName = NextWaveName(avgPrefix+pName, ccnt, overwrite)
			sdName = NextWaveName(sdPrefix + "_" + pName, ccnt, overwrite)
			sdpName = NextWaveName(sdPrefix + "p_" + pName, ccnt, overwrite)
			sdmName = NextWaveName(sdPrefix + "n_" + pName, ccnt, overwrite)
			
			Duplicate /O U_Avg $avgName // save average wave
	
			if (grpDsply == 1) // all Groups in one display
			
				if (gcnt == grpbeg)
				
					gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : All Groups"
					
					if (dsply == 1)
						NMPlotWaves(gName, gTitle, "", "", wList)
						AppendToGraph $avgName
					else
						NMPlotWaves(gName, gTitle, "", "", avgName)
						ModifyGraph rgb=(65535,0,0)
					endif
					
				else
				
					AppendToGraph $avgName
					
				endif
				
			else
			
				gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : " + avgName
				
				if (dsply == 1)
					NMPlotWaves(gName, gTitle, "", "", wList)
					AppendToGraph $avgName
				else
					NMPlotWaves(gName, gTitle, "", "", avgName)
					ModifyGraph rgb=(65535,0,0)
				endif
				
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
					sdvp = sdv
					sdvn = sdv
				elseif (mode == 4)
					sdv /= sqrt(nwaves) // standard error
					sdvp = sdv
					sdvn = sdv
				endif
			
				sdvp = avg + sdvp
				sdvn = avg - sdvn
				
				AppendToGraph /C=(1,16019,65535) $sdpName, $sdmName
				
			endif
			
			if (ItemsInList(gList) == 0)
				gList = gName
			else
				gList = AddListItem(gName, gList, ";", inf)
			endif
			
			NMMainHistory(avgName, ccnt, outList, 0)
		
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
	
	return allList

End // NMAvgWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSumWavesCall()
	String vlist = "", df = MainDF(), ndf = NMDF(), cdf = ChanDF(-1)
	
	String wselect = NMWaveSelectGet()
	
	Variable grpsOn = NumVarOrDefault(ndf+"GroupsOn", 0)
	
	Variable smthn = NumVarOrDefault(cdf+"smthNum", 0)
	Variable dt = NumVarOrDefault(cdf+"DTflag", 0)
	
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
	
		if (smthn + dt > 0)
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
		
			if (smthn + dt > 0)
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
	
			if (smthn + dt > 0)
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
	
	vlist = NMCmdNum(dsply, vlist)
	vlist = NMCmdNum(chanFlag, vlist)
	vlist = NMCmdNum(allGrps, vlist)
	vlist = NMCmdNum(grpDsply, vlist)
	NMCmdHistory("NMSumWaves", vlist)
	
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
	String gPrefix, gName, gList = "", gTitle, wList, sName, pName = ""
	String outList, allList = ""
	String sumPrefix, sumName
	
	String df = MainDF(), ndf = NMDF()
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Variable NameFormat = NumVarOrDefault(ndf+"NameFormat", 1)
	
	Wave ChanSelect, WavSelect
	
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
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)

		if (ChanSelect[ccnt] != 1)
			continue
		endif

		for (gcnt = grpbeg; gcnt <= grpend; gcnt += 1)
	
			if ((allgrps > 0) && (NMGroupCheck(gcnt) == 1))
				
				if (allgrps == 1)
					NMWaveSelect(wselect + " x Group" + num2str(gcnt))
				elseif (allgrps == 2)
					NMWaveSelect("Group" + num2str(gcnt))
				endif
				
			endif
			
			wList = NMChanWaveList(ccnt)
			
			nwaves = ItemsInList(wList)
			
			if (nwaves == 0)
				continue
			endif
			
			if (chanFlag == 1)
				outList = SumChanWaves(ccnt, wList) // NM_Utility.ipf
			else
				outList = SumWaves(wList) // NM_Utility.ipf
			endif
			
			allList += outList
			
			if (wcnt < 0)
				break
			endif
			
			gPrefix= MainPrefix("") + NMFolderPrefix("") + "Sum_" + NMWaveSelectStr() + "_"
			
			if (NameFormat == 1)
				pName = NMWaveSelectStr() + "_"
			endif
			
			gName = NextGraphName(gPrefix, ccnt, overwrite)
			sumName = NextWaveName(sumPrefix+pName, ccnt, overwrite)
			
			Duplicate /O U_Sum $sumName // save output wave
	
			if (grpDsply == 1) // all Groups in one display
			
				if (gcnt == grpbeg)
				
					gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : All Groups"
					
					if (dsply == 1)
						NMPlotWaves(gName, gTitle, "", "", wList)
						AppendToGraph $sumName
					else
						NMPlotWaves(gName, gTitle, "", "", sumName)
						ModifyGraph rgb=(65535,0,0)
					endif
					
				else
				
					AppendToGraph $sumName
					
				endif
				
			else
			
				gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : " + sumName
				
				if (dsply == 1)
					NMPlotWaves(gName, gTitle, "", "", wList)
					AppendToGraph $sumName
				else
					NMPlotWaves(gName, gTitle, "", "", sumName)
					ModifyGraph rgb=(65535,0,0)
				endif
				
			endif
			
			if (ItemsInList(gList) == 0)
				gList = gName
			else
				gList = AddListItem(gName, gList, ";", inf)
			endif
			
			NMMainHistory(sumName, ccnt, outList, 0)
		
		endfor // groups
		
	endfor // channels
	
	if (allgrps > 0)
		NMWaveSelect(saveSelect)
	endif
	
	NMNoteStrReplace(sumName, "Source", sumName)
	
	Killwaves /Z U_Sum
	
	return allList

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
	
	String vlist = "", df = MainDF()
	
	Variable rx = rightx($CurrentChanDisplayWave())
	
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
	
	vlist = NMCmdNum(chX, vlist)
	vlist = NMCmdStr(fxnX, vlist)
	vlist = NMCmdNum(tbgnX, vlist)
	vlist = NMCmdNum(tendX, vlist)
	vlist = NMCmdNum(chY, vlist)
	vlist = NMCmdStr(fxnY, vlist)
	vlist = NMCmdNum(tbgnY, vlist)
	vlist = NMCmdNum(tendY, vlist)
	NMCmdHistory("NMIV", vlist)
	
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
	
	wName1 = NextWaveName(MainPrefix("") + aName + "_", chY, overwrite)
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
	
	wName2 = NextWaveName(MainPrefix(aName + "_"), chX, overwrite)
	Duplicate /O $uName $wName2
	
	NMNoteStrReplace(wName2, "Source", wName2)
	
	KillWaves /Z U_AmpX, U_AmpY
	
	gPrefix = MainPrefix("") + NMFolderPrefix("") + NMWaveSelectStr() + "_IV" + aName
	gName = NextGraphName(gPrefix, -1, overwrite)
	gTitle = NMFolderListName("") + " : IV : " + wName2
	
	DoWindow /K $gName
	Display /K=1/W=(0,0,0,0) $wName1 vs $wName2 as gTitle
	DoWindow /C $gName
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

Function /S NMNormWavesCall()
	String vlist = "", df = MainDF()
	
	Variable rx = rightx($CurrentChanDisplayWave())
	
	String fxn = StrVarOrDefault(df+"NormFxn", "max")
	
	Variable bbgn = NumVarOrDefault(df+"Bsln_Bgn", 0)
	Variable bend = NumVarOrDefault(df+"Bsln_End", 5)
	
	Variable tbgn = NumVarOrDefault(df+"NormTbgn", bbgn)
	Variable tend = NumVarOrDefault(df+"NormTend", bend)
	
	Prompt tbgn, "measure baseline from (ms):"
	Prompt tend, "measure baseline to (ms):"
	Prompt fxn, "normalize waves to:", popup "max;min;"
	
	DoPrompt NMPromptStr("Normalize"), fxn, tbgn, tend
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	SetNMstr(df+"NormFxn", fxn)
	SetNMvar(df+"NormTbgn", tbgn)
	SetNMvar(df+"NormTend", tend)
	
	vlist = NMCmdStr(fxn, vlist)
	vlist = NMCmdNum(tbgn, vlist)
	vlist = NMCmdNum(tend, vlist)
	NMCmdHistory("NMNormWaves", vlist)
	
	return NMNormWaves(fxn, tbgn, tend)
	
End // NMNormWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNormWaves(fxn, tbgn, tend)
	String fxn // "max" or "min"
	Variable tbgn, tend
	
	Variable ccnt
	String wList, outList, allList = ""
	
	if ((tend <= tbgn) || (numtype(tbgn*tend) != 0))
		DoAlert 0, "Abort NMNormWaves : bad input parameters."
		return ""
	endif
	
	strswitch(fxn)
		case "min":
		case "max":
			break
		default:
			DoAlert 0, "Abort NMNormWaves : bad function parameter."
			return ""
	endswitch
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		outList = NormWaves2Bsln(fxn, tbgn, tend, wList) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory("Normalized to baseline" + fxn + " (t=" + num2str(tbgn) + "," + num2str(tend) + ")", ccnt, outList, 0)
		
	endfor
	
	ChanGraphsUpdate(0)
	
	return allList
	
End // NMNormWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConcatWavesCall()
	String df = MainDF()
	
	String wprefix = StrVarOrDefault(df+"ConcatPrefix", MainPrefix("Concat"))
		
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
	String wname, wList, outList, allList = ""
	
	if (WaveExists(ChanSelect) == 0)
		return ""
	endif
	
	Wave ChanSelect
	
	for (ccnt = 0; ccnt < numpnts(ChanSelect); ccnt += 1)
	
		if (ChanSelect[ccnt] != 1)
			continue
		endif
	
		wList = NMChanWaveList(ccnt)
		
		if (strlen(wList) == 0)
			continue
		endif
		
		wname = NextWaveName(wprefix + "_", ccnt, NMOverWrite())
		outList = ConcatWaves(wList, wname) // NM_Utility.ipf
		allList += outList
		
		NMMainHistory("Concatenate " + wname, ccnt, outList, 0)
		
	endfor
	
	NMPrefixAdd(wprefix)
	ChanGraphsUpdate(0)
	
	return allList

End // NMConcatWaves

//****************************************************************
//****************************************************************
//****************************************************************


