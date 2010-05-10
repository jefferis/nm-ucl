#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Deprecated Functions
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	Functions listed here should be replaced with the new functions provided.
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMDeprecated( oldfunction, newfunction )
	String oldfunction, newfunction

	if ( NeuroMaticVar( "DeprecationAlert" ) == 0 )
		return 0
	endif
	
	if ( strlen( newfunction ) > 0 )
		NMDoAlert( "Alert: NeuroMatic function " + oldfunction + " has been deprecated. Please use function " + newfunction + " instead." )
	else
		NMDoAlert( "Alert: NeuroMatic function " + oldfunction + " has been deprecated." )
	endif

End // NMDeprecated

//****************************************************************
//****************************************************************
//****************************************************************

Function AddNMTab(tabName) // called from old Preference files
	String tabName
	
	NMDeprecated( "AddNMTab", "NMTabAdd" )
	
	return NMTabAdd(tabName, "")

End // AddNMTab

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabsExisting()

	NMDeprecated( "NMTabsExisting", "TabNameList" )
	
	return TabNameList( NMTabControlList() )

End // NMTabsExisting

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabListGet()
	
	NMDeprecated( "NMTabListGet", "NMTabControlList" )

	return NMTabControlList()

End // NMTabListGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCurrentFolder()

	NMDeprecated( "NMCurrentFolder", "CurrentNMFolder" )

	return CurrentNMFolder( 0 )

End // NMCurrentFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderAppendAll()

	NMDeprecated( "NMFolderAppendAll", "" )
	
	return "" // NOT FUNCTIONAL

End // NMFolderAppendAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderAppend() 

	NMDeprecated( "NMFolderAppend", "NMFoldersMerge" )
	
	return -1 // NOT FUNCTIONAL

End // NMFolderAppend

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderAppendWaves( fromFolder, toFolder, wavePrefix )
	String fromFolder
	String toFolder
	String wavePrefix
	
	NMDeprecated( "NMFolderAppendWaves", "" )
	
	return -1 // NOT FUNCTIONAL

End // NMFolderAppendWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderGlobalsSave( wavePrefix )
	String wavePrefix
	
	NMDeprecated( "NMFolderGlobalsSave", "" )
	
	return -1 // NOT FUNCTIONAL

End // NMFolderGlobalsSave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderGlobalsGet( wavePrefix )
	String wavePrefix
	
	NMDeprecated( "NMFolderGlobalsGet", "" )
	
	return -1 // NOT FUNCTIONAL

End // NMFolderGlobalsGet

//****************************************************************
//****************************************************************
//****************************************************************

Function PrintFileDetails()

	NMDeprecated( "PrintFileDetails", "PrintNMFolderDetails" )

	return PrintNMFolderDetails( "" )

End // PrintFileDetails

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanPopupUpdate( chanNum )
	Variable chanNum
	
	NMDeprecated( "ChanPopupUpdate", "" )
	
	return -1 // NOT FUNCTIONAL

End // ChanPopupUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWavesCount( chanNum )
	Variable chanNum
	
	NMDeprecated( "ChanWavesCount", "NMWaveSelectCount" )

	return NMWaveSelectCount( chanNum )

End // ChanWavesCount

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanLabel( chanNum, xy, wList )
	Variable chanNum
	String xy
	String wList
	
	NMDeprecated( "ChanLabel", "NMChanLabel" )
	
	return NMChanLabel( chanNum, xy, wList )
	
End // ChanLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanLabelSet( chanNum, wSelect, xy, labelStr )
	Variable chanNum
	Variable wSelect
	String xy
	String labelStr
	
	NMDeprecated( "ChanLabelSet", "NMChanLabelSet" )
	
	return NMChanLabelSet( chanNum, wSelect, xy, labelStr )
	
End // ChanLabelSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanCharList( numchans, seperator )
	Variable numchans
	String seperator
	
	NMDeprecated( "ChanCharList", "NMChanList" )
	
	return NMChanList( "CHAR" )
	
End // ChanCharList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanWaveName( chanNum, waveNum )
	Variable chanNum
	Variable waveNum
	
	NMDeprecated( "ChanWaveName", "NMChanWaveName" )

	return NMChanWaveName( chanNum, waveNum )

End // ChanWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveNum( wName )
	String wName
	
	NMDeprecated( "ChanWaveNum", "NMChanWaveNum" )
	
	return NMChanWaveNum( wName )
	
End // ChanWaveNum

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveListSet( chanNum, force )
	Variable chanNum
	Variable force
	
	NMDeprecated( "ChanWaveListSet", "NMChanWaveListSet" )
	
	return NMChanWaveListSet( force )
	
End // ChanWaveListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveListSort( chanNum, sortOption )
	Variable chanNum
	Variable sortOption
	
	NMDeprecated( "ChanWaveListSort", "NMChanWaveListSort" )
	
	return NMChanWaveListSort( chanNum, sortOption )
	
End // ChanWaveListSort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanWaveListSearch( wavePrefix, chanNum )
	String wavePrefix
	Variable chanNum
	
	NMDeprecated( "ChanWaveListSearch", "NMChanWaveListSearch" )
	
	return NMChanWaveListSearch( wavePrefix, chanNum )
	
End // ChanWaveListSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function CurrentChanSet( chanNum )
	Variable chanNum
	
	String chanStr
	
	NMDeprecated( "CurrentChanSet", "NMChanSelect" )
	
	if ( chanNum < 0 )
		chanStr = "All"
	else
		chanStr = num2istr( chanNum )
	endif
	
	return NMChanSelect( chanStr )
	
End // CurrentChanSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListGet( chanNum ) 
	Variable chanNum
	
	NMDeprecated( "NMChanWaveListGet", "NMChanWaveList" )
	
	return NMChanWaveList( chanNum )
	
End // NMChanWaveListGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanWaveListGet( chanNum ) 
	Variable chanNum
	
	NMDeprecated( "ChanWaveListGet", "NMChanWaveList" )
	
	return NMChanWaveList( chanNum )
	
End // ChanWaveListGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentChanDisplayWave()

	NMDeprecated( "CurrentChanDisplayWave", "ChanDisplayWave" )
	
	return ChanDisplayWave( -1 )
	
End // CurrentChanDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetChanWaveList( chanNum ) 
	Variable chanNum
	
	NMDeprecated( "GetChanWaveList", "NMWaveSelectList" )

	return NMWaveSelectList( chanNum )
	
End // GetChanWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetWaveList()

	NMDeprecated( "GetWaveList", "NMWaveSelectList" )

	return NMWaveSelectList( -1 )
	
End // GetWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentChanWaveList()

	NMDeprecated( "CurrentChanWaveList", "NMWaveSelectList" )

	return NMWaveSelectList( -1 )

End // CurrentChanWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncNormAsk( chanNum )
	Variable chanNum
	
	NMDeprecated( "ChanFuncNormAsk", "NMChanFuncNormalizeCall" )
	
	return NMChanFuncNormalizeCall( chanNum )
	
End // ChanFuncNormAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncDFOFAsk( chanNum )
	Variable chanNum
	
	NMDeprecated( "ChanFuncDFOFAsk", "NMChanFuncDFOFCall" )
	
	return NMChanFuncDFOFCall( chanNum )
	
End // ChanFuncDFOFAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFuncBslnAsk( chanNum )
	Variable chanNum

	NMDeprecated( "ChanFuncBslnAsk", "NMChanFuncBaselineCall" )
	
	return NMChanFuncBaselineCall( chanNum )

End // ChanFuncBslnAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSmthNumCall( chanNum, smthNum )
	Variable chanNum, smthNum
	
	NMDeprecated( "ChanSmthNumCall", "ChanFilterNumCall" )
	
	return ChanFilterNumCall( chanNum, smthNum )

End // ChanSmthNumCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSmthNum( chanNum, smthNum )
	Variable chanNum, smthNum
	
	NMDeprecated( "ChanSmthNum", "ChanFilter" )
	
	return ChanFilter( chanNum, ChanFilterAlgGet( chanNum ), smthNum )

End // ChanSmthNum

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSmth( chanNum, smthNum, smthAlg )
	Variable chanNum, smthNum
	String smthAlg
	
	NMDeprecated( "ChanSmth", "ChanFilter" )
	
	return ChanFilter( chanNum, smthAlg, smthNum )

