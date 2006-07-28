#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic File I/O Functions
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 28 Feb 2006
//
//	Functions for opening/saving binary files
//
//	Import data file types currently supported:
//		1) Axograph
//		2) Pclamp
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFileCall(select)
	String select
	
	strswitch(select)
			
		case "Reload":
		case "Reload Data":
		case "Reload Waves":
			NMDataReloadCall()
			break
			
		case "Import":
		case "Import Data":
		case "Import Waves":
			NMImportFileCall("")
			break
			
		case "Axograph":
			NMImportFileCall("axograph")
			break
			
		case "Pclamp":
			NMImportFileCall("Pclamp")
			break
			
		case "Convert":
			NMBin2IgorCall()
			break
			
	endswitch
	
End // NMFileCall

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Import Data Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ImportConfigEdit()

	Variable wcnt
	String wname, tname = "Config_Import2"

	String df = PackDF("Import")
	
	String wlist = NMConfigVarList("Import", 6) + NMConfigVarList("Import", 5)
	
	DoWindow /K $tname
	Edit /K=1/W=(0,0,0,0)
	DoWindow /C $tName
	DoWindow /T $tName, "File Import Channel Configuration"
	Execute "ModifyTable title(Point)= \"Chan\""
	
	SetCascadeXY(tName)
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
		wname = StringFromList(wcnt, wlist)
		AppendToTable $(df+wname)
	endfor

End // ImportConfigEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function ImportConfigGet() // get import config waves

	Variable wcnt
	String wname, df = PackDF("Import")
	
	String xl = StrVarOrDefault(df+"xLabel", "")
	
	if (strlen(xl) > 0)
		SetNMstr("xLabel", xl)
	endif
	
	String wlist = NMConfigVarList("Import", 6) + NMConfigVarList("Import", 5)
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
		wname = StringFromList(wcnt, wlist)
		Duplicate /O $(df+wname), $wname // copy to current data folder
	endfor

End // ImportConfigGet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportFileManager(filetype, option) // call appropriate import data function
	String filetype // data file type (ie. "axograph" or "Pclamp")
	String option // "header" to read data header
				// "data" to read data
				// "test" to test whether this file manager supports file type
	
	Variable /G success // success flag (1) yes (0) no; or the number of data waves read
	
	strswitch(filetype)
	
		case "Axograph": // (see ReadAxograph.ipf)
		
			strswitch(option)
				case "header":
					Execute "success = ReadAxoHeader()"
					break
					
				case "data":
					Execute "success = ReadAxoData()"
					break
					
				case "test":
					success = 1
					break
					
			endswitch
			
			break
		
		case "Pclamp": // (see ReadPclamp.ipf)
		
			strswitch(option)
			
				case "header":
					Execute "success = ReadPclampHeader()"
					break
					
				case "data":
					Execute "success = ReadPclampData()"
					break
					
				case "test":
					success = 1
					break
					
			endswitch
			
			break
			
	endswitch
	
	Variable ss = success
	
	KillVariables /Z success
	
	return ss

End // NMImportFileManager

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportFileCall(ftype) // open a data file
	String ftype // file type ("axograph" or "Pclamp")
	
	Variable refnum, newfolder, sets
	String vlist = "", file = "", folder = "", df = NMDF()
	
	if (CheckCurrentFolder() == 0)
		NMFolderNew("")
	endif
	
	if (NMImportFileManager(ftype, "test") == 0)
	
		ftype = StrVarOrDefault(df+"ImportType", "Pclamp")
		
		Prompt ftype, "choose file type:", popup "Axograph;Pclamp;"
		DoPrompt "Import Data", ftype
		
		if (V_flag == 1)
			return 0 // cancel
		endif
		
		SetNMstr(df+"ImportType", ftype)
		
	endif
	
	if (IsNMDataFolder("") == 0)
	
		newfolder = 1
	
	elseif (NumVarOrDefault("NumWaves", 0) > 0)
	
		newfolder = 1 + NumVarOrDefault(df+"ImportNewFolder", 0)
		
		Prompt newfolder "import data where?", popup "this data folder;new data folder;"
		DoPrompt "Import Data", newfolder
		
		if (V_flag == 1)
			return 0 // cancel
		endif
		
		newfolder -= 1
		
		SetNMvar(df+"ImportNewFolder", newfolder)
		
		if (newfolder == 0)
			sets = 1
		endif
		
	endif
	
	file = FileDialogue(0, "OpenDataPath", "", "?")
	
	if (strlen(file) == 0)
		return 0 // cancel
	endif
	
	if (newfolder == 1)
		folder = FolderNameCreate(file) // create folder name
	else
		folder = GetDataFolder(1)
	endif
	
	vlist = NMCmdStr(folder, vlist)
	vlist = NMCmdStr(file, vlist)
	vlist = NMCmdStr(ftype, vlist)
	NMCmdHistory("NMImportFile", vlist)
	
	NMImportFile(folder, file, ftype)

End // NMImportFileCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMImportFile(folder, file, ftype) // import a data file
	String folder // folder name ("") dont care
	String file // external file name
	String ftype // file type, such as "Axograph" or "Pclamp"
	
	Variable success, refnum, newfolder, newname, cancel
	String setList, df = NMDF()
	
	CheckPackage("Import", 0)
	
	if ((strlen(file) == 0) || (FileExists(file) == 0))
		return "" 
	endif
	
	if (strlen(folder) == 0)
		folder = FolderNameCreate(file) // create folder name
	endif
		
	if (DataFolderExists(folder) == 0)
	
		folder = NMFolderNew(folder) // create NM folder
	
		if (strlen(folder) == 0)
			return ""
		endif
		
	elseif ((NumVarOrDefault("NumWaves", 0) == 0) && (strlen(StrVarOrDefault("CurrentFile","")) == 0))
	
		newname = 1
		
	endif
	
	SetNMstr("CurrentFile", file)
	SetNMstr("FileName", GetPathName(file, 0))
	SetNMstr("DataFileType", ftype)

	CheckNMwave("FileScaleFactors", 10, 1)
	CheckNMwave("MyScaleFactors", 10, 1)
	CheckNMtwave("yLabel", 10, "") // increase size
	
	ImportConfigGet()
	
	if (NMImportData(1) < 0)
		return "" // cancel
	endif
	
	if (newname == 1)
		folder = FolderNameCreate(file)
		NMFolderRename(GetDataFolder(0), folder)
	endif
	
	UpdateNM(0)
	
	return folder

