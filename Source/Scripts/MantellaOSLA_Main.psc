Scriptname MantellaOSLA_Main extends Quest
{Tells Mantella how aroused the player and the NPCs in a conversation are, using OSL Aroused.
How far an NPC acts on it depends on their temperament: reserved, bold or forward.
Each NPC also gets an appetite, rated once by Mantella from their bio: how many climaxes
in one session it takes to satisfy them.}

; Mantella mod events (see MantellaInterface.psc). Used by name so this needs no Mantella master.
string Property EVENT_ADD_EVENT = "MantellaAddEvent" AutoReadOnly
string Property EVENT_STARTED = "MantellaConversation_Started" AutoReadOnly
string Property EVENT_ENDED = "MantellaConversation_Ended" AutoReadOnly
string Property EVENT_NPC_ADDED = "MantellaConversation_NPC_Added" AutoReadOnly
string Property EVENT_NPC_REMOVED = "MantellaConversation_NPC_Removed" AutoReadOnly
; OStim climax event, also used by name so this needs no OStim master.
string Property EVENT_OSTIM_ORGASM = "ostim_actor_orgasm" AutoReadOnly

; Mantella actions (data\actions\*.json). Legacy events carry the speaker; advanced ones add conversation + arguments.
string Property ACTION_PREFIX = "MantellaConversation_Action_" AutoReadOnly
string Property ADVANCED_ACTION_PREFIX = "MantellaConversation_Advanced_Action_" AutoReadOnly
string Property ACTION_AROUSE = "mantella_osla_arouse" AutoReadOnly
string Property ACTION_CALM = "mantella_osla_calm" AutoReadOnly
string Property ACTION_RATE = "mantella_osla_rate_appetite" AutoReadOnly
string Property ACTION_CLIMAXES = "mantella_osla_add_climaxes" AutoReadOnly
float Property ActionStep = 10.0 AutoReadOnly

float Property CheckInterval = 30.0 AutoReadOnly
int Property MaxTracked = 10 AutoReadOnly

; Settings and override lists, read with PapyrusUtil from
; Data\SKSE\Plugins\StorageUtilData\MantellaOSLA\settings.json
string Property SETTINGS_FILE = "MantellaOSLA/settings.json" AutoReadOnly
; Kept on the actor by StorageUtil.
string Property KEY_PEAK_SINCE = "MantellaOSLA_PeakSince" AutoReadOnly ; game days, first seen at 100
string Property KEY_PEAK_RAISES = "MantellaOSLA_PeakRaises" AutoReadOnly ; need raises applied this peak stretch
string Property KEY_APPETITE = "MantellaOSLA_Appetite" AutoReadOnly ; rated appetite, 1-30
string Property KEY_NEED = "MantellaOSLA_Need" AutoReadOnly ; climaxes needed this session
string Property KEY_CLIMAXES = "MantellaOSLA_Climaxes" AutoReadOnly ; climaxes so far, drains over time
string Property KEY_CLIMAX_TIME = "MantellaOSLA_ClimaxTime" AutoReadOnly ; game days, last drain
string Property KEY_SATISFIED = "MantellaOSLA_Satisfied" AutoReadOnly
string Property KEY_OVERWHELMED = "MantellaOSLA_Overwhelmed" AutoReadOnly

int Property MaxAppetite = 30 AutoReadOnly
int Property MaxStoryClimaxes = 1000 AutoReadOnly
; Drain rate for an NPC who has climaxed but was never rated.
int Property UnratedAppetite = 10 AutoReadOnly

; Temperaments
int Property TIER_RESERVED = 0 AutoReadOnly
int Property TIER_BOLD = 1 AutoReadOnly
int Property TIER_FORWARD = 2 AutoReadOnly

Actor[] _actors
int[] _bands
int[] _tiers
bool[] _peakLongSent
bool[] _rateAsked
int _playerBand = -1
bool _inConversation = false

Event OnInit()
	AllocateTracked()
	RegisterEvents()
EndEvent

