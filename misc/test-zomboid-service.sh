#!/usr/bin/env bash
#
# Automated verification for the Project Zomboid systemd service
# (see misc/zomboid.service and the "Auto-start on boot" section of the README).
#
# It proves the four things that actually matter:
#   1. the unit is valid and the server reaches "SERVER STARTED";
#   2. the interactive console is still reachable with "screen -r";
#   3. "systemctl stop" saves the world and exits gracefully, with no SIGKILL;
#   4. the saved world is picked up again on the next start.
#
# It also checks crash recovery and that the unit is enabled for boot.
#
# Run as root, on a server with NO players connected. It stops and starts the
# service several times.
#
#   sudo ./test-zomboid-service.sh
#   sudo SERVICE=zomboid SERVERNAME=myserver ./test-zomboid-service.sh
#
set -uo pipefail

SERVICE=${SERVICE:-zomboid}
STEAM_HOME=${STEAM_HOME:-/home/steam}
CONSOLE_LOG=${CONSOLE_LOG:-$STEAM_HOME/Zomboid/server-console.txt}
START_TIMEOUT=${START_TIMEOUT:-600}
STOP_TIMEOUT=${STOP_TIMEOUT:-330}

pass=0
fail=0

ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; pass=$((pass + 1)); }
no()   { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail + 1)); }
step() { printf '\n\033[1m%s\033[0m\n' "$1"; }
info() { printf '       %s\n' "$1"; }

[[ $EUID -eq 0 ]] || { echo "run this as root"; exit 2; }

# PZ truncates server-console.txt on every start, so a stale offset can point
# past the end of a fresh log.
log_size()  { [[ -f $CONSOLE_LOG ]] && stat -c %s "$CONSOLE_LOG" || echo 0; }
log_since() {
  local from=$1
  [[ -f $CONSOLE_LOG ]] || return 0
  tail -c "+$((from + 1))" "$CONSOLE_LOG" 2>/dev/null | tr -d '\r'
}

# Waits for a regex to appear in the console log written after $offset.
# If the file shrinks below the offset the server restarted and truncated it,
# so the offset is dropped to 0 permanently for this wait. The reset has to
# latch: once the fresh log grows past the old offset again, a non-latching
# check would go back to skipping the very lines we are waiting for.
# The offset that actually matched is published in LOG_OFFSET_USED so the
# caller can read the same slice of the log without repeating the guesswork.
LOG_OFFSET_USED=0
wait_for_log() {
  local regex=$1 offset=$2 timeout=$3 waited=0
  while (( waited < timeout )); do
    (( $(log_size) < offset )) && offset=0
    LOG_OFFSET_USED=$offset
    log_since "$offset" | grep -qE "$regex" && return 0
    sleep 3
    waited=$((waited + 3))
  done
  return 1
}

wait_until_inactive() {
  local timeout=$1 waited=0
  while (( waited < timeout )); do
    systemctl is-active --quiet "$SERVICE" || return 0
    sleep 2
    waited=$((waited + 2))
  done
  return 1
}

start_and_wait() {
  local offset
  offset=$(log_size)
  systemctl start "$SERVICE" || return 1
  wait_for_log 'SERVER STARTED' "$offset" "$START_TIMEOUT"
}

printf '\033[1mProject Zomboid systemd service test\033[0m\n'
info "service: $SERVICE"
info "console log: $CONSOLE_LOG"

step '1. Unit file is valid'
if systemd-analyze verify "/etc/systemd/system/$SERVICE.service" 2>&1 | grep -q .; then
  no 'systemd-analyze verify reported problems'
  systemd-analyze verify "/etc/systemd/system/$SERVICE.service" 2>&1 | sed 's/^/       /'
else
  ok 'systemd-analyze verify is clean'
fi

# ExecStop must carry a REAL newline, otherwise the console never receives the
# "quit" command and the server is eventually killed instead of saving.
if systemctl show "$SERVICE" -p ExecStop | grep -qz 'stuff quit'$'\n'; then
  ok 'ExecStop sends "quit" followed by a real newline'
else
  no 'ExecStop newline escape did not survive unit parsing'
fi

step '2. Service starts and the server becomes ready'
systemctl stop "$SERVICE" 2>/dev/null
wait_until_inactive 60 || info 'service was slow to stop before the test'
start_offset=$(log_size)
if start_and_wait; then
  ok 'server reached "SERVER STARTED"'
