#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Panel Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last Modified 10 March 2008
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

Function NMPanelTabY()

	return 170

End // NMPanelTabY

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPanelWidth()
	
	return 300
	
End // NMPanelWidth

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPanelHeight()
	
	return 640 + 0
	
End // NMPanelHeight

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPanelFsize()

	return 11

End // NMPanelFsize

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPanelRGB(rgb)
	String rgb
	
	strswitch(rgb)
		case "r":
			return 43690
		case "g":
			return 43690
		case "b":
			return 43690
	endswitch

End // NMPanelRGB

//****************************************************************
//****************************************************************
//****************************************************************

Function MakeNMpanel()

	String df = NMDF()

	if (DataFolderExists(df) == 0)
		CheckNMVersionNum()
	endif
	
	Variable x0, y0, x1, y1, yinc, lineheight, fs = NMPanelFsize()
	Variable pwidth = NMPanelWidth(), pheight = NMPanelHeight(), taby = NMPanelTabY()
	
	String tabList = NMTabListGet()
	
	Variable xPixels = NumVarOrDefault(df+"xPixels", 1000)
	Variable r = NMPanelRGB("r")
	Variable g = NMPanelRGB("g")
	Variable b = NMPanelRGB("b")
	
	//CheckCurrentFolder()
	
	x0 = xPixels - pwidth - 10
	y0 = 43
	x1 = x0 + pwidth
	y1 = y0 + pheight
	
	DoWindow /K NMpanel
	NewPanel /K=1/N=NMpanel/W=(x0, y0, x1, y1) as "  NeuroMatic v" + NMVersionStr()
	
	SetWindow NMpanel, hook=NMPanelHook
	
	ModifyPanel cbRGB = (r, g, b)
	
	x0 = 40
	y0 = 6
	yinc = 29
	lineheight = y0 + 94
	
	PopupMenu NM_FolderMenu, title=" ", pos={x0+240, y0+0*yinc}, size={0,0}, bodyWidth=260, help={"data folders"}, win=NMpanel
	PopupMenu NM_FolderMenu, mode=1, value = "", proc=NMPopupFolder, fsize=fs, win=NMpanel
	
	PopupMenu NM_PrefixMenu, title=" ", pos={x0+140, y0+1*yinc}, size={0,0}, bodyWidth=130, help={"wave prefix select"}, win=NMpanel
	PopupMenu NM_PrefixMenu, mode=1, value="Prefix", proc=NMPopupPrefix, fsize=fs, win=NMpanel
	
	PopupMenu NM_SetsMenu, pos={x0+240, y0+1*yinc}, size={0,0}, bodyWidth=85, proc=NMPopupSets, help={"Set functions"}, win=NMpanel
	PopupMenu NM_SetsMenu, value = NMSetsMenu(), fsize=fs, win=NMpanel
	
	PopupMenu NM_GroupMenu, title="G", pos={x0, y0+2*yinc}, size={0,0}, bodyWidth=20, proc=NMPopupGroups, help={"Groups"}, win=NMpanel
	PopupMenu NM_GroupMenu, mode=1, value = "", fsize=fs, win=NMpanel
	
	SetVariable NM_SetWaveNum, title= " ", pos={x0+20, y0+2*yinc+2}, size={55,50}, limits={0,inf,0}, value=CurrentWave, win=NMpanel
	SetVariable NM_SetWaveNum, frame=1, fsize=fs, proc=NMSetVariable, help={"current wave"}, win=NMpanel
	
	SetVariable NM_SetGrpNum, title="Grp", pos={x0+80, y0+2*yinc+3}, size={55,50}, limits={0,inf,0}, value=CurrentGrp, win=NMpanel
	SetVariable NM_SetGrpNum, frame=1, fsize=fs, proc=NMSetVariable, help={"current group"}, win=NMpanel
	
	Button NM_JumpBck, title="<", pos={x0+21, y0+3*yinc}, size={20,20}, proc=NMButton, help={"last wave"}, win=NMpanel, fsize=14
	Button NM_JumpFwd, title=">", pos={x0+112, y0+3*yinc}, size={20,20}, proc=NMButton, help={"next wave"}, win=NMpanel, fsize=14
	
	Slider NM_WaveSlide, pos={x0+45, y0+3*yinc}, size={61,50}, limits={0,0,1}, vert=0, side=2, ticks=0, variable = CurrentWave, proc=NMWaveSlide, win=NMpanel
	
	PopupMenu NM_SkipMenu, title="+", pos={x0, y0+3*yinc-1}, size={0,0}, bodyWidth=20, help={"wave increment"}, proc=NMPopupSkip, win=NMpanel
	PopupMenu NM_SkipMenu, mode=1, value=" ;Wave Increment = 1;Wave Increment > 1;As Wave Select;", fsize=14, win=NMpanel
	
	yinc = 31.5
	
	GroupBox NM_ChanWaveGroup, title = "", pos={0,y0+4*yinc-9}, size={pwidth, 39}, win=NMpanel, labelBack=(43520,48896,65280)
	
	PopupMenu NM_ChanMenu, title="Ch", pos={x0-19, y0+4*yinc}, bodywidth=45, value="A;", mode=1, proc=NMPopupChan, help={"limit channels to analyze"}, fsize=fs, win=NMpanel
	
	PopupMenu NM_WaveMenu, title="Waves", value ="All", mode=1, pos={x0+160, y0+4*yinc}, bodywidth=130, proc=NMPopupWaveSelect, help={"limit waves to analyze"}, fsize=fs, win=NMpanel
	
	SetVariable NM_WaveCount, title=" ", pos={x0+215, y0+4*yinc+2}, size={40,50}, limits={0,inf,0}, value=NumActiveWaves, fsize=fs, win=NMpanel
	SetVariable NM_WaveCount, frame=0, help={"number of currently selected waves"}, win=NMpanel, labelBack=(43520,48896,65280)
	
	y0 += yinc
	
	SetVariable NM_Set1Cnt, title=" ", pos={x0+215, y0+28-2}, size={40,50}, limits={0,inf,0}, help={"number of Set1 waves"}, win=NMpanel
	SetVariable NM_Set1Cnt, value=SumSet1, frame=0, help={"number of Set1 waves"}, fsize=fs, win=NMpanel
	
	SetVariable NM_Set2Cnt, title=" ", pos={x0+215, y0+46-2}, size={40,50}, limits={0,inf,0}, help={"number of Set2 waves"}, win=NMpanel
	SetVariable NM_Set2Cnt, value=SumSet2, frame=0, help={"number of Set2 waves"}, fsize=fs, win=NMpanel
	
	SetVariable NM_SetXCnt, title=" ", pos={x0+215, y0+64-2}, size={40,50}, limits={0,inf,0}, help={"number of SetX waves"}, win=NMpanel
	SetVariable NM_SetXCnt, value=SumSetX, frame=0, help={"number of SetX waves"}, fsize=fs, win=NMpanel
	
	CheckBox NM_Set1Check, title="Set0 :", pos={x0+165, y0+28}, value=0, proc=NMSetsCheckBox, help={"include in Set1"}, fsize=fs, win=NMpanel
	CheckBox NM_Set2Check, title="Set2 :", pos={x0+165, y0+46}, value=0, proc=NMSetsCheckBox, help={"include in Set2"}, fsize=fs, win=NMpanel
	CheckBox NM_SetXCheck, title="SetX :", pos={x0+165, y0+64}, value=0, proc=NMSetsCheckBox, help={"exclude from all analyses"}, fsize=fs, win=NMpanel
	
	//CheckBox NM_WriteCheck, title="OverWrite Mode", pos={20,615}, size={16,18}, value=NumVarOrDefault(df+"OverWrite", 1), win=NMpanel
	//CheckBox NM_WriteCheck, proc=NMOverWriteCheckBox, help={"overwrite waves and graphs"}, fsize=fs, win=NMpanel
	
	//CheckBox NM_NMOK, title="NeuroMatic v"+NMVersionStr(), pos={20+160,615}, size={16,18}, value=NumVarOrDefault(df+"NMOK", 0), win=NMpanel
	//CheckBox NM_NMOK, proc=NMAboutCheckBox, help={"About NeuroMatic"}, fsize=fs, win=NMpanel
	
	TabControl NM_Tab, win=NMpanel, pos={0, taby}, size={pwidth, pheight}, labelBack=(r, g, b), proc=NMTabControl, fsize=fs, win=NMpanel
	
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

