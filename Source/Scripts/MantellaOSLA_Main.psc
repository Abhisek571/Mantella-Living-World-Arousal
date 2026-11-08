Scriptname MantellaOSLA_Main extends Quest
{Tells Mantella how aroused the player and the NPCs in a conversation are, using OSL Aroused.
How far an NPC acts on it depends on their temperament: reserved, bold or forward.
For strangers it is only a private mood that has nothing to do with the player; interest in
the player has to be earned (friend or closer), unless the NPC belongs to an open group.
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
; Temperament defaults and the never-force switch live in the Integration Hub.
string Property HUB_PLUGIN = "Mantella Living World - Integration Hub.esp" AutoReadOnly
; Kept on the actor by StorageUtil.
string Property KEY_PEAK_SINCE = "MantellaOSLA_PeakSince" AutoReadOnly ; game days, first seen at 100
string Property KEY_PEAK_RAISES = "MantellaOSLA_PeakRaises" AutoReadOnly ; need raises applied this peak stretch
string Property KEY_APPETITE = "MantellaOSLA_Appetite" AutoReadOnly ; rated appetite, 1-30
string Property KEY_NEED = "MantellaOSLA_Need" AutoReadOnly ; climaxes needed this session
string Property KEY_CLIMAXES = "MantellaOSLA_Climaxes" AutoReadOnly ; climaxes so far, drains over time
string Property KEY_CLIMAX_TIME = "MantellaOSLA_ClimaxTime" AutoReadOnly ; game days, last drain
string Property KEY_SATISFIED = "MantellaOSLA_Satisfied" AutoReadOnly
string Property KEY_OVERWHELMED = "MantellaOSLA_Overwhelmed" AutoReadOnly
; 1 always on duty, -1 never; 0 or unset = judged from guard status and duty_factions.
string Property KEY_ON_DUTY = "MantellaOSLA_OnDuty" AutoReadOnly
; Written for the other modules: 0 stranger, 1 close, 2 open group. Above 0 passes the "close" action gate.
string Property KEY_IS_CLOSE = "MLW_IsClose" AutoReadOnly
; Set above 0 by the Relationships module for NPCs it counts as friend or closer.
string Property KEY_RELATIONSHIPS_CLOSE = "MRB_Close" AutoReadOnly
string Property RELATIONSHIPS_PLUGIN = "Mantella Living World - Relationships.esp" AutoReadOnly
; 1 = the player allowed intimacy with this NPC (the Hub's hotkey). Close alone never does.
string Property KEY_INTIMATE = "MLW_Intimate" AutoReadOnly
; Written for the other modules: the temperament + 1 (1 reserved, 2 bold, 3 forward); 0 or unset = not known yet.
; They ask for a fresh value with the mod event below, so none of them has to name this script.
string Property KEY_TIER = "MLW_Tier" AutoReadOnly
string Property EVENT_TIER_REQUEST = "MLW_TierRequest" AutoReadOnly
; Another module adds climaxes for an NPC (form + count), so the drain is applied before the count goes up.
string Property EVENT_ADD_CLIMAXES = "MLW_AddClimaxes" AutoReadOnly
; The Hub's signal that an NPC's standing may have changed (form pushed with the event).
string Property EVENT_REFRESH_NPC = "MLW_RefreshNpc" AutoReadOnly
; Written for the hub's setup summary: the NPCs Mantella has rated.
string Property KEY_RATED = "MLW_RatedNPCs" AutoReadOnly

int Property MaxAppetite = 30 AutoReadOnly
int Property MaxStoryClimaxes = 1000 AutoReadOnly
; Drain rate for an NPC who has climaxed but was never rated.
int Property UnratedAppetite = 10 AutoReadOnly

; Temperaments
int Property TIER_RESERVED = 0 AutoReadOnly
int Property TIER_BOLD = 1 AutoReadOnly
int Property TIER_FORWARD = 2 AutoReadOnly

; How an NPC stands with the player
int Property STANDING_STRANGER = 0 AutoReadOnly
int Property STANDING_CLOSE = 1 AutoReadOnly
int Property STANDING_OPEN = 2 AutoReadOnly
; How far to look for the NPC's own spouse or partner (game units, about 30 m).
float Property SpouseRadius = 1024.0 AutoReadOnly  ; about 15 m: in earshot
; Someone else this close, in the same cell, makes it a public place (settings "public_radius", 0 = off).
float Property PublicRadius = 1024.0 AutoReadOnly  ; about 15 m

Actor[] _actors
int[] _bands
int[] _tiers
int[] _standing
bool[] _peakLongSent
bool[] _rateAsked
; Children in the conversation (never tracked above). While any is there, no arousal line is sent at all.
Actor[] _minors
int _playerBand = -1
bool _inConversation = false
bool _climaxLock = false

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
	RegisterForModEvent(EVENT_TIER_REQUEST, "OnTierRequest")
	RegisterForModEvent(EVENT_ADD_CLIMAXES, "OnAddClimaxesEvent")
	RegisterForModEvent(EVENT_REFRESH_NPC, "OnLivingWorldRefresh")
	RegisterForModEvent("MLW_Cheat", "OnCheat")
EndFunction

; The Integration Hub MCM's cheats page (testing): sets the target's arousal; "reset" puts back the value from before
; the first cheat, but only while the arousal is still what the last cheat set (within 1). If it has changed since,
; it is left as it is. Either way the snapshot is dropped.
Event OnCheat(Form akNpc, string asWhat, float afValue)
	Actor npc = akNpc as Actor
	if !npc || npc == Game.GetPlayer() || IsMinor(npc)
		return
	endif
	if asWhat == "arousal"
		if !StorageUtil.HasFloatValue(npc, "MantellaOSLA_CheatArousal")
			StorageUtil.SetFloatValue(npc, "MantellaOSLA_CheatArousal", OSLArousedNative.GetArousalNoSideEffects(npc))
		endif
		OSLArousedNative.SetArousal(npc, afValue)
		StorageUtil.SetFloatValue(npc, "MantellaOSLA_CheatArousalSet", afValue)
	elseif asWhat == "reset"
		if !StorageUtil.HasFloatValue(npc, "MantellaOSLA_CheatArousal")
			return
		endif
		float before = StorageUtil.GetFloatValue(npc, "MantellaOSLA_CheatArousal")
		float setTo = StorageUtil.GetFloatValue(npc, "MantellaOSLA_CheatArousalSet", -100.0)
		float diff = OSLArousedNative.GetArousalNoSideEffects(npc) - setTo
		StorageUtil.UnsetFloatValue(npc, "MantellaOSLA_CheatArousal")
		StorageUtil.UnsetFloatValue(npc, "MantellaOSLA_CheatArousalSet")
		if diff > 1.0 || diff < -1.0
			Debug.Notification(npc.GetDisplayName() + ": arousal changed since the debug menu set it, left as it is.")
			return
		endif
		OSLArousedNative.SetArousal(npc, before)
	else
		return
	endif
	RecheckActor(npc, false)
EndEvent

; Children are never close, never rated, never aroused. Some mods clear the child flag, so the race is checked too.
bool Function IsMinor(Actor akActor)
	if akActor.IsChild()
		return true
	endif
	Race actorRace = akActor.GetRace()
	return actorRace && StringUtil.Find(MiscUtil.GetRaceEditorID(actorRace), "Child") >= 0
EndFunction

; Another module asks for an NPC's temperament (form pushed with the event).
Event OnTierRequest(Form akForm)
	Actor npc = akForm as Actor
	if npc && npc != Game.GetPlayer()
		PublishTier(npc, GetTier(npc))
	endif
EndEvent

; An NPC's standing may have changed mid-talk (Relationships wrote MRB_Close, a follower joined): re-read it for a
; tracked NPC. Sends no MLW_RefreshNpc itself, since this script's own NPC-added handler sends one.
Event OnLivingWorldRefresh(Form akForm)
	Actor npc = akForm as Actor
	if !npc || npc == Game.GetPlayer() || !_actors || !_inConversation
		return
	endif
	int slot = _actors.Find(npc)
	if slot < 0
		return
	endif
	int standing = GetStanding(npc)
	int tier = TierFor(npc, standing)
	; The slot may have been freed or reused while the checks ran.
	if _actors[slot] != npc
		return
	endif
	if standing != _standing[slot]
		_bands[slot] = -1 ; the next check describes her the new way
	endif
	_standing[slot] = standing
	_tiers[slot] = tier
	PublishTier(npc, tier)
	StorageUtil.SetIntValue(npc, KEY_IS_CLOSE, standing)
EndEvent

Function PublishTier(Actor akActor, int aiTier)
	StorageUtil.SetIntValue(akActor, KEY_TIER, aiTier + 1)
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
	if !_standing
		_standing = new int[10]
	endif
	if !_minors
		_minors = new Actor[10]
	endif
EndFunction

bool Function MinorInTalk()
	if !_minors
		return false
	endif
	int i = 0
	while i < MaxTracked
		if _minors[i]
			return true
		endif
		i += 1
	endWhile
	return false
EndFunction

; The first child joined: every tracked NPC is reserved from now on (sent to the other modules too).
Function OnMinorJoined()
	int i = 0
	while i < MaxTracked
		if _actors[i]
			_tiers[i] = TIER_RESERVED
			PublishTier(_actors[i], TIER_RESERVED)
		endif
		i += 1
	endWhile
EndFunction

; The last child left: tiers are worked out again and every level is described afresh at the next check.
Function OnLastMinorLeft()
	_playerBand = -1
	int i = 0
	while i < MaxTracked
		Actor npc = _actors[i]
		if npc
			int tier = TierFor(npc, _standing[i])
			; The slot may have been freed or reused while the checks ran.
			if _actors[i] == npc
				_tiers[i] = tier
				_bands[i] = -1
				PublishTier(npc, tier)
			endif
		endif
		i += 1
	endWhile
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
; Temperament. On duty, with their own spouse nearby, or in public (someone
; else awake within about 15 m in the same cell, the player's party left out):
; reserved, always.
; Strangers are reserved and their arousal is a private mood. Open groups
; (settings open_races / open_factions / open_keywords) are forward even as
; strangers. Close NPCs (friend or above) weigh lusty (high appetite, or before
; rating the OSL arousal multiplier or exhibitionist) and intimate (vanilla Lover
; rank, M.A.R.A.S engaged, married or lover): both = forward, either = bold, neither =
; reserved. The settings file can force a name to "forward" (or the old
; "insatiable") or "reserved". Neither that nor the Hub's per-NPC choice makes
; anyone close: they only set how an NPC who is already close or open behaves.
; ---------------------------------------------------------------------------

int Function GetTier(Actor akActor)
	return TierFor(akActor, GetStanding(akActor))
EndFunction

int Function TierFor(Actor akActor, int aiStanding)
	; A child in the same conversation keeps everyone in it reserved.
	if IsMinor(akActor) || (MinorInTalk() && _actors && _actors.Find(akActor) >= 0)
		return TIER_RESERVED
	elseif IsOnDuty(akActor) || SpouseNearby(akActor) || InPublic(akActor)
		return TIER_RESERVED
	elseif aiStanding == STANDING_STRANGER
		return TIER_RESERVED
	endif
	; The Integration Hub's per-NPC choice (1 reserved, 2 bold, 3 forward) beats the rest.
	int override = StorageUtil.GetIntValue(akActor, "MLW_TemperOverride", 0)
	if override > 0
		return override - 1
	endif
	string name = akActor.GetDisplayName()
	if IsNamedForward(akActor)
		return TIER_FORWARD
	elseif JsonUtil.StringListHas(SETTINGS_FILE, "reserved", name)
		return TIER_RESERVED
	endif
	if aiStanding == STANDING_OPEN
		return TIER_FORWARD
	endif
	; ... then its default for close NPCs, unless that is Auto (0).
	GlobalVariable defaultTier = Game.GetFormFromFile(0x000802, HUB_PLUGIN) as GlobalVariable
	if defaultTier && defaultTier.GetValueInt() > 0
		return defaultTier.GetValueInt() - 1
	endif
	bool lusty = IsLusty(akActor)
	bool intimate = IsIntimate(akActor)
	if lusty && intimate
		return TIER_FORWARD
	elseif lusty || intimate
		return TIER_BOLD
	endif
	return TIER_RESERVED
EndFunction

bool Function IsNamedForward(Actor akActor)
	string name = akActor.GetDisplayName()
	return JsonUtil.StringListHas(SETTINGS_FILE, "forward", name) || JsonUtil.StringListHas(SETTINGS_FILE, "insatiable", name)
EndFunction

; Closeness is earned: friend or above, a follower or the Relationships module's
; say. Temperament never makes anyone close. An open group counts only while off duty.
int Function GetStanding(Actor akActor)
	if IsMinor(akActor)
		return STANDING_STRANGER
	elseif IsClose(akActor)
		return STANDING_CLOSE
	elseif IsOpen(akActor) && !IsOnDuty(akActor)
		return STANDING_OPEN
	endif
	return STANDING_STRANGER
EndFunction

; Guards and the listed duty factions (soldiers, knights, Thalmor) are on duty
; unless they travel with the player.
bool Function IsOnDuty(Actor akActor)
	int flag = StorageUtil.GetIntValue(akActor, KEY_ON_DUTY, 0)
	if flag != 0
		return flag > 0
	endif
	if akActor.IsPlayerTeammate()
		return false
	endif
	return akActor.IsGuard() || InListedFaction(akActor, "duty_factions")
EndFunction

; Their own living spouse (vanilla Spouse association) close by.
bool Function SpouseNearby(Actor akActor)
	Actor partner = SpouseOf(akActor)
	return partner && !partner.IsDead() && partner.Is3DLoaded() && partner.GetDistance(akActor) <= SpouseRadius
EndFunction

; Public: another living, awake person in the same cell within public_radius who could see them. The player and
; the player's party do not count; other people in the conversation do.
bool Function InPublic(Actor akActor)
	float radius = JsonUtil.GetFloatValue(SETTINGS_FILE, "public_radius", PublicRadius)
	if radius <= 0.0
		return false
	endif
	; One native search for the people within the radius (form type 62 = placed actor), usually none to a few.
	ObjectReference[] near = PO3_SKSEFunctions.FindAllReferencesOfFormType(akActor, 62, radius)
	if !near || near.Length == 0
		return false
	endif
	Cell here = akActor.GetParentCell()
	Actor player = Game.GetPlayer()
	; Only people count (ActorTypeNPC), not animals or creatures.
	Keyword npcType = Game.GetFormFromFile(0x013794, "Skyrim.esm") as Keyword
	int i = near.Length
	while i > 0
		i -= 1
		Actor other = near[i] as Actor
		if other && other != akActor && other != player && other.HasKeyword(npcType) && !other.IsDisabled() && !other.IsDead() && !other.IsPlayerTeammate()				&& other.GetSleepState() != 3 && other.GetParentCell() == here
			return true
		endif
	endwhile
	return false
EndFunction

; The spouse's base record comes from the Spouse relationship (one native call; unmarried NPCs stop there). Cell
; scans miss persistent NPCs such as Alvor and Sigrid, so the spouse's reference is found among the loaded actors
; and remembered once found.
Actor Function SpouseOf(Actor akActor)
	Form known = StorageUtil.GetFormValue(akActor, "MantellaOSLA_Spouse")
	if known
		return known as Actor
	endif
	AssociationType spouse = Game.GetFormFromFile(0x0142CA, "Skyrim.esm") as AssociationType
	ActorBase[] partners = PO3_SKSEFunctions.GetRelationships(akActor.GetActorBase(), spouse)
	if !spouse || !partners || partners.Length == 0
		return None
	endif
	Actor[] loaded = PO3_SKSEFunctions.GetActorsByProcessingLevel(0)
	int i = loaded.Length
	while i > 0
		i -= 1
		Actor other = loaded[i]
		if other && other != akActor && partners.Find(other.GetActorBase()) >= 0
			StorageUtil.SetFormValue(akActor, "MantellaOSLA_Spouse", other)
			return other
		endif
	endWhile
	return None
EndFunction

; Open groups, for NPCs whose nature is to be forward with anyone (succubi,
; courtesans). Races by name or form, factions by form, keywords by EditorID or form.
bool Function IsOpen(Actor akActor)
	Race actorRace = akActor.GetRace()
	int i = JsonUtil.StringListCount(SETTINGS_FILE, "open_races")
	while i > 0
		i -= 1
		string entry = JsonUtil.StringListGet(SETTINGS_FILE, "open_races", i)
		if actorRace && (entry == actorRace.GetName() || ResolveForm(entry) == actorRace)
			return true
		endif
	endWhile
	if InListedFaction(akActor, "open_factions")
		return true
	endif
	i = JsonUtil.StringListCount(SETTINGS_FILE, "open_keywords")
	while i > 0
		i -= 1
		string entry = JsonUtil.StringListGet(SETTINGS_FILE, "open_keywords", i)
		Keyword kw = ResolveForm(entry) as Keyword
		if !kw
			kw = Keyword.GetKeyword(entry)
		endif
		if kw && (akActor.HasKeyword(kw) || (actorRace && actorRace.HasKeyword(kw)))
			return true
		endif
	endWhile
	return false
EndFunction

bool Function InListedFaction(Actor akActor, string asList)
	int i = JsonUtil.StringListCount(SETTINGS_FILE, asList)
	while i > 0
		i -= 1
		Faction fac = ResolveForm(JsonUtil.StringListGet(SETTINGS_FILE, asList, i)) as Faction
		if fac && akActor.IsInFaction(fac)
			return true
		endif
	endWhile
	return false
EndFunction

; "0x00C90C|Some Mod.esp" (the plugin's own FormID, written the way PapyrusUtil
; writes forms) -> the form; None when the entry is no form or the plugin is not loaded.
Form Function ResolveForm(string asEntry)
	int bar = StringUtil.Find(asEntry, "|")
	if bar <= 0
		return None
	endif
	string plugin = StringUtil.Substring(asEntry, bar + 1)
	int lightIndex = Game.GetLightModByName(plugin)
	if Game.GetModByName(plugin) == 255 && (lightIndex < 0 || lightIndex >= 4096)
		return None
	endif
	return Game.GetFormFromFile(ParseHex(StringUtil.Substring(asEntry, 0, bar)), plugin)
EndFunction

; "0x00C90C" or "00C90C" -> 51468. Stops at the first character that is not a hex digit.
int Function ParseHex(string asText)
	; Upper and lower case both map to their value, whether Find matches case or not.
	string digits = "0123456789abcdef0123456789ABCDEF"
	int textLength = StringUtil.GetLength(asText)
	int i = 0
	if textLength >= 2 && StringUtil.Substring(asText, 0, 2) == "0x"
		i = 2
	endif
	int value = 0
	while i < textLength
		int digit = StringUtil.Find(digits, StringUtil.GetNthChar(asText, i))
		if digit < 0
			return value
		endif
		value = value * 16 + digit % 16
		i += 1
	endWhile
	return value
EndFunction

; OSL libido is one value shared by every NPC, so it cannot tell NPCs apart.
; The arousal multiplier and the exhibitionist flag are per NPC.
bool Function IsLusty(Actor akActor)
	; The hub's setup can tell Auto to ignore the appetite rating and use OSL values only.
	GlobalVariable source = Game.GetFormFromFile(0x000803, HUB_PLUGIN) as GlobalVariable
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

; Friend or above (vanilla rank 1+), a follower, the Relationships module's close
; status, or engaged/married/lover.
bool Function IsClose(Actor akActor)
	if IsMinor(akActor)
		return false
	endif
	if akActor.GetRelationshipRank(Game.GetPlayer()) >= 1 || akActor.IsPlayerTeammate()
		return true
	endif
	if RelationshipsLoaded() && StorageUtil.GetIntValue(akActor, KEY_RELATIONSHIPS_CLOSE, 0) > 0
		return true
	endif
	return IsIntimate(akActor)
EndFunction

; MRB_Close is only cleared by the Relationships module, so it is trusted only while that module is installed.
bool Function RelationshipsLoaded()
	return Game.GetModByName(RELATIONSHIPS_PLUGIN) != 255 || Game.GetLightModByName(RELATIONSHIPS_PLUGIN) != 65535
EndFunction

; The same test as the Hub's "intimate" action gate: a lover (vanilla Lover rank, M.A.R.A.S engaged, married or
; lover, the Relationships module's dating or closer), an open group off duty, or the player's own "Allow intimacy"
; choice for this NPC (StorageUtil MLW_Intimate = 1, set with the Hub's hotkey). Never a child.
bool Function AllowsIntimacy(Actor akActor)
	if IsMinor(akActor)
		return false
	endif
	if StorageUtil.GetIntValue(akActor, KEY_INTIMATE, 0) == 1 || IsIntimate(akActor)
		return true
	endif
	if RelationshipsLoaded() && StorageUtil.GetIntValue(akActor, KEY_RELATIONSHIPS_CLOSE, 0) > 0
		return true
	endif
	return IsOpen(akActor) && !IsOnDuty(akActor)
EndFunction

; Vanilla Lover rank, or M.A.R.A.S engaged, married or lover.
bool Function IsIntimate(Actor akActor)
	Actor player = Game.GetPlayer()
	if akActor.GetRelationshipRank(player) >= 4
		return true
	endif
	if Game.GetModByName("TT_MARAS.esp") != 255 || Game.GetLightModByName("TT_MARAS.esp") != 65535 ; light plugins: 65535 = not loaded
		return MantellaOSLA_MARAS.IsIntimateStatus(akActor)
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
		; No climaxes to drain: a need raised by a peak that has since ended goes back to the plain rating.
		if StorageUtil.GetFloatValue(akActor, KEY_PEAK_SINCE, 0.0) <= 0.0
			StorageUtil.UnsetFloatValue(akActor, KEY_NEED)
		endif
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

; abCap: story climaxes stop one past the overwhelm limit, so a big number cannot keep her overwhelmed for weeks.
Function AddClimaxes(Actor akActor, int aiCount, bool abCap = false)
	; Climax events for the same NPC can interleave: wait for the other one (at most 5 s).
	int tries = 0
	while _climaxLock && tries < 50
		Utility.Wait(0.1)
		tries += 1
	endWhile
	_climaxLock = true
	float before = GetClimaxes(akActor)
	float count = before + (aiCount as float)
	if abCap
		float cap = (OverwhelmLimit(akActor) + 1) as float
		if before > cap
			count = before
		elseif count > cap
			count = cap
		endif
	endif
	StorageUtil.SetFloatValue(akActor, KEY_CLIMAXES, count)
	StorageUtil.SetFloatValue(akActor, KEY_CLIMAX_TIME, Utility.GetCurrentGameTime())
	_climaxLock = false
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
	; The hub's "Never force-start a scene" (default on): she begs, but leaves it to the player.
	GlobalVariable neverForce = Game.GetFormFromFile(0x000804, HUB_PLUGIN) as GlobalVariable
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

; A stranger's level: a private mood, never aimed at the player. Nothing below noticeably aroused.
string Function PrivateMood(Actor akActor, int band, int aiOldBand)
	string name = akActor.GetDisplayName()
	if band >= 3
		return name + " is in a strongly sensual mood today, a private feeling not about anyone here; " + Pronoun(akActor) + " keeps it to " + Reflexive(akActor) + " and acts as usual."
	elseif band == 2
		return name + " is in a warm, restless mood today, a private feeling not about anyone here; " + Pronoun(akActor) + " keeps it to " + Reflexive(akActor) + "."
	elseif aiOldBand >= 2
		return name + "'s restless mood has passed."
	endif
	return ""
EndFunction

; An NPC's level, phrased by temperament; strangers get a private mood.
string Function DescribeNpc(Actor akActor, int band, int tier, int aiStanding, int aiOldBand)
	string name = akActor.GetDisplayName()
	string p = Pronoun(akActor)
	if aiStanding == STANDING_STRANGER && !IsSatisfied(akActor)
		return PrivateMood(akActor, band, aiOldBand)
	elseif band == 0
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
	if text == "" || MinorInTalk()
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
	Actor[] old = new Actor[10]
	int i = 0
	while i < MaxTracked
		old[i] = _actors[i]
		_actors[i] = None
		_bands[i] = -1
		_tiers[i] = TIER_RESERVED
		_peakLongSent[i] = false
		_rateAsked[i] = false
		_standing[i] = STANDING_STRANGER
		_minors[i] = None
		i += 1
	endWhile
	_playerBand = -1
	; The peak timer counts within one talk; left over, the next talk would see days at 100.
	i = 0
	while i < MaxTracked
		if old[i]
			StorageUtil.UnsetFloatValue(old[i], KEY_PEAK_SINCE)
			StorageUtil.UnsetIntValue(old[i], KEY_PEAK_RAISES)
		endif
		i += 1
	endWhile
EndFunction

; The player's own level goes only to NPCs who know the player well (close or
; open), never to strangers. With strangers in the group it says who notices.
; Waits until someone close is in the conversation.
Function UpdatePlayerLine()
	; Nothing while a child is in the talk; the band is sent once the child has left.
	if MinorInTalk()
		return
	endif
	Actor player = Game.GetPlayer()
	int band = GetBand(player)
	if band == _playerBand
		return
	endif
	int aware = 0
	bool strangers = false
	int i = 0
	while i < MaxTracked
		if _actors[i]
			if _standing[i] == STANDING_STRANGER
				strangers = true
			else
				aware += 1
			endif
		endif
		i += 1
	endWhile
	if aware == 0
		return
	endif
	_playerBand = band
	string line = Describe(player, band)
	if strangers
		string names = ""
		int added = 0
		i = 0
		while i < MaxTracked
			if _actors[i] && _standing[i] != STANDING_STRANGER
				if added > 0
					if added == aware - 1
						names += " and "
					else
						names += ", "
					endif
				endif
				names += _actors[i].GetDisplayName()
				added += 1
			endif
			i += 1
		endWhile
		if aware == 1
			line += " Only " + names + " knows the player well enough to notice."
		else
			line += " Only " + names + " know the player well enough to notice."
		endif
	endif
	SendLine(line)
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
	UpdatePlayerLine()
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
	if IsMinor(npc)
		if _minors.Find(npc) < 0
			bool first = !MinorInTalk()
			int free = _minors.Find(None)
			if free >= 0
				_minors[free] = npc
			endif
			if first
				OnMinorJoined()
			endif
		endif
		StorageUtil.SetIntValue(npc, KEY_IS_CLOSE, STANDING_STRANGER)
		PublishTier(npc, TIER_RESERVED)
		RefreshLivingWorldNpc(npc)
		return
	endif
	int slot = _actors.Find(None)
	if slot < 0
		return
	endif
	_actors[slot] = npc
	_bands[slot] = -1
	; A peak timer left from an earlier talk (or from outside one) starts over with this talk.
	StorageUtil.UnsetFloatValue(npc, KEY_PEAK_SINCE)
	StorageUtil.UnsetIntValue(npc, KEY_PEAK_RAISES)
	_standing[slot] = GetStanding(npc)
	_tiers[slot] = TierFor(npc, _standing[slot])
	PublishTier(npc, _tiers[slot])
	StorageUtil.SetIntValue(npc, KEY_IS_CLOSE, _standing[slot])
	RefreshLivingWorldNpc(npc)
	_peakLongSent[slot] = false
	_rateAsked[slot] = false
	CheckSlot(slot)
	UpdatePlayerLine()
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
	if _minors
		int minorSlot = _minors.Find(npc)
		if minorSlot >= 0
			_minors[minorSlot] = None
			if !MinorInTalk()
				OnLastMinorLeft()
			endif
		endif
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
	if !npc || npc == Game.GetPlayer() || GetAppetite(npc) > 0 || IsMinor(npc)
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
	StorageUtil.FormListAdd(None, KEY_RATED, npc, false)
	if !_actors
		return
	endif
	int slot = _actors.Find(npc)
	if slot >= 0
		_tiers[slot] = TierFor(npc, _standing[slot])
		PublishTier(npc, _tiers[slot])
	endif
EndEvent

; Climaxes the player describes in the story.
Event OnClimaxesAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Actor npc = akSpeaker as Actor
	; Offered only on the "intimate" gate; checked here too for installs without the Hub's action filter.
	if !npc || npc == Game.GetPlayer() || !AllowsIntimacy(npc)
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
	AddClimaxes(npc, count, true)
	RecheckActor(npc, wasOver)
EndEvent

; Climaxes another module counts (OStim Expansion's skipped scenes): form + count pushed with the event.
Event OnAddClimaxesEvent(Form akNpc, int aiCount)
	Actor npc = akNpc as Actor
	if !npc || npc == Game.GetPlayer() || IsMinor(npc) || aiCount <= 0
		return
	endif
	bool wasOver = IsOverwhelmed(npc)
	AddClimaxes(npc, aiCount)
	RecheckActor(npc, wasOver)
EndEvent

; Real OStim climaxes, for any NPC, in or out of a conversation.
Event OnOStimOrgasm(string asEventName, string asSceneID, float afThreadID, Form akSender)
	Actor npc = akSender as Actor
	if !npc || npc == Game.GetPlayer() || IsMinor(npc)
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

; The Integration Hub rewrites this NPC's file for Mantella's side (how close they are), now that it is known.
Function RefreshLivingWorldNpc(Actor npc)
	int handle = ModEvent.Create("MLW_RefreshNpc")
	if handle
		ModEvent.PushForm(handle, npc)
		ModEvent.Send(handle)
	endif
EndFunction

; Changes the speaker's arousal and reports a level change right away instead of at the next check. Only an NPC
; who passes the "intimate" gate has their arousal raised by an action: the Become Aroused action is only offered to
; them, so any other raise came from a stray "Aroused:" in the text or a model that named a hidden action (and with
; the Hub's action filter off, nothing else stops it).
Function ShiftArousal(Actor npc, float amount)
	if !npc || npc == Game.GetPlayer() || IsMinor(npc)
		return
	endif
	if amount > 0.0 && !AllowsIntimacy(npc)
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
; level changed or the peak timer ran out. Asks NPCs who are not strangers for a
; rating once they are aroused; a stranger's appetite is none of the conversation's business.
Function CheckSlot(int slot)
	Actor npc = _actors[slot]
	bool stranger = _standing[slot] == STANDING_STRANGER
	string line = UpdateSatisfied(npc)
	int band = GetBand(npc)
	UpdatePeak(npc, band)
	ApplyPeakRaises(npc)
	; With a child in the talk only the counts are kept up; the level is described once the child has left.
	if MinorInTalk()
		return
	endif
	if line != ""
		_bands[slot] = band
	elseif band != _bands[slot]
		int oldBand = _bands[slot]
		_bands[slot] = band
		line = DescribeNpc(npc, band, _tiers[slot], _standing[slot], oldBand)
		if line != "" && !stranger && band >= 2 && GetAppetite(npc) > 0 && !IsSatisfied(npc)
			line += ProgressText(npc)
		endif
	endif
	string peakLine = PeakLongLine(slot)
	if peakLine != ""
		line = peakLine
	endif
	SendLine(line)
	if !stranger && band >= 2 && !_rateAsked[slot] && GetAppetite(npc) <= 0
		_rateAsked[slot] = true
		SendLine(npc.GetDisplayName() + "'s sexual appetite has not been rated yet.")
	endif
EndFunction

Event OnUpdate()
	if !_inConversation
		return
	endif
	; the Ended event can be missed: no running talk means it is over
	Quest talk = Game.GetFormFromFile(0x03D41A, "Mantella.esp") as Quest
	if talk && !talk.IsRunning()
		_inConversation = false
		ClearTracked()
		return
	endif
	UpdatePlayerLine()
	int i = 0
	while i < MaxTracked
		if _actors[i]
			CheckSlot(i)
		endif
		i += 1
	endWhile
	RegisterForSingleUpdate(CheckInterval)
EndEvent
