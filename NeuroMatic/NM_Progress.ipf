#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Main Functions
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	First release: 05 May 2002
//
//	Progress Display Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXYCall( xpixels, ypixels )
	Variable xpixels, ypixels
	
	String vlist = ""

	vlist = NMCmdNum( xpixels, vlist )
	vlist = NMCmdNum( ypixels, vlist )
	NMCmdHistory( "NMProgressXY", vlist )
	
	return NMProgressXY( xpixels, ypixels )

End // NMProgressXYCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXY( xpixels, ypixels )
	Variable xpixels, ypixels
	
	if ( ( numtype( xPixels ) > 0 ) || ( xPixels < 0 ) )
		return -1
	endif
	
	if ( ( numtype( yPixels ) > 0 ) || ( yPixels < 0 ) )
		return -1
	endif
	
	SetNeuroMaticVar( "xProgress", xpixels )
	SetNeuroMaticVar( "yProgress", ypixels )
	
	return 0

End // NMProgressXY

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressX()

	Variable xProgress = NeuroMaticVar( "xProgress" )
	Variable xLimit = NMComputerPixelsX() - NMProgressWidth()
	
	if ( numtype( xProgress ) > 0 )
		xProgress = ( NMComputerPixelsX() - 2 * NMProgressWidth() ) / 2
	else
		xProgress = max( xProgress, 0 )
		xProgress = min( xProgress, xLimit )
	endif
	
	return xProgress
	
End // NMProgressX

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressY()
	
	Variable yProgress = NeuroMaticVar( "yProgress" )
	Variable yLimit = NMComputerPixelsY() - NMProgressHeight()
	
	if ( numtype( yProgress ) > 0 )
		yProgress = 0.5 * NMComputerPixelsY()
	else
		yProgress = max( yProgress, 0 )
		yProgress = min( yProgress, yLimit )
	endif
	
	return yProgress

End // NMProgressY

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressWidth()

	return 250

End // NMProgressWidth

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressHeight()

	return 100

End // NMProgressHeight

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressFlag()

	Variable progflag = NeuroMaticVar( "ProgFlag" )
	
	if ( progflag > 0 )
	
		if ( IgorVersion() >= 6.1 )
			//return 2 // new Igor progress
			return 1 // use ProgWin XOP
		endif
		
		return 1 // use ProgWin XOP
	
	endif
	
	return 0

End // NMProgressFlag

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgFlagDefault()

	if ( IgorVersion() >= 6.1 )
		return 2 // use Igor built-in Progress Window
	endif
	
	Execute /Z "ProgressWindow kill"
			
	if ( V_flag == 0 )
		return 1 // ProgWin XOP exists, so use this
	endif
	
	Execute /Z "ProgressWindow kill"
		
	if ( V_flag != 0 )
		NMDoAlert( "NM Alert: ProgWin XOP cannot be located. This XOP can be downloaded from www.wavemetrics.com/Support/ftpinfo.html." )
	endif
	
	return 0 // no progress window exists

End // NMProgFlagDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressOn( pflag ) // set Progress flag
	Variable pflag // ( 0 ) off ( 1 ) use ProgWin XOP ( 2 ) use Igor Progress Window
	
	if ( pflag == 1 )
		
		Execute /Z "ProgressWindow kill"
		
		if ( V_flag != 0 )
		
			if ( IgorVersion() >= 6.1 )
				pflag = 2
			else
				NMDoAlert( "NM Alert: ProgWin XOP cannot be located. This XOP can be downloaded from www.wavemetrics.com/Support/ftpinfo.html." )
				pflag = 0
			endif
			
		endif
		
	endif
		
	if ( pflag == 2 )
	
		if ( IgorVersion() < 6.1 )
			NMDoAlert( "NM Alert: this version of Igor does not support Progress Windows." )
			pflag = 0
		endif
		
	endif
	
	SetNeuroMaticVar( "ProgFlag", pflag )
	
	return pflag

End // NMProgressOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressCancel()
	
	switch( NMProgressFlag() )
	
		case 1:
			return NumVarOrDefault( "V_Progress", 0 ) // ProgWin XOP
			
		case 2:
			return NeuroMaticVar( "NMProgressCancel" ) // Igor Window Progress
	
	endswitch

	return 0

End // NMProgressCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function ResetProgress()

	Execute /Z "ProgressWindow kill"
	KillVariables /Z V_Progress
	
	if ( WinType( "NMProgressPanel" ) == 7 )
		KillWindow NMProgressPanel
	endif
	
	SetNeuroMaticVar( "NMProgressCancel", 0 )
	
	SetNeuroMaticStr( "ProgressStr", "" )
	
