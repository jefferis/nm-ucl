#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Read Axograph Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 11 May 2007
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
//	4		short		file format = 2
//	6		short		number of data columns, including x-column
//
//	X-Column Header, or time (92 Bytes)
//	0		long			column points
//    4		long			data type (?)
//	8		char[80]		column title
//	88		float			sample interval
//
//	Subsequent Y-Columns (88 + 2*ColumnPoints Bytes)
//	0		long			column points
//	4		char[80]		column title
//	84		float			scale factor
//	88		short		1st data point
//	90		short		2nd data point, etc...
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ReadAxograph(file, df, saveTheData)  // read Axograph file
	String file // file to read
	String df // data folder where everything is saved
	Variable saveTheData // (0) no (1) yes

	Variable icnt, success, format, numColumns, autoscale = 1, importDebug = 0
	String dumstr
	
	SetNMvar(df+"AxoAutoScale", autoscale)
	SetNMvar(df+"ImportDebug", importDebug)
	SetNMvar("POINTER", 0)
	
	icnt = strlen(df) - 1
	
	if (StringMatch(df[icnt,icnt], ":") == 0) // check df ends with colon
		df += ":"
	endif
	
	//
	// read main file header
	//
	
	dumstr = ReadAxoString(file, 4)
	
	if (importDebug == 1)
		Print "Axograph Header Format String:", dumstr
	endif
	
	if (StringMatch(dumstr, "AxGr") == 1)
	
		format = ReadAxoVar(file, "short")
		
		if (importDebug == 1)
			Print "File Format:", format
		endif
		
		numColumns = ReadAxoVar(file, "short") - 1 // minus the x-column
		
		if (importDebug == 1)
			Print "Total Num Waves:", numColumns
		endif
		
		switch(format)
			case 1:
			case 2:
				success = ReadAxoColumns(file, df, numColumns, saveTheData, format)
				break
			default:
				Print "Import File Aborted:  Axograph file format version " + num2str(format) + " not supported."
				return -1
		endswitch
	
	elseif (StringMatch(dumstr, "AxGx") == 1)
	
		format = ReadAxoVar(file, "long")
		
		if (importDebug == 1)
			Print "File Format:", format
		endif
		
		if (format >= 3)
			
			numColumns = ReadAxoVar(file, "long") - 1 // minus the x-column
			
			if (importDebug == 1)
				Print "Total Num Waves:", numColumns
			endif
			
			success = ReadAxoColumns(file, df, numColumns, saveTheData, format)
		
		else
			Print "Import File Aborted:  Axograph file format version " + num2str(format) + " not supported."
			return -1
		endif
	
	else
	
		//Print "Import File Aborted: file not of Axograph format."
		KillVariables /Z POINTER
		return -1
		
	endif
	
	SetNMvar(df+"FileFormat", format)
	SetNMvar(df+"TotalNumWaves", numColumns)
	SetNMstr(df+"AcqMode", "5 (Episodic)")
	
	if (CallProgress(1) == 1)
		return 0
	endif
	
	KillWaves /Z DumWave0
	KillVariables /Z POINTER
	KillVariables /Z $(df+"AxoAutoScale")
	KillVariables /Z $(df+"AxoUnitsScale")
	KillVariables /Z $(df+"ImportDebug")
	
	return success

End // ReadAxograph
	
//****************************************************************
//****************************************************************
//****************************************************************

