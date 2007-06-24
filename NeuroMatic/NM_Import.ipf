#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion = 5
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Import File Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 11 May 2007
//
//	Import data file types currently supported:
//		1) Axograph
//		2) Pclamp
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ImportDF()
	String df = PackDF("Import")
	
	if (DataFolderExists(df) == 1)
		return PackDF("Import")
	else
		return GetDataFolder(1)
	endif

End // ImportDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckImport()

	CheckPackDF("Import")

End // CheckImport

//****************************************************************
//****************************************************************
//****************************************************************

Function CallNMImportFileManager(file, df, fileType, option) // call appropriate import data function
	String file
	String df
	String fileType
	String option // "header", "data" or "test"
	
	Variable success
	
	if (strlen(fileType) > 0)
	
		success = NMImportFileManager(file, df, fileType, option)
	
	else
	
		fileType = "Axograph"
		success = NMImportFileManager(file, df, fileType, option)
		
		if (success <= 0)
			fileType = "Pclamp"
			success = NMImportFileManager(file, df, fileType, option)
		endif
		
	endif
	
	if (success <= 0)
		DoAlert 0, "Abort NMImportData: file format not recognized."
		fileType = ""
		success = -1
	endif
	
	SetNMstr(df+"DataFileType", fileType)
	
	return success

End // CallNMImportFileManager

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportFileManager(file, df, filetype, option) // call appropriate import data function
	String file
	String df // data folder to import to ("") for current
	String filetype // data file type (ie. "axograph" or "Pclamp")
	String option // "header" to read data header
				// "data" to read data
				// "test" to test whether this file manager supports file type
	
	Variable /G success // success flag (1) yes (0) no; or the number of data waves read
	
	if (strlen(df) == 0)
		df = GetDataFolder(1)
	endif
	
	df = LastPathColon(df, 1)
	
	strswitch(filetype)
	
		default:
			return 0
	
		case "Axograph": // (see ReadAxograph.ipf)
		
			strswitch(option)
				case "header":
					Execute "success = ReadAxograph(\"" + file + "\",\"" + df + "\", 0)"
					break
					
				case "data":
					Execute "success = ReadAxograph(\"" + file + "\",\"" + df + "\", 1)"
					break
					
				case "test":
					success = 1
					break
					
			endswitch
			
			break
		
		case "Pclamp": // (see ReadPclamp.ipf)
		
			strswitch(option)
			
				case "header":
					Execute "success = ReadPclampHeader(\"" + file + "\",\"" + df + "\")"
					break
					
				case "data":
					Execute "success = ReadPclampData(\"" + file + "\",\"" + df + "\")"
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

Function NMImportFileCall() // open a data file
	Variable newfolder
	String file = "", folder = "", vlist = "", df

	CheckImport()
	
	df = ImportDF()
	
	if (CheckCurrentFolder() == 0)
		NMFolderNew("")
	endif
	
	if (IsNMDataFolder("") == 0)
	
		newfolder = 1
	
	elseif (NumVarOrDefault("NumWaves", 0) > 0)
	
		newfolder = 1 + NumVarOrDefault(df+"AskNewFolder", 1)
		
		Prompt newfolder "import data where?", popup "this data folder;new data folder;"
		DoPrompt "Import Data", newfolder
		
		if (V_flag == 1)
			return 0 // cancel
		endif
		
		newfolder -= 1
		
		SetNMvar(df+"AskNewFolder", newfolder)
		
	endif
	
	file = FileDialogue(0, "OpenDataPath", "", "?")
	
	if (strlen(file) == 0)
		return 0 // cancel
	endif
	
	if (newfolder == 1)
		folder = "new" // create new folder
	else
		folder = GetDataFolder(1)
	endif
	
	vlist = NMCmdStr(folder, vlist)
	vlist = NMCmdStr(file, vlist)
	NMCmdHistory("NMImportFile", vlist)
	
	NMImportFile(folder, file)

End // NMImportFileCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMImportFile(folder, file) // import a data file
	String folder // folder name, or "new" for new folder
	String file // external file name
	
	Variable newFolder, renameFolder, success
	String saveDF, df = ImportDF()
	
	if ((strlen(file) == 0) || (FileExists(file) == 0))
		return "" 
	endif
	
	if ((strlen(folder) == 0) || (StringMatch(folder, "new") == 1))
		folder = FolderNameCreate(file) // create folder name
	endif
		
	if (DataFolderExists(folder) == 0)
	
		saveDF = GetDataFolder(0)
	
		folder = FolderNameCreate(file)
		folder = NMFolderNew(folder) // create NM folder
		
		newFolder = 1
	
		if (strlen(folder) == 0)
			return ""
		endif
		
	endif
	
	if ((NumVarOrDefault("NumWaves", 0) == 0) && (strlen(StrVarOrDefault("CurrentFile", "")) == 0))
		renameFolder = 1
	endif
	
	SetNMstr(df+"CurrentFile", file)
	SetNMstr(df+"FileName", GetPathName(file, 0))
	
	success = NMImport(file, newFolder)
	
	if ((success < 0) && (newfolder == 1))
		NMFolderClose(folder)
		NMFolderChange(saveDF)
		folder = ""
	endif
	
	UpdateNM(0)
	
	KillVariables /Z V_Flag, WaveBgn, WaveEnd
	KillStrings /Z S_path, S_filename, S_wavenames
	
	return folder

