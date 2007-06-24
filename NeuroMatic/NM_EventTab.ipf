#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.98

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spontaneous Event Detection
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last modified 25 Dec 2006
//
//	NM tab entry "Event"
//
//	Spontaneous event detection
//	Threshold search algorithm based on Kudoh and Taguchi,
//	Biosensors and Bioelectronics 17, 2002, pp. 773 - 782
//	"A simple exploratory algorithm for accurate detection of 
//	spontaneous synaptic events"
//
//	Template-Matching Algorithm by Clements and Bekkers,
//	Biophysical Journal, 1997, pp. 220-229
//	"Detection of spontaneous synaptic events with an
//	optimally scaled template"
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventPrefix(objName) // tab prefix identifier
	String objName
	
	return "EV_" + objName
	
End // EventPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventDF() // package full-path folder name

	return PackDF("Event")
	
End // EventDF

//****************************************************************
//****************************************************************
//****************************************************************

Function Event(enable) // enable/disable Event Tab
	Variable enable // (1) enable (0) disable

	if (enable == 1)
		CheckPackage("Event", 0) // create globals if necessary
		MakeEventTab(0) // create controls if necessary
		UpdateEventDisplay()
		UpdateEventTab()
		MatchTemplateCall(0)
	endif
	
	if (DataFolderExists(EventDF()) == 0)
		return 0 // Event Tab not created yet
	endif
	
	EventDisplay(enable)
	EventCursors(enable)

End // Event

//****************************************************************
//****************************************************************
//****************************************************************

Function KillEvent(what)
	String what
	String df = EventDF()
	
	strswitch(what)
		case "waves":
			break
		case "globals":
			if (DataFolderExists(df) == 1)
				KillDataFolder $df
			endif 
			break
	endswitch

End // KillEvent

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckEvent()
	
	String df = EventDF()
	
	if (DataFolderExists(df) == 0)
		return -1
	endif
	
	CheckNMvar(df+"SearchMethod", 3)			// (1) level+ (2) level- (3) threshold+ (4) threshold-
	CheckNMvar(df+"Thrshld", 3)					// threshold crossing value
	
	CheckNMvar(df+"DsplyWin", 50)				// display window size (ms)
	
	CheckNMvar(df+"SearchFlag", 0)				// (0) all time (1) limited time window
	CheckNMvar(df+"SearchBgn", -inf)				// seach time window begin
	CheckNMvar(df+"SearchEnd", inf)				// search time window end
	CheckNMvar(df+"SearchTime", 0)				// current search time
	
	CheckNMvar(df+"BaseFlag", 0)					// baseline flag
	CheckNMvar(df+"BaseWin", 2)					// baseline avg window (ms)
	CheckNMvar(df+"BaseDT", 2)					// time between mid-baseline and thresh crossing (ms)
	
	CheckNMvar(df+"ThreshX", Nan)
	CheckNMvar(df+"ThreshY", Nan)				// threshold/level x-y points
	
	CheckNMvar(df+"MatchFlag", 0)				// match template flag
	CheckNMvar(df+"MatchTau1", 2)				// template time constant
	CheckNMvar(df+"MatchTau2", 3)				// template time constant
	CheckNMvar(df+"MatchBsln", Nan)				// baseline (ms)
	CheckNMvar(df+"MatchWform", 8)				// waveform length (ms)
	
	CheckNMstr(df+"Template", "")					// template wave name
	
	CheckNMvar(df+"OnsetFlag", 1)				// onset search flag
	CheckNMvar(df+"OnsetWin", 2)				// limit of onset search (ms)
	CheckNMvar(df+"OnsetAvg", 1)					// average window for onset search
	CheckNMvar(df+"OnsetNstdv", 1)				// number of stdvs below avg
	CheckNMvar(df+"OnsetY", 0)
	CheckNMvar(df+"OnsetX", 0)					// onset time point
	
	CheckNMvar(df+"PeakFlag", 1)					// peak search flag
	CheckNMvar(df+"PeakWin", 5)					// limit of peak search (ms)
	CheckNMvar(df+"PeakAvg", 1)					// average window for peak search
	CheckNMvar(df+"PeakNstdv", 1)				// number of stdvs above avg
	CheckNMvar(df+"PeakY", 0)
	CheckNMvar(df+"PeakX", 0)					// peak time point
	
	CheckNMvar(df+"EventNum", 0)				// current event number
	CheckNMvar(df+"NumEvents", 0)				// number of saved events
	CheckNMvar(df+"TableNum", -1)				// current table number
	
	// channel display graph waves
	
	CheckNMwave(df+"EV_ThreshT", 0, 0)
	CheckNMwave(df+"EV_ThreshY", 0, 0)
	CheckNMwave(df+"EV_OnsetT", 0, 0)
	CheckNMwave(df+"EV_OnsetY", 0, 0)
	CheckNMwave(df+"EV_PeakT", 0, 0)
	CheckNMwave(df+"EV_PeakY", 0, 0)
	CheckNMwave(df+"EV_BaseT", 2, 0)
	CheckNMwave(df+"EV_BaseY", 2, Nan)
	CheckNMwave(df+"EV_ThisT", 1, 0)
	CheckNMwave(df+"EV_ThisY", 1, Nan)
	
	return 0
	
End // CheckEvent
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeEventTab(force) // create controls
	Variable force
	
	Variable x0, y0, yinc
	String df = EventDF()
	
	ControlInfo /W=NMPanel EV_Grp1
	
	if ((V_Flag != 0) && (force == 0))
		return 0 // Event tab controls exist
	endif
	
	if (DataFolderExists(df) == 0)
		return 0 // Event tab has not been initialized yet
	endif

	DoWindow /F NMPanel
	
	x0 = 35; y0 = 205; yinc = 25
	
	GroupBox EV_Grp1, title = "Criteria", pos={x0-15,y0-25}, size={260,220}
	
	PopupMenu EV_SearchMethod, pos={x0+150,y0}, bodywidth=170, mode=1, proc=EventPopupSearch
	PopupMenu EV_SearchMethod, value =""
	
	y0 += 10
	
	SetVariable EV_Threshold, title="", pos={x0+65,y0+1*yinc}, limits={-inf,inf,1}, size={100,20}
	SetVariable EV_Threshold, value=$(df+"Thrshld"), proc=EventSetVariable
	
	y0 += 5
	
	Checkbox EV_SearchCheck, title="search limits", pos={x0,y0+2*yinc}, size={200,20}, value=1, proc=EventCheckBox
	Checkbox EV_BaseCheck, title="baseline", pos={x0,y0+3*yinc}, size={200,20}, value=1, proc=EventCheckBox
	Checkbox EV_OnsetCheck, title="onset", pos={x0,y0+4*yinc}, size={200,20}, value=1, proc=EventCheckBox
	Checkbox EV_PeakCheck, title="peak", pos={x0,y0+5*yinc}, size={200,20}, value=1, proc=EventCheckBox
	Checkbox EV_MatchCheck, title="template matching", pos={x0,y0+6*yinc}, size={200,20}, value=0, proc=EventCheckBox
	
	Button EV_Match, pos={x0+180,y0+ 6*yinc-2}, title="Match", size={50,20}, disable=1, proc=EventButtonFxn
	
	y0 = 440
	
	GroupBox EV_Grp2, title = "Search", pos={x0-15,y0-25}, size={260,150}
	
	PopupMenu EV_TableMenu, value = "Table", bodywidth = 175, pos={x0+125, y0}, proc=EventPopupTable
	
	SetVariable EV_NumEvents, title=":", pos={x0+185,y0+2}, limits={0,inf,0}, size={55,20}
	SetVariable EV_NumEvents, value=$(df+"NumEvents"), frame=0, noedit=1
	
	y0 += 10
	
	SetVariable EV_DsplyWin, title="display win (ms):", pos={x0,y0+1*yinc}, limits={0.1,inf,5}, size={175,20}
	SetVariable EV_DsplyWin, value=$(df+"DsplyWin"), proc=EventSetVariable
	
	SetVariable EV_DsplyTime, title="search time (ms):", pos={x0,y0+2*yinc}, limits={0,inf,1}, size={175,20}
	SetVariable EV_DsplyTime, format = "%.1f", value=$(df+"SearchTime"), proc=EventSetVariable
	
	Button EV_Tzero, pos={220,y0+2*yinc-2}, title="t = 0", size={45,20}, proc=EventButtonSearch
	
	y0 += 5
	
	Button EV_Last, pos={35,y0+ 3*yinc}, title="<", size={25,20}, proc=EventButtonSearch
	Button EV_Next, pos={70,y0+ 3*yinc}, title=">", size={25,20}, proc=EventButtonSearch
	Button EV_Save, pos={110,y0+ 3*yinc}, title="Save", size={45,20}, proc=EventButtonSearch
	Button EV_Delete, pos={165,y0+ 3*yinc}, title="Delete", size={45,20}, proc=EventButtonSearch
	Button EV_Auto, pos={220,y0+ 3*yinc}, title="Auto", size={45,20}, proc=EventButtonSearch
	
	y0 = 580
	
	Button EV_E2W, pos={x0,y0}, title="Events 2 Waves", size={110,20}, proc=EventButtonFxn
	Button EV_Histo, pos={x0+130,y0}, title="Histogram", size={100,20}, proc=EventButtonFxn
	
	UpdateEventTab()

