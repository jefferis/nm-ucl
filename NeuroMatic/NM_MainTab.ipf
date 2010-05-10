#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Main Tab Functions 
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	NM tab entry "Main"
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S MainPrefix( objName )
	String objName
	
	return "MN_" + objName
	
End // MainPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S MainDF() // return Main full-path folder name

	return PackDF( "Main" )
	
End // MainDF

//****************************************************************
//****************************************************************
//****************************************************************

Function MainTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable == 1 )
		CheckPackage( "Main", 0 ) // declare folder/globals if necessary
		DisableNMPanel( 0 )
		MakeMainTab() // create controls if necessary
		ChanControlsDisable( -1, "000000" )
	endif

End // MainTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillMain( what )
	String what
	String df = MainDF()
	
	strswitch( what )
	
		case "waves":
			KillGlobals( GetDataFolder( 1 ), "Avg*", "001" )
			KillGlobals( GetDataFolder( 1 ), "Sum*", "001" )
			return 0
			
		case "folder":
			if ( DataFolderExists( df ) == 1 )
				KillDataFolder $df
			endif
			return 0
			
	endswitch
	
	return -1

End // KillMain

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckMain()
	
	// nothing to check
	
End // CheckMain

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMainVar( varName )
	String varName
	
	Variable defaultVal = Nan
	
	strswitch( varName )
	
		case "Bsln_Method":
			defaultVal = 1
			break
			
		case "Bsln_Bgn":
			defaultVal = 0
			break
		
		case "Bsln_End":
			defaultVal = 10
			break
		
		case "AvgMode":
			defaultVal = 2
			break
			
		case "AvgChanTransforms":
			defaultVal = 0
			break
			
		case "AvgIgnoreNANs":
			defaultVal = 1
			break
			
		case "AvgTruncate":
			defaultVal = 0
			break
			
		case "AvgPlotData":
			defaultVal = 1
			break
			
		case "AvgOnePlot":
			defaultVal = 1
			break
			
		case "SmoothNum":
			defaultVal = 1
			break
			
		case "CopyTbgn":
			defaultVal = -inf
			break
			
		case "CopyTend":
			defaultVal = inf
			break
			
		case "CopySelect":
			defaultVal = 1
			break
			
		case "ScaleByNumVal":
			defaultVal = 1
			break
			
		case "ScaleByWaveMthd":
			defaultVal = 0
			break
			
		case "AlignPosTime":
			defaultVal = 1
			break
			
		case "AlignInterp":
			defaultVal = 0
			break
			
		default:
			NMDoAlert( "NMMainVar Error : no variable called " + NMQuotes( varName ) )
			return Nan
	
	endswitch
	
	return NumVarOrDefault( MainDF()+varName, defaultVal )
	
End // NMMainVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainStr( varName )
	String varName
	
	String defaultStr = ""
	
	strswitch( varName )
	
		case "PlotColor":
			defaultStr = "rainbow"
			break
	
		case "SmoothAlg":
			defaultStr = "binomial"
			break
			
		case "ScaleByNumAlg":
			defaultStr = "*"
			break
			
		case "ScaleByWaveAlg":
			defaultStr = "*"
			break
			
		default:
			NMDoAlert( "NMMainStr Error : no variable called " + NMQuotes( varName ) )
			return ""
	
	endswitch
	
	return StrVarOrDefault( MainDF() + varName, defaultStr )
			
End // NMMainStr

//****************************************************************
//****************************************************************
//****************************************************************

Function MainConfigs()

	String fname = "Main"

	NMMainConfigVar( "Bsln_Method", "( 1 ) subtract wave's individual mean ( 2 ) subtract mean of all waves" )
	NMMainConfigVar( "Bsln_Bgn", "Baseline window begin (ms)" )
	NMMainConfigVar( "Bsln_End", "Baseline window end (ms)" )
	
	NMMainConfigVar( "AvgMode", "( 1 ) mean ( 2 ) mean + stdv ( 3 ) mean + var ( 4 ) mean + sem" )
	NMMainConfigVar( "AvgChanTransforms", "use channel filtering/smoothing and F(t )? ( 0 ) no ( 1 ) yes" )
	NMMainConfigVar( "AvgIgnoreNANs", "ignores NANs in data? ( 0 ) no ( 1 ) yes" )
	NMMainConfigVar( "AvgTruncate", "truncate average to a common time base? ( 0 ) no ( 1 ) yes" )
	NMMainConfigVar( "AvgPlotData", "display data with average results? ( 0 ) no ( 1 ) yes" )
	NMMainConfigVar( "AvgOnePlot", "display sets/groups in same plot? ( 0 ) no ( 1 ) yes" )
	
	NMMainConfigVar( "SmoothNum", "Number of smoothing points/operations" )
	NMMainConfigStr( "SmoothAlg", "Smoothing algorithm ( binomial, boxcar, polynomial )" )
	
End // MainConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMainConfigVar( varName, description )
	String varName
	String description
	
	return NMConfigVar( "Main", varName, NMMainVar( varName ), description )
	
End // NMMainConfigVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMainConfigStr( varName, description )
	String varName
	String description
	
	return NMConfigStr( "Main", varName, NMMainStr( varName ), description )
	
End // StatsConfigStr

//****************************************************************
//****************************************************************
//****************************************************************

Function MakeMainTab() // create Main tab controls
	Variable x0 = 40, xinc = 120, y0 = 190, yinc = 45, fs = NMPanelFsize()
	Variable taby = NMPanelTabY()
	
	y0 = taby + 50

	ControlInfo /W=NMPanel MN_Plot
	
	if ( V_Flag != 0 ) 
		return 0 // main tab controls already exist
	endif
	
	DoWindow /F NMPanel // bring NMPanel to front
	
	Button MN_Plot, pos={x0,y0}, title = "Plot", size={100,20}, proc=NMMainButton, fsize=fs, win=NMpanel
	Button MN_Copy, pos={x0+xinc,y0}, title = "Copy", size={100,20}, proc=NMMainButton, fsize=fs, win=NMpanel
	
	Button MN_Baseline, pos={x0,y0+1*yinc}, title="Baseline", size={100,20}, proc=NMMainButton, fsize=fs, win=NMpanel
	Button MN_Average, pos={x0+xinc,y0+1*yinc}, title="Average", size={100,20}, proc=NMMainButton, fsize=fs, win=NMpanel
	
	Button MN_YScale, pos={x0,y0+2*yinc}, title="Scale", size={100,20}, proc=NMMainButton, fsize=fs, win=NMpanel
	Button MN_XAlign, pos={x0+xinc,y0+2*yinc}, title="Align", size={100,20}, proc=NMMainButton, fsize=fs, win=NMpanel
	
	//Button MN_ReOrder, pos={x0+xinc/2,y0+3*yinc}, title="Order Waves", size={100,20}, proc=NMMainButton, fsize=fs, win=NMpanel
	
	y0 += 210
	
	GroupBox MN_Group, title = "More...", pos={x0-20,y0-35}, size={260,130}, fsize=fs, win=NMpanel
	
	PopupMenu MN_DisplayMenu, pos={x0+100,y0+0*yinc}, size={0,0}, bodyWidth=100, fsize=fs, proc=NMMainPopup, win=NMpanel
	PopupMenu MN_DisplayMenu, value=NMMainDisplayMenu(), win=NMpanel
	
	PopupMenu MN_EditMenu, pos={x0+100+xinc,y0+0*yinc}, size={0,0}, bodyWidth=100, fsize=fs, proc=NMMainPopup, win=NMpanel
	PopupMenu MN_EditMenu, value=NMMainEditMenu(), win=NMpanel
	
	PopupMenu MN_TScaleMenu, pos={x0+100,y0+1*yinc}, size={0,0}, bodyWidth=100, fsize=fs, proc=NMMainPopup, win=NMpanel
	PopupMenu MN_TScaleMenu, value=NMMainTimeScaleMenu(), win=NMpanel
	
	PopupMenu MN_FxnMenu, pos={x0+100+xinc,y0+1*yinc}, size={0,0}, bodyWidth=100, fsize=fs, proc=NMMainPopup, win=NMpanel
	PopupMenu MN_FxnMenu, value=NMMainOperationsMenu(), win=NMpanel
	
End // MakeMainTab

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainDisplayMenu()

	return "Display;---;Plot ;Table;XLabel;YLabel;Print Notes;Print Names;" // keep extra space after Plot

End // MainTabDisplayMenuList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainEditMenu()

	return "Edit;---;Copy;Rename;Renumber;Kill;"

End // MainTabEditMenuList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainTimeScaleMenu()

	return "Time Scale;---;Align;Time Begin;Time Step;Resample;Decimate;Interpolate;Redimension;XLabel;Xwave;---;Continuous;Episodic;---;sec;msec;usec;"

End // NMMainTimeScaleMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainOperationsMenu()

	return "Operations;---;Scale by Num;Scale by Wave;Rescale;Baseline;Normalize;Smooth;FilterFIR;FilterIIR;Blank;Integrate;Differentiate;2-Differentiate;Reverse;Sort;Replace Value;Delete NANs;---;Average;Sum;SumSqr;2D Matrix;Concatenate;Split Waves;IV;"

End // NMMainOperationsMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMainPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu $ctrlName, win=NMpanel, mode=1 // force menus back to title
	
	strswitch( popStr )
		case "---":
			break
		default:
			NMMainCall( popStr )
	endswitch
	
End // NMMainPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMainButton( ctrlName ) : ButtonControl
	String ctrlName
	
	NMMainCall( ctrlName[3,inf] )

End // NMMainButton

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainCall( fxn )
	String fxn
	
	String outList = ""
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( CheckCurrentFolder() == 0 )
		return ""
	endif
	
	if ( NumVarOrDefault( CurrentNMPrefixFolder()+"NumActiveWaves", 0 ) <= 0 )
		NMDoAlert( "No waves selected!" )
		return ""
	endif
	
	strswitch( fxn )
	
		// Display Functions
		
		case "Plot":
		case "Graph":
			return NMPlotCall( NMMainStr( "PlotColor" ) )
			
		case "Plot ":
			return NMPlotCall( "" )
		
		case "Plot Black":
			return NMPlotCall( "black" )

		case "Plot Red":
			return NMPlotCall( "red" )
			
		case "Rainbow":
		case "Plot Rainbow":
			return NMPlotCall( "rainbow" )
			
		case "Edit":
		case "Table":
			return NMEditWavesCall()
		
		case "Names":
		case "List Names":
		case "Print Names":
			outList = NMPrintWaveListCall()
			break
			
		case "Notes":
		case "Print Notes":
			outList = NMPrintWaveNotesCall()
			break
			
		case "XLabel":
		case "Time Label":
			outList = NMXLabelCall()
			break
			
		case "YLabel":
			outList = NMYLabelCall()
			break
		
		// Edit Functions
			
		case "Copy":
		case "Copy To":
			outList = NMCopyWavesToCall()
			break
			
		case "Kill":
		case "Delete":
			outList = NMDeleteWavesCall()
			break
			
		case "Rename":
			outList = NMRenameWavesCall( "Selected" )
			break
			
		case "Renumber":
			return NMRenumWavesCall()
			
		// Time Scale Functions
		
		case "Xwave":
			return NMXwaveSetCall()
		
		case "Align":
		case "XAlign":
			outList = NMAlignWavesCall()
			break
			
		case "Time Begin":
			outList = NMStartXCall()
			break
		
		case "Delta":
		case "Time Step":
			outList = NMDeltaXCall()
			break
			
		case "Redimension":
			outList = NMNumPntsCall()
			break
			
		case "Resample":
			outList = NMResampleWavesCall()
			break
			
		case "Decimate":
			outList = NMDecimate2DeltaXCall()
			break
			
		case "Interpolate":
			outList = NMInterpolateWavesCall()
			break
			
		case "Reverse":
		case "Reflect":
			outList = NMReverseWavesCall()
			break
			
		case "Sort":
			NMSortWavesByKeyWaveCall()
			break
			
		case "Continuous":
			return NMTimeScaleModeCall( 1 )
		
		case "Episodic":
			return NMTimeScaleModeCall( 0 )
			
		case "sec":
		case "msec":
		case "usec":
			return NMXUnitsChangeCall( fxn )
			
		// Operations
		
		case "Baseline":
			outList = NMBaselineCall()
			break
		
		case "YScale":
			outList = NMScaleWaveCall()
			break
		
		case "Scale By Num":
		case "Scale By Number":
			outList = NMScaleWaveCall()
			break
			
		case "Scale By Wave":
			outList = NMScaleByWaveCall()
			break
			
		case "Rescale":
			outList = NMYUnitsChangeCall()
			break
			
		case "Normalize":
			outList = NMNormalizeWavesCall()
			break
			
		case "Blank":
			NMBlankWavesCall()
			return ""
			
		case "d/dt":
		case "Differentiate":
			outList = NMDiffWavesCall( 1 )
			break
			
		case "dd/dt*dt":
		case "2-Differentiate":
			outList = NMDiffWavesCall( 2 )
			break
			
		case "integral":
		case "Integrate":
			outList = NMDiffWavesCall( 3 )
			break
			
		case "Smooth":
			outList = NMSmoothWavesCall()
			break
			
		case "FilterFIR":
			outList = NMFilterFIRWavesCall()
			break
			
		case "FilterIIR":
			outList = NMFilterIIRWavesCall()
			break
			
		case "Replace Value":
			outList = NMReplaceWaveValueCall()
			break
			
		case "Delete NANs":
			outList = NMDeleteNANsCall()
			break
			
		// Misc Functions
			
		case "Average":
			outList = NMWavesStatsCall( "Average" )
			break
			
		case "Sum":
			outList = NMWavesStatsCall( "Sum" )
			break
			
		case "SumSqr":
			outList = NMWavesStatsCall( "SumSqr" )
			break
		
		case "IV":
			return NMIVCall()
			
		case "Concat":
		case "Concatenate":
			outList = NMConcatWavesCall()
			break
			
		case "Split Waves":
			outList = NMSplitWavesCall()
			break
			
		case "2D Wave":
		case "2D Matrix":
			outList = NMWavesStatsCall( "Matrix" )
			break
			
		default:
			NMDoAlert( "NMMainCall: unrecognized function call: " + fxn )

	endswitch
	
	if ( ItemsInList( outList ) == 0 )
		//NMDoAlert( "Alert: no waves passed through " + NMQuotes( fxn ) + " function."
	endif
	
End // NMMainCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainHistory( mssg, chanNum, wList, namesFlag )
	String mssg
	Variable chanNum
	String wList // wave list ";"
	Variable namesFlag // print wave names ( 0 ) no ( 1 ) yes
	
	String waveSelect = NMWaveSelectGet()
	
	strswitch( waveSelect )
		case "This Wave":
			waveSelect = "Wave " + num2istr( CurrentNMWave() )
			break
	endswitch
	
	if ( strlen( mssg ) == 0 )
		mssg = "Chan " + ChanNum2Char( chanNum ) + " : " + waveSelect + " : N = " + num2istr( ItemsInlist( wList ) )
	else
		mssg += " : Chan " + ChanNum2Char( chanNum ) + " : " + waveSelect + " : N = " + num2istr( ItemsInlist( wList ) )
	endif
	
	if ( namesFlag == 1 )
		mssg += " : " + wList
	endif
	
	NMHistory( mssg )
	
	return mssg

End // NMMainHistory

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintWaveListCall()
	
	NMCmdHistory( "NMPrintWaveList", "" )
	
	return NMPrintWaveList()

End // NMPrintWaveListCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintWaveList()

	Variable ccnt, icnt
	String cList, wList = ""
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	Variable numChannels = NMNumChannels()
	
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	String allList = NMWaveSelectAllList()
	Variable allListItems = ItemsInList( allList )
	
	for ( icnt = 0; icnt < max( allListItems, 1 ) ; icnt += 1 )
		
		if ( allListItems > 0 )
			waveSelect = StringFromList( icnt, allList )
			NMWaveSelect( waveSelect )
		endif
	
		for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue // channel not selected
			endif
			
			cList = NMWaveSelectList( ccnt )
			wList += cList
			
			NMMainHistory( "", ccnt, cList, 0 )
			NMHistory( cList )
	
		endfor
		
	endfor
	
	if ( allListItems > 0 )
		NMWaveSelect( saveWaveSelect )
	endif
	
	return wList

End // NMPrintWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintWaveNotesCall()

	NMCmdHistory( "NMPrintWaveNotes", "" )
	
	return NMPrintWaveNotes()

End // NMPrintWaveNotesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrintWaveNotes()

	Variable ccnt, wcnt
	String wName, wNote, cList = "", wList = ""
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
		
			wName = NMWaveSelected( ccnt, wcnt )
			
			if ( strlen( wName ) == 0 )
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			wNote = note( $wName )
			
			if ( strlen( wNote ) == 0 )
				continue
			endif
			
			NMHistory( "\r" + wName + " Notes:\r" + wNote )
			
			cList = AddListItem( wName, cList, ";", inf )
			
		endfor
		
		wList += cList

	endfor
	
	return wList

End // NMPrintWaveNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDiffWavesCall( dtFlag )
	Variable dtFlag
	
	String df = MainDF()
	
	if (( numtype( dtFlag ) > 0 ) || ( dtFlag < 0 ) )
		dtFlag = NumVarOrDefault( df+"dtFlag", 1 )
	endif
	
	switch( dtFlag )
		case 1:
		case 2:
		case 3:
			break
		default:
			dtFlag = 1
	endswitch
		
	Prompt dtFlag, "choose operation:", popup "d/dt;dd/dt*dt;integrate"
	DoPrompt NMPromptStr( "Differentiate/Integrate" ), dtFlag
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( df+"dtFlag", dtFlag )
	
	NMCmdHistory( "NMDiffWaves", NMCmdNum( dtFlag,"" ) )
	
	return NMDiffWaves( dtFlag )

End // NMDiffWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDiffWaves( dtFlag )
	Variable dtFlag // ( 1 ) d/dt ( 2 ) dd/dt*dt ( 3 ) integral
	
	Variable ccnt
	String fxn, cList, wList = ""
	String thisfxn = "NMDiffWaves"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif 
	
	switch( dtFlag )
		case 1:
			fxn = "d/dt"
			break
		case 2:
			fxn = "dd/dt*dt"
			break
		case 3:
			fxn = "integrate"
			break
		default:
			return NMErrorStr( 10, thisfxn, "dtFlag", num2istr( dtFlag ) )
	endswitch
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = DiffWaves( cList, dtFlag )
		wList += cList
		
		NMMainHistory( fxn, ccnt, cList, 0 )
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMDiffWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeleteWavesCall()

	NMCmdHistory( "NMDeleteWaves", "" )

	return NMDeleteWaves()

End // NMDeleteWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeleteWaves()

	Variable ccnt, items, failure
	String cList, wList = ""
	
	Variable numChannels = NMNumChannels()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif 
	
	if ( NeuroMaticVar( "NMDeleteWavesNoAlert" ) == 1 )
	
		SetNeuroMaticVar( "NMDeleteWavesNoAlert", 0 ) // reset flag
	
	else
	
		DoAlert 1, "Warning: NMDeleteWaves will attempt to permanently delete all of your currently selected waves. Do you want to continue?"
		
		if ( V_Flag != 1 )
			return "" // cancel
		endif
	
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		items = ItemsInList( cList )
		
		cList = DeleteWaves( cList )
		
		if ( ItemsInList( cList ) != items )
			failure = 1
		endif
		
		wList += cList
		
		NMMainHistory( "Deleted", ccnt, cList, 0 )
		
	endfor
	
	if ( failure == 1 )
		NMDoAlert( "There was a failure to delete some of the currently selected waves. These waves may be currently displayed in a graph or table, or may be locked.." )
	endif
	
	//NMPrefixSelect( "" )
	ChanGraphsUpdate()
	
	return wList

End // NMDeleteWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeleteNANsCall()

	DoAlert 1, "Delete NAN's from selected waves?"
	
	if ( V_flag != 1 )
		return ""
	endif

	NMCmdHistory( "NMDeleteNANs", "" )

	return NMDeleteNANs()

End // NMDeleteNANsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeleteNANs()

	Variable ccnt, wcnt, error
	String wname, cList = "", wList = "", badList = ""
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif 
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
		
			wName = NMWaveSelected( ccnt, wcnt )
			
			if ( strlen( wName ) == 0 )
				continue // wave not selected, or does not exist... go to next wave
			endif
	
			WaveTransform /O zapNaNs $wname
			
			cList = AddListItem( wName, cList, ";", inf )
			
		endfor
		
		NMMainHistory( "Deleted NANs", ccnt, cList, 0 )
		
		wList += cList
		
	endfor
	
	ChanGraphsUpdate()
	
	KillWaves /Z U_TempWave
	
	return wList

End // NMDeleteNANs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReplaceWaveValueCall()
	
	String vlist = "", df = MainDF()
	
	Variable findVal = NumVarOrDefault( df+"ReplaceFindValue", 0 )
	Variable replacementVal = NumVarOrDefault( df+"ReplaceValue", 0 )
	
	Prompt findVal, "wave value to find:"
	Prompt replacementVal, "replacement value:"
	
	DoPrompt NMPromptStr( "Replace Wave Value" ), findVal, replacementVal
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( df+"ReplaceFindValue", findVal )
	SetNMvar( df+"ReplaceValue", replacementVal )
	
	vlist = NMCmdNum( findVal, vlist )
	vlist = NMCmdNum( replacementVal, vlist )
	NMCmdHistory( "NMReplaceWaveValue", vlist )

	return NMReplaceWaveValue( findVal, replacementVal )

End // NMReplaceWaveValueCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReplaceWaveValue( findVal, replacementVal )
	Variable findVal // wave value to find
	Variable replacementVal // replacement value
	
	Variable ccnt
	String cList, wList = ""
	String thisfxn = "NMReplaceWaveValue"
	
	Variable numChannels = NMNumChannels()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif 
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = NMReplaceValue( findVal, replacementVal, cList )
		wList += cList
		
		NMMainHistory( "Replaced wave value " + num2str( findVal ) + " with " + num2str( replacementVal ), ccnt, cList, 0 )
		
	endfor
	
	return wList

End // NMReplaceWaveValue

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWavesCall()

	String wList, vList = "", df = MainDF()
	
	String currentPrefix = CurrentNMWavePrefix()
	String newPrefix = StrVarOrDefault( df+"CopyPrefix", "C_" )
	
	Variable tbgn = NumVarOrDefault( df+"CopyTbgn", -inf )
	Variable tend = NumVarOrDefault( df+"CopyTend", inf )
	Variable select = 1 + NumVarOrDefault( df+"CopySelect", 1 )
	
	Prompt newPrefix, "enter new prefix name to attach to copied waves:"
	Prompt tbgn, "copy source waves from (ms):"
	Prompt tend, "copy source waves to (ms):"
	Prompt select, "select as current waves?", popup "no;yes;"
	
	DoPrompt NMPromptStr( "Copy Waves" ), newPrefix, tbgn, tend, select
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	select -= 1
	
	SetNMstr( df+"CopyPrefix", newPrefix )
	SetNMvar( df+"CopyTbgn", tbgn )
	SetNMvar( df+"CopyTend", tend )
	SetNMvar( df+"CopySelect", select )
	
	vList = NMCmdStr( newPrefix, vList )
	vList = NMCmdNum( tbgn, vList )
	vList = NMCmdNum( tend, vList )
	vList = NMCmdNum( select, vList )
	
	NMCmdHistory( "NMCopyWaves", vList ) 
	
	return NMCopyWaves( newPrefix, tbgn, tend, select )
	
End // NMCopyWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWaves( newPrefix, tbgn, tend, select )
	String newPrefix // new wave prefix to be appended to current wave names
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	Variable select // select as current prefix ( 0 ) no ( 1 ) yes
	
	Variable ccnt
	String cList, wList, txt, thisfxn = "NMCopyWaves"
	
	String currentPrefix = CurrentNMWavePrefix()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( strlen( newPrefix ) == 0 )
		return NMErrorStr( 21, thisfxn, "newPrefix", newPrefix )
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( StringMatch( newPrefix, currentPrefix ) == 1 )
		return NMErrorStr( 90, thisfxn, "this function is not to over-write currently active waves.", "" )
	endif
	
	wList = WaveList( newPrefix + currentPrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )
		txt = "waves with prefix " + NMQuotes( newPrefix + currentPrefix ) + " already exist in the current data folder. "
		txt += "Please try a different wave prefix."
		return NMErrorStr( 90, thisfxn, txt, "" )
	endif
	
	wList = ""
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = CopyWaves( newPrefix, tbgn, tend, cList )
		wList += cList
	
		NMMainHistory( "Copied to " + newPrefix + "*", ccnt, cList, 0 )
		
	endfor
	
	if ( ItemsInList( wList ) > 0 )
	
		NMPrefixAdd( newPrefix + currentPrefix )
		
		if ( select == 1 )
			NMPrefixSelectSilent( newPrefix + currentPrefix )
		endif
		
	endif
	
	return wList
	
End // NMCopyWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWavesToCall()

	String fList, wList, vList = "", df = MainDF()
	
	String currentPrefix = CurrentNMWavePrefix()
	
	String newPrefix = StrVarOrDefault( df+"Copy2Prefix", "C_" )
	Variable tbgn = NumVarOrDefault( df+"Copy2Tbgn", -inf )
	Variable tend = NumVarOrDefault( df+"Copy2Tend", inf )
	String toFolder = StrVarOrDefault( df+"Copy2Folder", "this folder" )
	Variable select = 1 + NumVarOrDefault( df+"Copy2Select", 1 )
	
	fList = NMDataFolderList()
	fList = RemoveFromList( GetDataFolder( 0 ), fList )
	
	fList = "This Folder;" + fList
	
	Prompt newPrefix, "new prefix for copied waves:"
	Prompt tbgn, "copy from time (ms):"
	Prompt tend, "copy to time (ms):"
	Prompt toFolder, "copy selected waves to:", popup fList
	Prompt select, "select as current waves?", popup "no;yes;"
	
	DoPrompt NMPromptStr( "Copy Waves" ), newPrefix, tbgn, tend, toFolder, select
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	select -= 1
	
	SetNMstr( df+"Copy2Prefix", newPrefix )
	SetNMvar( df+"Copy2Tbgn", tbgn )
	SetNMvar( df+"Copy2Tend", tend )
	SetNMstr( df+"Copy2Folder", toFolder )
	SetNMvar( df+"Copy2Select", select )
	
	if ( StringMatch( toFolder, "this folder" ) == 1 )
		toFolder = ""
	elseif ( StringMatch( toFolder[0,3], "root" ) == 0 )
		toFolder = "root:" + toFolder
	endif
	
	vList = NMCmdStr( toFolder, "" )
	vList = NMCmdStr( newPrefix, vList )
	vList = NMCmdNum( tbgn, vList )
	vList = NMCmdNum( tend, vList )
	vList = NMCmdNum( 1, vList )
	vList = NMCmdNum( select, vList )
	NMCmdHistory( "NMCopyWavesTo", vList )
	
	return NMCopyWavesTo( toFolder, newPrefix, tbgn, tend, 1, select )
	
End // NMCopyWavesToCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCopyWavesTo( toFolder, newPrefix, tbgn, tend, alert, select )
	String toFolder // where to copy selected waves, ( "" ) for current folder
	String newPrefix // new wave prefix, ( "" ) for current prefix
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	Variable alert // ( 0 ) no copy alert ( 1 ) alert if over-writing
	Variable select // select as current prefix ( 0 ) no ( 1 ) yes
	
	Variable ccnt
	String cList, wList, txt, thisfxn = "NMCopyWavesTo"
	
	String currentPrefix = CurrentNMWavePrefix()
	
	String thisFolder = GetDataFolder( 1 )
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( strlen( toFolder ) == 0 )
		toFolder = GetDataFolder( 1 )
	endif
	
	if ( DataFolderExists( toFolder ) == 0 )
		return NMErrorStr( 30, thisfxn, "toFolder", toFolder )
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	wList = NMFolderWaveList( toFolder, newPrefix + currentPrefix + "*", ";", "", 0 )
	
	if ( ItemsInList( wList ) > 0 )
		txt = "waves with prefix " + NMQuotes( newPrefix + currentPrefix ) + " already exist in folder "
		txt += GetPathName( toFolder, 0 ) + ". Please choose a different wave prefix."
		return NMErrorStr( 90, thisfxn, txt, "" )
	endif
	
	wList = ""
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = CopyWavesTo( thisFolder, toFolder, newPrefix, tbgn, tend, cList, alert )
		wList += cList
		
		//NMHistory( "Copied to " + newPrefix + "* : " + NMMainHistory( ccnt, cList ) )

	endfor
	
	if ( ItemsInList( wList ) > 0 )
	
		if ( strlen( newPrefix ) > 0 )
			NMPrefixAdd( newPrefix + currentPrefix )
		endif
		
		if ( select == 1 )
		
			if ( StringMatch( thisFolder, toFolder ) == 0 )
				NMFolderChange( toFolder )
			endif
			
			NMPrefixSelectSilent( newPrefix + currentPrefix )
			
		endif
		
	endif
	
	return wList
	
End // NMCopyWavesTo

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenameWavesCall( select )
	String select // ( "All" ) search all waves ( "Selected" or "" ) search selected waves
	
	String ptitle = "", vList = "", df = MainDF()
	
	String findStr = StrVarOrDefault( df+"RenameFind", "" )
	String replaceStr = StrVarOrDefault( df+"RenameReplace", "" )
	
	Prompt findStr, "search string:"
	Prompt replaceStr, "replace string:"
	
	strswitch( select )
		case "All":
			ptitle = "Rename Waves : folder " + GetDataFolder( 0 )
			break
		case "":
		case "Wave Select":
		case "Selected":
			ptitle = NMPromptStr( "Rename Waves" )
			break
		default:
			return NMErrorStr( 20, "NMRenameWavesCall", "select", select )
	endswitch
	
	DoPrompt ptitle, findStr, replaceStr
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( df+"RenameSelect", select )
	SetNMstr( df+"RenameFind", findStr )
	SetNMstr( df+"RenameReplace", replaceStr )
	
	vList = NMCmdStr( findStr, vList )
	vList = NMCmdStr( replaceStr, vList )
	vList = NMCmdStr( select, vList )
	NMCmdHistory( "NMRenameWaves", vList )
	
	return NMRenameWaves( findStr, replaceStr, select )

End // NMRenameWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenameWaves( findStr, replaceStr, select )
	String findStr, replaceStr // find string, replace string
	String select // ( "All" ) to search all waves, ( "Selected" or "" ) to search selected waves
	
	Variable ccnt
	String cList, wList = "", thisfxn = "NMRenameWaves"
	
	//if ( NMPrefixFolderAlert() == 0 )
	//	return ""
	//endif
	
	if ( strlen( findStr ) == 0 )
		return NMErrorStr( 21, thisfxn, "findStr", findStr )
	endif
	
	strswitch( select )
	
		case "All":
			wList = RenameWaves( findStr, replaceStr, WaveList( "*",";","" ) ) 
			NMHistory( "Replaced wave name string " + NMQuotes( findStr ) + " with " + NMQuotes( replaceStr ) )
			return wList
			
		default:
	
			for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
				if ( NMChanSelected( ccnt ) != 1 )
					continue // channel not selected
				endif
			
				cList = NMWaveSelectList( ccnt )
				
				if ( strlen( cList ) == 0 )
					continue
				endif
				
				cList = RenameWaves( findStr, replaceStr, cList )
				wList += cList
				
				NMMainHistory( "Replaced wave name string " + NMQuotes( findStr ) + " with " + NMQuotes( replaceStr ), ccnt, cList, 0 )
			
			endfor
	
	endswitch
	
	if ( strlen( wList ) > 0 )
		NMDoAlert( "Alert: renamed waves may no longer be recognized by NeuroMatic. Use wave prefix popup to select appropriate waves." )
	endif
	
	return wList

End // NMRenameWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenumWavesCall()
	String vlist = "", df = MainDF()

	Variable from = NumVarOrDefault( df+"RenumFrom", 0 )
	
	Prompt from, "renumber selected waves from:"
	DoPrompt NMPromptStr( "Renumber Waves" ), from
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( df+"RenumFrom", from )
	
	vlist = NMCmdNum( from, vlist )
	vlist = NMCmdNum( 1, vlist )
	NMCmdHistory( "NMRenumWaves", vlist )
	
	return NMRenumWaves( from, 1 )

End // NMRenumWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMRenumWaves( from, alert )
	Variable from // start sequence number
	Variable alert // ( 0 ) no ( 1 ) yes
	
	Variable ccnt
	String cList, outList, allList = ""
	
	if ( ( from < 0 ) || ( numtype( from ) > 0 ) )
		DoAlert 0, "Abort NMRenumWaves : bad sequence number parameter."
		return ""
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		outList = RenumberWaves( from, cList )
		allList += outList
		
		NMMainHistory( "Renumbered waves from " + num2istr( from ), ccnt, outList, 0 )
	
	endfor
	
	ChanGraphsUpdate()
	
	if ( alert == 1 )
		DoAlert 0, "Alert: renumbered waves may no longer be recognized by NeuroMatic. Use wave prefix popup to select appropriate waves."
	endif
	
	return allList

End // NMRenumWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSmoothWavesCall()

	String vList = "", df = MainDF()
	
	String smthAlg = StrVarOrDefault( df+"SmoothAlg", "binomial" )
	Variable smthNum = NumVarOrDefault( df+"SmoothNum", 10 )
	
	Prompt smthAlg, "choose smoothing algorithm:", popup "binomial;boxcar;polynomial"
	Prompt smthNum, "number of smoothing points/operations:"
	
	DoPrompt NMPromptStr( "Smooth Waves" ), smthAlg, smthNum
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( df+"SmoothAlg", smthAlg )
	SetNMvar( df+"SmoothNum", smthNum )
	
	vList = NMCmdStr( smthAlg, vList )
	vList = NMCmdNum( smthNum, vList )
	NMCmdHistory( "NMSmoothWaves", vList )
	
	return NMSmoothWaves( smthAlg, smthNum )
	
End // NMSmoothWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSmoothWaves( smthAlg, avgN )
	String smthAlg // "binomial", "boxcar" or "polynomial"
	Variable avgN
	
	Variable ccnt
	String cList, wList = "", thisfxn = "NMSmoothWaves"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	strswitch( smthAlg )
		case "binomial":
		case "boxcar":
		case "polynomial":
			break
		default:
			return NMErrorStr( 20, thisfxn, "smthAlg", smthAlg )
	endswitch
	
	if ( ( numtype( avgN ) > 0 ) || ( avgN < 1 )  )
		return NMErrorStr( 10, thisfxn, "avgN", num2istr( avgN ) )
	endif
	
	if ( ( StringMatch( smthAlg, "polynomial" ) == 1 ) && ( ( avgN < 5 ) || ( avgN > 25 ) ) )
		return NMErrorStr( 90, thisfxn, "number of points must be greater than 5 and less than 25 for polynomial smoothing.", "" )
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = SmoothWaves( smthAlg, avgN, cList )
		wList += cList
		
		NMMainHistory( "Smoothed " + num2istr( avgN ) + " pnt(s) " + smthAlg, ccnt, cList, 0 )
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMSmoothWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMainTabDeltaxWithAlert( fxnName )
	String fxnName // function name for alert

	Variable dx = NMWaveSelectXstats( "deltax", -1 )
	
	if ( numtype( dx ) > 0 )
	
		DoAlert 1, fxnName + " Alert: currently selected waves have different sample rates. Do you want to continue?"
		
		if ( V_flag != 1 )
			return Nan
		endif
		
		dx = NMWaveSelectXstats( "minDeltax", -1 )
		
		if ( numtype( dx ) > 0 )
			dx = 1
		endif
		
	endif
	
	return dx

End // NMMainTabDeltaxWithAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFilterFIRWavesCall()

	Variable f1, f2, sfreq, upperLimit, lowerLimit
	String vList = "", df = MainDF()
	
	Variable dx = NMMainTabDeltaxWithAlert( "Filter FIR" )
	
	if ( numtype( dx ) > 0 )
		return "" // cancel
	endif
	
	Variable n = NumVarOrDefault( df+"FilterFIRn", 101 )
	
	String alg = StrVarOrDefault( df+"FilterFIRalg", "low-pass" )
	
	sfreq = 1 / dx // kHz
	upperLimit = 0.5 * sfreq
	lowerLimit = 0.0158 * sfreq
	
	Prompt alg, "choose filter algorithm:", popup "low-pass;high-pass;notch;"
	Prompt n, "number of filter coefficients to generate:"
	
	DoPrompt NMPromptStr( "Filter FIR" ), alg
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( df+"FilterFIRalg", alg )
	
	strswitch(alg )
	
		case "low-pass":
			f1 = floor( NumVarOrDefault( df+"FilterFIRf1", 0.4 ) * sfreq * 10000 ) / 10000
			f2 = floor( NumVarOrDefault( df+"FilterFIRf2", 0.5 ) * sfreq * 10000 ) / 10000
			Prompt f1, "end of pass band ( 0 < f1 < " + num2str(upperLimit ) + " kHz ):"
			Prompt f2, "start of reject band ( f1 < f2 < " + num2str(upperLimit ) + " kHz ):"
			DoPrompt NMPromptStr( "Low-pass filter" ), f1, f2, n
			break
			
		case "high-pass":
			f1 = floor( NumVarOrDefault( df+"FilterFIRf1", 0.1 ) * sfreq * 10000 ) / 10000
			f2 = floor( NumVarOrDefault( df+"FilterFIRf2", 0.2 ) * sfreq * 10000 ) / 10000
			Prompt f1, "end of reject band ( 0 < f1 < " + num2str(upperLimit ) + " kHz ):"
			Prompt f2, "start of pass band ( f1 < f2 < " + num2str(upperLimit ) + " kHz ):"
			DoPrompt NMPromptStr( "High-pass filter" ), f1, f2, n
			break
			
		case "notch":
			f1 = floor( NumVarOrDefault( df+"FilterFIRf1", 0.5 ) * sfreq * 10000 ) / 10000
			f2 = floor( NumVarOrDefault( df+"FilterFIRf2", 0.1 ) * sfreq * 10000 ) / 10000
			Prompt f1, "center frequency ( 0 < fc < " + num2str(upperLimit ) + " kHz ):"
			Prompt f2, "width frequency ( " + num2str(lowerLimit ) + " < fw < " + num2str(upperLimit ) + " kHz ):"
			DoPrompt NMPromptStr( "Notch filter" ), f1, f2
			break
			
	endswitch
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	f1 /= sfreq // convert back to fraction of sample frequency
	f2 /= sfreq
	
	SetNMvar( df+"FilterFIRf1", f1 )
	SetNMvar( df+"FilterFIRf2", f2 )
	SetNMvar( df+"FilterFIRn", n )
	
	vList = NMCmdStr( alg, vList )
	vList = NMCmdNum( f1, vList )
	vList = NMCmdNum( f2, vList )
	vList = NMCmdNum( n, vList )
	NMCmdHistory( "NMFilterFIRWaves", vList )
	
	return NMFilterFIRWaves( alg, f1, f2, n )
	
End // NMFilterFIRWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFilterFIRWaves( alg, f1, f2, n )
	String alg // "low-pass" or "high-pass" or "notch"
	Variable f1, f2, n // see FilterFIR
	
	Variable ccnt
	String cList, wList = "", history = ""
	String thisfxn = "NMFilterFIRWaves"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	strswitch( alg )
		case "low-pass":
			history = "Filter FIR (" + alg + ",f1=" + num2str( f1 ) + ",f2=" + num2str( f2 ) + ",n=" + num2str( n ) + ")"
			break
		case "high-pass":
			history = "Filter FIR (" + alg + ",f1=" + num2str( f1 ) + ",f2=" + num2str( f2 ) + ",n=" + num2str( n ) + ")"
			break
		case "notch":
			history = "Filter FIR (" + alg + ",fc=" + num2str( f1 ) + ",fw=" + num2str( f2 ) + ")"
			break
		default:
			return NMErrorStr( 20, thisfxn, "alg", alg )
	endswitch
	
	if ( ( numtype( f1 ) > 0 ) || ( f1 <= 0 ) || ( f1 > 0.5 ) )
		return NMErrorStr( 90, thisfxn, "f1 is out of range: " + num2str( f1 ), "" )
	endif
	
	if ( ( numtype( f2 ) > 0 ) || ( f2 <= 0 ) || ( f2 > 0.5 ) )
		return NMErrorStr( 90, thisfxn, "f2 is out of range: " + num2str( f2 ), "" )
	endif
	
	strswitch( alg )
	
		case "low-pass":
		case "high-pass":
		
			if ( f1 >= f2 )
				return NMErrorStr( 90, thisfxn, "filter f1 > f2", "" )
			endif
			
			if ( ( numtype( n ) > 0 ) || ( n <= 0 ) )
				return NMErrorStr( 10, thisfxn, "n", num2str( n ) )
			endif
			
			break
			
	endswitch
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = NMWaveSelectList( ccnt )
		
		if ( ItemsInList( cList ) == 0 )
			continue
		endif
		
		cList = FilterFIRwaves( alg, f1, f2, n, cList )
		wList += cList
		
		NMMainHistory( history , ccnt, cList, 0 )
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMFilterFIRWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFilterIIRWavesCall()

	Variable sfreq, freqLimit

	String vList = "", df = MainDF()
	
	Variable dx = NMMainTabDeltaxWithAlert( "Filter IIR" )
	
	if ( numtype( dx ) > 0 )
		return "" // cancel
	endif
	
	Variable freq = NumVarOrDefault( df+"FilterIIRfreq", 0.25 ) // fraction of sample rate (fHigh, fLo or fNotch )
	Variable notchQ = NumVarOrDefault( df+"FilterIIRnotchQ", 10 )
	
	String alg = StrVarOrDefault( df+"FilterIIRalg", "low-pass" )
	
	sfreq = 1 / dx // kHz
	freqLimit = 0.5 / dx
	
	freq = floor( freq * sfreq * 10000 ) / 10000 // convert to kHz
	
	Prompt alg, "choose filter algorithm:", popup "low-pass;high-pass;notch;"
	Prompt freq, "corner frequency ( 0 < f < " + num2str(freqLimit ) + " kHz ):"
	Prompt notchQ, "filter width Q factor ( width = f / Q ):"
	
	DoPrompt NMPromptStr( "Filter IIR" ), alg
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( df+"FilterIIRalg", alg )
	
	strswitch(alg )
		case "low-pass":
			DoPrompt NMPromptStr( "Low-pass Butterworth filter" ), freq
			break
		case "high-pass":
			DoPrompt NMPromptStr( "High-pass Butterworth filter" ), freq
			break
		case "notch":
			Prompt freq, "center frequency ( 0 < f < " + num2str(freqLimit ) + " kHz ):"
			DoPrompt NMPromptStr( "Notch filter" ), freq, notchQ
			break
	endswitch
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	freq /= sfreq // convert back to fraction of sample frequency
	
	SetNMvar( df+"FilterIIRfreq", freq )
	SetNMvar( df+"FilterIIRnotchQ", notchQ )
	
	vList = NMCmdStr( alg, vList )
	vList = NMCmdNum( freq, vList )
	vList = NMCmdNum( notchQ, vList )
	NMCmdHistory( "NMFilterIIRWaves", vList )
	
	return NMFilterIIRWaves( alg, freq, notchQ )
	
End // NMFilterIIRWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFilterIIRWaves( alg, freqFraction, notchQ )
	String alg // "low-pass" or "high-pass" or "notch"
	Variable freqFraction, notchQ // see Igor FilterIIR
	
	Variable ccnt
	String cList, wList = "", history = "", thisfxn = "NMFilterIIRWaves"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	strswitch( alg )
		case "low-pass":
			history = "Filter IIR (" + alg + ",freq=" + num2str( freqFraction ) + ")"
			break
		case "high-pass":
			history = "Filter IIR (" + alg + ",freq=" + num2str( freqFraction ) + ")"
			break
		case "notch":
			history = "Filter IIR (" + alg + ",freq=" + num2str( freqFraction ) + ",Q=" + num2str( notchQ ) + ")"
			break
		default:
			return NMErrorStr( 20, thisfxn, "alg", alg )
	endswitch
	
	if ( ( numtype( freqFraction ) != 0 ) || ( freqFraction <= 0 ) || ( freqFraction > 0.5 ) )
		return NMErrorStr( 10, thisfxn, "freqFraction", num2str( freqFraction ) )
	endif
	
	strswitch( alg )
	
		case "notch":
			
			if ( ( numtype( notchQ ) > 0 ) || ( notchQ <= 1 ) )
				return NMErrorStr( 10, thisfxn, "notchQ", num2str( notchQ ) )
			endif
			
			break
			
	endswitch
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = NMWaveSelectList( ccnt )
		
		if ( ItemsInList( cList ) == 0 )
			continue
		endif
		
		cList = FilterIIRwaves( alg, freqFraction, notchQ, cList )
		wList += cList
		
		NMMainHistory( history , ccnt, cList, 0 )
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMFilterIIRWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMResampleWavesCall()

	String rstr, vlist = "", df = MainDF()
	
	Variable dx = NMMainTabDeltaxWithAlert( "Resample" )
	
	if ( numtype( dx ) > 0 )
		return "" // user cancel
	endif
	
	String chanList = NMChanList( "CHAR" )
	String chanSelect = "All"
	String saveChanSelect = NMChanSelectStr()
	
	Variable upSamples = 1
	Variable downSamples = 1
	Variable oldrate = 1 / dx
	Variable rate = oldrate
	
	Prompt upSamples, "resample UP by x number of points: "
	Prompt downSamples, "resample DOWN by x number of points: "
	Prompt rate, "or specify a new sample rate ( kHz ): "
	
	if ( ItemsInList( chanList ) > 1 )
		Prompt chanSelect, "channel:", popup, "All;" + chanList
		DoPrompt NMPromptStr( "Resample Waves" ), chanSelect, upSamples, downSamples, rate
	else
		DoPrompt NMPromptStr( "Resample Waves" ), upSamples, downSamples, rate
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( ( upSamples > 1 ) || ( downSamples > 1 ) )
		rate = Nan
	elseif ( rate == oldrate )
		return ""
	endif
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( chanSelect )
	endif
	
	vList = NMCmdNum( rate, vList )
	vList = NMCmdNum( upSamples, vList )
	vList = NMCmdNum( downSamples, vList )
	NMCmdHistory( "NMResampleWaves", vList )
	
	rstr = NMResampleWaves( upSamples, downSamples, rate )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	return rstr

End // NMResampleWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMResampleWaves( upSamples, downSamples, rate )
	Variable upSamples // interpolate points, enter 1 for no change
	Variable downSamples // decimate points, enter 1 for no change
	Variable rate // kHz
	
	Variable ccnt, rateflag
	String cList, wList = ""
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( ( numtype( rate ) == 0 ) && ( rate > 0 ) )
	
		rateflag = 1
		upSamples = 1 // do nothing
		downSamples = 1 // do nothing
		
	else
	
		if ( ( numtype( upSamples ) > 0 ) || ( upSamples < 1 ) )
			upSamples = 1
		endif
		
		if ( ( numtype( downSamples ) > 0 ) || ( downSamples < 1 ) )
			downSamples = 1
		endif
		
		if ( ( upSamples == 1 ) && ( downSamples == 1 ) )
			return "" // nothing to do
		endif
	
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = ResampleWaves( upSamples, downSamples, rate, cList )
		wList += cList
		
		if ( rateflag == 1 )
			NMMainHistory( "Resampled " + num2str( rate ) + " kHz", ccnt, cList, 0 )
		else
			NMMainHistory( "Resampled " + num2istr( upSamples ) + " upSamples, " + num2istr( downSamples ) + " downSamples", ccnt, cList, 0 )
		endif
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMResampleWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDecimateWavesCall()

	String rstr, df = MainDF()
	
	Variable dx = NMMainTabDeltaxWithAlert( "Decimate" )
	
	if ( numtype( dx ) > 0 )
		return "" // cancel
	endif
	
	Variable ipnts = NumVarOrDefault( df+"DecimateN", 4 )
	
	String chanList = NMChanList( "CHAR" )
	String chanSelect = "All"
	String saveChanSelect = NMChanSelectStr()
	
	Prompt ipnts, "decimate waves by x number of points: "
	
	if ( ItemsInList( chanList ) > 1 )
		Prompt chanSelect, "channel:", popup, "All;" + chanList
		DoPrompt NMPromptStr( "Decimate Waves" ), chanSelect, ipnts
	else
		DoPrompt NMPromptStr( "Decimate Waves" ), ipnts
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( df+"DecimateN", ipnts )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( chanSelect )
	endif
	
	NMCmdHistory( "NMDecimateWaves", NMCmdNum( ipnts,"" ) )
	
	rstr = NMDecimateWaves( ipnts )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	return rstr

End // NMDecimateWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDecimateWaves( ipnts )
	Variable ipnts // number of points
	
	Variable ccnt
	String cList, wList = "", thisfxn = "NMDecimateWaves"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( ( numtype( ipnts ) > 0 ) || ( ipnts < 0 ) )
		return NMErrorStr( 10, thisfxn, "ipnts", num2istr( ipnts ) )
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = DecimateWaves( ipnts, cList )
		wList += cList
		
		NMMainHistory( "Decimated " + num2istr( ipnts ) + " pnts", ccnt, cList, 0 )
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMDecimateWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDecimate2DeltaXCall()
	
	Variable newDeltaX
	String rstr, df = MainDF() 
	
	Variable oldDeltax = NMMainTabDeltaxWithAlert( "Decimate Waves" )
	
	if ( numtype( oldDeltax ) > 0 )
		return "" // user cancel
	endif
	
	newDeltaX = NumVarOrDefault( df+"DecimateDeltaX", oldDeltax )
	
	String chanList = NMChanList( "CHAR" )
	String chanSelect = "All"
	String saveChanSelect = NMChanSelectStr()
	
	Prompt newDeltaX, "new sample interval < " + num2str( oldDeltax ) + " : "
	
	if ( ItemsInList( chanList ) > 1 )
		Prompt chanSelect, "channel:", popup, "All;" + chanList
		DoPrompt NMPromptStr( "Decimate Waves" ), chanSelect, newDeltaX
	else
		DoPrompt NMPromptStr( "Decimate Waves" ), newDeltaX
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( df+"DecimateDeltaX", newDeltaX )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( chanSelect )
	endif
	
	NMCmdHistory( "NMDecimate2DeltaX", NMCmdNum( newDeltaX,"" ) )
	
	rstr = NMDecimate2DeltaX( newDeltaX )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	return rstr