Function RegisterEvents()
	RegisterForModEvent(EVENT_STARTED, "OnMantellaStarted")
	RegisterForModEvent(EVENT_ENDED, "OnMantellaEnded")
	RegisterForModEvent(EVENT_NPC_ADDED, "OnMantellaNpcAdded")
	RegisterForModEvent(EVENT_NPC_REMOVED, "OnMantellaNpcRemoved")
	RegisterForModEvent(ACTION_PREFIX + ACTION_AROUSE, "OnArouseLegacy")
	RegisterForModEvent(ADVANCED_ACTION_PREFIX + ACTION_AROUSE, "OnArouseAdvanced")
	RegisterForModEvent(ACTION_PREFIX + ACTION_CALM, "OnCalmLegacy")
	RegisterForModEvent(ADVANCED_ACTION_PREFIX + ACTION_CALM, "OnCalmAdvanced")
	; Only the advanced form carries the number these two need.
	RegisterForModEvent(ADVANCED_ACTION_PREFIX + ACTION_RATE, "OnRateAdvanced")
	RegisterForModEvent(ADVANCED_ACTION_PREFIX + ACTION_CLIMAXES, "OnClimaxesAdvanced")
	RegisterForModEvent(EVENT_OSTIM_ORGASM, "OnOStimOrgasm")
EndFunction

; Saves made before temperaments or appetite existed only have the earlier arrays.
Function AllocateTracked()
	if !_actors
		_actors = new Actor[10]
		_bands = new int[10]
	endif
	if !_tiers
		_tiers = new int[10]
		_peakLongSent = new bool[10]
	endif
	if !_rateAsked
		_rateAsked = new bool[10]
	endif
EndFunction

; 0 calm, 1 a little flushed, 2 noticeably aroused, 3 intensely aroused, 4 peak (100).
; OSL blends toward a baseline, so an NPC set to 100 reads back around 99.
int Function GetBand(Actor akActor)
	float arousal = OSLArousedNative.GetArousalNoSideEffects(akActor)
	if arousal >= 98.0
		return 4
	elseif arousal >= 80.0
		return 3
	elseif arousal >= 50.0
		return 2
	elseif arousal >= 20.0
		return 1
	endif
	return 0
EndFunction

; ---------------------------------------------------------------------------
; Temperament: lusty (high appetite, or before rating the OSL arousal multiplier or
; exhibitionist) and close to the player (vanilla Lover rank, Romantasy Lover or
; Spouse, M.A.R.A.S engaged or married).
; Both = forward, either = bold, neither = reserved. The settings file can
; force a name to "forward" (or the old "insatiable") or "reserved".
; ---------------------------------------------------------------------------

int Function GetTier(Actor akActor)
	; Mantella - Adult Expansion - OStim's per-NPC choice (1 reserved, 2 bold, 3 forward) beats everything.
	int override = StorageUtil.GetIntValue(akActor, "MAE_TemperOverride", 0)
	if override > 0
		return override - 1
	endif
	string name = akActor.GetDisplayName()
	if JsonUtil.StringListHas(SETTINGS_FILE, "forward", name) || JsonUtil.StringListHas(SETTINGS_FILE, "insatiable", name)
		return TIER_FORWARD
	elseif JsonUtil.StringListHas(SETTINGS_FILE, "reserved", name)
		return TIER_RESERVED
	endif
	; ... then its default for everyone else, unless that is Auto (0).
	GlobalVariable defaultTier = Game.GetFormFromFile(0x00080D, "Mantella - Adult Expansion - OStim.esp") as GlobalVariable
	if defaultTier && defaultTier.GetValueInt() > 0
		return defaultTier.GetValueInt() - 1
	endif
	bool lusty = IsLusty(akActor)
	bool close = IsClose(akActor)
	if lusty && close
		return TIER_FORWARD
	elseif lusty || close
		return TIER_BOLD
	endif
	return TIER_RESERVED
EndFunction

