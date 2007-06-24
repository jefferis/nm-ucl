#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Read PClamp Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 11 June 2007
//
//	PClamp file header details from Axon Instruments, Inc.
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPclampXOPExists(file)
	String file

	Execute /Z "ReadPclamp \"" + ReadPClampFileC(file) + "\"" // check for ABF XOP
	
	if (NumVarOrDefault("ABF_Version", 0) > 0)
		return 1
	endif
	
	return 0

End // ReadPclampXOPExists

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPClampHeader(file, df) // read pClamp file header
	String file // file to read
	String df // data folder where everything is saved

	Variable ccnt, amode, ActualEpisodes, tempvar, XOPexists, importDebug = 0
	Variable ADCResolution, ADCRange, DataPointer, DataFormat, AcqLength
	Variable FileFormat, NumChannels, TotalNumWaves, SamplesPerWave, SampleInterval, SplitClock
	String yl, dumstr, AcqMode, fileC
	
	XOPexists = ReadPclampXOPExists(file)
	
	//
	// file ID and size info
	//
	
	dumstr = ReadPclampString(file, 0, 4) // file signature
	
	if (ImportDebug == 1)
		Print "Pclamp Header Format String:", dumstr
	endif
	
	strswitch(dumstr)
		case "ABF ":
			if (XOPexists == 1)
				return ReadPClampHeaderXOP(file, df)
			endif
			break
		case "ABF2":
			if (XOPexists == 1)
				return ReadPClampHeaderXOP(file, df)
			else
				DoAlert 0, "Encounted ABF file format 2: Please contact Jason@ThinkRandom.com for the new ReadPclamp XOP. "
				return -1
			endif
		default:
			Print "Import File Aborted: file not of Pclamp format: " + dumstr
			return -1
	endswitch
	
	CheckNMwave(df+"FileScaleFactors", 16, 1)  // increase size
	CheckNMtwave(df+"yLabel", 16, "")
	
	Wave FileScaleFactors = $(df+"FileScaleFactors")
	Wave /T yLabel = $(df+"yLabel")
	
	FileScaleFactors = 1
	yLabel = ""
	
	FileFormat = ReadPclampVar(file, "short", 36)
	//SetNMvar(df+"FileFormat", FileFormat)
	
	if (ImportDebug == 1)
		Print "File format number:", FileFormat 
	endif
	
	amode = ReadPclampVar(file, "short", 8) // acquisition/operation mode
	
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
	
	SetNMstr(df+"AcqMode", AcqMode)
	
	AcqLength = ReadPclampVar(file, "long", 10) // actual number of ADC samples in data file
	SetNMvar(df+"AcqLength", AcqLength)
	ActualEpisodes = ReadPclampVar(file, "long", 16)
	SetNMvar(df+"NumWaves", ActualEpisodes)
	
	//
	// File Structure info
	//
	
	DataPointer = ReadPclampVar(file, "long", 40) // block number of start of Data section
	SetNMvar(df+"DataPointer", DataPointer)
	DataFormat = ReadPclampVar(file, "long", 100)
	SetNMvar(df+"DataFormat", DataFormat)
		
	//
	// Trial Hierarchy info
	//
	
	NumChannels = ReadPclampVar(file, "short", 120) // nADCNumChannels
	SetNMvar(df+"NumChannels", NumChannels)
	TotalNumWaves = ActualEpisodes * NumChannels
	SetNMvar(df+"TotalNumWaves", TotalNumWaves)
	SampleInterval = ReadPclampVar(file, "float", 122)
	SampleInterval = (SampleInterval * NumChannels) / 1000
	SetNMvar(df+"SampleInterval", SampleInterval)
	
	SplitClock = ReadPclampVar(file, "float", 126) // second clock interval
	
	SetNMvar(df+"SplitClock", SplitClock)
	
	if (SplitClock != 0) // SecondSampleInterval
		DoAlert 0, "Warning: data contains split-clock recording, which is not supported by this version of NeuroMatic."
	endif
	
	SamplesPerWave = ReadPclampVar(file, "long", 138) / NumChannels // sample points per wave
	SetNMvar(df+"SamplesPerWave", SamplesPerWave)
	//Variable /G PreTriggerSamples = ReadPclampVar(file, "long", 142)
	//Variable /G EpisodesPerRun = ReadPclampVar(file, "long", 146)
	//Variable /G RunsPerTrial = ReadPclampVar(file, "long", 150)
	//Variable /G NumberOfTrials = ReadPclampVar(file, "long", 154)
	//Variable /G EpisodeStartToStart = ReadPclampVar(file, "float", 178)
	//Variable /G RunStartToStart = ReadPclampVar(file, "float", 182)
	//Variable /G TrialStartToStart = ReadPclampVar(file, "float", 186)
	//Variable /G ClockChange = ReadPclampVar(file, "long", 194)
	
	//
	// Hardware Info
	//
	
	ADCRange = ReadPclampVar(file, "float", 244) // ADC positive full-scale input (volts)
	SetNMvar(df+"ADCRange", ADCRange)
	//Variable /G DACRange = ReadPclampVar(file, "float", 248)
	ADCResolution = ReadPclampVar(file, "long", 252) // number of ADC counts in ADC range
	SetNMvar(df+"ADCResolution", ADCResolution)
	//Variable /G DACResolution = ReadPclampVar(file, "long", 256)
	
	//
	// Multi-channel Info
	//

	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		yl = ReadPclampString(file, 442 + ccnt * 10, 10)
		yLabel[ccnt] = RemoveEndSpaces(yl)
	endfor
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		yl = ReadPclampString(file, 602 + ccnt * 8, 8)
		yLabel[ccnt] += " (" + RemoveEndSpaces(yl) + ")"
	endfor
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		tempvar = ReadPclampVar(file, "float", 922 + ccnt * 4)
		FileScaleFactors[ccnt] = ADCRange / (ADCResolution * tempvar)
		//print "chan" + num2str(ccnt) + " gain:", tempvar
	endfor
	
	//
	// Extended Environmental Info
	//
	
	//Variable /G TelegraphEnable = ReadPclampVar(file, "short", 4512)
	//Variable /G TelegraphInstrument = = ReadPclampVar(file, "short", 4544)
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		tempvar = ReadPclampVar(file, "float", 4576 + ccnt * 4)
		if ((numtype(tempvar) == 0) && (tempvar > 0))
			FileScaleFactors[ccnt] /= tempvar
			//print "chan" + num2str(ccnt) + " telegraph gain:", DumWave0[ccnt]
		endif
	endfor
	
	if (amode == 3) // gap free
		TotalNumWaves = ceil(AcqLength / SamplesPerWave)
	endif
	
	//if (strlen(xLabel) == 0)
	//	xLabel = "msec"
	//endif
	
	KillWaves /Z DumWave0
	
	SetNMstr(df+"ImportFileType", "Pclamp " + num2str(FileFormat))
	
	CheckNMwave(df+"FileScaleFactors", numChannels, 1)
	CheckNMtwave(df+"yLabel", numChannels, "")
	
	return 1

