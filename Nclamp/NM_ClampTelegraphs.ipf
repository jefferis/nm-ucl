#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Telegraph Functions ( Gain, Freq, Cap, Mode, etc. )
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	Created in the Laboratory of Dr. Angus Silver
//	Department of Physiology, University College London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Began 24 March 2008
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTelegraphNumSamples()

	return 10

End // ClampTelegraphNumSamples

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTelegraphInstrList()

	return "Axopatch200B;MultiClamp700;Dagan3900A;AlembicVE2;"

End // ClampTelegraphInstrList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTelegraphPrompt( type )
	String type // "Mode" or "Freq" or "Cap"

	String name, modeStr, tdf = ClampTabDF()
	
	Variable config = ConfigsTabIOnum()
	String instr = StrVarOrDefault( tdf+"TelegraphInstrument", "" )
	String instrList = ClampTelegraphInstrList()
	
	instrList = RemoveFromList( "MultiClamp700", instrList )

	Prompt instr "telegraphed instrument:", popup instrList
	
	DoPrompt "Telegraph " + type, instr
	
	if ( V_flag == 1 )
		return ""
	endif
	
	name = "T" + type + "_" + instr[0, 2]

	modeStr = ClampTelegraphStr( type, instr )
	
	ClampBoardNameSet( "ADC", config, name )
	ClampBoardUnitsSet( "ADC", config, "V" )
	ClampBoardScaleSet( "ADC", config, 1 )
	
	SetNMstr( tdf+"TelegraphInstrument", instr )
	
	return modeStr
	
End // ClampTelegraphPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTGainPrompt()

	Variable board, chan, output
	String name, chanStr, modeStr = ""
	
	String tdf = ClampTabDF(), cdf = ClampDF()

	Variable config = ConfigsTabIOnum()
	String instr = StrVarOrDefault( tdf+"TelegraphInstrument", "" )
	String blist = StrVarOrDefault( cdf+"BoardList", "" )

	Prompt instr "telegraphed instrument:", popup ClampTelegraphInstrList()
	
	DoPrompt "Telegraph Gain", instr
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( tdf+"TelegraphInstrument", instr )
	
	if ( StringMatch( instr, "MultiClamp700" ) == 1 )
	
		chan = 1
		output = 1
		
		Prompt chan "this ADC input is connected to channel:", popup "1;2;"
		Prompt output " ", popup "primary output;secondary output;"
		
		DoPrompt "MultiClamp700 Telegraph Gain", chan, output
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		return ClampTGainStrMultiClamp( chan, output )
	
	endif
	
	Prompt chan "ADC input channel to scale:"
	Prompt board "on board number:", popup blist
	
	if ( ItemsInList( blist ) > 1 )
		DoPrompt instr + " Telegraph Gain", chan, board
	else
		DoPrompt instr + " Telegraph Gain", chan
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	name = "TGain_" + instr[0, 2]

	modeStr = ClampTGainStr( board, chan, instr )
	
	ClampBoardNameSet( "ADC", config, name )
	ClampBoardUnitsSet( "ADC", config, "V" )
	ClampBoardScaleSet( "ADC", config, 1 )
	
	SetNMstr( tdf+"TelegraphInstrument", instr )
	
	return modeStr
	
End // ClampTGainPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTelegraphStr( select, instrument )
	String select // "Mode", "Freq", "Cap" (see ClampTGrainStr below)
	String instrument
	
	return "T" + select + "=" + instrument
	
End // ClampTelegraphStr

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTelegraphCheck( select, modeStr )
	String select // "Gain", "Mode", "Freq", "Cap"
	String modeStr
	
	String findStr = "T" + select + "="
	
	if ( strsearch( modeStr, findstr, 0, 2 ) >= 0 )
		return 1
	endif
	
	return 0
	
End // ClampTelegraphCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTelegraphInstrument( modeStr )
	String modeStr
	
	Variable icnt
	String instrument, instrList
	
	instrList = ClampTelegraphInstrList()
	
	for ( icnt = 0 ; icnt < ItemsInList( instrList ) ; icnt += 1 )
	
		instrument = StringFromList( icnt, instrList )
		
		if ( strsearch( modeStr, instrument, 0, 2 ) > 0 )
			return instrument
		endif
		
	endfor
	
	return ""
	
End // ClampTelegraphInstrument

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTelegraphStrShort( modeStr )
	String modeStr
	
	Variable icnt
	String bname, blist = ClampTelegraphInstrList()
	
	if ( StringMatch( modeStr[0,0], "T" ) == 0 )
		return "" // wrong format
	endif
	
	if ( strsearch( modeStr, "=", 0 ) < 0 )
		return "" // wrong format
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( blist ) ; icnt += 1 )
		bname = StringFromList( icnt, blist )
		modeStr = ReplaceString( bname, modeStr, bname[0,2])
	endfor
	
	return modeStr

End // ClampTelegraphStrShort

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTelegraphAuto()

	TModeAuto()
	TCapAuto()
	TFreqAuto()

End // ClampTelegraphAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTGainStr( board, chan, instrument )
	Variable board
	Variable chan
	String instrument
	
	if ( ( numtype( board ) > 0 ) || ( board < 0 ) )
		board = 0
	endif
	
	if ( ( numtype( chan ) > 0 ) || ( chan < 0 ) )
		chan = Nan
	endif
	
	return "TGain=B" + num2str( board ) + "_C" + num2str( chan ) + "_" + instrument
	
End // ClampTGainStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTGainStrMultiClamp( chan, output )
	Variable chan // 1 or 2
	Variable output // 1 ( primary ) or 2 ( secondary )
	
	if ( chan != 2 )
		chan = 1
	endif
	
	if ( output != 2 )
		output = 1
	endif
	
	return "TGain=C" + num2str( chan ) + "_O" + num2str( output ) + "_MultiClamp700"
	
