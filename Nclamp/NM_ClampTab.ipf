#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Tab Control // Stim Pulse Gen Functions
//	To be run with NeuroMatic, v1.91
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
//	Began 1 July 2003
//	Last modified 03 March 2006
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabEnable(enable)
	Variable enable
	
	if (enable == 1)
	
		if (CheckClampTabDF() == 1)
			CheckClampTab()
		endif
		
		ClampTabMake() // make controls if necessary
		ClampTabUpdate()
		
	else
	
		ClampTabDisable()
		
	endif
	
End // ClampTabEnable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTabDF() // full-path name of TabObjects folder
	return ClampDF() + "TabObjects:"
End // ClampTabDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckClampTabDF() // check to see if folder exists
	String tdf = ClampTabDF()

	if (DataFolderExists(tdf) == 0)
		NewDataFolder $LastPathColon(tdf, 0)
		return 1
	endif
	
	return 0

End // CheckClampTabDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckClampTab() // declare Clamp Tab global variables
	String tdf = ClampTabDF(), cdf = ClampDF()
	
	if (DataFolderExists(tdf) == 0)
		return 0 // folder doesnt exist
	endif
	
	CheckNMstr(tdf+"TabList", "CF,CT0_;Tau,CT1_;ADC,CT2_;DAC,CT2_;TTL,CT2_;PG,CT5_;NMPanel,CT_Tab;")
	
	CheckNMvar(tdf+"CurrentTab", 0)
	CheckNMvar(tdf+"StatsOn", 0)
	
	// tau tab
	
	CheckNMvar(tdf+"CurrentBoard", 0)
	CheckNMvar(tdf+"NumStimWaves", 1)
	CheckNMvar(tdf+"InterStimTime", 0)
	CheckNMvar(tdf+"WaveLength", 100)
	CheckNMvar(tdf+"NumStimReps", 1)
	CheckNMvar(tdf+"InterRepTime", 0)
	CheckNMvar(tdf+"SampleInterval", 1)
	CheckNMvar(tdf+"SamplesPerWave", 100)
	CheckNMvar(tdf+"StimRate", 0)
	CheckNMvar(tdf+"RepRate", 0)
	
	CheckNMvar(tdf+"TotalTime", 0)
	
	// ADC, DAC, TTL tabs
	
	CheckNMstr(tdf+"UnitsList", "V;mV;A;nA;pA;S;nS;pS;")
	CheckNMstr(tdf+"DataPrefix", "Record")
	
	CheckNMstr(tdf+"IOname", "")
	CheckNMvar(tdf+"IOnum", 0)
	CheckNMvar(tdf+"IOchan", 0)
	CheckNMvar(tdf+"IOscale", 1)
	CheckNMvar(tdf+"IOgain", 1)
	
	// pulse gen tab
	
	CheckNMstr(tdf+"PulsePrefix", "")
	CheckNMvar(tdf+"PulseShape", 1)
	CheckNMvar(tdf+"PulseWaveN", 0)
	CheckNMvar(tdf+"PulseWaveND", 0)
	CheckNMvar(tdf+"PulseAmp", 1)
	CheckNMvar(tdf+"PulseAmpD", 0)
	CheckNMvar(tdf+"PulseOnset", 0)
	CheckNMvar(tdf+"PulseOnsetD", 0)
	CheckNMvar(tdf+"PulseWidth", 1)
	CheckNMvar(tdf+"PulseWidthD", 0)
	CheckNMvar(tdf+"PulseTau2", 0)
	CheckNMvar(tdf+"PulseTau2D", 0)
	
	// pulse/stim display variables
	
	CheckNMvar(tdf+"PulseAllOutputs", 0)
	CheckNMvar(tdf+"PulseAllWaves", 1)
	CheckNMvar(tdf+"PulseWaveNum", 0)
	CheckNMvar(tdf+"PulseDisplay", NumVarOrDefault(cdf+"PulseDisplay", 1))
	
End // CheckClampTab

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabMake()

	Variable icnt, x0, y0, xinc, yinc
	Variable nDACon = 4
	Variable nADCon = 8
	Variable nTTLon = 4
	
	String cdf = ClampDF(), tdf = ClampTabDF(), ndf = NotesDF()

	ControlInfo /W=NMPanel CT_StimList 
	
	if (V_Flag != 0)
		return 0 // tab controls exist, return here
	endif
	
	DoWindow /F NMPanel
	
	x0 = 20; y0 = 190; yinc = 40
	
	PopupMenu CT_StimMenu, pos={x0+20,y0}, size={15,0}, bodyWidth= 20, mode=1, title="stim:", proc=StimMenu
	PopupMenu CT_StimMenu, value=" ;Open;Save;Save As;Close;Reload;---;Open All;Save All;Close All;---;New;Copy;Rename;---;Retrieve;---;Set Stim Path;Set Stim List;"
	
	PopupMenu CT_StimList, pos={x0+215,y0}, size={0,0}, bodyWidth=170, mode=1, value=" ", proc=StimListPopup
	
	Checkbox CT_StimCheck, pos={x0+225,y0+4}, title="chain", size={10,20}
	Checkbox CT_StimCheck, value=0, proc=ClampCheckBox
	
	Checkbox CT_StatsCheck, pos={x0+225,y0+yinc}, title="stats", size={10,20}
	Checkbox CT_StatsCheck, value=0, proc=ClampCheckBox
	
	Button CT_Note, title="Note", pos={x0,y0+yinc}, size={45,20}, proc=ClampButton
	Button CT_StartPreview, title="Preview", pos={x0+60,y0+yinc}, size={65,20}, proc=ClampButton
	Button CT_StartRecord, title="Record", pos={x0+135,y0+yinc}, size={65,20}, proc=ClampButton
	
	SetVariable CT_ErrorMssg, title= " ", pos={x0,590}, size={260,50}, value=$(cdf+"ClampErrorStr")
	
	TabControl CT_Tab, pos={0,270}, size={300, 640}, fsize=12, proc=ClampTabControl
	
	MakeTabs(StrVarOrDefault(tdf+"TabList", ""))
	
	y0 =305; xinc = 15; yinc = 25
	
	PopupMenu CT0_InterfaceMenu, pos={x0+200,y0}, size={0,0}, bodyWidth=140, mode=1, proc=ClampInterfacePopup
	PopupMenu CT0_InterfaceMenu, value="Demo;NIDAQ;ITC18;ITC16;"
	
	Button CT0_Tgain, title="Tgain", pos={x0+215,y0}, size={45,20}, proc=ClampButton
	
	y0 = 335
	
	GroupBox CT0_DataGrp, title = "Folders", pos={x0,y0}, size={260,125}
	
	SetVariable CT0_FileNameSet, title= "prefix", pos={x0+xinc,y0+1*yinc}, size={125,50}
	SetVariable CT0_FileNameSet, value=$(cdf+"FolderPrefix"), proc=ClampSetVariable
	
	SetVariable CT0_FileCellSet, title= "cell", pos={x0+150,y0+1*yinc}, size={65,50}
	SetVariable CT0_FileCellSet, limits={0,inf,0}, value=$(cdf+"DataFileCell"), proc=ClampSetVariable
	
	Button CT0_NewCell, title="+", pos={x0+225,y0+1*yinc-2}, size={20,20}, proc=ClampButton
	
	SetVariable CT0_StimNameSet, title= "stim tag", pos={x0+xinc,y0+2*yinc}, size={125,50}
	SetVariable CT0_StimNameSet, value=$(cdf+"StimTag"), proc=ClampSetVariable
	
	SetVariable CT0_FileSeqSet, title= "seq", pos={x0+150,y0+2*yinc}, size={65,50}
	SetVariable CT0_FileSeqSet, limits={0,inf,0}, value=$(cdf+"DataFileSeq")
	
	SetVariable CT0_FilePathSet, title= "save to", pos={x0+xinc,y0+3*yinc}, size={230,50}
	SetVariable CT0_FilePathSet, value=$(cdf+"ClampPath"), proc=ClampSetVariable
	
	Checkbox CT0_SaveConfig, pos={x0+xinc,y0+4*yinc}, title="save", size={10,20}
	Checkbox CT0_SaveConfig, value=0, proc=ClampCFCheckBox
	
	Checkbox CT0_CloseFolder, pos={x0+155,y0+4*yinc}, title="close previous", size={10,20}
	Checkbox CT0_CloseFolder, value=0, proc=ClampCFCheckBox
	
	y0 = 470
	
	GroupBox CT0_NotesGrp, title = "Notes", pos={x0,y0}, size={150,105}
	
	SetVariable CT0_UserName, title= "name", pos={x0+xinc,y0+1*yinc}, size={120,50}
	SetVariable CT0_UserName, value=$(ndf+"H_Name"), proc=ClampSetVariable
	
	//SetVariable CT0_UserLab, title= "lab", pos={x0+xinc,y0+2*yinc}, size={120,50}
	//SetVariable CT0_UserLab, value=$(ndf+"H_Lab"), proc=ClampSetVariable
	
	SetVariable CT0_ExpTitle, title= "title", pos={x0+xinc,y0+2*yinc}, size={120,50}
	SetVariable CT0_ExpTitle, value=$(ndf+"H_Title"), proc=ClampSetVariable
	
	Button CT0_NotesEdit, title="Edit All", pos={x0+50,y0+3*yinc}, size={55,20}, proc=ClampButton
	
	GroupBox CT0_LogGrp, title = "Log", pos={x0+165,y0}, size={95,105}
	
	PopupMenu CT0_LogMenu, pos={x0+245,y0+1*yinc}, size={0,0}, bodyWidth=65, mode=1, proc=ClampLogPopup
	PopupMenu CT0_LogMenu, value="Display;---;None;Text;Table;Both;"
	
	Checkbox CT0_LogSave, pos={x0+180,y0+2.8*yinc}, title="auto save", size={10,20}
	Checkbox CT0_LogSave, value=0, proc=ClampCFCheckBox
	
	y0 = 305; xinc = 15; yinc = 20
	
	PopupMenu CT1_AcqMode,title=" ", pos={x0+120,y0},size={0,0}, bodywidth=100
	PopupMenu CT1_AcqMode,mode=1,value="continuous;episodic;", proc=StimModePopup, disable=1
	
	PopupMenu CT1_TauBoard,title=" ", pos={x0+240,y0},size={0,0}, bodywidth=100
	PopupMenu CT1_TauBoard,mode=1,value=" ", proc=StimBoardPopup, disable=1
	
	y0 = 340
	
	GroupBox CT1_WaveGrp, title = "Waves", pos={x0,y0}, size={260,135}, disable=1
	
	SetVariable CT1_NumStimWaves, title= "num", pos={x0+xinc,y0+3*yinc}, size={75,50}, limits={1,inf,0}
	SetVariable CT1_NumStimWaves, value=$(tdf+"NumStimWaves"), proc=StimSetTau, disable=1
	
	SetVariable CT1_WaveLength, title= "wave length (ms)", pos={x0+xinc+90,y0+1*yinc}, size={140,50}
	SetVariable CT1_WaveLength, limits={0.001,inf,0}, value=$(tdf+"WaveLength"), proc=StimSetTau, disable=1
	
	SetVariable CT1_SampleInterval, title= "sample intvl (ms)", pos={x0+xinc+90,y0+2*yinc}, size={140,50}
	SetVariable CT1_SampleInterval, limits={0.001,inf,0}, value=$(tdf+"SampleInterval"), proc=StimSetTau, disable=1
	
	SetVariable CT1_SamplesPerWave, title= "samples/wave :", pos={x0+xinc+90,y0+3*yinc}, size={140,50}
	SetVariable CT1_SamplesPerWave, limits={0,inf,0}, value=$(tdf+"SamplesPerWave"), proc=StimSetTau, disable=1, frame=0
	
	SetVariable CT1_InterStimTime, title= "interlude (ms)", pos={x0+xinc+90,y0+5*yinc-10}, size={140,50}
	SetVariable CT1_InterStimTime, limits={0,inf,0}, value=$(tdf+"InterStimTime"), proc=StimSetTau, disable=1
	
	SetVariable CT1_StimRate, title= "stim rate (Hz) :", pos={x0+xinc+90,y0+6*yinc-10}, size={140,50}
	SetVariable CT1_StimRate, limits={0,inf,0}, value=$(tdf+"StimRate"), proc=StimSetTau, disable=1, frame=0
	
	y0 = 490
	
	GroupBox CT1_RepGrp, title = "Reps", pos={x0,y0}, size={260,85}, disable=1
	
	SetVariable CT1_NumStimReps, title= "num", pos={x0+xinc,y0+2*yinc}, size={75,50}
	SetVariable CT1_NumStimReps, limits={1,inf,0}, value=$(tdf+"NumStimReps"), proc=StimSetTau, disable=1
	
	SetVariable CT1_InterRepTime, title= "interlude (ms)", pos={x0+xinc+90,y0+yinc}, size={140,50}
	SetVariable CT1_InterRepTime, limits={0,inf,0}, value=$(tdf+"InterRepTime"), proc=StimSetTau, disable=1
	
	SetVariable CT1_RepRate, title= "rep rate (Hz) :", pos={x0+xinc+90,y0+2*yinc}, size={140,50}
	SetVariable CT1_RepRate, limits={0,inf,0}, value=$(tdf+"RepRate"), proc=StimSetTau, disable=1, frame=0
	
	SetVariable CT1_TotalTime, title= "total time (sec) :", pos={x0+xinc+90,y0+3*yinc}, size={140,50}
	SetVariable CT1_TotalTime, limits={0,inf,0}, value=$(tdf+"TotalTime"), disable=1, frame=0
	
	y0 = 305; xinc = 35
	
	Button CT2_IO0, title="0", pos={x0+0*xinc,y0}, size={25,20}, proc=StimActivateButton, disable=1
	Button CT2_IO1, title="1", pos={x0+1*xinc,y0}, size={25,20}, proc=StimActivateButton, disable=1
	Button CT2_IO2, title="2", pos={x0+2*xinc,y0}, size={25,20}, proc=StimActivateButton, disable=1
	Button CT2_IO3, title="3", pos={x0+3*xinc,y0}, size={25,20}, proc=StimActivateButton, disable=1
	Button CT2_IO4, title="4", pos={x0+4*xinc,y0}, size={25,20}, proc=StimActivateButton, disable=1
	Button CT2_IO5, title="5", pos={x0+5*xinc,y0}, size={25,20}, proc=StimActivateButton, disable=1
	
	SetVariable CT2_IOnum,pos={x0+6*xinc+5,y0+2},size={45,15},limits={0,20,1},title=" "
	SetVariable CT2_IOnum, fsize=12, value=$(tdf+"IOnum"), proc=StimSetVar, disable=1
	
	y0 = 335; xinc = 15; yinc = 30
	
	GroupBox CT2_IOgrp, title = "Input Config", pos={x0,y0+5}, size={260,145}, disable=1
	
	Checkbox CT2_IOactive, pos={x0+xinc,y0+1*yinc}, title="active", size={10,20}
	Checkbox CT2_IOactive, value=0, proc=StimActivateCheckBox, disable=1
	
	Checkbox CT2_ADCpresamp, pos={x0+140,y0+1*yinc}, title="pre-sample", size={10,20}
	Checkbox CT2_ADCpresamp, value=0, proc=StimPreSampCheckBox, disable=1
	
	PopupMenu CT2_IOboard,title="board", pos={x0+149,y0+2*yinc-4},size={0,0}, bodywidth=100
	PopupMenu CT2_IOboard,mode=1,value=" ", proc=StimBoardPopup, disable=1
	
	PopupMenu CT2_IOunits,title="units", pos={x0+245,y0+2*yinc-4},size={0,0}, proc=StimUnitsPopup
	PopupMenu CT2_IOunits,bodywidth=55,mode=1,value="V;", disable=1
	
	SetVariable CT2_IOchan, title= "chan", pos={x0+xinc,y0+3*yinc}, size={75,50}, limits={0,inf,1}
	SetVariable CT2_IOchan, value=$(tdf+"IOchan"), proc=StimSetVar, disable=1
	
	SetVariable CT2_IOscale, title= "scale (V/V)", pos={x0+105,y0+3*yinc}, size={140,50}, limits={-inf,inf,0}
	SetVariable CT2_IOscale, value=$(tdf+"IOscale"), proc=StimSetVar, disable=1
	
	SetVariable CT2_IOname, title= "name", pos={x0+xinc,y0+4*yinc}, size={140,50}
	SetVariable CT2_IOname, value=$(tdf+"IOname"), proc=StimSetVar, disable=1
	
	SetVariable CT2_IOgain, title= "gain", pos={x0+170,y0+4*yinc}, size={75,50}, limits={1,inf,1}
	SetVariable CT2_IOgain, value=$(tdf+"IOgain"), proc=StimSetVar, disable=1
	
	y0 = 470; yinc = 40
	
	PopupMenu CT2_PreAnalysis,title="Analysis :", pos={x0+105,y0+1*yinc-5},size={0,0}, bodywidth=55
	PopupMenu CT2_PreAnalysis,mode=1,value="Pre", proc=StimFxnPopup, disable=1
	
	PopupMenu CT2_InterAnalysis,title=" ", pos={x0+180,y0+1*yinc-5},size={0,0}, bodywidth=55
	PopupMenu CT2_InterAnalysis,mode=1,value="Inter", proc=StimFxnPopup, disable=1
	
	PopupMenu CT2_PostAnalysis,title=" ", pos={x0+255,y0+1*yinc-5},size={0,0}, bodywidth=55
	PopupMenu CT2_PostAnalysis,mode=1,value="Post", proc=StimFxnPopup, disable=1
	
	SetVariable CT2_ADCprefix, title= "wave prefix :", pos={x0+10,y0+2*yinc}, size={130,50}
	SetVariable CT2_ADCprefix, value=$(tdf+"DataPrefix"), proc=StimSetVar, disable=1
	
	Button CT2_IOtable, title="Table", pos={x0+165,y0+2*yinc-2}, size={75,20}, proc=PulseTableButton, disable=1
	
	x0 = 30; xinc = 105; y0 = 305; yinc = 30
	
	PopupMenu CT5_WavePrefix,pos={x0+225,y0},size={0,0}, bodywidth=175, proc=PulsePrefixPopup, disable=1
	PopupMenu CT5_WavePrefix,mode=1,title="Output",value=""
	
	y0 = 355
	
	GroupBox CT5_PulseGrp, title = "Pulse", pos={x0,y0}, size={240,115}, disable=1
	
	x0 += 25
	
	Button CT5_New, title="New", pos={x0,y0+1*yinc-6}, size={85,20}, proc=PulseButton, disable=1
	Button CT5_Clear, title="Clear", pos={x0+xinc,y0+1*yinc-6}, size={85,20}, proc=PulseButton, disable=1
	Button CT5_Edit, title="Edit", pos={x0,y0+2*yinc-6}, size={85,20}, proc=PulseButton, disable=1
	Button CT5_Train, title="Train", pos={x0+xinc,y0+2*yinc-6}, size={85,20}, proc=PulseButton, disable=1
	Button CT5_Table, title="Pulse Table", pos={x0+45,y0+3*yinc-6}, size={100,20}, proc=PulseButton, disable=1
	
	x0 = 30; y0 = 460; yinc = 40
	
	Checkbox CT5_Display, pos={x0+80,y0+yinc}, title="auto graph", size={10,20}
	Checkbox CT5_Display, value=1, proc=PulseCheckBox, disable=1
	
	Checkbox CT5_PulseOff, pos={x0+80,y0+2*yinc}, title="use \"my\" waves", size={10,20}, proc=PulseCheckBox
	Checkbox CT5_PulseOff, value=1, disable=1
	
	SetNMvar(tdf+"CurrentTab", 0)

End // ClampTabMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabUpdate()
	
	ControlInfo /W=NMPanel CT_StimList 
	
	if (V_Flag == 0)
		return 0 // tab controls dont exist
	endif

	String cdf = ClampDF(), tdf = ClampTabDF(), sdf = StimDF()
	
	StimCurrentCheck()
	
	String flist = NMFolderList(cdf,"NMStim")
	String CurrentStim = StimCurrent()
	
	Variable slct = WhichListItemLax(CurrentStim, flist, ";") + 1
	
	PopupMenu CT_StimList, win=NMPanel, mode=slct, value=NMFolderList(ClampDF(),"NMStim")
	
	Checkbox CT_StimCheck, win=NMPanel, value=StimChainOn()
	Checkbox CT_StatsCheck, win=NMPanel, value=StimStatsOn()
	
	Variable CurrentTab = NumVarOrDefault(tdf+"CurrentTab", 0)
	
	String TabList = StrVarOrDefault(tdf+"TabList", "")
	String TabName = StringFromList(CurrentTab, TabList)
	TabName = StringFromList(0, TabName, ",") // current tab name
	
	EnableTab(CurrentTab, TabList, 1)
	
	Execute /Z TabName + "(1)"

End // ClampTabUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabDisable()
	Variable icnt
	
	String tlist = StrVarOrDefault(ClampTabDF()+"TabList", "")

	for (icnt = 0; icnt < ItemsInList(tlist)-1; icnt += 1)
		EnableTab(icnt, tlist, 0) // disable tab controls
	endfor

End // ClampTabDisable

//****************************************************************
//****************************************************************
//****************************************************************