; OSL libido is one value shared by every NPC, so it cannot tell NPCs apart.
; The arousal multiplier and the exhibitionist flag are per NPC.
bool Function IsLusty(Actor akActor)
	; Adult Expansion setup can tell Auto to ignore the appetite rating and use OSL values only.
	GlobalVariable source = Game.GetFormFromFile(0x00080E, "Mantella - Adult Expansion - OStim.esp") as GlobalVariable
	int appetite = 0
	if !source || source.GetValueInt() == 0
		appetite = GetAppetite(akActor)
	endif
	if appetite > 0
		return appetite >= JsonUtil.GetIntValue(SETTINGS_FILE, "lusty_appetite", 15)
	endif
	float threshold = JsonUtil.GetFloatValue(SETTINGS_FILE, "multiplier_threshold", 1.5)
	return OSLArousedNative.GetArousalMultiplier(akActor) >= threshold || OSLArousedNative.IsActorExhibitionist(akActor)
EndFunction

bool Function IsClose(Actor akActor)
	Actor player = Game.GetPlayer()
	if akActor.GetRelationshipRank(player) >= 4
		return true
	endif
	; Romantasy mirrors its tier into this faction: rank 4 = Lover, 5 = Spouse.
	Faction romanceLevel = Game.GetFormFromFile(0x000800, "CS_Romantasy.esp") as Faction
	if romanceLevel && akActor.GetFactionRank(romanceLevel) >= 4
		return true
	endif
	if Game.GetModByName("TT_MARAS.esp") != 255 || Game.GetLightModByName("TT_MARAS.esp") != 255
		return MantellaOSLA_MARAS.IsEngagedOrMarried(akActor)
	endif
	return false
EndFunction

; ---------------------------------------------------------------------------
; Appetite: a fixed rating, this session's need (raised by long peaks), and a
; climax count that drains by the full rating every recovery_days game days.
; ---------------------------------------------------------------------------

; 0 = not rated yet. A settings override ("int": {"appetite_<Name>": n}) wins.
int Function GetAppetite(Actor akActor)
	int value = JsonUtil.GetIntValue(SETTINGS_FILE, "appetite_" + akActor.GetDisplayName(), 0)
	if value <= 0
		value = StorageUtil.GetIntValue(akActor, KEY_APPETITE, 0)
	endif
	if value > MaxAppetite
		value = MaxAppetite
	endif
	return value
EndFunction

float Function GetNeed(Actor akActor)
	float appetite = GetAppetite(akActor) as float
	float need = StorageUtil.GetFloatValue(akActor, KEY_NEED, 0.0)
	if need < appetite
		need = appetite
	endif
	return need
EndFunction

; Current count after draining for the time since the last change.
float Function GetClimaxes(Actor akActor)
	float count = StorageUtil.GetFloatValue(akActor, KEY_CLIMAXES, 0.0)
	if count <= 0.0
		return 0.0
	endif
	float now = Utility.GetCurrentGameTime()
	float last = StorageUtil.GetFloatValue(akActor, KEY_CLIMAX_TIME, now)
	float days = JsonUtil.GetFloatValue(SETTINGS_FILE, "recovery_days", 1.0)
	if days <= 0.0
		days = 1.0
	endif
	int rate = GetAppetite(akActor)
	if rate <= 0
		rate = UnratedAppetite
	endif
	count -= (rate as float) * (now - last) / days
	if count <= 0.0
		; Fully recovered: back to the plain rating.
		StorageUtil.UnsetFloatValue(akActor, KEY_CLIMAXES)
		StorageUtil.UnsetFloatValue(akActor, KEY_CLIMAX_TIME)
		StorageUtil.UnsetFloatValue(akActor, KEY_NEED)
		return 0.0
	endif
	StorageUtil.SetFloatValue(akActor, KEY_CLIMAXES, count)
	StorageUtil.SetFloatValue(akActor, KEY_CLIMAX_TIME, now)
	return count
EndFunction

Function AddClimaxes(Actor akActor, int aiCount)
	float count = GetClimaxes(akActor) + (aiCount as float)
	StorageUtil.SetFloatValue(akActor, KEY_CLIMAXES, count)
	StorageUtil.SetFloatValue(akActor, KEY_CLIMAX_TIME, Utility.GetCurrentGameTime())
