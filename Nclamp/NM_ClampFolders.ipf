#pragma rtGlobals=1
#pragma IgorVersion = 5
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Folder Functions
//	To be run with NeuroMatic
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
//	Began 1 July 2003
//	Last modified 31 Feb 2007
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderNewCell()
	String cdf = ClampDF()

	Variable cell = ClampDataFolderCell()
	
	if (numtype(cell) > 0)
		return 0
	endif
	
	NotesCopyVars(LogDF(),"H_") // update header Notes
	NotesCopyFolder(LogDF()+"Final_Notes") 
	LogSave() // save any remaining log notes
	
	ClampDataFolderSeqReset()
	SetNMvar(cdf+"DataFileCell", cell+1)
	SetNMvar(cdf+"LogFileSeq", -1) // reset log file counter
	
End // ClampDataFolderNewCell

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderCell()

	return NumVarOrDefault(ClampDF()+"DataFileCell", 0)

End // ClampDataFolderCell

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderSeq()

	return NumVarOrDefault(ClampDF()+"DataFileSeq", 0)

End // ClampDataFolderSeq

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderSeqReset()
	String cdf = ClampDF()
	
	if (NumVarOrDefault(cdf+"SeqAutoZero", 1) == 1)
		SetNMvar(cdf+"DataFileSeq", 0)
	endif

End // ClampDataFolderSeqReset

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampDataFolderName(next)
	Variable next // (0) this data folder name (1) next data folder name
	
	Variable icnt
	String fname = "", suffix = ""
	
	String cdf = ClampDF()
	
	String prefix = StrVarOrDefault(cdf+"FolderPrefix", ClampDateName())
	String stimtag = StrVarOrDefault(cdf+"StimTag", "")
	
	Variable first = 0
	Variable cell = ClampDataFolderCell()
	Variable seq = ClampDataFolderSeq()
	
	if (numtype(seq) > 0)
		seq = 0
	endif
	
	if (numtype(str2num(prefix[0,0])) == 0)
		prefix = "nm" + prefix
	endif
	
	if (numtype(cell) == 0)
		prefix += "c" + num2str(cell)
	endif
	
	for (icnt = seq; icnt <= 999; icnt += 1)

		suffix = "_"
	
		if (icnt < 10)
			suffix += "00"
		elseif (icnt < 100)
			suffix += "0"
		endif
		
		fname = prefix + suffix + num2str(icnt)
		
		if (ClampSaveTestStr(fname) == -1)
			continue // ext file already exists
		endif
		
		if (strlen(stimtag) > 0)
			fname += "_" + stimtag
		endif
		
		if (ClampSaveTest(fname) == -1) // final check
			continue // ext file already exists
		endif
		
		if (next == 0)
			break // found OK current folder name
		elseif (next == 1)
			if (IsNMDataFolder(fname) == 0)
				break // found OK next folder name
			endif
		endif
		
	endfor
	
	SetNMVar(cdf+"DataFileSeq", icnt) // set new seq num
	
	return fname

End // ClampDataFolderName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderCheck()
	String cdf = ClampDF()
	
	String prefix = StrVarOrDefault(cdf+"FolderPrefix", ClampDateName())
	
	String CurrentFolder = StrVarOrDefault(cdf+"CurrentFolder", "")
	String fname = ClampDataFolderName(0)
	
	if (strlen(CurrentFolder) == 0) // no data folders yet
		CurrentFolder = GetDataFolder(0)
	endif

	if ((StringMatch(CurrentFolder, GetDataFolder(0)) == 0) && (IsNMDataFolder(CurrentFolder) == 1))
		NMFolderChange(CurrentFolder) // data folder has changed, move back to current folder
	endif
	
	String thisFolder = GetDataFolder(0)
	String currentFile = StrVarOrDefault("CurrentFile", "")
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	Variable lastMode = NumVarOrDefault("CT_Record", 0)
	
	if (IsNMDataFolder(thisFolder) == 1)
	
		if (StringMatch(fname, thisFolder) == 1)
		
			if ((lastMode == 0) && (strlen(currentFile) == 0))
				return 0
			endif
			
		else
		
			if ((nwaves == 0) && (strlen(currentFile) == 0))
			
				thisFolder = NMFolderRename(thisFolder, fname)
				
				if (strlen(thisFolder) > 0)
					SetNMVar(cdf+"GetChanConfigs", 1)
					return 0
				endif
				
			endif
		endif
		
	endif
	
	return ClampDataFolderNew() // make new folder

End // ClampDataFolderCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderNew() // create a new data folder
	String cdf = ClampDF()

	String newfolder = ClampDataFolderName(1) // folder name
	String oldfolder = StrVarOrDefault(cdf+"CurrentFolder", "")
	String extfile = StrVarOrDefault("CurrentFile", "")
	
	Variable autoClose = NumVarOrDefault(cdf+"AutoCloseFolder", 0)
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	
	if ((autoClose == 1) && (SaveWhen > 0) && (IsNMDataFolder(oldfolder) == 1) && (strlen(extfile) > 0))
		SetNMvar(NMDF()+"ChanGraphCloseBlock", 1) // block closing chan graphs
		ClampGraphsUpdate(0)
		ClampStatsRemoveWaves(0)
		SetNMvar(NMDF()+"ChanGraphCloseBlock", 1) // block closing chan graphs
		NMFolderClose(oldfolder) // close current folder before opening new one
		ClampDataFolderCloseEmpty()
	endif
	
	SetNMvar(NMDF()+"UpdateNMBlock", 1) // block update
	SetNMvar(NMDF()+"ChanGraphCloseBlock", 1) // block closing chan graphs
	newfolder = NMFolderNew(newfolder) // create a new folder
	SetNMvar(NMDF()+"UpdateNMBlock", 0) // unblock
	
	CheckNMwave("CT_TimeStamp", 0, Nan)
	CheckNMwave("CT_TimeIntvl", 0, Nan)
	
	if (strlen(newfolder) == 0)
		return -1
	endif
	
	SetNMstr(cdf+"CurrentFolder", newfolder)
	
	SetNMVar(cdf+"GetChanConfigs", 1) // get chan graph configs
	
End // ClampDataFolderNew

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderCloseEmpty()
	Variable icnt, nwaves, match
	String extfile, cdf = ClampDF()
	
	String prefix = StrVarOrDefault(cdf+"FolderPrefix", ClampDateName())
	
	String fname, flist = NMDataFolderList()
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		fname = StringFromList(icnt, flist)
		
		nwaves = NumVarOrDefault("root:" + fname + ":NumWaves", 0)
		extfile = StrVarOrDefault("root:" + fname + ":CurrentFile", "")
		match = strsearch(UpperStr(fname), UpperStr(prefix), 0)
		
		if ((match >= 0) && (nwaves == 0) && (strlen(extfile) == 0))
			NMFolderClose(fname)
		endif
		
	endfor