Function StimMenu(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ClampError("")
	
	Variable new, ask, stimexists
	
	String slist, sname = "", newname = ""
	String gdf, cdf = ClampDF(), sdf = StimDF()
	
	String currentStim = StimCurrent()
	String currentFile = StrVarOrDefault(sdf+"CurrentFile", "")
	
	if (strlen(currentStim) > 0)
		stimexists = 1
	endif
	
	strswitch(popStr)
		
		case "New":
		
			sname = StimNew(cdf, "")
			
			if (strlen(sname) == 0)
				return 0
			endif
			
			StimSetCurrent(sname)
			
			break
			
		case "Open":
		
			sname = StimOpen(1, cdf, "") // open with dialogue
			
			if (strlen(sname) == 0)
				return 0
			endif
			
			break
			
		case "Reload":
			
			StimClose(cdf, currentStim)
			sname = StimOpen(0, cdf, currentFile) // open without dialogue
			
			if (strlen(sname) == 0)
				return 0
			endif
			
			break
			
		case "Open All":
			StimOpenAll(1, cdf, "StimPath")
			break
			
		case "Save As":
			new = 1; ask = 1
	
		case "Save":
		
			if (stimexists == 0)
				return 0
			endif
			
			if (StimStatsOn() == 1)
				ClampStatsSave(sdf)
			endif
			
			ClampGraphsCopy(-1, 1)
			
			sname = StimSave(ask, new, cdf, currentStim)
			
			if (strlen(sname) == 0)
				return 0 // cancel
			endif
			
			if (StringMatch(sname, currentStim) == 1)
				return 0 // nothing to update
			endif
			
			StimSetCurrent(sname)
			
			break
			
		case "Save All":
		
			slist = NMFolderList(cdf,"NMStim")
			
			if (ItemsInList(slist) == 0)
				return 0
			endif
		
			DoAlert 1, "Save all stimulus protocals to disk?"
			
			if (V_flag != 1)
				return 0
			endif
			
			if (StimStatsOn() == 1)
				ClampStatsSave(StimDF())
			endif
			
			ClampGraphsCopy(-1, 1)
			
			StimSaveList(ask, new, cdf, slist)
		
			break
			
		case "Close":
		case "Kill":
			
			slist = NMFolderList(cdf,"NMStim")
			slist = RemoveFromList(currentStim, slist)
			
			if (strlen(CurrentStim) == 0)
				return 0
			endif
			
			if (StimClose(cdf, currentStim) == -1)
				break
			endif
				
			if (ItemsInList(slist) > 0)
				StimSetCurrent(StringFromList(0,slist)) // set to new stim
			else
				ClampTabUpdate()
			endif
			
			break
			
		case "Close All":
		case "Kill All":
			
			slist = NMFolderList(cdf,"NMStim")
			
			if (ItemsInList(slist) == 0)
				return 0
			endif
			
			StimClose(cdf, slist)
			
			ClampTabUpdate()
			
			break
			
		case "Copy":
		
			if (stimexists == 0)
				return 0
			endif
			
			sname = currentStim + "_copy"
			
			Prompt sname, "new stimulus name:"
			DoPrompt "Copy Stimulus Protocol", sname
			
			if (V_flag == 1)
				return 0 // cancel
			endif
			
			StimCopy(cdf, currentStim, sname)
			StimSetCurrent(sname)
			
			break
			
		case "Rename":
		
			if (stimexists == 0)
				return 0
			endif
			
			sname = currentStim
			
			Prompt sname, "rename stimulus as:"
			DoPrompt "Rename Stimulus Protocol", sname
			
			if ((V_flag == 1) || (strlen(sname) == 0) || (StringMatch(sname, currentStim) == 1))
				return 0 // cancel
			endif
			
			sname = FolderNameCreate(sname)
			
			if (StimRename(cdf, currentStim, sname) == 0)
				StimSetCurrent(sname)
			endif
			
			break
			
		case "Retrieve":
		
			gdf = GetDataFolder(1)
			slist = NMFolderList(gdf,"NMStim")
			
			if (ItemsInList(slist) == 0)
				DoAlert 0, "No Stim folder located in current data folder \"" + GetDataFolder(0) + "\""
				return 0
			endif
			
			Prompt sname, "open:", popup slist
			DoPrompt "Retrieve Stimulus Protocol : " + gdf, sname
			
			if (V_flag == 1)
				return 0 // cancel
			endif
			
			newname = CheckFolderName(cdf+sname)
			
			DuplicateDataFolder $(gdf + sname), $newname
			SetNMvar(newname+":StatsOn", 0) // make sure stats is OFF when retrieving
			StimSetCurrent(GetPathName(newname, 0))
			StimWavesUpdate(1)
			
			break
			
		case "Set Stim Path":
			StimPathSet()
			return 0
			
		case "Set Stim List":
			OpenStimListSet()
			return 0
		
	endswitch
	
	PulseWavesUpdate(-1, 0)
	PulseGraph(0)
	PulseTableManager(0)
	
End // StimMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function StimListPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ClampError("")
	
	String cdf = ClampDF(), tdf = ClampTabDF()
	
	Variable tab = NumVarOrDefault(tdf+"CurrentTab", 0)
	
	ClampGraphsCopy(-1, 1) // save Chan graphs configs before changing
	StimSetCurrent(popStr)
	PulseWavesUpdate(-1, 0)
	PulseGraph(0)
	PulseTableManager(0)
	
End // StimListPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StimPathSet()

	String cdf = ClampDF()
	
	NewPath /Q/O/M="Stim File Directory" StimPath
	
	if (V_flag == 0)
		PathInfo StimPath
		SetNMstr(cdf+"StimPath", S_Path)
		DoAlert 0, "Don't forget to save changes by saving your Configurations (NeuroMatic > Configs > Save)."
	endif

End // StimPathSet

//****************************************************************
//****************************************************************
//****************************************************************

Function OpenStimListSet()

	String cdf = ClampDF()
	String openList = StrVarOrDefault(cdf+"OpenStimList", "")
	
	//if (strlen(openList) == 0)
		openList = NMFolderList(ClampDF(),"NMStim")
	//endif
	
	Prompt openList, "list of stim files to open when starting Nclamp:"
	DoPrompt "Set Stim List", openList
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMstr(cdf+"OpenStimList", openList)
	
	DoAlert 0, "Don't forget to save changes by saving your Configurations (NeuroMatic > Configs > Save)."

End // OpenStimListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function StimSetCurrent(fname) // set current stim
	String fname // stimulus name
	
	return StimCurrentSet(fname)

End // StimSetCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	ClampError("")
	
	String sdf = StimDF()
	
	strswitch(ctrlName)
	
		case "CT_StimCheck":
			SetNMvar(sdf+"AcqStimChain", checked)
			if (checked == 1)
				StimChainEdit()
			else
				ClampTabUpdate()
			endif
			break
			
		case "CT_StatsCheck":
			return ClampStats(checked)
			
	endswitch
	
End // ClampCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampButton(ctrlName) : ButtonControl
	String ctrlName
	
	ClampError("")

	strswitch(ctrlName)
		case "CT_StartPreview":
			ClampAcquireCall(0)
			break
		case "CT_StartRecord":
			ClampAcquireCall(1)
			break
		case "CT0_NewCell":
			ClampDataFolderNewCell()
			break
		case "CT_Note":
			NotesAddNote("")
			break
		case "CT0_NotesEdit":
			NotesTable(1)
			DoWindow /F $NotesTableName()
			break
		case "CT0_Tgain":
			ClampTgainConfig()
			break
	endswitch

End // ClampButton

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampButtonDisable(mode)
	Variable mode // (0) preview (1) record (-1) nothing
	String pf = "", rf = ""

	switch (mode)
		case 0:
			pf = "\\K(65280,0,0)"
			break
		case 1:
			rf = "\\K(65280,0,0)"
			break
	endswitch
	
	Button CT_StartPreview, win=NMPanel, title=pf+"Preview"
	Button CT_StartRecord, win=NMPanel, title=rf+"Record"

End // ClampButtonDisable

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabControl(name, tab)
	String name; Variable tab
	
	ClampError("")
	
	String cdf = ClampDF(), tdf = ClampTabDF()
	
	Variable lastTab = NumVarOrDefault(tdf+"CurrentTab", 0)
	
	String CurrentStim = StimCurrent()
	
	if ((IsStimFolder(cdf, CurrentStim) == 0) && (tab > 0))
		DoWindow /K PG_PulseGraph
		tab = 0
	endif
	
	SetNMvar(tdf+"CurrentTab", tab)
	ChangeTab(lastTab, tab, StrVarOrDefault(tdf+"TabList", "")) // see NM_TabManager.ipf
	
	if (tab == 5)
		DoWindow /F PG_PulseGraph
		DoWindow /F PG_StimTable
	endif

End // ClampTabControl

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTabName() // return current tab name
	String tdf = ClampTabDF()

	Variable tabnum = NumVarOrDefault(tdf+"CurrentTab", 0)
	
	return TabName(tabnum, StrVarOrDefault(tdf+"TabList", ""))

End // ClampTabName

//****************************************************************
//****************************************************************
//****************************************************************
//
//	CF (configuration) tab control functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CF(enable) // nClamp configure tab enable
	Variable enable
	
	String titlestr, cdf = ClampDF()
	
	if (enable == 1)

		String board = StrVarOrDefault(cdf+"AcqBoard", "Demo")
		
		PopupMenu CT0_InterfaceMenu, win=NMpanel, mode=1, value="Demo;NIDAQ;ITC18;ITC16;", popvalue=StrVarOrDefault(ClampDF()+"AcqBoard", "Demo")
		
		// folder details
		
		GroupBox CT0_DataGrp, win=NMpanel, title="Folder : "+GetDataFolder(0)
		
		PathInfo /S ClampPath

		if (strlen(S_path) > 0)
			SetNMStr(cdf+"ClampPath", S_path)
		endif
		
		Variable saveFormat = NumVarOrDefault(cdf+"SaveFormat", 1)
		Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 1)
		
		titlestr = "save"
		
		switch(saveFormat)
			case 1:
				titlestr += " (NM"
				break
			case 2:
				titlestr += " (Igor"
				break
			case 3:
				titlestr += " (NM,Igor"
				break
		endswitch
		
		switch(saveWhen)
			default:
				titlestr = "save"
				break
			case 1:
				titlestr += ";after)"
				break
			case 2:
				titlestr += ";while)"
				saveWhen = 1
				break
		endswitch
		
		Checkbox CT0_SaveConfig, win=NMpanel, value=(saveWhen), title=titlestr
		Checkbox CT0_CloseFolder, win=NMpanel, value=NumVarOrDefault(cdf+"AutoCloseFolder", 1)
		Checkbox CT0_LogSave, win=NMpanel, value=(NumVarOrDefault(cdf+"LogAutoSave", 1))
		
		Variable logdsply = NumVarOrDefault(cdf+"LogDisplay", 1)
		
		PopupMenu CT0_LogMenu, win=NMpanel, mode=(logdsply+3)
		
		PulseGraph(0)
	
	endif

End // CF

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampInterfacePopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	String cdf = ClampDF()
	
	ClampError("")
	
	ClampAcquireManager(popStr, -2, 0) // test interface board 
	
	if (NumVarOrDefault(cdf+"ClampError", -1) == 0)
		SetNMStr(cdf+"AcqBoard", popStr)
	endif
	
	CF(1)
	
End // ClampInterfacePopup

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampLogPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ClampError("")
	
	Variable change, nb, table
	
	String cdf = ClampDF(), ldf = LogDF()
	
	String nbName = LogNoteBookName(ldf)
	String tName = LogTableName(ldf)
	
	strswitch(popStr)
	
		case "None":
			change = 1
			break
			
		case "Both":
			change = 1; nb = 1; table = 1;
			break
			
		case "Text":
			change = 1; nb = 1; table = 0
			break
		
		case "Table":
			change = 1; nb = 0; table = 1;
			break
			
	endswitch
	
	if (change == 1)
		SetNMvar(cdf+"LogDisplay", popNum-3)
	endif
	
	if (nb == 0)
		DoWindow /K $nbName
	elseif (WinType(nbName) == 5)
		DoWindow /F $nbName
	else
		LogNoteBook(ldf)
	endif
	
	if (table == 0)
		DoWindow /K $tName
	elseif (WinType(tName) == 2)
		DoWindow /F $tName
	else
		LogTable(ldf)
	endif
	
	CF(1)
	
End // ClampLogPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampCFCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	ClampError("")
	
	String cdf = ClampDF()

	strswitch(ctrlName)
		case "CT0_SaveConfig":
			ClampSaveConfig()
			break
		case "CT0_CloseFolder":
			SetNMVar(cdf+"AutoCloseFolder", checked)
			break
		case "CT0_LogSave":
			SetNMvar(cdf+"LogAutoSave", checked)
			break
		case "CT0_LogDisplay":
			ClampLogConfig()
			break
	endswitch
	
	CF(1)
	
End // ClampCFCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String cdf = ClampDF()
	String sdf = StimDF()

	strswitch(ctrlName)
	
		case "CT0_FilePathSet":
			if (strlen(varStr) == 0)
				varStr = "c:x"
			endif
			NewPath /Q/O ClampPath varStr
			break
			
		case "CT0_FileNameSet":
			if (strlen(varStr) == 0)
				SetNMStr(cdf+"FolderPrefix", ClampDateName())
			else
				SetNMStr(cdf+"UserFolderPrefix", varStr)
				SetNMvar(cdf+"DataFileCell", 0)
				ClampDataFolderSeqReset()
			endif
			break
			
		case "CT0_FileCellSet":
			if (numtype(varNum) == 0)
				ClampDataFolderSeqReset()
			endif
			break
			
		case "CT0_StimNameSet":
				SetNMstr(sdf+"StimTag", varStr)
			break
			
		case "CT0_UserName":
		case "CT0_UserLab":
		case "CT0_ExpTitle":
			if (WinType(NotesTableName()) == 2)
				NotesTable(0)
			endif
			break
			
	endswitch
	
	ClampTabUpdate()
	
End // ClampSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveConfig()
	String cdf = ClampDF()
	
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 1) + 1
	Variable savePrompt = NumVarOrDefault(cdf+"SaveWithDialogue", 1) + 1
	Variable saveFormat = NumVarOrDefault(cdf+"SaveFormat", 1)
	
	Variable bintype = FileBinType()
	
	Prompt saveWhen, "save data when?", popup "never;after recording;while recording;"
	Prompt savePrompt, "save with dialogue prompt?", popup "no;yes;"
	Prompt saveFormat, "save as file format:", popup "NeuroMatic Binary;Igor Binary;Both;"
	
	DoPrompt "Save Data Configuration", saveWhen, savePrompt, saveFormat
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	if ((saveWhen == 3) && (saveFormat == 2))
		saveFormat = 3 // save both if save while recording
	endif
	
	if ((saveWhen == 2) && (bintype == 1) && (saveFormat != 2))
		saveFormat = 2
		DoPrompt "Please Check File Format", saveFormat
		if (V_flag == 1)
			return -1 // cancel
		endif
	endif

	if (saveWhen == 3)
		DoAlert 0, "Warning: depending on the speed of your computer, Save While Recording option may slow acquisition. Please use with caution."
	endif
	
	SetNMVar(cdf+"SaveWhen", saveWhen - 1)
	SetNMVar(cdf+"SaveWithDialogue", savePrompt - 1)
	SetNMVar(cdf+"SaveFormat", saveFormat)

End // ClampSaveConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampLogConfig()
	String cdf = ClampDF()

	Variable dsply = NumVarOrDefault(cdf+"LogDisplay", 1) + 1
	Prompt dsply, "display log format:", popup "none;notebook;table;both;"
	DoPrompt "Log Display Configuration", dsply
	
	if (V_flag == 1)
		return 0
	endif
	
	SetNMvar(cdf+"LogDisplay", dsply-1)

