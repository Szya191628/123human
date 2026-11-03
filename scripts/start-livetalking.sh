#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_common.sh"
need conda
project="$WORK_ROOT/LiveTalking"
[[ -f "$project/app.py" ]] || { echo "未找到 LiveTalking；先运行 bash scripts/install.sh" >&2; exit 1; }
[[ "$MODEL" == "wav2lip" || "$MODEL" == "musetalk" || "$MODEL" == "ultralight" ]] || { echo "不支持的模型: $MODEL" >&2; exit 1; }
[[ "$TRANSPORT" == "webrtc" || "$TRANSPORT" == "virtualcam" || "$TRANSPORT" == "rtmp" || "$TRANSPORT" == "rtcpush" ]] || { echo "不支持的传输模式: $TRANSPORT" >&2; exit 1; }
if [[ "$MODEL" == wav2lip ]]; then
  [[ -s "$project/models/wav2lip.pth" ]] || { echo "模型权重缺失：$project/models/wav2lip.pth" >&2; exit 1; }
fi
[[ -d "$project/data/avatars/$AVATAR_ID" ]] || { echo "Avatar 数据缺失：$project/data/avatars/$AVATAR_ID" >&2; exit 1; }
cd "$project"
cmd=(conda run --no-capture-output -n livetalking python app.py --transport "$TRANSPORT" --model "$MODEL" --avatar_id "$AVATAR_ID" --listenport "$LT_PORT")
if [[ -n "$LT_EXTRA_ARGS" ]]; then
  # 支持空格分隔的单值参数；包含空格的值请直接修改此脚本或通过上游 YAML 配置。
  read -r -a more <<< "$LT_EXTRA_ARGS"
  cmd+=("${more[@]}")
fi
printf '[LiveTalking] 模型=%s avatar=%s 传输=%s\n' "$MODEL" "$AVATAR_ID" "$TRANSPORT"
printf '[LiveTalking] %s/index.html\n' "$LIVETALKING_URL"
exec "${cmd[@]}"