End // MakeEventTab

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateEventTab() // update event tab display
	Variable md
	
	String df = EventDF()

	NVAR MatchFlag = $(df+"MatchFlag"); NVAR SearchMethod = $(df+"SearchMethod")
	NVAR SearchTime = $(df+"SearchTime")
	NVAR MatchTau1 = $(df+"MatchTau1"); NVAR MatchTau2 = $(df+"MatchTau2")
	NVAR OnsetFlag = $(df+"OnsetFlag"); NVAR PeakFlag = $(df+"PeakFlag")
	NVAR SearchBgn = $(df+"SearchBgn"); NVAR SearchEnd = $(df+"SearchEnd")
	NVAR OnsetWin = $(df+"OnsetWin"); NVAR OnsetAvg = $(df+"OnsetAvg")
	NVAR PeakWin = $(df+"PeakWin"); NVAR PeakAvg = $(df+"PeakAvg")
	NVAR OnsetNstdv = $(df+"OnsetNstdv"); NVAR PeakNstdv = $(df+"PeakNstdv")
	NVAR SearchMethod = $(df+"SearchMethod")
	NVAR BaseWin = $(df+"BaseWin")
	NVAR Thrshld = $(df+"Thrshld")
	NVAR TableNum = $(df+"TableNum")
	
	SVAR Template = $(df+"Template")
	
	Variable SearchFlag = NumVarOrDefault(df+"SearchFlag", 0)
	Variable BaseFlag = NumVarOrDefault(df+"BaseFlag", 0)
	Variable BaseDT = NumVarOrDefault(df+"BaseDT", BaseWin)
	
	Variable tbgn = EventSearchBgn()
	Variable tend = EventSearchEnd()
	
	String dname = ChanDisplayWave(-1)
	
	if (WaveExists($EventName("ThreshT", TableNum)) == 0)
		TableNum = -1
	endif
	
	if (SearchMethod > 2)
		Thrshld = abs(Thrshld)
		BaseFlag = 1
		SetNMvar(df+"BaseFlag", 1)
	endif
	
	if (MatchFlag > 0)
		OnsetFlag = 1
		BaseFlag = 0
		SetNMvar(df+"BaseFlag", 0)
	endif
	
	if (SearchTime < tbgn)
		SearchTime = tbgn
	endif
	
	if (SearchTime > tend)
		SearchTime = tend
	endif
	
	String methodstr = "level detect (+slope);level detect (-slope);threshold > baseline;threshold < baseline;"
	String threshstr = "threshold:", searchstr = "search limits", onsetstr = "onset", peakstr = "peak", basestr = "baseline"
	String matchstr = "template matching"
	String tablestr = "Event Table;---;" + EventTableList() + "---;New;Clear;Kill;"
	
	if (MatchFlag > 0)
		methodstr = "level cross (+slope);level cross (-slope);"
		threshStr = "matched"
		onsetstr += " (auto)"
	endif
	
	if (SearchMethod < 3)
		threshStr = "level:"
	endif
	
	if (SearchFlag == 0)
		SetNMvar(df+"SearchBgn", -inf)
		SetNMvar(df+"SearchEnd", inf)
	endif

	searchstr += " (t=" + num2str(SearchBgn) + ", " + num2str(SearchEnd) + " ms)"
	
	if (BaseFlag == 1)
		basestr += " (avg=" + num2str(BaseWin) + " ms, dt=" + num2str(BaseDT) + " ms)"
	endif
	
	if ((OnsetFlag == 1) && (MatchFlag == 0))
		onsetstr += " (avg=" + num2str(OnsetAvg) + " ms, Nsdv=" + num2str(OnsetNstdv) + ", limit=" + num2str(OnsetWin) + " ms)"
	endif
	
	if (PeakFlag == 1)
		peakstr += " (avg=" + num2str(PeakAvg) + " ms, Nsdv=" + num2str(PeakNstdv) + ", limit=" + num2str(PeakWin) + " ms)"
	endif
	
	if (MatchFlag == 1)
		matchstr = "template (tau1=" + num2str(MatchTau1) + ", tau2=" + num2str(MatchTau2) + " ms)"
	elseif (MatchFlag == 2)
		matchstr = "template (tau1=" + num2str(MatchTau1) + " ms)"
	elseif (MatchFlag == 3)
		matchstr = "template (" + Template + ")"
	endif
	
	Checkbox EV_SearchCheck, win=NMPanel, value=SearchFlag, title=searchstr
	Checkbox EV_BaseCheck, win=NMPanel, value=BaseFlag, title=basestr
	Checkbox EV_OnsetCheck, win=NMPanel, value=OnsetFlag, title=onsetstr
	Checkbox EV_PeakCheck, win=NMPanel, value=PeakFlag, title=peakstr
	Checkbox EV_MatchCheck, win=NMPanel, value=MatchFlag, title = matchstr
	
	Button EV_Match, win=NMPanel, disable=(!MatchFlag)
	
	SetVariable EV_Threshold, win=NMPanel, title=threshstr
	SetVariable EV_DsplyTime, win=NMPanel, limits={SearchBgn,SearchEnd,1}
	
	Execute /Z "PopupMenu EV_SearchMethod, win=NMPanel, value=\"" + methodstr + "\", mode=" + num2str(SearchMethod)
	
	md = WhichListItemLax("EventTable"+num2str(TableNum), tablestr, ";") + 1
	
	if (md < 1)
		md = 1
	endif
	
	Execute /Z "PopupMenu EV_TableMenu, win=NMPanel, value=\"" + tablestr + "\", mode=" + num2str(md)
	
	EventCount()
	
End // UpdateEventTab

//****************************************************************
//****************************************************************
//****************************************************************

Function EventButtonSearch(ctrlName) : ButtonControl
	String ctrlName
	
	EventSearchCall(ctrlName[3,inf])
	
End // EventButtonSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchBgn()

	Variable t = NumVarOrDefault(EventDF()+"SearchBgn", -inf)

	if (numtype(t) > 0)
		t = leftx($ChanDisplayWave(-1))
	endif
	
	return t

End // EventSearchBgn

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchEnd()

	Variable t = NumVarOrDefault(EventDF()+"SearchEnd", inf)

	if (numtype(t) > 0)
		t = rightx($ChanDisplayWave(-1))
	endif
	
	return t

End // EventSearchEnd

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchCall(func)
	String func
	
	Variable v1
	String df = EventDF()
	
	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)
	
	NVAR EventNum = $(df+"EventNum")
	NVAR TableNum = $(df+"TableNum")
	NVAR ThreshX = $(df+"ThreshX")
	
	if (TableNum >= 0)
		Wave waveN = $EventName("WaveN", TableNum)
	endif
	
	Variable event = EventFindSaved(EventName("WaveN", -1), df+"EV_ThreshT", ThreshX, 0.01, CurrentWave)
	
	Variable findHistory = EventSetValue(-1)
	
	if (event < 0) // no event time found
	
		if (EventNum == numpnts(ThreshT) - 1)
			event = EventNum + 1
		elseif (EventNum < numpnts(ThreshT) - 1)
			event = EventNum
		else
			event = numpnts(ThreshT)
		endif
		
	endif

	strswitch(func)
	
		case "Next":
		
			//NMCmdHistory("EventFindNext", "")
			
			if (numtype(findHistory) == 0)
				
			elseif (EventFindNext(1) == -1)
			
				DoAlert 0, "Found no more events."
				
			endif
			
			break
			
		case "Last":
		
			event -= 1
			
			if (event < 0)
				event = EventNum
			endif
			
			if ((TableNum >= 0) && (waveN[event] != CurrentWave))
				break
			endif
			
			//NMCmdHistory("EventRetrieve", NMCmdNum(event,""))
			
			EventRetrieve(event)
			
			break
			
		case "Save":
		
			if (TableNum == -1)
				TableNum = 0
			endif
			
			EventTable("make", TableNum)
			
			//NMCmdHistory("EventSave", "")
			
			if (EventSave() == 0)
				EventFindNext(1)
			endif
			
			break
			
		case "Delete":
		
			if (event == EventNum)
				//NMCmdHistory("EventDelete", NMCmdNum(event,""))
				EventDelete(event)
				EventNum -= 1
			endif
			
			break
		
		case "All":
		case "Auto":
		
			EventFindAllCall()
			
			break
			
		case "T0":
		case "Tzero":
			v1 = EventSearchBgn()
			NMCmdHistory("EventSearchTime", NMCmdNum(v1,""))
			EventSearchTime(v1)
			break
			
	endswitch
	
	Dowindow /F NMPanel
	
End // EventSearchCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventButtonFxn(ctrlName) : ButtonControl
	String ctrlName
	
	strswitch(ctrlName)
		case "EV_Match":
			MatchTemplateCall(1)
			EventDisplay(1)
			break
		case "EV_E2W":
			Event2WaveCall()
			break
		case "EV_Histo":
			EventHistoCall()
			break
	endswitch
	
End // EventButtonFxn

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName

	strswitch(ctrlName)
		case "EV_Threshold":
			NMCmdHistory("EventThreshold", NMCmdNum(varNum,""))
			EventThreshold(varNum)
			break
		case "EV_DsplyWin":
			NMCmdHistory("EventDisplayWin", NMCmdNum(varNum,""))
			EventDisplayWin(varNum)
			break
		case "EV_DsplyTime":
			NMCmdHistory("EventSearchTime", NMCmdNum(varNum,""))
			EventSearchTime(varNum)
		break
	endswitch

End // EventSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function EventCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	Variable v1, v2, v3, change
	String wName, vlist = "", df = EventDF()
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)
	
	NVAR MatchFlag = $(df+"MatchFlag")
	NVAR SearchMethod = $(df+"SearchMethod")
	
	String dname = ChanDisplayWave(-1)

	strswitch(ctrlName)
	
		case "EV_SearchCheck":
		
			v1 = -inf
			v2 = inf
			
			if (checked == 1)
			
				change = 1
				
				v1 = leftx($dname)
				v2 = rightx($dname)
				
				Prompt v1, "time window begin (ms):"
				Prompt v2, "time window end (ms):"
				DoPrompt "Event Search Limits", v1, v2
				
				if (V_flag == 1)
					checked = 0; v1 = -inf; v2 = inf;
				endif
			
			endif
			
			vlist = NMCmdNum(checked, vlist)
			vlist = NMCmdNum(v1, vlist)
			vlist = NMCmdNum(v2, vlist)
			NMCmdHistory("EventWindow", vlist)
			
			EventWindow(checked, v1, v2)
			
			break
	
		case "EV_BaseCheck":
		
			if (MatchFlag == 1)
				checked = 0
			endif
			
			if ((checked == 1) || (SearchMethod > 2))
			
				checked = 1
				v1 = NumVarOrDefault(df+"BaseWin", 2)
				v2 = NumVarOrDefault(df+"BaseDT", v1)
				Prompt v1, "average window (ms):"
				Prompt v2, "delta time (dt) between mid-baseline and threshold crossing (ms):"
				DoPrompt "Baseline Parameters", v1, v2
			
			endif
			
			vlist = NMCmdNum(checked, vlist)
			vlist = NMCmdNum(v1, vlist)
			vlist = NMCmdNum(v2, vlist)
			NMCmdHistory("EventBsln", vlist)
			
			EventBsln(checked, v1, v2)
			
			break
			
		case "EV_OnsetCheck":

			if ((checked == 1) && (MatchFlag == 0))
			
				v1 = NumVarOrDefault(df+"OnsetAvg", 1)
				v2 = NumVarOrDefault(df+"OnsetNstdv", 1)
				v3 = NumVarOrDefault(df+"OnsetWin", 2)
				
				Prompt v1, "sliding average window (ms):"
				Prompt v2, "define onset as number of stdv's above average:"
				Prompt v3, "search window limit (ms):"
				DoPrompt "Onset Time Search", v1, v2, v3
				
				if (V_flag == 1)
					checked = 0; v1 = 0; v2 = 0; v3 = 0;
				endif
				
			endif
			
			vlist = NMCmdNum(checked, vlist)
			vlist = NMCmdNum(v1, vlist)
			vlist = NMCmdNum(v2, vlist)
			vlist = NMCmdNum(v3, vlist)
			NMCmdHistory("EventOnset", vlist)
			
			EventOnset(checked, v1, v2, v3)
			
			break
			
		case "EV_PeakCheck":
			
			if (checked == 1)
			
				v1 = NumVarOrDefault(df+"PeakAvg", 2)
				v2 = NumVarOrDefault(df+"PeakNstdv", 1)
				v3 = NumVarOrDefault(df+"PeakWin", 5)
				
				Prompt v1, "sliding average window (ms):"
				Prompt v2, "define peak as number of stdv's above average:"
				Prompt v3, "search window limit (ms):"
				DoPrompt "Peak Time Search", v1, v2, v3
				
				if (V_flag == 1)
					checked = 0; v1 = 0; v2 = 0; v3 = 0;
				endif
				
			endif
			
			vlist = NMCmdNum(checked, vlist)
			vlist = NMCmdNum(v1, vlist)
			vlist = NMCmdNum(v2, vlist)
			vlist = NMCmdNum(v3, vlist)
			NMCmdHistory("EventPeak", vlist)
			
			EventPeak(checked, v1, v2, v3)
			
			break
			
		case "EV_MatchCheck":
			NMCmdHistory("MatchTemplateOn", NMCmdNum(checked,""))
			MatchTemplateOn(checked)
			break
			
	endswitch

End // EventCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function EventPopupSearch(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	NMCmdHistory("EventSearchMethod", NMCmdNum(popNum,""))
	EventSearchMethod(popNum)
	
End // EventPopupSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function EventPopupTable(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	Variable ipnt
	String df = EventDF()
	
	Variable tnum

	strswitch(popStr)
		case "Event Table":
		case "---":
			UpdateEventTab()
			break
			
		case "New":
		case "Clear":
		case "Kill":
			EventTableCall(popStr)
			break
			
		default:
			ipnt = strlen(popStr)
			tnum = str2num(popStr[ipnt-1,ipnt-1])
			NMCmdHistory("EventTableSelect", NMCmdNum(tnum,""))
			EventTableSelect(tnum)
			break
	endswitch
	
End // EventPopupTable

//****************************************************************
//****************************************************************
//****************************************************************

