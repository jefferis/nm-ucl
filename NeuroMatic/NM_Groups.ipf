#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Groups Functions
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last Modified 18 Nov 2004
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsCall(fxn, select)
	String fxn
	String select
	
	Variable snum = str2num(select)

	strswitch(fxn)
	
		case "On/Off":
			return NMGroupsToggle()
			
		case "Define":
			return NMGroupsDefine()
			
		case "Table":
			return NMGroupsEdit()
			
		// Groups Panel Functions
		
		case "Panel":
			return NMGroupsPanelCall()
		
		case "NumGroups":
			NMGroupsNumCall(snum)
		case "FirstGroup":
			return NMGroupsPanelSeq()
	
		case "GroupWStart":
		case "GroupWEnd":
		case "GroupBlocks":
			return NMGroupsPanelExecuteAuto()
			
		case "GroupSeq":
			return NMGroupsPanelExecute()
			
		case "GroupsAutoClear":
			NMGroupsPanelAutoClear(snum)
			break
	
		case "Clear":
		case "GroupsClear":
			return NMGroupsClearCall()
		
		case "GroupsClose":
			return NMGroupsPanelClose()
			
	endswitch
	
	return -1
	
End // NMGroupsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsToggle()

	Variable on = !NumVarOrDefault(NMDF()+"GroupsOn", 1)
	
	NMCmdHistory("NMGroupsOn", NMCmdNum(on, ""))
	
	return NMGroupsOn(on)
	
End // NMGroupsToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsOn(on)
	Variable on // (0) no (1) yes
	
	String df = NMDF()
	
	switch(on)
		case 0:
			NMGroupsPanelClose()
			break
		default:
			on = 1
	endswitch
	
	if (on == NumVarOrDefault(df+"GroupsOn", 0))
		return on
	endif
	
	SetNMvar(df+"GroupsOn", on)
	UpdateNMPanel(0)
	
	return on
	
End // NMGroupsOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsDefine() // turn on/off Group functionality

	if (WaveExists(Group) == 0)
		return -1
	endif
	
	Wave Group
	
	Variable npnts = numpnts(Group)
	
	String seqStr
	
	Variable ngrps = NumVarOrDefault("NumGrps", 2)
	Variable first = NumVarOrDefault("FirstGrp", NMCountFrom())
	Variable from = 0
	Variable to = npnts - 1
	Variable blocks = 1
	
	if (exists("Group") != 1)
		Abort "Abort: Group wave does not exist."
	endif
	
	if (ngrps < 2)
		ngrps = 2
	endif
	
	Prompt ngrps, "number of groups:"
	Prompt first, "first group number:"
	Prompt from, "define sequence from wave:"
	Prompt to, "define sequence to wave:"
	Prompt blocks, "in blocks of:"
	
	DoPrompt "Define Group Sequence", ngrps, first, from, to, blocks
	
	if (V_flag == 1)
		return 0 // user cancelled
	endif
		
	if (ngrps <= 1)
		Abort "Abort: number of groups must be greater than one."
	endif

	if ((from < 0) || (from > npnts-1))
		Abort "Abort Groups: starting wave number out of bounds."
	endif
	
	if ((to < 0) || (to > npnts-1))
		Abort "Abort Groups: ending wave number out of bounds."
	endif
	
	seqStr = num2str(first) + "," + num2str(first + ngrps - 1)
	
	//NMGroupSeq(seqStr, from, to, blocks)
	NMGroupSeqCall(seqStr, from, to, blocks)
	
	SetNMvar("NumGrps", ngrps)
	SetNMvar("FirstGrp", first)
	
	NMGroupsOn(1)
	
	return 0

End // NMGroupsDefine

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsClearCall()

	NMCmdHistory("NMGroupsClear", "")
	
	return NMGroupsClear()

End // NMGroupsClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsClear()

	SetNMwave("Group", -1, Nan)
	SetNMvar("CurrentGrp", Nan)
	
	Note /K Group
	NMGroupsTag("Group")
	
	return 0
			
End // NMGroupsClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupSeqDefault()
	
	Variable ngrps = NumVarOrDefault("NumGrps", 0)
	Variable first = NMGroupFirstDefault()
	
	String seqStr = num2str(first) + "," + num2str(first + ngrps - 1)
	
	NMGroupSeq(seqStr, 0, inf, 1)

End // NMGroupSeqDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupSeqCall(seqStr, fromWave, toWave, blocks)
	String seqStr
	Variable fromWave, toWave, blocks
	
	String vlist = ""
	
	vlist = NMCmdList(seqStr, vlist)
	vlist = NMCmdNum(fromWave, vlist)
	vlist = NMCmdNum(toWave, vlist)
	vlist = NMCmdNum(blocks, vlist)
	NMCmdHistory("NMGroupSeq", vlist)
	
	NMGroupSeq(seqStr, fromWave, toWave, blocks)
	
End // NMGroupSeqCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupSeq(seqStr, fromWave, toWave, blocks)
	String seqStr // seq string "0;1;2;3;" or "0,3" for range
	Variable fromWave // starting wave number
	Variable toWave // ending wave number
	Variable blocks // number of blocks in each group
	
	String txt, wName = "Group"
	
	CheckNMwave(wName, NumVarOrDefault("NumWaves", 0), 0)
	WaveSequence(wName, seqStr, fromWave, toWave, blocks) // NM_Utility.ipf
	NMGroupUpdate()
	NMGroupsOn(1)
	
	txt = "Groups Seq:" + ChangeListSep(seqStr, ",") + ";Groups From:" + num2str(fromWave)
	txt += ";Groups To:" + num2str(toWave) + ";Group Blocks:" + num2str(blocks) + ";"
	
	Note /K $wName
	NMGroupsTag(wName)
	Note $wName, "Func:NMGroupSeq"
	Note $wName, txt
	
	UpdateNMPanel(0)
	
End // NMGroupSeq

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupSeqWave(numGrps, firstGrp)
	Variable numGrps, firstGrp
	
	String seqStr, wName = "GroupSeq"
	
	if (numtype(numGrps) > 0)
		numGrps = NumVarOrDefault("NumGrps", 0)
	endif
	
	if (numtype(firstGrp) > 0)
		firstGrp = NMGroupFirstDefault()
	endif
	
	seqStr = num2str(firstGrp) + "," + num2str(firstGrp + numGrps - 1)
	
	CheckNMwave(wName, numGrps, 0)
	WaveSequence(wName, seqStr, 0, inf, 1) // NM_Utility.ipf
	NMGroupsTag(wName)

End // NMGroupSeqWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupList(type)
	Variable type // (0) e.g. "0;1;2;" (1) e.g. "Group0;Group1;Group2;"
	Variable gcnt
	String grpstr, glist = "", df = NMDF()
	
	if ((NumVarOrDefault(df+"GroupsOn", 0) == 0) || (WaveExists(Group) == 0))
		return ""
	endif
	
	Wave Group
	
	for (gcnt = 0; gcnt < numpnts(Group); gcnt += 1)
	
		if (numtype(Group[gcnt]) > 0)
			continue
		endif
		
		if (type == 0)
			grpstr = num2str(Group[gcnt])
		elseif (type == 1)
			grpstr = "Group" + num2str(Group[gcnt])
		else
			return ""
		endif
		
		if (WhichListItem(grpstr, glist) == -1)
			glist = AddListItem(grpstr, glist, ";", inf)
		endif
		
	endfor
	
	if (type == 0)
		return SortList(glist, ";", 2)
	else
		return SortListAlphaNum(glist, "Group")
	endif

End // NMGroupList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsNumCall(numGrps)
	Variable numGrps
	
	NMCmdHistory("NMGroupsNum", NMCmdNum(numGrps, ""))
	
	return NMGroupsNum(numGrps)
	
End // NMGroupsNumCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsNum(numGrps)
	Variable numGrps
	
	if ((numtype(numGrps) > 0) || (numGrps < 0))
		return -1
	endif
	
	SetNMvar("NumGrps", numGrps)
	
	return 0

End // NMGroupsNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupFirstDefault()
	String df = NMDF()

	return NumVarOrDefault(df+"FirstGrp", NMCountFrom())

End // NMGroupFirstDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupFirst()

	return str2num(StringFromList(0, NMGroupList(0)))

End // NMGroupFirst

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupLast()
	String glist = NMGroupList(0)

	return str2num(StringFromList(ItemsInlist(glist)-1, glist))

End // NMGroupLast

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupCheck(group) // return (0) no (1) yes
	Variable group // group number to check
	
	Variable GroupsOn = NumVarOrDefault(NMDF()+"GroupsOn", 0)
	
	if (WaveExists(Group) == 0)
		return 0
	endif
	
	WaveStats /Q Group
	
	if ((group >= V_min) && (group <= V_max))
		return 1*GroupsOn // yes, a group number
	else
		return 0 // no, not a group number
	endif

End // NMGroupCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupAssignCall(grpNum)
	Variable grpNum // group number
	
	Variable currentWave = -1 // current wave
	String vlist = ""
	
	vlist = NMCmdNum(currentWave, vlist)
	vlist = NMCmdNum(grpNum, vlist)
	NMCmdHistory("NMGroupAssign", vlist)
	
	return NMGroupAssign(currentWave, grpNum)
	
End // NMGroupAssignCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupSet(waveNum, grpNum) // old fxn name
	Variable waveNum // wave number (-1) for current
	Variable grpNum // group number
	
	NMGroupAssign(waveNum, grpNum)
	
End // NMGroupSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupAssign(waveNum, grpNum) // new fxn name
	Variable waveNum // wave number (-1) for current
	Variable grpNum // group number
	
	Variable currentWave = NumVarOrDefault("CurrentWave", -1)
	
	if (WaveExists(Group) == 0)
		return -1
	endif
	
	if (waveNum == -1)
		waveNum = currentWave
	endif
	
	if ((waveNum >= 0) && (waveNum < NumVarOrDefault("NumWaves", 0)))

		Wave Group
	
		Group[waveNum] = grpNum // update group wave with user input
		UpdateNMPanel(0)
		
		return 0
		
	endif
	
	return -1

End // NMGroupAssign

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupGet(waveNum)
	Variable waveNum // wave number, or (-1) for current
	
	if (WaveExists(Group) == 0)
		return Nan
	endif
	
	if (waveNum == -1)
		waveNum = NumVarOrDefault("CurrentWave", -1)
	endif
	
	if (waveNum == -1)
		return Nan
	endif

	Wave Group
	
	return Group[waveNum]
	
End // NMGroupGet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupUpdate()

	SetNMvar("CurrentGrp", NMGroupGet(-1))

End // NMGroupUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupFilter(n, grpNum)
	Variable n
	Variable grpNum

	if ((grpNum == -1) && (numtype(n) == 0))
		return 1
	elseif (n == grpNum)
		return 1
	else
		return 0
	endif
	
End // NMGroupFilter

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsTagDefaults()

	NMGroupsTag("Group;GroupSeq;")

End // NMGroupsTagDefaults

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsTag(grpList)
	String grpList
	
	Variable icnt
	String wName, wnote
	
	for (icnt = 0; icnt < ItemsInList(grpList); icnt += 1)
	
		wName = StringFromList(icnt, grpList)
		
		if (WaveExists($wName) == 0)
			continue
		endif
		
		if (StringMatch(NMNoteStrByKey(wName, "Type"), "NMGroup") == 1)
			continue
		endif
		
		wnote =  "WPrefix:" + StrVarOrDefault("CurrentPrefix", StrVarOrDefault("WavePrefix", ""))
		NMNoteType(wName, "NMGroup", "Wave#", "Group", wnote)
		
	endfor

End // NMGroupsTag

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMGroup(wName)
	String wName
	
	String cPrefix = StrVarOrDefault("CurrentPrefix", "")
	
	String type = NMNoteStrByKey(wName, "Type")
	String prefix = NMNoteStrByKey(wName, "Prefix")
	
	if (WaveExists($wName) == 0)
		return 0
	endif
	
	if ((StringMatch(type, "NMGroup") == 1) && (StringMatch(prefix, cPrefix) == 1))
		return 1
	endif
	
	return 0

End // IsNMGroup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsHook(infoStr)
	String infoStr
	
	String event= StringByKey("EVENT",infoStr)
	String win= StringByKey("WINDOW",infoStr)
	
	strswitch(event)
		case "deactivate":
		case "kill":
			NMGroupUpdate()
			NMWaveSelect("") // update WaveSelect
	endswitch

End // NMGroupsHook

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Groups Table functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsTableName()

	return NMPrefix("GroupsTable")
	
End // NMGroupsTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsTable(option)
	Variable option // (0) clear (1) update
	
	if (IgorVersion() < 5)
		return NMGroupsTableIgor4(option)
	else
		return NMGroupsTableIgor5(option)
	endif
	
End // NMGroupsTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsTableIgor4(option)
	Variable option // (0) clear (1) update
	
	Variable wcnt, x1, x2, y1, y2, width = 295, height = 370
	String wlist, df = NMDF()
	
	Variable cwave = NumVarOrDefault("CurrentWave", 0)
	
	Variable xPixels = NumVarOrDefault(df+"xPixels", 1000)
	
	String tname = NMGroupsTableName()
	String pname = NMGroupsPanelName()
	
	if ((option < 0) && (WinType(tname) != 2))
		return 0
	endif
	
	if (WaveExists(GroupSeq) == 0)
		NMGroupSeqWave(Nan, Nan)
	endif
	
	x1 = (xPixels/2) + (width/2) + 20
	y1 = 140 + 40
	x2 = x1 + width
	y2 = y1 + height
	
	if (WinType(pname) != 2)
		DoWindow /K $tname
		Edit /K=1/W=(x1, y1, x2, y2) as "Groups Table"
		DoWindow /C $tname
		Execute /Z "ModifyTable title(Point)= \"" + StrVarOrDefault("CurrentPrefix","") + "\""
		SetWindow $tname hook=NMGroupsHook
	endif
	
	DoWindow /F $tname
	
	wlist = WaveList("*", ";","WIN:"+tname)
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
		//RemoveFromTable /W=$tname $StringFromList(wcnt, wlist)
		RemoveFromTable $StringFromList(wcnt, wlist)
	endfor

	if (option < 0)
		return 0
	endif
	
	if (WaveExists(Group) == 1)
		AppendToTable Group
	endif
	
	if (WaveExists(GroupSeq) == 1)
		AppendToTable GroupSeq
	endif
	
	Execute /Z "ModifyTable selection=(" + num2str(cwave) + ",0," + num2str(cwave) + ",0, 0,0)"

End // NMGroupsTableIgor4

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsTableIgor5(option)
	Variable option // (0) clear (1) update
	
	Variable wcnt, x1 = 0.5, y1 = 0, x2 = 1, y2 = 1
	String wlist, txt, df = NMDF()
	
	Variable cwave = NumVarOrDefault("CurrentWave", 0)
	
	String tname = NMGroupsTableName()
	String pname = NMGroupsPanelName()
	String child = pname + "#" + tname
	
	if (WinType(pname) != 7)
		return -1
	endif
	
	if (WaveExists(GroupSeq) == 0)
		NMGroupSeqWave(Nan, Nan)
	endif
	
	//String clist = ChildWindowList(pname)
	Execute /Z "SetNMstr(\"" + df+"ChildWinList\", ChildWindowList(\"" + pname + "\"))"
	String clist = StrVarOrDefault(df+"ChildWinList", "")
	
	if (WhichListItem(tname, clist) < 0)
	
		//Edit /Host=$pname/N=$tname/W=(x1, y1, x2, y2)
		txt = "(" + num2str(x1) + "," + num2str(y1) + "," + num2str( x2) + "," + num2str( y2) + ")" 
		Execute "Edit /Host=" + pname + "/N=" + tname + "/W=" + txt
		
		Execute /Z "ModifyTable title(Point)= \"" + StrVarOrDefault("CurrentPrefix","") + "\""
		//SetWindow $(pname+"#"+tname) hook=NMGroupsHook // does not work
		
	endif
	
	wlist = WaveList("*", ";","WIN:"+child)
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
		Execute /Z "RemoveFromTable /W=" + child + " " + StringFromList(wcnt, wlist)
	endfor

	if (option < 0)
		return 0
	endif
	
	if (WaveExists(Group) == 1)
		Execute /Z "AppendToTable /W=" + child + " Group"
	endif
	
	if (WaveExists(GroupSeq) == 1)
		Execute /Z "AppendToTable /W=" + child + " GroupSeq"
	endif
	
	//ModifyTable /W=$(pname+"#"+tname) selection=(cwave , 0 , cwave , inf , 0 ,0 )
	txt = "(" + num2str(cwave) + ",0," + num2str(cwave) + ",0, 0,0)"
	Execute /Z "ModifyTable /W=" + child + "selection="

End // NMGroupsTableIgor5

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsEdit()
	
	if (exists("Group") != 1)
		Abort "Abort: Group wave does not exist."
	endif
	
	String tname = NMGroupsTableName()

	SVAR WavePrefix
	
	if (WinType(tname) == 2)
		DoWindow /F $tname
		return 0
	endif
	
	DoWindow /K $tname
	Edit /K=1/W=(0,0,0,0) Group as "Group Wave"
	DoWindow /C $tname
	Execute /Z "ModifyTable title(Point)= \"" + WavePrefix + "\""
	SetCascadeXY(tname)
	
	SetWindow $tname hook=NMGroupsHook

