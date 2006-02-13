#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Tab Control Manager
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 5 Oct 2004
//
//	To use this Tab Manager, you need to create a "tab list" of each tab (";" delineated), where 
//	each list item consists of the tab name, followed by a comma (","), followed by a tab prefix
//	for all control and global variables pertaining to that tab. The last list item should be the 
//	window name in conjunction with the tab control name. One example of a tab list is as follows:
//
//	String TabList = "Main,MN_;Stats,ST_;NMPanel,mytabcntrl"
//
//	This tab list defines two tabs named "Main" and "Stats", for the tab control named "mytabcntrl"
//	on the window "NMPanel". This tab list should be saved as a global variable, and passed
//	to the tab manager functions listed below, where "tabList" is a required input. Note, you should
//	first create your tab control before calling MakeTabs().
//
//	As an example, here are things to do to create a new tab window called "MyTab" on the
//	the tab control named "mytabcntrl" on window "NMPanel":
//
//	1) add the name of your tab, with its identifying prefix to TabList. For example,
//		TabList = "Main,MN_;Stats,ST_;MyTab,MY_;NMPanel,mytabcntrl"
//
//	2) create a function called MyTab(enable), which accepts an enable variable flag (1 - enable; 0 - disable).
//		Within this function you should call functions that create controls and global variables that
//		pertain to your tab if enable is one, if they do not already exist. All control names and global
//		variable names should begin with the prefix defined in the tab list, such as "MY_" for MyTab.
//
//		Button MY_Button
//		String MY_StringVar
//
//	3) call function ChangeTab(tabNum) when changing to a new tab. this function automatically
//		enables/disables the appropriate controls, so long as you use the tab's prefix to name your controls.
//
//	4) if your tab window creates lots of windows, waves and variables, it might be desireable to kill these
//		"outputs" at some point. Use KillTab(tabNum) to kill these outputs; however, the output names must begin
//		with the tab's prefix string, such as "My_String" or "My_Table".
//
//	5) to call a more specific function pertaining to your tab window, use CallTabFunction(prefixName, tabNum),
//		which will call a function named "prefixName + tabName". For example, CallTabFunction("Auto", 2) will
//		call AutoMyTab().
//			
//	6) See "MyTab.ipf" for an example of the above explanation.
//
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeTabs(tabList) // set up tab controls
	String tabList	 // list of: tab name, tab prefix
					// followed by: window name, control name
					// for example: "Main,MN_;Stats,ST_;MyTab,MY_;NMPanel,mytabcntrl"
	
	if (TabExists(tabList) == 0) // "empty" tab control should have already been created
		//Abort "Abort: tab control does not exist."
		return -1
	endif

	Variable icnt
	String tName = TabCntrlName(tabList)
	
	for (icnt = 0; icnt < NumTabs(tabList); icnt += 1) // add tabs
		TabControl $tName, win=$TabWinName(tabList), tabLabel(icnt)=tabName(icnt, tabList)
	endfor
	
End // MakeTabs

//****************************************************************
//****************************************************************
//****************************************************************

Function ClearTabs(tabList) // clear tab control
	String tabList	 // list of: tab name, tab prefix
					// followed by: window name, control name
					// for example: "Main,MN_;Stats,ST_;MyTab,MY_;NMPanel,mytabcntrl"
	
	if (TabExists(tabList) == 0) // "empty" tab control should have already been created
		//Abort "Abort: tab control does not exist."
		return -1
	endif

	Variable icnt
	String tName = TabCntrlName(tabList)
	
	for (icnt = NumTabs(tabList)-1; icnt >= 0; icnt -= 1) // add tabs
		TabControl $tName, win=$TabWinName(tabList), tabLabel(icnt)=""
	endfor
	
End // ClearTabs

//****************************************************************
//****************************************************************
//****************************************************************

