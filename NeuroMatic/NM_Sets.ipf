#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Sets Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last Modified 21 Feb 2005
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsCall(fxn, select)
	String fxn, select
	
	Variable snum = str2num(select)
	String setList = NMSetsPanelList()
	
	strswitch(fxn)
	
		case "Define":
			return NMSetsDefineCall("")
		
		case "Equation":
		case "Function":
			return NMSetsFxnCall("")
			
		case "Clear":
			return NMSetsClearCall("")
			
		case "Kill":
			return NMSetsKillCall("")
			
		case "Copy":
			return NMReturnStr2Num(NMSetsCopyCall(""))
			
		case "New":
			return NMReturnStr2Num(NMSetsNewCall(""))
			
		case "Rename":
			return NMReturnStr2Num(NMSetsRenameCall(""))
			
		case "Invert":
			return NMSetsInvertCall("")
			
		case "0 > Nan":
			return NMSetsZero2NanCall("")
			
		case "Nan > 0":
			return NMSetsNan2ZeroCall("")
			
		case "Table":
		case "Edit":
			return NMSetsEdit()
		
		case "Set1":
		case "Set1Check":
			return NMSetsAssignCall(NMSetsDisplayName(0), snum)

		case "Set2":
		case "Set2Check":
			return NMSetsAssignCall(NMSetsDisplayName(1), snum)

		case "SetX":
		case "SetXCheck":
			return NMSetsAssignCall(NMSetsDisplayName(2), snum)
			
		case "Exclude SetX?":
			return NMSetXCall(Nan)
			
		case "Auto Advance":
			return NMSetsAutoAdvanceCall(Nan)
			
		// Sets Panel Functions
		
		case "SetsFrom":
		case "SetsTo":
		case "SetsSkip":
			return NMSetsPanelDefineAuto()
			
		case "SetsAutoClear":
			NMSetsPanelAutoClear(snum)
			break
		
		case "Panel":
			return NMSetsPanelCall()
	
		case "SetsMenu":
			return NMSetsPanelSelect(select)
			
		case "SetsValue":
			return NMSetsPanelValue(snum)
			
		case "SetsOp":
			return NMSetsPanelOp(select)
			
		case "SetsArg":
			return NMSetsPanelArg(select)
			
		case "SetsDefine":
			return NMSetsPanelDefine()
			
		case "SetsFxn":
			return SetsPanelFxn()
			
		case "SetsInvert":
			return NMSetsInvertCall(setList)
			
		case "SetsZ2N":
			return NMSetsZero2NanCall(setList)
			
		case "SetsN2Z":
			return NMSetsNan2ZeroCall(setList)
	
		case "SetsClear":
			return NMSetsClearCall(setList)
			
		case "SetsCopy":
			return NMReturnStr2Num(NMSetsPanelCopy())
			
		case "SetsNew":
			return NMReturnStr2Num(NMSetsPanelNew())
			
		case "SetsRename":
			return NMReturnStr2Num(NMSetsPanelRename())
			
		case "SetsKill":
			return NMSetsPanelKill()
			
		case "SetsExclude":
			return NMSetsPanelExclude(snum)
			
		case "SetsAdvance":
			return NMSetsPanelAdvance(snum)
		
		case "Display":
		case "SetsDisplay":
			return NMSetsPanelDisplay(snum)
			
		case "SetsClose":
			return NMSetsPanelClose()
			
	endswitch
	
	return -1

End // NMSetsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsMenu()

	return "Sets ;---;Define;Equation;Invert;Clear;0 > Nan;Nan > 0;---;New;Copy;Rename;Kill;---;Table;Panel;---;Exclude SetX?;Auto Advance;Display;"

End // NMSetsMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsDisplayList()

	return StrVarOrDefault("SetsDisplayList", "Set1;Set2;SetX;")

End // NMSetsDisplayList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsDisplayName(select)
	Variable select

	String setList = StrVarOrDefault("SetsDisplayList", "Set1;Set2;SetX;")
	
	String setName = StringFromList(select, setList)
	
	if (isNMSet(setName, 1) == 1)
		return setName
	else
		return StringFromList(select, "Set1;Set2;SetX;")
	endif

End // NMSetsDisplayName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsToggleCall(setName)
	String setName
	
	NMCmdHistory("NMSetsToggle", NMCmdStr(setName,""))
	
	return NMSetsToggle(setName)

End // NMSetsToggleCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsToggle(setName)
	String setName
	String df = NMDF()
	
	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)

	if ((WaveExists($setName) == 1) && (CurrentWave < numpnts($setName)))
		Wave Set = $setName
		Set[CurrentWave] = BinaryInvert(Set[CurrentWave])
	else
		return -1
	endif
	
	if (NumVarOrDefault(df+"SetsAutoAdvance", 0) == 1) 
		NMNextWave(1)
	endif
	
	UpdateNMSets(1)
	
	return 0

End // NMSetsToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsClearCall(setList)
	String setList // set name list
	
	if (strlen(setList) == 0)

		Prompt setList, " ", popup NMSetsList(0)
		DoPrompt "Clear Set", setList
		
		if (V_flag == 1)
			return -1 // cancel
		endif
		
	endif
	
	NMCmdHistory("NMSetsClear", NMCmdList(setList,""))
	
	return NMSetsClear(setList)

End // NMSetsClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsClear(setList)
	String setList // set name list
	
	Variable icnt
	String setName
	
	for (icnt = 0; icnt < ItemsInList(setList); icnt += 1)
	
		setName = StringFromList(icnt, setList)
		
		if (WaveExists($setName) == 0)
			continue
		endif
		
		WaveStats /Q $setName
		
		if (V_numNaNs > 0)
			SetNMwave(setName, -1, Nan)
		else
			SetNMwave(setName, -1, 0)
		endif
		
		Note /K $setName
		NMSetsTag(setName)
	
	endfor
	
	UpdateNMSets(1)
	
	return 0

End // NMSetsClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsInvertCall(setList)
	String setList // set name list
	
	if (strlen(setList) == 0)

		Prompt setList, " ", popup NMSetsList(0)
		DoPrompt "Invert Set", setList
		
		if (V_flag == 1)
			return -1 // cancel
		endif
		
	endif
	
	NMCmdHistory("NMSetsInvert", NMCmdList(setList,""))
	
	return NMSetsInvert(setList)

End // NMSetsInvertCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsInvert(setList)
	String setList // set name list
	
	Variable icnt
	String setName
	
	for (icnt = 0; icnt < ItemsInList(setList); icnt += 1)
	
		setName = StringFromList(icnt, setList)
		
		if (WaveExists($setName) == 0)
			continue
		endif
	
		Wave Set = $setName
		
		Set = BinaryInvert(Set)
		
		NMSetsTag(setName)
		
		Note $setName, "Func:NMSetsInvert"
	
	endfor
	
	UpdateNMSets(1)
	
	return 0

