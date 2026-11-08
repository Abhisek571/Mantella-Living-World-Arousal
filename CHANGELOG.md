# Changelog

Every change to Mantella Living World - Arousal. The Nexus page lists only the main changes for each version.

## Unreleased

### New
- Debug menu support (Integration Hub's MCM page): set an NPC's arousal and reset it to the value from before.
- The Become Aroused and climax actions now need the "intimate" check: a lover, close in Relationships, an open arousal group, or the player's own Allow intimacy choice.
- No arousal lines while a child is in the conversation.

### Fixed
- Arousal set by this mod (raises, the debug menu, the reset when an NPC is satisfied) could read back far off, even below zero, under OSL Aroused's default OSL mode, most of all after the game clock was set back. The value is now brought up to date before it is changed.
- The appetite rating request made the NPC say out loud that they were rating the appetite; they now rate it silently and answer in character.
- Checks only run when the mods they need are loaded.

## 1.0.1 (2026-11-03)
- Keeps a list of rated NPCs for the setup summary in Integration Hub 1.1.6.

## 1.0.0 (2026-10-30)
- First release. Requires Mantella Living World - Integration Hub and OSL Aroused.
