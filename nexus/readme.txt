Mantella Living World - Arousal
Version 1.0.0 by itsPigeon2000

Tells Mantella how aroused NPCs are, using OSL Aroused, so they act on it in their own way: reserved, bold or forward. Each NPC gets an appetite, and Mantella knows when she is satisfied or overwhelmed.

Requirements
- Mantella Living World - Integration Hub (run its setup once)
- Mantella 0.14, with Advanced Actions turned on and an LLM that supports tool calling. Without it nobody gets an appetite rating, so no one becomes satisfied or overwhelmed
- OSL Aroused
- powerofthree's Papyrus Extender
- SKSE64 and PapyrusUtil SE
- Optional: OStim or OStim NG (counts real scene climaxes), M.A.R.A.S and Lover's Ledger (engaged or married counts as close)

Installation
1. Install the hub, then this module.

Notes
- Arousal is sent in bands, for the NPCs in the conversation. Your own level is sent to NPCs close to you.
- Climaxes come from real OStim scenes (any NPC, drained over game time) and from the AddClimaxes action. Satisfied sets the NPC's OSL arousal to 0.
- Actions BecomeAroused, CoolDown, RateAppetite and AddClimaxes are only offered to NPCs close to you, and only when the Hub's "Fitting actions only" filter is on.
- Temperament set with the Hub's hotkey cannot beat on-duty or spouse-nearby reserved. At peak, a forward NPC begs; with the Hub's "Never force-start a scene" off she insists.
- Settings file: SKSE\Plugins\StorageUtilData\MantellaOSLA\settings.json. Lists: forward, reserved, open_races, open_factions, open_keywords (forms as 0xFORMID|plugin.esp), duty_factions. Numbers: lusty_appetite, overwhelm_ratio, recovery_days, peak_minutes, peak_raise. "appetite_<Name>": n under int sets one NPC's appetite.

Credits
- Mantella by Art from the Machine and contributors (AGPL-3.0)
- SKSE team
- PapyrusUtil SE by exiledviper and meh321
- OSL Aroused by ozooma10
- M.A.R.A.S and Lover's Ledger by TangyTweaks

License
GNU Affero General Public License v3.0 (see LICENSE.txt). Script sources are included in Scripts\Source.
Source code: https://github.com/Abhisek571/Mantella-Living-World-Arousal