End // ClampLogConfig

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Tau tab control functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function Tau(enable) // stim wave configure tab
	Variable enable
	
	Variable tempvar, driver, slave, amode, nwaves, reps, dis, total
	String alist
	
	String cdf = ClampDF(), tdf = ClampTabDF(), sdf = StimDF()
	 
	String board = StrVarOrDefault(cdf+"AcqBoard", "Demo")
	
	if (enable == 1)
	
		Variable WaveLength = NumVarOrDefault(sdf+"WaveLength", 0)
		Variable SampleInterval = StimInterval(sdf, NumVarOrDefault(tdf+"CurrentBoard", 0))
		Variable nReps = NumVarOrDefault(sdf+"NumStimReps", 0)
		Variable repRate = NumVarOrDefault(sdf+"RepRate", 0)
	
		SetNMvar(tdf+"NumStimWaves", NumVarOrDefault(sdf+"NumStimWaves", 1))
		SetNMvar(tdf+"InterStimTime", NumVarOrDefault(sdf+"InterStimTime", 0))
		SetNMvar(tdf+"WaveLength", WaveLength)
		SetNMvar(tdf+"SampleInterval", SampleInterval)
		SetNMvar(tdf+"SamplesPerWave", floor(WaveLength/SampleInterval))
		
		SetNMvar(tdf+"StimRate", NumVarOrDefault(sdf+"StimRate", 0))
		SetNMvar(tdf+"NumStimReps", nReps)
		SetNMvar(tdf+"InterRepTime", NumVarOrDefault(sdf+"InterRepTime", 0))
		SetNMvar(tdf+"RepRate", repRate)
		
		total = nReps/repRate
		SetNMvar(tdf+"TotalTime", total)
		SetNMvar(sdf+"TotalTime", total)
		
		amode = NumVarOrDefault(sdf+"AcqMode", 0)
		nwaves = NumVarOrDefault(sdf+"NumStimWaves", 1)
		reps = NumVarOrDefault(sdf+"NumStimReps", 1)
		
		// acquisition mode popup
		
		alist = StimModeList()
		
		switch(amode)
			case 0:
				amode = 1+ WhichListItem("epic precise", alist)
				break
			case 1:
				amode = 1+ WhichListItem("continuous", alist)
				break
			case 2:
				amode = 1+ WhichListItem("episodic", alist)
				break
			case 3:
				amode = 1+ WhichListItem("triggered", alist)
				break
		endswitch
		
		PopupMenu CT1_AcqMode, win=NMpanel, value=StimModeList(), mode=amode
		
		// acq board popup
		
		tempvar = NumVarOrDefault(tdf+"CurrentBoard", 0)
		driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
		if (tempvar == 0) // nothing selected
			tempvar = driver
		endif
		
		if (tempvar != driver)
			slave = 1
		endif
		
		tempvar = 1 + ClampBoardListNum(tempvar)
		
		PopupMenu CT1_TauBoard,win=NMpanel,mode=(tempvar),value=StrVarOrDefault(ClampDF()+"BoardList", "")
		
		if (amode == 1) // continuous
			dis = 1
		endif
		
		SetVariable CT1_InterStimTime,win=NMpanel,noedit=dis,frame=(!dis)
		SetVariable CT1_InterRepTime,win=NMpanel,noedit=dis,frame=(!dis)
		
		PulseGraph(0)
		
	endif

End // Tau

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimModeList()
	return "continuous;episodic;epic precise;triggered;"
End // StimModeList

//****************************************************************
//****************************************************************
//****************************************************************

Function StimModePopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ClampError("")
	
	strswitch(popStr)
		case "epic precise":
			popNum = 0
			break
		case "continuous":
			popNum = 1
			break
		case "episodic": // less precise
			popNum = 2
			break
		case "triggered":
			popNum = 3
			break
	endswitch
	
	SetNMVar(StimDF()+"AcqMode", popNum)
	StimCheckTau()
	Tau(1)
	
End // StimModePopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StimSetTau(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ClampError("")
	
	Variable inter, updatestim = 1, updateNM
	String sdf = StimDF(), tdf = ClampTabDF()
	
	Variable NumStimWaves = NumVarOrDefault(tdf+"NumStimWaves", 0)
	Variable InterStimTime = NumVarOrDefault(tdf+"InterStimTime", 0)
	Variable WaveLength = NumVarOrDefault(tdf+"WaveLength", 0)
	Variable SampleInterval = NumVarOrDefault(tdf+"SampleInterval", 0.1)

	strswitch(ctrlName[4,inf])
	
		case "NumStimWaves":
			updateNM = 1
			break
	
		case "SampleInterval":
			break
		
		case "SamplesPerWave":
			SetNMVar(tdf+"WaveLength", varNum * SampleInterval)
			break
		
		case "StimRate":
			updatestim = 0
			inter =  (1000 / varNum) - WaveLength
			if (inter > 0)
				SetNMvar(tdf+"InterStimTime", inter)
			else
				ClampError("stim rate not possible.")
			endif
			break
			
		case "RepRate":
			updatestim = 0
			inter = (1000 / varNum) - NumStimWaves * (WaveLength + InterStimTime)
			if (inter > 0)
				SetNMVar(tdf+"InterRepTime", inter)
			else
				ClampError("rep rate not possible.")
			endif
			break
		
		case "InterStimTime":
		case "InterRepTime":
		case "NumStimReps":
			updatestim = 0
			break
			
	endswitch
	
	StimCheckTau()
	
	if (updatestim == 1)
		SetNMvar(sdf+"UpdateStim", 1)
		PulseWavesUpdate(-1, 0)
		PulseGraph(0)
	endif
	
	if (updateNM == 1)
		UpdateNMpanel(0)
	else
		Tau(1)
	endif
	
End // StimSetTau

//****************************************************************
//****************************************************************
//****************************************************************

Function StimCheckTau() // check and save stim time variables

	String tdf = ClampTabDF(), sdf = StimDF()
	
	Variable acqMode = NumVarOrDefault(sdf+"AcqMode", 0)
	
	Variable NumStimWaves = NumVarOrDefault(tdf+"NumStimWaves", 1)
	Variable InterStimTime = NumVarOrDefault(tdf+"InterStimTime", 0)
	Variable WaveLength = NumVarOrDefault(tdf+"WaveLength", 100)
	Variable StimRate = NumVarOrDefault(tdf+"StimRate", 0)
	Variable SampleInterval = NumVarOrDefault(tdf+"SampleInterval", 0.1)
	Variable SamplesPerWave = NumVarOrDefault(tdf+"SamplesPerWave", 1)
	
	Variable NumStimReps = NumVarOrDefault(tdf+"NumStimReps", 1)
	Variable InterRepTime = NumVarOrDefault(tdf+"InterRepTime", 0)
	Variable RepRate = NumVarOrDefault(tdf+"RepRate", 0)
	
	Variable CurrentBoard = NumVarOrDefault(tdf+"CurrentBoard", 0)
	Variable BoardDriver = NumVarOrDefault(tdf+"BoardDriver", 0)

	if ((AcqMode == 0) || (AcqMode == 2)) // episodic
	
		if (InterStimTime == 0)
			InterStimTime = 500
			ClampError("zero wave interlude time not allowed with episodic acquisition.")
		endif
		
	elseif (AcqMode == 1) // continuous
	
		if ((InterStimTime != 0) || (InterRepTime != 0))
			InterStimTime = 0
			InterRepTime = 0
		endif
		
	endif
	
	SampleInterval = floor(1e8*SampleInterval) / 1e8
	SamplesPerWave = floor(WaveLength/SampleInterval)

	StimRate = 1000 / (WaveLength + InterStimTime)
	RepRate = 1000 / (InterRepTime + NumStimWaves * (WaveLength + InterStimTime))
			
	SetNMVar(sdf+"NumStimWaves", NumStimWaves)
	SetNMVar("NumGrps", NumStimWaves)
	SetNMVar(sdf+"InterStimTime", InterStimTime)
	SetNMVar(sdf+"WaveLength", WaveLength)
	SetNMVar(sdf+"StimRate", StimRate)
	SetNMVar(sdf+"SamplesPerWave", SamplesPerWave)
	
	SetNMVar(sdf+"NumStimReps", NumStimReps)
	SetNMVar(sdf+"InterRepTime", InterRepTime)
	SetNMVar(sdf+"RepRate", RepRate)
	
	if (CurrentBoard == BoardDriver)
		SetNMVar(sdf+"SampleInterval", SampleInterval)
	else
		SetNMVar(sdf+"SampleInterval_"+num2str(CurrentBoard), SampleInterval)
	endif

End // StimCheckTau

//****************************************************************
//****************************************************************
//****************************************************************
//
//	ADC tab control functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ADC(enable) // stim ADC input configure tab
	Variable enable
	
	Variable tempvar, icnt
	String tempstr, cdf = ClampDF(), tdf = ClampTabDF(), sdf = StimDF()
	
	String CurrentStim = StimCurrent()
	
	if ((enable == 1) && (IsStimFolder(cdf, CurrentStim) == 1))
	
		Variable config = NumVarOrDefault(tdf+"IOnum", 0)
	
		Wave active = $(sdf+"ADCon")
		Wave mode = $(sdf+"ADCmode")
		Wave board = $(sdf+"ADCboard")
		Wave chan = $(sdf+"ADCchan")
		Wave scale = $(sdf+"ADCscale")
		Wave gain = $(sdf+"ADCgain")
		
		Wave /T name = $(sdf+"ADCname")
		Wave /T units = $(sdf+"ADCunits")
		
		SetNMvar(tdf+"IOchan", chan[config])
		SetNMvar(tdf+"IOscale", scale[config])
		SetNMvar(tdf+"IOgain", gain[config])
		SetNMstr(tdf+"IOname", name[config])
		
		 IOdisable(0) // enable ADC controls
		
		// activate buttons
		
		for (icnt = 0; icnt < 6; icnt += 1)
		
			tempstr = ""
			
			if (icnt == config)
				tempstr += "\\f01"
			endif
			
			if (active[icnt] == 1)
				tempstr +=  "\\K(65280,0,0)"
			endif
			
			Button $("CT2_IO"+num2str(icnt)), win=NMpanel, title=tempstr + num2str(icnt)
			
		endfor
		
		// Group box
		
		GroupBox CT2_IOgrp, win=NMpanel, title = "Input Config " + num2str(config) 
		
		// board driver popup
		
		tempvar = board[config]
	
		if (tempvar == 0) // nothing selected
			tempvar = NumVarOrDefault(cdf+"BoardDriver", 0) // default
		endif
		
		tempvar = 1 + ClampBoardListNum(tempvar)
		
		PopupMenu CT2_IOboard, win=NMpanel,mode=(tempvar),value=StrVarOrDefault(ClampDF()+"BoardList", "")
		
		// units popup
		
		tempstr = units[config]
		tempvar = WhichListItemLax(tempstr, StrVarOrDefault(tdf+"UnitsList", ""), ";") + 1
		PopupMenu CT2_IOunits, win=NMpanel,mode=(tempvar),value=StrVarOrDefault(ClampTabDF()+"UnitsList", "") + "Other...;"
		
		// scale
		
		tempstr = "scale (V/" + tempstr + "):"
		SetVariable CT2_IOscale, win=NMpanel, title=tempstr
		
		// active checkbox
	
		Checkbox CT2_IOactive, win=NMpanel, value=(active[config])
		
		// pre-samp checkbox
		
		tempvar = 0
		tempstr = "pre-sample"
		
		if (mode[config] > 0)
			tempvar = 1
			tempstr += " (" + num2str(mode[config]) + ")"
		endif
		
		Checkbox CT2_ADCpresamp, win=NMpanel, value=(tempvar), title=tempstr
		
		// wave prefix

		SetNMstr(tdf+"DataPrefix", StimWavePrefix())
		
		// stim pre, inter, post analysis
		
		PopupMenu CT2_PreAnalysis,win=NMpanel,mode=1,value="Pre;---;"+StrVarOrDefault(StimDF()+"PreStimFxnList", "")+"---;Add to List;Remove from List;Clear List;"
		PopupMenu CT2_InterAnalysis,win=NMpanel,mode=1,value="Inter;---;"+StrVarOrDefault(StimDF()+"InterStimFxnList", "")+"---;Add to List;Remove from List;Clear List;"
		PopupMenu CT2_PostAnalysis,win=NMpanel,mode=1,value="Post;---;"+StrVarOrDefault(StimDF()+"PostStimFxnList", "")+"---;Add to List;Remove from List;Clear List;"
		
		PulseGraph(0)
		
	endif

End // ADC

//****************************************************************
//****************************************************************
//****************************************************************

Function StimPreSampCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	ClampError("")
	
	String tdf = ClampTabDF(), sdf = StimDF()
	
	Variable config = NumVarOrDefault(tdf+"IOnum", 0)
	
	Wave mode = $(sdf+"ADCmode")
	
	Variable npnts = mode[config]
	
	if (checked == 1)
	
		if ((npnts < 1) || (npnts > 20))
			npnts = 1
		endif
		
		Prompt npnts "number of samples (< 20):"
		DoPrompt "Pre-sample ADC input", npnts
		
		if (V_flag == 0)
			mode[config] = npnts
		endif
		
	else
	
		mode[config] = 0
		
	endif
	
	ADC(1)  // update tab
	
End // StimPreSampCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function StimFxnPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu CT2_PreAnalysis, win=NMpanel, mode=1
	PopupMenu CT2_InterAnalysis, win=NMpanel, mode=1
	PopupMenu CT2_PostAnalysis, win=NMpanel, mode=1
	
	ClampError("")
	
	Variable icnt
	String fxn, otherfxn, flist, flist2, listname, sdf = StimDF()
	
	strswitch(ctrlName[4,inf])
		default:
			return 0
		case "PreAnalysis":
			listname = "PreStimFxnList"
			flist2 = ClampUtilityPreList()
			break
		case "InterAnalysis":
			listname = "InterStimFxnList"
			flist2 = ClampUtilityInterList()
			break
		case "PostAnalysis":
			listname = "PostStimFxnList"
			flist2 = ClampUtilityPostList()
			break
	endswitch
	
	flist = StrVarOrDefault(sdf+listname,"")
	
	strswitch(popStr)
		case "Add to List":
			
			if (strlen(flist2) > 0)
				Prompt fxn, "choose utility function:", popup flist2
				Prompt otherfxn, "or enter function name, such as \"MyFunction\":"
				DoPrompt "Add Stim Function", fxn, otherfxn
			else
				Prompt otherfxn, "enter function name, such as \"MyFunction\":"
				DoPrompt "Add Stim Function", otherfxn
			endif
			
			if (V_flag == 1)
				break // cancel
			endif
			
			if (strlen(otherfxn) > 0)
				fxn = otherfxn
			endif
			
			if (strlen(fxn) == 0)
				break
			endif
			
			if (exists(fxn) != 6)
				DoAlert 0, "Error: function " + fxn + "() does not appear to exist."
				break
			endif
			
			Execute /Z fxn + "(1)" // call function config
			
			if (WhichListItemLax(fxn, flist, ";") == -1)
				flist = AddListItem(fxn,StrVarOrDefault(sdf+listname,""),";",inf)
				SetNMStr(sdf+listname,flist)
			endif
			
			break
			
		case "Remove from List":
		
			if (ItemsInlist(flist) == 0)
				DoAlert 0, "No funtions to remove."
				break
			endif
			
			Prompt fxn, "select function to remove:", popup flist
			DoPrompt "Remove Stim Function", fxn
	
			if (V_flag == 1)
				return 0
			endif
			
			Execute /Z fxn + "(-1)" // call function to kill variables
			
			SetNMStr(sdf+listname,RemoveFromList(fxn,flist))
			
			break
			
		case "Clear List":
			for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
				fxn = StringFromlist(icnt, flist)
				Execute /Z fxn + "(-1)" // call function to kill variables
			endfor
			SetNMStr(sdf+listname,"")
			break
			
		default:
			if (exists(popStr) == 6)
				Execute /Z popStr + "(1)" // call function config
			endif
			
	endswitch
	
	ADC(1)
	
End // StimFxnPopup

//****************************************************************
//****************************************************************
//****************************************************************
//
//	DAC/TTL/ADC tab control functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function DAC(enable) // stim DAC output configure tab
	Variable enable
	
	OutEnable("DAC", enable)
	
End // DAC

//****************************************************************
//****************************************************************
//****************************************************************

Function TTL(enable) // stim TTL output configure tab
	Variable enable
	
	OutEnable("TTL", enable)
	
End // TTL

//****************************************************************
//****************************************************************
//****************************************************************

Function OutEnable(io, enable) // stim DAC output configure tab
	String io // "DAC" or "TTL"
	Variable enable
	
	Variable tempvar, icnt
	String tempstr, cdf = ClampDF(), tdf = ClampTabDF(), sdf = StimDF()
	
	String CurrentStim = StimCurrent()
	
	strswitch(io)
		case "DAC":
		case "TTL":
			break
		default:
			return -1
	endswitch
	
	if ((enable == 1) && (IsStimFolder(cdf, CurrentStim) == 1))
	
		Variable config = NumVarOrDefault(tdf+"IOnum", 0)
	
		Wave active = $(sdf+io+"on")
		Wave board = $(sdf+io+"board")
		Wave chan = $(sdf+io+"chan")
		Wave scale = $(sdf+io+"scale")
		
		Wave /T name = $(sdf+io+"name")
		Wave /T units = $(sdf+io+"units")
		
		SetNMvar(tdf+"IOchan", chan[config])
		SetNMvar(tdf+"IOscale", scale[config])
		SetNMstr(tdf+"IOname", name[config])
		
		// activate buttons
		
		for (icnt = 0; icnt < 6; icnt += 1)
			
			tempstr = ""
			
			if (icnt == config)
				tempstr += "\\f01"
			endif
			
			if (active[icnt] == 1)
				tempstr +=  "\\K(65280,0,0)"
			endif
			
			Button $("CT2_IO"+num2str(icnt)), win=NMpanel, title=tempstr + num2str(icnt)
			
		endfor
		
		// Group box
		
		GroupBox CT2_IOgrp, win=NMpanel, title = "Output Config " + num2str(config)
		
		// board driver popup
		
		tempvar = board[config]
	
		if (tempvar == 0) // nothing selected
			tempvar = NumVarOrDefault(cdf+"BoardDriver", 0) // default
		endif
		
		tempvar = 1 + ClampBoardListNum(tempvar)
		
		PopupMenu CT2_IOboard, win=NMpanel,mode=(tempvar),value=StrVarOrDefault(ClampDF()+"BoardList", "")
		
		// units popup
		
		tempstr = units[config]
		tempvar = WhichListItemLax(tempstr, StrVarOrDefault(tdf+"UnitsList", ""), ";") + 1
		PopupMenu CT2_IOunits, win=NMpanel,mode=(tempvar),value=StrVarOrDefault(ClampTabDF()+"UnitsList", "") + "Other...;"
		
		// scale
		
		tempstr = "scale (" + tempstr + "/V):"
		SetVariable CT2_IOscale, win=NMpanel, title=tempstr
		
		// active checkbox
	
		Checkbox CT2_IOactive, win=NMpanel, value=(active[config])
		
		IOdisable(1) // disable ADC controls
		
		PulseGraph(0)
		PulseTableUpdate("", 0)
		
	endif

End // OutEnable

//****************************************************************
//****************************************************************
//****************************************************************

Function IOdisable(dFlag)
	Variable dFlag
	
	Checkbox CT2_ADCpresamp, win=NMPanel, disable=dFlag
	SetVariable CT2_IOgain, win=NMPanel, disable=dFlag
	PopupMenu CT2_PreAnalysis, win=NMPanel, disable=dFlag
	PopupMenu CT2_InterAnalysis, win=NMPanel, disable=dFlag
	PopupMenu CT2_PostAnalysis, win=NMPanel, disable=dFlag
	SetVariable CT2_ADCprefix, win=NMPanel, disable=dFlag

End // IOenable

//****************************************************************
//****************************************************************
//****************************************************************

Function StimActivateCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	ClampError("")
	
	String tdf = ClampTabDF()
	String io = ClampTabName()
	
	Variable config = NumVarOrDefault(tdf+"IOnum", 0)
	
	StimActivate(io, config, checked)
	
	Execute /Z io + "(1)" // update tab
	
End // StimActivateCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function StimActivateButton(ctrlName) : ButtonControl
	String ctrlName
	
	ClampError("")
	
	String tdf = ClampTabDF()
	String io = ClampTabName()
	
	Variable j = strlen(ctrlName) - 1
	Variable config = str2num(ctrlName[j, j])
	
	SetNMvar(tdf+"IOnum", config)
	//StimActivate(io, config, 1)
	
	Execute /Z io + "(1)" // update tab
	
End // StimActivateButton

//****************************************************************
//****************************************************************
//****************************************************************

Function StimActivate(io, config, activate)
	String io
	Variable config
	Variable activate

	String wPrefix, tdf = ClampTabDF(), sdf = StimDF()

	Wave ioWave = $(sdf+io+"on")
	
	ioWave[config] = activate
	
	if (StringMatch(io, "ADC") == 1)
	
		if (activate == 1)
			CheckStimChanFolders()
		endif
	
	else // DAC/TTL
	
		wPrefix = StimWaveName(io, config, -1)
	
		SetNMstr(tdf+"PulsePrefix", wPrefix)
		
		if (activate == 0)
			StimWavesKill(sdf, wPrefix)
			StimWavesKill(tdf, wPrefix)
		else//if (ioWave[config] == 0)
			PulseWaveCheck(io, config)
			PulseWavesUpdate(0, 0) // this creates waves
			SetNMvar(sdf+"UpdateStim", 1)
		endif
		
	endif
	
	
	
End // StimActivate

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableButton(ctrlName) : ButtonControl
	String ctrlName
	
	ClampError("")
	
	StimConfigTable(StimDF(), ClampTabName(), 1)
	
End // PulseTableButton

//****************************************************************
//****************************************************************
//****************************************************************

Function StimBoardPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ClampError("")
	
	String tdf = ClampTabDF(), sdf = StimDF()
	
	String io = ClampTabName()
	
	Variable config = NumVarOrDefault(tdf+"IOnum", 0)
	
	strswitch(io)
		Case "Tau":
			SetNMvar(tdf+"CurrentBoard", ClampBoardNum(popStr))
			break
		
		Case "DAC":
		Case "TTL":
			SetNMvar(sdf+"UpdateStim", 1)
		Case "ADC":
			Wave board = $(sdf+io+"board")
			board[config] = ClampBoardNum(popStr)
			StimCheckChannels()
			break
	endswitch
	
	Execute /Z io + "(1)" // update tab

End // StimBoardPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StimUnitsPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ClampError("")
	
	String tdf = ClampTabDF(), sdf = StimDF()
	
	String io = ClampTabName()
	
	Variable config = NumVarOrDefault(tdf+"IOnum", 0)
	
	Wave /T units = $(sdf+io+"units")
	
	String unitsList = StrVarOrDefault(tdf+"UnitsList", "")
			
	strswitch(popStr)
	
		case "Other...":
		
			String unitstr = ""
			Prompt unitstr "enter channel units:"
			DoPrompt "Other Channel Units", unitstr
			
			if ((V_flag) || (strlen(unitstr) == 0))
				break // cancel
			endif

			if (WhichListItemLax(unitstr, unitsList, ";") == -1)
				unitstr = unitsList + unitstr + ";"
				SetNMStr(tdf+"UnitsList", unitstr)
			endif
			
			popStr = unitstr
			
		default:
		
			units[config] = popStr
	
	endswitch
	
	Execute /Z io + "(1)" // update tab

End // StimUnitsPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StimSetVar(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ClampError("")
	
	String wname
	String tdf = ClampTabDF(), sdf = StimDF(), io = ClampTabName()
	
	Variable config = NumVarOrDefault(tdf+"IOnum", 0)
	
	StimRedimenWaves(sdf, io, config + 1) // redimension if necessary
	
	strswitch(ctrlName[4,inf])
	
		case "IOchan":
			wname = sdf + io + "chan"
			if (WaveExists($wname) == 1)
				Wave chan = $wname
				chan[config] = varNum
				StimCheckChannels()
			endif
			break
			
		case "IOscale":
		
			if (StringMatch(io, "ADC") == 0)
				SetNMvar(sdf+"UpdateStim", 1)
			endif
			
			if ((numtype(varNum) > 0) || (varNum <= 0))
				varNum = 1
			endif
			
			wname = sdf + io + "scale"
			
			if (WaveExists($wname) == 1)
				Wave scale = $wname
				scale[config] = varNum
			endif
			
			break
			
		case "IOgain":
			wname = sdf + io + "gain"
			if (WaveExists($wname) == 1)
				Wave gain = $wname
				gain[config] = varNum
			endif
			break
			
		case "ADCprefix":
			SetNMstr(sdf+"WavePrefix", varStr)
			break
		
		case "IOname":
			wname = sdf + io + "name"
			if (WaveExists($wname) == 1)
				Wave /T name = $wname
				name[config] = varStr
			endif
			break
		
		case "IOnum":
			break
			
	endswitch
	
	Execute /Z io + "(1)" // update tab
	
End // StimSetVar

//****************************************************************
//****************************************************************
//****************************************************************