Function EventDisplay(appnd) // append/remove event display waves from channel graph
	Variable appnd // (1) append wave (0) remove wave
	Variable icnt
	
	Variable ccnt, found
	String gName, df = EventDF()
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	
	if (DataFolderExists(df) == 0)
		return 0 // event tab has not been initialized yet
	endif
	
	Variable MatchFlag = NumVarOrDefault(df+"MatchFlag", 0)
	
	for (ccnt = 0; ccnt < 10; ccnt += 1)
	
		gName = GetGraphName("Chan", ccnt)
	
		if (Wintype(gName) == 0)
			continue
		endif
	
		DoWindow /F $gName
		
		found = WhichListItemLax("EV_ThreshY", TraceNameList(gName, ";", 1), ";")
	
		RemoveFromGraph /Z/W=$gName EV_BaseY, EV_ThisY, EV_ThreshY, EV_OnsetY, EV_PeakY, EV_MatchTmplt
	
		if ((appnd == 0) || (ccnt != CurrentChan))
		
			ChanAutoScale( CurrentChan , 1 )
			SetAxis /A/W=$gName
			HideInfo
			
			if (found != -1) // remove cursors
				Cursor /K/W=$gName A
				Cursor /K/W=$gName B
			endif
		
			continue
			
		endif
	
		if ((MatchFlag > 0) && (exists(df+"EV_MatchTmplt") == 1))
		
			AppendToGraph /R=match /W=$gName $(df+"EV_MatchTmplt")
			ModifyGraph rgb(EV_MatchTmplt)=(0,0,65535)
			ModifyGraph axRGB(match)=(0,0,65535)
			AppendToGraph /R=match /W=$gName $(df+"EV_ThisY") vs $(df+"EV_ThisT")
			ModifyGraph /W=$gName mode(EV_ThisY)=3, marker(EV_ThisY)=9, msize(EV_ThisY)=6
			ModifyGraph /W=$gName mrkThick(EV_ThisY)=2, rgb(EV_ThisY)=(65535,0,0)
			AppendToGraph /R=match /W=$gName $(df+"EV_ThreshY") vs $(df+"EV_ThreshT")
			ModifyGraph /W=$gName mode(EV_ThreshY)=3, marker(EV_ThreshY)=9, msize(EV_ThreshY)=6
			ModifyGraph /W=$gName mrkThick(EV_ThreshY)=2, rgb(EV_ThreshY)=(65535,0,0)
			Label match "Detection Criteria"
			
		endif
		
		if (exists(df+"EV_ThreshY") == 1)
		
			AppendToGraph /W=$gName $(df+"EV_BaseY") vs $(df+"EV_BaseT")
			ModifyGraph /W=$gName mode(EV_BaseY)=0
			ModifyGraph /W=$gName lsize(EV_BaseY)=2, rgb(EV_BaseY)=(0,0,65535)
			
			if (MatchFlag == 0)
				AppendToGraph /W=$gName $(df+"EV_ThisY") vs $(df+"EV_ThisT")
				ModifyGraph /W=$gName mode(EV_ThisY)=3, marker(EV_ThisY)=9, msize(EV_ThisY)=4
				ModifyGraph /W=$gName mrkThick(EV_ThisY)=2, rgb(EV_ThisY)=(65535,0,0)
				AppendToGraph /W=$gName $(df+"EV_ThreshY") vs $(df+"EV_ThreshT")
				ModifyGraph /W=$gName mode(EV_ThreshY)=3, marker(EV_ThreshY)=9, msize(EV_ThreshY)=4
				ModifyGraph /W=$gName mrkThick(EV_ThreshY)=2, rgb(EV_ThreshY)=(65535,0,0)
			endif
			
			AppendToGraph /W=$gName $(df+"EV_OnsetY") vs $(df+"EV_OnsetT")
			ModifyGraph /W=$gName mode(EV_OnsetY)=3, marker(EV_OnsetY)=19, msize(EV_OnsetY)=4
			ModifyGraph /W=$gName mrkThick(EV_OnsetY)=2, rgb(EV_OnsetY)=(65535,0,0)
			AppendToGraph /W=$gName $(df+"EV_PeakY") vs $(df+"EV_PeakT")
			ModifyGraph /W=$gName mode(EV_PeakY)=3, marker(EV_PeakY)=16, msize(EV_PeakY)=3
			ModifyGraph /W=$gName mrkThick(EV_PeakY)=2, rgb(EV_PeakY)=(65535,0,0)
			ShowInfo
			
		endif
		
	endfor

End // EventDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateEventDisplay() // update event display waves from table wave values

	Variable icnt, npnts1, npnts2
	String df = EventDF()

	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)
	
	NVAR TableNum = $(df+"TableNum")

	Wave ThreshT = $(df+"EV_ThreshT"); Wave ThreshY = $(df+"EV_ThreshY")
	Wave OnsetT = $(df+"EV_OnsetT"); Wave OnsetY = $(df+"EV_OnsetY")
	Wave PeakT = $(df+"EV_PeakT"); Wave PeakY = $(df+"EV_PeakY")
	
	if ((TableNum == -1) || (WaveExists($EventName("ThreshT", -1)) == 0))
		ThreshY = Nan; OnsetY = Nan; PeakY = Nan
		return 0
	endif
	
	Wave waveN = $EventName("WaveN", -1)
	Wave thT = $EventName("ThreshT", -1); Wave thY = $EventName("ThreshY", -1)
	Wave onT = $EventName("onsetT", -1); Wave onY = $EventName("onsetY", -1)
	Wave pkT = $EventName("peakT", -1); Wave pkY = $EventName("peakY", -1)
	
	npnts1 = numpnts(ThreshT)
	npnts2 = numpnts(thT)
	
	if (npnts1 != npnts2)
		Redimension /N=(npnts2) ThreshT, ThreshY, OnsetT, OnsetY, PeakT, PeakY
	endif
	
	if (npnts2 == 0)
		return 0
	endif
	
	ThreshT = thT; OnsetT = onT; PeakT = pkT
	
	for (icnt = 0; icnt < npnts2; icnt += 1)
		if (waveN[icnt] == CurrentWave)
			ThreshY[icnt] = thY[icnt]
			OnsetY[icnt] = onY[icnt]
			PeakY[icnt] = pkY[icnt]
		else
			ThreshY[icnt] = Nan
			OnsetY[icnt] = Nan
			PeakY[icnt] = Nan
		endif
	endfor
	
	DoUpdate
	
End // UpdateEventDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function EventCursors(enable) // place cursors on onset and peak times
	Variable enable // (1) add (0) remove
	
	String df = EventDF()

	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	
	NVAR DsplyWin = $(df+"DsplyWin"); NVAR ThreshX = $(df+"ThreshX")
	NVAR OnsetX = $(df+"OnsetX"); NVAR PeakX = $(df+"PeakX")
	
	String gName = ChanGraphName(-1)
	String dName = GetPathName(ChanDisplayWave(-1), 0)
	
	Variable tmid = ThreshX

	if ((numtype(tmid) > 0) || (tmid == 0))
		tmid = leftx($ChanDisplayWave(-1))
	endif

	if ((enable == 1) && (WinType(gName) == 1))
		Cursor /W=$gName A, $dName, OnsetX
		Cursor /W=$gName B, $dName, PeakX
		SetAxis /W=$gName bottom tmid-DsplyWin/2, tmid+DsplyWin/2
	endif
	
	DoUpdate
	
End // EventCursors

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchMethod(method)
	Variable method
	
	switch(method)
		case 1:
		case 2:
		case 3:
		case 4:
			break
		default:
			method = 3
	endswitch

	SetNMvar(EventDF()+"SearchMethod", method)
	UpdateEventTab()
	
End // EventSearchMethod

//****************************************************************
//****************************************************************
//****************************************************************

Function EventThreshold(thresh)
	Variable thresh
	
	if (numtype(thresh) > 0)
		thresh = 0
	endif
	
	SetNMvar(EventDF()+"Thrshld", thresh)
	
End // EventThresh

//****************************************************************
//****************************************************************
//****************************************************************

Function EventWindow(on, tbgn, tend)
	Variable on, tbgn, tend
	
	String df = EventDF()
	
	SetNMvar(df+"SearchBgn", tbgn)
	SetNMvar(df+"SearchEnd", tend)
	SetNMvar(df+"SearchFlag", BinaryCheck(on))
	
	UpdateEventTab()

End // EventWindow

//****************************************************************
//****************************************************************
//****************************************************************

Function EventBsln(on, avg, dt)
	Variable on, avg, dt
	
	String df = EventDF()
	
	switch(on)
		default:
			SetNMvar(df+"BaseWin", avg)
			SetNMvar(df+"BaseDT", dt)
			on = 1
		case 0:
			break
	endswitch
			
	SetNMvar(df+"BaseFlag", on)
	
	EventTable("update", NumVarOrDefault(df+"TableNum", 0))
	UpdateEventTab()
			
End // EventBsln

//****************************************************************
//****************************************************************
//****************************************************************

Function EventOnset(on, avg, nSTDV, win)
	Variable on, avg, nSTDV, win
	
	String df = EventDF()
	
	switch(on)
		default:
			SetNMvar(df+"OnsetAvg", avg)
			SetNMvar(df+"OnsetNstdv", nSTDV)
			SetNMvar(df+"OnsetWin", win)
			on = 1
		case 0:
			break
	endswitch
	
	SetNMvar(df+"OnsetFlag", on)
	
	EventTable("update", NumVarOrDefault(df+"TableNum", 0))
	UpdateEventTab()
			
End // EventOnset

//****************************************************************
//****************************************************************
//****************************************************************

Function EventPeak(on, avg, nSTDV, win)
	Variable on, avg, nSTDV, win
	
	String df = EventDF()
	
	switch(on)
		default:
			SetNMvar(df+"PeakAvg", avg)
			SetNMvar(df+"PeakNstdv", nSTDV)
			SetNMvar(df+"PeakWin", win)
			on = 1
		case 0:
			break
	endswitch
	
	SetNMvar(df+"PeakFlag", on)
	
	EventTable("update", NumVarOrDefault(df+"TableNum", 0))
	UpdateEventTab()
			
End // EventPeak

//****************************************************************
//****************************************************************
//****************************************************************

Function EventDisplayWin(win) // display window size
	Variable win
	
	if (numtype(win) > 0)
		win = 50
	endif
	
	SetNMvar(EventDF()+"DsplyWin", win)
	
	EventCursors(1)
	
End // EventDisplayWin

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchTime(t) // set current search time
	Variable t
	
	String df = EventDF()
	
	if (numtype(t) > 0)
		t = leftx($ChanDisplayWave(-1))
	endif
	
	SetNMvar(df+"SearchTime", t)
	
	SetNMvar(df+"ThreshX", t)
	SetNMvar(df+"ThreshY", Nan)
	
	SetNMvar(df+"OnsetX", t)
	SetNMvar(df+"PeakX", t)
	
	SetNMwave(df+"EV_ThisT", -1, Nan)
	SetNMwave(df+"EV_ThisY", -1, Nan)
	SetNMwave(df+"EV_BaseT", -1, Nan)
	SetNMwave(df+"EV_BaseY", -1, Nan)
	
	EventCursors(1)
	
End // EventSearchTime

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoEvent() // called when user changes CurrentWave
	
	EventSearchTime(NumVarOrDefault(EventDF()+"SearchBgn", 0))
	UpdateEventDisplay()
	MatchTemplateCall(0)

