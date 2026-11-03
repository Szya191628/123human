#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_common.sh"
need conda
project="$LIVESTREAM_SOURCE_DIR/backend"
[[ -f "$project/app/main.py" ]] || { echo "未找到 LiveStream 后端；先运行 bash scripts/install.sh" >&2; exit 1; }
mkdir -p "$project/data"
cd "$project"
export APP_HOST=127.0.0.1 APP_PORT="$LS_PORT"
# 绕开上游 main.py 内的 reload=True：减少后台运行出现的重复进程。
# 同时将后端绑定在回环接口，避免直接暴露无登录的后台。
printf '[LiveStream] %s，LiveTalking 地址请在后台系统配置中设置：%s\n' "$LIVESTREAM_URL" "$LIVETALKING_URL"
exec conda run --no-capture-output -n livestream python -m uvicorn app.main:app --host 127.0.0.1 --port "$LS_PORT"
