#pragma rtGlobals = 1
#pragma version = 2

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
//
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
	
	return 640
	
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

Function MakeNMpanelCall()

	NMCmdHistory("MakeNMpanel","")
	
	return MakeNMpanel()

End // MakeNMpanelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function MakeNMpanel()

	Variable x0, y0, x1, y1, yinc, icnt, lineheight
	String ctrlName, setName, df = NMDF()

	if (DataFolderExists(df) == 0)
		CheckNMVersion()
	endif
	
	CheckNMvar(df+"SumSet0", 0)				// set counters
	CheckNMvar(df+"SumSet1", 0)
	CheckNMvar(df+"SumSet2", 0)
	
	CheckNMvar(df+"NumActiveWaves", 0) 	// number of active waves to analyze
	
	CheckNMvar(df+"CurrentWave", 0)			// current wave to display
	CheckNMvar(df+"CurrentGrp", 0)			// current group number
	
	Variable pwidth = NMPanelWidth()
	Variable pheight = NMPanelHeight()
	Variable taby = NMPanelTabY()
	Variable fs = NMPanelFsize()
	
	String tabList = NMTabControlList()
	
	Variable xPixels = NMComputerPixelsX()
	
	Variable r = NMPanelRGB("r")
	Variable g = NMPanelRGB("g")
	Variable b = NMPanelRGB("b")
	
	x0 = xPixels - pwidth
	y0 = 43
	x1 = x0 + pwidth
	y1 = y0 + pheight
	
	DoWindow /K NMpanel
	NewPanel /K=1/N=NMpanel/W=(x0, y0, x1, y1) as "  NeuroMatic v" + num2str( NMVersion() )
	
	//SetWindow NMpanel, hook=NMPanelHook
	
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
	
	PopupMenu NM_GroupMenu, title="G ", pos={x0, y0+2*yinc}, size={0,0}, bodyWidth=20, proc=NMPopupGroups, help={"Groups"}, win=NMpanel
	PopupMenu NM_GroupMenu, mode=1, value = "", fsize=fs, win=NMpanel
	
	SetVariable NM_SetWaveNum, title= " ", pos={x0+20, y0+2*yinc+2}, size={55,50}, limits={0,inf,0}, value=$(df+"CurrentWave"), win=NMpanel
	SetVariable NM_SetWaveNum, frame=1, fsize=fs, proc=NMSetVariable, help={"current wave"}, win=NMpanel
	
	SetVariable NM_SetGrpNum, title="Grp", pos={x0+80, y0+2*yinc+3}, size={55,50}, limits={0,inf,0}, value=$(df+"CurrentGrp"), win=NMpanel
	SetVariable NM_SetGrpNum, frame=1, fsize=fs, proc=NMSetVariable, help={"current group"}, win=NMpanel
	
	Button NM_JumpBck, title="<", pos={x0+21, y0+3*yinc}, size={20,20}, proc=NMButton, help={"last wave"}, win=NMpanel, fsize=14
	Button NM_JumpFwd, title=">", pos={x0+112, y0+3*yinc}, size={20,20}, proc=NMButton, help={"next wave"}, win=NMpanel, fsize=14
	
	Slider NM_WaveSlide, pos={x0+45, y0+3*yinc}, size={61,50}, limits={0,0,1}, vert=0, side=2, ticks=0, variable = $(df+"CurrentWave"), proc=NMWaveSlide, win=NMpanel
	
	PopupMenu NM_SkipMenu, title="+ ", pos={x0, y0+3*yinc-1}, size={0,0}, bodyWidth=20, help={"wave increment"}, proc=NMPopupSkip, win=NMpanel
	PopupMenu NM_SkipMenu, mode=1, value=" ;Wave Increment = 1;Wave Increment > 1;As Wave Select;", fsize=14, win=NMpanel
	
	yinc = 31.5
	
	GroupBox NM_ChanWaveGroup, title = "", pos={0,y0+4*yinc-9}, size={pwidth, 39}, win=NMpanel, labelBack=(43520,48896,65280)
	
	PopupMenu NM_ChanMenu, title="Ch", pos={x0-19, y0+4*yinc}, bodywidth=45, value="A;", mode=1, proc=NMPopupChan, help={"limit channels to analyze"}, fsize=fs, win=NMpanel
	
	PopupMenu NM_WaveMenu, title="Waves", value ="All", mode=1, pos={x0+160, y0+4*yinc}, bodywidth=130, proc=NMPopupWaveSelect, help={"limit waves to analyze"}, fsize=fs, win=NMpanel
	
	SetVariable NM_WaveCount, title=" ", pos={x0+215, y0+4*yinc+2}, size={40,50}, limits={0,inf,0}, value=$(df+"NumActiveWaves"), fsize=fs, win=NMpanel
	SetVariable NM_WaveCount, frame=0, help={"number of currently selected waves"}, win=NMpanel, labelBack=(43520,48896,65280), noedit=1
	
	y0 += yinc
	
	for ( icnt = 0 ; icnt < 3 ; icnt += 1  )
	
		ctrlName = "NM_Set" + num2istr( icnt ) + "Cnt"
		setName = NMSetsDisplayName( icnt )
	
		SetVariable $ctrlName, title=" ", pos={x0+215, y0+28+18*icnt-2}, size={40,50}, limits={0,inf,0}, win=NMpanel
		SetVariable $ctrlName, value=$(df+"SumSet"+num2istr(icnt)), frame=0, help={"number of " + setName + " waves"}, fsize=fs, noedit=1, win=NMpanel
		
		ctrlName = "NM_Set" + num2istr( icnt ) + "Check"
		
		CheckBox $ctrlName, title=setName+" ", pos={x0+165, y0+28+18*icnt}, value=0, proc=NMSetsCheckBox, help={"include in "+setName}, fsize=fs, win=NMpanel
	
	endfor
	
	CheckBox NM_WriteCheck, title="OverWrite Mode", pos={20,615}, size={16,18}, value=NeuroMaticVar("OverWrite"), win=NMpanel
	CheckBox NM_WriteCheck, proc=NMOverWriteCheckBox, help={"overwrite waves and graphs"}, fsize=fs, win=NMpanel
	
	CheckBox NM_NMOK, title="NeuroMatic v"+num2str( NMVersion() ), pos={20+140,615}, size={16,18}, value=1, win=NMpanel
	CheckBox NM_NMOK, proc=NMAboutCheckBox, help={"About NeuroMatic"}, fsize=fs, win=NMpanel
	
	TabControl NM_Tab, win=NMpanel, pos={0, taby}, size={pwidth, pheight}, labelBack=(r, g, b), proc=NMTabControl, fsize=fs, win=NMpanel
	
	NMTabsMake(1)
	
	UpdateNMPanel(1)
	
	return 0
	