EndFunction

; The count drains a little between any two events, so it is compared and shown rounded.
int Function WholeClimaxes(Actor akActor)
	return Math.Floor(GetClimaxes(akActor) + 0.5)
EndFunction

bool Function IsSatisfied(Actor akActor)
	return StorageUtil.GetIntValue(akActor, KEY_SATISFIED, 0) == 1
EndFunction

bool Function IsOverwhelmed(Actor akActor)
	return StorageUtil.GetIntValue(akActor, KEY_OVERWHELMED, 0) == 1
EndFunction

; Climaxes at which she is overwhelmed: overwhelm_ratio (1.5) times the need.
int Function OverwhelmLimit(Actor akActor)
	return Math.Ceiling(GetNeed(akActor) * JsonUtil.GetFloatValue(SETTINGS_FILE, "overwhelm_ratio", 1.5))
EndFunction

; Flips the satisfied and overwhelmed flags when the count crosses the need or
; the overwhelm limit. Returns the line to send when one was just reached, else "".
string Function UpdateSatisfied(Actor akActor)
	if GetAppetite(akActor) <= 0
		return ""
	endif
	int count = WholeClimaxes(akActor)
	int need = Math.Ceiling(GetNeed(akActor))
	int limit = OverwhelmLimit(akActor)
	bool was = IsSatisfied(akActor)
	bool wasOver = IsOverwhelmed(akActor)
	string line = ""
	if count >= need && !was
		StorageUtil.SetIntValue(akActor, KEY_SATISFIED, 1)
		OSLArousedNative.SetArousal(akActor, 0.0)
		StorageUtil.UnsetFloatValue(akActor, KEY_PEAK_SINCE)
		StorageUtil.UnsetIntValue(akActor, KEY_PEAK_RAISES)
		line = akActor.GetDisplayName() + " is completely satisfied for now."
	elseif count < need && was
		StorageUtil.UnsetIntValue(akActor, KEY_SATISFIED)
	endif
	if count >= limit && !wasOver
		StorageUtil.SetIntValue(akActor, KEY_OVERWHELMED, 1)
		string name = akActor.GetDisplayName()
		line = name + " has climaxed " + count + " times, far past the " + need + " that satisfies " + Objective(akActor) + "; " + name + " is overwhelmed and keeps begging the player to stop and let " + Objective(akActor) + " rest."
	elseif count < limit && wasOver
		StorageUtil.UnsetIntValue(akActor, KEY_OVERWHELMED)
	endif
	return line
EndFunction

; Every peak_minutes at 100 raises this session's need by peak_raise of the
; rating (rounded up, at least 1), up to double the rating.
Function ApplyPeakRaises(Actor akActor)
	int appetite = GetAppetite(akActor)
	if appetite <= 0
		return
	endif
	float minutes = JsonUtil.GetFloatValue(SETTINGS_FILE, "peak_minutes", 5.0)
	if minutes <= 0.0
		return
	endif
	int due = Math.Floor(PeakRealMinutes(akActor) / minutes)
	int applied = StorageUtil.GetIntValue(akActor, KEY_PEAK_RAISES, 0)
	if due <= applied
		return
	endif
	int step = Math.Ceiling((appetite as float) * JsonUtil.GetFloatValue(SETTINGS_FILE, "peak_raise", 0.2))
	if step < 1
		step = 1
	endif
	float need = GetNeed(akActor) + ((due - applied) * step) as float
	float cap = (appetite * 2) as float
	if need > cap
		need = cap
	endif
	StorageUtil.SetFloatValue(akActor, KEY_NEED, need)
	StorageUtil.SetIntValue(akActor, KEY_PEAK_RAISES, due)
EndFunction