End // NMImportFile

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportData(appnd) // the main load data function
	Variable appnd // (0) do not append (1) append
	
	if (CheckCurrentFolder() == 0)
		return 0
	endif
	
	Variable iSeqBgn, iSeqEnd, newPrefix
	String df = NMDF(), idf = PackDF("Import")
	
	String CurrentFile = StrVarOrDefault("CurrentFile", "")
	
	NVAR TotalNumWaves, NumWaves, NumChannels, CurrentWave
	SVAR WavePrefix, CurrentPrefix
	
	if (FileExists(CurrentFile) == 0) // check to see if CurrentFile points to an existing file
		DoAlert 0, "Error: external data file has not been selected."
		return -1
	endif
	
	String setList = NMSetsList(1) // save list of Sets before appending

	Variable /G WaveBeg, WaveEnd, WaveInc // temporary variables for loading waves
	Variable /G FileBeg, FileEnd, FileInc = -1 // temporary variables for loading file sequence
	
	Variable prmpt = NumVarOrDefault(idf+"ImportPrompt", 1)
	
	String fileType = StrVarOrDefault("DataFileType", "")
	
	String oldPrefix = WavePrefix
	
	Variable success = NMImportFileManager(fileType, "header") // read data header and store variables

	if (success == 0)
		if ((appnd == 0) && (NumWaves == 0))
			NMFolderClose(GetDataFolder(1))
		endif
		return -1
	endif
	
	WaveInc = 1; WaveBeg = 1; WaveEnd = floor(TotalNumWaves/NumChannels)
	
	CheckNMDataFolderWaves() // redimension file waves
	
	CheckNMwave("FileScaleFactors", NumChannels, 1)
	CheckNMwave("MyScaleFactors", NumChannels, 1)
	
	if (prmpt == 1)
		NMImportPanel() // open panel to display header info, and request user input
	endif
	
	if (WaveInc == -1) // user aborted
		if ((appnd == 0) && (NumWaves == 0))
			NMFolderClose(GetDataFolder(1))
		endif
		return -1
	endif
	
	NMPrefixAdd(WavePrefix)
	
	if (StringMatch(WavePrefix, oldPrefix) == 0)
		newPrefix = 1
	endif
	
	if ((newPrefix == 0) && (appnd == 1))
		CurrentWave = NumWaves
	else
		CurrentWave = 0
	endif
	
	NMProgressStr("Importing Data...")
	
	success = NMImportFileManager(fileType, "Data") // now read the data
	
	if (success < 0) // user aborted
		if (appnd == 0)
			NMFolderClose(GetDataFolder(1))
		endif
		return -1
	endif
	
	if (newPrefix == 1)
		NMPrefixSelectSilent(WavePrefix)
		KillWaves /Z Set_Data0
		setList = RemoveFromList("Set_Data0", setList)
	else
		CurrentPrefix = WavePrefix
	endif
	
	if ((newPrefix == 0) && (appnd == 1))
		NumWaves += success // save number of waves read
	else
		NumWaves = success
	endif
	
	TotalNumWaves = NumChannels * NumWaves
	
	PrintFileDetails(success)
	
	CheckNMwave(setList, NumVarOrDefault("NumWaves", 0), 0)  // redimension old Sets
	
	NMSetsDataNew() // create Set_Data wave
	
	if ((FileEnd > FileBeg) && (FileInc >= 1)) // file sequence to read
		iSeqBgn = NumVarOrDefault("iSeqBgn",0) // from SeqNumFind
		iSeqEnd = NumVarOrDefault("iSeqEnd",0)
		NMImportFileAuto(FileBeg+FileInc, FileEnd, FileInc, iSeqBgn, iSeqEnd) // append the remaining files
	endif
	
	KillVariables /Z WaveBeg, WaveEnd, WaveInc, FileBeg, FileEnd, FileInc, FilePromptFlag, iSeqBgn, iSeqEnd, V_Flag
	KillStrings /Z S_path, S_filename, S_wavenames
	
	CheckNMDataFolderWaves() // update waves
	ChanWaveListSet(1) // set channel wave names
	
	return 0

End // NMImportData

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportFileAuto(fbeg, fend, finc, iSeqBgn, iseqend) // append a sequence of files
	Variable fbeg // file sequence begin number
	Variable fend // file sequence end number
	Variable finc // file sequence increment number
	Variable iSeqBgn // begin index of sequence number in filename string
	Variable iseqend // end index of sequence number in filename string
	
	if (CheckCurrentFolder() == 0)
		return 0
	endif
	
	Variable fcnt, success
	String setList
	
	NVAR WaveBeg, WaveEnd, WaveInc
	NVAR NumWaves, CurrentWave, TotalNumWaves, NumChannels
	SVAR CurrentFile
	
	String fileType = StrVarOrDefault("DataFileType", "")
	
	if ((fbeg > fend) || (finc < 1) || (iSeqBgn > iseqend) || (numtype(fbeg*fend*finc*iSeqBgn*iseqend) != 0))
		return -1 // not allowed
	endif
	
	Variable FilePromptFlag = NumVarOrDefault("FilePromptFlag", 1)
	
	Duplicate /O yLabel saveYLabel
	
	for (fcnt = fbeg; fcnt <= fend; fcnt += finc) // loop thru file sequence numbers
		
		CurrentFile = SeqNumSet(CurrentFile, iSeqBgn, iseqend, fcnt)
		
		setList = NMSetsList(1) // save list of Sets before appending

		if (StringMatch(CurrentFile, "overflow") == 1)
			DoAlert 0, "Error: overflow of file sequence number: " + num2str(fcnt)
			continue
		endif
		
		if (FileExists(CurrentFile) == 0)
			DoAlert 0, CurrentFile + " does not exist."
			continue
		endif
		
		CurrentWave = NumWaves
		
		success = NMImportFileManager(FileType, "header") // read data header
		
		WaveInc = 1; WaveBeg = 1; WaveEnd = TotalNumWaves/NumChannels
		
		if (FilePromptFlag == 1)
			NMImportPanel()
		endif
		
		if (success == 0)
			continue
		endif
		
		NumWaves += NMImportFileManager(fileType, "data") // read data
		
		PrintFileDetails(NumWaves)
		
		CheckNMwave(setList, NumVarOrDefault("NumWaves", 0), 0) // redimension old Sets
		NMSetsDataNew() // create Set_Data wave
		
	endfor
	
	CurrentWave = 0
	
	Duplicate /O saveYLabel yLabel
	
	KillWaves /Z saveYLabel

End // NMImportFileAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function PrintFileDetails(nwaves)
	Variable nwaves // number of waves read; (-1) to use NumWaves
	
	String txt
	Variable chncnt, scale
	
	Variable NumWaves = NumVarOrDefault("NumWaves", Nan)
	Variable NumChannels = NumVarOrDefault("NumChannels", Nan)
	
	if (nwaves == -1)
		nwaves = NumWaves
	endif
	
	NMHistory("Data File: " + StrVarOrDefault("CurrentFile", "Unknown Data File"))
	NMHistory("File Type: " + StrVarOrDefault("DataFileType", "Unknown"))
	NMHistory("Acquisition Mode: " + StrVarOrDefault("AcqMode", "Unknown"))
	NMHistory("Number of Channels: " + num2str(NumVarOrDefault("NumChannels", Nan)))
	NMHistory("Waves per Channel: " + num2str(nwaves))
	NMHistory("Samples per Wave: " + num2str(NumVarOrDefault("SamplesPerWave", Nan)))
	NMHistory("Sample Interval (ms): " + num2str(NumVarOrDefault("SampleInterval", Nan)))
	
	if (WavesExist("FileScaleFactors;MyScaleFactors") == 0)
		return 0
	endif
	
	Wave FileScaleFactors, MyScaleFactors
	
	for (chncnt = 0; chncnt < NumChannels; chncnt += 1)
		txt = "Chan " + ChanNum2Char(chncnt) + " Scale Factor: " + num2str(FileScaleFactors[chncnt])
		scale = MyScaleFactors[chncnt]
		if (scale != 1)
			txt += " * " + num2str(scale)
		endif
		NMHistory(txt)
	endfor

