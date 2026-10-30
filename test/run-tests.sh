#!/usr/bin/env bash
# Drives the temperament tests over DevBench (game running, test build + MantellaOSLA_TEST.esp loaded, player in
# Riverwood in daytime), then prints PASS/FAIL per check. The conversation is faked by the test harness.
# usage: bash run-tests.sh [stranger ref] [married ref] [their spouse ref] [guard ref]
#        defaults: Faendal 0x1348C, Alvor 0x13482, Sigrid 0x13483, no guard (guard check skipped)
set -u
MO2=${MO2:?set MO2 to your Mod Organizer 2 instance folder}
S=${1:-0x1348C}; M=${2:-0x13482}; W=${3:-0x13483}; G=${4:-}
SF="{\"form\":\"$S\"}"; MF="{\"form\":\"$M\"}"; P='{"form":"0x14"}'
PASS=0; FAIL=0

call() { bash "$MO2/tools/devbench-cli.sh" call "$@" 2>&1 | py -3 -I -c "import json,sys
try:
    d=json.load(sys.stdin); print(d.get('returned') if d.get('called') else 'ERROR '+str(d))
except Exception: print('ERROR no reply')"; }
t() { call MantellaOSLA_Test "$1" "${2:-[]}"; }
con() { bash "$MO2/tools/devbench-cli.sh" exec "$1" >/dev/null 2>&1; }
note() { bash "$MO2/tools/devbench-cli.sh" notify "$1" >/dev/null 2>&1; echo "== $1"; }
check() {  # check <label> <text> <must match regex> [<must not match regex>]
  local ok=1
  echo "$2" | grep -qiE "$3" || ok=0
  [ -n "${4:-}" ] && echo "$2" | grep -qiE "$4" && ok=0
  if [ $ok = 1 ]; then PASS=$((PASS + 1)); echo "   PASS $1"; else FAIL=$((FAIL + 1)); echo "   FAIL $1: $2"; fi
}
talk() {  # talk <actor json> [<second actor json>]: fresh fake conversation, returns the event log
  t Finish >/dev/null; sleep 1; t Begin >/dev/null; sleep 1
  t Join "[$1]" >/dev/null; sleep 2
  [ -n "${2:-}" ] && { t Join "[$2]" >/dev/null; sleep 2; }
  t Log
}
reset() {  # reset <actor json>: no override, duty judged, unrated, not open
  t SetOverride "[$1,0]" >/dev/null; t SetDuty "[$1,0]" >/dev/null; t SetAppetite "[$1,0]" >/dev/null
  t SetOpen "[$1,false]" >/dev/null
}
rank_of() { t Status "[$1]" | grep -oE 'rank=-?[0-9]+' | cut -d= -f2; }

con "set GameHour to 12"
RS=$(rank_of "$SF"); RM=$(rank_of "$MF")
echo "saved ranks: stranger=$RS married=$RM"
reset "$SF"; reset "$MF"
t SetArousal "[$P,90.0]" >/dev/null   # the player is intensely aroused throughout
t SetPublicRadius "[0.0]" >/dev/null   # tests 1-6 ignore bystanders; test 7 checks them

note "1/8 stranger at arousal 85: private mood, no player line, no rating request"
t SetRank "[$SF,0]" >/dev/null; t SetArousal "[$SF,85.0]" >/dev/null
LOG=$(talk "$SF")
check "mood line is private" "$LOG" 'private feeling'
check "nothing about the player" "$LOG" '.' 'player|not been rated'
check "standing stranger, reserved, MLW_IsClose 0" "$(t Status "[$SF]")" 'tier=0 standing=0 isClose=0'

note "2/8 friend (rank 1, lusty appetite): bold, player line, no rating request (rated)"
t SetRank "[$SF,1]" >/dev/null; t SetAppetite "[$SF,20]" >/dev/null
LOG=$(talk "$SF")
check "bold line" "$LOG" 'actively trying to get the player into bed|doesn.t hide it|asks the player directly'
check "player line, nobody excluded" "$LOG" 'is intensely aroused\.' 'Only .* notice'
check "standing close, bold, MLW_IsClose 1" "$(t Status "[$SF]")" 'tier=1 standing=1 isClose=1'

note "3/8 group of a stranger and a friend: player line names only the friend"
t SetRank "[$MF,0]" >/dev/null; t SetArousal "[$MF,85.0]" >/dev/null
LOG=$(talk "$MF" "$SF")
check "only the friend notices" "$LOG" 'Only [^|]* knows the player well enough to notice'
check "stranger gets no rating request" "$LOG" '.' 'appetite has not been rated'

note "4/8 on duty: the friend is reserved"
t SetDuty "[$SF,1]" >/dev/null
check "on-duty friend reserved" "$(t Status "[$SF]")" 'tier=0 standing=1 .*duty=true'
t SetDuty "[$SF,0]" >/dev/null
if [ -n "$G" ]; then
  GF="{\"form\":\"$G\"}"
  t SetOverride "[$GF,3]" >/dev/null
  check "real guard reserved even with forward override" "$(t Status "[$GF]")" 'tier=0 .*duty=true'
  t SetOverride "[$GF,0]" >/dev/null
fi

note "5/8 spouse nearby: forward override, still reserved"
con "player.moveto ${M#0x}"; sleep 2
call ObjectReference MoveTo "[$MF,80.0,0.0,0.0,true]" "{\"form\":\"$W\"}" >/dev/null; sleep 2   # the console form "<ref>.moveto" does nothing over DevBench
t SetOverride "[$MF,3]" >/dev/null
t Status "[$MF]" >/dev/null; sleep 6   # the first look-up of a partner scans every loaded actor (slow, once)
check "spouse nearby reserved" "$(t Status "[$MF]")" 'tier=0 standing=1 .*spouse=true'
t SetOverride "[$MF,0]" >/dev/null
con "player.moveto ${S#0x}"; sleep 2

note "6/8 open faction stranger: forward and rated; on duty: reserved and private"
t SetRank "[$SF,0]" >/dev/null; t SetAppetite "[$SF,0]" >/dev/null; t SetOpen "[$SF,true]" >/dev/null
t SetArousal "[$SF,85.0]" >/dev/null
LOG=$(talk "$SF")
check "forward line" "$LOG" 'actively trying to get the player into bed|asks the player directly'
check "open NPC gets the rating request" "$LOG" 'appetite has not been rated'
check "standing open, forward, MLW_IsClose 2" "$(t Status "[$SF]")" 'tier=2 standing=2 isClose=2 .*open=true'
t SetDuty "[$SF,1]" >/dev/null
LOG=$(talk "$SF")
check "open but on duty: private mood" "$LOG" 'private feeling' 'player|not been rated'
check "open but on duty: stranger, reserved" "$(t Status "[$SF]")" 'tier=0 standing=0 isClose=0'

note "7/8 public: a friend with someone else close by is reserved; alone again, bold"
t SetOpen "[$SF,false]" >/dev/null; t SetDuty "[$SF,0]" >/dev/null
t SetRank "[$SF,1]" >/dev/null; t SetAppetite "[$SF,20]" >/dev/null
t SetPublicRadius "[1024.0]" >/dev/null
call ObjectReference MoveTo "[$SF,200.0,0.0,0.0,true]" "$P" >/dev/null; sleep 4   # the check only sees loaded cells: the player must be there
call ObjectReference MoveTo "[$MF,90.0,0.0,0.0,true]" "$SF" >/dev/null; sleep 2   # a bystander right next to the friend
check "friend in public: reserved" "$(t Status "[$SF]")" 'tier=0 standing=1 .*public=true'
t SetPublicRadius "[0.0]" >/dev/null
check "same friend, public check off: bold" "$(t Status "[$SF]")" 'tier=1 standing=1 .*public=false'

note "8/8 Dibella's temple is an open group by default"
call Actor AddToFaction '[{"form":"0x0656EA"}]' "$SF" >/dev/null
t SetRank "[$SF,0]" >/dev/null
check "temple member stranger: open" "$(t Status "[$SF]")" 'standing=2 .*open=true'
call Actor RemoveFromFaction '[{"form":"0x0656EA"}]' "$SF" >/dev/null

note "cleanup"
t SetPublicRadius "[1024.0]" >/dev/null
t Finish >/dev/null
reset "$SF"; reset "$MF"
t SetRank "[$SF,${RS:-0}]" >/dev/null; t SetRank "[$MF,${RM:-0}]" >/dev/null
t SetArousal "[$SF,0.0]" >/dev/null; t SetArousal "[$MF,0.0]" >/dev/null; t SetArousal "[$P,0.0]" >/dev/null
note "tests finished: $PASS passed, $FAIL failed"
[ $FAIL = 0 ]