End // ClampTGainStrMultiClamp

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainStrSearch( modeStr, searchStr )
	String modeStr
	String searchStr
	
	Variable icnt, jcnt, slen = strlen( searchStr )
	
	icnt = strsearch( modeStr, searchStr, 0, 2 )
	
	if ( icnt < 0 )
		return Nan
	endif
	
	icnt += slen
	
	jcnt = strsearch( modeStr, "_", icnt )
	
	if ( jcnt < 0 )
		return Nan
	endif
	
	return str2num( modeStr[icnt, jcnt - 1] )
	
End // ClampTGainStrSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainBoard( modeStr )
	String modeStr
	
	return ClampTGainStrSearch( modeStr, "=B" )
	
End // ClampTGainBoard

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainChan( modeStr )
	String modeStr
	
	Variable chan = ClampTGainStrSearch( modeStr, "_C" )
	
	if ( numtype( chan ) > 0 )
		chan = ClampTGainStrSearch( modeStr, "=C" )
	endif
	
	return chan
	
End // ClampTGainChan

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTGainConfigNameList()

	Variable icnt
	String nlist = "", cdf = ClampDF()
	
	String TGainList = StrVarOrDefault( cdf+"TGainList", "" )
	
	for ( icnt = 0; icnt < ItemsInList( TGainList ); icnt += 1 )
		nlist = AddListItem( "TGain_" + num2str( icnt ), nlist, ";", inf )
	endfor
	
	return nlist

End // ClampTGainConfigNameList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTGainInstrumentFind( config )
	Variable config
	
	String modeStr
	
	String bdf = StimBoardDF( "" )

	if ( WaveExists( $bdf+"ADCmode" ) == 1 )
	
		Wave /T ADCmode = $bdf+"ADCmode"
		
		modeStr = ADCmode[config]
		
		if ( ClampTelegraphCheck( "Gain", modeStr ) == 1 )
			return ClampTelegraphInstrument( modeStr )
		endif
		
	endif
	
	return ""

End // ClampTGainInstrumentFind

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainConfigEditOld( config )
	Variable config
	
	Variable gchan, achan, icnt, kill = 1
	String item, instr, newList = "", cdf = ClampDF()
	
	String TGainList = StrVarOrDefault( cdf+"TGainList", "" )
	
	item = StringFromList( config, TGainList )
	
	if ( strlen( item ) == 0 )
		return -1
	endif
	
	gchan = str2num( StringFromList( 0, item, "," ) )
	achan = str2num( StringFromList( 1, item, "," ) )
	instr = StringFromList( 2, item, "," )
	
	Prompt gchan, "ADC input channel to read telegraph gain:"
	Prompt achan, "ADC input channel to scale:"
	Prompt instr, "telegraphed instrument:", popup ClampTelegraphInstrList()
	Prompt kill, "or delete this telegraph configuration:", popup "no;yes;"
	
	DoPrompt "ADC Telegraph Gain Config " + num2str( config ), gchan, achan, instr, kill
		
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	for ( icnt = 0; icnt < ItemsInList( TGainList ); icnt += 1 )
		
		if ( icnt == config )
		
			if ( kill == 2 )
				continue
			endif
			
			item = num2str( gchan ) + "," + num2str( achan ) + "," + instr
			
		else
		
			item = StringFromList( icnt, TGainList )
			
		endif
		
		newList = AddListItem( item, newList, ";", inf )
	
	endfor
	
	SetNMstr( cdf+"TGainList", newList )

End // ClampTGainConfigEditOld

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainValue( df, config, waveNum )
	String df // data folder
	Variable config
	Variable waveNum
	
	Variable npnts
	
	String wname = df + "CT_TGain" + num2str( config ) // telegraph gain wave
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif
	
	Wave temp = $wname

	if ( waveNum == -1 ) // return avg of wave
		temp = Zero2Nan( temp ) // remove possible 0's
		WaveStats /Q temp
		return V_avg
	else
		return temp[waveNum]
	endif

End // ClampTGainValue

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainConvert() // convert final TGain values to scale values
	Variable ocnt, icnt, tvalue, npnts, chan, gchan, achan
	String olist, oname, item
	
	String instr, cdf = ClampDF()
	
	String TGainList = StrVarOrDefault( cdf+"TGainList", "" )
	String instrOld = StrVarOrDefault( cdf+"ClampInstrument", "" )
	
	olist = WaveList( "CT_TGain*", ";", "" ) // created by NIDAQ code
	
	if ( ItemsInList( TGainList ) <= 0 )
		return 0
	endif
	
	for ( ocnt = 0; ocnt < ItemsInList( olist ); ocnt += 1 )
	
		oname = StringFromList( ocnt, olist )
		chan = str2num( oname[8,inf] )
		
		instr = ""
		
		for ( icnt = 0; icnt < ItemsInList( TGainList ); icnt += 1 )
		
			item = StringFromList( icnt, TGainList )
			gChan = str2num( StringFromList( 0, item, "," ) ) // corresponding telegraph ADC input channel
			aChan = str2num( StringFromList( 1, item, "," ) ) // ADC input channel
			
			if ( chan == aChan )
				instr = StringFromList( 2, item, "," )
			endif
			
		endfor
		
		if ( strlen( instr ) == 0 )
			instr = instrOld
		endif
		
		Wave wtemp = $oname
		
		npnts = numpnts( wtemp )
		
		for ( icnt = 0; icnt < npnts; icnt += 1 )
		
			tvalue = wtemp[icnt]
			
			if ( numtype( tvalue ) == 0 )
				wtemp[icnt] = MyTelegraphGain( tvalue, tvalue, instr )
			endif
			
		endfor
	
	endfor
	
	olist = VariableList( "CT_TGain*",";",4+2 ) // created by ITC code
	
	for ( ocnt = 0; ocnt < ItemsInList( olist ); ocnt += 1 )
	
		oname = StringFromList( ocnt, olist )
		
		tvalue = NumVarOrDefault( oname, -1 )
		
		chan = str2num( oname[5,inf] )
		
		instr = ""
		
		for ( icnt = 0; icnt < ItemsInList( TGainList ); icnt += 1 )
		
			item = StringFromList( icnt, TGainList )
			gChan = str2num( StringFromList( 0, item, "," ) ) // corresponding telegraph ADC input channel
			aChan = str2num( StringFromList( 1, item, "," ) ) // ADC input channel
			
			if ( chan == aChan )
				instr = StringFromList( 2, item, "," )
			endif
			
		endfor
		
		if ( strlen( instr ) == 0 )
			instr = instrOld
		endif
		
		if ( tvalue == -1 )
			continue
		endif
		
		SetNMvar( oname, MyTelegraphGain( tvalue, tvalue, instr ) )
		
	endfor