End // ReadPClampHeader

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ReadPClampFileC(file) // convert Igor file string to C/C++ file string
	String file
	String fileC

	fileC = ReplaceString(":", file, "/")
	fileC = file[0,0] + ":/" + fileC[2,inf]
	
	return fileC
	
End // ReadPClampFileC

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPClampHeaderXOP(file, df)
	String file, df
	
	Variable ccnt, chan, tempvar
	Variable amode, FileFormat, AcqLength, ActualEpisodes, DataFormat, TotalNumWaves
	Variable SampleInterval, NumChannels, SplitClock, SamplesPerWave
	Variable ADCRange, ADCResolution
	
	String acqMode, yl, yu
	String folder = GetPathName(file, 0) + "_Header"
	String saveDF = GetDataFolder(1)
	
	folder = ReplaceString(".abf", folder, "")
	
	folder = CheckFolderNameChar(folder)
	
	NewDataFolder /O /S $LastPathColon(folder, 0) // create subfolder in current directory
	
	Execute /Z "ReadPclamp /H \"" + ReadPClampFileC(file) + "\"" // import header
	
	if (WaveExists(ABF_nADCSamplingSeq) == 0) // something went wrong
		SetDataFolder $saveDF // back to original folder
		return -1
	endif
	
	CheckNMwave(df+"FileScaleFactors", 20, 1)  // increase size
	CheckNMtwave(df+"yLabel", 20, "")
	
	Wave FileScaleFactors = $(df+"FileScaleFactors")
	Wave /T yLabel = $(df+"yLabel")
	
	FileScaleFactors = 1
	yLabel = ""
	
	FileFormat = NumVarOrDefault("ABF_nFileType", -1)
	
	amode = NumVarOrDefault("ABF_nOperationMode", -1)
	
	switch(amode)
	case 1:
		acqMode = "1 (Event-Driven)"
		break
	case 2:
		acqMode = "2 (Oscilloscope, loss free)"
		break
	case 3:
		acqMode = "3 (Gap-Free)"
		break
	case 4:
		acqMode = "4 (Oscilloscope, high-speed)"
		break
	case 5:
		acqMode = "5 (Episodic)"
		break
	default:
		acqMode = "-1 (UNKNOWN)"
	endswitch
	
	SetNMstr(df+"AcqMode", acqMode)
	
	AcqLength = NumVarOrDefault("ABF_lActualAcqLength", -1)
	SetNMvar(df+"AcqLength", AcqLength)
	ActualEpisodes = NumVarOrDefault("ABF_lActualEpisodes", -1)
	SetNMvar(df+"NumWaves", ActualEpisodes)
	
	//
	// File Structure info
	//
	
	DataFormat = NumVarOrDefault("ABF_nDataFormat", -1)
	SetNMvar(df+"DataFormat", DataFormat)
		
	//
	// Trial Hierarchy info
	//
	
	NumChannels = NumVarOrDefault("ABF_nADCNumChannels", -1)
	SetNMvar(df+"NumChannels", NumChannels)
	TotalNumWaves = ActualEpisodes * NumChannels
	SetNMvar(df+"TotalNumWaves", TotalNumWaves)
	SampleInterval = NumVarOrDefault("ABF_fADCSampleInterval", -1)
	
	if (SampleInterval <= 0)
		SampleInterval = NumVarOrDefault("ABF_fADCSequenceInterval", -1)
	endif
	
	SampleInterval = (SampleInterval * NumChannels) / 1000
	SetNMvar(df+"SampleInterval", SampleInterval)
	
	SplitClock = NumVarOrDefault("ABF_fADCSecondSampleInterval", -1)
	SetNMvar(df+"SplitClock", SplitClock)
	
	if (SplitClock > 0) // SecondSampleInterval
		DoAlert 0, "Warning: data contains split-clock recording, which is not supported by this version of NeuroMatic."
	endif
	
	SamplesPerWave = NumVarOrDefault("ABF_lNumSamplesPerEpisode", -1) / NumChannels // sample points per wave
	SetNMvar(df+"SamplesPerWave", SamplesPerWave)
	
	//
	// Hardware Info
	//
	
	ADCRange = NumVarOrDefault("ABF_fADCRange", -1) // ADC positive full-scale input (volts)
	SetNMvar(df+"ADCRange", ADCRange)
	ADCResolution = NumVarOrDefault("ABF_lADCResolution", -1) // number of ADC counts in ADC range
	SetNMvar(df+"ADCResolution", ADCResolution)
	
	//
	// Multi-channel Info
	//
	
	Wave ABF_nADCSamplingSeq, ABF_fInstrumentScaleFactor
	Wave /T ABF_sADCChannelName, ABF_sADCUnits

	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		
		chan = ABF_nADCSamplingSeq[ccnt]
		
		if ((chan >= 0) && (chan < numpnts(ABF_sADCChannelName)))
			yl = RemoveEndSpaces(ABF_sADCChannelName[chan])
			yu = RemoveEndSpaces(ABF_sADCUnits[chan])
			yLabel[ccnt] =  yl + " (" + yu + ")"
		endif
		
	endfor
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
	
		chan = ABF_nADCSamplingSeq[ccnt]
		
		if ((chan >= 0) && (chan < numpnts(ABF_fInstrumentScaleFactor)))
			tempvar = ABF_fInstrumentScaleFactor[chan]
		else
			tempvar = Nan
		endif
		
		if ((numtype(tempvar) == 0) && (tempvar > 0))
			FileScaleFactors[ccnt] = ADCRange / (ADCResolution * tempvar)
		else
			FileScaleFactors[ccnt] = ADCRange / ADCResolution
		endif
		
	endfor
	
	//
	// Extended Environmental Info
	//
	
	if (WaveExists(ABF_fTelegraphAdditGain) == 1)
	
		Wave ABF_fTelegraphAdditGain
	
		for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		
			chan = ABF_nADCSamplingSeq[ccnt]
		
			if ((chan >= 0) && (chan < numpnts(ABF_fTelegraphAdditGain)))
				tempvar = ABF_fTelegraphAdditGain[chan]
			else
				tempvar = NAN
			endif
			
			if ((numtype(tempvar) == 0) && (tempvar > 0))
				FileScaleFactors[ccnt] /= tempvar
				//print "chan" + num2str(ccnt) + " telegraph gain:", DumWave0[ccnt]
			endif
			
		endfor
	
	endif
	
	SetDataFolder $saveDF // back to original folder
	
	KillWaves /Z DumWave0
	
	SetNMstr(df+"ImportFileType", "Pclamp " + num2str(FileFormat))
	
	CheckNMwave(df+"FileScaleFactors", numChannels, 1)
	CheckNMtwave(df+"yLabel", numChannels, "")
	
	return 1