End // NMSetsInvert

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsZero2NanCall(setList)
	String setList
	
	if (strlen(setList) == 0)

		Prompt setList, "choose Set:", popup NMSetsList(0)
		DoPrompt "Convert Zeros 2 NANs", setList
		
		if (V_flag == 1)
			return -1 // cancel
		endif
	
	endif
	
	NMCmdHistory("NMSetsZero2Nan", NMCmdList(setList,""))
	
	return NMSetsZero2Nan(setList)
	
End // NMSetsZero2NanCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsZero2Nan(setList)
	String setList
	
	Variable icnt
	String setName
	
	for (icnt = 0; icnt < ItemsInList(setList); icnt += 1)
	
		setName = StringFromList(icnt, setList)
		
		if (WaveExists($setName) == 0)
			continue
		endif
		
		Wave Set = $setName
		
		Set = Zero2Nan(set)
		
		NMSetsTag(setName)
		
		Note $setName, "Func:NMSetsZero2Nan"
		
	endfor
	
	return 0

End // NMSetsZero2Nan

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsNan2ZeroCall(setList)
	String setList

	if (strlen(setList) == 0)
	
		Prompt setList, "choose Set:", popup NMSetsList(0)
		DoPrompt "Convert NANs 2 Zeros", setList
		
		if (V_flag == 1)
			return -1 // cancel
		endif
		
	endif
	
	NMCmdHistory("NMSetsNan2Zero", NMCmdList(setList,""))
	
	return NMSetsNan2Zero(setList)

End // NMSetsNan2ZeroCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsNan2Zero(setList)
	String setList
	
	Variable icnt
	String setName
	
	for (icnt = 0; icnt < ItemsInList(setList); icnt += 1)
	
		setName = StringFromList(icnt, setList)
		
		if (WaveExists($setName) == 0)
			continue
		endif
		
		Wave Set = $setName
		
		Set = BinaryCheck(Set)
		
		NMSetsTag(setName)
		
		Note $setName, "Func:NMSetsNan2Zero"
		
	endfor
	
	return 0

End // NMSetsNan2Zero

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsKillCall(setList)
	String setList

	String wlist 
	
	if (strlen(setList) == 0)
	
		wlist = NMSetsList(0)
	
		wlist = RemoveFromList("Set1", wlist)
		wlist = RemoveFromList("Set2", wlist)
		wlist = RemoveFromList("SetX", wlist)
		wlist = " ;" + wlist
		
		if (ItemsInlist(wlist) == 0)
			return -1
		endif
	
		Prompt setList, "select wave to kill:", popup wlist
		DoPrompt "Kill Set Wave", setList
		
		if (V_flag == 1)
			return -1 // cancel
		endif
		
	endif
	
	NMCmdHistory("NMSetsKill", NMCmdList(setList, ""))
	
	return NMSetsKill(setList)

End // NMSetsKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsKill(setList)
	String setList
	
	Variable icnt
	String setName
	
	for (icnt = 0; icnt < ItemsInlist(setList); icnt += 1)
	
		setName = StringFromList(icnt, setList)
	
		strswitch(setName)
			case "Set1":
			case "Set2":
			case "SetX":
				continue
		endswitch
		
		if (WaveExists($setName) == 0)
			continue
		endif
		
		KillWaves /Z $setName
	
	endfor
	
	UpdateNMWaveSelect()

End // NMSetsKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsCopyCall(setName)
	String setName
	
	Variable icnt
	String vlist = "", newName = NMSetsNameNext()
	
	Prompt setName, "select wave to copy:", popup NMSetsList(0)
	Prompt newName, "enter new set name:"
	
	if (strlen(setName) > 0)
		DoPrompt "Copy Set Wave", newName
	else
		DoPrompt "Copy Set Wave", setName, newName
	endif
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	vlist = NMCmdStr(setName, vlist)
	vlist = NMCmdStr(newName, vlist)
	NMCmdHistory("NMSetsCopy", vlist)
	
	return NMSetsCopy(setName, newName)

End // NMSetsCopyCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsCopy(setName, newName)
	String setName
	String newName
	
	if (WaveExists($setName) == 0)
		return ""
	endif
	
	if (StringMatch(setName, newName) == 1)
		return ""
	endif
	
	if (WaveExists($newName) == 1)
	
		DoAlert 1, "Alert: wave \"" + newName + "\" already exists. Do you want to overwrite it?"
		
		if (V_Flag != 1)
			return "" // cancel
		endif
		
	endif
	
	Duplicate /O $setName, $newName
	
	NMSetsTag(newName)
	UpdateNMWaveSelect()
	
	return newName

End // NMSetsCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsRenameCall(setName)
	String setName
	
	Variable icnt
	String vlist = "", newName = NMSetsNameNext(), wlist = NMSetsList(0)
	
	wlist = RemoveListFromList("Set1;Set2;SetX;", wlist, ";")
	
	if (ItemsInList(wlist) == 0)
		DoAlert 0, "No Sets to rename."
		return ""
	endif
	
	Prompt setName, "select wave to rename:", popup wlist
	Prompt newName, "enter new set name:"
	
	if (strlen(setName) > 0)
		DoPrompt "Rename Set Wave", newName
	else
		DoPrompt "Rename Set Wave", setName, newName
	endif
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	vlist = NMCmdStr(setName, vlist)
	vlist = NMCmdStr(newName, vlist)
	NMCmdHistory("NMSetsRename", vlist)
	
	return NMSetsRename(setName, newName)

End // NMSetsRenameCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsRename(setName, newName)
	String setName
	String newName
	
	if (WaveExists($setName) == 0)
		return ""
	endif
	
	if (StringMatch(setName, newName) == 1)
		return ""
	endif
	
	if (WaveExists($newName) == 1)
	
		DoAlert 1, "Alert: wave \"" + newName + "\" already exists. Do you want to overwrite it?"
		
		if (V_Flag != 1)
			return "" // cancel
		endif
		
		KillWaves /Z $newName
		
	endif
	
	Rename $setName, $newName
	
	UpdateNMWaveSelect()
	
	return newName

End // NMSetsRename

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNewCall(setName)
	String setName
	
	if (strlen(setName) == 0)
	
		setName = NMSetsNameNext()
		
		Prompt setName, "enter new set name:"
		DoPrompt "New Set", setName
	
		if (V_flag == 1)
			return "" // cancel
		endif
		
	endif
	
	NMCmdHistory("NMSetsNew", NMCmdStr(setName, ""))
	
	return NMSetsNew(setName)

End // NMSetsNewCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNew(setList)
	String setList
	
	Variable icnt
	String setName
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	
	for (icnt = 0; icnt < ItemsInList(setList); icnt += 1)
		
		setName = StringFromList(icnt, setList)
	
		if (WaveExists($setName) == 1)
			DoAlert 0, "Error: wave \"" + setName + "\" already exists."
			continue
		endif
	
		CheckNMwave(setName, nwaves, 0)
		NMSetsTag(setName)
		
	endfor
	
	UpdateNMWaveSelect()
	
	return setName
	