string Function ProgressText(Actor akActor)
	int need = Math.Ceiling(GetNeed(akActor))
	int count = WholeClimaxes(akActor)
	; Papyrus shares one copy of strings that differ only in case, so a capitalised
	; pronoun can come out lowercase; start the sentence with the name instead.
	string name = akActor.GetDisplayName()
	if count <= 0
		return " Right now it would take about " + need + " climaxes to satisfy " + Objective(akActor) + "."
	elseif count == 1
		return " " + name + " has climaxed once so far; it would take about " + need + " to satisfy " + Objective(akActor) + "."
	endif
	return " " + name + " has climaxed " + count + " times so far; it would take about " + need + " to satisfy " + Objective(akActor) + "."
EndFunction

; ---------------------------------------------------------------------------
; Peak timer
; ---------------------------------------------------------------------------

Function UpdatePeak(Actor akActor, int band)
	if band == 4
		if StorageUtil.GetFloatValue(akActor, KEY_PEAK_SINCE, 0.0) <= 0.0
			StorageUtil.SetFloatValue(akActor, KEY_PEAK_SINCE, Utility.GetCurrentGameTime())
		endif
	else
		StorageUtil.UnsetFloatValue(akActor, KEY_PEAK_SINCE)
		StorageUtil.UnsetIntValue(akActor, KEY_PEAK_RAISES)
	endif
EndFunction

; Real minutes spent at 100, from game time and the timescale.
float Function PeakRealMinutes(Actor akActor)
	float since = StorageUtil.GetFloatValue(akActor, KEY_PEAK_SINCE, 0.0)
	if since <= 0.0
		return 0.0
	endif
	float timescale = 20.0
	GlobalVariable timescaleGlobal = Game.GetFormFromFile(0x00003A, "Skyrim.esm") as GlobalVariable
	if timescaleGlobal && timescaleGlobal.GetValue() > 0.0
		timescale = timescaleGlobal.GetValue()
	endif
	return (Utility.GetCurrentGameTime() - since) * 1440.0 / timescale
EndFunction

; The "right here, right now" line, once per conversation, for forward NPCs
; who have been at 100 long enough and are not yet satisfied.
string Function PeakLongLine(int slot)
	Actor npc = _actors[slot]
	if _tiers[slot] != TIER_FORWARD || _bands[slot] != 4 || _peakLongSent[slot] || IsSatisfied(npc)
		return ""
	endif
	float minutes = JsonUtil.GetFloatValue(SETTINGS_FILE, "peak_minutes", 5.0)
	if PeakRealMinutes(npc) < minutes
		return ""
	endif
	_peakLongSent[slot] = true
	; Adult Expansion "Never force-start a scene" (default on): she begs, but leaves it to the player.
	GlobalVariable neverForce = Game.GetFormFromFile(0x000810, "Mantella - Adult Expansion - OStim.esp") as GlobalVariable
	if !neverForce || neverForce.GetValueInt() == 1
		return npc.GetDisplayName() + " has been at peak arousal for a long while and can't hold back any more; " + Pronoun(npc) + " begs the player for sex right here, right now, but does not start anything without the player's yes."
	endif
	return npc.GetDisplayName() + " has been at peak arousal for a long while and can't hold back any more; " + Pronoun(npc) + " insists on having sex with the player right here, right now."
EndFunction

; ---------------------------------------------------------------------------
; Lines
; ---------------------------------------------------------------------------

string Function Pronoun(Actor akActor)
	if akActor.GetLeveledActorBase().GetSex() == 1
		return "she"
	endif
	return "he"
EndFunction

string Function Objective(Actor akActor)
	if akActor.GetLeveledActorBase().GetSex() == 1
		return "her"
	endif
	return "him"
EndFunction


; The player's own level.
string Function Describe(Actor akActor, int band)
	string name = akActor.GetDisplayName()
	if band >= 3
		return name + " is intensely aroused."
	elseif band == 2
		return name + " seems noticeably aroused."
	elseif band == 1
		return name + " looks a little flushed."
	endif
	return name + " seems calm."
EndFunction

