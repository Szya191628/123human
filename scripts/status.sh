#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_common.sh"
need tmux
for s in dh_livetalking dh_livestream; do
  if tmux has-session -t "$s" 2>/dev/null; then
    echo "[RUNNING?] tmux 会话: $s（需结合 HTTP 检查实际健康）"
  else echo "[STOPPED] tmux 会话: $s"; fi
done
python3 "$KIT_ROOT/scripts/doctor.py" --live