End // NMSetsNew

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDefineCall(setList)
	String setList
	
	Variable wlimit, first, last, skip
	String vlist = "", valueStr, df = NMDF()
	
	wlimit = numpnts(Set1) - 1
	last = wlimit
	
	Variable zero = 1 + NumVarOrDefault(df+"SetsZero", 0)
	Variable value = NumVarOrDefault(df+"SetsValue", 1)
	
	valueStr = num2str(value)
	
	Prompt setList, " ", popup NMSetsList(0)
	Prompt first, "define FROM wave:"
	Prompt last, "define TO wave:"
	Prompt skip, "SKIP every other:"
	Prompt valueStr, "Define as:", popup "0;1;NAN;"
	Prompt zero, "clear Set first?", popup "no;yes"
	
	if (strlen(setList) > 0)
		DoPrompt "Define Set", first, last, skip, valueStr, zero
	else
		DoPrompt "Define Set", setList, skip, first, valueStr, last, zero
	endif
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	wlimit = numpnts($setList) - 1
	
	zero -= 1
	value = str2num(valueStr)
	
	SetNMvar(df+"SetsZero", zero)
	SetNMvar(df+"SetsValue", value)
	
	if ((first < 0) || (first > wlimit) || (last < 0) || (last > wlimit) || (first > last))
		DoAlert 0, "NMSetsDefineCall Abort: wave number out of bounds."
		return -1
	endif
	
	vlist = NMCmdList(setList, vlist)
	vlist = NMCmdNum(value, vlist)
	vlist = NMCmdNum(first, vlist)
	vlist = NMCmdNum(last, vlist)
	vlist = NMCmdNum(skip, vlist)
	vlist = NMCmdNum(zero, vlist)
	NMCmdHistory("NMSetsDefine", vlist)
	
	return NMSetsDefine(setList, value, first, last, skip, zero)

End // NMSetsDefineCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDefine(setList, value, first, last, skip, zero)
	String setList
	Variable value // 0, 1 or Nan
	Variable first // from wave num
	Variable last // to wave num
	Variable skip // skip wave increment (0) for none
	Variable zero // zero wave first (0) no (1) yes
	
	Variable wcnt
	String setName
	
	if (numtype(skip*zero) > 0)
		return -1
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(setList); wcnt += 1)
	
		setName = StringFromList(wcnt, setList)
	
		if (WaveExists($setName) == 0)
			CheckNMwave(setName, NumVarOrDefault("NumWaves", 0), 0)  // create Set
		endif
	
		Wave Set = $setName
		
		if (zero == 1)
			Set = 0
		endif
		
		Set[first,last;abs(skip)+1] = value
		
		NMSetsTag(setName)
		
		if (NMNoteExists(setName, "Sets From") == 1)
			NMNoteVarReplace(setName, "Sets From", first)
			NMNoteVarReplace(setName, "Sets To", last)
			NMNoteVarReplace(setName, "Sets Skip", skip)
			NMNoteVarReplace(setName, "Sets Value", value)
		else
			Note $setName, "Func:NMSetsDefine"
			Note $setName, "Sets From:" + num2str(first) + ";Sets To:" + num2str(last) + ";Sets Skip:" + num2str(skip) + ";Sets Value:" + num2str(value) + ";"
		endif
		
	endfor
	
	UpdateNMSets(1)
	
	return 0

End // NMSetsDefine

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAssignCall(setName, value)
	String setName
	Variable value
	
	String vlist = ""
	Variable wavenum = NumVarOrDefault("CurrentWave", Nan)
	
	vlist = NMCmdStr(setName, vlist)
	vlist = NMCmdNum(wavenum, vlist)
	vlist = NMCmdNum(value, vlist)
	NMCmdHistory("NMSetsAssign", vlist)
	
	return NMSetsAssign(setName, wavenum, value)

End // NMSetsAssignCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsSet(setName, waveNum, value) // old name
	String setName
	Variable waveNum // wave number (-1) for current
	Variable value // (0 or Nan) false (1) true
	
	NMSetsAssign(setName, waveNum, value)
	
End // NMSetsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAssign(setName, waveNum, value)
	String setName
	Variable waveNum // wave number (-1) for current
	Variable value // (0 or Nan) false (1) true
	
	String df = NMDF()
	
	if (waveNum == -1)
		waveNum = NumVarOrDefault("CurrentWave", -1)
	endif
	
	if ((waveNum < 0) || (waveNum >= NumVarOrDefault("NumWaves", 0)))
		return -1
	endif

	SetNMwave(setName, waveNum, BinaryCheck(value))
	
	UpdateNMSets(1)
	
	if ((value == 1) && (NumVarOrDefault(df+"SetsAutoAdvance", 0) == 1)) 
		NMNextWave(1)
	endif
	
	return value
	
End // NMSetsAssign

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsFxnCall(setList)
	String setList
	
	String vlist = "", df = NMDF()
	Variable setPrompt
	
	if (strlen(setList) == 0)
		setList = StrVarOrDefault(df+"SetsFxnName", "Set1")
		setPrompt = 1
	endif
	
	String arg = StrVarOrDefault(df+"SetsFxnArg", "Set1")
	String op = StrVarOrDefault(df+"SetsFxnOp", "EQUALS")
	
	String wlist = NMSetsList(0)
	
	if (NumVarOrDefault(df+"GroupsOn", 0) == 1)
		Prompt arg, "select Set or Group:", popup wlist+NMGroupList(1)
	else
		Prompt arg, "select Set:", popup wlist
	endif

	Prompt setList, "select operand:", popup wlist
	Prompt op, "select logical operator:", popup "EQUALS;AND;OR;"
	
	if (setPrompt == 0)
		DoPrompt "Execute Sets Function", op, arg
	else
		DoPrompt "Execute Sets Function", setList, op, arg
	endif
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMstr(df+"SetsFxnName", setList)
	SetNMstr(df+"SetsFxnArg", arg)
	SetNMstr(df+"SetsFxnOp", op)
	
	vlist = NMCmdList(setList, vlist)
	vlist = NMCmdStr(arg, vlist)
	vlist = NMCmdStr(op, vlist)
	NMCmdHistory("NMSetsFxn", vlist)
	
	return NMSetsFxn(setList, arg, op)

End // NMSetsFxnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsFxn(setList, arg, op)
	String setList
	String arg // argument (e.g. "Set1" or "Group2")
	String op // operator ("AND", "OR", "EQUALS")
	
	Variable wcnt, grp = -1
	String setName
	
	if (StringMatch(arg[0,4], "Group") == 1)
		grp = str2num(arg[5,inf])
		arg = "Group"
	endif
	
	if (WaveExists($arg) == 0)
		return -1
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(setList); wcnt += 1)
	
		setName = StringFromList(wcnt, setList)
	
		if (StringMatch(setName, arg) == 1)
			continue
		endif
		
		if (numpnts($setName) != numpnts($arg))
			DoAlert 0, "NMSetsFxn Error: waves of unequal dimension : " + setName + ", " + arg
			continue
		endif
		
		Wave Set = $setName
		Wave Set2 = $arg
		
		Set = NMSetsFxnFilter(Set, Set2, grp, op)
		
		Note /K $setName
		 
		NMSetsTag(setName)
		
		Note $setName, "Func:NMSetsFxn"
		Note $setName, "Sets Operator:" + op + ";Sets Argument:" + arg + ";"
		
	 endfor
	
	UpdateNMSets(1)
	
	return 0

