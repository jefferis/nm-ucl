#pragma rtGlobals = 1
#pragma version = 2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Tab Control // Pulse Gen Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	Created in the Laboratory of Dr. Angus Silver
//	Department of Physiology, University College London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Began 1 July 2003
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabEnable( enable )
	Variable enable
	
	if ( enable == 1 )
	
		if ( CheckClampTabDF() == 1 )
			CheckClampTab()
		endif
		
		DisableNMPanel( 1 )
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

	if ( DataFolderExists( tdf ) == 0 )
		NewDataFolder $RemoveEnding( tdf, ":" )
		return 1
	endif
	
	return 0

End // CheckClampTabDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckClampTab() // declare Clamp Tab global variables
	String tdf = ClampTabDF(), cdf = ClampDF()
	
	if ( DataFolderExists( tdf ) == 0 )
		return 0 // folder doesnt exist
	endif
	
	CheckNMstr( tdf+"TabControlList", "File,CT1_;Configs,CT2_;Stim,CT3_;NMpanel,CT0_Tab;" )
	
	CheckNMvar( tdf+"CurrentTab", 0 )
	CheckNMvar( tdf+"StatsOn", 0 )
	CheckNMvar( tdf+"SpikeOn", 0 )
	
	CheckNMvar( tdf+"ADCnum", 0 )
	CheckNMvar( tdf+"DACnum", 0 )
	CheckNMvar( tdf+"TTLnum", 0 )
	
	CheckNMstr( tdf+"ADCname", "" )
	CheckNMstr( tdf+"DACname", "" )
	CheckNMstr( tdf+"TTLname", "" )
	
	// stim tab
	
	CheckNMstr( tdf+"StimTag", "" )
	CheckNMstr( tdf+"DataPrefix", "Record" )
	CheckNMstr( tdf+"PreStimFxnList", "" )
	CheckNMstr( tdf+"InterStimFxnList", "" )
	CheckNMstr( tdf+"PostStimFxnList", "" )
	
	CheckNMvar( tdf+"NumStimWaves", 1 )
	CheckNMvar( tdf+"InterStimTime", 0 )
	CheckNMvar( tdf+"WaveLength", 100 )
	CheckNMvar( tdf+"NumStimReps", 1 )
	CheckNMvar( tdf+"InterRepTime", 0 )
	CheckNMvar( tdf+"SampleInterval", 1 )
	CheckNMvar( tdf+"SamplesPerWave", 100 )
	CheckNMvar( tdf+"StimRate", 0 )
	CheckNMvar( tdf+"RepRate", 0 )
	
	CheckNMvar( tdf+"TotalTime", 0 )
	
	// config tab
	
	CheckNMstr( tdf+"UnitsList", "V;mV;A;nA;pA;S;nS;pS;" )
	
	CheckNMstr( tdf+"IOname", "" )
	CheckNMvar( tdf+"IOnum", 0 )
	CheckNMvar( tdf+"IOchan", 0 )
	CheckNMvar( tdf+"IOscale", 1 )
	CheckNMvar( tdf+"IOgain", 1 )
	
	// pulse gen tab
	
	CheckNMstr( tdf+"PulsePrefix", "" )
	CheckNMvar( tdf+"PulseShape", 1 )
	CheckNMvar( tdf+"PulseWaveN", 0 )
	CheckNMvar( tdf+"PulseWaveND", 0 )
	CheckNMvar( tdf+"PulseAmp", 1 )
	CheckNMvar( tdf+"PulseAmpD", 0 )
	CheckNMvar( tdf+"PulseOnset", 0 )
	CheckNMvar( tdf+"PulseOnsetD", 0 )
	CheckNMvar( tdf+"PulseWidth", 1 )
	CheckNMvar( tdf+"PulseWidthD", 0 )
	CheckNMvar( tdf+"PulseTau2", 0 )
	CheckNMvar( tdf+"PulseTau2D", 0 )
	
	// pulse/stim display variables
	
	CheckNMvar( tdf+"PulseAllOutputs", 0 )
	CheckNMvar( tdf+"PulseAllWaves", 1 )
	CheckNMvar( tdf+"PulseWaveNum", 0 )
	
End // CheckClampTab

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampFindShortName( ctrlName )
	String ctrlName
	
	if ( strsearch( ctrlName, "ADC", 0 ) > 0 )
		return "ADC"
	elseif ( strsearch( ctrlName, "DAC", 0 ) > 0 )
		return "DAC"
	elseif ( strsearch( ctrlName, "TTL", 0 ) > 0 )
		return "TTL"
	elseif ( strsearch( ctrlname, "Misc", 0 ) > 0 )
		return "Misc"
	elseif ( strsearch( ctrlname, "Time", 0 ) > 0 )
		return "Time"
	elseif ( strsearch( ctrlname, "Board", 0 ) > 0 )
		return "Board"
	elseif ( strsearch( ctrlname, "Pulse", 0 ) > 0 )
		return "Pulse"
	endif
	
	return ""

