#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Panel Functions
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last Modified 08 Nov 2005
//
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeNMpanelCall()

	NMCmdHistory("MakeNMpanel","")
	
	return MakeNMpanel()

End // MakeNMpanelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function MakeNMpanel()
	
	Variable x1, y1, x2, y2, lineheight = 100
	Variable pw = 300, ph = 640
	
	String df = NMDF()
	String tabList = NMTabListGet()
	
	Variable xPixels = NumVarOrDefault(df+"xPixels", 1000)
	
	CheckCurrentFolder()
	
	x1 = xPixels - pw - 10
	y1 = 43
	x2 = x1 + pw
	y2 = y1 + ph
	
	DoWindow /K NMpanel
	NewPanel /K=1/W=(x1, y1, x2, y2)
	DoWindow /C NMpanel
	
	SetWindow NMpanel, hook=NMPanelHook
	
	ModifyPanel cbRGB = (43690,43690,43690) // set background color
	
	PopupMenu NM_FolderMenu, title="F", pos={40,6}, size={0,0}, bodyWidth=20, help={"data folders"}
	PopupMenu NM_FolderMenu, mode=1, value = "", proc=NMPopupFolder
	
	PopupMenu NM_PrefixMenu, pos={195,6}, size={0,0}, bodyWidth=140, help={"wave prefix select"}
	PopupMenu NM_PrefixMenu, mode=1, value="Prefix", proc=NMPopupPrefix
	
	PopupMenu NM_SetsMenu, pos={285,6}, size={0,0}, bodyWidth=75, proc=NMPopupSets, help={"Set functions"}
	PopupMenu NM_SetsMenu, value = "Sets ;---;Define;Equation;Invert;Clear;0 > Nan;Nan > 0;---;New;Copy;Rename;Kill;---;Table;Panel;---;Exclude SetX?;Auto Advance;Display;"
	
	//Button NM_SetsEdit, title="Sets", pos={210,6}, size={75,20}, proc=NMButton, help={"Sets panel"}
	
	PopupMenu NM_GroupMenu, title="G", pos={40,35}, size={0,0}, bodyWidth=20, proc=NMPopupGroups, help={"Groups"}
	PopupMenu NM_GroupMenu, mode=1, value = "Groups;---;Define;Clear;Table;Panel;On/Off;"
	
	SetVariable NM_SetWaveNum, title= " ", pos={70,36}, size={50,50}, limits={0,inf,0}, value=CurrentWave
	SetVariable NM_SetWaveNum, frame=1, fsize=12, proc=NMSetVariable, help={"current wave number"}
	
	SetVariable NM_SetGrpNum, title="Grp", pos={125,36}, size={55,50}, limits={0,inf,0}, value=CurrentGrp
	SetVariable NM_SetGrpNum, frame=1, fsize=12, proc=NMSetVariable, help={"current group number"}
	
	Button NM_JumpBck, title="<", pos={70,64}, size={20,20}, proc=NMButton, help={"jump backward"}
	Button NM_JumpFwd, title=">", pos={160,64}, size={20,20}, proc=NMButton, help={"jump forward"}
	
	Slider NM_WaveSlide, pos={95,64}, size={60,50}, limits={0,0,1}, vert=0, side=2, ticks=0, variable = CurrentWave, proc=NMWaveSlide
	
	PopupMenu NM_SkipMenu, title="+", pos={40,64}, size={0,0}, bodyWidth=20, help={"wave increment value"}, proc=NMPopupSkip
	PopupMenu NM_SkipMenu, mode=1, value=" ;Wave Increment = 1;Wave Increment > 1;As Wave Select;", fsize=14
	
	CheckBox NM_Set1Check, title="Set1", pos={215,34}, size={16,18}, value=0, proc=NMSetsCheckBox, help={"include in Set1"}
	CheckBox NM_Set2Check, title="Set2", pos={215,52}, size={16,18}, value=0, proc=NMSetsCheckBox, help={"include in Set2"}
	CheckBox NM_SetXCheck, title="SetX", pos={215,70}, size={16,18}, value=0, proc=NMSetsCheckBox, help={"exclude from all analyses"}
	
	SetVariable NM_Set1Cnt, title=":", pos={260,34}, size={45,50}, limits={0,inf,0}, help={"number of Set1 waves"}
	SetVariable NM_Set1Cnt, value=SumSet1, frame=0, noedit=1, help={"number of Set1 waves"}
	
	SetVariable NM_Set2Cnt, title=":", pos={260,52}, size={45,50}, limits={0,inf,0}, help={"number of Set2 waves"}
	SetVariable NM_Set2Cnt, value=SumSet2, frame=0, noedit=1, help={"number of Set2 waves"}
	
	SetVariable NM_SetXCnt, title=":", pos={260,70}, size={45,50}, limits={0,inf,0}, help={"number of SetX waves"}
	SetVariable NM_SetXCnt, value=SumSetX, frame=0, noedit=1, help={"number of SetX waves"}
	
	CheckBox NM_WriteCheck, title="OverWrite Mode", pos={20,615}, size={16,18}, value=NumVarOrDefault(df+"OverWrite", 1)
	CheckBox NM_WriteCheck, proc=NMOverWriteCheckBox, help={"overwrite waves and graphs"}
	
	SetDrawLayer UserBack
	SetDrawEnv dash=3, linefgc= (0,0,26112)
	DrawLine 1,lineheight,100,lineheight
	
	SetDrawEnv textrgb= (0,0,26112)
	SetDrawEnv fsize= 12
	DrawText 116,lineheight+7,"Wave Select"
	SetDrawEnv dash=3, linefgc= (0,0,26112)
	DrawLine 200,lineheight,pw,lineheight
	
	SetDrawEnv textrgb= (0,0,26112)
	SetDrawEnv fsize= 12
	DrawText 188,631,"NeuroMatic v1.91"
	
	PopupMenu NM_ChanMenu, title="Chan", pos={35,115}, bodywidth=45, value="A;", mode=1, proc=NMPopupChan, help={"limit channels to analyze"}
	PopupMenu NM_WaveMenu, title="Waves", value ="All", mode=1, pos={205,115}, bodywidth=115, proc=NMPopupWaveSelect, help={"limit waves to analyze"}
	SetVariable NM_WaveCount, title=":", pos={260,117}, size={45,50}, limits={0,inf,0}, value=NumActiveWaves
	SetVariable NM_WaveCount, frame=0, noedit=1, help={"number of currently selected waves"}
	
	TabControl NM_Tab, win=NMpanel, pos={0,150}, size={pw,ph}, proc=NMTabControl // position the tab control
	
	NMTabsMake(1)
	
	UpdateNMPanel(1)
	
	return 0
	
End // MakeNMpanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPanelHook(infoStr)
	string infoStr
	
	string event= StringByKey("EVENT",infoStr)
	string win= StringByKey("WINDOW",infoStr)
	
	if (StringMatch(win, "NMpanel") == 0)
		return 0 // wrong window
	endif
	
	if (StringMatch(event, "activate") == 1)
		CheckCurrentFolder()
		//CheckNMFolderList()
	endif

End // NMPanelHook

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanel(updateTab)
	Variable updateTab

	if (WinType("NMpanel") == 0)
		return 0
	endif
	
	UpdateNMPanelTitle()
	UpdateNMFolderMenu()
	UpdateNMSetVar()
	UpdateNMPrefixMenu()
	UpdateNMChanSelect()
	UpdateNMWaveSelect()
	UpdateNMSetsCount()
	
	if (updateTab == 1)
		UpdateNMTab()
	endif
	
	NMSetsPanelSelect("") // update Sets panel
	NMGroupsPanelUpdate() // new Groups panel

End // UpdateNMPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function /S UpdateNMPanelTitle()
	String title, stim

	if (IsNMDataFolder("") == 0)
	
		title = "Not a NeuroMatic Data Folder"
		
	else
	
		title = NMFolderListName("") + " : " + GetDataFolder(0)
		stim = SubStimName("")
		
		if (strlen(stim) > 0)
			title += " : " + stim
		endif
	
	endif
	
	if (WinType("NMpanel") == 7)
		DoWindow /T NMpanel, title
	endif

End // UpdateNMPanelTitle

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMSetVar()

	Variable currentWave = NumVarOrDefault("CurrentWave", 0)
	Variable groupsOn = NumVarOrDefault(NMDF()+"GroupsOn", 1)
	Variable numGrps = NumVarOrDefault("NumGrps",0)
	Variable currentGrp = NumVarOrDefault("CurrentGrp",0)
	
	if (groupsOn == 1)
		SetVariable NM_SetWaveNum, win=NMpanel, value=currentWave, pos={70,36}
		SetVariable NM_SetGrpNum, win=NMpanel, value=currentGrp, disable = 0, limits={0,numGrps,0}
	else
		SetVariable NM_SetWaveNum, win=NMpanel, value=CurrentWave, pos={100,36}
		SetVariable NM_SetGrpNum, win=NMpanel, value=currentGrp, disable = 1
	endif
	
	SetVariable NM_Set1Cnt, win=NMpanel, value=SumSet1
	SetVariable NM_Set2Cnt, win=NMpanel, value=SumSet2
	SetVariable NM_SetXCnt, win=NMpanel, value=SumSetX
	SetVariable NM_WaveCount, win=NMpanel, value=NumActiveWaves
	
	Slider NM_WaveSlide, win=NMpanel, variable = CurrentWave, limits={0,NumVarOrDefault("NumWaves",1)-1,1}

End // UpdateNMSetVar

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMChanSelect()
	Variable cmode, csum
	String cselect, cmenu = "A;"
	
	if (WaveExists(ChanSelect) == 0)
		return 0
	endif

	Variable numChannels = NumVarOrDefault("NumChannels", 0)
	Variable currentChan = NumVarOrDefault("CurrentChan", 0)
	
	Wave ChanSelect
	
	csum = sum(ChanSelect, -inf, inf)
	
	if ((csum == 0) || (ChanSelect[currentChan] == 0))
		currentChan = 0 // something wrong, select channel A
		SetNMwave("ChanSelect", 0, 1)
		SetNMvar("CurrentChan", 0)
	endif
	
	cselect = ChanNum2Char(currentChan)

	if (numChannels > 1)
	
		cmenu = "All;" + ChanCharList(numChannels, ";")
		
		if (csum == numChannels)
			cselect = "All"
		endif
		
	endif
	
	cmode = 1+ WhichListItem(cselect, cmenu)
	
	Execute /Z "PopupMenu NM_ChanMenu, win=NMpanel, mode=" + num2str(cmode) + ", value =\"" + cmenu + "\""

End // UpdateNMChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMWaveSelect()

	String wmenu = UpdateNMWaveSelectStr()
	String slist = StrVarOrDefault("WavSelectList", "")
	String wselect = NMWaveSelectGet()
	
	Variable modenum = WhichListItemLax(wselect, wmenu, ";")

	if (modenum == -1) // not in list
		slist = AddListItem(wselect,slist, ";", inf) // add to list
		SetNMstr("WavSelectList", slist)
		wmenu = UpdateNMWaveSelectStr()
		modenum = WhichListItemLax(wselect, wmenu, ";")
	endif
	
	PopupMenu NM_WaveMenu, win=NMpanel, mode=(modenum+1), value=UpdateNMWaveSelectStr()

End // UpdateNMWaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S UpdateNMWaveSelectStr()

	String wmenu = NMWaveSelectDefaults()
	String wlist = StrVarOrDefault("WavSelectList", "")
	
	wlist = RemoveListFromList(wmenu, wlist, ";")
	
	wmenu += wlist
	
	if (NumVarOrDefault(NMDF()+"GroupsOn", 1) == 1)
		wmenu += "---;Set x Group;Other...;Clear List;"
	else
		wmenu += "---;Other...;Clear List;"
	endif
	
	return wmenu

End // UpdateNMWaveSelectStr

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMFolderMenu()

	if (WinType("NMpanel") == 0)
		return 0
	endif
	
	String item = NMFolderListName("") + " : " + GetDataFolder(0)
	
	Variable md = max(1, 1 + WhichListItem(item, UpdateNMFolderMenuStr()))

	PopupMenu NM_FolderMenu, win=NMpanel, mode=md, value=UpdateNMFolderMenuStr()

End // UpdateNMFolderMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S UpdateNMFolderMenuStr()

	String txt = "---;New;Open;Open | Append;Save;Close;Duplicate;Rename;Merge;---;Open All;Append All;Save All;Close All;---;Import Waves;Reload Waves;Rename Waves;"
	
	String folderList = NMDataFolderListLong()
	
	String logList = NMLogFolderListLong()
	
	if (strlen(folderList) > 0)
		
		folderList = "---;" + folderList
	
	endif
	
	if (strlen(logList) > 0)
		
		logList = "---;" + logList
	
	endif

	return "Folders;" + folderList + logList  + txt