End // MakeNMpanel

//****************************************************************
//****************************************************************
//****************************************************************

Function DisableNMPanel( enable )
	Variable enable
	
	CheckBox NM_WriteCheck, win=NMPanel, disable=enable
	CheckBox NM_NMOK, win=NMPanel, disable=enable
	
End // DisableNMPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPanelHook(infoStr) // REMOVED Sept 2009
	string infoStr
	
	string event= StringByKey("EVENT",infoStr)
	string win= StringByKey("WINDOW",infoStr)
	
	if (StringMatch(win, "NMpanel") == 0)
		return 0 // wrong window
	endif
	
	if (StringMatch(event, "activate") == 1)
		//CheckCurrentFolder()
		//CheckNMFolderList()
	endif

End // NMPanelHook

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanel(updateTab)
	Variable updateTab
	
	Variable fs = NMPanelFsize()

	if (WinType("NMpanel") == 0)
		return 0
	endif
	
	UpdateNMPanelVariables()
	UpdateNMPanelTitle()
	UpdateNMPanelFolderMenu()
	UpdateNMPanelGroupMenu()
	UpdateNMPanelSetVariables()
	UpdateNMPanelPrefixMenu()
	
	UpdateNMPanelChanSelect()
	UpdateNMPanelWaveSelect()
	UpdateNMSetsDisplayCount()
	UpdateNMWaveSelectCount()
	
	if (updateTab == 1)
		UpdateNMTab()
	endif

End // UpdateNMPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanelVariables()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		
		SetNeuroMaticVar( "SumSet0", 0 )
		SetNeuroMaticVar( "SumSet1", 0 )
		SetNeuroMaticVar( "SumSet2", 0 )
		SetNeuroMaticVar( "NumActiveWaves", 0 )
		SetNeuroMaticVar( "CurrentWave", 0 )
		SetNeuroMaticVar( "CurrentGrp", 0)
	
	else
	
		//SetNeuroMaticVar( "NumActiveWaves", NumVarOrDefault(prefixFolder+"NumActiveWaves", 0) )
		SetNeuroMaticVar( "CurrentWave",  CurrentNMWave() )
		SetNeuroMaticVar( "CurrentGrp", CurrentNMGroup() )
	
	endif

End // UpdateNMPanelVariables

//****************************************************************
//****************************************************************
//****************************************************************

Function /S UpdateNMPanelTitle()
	
	if (WinType("NMpanel") == 7)
		DoWindow /T NMpanel, NMFolderListName("") + " : " + CurrentNMFolder( 0 )
	endif

End // UpdateNMPanelTitle

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanelSetVariables()

	Variable numWaves, numWavesMax, x0 = 40, y0 = 6, yinc = 29
	
	String prefixFolder = CurrentNMPrefixFolder()

	Variable grpsOn = NMGroupsAreOn()
	
	if ( strlen( prefixFolder ) > 0 )
		numWaves = NMNumWaves()
		numWavesMax = max( 0, numWaves - 1 )
	else
		grpsOn = 0
	endif
	
	if (grpsOn == 1)
		SetVariable NM_SetWaveNum, win=NMpanel, limits={0,numWavesMax,0}, pos={x0+20, y0+2*yinc+3}
		SetVariable NM_SetGrpNum, win=NMpanel, disable = 0
	else
		SetVariable NM_SetWaveNum, win=NMpanel, limits={0,numWavesMax,0}, pos={x0+49, y0+2*yinc+3}
		SetVariable NM_SetGrpNum, win=NMpanel, disable = 1
	endif
	
	Slider NM_WaveSlide, limits={0,numWavesMax,1}, win=NMpanel

End // UpdateNMPanelSetVariables

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanelChanSelect()

	Variable cmode
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	String chanStr = NMChanSelectStr()
	String chanMenu = NMChanSelectMenu()
	
	cmode = WhichListItem( chanStr , chanMenu )
	
	cmode = max( cmode, 0 )
	
	PopupMenu NM_ChanMenu, mode=(cmode+1) , value=NMChanSelectMenu(), win=NMpanel

End // UpdateNMPanelChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanSelectMenu()

	String prefixFolder = CurrentNMPrefixFolder()
	String allStr = "All;"
	
	Variable numChannels = NMNumChannels()
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( numChannels == 0 ) )
		return " "
	endif
	
	strswitch( CurrentNMTabName() )
		case "Event":
		case "Fit":
		case "EPSC":
			allStr = ""
			break
	
	endswitch
	
	if ( numChannels == 1 )
		return "A;"
	elseif ( numChannels < 3 )
		return "Channel;---;" + allStr + NMChanList( "CHAR" )
	endif
	
	return "Channel;---;" + allStr + NMChanList( "CHAR" ) + "---;Edit List;"

End // NMChanSelectMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanelWaveSelect()

	Variable modenum
	
	String waveSelect = NMWaveSelectGet()
	String wmenu = NMWaveSelectMenu()
	
	if ( StringMatch( wmenu, "None" ) == 1 )
		waveSelect = "None"
	endif
	
	modenum = WhichListItem(waveSelect, wmenu, ";", 0, 0)
			
	if (modenum == -1) // not in list
		waveSelect = "None"
		modenum = WhichListItem(waveSelect, wmenu, ";", 0, 0)
	endif
	
	modenum = max( modenum , 0 )
	
	PopupMenu NM_WaveMenu, mode=(modenum+1), value=NMWaveSelectMenu(), win=NMpanel

End // UpdateNMPanelWaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectMenu()

	Variable numSets, numGrps, numAdded
	String grpList = "", otherList = "", outList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( NMNumWaves() < 1 ) )
		return "None"
	endif
	
	Variable grpsOn = NMGroupsAreOn()
	
	String waveSelect = NMWaveSelectGet()
	String setList = NMSetsList()
	String addedList = NeuroMaticStr( "WaveSelectAdded" )
	
	numSets = ItemsInList( setList )
	numAdded = ItemsInList( addedList )
	
	if ( numSets > 1 )
		otherList = AddListItem( "All Sets", otherList, ";", inf )
	endif
	
	if ( grpsOn == 1 )
		grpList =  NMGroupsList( 1 )
		numGrps = ItemsInList( grpList )
	endif
	
	if ( numGrps > 0 )
	
		otherList = AddListItem("---", otherList, ";", 0 )
		
		if ( numGrps > 1 )
			otherList = NMAddToList( "All Groups;", otherList, ";" )
		endif
		
		if ( numSets > 0 )
		
			otherList = NMAddToList( "Set x Group;", otherList, ";" )
			
			if ( numAdded > 0 )
				addedList = AddListItem( "Clear List", addedList, ";", inf )
				otherList = NMAddToList( addedList, otherList, ";" )
			endif
			
		endif
		
		grpList = AddListItem( "---", grpList, ";", 0 ) // add to beginning
		
	endif
	
	otherList = AddListItem( "This Wave", otherList, ";", inf )
	
	outList = "All;" + setList + otherList + grpList
	
	//outList = AddWaveListCheckMark( waveSelect, outList, ";", 1 )
	
	return outList

End // NMWaveSelectMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanelFolderMenu()

	if (WinType("NMpanel") == 0)
		return 0
	endif
	
	String item = NMFolderListName("") + " : " + CurrentNMFolder( 0 )
	
	Variable md = max(1, 1 + WhichListItem(item, NMFolderMenu()))

	PopupMenu NM_FolderMenu, mode=md, value=NMFolderMenu(), win=NMpanel

End // UpdateNMPanelFolderMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderMenu()

	String txt = "---;New;Open;Close;Save;Duplicate;Rename;Merge;---;Open All;Import All;Save All;Close All;---;Rename Waves;Reload Waves;Import Waves;Load All Waves;---;Set Open Path;Set Save Path;"
	
	String folderList = NMDataFolderListLong()
	
	String logList = NMLogFolderListLong()
	
	if (strlen( folderList) > 0)
		
		folderList = "---;" + folderList
	
	endif
	
	if (strlen(logList) > 0)
		
		logList = "---;" + logList
	
	endif

	return "Folders;" + folderList + logList  + txt

End // NMFolderMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanelGroupMenu()

	PopupMenu NM_GroupMenu, mode=1, value=NMGroupsMenu(), win=NMpanel

End // UpdateNMPanelGroupMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsMenu()

	Variable numWaves, numStimWaves, numGrps

	String menuList
	
	Variable on = NMGroupsAreOn()
	
	String prefixFolder = CurrentNMPrefixFolder()
	String subStimFolder =  SubStimDF()

	if ( strlen( prefixFolder ) == 0 )
		return "Groups;"
	endif
	
	numGrps = NMGroupsNumCount()
	
	menuList = "Groups;---;Define;Edit;Convert;"
	
	if ( numGrps > 0 )
		menuList += "Clear;"
	endif
		
	if ( on == 1 )
		menuList = AddListItem("Off", menuList, ";", inf)
	elseif ( numGrps > 0 )
		menuList = AddListItem("On", menuList, ";", inf)
	endif
	
	if (strlen(subStimFolder) > 0)
	
		numWaves = NumVarOrDefault(prefixFolder+"NumWaves", 0)
	
		numStimWaves = NumVarOrDefault(subStimFolder+"NumStimWaves", numWaves)
		
		menuList += ";---;Groups=" + num2istr(numStimWaves) + ";Blocks="+num2istr(numStimWaves)
		
	endif
	
	return menuList

End // NMGroupsMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanelPrefixMenu()
	
	if (WinType("NMpanel") == 0)
		return 0
	endif
	
	String cPrefix = CurrentNMWavePrefix()
	String pList = NMPrefixList()
	
	if ((strlen(cPrefix) > 0) && (WhichListItem(cPrefix, pList, ";", 0, 0) == -1))
		pList = AddListItem(cPrefix, pList, ";", inf) // add prefix to list
		SetNeuroMaticStr( "PrefixList", pList )
	endif
	
	PopupMenu NM_PrefixMenu, win=NMpanel, mode=1, value=NMPrefixMenu(), popvalue=CurrentNMWavePrefix()

End // UpdateNMPanelPrefixMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixMenu()
	
	return "Wave Prefix;---;" + NMPrefixList() + ";---;Other;Edit Default List;Kill Prefix Globals;---;Order Waves;Order Waves Preference;"

End // NMPrefixMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixCall(fxn)
	String fxn
	
	Variable error = -1
	
	strswitch( fxn )
	
		case "Wave Prefix":
			SetNMstr( "CurrentPrefix", "" )
			break
			
		case "---":
			break
		
		case "Other":
			error = NMPrefixOtherCall()
			break
			
		case "Kill Prefix Globals":
			error = NMPrefixSubfolderKillCall()
			break
			
		case "Edit Default List":
			error = NMPrefixListSetCall()
			break
			
		case "Clear List":
			return NMPrefixListClearCall()
			
		case "Remove from List":
			return NMPrefixRemoveCall()
		
		case "Order Waves":
			NMOrderWavesCall()
			break
			
		case "Order Waves Preference":
			NMOrderWavesPrefCall()
			break
		
		default:
			error = NMPrefixSelectCall( fxn )
			
	endswitch
	
	if ( error != 0 )
		UpdateNMPanelPrefixMenu()
	endif
	
	return 0

End // NMPrefixCall

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPanelSets( recount ) // udpate Sets display
	Variable recount
	
	Variable icnt, setValue
	String ttle, oldttle, ttleStrVar, setList, setName, ctrlName
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	String wname = CurrentNMWaveName()
	
	String prefixFolder = NMChanWaveName( currentChan, currentWave )
	
	for ( icnt = 0 ; icnt < 3 ; icnt += 1 )
	
		setName = NMSetsDisplayName( icnt )
		
		ttle = " "
		setValue = 0
		
		if ( ( strlen( setName ) > 0 ) && ( AreNMSets( setName ) == 1 ) )
		
			setList = NMSetsWaveList( setName, currentChan )
		
			ttle = setName + " :"
		
			if ( ( ItemsInList( setList ) > 0 ) && ( WhichListItem( wname, setList ) >= 0 ) )
				setValue = 1
			endif
		
		endif
		
		ctrlName = "NM_Set" + num2istr( icnt ) + "Check"
		
		ttleStrVar = NMDF() + "SetsDisplayTitle" + num2istr( icnt )
		oldttle = StrVarOrDefault( ttleStrVar, " " )
		
		if ( StringMatch( ttle, oldttle ) == 1 )
			CheckBox $ctrlName, win=NMpanel, value=(setValue)
		else
			CheckBox $ctrlName, title=ttle, win=NMpanel, value=(setValue)
			SetNMstr( ttleStrVar, ttle )
		endif
	
	endfor
	
	if (recount == 1)
		UpdateNMSetsDisplayCount()
		UpdateNMWaveSelectCount()
	endif

End // UpdateNMPanelSets

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsMenu()

	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
		return "Sets;"
	endif
	
	return "Sets;---;Define;Equation;Edit;Convert;Invert;Clear;---;New;Copy;Rename;Kill;---;Exclude SetX?;Auto Advance;Display;"

End // NMSetsMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMTabControl(name, tab) // called when user clicks on NMpanel tab
	String name; Variable tab
	
	name = TabName(tab, NMTabControlList())
	
	NMCmdHistory("NMTab", NMCmdStr(name,""))
	
	NMTab(name)

