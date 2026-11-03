#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_common.sh"
need tmux
for s in dh_livestream dh_livetalking; do
  if tmux has-session -t "$s" 2>/dev/null; then tmux kill-session -t "$s"; echo "[STOP] $s"; else echo "[SKIP] $s 不在运行"; fi
done
