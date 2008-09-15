#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Fit Tab
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 9 July 2007
//	Last modified 21 Jan 2008
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S FitPrefix(varName) // tab prefix identifier
	String varName
	
	return "FT_" + varName
	
End // FitPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FitDF() // package full-path folder name

	return PackDF("Fit")
	
End // FitDF

//****************************************************************
//****************************************************************
//****************************************************************

Function FitTab(enable)
	Variable enable // (0) disable (1) enable tab
	
	if (enable == 1)
		CheckPackage("Fit", 1) // declare globals if necessary
		ChanControlsDisable(-1, "000000")
		NMFitMake() // create tab controls if necessary
		NMFitUpdate()
		AutoFit()
	else
		NMFitRemoveDisplayWaves()
	endif

End // FitTab

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoFit()
	String df = FitDF()
	String dwave = NMFitDisplayWaveName()
	
	String gName = CurrentChanGraphName()
	String fitWave = NMFitWaveName(-1)
	
	if (WaveExists($dwave) == 1)
		Wave wtemp = $dwave
		wtemp = Nan
	endif

	if (WaveExists(W_coef) == 1)
		Wave wtemp = W_coef
		wtemp = Nan
	endif
	
	if (WaveExists(W_sigma) == 1)
		Wave wtemp = W_sigma
		wtemp = Nan
	endif
	
	NMFitRemoveDisplayWaves()
	
	if (NMFitAuto() == 1)
		NMFitWave()
	else
		if ((WinType(gName) == 1) && (WaveExists($fitWave) == 1))
			AppendToGraph /W=$gName $fitWave
		endif
	endif

End // AutoFit

//****************************************************************
//****************************************************************
//****************************************************************

Function KillFit(what)
	String what
	String df = FitDF()

	// TabManager will automatically kill objects that begin with appropriate prefix
	// place any other things to kill here.
	
	strswitch(what)
	
		case "waves":
			// kill any other waves here
			break
			
		case "folder":
			if (DataFolderExists(df) == 1)
				KillDataFolder $df
			endif
			break
			
	endswitch

End // KillFit

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckFit() // declare global variables

	String df = FitDF()
	
	if (DataFolderExists(df) == 0)
		return -1 // folder doesnt exist
	endif
	
	CheckNMvar(df+"UserInput", 0)
	CheckNMvar(df+"Tbgn", -inf)
	CheckNMvar(df+"Tend", inf)
	CheckNMvar(df+"Cursors", 0)
	CheckNMvar(df+"FitAuto", 0)
	CheckNMvar(df+"FitNumPnts", Nan)
	CheckNMvar(df+"MaxIterations", 40)
	CheckNMvar(df+"SaveFitWaves", 1)
	CheckNMvar(df+"FullGraphWidth", 0)
	CheckNMvar(df+"Print", 1)
	CheckNMvar(df+"WeightStdv", 0)
	
	CheckNMstr(df+"Function", "")
	CheckNMstr(df+"FxnShort", "")
	CheckNMstr(df+"Equation", "")
	CheckNMstr(df+"FxnList", NMFitIgorList())
	CheckNMstr(df+"UserFxnList", "f:NMBekkers2,n:8;f:NMBekkers3,n:10;")
	CheckNMstr(df+"Xwave", "")
	
	return 0
	
End // CheckFit

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFunction()

	return StrVarOrDefault(FitDF()+"Function", "")

End // NMFitFunction

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitNumParams()

	return NMFitFxnListNumParams("")

End // NMFitNumParams

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitUserInput()

	return NumVarOrDefault(FitDF()+"UserInput", 0)

End // NMFitUserInput

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitTbgn()

	return NumVarOrDefault(FitDF()+"Tbgn", -inf)

End // NMFitTbgn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitTend()

	return NumVarOrDefault(FitDF()+"Tend", -inf)

End // NMFitTend

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCursors()

	return NumVarOrDefault(FitDF()+"Cursors", 0)

End // NMFitCursors

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitAuto()

	return NumVarOrDefault(FitDF()+"FitAuto", 0)

End // NMFitAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSaveWaves()

	return NumVarOrDefault(FitDF()+"SaveFitWaves", 0)

End // NMFitSaveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFullGraphWidth()

	return NumVarOrDefault(FitDF()+"FullGraphWidth", 0)

End // NMFitFullGraphWidth

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitNumPnts()

	return NumVarOrDefault(FitDF()+"FitNumPnts", Nan)

End // NMFitNumPnts

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPrint()

	return NumVarOrDefault(FitDF()+"Print", 1)

End // NMFitPrint

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWeight()

	return NumVarOrDefault(FitDF()+"WeightStdv", 0)

End // NMFitWeigh

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitMaxIterations()

	return NumVarOrDefault(FitDF()+"MaxIterations", 40)

End // NMFitMaxIterations

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitEquation()

	return StrVarOrDefault(FitDF()+"Equation", "")

End // NMFitEquation

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFxnList()

	String flist = StrVarOrDefault(FitDF()+"FxnList", NMFitIgorList())
	String user = StrVarOrDefault(FitDF()+"UserFxnList", "")

	if (ItemsInList(flist) == 0)
		flist = NMFitIgorList()
	endif

	return flist + user

End // NMFitFxnList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFxnListShort()
	
	return NMFitFxnListByKey(NMFitFxnList(), "f")

End // NMFitFxnListShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFxnListByKey(fList, key)
	String fList
	String key
	
	Variable icnt
	String istr, kList = ""
	
	for (icnt = 0; icnt < ItemsInList(fList); icnt += 1)
		istr = StringFromList(icnt, fList, ";")
		istr = StringByKey(key, istr, ":", ",")
		kList = AddListItem(istr, kList, ";", inf)
	endfor

	return kList

End // NMFitFxnListByKey

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListWhichItem(fxn)
	String fxn
	
	return WhichListItemLax(fxn, NMFitFxnListShort(), ";")
	
End // NMFitFxnListWhichItem

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListNumParams(fxn)
	String fxn
	
	if (strlen(fxn) == 0)
		fxn = NMFitFunction()
	endif
	
	Variable item = NMFitFxnListWhichItem(fxn)
	
	if (item < 0)
		return 0
	endif
	
	String f = StringFromList(item, NMFitFxnList(), ";")
	
	f = StringByKey("n", f, ":", ",")
	
	return str2num(f)

End // NMFitFxnListNumParams

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListNumParamsSet(fxn, numparams)
	String fxn
	Variable numparams
	
	Variable oldNum = NMFitFxnListNumParams(fxn)
	
	if (numparams == oldNum)
		return 0
	endif
	
	String fold = "f:" + fxn + ",n:" + num2str(oldNum)
	String fnew = "f:" + fxn + ",n:" + num2str(numparams)
	String fList = ReplaceString(fold, NMFitFxnList(), fnew)
	
	SetNMstr(FitDF()+"FxnList", fList)
	
End // NMFitFxnListNumParamsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitIgorList() // built-in Igor fitting functions
	
	return "f:Line,n:2;f:Poly,n:3;f:Gauss,n:4;f:Lor,n:4;f:Exp,n:3;f:DblExp,n:5;f:Exp_XOffset,n:3;f:DblExp_XOffset,n:5;f:Sin,n:4;f:HillEquation,n:4;f:Sigmoid,n:4;f:Power,n:3;f:LogNormal,n:4;"
	
End // NMFitIgorList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitIgorListShort()
	
	return NMFitFxnListByKey(NMFitIgorList(), "f")

End // NMFitIgorListShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitPopupList()
	
	return " ;" + NMFitFxnListShort() + "---;Other;Remove from List;"
	