Function ReadAxoColumns(file, df, numColumns, saveTheData, format)  // read Axograph data columns
	String file // file to read
	String df // data folder where everything is saved
	Variable numColumns
	Variable saveTheData // (0) no (1) yes
	Variable format
	
	Variable icnt, scnt, wcnt, ncnt, scale, sampleInterval
	Variable ccnt, numChannels, nomorechannels
	String dumstr, wprefix, wname, wnote, tLabel, xLabel
	
	Variable dbug = NumVarOrDefault(df+"ImportDebug", 0)
	Variable autoscale = NumVarOrDefault(df+"AxoAutoScale", 1)
	
	Variable waveBgn = NumVarOrDefault(df+"WaveBgn", 0)
	Variable waveEnd = NumVarOrDefault(df+"WaveEnd", -1)
	
	CheckNMwave(df+"FileScaleFactors", 20, 1)  // increase size
	CheckNMwave(df+"MyScaleFactors", 20, 1)
	CheckNMtwave(df+"yLabel", 20, "")
	
	Wave FileScaleFactors = $(df+"FileScaleFactors")
	Wave MyScaleFactors = $(df+"MyScaleFactors")
	Wave /T yLabel = $(df+"yLabel")
	
	FileScaleFactors = 1
	MyScaleFactors = 1
	yLabel = ""
	
	Make /O DumWave0 // where ReadAxoFile puts data
	
	NMProgressStr("Reading Axograph File...")
	CallProgress(-1)
	
	xLabel = ReadAxoColumnX(file, df, saveTheData, format)
	
	if (strlen(xLabel) == 0)
		return 0 // error
	endif
	
	SetNMstr(df+"xLabel", xLabel)
	
	wprefix = StrVarOrDefault(df+"WavePrefix", "Record")
	
	ccnt = -1
	numChannels = 0
	wcnt = 0
	ncnt = NextWaveNum("", wprefix, 0, 0)
	
	sampleInterval = NumVarOrDefault(df+"SampleInterval", 1)
	
	if (WaveEnd < 0)
		WaveEnd = numColumns
	endif
	
	for (icnt = 0; icnt < numColumns; icnt += 1) // read y-columns
	
		if (CallProgress(-2) == 1)
			return 0 // cancel
		endif
		
		tLabel = ReadAxoColumnY(file, df, saveTheData, format)
		
		if (strlen(tLabel) == 0)
			return 0 // error
		endif
		
		tLabel = CheckAxoUnits(df, tLabel)
		
		if (strlen(tLabel) > 0)
			scale = NumVarOrDefault(df+"AxoUnitsScale", 1)
		else
			scale = 1
		endif
		
		if (nomorechannels == 0)
	
			if ((StringMatch(tLabel[0,5], "Column") == 1) || (AxoLabelExists(tLabel, yLabel) == 1))
			
				nomorechannels = 1
				ccnt = 0 // return to first channel
				wcnt += 1 // next wave
				
				if (saveTheData == 0)
					scnt = 1
					break
				endif
				
			else
				
				numChannels += 1 // found a new channel
				ccnt += 1
				
				yLabel[ccnt] = tLabel
				MyScaleFactors[ccnt] = scale
				
				if (dbug == 1)
					Print "Channel " + num2str(icnt) + " Y-label:", yLabel[ccnt]
				endif
			
			endif
		
		endif
		
		if ((saveTheData == 1) && (wcnt >= WaveBgn) && (wcnt <= WaveEnd))
		
			DumWave0 *= MyScaleFactors[ccnt]
			
			wName = GetWaveName(wprefix, ccnt, ncnt)
			
			Duplicate /O DumWave0 $wName
			Setscale /P x 0, sampleInterval, $wName
			
			wNote = "Folder:" + GetDataFolder(0)
			wNote += "\rFile:" + NMNoteCheck(file)
			wNote += "\rChan:" + ChanNum2Char(ccnt)
			wNote += "\rWave:" + num2str(wcnt)
			wNote += "\rScale:" + num2str(scale)
	
			NMNoteType(wName, "Axograph", xLabel, yLabel[ccnt], wNote)
			
			scnt += 1
			ncnt += 1
		
		endif
		
		if (nomorechannels == 1)
		
			ccnt += 1
			
			if (ccnt == numChannels)
				ccnt = 0
				wcnt += 1
			endif
		
		endif
		
	endfor
	
	CheckNMwave(df+"FileScaleFactors", numChannels, 1)
	CheckNMwave(df+"MyScaleFactors", numChannels, 1)
	CheckNMtwave(df+"yLabel", numChannels, "")
	
	SetNMvar(df+"NumChannels", numChannels)
	
	return scnt

