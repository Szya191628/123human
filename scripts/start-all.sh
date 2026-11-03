#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_common.sh"
need tmux
# tmux 保留服务会话；单个进程异常退出时不会冒险无限重试（请先检查日志）
for entry in "livetalking:start-livetalking.sh" "livestream:start-livestream.sh"; do
  session="dh_${entry%%:*}"
  script="${entry#*:}"
  if tmux has-session -t "$session" 2>/dev/null; then
    echo "[SKIP] $session 已运行，查看日志：tmux attach -t $session"
  else
    tmux new-session -d -s "$session" "bash '$KIT_ROOT/scripts/$script' 2>&1 | tee -a '$LOG_ROOT/${entry%%:*}.log'"
    echo "[OK] 已建立会话 $session"
  fi
done
echo "打开：$LIVETALKING_URL/index.html 和 $LIVESTREAM_URL"
echo "启动前请先运行 python3 scripts/doctor.py，且需手动连接 LiveTalking WebRTC Session。"