Function StimCheckChannels()

	Variable config, jcnt, test
	String sdf = StimDF()
	
	Wave ADCon = $(sdf+"ADCon")
	Wave ADCchan = $(sdf+"ADCchan")
	Wave ADCmode = $(sdf+"ADCmode")
	Wave ADCboard = $(sdf+"ADCboard")

	Wave DACon = $(sdf+"DACon")
	Wave DACchan = $(sdf+"DACchan")
	Wave DACboard = $(sdf+"DACboard")
	
	Wave TTLon = $(sdf+"TTLon")
	Wave TTLchan = $(sdf+"TTLchan")
	Wave TTLboard = $(sdf+"TTLboard")
	
	for (config = 0; config < numpnts(ADCon); config += 1)
	
		if (ADCon[config] == 1)
		
			for (jcnt = 0; jcnt < numpnts(ADCon); jcnt += 1)
			
				test = ADCon[jcnt] && (ADCboard[jcnt] == ADCboard[config])
				test = test && (ADCchan[jcnt] == ADCchan[config]) && (ADCmode[jcnt] == ADCmode[config])
				
				if ((jcnt != config) && (test == 1))
					ClampError("duplicate ADC inputs for configs " + num2str(config) + " and " + num2str(jcnt))
					return -1
				endif
				
			endfor
			
		endif
		
	endfor
	
	for (config = 0; config < numpnts(DACon); config += 1)
	
		if (DACon[config] == 1)
		
			for (jcnt = 0; jcnt < numpnts(DACon); jcnt += 1)
			
				test = DACon[jcnt] && (DACboard[jcnt] == DACboard[config]) && (DACchan[jcnt] == DACchan[config])
				
				if ((jcnt != config) && (test == 1))
					ClampError("duplicate DAC outputs for configs " + num2str(config) + " and " + num2str(jcnt))
					return -1
				endif
				
			endfor
			
		endif
		
	endfor
	
	for (config = 0; config < numpnts(TTLon); config += 1)
	
		if (TTLon[config] == 1)
		
			for (jcnt = 0; jcnt < numpnts(TTLon); jcnt += 1)
			
				test = TTLon[jcnt] && (TTLboard[jcnt] == TTLboard[config]) && (TTLchan[jcnt] == TTLchan[config])
			
				if ((jcnt != config) && (test == 1))
					ClampError("duplicate TTL outputs for configs " + num2str(config) + " and " + num2str(jcnt))
					return -1
				endif
				
			endfor
			
		endif
		
	endfor
	
	return 0

End // StimCheckChannels

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Pulse Generator tab control functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function PG(enable) // stim pulse generator tab
	Variable enable

	Variable icnt, npulses, md
	String wlist, wPrefix
	
	String cdf = ClampDF(), tdf = ClampTabDF(), sdf = StimDF()
	
	Variable numStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 1)
	
	String CurrentStim = StimCurrent()
	
	if ((enable == 1) && (IsStimFolder(cdf, CurrentStim) == 1))
		
		wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
		wlist = StimPrefixListAll(sdf)
		
		if (WhichListItemLax(wPrefix, wlist, ";") == -1)
			wPrefix = ""
		endif
	
		if ((strlen(wPrefix) == 0) && (strlen(wlist) > 0))
			wPrefix = StringFromList(0,wlist)
			SetNMstr(tdf+"PulsePrefix", wPrefix)
			wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
		endif
		
		if (strlen(wlist) == 0)
			wPrefix = ""
			SetNMstr(tdf+"PulsePrefix", wPrefix)
			PopupMenu CT5_WavePrefix,win=NMpanel,mode=1,value="no outputs;"
		else
			md = WhichListItemLax(wPrefix, wlist, ";") + 1
			PopupMenu CT5_WavePrefix,win=NMpanel,mode=md,value=StimNameListAll(StimDF())
		endif
		
		Checkbox CT5_PulseOff, win=NMpanel, value=NumVarOrDefault(sdf+"PulseGenOff", 0)
		
		PulseConfigCheck()
		
		GroupBox CT5_PulseGrp, win=NMpanel, title = "Pulse Config ( n = " + num2str(PulseCount(sdf,wPrefix)) + " )"
		
		Checkbox CT5_Display, win=NMpanel, value=NumVarOrDefault(tdf+"PulseDisplay", 1)
		
		PulseGraph(1)
		PulseTableManager(0)
		
	endif
	
	DoWindow /F NMpanel // bring NM panel back to front
	
End // PG

//****************************************************************
//****************************************************************
//****************************************************************

Function PulsePrefixPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	Variable icnt
	
	ClampError("")
	
	String tdf = ClampTabDF()
	
	if (strlen(popStr) > 0)
	
		icnt = strsearch(popStr," : ",0)
		
		if (icnt >= 0)
			popStr = popStr[0,icnt-1]
		endif
		
		SetNMstr(tdf+"PulsePrefix", popStr)
		PG(1)
		
	endif
	
End // PulsePrefixPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseButton(ctrlName) : ButtonControl
	String ctrlName
	
	ClampError("")
	
	String tdf = ClampTabDF()
	
	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	
	strswitch(ctrlName[4,inf])
	
		case "New":
		
			strswitch(wPrefix[0,2])
			
				case "DAC":
					if (PulseEditDAC(-1) == -1)
						return 0  // cancel
					endif
					break
					
				case "TTL":
					if (PulseEditTTL(-1) == -1)
						return 0  // cancel
					endif
					break
					
				default:
					return 0
					
			endswitch
			
			break
			
		case "Clear":
			if (PulseClearCall() == -1)
				return 0 // cancel
			endif
			break
			
		case "Edit":
			if (PulseEditCall() == -1)
				return 0 // cancel
			endif
			break
			
		case "Train":
			 if (PulseTrainCall() == -1)
			 	return 0 // cancel
			 endif
			 break
			 
		case "Table":
			PulseTableManager(1)
			DoWindow /F PG_StimTable
			return 0
			
	endswitch
	
	PulseWavesUpdate(0, 0)
	SetNMvar(StimDF()+"UpdateStim", 1)
	
	PG(1)

End // PulseButton

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	ClampError("")
	
	String sdf = StimDF(), tdf = ClampTabDF()
	
	strswitch(ctrlname)
	
		case "CT5_PulseOff":
			SetNMvar(sdf+"PulseGenOff", checked)
			break
	
		case "CT5_Display":
			SetNMvar(tdf+"PulseDisplay", checked)
			break
			
		case "CT5_AllOutputs":
			SetNMvar(tdf+"PulseAllOutputs", checked)
			break
			
		case "CT5_AllWaves":
			SetNMvar(tdf+"PulseAllWaves", checked)
			break
			
	endswitch
	
	PulseGraph(1)
	PG(1)
	
End // PulseCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseSetVar(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	PulseGraph(1)
	DoWindow /F NMpanel
	
End // PulseSetVar

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseEditCall()
	Variable pnum
	
	String plist = PulseConfigList()
	
	String tdf = ClampTabDF()
	
	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	
	if (ItemsInList(plist) == 0)
		DoAlert 0, "No pulses to edit."
		return -1
	endif
	
	Prompt pnum, "choose pulse configuration:", popup plist
	DoPrompt "Edit Pulse Config", pnum
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	PulseRetrieve(pnum-1)
	
	strswitch(wPrefix[0,2])
		case "DAC":
			return PulseEditDAC(pnum-1)
		case "TTL":
			return PulseEditTTL(pnum-1)
		default:
			return -1
	endswitch

End // PulseEditCall

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseEditDAC(pulseNum)
	Variable pulseNum // (-1) for new
	
	Variable icnt, oldsh
	String title, wlist = "", shlist = "Square;Ramp;Alpha;2-Exp;Other;"
	
	if (pulseNum == -1)
		title = "New DAC Pulse Config"
	else
		title = "Edit DAC Pulse Config " + num2str(pulseNum)
	endif

	String tdf = ClampTabDF(), sdf = StimDF()
	
	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	
	Variable nwaves = NumVarOrDefault(sdf+"NumStimWaves", 1)
	
	for (icnt = 0; icnt < nwaves; icnt += 1)
		wlist = AddListItem("Wave"+num2str(icnt), wlist, ";", inf)
	endfor
	
	Variable sh = NumVarOrDefault(tdf+"PulseShape", 1)
	Variable wn = 1 + NumVarOrDefault(tdf+"PulseWaveN", 0)
	Variable wnd = NumVarOrDefault(tdf+"PulseWaveND", 0)
	Variable am = NumVarOrDefault(tdf+"PulseAmp", 1)
	Variable amd = NumVarOrDefault(tdf+"PulseAmpD", 0)
	Variable on = NumVarOrDefault(tdf+"PulseOnset", 0)
	Variable ond = NumVarOrDefault(tdf+"PulseOnsetD", 0)
	Variable wd = NumVarOrDefault(tdf+"PulseWidth", 0)
	Variable wdd = NumVarOrDefault(tdf+"PulseWidthD", 0)
	Variable t2 = NumVarOrDefault(tdf+"PulseTau2", 0)
	Variable t2d = NumVarOrDefault(tdf+"PulseTau2D", 0)
	
	if (nwaves > 1)
		wlist += "All;"
		wn = ItemsInList(wlist)
	endif
	
	Prompt sh, "pulse shape:", popup shlist
	Prompt wn, "add pulse to output wave:", popup wlist
	Prompt wnd, "optional wave delta: (1) every wave, (2) every other wave..."
	Prompt am, "amplitude:"
	Prompt amd, "amplitude delta:"
	Prompt on, "onset time (ms):"
	Prompt ond, "onset delta (ms):"
	Prompt wd, "width (ms):"
	Prompt wdd, "width delta (ms):"
	Prompt t2, "decay tau (ms):"
	Prompt t2d, "decay tau delta (ms):"
	
	oldsh = sh

	if (nwaves == 1)
		wnd = 0
		DoPrompt title, sh
	else
		DoPrompt title, sh, wn, wnd
	endif

	if (V_flag == 1)
		return -1 // cancel
	endif
	
	if (sh == 5)
	
		PulseGetUserWave()
		
	elseif (sh != oldsh) // set default time constants
		switch(sh)
			case 3:
				wd = 2
				break
			case 4:
				wd = 2
				t2 = 3
				break
		endswitch
	endif
	
	wn -= 1
	
	if (wn == nwaves) // All
		wn = 0; wnd = 1;
	endif
	
	if (wnd == 0) // no wave increment
	
		ond = 0; amd = 0; wdd = 0; t2d = 0
	
		switch(sh)
			case 3:
				Prompt wd, "alpha time constant (ms):"
			case 1:
			case 2:
				DoPrompt title, am, on, wd
				break
			case 4:
				Prompt wd, "rise time constant (ms):"
				DoPrompt title, am, on, wd, t2
				break
		endswitch
	
	else // wave increment > 0
	
		switch(sh)
			case 3:
				Prompt wd, "alpha time constant (ms):"
			case 1:
			case 2:
				t2 = 0; t2d = 0;
				DoPrompt title, am, amd, on, ond, wd, wdd
				break
			case 4:
				Prompt wd, "rise time constant (ms):"
				DoPrompt title, am, amd, on, ond, wd, wdd, t2, t2d
				break
		endswitch
	
	endif
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMvar(tdf+"PulseShape", sh)
	SetNMvar(tdf+"PulseWaveN", wn)
	SetNMvar(tdf+"PulseWaveND", wnd)
	SetNMvar(tdf+"PulseAmp", am)
	SetNMvar(tdf+"PulseAmpD", amd)
	SetNMvar(tdf+"PulseOnset", on)
	SetNMvar(tdf+"PulseOnsetD", ond)
	SetNMvar(tdf+"PulseWidth", wd)
	SetNMvar(tdf+"PulseWidthD", wdd)
	SetNMvar(tdf+"PulseTau2", t2)
	SetNMvar(tdf+"PulseTau2D", t2d)
	
	PulseSave(sdf, wPrefix, pulseNum, sh, wn, wnd, on, ond, am, amd, wd, wdd, t2, t2d)
	
End // PulseEditDAC

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseEditTTL(pulseNum)
	Variable pulseNum // (-1) for new
	
	Variable icnt
	String title, wlist = ""
	
	if (pulseNum == -1)
		title = "New TTL Pulse Config"
	else
		title = "Edit TTL Pulse Config " + num2str(pulseNum)
	endif

	String tdf = ClampTabDF(), sdf = StimDF()
	
	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	
	Variable nwaves = NumVarOrDefault(sdf+"NumStimWaves", 1)
	
	for (icnt = 0; icnt < nwaves; icnt += 1)
		wlist = AddListItem("Wave"+num2str(icnt), wlist, ";", inf)
	endfor
	
	wlist += "All;"
	
	Variable sh = 1
	Variable wn = 1 + NumVarOrDefault(tdf+"PulseWaveN", 0)
	Variable wnd = NumVarOrDefault(tdf+"PulseWaveND", 0)
	Variable am = 1
	Variable amd = 0
	Variable on = NumVarOrDefault(tdf+"PulseOnset", 0)
	Variable ond = NumVarOrDefault(tdf+"PulseOnsetD", 0)
	Variable wd = NumVarOrDefault(tdf+"PulseWidth", 0)
	Variable wdd = NumVarOrDefault(tdf+"PulseWidthD", 0)
	Variable t2 = 0
	Variable t2d = 0
	
	Prompt wn, "add pulse to output wave:", popup wlist
	Prompt wnd, "optional wave delta: (1) every wave after, (2) every other wave after..."
	Prompt on, "onset time (ms):"
	Prompt ond, "onset delta (ms):"
	Prompt am, "amplitude:"
	Prompt amd, "amplitude delta:"
	Prompt wd, "width (ms):"
	Prompt wdd, "width delta (ms):"
	
	if (nwaves == 1)
		wnd = 0
		DoPrompt title, wn
	else
		DoPrompt title, wn, wnd
	endif
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	wn -= 1
	
	if (wn == nwaves) // All
		wn = 0; wnd = 1;
	endif
	
	if (wnd == 0)
		ond = 0; wdd = 0
		DoPrompt title, on, wd
	else
		DoPrompt title, on, ond, wd, wdd
	endif
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMvar(tdf+"PulseWaveN", wn)
	SetNMvar(tdf+"PulseWaveND", wnd)
	SetNMvar(tdf+"PulseOnset", on)
	SetNMvar(tdf+"PulseOnsetD", ond)
	SetNMvar(tdf+"PulseWidth", wd)
	SetNMvar(tdf+"PulseWidthD", wdd)
	
	PulseSave(sdf, wPrefix, pulseNum, sh, wn, wnd, on, ond, am, amd, wd, wdd, t2, t2d)
	
