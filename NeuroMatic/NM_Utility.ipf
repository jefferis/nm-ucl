#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Utility Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 22 June 2007
//
//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave utility functions defined below...
//
//****************************************************************
//****************************************************************
//****************************************************************

//****************************************************************
//
//	WavesExist()
//	determine if all waves in list exist
//
//****************************************************************

Function WavesExist(wList)
	String wList // wave name list (";" seperator)
	
	Variable wcnt, yes = 1
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
		if (WaveExists($StringFromList(wcnt, wList)) == 0)
			yes = 0
		endif
	endfor
	
	return yes

End // WavesExist

//****************************************************************
//
//	GetSeqNum()
//	return sequence number of wave name
//
//
//****************************************************************

Function GetSeqNum(wname)
	String wname // wave name
	
	Variable icnt, ibeg, iend, seqnum = Nan
	
	for (icnt = strlen(wname)-1; icnt >= 0;  icnt -= 1)
		if (numtype(str2num(wname[icnt])) == 0)
			break // first appearance of number, from right
		endif
	endfor
	
	iend = icnt
	
	for (icnt = iend; icnt >= 0;  icnt -= 1)
		if (numtype(str2num(wname[icnt])) == 2)
			break // last appearance of number, from right
		endif
	endfor
	
	ibeg = icnt+1
	
	seqnum = str2num(wname[ibeg, iend])
	
	return seqnum

End // GetSeqNum

//****************************************************************
//
//	WaveListOfSize()
//	returns a list of numeric waves of certain size
//
//****************************************************************

Function /S WaveListOfSize(size, matchstr)
	Variable size // point size of waves
	String matchstr // match to string (ie. "*xyz", for all wave names that end with xyz)
	
	Variable wavcnt
	String wList, wName, opstr = "", newList = ""
	
	//if (IgorVersion() >= 5)
		//opstr = "MAXROWS:" + num2str(size) + ",MINROWS:" + num2str(size) + ",TEXT:0"
		//return WaveList(matchstr, ";", opstr)
	//endif
	
	wList = WaveList(matchstr, ";", opstr)

	for (wavcnt = 0; wavcnt < ItemsInList(wList); wavcnt += 1)
	
		wName = StringFromList(wavcnt, wList)
		
		if ((numpnts($wName) == size) && (WaveType($wName) > 0))
			newList = AddListItem(wName, newList, ";", inf)
		endif
		
	endfor
	
	return newList

End // WaveListOfSize

//****************************************************************
//
//	WaveListFolder
//
//****************************************************************

Function /S WaveListFolder(folder, matchStr, separatorStr, optionsStr)
	String folder
	String matchStr, separatorStr, optionsStr // see Igor WaveList
	
	String wList
	String saveDF = GetDataFolder(1) // save current directory
	
	folder = LastPathColon(folder,0)
	
	if (DataFolderExists(folder) == 0)
		return ""
	endif
	
	SetDataFolder $folder
	
	wList = WaveList(matchStr, separatorStr, optionsStr)
	
	SetDataFolder $saveDF // back to original data folder
	
	return wList

End // WaveListFolder

//****************************************************************
//
//	WaveListText0()
//
//****************************************************************

Function /S WaveListText0() // only Igor 5

	if (IgorVersion() >= 5)
		return "Text:0"
	else
		return ""
	endif

End // WaveListText0

//****************************************************************
//
//	Wave2List()
//	convert wave items to list items
//
//****************************************************************

Function /S Wave2List(wName)
	String wName // wave name
	
	Variable icnt, text, npnts, numObj
	String strObj, wList = ""
	
	if (WaveExists($wName) == 0)
		return ""
	endif
	
	if (WaveType($wName) == 0)
		Wave /T wtext = $wName
		npnts = numpnts(wtext)
		text = 1
	else
		Wave wtemp = $wName
		npnts = numpnts(wtemp)
	endif
	
	for (icnt = 0; icnt < npnts; icnt += 1)
		if (text == 1)
			strObj = wtext[icnt]
			if (strlen(strObj) > 0)
				wList = AddListItem(strObj, wList, ";", inf)
			endif
		else
			wList = AddListItem(num2str(wtemp[icnt]), wList, ";", inf)
		endif 
	endfor
	
	return wList

End // Wave2List

//****************************************************************
//
//	List2Wave()
//	convert list items to wave items
//
//****************************************************************

Function List2Wave(strList, wName)
	String strList
	String wName // wave name
	
	Variable icnt
	String item
	
	Variable items = ItemsInList(strList)
	
	if (items == 0)
		return 0 // nothing to do
	endif
	
	if (WaveExists($wName) == 1)
		DoAlert 0, "Abort List2Wave: wave " + wName + " already exists."
		return -1
	endif
	
	Make /T/N=(items) $wName
	
	Wave /T wtemp = $wName
	
	for (icnt = 0; icnt < items; icnt += 1)
		wtemp[icnt] = StringFromList(icnt, strList)
	endfor
	
	return 0

End // Wave2List

//****************************************************************
//
//
//
//****************************************************************

Function NMUtilityAlert(fxn, badList)
	String fxn
	String badList

	if (ItemsInList(badList) <= 0)
		return 0
	endif
	
	String alert = fxn + " Alert : the following waves did not pass sucessfully through function execution : " + badList
	
	//DoAlert 0, alert
	
	NMhistory(alert)
	
End // NMUtilityAlert

//****************************************************************
//
//
//
//****************************************************************

Function NMUtilityWaveTest(wName)
	String wName
	
	if ((WaveExists($wName) == 0) || (WaveType($wName) == 0))
		return -1
	endif
	
	return 0
	
End // NMUtilityWaveTest

//****************************************************************
//
//	NMPlotWaves()
//	plot a list of waves
//
//****************************************************************

Function NMPlotWaves(gName, gTitle, xLabel, yLabel, wList) // renamed from PlotWaves to avoid software conflicts
	String gName // graph name
	String gTitle // graph title
	String xLabel // x axis label, or ("") from wave notes
	String yLabel // y axis label, or ("") from wave notes
	String wList // wave list (seperator ";")

	String wName, badList = wList
	Variable wcnt, gmode, first = 1
	
	if (ItemsInList(wList) == 0)
		return -1
	endif
	
	DoWindow /K $gName // warning, this function will kill window named gName if it already exists
	
	if (strlen(xLabel) == 0)
		xLabel = NMNoteLabel("x", wList, "")
	endif
	
	if (strlen(yLabel) == 0)
		yLabel = NMNoteLabel("y", wList, "")
	endif

	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)

		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		badList = RemoveFromList(wName, badList)
		
		WaveStats /Q $wName
		
		if ((V_numNaNs > 2) && (V_npnts > 0) && (V_npnts < 1000))
			//gmode = 4
		endif
	
		if (first == 1)
			first = 0
			Display /K=1/W=(0,0,0,0) $wName as gTitle
			DoWindow /C $gName
			SetCascadeXY(gName)
			continue
		endif
		
		if (first == 0)
			AppendToGraph $wName
		endif
		
	endfor
	
	if (first == 1)
		return -1 // nothing plotted
	endif
	
	ModifyGraph rgb=(0,0,0), mode=gmode
	Label left yLabel
	Label bottom xLabel
	ModifyGraph standoff=0
	ShowInfo
	SetAxis /A
	
	NMUtilityAlert("NMPlotWaves", badList)
	
	return 0

End // NMPlotWaves

//****************************************************************
//
//	EditWaves()
//	edit a list of waves (create a table)
//
//****************************************************************

Function EditWaves(tName, tTitle, wList)
	String tName // graph name
	String tTitle // graph title
	String wList // wave list (seperator ";")

	String wName, badList = wList
	Variable wcnt, first = 1
	
	if ((strlen(tName) == 0) || (ItemsInList(wList) == 0))
		return -1
	endif
	
	if (WinType(tName) > 0)
	
		if (WinType(tName) != 2)
			DoAlert 0, "Abort EditWaves: window already exists with that name : " + tName
			return -1
		endif
	
		DoAlert 2, "Warning: table \"" + tName + "\" already exists. Do you want to overwrite it?"
		
		if (V_flag == 1) // yes
		
			DoWindow /K $tName // kill window
			
		elseif (V_flag == 2) // no
			
			tName += "_0"
			
			Prompt tName, "enter new name for table:"
			DoPrompt "Edit Waves", tName
			
			if (V_flag == 1)
				return -1 // cancel
			endif
		
		elseif (V_flag == 3) // cancel
		
			return - 1
			
		endif
	
	endif

	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)

		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		badList = RemoveFromList(wName, badList)
	
		if (first == 1)
			first = 0
			Edit /K=1/W=(0,0,0,0) $wName as tTitle
			DoWindow /C $tName
			SetCascadeXY(tName)
			continue
		endif
		
		if (first == 0)
			AppendToTable $wName
		endif
		
	endfor
	
	if (first == 1)
		return -1 // nothing plotted
	endif
	
	NMUtilityAlert("EditWaves", badList)
	
	return 0

End // EditWaves

//****************************************************************
//
//	DeleteWaves()
//	delete a list of waves
//
//****************************************************************

Function /S DeleteWaves(wList)
	String wList // wave list (seperator ";")
	
	String wName, outList = "", badList = wList
	Variable wcnt, move
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (WaveExists($wName) == 0)
			continue
		endif
		
		KillWaves /Z $wName
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
	
	endfor
	
	NMUtilityAlert("DeleteWaves", badList)
	
	return outList

End // DeleteWaves

//****************************************************************
//
//	CopyWaves()
//	duplicate a list of waves - giving them a new prefix name
//
//****************************************************************

