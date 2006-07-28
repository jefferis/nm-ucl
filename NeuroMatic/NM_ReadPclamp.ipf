#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Read PClamp Functions
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 16 Oct 2004
//
//	PClamp file header details from Axon Instruments, Inc.
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPClampHeader() // read pClamp file header

	Variable ccnt, amode, icnt, ActualEpisodes, tempvar
	Variable /G ADCResolution, ADCRange, DataPointer, AcqLength // create new globabl variables
	String yl
	
	NVAR FileFormat, NumChannels, TotalNumWaves, SamplesPerWave, SampleInterval
	SVAR CurrentFile, AcqMode, xLabel
	
	Wave FileScaleFactors
	Wave /T yLabel
	
	Make /O DumWave0 // where GBLoadWave puts data
	
	//
	// file ID and size info
	//
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={16,4} CurrentFile" // read short integers (16 bits)
	
	if (V_Flag != 0)
		DoAlert 0, " Load File Aborted: error in reading pClamp file."
		return 0
	endif
	
	FileFormat = DumWave0[18] // should be "1" for ABF filetype
	
	if (FileFormat != 1)
		DoAlert 0, "Abort: PClamp file format is not ABF (format = " + num2str(FileFormat) + ")"
		return 0
	endif
	
	NMProgressStr("Reading Pclamp Header...")
	CallProgress(-1)
	
	amode = DumWave0[4] // acquisition/operation mode
	
	switch(amode)
	case 1:
		AcqMode = "1 (Event-Driven)"
		break
	case 2:
		AcqMode = "2 (Oscilloscope, loss free)"
		break
	case 3:
		AcqMode = "3 (Gap-Free)"
		break
	case 4:
		AcqMode = "4 (Oscilloscope, high-speed)"
		break
	case 5:
		AcqMode = "5 (Episodic)"
		break
	endswitch
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={32,4}/S=10 CurrentFile" // read long integers (32 bits)
	AcqLength = DumWave0[0] // actual number of ADC samples in data file
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={32,4}/S=16 CurrentFile" // read long integers (32 bits)
	ActualEpisodes = DumWave0[0]
	
	//
	// File Structure info
	//
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={32,4}/S=40 CurrentFile" // read long integers (32 bits)
	DataPointer = DumWave0[0] // block number of start of Data section
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={16,4}/S=100 CurrentFile" // read long integers (32 bits)
	SetNMVar("DataFormat", DumWave0[0]) // data representation (0) 2-byte integer (1) IEEE 4-byte float
	
	if (CallProgress(-2) == 1)
		return 0 // cancel
	endif
		
	//
	// Trial Hierarchy info
	//
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={16,4}/S=120 CurrentFile" // read short integers (16 bits)
	NumChannels = DumWave0[0] // nADCNumChannels
	TotalNumWaves = ActualEpisodes*NumChannels
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={2,4}/S=122 CurrentFile" // single precision floating (32 bits)
	SampleInterval = (DumWave0[0]*NumChannels)/1000 // fADC sample interval (convert to milliseconds here)
	
	if (DumWave0[1] != 0) // SecondSampleInterval
		DoAlert 0, "Warning: data contains split-clock recording, which is not supported by this version of NeuroMatic."
	endif
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={32,4}/S=138 CurrentFile" // read long integers (32 bits)
	SamplesPerWave = DumWave0[0]/NumChannels // sample points per wave
	//Variable /G PreTriggerSamples = DumWave0[1]
	//Variable /G EpisodesPerRun = DumWave0[2]
	//Variable /G RunsPerTrial = DumWave0[3]
	//Variable /G NumberOfTrials = DumWave0[4]
	
	//Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={2,4}/S=178 CurrentFile" // single precision floating (32 bits)
	//Variable /G EpisodeStartToStart = DumWave0[0]
	//Variable /G RunStartToStart = DumWave0[1]
	//Variable /G TrialStartToStart = DumWave0[2]
	
	//Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={32,4}/S=194 CurrentFile" // read long integers (32 bits)
	//Variable /G ClockChange = DumWave0[0]
	
	//
	// Hardware Info
	//
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={2,4}/S=244 CurrentFile" // single precision floating (32 bits)
	ADCRange = DumWave0[0] // ADC positive full-scale input (volts)
	//Variable /G DACRange = DumWave0[1]
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={32,4}/S=252 CurrentFile" // read long integers (32 bits)
	ADCResolution =  DumWave0[0] // number of ADC counts in ADC range
	//Variable /G DACResolution = DumWave0[1]
	
	if (CallProgress(-2) == 1)
		return 0 // cancel
	endif
	
	//
	// Multi-channel Info
	//
	
	if (strlen(yLabel[ccnt]) == 0)
	
		Execute /Z "GBLoadWave /O/Q/N=DumWave/T={8,8}/S=442 CurrentFile" // read characters (1 byte)
	
		for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
			yl = ""
			for (icnt = 0; icnt < 10; icnt += 1)
				tempvar = DumWave0[icnt + ccnt*8]
				if (tempvar != 32)
					yl += num2char(tempvar)
				endif
			endfor
			yLabel[ccnt] = yl + " ("
		endfor
		
		Execute /Z "GBLoadWave /O/Q/N=DumWave/T={8,8}/S=602 CurrentFile" // read characters (1 byte)
		
		for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
			yl = ""
			for (icnt = 0; icnt < 8; icnt += 1)
				tempvar = DumWave0[icnt + ccnt*8]
				if (tempvar != 32)
					yl += num2char(tempvar)
				endif
			endfor
			yLabel[ccnt] += yl+ ")"
		endfor
	
	endif
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={2,4}/S=922 CurrentFile" // single precision floating (32 bits)
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		FileScaleFactors[ccnt] = ADCRange/(ADCResolution*DumWave0[ccnt])
		//print "chan" + num2str(ccnt) + " gain:", DumWave0[ccnt]
	endfor
	
	if (CallProgress(-2) == 1)
		return 0 // cancel
	endif
	
	//
	// Extended Environmental Info
	//
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={16,4}/S=4512 CurrentFile" // telegraph enable (short)
	Variable TelegraphEnable = DumWave0[0]
	//Print "Telegraph Enable:", TelegraphEnable
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={16,4}/S=4544 CurrentFile" // telegraph instrument (short)
	//Variable /G TelegraphInstrument = DumWave0[0]
	
	Execute /Z "GBLoadWave/O/B/Q/N=DumWave/T={2,4}/S=4576 CurrentFile" // single precision floating (32 bits)
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		if ((numtype(DumWave0[ccnt]) == 0) && (DumWave0[ccnt] > 0))
			FileScaleFactors[ccnt] /= DumWave0[ccnt]
			//print "chan" + num2str(ccnt) + " telegraph gain:", DumWave0[ccnt]
		endif
	endfor
	
	// finish up things here...
	
	if (amode == 3) // gap free
		TotalNumWaves = ceil(AcqLength/SamplesPerWave)
	endif
	
	if (strlen(xLabel) == 0)
		xLabel = "msec"
	endif
	
	KillWaves /Z DumWave0
	
	if (CallProgress(1) == 1)
		return 0 // cancel
	endif
	
	return 1

