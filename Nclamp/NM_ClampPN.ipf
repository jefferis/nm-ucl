#pragma rtGlobals=1		// Use modern global access method.

#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp P / N Stimulus Subtraction
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
//	Began 5 May 2009
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPNenable( enable )
	Variable enable // ( 0 ) off ( 1 ) on
	
	Variable TURNTHISOFF = 1
	
	String sdf = StimDF( )
	
	Variable on = NumVarOrDefault( sdf + "PN", 0 )
	Variable subtract = 1 + NumVarOrDefault( sdf + "PNsubtract", 1 ) // ( 0 ) no ( 1 ) yes
	Variable displayN = 1 + NumVarOrDefault( sdf + "PNdisplay", 0 ) // ( 0 ) no ( 1 ) yes
	Variable saveflag = 1 + NumVarOrDefault( sdf + "PNsave", 1 ) // ( 0 ) kill the N waves ( 1 ) save the N waves ( 2 ) save sum of the N waves
	
	String ADClist = StimBoardConfigActiveNameList(sdf, "ADC")
	String DAClist = StimBoardConfigActiveNameList(sdf, "DAC")
	String adc = StrVarOrDefault( sdf + "PN_ADCname", "" )
	String dac = StrVarOrDefault( sdf + "PN_DACname", "" )
	
	if ( TURNTHISOFF == 1 )
		DoAlert 0, "Sorry, this function is not working yet."
		on = 0
		enable = 0
	endif
	
	if ( enable == 1 )
	
		if ( on == 0 )
			on = -4
		endif
	
		Prompt on, "N = "
		Prompt adc, "Select ADC input for subtraction:", popup ADClist
		Prompt dac, "Select appropriate DAC output for N scaling:", popup DAClist
		Prompt displayN, "Display extra N waves while recording?", popup "no;yes;"
		Prompt subtract, "Compute online subtraction?", popup "no;yes;"
		Prompt saveflag, "Save the extra N waves?", popup "no;yes;save their sum;"
		DoPrompt "Clamp P / N Subtraction", adc, dac, on, displayN, subtract, saveflag
		
		if (V_flag == 1) // cancel
			on = 0
		endif
		
		on = round( on )
		
	else
	
		on = 0
		
	endif
	
	displayN -= 1
	subtract -= 1
	saveflag -= 1
	
	SetNMvar( sdf + "PN", on )
	SetNMstr( sdf + "PN_ADCname",  adc)
	SetNMstr( sdf + "PN_DACname",  dac)
	SetNMvar( sdf + "PNdisplay", displayN )
	SetNMvar( sdf + "PNsubtract", subtract )
	SetNMvar( sdf + "PNsave", saveflag )
	
	if ( on == 0 )
		ClampPNcheckwaves( ) // delete existing waves
	endif
	
	StimTabMisc( 1 )
	
End // ClampPNenable

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPN( )

	return NumVarOrDefault( StimDF( ) + "PN", 0 )

End // ClampPN

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampPN_ADCname( )

	return StrVarOrDefault( StimDF( ) + "PN_ADCname", "" )

End // ClampPN_ADCname

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampPN_DACname( )

	return StrVarOrDefault( StimDF( ) + "PN_DACname", "" )

End // ClampPN_DACname

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPNdisplay( )

	return NumVarOrDefault( StimDF( ) + "PNdisplay", 0 )

End // ClampPNdisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPNsubtract( )

	return NumVarOrDefault( StimDF( ) + "PNsubtract", 1 )

End // ClampPNsubtract

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPNsave( )

	return NumVarOrDefault( StimDF( ) + "PNsave", 1 )

End // ClampPNsave

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPN_ADCconfig( )
	
	String sdf = StimDF( )
	String cname = StrVarOrDefault( sdf + "PN_ADCname", "" )
	
	return StimBoardConfigNum( sdf, "ADC", cname )

End // ClampPN_DACwavename

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPN_DACconfig( )
	
	String sdf = StimDF( )
	String cname = StrVarOrDefault( sdf + "PN_DACname", "" )
	
	return StimBoardConfigNum( sdf, "DAC", cname )