End // PulseEditTTL

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseClearCall()
	Variable pnum = 1
	String plist = PulseConfigList()

	String tdf = ClampTabDF(), sdf = StimDF()
	
	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	
	if (ItemsInList(plist) == 0)
		DoAlert 0, "No pulses to clear."
		return -1
	endif
	
	plist = "All;" + plist
	
	Prompt pnum, "choose pulse configuration:", popup plist
	DoPrompt "Clear Pulse Config", pnum
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	pnum -= 2
	
	PulseClear(sdf, wPrefix, pnum)

End // PulseClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTrainCall()
	Variable icnt
	String wlist = "", wlist2 = "", wname = ""
	
	String tdf = ClampTabDF(), sdf = StimDF(), cdf = ClampDF()
	
	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	
	Variable nwaves = NumVarOrDefault(sdf+"NumStimWaves", 1)
	
	for (icnt = 0; icnt < nwaves; icnt += 1)
		wlist = AddListItem("Wave"+num2str(icnt), wlist, ";", inf)
	endfor
	
	wlist += "All;"
	
	Variable npulses = 10
	Variable wn = 1 // NumVarOrDefault(tdf+"PulseWaveN", 0)
	Variable wnd = 0 // wave increment
	Variable tbeg = 0
	Variable tend = NumVarOrDefault(sdf+"WaveLength", 100)
	Variable type = 1 // (1) fixed (2) random
	Variable intvl = 10
	Variable refrac = 0
	Variable shape = NumVarOrDefault(tdf+"PulseShape", 1)
	Variable amp = NumVarOrDefault(tdf+"PulseAmp", 1)
	Variable width = NumVarOrDefault(tdf+"PulseWidth", 0)
	Variable tau2 = NumVarOrDefault(tdf+"PulseTau2", 0)
	Variable continuous = 0
	
	if (NumVarOrDefault(sdf+"AcqMode", 0) == 1)
		continuous = 1
	endif
	
	Prompt wn, "add pulses to wave:", popup wlist
	Prompt wnd, "optional wave delta: (1) every wave after, (2) every other wave after..."
	
	Prompt tend, "time window end (ms):"
	Prompt npulses, "number of pulses:"
	Prompt type, "pulse intervals:", popup "fixed intervals;random intervals;my intervals;"
	
	Prompt intvl, "inter-pulse interval (ms):"
	Prompt refrac, "refractory period (ms):"
	Prompt shape, "pulse shape:", popup "Square;Ramp;Alpha;2-Exp;Other;"
	
	Prompt amp, "pulse amplitude:"
	Prompt width, "pulse width:"
	Prompt tau2, "decay time constant (ms):"
	
	if (nwaves > 1)
		DoPrompt "Make Pulse Train", type, wn, wnd
	else
		DoPrompt "Make Pulse Train", type
	endif
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	wn -= 1
	
	if (wn == nwaves) // All
		wn = 0; wnd = 1;
	endif
	
	if (type == 1)
		Prompt tbeg, "first pulse onset time (ms):"
		Prompt intvl, "inter-pulse interval (ms):"
		DoPrompt "Make Pulse Train", shape, npulses, tbeg, intvl
		tend = tbeg + npulses * intvl
	elseif (type == 2)
		Prompt tbeg, "time window begin (ms):"
		Prompt intvl, "mean inter-pulse interval (ms):"
		DoPrompt "Make Pulse Train", shape, tbeg, tend, intvl, refrac
		wnd = 0
	elseif (type == 3)
		
		wlist2 = FolderObjectList(cdf, 1)
		
		if (strlen(wlist2) == 0)
			DoAlert 0, "No waves detected in root:Packages:Clamp directory"
			return -1 // no waves in Clamp directory
		endif
		
		Prompt tbeg, "time window begin (ms):"
		Prompt wname, "choose wave of pulse intervals (wave must be in root:Packages:Clamp directory):", popup wlist2
		DoPrompt "Make Pulse Train", wname, shape, tbeg, tend
		
		wname = cdf + wname
		
	endif
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	if (amp == 0)
		amp = 1
	endif
	
	switch(shape)
		case 1:
			DoPrompt "Square Pulse Dimensions", amp, width
			break
		case 2:
			DoPrompt "Ramp Dimensions", amp, width
			break
		case 3:
			width = 2
			Prompt width, "alpha time constant (ms):"
			DoPrompt "Alpha Pulse Dimensions", amp, width
			break
		case 4:
			width = 2
			tau2 = 3
			Prompt width, "rise time constant (ms):"
			DoPrompt "2-Exp Pulse Dimensions", amp, width, tau2
			break
		case 5:
			PulseGetUserWave()
			DoPrompt "User Pulse Dimensions", amp
			break
	endswitch
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMvar(tdf+"PulseShape", shape)
	SetNMvar(tdf+"PulseAmp", amp)
	SetNMvar(tdf+"PulseWidth", width)
	SetNMvar(tdf+"PulseTau2", tau2)
	
	PulseTrain(sdf, wPrefix, wn, nwaves-1, wnd, tbeg, tend, type, intvl, refrac, shape, amp, width, tau2, continuous, wname)

End // PulseTrainCall

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseRetrieve(pulseNum)
	Variable pulseNum
	Variable index, pNumVar = 12
	
	String tdf = ClampTabDF(), sdf = StimDF()

	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	String wname = PulseWaveName(sdf, wPrefix)
	
	if (WaveExists($wname) == 0)
		return 0
	endif

	Wave Pulse = $wname

	index = pulseNum * pNumVar

	if ((Pulse[index] <= 0) && (index + 11 < numpnts(Pulse)))
		
		SetNMvar(tdf+"PulseShape", Pulse[index+1])
		SetNMvar(tdf+"PulseWaveN", Pulse[index+2])
		SetNMvar(tdf+"PulseWaveND", Pulse[index+3])
		SetNMvar(tdf+"PulseOnset", Pulse[index+4])
		SetNMvar(tdf+"PulseOnsetD", Pulse[index+5])
		SetNMvar(tdf+"PulseAmp", Pulse[index+6])
		SetNMvar(tdf+"PulseAmpD", Pulse[index+7])
		SetNMvar(tdf+"PulseWidth", Pulse[index+8])
		SetNMvar(tdf+"PulseWidthD", Pulse[index+9])
		SetNMvar(tdf+"PulseTau2", Pulse[index+10])
		SetNMvar(tdf+"PulseTau2D", Pulse[index+11])
		
	endif

End // PulseRetrieve

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGetUserWave()
	String sdf = StimDF()

	String pname = StrVarOrDefault(sdf+"UserPulseName", "MyPulse")
	Prompt pname, "pulse wave name:"
	DoPrompt "User Pulse Wave", pname
	
	if (V_flag == 1)
		return -1
	endif
	
	if (exists(sdf+pname) == 0)
		DoAlert 0, "Error: wave '" + pname + "' does not reside in Stim folder " + sdf
		return -1
	endif
	
	SetNMStr(sdf+"UserPulseName", pname)
	
	return 0
			
End // PulseGetUserWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseConfigList()
	Variable pnum, icnt, npulses, index, pNumVar = 12
	String item, plist = ""

	String tdf = ClampTabDF(), sdf = StimDF()
	
	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	
	String wname = PulseWaveName(sdf, wPrefix)
	
	if (WaveExists($wname) == 0)
		return ""
	endif

	Wave Pulse = $wname
	
	npulses = numpnts(Pulse) / pNumVar
	
	if (npulses < 1)
		return ""
	endif
	
	for (icnt = 0; icnt < npulses; icnt += 1)
		index = icnt * pNumVar
		item = num2str(icnt) + " : "
		item += "wave" + num2str(Pulse[index+2]) + ","
		item += PulseShape(sdf, Pulse[index+1]) + ","
		item += "@" + num2str(Pulse[index+4]) + " ms"
		plist = AddListItem(item, plist, ";", inf)
	endfor
	
	return plist
	
End // PulseConfigList

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseConfigCheck()
	Variable index, value, icnt, pcnt, npulses, pNumVar = 12
	
	String numstr = "", clearList = "", tdf = ClampTabDF(), sdf = StimDF()
	
	Variable NumStimWaves = NumVarOrDefault(sdf+"NumStimWaves",1)
	Variable pulseNum = NumVarOrDefault(tdf+"PulseNum", 0)
	
	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	String wname = PulseWaveName(sdf, wPrefix)
	String errorStr = "pulse config " + num2str(pulseNum)
	
	if (WaveExists($wname) == 0)
		return 0
	endif

	Wave Pulse = $wname
	
	npulses = numpnts(Pulse) / pNumVar // should be whole number
	
	for (pcnt = 0; pcnt < npulses; pcnt += 1)
	
		index = pcnt * pNumVar
		
		errorStr = "pulse config " + num2str(pcnt)
		
		value = Pulse[index+1]
		
		if ((value < 1) || (value > 5)) // shape
			ClampError(errorStr + " shape out of range : " + num2str(value))
			Pulse[index+1] = 1
		endif
		
		value = Pulse[index+2]
		
		if ((value < 0) || (value >= NumStimWaves)) // waveN
			for (icnt = 0; icnt < NumStimWaves; icnt += 1)
				numstr = AddListItem("wave"+num2str(icnt), numstr, ";", inf)
			endfor
			Prompt value, "wave" + num2str(value) + " out or range. choose new wave or clear:", popup numstr + "clear config;"
			Print value, "wave" + num2str(value) + " out or range."
			value = 1
			//DoPrompt "Pulse Config " + num2str(pcnt) + " Error", value
			if (value <= NumStimWaves)
				Pulse[index+2] = value - 1
			else
				clearList = AddListItem(num2str(pcnt), clearList, ";", inf)
			endif
		endif
		
		value = Pulse[index+3]
		
		if (value < 0) // waveND
			ClampError(errorStr + " wave delta out of range : " + num2str(value))
			Pulse[index+3] = 0
		endif
		
		value = Pulse[index+4]
		
		if (value < 0) // onset
			ClampError(errorStr + " onset out of range : " + num2str(value))
			Pulse[index+4] = 0
		endif
		
		value = Pulse[index+5]
		
		if (value < 0) // onsetD
			ClampError(errorStr + " onset delta out of range : " + num2str(value))
			Pulse[index+5] = 0
		endif
		
		value = Pulse[index+7]
		
		if (value < 0) // ampD
			ClampError(errorStr + " amp delta out of range : " + num2str(value))
			Pulse[index+7] = 0
		endif
		
		value = Pulse[index+8]
		
		if (value < 0) // width
			ClampError(errorStr + " width out of range : " + num2str(value))
			Pulse[index+8] = 0
		endif
		
		value = Pulse[index+9]
		
		if (value < 0) // widthD
			ClampError(errorStr + " width delta out of range : " + num2str(value))
			Pulse[index+9] = 0
		endif
		
		value = Pulse[index+10]
		
		if (value < 0) // tau2
			ClampError(errorStr + " tau decay out of range : " + num2str(value))
			Pulse[index+10] = 0
		endif
		
		value = Pulse[index+11]
		
		if (value < 0) // tau2D
			ClampError(errorStr + " tau decay delta out of range : " + num2str(value))
			Pulse[index+11] = 0
		endif
	
	endfor
	
	for (icnt = 0; icnt < ItemsInList(clearList); icnt += 1)
		PulseClear(sdf, wPrefix, str2num(StringFromList(icnt,clearList)))
	endfor