Function ChangeTab(fromTab, toTab, tabList) // change to new tab window
	Variable fromTab
	Variable toTab // tab number (pass negative number to send this number to specific function TabName())
	String tabList // list of tab names
	
	if (TabExists(tabList) == 0)
		//Abort "Abort: tab control does not exist."
		return -1
	endif

	String tName
	
	if (toTab < 0)
	
		tName = TabName(fromTab, tabList)
		Execute /Z  tName + "(" + num2str(toTab) + ")" // if toTab < 0, pass this variable
		
	else
	
		if (fromTab != toTab)
			tName = TabName(fromTab, tabList)
			EnableTab(fromTab, tabList, 0) // disable controls if they exist
			Execute /Z tName + "(0)" // run specific disable tab function
		endif
		
		tName = TabName(toTab, tabList)
		EnableTab(toTab, tabList, 1) // enable controls if they exist
		Execute /Z tName + "(1)" // run specific enable tab function

		if (V_Flag == 2003)
			DoAlert 0, "Failed to find function " + tName + "(enable). Make sure the Igor procedure file for this tab is open."
		endif
		
	endif
	
	TabControl $TabCntrlName(tabList), win=$TabWinName(tabList), value = toTab // reset control

End // ChangeTab

//****************************************************************
//****************************************************************
//****************************************************************

Function EnableTab(tabNum, tabList, enable) // enable/disable a tab window
	Variable tabNum // tab number
	String tabList // list of tab names
	Variable enable // 1 - enable; 0 - disable
	
	Variable icnt
	String cname
	String wName = TabWinName(tabList)
	
	if (TabExists(tabList) == 0)
		//Abort "Abort: tab control does not exist."
		return -1
	endif
	
	DoWindow /F $wName
	
	String clist = ControlList(wName,  TabPrefix(tabNum, tabList) + "*", ";")
	
	if (ItemsInList(clist) == 0)
		return 0
	endif
	
	for (icnt = 0; icnt < ItemsInList(clist); icnt += 1)
	
		cname = StringFromList(icnt, clist)
		
		ControlInfo /W=$wName $cname
		
		switch(abs(V_Flag))
			case 1:
				Button $cname, disable=(!enable)
				break
			case 2:
				CheckBox $cname, disable=(!enable)
				break
			case 3:
				PopupMenu $cname, disable=(!enable)
				break
			case 4:
				ValDisplay $cname, disable=(!enable)
				break
			case 5:
				SetVariable $cname, disable=(!enable)
				break
			case 6:
				Chart $cname, disable=(!enable)
				break
			case 7:
				Slider $cname, disable=(!enable)
				break
			case 8:
				TabControl $cname, disable=(!enable)
				break
			case 9:
				GroupBox $cname, disable=(!enable)
				break
			case 10:
				TitleBox $cname, disable=(!enable)
				break
			case 11:
				ListBox $cname, disable=(!enable)
				break
		endswitch
		
	endfor

End // EnableTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillTab(tabNum, tabList, dialogue) // kill global variables, controls and windows related to a tab
	Variable tabNum // tab number
	String tabList // list of tab names
	Variable dialogue // call dialogue flag (1 - yes;0 - no)
	
	String prefix = TabPrefix(tabNum, tabList) + "*"
	String tname = TabName(tabNum, tabList)
	
	if (TabExists(tabList) == 0)
		//Abort "Abort: tab control does not exist."
		return -1
	endif
	
	Execute /Z tname + "(-1)" // remove graph waves
	
	If (dialogue == 1)
		DoAlert 1, "Kill \"" + tname + "\" plots and tables?"
	endif
		
	if ((V_Flag == 1) || (dialogue == 0))
		KillWindows(prefix)
	endif
	
	If (dialogue == 1)
		DoAlert 1, "Kill \"" + tname + "\" output waves?"
	endif
		
	if ((V_Flag == 1) || (dialogue == 0))
		KillGlobals(GetDataFolder(1), prefix, "001") // kill waves
		Execute /Z "Kill" + tname + "(\"waves\")" // execute user-defined kill function, if it exists
	endif
	
	If (dialogue == 1)
		DoAlert 1, "Kill \"" + tname + "\" strings and variables?"
	endif
	
	if ((V_Flag == 1) || (dialogue == 0))
		KillGlobals(GetDataFolder(1), prefix, "110") // kill variables and strings in current folder
		Execute /Z "Kill" + tname + "(\"folder\")" // execute user-defined kill function, if it exists
		//KillControls(TabWinName(tabList), prefix) // kill controls
	endif
	
End // KillTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillTabs(tabList) // kill all tabs, no dialogue
	String tabList // list of tab names
	
	if (TabExists(tabList) == 0)
		//Abort "Abort: tab control does not exist."
		return -1
	endif
	
	Variable icnt
	
	for (icnt = 0; icnt < NumTabs(tabList); icnt += 1) // kill each tab
		KillTab(icnt, tabList, 0) // no dialogue
	endfor

End // KillTabs

//****************************************************************
//****************************************************************
//****************************************************************

Function KillTabControls(tabNum, tabList) // kill tab controls
	Variable tabNum // tab number
	String tabList // list of tab names
	
	String prefix = TabPrefix(tabNum, tabList) + "*"
	String tname = TabName(tabNum, tabList)
	
	if (TabExists(tabList) == 0)
		//Abort "Abort: tab control does not exist."
		return -1
	endif

	KillControls(TabWinName(tabList), prefix) // kill controls
	
End // KillTabControls

//****************************************************************
//****************************************************************
//****************************************************************

Function CallTabFunction(funcPrefix, tabNum, tabList) // call a tab's function, whose name is Prefix + TabName
	String funcPrefix // function prefix name, such as "Auto", to be conjoined with the tab's name
	Variable tabNum // tab number
	String tabList // list of tab names
	
	// execute function PrefixTabName().
	// for example, if the prefix is "Auto"  and tab name is "Main", AutoMain() will be executed.
	
	if (TabExists(tabList) == 0)
		//Abort "Abort: tab control does not exist."
		return -1
	endif
	
	Execute /Z funcPrefix + TabName(tabNum, tabList) + "()"
	
	return V_flag // return error flag (zero if no error)

End // CallTabFunction

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Tab Manager utility functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function TabExists(tabList) // determine if tab control exists, as defined by tab list
	String tabList // list of tab names
	
	ControlInfo /W=$TabWinName(tabList) $TabCntrlName(tabList)
	
	if (V_Flag == 8)
		return 1
	else
		return 0
	endif
	
End // TabExists

//****************************************************************
//****************************************************************
//****************************************************************

Function NumTabs(tabList) // compute the number of tabs defined by tab list
	String tabList // list of tab names
	
	return ItemsInList(tabList, ";")-1

End // NumTabs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TabWinName(tabList) // extract window name from the tab list
	String tabList // list of tab names
	String name = ""
	
	name = StringFromList(ItemsInList(tabList, ";")-1, tabList, ";")
	name = StringFromList(0, name, ",")
	
	return name

End // TabWinName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TabCntrlName(tabList) // extract control name from the tab list
	String tabList // list of tab names
	String name = ""
	
	name = StringFromList(ItemsInList(tabList, ";")-1, tabList, ";")
	name = StringFromList(1, name, ",")
	
	return name

End // TabCntrlName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TabName(tabNum, tabList) // extract tab name from the tab list
	Variable tabNum // tab number
	String tabList // list of tab names
	String name = ""
	
	name = StringFromList(tabNum, tabList, ";")
	name = StringFromList(0, name, ",")
	
	return name

End // TabName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TabNameList(tabList) // create a list of tab names given TabManager list
	String tabList // list of tab names
	String name, tlist = ""
	Variable icnt
	
	for (icnt = 0; icnt < ItemsInList(tabList, ";")-1;icnt += 1)
		name = StringFromList(icnt, tabList, ";")
		name = StringFromList(0, name, ",")
		tlist = AddListItem(name, tlist,";",inf)
	endfor
	
	return tlist

End // TabNameList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TabPrefix(tabNum, tabList) // extract tab prefix name of controls and globals from the tab list
	Variable tabNum // tab number
	String tabList // list of tab names
	
	String name
	
	name = StringFromList(tabNum, tabList, ";")
	name = StringFromList(1, name, ",")
	
	return name

End // TabPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function TabNumber(tName, tabList) // determine the tab number, given the tab's name
	String tName // tab name
	String tabList // list of tab names
	
	Variable icnt
	
	for (icnt = 0; icnt < NumTabs(tabList); icnt += 1)
		if (StringMatch(TabName(icnt, tabList), tName) == 1)
			return icnt
		endif
	endfor
	
	return -1

End // TabNumber

//****************************************************************
//
//	ControlList(): create a list of control names that match matchStr
//
//****************************************************************

Function /S ControlList(wName, mtchStr, listSepStr)
	String wName // window string
	String mtchStr // string match item
	String listSepStr // string list seperator
	
	String olist = ""
	String clist = ControlNameList(wName)
		
	if (ItemsInList(clist) == 0)
		return ""
	endif
	
	Variable icnt
	String cname
	
	for (icnt = 0; icnt < ItemsInList(clist); icnt += 1)
		cname = StringFromList(icnt, clist)
		if (StringMatch(cname, mtchStr) == 1)
			olist = AddListItem(cname, olist, listSepStr, inf)
		endif
	endfor

	return olist
	
End Function // ControlList

//****************************************************************
//
//	KillControls(): kill a group of controls
//
//****************************************************************

Function KillControls(wName, matchStr)
	String wName // window name
	String matchStr // control name to match (ie. "ST_*", or "*" for all)
	
	Variable icnt
	
	DoWindow /F $wName
	
	String clist = ControlList(wName, matchStr, ";")
	
	if (ItemsInList(clist) == 0)
		return 0
	endif
	
	for (icnt = 0; icnt < ItemsInList(clist); icnt += 1)
		KillControl $StringFromList(icnt, clist)
	endfor

End Function // KillControls

//****************************************************************
//
//	KillGlobals(): kill a group of variables, strings and/or waves
//
//****************************************************************

Function KillGlobals(folder, matchStr, select)
	String folder	// folder name ("") current folder
	String matchStr	// variable/string name to match (ie. "ST_*", or "*" for all)
	String select	// variable | string | wave (i.e. "111" for all, or "001" for waves)
	
	Variable icnt
	String vList, sList, wList, thisDF
	
	if (strlen(folder) == 0)
		folder = GetDataFolder(1)
	elseif (DataFolderExists(folder) == 0)
		return -1
	endif
	
	thisDF = GetDataFolder(1)		// save current directory
	
	SetDataFolder $folder
	
	vList = VariableList(matchStr, ";", 4+2)
	sList = StringList(matchStr, ";")
	wList = WaveList(matchStr, ";", "")
	
	if ((StringMatch(select[0,0], "1") == 1) && (ItemsInList(vList) > 0))
		for (icnt = 0; icnt < ItemsInList(vList); icnt += 1)
			Execute /Z "KillVariables /Z " + StringFromList(icnt, vList)
		endfor
	endif
	
	if ((StringMatch(select[1,1], "1") == 1) && (ItemsInList(sList) > 0))
		for (icnt = 0; icnt < ItemsInList(sList); icnt += 1)
			Execute /Z "KillStrings /Z " + StringFromList(icnt, sList)
		endfor
	endif
	
	if ((StringMatch(select[2,2], "1") == 1) && (ItemsInList(wList) > 0))
		for (icnt = 0; icnt < ItemsInList(wList); icnt += 1)
			Execute /Z "KillWaves /Z " + StringFromList(icnt, wList)
		endfor
	endif
	
	SetDataFolder $thisDF					// back to original data folder

End Function // KillGlobals

//****************************************************************
//
//	KillWindows(): kill a group of windows
//
//****************************************************************

Function KillWindows(matchStr)
	String matchStr // window name to match (ie. "ST_*", or "*" for all)
	
	Variable wcnt, killwin
	String wName, wList
	
	wList = WinList(matchStr, ";","WIN:3")
	
	if (ItemsInList(wList) == 0)
		return 0
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
		wName = StringFromList(wcnt, wList)
		Execute /Z "DoWindow /K " + wName // close graphs and tables
	endfor

End Function // KillWindows

//****************************************************************
//
//
//
//****************************************************************
