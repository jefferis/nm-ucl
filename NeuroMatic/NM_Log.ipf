#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Log Display Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last Modified 25 Feb 2007
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogParent() // directory of log folders

	if (DataFolderExists("root:Logs:") == 0)
		NewDataFolder root:Logs
	endif
	
	return "root:Logs:"
	
End // LogParent

//****************************************************************
//****************************************************************
//****************************************************************

Function IsLogFolder(ldf)
	String ldf // log data folder
	
	return IsNMFolder(ldf, "NMLog")
	
End // IsLogFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogFolderList()

	return NMFolderList("root:","NMLog")
	
End // LogFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogSubFolderList(ldf)
	String ldf // log data folder
	
	return FolderObjectList(ldf, 4)
	
End // LogSubFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogVarList(ndf, prefix, varType)
	String ndf // notes data folder
	String prefix // prefix string ("H_" for header, "F_" for file)
	String varType // "numeric" or "string"

	Variable ocnt, vtype = 2
	String objName, olist = ""
	
	if (DataFolderExists(ndf) == 0)
		return ""
	endif
	
	if (StringMatch(varType, "string") == 1)
		vtype = 3
	endif
	
	olist = FolderObjectList(ndf, vtype)
	olist = RemoveFromList("FileType", olist)
	
	return olist

End // LogVarList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogWaveList(ldf, type)
	String ldf // log data folder
	String type // ("H") Header ("F") File
	
	ldf = LastPathColon(ldf,1)
	
	Variable ocnt, add
	String objName, wnote = "", olist = ""
	
	do
	
		objName = GetIndexedObjName(ldf, 1, ocnt)
		
		if (strlen(objName) == 0)
			break // finished
		endif
		
		wnote = note($(ldf+objName))
		
		add = 1
		
		strswitch(type)
		
			case "H":
				if (StringMatch(wnote, "Header Notes") == 0)
					add = 0
				endif
				break
				
			case "F":
				if (StringMatch(wnote, "File Notes") == 0)
					add = 0
				endif
				break
				
		endswitch
		
		if (add == 1)
			olist = AddListItem(objName, olist, ";", inf)
		endif
		
		ocnt += 1
		
	while(1)
	
	return olist
	
End // LogWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function LogUpdateWaves(ldf) // create log waves from notes subfolders
	String ldf // log data folder
	Variable ocnt, icnt
	String objName, wname, flist, slist, nlist, tdf = ""
	
	ldf = LastPathColon(ldf,1)
	
	flist = LogSubFolderList(ldf)
	
	for (ocnt = 0; ocnt < ItemsInList(flist); ocnt += 1)
	
		objName = StringFromList(ocnt, flist)
		
		tdf = ldf + objName + ":"
		
		slist = LogVarList(tdf, "F_", "string")
		nlist = LogVarList(tdf, "F_", "numeric")
		
		for (icnt = 0; icnt < ItemsInList(slist); icnt += 1) // string vars
			objName = StringFromList(icnt,slist)
			wname = ldf+objName[2,inf]
			CheckNMtwave(wname, ocnt+1, "")
			SetNMtwave(wname, ocnt, StrVarOrDefault(tdf+objName, ""))
			Note /K $wname; Note $wname, "File Notes"
		endfor
		
		for (icnt = 0; icnt < ItemsInList(nlist); icnt += 1) // numeric vars
			objName = StringFromList(icnt,nlist)
			wname = ldf+objName[2,inf]
			CheckNMwave(wname, ocnt+1, Nan)
			SetNMwave(wname, ocnt, NumVarOrDefault(tdf+objName, Nan))
			Note /K $wname; Note $wname, "File Notes"
		endfor
		
		slist = LogVarList(tdf, "H_", "string")
		nlist = LogVarList(tdf, "H_", "numeric")
		
		for (icnt = 0; icnt < ItemsInList(slist); icnt += 1) // string vars
			objName = StringFromList(icnt,slist)
			wname = ldf+objName[2,inf]
			CheckNMtwave(wname, ocnt+1, "")
			SetNMtwave(wname, ocnt, StrVarOrDefault(tdf+objName, ""))
			Note /K $wname; Note $wname, "Header Notes"
		endfor
		
		for (icnt = 0; icnt < ItemsInList(nlist); icnt += 1) // numeric vars
			objName = StringFromList(icnt,nlist)
			wname = ldf+objName[2,inf]
			CheckNMwave(wname, ocnt+1, Nan)
			SetNMwave(wname, ocnt, NumVarOrDefault(tdf+objName, Nan))
			Note /K $wname; Note $wname, "Header Notes"
		endfor
		
	endfor

End // LogUpdateWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogTableName(ldf)
	String ldf // log data folder
	
	return FolderNameCreate(ldf) + "_table"
	
End // LogTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogNotebookName(ldf)
	String ldf // log data folder
	
	return FolderNameCreate(ldf) + "_notebook"
	
End // LogNotebookName

//****************************************************************
//****************************************************************
//****************************************************************

Function LogDisplayCall(ldf)
	String ldf
	
	String vlist = ""

	Variable select = 1
	Prompt select, "display log as:", popup "notebook;table;both;"
	DoPrompt "NeuroMatic Clamp Log File", select
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	vlist = NMCmdStr(ldf, vlist)
	vlist = NMCmdNum(select, vlist)
	NMCmdHistory("LogDisplay", vlist)
	
	LogDisplay(ldf, select)

End // LogDisplayCall

//****************************************************************
//****************************************************************
//****************************************************************

Function LogDisplay(ldf, select)
	String ldf // log data folder
	Variable select // (1) notebook (2) table (3) both

	if ((select == 1) || (select == 3))
		LogNotebook(ldf)
	endif
	
	if ((select == 2) || (select == 3))
		LogTable(ldf)
	endif
	
End // LogDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function LogTable(ldf) // create a log table from a log data folder
	String ldf // log data folder
	
	ldf = LastPathColon(ldf,1)
	
	Variable ocnt
	String objName, wlist, nlist
	String tName = LogTableName(ldf)
	String ftype = StrVarOrDefault(ldf+"FileType", "")
	
	if (DataFolderExists(ldf) == 0)
		DoAlert 0, "Error: data folder \"" + ldf + "\" does not appear to exist."
		return -1
	endif
	
	if (StringMatch(ftype, "NMLog") == 0)
		DoAlert 0, "Error: data folder \"" + ldf + "\" does not appear to be a NeuroMatic Log folder."
		return -1
	endif
	
	LogUpdateWaves(ldf)
	
	if (WinType(tName) == 0) // make table
		Edit /K=1/N=$tName/W=(0,0,0,0) as "Clamp Log : " + GetPathName(ldf,0)
		SetCascadeXY(tName)
		Execute "ModifyTable title(Point)= \"Entry\""
	endif
	
	DoWindow /F $tName
	
	wlist = LogWaveList(ldf, "F")
	
	nlist = GetListItems("*note*", wlist, ";")
	nlist = SortListLax(nlist, ";")
	
	wlist = RemoveListFromList(nlist, wlist, ";") + nlist // place Note waves after others
	wlist += LogWaveList(ldf, "H") // place Header waves last
	
	for (ocnt = 0; ocnt < ItemsInList(wlist); ocnt += 1)
	
		objName = StringFromList(ocnt, wlist)
		
		RemoveFromTable $(ldf+objName) // remove wave first before appending
		AppendToTable $(ldf+objName)
		
		if (StringMatch(objName[0,3], "Note") == 1)
			Execute "ModifyTable alignment(" + ldf + objName + ")=0"
			Execute "ModifyTable width(" + ldf + objName + ")=150"
		endif
		
	endfor

End // LogTable

//****************************************************************
//****************************************************************
//****************************************************************