End // ReadPClampHeaderXOP

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPClampDataXOP(file, df) // read pClamp file (need to read header before calling this function)
	String file // file to read
	String df // data folder where everything is saved
	
	Variable wcnt, ccnt, scnt, scale
	String wName, wNote
	
	Variable version = NumVarOrDefault(df+"ABF_Version", 0)
	
	if (version == 0)
		return 0
	endif
	
	Variable NumWaves = NumVarOrDefault(df+"NumWaves", 0)
	Variable WaveBgn = NumVarOrDefault(df+"WaveBgn", 0)
	Variable WaveEnd = NumVarOrDefault(df+"WaveEnd", -1)
	
	String wavePrefix = StrVarOrDefault(df+"WavePrefix", "Record")
	
	String saveDF = GetDataFolder(1)
	
	SetDataFolder $df
	
	Variable strtnum = NextWaveNum("", wavePrefix, 0, 0)
	
	WaveBgn += 1
	WaveEnd += 1
	
	if ((WaveBgn > WaveEnd) || (strtnum < 0) || (numtype(WaveBgn*WaveEnd*strtnum) != 0))
		return 0 // options not allowed
	endif
	
	NMProgressStr("Reading Pclamp File...")
	CallProgress(-1) // bring up progress window
	
	Execute /Z "ReadPclamp /D /N=(" + num2str(WaveBgn) + "," + num2str(WaveEnd) + ") /P=\"" + wavePrefix + "\" /S=" + num2str(strtnum) + " \"" + ReadPClampFileC(file) + "\""
	
	SetDataFolder $saveDF // back to original folder
	
	CallProgress(1) // bring up progress window
	