End // NMGroupsEdit

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Groups Panel functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsPanelName()

	return "MN_GroupsPanel"
	
End // NMGroupsPanelName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelCall()

	NMCmdHistory("NMGroupsPanel", "")

	return NMGroupsPanel()

End // NMGroupsPanelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanel()
	Variable x1, x2, y1, y2, width = 600, height = 370
	Variable x0 = 44, y0 = 65, yinc = 40
	
	String df = NMDF()
	
	String Computer = StrVarOrDefault(df+"Computer", "mac")
	
	Variable xPixels = NumVarOrDefault(df+"xPixels", 1000)
	Variable ngrps = NumVarOrDefault("NumGrps", 0)
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	
	String pname = NMGroupsPanelName()
	String tname = NMGroupsTableName()
	
	NMGroupsOn(1)
	
	if (WinType(pname) == 7)
		DoWindow /F $pname
		DoWindow /F $tname
		NMGroupsPanelUpdate()
		return 0
	endif
	
	CheckNMvar(df+"GroupsAutoClear", 1)
	NMGroupsTagDefaults()
	NMGroupsPanelDefaults()
	
	if (IgorVersion() < 5)
		width = 295
	endif
	
	x1 = 20 + (xPixels - width) / 2
	y1 = 140 + 40
	x2 = x1 + width
	y2 = y1 + height
	
	DoWindow /K $pname
	NewPanel /K=1/W=(x1,y1,x2,y2) as "Edit Groups"
	DoWindow /C $pname
	
	GroupBox $NMPrefix("GroupsBox"), title = "Sequence (01230123...)", pos={x0-20,y0-30}, size={245,270}
	
	SetVariable $NMPrefix("NumGroups"), title="number of Groups:", limits={1,inf,0}, pos={x0,y0}, size={200,50}, fsize=14
	SetVariable $NMPrefix("NumGroups"), value=$(df+"NumGrps"), proc=NMGroupsSetVariable
	
	SetVariable $NMPrefix("FirstGroup"), title="first Group number:", limits={0,inf,0}, pos={x0,y0+1*yinc}, size={200,50}, fsize=14
	SetVariable $NMPrefix("FirstGroup"), value=$(df+"FirstGrp"), proc=NMGroupsSetVariable
	
	SetVariable $NMPrefix("GroupWStart"), title="start at wave:", limits={0,nwaves-1,0}, pos={x0,y0+2*yinc}, size={200,50}, fsize=14
	SetVariable $NMPrefix("GroupWStart"), value=$(df+"GrpsFrom"), proc=NMGroupsSetVariable
	
	SetVariable $NMPrefix("GroupWEnd"), title="end at wave:", limits={0,nwaves-1,0}, pos={x0,y0+3*yinc}, size={200,50}, fsize=14
	SetVariable $NMPrefix("GroupWEnd"), value=$(df+"GrpsTo"), proc=NMGroupsSetVariable
	
	SetVariable $NMPrefix("GroupBlocks"), title="in blocks of:", limits={1,inf,0}, pos={x0,y0+4*yinc}, size={200,50}, fsize=14
	SetVariable $NMPrefix("GroupBlocks"), value=$(df+"GrpBlocks"), proc=NMGroupsSetVariable
	
	Button $NMPrefix("GroupSeq"), title="Execute", pos={70,y0+5*yinc}, size={70,20}, proc=NMGroupsButton
	
	CheckBox $NMPrefix("GroupsAutoClear"), title="Auto Clear", pos={160,y0+5*yinc+4}, size={16,18}
	CheckBox $NMPrefix("GroupsAutoClear"), value=0, proc=NMGroupsPanelCheckBox
	
	y0 = 330
	
	Button $NMPrefix("GroupsClear"), title="Clear", pos={70,y0}, size={70,20}, proc=NMGroupsButton
	Button $NMPrefix("GroupsClose"), title="Close", pos={160,y0}, size={70,20}, proc=NMGroupsButton
	
	NMGroupsPanelUpdate()
	
End // NMGroupsPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelUpdate()
	
	String df = NMDF()
	String pname = NMGroupsPanelName()
	
	if (WinType(pname) != 7)
		return -1
	endif
	
	DoWindow /T $pname, "Edit Groups : " + GetDataFolder(0)
	
	CheckBox $NMPrefix("GroupsAutoClear"), win=$pname, value=NumVarOrDefault(df+"GroupsAutoClear", 0)

	NMGroupsPanelDefaults()
	NMGroupsTable(1)

End // NMGroupsPanelUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelDefaults()

	Variable icnt, ngrps=-1, from=-1, to=-1, blocks=-1, first=-1
	String seqStr = "", wName = "Group", df = NMDF()
	
	if (NMNoteExists(wname, "Groups Seq") == 1)
	
		seqStr = NMNoteStrByKey(wName, "Groups Seq")
		seqStr = ChangeListSep(seqStr, ";")
		
		first = 9999
		
		for (icnt = 0; icnt < ItemsInlist(seqStr); icnt += 1)
			first = min(first, str2num(StringFromList(icnt, seqStr)))
		endfor
		
		ngrps = ItemsInList(seqStr)
		from = NMNoteVarByKey(wName, "Groups From")
		to = NMNoteVarByKey(wName, "Groups To")
		blocks = max(1, NMNoteVarByKey(wName, "Group Blocks"))
		
	endif
		
	if ((numtype(ngrps) > 0) || (ngrps < 0))
		ngrps = NumVarOrDefault("NumGrps", 0)
	endif
	
	if ((numtype(first) > 0) || (first < 0))
		first = NMGroupFirstDefault()
	endif
	
	if ((numtype(from) > 0) || (from < 0))
		from = 0
	endif
	
	if ((numtype(to) > 0) || (to < 0))
		to = NumVarOrDefault("NumWaves", 0) - 1
	endif
	
	if ((numtype(blocks) > 0) || (blocks < 0))
		blocks = 1
	endif
	
	SetNMvar(df+"NumGrps", ngrps)
	SetNMvar(df+"FirstGrp", first)
	SetNMvar(df+"GrpsFrom", from)
	SetNMvar(df+"GrpsTo", to)
	SetNMvar(df+"GrpBlocks", blocks)
	
	if (ItemsInlist(seqStr) > 0)
		CheckNMwave("GroupSeq", ngrps, Nan)
		WaveSequence("GroupSeq", seqStr, 0, inf, 1) // NM_Utility.ipf
	else
		NMGroupSeqWave(ngrps, first)
	endif

End // NMGroupsPanelDefaults

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	if (CheckCurrentFolder() == 0)
		return 0
	endif

	NMGroupsCall(NMCtrlName(NMPrefix(""), ctrlName), varStr)
	
	DoWindow /F $NMGroupsPanelName()
	
End // NMGroupsSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsButton(ctrlName) : ButtonControl
	String ctrlName
	
	if (CheckCurrentFolder() == 0)
		return 0
	endif
	
	NMGroupsCall(NMCtrlName(NMPrefix(""), ctrlName), "")
	
	DoWindow /F $NMGroupsPanelName()
	
End // NMGroupsButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	if (CheckCurrentFolder() == 0)
		return 0
	endif
	
	NMGroupsCall(NMCtrlName(NMPrefix(""), ctrlName), num2str(checked))
	
	DoWindow /F $NMGroupsPanelName()

End // NMGroupsPanelCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelSeq()
	
	NMGroupSeqWave(NumVarOrDefault(NMDF()+"NumGrps", 0), NMGroupFirstDefault())
	NMGroupsPanelExecuteAuto()

End // NMGroupsPanelSeq

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelExecuteAuto()

	if (NumVarOrDefault(NMDF()+"GroupsAutoClear", 0) == 1)
		return NMGroupsPanelExecute()
	endif

End // NMGroupsPanelExecuteAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelExecute()
	String df = NMDF()
	
	Variable from = NumVarOrDefault(df+"GrpsFrom", 0)
	Variable to = NumVarOrDefault(df+"GrpsTo", inf)
	Variable blocks = NumVarOrDefault(df+"GrpBlocks", 1)
	
	if (NumVarOrDefault(df+"GroupsAutoClear", 0) == 1)
		NMGroupsClear()
	endif
	
	NMGroupSeqCall(Wave2List("GroupSeq"), from, to, blocks)

End // NMGroupsPanelExecute

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelAutoClear(on)
	Variable on
	
	SetNMvar(NMDF()+"GroupsAutoClear", on)
	
End // NMGroupsPanelAutoClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelClose()

	DoWindow /K $NMGroupsPanelName()
	DoWindow /K $NMGroupsTableName()

End // NMGroupsPanelClose

//****************************************************************
//****************************************************************
//****************************************************************