End // NMSetsFxn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsFxnFilter(n1, n2, grp, op)
	Variable n1, n2, grp
	String op
	
	strswitch(op)
	
		case "AND":
		case "&":
		case "&&":
			if (grp == -1)
				return n1 && n2
			else
				return n1 && NMGroupFilter(n2, grp)
			endif
			break
			
		case "OR":
		case "|":
		case "||":
			if (grp == -1)
				return n1 || n2
			else
				return n1 || (NMGroupFilter(n2, grp))
			endif
			break
			
		case "EQUALS":
		case "=":
			if (grp == -1)
				return n2
			else
				return NMGroupFilter(n2, grp)
			endif
			break
			
		default:
			return 0
	
	endswitch
	
End // NMSetsFxnFilter

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAutoAdvanceCall(on) // auto advance wave increment
	Variable on
	
	if ((on != 0) && (on != 1))
	
		on = 1 + NumVarOrDefault(NMDF()+"SetsAutoAdvance", 0)
	
		Prompt on, "auto-advance wave number after each checkbox selection?", popup "no;yes;"
		DoPrompt "Sets Auto Advance Mode", on
		
		if (V_flag == 1)
			return -1 // cancel
		endif
		
		on -= 1
		
	endif
	
	on = BinaryCheck(on)
	
	NMCmdHistory("NMSetsAutoAdvance", NMCmdNum(on,""))
	
	return NMSetsAutoAdvance(on)
	
End // NMSetsAutoAdvanceCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAutoAdvance(on) // auto advance wave increment
	Variable on // (0) no (1) yes
	
	SetNMvar(NMDF()+"SetsAutoAdvance", BinaryCheck(on))
	
	return on
	
End // NMSetsAutoAdvance

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDisplayCall() // auto advance wave increment
	Variable on
	
	String df = NMDF()
	String setList = NMSetsDisplayList()
	
	String s1 = StringFromList(0, setList)
	String s2 = StringFromList(1, setList)
	String s3 = StringFromList(2, setList)
	
	Prompt s1, "first checkbox:", popup NMSetsList(1)
	Prompt s2, "second checkbox:", popup NMSetsList(1)
	Prompt s3, "third checkbox:", popup NMSetsList(1)
	DoPrompt "Main Panel Sets Display", s1, s2, s3
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	setList = AddListItem(s1, "", ";", inf)
	setList = AddListItem(s2, setList, ";", inf)
	setList = AddListItem(s3, setList, ";", inf)
	
	NMCmdHistory("NMSetsDisplay", NMCmdList(setList, ""))
	
	return NMSetsDisplay(setList)
	
End // NMSetsDisplayCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDisplay(setList)
	String setList
	
	if ((ItemsInList(setList) != 3) || (AreNMSets(setList) == 0))
		return -1
	endif
	
	SetNMstr("SetsDisplayList", setList)
	
	UpdateNMSets(1)
	
	return 0
	
End // NMSetsDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetXCall(exclude)
	Variable exclude
	
	if ((exclude != 0) && (exclude != 1))
	
		exclude = 1 + NMSetXType()
	
		Prompt exclude, "waves checked as SetX are to be excluded? (otherwise SetX acts as Set1 and 2)", popup "no;yes"
		DoPrompt "Define SetX", exclude
		
		if (V_flag == 1)
			return -1 // cancel
		endif
		
		exclude -= 1
		
	endif
	
	NMCmdHistory("NMSetXclude", NMCmdNum(exclude,""))
	
	return NMSetXclude(exclude)
	
End // NMSetXCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetXclude(excluding)
	Variable excluding // (0) normal Set (1) excluding Set
	
	if (excluding != 0)
		excluding = 1
	endif
	
	NMSetsTag("SetX")
	NMNoteVarReplace("SetX", "Excluding", excluding)
	UpdateNMSets(1)
	
	return excluding
	
End // NMSetXclude

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetXType() // determine if SetX is excluding 

	if (NMNoteVarByKey("SetX", "Excluding") != 0)
		return 1
	else
		return 0
	endif

End // NMSetXType

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNameNext()
	String setName
	Variable icnt
	
	for (icnt = 3; icnt < 99; icnt += 1)
		setName = "Set" + num2str(icnt)
		if (WaveExists($setName) == 0)
			return setName
		endif
	endfor

	return ""
	
End // NMSetsNameNext

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsTagDefaults()

	NMSetsTag("Set1;Set2;SetX;")

End // NMSetsTagDefaults

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsTag(setList)
	String setList
	
	Variable icnt
	String setName, wnote
	
	for (icnt = 0; icnt < ItemsInList(setList); icnt += 1)
	
		setName = StringFromList(icnt, setList)
		
		if (WaveExists($setName) == 0)
			continue
		endif
		
		if (StringMatch(NMNoteStrByKey(setName, "Type"), "NMSet") == 1)
			continue
		endif
		
		wnote = "WPrefix:" + StrVarOrDefault("CurrentPrefix", StrVarOrDefault("WavePrefix", ""))
		
		if (StringMatch(setName, "SetX") == 1)
			wnote += "\rExcluding:" + num2str(NMSetXType())
		endif
		
		NMNoteType(setName, "NMSet", "Wave#", "True (1) / False (0)", wnote)
		
	endfor

End // NMSetsTag

//****************************************************************
//****************************************************************
//****************************************************************

Function AreNMSets(setList)
	String setList
	
	Variable icnt, yes = 1
	
	for (icnt = 0; icnt < 3; icnt += 1)
		yes *= isNMSet(StringFromList(icnt, setList), 1)
	endfor
	
	return yes
	
End // AreNMSets

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMSet(setName, strict)
	String setName
	Variable strict // (0) no (1) yes, only strict Sets (Type:NMSets)
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	
	String cPrefix = StrVarOrDefault("CurrentPrefix", "")
	
	String type = NMNoteStrByKey(setName, "Type")
	String prefix = NMNoteStrByKey(setName, "Prefix")
	
	if ((WaveExists($setName) == 0) || (numpnts($setName) != nwaves))
		return 0
	endif
	
	//if ((StringMatch(type, "NMSet") == 1) && (StringMatch(prefix, cPrefix) == 1))
	if (StringMatch(type, "NMSet") == 1)
		return 1
	endif
	
	if (nwaves == 0)
		return 0
	endif
	
	WaveStats /Q $setName
	
	if ((numtype(V_min) == 0) && ((V_max != 0) && (V_max != 1)))
		return 0
	endif
	
	if ((numtype(V_max) == 0) && ((V_max != 0) && (V_max != 1)))
		return 0
	endif
	
	if (strict == 0)
		return 1
	endif
	
	return 0

End // IsNMSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsList(strict)
	Variable strict // (0) no (1) yes, only strict Sets (Type:NMSets)
	
	Variable wcnt
	String wName
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	
	String wList = WaveListOfSize(nwaves, "Set*")
	String wList2 = NMSetsDataList()
	String allList = WaveListOfSize(nwaves, "!" + StrVarOrDefault("WavePrefix","") + "*")
	String remList = WaveList("*TShift*", ";", "")
	
	remList += "WavSelect;ChanSelect;Group;FileScaleFactors;MyScaleFactors;"
	
	wList = SortListAlphaNum(wList, "Set")
	wList2 = SortListAlphaNum(wList2, "Set_Data")
	
	wList = RemoveListFromList(wList2, wList, ";")
	wList = RemoveFromList("SetX", wList)
	wList = AddListItem("SetX", wList, ";", inf)
	
	//wList += wList2
	remList += wList2 // remove Set_Data waves
	
	allList = RemoveListFromList(wList+remList, allList, ";")
	
	wList += allList

	if (ItemsInList(wList) < 1)
		return ""
	endif
	
	for (wcnt = ItemsInList(wList)-1; wcnt >= 0; wcnt -= 1)
	
		wName = StringFromList(wcnt, wList)
		
		//if ((IsNMSet(wName, strict) == 0) || (StringMatch(wName[0,2], "ST_") == 1))
		if (IsNMSet(wName, strict) == 0)
			wList = RemoveFromList(wName, wList)
		endif
		
	endfor
	
	return wList

End // NMSetsList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDataNew() // special Sets for importing/appending data
	
	Variable icnt, jcnt
	String setName, prefix = "Set_Data"
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	
	for (icnt = 0; icnt < 99; icnt += 1)
	
		setName = prefix + num2str(icnt)
		
		if (WaveExists($setName) == 0)
			break
		endif
		
	endfor
	
	jcnt = icnt
	
	NMSetsDefine(setName, 1, 0, inf, 0, 0) // create new Set
	
	Wave newSet = $setName
	
	for (icnt = 0; icnt < jcnt; icnt += 1)
		
		Wave oldSet = $(prefix + num2str(icnt))
		
		Redimension /N=(nwaves) oldSet
		
		newSet = newSet && (!oldSet)
	
	endfor

End // NMSetsDataNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsDataList()

	return WaveListOfSize(NumVarOrDefault("NumWaves", 0), "Set_Data*")

End // NMSetsDataList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsHook(infoStr)
	String infoStr
	
	String event= StringByKey("EVENT", infoStr)
	String win= StringByKey("WINDOW", infoStr)

	strswitch(event)
		case "deactivate":
		case "kill":
			UpdateNMSets(1)
	endswitch

End // NMSetsHook

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Sets Table functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsTableName()

	return NMPrefix(NMFolderPrefix("")+"SetsTable")
	
End // NMSetsTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsTable(option)
	Variable option // (-1) clear (1) update
	
	if (IgorVersion() < 5)
		return NMSetsTableIgor4(option)
	else
		return NMSetsTableIgor5(option)
	endif

End // NMSetsTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsTableIgor4(option)
	Variable option // (-1) clear (1) update
	
	Variable wcnt, x1, x2, y1, y2, width = 340, height = 415
	String wlist, wName, df = NMDF()
	
	Variable cwave = NumVarOrDefault("CurrentWave", 0)
	
	Variable xPixels = NumVarOrDefault(df+"xPixels", 1000)
	
	String arg = StrVarOrDefault(df+"SetsArgument", "")
	
	String tname = NMSetsTableName()
	
	if ((option < 0) && (WinType(tname) != 2))
		return 0
	endif
	
	String setList = NMSetsPanelList()
	
	x1 = (xPixels/2) + (width/2)
	y1 = 140
	x2 = x1 + width
	y2 = y1 + height
	
	if (WinType(tname) != 2)
		DoWindow /K $tname
		Edit /K=1/N=$tName/W=(x1, y1, x2, y2) as "Sets Table"
		Execute /Z "ModifyTable title(Point)= \"" + StrVarOrDefault("CurrentPrefix","") + "\""
		SetWindow $tname hook=NMSetsHook
	endif
	
	DoWindow /F $tName
	
	wlist = WaveList("*", ";","WIN:"+tname)
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
		RemoveFromTable $StringFromList(wcnt, wlist)
	endfor
	
	if (option < 0)
		return 0
	endif
	
	if (StringMatch(arg[0,4], "Group") == 1)
		arg = "Group"
	endif
	
	setList = AddListItem(arg, setList, ";", inf)
	
	for (wcnt = 0; wcnt < ItemsInList(setList); wcnt += 1)
		wName = StringFromList(wcnt, setList)
		if (WaveExists($wName) == 1)
			AppendToTable $wName
		endif
	endfor
	
	Execute /Z "ModifyTable selection=(" + num2str(cwave) + ",0," + num2str(cwave) + ",0, 0,0)"
	
	return 0

End // NMSetsTableIgor4

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsTableIgor5(option)
	Variable option // (-1) clear (1) update
	
	Variable wcnt, x1 = 350, x2 = 1500, y1 = 0, y2 = 1000
	String wlist, wname, txt, df = NMDF()
	
	Variable cwave = NumVarOrDefault("CurrentWave", 0)
	
	String arg = StrVarOrDefault(df+"SetsArgument", "")
	
	String pname = NMSetsPanelName()
	String tname = NMSetsTableName()
	String child = pname + "#" + tname
	
	if (WinType(pname) != 7)
		return -1
	endif
	
	String setList = NMSetsPanelList()
	
	//String clist = ChildWindowList(pname)
	Execute /Z "SetNMstr(\"" + df+"ChildWinList\", ChildWindowList(\"" + pname + "\"))"
	String clist = StrVarOrDefault(df+"ChildWinList", "")
	
	if (WhichListItem(tname, clist) < 0)
	
		//Edit /Host=$pname/N=$tname/W=(x1, y1, x2, y2)
		txt = "(" + num2str(x1) + "," + num2str(y1) + "," + num2str( x2) + "," + num2str( y2) + ")" 
		Execute "Edit /Host=" + pname + "/N=" + tname + "/W=" + txt
		
		Execute /Z "ModifyTable title(Point)= \"" + StrVarOrDefault("CurrentPrefix","") + "\""
		//SetWindow $(pname+"#"+tname) hook=NMSetsHook // does not work
		
	endif
	
	wlist = WaveList("*", ";","WIN:"+child)
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
		Execute /Z "RemoveFromTable /W=" + child + " " + StringFromList(wcnt, wlist)
	endfor
	
	if (option < 0)
		return 0
	endif
	
	if (StringMatch(arg[0,4], "Group") == 1)
		arg = "Group"
	endif
	
	setList = AddListItem(arg, setList, ";", inf)
	
	for (wcnt = 0; wcnt < ItemsInList(setList); wcnt += 1)
		wName = StringFromList(wcnt, setList)
		if (WaveExists($wName) == 1)
			//AppendToTable /W=$(pname+"#"+tname) $wName
			Execute /Z "AppendToTable /W=" + child + " " + wName
		endif
	endfor
	
	//ModifyTable /W=$(pname+"#"+tname) selection=(cwave , 0 , cwave , inf , 0 ,0 )
	txt = "(" + num2str(cwave) + ",0," + num2str(cwave) + ",0, 0,0)"
	Execute /Z "ModifyTable /W=" + child + "selection="
	
	return 0

