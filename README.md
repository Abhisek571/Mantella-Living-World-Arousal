# Mantella Living World - Arousal

Tells Mantella how aroused NPCs are, so they act on it in their own way. A module of [Mantella Living World - Integration Hub](https://github.com/Abhisek571/Mantella-Living-World-Hub).

| Feature | What it does |
|---|---|
| Arousal | Each NPC's level from OSL Aroused is sent in bands as it changes, for the NPCs in the conversation. Your own level is sent to NPCs close to you. Aroused lines can also show how many times she has climaxed |
| Temperament | Reserved, bold or forward, from the Hub's setting or worked out from lust and closeness. Bold lets it show and, at peak, asks you directly but accepts no. Forward says it openly and, at peak, begs. With the Hub's "Never force-start a scene" off, she insists instead |
| Appetite | Mantella rates each NPC's appetite once, from her bio. Climaxes are counted against it: satisfied sets her OSL arousal to 0, far past it she is overwhelmed and asks to rest. NPCs that are not rated yet never become satisfied or overwhelmed |
| Climax counting | Real OStim scenes count for any NPC, in a conversation or not. The count drains over game time. Story climaxes can be added by the AddClimaxes action |
| Closeness | Strangers keep it private; friends, lovers, followers and open groups (courtesans, succubus races) can show interest. On-duty guards and a spouse nearby keep NPCs reserved. Engaged or married (M.A.R.A.S) counts as close |
| Actions | BecomeAroused (+10 arousal), CoolDown (-10 arousal), RateAppetite and AddClimaxes. All are only offered to NPCs close to you, and only when the Hub's "Fitting actions only" filter is on |

Requires:
- [Mantella Living World - Integration Hub](https://github.com/Abhisek571/Mantella-Living-World-Hub), with its setup run once (default temperament)
- [Mantella](https://www.nexusmods.com/skyrimspecialedition/mods/98631) 0.14, with Advanced Actions turned on (Mantella's Actions settings) and an LLM that supports tool calling. Without it RateAppetite and AddClimaxes do not work, so nobody gets rated or satisfied
- [OSL Aroused](https://www.nexusmods.com/skyrimspecialedition/mods/65454)
- [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854)
- SKSE64 and PapyrusUtil SE
- Optional: OStim or OStim NG (counts real scene climaxes), M.A.R.A.S and Lover's Ledger by TangyTweaks (engaged or married counts as close)

Settings: `SKSE/Plugins/StorageUtilData/MantellaOSLA/settings.json`. Lists: `forward` and `reserved` (NPC names), `open_races`, `open_factions`, `open_keywords` (forms written as `0xFORMID|plugin.esp`) and `duty_factions`. Numbers: `lusty_appetite`, `overwhelm_ratio`, `recovery_days`, `peak_minutes`, `peak_raise`. Set one NPC's appetite yourself with `"appetite_<Name>": n` under `int` (name as shown in game); it replaces the rating.

Build: the Hub's `tools/build.py --only arousal`. In-game tests: `bash test/run-tests.sh` (DevBench).

License: GNU AGPL-3.0.