else
  no "server did not reach \"SERVER STARTED\" within ${START_TIMEOUT}s"
  info 'aborting: the remaining tests need a running server'
  exit 1
fi

[[ $(systemctl show "$SERVICE" -p ActiveState --value) == active ]] \
  && ok 'ActiveState=active' || no 'service is not active'

main_pid=$(systemctl show "$SERVICE" -p MainPID --value)
[[ -n $main_pid && $main_pid != 0 ]] \
  && ok "MainPID is set ($main_pid)" || no 'MainPID is 0, systemd is not tracking the process'

step '3. Game ports are listening'
for port in 16261 16262; do
  ss -ulnp 2>/dev/null | grep -q ":$port " \
    && ok "UDP $port is listening" || no "UDP $port is NOT listening"
done

step '4. The interactive console survived'
if runuser -u steam -- screen -ls 2>/dev/null | grep -q '\.zomboid'; then
  ok 'screen session "zomboid" exists (screen -r zomboid works)'
else
  no 'no "zomboid" screen session, the console was lost'
fi

step '5. systemctl stop saves the world and exits gracefully'
stop_offset=$(log_size)
stop_started=$(date +%s)
stop_since=$(date '+%Y-%m-%d %H:%M:%S')
systemctl stop "$SERVICE"
stop_elapsed=$(( $(date +%s) - stop_started ))

if wait_until_inactive 30; then
  ok "service stopped in ${stop_elapsed}s (limit ${STOP_TIMEOUT}s)"
else
  no 'service was still active after the stop returned'
fi

stop_log=$(log_since "$stop_offset")
grep -qE 'Saving finish|Saving took' <<<"$stop_log" \
  && ok 'world save ran during shutdown' || no 'no save recorded during shutdown'
grep -q 'Shutdown handling finished' <<<"$stop_log" \
  && ok 'clean "Shutdown handling finished"' || no 'server did not finish its shutdown sequence'

# If the quit never arrived, systemd falls back to signals. That is the exact
# failure this whole design exists to prevent, so it is a hard FAIL.
stop_journal=$(journalctl -u "$SERVICE" --since "$stop_since" --no-pager 2>/dev/null)
if grep -qiE 'Killing process|signal=KILL|state .stop-sigterm.' <<<"$stop_journal"; then
  no 'systemd had to signal the process, the world may not have saved'
else
  ok 'no SIGKILL fallback in the journal'
fi

# ExecStop must BLOCK until the save is done. If it only injects "quit" and
# returns, systemd thinks the stop is over and signals the server mid-save,
# which shows up as a failed final state.
final_state=$(systemctl show "$SERVICE" -p ActiveState --value)
if [[ $final_state == failed ]]; then
  no 'service ended in the failed state'
elif grep -q 'Failed with result' <<<"$stop_journal"; then
  no 'systemd recorded a failed stop, ExecStop did not wait for the save'
else
  ok "service ended cleanly (ActiveState=$final_state)"
fi

step '6. The saved world is reused on the next start'
if start_and_wait; then
  ok 'server started again'
  restart_log=$(log_since "$LOG_OFFSET_USED")
  if grep -q 'map_t.bin does not exist' <<<"$restart_log"; then
    no 'server treated the world as brand new, the save did not persist'
  elif grep -q 'checking server WorldVersion in map_t.bin' <<<"$restart_log"; then
    ok 'existing world was loaded from disk'
  else
    no 'could not confirm which world the server loaded'
  fi
else
  no 'server failed to start after the graceful stop'
fi

step '7. Crash recovery (Restart=always)'
game_pid=$(pgrep -u steam -f 'ProjectZomboid64' | head -1)
if [[ -z $game_pid ]]; then
  no 'could not find the game process to kill'
else
  crash_offset=$(log_size)
  kill -9 "$game_pid"
  info "sent SIGKILL to $game_pid, waiting for systemd to restart it"
  if wait_for_log 'SERVER STARTED' "$crash_offset" "$START_TIMEOUT"; then
    ok 'systemd brought the server back after a crash'
  else
    no 'server did not come back after the crash'
  fi
fi

step '8. Enabled for boot'
if systemctl is-enabled --quiet "$SERVICE"; then
  ok 'service is enabled (will start at boot)'
else
  no 'service is NOT enabled, run: systemctl enable '"$SERVICE"
fi

printf '\n\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
(( fail == 0 )) || exit 1