End // NMImportFile

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImport(file, newFolder) // main load data function
	String file
	Variable newFolder // (0) no (1) yes
	
	Variable success
	String wPrefix, seq, folder, df = ImportDF()
	
	Variable importPrompt = NumVarOrDefault(NMDF()+"ImportPrompt", 1)
	String saveWavePrefix = StrVarOrDefault("WavePrefix", "Record")
	
	if (CheckCurrentFolder() == 0)
		return 0
	endif
	
	if (FileExists(file) == 0)
		DoAlert 0, "Error: external data file has not been selected."
		return -1
	endif
	
	Variable emptyfolder = ((NumVarOrDefault("NumWaves", 0) == 0) && (strlen(StrVarOrDefault("CurrentFile", "")) == 0))
	
	String setList = NMSetsList(1) // save list of Sets before appending
	
	success = CallNMImportFileManager(file, df, "", "header")
	
	if (success <= 0)
		return -1
	endif
	
	SetNMvar(df+"WaveBgn", 0)
	SetNMvar(df+"WaveEnd", floor(NumVarOrDefault(df+"TotalNumWaves", 0) / NumVarOrDefault(df+"NumChannels", 1)) - 1)
	SetNMstr(df+"ImportSeqStr", "")
	CheckNMstr(df+"WavePrefix", StrVarOrDefault("WavePrefix", "Record"))
	
	if (importPrompt == 1)
		NMImportPanel(1) // open panel to display header info and request user input
	endif
	
	if (NumVarOrDefault(df+"WaveBgn", -1) < 0) // user aborted
		return -1
	endif
	
	wPrefix = StrVarOrDefault(df+"WavePrefix", "Record")
	
	SetNMvar("WaveBgn", NumVarOrDefault(df+"WaveBgn", 0))
	SetNMvar("WaveEnd", NumVarOrDefault(df+"WaveEnd", -1))
	
	SetNMstr("WavePrefix", wPrefix)
	SetNMstr("CurrentFile", file)
	SetNMstr("FileName", GetPathName(file, 0))
	
	seq = StrVarOrDefault(df+"ImportSeqStr", "")
	
	if (strlen(seq) > 0)
		SetNMstr("ImportSeqStr", seq)
	endif
	
	if (emptyfolder == 1)
	
		folder = FolderNameCreate(file)
			
		if (StringMatch(GetDataFolder(0), folder) == 0)
			NMFolderRename(GetDataFolder(0), folder)
		endif
	
	endif
	
	success = CallNMImportFileManager(file, "", StrVarOrDefault(df+"DataFileType", ""), "Data") // now read the data
	
	if (success < 0) // user aborted
		return -1
	endif
	
	PrintFileDetails()
	NMPrefixSelectSilent(wPrefix)
	
	if (StringMatch(wPrefix, saveWavePrefix) == 1)
		NMSetsDataNew()
	endif
	
	if (strlen(seq) > 0) // file sequence to read
		return NMImportFileSeq(file, Seq2List(seq))
	endif
	
	return 1

