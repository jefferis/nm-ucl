#pragma rtGlobals=1
#pragma version = 2

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
	
	Variable icnt, seqLimit = 999
	String folderName = "", suffix = ""
	
	String cdf = ClampDF(), sdf = StimDF()
	String path = ClampSavePathStr()
	String datePrefix = ClampDateName()
	String userPrefix = StrVarOrDefault(cdf+"UserFolderPrefix", "")
	String prefix = StrVarOrDefault(cdf+"FolderPrefix", "")
	String stag = StimTag("")
	
	Variable first = 0
	Variable cell = ClampDataFolderCell()
	Variable seq = ClampDataFolderSeq()
	
	if ((strlen(userPrefix) == 0) && (StringMatch(prefix, datePrefix) == 0))
		prefix = datePrefix
		SetNMstr(cdf+"FolderPrefix", prefix)
		SetNMstr(cdf+"UserFolderPrefix", prefix)
	endif
	
	if ( ( numtype(seq) > 0 ) || ( seq >= seqLimit ) )
		seq = 0
	endif
	
	if (numtype(str2num(prefix[0,0])) == 0)
		prefix = "nm" + prefix
	endif
	
	if (numtype(cell) == 0)
		prefix += "c" + num2istr(cell)
	endif
	
	for (icnt = seq; icnt <= seqLimit; icnt += 1)
	
		if (strlen(path) == 0)
			break
		endif

		suffix = "_"
	
		if (icnt < 10)
			suffix += "00"
		elseif (icnt < 100)
			suffix += "0"
		endif
		
		folderName = prefix + suffix + num2istr(icnt)
		
		if (ClampSaveTestStr(folderName) == -1)
			continue // ext file already exists
		endif
		
		if (strlen(stag) > 0)
			folderName += "_" + stag
		endif
		
		if (ClampSaveTest(folderName) == -1) // final check
			continue // ext file already exists
		endif
		
		if (next == 0)
		
			break // found OK current folder name
			
		elseif (next == 1)
		
			if (IsNMDataFolder(folderName) == 0)
				break // found OK next folder name
			endif
			
		endif
		
	endfor
	
	SetNMVar(cdf+"DataFileSeq", icnt) // set new seq num
	
	return folderName

End // ClampDataFolderName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderCheck()

	String cdf = ClampDF()
	
	String prefix = ClampFolderPrefix()
	
	String CurrentFolder = StrVarOrDefault(cdf+"CurrentFolder", "")
	String folderName = ClampDataFolderName(0)
	
	if (strlen(CurrentFolder) == 0) // no data folders yet
		CurrentFolder = GetDataFolder(0)
	endif

	if ((StringMatch(CurrentFolder, GetDataFolder(0)) == 0) && (IsNMDataFolder(CurrentFolder) == 1))
		NMFolderChange(CurrentFolder) // data folder has changed, move back to current folder
	endif
	
	String thisFolder = GetDataFolder(0)
	String currentFile = StrVarOrDefault("CurrentFile", "")
	
	Variable lastMode = NumVarOrDefault("CT_RecordMode", 0)
	
	if (IsNMDataFolder(thisFolder) == 1)
	
		if (StringMatch(folderName, thisFolder) == 1)
		
			if ((lastMode == 0) && (strlen(currentFile) == 0))
				return 0
			endif
			
		else
		
			if ( 0 && (lastMode == 0) && (strlen(currentFile) == 0))
			
				thisFolder = NMFolderRename(thisFolder, folderName)
				
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

	String df, cdf = ClampDF()

	String newfolder = ClampDataFolderName(1) // folder name
	String oldfolder = StrVarOrDefault(cdf+"CurrentFolder", "")
	
	String extfile = StrVarOrDefault("CurrentFile", "")
	
	String wavePrefix = StimWavePrefix( "" )
	
	Variable autoClose = NumVarOrDefault(cdf+"AutoCloseFolder", 0)
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	
	if ((autoClose == 1) && (SaveWhen > 0) && (IsNMDataFolder(oldfolder) == 1))
	
		if (strlen(extfile) > 0)
			SetNeuroMaticVar( "ChanGraphCloseBlock", 1 ) // block closing chan graphs
			ClampGraphsUpdate(0)
			ClampStatsRemoveWavesAll( 0 )
			ClampSpikeRemoveWaves( 0 )
			NMFolderClose(oldfolder) // close current folder before opening new one
			ClampDataFolderCloseEmpty()
		endif
		
	endif
	
	SetNeuroMaticVar( "UpdateNMBlock", 1 ) // block update
	newfolder = NMFolderNew(newfolder) // create a new folder
	SetNeuroMaticVar( "UpdateNMBlock", 0 ) // unblock
	
	CheckNMwave("CT_TimeStamp", 0, Nan)
	CheckNMwave("CT_TimeIntvl", 0, Nan)
	
	if (strlen(newfolder) == 0)
		return -1
	endif
	
	SetNMstr(cdf+"CurrentFolder", newfolder)
	
	SetNMstr(newfolder+"WavePrefix", wavePrefix)
	SetNMstr(newfolder+"CurrentPrefix", wavePrefix)
	
	NMPrefixFolderMake( newfolder, wavePrefix, 1, 0 )
	
	SetNMVar(cdf+"GetChanConfigs", 1) // get chan graph configs
	SetNeuroMaticVar( "ChanGraphCloseBlock", 0 ) // block closing chan graphs
	
