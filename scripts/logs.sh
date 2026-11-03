#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_common.sh"
case "${1:-both}" in
  lt) exec tail -n 100 -f "$LOG_ROOT/livetalking.log";;
  ls) exec tail -n 100 -f "$LOG_ROOT/livestream.log";;
  both) exec tail -n 60 -f "$LOG_ROOT/livetalking.log" "$LOG_ROOT/livestream.log";;
  *) echo '使用：bash scripts/logs.sh [lt|ls|both]' >&2; exit 2;;
esac