End // ReadAxoColumns

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ReadAxoColumnX(file, df, saveTheData, format) // read Axograph x-columns
	String file // file to read
	String df // data folder where everything is saved
	Variable saveTheData // (0) no (1) yes
	Variable format
	
	if (format == 1)
		return ReadAxoColumnX_1(file, df, saveTheData)
	elseif (format == 2)
		return ReadAxoColumnX_2(file, df, saveTheData)
	elseif (format >= 3)
		return ReadAxoColumnX_3(file, df, saveTheData)
	endif
	
	return ""

End // ReadAxoColumnX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ReadAxoColumnY(file, df, saveTheData, format) // read Axograph y-columns
	String file // file to read
	String df // data folder where everything is saved
	Variable saveTheData // (0) no (1) yes
	Variable format
	
	if (format == 1)
		return ReadAxoColumnY_1(file, df, saveTheData)
	elseif (format == 2)
		return ReadAxoColumnY_2(file, df, saveTheData)
	elseif (format >= 3)
		return ReadAxoColumnY_3(file, df, saveTheData)
	endif
	
	return ""

End // ReadAxoColumnY

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ReadAxoColumnX_1(file, df, saveTheData)  // read x-column, format = 1
	String file // file to read
	String df // data folder where everything is saved
	Variable saveTheData // (0) no (1) yes
	
	Variable scale, samples, intvl
	String wNote, tLabel
	
	Variable /G StartX
	
	Variable dbug = NumVarOrDefault(df+"ImportDebug", 0)
	
	Make /O/N=1 DumWave0 // where ReadAxoFile puts data
	
	samples = ReadAxoVar(file, "long")
	
	ReadAxoString(file, 1) // first char seems to be garbage
	
	tLabel = ReadAxoString(file, 79)
	tLabel = CheckAxoUnits(df, tLabel)
		
	if (strlen(tLabel) > 0)
		scale = NumVarOrDefault(df+"AxoUnitsScale", 1)
	else
		scale = 1
	endif
	
	ReadAxoFile(file, "float", samples)
	
	DumWave0 *= scale
	
	intvl = DumWave0[1] - DumWave0[0]
	StartX = DumWave0[0]
	
	if (saveTheData == 1)
	
		Duplicate /O DumWave0 ImportTimeWave
	
		if (WaveExists(ImportTimeWave) == 1)
			wNote = "Folder:" + GetDataFolder(0)
			wNote += "\rScale:" + num2str(scale)
			wNote += "\rFile:" + NMNoteCheck(file)
			NMNoteType("ImportTimeWave", "Axograph", tLabel, tLabel, wNote)
		endif
	
	endif
	
	if (dbug == 1)
		Print "Samples Per Wave:", samples
		Print "X-wave Label:", tLabel
		Print "Sample Interval:", intvl
	endif
	
	SetNMvar(df+"SamplesPerWave", samples)
	SetNMvar(df+"SampleInterval", intvl)
	
	return tLabel
	
End // ReadAxoColumnX_1

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ReadAxoColumnY_1(file, df, saveTheData)  // read y-column, format = 1
	String file // file to read
	String df // data folder where everything is saved
	Variable saveTheData // (0) no (1) yes
	
	Variable samples
	String tLabel
	
	samples = ReadAxoVar(file, "long")
	
	ReadAxoString(file, 1) // skip first character
	
	tLabel = ReadAxoString(file, 79)
	
	ReadAxoFile(file, "float", samples)
	
	return tLabel
	