Function /S NMmenuDivider()

	//return "---;"
	return " ;---; ;"

End // NMmenuDivider

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanel(updateTab)
	Variable updateTab
	
	Variable fs = NMPanelFsize()
	String df = NMDF()

	if (WinType("NMpanel") == 0)
		return 0
	endif
	
	UpdateNMPanelTitle()
	UpdateNMFolderMenu()
	UpdateNMGroupMenu()
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
	
	CheckBox NM_WriteCheck, title="OverWrite Mode", pos={20,615}, size={16,18}, value=NumVarOrDefault(df+"OverWrite", 1), win=NMpanel
	CheckBox NM_WriteCheck, proc=NMOverWriteCheckBox, help={"overwrite waves and graphs"}, fsize=fs, win=NMpanel
	
	CheckBox NM_NMOK, title="NeuroMatic v"+NMVersionStr(), pos={20+140,615}, size={16,18}, value=NumVarOrDefault(df+"NMOK", 0), win=NMpanel
	CheckBox NM_NMOK, proc=NMAboutCheckBox, help={"About NeuroMatic"}, fsize=fs, win=NMpanel
	
	//CheckBox NM_WriteCheck, win=NMpanel, value = NumVarOrDefault(df+"OverWrite", 1)
	//CheckBox NM_NMOK, win=NMpanel, value = NumVarOrDefault(df+"NMOK", 0)

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
			//title += " : " + stim
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

	Variable currentWave = NMCurrentWave()
	Variable groupsOn = NumVarOrDefault(NMDF()+"GroupsOn", 1)
	Variable numGrps = NumVarOrDefault("NumGrps",0)
	Variable currentGrp = NumVarOrDefault("CurrentGrp",0)
	
	Variable x0 = 40
	Variable y0 = 6
	Variable yinc = 29
	
	if (groupsOn == 1)
		SetVariable NM_SetWaveNum, win=NMpanel, value=currentWave, pos={x0+20, y0+2*yinc+3}
		SetVariable NM_SetGrpNum, win=NMpanel, value=currentGrp, disable = 0, limits={0,numGrps,0}
	else
		SetVariable NM_SetWaveNum, win=NMpanel, value=CurrentWave, pos={x0+49, y0+2*yinc+3}
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
	String cselect, cmenu = "Channel;---;A;"
	
	if (WaveExists(ChanSelect) == 0)
		return 0
	endif

	Variable numChannels = NMNumChannels()
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
	
		cmenu = "Channel;---;All;" + ChanCharList(numChannels, ";")
		
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
	String df = CurrentNMFolder(1)
	
	Variable modenum = WhichListItemLax(wselect, wmenu, ";")

	if (modenum == -1) // not in list
		slist = AddListItem(wselect,slist, ";", inf) // add to list
		SetNMstr(df+"WavSelectList", slist)
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
	
	if (WhichListItem("This Wave;", wmenu) < 0)
		wmenu += "This Wave;"
	endif
	
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

	String txt = "---;Edit This List;---;New;Open;Save;Close;Duplicate;Rename;Merge;---;Open All;Save All;Close All;---;Import Waves;Reload Waves;Rename Waves;"
	
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