End // ClampDataFolderCloseEmpty

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderUpdate(nwaves, mode)
	Variable nwaves
	Variable mode // (0) preview (1) record
	
	Variable config, icnt, npnts
	String wlist, item
	
	String cdf = ClampDF(), sdf = StimDF(), ndf = NotesDF(), gdf = cdf+"Temp:"

	Variable CopyStim2Folder = NumVarOrDefault(cdf+"CopyStim2Folder", 1)
	String CurrentStim = StimCurrent()
	
	NVAR NumChannels, NumWaves

	Wave ADCon = $(sdf+"ADCon")
	Wave ADCmode = $(sdf+"ADCmode")
	Wave /T ADCname = $(sdf+"ADCname")
	Wave /T ADCunits = $(sdf+"ADCunits")
	
	Wave /T yLabel
	
	Variable nchans = StimNumChannels(sdf)
	
	Redimension /N=(nchans) yLabel
	
	npnts = numpnts(ADCon)
	
	for (config = 0; config < npnts; config += 1)
		if ((ADCon[config] == 1) && (ADCmode[config] <= 0))
			yLabel[icnt] = ADCname[config] + " (" + ADCunits[config] + ")"
			icnt += 1
		endif
	endfor
	
	String wPrefix = StimWavePrefix()

	SetNMVar("NumChannels", icnt)
	SetNMVar("NumWaves", nwaves)
	SetNMVar("TotalNumWaves", icnt*nwaves)
	SetNMVar("FileDateTime", DateTime)
	SetNMstr(cdf+"CurrentFolder", GetDataFolder(0))
	SetNMVar("SamplesPerWave", NumVarOrDefault(sdf+"SamplesPerWave", 0))
	SetNMVar("SampleInterval", NumVarOrDefault(sdf+"SampleInterval", 0))
	SetNMvar("NumGrps", NumVarOrDefault(sdf+"NumStimWaves", 1))
	SetNMvar ("FirstGrp", NMGroupFirstDefault())
	SetNMvar("CT_Record", mode)

	SetNMstr("WavePrefix", wPrefix)
	SetNMstr("CurrentPrefix", wPrefix)
	SetNMstr("FileDate", date())
	SetNMstr("FileTime", time())
	SetNMstr("FileName", GetDataFolder(0))
	
	switch(NumVarOrDefault(sdf+"AcqMode", 0))
		case 0:
			SetNMstr("AcqMode", "episodic")
			break
		case 1:
			SetNMstr("AcqMode", "continuous")
			break
		default:
			SetNMstr("AcqMode", "")
			break
	endswitch
	
	CheckNMwave("CT_TimeStamp", nwaves, Nan) // waves to save acquisition times
	CheckNMwave("CT_TimeIntvl", nwaves, Nan)
	
	SetNMwave("CT_TimeStamp", -1, Nan)
	SetNMwave("CT_TimeIntvl", -1, Nan)
	
	CheckNMDataFolderWaves() // redimension NM waves
	
	if ((mode == 1) && (copyStim2Folder == 1))
	
		if (DataFolderExists(CurrentStim) == 1)
			KillDataFolder $CurrentStim
		endif
		
		//if (DataFolderExists(gdf) == 1)
		//	KillDataFolder $(gdf) // shouldnt exist yet
		//endif
		
		//StimWavesMove(sdf, gdf)
		
		DuplicateDataFolder $sdf, $CurrentStim // save copy of stim protocol folder
		
		//if (DataFolderExists(gdf) == 1)
		//	StimWavesMove(gdf, sdf)
		//	KillDataFolder $(gdf)
		//endif
		
	endif
	
	wlist = WaveList(wPrefix+"*",";","")
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		KillWaves /Z $(StringFromList(icnt, wlist)) // kill existing input waves
	endfor
	
	if (StimStatsOn() == 0)
		ClampStatsRemoveWaves(1)
	endif

End // ClampDataFolderUpdate

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Save folder functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampSaveSubPath()

	String subStr, cdf = ClampDF()
	String ClampPathStr = StrVarOrDefault(cdf+"ClampPath", "")
	String prefix = StrVarOrDefault(cdf+"FolderPrefix", "")
	
	Variable saveSub = NumVarOrDefault(cdf+"SaveInSubfolder", 1)
	Variable cell = NumVarOrDefault(cdf+"DataFileCell", Nan)
	
	if ((saveSub == 0) || (strlen(ClampPathStr) == 0))
		return ""
	endif
	
	if (numtype(cell) == 0)
		prefix += "c" + num2str(cell)
	endif
	
	if ((strlen(ClampPathStr) > 0) && (strlen(prefix) > 0))
		subStr = ClampPathStr + prefix + ":"
		NewPath /C/Z/O/Q ClampSubPath subStr
		if (V_flag != 0)
			DoAlert 0, "Failed to create external path to: " + subStr
			SetNMstr(cdf+"ClampSubPath", "")
		else
			SetNMstr(cdf+"ClampSubPath", subStr)
		endif
	endif
	
	return subStr

End // ClampSaveSubPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampSavePathGet()

	String cdf = ClampDF()
	
	if (NumVarOrDefault(cdf+"SaveInSubfolder", 1) == 1)
		return "ClampSubPath"
	else
		return "ClampPath"
	endif

End // ClampSavePathGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampSavePathStr()

	String cdf = ClampDF()
	String path = ""
	
	if (NumVarOrDefault(cdf+"SaveInSubfolder", 1) == 1)
		path = StrVarOrDefault(cdf+"ClampSubPath", "")
	endif
	
	if (strlen(path) == 0)
		path = StrVarOrDefault(cdf+"ClampPath", "")
	endif
	
	return path

End // ClampSavePathStr

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveBegin() // NM binary format only

	String path, cdf = ClampDF(), sdf = StimDF()

	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	Variable numStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable numStimReps = NumVarOrDefault(sdf+"NumStimReps", 0)
	Variable ask = NumVarOrDefault(cdf+"SaveWithDialogue", 1)
	
	if (saveWhen == 2) // begin save while recording
		ClampDataFolderUpdate(NumStimWaves * NumStimReps, 1)
		KillWaves /Z CT_TimeStamp, CT_TimeIntvl
		FileBinSave(ask, 1, "", ClampSavePathGet(), "", 0, 0) // NM_FileManager.ipf
		Make /O/N=(NumStimWaves * NumStimReps) CT_TimeStamp, CT_TimeIntvl
	endif
	
	return 0

End // ClampSaveBegin

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveFinish()

	String file, cdf = ClampDF()
	String path = ClampSavePathGet()
	
	Variable saveFormat = NumVarOrDefault(cdf+"SaveFormat", 1)
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	Variable ask = NumVarOrDefault(cdf+"SaveWithDialogue", 1)

	if ((SaveFormat == 1) || (SaveFormat == 3)) // NM binary
	
		if (saveWhen == 1) // save after recording (Igor 4)
		
			file = FileBinSave(ask, 1, "", path, "", 1, 0) // NM_FileManager.ipf
			
		elseif (saveWhen == 2) // save while recording (Igor 4 and 5)
		
			file = ClampNMbinAppend("CT_TimeStamp") // append
			file = ClampNMbinAppend("CT_TimeIntvl") // append
			file = ClampNMbinAppend("close file") // close file
			ask = 0
			
		endif
		
	endif
	
	if ((SaveFormat == 2) || (SaveFormat == 3)) // Igor binary
		file = FileBinSave(ask, 1, "", path, "", 1, 1) // NM_FileManager.ipf
	endif
	
	path = GetPathName(file, 1)
	
	PathInfo /S ClampPath
	
	if (strlen(S_path) > 0)
		SetNMStr(cdf+"ClampPath", S_path)
	elseif ((strlen(file) > 0) && (strlen(path) > 0))
		SetNMStr(cdf+"ClampPath", path)
		NewPath /Z/Q/O ClampPath path
	endif
	
	if (strlen(file) == 0)
		SetNMstr("CurrentFile", "not saved")
	endif

End // ClampSaveFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveTest(folderName)
	String folderName
	
	String cdf = ClampDF()
	String file = FolderNameCreate(folderName)
	
	String path = ClampSavePathStr()
	
	if ((strlen(path) == 0) || (strlen(file) == 0))
		return -1
	endif
	
	if (FileBinType() == 1)
		file = FileExtCheck(file, ".pxp", 1) // force this ext
	else
		file = FileExtCheck(file, ".nmb", 1) // force this ext
	endif
	
	file = path + file
	
	if (FileExists(file) == 1)
		return -1
	endif
	
	return 0

End // ClampSaveTest

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveTestStr(folderName)
	String folderName
	
	Variable icnt
	String file, slist = "", cdf = ClampDF()
	
	PathInfo /S ClampPath
	
	if (strlen(S_path) == 0)
		return 0
	endif
	
	if (NumVarOrDefault(cdf+"SaveInSubfolder", 1) == 1)
		PathInfo /S ClampSubPath
		if (strlen(S_path) > 0)
			slist = IndexedFile(ClampSubPath,-1,"????")
		endif
	endif
	
	if (strlen(slist) == 0)
		slist = IndexedFile(ClampPath,-1,"????")
	endif
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1)
	
		file = StringFromList(icnt, slist)
		
		if (StrSearchLax(file, folderName, 0) >= 0)
			return -1 // already exists
		endif
		
	endfor
	
	return 0

End // ClampSaveTestStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampNMbinAppend(oname) // NM binary format only
	String oname // object name (or "close file")
	
	String cdf = ClampDF()
	String file = StrVarOrDefault("CurrentFile", "")
	
	if ((strlen(file) == 0) || (NumVarOrDefault(cdf+"SaveWhen", 0) != 2))
		return ""
	endif
	
	strswitch(oname)
		case "close file":
			NMbinWriteObject(file, 3, "") // close object file
			break
		default:
			NMbinWriteObject(file, 2, oname) // append object to file
	endswitch
	
	return file

End // ClampNMbinAppend

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Log Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogDF() // return full-path name of Log folder

	return LogParent() + LogFolderName() +  ":"
	
End // LogDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogFolderName()
	Variable icnt, ibgn = 0, iend = 99

	String fname, cdf = ClampDF()
	
	Variable seq = NumVarOrDefault(cdf+"LogFileSeq", -1)
	Variable cell = ClampDataFolderCell()
	
	String prefix = ClampDateName()
	
	if (numtype(cell) == 0)
		prefix += "c" + num2str(cell)
	endif

	if (seq >= 0)
		return prefix + "_log" + num2str(seq)
	endif
	
	for (icnt = ibgn; icnt <= iend; icnt += 1)
	
		fname = prefix + "_log" + num2str(icnt)

		if (ClampSaveTest(fname) == 0)
			break
		endif
	
	endfor
	
	SetNMvar(cdf+"LogFileSeq", icnt)
	
	return fname

End // LogFolderName

//****************************************************************
//****************************************************************
//****************************************************************

Function LogCheckFolder(ldf) // check log data folder exists
	String ldf // log data folder
	
	ldf = LastPathColon(ldf,1)
	
	if (DataFolderExists(ldf) == 0) // check Log folder exists
		NewDataFolder $LastPathColon(ldf, 0)
		SetNMstr(ldf+"FileType", "NMLog")
		SetNMstr(ldf+"FileDate", date())
		SetNMstr(ldf+"FileTime", time())
	endif
	
End // LogCheckFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function LogDisplay2(ldf, select)
	String ldf // log data folder
	Variable select // (1) notebook (2) table (3) both

	if ((select == 1) || (select == 3))
		LogNoteBookUpdate(ldf)
	endif
	
	if ((select == 2) || (select == 3))
		LogTable(ldf)
	endif
	
End // LogDisplay2

//****************************************************************
//****************************************************************
//****************************************************************

Function LogNoteBookUpdate(ldf) // update existing notebook
	String ldf // log data folder
	
	ldf = LastPathColon(ldf,1)
	
	String nbName = GetPathName(ldf,0) + "_notebook"
	
	if (DataFolderExists(ldf) == 0)
		DoAlert 0, "Error: data folder \"" + ldf + "\" does not appear to exist."
		return -1
	endif
	
	if (StringMatch(StrVarOrDefault(ldf+"FileType", ""), "NMLog") == 0)
		DoAlert 0, "Error: data folder \"" + ldf + "\" does not appear to be a NeuroMatic Log folder."
		return -1
	endif
	
	if (WinType(nbName) == 5)
		LogNoteBookFileVars(PackDF("Notes"), nbName)
	else
		LogNoteBook(ldf)
	endif
	
End // LogNoteBookUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function LogSave()
	
	String ldf = LogDF() // log data folder
	String path = ClampSavePathGet()

	if (StringMatch(StrVarOrDefault(ldf+"FileType", ""), "NMLog") == 0)
		//ClampError(ldf + " is not a NeuroMatic Log folder.")
		return -1
	endif
	
	if (strlen(StrVarOrDefault(ldf+"CurrentFile", "")) > 0)
		FileBinSave(0, 0, ldf, path, "", 1, -1) // replace file
	else
		FileBinSave(0, 1, ldf, path, "", 1, -1) // new file
	endif

End // LogSave

//****************************************************************
//****************************************************************
//****************************************************************