End // ResetProgress

//****************************************************************
//****************************************************************
//****************************************************************

Function CallNMProgress( count, maxIterations )
	Variable count, maxIterations
	
	return CallProgress( count / ( maxIterations - 1 ) ) // counting from zero
	
End // CallNMProgress

//****************************************************************
//****************************************************************
//****************************************************************

Function CallProgress( fraction )
	Variable fraction // fraction of progress ( 0 ) create ( 1 ) kill prog window ( -1 ) create candy ( -2 ) spin
	
	// returns 1 for cancel
	
	if (numtype( fraction ) > 0 )
		return -1
	endif
	
	switch( NMProgressFlag() )
	
		case 1:
			return NMProgWinXOP( fraction )
			
		case 2:
			return NMProgress61( fraction )
			
	endswitch
	
	return 0

End // CallProgress

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgWinXOP( fraction )
	Variable fraction // fraction of progress ( 0 ) create ( 1 ) kill prog window ( -1 ) create candy ( -2 ) spin
	
	Variable xProgress = NMProgressX()
	Variable yProgress = NMProgressY()
	
	String ProgressStr = NeuroMaticStr( "ProgressStr" )
	
	String win = "win=( " + num2str( xProgress ) + "," + num2str( yProgress ) + " )"
	String txt = "text=" + NMQuotes( ProgressStr )
	
	if (numtype( fraction ) > 0 )
		return -1
	endif

	if ( fraction == -1 )
		Execute /Z "ProgressWindow open=candy, button=\"cancel\", buttonProc=NMProgCancel," + win + "," + txt
	elseif ( fraction == -2 )
		Execute /Z "ProgressWindow spin"
	elseif ( fraction == 0 )
		Execute /Z "ProgressWindow open, button=\"cancel\", buttonProc=NMProgCancel," + win + "," + txt
		KillVariables /Z V_Progress
	endif
	
	if ( fraction >= 0 )
		Execute /Z "ProgressWindow frac=" + num2str( fraction )
	endif
	
	if ( fraction >= 1 )
		Execute /Z "ProgressWindow kill"
		KillVariables /Z V_Progress
		SetNeuroMaticStr( "ProgressStr", "" )
	endif
	
	Variable pflag = NumVarOrDefault( "V_Progress", 0 ) // progress flag, set to 1 if user hits "cancel" on ProgWin
	
	if ( pflag == 1 )
		Execute /Z "ProgressWindow kill"
	endif
	
	return pflag // returns the value of V_Progress ( WinProg XOP ), or 0 if it does not exist

End // NMProgWinXOP

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgCancel( buttonNum, buttonName )
	Variable buttonNum
	String buttonName
	
	Execute /Z "ProgressWindow kill"
	SetNeuroMaticStr( "ProgressStr", "" )
	
End // NMProgCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgress61( fraction ) // based on code from Igor Progress Windows Help
	Variable fraction // fraction of progress ( 0 ) create ( 1 ) kill prog window ( -1 ) create candy ( -2 ) spin
	
	Variable start = 0, kill = 0;
	
	String ProgressStr = NeuroMaticStr( "ProgressStr" )
	
	Variable xProgress = NMProgressX()
	Variable yProgress = NMProgressY()
	
	variable width=NMProgressWidth()
	variable height=NMProgressHeight()
	
	Variable cancelvar = NeuroMaticVar( "NMProgressCancel" )
	
	if ( numtype( fraction ) > 0 )
		return -1
	endif
	
	if ( IgorVersion() < 6.1 )
		return -1 // not available
	endif
	
	if ( ( fraction == 0 ) || ( fraction == -1 ) )
		start = 1
		cancelvar = 0
	elseif ( (fraction > 0 ) && ( WinType( "NMProgressPanel" ) == 0 ) )
		kill = 1 // progress window no longer exists
		cancelvar = 1
	elseif ( fraction >= 1 )
		kill = 1
		cancelvar = 0
	endif
	
	if ( kill == 1 )
	
		SetNeuroMaticStr( "ProgressStr", "" )
	
		if ( WinType( "NMProgressPanel" ) == 7 )
			KillWindow NMProgressPanel
		endif
		
		return cancelvar
	
	endif
	
	if ( start == 1 )
	
		if ( WinType( "NMProgressPanel" ) != 0 )
			KillWindow NMProgressPanel
		endif
	
		NewPanel /FLT/K=1/N=NMProgressPanel /W=(xProgress,yProgress,xProgress+width,yProgress+height) as "NM Progress"
		
		TitleBox /Z NM_ProgWinTitle, pos={5,10}, size={width-10,18}, fsize=9,fixedSize=1,win=NMProgressPanel
		TitleBox /Z NM_ProgWinTitle, frame=0,title=ProgressStr, anchor=MC,win=NMProgressPanel
	
		ValDisplay NM_ProgWinValDisplay,pos={5,40},size={width-10,18},limits={0,1,0},barmisc={0,0},win=NMProgressPanel
		ValDisplay NM_ProgWinValDisplay,highColor=(1,34817,52428),win=NMProgressPanel // green
		
		if ( fraction == -1 )
			ValDisplay NM_ProgWinValDisplay,mode=4,value= _NUM:1,win=NMProgressPanel // candy stripe
		else
			ValDisplay NM_ProgWinValDisplay,mode=3,value= _NUM:0,win=NMProgressPanel // bar with no fractional part
		endif
	
		Button NM_ProgWinButtonStop,pos={width/2-40,70},size={80,20},title="Cancel",win=NMProgressPanel
		
		SetActiveSubwindow _endfloat_
	
		DoUpdate /W=NMProgressPanel /E=1 // mark this as our progress window
		
		SetWindow NMProgressPanel,hook(cancel)= NMProgress61HookCancel
		
		SetNeuroMaticVar( "NMProgressCancel", 0) // reset cancel flag
		
		return 0
		
	endif
	
	if ( WinType( "NMProgressPanel" ) == 7 )
	
		//DoWindow /F NMProgressPanel
		
		if ( fraction >  0 )
			ValDisplay NM_ProgWinValDisplay,mode=3,value= _NUM:fraction,win=NMProgressPanel
		elseif ( fraction < 0 )
			ValDisplay NM_ProgWinValDisplay,mode=4,value= _NUM:1,win=NMProgressPanel
		endif
	
	endif
	
	return 0

End // NMProgress61

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgress61HookCancel(s)
	STRUCT WMWinHookStruct &s
	
	if ( s.eventCode == 23 )
	
		DoUpdate/W=$s.winName
		
		if ( V_Flag == 2 ) // we only have one button and that means abort
		
			SetNeuroMaticVar( "NMProgressCancel", 1 )
			
			if ( WinType( "NMProgressPanel" ) == 7 )
				//KillWindow NMProgressPanel
			endif
		
		endif
		
	endif
	
End // NMProgress61HookCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXYPanel() // set Progress X,Y location
	
	Variable width = NMProgressWidth()
	Variable xProgress = NMProgressX()
	Variable yProgress = NMProgressY()
	
	Variable x2 = xProgress + NMProgressWidth()
	Variable y2 = yProgress + NMProgressHeight()
	
	String titleStr = "Move to desired location and click save..."
	
	DoWindow /K NMProgressPanel
	NewPanel /K=1/N=NMProgressPanel/W=( xProgress,yProgress,x2,y2 ) as "Move NM Progress"
	
	TitleBox /Z NM_ProgTitle, pos={5,10}, size={width-10,18}, fsize=9,fixedSize=1,win=NMProgressPanel
	TitleBox /Z NM_ProgTitle, frame=0,title=titleStr, anchor=MC,win=NMProgressPanel
	
	Button NM_ProgButton, pos={75,40}, title = "Save Location", size={100,20}, proc=NMProgressXYButton

End // NMProgressXYPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXYButton( ctrlName ) : ButtonControl
	String ctrlName
	
	Variable x, y, scale = 1 // ( 4/3 )
	
	GetWindow NMProgressPanel, wsize
	
	x = round( V_left*scale )
	y = round( V_top*scale )
	
	NMProgressXYCall( x, y )
	
	DoWindow /K NMProgressPanel
	
End // NMProgressXYButton

//****************************************************************
//****************************************************************
//****************************************************************

Function TestNMProgress(candy )
	Variable candy // (0) no (1) yes

	Variable t0, i, j, imax=100
	
	SetNeuroMaticStr( "ProgressStr", "Testing Progress..." )
	
	if ( candy == 1 )
		CallProgress( -1 )
	endif
	
	for (i=0;i<imax;i+=1)
	
		if ( candy == 1 )
			j = -2
		else
			j = i / ( imax - 1 )
		endif
		
		if ( CallProgress( j ) == 1 )
			break // cancel
		endif
	
		t0=ticks
	
		do
		while( ticks < (t0+3) ) // slow down the loop
		
	endfor
	
	CallProgress(1)
	
	return 0

End // TestNMProgress

//****************************************************************
//****************************************************************
//****************************************************************