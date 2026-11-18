Scriptname MantellaOSLA_Test Hidden
{TEST ONLY. Global entry points for DevBench: drive the harness and read what the module decides.}

MantellaOSLA_TestHarness Function Harness() Global
	return Game.GetFormFromFile(0x000800, "MantellaOSLA_TEST.esp") as MantellaOSLA_TestHarness
EndFunction

MantellaOSLA_Main Function Main() Global
	return Game.GetFormFromFile(0x000800, "Mantella Living World - Arousal.esp") as MantellaOSLA_Main
EndFunction

Faction Function OpenFaction() Global
	return Game.GetFormFromFile(0x000801, "MantellaOSLA_TEST.esp") as Faction
EndFunction

; Clears the log and starts a fake conversation (NPCs join with Join). Call Finish first.
Function Begin() Global
	MantellaOSLA_TestHarness h = Harness()
	h.Reregister()
	h.ClearLog()
	h.FireStarted()
EndFunction

Function Join(Actor akNpc) Global
	Harness().FireNpcAdded(akNpc)
EndFunction

Function Finish() Global
	Harness().FireEnded()
EndFunction

string Function Log() Global
	return Harness().GetLog()
EndFunction

; "tier=<0-2> standing=<0-2> isClose=<key> duty=<bool> spouse=<bool> open=<bool> rank=<n>"
string Function Status(Actor akNpc) Global
	MantellaOSLA_Main m = Main()
	return "tier=" + m.GetTier(akNpc) + " standing=" + m.GetStanding(akNpc) + " isClose=" + StorageUtil.GetIntValue(akNpc, "MLW_IsClose", -1) + " duty=" + m.IsOnDuty(akNpc) + " spouse=" + m.SpouseNearby(akNpc) + " open=" + m.IsOpen(akNpc) + " public=" + m.InPublic(akNpc) + " rank=" + akNpc.GetRelationshipRank(Game.GetPlayer()) + " arousal=" + OSLArousedNative.GetArousalNoSideEffects(akNpc)
EndFunction

Function SetArousal(Actor akActor, float afValue) Global
	OSLArousedNative.GetArousal(akActor)  ; store the value for now first, see MantellaOSLA_Main.SetArousalNow
	OSLArousedNative.SetArousal(akActor, afValue)
EndFunction

Function SetRank(Actor akNpc, int aiRank) Global
	akNpc.SetRelationshipRank(Game.GetPlayer(), aiRank)
EndFunction

; 1 on duty, -1 off duty, 0 judged by the module.
Function SetDuty(Actor akNpc, int aiFlag) Global
	if aiFlag == 0
		StorageUtil.UnsetIntValue(akNpc, "MantellaOSLA_OnDuty")
	else
		StorageUtil.SetIntValue(akNpc, "MantellaOSLA_OnDuty", aiFlag)
	endif
EndFunction

; 0 clears the Hub's temperament override; 1 reserved, 2 bold, 3 forward.
Function SetOverride(Actor akNpc, int aiValue) Global
	if aiValue == 0
		StorageUtil.UnsetIntValue(akNpc, "MLW_TemperOverride")
	else
		StorageUtil.SetIntValue(akNpc, "MLW_TemperOverride", aiValue)
	endif
EndFunction

; 0 clears the rating.
Function SetAppetite(Actor akNpc, int aiValue) Global
	if aiValue == 0
		StorageUtil.UnsetIntValue(akNpc, "MantellaOSLA_Appetite")
	else
		StorageUtil.SetIntValue(akNpc, "MantellaOSLA_Appetite", aiValue)
	endif
EndFunction