End // ChanSmth

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanSmthNumGet( chanNum ) 
	Variable chanNum
	
	NMDeprecated( "ChanSmthNumGet", "ChanFilterNumGet" )
	
	return ChanFilterNumGet( chanNum )
	
End // ChanSmthNumGet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFilterFxnExists()

	NMDeprecated( "ChanFilterFxnExists", "exists" )

	if ( exists( "FilterIIR" ) == 4 ) // Igor 6.0 FilterIIR operation
		return 1
	endif
	
	return 0
	
End // ChanFilterFxnExists

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NextWaveName( prefix, chanNum, overwrite ) 
	String prefix
	Variable chanNum
	Variable overwrite
	
	NMDeprecated( "NextWaveName", "NextWaveName2" )
	
	String dataFolder = ""
	
	return NextWaveName2( dataFolder, prefix, chanNum, overwrite ) 
	
End // NextWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMComputerCall( dialogue )
	Variable dialogue
	
	NMDeprecated( "NMComputerCall", "" )
	
	return -1 // NOT FUNCTIONAL

End // NMComputerCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMComputerStats( computer, xPixels, yPixels )
	String computer
	Variable xPixels, yPixels
	
	NMDeprecated( "NMComputerStats", "" )
	
	return -1 // NOT FUNCTIONAL

End // NMComputerStats

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckComputerXYpixels()

	NMDeprecated( "CheckComputerXYpixels", "" )

	return -1 // NOT FUNCTIONAL

End // CheckComputerXYpixels

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPixelsX()

	NMDeprecated( "NMPixelsX", "NMComputerPixelsX" )

	return NMComputerPixelsX()

End // NMPixelsX

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPixelsY()

	NMDeprecated( "NMPixelsY", "NMComputerPixelsY" )

	return NMComputerPixelsY()

End // NMPixelsY

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMProgressString()

	NMDeprecated( "NMProgressString", "NeuroMaticStr" )

	return NeuroMaticStr( "ProgressStr" )

End // NMProgressString

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressStr( progStr )
	String progStr
	
	NMDeprecated( "NMProgressStr", "SetNeuroMaticStr" )

	return SetNeuroMaticStr( "ProgressStr", progStr )

End // NMProgressStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOverWriteOn( on )
	Variable on
	
	NMDeprecated( "NMOverWriteOn", "SetNeuroMaticVar" )
		
	return SetNeuroMaticVar( "OverWrite", BinaryCheck( on ) )

End // NMOverWriteOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOverWrite()

	NMDeprecated( "NMOverWrite", "NeuroMaticVar" )

	return NeuroMaticVar( "OverWrite" )

End // NMOverWrite

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentChan()

	NMDeprecated( "NMCurrentChan", "CurrentNMChannel" )
	
	return CurrentNMChannel()

End // CurrentNMChannel()

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCurrentChanStr()

	NMDeprecated( "NMCurrentChanStr", "CurrentNMChanChar" )

	return CurrentNMChanChar()

End // NMCurrentChanStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentWave()

	NMDeprecated( "NMCurrentWave", "CurrentNMWave" )
	
	return CurrentNMWave()

End // NMCurrentWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentWaveName()

	NMDeprecated( "CurrentWaveName", "CurrentNMWaveName" )

	return CurrentNMWaveName()

End // CurrentWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCurrentWavePrefix()

	NMDeprecated( "NMCurrentWavePrefix", "CurrentNMWavePrefix" )

	return CurrentNMWavePrefix()

End // NMCurrentWavePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectDefaults()

	NMDeprecated( "NMWaveSelectDefaults", "" )

	return "" // NOT FUNCTIONAL
	
End // NMWaveSelectDefaults

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentTab()

	NMDeprecated( "NMCurrentTab", "NeuroMaticVar" )

	return NeuroMaticVar( "CurrentTab" )

End // NMCurrentTab

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabCurrent()

	NMDeprecated( "NMTabCurrent", "CurrentNMTabName" )

	return CurrentNMTabName()

End // NMTabCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMFolderMenu()

	NMDeprecated( "UpdateNMFolderMenu", "UpdateNMPanelFolderMenu" )

	return UpdateNMPanelFolderMenu()
	
End // UpdateNMFolderMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMGroupMenu()

	NMDeprecated( "UpdateNMGroupMenu", "UpdateNMPanelGroupMenu" )

	return UpdateNMPanelGroupMenu()

End // UpdateNMGroupMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMSetVar()

	NMDeprecated( "UpdateNMSetVar", "UpdateNMPanelSetVariables" )

	return UpdateNMPanelSetVariables()

End // UpdateNMSetVar

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMPrefixMenu()

	NMDeprecated( "UpdateNMPrefixMenu", "UpdateNMPanelPrefixMenu" )

	return UpdateNMPanelPrefixMenu()

End // UpdateNMPrefixMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMChanSelect()

	NMDeprecated( "UpdateNMChanSelect", "UpdateNMPanelChanSelect" )

	return UpdateNMPanelChanSelect()

End // UpdateNMChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMWaveSelect()

	NMDeprecated( "UpdateNMWaveSelect", "UpdateNMPanelWaveSelect" )

	return UpdateNMPanelWaveSelect()

End // UpdateNMWaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixPromptCall()

	NMDeprecated( "NMPrefixPromptCall", "" )
	
	return -1 // NOT FUNCTIONAL

End // NMPrefixPromptCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixPrompt( on )
	Variable on
	
	NMDeprecated( "NMPrefixPrompt", "SetNeuroMaticVar" )
	
	return SetNeuroMaticVar( "ChangePrefixPrompt", BinaryCheck( on ) )
	
End // NMPrefixPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsEdit()

	NMDeprecated( "NMGroupsEdit", "NMGroupsPanel" )

	return NMGroupsPanel()
	
End // NMGroupsEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupList( type )
	Variable type
	
	NMDeprecated( "NMGroupList", "NMGroupsList" )
	
	return NMGroupsList( type )

End // NMGroupList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupSet( waveNum, grpNum )
	Variable waveNum
	Variable grpNum
	
	NMDeprecated( "NMGroupSet", "NMGroupsAssign" )
	
	return NMGroupsAssign( waveNum, grpNum )
	
End // NMGroupSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupSeqDefault()

	NMDeprecated( "NMGroupSeqDefault", "NMGroupsSequenceBasic" )
	
	String grpSeq = NMGroupsSequenceBasic( NMGroupsNumDefault() )

End // NMGroupSeqDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupAssignCall( grpNum )
	Variable grpNum // group number
	
	NMDeprecated( "NMGroupAssignCall", "NMGroupsAssignCall" )
	
	return NMGroupsAssignCall( grpNum )
	
End // NMGroupAssignCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupAssign( waveNum, grpNum )
	Variable waveNum
	Variable grpNum
	
	NMDeprecated( "NMGroupAssign", "NMGroupsAssign" )
	
	return NMGroupsAssign( waveNum, grpNum )
	
End // NMGroupAssign

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupSeqCall( grpSeqStr, fromWave, toWave, blocks )
	String grpSeqStr
	Variable fromWave, toWave, blocks
	
	NMDeprecated( "NMGroupSeqCall", "NMGroupsSequenceCall" )
	
	Variable clearFirst = 1
	
	String rvalue = NMGroupsSequenceCall( grpSeqStr, fromWave, toWave, blocks, clearFirst )
	
	return 0
	
End // NMGroupSeqCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupSeq( grpSeqStr, fromWave, toWave, blocks )
	String grpSeqStr
	Variable fromWave
	Variable toWave
	Variable blocks
	
	NMDeprecated( "NMGroupSeq", "NMGroupsSequence" )
	
	Variable clearFirst = 1
	
	String rvalue = NMGroupsSequence( grpSeqStr, fromWave, toWave, blocks, clearFirst )
	
	return 0
	
End // NMGroupSeq

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsTable( option )
	Variable option
	
	NMDeprecated( "NMGroupsTable", "NMGroupsPanel" )

	return NMGroupsPanel()
	
End // NMGroupsTable

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMSets( recount )
	Variable recount
	
	NMDeprecated( "UpdateNMSets", "UpdateNMPanelSets" )
	
	UpdateNMWaveSelectLists()
	UpdateNMPanelSets( recount )
	
	return 0
	