Function /S CopyWaves(newPrefix, tbgn, tend, wList)
	String newPrefix // new wave prefix of duplicated waves
	Variable tbgn, tend // copy data from, to
	String wList // wave list (seperator ";")
	
	String wName, newName, newList = "", badList = ""
	Variable wcnt, alert
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		//newName = newPrefix + ChanCharGet(wName) + num2str(ChanWaveNum(wName))
		newName = newPrefix + wName
		newList = AddListItem(newName, newList, ";", inf)
		
		if (StringMatch(wName, newName) == 1)
			return ""
		endif
		
		if (WaveExists($newName) == 1)
			alert = 1
		endif
		
	endfor
	
	if (alert == 1)
	
		DoAlert 2, "CopyWaves Alert: wave(s) with prefix \"" + newPrefix + "\" already exist. Do you want to over-write them?"
		
		if (V_flag != 1)
			return "" // cancel
		endif
		
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(newList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		newName = StringFromList(wcnt, newList)
		
		if (WaveExists($wName) == 0)
			continue
		endif
		
		if ((numtype(tbgn) == 0) && (numtype(tend) == 0))
			Duplicate /O/R=(tbgn,tend) $wName $newName
		else
			Duplicate /O $wName $newName
		endif
		
		badList = RemoveFromList(wName, badList)
		
		Note $newName, "Func:CopyWaves"
		Note $newName, "Copy From:" + num2str(tbgn) + ";Copy To:" + num2str(tend) + ";"
		
	endfor
	
	NMUtilityAlert("CopyWaves", badList)
	
	return newList

End // CopyWaves

//****************************************************************
//
//	CopyAllWavesTo()
//	copy all waves from one folder to another
//
//****************************************************************

Function /S CopyAllWavesTo(fromFolder, toFolder, alert)
	String fromFolder, toFolder
	Variable alert // (0) no alert (1) alert if overwriting
	
	CopyWavesTo(fromFolder, toFolder, "", -inf, inf, "", alert)
	
End // CopyAllWavesTo

//****************************************************************
//
//	CopyWavesTo()
//	copy waves from one folder to another
//
//****************************************************************

Function /S CopyWavesTo(fromFolder, toFolder, newPrefix, tbgn, tend, wList, alert)
	String fromFolder, toFolder
	String wList // wave list ("") all waves
	String newPrefix // new wave prefix, ("") for same as source
	Variable tbgn, tend // copy data from, to
	Variable alert // (0) no alert (1) alert if overwriting
	
	Variable wcnt, overwrite, first = 1
	String wname, dname, outList = "", badList = wList
	
	if ((DataFolderExists(fromFolder) == 0) || (DataFolderExists(toFolder) == 0))
		return ""
	endif
	
	if (strlen(wList) == 0)
		wList = WaveListFolder(fromFolder, "*", ";", "")
	endif
	
	toFolder = LastPathColon(toFolder,1)
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wname = StringFromList(wcnt, wList)
	
		dname = toFolder + newPrefix + wname
		
		if ((WaveExists($dname) == 1) && (alert == 1) && (first == 1))
		
			DoAlert 1, "CopyWavesTo Alert: wave(s) with the same name already exist in " + LastPathColon(toFolder,0) + ". Do you want to over-write them?"
			
			first = 0
			
			if (V_flag == 1)
				overwrite = 1
			endif
			
		endif
		
		if ((WaveExists($dname) == 1) && (alert == 1) && (overwrite == 0))
			continue
		endif
		
		if (WaveExists($(fromFolder+wname)) == 0)
			continue
		endif
		
		Wave wtemp = $(fromFolder+wname)
		
		if ((numtype(tbgn) == 0) && (numtype(tend) == 0))
			Duplicate /O/R=(tbgn,tend) wtemp $dname
		else
			Duplicate /O wtemp $dname
		endif
		
		outList = AddListItem(dname, outList, ";", inf)
		
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	//NMUtilityAlert("CopyWavesTo", badList)
	
	return outList

End // CopyWavesTo

//****************************************************************
//
//	RenameWaves()
//	string replace name
//
//****************************************************************

Function /S RenameWaves(findStr, repStr, wList)
	String findStr // search string
	String repStr // replace string
	String wList // wave list (seperator ";")
	
	if (strlen(findStr) <= 0)
		return ""
	endif
	
	String wName, newName = "", outList = "", badList = wList
	Variable wcnt, first = 1, kill
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		newName = StringReplace(wName,findStr,repStr)
		
		if (StringMatch(newName, wName) == 1)
			continue // no change
		endif
		
		if ((WaveExists($newName) == 1) && (first == 1))
			DoAlert 1, "Name Conflict: wave(s) already exist with new name. Do you want to over-write them?"
			first = 0
			if (V_Flag == 1)
				kill = 1
			endif
		endif
		
		if ((WaveExists($newName) == 1) && (kill == 1) && (first == 0))
			KillWaves /Z $newName
		endif
		
		if ((WaveExists($wName) == 0) || (WaveExists($newName) == 1))
			continue
		endif

		Rename $wName $newName
		
		outList = AddListItem(newName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	//NMUtilityAlert("RenameWaves", badList)
	
	return outList

End // RenameWaves

//****************************************************************
//
//	RenumberWaves()
//	string replace name
//
//****************************************************************

Function /S RenumberWaves(from, wList)
	Variable from // renumber from
	String wList // wave list (seperator ";")
	
	DoAlert 0, "Alert: RenumberWaves has been deprecated."
	
	return ""

End // RenumberWaves

//****************************************************************
//
//	ConcatWaves()
//	concatenate waves together
//
//****************************************************************

Function /S ConcatWaves(wList, outname)
	String wList // input wave name list (";" seperator)
	String outname // output wname
	
	Variable npnts0, npnts1, icnt
	String xl, yl
	
	if ((WavesExist(wList) == 0) || (ItemsInList(wList) < 2))
		return ""
	endif
	
	Duplicate /O $StringFromList(0, wList) U_ConcatWave0
	
	for (icnt = 1; icnt < ItemsInList(wList); icnt += 1)
	
		Duplicate /O $StringFromList(icnt, wList) U_ConcatWave1
	
		npnts0 = numpnts(U_ConcatWave0)
		npnts1 = numpnts(U_ConcatWave1)
	
		Redimension /N=(npnts0+npnts1) U_ConcatWave0, U_ConcatWave1
		Rotate npnts0, U_ConcatWave1
	
		U_ConcatWave0 += U_ConcatWave1
		
	endfor
	
	Duplicate /O U_ConcatWave0 $outname
	
	KillWaves /Z U_ConcatWave0, U_ConcatWave1
	
	xl = NMNoteLabel("x", wList, "")
	yl = NMNoteLabel("y", wList, "")
	
	NMNoteType(outName, "NMConcat", xl, xl, "Func:ConcatWaves")
	Note $outName, "Wave List:" + ChangeListSep(wList, ",")
	
	return wList

End // ConcatWaves

//****************************************************************
//
//	DiffWaves()
//	differentiate a list of waves
//
//****************************************************************

Function /S DiffWaves(wList, dflag)
	String wList // wave list (seperator ";")
	Variable dflag // (1) single d/dt (2) double d/dt (3)  integrate
	
	String wName, outList = "", badList = wList
	Variable wcnt, count
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		Note $wName, "Func:DiffWaves"
		
		switch(dflag)
			case 1:
				Differentiate $wName
				Note $wName, "F(t):d/dt;"
				break
			case 2:
				Differentiate $wName
				Differentiate $wName
				Note $wName, "F(t):dd/dt*dt;"
				break
			case 3:
				Integrate $wName
				Note $wName, "F(t):integrate;"
				break
			default:
				return ""
		endswitch
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	NMUtilityAlert("DiffWaves", badList)
	
	return outList

End // DiffWaves

//****************************************************************
//
//	SmoothWaves()
//	smooth a list of waves, using Smooth function
//
//****************************************************************

Function /S SmoothWaves(method, AvgN, wList)
	String method // smoothing algorithm
	Variable AvgN // smooth number (see 'Smooth' help)
	String wList // wave list (seperator ";")
	
	String wName, outList = "", badList = wList
	Variable wcnt
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	if ((AvgN < 1) || (numtype(AvgN) != 0))
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		Note $wName, "Func:SmoothWaves"
		
		strswitch(method)
			case "binomial":
			case "Binomial":
				Smooth AvgN, $wName
				Note $wName, "Smth Alg:binomial;Smth Num:" + num2str(AvgN) + ";"
				break
			case "boxcar":
			case "Boxcar":
				Smooth /B AvgN, $wName
				Note $wName, "Smth Alg:boxcar;Smth Num:" + num2str(AvgN) + ";"
				break
			case "polynomial":
			case "Polynomial":
				Smooth /S=2 AvgN, $wName
				Note $wName, "Smth Alg:polynomial;Smth Num:" + num2str(AvgN) + ";"
				break
			default:
				return ""
		endswitch
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
	
	endfor
	
	NMUtilityAlert("SmoothWaves", badList)
	
	return outList

End // SmoothWaves

//****************************************************************
//
//	DecimateWaves()
//	decimate a list of waves - ie. reduce the number of points by linear interp
//
//****************************************************************

Function /S DecimateWaves(ipnts, wList)
	Variable ipnts // number of points to reduce waves by
	String wList // wave list (seperator ";")
	
	String wName, oldnote, outList = "", badList = wList
	Variable wcnt, npnts, tdelta
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	if ((ipnts < 1) || (numtype(ipnts) > 0))
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		npnts = numpnts($wName)/ipnts
		tdelta = deltax($wName)

		Execute /Z "Interpolate/T=1/N=" + num2str(npnts) + "/Y=U_InterpY " + wname
		// Interpolate function must be called by Execute
		
		if (V_Flag < 0)
			continue
		endif
		
		oldnote = note($wName)
		
		Duplicate /O U_InterpY, $wName
		Setscale /P x 0, (tdelta*ipnts), $wName
		
		Note /K $wName
		Note $wName, oldnote
		Note $wName, "Func:DecimateWaves"
		Note $wName, "Decimate Pnts:" + num2str(ipnts)
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	KillWaves /Z U_InterpY
	
	NMUtilityAlert("DecimateWaves", badList)
	
	return outList

End // DecimateWaves

//****************************************************************
//
//	InterpolateWaves()
//	x-interpolate a list of waves
//
//****************************************************************

Function /S InterpolateWaves(alg, mode, xwave, wList)
	Variable alg // (1) linear (2) cubic spline
	Variable mode	// (1) compute a common x-axis for input waves
					// (2) use x-axis scale of xwave
					// (3) use values of xwave as x-scale
	String xwave // wave to derive x-values from
	String wList // wave list (seperator ";")

	Variable wcnt, npnts, dx, lftx, lx, rghtx, rx
	String wName, oldnote, outList = "", badList = wList
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	switch(mode)
		case 1:
			dx = GetXStats("deltax", wList)
			lftx = GetXStats("minleftx", wList)
			rghtx = GetXStats("maxrightx", wList)
			npnts = (rghtx-lftx)/dx
			Make /O/N=(npnts) U_InterpX
			U_InterpX = lftx + x*dx
			break
		case 2:
			dx = deltax($xwave)
			lftx = leftx($xwave)
			rghtx = rightx($xwave)
			npnts = numpnts($xwave)
			Duplicate /O $xwave U_InterpX
			U_InterpX = x
			break
		case 3:
			Duplicate /O $xwave U_InterpX
			npnts = numpnts(U_InterpX)
			lftx = U_InterpX[0]
			rghtx = U_InterpX[npnts-1]
			dx = U_InterpX[1] - U_InterpX[0] // (assuming equal intervals)
			break
		default:
			return ""
	endswitch
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		lx = leftx($wName); rx = rightx($wName)
				
		Execute /Z "Interpolate /T=" + num2str(alg) + "/I=3/Y=U_InterpY /X=U_interpX " + wname
		// Interpolate function must be called by Execute
		
		if (V_Flag < 0)
			continue
		endif
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
		oldnote = note($wName)
		Duplicate /O U_InterpY, $wName
		
		Wave wtemp = $wName
		
		Setscale /P x lftx, dx, wtemp
		
		if (lx > lftx)
			wtemp[x2pnt(wtemp, lftx), x2pnt(wtemp, lx)] = Nan
		endif
		
		if (rx < rghtx)
			wtemp[x2pnt(wtemp, rx), x2pnt(wtemp, rghtx)] = Nan
		endif
		
		Note /K $wName
		Note $wName, oldnote
		
		Note $wName, "Func:InterpolateWaves"
		
		if (mode == 0)
			Note $wName, "Interp Leftx:" + num2str(lftx) + ";Interp Rightx:" + num2str(rghtx) + ";Interp dx:" + num2str(dx) + ";"
		elseif (mode == 1)
			Note $wName, "Interp xScale:" + xwave
		elseif (mode == 2)
			Note $wName, "Interp xValues:" + xwave
		endif
		
	endfor
	
	KillWaves /Z U_InterpX, U_InterpY
	
	NMUtilityAlert("InterpolateWaves", badList)
	
	return outList

End // InterpolateWaves

//****************************************************************
//
//	NormWaves()
//	normalize a list of waves - uses min and max values
//
//****************************************************************

Function /S NormWaves(fxn, tbgn, tend, bbgn, bend, wList)
	String fxn // normalize function ("max" or "min" or "avg")
	Variable tbgn, tend // window to compute max or min
	Variable bbgn, bend // baseline window
	String wList // wave list (seperator ";")
	
	String wName, outList = "", badList = wList
	Variable wcnt, value, amp, base, scale = 1, items = ItemsInList(wList)
	
	strswitch(fxn)
		case "max":
		case "min":
		case "avg":
			break
		default:
			return ""
	endswitch
	
	if (items == 0)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		Wave tempwave = $wName
		
		WaveStats /Q/R=(bbgn,bend) tempwave
		base = V_avg
		
		WaveStats /Q/R=(tbgn,tend) tempwave
		
		strswitch(fxn)
			case "max":
				value = V_max
				break
			case "min":
				value = V_min
				break
			case "avg":
				value = V_avg
				break
		endswitch
		
		if (value < base)
			scale = -1
		endif
		
		amp = abs(value - base)
		
		if ((amp == 0) || (numtype(amp) > 0))
			Print "Normalization error, skipped wave:", wName
			continue
		else
			tempwave = scale * (tempwave - base) / amp
		endif
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
		Note tempwave, "Func:NormWaves"
		Note tempwave, "Norm Value:" + num2str(value) + ";Norm Alg:" + fxn + ";Norm PeakBgn:" + num2str(tbgn) + ";Norm PeakEnd:" + num2str(tend) + ";Norm BaseBgn:" + num2str(bbgn) + ";Norm BaseEnd:" + num2str(bend) + ";"
	
	endfor
	
	NMUtilityAlert("NormWaves", badList)
	
	return outList

End // NormWaves

//****************************************************************
//
//	BlankWaves()
//	blank waves using a wave of event times
//
//****************************************************************

Function /S BlankWaves(waveOfEventTimes, tbefore, tafter, bvalue, wList)
	String waveOfEventTimes // wave of event times
	Variable tbefore // blank time before event
	Variable tafter // blank time after event
	Variable bvalue // blank value (try Nan)
	String wList // wave list (seperator ";")
	
	Variable wcnt, icnt, t, tbgn, tend, pbgn, pend, nwaves = ItemsInList(wList)
	String wName, outList = "", badList = wList
	
	if ((WaveExists($waveOfEventTimes) == 0) || (nwaves == 0))
		return ""
	endif
	
	Wave events = $waveOfEventTimes
	
	for (wcnt = 0; wcnt < nwaves; wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		Wave tempwave = $wName
		
		for (icnt = 0; icnt < numpnts(events); icnt += 1)
			t = events[icnt]
			if (numtype(t) > 0)
				continue
			endif	
			tbgn = t - tbefore
			tend = t + tafter
			if (tbgn < leftx(tempwave))
				tbgn = leftx(tempwave)
			endif
			if (tend > rightx(tempwave))
				tend = rightx(tempwave)
			endif
			pbgn = x2pnt(tempwave, tbgn)
			pend = x2pnt(tempwave, tend)
			tempwave[pbgn, pend] = bvalue
		endfor
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
		Note tempwave, "Func:BlankWaves"
		Note tempwave, "Blank Event Times:" + waveOfEventTimes + ";Blank Before:" + num2str(tbefore) + ";Blank After:" + num2str(tafter) + ";"
	
	endfor
	
	NMUtilityAlert("BlankWaves", badList)
	
	return outList

End // BlankWaves

//****************************************************************
//
//	DFOFWaves()
//	compute DF/Fo
//
//****************************************************************

Function /S DFOFWaves(bbgn, bend, wList)
	Variable bbgn, bend // baseline window
	String wList // wave list (seperator ";")
	
	String wName, outList = "", badList = wList
	Variable wcnt, value, amp, base, scale = 1, items = ItemsInList(wList)
	
	if (items == 0)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		Wave tempwave = $wName
		
		WaveStats /Q/R=(bbgn,bend) tempwave
		base = V_avg
		
		if (numtype(base) > 0)
			Print "dF/Fo error, skipped wave:", wName
			continue
		else
			tempwave = (tempwave - base) / base
		endif
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
		Note tempwave, "Func:dFoFWaves"
		Note tempwave, "dFoF Bsln Value:" + num2str(base) + ";dFoF BaseBgn:" + num2str(bbgn) + ";dFoF BaseEnd:" + num2str(bend) + ";"
	
	endfor
	
	NMUtilityAlert("DFOFWaves", badList)
	
	return outList

End // DFOFWaves

//****************************************************************
//
//	ReverseWaves(wName)
//	reflect wave(s) about x-axis
//
//****************************************************************

Function /S ReverseWaves(wList)
	String wList
	
	String wName, outList = "", badList = wList
	Variable wcnt, icnt, npnts, items
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	items = ItemsInList(wList)
	
	NMProgressStr("Reflecting Waves...")
	
	for (wcnt = 0; wcnt < items; wcnt += 1)
		
		if (CallProgress(wcnt/(items-1)) == 1) // cancel
			wcnt = -1
			break
		endif
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
	
		Wave inWave = $wName
	
		Duplicate /O inWave tempWave
	
		npnts = numpnts($wName)
	
		for (icnt = 0; icnt < npnts; icnt += 1)
			tempWave[npnts - 1 - icnt] = inWave[icnt]
		endfor
	
		inWave = tempWave
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
		Note inWave, "Func:ReverseWaves"
		
	endfor
	
	KillWaves /Z tempWave
	
	NMUtilityAlert("ReverseWaves", badList)
	
	return outList

End // ReverseWaves

//****************************************************************
//
//	AlignByNum()
//	align x-zero point of a list of waves at a single offset value
//
//****************************************************************

Function AlignByNum(offset, wList)
	Variable offset // zero-alignment value
	String wList // wave list (seperator ";")
	
	String wName, badList = wList
	Variable wcnt, dx
	
	if (ItemsInList(wList) == 0)
		return -1
	endif
	
	if (numtype(offset) != 0)
		return -1
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		dx = deltax($wName)
	
		Setscale /P x -offset, dx, $wName
		//Note $wName, "Func:AlignByNum"
		//Note $wName, "Align Offset:" + num2str(offset)
		
		badList = RemoveFromList(wName, badList)
	
	endfor
	
	NMUtilityAlert("AlignByNum", badList)
	
	return 0

End // AlignByNum

//****************************************************************
//
//	ScaleByNum()
//	scale a list of waves (x, /, +, -) by a single number
//
//****************************************************************

Function /S ScaleByNum(alg, num, wList)
	String alg // arhithmatic symbol (x, /, +, -)
	Variable num // scale value
	String wList // wave list (seperator ";")
	
	Variable wcnt
	String wName, outList = "", badList = wList
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	//if (numtype(num) != 0)
		//return ""
	//endif
	
	if (strsearch("x*/+-", alg, 0) == -1)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		Wave wtemp = $wName
		
		strswitch(alg)
			case "*":
			case "x":
				wtemp *= num
				break
			case "/":
				wtemp /= num
				break
			case "+":
				wtemp += num
				break
			case "-":
				wtemp -= num
				break
			default:
				continue
		endswitch
		
		//Execute /Z wName + alg + "=" + num2str(num)
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
		Note $wName, "Func:ScaleByNum"
		Note $wName, "Scale Alg:" + alg + ";Scale Value:" + num2str(num) + ";"
		
	endfor
	
	NMUtilityAlert("ScaleByNum", badList)
	
	return outList

End // ScaleByNum

//****************************************************************
//
//	ScaleWave()
//	scale a list of waves (x, /, +, -) by a single number
//
//****************************************************************

Function /S ScaleWave(alg, num, tbgn, tend, wList)
	String alg // arhithmatic symbol (x, /, +, -)
	Variable num // scale value
	Variable tbgn, tend // time begin, end values
	String wList // wave list (seperator ";")
	
	Variable wcnt, pcnt, pbgn, pend
	String wName, outList = "", badList = wList
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	//if (numtype(num) != 0)
	//	return ""
	//endif
	
	if (strsearch("x*/+-", alg, 0) == -1)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		if (numtype(tbgn) == 1)
			pbgn = 0
		else
			pbgn = x2pnt($wName, tbgn)
		endif
		
		if (numtype(tend) == 1)
			pend = numpnts($wName) - 1
		else
			pend = x2pnt($wName, tend)
		endif
		
		if ((pbgn < 0) || (pend >= numpnts($wName)))
			continue
		endif
		
		Wave wtemp = $wName
		
		for (pcnt = pbgn; pcnt <= pend; pcnt += 1)
			
			strswitch(alg)
				case "*":
				case "x":
					wtemp[pcnt] *= num
					break
				case "/":
					wtemp[pcnt] /= num
					break
				case "+":
					wtemp[pcnt] += num
					break
				case "-":
					wtemp[pcnt] -= num
					break
				default:
					continue
			endswitch
		
		endfor
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
		Note $wName, "Func:ScaleWave"
		Note $wName, "Scale Alg:" + alg + ";Scale Value:" + num2str(num) + ";Scale Tbgn:" + num2str(tbgn) + ";Scale Tend:" + num2str(tend)
		
	endfor
	
	NMUtilityAlert("ScaleWave", badList)
	
	return outList

End // ScaleWave

//****************************************************************
//
//	ScaleByWave()
//	scale a list of waves (x, /, +, -) by another wave of equal points
//
//****************************************************************

Function /S ScaleByWave(alg, sclWave, wList) // all input waves should have same number of points
	String alg // arhithmatic symbol (x, /, +, -)
	String sclWave // wave to scale by
	String wList // wave list (seperator ";")
	
	Variable wcnt, npnts
	String wName, outList = "", badList = wList
	
	if (ItemsInList(wList) == 0)
		return ""
	endif

	if (WaveExists($sclWave) == 0)
		return ""
	endif

	if (strsearch("x*/+-", alg, 0) == -1)
		return ""
	endif
	
	npnts = GetXStats("numpnts", wList)
	
	if (npnts != numpnts($sclWave))
		return "" // should have the same number of points
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		if (numpnts($wName) != numpnts($sclWave))
			continue // skip, unequal waves
		endif
		
		Wave wtemp = $wName
		Wave stemp = $sclWave
		
		strswitch(alg)
			case "*":
			case "x":
				wtemp *= stemp
				break
			case "/":
				wtemp /= stemp
				break
			case "+":
				wtemp += stemp
				break
			case "-":
				wtemp -= stemp
				break
			default:
				continue
		endswitch

		//Execute wName + alg + "=" + sclWave
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
		Note $wName, "Func:ScaleByWave"
		Note $wName, "Scale Alg:" + alg + ";Scale Wave:" + sclWave + ";"
		
	endfor
	
	NMUtilityAlert("ScaleByWave", badList)
	
	return outList

End // ScaleByWave

//****************************************************************
//
//	SetXScale()
//	set the x-scaling of a list of waves
//
//****************************************************************

Function /S SetXScale(startx, dx, npnts, wList)
	Variable startx // time of first x-point (Nan)  dont change
	Variable dx // time step value (-1) dont change
	Variable npnts // number of points (-1) dont change
	String wList // wave list (seperator ";")
	
	Variable wcnt, wpnts
	String wName, outList = "", badList = wList
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	if (numtype(dx*npnts) != 0)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		wpnts = numpnts($wName)
		
		if ((npnts > 0) && (wpnts != npnts))
			CheckNMwave(wName, npnts, Nan) // Redimension
		endif
		
		if ((numtype(startx) == 0) && (dx > 0))
			Setscale /P x startx, dx, $wName
		elseif ((numtype(startx) == 0) && (dx == -1))
			Setscale /P x startx, deltax($wName), $wName
		elseif ((numtype(startx) > 0) && (dx > 0))
			Setscale /P x leftx($wName), dx, $wName
		endif
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	NMUtilityAlert("SetXScale", badList)
	
	return outList
	
End // SetXScale

//****************************************************************
//
//	Baseline()
//	subtract mean baseline value from a list of waves
//
//****************************************************************

Function /S BaselineWaves(method, tbgn, tend, wList)
	Variable method // (1) subtract wave's individual mean, (2) subtract mean of all waves
	Variable tbgn // begin time of mean computation
	Variable tend // end time of mean computation
	String wList // wave list (seperator ";")
	
	String wName, mnsd, outList = "", badList = wList
	Variable wcnt, mn, sd, cnt
	
	//String wPrefix = "MN_Bsln_" + NMWaveSelectStr()
	//String outName = NextWaveName(wPrefix, NMCurrentChan(), 1)
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	if ((method < 0) || (method > 2) || (tend <= tbgn) || (numtype(tend*tbgn) == 2))
		return ""
	endif
	
	if (method == 2) // subtract mean of all waves
	
		mnsd = MeanStdv(tbgn, tend, wList) // compute mean and stdv of waves
		
		mn = str2num(StringByKey("mean", mnsd, "="))
		sd = str2num(StringByKey("stdv", mnsd, "="))
		cnt = str2num(StringByKey("count", mnsd, "="))
	 
		DoAlert 1, "Baseline mean = " + num2str(mn) + " ± " + num2str(sd) + ".    Subtract mean from selected waves?"
	
		if (V_Flag != 1)
			return "" // cancel
		endif
	
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
	
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
	
		Wave tempwave = $wName
		
		if (method == 1)
			mn = mean(tempwave, tbgn, tend)
		endif
	
		tempwave -= mn
		
		Note tempwave, "Func:BaselineWaves"
		Note tempwave, "Bsln Value:" + num2str(mn) + ";Bsln Tbgn:" + num2str(tbgn) + ";Bsln Tend:" + num2str(tend) + ";"
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
	
	endfor
	
	NMUtilityAlert("BaselineWaves", badList)
	
	return outList

End // BaselineWaves

//****************************************************************
//
//	AvgWaves()
//	compute avg and stdv of waves; results stored in U_Avg and U_Sdv
//
//****************************************************************

Function /S AvgWaves(wList)
	String wList // wave list (seperator ";")

	Variable wcnt, icnt, items
	String xl, yl, txt, wName, outList = "", badList = wList
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	Variable dx = GetXStats("deltax", wList)
	Variable lftx = GetXStats("maxleftx", wList)
	Variable rghtx = GetXStats("minrightx", wList)
	
	if (numtype(dx) != 0)
		DoAlert 0, "AvgWaves Abort : waves do not have the same delta-x values."
		return ""
	endif
	
	items = ItemsInList(wList)
	
	NMProgressStr("Averaging Waves...")
	
	for (wcnt = 0; wcnt < items; wcnt += 1)
		
		if (CallProgress(wcnt/(items-1)) == 1) // cancel
			wcnt = -1
			break
		endif
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		if (icnt == 0) // first wave
			Duplicate /O/R=(lftx,rghtx)  $wName U_Avg
			Duplicate /O/R=(lftx,rghtx)  $wName U_Sdv
			U_Sdv *= U_Sdv
		else
			Duplicate /O/R=(lftx,rghtx)  $wName U_waveCopy
			U_Avg += U_waveCopy
			U_Sdv += U_waveCopy^2
		endif
		
		icnt += 1
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	if (wcnt > 1)
		U_Sdv = sqrt((U_Sdv - ((U_Avg^2) / icnt)) / (icnt - 1))
		U_Avg = U_Avg / icnt
		Setscale /P x lftx, dx, U_Avg, U_Sdv
	endif
	
	xl = NMNoteLabel("x", wList, "")
	yl = NMNoteLabel("y", wList, "")
	
	NMNoteType("U_Avg", "NMAvg", xl, yl, "Func:AvgWaves")
	NMNoteType("U_Sdv", "NMSdv", xl, yl, "Func:AvgWaves")
	
	txt = "Wave List:" + ChangeListSep(wList, ",")
	
	if (WaveExists(U_Avg) == 1)
		Note U_Avg, txt
	endif
	
	if (WaveExists(U_Sdv) == 1)
		Note U_Sdv, txt
	endif
	
	KillWaves /Z U_waveCopy
	
	NMUtilityAlert("AvgWaves", badList)
	
	return outList

End // AvgWaves

//****************************************************************
//
//	SumWaves()
//	compute sum of waves; results stored in wave U_Sum
//
//****************************************************************

Function /S SumWaves(wList)
	String wList // wave list (seperator ";")

	Variable wcnt, icnt, items
	String xl, yl, txt, wName, outList = "", badList = wList
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	Variable dx = GetXStats("deltax", wList)
	Variable lftx = GetXStats("maxleftx", wList)
	Variable rghtx = GetXStats("minrightx", wList)
	Variable npnts = GetXStats("numpnts", wList)
	
	if (numtype(dx*npnts) > 0)
	
		DoAlert 1, "Alert : waves have different x-scaling. Do you want to continue?"
		
		if (V_flag != 1)
			return ""
		endif
		
	endif
	
	items = ItemsInList(wList)
	
	NMProgressStr("Summing Waves...")
	
	for (wcnt = 0; wcnt < items; wcnt += 1)
		
		if (CallProgress(wcnt/(items-1)) == 1) // cancel
			wcnt = -1
			break
		endif
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		if (icnt == 0) // first wave
			Duplicate /O/R=(lftx,rghtx)  $wName U_Sum
		else
			Duplicate /O/R=(lftx,rghtx)  $wName U_waveCopy
			U_Sum += U_waveCopy
		endif
		
		icnt += 1
		
		outList = AddListItem(wName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	if (wcnt > 1)
		Setscale /P x lftx, dx, U_Sum
	endif
	
	xl = NMNoteLabel("x", wList, "")
	yl = NMNoteLabel("y", wList, "")
	
	NMNoteType("U_Sum", "NMSum", xl, yl, "Func:SumWaves")
	
	txt = "Wave List:" + ChangeListSep(wList, ",")
	
	Note U_Sum, txt
	
	KillWaves /Z U_waveCopy
	
	NMUtilityAlert("SumWaves", badList)
	
	return outList

End // SumWaves

//****************************************************************
//
//	DeleteNANs()
//	remove NANs in a wave
//
//****************************************************************

Function DeleteNANs(wList, yname, xflag)
	String wList // input wave names (Nan's are searched in first waves, same points deleted for all waves)
	String yname // output wave name
	Variable xflag // (0) no x wave (1) compute x wave
	
	Variable nwaves = ItemsInList(wList)
	String wName = StringFromList(0, wList)
	
	if (nwaves == 0)
		return -1
	endif
	
	if (WaveExists($wName) == 0)
		return -1
	endif
	
	WaveStats /Q $wname
	
	Variable numNans = V_numNaNs
	
	if (numNans == 0)
		return 0 // nothing to do
	endif
	
	String xname = yname + "_X"
	
	Duplicate /O $wname $yname, $xname
	
	Wave xwave = $xname
	Wave ywave = $yname
	
	xwave = x * (ywave / ywave)
	
	Sort xwave ywave, xwave
	
	WaveStats /Q xwave
	
	Redimension /N=(V_maxloc+1) xwave, ywave // eliminate NANs
	
	Note $xname, "Func:DeleteNANs"
	
	if (xflag == 0)
		KillWaves /Z $xname
	endif
	
	Note $yname, "Func:DeleteNANs"
	
	return 0

End // DeleteNANs

//****************************************************************
//****************************************************************
//****************************************************************

Function CopyWaveValues(fromFolder, toFolder, wList, fromOffset, toOffset)
	String fromFolder
	String toFolder
	String wList
	Variable fromOffset
	Variable toOffset
	
	Variable wcnt, icnt, jcnt, error = 0
	String wName
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
		
		wName = StringFromList(wcnt, wList)
		
		if ((WaveExists($(fromFolder + wName)) == 0) || (WaveExists($(toFolder + wName)) == 0))
			error = -1
			continue
		endif
		
		Wave wtemp1 = $(fromFolder + wName)
		Wave wtemp2 = $(toFolder + wName)
		
		jcnt = toOffset
		
		for (icnt = fromOffset; icnt < numpnts(wtemp1); icnt += 1)
			if (jcnt < numpnts(wtemp2))
				wtemp2[jcnt] = wtemp1[icnt]
				jcnt += 1
			endif
		endfor
		
	endfor
	
	return error

End // CopyWaveValues

//****************************************************************
//****************************************************************
//****************************************************************

Function BinAndAverage(xWave, yWave, xbgn, xbin)
	String xWave // x-wave name, ("") enter null-string to use x-scale of y-wave
	String yWave // y-wave name
	Variable xbgn // beginning xvalue
	Variable xbin // bin size
	
	Variable x0 = xbgn, x1 = x0 + xbin
	Variable sumy, count, nbins, icnt, jcnt, savex
	
	String yOut = yWave + "_binned"
	
	if (numtype(x0 * x1) > 0)
		return -1
	endif
	
	If (WaveExists($yWave) == 0)
		return -1
	endif
	
	If ((strlen(xWave) > 0) && (WaveExists($xWave) == 0))
		return -1
	endif
	
	if (strlen(xWave) == 0)
		Duplicate /O $yWave U_BinAvg_x
		Wave xtemp = U_BinAvg_x
		xtemp = x
	else
		Duplicate /O $xWave U_BinAvg_x
	endif
	
	Duplicate /O $yWave U_BinAvg_y
	
	Sort U_BinAvg_x U_BinAvg_y, U_BinAvg_x
	
	Wavestats /Q U_BinAvg_x
	
	nbins = ceil((V_max - xbgn) / xbin)
	
	Make /O/N=(nbins) $yOut
	Wave outy = $yOut
	
	Setscale /P x xbgn, xbin, outy
	
	for (icnt = 0; icnt < nbins; icnt += 1)
	
		sumy = 0
		count = 0
	
		for (jcnt = 0; jcnt < numpnts(U_BinAvg_x); jcnt += 1)
			if ((U_BinAvg_x[jcnt] > x0) && (U_BinAvg_x[jcnt] <= x1))
				sumy += U_BinAvg_y[jcnt]
				count += 1
			endif
		endfor
		
		outy[icnt] = sumy / count
		
		x0 += xbin
		x1 += xbin
		
	endfor
	
	KillWaves /Z U_BinAvg_x, U_BinAvg_y
	
End // BinAndAverage

//****************************************************************
//****************************************************************
//****************************************************************

Function BinaryCheck(n)
	Variable n
	
	if (n >= 1)
		return 1
	else
		return 0
	endif

End // BinaryCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function BinaryInvert(n)
	Variable n
	
	if (n == 1)
		return 0
	else
		return 1
	endif

End // BinaryInvert

//****************************************************************
//****************************************************************
//****************************************************************

Function Zero2Nan(n)
	Variable n
	
	if (n == 0)
		return Nan
	else
		return n
	endif
	
End // Zero2Nan

//****************************************************************
//****************************************************************
//****************************************************************

Function Nan2Zero(n)
	Variable n
	
	if (numtype(n) == 2)
		return 0
	else
		return n
	endif
	
End // Nan2Zero

//****************************************************************
//
//	NMFindOnset()
//	find onset time of when signal rises above baseline noise
//
//****************************************************************

Function NMFindOnset(wName, tbgn, tend, avgN, Nstdv, negpos, direction)
	String wName // wave name
	Variable tbgn, tend // search window (ms)
	Variable avgN // avg points
	Variable Nstdv // number of stdv's above baseline
	Variable negpos // (1) pos onset (-1) neg onset
	Variable direction // (1) forward search (-1) backward search
	
	Variable icnt, ibgn, iend, level
	
	if ((WaveExists($wName) == 0) || (abs(negpos) != 1))
		return Nan
	endif
	
	Wave eWave = $wName
	
	Variable dx = deltax(eWave)
	
	if (direction == 1)
	
		// search forward from tbgn until right-most data point falls above (Avg + N*Stdv), the baseline
	
		if (tbgn < leftx(eWave))
			tbgn = leftx(eWave)
		endif
		
		if (tend + avgN*dx >= rightx(eWave))
			tend = rightx(eWave) - AvgN*dx
		endif
		
		ibgn = x2pnt(eWave, tbgn)
		iend = x2pnt(eWave, tend) - AvgN
		
		if (ibgn >= iend)
			return Nan
		endif
	
		for (icnt = ibgn; icnt < iend; icnt += 1)
			
			WaveStats /Q/R=[icnt, icnt + avgN] eWave
			
			level = V_avg + Nstdv * V_sdev * negpos
	
			if ((negpos > 0) && (eWave[icnt+AvgN] >= level))
				return pnt2x(eWave, (icnt+AvgN))
			elseif ((negpos < 0) && (eWave[icnt+AvgN] <= level))
				return pnt2x(eWave, (icnt+AvgN))
			endif
	
		endfor
	
	elseif (direction == -1)
	
	// search backward from tend until right-most data point falls below (Avg + N*Stdv), the baseline
	
		if (tbgn - avgN*dx <= leftx(eWave))
			tbgn = leftx(eWave) + AvgN*dx
		endif
		
		if (tend > rightx(eWave))
			tend = rightx(eWave)
		endif
		
		ibgn = x2pnt(eWave, tbgn)
		iend = x2pnt(eWave, tend) //- AvgN
		
		if (ibgn >= iend)
			return Nan
		endif
	
		for (icnt = iend; icnt > ibgn; icnt -= 1)
		
			WaveStats /Q/R=[icnt - avgN, icnt] eWave
			
			level = V_avg + Nstdv * V_sdev * negpos
		
			if ((negpos > 0) && (eWave[icnt] <= level))
				return pnt2x(eWave, icnt)
			elseif ((negpos < 0) && (eWave[icnt] >= level))
				return pnt2x(eWave, icnt)
			endif
	
		endfor
	
	endif
	
	return Nan

End // NMFindOnset

//****************************************************************
//
//	NMFindPeak()
//	find time of peak y-value
//
//****************************************************************

Function NMFindPeak(wName, tbgn, tend, avgN, Nstdv, negpos)
	String wName // wave name
	Variable tbgn, tend // search window (ms)
	Variable avgN // avg points
	Variable Nstdv // number of stdv's above baseline
	Variable negpos // (1) pos peak (-1) neg peak

	Variable icnt, ibgn, iend, lbgn, level
	
	if ((WaveExists($wName) == 0) || (abs(negpos) != 1))
		return Nan
	endif
	
	Wave eWave = $wName
	
	Variable dx = deltax(eWave)
	
	if (tbgn < leftx(eWave))
		tbgn = leftx(eWave)
	endif
	
	if (tend > rightx(eWave))
		tend = rightx(eWave)
	endif
	
	ibgn = x2pnt(eWave, tbgn)
	iend = x2pnt(eWave, tend) - avgN
	lbgn = eWave[ibgn]
	
	if (ibgn >= iend)
		return Nan
	endif
	
	// search forward from tbgn until left-most data point resides above (Avg + N*Stdv)

	for (icnt = ibgn+1; icnt < iend; icnt += 1)
		
		WaveStats /Q/R=[icnt, icnt + avgN] eWave
		
		level = V_avg + Nstdv * V_sdev * negpos
		
		if ((negpos > 0) && (V_avg > lbgn) && (eWave[icnt] >= level))
			return pnt2x(eWave, icnt)
		elseif ((negpos < 0) && (V_avg < lbgn) && (eWave[icnt] <= level))
			return pnt2x(eWave, icnt)
		endif
	
	endfor
	
	return Nan

End // NMFindPeak

//****************************************************************
//
//	FindStim()
//	find stimulus artifact times
//
//****************************************************************

Function FindStim(wName, tbin, conf)
	String wName // wave name
	Variable tbin // time bin size (e.g. 1 ms)
	Variable conf // % confidence from max value (e.g. 95)
	
	Variable tlimit = 0.1 // limit of stim width
	
	Variable absmax, absmin, icnt, jcnt
	
	if (NMUtilityWaveTest(wName) < 0)
		return -1
	endif
	
	if ((tbin < 0) || (conf <= 0) || (conf > 100) || (numtype(tbin*conf) != 0))
		return -1
	endif
	
	Duplicate /O $wName tempwave
	Differentiate tempwave
	WaveStats /Q tempwave
	
	absmax = abs(V_max - V_avg)
	absmin = abs(V_min - V_avg)
	
	if (absmax > absmin)
		Findlevels /Q tempwave, (V_avg + absmax*conf/100)
	else
		Findlevels /Q tempwave, (V_avg - absmin*conf/100)
	endif
	
	if (V_Levelsfound == 0)
		return -1
	endif
	
	Wave W_FindLevels
	
	Make /O/N=(V_Levelsfound/2) U_StimTimes
	
	for (icnt = 0; icnt < V_Levelsfound-1;icnt += 2)
		if (W_FindLevels[1] - W_FindLevels[0] <= tlimit)
			U_StimTimes[jcnt] = floor(W_FindLevels[icnt]/tbin) * tbin
			jcnt += 1
		endif
	endfor
	
	Note U_StimTimes, "Func:FindStim"
	Note U_StimTimes, "Source:" + wName
	
	KillWaves /Z tempwave, W_FindLevels
	
	return 0

End // FindStim

//****************************************************************
//
//	GetXStats()
//	compute x stats of a group of waves
//
//****************************************************************

Function GetXStats(select, wList)
	String select // select which value to pass back (see below)
	String wList // wave list
	
	// select options: "deltax", "numpnts", "minleftx", "maxrightx", "maxleftx", "minrightx"
	// note, if waves have different deltax or numpnts, this function returns Nan
	
	Variable wcnt, dumvar, dx = -1, pnts = -1
	Variable minmin = inf, maxmax = -inf, maxmin = -inf, minmax = inf
	String wName, badList = wList
	
	if (ItemsInList(wList) == 0)
		return Nan
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		wName = StringFromList(0, wName, ",") // in case of sub-list
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		 
		 dumvar = deltax($wName)
		 
		if (dx < 0)
			dx = dumvar // first wave
		elseif (abs(dumvar - dx) > 0.001)
			dx = Nan // waves have different deltax
		endif
		
		dumvar = numpnts($wName)
		
		if (pnts < 0)
			pnts = dumvar // first wave
		elseif (dumvar != pnts)
			pnts = Nan // waves have different numpnts
		endif
		
		dumvar = leftx($wName)
		
		if (dumvar < minmin)
			minmin = dumvar
		endif
		
		if (dumvar > maxmin)
			maxmin = dumvar
		endif
		
		dumvar = rightx($wName)
		
		if (dumvar > maxmax)
			maxmax = dumvar
		endif
		
		if (dumvar < minmax)
			minmax = dumvar
		endif
		
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	strswitch(select)
		case "deltax":
			return dx
		case "numpnts":
			return pnts
		case "minleftx":
			return minmin
		case "maxleftx":
			return maxmin
		case "maxrightx":
			return maxmax
		case "minrightx":
			return minmax
		default:
			return Nan
	endswitch

	NMUtilityAlert("GetXStats", badList)
	
End // GetXStats

//****************************************************************
//
//	WaveListStats()
//	compute stats of a list of waves
//	results returned in waves U_AmpX and U_AmpY
//	stats can be Max, Min, Avg or Slope.
//
//****************************************************************

Function WaveListStats(stat, tbgn, tend, wList)
	String stat // statistic to compute ("Max", "Min", "Avg" or "Slope")
	Variable tbgn // time window begin
	Variable tend // time window end
	String wList // wave list (seperator ";")
	
	String xl, yl, txt, wName, dumstr, badList = wList
	Variable wcnt, ampy, ampx, nwaves
	
	nwaves = ItemsInList(wList)
	
	if (nwaves == 0)
		return -1
	endif

	if ((tend <= tbgn) || (numtype(tbgn*tend) != 0))
		return -1
	endif
	
	Make /O/N=(nwaves) U_AmpX
	Make /O/N=(nwaves) U_AmpY
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		strswitch(stat)
		
			case "Max":
				WaveStats /Q/R=(tbgn, tend) $wName
				ampy = V_max
				ampx = V_maxloc
				break
				
			case "Min":
				WaveStats /Q/R=(tbgn, tend) $wName
				ampy = V_min
				ampx = V_minloc
				break
				
			case "Avg":
				WaveStats /Q/R=(tbgn, tend) $wName
				ampy = V_avg
				ampx = Nan
				break
				
			case "Slope":
				dumstr = FindSlope(tbgn, tend, wName) // function located in "Utility.ipf"
				ampy = str2num(StringByKey("b", dumstr, "="))
				ampx = str2num(StringByKey("m", dumstr, "="))
				break
				
			default:
				return -1
				
		endswitch
	
		U_AmpY[wcnt] = ampy
		U_AmpX[wcnt] = ampx
		
		badList = RemoveFromList(wName, badList)
	
	endfor
	
	xl = NMNoteLabel("x", wList, "")
	yl = NMNoteLabel("y", wList, "")
	
	NMNoteType("U_AmpX", "NMStatsX", xl, yl, "Func:WaveListStats")
	NMNoteType("U_AmpY", "NMStatsY", xl, yl, "Func:WaveListStats")
	
	txt = "Stats Alg:" + stat + ";Stats Tbgn:" + num2str(tbgn) + ";Stats Tend:" + num2str(tend) + ";"
	
	Note U_AmpX, txt
	Note U_AmpY, txt
	
	txt = "Wave List:" + ChangeListSep(wList, ",")
	
	Note U_AmpX, txt
	Note U_AmpY, txt
	
	NMUtilityAlert("WaveListStats", badList)
	
	return 0
	
End // WaveListStats

//****************************************************************
//
//	MeanStdv()
//	compute the mean and stdv of a list of waves.
//	results returned as a string list.
//
//****************************************************************

Function /S MeanStdv(tbgn, tend, wList)
	Variable tbgn // time window begin
	Variable tend // time window end
	String wList // wave list (seperator ";")
	
	String wName, badList = wList
	Variable wcnt, cnt, num, avg, stdv
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	if ((tend <= tbgn) || (numtype(tbgn*tend) != 0))
		return "" // bad time window
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		if (NMUtilityWaveTest(wName) < 0)
			continue
		endif
		
		Wave wv = $wName
		
		num = mean(wv, tbgn, tend)
		avg += num
		stdv += num*num
		cnt += 1
		
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	stdv = sqrt((stdv - ((avg^2)/cnt))/(cnt-1))
	avg = avg/cnt
	
	NMUtilityAlert("MeanStdv", badList)
	
	return "mean=" + num2str(avg) + ";stdv=" + num2str(stdv) + ";count=" + num2str(cnt)+";"

End // MeanStdv

//****************************************************************
//
//	ComputeWaveStats()
//	compute wave statistics
//	options: Max, Min, Avg, SDev, Var, RMS, Area, Slope, Level, Level+, Level-
//
//****************************************************************

Function ComputeWaveStats(wv, tbgn, tend, fxn, level)
	Wave wv // wave to measure
	Variable tbgn, tend // measure window times
	String fxn // function (Max, Min, Avg, SDev, Var, RMS, Area, Slope, Level, Level+, Level-, FWHM+, FWHM-)
	Variable level // level detection value
	
	String dumstr, wName = GetWavesDataFolder(wv, 2)
	
	Variable ax = Nan, ay = Nan
	
	strswitch(fxn)
			
		case "Max":
		case "RTSlope+":
		case "FWHM+":
		
			WaveStats /Q/R=(tbgn, tend) wv
			ay = V_max; ax = V_maxloc
			
			if (numtype(ax * ay) > 0)
				ax = Nan
				ay = Nan
			endif
			
			break
			
		case "Min":
		case "RTSlope-":
		case "FWHM-":
		
			WaveStats /Q/R=(tbgn, tend) wv
			ay = V_min; ax = V_minloc
			
			if (numtype(ax * ay) > 0)
				ax = Nan
				ay = Nan
			endif
			
			break
			
		case "Avg":
			WaveStats /Q/R=(tbgn, tend) wv
			ay = V_avg; ax = Nan
			break
			
		case "SDev":
			WaveStats /Q/R=(tbgn, tend) wv
			ay = V_sdev; ax = Nan
			break
			
		case "Var":
			WaveStats /Q/R=(tbgn, tend) wv
			ay = V_sdev*V_sdev; ax = Nan
			break
			
		case "RMS":
			WaveStats /Q/R=(tbgn, tend) wv
			ay = V_rms; ax = Nan
			break
			
		case "Area":
			ay = area(wv,tbgn, tend); ax = Nan
			break
			
		case "Sum":
			ay = sum(wv,tbgn, tend); ax = Nan
			break
			
		case "Slope":
		
			dumstr = FindSlope(tbgn, tend, wName)
			ax = str2num(StringByKey("b", dumstr, "="))
			ay = str2num(StringByKey("m", dumstr, "="))
			
			if (numtype(ax * ay) > 0)
				ax = Nan
				ay = Nan
			endif
			
			break
			
		case "Onset":
		
			dumstr = FindMaxCurvatures(tbgn, tend, wName)
			ax = str2num(StringByKey("t1", dumstr, "=")) // use the first time value
			
			if (numtype(ax) == 0)
				ay = wv[x2pnt(wv, ax)]
			endif
		
			break
			
		case "Level":
		
			ay = level
			FindLevel /Q/R=(tbgn, tend) wv, ay
			
			if (V_flag == 1)
				ax = Nan
			else
				ax = V_LevelX
			endif
			
			break
			
		case "Level+":
			ay = level
			ax = FindLevelPosNeg(tbgn, tend,ay, "+", wName)
			break
			
		case "Level-":
			ay = level
			ax = FindLevelPosNeg(tbgn, tend, ay, "-", wName)
			break	
			
	endswitch
	
	SetNMvar("U_ax", ax)
	SetNMvar("U_ay", ay)
	
	KillVariables /Z V_Flag
	
End // ComputeWaveStats

//****************************************************************
//
//	FindLevelPosNeg()
//	find level on positive or negative slope
//
//****************************************************************

Function FindLevelPosNeg(tbgn, tend, level, direction, wName)
	Variable tbgn // time window begin
	Variable tend // time window end
	Variable level // level to detect
	String direction // slope direction ("+" or "-")
	String wName // wave name
	
	String dumstr
	Variable t, dt, slope, stop, cnt, climit = 100
	Variable dtwin = 0.2 // window to compute slope over (ms)
	
	if (NMUtilityWaveTest(wName) < 0)
		return Nan
	endif
	
	if ((tbgn >= tend) || (numtype(level*tbgn*tend) != 0))
		return Nan
	endif
	
	t = Nan
	dt = deltax($wName)
	
	if (dtwin < dt)
		dtwin = 3 * dt
	endif
	
	do
	
		FindLevel /Q/R=(tbgn, tend) $wName, level
	
		if ((V_Flag == 1) || (numtype(V_LevelX) > 0))
			t = Nan
			break // no level crossings were found
		else
			t = V_LevelX
		endif
		
		dumstr = FindSlope(t - dtWin, t + dtWin, wName)
		slope = str2num(StringByKey("m", dumstr, "="))
	
		strswitch(direction)
			case "+":
				if (slope > 0)
					stop = 1
					break
				endif
				break
			case "-":
				if (slope < 0)
					stop = 1
					break
				endif
				break
			default:
				return Nan
		endswitch
		
		tbgn = t + dt
		cnt += 1
		
		if (cnt == climit)
			stop = 1 // computed 100 trials, nothing found
		endif
		
	while (stop == 0)
	
	return t

End // FindLevelPosNeg

//****************************************************************
//
//	FindSlope()
//	compute the slope of a wave. 
//	slope (m) and intercept (b) passed back as a string list.
//
//****************************************************************

Function /S FindSlope(tbgn, tend, wName)
	Variable tbgn // time window begin
	Variable tend // time window end
	String wName // wave name
	
	Variable m, b
	
	String rslts = ""
	
	if (NMUtilityWaveTest(wName) < 0)
		return "" // bad input wave
	endif
	
	if ((tbgn >= tend)|| (numtype(tbgn*tend) > 0))
		return "" // bad inputs
	endif
	
	WaveStats /Q/R=(tbgn, tend) $wName
	
	if (V_npnts <= 2)
		return ""
	endif
	
	Curvefit /Q/N line $wName (tbgn, tend)
	
	Wave W_Coef
	
	m = W_Coef[1]
	b = W_Coef[0]
	
	if (numtype(m * b) > 0)
		m = Nan
		b = Nan
	endif
	
	rslts = "m=" + num2str(m) + ";b=" + num2str(b)+";"
	
	KillWaves /Z W_coef, W_sigma
	
	return rslts // return slope (m) and intercept (b) as a string list

End // FindSlope

//****************************************************************
//
//	FindMaxCurvatures()
//	find maximum curvature by fitting sigmoidal function (Boltzmann equation) 
//     based on analysis of Fedchyshyn and Wang, J Physiol 2007 June, 581:581-602
//	returns three times t1, t2, t3, where max occurs
//
//****************************************************************

Function /S FindMaxCurvatures(tbgn, tend, wName)
	Variable tbgn // time window begin
	Variable tend // time window end
	String wName // wave name
	
	Variable tmid, tc, t1, t2, t3
	
	String rslts = ""
	
	if (NMUtilityWaveTest(wName) < 0)
		return "" // bad input wave
	endif
	
	if ((tbgn >= tend) || (numtype(tbgn*tend) > 0))
		return "" // bad inputs
	endif
	
	WaveStats /Q/R=(tbgn, tend) $wName
	
	if (V_npnts <= 2)
		return ""
	endif
	
	Curvefit /N/Q Sigmoid $wName (tbgn, tend)
	
	Wave W_Coef
	
	tmid = W_Coef[2]
	tc = W_Coef[3]
	
	if (numtype(tmid * tc) > 0)
		return ""
	endif
	
	t1 = tmid - ln(5 + 2 * sqrt(6)) * tc
	t2 = tmid
	t3 = tmid - ln(5 - 2 * sqrt(6)) * tc
	
	rslts = "t1=" + num2str(t1) + ";t2=" + num2str(t2) + ";t3=" + num2str(t3) + ";"
	
	KillWaves /Z W_coef, W_sigma
	
	return rslts

End // FindMaxCurvatures

//****************************************************************
//
//	SortWave()
//	sort successes ("true" values) of a wave, via one of six sorting algorithms
//
//****************************************************************

Function SortWave(sName, dName, method, xv, yv, nv)
	String sName // wave to sort
	String dName // destination sort wave, where 1's and 0's are stored
	Variable method // sorting method (see switch cases 1-6 below)
	Variable xv // x value
	Variable yv // y value
	Variable nv // n value
	
	Variable scnt
	String alg, xl, yl
	
	if ((WaveExists($sName) == 0) || (WaveType($sName) == 0))
		return -1
	endif
	
	Duplicate /O $sName $dName
	
	Wave wTemp = $sName
	Wave wSort = $dName
	
	wSort = 0
	
	switch(method)
	
		case 1:
		
			alg = "[a] > x"
			
			for (scnt = 0; scnt < numpnts(wTemp); scnt += 1)
				if (numtype(wTemp[scnt]) > 0)
					wSort[scnt] = Nan
				elseif (wTemp[scnt] > xv)
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		case 2:
		
			alg = "[a] > x - n*y"
			
			for (scnt = 0; scnt < numpnts(wTemp); scnt += 1)
				if (numtype(wTemp[scnt]) > 0)
					wSort[scnt] = Nan
				elseif (wTemp[scnt] > xv - (nv * yv))
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		case 3:
		
			alg = "[a] < x"
			
			print xv
			
			for (scnt = 0; scnt < numpnts(wTemp); scnt += 1)
				if (numtype(wTemp[scnt]) > 0)
					wSort[scnt] = Nan
				elseif (wTemp[scnt] < xv)
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		case 4:
		
			alg = "[a] < x + n*y"
			
			for (scnt = 0; scnt < numpnts(wTemp); scnt += 1)
				if (numtype(wTemp[scnt]) > 0)
					wSort[scnt] = Nan
				elseif (wTemp[scnt] < xv + (nv * yv))
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		case 5:
		
			alg = "x < [a] < y"
			
			for (scnt = 0; scnt < numpnts(wTemp); scnt += 1)
				if (numtype(wTemp[scnt]) > 0)
					wSort[scnt] = Nan
				elseif ((wTemp[scnt] > xv) && (wTemp[scnt] < yv))
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		case 6:
		
			alg = "x - n*y < [a] < x + n*y"
			
			for (scnt = 0; scnt < numpnts(wTemp); scnt += 1)
				if (numtype(wTemp[scnt]) > 0)
					wSort[scnt] = Nan
				elseif ((wTemp[scnt] > xv - (nv * yv)) && (wTemp[scnt] < xv + (nv * yv)))
					wSort[scnt] = 1
				else
					wSort[scnt] = 0
				endif
			endfor
			
			break
			
		default:
			wSort = Nan
			return -1
			
	endswitch
	
	xl = NMNoteLabel("x", sName, "")
	yl = "True (1) / False (0)"
	
	NMNoteType(dName, "NMSet", xl, yl, "Func:SortWave")
	
	Note wSort, "Sort Wave:" + sName
	Note wSort, "Sort Alg:" +alg + ";Sort xValue:" + num2str(xv) + ";Sort yValue:" + num2str(yv)+ ";Sort nValue:" + num2str(nv) + ";"
	
	return sum(wSort,0,inf) // return number of successes

End // SortWave

//****************************************************************
//
//	NextWaveItem()
//	find next occurence of number within a wave
//
//****************************************************************

Function NextWaveItem(wName, item, from, direction) // find next item in wave
	String wName // wave name
	Variable item // item number to find
	Variable from // start point number
	Variable direction // +1 forward; -1 backward
	
	Variable wcnt, wlmt, next, found, npnts, inc = 1

	if  ((WaveExists($wName) == 0)  || (WaveType($wName) == 0))
		return from
	endif
	
	Wave tWave = $wName
	npnts = numpnts(tWave)
	
	if (direction < 0)
		next = from - 1
		inc = -1
		wlmt = next + 1
	else
		next =from + 1
		wlmt = npnts - from
	endif
	
	if  ((next > npnts - 1) || (next < 0))
		return from // next out of bounds
	endif
	
	found = from
	
	for (wcnt = 0; wcnt < wlmt; wcnt += 1)
		if (tWave[next] == item)
			found = next
			break
		endif
		next += inc
	endfor
	
	return  found

End // NextWaveItem

//****************************************************************
//****************************************************************
//****************************************************************

Function WaveSequence(wName, seqStr, fromWave, toWave, blocks)
	String wName // wave name
	String seqStr // seq string "0;1;2;3;" or "0,3" for range
	Variable fromWave // starting wave number
	Variable toWave
	Variable blocks // number of blocks in each group
	
	Variable index, last, icnt, jcnt
	
	if (WaveExists($wName) == 0)
		return -1
	endif
	
	if (strsearch(seqStr, ",", 0) > 0)
	
		if (ItemsInList(seqStr, ",") != 2)
			return -1
		endif
		
		index = str2num(StringFromList(0, seqStr, ","))
		last = str2num(StringFromList(1, seqStr, ","))
		seqStr = ""
		
		for (icnt = index; icnt <= last; icnt += 1)
			seqStr = AddListItem(num2str(icnt), seqStr, ";", inf)
		endfor
		
	endif
	
	if (ItemsInList(seqStr) == 0)
		return -1
	endif
	
	Wave wTemp = $wName
		
	index = fromWave
	
	toWave = Min(toWave, numpnts(wTemp)-1)
	
	for (icnt = fromWave; icnt <= toWave; icnt += blocks)
	
		wTemp[icnt,icnt+blocks-1] = str2num(StringFromList(jcnt,seqStr))
		
		jcnt += 1
		
		if (jcnt >= ItemsInList(seqStr))
			jcnt = 0
		endif
		
	endfor

End // WaveSequence

//****************************************************************
//****************************************************************
//****************************************************************

Function WaveCountOnes(wname)
	String wname

	return WaveCountValue(wname, 1)

End // WaveCountOnes

//****************************************************************
//****************************************************************
//****************************************************************

Function WaveCountValue(wname, valueToCount)
	String wname
	Variable valueToCount // value to count, or (inf) all positive numbers (-inf) all negative numbers
	
	Variable icnt, count

	if (WaveExists($wname) == 0)
		return Nan
	endif
	
	Wave wtemp = $wname
	
	for (icnt = 0; icnt < numpnts(wtemp); icnt += 1)
	
		if (numtype(valueToCount) == 0)
		
			if (wtemp[icnt] == valueToCount)
				count += 1
			endif
		
		elseif (valueToCount == inf)
		
			if (wtemp[icnt] > 0)
				count += 1
			endif
		
		elseif (valueToCount == -inf)
		
			if (wtemp[icnt] < 0)
				count += 1
			endif
			
		endif
		
	endfor
	
	return count

End // WaveCountValue

//****************************************************************
//****************************************************************
//****************************************************************

Function Time2Intervals(wname, tMin, tMax, iMin, iMax) // compute inter-time intervals
	String wname // wname of time values
	Variable tMin, tMax // time window
	Variable iMin, iMax // min, max allowed interval
	
	Variable isi, ecnt, icnt, event, last
	String xl, yl
	
	if ((exists(wname) == 0) || (numpnts($wname) == 0) || (iMin >= iMax))
		return Nan // bad inputs
	endif
	
	Wave wtemp = $wname

	Duplicate /O $wname U_INTVLS
	
	U_INTVLS = Nan
	
	for (ecnt = 1; ecnt < numpnts(wtemp); ecnt += 1)
	
		last = wtemp[ecnt - 1]
		event = wtemp[ecnt]
		
		if ((numtype(last) > 0) || (numtype(event) > 0))
			continue
		endif
		
		if ((event >= tMin) && (event <= tMax) && (event > last))
		
			isi = event - last
			
			if ((isi >= iMin) && (isi <= iMax))
				U_INTVLS[ecnt] = isi
				icnt += 1
			endif
			
		endif
		
	endfor
	
	xl = NMNoteLabel("x", wname, "")
	yl = NMNoteLabel("y", wname, "msec")
	
	NMNoteType("U_INTVLS", "NMIntervals", xl, yl, "Func:Time2Intervals")
	
	Note U_INTVLS, "Interval Source:" + wname
	
	return icnt

End // Time2Intervals

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Event2Wave(rwave, ewave, before, after, stopAtNextEvent, chan, prefix) // save events to waves
	String rwave // wave of record numbers
	String ewave // wave of event times
	Variable before, after // save time before, after event time
	Variable stopAtNextEvent // (< 0) no (>= 0) yes...  if greater than zero, use value to limit time before next event
	Variable chan // channel number
	String prefix // prefix name
	
	Variable icnt, jcnt, tbgn, tend, npnts, event, wnum, continuous, dx, intvl
	String xl, yl, wName1, wName2, wName3, lastWave, nextWave, wlist = ""
	
	if (numpnts($rwave) != numpnts($ewave))
		return ""
	endif
	
	Wave recordNum = $rwave
	Wave eventTimes = $ewave
	
	npnts = numpnts(recordNum)
	
	wName3 = prefix + "Times"
	
	Make /O/N=(npnts) $wName3 = Nan
	
	Wave st = $wName3
	
	for (icnt = 0; icnt < npnts; icnt += 1)
	
		wnum = recordNum[icnt]
		wName1 = ChanWaveName(chan, wnum) // source wave, raw data
		nextWave = ChanWaveName(chan, wnum+1)
		
		if (wnum == 0)
			lastWave = ""
		else
			lastWave = ChanWaveName(chan, wnum-1) 
		endif
		
		continuous = 0
		
		if (WaveExists($wName1) == 0)
			continue
		endif
		
		xl = NMNoteLabel("x", wName1, "msec")
		yl = NMNoteLabel("y", wName1, "")
		
		event = eventTimes[icnt]
		
		if (icnt < npnts - 1)
			intvl = eventTimes[icnt+1] - eventTimes[icnt]
		else
			intvl = Nan
		endif
		
		if (numtype(event) > 0)
			continue
		endif
		
		tbgn = event - before
		tend = event + after
		
		if (tbgn < leftx($wName1))
			if ((WaveExists($lastWave) == 1) && (tbgn >= leftx($lastWave)) && (tbgn <= rightx($lastWave))) // continuous
				continuous = 1
			else
				Print "Event " + num2str(icnt) + " out of range on left:" + wName1
				continue
			endif
		endif
		
		if (tend > rightx($wName1))
			if ((WaveExists($nextWave) == 1) && (tend >= leftx($nextWave)) && (tend <= rightx($nextWave))) // continuous
				continuous = 2
			else
				Print "Event " + num2str(icnt) + " out of range on right:" + wName1
				continue
			endif
		endif
		
		wName2 = GetWaveName(prefix + "_", chan, icnt)
		
		dx = deltax($wName1)
		
		switch (continuous)
		
			case 1:
				Duplicate /O/R=(tbgn,rightx($lastWave)) $lastWave $(wName2 + "_last")
				Duplicate /O/R=(leftx($wName1),tend) $wName1 $wName2
				Wave w1 = $(wName2 + "_last")
				Wave w2 = $wName2
				Concatenate /KILL/NP/O {w1, w2}, U_EventConcat
				Duplicate /O U_EventConcat, $wName2
				KillWaves /Z U_EventConcat
				break
				
			case 2:
				Duplicate /O/R=(tbgn,rightx($wName1)) $wName1 $wName2
				Duplicate /O/R=(leftx($nextWave),tend) $nextWave $(wName2 + "_next")
				Wave w1 = $wName2
				Wave w2 = $(wName2 + "_next")
				Concatenate /KILL/NP/O {w1, w2}, U_EventConcat
				Duplicate /O U_EventConcat, $wName2
				KillWaves /Z U_EventConcat
				break
				
			default:
				Duplicate /O/R=(tbgn,tend) $wName1 $wName2
			
		endswitch
		
		Setscale /P x 0, dx, $wName2
		
		if ((stopAtNextEvent >= 0) && (numtype(intvl) == 0) && (before + intvl - stopAtNextEvent < tend))
			Wave wtemp = $wName2
			tbgn = before + intvl - stopAtNextEvent
			wtemp[x2pnt(wtemp, tbgn), inf] = Nan
		endif
		
		NMNoteType(wName2, "Event", xl, yl, "Func:Event2Wave")
		Note $wName2, "Event Source:" + wName1 + ";Event Time:" + Num2StrLong(event, 3) + ";"
		
		st[jcnt] = event
		
		jcnt += 1
	
		wlist = AddListItem(wName2, wlist, ";", inf)
		
	endfor
	
	if (jcnt == 0) 
		KillWaves /Z st
	else
		Redimension /N=(jcnt) st
	endif
	
	NMPrefixAdd(prefix + "_")
	
	return wlist

End // Event2Wave

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Display graph functions defined below...
//
//****************************************************************
//****************************************************************
//****************************************************************

//****************************************************************
//
//	CheckGraphName()
//	check graph name is correct format
//
//****************************************************************

Function /S CheckGraphName(gName)
	String gName
	
	Variable icnt
	
	for (icnt = 0; icnt < strlen(gName); icnt += 1)
	
		strswitch(gName[icnt,icnt])
			case ":":
			case ";":
			case ",":
			case ".":
			case " ":
				gName[icnt,icnt] = "_"
		endswitch
	endfor
	
	return gName[0,30]

End // GetGraphName

//****************************************************************
//
//	GetGraphName()
//	return graph name string, given prefix and chanNum
//
//****************************************************************

Function /S GetGraphName(prefix, chanNum)
	String prefix
	Variable chanNum
	
	return CheckGraphName(prefix + ChanNum2Char(chanNum))

End // GetGraphName

//****************************************************************
//
//	NextGraphName()
//	return next graph name in a sequence, given prefix and channel number
//
//****************************************************************

Function /S NextGraphName(prefix, chanNum, overwrite)
	String prefix // graph name prefix
	Variable chanNum // channel number (pass -1 for none)
	Variable overwrite // overwrite flag: (1) return last name in sequence (0) return next name in sequence
	
	Variable count
	String gName
	
	for (count = 0; count <= 99; count += 1) // search thru sequence numbers
	
		if (chanNum == -1)
			gName = prefix + num2str(count)
		else
			gName = prefix + ChanNum2Char(chanNum) + num2str(count)
		endif
		
		if (WinType(gName) == 0)
			break // found name not in use
		endif
		
	endfor
	
	if ((overwrite == 0) || (count == 0))
		return CheckGraphName(gName)
	elseif (chanNum < 0)
		return CheckGraphName(prefix + num2str(count-1))
	else
		return CheckGraphName(prefix + ChanNum2Char(chanNum) + num2str(count-1))
	endif

End // NextGraphName

//****************************************************************
//
//	SetGraphWaveColor()
//	change color of waves to raindow
//
//****************************************************************

Function GraphRainbow(gName)
	String gName // graph name
	
	if (Wintype(gName) == 0)
		return -1
	endif
	
	Variable wcnt, inc =  800, cmax = 65280, cvalue
	String wname
	
	String wList = TraceNameList(gName, ";", 1)

	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
		wname = StringFromList(wcnt, wList)
		
		cvalue -= trunc(wcnt/6) * inc
		
		if (cvalue <= 3000)
			cvalue = cmax
		endif
		
		switch (mod(wcnt,6))
			case 0: // red
				ModifyGraph /W=$gName rgb($wname)=(cvalue,0,0)
				break
			case 1: // green
				ModifyGraph /W=$gName rgb($wname)=(0,cvalue,0)
				break
			case 2: // blue
				ModifyGraph /W=$gName rgb($wname)=(0,0,cvalue)
				break
			case 3: // yellow
				cvalue = min(cvalue, 50000)
				ModifyGraph /W=$gName rgb($wname)=(cvalue,cvalue,0)
				break
			case 4: // turqoise
				ModifyGraph /W=$gName rgb($wname)=(0,cvalue,cvalue)
				break
			case 5: // purple
				ModifyGraph /W=$gName rgb($wname)=(cvalue,0,cvalue)
				break
		endswitch
		
	endfor
	
End // GraphRaindow

//****************************************************************
//
//	PrintMarqueeCoords()
//
//****************************************************************

Function PrintMarqueeCoords() : GraphMarquee

	GetMarquee left, bottom
	
	if (V_Flag == 0)
		Print "There is no marquee"
	else
		printf "marquee left : %g\r", V_left
		printf "marquee right: %g\r", V_right
		printf "marquee top: %g\r", V_top
		printf "marquee bottom: %g\r", V_bottom
	endif
	
End // PrintMarqueeCoords()

//****************************************************************
//****************************************************************
//****************************************************************
//
//	String functions defined below...
//
//****************************************************************
//****************************************************************
//****************************************************************

//****************************************************************
//
//	Num2StrLong()
//
//****************************************************************

Function /S Num2StrLong(num, decimals)
	Variable num, decimals
	
	String ttl
	
	sprintf ttl, "%." + num2str(decimals) + "f", num
	
	return ttl
	
End // RemoveStrEndSpace

//****************************************************************
//
//	RemoveStrEndSpace()
//	remove spaces at end of string
//
//****************************************************************

Function /S RemoveStrEndSpace(istring)
	String istring
	Variable icnt
	
	for (icnt = strlen(istring) - 1; icnt >= 0; icnt -= 1)
		if (StringMatch(istring[icnt,icnt], " ") == 0)
			break
		endif
	endfor

	return istring[0,icnt]

End // RemoveStrEndSpace

//****************************************************************
//
//	StrQuotes()
//	add string quotes "" around string
//
//****************************************************************

Function /S StrQuotes(istring)
	String istring

	return "\"" + istring + "\""

End // StrQuotes

//****************************************************************
//
//	StringReplace()
//	replace a string in a string expression
//
//****************************************************************

Function /S StringReplace(str, findstr, repstr)
	String str // string expression
	String findstr // search string
	String repstr // replace string
	
	Variable icnt
	String pname = ""
	
	//do
	
		icnt = strsearch(UpperStr(str),UpperStr(findstr),0)
		
		if (icnt == 0)
			pname = ""
		elseif (icnt > 0)
			pname = str[0,icnt-1]
		else
			return str
		endif
	
		str = pname + repstr + str[icnt+strlen(findstr),inf]
	
	//while (1)
	
	return str

End // StringReplace

//****************************************************************
//
//	NMStringReplace()
//	replace a string in a string expression
//
//****************************************************************

Function /S NMReplaceChar(findchar, str, repchar)
	String findchar // search char
	String str // string expression
	String repchar // replace char
	
	Variable icnt
	
	for (icnt = 0; icnt < strlen(str); icnt += 1)
		if (StringMatch(str[icnt,icnt], findchar) == 1)
			str[icnt,icnt] = repchar
		endif
	endfor
	
	return str

End // NMReplaceChar

//****************************************************************
//
//	StrSearchLax()
//
//****************************************************************

Function StrSearchLax(str, searchStr, start)
	String str
	String searchStr
	Variable start 
	
	return strsearch(UpperStr(str), UpperStr(searchStr), start)

End // StrSearchLax

//****************************************************************
//
//	GetNumFromStr()
//	find number following a string value
//
//****************************************************************

Function GetNumFromStr(str, findStr)
	String str // string to search
	String findStr // string to find (e.g. "marker(x)=")
	
	Variable icnt, ibgn
	
	ibgn = strsearch(str, findStr, 0)
	
	if (ibgn < 0)
		return Nan
	endif
	
	for (icnt = ibgn+strlen(findStr); icnt < strlen(str); icnt += 1)
		if (numtype(str2num(str[icnt])) == 0)
			ibgn = icnt
			break
		endif
	endfor
	
	for (icnt = ibgn; icnt < strlen(str); icnt += 1)
		if (numtype(str2num(str[icnt])) > 0)
			break
		endif
	endfor
	
	return str2num(str[ibgn,icnt-1])

End // GetNumFromStr

//****************************************************************
//
//	UnitsFromStr()
//	find units string from label string
//	units should be in parenthesis, i.e. "Vmem (mV)"
//	or seperated by space, i.e. "Vmem mV"
//
//****************************************************************

Function /S UnitsFromStr(str)
	String str // string to search
	
	Variable icnt, jcnt
	String units = ""
	
	for (icnt = strlen(str)-1; icnt >= 0; icnt -= 1)
	
		if (StringMatch(str[icnt], ")") == 1)
		
			for (jcnt = icnt-1; jcnt >= 0; jcnt -= 1)
				if (StringMatch(str[jcnt, jcnt], "(") == 1)
					return str[jcnt+1, icnt-1]
				endif
			endfor
			
		endif
		
		if (strlen(units) > 0)
			break
		endif
		
		strswitch(str[icnt, icnt])
			case " ":
			case ":":
				return str[icnt+1, inf]
		endswitch
		
	endfor
	
	return str
	
End // UnitsFromStr

//****************************************************************
//
//	OhmsUnitsFromStr()
//	find units string from axis label string
//
//****************************************************************

Function /S OhmsUnitsFromStr(str)
	String str // string to search
	
	return CheckOhmsUnits(UnitsFromStr(str))
	
End // OhmsUnitsFromStr

//****************************************************************
//
//	CheckOhmsUnits()
//
//****************************************************************

Function /S CheckOhmsUnits(units)
	String units
	
	strswitch(units)
		case "V":
		case "mV":
		case "A":
		case "nA":
		case "pA":
		case "S":
		case "nS":
		case "pS":
		case "Ohms":
		case "MOhms":
		case "MegaOhms":
		case "GOhms":
		case "GigaOhms":
		case "sec":
		case "msec":
		case "ms":
		case "usec":
		case "us":
			break
		default:
			units = ""
	endswitch
	
	return units

End // CheckOhmsUnits

//****************************************************************
//
//	RemoveListFromList()
//	remove sublist from list
//
//****************************************************************

Function /S RemoveListFromList(itemList, listStr, listSepStr)
	String itemList, listStr, listSepStr
	Variable icnt
	
	for (icnt = 0; icnt < ItemsInList(itemList, listSepStr); icnt += 1)
		listStr = RemoveFromList(StringFromList(icnt, itemList, listSepStr), listStr, listSepStr)
	endfor

	return listStr

End // RemoveListFromList

//****************************************************************
//
//	ListReverse()
//	reverse string list
//
//****************************************************************

Function /S ReverseList(listStr, listSepStr)
	String listStr, listSepStr
	
	Variable icnt
	String item, outList = ""
	
	for (icnt = ItemsInList(listStr, listSepStr)-1; icnt >= 0 ; icnt -= 1)
		item = StringFromList(icnt, listStr, listSepStr)
		outList = AddListItem(item, outList, listSepStr, inf)
	endfor

	return outList

End // ReverseList

//****************************************************************
//
//	GetListItems()
//	get items from list that match matchstr
//	CASE INSENSITIVE
//
//****************************************************************

Function /S GetListItems(matchstr, listStr, listSepStr)
	String matchstr // match string expression (i.e. "test*")
	String listStr // list string
	String listSepStr // ";" or ","
	
	Variable icnt
	String objName, rlist = ""

	for (icnt = 0; icnt < ItemsInList(listStr, listSepStr); icnt += 1)
	
		objName = StringFromList(icnt, listStr, listSepStr)
		
		if (stringmatch(objName, matchstr) == 1)
			rlist = AddListItem(objName, rlist, ";", inf)
		endif
		
	endfor
	
	return rlist

End // GetListItems

//****************************************************************
//
//	SortListLax()
//	Sort a list CASE INSENSITIVE
//
//****************************************************************

Function /S SortListLax(listStr, listSepStr)
	String listStr // list string
	String listSepStr // ";" or ","
	
	Variable icnt, item
	String objName, caplist = "", outList = ""
	
	caplist = SortList(UpperStr(listStr))
	
	for (icnt = 0; icnt < ItemsInList(caplist, listSepStr); icnt += 1)
	
		objName = StringFromList(icnt, caplist, listSepStr)
		item = WhichListItem(objName, UpperStr(listStr), listSepStr)
		objName = StringFromList(item, listStr, listSepStr)
		outList = AddListItem(objName, outList, listSepStr, inf)
	
	endfor
	
	return outList
	
End // SortListLax

//****************************************************************
//
//	SortListAlphaNum()
//	Sort a list alpha-numerically
//	can be replaced by SortList(wList, ";", 16)
//
//****************************************************************

Function /S SortListAlphaNum(list, prefix)
	String list
	String prefix
	
	Variable icnt, jcnt, jbgn, jend, npnts = ItemsInList(list)
	String item, rlist = ""
	
	if (npnts <= 0)
		return ""
	endif
	
	Make /T/O/N=(npnts) MN_ItemWaveTemp = ""
	Make /O/N=(npnts) MN_ItemNumTemp = Nan
	
	for (icnt = 0; icnt < npnts; icnt += 1)
	
		item = StringFromList(icnt, list)
		jbgn = strsearch(item, prefix, 0)
		
		if (jbgn < 0)
			jbgn = 0
		else
			jbgn += strlen(prefix)
		endif
		
		for (jcnt = jbgn; jcnt < strlen(item); jcnt += 1)
			if (numtype(str2num(item[jcnt,jcnt])) == 0)
				break // found start of sequence number
			endif
		endfor
		
		jbgn = jcnt
		
		for (jcnt = jbgn; jcnt < strlen(item); jcnt += 1)
			if (numtype(str2num(item[jcnt,jcnt])) > 0)
				break // found end of sequence number
			endif
		endfor
		
		jend = jcnt - 1
		
		MN_ItemWaveTemp[icnt] = item
		MN_ItemNumTemp[icnt] = str2num(item[jbgn,jend])
		
	endfor
	
	Sort MN_ItemNumTemp, MN_ItemNumTemp, MN_ItemWaveTemp
	
	rlist = ""
	
	for (icnt = 0; icnt < npnts; icnt += 1)
		item = MN_ItemWaveTemp[icnt]
		if (strlen(item) > 0)
			rlist = AddListItem(item, rlist, ";", inf)
		endif
	endfor
	
	KillWaves /Z MN_ItemNumTemp, MN_ItemWaveTemp
	
	return rlist

End // SortListAlphaNum

//****************************************************************
//
//	WhichListItemLax()
//	WhichListItem() CASE INSENSITIVE
//
//****************************************************************

Function WhichListItemLax(itemStr, listStr, listSepStr)
	String itemStr, listStr, listSepStr
	
	return WhichListItem(UpperStr(itemStr), UpperStr(listStr), listSepStr)
	
End // WhichListItemLax

//****************************************************************
//
//	ChangeListSep()
//	change listSepStr (e.g. "," to ";" or visa versa)
//
//****************************************************************

Function /S ChangeListSep(strList, listSepStr)
	String strList
	String listSepStr
	
	Variable icnt
	String str, sepstr, outList = ""
	
	if (ItemsInList(strList, ",") > 1)
		sepstr = ","
	elseif (ItemsInList(strList, ";") > 1)
		sepstr = ";"
	else
		return strList
	endif
	
	for (icnt = 0; icnt < ItemsInList(strList, sepstr); icnt += 1)
		outList = AddListItem(StringFromList(icnt, strList, sepstr), outList, listSepStr, inf)
	endfor
	
	return outList
	
End // ChangeListSep

//****************************************************************
//
//	ChangeListSep()
//	change listSepStr (e.g. "," to ";" or visa versa)
//
//****************************************************************

Function /S MatchStrList(strList, matchStr)
	String strList
	String matchStr
	
	Variable icnt
	String item, outList = ""
	
	for (icnt = 0; icnt < ItemsInList(strList); icnt += 1)
	
		item = StringFromList(icnt, strList)
		
		if (stringmatch(item, matchStr) == 1)
			outList = AddListItem(item, outList, ";", inf)
		endif
		
	endfor
	
	return outList
	
End // MatchStrList

//****************************************************************
//
//
//
//****************************************************************

Function IgorVersion()

	return NumberByKey("IGORVERS", IgorInfo(0))

End // IgorVersion

//****************************************************************
//
//	Igor-timed clock functions
//
//****************************************************************

Function NMwait(t)
	Variable t
	
	if (IgorVersion() >= 5)
		return NMwaitMSTimer(t)
	else
		return NMwaitTicks(t)
	endif
	
End // NMwait

//****************************************************************
//
//
//
//****************************************************************

Function NMwaitTicks(t) // wait t msec (only accurate to 17 msec)
	Variable t
	
	if (t == 0)
		return 0
	endif
	
	Variable t0 = ticks
	
	t *= 60 / 1000

	do
	while (ticks - t0 < t )
	
	return 0
	
End // NMwaitTicks

//****************************************************************
//
//
//
//****************************************************************

Function NMwaitMSTimer(t) // wait t msec (this is more accurate)
	Variable t
	
	if (t == 0)
		return 0
	endif
	
	Variable t0 = stopMSTimer(-2)
	
	t *= 1000 // convert to usec
	
	do
	while (stopMSTimer(-2) - t0 < t )
	
	return 0
	
End // NMwaitMSTimer

//****************************************************************
//
//
//
//****************************************************************