End // AutoEvent

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindAllCall()

	String vlist = "", df = EventDF()

	String wlist = NMChanWaveList(-1)
	Variable nwaves = ItemsInList(wlist)
	
	NVAR SearchTime = $(df+"SearchTime")
	NVAR TableNum = $(df+"TableNum")
	
	if (nwaves == 0)
		DoAlert 0, "No waves selected."
		return 0
	endif

	Variable wselect = 1 + NumVarOrDefault(df+"AutoWSelect", 1)
	Variable tselect = NumVarOrDefault(df+"AutoTSelect", 1)
	Variable tzero = 1+ NumVarOrDefault(df+"AutoTZero", 1)
	Variable dsply = 1 + NumVarOrDefault(df+"AutoDsply", 1)
	
	if (EventCount() == 0)
		tselect = 2
	endif
	
	if (nwaves == 1)
		Prompt wselect, "auto event detection on:", popup "this wave;"
	else
		Prompt wselect, "auto event detection on:", popup "this wave;" + NMWaveSelectGet() + " waves;"
	endif
	
	Prompt tselect, "save events where?", popup "new table;current table;"
	Prompt tzero, "search from time zero?", popup "no;yes;"
	Prompt dsply, "display results while detecting?", popup "no;yes;"
	
	if (TableNum == -1)
		tselect = 2
		DoPrompt "Auto Event Detection", wselect, tzero, dsply
	else
		DoPrompt "Auto Event Detection", wselect, tselect, tzero, dsply
	endif
	
	if (V_flag == 1)
		return 0
	endif
	
	wselect -= 1
	tzero -= 1
	dsply -= 1
	
	SetNMvar(df+"AutoWSelect", wselect)
	SetNMvar(df+"AutoTSelect", tselect)
	SetNMvar(df+"AutoTZero", tzero)
	SetNMvar(df+"AutoDsply", dsply)
	
	if (tselect == 0)
		EventTableNew()
	endif
	
	if (tzero == 1)
		EventSearchTime( EventSearchBgn() )
	endif
	
	NMCmdNum(wselect, vlist)
	NMCmdNum(dsply, vlist)
	
	NMCmdHistory("EventFindAll", vlist)
	
	EventFindAll(wselect, dsply)

End // EventFindAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindAll(wselect, dsply) // find events until end of trace
	Variable wselect // (0) current wave (1) all waves
	Variable dsply // (0) no (1) yes, update display

	Variable pflag
	String wName, setName, df = EventDF()
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	
	NVAR CurrentWave
	
	NVAR SearchTime = $(df+"SearchTime")
	NVAR TableNum = $(df+"TableNum")
	NVAR EventNum = $(df+"EventNum")
	
	Wave ThreshT = $(df+"EV_ThreshT")
	Wave WavSelect
	
	Variable wcnt, ecnt, events
	Variable wbgn = CurrentWave
	Variable wend = CurrentWave
	Variable savewave = CurrentWave
	Variable savetime = SearchTime

	//Variable saveEvent = EventFindSaved(EventName("WaveN", -1), df+"EV_ThreshT", savetime, 0.01, CurrentWave)

	if (TableNum < 0)
		EventTableNew()
	endif
	
	Wave waveN = $EventName("WaveN", TableNum)
	
	if (wselect == 1)
		wbgn = 0
		wend = numpnts(WavSelect) - 1
	endif
	
	Wave set = $EventSetName(TableNum)
	
	DoWindow /F $ChanGraphName(-1)
	
	//Print ""
	//Print "Auto event detection for Ch " + ChanNum2Char(CurrentChan) + " saved in Table " + num2str(TableNum)
	
	NMProgressStr("Detecting Events...")

	for (wcnt = wbgn; wcnt <= wend; wcnt += 1)
	
		if ((wselect == 0) || ((wselect == 1) && (WavSelect[wcnt] == 1)))
		
			if (wselect == 1) // all waves
				CurrentWave = wcnt
				UpdateCurrentWave()
				UpdateEventDisplay()
			endif
			
			ecnt = 0
			
			NMProgressStr("Detecting Events...")
			CallProgress(-1)
			
			do
			
				pflag = CallProgress(-2)
			
				if (pflag == 1) // cancel
					break
				endif
				
				if (EventFindNext(dsply) == 0)
				
					if (EventSaveCurrent(0) == -3)
						break
					endif
					
					if (numtype(set[wcnt]) > 0)
						set[wcnt] = EventNum // mark location of first event
					endif
					
					ecnt += 1
					
				else
				
					break // no more events
					
				endif
				
			while (1)
			
			Print "Located " + num2str(ecnt) + " event(s) in wave " + CurrentWaveName()
			
		endif
		
		if (pflag == 1) // cancel
			break
		endif
	
	endfor
	
	CallProgress(1)
	
	if (pflag == 0)
	
		//if (saveEvent == -1)
		//	EventSearchTime(savetime)
		//else
		//	EventRetrieve(saveEvent)
		//endif
		
		if (CurrentWave != wbgn)
			CurrentWave = wbgn
			UpdateCurrentWave()
		endif
	
	endif
	
	UpdateEventTab()
	
	DoWindow /F $EventTableName(tableNum)

End // EventFindAll

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindNext(dsply) // find next event
	Variable dsply // (0) no (yes) update display
	
	Variable wbgn, wend, nstdv, posneg = -1, jcnt, jlimit = 20
	Variable tbgn, tend, dx
	String df = EventDF()
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)
	
	NVAR SearchMethod = $(df+"SearchMethod")
	
	NVAR MatchFlag = $(df+"MatchFlag"); NVAR MatchBsln = $(df+"MatchBsln")
	NVAR MatchWform = $(df+"MatchWform")
	
	NVAR OnsetFlag = $(df+"OnsetFlag"); NVAR OnsetNstdv = $(df+"OnsetNstdv")
	NVAR OnsetWin = $(df+"OnsetWin"); NVAR OnsetAvg = $(df+"OnsetAvg")
	
	NVAR PeakFlag = $(df+"PeakFlag"); NVAR PeakNstdv = $(df+"PeakNstdv")
	NVAR PeakWin = $(df+"PeakWin"); NVAR PeakAvg = $(df+"PeakAvg")
	
	NVAR ThreshX = $(df+"ThreshX"); NVAR ThreshY = $(df+"ThreshY")
	NVAR OnsetX = $(df+"OnsetX"); NVAR OnsetY = $(df+"OnsetY")
	NVAR PeakX = $(df+"PeakX"); NVAR PeakY = $(df+"PeakY")
	
	NVAR Thrshld = $(df+"Thrshld"); NVAR BaseWin = $(df+"BaseWin")
	NVAR EventNum = $(df+"EventNum"); NVAR SearchTime = $(df+"SearchTime")
	
	Variable BaseDT = NumVarOrDefault(df+"BaseDT", BaseWin)
	Variable BaseFlag = NumVarOrDefault(df+"BaseFlag", 0)
	
	Wave ThreshT = $(df+"EV_ThreshT")
	Wave BaseT = $(df+"EV_BaseT"); Wave BaseY = $(df+"EV_BaseY")
	Wave ThisT = $(df+"EV_ThisT"); Wave ThisY = $(df+"EV_ThisY")
	
	String wName = ChanDisplayWave(-1)
	
	if (WaveExists($wName) == 0)
		return 0
	endif
	
	Wave eWave = $wName
	
	String wName2 = wName
	
	if (MatchFlag > 0)
		wName2 = df + "EV_MatchTmplt"
	endif
	
	dx = deltax($wName)
	
	BaseY = Nan
	ThreshY = Thrshld
	
	tbgn = EventSearchBgn()
	tend = EventSearchEnd()
	
	do // search for next event
	
		if ((PeakFlag == 1) && (numtype(PeakX) == 0))
			tbgn = PeakX + 4*dx
		elseif (numtype(ThreshX) == 0) 
			tbgn = ThreshX + 4*dx
		else
			break
			//tbgn = SearchBgn
		endif
	
		switch(SearchMethod)
			case 1: // Level+
				posneg = 1; ThreshX = FindLevelPosNeg(tbgn, tend, Thrshld, "+", wName2)
				break
			case 2: // Level-
				ThreshX = FindLevelPosNeg(tbgn, tend, Thrshld, "-", wName2)
				break
			case 3: // thresh > base
				posneg = 1
			case 4: // thresh < base
				ThreshX = EventFindThresh(wName2, tbgn, tend, BaseWin/dx, BaseDT/dx, Thrshld, posneg)
				break
		endswitch
		
		if (numtype(ThreshX) > 0) // no event found
			ThreshX = ThisT[0]
			return -1
		endif
		
		Wave eWave2 = $wName2
		
		ThreshY = eWave2[x2pnt(eWave2, ThreshX)]
		
		// find onsets and peaks
	
		if (MatchFlag > 0)
		
			WaveStats /Q/R=(ThreshX, ThreshX+PeakWin) $wName2
			
			if (SearchMethod == 1)
				OnsetX = V_maxloc + MatchBsln
			elseif (SearchMethod == 2)
				OnsetX = V_minloc + MatchBsln
			else
				OnsetX = Nan
			endif
			
			OnsetY = eWave[x2pnt(eWave, OnsetX)]
	
			if (PeakFlag == 1)
				PeakX = NMFindPeak(wName, OnsetX, OnsetX+PeakWin, floor(PeakAvg/dx), PeakNstdv, posneg)
				PeakY = eWave[x2pnt(eWave, PeakX)]
			else
				PeakX = Nan
				PeakY = Nan
			endif
			
		else
		
			if (OnsetFlag == 1) // search backward from ThreshX
				OnsetX = NMFindOnset(wName, ThreshX-OnsetWin, ThreshX, floor(OnsetAvg/dx), OnsetNstdv, posneg, -1)
				OnsetY = eWave[x2pnt(eWave, OnsetX)]
			else
				OnsetX = Nan
				OnsetY = Nan
			endif
			
			if (PeakFlag == 1)
				PeakX = NMFindPeak(wName, ThreshX, ThreshX+PeakWin, floor(PeakAvg/dx), PeakNstdv, posneg)
				PeakY = eWave[x2pnt(eWave, PeakX)]
			else
				PeakX = Nan
				PeakY = Nan
			endif
			
		endif
		
		jcnt =+ 1
		
		if (jcnt > jlimit)
			ThreshX = Nan; PeakX = Nan; OnsetX = Nan
			break
		endif
		
		if ((SearchMethod == 3) || (SearchMethod == 4)) // threshold/baseline method
			tbgn = ThreshX - BaseDT
		else
			tbgn = ThreshX + dx
		endif

		if ((OnsetFlag == 1) && (numtype(OnsetX) > 0))
			continue // bad event
		endif
		
		if ((PeakFlag == 1) && (numtype(PeakX) > 0))
			continue // bad event
		endif
		
		break // found event
	
	while (1)
	
	if (BaseFlag == 1) // compute baseline display
		wbgn = ThreshX - BaseDT - BaseWin/2
		wend = ThreshX - BaseDT + BaseWin/2
		WaveStats /Q/R=(wbgn,wend) $wName
		BaseY = V_avg
		BaseT[0] = wbgn
		BaseT[1] = wend
	endif
	
	ThisT[0] = ThreshX
	ThisY[0] = ThreshY
	
	SearchTime = ThreshX
	
	EventNum = EventFindSaved(EventName("WaveN", -1), df+"EV_ThreshT", ThreshX, 0.01, CurrentWave)
	
	if (EventNum == -1)
		EventNum = numpnts(ThreshT) - 1
	endif
	
	if (dsply == 1)
		EventCursors(1)
	endif
	
	return 0 // success

End // EventFindNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventMethod(method)
	Variable method
	
	switch(method)
		case 1:
			return "Level+"
		case 2:
			return "Level-"
		case 3:
			return "thresh > bsln"
		case 4:
			return "thresh < bsln"
	endswitch
	
	return ""
	
