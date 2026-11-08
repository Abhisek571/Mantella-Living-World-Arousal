Scriptname MantellaOSLA_MARAS Hidden
{Optional M.A.R.A.S check, kept in its own script so the bridge itself never
names M.A.R.A.S. Only called when TT_MARAS.esp is loaded.}

; True when M.A.R.A.S has the NPC engaged (1), married (2) or, in M.A.R.A.S 2.x, lover (6) to the player.
bool Function IsIntimateStatus(Actor akActor) Global
	int status = MARAS.GetNpcStatusEnum(akActor)
	Return status == 1 || status == 2 || status == 6
EndFunction