Function UpdateNMGroupMenu()

	PopupMenu NM_GroupMenu, mode=1, value=UpdateNMGroupMenuStr(), win=NMpanel

End // UpdateNMGroupMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S UpdateNMGroupMenuStr()

	String df = NMDF(), subStim =  SubStimDF()
	String mList = "Groups;---;Define;Clear;Table;Panel;"
	Variable numStimWaves
	
	if (NumVarOrDefault(df+"GroupsOn", 0) == 0)
		mList = AddListItem("On", mList, ";", inf)
	else
		mList = AddListItem("Off", mList, ";", inf)
	endif
	
	if (strlen(subStim) > 0)
		numStimWaves = NumVarOrDefault(subStim+"NumStimWaves", NumVarOrDefault("NumWaves", 0))
		mList += ";---;Groups=" + num2str(numStimWaves) + ";Blocks="+num2str(numStimWaves)
	endif
	
	return mList

End // UpdateNMGroupMenuStr

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPrefixMenu()
	String df = NMDF()
	
	if (WinType("NMpanel") == 0)
		return 0
	endif
	
	String cPrefix = NMCurrentWavePrefix()
	String pList = NMPrefixList()
	
	if ((strlen(cPrefix) > 0) && (WhichListItemLax(cPrefix, pList, ";") == -1))
		pList = AddListItem(cPrefix, pList, ";", inf) // add prefix to list
		SetNMstr(df+"PrefixList", pList)
	endif
	
	PopupMenu NM_PrefixMenu, win=NMpanel, mode=1, value=NMPrefixMenuStr(), popvalue=NMCurrentWavePrefix()

End // UpdateNMPrefixMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixList()
	
	return StrVarOrDefault(NMDF()+"PrefixList", "Record;Avg_;")

End // NMPrefixMenuStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixMenuStr()
	
	return "Wave Prefix;---;" + NMPrefixList() + ";---;Other;Remove from List;Clear List;Prompt On/Off;Order Waves Preference;"

End // NMPrefixMenuStr

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMSets(recount) // udpate Sets display
	Variable recount

	if (WaveExists(Set1) == 0)
		return 0
	endif

	Variable wNum = NMCurrentWave()
	
	String s1 = NMSetsDisplayName(0)
	String s2 = NMSetsDisplayName(1)
	String s3 = NMSetsDisplayName(2)
	
	Wave Set1 = $s1
	Wave Set2 = $s2
	Wave Set3 = $s3
	
	CheckBox NM_Set1Check, title=s1 + " :", win=NMpanel, value=BinaryCheck(Set1[wNum])
	CheckBox NM_Set2Check, title=s2 + " :", win=NMpanel, value=BinaryCheck(Set2[wNum])
	CheckBox NM_SetXCheck, title=s3 + " :", win=NMpanel, value=BinaryCheck(Set3[wNum])
	
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
		SetNMvar("SumSet1", WaveCountValue(s1, inf))
	endif
	
	sumvar = sum($s2)
	
	if (numtype(sumvar) == 0)
		SetNMvar("SumSet2", sumvar)
	else
		SetNMvar("SumSet2", WaveCountValue(s2, inf))
	endif
	
	sumvar = sum($s3)
	
	if (numtype(sumvar) == 0)
		SetNMvar("SumSetX", sumvar)
	else
		SetNMvar("SumSetX", WaveCountValue(s3, inf))
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
			
		case "Edit This List":
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
	
	//if (NumVarOrDefault("NumWaves", 0) == 0)
		//DoAlert 0, "Data waves have not been selected for this folder."
		//return 0
	//endif
	
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

Function NMAboutCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	CheckBox NM_NMOK, win=NMpanel, value = NumVarOrDefault(NMDF()+"NMOK", 0)
	
	NMwebpage()

End // NMAboutCheckBox

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
	
	CheckCurrentFolder()
	
	if (tab != lastTab)
		SetNMvar(df+"CurrentTab", tab)
		ChangeTab(lastTab, tab, tabList) // NM_TabManager.ipf
		//ChanGraphsUpdate(0)
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
	
	//DoAlert 1, "Kill \"" + tabName + "\" controls?"
	
	//if (V_Flag == 1)
	//	KillControls(TabWinName(tlist), prefix) // kill controls
	//endif
	
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
	
	return NMTabAdd(tabName, "")

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

	String tabList = "Main;Stats;Spike;Event;Clamp;MyTab;RiseT;PairP;MPFA;Art;Fit;"
	
	for (icnt = 0; icnt < ItemsInList(tabList); icnt += 1)
	
		tname = StringFromList(icnt, tabList)
		
		if ((exists(tname) == 6) || (exists(tname+"Tab") == 6))
			aList = AddListItem(tname, aList, ";", inf)
		endif
		
	endfor
	
	return aList

End // NMTabsAvailable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabsExisting()
	
	return TabNameList(NMTabListGet())

End // NMTabsExisting

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
	
	NMCmdHistory("NMCurrentWaveSet", NMCmdNum(waveNum,""))
	
	return NMCurrentWaveSet(waveNum)
	
End // NMCurrentWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentWaveSet(waveNum)
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
	
