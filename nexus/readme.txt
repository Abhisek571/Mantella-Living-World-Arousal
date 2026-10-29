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

Before you start
1. Mantella 0.14: install it and check that a normal conversation works.
2. Mantella - Direct AI Connect: install it below Mantella in MO2 and run its Setup Backend.cmd once (needs Python 3.11). Without it the stock Mantella.exe runs and Living World does nothing.
3. Mantella Living World - Integration Hub, then the modules you want.
4. API key: your LLM service's key stays in GPT_SECRET_KEY.txt in the Mantella mod folder (in MO2, right-click Mantella, Open in Explorer). A key for another service goes in the file named on the Direct AI Connect page, next to it.
5. Open Mantella's settings page (http://localhost:4999/ui in your browser, only while Mantella is running), go to the Actions tab and turn on Advanced Actions. Many Living World actions (bribe, persuade, marriage steps, positions, map marks and others) only work with it, and it needs a model that supports tool calling.
6. Nothing happens? Living World Main Status in Mantella's settings page lists what is missing.

Installation
1. Install the hub, then this module.

Notes
- Arousal is sent in bands, for the NPCs in the conversation. Your own level is sent to NPCs close to you.
- Climaxes come from real OStim scenes (any NPC, drained over game time) and from the AddClimaxes action. Satisfied sets the NPC's OSL arousal to 0.
- Actions BecomeAroused, CoolDown, RateAppetite and AddClimaxes are offered only to NPCs close to you while the Hub's "Offer only fitting actions" is on (the default); with it off, to everyone.
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