End // UpdateNMSets

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsTable( option )
	Variable option
	
	NMDeprecated( "NMSetsTable", "NMSetsPanel" )
	
	return NMSetsPanel()
	
End // NMSetsTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsSet( setName, waveNum, value )
	String setName
	Variable waveNum
	Variable value
	
	NMDeprecated( "NMSetsSet", "NMSetsAssign" )
	
	return NMSetsAssign( setName, waveNum, value )
	
End // NMSetsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDataNew()

	NMDeprecated( "NMSetsDataNew", "" )

	return -1 // NOT FUNCTIONAL
	
End // NMSetsDataNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsDataList()

	NMDeprecated( "NMSetsDataList", "" )

	return "" // NOT FUNCTIONAL

End // NMSetsDataList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEdit()

	NMDeprecated( "NMSetsEdit", "NMSetsPanel" )

	return NMSetsPanel()

End // NMsetsEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMSetsCount()

	NMDeprecated( "UpdateNMSetsCount", "UpdateNMSetsDisplayCount" )

	return UpdateNMSetsDisplayCount()

End // UpdateNMSetsCount

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsZero2NanCall( setList )
	String setList
	
	NMDeprecated( "NMSetsZero2NanCall", "" )
	
	return -1 // NOT FUNCTIONAL
	
End // NMSetsZero2NanCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsZero2Nan( setList )
	String setList
	
	NMDeprecated( "NMSetsZero2Nan", "" )
	
	return -1 // NOT FUNCTIONAL
	
End // NMSetsZero2Nan

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsNan2ZeroCall( setList )
	String setList
	
	NMDeprecated( "NMSetsNan2ZeroCall", "" )
	
	return -1 // NOT FUNCTIONAL

End // NMSetsNan2ZeroCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsNan2Zero( setList )
	String setList
	
	NMDeprecated( "NMSetsNan2Zero", "" )
	
	return -1 // NOT FUNCTIONAL

End // NMSetsNan2Zero

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsFxnCall( setList )
	String setList
	
	NMDeprecated( "NMSetsFxnCall", "NMSetsEquationCall" )
	
	return NMSetsEquationCall()
	
End // NMSetsFxnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsFxn( setList, arg, op )
	String setList
	String arg // argument ( e.g. "Set1" or "Group2" )
	String op // operator ( "AND", "OR", "EQUALS" )
	
	Variable icnt
	String setName, arg1, operation, arg2
	
	NMDeprecated( "NMSetsFxn", "NMSetsEquation" )
	
	for ( icnt = 0 ; icnt < ItemsInList( setList ) ; icnt += 1 )
	
		setName = StringFromList( icnt, setList )
		
		strswitch( op )
		
			case "AND":
			case "OR":
				arg1 = setName
				operation = op
				arg2 = arg
				return NMSetsEquation( setName, arg1, operation, arg2 )
				
			case "EQUALS":
				arg1 = arg
				operation = ""
				arg2 = ""
				return NMSetsEquation( setName, arg1, operation, arg2 )
		
		endswitch
	
	endfor
	
	return -1

End // NMSetsFxn

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCtrlName( prefix, ctrlName )
	String prefix
	String ctrlName
	
	NMDeprecated( "NMCtrlName", "ReplaceString" )
	
	return ReplaceString( prefix, ctrlName, "" )

End // NMCtrlName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBslnWaves( tbgn, tend )
	Variable tbgn, tend
	
	NMDeprecated( "NMBslnWaves", "NMBaselineWaves" )
	
	return NMBaselineWaves( 1, tbgn, tend )
	
End // NMBslnWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBslnAvgWaves( tbgn, tend )
	Variable tbgn, tend
	
	NMDeprecated( "NMBslnAvgWaves", "NMBaselineWaves" )
	
	return NMBaselineWaves( 2, tbgn, tend )
	
End // NMBslnAvgWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAvgWavesCall()

	NMDeprecated( "NMAvgWavesCall", "NMWavesStatsCall" )
	
	return NMWavesStatsCall( "Average" )

End // NMAvgWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAvgWaves( mode, plotData, useChannelTransforms, avgAllGrps, onePlot )
	Variable mode
	Variable plotData
	Variable useChannelTransforms
	Variable avgAllGrps
	Variable onePlot
	
	String txt
	
	Variable ignoreNANs = 0 // matches old algorithm
	Variable truncateToCommonTimeScale = 1 // matches old algorithm
	Variable interpToSameTimeScale = 0 // matches old algorithm
	Variable saveMatrix = 0
	
	if ( avgAllGrps == 1 )
		txt = "Alert: NMAvgWaves has been deprecated. Please select " + NMQuotes( "All Groups" )
		txt += " and use " + NMQuotes( "NMWavesStats" ) + " instead."
		NMDoAlert(  txt )
		return "" // NOT FUNCTIONAL
	else
		NMDeprecated( "NMAvgWaves", "NMWavesStats" )
		return NMWavesStats( mode, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix, plotData, onePlot )
	endif
	
End // NMAvgWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAvgWaves2( mode, ignoreNANs, plotData, useChannelTransforms, avgAllGrps, onePlot )
	Variable mode
	Variable ignoreNANs
	Variable plotData
	Variable useChannelTransforms
	Variable avgAllGrps
	Variable onePlot
	
	String txt
	
	Variable truncateToCommonTimeScale = 1 // matches old algorithm
	Variable interpToSameTimeScale = 0 // matches old algorithm
	Variable saveMatrix = 0
	
	if ( avgAllGrps == 1 )
		txt = "Alert: NMAvgWaves2 has been deprecated. Please select " + NMQuotes( "All Groups" )
		txt += " and use " + NMQuotes( "NMWavesStats" ) + " instead."
		NMDoAlert(  txt )
		return "" // NOT FUNCTIONAL
	else
		NMDeprecated( "NMAvgWaves2", "NMWavesStats" )
		return NMWavesStats( mode, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix, plotData, onePlot )
	endif
	
End // NMAvgWaves2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSumWavesCall()
	
	NMDeprecated( "NMSumWavesCall", "NMWavesStatsCall" )
	
	return NMWavesStatsCall( "Sum" )

End // NMSumWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSumWaves( plotData, useChannelTransforms, sumAllGrps, onePlot )
	Variable plotData // plot input waves with final sum? ( 0 ) no ( 1 ) yes
	Variable useChannelTransforms // use channel F( t ) and smooth? ( 0 ) no ( 1 ) yes
	Variable sumAllGrps // sum all groups? ( 0 ) no ( 1 ) yes
	Variable onePlot // display groups together? ( 0 ) no ( 1 ) yes
	
	String txt
	
	Variable mode = 5
	Variable ignoreNANs = 0 // matches old algorithm
	Variable truncateToCommonTimeScale = 1 // matches old algorithm
	Variable interpToSameTimeScale = 0 // matches old algorithm
	Variable saveMatrix = 0
	
	if ( sumAllGrps == 1 )
		txt = "Alert: NMSumWaves has been deprecated. Please select " + NMQuotes( "All Groups" )
		txt += " and use " + NMQuotes( "NMWavesStats" ) + " instead."
		NMDoAlert(  txt )
		return "" // NOT FUNCTIONAL
	else
		NMDeprecated( "NMSumWaves", "NMWavesStats" )
		return NMWavesStats( mode, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix, plotData, onePlot )
	endif

End // NMSumWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNormWaves( fxn, tbgn, tend, bbgn, bend )
	String fxn // "max" or "min"
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	Variable bbgn, bend
	
	NMDeprecated( "NMNormWaves", "NMNormalizeWaves" )
	
	String fxn1 = "avg"
	Variable tbgn1 = bbgn
	Variable tend1 = bend
	
	String fxn2 = fxn
	Variable tbgn2 = tbgn
	Variable tend2 = tend
	
	return NMNormalizeWaves( fxn1, tbgn1, tend1, fxn2, tbgn2, tend2 )
	
End // NMNormWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPlotWaves( gName, gTitle, xLabel, yLabel, xWave, wList )
	String gName
	String gTitle
	String xLabel
	String yLabel
	String xWave
	String wList
	
	NMDeprecated( "NMPlotWaves", "NMPlotWavesOffset" )

	return NMPlotWavesOffset( gName, gTitle, xLabel, yLabel, xWave, wList, 0, 0, 0, 0 )

End // NMPlotWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlot( color )
	String color
	
	Variable onePlotPerChannel = 1
	Variable reverseOrder = 0
	Variable xoffset = 0
	Variable yoffset = 0
	
	NMDeprecated( "NMPlot", "NMMainPlotWaves" )

	return NMMainPlotWaves( color, onePlotPerChannel , reverseOrder, xoffset, yoffset )
	
End // NMPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlotOffset( color, xoffset, yoffset )
	String color
	Variable xoffset, yoffset
	
	Variable onePlotPerChannel = 1
	Variable reverseOrder = 0
	
	NMDeprecated( "NMPlotOffset", "NMMainPlotWaves" )
	
	return NMMainPlotWaves( color, onePlotPerChannel , reverseOrder, xoffset, yoffset )
	
End // NMPlotOffset

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlotGroups( color, onePlotPerChannel, reverseGroupOrder, xOffset, yOffset )
	String color
	Variable onePlotPerChannel
	Variable reverseGroupOrder
	Variable xOffset, yOffset
	
	NMDeprecated( "NMPlotGroups", "NMMainPlotWaves" )
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect( "All Groups" )
	
	String gList = NMMainPlotWaves( color, onePlotPerChannel, reverseGroupOrder, xoffset, yoffset )
	
	NMWaveSelect( saveWaveSelect )
	
	return gList
	
End // NMPlotGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEditGroups()

	NMDeprecated( "NMEditGroups", "NMEditWaves" )
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect( "All Groups" )
	
	String tList = NMEditWaves()
	
	NMWaveSelect( saveWaveSelect )
	
	return tList

End // NMEditGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintGroupWaveList()

	NMDeprecated( "NMPrintGroupWaveList", "NMPrintWaveList()" )
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect( "All Groups" )

	String wList = NMPrintWaveList()
	
	NMWaveSelect( saveWaveSelect )
	
	return wList

End // NMPrintGroupWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMInterpolateGroups( alg, xmode, xwave )
	Variable alg
	Variable xmode
	String xwave
	
	NMDeprecated( "NMInterpolateGroups", "NMInterpolateWaves" )
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect( "All Groups" )
	
	String wList = NMInterpolateWaves( alg, xmode, xwave )
	
	NMWaveSelect( saveWaveSelect )
	
	return wList

End // NMInterpolateGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReplaceNanZeroCall( direction )
	Variable direction
	
	NMDeprecated( "NMReplaceNanZeroCall", "NMReplaceWaveValueCall" )
	
	return NMReplaceWaveValueCall()

End // NMReplaceNanZeroCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReplaceNanZero( direction )
	Variable direction // ( 1 ) Nan to 0 ( -1 ) 0 to Nan
	
	NMDeprecated( "NMReplaceNanZero", "NMReplaceWaveValue" )
	
	if ( direction == 1 )
		return NMReplaceWaveValue( Nan, 0 )
	elseif ( direction == -1 )
		return NMReplaceWaveValue( 0, Nan )
	endif
	
End // NMReplaceNanZero

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NM2DWaveCall()

	NMDeprecated( "NM2DWaveCall", "NMWavesStatsCall" )
	
	return NMWavesStatsCall( "Matrix" )

End // NM2DWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NM2DWave( wprefix )
	String wprefix
	
	Variable mode = 7
	Variable useChannelTransforms = 0
	Variable ignoreNANs = 0 // matches old algorithm
	Variable truncateToCommonTimeScale = 1 // matches old algorithm
	Variable interpToSameTimeScale = 0 // matches old algorithm
	Variable saveMatrix = 1
	Variable plotData = 0
	Variable onePlot = 1
	
	NMDeprecated( "NM2DWave", "NMWavesStats" )
		
	return NMWavesStats( mode, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix, plotData, onePlot )

End // NM2DWave

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDragCall( on )
	Variable on
	
	NMDeprecated( "SpikeDragCall", "NMDragOnCall" )
	
	return NMDragOnCall( on )
	
End // SpikeDragCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDrag( on )
	Variable on
	
	NMDeprecated( "SpikeDrag", "NMDragOn" )
	
	return NMDragOn( on )
	
End // SpikeDrag

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDragToggle()

	NMDeprecated( "SpikeDragToggle", "NMDragOnToggle" )

	return NMDragOnToggle()
	
End // SpikeDragToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDragCheck()

	String gName = ChanGraphName( -1 )
	String fxnName = ""
	
	NMDeprecated( "SpikeDragCheck", "NMDragFoldersCheck" )

	return NMDragFoldersCheck( gName, fxnName )

End // SpikeDragCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDragTrigger( offsetStr )
	String offsetStr
	
	NMDeprecated( "SpikeDragTrigger", "NMDragTrigger" )
	
	return NMDragTrigger( offsetStr )
	
End // SpikeDragTrigger

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeDragSetY()

	NMDeprecated( "SpikeDragSetY", "NMDragUpdate" )
	
	NMDragUpdate( "DragTbgn" )
	NMDragUpdate( "DragTend" )

End // SpikeDragSetY

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllGroups( dsplyFlag, speed, format )
	Variable dsplyFlag // display results while computing ( 0 ) no ( 1 ) yes ( 2 ) yes, accept/reject prompt
	Variable speed // update display speed in sec ( 0 ) for none
	Variable format // save spike times to ( 0 ) one wave ( 1 ) one wave per input wave
	
	Variable plot = 1
	Variable table = 0
	
	NMDeprecated( "SpikeAllGroups", "NMSpikeComputeAll" )
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect( "All Groups" )
	
	String folderList = NMSpikeComputeAll( dsplyFlag, speed, format, plot, table )
	
	NMWaveSelect( saveWaveSelect )
	
	return folderList
	
End // SpikeAllGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllGroupsDelay( dsplyFlag, speed )
	Variable dsplyFlag
	Variable speed
	
	Variable format = 0
	Variable plot = 1
	Variable table = 0
	
	NMDeprecated( "SpikeAllGroupsDelay", "NMSpikeComputeAll" )
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect( "All Groups" )

	String folderList = NMSpikeComputeAll( dsplyFlag, speed, format, plot, table )
	
	NMWaveSelect( saveWaveSelect )
	
	return folderList

End // SpikeAllGroupsDelay

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllGroupsDelayFormat( dsplyFlag, speed, format )
	Variable dsplyFlag
	Variable speed
	Variable format
	
	Variable plot = 1
	Variable table = 0
	
	NMDeprecated( "SpikeAllGroupsDelayFormat", "NMSpikeComputeAll" )
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect( "All Groups" )

	String folderList = NMSpikeComputeAll( dsplyFlag, speed, format, plot, table )
	
	NMWaveSelect( saveWaveSelect )
	
	return folderList

End // SpikeAllGroupsDelayFormat

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllWavesDelay( dsplyFlag, speed ) 
	Variable dsplyFlag
	Variable speed
	
	Variable format = 0
	Variable plot = 1
	Variable table = 0
	
	NMDeprecated( "SpikeAllWavesDelay", "NMSpikeComputeAll" )
	
	return NMSpikeComputeAll( dsplyFlag, speed, format, plot, table )
	
End // SpikeAllWavesDelay

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllWavesDelayFormat( dsplyFlag, speed, format ) 
	Variable dsplyFlag
	Variable speed
	Variable format
	
	Variable plot = 1
	Variable table = 0
	
	NMDeprecated( "SpikeAllWavesDelayFormat", "NMSpikeComputeAll" )
	
	return NMSpikeComputeAll( dsplyFlag, speed, format, plot, table )
	
End // SpikeAllWavesDelayFormat

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllWavesCall()

	NMDeprecated( "SpikeAllWavesCall", "NMSpikeComputeAllCall" )

	return NMSpikeComputeAllCall()

End // SpikeAllWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeAllWaves( dsplyFlag, speed, format )
	Variable dsplyFlag
	Variable speed
	Variable format
	
	Variable plot = 1
	Variable table = 0
	
	NMDeprecated( "SpikeAllWaves", "NMSpikeComputeAll" )
	
	return NMSpikeComputeAll( dsplyFlag, speed, format, plot, table )
	
End // SpikeAllWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterSelectWaves()

	NMDeprecated( "SpikeRasterSelectWaves", "NMSpikeRasterSelectPrompt" )
	
	return NMSpikeRasterXSelectPrompt()

End // SpikeRasterSelectWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterSelectCall( raster )
	String raster
	
	NMDeprecated( "SpikeRasterSelectCall", "NMSpikeRasterXSelectCall" )
	
	return NMSpikeRasterXSelectCall( raster )
	
End // SpikeRasterSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterSelect( xRaster, yRaster )
	String xRaster
	String yRaster // NOT SAVED ANYMORE
	
	NMDeprecated( "SpikeRasterSelect", "NMSpikeRasterXSelect" )
	
	return NMSpikeRasterXSelect( xRaster )
	
End // SpikeRasterSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function Hazard( ISIHname )
	String ISIHname
	
	NMDeprecated( "Hazard", "NMSpikeHazard" )
	
	NMSpikeHazard( ISIHname )
	
	return 0
	
End // Hazard

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Spike2WavesCall()

	NMDeprecated( "Spike2WavesCall", "NMSpikes2WavesCall" )

	return NMSpikes2WavesCall()

End // Spike2WavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Spikes2Waves( xRaster, yRaster, before, after, stopAtNextSpike, chanNum )
	String xRaster
	String yRaster
	Variable before, after
	Variable stopAtNextSpike
	Variable chanNum
	
	NMDeprecated( "Spike2Waves", "NMSpikes2Waves" )
	
	String outputWavePrefix = NMSpikeStr( "S2W_WavePrefix" )
	
	outputWavePrefix = NMPrefixUnique( outputWavePrefix )
	
	return NMSpikes2Waves( xRaster, yRaster, before, after, stopAtNextSpike, chanNum, outputWavePrefix )
	
End // Spikes2Waves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSetTbgn( tbgn )
	Variable tbgn
	
	NMDeprecated( "NMFitSetTbgn", "NMFitTbgnSet" )
	
	return NMFitTbgnSet( tbgn )
	
End // NMFitSetTbgn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSetTend( tend )
	Variable tend
	
	NMDeprecated( "NMFitSetTend", "NMFitTendSet" )
	
	return NMFitTendSet( tend )
	
End // NMFitSetTend

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitCsrInfo( ab, gName )
	String ab
	String gName
	
	NMDeprecated( "NMFitCsrInfo", "CsrInfo" )
	
	return "" // NOT FUNCTIONAL
	
End // NMFitCsrInfo

//****************************************************************
//****************************************************************
//****************************************************************

Function EventWindow( on, tbgn, tend )
	Variable on, tbgn, tend
	
	NMDeprecated( "EventWindow", "EventSearchWindow" )
	
	return EventSearchWindow( on, tbgn, tend )

End // EventWindow

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventTableTitle(tableNum)
	Variable tableNum
	
	NMDeprecated( "EventTableTitle", "NMEventTableTitle" )
	
	return NMEventTableTitle()
	
End // EventTableTitle

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableSelect( tableNum )
	Variable tableNum
	
	NMDeprecated( "EventTableSelect", "NMEventTableSelect" )
	
	String tableName = NMEventTableOldName( CurrentNMChannel(), tableNum )
	
	NMEventTableSelect( tableName )
	
	return 0
	
End // EventTableSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableClear( tableNum )
	Variable tableNum
	
	NMDeprecated( "EventTableClear", "NMEventTableClear" )
	
	String tableName = NMEventTableOldName( CurrentNMChannel(), tableNum )
	
	//tableName = CurrentNMEventTableName()
	
	return NMEventTableClear( tableName )
	
End // EventTableClear

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableKill( tableNum )
	Variable tableNum
	
	NMDeprecated( "EventTableKill", "NMEventTableKill" )
	
	String tableName = NMEventTableOldName( CurrentNMChannel(), tableNum )
	
	//tableName = CurrentNMEventTableName()
	
	return NMEventTableKill( tableName )
	
End // EventTableKill

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTable( option, tableNum )
	String option // "make", "update", "clear" or "kill"
	Variable tableNum
	
	NMDeprecated( "EventTable", "NMEventTableManager" )
	
	String tableName = NMEventTableOldName( CurrentNMChannel(), tableNum )
	
	//tableName = CurrentNMEventTableName()
	
	return NMEventTableManager( tableName, option )
	
End // EventTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventSetName( tableNum )
	Variable tableNum
	
	NMDeprecated( "EventSetName", "" )
	
	return "" // NOT FUNCTIONAL
	
End // EventSetName

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSetValue( waveNum )
	Variable waveNum // ( -1 ) for current wave
	
	NMDeprecated( "EventSetValue", "" )
	
	return -1 // NOT FUNCTIONAL

End // EventSetValue

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSet( option, tableNum )
	String option // "make", "clear" or "kill"
	Variable tableNum
	
	NMDeprecated( "EventSet", "" )
	
	return -1 // NOT FUNCTIONAL
	
End // EventSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Event2Wave( wNumWave, eventWave, before, after, stopAtNextEvent, chanNum, outputWavePrefix ) // save events to waves
	String wNumWave // wave of wave numbers
	String eventWave // wave of event times
	Variable before, after // save time before, after event time
	Variable stopAtNextEvent // ( < 0 ) no ( >= 0 ) yes... if greater than zero, use value to limit time before next event
	Variable chanNum // channel number
	String outputWavePrefix // prefix name
	
	NMDeprecated( "Event2Wave", "NMEvent2Wave" )
	
	Variable allowTruncatedEvents = 1
	
	return NMEvent2Wave( wNumWave, eventWave, before, after, stopAtNextEvent, allowTruncatedEvents, chanNum, outputWavePrefix )
	
End // Event2Wave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckStatsWaves()

	NMDeprecated( "CheckStatsWaves", "CheckNMStatsWaves" )
	
	Variable reset = 0

	return CheckNMStatsWaves( reset ) 
	
End // CheckStatsWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWinList( kind )
	Variable kind
	
	NMDeprecated( "StatsWinList", "NMStatsWinList" )
	
	String prefix = "Win"
	
	return NMStatsWinList( kind, prefix )
	
End // StatsWinList

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinCall( tbgn, tend, fxn )
	Variable tbgn, tend
	String fxn
	
	NMDeprecated( "StatsWinCall", "NMStatsAmpSelectCall" )
	
	return NMStatsAmpSelectCall( tbgn, tend, fxn )
	
End // StatsWinCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWin( win, tbgn, tend, fxn )
	Variable win
	Variable tbgn, tend
	String fxn
	
	NMDeprecated( "StatsWin", "NMStatsAmpSelect" )
	
	return NMStatsAmpSelect( win, tbgn, tend, fxn )

End // StatsWin

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsSmoothCall( smthN, smthA )
	Variable smthN
	String smthA
	
	NMDeprecated( "StatsSmoothCall", "StatsFilterCall" )
	
	return StatsFilterCall( smthA, smthN )
	
End // StatsSmoothCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsSmooth( win, smthN, smthA )
	Variable win
	Variable smthN
	String smthA
	
	NMDeprecated( "StatsSmooth", "StatsFilter" )
	
	return StatsFilter( win, smthA, smthN )

End // StatsSmooth

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBslnReflect( win, on, tbgn, tend, fxn, subtract, center )
	Variable win, on, tbgn, tend
	String fxn
	Variable subtract
	Variable center
	
	NMDeprecated( "StatsBslnReflect", "" )
	
	return -1 // NOT FUNCTIONAL

End // StatsBslnReflect

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsBslnReflectUpdate( win )
	Variable win
	
	NMDeprecated( "StatsBslnReflectUpdate", "" )
	
	return -1 // NOT FUNCTIONAL

End // StatsBslnReflectUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsLevelStr( win, levelStr )
	Variable win
	String levelStr
	
	NMDeprecated( "StatsLevelStr", "StatsLevel" )
	
	return StatsLevel( win, str2num( levelStr ) )
	
End // StatsLevelStr

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFuncCall( on )
	Variable on
	
	NMDeprecated( "StatsFuncCall", "NMStatsTransformCall" )
	
	return NMStatsTransformCall( on )
	
End // StatsFuncCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFunc( win, fxn )
	Variable win
	Variable fxn
	
	NMDeprecated( "StatsFunc", "NMStatsTransform" )
	
	return NMStatsTransform( win, fxn )
	
End // StatsFunc

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsFxn( win, fxn )
	Variable win, fxn
	
	NMDeprecated( "StatsFxn", "NMStatsTransform" )
	
	return NMStatsTransform( win, fxn )
	