End // ClampTGainConvert

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTelegraphGain( TGain, defaultTGain, instrument ) // see NIDAQ code for example call
	Variable TGain // telegraphed value
	Variable defaultTGain // default gain value
	String instrument // instrument name
	
	Variable scale, betaV, alpha = -1, gain=defaultTGain
	
	strswitch( instrument )
	
		case "Axopatch200B":
			alpha = TGainAxopatch200B( TGain )
			betaV = 1 // whole cell
			scale = 0.001 * betaV // V / mV
			break
			
		case "Dagan3900A":
			alpha = TGainDagan3900A( TGain )
			scale = 0.001
			break
			
		case "AlembicVE2":
			alpha = TGainAlembicVE2( TGain )
			scale = 0.001
			break
			
		default:
			alpha = -1
			
	endswitch
	
	if ( ( alpha > 0 ) && ( numtype( alpha ) == 0 ) )
		gain = alpha * scale
	endif
	
	NotesFileVar( "F_TGain", gain )
	
	return gain
	
End // MyTelegraphGain

//****************************************************************
//****************************************************************
//****************************************************************

Function TGainAxopatch200B( telValue ) // Axopatch 200B telegraph gain look-up table
	Variable telValue
	
	Variable tv = 5 * round( 10 * telValue / 5 ) // multiply by 10 and round to nearest multiple of 5
	
	switch( tv )
		case 5:
			return 0.05
		case 10:
			return 0.1
		case 15:
			return 0.2
		case 20:
			return 0.5
		case 25:
			return 1
		case 30:
			return 2
		case 35:
			return 5
		case 40:
			return 10
		case 45:
			return 20
		case 50:
			return 50
		case 55:
			return 100
		case 60:
			return 200
		case 65:
			return 500
		default:
			Print "\rAxopatch 200B Telegraph Gain not recognized : " + num2str( telValue )
	endswitch
	
	return -1

End // TGainAxopatch200B

//****************************************************************
//****************************************************************
//****************************************************************

Function TGainAlembicVE2( telValue ) // TGainAlembic VE2 telegraph gain look-up table
	Variable telValue
	
	Variable tv = 5 * round( 10 * telValue / 5 ) // multiply by 10 and round to nearest multiple of 5
	
	switch( tv )
		case 5:
			return 0.05
		case 10:
			return 0.1
		case 15:
			return 0.2
		case 20:
			return 0.5
		case 25:
			return 1
		case 30:
			return 2
		case 35:
			return 5
		default:
			Print "\rAlembic VE2 Telegraph Gain not recognized : " + num2str( telValue )
	endswitch
	
	return -1

End // TGainAlembicVE2

//****************************************************************
//****************************************************************
//****************************************************************

Function TGainDagan3900A( telValue ) // Dagan 3900A telegraph gain look-up table
	Variable telValue
	
	Variable tv = round( telValue / 0.405 )	
	
	switch( tv )
		case 1:
			return 1
		case 2:
			return 2
		case 3:
			return 5
		case 4:
			return 10
		case 5:
			return 20
		case 6:
			return 50
		case 7:
			return 100
		case 8:
			return 500
		default:
			Print "\rDagan 3900A Telegraph Gain not recognized : " + num2str( telValue )
	endswitch
	
	return -1

End // TGainDagan3900A

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Telegraph Mode Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function TModeAuto()

	Variable wcnt, bcnt, icnt, found
	
	String instr, tmode, ndf = NotesDF()
	String bname, blist = ClampTelegraphInstrList()
	String wname, wlist = WaveList("CT_TMode*",";","")
	
	if ( exists( ndf + "F_TMode" ) == 2 )
		NotesFileStr("F_TMode", "") // clear existing note variables
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wlist ) ; wcnt += 1 )
	
		wname = StringFromList( wcnt, wlist )
		icnt = strlen( wname )
		instr = wname[icnt-3, icnt-1]
		
		found = 0
		
		for ( bcnt = 0 ; bcnt < ItemsInList( blist ) ; bcnt += 1 )
		
			bname = StringFromList( bcnt, blist )
			
			if ( StringMatch( instr, bname[0,2] ) == 1 )
				instr = bname
				found = 1
				break
			endif
			
		endfor
		
		if ( found == 0 )
			continue
		endif
		
		WaveStats /Q $wname
		
		tmode = ""
		
		strswitch( instr )
	
			case "Axopatch200B":
				tmode = TModeAxopatch200B(V_avg)
				break
			
		endswitch
		
		SetNMstr(wname+"_Setting", tmode )
		NotesFileStr("F_TMode", tmode)
	
	endfor

End // TModeAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function TModeCheck(mode) // check acquisition telegraph mode is set correctly
	Variable mode // (-1) kill (0) run (1) config (2) init
	
	String tmode, mode1, mode2, sdf = StimDF()
	
	String instr = StrVarOrDefault(sdf+"TModeInstrument", "")
	String amode = StrVarOrDefault(sdf+"TModeStr", "")
	
	String strName = "CT_TMode_" + instr[0,2] + "_Setting" // output string from TModeAuto
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
			TModeCheckConfig()
			return 0
			
		case 2:
		case -1:
		default:
			return 0
			
	endswitch
	
	if ( StringMatch( instr, "MultiClamp700" ) == 1 )
		
		if ( NMMultiClampTModeCheck( amode ) != 0 )
			return -1
		endif
		
	endif
	
	if ( exists( strName ) == 2 )
		
		tmode = StrVarOrDefault( strName, "" )
		
		if ( ( strlen( tmode ) > 0 ) && ( StringMatch( amode, tmode ) == 0 ) )
			ClampError(1, "acquisition mode should be " + amode)
			return -1
		endif
	
	endif
	
	return 0
	
End // TModeCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function TModeCheckConfig()
	
	String cdf = ClampDF(), sdf = StimDF()
	String select1, select2, mlist = ""
	
	String instr = StrVarOrDefault(sdf+"TModeInstrument", "")
	String tmode = StrVarOrDefault(sdf+"TModeStr", "")
	
	Prompt instr, "telegraphed instrument:", popup ClampTelegraphInstrList()
	
	DoPrompt "Check Telegraph Mode", instr
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMstr(sdf+"TModeInstrument", instr)
	
	mlist = TModeList( instr )
	
	if ( StringMatch( instr, "MultiClamp700" ) == 1 )
	
		select1 = StringFromList( 0, tmode )
		select2 = StringFromList( 1, tmode )
		
		Prompt select1, "choose mode required for channel 1:", popup mlist
		Prompt select2, "choose mode required for channel 2:", popup mlist
		DoPrompt "Check Telegraph Mode", select1, select2
		
		if (V_flag == 1)
			return 0 // cancel
		endif
		
		tmode = select1 + ";" + select2 + ";"
	
	else
	
		Prompt tmode, "choose mode required for this protocol:", popup mlist
		DoPrompt "Check Telegraph Mode", tmode
		
		if (V_flag == 1)
			return 0 // cancel
		endif
		
	endif
	
	SetNMstr(sdf+"TModeStr", tmode)

End // TModeCheckConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function TModeCheckOld(mode) // check acquisition telegraph mode is set correctly
	Variable mode // (-1) kill (0) run (1) config (2) init
	
	Variable telValue
	String tmode, cdf = ClampDF(), sdf = StimDF()
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
			TModeCheckConfig()
			return 0
			
		case 2:
		case -1:
		default:
			return 0
			
	endswitch
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
	Variable chan = NumVarOrDefault(cdf+"TModeChan", -1)
	String amode = StrVarOrDefault(sdf+"TModeStr", "")
	String instr = StrVarOrDefault(cdf+"ClampInstrument", "Axopatch200B")
	
	if (chan < 0)
		return -1
	endif
	
	telValue = ClampReadManager(StrVarOrDefault(cdf+"AcqBoard", ""), driver, chan, 1, 5)
	tmode = TModeAxopatch200B(telValue)
	
	strswitch(instr)
	
		case "Axopatch200B":
		
			if (StringMatch(amode, "I-clamp") == 1)
				if (StringMatch(tmode[0,0], "I") == 1)
					tmode = "I-clamp"
				endif
			endif
			
			if (StringMatch(amode, tmode) == 0)
				ClampError(1, "acquisition mode should be " + amode)
				return -1
			endif
			
			break
			
	endswitch
	
	String /G TModeStr = amode
	
End // TModeCheckOld

//****************************************************************
//****************************************************************
//****************************************************************

Function TModeCheckConfigOld()
	String cdf = ClampDF(), sdf = StimDF()
	
	Variable board = NumVarOrDefault(cdf+"TModeBoard", 0)
	Variable chan = NumVarOrDefault(cdf+"TModeChan", 0)
	
	String instr = StrVarOrDefault(cdf+"TModeInstrument", "")
	String amode = StrVarOrDefault(sdf+"TModeStr", "")
	
	String mlist = "V-clamp;I-clamp;I-clamp Normal;I-clamp Fast;"
	
	Prompt chan, "select ADC input that reads telegraph mode:", popup "0;1;2;3;4;5;6;7;"
	Prompt amode, "choose mode required for this protocol:", popup mlist
	Prompt instr, "telegraphed instrument:", popup "Axopatch200B;"
	
	DoPrompt "Check Telegraph Mode", chan, amode, instr
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMvar(cdf+"TModeChan", chan-1)
	SetNMstr(sdf+"TModeStr", amode)

End // TModeCheckConfigOld

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TModeList( device )
	String device // i.e. "Axopatch200B"
	
	strswitch( device )
	
		case "Axopatch200B":
			return "Dont Care;V-clamp;I-clamp;I-clamp Normal;I-clamp Fast;"
			
		case "MultiClamp700":
			return "Dont Care;V-clamp;I-clamp;"
			
	endswitch
	
	return ""

End // TModeList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TModeAxopatch200B( telValue ) // Axopatch 200B telegraph mode look-up table
	Variable telValue
	
	Variable tv = 5*round( 10 * telValue / 5 )
	
	switch( tv )
		case 40:
			return "Track"
		case 60:
			return "V-Clamp"
		case 30:
			return "I = 0"
		case 20:
			return "I-Clamp Normal"
		case 10:
			return "I-Clamp Fast"
		default:
			Print "\rAxopatch 200B Telegraph Mode not recognized : " + num2str( telValue )
	endswitch
	
	return "Mode Not Recognized"

End // TModeAxopatch200B

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Telegraph Capacitance Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function TCapAuto()

	Variable wcnt, bcnt, icnt, found, cap
	Variable Axopatch200B_beta = 1
	
	String instr, ndf = NotesDF()
	String bname, blist = ClampTelegraphInstrList()
	String wname, wlist = WaveList("CT_TCap*",";","")
	
	if ( exists( ndf + "F_TCap" ) == 2 )
		NotesFileVar("F_TCap", Nan) // clear existing note variables
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wlist ) ; wcnt += 1 )
	
		wname = StringFromList( wcnt, wlist )
		icnt = strlen( wname )
		instr = wname[icnt-3, icnt-1]
		
		found = 0
		
		for ( bcnt = 0 ; bcnt < ItemsInList( blist ) ; bcnt += 1 )
		
			bname = StringFromList( bcnt, blist )
			
			if ( StringMatch( instr, bname[0,2] ) == 1 )
				instr = bname
				found = 1
				break
			endif
			
		endfor
		
		if ( found == 0 )
			continue
		endif
		
		WaveStats /Q $wname
		
		cap = Nan
		
		strswitch( instr )
	
			case "Axopatch200B":
				cap = TCapAxopatch200B(V_avg, Axopatch200B_beta)
				break
			
		endswitch
		
		SetNMvar(wname+"_Setting", cap )
		NotesFileVar("F_TCap", cap)
	
	endfor

End // TCapAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function TCapAxopatch200B( telValue, betaValue ) // Axopatch 200B telegraph cell capacitance look-up table
	Variable telValue
	Variable betaValue
	
	if ( ( telValue < 0 ) || ( telValue > 10 ) )
		Print "\rAxopatch 200B Telegraph Capacitance not recognized : " + num2str( telValue )
		return Nan
	endif
	
	if ( betaValue == 1 )
		return telValue * 10 // 0 - 100 pF
	elseif ( betaValue == 0.1 )
		return telValue * 100 // range 0 - 1000 pF
	else
		Print "\rAxopatch 200B Telegraph Capacitance not recognized : " + num2str( telValue )
		return Nan
	endif

End // TCapAxopatch200B

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Telegraph Frequency Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function TFreqAuto()

	Variable wcnt, bcnt, icnt, found, freq
	Variable beta = 1
	
	String instr, ndf = NotesDF()
	String bname, blist = ClampTelegraphInstrList()
	String wname, wlist = WaveList("CT_TFreq*",";","")
	
	if ( exists( ndf + "F_TFreq" ) == 2 )
		NotesFileVar("F_TFreq", Nan) // clear existing note variables
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wlist ) ; wcnt += 1 )
	
		wname = StringFromList( wcnt, wlist )
		icnt = strlen( wname )
		instr = wname[icnt-3, icnt-1]
		
		found = 0
		
		for ( bcnt = 0 ; bcnt < ItemsInList( blist ) ; bcnt += 1 )
		
			bname = StringFromList( bcnt, blist )
			
			if ( StringMatch( instr, bname[0,2] ) == 1 )
				instr = bname
				found = 1
				break
			endif
			
		endfor
		
		if ( found == 0 )
			continue
		endif
		
		WaveStats /Q $wname
		
		freq = Nan
		
		strswitch( instr )
	
			case "Axopatch200B":
				freq = TFreqAxopatch200B(V_avg)
				break
			
		endswitch
		
		SetNMvar(wname+"_Setting", freq )
		NotesFileVar("F_TFreq", freq)
	
	endfor

End // TFreqAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function TFreqAxopatch200B( telValue ) // Axopatch 200B telegraph frequency look-up table
	Variable telValue
	
	Variable tv = 5*round( 10 * telValue / 5 )
	
	switch( tv )
		case 20:
			return 1
		case 40:
			return 2
		case 60:
			return 5
		case 80:
			return 10
		case 100:
			return 100
		default:
			Print "\rAxopatch 200B Telegraph Frequency not recognized : " + num2str( telValue )
	endswitch
	
	return Nan

End // TFreqAxopatch200B

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Telegraph Functions for MultiClamp700 amplifier
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampUseLongNames()

	return 0 // ( 0 ) short names ( 1 ) long names
	
End // NMMultiClampUseLongNames

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTelegraphWhile()

	return 1 // ( 0 ) read gain setting once before acquisition starts ( 1 ) read immediately after recording each wave

End // NMMultiClampTelegraphWhile

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampVarList( output )
	Variable output // ( 0 ) both ( 1 ) primary ( 2 ) secondary
	
	String strList0 = "OperatingMode;HardwareType;ExtCmdSens;MembraneCap;SeriesResistance;"
	String strList1 = "ScaledOutSignal;ScaleFactorUnits;ScaleFactor;Alpha;LPFCutoff;"
	String strList2 = "RawOutSignal;RawScaleFactorUnits;RawScaleFactor;SecondaryAlpha;SecondaryLPFCutoff;"
	
	switch( output )
		case 0:
			return strList0 + strList1 + strList2
		case 1:
			return strList0 + strList1
		case 2:
			return strList0 + strList2
	endswitch
	
	return ""
	
End // NMMultiClampVarList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampStrVarList( output )
	Variable output // ( 0 ) both ( 1 ) primary ( 2 ) secondary
	
	String strList0 = "OperatingMode;HardwareType;"
	String strList1 = "ScaledOutSignal;ScaleFactorUnits;"
	String strList2 = "RawOutSignal;RawScaleFactorUnits;"
	
	switch( output )
		case 0:
			return strList0 + strList1 + strList2
		case 1:
			return strList0 + strList1
		case 2:
			return strList0 + strList2
	endswitch
	
	return ""

End // NMMultiClampStrVarList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampServerWave()

	return ClampDF() + "W_TelegraphServers"

End // NMMultiClampServerWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampCheck()

	if ( exists( "AxonTelegraphFindServers" ) != 4 )
		DoAlert 0, "Alert: located MultiClamp700 telegraph configurations but cannot access the Axon Telegraph XOP."
		return -1 // ERROR
	endif
	
	if ( NMMultiClampServersCheck() != 0 )
		DoAlert 0, "Alert: located MultiClamp700 telegraph configurations but cannot access the Axon Telegraph Servers."
		return -1 // ERROR
	endif
	
	return 0
	
End // NMMultiClampCheck()

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampServersCheck()

	Variable numServers
	String saveDF, cdf = ClampDF()
	
	String wname = NMMultiClampServerWave()
	
	if ( exists( "AxonTelegraphFindServers" ) != 4 )
		return -1
	endif
	
	if ( WaveExists( $wname ) == 1 )
		
		numServers = DimSize( $wname, 0 )
		
		if ( numServers > 0 )
			return 0
		endif
		
	endif
	
	if ( DataFolderExists( cdf ) == 0 )
		return -1
	endif
	
	saveDF = GetDataFolder( 1 )
	
	SetDataFolder $cdf

	Execute /Q/Z "AxonTelegraphFindServers /Z"
	
	SetDataFolder $saveDF
	
	if ( WaveExists( $wname ) == 1 )
		
		numServers = DimSize( $wname, 0 )
		
		if ( numServers > 0 )
			return 0
		endif
		
	endif
	
	return -1
	
End // NMMultiClampServersCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTelegraphMode( modeStr )
	String modeStr
	
	Variable chanNum, output
	
	if ( strsearch( modeStr, "MultiClamp700", 0 ) < 0 )
		return 0 // NO
	endif
	
	chanNum = ClampTGainStrSearch( modeStr, "=C" )
	output = ClampTGainStrSearch( modeStr, "_O" )
		
	if ( ( chanNum != 1 ) && ( chanNum != 2 ) )
		DoAlert 0, "MultiClamp Telegraph Error: bad channel number: " + num2str( chanNum )
		return 0
	endif
	
	if ( ( output != 1 ) && ( output != 2 ) )
		DoAlert 0, "MultiClamp Telegraph Error: bad output number: " + num2str( output )
		return 0
	endif

	return 1 // YES

End // NMMultiClampTelegraphMode

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampScale( chanNum, output )
	Variable chanNum // 1 or 2
	Variable output // 1 - primary, 2 - secondary
	
	switch( output )
		case 1:
			return NMMultiClampValue( chanNum, "ScaleFactor" ) * NMMultiClampValue( chanNum, "Alpha" )
		case 2:
			return NMMultiClampValue( chanNum, "RawScaleFactor" ) * NMMultiClampValue( chanNum, "SecondaryAlpha" )
	endswitch
	
	return Nan
	
End // NMMultiClampScale

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampScale2( modeStr )
	String modeStr
	
	Variable chanNum, output

	if ( NMMultiClampTelegraphMode( modeStr ) == 0 )
		return Nan
	endif
	
	chanNum = ClampTGainStrSearch( modeStr, "=C" )
	output = ClampTGainStrSearch( modeStr, "_O" )
	
	return NMMultiClampScale( chanNum, output )

End // NMMultiClampScale2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampUnits( chanNum, output )
	Variable chanNum // 1 or 2
	Variable output // 1 - primary, 2 - secondary
	
	Variable strLength  = NMMultiClampUseLongNames()
	
	switch( output )
		case 1:
			return NMMultiClampStrValue( chanNum, "ScaleFactorUnits", strLength )
		case 2:
			return NMMultiClampStrValue( chanNum, "RawScaleFactorUnits", strLength )
	endswitch
	
	return ""
	
End // NMMultiClampUnits

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampSignal( chanNum, output )
	Variable chanNum // 1 or 2
	Variable output // 1 - primary, 2 - secondary
	
	Variable strLength  = NMMultiClampUseLongNames()
	
	switch( output )
		case 1:
			return NMMultiClampStrValue( chanNum, "ScaledOutSignal", strLength )
		case 2:
			return NMMultiClampStrValue( chanNum, "RawOutSignal", strLength )
	endswitch
	
	return ""
	
End // NMMultiClampSignal

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampValue( chanNum, varName )
	Variable chanNum // 1 or 2
	String varName // e.g. "Alpha"
	
	Variable scnt, value, serialNum, chanID, comPortID, axoBusID 
	String params
	
	String wname = NMMultiClampServerWave()
	
	switch( chanNum )
		case 1:
		case 2:
			break
		default:
			return Nan
	endswitch
	
	if ( WhichListItem( varName, NMMultiClampVarList( 0 ) ) < 0 )
		return Nan
	endif
	
	if ( NMMultiClampServersCheck() != 0 )
		return Nan
	endif
	
	if ( WaveExists( $wname ) == 0 )
		return Nan
	endif
	
	Wave servers = $wname
	
	for ( scnt = 0 ; scnt < DimSize( servers, 0 ) ; scnt += 1 )
	
		serialNum = servers[ scnt ][ 0 ]
		chanID = servers[ scnt ][ 1 ]
		comPortID = servers[ scnt ][ 2 ]
		axoBusID = servers[ scnt ][ 3 ]
		
		if ( chanID == chanNum )
		
			Variable /G NM_TempValue = Nan
		
			if ( serialNum < 0 ) // 700A
				params = num2str( comPortID ) + ", " + num2str( axoBusID ) + ", " + num2str( chanID ) + ", " + StrQuotes( varName ) 
				Execute /Q/Z "NM_TempValue = AxonTelegraphAGetDataNum( " + params + " )"
			else // 700B
				params = num2str( serialNum ) + ", " + num2str( chanID ) + ", " + StrQuotes( varName ) 
				Execute /Q/Z "NM_TempValue = AxonTelegraphGetDataNum( " + params + " )"
			endif
			
			value = NM_TempValue
			
			KillVariables /Z NM_TempValue
			
			return value
		
		endif
		
	endfor
	
	return Nan
	
