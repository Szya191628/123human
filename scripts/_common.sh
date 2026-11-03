#!/usr/bin/env bash
set -euo pipefail
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
WORK_ROOT="$KIT_ROOT/workspace"
LOG_ROOT="$KIT_ROOT/logs"
mkdir -p "$LOG_ROOT"
if [[ -f "$KIT_ROOT/config/settings.env" ]]; then
  # settings.env 为受信任的本机脚本配置，使用 shell 赋值语法
  set -a
  # shellcheck disable=SC1091
  source "$KIT_ROOT/config/settings.env"
  set +a
fi
if [[ -z "${LIVESTREAM_SOURCE_DIR:-}" ]]; then
  LIVESTREAM_SOURCE_DIR="$WORK_ROOT/LiveStream"
  if [[ -f /mnt/d/360download/LiveStream/backend/app/main.py && -f /mnt/d/360download/LiveStream/frontend/package.json ]]; then
    LIVESTREAM_SOURCE_DIR=/mnt/d/360download/LiveStream
  fi
fi
: "${MODEL:=wav2lip}"
: "${AVATAR_ID:=wav2lip256_avatar1}"
: "${TRANSPORT:=webrtc}"
: "${LIVETALKING_URL:=http://127.0.0.1:8010}"
: "${LIVESTREAM_URL:=http://127.0.0.1:8020}"
: "${LT_PORT:=8010}"
: "${LS_PORT:=8020}"
: "${PYTORCH_VERSION:=2.9.1}"
: "${TORCHVISION_VERSION:=0.24.1}"
: "${TORCHAUDIO_VERSION:=2.9.1}"
: "${PYTORCH_INDEX_URL:=https://download.pytorch.org/whl/cu128}"
: "${LT_EXTRA_ARGS:=}"
need() { command -v "$1" >/dev/null || { echo "缺少命令: $1" >&2; exit 1; }; }
ensure_loopback() { case "$1" in http://127.0.0.1:*|http://localhost:*|http://\[::1\]:*) ;; *) echo "为安全起见，只支持本机 URL: $1" >&2; exit 1;; esac; }