End // NMDecimate2DeltaXCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDecimate2DeltaX( newDeltaX )
	Variable newDeltaX // new deltax
	
	Variable ccnt
	String cList, wList = "", thisfxn = "NMDecimate2DeltaX"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( ( numtype( newDeltaX ) > 0 ) || ( newDeltaX <= 0 )  )
		return NMErrorStr( 10, thisfxn, "newDeltaX", num2str( newDeltaX ) )
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = Decimate2DeltaX( newDeltaX, cList )
		wList += cList
		
		NMMainHistory( "Decimated to " + num2str( newDeltaX ) + " sample interval", ccnt, cList, 0 )
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMDecimate2DeltaX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMInterpolateWavesCall()

	Variable npnts
	String optionsStr, rstr, wList = "", vList = "", df = MainDF()
	
	Variable alg = NumVarOrDefault( df+"InterpAlg", 1 )
	Variable xmode = NumVarOrDefault( df+"InterpXMode", 1 )
	String xWave = StrVarOrDefault( df+"InterpXWave", "" )
	
	String chanList = NMChanList( "CHAR" )
	String chanSelect = "All"
	String saveChanSelect = NMChanSelectStr()
	
	Prompt alg, "interpolation method: ", popup "linear;cubic spline;"
	Prompt xmode, "choose x-axis for interpolation:" popup "use common x-axis computed by NeuroMatic;use x-axis of a selected wave;use data values of a selected wave;"
	
	if ( ItemsInList( chanList ) > 1 )
		Prompt chanSelect, "channel:", popup, "All;" + chanList
		DoPrompt NMPromptStr( "Interpolate to new x-axis" ), chanSelect, alg, xmode
	else
		DoPrompt NMPromptStr( "Interpolate to new x-axis" ), alg, xmode
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	switch( xmode )
	
		case 2:
		
			Prompt xWave, "select wave to supply x-axis for interpolation: ", popup WaveList( "*", ";", "" )
			
		case 3:
		
			npnts = NMWaveSelectXstats( "numpnts", -1 )
			optionsStr = NMWaveListOptions( npnts, 0 )
			
			if ( ( numtype( npnts ) == 0 ) && ( npnts > 0 ) )
				wList = " ;" + WaveList( "*", ";", optionsStr )
			endif
			
			Prompt xWave, "select wave to supply data values for interpolation: ", popup wList
			DoPrompt NMPromptStr( "Interpolate" ), xWave
			
			if ( strlen( xWave ) == 0 )
				return ""
			endif
			
	endswitch
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( df+"InterpAlg", alg )
	SetNMvar( df+"InterpXMode", xmode )
	SetNMstr( df+"InterpXWave", xWave )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( chanSelect )
	endif
	
	vList = NMCmdNum( alg, vList )
	vList = NMCmdNum( xmode, vList )
	vList = NMCmdStr( xWave, vList )
	NMCmdHistory( "NMInterpolateWaves", vList )
	
	rstr = NMInterpolateWaves( alg, xmode, xWave )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	return rstr

End // NMInterpolateWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMInterpolateWaves( alg, xmode, xWave )
	Variable alg // ( 1 ) linear ( 2 ) cubic spline
	Variable xmode // ( 1 ) find common x-axis ( 2 ) use x-axis scale of xWave ( 3 ) use values of xWave as x-scale
	String xWave // wave for xmode 2 or 3
	
	// Warning: interpolation will change the noise characteristics of your data.
	
	Variable ccnt
	String cList, wList = "", thisfxn = "NMInterpolateWaves"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	switch( alg )
		case 1:
		case 2:
			break
		default:
			return NMErrorStr( 10, thisfxn, "alg", num2istr( alg ) )
	endswitch
	
	switch( xmode )
	
		case 1:
			break
			
		case 2:
		case 3:
			
			if ( NMUtilityWaveTest( xWave ) < 0 )
				return NMErrorStr( 1, thisfxn, "xWave", xWave )
			endif
			
			break
		
		default:
			return NMErrorStr( 10, thisfxn, "xmode", num2istr( xmode ) )
			
	endswitch
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
			
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif

		cList = InterpolateWaves( alg, xmode, xWave, cList )
		wList += cList

		switch( xmode )
			case 1:
				NMMainHistory( "Interpolated to common x-axis", ccnt, cList, 0 )
				break
			case 2:
				NMMainHistory( "Interpolated to x-scale of " + xWave, ccnt, cList, 0 )
				break
			case 3:
				NMMainHistory( "Interpolated to data values of " + xWave, ccnt, cList, 0 )
				break
		endswitch
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMInterpolateWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPlotCall( color )
	String color
	
	String gName, vList = "", df = MainDF()
	
	String selectList = NMWaveSelectAllList()
	String waveSelect = NMWaveSelectGet()
	
	Variable onePlotPerChannel = NumVarOrDefault( df+"PlotOnePerChannel", 1 )
	Variable reverseOrder = NumVarOrDefault( df+"PlotReverseOrder", 0 )
	Variable xOffset = NumVarOrDefault( df+"PlotXoffset", 0 )
	Variable yOffset = NumVarOrDefault( df+"PlotYoffset", 0 )
	
	Prompt color, "choose wave color:", popup "rainbow;black;red;green;blue;purple;yellow;"
	Prompt onePlotPerChannel, "plot " + NMQuotes( waveSelect ) + " in the same graph?", popup "no;yes;"
	Prompt reverseOrder, "reverse order of waves?", popup "no;yes;"
	Prompt xOffset, "x-offset increment:"
	Prompt yOffset, "y-offset increment:"
	
	if ( ItemsInList( selectList ) > 1 )
	
		if ( strlen( color ) == 0 )
			color = NMMainStr( "PlotColor" )
		endif
		
		onePlotPerChannel += 1
		reverseOrder += 1
	
		DoPrompt "Plot " + waveSelect, color, onePlotPerChannel, reverseOrder, xOffset, yOffset
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
		onePlotPerChannel -= 1
		reverseOrder -= 1
		
		SetNMstr( df+"PlotColor", color )
		SetNMvar( df+"PlotOnePerChannel", onePlotPerChannel )
		SetNMvar( df+"PlotReverseOrder", reverseOrder )
		SetNMvar( df+"PlotXoffset", xOffset )
		SetNMvar( df+"PlotYoffset", yOffset )
		
	else
	
		if ( strlen( color ) == 0 )
		
			color = NMMainStr( "PlotColor" )
	
			onePlotPerChannel = 1
			reverseOrder += 1
		
			DoPrompt "Plot Waves", color, reverseOrder, xOffset, yOffset
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			reverseOrder -= 1
			
			SetNMstr( df+"PlotColor", color )
			SetNMvar( df+"PlotReverseOrder", reverseOrder )
			SetNMvar( df+"PlotXoffset", xOffset )
			SetNMvar( df+"PlotYoffset", yOffset )
		
		else
		
			xOffset = 0
			yOffset = 0
		
		endif
		
	endif
	
	vList = NMCmdStr( color, vList )
	vList = NMCmdNum( onePlotPerChannel, vList )
	vList = NMCmdNum( reverseOrder, vList )
	vList = NMCmdNum( xOffset, vList )
	vList = NMCmdNum( yOffset, vList )
		
	NMCmdHistory( "NMMainPlotWaves", vList )
	
	return NMMainPlotWaves( color, onePlotPerChannel, reverseOrder, xoffset, yoffset )

End // NMPlotCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainPlotWaves( color, onePlotPerChannel, reverseOrder, xoffset, yoffset )
	String color // "rainbow", "black", "red", "green", "blue", "yellow", "purple" or ( "" ) for default
	Variable onePlotPerChannel // ( 0 ) no ( 1 ) yes ( used only if "All Sets" or "All Groups" is selected )
	Variable reverseOrder // ( 0 ) no (1 ) yes
	Variable xoffset // ( 0 ) for no offset
	Variable yoffset // ( 0 ) for no offset
	
	Variable ccnt, icnt, error, r, g, b
	String xl, yl, gPrefix, gName, gTitle, gList = "", colorList = ""
	String cList, df = MainDF()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	Variable numChannels = NMNumChannels()
	Variable currentWave = CurrentNMWave()
	
	String xWave = NMXwave()
	
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	String allList = NMWaveSelectAllList()
	Variable allListItems = ItemsInList( allList )
	
	if ( strlen( color ) > 0 )
		SetNMstr( df+"PlotColor", color )
	endif
	
	allListItems = max( ItemsInList( allList ), 1 )
	
	if ( ( onePlotPerChannel == 1 ) && ( allListItems > 1 ) )
	
		if ( StringMatch( color, "rainbow" ) == 1 )
			colorList = "red;blue;green;purple;black;yellow;red;blue;green;purple;black;yellow;"
		endif
		
		if ( reverseOrder == 1 )
			allList = NMReverseList( allList, ";" )
		endif
	
	endif
	
	if ( strlen( color ) == 0 )
		color = NMMainStr( "PlotColor" )
	endif
	
	if ( strlen( color ) == 0 )
		color = "black"
	endif
	
	if ( numtype( xoffset ) > 0 )
		xoffset = 0
	endif
	
	if ( numtype( yoffset ) > 0 )
		yoffset = 0
	endif
	
	gPrefix = MainPrefix( "" ) + NMFolderPrefix( "" ) + NMWaveSelectStr() + "_Plot_"
	
	for ( icnt = 0; icnt < max( allListItems, 1 ) ; icnt += 1 )
	
		if ( allListItems > 0 )
		
			waveSelect = StringFromList( icnt, allList )
			NMWaveSelect( waveSelect )
			
			if ( onePlotPerChannel == 0 )
				gPrefix = MainPrefix( "" ) + NMFolderPrefix( "" ) + NMWaveSelectStr() + "_Plot_"
			endif
			
			if ( ItemsInLIst( colorList ) > 0 )
			
				color = StringFromList( icnt, colorList )
				
				if ( strlen( color ) == 0 )
					color = "black"
				endif
				
			endif
			
		endif

		for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue // channel not selected
			endif

			gName = NextGraphName( gPrefix, ccnt, NeuroMaticVar( "OverWrite" ) )
			
			if ( StringMatch( waveSelect, "This Wave" ) == 1 )
				gTitle = NMFolderListName( "" ) + " : " + NMChanWaveName( ccnt, currentWave )
			elseif ( onePlotPerChannel == 1 )
				gTitle = NMFolderListName( "" ) + " : " + CurrentNMWavePrefix() + " : Ch " + ChanNum2Char( ccnt ) + " : " + saveWaveSelect
			else
				gTitle = NMFolderListName( "" ) + " : " + CurrentNMWavePrefix() + " : Ch " + ChanNum2Char( ccnt ) + " : " + waveSelect
			endif
	
			cList = NMWaveSelectList( ccnt )
			
			if ( reverseOrder == 1 )
				cList = NMReverseList( cList, ";" )
			endif
			
			xl = NMChanLabel( ccnt, "x", cList )
			yl = NMChanLabel( ccnt, "y", cList )
			
			if ( ( icnt == 0 ) || ( onePlotPerChannel == 0 ) || ( WinType( gName ) == 0 ) )
			
				error = NMPlotWavesOffset( gName, gTitle, xl, yl, xWave, cList, xoffset, 1, yoffset, 1 )
				
				if ( error == 0 )
			
					gList = AddListItem( gName, gList, ";", inf )
					
					if ( StringMatch( color, "rainbow" ) == 1 )
					
						GraphRainbow( gName, "_All_" )
						
					else
					
						r = NMPlotRGB( color, "r" )
						g = NMPlotRGB( color, "g" )
						b = NMPlotRGB( color, "b" )
						
						ModifyGraph /W=$gName rgb=( r,g,b )
						
					endif
					
				endif
				
			elseif ( WinType( gName ) == 1 )
				
				NMPlotAppend( gName, color, xWave, cList, xoffset*icnt, 0, yoffset*icnt, 0 )
				
			endif
			
		endfor
	
	endfor
	
	if ( allListItems > 0 )
		NMWaveSelect( saveWaveSelect )
	endif
	
	return gList

End // NMMainPlotWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEditWavesCall()
	
	NMCmdHistory( "NMEditWaves", "" )
	
	return NMEditWaves()

End // NMEditWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEditWaves()

	Variable ccnt, icnt, error
	String tPrefix, tName, tTitle, cList, tList = ""
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	String allList = NMWaveSelectAllList()
	Variable allListItems = ItemsInList( allList )
	
	for ( icnt = 0; icnt < max( allListItems, 1 ) ; icnt += 1 )
		
		if ( allListItems > 0 )
			waveSelect = StringFromList( icnt, allList )
			NMWaveSelect( waveSelect )
		endif
	
		for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue // channel not selected
			endif
				
			tPrefix = MainPrefix( "" ) + "_Table_" + NMFolderPrefix( "" ) + NMWaveSelectStr() 
			tName = NextGraphName( tPrefix, ccnt, NeuroMaticVar( "OverWrite" ) )
			tTitle = NMFolderListName( "" ) + " : Ch " + ChanNum2Char( ccnt ) + " : " + CurrentNMWavePrefix() + " : " + waveSelect
			
			cList = NMWaveSelectList( ccnt )
	
			error = EditWaves( tName, tTitle, cList )
			
			if ( error == 0 )
				if ( ItemsInList( tList ) == 0 )
					tList = tName
				else
					tList = AddListItem( tName, tList, ";", inf )
				endif
			endif
		
		endfor
	
	endfor
	
	if ( allListItems > 0 )
		NMWaveSelect( saveWaveSelect )
	endif
	
	return tList

End // NMEditWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReverseWavesCall()

	DoAlert 1, "Reverse points of selected waves?"
	
	if ( V_flag != 1 )
		return ""
	endif

	NMCmdHistory( "NMReverseWaves", "" )
	
	return NMReverseWaves()

End // NMReverseWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMReverseWaves()

	Variable ccnt, wcnt
	String cList, wName, wList = ""
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		for ( wcnt = 0; wcnt < ItemsInList( cList ); wcnt += 1 )
		
			wName = StringFromList( wcnt, cList )
			
			if ( WaveExists( $wName ) == 1 )
				WaveTransform /O flip $wName
				wList = AddListItem( wName, wList, ";", inf )
			endif
			
		endfor
		
		NMMainHistory( "Reversed", ccnt, cList, 0 )
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMReverseWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSortWavesByKeyWaveCall()

	String df = MainDF(), keyWaveName = StrVarOrDefault( df+"SortKeyWaveName", "" )
	String optionsStr, wList = ""
	
	Variable npnts = NMWaveSelectXstats( "numpnts", -1 )
	
	if ( numtype( npnts ) == 0 )
		optionsStr = NMWaveListOptions( npnts, 0 )
		wList = " ;" + WaveList( "*", ";", optionsStr )
	endif
	
	Prompt keyWaveName, "choose a wave of key values to sort selected wave( s ) against:", popup wList
	DoPrompt NMPromptStr( "Sort Waves" ), keyWaveName
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( df+"SortKeyWaveName", keyWaveName )
	
	NMCmdHistory( "NMSortWavesByKeyWave", NMCmdStr( keyWaveName, "" ) )

	return NMSortWavesByKeyWave( keyWaveName )

End // NMSortWavesByKeyWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSortWavesByKeyWave( keyWaveName )
	String keyWaveName // name of wave that
	
	Variable ccnt
	String cList, wList = "", thisfxn = "NMSortWavesByKeyWave"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( WaveExists( $keyWaveName ) == 0 )
		return NMErrorStr( 1, thisfxn, "keyWaveName", keyWaveName )
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = SortWavesByKeyWave( keyWaveName, cList )
		wList += cList
		
		NMMainHistory( "Sorted", ccnt, cList, 0 )
	
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMSortWavesByKeyWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAlignWavesCall()

	Variable error
	String optionsStr, wList, vList = "", df = MainDF()
	
	String wname = StrVarOrDefault( df+"AlignWName", "" )
	Variable positiveTimeOnly = NumVarOrDefault( df+"AlignPosTime", 1 )
	Variable intrp = NumVarOrDefault( df+"AlignInterp", 0 )
	Variable atTimeZero = BinaryInvert( positiveTimeOnly )
	
	optionsStr = NMWaveListOptions( NMNumWaves(), 0 )
	
	wList = WaveList( "*", ";", optionsStr )
	wList = AddListItem( " ", wList, ";", -inf ) // add space to beginning

	atTimeZero += 1
	intrp += 1
	
	Prompt wname, "choose a wave of alignment values:", popup wList
	Prompt atTimeZero, "align at:", popup "maximum alignment value;time zero"
	Prompt intrp, "make alignments permanent by interpolation?", popup "no;yes"
	//DoPrompt NMPromptStr( "Time Scale Alignment" ), wname, atTimeZero, intrp
	DoPrompt NMPromptStr( "Time Scale Alignment" ), wname, atTimeZero
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	atTimeZero -= 1
	intrp -= 1
	positiveTimeOnly = BinaryInvert( atTimeZero )
	
	SetNMstr( df+"AlignWName", wname )
	SetNMvar( df+"AlignPosTime", positiveTimeOnly )
	SetNMvar( df+"AlignInterp", intrp )

	vList = NMCmdStr( wname, vList )
	vList = NMCmdNum( positiveTimeOnly, vList )
	NMCmdHistory( "NMAlignWaves", vList )
	
	wList = NMAlignWaves( wname, positiveTimeOnly )
	
	if ( intrp == 1 )
	
		vList = NMCmdNum( 1, "" )
		vList = NMCmdNum( 1, vList )
		vList = NMCmdStr( "", vList )
		
		NMCmdHistory( "NMInterpolateWaves", vList )
		
		NMInterpolateWaves( 1, 1, "" )
		
	endif
	
	return wList

End // NMAlignWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAlignWaves( waveOfAlignments, positiveTimeOnly )
	String waveOfAlignments // wave of x-align values
	Variable positiveTimeOnly // allow only positive time values? ( 0 ) no, align at time zero ( 1 ) yes, align at maximum alignment value
	
	Variable ccnt, wcnt, error, setZeroAt, maxoffset, dx
	String wName, cList = "", wList = "", badList = ""
	String thisfxn = "NMAlignWaves"
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( NMUtilityWaveTest( waveOfAlignments ) < 0 )
		return NMErrorStr( 1, thisfxn, "waveOfAlignments", waveOfAlignments )
	endif
		
	Wave offsetWave = $waveOfAlignments
		
	if ( positiveTimeOnly == 1 )
		WaveStats /Q/Z offsetWave
		maxoffset = V_max
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
		
			wName = NMWaveSelected( ccnt, wcnt )
			
			if ( strlen( wName ) == 0 )
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			setZeroAt = offsetWave[wcnt]
				
			if ( positiveTimeOnly == 1 )
				setZeroAt -= maxoffset
			endif
			
			dx = deltax( $wName )
	
			Setscale /P x -setZeroAt, dx, $wName
			
			cList = AddListItem( wName, cList, ";", inf )
		
		endfor
		
		wList += cList
			
		if ( positiveTimeOnly == 1 )
			NMMainHistory( "X-Aligned at " + num2str( maxoffset ) + " ms ( offset wave:" + waveOfAlignments + " )", ccnt, cList, 0 )
		else
			NMMainHistory( "X-Aligned at 0 ms ( offset wave:" + waveOfAlignments + " )", ccnt, cList, 0 )
		endif
		
	endfor
	
	ChanGraphsUpdate()
	
	if ( ItemsInlist( badList ) > 0 )
		NMDoAlert( "Warning: x-alignment not performed on the following waves due to bad input values : " + badList )
	endif
	
	return wList

End // NMAlignWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStartXCall()

	String rstr, df = MainDF()
	Variable startx = NumVarOrDefault( df+"StartX", 0 )
	
	String chanList = NMChanList( "CHAR" )
	String chanSelect = "All"
	String saveChanSelect = NMChanSelectStr()
	
	Prompt startx, "time begin (ms):"
	
	if ( ItemsInList( chanList ) > 1 )
		Prompt chanSelect, "channel:", popup, "All;" + chanList
		DoPrompt NMPromptStr( "Wave Start Time" ), chanSelect, startx
	else
		DoPrompt NMPromptStr( "Wave Start Time" ), startx
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( df+"StartX", startx )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( chanSelect )
	endif
	
	NMCmdHistory( "NMStartX", NMCmdNum( startx, "" ) )
	
	rstr = NMStartX( startx )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	return rstr
	
End // NMStartXCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStartX( startx )
	Variable startx // time begin
	
	if ( numtype( startx ) > 0 )
		return NMErrorStr( 10, "NMStartX", "startx", num2str( startx ) )
	endif
	
	return NMXScaleWaves( startx, Nan, Nan )
	
End // NMStartX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeltaXCall()

	String rstr
	String wList = NMWaveSelectList( -1 )

	Variable dx = NMMainTabDeltaxWithAlert( "Time Scale" )
	
	if ( numtype( dx ) > 0 )
		return "" // user cancel
	endif
	
	String chanList = NMChanList( "CHAR" )
	String chanSelect = "All"
	String saveChanSelect = NMChanSelectStr()
	
	Prompt dx, "time step (ms):"
	
	if ( ItemsInList( chanList ) > 1 )
		Prompt chanSelect, "channel:", popup, "All;" + chanList
		DoPrompt NMPromptStr( "Set Time Sample Interval" ), chanSelect, dx
	else
		DoPrompt NMPromptStr( "Set Time Sample Interval" ), dx
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( chanSelect )
	endif
	
	NMCmdHistory( "NMDeltaX", NMCmdNum( dx, "" ) )
	
	rstr = NMDeltaX( dx )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	return rstr
	
End // NMDeltaXCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDeltaX( dx )
	Variable dx // time step
	
	if ( ( numtype( dx ) > 0 ) || ( dx <= 0 ) )
		return NMErrorStr( 10, "NMDeltaX", "dx", num2str( dx ) )
	endif
	
	return NMXScaleWaves( Nan, dx, Nan )
	
End // NMDeltaX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNumPntsCall()
	
	Variable npnts = GetXstats( "minNumPnts" , NMWaveSelectList( -1 ) )
	String rstr
	
	if ( npnts <= 0 )
		npnts = 100
	endif
	
	String chanList = NMChanList( "CHAR" )
	String chanSelect = "All"
	String saveChanSelect = NMChanSelectStr()
	
	Prompt npnts, "wave points:"
	
	if ( ItemsInList( chanList ) > 1 )
		Prompt chanSelect, "channel:", popup, "All;" + chanList
		DoPrompt NMPromptStr( "Set Number of Points" ), chanSelect, npnts
	else
		DoPrompt NMPromptStr( "Set Number of Points" ), npnts
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( chanSelect )
	endif
	
	NMCmdHistory( "NMNumPnts", NMCmdNum( npnts, "" ) )
	
	rstr = NMNumPnts( npnts )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	return rstr
	
End // NMNumPntsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNumPnts( npnts )
	Variable npnts // number of points
	
	if ( ( numtype( npnts ) > 0 ) || ( npnts <= 0 ) )
		return NMErrorStr( 10, "NMNumPnts", "npnts", num2istr( npnts ) )
	endif
	
	return NMXScaleWaves( Nan, Nan, npnts )
	
End // NMNumPnts

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXScaleWaves( startx, dx, npnts )
	Variable startx // time begin, pass ( Nan ) to not change
	Variable dx // time step, pass ( Nan ) to not change
	Variable npnts // number of points, pass ( Nan ) to not change

	Variable ccnt, somethingtodo
	String paramstr = "", cList, wList = ""
	String thisfxn = "NMXScaleWaves"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( numtype( startx ) == 0 )
		paramstr += "t0=" + num2str( startx )
		somethingtodo = 1
	else
		startx = Nan
	endif
	
	if ( ( numtype( dx ) == 0 ) && ( dx > 0 ) )
	
		if ( strlen( paramstr ) > 0 )
			paramstr += ", "
		endif
		
		paramstr += "dt=" + num2str( dx ) + " ms"
		
		somethingtodo = 1
		
	else
		
		dx = Nan
		
	endif
	
	if ( ( numtype( npnts ) == 0 ) && ( npnts > 0 ) )
	
		if ( strlen( paramstr ) > 0 )
			paramstr += ", "
		endif
		
		paramstr += "npnts=" + num2istr( npnts )
		
		somethingtodo = 1
		
	else
	
		npnts = Nan
		
	endif
	
	if ( somethingtodo == 0 )
		return ""
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
	
		cList = SetXScale( startx, dx, npnts, cList )
		wList += cList
	
		NMMainHistory( "X-scale ( " + paramstr + " )", ccnt, cList, 0 )
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMXScaleWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXLabelCall()

	String rstr, vList = ""
	
	String xLabel = NMChanLabel( -1, "x", "" )
	
	String chanList = NMChanList( "CHAR" )
	String chanSelect = "All"
	String saveChanSelect = NMChanSelectStr()
	
	if ( strlen( xLabel ) == 0 )
		xLabel = "msec"
	endif
	
	Prompt xLabel, "label:"
	
	if ( ItemsInList( chanList ) > 1 )
		Prompt chanSelect, "channel:", popup, "All;" + chanList
		DoPrompt "Set X-axis Label", chanSelect, xLabel
	else
		DoPrompt "Set X-axis Label", xLabel
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( chanSelect )
	endif
	
	vList = NMCmdStr( "x", vList )
	vList = NMCmdStr( xLabel, vList )
	NMCmdHistory( "NMLabel", vList )
	
	rstr = NMLabel( "x", xLabel )
	
	if ( StringMatch( chanSelect, saveChanSelect ) == 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	return rstr
	
End // NMXLabelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMYLabelCall()

	String vList = ""
	String yLabel = NMChanLabel( -1, "y", "" )
	
	Prompt yLabel, "label:"
	DoPrompt "Set Y-Axis Label", yLabel
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	vList = NMCmdStr( "y", vList )
	vList = NMCmdStr( yLabel, vList )
	
	NMCmdHistory( "NMLabel", vList )
	
	return NMLabel( "y", yLabel )
	
End // NMYLabelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLabel( xy, labelStr )
	String xy // "x" or "y"
	String labelStr
	
	Variable ccnt
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	strswitch( xy )
		case "x":
		case "y":
			break
		default:
			return NMErrorStr( 20, "NMLabel", "xy", xy )
	endswitch
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		NMChanLabelSet( ccnt, 1, xy, labelStr )
		
	endfor
	
	ChanGraphsUpdate()
	
	return labelStr
	
End // NMLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMYUnitsChangeCall()
	
	Variable scale, scale2
	Variable chan = CurrentNMChannel()
	
	String oldunits = GetWaveUnits( "y", CurrentNMWaveName(), "" )
	String newUnits = oldUnits, ulist = "", vlist = ""
	
	strswitch( oldunits )
	
		case "A":
		case "Amps":
			scale = 1
			ulist = "A;mA;uA;nA;pA;"
			break
		case "mA":
		case "mAmps":
		case "milliAmps":
			scale = 1e-3
			ulist = "A;mA;uA;nA;pA;"
			break
		case "uA":
		case "uAmps":
		case "microAmps":
			scale = 1e-6
			ulist = "A;mA;uA;nA;pA;"
			break
		case "nA":
		case "nAmps":
		case "nanoAmps":
			scale = 1e-9
			ulist = "A;mA;uA;nA;pA;"
			break
		case "pA":
		case "pAmps":
		case "picoAmps":
			scale = 1e-12
			ulist = "A;mA;uA;nA;pA;"
			break
		
		case "V":
		case "Volts":
			scale = 1
			ulist = "V;mV;uV;nV;pV;"
			break
		case "mV":
		case "mVolts":
		case "milliVolts":
			scale = 1e-3
			ulist = "V;mV;uV;nV;pV;"
			break
		case "uV":
		case "uVolts":
		case "microVolts":
			scale = 1e-6
			ulist = "V;mV;uV;nV;pV;"
			break
		case "nV":
		case "nVolts":
		case "nanoVolts":
			scale = 1e-9
			ulist = "V;mV;uV;nV;pV;"
			break
		case "pV":
		case "pVolts":
		case "picoVolts":
			scale = 1e-12
			ulist = "V;mV;uV;nV;pV;"
			break
			
		case "S":
		case "Siemens":
			scale = 1
			ulist = "S;mS;uS;nS;pS;"
			break
		case "mS":
		case "mSiemens":
		case "milliSiemens":
			scale = 1e-3
			ulist = "S;mS;uS;nS;pS;"
			break
		case "uS":
		case "uSiemens":
		case "microSiemens":
			scale = 1e-6
			ulist = "S;mS;uS;nS;pS;"
			break
		case "nS":
		case "nSiemens":
		case "nanoSiemens":
			scale = 1e-9
			ulist = "S;mS;uS;nS;pS;"
			break
		case "pS":
		case "pSiemens":
		case "picoSiemens":
			scale = 1e-12
			ulist = "S;mS;uS;nS;pS;"
			break
			
		default:
			NMDoAlert( "Abort NMYUnitsChange: cannot locate current wave y-units." )
			return ""
			
	endswitch
	
	Prompt newUnits, "new units:", popup ulist
	DoPrompt "Change Wave Y-units", newUnits
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	switch( WhichListItem( newUnits, ulist ) )
		case 0:
			scale2 = 1
			break
		case 1:
			scale2 = 1e-3
			break
		case 2:
			scale2 = 1e-6
			break
		case 3:
			scale2 = 1e-9
			break
		case 4:
			scale2 = 1e-12
			break
		default:
			return ""
	endswitch
	
	scale /= scale2
	
	vlist = NMCmdNum( chan, vlist )
	vlist = NMCmdStr( oldUnits, vlist )
	vlist = NMCmdStr( newUnits, vlist )
	vlist = NMCmdNum( scale, vlist )
	
	NMCmdHistory( "NMYUnitsChange", vlist )
	
	return NMYUnitsChange( chan, oldUnits, newUnits, scale )

End // NMYUnitsChangeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMYUnitsChange( chanNum, oldUnits, newUnits, scaleNum )
	Variable chanNum
	String oldUnits, newUnits
	Variable scaleNum
	
	Variable wcnt, lftx, dx
	String wname, saveNote, cList = ""
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( ( numtype( scaleNum ) > 0 ) || ( scaleNum == 1 ) )
		return ""
	endif
		
	for ( wcnt = 0; wcnt < NMNumWaves(); wcnt += 1 ) // loop thru waves
	
		wName = NMWaveSelected( chanNum, wcnt )
		
		if ( strlen( wName ) == 0 )
			continue // wave not selected, or does not exist... go to next wave
		endif
		
		if ( StringMatch( oldUnits, GetWaveUnits( "y", wName, "" ) ) == 0 )
			continue // not of correct dimension
		endif
		
		Wave wtemp = $wname
		
		lftx = leftx( wtemp )
		dx = deltax( wtemp )
		saveNote = note( wtemp )
		
		MatrixOp /O wtemp = wtemp * scaleNum
		Setscale /P x lftx, dx, wtemp
		Note wtemp, saveNote
	
		NMNoteStrReplace( wName, "yLabel", newUnits )
		
		cList = AddListItem( wName, cList, ";", inf )
	
	endfor
	
	NMMainHistory( "Rescaled to " + newUnits, chanNum, cList, 0 )
	
	ChanGraphsUpdate()
	
	return newUnits
	
End // NMYUnitsChange

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXUnitsChangeCall( newUnits )
	String newUnits
	
	Variable ccnt, wcnt
	String wName, units, oldUnits = ""
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
			
			wName = NMChanWaveName( ccnt, wcnt )
			
			if ( ( strlen( wName ) == 0 ) || ( WaveExists( $wName ) == 0 ) )
				continue
			endif
			
			units = GetWaveUnits( "x", wName, "" )
		
			strswitch( units )
			
				case "s":
				case "sec":
				case "seconds":
				case "ms":
				case "msec":
				case "milliseconds":
				case "us":
				case "usec":
				case "microseconds":
					oldUnits = units
					break
				
			endswitch
			
		endfor
		
	endfor
	
	if ( strlen( oldUnits ) == 0 )
	
		oldUnits = "msec"
	
		Prompt oldUnits, "please select the current x-scaling of your data waves:", popup "sec;msec;usec;"
	
		DoPrompt NMPromptStr( "Unknown X-scale Units" ), oldUnits
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		NMLabel( "x" , oldUnits )
	
	endif
	
	NMCmdHistory( "NMXUnitsChange", NMCmdStr( newUnits, "" ) )
		
	return NMXUnitsChange( newUnits )

End // NMXUnitsChangeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXUnitsChange( newUnits )
	String newUnits
	
	Variable ccnt, wcnt, scale = 1
	String oldunits, labelStr, wname, rstr, wList = "", cList, badList = ""
	String thisfxn = "NMXUnitsChange"
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	strswitch( newUnits )
		case "s":
		case "sec":
		case "seconds":
		case "ms":
		case "msec":
		case "milliseconds":
		case "us":
		case "usec":
		case "microseconds":
			break
		default:
			return NMErrorStr( 20, thisfxn, "newUnits", newUnits )
	endswitch
	
	// change all channels and waves
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		//if ( NMChanSelected( ccnt ) != 1 )
		//	continue // channel not selected
		//endif
		
		cList = ""
		
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
		
			//wName = NMWaveSelected( ccnt, wcnt )
			
			wName = NMChanWaveName( ccnt, wcnt )
			
			if ( ( strlen( wName ) == 0 ) || ( WaveExists( $wName ) == 0 ) )
				continue
			endif
			
			oldunits = GetWaveUnits( "x", wName, "" )
			
			scale = 1
		
			strswitch( oldunits )
			
				case "s":
				case "sec":
				case "seconds":
				
					strswitch( newUnits )
						case "s":
						case "sec":
						case "seconds":
							break
						case "ms":
						case "msec":
						case "milliseconds":
							scale = 1000
							break
						case "us":
						case "usec":
						case "microseconds":
							scale = 1000000
							break
					endswitch
					
					break
				
				case "ms":
				case "msec":
				case "milliseconds":
				
					strswitch( newUnits )
						case "s":
						case "sec":
						case "seconds":
							scale = 0.001
							break
						case "ms":
						case "msec":
						case "milliseconds":
							break
						case "us":
						case "usec":
						case "microseconds":
							scale = 1000
							break
					endswitch
					
					break
					
				case "us":
				case "usec":
				case "microseconds":
				
					strswitch( newUnits )
						case "s":
						case "sec":
						case "seconds":
							scale = 0.000001
							break
						case "ms":
						case "msec":
						case "milliseconds":
							scale = 0.001
							break
						case "us":
						case "usec":
						case "microseconds":
							break
					endswitch
					
					break
					
				default:
				
					badList = AddListItem( wName, badList, ";", inf )
				
					continue
					
			endswitch
			
			if ( scale == 1 )
				continue // nothing to do
			endif
			
			rstr = SetXScale( Nan, scale*deltax( $wName ), Nan, wName )
			
			if ( strlen( rstr ) == 0 )
				badList = AddListItem( wName, badList, ";", inf )
				continue
			endif
			
			NMNoteStrReplace( wName, "XUnits", newUnits )
			
			labelStr = NMNoteStrByKey( wName, "XLabel" )
			
			if ( strlen( labelStr ) > 0 )
				labelStr = ReplaceString( oldUnits, labelStr, newUnits )
				NMNoteStrReplace( wName, "XLabel", labelStr )
			endif
			
			cList = AddListItem( wName, cList, ";", inf )
		
		endfor
		
		NMMainHistory( "X-scale ( " + newUnits+ " )", ccnt, cList, 0 )
		
		wList += cList
		
	endfor
	
	if ( ItemsInList( badList ) > 0 )
		NMDoAlert( "Failed to find time units for wave(s): " + badList )
	endif
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMXUnitsChange

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleWaveCall()
	Variable npnts
	String vList = "", df = MainDF()
	
	String alg = StrVarOrDefault( df+"ScaleWaveAlg", "x" )
	Variable value = NumVarOrDefault( df+"ScaleWaveVal", 1 )
	Variable tbgn = NumVarOrDefault( df+"ScaleWaveTbgn", -inf )
	Variable tend = NumVarOrDefault( df+"ScaleWaveTend", inf )
		
	Prompt alg, "function:", popup "x;/;+;-"
	Prompt value, "scale value:"
	Prompt tbgn, "time begin:"
	Prompt tend, "time end:"
	
	DoPrompt NMPromptStr( "Scale Wave By Number" ), alg, value, tbgn, tend
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( numtype( value ) > 0 )
	
		DoAlert 1, "Alert: the scale value you entered ( " + num2str( value ) + " ) is not a number. Do you wish to continue?"
		
		if ( V_flag != 1 )
			return "" // cancel
		endif
		
	endif
	
	if ( ( StringMatch( alg, "/" ) == 1 ) && ( value == 0 ) )
		NMDoAlert( "Abort NMScaleWave: cannot divide by zero." )
		return "" // cancel
	endif
	
	SetNMstr( df+"ScaleWaveAlg", alg )
	SetNMvar( df+"ScaleWaveVal", value )
	SetNMvar( df+"ScaleWaveTbgn", tbgn )
	SetNMvar( df+"ScaleWaveTend", tend )
	
	vList = NMCmdStr( alg, vList )
	vList = NMCmdNum( value, vList )
	vList = NMCmdNum( tbgn, vList )
	vList = NMCmdNum( tend, vList )
	NMCmdHistory( "NMScaleWave", vList )
	
	return NMScaleWave( alg, value, tbgn, tend )
	
End // NMScaleWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleWave( alg, scaleValue, tbgn, tend )
	String alg // "x", "/", "+" or "-"
	Variable scaleValue // scale by value
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	
	Variable ccnt, wcnt
	String cList, wList = "", thisfxn = "NMScaleWave"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( strsearch( "x*/+-", alg, 0 ) == -1 )
		return NMErrorStr( 20, thisfxn, "alg", alg )
	endif
	
	if ( ( StringMatch( alg, "/" ) == 1 ) && ( scaleValue == 0 ) )
		return NMErrorStr( 90, thisfxn, "cannot divide by zero", "" )
	endif
	
	if ( numtype( scaleValue ) == 1 )
		return NMErrorStr( 10, thisfxn, "scaleValue", num2str( scaleValue ) ) // inf not allowed
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = NMScaleWaves( alg, scaleValue, tbgn, tend, cList )
		wList += cList
		
		NMMainHistory( "Y-scale ( " + alg + num2str( scaleValue ) + "; t=" + num2str( tbgn ) + "," + num2str( tend ) + " )", ccnt, cList, 0 )
	
	endfor
	
	ChanGraphsUpdate()
	
	KillWaves /Z U_ScaleWave
	
	return wList

End // NMScaleWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByWaveCall()

	Variable npnts
	String optionsStr, wList, wList2 = "", vList = "", sname, df = MainDF()
	
	Variable numWaves = NMNumWaves()
	
	Variable method = NumVarOrDefault( df+"ScaleByWaveMthd", 0 )
	String alg = StrVarOrDefault( df+"ScaleByWaveAlg", "x" )
	String waveSelect = StrVarOrDefault( df+"ScaleByWaveSelect", "" )
	String waveSelect2 = StrVarOrDefault( df+"ScaleByWaveSelect2", "" )
	
	optionsStr = NMWaveListOptions( numWaves, 0 )
	
	wList = WaveList( "*", ";", optionsStr )
	
	if ( ItemsInList( wList ) > 0 )
		wList = " ;" + wList
	endif
	
	npnts = NMWaveSelectXstats( "numpnts", -1 )
	
	if ( ( numtype( npnts ) == 0 ) && ( npnts > 0 ) )
	
		optionsStr = NMWaveListOptions( npnts, 0 )
	
		wList2 = WaveList( "*", ";", optionsStr )
		
		if ( ItemsInList( wList2 ) > 0 )
			wList2 = " ;" + wList2
		endif
		
	endif
	
	Prompt alg, "function:", popup "x;/;+;-"
	Prompt waveSelect, "choose a wave of scale values:", popup wList
	Prompt waveSelect2, "or choose a wave to scale by:", popup wList2
	
	DoPrompt NMPromptStr( "Scale by Wave" ), alg, waveSelect, waveSelect2
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( StringMatch( waveSelect, "_none_" ) == 0 ) // scale by wave of values
		method = 1
		sname = waveSelect
		waveSelect2 = ""
	elseif ( StringMatch( waveSelect2, "_none_" ) == 0 ) // scale by wave
		method = 2
		sname = waveSelect2
		waveSelect = ""
	else
		return ""
	endif
	
	SetNMvar( df+"ScaleByWaveMthd", method )
	SetNMstr( df+"ScaleByWaveAlg", alg )
	SetNMstr( df+"ScaleByWaveSelect", waveSelect )
	SetNMstr( df+"ScaleByWaveSelect2", waveSelect2 )
	
	vList = NMCmdNum( method, vList )
	vList = NMCmdStr( alg, vList )
	vList = NMCmdStr( sname, vList )
	NMCmdHistory( "NMScaleByWave", vList )
	
	return NMScaleByWave( method, alg, sname )

End // NMScaleByWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMScaleByWave( method, alg, scaleWaveName )
	Variable method // ( 1 ) scale by wave of values ( 2 ) scale by wave
	String alg // "x", "/", "+" or "-"
	String scaleWaveName // scale wave name

	Variable ccnt, wcnt
	String wName, cList = "", wList = "", thisfxn = "NMScaleByWave"
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( strsearch( "x*/+-", alg, 0 ) < 0 )
		return NMErrorStr( 20, thisfxn, "alg", alg )
	endif
	
	switch( method )
	
		case 1:
		
			if ( NMUtilityWaveTest( scaleWaveName ) < 0 )
				return NMErrorStr( 1, thisfxn, "scaleWaveName", scaleWaveName )
			endif
			
			Wave scalewave = $scaleWaveName
			
			break
			
		case 2:
		
			if ( NMUtilityWaveTest( scaleWaveName ) < 0 )
				return NMErrorStr( 1, thisfxn, "scaleWaveName", scaleWaveName )
			endif
			
			Duplicate /O $scaleWaveName U_ScaleWave
			
			break
			
		default:
		
			return NMErrorStr( 10, thisfxn, "method", num2istr( method ) )
			
	endswitch
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
		
			wName = NMWaveSelected( ccnt, wcnt )
			
			if ( strlen( wName ) == 0 )
				continue // wave not selected, or does not exist... go to next wave
			endif
		
			if ( method == 1 )

				wName = NMScaleWaves( alg, scalewave[NMChanWaveNum( wName )], -inf, inf, wName )
				
			elseif ( method == 2 )
			
				wName = ScaleByWave( alg, "U_ScaleWave", wName )
				
			endif
			
			if ( strlen( wName ) > 0 )
				cList = AddListItem( wName, cList, ";", inf )
			endif
		
		endfor
		
		wList += cList
		
		if ( method == 1 )
			NMMainHistory( "Y-scale ( " + alg + scaleWaveName + " )", ccnt, cList, 0 )
		elseif ( method == 2 )
			NMMainHistory( "Y-scale ( " + alg + scaleWaveName + " )", ccnt, cList, 0 )
		endif
	
	endfor
	
	ChanGraphsUpdate()
	
	KillWaves /Z U_ScaleWave
	
	return wList

End // NMScaleByWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTimeScaleModeCall( mode )
	Variable mode // ( 0 ) episodic ( 1 ) continuous

	NMCmdHistory( "NMTimeScaleMode", NMCmdNum( mode, "" ) )
	
	return NMTimeScaleMode( mode )

End // NMTimeScaleModeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTimeScaleMode( mode )
	Variable mode // ( 0 ) episodic ( 1 ) continuous
	
	Variable ccnt, wcnt, dx, tbgn
	String wname
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		//if ( NMChanSelected( ccnt ) != 1 )
		//	continue // channel not selected
		//endif
		
		tbgn = Nan
		
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) 
		
			wName = NMChanWaveName( ccnt, wcnt )
			
			if ( exists( wName ) == 0 )
				continue // wave does not exist, go to next wave
			endif
			
			if ( numtype( tbgn ) > 0 )
				tbgn = leftx( $wName )
			endif
			
			if ( mode == 1 ) // continuous
				dx = deltax( $wName )
				Setscale /P x tbgn, dx, $wName
				tbgn = rightx( $wName )
			else // episodic
				dx = deltax( $wName )
				Setscale /P x tbgn, dx, $wName
			endif
			
		endfor
		
	endfor
	
	ChanGraphsUpdate()
	
	return ""
	