; An NPC's level, phrased by temperament.
string Function DescribeNpc(Actor akActor, int band, int tier)
	string name = akActor.GetDisplayName()
	string p = Pronoun(akActor)
	if band == 0
		return name + " seems calm."
	elseif band == 1
		return name + " looks a little flushed."
	elseif IsSatisfied(akActor)
		return name + " is still a little aroused, but satisfied for now and in no hurry."
	elseif tier == TIER_RESERVED
		if band == 2
			return name + " seems noticeably aroused, though " + p + " keeps it to " + Reflexive(akActor) + "."
		endif
		return name + " is intensely aroused; " + p + " lets it show and drops a hint or two, but won't make the first move."
	elseif band == 2
		return name + " is noticeably aroused and doesn't hide it; " + p + " may bring it up openly."
	elseif band == 3
		return name + " is intensely aroused and is actively trying to get the player into bed."
	endif
	return name + "'s arousal is at its peak; " + p + " asks the player directly for sex, but accepts a refusal."
EndFunction

string Function Reflexive(Actor akActor)
	if akActor.GetLeveledActorBase().GetSex() == 1
		return "herself"
	endif
	return "himself"
EndFunction

Function SendLine(string text)
	if text == ""
		return
	endif
	int handle = ModEvent.Create(EVENT_ADD_EVENT)
	if handle
		ModEvent.PushString(handle, text)
		ModEvent.Send(handle)
	endif
EndFunction

Function ClearTracked()
	AllocateTracked()
	int i = 0
	while i < MaxTracked
		_actors[i] = None
		_bands[i] = -1
		_tiers[i] = TIER_RESERVED
		_peakLongSent[i] = false
		_rateAsked[i] = false
		i += 1
	endWhile
	_playerBand = -1
EndFunction

; ---------------------------------------------------------------------------
; Conversation events
; ---------------------------------------------------------------------------

Event OnMantellaStarted()
	; Saves made before the actions existed only registered the conversation events in OnInit.
	RegisterEvents()
	AllocateTracked()
	if !_inConversation
		ClearTracked()
		_inConversation = true
	endif
	if _playerBand < 0
		Actor player = Game.GetPlayer()
		_playerBand = GetBand(player)
		SendLine(Describe(player, _playerBand))
	endif
	RegisterForSingleUpdate(CheckInterval)
EndEvent

Event OnMantellaEnded()
	_inConversation = false
	UnregisterForUpdate()
	ClearTracked()
EndEvent

Event OnMantellaNpcAdded(Form akForm)
	Actor npc = akForm as Actor
	if !npc || npc == Game.GetPlayer()
		return
	endif
	AllocateTracked()
	if !_inConversation
		ClearTracked()
		_inConversation = true
		RegisterForSingleUpdate(CheckInterval)
	endif
	if _actors.Find(npc) >= 0
		return
	endif
	int slot = _actors.Find(None)
	if slot < 0
		return
	endif
	_actors[slot] = npc
	_bands[slot] = -1
	_tiers[slot] = GetTier(npc)
	_peakLongSent[slot] = false
	_rateAsked[slot] = false
	CheckSlot(slot)
EndEvent

Event OnMantellaNpcRemoved(Form akForm)
	Actor npc = akForm as Actor
	if !npc || !_actors
		return
	endif
	int slot = _actors.Find(npc)
	if slot >= 0
		_actors[slot] = None
		_bands[slot] = -1
	endif
EndEvent

Event OnArouseLegacy(Form akSpeaker)
	ShiftArousal(akSpeaker as Actor, ActionStep)
EndEvent

Event OnArouseAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	ShiftArousal(akSpeaker as Actor, ActionStep)
EndEvent

Event OnCalmLegacy(Form akSpeaker)
	ShiftArousal(akSpeaker as Actor, -ActionStep)
EndEvent

Event OnCalmAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	ShiftArousal(akSpeaker as Actor, -ActionStep)
EndEvent

; Mantella's one-time rating of the speaker's appetite. Ignored once rated.
Event OnRateAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Actor npc = akSpeaker as Actor
	if !npc || npc == Game.GetPlayer() || GetAppetite(npc) > 0
		return
	endif
	int value = SKSE_HTTP.getInt(aiArguments, "appetite", 0)
	if value <= 0
		return
	endif
	if value > MaxAppetite
		value = MaxAppetite
	endif
	StorageUtil.SetIntValue(npc, KEY_APPETITE, value)
	if !_actors
		return
	endif
	int slot = _actors.Find(npc)
	if slot >= 0
		_tiers[slot] = GetTier(npc)
	endif