End // PulseConfigCheck

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Pulse Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraph(force)
	Variable force
	
	String sdf = StimDF() // stim data folder
	
	Variable x0 = 90, y0 = 5, xinc = 150
	Variable madeGraph
	
	String titlestr, yLabel, io = "All"
	String wName, wList, wPrefix, wPrefixList

	String tdf = ClampTabDF()
	
	String gName = "PG_PulseGraph"
	String gTitle = StimCurrent()
	String Computer = StrVarOrDefault(NMDF()+"Computer", "mac")
	
	Variable numStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 1)
	
	Variable tabnum = NumVarOrDefault(tdf+"CurrentTab", 0)
	
	Variable allout = NumVarOrDefault(tdf+"PulseAllOutputs", 0)
	Variable allwaves = NumVarOrDefault(tdf+"PulseAllWaves",0)
	Variable wNum = NumVarOrDefault(tdf+"PulseWaveNum",0)
	Variable dsply = NumVarOrDefault(tdf+"PulseDisplay",1)
	
	if (dsply == 0)
		DoWindow /K $gName
		return 0
	endif
	
	if (StimChainOn() == 1)
		return 0
	endif
	
	switch(tabnum) // get available DAC/TTL waves to display
	
		case 3:
			io = "DAC"
			break
			
		case 4:
			io = "TTL"
			break
			
	endswitch
	
	if (allout == 1)
		io = "ALL"
	endif
	
	if ((force == 1) && (WinType("PG_PulseGraph") == 0))
		PulseWavesUpdate(-1, 1) // update all display waves
	endif
	
	if ((force == 1) || (WinType("PG_PulseGraph") == 1))
	
		if (allwaves == 1)
			wNum = -1
		endif
		
		if (StringMatch(io, "All") == 1)
			wPrefixList = StimPrefixListAll(sdf)
		else
			wPrefixList = StimPrefixList(sdf, io)
		endif
		
		wPrefixList = StimPrefixListAll(sdf)
		
		wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
		
		if (WhichListItemLax(wPrefix, wPrefixList, ";") == -1) // prefix not in list, try another
			if (ItemsInlist(wPrefixList) > 0)
				wPrefix = StringFromList(0,wPrefixList) 
			else
				wPrefix = "" 
			endif
		endif
		
		if (allout == 1)
			wPrefixList = RemoveFromList(wPrefix, wPrefixList)
			wPrefixList = AddListItem(wPrefix, wPrefixList) // this puts current prefix first
			wlist = StimWaveList(sdf, tdf, wPrefixList, wNum)
		else
			wlist = StimWaveList(sdf, tdf, wPrefix, wNum)
		endif
	
		if ((ItemsInlist(wlist) == 0) && (ItemsInlist(wPrefixList) > 0))
			wPrefix = StringFromList(0,wPrefixList) // no waves, try another prefix
			wlist = StimWaveList(sdf, tdf, wPrefix, wNum)
		endif
		
		SetNMstr(tdf+"PulsePrefix", wPrefix)

		madeGraph = PulseGraphUpdate(tdf, wlist) // NM_PulseGen.ipf
		
		if (madeGraph == 1)
		
			ModifyGraph margin(left)=60, margin(right)=0, margin(top)=19, margin(bottom)=0
			
			if (StringMatch(computer, "mac") == 1)
				y0 = 3
			endif
			
			Checkbox CT5_AllOutputs, pos={150,y0}, title="all outputs", size={16,18}, proc=PulseCheckBox
			Checkbox CT5_AllOutputs, value=0
	
			Checkbox CT5_AllWaves, pos={300,y0}, title="all waves", size={16,18}, proc=PulseCheckBox
			Checkbox CT5_AllWaves, value=1
	
			SetVariable CT5_WaveNum, title="wave", pos={450,y0-1}, size={80,50}, limits={0,inf,1}
			SetVariable CT5_WaveNum, value=$(tdf+"PulseWaveNum"), proc=PulseSetVar
			
		else
		
			Checkbox CT5_AllOutputs, win=PG_PulseGraph, value=NumVarOrDefault(tdf+"PulseAllOutputs", 0)
			Checkbox CT5_AllWaves, win=PG_PulseGraph, value=allwaves
			SetVariable CT5_WaveNum, win=PG_PulseGraph, limits={0,numStimWaves-1,1}
		
			if (allwaves == 1)
				SetNMvar(tdf+"PulseWaveNum", 0)
				SetVariable CT5_WaveNum, win=PG_PulseGraph, noedit = 1, limits={0,numStimWaves-1,0}
			else
				SetVariable CT5_WaveNum, win=PG_PulseGraph, noedit = 0, limits={0,numStimWaves-1,1}
			endif
			
		endif
	
		yLabel = StimConfigStr(sdf, wPrefix, "name")
		
		if (strlen(yLabel) == 0)
			yLabel = wPrefix
		else
			yLabel += " (" + StimConfigStr(sdf, wPrefix, "units") + ")"
		endif
		
		if (ItemsInList(wlist) > 0)
		
			Label /W=$gName left, yLabel
			Label /W=$gName bottom, "msec"
			
			if (allout == 0)
			
				if (allwaves == 0)
					gTitle += " : " + wPrefix + " : " + "Wave" + num2str(wNum)
				else
					gTitle += " : " + wPrefix + " : " + "All Waves"
				endif
				
			else
			
				if (allwaves == 0)
					gTitle += " : " + "All Outputs : " + "Wave" + num2str(wNum)
				else
					gTitle += " : " + "All Outputs : " + "All Waves"
				endif
				
			endif
			
		else

			strswitch(io)
			
				default:
					gTitle += " : " + "No Outputs"
					break
					
				case "DAC":
				case "TTL":
					gTitle += " : No " + io + " Outputs"
					
			endswitch
			
		endif
		
		DoWindow /T $gName, gTitle
		
		if (force == 1)
			//DoWindow /F PG_PulseGraph
		endif
		
	endif

End // PulseGraph

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseWavesUpdate(what, force)
	Variable what // (0) update current output (-1) update all output waves
	Variable force

	Variable icnt, outNum, ORflag
	String out, wprefix
	
	String sdf = StimDF(), tdf = ClampTabDF()
	
	String plist = StrVarOrDefault(tdf+"PulsePrefix", "")
	
	Variable off = NumVarOrDefault(sdf+"PulseGenOff", 0)
	
	if ((WinType("PG_PulseGraph") == 0) && (force == 0))
		return -1 // nothing to update
	endif
	
	if (what == -1)
		plist = StimPrefixListAll(sdf)
		StimWavesKill(tdf, plist) // kill all waves first
	endif
	
	for (icnt = 0; icnt < ItemsInList(plist); icnt += 1)
	
		wprefix = StringFromList(icnt, plist)
		out = wprefix[0,2]
		outNum = str2num(wprefix[4,inf])
		
		if (StringMatch(out, "TTL") == 1)
			ORflag = 1
		else
			ORflag = 0
		endif
		
		if (off == 0)
			PulseCloneUpdate(wPrefix)
		endif
		
		StimWavesMake(sdf, tdf, out, outNum, 1, ORflag)
		
	endfor

End // PulseWavesUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseWaveCheck(io, config)
	String io // "DAC" or "TTL"
	Variable config // config Num (-1) for all
	
	Variable icnt, ibgn = config, iend = config
	String wname, sdf = StimDF()
	
	wname = sdf + io + "on"
	
	if (WaveExists($wname) == 0)
		return -1
	endif
	
	Wave ioWave = $(sdf+io+"on")
	
	if (config == -1)
		ibgn = 0
		iend = numpnts(ioWave) - 1
	endif
	
	for (icnt = ibgn; icnt <= iend; icnt += 1)
	
		wname = PulseWaveName(sdf, io + "_" + num2str(icnt))
		
		if (ioWave[icnt] == 0)
			continue
		endif
		
		if (WaveExists($wname) == 0)
			Make /N=0 $wname
		endif
		
	endfor
	
	return 0
	
End // PulseWaveCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseCloneUpdate(wPrefix)
	String wPrefix
	
	String cdf = ClampDF(), sdf = StimDF(), tdf = ClampTabDF()
	
	String wname1 = PulseWaveName(sdf, wPrefix)
	String wname2 = PulseWaveName(tdf, wPrefix)
	
	if (WaveExists($wname1) == 1)
		Duplicate /O $wname1, $wname2
	elseif (WaveExists($wname2) == 1)
		Redimension /N=0 $wname2
	endif
	
	String userpulse = StrVarOrDefault(sdf+"UserPulseName", "")
	
	if ((strlen(userpulse) > 0) && (WaveExists($(sdf+userpulse)) == 1))
		SetNMstr(tdf+"UserPulseName", userpulse)
		Duplicate /O $(sdf+userpulse), $(tdf+userpulse)
	endif

End // PulseCloneUpdate

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Pulse Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableManager(select)
	Variable select // (0) update (1) make (2) save

	String sdf = StimDF(), tdf = ClampTabDF()
	
	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	String pname = PulseWaveName(sdf, wPrefix)
	
	switch(select)
		case 0:
		case 1:
			PulseTableUpdate(pname, select)
			break
		case 2:
			PulseTableSave(pname)
			break
	endswitch
	
End // PulseTableManager

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableUpdate(pName, force)
	String pName // pulse wave name
	Variable force // (0) update if exists (1) force make
	
	String wName, prefix = "PG_"
	String tName = prefix + "StimTable"
	String sdf = StimDF(), tdf = ClampTabDF()
	
	String wPrefix = StrVarOrDefault(tdf+"PulsePrefix", "")
	
	if (strlen(pName) == 0)
		pname = PulseWaveName(sdf, wPrefix)
	endif
	
	if (WinType(tName) == 0)
	
		if (force == 0)
			return 0
		else
			tName = PulseTableMake(pName, tdf, prefix)
		endif
		
	endif
		
	DoWindow /T $tName, GetPathName(pName,0)
	
	StimTableWavesUpdate(pName, tdf, prefix)
	
	wName = tdf + prefix + "Shape"
	
	CheckStimTableWaves(tdf, prefix, numpnts($wName)+10)

End // PulseTableUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseTableMake(pName, tdf, prefix)
	String pName, tdf, prefix
	
	String tName = StimTable(pName, tdf, prefix)
	
	SetWindow $tName hook=PulseTableHook
	
	return tName
	
End // PulseTableMake

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableHook(infoStr)
	string infoStr
	
	string event= StringByKey("EVENT",infoStr)
	string win= StringByKey("WINDOW",infoStr)
	
	if (StringMatch(win, "PG_StimTable") == 0)
		return 0 // wrong window
	endif
	
	strswitch(event)
		case "deactivate":
		case "kill":
			PulseTableManager(2)
			PulseWavesUpdate(0, 0)
			SetNMvar(StimDF()+"UpdateStim", 1)
	endswitch

End // PulseTableHook

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableSave(pname)
	String pname
	
	Variable icnt, index, ilmt, pNumVar = 12
	String tdf = ClampTabDF()
	
	String tName = "PG_StimTable"
	
	if (WinType(tName) == 0)
		return 0
	endif
	
	Wave Shape = $(tdf+"PG_Shape")
	Wave WaveN = $(tdf+"PG_WaveN")
	Wave WaveND = $(tdf+"PG_ND")
	Wave Onset = $(tdf+"PG_Onset")
	Wave OnsetD = $(tdf+"PG_OD")
	Wave Amp = $(tdf+"PG_Amp")
	Wave AmpD = $(tdf+"PG_AD")
	Wave Width = $(tdf+"PG_Width")
	Wave WidthD = $(tdf+"PG_WD")
	Wave Tau2 = $(tdf+"PG_Tau2")
	Wave Tau2D = $(tdf+"PG_TD")
	
	WaveStats /Q Shape
	
	ilmt = V_npnts
	
	if (WaveExists($pname) == 0)
		Make /O/N=(ilmt*pNumVar) $pname
	endif
	
	Wave Pulse = $pname
	
	Redimension /N=(ilmt*pNumVar) Pulse
	
	Pulse = Nan
		
	for (icnt = 0; icnt < ilmt; icnt += 1)
		
		index = icnt*pNumVar
		
		Pulse[index] = -icnt
		Pulse[index + 1] = Shape[icnt]
		Pulse[index + 2] = WaveN[icnt]
		Pulse[index + 3] = PulseTableValue(WaveND[icnt])
		Pulse[index + 4] = Onset[icnt]
		Pulse[index + 5] = PulseTableValue(OnsetD[icnt])
		Pulse[index + 6] = Amp[icnt]
		Pulse[index + 7] = PulseTableValue(AmpD[icnt])
		Pulse[index + 8] = Width[icnt]
		Pulse[index + 9] = PulseTableValue(WidthD[icnt])
		Pulse[index + 10] = PulseTableValue(Tau2[icnt])
		Pulse[index + 11] = PulseTableValue(Tau2D[icnt])
		
	endfor

End // PulseTableSave

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableValue(value)
	Variable value
	
	if (numtype(value) > 0)
		return 0
	else
		return value
	endif
	
End // PulseTableValue

//****************************************************************
//****************************************************************
//****************************************************************