End // NMCurrentWaveSet

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
	
	Variable current = NumVarOrDefault("CurrentWave", 0)
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	Variable wskip = NumVarOrDefault("WaveSkip", 1)
	
	if (nwaves == 0)
		DoAlert 0, "No waves to display."
		return -1
	endif
	
	if (wskip < 0)
		wskip = 1
		SetNMvar("WaveSkip", wskip)
	endif

	if (wskip > 0)
	
		next = current + direction*wskip
		
		if ((next >= 0) && (next < nwaves))
			found = next
		endif
		
	elseif (wskip == 0)
	
		found = NextWaveItem("WavSelect", 1, current, direction) // NM_Utility.ipf
		
	endif

	if ((found >= 0) && (found != current))
		SetNMvar("CurrentWave", found)
		UpdateCurrentWave()
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
			break
		
		case "Other":
			return NMPrefixOtherCall()
			
		case "Add to List":
			return NMPrefixAddCall()
			
		case "Clear List":
			return NMPrefixListClearCall()
			
		case "Remove from List":
			return NMPrefixRemoveCall()
			
		case "Prompt On/Off":
			return NMPrefixPromptCall()
			
		case "Order Waves Preference":
			NMOrderWavesPrefCall()
			break
		
		default:
			return NMPrefixSelectCall(fxn)
			
	endswitch
	
	UpdateNMPrefixMenu()

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

Function NMPrefixOtherCall()
	String getprefix
	
	Prompt getprefix, "enter prefix string:"
	DoPrompt "Other Wave Prefix", getprefix
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	NMCmdHistory("NMPrefixSelect", NMCmdStr(getprefix,""))
	
	return NMPrefixSelect(getprefix)

End // NMPrefixOtherCall

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
	
	NMPrefixAdd(getprefix)
	
	return NMPrefixSelect(getprefix)

End // NMPrefixAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixAdd(addList) // add prefix name to NM PrefixList
	String addList // prefix list
	String df = NMDF()
	
	Variable icnt, added
	String prefix
	
	if (strlen(addList) == 0)
		return -1
	endif
	
	String pList = NMPrefixList()
	
	for (icnt = 0; icnt < ItemsInlist(addList); icnt += 1)
	
		prefix = StringFromList(icnt, addList)
	
		if (WhichListItemLax(prefix, pList, ";") == -1)
			pList = AddListItem(prefix, pList, ";", inf)
			added = 1
		endif
		
	endfor
	
	SetNMstr(df+"PrefixList", pList)
	
	if (added == 1)
		UpdateNMPrefixMenu()
	endif
	
	return 0

End // NMPrefixAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixRemoveCall()

	String df = NMDF()
	String pList = StrVarOrDefault(df+"PrefixList", "")
	String CurrentPrefix = NMCurrentWavePrefix()

	String getprefix = RemoveFromList(CurrentPrefix, pList)
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

Function NMPrefixRemove(removeList) // remove prefix name from NM PrefixList
	String removeList // prefix list
	
	String df = NMDF()
	
	if (strlen(removeList) == 0)
		return -1
	endif
	
	String pList = StrVarOrDefault(df+"PrefixList", "")
	
	pList = RemoveListFromList(removeList, pList, ";")
	
	SetNMstr(df+"PrefixList", pList)
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

	SetNMstr(df+"PrefixList", "")
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
	
	NMPrefixAdd(prefix)
	SetNMvar(df+"ChangePrefixPrompt", 0)
	NMPrefixSelect(prefix)
	SetNMvar(df+"ChangePrefixPrompt", savePrompt)