End // ClampDataFolderNew

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderCloseEmpty()

	Variable icnt, numWaves, match
	String extfile, wavePrefix, prefixFolder, cdf = ClampDF()
	
	String prefix = ClampFolderPrefix()
	
	String folderName, flist = NMDataFolderList()
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		folderName = StringFromList(icnt, flist)
		
		wavePrefix = StrVarOrDefault( folderName+"WavePrefix", "" )
		
		if ( strlen( wavePrefix ) == 0 )
			continue
		endif
		
		prefixFolder = NMPrefixFolderDF( folderName, wavePrefix )
		numWaves = NumVarOrDefault(prefixFolder+"NumWaves", 0)
		
		extfile = StrVarOrDefault("root:" + folderName + ":CurrentFile", "")
		match = strsearch(UpperStr(folderName), UpperStr(prefix), 0)
		
		if ((match >= 0) && (numWaves == 0) && (strlen(extfile) == 0))
			NMFolderClose(folderName)
		endif
		
	endfor

End // ClampDataFolderCloseEmpty

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderUpdate(nwaves, mode)
	Variable nwaves
	Variable mode // (0) preview (1) record
	
	Variable config, ccnt, nchans, icnt
	String wPrefix, wlist, name, units, modeStr
	
	String cdf = ClampDF(), sdf = StimDF(), ndf = NotesDF(), gdf = cdf+"Temp:", bdf = StimBoardDF(sdf)

	Variable CopyStim2Folder = NumVarOrDefault(cdf+"CopyStim2Folder", 1)
	
	String CurrentStim = StimCurrent()
	String prefixFolder = CurrentNMPrefixFolder()
	
	if (WaveExists($bdf+"ADCname") == 1)

		Wave /T ADCname = $(bdf+"ADCname")
		Wave /T ADCunits = $(bdf+"ADCunits")
		Wave /T ADCmode = $(bdf+"ADCmode")
		
		nchans = StimBoardNumADCchan("")
		
		Make /T/O/N=(nchans) yLabel
		
		for (config = 0; config < numpnts(ADCname); config += 1)
		
			modeStr = ADCmode[ config ]
			
			if ( ( strlen( ADCname[ config ] ) > 0 ) && ( StimADCmodeNormal( modeStr ) == 1 ) )
			
				if ( NMMultiClampTelegraphMode( modeStr ) == 1 )
					name = NMMultiClampADCStr( sdf, config, "name" )
					units = NMMultiClampADCStr( sdf, config, "units" )
				else
					name = ADCname[ config ]
					units = ADCunits[ config ]
				endif
				
				yLabel[ ccnt ] = name + " (" + units + ")"
				ccnt += 1
				
			endif
			
		endfor
		
	endif
	
	SetNMstr(cdf+"CurrentFolder", GetDataFolder(0))
	
	wPrefix = StimWavePrefix("")

	SetNMstr("WavePrefix", wPrefix)
	SetNMstr("CurrentPrefix", wPrefix)
	SetNMstr( "xLabel", "msec" )

	SetNMvar(prefixFolder+"NumChannels", ccnt)
	SetNMvar(prefixFolder+"NumWaves", nwaves)
	SetNMvar(prefixFolder+"NumGrps", NumVarOrDefault(sdf+"NumStimWaves", 1))
	
	SetNMvar("SamplesPerWave", NumVarOrDefault(sdf+"SamplesPerWave", 0))
	SetNMvar("SampleInterval", NumVarOrDefault(sdf+"SampleInterval", 0))
	
	SetNMvar("CT_RecordMode", mode)
	
	SetNMvar("FileDateTime", DateTime)
	
	SetNMstr("FileDate", date())
	SetNMstr("FileTime", time())
	
	switch(NumVarOrDefault(sdf+"AcqMode", 0))
		case 0:
			SetNMstr("AcqMode", "epic precise")
			break
		case 1:
			SetNMstr("AcqMode", "continuous")
			break
		case 2:
			SetNMstr("AcqMode", "episodic")
			break
		case 3:
			SetNMstr("AcqMode", "episodic triggered")
			break
		case 4:
			SetNMstr("AcqMode", "continuous triggered")
			break
		default:
			SetNMstr("AcqMode", "")
			break
	endswitch
	
	CheckNMwave("CT_TimeStamp", nwaves, Nan) // waves to save acquisition times
	CheckNMwave("CT_TimeIntvl", nwaves, Nan)
	
	SetNMwave("CT_TimeStamp", -1, Nan)
	SetNMwave("CT_TimeIntvl", -1, Nan)
	
	//CheckNMPrefixFolderWaves( "" ) // redimension NM waves
	
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
	
	if (NMStimStatsOn() == 0)
		ClampStatsRemoveWavesAll( 1 )
	endif
	
	if (NMStimSpikeOn() == 0)
		ClampSpikeRemoveWaves( 1 )
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

