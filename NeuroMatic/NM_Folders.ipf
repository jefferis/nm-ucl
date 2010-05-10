#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Folder Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	Began 5 May 2002
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderCall( fxn )
	String fxn
	
	strswitch( fxn )
	
		case "Edit This List":
			NMFolderListEdit()
			break
	
		case "New":
			NMFolderNewCall()
			break
			
		case "Open":
			NMFolderOpen()
			break
			
		case "Open All":
			NMFolderOpenAll()
			break
		
		//case "Append All":
		//	NMFolderAppendAll()
		//	break
			
		//case "Append":
		//case "Open | Append":
		//	NMFolderAppend()
		//	break
		
		case "Merge":
			NMFoldersMerge()
			break
			
		case "Save":
			NMFolderSave()
			break
			
		case "Save All":
			NMFolderSaveAll()
			break
		
		case "Kill":
		case "Close":
			NMFolderCloseCurrentCall()
			break
			
		case "Kill All":
		case "Close All":
			DoAlert 1, "Are you sure you want to close all NeuroMatic data folders?"
			if ( V_Flag != 1 )
				break
			endif
			NMCmdHistory( "NMFolderCloseAll", "" )
			NMFolderCloseAll()
			break
			
		case "Duplicate":
			NMFolderDuplicateCall()
			break
			
		case "Rename":
			NMFolderRenameCall()
			break
			
		case "Change":
			NMFolderChangeCall()
			break
			
		case "Import":
		case "Import Data":
		case "Import Waves":
			NMImportFileCall()
			break
			
		case "Import All":
			NMImportAllCall()
			break
			
		case "Load All Waves":
			NMLoadAllWavesFromExtFolderCall()
			break
			
		case "Reload":
		case "Reload Data":
		case "Reload Waves":
			NMDataReloadCall()
			break
			
		case "Rename Waves":
			NMRenameWavesCall( "All" ) // NM_MainTab.ipf
			break
			
		case "Convert":
			NMBin2IgorCall()
			break
			
		case "Open Path":
		case "Set Open Path":
			SetOpenDataPathCall()
			break
			
		case "Save Path":
		case "Set Save Path":
			SetSaveDataPathCall()
			break
			
		default:
			NMDoAlert( "NMFolderCall: unrecognized function call: " + fxn )
			
	endswitch
	
End // NMFolderCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SetOpenDataPathCall()

	NMCmdHistory( "SetOpenDataPath", "" )
	SetOpenDataPath()

End // SetOpenDataPathCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SetOpenDataPath()
	
	NewPath /Q/O/M="Stim File Directory" OpenDataPath
	
	if ( V_flag == 0 )
		PathInfo OpenDataPath
		SetNeuroMaticStr( "OpenDataPath", S_path )
		//NMDoAlert( "Don't forget to save changes by saving your Configurations ( NeuroMatic > Configs > Save )."
	endif
	
	return V_flag

End // SetOpenDataPath

//****************************************************************
//****************************************************************
//****************************************************************

Function SetSaveDataPathCall()

	NMCmdHistory( "SetSaveDataPath", "" )
	SetSaveDataPath()

End // SetSaveDataPathCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SetSaveDataPath()
	
	NewPath /Q/O/M="Stim File Directory" SaveDataPath
	
	if ( V_flag == 0 )
		PathInfo SaveDataPath
		SetNeuroMaticStr( "SaveDataPath", S_path )
		//NMDoAlert( "Don't forget to save changes by saving your Configurations ( NeuroMatic > Configs > Save )."
	endif
	
	return V_flag

End // SetSaveDataPath

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckCurrentFolder() // check to make sure we are sitting in the current NM folder

	String currentFolder = CurrentNMFolder( 1 ) 
	
	if ( NeuroMaticVar( "NMOn" ) == 0 )
		return 0
	endif

	if ( StringMatch( currentFolder, GetDataFolder( 1 ) ) == 1 )
		return 1 // OK
	endif
	
	if ( ( strlen( currentFolder ) > 0 ) && ( DataFolderExists( currentFolder ) == 1 ) )
		SetDataFolder currentFolder
		UpdateNM( 0 )
		return 1
	endif
	
	return 0

End // CheckCurrentFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMWavePrefix()

	String currentFolder = CurrentNMFolder( 1 )

	return StrVarOrDefault( currentFolder + "CurrentPrefix", "" )

End // CurrentNMWavePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMFolder( path )
	Variable path // ( 0 ) no path ( 1 ) with path
	
	String currentFolder = NeuroMaticStr( "CurrentFolder" )
	
	if ( strlen( currentFolder ) == 0 )
		return ""
	endif
	
	if ( DataFolderExists( currentFolder ) == 0 )
		return ""
	endif
	
	if ( IsNMDataFolder( currentFolder ) == 0 )
		return ""
	endif
	
	if ( path == 0 )
		return GetPathName( currentFolder, 0 )
	endif
	
	return currentFolder

End // CurrentNMFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMFolderPath( folder )
	String folder
	
	if ( strlen( folder ) == 0 )
		return CurrentNMFolder( 1 )
	endif
	
	if ( strlen( folder ) == 0 )
		return ""
	endif
	
	if ( StringMatch( folder[ 0,4 ], "root:" ) == 0 )
		folder = "root:" + folder + ":" // create full-path
	endif
	
	folder = LastPathColon( folder, 1 )
		
	return folder

End // CheckNMFolderPath

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMDataFolders() // check all NM Data folders

	Variable icnt

	String fList = NMDataFolderList()
	
	for ( icnt = 0 ; icnt < ItemsInList( flist ) ; icnt += 1 )
		CheckNMDataFolder( StringFromList( icnt, flist ) )
	endfor
	
End // CheckNMDataFolders

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMDataFolder( folder ) // check data folder globals
	String folder
	
	Variable ccnt, changeFolder
	String wavePrefix, subfolder
	
	Variable NMver = NeuroMaticVar( "NMversion" )
	
	String saveCurrentFolder = NeuroMaticStr( "CurrentFolder" )
	
	folder = CheckNMFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return -1
	endif
	
	if ( StringMatch( folder, saveCurrentFolder ) == 0 )
		changeFolder = 1
		SetNeuroMaticStr( "CurrentFolder", folder )
	endif
 
	wavePrefix = StrVarOrDefault( folder+"WavePrefix", "" )
	
	CheckNMFolderType( folder )
	
	CheckNMvar( folder+"FileFormat", NMver )
	CheckNMvar( folder+"FileDateTime", DateTime )
	
	CheckNMstr( folder+"FileType", "NMData" )				// NM data folder
	CheckNMstr( folder+"FileDate", date() )
	CheckNMstr( folder+"FileTime", time() )
	
	//CheckOldNMDataNotes( folder )
	
	NMPrefixFolderUtility( folder, "rename" ) // new names for old prefix subfolders
	
	CheckNMDataFolderFormat6( folder )
	
	NMPrefixFolderUtility( folder, "check" ) // check for globals
	
	subfolder = NMPrefixFolderDF( folder, wavePrefix )
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
		ChanGraphSetCoordinates( ccnt )
	endfor
	
	//if ( ( NumVarOrDefault( subfolder+"NumGrps", 0 ) == 0 ) && ( exists( "NumStimWaves" ) == 2 ) )
	//	SetNMvar( subfolder+"NumGrps", NumVarOrDefault( "NumStimWaves", 0 ) )
	//	SetNMvar( subfolder+"CurrentGrp", Nan )
	//	NMGroupSeqDefault() // set Groups for Nclamp data
	//endif
	
	if ( changeFolder == 1 )
		SetNeuroMaticStr( "CurrentFolder", saveCurrentFolder )
	endif
	
	return 0
	
End // CheckNMDataFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMDataFolderFormat6( folder )
	String folder

	Variable icnt
	String vname, waveSelect
	
	if ( strlen( folder ) == 0 )
		return -1
	endif
	
	String setList = NMSetsWavesList( folder, 0 )
	
	String wlist = "ChanSelect;ChanWaveList;WavSelect;Group;"
	String vList = "NumChannels;CurrentChan;NumWaves;CurrentWave;"
	String kvList = "SumSet1;SumSet2;SumSetX;NumActiveWaves;CurrentChan;CurrentWave;CurrentGrp;FirstGrp;"
	
	String currentPrefix = StrVarOrDefault( folder+"CurrentPrefix", "" )
	String prefixFolder = NMPrefixFolderDF( folder, currentPrefix )
	
	Variable numChannels = NumVarOrDefault( folder+"NumChannels", 0 )
	Variable numWaves = NumVarOrDefault( folder+"NumWaves", 0 )
	
	if ( strlen( currentPrefix ) == 0 )
		return 0 // nothing to update
	endif
	
	String twList = NMFolderWaveList( folder, "wNames_*", ";", "TEXT:1", 0 )
	
	vname = folder+"WavSelect"
	
	if ( ( WaveExists( $folder+"WaveSelect" ) == 1 ) && ( WaveExists( $vname ) == 0 ) )
		Rename $folder+"WaveSelect" $vname // rename old wave
	endif

	if ( ( WaveExists( $folder+"ChanSelect" ) == 0 ) && ( WaveExists( $vname ) == 0 ) )
		return 0 // nothing to do, must be new NM data folder format
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	if ( DataFolderExists( prefixFolder ) == 0 )
		NewDataFolder $RemoveEnding( prefixFolder, ":" )
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( vList ) ; icnt += 1 ) // copy old variables to new subfolder
	
		vname = StringFromList( icnt, vList )
		
		if ( exists( folder+vname ) != 2 )
			continue
		endif
		
		Variable /G $prefixFolder+vname = NumVarOrDefault( folder+vname, Nan )
		
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( kvList ) ; icnt += 1 ) // kill unecessary old variables
	
		vname = StringFromList( icnt, kvList )
		
		if ( exists( folder+vname ) == 2 )
			KillVariables /Z $folder+vname
		endif

	endfor
	
	wList = NMAddToList( setList, wList, ";" )
	wList = NMAddToList( twList, wList, ";" )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 ) // copy old waves to new subfolder
	
		vname = StringFromList( icnt, wList )
		
		if ( WaveExists( $folder+vname ) == 0 )
			continue
		endif
		
		Duplicate /O $folder+vname $prefixFolder+vname
		
		if ( WaveExists( $prefixFolder+vname ) == 1 )
			KillWaves /Z $folder+vname
		endif
		
	endfor
	
	for ( icnt = 0 ; icnt < numChannels ; icnt += 1 ) // copy channel graph folders to new subfolder
		
		vname = ChanGraphName( icnt ) // channel graph folder name
		
		if ( ( DataFolderExists( folder+vname ) == 1 ) && ( DataFolderExists( prefixFolder+vname ) == 0 ) )
		
			DuplicateDataFolder $folder+vname $prefixFolder+vname
			
			if ( DataFolderExists( prefixFolder+vname ) == 1 )
				KillDataFolder /Z $folder+vname
			endif
			
		endif
		
	endfor
	
	NMHistory( "Converted NM data folder " + NMQuotes( folder ) + " to version " + num2str( NMVersion() ) )

End // CheckNMDataFolderFormat6

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckOldNMDataNotes( folder ) // check data notes of old NM acquired data
	String folder
	
	Variable ccnt, wcnt
	String wList, wNote, yl
	
	String wname = "ChanWaveList" // OLD WAVE
	String ywname = "yLabel"
	
	folder = CheckNMFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return 0
	endif
	
	String wavePrefix = StrVarOrDefault( folder+"WavePrefix", "" )
	
	if ( strlen( wavePrefix ) == 0 )
		return 0 // nothing to do
	endif
	
	if ( ( WaveExists( $wname ) == 0 ) || ( WaveExists( $ywname ) == 0 ) )
		return 0
	endif
	
	String type = StrVarOrDefault( folder+"DataFileType", "" )
	String file = StrVarOrDefault( folder+"CurrentFile", "" )
	String fdate = StrVarOrDefault( folder+"FileDate", "" )
	String ftime = StrVarOrDefault( folder+"FileTime", "" )
	
	String xl = StrVarOrDefault( "xLabel", "" )
	
	String stim = SubStimName( folder )
	
	Wave /T wtemp = $wname
	Wave /T ytemp = $ywname
	
	strswitch( type )
		case "IgorBin":
		case "NMBin":
			type = "NMData"
	endswitch
	
	for ( ccnt = 0; ccnt < numpnts( wtemp ); ccnt += 1 )
	
		wList = wtemp[ ccnt ]
		yl = ytemp[ ccnt ]
		
		for ( wcnt = 0; wcnt < ItemsInlist( wList ); wcnt += 1 )
		
			wname = StringFromList( wcnt, wList )
			
			if ( WaveExists( $folder+wname ) == 0 )
				continue
			endif
			
			//if ( strsearch( wname, wavePrefix, 0, 2 ) < 0 )
			if ( strsearch( wname, wavePrefix, 0 ) < 0 )
				continue
			endif
			
			if ( strlen( NMNoteStrByKey( folder+wname, "Type" ) ) == 0 )
				wNote = "Stim:" + stim
				wNote += "\rFolder:" + GetPathName( folder, 0 )
				wNote += "\rDate:" + NMNoteCheck( fdate )
				wNote += "\rTime:" + NMNoteCheck( ftime )
				wNote += "\rChan:" + ChanNum2Char( ccnt )
				NMNoteType( folder+wname, type, xl, yl, wNote )
			endif
			
			if ( strlen( NMNoteStrByKey( folder+wname, "File" ) ) == 0 )
				Note $folder+wname, "File:" + NMNoteCheck( file )
			endif
			
		endfor
	
	endfor
	
End // CheckOldNMDataNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFolderType( folder )
	String folder
	
	folder = CheckNMFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return -1
	endif
	
	if ( exists( folder+"FileType" ) == 0 )
		return -1
	endif

	String ftype = StrVarOrDefault( folder+"FileType", "" )
	
	if ( StringMatch( ftype, "pclamp" ) == 1 )
	
		SetNMstr( folder+"DataFileType", "pclamp" )
		SetNMstr( folder+"FileType", "NMData" )
		
	elseif ( StringMatch( ftype, "axograph" ) == 1 )
	
		SetNMstr( folder+"DataFileType", "axograph" )
		SetNMstr( folder+"FileType", "NMData" )
		
	elseif ( strlen( ftype ) == 0 )
	
		SetNMstr( folder+"FileType", "NMData" )
		
	endif
	
	return 0

End // CheckNMFolderType

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderNewCall()

	String folder = FolderNameNext( "" )
	
	Prompt folder, "enter new folder name:"
	DoPrompt "Create New NeuroMatic Folder", folder
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	NMCmdHistory( "NMFolderNew", NMCmdStr( folder,"" ) )
	
	NMFolderNew( folder )

End // NMFolderNewCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderNew( folder ) // create a new NM data folder
	String folder // name of folder, or "" for next default name
	
	if ( strlen( folder ) == 0 )
		folder = FolderNameNext( "" )
	else
		folder = GetPathName( folder, 0 )
	endif
	
	folder = CheckFolderName( folder )
	
	if ( strlen( folder ) == 0 )
		return ""
	endif
	
	folder = "root:" + folder + ":"

	if ( DataFolderExists( folder ) == 1 )
		return "" // already exists
	endif
	
	NewDataFolder /S $RemoveEnding( folder, ":" )
	
	SetNeuroMaticStr( "CurrentFolder", GetDataFolder( 1 ) )
	
	CheckNMDataFolder( folder )
	NMFolderListAdd( folder )
	ChanGraphsReset()
	UpdateNM( 1 )
	
	return folder // return folder name

End // NMFolderNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderChangeCall() // change the active folder

	String folder, flist = NMDataFolderList()
	
	folder = StringFromList( 0, flist )
	
	folder = GetPathName( folder, 0 )
	
	flist = RemoveFromList( CurrentNMFolder( 0 ) , flist ) // remove active folder from list

	If ( ItemsInList( flist ) == 0 )
		NMDoAlert( "Abort NMFolderChange: no folders to change to." )
		return ""
	endif
	
	Prompt folder, "choose folder:", popup flist
	DoPrompt "Change NeuroMatic Folder", folder
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	NMCmdHistory( "NMFolderChange", NMCmdStr( folder,"" ) )
	
	return NMFolderChange( folder )

End // NMFolderChangeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderChange( folder ) // change the active folder
	String folder
	
	if ( strlen( folder ) == 0 )
		return ""
	endif
	
	folder = CheckNMFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		NMDoAlert( "Abort NMFolderChange: " + folder + " does not exist." )
		return ""
	endif
	
	if ( IsNMFolder( folder, "NMLog" ) == 1 )
		Execute "LogDisplayCall(" + NMQuotes( folder ) + ")"
		return ""
	endif
	
	if ( IsNMDataFolder( folder ) == 0 )
		return ""
	endif
	
	if ( strlen( NMFolderListName( folder ) ) == 0 )
		NMFolderListAdd( folder )
	endif
	
	ChanScaleSave( -1 )
	
	SetDataFolder folder
	
	SetNeuroMaticStr( "CurrentFolder", GetDataFolder( 1 ) )
	
	ChanGraphsReset()
	NMChanWaveListSet( 0 ) // check channel wave names
	UpdateNM( 1 )
	
	return folder

End // NMFolderChange

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderChangeToFirst()

	String flist = NMDataFolderList()
		
	if ( ItemsInList( flist ) > 0 )
		return NMFolderChange( StringFromList( 0,flist ) ) // change to first data folder
	else
		NMFolderNew( "" )
	endif
		
End // NMFolderChangeToFirst

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderCloseAll()
	Variable icnt
	String fname
	
	String flist = NMDataFolderList() + NMFolderList( "root:","NMLog" )
	
	if ( ItemsInList( flist ) == 0 )
		return 0
	endif
	
	//flist = RemoveFromList( "nm_folder0", flist ) // remove default folder if it still exists
	
	for ( icnt = 0; icnt < ItemsInlist( flist ); icnt += 1 )
		NMFolderClose( StringFromList( icnt,flist ) )
	endfor
	
	SetNeuroMaticStr( "CurrentFolder", "" )
	
	NMFolderChangeToFirst()
	
	//UpdateNMPanelTitle()

End // NMFolderCloseAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderCloseCurrentCall()

	String folder = CurrentNMFolder( 0 )

	String txt = "Are you sure you want to close " +  folder + "?"
	txt += " This will kill all graphs, tables and waves associated with this folder."
	
	DoAlert 1, txt
	
	if ( V_flag != 1 )
		return ""
	endif
	
	NMCmdHistory( "NMFolderCloseCurrent", "" )
	
	return NMFolderCloseCurrent()

End // NMFolderCloseCurrentCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderCloseCurrent()

	Variable inum
	String txt, nfolder = ""
	
	String folder = CurrentNMFolder( 0 )
	String flist = NMDataFolderList()
	
	inum = WhichListItem( folder, flist )
	
	if ( inum < 0 )
		return ""
	endif
	
	nfolder = StringFromList( inum-1, flist )

	if ( NMFolderClose( folder ) == -1 )
		return ""
	endif
	
	if ( IsNMDataFolder( folder ) == 1 )
		return ""
	endif
	
	SetNeuroMaticStr( "CurrentFolder", "" )
	
	if ( strlen( nfolder ) > 0 )
		return NMFolderChange( nfolder ) // change to next data folder
	else
		return NMFolderChangeToFirst()
	endif
	
	//UpdateNMPanelTitle()
	
	return ""
	
End // NMFolderCloseCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderClose( folder ) // close/kill a data folder
	String folder // folder path
	
	String wname
	String currentFolder = CurrentNMFolder( 1 )
	
	if ( strlen( folder ) == 0 )
		return -1
	endif
	
	folder = CheckNMFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return -1
	endif
	
	NMKillWindows( folder ) // old kill method
	NMFolderWinKill( folder ) // new FolderList function
	
	if ( StringMatch( currentFolder, folder ) == 1 )
		ChanGraphClose( -1, 0 )
	endif
	
	NMPrefixFolderUtility( folder, "unlock" )

	KillDataFolder /Z $folder
	
	if ( DataFolderExists( folder ) == 1 )
		NMFolderCloseAlert( folder )
	else
		NMFolderListRemove( folder )
		NMFolderChangeToFirst()
	endif
	
	return 0

End // NMFolderClose

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderCloseAlert( folder )
	String folder

	String txt = "Failed to close data folder " + NMQuotes( GetPathName( folder, 0 ) )
	txt += ". Waves that reside in this folder may be currently displayed in a graph or table"
	txt += ", or may be locked."
	
	NMDoAlert( txt )

End // NMFolderCloseAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function NMKillWindows( folder )
	String folder
	
	Variable wcnt
	String wName
	
	if ( ( strlen( folder ) == 0 ) || ( IsNMDataFolder( folder ) == 0 ) )
		return -1
	endif
	
	folder = GetPathName( folder, 0 )
	
	String wlist = WinList( "*" + folder + "*", ";", "" )
	
	for ( wcnt = 0; wcnt < ItemsInList( wlist ); wcnt += 1 )
	
		wName = StringFromList( wcnt,wlist )
		
		if ( ( strlen( wName ) > 0 ) && ( winType( wName ) > 0 ) )
			DoWindow /K $wName
		endif
		
	endfor
	
	return 0
	
End // NMKillWindows

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderWinKill( folder )
	String folder
	
	String wname
	Variable wcnt
	
	if ( IsNMDataFolder( folder ) == 0 )
		return -1
	endif
	
	String wlist = WinList( "*" + NMFolderPrefix( folder ) + "*", ";", "" )
	
	for ( wcnt = 0; wcnt < ItemsInList( wlist ); wcnt += 1 )
		
		wname = StringFromList( wcnt,wlist )
		
		if ( WinType( wname ) == 0 )
			continue
		endif
		
		DoWindow /K $wname
		
	endfor
	
	return 0
	
End // NMFolderWinKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderDuplicateCall()

	String folder = CurrentNMFolder( 0 )
	String newName = FolderNameNext( folder + "_copy0" )
	String vlist = ""
	
	Prompt newName, "enter new folder name:"
	DoPrompt "Duplicate NeuroMatic Data Folder", newName
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( folder, newName ) == 1 )
		return -1 // not allowed
	endif
	
	//if ( DataFolderExists( CheckNMFolderPath( newName ) ) == 1 )
	//	NMDoAlert( "Abort NMFolderDuplicate: folder name already in use."
	//	return -1
	//endif
	
	vlist = NMCmdStr( folder, vlist )
	vlist = NMCmdStr( newName, vlist )
	NMCmdHistory( "NMFolderDuplicate", vlist )
	
	NMFolderDuplicate( folder, newName )
	
	return 0

End // NMFolderDuplicateCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderDuplicate( folder, newName ) // duplicate NeuroMatic data folder
	String folder // folder to copy
	String newName
	
	String newFolder
	
	folder = CheckNMFolderPath( folder )
	
	if ( DataFolderExists( folder ) == 0 )
		return ""
	endif
	
	newFolder = CheckNMFolderPath( newName )
	newFolder = CheckFolderName( newFolder )
	
	if ( ( strlen( newFolder ) == 0 ) || ( DataFolderExists( newFolder ) == 1 ) )
		return ""
	endif
	
	DuplicateDataFolder $RemoveEnding( folder, ":" ), $RemoveEnding( newFolder, ":" )
	
	NMFolderListAdd( newName )
	
	return newName

End // NMFolderDuplicate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderRenameCall()

	String oldName = CurrentNMFolder( 0 )
	String newName = oldName
	String vlist = ""
	
	Prompt newName, "rename " + NMQuotes( oldName ) + " as:"
	DoPrompt "Rename NeuroMatic Data Folder", newName
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( oldName, newName ) == 1 )
		return -1 // nothing new
	endif
	
	//if ( DataFolderExists( CheckNMFolderPath( newName ) ) == 1 )
	//	NMDoAlert( "Abort NMFolderRename: folder name already in use."
	//	return -1
	//endif
	
	vlist = NMCmdStr( oldName, vlist )
	vlist = NMCmdStr( newName, vlist )
	NMCmdHistory( "NMFolderRename", vlist )
	
	NMFolderRename( oldName, newName )
	
	return 0

End // NMFolderRenameCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderRename( oldName, newName ) // rename NeuroMatic data folder
	String oldName
	String newName
	
	oldName = CheckNMFolderPath( oldName )
	
	if ( DataFolderExists( oldName ) == 0 )
		return ""
	endif
	
	oldName = GetPathName( oldName, 0 )
	newName = GetPathName( newName, 0 )
	
	// note, this function does NOT change graph or table names
	// associated with the old folder name
	
	if ( ( strlen( oldName ) == 0 ) || ( strlen( newName ) == 0 ) )
		return ""
	endif
	
	if ( DataFolderExists( "root:" + oldName ) == 0 )
		NMDoAlert( "Abort NMFolderRename: folder " + NMQuotes( oldName ) + " does not exist" )
		return ""
	endif
	
	if ( DataFolderExists( "root:" + newName ) == 1 )
		NMDoAlert( "Abort NMFolderRename: folder name " + NMQuotes( newName ) + " is already in use." )
		return ""
	endif
	
	RenameDataFolder $"root:"+oldName, $newName
	
	NMFolderListChange( oldName, newName )
	
	SetNeuroMaticStr( "CurrentFolder", GetDataFolder( 1 ) )
	
	UpdateNM( 0 )
	
	return newName

End // NMFolderRename

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderOpen()
	
	String fname = FileBinOpen( 1, 1, "root:", "OpenDataPath", "", 1 )
	
	NMTab( "Main" ) // force back to Main tab
	UpdateNM( 1 )
	
	return fname

End // NMFolderOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderOpenAll()

	Variable icnt
	String fname, flist

	flist = FileBinOpenAll( 1, "root:", "OpenDataPath" )
	
	if ( ItemsInList( flist ) == 0 )
	
		return ""
		
	else
		
		fname = StringFromList( 0, flist )
		NMFolderChange( fname ) 
		
	endif
	
	NMTab( "Main" ) // force back to Main tab
	UpdateNM( 1 )

	return flist

End // NMFolderOpenAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDataReloadCall()

	DoAlert 1, "Warning: reloading will over-write existing data. Do you want to continue?"
	
	if ( V_Flag != 1 )
		return 0
	endif

	NMCmdHistory( "NMDataReload", "" )
	NMDataReload()

End // NMDataReloadCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDataReload()

	String file = StrVarOrDefault( "CurrentFile", "" )
	String temp = CheckNMFolderPath( "reload_temp" )
	String folder, saveDF = GetDataFolder( 1 )
	
	String wavePrefix = StrVarOrDefault( "WavePrefix", "" )
	
	if ( strlen( wavePrefix ) == 0 )
		return -1
	endif
	
	if ( FileExists( file ) == 0 )
		return -1
	endif
	
	if ( DataFolderExists( temp ) == 1 )
		NMFolderClose( temp ) // shouldnt be here
	endif
	
	strswitch( StrVarOrDefault( "DataFileType","" ) )
		case "Pclamp":
		case "Axograph":
			//NMImportFile( temp, file )
			return 0
		case "NMBin":
			folder = NMBinOpen( temp, file, "1111", 1 )
			break
		case "IgorBin":
			folder = IgorBinOpen( temp, file, 1 )
			break
		default:
			return -1
	endswitch
	
	if ( strlen( folder ) == 0 )
		SetDataFolder $saveDF // failure, back to original folder
		return -1
	endif
	
	NMChanSelect( "All" )
	
	NMCopyWavesTo( saveDF, "", -inf, inf, 0, 0 )
	
	if ( DataFolderExists( temp ) == 1 )
		NMFolderClose( temp )
	endif
	
	NMFolderChange( saveDF )
	
	NMPrefixSelectSilent( wavePrefix )
	
	return 0

End // NMDataReload

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFoldersMerge()

	Variable fcnt, numfolders
	String fname, newprefix, wlist
	
	String f1 = CurrentNMFolder( 0 )
	String f2 = ""
	String flist = NMDataFolderList()
	
	String currentPrefix = CurrentNMWavePrefix()
	String newfolder = FolderNameNext( "" )
	
	for ( fcnt = 0; fcnt < ItemsInList( flist ); fcnt += 1 )
		
		if ( ( StringMatch( f1, StringFromList( fcnt, flist ) ) == 1 ) && ( fcnt + 1 < ItemsInList( flist ) ) )
			f2 = StringFromList( fcnt+1, flist )
			break
		endif
		
	endfor
	
	Prompt newfolder, "new folder name:"
	Prompt currentPrefix, "prefix of waves to copy to new folder:"
	Prompt f1, "first folder:", popup flist
	Prompt f2, "second folder:", popup flist
	
	DoPrompt "Merge Folders", newfolder, currentPrefix, f1, f2
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	NMPrefixAdd( "DF" )
	
	NMFolderNew( newfolder )
	
	NMFolderChange( f1 )
	
	wlist = WaveList( currentPrefix + "*",";","" )
	
	if ( ItemsInList( wlist ) > 0 )
	
		NMPrefixSelectSilent( currentPrefix )
	
		newprefix = "D"+ NMFolderPrefix( f1 )
	
		NMCopyWavesTo( "root:" + newfolder, newprefix, -inf, inf, 0, 0 )
		
	endif
	
	NMFolderChange( f2 )
	
	wlist = WaveList( currentPrefix + "*",";","" )
	
	if ( ItemsInList( wlist ) > 0 )
	
		NMPrefixSelectSilent( currentPrefix )
	
		newprefix = "D"+ NMFolderPrefix( f2 )
	
		NMCopyWavesTo( "root:" + newfolder, newPrefix, -inf, inf, 0, 0 )
		
	endif
	
	flist = RemoveFromList( f1, flist )
	flist = RemoveFromList( f2, flist )
	
	f2 = ""
	
	numfolders = ItemsInList( flist )
	
	for ( fcnt = 0; fcnt < numfolders; fcnt += 1 )
	
		fname = StringFromList( 0, flist )
		
		if ( strlen( fname ) == 0 )
			break
		endif
		
		wlist = NMFolderWaveList( "root:" + fname, currentPrefix + "*", ";", "", 0 )
		
		if ( ItemsInList( wlist ) == 0 )
			flist = RemoveFromList( fname, flist )
		endif
	
	endfor
	
	numfolders = ItemsInList( flist )
	
	for ( fcnt = 0; fcnt < numfolders; fcnt += 1 )
	
		if ( ItemsInList( flist ) <= 0 )
			break
		endif
	
		Prompt f2, "next folder:", popup flist
	
		DoPrompt "Merge Folders", f2
		
		if ( V_flag == 1 )
			break // cancel
		endif
		
		NMFolderChange( f2 )
		
		wlist = WaveList( currentPrefix + "*",";","" )
		
		if ( ItemsInList( wlist ) > 0 )
		
			NMPrefixSelectSilent( currentPrefix )
	
			newprefix = "D"+ NMFolderPrefix( f2 )
	
			NMCopyWavesTo( "root:" + newfolder, newPrefix, -inf, inf, 0, 0 )
		
			flist = RemoveFromList( f2, flist )
			
		endif
	
	endfor
	
	NMFolderChange( newfolder )
	
	NMPrefixSelect( "DF" )
	
End // NMFoldersMerge

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderSave() // save current NM folder
	
	return FileBinSave( 1, 1, "", "SaveDataPath", "", 1, -1 )
	
End // NMFolderSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderSaveAll()

	Variable icnt
	String folder, file, slist = "", flist = NMDataFolderList()
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
	
		folder = CheckNMFolderPath( StringFromList( icnt, flist ) )
		
		if ( DataFolderExists( folder ) == 0 )
			continue
		endif
		
		file = FileBinSave( 1, 1, folder, "SaveDataPath", "", 1, -1 )
		
		slist = AddListItem( file, slist, ";", inf )
		
	endfor
	
	return slist
	
End // NMFolderSaveAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderList( df, type )
	String df // data folder to look in ( "" ) for current
	String type // "NMData", "NMStim", "NMLog", ( "" ) any
	
	Variable index
	String objName, folderlist = ""
	
	if ( strlen( df ) == 0 )
		df = CurrentNMFolder( 1 )
	endif
	
	do
		objName = GetIndexedObjName( df, 4, index )
		
		if ( strlen( objName ) == 0 )
			break
		endif
		
		CheckNMFolderType( objName )
		
		if ( IsNMFolder( df+objName, type ) == 1 )
			folderlist = AddListItem( objName, folderlist, ";", inf )
		endif
		
		index += 1
		
	while( 1 )
	
	return folderlist

End // NMFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDataFolderList()

	String flist = Wave2List( NMFolderListWave() )

	if ( ItemsInlist( flist ) == 0 )
		return NMFolderList( "root:","NMData" )
	endif
	
	return flist
	
End // NMDataFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDataFolderListLong() // includes Folder list name ( i.e. "F0" )
	Variable icnt
	
	String fname, flist2 = "", flist = NMDataFolderList()
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
		fname = StringFromList( icnt, flist )
		fname = NMFolderListName( fname ) + " : " + fname
		flist2 = AddListItem( fname, flist2, ";", inf )
	endfor

	return flist2
	
End // NMDataFolderListLong

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLogFolderListLong()
	Variable icnt
	
	String fname, flist2 = "", flist = NMFolderList( "root:","NMLog" )
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
		fname = StringFromList( icnt, flist )
		fname = "L" + num2istr( icnt ) + " : " + fname
		flist2 = AddListItem( fname, flist2, ";", inf )
	endfor

	return flist2
	
End // NMLogFolderListLong

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderListWave()

	return NMDF() + "FolderList"

End // NMFolderListWave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFolderList()

	Variable icnt, folders
	String folder
	
	String wname = NMFolderListWave()
	String folderList = NMFolderList( "root:","NMData" )
	
	folders = ItemsInList( folderList )

	CheckNMtwave( wname, -1, "" )
	
	if ( WaveExists( $wname ) == 0 )
		return 0
	endif
	
	Wave /T list = $wname
	
	for ( icnt = 0; icnt < numpnts( list ); icnt += 1 )
	
		folder = list[ icnt ]
		
		if ( IsNMDataFolder( folder ) == 0 )
			NMFolderListRemove( folder )
		endif
		
	endfor
	
	for ( icnt = 0; icnt < folders; icnt += 1 )
		NMFolderListAdd( StringFromList( icnt, folderList ) )
	endfor
	
End // CheckNMFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListEdit()

	String tName = "NM_FolderList"
	
	String wname = NMFolderListWave()
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif
	
	if ( WinType( tName ) > 0 )
		DoWindow /F $tName
	else
		Edit /K=1/N=$tName $wname as "NM Data Folder List"
	endif

end // NMFolderListEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListNextNum()

	Variable icnt, found, npnts
	
	String wname = NMFolderListWave()
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif
	
	Wave /T list = $wname
	
	npnts = numpnts( list )
	
	for ( icnt = npnts-1; icnt >= 0; icnt -=1 )
		if ( strlen( list[ icnt ] ) > 0 )
			found = 1
			break
		endif
	endfor
	
	if ( found == 0 )
	
		return 0
		
	else
	
		icnt += 1
		
		return icnt
		
	endif

End // NMFolderListNextNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListAdd( folder )
	String folder
	
	Variable icnt, found, npnts
	
	String wname = NMFolderListWave()
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif
	
	Wave /T list = $wname
	
	folder = GetPathName( folder, 0 )
	
	npnts = numpnts( list )
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
		if ( StringMatch( folder, list[ icnt ] ) == 1 )
			return 0 // already exists
		endif
	endfor
	
	for ( icnt = npnts-1; icnt >= 0; icnt -=1 )
		if ( strlen( list[ icnt ] ) > 0 )
			found = 1
			break
		endif
	endfor

	if ( found == 0 )
		icnt = 0
	else	
		icnt = icnt + 1
	endif
	
	if ( icnt < npnts )
		list[ icnt ] = folder
	else
		Redimension /N=( icnt+1 ) list
		list[ icnt ] = folder
	endif
	
	return icnt
	
End // NMFolderListAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListRemove( folder )
	String folder
	
	Variable icnt, found, npnts
	
	String wname = NMFolderListWave()
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif
	
	Wave /T list = $wname
	
	folder = GetPathName( folder, 0 )
	
	npnts = numpnts( list )
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
		if ( StringMatch( folder, list[ icnt ] ) == 1 )
			list[ icnt ] = ""
			return 1
		endif
	endfor
	
	return 0
	
End // NMFolderListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListChange( oldName, newName )
	String oldName, newName
	
	Variable icnt, found, npnts
	
	String wname = NMFolderListWave()
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif
	
	Wave /T list = $wname
	
	oldName = GetPathName( oldName, 0 )
	
	npnts = numpnts( list )
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
		if ( StringMatch( oldName, list[ icnt ] ) == 1 )
			list[ icnt ] = GetPathName( newName, 0 )
			return 1
		endif
	endfor
	
	return 0
	
End // NMFolderListChange

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListNum( folder )
	String folder
	
	Variable icnt, found, npnts
	
	String wname = NMFolderListWave()
	
	if ( WaveExists( $wname ) == 0 )
		return Nan
	endif
	
	if ( strlen( folder ) == 0 )
		folder = CurrentNMFolder( 0 )
	endif
	
	Wave /T list = $wname
	
	folder = GetPathName( folder, 0 )
	
	npnts = numpnts( list )
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
		if ( StringMatch( folder, list[ icnt ] ) == 1 )
			return icnt
		endif
	endfor
	
	return Nan
	
End // NMFolderListNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderListName( folder )
	String folder // folder name ( "" ) for current
	
	String prefix = "F"
	
	if ( strlen( folder ) == 0 )
		folder = CurrentNMFolder( 0 )
	endif
	
	Variable id = NMFolderListNum( folder )
	
	if ( numtype( id ) == 0 )
		return prefix + num2istr( id )
	else
		return ""
	endif

End // NMFolderListName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderPrefix( folder )
	String folder // folder name, ( "" ) for current
	
	return NMFolderListName( folder ) + "_"

End // NMFolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMFolder( folder, type )
	String folder // full-path folder name
	String type // "NMData", "NMStim", "NMLog", ( "" ) any
	
	Variable yes
	String ftype
	
	if ( strlen( folder ) == 0 )
		folder = GetDataFolder( 1 )
	endif
	
	folder = CheckNMFolderPath( folder )
	
	if ( ( strlen( folder ) > 0 ) && ( DataFolderExists( folder ) == 1 ) )
	
		ftype = StrVarOrDefault( folder+"FileType", "No" )
	
		if ( StringMatch( type, ftype ) == 1 )
			yes = 1
		elseif ( ( strlen( type ) == 0 ) && ( StringMatch( ftype, "No" ) == 0 ) )
			yes = 1
		endif
	
	endif
	
	return yes

End // IsNMFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMDataFolder( folder )
	String folder // full-path folder name
	
	return IsNMFolder( folder,"NMData" )
	
End // IsNMDataFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SubStimName( df ) // sub folder stim name
	String df // data folder or ( "" ) for current

	return StringFromList( 0, NMFolderList( df, "NMStim" ) )

End // SubStimName

//****************************************************************
//****************************************************************
//****************************************************************

Function PrintNMFolderDetails( folder )
	String folder
	
	folder = CheckNMFolderPath( folder )

	if ( DataFolderExists( folder ) == 0 )
		return -1
	endif
	
	NMHistory( "Data File: " + StrVarOrDefault( folder+"CurrentFile", "Unknown Data File" ) )
	NMHistory( "File Type: " + StrVarOrDefault( folder+"DataFileType", "Unknown" ) )
	NMHistory( "Acquisition Mode: " + StrVarOrDefault( folder+"AcqMode", "Unknown" ) )
	NMHistory( "Data Prefix Name: " + StrVarOrDefault( folder+"WavePrefix", "" ) )
	NMHistory( "Channels: " + num2istr( NumVarOrDefault( folder+"NumChannels", Nan ) ) )
	NMHistory( "Waves per Channel: " + num2istr( NumVarOrDefault( folder+"NumWaves", Nan ) ) )
	NMHistory( "Samples per Wave: " + num2istr( NumVarOrDefault( folder+"SamplesPerWave", Nan ) ) )
	NMHistory( "Sample Interval ( ms ): " + num2str( NumVarOrDefault( folder+"SampleInterval", Nan ) ) )
	NMHistory( " " )

