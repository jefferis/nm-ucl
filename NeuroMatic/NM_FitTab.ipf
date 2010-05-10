#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Fit Tab
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	Began 9 July 2007
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S FitPrefix( varName ) // tab prefix identifier
	String varName
	
	return "FT_" + varName
	
End // FitPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FitDF() // package full-path folder name

	return PackDF( "Fit" )
	
End // FitDF

//****************************************************************
//****************************************************************
//****************************************************************

Function FitTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable == 1 )
		CheckPackage( "Fit", 1 ) // declare globals if necessary
		ChanControlsDisable( CurrentNMChannel(), "000000" )
		DisableNMPanel( 1 )
		NMFitMake() // create tab controls if necessary
		NMFitUpdate()
	endif
	
	NMFitDisplay( -1, enable )
	
	if ( enable == 1 )
		AutoFit()
	endif

End // FitTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillFit( what )
	String what
	
	String df = FitDF()

	// TabManager will automatically kill objects that begin with appropriate prefix
	// place any other things to kill here.
	
	strswitch( what )
	
		case "waves":
			// kill any other waves here
			break
			
		case "folder":
			if ( DataFolderExists( df ) == 1 )
				KillDataFolder $df
			endif
			break
			
	endswitch

End // KillFit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitOverWrite()

	return 1 // NMOverWrite()
	
End // NMFitOverWrite

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitDisplay( chan, appnd )
	Variable chan // channel number ( -1 ) for current channel
	Variable appnd // 1 - append wave; 0 - remove wave
	
	Variable ccnt, drag = appnd
	String gName, df = FitDF()
	
	if ( DataFolderExists( df ) == 0 )
		return 0
	endif
	
	if ( ( NeuroMaticVar( "DragOn" ) == 0 ) || ( StringMatch( CurrentNMTabName(), "Fit" ) == 0 ) )
		drag = 0
	endif
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue // window does not exist
		endif

		RemoveFromGraph /Z/W=$gName DragTbgnY, DragTendY
		
	endfor

	gName = ChanGraphName( chan )
	
	NMDragEnable( drag, "DragTbgn", "", df+"Tbgn", "", gName, "bottom", "min", 65535, 0, 0 )
	NMDragEnable( drag, "DragTend", "", df+"Tend", "", gName, "bottom", "max", 65535, 0, 0 )
	
	if ( appnd == 0 )
		NMFitRemoveDisplayWaves()
	endif

End // NMFitDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitDisplayClear()

	String dwave = NMFitDisplayWaveName()
	String df = NMFitWaveDF()
	String wname = df + "W_sigma"
	
	if ( WaveExists( $dwave ) == 1 )
		Wave wtemp = $dwave
		wtemp = Nan
	endif
	
	if ( WaveExists( $wname ) == 1 )
		Wave wtemp = $wname
		wtemp = Nan
	endif
	
	NMFitRemoveDisplayWaves()
	
	NMDragClear( "DragTbgn" )
	NMDragClear( "DragTend" )

End // NMFitDisplayClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitRemoveDisplayWaves()

	Variable ccnt, wcnt
	String gName, wName

	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue
		endif
		
		GetWindow $gName wavelist
		
		if ( WaveExists( W_WaveList ) == 0 )
			continue
		endif
		
		Wave /T W_WaveList
		
		for ( wcnt = 0 ; wcnt < numpnts( W_WaveList ) ; wcnt += 1 )
		
			wName = W_WaveList[ wcnt ] [ 0 ]
			
			if ( ( StrSearch( wName, "Fit_", 0, 2 ) >= 0 ) || ( StrSearch( wName, "Res_", 0, 2 ) >= 0 ) )
				RemoveFromGraph /W=$gName /Z $wName
			endif
			
		endfor
		
	endfor
	
	KillWaves /Z W_WaveList
	
	return 0

End // NMFitRemoveDisplayWaves

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Global Variables, Strings and Waves
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckFit() // declare global variables

	return 0 // nothing to do
	
End // CheckFit

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFitVar( varName )
	String varName
	
	return CheckNMvar( FitDF()+varName, NMFitVar( varName ) )

End // CheckNMFitVar

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFitStr( varName )
	String varName
	
	return CheckNMstr( FitDF()+varName, NMFitStr( varName ) )

End // CheckNMFitStr

//****************************************************************
//****************************************************************
//****************************************************************

Function FitConfigs()

	String fname = "Fit"
			
	NMConfigVar( fname, "UseSubfolders", 1, "use subfolders when creating Fit result waves ( 0 ) no ( 1 ) yes ( use 0 for previous NM formatting )" )
	
End // FitConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitVar( varName )
	String varName
	
	Variable defaultVal = Nan
	
	strswitch( varName )
	
		case "UseSubfolders":
			defaultVal = 1
			break
	
		case "UserInput":
			defaultVal = 0
			break
			
		case "Tbgn":
			defaultVal = -inf
			break
			
		case "Tend":
			defaultVal = inf
			break
			
		case "Cursors":
			defaultVal = 0
			break
			
		case "FitAuto":
			defaultVal = 0
			break
			
		case "SaveFitWaves":
			defaultVal = 1
			break
			
		case "FullGraphWidth":
			defaultVal = 0
			break
			
		case "FitNumPnts":
			defaultVal = Nan
			break
			
		case "Residuals":
			defaultVal = 0
			break
			
		case "Print":
			defaultVal = 0
			break
			
		case "WeightStdv":
			defaultVal = 0
			break
			
		case "MaxIterations":
			defaultVal = 40
			break
			
		case "FitAllWavesPause":
			defaultVal = -1
			break
			
		case "CompactTableFormat":
			defaultVal = 1
			break
			
		case "ClearWavesSelect":
			defaultVal = 1
			break
			
		case "SynExpSign":
			defaultVal = 1 // ( 1 ) positive events ( -1 ) negative events
			break
			
		case "V_chisq":
			defaultVal = Nan
			break
			
		case "V_npnts":
			defaultVal = Nan
			break
			
		case "V_numNaNs":
			defaultVal = Nan
			break
			
		case "V_numINFs":
			defaultVal = Nan
			break
			
		case "V_startRow":
			defaultVal = Nan
			break
			
		case "V_endRow":
			defaultVal = Nan
			break
			
		default:
			NMDoAlert( "NMFitVar Error: no variable called " + NMQuotes( varName ) )
			return Nan
	
	endswitch
	
	return NumVarOrDefault( FitDF()+varName, defaultVal )
	
End // NMFitVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitStr( varName )
	String varName
	
	String defaultStr = "", df = FitDF()
	
	strswitch( varName )
	
		case "Equation":
			defaultStr = ""
			break
			
		case "Function":
			defaultStr = ""
			break
			
		case "FxnShort":
			defaultStr = StrVarOrDefault( df+"Function", "" )
			break
			
		case "FxnList":
			defaultStr = NMFitIgorList()
			break
			
		case "UserFxnList":
			defaultStr = ""
			break
	
		default:
			NMDoAlert( "NMFitStr Error: no variable called " + NMQuotes( varName ) )
			return ""
	
	endswitch
	
	return StrVarOrDefault( df+varName, defaultStr )
	
End // NMFitStr

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMFitVar( varName, value )
	String varName
	Variable value
	
	String thisfxn = "SetNMFitVar", df = FitDF()
	
	if ( strlen( varName ) == 0 )
		return NMError( 21, thisfxn, "varName", varName )
	endif
	
	if ( DataFolderExists( df ) == 0 )
		return NMError( 30, thisfxn, "FitDF", df )
	endif
	
	Variable /G $df+varName = value
	
	return 0
	
End // SetNMFitVar

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMFitStr( varName, strValue )
	String varName
	String strValue
	
	String thisfxn = "SetNMFitStr", df = FitDF()
	
	if ( strlen( varName ) == 0 )
		return NMError( 21, thisfxn, "varName", varName )
	endif
	
	if ( DataFolderExists( df ) == 0 )
		return NMError( 30, thisfxn, "FitDF", df )
	endif
	
	String /G $df+varName = strValue
	
	return 0
	
End // SetNMFitStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitWavePath( wName )
	String wName
	
	return FitDF() + "FT_" + wName
	
End // NMFitWavePath

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitNumParams()

	return NMFitFxnListNumParams( "" )

End // NMFitNumParams

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Fit Function Lists
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFxnList()

	Variable icnt
	String item, fname, userList = ""

	String flist = NMFitStr( "FxnList" )
	String user = NMFitFuncList() + NMFitStr( "UserFxnList" )

	if ( ItemsInList( flist ) == 0 )
		flist = NMFitIgorList()
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( user ) ; icnt += 1 )
	
		item = StringFromList( icnt, user )
		fname = StringByKey( "f", item, ":", "," )
		
		if ( exists( fname ) == 6 )
			userList = AddListItem( item, userList, ";", inf )
		endif
	
	endfor

	return flist + userList

End // NMFitFxnList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFxnListShort()
	
	return NMFitFxnListByKey( NMFitFxnList(), "f" )

End // NMFitFxnListShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFxnListByKey( fList, key )
	String fList
	String key
	
	Variable icnt
	String istr, kList = ""
	
	for ( icnt = 0 ; icnt < ItemsInList( fList ) ; icnt += 1 )
		istr = StringFromList( icnt, fList, ";" )
		istr = StringByKey( key, istr, ":", "," )
		kList = AddListItem( istr, kList, ";", inf )
	endfor

	return kList

End // NMFitFxnListByKey

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListWhichItem( fxn )
	String fxn
	
	return WhichListItem( fxn, NMFitFxnListShort(), ";", 0, 0 )
	
End // NMFitFxnListWhichItem

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListNumParams( fxn )
	String fxn
	
	if ( strlen( fxn ) == 0 )
		fxn = NMFitStr( "Function" )
	endif
	
	Variable item = NMFitFxnListWhichItem( fxn )
	
	if ( item < 0 )
		return 0
	endif
	
	String f = StringFromList( item, NMFitFxnList(), ";" )
	
	f = StringByKey( "n", f, ":", "," )
	
	return str2num( f )

End // NMFitFxnListNumParams

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListNumParamsSet( fxn, numParams )
	String fxn
	Variable numParams
	
	Variable oldNum = NMFitFxnListNumParams( fxn )
	
	if ( numParams == oldNum )
		return 0
	endif
	
	String fold = "f:" + fxn + ",n:" + num2istr( oldNum )
	String fnew = "f:" + fxn + ",n:" + num2istr( numParams )
	String fList = ReplaceString( fold, NMFitFxnList(), fnew )
	
	SetNMFitStr( "FxnList", fList )
	
End // NMFitFxnListNumParamsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitIgorList() // built-in Igor fitting functions
	
	return "f:Line,n:2;f:Poly,n:3;f:Gauss,n:4;f:Lor,n:4;f:Exp,n:3;f:DblExp,n:5;f:Exp_XOffset,n:3;f:DblExp_XOffset,n:5;f:Sin,n:4;f:HillEquation,n:4;f:Sigmoid,n:4;f:Power,n:3;f:LogNormal,n:4;"
	
End // NMFitIgorList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitIgorListShort()
	
	return NMFitFxnListByKey( NMFitIgorList(), "f" )

End // NMFitIgorListShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFuncList() // built-in Igor fitting functions
	
	return "f:NMSynExp3,n:7;f:NMSynExp4,n:9;"
	
