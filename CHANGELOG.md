# Changelog

Every change to Mantella Living World - Arousal. The Nexus page lists only the main changes for each version.

## 1.1.1 (2026-11-18)

### Changed
- The Become Aroused and climax actions follow the Integration Hub's Intimacy setting and each NPC's choice when the Hub is installed: NPC decides lets every adult use them, Intimacy: never shuts them, Always willing and an absolute command open them. Lovers only, or no Hub, keeps the old check. Children never get them.
- Shorter descriptions for all four actions (less text sent to the model on every reply; same rules).
- Satisfied now lasts about a day, longer for low-appetite NPCs and shorter for high-appetite ones.
- No more "seems calm" lines at the start of every talk; a line is sent only when someone has calmed down. Without OSL Aroused installed the module stays idle.

### Fixed
- A stranger's satisfied or overwhelmed state is never sent to the talk.
- The appetite rating and the other silent actions now say plainly that nothing about them may be spoken (an NPC said "I'm rating her appetite quietly" aloud).
- People from a talk whose end was missed no longer get arousal lines in the next talk, and a child left over from it no longer mutes every line.
- The duty and open faction lists are read once instead of on every check; the Integration Hub is asked to update an NPC only when the standing changed.
- Setting the game clock back no longer raises an NPC's climax count or peak timer; recovery starts over from the new time.
- A married NPC whose spouse is not nearby no longer makes every check search all loaded people; the search waits one game hour before trying again.
- A duty or open faction from a mod installed mid-playthrough is picked up instead of staying missing.
- An NPC joining a talk is worked out once instead of twice.

## 1.1.0 (2026-11-09)

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