Function ClampDataFolderSaveCheckAll()

	Variable icnt, mode
	String df, folder, file, cdf = ClampDF(), flist = NMDataFolderList()
	
	String currentFolder = StrVarOrDefault(cdf+"CurrentFolder", "")
	
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	
	flist = RemoveFromList(currentFolder, flist)
	
	if (SaveWhen == 0)
		return 0 // nothing to do
	endif
	
	for (icnt = 0; icnt < ItemsInlist(flist); icnt += 1)
	
		folder = StringFromList(icnt, flist)
		df = "root:" + folder + ":"
		
		mode = NumVarOrDefault(df+"CT_RecordMode", 0)
		file = StrVarOrDefault(df+"CurrentFile", "")
		
		if ((WaveExists($df+"CT_TimeStamp") == 1) && (mode == 1) && (strlen(file) == 0))
			ClampSaveFinish(df)
		endif
	
	endfor

End // ClampDataFolderSaveCheckAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampSaveSubPath()

	String subStr, cdf = ClampDF()
	String ClampPathStr = StrVarOrDefault(cdf+"ClampPath", "")
	String prefix = ClampFolderPrefix()
	
	Variable saveSub = NumVarOrDefault(cdf+"SaveInSubfolder", 1)
	Variable cell = NumVarOrDefault(cdf+"DataFileCell", Nan)
	
	if ((saveSub == 0) || (strlen(ClampPathStr) == 0))
		return ""
	endif
	
	if (numtype(cell) == 0)
		prefix += "c" + num2istr(cell)
	endif
	
	if ((strlen(ClampPathStr) > 0) && (strlen(prefix) > 0))
	
		subStr = ClampPathStr + prefix + ":"
		
		NewPath /C/Z/O/Q ClampSubPath subStr
		
		if (V_flag != 0)
			ClampError( 1, "ClampSaveFinish: failed to create external path  " + subStr )
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