End // ReadAxoColumnY_1

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ReadAxoColumnX_2(file, df, saveTheData)  // read x-column, format = 2
	String file // file to read
	String df // data folder where everything is saved
	Variable saveTheData // (0) no (1) yes
	
	Variable scale, samples, intvl
	String wNote, tLabel
	
	Variable dbug = NumVarOrDefault(df+"ImportDebug", 0)
	
	samples = ReadAxoVar(file, "long")
	
	ReadAxoVar(file, "long") // Data Type (????)
	
	ReadAxoString(file, 1) // skip first character
	
	tLabel = ReadAxoString(file, 79)
	tLabel = CheckAxoUnits(df, tLabel)
		
	if (strlen(tLabel) > 0)
		scale = NumVarOrDefault(df+"AxoUnitsScale", 1)
	else
		scale = 1
	endif
	
	intvl = ReadAxoVar(file, "float")
	intvl *= scale
	
	if (dbug == 1)
		Print "Samples Per Wave:", samples
		Print "X-wave Label:", tLabel
		Print "Sample Interval:", intvl
	endif
	
	SetNMvar(df+"SamplesPerWave", samples)
	SetNMvar(df+"SampleInterval", intvl)
	
	return tLabel
	
End // ReadAxoColumnX_2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ReadAxoColumnY_2(file, df, saveTheData)  // read y-column, format = 2
	String file // file to read
	String df // data folder where everything is saved
	Variable saveTheData // (0) no (1) yes
	
	Variable scale, samples
	String tLabel
	
	Variable dbug = NumVarOrDefault(df+"ImportDebug", 0)
	
	Make /O/N=1 DumWave0 // where ReadAxoFile puts data
	
	samples = ReadAxoVar(file, "long")
		
	ReadAxoString(file, 1) // skip first character
	
	tLabel = ReadAxoString(file, 79)
	
	scale = ReadAxoVar(file, "float")
	
	ReadAxoFile(file, "short", samples)
	
	DumWave0 *= scale
	
	return tLabel
	
End // ReadAxoColumnY_2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ReadAxoColumnX_3(file, df, saveTheData)  // read x-column, format >= 3
	String file // file to read
	String df // data folder where everything is saved
	Variable saveTheData // (0) no (1) yes
	
	Variable charbytes, nchar, dataformat, scale, offset, samples, intvl
	Variable /G Startx
	String wNote, tLabel
	
	Variable dbug = NumVarOrDefault(df+"ImportDebug", 0)
	
	Make /O DumWave0 // where ReadAxoFile puts data
	
	samples = ReadAxoVar(file, "long")
	
	if (dbug == 1)
		Print "Samples Per Wave:", samples
	endif
	
	dataformat = ReadAxoVar(file, "long")
	
	if (dbug == 1)
		Print "Data Format Type:", dataformat
	endif
	
	charbytes = ReadAxoVar(file, "long")
	nchar = charbytes / 2
	
	if (dbug == 1)
		Print "Num Label Chars:", nchar
	endif
	
	tLabel = ReadAxoUnicode(file, nchar)
	tLabel = CheckAxoUnits(df, tLabel)
		
	if (strlen(tLabel) > 0)
		scale = NumVarOrDefault(df+"AxoUnitsScale", 1)
	else
		scale = 1
	endif
	
	switch(dataformat)
		
		case 4:
		case 5:
		case 6:
		case 7:
			ReadAxoColumnType(file, dataformat, samples)
			if (saveTheData == 1)
				Duplicate /O DumWave0 ImportTimeWave
			endif
			break
			
		case 9: // should be the case for x-column
		
			Startx = ReadAxoVar(file, "double")
			intvl = ReadAxoVar(file, "double")
			
			break
			
		case 10:
			
			scale = ReadAxoVar(file, "double")
			offset = ReadAxoVar(file, "double")
			
			ReadAxoFile(file, "short", samples)
			
			Duplicate /O DumWave0 ImportTimeWave
			
			if (saveTheData == 1)
				ImportTimeWave = (ImportTimeWave * scale) + offset
			endif
			
			break
			
		default:
			return ""
			
	endswitch
	
	Startx *= scale
	intvl *= scale
		
	if (WaveExists(ImportTimeWave) == 1)
	
		ImportTimeWave *= scale

		wNote = "Folder:" + GetDataFolder(0)
		wNote += "\rScale:" + num2str(scale)
		wNote += "\rFile:" + NMNoteCheck(file)
		NMNoteType("ImportTimeWave", "Axograph", tLabel, tLabel, wNote)
		
	endif
	
	if (dbug == 1)
		Print "X Label:", tLabel
		Print "Start Time:", Startx
		Print "Sample Interval:", intvl
	endif
	
	SetNMvar(df+"SamplesPerWave", samples)
	SetNMvar(df+"SampleInterval", intvl)
	
	return tLabel
	