End // NMImport

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportFileSeq(fileName, ImportSeqStr)
	String fileName
	String ImportSeqStr
	
	Variable icnt, jcnt, success, newfolder
	String setList, file, seq, ext = "", wlist, wprefix, folder, df = ImportDF()
	
	String saveCurrentFile = StrVarOrDefault("CurrentFile", "")
	String saveWavePrefix = StrVarOrDefault("WavePrefix", "Record")
	
	Variable importPrompt = NumVarOrDefault(NMDF()+"ImportPrompt", 1)
	
	if (ItemsInList(ImportSeqStr) == 0)
		return 1
	endif
	
	Duplicate /O yLabel saveYLabel
	
	for (icnt = strlen(fileName) - 1; icnt > strlen(fileName) - 5; icnt -= 1)
		if (StringMatch(fileName[icnt,icnt], ".") == 1)
			ext = fileName[icnt,inf]
			fileName = fileName[0, icnt-1]
			break
		endif
	endfor
	
	for (icnt = 0; icnt < ItemsInList(ImportSeqStr); icnt += 1) // loop thru file sequence numbers
		
		seq = StringFromList(icnt, ImportSeqStr)
		
		jcnt = strlen(fileName) - strlen(seq) - 1
		
		file = fileName[0, jcnt] + seq + ext
		
		if (StringMatch(file, saveCurrentFile) == 1)
			continue // not allowed
		endif
		
		setList = NMSetsList(1) // save list of Sets before appending
		
		if (FileExists(file) == 0)
			DoAlert 0, file + " does not exist."
			continue
		endif
		
		newfolder = NumVarOrDefault(df+"NewFolder", 1)
		
		if (newfolder == 1)
			folder = FolderNameCreate(file) // create folder name
			folder = NMFolderNew(folder) // create NM folder
			if (strlen(folder) == 0)
				continue
			endif
		endif
		
		SetNMstr(df+"CurrentFile", file)
		SetNMstr(df+"FileName", GetPathName(file, 0))
		
		success = CallNMImportFileManager(file, df, StrVarOrDefault(df+"DataFileType", ""), "header") // read data header
		
		if (success <= 0)
			continue
		endif
	
		SetNMvar(df+"WaveBgn", 0)
		SetNMvar(df+"WaveEnd", floor(NumVarOrDefault(df+"TotalNumWaves", 0) / NumVarOrDefault(df+"NumChannels", 0)) - 1)
		CheckNMstr(df+"WavePrefix", StrVarOrDefault("WavePrefix", "Record"))
		
		if (importPrompt == 1)
			NMImportPanel(0)
		endif
		
		if (NumVarOrDefault(df+"WaveBgn", -1) < 0)
			continue // user cancelled
		endif
		
		wPrefix = StrVarOrDefault(df+"WavePrefix", "Record")
	
		SetNMvar("WaveBgn", NumVarOrDefault(df+"WaveBgn", 0))
		SetNMvar("WaveEnd", NumVarOrDefault(df+"WaveEnd", -1))
	
		SetNMstr("WavePrefix", wPrefix)
		SetNMstr("CurrentFile", file)
		SetNMstr("FileName", GetPathName(file, 0))
		
		success = CallNMImportFileManager(file, "", StrVarOrDefault(df+"DataFileType", ""), "data") // read data
		
		if (success < 0) // user aborted
			continue
		endif
		
		PrintFileDetails()
		NMPrefixSelectSilent(wPrefix)
		
		if (StringMatch(wPrefix, saveWavePrefix) == 1)
			NMSetsDataNew()
		endif
		
	endfor
	
	//Duplicate /O saveYLabel yLabel
	
	KillWaves /Z saveYLabel
	
	return 2

End // NMImportFileSeq

//****************************************************************
//****************************************************************
//****************************************************************

Function PrintFileDetails()
	Variable nwaves, chncnt, scale 
	String txt
	
	Variable numWaves = NumVarOrDefault("NumWaves", Nan)
	Variable numChannels = NumVarOrDefault("NumChannels", Nan)
	Variable WaveBgn = NumVarOrDefault("WaveBgn", 0)
	Variable waveEnd = NumVarOrDefault("WaveEnd", numWaves)
	
	nwaves = waveEnd - WaveBgn + 1
	
	NMHistory("Data File: " + StrVarOrDefault("CurrentFile", "Unknown Data File"))
	NMHistory("File Type: " + StrVarOrDefault("DataFileType", "Unknown"))
	NMHistory("Acquisition Mode: " + StrVarOrDefault("AcqMode", "Unknown"))
	NMHistory("Channels: " + num2str(NumVarOrDefault("NumChannels", Nan)))
	NMHistory("Waves per Channel: " + num2str(nwaves))
	NMHistory("Waves: " + num2str(WaveBgn) + " - " + num2str(waveEnd))
	NMHistory("Samples per Wave: " + num2str(NumVarOrDefault("SamplesPerWave", Nan)))
	NMHistory("Sample Interval (ms): " + num2str(NumVarOrDefault("SampleInterval", Nan)))
	
	if (WavesExist("FileScaleFactors;MyScaleFactors") == 0)
		return 0
	endif
	
	Wave FileScaleFactors, MyScaleFactors
	
	for (chncnt = 0; chncnt < numChannels; chncnt += 1)
		txt = "Chan " + ChanNum2Char(chncnt) + " Scale Factor: " + num2str(FileScaleFactors[chncnt])
		scale = MyScaleFactors[chncnt]
		if (scale != 1)
			txt += " * " + num2str(scale)
		endif
		NMHistory(txt)
	endfor
	
	NMHistory(" ")

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

