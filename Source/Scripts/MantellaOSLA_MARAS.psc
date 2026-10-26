Scriptname MantellaOSLA_MARAS Hidden
{Optional M.A.R.A.S check, kept in its own script so the bridge itself never
names M.A.R.A.S. Only called when TT_MARAS.esp is loaded.}

; True when M.A.R.A.S has the NPC engaged (1) or married (2) to the player.
bool Function IsEngagedOrMarried(Actor akActor) Global
	int status = MARAS.GetNpcStatusEnum(akActor)
	Return status == 1 || status == 2
EndFunction