End // StatsFxn

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffsetCall( on )
	Variable on
	
	NMDeprecated( "StatsOffsetCall", "StatsOffsetWinCall" )
	
	return StatsOffsetWinCall( on )
	
End // StatsOffsetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffset( win, offName )
	Variable win
	String offName
	
	Variable offsetType
	String wName, typeStr
	
	if ( strlen( offName ) > 0 ) 
		
		typeStr = offName[ 0,1 ]
		wName = offName[ 2,inf ]
		
		strswitch( typeStr )
			default:
				return -1
			case "/g":
				offsetType = 1
				break
			case "/w":
				offsetType = 2
				break
		endswitch
		
	endif
	
	NMDeprecated( "StatsOffset", "NMStatsOffsetWin" )
	
	String folder = "_subfolder_"
	Variable baseline = NMStatsVar( "OffsetBsln" )
	Variable table = 1
	
	return NMStatsOffsetWin( win, folder, wName, offsetType, baseline, table )
	
End // StatsOffset

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsOffsetWave(wname, offsetType)
	String wname
	Variable offsetType
	
	NMDeprecated( "StatsOffsetWave", "NMStatsOffsetWave" )
	
	String folder = "_subfolder_"
	
	NMStatsOffsetWave( folder, wName, offsetType )
	
	return 0
	
End // StatsOffsetWave

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsRiseTimeOnset()

	NMDeprecated( "StatsRiseTimeOnset", "" )
	
	return -1 // NOT FUNCTIONAL

End // StatsRiseTimeOnset

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTablesOn( on )
	Variable on
	
	NMDeprecated( "StatsTablesOn", "NMStatsAutoTable" )
	
	return NMStatsAutoTable( on )
	
End // StatsTablesOn

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsPlotAutoCall()

	NMDeprecated( "StatsPlotAutoCall", "NMStatsAutoCall" )
	
	return NMStatsAutoCall()
	
End // StatsPlotAutoCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsPlotAuto( on )
	Variable on
	
	NMDeprecated( "StatsPlotAuto", "NMStatsAutoPlot" )
	
	return NMStatsAutoPlot( on )
	
End // StatsPlotAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDragCall( on )
	Variable on
	
	NMDeprecated( "StatsDragCall", "NMDragOnCall" )
	
	return NMDragOnCall( on )
	
End // StatsDragCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDrag( on )
	Variable on
	
	NMDeprecated( "StatsDrag", "NMDragOn" )
	
	return NMDragOn( on )
	
End // StatsDrag

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDragToggle()

	NMDeprecated( "StatsDragToggle", "NMDragOnToggle" )

	return NMDragOnToggle()
	
End // StatsDragToggle

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDragCheck()

	NMDeprecated( "StatsDragCheck", "NMDragFoldersCheck" )
	
	String gName = ChanGraphName( -1 )
	String fxnName = "StatsDragTrigger"

	return NMDragFoldersCheck( gName, fxnName )

End // StatsDragCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsDragSetY()

	NMDeprecated( "StatsDragSetY", "NMStatsDragUpdate" )
	
	return NMStatsDragUpdate()

End // StatsDragSetY

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAllGroups( win, dsplyFlag, speed )
	Variable win
	Variable dsplyFlag
	Variable speed
	
	NMDeprecated( "StatsAllGroups", "NMStatsComputeAll" )
	
	Variable table = NMStatsVar( "AutoTable" )
	Variable plot = NMStatsVar( "AutoPlot" )
	Variable stats2 = NMStatsVar( "AutoStats2" )
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect( "All Groups" )
	
	Variable rvalue = NMStatsComputeAll( win, dsplyFlag, speed, table, plot, stats2 )
	
	NMWaveSelect( saveWaveSelect )
	
	return rvalue

End // StatsAllGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAllWavesCall()

	NMDeprecated( "StatsAllWavesCall", "NMStatsComputeAllCall" )

	return NMStatsComputeAllCall()

End // StatsAllWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsAllWaves( win, dsplyFlag, speed )
	Variable win
	Variable dsplyFlag
	Variable speed
	
	NMDeprecated( "StatsAllWaves", "NMStatsComputeAll" )
	
	Variable table = NMStatsVar( "AutoTable" )
	Variable plot = NMStatsVar( "AutoPlot" )
	Variable stats2 = NMStatsVar( "AutoStats2" )
	
	return NMStatsComputeAll( win, dsplyFlag, speed, table, plot, stats2 )

End // StatsAllWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesTables( chanNum, forcenew )
	Variable chanNum
	Variable forcenew // NOT USED
	
	NMDeprecated( "StatsWavesTables", "NMStatsWavesTable" )
	
	String folder = "_subfolder_"
	
	return NMStatsWavesTable( folder, chanNum, "" )
	
End // StatsWavesTables

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsWinSelectUpdate()

	NMDeprecated( "StatsWinSelectUpdate", "" )
	
	return -1 // NOT FUNCTIONAL

End // StatsWinSelectUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTableCall()

	NMDeprecated( "StatsTableCall", "NMStatsWinTable" )
	
	NMStatsWinTable( "inputs" )
	NMStatsWinTable( "outputs" )
	
	return 0

End // StatsTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsTableParams( select )
	String select
	
	NMDeprecated( "StatsTableParams", "NMStatsWinTable" )
	
	NMStatsWinTable( select )
	
	return 0
	
End // StatsTableParams

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2Call( fxn )
	String fxn
	
	NMDeprecated( "Stats2Call", "NMStats2Call" )
	
	String select = ""
	
	return NMStats2Call(fxn, select )
	
End // Stats2Call

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2WSelectCall( wname )
	String wname
	
	NMDeprecated( "Stats2WSelectCall", "NMStats2WaveSelectCall" )
	
	String folder = "_selected_"
	
	return NMStats2WaveSelectCall( folder, wName )
	
End // Stats2WSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2WSelect( wname )
	String wname
	
	NMDeprecated( "Stats2WSelect", "NMStats2WaveSelect" )
	
	String folder = "_selected_"
	
	return NMStats2WaveSelect( folder, wName )
	
End // Stats2WSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2WSelectList( filter )
	String filter // not used
	
	NMDeprecated( "Stats2WSelectList", "NMStats2WaveSelectList" )
	
	Variable fullPath = 0
	
	return NMStats2WaveSelectList( fullPath )
	
End // Stats2WSelectList

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2FilterSelectCall()

	NMDeprecated( "Stats2FilterSelectCall", "NMStats2WaveSelectFilterCall" )

	NMStats2WaveSelectFilterCall()
	
	return 0

End // Stats2FilterSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2FilterSelect( filter )
	String filter
	
	NMDeprecated( "Stats2FilterSelect", "NMStats2WaveSelectFilter" )
	
	NMStats2WaveSelectFilter( filter )
	
	return 0
	
End // Stats2FilterSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2Compute()

	NMDeprecated( "Stats2Compute", "NMStats2WaveStats" )

	String wName = "_selected_"
	Variable printToHistory = 0

	return NMStats2WaveStats( wName, printToHistory )

End // Stats2Compute

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2AllCall()

	NMDeprecated( "Stats2AllCall", "NMStats2WaveStatsTableCall" )
	
	return NMStats2WaveStatsTableCall()

End // Stats2AllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2All()

	NMDeprecated( "Stats2All", "NMStats2WaveStatsTable" )
	
	String folder = "_selected_"
	Variable option = 1

	return NMStats2WaveStatsTable( folder, option )

End // Stats2All

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2SaveCall()

	NMDeprecated( "Stats2SaveCall", "NMStats2WaveStatsTableSave" )
	
	String folder = "_selected_"
	String wName = ""
	
	return NMStats2WaveStatsTableSave( folder, wName )

End // Stats2SaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2Save()

	NMDeprecated( "Stats2Save", "NMStats2WaveStatsTableSave" )

	String folder = "_selected_"
	String wName = ""

	return NMStats2WaveStatsTableSave( folder, wName )

End // Stats2Save

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2Table( force )
	Variable force
	
	NMDeprecated( "Stats2Table", "NMStats2WaveStatsTableMake" )
	
	String folder = "_selected_"
	
	return NMStats2WaveStatsTableMake( folder, force )