End // NMPrefixSelectSilent

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSelect(prefix) // change to a new wave prefix
	String prefix // wave prefix name, or ("") for current prefix
	
	Variable ccnt, wcnt, nchan, found, nmax, prmt, nwaves, newPrefix = 1
	Variable oldNumChan, oldNumWaves, oldWaveListExists
	String wlist, olist, wname, sdf, df = NMDF()
	
	String opstr = WaveListText0()
	
	String currentPrefix = NMCurrentWavePrefix()
	
	if (strlen(prefix) == 0)
		prefix = currentPrefix
		newPrefix = 0
	endif
	
	NMPrefixAdd( prefix )
	
	wlist = WaveList(prefix + "*", ";", opstr)
	nwaves = ItemsInList(wlist)

	if (nwaves == 0)
		DoAlert 0, "NMPrefixSelect Abort: no waves detected with prefix \"" + prefix + "\""
		return -1
	endif
	
	sdf = GetDataFolder(1)+prefix+":"
	
	oldNumChan = NumVarOrDefault(sdf+"NumChannels", -1)
	oldNumWaves = NumVarOrDefault(sdf+"NumWaves", -1)
	
	if (WaveExists($sdf+"ChanWaveList") == 1)
		oldWaveListExists = 1
		Wave /T chanWaveList = $sdf+"ChanWaveList"
	endif
	
	for (ccnt = 0; ccnt < 10; ccnt += 1) // detect multiple channels (up to 10)
	
		wlist = ChanWaveListSearch(prefix, ccnt)
		
		if (ItemsInList(wlist) > 0)
		
			nchan += 1
			found = ItemsInList(wlist)
			
			if (found > nmax)
				nmax = found
			endif
			
			if (oldWaveListExists == 1)
			
				olist = chanWaveList[ccnt]
				
				if (ItemsInList(olist) == ItemsInList(wlist))
			
					for (wcnt = 0; wcnt < ItemsInList(olist); wcnt += 1)
					
						wname = StringFromList(wcnt, olist)
						
						if (WhichListItem(wname, wlist) < 0)
							oldWaveListExists = 0
							
						endif
						
					endfor
					
				else
				
					oldWaveListExists = 0
				
				endif
					
			endif
			
		else
		
			oldWaveListExists = 0
			
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
	
	if ((NumVarOrDefault(df+"ChangePrefixPrompt", 1) == 1) && (nchan > 1) && (nchan != oldNumChan))
	
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
	NMFolderGlobalsGet(prefix) // get old global variables if they exist
	
	if (DataFolderExists(GetDataFolder(1)+prefix+":") == 0)
		ChanSubFolderDefaultsSet(-1)
	endif
	
	SetNMvar("NumWaves", nwaves)
	SetNMvar("NumChannels", nchan)
	SetNMvar("TotalNumWaves", nchan*nwaves)
	
	if ((nwaves > 0) && (oldWaveListExists == 0))
		ChanWaveListSet(-1, 1)
	endif
	
	if (StringMatch(prefix, "Pulse*") == 1)
		ChanUnits2Labels()
	endif
	
	CheckNMDataFolderWaves()
	ChanGraphsReset()
	ChanGraphsUpdate()
	//UpdateNMPanel(0)
	UpdateNM(1)
	
	//ChanGraphClose(-2, 0) // close unecessary windows
	
	//ChanGraphsToFront()
	
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
	
	Variable sumvar, grpNum, and = -1, or = -1, error = 1, update = 1
	String wname, df = NMDF()
	
	if (WavesExist("WavSelect;SetX;Group;") == 0)
		return -1
	endif
	
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

	Variable nwaves, nchan, wavNum, grpNum, and = -1, or = -1, error = 1
	String wname, df = NMDF()
	String fxn = NMWaveSelectGet()
	
	if (WavesExist("ChanSelect;WavSelect;SetX;Group;") == 0)
		SetNMvar("NumActiveWaves", Nan)
		return Nan
	endif
	
	Wave ChanSelect, WavSelect, SetX, Group
	
	if (numpnts(WavSelect) == 0)
		return Nan
	endif
	
	Variable GroupsOn = NumVarOrDefault(df+"GroupsOn", 0)
	
	and = strsearch(fxn, " x ", 0)
	or = strsearch(fxn, " + ", 0)
	
	if (StringMatch(fxn, "All") == 1)
		
		WavSelect = 1
		error = 0
		
	elseif (StringMatch(fxn, "This Wave") == 1)
	
		wavNum = NumVarOrDefault("CurrentWave", 0)
		WavSelect = 0
		WavSelect[wavNum] = 1
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
	
	WaveStats /Q/Z SetX
	
	if ((NMSetXType() == 1) && (StringMatch(fxn, "SetX") == 0) && (V_max == 1))
		
		WavSelect *= BinaryInvert(SetX)
		
	endif
	
	nwaves = sum(WavSelect)
	
	nchan = WaveCountValue("ChanSelect", 1)
	
	if (numtype(nwaves) == 0)
		SetNMvar("NumActiveWaves", nwaves * nchan)
	else
		nwaves = WaveCountValue("WavSelect", 1)
		SetNMvar("NumActiveWaves", nwaves * nchan)
	endif
	
	return nwaves

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
		case "This Wave":
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
	String glist = "", sList = NMSetsList(1) + NMSetsDataList()
	
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

	String wselect = NMCurrentWavePrefix() + NMWaveSelectGet()
	
	wselect = StringReplace(wselect, "This Wave", num2str(NumVarOrDefault("CurrentWave", 0)))
	
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