End // ReadPClampDataXOP

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPClampData(file, df) // read pClamp file
	String file // file to read
	String df // data folder where everything is saved

	Variable strtnum, nwaves, amode, scale, pointer, column, nsamples
	Variable ccnt, wcnt, scnt, pcnt, pflag, smpcnt, npnts1, npnts2, lastwave
	String wname, wNote
	
	String saveDF = GetDataFolder(1)
	
	Variable XOPexists = ReadPclampXOPExists(file)
	
	ReadPClampHeader(file, df)
	
	if (XOPexists == 1)
		return ReadPClampDataXOP(file, df)
	endif
	
	Variable NumChannels = NumVarOrDefault(df+"NumChannels", 0)
	Variable NumWaves = NumVarOrDefault(df+"NumWaves", 0)
	Variable SamplesPerWave = NumVarOrDefault(df+"SamplesPerWave", 0)
	Variable SampleInterval = NumVarOrDefault(df+"SampleInterval", 1)
	Variable AcqLength = NumVarOrDefault(df+"AcqLength", 0)
	Variable DataPointer = NumVarOrDefault(df+"DataPointer", 0)
	Variable WaveBgn = NumVarOrDefault(df+"WaveBgn", 0)
	Variable WaveEnd = NumVarOrDefault(df+"WaveEnd", -1)
	
	String AcqMode = StrVarOrDefault(df+"AcqMode", "")
	String xLabel = StrVarOrDefault(df+"xLabel", "")
	String wavePrefix = StrVarOrDefault(df+"WavePrefix", "Record")
	
	Wave FileScaleFactors = $(df+"FileScaleFactors")
	Wave /T yLabel  = $(df+"yLabel")
	
	Variable DataFormat = NumVarOrDefault(df+"DataFormat", 0)
	
	SetDataFolder $df
	
	strtnum = NextWaveNum("", wavePrefix, 0, 0)
	
	if (WaveEnd < 0)
		WaveEnd = NumWaves
	endif
	
	if ((WaveBgn > WaveEnd) || (strtnum < 0) || (numtype(WaveBgn*WaveEnd*strtnum) != 0))
		return 0 // options not allowed
	endif
	
	Make /O DumWave0, DumWave1 // where GBLoadWave puts data
	
	lastwave = floor(AcqLength/(NumChannels*SamplesPerWave))
	
	if (WaveEnd > lastwave)
		WaveEnd = lastwave
	endif
	
	nwaves = floor(WaveEnd - WaveBgn + 1)
	amode = str2num(AcqMode[0])
	
	nsamples = SamplesPerWave * NumChannels
	
	if (amode == 3)
		for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
			Variable /G $("xbeg" + num2str(ccnt))
			Variable /G $("xend" + num2str(ccnt)) 
			Make /O/N=(AcqLength/NumChannels) $GetWaveName(wavePrefix, ccnt, strtnum) = NAN
		endfor
	endif
	
	NMProgressStr("Reading Pclamp File...")
	CallProgress(0) // bring up progress window
	
	for (wcnt = WaveBgn; wcnt <= WaveEnd; wcnt += 1) // loop thru waves
	
		column = wcnt // compute column index to read

		if (DataFormat == 0) // 2 bytes integer
			pointer = 512 * DataPointer + nsamples * 2 * column
			GBLoadWave/O/Q/B/N=DumWave/T={16,2}/S=(pointer)/W=1/U=(nsamples) file
		elseif (DataFormat == 1) // 4 bytes float
			pointer = 512 * DataPointer + nsamples * 4 * column
			GBLoadWave/O/Q/B/N=DumWave/T={2,2}/S=(pointer)/W=1/U=(nsamples) file
		endif
			
		//if (V_Flag != 0)
		//	DumWave0 = NAN
		//	DoAlert 0, "WARNING: Unsuccessfull read on Wave #" + num2str(wcnt)
		//endif
		
		for (ccnt = 0; ccnt < NumChannels; ccnt += 1) // loop thru channels and extract channel waves
		
			Redimension /N=(nsamples/NumChannels) DumWave1
			
			if (NumChannels == 1)
				Duplicate /O DumWave0 DumWave1
			else
				for (smpcnt = 0; smpcnt < SamplesPerWave; smpcnt += 1)
					DumWave1[smpcnt]=DumWave0[smpcnt*NumChannels+ccnt]
				endfor
			endif
			
			scale = FileScaleFactors[ccnt]
			
			if (numtype(scale) == 0)
				DumWave1 *= scale
			endif
			
			if (amode == 3) // Gap-Free acquisition mode
			
				Wave DumWave = $GetWaveName(wavePrefix, ccnt, strtnum)
				
				NVAR xbeg = $("xbeg" + num2str(ccnt))
				NVAR xend = $("xend" + num2str(ccnt))
			
				xend = xbeg + numpnts(DumWave1) - 1
				DumWave[xbeg,xend] = DumWave1[x-xbeg]
				xbeg = xend + 1

			else // all other acqusition modes
			
				wName = GetWaveName(wavePrefix, ccnt, (scnt + strtnum))
				//wName = GetWaveName("default", ccnt, wcnt)
				
				Duplicate /O DumWave1, $wName
				Setscale /P x 0, SampleInterval, $wName
				
				wNote = "Folder:" + GetDataFolder(0)
				wNote += "\rFile:" + NMNoteCheck(file)
				wNote += "\rChan:" + ChanNum2Char(ccnt)
				wNote += "\rWave:" + num2str(wcnt)
				wNote += "\rScale:" + num2str(scale)

				NMNoteType(wName, "Pclamp", xLabel, yLabel[ccnt], wNote)
				
			endif
			
		endfor
		
		scnt += 1
		pcnt += 1
		
		pflag = CallProgress(pcnt/nwaves)
		
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
			wNote += "\rFile:" + NMNoteCheck(file)

			NMNoteType(wName, "Pclamp", xLabel, yLabel[ccnt], wNote)
			
		endfor
		
	endif
	
	KillWaves /Z DumWave0, DumWave1
	
	SetDataFolder $saveDF // back to original folder
	
	return scnt // return count