End // NMSetsTableIgor5

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEdit()

	String tname = NMSetsTableName()
	String wlist = NMSetsList(0) + NMSetsDataList()
	
	if (WinType(tname) == 2)
		DoWindow /F $tname
		return 0
	endif
	
	DoWindow /K $tname
	Edit /K=1/N=$tname/W=(0,0,0,0) Set1, Set2, SetX as "Set Waves"
	Execute /Z "ModifyTable title(Point)= \"" + StrVarOrDefault("WavePrefix","") + "\""
	SetCascadeXY(tname)
	
	SetWindow $tname hook=NMSetsHook
	
	Variable icnt
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		AppendToTable $StringFromList(icnt, wlist)
	endfor
	
End // NMSetsEdit

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Sets Panel functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelName()

	return NMPrefix("SetsPanel")
	
End // NMSetsPanelName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelList()

	String df = NMDF()
	String setList = StrVarOrDefault(df+"SetsSelect", "")
	
	if (StringMatch(setList, "All") == 1)
	
		setList = NMSetsList(0)
		
		if (NMSetXType() == 1)
			setList = RemoveFromList("SetX", setList)
		endif
		
		return setList
		
	else
		
		return setList + ";"
	
	endif

End // NMSetsPanelList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelCall()

	NMCmdHistory("NMSetsPanel", "")
	
	return NMSetsPanel()

End // NMSetsPanelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanel()
	
	Variable x1, x2, y1, y2, width = 600, height = 415
	Variable x0 = 35, y0 = 15, xinc = 90, yinc = 35
	
	String df = NMDF()
	String pname = NMSetsPanelName()
	String tname = NMSetsTableName()
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	Variable xPixels = NumVarOrDefault(df+"xPixels", 1000)
	
	if (WinType(pname) == 7)
		DoWindow /F $pname
		DoWindow /F $tname
		NMSetsPanelUpdate(1)
		return 0
	endif
	
	NMSetsTagDefaults()
	
	if (IgorVersion() < 5)
		width = 340
	endif
	
	x1 = (xPixels - width) /2
	y1 = 140
	x2 = x1 + width
	y2 = y1 + height
	
	CheckNMstr(df+"SetsSelect", "Set1")
	CheckNMvar(df+"SetsAutoClear", 1)
	
	NMSetsPanelDefaults(StrVarOrDefault(df+"SetsSelect", "Set1"))
	
	DoWindow /K$pname
	NewPanel /K=1/N=$pname/W=(x1,y1,x2,y2) as "Edit Sets"
	SetWindow $pname hook=NMSetsHook
	
	PopupMenu $NMPrefix("SetsMenu"), title=" ", pos={x0+215,y0}, size={0,0}, bodyWidth=160, fsize=14
	PopupMenu $NMPrefix("SetsMenu"), mode=1, value="Set1;Set2;SetX;", proc=NMSetsPanelPopup
	
	CheckBox $NMPrefix("SetsExclude"), title="Excluding", pos={x0+230,y0+4}, size={16,18}
	CheckBox $NMPrefix("SetsExclude"), value=0, proc=NMSetsPanelCheckBox
	
	x0 = 35; y0 += 70
	
	GroupBox $NMPrefix("SetsGrp"), title = "Define (010101...)", pos={x0-20,y0-30}, size={310,135}
	
	SetVariable $NMPrefix("SetsFrom"), title="from wave: ", limits={0,nwaves-1,1}, pos={x0,y0+0*yinc}, size={150,50}
	SetVariable $NMPrefix("SetsFrom"), value=$(df+"SetsFrom"), fsize=14, proc=NMSetsPanelVariable
	
	SetVariable $NMPrefix("SetsTo"), title="to: ", limits={0,nwaves-1,1}, pos={x0+175,y0+0*yinc}, size={95,50}
	SetVariable $NMPrefix("SetsTo"), value=$(df+"SetsTo"), fsize=14, proc=NMSetsPanelVariable
	
	SetVariable $NMPrefix("SetsSkip"), title="skip: ", limits={0,nwaves,1}, pos={x0,y0+1*yinc}, size={120,50}
	SetVariable $NMPrefix("SetsSkip"), value=$(df+"SetsSkip"), fsize=14, proc=NMSetsPanelVariable
	
	PopupMenu $NMPrefix("SetsValue"), title="value: ", pos={x0+270,y0+1*yinc}, size={0,0}, bodyWidth=80
	PopupMenu $NMPrefix("SetsValue"), mode=1, value="0;1;NAN;", proc=NMSetsPanelPopup, fsize=14
	
	Button $NMPrefix("SetsDefine"), title="Execute", pos={x0+100,y0+2*yinc}, size={70,20}, proc=NMSetsPanelButton
	
	CheckBox $NMPrefix("SetsAutoClear"), title="Auto Clear", pos={x0+190,y0+2*yinc+4}, size={16,18}
	CheckBox $NMPrefix("SetsAutoClear"), value=0, proc=NMSetsPanelCheckBox
	
	y0 += 145
	
	GroupBox $NMPrefix("SetsGrp2"), title = "Equation", pos={x0-20,y0-25}, size={310,60}
	
	PopupMenu $NMPrefix("SetsOp"), title=" ", pos={x0+70,y0}, size={0,0}, bodyWidth=70, fsize=14
	PopupMenu $NMPrefix("SetsOp"), mode=1, value="=;AND;OR;", proc=NMSetsPanelPopup
	
	PopupMenu $NMPrefix("SetsArg"), title=" ", pos={x0+185,y0}, size={0,0}, bodyWidth=100, fsize=14
	PopupMenu $NMPrefix("SetsArg"), mode=1, value=" ", proc=NMSetsPanelPopup
	
	Button $NMPrefix("SetsFxn"), title="Execute", pos={x0+200,y0}, size={70,20}, proc=NMSetsPanelButton
	
	x0 = 45; y0 += 55; yinc = 35
	
	Button $NMPrefix("SetsClear"), title="Clear", pos={x0,y0}, size={70,20}, proc=NMSetsPanelButton
	Button $NMPrefix("SetsCopy"), title="Copy", pos={x0+1*xinc,y0}, size={70,20}, proc=NMSetsPanelButton
	Button $NMPrefix("SetsNew"), title="New", pos={x0+2*xinc,y0}, size={70,20}, proc=NMSetsPanelButton
	
	Button $NMPrefix("SetsInvert"), title="Invert", pos={x0,y0+1*yinc}, size={70,20}, proc=NMSetsPanelButton
	Button $NMPrefix("SetsZ2N"), title="0 > Nan", pos={x0+1*xinc,y0+1*yinc}, size={70,20}, proc=NMSetsPanelButton
	Button $NMPrefix("SetsN2Z"), title="Nan > 0", pos={x0+2*xinc,y0+1*yinc}, size={70,20}, proc=NMSetsPanelButton
	
	Button $NMPrefix("SetsKill"), title="Kill", pos={x0,y0+2*yinc}, size={70,20}, proc=NMSetsPanelButton
	Button $NMPrefix("SetsRename"), title="Rename", pos={x0+1*xinc,y0+2*yinc}, size={70,20}, proc=NMSetsPanelButton
	Button $NMPrefix("SetsClose"), title="Close", pos={x0+2*xinc,y0+2*yinc}, size={70,20}, proc=NMSetsPanelButton
	
	CheckBox $NMPrefix("SetsAdvance"), title="Auto Advance", pos={x0+20,y0+3*yinc}, size={16,18}
	CheckBox $NMPrefix("SetsAdvance"), value=0, proc=NMSetsPanelCheckBox
	
	CheckBox $NMPrefix("SetsDisplay"), title="Display : Set1,Set2,SetX", pos={x0+130,y0+3*yinc}
	CheckBox $NMPrefix("SetsDisplay"), size={16,18}, value=1, proc=NMSetsPanelCheckBox
	
	NMSetsPanelUpdate(1)
	
End // NMSetsPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelUpdate(updateTable)
	Variable updateTable // (0) no (1) yes
	
	Variable md, dis
	String df = NMDF()
	
	String setsList = NMSetsList(0)
	String pname = NMSetsPanelName()
	String displayList = NMSetsDisplayList()
	
	if (WinType(pname) != 7)
		return -1
	endif
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	
	String setName = StrVarOrDefault(df+"SetsSelect", "Set1")
	
	Variable from = NumVarOrDefault(df+"SetsFrom", 0)
	Variable to = NumVarOrDefault(df+"SetsTo", Nan)
	Variable skip = NumVarOrDefault(df+"SetsSkip", 0)
	Variable value = NumVarOrDefault(df+"SetsValue", 1)
	
	String arg = StrVarOrDefault(df+"SetsArgument", "")
	String op = StrVarOrDefault(df+"SetsOperator", "=")
	
	DoWindow /T $pname, "Edit Sets : " + GetDataFolder(0)
	
	// Set menu
	
	md = WhichListItem(setName, "All;"+setsList)
	
	if (md >= 0)
		md += 1
	else
		setName = StringFromList(0, setsList)
		md = 1 + WhichListItem(setName, "All;"+setsList)
		SetNMstr(df+"SetsSelect", setName)
	endif
	
	PopupMenu $NMPrefix("SetsMenu"), win=$pname, mode=md, value="All;"+NMSetsList(0)
	
	// excluding checkbox
	
	dis = 1
	
	if (StringMatch(setName, "SetX") == 1)
		dis = 0
	endif
	
	CheckBox $NMPrefix("SetsExclude"), win=$pname, disable=dis, value=NMSetXType()
	
	// define variables
	
	if ((numtype(from) > 0) || (from < 0) || (from >= nwaves))
		from = 0
	endif
	
	if ((numtype(to) > 0) || (to < 0) || (to >= nwaves))
		to = nwaves - 1
	endif
	
	if ((numtype(skip) > 0) || (skip < 0))
		skip = 0
	endif
	
	if (nwaves <= 0)
		from = Nan; to = Nan
	endif
	
	SetNMvar(df+"SetsFrom", from)
	SetNMvar(df+"SetsTo", to)
	SetNMvar(df+"SetsSkip", skip)
	
	if (numtype(value) > 0)
		md = 3; value = Nan;
	elseif (value == 0)
		md = 1
	else
		md = 2; value = 1;
	endif
	
	SetNMvar(df+"SetsValue", value)
	
	PopupMenu $NMPrefix("SetsValue"), win=$pname, mode=md, value="0;1;NAN;"
	
	// operator menu
	
	md = WhichListItem(op, "=;AND;OR;")
	
	if (md >= 0)
		md += 1
	else
		md = 1
		SetNMstr(df+"SetsOperator", "=")
	endif
	
	PopupMenu $NMPrefix("SetsOp"), win=$pname, mode=md, value="=;AND;OR;"
	
	// argument menu
	
	md = WhichListItem(arg, setsList+NMGroupList(1))
	
	if (md >= 0)
		md += 2
	else
		md = 1
		SetNMstr(df+"SetsArgument", "")
	endif
	
	PopupMenu $NMPrefix("SetsArg"), win=$pname, mode=md, value=" ;"+NMSetsList(0)+NMGroupList(1)
	
	// button controls
	
	dis = 0
	
	if (WhichListItem(setName, "Set1;Set2;SetX;All;") >= 0)
		dis = 2
	endif
	
	Button $NMPrefix("SetsKill"), win=$pname, disable=dis
	Button $NMPrefix("SetsRename"), win=$pname, disable=dis
	
	CheckBox $NMPrefix("SetsAutoClear"), win=$pname, value=NumVarOrDefault(df+"SetsAutoClear", 0)
	CheckBox $NMPrefix("SetsAdvance"), win=$pname, value=NumVarOrDefault(df+"SetsAutoAdvance", 0)
	CheckBox $NMPrefix("SetsDisplay"), win=$pname, value=1, title="Display : " + ChangeListSep(displayList, ",")
	
	if (updateTable == 1)
		NMSetsTable(1)
	endif

End // NMSetsPanelUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelDefaults(setName)
	String setName
	String df = NMDF()
	
	if (NMNoteExists(setName, "Sets From") == 1)
		SetNMvar(df+"SetsFrom", NMNoteVarByKey(setName, "Sets From"))
		SetNMvar(df+"SetsTo", NMNoteVarByKey(setName, "Sets To"))
		SetNMvar(df+"SetsSkip", NMNoteVarByKey(setName, "Sets Skip"))
		SetNMvar(df+"SetsValue", NMNoteVarByKey(setName, "Sets Value"))
	else
		SetNMvar(df+"SetsFrom", 0)
		SetNMvar(df+"SetsTo", NumVarOrDefault("NumWaves", Nan)-1)
		SetNMvar(df+"SetsSkip", 0)
		SetNMvar(df+"SetsValue", 1)
	endif
	
	if (NMNoteExists(setName, "Sets Argument") == 1)
		SetNMstr(df+"SetsArgument", NMNoteStrByKey(setName, "Sets Argument"))
		SetNMstr(df+"SetsOperator", NMNoteStrByKey(setName, "Sets Operator"))
	else
		SetNMstr(df+"SetsArgument", "")
		SetNMstr(df+"SetsOperator", "=")
	endif