End // NMMultiClampValue

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampStrValue( chanNum, varName, strLengthFlag )
	Variable chanNum // 1 or 2
	String varName // e.g. "ScaleFactorUnits"
	Variable strLengthFlag // ( 0 ) short name ( 1 ) long name
	
	Variable scnt, serialNum, chanID, comPortID, axoBusID
	String params, strValue
	
	String wname = NMMultiClampServerWave()
	
	switch( chanNum )
		case 1:
		case 2:
			break
		default:
			return ""
	endswitch
	
	if ( WhichListItem( varName, NMMultiClampStrVarList( 0 ) ) < 0 )
		return ""
	endif
	
	if ( NMMultiClampServersCheck() != 0 )
		return ""
	endif
	
	if ( WaveExists( $wname ) == 0 )
		return ""
	endif
	
	Wave servers = $wname
	
	for ( scnt = 0 ; scnt < DimSize( servers, 0 ) ; scnt += 1 )
	
		serialNum = servers[ scnt ][ 0 ]
		chanID = servers[ scnt ][ 1 ]
		comPortID = servers[ scnt ][ 2 ]
		axoBusID = servers[ scnt ][ 3 ]
		
		if ( chanID == chanNum )
		
			String /G NM_TempStr = ""
		
			if ( serialNum < 0 ) // 700A
				params = num2str( comPortID ) + ", " + num2str( axoBusID ) + ", " + num2str( chanID ) + ", " + StrQuotes( varName ) + ", " + num2str( strLengthFlag )
				Execute /Q/Z "NM_TempStr = AxonTelegraphAGetDataString( " + params + " )"
			else // 700B
				params = num2str( serialNum ) + ", " + num2str( chanID ) + ", " + StrQuotes( varName )  + ", " + num2str( strLengthFlag )
				Execute /Q/Z "NM_TempStr = AxonTelegraphGetDataString( " + params + " )"
			endif
			
			strValue = NM_TempStr
			
			KillStrings /Z NM_TempStr
			
			return strValue
		
		endif
		
	endfor
	
	return ""
	
End // NMMultiClampStrValue

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTelegraphsSave( folder )
	String folder // where to save the telegraph server information ( "" ) for current data folder

	Variable scnt, numServers, icnt, value
	Variable serialNum, chanID, comPortID, axoBusID
	String subfolder1, subfolder2, params, varName
	
	Variable /G NM_TempValue
	String /G NM_TempStr
	
	Variable strLength = NMMultiClampUseLongNames()
	
	String varList = NMMultiClampVarList( 0 )
	String strVarList = NMMultiClampStrVarList( 0 )
	
	String wname = NMMultiClampServerWave()
	
	if ( strlen( folder ) == 0 )
		folder = GetDataFolder( 1 )
	endif
	
	if ( DataFolderExists( folder ) == 0 )
		return -1
	endif
	
	if ( NMMultiClampServersCheck() != 0 )
		return -1
	endif
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif

	Wave servers = $wname
	
	numServers = DimSize( servers, 0 )
	
	if ( numServers <= 0 )
		return -1
	endif
	
	subfolder1 = folder + "MultiClampTelegraphs:"
	
	if ( DataFolderExists( subfolder1 ) == 1 )
		KillDataFolder /Z $LastPathColon( subfolder1, 0 )
	endif
	
	NewDataFolder /O $LastPathColon( subfolder1, 0 )
	
	for ( scnt = 0 ; scnt < numServers ; scnt += 1 )
	
		serialNum = servers[ scnt ][ 0 ]
		chanID = servers[ scnt ][ 1 ]
		comPortID = servers[ scnt ][ 2 ]
		axoBusID = servers[ scnt ][ 3 ]
	
		if ( serialNum < 0 ) // 700A
			folder = "port" + num2str( comPortID ) + "_bus" + num2str( axoBusID ) + "_chan" + num2str( chanID ) + ":"
			params = num2str( comPortID ) + ", " + num2str( axoBusID ) + ", " + num2str( chanID ) + ", "
		else // 700B
			folder = "serial" + num2str( serialNum ) + "_chan" + num2str( chanID ) + ":"
			params = num2str( serialNum ) + ", " + num2str( chanID ) + ", "
		endif
		
		subfolder2 = subfolder1 + folder
		
		NewDataFolder /O $LastPathColon( subfolder2, 0 )
		
		for ( icnt = 0 ; icnt < ItemsInList( varList ) ; icnt += 1 )
			
			varName = StringFromList( icnt, varList )
			
			if ( serialNum < 0 ) // 700A
				Execute /Q/Z "NM_TempValue = AxonTelegraphAGetDataNum( " + params + StrQuotes( varName ) + " )"
			else // 700B
				Execute /Q/Z "NM_TempValue = AxonTelegraphGetDataNum( " + params + StrQuotes( varName ) + " )"
			endif
			
			Variable /G $subfolder2+varName = NM_TempValue
			
		endfor
		
		for ( icnt = 0 ; icnt < ItemsInList( strVarList ) ; icnt += 1 )
			
			varName = StringFromList( icnt, strVarList )
			
			if ( serialNum < 0 ) // 700A
				Execute /Q/Z "NM_TempStr = AxonTelegraphAGetDataString( " + params + StrQuotes( varName ) + ", " + num2str( strLength ) + " )"
			else // 700B
				Execute /Q/Z "NM_TempStr = AxonTelegraphGetDataString( " + params + StrQuotes( varName ) + ", " + num2str( strLength ) + " )"
			endif
			
			String /G $subfolder2+varName+"Str" = NM_TempStr
			
		endfor
	
	endfor
	
	KillVariables /Z NM_TempValue
	KillStrings /Z NM_TempStr
	
	return 0

End // NMMultiClampTelegraphsSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampADCWavePath( stimDF, waveSelect )
	String stimDF
	String waveSelect
	
	String bdf = StimBoardDF( stimDF )
	
	strswitch( waveSelect )
	
		case "scale":
			return  bdf + "ADCscale_MultiClamp"
			
		case "units":
			return bdf + "ADCunits_MultiClamp"
			
		case "name":
			return bdf + "ADCname_MultiClamp"
			
	endswitch
	
	return ""