End // PrintFileDetails

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Import File Panel
//		(panel called to request user input)
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportPanel() // Bring up "Load File Panel" to request user information

	if (CheckCurrentFolder() == 0)
		return 0
	endif

	Variable x1, x2, y1, y2, amode
	Variable tablewidth = 300, panelwidth = 390
	Variable xPixels = NumVarOrDefault(NMDF() + "xPixels", 1000)
	
	String Computer = StrVarOrDefault(NMDF() + "Computer", "mac")
	
	NVAR NumChannels, TotalNumWaves, SamplesPerWave, SampleInterval
	NVAR WaveBeg, WaveEnd, WaveInc, FileBeg, FileEnd, FileInc
	
	SVAR FileName, AcqMode
	
	x1 = (xPixels/2)+(panelwidth/2)+16
	y1 = 142
	
	if (StringMatch(Computer, "pc") == 1)
		x1 = 630
		y1 = 115
	endif
	
	x2 = x1 + tablewidth
	y2 = y1 + 345
	
	DoWindow /K ImportTable
	Edit /K=1/W=(x1,y1,x2,y2) YLabel, MyScaleFactors
	DoWindow /C ImportTable
	DoWindow /T ImportTable, "Check Channel Details"
	Execute /Z "ModifyTable title(Point)= \"Channel\""
	
	x1 = (xPixels/2)-(panelwidth/2)
	y1 = 142
	x2 = x1 + panelwidth
	y2 = 487
	
	DoWindow /K ImportPanel
	NewPanel /W=(x1,y1,x2,y2) as "Check File Details"
	DoWindow /C ImportPanel
	
	amode = str2num(AcqMode[0])
	
	SetDrawEnv fsize= 18
	DrawText 20,30, "File:  " + FileName
	
	SetVariable NumChannelSet, title="Number of Channels: ", limits={1,10,0}, pos={20,50}, size={180,50}, frame=0, value=NumChannels, win=ImportPanel, proc=NMImportSetVariable
	SetVariable SampIntSet, title="Sample Interval (ms):  ", limits={0,10,0}, pos={20,75}, size={250,50}, frame=0, value=SampleInterval, win=ImportPanel
	
	SetVariable SPSSet, title="Samples/Wave:  ", limits={0,inf,0}, pos={20,100}, size={250,50}, frame=0, value=SamplesPerWave, win=ImportPanel
	
	//SetDrawEnv fsize= 14
	DrawText 20,145, "Acquisition mode: " + AcqMode
	
	SetVariable WaveBegSet, title="wave beg: ", limits={1,TotalNumWaves,0}, pos={20,185}, size={160,60}, frame=1, value=WaveBeg, win=ImportPanel
	SetVariable WaveEndSet, title="wave end: ", limits={1,TotalNumWaves,0}, pos={20,215}, size={160,60}, frame=1, value=WaveEnd, win=ImportPanel
	SetVariable WaveIncSet, title="wave inc:  ", limits={1,TotalNumWaves,0}, pos={20,245}, size={160,60}, frame=1, value=WaveInc, win=ImportPanel
	SetVariable WaveIncSet, title="wave prefix:  ", pos={20,245}, size={160,60}, frame=1, value=WavePrefix, win=ImportPanel
	
	if ((amode != 3) && (FileInc == -1))
		SetVariable FileBegSet, title="file beg: ", limits={FileBeg,FileBeg,0}, pos={210,185}, size={140,70}, frame=1, value=FileBeg, disable=1, win=ImportPanel
		SetVariable FileEndSet, title="file end: ", limits={FileBeg,inf,0}, pos={210,215}, size={140,70}, frame=1, value=FileEnd, disable=1, win=ImportPanel, proc=NMImportSetVariable
		SetVariable FileIncSet, title="file Inc: ", limits={1,inf,0}, pos={210,245}, size={140,70}, frame=1, value=FileInc, disable = 1, win=ImportPanel
		CheckBox FileSeqCheck, title="open file sequence", value=0, pos={190,155}, size={16,18}, win=ImportPanel, proc=NMImportSeqCheck
		CheckBox FilePromptCheck, title="file details prompt on", value=1, pos={190,275}, size={16,18}, disable=1, win=ImportPanel, proc=NMImportSeqCheck
	endif
	
	Button AbortButton, title="Abort", pos={110,305}, size={50,20}, win=ImportPanel, proc=NMImportFinish
	Button ContinueButton, title="Open File", pos={210,305}, size={80,20}, win=ImportPanel, proc=NMImportFinish
	
	PauseForUser ImportPanel, ImportTable

End // NMImportPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportFinish(ctrlName) : ButtonControl
	String ctrlName
	
	if (StringMatch(ctrlName, "AbortButton") == 1)
		SetNMvar("WaveInc", -1)
	endif
	
	DoWindow /K ImportPanel
	DoWindow /K ImportTable

End // NMImportFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr, varName
	
	Variable chncnt
	
	strswitch(ctrlName)
	
		case "NumChannelSet":
			NVAR NumChannels, TotalNumWaves, WaveEnd
			Wave FileScaleFactors, MyScaleFactors
			Wave /T YLabel
			WaveEnd = TotalNumWaves / NumChannels
			Redimension /N=(NumChannels) MyScaleFactors
			Redimension /N=(NumChannels) YLabel
			for (chncnt = 1; chncnt < NumChannels; chncnt += 1)
				if (MyScaleFactors[chncnt] == 0)
					MyScaleFactors[chncnt] = 1
				endif
				YLabel[chncnt] = "mV"
			endfor
			break
			
		case "FileEndSet":
			NVAR FileEnd
			SetVariable FileIncSet, limits={1,FileEnd,0}
			break
		
	endswitch

End // NMImportSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportSeqCheck(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR FileBeg, FileEnd, FileInc
	SVAR CurrentFile
	
	Variable FilePromptFlag = NumVarOrDefault("FilePromptFlag", 1)
	
	strswitch(ctrlName)
		case "FileSeqCheck":
			
			if (checked == 1)
				FileBeg = SeqNumFind(CurrentFile)
				FileEnd = FileBeg
				FileInc = 1 // load a sequence of files
				if (numtype(FileBeg) > 0)
					FileInc = -1 // probably no seq num
				endif
				FilePromptFlag = 1
			else
				FileInc = -1 // dont load a sequence of files
			endif
			
			SetVariable FileBegSet, disable = (!checked)
			SetVariable FileEndSet, disable = (!checked)
			SetVariable FileIncSet, disable = (!checked)
			CheckBox FilePromptCheck, disable = (!checked), value=FilePromptFlag
			
			break
			
		case "FilePromptCheck":
			SetNMvar("FilePromptFlag", checked)
			break
	
	endswitch
	
End // NMImportSeqCheck

//****************************************************************
//****************************************************************
//****************************************************************
//
//	File utility functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMPath() // find path to NeuroMatic Procedure folder

	Variable icnt
	String flist, fname, igor, path = ""
	
	Variable /G V_isAliasShortcut
	String /G S_aliasPath
	
	PathInfo NMPath
	
	if (V_flag == 1)
		return S_path
	endif

	PathInfo Igor
	
	if (V_flag == 0)
		return ""
	endif
	
	igor = S_path + "Igor Procedures:"
	
	NewPath /O/Q NMPath, igor
	
	flist = IndexedDir(NMPath, -1, 0) // look for NM folder
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		fname = StringFromList(icnt, flist)
		
		if (StrSearchLax(fname, "NeuroMatic", 0) >= 0)
			path = igor + fname + ":" // found it
			break
		endif
		
	endfor
	
	if (strlen(path) == 0) // try to locate NM alias
	
		flist = IndexedFile(NMPath, -1, "????")
		
		for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		
			fname = StringFromList(icnt, flist)
			
			if (StrSearchLax(fname, "NeuroMatic", 0) >= 0)
			
				if (IgorVersion() < 5)
					DoAlert 0, "NM path cannot be determined. Try putting NM folder (rather than alias) in Igor Procedures folder."
					break
				endif
				
				Execute "GetFileFolderInfo /P=NMPath/Q/Z \"" + fname + "\"" // Igor 5 only
				
				if (V_isAliasShortcut == 1)
					path = S_aliasPath
					break
				endif
				
			endif
			
		endfor
	
	endif
	
	NewPath /O/Q NMPath, path
	
	PathInfo /S Igor
	
	return path

End // CheckNMPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FileDialogue(dialType, pathname, file, ext)
	Variable dialType // (0) open (1) save
	String pathname // symbolic path name
	String file // for save dialogue
	String ext // file extension; ("") for FileBinExt (?) for any

	Variable refnum
	String type = "????"
	
	if (strlen(ext) == 0)
		ext = FileBinExt()
	endif
	
	if (strlen(file) == 0)
		dialType = 0
	else
		file = FileExtCheck(file, ext, 1) // check extension exists
	endif
	
	strswitch(ext)
		case ".pxp":
			type = "IGsU????"
			break
		case ".txt":
			type = "TEXT"
	endswitch
	
	PathInfo /S $pathName

	if (dialType == 0)
		Open /R/D/T=type refnum
	else
		Open /D/T=type refnum as GetPathName(file, 0)
	endif
	
	if (StringMatch(S_fileName, "") == 1)
		return "" // no file name
	endif
	
	return S_fileName // return file name

End // FileDialogue

//****************************************************************
//****************************************************************
//****************************************************************

Function FileExists(file) // determine if file exists
	String file // file name
	
	Variable refnum
	
	if (strlen(file) == 0)
		return 0
	endif
	
	Open /Z=1/R/T="????" refnum as file
	
	if (refnum == 0)
		return 0 // no, file does not exist
	else
		Close refnum
		return 1 // yes, file exists
	endif

End // FileExists

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FilePathCheck(pathName, file) // combine path and file name
	String pathName, file
	
	PathInfo /S $pathName
	
	if (V_Flag == 1)
		return S_path + GetPathName(file, 0)
	else
		return file
	endif

End // FilePathCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FileExtCheck(istring, ext, yes)
	String istring // string value, such as file name "myfile.txt"
	String ext // file extension such as ".txt"; (".*") for any ext
	Variable yes // (0) has no extension (1) has extension
	
	Variable icnt, ipnt = -1, sl = strlen(ext)
	
	for (icnt = strlen(istring) - 1; icnt >= 0; icnt -= 1)
		if (StringMatch(istring[icnt,icnt], ".") == 1)
			ipnt = icnt
		endif
		if (StringMatch(istring[icnt,icnt], ":") == 1)
			break
		endif
	endfor
	
	switch(yes)
	
		case 0:
			if ((StringMatch(ext, ".*") == 1) && (ipnt >= 0)) // any extension
				istring = istring[0,ipnt-1] // remove extension
			elseif (StringMatch(istring[strlen(istring)-sl,inf], ext) == 1)
				istring = istring[0,strlen(istring)-sl-1] // remove extension
			endif
			break
			
		case 1:
			if (ipnt >= 0)
				istring = istring[0,ipnt-1] + ext // replace extension
			else
				istring += ext // add extension
			endif
			break
			
		default:
			return ""
			
	endswitch

	return istring

End // FileExtCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function SeqNumFind(file) // determine file sequence number, and its string index boundaries
	String file // file name
	
	Variable icnt, ibeg, iend, seqnum = Nan
	
	for (icnt = strlen(file)-1; icnt >= 0;  icnt -= 1)
		if (numtype(str2num(file[icnt])) == 0)
			break // first appearance of number, from right
		endif
	endfor
	
	iend = icnt
	
	for (icnt = iend; icnt >= 0;  icnt -= 1)
		if (numtype(str2num(file[icnt])) == 2)
			break // last appearance of number, from right
		endif
	endfor
	
	ibeg = icnt+1
	
	seqnum = str2num(file[ibeg, iend])
	
	Variable /G iSeqBgn = ibeg	// store begin/end placement of seq number
	Variable /G iSeqEnd = iend
	
	return seqnum

End // SeqNumFind

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SeqNumStr(file) // get file sequence number as string
	String file // file name
	
	Variable icnt, ibeg, iend, seqnum = Nan
	
	for (icnt = strlen(file)-1; icnt >= 0;  icnt -= 1)
		if (numtype(str2num(file[icnt, icnt])) == 0)
			break // first appearance of number, from right
		endif
	endfor
	
	iend = icnt
	
	for (icnt = iend; icnt >= 0;  icnt -= 1)
		if (numtype(str2num(file[icnt, icnt])) == 2)
			break // last appearance of number, from right
		endif
	endfor
	
	ibeg = icnt + 1
	
	return file[ibeg, iend]

End // SeqNumStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SeqNumSet(file, ibeg, iend, seqnum) // create new file name, with new sequence number
	String file // original file name
	Variable ibeg // begin string index of sequence number (iSeqBgn)
	Variable iend // end string index of sequence number (iSeqEnd)
	Variable seqnum // new sequence number
	
	Variable icnt, jcnt
	
	icnt = iend - ibeg + 1
	
	jcnt = strlen(num2str(seqnum))
	
	if (jcnt <= icnt)
		ibeg = iend - jcnt + 1
		file[ibeg,iend] = num2str(seqnum)
	else
		file = "overflow" // new sequence number does not fit within allowed index boundaries
	endif
	
	return file

End // SeqNumSet

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Binary object file functions defined below...
// 	Igor 4 : NeuroMatic binary files
//	Igor 5 : Igor 5 packed binary files
//
//****************************************************************
//****************************************************************
//****************************************************************

Function FileBinType()

	if ((IgorVersion() >= 5) && (exists("LoadData") == 4) && (exists("SaveData") == 4))
		return 1 // Igor 5 binary file
	else
		return 0 // NM binary file
	endif

End // FileBinType

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FileBinExt()

	if (FileBinType() == 1)
		return ".pxp"
	else
		return ".nmb"
	endif

End // FileBinExt

//****************************************************************
//****************************************************************
//****************************************************************

Function FileBinLoadCurrent()

	NVAR WaveBeg, WaveEnd, WaveInc

	if (DataFolderExists("root:OpenFileTemp:") == 0)
		NewDataFolder /O root:OpenFileTemp
	endif

	String CurrentFile = StrVarOrDefault("CurrentFile", "")
	
	String folder = FileBinOpen(0, 1, "root:OpenFileTemp:", "", CurrentFile, 1)
	
	if (DataFolderExists("root:OpenFileTemp:") == 1)
		KillDataFolder root:OpenFileTemp:
	endif

End // FileBinLoadCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function FileBinOpenHook(refNum, fileName, path, type, creator, kind)
	
	Variable refNum,kind
	String fileName,path,type,creator
	
	if (StringMatch(type,"IGsU") == 1) // Igor Experiment, packed
		CheckFileOpen(fileName)
	endif
	
	return 0					// 1 tells Igor not to open the file
	
End // FileBinOpenHook

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckFileOpen(fileName) // check to see if file opened was NM folder
	String fileName
	
	if (StringMatch(GetDataFolder(0), "root") == 0)
		return "" // not in root directory
	endif
	
	if (strlen(fileName) == 0)
		fileName = StrVarOrDefault("FileName", "")
	endif

	if (StringMatch(StrVarOrDefault("FileType", ""), "NMData") == 1)
		return FileOpenFix2NM(fileName) // move everything to subfolder
	else
		return ""
	endif

End // FileOpenCheck

