#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Demo - Loop Through Waves
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDemoLoop() // example function that loops thru all currently selected channels and waves
	
	Variable wcnt, ccnt, cancel
	String wname, cList = "", wList = ""
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	SetNeuroMaticStr( "ProgressStr", "My Demo Function..." ) // set progress title
	
	for ( ccnt = 0 ;  ccnt < numChannels ;  ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		for ( wcnt = 0 ;  wcnt < numWaves ;  wcnt += 1 ) // loop thru waves
		
			if ( CallNMProgress( wcnt, numWaves ) == 1 ) // progress display
				cancel = 1
				break // cancel wave loop
			endif
		
			wname = NMWaveSelected( ccnt, wcnt )
			
			if ( strlen( wname ) == 0 )
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			Wave tempWave = $wname // create local reference to wave
			
			//PutYourCodeStartingHere...PutYourCodeStartingHere
			//PutYourCodeStartingHere...PutYourCodeStartingHere
			//PutYourCodeStartingHere...PutYourCodeStartingHere
			
			//tempWave *= 1 // do something to the wave
			
			Print "Demo Loop wave: " + wname // as demo, we just print the wave name here
			
			//PutYourCodeEndingHere...PutYourCodeEndingHere
			//PutYourCodeEndingHere...PutYourCodeEndingHere
			//PutYourCodeEndingHere...PutYourCodeEndingHere
			
			cList = AddListItem( wname, cList, ";", inf )
			
		endfor
		
		NMMainHistory( "Demo Loop", ccnt, cList, 0 ) // print results to history for this channel
		
		wList += cList
		
		if ( cancel == 1 )
			break // cancel channel loop
		endif
		
	endfor
	
	return wList // return list of waves that successfully made it thru the loop

End // NMDemoLoop

//****************************************************************
//****************************************************************
//****************************************************************