End // EventMethod

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindThresh(wName, tbgn, tend, avgN, skipN, thresh, posneg) // locate threshold above baseline
	String wName // wave name
	Variable tbgn, tend //search window (ms)
	Variable avgN // baseline average points
	Variable skipN // number of points between baseline and threshold crossing point
	Variable thresh // threshold value
	Variable posneg // (1) pos event (-1) neg event
	
	if (numtype(tbgn*tend*avgN*skipN*thresh*posneg) > 0)
		return Nan
	endif
	
	if (WaveExists($wName) == 0)
		return Nan
	endif
	
	Variable icnt, level, xpnt, avg
	
	Wave eWave = $wName
	Variable dx = deltax(eWave)

	// search forward from tbgn until right-most data point falls above threshold value
	
	for (icnt = x2pnt(eWave, tbgn); icnt < x2pnt(eWave, tend) - skipN; icnt+=1)
	
		if (avgN > 0)
			WaveStats /Q/R=[icnt - avgN/2, icnt + avgN/2] eWave
			avg = V_avg
		else
			avg = eWave[icnt]
		endif
		
		level = avg + abs(thresh)*posneg
		
		xpnt = icnt + skipN
		
		if ((posneg > 0) && (eWave[xpnt] >= level))
			return pnt2x(eWave, xpnt)
		elseif ((posneg < 0) && (eWave[xpnt] <= level))
			return pnt2x(eWave, xpnt)
		endif
		
	endfor
	
	return Nan

End // EventFindThresh

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateOn(on)
	Variable on // (0) off (1) on
	
	String df = EventDF()

	NVAR SearchMethod = $(df+"SearchMethod")
	NVAR Thrshld = $(df+"Thrshld")
	
	if (on == 1)
	
		on = MatchTemplateSelect()
		
		if (on > 0)
		
			MatchTemplateCall(0)
			
			SearchMethod = 1
			Thrshld = 4
			
			if (WaveExists($(df+"EV_MatchTmplt")) == 1)
			
				WaveStats /Q $(df+"EV_MatchTmplt")
				
				if (abs(V_min) > abs(V_max))
					SearchMethod = 2
					Thrshld = -4
				endif
				
			elseif ((searchMethod == 2) || (searchMethod == 4))
			
				SearchMethod = 2
				Thrshld = -4
				
			endif
			
		endif
		
	else
	
		MatchTemplateKill()
		
	endif
	
	SetNMvar(df+"MatchFlag", on)
	
	EventDisplay(1)
	UpdateEventTab()
	
End // MatchTemplateOn

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateSelect()
	Variable v1, v2, v3, v4, v5, dx
	String tname, vlist = "", df = EventDF()

	Prompt v1, "choose template:", popup "2-exp;alpha wave;your wave;"
	DoPrompt "Template Matching Search", v1
	
	if (V_flag == 1)
		return 0
	endif
	
	v2 = NumVarOrDefault(df+"MatchTau1", 2)
	v3 = NumVarOrDefault(df+"MatchTau2", 3)
	v4 = NumVarOrDefault(df+"MatchBsln", Nan)
	v5 = NumVarOrDefault(df+"MatchWform", 8)
	
	tname = StrVarOrDefault(df+"Template", "")
	
	if (numtype(v4) > 0)
		v4 = NumVarOrDefault(df+"BaseWin", 2)
	endif
	
	Prompt v2, "rise-time (ms):"
	Prompt v3, "decay-time (ms):"
	Prompt v4, "baseline time before waveform (ms):"
	Prompt v5, "template waveform time (ms):"
	
	switch(v1)
	
		case 1:
		
			DoPrompt "Create 2-exp Template", v2, v3, v4, v5
			
			if (V_flag == 1)
				return 0 // cancel
			endif
			
			SetNMvar(df+"MatchTau1", v2)
			SetNMvar(df+"MatchTau2", v3)
			SetNMvar(df+"MatchBsln", v4)
			SetNMvar(df+"MatchWform", v5)
			break
		
		case 2:
	
			Prompt v2, "tau (ms):"
			DoPrompt "Create Alpha-Wave Template", v2, v4, v5
			
			if (V_flag == 1)
				return 0 // cancel
			endif
			
			v3 = 0
			SetNMvar(df+"MatchTau1", v2)
			SetNMvar(df+"MatchBsln", v4)
			SetNMvar(df+"MatchWform", v5)
			break
		
		case 3:
	
			v4 = 0
			Prompt tname, "choose your pre-defined template wave:", popup WaveList("*", ";", WaveListText0())
			Prompt v4, "baseline of your pre-defined template wave (ms):"
			DoPrompt "Template Matching Search", tname, v4
			
			if (V_flag == 1)
				return 0 // cancel
			endif
			
			SetNMvar(df+"MatchBsln", v4)
			
			WaveStats /Q $tname
			
			if (V_max > 1)
				DoAlert 0, "Warning: your template waveform should be normalized to one and have zero baseline."
			endif
			
			break
		
	endswitch
	
	if ((v1 == 1) || (v1 == 2))
	
		dx = deltax($ChanDisplayWave(-1))
		
		vlist = NMCmdNum(v1, vlist)
		vlist = NMCmdNum(v2, vlist)
		vlist = NMCmdNum(v3, vlist)
		vlist = NMCmdNum(v4, vlist)
		vlist = NMCmdNum(v5, vlist)
		vlist = NMCmdNum(dx, vlist)
		NMCmdHistory("MatchTemplateMake", vlist)
		
		tname = MatchTemplateMake(v1, v2, v3, v4, v5, dx)
		
	endif
	
	if (strlen(tname) > 0)
		SetNMvar(df+"MatchFlag", v1)
		SetNMstr(df+"Template", tname)
	endif
	
	return v1

End // MatchTemplateSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S MatchTemplateMake(fxn, tau1, tau2, base, wform, dx)
	Variable fxn, tau1, tau2, base, wform, dx

	if (numtype(tau1*tau2*base*wform*dx) > 0)
		return "" // bad input parameters
	endif

	String wName = EventDF() + "TemplateWave"
	
	Make /D/O/N=((base + wform) / dx) $wName
	SetScale /P x, 0, dx, $wName
	
	Wave pulse = $wName
	
	switch(fxn)
		case 1: // 2-exp
			pulse = (1 - exp((base - x)/tau1)) * exp(((base - x))/tau2)
			break
		case 2: // alpha wave
			pulse = (x - base)*exp((base - x)/tau1)
			break
	endswitch
	
	pulse[0, x2pnt(pulse, base)] = 0
	
	Wavestats /Q pulse
	pulse /= v_max
	
	NMPlotWaves("EV_Tmplate", "Event Template", "msec", "", wName)
	
	NMHistory("Created Template Wave \"" + wName + "\"")

	return wName

End // MatchTemplateMake

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateCall(force)
	Variable force
	
	String vlist = "", df = EventDF()
	
	Variable MatchFlag = NumVarOrDefault(df+"MatchFlag", 0)
	
	String Template = StrVarOrDefault(df+"Template", "")
	
	String wName = CurrentWaveName()
	String tname = EventPrefix(wName + "_matched")
	String mtname = df+"EV_MatchTmplt"
	
	if ((MatchFlag == 0) || (WaveExists($wName) == 0))
		return 0
	endif
	
	if (force == 0)
	
		if (WaveExists($tname) == 1)
			Duplicate /O $tname $mtname
			return 0
		endif
		
		DoAlert 2, "Match template to \"" + wName + "\"? (This may take a few minutes...)"
		
		if (V_Flag != 1)
			if (WaveExists($mtname) == 1)
				Wave temp = $mtname
				temp = Nan
			endif
			return 0
		endif
		
	endif
	
	vlist = NMCmdStr(wName, vlist)
	vlist = NMCmdStr(Template, vlist)
	NMCmdHistory("MatchTemplateCompute", vlist)

	MatchTemplateCompute(wName, Template)
	Duplicate /O $mtname $tname

End // MatchTemplateCall

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateKill()
	Variable icnt

	String wName, wlist = WaveList("*_matched",";","")
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		wName = StringFromList(icnt, wlist)
		KillWaves /Z $wName
	endfor

End // MatchTemplateKill

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateCompute(wName, tName) // match template to wave
	String wName // wave name
	String  tName // template name
	
	String df = EventDF()
	
	if ((WaveExists($wName) == 0) || (WaveExists($tName) == 0))
		return -1
	endif
	
	if (deltax($wName) != deltax($tName))
		DoAlert 0, "Abort: template wave delta-x does not match that of wave to measure."
		return -1
	endif
	
	SetNMStr(NMDF()+"ProgressStr", "Matching Template...")
	
	CallProgress(-1)
	DoUpdate
	
	Duplicate /O $wName $(df+"EV_MatchTmplt")
	
	Execute /Z "MatchTemplate /C " + tName + " " + df+"EV_MatchTmplt"
	Execute /Z "MatchTemplate /C " + tName + ", " + df+"EV_MatchTmplt" // NEW FORMAT
	
	CallProgress(1)
	
End // MatchTemplateCompute

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieve(event) // retrieve event times from wave
	Variable event // event number
	
	Variable wbgn, wend
	String df = EventDF()
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)
	
	Variable BaseFlag = NumVarOrDefault(df+"BaseFlag", 0)
	Variable BaseWin = NumVarOrDefault(df+"BaseWin", BaseWin)
	Variable BaseDT = NumVarOrDefault(df+"BaseDT", BaseWin)
	
	NVAR EventNum = $(df+"EventNum"); NVAR ThreshX = $(df+"ThreshX")
	NVAR OnsetX = $(df+"OnsetX"); NVAR PeakX = $(df+"PeakX")
	NVAR SearchTime = $(df+"SearchTime")
	
	Wave ThreshT = $(df+"EV_ThreshT"); Wave ThreshY = $(df+"EV_ThreshY")
	Wave OnsetT = $(df+"EV_OnsetT"); Wave PeakT = $(df+"EV_PeakT")
	Wave ThisT = $(df+"EV_ThisT"); Wave ThisY = $(df+"EV_ThisY")
	Wave BaseT = $(df+"EV_BaseT"); Wave BaseY = $(df+"EV_BaseY")
	
	if ((event < 0) || (event >= numpnts(ThreshT)))
		return -1 // out of range
	endif
	
	EventNum = event
	ThreshX = ThreshT[event]; OnsetX = OnsetT[event]; PeakX = PeakT[event]
	ThisT = ThreshT[event]; ThisY = ThreshY[event]
	SearchTime = ThreshX
	
	if (BaseFlag == 1) // compute baseline display
		wbgn = ThreshX - BaseDT - BaseWin/2
		wend = ThreshX - BaseDT + BaseWin/2
		WaveStats /Q/R=(wbgn,wend) $ChanDisplayWave(-1)
		BaseY = V_avg
		BaseT[0] = wbgn
		BaseT[1] = wend
	endif
	
	
	EventCursors(1)
	
	Return 0

End // EventRetrieve

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSave()

	Variable success = EventSaveCurrent(1)
	UpdateEventTab()
	
	return success
	