//****************************************************************
//****************************************************************
//****************************************************************
//
//   FileOpenFix2NM :  this program fixes NM folders which were
//   opened by double-clicking NM pxp folder, which Igor places
//   in root directory
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S FileOpenFix2NM(fileName) // move opened NM folder to new subfolder
	String fileName
	
	Variable icnt
	String list, name
	
	if (strlen(fileName) == 0)
		return "" // not allowed
	endif

	String folder //= "root:" + FolderNameCreate(fileName)
	
	folder = "root:" + WinName(0, 0)
	
	folder = CheckFolderName(folder) // get unused folder name

	if (DataFolderExists(folder) == 1)
		return "" // not allowed
	endif
	
	list = FolderObjectList("", 4) // df
	
	list = RemoveFromList("WinGlobals;Packages;", list)
	
	NewDataFolder /O $LastPathColon(folder, 0)
	
	for (icnt = 0; icnt < ItemsInList(list); icnt += 1)
		MoveDataFolder $StringFromList(icnt, list), $folder
	endfor
	
	list = FolderObjectList("", 1) // waves
	
	for (icnt = 0; icnt < ItemsInList(list); icnt += 1)
		name = StringFromList(icnt, list)
		MoveWave $name, $(LastPathColon(folder, 1) + name)
	endfor
	
	list = FolderObjectList("", 2) // variables
	
	for (icnt = 0; icnt < ItemsInList(list); icnt += 1)
		name = StringFromList(icnt, list)
		MoveVariable $name, $(LastPathColon(folder, 1) + name)
	endfor
	
	list = FolderObjectList("", 3) // strings
	
	for (icnt = 0; icnt < ItemsInList(list); icnt += 1)
		name = StringFromList(icnt, list)
		MoveString $name, $(LastPathColon(folder, 1) + name)
	endfor
	
	NMFolderChange( folder )
	
	return folder
	
End // FileOpenFix2NM

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FileBinOpen(dialogue, new, folder, pathName, file, changeFolder)
	Variable dialogue // (0) no (1) yes
	Variable new // (0) over-write existing folder (1) create new folder
	String folder // data folder path where to open folder; ("") for "root:"
	String pathName // symbolic path name
	String file // external file name
	Variable changeFolder // change to this folder after opening file (0) no (1)

	Variable numwaves, numchans, bintype = FileBinType()
	String vlist = "", df, dtype, ndf = NMDF()
	
	file = FilePathCheck(pathName, file)

	if ((dialogue == 0) && (FileExists(file) == 0))
		return "" // file doesnt exist
	endif
	
	if (dialogue == 1)
		file = FileDialogue(0, pathName, "", "")
	endif

	if (strlen(file) == 0)
		return "" // cancel
	endif
	
	if (strlen(folder) == 0)
	
		folder = "root:"
		
	else
	
		folder = LastPathColon(folder,1) + FolderNameCreate(file) // create folder name
	
		if (DataFolderExists(folder) == 1)
		
			DoAlert 2, "Folder \"" + GetPathName(folder, 0) + "\" already exists in directory \"" + GetPathName(folder, 1) + "\". Do you want to replace it?"
			
			if (V_Flag == 1)
				NMFolderClose(folder)
			elseif (V_Flag == 3)
				return ""
			endif
			
		endif
	
	endif
	
	if (changeFolder == 1) //&& (IsNMDataFolder(folder) == 1))
		//NMFolder0Close() // close default folder if open and empty
		NMSetsTable(-1) // remove Set waves
		NMGroupsTable(-1) // remove Group waves
	endif
	
	if (strlen(NMBinFileType(file)) > 0)
		bintype = 0
	endif

	if (bintype == 1)
	
		NMProgressStr("Opening Igor Binary File...")
	
		CallProgress(-1)
		CallProgress(-2)
		
		vlist = NMCmdStr(folder, vlist)
		vlist = NMCmdStr(file, vlist)
		vlist = NMCmdNum(changeFolder, vlist)
		NMCmdHistory("IgorBinOpen", vlist)
	
		folder = IgorBinOpen(folder, file, changeFolder) // Igor 5 LoadData
	
	else
	
		NMProgressStr("Opening NM Binary File...")
	
		CallProgress(-1)
		CallProgress(-2)
	
		vlist = NMCmdStr(folder, vlist)
		vlist = NMCmdStr(file, vlist)
		vlist = NMCmdStr("1111", vlist)
		vlist = NMCmdNum(changeFolder, vlist)
		NMCmdHistory("NMBinOpen", vlist)
	
		folder = NMBinOpen(folder, file, "1111", changeFolder)
		
	endif
	
	CheckNMDataNotes()
	
	CallProgress(1)

	return folder
	
End // FileBinOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FileBinOpenAll(dialogue, df, pathName)
	Variable dialogue // (0) no (1) yes
	String df // data folder path ("") for "root:"
	String pathName // Igor path name
	
	Variable icnt, add, nfiles, change = 1
	String file, fname, slist, folder, pathStr, flist = "", olist = ""
	
	if ((dialogue == 1) || (strlen(pathName) == 0))
	
		file = FileDialogue(0, pathName, "", "")
		
		if (strlen(file) == 0)
			return "" // cancel
		endif
		
		pathStr = GetPathName(file, 1)
		fname = GetPathName(file, 0)
		
	else
	
		PathInfo $pathName
		
		if (strlen(S_path) == 0)
			return ""
		endif
		
		pathStr = S_path
	
	endif
	
	NewPath /Q/O OpenAllPath, pathStr
	
	slist = IndexedFile(OpenAllPath,-1,"????")
	
	nfiles = ItemsInList(slist)
	
	if (nfiles == 0)
		return ""
	endif
	
	for (icnt = 0; icnt < nfiles; icnt += 1)
	
		file = StringFromList(icnt, slist)
		
		if (StringMatch(file, fname) == 1)
			add = 1
		endif
		
		if (add == 1)
			olist = AddListItem(file, olist, ";", inf)
		endif
		
	endfor
	
	slist = olist
	
	nfiles = ItemsInList(slist)
	
	if (dialogue == 1)
	
		nfiles -= 1
		Prompt nfiles, "Located " + num2str(nfiles) + " files after " + fname + ". How many do you wish to open?"
		DoPrompt "Open Files", nfiles
		
		if (V_flag == 1)
			return ""
		endif
		
		nfiles += 1
		
	endif
	
	if (strlen(df) == 0)
		df = "root:"
	endif
	
	for (icnt = 0; icnt < nfiles; icnt += 1)
	
		file = StringFromList(icnt, slist)
		folder = FileBinOpen(0, 1, df, "OpenAllPath", file, change)
		flist = AddListItem(folder, flist, ";", inf)
		// change = 0
	
	endfor
	
	return flist

End // FileBinOpenAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FileBinSave(dialogue, new, folder, pathName, file, closed, bintype)
	Variable dialogue // (0) no (1) yes
	Variable new // (0) over-write existing file (1) create new file
	String folder // data folder to save; ("") for current data folder
	String pathName // symbolic path name
	String file // external file name; "" to create filename based on folder name
	Variable closed // (0) save unclosed (1) save closed (NM binary files only; allows appending)
	Variable bintype // (0) NM binary (1) Igor binary (-1) use FileBinType() to determine
	
	// be careful when using dialogue = 0, new = 0 since this will over-write existing file
	
	Variable kill
	String vlist = "", ndf = NMDF()
	
	if (bintype == -1)
		bintype = FileBinType()
	endif
	
	if (strlen(folder) == 0)
		folder = GetDataFolder(1)
	elseif (DataFolderExists(folder) == 0)
		return ""
	endif
	
	if (new == 0)
		file = StrVarOrDefault(LastPathColon(folder,1)+"CurrentFile", "")
		pathName = ""
	endif
	
	if (strlen(file) == 0)
		file = FolderNameCreate(folder)
	endif
	
	if (strlen(file) > 0)
	
		if (strlen(pathName) > 0)
			
			PathInfo /S $pathName
	
			if (strlen(S_path) == 0)
				dialogue = 1
			endif
		
		endif
	
		file = FilePathCheck(pathName, file)
	
		if (bintype == 1)
			file = FileExtCheck(file, ".pxp", 1) // force this ext
		else
			file = FileExtCheck(file, ".nmb", 1) // force this ext
		endif
	
	endif
	
	if ((new == 0) && (FileExists(file) == 0))
		dialogue = 1
	elseif ((new == 1) && (FileExists(file) == 1))
		dialogue = 1
	endif
	
	if (dialogue == 1)
		if (bintype == 1)
			file = FileDialogue(1, pathName, file, ".pxp")
		else
			file = FileDialogue(1, pathName, file, ".nmb")
		endif
	endif
	
	
	
	if ((strlen(folder) == 0)  || (strlen(file) == 0))
		return ""
	endif
	
	if (bintype == 1) // Igor binary

		if (FileBinType() == 1)
			
			vlist = NMCmdStr(folder, vlist)
			vlist = NMCmdStr(file, vlist)
			NMCmdHistory("IgorBinSave", vlist)
		
			file = IgorBinSave(folder, file) // Igor 5 SaveData
			
		else
		
			SaveExperiment as file // Igor 4
			
		endif
		
		if (strlen(folder) > 0)
			NMHistory("Saved folder \"" + folder + "\" to Igor binary file \"" + file + "\"")
		endif
		
	elseif (bintype == 0) // NM binary
	
		if (IsNMDataFolder(folder) == 1) // special save function here
			
			vlist = NMCmdStr(folder, vlist)
			vlist = NMCmdStr(file, vlist)
			vlist = NMCmdNum(closed, vlist)
			NMCmdHistory("NMBinSaveSpecial", vlist)
			
			file = NMBinSaveSpecial(folder, file, closed) // save waves in Data subfolder
			
		else
			
			vlist = NMCmdStr(folder, vlist)
			vlist = NMCmdStr(file, vlist)
			vlist = NMCmdStr("1111", vlist)
			vlist = NMCmdNum(closed, vlist)
			NMCmdHistory("NMBinSave", vlist)
		
			file = NMBinSave(folder, file, "11111", closed)  // standard NM binary file
			
		endif
		
		if ((strlen(folder) > 0) && (new == 1))
			NMHistory("Saved folder \"" + folder + "\" to NeuroMatic binary file \"" + file + "\"")
		endif
		
	endif

	SetNMstr(LastPathColon(folder,1)+"CurrentFile", file)
	
	return file
	
End // FileBinSave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMBin2IgorCall()

	if (FileBinType() == 0)
		DoAlert 0, "Sorry, this is an Igor 5 function."
		return -1
	endif

	Variable select
	String path, file, vlist = ""
	
	file = FileDialogue(0, "OpenDataPath", "", ".nmb")

	if (strlen(file) == 0)
		return -1
	endif
	
	path = GetPathName(file, 1)
	file = GetPathName(file, 0)
	
	Prompt select " ", popup "convert this file;convert all files in this directory;"
	DoPrompt "Convert Old NeuroMatic File to New Format", select
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	if (select == 2) // all files
		file = IndexedFile(OpenDataPath,-1,"????")
	endif
	
	vlist = NMCmdStr(path, vlist)
	vlist = NMCmdStr(file, vlist)
	NMCmdHistory("NMBin2Igor", vlist)
	
	NMBin2Igor(path, file) // this folder only

End // NMBin2IgorCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMBin2Igor(path, flist) // open NM bin file and save as Igor bin file
	String path // path
	String flist // file list

	Variable icnt
	String file, oname, sname, folder
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		file = path + StringFromlist(icnt, flist)
		
		folder = "root:" + FolderNameCreate(file) // get folder name
		folder = CheckFolderName(folder) // get unused folder name
		
		if (strlen(folder) == 0)
			return 0 // cancel
		endif
		
		oname = NMBinOpen(folder, file, "1111", 0)
		
		if (strlen(oname) == 0)
			continue // cancel
		endif
		
		sname = FileBinSave(0, 1, oname, "OpenDataPath", GetPathName(oname, 0), 1, 1)
		
		if (strlen(sname) > 0)
			NMHistory("Converted NM binary file \"" + file + "\" to Igor binary file \"" + sname + "\"")
		endif
		
		NMFolderClose(oname) // close opened file
	
	endfor

End // NMBin2Igor

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Igor binary object file functions defined below...
//	requires Igor 5 LoadData and SaveData
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S IgorBinOpen(folder, file, changeFolder) // open Igor packed binary file
	String folder // data folder path where to open folder, ("") or ("root:") to auto create in root
	String file // external file name
	Variable changeFolder // change to this folder after opening file (0) no (1)
	
	if ((strlen(folder) == 0) || (StringMatch(folder, "root:") == 1))
		folder = "root:" + FolderNameCreate(file)
	endif
	
	folder = CheckFolderName(folder) // get unused folder name

	if (DataFolderExists(folder) == 1)
		return "" // not allowed
	endif
	
	if (strlen(file) == 0)
		return "" // not allowed
	endif

	String saveDF = GetDataFolder(1)
	NewDataFolder /O/S $LastPathColon(folder, 0)
	Execute "LoadData /O/Q/R \"" + file + "\""
	
	SetNMstr("DataFileType", "IgorBin")
	SetNMstr("FileName", GetPathName(file, 0))
	SetNMstr("CurrentFile", file)
	
	String ftype = StrVarOrDefault("FileType", "")
	
	NMHistory("Opened Igor binary file \"" + file + "\" to folder \"" + folder + "\"")
	
	if (StringMatch(ftype, "NMLog") == 1)
		Execute "LogDisplayCall(\"" + folder + "\")"
		changeFolder = 0
	endif
	
	if (changeFolder == 0)
	
		SetDataFolder $saveDF // back to original data folder
		
	elseif (StringMatch(ftype, "NMData") == 1)
	
		NMFolderListAdd(folder)
		NMFolderChange(folder)
		CheckNMDataFolder()
		NMSetsDataNew()
		PrintFileDetails(-1)
		
		if (NumVarOrDefault(NMDF()+"AutoPlot", 0) == 1)
			NMPlot( "" )
		endif
		
	endif
	
	return folder
	
End // IgorBinOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S IgorBinSave(folder, file) // save Igor packed binary file
	String folder // data folder to save
	String file // external file name
	
	// Please use FileBinSave to call this function
	// since this function will over-write existing file
	// BE CAREFUL!!!!!
	
	if (DataFolderExists(folder) == 0)
		return ""
	endif
 
 	//String /G S_path
	String saveDF = GetDataFolder(1)
	
	SetDataFolder $folder
	Execute "SaveData /O/Q/R \"" + file + "\""
	
	//if (strlen(S_path) > 0)
	//	file = S_path
	//endif
	
	KillStrings /Z S_path
	KillVariables /Z V_Flag
	
	SetDataFolder $saveDF
	
	return file

