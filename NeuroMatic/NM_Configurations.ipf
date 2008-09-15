#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Configuration Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last Modified 02 Oct 2007
//
//	New Configurations
//
//	Unlike old Preferences.ipf, pref variables cannot be set here
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigDF(fname) // return Configurations full-path folder name
	String fname // config folder name (i.e. "NeuroMatic", "Main", "Stats")
	
	return PackDF("Configurations:" + fname)
	
End // ConfigDF

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfig(fName, copyConfigs) // wrapper for old NMPrefs function
	String fName // package folder name
	Variable copyConfigs // (-1) copy configs to folder (0) no copy (1) copy folder to configs
	
	CheckNMConfig(fName) // create new config folder and variables
	
	if (copyConfigs != 0)
		NMConfigCopy(fname, copyConfigs)
	endif
	
End // NMConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMConfigsAll()

	Variable icnt
	String fname, flist = NMConfigList()
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		CheckNMConfig(StringFromList(icnt, flist))
	endfor

End // CheckNMConfigsAll

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMConfig(fname)
	String fname // config folder name ("NeuroMatic", "Chan", "Stats"...)
	
	Execute /Z fname + "Configs()" // run particular configs function if it exists
	
	//UpdateNMConfigMenu()
	
End // CheckNMConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMConfigDF(fname)
	String fname // config folder name
	
	String df = ConfigDF("") // main config folder
	String sub =df + fname + ":" // sub-folder to check
	
	Variable makeDF
	
	CheckPackDF("Configurations")
	makeDF = CheckPackDF("Configurations:"+fname)
	
	SetNMstr(df+"FileType", "NMConfig")
	SetNMstr(sub+"FileType", "NMConfig")
	
	return makeDF // (0) already made (1) yes, made
	
End // CheckNMConfigDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConfigList()

	String flist = FolderObjectList(ConfigDF(""), 4)
	
	if (FindListItem("NeuroMatic", flist) >= 0)
		flist = RemoveFromList("NeuroMatic", flist)
		flist = AddListItem("NeuroMatic", flist, ";", 0)
	endif
	
	return flist
	
End // NMConfigList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigCopy(flist, direction) // set configurations
	String flist // config folder name list or "All"
	Variable direction // (-1) config to package folder (1) package folder to config
	
	Variable icnt, fcnt
	String fname, objName, cdf, df, objList
	
	if (StringMatch(flist, "All") == 1)
		flist = NMConfigList()
	endif
	
	for (fcnt = 0; fcnt < ItemsInList(flist); fcnt += 1)
	
		fname = StringFromList(fcnt, flist)
		
		cdf = ConfigDF(fname) // config data folder
		df = PackDF(fname) // package data folder
		
		if (DataFolderExists(cdf) == 0)
			continue
		endif
		
		if (direction == -1)
			CheckPackDF(fname)
		endif
		
		objList = NMConfigVarList(fname, 2) // numbers
		
		for (icnt = 0; icnt < ItemsInList(objList); icnt += 1)
		
			objName = StringFromList(icnt, objList)
			
			if ((direction == 1) && (exists(df+objName) == 2))
				SetNMvar(cdf+objName, NumVarOrDefault(df+objName, Nan))
			elseif (direction == -1)
				SetNMvar(df+objName, NumVarOrDefault(cdf+objName, Nan))
			endif
			
		endfor
		
		objList = NMConfigVarList(fname, 3) // strings
		
		for (icnt = 0; icnt < ItemsInList(objList); icnt += 1)
		
			objName = StringFromList(icnt, objList)
			
			if ((direction == 1) && (exists(df+objName) == 2))
				SetNMstr(cdf+objName, StrVarOrDefault(df+objName, ""))
			elseif (direction == -1)
				SetNMstr(df+objName, StrVarOrDefault(cdf+objName, ""))
			endif
			
		endfor
		
		objList = NMConfigVarList(fname, 5) // numeric waves
		
		for (icnt = 0; icnt < ItemsInList(objList); icnt += 1)
		
			objName = StringFromList(icnt, objList)
			
			if ((direction == 1) && (WaveExists($(df+objName)) == 1))
				Duplicate /O $(df+objName), $(cdf+objName)
			elseif (direction == -1)
				Duplicate /O $(cdf+objName), $(df+objName)
			endif
			
		endfor
		
		objList = NMConfigVarList(fname, 6) // text waves
		
		for (icnt = 0; icnt < ItemsInList(objList); icnt += 1)
		
			objName = StringFromList(icnt, objList)
			
			if ((direction == 1) && (WaveExists($(df+objName)) == 1))
				Duplicate /O $(df+objName), $(cdf+objName)
			elseif (direction == -1)
				Duplicate /O $(cdf+objName), $(df+objName)
			endif
			
		endfor
	
	endfor
	
	if (direction == -1)
		UpdateNM(0)
	endif
	
	return 0

End // NMConfigCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConfigSaveCall(fname)
	String fname // config folder name

	String flist = NMConfigList()
	
	if ((strlen(fname) == 0) || (FindListItem(fname, flist) < 0))
	
		fname = "All"
	
		if (ItemsInList(flist) == 0)
			DoAlert 0, "No Configurations to save."
			return ""
		endif
		
		if (ItemsInList(flist) > 1)
			flist += "All;"
		endif
	
		Prompt fname, "choose configuration to save:", popup flist
		DoPrompt "Save Configuration", fname
		
		if (V_flag == 1)
			return "" // cancel
		endif
	
	endif
	
	NMCmdHistory("NMConfigSave", NMCmdStr(fname, ""))
	
	return NMConfigSave(fname)

End // NMConfigSaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConfigSave(fname) // save config folder
	String fname // config folder fname, or "All"
	
	if (StringMatch(fname, "All") == 1)
		return NMConfigSaveAll()
	endif

	String folder, tdf, df = ConfigDF("")
	
	String file = "NMConfig" + fname

	if (StringMatch(StrVarOrDefault(df+"FileType", ""), "NMConfig") == 0)
		DoAlert 0, "NMConfigSave Error: folder is not a NM configuration file."
		return ""
	endif
	
	NMConfigCopy(fname, 1) // get current configuration values
	
	tdf = "root:" + file + ":" // temp folder
	
	if (DataFolderExists(tdf) == 1)
		KillDataFolder $tdf // kill temp folder if already exists
	endif
	
	NewDataFolder $LastPathColon(tdf, 0)
	
	SetNMstr(tdf+"FileType", "NMConfig")
	
	DuplicateDataFolder $(df+fname), $(tdf+fname)
	
	CheckNMPath()
	
	folder = FileBinSave(1, 1, tdf, "NMPath", file, 1, -1) // new file
	
	if (DataFolderExists(tdf) == 1)
		KillDataFolder $tdf // kill temp folder
	endif
	
	return folder
	
End // NMConfigSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConfigSaveAll()
	
	String df =  ConfigDF("")
	String file = StrVarOrDefault(df+"CurrentFile", "")
	
	if (strlen(file) == 0)
		file = "NMConfigs"
	endif

	if (StringMatch(StrVarOrDefault(df+"FileType", ""), "NMConfig") == 0)
		DoAlert 0, "NMConfigSave Error: folder is not a NM configuration file."
		return ""
	endif
	
	NMConfigCopy("All", 1) // get current configuration values
	
	CheckNMPath()
	
	file = FileBinSave(1, 1, df, "NMPath", file, 1, -1) // new file
	
	return file

End // NMConfigSaveAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigOpenCall()

	NMCmdHistory("NMConfigOpen", NMCmdStr("", ""))
	
	return NMConfigOpen("")

End // NMConfigOpenCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigOpen(file)
	String file
	
	String flist, fname, odf, cdf, df = ConfigDF("")
	Variable icnt, dialogue, error = -1
	
	CheckNMPath()
	
	if (strlen(file) == 0)
		dialogue = 1
	endif
	
	String folder = FileBinOpen(dialogue, 0, "", "NMPath", file, 0) // NM_FileManager.ipf

	if (strlen(folder) == 0)
		return error // cancel
	endif
	
	if (IsNMFolder(folder, "NMConfig") == 1)
	
		flist = FolderObjectList(folder, 4) // sub-folder list
		
		for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		
			fname = StringFromList(icnt, flist)
			
			odf = folder + ":" + fname
			cdf = df + fname
		
			if (DataFolderExists(cdf) == 1)
				KillDataFolder $cdf // kill config folder
			endif
			
			DuplicateDataFolder $odf, $cdf
			
			NMConfigCopy(fname, -1) // set config values
		
		endfor
		
		
		error = 0
		
		CheckNMConfigsAll()
		
	else
	
		DoAlert 0, "Open File Error: file is not a NeuroMatic configuration file."
		
	endif
	
	if (DataFolderExists(folder) == 1)
		KillDataFolder $folder
	endif
	
	//UpdateNMConfigMenu()
	
	return error

End // NMConfigOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigOpenAuto()

	Variable icnt, error = -1
	String fname, ext = FileBinExt()
	
	if (IgorVersion() < 5)
		return -1 // does not seem to work with earlier Igor
	endif

	CheckNMPath()
	
	PathInfo NMPath
	
	if (V_flag == 0)
		return 0 // cannot open config file
	endif
	
	String path = S_path
	
	String flist = IndexedFile(NMPath, -1, "????")
	
	flist = RemoveFromList("NMConfigs.pxp", flist)
	flist = AddListItem("NMConfigs.pxp", flist, ";", 0) // open NMConfigs first
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		fname = StringFromList(icnt, flist)
		
		if (StrSearchLax(fname, ".ipf", 0) >= 0)
			continue // skip procedure files
		endif
		
		if (StrSearchLax(fname, ext, 0) >= 0)
			
			strswitch(ext)
				case ".nmb":
					if (StringMatch(NMBinFileType(path+fname), "NMConfig") == 0)
						continue
					endif
				case ".pxp":
					error = NMConfigOpen(fname)
			endswitch
			
		endif
		
	endfor
	
	//UpdateNMConfigMenu()
	
	CheckNMConfigsAll()
	
	PathInfo /S Igor // reset path to Igor

End // NMConfigOpenAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigKillCall(fname)
	String fname // config folder name
	
	String flist = NMConfigList()
	
	if ((strlen(fname) == 0) || (FindListItem(fname, flist) < 0))
	
		if (ItemsInList(flist) == 0)
			DoAlert 0, "No configuration to kill."
			return 0
		endif
		
		if (ItemsInList(flist) > 1)
			flist += "All;"
		endif
	
		Prompt fname, "choose configuration to kill:", popup flist
		DoPrompt "Kill Configuration", fname
		
		if (V_flag == 1)
			return 0 // cancel
		endif
	
	endif
	
	NMCmdHistory("NMConfigKill", NMCmdStr(fname, ""))
	
	return NMConfigKill(fname)

End // NMConfigKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigKill(flist) // kill config folder
	String flist // config folder list, or "All"
	
	if (StringMatch(flist, "All") == 1)
		flist = NMConfigList()
	endif
	
	Variable icnt
	String fname, cdf, df = ConfigDF("")
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		
		fname = StringFromList(icnt, flist)
		
		cdf = df + fname
	
		if (DataFolderExists(cdf) == 1)
			KillDataFolder $cdf // kill config folder
		endif
	
	endfor
	
	UpdateNM(1)
	
End // NMConfigKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigVar(fname, vName, value, infoStr)
	String fname, vName
	Variable value
	String infoStr
	
	String df = ConfigDF(fname)
	String pf = PackDF(fname)
	
	CheckNMConfigDF(fname) // check config folder exists
	CheckNMvar(df+vname, NumVarOrDefault(pf+vName, value))
	CheckNMstr(df+"D_"+vName, infoStr)
	
End // NMConfigVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigStr(fname, vName, strValue, infoStr)
	String fname, vName, strValue, infoStr
	
	String df = ConfigDF(fname)
	String pf = PackDF(fname)
	
	CheckNMConfigDF(fname) // check config folder exists
	CheckNMstr(df+vName, StrVarOrDefault(pf+vName, strValue))
	CheckNMstr(df+"D_"+vName, infoStr)
	
End // NMConfigStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigWave(fname, wName, npnts, value, infoStr)
	String fname, wName
	Variable npnts
	Variable value
	String infoStr
	
	String cw = ConfigDF(fname) + wName
	String pw = PackDF(fname) + wName
	
	CheckNMConfigDF(fname) // check config folder exists
	
	infoStr = NMNoteCheck(infoStr)
	
	if ((WaveExists($pw) == 1) && (WaveExists($cw) == 0))
		Duplicate /O $pw $cw
	else
		CheckNMwave(cw, npnts, value)
	endif
	
	NMNoteType(cw, "NM"+fname, "", "", "Description:" + infoStr)
	
End // NMConfigWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigTWave(fname, wName, npnts, strValue, infoStr)
	String fname, wName
	Variable npnts
	String strValue
	String infoStr
	
	String cw = ConfigDF(fname) + wName
	String pw = PackDF(fname) + wName
	
	CheckNMConfigDF(fname) // check config folder exists
	
	infoStr = NMNoteCheck(infoStr)
	
	if ((WaveExists($pw) == 1) && (WaveExists($cw) == 0))
		Duplicate /O $pw $cw
	else
		CheckNMtwave(cw, npnts, strValue)
	endif
	
	NMNoteType(cw, "NM"+fname, "", "", "Description:" + infoStr)
	
End // NMConfigTWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConfigVarList(fname, objType)
	String fname // config folder name
	Variable objType // (1) waves (2) variables (3) strings (4) data folders (5) numeric wave (6) text wave
	
	Variable ocnt
	String objName, rlist = ""
	
	String objList = FolderObjectList(ConfigDF(fname), objType)
	
	if (objType == 3) // strings
	
		for (ocnt = 0; ocnt < ItemsInList(objList); ocnt += 1)
		
			objName = StringFromList(ocnt, objList)
			
			if (StringMatch(objName[0,1], "D_") == 0) // do not include "Description" strings
				rlist = AddListItem(objName, rlist, ";", inf)
			endif
			
		endfor
		
		objList = rlist
		
	endif
	
	objList = RemoveFromList("FileType", objList)
	objList = RemoveFromList("VarName", objList)
	objList = RemoveFromList("StrValue", objList)
	objList = RemoveFromList("NumValue", objList)
	objList = RemoveFromList("Description", objList)
	
	return objList

End // NMConfigVarList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Configuration Edit/Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigEditCall(fname)
	String fname // config folder name
	
	String flist = NMConfigList()
	
	if ((strlen(fname) == 0) || (FindListItem(fname, flist) < 0))
	
		if (ItemsInList(flist) == 0)
			DoAlert 0, "No Configurations to edit."
			return 0
		endif
		
		if (ItemsInList(flist) > 1)
			flist += "All;"
		endif
	
		Prompt fname, "choose configuration to edit:", popup flist
		DoPrompt "Edit Configurations", fname
		
		if (V_flag == 1)
			return 0 // cancel
		endif
	
	endif
	
	NMCmdHistory("NMConfigEdit", NMCmdStr(fname, ""))
	
	return NMConfigEdit(fname)

End // NMConfigEditCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigEdit(flist) // create table to edit config vars
	String flist // config folder name list, or "All"
	
	Variable fcnt, ocnt, icnt, items, numItems, strItems
	Variable x1, x2, y1, y2
	
	String fname, objName, tName, tTitle, varList, strList
	String df, ndf = NMDF()
	
	String blankStr = ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
	
	Variable xPixels = NumVarOrDefault(ndf+"xPixels", 1000)
	
	if (StringMatch(flist, "All") == 1)
		flist = NMConfigList()
	endif
	
	for (fcnt = 0; fcnt < ItemsInList(flist); fcnt += 1)
	
		fname = StringFromList(fcnt, flist)
		df = ConfigDF(fname)
		
		Execute /Z fname + "ConfigEdit()" // run particular edit tab config if exists
		
	endfor
	
	for (fcnt = 0; fcnt < ItemsInList(flist); fcnt += 1)
	
		fname = StringFromList(fcnt, flist)
		df = ConfigDF(fname)
	
		tName = "Config_" + fname
		tTitle = fname + " Configurations"
	
		varList = NMConfigVarList(fname, 2)
		strList = NMConfigVarList(fname, 3)
	
		if ((ItemsInList(varList) == 0) && (ItemsInList(strList) == 0))
			//DoAlert 0, "Located no  \"" + fname + "\" configurations."
			Execute /Z fname + "ConfigEdit()" // run particular edit tab config if exists
			continue
		endif
		
		numItems = ItemsInList(varList)
		strItems = ItemsInList(strList)
		items = numItems + strItems
		
		if ((numItems > 0) && (strItems > 0))
			items += 1 // for seperator
		endif
		
		Make /O/T/N=(items) $(df+"Description") = ""
		Make /O/T/N=(items) $(df+"VarName") = ""
		Make /O/T/N=(items) $(df+"StrValue") = ""
		
		Make /O/N=(items) $(df+"NumValue") = Nan
		
		Wave /T Description = $(df+"Description")
		Wave /T VarName = $(df+"VarName")
		Wave /T StrValue = $(df+"StrValue")
		
		Wave NumValue = $(df+"NumValue")
		
		if (WinType(tName) == 0)
		
			Edit /K=1/W=(x1,y1,x2,y2)/N=$tName VarName as tTitle
			
			SetCascadeXY(tName)
			
			if (numItems > 0)
				AppendToTable /W=$tName NumValue
				Execute /Z "ModifyTable width(" + df + "NumValue)=60"
			endif
			
			if (strItems > 0)
				AppendToTable /W=$tName StrValue
				Execute /Z "ModifyTable alignment(" + df + "StrValue)=0, width(" + df + "StrValue)=150"
			endif
			
			AppendToTable Description
			
			Execute /Z "ModifyTable title(Point)= \"Entry\""
			Execute /Z "ModifyTable alignment(" + df + "VarName)=0, width(" + df + "VarName)=100"
			Execute /Z "ModifyTable alignment(" + df + "Description)=0, width(" + df + "Description)=500"
			
			SetWindow $tName hook=NMConfigEditHook
			
		endif
		
		DoWindow /F $tName
		
		NMConfigCopy(fname, 1) // get current configuration values
		
		icnt = 0
	
		for (ocnt = 0; ocnt < ItemsInList(varList); ocnt += 1)
			objName = StringFromList(ocnt, varList)
			VarName[icnt] = objName
			NumValue[icnt] = NumVarOrDefault(df+objName, Nan)
			StrValue[icnt] = blankStr
			Description[icnt] = StrVarOrDefault(df+"D_"+objName, "")
			icnt += 1
		endfor
		
		icnt += 1
		
		for (ocnt = 0; ocnt < ItemsInList(strList); ocnt += 1)
			objName = StringFromList(ocnt, strList)
			VarName[icnt] = objName
			StrValue[icnt] = StrVarOrDefault(df+objName,"")
			Description[icnt] = StrVarOrDefault(df+"D_"+objName, "")
			icnt += 1
		endfor
		
	endfor
	
	return 0

End // NMConfigEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigEditHook(infoStr)
	String infoStr
	
	Variable runhook
	String df = NMDF()
	
	String event = StringByKey("EVENT",infoStr)
	String win = StringByKey("WINDOW",infoStr)
	String prefix = "Config_"
	
	Variable icnt = StrSearchLax(win, prefix, 0)
	
	if (icnt < 0)
		return 0
	endif
	
	String fname = win[icnt+strlen(prefix),inf]

	strswitch(event)
		case "deactivate":
			runhook = 1
			SetNMstr(df+"ConfigHookEvent", "deactivate")
			break
		case "kill":
			runhook = 1
			SetNMstr(df+"ConfigHookEvent", "kill")
			break
	endswitch
	
	if (runhook == 1)
		NMConfigEdit2Vars(fname)
		NMConfigCopy(fname, -1) // now save these to appropriate folder
		Execute /Z fname + "ConfigHook()" // run particular tab hook if exists
	endif

End // NMConfigEditHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMConfigEdit2Vars(fname) // save table values to config vars
	String fname // config folder name

	String objName, df = ConfigDF(fname)
	
	Variable icnt, jcnt, items, objNum
	String objStr, objList, vList
	
	String tName = "Config_" + fname

	if (WinType(tName) != 2)
		return 0 // table doesnt exist
	endif
	
	if (WaveExists($(df+"VarName")) == 0)
		return 0
	endif
	
	Wave /T VarName = $(df+"VarName")
	Wave /T Description = $(df+"Description")
	
	vList = Wave2List(df+"VarName")
	
	// save numeric variables
	
	objList = NMConfigVarList(fname, 2)
	
	if (WaveExists($(df+"NumValue")) == 1)
	
		Wave NumValue = $(df+"NumValue")
		
		items = numpnts(NumValue)
	
		for (icnt = 0; icnt < items; icnt += 1)
		
			objName = VarName[icnt]
	
			if ((strlen(objName) == 0) || (FindListItem(objName, objList) < 0))
				continue
			endif
			
			SetNMvar(df+objName, NumValue[icnt])
			
			vList = RemoveFromList(objName, vList)
			
		endfor
	
	endif
	
	// save string variables
	
	objList = NMConfigVarList(fname, 3)
	
	if (WaveExists($(df+"StrValue")) == 1)
	
		Wave /T StrValue = $(df+"StrValue")
		
		items = numpnts(NumValue)
	
		for (icnt = 0; icnt < items; icnt += 1)
		
			objName = VarName[icnt]
			
			if ((strlen(objName) == 0) || (FindListItem(objName, objList) < 0))
				continue
			endif
			
			SetNMstr(df+objName, StrValue[icnt])
			
			vList = RemoveFromList(objName, vList)
			
		endfor
	
	endif
	
	// check for remaining variables
	
	for (icnt = 0; icnt < ItemsInList(vlist); icnt += 1)
	
		objName = StringFromList(icnt, vlist)
		
		if (exists(df+objName) > 0)
			continue
		endif
		
		for (jcnt = 0; jcnt < numpnts(VarName); jcnt += 1)
		
			if (StringMatch(objName, VarName[jcnt]) == 1)
			
				objStr = StrValue[jcnt]
				objNum = NumValue[jcnt]
				
				if (numtype(objNum) == 0)
					SetNMvar(df+objName, objNum)
				else
					SetNMstr(df+objName, objStr)
				endif
				
				SetNMstr(df+"D_"+objName, Description[jcnt])
				
			endif
		
		endfor
		
	endfor
	
End // NMConfigEdit2Vars

//****************************************************************
//****************************************************************
//****************************************************************