End // NMMultiClampADCWavePath

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTelegraphsConfig( stimDF ) // configure scale factor waves
	String stimDF

	Variable icnt, found, numConfigs, chanNum, output, value
	String modeStr, unitsStr
	String bdf = StimBoardDF( stimDF )
	
	String scaleName = NMMultiClampADCWavePath( stimDF, "scale" )
	String unitsName = NMMultiClampADCWavePath( stimDF, "units" )
	String signalName = NMMultiClampADCWavePath( stimDF, "name" )
	
	Wave /T ADCmode = $bdf+"ADCmode"
	
	numConfigs = numpnts( ADCmode )
	
	for ( icnt = 0 ; icnt < numConfigs ; icnt += 1 )
		
		if ( strsearch( ADCmode[ icnt ], "MultiClamp700", 0 ) > 0 )
			found = 1
		endif
	
	endfor
	
	if ( found == 0 )
	
		KillWaves /Z $scaleName, $unitsName, $signalName
	
		SetNMvar( stimDF+"MultiClamp700", 0 ) // set MultiClamp flag to NO
		
		return 0
		
	endif
	
	if ( NMMultiClampCheck() != 0 )
		return -1
	endif
	
	Make /O/N=( numConfigs ) $scaleName = Nan
	Make /T/O/N=( numConfigs ) $unitsName = ""
	Make /T/O/N=( numConfigs ) $signalName = ""
	
	Wave ADCscale = $scaleName
	Wave /T ADCunits = $unitsName
	Wave /T ADCname = $signalName
	
	for ( icnt = 0 ; icnt < numConfigs ; icnt += 1 )
	
		modeStr = ADCmode[ icnt ]
		
		if ( NMMultiClampTelegraphMode( modeStr ) == 1 )
		
			chanNum = ClampTGainStrSearch( modeStr, "=C" )
			output = ClampTGainStrSearch( modeStr, "_O" )
			
			ADCscale[ icnt ] = NMMultiClampScale( chanNum, output )
			
			if ( numtype( ADCscale[ icnt ] ) > 0 )
				DoAlert 0, "Alert: located MultiClamp700 telegraph configurations but cannot access the Axon Telegraph Servers."
				return -1
			endif
			
			unitsStr = NMMultiClampUnits( chanNum, output )
			
			if ( StringMatch( unitsStr, "V/V" ) == 1 )
			
				ADCscale[ icnt ] /= 1000 // convert to V/mV
				ADCunits[ icnt ] = "mV"
			
			else
			
				ADCunits[ icnt ] = ReplaceString( "V/", unitsStr, "" )
				
			endif
			
			ADCname[ icnt ] = NMMultiClampSignal( chanNum, output )
			
		endif
		
	endfor
	
	SetNMvar( stimDF+"MultiClamp700", 1 )  // set MultiClamp flag to YES
	
	return 0

End // NMMultiClampTelegraphsConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampADCNum( stimDF, config, select )
	String stimDF
	Variable config
	String select // "scale"
	
	String wname = NMMultiClampADCWavePath( stimDF, select )
	
	if ( NumVarOrDefault( stimDF + "MultiClamp700", 0 ) == 0 )
		return Nan
	endif
	
	if ( WaveExists($wname) == 0 )
		return Nan
	endif
	
	if ( ( numtype( config ) > 0 ) || ( config < 0 ) || ( config >= numpnts( $wname ) ) )
		return Nan
	endif
	
	Wave ADC_MC = $wname
	
	return ADC_MC[ config ]
	
End // NMMultiClampADCNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampADCStr( stimDF, config, select )
	String stimDF
	Variable config
	String select // "name" or "units"
	
	String wname = NMMultiClampADCWavePath( stimDF, select )
	
	if ( NumVarOrDefault( stimDF + "MultiClamp700", 0 ) == 0 )
		return ""
	endif
	
	if ( WaveExists( $wname ) == 0 )
		return ""
	endif
	
	if ( ( numtype( config ) > 0 ) || ( config < 0 ) || ( config >= numpnts( $wname ) ) )
		return ""
	endif
	
	Wave /T ADC_MC = $wname
	
	return ADC_MC[ config ]
	
End // NMMultiClampADCStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampWaveNotes( wName, modeStr )
	String wName
	String modeStr
	
	Variable icnt, chanNum, output
	String varList, strVarList, varName
	
	Variable strLength  = NMMultiClampUseLongNames()
	
	if ( NMMultiClampTelegraphMode( modeStr ) == 0 )
		return -1
	endif
	
	chanNum = ClampTGainStrSearch( modeStr, "=C" )
	output = ClampTGainStrSearch( modeStr, "_O" )
	
	varList = NMMultiClampVarList( output )
	strVarList = NMMultiClampStrVarList( output )
	
	varList = RemoveFromList( strVarList, varList ) // remove redundant variables
	
	for ( icnt = 0 ; icnt < ItemsInList( varList ) ; icnt += 1 )
		varName = StringFromList( icnt, varList )
		Note $wName, "MultiClamp " + varName + ":" + num2str( NMMultiClampValue( chanNum, varName ) )
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( strVarList ) ; icnt += 1 )
		varName = StringFromList( icnt, strVarList )
		Note $wName, "MultiClamp " + varName + ":" + NMMultiClampStrValue( chanNum, varName, strLength )
	endfor
	
	return 0

End // NMMultiClampWaveNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTModeCheck( modeList )
	String modeList // list with two entries for channel 1 and 2
	
	Variable error
	String mode1, mode2, tmode1, tmode2
	
	if ( ItemsInList( modeList ) != 2 )
		DoAlert 0, "TmodeCheck Alert: MultiClamp700 configuration requires a telegraph mode entry for each channel."
		return -1
	endif
	
	if ( NMMultiClampCheck() != 0 )
		return -1
	endif
	
	mode1 = StringFromList( 0, modeList )
	mode2 = StringFromList( 1, modeList )
	
	tmode1 = NMMultiClampStrValue( 1, "OperatingMode", 1 )
	tmode2 = NMMultiClampStrValue( 2, "OperatingMode", 1 )
	
	if ( ( StringMatch( mode1, "Dont Care" ) == 0 ) && ( StringMatch( mode1, tmode1 ) == 0 ) )
		ClampError(1, "channel 1 acquisition mode should be " + mode1)
		error = -1
	endif
	
	if ( ( StringMatch( mode2, "Dont Care" ) == 0 ) && ( StringMatch( mode2, tmode2 ) == 0 ) )
		ClampError(1, "channel 2 acquisition mode should be " + mode2)
		error = -1
	endif
	
	return error
	
End // NMMultiClampTModeCheck

//****************************************************************
//****************************************************************
//****************************************************************