End // Stats2Table

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesEditCall()

	NMDeprecated( "StatsWavesEditCall", "NMStats2EditAllCall" )

	return NMStats2EditAllCall()
	
End // StatsWavesEditCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesEdit( select )
	String select
	
	NMDeprecated( "StatsWavesEdit", "NMStats2EditAll" )
	
	String folder = "_selected_"
	Variable option = 1
	
	return NMStats2EditAll( folder, option )

End // StatsWavesEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function Stats2Display()

	NMDeprecated( "Stats2Display", "" )

	return -1 // NOT FUNCTIONAL
	
End // Stats2Display

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsSortCall()

	NMDeprecated( "StatsSortCall", "NMStats2SortWaveCall" )

	return NMStats2SortWaveCall()

End // StatsSortCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsSort( wName, wSelect )
	String wName
	Variable wSelect // NOT USED
	
	NMDeprecated( "StatsSort", "NMStats2SortWave" )
	
	return "" // NOT FUNCTIONAL

End // StatsSort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsSortWave( wName, method, xvalue, yvalue, nvalue )
	String wName
	Variable method, xvalue, yvalue, nvalue
	
	NMDeprecated( "StatsSortWave", "NMStats2SortWave" )
	
	String setName = ""
	
	return NMStats2SortWave( wName, method, xvalue, yvalue, nvalue, setName )
	
End // StatsSortWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsHistoCall()

	NMDeprecated( "StatsHistoCall", "NMStats2HistogramCall" )

	String wName = ""
	
	return NMStats2HistogramCall( wName )

End // StatsHistoCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsHisto( wName )
	String wName
	
	NMDeprecated( "StatsHisto", "NMStats2Histogram" )
	
	Variable binsize = 1
	
	return NMStats2Histogram( wName, binsize )
	
End // StatsHisto

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Stats2WSelectDefault()

	NMDeprecated( "Stats2WSelectDefault", "" )
	
	return "" // NOT FUNCTIONAL

End // Stats2WSelectDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsPlotCall()

	NMDeprecated( "StatsPlotCall", "NMStats2PlotCall" )

	return NMStats2PlotCall()

End // StatsPlotCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsPlot( wName )
	String wName
	
	NMDeprecated( "StatsPlot", "NMStats2Plot" )
	
	String waveNameX = ""
	
	return NMStats2Plot( wName, waveNameX )
	
End // StatsPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsEditCall()

	NMDeprecated( "StatsEditCall", "NMStats2EditCall" )

	return NMStats2EditCall()

End // StatsEditCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsEdit( wName )
	String wName
	
	NMDeprecated( "StatsEdit", "NMStats2Edit" )
	
	return NMStats2Edit( wName )
	
End // StatsEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsDeleteNANsCall()

	NMDeprecated( "StatsDeleteNANsCall", "" )

	return "" // NOT FUNCTIONAL

End // StatsDeleteNANsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsDeleteNANs( wName )
	String wName

	NMDeprecated( "StatsDeleteNANs", "" )
	
	//SetNMStatsVar( "WaveLengthFormat", 1 ) // USE THIS FLAG INSTEAD
	
	return "" // NOT FUNCTIONAL
	
End // StatsDeleteNANs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesKillCall()

	NMDeprecated( "StatsWavesKillCall", "NMStats2FolderClearCall" )

	return NMStats2FolderClearCall()

End // StatsWavesKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsWavesKill( select )
	String select
	
	NMDeprecated( "StatsWavesKill", "NMStats2FolderClear" )
	
	String folder = "_selected_"
	
	return NMStats2FolderClear( folder )

End // StatsWavesKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsPrintNamesCall()

	NMDeprecated( "StatsPrintNamesCall", "NMStats2PrintNamesCall" )

	return NMStats2PrintNamesCall()

End // StatsPrintNamesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsPrintNames( select )
	String select // NOT USED
	
	NMDeprecated( "StatsPrintNames", "NMStats2PrintNames" )
	
	String folder = "_selected_"
	Variable option = 1
	Variable fullPath = 0
	
	return NMStats2PrintNames( folder, option, fullPath )
	
End // StatsPrintNames

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StatsStabilityCall()

	NMDeprecated( "StatsStabilityCall", "NMStats2StabilityCall" )

	return NMStats2StabilityCall()

End // StatsStabilityCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStability( wName, bgnPnt, endPnt, minArray, sig, win2Frac )
	String wName // input wave name
	Variable bgnPnt // begin search point
	Variable endPnt // end search point ( inf ) for all
	Variable minArray // min sliding search window size
	Variable sig // significance level ( 0.05 )
	Variable win2Frac // fraction of minArray for 2nd refinement pass, ( 1 ) for no refinement
	
	NMDeprecated( "NMStability", "NMStabilityRankOrderTest" )
	
	String setName = ""
	
	return NMStabilityRankOrderTest( wName, bgnPnt, endPnt, minArray, sig, win2Frac, setName )
	
End // NMStability

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMOrderWavesPref()

	NMDeprecated( "NMOrderWavesPref", "NeuroMaticStr" )

	return NeuroMaticStr( "OrderWavesBy" )

End // NMOrderWavesPref()

//****************************************************************
//****************************************************************
//****************************************************************

Function /S WaveListOfSize( wavesize, matchStr )
	Variable wavesize
	String matchStr
	
	NMDeprecated( "WaveListOfSize", "WaveList" )
	
	String optionsStr = NMWaveListOptions( waveSize, 0 )
	
	return WaveList( matchStr, ";", optionsStr )

End // WaveListOfSize

//****************************************************************
//****************************************************************
//****************************************************************

Function /S WaveListFolder( folder, matchStr, separatorStr, optionsStr )
	String folder // ( "" ) for current folder
	String matchStr, separatorStr, optionsStr // see Igor WaveList
	
	NMDeprecated( "WaveListFolder", "NMFolderWaveList" )
	
	return NMFolderWaveList( folder, matchStr, separatorStr, optionsStr, 0 )
	
End // WaveListFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S WaveListText0() // only Igor 5

	NMDeprecated( "WaveListText0", "" )

	return "Text:0"
	
End // WaveListText0

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CopyAllWavesTo( fromFolder, toFolder, alert )
	String fromFolder, toFolder
	Variable alert // ( 0 ) no alert ( 1 ) alert if overwriting
	
	NMDeprecated( "CopyAllWavesTo", "CopyWavesTo" )
	
	String newPrefi = ""
	String wList = "_All_"
	
	return CopyWavesTo( fromFolder, toFolder, newPrefi, -inf, inf, wList, alert )
	
End // CopyAllWavesTo

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByNumCall()

	NMDeprecated( "NMScaleByNumCall", "NMScaleWaveCall" )
	
	return NMScaleWaveCall()

End // NMScaleByNumCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByNum( alg, value )
	String alg
	Variable value
	
	NMDeprecated( "NMScaleByNum", "NMScaleWave" )
	
	return NMScaleWave( alg, value, -inf, inf )

End // NMScaleByNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S BreakWave( wName, outPrefix, npnts )
	String wName // wave to break up
	String outPrefix // output wave prefix
	Variable npnts
	
	Variable chanNum = -1
	
	NMDeprecated( "BreakWave", "SplitWave" )

	return SplitWave( wName, outPrefix, chanNum, npnts )

End // BreakWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NormWaves( fxn, tbgn, tend, bbgn, bend, wList )
	String fxn // normalize function ( "max" or "min" or "avg" )
	Variable tbgn, tend // window to compute max or min
	Variable bbgn, bend // baseline window
	String wList // wave list ( seperator ";" )
	
	NMDeprecated( "NormWaves", "NormalizeWaves" )
	
	return NormalizeWaves( "avg", bbgn, bend, fxn, tbgn, tend, wList )

End // NormWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ScaleByNum( alg, num, wList )
	String alg // arhithmatic symbol ( x, /, +, - )
	Variable num // scale value
	String wList // wave list ( seperator ";" )
	
	NMDeprecated( "ScaleByNum", "NMScaleWaves" )
	
	Variable tbgn = -inf
	Variable tend = inf
	
	return NMScaleWaves( alg, num, tbgn, tend, wList )

End // ScaleByNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ScaleWave( alg, num, tbgn, tend, wList )
	String alg // arhithmatic symbol ( x, /, +, - )
	Variable num // scale value
	Variable tbgn, tend // time begin, end values
	String wList // wave list ( seperator ";" )
	
	NMDeprecated( "ScaleWave", "NMScaleWaves" )
	
	return NMScaleWaves( alg, num, tbgn, tend, wList )

End // ScaleWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S AvgWaves( wList )
	String wList // wave list ( seperator ";" )
	
	Variable useChannelTransforms = -1
	Variable ignoreNANs = 0
	Variable truncateToCommonTimeScale = 1
	Variable interpToSameTimeScale = 0
	Variable saveMatrix = 0
	
	NMDeprecated( "AvgWaves", "NMWavesStatistics" )

	String rList = NMWavesStatistics( wList, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix )
	
	KillWaves /Z U_Sum, U_SumSqr
	
	if ( ItemsInList( rList ) > 0 )
		return wList
	else
		return ""
	endif

End // AvgWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S AvgWavesPntByPnt( wList )
	String wList // wave list ( seperator ";" )
	
	Variable useChannelTransforms = -1
	Variable ignoreNANs = 1
	Variable truncateToCommonTimeScale = 0
	Variable interpToSameTimeScale = 0
	Variable saveMatrix = 0

	NMDeprecated( "AvgWavesPntByPnt", "NMWavesStatistics" )
	
	String rList = NMWavesStatistics( wList, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix )
	
	KillWaves /Z U_Sum, U_SumSqr
	
	if ( ItemsInList( rList ) > 0 )
		return wList
	else
		return ""
	endif

End // AvgWavesPntByPnt

//****************************************************************
//****************************************************************
//****************************************************************

Function /S AvgChanWaves( chanNum, wList )
	Variable chanNum
	String wList
	
	Variable useChannelTransforms = chanNum
	Variable ignoreNANs = 0
	Variable truncateToCommonTimeScale = 1
	Variable interpToSameTimeScale = 0
	Variable saveMatrix = 0
	
	NMDeprecated( "AvgChanWaves", "NMWavesStatistics" )
	
	String rList = NMWavesStatistics( wList, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix )
	
	KillWaves /Z U_Sum, U_SumSqr
	
	if ( ItemsInList( rList ) > 0 )
		return wList
	else
		return ""
	endif

End // AvgChanWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SumWaves( wList )
	String wList
	
	Variable useChannelTransforms = -1
	Variable ignoreNANs = 0
	Variable truncateToCommonTimeScale = 1
	Variable interpToSameTimeScale = 0
	Variable saveMatrix = 0
	
	NMDeprecated( "SumWaves", "NMWavesStatistics" )

	String rList = NMWavesStatistics( wList, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix )
	
	KillWaves /Z U_Avg, U_Sdv, U_2Dmatrix
	
	if ( ItemsInList( rList ) > 0 )
		return wList
	else
		return ""
	endif

End // SumWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SumChanWaves( chanNum, wList )
	Variable chanNum
	String wList // wave list ( seperator ";" )
	
	Variable useChannelTransforms = chanNum
	Variable ignoreNANs = 0
	Variable truncateToCommonTimeScale = 1
	Variable interpToSameTimeScale = 0
	Variable saveMatrix = 0
	
	NMDeprecated( "SumChanWaves", "NMWavesStatistics" )
	
	String rList = NMWavesStatistics( wList, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix )
	
	KillWaves /Z U_Avg, U_Sdv, U_2Dmatrix
	
	if ( ItemsInList( rList ) > 0 )
		return wList
	else
		return ""
	endif

End // SumChanWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function CopyWaveValues( fromFolder, toFolder, wList, fromOffset, toOffset )
	String fromFolder
	String toFolder
	String wList // wave list ( seperator ";" )
	Variable fromOffset
	Variable toOffset
	
	NMDeprecated( "CopyWaveValues", "CopyWavesTo" )
	
	return -1

End // CopyWaveValues

//****************************************************************
//****************************************************************
//****************************************************************

Function FindLevelPosNeg( tbgn, tend, level, direction, wName )
	Variable tbgn
	Variable tend
	Variable level
	String direction
	String wName
	
	NMDeprecated( "FindLevelPosNeg", "FindLevel /EDGE" )
	
	strswitch( direction )
	
		case "+":
			FindLevel /EDGE=1/Q/R=( tbgn, tend ) $wname, level
			break
			
		case "-":
			FindLevel /EDGE=2/Q/R=( tbgn, tend ) $wname, level
			break
			
		default:
			return Nan
			
	endswitch
	
	return V_LevelX

End // FindLevelPosNeg

//****************************************************************
//****************************************************************
//****************************************************************

Function WaveCountOnes( wname )
	String wname
	
	NMDeprecated( "WaveCountOnes", "WaveCountValue" )

	return WaveCountValue( wname, 1 )

End // WaveCountOnes

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Make2DWave( wList )
	String wList // input wave name list ( ";" seperator )
	
	Variable useChannelTransforms = -1
	Variable ignoreNANs = 0
	Variable truncateToCommonTimeScale = 1
	Variable interpToSameTimeScale = 0
	Variable saveMatrix = 1
	
	NMDeprecated( "Make2DWave", "NMWavesStatistics" )
	
	return NMWavesStatistics( wList, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix )

End // Make2DWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S RemoveStrEndSpace( istring )
	String istring
	Variable icnt
	
	NMDeprecated( "RemoveStrEndSpace", "RemoveEnding" )
	
	return RemoveEnding( istring, " " )

End // RemoveStrEndSpace

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StringReplace( inStr, replaceThisStr, withThisStr )
	String inStr
	String replaceThisStr
	String withThisStr
	
	NMDeprecated( "StringReplace", "ReplaceString" )
	
	return ReplaceString( replaceThisStr, inStr, withThisStr )

End // StringReplace

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReplaceChar( replaceThisStr, inStr, withThisStr )
	String replaceThisStr
	String inStr
	String withThisStr
	
	NMDeprecated( "NMReplaceChar", "ReplaceString" )
	
	return ReplaceString( replaceThisStr, inStr, withThisStr )
	
End // NMReplaceChar

//****************************************************************
//****************************************************************
//****************************************************************

Function StrSearchLax( str, findThisStr, start )
	String str
	String findThisStr
	Variable start
	
	NMDeprecated( "StrSearchLax", "strsearch" )
	
	return strsearch( str, findThisStr, start, 2 )

End // StrSearchLax

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ReverseList( listStr, listSepStr )
	String listStr, listSepStr
	
	NMDeprecated( "ReverseList", "NMReverseList" )
	
	return NMReverseList( listStr, listSepStr )
	
End // ReverseList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S RemoveListFromList( itemList, listStr, listSepStr )
	String itemList, listStr, listSepStr
	
	NMDeprecated( "RemoveListFromList", "RemoveFromList" )

	return RemoveFromList( itemList, listStr, listSepStr )

End // RemoveListFromList

//****************************************************************
//****************************************************************
//****************************************************************

Function WhichListItemLax( itemStr, listStr, listSepStr )
	String itemStr, listStr, listSepStr
	
	NMDeprecated( "WhichListItemLax", "WhichListItem" )
	
	Variable startIndex = 0
	Variable matchCase = 0
	
	return WhichListItem( itemStr , listStr , listSepStr, startIndex, matchCase )
	
End // WhichListItemLax

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChangeListSep( strList, listSepStr )
	String strList
	String listSepStr
	
	NMDeprecated( "ChangeListSep", "ReplaceString" )
	
	strswitch( listSepStr )
		case ";":
			return ReplaceString( ",", strList, ";" )
		case ",":
			return ReplaceString( ";", strList, "," )
	endswitch
	
	return ""
	
End // ChangeListSep

//****************************************************************
//****************************************************************
//****************************************************************

Function /S GetListItems( matchStr, strList, listSepStr )
	String matchStr
	String strList
	String listSepStr
	
	NMDeprecated( "GetListItems", "ListMatch" )
	
	return ListMatch( strList, matchStr, listSepStr )

End // GetListItems

//****************************************************************
//****************************************************************
//****************************************************************

Function /S MatchStrList( strList, matchStr )
	String strList
	String matchStr
	
	NMDeprecated( "MatchStrList", "ListMatch" )
	
	return ListMatch( strList, matchStr, ";" )
	
End // MatchStrList

//****************************************************************
//****************************************************************
//****************************************************************