Function /S ClampSaveFinish( folder )
	String folder // NM folder to save, ("") for current folder

	String file, cdf = ClampDF()
	String path = ClampSavePathGet()
	
	Variable saveFormat = NumVarOrDefault(cdf+"SaveFormat", 1)
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	Variable ask = NumVarOrDefault(cdf+"SaveWithDialogue", 1)

	if ((SaveFormat == 1) || (SaveFormat == 3)) // NM binary
	
		if (saveWhen == 1) // save after recording (Igor 4)
		
			file = FileBinSave(ask, 1, folder, path, "", 1, 0) // NM_FileManager.ipf
			
		elseif (saveWhen == 2) // save while recording (Igor 4 and 5)
		
			file = ClampNMbinAppend("CT_TimeStamp") // append
			file = ClampNMbinAppend("CT_TimeIntvl") // append
			file = ClampNMbinAppend("close file") // close file
			ask = 0
			
		endif
		
	endif
	
	if ((SaveFormat == 2) || (SaveFormat == 3)) // Igor binary
		file = FileBinSave(ask, 1, folder, path, "", 1, 1) // NM_FileManager.ipf
	endif
	
	path = GetPathName(file, 1)
	
	PathInfo /S ClampSaveDataPath
	
	if (strlen(S_path) > 0)
	
		SetNMStr(cdf+"ClampPath", S_path)
		
	elseif ((strlen(file) > 0) && (strlen(path) > 0))
	
		NewPath /Z/Q/O ClampSaveDataPath path
		
		PathInfo /S ClampSaveDataPath
		
		if (strlen(S_path) > 0)
			SetNMStr(cdf+"ClampPath", S_path)
		else
			ClampError( 1, "ClampSaveFinish: failed to create external path  " + path )
		endif
		
	endif
	
	if (strlen(file) == 0)
	
		SetNMstr(LastPathColon(folder, 1) + "CurrentFile", "")
		
		if ( strlen( folder) == 0 )
			folder = GetDataFolder(1)
		endif
		
		Print "ClampSaveFinish: failed to save folder " + folder
		
	endif
	
	ClampErrorCheck( "ClampSaveFinish" )
	
	return file

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
	
	PathInfo /S ClampSaveDataPath
	
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
		slist = IndexedFile(ClampSaveDataPath,-1,"????")
	endif
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1)
	
		file = StringFromList(icnt, slist)
		
		if (StrSearch(file, folderName, 0, 2) >= 0)
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

	String folderName, cdf = ClampDF()
	
	Variable seq = NumVarOrDefault(cdf+"LogFileSeq", -1)
	Variable cell = ClampDataFolderCell()
	
	String prefix = ClampFolderPrefix()
	
	if (numtype(cell) == 0)
		prefix += "c" + num2istr(cell)
	endif

	if (seq >= 0)
		return prefix + "_log" + num2istr(seq)
	endif
	
	for (icnt = ibgn; icnt <= iend; icnt += 1)
	
		folderName = prefix + "_log" + num2istr(icnt)
		
		folderName = CheckFolderNameChar( folderName )

		if (ClampSaveTest(folderName) == 0)
			break
		endif
	
	endfor
	
	SetNMvar(cdf+"LogFileSeq", icnt)
	
	return folderName

End // LogFolderName

//****************************************************************
//****************************************************************
//****************************************************************

Function LogCheckFolder(ldf) // check log data folder exists
	String ldf // log data folder
	
	ldf = LastPathColon(ldf,1)
	
	if (DataFolderExists(ldf) == 0) // check Log folder exists
		NewDataFolder $RemoveEnding( ldf, ":" )
		SetNMstr(ldf+"FileType", "NMLog")
		SetNMstr(ldf+"FileDate", date())
		SetNMstr(ldf+"FileTime", time())
	endif
	
	return ClampErrorCheck( "LogCheckFolder" )
	
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
		DoAlert 0, "Error: data folder " + NMQuotes( ldf ) + " does not appear to exist."
		return -1
	endif
	
	if (StringMatch(StrVarOrDefault(ldf+"FileType", ""), "NMLog") == 0)
		DoAlert 0, "Error: data folder " + NMQuotes( ldf ) + " does not appear to be a NeuroMatic Log folder."
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