End // NMSetsPanelDefaults

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	NMSetsCall(NMCtrlName(NMPrefix(""), ctrlName), "")
	
	DoWindow /F $NMSetsPanelName()
	
End // NMSetsPanelVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelButton(ctrlName) : ButtonControl
	String ctrlName
	
	if (CheckCurrentFolder() == 0)
		return 0
	endif

	NMSetsCall(NMCtrlName(NMPrefix(""), ctrlName), "")
	
	DoWindow /F $NMSetsPanelName()
	
End // NMSetsPanelButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	if (CheckCurrentFolder() == 0)
		return 0
	endif
	
	NMSetsCall(NMCtrlName(NMPrefix(""), ctrlName), popStr)
	
	DoWindow /F $NMSetsPanelName()

End // NMSetsPanelPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	if (CheckCurrentFolder() == 0)
		return 0
	endif
	
	NMSetsCall(NMCtrlName(NMPrefix(""), ctrlName), num2str(checked))
	
	DoWindow /F $NMSetsPanelName()

End // NMSetsPanelCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelSelect(setName)
	String setName // ("") for current
	
	String df = NMDF()
	String pname = NMSetsPanelName()
	String setsList = NMSetsList(0)
	
	if (WinType(pname) != 7)
		return -1
	endif
	
	if (strlen(setName) == 0)
		setName = StrVarOrDefault(df+"SetsSelect", "")
	endif
	
	if (WhichListItem(setName, "All;"+setsList) < 0)
		setName = StringFromList(0, setsList)
		SetNMstr(df+"SetsSelect", setName)
	else
		SetNMstr(df+"SetsSelect", setName)
	endif
	
	NMSetsPanelDefaults(setName)
	NMSetsPanelUpdate(1)
	
End // NMSetsPanelSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelValue(value)
	Variable value
	
	SetNMvar(NMDF()+"SetsValue", value)
	NMSetsPanelDefineAuto()
	NMSetsPanelUpdate(0)
	
End // NMSetsPanelValue

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelOp(op)
	String op
	
	SetNMstr(NMDF()+"SetsOperator", op)
	NMSetsPanelUpdate(0)
	
End // NMSetsPanelOp

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelArg(arg)
	String arg
	
	SetNMstr(NMDF()+"SetsArgument", arg)
	NMSetsPanelUpdate(1)
	
End // NMSetsPanelArg

//****************************************************************
//****************************************************************
//****************************************************************

Function SetsPanelFxn()

	String vlist = "", df = NMDF()
	String setList = NMSetsPanelList()
	
	String arg = StrVarOrDefault(df+"SetsArgument", "")
	String op = StrVarOrDefault(df+"SetsOperator", "=")
	
	vlist = NMCmdList(setList, vlist)
	vlist = NMCmdStr(arg, vlist)
	vlist = NMCmdStr(op, vlist)
	NMCmdHistory("NMSetsFxn", vlist)
	
	NMSetsFxn(setList, arg, op)

End // SetsPanelFxn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelDefineAuto()

	if (NumVarOrDefault(NMDF()+"SetsAutoClear", 0) == 1)
		return NMSetsPanelDefine()
	endif

End // NMSetsPanelDefineAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelDefine()

	String vlist = "", df = NMDF()
	
	Variable first = NumVarOrDefault(df+"SetsFrom", Nan)
	Variable last = NumVarOrDefault(df+"SetsTo", Nan)
	Variable skip = NumVarOrDefault(df+"SetsSkip", 0)
	Variable value = NumVarOrDefault(df+"SetsValue", 1)
	Variable clear = NumVarOrDefault(df+"SetsAutoClear", 0)
	
	String setList = NMSetsPanelList()
	
	vlist = NMCmdList(setList, vlist)
	vlist = NMCmdNum(value, vlist)
	vlist = NMCmdNum(first, vlist)
	vlist = NMCmdNum(last, vlist)
	vlist = NMCmdNum(skip, vlist)
	vlist = NMCmdNum(clear, vlist)
	NMCmdHistory("NMSetsDefine", vlist)

	return NMSetsDefine(setList, value, first, last, skip, clear)

End // NMSetsPanelDefine

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelRename()
	String df = NMDF()
	String setName = StrVarOrDefault(df+"SetsSelect", "")
	String newName = NMSetsRenameCall(setName)
	
	if (strlen(newName) > 0)
		SetNMstr(df+"SetsSelect", newName)
	endif
	
	NMSetsPanelUpdate(0)
	
	return newName

End // NMSetsPanelRename

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelKill()

	String df = NMDF()
	String setName = StrVarOrDefault(df+"SetsSelect", "")
	
	DoAlert 1, "Are you sure you want to kill \"" + setName + "\"?"
		
	if (V_flag != 1)
		return 0
	endif
	
	SetNMstr(df+"SetsSelect", "Set1")
	NMSetsTable(1)
	NMSetsKillCall(setName)
	NMSetsPanelUpdate(0)
	
End // NMSetsPanelKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelCopy()
	String df = NMDF()

	String setName = StrVarOrDefault(df+"SetsSelect", "")
	
	if (WaveExists($setName) == 0)
		return ""
	endif
	
	String newName = NMSetsCopyCall(setName)
	
	if (strlen(newName) == 0)
		return ""
	endif

	SetNMstr(df+"SetsSelect", newName)
	
	NMSetsPanelUpdate(1)
	
	return newName

End // NMSetsPanelCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelNew()

	String df = NMDF()
	
	String newName = NMSetsNewCall("")

	if (strlen(newName) == 0)
		return ""
	endif
	
	SetNMstr(df+"SetsSelect", newName)
	
	NMSetsPanelUpdate(1)
	
	return newName

End // NMSetsPanelNew

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelExclude(x)
	Variable x
	
	NMSetXCall(x)
	NMSetsPanelUpdate(0)
	
End // NMSetsPanelExclude

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelAdvance(on)
	Variable on
	
	NMSetsAutoAdvanceCall(on)
	NMSetsPanelUpdate(0)
	
End // NMSetsPanelAdvance

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelDisplay(on)
	Variable on
	
	NMSetsDisplayCall()
	
	NMSetsPanelUpdate(0)
	
End //  NMSetsPanelDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelAutoClear(on)
	Variable on
	
	SetNMvar(NMDF()+"SetsAutoClear", on)
	
End // NMSetsPanelAutoClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelClose()

	DoWindow /K $NMSetsPanelName()
	DoWindow /K $NMSetsTableName()
	
	UpdateCurrentWave()

End // NMSetsPanelClose

//****************************************************************
//****************************************************************
//****************************************************************