End // NMTabControl

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMTab()

	Variable thisTab = NeuroMaticVar( "CurrentTab" )
	
	NMTabsMake(0) // checks if tablist has changed
	
	ChangeTab(thisTab, thisTab, NMTabControlList())

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
		case "Close":
		case "Save":
		case "Kill":
		case "Duplicate":
		case "Rename":
		case "Merge":
		case "Append":
		case "Open | Append":
		case "Rename Waves":
		case "Reload Waves":
		case "Import Waves":
		case "Load All Waves":
		case "Open All":
		case "Import All":
		case "Append All":
		case "Save All":
		case "Kill All":
		case "Close All":
		case "Set Open Path":
		case "Set Save Path":
			NMFolderCall(popStr)
			break
			
		default:
		
			found = strsearch(popstr, " : ", 0)
		
			if (found >= 0)
				popstr = popstr[found+3,inf]
			endif
		
			if (StringMatch(popstr, CurrentNMFolder( 0 )) == 0)
				NMCmdHistory("NMFolderChange", NMCmdStr(popStr,""))
				NMFolderChange(popStr)
			endif
			
			break
			
	endswitch
	
	UpdateNMPanelFolderMenu()
	CheckNMFolderList()
	
	DoWindow /F NMpanel
	
End // NMPopupFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupPrefix(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	Variable update = 1
	
	strswitch( popStr)
	
		case "---":
			break
			
		default:
	
		if (NMPrefixCall(popStr) == 0)
			update = 0 // update already done
		endif
	
	endswitch
	
	if ( update == 1 )
		UpdateNMPanelPrefixMenu()
	endif
	
	DoWindow /F NMpanel

End // NMPopupPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupGroups(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_GroupMenu, win=NMpanel, mode=1
	
	strswitch( popStr)
	
		case "Groups":
		case "---":
			return 0
			
		default:
			NMGroupsCall(popStr, "")
	
	endswitch
	
End // NMPopupGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupSets(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_SetsMenu, win=NMpanel, mode=1
	
	strswitch( popStr)
	
		case "Sets":
		case "---":
			return 0
			
		default:
			NMSetsCall(popStr, "")
		
	endswitch
	
End // NMPopupSets

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupSkip(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_SkipMenu, win=NMpanel, mode=1
	
	strswitch( popStr )
		case " ":
			return 0 // nothing
	
		default:
			NMWaveIncCall(popStr)
			
	endswitch

End // NMPopupSkip

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupChan(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	strswitch( popStr )
	
		case "Channel":
		case "---":
		
			UpdateNMPanelChanSelect()
			
			return 0
			
		case "Edit List":
		
			if ( NMChanSelectListEdit() < 0 )
				UpdateNMPanelChanSelect()
			endif
			
			return 0
			
	endswitch
	
	NMChanSelectCall( popStr )
	
	DoWindow /F NMpanel
	
End // NMPopupChan

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPopupWaveSelect(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	strswitch( popStr )
	
		case "---":
			UpdateNMPanelWaveSelect()
			return 0
	
	endswitch
	
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
			return NMCurrentWaveSetCall(varNum)
			
		case "NM_SetGrpNum":
			return NMGroupsAssignCall(varNum)
			
	endswitch
	
End // NMSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	if ( NMSetsOK() == 0 )
		UpdateNMPanelSets(0)
		return -1
	endif
	
	NMSetsCall(ctrlName[3,inf], num2istr(checked))
	
	DoWindow /F NMPanel

End // NMSetsCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOverWriteCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked

	NMCmdHistory("NMOverWriteOn", NMCmdNum(checked,""))
	
	SetNeuroMaticVar( "OverWrite", checked )

End // NMOverWriteCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAboutCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	CheckBox NM_NMOK, win=NMpanel, value = 1
	
	//NMwebpage()

End // NMAboutCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSlide(ctrlName, value, event) // SlideVariable Control
	String ctrlName
	Variable value // slider value
	Variable event // event - bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	
	if ( ( event == 4 ) && ( NMPrefixFolderAlert() == 1 ) )
		NMCurrentWaveSetCall( value )
	endif

End // NMWaveSlide

//****************************************************************
//****************************************************************
//****************************************************************