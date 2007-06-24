#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Demo Loop 
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 16 May 2007
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDemoLoop() // example function that loops thru all currently selected channels and waves
	
	Variable wcnt, ccnt, cancel
	String wName, cList = "", wList = ""
	
	Variable nwaves = NMNumWaves()
	
	NMProgressStr("My Demo Function...") // set progress title
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt += 1) // loop thru channels
	
		if (NMChanSelected(ccnt) != 1)
			continue // channel not selected
		endif
		
		for (wcnt = 0; wcnt < nwaves; wcnt += 1) // loop thru waves
		
			if (CallNMProgress(wcnt, nwaves) == 1) // progress display
				cancel = 1
				break // cancel wave loop
			endif
		
			wName = NMWaveSelected(ccnt, wcnt)
			
			if ((strlen(wName) == 0) || (WaveExists($wName) == 0))
				continue // wave not selected, or does not exist... go to next wave
			endif
			
			Wave tempWave = $wName // create local reference to wave
			
			//PutYourCodeStartingHere...PutYourCodeStartingHere
			//PutYourCodeStartingHere...PutYourCodeStartingHere
			//PutYourCodeStartingHere...PutYourCodeStartingHere
			
			//tempWave *= 1 // do something to the wave
			
			Print "Demo Loop wave: " + wName // as demo, we just print the wave name here
			
			//PutYourCodeEndingHere...PutYourCodeEndingHere
			//PutYourCodeEndingHere...PutYourCodeEndingHere
			//PutYourCodeEndingHere...PutYourCodeEndingHere
			
			cList = AddListItem(wName, cList, ";", inf)
			
		endfor
		
		NMMainHistory("Demo Loop", ccnt, cList, 0) // print results to history for this channel
		
		wList += cList
		
		if (cancel == 1)
			break // cancel channel loop
		endif
		
	endfor
	
	return wList // return list of waves that successfully made it thru the loop

End // NMDemoLoop

//****************************************************************
//****************************************************************
//****************************************************************