End // ClampFindShortName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabMake()

	Variable icnt, x0, y0, xinc, yinc, fs = NMPanelFsize()
	Variable nDACon = 4
	Variable nADCon = 8
	Variable nTTLon = 4
	Variable pwidth = NMPanelWidth(), pheight = NMPanelHeight(), taby = NMPanelTabY()
	
	Variable r = NMpanelRGB( "r" )
	Variable g = NMpanelRGB( "g" )
	Variable b = NMpanelRGB( "b" )
	
	String cdf = ClampDF(), tdf = ClampTabDF(), ndf = NotesDF()

	ControlInfo /W=NMpanel CT0_StimList 
	
	if ( V_Flag != 0 )
		return 0 // tab controls already exist
	endif
	
	if ( WinType( "NMpanel" ) != 7 )
		return -1
	endif
	
	DoWindow /F NMpanel
	
	x0 = 20
	y0 = taby + 40
	yinc = 30
	
	GroupBox CT0_StimGrp, title = "", pos={x0,y0-10}, size={260,70}, labelBack=( 43520,48896,65280 ), fsize=fs, win=NMpanel
	
	//PopupMenu CT0_StimMenu, pos={x0+45,y0}, size={15,0}, bodyWidth= 20, mode=1, title="stim:", proc=StimMenu, fsize=fs, win=NMpanel
	//PopupMenu CT0_StimMenu, value=" ;Open;Save;Save As;Close;Reload;---;Open All;Save All;Close All;---;New;Copy;Rename;---;Retrieve;---;Set Stim Path;Set Stim List;", win=NMpanel
	
	PopupMenu CT0_StimList, pos={x0+240,y0}, size={0,0}, bodyWidth=220, mode=1, value=" ", proc=StimListPopup, fsize=fs, win=NMpanel
	
	Button CT0_StartPreview, title="Preview", pos={x0+35,y0+yinc}, size={60,20}, proc=ClampButton, fsize=fs, win=NMpanel
	Button CT0_StartRecord, title="Record", pos={x0+110,y0+yinc}, size={60,20}, proc=ClampButton, fsize=fs, win=NMpanel
	Button CT0_Note, title="Note", pos={x0+185,y0+yinc}, size={40,20}, proc=ClampButton, fsize=fs, win=NMpanel
	
	SetVariable CT0_ErrorMssg, title=" ", pos={x0,605}, size={260,50}, value=$( cdf+"ClampErrorStr" ), fsize=fs, win=NMpanel
	
	TabControl CT0_Tab, pos={2, taby+110}, size={pwidth-4, 640}, labelBack=( r, g, b ), proc=ClampTabControl, fsize=fs, win=NMpanel
	
	MakeTabs( StrVarOrDefault( tdf+"TabControlList", "" ) )
	
	// File tab
	
	y0 = taby + 145
	xinc = 15
	yinc = 23
	
	GroupBox CT1_DataGrp, title = "Folders", pos={x0,y0}, size={260,118}, fsize=fs, win=NMpanel
	
	SetVariable CT1_FilePrefix, title= "prefix", pos={x0+xinc,y0+1*yinc}, size={125,50}, fsize=fs, win=NMpanel
	SetVariable CT1_FilePrefix, value=$( cdf+"FolderPrefix" ), proc=FileTabSetVariable, win=NMpanel
	
	SetVariable CT1_FileCellSet, title= "cell", pos={x0+150,y0+1*yinc}, size={65,50}, fsize=fs, win=NMpanel
	SetVariable CT1_FileCellSet, limits={0,inf,0}, value=$( cdf+"DataFileCell" ), proc=FileTabSetVariable, win=NMpanel
	
	Button CT1_FileNewCell, title="+", pos={x0+225,y0+1*yinc-2}, size={20,20}, proc=FileTabButton, fsize=fs, win=NMpanel
	
	SetVariable CT1_StimSuffix, title= "suffix", pos={x0+xinc,y0+2*yinc}, size={125,50}, fsize=fs, win=NMpanel
	SetVariable CT1_StimSuffix, value=$( tdf+"StimTag" ), proc=FileTabSetVariable, win=NMpanel
	
	SetVariable CT1_FileSeqSet, title= "seq", pos={x0+150,y0+2*yinc}, size={65,50}, fsize=fs, win=NMpanel
	SetVariable CT1_FileSeqSet, limits={0,inf,0}, value=$( cdf+"DataFileSeq" ), win=NMpanel
	
	SetVariable CT1_FilePathSet, title= "save to", pos={x0+xinc,y0+3*yinc}, size={230,50}, fsize=fs, win=NMpanel
	SetVariable CT1_FilePathSet, value=$( cdf+"ClampPath" ), proc=FileTabSetVariable, win=NMpanel
	
	Checkbox CT1_SaveConfig, pos={x0+xinc,y0+4*yinc}, title="save", size={10,20}, fsize=fs, win=NMpanel
	Checkbox CT1_SaveConfig, value=0, proc=FileTabCheckbox, win=NMpanel
	
	Checkbox CT1_CloseFolder, pos={x0+155,y0+4*yinc}, title="close previous", size={10,20}, fsize=fs, win=NMpanel
	Checkbox CT1_CloseFolder, value=0, proc=FileTabCheckbox, win=NMpanel
	
	y0 += 130
	yinc = 24
	
	GroupBox CT1_NotesGrp, title = "Notes", pos={x0,y0}, size={150,125}, fsize=fs, win=NMpanel
	
	SetVariable CT1_UserName, title= "name:", pos={x0+xinc,y0+1*yinc}, size={120,50}, fsize=fs, win=NMpanel
	SetVariable CT1_UserName, value=$( ndf+"H_Name" ), proc=FileTabSetVariable, win=NMpanel
	
	SetVariable CT1_UserLab, title= "lab:", pos={x0+xinc,y0+2*yinc}, size={120,50}, fsize=fs, win=NMpanel
	SetVariable CT1_UserLab, value=$( ndf+"H_Lab" ), proc=FileTabSetVariable, win=NMpanel
	
	SetVariable CT1_ExpTitle, title= "title:", pos={x0+xinc,y0+3*yinc}, size={120,50}, fsize=fs, win=NMpanel
	SetVariable CT1_ExpTitle, value=$( ndf+"H_Title" ), proc=FileTabSetVariable, win=NMpanel
	
	Button CT1_NotesEdit, title="Edit All", pos={x0+50,y0+4*yinc}, size={55,20}, proc=FileTabButton, fsize=fs, win=NMpanel
	
	GroupBox CT1_LogGrp, title = "Log", pos={x0+165,y0}, size={95,125}, fsize=fs, win=NMpanel
	
	PopupMenu CT1_LogMenu, pos={x0+245,y0+1*yinc}, size={0,0}, bodyWidth=65, proc=FileTabPopup, win=NMpanel
	PopupMenu CT1_LogMenu, value="Display;---;None;Text;Table;Both;", mode=1, fsize=fs, win=NMpanel
	
	Checkbox CT1_LogAutoSave, pos={x0+180,y0+3*yinc}, title="auto save", size={10,20}, win=NMpanel
	Checkbox CT1_LogAutoSave, value=0, proc=FileTabCheckbox, fsize=fs, win=NMpanel
	
	// Config Tab
	
	x0 = 20
	y0 = taby + 150
	xinc = 90
	yinc = 28
	
	PopupMenu CT2_InterfaceMenu, pos={x0+150,y0}, size={0,0}, bodyWidth=100, mode=1, disable=1, fsize=fs, title=" ", proc=ConfigsTabPopup, win=NMpanel
	PopupMenu CT2_InterfaceMenu, value=ConfigsTabPopupList(), popvalue=StrVarOrDefault( ClampDF()+"BoardSelect", "Demo" ), win=NMpanel
	
	
	Button CT2_Hide, title="Hide", pos={x0+190,y0+1}, size={50,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=NMpanel
	
	y0 += 60
	xinc = 15
	yinc = 28
	
	GroupBox CT2_IOgrp2, title = "Configuration", pos={x0,y0-25}, size={260,180}, disable=1, fsize=fs, win=NMpanel
	
	PopupMenu CT2_IOboard, title="board", pos={x0+143,y0}, size={0,0}, bodywidth=100, win=NMpanel
	PopupMenu CT2_IOboard, mode=1, value=" ", proc=ConfigsTabPopup, disable=1, fsize=fs, win=NMpanel
	
	PopupMenu CT2_IOunits, title="units", pos={x0+243,y0}, size={0,0}, proc=ConfigsTabPopup, win=NMpanel
	PopupMenu CT2_IOunits,bodywidth=55, mode=1, value="V;", disable=1, fsize=fs, win=NMpanel
	
	SetVariable CT2_IOchan, title= "chan", pos={x0+xinc,y0+1*yinc}, size={75,50}, limits={0,inf,1}, win=NMpanel
	SetVariable CT2_IOchan, value=$( tdf+"IOchan" ), proc=ConfigsTabSetVariable, disable=1, fsize=fs, win=NMpanel
	
	SetVariable CT2_IOscale, title= "scale ( V/V )", pos={x0+106,y0+1*yinc}, size={140,50}, limits={-inf,inf,0}, win=NMpanel
	SetVariable CT2_IOscale, value=$( tdf+"IOscale" ), proc=ConfigsTabSetVariable, disable=1, fsize=fs, win=NMpanel
	
	SetVariable CT2_IOname, title= "name", pos={x0+xinc,y0+2*yinc}, size={115,50}, win=NMpanel
	SetVariable CT2_IOname, value=$( tdf+"IOname" ), proc=ConfigsTabSetVariable, disable=1, fsize=fs, win=NMpanel
	
	//SetVariable CT2_IOgain, title= "gain", pos={x0+170,y0+2*yinc}, size={75,50}, limits={1,inf,1}, win=NMpanel
	//SetVariable CT2_IOgain, value=$( tdf+"IOgain" ), proc=ConfigsTabSetVariable, disable=1, fsize=fs, win=NMpanel
	
	Checkbox CT2_ADCpresamp, pos={x0+140,y0+2*yinc}, title="PreSamp/TeleGrph", size={10,20}, win=NMpanel
	Checkbox CT2_ADCpresamp, value=0, proc=ConfigsTabCheckbox, disable=1, fsize=fs, win=NMpanel
	
	y0 += 95
	xinc = 86
	
	GroupBox CT2_IOgrp1, title = "", pos={x0+10,y0-12}, size={240,1}, disable=1, fsize=fs, labelBack=( r, g, b ), win=NMpanel
	
	Checkbox CT2_ADCcheck, pos={x0+25,y0}, title="ADC", size={10,20}, mode=1, win=NMpanel
	Checkbox CT2_ADCcheck, value=1, proc=ConfigsTabCheckbox, disable=1, fsize=fs, win=NMpanel
	
	Checkbox CT2_DACcheck, pos={x0+25+1*xinc,y0}, title="DAC", size={10,20}, mode=1, win=NMpanel
	Checkbox CT2_DACcheck, value=0, proc=ConfigsTabCheckbox, disable=1, fsize=fs, win=NMpanel
	
	Checkbox CT2_TTLcheck, pos={x0+25+2*xinc,y0}, title="TTL", size={10,20}, mode=1, win=NMpanel
	Checkbox CT2_TTLcheck, value=0, proc=ConfigsTabCheckbox, disable=1, fsize=fs, win=NMpanel
	
	xinc = 27
	yinc = 24
	
	for ( icnt = 0; icnt < 7; icnt += 1 )
		Button $"CT2_IObnum"+num2istr( icnt ), title=num2istr( icnt ), pos={x0-10+( icnt+1 )*xinc,y0+1*yinc}, win=NMpanel
		Button $"CT2_IObnum"+num2istr( icnt ), size={20,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=NMpanel
	endfor
	
	SetVariable CT2_IOnum,pos={x0+42+6*xinc+2,y0+1*yinc+2}, size={40,15},limits={0,20,1}, title=" ", win=NMpanel
	SetVariable CT2_IOnum, value=$( tdf+"IOnum" ), proc=ConfigsTabSetVariable, disable=1, fsize=fs, win=NMpanel
	
	y0 += 75
	xinc = 64
	
	Button CT2_IOtable, title="Table", pos={x0+10,y0}, size={50,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=NMpanel
	Button CT2_IOreset, title="Reset", pos={x0+10+1*xinc,y0}, size={50,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=NMpanel
	Button CT2_IOextract, title="Extract", pos={x0+10+2*xinc,y0}, size={50,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=NMpanel
	Button CT2_IOsave, title="Save", pos={x0+10+3*xinc,y0}, size={50,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=NMpanel
	
	// Stim Misc Tab
	
	y0 = taby + 150
	xinc = 68
	yinc = 23
	
	GroupBox CT3_SelectGrp, title = "", pos={x0,y0-10}, size={260,35}, disable=1, fsize=fs, win=NMpanel
	
	Checkbox CT3_MiscCheck, pos={x0+10,y0}, title="Misc", size={10,20}, mode=1, win=NMpanel
	Checkbox CT3_MiscCheck, value=0, proc=StimTabCheckbox, disable=1, fsize=fs, win=NMpanel
	
	Checkbox CT3_TimeCheck, pos={x0+1*xinc-3,y0}, title="Time", size={10,20}, mode=1, win=NMpanel
	Checkbox CT3_TimeCheck, value=0, proc=StimTabCheckbox, disable=1, fsize=fs, win=NMpanel
	
	Checkbox CT3_Boardcheck, pos={x0+2*xinc-13,y0}, title="Ins / Outs", size={10,20}, mode=1, win=NMpanel
	Checkbox CT3_Boardcheck, value=0, proc=StimTabCheckbox, disable=1, fsize=fs, win=NMpanel
	
	Checkbox CT3_Pulsecheck, pos={x0+3*xinc,y0}, title="Pulse", size={10,20}, mode=1, win=NMpanel
	Checkbox CT3_Pulsecheck, value=0, proc=StimTabCheckbox, disable=1, fsize=fs, win=NMpanel
	
	y0 = taby + 150 + 45
	xinc = 65
	yinc = 25
	
	Checkbox CT3_ChainCheck, pos={x0+10,y0}, title="chain", size={10,20}, fsize=fs, win=NMpanel
	Checkbox CT3_ChainCheck, value=0, proc=StimTabCheckbox, disable=1, win=NMpanel
	
	Checkbox CT3_StatsCheck, pos={x0+10+1*xinc,y0}, title="stats", size={10,20}, fsize=fs, win=NMpanel
	Checkbox CT3_StatsCheck, value=0, proc=StimTabCheckbox, disable=1, win=NMpanel
	
	Checkbox CT3_SpikeCheck, pos={x0+10+2*xinc,y0}, title="spike", size={10,20}, fsize=fs, win=NMpanel
	Checkbox CT3_SpikeCheck, value=0, proc=StimTabCheckbox, disable=1, win=NMpanel
	
	Checkbox CT3_PNCheck, pos={x0+10+3*xinc,y0}, title="P / N", size={10,20}, fsize=fs, win=NMpanel
	Checkbox CT3_PNCheck, value=0, proc=StimTabCheckbox, disable=1, win=NMpanel
	
	y0 += 10
	
	SetVariable CT3_StimSuffix, title= "file name suffix", pos={x0+10,y0+1*yinc}, size={170,50}, fsize=fs, win=NMpanel
	SetVariable CT3_StimSuffix, value=$( tdf+"StimTag" ), proc=StimTabSetVariable, disable=1, win=NMpanel
	
	SetVariable CT3_ADCprefix, title= "wave name prefix", pos={x0+10,y0+2*yinc}, size={170,50}, fsize=fs, win=NMpanel
	SetVariable CT3_ADCprefix, value=$( tdf+"DataPrefix" ), proc=StimTabSetVariable, disable=1, win=NMpanel
	
	yinc = 30
	
	PopupMenu CT3_PreAnalysis, title="analysis", pos={x0+105,y0+3*yinc}, size={0,0}, bodywidth=55, win=NMpanel
	PopupMenu CT3_PreAnalysis, mode=1, value="Pre", proc=StimTabFxnPopup, disable=1, fsize=fs, win=NMpanel
	
	PopupMenu CT3_InterAnalysis, title="analysis", pos={x0+105,y0+4*yinc}, size={0,0}, bodywidth=55, win=NMpanel
	PopupMenu CT3_InterAnalysis, mode=1, value="Inter", proc=StimTabFxnPopup, disable=1, fsize=fs, win=NMpanel
	
	PopupMenu CT3_PostAnalysis, title="analysis", pos={x0+105,y0+5*yinc}, size={0,0}, bodywidth=55, win=NMpanel
	PopupMenu CT3_PostAnalysis, mode=1, value="Post", proc=StimTabFxnPopup, disable=1, fsize=fs, win=NMpanel
	
	SetVariable CT3_PreAnalysisList, title= " ", pos={x0+115,y0+3*yinc+2}, size={150,50}, fsize=fs, frame=0, win=NMpanel
	SetVariable CT3_PreAnalysisList, value=$( tdf+"PreStimFxnList" ), proc=StimTabSetVariable, disable=1, win=NMpanel
	
	SetVariable CT3_InterAnalysisList, title= " ", pos={x0+115,y0+4*yinc+2}, size={150,50}, fsize=fs, frame=0, win=NMpanel
	SetVariable CT3_InterAnalysisList, value=$( tdf+"InterStimFxnList" ), proc=StimTabSetVariable, disable=1, win=NMpanel
	
	SetVariable CT3_PostAnalysisList, title= " ", pos={x0+115,y0+5*yinc+2}, size={150,50}, fsize=fs, frame=0, win=NMpanel
	SetVariable CT3_PostAnalysisList, value=$( tdf+"PostStimFxnList" ), proc=StimTabSetVariable, disable=1, win=NMpanel
	
	// Stim Time Tab
	
	y0 = taby + 150 + 38
	xinc = 15
	yinc = 23
	
	PopupMenu CT3_AcqMode, title=" ", pos={x0+145,y0}, size={0,0}, bodywidth=130, fsize=fs, win=NMpanel
	PopupMenu CT3_AcqMode, mode=1, value="continuous;episodic;", proc=StimTabPopup, disable=1, win=NMpanel
	
	PopupMenu CT3_TauBoard, title=" ", pos={x0+240,y0}, size={0,0}, bodywidth=80, fsize=fs, win=NMpanel
	PopupMenu CT3_TauBoard, mode=1, value=" ", proc=StimTabPopup, disable=1, win=NMpanel
	
	y0 +=30
	
	GroupBox CT3_WaveGrp, title = "Waves", pos={x0,y0}, size={260,98}, disable=1, fsize=fs, win=NMpanel
	
	SetVariable CT3_NumStimWaves, title= "number", pos={x0+xinc,y0+1*yinc}, size={110,50}, limits={1,inf,0}, win=NMpanel
	SetVariable CT3_NumStimWaves, value=$( tdf+"NumStimWaves" ), proc=StimTabSetTau, disable=1, fsize=fs, win=NMpanel
	
	SetVariable CT3_WaveLength, title= "length (ms)", pos={x0+xinc+120,y0+1*yinc}, size={110,50}, fsize=fs, win=NMpanel
	SetVariable CT3_WaveLength, limits={0.001,inf,0}, value=$( tdf+"WaveLength" ), proc=StimTabSetTau, disable=1, win=NMpanel
	
	SetVariable CT3_SampleInterval, title= "tstep (ms)", pos={x0+xinc,y0+2*yinc}, size={110,50}, fsize=fs, win=NMpanel
	SetVariable CT3_SampleInterval, limits={0.001,inf,0}, value=$( tdf+"SampleInterval" ), proc=StimTabSetTau, disable=1, win=NMpanel
	
	SetVariable CT3_SamplesPerWave, title= "samples :", pos={x0+xinc+120,y0+2*yinc}, size={110,50}, fsize=fs, win=NMpanel
	SetVariable CT3_SamplesPerWave, limits={0,inf,0}, value=$( tdf+"SamplesPerWave" ), proc=StimTabSetTau, disable=1, frame=0, win=NMpanel
	
	SetVariable CT3_InterStimTime, title= "interlude (ms)", pos={x0+xinc,y0+3*yinc}, size={110,50}, fsize=fs, win=NMpanel
	SetVariable CT3_InterStimTime, limits={0,inf,0}, value=$( tdf+"InterStimTime" ), proc=StimTabSetTau, disable=1, win=NMpanel
	
	SetVariable CT3_StimRate, title= "stim rate (Hz) :", pos={x0+xinc+120,y0+3*yinc}, size={110,50}, fsize=fs, win=NMpanel
	SetVariable CT3_StimRate, limits={0,inf,0}, value=$( tdf+"StimRate" ), proc=StimTabSetTau, disable=1, frame=0, win=NMpanel
	
	x0 += 5
	
	y0 += 110
	
	GroupBox CT3_RepGrp, title = "Repetitions", pos={x0,y0}, size={260,76}, disable=1, fsize=fs, win=NMpanel
	
	SetVariable CT3_NumStimReps, title= "number", pos={x0+xinc,y0+1*yinc}, size={110,50}, fsize=fs, win=NMpanel
	SetVariable CT3_NumStimReps, limits={1,inf,0}, value=$( tdf+"NumStimReps" ), proc=StimTabSetTau, disable=1, win=NMpanel
	
	SetVariable CT3_TotalTime, title= "total time (sec) :", pos={x0+xinc+120,y0+1*yinc}, size={110,50}, fsize=fs, win=NMpanel
	SetVariable CT3_TotalTime, limits={0,inf,0}, value=$( tdf+"TotalTime" ), disable=1, frame=0, win=NMpanel
	
	SetVariable CT3_InterRepTime, title= "interlude (ms)", pos={x0+xinc,y0+2*yinc}, size={110,50}, fsize=fs, win=NMpanel
	SetVariable CT3_InterRepTime, limits={0,inf,0}, value=$( tdf+"InterRepTime" ), proc=StimTabSetTau, disable=1, win=NMpanel
	
	SetVariable CT3_RepRate, title= "rep rate (Hz) :", pos={x0+xinc+120,y0+2*yinc}, size={110,50}, fsize=fs, win=NMpanel
	SetVariable CT3_RepRate, limits={0,inf,0}, value=$( tdf+"RepRate" ), proc=StimTabSetTau, disable=1, frame=0, win=NMpanel
	
	// Stim Board Tab
	
	y0 = taby + 150 + 55
	xinc = 86
	yinc = 20
	
	GroupBox CT3_ADCgrp, title = "ADC in", pos={x0,y0-18}, size={xinc+2,185}, disable=1, fsize=fs, labelBack=( r, g, b ), win=NMpanel
	
	for ( icnt = 0; icnt < 8; icnt += 1 )
		PopupMenu $"CT3_ADC"+num2istr( icnt ),pos={x0+4,y0+icnt*yinc}, size={80,0}, bodywidth=80, disable=1, win=NMpanel
		PopupMenu $"CT3_ADC"+num2istr( icnt ), mode=1, title="", value="", proc=StimTabIOPopup, fsize=fs, win=NMpanel
	endfor
	
	GroupBox CT3_DACgrp, title = "DAC out", pos={x0+xinc,y0-18}, size={xinc+2,185}, disable=1, fsize=fs, labelBack=( r, g, b ), win=NMpanel
	
	for ( icnt = 0; icnt < 8; icnt += 1 )
		PopupMenu $"CT3_DAC"+num2istr( icnt ),pos={x0+1*xinc+4,y0+icnt*yinc}, size={80,0}, bodywidth=80, disable=1, win=NMpanel
		PopupMenu $"CT3_DAC"+num2istr( icnt ), mode=1, title="", value="", proc=StimTabIOPopup, fsize=fs, win=NMpanel
	endfor
	
	GroupBox CT3_TTLgrp, title = "TTL out", pos={x0+2*xinc,y0-18}, size={xinc+2,185}, disable=1, fsize=fs, labelBack=( r, g, b ), win=NMpanel
	
	for ( icnt = 0; icnt < 8; icnt += 1 )
		PopupMenu $"CT3_TTL"+num2istr( icnt ),pos={x0+2*xinc+4,y0+icnt*yinc}, size={80,0}, bodywidth=80, disable=1, win=NMpanel
		PopupMenu $"CT3_TTL"+num2istr( icnt ), mode=1, title="", value="", proc=StimTabIOPopup, fsize=fs, win=NMpanel
	endfor
	
	Checkbox CT3_GlobalConfigs, pos={x0+5,y0+9*yinc}, title="use global configs", size={10,20}, win=NMpanel
	Checkbox CT3_GlobalConfigs, value=1, proc=StimTabCheckbox, disable=1, fsize=fs, win=NMpanel
	
	Button CT3_IOtable, title="Table", pos={x0+130,y0+9*yinc}, size={55,20}, proc=StimTabButton, disable=1, fsize=fs, win=NMpanel
	
	Button CT3_Tab, title="Configs", pos={x0+200,y0+9*yinc}, size={55,20}, proc=StimTabButton, disable=1, fsize=fs, win=NMpanel
	
	// Stim Pulse Tab
	
	y0 = taby + 155 + 40
	xinc = 105
	yinc = 30
	
	PopupMenu CT3_WavePrefix,pos={x0+175,y0}, size={0,0}, bodywidth=140, disable=1, win=NMpanel
	PopupMenu CT3_WavePrefix, mode=1, title="Output", value="", proc=PulseTabPopup, fsize=fs, win=NMpanel
	
	Button CT3_Display, title="Plot", pos={x0+190,y0}, size={50,20}, proc=PulseTabButton, disable=1, fsize=fs, win=NMpanel
	
	y0 += 45
	
	GroupBox CT3_PulseGrp, title = "Pulse", pos={x0,y0-5}, size={260,125}, disable=1, fsize=fs, win=NMpanel
	
	Button CT3_New, title="New", pos={x0+35,y0+1*yinc-6}, size={85,20}, proc=PulseTabButton, disable=1, fsize=fs, win=NMpanel
	Button CT3_Clear, title="Clear", pos={x0+35+xinc,y0+1*yinc-6}, size={85,20}, proc=PulseTabButton, disable=1, fsize=fs, win=NMpanel
	Button CT3_Edit, title="Edit", pos={x0+35,y0+2*yinc-6}, size={85,20}, proc=PulseTabButton, disable=1, fsize=fs, win=NMpanel
	Button CT3_Train, title="Train", pos={x0+35+xinc,y0+2*yinc-6}, size={85,20}, proc=PulseTabButton, disable=1, fsize=fs, win=NMpanel
	Button CT3_Table, title="Pulse Table", pos={x0+85,y0+3*yinc-6}, size={100,20}, proc=PulseTabButton, disable=1, fsize=fs, win=NMpanel
	
	y0 += 140
	yinc = 40
	
	Checkbox CT3_PulseOff, pos={x0+70,y0}, title="use \"My\" waves", size={10,20}, win=NMpanel
	Checkbox CT3_PulseOff, value=1, disable=1, proc=PulseTabCheckbox, fsize=fs, win=NMpanel
	
	SetNMvar( tdf+"CurrentTab", 0 )

End // ClampTabMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabUpdate()
	
	ControlInfo /W=NMpanel CT0_StimList 
	
	if ( V_Flag == 0 )
		return 0 // tab controls dont exist
	endif

	String tdf = ClampTabDF()
	
	StimCurrentCheck()
	
	Variable select = WhichListItem( StimCurrent(), StimMenuList(), ";", 0, 0 ) + 1
	
	PopupMenu CT0_StimList, win=NMpanel, mode=select, value=StimMenuList()
	
	Variable currentTab = NumVarOrDefault( tdf+"CurrentTab", 0 )
	
	String TabList = StrVarOrDefault( tdf+"TabControlList", "" )
	String TabName = StringFromList( currentTab, TabList )
	
	TabName = StringFromList( 0, TabName, "," ) // current tab name
	
	EnableTab( currentTab, TabList, 1 )
	
	Execute /Z TabName + "Tab( 1 )"

End // ClampTabUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabDisable()
	Variable icnt
	
	String tlist = StrVarOrDefault( ClampTabDF()+"TabControlList", "" )

	for ( icnt = 0; icnt < ItemsInList( tlist )-1; icnt += 1 )
		EnableTab( icnt, tlist, 0 ) // disable tab controls
	endfor

End // ClampTabDisable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimMenuList()

	String d = " ;---; ;"
	String mList = "Stimulus Protocols;" + d + StimList()

	return mList + d + "Open;Save;Save As;Close;Reload;" + d + "Open All;Save All;Close All;" + d + "New;Copy;Rename;Retrieve;" + d + "Set Stim List;Set Stim Path; ;"

End // StimMenuList

//****************************************************************
//****************************************************************
//****************************************************************

Function StimCall( select )
	String select
	
	Variable new, ask, stimexists
	
	String sname = "", newname = ""
	String gdf, dp = StimParent(), sdf = StimDF()
	String slist = StimList()
	
	String currentStim = StimCurrent()
	String currentFile = StrVarOrDefault( sdf+"CurrentFile", "" )
	
	if ( strlen( currentStim ) > 0 )
		stimexists = 1
	endif
	
	ClampGraphsCopy( -1, 1 )
	
	strswitch( select )
		
		case "New":
			sname = StimNew( "" )
			StimCurrentSet( sname )
			break
			
		case "Open":
			sname = StimOpen( 1, "ClampStimPath", "" ) // open with dialogue
			break
			
		case "Reload":
			StimClose( currentStim )
			sname = StimOpen( 0, "ClampStimPath", currentFile ) // open without dialogue
			break
			
		case "Open All":
			StimOpenAll( "ClampStimPath" )
			break
			
		case "Save As":
			new = 1; ask = 1
	
		case "Save":
		
			if ( stimexists == 0 )
				break
			endif
			
			if ( NMStimStatsOn() == 1 )
				NMStimStatsUpdate()
				ClampStatsDisplaySavePositions()
			endif
			
			if ( NMStimSpikeOn() == 1 )
				ClampSpikeDisplaySavePosition()
			endif
			
			ClampGraphsCopy( -1, 1 )
			
			sname = StimSave( ask, new, currentStim )
			
			if ( StringMatch( sname, currentStim ) == 0 )
				StimCurrentSet( sname )
			endif
			
			break
			
		case "Save All":
			
			if ( ItemsInList( slist ) == 0 )
				break
			endif
		
			DoAlert 1, "Save all stimulus protocols to disk?"
			
			if ( V_flag != 1 )
				break
			endif
			
			if ( NMStimStatsOn() == 1 )
				NMStimStatsUpdate()
			endif
			
			ClampGraphsCopy( -1, 1 )
			
			StimSaveList( ask, new, slist )
		
			break
			
		case "Close":
		case "Kill":
			
			slist = RemoveFromList( currentStim, slist )
			
			if ( strlen( CurrentStim ) == 0 )
				break
			endif
			
			if ( StimClose( currentStim ) == -1 )
				break
			endif
				
			if ( ItemsInList( slist ) > 0 )
				StimCurrentSet( StringFromList( 0,slist ) ) // set to new stim
			else
				ClampTabUpdate()
			endif
			
			break
			
		case "Close All":
		case "Kill All":
			
			if ( ItemsInList( slist ) == 0 )
				break
			endif
			
			StimClose( slist )
			
			ClampTabUpdate()
			
			break
			
		case "Copy":
		
			if ( stimexists == 0 )
				break
			endif
			
			sname = currentStim + "_copy"
			
			Prompt sname, "new stimulus name:"
			DoPrompt "Copy Stimulus Protocol", sname
			
			if ( V_flag == 1 )
				break // cancel
			endif
			
			StimCopy( currentStim, sname )
			StimCurrentSet( sname )
			
			break
			
		case "Rename":
		
			if ( stimexists == 0 )
				break
			endif
			
			sname = currentStim
			
			Prompt sname, "rename stimulus as:"
			DoPrompt "Rename Stimulus Protocol", sname
			
			if ( ( V_flag == 1 ) || ( strlen( sname ) == 0 ) || ( StringMatch( sname, currentStim ) == 1 ) )
				break // cancel
			endif
			
			sname = FolderNameCreate( sname )
			
			if ( StimRename( currentStim, sname ) == 0 )
				StimCurrentSet( sname )
			endif
			
			break
			
		case "Retrieve":
		
			gdf = GetDataFolder( 1 )
			
			if ( ItemsInList( slist ) == 0 )
				DoAlert 0, "No Stim folder located in current data folder " + NMQuotes( GetDataFolder( 0 ) )
				break
			endif
			
			Prompt sname, "open:", popup slist
			DoPrompt "Retrieve Stimulus Protocol : " + gdf, sname
			
			if ( V_flag == 1 )
				break // cancel
			endif
			
			newname = CheckFolderName( dp+sname )
			
			DuplicateDataFolder $( gdf + sname ), $newname
			SetNMvar( newname+":StatsOn", 0 ) // make sure stats is OFF when retrieving
			StimCurrentSet( GetPathName( newname, 0 ) )
			StimWavesCheck( StimDF(), 0 )
			
			break
			
		case "Set Stim Path":
			ClampStimPathAsk()
			break
			
		case "Set Stim List":
			ClampStimListAsk()
			break
			
		default: // should be a stim
		
			if ( WhichListItem( select, slist, ";", 0, 0 ) >= 0 )
				ClampGraphsCopy( -1, 1 ) // save Chan graphs configs before changing
				StimCurrentSet( select )
			else
				
			endif
			
	endswitch
	
	StimWavesCheck( StimDF(), 0 )
	
	UpdateNMPanel( 0 )
	ClampTabUpdate()
	ChanGraphsUpdate()
	ClampGraphsCloseUnecessary()
	
	PulseGraph( 0 )
	PulseTableManager( 0 )
	
End // StimCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StimListPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ClampError( 0, "" )
	
	StimCall( popStr )
	
	//ClampTabUpdate()
	
End // StimListPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ClampError( 0, "" )
	
	ctrlName = ctrlName[ 4, inf ]

	strswitch( ctrlName )
	
		case "StartPreview":
			ClampAcquireCall( 0 )
			break
			
		case "StartRecord":
			ClampAcquireCall( 1 )
			break
		
		case "Note":
			NotesAddNote( "" )
			break
			
		//case "TGain":
		//	ClampTGainConfigCall()
		//	break
			
	endswitch

End // ClampButton

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampButtonDisable( mode )
	Variable mode // ( 0 ) preview ( 1 ) record ( -1 ) nothing
	String pf = "", rf = ""

	switch ( mode )
		case 0:
			pf = "\\K( 65280,0,0 )"
			break
		case 1:
			rf = "\\K( 65280,0,0 )"
			break
	endswitch
	
	Button CT0_StartPreview, win=NMpanel, title=pf+"Preview"
	Button CT0_StartRecord, win=NMpanel, title=rf+"Record"

End // ClampButtonDisable

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabControl( name, tab )
	String name; Variable tab
	
	ClampTabChange( tab )

End // ClampTabControl

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabChange( tab )
	Variable tab
	
	String cdf = ClampDF(), tdf = ClampTabDF()
	
	Variable lastTab = NumVarOrDefault( tdf+"CurrentTab", 0 )
	
	String CurrentStim = StimCurrent()
	
	ClampError( 0, "" )
	
	SetNMvar( tdf+"CurrentTab", tab )
	ChangeTab( lastTab, tab, StrVarOrDefault( tdf+"TabControlList", "" ) ) // NM_TabManager.ipf
	
	if ( tab == 2 ) // Pulse
		DoWindow /F PG_PulseGraph
		DoWindow /F PG_StimTable
	endif
	
End // ClampTabChange

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTabName() // return current tab name
	String tdf = ClampTabDF()

	Variable tabnum = NumVarOrDefault( tdf+"CurrentTab", 0 )
	
	return TabName( tabnum, StrVarOrDefault( tdf+"TabControlList", "" ) )

End // ClampTabName

//****************************************************************
//****************************************************************
//****************************************************************
//
//	File tab control functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function FileTab( enable ) // NM Clamp configure tab enable
	Variable enable
	
	String str, cdf = ClampDF(), tdf = ClampTabDF(), sdf = StimDF()
	
	if ( enable == 1 )
		
		SetNMstr( tdf+"StimTag", StrVarOrDefault( sdf+"StimTag", "" ) )
		
		// folder and file details
		
		GroupBox CT1_DataGrp, win=NMpanel, title="Folder : "+GetDataFolder( 0 )
		
		PathInfo /S ClampPath

		if ( strlen( S_path ) > 0 )
			SetNMStr( cdf+"ClampPath", S_path )
		endif
		
		Variable saveFormat = NumVarOrDefault( cdf+"SaveFormat", 1 )
		Variable saveWhen = NumVarOrDefault( cdf+"SaveWhen", 1 )
		
		str = "save"
		
		switch( saveFormat )
			case 1:
				str += " ( NM"
				break
			case 2:
				str += " ( Igor"
				break
			case 3:
				str += " ( NM,Igor"
				break
		endswitch
		
		switch( saveWhen )
			default:
				str = "save"
				break
			case 1:
				str += ";after )"
				break
			case 2:
				str += ";while )"
				saveWhen = 1
				break
		endswitch
		
		Checkbox CT1_SaveConfig, win=NMpanel, value=( saveWhen ), title=str
		Checkbox CT1_CloseFolder, win=NMpanel, value=NumVarOrDefault( cdf+"AutoCloseFolder", 1 )
		Checkbox CT1_LogAutoSave, win=NMpanel, value=( NumVarOrDefault( cdf+"LogAutoSave", 1 ) )
		
		Variable logdsply = NumVarOrDefault( cdf+"LogDisplay", 1 )
		
		PopupMenu CT1_LogMenu, win=NMpanel, mode=( logdsply+3 )
		
		//PulseGraph( 0 )
	
	endif

End // FileTab

//****************************************************************
//****************************************************************
//****************************************************************

Function FileTabCheckbox( ctrlName, checked ) : CheckboxControl
	String ctrlName; Variable checked
	
	ctrlName = ctrlName[ 4, inf ]
	
	FileTabCall( ctrlName, checked, "" )
	
End // FileTabCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function FileTabSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ctrlName[ 4, inf ]
	
	FileTabCall( ctrlName, varNum, varStr )
	
End // FileTabSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function FileTabPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ctrlName[ 4, inf ]
	
	FileTabCall( ctrlName, popNum, popStr )
	
End // FileTabPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function FileTabButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ctrlName[ 4, inf ]
	
	FileTabCall( ctrlName, Nan, "" )
	
End // FileTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function FileTabCall( select, varNum, varStr )
	String select
	Variable varNum
	String varStr
	
	ClampError( 0, "" )
	
	strswitch( select )
	
		case "SaveConfig":
			ClampSaveAsk()
			break
			
		case "CloseFolder":
			ClampFolderAutoCloseSet( varNum )
			break
			
		case "LogAutoSave":
			ClampLogAutoSaveSet( varNum )
			break
			
		case "FilePathSet":
			ClampPathSet( varStr )
			break
			
		case "FilePrefix":
			ClampFileNamePrefixSet( varStr )
			break
			
		case "StimSuffix":
			StimTagSet( "", varStr )
			break
			
		case "FileCellSet":
			if ( numtype( varNum ) == 0 )
				ClampDataFolderSeqReset()
			endif
			break
			
		case "FileNewCell":
			ClampDataFolderNewCell()
			break
			
		case "UserName":
		case "UserLab":
		case "ExpTitle":
			if ( WinType( NotesTableName() ) == 2 )
				NotesTable( 0 ) // update Notes table
			endif
			break
			
		case "NotesEdit":
			NotesTable( 1 )
			DoWindow /F $NotesTableName()
			break
			
		case "LogMenu":
			ClampLogDisplaySet( varStr )
			break
			
	endswitch
	
	FileTab( 1 )
	
End // FileTabCall

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim tab control functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function StimTab( enable )
	Variable enable
	
	Variable misc, tim, board, pulse
	
	Variable chain = StimChainOn( "" )
	String select = StimTabMode()
	
	if ( enable == 1 )
	
		strswitch( select )
			case "Misc":
				misc = 1
				Checkbox CT3_MiscCheck, win=NMpanel, value=1, title="\f01Misc"
				Checkbox CT3_TimeCheck, win=NMpanel, value=0, title="Time"
				Checkbox CT3_Boardcheck, win=NMpanel, value=0, title="Ins / Outs"
				Checkbox CT3_Pulsecheck, win=NMpanel, value=0, title="Pulse"
				break
			case "Time":
				tim = 1
				Checkbox CT3_MiscCheck, win=NMpanel, value=0, title="Misc"
				Checkbox CT3_TimeCheck, win=NMpanel, value=1, title="\f01Time"
				Checkbox CT3_Boardcheck, win=NMpanel, value=0, title="Ins / Outs"
				Checkbox CT3_Pulsecheck, win=NMpanel, value=0, title="Pulse"
				break
			case "Ins/Outs":
				board = 1
				Checkbox CT3_MiscCheck, win=NMpanel, value=0, title="Misc"
				Checkbox CT3_TimeCheck, win=NMpanel, value=0, title="Time"
				Checkbox CT3_Boardcheck, win=NMpanel, value=1, title="\f01Ins / Outs"
				Checkbox CT3_Pulsecheck, win=NMpanel, value=0, title="Pulse"
				break
			case "Pulse":
				pulse = 1
				Checkbox CT3_MiscCheck, win=NMpanel, value=0, title="Misc"
				Checkbox CT3_TimeCheck, win=NMpanel, value=0, title="Time"
				Checkbox CT3_Boardcheck, win=NMpanel, value=0, title="Ins / Outs"
				Checkbox CT3_Pulsecheck, win=NMpanel, value=1, title="\f01Pulse"
		endswitch
		
		if ( chain == 1 )
			tim = 0
			board = 0
			pulse = 0
		endif
		
		StimBoardConfigsUpdateAll( "" )
		
		StimTabMisc( misc )
		StimTabTime( tim )
		StimTabBoard( board )
		StimTabPulse( pulse )
		
	endif

End // StimTab

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabMisc( enable )
	Variable enable
	
	Variable chain = StimChainOn( "" )
	Variable pn = ClampPN()
	String pnstr, tdf = ClampTabDF(), sdf = StimDF()
		
	SetNMstr( tdf+"StimTag", StrVarOrDefault( sdf+"StimTag", "" ) )
	SetNMstr( tdf+"DataPrefix", StrVarOrDefault( sdf+"WavePrefix", "" ) )
	SetNMstr( tdf+"PreStimFxnList", StrVarOrDefault( sdf+"PreStimFxnList", "" ) )
	SetNMstr( tdf+"InterStimFxnList", StrVarOrDefault( sdf+"InterStimFxnList", "" ) )
	SetNMstr( tdf+"PostStimFxnList", StrVarOrDefault( sdf+"PostStimFxnList", "" ) )
	
	Checkbox CT3_ChainCheck, win=NMpanel, disable=!enable, value=chain
		
	if ( chain == 1 )
		enable = 0
	endif
	
	if ( pn == 0 )
		pnstr = "P / N"
	else
		pnstr = "P / " + num2istr( pn )
	endif
	
	Checkbox CT3_StatsCheck, win=NMpanel, disable=!enable, value=NMStimStatsOn()
	Checkbox CT3_SpikeCheck, win=NMpanel, disable=!enable, value=NMStimSpikeOn()
	Checkbox CT3_PNCheck, win=NMpanel, disable=!enable, value=pn, title=pnstr
	SetVariable CT3_ADCprefix, win=NMpanel, disable=!enable
	SetVariable CT3_StimSuffix, win=NMpanel, disable=!enable
	PopupMenu CT3_PreAnalysis, win=NMpanel, disable=!enable, mode=1, value="Pre;---;"+StrVarOrDefault( StimDF()+"PreStimFxnList", "" )+"---;Add to List;Remove from List;Clear List;"
	PopupMenu CT3_InterAnalysis, win=NMpanel, disable=!enable, mode=1, value="Inter;---;"+StrVarOrDefault( StimDF()+"InterStimFxnList", "" )+"---;Add to List;Remove from List;Clear List;"
	PopupMenu CT3_PostAnalysis, win=NMpanel, disable=!enable, mode=1, value="Post;---;"+StrVarOrDefault( StimDF()+"PostStimFxnList", "" )+"---;Add to List;Remove from List;Clear List;"
	SetVariable CT3_PreAnalysisList, win=NMpanel, disable=!enable
	SetVariable CT3_InterAnalysisList, win=NMpanel, disable=!enable
	SetVariable CT3_PostAnalysisList, win=NMpanel, disable=!enable
	
End // StimTabMisc

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabTime( enable )
	Variable enable
	
	Variable dis, tempvar, driver, slave, total
	String cdf = ClampDF(), sdf = StimDF(), tdf = ClampTabDF()
	String alist = StimAcqModeList()
	
	Variable amode = NumVarOrDefault( sdf+"AcqMode", 0 )
	Variable WaveLength = NumVarOrDefault( sdf+"WaveLength", 0 )
	Variable SampleInterval = StimIntervalGet( sdf, NumVarOrDefault( tdf+"CurrentBoard", 0 ) )
	Variable nReps = NumVarOrDefault( sdf+"NumStimReps", 0 )
	Variable repRate = NumVarOrDefault( sdf+"RepRate", 0 )

	SetNMvar( tdf+"NumStimWaves", NumVarOrDefault( sdf+"NumStimWaves", 1 ) )
	SetNMvar( tdf+"InterStimTime", NumVarOrDefault( sdf+"InterStimTime", 0 ) )
	
	SetNMvar( tdf+"WaveLength", WaveLength )
	SetNMvar( tdf+"SampleInterval", SampleInterval )
	SetNMvar( tdf+"SamplesPerWave", floor( WaveLength/SampleInterval ) )
	
	SetNMvar( tdf+"StimRate", NumVarOrDefault( sdf+"StimRate", 0 ) )
	SetNMvar( tdf+"NumStimReps", nReps )
	SetNMvar( tdf+"InterRepTime", NumVarOrDefault( sdf+"InterRepTime", 0 ) )
	SetNMvar( tdf+"RepRate", repRate )
	
	total = nReps/repRate
	
	SetNMvar( tdf+"TotalTime", total )
	SetNMvar( sdf+"TotalTime", total )
	
	// acquisition mode popup
	
	switch( amode )
		case 0:
			amode = 1+ WhichListItem( "epic precise", alist, ";", 0, 0 )
			break
		case 1:
			amode = 1+ WhichListItem( "continuous", alist, ";", 0, 0 )
			dis = 1
			break
		case 2:
			amode = 1+ WhichListItem( "episodic", alist, ";", 0, 0 )
			break
		case 3:
			amode = 1+ WhichListItem( "epic triggered", alist, ";", 0, 0 )
			break
		case 4:
			amode = 1+ WhichListItem( "continuous triggered", alist, ";", 0, 0 )
			dis = 1
			break
	endswitch
	
	PopupMenu CT3_AcqMode, win=NMpanel, value=StimAcqModeList(), mode=amode, disable=!enable
		
	// acq board popup
	
	tempvar = NumVarOrDefault( tdf+"CurrentBoard", 0 )
	driver = NumVarOrDefault( cdf+"BoardDriver", 0 )

	if ( tempvar == 0 ) // nothing selected
		tempvar = driver
	endif
	
	if ( tempvar != driver )
		slave = 1
	endif
	
	if ( tempvar == 0 )
		tempvar = 1
	endif
	
	PopupMenu CT3_TauBoard, win=NMpanel, mode=( tempvar ), value=StrVarOrDefault( ClampDF()+"BoardList", "" ), disable=!enable
	
	GroupBox CT3_WaveGrp, win=NMpanel, disable=!enable
	SetVariable CT3_NumStimWaves, win=NMpanel, disable=!enable
	SetVariable CT3_WaveLength, win=NMpanel, disable=!enable
	SetVariable CT3_SampleInterval, win=NMpanel, disable=!enable
	SetVariable CT3_SamplesPerWave, win=NMpanel, disable=!enable
	SetVariable CT3_InterStimTime, win=NMpanel, disable=(!enable || dis)
	SetVariable CT3_StimRate, win=NMpanel, disable=!enable
	
	GroupBox CT3_RepGrp, win=NMpanel, disable=!enable
	SetVariable CT3_NumStimReps, win=NMpanel, disable=!enable
	SetVariable CT3_InterRepTime, win=NMpanel, disable=(!enable || dis)
	SetVariable CT3_RepRate, win=NMpanel, disable=!enable
	SetVariable CT3_TotalTime, win=NMpanel, disable=!enable
	
End // StimTabTime

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabBoard( enable )
	Variable enable
	
	GroupBox CT3_ADCgrp, win=NMpanel, disable=!enable
	GroupBox CT3_DACgrp, win=NMpanel, disable=!enable
	GroupBox CT3_TTLgrp, win=NMpanel, disable=!enable
	
	PopupMenu $"CT3_ADC0", win=NMpanel, disable=!enable, mode=StimTabIOMode( "ADC", 0 ), value=StimTabIOList( "ADC", 0 )
	PopupMenu $"CT3_ADC1", win=NMpanel, disable=!enable, mode=StimTabIOMode( "ADC", 1 ), value=StimTabIOList( "ADC", 1 )
	PopupMenu $"CT3_ADC2", win=NMpanel, disable=!enable, mode=StimTabIOMode( "ADC", 2 ), value=StimTabIOList( "ADC", 2 )
	PopupMenu $"CT3_ADC3", win=NMpanel, disable=!enable, mode=StimTabIOMode( "ADC", 3 ), value=StimTabIOList( "ADC", 3 )
	PopupMenu $"CT3_ADC4", win=NMpanel, disable=!enable, mode=StimTabIOMode( "ADC", 4 ), value=StimTabIOList( "ADC", 4 )
	PopupMenu $"CT3_ADC5", win=NMpanel, disable=!enable, mode=StimTabIOMode( "ADC", 5 ), value=StimTabIOList( "ADC", 5 )
	PopupMenu $"CT3_ADC6", win=NMpanel, disable=!enable, mode=StimTabIOMode( "ADC", 6 ), value=StimTabIOList( "ADC", 6 )
	PopupMenu $"CT3_ADC7", win=NMpanel, disable=!enable, mode=StimTabIOMode( "ADC", 7 ), value=StimTabIOList( "ADC", 7 )
	
	PopupMenu $"CT3_DAC0", win=NMpanel, disable=!enable, mode=StimTabIOMode( "DAC", 0 ), value=StimTabIOList( "DAC", 0 )
	PopupMenu $"CT3_DAC1", win=NMpanel, disable=!enable, mode=StimTabIOMode( "DAC", 1 ), value=StimTabIOList( "DAC", 1 )
	PopupMenu $"CT3_DAC2", win=NMpanel, disable=!enable, mode=StimTabIOMode( "DAC", 2 ), value=StimTabIOList( "DAC", 2 )
	PopupMenu $"CT3_DAC3", win=NMpanel, disable=!enable, mode=StimTabIOMode( "DAC", 3 ), value=StimTabIOList( "DAC", 3 )
	PopupMenu $"CT3_DAC4", win=NMpanel, disable=!enable, mode=StimTabIOMode( "DAC", 4 ), value=StimTabIOList( "DAC", 4 )
	PopupMenu $"CT3_DAC5", win=NMpanel, disable=!enable, mode=StimTabIOMode( "DAC", 5 ), value=StimTabIOList( "DAC", 5 )
	PopupMenu $"CT3_DAC6", win=NMpanel, disable=!enable, mode=StimTabIOMode( "DAC", 6 ), value=StimTabIOList( "DAC", 6 )
	PopupMenu $"CT3_DAC7", win=NMpanel, disable=!enable, mode=StimTabIOMode( "DAC", 7 ), value=StimTabIOList( "DAC", 7 )
	
	PopupMenu $"CT3_TTL0", win=NMpanel, disable=!enable, mode=StimTabIOMode( "TTL", 0 ), value=StimTabIOList( "TTL", 0 )
	PopupMenu $"CT3_TTL1", win=NMpanel, disable=!enable, mode=StimTabIOMode( "TTL", 1 ), value=StimTabIOList( "TTL", 1 )
	PopupMenu $"CT3_TTL2", win=NMpanel, disable=!enable, mode=StimTabIOMode( "TTL", 2 ), value=StimTabIOList( "TTL", 2 )
	PopupMenu $"CT3_TTL3", win=NMpanel, disable=!enable, mode=StimTabIOMode( "TTL", 3 ), value=StimTabIOList( "TTL", 3 )
	PopupMenu $"CT3_TTL4", win=NMpanel, disable=!enable, mode=StimTabIOMode( "TTL", 4 ), value=StimTabIOList( "TTL", 4 )
	PopupMenu $"CT3_TTL5", win=NMpanel, disable=!enable, mode=StimTabIOMode( "TTL", 5 ), value=StimTabIOList( "TTL", 5 )
	PopupMenu $"CT3_TTL6", win=NMpanel, disable=!enable, mode=StimTabIOMode( "TTL", 6 ), value=StimTabIOList( "TTL", 6 )
	PopupMenu $"CT3_TTL7", win=NMpanel, disable=!enable, mode=StimTabIOMode( "TTL", 7 ), value=StimTabIOList( "TTL", 7 )
	
	Button CT3_IOtable, win=NMpanel, disable=!enable
	Button CT3_Tab, win=NMpanel, disable=!enable
	
	Checkbox CT3_GlobalConfigs, value=StimUseGlobalBoardConfigs( "" ), disable=!enable
	
End // StimTabBoard

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabPulse( enable )
	Variable enable
	
	Variable md
	String wPrefix, wlist
	String sdf = StimDF(), tdf = ClampTabDF()
	String gname = PulseGraphName()
	
	wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	wlist = StimPrefixListAll( sdf )
	
	if ( WhichListItem( wPrefix, wlist, ";", 0, 0 ) == -1 )
		wPrefix = ""
	endif

	if ( ( strlen( wPrefix ) == 0 ) && ( strlen( wlist ) > 0 ) )
		wPrefix = StringFromList( 0, wlist )
		SetNMstr( tdf+"PulsePrefix", wPrefix )
		wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	endif
	
	if ( strlen( wlist ) == 0 )
		wPrefix = ""
		SetNMstr( tdf+"PulsePrefix", wPrefix )
		PopupMenu CT3_WavePrefix, win=NMpanel, mode=1, value="no outputs;", disable=!enable
	else
		md = WhichListItem( wPrefix, wlist, ";", 0, 0 ) + 1
		PopupMenu CT3_WavePrefix, win=NMpanel, mode=md, value=StimNameListAll( StimDF() ), disable=!enable
	endif
	
	Button CT3_Display, win=NMpanel, disable=!enable
	
	PulseConfigCheck()
	
	GroupBox CT3_PulseGrp, win=NMpanel, title = "Pulse Config ( n = " + num2istr( PulseCount( sdf,wPrefix ) ) + " )", disable=!enable

	Button CT3_New, title="New", win=NMpanel, disable=!enable
	Button CT3_Clear, title="Clear", win=NMpanel, disable=!enable
	Button CT3_Edit, title="Edit", win=NMpanel, disable=!enable
	Button CT3_Train, title="Train", win=NMpanel, disable=!enable
	Button CT3_Table, title="Pulse Table", win=NMpanel, disable=!enable

	Checkbox CT3_PulseOff, win=NMpanel, value=NumVarOrDefault( sdf+"PulseGenOff", 0 ), disable=!enable
	
	PulseGraph( 0 )
	
	if ( enable == 1 )
	
		PulseTableManager( 0 )
		
		if ( WinType( gname ) == 1 )
			DoWindow /F $gname
		endif
	
	endif
	
End // StimTabPulse

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimTabMode()

	return StrVarOrDefault( ClampTabDF()+"StimTabMode", "Time" )

End // StimTabMode

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimTabIOList( io, config )
	String io
	Variable config

	Variable icnt
	String slist = " ;"
	String ludf = StimBoardLookUpDF( "" )
	String bdf = StimBoardDF( "" )
	
	if ( ( WaveExists( $bdf + io + "name" ) == 0 ) || ( WaveExists( $ludf + io + "name" ) == 0 ) )
		return "None"
	endif
	
	Wave /T IOnameS = $bdf + io + "name"
	Wave /T IOnameL = $ludf + io + "name"
	
	for ( icnt = 0; icnt < numpnts( IOnameL ); icnt += 1 )
		slist = AddListItem( IOnameL[icnt], slist, ";", inf )
	endfor
	
	for ( icnt = 0; icnt < numpnts( IOnameS ); icnt += 1 )
	
		if ( icnt == config )
			continue
		endif
		
		if ( strlen( IOnameS[icnt] ) > 0 )
			slist = RemoveFromList( IOnameS[icnt], slist )
		endif
		
	endfor
	
	if ( StringMatch( io, "ADC" ) == 1 )
		slist += ClampTGainConfigNameList()
	endif
	
	slist = AddListItem( "ERROR", slist, ";", inf )
	
	return slist

End // StimTabIOList

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabIOMode( io, config )
	String io
	Variable config
	
	Variable mode = 1
	String configName
	
	String bdf = StimBoardDF( StimDF() )
	String mlist = StimTabIOList( io, config )
	
	if ( ( WaveExists( $bdf+io+"name" ) == 0 ) || ( ItemsInList( mlist ) == 0 ) )
		return 1
	endif
	
	Wave /T name = $bdf + io + "name"
	
	configName = name[config]
	
	if ( strlen( configName ) > 0 )
	
		mode = WhichListItem( configName, mlist, ";", 0, 0 )
		
		if ( ( mode < 0 ) && ( StringMatch( configName[0,5], "TGain_" ) == 0 ) )
			mode = 1 + WhichListItem( "ERROR", mlist )
			ClampError( 0, "failed to find config " + NMQuotes( configName ) + ". Please reselect " + io + " config #" + num2istr( config ) )
		else
			mode += 1
		endif
			
	endif
	
	return max( mode, 1 )
	
End // StimTabIOMode

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabCall( select, varNum, varStr )
	String select
	Variable varNum
	String varStr
	
	ClampError( 0, "" )
	
	String tdf = ClampTabDF()
	String sdf = StimDF()
	
	strswitch( select )
	
		case "MiscCheck":
			SetNMstr( tdf+"StimTabMode", "Misc" )
			break
			
		case "TimeCheck":
			SetNMstr( tdf+"StimTabMode", "Time" )
			break
			
		case "BoardCheck":
			SetNMstr( tdf+"StimTabMode", "Ins/Outs" )
			break
			
		case "PulseCheck":
			SetNMstr( tdf+"StimTabMode", "Pulse" )
			break
	
		case "ChainCheck":
			StimChainSet( "", varNum )
			ClampTabUpdate()
			return 0
			
		case "StatsCheck":
			return NMStimStatsOnSet( varNum )
			
		case "SpikeCheck":
			return NMStimSpikeOnSet( varNum )
			
		case "PNCheck":
			return ClampPNenable( varNum )
			
		case "ADCprefix":
			StimWavePrefixSet( "", varStr )
			break
			
		case "StimSuffix":
			StimTagSet( "", varStr )
			break
			
		case "PreAnalysisList":
			StimFxnListSet( "", "Pre", varStr )
			break
		
		case "InterAnalysisList":
			StimFxnListSet( "", "Inter", varStr )
			break
			
		case "PostAnalysisList":
			StimFxnListSet( "", "Post", varStr )
			break
			
		case "AcqMode":
			StimAcqModeSet( "", varStr )
			StimWavesCheck( sdf, 1 )
			StimTabTauCheck()
			break
			
		case "TauBoard":
			SetNMvar( tdf+"CurrentBoard", varNum )
			break
			
		case "GlobalConfigs":
			StimUseGlobalBoardConfigsSet( "", varNum )
			break
			
		case "IOtable":
			StimIOtable()
			break
			
		case "Tab":
		case "Globals":
			ConfigsTabMake()
			return 0
	
	endswitch
	
	StimTab( 1 )
	
End // StimTabCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ctrlName[ 4, inf ]
	
	return StimTabCall( ctrlName, Nan, "" )
	
End // StimTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabCheckbox( ctrlName, checked ) : CheckboxControl
	String ctrlName; Variable checked
	
	ctrlName = ctrlName[ 4, inf ]
	
	StimTabCall( ctrlName, checked, "" )
	
End // StimTabCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ctrlName[ 4, inf ]
	
	StimTabCall( ctrlName, varNum, varStr )
	
End // StimTabSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ctrlName[ 4, inf ]
	
	StimTabCall( ctrlName, popNum, popStr )
	
End // StimTabPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabFxnPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	String select = ctrlName[ 4, inf ]
	
	ClampError( 0, "" )
	
	select = select[0,2]
	
	strswitch( popStr )
	
		case "Add to List":
			StimFxnListAddAsk( "", select )
			break
			
		case "Remove from List":
			StimFxnListRemoveAsk( "", select )
			break
			
		case "Clear List":
			StimFxnListClear( "", select )
			break
			
		default:
			if ( exists( popStr ) == 6 )
				Execute /Z popStr + "(1)" // call function's with config flag 1
			endif
			
	endswitch
	
	StimTab( 1 )
	
End // StimTabFxnPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabSetTau( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ClampError( 0, "" )
	
	Variable inter, update = 1, updateNM
	String tdf = ClampTabDF(), sdf = StimDF()
	
	Variable NumStimWaves = NumVarOrDefault( tdf+"NumStimWaves", 0 )
	Variable InterStimTime = NumVarOrDefault( tdf+"InterStimTime", 0 )
	Variable WaveLength = NumVarOrDefault( tdf+"WaveLength", 0 )
	Variable SampleInterval = NumVarOrDefault( tdf+"SampleInterval", 0.1 )

	strswitch( ctrlName[4,inf] )
	
		case "NumStimWaves":
			updateNM = 1
			break
	
		case "SampleInterval":
			break
		
		case "SamplesPerWave":
			SetNMVar( tdf+"WaveLength", varNum * SampleInterval )
			break
		
		case "StimRate":
			update = 0
			inter = ( 1000 / varNum ) - WaveLength
			if ( inter > 0 )
				SetNMvar( tdf+"InterStimTime", inter )
			else
				ClampError( 1, "stim rate not possible." )
			endif
			break
			
		case "RepRate":
			update = 0
			inter = ( 1000 / varNum ) - NumStimWaves * ( WaveLength + InterStimTime )
			if ( inter > 0 )
				SetNMVar( tdf+"InterRepTime", inter )
			else
				ClampError( 1, "rep rate not possible." )
			endif
			break
		
		case "InterStimTime":
		case "InterRepTime":
		case "NumStimReps":
			update = 0
			break
			
	endswitch
	
	StimTabTauCheck()
	
	if ( update == 1 )
		StimWavesCheck( sdf, 1 )
		PulseGraph( 0 )
	endif
	
	if ( updateNM == 1 )
		UpdateNMpanel( 0 )
	else
		StimTab( 1 )
	endif
	
End // StimTabSetTau

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabTauCheck() // check and save stim time variables

	String varName
	String cdf = ClampDF(), tdf = ClampTabDF(), sdf = StimDF()
	
	Variable acqMode = StimAcqMode( sdf )
	
	Variable NumStimWaves = NumVarOrDefault( tdf+"NumStimWaves", 1 )
	Variable InterStimTime = NumVarOrDefault( tdf+"InterStimTime", 0 )
	Variable WaveLength = NumVarOrDefault( tdf+"WaveLength", 100 )
	Variable StimRate = NumVarOrDefault( tdf+"StimRate", 0 )
	Variable SampleInterval = NumVarOrDefault( tdf+"SampleInterval", 0.1 )
	Variable SamplesPerWave = NumVarOrDefault( tdf+"SamplesPerWave", 1 )
	
	Variable NumStimReps = NumVarOrDefault( tdf+"NumStimReps", 1 )
	Variable InterRepTime = NumVarOrDefault( tdf+"InterRepTime", 0 )
	Variable RepRate = NumVarOrDefault( tdf+"RepRate", 0 )
	
	Variable CurrentBoard = NumVarOrDefault( tdf+"CurrentBoard", 0 )
	Variable BoardDriver = NumVarOrDefault( tdf+"BoardDriver", 0 )
	
	String AcqBoard = StrVarOrDefault( cdf+"AcqBoard", "" )
	
	switch( AcqMode )
	
		case 0: // epic precise
		case 2: // episodic
		case 3: // episodic triggered
		
			if ( InterStimTime == 0 )
				InterStimTime = 500
				ClampError( 1, "zero wave interlude time not allowed with episodic acquisition." )
			endif
			
			StimRate = 1000 / ( WaveLength + InterStimTime )
			RepRate = 1000 / ( InterRepTime + NumStimWaves * ( WaveLength + InterStimTime ) )
			
			break
			
		case 1: // continuous
		case 4: // continuous triggered
		
			if ( ( StringMatch( AcqBoard, "NIDAQ" ) == 1 ) && ( NumStimWaves > 1 ) )
				NumStimWaves = 1
				ClampError( 1, "only one stimulus wave is allowed with continuous acquisition." )
			endif
			
			StimRate = 1000 / WaveLength
			RepRate = 1000 / ( NumStimWaves * WaveLength )
	
	endswitch
	
	SampleInterval = floor( 1e8*SampleInterval ) / 1e8
	SamplesPerWave = floor( WaveLength/SampleInterval )

	SetNMVar( sdf+"NumStimWaves", NumStimWaves )
	SetNMVar( "NumGrps", NumStimWaves )
	SetNMVar( sdf+"InterStimTime", InterStimTime )
	SetNMVar( sdf+"WaveLength", WaveLength )
	SetNMVar( sdf+"StimRate", StimRate )
	SetNMVar( sdf+"SamplesPerWave", SamplesPerWave )
	
	SetNMVar( sdf+"NumStimReps", NumStimReps )
	SetNMVar( sdf+"InterRepTime", InterRepTime )
	SetNMVar( sdf+"RepRate", RepRate )
	
	StimIntervalSet( sdf, CurrentBoard, BoardDriver, SampleInterval )

End // StimTabTauCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabIOPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	Variable config, boardConfig, board, chan
	String io, tgain, oldName, cdf = ClampDF(), tdf = ClampTabDF()
	
	String tlist = ClampTGainConfigNameList()
	
	ClampError( 0, "" )
	
	ctrlName = ctrlName[ 4, inf ]
	
	io = ctrlName[0,2]
	
	config = str2num( ctrlName[3,inf] )
	
	oldName = StimBoardConfigName( "", io, config )
	
	if ( StringMatch( popStr, oldName ) == 1 )
	
		if ( WhichListItem( popStr, tlist ) >= 0 )
			ClampTGainConfigEditOld( str2num( popStr[6, inf] ) )
		else
			StimBoardConfigEdit( "", io, popStr )
		endif
		
	else
	
		StimBoardConfigActivate( "", io, config, popStr )
		StimBoardConfigsUpdate( "", io )
		
	endif
	
	StimTab( 1 )
	
End // StimTabIOPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StimIOtable()
	
	StimBoardNamesTable( "", 1 )
	
End // StimIOtable

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Board tab control functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigsTabIOselect()
	
	return ClampIOcheck( StrVarOrDefault( ClampTabDF()+"ConfigsTabIOselect", "ADC" ) )

End // ConfigsTabIOselect

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabIOnum()

	return NumVarOrDefault( ClampTabDF()+"IOnum", 0 )

End // ConfigsTabIOnum

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTab( enable )
	Variable enable
	
	Variable tempvar, icnt, config, board, chan, adc
	String tempstr, instr, cdf = ClampDF(), tdf = ClampTabDF()
	
	Variable driver = NumVarOrDefault( cdf+"BoardDriver", 0 )
	String blist = StrVarOrDefault( cdf+"BoardList", "" )
	String io = ConfigsTabIOselect()
	Variable tabNum = TabNumber( "Configs", StrVarOrDefault( tdf+"TabControlList", "" ) )
	
	config = ConfigsTabIOnum()
	
	if ( strlen( io ) == 0 )
		return -1
	endif
	
	if ( ( enable == 1 ) && ( tabNum >= 0 ) )
	
		PopupMenu CT2_InterfaceMenu, win=NMpanel, mode=1, value=ConfigsTabPopupList(), popvalue=StrVarOrDefault( ClampDF()+"BoardSelect", "Demo" )
		
		if ( WaveExists( $cdf+io+"board" ) == 0 )
			return -1
		endif
		
		SetNMvar( tdf+"IOnum", config )
		SetNMvar( tdf+"IOchan", WaveValOrDefault( cdf+io+"chan", config, 0 ) )
		SetNMvar( tdf+"IOscale", WaveValOrDefault( cdf+io+"scale", config, 0 ) )
		SetNMstr( tdf+"IOname", WaveStrOrDefault( cdf+io+"name", config, "" ) )
		
		strswitch( io )
			case "ADC":
				Checkbox CT2_ADCcheck, win=NMpanel, value=1, title="\f01ADC"
				Checkbox CT2_DACcheck, win=NMpanel, value=0, title="DAC"
				Checkbox CT2_TTLcheck, win=NMpanel, value=0, title="TTL"
				break
			case "DAC":
				Checkbox CT2_ADCcheck, win=NMpanel, value=0, title="ADC"
				Checkbox CT2_DACcheck, win=NMpanel, value=1, title="\f01DAC"
				Checkbox CT2_TTLcheck, win=NMpanel, value=0, title="TTL"
				break
			case "TTL":
				Checkbox CT2_ADCcheck, win=NMpanel, value=0, title="ADC"
				Checkbox CT2_DACcheck, win=NMpanel, value=0, title="DAC"
				Checkbox CT2_TTLcheck, win=NMpanel, value=1, title="\f01TTL"
				break
		endswitch
		
		// buttons
		
		for ( icnt = 0; icnt < 7; icnt += 1 )
			
			tempstr = ""
			
			if ( icnt == config )
				tempstr += "\\f01"
			else
				tempstr += "\\K( 21760,21760,21760 )"
			endif
			
			Button $( "CT2_IObnum"+num2istr( icnt ) ), win=NMpanel, title=tempstr + num2istr( icnt )
			
		endfor
		
		// board popup
		
		board = WaveValOrDefault( cdf+io+"board", config, 0 )
		
		if ( ( numtype( board ) > 0 ) || ( board <= 0 ) ) // something wrong
			board = NumVarOrDefault( cdf+"BoardDriver", 0 )
		endif
		
		tempstr = ClampBoardName( board )
		
		tempvar = WhichListItem( tempstr, blist, ";", 0, 0 )
		
		if ( tempvar < 0 )
			DoAlert 0, "Config Error: cannot locate board #" + num2istr( board ) + ". Please select a new board."
		endif
		
		PopupMenu CT2_IOboard, win=NMpanel, mode=( tempvar+1 ), value=StrVarOrDefault( ClampDF()+"BoardList", "" )
		
		// units popup
		
		tempstr = WaveStrOrDefault( cdf+io+"units", config, "" )
		tempvar = WhichListItem( tempstr, StrVarOrDefault( tdf+"UnitsList", "" ), ";", 0, 0 ) + 1
		PopupMenu CT2_IOunits, win=NMpanel, mode=( tempvar ), value=StrVarOrDefault( ClampTabDF()+"UnitsList", "" ) + "Other...;"
		
		// scale
		
		if ( StringMatch( io, "ADC" ) == 1 )
			tempstr = "scale ( V/" + tempstr + " ):"
		else
			tempstr = "scale ( " + tempstr + "/V ):"
		endif
		
		SetVariable CT2_IOscale, win=NMpanel, title=tempstr
		
		if ( StringMatch( io, "ADC" ) == 1 )
			
			tempvar = 0
			tempstr = WaveStrOrDefault( cdf+io+"mode", config, "" )
			
			if ( strsearch( tempstr, "PreSamp=", 0 ) >= 0 )
			
				tempvar = 1
				
			elseif ( strsearch( tempstr, "=", 0 ) >= 0 ) // could be a Telegraph
			
				tempstr = ClampTelegraphStrShort( tempstr )
				
				if ( strlen( tempstr ) > 0 )
					tempvar = 1 // yes, it's Telegraph
				endif
				
			endif
			
			if ( tempvar == 0 )
				tempstr = "PreSamp/TeleGrph"
			endif
			
			Checkbox CT2_ADCpresamp, win=NMpanel, disable=0, value=( tempvar ), title=tempstr
			
		else
		
			Checkbox CT2_ADCpresamp, win=NMpanel, disable=1
			
		endif
		
		strswitch( io )
			case "ADC":
				GroupBox CT2_IOgrp2, win=NMpanel, title = io + " Input Config " + num2istr( config )
				break
			case "DAC":
			case "TTL":
				GroupBox CT2_IOgrp2, win=NMpanel, title = io + " Output Config " + num2istr( config )
				break
		endswitch
		
	endif

End // ConfigsTab

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigsTabPopupList()
	String blist = "Demo;"
	String board = StrVarOrDefault( ClampDF()+"AcqBoard", "" )
	
	if ( StringMatch( "Demo", board ) == 1 )
		return blist
	endif
	
	return AddListItem( board, blist, ";", inf )

End // ConfigsTabPopupList

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabCall( select, varNum, varStr )
	String select
	Variable varNum
	String varStr
	
	Variable config = ConfigsTabIOnum()
	String io = ConfigsTabIOselect()
	String tdf = ClampTabDF()
	
	ClampError( 0, "" )
	
	strswitch( select )
	
		case "ADCcheck":
			ConfigsTabIOset( "ADC" )
			break
			
		case "DACcheck":
			ConfigsTabIOset( "DAC" )
			break
			
		case "TTLcheck":
			ConfigsTabIOset( "TTL" )
			break
	
		case "InterfaceMenu":
			ClampBoardSet( varStr )
			break
			
		case "ADCpresamp":
			ConfigsTabPreSampAsk( varNum )
			break
			
		case "IOname":
			ClampBoardNameSet( io, config, varStr )
			break
			
		case "IOunits":
			if ( strsearch( varStr, "Other", 0 ) >= 0 )
				varStr = ConfigsTabUnitsAsk()
			endif
			ClampBoardUnitsSet( io, config, varStr )
			break
			
		case "IOboard":
			ClampBoardBoardSet( io, config, varNum )
			break
			
		case "IOchan":
			ClampBoardChanSet( io, config, varNum )
			break
			
		case "IOscale":
			ClampBoardScaleSet( io, config, varNum )
			break
		
		case "IOnum":
			ConfigsTabConfigNumSet( varNum )
			break
			
		case "IOtable":
			ClampBoardTable( io, "", 1 )
			break
			
		case "IOreset":
			ConfigsTabWavesResetAsk()
			break
			
		case "IOextract":
			ConfigsTabConfigsFromStims()
			break
			
		case "IOsave":
			ClampBoardWavesSave()
			break
			
		case "Hide":
			ConfigsTabHide()
			break
			
		default:
		
			if ( strsearch( select, "IObnum", 0 ) >= 0 )
				ConfigsTabConfigNumSet( str2num( select[6, inf] ) )
			endif
	
	endswitch
	
	ConfigsTab( 1 )

End // ConfigsTabCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ctrlName[ 4, inf ]
	
	return ConfigsTabCall( ctrlName, popNum, popStr )
	
End // ConfigsTabPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ctrlName[ 4, inf ]
	
	return ConfigsTabCall( ctrlName, varNum, varStr )
	
End // ConfigsTabSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ctrlName[ 4, inf ]
	
	return ConfigsTabCall( ctrlName, Nan, "" )
	
End // ConfigsTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabCheckbox( ctrlName, checked ) : CheckboxControl
	String ctrlName; Variable checked
	
	ctrlName = ctrlName[ 4, inf ]
	
	return ConfigsTabCall( ctrlName, checked, "" )
	
End // ConfigsTabCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabHide()

	DoAlert 1, "Hide this tab?"
	
	if ( V_flag == 1 )
		ConfigsTabKill()
	endif

End // ConfigsTabHide

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabKill()

	String tdf = ClampTabDF()
	String tabList = StrVarOrDefault( tdf+"TabControlList", "" )
	Variable tabNum = TabNumber( "Configs", tabList )
	
	if ( tabNum < 0 )
		return -1 // tab does not exist
	endif
	
	ClampTabChange( 0 )
	
	KillTabControls( tabNum, tabList )

	SetNMstr( tdf+"TabControlList", "File,CT1_;Stim,CT3_;NMpanel,CT0_Tab;" )
	
	MakeNMpanel()

End // ConfigsTabKill

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabMake()

	String tdf = ClampTabDF()
	String tabList = StrVarOrDefault( tdf+"TabControlList", "" )
	Variable tabNum = TabNumber( "Configs", tabList )
	
	if ( DataFolderExists( tdf ) == 0 )
		return -1
	endif
	
	if ( tabNum >= 0 )
		ClampTabChange( 1 )
		return 0 // tab exists
	endif

	SetNMstr( tdf+"TabControlList", "File,CT1_;Configs,CT2_;Stim,CT3_;NMpanel,CT0_Tab;" )
	
	MakeNMpanel()
	
	ClampTabChange( 1 )
	
	return 0

End // ConfigsTabMake

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigsTabUnitsAsk()

	String unitstr = "", tdf = ClampTabDF()
	String unitsList = StrVarOrDefault( tdf+"UnitsList", "" )
	
	Prompt unitstr "enter channel units:"
	DoPrompt "Other Channel Units", unitstr
	
	if ( ( V_flag == 1 ) || ( strlen( unitstr ) == 0 ) )
		return ""
	endif

	if ( WhichListItem( unitstr, unitsList, ";", 0, 0 ) == -1 )
		unitstr = unitsList + unitstr + ";"
		SetNMStr( tdf+"UnitsList", unitstr )
	endif
	
	return unitstr

End // ConfigsTabUnitsAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabIOset( io )
	String io
	
	String cdf = ClampDF(), tdf = ClampTabDF()
	Variable config = ConfigsTabIOnum()
	
	if ( strlen( ClampIOcheck( io ) ) == 0 )
		return -1
	endif
	
	SetNMstr( tdf+"ConfigsTabIOselect", io )
	
	if ( config >= numpnts( $cdf+io+"name" ) )
		SetNMvar( tdf+"IOnum", 0 )
	endif
	
End // ConfigsTabIOset

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabConfigNumSet( config )
	Variable config
	
	String cdf = ClampDF(), io = ConfigsTabIOselect()
	
	SetNMvar( ClampTabDF()+"IOnum", config )
	
	if ( config >= numpnts( $cdf+io+"name" ) )
		ClampBoardWavesRedimen( io, config + 1 )
	endif
	
End // ConfigsTabConfigNumSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabWavesResetAsk()

	Variable config = ConfigsTabIOnum()
	String io = ConfigsTabIOselect()
	String tdf = ClampTabDF()

	Variable this = NumVarOrDefault( tdf+"ConfigsTabResetThis", 1 )
	
	Prompt this " ", popup "This " + io + " Config ( #" + num2istr( config ) + " );All " + io + " Configs;All ADC, DAC and TTL Configs;"
	DoPrompt "Reset Board Configs", this
		
	if ( V_flag == 1 )
		return 0
	endif
	
	if ( this == 2 )
		config = -1
	endif
	
	SetNMvar( tdf+"ConfigsTabResetThis", this )
	
	switch( this )
		case 1:
			return ClampBoardWavesReset( io, config )
		case 2:
			return ClampBoardWavesReset( io, -1 )
		case 3:
			return ClampBoardWavesReset( "ADC", -1 ) + ClampBoardWavesReset( "DAC", -1 ) + ClampBoardWavesReset( "TTL", -1 )
	endswitch
	
	return -1

End // ConfigsTabWavesResetAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigsTabPreSampAsk( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	Variable numSamples = 10
	String name, select = "PreSample", modeStr = ""
	
	String cdf = ClampDF()
	
	Variable config = ConfigsTabIOnum()
	
	if ( on == 1 )
		
		Prompt select " ", popup "PreSample;Telegraph Gain;Telegraph Mode;Telegraph Freq;Telegraph Cap;"
		DoPrompt "ADC input", select
		
		if ( V_flag == 0 )
		
			strswitch( select )
		
				case "PreSample":
		
					Prompt numSamples "number of samples to acquire:"
					DoPrompt "Pre-sample ADC input", numSamples
					
					if ( V_flag == 0 )
						modeStr = "PreSamp=" + num2istr( numSamples )
					endif
					
					break
			
				case "Telegraph Gain":
					modeStr = ClampTGainPrompt()
					break
					
				case "Telegraph Mode":
					modeStr = ClampTelegraphPrompt( "Mode" )
					break
				
				case "Telegraph Freq":
					modeStr = ClampTelegraphPrompt( "Freq" )
					break
				
				case "Telegraph Cap":
					modeStr = ClampTelegraphPrompt( "Cap" )
					break
					
			endswitch
		
		endif
		
	else
	
		name = WaveStrOrDefault( cdf + "ADCname", config, "" )
	
		if ( StringMatch( name[0, 4], "TGain" ) == 1 )
			name = ClampBoardNextDefaultName( "ADC", config )
			ClampBoardNameSet( "ADC", config, name )
		elseif ( StringMatch( name[0, 4], "Tmode" ) == 1 )
			name = ClampBoardNextDefaultName( "ADC", config )
			ClampBoardNameSet( "ADC", config, name )
		elseif ( StringMatch( name[0, 4], "TFreq" ) == 1 )
			name = ClampBoardNextDefaultName( "ADC", config )
			ClampBoardNameSet( "ADC", config, name )
		elseif ( StringMatch( name[0, 3], "TCap" ) == 1 )
			name = ClampBoardNextDefaultName( "ADC", config )
			ClampBoardNameSet( "ADC", config, name )
		endif
		
	endif
	
	return ClampBoardModeSet( config, modeStr )
	
End // ConfigsTabPreSampAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigsTabTGainPrompt()

	Variable board, chan, output
	String name, chanStr, modeStr = ""
	
	String tdf = ClampTabDF(), cdf = ClampDF()

	Variable config = ConfigsTabIOnum()
	String instr = StrVarOrDefault( tdf+"TelegraphInstrument", "" )
	String blist = StrVarOrDefault( cdf+"BoardList", "" )

	Prompt instr "telegraphed instrument:", popup ClampTelegraphInstrList()
	
	DoPrompt "Telegraph Gain", instr
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( tdf+"TelegraphInstrument", instr )
	
	if ( StringMatch( instr, "MultiClamp700" ) == 1 )
	
		chan = 1
		output = 1
		
		Prompt chan "this ADC input is connected to channel:", popup "1;2;"
		Prompt output " ", popup "primary output;secondary output;"
		
		DoPrompt "MultiClamp700 Telegraph Gain", chan, output
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		return ClampTGainStrMultiClamp( chan, output )
	
	endif
	
	Prompt chan "ADC input channel to scale:"
	Prompt board "on board number:", popup blist
	
	if ( ItemsInList( blist ) > 1 )
		DoPrompt instr + " Telegraph Gain", chan, board
	else
		DoPrompt instr + " Telegraph Gain", chan
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	name = "TGain_" + instr[0, 2]

	modeStr = ClampTGainStr( board, chan, instr )
	
	ClampBoardNameSet( "ADC", config, name )
	ClampBoardUnitsSet( "ADC", config, "V" )
	ClampBoardScaleSet( "ADC", config, 1 )
	
	SetNMstr( tdf+"TelegraphInstrument", instr )
	
	return modeStr
	
End // ConfigsTabTGainPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabConfigsFromStims()
	String ctrlName
	
	Variable scnt
	String sdf, sname, sList = StimList(), cdf = ClampDF()
	
	for ( scnt = 0; scnt < ItemsInList( sList ); scnt += 1 )
	
		sname = StringFromList( scnt, sList )
		sdf = StimParent() + sname + ":"
		
		if ( WaveExists( $sdf+"ADCname" ) == 0 )
			sList = RemoveFromList( sname, sList ) // old board config waves do not exist
		endif
	
	endfor
	
	if ( ItemsInList( sList ) == 0 )
		DoAlert 0, "There are no stimulus files to extract board configurations from. Try opening older stimulus files and reselecting Extract button."
		return 0
	elseif ( ItemsInList( sList ) > 1 )
		sList = "All;" + sList
	endif
	
	sname = "All"
	
	Prompt sname, "choose stimulus:", popup sList
			
	DoPrompt "Extract Board Configs From Stimulus Files", sname 

	if ( V_flag == 0 )
	
		if ( StringMatch( sname, "All" ) == 1 )
			sname = slist
		endif
		
		ClampBoardConfigsFromStims( "ADC", sname )
		ClampBoardConfigsFromStims( "DAC", sname )
		ClampBoardConfigsFromStims( "TTL", sname )
		
	endif
	
End // ConfigsTabConfigsFromStims

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

Function /S PulseTabPrefixSelect()

	return StrVarOrDefault( ClampTabDF()+"PulsePrefix", "" )

End // PulseTabPrefixSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTabCall( select, varNum, varStr )
	String select
	Variable varNum
	String varStr
	
	Variable icnt, updateWaves = 1, updateTab = 1
	String tdf = ClampTabDF(), sdf = StimDF()
	
	String wPrefix = PulseTabPrefixSelect()
	
	ClampError( 0, "" )
	
	if ( strlen( wPrefix ) == 0 )
		DoAlert 0, "There is currently no selected DAC or TTL output for this stimulus protocol."
		return -1
	endif
	
	strswitch( select )
	
		case "WavePrefix":
		
			updateWaves = 0
		
			if ( strlen( varStr ) > 0 )
	
				icnt = strsearch( varStr," : ",0 )
				
				if ( icnt >= 0 )
					varStr = varStr[0,icnt-1]
				else
					varStr = ""
				endif
				
				SetNMstr( tdf+"PulsePrefix", varStr )
				
			endif
			
			break
			
		case "New":
		
			strswitch( wPrefix[0,2] )
			
				case "DAC":
					if ( PulseEditDAC( -1 ) == -1 )
						return 0 // cancel
					endif
					break
					
				case "TTL":
					if ( PulseEditTTL( -1 ) == -1 )
						return 0 // cancel
					endif
					break
					
				default:
					DoAlert 0, "There is no currently selected DAC or TTL output."
					return -1
					
			endswitch
			
			break
			
		case "Clear":
			if ( PulseClearCall() == -1 )
				return 0 // cancel
			endif
			break
			
		case "Edit":
			if ( PulseEditCall() == -1 )
				return 0 // cancel
			endif
			break
			
		case "Train":
			 if ( PulseTrainCall() == -1 )
			 	return 0 // cancel
			 endif
			 break
			 
		case "Table":
			PulseTableManager( 1 )
			DoWindow /F PG_StimTable
			return 0
			
		case "PulseOff":
			SetNMvar( sdf+"PulseGenOff", varNum )
			//StimWavesCheck( sdf, 1 )
			break
	
		case "Display":
			updateWaves = 0
			StimWavesCheck( sdf, 0 )
			PulseGraph( 1 )
			break
			
		case "AllOutputs":
			SetNMvar( tdf+"PulseAllOutputs", varNum )
			PulseGraph( 1 )
			return 0
			
		case "AllWaves":
			SetNMvar( tdf+"PulseAllWaves", varNum )
			PulseGraph( 1 )
			return 0
			
		case "AutoScale":
			SetNMvar( tdf+"PulseAutoScale", varNum )
			PulseGraphAxesSave()
			PulseGraph( 1 )
			return 0
	
	endswitch
	
	if ( updateWaves == 1 )
		StimWavesCheck( sdf, 1 )
	endif
	
	if ( updateTab == 1 )
		StimTabPulse( 1 )
	endif

End // PulseTabCall

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTabPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ctrlName[ 4, inf ]
	
	PulseTabCall( ctrlName, popNum, popStr )
	
End // PulseTabPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTabButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ctrlName[ 4, inf ]
	
	PulseTabCall( ctrlName, Nan, "" )

End // PulseTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTabCheckbox( ctrlName, checked ) : CheckboxControl
	String ctrlName; Variable checked
	
	ctrlName = ctrlName[ 4, inf ]
	
	PulseTabCall( ctrlName, checked, "" )
	
End // PulseTabCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseSetVar( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	PulseGraph( 1 )
	//DoWindow /F NMpanel
	
End // PulseSetVar

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseEditCall()
	Variable pnum
	
	String plist = PulseConfigList()
	String wPrefix = PulseTabPrefixSelect()
	
	if ( strlen( wPrefix ) == 0 )
		DoAlert 0, "There is currently no selected DAC or TTL output for this stimulus protocol."
		return -1
	endif
	
	if ( ItemsInList( plist ) == 0 )
		DoAlert 0, "No pulses to edit."
		return -1
	endif
	
	Prompt pnum, "choose pulse configuration:", popup plist
	DoPrompt "Edit Pulse Config", pnum
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	PulseRetrieve( pnum-1 )
	
	strswitch( wPrefix[0,2] )
		case "DAC":
			return PulseEditDAC( pnum-1 )
		case "TTL":
			return PulseEditTTL( pnum-1 )
		default:
			return -1
	endswitch

End // PulseEditCall

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseEditDAC( pulseNum )
	Variable pulseNum // ( -1 ) for new
	
	Variable icnt, oldsh, pcnt
	String title, wlist = "", shlist = "Square;Ramp;Alpha;2-Exp;Other;"
	
	if ( pulseNum == -1 )
		title = "New DAC Pulse Config"
	else
		title = "Edit DAC Pulse Config " + num2istr( pulseNum )
	endif

	String tdf = ClampTabDF(), sdf = StimDF()
	
	String wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	
	Variable nwaves = NumVarOrDefault( sdf+"NumStimWaves", 1 )
	
	if ( strlen( wPrefix ) == 0 )
		DoAlert 0, "There is currently no selected DAC or TTL output for this stimulus protocol."
		return -1
	endif
	
	for ( icnt = 0; icnt < nwaves; icnt += 1 )
		wlist = AddListItem( "Wave"+num2istr( icnt ), wlist, ";", inf )
	endfor
	
	Variable sh = NumVarOrDefault( tdf+"PulseShape", 1 )
	Variable wn = 1 + NumVarOrDefault( tdf+"PulseWaveN", 0 )
	Variable wdelta = NumVarOrDefault( tdf+"PulseWaveND", 0 )
	Variable am = NumVarOrDefault( tdf+"PulseAmp", 1 )
	Variable amd = NumVarOrDefault( tdf+"PulseAmpD", 0 )
	Variable on = NumVarOrDefault( tdf+"PulseOnset", 0 )
	Variable ond = NumVarOrDefault( tdf+"PulseOnsetD", 0 )
	Variable wd = NumVarOrDefault( tdf+"PulseWidth", 0 )
	Variable wdd = NumVarOrDefault( tdf+"PulseWidthD", 0 )
	Variable t2 = NumVarOrDefault( tdf+"PulseTau2", 0 )
	Variable t2d = NumVarOrDefault( tdf+"PulseTau2D", 0 )
	Variable np = NumVarOrDefault( tdf+"PulseNegPos", 1 )
	
	if ( nwaves > 1 )
		wlist += "All;"
		wn = ItemsInList( wlist )
	endif
	
	if ( sh > 5 )
		sh = 5
	endif
	
	Prompt sh, "pulse shape:", popup shlist
	Prompt wn, "add pulse to output wave:", popup wlist
	Prompt wdelta, "optional wave delta: ( 1 ) every wave, ( 2 ) every other wave..."
	Prompt am, "amplitude:"
	Prompt amd, "amplitude delta:"
	Prompt on, "onset time ( ms ):"
	Prompt ond, "onset delta ( ms ):"
	Prompt wd, "width ( ms ):"
	Prompt wdd, "width delta ( ms ):"
	Prompt t2, "decay tau ( ms ):"
	Prompt t2d, "decay tau delta ( ms ):"
	Prompt np, "slope:", popup "positive;negative;"
	
	oldsh = sh

	if ( nwaves == 1 )
		wdelta = 0
		DoPrompt title, sh
	else
		DoPrompt title, sh, wn, wdelta
	endif

	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( sh == 5 )
	
		sh = PulseGetUserWave()
		
		if ( sh < 5 )
			return -1 // something wrong
		endif
		
	elseif ( sh != oldsh ) // set default time constants
		switch( sh )
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
	
	if ( wn == nwaves ) // All
		wn = 0; wdelta = 1;
	endif
	
	if ( wdelta == 0 ) // no wave increment
	
		ond = 0; amd = 0; wdd = 0; t2d = 0
	
		switch( sh )
			case 3:
				Prompt wd, "alpha time constant ( ms ):"
			case 1:
				DoPrompt title, am, on, wd
				break
			case 2:
				DoPrompt title, am, on, wd, np
				break
			case 4:
				Prompt wd, "rise time constant ( ms ):"
				DoPrompt title, am, on, wd, t2
				break
			default:
				DoPrompt title, am, on
				break
		endswitch
	
	else // wave increment > 0
	
		switch( sh )
			case 3:
				Prompt wd, "alpha time constant ( ms ):"
			case 1:
				t2 = 0; t2d = 0;
				DoPrompt title, am, amd, on, ond, wd, wdd
				break
			case 2:
				t2 = 0; t2d = 0;
				DoPrompt title, am, amd, on, ond, wd, wdd, np
				break
			case 4:
				Prompt wd, "rise time constant ( ms ):"
				DoPrompt title, am, amd, on, ond, wd, wdd, t2, t2d
				break
			default:
				DoPrompt title, am, amd, on, ond
				break
		endswitch
	
	endif
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	SetNMvar( tdf+"PulseShape", sh )
	SetNMvar( tdf+"PulseWaveN", wn )
	SetNMvar( tdf+"PulseWaveND", wdelta )
	SetNMvar( tdf+"PulseAmp", am )
	SetNMvar( tdf+"PulseAmpD", amd )
	SetNMvar( tdf+"PulseOnset", on )
	SetNMvar( tdf+"PulseOnsetD", ond )
	SetNMvar( tdf+"PulseWidth", wd )
	SetNMvar( tdf+"PulseWidthD", wdd )
	SetNMvar( tdf+"PulseTau2", t2 )
	SetNMvar( tdf+"PulseTau2D", t2d )
	SetNMvar( tdf+"PulseNegPos", np )
	
	wd = abs( wd )
	
	if ( ( sh == 2 ) && ( np == 2 ) )
		wd = -wd // negative ramp
	endif
	
	PulseSave( sdf, wPrefix, pulseNum, sh, wn, wdelta, on, ond, am, amd, wd, wdd, t2, t2d )
	
	PulseGraph( 1 )
	
End // PulseEditDAC

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseEditTTL( pulseNum )
	Variable pulseNum // ( -1 ) for new
	
	Variable icnt
	String title, wlist = ""
	
	if ( pulseNum == -1 )
		title = "New TTL Pulse Config"
	else
		title = "Edit TTL Pulse Config " + num2istr( pulseNum )
	endif

	String tdf = ClampTabDF(), sdf = StimDF()
	
	String wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	
	Variable nwaves = NumVarOrDefault( sdf+"NumStimWaves", 1 )
	
	if ( strlen( wPrefix ) == 0 )
		DoAlert 0, "There is currently no selected DAC or TTL output for this stimulus protocol."
		return -1
	endif
	
	for ( icnt = 0; icnt < nwaves; icnt += 1 )
		wlist = AddListItem( "Wave"+num2istr( icnt ), wlist, ";", inf )
	endfor
	
	wlist += "All;"
	
	Variable sh = 1
	Variable wn = 1 + NumVarOrDefault( tdf+"PulseWaveN", 0 )
	Variable wdelta = NumVarOrDefault( tdf+"PulseWaveND", 0 )
	Variable am = 1
	Variable amd = 0
	Variable on = NumVarOrDefault( tdf+"PulseOnset", 0 )
	Variable ond = NumVarOrDefault( tdf+"PulseOnsetD", 0 )
	Variable wd = NumVarOrDefault( tdf+"PulseWidth", 0 )
	Variable wdd = NumVarOrDefault( tdf+"PulseWidthD", 0 )
	Variable t2 = 0
	Variable t2d = 0
	
	Prompt wn, "add pulse to output wave:", popup wlist
	Prompt wdelta, "optional wave delta: ( 1 ) every wave after, ( 2 ) every other wave after..."
	Prompt on, "onset time ( ms ):"
	Prompt ond, "onset delta ( ms ):"
	Prompt am, "amplitude:"
	Prompt amd, "amplitude delta:"
	Prompt wd, "width ( ms ):"
	Prompt wdd, "width delta ( ms ):"
	
	if ( nwaves == 1 )
		wdelta = 0
		DoPrompt title, wn
	else
		DoPrompt title, wn, wdelta
	endif
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	wn -= 1
	
	if ( wn == nwaves ) // All
		wn = 0; wdelta = 1;
	endif
	
	if ( wdelta == 0 )
		ond = 0; wdd = 0
		DoPrompt title, on, wd
	else
		DoPrompt title, on, ond, wd, wdd
	endif
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	SetNMvar( tdf+"PulseWaveN", wn )
	SetNMvar( tdf+"PulseWaveND", wdelta )
	SetNMvar( tdf+"PulseOnset", on )
	SetNMvar( tdf+"PulseOnsetD", ond )
	SetNMvar( tdf+"PulseWidth", wd )
	SetNMvar( tdf+"PulseWidthD", wdd )
	
	PulseSave( sdf, wPrefix, pulseNum, sh, wn, wdelta, on, ond, am, amd, wd, wdd, t2, t2d )
	
	PulseGraph( 1 )
	
End // PulseEditTTL

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseClearCall()
	Variable pnum = 1
	String plist = PulseConfigList()

	String tdf = ClampTabDF(), sdf = StimDF()
	
	String wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	
	if ( strlen( wPrefix ) == 0 )
		DoAlert 0, "There is currently no selected DAC or TTL output for this stimulus protocol."
		return -1
	endif
	
	if ( ItemsInList( plist ) == 0 )
		DoAlert 0, "No pulses to clear."
		return -1
	endif
	
	plist = "All;" + plist
	
	Prompt pnum, "choose pulse configuration:", popup plist
	DoPrompt "Clear Pulse Config", pnum
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	pnum -= 2
	
	PulseClear( sdf, wPrefix, pnum )

End // PulseClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTrainCall()

	Variable icnt, wbgn, wend
	String wlist = "", wlist2 = "", wname = ""
	
	String tdf = ClampTabDF(), sdf = StimDF(), cdf = ClampDF()
	
	String wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	
	Variable nwaves = NumVarOrDefault( sdf+"NumStimWaves", 1 )
	
	if ( strlen( wPrefix ) == 0 )
		DoAlert 0, "There is currently no selected DAC or TTL output for this stimulus protocol."
		return -1
	endif
	
	for ( icnt = 0; icnt < nwaves; icnt += 1 )
		wlist = AddListItem( "Wave"+num2istr( icnt ), wlist, ";", inf )
	endfor
	
	wlist += "All;"
	
	Variable npulses = NumVarOrDefault( tdf+"PulseTrainNumPulses", 10 )
	Variable wnum = NumVarOrDefault( tdf+"PulseTrainWaveN", 1 )
	Variable wdelta = NumVarOrDefault( tdf+"PulseTrainWaveD", 0 )
	Variable tbgn = NumVarOrDefault( tdf+"PulseTrainTbgn", -inf )
	Variable tend = NumVarOrDefault( tdf+"PulseTrainTend", inf )
	
	Variable type = NumVarOrDefault( tdf+"PulseTrainType", 1 ) // ( 1 ) fixed ( 2 ) random ( 3 ) user intervals
	Variable intvl = NumVarOrDefault( tdf+"PulseTrainInterval", 10 )
	Variable refrac = NumVarOrDefault( tdf+"PulseTrainRefrac", 0 )
	
	Variable shape = NumVarOrDefault( tdf+"PulseShape", 1 )
	Variable amp = NumVarOrDefault( tdf+"PulseAmp", 1 )
	Variable width = NumVarOrDefault( tdf+"PulseWidth", 0 )
	Variable tau2 = NumVarOrDefault( tdf+"PulseTau2", 0 )
	Variable continuous = 0
	
	if ( StimAcqMode( "" ) == 1 )
		continuous = 1
	endif
	
	if ( wnum > ItemsInList( wlist ) )
		wnum = 1
	endif
	
	Prompt wnum, "add pulses to wave:", popup wlist
	Prompt wdelta, "optional wave delta: ( 1 ) every wave after, ( 2 ) every other wave after..."
	
	Prompt tend, "time window end ( ms ):"
	Prompt npulses, "number of pulses:"
	Prompt type, "pulse intervals:", popup "fixed intervals;random intervals;my intervals;"
	
	Prompt intvl, "inter-pulse interval ( ms ):"
	Prompt refrac, "refractory period ( ms ):"
	Prompt shape, "pulse shape:", popup "Square;Ramp;Alpha;2-Exp;Other;"
	
	Prompt amp, "pulse amplitude:"
	Prompt width, "pulse width:"
	Prompt tau2, "decay time constant ( ms ):"
	
	wdelta = 0
	
	if ( nwaves > 1 )
		DoPrompt "Make Pulse Train", type, wnum//, wdelta
	else
		DoPrompt "Make Pulse Train", type
	endif
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	SetNMvar( tdf+"PulseTrainType", type )
	SetNMvar( tdf+"PulseTrainWaveN", wnum )
	SetNMvar( tdf+"PulseTrainWaveD", wdelta )
	
	wnum -= 1
	wbgn = wnum
	wend = wnum
	
	if ( type == 1 ) // fixed interval
	
		if ( wnum == nwaves ) // All
			wbgn = 0
			wdelta = 1
		endif
	
		Prompt tbgn, "first pulse onset time ( ms ):"
		Prompt intvl, "inter-pulse interval ( ms ):"
		DoPrompt "Make Pulse Train", shape, npulses, tbgn, intvl
		
		tend = tbgn + npulses * intvl
		
	elseif ( type == 2 ) // random interval
	
		if ( wnum == nwaves ) // All
			wbgn = 0
			wend = nwaves - 1
			wdelta = 0
		endif
	
		Prompt tbgn, "time window begin ( ms ):"
		Prompt intvl, "mean inter-pulse interval ( ms ):"
		DoPrompt "Make Pulse Train", shape, tbgn, tend, intvl, refrac
		
	elseif ( type == 3 )
		
		wlist2 = FolderObjectList( cdf, 1 )
		
		if ( strlen( wlist2 ) == 0 )
			DoAlert 0, "No waves detected in root:Packages:Clamp directory"
			return -1 // no waves in Clamp directory
		endif
		
		Prompt tbgn, "time window begin ( ms ):"
		Prompt wname, "choose wave of pulse intervals ( wave must be in root:Packages:Clamp directory ):", popup wlist2
		DoPrompt "Make Pulse Train", wname, shape, tbgn, tend
		
		wname = cdf + wname
		
	endif
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	SetNMvar( tdf+"PulseShape", shape )
	SetNMvar( tdf+"PulseTrainNumPulses", npulses )
	SetNMvar( tdf+"PulseTrainTbgn", tbgn )
	SetNMvar( tdf+"PulseTrainTend", tend )
	SetNMvar( tdf+"PulseTrainInterval", intvl )
	SetNMvar( tdf+"PulseTrainRefrac", refrac )
	
	if ( amp == 0 )
		amp = 1
	endif
	
	switch( shape )
		case 1:
			DoPrompt "Square Pulse Dimensions", amp, width
			break
		case 2:
			DoPrompt "Ramp Dimensions", amp, width
			break
		case 3:
			width = 2
			Prompt width, "alpha time constant ( ms ):"
			DoPrompt "Alpha Pulse Dimensions", amp, width
			break
		case 4:
			width = 2
			tau2 = 3
			Prompt width, "rise time constant ( ms ):"
			DoPrompt "2-Exp Pulse Dimensions", amp, width, tau2
			break
		case 5:
			shape = PulseGetUserWave()
			DoPrompt "User Pulse Dimensions", amp
			break
	endswitch
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	SetNMvar( tdf+"PulseAmp", amp )
	SetNMvar( tdf+"PulseWidth", width )
	SetNMvar( tdf+"PulseTau2", tau2 )
	
	if ( numtype( tbgn ) > 0 )
		tbgn = 0
	endif
	
	if ( numtype( tend ) > 0 )
		tend = NumVarOrDefault( sdf+"WaveLength", 100 )
	endif
	
	refrac = abs( refrac )
	
	if ( type == 2 )
		Intvl += refrac // correct for refractoriness
	endif
	
	PulseTrain( sdf, wPrefix, wbgn, wend, wdelta, tbgn, tend, type, intvl, refrac, shape, amp, width, tau2, continuous, wname )
	
	PulseGraph( 1 )

End // PulseTrainCall

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseRetrieve( pulseNum )
	Variable pulseNum
	Variable index, pNumVar = 12
	
	String tdf = ClampTabDF(), sdf = StimDF()

	String wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	String wname = PulseWaveName( sdf, wPrefix )
	
	if ( strlen( wPrefix ) == 0 )
		DoAlert 0, "There is currently no selected DAC or TTL output for this stimulus protocol."
		return -1
	endif
	
	if ( WaveExists( $wname ) == 0 )
		return 0
	endif

	Wave Pulse = $wname

	index = pulseNum * pNumVar

	if ( ( Pulse[index] <= 0 ) && ( index + 11 < numpnts( Pulse ) ) )
		
		SetNMvar( tdf+"PulseShape", Pulse[index+1] )
		SetNMvar( tdf+"PulseWaveN", Pulse[index+2] )
		SetNMvar( tdf+"PulseWaveND", Pulse[index+3] )
		SetNMvar( tdf+"PulseOnset", Pulse[index+4] )
		SetNMvar( tdf+"PulseOnsetD", Pulse[index+5] )
		SetNMvar( tdf+"PulseAmp", Pulse[index+6] )
		SetNMvar( tdf+"PulseAmpD", Pulse[index+7] )
		SetNMvar( tdf+"PulseWidth", Pulse[index+8] )
		SetNMvar( tdf+"PulseWidthD", Pulse[index+9] )
		SetNMvar( tdf+"PulseTau2", Pulse[index+10] )
		SetNMvar( tdf+"PulseTau2D", Pulse[index+11] )
		
	endif

End // PulseRetrieve

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGetUserWave()

	Variable icnt
	String pname, pname2, wname, sdf = StimDF()
	
	String pnameOLD = StrVarOrDefault( sdf+"UserPulseName", "" )
	
	if ( strlen( pnameOLD ) == 0 )
	
		for ( icnt = 5; icnt < 25; icnt += 1 )
		
			pname = StrVarOrDefault( sdf+"UserPulseName"+num2istr( icnt ), "" )
			
			if ( WaveExists( $sdf+pname ) == 1 )
				break
			endif
			
		endfor
		
	else
	
		pname = pnameOLD
		
	endif
	
	if ( strlen( pname ) == 0 )
		pname = "MyPulse"
	endif
	
	Prompt pname, "pulse wave name:"
	DoPrompt "User Pulse Wave", pname
	
	if ( V_flag == 1 )
		return -1
	endif
	
	if ( WaveExists( $sdf+pname ) == 0 )
		DoAlert 0, "Error: wave '" + pname + "' does not reside in Stim folder " + sdf
		return -1
	endif
	
	if ( StringMatch( pname, pnameOLD ) == 1 )
		SetNMStr( sdf+"UserPulseName", pname )
		return 5
	endif
	
	for ( icnt = 5; icnt < 25; icnt += 1 )
	
		pname2 = StrVarOrDefault( sdf+"UserPulseName"+num2istr( icnt ), "" )
		
		if ( StringMatch( pname, pname2 ) == 1 )
			SetNMStr( sdf+"UserPulseName"+num2istr( icnt ), pname )
			return icnt
		endif
		
	endfor
	
	for ( icnt = 5; icnt < 25; icnt += 1 )
	
		pname2 = StrVarOrDefault( sdf+"UserPulseName"+num2istr( icnt ), "" )
		
		if ( strlen( pname2 ) == 0 )
			SetNMStr( sdf+"UserPulseName"+num2istr( icnt ), pname )
			return icnt
		endif
	endfor
	
	return -1
			
End // PulseGetUserWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseConfigList()
	Variable pnum, icnt, npulses, index, pNumVar = 12
	String item, plist = ""

	String tdf = ClampTabDF(), sdf = StimDF()
	
	String wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	
	String wname = PulseWaveName( sdf, wPrefix )
	
	if ( WaveExists( $wname ) == 0 )
		return ""
	endif

	Wave Pulse = $wname
	
	npulses = numpnts( Pulse ) / pNumVar
	
	if ( npulses < 1 )
		return ""
	endif
	
	for ( icnt = 0; icnt < npulses; icnt += 1 )
		index = icnt * pNumVar
		item = num2istr( icnt ) + " : "
		item += "wave" + num2istr( Pulse[index+2] ) + ","
		item += PulseShape( sdf, Pulse[index+1] ) + ","
		item += "@" + num2str( Pulse[index+4] ) + " ms"
		plist = AddListItem( item, plist, ";", inf )
	endfor
	
	return plist
	
End // PulseConfigList

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseConfigCheck()

	Variable index, value, icnt, pcnt, npulses, pNumVar = 12
	
	String wname, numstr = "", clearList = "", tdf = ClampTabDF(), sdf = StimDF()
	
	Variable NumStimWaves = NumVarOrDefault( sdf+"NumStimWaves", 1 )
	Variable pulseNum = NumVarOrDefault( tdf+"PulseNum", 0 )
	
	String wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	String errorStr = "pulse config " + num2istr( pulseNum )
	
	if ( strlen( wPrefix ) == 0 )
		return 0
	endif
	
	wname = PulseWaveName( sdf, wPrefix )
	
	if ( WaveExists( $wname ) == 0 )
		return 0
	endif

	Wave Pulse = $wname
	
	npulses = numpnts( Pulse ) / pNumVar // should be whole number
	
	for ( pcnt = 0; pcnt < npulses; pcnt += 1 )
	
		index = pcnt * pNumVar
		
		errorStr = "pulse config " + num2istr( pcnt )
		
		value = Pulse[index+1]
		
		if ( value < 1 ) // shape
			ClampError( 1, errorStr + " shape out of range : " + num2str( value ) )
			Pulse[index+1] = 1
		endif
		
		value = Pulse[index+2]
		
		if ( ( value < 0 ) || ( value >= NumStimWaves ) ) // waveN
			for ( icnt = 0; icnt < NumStimWaves; icnt += 1 )
				numstr = AddListItem( "wave"+num2istr( icnt ), numstr, ";", inf )
			endfor
			Prompt value, "wave" + num2str( value ) + " out or range. choose new wave or clear:", popup numstr + "clear config;"
			Print value, "wave" + num2str( value ) + " out or range."
			value = 1
			//DoPrompt "Pulse Config " + num2istr( pcnt ) + " Error", value
			if ( value <= NumStimWaves )
				Pulse[index+2] = value - 1
			else
				clearList = AddListItem( num2istr( pcnt ), clearList, ";", inf )
			endif
		endif
		
		value = Pulse[index+3]
		
		if ( value < 0 ) // waveND
			ClampError( 1, errorStr + " wave delta out of range : " + num2str( value ) )
			Pulse[index+3] = 0
		endif
	
	endfor
	
	for ( icnt = 0; icnt < ItemsInList( clearList ); icnt += 1 )
		PulseClear( sdf, wPrefix, str2num( StringFromList( icnt,clearList ) ) )
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

Function /S PulseGraphName()

	return "PG_PulseGraph"

End // PulseGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraph( force )
	Variable force
	
	String sdf = StimDF() // stim data folder
	
	Variable x0 = 100, y0 = 5, xinc = 140
	Variable madeGraph
	
	String yLabel
	String wName, wList, wPrefix, wPrefixList

	String tdf = ClampTabDF()
	
	String gName = PulseGraphName()
	String gTitle = StimCurrent()
	String Computer = NMComputerType()
	
	Variable numStimWaves = NumVarOrDefault( sdf+"NumStimWaves", 1 )
	
	Variable tabnum = NumVarOrDefault( tdf+"CurrentTab", 0 )
	
	Variable allout = NumVarOrDefault( tdf+"PulseAllOutputs", 0 )
	Variable allwaves = NumVarOrDefault( tdf+"PulseAllWaves", 1 )
	Variable autoscale = NumVarOrDefault( tdf+"PulseAutoScale", 1 )
	Variable wNum = NumVarOrDefault( tdf+"PulseWaveNum", 0 )
	
	if ( StimChainOn( "" ) == 1 )
		return 0
	endif
	
	PulseGraphAxesSave() // save axes values
	
	//StimWavesCheck( sdf, 0 )
	
	if ( ( force == 1 ) || ( WinType( gName ) == 1 ) )
	
		if ( allwaves == 1 )
			wNum = -1
		endif
		
		if ( wNum >= numStimWaves )
			SetNMvar( tdf+"PulseWaveNum", 0 )
			wNum = 0
		endif
		
		wPrefixList = StimPrefixListAll( sdf )
		
		wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
		
		if ( allout == 1 )
			wPrefixList = RemoveFromList( wPrefix, wPrefixList )
			wPrefixList = AddListItem( wPrefix, wPrefixList ) // this puts current prefix first
			wlist = StimWaveList( sdf, wPrefixList, wNum )
		else
			wlist = StimWaveList( sdf, wPrefix, wNum )
		endif
	
		if ( ( ItemsInlist( wlist ) == 0 ) && ( ItemsInlist( wPrefixList ) > 0 ) )
			wPrefix = StringFromList( 0,wPrefixList ) // no waves, try another prefix
			wlist = StimWaveList( sdf, wPrefix, wNum )
			SetNMstr( tdf+"PulsePrefix", wPrefix )
		endif
	
		if ( ( ItemsInlist( wlist ) == 0 ) && ( WinType( "PG_PulseGraph" ) == 0 ) )
			return 0
		endif
		
		wlist = PulseGraphWaveList( sdf, wlist ) // convert wlist do display waves
		
		madeGraph = PulseGraphUpdate( sdf, wlist ) // NM_PulseGen.ipf
		
		if ( madeGraph == 1 )
		
			ModifyGraph /W=PG_PulseGraph margin( left )=60, margin( right )=0, margin( top )=19, margin( bottom )=0
			
			if ( StringMatch( computer, "mac" ) == 1 )
				y0 = 3
			endif
			
			Checkbox CT3_AllOutputs, value=allout, pos={x0,y0}, title="All Outputs", size={16,18}, proc=PulseTabCheckbox, win=PG_PulseGraph
	
			Checkbox CT3_AllWaves, value=allwaves, pos={x0+1*xinc,y0}, title="All Waves", size={16,18}, proc=PulseTabCheckbox, win=PG_PulseGraph
	
			SetVariable CT3_WaveNum, title="Wave", pos={x0+2*xinc,y0-1}, size={80,50}, limits={0,inf,1}, win=PG_PulseGraph
			SetVariable CT3_WaveNum, value=$( tdf+"PulseWaveNum" ), proc=PulseSetVar, win=PG_PulseGraph
			
			Checkbox CT3_AutoScale, value=autoscale, pos={x0+3*xinc,y0}, title="AutoScale", size={16,18}, proc=PulseTabCheckbox, win=PG_PulseGraph
			
		else
		
			Checkbox CT3_AllOutputs, win=PG_PulseGraph, value=allout
			Checkbox CT3_AllWaves, win=PG_PulseGraph, value=allwaves
			Checkbox CT3_AutoScale, win=PG_PulseGraph, value=autoscale
			
		endif
		
		if ( allwaves == 1 )
			SetNMvar( tdf+"PulseWaveNum", 0 )
			SetVariable CT3_WaveNum, win=PG_PulseGraph, noedit = 1, limits={0,numStimWaves-1,0}
		else
			SetVariable CT3_WaveNum, win=PG_PulseGraph, noedit = 0, limits={0,numStimWaves-1,1}
		endif
	
		yLabel = StimConfigStr( sdf, wPrefix, "name" )
		
		if ( strlen( yLabel ) == 0 )
			yLabel = wPrefix
		else
			yLabel += " ( " + StimConfigStr( sdf, wPrefix, "units" ) + " )"
		endif
		
		if ( ItemsInList( wlist ) > 0 )
		
			Label /Z/W=$gName left, yLabel
			Label /Z/W=$gName bottom, "msec"
			
			if ( allout == 0 )
			
				if ( allwaves == 0 )
					gTitle += " : " + wPrefix + " : " + "Wave" + num2istr( wNum )
				else
					gTitle += " : " + wPrefix + " : " + "All Waves"
				endif
				
			else
			
				if ( allwaves == 0 )
					gTitle += " : " + "All Outputs : " + "Wave" + num2istr( wNum )
				else
					gTitle += " : " + "All Outputs : " + "All Waves"
				endif
				
			endif
			
		else

			gTitle += " : " + "No Outputs"
			
		endif
		
		DoWindow /T $gName, gTitle
		
		if ( force == 1 )
			DoWindow /F PG_PulseGraph
		endif
		
		PulseGraphAxesSet()
		
	endif

End // PulseGraph

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraphRemoveWaves()

	Variable wcnt
	String wList, wName, gName = PulseGraphName()
	
	if ( WinType( gName ) != 1 )
		return 0
	endif
	
	wList = TraceNameList( gName, ";", 1 )
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		wName = StringFromList( wcnt, wList )
		RemoveFromGraph /W=$gName /Z $wName
	endfor

End // PulseGraphRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraphAxesSave()

	String tdf = ClampTabDF()
	String gName = PulseGraphName()
		
	if ( WinType( gName ) == 1 )
	
		GetAxis /Q/W=$gName bottom
	
		SetNMvar( tdf+"Xmin", V_min )
		SetNMvar( tdf+"Xmax", V_max )
		
		GetAxis /Q/W=$gName left
		
		SetNMvar( tdf+"Ymin", V_min )
		SetNMvar( tdf+"Ymax", V_max )
		
	endif

End // PulseGraphAxesSave

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraphAxesSet()
	
	String tdf = ClampTabDF()
	String gName = PulseGraphName()
	
	Variable autoscale = NumVarOrDefault( tdf+"PulseAutoScale", 1 )
	
	Variable xmin = NumVarOrDefault( tdf+"Xmin", 0 )
	Variable xmax = NumVarOrDefault( tdf+"Xmax", 1 )
	Variable ymin = NumVarOrDefault( tdf+"Ymin", 0 )
	Variable ymax = NumVarOrDefault( tdf+"Ymax", 1 )
	
	if ( autoscale == 1 )
		SetAxis /W=$gName/A
		return 0
	endif
	
	SetAxis /W=$gName bottom xmin, xmax
	SetAxis /W=$gName left ymin, ymax
		
End // PulseGraphAxesSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseGraphWaveList( sdf, wlist )
	String sdf
	String wlist
	
	Variable wcnt
	String wname, dlist = ""
	
	Variable off = NumVarOrDefault( sdf+"PulseGenOff", 0 )
	
	for ( wcnt = 0; wcnt < ItemsInList( wlist ); wcnt += 1 )
	
		wname = StringFromList( wcnt, wlist )
		
		if ( ( off == 1 ) && ( WaveExists( $( sdf+"My"+wname ) ) == 1 ) )
			dlist = AddListItem( "My"+wname, dlist ) // display "My" waves ( MyDAC, MyTTL )
		else
			dlist = AddListItem( "u"+wname, dlist ) // display unscaled waves ( uDAC, uTTL )
		endif
		
	endfor
	
	return dlist
	
End // PulseGraphWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseWaveCheck( io, config )
	String io // "DAC" or "TTL"
	Variable config // config Num ( -1 ) for all
	
	Variable icnt, ibgn = config, iend = config
	String wname, sdf = StimDF()
	
	if ( config == -1 )
		ibgn = 0
		iend = numpnts( ioWave ) - 1
	endif
	
	for ( icnt = ibgn; icnt <= iend; icnt += 1 )
	
		wname = PulseWaveName( sdf, io + "_" + num2istr( icnt ) )
		
		if ( StimBoardConfigIsActive( sdf, io, config ) == 0 )
			continue
		endif
		
		if ( WaveExists( $wname ) == 0 )
			Make /N=0 $wname
		endif
		
	endfor
	
	return 0
	
End // PulseWaveCheck

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Pulse Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableManager( select )
	Variable select // ( 0 ) update ( 1 ) make ( 2 ) save

	String pname, sdf = StimDF(), tdf = ClampTabDF()
	
	String wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	
	if ( strlen( wPrefix ) == 0 )
		return 0
	endif
	
	pname = PulseWaveName( sdf, wPrefix )
	
	switch( select )
		case 0:
		case 1:
			PulseTableUpdate( pname, select )
			break
		case 2:
			PulseTableSave( pname )
			break
	endswitch
	
End // PulseTableManager

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableUpdate( pName, force )
	String pName // pulse wave name
	Variable force // ( 0 ) update if exists ( 1 ) force make
	
	String wName, prefix = "PG_"
	String tName = prefix + "StimTable"
	String sdf = StimDF(), tdf = ClampTabDF()
	
	String wPrefix = StrVarOrDefault( tdf+"PulsePrefix", "" )
	String ioName = StimConfigStr( sdf, pName, "name" )
	
	if ( strlen( wPrefix ) == 0 )
		return 0
	endif
	
	if ( strlen( pName ) == 0 )
		pname = PulseWaveName( sdf, wPrefix )
	endif
	
	if ( WinType( tName ) == 0 )
	
		if ( force == 0 )
			return 0
		else
			tName = PulseTableMake( pName, tdf, prefix )
		endif
		
	endif
	
	if ( ( strlen( tName ) == 0 ) || ( WinType( tName ) == 0 ) )
		return -1
	endif
		
	DoWindow /T $tName, GetPathName( pName,0 ) + " : " + ioName
	
	StimTableWavesUpdate( pName, tdf, prefix )
	
	wName = tdf + prefix + "Shape"
	
	CheckStimTableWaves( tdf, prefix, numpnts( $wName ) )

End // PulseTableUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseTableMake( pName, tdf, prefix )
	String pName, tdf, prefix
	
	String tName = StimTable( StimDF(), pName, tdf, prefix )
	
	SetWindow $tName hook=PulseTableHook
	
	return tName
	
End // PulseTableMake

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableHook( infoStr )
	string infoStr
	
	string event= StringByKey( "EVENT",infoStr )
	string win= StringByKey( "WINDOW",infoStr )
	
	if ( StringMatch( win, "PG_StimTable" ) == 0 )
		return 0 // wrong window
	endif
	
	strswitch( event )
		case "deactivate":
		case "kill":
			PulseTableManager( 2 )
			StimWavesCheck( StimDF(), 1 )
			PulseGraph( 0 )
	endswitch

End // PulseTableHook

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableSave( pname )
	String pname
	
	Variable icnt, index, ilmt, pNumVar = 12
	String titlePname, tdf = ClampTabDF()
	
	String tName = "PG_StimTable"
	
	if ( WinType( tName ) == 0 )
		return 0
	endif
	
	titlePname = GetPathName( pName, 0 )
	
	//GetWindow $tName, title
	
	//if ( strsearch( S_value, titlePname, 0 ) < 0 )
	//	return -1
	//endif
	
	if ( WaveExists( $tdf+"PG_Shape" ) == 0 )
		return -1
	endif
	
	Wave Shape = $( tdf+"PG_Shape" )
	Wave WaveN = $( tdf+"PG_WaveN" )
	Wave WaveND = $( tdf+"PG_ND" )
	Wave Onset = $( tdf+"PG_Onset" )
	Wave OnsetD = $( tdf+"PG_OD" )
	Wave Amp = $( tdf+"PG_Amp" )
	Wave AmpD = $( tdf+"PG_AD" )
	Wave Width = $( tdf+"PG_Width" )
	Wave WidthD = $( tdf+"PG_WD" )
	Wave Tau2 = $( tdf+"PG_Tau2" )
	Wave Tau2D = $( tdf+"PG_TD" )
	
	WaveStats /Z/Q Shape
	
	ilmt = V_npnts
	
	if ( WaveExists( $pname ) == 0 )
		Make /O/N=( ilmt*pNumVar ) $pname
	endif
	
	Wave Pulse = $pname
	
	Redimension /N=( ilmt*pNumVar ) Pulse
	
	Pulse = Nan
		
	for ( icnt = 0; icnt < ilmt; icnt += 1 )
		
		index = icnt*pNumVar
		
		Pulse[index] = -icnt
		Pulse[index + 1] = Shape[icnt]
		Pulse[index + 2] = WaveN[icnt]
		Pulse[index + 3] = PulseTableValue( WaveND[icnt] )
		Pulse[index + 4] = Onset[icnt]
		Pulse[index + 5] = PulseTableValue( OnsetD[icnt] )
		Pulse[index + 6] = Amp[icnt]
		Pulse[index + 7] = PulseTableValue( AmpD[icnt] )
		Pulse[index + 8] = Width[icnt]
		Pulse[index + 9] = PulseTableValue( WidthD[icnt] )
		Pulse[index + 10] = PulseTableValue( Tau2[icnt] )
		Pulse[index + 11] = PulseTableValue( Tau2D[icnt] )
		
	endfor

End // PulseTableSave

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableValue( value )
	Variable value
	
	if ( numtype( value ) > 0 )
		return 0
	else
		return value
	endif
	
End // PulseTableValue

//****************************************************************
//****************************************************************
//****************************************************************