#pragma rtGlobals = 1
#pragma IgorVersion = 4
#pragma version = 1.86

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Read Axograph Functions
//	To be run with NeuroMatic, v1.86
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro 4
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 16 Oct 2004
//
//****************************************************************
//****************************************************************
//****************************************************************
//
//	Axograph file header details
//	From 'Axograph 4.6 User Manual" by John Clements.
//	Axon Instruments, Inc.
//
//	Main Header (8 Bytes)
//	Byte	Type		Details
//	0		OSType		header = 'AxGr' (4 Byte char)
//	4		Int			file format = 2
//	6		Int			number of data columns, including x-column
//
//	X-Column Header, or time (92 Bytes)
//	0		LongInt		column points
//	4		String[79]	column title
//	84		Real*4		sample interval
//
//	Subsequent Y-Columns (88 + 2*ColumnPoints Bytes)
//	0		LongInt		column points
//	4		String[79]	column title
//	84		Real*4		scale factor
//	88		Int*2		1st data point
//	90		Int*2		2nd data point, etc...
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ReadAxoHeader()  // read Axograph file header, set global variables

	String dumstr
	Variable ccnt
	Variable /G column // needs to be global for GBLoadWave to work
	
	NVAR FileFormat, NumChannels, TotalNumWaves, SamplesPerWave, SampleInterval
	SVAR CurrentFile, AcqMode, xLabel
	Wave FileScaleFactors
	Wave /T yLabel
	
	Make /O DumWave0 // where GBLoadWave puts data
	
	//
	// read main file header
	//
	
	Execute /Z "GBLoadWave /N=DumWave/T={8,8}/S=0/Q CurrentFile"
	
	if (V_Flag != 0)
		DoAlert 0, " Load File Aborted: error in reading Axograph file."
		return 0
	endif
	
	dumstr = num2char(DumWave0[0]) + num2char(DumWave0[1]) + num2char(DumWave0[2]) + num2char(DumWave0[3])
	
	if (StringMatch(dumstr, "AxGr") == 0)
		DoAlert 0, "Load File Aborted: file not of Axograph format."
		return 0
	endif
	
	Execute /Z "GBLoadWave /N=DumWave/T={16,16}/S=4/Q CurrentFile"
								
	FileFormat=DumWave0[0]	// this should be 2, for acquired data
	
	if (FileFormat != 2)
		DoAlert 0, "Load File Aborted:  Axograph file format version " + num2str(FileFormat) + " is not supported."
		return 0
	endif
	
	NMProgressStr("Reading Axograph Header...")
	CallProgress(-1)
	
	TotalNumWaves=DumWave0[1]-1 // minus the x-column
	
	//
	// read x-column header (time)
	//
	
	Execute /Z "GBLoadWave /N=DumWave/T={32,32}/S=8/Q CurrentFile"
	
	SamplesPerWave = DumWave0[0]
	
	Execute /Z "GBLoadWave/N=DumWave/T={8,8}/S=(8+4)/Q CurrentFile"
	
	if (strlen(xLabel) == 0)
		xLabel = GetAxoLabel(DumWave0)
	endif
	
	Execute /Z "GBLoadWave/N=DumWave/T={2,2}/S=(8+84)/Q CurrentFile"
	
	SampleInterval = DumWave0[0]*1000 // (msec)
	
	//
	// read y-column headers (the data), determine the number of channels
	//
	
	for (ccnt = 0; ccnt < TotalNumWaves; ccnt += 1)
	
		if (CallProgress(-2) == 1)
			return 0 // cancel
		endif
	
		column = ccnt
		
		Execute /Z "GBLoadWave/N=DumWave/T={8,8}/S=(8+92+4+(88*column)+(SamplesPerWave*2*column))/Q CurrentFile"
		
		dumstr = GetAxoLabel(DumWave0)
		
		if (StringMatch(dumstr[0,5], "Column") == 1)
			break // no more new channel titles
		endif
		
		if (strlen(yLabel[ccnt]) == 0)
			yLabel[ccnt] = dumstr
		endif
		
		Execute /Z "GBLoadWave/N=DumWave/T={2,2}/S=(8+92+84+(88*column)+(SamplesPerWave*2*column))/Q CurrentFile"
		
		FileScaleFactors[ccnt] = DumWave0[0]
		
	endfor
	
	NumChannels = ccnt
	
	AcqMode = "5 (Episodic)"
	
	KillVariables /Z column
	KillWaves /Z DumWave0
	
	if (CallProgress(1) == 1)
		return 0
	endif
	
	return 1