End // UpdateNMFolderMenuStr

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPrefixMenu()
	String df = NMDF()
	
	if (WinType("NMpanel") == 0)
		return 0
	endif
	
	String cPrefix = StrVarOrDefault("CurrentPrefix", "")
	String dList = StrVarOrDefault(df+"PrefixList", "Record;Avg_;ST_;")
	String uList = StrVarOrDefault(df+"UserPrefixList", "")
	
	if ((strlen(cPrefix) > 0) && (WhichListItemLax(cPrefix, dList+uList, ";") == -1))
		uList = AddListItem(cPrefix, uList, ";", inf) // add prefix to list
		SetNMstr(df+"UserPrefixList", uList)
	endif
	
	PopupMenu NM_PrefixMenu, win=NMpanel, mode=1, value=NMPrefixMenuStr(), popvalue=StrVarOrDefault("CurrentPrefix", "")

End // UpdateNMPrefixMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixMenuStr()
	String df = NMDF()
	String dList = StrVarOrDefault(df+"PrefixList", "Record;Avg_;ST_;")
	String uList = StrVarOrDefault(df+"UserPrefixList", "")

	return "Wave Prefix;---;" + dList + uList + ";---;Add to List;Remove from List;Clear List;Prompt On/Off;"

End // NMPrefixMenuStr

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMSets(recount) // udpate Sets display
	Variable recount

	if (WaveExists(Set1) == 0)
		return 0
	endif

	Variable wNum = NumVarOrDefault("CurrentWave", 0)
	
	String s1 = NMSetsDisplayName(0)
	String s2 = NMSetsDisplayName(1)
	String s3 = NMSetsDisplayName(2)
	
	Wave Set1 = $s1
	Wave Set2 = $s2
	Wave Set3 = $s3
	
	CheckBox NM_Set1Check, title=s1, win=NMpanel, value=BinaryCheck(Set1[wNum])
	CheckBox NM_Set2Check, title=s2, win=NMpanel, value=BinaryCheck(Set2[wNum])
	CheckBox NM_SetXCheck, title=s3, win=NMpanel, value=BinaryCheck(Set3[wNum])
	
	if (recount == 1)
		UpdateNMSetsCount()
	endif

End // UpdateNMSets

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMSetsCount() // udpate Sets count display
	Variable sumvar

	if (WaveExists(Set1) == 0)
		return 0
	endif
	
	String s1 = NMSetsDisplayName(0)
	String s2 = NMSetsDisplayName(1)
	String s3 = NMSetsDisplayName(2)
	
	sumvar = sum($s1)
	
	if (numtype(sumvar) == 0)
		SetNMvar("SumSet1", sumvar)
	else
		SetNMvar("SumSet1", WaveCountOnes(s1))
	endif
	
	sumvar = sum($s2)
	
	if (numtype(sumvar) == 0)
		SetNMvar("SumSet2", sumvar)
	else
		SetNMvar("SumSet2", WaveCountOnes(s2))
	endif
	
	sumvar = sum($s3)
	
	if (numtype(sumvar) == 0)
		SetNMvar("SumSetX", sumvar)
	else
		SetNMvar("SumSetX", WaveCountOnes(s3))
	endif
	
	NMWaveSelectCount() // update Wave Select count display

End // UpdateNMSetsCount

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMTab()

	String df = NMDF()
	Variable thisTab = NumVarOrDefault(df+"CurrentTab", 0)
	
	NMTabsMake(0) // checks if tablist has changed
	
	ChangeTab(thisTab, thisTab, NMTabListGet())