End // EventSave

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSaveCurrent(cursors) // save event times to table
	Variable cursors // (0) save computed values (1) save values from cursors A, B
	
	Variable tbgn, tend
	String df = EventDF()
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)
	
	NVAR EventNum = $(df+"EventNum"); NVAR TableNum = $(df+"TableNum")
	NVAR OnsetX = $(df+"OnsetX"); NVAR OnsetY = $(df+"OnsetY")
	NVAR PeakX = $(df+"PeakX"); NVAR PeakY = $(df+"PeakY")
	
	if (TableNum == -1)
		return -1 // no table exists
	endif
	
	Wave waveN = $EventName("WaveN", -1); Wave baseY = $EventName("BaseY", -1)
	Wave thT = $EventName("ThreshT", -1); Wave thY = $EventName("ThreshY", -1)
	Wave onT = $EventName("onsetT", -1); Wave onY = $EventName("onsetY", -1)
	Wave pkT = $EventName("peakT", -1); Wave pkY = $EventName("peakY", -1)
	
	Wave EV_ThreshT = $(df+"EV_ThreshT"); Wave EV_ThreshY = $(df+"EV_ThreshY")
	Wave EV_OnsetT = $(df+"EV_OnsetT"); Wave EV_OnsetY = $(df+"EV_OnsetY")
	Wave EV_PeakT = $(df+"EV_PeakT"); Wave EV_PeakY = $(df+"EV_PeakY")
	Wave EV_ThisT = $(df+"EV_ThisT"); Wave EV_ThisY = $(df+"EV_ThisY")
	Wave EV_BaseY = $(df+"EV_BaseY")
	
	// get cursor points from graph (allows user to move onset/peak cursors)
	
	String gName = ChanGraphName(-1)
	
	Variable onTv = OnsetX, onYv = OnsetY, pkTv = PeakX, pkYv = PeakY
	
	tbgn = EventSearchBgn()
	tend = EventSearchEnd()
	
	if (cursors == 1)
		onTv = xcsr(A, gName); onYv = vcsr(A, gName)
		pkTv = xcsr(B, gName); pkYv = vcsr(B, gName)
	endif
	
	if ((numtype(onTv*onYv) != 0) || (onTv <= tbgn) || (onTv >= tend))
		onTv = Nan; onYv = Nan
	endif
	
	if ((numtype(pkTv*pkYv) != 0) || (pkTv <= tbgn) || (pkTv >= tend))
		pkTv = Nan; pkYv = Nan
	endif

	Variable event = EventFindSaved(EventName("WaveN", -1), df+"EV_ThreshT", EV_ThisT[0], 0.01, CurrentWave)

	if (event != -1)
	
		DoAlert 2, "alert: a similar event already exists. Do you want to replace it?"
		
		if (V_flag == 1)
			EventDelete(event)
		elseif (V_flag == 3)
			return -3 // cancel
		endif
		
	endif
	 
	Variable npnts1 = numpnts(thT)

	Redimension /N=(npnts1+1) waveN, thT, thY, onT, onY, pkT, pkY, baseY
	Redimension /N=(npnts1+1) EV_ThreshT, EV_ThreshY, EV_OnsetT, EV_OnsetY, EV_PeakT, EV_PeakY
	
	waveN[npnts1] = CurrentWave
	thT[npnts1] = EV_ThisT[0]; thY[npnts1] = EV_ThisY[0]
	onT[npnts1] = onTv; onY[npnts1] = onYv
	pkT[npnts1] = pkTv; pkY[npnts1] = pkYv
	baseY[npnts1] = EV_BaseY[0]
	
	EV_ThreshT[npnts1] = EV_ThisT[0]; EV_ThreshY[npnts1] = EV_ThisY[0]
	EV_OnsetT[npnts1] = onTv; EV_OnsetY[npnts1] = onYv
	EV_PeakT[npnts1] = pkTv; EV_PeakY[npnts1] = pkYv
	
	// sort waves according to thT
	
	Sort EV_ThreshT, EV_ThreshT, EV_ThreshY, EV_OnsetT, EV_OnsetY, EV_PeakT, EV_PeakY
	Sort {WaveN, thT}, waveN, thT, thY, onT, onY, pkT, pkY, baseY
	
	// remove NANs if they exist
	
	WaveStats /Q thT
	npnts1 = V_npnts
	
	Redimension /N=(npnts1) waveN, thT, thY, onT, onY, pkT, pkY, baseY
	Redimension /N=(npnts1) EV_ThreshT, EV_ThreshY, EV_OnsetT, EV_OnsetY, EV_PeakT, EV_PeakY
	
	EventNum = EventFindSaved(EventName("WaveN", -1), df+"EV_ThreshT", EV_ThisT[0], 0.01, CurrentWave)
	
	EventCount()
	
	return 0
	
End // EventSaveCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindSaved(nwName, ewName, event, twin, rcrdN) // locate saved event time
	String nwName // wave of record numbers
	String ewName // wave of event times
	Variable event // event time (ms)
	Variable twin // tolerance window
	Variable rcrdN // record number
	
	Variable icnt
	
	if ((WaveExists($nwName) == 0) || (WaveExists($ewName) == 0))
		return -1
	endif
	
	Wave waveN = $nwName
	Wave waveE = $ewName
	
	for (icnt = 0; icnt < numpnts(waveE); icnt += 1)
		if ((waveE[icnt] > event - twin) && (waveE[icnt] < event + twin) && (waveN[icnt] == rcrdN))
			return icnt
		endif
	endfor

	return -1

End // EventFindSaved

//****************************************************************
//****************************************************************
//****************************************************************

Function EventDelete(event) // delete saved event from table/display waves
	Variable event // event number
	
	String df = EventDF()
	
	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)
	
	Variable tableNum = NumVarOrDefault(df+"TableNum", -1)
	 
	 if (TableNum == -1)
	 	return -1 // no table exists
	 endif
	 
	Wave waveN = $EventName("WaveN", -1)
	
	Wave thT = $EventName("ThreshT", -1); Wave thY = $EventName("ThreshY", -1)
	Wave onT = $EventName("onsetT", -1); Wave onY = $EventName("onsetY", -1)
	Wave pkT = $EventName("peakT", -1); Wave pkY = $EventName("peakY", -1)
	Wave baseY = $EventName("BaseY", -1)
	
	Wave ThreshT = $(df+"EV_ThreshT"); Wave ThreshY = $(df+"EV_ThreshY")
	Wave OnsetT = $(df+"EV_OnsetT"); Wave OnsetY = $(df+"EV_OnsetY")
	Wave PeakT = $(df+"EV_PeakT"); Wave PeakY = $(df+"EV_PeakY")
	
	if ((event < 0) || (event >= numpnts(ThreshT)))
		return -1
	endif
	
	Variable event2 = EventFindSaved(EventName("WaveN", -1), df+"EV_ThreshT", ThreshT[event], 0.01, CurrentWave)
	
	DeletePoints event, 1, ThreshT, ThreshY, OnsetT, OnsetY, PeakT, PeakY
	
	if (event2 == -1)
		return -1
	endif
	
	//DeletePoints event2, 1, waveN, thT, thY, onT, onY, pkT, pkY, baseY
	waveN[event2] = Nan
	thT[event2] = Nan
	thY[event2] = Nan
	onT[event2] = Nan
	onY[event2] = Nan
	pkT[event2] = Nan
	pkY[event2] = Nan
	baseY[event2] = Nan
	
	EventCount()
	
	return 0

End // EventDelete

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableCall(fxn)
	String fxn
	
	String df = EventDF()
	String tlist = EventTableNumList()
	
	Variable tnum = NumVarOrDefault(df+"TableNum", -1)
	
	String tname = EventTableName(tnum)

	strswitch(fxn)
	
		case "New":
			NMCmdHistory("EventTableNew", "")
			EventTableNew()
			break
			
		case "Clear":
		
			if (ItemsInList(tlist) == 0)
				DoAlert 0, "No event tables to clear."
				break
			endif
			
			DoAlert 1, "Are you sure you want to clear " + tname + "?"
			
			if (V_flag == 1)
				NMCmdHistory("EventTableClear", NMCmdNum(tnum,""))
				EventTableClear(tnum)
			endif
			
			return 0
			
		case "Kill":
		
			if (ItemsInList(tlist) == 0)
				DoAlert 0, "No event tables to kill."
				break
			endif
			
			DoAlert 1, "Are you sure you want to kill " + tname + "?"
			
			if (V_flag == 1)
				NMCmdHistory("EventTableKill", NMCmdNum(tnum,""))
				EventTableKill(tnum)
			endif
			
			break
		
	endswitch
	
End // EventTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableNew()
	Variable tnum
	
	String df = EventDF()
	String tlist = EventTableNumList()

	if (ItemsInList(tlist) == 0)
		tnum = 0
	else
		tnum = 1 + str2num(StringFromList(ItemsInList(tlist)-1, tlist))
	endif
	
	SetNMvar(df+"TableNum", tnum)
	EventTable("make", tnum)
	EventCount()
	UpdateEventDisplay()
	UpdateEventTab()

End // EventTableNew

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableClear(tnum)
	Variable tnum // table num or (-1) for TableNum
	
	if (tnum < 0)
		tnum = NumVarOrDefault(EventDF() + "TableNum", -1)
	endif
	
	String tname = EventTableName(tnum)

	EventTable("clear", tnum)
	EventCount()
	UpdateEventDisplay()
	UpdateEventTab()
	
	return 0

End // EventTableClear

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableKill(tnum)
	Variable tnum // table num or (-1) for TableNum
	
	Variable items
	String tlist, df = EventDF()
	
	if (tnum < 0)
		tnum = NumVarOrDefault(df+"TableNum", -1)
	endif
	
	EventTable("kill", tnum)
	
	tlist = EventTableNumList()
	
	items = ItemsInList(tlist)
	
	if (items > 0)
		tnum = str2num(StringFromList(items-1, tlist))
	else
		tnum = -1
	endif
	
	SetNMvar(df+"TableNum", tnum)
	
	EventCount()
	UpdateEventDisplay()
	UpdateEventTab()
	
	return 0
	
End // EventTableKill

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableSelect(tnum)
	Variable tnum
	
	if ((numtype(tnum) > 0) || (tnum < 0))
		return -1
	endif

	SetNMvar(EventDF()+"TableNum", tnum)
	EventTable("make", tnum)
	UpdateEventTab()
	
	return 0
	
End // EventTableSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventTableName(tableNum)
	Variable tableNum
	
	return EventName(NMFolderListName("")+"_Table", tableNum)

End // EventTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTable(option, tableNum) // create table of event times
	String option // "make", "update", "clear" or "kill"
	Variable tableNum // table number
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable NumWaves = NumVarOrDefault("NumWaves", 0)
	
	String df = EventDF()
	
	if (tableNum == -1)
		tableNum = 0
	endif
	
	String suffix = ChanNum2Char(CurrentChan) + num2str(tableNum)
	String tName = EventTableName(tableNum)
	
	EventSet(option, tableNum)
	
	strswitch(option)
	
		case "make":
		
			if (WinType(tName) == 2)
				//DoWindow /F $tName
				return 0 // table already exists
			endif
			
			Make /O/N=0 EV_DumWave
			DoWindow /K $tName
			Edit /K=1/W=(0,0,0,0) EV_DumWave as "Event Table " + suffix
			DoWindow /C $tName
			Execute "ModifyTable title(Point)= \"Event\""
			RemoveFromTable EV_DumWave
			KillWaves /Z EV_DumWave
			
			SetCascadeXY(tName)
			
			break
			
		case "clear":
			DoWindow /F $tName
			break
			
		case "kill":
			DoWindow /K $tName
			break
	
	endswitch 
	
	EventTableWave(option, "WaveN", tableNum, tName)
	EventTableWave(option, "ThreshT", tableNum, tName)
	EventTableWave(option, "ThreshY", tableNum, tName)
	EventTableWave(option, "OnsetT", tableNum, tName)
	EventTableWave(option, "OnsetY", tableNum, tName)
	EventTableWave(option, "PeakT", tableNum, tName)
	EventTableWave(option, "PeakY", tableNum, tName)
	EventTableWave(option, "BaseY", tableNum, tName)
	
	strswitch(option)
	
		case "make":
		case "update":
	
			EventTableWave("remove", "WaveN", tableNum, tName)
			EventTableWave("remove", "ThreshT", tableNum, tName)
			EventTableWave("remove", "ThreshY", tableNum, tName)
			EventTableWave("remove", "OnsetT", tableNum, tName)
			EventTableWave("remove", "OnsetY", tableNum, tName)
			EventTableWave("remove", "PeakT", tableNum, tName)
			EventTableWave("remove", "PeakY", tableNum, tName)
			EventTableWave("remove", "BaseY", tableNum, tName)
			
			EventTableWave("append", "WaveN", tableNum, tName)
			
			EventTableWave("append", "ThreshT", tableNum, tName)
			EventTableWave("append", "ThreshY", tableNum, tName)
			
			if (NumVarOrDefault(df+"OnsetFlag", 0) == 1)
				EventTableWave("append", "OnsetT", tableNum, tName)
				EventTableWave("append", "OnsetY", tableNum, tName)
			endif
			
			if (NumVarOrDefault(df+"PeakFlag", 0) == 1)
				EventTableWave("append", "PeakT", tableNum, tName)
				EventTableWave("append", "PeakY", tableNum, tName)
			endif
			
			if (NumVarOrDefault(df+"BaseFlag", 0) == 1)
				EventTableWave("append", "BaseY", tableNum, tName)
			endif
		
	endswitch