End // NMTimeScaleMode

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBaselineCall()
	String vList = "", df = MainDF()
	
	Variable method = NumVarOrDefault( df+"Bsln_Method", 1 )
	Variable tbgn = NumVarOrDefault( df+"Bsln_Bgn", 0 )
	Variable tend = NumVarOrDefault( df+"Bsln_End", 5 )
	
	Prompt tbgn, "compute baseline FROM (ms):"
	Prompt tend, "compute baseline TO (ms):"
	Prompt method, "subtract from each wave:", popup "its individual baseline;average baseline of selected waves"
	
	DoPrompt NMPromptStr( "Subtract Baseline" ), tbgn, tend, method
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( df+"Bsln_Method", method )
	SetNMvar( df+"Bsln_Bgn", tbgn )
	SetNMvar( df+"Bsln_End", tend )
	
	if ( method == 1 )
	
		vList = NMCmdNum( 1, vList )
		vList = NMCmdNum( tbgn, vList )
		vList = NMCmdNum( tend, vList )
		NMCmdHistory( "NMBaselineWaves", vList )
		
		return NMBaselineWaves( 1, tbgn, tend )
		
	elseif ( method == 2 )
	
		vList = NMCmdNum( 2, vList )
		vList = NMCmdNum( tbgn, vList )
		vList = NMCmdNum( tend, vList )
		NMCmdHistory( "NMBaselineWaves", vList )
		
		return NMBaselineWaves( 2, tbgn, tend )
		
	endif
	
	return ""

End // NMBaselineCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBaselineWaves( method, tbgn, tend )
	Variable method // ( 1 ) subtract wave's individual mean ( 2 ) subtract mean of all waves
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	
	Variable ccnt, wcnt, avg, mn, sd, cnt
	String mnsd, cList, wName, oName, wList = ""
	String thisfxn = "NMBaselineWaves"
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( ( method != 1 ) && ( method != 2 ) )
		return NMErrorStr( 10, thisfxn, "method", num2istr( method ) )
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		if ( method == 2 ) // subtract mean of all waves
	
			mnsd = MeanStdv( tbgn, tend, cList ) // compute mean and stdv of waves
			
			avg = str2num( StringByKey( "mean", mnsd, "=" ) )
			sd = str2num( StringByKey( "stdv", mnsd, "=" ) )
			cnt = str2num( StringByKey( "count", mnsd, "=" ) )
		 
			DoAlert 1, "Baseline mean = " + num2str( avg ) + " ± " + num2str( sd ) + ". Subtract mean from selected waves?"
		
			if ( V_Flag != 1 )
				return "" // cancel
			endif
	
		endif
		
		cList = ""
		
		oName = GetWaveName( MainPrefix( "" ) + "Bsln_" + NMWaveSelectStr() + "_", ccnt, 0 )
		
		Make /O/N=( numWaves ) $oName
		
		Wave otempwave = $oName
		
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
		
			wName = NMWaveSelected( ccnt, wcnt )
			
			if ( strlen( wName ) == 0 )
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			Wave tempWave = $wName // create local reference to wave
			
			if ( method == 1 )
				mn = mean( tempwave, tbgn, tend )
			else
				mn = avg
			endif
	
			tempwave -= mn
			
			otempwave[wcnt] = mn
			
			Note tempwave, "Func:" + thisfxn
			Note tempwave, "Bsln Value:" + num2str( mn ) + ";Bsln Tbgn:" + num2str( tbgn ) + ";Bsln Tend:" + num2str( tend ) + ";"
			
			cList = AddListItem( wName, cList, ";", inf )
			
		endfor
		
		//cList = BaselineWaves( method, tbgn, tend, cList )
		wList += cList
		
		NMMainHistory( "Baselined ( t=" + num2str( tbgn ) + "," + num2str( tend ) + " )", ccnt, cList, 0 )
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList

End // NMBaselineWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWavesStatsCall( select )
	String select // "Average" or "Sum" or "SumSqr" or "Matrix"
	
	Variable ccnt, dx, sameDx = 1, waveNANs, lftx, rghtx
	String sprefix = select, vList = "", df = MainDF()
	
	String waveSelect = NMWaveSelectGet()
	String allList = NMWaveSelectAllList()
	
	Variable filterN = ChanFilterNumGet( -1 )
	Variable ft = ChanFuncGet( -1 )
	
	Variable sameTimeScale = NMWavesHaveSameTimeScale()
	Variable noPlot = 0
	
	Variable mode=1, useChannelTransforms=0, ignoreNANs=1, truncateToCommonTimeScale=1, interpToSameTimeScale=0
	Variable saveMatrix=0, plotInputData=1, onePlotPerChannel=1
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue
		endif
		
		dx = NMWaveSelectXstats( "deltax", ccnt )
		
		if ( numtype( dx ) > 0 )
			sameDx = 0
		endif
	
	endfor
	
	if ( sameDx == 0 )
	
		interpToSameTimeScale = 1
	
		DoAlert 1, "Alert: your data has different sample intervals and requires interpolation to compute the " + select + ". The interpolation will not effect your original data. Do you want to continue?"
		
		if ( V_flag != 1 )
			return "" // cancel
		endif
	
	endif
	
	Prompt mode, "Compute:", popup "Avg;Avg + Stdv;Avg + Var;Avg + SEM;Sum;SumSqr;Matrix;"
	Prompt useChannelTransforms, "Use channel F(t) and filtering on your data?", popup "no;yes;"
	Prompt ignoreNANs, "Your data contains NANs (non-numbers). Do you want to ignore them?", popup "no;yes;"
	Prompt truncateToCommonTimeScale, "Your data waves have different time scales. " + select + " should include:", popup "all given time points;only common time points;"
	Prompt plotInputData, "Include selected data waves in final plot?", popup "no;yes;"
	Prompt onePlotPerChannel, "Plot " + NMQuotes( waveSelect ) + " in the same graph?", popup, "no;yes;"
	
	String modeStr = "Mode"
	String chanTransStr = "ChanTransforms"
	String NANstr = "IgnoreNANs"
	String truncateStr = "Truncate"
	String plotInputDataStr = "PlotData"
	String onePlotStr = "OnePlot"
	
	strswitch( select )
	
		case "Average":
			sprefix = "Avg"
			break
			
		case "Sum":
			mode = 5
			modestr = ""
			break
			
		case "SumSqr":
			mode = 6
			modestr = ""
			break
			
		case "Matrix":
		
			mode = 7
			modestr = ""
			NANstr = ""
			plotInputDataStr = ""
			onePlotStr = ""
			
			noPlot = 1
			saveMatrix = 1
			
			break
			
		default:
			return "" // error

	endswitch
	
	if ( strlen( modestr ) > 0 )
		mode = NumVarOrDefault( df+sprefix+modestr, mode )
	endif
	
	if ( strlen( chanTransStr ) > 0 )
		useChannelTransforms = BinaryCheck( NumVarOrDefault( df+sprefix+chanTransStr, useChannelTransforms ) )
	endif
	
	if ( strlen( NANstr ) > 0 )
		ignoreNANs = BinaryCheck( NumVarOrDefault( df+sprefix+NANstr, ignoreNANs ) )
	endif
	
	if ( strlen( truncateStr ) > 0 )
		truncateToCommonTimeScale = BinaryCheck( NumVarOrDefault( df+sprefix+truncateStr, truncateToCommonTimeScale ) )
	endif
	
	if ( strlen( plotInputDataStr ) > 0 )
		plotInputData = BinaryCheck( NumVarOrDefault( df+sprefix+plotInputDataStr, plotInputData ) )
	endif
	
	if ( strlen( onePlotStr ) > 0 )
		onePlotPerChannel = BinaryCheck( NumVarOrDefault( df+sprefix+onePlotStr, onePlotPerChannel ) )
	endif
	
	useChannelTransforms += 1
	ignoreNANs += 1
	truncateToCommonTimeScale += 1
	plotInputData += 1
	onePlotPerChannel += 1
	
	if ( noPlot == 1 )
		
		plotInputData = 0
		onePlotPerChannel = 1
		
		plotInputDataStr = ""
		onePlotStr = ""
	
		if ( filterN + ft > 0 )
		
			DoPrompt NMPromptStr( select ), mode, useChannelTransforms
			
			useChannelTransforms -= 1
			
		else
		
			chanTransStr = ""
			useChannelTransforms = 0
			
		endif
	
	elseif ( ItemsInList( allList ) > 1 )
	
		if ( filterN + ft > 0 )
		
			DoPrompt NMPromptStr( select ), mode, useChannelTransforms, plotInputData, onePlotPerChannel
			
			useChannelTransforms -= 1
			plotInputData -= 1
			onePlotPerChannel -= 1
			
		else
		
			chanTransStr = ""
			useChannelTransforms = 0
		
			DoPrompt NMPromptStr( select ), mode, plotInputData, onePlotPerChannel
			
			plotInputData -= 1
			onePlotPerChannel -= 1
			
		endif
		
	else
	
		onePlotStr = ""
		onePlotPerChannel = 1
	
		if ( filterN + ft > 0 )
		
			DoPrompt NMPromptStr( select ), mode, useChannelTransforms, plotInputData
			
			useChannelTransforms -= 1
			plotInputData -= 1
			
		else
		
			chanTransStr = ""
			useChannelTransforms = 0
		
			DoPrompt NMPromptStr( select ), mode, plotInputData
			
			plotInputData -= 1
			
		endif
		
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( sameTimeScale == 0 )
	
		DoPrompt NMPromptStr( select ), truncateToCommonTimeScale
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		truncateToCommonTimeScale -= 1
		
	else
	
		truncateStr = ""
		truncateToCommonTimeScale = 1
		
	endif
	
	if ( truncateToCommonTimeScale == 1 )
		lftx = NMChanXstats( "maxLeftx" )
		rghtx = NMChanXstats( "minRightx" )
	else
		lftx = NMChanXstats( "minLeftx" )
		rghtx = NMChanXstats( "maxRightx" )
	endif
	
	waveNANs = NMWavesHaveNANs( lftx, rghtx )
	
	if ( (mode < 7 ) && ( waveNANs == 1 ) && ( truncateToCommonTimeScale == 1 ) )
	
		DoPrompt NMPromptStr( select ), ignoreNANs
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		ignoreNANs -= 1
		
	endif
	
	if ( truncateToCommonTimeScale == 0 )
		ignoreNANs = 1 // NANs must be ignored in this case
	endif
	
	if ( strlen( modeStr ) > 0 )
		SetNMvar( df+sprefix+modeStr, mode )
	endif
	
	if ( strlen( chanTransStr ) > 0 )
		SetNMvar( df+sprefix+chanTransStr, useChannelTransforms )
	endif
	
	if ( strlen( NANstr ) > 0 )
		SetNMvar( df+sprefix+NANstr, ignoreNANs )
	endif
	
	if ( strlen( truncateStr ) > 0 )
		SetNMvar( df+sprefix+truncateStr, truncateToCommonTimeScale )
	endif
	
	if ( strlen( plotInputDataStr ) > 0 )
		SetNMvar( df+sprefix+plotInputDataStr, plotInputData )
	endif
	
	if ( strlen( onePlotStr ) > 0 )
		SetNMvar( df+sprefix+onePlotStr, onePlotPerChannel )
	endif
	
	vList = NMCmdNum( mode, vList )
	vList = NMCmdNum( useChannelTransforms, vList )
	vList = NMCmdNum( ignoreNANs, vList )
	vList = NMCmdNum( truncateToCommonTimeScale, vList )
	vList = NMCmdNum( interpToSameTimeScale, vList )
	vList = NMCmdNum( saveMatrix, vList )
	vList = NMCmdNum( plotInputData, vList )
	vList = NMCmdNum( onePlotPerChannel, vList )
	
	NMCmdHistory( "NMWavesStats", vList )
		
	return NMWavesStats( mode, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix, plotInputData, onePlotPerChannel )
	
End // NMWavesStatsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWavesStats( mode, useChannelTransforms, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix, plotInputData, onePlotPerChannel )
	Variable mode // ( 1 ) avg ( 2 ) avg + stdv ( 3 ) avg + var ( 4 ) avg + sem ( 5 ) sum ( 6 ) sum squares ( 7 ) matrix
	Variable useChannelTransforms // use channel F(t ) and smoothing/filtering on input waves? ( 0 ) no ( 1 ) yes
	Variable ignoreNANs // ignore NaN's (empty data points ) within input waves? ( 0 ) no ( 1 ) yes
	Variable truncateToCommonTimeScale // ( 0 ) no. if necessary, inputs waves are expanded to fit all min and max times ( 1 ) yes. input waves are truncated to a common time base ( temporary operations )
	Variable interpToSameTimeScale // interpolate input waves to the same x-scale (0 ) no (1 ) yes ( generally one should use interp ONLY if waves have different sample intervals. this is a temporary operation )
	Variable saveMatrix // save list of waves as a 2D matrix ( 0 ) no ( 1 ) yes
	Variable plotInputData // plot input waves? ( 0 ) no ( 1 ) yes
	Variable onePlotPerChannel // display sets/groups all in one plot? ( 0 ) no, each has its own plot ( 1 ) yes ( note, this is used when "All Sets" or "All Groups" is selected )
	
	Variable markerLimit = 200 // limit for number of points to use "lines + markers"
	
	Variable errorWavesPosNeg = 0 // create additional positive and negative errror waves ( 0 ) no ( 1 ) yes

	Variable icnt, ccnt, wcnt, nwaves, cancel, noplot, savePnts, editMatrix, chanTransform, r, g, b
	
	String gPrefix, gName, gName2, gList = "", gTitle, wSelectStr, color
	String cList, wList = "", rList = ""
	String wavePrefix = "", wName = ""
	String sdPrefix = "", sdName = "", sdPrefixP = "", sdNameP = "", sdPrefixN = "", sdNameN = ""
	String pntsName, matrixName
	String df = MainDF(), thisfxn = "NMWavesStats"
	
	String colorList = "red;blue;green;purple;black;yellow;red;blue;green;purple;black;yellow;"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	Variable numChannels = NMNumChannels()
	
	String xWave = NMXwave()
	
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	String allList = NMWaveSelectAllList()
	Variable allListItems = ItemsInList( allList )
	
	Variable overwrite = NeuroMaticVar( "OverWrite" )
	
	switch( mode )
		case 1:
			wavePrefix = "Avg_"
			break
		case 2:
			wavePrefix = "Avg_"
			sdPrefix = "Stdv_"
			sdPrefixP = "StdvP_"
			sdPrefixN = "StdvN_"
			break
		case 3:
			wavePrefix = "Avg_"
			sdPrefix = "Var_"
			sdPrefixP = "VarP_"
			sdPrefixN = "VarN_"
			break
		case 4:
			wavePrefix = "Avg_"
			sdPrefix = "Sem_"
			sdPrefixP = "SemP_"
			sdPrefixN = "SemN_"
			break
		case 5:
			wavePrefix = "Sum_"
			break
		case 6:
			wavePrefix = "SumSqr_"
			break
		case 7:
			wavePrefix = "Matrix_"
			noplot = 1
			editMatrix = 1
			saveMatrix = 1
			break
		default:
			return NMErrorStr( 10, thisfxn, "mode", num2istr( mode ) )
	endswitch
	
	if ( ( strlen( xWave ) > 0 ) && ( NMUtilityWaveTest( xWave ) < 0 ) )
		xWave = ""
	endif
	
	for ( icnt = 0; icnt < max( allListItems, 1 ); icnt += 1 ) // loop thru wave selections
	
		if ( cancel == 1 )
			break
		endif
		
		if ( allListItems > 0 )
			waveSelect = StringFromList( icnt, allList )
			NMWaveSelect( waveSelect )
		endif
		
		if ( NMNumActiveWaves() <= 0 )
			continue
		endif
	
		for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
		
			if ( cancel == 1 )
				break
			endif
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue // channel not selected
			endif
			
			cList = NMWaveSelectList( ccnt ) // channel wave list
			
			nwaves = ItemsInList( cList )
			
			if ( nwaves < 2 )
				NMDoAlert( "NMWavesStats: Channel " + ChanNum2Char( ccnt ) + ": not enough waves." )
				continue
			endif
			
			if ( useChannelTransforms == 1 )
				chanTransform = ccnt
			else
				chanTransform = -1
			endif
			
			NMWavesStatistics( cList, chanTransform, ignoreNANs, truncateToCommonTimeScale, interpToSameTimeScale, saveMatrix )
			
			wList = AddListItem( cList, wList, ";", inf )
			
			if ( WavesExist( "U_Avg;U_Sdv;U_Sum;U_Pnts;" ) == 0 )
				cancel = 1
				break // something is wrong
			endif
			
			wSelectStr = NMWaveSelectStr()
			
			wName = NextWaveName2( "", wavePrefix + wSelectStr + "_", ccnt, overwrite )
			sdName = NextWaveName2( "", sdPrefix + wavePrefix + wSelectStr + "_", ccnt, overwrite )
			sdNameP = NextWaveName2( "", sdPrefixP + wavePrefix + wSelectStr + "_", ccnt, overwrite )
			sdNameN = NextWaveName2( "", sdPrefixN + wavePrefix + wSelectStr + "_", ccnt, overwrite )
			pntsName = NextWaveName2( "", "Pnts_" + wavePrefix + wSelectStr + "_", ccnt, overwrite )
			matrixName = NextWaveName2( "", "Matrix_" + wSelectStr + "_", ccnt, overwrite )
			
			gPrefix= MainPrefix( "" )+ wavePrefix + NMFolderPrefix( "" ) + wSelectStr
			gName = NextGraphName( gPrefix, ccnt, overwrite )
			
			if ( ( allListItems > 0 ) && ( onePlotPerChannel == 1 ) )
				gTitle = NMFolderListName( "" ) + " : " + ReplaceString( "_", wavePrefix, "" ) + " : " + CurrentNMWavePrefix() + " : Ch " + ChanNum2Char( ccnt ) + " : " + saveWaveSelect
			else
				gTitle = NMFolderListName( "" ) + " : " + ReplaceString( "_", wavePrefix, "" ) + " : " + CurrentNMWavePrefix() + " : Ch " + ChanNum2Char( ccnt ) + " : " + waveSelect
			endif
			
			savePnts = 0
			
			WaveStats /Q U_Pnts
			
			if ( ( V_numNaNs > 0 ) || ( V_min != V_max ) )
				savePnts = 1
			endif
		
			switch( mode )
				case 1:
				case 2:
				case 3:
				case 4:
					Duplicate /O U_Avg $wName
					break
				case 5:
					Duplicate /O U_Sum $wName
					break
				case 6:
					Duplicate /O U_SumSqr $wName
					break
				case 7:
					savePnts = 0
					break
				default:
					savePnts = 0
					cancel = 1
			endswitch
			
			if ( savePnts == 1 )
				Duplicate /O U_Pnts $pntsName
			endif
			
			if ( saveMatrix == 1 )
				Duplicate /O U_2Dmatrix $matrixName
			endif
			
			if ( editMatrix == 1 )
				EditWaves( gName, gTitle, matrixName )
			endif
			
			NMMainHistory( wName, ccnt, cList, 0 )
			
			if ( noplot == 1 )
				continue
			endif
	
			if ( ( allListItems > 0 ) && ( onePlotPerChannel == 1 ) ) // All Sets or All Groups in one display
			
				color = StringFromList( icnt, colorList )
				
				r = NMPlotRGB( color, "r" )
				g = NMPlotRGB( color, "g" )
				b = NMPlotRGB( color, "b" )
			
				if ( icnt == 0 )
				
					gName2 = gName
					
					if ( plotInputData == 1 )
					
						NMPlotWavesOffset( gName2, gTitle, "", "", xWave, cList, 0, 0, 0, 0 )
						
						if ( strlen( xWave ) > 0 )
							AppendToGraph /W=$gName2 /C=(r,g,b ) $wName vs $xWave
						else
							AppendToGraph /W=$gName2 /C=(r,g,b ) $wName
						endif
						
					else
					
						NMPlotWavesOffset( gName2, gTitle, "", "", xWave, wName, 0, 0, 0, 0 )
						ModifyGraph /W=$gName rgb=( r,g,b )
						
					endif
					
				else
				
					gName = gName2
					
					if ( plotInputData == 1 )
						NMPlotAppend( gName, "black", xWave, cList, 0, 0, 0, 0 )
					endif
					
					if ( strlen( xWave ) > 0 )
						AppendToGraph /W=$gName /C=(r,g,b ) $wName vs $xWave
					else
						AppendToGraph /W=$gName /C=(r,g,b ) $wName
					endif
					
				endif
				
			else
				
				if ( plotInputData == 1 )
				
					NMPlotWavesOffset( gName, gTitle, "", "", xWave, cList, 0, 0, 0, 0 )
					
					if ( strlen( xWave ) > 0 )
						AppendToGraph /W=$gName $wName vs $xWave
					else
						AppendToGraph /W=$gName $wName
					endif
					
				else
				
					NMPlotWavesOffset( gName, gTitle, "", "", xWave, wName, 0, 0, 0, 0 )
					
				endif
				
			endif
			
			//ModifyGraph /W=$gName rgb( $wName )=( 65535,0,0 ), lsize( $wName )=1.5
			
			if ( numpnts( $wName ) < markerLimit )
				ModifyGraph /W=$gName mode( $wName )=4,marker( $wName )=19
			endif
			
			if ( ( mode >= 2 ) && ( mode <= 4 ) && ( WaveExists( U_Sdv ) == 1 ) ) // Stdv, Var or SEM
			
				Duplicate /O U_Sdv $sdName
				
				Wave avg = $wName
				Wave sdv = $sdName
				
				if ( mode == 3 )
				
					sdv *= sdv // variance
					
				elseif ( mode == 4 )
				
					if ( WaveExists( U_Pnts ) == 1 )
					
						Wave npnts = U_Pnts
						
						sdv /= sqrt( npnts ) // SEM
						
					else
					
						sdv = Nan
						
					endif
					
				endif
				
				if ( errorWavesPosNeg == 1 )
				
					Duplicate /O U_Sdv $sdNameP
					
					Wave sdvp = $sdNameP
					
					sdvp = avg + sdv
					
					Duplicate /O U_Sdv $sdNameN
					
					Wave sdvp = $sdNameN
					
					sdvp = avg - sdv
				
				endif
				
				if ( ( mode == 2 ) || ( mode == 4 ) ) // plot Sdv or SEM
				
					if ( numpnts( $sdName ) > markerLimit )
						ErrorBars /W=$gName/L=0/Y=1 $wName Y,wave=($sdName,$sdName )
					else
						ErrorBars /W=$gName $wName Y, wave=( $sdName,$sdName )
					endif
					
				endif
				
			endif
			
			if ( ItemsInList( gList ) == 0 )
				gList = gName
			else
				gList = AddListItem( gName, gList, ";", inf )
			endif
			
		endfor // channels
		
	endfor // waveSelect
	
	//if ( onePlotPerChannel == 1 ) && (ItemsInList( rList ) > 1 ) )
	//	GraphRainbow( gName, rList )
	//endif
	
	if ( allListItems > 0 )
		NMWaveSelect( saveWaveSelect ) // back to original wave select
	endif
	
	NMNoteStrReplace( wName, "Source", wName )
	NMNoteStrReplace( sdName, "Source", sdName )
	
	Killwaves /Z U_Avg, U_Sdv, U_Sum, U_SumSqr, U_Pnts, U_2Dmatrix // kill output waves from WavesStatistics
	
	return wList