End // UpdateNMTab

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupFolder(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	Variable found
	
	PopupMenu NM_FolderMenu, win=NMpanel, mode=1
	
	strswitch(popStr)
	
		case "Folders":
		case "---":
			break
			
		case "New":
		case "Open":
		case "Save":
		case "Close":
		case "Kill":
		case "Duplicate":
		case "Rename":
		case "Append":
		case "Open | Append":
		case "Merge":
		case "Import Waves":
		case "Reload Waves":
		case "Rename Waves":
		case "Open All":
		case "Append All":
		case "Save All":
		case "Kill All":
		case "Close All":
			NMFolderCall(popStr)
			break
			
		default:
		
			found = strsearch(popstr, " : ", 0)
		
			if (found >= 0)
				popstr = popstr[found+3,inf]
			endif
		
			if (StringMatch(popstr, GetDataFolder(0)) == 0)
				NMCmdHistory("NMFolderChange", NMCmdStr(popStr,""))
				NMFolderChange(popStr)
			endif
			
			break
			
	endswitch
	
	UpdateNMFolderMenu()
	CheckNMFolderList()
	
	DoWindow /F NMpanel
	
End // NMPopupFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupPrefix(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	if (NMPrefixCall(popStr) == -1)
		UpdateNMPrefixMenu()
	endif
	
	DoWindow /F NMpanel

End // NMPopupPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupGroups(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_GroupMenu, win=NMpanel, mode=1
	
	if (NumVarOrDefault("NumWaves", 0) == 0)
		DoAlert 0, "Data waves have not been selected for this folder."
		return 0
	endif
	
	NMGroupsCall(popStr, "")
	
End // NMPopupGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupSets(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_SetsMenu, win=NMpanel, mode=1
	
	if (NumVarOrDefault("NumWaves", 0) == 0)
		DoAlert 0, "Data waves have not been selected for this folder."
		return 0
	endif
	
	NMSetsCall(popStr, "")
	
End // NMPopupSets

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupSkip(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_SkipMenu, win=NMpanel, mode=1
	
	NMWaveIncCall(popStr)

End // NMPopupSkip

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupChan(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	NMChanSelectCall(popStr)
	
	DoWindow /F NMpanel
	
End // NMPopupChan

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupWaveSelect(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	NMWaveSelectCall(popStr)

End // NMPopupWaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMButton(ctrlName) : ButtonControl
	String ctrlName
	
	strswitch(ctrlName[3,inf])
	
		case "JumpFwd":
			NMNextWave(+1)
			break
			
		case "JumpBck":
			NMNextWave(-1)
			break
			
		case "SetsEdit":
			return NMSetsPanelCall()
			
	endswitch
	
	DoWindow /F NMpanel
	
End // NMButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	strswitch(ctrlName)
	
		case "NM_SetWaveNum":
			return NMCurrentWaveCall(varNum)
			
		case "NM_SetGrpNum":
			return NMGroupAssignCall(varNum)
			
	endswitch
	
End // NMSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	NMSetsCall(ctrlName[3,inf], num2str(checked))
	
	DoWindow /F NMPanel

End // NMSetsCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOverWriteCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked

	NMCmdHistory("NMOverWriteOn", NMCmdNum(checked,""))
	
	NMOverWriteOn(checked)

End // NMOverWriteCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSlide(ctrlName, value, event) // SlideVariable Control
	String ctrlName
	Variable value // slider value
	Variable event // event - bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	
	if (event == 4)
		UpdateCurrentWave()
	endif

End // NMWaveSlide

//****************************************************************
//****************************************************************
//****************************************************************
//
//		NeuroMatic Tab Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabControl(name, tab) // called when user clicks on NMpanel tab
	String name; Variable tab
	
	name = TabName(tab, NMTabListGet())
	
	NMCmdHistory("NMTab", NMCmdStr(name,""))
	
	NMTab(name)

End // NMTabControl

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabsMake(force)
	Variable force // (0) check (1) make

	Variable icnt, tnum
	String tname, df = NMDF()
	
	String cList = StrVarOrDefault(df+"CurrentNMTabList", "")
	String tabList =  StrVarOrDefault(df+"TabList", "")
	String newList =  StrVarOrDefault(df+"NMTabList", "")
	
	if ((force == 1) || (StringMatch(cList, newList) == 0))
	
		for (icnt = 0; icnt < ItemsInList(cList); icnt += 1)
		
			tname = StringFromList(icnt, cList)
			
			if (WhichListItemLax(tname, newList, ";") < 0)
				tnum = WhichListItemLax(tname, cList, ";")
				KillTabControls(tnum, tabList)
			endif
			
		endfor
		
		ClearTabs(tabList) // clear old tabs
		SetNMstr(df+"TabList", "") // clear old list
		MakeTabs(NMTabListGet()) // update tabs
		CheckNMTabs(1)
		
	endif
	
End // NMTabsMake

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabListGet()
	String df = NMDF()
	
	Variable icnt
	String tname, prefix
	
	String tabList = StrVarOrDefault(df+"TabList", "")
	String newList =  StrVarOrDefault(df+"NMTabList", "")
	String newList2 = NMTabListConvert(tabList)
	
	String win = TabWinName(tabList)
	String tab = TabCntrlName(tabList)
	
	if ((StringMatch(win, "NMPanel") == 1) && (StringMatch(tab, "NM_Tab") == 1))
		
		if (StringMatch(newList, newList2) == 0)
			SetNMstr(df+"NMTabList", newList2)
		endif
		
		return tabList // OK format
		
	endif
	
	tabList = ""
	
	for (icnt = 0; icnt < ItemsInList(newList); icnt += 1)
	
		tname = StringFromList(icnt, newList)
		prefix = NMTabPrefix(tname)
		
		if (strlen(prefix) > 0)
			tabList = AddListItem(tname + "," + prefix, tabList, ";", inf)
		else
			DoAlert 0, "NM Tab Entry Failure : " + tname
		endif
		
	endfor
	
	tabList = AddListItem("NMPanel,NM_Tab", tabList, ";", inf)
	
	SetNMstr(df+"TabList", tabList)
	SetNMstr(df+"CurrentNMTabList", newList)

	return tabList

End // NMTabListGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabPrefix(tabName)
	String tabName
	
	String df = NMDF()
	String prefix = StrVarOrDefault(df+tabName+"Prefix", "")
	
	// tab prefix string should reside in NMDF()
	// i.e. for Stats tab, StatsPrefix = "ST_"
	
	if (strlen(prefix) > 0)
		return prefix
	endif
	
	// attemp to create tab prefix name by calling new function (i.e. StatsPrefix())
	
	Execute /Z "SetNMstr(\"" + df + tabName + "Prefix\", " + tabName + "Prefix(\"\"))"
		
	return StrVarOrDefault(df+tabName+"Prefix", "")

End // NMTabPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabListConvert(tabList)
	String tabList // ('') for current
	Variable icnt
	
	String newList = "", df = NMDF()
	
	if (strlen(tabList) == 0)
		tabList = StrVarOrDefault(df+"TabList", "")
	endif
	
	for (icnt = 0; icnt < ItemsInList(tabList)-1; icnt += 1)
		newList = AddListItem(TabName(icnt, tabList), newList, ";", inf)
	endfor
	
	return newList
	
End // NMTabListConvert

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMTabs(force)
	Variable force
	Variable icnt
	
	String tList = NMTabListGet(), df = NMDF()
	
	for (icnt = 0; icnt < NumTabs(tList); icnt += 1) // go through each tab and check variables
		SetNMvar(df+"UpdateNMBlock", 1) // block UpdateNM()
		CheckPackage(TabName(icnt, tList), force)
		SetNMvar(df+"UpdateNMBlock", 0) // unblock UpdateNM()
	endfor

End // CheckNMTabs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAutoTabCall()

	String df = NMDF()
	String TabList = NMTabListGet()
	
	Variable thisTab = NumVarOrDefault(df+"CurrentTab", 0)

	Variable error = CallTabFunction("Auto", thisTab, TabList)
	
	if (error != 0) // error occurred. try another tab function
		CallTabFunction("NMAuto", thisTab, TabList)
	endif

End // NMAutoTabCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTab(tName) // change NMpanel tab
	String tName // tab name
	
	String df = NMDF()
	String tabList = NMTabListGet()
	
	Variable tab = TabNumber(tName, tabList) // NM_TabManager.ipf
	
	if (tab < 0)
		return -1
	endif
	
	Variable lastTab = NumVarOrDefault(df+"CurrentTab", 0)
	
	if (tab != lastTab)
		SetNMvar(df+"CurrentTab", tab)
		ChangeTab(lastTab, tab, tabList) // NM_TabManager.ipf
		ChanGraphsUpdate(0)
	endif

End // NMTab

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabCurrent() // returns name of current tab

	String df = NMDF()

	Variable tab = NumVarOrDefault(df+"CurrentTab", 0)
	String tlist = NMTabListGet()

	return TabName(tab, tlist)

End // NMTabCurrent()

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabKillCall()

	String tlist = NMTabListGet()
	
	if (strlen(tlist) == 0)
		return -1
	endif
	
	String tabName
	Prompt tabName, "choose tab:", popup TabNameList(tlist)
	DoPrompt "Kill Tab", tabName
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	NMCmdHistory("NMTabKill", NMCmdStr(tabName,""))
	
	return NMTabKill(tabName)

End // NMTabKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabKill(tabName)
	String tabName

	String tlist = NMTabListGet()
	
	Variable tabnum = TabNumber(tabName, tlist)
	String prefix = TabPrefix(tabnum, tlist) + "*"
	
	if (tabnum == -1)
		return -1
	endif
	
	KillTab(tabnum, tlist, 1)
	
	Execute /Z "Kill" + tabName + "(\"globals\")" // execute user-defined kill function, if it exists
	
	DoAlert 1, "Kill \"" + tabName + "\" controls?"
	
	if (V_Flag == 1)
		KillControls(TabWinName(tlist), prefix) // kill controls
	endif
	
	return 0

End // NMTabKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabAddCall()

	String vlist = "", tabName = "", newName = "", tabprefix = ""

	Prompt tabName, "choose tab to add:", popup NMTabsAvailable()
	Prompt newName, "or enter new tab name (e.g. \"Stats\"):"
	Prompt tabprefix, "and the tab's prefix signature (e.g. \"ST_\"):"
	DoPrompt "Add Tab", tabName, newName, tabprefix
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	if ((strlen(newName) > 0) && (strlen(tabprefix) > 0))
	
		tabName = newName
		
		// save prefix string to NMDF()
		// before calling NMTabAdd
		
		SetNMstr(NMDF()+newName+"Prefix", tabprefix) 
		
	elseif (StringMatch(tabName, " ") == 0)
	
		tabprefix = "" // auto-detected
		
	endif
	
	vlist = NMCmdStr(tabName, vlist)
	vlist = NMCmdStr(tabprefix, vlist)
	NMCmdHistory("NMTabAdd", vlist)
	
	return NMTabAdd(tabName, tabprefix)

End // NMTabAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function AddNMTab(tabName) // called from old Preference files
	String tabName
	
	String tabprefix = NMTabPrefix(tabname)
	
	Variable ilast
	String tempstr, templist, item, df = NMDF()
	
	if ((strlen(tabname) == 0) || (strlen(tabprefix) == 0))
		return -1
	endif
	
	String TabList = StrVarOrDefault(df+"TabList", "Main,MN_;NMpanel,NM_Tab;")
	
	item = tabname + "," + tabprefix
	
	if (WhichListItemLax(item, TabList, ";") == -1)
		
		ilast = ItemsInList(TabList, ";") - 1
		tempstr = StringFromList(ilast, TabList, ";")
		templist = RemoveListItem(ilast, TabList, ";")
		templist = AddListItem(item, templist, ";",inf)
		templist = AddListItem(tempstr, templist, ";", inf)
		
		SetNMstr(df+"TabList", templist)
	
	endif
	
	return 0

End // AddNMTab

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabAdd(tabName, tabprefix)
	String tabName, tabprefix
	
	String df = NMDF(), tabList = StrVarOrDefault(df+"NMTabList", "")
	
	if (strlen(tabprefix) == 0)
		tabprefix = NMTabPrefix(tabName)
	endif
	
	if ((strlen(tabName) == 0) || (strlen(tabprefix) == 0))
		return -1
	endif
	
	if (WhichListItemLax(tabName, tabList, ";") == -1)
		
		tabList = AddListItem(tabName, tabList, ";", inf)
		SetNMstr(df+"NMTabList", tabList)
		UpdateNMTab()
	
	endif
	
	return 0

End // NMTabAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabRemoveCall()
	String df = NMDF()
	String tlist = NMTabListGet()
	
	if (StringMatch(tlist, "") == 1)
		return -1
	endif

	String tabName
	Prompt tabName, "choose tab:", popup TabNameList(tlist)
	DoPrompt "Kill Tab", tabName
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	NMCmdHistory("NMTabRemove", NMCmdStr(tabName,""))
	
	return NMTabRemove(tabName)

End // NMTabRemoveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabRemove(tabName)
	String tabName
	
	String df = NMDF(), tabList = StrVarOrDefault(df+"NMTabList", "")
	
	if ((strlen(tabName) == 0) || (strlen(tabList) == 0))
		return -1
	endif
	
	Variable tabnum = WhichListItemLax(tabName, tabList, ";")
	
	if (tabnum < 0)
		return -1
	elseif (tabnum == NumVarOrDefault(df+"CurrentTab", 0))
		SetNMvar(df+"CurrentTab", 0)
	endif
	
	tabList = RemoveListItem(tabnum, tabList, ";")
	SetNMstr(df+"NMTabList", tabList)
	UpdateNMPanel(1)
	
	return 0
	
End // NMTabRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabsAvailable()
	Variable icnt
	String tname, aList = ""

	String tabList = "Main;Stats;Spike;Event;Clamp;MyTab;RiseT;PairP;MPFA;Art;"
	
	for (icnt = 0; icnt < ItemsInList(tabList); icnt += 1)
	
		tname = StringFromList(icnt, tabList)
		
		if (exists(tname) == 6)
			aList = AddListItem(tname, aList, ";", inf)
		endif
		
	endfor
	
	return aList

End // NMTabsAvailable

//****************************************************************
//****************************************************************
//****************************************************************

Function IsCurrentNMTab(tName)
	String tName
	
	String df = NMDF()
	
	String tlist = NMTabListGet()
	String ctab = TabName(NumVarOrDefault(df+"CurrentTab",0), tList)
	
	if (StringMatch(tName, ctab) == 1)
		return 1
	else
		return 0
	endif
	
End // IsCurrentNMTab

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave Number Select/Increment Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentWaveCall(waveNum)
	Variable waveNum
	
	NMCmdHistory("NMCurrentWave", NMCmdNum(waveNum,""))
	
	return NMCurrentWave(waveNum)
	
End // NMCurrentWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentWave(waveNum)
	Variable waveNum
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	
	if (waveNum < 0)
		waveNum = 0
	elseif (waveNum >= nwaves)
		waveNum = nwaves - 1
	endif
	
	SetNMvar("CurrentWave", waveNum)
	UpdateCurrentWave()
	
	return waveNum
	
End // NMCurrentWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNextWaveCall(direction)
	Variable direction
	
	NMCmdHistory("NMNextWave", NMCmdNum(direction,""))
	
	return NMNextWave(direction)
	
End // NMNextWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNextWave(direction) // set next wave number
	Variable direction
	
	Variable next, found = -1
	String df = NMDF()

	NVAR CurrentWave, NumWaves, WaveSkip
	
	if (NumWaves == 0)
		DoAlert 0, "No waves to display."
		return -1
	endif
	
	if (WaveSkip < 0)
		WaveSkip = 1
	endif

	if (WaveSkip > 0)
	
		next = CurrentWave + direction*WaveSkip
		
		if ((next >= 0) && (next < NumWaves))
			found = next
		endif
		
	elseif (WaveSkip == 0)
	
		found = NextWaveItem("WavSelect", 1, CurrentWave, direction) // NM_Utility.ipf
		
	endif

	if ((found >= 0) && (found != CurrentWave))
		CurrentWave = found
		UpdateCurrentWave()
		ChanGraphsToFront()
	endif
	
	return found

End // NMNextWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveIncCall(select)
	String select

	Variable inc = 1
	
	strswitch(select) // set appropriate WaveSkip flag
	
		case "Wave Increment = 1":
			break
			
		case "Wave Increment > 1":
			inc = 2
				
			Prompt inc, "set wave increment to:"
			DoPrompt "Change Wave Increment", inc // call for user input
				
			if (V_flag == 1)
				return 0
			endif
				
			if (inc < 1)
				inc = 1
			endif
			
			break
			
		case "As Wave Select":
			inc = 0
			break
			
		default:
			return 0

	endswitch
	
	NMCmdHistory("NMWaveInc", NMCmdNum(inc, ""))
	
	return NMWaveInc(inc)

End // NMWaveIncCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveInc(value)
	Variable value // increment value or (0) for "As Wave Select"
	
	if ((numtype(value) > 0) || (value < 0))
		value = 1
	endif
	
	SetNMvar("WaveSkip", value)
	
	return value
	
End // NMWaveInc

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Prefix Select Functions (i.e. "Record")
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixCall(fxn)
	String fxn
	
	strswitch(fxn)
	
		case "Wave Prefix":
		case "---":
			return UpdateNMPrefixMenu()
			
		case "Add to List":
			return NMPrefixAddCall()
			
		case "Clear List":
			return NMPrefixListClearCall()
			
		case "Remove from List":
			return NMPrefixRemoveCall()
			
		case "Prompt On/Off":
			return NMPrefixPromptCall()
		
		default:
			return NMPrefixSelectCall(fxn)
			
	endswitch

End // NMPrefixCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixPromptCall()

	String df = NMDF()

	Variable pp = 1 + NumVarOrDefault(df+"ChangePrefixPrompt", 1)
	Prompt pp, "Prompt for number of channels and waves upon changing prefix?", popup "no;yes"
	DoPrompt "Change Prefix Prompt On/Off", pp
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	pp -= 1
	
	NMCmdHistory("NMPrefixPrompt", NMCmdNum(pp,""))
	
	return NMPrefixPrompt(pp)

End // NMPrefixPromptCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixPrompt(on)
	Variable on // (0) no (1) yes
	
	SetNMvar(NMDF()+"ChangePrefixPrompt", on)
	
	return on
	
End // NMPrefixPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixAddCall()
	String getprefix
	
	Prompt getprefix, "enter prefix string:"
	DoPrompt "Add Wave Prefix", getprefix
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	NMCmdHistory("NMPrefixAdd", NMCmdStr(getprefix,""))
	
	return NMPrefixAdd(getprefix)

End // NMPrefixAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixAdd(addList) // add prefix name to NM PrefixList
	String addList // prefix list
	String df = NMDF()
	
	Variable icnt
	String prefix
	
	if (strlen(addList) == 0)
		return -1
	endif
	
	String dList = StrVarOrDefault(df+"PrefixList", "Record;Avg_;ST_;")
	String uList = StrVarOrDefault(df+"UserPrefixList", "")
	
	for (icnt = 0; icnt < ItemsInlist(addList); icnt += 1)
	
		prefix = StringFromList(icnt, addList)
	
		if (WhichListItemLax(prefix, dList+uList, ";") == -1)
			uList = AddListItem(prefix, uList, ";", inf)
		endif
		
	endfor
	
	SetNMstr(df+"UserPrefixList", uList)
	UpdateNMPrefixMenu()
	
	return 0

End // NMPrefixAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixRemoveCall()

	String df = NMDF()
	String uList = StrVarOrDefault(df+"UserPrefixList", "")
	String CurrentPrefix = StrVarOrDefault("CurrentPrefix", StrVarOrDefault("WavePrefix", ""))

	String getprefix = RemoveFromList(CurrentPrefix, uList)
	Prompt getprefix, "remove:", popup getprefix
	DoPrompt "Remove Wave Prefix", getprefix
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	NMCmdHistory("NMPrefixRemove", NMCmdStr(getprefix,""))
	
	return NMPrefixRemove(getprefix)

End // NMPrefixRemoveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixRemove(removeList) // add prefix name to NM PrefixList
	String removeList // prefix list
	
	String df = NMDF()
	
	if (strlen(removeList) == 0)
		return -1
	endif
	
	String pList = StrVarOrDefault(df+"UserPrefixList", "")
	
	pList = RemoveListFromList(removeList, pList, ";")
	
	SetNMstr(df+"UserPrefixList", pList)
	UpdateNMPrefixMenu()
	
	return 0

End // NMPrefixRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixListClearCall()

	NMCmdHistory("NMPrefixListClear", "")
	
	return NMPrefixListClear()

End // NMPrefixListClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixListClear()
	String df = NMDF()

	SetNMstr(df+"UserPrefixList", "")
	UpdateNMPrefixMenu()
	
	return 0

End // NMPrefixListClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSelectCall(prefix)
	String prefix
	
	NMCmdHistory("NMPrefixSelect", NMCmdStr(prefix,""))
	
	return NMPrefixSelect(prefix)

End // NMPrefixSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSelectSilent(prefix)
	String prefix
	String df = NMDF()
	
	Variable savePrompt = NumVarOrDefault(df+"ChangePrefixPrompt", 1)
	
	SetNMvar(df+"ChangePrefixPrompt", 0)
	NMPrefixSelect(prefix)
	SetNMvar(df+"ChangePrefixPrompt", savePrompt)

End // NMPrefixSelectSilent

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSelect(prefix) // change to a new wave prefix
	String prefix // wave prefix name, or ("") for current prefix
	
	Variable ccnt, nchan, found, nmax, prmt, nwaves
	String wlist, df = NMDF()
	
	String opstr = WaveListText0()
			
	NVAR NumWaves, NumChannels, CurrentWave, WaveSkip
	
	String currentPrefix = StrVarOrDefault("CurrentPrefix", StrVarOrDefault("WavePrefix", ""))
	
	if (strlen(prefix) == 0)
		prefix = currentPrefix
	endif
	
	wlist = WaveList(prefix + "*", ";", opstr)
	nwaves = ItemsInList(wlist)

	if (nwaves == 0)
		DoAlert 0, "NMPrefixSelect Abort: no waves detected with prefix \"" + prefix + "\""
		return -1
	endif
	
	Variable oldnchan = NumVarOrDefault(GetDataFolder(1)+prefix+":NumChannels", -1)
	
	for (ccnt = 0; ccnt < 10; ccnt += 1) // detect multiple channels (up to 10)
	
		//wlist = WaveList(prefix + "*" + ChanNum2Char(ccnt) + "*", ";", opstr)
		wlist = ChanWaveListSearch(prefix, ccnt)
		
		if (ItemsInList(wlist) > 0)
		
			nchan += 1
			found = ItemsInList(wlist)
			
			if (found > nmax)
				nmax = found
			endif
			
		endif
		
	endfor
	
	if (nchan <= 0)
		nchan = 1
	endif
	
	if (nchan == 1)
		nmax = nwaves
	endif
	
	if ((nmax < nwaves) && (nmax > 0))
		nwaves = nmax
	endif
	
	nwaves = ceil(nwaves)
	
	if ((NumVarOrDefault(df+"ChangePrefixPrompt", 1) == 1) && (nchan > 1) && (nchan != oldnchan))
	
		Prompt nchan, "number of channels:"
		Prompt nwaves, "waves per channel:"
		Prompt prmt, "turn this prompt off in the future:", popup "no;yes;"
	
		DoPrompt "New Wave Details", nchan, nwaves, prmt
		
		if (V_Flag == 1)
			return -1 // cancel
		endif
		
		if (prmt == 2)
			SetNMvar(df+"ChangePrefixPrompt", 0)
		endif
		
	endif
	
	NMFolderGlobalsSave(currentPrefix) // save current prefix globals
	SetNMstr("CurrentPrefix", prefix) // change to new prefix
	NMFolderGlobalsReset()
	NMFolderGlobalsGet(prefix, 1) // get old global variables if they exist
	
	SetNMvar("CurrentWave", 0)
	SetNMvar("NumWaves", nwaves)
	SetNMvar("NumChannels", nchan)
	
	ChanWaveListSet(1)
	CheckNMDataFolderWaves()
	UpdateCurrentWave()
	UpdateNMPanel(0)
	ChanGraphClose(-2, 0) // close unecessary windows
	ChanGraphsToFront()
	NMWaveSelect( "All" )  
	
	return 0

End // NMPrefixSelect

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave Select Functions (i.e. "Set1")
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectCall(fxn)
	String fxn // wave select function (i.e. "All" or "Set1" or "Group1")
	
	Variable grpNum, error, andor, history = 1
	String wavname, wavList, df = NMDF()
	
	strswitch(fxn)
	
		case "---":
		case "Update":
			history = 0
			break
		
		case "Clear":
		case "Clear List":
			NMCmdHistory("NMWaveSelectClear", "")
			NMWaveSelectClear()
			history = 0
			break
		
		case "Other":
		case "Other...":
			wavList = NMSetsList(0)
			wavList = RemoveListFromList(NMWaveSelectDefaults(), wavList, ";")
			
			if (ItemsInList(wavList) == 0)
				DoAlert 0, "No appropriate waves detected."
				error = 1
				break
			endif
			
			Prompt wavname, " ", popup wavList
			DoPrompt "Select Wave", wavname
			
			if (V_flag == 1)
				error = 1
				break
			endif
			
			if (WaveExists($wavname) == 0)
				error = 1
				break
			endif
			
			fxn = wavname
			
			break
			
		case "Set x Group":
			grpNum = NMGroupFirst()
			wavname = StringFromList(0, NMSetsList(0))
			Prompt wavname, " ", popup NMSetsList(0)
			Prompt andor, " ", popup "AND;OR"
			Prompt grpNum, "group number:"
			DoPrompt "Select Wave Group", wavname, andor, grpNum
	
			if (V_flag == 1)
				error = 1
				break
			endif
			
			if (NMGroupCheck(grpNum) == 0)
				error = 1
				break
			endif
			
			fxn = wavname
			
			if (andor == 1)
				fxn += " x "
			else
				fxn += " + "
			endif
			
			fxn += "Group" + num2str(grpNum)
			
			break
		
	endswitch
	
	if (error == 1) // set to "All"
		fxn = "All"
	endif
	
	if (history == 1)
		NMCmdHistory("NMWaveSelect", NMCmdStr(fxn,""))
	endif
	
	return NMWaveSelect(fxn)

End // NMWaveSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelect(fxn)
	String fxn // wave select function (i.e. "All" or "Set1" or "Group1")
	// ("" or "update") to update current selection
	
	if (WavesExist("WavSelect;SetX;Group;") == 0)
		return -1
	endif

	Variable sumvar, grpNum, and = -1, or = -1, error = 1, update = 1
	String wname, df = NMDF()
	
	Wave WavSelect, SetX, Group
	
	if (numpnts(WavSelect) == 0)
		return -1
	endif
	
	Variable NumActiveWaves = NumVarOrDefault("NumActiveWaves", 0)
	Variable GroupsOn = NumVarOrDefault(df+"GroupsOn", 0)

	if ((strlen(fxn) == 0) || (StringMatch(fxn, "Update") == 1))
		fxn = NMWaveSelectGet()
		update = 0
	else // set the function in WavSelect
		Note /K WavSelect
		Note WavSelect, fxn
	endif
	
	sumvar = NMWaveSelectCount()
	
	if (numtype(sumvar) > 0) // error, set to "All"
		fxn = "All"
		WavSelect = 1
		Note /K WavSelect
		Note WavSelect, fxn
		sumvar = NMWaveSelectCount()
	endif
	
	NMWaveSelectAdd(fxn)
	
	if ((update == 1) && (numtype(sumvar) == 0))
		NMAutoTabCall()
	endif
	
	return 0

End // NMWaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectCount()
	
	if (WavesExist("WavSelect;SetX;Group;") == 0)
		return Nan
	endif

	Variable sumvar, grpNum, and = -1, or = -1, error = 1
	String wname, df = NMDF()
	String fxn = NMWaveSelectGet()
	
	Wave WavSelect, SetX, Group
	
	if (numpnts(WavSelect) == 0)
		return Nan
	endif
	
	Variable NumActiveWaves = NumVarOrDefault("NumActiveWaves", 0)
	Variable GroupsOn = NumVarOrDefault(df+"GroupsOn", 0)
	
	and = strsearch(fxn, " x ", 0)
	or = strsearch(fxn, " + ", 0)
	
	if (StringMatch(fxn, "All") == 1)
		
		WavSelect = 1
		error = 0
		
	elseif ((groupsOn == 0) && (StringMatch(fxn, "*group*") == 1))
	
		return Nan
		
	elseif (StringMatch(fxn[0,4], "Group") == 1)
	
		grpNum = str2num(fxn[5,inf])
		WavSelect = NMGroupFilter(Group, grpNum)
		error = 0
		
	elseif (StringMatch(fxn, "All Groups") == 1)

		WavSelect = NMGroupFilter(Group, -1)
		error = 0
		
	elseif (WaveExists($fxn) == 1) // Set or Other wave
	
		Wave tempwave = $fxn
		
		WavSelect = tempwave
		error = 0
	
	elseif (and > 0) // Set && Group
	
		wname = fxn[0,and-1] // Set wave
		
		if (WaveExists($wname) == 1)
		
			Wave tempwave = $wname // Set wave reference
			
			grpNum = str2num(fxn[and+8,inf])
			WavSelect = tempwave && NMGroupFilter(Group, grpNum)
			error = 0

		endif
		
	elseif (or > 0) // Set || Group
	
		wname = fxn[0,or-1] // Set wave
		
		if (WaveExists($wname) == 1)
		
			Wave tempwave = $wname // Set wave reference
			
			grpNum = str2num(fxn[or+8,inf])
			WavSelect = tempwave || NMGroupFilter(Group, grpNum)
			error = 0

		endif
		
	endif
	
	if (error == 1)
	
		return Nan
		
	endif
	
	WaveStats /Q SetX
	
	if ((NMSetXType() == 1) && (StringMatch(fxn, "SetX") == 0) && (V_max == 1))
		
		WavSelect *= BinaryInvert(SetX)
		
	endif
	
	sumvar = sum(WavSelect)
	
	if (numtype(sumvar) == 0)
		SetNMvar("NumActiveWaves", sumvar)
	else
		sumvar = WaveCountOnes("WavSelect")
		SetNMvar("NumActiveWaves", sumvar)
	endif
	
	return sumvar

End // NMWaveSelectCount

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectAdd(fxn)
	String fxn
	
	String WavSelectList = StrVarOrDefault("WavSelectList", "")
	String wSelectDefaults = NMWaveSelectDefaults()
	
	strswitch(fxn)
		case "update":
		case "---":
			return -1
	endswitch
	
	if (WhichListItemLax(fxn, wSelectDefaults+WavSelectList, ";") == -1)
		WavSelectList = AddListItem(fxn, WavSelectList, ";", inf)
		SetNMstr("WavSelectList", WavSelectList)
	endif
	
	UpdateNMWaveSelect()
	
	return 0
	
End // NMWaveSelectAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectClear()

	SetNMstr("WavSelectList", "")

End // NMWaveSelectClear

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectGet()

	CheckWavSelectWave()
	
	if (WaveExists(WavSelect) == 0)
		return ""
	endif

	Wave WavSelect
	
	String wnote = note(WavSelect)
	
	if (StringMatch(wnote, "") == 1)
		wnote = StrVarOrDefault("WaveSlctFxn", "All")
		Note WavSelect, wnote
	endif
	
	return wnote

End // NMWaveSelectGet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAllGroups() // determine if "All Groups" is selected

	if (StringMatch(NMWaveSelectGet(), "All Groups") == 1)
		return 1 // yes
	else
		return 0 // no
	endif

End // NMAllGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectDefaults()

	Variable icnt
	String glist = "", sList = NMSetsList(0) + NMSetsDataList()
	
	if (WhichListItemLax("Set_Data0", sList, ";") > 0)
		if (WhichListItemLax("Set_Data1", sList, ";") < 0)
			// only one Set_Data, no need to display
			sList = RemoveFromList("Set_Data0", sList) 
		endif
	endif
	
	if (NumVarOrDefault(NMDF()+"GroupsOn", 0) == 1)
		glist = "All Groups;" + NMGroupList(1)
	endif
	
	return "All;" + sList + glist
	
End // NMWaveSelectDefaults

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectStr()

	String wselect = StrVarOrDefault("CurrentPrefix", "") + NMWaveSelectGet()
	
	wselect = StringReplace(wselect, " x ","")
	wselect = StringReplace(wselect, " + ","")
	wselect = StringReplace(wselect, "_","")
	wselect = StringReplace(wselect, " ","")
	wselect = StringReplace(wselect, ".","")
	wselect = StringReplace(wselect, ",","")
	
	wselect = StringReplace(wselect, "Data", "D")
	wselect = StringReplace(wselect, "Record", "R")
	wselect = StringReplace(wselect, "Sweep", "S")
	wselect = StringReplace(wselect, "Wave", "W")
	wselect = StringReplace(wselect, "EVEvnt", "EV")
	wselect = StringReplace(wselect, "Event", "EV")
	wselect = StringReplace(wselect, "SPRstr", "SP")
	
	wselect = StringReplace(wselect, "Groups","G")
	wselect = StringReplace(wselect, "Group","G")
	wselect = StringReplace(wselect, "Set", "S")
	
	return wselect[0,11]
	
End // NMWaveSelectStr

//****************************************************************
//****************************************************************
//****************************************************************