End // PrintNMFolderDetails

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Folder utility functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S FolderNameCreate( filename ) // create a folder name based on a given file name
	String filename
	
	String prefix = NeuroMaticStr( "FolderPrefix" )
	
	filename = GetPathName( filename, 0 ) // remove path if it exists
	filename = FileExtCheck( filename, ".*", 0 ) // remove extension if it exists
	
	if ( numtype( str2num( filename[ 0,0 ] ) ) == 0 ) // file name begins with a number - BAD!!!
		filename = prefix + filename
	endif
	
	return CheckFolderNameChar( filename )

End // FolderNameCreate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FolderNameNext( folder ) // return next unused folder name
	String folder
	
	Variable fcnt, seqnum, iSeqBgn, iSeqEnd
	String testname, rname = ""
	
	String prefix = NeuroMaticStr( "FolderPrefix" )
	
	if ( strlen( folder ) == 0 )
		folder = prefix + "Folder" + num2istr( NMFolderListNextNum() )
	else
		folder = GetPathName( folder, 0 )
	endif
	
	folder = CheckFolderNameChar( folder )
	
	seqnum = SeqNumFind( folder )
	
	iSeqBgn = NumVarOrDefault( "iSeqBgn", 0 )
	iSeqEnd = NumVarOrDefault( "iSeqEnd", 0 )

	for ( fcnt = 0; fcnt <= 99; fcnt += 1 )
	
		if ( numtype( seqnum ) == 0 )
			testname = SeqNumSet( folder, iSeqBgn, iSeqEnd, ( seqnum+fcnt ) )
		else
			testname = folder + num2istr( fcnt )
		endif
		
		testname = testname[ 0,30 ]
		
		if ( ( strlen( testname ) > 0 ) && ( DataFolderExists( "root:" + testname ) == 0 ) )
			rname = testname
			break
		endif
		
	endfor

	KillVariables /Z iSeqBgn, iSeqEnd
	
	return rname
	
End // FolderNameNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckFolderName( folder ) // if folder exists, request new folder name
	String folder
	
	if ( strlen( folder ) == 0 )
		return ""
	endif
	
	Variable icnt
	
	String parent = GetPathName( folder, 1 )
	String fname = GetPathName( folder, 0 )
	
	String lastname, savename = fname
	
	fname = CheckFolderNameChar( fname )
	
	do // test whether data folder already exists
	
		if ( DataFolderExists( parent+fname ) == 1 )
			
			lastname = fname
			fname = savename + "_" + num2istr( icnt )
			
			Prompt fname, "Folder " + NMQuotes( lastname ) + " already exists. Please enter a different folder name:"
			DoPrompt "Folder Name Conflict", fname
			
			if ( V_flag == 1 )
				return "" // cancel
			endif

		else
		
			break // name OK
			
		endif
		
	while ( 1 )
	
	return parent+fname

End // CheckFolderName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckFolderNameChar( fname )
	String fname
	
	Variable icnt, ascii
	
	for ( icnt = 0; icnt < strlen( fname ); icnt += 1 )
	
		ascii = char2num( fname[ icnt,icnt ] )
		
		if ( ( ascii < 48 ) || ( ( ascii > 57 ) && ( ascii < 65 ) ) || ( ( ascii > 90 ) && ( ascii < 97 ) ) || ( ascii > 127 ) )
			fname[ icnt,icnt ] = "_" // replace with underline
		endif
		
	endfor
	
	fname = ReplaceString( "__", fname, "_" )
	fname = ReplaceString( "__", fname, "_" )
	fname = ReplaceString( "__", fname, "_" )
	
	icnt = strlen( fname ) - 1
	
	if ( StringMatch( fname[ icnt, icnt ], "_" ) == 1 )
		fname = fname[ 0, icnt - 1 ]
	endif
	
	return fname[ 0,30 ]

End // CheckFolderNameChar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FolderObjectList( df, objType )
	String df // data folder path ( "" ) for current
	Variable objType // ( 1 ) waves ( 2 ) variables ( 3 ) strings ( 4 ) data folders ( 5 ) numeric wave ( 6 ) text wave
	
	Variable ocnt, otype, add
	String objName, olist = ""
	
	switch( objType )
		case 1:
		case 2:
		case 3:
		case 4:
			otype = objType
			break
		case 5:
		case 6:
			otype = 1
			break
		default:
			return ""
	endswitch
	
	do
	
		add = 0
		objName = GetIndexedObjName( df, oType, ocnt )
		
		if ( strlen( objName ) == 0 )
			break
		endif
		
		switch( objType )
			case 1:
			case 2:
			case 3:
			case 4:
				add = 1
				break
			case 5:
				if ( WaveType( $( df+objName ) ) > 0 )
					add = 1
				endif
				break
			case 6:
				if ( WaveType( $( df+objName ) ) == 0 )
					add = 1
				endif
				break
		endswitch
		
		if ( add == 1 )
			olist = AddListItem( objName, olist, ";", inf )
		endif
		
		ocnt += 1
		
	while( 1 )
	
	return olist

End // FolderObjectList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Prefix Menu Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixSubfolderList( withNMPrefix )
	Variable withNMPrefix // ( 0 ) without "NMprefix_" ( 1 ) with "NMprefix_"
	
	String folderPrefix = NMPrefixFolderPrefix()
	
	String subfolderList = NMSubfolderList( folderPrefix, CurrentNMFolder( 1 ), 0 )
	
	if ( withNMPrefix == 1 )
		return subfolderList
	else
		return ReplaceString( folderPrefix, subfolderList, "" )
	endif
	
End // NMPrefixSubfolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSubfolderKillCall()

	String txt, vlist = ""
	String subfolderList = NMPrefixSubfolderList( 0 )
	String prefix = CurrentNMWavePrefix()
	
	if ( ItemsInList( subfolderList ) == 0 )
		
		NMDoAlert( "There are no prefix subfolders to kill." )
		return -1
		
	elseif ( ItemsInList( subfolderList ) > 1 )
		subfolderList += "All;"
	endif
	
	Prompt prefix, "select prefix to kill:", popup subfolderList
	DoPrompt "Kill Wave Prefix Subfolder Globals", prefix
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( prefix, "All" ) == 1 )
		prefix = subfolderList
		txt = "Are you sure you want to kill all prefix subfolders?"
		txt += " This will kill all Sets and Groups and variables associated with these prefixes."
	else
		txt = "Are you sure you want to kill the subfolder for prefix " + NMQuotes( prefix ) + "?"
		txt += " This will kill all Sets, Groups and variables associated with this prefix."
	endif
	
	DoAlert 1, txt
	
	if ( V_flag != 1 )
		return -1
	endif
	
	vlist = NMCmdList( prefix, "" )
	NMCmdHistory( "NMPrefixSubfolderKill", vlist )
	
	return NMPrefixSubfolderKill( prefix )

End // NMPrefixSubfolderKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSubfolderKill( killList )
	String killList
	
	Variable icnt
	String prefix, subfolder
	
	String prefixList = NeuroMaticStr( "PrefixList" )
	String currentPrefix = CurrentNMWavePrefix()
	String folderPrefix = NMPrefixFolderPrefix()
	
	if ( ItemsInList( killList ) == 0 )
		return -1
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( killList ) ; icnt += 1 )
	
		prefix = StringFromList( icnt, killList )
		
		if ( StringMatch( prefix, currentPrefix ) == 1 )
			SetNMstr( "CurrentPrefix", "" )
		endif
		
		//prefixList = RemoveFromList( prefix, prefixList )
		
		subfolder = folderPrefix + prefix
		
		NMPrefixFolderLock( subfolder, 0 )
		NMSubfolderKill( subfolder )
	
	endfor
	
	SetNeuroMaticStr( "PrefixList", prefixList )
	
	UpdateNM( 1 )
	
	return 0
	
End // NMPrefixSubfolderKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixList()

	String prefixList = NeuroMaticStr( "PrefixList" )
	String subfolderList = NMPrefixSubfolderList( 0 )
	
	return NMAddToList( subfolderList, prefixList, ";" )

End // NMPrefixList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixOtherCall()

	String newPrefix
	
	Prompt newPrefix, "enter new wave prefix:"
	DoPrompt "Other Wave Prefix", newPrefix
	
	if ( ( V_flag == 1 ) || ( strlen( newPrefix ) == 0 ) )
		return -1 // cancel
	endif
	
	NMCmdHistory( "NMPrefixSelect", NMCmdStr( newPrefix,"" ) )
	
	return NMPrefixSelect( newPrefix )

End // NMPrefixOtherCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixListSetCall()

	Variable error
	
	String vlist = ""
	String prefixList = NeuroMaticStr( "PrefixList" )
	
	String addPrefix = ""
	String RemovePrefix = " "
	String editList = prefixList
	
	Prompt addPrefix, "enter a new prefix:"
	Prompt removePrefix, "or select a prefix to remove:", popup " ;" + prefixList
	Prompt editList, "or edit the list directly:"
	DoPrompt "Edit Default Wave Prefix List", addPrefix, removePrefix, editList
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( editList, prefixList ) == 0 )
	
		vlist = NMCmdList( editList, "" )
		NMCmdHistory( "NMPrefixListSet", vlist )
	
		error = NMPrefixListSet( editList )
		
	endif
	
	if ( strlen( addPrefix ) > 0 )
	
		vlist = NMCmdStr( addPrefix,"" )
		NMCmdHistory( "NMPrefixAdd", vlist )
		
		error += NMPrefixAdd( addPrefix )
		
	endif
	
	if ( StringMatch( removePrefix, " " ) == 0 )
	
		vlist = NMCmdStr( removePrefix,"" )
		NMCmdHistory( "NMPrefixRemove", vlist )
		
		error += NMPrefixRemove( removePrefix )
	
	endif
	
	return error

End // NMPrefixListSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixListSet( prefixList )
	String prefixList
	
	Variable icnt
	String pList = ""
	
	if ( strsearch( prefixList, ",", 0 ) >= 0 )
		prefixList = ReplaceString( ",", prefixList, ";" )
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( prefixList ) ; icnt += 1 )
		pList += StringFromList( icnt, prefixList ) + ";"
	endfor
	
	SetNeuroMaticStr( "PrefixList", pList )
	UpdateNMPanelPrefixMenu()
	
	return 0

End // NMPrefixListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixListClearCall()

	NMCmdHistory( "NMPrefixListClear", "" )
	
	return NMPrefixListClear()

End // NMPrefixListClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixListClear()

	SetNeuroMaticStr( "PrefixList", "Record;Avg;" )
	UpdateNMPanelPrefixMenu()
	
	return 0

End // NMPrefixListClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixAddCall()

	String newPrefix
	
	Prompt newPrefix, "enter prefix string:"
	DoPrompt "Add Wave Prefix", newPrefix
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	NMCmdHistory( "NMPrefixAdd", NMCmdStr( newPrefix,"" ) )
	
	return NMPrefixAdd( newPrefix )

End // NMPrefixAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixAdd( addList )
	String addList // prefix list to add
	
	String prefixList = NeuroMaticStr( "PrefixList" )
	
	if ( ItemsInList( addList ) == 0 )
		return -1
	endif
	
	prefixList = NMAddToList( addList, prefixList, ";" )
	
	SetNeuroMaticStr( "PrefixList", prefixList )
	
	UpdateNMPanelPrefixMenu()
	
	return 0

End // NMPrefixAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixRemoveCall()

	String prefixList = NeuroMaticStr( "PrefixList" )
	String CurrentPrefix = CurrentNMWavePrefix()

	String getprefix
	
	Prompt getprefix, "remove:", popup RemoveFromList( CurrentPrefix, prefixList )
	DoPrompt "Remove Wave Prefix", getprefix
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	NMCmdHistory( "NMPrefixRemove", NMCmdStr( getprefix,"" ) )
	
	return NMPrefixRemove( getprefix )

End // NMPrefixRemoveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixRemove( removeList )
	String removeList
	
	String prefixList = NeuroMaticStr( "PrefixList" )
	
	if ( ItemsInList( removeList ) == 0 )
		return -1
	endif
	
	prefixList = RemoveFromList( removeList, prefixList, ";" )
	
	SetNeuroMaticStr( "PrefixList", prefixList )
	UpdateNMPanelPrefixMenu()
	
	return 0

End // NMPrefixRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesPrefCall()
	
	String order = NeuroMaticStr( "OrderWavesBy" )
	
	Prompt order, "Order selected waves by:", popup "name;date;"
	DoPrompt "Order Waves Preference", order
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	NMCmdHistory( "NMOrderWavesPrefSet", NMCmdStr( order,"" ) )
	
	return NMOrderWavesPrefSet( order )

End // NMOrderWavesPreferenceCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesPrefSet( order )
	String order // order waves ( 0 ) by creation date ( 1 ) alpha-numerically
	
	strswitch( order )
		case "name":
		case "date":
			SetNeuroMaticStr( "OrderWavesBy", order )
			break
		default:
			NMDoAlert( "Unrecognized order waves preference: " + order )
			return -1
	endswitch
	
	return 0
	
End // NMOrderWavesPrefSet

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave Prefix Select Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSelectCall( prefix )
	String prefix
	
	NMCmdHistory( "NMPrefixSelect", NMCmdStr( prefix,"" ) )
	
	return NMPrefixSelect( prefix )

End // NMPrefixSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSelectSilent( wavePrefix )
	String wavePrefix
	
	Variable error
	
	SetNeuroMaticVar( "ChangePrefixPrompt", 0 )
	
	error = NMPrefixSelect( wavePrefix )
	
	KillVariables /Z $NMDF()+"ChangePrefixPrompt"
	
	return error