Function LogNotebook(ldf) // create a log notebook from a log data folder
	String ldf // log data folder
	String name, tabs
	
	ldf = LastPathColon(ldf,1)
	
	Variable ocnt
	String objName, olist, ftype = StrVarOrDefault(LastPathColon(ldf,1)+"FileType", "")
	
	String nbName = LogNotebookName(ldf)
	
	if ((DataFolderExists(ldf) == 0) || (StringMatch(ftype, "NMLog") == 0))
		return 0
	endif
	
	DoWindow /K $nbName
	NewNotebook /K=1/F=0/N=$nbName/W=(0,0,0,0) as "Clamp Notebook : " + GetPathName(ldf,0)
	
	SetCascadeXY(nbName)
	
	Notebook $nbName text=("NeuroMatic Clamp Notebook")
	Notebook $nbName text=("\rFILE:\t\t\t\t\t" + StrVarOrDefault(ldf+"FileName", GetPathName(ldf,0)))
	//Notebook $nbName text=("\rCreated:\t\t\t\t" + StrVarOrDefault(ldf+"FileDate", ""))
	//Notebook $nbName text=("\rTime:\t\t\t\t" + StrVarOrDefault(ldf+"FileTime", ""))
	//Notebook $nbName text=("\r")
	
	olist = LogVarList(ldf, "H_", "string")
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
		objName = StringFromList(ocnt, olist)
		name = UpperStr(ReplaceString("H_", objName, "") + ":")
		tabs = LogNotebookTabs(name)
		Notebook $nbName text=("\r" + name + tabs + StrVarOrDefault(ldf+objName, ""))
	endfor
	
	olist = LogVarList(ldf, "H_", "numeric")
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
		objName = StringFromList(ocnt, olist)
		name = UpperStr(ReplaceString("H_", objName, "") + ":")
		tabs = LogNotebookTabs(name)
		Notebook $nbName text=("\r" + name + tabs + num2str(NumVarOrDefault(ldf+objName, Nan)))
	endfor
	
	olist = LogSubFolderList(ldf)
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1) // loop thru Note subfolders
		objName = StringFromList(ocnt, olist)
		LogNotebookFileVars(LastPathColon(ldf,1) + objName + ":", nbName)
	endfor
	
End // LogNotebook

//****************************************************************
//****************************************************************
//****************************************************************

Function LogNotebookFileVars(ndf, nbName)
	String ndf // notes data folder
	String nbName
	String name, tabs

	if ((WinType(nbName) == 0) || (DataFolderExists(ndf) == 0))
		return 0
	endif
	
	Variable icnt, value
	String objName, strvalue
	
	String nlist = LogVarList(ndf, "F_", "numeric")
	String slist = LogVarList(ndf, "F_", "string")
	String notelist = GetListItems("*note*", slist, ";") // note variables
	
	notelist = SortListLax(notelist, ";")
	
	slist = RemoveListFromList(notelist, slist, ";")
	
	Notebook $nbName selection={endOfFile, endOfFile}
	Notebook $nbName text=("\r")
	Notebook $nbName text=("\r************************************************************")
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1) // string vars
		objName = StringFromList(icnt,slist)
		name = ReplaceString("H_", objName, "") + ":"
		name = UpperStr(ReplaceString("F_", name, ""))
		tabs = LogNotebookTabs(name)
		Notebook $nbName text=("\r" + name + tabs + StrVarOrDefault(ndf+objName, ""))
	endfor
	
	Notebook $nbName text=("\r")
	
	for (icnt = 0; icnt < ItemsInList(nlist); icnt += 1) // numeric vars
	
		objName = StringFromList(icnt,nlist)
		name = UpperStr(ReplaceString("F_", objName, "") + ":")
		tabs = LogNotebookTabs(name)
		value = NumVarOrDefault(ndf+objName, Nan)
		strvalue = ""
		
		if (numtype(value) == 0)
			strvalue = num2str(value)
		endif
		
		Notebook $nbName text=("\r" + name + tabs + strvalue)
		
	endfor
	
	Notebook $nbName text=("\r")
	
	for (icnt = 0; icnt < ItemsInList(notelist); icnt += 1) // note vars
	
		objName = StringFromList(icnt,notelist)
		name = UpperStr(ReplaceString("F_", objName, "") + ":")
		tabs = LogNotebookTabs(name)
		strvalue = StrVarOrDefault(ndf+objName, "")
		
		if (strlen(strvalue) > 0)
			Notebook $nbName text=("\r" + name + tabs + strvalue)
		endif
		
	endfor
	
End // LogNotebookFileVars

//****************************************************************
//****************************************************************
//****************************************************************

Function /T LogNotebookTabs(name)
	String name
	
	if (strlen(name) < 4)
		return "\t\t\t\t\t"
	elseif (strlen(name) < 7)
		return "\t\t\t\t"
	elseif (strlen(name) < 10)
		return "\t\t\t"
	elseif (strlen(name) < 13)
		return "\t\t"
	else
		return "\t"
	endif

End // LogNotebookTabs

//****************************************************************
//****************************************************************
//****************************************************************