End // ReadAxoColumnX_3

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ReadAxoColumnY_3(file, df, saveTheData)  // read y-column, format >= 3
	String file // file to read
	String df // data folder where everything is saved
	Variable saveTheData // (0) no (1) yes
	
	Variable ccnt, charbytes, nchar, dataformat, scale, offset, samples
	String tLabel
	
	Variable dbug = NumVarOrDefault(df+"ImportDebug", 0)
	
	Make /O/N=1 DumWave0 // where ReadAxoFile puts data
	
	samples = ReadAxoVar(file, "long")
	
	if (dbug == 1)
		Print "Samples Per Wave:", samples
	endif
	
	dataFormat = ReadAxoVar(file, "long")
	
	if (dbug == 1)
		Print "Data Format Type:", dataFormat
	endif
	
	charbytes = ReadAxoVar(file, "long")
	nchar = charbytes / 2
	
	if (dbug == 1)
		Print "Num Label Chars:", nchar
	endif
	
	tLabel = ReadAxoUnicode(file, nchar)
	
	switch(dataformat)
		
		case 4:
		case 5:
		case 6:
		case 7:
			ReadAxoColumnType(file, dataformat, samples)
			break
			
		case 9:
			ReadAxoVar(file, "double")
			ReadAxoVar(file, "double")
			break
			
		case 10: // should be the case
			
			scale = ReadAxoVar(file, "double")
			offset = ReadAxoVar(file, "double")
			
			ReadAxoFile(file, "short", samples) // NOW READ THE DATA
			DumWave0 = (DumWave0 * scale) + offset
			
			break
			
		default:
			return ""
				
	endswitch
	
	return tLabel
	
End // ReadAxoColumnY_3

//****************************************************************
//****************************************************************
//****************************************************************

function /S SearchAxoLabel(strLabel, what) // get title or units from label
	String strLabel
	Variable what // (0) title (1) units
	
	Variable ifirst, ilast
	
	ifirst = strsearch(strLabel, "(", 0)
	
	if (ifirst < 0) // no units
		if (what == 0)
			return strLabel
		else
			return ""
		endif
	elseif (what == 0)
		return strLabel[0, ifirst - 1]
	endif
	
	ilast = strsearch(strLabel, ")", ifirst)
	
	if (ilast < 0)
		return ""
	endif
	
	return strLabel[ifirst, ilast]

End // SearchAxoLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function AxoLabelExists(checkLabel, yLabel)
	String checkLabel
	Wave /T yLabel
	
	Variable icnt
	
	for (icnt = 0; icnt < numpnts(yLabel); icnt += 1)
		if (StringMatch(yLabel[icnt], checkLabel) == 1)
			return 1
		endif
	endfor
	
	return 0
	