End // NMPrefixSelectSilent

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSelect( wavePrefix ) // change to a new wave prefix
	String wavePrefix // wave prefix name, or ( "" ) for current prefix
	
	Variable ccnt, numChannels, oldNumChannels, numItems, numWaves, numWavesMax
	Variable oldWaveListExists, madePrefixFolder, prmpt = 1
	
	String wlist, newList, oldList = "", prefixFolder
	
	String currentFolder = CurrentNMFolder( 1 )
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = StrVarOrDefault( currentFolder+"CurrentPrefix", "" )
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		return -1
	endif
	
	prefixFolder = NMPrefixFolderDF( currentFolder, wavePrefix )
	
	newList = WaveList( wavePrefix + "*", ";", "Text:0" )
	numWaves = ItemsInList( newList )

	if ( numWaves <= 0 )
		NMDoAlert( "No waves detected with prefix " + NMQuotes( wavePrefix ) )
		return -1
	endif
	
	if ( strlen( prefixFolder ) > 0 )
		oldList = StrVarOrDefault( prefixFolder+"PrefixSelect_WaveList", "" )
		oldNumChannels = NumVarOrDefault( prefixFolder+"NumChannels", 0 )
	endif
	
	if ( StringMatch( newList, oldList ) == 1 )
	
		numChannels = NumVarOrDefault( prefixFolder+"NumChannels", 0 )
		numWaves = NumVarOrDefault( prefixFolder+"NumWaves", 0 )
		oldWaveListExists = 1
		prmpt = 0
		
	else
	
		for ( ccnt = 0; ccnt < 20; ccnt += 1 ) // detect multiple channels
		
			wlist = NMChanWaveListSearch( wavePrefix, ccnt )
			
			if ( ItemsInList( wlist ) > 0 )
			
				numChannels += 1
				numItems = ItemsInList( wlist )
				
				if ( numItems > numWavesMax )
					numWavesMax = numItems
				endif

			endif
			
		endfor
	
	endif
	
	if ( numChannels <= 0 )
		numChannels = 1
	endif
	
	if ( numChannels == 1 )
		numWavesMax = numWaves
	endif
	
	if ( ( numWavesMax < numWaves ) && ( numWavesMax > 0 ) )
		numWaves = numWavesMax
	endif
	
	if ( ( prmpt == 1 ) && ( numChannels > 1 ) && ( NeuroMaticVar( "ChangePrefixPrompt" ) != 0 ) )
	
		Prompt numChannels, "number of channels:"
		Prompt numWaves, "waves per channel:"
	
		DoPrompt "Check Channel Configuration", numChannels, numWaves
		
		if ( V_Flag == 1 )
			return -1 // cancel
		endif
		
	endif
	
	SetNMstr( "CurrentPrefix", wavePrefix ) // change to new prefix
	
	if ( ( strlen( prefixFolder ) > 0 ) && ( DataFolderExists( prefixFolder ) == 1 ) )
	
		CheckNMPrefixFolder( prefixFolder, numChannels, numWaves )
		
	else
	
		prefixFolder = NMPrefixFolderMake( currentFolder, wavePrefix, numChannels, numWaves )
	
		if ( strlen( prefixFolder ) > 0 )
			madePrefixFolder = 1
		endif
	
	endif
	
	if ( DataFolderExists( prefixFolder ) == 0 )
		NMDoAlert( "Failed to create prefix subfolder for " + NMQuotes( wavePrefix ) )
		return -1
	endif
	
	SetNMstr( prefixFolder+"PrefixSelect_WaveList", newList )
	
	if ( oldWaveListExists == 0 )
		NMChanWaveListSet( 1 )
	endif
	
	if ( StringMatch( wavePrefix, "Pulse*" ) == 1 )
		NMChanUnits2Labels()
	endif
	
	CheckChanSubFolder( -1 )
	ChanGraphsReset()
	
	//UpdateNM( 1 ) // UPDATE TAB
	
	if ( oldNumChannels != numChannels )
	
		if ( ( oldNumChannels > 0 ) && ( numChannels != oldNumChannels ) )
		
			//DoAlert 1, "Alert: the number of channels for prefix " + NMQuotes( wavePrefix ) + " has changed. Do you want to update your Sets and Groups to correspond to the new number of channels?"
			
			//if ( V_Flag == 1 )
				NMSetsListsUpdateNewChannels()
				NMGroupsListsUpdateNewChannels()
			//endif
			
		endif
		
		ChanGraphsResetCoordinates()
		
	endif
	
	if ( madePrefixFolder == 1 )
		NMChanSelect( "A" )
		NMCurrentWaveSet( 0 )
	endif
	
	if ( strlen( NMWaveSelectGet() ) == 0 )
		NMWaveSelect( "All" )
	else
		NMWaveSelect( "Update" )
	endif 
	
	NMCurrentWaveSet( CurrentNMWave() )
	
	return 0

End // NMPrefixSelect

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Subfolder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolder( folderPrefix, wavePrefix, chanNum, waveSelect )
	String folderPrefix // e.g. "Spike_"
	String wavePrefix // e.g. "Record"
	Variable chanNum // e.g. channel number or ( -1 ) for current channel or ( NAN ) for no channel
	String waveSelect // e.g. "Set1"
	
	String currentFolder, folderName
	
	if ( ( strlen( folderPrefix ) == 0 ) || ( strlen( wavePrefix ) == 0 ) || ( strlen( waveSelect ) == 0 ) )
		return ""
	endif
	
	currentFolder = CurrentNMFolder( 1 )
	
	if ( strlen( currentFolder ) == 0 )
		return ""
	endif
	
	if ( chanNum == -1 )
		chanNum = CurrentNMChannel()
	endif
	
	folderName = folderPrefix + StringAddToEnd( wavePrefix, "_" ) + waveSelect
	
	folderName = folderName[ 0,28 ]
	
	if ( ( numtype( chanNum ) == 0 ) && ( chanNum >= 0 ) && ( chanNum < NMNumChannels() ) )
		folderName += "_" + ChanNum2Char( chanNum )
	endif
	
	return currentFolder + folderName[ 0,30 ] + ":"

End // NMSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSubfolder( subfolder )
	String subfolder
	
	if ( strlen( subfolder ) == 0 )
		return -1
	endif
	
	if ( DataFolderExists( subfolder ) == 1 )
		return 0 // OK, exists
	endif
	
	NewDataFolder $RemoveEnding( subfolder, ":" )
	
	return 1 // OK, made
	
End // CheckNMSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolderList( folderPrefix, parentFolder, fullPath )
	String folderPrefix // e.g. "Spike_"
	String parentFolder // where to look for subfolders
	Variable fullPath // use full-path names ( 0 ) no ( 1 ) yes

	Variable icnt
	String subfolderList, folderName, outList = ""
	
	if ( strlen( parentFolder ) == 0 )
		parentFolder = CurrentNMFolder( 1 )
	endif
	
	subfolderList = FolderObjectList( parentFolder, 4 )
	
	for ( icnt = 0 ; icnt < ItemsInList( subfolderList ) ; icnt += 1 )
		
		folderName = StringFromList( icnt, subfolderList )
		
		if ( strsearch( folderName, folderPrefix, 0, 2 ) == 0 )
		
			if ( fullPath == 1 )
				outList = AddListItem( parentFolder + folderName + ":" , outList, ";", inf )
			else
				outList = AddListItem( folderName, outList, ";", inf )
			endif
			
		endif
	
	endfor
	
	return outList

End // NMSubfolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolderTableName( subfolder, tablePrefix )
	String subfolder
	String tablePrefix

	String fname = GetPathName( subfolder, 0 )
	
	return tablePrefix + NMFolderPrefix( "" ) + fname

End // NMSubfolderTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolderTable( subfolder, tablePrefix )
	String subfolder
	String tablePrefix
	
	Variable icnt, items
	String wList, tname, title, fname
	
	if ( DataFolderExists( subfolder ) == 0 )
		return ""
	endif
	
	wList = NMFolderWaveList( subfolder, "*", ";", "", 1 )
	
	items = ItemsInList( wList )
	
	if ( items == 0 )
		NMDoAlert( "NMSubfolderTable Alert: no waves found in subfolder " + GetPathName( subfolder, 0 ) )
		return ""
	endif
	
	fname = GetPathName( subfolder, 0 )
	tname = NMSubfolderTableName( subfolder, tablePrefix )
	title = NMFolderListName( "" ) + " : " + ReplaceString( "_", fname, " " )
	
	DoWindow /K $tname
	Edit /K=1/N=$tname/W=( 0,0,0,0 ) as title
	SetCascadeXY( tname )
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
		AppendToTable /W=$tname $StringFromList( icnt, wList )
	endfor
	
	return tname
	
End // NMSubfolderTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolderClear( subfolder )
	String subfolder
	
	Variable icnt, error = 0
	String wName, wList, failureList = ""
	
	if ( DataFolderExists( subfolder ) == 0 )
		return ""
	endif
	
	if ( StringMatch( subfolder, GetDataFolder( 1 ) ) == 1 )
		NMDoAlert( "NMSubfolderClear Error: this function cannot kill waves inside the current NM data folder." )
		return ""
	endif
	
	wList = NMFolderWaveList( subfolder, "*", ";", "", 1 )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		
		KillWaves /Z $wName
		
		if ( WaveExists( $wName ) == 1 )
			failureList = AddListItem( GetPathName( wName, 0 ), failureList, ";", inf )
		endif
		
	endfor
	
	return failureList

End // NMSubfolderClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSubfolderKill( subfolder )
	String subfolder
	
	if ( DataFolderExists( subfolder ) == 0 )
		return -1
	endif
	
	if ( StringMatch( subfolder, GetDataFolder( 1 ) ) == 1 )
		NMDoAlert( "NMSubfolderKill Error: cannot delete the current NM data folder." )
		return -1
	endif
	
	if ( DataFolderExists( subfolder ) == 0 )
		NMDoAlert( "NMSubfolderKill Error: no such folder: " + subfolder )
		return -1
	endif
	
	KillDataFolder /Z $subfolder
	
	if ( DataFolderExists( subfolder ) == 1 )
		NMFolderCloseAlert( subfolder )
		return -1
	endif
	
	return 0

End // NMSubfolderKill

//****************************************************************
//****************************************************************
//****************************************************************