EndEvent

; Climaxes the player describes in the story.
Event OnClimaxesAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Actor npc = akSpeaker as Actor
	if !npc || npc == Game.GetPlayer()
		return
	endif
	int count = SKSE_HTTP.getInt(aiArguments, "count", 0)
	if count <= 0
		return
	endif
	if count > MaxStoryClimaxes
		count = MaxStoryClimaxes
	endif
	bool wasOver = IsOverwhelmed(npc)
	AddClimaxes(npc, count)
	RecheckActor(npc, wasOver)
EndEvent

; Real OStim climaxes, for any NPC, in or out of a conversation.
Event OnOStimOrgasm(string asEventName, string asSceneID, float afThreadID, Form akSender)
	Actor npc = akSender as Actor
	if !npc || npc == Game.GetPlayer()
		return
	endif
	bool wasOver = IsOverwhelmed(npc)
	AddClimaxes(npc, 1)
	RecheckActor(npc, wasOver)
EndEvent

; Reports a change right away if the NPC is in the conversation; otherwise just
; updates the flags for later. Already overwhelmed and still climaxing: she begs again.
Function RecheckActor(Actor npc, bool abWasOverwhelmed)
	int slot = -1
	if _actors && _inConversation
		slot = _actors.Find(npc)
	endif
	if slot >= 0
		CheckSlot(slot)
		if abWasOverwhelmed && IsOverwhelmed(npc)
			SendLine(npc.GetDisplayName() + " climaxed again past " + Objective(npc) + " limit and begs the player even harder to let " + Objective(npc) + " rest.")
		endif
	else
		UpdateSatisfied(npc)
	endif
EndFunction

; Changes the speaker's arousal and reports a level change right away instead of at the next check.
Function ShiftArousal(Actor npc, float amount)
	if !npc || npc == Game.GetPlayer()
		return
	endif
	; SetArousal instead of ModifyArousal, which scales by the actor's arousal multiplier.
	float value = OSLArousedNative.GetArousalNoSideEffects(npc) + amount
	if value > 100.0
		value = 100.0
	elseif value < 0.0
		value = 0.0
	endif
	OSLArousedNative.SetArousal(npc, value)
	if !_actors
		return
	endif
	int slot = _actors.Find(npc)
	if slot >= 0
		CheckSlot(slot)
	endif
EndFunction

; Re-reads one tracked NPC and sends a line if they just became satisfied, their
; level changed or the peak timer ran out. Asks for a rating once they are aroused.
Function CheckSlot(int slot)
	Actor npc = _actors[slot]
	string line = UpdateSatisfied(npc)
	int band = GetBand(npc)
	UpdatePeak(npc, band)
	ApplyPeakRaises(npc)
	if line != ""
		_bands[slot] = band
	elseif band != _bands[slot]
		_bands[slot] = band
		line = DescribeNpc(npc, band, _tiers[slot])
		if band >= 2 && GetAppetite(npc) > 0 && !IsSatisfied(npc)
			line += ProgressText(npc)
		endif
	endif
	string peakLine = PeakLongLine(slot)
	if peakLine != ""
		line = peakLine
	endif
	SendLine(line)
	if band >= 2 && !_rateAsked[slot] && GetAppetite(npc) <= 0
		_rateAsked[slot] = true
		SendLine(npc.GetDisplayName() + "'s sexual appetite has not been rated yet.")
	endif
EndFunction

Event OnUpdate()
	if !_inConversation
		return
	endif
	Actor player = Game.GetPlayer()
	int band = GetBand(player)
	if band != _playerBand
		_playerBand = band
		SendLine(Describe(player, band))
	endif
	int i = 0
	while i < MaxTracked
		if _actors[i]
			CheckSlot(i)
		endif
		i += 1
	endWhile
	RegisterForSingleUpdate(CheckInterval)
EndEvent
