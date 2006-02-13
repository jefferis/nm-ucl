#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Notes Functions
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Created in the Laboratory of Dr. Angus Silver
//	Department of Physiology, University College London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Notes are subfolders saved in NM data folders (NMData) 
//	and log (NMLog) folders.
//
//	Began 1 July 2003
//	Last modified 08 Nov 2005
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NotesDF() // return full-path name of Notes folder

	return PackDF("Notes")
	
End // NotesDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NotesTableName()

	return ClampPrefix("NotesTable")
	
End // NotesTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NotesBasicList(prefix, varType)
	String prefix // ("H") Header ("F") File
	Variable varType // (0) numeric (1) string
	
	strswitch(prefix)
	
		case "H":
			if (varType == 0)
				return ""
			else
				return "H_Name;H_Lab;H_Title;"
			endif
		
		case "F":
			if (varType == 0)
				return ""
			else
				return "F_Folder;F_Stim;F_Tbgn;F_Tend;F_ExtFile;"
			endif
			
	endswitch

End // NotesBasicList

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesEditHeader()

	String ndf = NotesDF()
	String name = StrVarOrDefault(ndf+"H_Name", "")
	String lab = StrVarOrDefault(ndf+"H_Lab", "")
	String title = StrVarOrDefault(ndf+"H_Title", "")
	
	Prompt name, "enter user name:"
	Prompt lab, "enter user lab/affiliation:"
	Prompt title, "experiment title:"
	DoPrompt "Edit User Name and Lab", name, lab, title
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMstr(ndf+"H_Name", name)
	SetNMstr(ndf+"H_Lab", lab)
	SetNMstr(ndf+"H_Title", title)

End // NotesEditHeader

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesBasicUpdate()

	String cdf = ClampDF(), ndf = NotesDF()
	
	SetNMstr(ndf+"F_Folder", StrVarOrDefault("FileName", ""))
	SetNMstr(ndf+"F_Stim", StimCurrent())
	SetNMstr(ndf+"F_Tbgn", StrVarOrDefault("FileTime", ""))
	SetNMstr(ndf+"F_Tend", StrVarOrDefault("FileFinish", ""))
	SetNMstr(ndf+"F_ExtFile", StrVarOrDefault("CurrentFile", ""))
	
End // NotesBasicUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNotes()

	Variable icnt
	String olist, ndf = NotesDF()
	
	if (DataFolderExists(ndf) == 0)
		return -1
	endif
	
	SetNMstr(ndf+"FileType", "NMNotes")
	
	// header notes "H_"
	
	olist = NotesBasicList("H", 1)
	
	for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		CheckNMstr(ndf+StringFromList(icnt, olist), "")
	endfor
	
	olist = NotesBasicList("H", 0)
	
	for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		CheckNMvar(ndf+StringFromList(icnt, olist), Nan)
	endfor
	
	// file notes "F_"
	
	olist = NotesBasicList("F", 1)
	
	for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		CheckNMstr(ndf+StringFromList(icnt, olist), "")
	endfor
	
	olist = NotesBasicList("F", 0)
	
	for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		CheckNMvar(ndf+StringFromList(icnt, olist), Nan)
	endfor
	
	return 0

End // CheckNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesTable(update) // create table to edit note vars
	Variable update // (0) dont update table values (1) update existing table values
	
	String cdf = ClampDF(), ndf = NotesDF()
	
	Variable ocnt, icnt, items
	String objName
	
	String tName = NotesTableName()
	String tTitle = "Data Acquisition Notes"
	
	if (update == 1)
		if (WinType(tName) == 2)
			NotesTable2Vars() // update note values
		endif
	endif
	
	String hslist = NotesVarList(ndf, "H_", "string")
	String hnlist = NotesVarList(ndf, "H_", "numeric")
	String fslist = NotesVarList(ndf, "F_", "string")
	String fnlist = NotesVarList(ndf, "F_", "numeric")
	String notelist = GetListItems("*note*", fslist, ";") // note strings
	
	notelist = SortListLax(notelist, ";")
	
	fnlist = RemoveListFromList(NotesBasicList("F",0), fnlist, ";")
	fslist = RemoveListFromList(NotesBasicList("F",1), fslist, ";")
	fslist = RemoveListFromList(notelist, fslist, ";") // remove note strings
	
	items = ItemsInList(hslist) + ItemsInList(hnlist) + ItemsInList(fslist) + ItemsInList(fnlist)
	
	Make /O/T/N=(4*items) $(cdf+"VarName") = ""
	Make /O/T/N=(4*items) $(cdf+"StrValue") = ""
	Make /O/N=(4*items) $(cdf+"NumValue") = Nan
	
	Wave /T VarName = $(cdf+"VarName")
	Wave /T StrValue = $(cdf+"StrValue")
	Wave NumValue = $(cdf+"NumValue")
	
	if (WinType(tName) == 0)
	
		Edit /K=1/W=(0,0,0,0) VarName, NumValue, StrValue
		DoWindow /C $tName
		DoWindow /T $tName, tTitle
		SetCascadeXY(tName)
		Execute "ModifyTable title(Point)= \"Entry\""
		Execute "ModifyTable alignment(" + cdf + "VarName)=0, alignment(" + cdf + "StrValue)=0"
		Execute "ModifyTable width(" + cdf + "NumValue)=60, width(" + cdf + "StrValue)=200"
		
		SetWindow $tName hook=NotesTableHook
		
	endif
	
	VarName[icnt] = "HEADER NOTES:"
	
	icnt += 1

	for (ocnt = 0; ocnt < ItemsInList(hslist); ocnt += 1)
		objName = StringFromList(ocnt,hslist)
		objName = NotesCheckVarName(objName)
		VarName[icnt] = objName
		StrValue[icnt] = StrVarOrDefault(ndf+objName,"")
		icnt += 1
	endfor
	
	for (ocnt = 0; ocnt < ItemsInList(hnlist); ocnt += 1)
		objName = StringFromList(ocnt,hnlist)
		objName = NotesCheckVarName(objName)
		VarName[icnt] = objName
		NumValue[icnt] = NumVarOrDefault(ndf+objName,Nan)
		StrValue[icnt] = NotesStrX()
		icnt += 1
	endfor
	
	icnt += 1
	
	VarName[icnt] = "FILE NOTES:"
	
	icnt += 2
	
	for (ocnt = 0; ocnt < ItemsInList(fnlist); ocnt += 1)
		objName = StringFromList(ocnt,fnlist)
		objName = NotesCheckVarName(objName)
		VarName[icnt] = objName
		NumValue[icnt] = NumVarOrDefault(ndf+objName,Nan)
		StrValue[icnt] = NotesStrX()
		icnt += 1
	endfor
	
	for (ocnt = 0; ocnt < ItemsInList(fslist); ocnt += 1)
		objName = StringFromList(ocnt,fslist)
		objName = NotesCheckVarName(objName)
		VarName[icnt] = objName
		StrValue[icnt] = StrVarOrDefault(ndf+objName,"")
		icnt += 1
	endfor
	
	icnt += 1
	
	for (ocnt = 0; ocnt < ItemsInList(notelist); ocnt += 1)
		objName = StringFromList(ocnt,notelist)
		objName = NotesCheckVarName(objName)
		VarName[icnt] = objName
		StrValue[icnt] = StrVarOrDefault(ndf+objName,"")
		icnt += 1
	endfor
	
	icnt += 1

End // NotesTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesTableHook(infoStr)
	String infoStr
	
	String event= StringByKey("EVENT",infoStr)
	String win= StringByKey("WINDOW",infoStr)
	
	if (StringMatch(win, NotesTableName()) == 0)
		return 0 // wrong window
	endif
	
	strswitch(event)
		case "deactivate":
		case "kill":
			NotesTable(1)
	endswitch

End // NotesTableHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesTable2Vars() // save table values to note vars

	String cdf = ClampDF(), ndf = NotesDF()
	
	Variable icnt, objNum, type, nitem, sitem
	String objName, objStr
	
	String nlist = NotesVarList(ndf, "H_", "numeric") + NotesVarList(ndf, "F_", "numeric")
	String slist = NotesVarList(ndf, "H_", "string") + NotesVarList(ndf, "F_", "string")
	
	nlist = RemoveListFromList(NotesBasicList("F",0), nlist, ";")
	slist = RemoveListFromList(NotesBasicList("F",1), slist, ";")
	
	String tName = NotesTableName()

	if (WinType(tName) != 2)
		return 0 // table doesnt exist
	endif
	
	if (WavesExist(cdf+"VarName;"+cdf+"StrValue;") == 0)
		return 0 // waves dont exist
	endif
	
	Wave /T VarName = $(cdf+"VarName")
	Wave /T StrValue = $(cdf+"StrValue")
	Wave NumValue = $(cdf+"NumValue")
	
	for (icnt = 0; icnt < numpnts(VarName); icnt += 1)
	
		objName = VarName[icnt]
		
		if (strlen(objName) == 0)
			continue
		endif
		
		if (StringMatch(objName, "Header Notes:") == 1)
			continue
		endif
		
		if (StringMatch(objName, "File Notes:") == 1)
			continue
		endif
		
		objName = NotesCheckVarName(objName)
		objNum = NumValue[icnt]
		objStr = StrValue[icnt]
		
		type = 0 // undefined
		
		nitem = WhichListItemLax(objName, nlist, ";")
		sitem = WhichListItemLax(objName, slist, ";")
		
		if (nitem >= 0) // numeric variable
			type = 1
			nlist = RemoveListItem(nitem, nlist)
			objNum = NotesCheckNumValue(objName, objStr, objNum)
		elseif (sitem >= 0) // string variable
			type = 2
			slist = RemoveListItem(sitem, slist)
			objStr = NotesCheckStrValue(objName, objStr, objNum)
		endif

		if (type == 0)
			if (strlen(objStr) > 0)
				type = 2
				objStr = NotesCheckStrValue(objName, objStr, objNum)
			else
				type = 1
			endif
		endif
		
		KillStrings /Z $(ndf+objName)
		KillVariables /Z $(ndf+objName)
		
		if (type == 1)
			SetNMvar(ndf+objName, objNum)
		elseif (type == 2)
			SetNMstr(ndf+objName, objStr)
		endif
		
	endfor
	
	// kill deleted variables
	
	NotesKillVar(ndf, nlist, 0)
	NotesKillStr(ndf, slist, 0)
	
