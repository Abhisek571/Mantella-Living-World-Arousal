Scriptname MantellaOSLA_TestHarness extends Quest
{TEST ONLY. Fakes Mantella conversation events and records what the bridge sends.}

string[] _log
int _count = 0

Event OnInit()
	_log = new string[64]
	RegisterForModEvent("MantellaAddEvent", "OnAddEvent")
EndEvent

Event OnAddEvent(string text)
	if !_log
		_log = new string[64]
	endif
	if _count < 64
		_log[_count] = text
		_count += 1
	endif
EndEvent

string Function GetLog()
	string s = ""
	int i = 0
	while i < _count
		s += "[" + i + "] " + _log[i] + " | "
		i += 1
	endWhile
	return s
EndFunction

Function ClearLog()
	_log = new string[64]
	_count = 0
EndFunction

Function Reregister()
	RegisterForModEvent("MantellaAddEvent", "OnAddEvent")
EndFunction

Function FireStarted()
	int h = ModEvent.Create("MantellaConversation_Started")
	if h
		ModEvent.Send(h)
	endif
EndFunction

Function FireNpcAdded(Actor npc)
	int h = ModEvent.Create("MantellaConversation_NPC_Added")
	if h
		ModEvent.PushForm(h, npc)
		ModEvent.Send(h)
	endif
EndFunction

Function FireEnded()
	int h = ModEvent.Create("MantellaConversation_Ended")
	if h
		ModEvent.Send(h)
	endif
EndFunction

Function FireLegacyAction(string identifier, Actor speaker)
	int h = ModEvent.Create("MantellaConversation_Action_" + identifier)
	if h
		ModEvent.PushForm(h, speaker)
		ModEvent.Send(h)
	endif
EndFunction

Function FireAdvancedAction(string identifier, Actor speaker)
	int h = ModEvent.Create("MantellaConversation_Advanced_Action_" + identifier)
	if h
		ModEvent.PushForm(h, speaker)
		ModEvent.PushForm(h, None)
		ModEvent.PushInt(h, 0)
		ModEvent.Send(h)
	endif
EndFunction

; Advanced action with one integer argument, the way Mantella sends ReportCrime.
Function FireAdvancedActionInt(string identifier, Actor speaker, string argKey, int value)
	int args = SKSE_HTTP.createDictionary()
	SKSE_HTTP.setInt(args, argKey, value)
	int h = ModEvent.Create("MantellaConversation_Advanced_Action_" + identifier)
	if h
		ModEvent.PushForm(h, speaker)
		ModEvent.PushForm(h, None)
		ModEvent.PushInt(h, args)
		ModEvent.Send(h)
	endif
EndFunction

; Standard mod event, as OStim sends it: (eventName, sceneID, threadID, sender = the actor).
Function FireOrgasm(Actor a)
	a.SendModEvent("ostim_actor_orgasm", "test_scene", 0.0)
EndFunction

string Function GetAppetiteState(Actor a)
	return "appetite=" + StorageUtil.GetIntValue(a, "MantellaOSLA_Appetite", 0) + " need=" + StorageUtil.GetFloatValue(a, "MantellaOSLA_Need", 0.0) + " climaxes=" + StorageUtil.GetFloatValue(a, "MantellaOSLA_Climaxes", 0.0) + " satisfied=" + StorageUtil.GetIntValue(a, "MantellaOSLA_Satisfied", 0) + " raises=" + StorageUtil.GetIntValue(a, "MantellaOSLA_PeakRaises", 0) + " peakSince=" + StorageUtil.GetFloatValue(a, "MantellaOSLA_PeakSince", 0.0) + " now=" + Utility.GetCurrentGameTime() + " arousal=" + OSLArousedNative.GetArousalNoSideEffects(a)
EndFunction

; Moves a stored game-time stamp back, to fake time passing.
Function AgeStamp(Actor a, string stampKey, float days)
	float v = StorageUtil.GetFloatValue(a, stampKey, 0.0)
	if v > 0.0
		StorageUtil.SetFloatValue(a, stampKey, v - days)
	endif
EndFunction

Function ResetAppetite(Actor a)
	StorageUtil.UnsetIntValue(a, "MantellaOSLA_Appetite")
	StorageUtil.UnsetFloatValue(a, "MantellaOSLA_Need")
	StorageUtil.UnsetFloatValue(a, "MantellaOSLA_Climaxes")
	StorageUtil.UnsetFloatValue(a, "MantellaOSLA_ClimaxTime")
	StorageUtil.UnsetIntValue(a, "MantellaOSLA_Satisfied")
	StorageUtil.UnsetIntValue(a, "MantellaOSLA_PeakRaises")
	StorageUtil.UnsetFloatValue(a, "MantellaOSLA_PeakSince")
EndFunction

float Function GetArousal(Actor a)
	return OSLArousedNative.GetArousalNoSideEffects(a)
EndFunction

float Function SetArousal(Actor a, float v)
	return OSLArousedNative.SetArousal(a, v)
EndFunction