End // ReadAxoHeader

//****************************************************************
//****************************************************************
//****************************************************************

function /S GetAxoLabel(labelWave) // compute channel label, which always ends with "(units)"
	Wave labelWave // channel label, read from Axograph header
	
	String chr, finalLabel = ""
	Variable foundOpen, foundClose, icount
	
	for (icount = 1; icount <= 80; icount += 1) // first (zero) position appears to be garbage
		chr = num2char(labelWave[icount])
		finalLabel += chr
		if (StringMatch(chr, "(") == 1)
			foundopen = 1
		endif
		if (StringMatch(chr, ")") == 1)
			foundclose = 1
		endif
		if ((foundopen == 1) &&(foundclose == 1))
			break
		endif
	endfor
	
	return finalLabel

End // GetAxoLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadAxoData() // read Axograph y-data columns

	Variable strtnum, numwaves, ccnt, wcnt, scnt, pcnt, pflag, scale
	Variable /G column // must be global for GBLoadWave to work properly
	String wName, wNote
	
	NVAR NumChannels, SamplesPerWave, SampleInterval
	NVAR WaveBeg, WaveEnd, WaveInc, CurrentWave
	SVAR CurrentFile, xLabel
	
	Wave FileScaleFactors, MyScaleFactors
	Wave /T yLabel
	
	strtnum = CurrentWave
	
	if ((WaveBeg > WaveEnd) || (WaveInc < 1) || (strtnum < 0) || (numtype(WaveBeg*WaveEnd*WaveInc*strtnum) != 0))
		return 0 // options not allowed
	endif
	
	Make /O DumWave0 // where GBLoadWave puts data
	
	CallProgress(0) // bring up progress window
	
	numwaves = floor((WaveEnd - WaveBeg + 1) / WaveInc)
	
	for (wcnt = WaveBeg; wcnt <= WaveEnd; wcnt += WaveInc) // loop thru waves
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1) // loop thru channels
	
		column = (wcnt-1)*NumChannels + ccnt // compute column index to read
		
		wName = GetWaveName("default", ccnt, (scnt + strtnum)) // compute wave name
		
		Execute /Z "GBLoadWave /O/Q/N=DumWave/T={16,2}/S=(8+92+88 +(88*column)+(SamplesPerWave*2*column))/W=1/U=(SamplesPerWave) CurrentFile"
		
		if (V_Flag != 0)
			DumWave0 = NAN
			DoAlert 0, "WARNING: Unsuccessfull read on data column: " + wName
		endif
	
		scale = FileScaleFactors[ccnt] * MyScaleFactors[ccnt]
		DumWave0 *= scale
		
		Duplicate /O  DumWave0,  $wName
		Setscale /P x 0, SampleInterval, $wName
		
		wNote = "Folder:" + GetDataFolder(0)
		wNote += "\rChan:" + ChanNum2Char(ccnt)
		wNote += "\rScale:" + num2str(scale)
		wNote += "\rFile:" + NMNoteCheck(CurrentFile)

		NMNoteType(wName, "Axograph", xLabel, yLabel[ccnt], wNote)
		
		pcnt += 1
		pflag = CallProgress(pcnt/(numwaves*NumChannels))
		
		if (pflag == 1) // cancel
			break
		endif
		
	endfor
	
	scnt += 1
	
	if (pflag == 1)
		scnt = -1
		break
	endif
	
	endfor
	
	CallProgress(1) // close progress window
	
	KillVariables /Z column
	KillWaves /Z DumWave0
	
	return scnt

End // ReadAxoData

//****************************************************************
//****************************************************************
//****************************************************************