End // AxoLabelExists

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckAxoUnits(df, strlabel) // autoscale of units
	String df
	String strlabel
	
	Variable scale = 1
	String title, units, tLabel
	
	Variable autoscale = NumVarOrDefault(df+"AxoAutoScale", 1)
	
	tLabel = strlabel
		
	title = SearchAxoLabel(strlabel, 0)
	units = SearchAxoLabel(strlabel, 1)
	
	if (strlen(units) < 0)
		return ""
	endif
	
	tLabel = title + units
	
	if (autoscale == 0)
		return ""
	endif
	
	strswitch(units)
		case "(s)":
		case "(S)":
		case "(sec)":
		case "(seconds)":
			tLabel = title + "(msec)"
			scale = 1000
			break
		case "(v)":
		case "(V)": // volts
			tLabel = title + "(mV)"
			scale = 1e3;
			break
		case "(a)":
		case "(A)": // amps
			tLabel = title + "(pA)"
			scale = 1e12
			break
		case "(s)":
		case "(S)": // siemens
			tLabel = title + "(nS)"
			scale = 1e9
			break
	endswitch
	
	SetNMvar(df+"AxoUnitsScale", scale)
	
	return tLabel

End // CheckAxoUnits

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadAxoColumnType(file, type, nread)
	String file
	Variable type
	Variable nread
	
	switch(type)
		case 4:
			return ReadAxoFile(file, "short", nread)
		case 5:
			return ReadAxoFile(file, "long", nread)
		case 6:
			return ReadAxoFile(file, "float", nread)
		case 7:
			return ReadAxoFile(file, "double", nread)
		case 9:
		case 10:
			return ReadAxoFile(file, "double", 2)
	endswitch
	
	return Nan
	
End // ReadAxoColumnType

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadAxoVar(file, type)
	String file
	String type
	
	ReadAxoFile(file, type, 1)
	
	if (WaveExists(DumWave0) == 0)
		return Nan
	endif
	
	Wave DumWave0
	
	return DumWave0[0]

End // ReadAxoVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /T ReadAxoString(file, nchar)
	String file
	Variable nchar
	
	Variable icnt
	String str = ""
	
	ReadAxoFile(file, "char", nchar)
	
	if (WaveExists(DumWave0) == 0)
		return ""
	endif
	
	Wave DumWave0
	
	for (icnt = 0; icnt < nchar; icnt += 1)
		str += num2char(DumWave0[icnt])
	endfor
	
	return str

End // ReadAxoString

//****************************************************************
//****************************************************************
//****************************************************************

Function /T ReadAxoUnicode(file, nchar)
	String file
	Variable nchar
	
	Variable icnt
	String str = ""
	
	ReadAxoFile(file, "unicode", nchar)
	
	if (WaveExists(DumWave0) == 0)
		return ""
	endif
	
	Wave DumWave0
	
	for (icnt = 0; icnt < nchar; icnt += 1)
		str += num2char(DumWave0[icnt])
	endfor
	
	return str

End // ReadAxoUnicode

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadAxoFile(file, type, nread)
	String file
	String type
	Variable nread
	
	Variable POINTER = NumVarOrDefault("POINTER", 0)
	
	if (numtype(POINTER * nread) > 0)
		return Nan
	endif
	
	strswitch(type)
		case "char":
			GBLoadWave /O/N=DumWave/T={8,2}/S=(POINTER)/U=(nread)/W=1/Q file
			POINTER += 1 * nread
			break
		case "unicode":
		case "short":
			GBLoadWave /O/N=DumWave/T={16,2}/S=(POINTER)/U=(nread)/W=1/Q file
			POINTER += 2 * nread
			break
		case "long":
			GBLoadWave /O/N=DumWave/T={32,2}/S=(POINTER)/U=(nread)/W=1/Q file
			POINTER += 4 * nread
			break
		case "float":
			GBLoadWave /O/N=DumWave/T={2,2}/S=(POINTER)/U=(nread)/W=1/Q file
			POINTER += 4 * nread
			break
		case "double":
			GBLoadWave /O/N=DumWave/T={4,4}/S=(POINTER)/U=(nread)/W=1/Q file
			POINTER += 8 * nread
			break
		default:
			return Nan
	endswitch
	
	SetNMvar("POINTER", POINTER)
	
	return Nan
	
End // ReadAxoFile

//****************************************************************
//****************************************************************
//****************************************************************