End // IgorBinSave

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic binary object file functions defined below...
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBinOpen(folder, file, makeflag, changeFolder)
	String folder // folder name where file objects are loaded, ("") or ("root:") to auto create folder in root 
	String file // external file name
	String makeflag // text waves | numeric waves  | numeric variables | string variables
	Variable changeFolder // change to this folder after opening file (0) no (1)
	
	if ((strlen(folder) == 0) || (StringMatch(folder, "root:") == 1))
		folder = "root:" + FolderNameCreate(file)
	endif
	
	folder = CheckFolderName(folder) // get unused folder name
	
	if (DataFolderExists(folder) == 1)
		return "" // folder must not exist
	endif
	
	if (strlen(file) == 0)
		return "" // not allowed
	endif
	
	if ((FileExists(file) == 0) || (strlen(NMBinFileType(file)) == 0))
		DoAlert 0, "Error: file \"" + file + "\" is not a NeuroMatic binary file."
		return "" // not a NM binary file
	endif

	String saveDF = GetDataFolder(1) // save current directory
	NewDataFolder /O/S $LastPathColon(folder, 0) // open new folder
	NMBinReadObject(file, makeflag) // read data
	
	SetDataFolder folder
	
	SetNMstr("DataFileType", "NMBin")
	SetNMstr("FileName", GetPathName(file, 0))
	SetNMstr("CurrentFile", file)
	
	NMHistory("Opened NeuroMatic binary file \"" + file + "\" to folder \"" + folder + "\"")
	
	String df = LastPathColon(folder, 1) + "Data"
	String ftype = StrVarOrDefault("FileType", "")
	
	strswitch(ftype)
	
		case "NMLog":
			Execute "LogDisplayCall(\"" + folder + "\")"
			changeFolder = 0
			break
			
		case "NMData":
			
			if (DataFolderExists(df) == 1)
			
				// folder was created by Clamp tab
				// waves stored in folder "Data"
				
				CopyWavesTo(df, folder, "", -inf, inf, "", 0)
				
				if (CountObjects(df,1) == 0)
					KillDataFolder df
				endif
				
			endif
			
			break
			
	endswitch
	
	if (changeFolder == 0)
	
		SetDataFolder saveDF // back to original data folder
		
	elseif (StringMatch(ftype, "NMData") == 1)
	
		NMFolderListAdd(folder)
		NMFolderChange(folder)
		CheckNMDataFolder()
		NMSetsDataNew()
		UpdateNM(1)
		PrintFileDetails(-1)
		
		if (NumVarOrDefault(NMDF()+"AutoPlot", 0) == 1)
			NMPlot( "" )
		endif
		
	
	endif
	
	return folder
	
End // NMBinOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBinSave(folder, file, writeflag, closed)
	String folder // data folder name
	String file // external file name
	String writeflag // string variables | numeric variables  | text waves | numeric waves | daughter folders
	// "11111" to write all
	// "00011" to write numeric waves, all folders
	Variable closed // (0) save unclosed (1) save and close

	Variable ocnt
	String objName, olist
	
	if (strlen(folder) == 0)
		return ""
	endif
	
	if (DataFolderExists(folder) == 0)
		DoAlert 0, "Data folder \"" + folder + "\" does not exist."
		return ""
	endif

	String saveDF = GetDataFolder(1) // save current directory
	
	folder = LastPathColon(folder, 0) // remove trailing colon
	
	SetDataFolder folder
	
	NMBinWriteObject(file, 1, "") // open new
	
	NMBinSaveGlobals(file, writeflag)
	
	olist = FolderObjectList("", 4) // sub-folder list

	if (StringMatch(writeflag[4,4], "1") == 1)
		for (ocnt =0; ocnt < ItemsInList(olist); ocnt += 1) // loop thru sub-folders
			objName = StringFromList(ocnt, olist)
			NMBinWriteObject(file, 2, objName)
			SetDataFolder folder + ":" + objName
			NMBinSaveGlobals(file, writeflag)
			SetDataFolder folder
		endfor
	endif
	
	if (closed == 1)
		NMBinWriteObject(file, 3, "") // close
	endif
	
	SetDataFolder saveDF // back to original data folder
	
	return file
	
End // NMBinSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBinSaveSpecial(folder, file, closed) // creates a Data subfolder to hold data waves
	String folder, file
	Variable closed
	
	Variable kill

	if (DataFolderExists("Data") == 0)
		NewDataFolder /O Data // create an empty data folder
		// upon opening, data waves will appear in Data sub-folder
		kill = 1
	endif
	
	if (closed == 0)
	
		NMBinSave(folder, file, "11111", 0) // NM binary file unclosed
	
	elseif (closed == 1)
	
		file = NMBinSave(folder, file, "11121", 0) // save all except data waves, unclosed
		
		if (strlen(file) > 0)
			NMBinSaveGlobals(file, "0003") // save data waves last
			NMBinWriteObject(file, 3, "") // EOF marker, close file
		endif
		
	endif
	
	if (kill == 1)
		KillDataFolder Data
	endif
	
	return file

End // NMBinSaveSpecial

//****************************************************************
//****************************************************************
//****************************************************************

Function NMBinSaveGlobals(file, writeflag)
	String file // external file name
	String writeflag // string variables | numeric variables  | text waves | numeric waves
	// number waves (0) dont write (1) write all waves (2) all waves except data waves (3) only data waves

	Variable ocnt, icnt, wflag
	String objName, olist, clist = ""
	
	if (WaveExists(ChanWaveList) == 1)
	
		Wave /T ChanWaveList // data wave names
	
		for (icnt = 0; icnt < numpnts(ChanWaveList); icnt += 1)
			clist += ChanWaveList[icnt] // data wave list
		endfor
		
	endif
	
	if (StringMatch(writeflag[0,0], "1") == 1) // string variables
	
		olist = FolderObjectList("", 3)
		
		if (WhichListItemLax("FileType", olist, ";") > 0) // make sure FileType is first
			olist = RemoveFromList("FileType", olist)
			olist = AddListItem("FileType", olist) // add back to beginning of list
		endif
		
		NMBinWriteObject(file, 2, olist)
	
	endif
	
	if (StringMatch(writeflag[1,1], "1") == 1) // numeric variables
		olist = FolderObjectList("", 2)
		NMBinWriteObject(file, 2, olist)
	endif
	
	if (StringMatch(writeflag[2,2], "1") == 1) // text waves
		olist = FolderObjectList("", 6)
		NMBinWriteObject(file, 2, olist)
	endif
	
	wflag = str2num(writeflag[3,3])
	
	if (wflag > 0) // numeric waves
	
		olist = FolderObjectList("", 5)
		
		if (wflag > 1) // subset of waves
		
			for (ocnt = 0; ocnt < ItemsInlist(olist); ocnt += 1)
			
				objName = StringFromList(ocnt, olist)
				
				if ((wflag == 2) && (WhichListItemLax(objName, clist, ";") >= 0))
					olist = RemoveFromList(objName, olist) // except data waves
				elseif ((wflag == 3) && (WhichListItemLax(objName, clist, ";") < 0))
					olist = RemoveFromList(objName, olist) // only data waves
				endif
			
			endfor
		
		endif

		NMBinWriteObject(file, 2, olist)
	
	endif
	
End // NMBinSaveGlobals

//****************************************************************
//****************************************************************
//****************************************************************