End // NMWavesStats

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMIVCall()

	Variable numChannels = NMNumChannels()
	
	if ( numChannels < 2 )
		NMDoAlert( "Abort NMIVCall : this function requires two or more data channels." )
		return ""
	endif
	
	String vList = "", df = MainDF()
	
	Variable rx = rightx( $ChanDisplayWave( -1 ) )
	
	String fxnX = StrVarOrDefault( df+"IVFxnX", "Avg" )
	String fxnY = StrVarOrDefault( df+"IVFxnY", "Avg" )
	
	Variable chX = NumVarOrDefault( df+"IVChX", 1 )
	Variable chY = NumVarOrDefault( df+"IVChY", 0 )
	Variable tbgnX = NumVarOrDefault( df+"IVTbgnX", 0 )
	Variable tendX = NumVarOrDefault( df+"IVTendX", rx )
	Variable tbgnY = NumVarOrDefault( df+"IVTbgnY", 0 )
	Variable tendY = NumVarOrDefault( df+"IVTendY", rx )
	
	chX += 1
	chY += 1

	Prompt chX, "select channel for x-data:", popup, NMChanList( "CHAR" )
	Prompt fxnX, "wave statistic for x-data:", popup, "Max;Min;Avg;Slope"
	Prompt tbgnX, "x-time window begin:"
	Prompt tendX, "x-time window end:"
	
	DoPrompt NMPromptStr( "IV : X Data" ), chX, fxnX, tbgnX, tendX
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	tbgnY = tbgnX
	tendY = tendX
	
	Prompt chY, "channel for y-data:", popup, NMChanList( "CHAR" )
	Prompt fxnY, "wave statistic for y-data:", popup, "Max;Min;Avg;Slope;"
	Prompt tbgnY, "y-time window begin:"
	Prompt tendY, "y-time window end:"
	
	DoPrompt NMPromptStr( "IV : Y Data" ), chY, fxnY, tbgnY, tendY
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	chY -= 1
	chX -= 1
	
	SetNMvar( df+"IVChY", chY )
	SetNMvar( df+"IVChX", chX )
	SetNMstr( df+"IVFxnY", fxnY )
	SetNMstr( df+"IVFxnX", fxnX )
	SetNMvar( df+"IVTbgnY", tbgnY )
	SetNMvar( df+"IVTendY", tendY )
	SetNMvar( df+"IVTbgnX", tbgnX )
	SetNMvar( df+"IVTendX", tendX )
	
	vList = NMCmdNum( chX, vList )
	vList = NMCmdStr( fxnX, vList )
	vList = NMCmdNum( tbgnX, vList )
	vList = NMCmdNum( tendX, vList )
	vList = NMCmdNum( chY, vList )
	vList = NMCmdStr( fxnY, vList )
	vList = NMCmdNum( tbgnY, vList )
	vList = NMCmdNum( tendY, vList )
	NMCmdHistory( "NMIV", vList )
	
	return NMIV( chX, fxnX, tbgnX, tendX, chY, fxnY, tbgnY, tendY )
	
End // NMIVCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMIV( chX, fxnX, tbgnX, tendX, chY, fxnY, tbgnY, tendY )
	Variable chx // channel for x data
	String fxnX // "min", "max", "avg", "slope"
	Variable tbgnX, tendX // x measure time begin and end, use ( -inf, inf ) for all time
	Variable chy // channel for y data
	String fxnY // "min", "max", "avg", "slope"
	Variable tbgnY, tendY // y measure time begin and end, use ( -inf, inf ) for all time
	
	Variable error, overwrite
	String xl, yl, wList, wName1, wName2, gPrefix, gName, gTitle, aName, uName
	String thisfxn = "NMIV"
	
	Variable numChannels = NMNumChannels()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( ( numtype( chX ) > 0 ) || ( chX < 0 ) || ( chX >= numChannels ) )
		return NMErrorStr( 10, thisfxn, "chX", num2istr( chX ) )
	endif
	
	strswitch( fxnX )
		case "Max":
		case "Min":
		case "Avg":
		case "Slope":
			break
		default:
			return NMErrorStr( 20, thisfxn, "fxnX", fxnX )
	endswitch
	
	if ( numtype( tbgnX ) > 0 )
		tbgnX = -inf
	endif
	
	if ( numtype( tendX ) > 0 )
		tendX = inf
	endif
	
	if ( ( numtype( chY ) > 0 ) || ( chY < 0 ) || ( chY >= numChannels ) )
		return NMErrorStr( 10, thisfxn, "chY", num2istr( chY ) )
	endif
	
	strswitch( fxnY )
		case "Max":
		case "Min":
		case "Avg":
		case "Slope":
			break
		default:
			return NMErrorStr( 20, thisfxn, "fxnY", fxnY )
	endswitch
	
	if ( numtype( tbgnY ) > 0 )
		tbgnY = -inf
	endif
	
	if ( numtype( tendY ) > 0 )
		tendY = inf
	endif
	
	aName = fxnY
	uName = "U_AmpY"
	
	if ( StringMatch( aName, "Slope" ) == 1 )
		aName = "Slp"
		uName = "U_AmpX"
	endif
	
	overwrite = NeuroMaticVar( "OverWrite" )
	
	wList = NMChanWaveList( chY )
	error = WaveListStats( fxnY, tbgnY, tendY, wList )
	yl = NMChanLabel( chY, "y", wList )
	
	wName1 = NextWaveName2( "", MainPrefix( "" ) + aName + "_", chY, overwrite )
	Duplicate /O $uName $wName1
	
	NMNoteStrReplace( wName1, "Source", wName1 )
	
	aName = fxnX
	uName = "U_AmpY"
	
	if ( StringMatch( aName, "Slope" ) == 1 )
		aName = "Slp"
		uName = "U_AmpX"
	endif
	
	wList = NMChanWaveList( chX )
	error = WaveListStats( fxnX, tbgnX, tendX, wList )
	xl = NMChanLabel( chX, "x", wList )
	
	wName2 = NextWaveName2( "", MainPrefix( aName + "_" ), chX, overwrite )
	Duplicate /O $uName $wName2
	
	NMNoteStrReplace( wName2, "Source", wName2 )
	
	KillWaves /Z U_AmpX, U_AmpY
	
	gPrefix = MainPrefix( "" ) + "IV_" + NMFolderPrefix( "" ) + NMWaveSelectStr() + "_" + aName
	gName = NextGraphName( gPrefix, -1, overwrite )
	gTitle = NMFolderListName( "" ) + " : IV : " + wName2
	
	gTitle = NMFolderListName( "" ) + " : IV : " + CurrentNMWavePrefix() + " : Ch " + ChanNum2Char( chY ) + " vs " + ChanNum2Char( chX ) + " : " + NMWaveSelectGet()
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=( 0,0,0,0 ) $wName1 vs $wName2 as gTitle
	SetCascadeXY( gName )
	
	ModifyGraph mode=3,marker=19,rgb=( 65535,0,0 )
	Label left yl
	Label bottom xl
	ModifyGraph standoff=0
	SetAxis /A
	
	return gName
	
End // NMIV

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNormalizeWavesCall()

	Variable win1, win2
	String vList = "", df = MainDF()
	
	if ( NMNormalizeCall( df ) < 0 )
		return "" // cancel
	endif
	
	String fxn1 = StrVarOrDefault( df+"Norm_Fxn1", "Avg" )
	
	Variable tbgn1 = NumVarOrDefault( df+"Norm_Tbgn1", 0 )
	Variable tend1 = NumVarOrDefault( df+"Norm_Tend1", 5 )
	
	String fxn2 = StrVarOrDefault( df+"Norm_Fxn2", "Max" )
	
	Variable tbgn2 = NumVarOrDefault( df+"Norm_Tbgn2", -inf )
	Variable tend2 = NumVarOrDefault( df+"Norm_Tend2", inf )
	
	vList = NMCmdStr( fxn1, vList )
	vList = NMCmdNum( tbgn1, vList )
	vList = NMCmdNum( tend1, vList )
	vList = NMCmdStr( fxn2, vList )
	vList = NMCmdNum( tbgn2, vList )
	vList = NMCmdNum( tend2, vList )
	NMCmdHistory( "NMNormalizeWaves", vList )
	
	return NMNormalizeWaves( fxn1, tbgn1, tend1, fxn2, tbgn2, tend2 )
	
End // NMNormalizeWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNormalizeWaves( fxn1, tbgn1, tend1, fxn2, tbgn2, tend2 )
	String fxn1 // function to compute min value, "avg" or "min" or "minavg"
	Variable tbgn1, tend1 // time begin and end, use ( -inf, inf ) for all time
	String fxn2 // function to compute max value, "avg" or "max" or "maxavg"
	Variable tbgn2, tend2 // time begin and end, use ( -inf, inf ) for all time
	
	Variable ccnt
	String cList, wList = "", thisfxn = "NMNormalizeWaves"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	Variable win1 = GetNumFromStr( fxn1, "MinAvg" )
	Variable win2 = GetNumFromStr( fxn2, "MaxAvg" )
	
	strswitch( fxn1 )
		case "Min":
		case "Avg":
			break
		default:
			if ( numtype( win1 ) > 0 )
				return NMErrorStr( 20, thisfxn, "fxn1", fxn1 )
			endif
	endswitch
	
	if ( numtype( tbgn1 ) > 0 )
		tbgn1 = -inf
	endif
	
	if ( numtype( tend1 ) > 0 )
		tend1 = inf
	endif
	
	strswitch( fxn2 )
		case "Max":
		case "Avg":
			break
		default:
			if ( numtype( win2 ) > 0 )
				return NMErrorStr( 20, thisfxn, "fxn2", fxn2 )
			endif
	endswitch
	
	if ( numtype( tbgn2 ) > 0 )
		tbgn2 = -inf
	endif
	
	if ( numtype( tend2 ) > 0 )
		tend2 = inf
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = NormalizeWaves( fxn1, tbgn1, tend1, fxn2, tbgn2, tend2, cList )
		wList += cList
		
		NMMainHistory( "Normalized waves to baseline", ccnt, cList, 0 )
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMNormalizeWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBlankWavesCall()
	String wList, vList = "", df = MainDF()
	
	String wname = StrVarOrDefault( df+"BlankWaveName", "" )
	Variable beforeTime = NumVarOrDefault( df+"BlankBeforeTime", 0 )
	Variable afterTime = NumVarOrDefault( df+"BlankAfterTime", 0 )
	
	wList = " ;" + WaveList( "*",";","TEXT:0" )
	
	Prompt wname, "wave of event times:", popup wList
	Prompt beforeTime, "time to blank before event (ms):"
	Prompt afterTime, "time to blank after event (ms):"
	
	DoPrompt NMPromptStr( "Blank Wave Events" ), wname, beforeTime, afterTime
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( df+"BlankWaveName", wname )
	SetNMvar( df+"BlankBeforeTime", beforeTime )
	SetNMvar( df+"BlankAfterTime", afterTime )
	
	vList = NMCmdStr( wname, vList )
	vList = NMCmdNum( beforeTime, vList )
	vList = NMCmdNum( afterTime, vList )
	NMCmdHistory( "NMBlankWaves", vList )
	
	return NMBlankWaves( wname, beforeTime, afterTime )
	
End // NMBlankWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBlankWaves( waveOfBlankTimes, beforeTime, afterTime )
	String waveOfBlankTimes
	Variable beforeTime, afterTime
	
	Variable ccnt
	String cList = "", wList = "", thisfxn = "NMBlankWaves"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif 
	
	if ( NMUtilityWaveTest( waveOfBlankTimes ) < 0 )
		return NMErrorStr( 1, thisfxn, "waveOfBlankTimes", waveOfBlankTimes )
	endif
	
	if ( numtype( beforeTime ) > 0 )
		return NMErrorStr( 10, thisfxn, "beforeTime", num2str( beforeTime ) )
	endif
	
	if ( numtype( afterTime ) > 0 )
		return NMErrorStr( 10, thisfxn, "afterTime", num2str( afterTime ) )
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		cList = BlankWaves( waveOfBlankTimes, beforeTime, afterTime, Nan, cList )
		wList += cList
		
		NMMainHistory( "blanked waves using event times " + waveOfBlankTimes, ccnt, cList, 0 )
		
	endfor
	
	ChanGraphsUpdate()
	
	return wList
	
End // NMBlankWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConcatWavesCall()
	String df = MainDF()
	
	String wavePrefix = StrVarOrDefault( df+"ConcatPrefix", "C_"+CurrentNMWavePrefix() )
		
	Prompt wavePrefix, "output wave name prefix:"
	DoPrompt "Concatenate Waves", wavePrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( df+"ConcatPrefix", wavePrefix )
	
	NMCmdHistory( "NMConcatWaves", NMCmdStr( wavePrefix, "" ) )
	
	return NMConcatWaves( wavePrefix )

End // NMConcatWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMConcatWaves( wavePrefix )
	String wavePrefix // output wave prefix
	
	Variable ccnt
	String wname, cList, wList = ""
	String thisfxn = "NMConcatWaves"
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		return NMErrorStr( 21, thisfxn, "wavePrefix", wavePrefix )
	endif
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
	
		cList = NMWaveSelectList( ccnt )
		
		if ( strlen( cList ) == 0 )
			continue
		endif
		
		wname = NextWaveName2( "", wavePrefix, ccnt, NeuroMaticVar( "OverWrite" ) )
		Concatenate /O/NP cList, $wname
		//cList = ConcatWaves( cList, wname )""
		wList += cList
		
		NMMainHistory( "Concatenate " + wname, ccnt, cList, 0 )
		
	endfor
	
	NMPrefixAdd( wavePrefix )
	ChanGraphsUpdate()
	
	return wList

End // NMConcatWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSplitWavesCall()
	
	String vList = "", df = MainDF()
	
	String wavePrefix = StrVarOrDefault( df+"SplitWavePrefix", "C_" + CurrentNMWavePrefix() )
	
	Variable waveLength = ( rightx( $ChanDisplayWave( -1 ) ) - leftx( $ChanDisplayWave( -1 ) ) )
	
	waveLength = NumVarOrDefault( df+"SplitWaveLength", waveLength / 10 )
		
	Prompt wavePrefix, "output wave prefix name:"
	Prompt waveLength, "output wave length:"
	DoPrompt "Split Waves", wavePrefix, waveLength
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( df+"SplitWavePrefix", wavePrefix )
	SetNMvar( df+"SplitWaveLength", waveLength )
	
	vList = NMCmdStr( wavePrefix, vList )
	vList = NMCmdNum( waveLength, vList )
	
	NMCmdHistory( "NMSplitWaves", vList )
	
	return NMSplitWaves( wavePrefix, waveLength )

End // NMSplitWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSplitWaves( wavePrefix, waveLength )
	String wavePrefix // output wave prefix
	Variable waveLength // output wave length
	
	Variable ccnt, wcnt, cancel, npnts
	String wname, outprefix, cList = "", wList = ""
	String thisfxn = "NMSplitWaves"
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( NMPrefixFolderAlert() == 0 )
		return ""
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		return NMErrorStr( 21, thisfxn, "wavePrefix", wavePrefix )
	endif
	
	if ( ( numtype( waveLength ) > 0 ) || ( waveLength <= 0 ) )
		return NMErrorStr( 10, thisfxn, "waveLength", num2str( waveLength ) )
	endif
	
	SetNeuroMaticStr( "ProgressStr", "Split Waves..." ) // set progress title
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = ""
		
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
		
			if ( CallNMProgress( wcnt, numWaves ) == 1 ) // progress display
				cancel = 1
				break // cancel wave loop
			endif
			
			wName = NMWaveSelected( ccnt, wcnt )
			
			if ( strlen( wName ) == 0 )
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			npnts = waveLength / deltax( $wName )
			
			if ( npnts >= numpnts( $wName ) )
				NMHistory( "Split wave error : output wave points is too large for wave " + wName )
				continue
			endif
			
			outprefix = wavePrefix
			
			if ( numWaves > 1 )
				outprefix = wavePrefix + num2istr( wcnt )
			endif
			
			cList = SplitWave( wName, outprefix, ccnt, npnts )
			
			cList = AddListItem( wName, cList, ";", inf )
		
		endfor
		
		NMMainHistory( "Split wave " + wname + " ( prefix " + NMQuotes( wavePrefix ) + " )", ccnt, cList, 0 )
		
		wList += cList
		
		if ( cancel == 1 )
			break // cancel channel loop
		endif
		
	endfor
	
	NMPrefixAdd( wavePrefix )
	ChanGraphsUpdate()
	
	return wList

End // NMSplitWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWavesHaveSameTimeScale()
	
	Variable ccnt, dx, lftx, npnts
	String cList
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( ( numChannels <= 0 ) || ( numWaves <= 0 ) )
		return 0
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		cList = NMWaveSelectList( ccnt )
		
		dx = GetXStats( "deltax" , cList )
		lftx = GetXStats( "leftx" , cList )
		npnts = GetXStats( "numpnts" , cList )
		
		if ( numtype( dx * lftx * npnts ) == 2 )
			return 0 // they are different
		endif
		
	endfor
	
	return 1
	
End // NMWavesHaveSameTimeScale

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWavesHaveNANs( tbgn, tend )
	Variable tbgn, tend // time begin and end, use ( -inf, inf ) for all time
	
	Variable ccnt, wcnt
	String wName, thisfxn = "NMWavesHaveNANs"
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	if ( ( numChannels <= 0 ) || ( numWaves <= 0 ) )
		return 0
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
		
			wName = NMWaveSelected( ccnt, wcnt )
			
			if ( strlen( wName ) == 0 )
				continue
			endif
			
			WaveStats /Q/Z/R=( tbgn, tend ) $wName
			
			if ( V_numNans > 0 )
				return 1
			endif
			
		endfor
		
	endfor
	
	return 0
	
End // NMWavesHaveNANs

//****************************************************************
//****************************************************************
//****************************************************************



