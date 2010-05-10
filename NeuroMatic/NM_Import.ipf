#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 2

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
//	Import data file types currently supported:
//		1) Axograph
//		2) Pclamp
//		3) Text files
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
		NMDoAlert("Abort NMImportFileManager: file format not recognized.")
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
					Execute "success = ReadAxograph(" + NMQuotes( file ) + "," + NMQuotes( df ) + ", 0)"
					break
					
				case "data":
					Execute "success = ReadAxograph(" + NMQuotes( file ) + "," + NMQuotes( df ) + ", 1)"
					break
					
				case "test":
					success = 1
					break
					
			endswitch
			
			break
		
		case "Pclamp": // (see ReadPclamp.ipf)
		
			strswitch(option)
			
				case "header":
					Execute "success = ReadPclampHeader(" + NMQuotes( file ) + "," + NMQuotes( df ) + ")"
					break
					
				case "data":
					Execute "success = ReadPclampData(" + NMQuotes( file ) + "," + NMQuotes( df ) + ")"
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

Function NMImportAllCall()

End // NMImportAllCall

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
	
	elseif (NMNumWaves() > 0)
	
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
	
	if ((NMNumWaves() == 0) && (strlen(StrVarOrDefault("CurrentFile", "")) == 0))
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
	KillStrings /Z S_filename, S_wavenames
	
	return folder

End // NMImportFile

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImport( file, newFolder ) // main load data function
	String file
	Variable newFolder // (0) no (1) yes
	
	Variable success, amode, saveprompt, totalNumWaves, numChannels
	String acqMode, wPrefix, wList, seq, folder, prefixFolder
	String df = ImportDF()
	
	if (CheckCurrentFolder() == 0)
		return 0
	endif
	
	Variable importPrompt = NeuroMaticVar("ImportPrompt")
	String saveWavePrefix = StrVarOrDefault("WavePrefix", "Record")
	
	if (FileExists(file) == 0)
		NMDoAlert("Error: external data file has not been selected.")
		return -1
	endif
	
	Variable emptyfolder = ((NMNumWaves() == 0) && (strlen(StrVarOrDefault("CurrentFile", "")) == 0))
	
	success = CallNMImportFileManager(file, df, "", "header")
	
	if (success <= 0)
		return -1
	endif
	
	totalNumWaves = NumVarOrDefault(df+"TotalNumWaves", 0)
	numChannels = NumVarOrDefault(df+"NumChannels", 1)
	
	SetNMvar(df+"WaveBgn", 0)
	SetNMvar(df+"WaveEnd", floor(totalNumWaves / numChannels ) - 1)
	SetNMstr(df+"ImportSeqStr", "")
	CheckNMstr(df+"WavePrefix", "Record")
	
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
	
	PrintNMFolderDetails( GetDataFolder( 1 ) )
	NMPrefixSelectSilent( wPrefix )
	
	prefixFolder = CurrentNMPrefixFolder()
	
	//if (StringMatch(wPrefix, saveWavePrefix) == 1)
	//	NMSetsDataNew()
	//endif
	
	acqMode = StrVarOrDefault(df+"AcqMode", "")
	
	amode = str2num(acqMode[0])
	
	if ((numtype(amode) == 0) && (amode == 3)) // gap free
	
		if (NumVarOrDefault(df+"ConcatWaves", 0) == 1)
		
			NMChanSelect( "All" )
		
			wList = NMConcatWaves( "C_Record" )
			
			if (ItemsInList(wList) == NMNumWaves() * NMNumChannels())
				SetNeuroMaticVar( "NMDeleteWavesNoAlert", 1 )
				NMDeleteWaves()
			else
				NMDoAlert("Alert: waves may have not been properly concatenated.")
			endif
			
			NMPrefixSelectSilent( "C_Record" )
			
		else
			NMTimeScaleMode(1) // make continuous
		endif
		
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
	
	Variable icnt, jcnt, success, newfolder, amode, totalNumWaves, numChannels
	String acqMode, setList, file, seq, ext = "", wlist, wprefix, folder, df = ImportDF()
	
	String saveCurrentFile = StrVarOrDefault("CurrentFile", "")
	String saveWavePrefix = StrVarOrDefault("WavePrefix", "Record")
	
	Variable importPrompt = NeuroMaticVar( "ImportPrompt" )
	
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
		
		//setList = NMSetsList( "", 1 ) // save list of Sets before appending
		
		if (FileExists(file) == 0)
			NMDoAlert(file + " does not exist.")
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
		
		totalNumWaves = NumVarOrDefault(df+"TotalNumWaves", 0)
		numChannels = NumVarOrDefault(df+"NumChannels", 0)
	
		SetNMvar(df+"WaveBgn", 0)
		SetNMvar(df+"WaveEnd", floor( totalNumWaves / numChannels ) - 1)
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
		
		success = CallNMImportFileManager(file, "", StrVarOrDefault(df+"DataFileType", ""), "data") // read data
		
		if (success < 0) // user aborted
			continue
		endif
		
		PrintNMFolderDetails( GetDataFolder( 1 ) )
		NMPrefixSelectSilent(wPrefix)
		
		//if (StringMatch(wPrefix, saveWavePrefix) == 1)
		//	NMSetsDataNew()
		//endif
		
		acqMode = StrVarOrDefault(df+"AcqMode", "")
	
		amode = str2num(acqMode[0])
		
		if ((numtype(amode) == 0) && (amode == 3)) // gap free
		
			if (NumVarOrDefault(df+"ConcatWaves", 0) == 1)
			
				wList = NMConcatWaves( "C_Record" )
				
				if (ItemsInList(wList) == NMNumWaves())
					SetNeuroMaticVar( "NMDeleteWavesNoAlert", 1 )
					NMDeleteWaves()
				else
					NMDoAlert("Alert: waves were not properly concatenated.")
				endif
				
				NMPrefixSelect( "C_Record" )
				
			else
				NMTimeScaleMode(1) // make continuous
			endif
			
		endif
		
	endfor
	
	//Duplicate /O saveYLabel yLabel
	
	KillWaves /Z saveYLabel
	
	return 2