Function NMBinWriteObject(file, openflag, olist)
	String file // file name
	Variable openflag // (1) open new (2) append (3) append then close (-1 objtype)
	String olist // object name list

	Variable ocnt, icnt, jcnt, nobjchar, opnts, otype, slength, refnum
	String objName, dumstr, wnote
	
	Variable /G dumvar
	
	if (strlen(file) == 0)
		return -1
	endif
	
	if (openflag == 1)
		Open /T="IGBW" refnum as file
	elseif ((openflag == 2) || (openflag == 3))
		Open /A/T="IGBW" refnum as file
	else
		return -1
	endif
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
	
		objName = StringFromList(ocnt, olist)
		otype = NMBinObjType(objName)
		
		if ((otype < 0) || (otype > 4))
			continue
		endif
		
		dumvar = otype
		FBinWrite /B=2/F=1 refnum, dumvar
		
		NMBinWriteString(refnum, objName)
		
		switch(otype)
		
			case 0: // text wave (1D)
				Wave /T tWave = $objName
				NMBinWriteString(refnum, note(tWave)) // write wave note
				
				opnts = numpnts(tWave); dumvar = opnts
				FBinWrite /B=2/F=3 refnum, dumvar // write numpnts
				
				for (icnt = 0; icnt < opnts; icnt += 1) // write wave points
					NMBinWriteString(refnum, tWave[icnt])
				endfor
				break
				
			case 1: // numeric wave (1D)
				Wave nWave = $objName
				NMBinWriteString(refnum, note(nWave)) // write wave note
				
				dumvar = leftx(nWave)
				FBinWrite /B=2/F=4 refnum, dumvar // write leftx scaling
				
				dumvar = deltax(nWave)
				FBinWrite /B=2/F=4 refnum, dumvar // write deltax scaling
				
				opnts = numpnts(nWave); dumvar = opnts
				FBinWrite /B=2/F=3 refnum, dumvar // write numpnts
				
				for (icnt = 0; icnt < opnts; icnt += 1) // write wave points
					dumvar = nWave[icnt]
					FBinWrite /B=2/F=4 refnum, dumvar
				endfor
				break
				
			case 2: // numeric variable
				dumvar = NumVarOrDefault(objName, Nan)
				FBinWrite /B=2/F=4 refnum, dumvar
				break
				
			case 3: // string variable 
				NMBinWriteString(refnum, StrVarOrDefault(objName, ""))
				break
				
			case 4: // folder
				break
			
		endswitch
		
	endfor
	
	if (openflag == 3) // write EOF
		dumvar = -1
		FBinWrite /B=2/F=1 refnum, dumvar
	endif
	
	KillVariables /Z dumvar
	
	Close refnum

End // NMBinWriteObject

//****************************************************************
//****************************************************************
//****************************************************************

Function NMBinWriteString(refnum, str2write)
	Variable refnum
	String str2write
	
	Variable icnt, nobjchar = strlen(str2write)
	Variable /G dumvar = nobjchar
	
	FBinWrite /B=2/F=2 refnum, dumvar

	for (icnt = 0; icnt < nobjchar; icnt += 1)
		dumvar = char2num(str2write[icnt,icnt])
		FBinWrite /B=2/F=1 refnum, dumvar
	endfor

End // NMBinWriteString

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBinReadString(refnum)
	Variable refnum
	String str2read = ""
	
	Variable /G dumvar
	
	FBinRead /B=2/F=2 refnum, dumvar
	
	Variable icnt, nobjchar = dumvar

	for (icnt = 0; icnt < nobjchar; icnt += 1)
		FBinRead /B=2/F=1 refnum, dumvar
		str2read += num2char(dumvar)
	endfor
	
	return str2read

End // NMBinReadString

//****************************************************************
//****************************************************************
//****************************************************************

Function NMBinReadObject(file, makeflag)
	String file // file name
	String makeflag // string variables | numeric variables  | text waves | numeric waves
	// "1111" to make all variables and waves
	// "0001" to make only numeric waves
	
	Variable icnt, jcnt, nobjchar, opnts, otype, slength, refnum, lx, dx
	String objName, dumstr, wnote
	
	Variable /G dumvar
	
	String saveDF = GetDataFolder(1) // save current directory 
	
	Open /R/T="IGBW" refnum as file
		
	do
		
		FBinRead /B=2/F=1 refnum, dumvar
		otype = dumvar

		if (otype == -1)
			break // NM Object EOF
		endif
		
		if ((otype < 0) || (otype > 4))
			break // something wrong
		endif
		
		objName = NMBinReadString(refnum)
		
		if (strlen(objName) == 0)
			break // something wrong
		endif
		
		switch(otype)
		
			case 0: // text wave (1D)
				wnote = NMBinReadString(refnum) // read wave note
				
				FBinRead /B=2/F=3 refnum, dumvar
				opnts = dumvar
				
				if (StringMatch(makeflag[2,2], "1") == 1) // make wave
					Make /T/O/N=(opnts) $objName
					Wave /T tWave = $objName
					Note tWave, wnote
				endif
				
				for (icnt = 0; icnt < opnts; icnt += 1) // read wave points
					dumstr = NMBinReadString(refnum)
					if (StringMatch(makeflag[2,2], "1") == 1)
						tWave[icnt] = dumstr
					endif
				endfor
				
				break
				
			case 1: // numeric wave (1D)
				
				wnote = NMBinReadString(refnum) // read wave note
				
				FBinRead /B=2/F=4 refnum, dumvar // read leftx scaling
				lx = dumvar
				
				FBinRead /B=2/F=4 refnum, dumvar // read deltax scaling
				dx = dumvar
				
				FBinRead /B=2/F=3 refnum, dumvar // read numpnts
				opnts = dumvar
				
				if (StringMatch(makeflag[3,3], "1") == 1) // make wave
					Make /O/N=(opnts) $objName
					Wave nWave = $objName
					Setscale /P x lx, dx, nWave
					Note nWave, wnote
				endif
				
				for (icnt = 0; icnt < opnts; icnt += 1) // read wave points
					FBinRead /B=2/F=4 refnum, dumvar
					if (StringMatch(makeflag[3,3], "1") == 1)
						nWave[icnt] = dumvar
					endif
				endfor
				
				break
				
			case 2: // numeric variable
				FBinRead /B=2/F=4 refnum, dumvar
				if (StringMatch(makeflag[1,1], "1") == 1)
					SetNMVar(objName, dumvar)
				endif
				break
				
			case 3: // string variable
				dumstr = NMBinReadString(refnum)
				if (StringMatch(makeflag[0,0], "1") == 1)
					SetNMStr(objName, dumstr)
				endif
				break
				
			case 4: // folder type
				NewDataFolder /O/S $(saveDF+objName)
				break
			
		endswitch
		
	while (1)
	
	KillVariables /Z dumvar
	
	Close refnum

End // NMBinReadObject

//****************************************************************
//****************************************************************
//****************************************************************

Function NMBinObjType(objName)
	String objName
	
	Variable otype = -1
	
	switch(exists(objName))
	
		case 1: // wave
			if (WaveType($objName) == 0)
				otype = 0 // text wave
			else
				otype = 1 // numeric wave
			endif
			break
			
		case 2: // variable or string
			
			if (NumVarOrDefault(objName, -pi) == -pi)
				otype = -2
			else
				otype = 2 // numeric variable
				break
			endif
			
			if (StringMatch(StrVarOrDefault(objName, "somethingcrazy"), "somethingcrazy") == 1)
				otype = -2
			else
				otype = 3 // string variable
				break
			endif
			
			break
			
	endswitch
	
	if ((otype == -1) && (DataFolderExists(objName) == 1))
		otype = 4 // is folder
	endif
	
	return otype
	
End // NMBinObjType

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBinFileType(file)
	String file // file name
	String ftype = ""
	
	Variable icnt, nobjchar, opnts, otype, refnum
	String objName
	
	Variable /G dumvar
	
	Open /R/T="IGBW" refnum as file
	
	FBinRead /B=2/F=1 refnum, dumvar
	
	otype = dumvar

	if (otype == 3)
	
		objName = NMBinReadString(refnum)
		
		if (StringMatch(objName, "FileType") == 1)
			ftype = NMBinReadString(refnum)
		endif
	
	endif
	
	KillVariables /Z dumvar
	
	Close refnum
	
	return ftype
		
End // NMBinFileType

//****************************************************************
//****************************************************************
//****************************************************************