End // ReadPClampHeader

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPClampData() // read pClamp file

	Variable strtnum, numwaves, amode, scale
	Variable ccnt, wcnt, scnt, pcnt, pflag, smpcnt, npnts1, npnts2, lastwave
	String wName, wNote
	
	Variable /G column, NumSamps // these variables must be global for GBLoadWave to run properly
	
	NVAR NumChannels, SamplesPerWave, SampleInterval, AcqLength, DataPointer
	NVAR WaveBeg, WaveEnd, WaveInc, CurrentWave
	SVAR CurrentFile, AcqMode, xLabel
	
	Wave FileScaleFactors, MyScaleFactors
	Wave /T yLabel
	
	Variable DataFormat = NumVarOrDefault("DataFormat", 0)
	
	strtnum = CurrentWave
	
	if ((WaveBeg > WaveEnd) || (WaveInc < 0) || (strtnum < 0) || (numtype(WaveBeg*WaveEnd*WaveInc*strtnum) != 0))
		return 0 // options not allowed
	endif
	
	Make /O DumWave0, DumWave1 // where GBLoadWave puts data
	
	lastwave = floor(AcqLength/(NumChannels*SamplesPerWave))
	
	if (WaveEnd > lastwave)
		WaveEnd = lastwave
	endif
	
	numwaves = floor((WaveEnd - WaveBeg + 1)/ WaveInc)
	amode = str2num(AcqMode[0])
	
	NumSamps = SamplesPerWave*NumChannels
	
	if (amode == 3)
		for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
			Variable /G $("xbeg" + num2str(ccnt))
			Variable /G $("xend" + num2str(ccnt))
			Make /O/N=(AcqLength/NumChannels) $GetWaveName("default", ccnt, strtnum) = NAN
		endfor
	endif
	
	CallProgress(0) // bring up progress window
	
	for (wcnt = WaveBeg; wcnt <= WaveEnd; wcnt += WaveInc) // loop thru waves
	
		column = wcnt - 1 // compute column index to read

		if (DataFormat == 0) // 2 bytes integer
			Execute /Z "GBLoadWave/O/Q/B/N=DumWave/T={16,2}/S=(512*DataPointer+NumSamps*2*column)/W=1/U=(NumSamps) CurrentFile"
		elseif (DataFormat == 1) // 4 bytes float
			Execute /Z "GBLoadWave/O/Q/B/N=DumWave/T={2,2}/S=(512*DataPointer+NumSamps*4*column)/W=1/U=(NumSamps) CurrentFile"
		endif
			
		if (V_Flag != 0)
			DumWave0 = NAN
			DoAlert 0, "WARNING: Unsuccessfull read on Wave #" + num2str(wcnt)
		endif
		
		for (ccnt = 0; ccnt < NumChannels; ccnt += 1) // loop thru channels and extract channel waves
		
			Redimension /N=(NumSamps/NumChannels) DumWave1
			
			if (NumChannels == 1)
				Duplicate /O DumWave0 DumWave1
			else
				for (smpcnt = 0; smpcnt < SamplesPerWave; smpcnt += 1)
					DumWave1[smpcnt]=DumWave0[smpcnt*NumChannels+ccnt]
				endfor
			endif
			
			scale = FileScaleFactors[ccnt]*MyScaleFactors[ccnt]
			
			if (numtype(scale) == 0)
				DumWave1 *= scale
			endif
			
			if (amode == 3) // Gap-Free acquisition mode
			
				Wave DumWave = $GetWaveName("default", ccnt, strtnum)
				
				NVAR xbeg = $("xbeg" + num2str(ccnt))
				NVAR xend = $("xend" + num2str(ccnt))
			
				xend = xbeg + numpnts(DumWave1) - 1
				DumWave[xbeg,xend] = DumWave1[x-xbeg]
				xbeg = xend + 1

			else // all other acqusition modes
			
				wName = GetWaveName("default", ccnt, (scnt + strtnum))
				
				Duplicate /O DumWave1, $wName
				Setscale /P x 0, SampleInterval, $wName
				
				wNote = "Folder:" + GetDataFolder(0)
				wNote += "\rChan:" + ChanNum2Char(ccnt)
				wNote += "\rScale:" + num2str(scale)
				wNote += "\rFile:" + NMNoteCheck(CurrentFile)

				NMNoteType(wName, "Pclamp", xLabel, yLabel[ccnt], wNote)
				
			endif
			
		endfor
		
		scnt += 1
		pcnt += 1
		
		pflag = CallProgress(pcnt/numwaves)
		
		if (pflag == 1) // cancel
			break
		endif
			
	endfor
	
	CallProgress(1) // close progress window
	
	if (amode == 3) // Gap-Free acqusition mode
	
		scnt = 1 // loaded one wave
		
		for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		
			wName = GetWaveName("default", ccnt, strtnum)
			
			NVAR xend = $("xend" + num2str(ccnt))
			
			Redimension /N=(xend+1) $wName
			Setscale /P x 0, SampleInterval, $wName
			
			wNote = "Folder:" + GetDataFolder(0)
			wNote += "\rChan:" + ChanNum2Char(ccnt)
			wNote += "\rScale:" + num2str(scale)
			wNote += "\rFile:" + NMNoteCheck(CurrentFile)

			NMNoteType(wName, "Pclamp", xLabel, yLabel[ccnt], wNote)
			
		endfor
		
	endif
	
	KillVariables /Z NumSamps, column, DataPointer
	KillWaves /Z DumWave0, DumWave1
	
	return scnt // return count

End // ReadPClampData

//****************************************************************
//****************************************************************
//****************************************************************