End // NotesTable2Vars

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NotesStrX()
	return ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
End // NotesStrX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NotesCheckVarName(objname) // vars require prefix "H_" or "F_"
	String objname
	
	String prefix = objname[0,1]
	
	if ((StringMatch(prefix, "H_") == 1) || (StringMatch(prefix, "F_") == 1))
		return objname // ok
	else
		return "F_" + objname // file var is default
	endif
	
End // NotesCheckVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesCheckNumValue(varName, strValue, numValue)
	String varName, strValue
	Variable numValue
	
	if ((strlen(strValue) > 0) && (StringMatch(strValue, NotesStrX()) == 0))
	
		if (numtype(numValue) > 0)
			numValue = str2num(strValue)
		endif
		
		Prompt numValue, varName
		DoPrompt "Please Check Numeric Input Value", numValue
		
		if (V_flag == 1)
			numValue = Nan // cancel
		endif
		
	endif
	
	return numValue

End // NotesCheckNumValue

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NotesCheckStrValue(varName, strValue, numValue)
	String varName, strValue
	Variable numValue
	
	if (numtype(numValue) == 0)
	
		if (strlen(strValue) == 0)
			strValue += num2str(numValue)
		else
			strValue += " : " + num2str(numValue)
		endif
		
		Prompt strValue, varName
		DoPrompt "Please Check String Input Value", strValue
		
		if (V_flag == 1)
			strValue = "" // cancel
		endif
		
	endif
	
	return strValue

End // NotesCheckStrValue

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesKillVar(df, vlist, ask)
	String df, vlist
	Variable ask
	
	Variable icnt, kill = 2
	String objName
	
	for (icnt = 0; icnt < ItemsInList(vlist); icnt += 1) // kill unused variables
	
		objName = StringFromList(icnt, vlist)
		
		if (ask == 1)
			Prompt kill, "kill variable \"" + objName + "\"?", popup "no;yes;"
			DoPrompt "Encountered Unused Note Variable", kill
		endif
		
		if (kill == 2)
			KillVariables $(df+objName)
		endif
		
	endfor
	
End // NotesKillVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesKillStr(df, vlist, ask)
	String df, vlist
	Variable ask
	
	Variable icnt, kill = 2
	String objName
	
	for (icnt = 0; icnt < ItemsInList(vlist); icnt += 1) // kill unused strings
	
		objName = StringFromList(icnt, vlist)
		
		if (ask == 1)
			Prompt kill, "kill variable \"" + objName + "\"?", popup "no;yes;"
			DoPrompt "Encountered Unused Note Variable", kill
		endif
		
		if (kill == 2)
			KillStrings $(df+objName)
		endif
		
	endfor
	
End // NotesKillStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NotesVarList(ndf, prefix, varType)
	String ndf // notes data folder
	String prefix // prefix string ("H_" for header, "F_" for file)
	String varType // "numeric" or "string"

	Variable ocnt, vtype = 2
	String objName, olist, vlist = ""
	
	if (DataFolderExists(ndf) == 0)
		return ""
	endif
	
	if (StringMatch(varType, "string") == 1)
		vtype = 3
	endif
	
	olist = FolderObjectList(ndf, vtype)
	olist = RemoveFromList("FileType", olist)
	
	for (ocnt = 0; ocnt < ItemsInlist(olist); ocnt += 1)
		
		objName = StringFromList(ocnt, olist)
		
		if (StringMatch(prefix, objName[0,1]) == 1)
			vlist = AddListItem(objName, vlist, ";", inf)
		endif
		
	endfor
	
	return vlist