End // ClampPN_DACwavename

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPNcheckwaves( )
	
	Variable config, wcnt
	String prefix, wname, wname2, wlist, sdf = StimDF( )
	
	Variable pn = NumVarOrDefault( sdf + "PN", 0 )

	String DACname = StrVarOrDefault( sdf + "PN_DACname", "" )
	
	wlist = WaveListFolder( sdf, "pnDAC*", ";", "" )
	
	for ( wcnt = 0 ; wcnt < ItemsInlist( wlist ) ; wcnt += 1 )
		wname = StringFromList( wcnt, wlist )
		KillWaves /Z $( sdf + wname )
	endfor
	
	if ( ( pn == 0 ) || ( strlen( DACname ) == 0 ) )
		return  0 // nothing to do
	endif
	
	config = StimBoardConfigNum( sdf, "DAC", DACname)
	
	if ( config < 0 )
		DoAlert 0, "P / N Error: cannot locate DAC output : " + DACname
		return -1
	endif
	
	prefix = "DAC_" + num2str( config )
	
	wlist = StimWaveList( sdf, prefix, -1 )
	
	if ( ItemsInList( wlist ) <= 0 )
		return 0 // nothing to do
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wlist ) ; wcnt += 1 )
	
		wname = StringFromList( wcnt, wlist )
		
		if ( WaveExists( $sdf+wname ) == 0 )
			continue
		endif
		
		wname2 = "pn" + wname
		
		Duplicate /O $(sdf+wname) $(sdf+wname2)
		
		Wave wtemp = $sdf+wname2
		
		wtemp /= pn
		
	endfor


End // ClampPNcheckwaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPNinit( )

	if ( ( ClampPN( ) == 0 ) || ( ClampPNsubtract( ) == 0 ) )
		return 0 // nothing to do
	endif
	
	SetNMvar( "PNcounter", 0 )
	SetNMvar( "PNsumcounter", 0 )
	
End // ClampPNinit

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPNfinish()

	if ( ( ClampPN( ) == 0 ) || ( ClampPNsubtract( ) == 0 ) )
		return 0 // nothing to do
	endif
	
	NMPrefixSelectSilent(  "PN" + StrVarOrDefault( "WavePrefix", "Record" )  )

End // ClampPNfinish

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampPNsubtraction( wname, chan, currentwave )
	String wname
	Variable chan
	Variable currentwave
	
	String cdf = ClampDF( ), sdf = StimDF( )
	String prefix = StrVarOrDefault( "WavePrefix", "Record" )
	
	Variable pn = ClampPN( )
	Variable config = ClampPN_ADCconfig( )
	Variable subtract = ClampPNsubtract( )
	Variable displayN = ClampPNdisplay( )
	
	Variable counter = NumVarOrDefault( "PNcounter", 0 )
	Variable sumcounter = NumVarOrDefault( "PNsumcounter", 0 )
	Variable scount = mod( currentwave + 1, abs( pn ) + 1 )
	
	Variable mode = NumVarOrDefault( cdf + "PRTmode", 0 )
	Variable saveflag = NumVarOrDefault( sdf + "PNsave", 1 ) // ( 0 ) kill the N waves ( 1 ) save the N waves ( 2 ) save sum of the N waves
	
	String sname = GetWaveName( "PN"+prefix, chan, sumcounter )
	String pnname = GetWaveName( "PNSum", chan, sumcounter )
	String rname = wname
	
	if ( pn == 0 )
		return wname
	endif
	
	if ( chan != config )
		
		if ( ( displayN == 1 ) || ( scount == 0 ) )
			Duplicate /O $wname $sname
			return sname
		endif
		
		return "Skip"
		
	endif
	
	if ( WaveExists( $wname ) == 0 )
		return wname
	endif
	
	if ( counter == 0 )
	
		Duplicate /O $wname $pnname
		counter += 1
		
		if ( displayN == 0 )
			rname = "Skip"
		endif
	
	elseif ( counter == abs( pn ) ) // compute subtraction
	
		Duplicate /O $wname $sname
		
		Wave wtemp = $sname
		Wave ptemp = $pnname
		
		wtemp += ptemp
		counter = 0
		
		if ( mode == 1 ) // Recording
			sumcounter += 1
		endif
		
		rname = sname
		
	else
	
		Wave wtemp = $wname
		Wave ptemp = $pnname
		
		ptemp += wtemp
		counter += 1
		
		if ( displayN == 0 )
			rname = "Skip"
		endif
		
	endif
	
	SetNMvar( "PNcounter", counter )
	SetNMvar( "PNsumcounter", sumcounter )
	
	return rname

End // ClampPNsubtraction

//****************************************************************
//****************************************************************
//****************************************************************