Function NMImportPanel(showSeq) // Bring up "Load File Panel" to request user information
	Variable showSeq // (0) no (1) yes

	if (CheckCurrentFolder() == 0)
		return 0
	endif

	Variable x1, x2, y1, y2, yinc, seq, height = 330, width = 280
	String seqstr, df = ImportDF()
	
	Variable xPixels = NumVarOrDefault(NMDF() + "xPixels", 1000)
	Variable newFolder = NumVarOrDefault(df+"NewFolder", 1)
	Variable waveEnd = NumVarOrDefault(df+"WaveEnd", 0)
	
	String fileType = StrVarOrDefault(df+"DataFileType", "UNKNOWN")
	
	x1 = (xPixels - width) / 2
	y1 = 200
	x2 = x1 + width
	y2 = y1 + height
	
	seq = SeqNumFind(StrVarOrDefault(df+"FileName", ""))
	
	if ((numtype(seq) > 0) || (seq > 999))
		seq = 6
	endif
	
	seqstr = "file seq (e.g. " + num2str(seq) + "-" + num2str(seq+2) + ", " + num2str(seq+4) + ", " + num2str(seq+7) + ") "
	
	DoWindow /K ImportPanel
	NewPanel /W=(x1,y1,x2,y2) as "Import " + fileType + " File"
	DoWindow /C ImportPanel
	
	x1 = 20
	y1 = 45
	yinc = 23
	
	SetDrawEnv fsize= 18
	DrawText x1, 30, "File:  " + StrVarOrDefault(df+"FileName", "")
	
	SetVariable NM_NumChannelSet, title="channels: ", limits={1,10,0}, pos={x1,y1}, size={250,50}, frame=0, value=$(df+"NumChannels"), win=ImportPanel, proc=NMImportSetVariable
	SetVariable NM_SampIntSet, title="sample interval (ms):  ", limits={0,10,0}, pos={x1,y1+1*yinc}, size={250,50}, frame=0, value=$(df+"SampleInterval"), win=ImportPanel
	SetVariable NM_SPSSet, title="samples:  ", limits={0,inf,0}, pos={x1,y1+2*yinc}, size={250,50}, frame=0, value=$(df+"SamplesPerWave"), win=ImportPanel
	SetVariable NM_AcqModeSet, title="acquisition mode: ", pos={x1,y1+3*yinc}, size={250,50}, frame=0, value=$(df+"AcqMode"), win=ImportPanel
	
	yinc = 28
	
	SetVariable NM_WavePrefixSet, title="wave prefix ", pos={x1,y1+4*yinc}, size={140,60}, frame=1, value=$(df+"WavePrefix"), win=ImportPanel
	SetVariable NM_WaveBgnSet, title="wave beg ", limits={0,waveEnd-1,0}, pos={x1,y1+5*yinc}, size={140,60}, frame=1, value=$(df+"WaveBgn"), win=ImportPanel
	SetVariable NM_WaveEndSet, title="wave end ", limits={0,waveEnd-1,0}, pos={x1,y1+6*yinc}, size={140,60}, frame=1, value=$(df+"WaveEnd"), win=ImportPanel
	
	if (showSeq == 1)
		SetVariable NM_FileSeq, title=(seqstr), pos={x1,y1+7*yinc}, size={235,60}, frame=1, value=$(df+"ImportSeqStr"), win=ImportPanel, proc=NMImportSetVariable
	endif
	
	CheckBox NM_NewFolder, title="new folder", pos={x1+165,y1+6*yinc}, size={16,18}, value=(newFolder), proc=NMImportCheckBox, win=ImportPanel, disable=1
	
	Button NM_AbortButton, title="Abort", pos={55,y1+8.5*yinc}, size={50,20}, win=ImportPanel, proc=NMImportButton
	Button NM_ContinueButton, title="Open File", pos={145,y1+8.5*yinc}, size={80,20}, win=ImportPanel, proc=NMImportButton
	
	KillVariables /Z iSeqBgn, iSeqEnd
	
	PauseForUser ImportPanel

End // NMImportPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	String df = ImportDF()
	
	strswitch(ctrlName)
		case "NM_NewFolder":
			SetNMvar(df+"NewFolder", checked)
			break	
	endswitch
	
End // NMImportCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportButton(ctrlName) : ButtonControl
	String ctrlName
	
	String df = ImportDF()
	
	if (StringMatch(ctrlName, "NM_AbortButton") == 1)
		SetNMvar(df+"WaveBgn", -1)
	endif
	
	DoWindow /K ImportPanel

End // NMImportButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr, varName
	
	Variable chncnt
	String df = ImportDF()
	
	Variable numChannels = NumVarOrDefault("NumChannels", 0)
	Variable totalNumWaves = NumVarOrDefault("TotalNumWaves", 0)
	
	strswitch(ctrlName)
	
		case "NM_NumChannelSet":
			SetNMvar(df+"WaveEnd", totalNumWaves / numChannels)
			break
			
		case "NM_FileSeq":
			SetNMvar(df+"NewFolder", 1)
			CheckBox NM_NewFolder, win=ImportPanel, disable=0
			break
		
	endswitch

End // NMImportSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