End // EventTable

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableWave(option, wtype, tableNum, tname)
	String option // "make", "clear" or "kill"
	String wtype
	Variable tableNum
	String tname
	
	String wName = EventName(wtype, tableNum)
	
	strswitch(option)
	
		case "make":
			if (WaveExists($wName) == 0)
				Make /D/O/N=0 $wName
				EventNote(wName, wtype)
			endif
			break
			
		case "append":
			if ((WaveExists($wName) == 1) && (WinType(tName) == 2))
				//DoWindow /F $tName
				AppendToTable $wName
			endif
			break
			
		case "remove":
			if ((WaveExists($wName) == 1) && (WinType(tName) == 2))
				//DoWindow /F $tName
				RemoveFromTable $wName
			endif
			break
			
		case "clear":
			if (WaveExists($wName) == 1)
				Wave evWave = $wName
				Redimension /N=0 evWave
			endif
			break
			
		case "kill":
			KillWaves /Z $wName
			break
			
	endswitch

End // EventTableWave

//****************************************************************
//****************************************************************
//****************************************************************

Function EventNote(wName, wtype)
	String wName
	String wtype
	String wList
	
	String yl, xl = "Event#", txt = "", df = EventDF()
	
	String  wPrefix = StrVarOrDefault("CurrentPrefix", "Wave")
	
	String chX = ChanLabel(-1, "x", "")
	String chY = ChanLabel(-1, "y", "")
	
	Variable tbgn = EventSearchBgn()
	Variable tend = EventSearchEnd()
	
	NVAR SearchMethod = $(df+"SearchMethod")
	NVAR Thrshld = $(df+"Thrshld")
	
	NVAR BaseWin = $(df+"BaseWin")
	Variable BaseDT = NumVarOrDefault(df+"BaseDT", BaseWin)
	
	NVAR OnsetNstdv = $(df+"OnsetNstdv")
	NVAR OnsetWin = $(df+"OnsetWin"); NVAR OnsetAvg = $(df+"OnsetAvg")
	
	NVAR PeakNstdv = $(df+"PeakNstdv")
	NVAR PeakWin = $(df+"PeakWin"); NVAR PeakAvg = $(df+"PeakAvg")
	
	NVAR MatchFlag = $(df+"MatchFlag"); NVAR MatchWform = $(df+"MatchWform")
	NVAR MatchTau1 = $(df+"MatchTau1"); NVAR MatchTau2 = $(df+"MatchTau2")
	NVAR MatchBsln = $(df+"MatchBsln")
	
	SVAR Template = $(df+"Template")
	
	txt = "Event Prefix:" + wPrefix
	txt += "\rEvent Method:" + EventMethod(SearchMethod) + ";Event Thresh:" + num2str(thrshld) + ";"
	txt += "\rEvent Tbgn:" + num2str(tbgn) + ";Event Tend:" + num2str(tend) + ";"
	txt += "\rBase Avg:" + num2str(BaseWin) + ";Base DT:" + num2str(BaseDT) + ";"
	txt += "\rOnset Limit:" + num2str(OnsetWin) + ";Onset Avg:" + num2str(OnsetAvg) + ";"
	txt += "Onset Nstdv:" + num2str(OnsetNstdv) + ";"
	txt += "\rPeak Limit:" + num2str(PeakWin) + ";Peak Avg:" + num2str(PeakAvg) + ";"
	txt += "Peak Nstdv:" + num2str(PeakNstdv) + ";"
	
	switch(MatchFlag)
		case 1:
			txt += "\rMatch Template: 2-exp;Match Tau1:" + num2str(MatchTau1) + ";Match Tau2:" + num2str(MatchTau2) + ";"
			txt += "\rMatch Bsln:" + num2str(MatchBsln) + ";Match Win:" + num2str(MatchWform) + ";"
			break
		case 2: // tau1
			txt += "\rMatch Template: alpha;Match Tau1:" + num2str(MatchTau1) + ";"
			txt += "\rMatch Bsln:" + num2str(MatchBsln) + ";Match Win:" + num2str(MatchWform) + ";"
			break
		case 3: // template
			txt += "\rMatch Template:" + Template + ";"
			break
	endswitch
	
	strswitch(wtype)
	
		case "WaveN":
			yl = wPrefix + "#"
			break
			
		case "OnsetT":
			yl = chX
			break
			
		case "OnsetY":
			yl = chY
			break
			
		case "ThreshT":
			yl = chX
			break
			
		case "ThreshY":
			yl = chY
			break
			
		case "PeakT":
			yl = chX
			break
			
		case "PeakY":
			yl = chY
			break
			
		case "BaseY":
			yl = chY
			break
			
	endswitch
	
	NMNoteType(wName, "Event "+wtype, xl, yl, txt)
	
End // EventNote

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventName(prefix, tnum) // return appropriate event wave name
	String prefix // name prefix
	Variable tnum // table number  (-1) TableNum
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	
	Variable TableNum = NumVarOrDefault(EventDF() + "TableNum", 0)
	
	if (tnum == -1)
		tnum = TableNum
	endif
	
	if (StringMatch(prefix, "WavePrefix") == 1)
		prefix = StrVarOrDefault("WavePrefix", "Rcrd") + "N"
	endif
	
	return EventPrefix(prefix + "_" + ChanNum2Char(CurrentChan) + num2str(tnum))
	
End // EventName

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableNum(wName)
	String wName
	
	if (strlen(wName) == 0)
		return -1
	endif
	
	Variable icnt
	
	for (icnt = strlen(wName)-1; icnt >= 0; icnt -= 1)
		if (numtype(str2num(wName[icnt])) != 0)
			break // found letter
		endif
	endfor

	return str2num(wName[icnt+1, strlen(wName)-1])
	
End // EventTableNum

//****************************************************************
//****************************************************************
//****************************************************************

Function EventCount()
	Variable events
	
	String df = EventDF()
	
	Variable tableNum = NumVarOrDefault(df+"TableNum", -1)
	
	if (tableNum >= 0)
		events = numpnts($EventName("ThreshT", tableNum))
	endif
	
	SetNMvar(df+"NumEvents", events)
	
	return events

End // EventCount

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventTableList()
	Variable icnt, ipnt
	
	String wName, tList = ""
	String wList = WaveList(EventPrefix("ThreshY_*"), ";", WaveListText0())
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	for (icnt = 0; icnt < ItemsInList(wList); icnt += 1)
		wName = StringFromList(icnt, wList)
		ipnt = strsearch(wName, "ThreshY_", 0)
		tList = AddListItem("Event Table "+wName[ipnt+8, strlen(wName)], tList, ";", inf)
	endfor
	
	return tList

End // EventTableList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventTableNumList()
	Variable icnt, ipnt
	
	String wName, tList = ""
	String wList = WaveList(EventPrefix("ThreshY_*"), ";", WaveListText0())
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	for (icnt = 0; icnt < ItemsInList(wList); icnt += 1)
		wName = StringFromList(icnt, wList)
		ipnt = strsearch(wName, "ThreshY_", 0)
		tList = AddListItem(wName[ipnt+8, strlen(wName)], tList, ";", inf)
	endfor
	
	return tList

End // EventTableNumList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventSetName(tableNum)
	Variable tableNum // (-1) for current table
	
	String df = EventDF()
	
	if (tableNum < 0)
		tableNum = NumVarOrDefault(df+"TableNum", -1)
	endif
	
	if (tableNum >= 0)
		return "EV_Table" + num2str(tableNum)
	else
		return ""
	endif
	
End // EventSetName

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSetValue(waveNum)
	Variable waveNum // (-1) for current wave
	
	String df = EventDF()
	
	if (waveNum < 0)
		waveNum = NumVarOrDefault("CurrentWave", 0)
	endif
	
	String setName = EventSetName(-1)
	
	if (WaveExists($setName) == 0)
	
		return Nan
		
	else
	
		Wave set = $setName
		
		if ((waveNum >= 0) && (waveNum < numpnts(set)))
			return set[waveNum]
		endif
		
	endif
	
	return Nan

End // EventSetValue

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSet(option, tableNum)
	String option // "make", "clear" or "kill"
	Variable tableNum
	
	String setName = EventSetName(tableNum)
	
	strswitch(option)
		case "make":
			KillWaves /Z $setName
			NMSetsNew(setName)
			Wave temp = $setName
			temp = Nan
			break
		case "clear":
			Wave temp = $setName
			temp = Nan
			break
		case "kill":
			KillWaves /Z $setName
			break
	endswitch
	
End // EventSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventWaveList(tnum)
	Variable tnum

	Variable icnt
	String wName, wList, wRemove, tstr = num2str(tnum)
	
	String opstr = WaveListText0()
	
	if (tnum == -1)
		tstr = ""
	endif
	
	wList = WaveList("EV_*T_*" + tstr, ";", opstr)
	wRemove = WaveList("EV_Evnt*", ";", opstr)
	wRemove += WaveList("EV_*intvl*", ";", opstr)
	wRemove += WaveList("EV_*hist*", ";", opstr)
	
	for (icnt = 0; icnt < ItemsInList(wRemove); icnt += 1)
		wName = StringFromList(icnt, wRemove)
		wList = RemoveFromList(wName, wList)
	endfor

	for (icnt = ItemsInList(wList) - 1; icnt >= 0; icnt -= 1)
	
		wName = StringFromList(icnt, wList)
		
		WaveStats /Q $wName
		
		if (V_numNans == numpnts($wName))
			wList = RemoveFromList(wName, wList)
		endif
		
	endfor
	
	return wList

End // EventWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRepsCount(waveN)
	String waveN
	
	Variable icnt, jcnt, rcnt
	
	if (WaveExists($waveN) == 0)
		return 0
	endif
	
	Wave yWave = $waveN
	
	for (icnt = 0; icnt < NumVarOrDefault("NumWaves", 0); icnt += 1)
	
		for (jcnt = 0; jcnt < numpnts(yWave); jcnt += 1)
			if (yWave[jcnt] == icnt)
				rcnt += 1
				break
			endif
		endfor
	
	endfor
	
	return rcnt
	
End // EventRepsCount

//****************************************************************
//****************************************************************
//****************************************************************