End // NMFitFuncList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFuncListShort()
	
	return NMFitFxnListByKey( NMFitFuncList(), "f" )

End // NMFitFuncListShort

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Tab Panel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitMake() // create controls that will begin with appropriate prefix

	Variable x0 = 40, y0 = 205, xinc, yinc = 25, fs = NMPanelFsize()
	Variable taby = NMPanelTabY()
	
	y0 = taby + 55
	
	String df = FitDF()
	
	CheckNMFitVar( "UserInput" )
	CheckNMFitVar( "Tbgn" )
	CheckNMFitVar( "Tend" )
	CheckNMFitVar( "FitNumPnts" )
	CheckNMFitVar( "MaxIterations" )
	
	CheckNMFitStr( "Equation" )

	ControlInfo /W=NMPanel FT_FxnGroup // check first in a list of controls
	
	if ( V_Flag != 0 )
		return 0 // tab controls exist, return here
	endif

	DoWindow /F NMPanel
	
	GroupBox FT_FxnGroup, title = "Function", pos={x0-20,y0-23}, size={260,85}, win=NMpanel, fsize=fs
	
	PopupMenu FT_FxnMenu, pos={x0+210,y0+0*yinc}, size={0,0}, bodyWidth=200, fsize=14, proc=NMFitFxnPopup, win=NMpanel
	PopupMenu FT_FxnMenu, value=NMFitPopupList(), win=NMpanel, fsize=fs
	
	SetVariable FT_UserInput, title="", pos={x0+70,y0+1*yinc+10}, size={100,50}, limits={0,inf,0}, frame=1, win=NMpanel
	SetVariable FT_UserInput, value=$( df+"UserInput" ), proc=SetNMFitUserVariable, win=NMpanel, fsize=fs
	
	y0 += 95
	
	GroupBox FT_RangeGroup, title = "Range", pos={x0-20,y0-23}, size={260,75}, win=NMpanel, fsize=fs
	
	SetVariable FT_Tbgn, title="t_bgn:", pos={x0,y0+0*yinc}, size={115,50}, limits={-inf,inf,1}, win=NMpanel
	SetVariable FT_Tbgn, value=$( df+"Tbgn" ), proc=SetNMFitVariable, win=NMpanel, fsize=fs
	
	SetVariable FT_Tend, title="t_end:", pos={x0,y0+1*yinc}, size={115,50}, limits={-inf,inf,1}, win=NMpanel
	SetVariable FT_Tend, value=$( df+"Tend" ), proc=SetNMFitVariable, win=NMpanel, fsize=fs
	
	Button FT_ClearRange, pos={x0+140,y0+0*yinc}, title="Clear", size={60,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	
	Checkbox FT_Cursors, title="Cursors", pos={x0+140,y0+1*yinc}, size={200,50}, value=NMFitVar( "Cursors" ), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	
	y0 += 85
	
	GroupBox FT_FitWaveGroup, title = "Fit Waves", pos={x0-20,y0-23}, size={260,77}, win=NMpanel, fsize=fs
	
	Checkbox FT_FullGraphWidth, title="Full Graph Width", pos={x0,y0+0*yinc}, size={200,50}, value=NMFitVar( "SaveFitWaves" ), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	Checkbox FT_SaveFits, title="Save", pos={x0,y0+1*yinc}, size={200,50}, value=NMFitVar( "SaveFitWaves" ), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	Checkbox FT_Residuals, title="Residuals", pos={x0+65,y0+1*yinc}, size={200,50}, value=NMFitVar( "Residuals" ), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	
	SetVariable FT_FitNumPnts, title="Points:", pos={x0+135,y0+0*yinc}, size={90,50}, limits={0,inf,1}, win=NMpanel
	SetVariable FT_FitNumPnts, value=$( df+"FitNumPnts" ), proc=SetNMFitVariable, win=NMpanel, fsize=fs
	
	Button FT_Compute, pos={x0+155,y0+1*yinc}, title="Compute", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	
	y0 += 87
	
	GroupBox FT_FitExecuteGroup, title = "Execute", pos={x0-20,y0-23}, size={260,130}, win=NMpanel, fsize=fs
	
	Button FT_Fit, pos={x0-5,y0+0*yinc}, title="Fit", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button FT_Save, pos={x0+75,y0+0*yinc}, title="Save", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button FT_Clear, pos={x0+155,y0+0*yinc}, title="Clear", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button FT_FitAll, pos={x0-5,y0+1*yinc}, title="Fit All", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button FT_PlotAll, pos={x0+75,y0+1*yinc}, title="Plot All", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	Button FT_Table, pos={x0+155,y0+1*yinc}, title="Table", size={70,20}, proc=NMFitButton, win=NMpanel, fsize=fs
	
	y0 += 30
	
	Checkbox FT_FitAuto, title="Auto Fit", pos={x0+10,y0+1*yinc}, size={200,50}, value=NMFitVar( "FitAuto" ), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	Checkbox FT_Weight, title="Stdv Weighting", pos={x0+120,y0+1*yinc}, size={200,50}, value=NMFitVar( "WeightStdv" ), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	Checkbox FT_Print, title="Print Results", pos={x0+10,y0+2*yinc}, size={200,50}, value=NMFitVar( "Print" ), proc=NMFitCheckBox, win=NMPanel, fsize=fs
	
	SetVariable FT_MaxIter, title="max iter:", pos={x0+120,y0+2*yinc}, size={100,50}, limits={5,500,1}, win=NMpanel
	SetVariable FT_MaxIter, value=$( df+"MaxIterations" ), proc=SetNMFitVariable, win=NMpanel, fsize=fs

End // NMFitMake

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitUpdate()

	Variable igorFxn
	String ttl

	String fxn = NMFitStr( "Function" )
	String eq = NMFitStr( "Equation" )
	String flist = NMFitPopupList()
	
	Variable fmode = WhichListItem( fxn, flist, ";", 0, 0 )
	
	if ( ( strlen( fxn ) > 0 ) && ( WhichListItem( fxn, NMFitIgorListShort(), ";", 0, 0 ) >= 0 ) )
		igorFxn = 1
	endif
	
	ttl = "Function"
	
	if ( strlen( eq ) > 0 )
		ttl = "F=" + eq
	endif
	
	GroupBox FT_FxnGroup, win=NMpanel, title=ttl
	
	if ( fmode < 0 )
		fmode = 0
	endif
	
	fmode += 1
	
	PopupMenu FT_FxnMenu, win=NMpanel, mode=( fmode ), value =NMFitPopupList()
	
	strswitch( fxn )
	
		case "Poly":
			SetVariable FT_UserInput, title="Terms:", frame=1, noedit=0, win=NMpanel
			break
			
		case "Exp_XOffset":
		case "DblExp_XOffset":
			SetVariable FT_UserInput, title="X0:", frame=1, noedit=0, win=NMpanel
			break
			
		case "Sin":
			SetVariable FT_UserInput, title="Pnts/Cycle:", frame=1, noedit=0, win=NMpanel
			break
	
		default:
			SetVariable FT_UserInput, title="Terms:", frame=0, noedit=1, win=NMpanel
			
	endswitch
	
	if ( ( strlen( fxn ) > 0 ) && ( igorFxn == 0 ) )
		SetVariable FT_UserInput, title="Terms:", frame=1, noedit=0, win=NMpanel
	endif
	
	Checkbox FT_Cursors, value=NMFitVar( "Cursors" ), win=NMPanel
	Checkbox FT_FullGraphWidth, value=NMFitVar( "FullGraphWidth" ), win=NMPanel
	Checkbox FT_SaveFits, value=NMFitVar( "SaveFitWaves" ), win=NMPanel
	Checkbox FT_Residuals, value=NMFitVar( "Residuals" ), win=NMPanel
	
	Checkbox FT_FitAuto, value=NMFitVar( "FitAuto" ), win=NMPanel
	Checkbox FT_Print, value=NMFitVar( "Print" ), win=NMPanel
	Checkbox FT_Weight, value=NMFitVar( "WeightStdv" ), win=NMPanel
	
	NMFitCursorsSetTimes()
	
End // NMFitUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitPopupList()
	
	return " ;" + NMFitFxnListShort() + "---;Other;Remove from List;"
	
End // NMFitPopupList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	String fxn = ReplaceString( "FT_", ctrlName, "" )
		
	NMFitCall( fxn, popStr )
			
End // NMFitPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	strswitch( popStr )
		case "---":
			NMFitUpdate()
			break
		default:
			NMFitFxnCall( popStr )
	endswitch
			
End // NMFitFxnPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( "FT_", ctrlName, "" )
	
	NMFitCall( fxn, "" )
	
End // NMFitButton

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMFitVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = ReplaceString( "FT_", ctrlName, "" )
	
	NMFitCall( fxn, varStr )
	
End // SetNMFitVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMFitUserVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = NMFitStr( "Function" ) 
	
	NMFitFxnUserValueCall( fxn, varNum )
	
End // SetNMFitUserVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	String fxn = ReplaceString( "FT_", ctrlName, "" )
	
	NMFitCall( fxn, num2istr( checked ) )
	
End // NMFitCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnCall( select )
	String select
	
	strswitch( select )
		case "Add to List":
		case "Other":
			NMFitUserFxnAddCall()
			break
		case "Remove from List":
			NMFitFxnListRemoveCall()
			break
		default:
			NMFitFunctionSetCall( select )
			AutoFit()
	endswitch

End // NMFitFxnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnUserValueCall( fxn, value )
	String fxn // function name
	Variable value
	
	strswitch( fxn )
	
		case "Poly":
			NMFitPolyNumSetCall( value )
			AutoFit()
			break
			
		case "Exp_XOffset":
		case "DblExp_XOffset":
			AutoFit()
			break
			
		case "Sin":
			NMFitSinPntsPerCycleCall( value )
			AutoFit()
			break
			
		default:
			NMFitFxnListNumParamsSet( fxn, value )
			NMFitWaveTable( 0 )
			AutoFit()
			
	endswitch
			
End // NMFitFxnUserValueCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCall( fxn, select )
	String fxn // function name
	String select // parameter string variable
	
	Variable snum = str2num( select ) // parameter variable number
	
	strswitch( fxn )
			
		case "Tbgn":
			NMFitTbgnSetCall( snum )
			AutoFit()
			break
			
		case "Tend":
			NMFitTendSetCall( snum )
			AutoFit()
			break
			
		case "ClearRange":
			NMFitRangeClearCall()
			AutoFit()
			break
			
		case "Cursors":
			NMFitCursorsSetCall()
			AutoFit()
			break
			
		case "FullGraphWidth":
			NMFitFullGraphWidthSetCall()
			break
			
		case "SaveFits":
			NMFitSaveFitsSetCall()
			break
			
		case "Residuals":
			NMFitResidualsSetCall()
			break
			
		case "FitNumPnts":
			NMFitWaveNumPntsCall( snum )
			break
			
		case "MaxIter":
			NMFitMaxIterationsCall( snum )
			break
			
		case "FitAuto":
			NMFitAutoSetCall()
			break
			
		case "Print":
			NMFitPrintSetCall()
			break
			
		case "Weight":
			NMFitWeightSetCall()
			AutoFit()
			break
			
		case "Compute":
			NMFitWaveComputeCall()
			break
			
		case "Fit":
			NMFitWaveCall()
			break
			
		case "FitAll":
			NMFitAllWavesCall()
			break
		
		case "Save":
			NMFitSaveCurrentCall()
			break
		
		case "Clear":
		case "ClearAll":
			NMFitClearCall()
			break
			
		case "Plot":
			NMFitPlotAll( 0 )
			break
			
		case "PlotAll":
			NMFitPlotAll( 1 )
			break
			
		case "Table":
			NMFitSubfolderTableCall()
			break
			
		default:
			NMDoAlert( "NMFitCall: unrecognized function call: " + fxn )

	endswitch
	
End // NMFitCall

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Set Global Values Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitUserFxnAddCall()

	String fxn = "", cmdstr = ""
	Variable numParams = 2
	
	Prompt fxn, "function name:"
	Prompt numParams, "number of fitting parameters:"
	DoPrompt "Add Function", fxn, numParams
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	cmdstr = NMCmdStr( fxn, cmdstr )
	cmdstr = NMCmdNum( numParams, cmdstr )
	
	NMCmdHistory( "NMFitUserFxnAdd", NMCmdStr( fxn,"" ) )
	
	return NMFitUserFxnAdd( fxn, numParams )

End // NMFitUserFxnAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitUserFxnAdd( fxn, numParams )
	String fxn
	Variable numParams
	
	Variable item
	String userList, fList, thisfxn = "NMFitUserFxnAdd"
	
	if ( strlen( fxn ) == 0 )
		return NMError( 21, thisfxn, "fxn", fxn )
	endif
	
	item = NMFitFxnListWhichItem( fxn )
	
	if ( item >= 0 )
		return 0 // name already exists
	endif
	
	if ( ( numtype( numParams ) > 0 ) || ( numParams < 1 ) )
		return NMError( 10, thisfxn, "numParams", num2istr( numParams ) )
	endif
	
	userList = NMFitStr( "UserFxnList" )
	
	fList = AddListItem( "f:" + fxn + ",n:" + num2istr( numParams ), userList, ";", inf )
	
	SetNMFitStr( "UserFxnList", fList )
	
	NMFitFunctionSet( fxn )
	
	NMFitUpdate()
	
	return 0
	
End // NMFitUserFxnAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListRemoveCall()
	String fxn = ""
	
	Prompt fxn, "remove:", popup NMFitFxnListShort()
	DoPrompt "Remove Function", fxn
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	NMCmdHistory( "NMFitFxnListRemove", NMCmdStr( fxn,"" ) )
	
	return NMFitFxnListRemove( fxn )
	
End // NMFitFxnListRemoveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListRemove( fxn )
	String fxn
	
	Variable item = NMFitFxnListWhichItem( fxn )
	
	if ( item < 0 )
		return 0
	endif
	
	String fList = RemoveListItem( item, NMFitFxnList(), ";" )
	
	SetNMFitStr( "FxnList", fList )
	
	NMFitUpdate()
	
	return 0
	
End // NMFitFxnListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPolyNumSetCall( numParams )
	Variable numParams
	
	NMCmdHistory( "NMFitPolyNumSet", NMCmdNum( numParams,"" ) )
	
	return NMFitPolyNumSet( numParams )
	
End // NMFitPolyNumSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPolyNumSet( numParams )
	Variable numParams

	Variable icnt
	String pList = ""
	
	if ( ( numtype( numParams ) > 0 ) || ( numParams < 3 ) )
		numParams = 3
	endif
	
	NMFitFxnListNumParamsSet( "Poly", numParams )
	
	SetNMFitVar( "UserInput", numParams )
	SetNMFitStr( "Function", "Poly" )
	SetNMFitStr( "FxnShort", "Poly" )
	SetNMFitStr( "Equation", "K0+K1*x+K2*x^2..." )
	
	NMFitWaveTable( 1 )
	NMFitCoefNamesSet( pList )
	NMFitUpdate()
	
	return numParams

End // NMFitPolyNumSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSinPntsPerCycleCall( pnts )
	Variable pnts
	
	NMCmdHistory( "NMFitSinPntsPerCycle", NMCmdNum( pnts,"" ) )
	
	return NMFitSinPntsPerCycle( pnts )
	
End // NMFitSinPntsPerCycleCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSinPntsPerCycle( pnts )
	Variable pnts
	
	String thisfxn = "NMFitSinPntsPerCycle"
	
	if ( numtype( pnts ) > 0 )
		pnts = 7
	endif
	
	SetNMFitVar( "UserInput", pnts )
	
	return pnts
	
End // NMFitSinPntsPerCycle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFunctionSetCall( fxn )
	String fxn
	
	strswitch( fxn )
		case "NMSynExp3":
		case "NMSynExp4":
			NMSynExpSignCall()
			break
	endswitch
	
	NMCmdHistory( "NMFitFunctionSet", NMCmdStr( fxn,"" ) )
	
	return NMFitFunctionSet( fxn )

End // NMFitFunctionSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFunctionSet( fxn )
	String fxn
	
	Variable numParams
	String sfxn = fxn, pList = "", eq = ""
	
	String fList = NMFitFxnListShort()
	
	NMFitWaveTableSave()
	
	if ( StringMatch( fxn, " " ) == 1 )
		SetNMFitVar( "UserInput", 0 )
		SetNMFitStr( "Function", "" )
		SetNMFitStr( "FxnShort", "" )
		SetNMFitStr( "Equation", "" )
	endif
	
	if ( WhichListItem( fxn, fList ) < 0 )
		NMFitUpdate()
		return 0
	endif
	
	strswitch( fxn )
		case "Line":
			pList = "A;B;"
			eq = "A+Bx"
			break
		case "Poly":
			return NMFitPolyNumSet( 3 )
		case "Gauss":
			pList = "Y0;A;X0;W;"
			eq = "Y0+A*exp( -( ( x -X0 )/W )^2 )"
			break
		case "Lor":
			pList = "Y0;A;X0;B;"
			eq = "Y0+A/( ( x-X0 )^2+B )"
			break
		case "Exp":
			pList = "Y0;A;InvT;"
			eq = "Y0+A*exp( -InvT*x )"
			break
		case "DblExp":
			sfxn = "2Exp"
			pList = "Y0;A1;InvT1;A2;InvT2;"
			eq = "Y0+A1*exp( -InvT1*x )+A2*exp( -InvT2*x )"
			break
		case "Exp_XOffset":
			sfxn = "Exp"
			pList = "Y0;A;T;"
			eq = "Y0+A*exp( -( x-X0 )/T )"
			break
		case "DblExp_XOffset":
			sfxn = "2Exp"
			pList = "Y0;A1;T1;A2;T2;"
			eq = "Y0+A1*exp( -( x-X0 )/T1 )+A2*exp( -( x-X0 )/T2 )"
			break
		case "Sin":
			pList = "Y0;A;F;P;"
			eq = "Y0+A*sin( F*x+P )"
			break
		case "HillEquation":
			sfxn = "Hill"
			pList = "B;M;R;XH;"
			eq = "B+( M-B )*( x^R/( 1+( x^R+XH^R ) ) )"
			break
		case "Sigmoid":
			sfxn = "Sig"
			pList = "B;M;XH;R;"
			eq = "B+M/( 1+exp( -( x-XH )/R ) )"
			break
		case "Power":
			sfxn = "Pow"
			pList = "Y0;A;P;"
			eq = "Y0+A*x^P"
			break
		case "LogNormal":
			sfxn = "Log"
			pList = "Y0;A;X0;W;"
			eq = "Y0+A*exp( -( ln( x/X0 )/W )^2 )"
			break
		case "NMSynExp3":
			sfxn = "Syn3"
			pList = "X0;TR1;N;A1;TD1;A2;TD2;"
			eq = "( 1-exp( -( x-X0 )/TR1 ) )^N*( A1*exp( -( x-X0 )/TD1 )+A2*exp( -( x-X0 )/TD2 ) )"
			break
		case "NMSynExp4":
			sfxn = "Syn4"
			pList = "X0;TR1;N;A1;TD1;A2;TD2;A3;TD3;"
			eq = "( 1-exp( -( x-X0 )/TR1 ) )^N*( A1*exp( -( x-X0 )/TD1 )+A2*exp( -( x-X0 )/TD2 ) )+A3*exp( -( x-X0 )/TD3 ) )"
			break
		default:
			sfxn = fxn
			eq = ""
	endswitch
	
	numParams = NMFitFxnListNumParams( fxn )
	
	SetNMFitVar( "UserInput", numParams )
	SetNMFitStr( "Function", fxn )
	SetNMFitStr( "FxnShort", sfxn )
	SetNMFitStr( "Equation", eq )
	
	NMHistory( fxn + ": " + eq )
	
	NMFitWaveTable( 1 )
	NMFitCoefNamesSet( pList )
	NMFitGuess()
	NMFitX0Set()
	NMFitUpdate()
	
	return 0
	
End // NMFitFunctionSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitX0Set()

	Variable x0 = 0
	Variable tbgn = NMFitVar( "Tbgn" )
	
	Variable currentChan = CurrentNMChannel()
	
	String gName = ChanGraphName( currentChan )
	String wName = ChanDisplayWave( currentChan )
	
	strswitch( NMFitStr( "Function" ) )
	
		case "Exp_XOffset":
		case "DblExp_XOffset":
			break
	
		default:
			return 0
			
	endswitch

	if ( ( NMFitVar( "Cursors" ) == 1 ) && ( strlen( CsrInfo( A, gName ) ) > 0 ) )
		x0 = xcsr( A )
	elseif ( numtype( tbgn ) == 0 )
		x0 = tbgn
	else
		if ( WaveExists( $wName ) == 1 )
			x0 = leftx( $wName )
		endif
	endif
	
	SetNMFitVar( "UserInput", x0 )
	
	return x0

End // NMFitX0Set

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitTbgnSetCall( tbgn )
	Variable tbgn
	
	NMCmdHistory( "NMFitTbgnSet", NMCmdNum( tbgn,"" ) )
	
	return NMFitTbgnSet( tbgn )
	
End // NMFitTbgnSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitTbgnSet( tbgn )
	Variable tbgn
	
	if ( numtype( tbgn ) > 0 )
		tbgn = -inf
	endif
	
	SetNMFitVar( "Tbgn", tbgn )
	
	NMFitX0Set()
	
	return tbgn
	
End // NMFitTbgnSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitTendSetCall( tend )
	Variable tend
	
	NMCmdHistory( "NMFitTendSet", NMCmdNum( tend,"" ) )
	
	return NMFitTendSet( tend )
	
End // NMFitTendSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitTendSet( tend )
	Variable tend
	
	if ( numtype( tend ) > 0 )
		tend = inf
	endif
	
	SetNMFitVar( "Tend", tend )
	
	NMFitX0Set()
	
	return tend
	
End // NMFitTendSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitRangeClearCall()

	NMCmdHistory( "NMFitRangeClear", "" )
	
	return NMFitRangeClear()

End // NMFitRangeClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitRangeClear()
	
	SetNMFitVar( "Tbgn", -inf )
	SetNMFitVar( "Tend", inf )
	
	NMFitX0Set()
	
	return 0

End // NMFitRangeClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCursorsSetCall()

	Variable on = BinaryInvert( NMFitVar( "Cursors" ) )
	
	NMCmdHistory( "NMFitCursorsSet", NMCmdNum( on,"" ) )

	return NMFitCursorsSet( on )

End // NMFitCursorsSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCursorsSet( on )
	Variable on
	
	Variable currentChan = CurrentNMChannel()
	
	String gName = ChanGraphName( currentChan )
	String df = FitDF()
	
	on = BinaryCheck( on )
	
	SetNMFitVar( "Cursors", on )
	
	if ( on == 1 )
		ShowInfo /W=$gName
		SetNMFitVar( "TbgnOld", NumVarOrDefault( df+"Tbgn", Nan ) )
		SetNMFitVar( "TendOld", NumVarOrDefault( df+"Tend", Nan ) )
		NMFitCursorsSetTimes()
	else
		SetNMFitVar( "Tbgn", NumVarOrDefault( df+"TbgnOld", Nan ) )
		SetNMFitVar( "Tend", NumVarOrDefault( df+"TendOld", Nan ) )
	endif
	
	return on

End // NMFitCursorsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCursorsSetTimes()

	Variable currentChan = CurrentNMChannel()

	String gName = ChanGraphName( currentChan )

	if ( NMFitVar( "Cursors" ) == 0 )
		return 0
	endif

	if ( strlen( CsrInfo( A, gName ) ) > 0 )
		SetNMFitVar( "Tbgn", xcsr( A, gName ) )
	endif
	
	if ( strlen( CsrInfo( B, gName ) ) > 0 )
		SetNMFitVar( "Tend", xcsr( B, gName ) )
	endif
	
	return 0
	
End // NMFitCursorsSetTimes

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFullGraphWidthSetCall()

	Variable on = BinaryInvert( NMFitVar( "FullGraphWidth" ) )
	
	NMCmdHistory( "NMFitFullGraphWidthSet", NMCmdNum( on,"" ) )

	return NMFitFullGraphWidthSet( on )

End // NMFitFullGraphWidthSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFullGraphWidthSet( on )
	Variable on
	
	on = BinaryCheck( on )
	
	SetNMFitVar( "FullGraphWidth", on )
	
	return on

End // NMFitFullGraphWidthSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveNumPntsCall( npnts )
	Variable npnts
	
	NMCmdHistory( "NMFitWaveNumPntsSet", NMCmdNum( npnts, "" ) )
	
	return NMFitWaveNumPntsSet( npnts )
	
End // NMFitWaveNumPntsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveNumPntsSet( npnts )
	Variable npnts
	
	if ( ( numtype( npnts ) > 0 ) || ( npnts <= 1 ) )
		npnts = Nan
	endif
	
	SetNMFitVar( "FitNumPnts", npnts )
	
	return npnts
	
End // NMFitWaveNumPntsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitMaxIterationsCall( mi )
	Variable mi
	
	NMCmdHistory( "NMFitMaxIterationsSet", NMCmdNum( mi, "" ) )
	
	return NMFitMaxIterationsSet( mi )
	
End // NMFitMaxIterationsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitMaxIterationsSet( mi )
	Variable mi
	
	if ( ( numtype( mi ) > 0 ) || ( mi < 5 ) )
		mi = 5
	endif
	
	SetNMFitVar( "MaxIterations",  mi )
	
	return mi
	
End // NMFitMaxIterationsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSaveFitsSetCall()

	Variable on = BinaryInvert( NMFitVar( "SaveFitWaves" ) )
	
	NMCmdHistory( "NMFitSaveFitsSet", NMCmdNum( on,"" ) )

	return NMFitSaveFitsSet( on )

End // NMFitSaveFitsSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSaveFitsSet( on )
	Variable on
	
	on = BinaryCheck( on )
	
	SetNMFitVar( "SaveFitWaves", on )
	
	return on

End // NMFitSaveFitsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitResidualsSetCall()

	Variable on = BinaryInvert( NMFitVar( "Residuals" ) )
	
	NMCmdHistory( "NMFitResidualsSet", NMCmdNum( on,"" ) )

	return NMFitResidualsSet( on )

End // NMFitResidualsSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitResidualsSet( on )
	Variable on
	
	on = BinaryCheck( on )
	
	SetNMFitVar( "Residuals", on )
	
	return on

End // NMFitResidualsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPrintSetCall()

	Variable on = BinaryInvert( NMFitVar( "Print" ) )
	
	NMCmdHistory( "NMFitPrintSet", NMCmdNum( on,"" ) )

	return NMFitPrintSet( on )

End // NMFitPrintSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPrintSet( on )
	Variable on
	
	on = BinaryCheck( on )
	
	SetNMFitVar( "Print", on )
	
	return on

End // NMFitPrintSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitAutoSetCall()

	Variable on = BinaryInvert( NMFitVar( "FitAuto" ) )
	
	NMCmdHistory( "NMFitAutoSet", NMCmdNum( on,"" ) )

	return NMFitAutoSet( on )

End // NMFitAutoSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitAutoSet( on )
	Variable on
	
	on = BinaryCheck( on )
	
	SetNMFitVar( "FitAuto", on )
	
	return on

End // NMFitAutoSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWeightSetCall()

	Variable on = BinaryInvert( NMFitVar( "WeightStdv" ) )
	
	if ( on == 1 )
		NMDoAlert( "Note: to use this option, weight waves must have the same name as the data waves, but with \"Stdv_\" or \"InvStdv_\" as a prefix ( i.e. Stdv_Data0 )." )
	endif
	
	NMCmdHistory( "NMFitWeightSet", NMCmdNum( on,"" ) )

	return NMFitWeightSet( on )

End // NMFitWeightSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWeightSet( on )
	Variable on
	
	on = BinaryCheck( on )
	
	SetNMFitVar( "WeightStdv", on )
	
	return on

End // NMFitWeightSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSynExpSignCall()

	Variable signValue = NMFitVar( "SynExpSign" )
	String signStr, vlist = ""
	
	if ( signValue == -1 )
		signStr = "negative"
	else
		signStr = "positive"
	endif
	
	Prompt signStr,"amplitude sign of your data waveform:", popup, "positive;negative"
	DoPrompt "SynExp Sign Value", signStr
	 	
 	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	if ( StringMatch( signStr, "negative" ) == 1 )
		signValue = -1
	else
		signValue = 1
	endif
	
	vlist = NMCmdNum( signValue, vlist )
	NMCmdHistory( "NMSynExpSign", vlist )
	
	return NMSynExpSign( signValue )

End // NMSynExpSignCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSynExpSign( signValue )
	Variable signValue
	
	if ( signValue == -1 )
		SetNMFitVar( "SynExpSign", -1 )
	else
		SetNMFitVar( "SynExpSign", 1 )
	endif
	
End // NMSynExpSign

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Curve Fitting Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function AutoFit()
	
	String gName = ChanGraphName( CurrentNMChannel() )
	String fitWave = NMFitWaveName( CurrentNMWave() )
	
	NMFitDisplayClear()
	
	if ( NMFitVar( "FitAuto" ) == 1 )
		NMFitWave()
	else
		if ( ( WinType( gName ) == 1 ) && ( WaveExists( $fitWave ) == 1 ) )
			AppendToGraph /W=$gName $fitWave
		endif
	endif
	
	NMDragUpdate( "DragTbgn" )
	NMDragUpdate( "DragTend" )

End // AutoFit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitAllWavesCall()

	Variable p, pause
	
	Variable pauseMode = NMFitVar( "FitAllWavesPause" )
	Variable pauseValue = 0
	
	if ( NMNumActiveWaves() <= 0 )
		NMDoAlert( "No waves selected!" )
		return -1
	endif
	
	if ( pauseMode > 0 )
		p = 2
		pauseValue = pauseMode
	elseif ( pauseMode < 0 )
		p = 3
		pauseValue = 0
	else
		p = 1
		pauseValue = 0
	endif
	
	Prompt p, "pause after each fit?", popup "no;yes;yes, with OK prompt;"
	Prompt pauseValue, "pause time ( sec ):"
	
	DoPrompt "Fit All Waves", p, pauseValue
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	switch( p )
		case 1:
			pauseMode = 0
			break
		case 2:
			pauseMode = abs( pauseValue )
			break
		case 3:
			pauseMode = -1
			break
	endswitch
	
	SetNMFitVar( "FitAllWavesPause", pauseMode )
	
	NMCmdHistory( "NMFitAllWaves", NMCmdNum( pauseMode, "" ) )

	Variable returnVar = NMFitAllWaves( pauseMode )
	
	if ( NMFitVar( "SaveFitWaves" ) == 1 )
		NMFitPlotAll( 1 )
	endif
	
	return returnVar

End // NMFitAllWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitAllWaves( pause )
	Variable pause // ( 0 ) no pause ( > 0 ) pause for given sec ( < 0 ) pause with OK prompt

	Variable wcnt, changeChan, error
	String wName, tName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable numChannels = NMNumChannels()
	Variable nwaves = NMNumWaves()
	Variable currentWave = CurrentNMWave()
	Variable currentChan = CurrentNMChannel()
	
	Variable drag = NeuroMaticVar( "DragOn" )
	
	if ( NMPrefixFolderAlert() == 0 )
		return -1
	endif
	
	if ( NMNumActiveWaves() <= 0 )
		NMDoAlert( "No Waves Selected!" )
		return -1
	endif
	
	if ( numtype( pause ) > 0 )
		pause = 0
	endif
		
	tName = NMFitTableName()
	
	if ( WinType( tName ) > 0 )
		DoWindow /K $tName
	endif
	
	DoWindow /F $ChanGraphName( currentChan )
	
	if ( drag == 1 )
		NMDragOn( 0 )
		NMDragClear( "DragTbgn" )
		NMDragClear( "DragTend" )
	endif

	SetNeuroMaticStr( "ProgressStr", "Fit Chan " + ChanNum2Char( currentChan ) )
	
	for ( wcnt = 0 ; wcnt < nwaves ; wcnt += 1 )
		
		if ( ( pause >= 0 ) && ( CallNMProgress( wcnt, nwaves ) == 1 ) )
			break
		endif
		
		wName = NMWaveSelected( currentChan, wcnt )
		
		if ( strlen( wName ) == 0 )
			continue // wave not selected, or does not exist... go to next wave
		endif
		
		NMCurrentWaveSetNoUpdate( wcnt )
		
		ChanGraphUpdate( currentChan, 1 )
		
		error = NMFitWave()
		
		DoUpdate
		
		if ( pause < 0 )
			
			DoAlert 2, "Save results?"
			
			if ( V_flag == 1 )
				NMFitSaveCurrent()
			elseif ( V_flag == 3 )
				break // cancel
			endif
			
			continue
			
		else
		
			NMFitSaveCurrent()
			
		endif
		
		if ( pause > 0 )
			NMwaitMSTimer( pause*1000 )
		endif
			
		if ( error == 0 )
			NMFitSaveCurrent()
		endif
		
	endfor
	
	if ( drag == 1 )
		NMDragOn( 1 )
		NMDragUpdate( "DragTbgn" )
		NMDragUpdate( "DragTend" )
	endif
	
	NMCurrentWaveSet( currentWave )
	
	DoWindow /F $tName
	
	return 0

End // NMFitAllWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitWaveDF() // directory where curve fitting is performed
	
	//return CurrentNMFolder( 1 )

	return NMDF() // where display waves are

End // NMFitWaveDF

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveCall()

	NMCmdHistory( "NMFitWave", "" )

	return NMFitWave()

End // NMFitWaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWave()

	Variable pbgn, pend, icnt, changeFolder
	String wsigma, guessName, thisfxn = "NMFitWave"

	String fit = "CurveFit ", quiet = "", polynom = "", guess = "", region = "", cmd = "", fitpnts = "", fitw = "", resid = ""
	String fullgraph = "", hold = "", const = "", cycle = "", xw = "", weightflag = "", weightwave = "", coef = "", constraints = ""
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	String currentWaveName = CurrentNMWaveName()
	String wName = ChanDisplayWave( currentChan )
	String gName = ChanGraphName( currentChan )
	String sourceWave = NMChanWaveName( currentChan, currentWave )
	
	Variable numParams = NMFitNumParams()
	Variable userinput = NMFitVar( "UserInput" )
	Variable weight = NMFitVar( "WeightStdv" )
	Variable tbgn = NMFitVar( "Tbgn" )
	Variable tend = NMFitVar( "Tend" )
	Variable fitNumPnts = NMFitVar( "FitNumPnts" )
	Variable fullGraphWidth = NMFitVar( "FullGraphWidth" )
	Variable residuals = NMFitVar( "Residuals" )
	Variable maxIter = NMFitVar( "MaxIterations" )
	
	String fxn = NMFitStr( "Function" )
	String xwave = NMXwave()
	
	String saveDF = CurrentNMFolder( 1 )
	String df = NMFitWaveDF()
	
	NMFitWaveTable( 0 )
	NMFitCursorsSetTimes()
	NMFitRemoveDisplayWaves()
	
	if ( strlen( fxn ) == 0 )
		return NMError( 21, thisfxn, "fxn", fxn )
	endif
	
	if ( ( numtype( numParams ) > 0 ) || ( numParams <= 0 ) )
		return NMError( 10, thisfxn, "numParams", num2istr( numParams ) )
	endif
	
	if ( WaveExists( $wName ) == 0 )
		return NMError( 1, thisfxn, "wName", wName )
	endif
	
	if ( strlen( currentWaveName ) == 0 )
		return NMError( 21, thisfxn, "currentWaveName", currentWaveName )
	endif
	
	if ( StringMatch( df, saveDF ) == 0 )
		changeFolder = 1
	endif
	
	if ( strlen( xwave ) > 0 )
	
		if ( WaveExists( $xwave ) == 0 )
			return NMError( 1, thisfxn, "xwave", xwave )
		endif
		
		if ( ( numpnts( $xwave ) != numpnts( $wName ) ) )
			return NMError( 5, thisfxn, "xwave", xwave )
		endif
		
		xw = "/X=" + saveDF + xwave
		
	endif
	
	DoWindow /F $gName
	
	if ( ( numtype( tbgn ) == 0 ) || ( numtype( tend ) == 0 ) )
	
		if ( strlen( xwave ) == 0 )
		
			region = "(" + num2str( tbgn ) + "," + num2str( tend ) + ") "
			
		elseif ( WaveExists( $xwave ) == 1 )
		
			Wave xtemp = $xwave
			
			pbgn = 0
			pend = numpnts( xtemp ) - 1
			
			if ( numtype( tbgn ) == 0 )
			
				for ( icnt = 0 ; icnt < numpnts( xtemp ) ; icnt += 1 )
					if ( xtemp[icnt] >= tbgn )
						pbgn = icnt
						break
					endif
				endfor
			
			endif
			
			if ( numtype( tend ) == 0 )
			
				for ( icnt = numpnts( xtemp ) - 1 ; icnt > 0 ; icnt -= 1 )
					if ( xtemp[icnt] <= tend )
						pend = icnt
						break
					endif
				endfor
				
			endif
			
			region = "[" + num2istr( pbgn ) + "," + num2istr( pend ) + "] "
			
			xw += region
		
		endif
		
	endif
	
	if ( NMFitVar( "Cursors" ) == 1 )
	
		if ( ( strlen( CsrInfo( A, gName ) ) == 0 ) && ( strlen( CsrInfo( B, gName ) ) == 0 ) )
			return NMError( 90, thisfxn, "cannot locate Cursor information on current graph", "" )
		endif
		
		pbgn = pcsr( A )
		pend = pcsr( B )
		
		if ( pbgn < 0 )
			pbgn = 0
		endif
	
		if ( pend >= numpnts( $wName ) )
			pend = numpnts( $wName ) - 1
		endif
		
		region = "[" + num2istr( pbgn ) + "," + num2istr( pend ) + "] "
		
	endif
	
	if ( NMFitVar( "Print" ) == 0 )
		quiet = "/Q "
	endif
	
	wsigma = df + "W_sigma"
	
	if ( WaveExists( $wsigma ) == 1 )
		Wave wtemp = $wsigma
		wtemp = Nan
	endif
	
	guessName = NMFitWavePath( "guess" )
	
	if ( WaveExists( $guessName ) == 0 )
		return NMError( 1, thisfxn, "guessName", guessName )
	endif
	
	Wave FT_guess = $guessName
	Wave FT_coef = $NMFitWavePath( "coef" )
	Wave FT_sigma = $NMFitWavePath( "sigma" )
	Wave FT_hold = $NMFitWavePath( "hold" )
	
	if ( WhichListItem( fxn, NMFitIgorListShort() ) < 0 )
	
		fit = "FuncFit "
		
		if ( NumType( sum( FT_guess ) ) > 0 )
			return NMError( 90, thisfxn, "you must provide initial guesses for user-defined equations", "" )
		endif
		
	endif
	
	FT_sigma = Nan
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
		if ( numtype( FT_guess[icnt] ) == 0 )
			FT_coef[icnt] = FT_guess[icnt]
			guess = "/G "
		else
			FT_coef[icnt] = Nan
		endif
	endfor
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
		if ( FT_hold[icnt] == 1 )
			hold = "/H=\""
		endif
	endfor
	
	if ( strlen( hold ) > 0 )
	
		for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
			if ( FT_hold[icnt] == 1 )
				FT_coef[icnt] = FT_guess[icnt]
				hold += "1"
			else
				hold += "0"
			endif
		endfor
		
		hold += "\" "
	
	endif
	
	strswitch( fxn )
	
		case "poly":
			fxn += " " + num2istr( numParams ) + ","
			break
			
		case "Exp_XOffset":
		case "DblExp_XOffset":
			const = "/K={" + num2str( userinput ) + "} "
			break
			
		case "Sin":
			if ( userinput > 0 )
				cycle = "/B=" + num2str( userinput ) + " "
			endif
			break
			
	endswitch
	
	if ( weight == 1 )
		if ( WaveExists( $( "Stdv_" + sourceWave ) ) == 1 )
			weightflag = "/I=1 "
			weightwave = "/W=" + saveDF + "Stdv_" + sourceWave + " "
		elseif ( WaveExists( $( "Stdv" + sourceWave ) ) == 1 )
			weightflag = "/I=1 "
			weightwave = "/W=" + saveDF + "Stdv" + sourceWave + " "
		elseif ( WaveExists( $( "InvStdv_" + sourceWave ) ) == 1 )
			weightflag = "/I=0 "
			weightwave = "/W=" + saveDF + "InvStdv_" + sourceWave + " "
		elseif ( WaveExists( $( "InvStdv" + sourceWave ) ) == 1 )
			weightflag = "/I=0 "
			weightwave = "/W=" + saveDF + "InvStdv" + sourceWave + " "
		else
			return NMError( 90, thisfxn, "cannot locate Stdv or InvStdv wave for " + sourceWave, "" )
		endif
	endif
	
	constraints = NMFitWaveConstraints()
	
	if ( ( numtype( fitNumPnts ) == 0 ) && ( fitNumPnts > 1 ) )
		fitpnts = "/L=" + num2istr( fitNumPnts ) + " "
	endif
	
	fitw = " /D "
	
	if ( fullGraphWidth == 1 )
		fullGraph = "/X=1 "
	endif
	
	if ( residuals == 1 )
		resid = "/R "
	endif
	
	if ( maxIter != 40 )
		Variable /G V_FitMaxIters = maxIter
	endif
	
	coef = " kwCWave=" + NMFitWavePath( "coef" ) + ", "
	
	FT_sigma = Nan
	
	cmd = fit + fitpnts + "/N " + cycle + guess + quiet + fullGraph + hold + const + fxn + coef
	cmd += wName + region + fitw + resid + weightflag + weightwave + xw + constraints
	
	if ( changeFolder == 1 )
		SetDataFolder df
	endif
	
	//Variable /G V_FitError = Nan
	
	Execute /Z cmd
	
	if ( changeFolder == 1 )
		SetDataFolder saveDF
	endif
	
	//NMHistory( cmd )
		
	if ( WaveExists( $wsigma ) == 1 )
		Wave wtemp = $wsigma
		FT_sigma = wtemp
	endif
	
	return V_flag

End // NMFitWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitWaveConstraints()

	Variable icnt, jcnt, found
	
	String wName = NMFitWavePath( "constraints" )
	
	Variable numParams = NMFitNumParams()

	Wave FT_low = $NMFitWavePath( "low" )
	Wave FT_high = $NMFitWavePath( "high" )
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
	
		if ( numtype( FT_low[ icnt ] ) == 0 )
			found += 1
		endif
		
		if ( numtype( FT_high[ icnt ] ) == 0 )
			found += 1
		endif
		
	endfor
	
	Make /T/O/N=( found ) $wName = ""
	
	if ( found == 0 )
		return ""
	endif
	
	Wave /T wtemp = $wName
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
	
		if ( numtype( FT_low[ icnt ] ) == 0 )
			wtemp[ jcnt ] = "K" + num2str( icnt ) + " > " + num2str( FT_low[ icnt ] )
			jcnt += 1
		endif
		
		if ( numtype( FT_high[ icnt ] ) == 0 )
			wtemp[ jcnt ] = "K" + num2str( icnt ) + " < " + num2str( FT_high[ icnt ] )
			jcnt += 1
		endif
		
	endfor
	
	return "/C=" + wName

End // NMFitWaveConstraints

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitWaveName( wavNum )
	Variable wavNum // ( -1 ) for current

	return "Fit_" + NMChanWaveName( CurrentNMChannel(), wavNum )
	
End // NMFitWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitResidWaveName( wavNum )
	Variable wavNum // ( -1 ) for current

	return "Res_" + NMChanWaveName( CurrentNMChannel(), wavNum )
	
End // NMFitResidWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitDisplayWaveName()
	
	return NMFitWaveDF() + "Fit_" + ChanDisplayWaveName( 0, CurrentNMChannel(), 0 )

End // NMFitDisplayWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitResidDisplayWaveName()
	
	return NMFitWaveDF() + "Res_" + ChanDisplayWaveName( 0, CurrentNMChannel(), 0 )

End // NMFitResidDisplayWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveComputeCall()

	Variable guessORfit
	String guessName = NMFitWavePath( "guess" )
	
	if ( WaveExists( $guessName ) == 0 )
		return -1
	endif
	
	WaveStats /Q $guessName
	
	if ( V_npnts != numpnts( $guessName ) )
	
		if ( WaveExists( $NMFitWavePath( "coef" ) ) == 0 )
			return -1
		endif
		
		guessORfit = 1
	
	endif
	
	NMCmdHistory( "NMFitWaveCompute", NMCmdNum( guessORfit, "" ) )

	return NMFitWaveCompute( guessORfit )

End // NMFitWaveComputeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveCompute( guessORfit )
	Variable guessORfit // ( 0 ) guess ( 1 ) fit

	Variable icnt, dt, pbgn, pend
	String thisfxn = "NMFitWaveCompute"
	
	Variable npnts = NMFitVar( "FitNumPnts" )
	Variable tbgn = NMFitVar( "Tbgn" )
	Variable tend = NMFitVar( "Tend" )
	Variable userinput = NMFitVar( "UserInput" )
	Variable fullGraphWidth = NMFitVar( "FullGraphWidth" )
	
	Variable currentChan = CurrentNMChannel()
	
	String paramWave
	String cmd = ""
	String fxn = NMFitStr( "Function" )
	String igorFxns = NMFitIgorListShort()
	String gName = ChanGraphName( currentChan )
	String displayWave = ChanDisplayWave( currentChan )
	String fitWave = NMFitDisplayWaveName()
	
	if ( WhichListItem( fxn, igorFxns ) < 0 ) // user defined function here
		//NMDoAlert( "Sorry, this function does not work for user-defined curve fit functions." )
		//return 0
	endif
	
	NMFitRemoveDisplayWaves()
	
	if ( guessORfit == 1 )
		paramWave = NMFitWavePath( "coef" )
	else
		paramWave = NMFitWavePath( "guess" )
	endif

	if ( WaveExists( $paramWave ) == 0 )
		return NMError( 1, thisfxn, "paramWave", paramWave )
	endif
	
	WaveStats /Q/Z $paramWave

	if ( V_numNaNs > 0 )
		return NMError( 90, thisfxn, "parameter wave contains NANs", "" )
	endif
	
	if ( numtype( npnts ) > 0 )
		npnts = numpnts( $displayWave )
		tbgn = leftx( $displayWave )
		dt = deltax( $displayWave )
	else
		dt = ( tend - tbgn ) / ( npnts - 1 )
	endif
	
	Wave w = $paramWave
	
	//Duplicate /O $displayWave $fitWave
	Make /O/N=( npnts ) $fitWave
	Setscale /P x tbgn, dt, $fitWave
	
	Wave fit = $fitWave
	
	strswitch( fxn )
		case "Line":
			//pList = "A;B;"
			//eq = "A+Bx"
			fit = w[0] + w[1] * x
			break
		case "Poly":
			fit = 0
			for ( icnt = 0 ; icnt < numpnts( w ) ; icnt += 1 )
				fit += w[icnt]*x^icnt
			endfor
			break
		case "Gauss":
			//pList = "Y0;A;X0;W;"
			//eq = "Y0+A*exp( -( ( x -X0 )/W )^2 )"
			fit = w[0] + w[1]*exp( -( ( x -w[2] )/w[3] )^2 ) 
			break
		case "Lor":
			//pList = "Y0;A;X0;B;"
			//eq = "Y0+A/( ( x-X0 )^2+B )"
			fit = w[0]+w[1]/( ( x-w[2] )^2+w[3] )
			break
		case "Exp":
			//pList = "Y0;A;InvT;"
			//eq = "Y0+A*exp( -InvT*x )"
			fit = w[0]+w[1]*exp( -w[2]*x )
			break
		case "DblExp":
			//pList = "Y0;A1;InvT1;A2;InvT2;"
			//eq = "Y0+A1*exp( -InvT1*x )+A2*exp( -InvT2*x )"
			fit = w[0]+w[1]*exp( -w[2]*x )+w[3]*exp( -w[4]*x )
			break
		case "Exp_XOffset":
			//pList = "Y0;A;T;"
			//eq = "Y0+A*exp( -( x-X0 )/T )"
			fit = w[0]+w[1]*exp( -( x-userInput )/w[2] )
			break
		case "DblExp_XOffset":
			//pList = "Y0;A1;T1;A2;T2;"
			//eq = "Y0+A1*exp( -( x-X0 )/T1 )+A2*exp( -( x-X0 )/T2 )"
			fit = w[0]+w[1]*exp( -( x-userInput )/w[2] )+w[3]*exp( -( x-userInput )/w[4] )
			break
		case "Sin":
			//pList = "Y0;A;F;P;"
			//eq = "Y0+A*sin( F*x+P )"
			fit = w[0]+w[1]*sin( w[2]*x+w[3] )
			break
		case "HillEquation":
			//pList = "B;M;R;XH;"
			//eq = "B+( M-B )*( x^R/( 1+( x^R+XH^R ) ) )"
			fit = w[0]+( w[1]-w[0] )*( x^w[2]/( 1+( x^w[2]+w[3]^w[2] ) ) )
			break
		case "Sigmoid":
			//pList = "B;M;XH;R;"
			//eq = "B+M/( 1+exp( -( x-XH )/R ) )"
			fit = w[0]+w[1]/( 1+exp( -( x-w[2] )/w[3] ) )
			break
		case "Power":
			//pList = "Y0;A;P;"
			//eq = "Y0+A*x^P"
			fit = w[0]+w[1]*x^w[2]
			break
		case "LogNormal":
			//pList = "Y0;A;X0;W;"
			//eq = "Y0+A*exp( -( ln( x/X0 )/W )^2 )"
			fit = w[0]+w[1]*exp( -( ln( x/w[2] )/w[3] )^2 )
			break
		case "NMSynExp3":
			fit = NMSynExp3( w,x )
			break
		case "NMSynExp4":
			fit = NMSynExp4( w,x )
			break
		default:
			return NMError( 90, thisfxn, "cannot compute function for " + NMQuotes( fxn ), "" )
	endswitch
	
	AppendToGraph /W=$gName fit
	
	if ( ( fullGraphWidth == 1 ) && ( guessORfit == 1 ) )
		return 0
	endif
	
	pbgn = x2pnt( fit, tbgn )
	pend = x2pnt( fit, tend )
	
	if ( ( numtype( tbgn ) == 0 ) && ( pbgn - 1 >= 0 ) )
		fit[0, pbgn - 1] = Nan
	endif
	
	if ( ( numtype( tend ) == 0 ) && ( pend + 1 <= numpnts( fit ) - 1 ) )
		fit[pend + 1, inf] = Nan
	endif
	
	return 0

End // NMFitWaveCompute

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubDirectory()

	String fxn = NMFitStr( "Function" )
	
	if ( strlen( fxn ) > 0 )
		return FitDF() + "FT_" + fxn + ":"
	else
		return ""
	endif 

End // NMFitSubDirectory

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubDirWavePath( wName )
	String wName
	
	return NMFitSubDirectory() + "FT_" + wName
	
End // NMFitSubDirWavePath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitWaveTable( new )
	Variable new // ( 0 ) no ( 1 ) yes
	
	Variable numParams = NMFitNumParams()
	String tName = "NM_Fit_Parameters"
	
	if ( ( new == 1 ) || ( WaveExists( $NMFitWavePath( "cname" ) ) == 0 ) )
	
		if ( WaveExists( $NMFitSubDirWavePath( "cname" ) ) == 1 )
			Duplicate /T/O $NMFitSubDirWavePath( "cname" ) $NMFitWavePath( "cname" )
		else
			Make /O/T/N=( numParams ) $NMFitWavePath( "cname" ) = ""
		endif
		
	endif
	
	if ( ( new == 1 ) || ( WaveExists( $NMFitWavePath( "coef" ) ) == 0 ) )
		Make /D/O/N=( numParams ) $NMFitWavePath( "coef" ) = Nan
	endif
	
	if ( ( new == 1 ) || ( WaveExists( $NMFitWavePath( "sigma" ) ) == 0 ) )
		Make /D/O/N=( numParams ) $NMFitWavePath( "sigma" ) = Nan
	endif
	
	if ( ( new == 1 ) || ( WaveExists( $NMFitWavePath( "guess" ) ) == 0 ) )
	
		if ( WaveExists( $NMFitSubDirWavePath( "guess" ) ) == 1 )
			Duplicate /O $NMFitSubDirWavePath( "guess" ) $NMFitWavePath( "guess" )
		else
			Make /O/N=( numParams ) $NMFitWavePath( "guess" ) = Nan
		endif
		
	endif
	
	if ( ( new == 1 ) || ( WaveExists( $NMFitWavePath( "hold" ) ) == 0 ) )
	
		if ( WaveExists( $NMFitSubDirWavePath( "guess" ) ) == 1 )
			Duplicate /O $NMFitSubDirWavePath( "guess" ) $NMFitWavePath( "hold" )
		else
			Make /O/N=( numParams ) $NMFitWavePath( "hold" ) = Nan
		endif
		
	endif
	
	CheckNMtwave( NMFitWavePath( "cname" ), numParams, "" )
	CheckNMwave( NMFitWavePath( "coef" ), numParams, Nan )
	CheckNMwave( NMFitWavePath( "sigma" ), numParams, Nan )
	CheckNMwave( NMFitWavePath( "guess" ), numParams, Nan )
	CheckNMwave( NMFitWavePath( "hold" ), numParams, Nan )
	CheckNMwave( NMFitWavePath( "low" ), numParams, Nan )
	CheckNMwave( NMFitWavePath( "high" ), numParams, Nan )
	
	Wave /T FT_cname = $NMFitWavePath( "cname" )
	Wave FT_coef = $NMFitWavePath( "coef" )
	Wave FT_sigma = $NMFitWavePath( "sigma" )
	Wave FT_guess = $NMFitWavePath( "guess" )
	Wave FT_hold = $NMFitWavePath( "hold" )
	Wave FT_low = $NMFitWavePath( "low" )
	Wave FT_high = $NMFitWavePath( "high" )
	
	if ( WinType( tName ) == 2 )
		DoWindow /F $tName
		return tName
	endif
	
	Edit /K=1/N=$tName FT_cname, FT_coef, FT_sigma, FT_guess, FT_hold, FT_low, FT_high as "Fit Results"
	
	SetCascadeXY( tName )
	
	return tName

End // NMFitWaveTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCoefNamesSet( paramList )
	String paramList
	
	Variable icnt, numParams = NMFitNumParams()
	String param
	
	Wave /T FT_cname = $NMFitWavePath( "cname" )

	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
		
		param = StringFromList( icnt, paramList )
		
		if ( strlen( param ) == 0 )
			param = "K" + num2istr( icnt )
		endif
		
		if ( strlen( FT_cname[icnt] ) == 0 )
			FT_cname[icnt] = param
		endif
		
	endfor
	
	return 0
	
End // NMFitCoefNamesSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitGuess()

	Variable tbgn = NMFitVar( "Tbgn" )
	String fxn = NMFitStr( "Function" )
	
	Wave FT_guess = $NMFitWavePath( "guess" )
	
	if ( numtype( FT_guess[0] * FT_guess[1] ) == 0 )
		return 0 // already exist
	endif
	
	if ( numtype( tbgn ) > 0 )
		tbgn = 0
	endif
	
	strswitch( fxn )
		case "NMSynExp3":
			FT_guess[0] = tbgn // X0
			FT_guess[1] = 0.1 // TR1
			FT_guess[2] = 11 // N
			FT_guess[3] = 2 // A1
			FT_guess[4] = 0.5 // TD1
			FT_guess[5] = 0.3 // A2
			FT_guess[6] = 3 // TD2
			break
		case "NMSynExp4":
			FT_guess[0] = tbgn // X0
			FT_guess[1] = 0.1 // TR1
			FT_guess[2] = 11 // N
			FT_guess[3] = 2 // A1
			FT_guess[4] = 0.5 // TD1
			FT_guess[5] = 0.3 // A2
			FT_guess[6] = 3 // TD2
			FT_guess[7] = 0.1 // A3
			FT_guess[8] = 20 // TD3
			break
	endswitch
	
	return 0

End // NMFitGuess

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveTableSave()

	String subD = NMFitSubDirectory()
	
	if ( strlen( subD ) == 0 )
		return 0
	endif
	
	if ( DataFolderExists( subD ) == 0 )
		NewDataFolder $RemoveEnding( subD, ":" )
	endif
	
	if ( WaveExists( $NMFitWavePath( "cname" ) ) == 1 )
		Duplicate /O $NMFitWavePath( "cname" ), $NMFitSubDirWavePath( "cname" )
	endif
	
	if ( WaveExists( $NMFitWavePath( "guess" ) ) == 1 )
		Duplicate /O $NMFitWavePath( "guess" ), $NMFitSubDirWavePath( "guess" )
	endif
	
	if ( WaveExists( $NMFitWavePath( "hold" ) ) == 1 )
		Duplicate /O $NMFitWavePath( "hold" ), $NMFitSubDirWavePath( "guess" )
	endif
	
	return 0

End // NMFitWaveTableSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSaveCurrentCall()

	String tName = NMFitTableName()
	
	if ( WinType( tName ) == 2 )
		DoWindow /F $tName
	endif

	NMCmdHistory( "NMFitSaveCurrent", "" )

	return NMFitSaveCurrent()

End // NMFitSaveCurrentCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSaveCurrent()

	String fitwave, reswave
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	String sourceWave = NMChanWaveName( currentChan, currentWave )

	if ( NMFitVar( "SaveFitWaves" ) == 1 )
	
		fitwave = NMFitDisplayWaveName()
		reswave = NMFitResidDisplayWaveName()
		
		WaveStats /Q/Z $fitwave
		
		if ( numtype( V_avg ) > 0 )
		
			NMFitWaveCompute( 1 ) // something went wrong - recompute fit wave
			
			if ( WaveExists( $reswave ) == 1 )
			
				Wave res = $reswave
			
				res = Nan
				
			endif
			
		endif
		
		if ( WaveExists( $fitwave ) == 1 )
			Duplicate /O $fitwave $( "Fit_" + sourceWave )
			NMPrefixAdd( "Fit_" + CurrentNMWavePrefix() )
		endif
		
		if ( WaveExists( $reswave ) == 1 )
			Duplicate /O $reswave $( "Res_" + sourceWave )
		endif
		
	endif

	return NMFitSaveClear( CurrentNMWave(), 0 )
	
End // NMFitSaveCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitClearCall()

	Variable clear = NMFitVar( "ClearWavesSelect" )
	
	Prompt clear, "clear results for:", popup "current wave;all waves;"
	DoPrompt "Clear Fit Results", clear
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMFitVar( "ClearWavesSelect", clear )
	
	if ( clear == 1 )
	
		NMCmdHistory( "NMFitClearCurrent", "" )
		
		return NMFitClearCurrent()
	
	elseif ( clear == 2 )
	
		NMCmdHistory( "NMFitClearAll", "" )

		return NMFitClearAll()
	
	endif
	
	return ""

End // NMFitClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitClearCurrentCall()

	NMCmdHistory( "NMFitClearCurrent", "" )

	return NMFitClearCurrent()

End // NMFitClearCurrentCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitClearCurrent()

	String tName = NMFitTableName()
	
	if ( WinType( tName ) == 2 )
		DoWindow /F $tName
	endif

	return NMFitSaveClear( CurrentNMWave(), 1 )
	
End // NMFitClearCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitClearAllCall()

	NMCmdHistory( "NMFitClearAll", "" )

	return NMFitClearAll()

End // NMFitClearAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitClearAll()

	Variable wcnt, nwaves = NMNumWaves()
	String tList = ""
	
	String tName = NMFitTableName()
	
	if ( WinType( tName ) == 2 )
		DoWindow /F $tName
	endif

	for ( wcnt = 0 ; wcnt < nwaves ; wcnt += 1 )
		tname = NMFitSaveClear( wcnt, 1 )
		tList = AddListItem( tname, tList, ";", inf )
	endfor
	
	return tList
	
End // NMFitClearAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSaveClear( wavNum, clear )
	Variable wavNum
	Variable clear // ( 0 ) save ( 1 ) clear

	Variable icnt
	Variable chan = CurrentNMChannel()
	Variable overwrite = NMFitOverWrite()
	Variable numParams = NMFitNumParams()

	String wname
	String tName = NMFitTable()
	String fitWave = NMFitWaveName( wavNum )
	String resWave = NMFitResidWaveName( wavNum )
	String fitDisplay = NMFitDisplayWaveName()
	String resDisplay = NMFitResidDisplayWaveName()
	String df = NMFitWaveDF()
	
	if ( ( WaveExists( $NMFitWavePath( "coef" ) ) == 0 ) || ( WaveExists( $NMFitWavePath( "sigma" ) ) == 0 ) )
		return ""
	endif
	
	Wave FT_coef = $NMFitWavePath( "coef" )
	Wave FT_sigma = $NMFitWavePath( "sigma" )
	
	if ( clear == 1 )
	
		clear = Nan
		
		if ( WaveExists( $fitWave ) == 1 )
			Wave wtemp = $fitWave
			wtemp = Nan
		endif
		
		if ( WaveExists( $resWave ) == 1 )
			Wave wtemp = $resWave
			wtemp = Nan
		endif
		
		if ( WaveExists( $fitDisplay ) == 1 )
			Wave wtemp = $fitDisplay
			wtemp = Nan
		endif
		
		if ( WaveExists( $resDisplay ) == 1 )
			Wave wtemp = $resDisplay
			wtemp = Nan
		endif
		
	else
	
		clear = 1
		
	endif
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
	
		if ( ( numtype( FT_coef[icnt] ) > 0 ) || ( numtype( FT_sigma[icnt] ) > 0 ) )
			clear = Nan
		endif
		
		wname = NMFitTableWaveNameCoef( icnt, 0, chan, overwrite )
		
		if ( WaveExists( $wname ) == 0 )
			continue
		endif
		
		Wave wtemp = $wname
		wtemp[wavNum] = FT_coef[icnt] * clear
	
		wname = NMFitTableWaveNameCoef( icnt, 1, chan, overwrite )
		
		if ( WaveExists( $wname ) == 0 )
			continue
		endif
		
		Wave wtemp = $wname
		wtemp[wavNum] = FT_sigma[icnt] * clear
		
	endfor
	
	wname = NMFitTableWaveName( "ChiSqr", chan, overwrite )
	
	if ( WaveExists( $wname ) == 1 )
		Wave wtemp = $wname
		wtemp[wavNum] = NMFitVar( "V_chisq" ) * clear
	endif
	
	wname = NMFitTableWaveName( "NumPnts", chan, overwrite )
	
	if ( WaveExists( $wname ) == 1 )
		Wave wtemp = $wname
		wtemp[wavNum] = NMFitVar( "V_npnts" ) * clear
	endif
	
	wname = NMFitTableWaveName( "NumNANs", chan, overwrite )
	
	if ( WaveExists( $wname ) == 1 )
		Wave wtemp = $wname
		wtemp[wavNum] = NMFitVar( "V_numNaNs" ) * clear
	endif
	
	wname = NMFitTableWaveName( "NumINFs", chan, overwrite )
	
	if ( WaveExists( $wname ) == 1 )
		Wave wtemp = $wname
		wtemp[wavNum] = NMFitVar( "V_numINFs" ) * clear
	endif
	
	wname = NMFitTableWaveName( "StartRow", chan, overwrite )
	
	if ( WaveExists( $wname ) == 1 )
		Wave wtemp = $wname
		wtemp[wavNum] = NMFitVar( "V_startRow" ) * clear
	endif
	
	wname = NMFitTableWaveName( "EndRow", chan, overwrite )
	
	if ( WaveExists( $wname ) == 1 )
		Wave wtemp = $wname
		wtemp[wavNum] = NMFitVar( "V_endRow" ) * clear
	endif
	
	return tName
	
End // NMFitSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitTableName()

	Variable overwrite = NMFitOverWrite()
	
	String tName = "FT_" + NMFitStr( "Function" ) + "_" + NMFolderPrefix( "" ) + NMWaveSelectStr() + "_"
	
	tname = NextGraphName( tname, CurrentNMChannel(), overwrite )
	
	return tName

End // NMFitTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitTableWaveName( name, chanNum, overWrite )
	String name
	Variable chanNum
	Variable overWrite
	
	String fname
	String fxn = NMFitStr( "FxnShort" )
	String subfolder = CurrentNMFitSubfolder()
	
	if ( strlen( fxn ) > 5 )
		fxn = ReplaceString( "_", fxn, "" )
		fxn = ReplaceString( "-", fxn, "" )
		fxn = fxn[0, 4]
	endif
	
	String wPrefix = "FT_" + fxn + "_" + name+ "_" + NMWaveSelectStr() + "_"
	
	fname = NextWaveName2( subfolder, wPrefix, chanNum, overWrite )
	
	return subfolder + fname[0,30]

End // NMFitTableWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitTableWaveNameCoef( coefNum, sig, chanNum, overWrite )
	Variable coefNum
	Variable sig // ( 0 ) no ( 1 ) yes
	Variable chanNum
	Variable overWrite
	
	if ( WaveExists( $NMFitWavePath( "cname" ) ) == 0 )
		return ""
	endif
	
	Wave /T FT_cname = $NMFitWavePath( "cname" )
	
	String fxn = FT_cname[coefNum]
	
	if ( sig == 1 )
		fxn += "sig"
	endif
	
	return NMFitTableWaveName( fxn, chanNum, overWrite )

End // NMFitTableWaveNameCoef

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitTable()

	Variable icnt
	String wname, thisfxn = "NMFitTable"

	NMChanWaveList2Waves()
	
	Variable chan = CurrentNMChannel()
	Variable nwaves = NMNumWaves()
	Variable overwrite = NMFitOverWrite()

	String fxn =NMFitStr( "FxnShort" )
	String tName = NMFitTableName()
	String wNames = NMChanWaveListName( CurrentNMChannel() )
	String title = NMFolderListName( "" ) + " : Fit " + fxn + " : Ch" + CurrentNMChanChar() + " : " + CurrentNMWavePrefix() + " : " + NMWaveSelectGet()
	
	wname = NMFitWavePath( "cname" )
	
	if ( WaveExists( $wname ) == 0 )
		return NMErrorStr( 1, thisfxn, "wname", wname )
	endif
	
	if ( WinType( tName ) == 2 )
		//DoWindow /F $tName
		return tName
	endif
	
	CheckNMFitSubfolder( "" )
	
	Wave /T FT_cname = $wname
	
	Edit /K=1/N=$tName as title
	
	SetCascadeXY( tName )
	
	if ( WaveExists( $wnames ) == 1 )
		wname = NMFitTableWaveName( "wName", chan, overwrite )
		Duplicate /O $wNames $wname
		AppendToTable /W=$tName $wname
	endif
	
	for ( icnt = 0 ; icnt < numpnts( FT_cname ) ; icnt += 1 )
	
		wname = NMFitTableWaveNameCoef( icnt, 0, chan, overwrite )
		
		if ( ( WaveExists( $wname ) == 0 ) || ( numpnts( $wname ) != nwaves ) )
			Make /O/N=( nwaves ) $wname = Nan
		endif
		
		AppendToTable /W=$tName $wname
		
		wname = NMFitTableWaveNameCoef( icnt, 1, chan, overwrite )
		
		if ( ( WaveExists( $wname ) == 0 ) || ( numpnts( $wname ) != nwaves ) )
			Make /O/N=( nwaves ) $wname = Nan
		endif
		
		AppendToTable /W=$tName $wname
		
	endfor
	
	wname = NMFitTableWaveName( "ChiSqr", chan, overwrite )
	
	if ( ( WaveExists( $wname ) == 0 ) || ( numpnts( $wname ) != nwaves ) )
		Make /O/N=( nwaves ) $wname = Nan
	endif
	
	AppendToTable /W=$tName $wname
	
	wname = NMFitTableWaveName( "NumPnts", chan, overwrite )
	
	if ( ( WaveExists( $wname ) == 0 ) || ( numpnts( $wname ) != nwaves ) )
		Make /O/N=( nwaves ) $wname = Nan
	endif
	
	AppendToTable /W=$tName $wname
	
	wname = NMFitTableWaveName( "NumNANs",chan, overwrite )
	
	if ( ( WaveExists( $wname ) == 0 ) || ( numpnts( $wname ) != nwaves ) )
		Make /O/N=( nwaves ) $wname = Nan
	endif
	
	AppendToTable /W=$tName $wname
	
	wname = NMFitTableWaveName( "NumINFs", chan, overwrite )
	
	if ( ( WaveExists( $wname ) == 0 ) || ( numpnts( $wname ) != nwaves ) )
		Make /O/N=( nwaves ) $wname = Nan
	endif
		
	AppendToTable /W=$tName $wname
	
	wname = NMFitTableWaveName( "StartRow",chan, overwrite )
	
	if ( ( WaveExists( $wname ) == 0 ) || ( numpnts( $wname ) != nwaves ) )
		Make /O/N=( nwaves ) $wname = Nan
	endif
	
	AppendToTable /W=$tName $wname
	
	wname = NMFitTableWaveName( "EndRow", chan, overwrite )
	
	if ( ( WaveExists( $wname ) == 0 ) || ( numpnts( $wname ) != nwaves ) )
		Make /O/N=( nwaves ) $wname = Nan
	endif
	
	AppendToTable /W=$tName $wname
	
	return tName

End // NMFitTable

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Graph Display Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPlotAll( plotData )
	Variable plotData // ( 0 ) no ( 1 )
	
	Variable wcnt, error
	String cList = "", fList = "", fitWave, xl, yl
	
	Variable currentChan = CurrentNMChannel()
	Variable nwaves = NMNumWaves()
	Variable overwrite = NMFitOverWrite()
	
	String fxn = NMFitStr( "FxnShort" )
	String wavePrefix = CurrentNMWavePrefix()
	String gPrefix = "FT_" + NMFolderPrefix( "" ) + NMWaveSelectStr() + fxn + num2istr( plotData )
	String gName = NextGraphName( gPrefix, currentChan, overwrite )
	String gTitle = NMFolderListName( "" ) + " : Ch" + ChanNum2Char( currentChan ) + " : " + wavePrefix + " : " + NMWaveSelectGet() + " : " + fxn + " Fits"
	String xwave = NMXwave()
	
	for ( wcnt = 0 ; wcnt < nwaves ; wcnt += 1 )
	
		fitWave = NMFitWaveName( wcnt )
		
		if ( WaveExists( $fitWave ) == 1 )
			cList = AddListItem( NMChanWaveName( currentChan, wcnt ), cList, ";", inf )
			fList = AddListItem( fitWave, fList, ";", inf )
		endif
		
	endfor
	
	If ( ItemsInList( fList ) <= 0 )
		NMDoAlert( "There are no saved fits to plot." )
		return 0
	endif
	
	xl = NMChanLabel( currentChan, "x", cList )
	yl = NMChanLabel( currentChan, "y", cList )

	if ( plotData == 1 )
	
		NMPlotWavesOffset( gName, gTitle, xl, yl, xwave, cList, 0, 0, 0, 0 ) // NM_Utility.ipf
		
		if ( WinType( gName ) != 1 )
			return -1
		endif
		
		ModifyGraph /W=$gName rgb=( 0,0,0 )
		
		for ( wcnt = 0 ; wcnt < ItemsInlist( fList ) ; wcnt += 1 )
			AppendToGraph /Q/W=$gName $StringFromList( wcnt, fList )
		endfor
		
	else
	
		NMPlotWavesOffset( gName, gTitle, xl, yl, xwave, fList, 0, 0, 0, 0 ) // NM_Utility.ipf
		ModifyGraph /W=$gName rgb=( 65280,0,0 )
	
	endif
	
	return 0

End // NMFitPlotAll

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Subfolder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubfolderPrefix()

	return "Fit_" + NMFitStr( "FxnShort" ) + "_"

End //NMFitSubfolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubfolder( wavePrefix, waveSelect )
	String wavePrefix
	String waveSelect
	
	if ( NMFitVar( "UseSubfolders" ) == 0 )
		return ""
	endif
	
	return NMSubfolder( NMFitSubfolderPrefix(), wavePrefix, CurrentNMChannel(), waveSelect )

End // NMFitSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMFitSubfolder()

	return NMFitSubfolder( CurrentNMWavePrefix(), NMWaveSelectShort() )
	
End // CurrentNMFitSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFitSubfolder( subfolder )
	String subfolder // ( "" ) for current
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMFitSubfolder()
	endif
	
	return CheckNMSubfolder( subfolder )
	
End // CheckNMFitSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubfolderList( folder, fullPath, restrictToCurrentPrefix )
	String folder
	Variable fullPath // ( 0 ) no ( 1 ) yes
	Variable restrictToCurrentPrefix
	
	Variable icnt
	String folderName, tempList = ""
	
	String currentPrefix = CurrentNMWavePrefix()
	
	String folderList = NMSubfolderList( NMFitSubfolderPrefix(), folder, fullPath )
	
	if ( restrictToCurrentPrefix == 1 )
		
		for ( icnt = 0 ; icnt < ItemsInList( folderList ) ; icnt += 1 )
			
			folderName = StringFromList( icnt, folderList )
			
			if ( strsearch( folderName, currentPrefix, 0, 2 ) > 0 )
				tempList = AddListItem( folderName, tempList, ";", inf )
			endif
			
		endfor
		
		folderList = tempList
	
	endif
	
	return folderList

End // NMFitSubfolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubfolderTableCall()

	Variable items
	
	String df = FitDF()
	String fList = NMFitSubfolderList( CurrentNMFolder( 1 ), 0, 0 )
	
	String subfolder = StringFromList( 0, fList )
	
	items = ItemsInList( fList )
	
	if ( items  <= 0 )
		NMDoAlert( "Fit Table Alert: there are currently no Fit subfolders in the current NM folder to create a table." )
		return ""
	endif
	
	if ( items > 1 )
	
		subfolder = StrVarOrDefault( df+"SubfolderTableSelect", subfolder )
		
		Prompt subfolder, "choose results subfolder:", popup fList
		DoPrompt "Fit Table", subfolder
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		SetNMFitStr( "SubfolderTableSelect", subfolder )
		
	endif
	
	NMCmdHistory( "NMFitSubfolderTable", NMCmdStr( subfolder, "" ) )
	
	return NMFitSubfolderTable( subfolder )

End // NMFitSubfolderTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubfolderTable( subfolder )
	String subfolder
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMFitSubfolder()
	endif
	
	return NMSubfolderTable( subfolder, "FT_" )
	
End // NMFitSubfolderTable

//****************************************************************
//****************************************************************
//****************************************************************
//
//	More Fit Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMSynExp3( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f( x ) = ( 1-exp( -( x-X0 )/TR1 ) )^N*( A1*exp( -( x-X0 )/TD1 )+A2*exp( -( x-X0 )/TD2 ) )
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = X0
	//CurveFitDialog/ w[1] = TR1
	//CurveFitDialog/ w[2] = N
	//CurveFitDialog/ w[3] = A1
	//CurveFitDialog/ w[4] = TD1
	//CurveFitDialog/ w[5] = A2
	//CurveFitDialog/ w[6] = TD2
	
	Variable scale = NMFitVar( "SynExpSign" )
	
	switch( scale )
		case 1:
		case -1:
			break
		default:
			scale = 1
	endswitch
	
	w[3] = scale * abs( w[3] )
	w[5] = scale * abs( w[5] )
	
	if ( x < w[0] )
		return 0
	else
		return ( 1-exp( -( x-w[0] )/w[1] ) )^w[2]*( w[3]*exp( -( x-w[0] )/w[4] )+w[5]*exp( -( x-w[0] )/w[6] ) )
	endif
	
End // NMSynExp3

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSynExp3F( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f( x ) = A0*( 1-exp( -( x-X0 )/TR1 ) )^N*( F*exp( -( x-X0 )/TD1 )+( 1-F )*exp( -( x-X0 )/TD2 ) )
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = X0
	//CurveFitDialog/ w[1] = TR1
	//CurveFitDialog/ w[2] = N
	//CurveFitDialog/ w[3] = A0
	//CurveFitDialog/ w[4] = TD1
	//CurveFitDialog/ w[5] = F
	//CurveFitDialog/ w[6] = TD2
	
	Variable scale = NMFitVar( "SynExpSign" )
	
	switch( scale )
		case 1:
		case -1:
			break
		default:
			scale = 1
	endswitch
	
	w[3] = scale * abs( w[3] )
	w[5] = scale * abs( w[5] )
	
	if ( x < w[0] )
		return 0
	else
		return w[3]*( 1-exp( -( x-w[0] )/w[1] ) )^w[2]*( w[5]*exp( -( x-w[0] )/w[4] )+( 1-w[5] )*exp( -( x-w[0] )/w[6] ) )
	endif
	
End // NMSynExp3F

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSynExp4( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f( x ) = ( 1-exp( -( x-X0 )/TR1 ) )^N*( A1*exp( -( x-X0 )/TD1 )+A2*exp( -( x-X0 )/TD2 )+A3*exp( -( x-X0 )/TD3 ) )
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 9
	//CurveFitDialog/ w[0] = X0
	//CurveFitDialog/ w[1] = TR1
	//CurveFitDialog/ w[2] = N
	//CurveFitDialog/ w[3] = A1
	//CurveFitDialog/ w[4] = TD1
	//CurveFitDialog/ w[5] = A2
	//CurveFitDialog/ w[6] = TD2
	//CurveFitDialog/ w[7] = A3
	//CurveFitDialog/ w[8] = TD3
	
	Variable scale = NMFitVar( "SynExpSign" )
	
	switch( scale )
		case 1:
		case -1:
			break
		default:
			scale = 1
	endswitch
	
	w[3] = scale * abs( w[3] )
	w[5] = scale * abs( w[5] )
	w[7] = scale * abs( w[7] )
	
	if( x<w[0] )
		return 0
	else
		return ( 1-exp( -( x-w[0] )/w[1] ) )^w[2]*( w[3]*exp( -( x-w[0] )/w[4] )+w[5]*exp( -( x-w[0] )/w[6] )+w[7]*exp( -( x-w[0] )/w[8] ) )
	endif
	
End // NMSynExp4

//****************************************************************
//****************************************************************
//****************************************************************