End // NotesVarList

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesClearFileVars()
	Variable ocnt
	String objName, ndf = NotesDF()

	String fslist = NotesVarList(ndf, "F_", "string")
	String fnlist = NotesVarList(ndf, "F_", "numeric")

	for (ocnt = 0; ocnt < ItemsInList(fslist); ocnt += 1)
		objName = StringFromList(ocnt,fslist)
		SetNMstr(ndf+objName, "")
	endfor
	
	for (ocnt = 0; ocnt < ItemsInList(fnlist); ocnt += 1)
		objName = StringFromList(ocnt,fnlist)
		SetNMvar(ndf+objName, Nan)
	endfor
	
	if (WinType(NotesTableName()) == 2)
		NotesTable(0)
	endif

End // NotesClearFileVars

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesCopyVars(df, prefix)
	String df // data folder to copy to
	String prefix // "H_" or "F_"
	
	String ndf = NotesDF()
	
	if ((DataFolderExists(df) == 0) || (DataFolderExists(ndf) == 0))
		return -1
	endif
	
	Variable icnt
	String objName, slist, nlist
	
	slist = NotesVarList(ndf, prefix, "string")
	nlist = NotesVarList(ndf, prefix, "numeric")
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1) // string vars
		objName = StringFromList(icnt,slist)
		SetNMstr(df+objName, StrVarOrDefault(ndf+objName,""))
	endfor
	
	for (icnt = 0; icnt < ItemsInList(nlist); icnt += 1) // numeric vars
		objName = StringFromList(icnt,nlist)
		SetNMvar(df+objName, NumVarOrDefault(ndf+objName,Nan))
	endfor
	
End // NotesCopyVars

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesCopyFolder(df) // save note variables to appropriate data folders
	String df // folder where to save Notes

	String cdf = ClampDF(), ndf = NotesDF()
	String path = GetPathName(df, 1)
	
	df = LastPathColon(df, 0)
	path = LastPathColon(path, 0)
	
	if (DataFolderExists(path) == 0)
		return 0
	endif
	
	if (DataFolderExists(df) == 1)
		KillDataFolder $df
	endif
	
	if (DataFolderExists(df) == 1)
		return 0
	endif
	
	DuplicateDataFolder $ndf, $df

End // NotesCopyFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesAddNote(usernote) // add user note
	String usernote // string note or ("") to call prompt
	Variable icnt
	
	String ndf = NotesDF()
	
	String varname, t = time()
	
	if (strlen(usernote) == 0)
 
		Prompt usernote "enter note:"
		DoPrompt "File Note (" + t + ")", usernote
		
		if (V_flag == 1)
			return 0 // cancel
		endif
		
	endif
	
	NotesTable2Vars()
	
	do
	
		varname = ndf + "F_Note" + num2str(icnt)
		
		if (exists(varname) == 0)
			break
		elseif (strlen(StrVarOrDefault(varname, "")) == 0)
			break
		endif
		
		icnt += 1
		
	while(1)
	
	SetNMstr(varname, "[" + t + "] " + usernote)
	
	NotesTable(0)

End // NotesAddNote

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesHeaderVar(varName, value)
	String varName
	Variable value
	
	if (StringMatch(varName[0,1], "H_") == 0)
		varName = "H_" + varName
	endif
	
	SetNMvar(NotesDF()+varName, value)
	
	if (WinType("ClampNotesTable") == 2)
		NotesTable(0)
	endif

End // NotesHeaderVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesHeaderStr(varName, strValue)
	String varName
	String strValue
	
	if (StringMatch(varName[0,1], "H_") == 0)
		varName = "H_" + varName
	endif
	
	SetNMstr(NotesDF()+varName, strValue)
	
	if (WinType("ClampNotesTable") == 2)
		NotesTable(0)
	endif

End // NotesHeaderStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesFileVar(varName, value)
	String varName
	Variable value
	
	if (StringMatch(varName[0,1], "F_") == 0)
		varName = "F_" + varName
	endif
	
	SetNMvar(NotesDF()+varName, value)
	
	if (WinType("ClampNotesTable") == 2)
		NotesTable(0)
	endif

End // NotesFileVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NotesFileStr(varName, strValue)
	String varName
	String strValue
	
	if (StringMatch(varName[0,1], "F_") == 0)
		varName = "F_" + varName
	endif
	
	SetNMstr(NotesDF()+varName, strValue)
	
	if (WinType("ClampNotesTable") == 2)
		NotesTable(0)
	endif

End // NotesFileStr

//****************************************************************
//****************************************************************
//****************************************************************