End // NMImportFileSeq

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
	
	Variable xPixels = NMComputerPixelsX()
	Variable newFolder = NumVarOrDefault(df+"NewFolder", 1)
	Variable waveEnd = NumVarOrDefault(df+"WaveEnd", 0)
	Variable concat = NumVarOrDefault(df+"ConcatWaves", 0)
	String acqmode = StrVarOrDefault(df+"AcqMode", "")
	
	Variable amode = str2num(acqMode[0])
	
	String fileType = StrVarOrDefault(df+"DataFileType", "UNKNOWN")
	
	x1 = (xPixels - width) / 2
	y1 = 200
	x2 = x1 + width
	y2 = y1 + height
	
	seq = SeqNumFind(StrVarOrDefault(df+"FileName", ""))
	
	if ((numtype(seq) > 0) || (seq > 999))
		seq = 6
	endif
	
	seqstr = "file seq (e.g. " + num2istr(seq) + "-" + num2istr(seq+2) + ", " + num2istr(seq+4) + ", " + num2istr(seq+7) + ") "
	
	DoWindow /K ImportPanel
	NewPanel /N=ImportPanel/W=(x1,y1,x2,y2) as "Import " + fileType + " File"
	
	x1 = 20
	y1 = 45
	yinc = 23
	
	SetDrawEnv fsize= 18
	DrawText x1, 30, "File:  " + StrVarOrDefault(df+"FileName", "")
	
	SetVariable NM_NumChannelSet, title="channels: ", limits={1,10,0}, pos={x1,y1}, size={250,50}, frame=0, value=$(df+"NumChannels"), win=ImportPanel, proc=NMImportSetVariable
	SetVariable NM_SampIntSet, title="sample interval (ms):  ", limits={0,10,0}, pos={x1,y1+1*yinc}, size={250,50}, frame=0, value=$(df+"SampleInterval"), win=ImportPanel
	SetVariable NM_SPSSet, title="samples:  ", limits={0,inf,0}, pos={x1,y1+2*yinc}, size={250,50}, frame=0, value=$(df+"SamplesPerWave"), win=ImportPanel
	SetVariable NM_AcqModeSet, title="acquisition mode: ", pos={x1,y1+3*yinc}, size={250,50}, frame=0, value=$(df+"AcqMode"), win=ImportPanel
	
	if ((numtype(amode) == 0) && (amode == 3)) // gap free
		CheckBox NM_ConcatWaves, title="concatenate waves", pos={x1+50,y1+4*yinc}, size={16,18}, value=(concat), proc=NMImportCheckBox, win=ImportPanel
		y1 += 15
	endif
	
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
		case "NM_ConcatWaves":
			SetNMvar(df+"ConcatWaves", checked)
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
	
	Variable chncnt, totalWaves, numChannels
	String df = ImportDF()
	
	strswitch(ctrlName)
	
		case "NM_NumChannelSet":
		
			totalWaves = NumVarOrDefault( df+"TotalNumWaves", 0 )
			numChannels = NumVarOrDefault( df+"NumChannels", 1 )
			SetNMvar(df+"WaveEnd", floor( totalWaves / numChannels ) - 1 )
			
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
//
//	Text File Import Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLoadAllWavesFromExtFolderCall()

	String vlist = ""
	String df = ImportDF()

	String fileType = StrVarOrDefault( df+"LoadWavesFileType", "Igor Binary" )
	String fileExt = StrVarOrDefault( df+"LoadWavesFileExt", "ibw" )
	Variable createNewFolder = 1 + NumVarOrDefault( df+"LoadWavesNewFolder", 1 )
	
	Prompt fileType "type of files to load:", popup "Igor Binary;Igor Text;General Text;Delimited Text;"
	Prompt fileExt "file extension (e.g. \"ibw\" or \"itx\" or \"txt\")"
	Prompt createNewFolder "import to a new data folder?", popup "no;yes;"
	DoPrompt "Load all waves that reside in an external folder", fileType, fileExt, createNewFolder
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	createNewFolder -= 1
	
	SetNMstr( df+"LoadWavesFileType", fileType )
	SetNMstr( df+"LoadWavesFileExt", fileExt )
	SetNMvar( df+"LoadWavesNewFolder", createNewFolder )
	
	vlist = NMCmdStr(fileType, vlist)
	vlist = NMCmdStr(fileExt, vlist)
	vlist = NMCmdNum(createNewFolder, vlist)
	NMCmdHistory("NMLoadAllWavesFromExtFolder", vlist)
	
	return NMLoadAllWavesFromExtFolder( fileType, fileExt, createNewFolder )

End // NMLoadAllWavesFromExtFolderCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLoadAllWavesFromExtFolder( fileType, fileExt, createNewFolder )
	String fileType // "Igor Binary" or "Igor Text" or "General Text" or "Delimited Text"
	String fileExt // file extension of waves to load ( e.g. "txt" or "dat" )
	Variable createNewFolder // ( 0 ) no ( 1 ) yes
	
	Variable numFiles, icnt, slen
	String file, pathStr, fname, newFolder, fileList, wname, wname2, wList = ""
	
	if ( StringMatch( fileExt[0,0], "." ) == 0 )
		fileExt = "." + fileExt
	endif
	
	file = FileDialogue(0, "", "", ".*")
		
	if (strlen(file) == 0)
		return "" // cancel
	endif
	
	pathStr = GetPathName(file, 1)
	fname = GetPathName(file, 0)
	
	NewPath /Q/O OpenAllPath, pathStr
	
	fileList = IndexedFile(OpenAllPath,-1,"????")
	
	numFiles = ItemsInList(fileList)
	
	if (numFiles == 0)
		return ""
	endif
	
	if ( createNewFolder == 1 )
		newFolder = FolderNameCreate(pathStr)
		NMFolderNew( "" )
	endif
	
	for (icnt = 0; icnt < numFiles; icnt += 1)
	
		file = StringFromList(icnt, fileList)
		
		slen = strlen(file)
			
		if ( StringMatch(file[slen-strlen(fileExt),slen-1], fileExt) == 1 )
		
			strswitch( fileType )
				case "Igor Binary":
					LoadWave /A=NMwave/O/P=OpenAllPath/Q file
					break
				case "Igor Text":
					LoadWave /A=NMwave/T/O/P=OpenAllPath/Q file
					break
				case "General Text":
					LoadWave /A=NMwave/D/G/O/P=OpenAllPath/Q file
					break
				case "Delimited Text":
					LoadWave /A=NMwave/D/J/K=1/O/P=OpenAllPath/Q file
					break
				default:
					return "" // wrong format
			endswitch
			
			wname = StringFromList(0, S_waveNames)
			wname2 = file[0,slen-5]
			
			Duplicate /O $wname, $wname2
			
			KillWaves /Z $wname
			
			wList = AddListItem( wname2, wList, ";", inf )
			
		endif
		
	endfor
	
	if ( ( createNewFolder == 1 ) && ( DataFolderExists( CheckNMFolderPath( newFolder ) ) == 0 ) )
		NMFolderRename( "" , newFolder )
	endif
	
	return wList
	
End // NMLoadAllWavesFromExtFolder

//****************************************************************
//****************************************************************
//****************************************************************