; Puts the NPC in the test faction and lists that faction in open_factions (or undoes both).
Function SetOpen(Actor akNpc, bool abOn) Global
	string file = "MantellaOSLA/settings.json"
	string entry = "0x000801|MantellaOSLA_TEST.esp"
	SaveSettings()
	if abOn
		akNpc.AddToFaction(OpenFaction())
		if !JsonUtil.StringListHas(file, "open_factions", entry)
			JsonUtil.StringListAdd(file, "open_factions", entry)
		endif
	else
		akNpc.RemoveFromFaction(OpenFaction())
		JsonUtil.StringListRemove(file, "open_factions", entry)
	endif
EndFunction

; 1 = the player allowed intimacy with this NPC (as the Hub's hotkey writes it), 0 clears it.
Function SetIntimate(Actor akNpc, int aiValue) Global
	if aiValue == 0
		StorageUtil.UnsetIntValue(akNpc, "MLW_Intimate")
	else
		StorageUtil.SetIntValue(akNpc, "MLW_Intimate", aiValue)
	endif
EndFunction

; The BecomeAroused action, as Mantella sends it for the speaker.
Function Arouse(Actor akNpc) Global
	Harness().FireLegacyAction("mantella_osla_arouse", akNpc)
EndFunction

; settings public_radius (0 turns the public check off; the other tests run with it off).
Function SetPublicRadius(float afRadius) Global
	SaveSettings()
	JsonUtil.SetFloatValue("MantellaOSLA/settings.json", "public_radius", afRadius)
EndFunction

; Remembers the player's public_radius and whether open_factions listed the test faction, before a test changes them.
; Kept until RestoreSettings, so a run that stopped early is put back by the next run's cleanup.
Function SaveSettings() Global
	if StorageUtil.GetIntValue(None, "MantellaOSLA_Test_Saved", 0) == 1
		return
	endif
	string file = "MantellaOSLA/settings.json"
	StorageUtil.SetIntValue(None, "MantellaOSLA_Test_HadRadius", JsonUtil.HasFloatValue(file, "public_radius") as int)
	StorageUtil.SetFloatValue(None, "MantellaOSLA_Test_Radius", JsonUtil.GetFloatValue(file, "public_radius"))
	StorageUtil.SetIntValue(None, "MantellaOSLA_Test_HadOpen", JsonUtil.StringListHas(file, "open_factions", "0x000801|MantellaOSLA_TEST.esp") as int)
	StorageUtil.SetIntValue(None, "MantellaOSLA_Test_Saved", 1)
EndFunction

; Puts back what SaveSettings remembered.
Function RestoreSettings() Global
	if StorageUtil.GetIntValue(None, "MantellaOSLA_Test_Saved", 0) != 1
		return
	endif
	string file = "MantellaOSLA/settings.json"
	string entry = "0x000801|MantellaOSLA_TEST.esp"
	if StorageUtil.GetIntValue(None, "MantellaOSLA_Test_HadRadius", 0) == 1
		JsonUtil.SetFloatValue(file, "public_radius", StorageUtil.GetFloatValue(None, "MantellaOSLA_Test_Radius"))
	else
		JsonUtil.UnsetFloatValue(file, "public_radius")
	endif
	if StorageUtil.GetIntValue(None, "MantellaOSLA_Test_HadOpen", 0) == 1
		if !JsonUtil.StringListHas(file, "open_factions", entry)
			JsonUtil.StringListAdd(file, "open_factions", entry)
		endif
	else
		JsonUtil.StringListRemove(file, "open_factions", entry)
	endif
	StorageUtil.UnsetIntValue(None, "MantellaOSLA_Test_HadRadius")
	StorageUtil.UnsetFloatValue(None, "MantellaOSLA_Test_Radius")
	StorageUtil.UnsetIntValue(None, "MantellaOSLA_Test_HadOpen")
	StorageUtil.UnsetIntValue(None, "MantellaOSLA_Test_Saved")
EndFunction

; Forgets that the NPC's spouse was not found, so the next check searches the loaded actors again.
Function ForgetSpouseMiss(Actor akNpc) Global
	StorageUtil.UnsetFloatValue(akNpc, "MantellaOSLA_SpouseMiss")
EndFunction