End // NMFitPopupList
	
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitMake() // create controls that will begin with appropriate prefix

	Variable x0 = 40, y0 = 205, xinc, yinc = 25, fs = NMPanelFsize()
	Variable taby = NMPanelTabY()
	
	y0 = taby + 50
	
	String df = FitDF()

	ControlInfo /W=NMPanel $FitPrefix("FxnGroup") // check first in a list of controls
	
	if (V_Flag != 0)
		return 0 // tab controls exist, return here
	endif

	DoWindow /F NMPanel
	
	GroupBox $FitPrefix("FxnGroup"), title = "Function", pos={x0-20,y0-23}, size={260,100}, win=NMpanel, fsize=fs
	
	PopupMenu $FitPrefix("FxnMenu"), pos={x0+210,y0+0*yinc}, size={0,0}, bodyWidth=200, fsize=14, proc=NMFitPopup, win=NMpanel
	PopupMenu $FitPrefix("FxnMenu"), value=NMFitPopupList(), win=NMpanel, fsize=fs
	
	SetVariable $FitPrefix("FitEq"), title=" ", pos={x0,y0+1*yinc+4}, size={225,50}, frame=0, noedit=1, win=NMpanel
	SetVariable $FitPrefix("FitEq"), variable=$(df+"Equation"), win=NMpanel, fsize=fs
	
	SetVariable $FitPrefix("UserInput"), title="", pos={x0+60,y0+2*yinc}, size={90,50}, limits={0,inf,0}, frame=1, win=NMpanel
	SetVariable $FitPrefix("UserInput"), value=$(df+"UserInput"), proc=NMFitSetVariable, win=NMpanel, fsize=fs
	
	y0 += 108
	
	GroupBox $FitPrefix("RangeGroup"), title = "Range", pos={x0-20,y0-23}, size={260,75}, win=NMpanel, fsize=fs
	
	SetVariable $FitPrefix("Tbgn"), title="t_bgn:", pos={x0,y0+0*yinc}, size={90,50}, limits={-inf,inf,1}, win=NMpanel
	SetVariable $FitPrefix("Tbgn"), value=$(df+"Tbgn"), proc=NMFitSetVariable, win=NMpanel, fsize=fs
	
	SetVariable $FitPrefix("Tend"), title="t_end:", pos={x0,y0+1*yinc}, size={90,50}, limits={-inf,inf,1}, win=NMpanel
	SetVariable $FitPrefix("Tend"), value=$(df+"Tend"), proc=NMFitSetVariable, win=NMpanel, fsize=fs
	
	Button $FitPrefix("ClearRange"), pos={x0+140,y0+0*yinc}, title="Clear", size={60,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	
	Checkbox $FitPrefix("Cursors"), title="Cursors", pos={x0+140,y0+1*yinc}, size={200,50}, value=NMFitCursors(), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	
	y0 += 85
	
	GroupBox $FitPrefix("FitWaveGroup"), title = "Fit Waves", pos={x0-20,y0-23}, size={260,77}, win=NMpanel, fsize=fs
	Checkbox $FitPrefix("FullGraphWidth"), title="Full Graph Width", pos={x0,y0+0*yinc}, size={200,50}, value=NMFitSaveWaves(), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	Checkbox $FitPrefix("SaveFits"), title="Save", pos={x0,y0+1*yinc}, size={200,50}, value=NMFitSaveWaves(), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	SetVariable $FitPrefix("FitNumPnts"), title="Points:", pos={x0+130,y0+0*yinc}, size={90,50}, limits={0,inf,1}, win=NMpanel
	SetVariable $FitPrefix("FitNumPnts"), value=$(df+"FitNumPnts"), proc=NMFitSetVariable, win=NMpanel, fsize=fs
	Button $FitPrefix("Compute"), pos={x0+75,y0+1*yinc}, title="Compute", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button $FitPrefix("Plot"), pos={x0+155,y0+1*yinc}, title="Plot", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	
	y0 += 85
	
	GroupBox $FitPrefix("FitExecuteGroup"), title = "Execute", pos={x0-20,y0-23}, size={260,130}, win=NMpanel, fsize=fs
	
	Button $FitPrefix("Fit"), pos={x0-5,y0+0*yinc}, title="Fit", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button $FitPrefix("Save"), pos={x0+75,y0+0*yinc}, title="Save", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button $FitPrefix("Clear"), pos={x0+155,y0+0*yinc}, title="Clear", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button $FitPrefix("FitAll"), pos={x0-5,y0+1*yinc}, title="Fit All", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button $FitPrefix("PlotAll"), pos={x0+75,y0+1*yinc}, title="Plot All", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button $FitPrefix("ClearAll"), pos={x0+155,y0+1*yinc}, title="Clear All", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	
	y0 += 30
	
	Checkbox $FitPrefix("FitAuto"), title="Auto Fit", pos={x0+10,y0+1*yinc}, size={200,50}, value=NMFitAuto(), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	Checkbox $FitPrefix("Weight"), title="Stdv Weighting", pos={x0+120,y0+1*yinc}, size={200,50}, value=NMFitWeight(), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	Checkbox $FitPrefix("Print"), title="Print Results", pos={x0+10,y0+2*yinc}, size={200,50}, value=NMFitPrint(), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	
	SetVariable $FitPrefix("MaxIter"), title="max iter:", pos={x0+120,y0+2*yinc}, size={90,50}, limits={5,500,1}, win=NMpanel
	SetVariable $FitPrefix("MaxIter"), value=$(df+"MaxIterations"), proc=NMFitSetVariable, win=NMpanel, fsize=fs

End // NMFitMake

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitUpdate()

	String fxn = NMFitFunction()
	String flist = NMFitPopupList()
	
	Variable fmode = WhichListItemLax(fxn, flist, ";")
	Variable IgorFxn = WhichListItemLax(fxn, NMFitIgorListShort(), ";")
	
	if (fmode < 0)
		fmode = 0
	endif
	
	fmode += 1
	
	Execute /Z "PopupMenu " + FitPrefix("FxnMenu") + ", win=NMpanel, mode=" + num2str(fmode) + ", value =\"" + flist + "\""
	
	strswitch(fxn)
	
		case "Poly":
			SetVariable $FitPrefix("UserInput"), title="Terms:", frame=1, noedit=0, win=NMpanel
			break
			
		case "Exp_XOffset":
		case "DblExp_XOffset":
			SetVariable $FitPrefix("UserInput"), title="X0:", frame=1, noedit=0, win=NMpanel
			break
			
		case "Sin":
			SetVariable $FitPrefix("UserInput"), title="Pnts/Cycle:", frame=1, noedit=0, win=NMpanel
			break
	
		default:
			SetVariable $FitPrefix("UserInput"), title="Terms:", frame=0, noedit=1, win=NMpanel
	endswitch
	
	if (IgorFxn < 0)
		SetVariable $FitPrefix("UserInput"), title="Terms:", frame=1, noedit=0, win=NMpanel
	endif
	
	Checkbox $FitPrefix("Cursors"), value=NMFitCursors(), win=NMPanel
	Checkbox $FitPrefix("FullGraphWidth"), value=NMFitFullGraphWidth(), win=NMPanel
	Checkbox $FitPrefix("SaveFits"), value=NMFitSaveWaves(), win=NMPanel
	
	Checkbox $FitPrefix("FitAuto"), value=NMFitAuto(), win=NMPanel
	Checkbox $FitPrefix("Print"), value=NMFitPrint(), win=NMPanel
	Checkbox $FitPrefix("Weight"), value=NMFitWeight(), win=NMPanel
	
	NMFitCursorsSetTimes()
	
End // NMFitUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	String fxn = NMCtrlName(FitPrefix(""), ctrlName)
		
	NMFitCall(fxn, popStr)
			
End // NMFitPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitButton(ctrlName) : ButtonControl
	String ctrlName
	
	String fxn = NMCtrlName(FitPrefix(""), ctrlName)
	
	NMFitCall(fxn, "")
	
End // NMFitButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = NMCtrlName(FitPrefix(""), ctrlName)
	
	NMFitCall(fxn, varStr)
	
End // NMFitSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	String fxn = NMCtrlName(FitPrefix(""), ctrlName)
	
	NMFitCall(fxn, num2str(checked))
	
End // NMFitCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCall(fxn, select)
	String fxn // function name
	String select // parameter string variable
	
	Variable snum = str2num(select) // parameter variable number
	
	strswitch(fxn)
	
		case "FxnMenu":
		
			strswitch(select)
				case "Add to List":
				case "Other":
					NMFitUserFxnAddCall()
					break
				case "Remove from List":
					NMFitFxnListRemoveCall()
					break
				default:
					NMFitFunctionSetCall(select)
					AutoFit()
			endswitch
			
			break
			
		case "UserInput":
		
			strswitch(NMFitFunction())
				case "Poly":
					NMFitPolyNumSetCall(snum)
					AutoFit()
					break
				case "Exp_XOffset":
				case "DblExp_XOffset":
					AutoFit()
					break
				case "Sin":
					NMFitSinPntsPerCycleCall(snum)
					AutoFit()
					break
				default:
					NMFitFxnListNumParamsSet(NMFitFunction(), snum)
					NMFitWaveTable(0)
					AutoFit()
			endswitch
			
			break
			
		case "Tbgn":
			NMFitSetTbgnCall(snum)
			AutoFit()
			break
			
		case "Tend":
			NMFitSetTendCall(snum)
			AutoFit()
			break
			
		case "ClearRange":
			NMFitRangeClearCall()
			AutoFit()
			break
			
		case "Cursors":
			NMFitCursorsSetCall()
			AutoFit()
			break
			
		case "FullGraphWidth":
			NMFitFullGraphWidthSetCall()
			break
			
		case "SaveFits":
			NMFitSaveFitsSetCall()
			break
			
		case "FitNumPnts":
			NMFitWaveNumPntsCall(snum)
			break
			
		case "MaxIter":
			NMFitMaxIterationsCall(snum)
			break
			
		case "FitAuto":
			NMFitAutoSetCall()
			break
			
		case "Print":
			NMFitPrintSetCall()
			break
			
		case "Weight":
			NMFitWeightSetCall()
			AutoFit()
			break
			
		case "Compute":
			NMFitWaveComputeCall()
			break
			
		case "Fit":
			NMFitWaveCall()
			break
			
		case "FitAll":
			NMFitAllWavesCall()
			break
		
		case "Save":
			NMFitSaveCurrentCall()
			break
			
		case "Clear":
			NMFitClearCurrentCall()
			break
			
		case "ClearAll":
			NMFitClearAllCall()
			break
			
		case "Plot":
			NMFitPlotAll(0)
			break
			
		case "PlotAll":
			NMFitPlotAll(1)
			break

	endswitch
	
End // NMFitCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitUserFxnAddCall()
	String fxn = "", cmdstr = ""
	Variable numparams = 2
	
	Prompt fxn, "function name:"
	Prompt numparams, "number of fitting parameters:"
	DoPrompt "Add Function", fxn, numparams
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	cmdstr = NMCmdStr(fxn, cmdstr)
	cmdstr = NMCmdNum(numparams, cmdstr)
	
	NMCmdHistory("NMFitUserFxnAdd", NMCmdStr(fxn,""))
	
	return NMFitUserFxnAdd(fxn, numparams)

End // NMFitUserFxnAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitUserFxnAdd(fxn, numparams)
	String fxn
	Variable numparams
	
	String df = FitDF()
	String userList = StrVarOrDefault(df+"UserFxnList", "")
	
	Variable item = NMFitFxnListWhichItem(fxn)
	
	if (item >= 0)
		return -1 // name already exists
	endif
	
	String fList = AddListItem("f:" + fxn + ",n:" + num2str(numparams), userList, ";", inf)
	
	SetNMstr(df+"UserFxnList", fList)
	
	NMFitFunctionSet( fxn )
	
	NMFitUpdate()
	
End // NMFitUserFxnAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListRemoveCall()
	String fxn = ""
	
	Prompt fxn, "remove:", popup NMFitFxnListShort()
	DoPrompt "Remove Function", fxn
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	NMCmdHistory("NMFitFxnListRemove", NMCmdStr(fxn,""))
	
	return NMFitFxnListRemove(fxn)
	
End // NMFitFxnListRemoveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListRemove(fxn)
	String fxn
	
	Variable item = NMFitFxnListWhichItem(fxn)
	
	if (item < 0)
		return -1
	endif
	
	String fList = RemoveListItem(item, NMFitFxnList(), ";")
	
	SetNMstr(FitDF()+"FxnList", fList)
	
	NMFitUpdate()
	
End // NMFitFxnListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPolyNumSetCall(nparams)
	Variable nparams
	
	NMCmdHistory("NMFitPolyNumSet", NMCmdNum(nparams,""))
	
	return NMFitPolyNumSet(nparams)
	
End // NMFitPolyNumSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPolyNumSet(nparams)
	Variable nparams

	Variable icnt
	String pList = "", df = FitDF()
	
	nparams = max(nparams, 3)
	
	NMFitFxnListNumParamsSet("Poly", nparams)
	
	SetNMvar(df+"UserInput", nparams)
	SetNMstr(df+"Function", "Poly")
	SetNMstr(df+"FxnShort", "Poly")
	SetNMstr(df+"Equation", "                     K0+K1*x+K2*x^2...")
	
	NMFitWaveTable(1)
	NMFitCoefNamesSet(pList)
	NMFitUpdate()
	
	return 0

End // NMFitPolyNumSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSinPntsPerCycleCall(pnts)
	Variable pnts
	
	NMCmdHistory("NMFitSinPntsPerCycle", NMCmdNum(pnts,""))
	
	return NMFitSinPntsPerCycle(pnts)
	
End // NMFitSinPntsPerCycleCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSinPntsPerCycle(pnts)
	Variable pnts
	
	SetNMvar(FitDF()+"UserInput", pnts)
	
End // NMFitSinPntsPerCycle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFunctionSetCall(fxn)
	String fxn
	
	NMCmdHistory("NMFitFunctionSet", NMCmdStr(fxn,""))
	
	return NMFitFunctionSet(fxn)

End // NMFitFunctionSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFunctionSet(fxn)
	String fxn
	
	Variable nparams
	String sfxn = fxn, pList = "", eq = "", df = FitDF()
	
	NMFitWaveTableSave()
	
	if (WhichListItem(fxn, NMFitFxnListShort()) < 0)
		NMFitUpdate()
		return -1
	endif
	
	strswitch(fxn)
		case "Line":
			pList = "A;B;"
			eq = "                              A+Bx"
			break
		case "Poly":
			return NMFitPolyNumSet(3)
		case "Gauss":
			pList = "Y0;A;X0;W;"
			eq = "               Y0+A*exp(-((x -X0)/W)^2)"
			break
		case "Lor":
			pList = "Y0;A;X0;B;"
			eq = "                   Y0+A/((x-X0)^2+B)"
			break
		case "Exp":
			pList = "Y0;A;InvT;"
			eq = "                   Y0+A*exp(-InvT*x)"
			break
		case "DblExp":
			sfxn = "2Exp"
			pList = "Y0;A1;InvT1;A2;InvT2;"
			eq = "Y0+A1*exp(-InvT1*x)+A2*exp(-InvT2*x)"
			break
		case "Exp_XOffset":
			sfxn = "Exp"
			pList = "Y0;A;T;"
			eq = "                  Y0+A*exp(-(x-X0)/T)"
			break
		case "DblExp_XOffset":
			sfxn = "2Exp"
			pList = "Y0;A1;T1;A2;T2;"
			eq = "Y0+A1*exp(-(x-X0)/T1)+A2*exp(-(x-X0)/T2)"
			break
		case "Sin":
			pList = "Y0;A;F;P;"
			eq = "                     Y0+A*sin(F*x+P)"
			break
		case "HillEquation":
			sfxn = "Hill"
			pList = "B;M;R;XH;"
			eq = "          B+(M-B)*(x^R/(1+(x^R+XH^R)))"
			break
		case "Sigmoid":
			sfxn = "Sig"
			pList = "B;M;XH;R;"
			eq = "               B+M/(1+exp(-(x-XH)/R))"
			break
		case "Power":
			sfxn = "Pow"
			pList = "Y0;A;P;"
			eq = "                         Y0+A*x^P"
			break
		case "LogNormal":
			sfxn = "Log"
			pList = "Y0;A;X0;W;"
			eq = "             Y0+A*exp(-(ln(x/X0)/W)^2)"
			break
		case "NMBekkers2":
			sfxn = "Bek2"
			pList = "A0;TR1;N;A1;TD1;A2;TD2;X0;"
			eq = "A0*(1-exp(-(x-X0)/TR1))^N*(A1*exp(-(x-X0)/TD1)+A2*exp(-(x-X0)/TD2))"
			break
		case "NMBekkers3":
			sfxn = "Bek3"
			pList = "A0;TR1;N;A1;TD1;A2;TD2;A3;TD3;X0;"
			eq = "A0*(1-exp(-(x-X0)/TR1))^N*(A1*exp(-(x-X0)/TD1)+A2*exp(-(x-X0)/TD2))+A3*exp(-(x-X0)/TD3))"
			break
		default:
			sfxn = fxn
			eq = ""
	endswitch
	
	nparams = NMFitFxnListNumParams(fxn)
	
	SetNMvar(df+"UserInput", nparams)
	SetNMstr(df+"Function", fxn)
	SetNMstr(df+"FxnShort", sfxn)
	SetNMstr(df+"Equation", eq)
	
	Print fxn + ": " + eq
	
	NMFitWaveTable(1)
	NMFitCoefNamesSet(pList)
	NMFitGuess()
	NMFitX0Set()
	NMFitUpdate()
	
End // NMFitFunctionSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitX0Set()

	Variable x0 = 0
	Variable tbgn = NMFitTbgn()
	
	String df = FitDF()
	String gName = CurrentChanGraphName()
	String wName = ChanDisplayWave(-1)
	
	strswitch(NMFitFunction())
		case "Exp_XOffset":
		case "DblExp_XOffset":
			break
	
		default:
			return 0
	endswitch

	if ((NMFitCursors() == 1) && (strlen(NMFitCsrInfo("A", gName)) > 0))
		x0 = xcsr(A)
	elseif (numtype(tbgn) == 0)
		x0 = tbgn
	else
		if (WaveExists($wName) == 1)
			x0 = leftx($wName)
		endif
	endif
	
	SetNMvar(df+"UserInput", x0)

End // NMFitX0Set

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSetTbgnCall(tbgn)
	Variable tbgn
	
	NMCmdHistory("NMFitSetTbgn", NMCmdNum(tbgn,""))
	
	return NMFitSetTbgn(tbgn)
	
End // NMFitSetTbgnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSetTbgn(tbgn)
	Variable tbgn
	
	SetNMvar(FitDF()+"Tbgn", tbgn)
	
	NMFitX0Set()
	
End // NMFitSetTbgn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSetTendCall(tend)
	Variable tend
	
	NMCmdHistory("NMFitSetTend", NMCmdNum(tend,""))
	
	return NMFitSetTend(tend)
	
End // NMFitSetTendCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSetTend(tend)
	Variable tend
	
	SetNMvar(FitDF()+"Tend", tend)
	
	NMFitX0Set()
	
End // NMFitSetTend

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitRangeClearCall()

	NMCmdHistory("NMFitRangeClear", "")
	
	return NMFitRangeClear()

End // NMFitRangeClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitRangeClear()
	String df = FitDF()
	
	SetNMvar(df+"Tbgn", -inf)
	SetNMvar(df+"Tend", inf)
	
	NMFitX0Set()

End // NMFitRangeClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCursorsSetCall()

	Variable on = BinaryInvert(NMFitCursors())
	
	NMCmdHistory("NMFitCursorsSet", NMCmdNum(on,""))

	return NMFitCursorsSet(on)

End // NMFitCursorsSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCursorsSet(on)
	Variable on
	
	String gName = CurrentChanGraphName()
	String df = FitDF()
	
	SetNMvar(df+"Cursors", BinaryCheck(on))
	
	if (on == 1)
		ShowInfo /W=$gName
		SetNMvar(df+"TbgnOld", NumVarOrDefault(df+"Tbgn", Nan))
		SetNMvar(df+"TendOld", NumVarOrDefault(df+"Tend", Nan))
		NMFitCursorsSetTimes()
	else
		SetNMvar(df+"Tbgn", NumVarOrDefault(df+"TbgnOld", Nan))
		SetNMvar(df+"Tend", NumVarOrDefault(df+"TendOld", Nan))
	endif

End // NMFitCursorsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCursorsSetTimes()

	String gName = CurrentChanGraphName()
	String df = FitDF()

	if (NMFitCursors() == 0)
		return 0
	endif

	if (strlen(NMFitCsrInfo("A", gName)) > 0)
		SetNMvar(df+"Tbgn", xcsr(A, gName))
	endif
	
	if (strlen(NMFitCsrInfo("B", gName)) > 0)
		SetNMvar(df+"Tend", xcsr(B, gName))
	endif
	
End // NMFitCursorsSetTimes

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitCsrInfo(ab, gName)
	String ab
	String gName
	
	String tstr
	String /G FT_CsrInfo = ""
	
	strswitch(ab)
		case "A":
			Execute /Q/Z "FT_CsrInfo = CsrInfo(A, \"" + gName + "\")"
			break
		case "B":
			Execute /Q/Z "FT_CsrInfo = CsrInfo(B, \"" + gName + "\")"
			break
	endswitch
	
	if (V_flag != 0)
		FT_CsrInfo = "CsrInfo function does not exist" 
	endif
	
	tstr = FT_CsrInfo
	
	KillStrings /Z FT_CsrInfo
	
	return tstr
	
End // NMFitCsrInfo

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFullGraphWidthSetCall()

	Variable on = BinaryInvert(NMFitFullGraphWidth())
	
	NMCmdHistory("NMFitFullGraphWidthSet", NMCmdNum(on,""))

	return NMFitFullGraphWidthSet(on)

End // NMFitFullGraphWidthSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFullGraphWidthSet(on)
	Variable on
	
	SetNMvar(FitDF()+"FullGraphWidth", BinaryCheck(on))

End // NMFitFullGraphWidthSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveNumPntsCall(npnts)
	Variable npnts
	
	NMCmdHistory("NMFitWaveNumPntsSet", NMCmdNum(npnts, ""))
	
	return NMFitWaveNumPntsSet(npnts)
	
End // NMFitWaveNumPntsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveNumPntsSet(npnts)
	Variable npnts
	
	String df = FitDF()
	
	if (npnts < 1)
		npnts = Nan
	endif
	
	SetNMvar(df+"FitNumPnts", npnts)
	
	return npnts
	
End // NMFitWaveNumPntsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitMaxIterationsCall(mi)
	Variable mi
	
	NMCmdHistory("NMFitMaxIterationsSet", NMCmdNum(mi, ""))
	
	return NMFitMaxIterationsSet(mi)
	
End // NMFitMaxIterationsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitMaxIterationsSet(mi)
	Variable mi
	
	SetNMvar(FitDF()+"MaxIterations", max(mi, 5))
	
	return mi
	
End // NMFitMaxIterationsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSaveFitsSetCall()

	Variable on = BinaryInvert(NMFitSaveWaves())
	
	NMCmdHistory("NMFitSaveFitsSet", NMCmdNum(on,""))

	return NMFitSaveFitsSet(on)

End // NMFitSaveFitsSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSaveFitsSet(on)
	Variable on
	
	SetNMvar(FitDF()+"SaveFitWaves", BinaryCheck(on))

End // NMFitSaveFitsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPrintSetCall()

	Variable on = BinaryInvert(NMFitPrint())
	
	NMCmdHistory("NMFitPrintSet", NMCmdNum(on,""))

	return NMFitPrintSet(on)

End // NMFitPrintSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPrintSet(on)
	Variable on
	
	SetNMvar(FitDF()+"Print",  BinaryCheck(on))

End // NMFitPrintSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitAutoSetCall()

	Variable on = BinaryInvert(NMFitAuto())
	
	NMCmdHistory("NMFitAutoSet", NMCmdNum(on,""))

	return NMFitAutoSet(on)

End // NMFitAutoSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitAutoSet(on)
	Variable on
	
	SetNMvar(FitDF()+"FitAuto", BinaryCheck(on))

End // NMFitAutoSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWeightSetCall()

	Variable on = BinaryInvert(NMFitWeight())
	
	if (on == 1)
		DoAlert 0, "Note: to use this option, weight waves must have the same name as the data waves, but with \"Stdv_\" or \"InvStdv_\" as a prefix (i.e. Stdv_Data0)."
	endif
	
	NMCmdHistory("NMFitWeightSet", NMCmdNum(on,""))

	return NMFitWeightSet(on)

End // NMFitWeightSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWeightSet(on)
	Variable on
	
	SetNMvar(FitDF()+"WeightStdv", BinaryCheck(on))

End // NMFitWeightSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitAllWavesCall()

	Variable p, pause
	String df = FitDF()
	
	Variable pauseMode = NumVarOrDefault(df+"FitAllWavesPause", -1)
	Variable pauseValue = 0
	
	if (pauseMode > 0)
		p = 2
		pauseValue = pauseMode
	elseif (pauseMode < 0)
		p = 3
		pauseValue = 0
	else
		p = 1
		pauseValue = 0
	endif
	
	Prompt p, "pause after each fit?", popup "no;yes;yes, with OK prompt;"
	Prompt pauseValue, "pause time (sec):"
	
	DoPrompt "Fit All Waves", p, pauseValue
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	switch(p)
		case 1:
			pauseMode = 0
			break
		case 2:
			pauseMode = abs(pauseValue)
			break
		case 3:
			pauseMode = -1
			break
	endswitch
	
	SetNMvar(df+"FitAllWavesPause", pauseMode)
	
	NMCmdHistory("NMFitAllWaves", NMCmdNum(pauseMode, ""))

	NMFitAllWaves(pauseMode)

End // NMFitAllWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitAllWaves(pause)
	Variable pause // (0) no pause (> 0) pause for given sec (< 0) pause with OK prompt

	Variable ccnt, wcnt, changeChan, error
	String wName, tName = NMFitTableName()
	
	Variable nwaves = NMNumWaves()
	Variable sCurrentWave = NMCurrentWave()
	
	WaveStats /Q/Z WavSelect
	
	if (V_max != 1)
		DoAlert 0, "No Waves Selected!"
		return -1
	endif
	
	if (WinType(tName) > 0)
		DoWindow /K $tName
	endif

	DoWindow /F $ChanGraphName(ccnt)
	
	NMProgressStr("Fit Chan " + ChanNum2Char(ccnt))
	
	for (wcnt = 0; wcnt <  nwaves; wcnt += 1)
		
		if ((pause >= 0) && (CallNMProgress(wcnt, nwaves) == 1))
			break
		endif
		
		wName = NMWaveSelected(ccnt, wcnt)
		
		if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
			continue // wave not selected, or does not exist... go to next wave
		endif
		
		SetNMvar("CurrentWave", wcnt)
		SetNMvar("CurrentGrp", NMGroupGet(wcnt))
		
		ChanGraphUpdate(ccnt, 1)
		
		error = NMFitWave()
		
		DoUpdate
		
		if (pause < 0)
			
			DoAlert 2, "Save results?"
			
			if (V_flag == 1)
				NMFitSaveCurrent()
			elseif (V_flag == 3)
				break // cancel
			endif
			
			continue
			
		else
		
			NMFitSaveCurrent()
			
		endif
		
		if (pause > 0)
			NMWait(pause*1000)
		endif
			
		if (error == 0)
			NMFitSaveCurrent()
		endif
		
	endfor
	
	NMCurrentWaveSet(sCurrentWave)
	
	DoWindow /F $tName

End // NMFitAllWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveCall()

	NMCmdHistory("NMFitWave", "")

	return NMFitWave()

End // NMFitWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWave()

	Variable pbgn, pend, icnt
	String fitwave = ""

	String fit = "CurveFit ", quiet = "", polynom = "", guess = "", region = "", cmd = "", fitpnts = ""
	String fullgraph = "", hold = "", const = "", cycle = "", xw = "", weightflag = "", weightwave = "", df = FitDF()
	String wName = ChanDisplayWave(-1)
	String gName = CurrentChanGraphName()
	String sourceWave = ChanWaveName(-1, -1)
	
	Variable nparams = NMFitNumParams()
	Variable userinput = NMFitUserInput()
	Variable weight = NMFitWeight()
	Variable tbgn = NMFitTbgn()
	Variable tend = NMFitTend()
	Variable fitNumPnts = NMFitNumPnts()
	Variable fullGraphWidth = NMFitFullGraphWidth()
	Variable maxIter = NMFitMaxIterations()
	
	String fxn = NMFitFunction()
	String xwave = NMXwave()
	
	NMFitWaveTable(0)
	NMFitCursorsSetTimes()
	NMFitRemoveDisplayWaves()
	
	if ((strlen(fxn) == 0) || (nparams <= 0) || (WaveExists($wName) == 0))
		return -1
	endif
	
	if (strlen(xwave) > 0)
	
		if ((WaveExists($xwave) == 0) || (numpnts($xwave) != numpnts($wName)))
			return -1
		endif
		
		xw = "/X=" + xwave
		
	endif
	
	DoWindow /F $gName
	
	if ((numtype(tbgn) == 0) || (numtype(tend) == 0))
	
		if (strlen(xwave) == 0)
		
			region = "(" + num2str(tbgn) + "," + num2str(tend) + ") "
			
		elseif (WaveExists($xwave) == 1)
		
			Wave xtemp = $xwave
			
			pbgn = 0
			pend = numpnts(xtemp) - 1
			
			if (numtype(tbgn) == 0)
			
				for (icnt = 0; icnt < numpnts(xtemp); icnt += 1)
					if (xtemp[icnt] >= tbgn)
						pbgn = icnt
						break
					endif
				endfor
			
			endif
			
			if (numtype(tend) == 0)
			
				for (icnt = numpnts(xtemp) - 1; icnt > 0; icnt -= 1)
					if (xtemp[icnt] <= tend)
						pend = icnt
						break
					endif
				endfor
				
			endif
			
			region = "[" + num2str(pbgn) + "," + num2str(pend) + "] "
			
			xw += region
		
		endif
		
	endif
	
	if (NMFitCursors() == 1)
	
		if ((strlen(NMFitCsrInfo("A", gName)) == 0) && (strlen(NMFitCsrInfo("B", gName)) == 0))
			DoAlert 0, "Error: cannot locate Cursor information on current graph."
			return -1
		endif
		
		pbgn = pcsr(A)
		pend = pcsr(B)
		
		if (pbgn < 0)
			pbgn = 0
		endif
	
		if (pend >= numpnts($wName))
			pend = numpnts($wName) - 1
		endif
		
		region = "[" + num2str(pbgn) + "," + num2str(pend) + "] "
		
	endif
	
	if (NMFitPrint() == 0)
		quiet = "/Q "
	endif
	
	if (WaveExists(W_sigma) == 1)
		Wave W_sigma
		W_sigma = Nan
	endif
	
	if (WaveExists($df+"FT_guess") == 0)
		return -1
	endif
	
	Wave FT_guess = $df + "FT_guess"
	Wave FT_coef = $df + "FT_coef"
	Wave FT_hold = $df + "FT_hold"
	Wave FT_sigma = $df + "FT_sigma"
	
	if (WhichListItem(fxn, NMFitIgorListShort()) < 0)
	
		fit = "FuncFit "
		
		if (NumType(sum(FT_guess)) > 0)
			DoAlert 0, "Fit Error: you must provide initial guesses for user-defined equations."
			return -1
		endif
		
	endif
	
	FT_sigma = Nan
	
	for (icnt = 0; icnt < nparams; icnt += 1)
		if (numtype(FT_guess[icnt]) == 0)
			FT_coef[icnt] = FT_guess[icnt]
			guess = "/G "
		else
			FT_coef[icnt] = Nan
		endif
	endfor
	
	for (icnt = 0; icnt < nparams; icnt += 1)
		if (FT_hold[icnt] == 1)
			hold = "/H=\""
		endif
	endfor
	
	if (strlen(hold) > 0)
	
		for (icnt = 0; icnt < nparams; icnt += 1)
			if (FT_hold[icnt] == 1)
				FT_coef[icnt] = FT_guess[icnt]
				hold += "1"
			else
				hold += "0"
			endif
		endfor
		
		hold += "\" "
	
	endif
	
	strswitch(fxn)
	
		case "poly":
			fxn += " " + num2str(nparams) + ","
			break
			
		case "Exp_XOffset":
		case "DblExp_XOffset":
			const = "/K={" + num2str(userinput) + "} "
			break
			
		case "Sin":
			if (userinput > 0)
				cycle = "/B=" + num2str(userinput) + " "
			endif
			break
			
	endswitch
	
	if (weight == 1)
		if (WaveExists($("Stdv_" + sourceWave)) == 1)
			weightflag = "/I=1 "
			weightwave = "/W=Stdv_" + sourceWave + " "
		elseif (WaveExists($("Stdv" + sourceWave)) == 1)
			weightflag = "/I=1 "
			weightwave = "/W=Stdv" + sourceWave + " "
		elseif (WaveExists($("InvStdv_" + sourceWave)) == 1)
			weightflag = "/I=0 "
			weightwave = "/W=InvStdv_" + sourceWave + " "
		elseif (WaveExists($("InvStdv" + sourceWave)) == 1)
			weightflag = "/I=0 "
			weightwave = "/W=InvStdv" + sourceWave + " "
		else
			DoAlert 0, "Error: cannot locate Stdv or InvStdv wave for " + sourceWave
			return -1
		endif
	endif
	
	if (numtype(fitNumPnts) ==  0)
		fitpnts = "/L=" + num2str(fitNumPnts) + " "
	endif
	
	if (fullGraphWidth == 1)
		fullGraph = "/X=1 "
	endif
	
	if (maxIter != 40)
		Variable /G V_FitMaxIters = maxIter
	endif
	
	Variable /G V_FitError = 0
	
	FT_sigma = Nan
	
	cmd = fit + fitpnts + "/N " + cycle + guess + quiet + fullGraph + hold + const + fxn + " kwCWave=" + df + "FT_coef, "
	cmd += wName + region + " /D " + weightflag + weightwave + xw
	
	Execute cmd
	
	NMHistory(cmd)
		
	if (WaveExists(W_sigma) == 1)
		Wave W_sigma
		FT_sigma = W_sigma
	endif
	
	if ((V_FitError == 0) && (NMFitSaveWaves() == 1))
	
		fitwave = NMFitDisplayWaveName()
		
		WaveStats /Q/Z $fitwave
		
		if (numtype(V_avg) > 0)
			NMFitWaveCompute(1) // something went wrong - recompute fit wave
		endif
		
		if (WaveExists($fitwave) == 1)
			Duplicate /O $fitwave $("fit_" + sourceWave)
			NMPrefixAdd("fit_" + NMCurrentWavePrefix())
		endif
		
	endif
	
	return V_flag

End // NMFitWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitWaveName(wavNum)
	Variable wavNum // (-1) for current

	return "fit_" + ChanWaveName(-1, wavNum)
	
End // NMFitWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitDisplayWaveName()
	
	return "fit_" + ChanDisplayWaveName(0, NMCurrentChan(), 0)

End // NMFitDisplayWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveComputeCall()

	Variable guessORfit
	String df = FitDF()
	
	if (WaveExists($df+"FT_guess") == 0)
		return -1
	endif
	
	WaveStats /Q $df+"FT_guess"
	
	if (V_npnts != numpnts($df+"FT_guess"))
	
		if (WaveExists($df+"FT_coef") == 0)
			return -1
		endif
		
		guessORfit = 1
	
	endif
	
	NMCmdHistory("NMFitWaveCompute", NMCmdNum(guessORfit, ""))

	return NMFitWaveCompute(guessORfit)

End // NMFitWaveComputeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveCompute(guessORfit)
	Variable guessORfit // (0) guess (1) fit

	Variable icnt, dt, pbgn, pend
	Variable npnts = NMFitNumPnts()
	Variable tbgn = NMFitTbgn()
	Variable tend = NMFitTend()
	Variable userinput = NMFitUserInput()
	Variable fullGraphWidth = NMFitFullGraphWidth()
	
	String params, df = FitDF()
	String cmd = ""
	String fxn = NMFitFunction()
	String igorFxns = NMFitIgorListShort()
	String gName = CurrentChanGraphName()
	String displayWave = ChanDisplayWave(-1)
	String fitWave = NMFitDisplayWaveName()
	
	if (WhichListItem(fxn, igorFxns) < 0) // user defined function here
		//DoAlert 0, "Sorry, this function does not work for user-defined curve fit functions."
		//return 0
	endif
	
	NMFitRemoveDisplayWaves()
	
	switch(guessORfit)
		case 0:
			params = "FT_guess"
			break
		case 1:
			params = "FT_coef"
			break
		default:
			return -1
	endswitch

	if (WaveExists($df+params) == 0)
		return -1
	endif
	
	WaveStats /Q/Z $df+params

	if (V_numNaNs > 0)
		return -1
	endif
	
	if (numtype(npnts) > 0)
		npnts = numpnts($displayWave)
		tbgn = leftx($displayWave)
		dt = deltax($displayWave)
	else
		dt = (tend - tbgn) / (npnts - 1)
	endif
	
	Wave w = $df+params
	
	//Duplicate /O $displayWave $fitWave
	Make /O/N=(npnts) $fitWave
	Setscale /P x tbgn, dt, $fitWave
	
	Wave fit = $fitWave
	
	strswitch(fxn)
		case "Line":
			//pList = "A;B;"
			//eq = "                              A+Bx"
			fit = w[0] + w[1] * x
			break
		case "Poly":
			fit = 0
			for (icnt = 0; icnt < numpnts(w); icnt += 1)
				fit += w[icnt]*x^icnt
			endfor
			break
		case "Gauss":
			//pList = "Y0;A;X0;W;"
			//eq = "               Y0+A*exp(-((x -X0)/W)^2)"
			fit = w[0] + w[1]*exp(-((x -w[2])/w[3])^2) 
			break
		case "Lor":
			//pList = "Y0;A;X0;B;"
			//eq = "                   Y0+A/((x-X0)^2+B)"
			fit = w[0]+w[1]/((x-w[2])^2+w[3])
			break
		case "Exp":
			//pList = "Y0;A;InvT;"
			//eq = "                   Y0+A*exp(-InvT*x)"
			fit = w[0]+w[1]*exp(-w[2]*x)
			break
		case "DblExp":
			//pList = "Y0;A1;InvT1;A2;InvT2;"
			//eq = "Y0+A1*exp(-InvT1*x)+A2*exp(-InvT2*x)"
			fit = w[0]+w[1]*exp(-w[2]*x)+w[3]*exp(-w[4]*x)
			break
		case "Exp_XOffset":
			//pList = "Y0;A;T;"
			//eq = "                  Y0+A*exp(-(x-X0)/T)"
			fit = w[0]+w[1]*exp(-(x-userInput)/w[2])
			break
		case "DblExp_XOffset":
			//pList = "Y0;A1;T1;A2;T2;"
			//eq = "Y0+A1*exp(-(x-X0)/T1)+A2*exp(-(x-X0)/T2)"
			fit = w[0]+w[1]*exp(-(x-userInput)/w[2])+w[3]*exp(-(x-userInput)/w[4])
			break
		case "Sin":
			//pList = "Y0;A;F;P;"
			//eq = "                     Y0+A*sin(F*x+P)"
			fit = w[0]+w[1]*sin(w[2]*x+w[3])
			break
		case "HillEquation":
			//pList = "B;M;R;XH;"
			//eq = "          B+(M-B)*(x^R/(1+(x^R+XH^R)))"
			fit = w[0]+(w[1]-w[0])*(x^w[2]/(1+(x^w[2]+w[3]^w[2])))
			break
		case "Sigmoid":
			//pList = "B;M;XH;R;"
			//eq = "               B+M/(1+exp(-(x-XH)/R))"
			fit = w[0]+w[1]/(1+exp(-(x-w[2])/w[3]))
			break
		case "Power":
			//pList = "Y0;A;P;"
			//eq = "                         Y0+A*x^P"
			fit = w[0]+w[1]*x^w[2]
			break
		case "LogNormal":
			//pList = "Y0;A;X0;W;"
			//eq = "             Y0+A*exp(-(ln(x/X0)/W)^2)"
			fit = w[0]+w[1]*exp(-(ln(x/w[2])/w[3])^2)
			break
		case "NMBekkers2":
			fit = NMBekkers2(w,x)
			break
		case "NMBekkers3":
			fit = NMBekkers3(w,x)
			break
		default:
			DoAlert 0, "Cannot compute function for : " + fxn
			return -1
	endswitch
	
	AppendToGraph /W=$gName fit
	
	if ((fullGraphWidth == 1) && (guessORfit == 1))
		return 0
	endif
	
	pbgn = x2pnt(fit, tbgn)
	pend = x2pnt(fit, tend)
	
	if ((numtype(tbgn) == 0) && (pbgn - 1 >= 0))
		fit[0, pbgn - 1] = Nan
	endif
	
	if ((numtype(tend) == 0) && (pend + 1 <= numpnts(fit) - 1))
		fit[pend + 1, inf] = Nan
	endif

End // NMFitWaveCompute

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubDirectory()

	String fxn = NMFitFunction()
	
	if (strlen(fxn) > 0)
		return FitDF() + "FT_" + fxn + ":"
	else
		return ""
	endif 

End // NMFitSubDirectory

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveTable(new)
	Variable new // (0) no (1) yes
	
	String df = FitDF()
	String subF = NMFitSubDirectory()
	
	Variable nparams = NMFitNumParams()
	String tName = "NM_Fit_Parameters"
	
	if ((new == 1) || (WaveExists($df+"FT_cname") == 0))
		if (WaveExists($subF+"FT_cname") == 1)
			Duplicate /T/O $(subF+"FT_cname") $(df+"FT_cname")
		else
			Make /O/T/N=(nparams) $(df+"FT_cname") = ""
		endif
	endif
	
	if ((new == 1) || (WaveExists($df+"FT_coef") == 0))
		Make /D/O/N=(nparams) $(df+"FT_coef") = Nan
	endif
	
	if ((new == 1) || (WaveExists($df+"FT_sigma") == 0))
		Make /D/O/N=(nparams) $(df+"FT_sigma") = Nan
	endif
	
	if ((new == 1) || (WaveExists($df+"FT_guess") == 0))
		if (WaveExists($subF+"FT_guess") == 1)
			Duplicate /O $(subF+"FT_guess") $(df+"FT_guess")
		else
			Make /O/N=(nparams) $(df+"FT_guess") = Nan
		endif
	endif
	
	if ((new == 1) || (WaveExists($df+"FT_hold") == 0))
		if (WaveExists($subF+"FT_hold") == 1)
			Duplicate /O $(subF+"FT_hold") $(df+"FT_hold")
		else
			Make /O/N=(nparams) $(df+"FT_hold") = Nan
		endif
	endif
	
	CheckNMtwave(df+"FT_cname", nparams, "")
	CheckNMwave(df+"FT_coef", nparams, Nan)
	CheckNMwave(df+"FT_sigma", nparams, Nan)
	CheckNMwave(df+"FT_guess", nparams, Nan)
	CheckNMwave(df+"FT_hold", nparams, Nan)
	
	Wave /T FT_cname = $df+"FT_cname"
	Wave FT_coef = $df+"FT_coef"
	Wave FT_sigma = $df+"FT_sigma"
	Wave FT_guess = $df+"FT_guess"
	Wave FT_hold = $df+"FT_hold"
	
	if (WinType(tName) == 2)
		DoWindow /F $tName
		return 0
	endif
	
	Edit /K=1/N=$tName FT_cname, FT_coef, FT_sigma, FT_guess, FT_hold as "Fit Results"
	
	SetCascadeXY(tName)

End // NMFitWaveTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCoefNamesSet(paramList)
	String paramList
	
	Variable icnt, nparams = NMFitNumParams()
	String param, df = FitDF()
	
	Wave /T FT_cname = $df+"FT_cname"

	for (icnt = 0; icnt < nparams; icnt += 1)
		
		param = StringFromList(icnt, paramList)
		
		if (strlen(param) == 0)
			param = "K" + num2str(icnt)
		endif
		
		if (strlen(FT_cname[icnt]) == 0)
			FT_cname[icnt] = param
		endif
		
	endfor
	
End // NMFitCoefNamesSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitGuess()
	Variable tbgn = NMFitTbgn()
	String df = FitDF(), fxn = NMFitFunction()
	
	Wave FT_guess = $df+"FT_guess"
	
	if (numtype(FT_guess[0] * FT_guess[1]) == 0)
		return 0 // already exist
	endif
	
	if (numtype(tbgn) > 0)
		tbgn = 0
	endif
	
	strswitch(fxn)
		case "NMBekkers2":
			FT_guess[0] = 1 // A0
			FT_guess[1] = 0.1 // TR1
			FT_guess[2] = 11 // N
			FT_guess[3] = 2 // A1
			FT_guess[4] = 0.5 // TD1
			FT_guess[5] = 0.3 // A2
			FT_guess[6] = 3 // TD2
			FT_guess[7] = tbgn // X0
			break
		case "NMBekkers3":
			FT_guess[0] = 1 // A0
			FT_guess[1] = 0.1 // TR1
			FT_guess[2] = 11 // N
			FT_guess[3] = 2 // A1
			FT_guess[4] = 0.5 // TD1
			FT_guess[5] = 0.3 // A2
			FT_guess[6] = 3 // TD2
			FT_guess[7] = 0.1 // A2
			FT_guess[8] = 20 // TD2
			FT_guess[9] = tbgn // X0
			break
	endswitch

End // NMFitGuess

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveTableSave()

	String df = FitDF()
	String subF = NMFitSubDirectory()
	
	if (strlen(subF) == 0)
		return 0
	endif
	
	if (DataFolderExists(subF) == 0)
		NewDataFolder $LastPathColon(subF, 0)
	endif
	
	if (WaveExists($df+"FT_cname") == 1)
		Duplicate /O $(df+"FT_cname"), $(subF+"FT_cname")
	endif
	
	if (WaveExists($df+"FT_guess") == 1)
		Duplicate /O $(df+"FT_guess"), $(subF+"FT_guess")
	endif
	
	if (WaveExists($df+"FT_hold") == 1)
		Duplicate /O $(df+"FT_hold"), $(subF+"FT_hold")
	endif

End // NMFitWaveTableSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSaveCurrentCall()

	NMCmdHistory("NMFitSaveCurrent", "")

	return NMFitSaveCurrent()

End // NMFitSaveCurrentCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSaveCurrent()

	return NMFitSaveClear(NMCurrentWave(), 0)
	
End // NMFitSaveCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitClearCurrentCall()

	NMCmdHistory("NMFitClearCurrent", "")

	return NMFitClearCurrent()

End // NMFitClearCurrentCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitClearCurrent()

	NMFitSaveClear(NMCurrentWave(), 1)
	
End // NMFitClearCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitClearAllCall()

	NMCmdHistory("NMFitClearAll", "")

	return NMFitClearAll()

End // NMFitClearAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitClearAll()
	Variable wcnt, nwaves = NMNumWaves()

	for (wcnt = 0; wcnt < nwaves; wcnt += 1)
		NMFitSaveClear(wcnt, 1)
	endfor
	
End // NMFitClearAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSaveClear(wavNum, clear)
	Variable wavNum
	Variable clear // (0) no (1) yes

	Variable icnt
	Variable chan = NMCurrentChan()
	Variable overwrite = NMOverwrite()
	Variable nparams = NMFitNumParams()

	String wname
	String df = FitDF()
	String tName = NMFitTable()
	String fitWave = NMFitWaveName(wavNum)
	String fitDisplay = NMFitDisplayWaveName()
	
	if ((WaveExists($df+"FT_coef") == 0) || (WaveExists($df+"FT_sigma") == 0))
		return ""
	endif
	
	Wave FT_coef = $df+"FT_coef"
	Wave FT_sigma = $df+"FT_sigma"
	
	if (clear == 1)
		clear = Nan
		if (WaveExists($fitWave) == 1)
			Wave wtemp = $fitWave
			wtemp = Nan
		endif
		if (WaveExists($fitDisplay) == 1)
			Wave wtemp = $fitDisplay
			wtemp = Nan
		endif
	else
		clear = 1
	endif
	
	for (icnt = 0; icnt < nparams; icnt += 1)
	
		if ((numtype(FT_coef[icnt]) > 0) || (numtype(FT_sigma[icnt]) > 0))
			clear = Nan
		endif
		
		wname = NMFitCoefWaveName(icnt, 0, chan, overwrite)
		
		if (WaveExists($wname) == 0)
			continue
		endif
		
		Wave wtemp = $wname
		wtemp[wavNum] = FT_coef[icnt] * clear
	
		wname = NMFitCoefWaveName(icnt, 1, chan, overwrite)
		
		if (WaveExists($wname) == 0)
			continue
		endif
		
		Wave wtemp = $wname
		wtemp[wavNum] = FT_sigma[icnt] * clear
		
	endfor
	
	wname = NMFitName("ChiSqr", chan, overwrite)
	
	if (WaveExists($wname) == 1)
		Wave wtemp = $wname
		wtemp[wavNum] = NumVarOrDefault("V_chisq", Nan)  * clear
	endif
	
	wname = NMFitName("NumPnts", chan, overwrite)
	
	if (WaveExists($wname) == 1)
		Wave wtemp = $wname
		wtemp[wavNum] = NumVarOrDefault("V_npnts", Nan)  * clear
	endif
	
	wname = NMFitName("NumNANs", chan, overwrite)
	
	if (WaveExists($wname) == 1)
		Wave wtemp = $wname
		wtemp[wavNum] = NumVarOrDefault("V_numNaNs", Nan)  * clear
	endif
	
	wname = NMFitName("NumINFs", chan, overwrite)
	
	if (WaveExists($wname) == 1)
		Wave wtemp = $wname
		wtemp[wavNum] = NumVarOrDefault("V_numINFs", Nan)  * clear
	endif
	
	wname = NMFitName("StartRow", chan, overwrite)
	
	if (WaveExists($wname) == 1)
		Wave wtemp = $wname
		wtemp[wavNum] = NumVarOrDefault("V_startRow", Nan)  * clear
	endif
	
	wname = NMFitName("EndRow", chan, overwrite)
	
	if (WaveExists($wname) == 1)
		Wave wtemp = $wname
		wtemp[wavNum] = NumVarOrDefault("V_endRow", Nan)  * clear
	endif
	
	return tName
	
End // NMFitSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitTableName()
	
	String tName = FitPrefix(NMFolderPrefix("") + NMWaveSelectStr() + "_" + NMFitFunction() + "_" + NMCurrentChanStr())
	
	tname = NextGraphName(tname, -1, NMOverWrite())
	
	return tName

End // NMFitTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitName(name, chanNum, overWrite)
	String name
	Variable chanNum
	Variable overWrite
	
	String fxn = StrVarOrDefault(FitDF()+"FxnShort", NMFitFunction())
	
	if (strlen(fxn) > 5)
		fxn = ReplaceString("_", fxn, "")
		fxn = ReplaceString("-", fxn, "")
		fxn = fxn[0, 4]
	endif
	
	String wPrefix = FitPrefix(fxn + "_" + name+ "_" + NMWaveSelectStr() + "_")
	
	return NextWaveName2("", wPrefix, chanNum, overWrite)

End // NMFitName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitCoefWaveName(coefNum, sig, chanNum, overWrite)
	Variable coefNum
	Variable sig // (0) no (1) yes
	Variable chanNum
	Variable overWrite
	
	String df = FitDF()
	
	if (WaveExists($df+"FT_cname") == 0)
		return ""
	endif
	
	Wave /T FT_cname = $df+"FT_cname"
	
	String fxn = FT_cname[coefNum]
	
	if (sig == 1)
		fxn += "sig"
	endif
	
	return NMFitName(fxn, chanNum, overWrite)

End // NMFitCoefWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitTable()

	Variable icnt, nwaves = NMNumWaves()
	String wname, df = FitDF()

	ChanWaveList2Waves()
	
	Variable chan = NMCurrentChan()
	Variable overwrite = NMOverwrite()

	String fxn = StrVarOrDefault(df+"FxnShort", NMFitFunction())
	String tName = NMFitTableName()
	String wNames = CurrentChanWaveListName()
	String title = NMFolderListName("") + " : Ch " + NMCurrentChanStr() + " : Fit " + fxn + " : " + NMWaveSelectGet()
	
	if ((WaveExists($df+"FT_cname") == 0) || (WaveExists($wNames) == 0))
		return ""
	endif
	
	if (WinType(tName) == 2)
		//DoWindow /F $tName
		return tName
	endif
	
	Wave /T FT_cname = $df+"FT_cname"
	
	wname = NMFitName("wName", chan, overwrite)
	
	Duplicate /O $wNames $wname
	
	Edit /K=1/N=$tName $wname as title
	
	SetCascadeXY(tName)
	
	for (icnt = 0; icnt < numpnts(FT_cname); icnt += 1)
	
		wname = NMFitCoefWaveName(icnt, 0, chan, overwrite)
		Make /O/N=(nwaves) $wname = Nan
		AppendToTable /W=$tName $wname
		
		wname = NMFitCoefWaveName(icnt, 1, chan, overwrite)
		Make /O/N=(nwaves) $wname = Nan
		AppendToTable /W=$tName $wname
		
	endfor
	
	wname = NMFitName("ChiSqr", chan, overwrite)
	Make /O/N=(nwaves) $wname = Nan
	AppendToTable /W=$tName $wname
	
	wname = NMFitName("NumPnts", chan, overwrite)
	Make /O/N=(nwaves) $wname = Nan
	AppendToTable /W=$tName $wname
	
	wname = NMFitName("NumNANs", chan, overwrite)
	Make /O/N=(nwaves) $wname = Nan
	AppendToTable /W=$tName $wname
	
	wname = NMFitName("NumINFs", chan, overwrite)
	Make /O/N=(nwaves) $wname = Nan
	AppendToTable /W=$tName $wname
	
	wname = NMFitName("StartRow", chan, overwrite)
	Make /O/N=(nwaves) $wname = Nan
	AppendToTable /W=$tName $wname
	
	wname = NMFitName("EndRow", chan, overwrite)
	Make /O/N=(nwaves) $wname = Nan
	AppendToTable /W=$tName $wname
	
	return tName

End // NMFitTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPlotAll(plotData)
	Variable plotData // (0) no (1)
	
	Variable wcnt, error, chan = NMCurrentChan(), nwaves = NMNumWaves()
	String cList = "", fList = "", fitWave, xl, yl, df = FitDF()
	
	String fxn = StrVarOrDefault(df+"FxnShort", NMFitFunction())
	String prefix = NMCurrentWavePrefix()
	String gPrefix = FitPrefix("") + NMFolderPrefix("") + NMWaveSelectStr() + fxn + num2str(plotData)
	String gName = NextGraphName(gPrefix, chan, NMOverWrite())
	String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(chan) + " : " + prefix + " : " + NMWaveSelectGet() + " : " + fxn + " Fits"
	String xwave = NMXwave()
	
	for (wcnt = 0; wcnt < nwaves; wcnt += 1)
	
		fitWave = NMFitWaveName(wcnt)
		
		if (WaveExists($fitWave) == 1)
			cList = AddListItem(ChanWaveName(-1, wcnt), cList, ";", inf)
			fList = AddListItem(fitWave, fList, ";", inf)
		endif
		
	endfor
	
	If (ItemsInList(fList) <= 0)
		DoAlert 0, "There are no saved fits to plot."
		return 0
	endif
	
	xl = ChanLabel(chan, "x", cList)
	yl = ChanLabel(chan, "y", cList)

	if (plotData == 1)
	
		NMPlotWaves(gName, gTitle, xl, yl, xwave, cList) // NM_Utility.ipf
		
		if (WinType(gName) != 1)
			return -1
		endif
		
		ModifyGraph /W=$gName rgb=(0,0,0)
		
		for (wcnt = 0; wcnt < ItemsInlist(fList); wcnt += 1)
			AppendToGraph /Q/W=$gName $StringFromList(wcnt, fList)
		endfor
		
	else
	
		NMPlotWaves(gName, gTitle, xl, yl, xwave, fList) // NM_Utility.ipf
		ModifyGraph /W=$gName rgb=(65280,0,0)
	
	endif

End // NMFitPlotAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitRemoveDisplayWaves()
	Variable ccnt, wcnt
	String gName, wName, wList

	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1)
	
		gName = ChanGraphName(ccnt)
	
		if (Wintype(gName) == 0)
			continue
		endif
		
		wList = WaveList("fit_*", ";", "WIN:"+gName)
		
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
			wName = StringFromList(wcnt, wList)
			if (WaveExists($wName) == 1)
				RemoveFromGraph /W=$gName /Z $wName
			endif
		endfor
		
	endfor

End // NMFitRemoveDisplayWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSingleExp(w,x) : FitFunc // example of a user-defined fit function
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = Yo + A1*exp(-(x-Xo)/tau1) 
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = Yo
	//CurveFitDialog/ w[1] = A1
	//CurveFitDialog/ w[2] = tau1
	//CurveFitDialog/ w[3] = Xo

	return w[0] + w[1]*exp(-(x-w[3])/w[2])
	
End // NMSingleExp

//****************************************************************
//****************************************************************
//****************************************************************

Function NMBekkers2(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) =A0*(1-exp(-(x-X0)/TR1))^N*(A1*exp(-(x-X0)/TD1)+A2*exp(-(x-X0)/TD2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 8
	//CurveFitDialog/ w[0] = A0
	//CurveFitDialog/ w[1] = TR1
	//CurveFitDialog/ w[2] = N
	//CurveFitDialog/ w[3] = A1
	//CurveFitDialog/ w[4] = TD1
	//CurveFitDialog/ w[5] = A2
	//CurveFitDialog/ w[6] = TD2
	//CurveFitDialog/ w[7] = X0
	
	//Variable signA0 = w[0] / abs(w[0])
	
	//w[3] = signA0 * abs(w[3])
	//w[5] = signA0 * abs(w[5])
	
	if (x < w[7])
		return 0
	else
		return w[0]*(1-exp(-(x-w[7])/w[1]))^w[2]*(w[3]*exp(-(x-w[7])/w[4])+w[5]*exp(-(x-w[7])/w[6]))
	endif
	
End // NMBekkers2

//****************************************************************
//****************************************************************
//****************************************************************

Function NMBekkers3(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) =A0*(1-exp(-(x-X0)/TR1))^N*(A1*exp(-(x-X0)/TD1)+A2*exp(-(x-X0)/TD2)+A3*exp(-(x-X0)/TD3))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 10
	//CurveFitDialog/ w[0] = A0
	//CurveFitDialog/ w[1] = TR1
	//CurveFitDialog/ w[2] = N
	//CurveFitDialog/ w[3] = A1
	//CurveFitDialog/ w[4] = TD1
	//CurveFitDialog/ w[5] = A2
	//CurveFitDialog/ w[6] = TD2
	//CurveFitDialog/ w[7] = A3
	//CurveFitDialog/ w[8] = TD3
	//CurveFitDialog/ w[9] = x0
	
	if(x<w[9])
		return 0
	else
		return w[0]*(1-exp(-(x-w[9])/w[1]))^w[2]*(w[3]*exp(-(x-w[9])/w[4])+w[5]*exp(-(x-w[9])/w[6])+w[7]*exp(-(x-w[9])/w[8]))
	endif
	
End // NMBekkers3

//****************************************************************
//****************************************************************
//****************************************************************