End // ReadPClampData

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPclampVar(file, type, pointer)
	String file
	String type
	Variable pointer
	
	pointer = ReadPclampFile(file, type, pointer, 1)
	
	if ((numtype(pointer) > 0) || (WaveExists(DumWave0) == 0))
		return Nan
	endif
	
	Wave DumWave0
	
	return DumWave0[0]

End // ReadPclampVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /T ReadPclampString(file, pointer, nchar)
	String file
	Variable pointer, nchar
	
	Variable icnt
	String str = ""
	
	pointer = ReadPclampFile(file, "char", pointer, nchar)
	
	if ((numtype(pointer) > 0) || (WaveExists(DumWave0) == 0))
		return ""
	endif
	
	Wave DumWave0
	
	for (icnt = 0; icnt < nchar; icnt += 1)
		str += num2char(DumWave0[icnt])
	endfor
	
	return str

End // ReadPclampString

//****************************************************************
//****************************************************************
//****************************************************************

Function /T RemoveEndSpaces(str)
	String str
	Variable icnt
	
	for (icnt = strlen(str) - 1; icnt >= 0; icnt -= 1)
		if (stringmatch(str[icnt,icnt], " ") == 0)
			return str[0,icnt]
		endif
	endfor
	
	return str
	
End // RemoveEndSpaces

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPclampFile(file, type, pointer, nread)
	String file
	String type
	Variable pointer
	Variable nread
	
	Variable bytes = 0
	
	if (numtype(pointer) > 0)
		return Nan
	endif
	
	strswitch(type)
		case "char":
			bytes = 1
			GBLoadWave /B/N=DumWave/O/S=(pointer)/T={8,2}/U=(nread)/W=1/Q file
			break
		case "unicode":
		case "short":
			bytes = 2
			GBLoadWave /B/N=DumWave/O/S=(pointer)/T={16,2}/U=(nread)/W=1/Q file
			break
		case "long":
			bytes = 4
			GBLoadWave /B/N=DumWave/O/S=(pointer)/T={32,2}/U=(nread)/W=1/Q file
			break
		case "float":
			bytes = 4
			GBLoadWave /B/N=DumWave/O/S=(pointer)/T={2,2}/U=(nread)/W=1/Q file
			break
		case "double":
			bytes = 8
			GBLoadWave /B/N=DumWave/O/S=(pointer)/T={4,4}/U=(nread)/W=1/Q file
			break
		default:
			return Nan
	endswitch
	
	return (pointer + bytes * nread)
	
End // ReadPclampFile

//****************************************************************
//****************************************************************
//****************************************************************