Function Event2WaveCall()

	Variable tnum, ccnt, cbgn, cend, stopyesno = 2
	String wName, wName2, fname, xl, yl
	String wlist, prefix, vlist = "", df = EventDF()
	
	String opstr = WaveListText0()
	
	Variable tableNum = NumVarOrDefault(df+"TableNum", -1)
	
	Variable currChan = NumVarOrDefault("CurrentChan", 0)
	Variable nChan = NumVarOrDefault("NumChannels", 1)
	
	String wPrefix = StrVarOrDefault("CurrentPrefix", "")
	
	Variable before = NumVarOrDefault(df+"E2W_before", 2)
	Variable after = NumVarOrDefault(df+"E2W_after", 10)
	Variable stop = NumVarOrDefault(df+"E2W_stopAtNextEvent", 0)
	String chan = StrVarOrDefault(df+"E2W_chan", ChanNum2Char(currChan))
	
	String elist = EventWaveList(-1)
	
	if (ItemsInList(elist) == 0)
		DoAlert 0, "Detected no event waves."
		return -1
	endif
	
	wName = StringFromList(0, EventWaveList(TableNum))
	
	if (stop < 0)
		stopyesno = 1
	endif
	
	Prompt wName, "wave of event times:", popup elist
	Prompt before, "time before event (ms):"
	Prompt after, "time after event (ms):"
	Prompt stopyesno, "limit data to time before next spike?", popup "no;yes;"
	Prompt stop, "additional time to limit data before next spike (ms):"
	Prompt prefix, "enter new prefix name:"
	
	if (nChan > 1)
	
		Prompt chan, "channel waves to copy:", popup "All;" + ChanCharList(-1, ";")
		DoPrompt "Events to Waves", wName, before, after, stopyesno, chan
		
		cbgn = ChanChar2Num(chan)
		cend = ChanChar2Num(chan)
		
	else
	
		DoPrompt "Events to Waves", wName, before, after, stopyesno
		
		cbgn = currChan
		cend = currChan
		
	endif
	
	if (V_flag == 1)
		return -1
	endif
	
	if (stopyesno == 2)
	
		if (stop < 0)
			stop = 0
		endif
		
		DoPrompt "Events to Waves", stop
		
	else
	
		stop = -1
		
	endif
	
	if (V_flag == 1)
		return -1
	endif
	
	SetNMvar(df+"E2W_before", before)
	SetNMvar(df+"E2W_after", after)
	SetNMvar(df+"E2W_stopAtNextEvent", stop)
	SetNMstr(df+"E2W_chan", chan)
	
	tnum = EventTableNum(wName)
	
	wName2 = "EV_WaveN_" + wName[strlen(wName)-2, strlen(wName)-1]
	
	if (StringMatch(wPrefix, NMNoteStrByKey(wName, "Event Prefix")) == 0)
	
		DoAlert 1, "The current wave prefix does not match that of \"" + wName + "\". Do you want to continue?"
		
		if (V_Flag != 1)
			return 0
		endif
		
	endif
	
	if (WaveExists($wName2) == 0)
		DoAlert 0, "Abort: cannot locate wave " + wName2
		return -1
	endif
	
	prefix = "EV_Event" + num2str(tnum)
	
	if (StringMatch(chan, "All") == 1)
		cbgn = 0
		cend = nChan - 1
	endif
	
	for (ccnt = cbgn; ccnt <= cend; ccnt += 1)
	
		do
		
			fname = prefix + "*" + ChanNum2Char(ccnt) + "*"
			wlist = WaveList(fname, ";", opstr)
			
			if (ItemsInList(wlist) == 0)
				break // no name conflict
			else
			
				DoAlert 2, "Warning: waves already exist with prefix name \"" + prefix + "\". Do you want to overwrite these waves?"
				
				if (V_flag == 1)
				
					KillGlobals(GetDataFolder(1), fname, "001") // kill waves that exist
					break
					
				elseif (V_flag == 2)
				
					tnum += 1
					prefix = "EV_Event" + num2str(tnum)
					
					DoPrompt "Event to Waves", prefix
					
					if (V_flag == 1)
						return 0
					endif
					
				else
				
					return 0
					
				endif
				
			endif
		
		while (1)
		
		vlist = NMCmdStr(wName2, vlist)
		vlist = NMCmdStr(wName, vlist)
		vlist = NMCmdNum(before, vlist)
		vlist = NMCmdNum(after, vlist)
		vlist = NMCmdNum(stop, vlist)
		vlist = NMCmdNum(ccnt, vlist)
		vlist = NMCmdStr(prefix, vlist)
		
		NMCmdHistory("Event2Wave", vlist)
	
		wlist = Event2Wave(wName2, wName, before, after, stop, ccnt, prefix)
		
		if (strlen(wlist) == 0)
			return 0
		endif
		
		xl = ChanLabel(ccnt, "x", "")
		yl = ChanLabel(ccnt, "y", "")
		
		String gPrefix = prefix + "_" + NMFolderPrefix("") + ChanNum2Char(ccnt) + num2str(tnum) 
		String gName = CheckGraphName(gPrefix)
		String gTitle = NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt) + " : Events Table" + num2str(tnum) 
	
		NMPlotWaves(gName, gTitle, xl, yl, wlist)
		
	endfor

End // Event2WaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventHistoCall()
	
	if (ItemsInList(EventWaveList(-1)) == 0)
		DoAlert 0, "Detected no event waves."
		return -1
	endif
	
	Variable tnum
	String yl, wName = "", wName2 = "", vlist = ""
	String df = EventDF()
	
	Variable tableNum = NumVarOrDefault(df+"TableNum", -1)
	
	String select = StrVarOrDefault(df+"HistoSelect", "interval")
	
	Variable reps = 0
	Variable dx = 1
	Variable v1 = -inf
	Variable v2 = inf
	Variable v3 = 0
	Variable v4 = inf
	
	wName = StringFromList(0, EventWaveList(TableNum))
	
	Prompt wName, "wave:", popup EventWaveList(-1)
	Prompt select, "historgram type:", popup "time;interval;"
	
	Prompt v1, "include events from (ms):"
	Prompt v2, "include events to (ms):"
	Prompt v3, "minimum interval allowed (ms):"
	Prompt v4, "maximum interval allowed (ms):"
	
	Prompt dx, "histogram bin size (ms):"
	
	wName2 = EventName("WaveN", tnum)
	
	DoPrompt "Event Histogram", wName, select
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMstr(df+"HistoSelect", select)
	
	strswitch(select)
			
		case "time":
		
			yl = "Events / bin"
			
			Prompt yl, "y-axis:" popup "Events / bin;Events / sec;Probability;"
			Prompt reps, "verifiy events were collected from this number of waves:"
			
			DoPrompt "Event Histogram", dx, v1, v2, yl
			
			if (V_flag == 1)
				break
			endif
			
			strswitch(yl)
			
				case "Events / sec":
				case "Probability":
			
					if (WaveExists($wName2) == 1) 
						reps = EventRepsCount(wName2) // get number of waves
					endif
					
					DoPrompt "Event Time Histogram", reps
					
					if (V_flag == 1)
						break
					endif
					
					if (reps < 1)
						DoAlert 0, "Bad number of waves."
						return -1
					endif
				
			endswitch
			
			vlist = NMCmdStr(wName, vlist)
			vlist = NMCmdNum(reps, vlist)
			vlist = NMCmdNum(dx, vlist)
			vlist = NMCmdNum(v1, vlist)
			vlist = NMCmdNum(v2, vlist)
			vlist = NMCmdStr(yl, vlist)
			NMCmdHistory("EventHisto", vlist)
			
			EventHisto(wName, reps, dx, v1, v2, yl)
			
			break
			
		case "interval":
			
			DoPrompt "Event Interval Histogram", dx, v1, v2, v3, v4
			
			if (V_flag == 1)
				break
			endif
			
			vlist = NMCmdStr(wName, vlist)
			vlist = NMCmdNum(dx, vlist)
			vlist = NMCmdNum(v1, vlist)
			vlist = NMCmdNum(v2, vlist)
			vlist = NMCmdNum(v3, vlist)
			vlist = NMCmdNum(v4, vlist)
			
			NMCmdHistory("EventHistoIntvl", vlist)
			
			EventHistoIntvl(wName, dx, v1, v2, v3, v4)
			
			break
			
	endswitch

End // EventHistoCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventHisto(wName, reps, bin, winB, winE, yl)
	String wName // wave name
	Variable reps // number of repititions (number of waves)
	Variable bin // histo bin size
	Variable winB, winE // begin, end time
	String yl // y-axis dimensions (see switch below)
	
	Variable nbins
	String df = EventDF()
	
	String xl = NMNoteLabel("y", wName, "msec")
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	
	String hName = NextWaveName("", wName + "_hist", -1, NMOverWrite())
	String gPrefix = wName + "_" + NMFolderPrefix("") + "PSTH"
	String gName = NextGraphName(gPrefix, -1, 0) // no overwrite, due to long name
	String gTitle = NMFolderListName("") + " : " + wName + " Histogram"
	
	Make /D/O/N=1 $hName
	
	WaveStats /Q $wName
	
	nbins = ceil((V_max - V_min) / bin)
	
	Histogram /B={V_min, bin, nbins} $wName, $hName
	
	if (WaveExists($hName) == 0)
		return -1
	endif
	
	wave histo = $hName
	
	strswitch(yl)
		case "Events / bin":
			break
		case "Events / sec":
			histo /= reps * bin * 0.001
			break
		case "Probability":
			histo /= reps
			break
	endswitch
	
	NMPlotWaves(gName, gTitle, xl, yl, hName)
	
	ModifyGraph mode=5, hbFill=2
	
	NMNoteType(hName, "Event Histogram", xl, yl, "Func:EventHisto")
	
	Note $hName, "Histo Bin:" + num2str(bin) + ";Histo Tbgn:" + num2str(winB) + ";Histo Tend:" + num2str(winE) + ";"
	Note $hName, "Histo Source:" + wName
	
End // EventHisto
	
//****************************************************************
//****************************************************************
//****************************************************************

Function EventHistoIntvl(wName, bin, winB, winE, isiMin, isiMax)
	String wName // wave name
	Variable bin // histo bin size
	Variable winB, winE
	Variable isiMin, isiMax
	
	Variable icnt, nbins
	String df = EventDF()
	String yl = "Intvls / bin"
	String xl = NMNoteLabel("y", wName, "msec")
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	
	if (numtype(winE) > 0)
		winE = NumVarOrDefault(df+"SearchEnd", 0)
	endif
	
	if (numtype(isiMax) > 0)
		isiMax = NumVarOrDefault(df+"SearchEnd", 0)
	endif
	
	Variable events = Time2Intervals(wName, winB, winE, isiMin, isiMax) // results saved in U_INTVLS (function in Utility.ipf)

	if (events <= 0)
		DoAlert 0, "No inter-event intervals detected."
		return -1
	endif
	
	String hName = NextWaveName("", wName + "_intvl", -1, NMOverWrite())
	String gPrefix = wName + "_" + NMFolderPrefix("") + "ISIH"
	String gName = NextGraphName(gPrefix, -1, 0) // no overwrite, due to long name
	String gTitle = NMFolderListName("") + " : " + wName + " Interval Histogram"

	Make /D/O/N=1 $hName
	
	WaveStats /Q U_INTVLS
	
	nbins = ceil((V_max - isiMin) / bin)
	
	Histogram /B={isiMin, bin, nbins} U_INTVLS, $hName
	
	if (WaveExists($hName) == 0)
		return -1
	endif
	
	Wave histo = $hName
	
	for (icnt = numpnts(histo) - 1; icnt >= 0; icnt -= 1)
		if (histo[icnt] > 0)
			break
		elseif (histo[icnt] == 0)
			histo[icnt] = Nan
		endif
	endfor
	
	WaveStats /Q histo
	
	Redimension /N=(V_npnts) histo
	
	NMPlotWaves(gName, gTitle, xl, yl, hName)
	
	ModifyGraph mode=5, hbFill=2
	
	WaveStats /Q U_INTVLS
	
	SetAxis bottom 0, (V_max*1.1)
	
	NMNoteType(hName, "Event Intvl Histogram", xl, yl, "Func:EventHistoIntvl")
	
	Note $hName, "Intvl Bin:" + num2str(bin) + ";Intvl Tbgn:" + num2str(winB) + ";Intvl Tend:" + num2str(winE) + ";"
	Note $hName, "Intvl Min:" + num2str(isiMin) + ";Intvl Max:" + num2str(isiMax) + ";"
	Note $hName, "Intvl Source:" + wName
	
	Print "\rIntervals stored in wave U_INTVLS"

End // EventHistoIntvl

//****************************************************************
//****************************************************************
//****************************************************************