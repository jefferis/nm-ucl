#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 2.00

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic MyTab Demo Tab
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 30 Nov 2004
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S MyTabPrefix(varName) // tab prefix identifier
	String varName
	
	return "MY_" + varName
	
End // MyTabPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S MyTabDF() // package full-path folder name

	return PackDF("MyTab")
	
End // MyTabDF

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTab(enable)
	Variable enable // (0) disable (1) enable tab
	
	if (enable == 1)
		CheckPackage("MyTab", 0) // declare globals if necessary
		MakeMyTab() // create tab controls if necessary
		ChanControlsDisable(-1, "000000")
		AutoMyTab()
	endif

End // MyTab

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoMyTab()

// put a function here that runs each time CurrentWave number has been incremented 
// see "AutoSpike" for example

End // AutoMyTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillMyTab(what)
	String what
	String df = MyTabDF()

	// TabManager will automatically kill objects that begin with appropriate prefix
	// place any other things to kill here.
	
	strswitch(what)
	
		case "waves":
			// kill any other waves here
			break
			
		case "folder":
			if (DataFolderExists(df) == 1)
				KillDataFolder $df
			endif
			break
			
	endswitch

End // KillMyTab

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckMyTab() // declare global variables

	String df = MyTabDF()
	
	if (DataFolderExists(df) == 0)
		return -1 // folder doesnt exist
	endif
	
	CheckNMvar(df+"MyVar", 11) // create variable (also see Configurations.ipf)
	
	CheckNMstr(df+"MyStr", "Anything") // create string
	
	CheckNMwave(df+"MyWave", 5, 22) // numeric wave
	
	CheckNMtwave(df+"MyTxtWave", 5, "Anything") // text wave
	
	return 0
	
End // CheckMyTab

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTabConfigs()
	String fname = "MyTab"

	NMConfigVar(fname, "MyVar", 11, "My Variable")
	NMConfigStr(fname, "MyStr", "Anything", "My Text Variable")
	
	NMConfigWave(fname, "MyWave", 5, 22, "My Wave")
	NMConfigTWave(fname, "MyTxtWave", 5, "Anything", "My Text Wave")

End // MyTabConfigs
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeMyTab() // create controls that will begin with appropriate prefix

	Variable x0 = 60, y0 = 250, xinc, yinc = 60, fs = NMPanelFsize()
	Variable taby = NMPanelTabY()
	
	y0 = taby + 80
	
	String df = MyTabDF()

	ControlInfo /W=NMPanel $MyTabPrefix("Function0") // check first in a list of controls
	
	if (V_Flag != 0)
		return 0 // tab controls exist, return here
	endif

	DoWindow /F NMPanel
	
	Button $MyTabPrefix("Function0"), pos={x0,y0+0*yinc}, title="Your button can go here", size={200,20}, proc=MyTabButton, fsize=fs
	Button $MyTabPrefix("Demo"), pos={x0,y0+1*yinc}, title="Demo Function", size={200,20}, proc=MyTabButton, fsize=fs
	Button $MyTabPrefix("Function1"), pos={x0,y0+2*yinc}, title="My Function 1", size={200,20}, proc=MyTabButton, fsize=fs
	Button $MyTabPrefix("Function2"), pos={x0,y0+3*yinc}, title="My Function 2", size={200,20}, proc=MyTabButton
	
	SetVariable $MyTabPrefix("Function3"), title="my variable", pos={x0,y0+4*yinc}, size={200,50}, limits={-inf,inf,1}
	SetVariable $MyTabPrefix("Function3"), value=$(df+"MyVar"), proc=MyTabSetVariable, fsize=fs

End // MakeMyTab

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTabButton(ctrlName) : ButtonControl
	String ctrlName
	
	String fxn = NMCtrlName(MyTabPrefix(""), ctrlName)
	
	MyTabCall(fxn, "")
	
End // MyTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTabSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = NMCtrlName(MyTabPrefix(""), ctrlName)
	
	MyTabCall(fxn, varStr)
	
End // MyTabSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTabCall(fxn, select)
	String fxn // function name
	String select // parameter string variable
	
	Variable snum = str2num(select) // parameter variable number
	
	strswitch(fxn)
	
		case "Demo":
			Execute /Z "NMDemoLoop()" // see NM_MainTab.ipf
			return 0
	
		case "Function0":
			return MyFunction0()
			
		case "Function1":
			return MyFunction1()
			
		case "Function2":
			return MyFunction2()
			
		case "Function3":
			return MyFunction3(select)

	endswitch
	
End // MyTabCall

//****************************************************************
//****************************************************************
//****************************************************************

Function MyFunction0()

	String df = MyTabDF()

	DoAlert 0, "Your macro can be run here."
	
	NVAR MyVar = $(df+"MyVar")
	SVAR MyStr = $(df+"MyStr")
	
	Wave MyWave = $(df+"MyWave")
	Wave /T MyTxtWave = $(df+"MyTxtWave")

End // MyFunction0

//****************************************************************
//****************************************************************
//****************************************************************

Function MyFunction1()

	Print "My Function 1"

End // MyFunction1

//****************************************************************
//****************************************************************
//****************************************************************

Function MyFunction2()

	Print "My Function 2"

End // MyFunction2

//****************************************************************
//****************************************************************
//****************************************************************

Function MyFunction3(select)
	String select

	Print "You entered : " + select

End // MyFunction3

//****************************************************************
//****************************************************************
//****************************************************************
