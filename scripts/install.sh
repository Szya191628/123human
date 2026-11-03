#!/usr/bin/env bash
# 安装上游两个开源仓库（随包附带 LiveTalking 源码，LiveStream 由上游拉取，模型权重另行准备）
set -euo pipefail
source "$(dirname "$0")/_common.sh"
ONLY_CLONE=0; SKIP_TORCH=0; SKIP_FRONTEND=0
for arg in "$@"; do
  case "$arg" in
    --clone-only) ONLY_CLONE=1;;
    --skip-torch) SKIP_TORCH=1;;
    --skip-frontend) SKIP_FRONTEND=1;;
    *) echo "未知参数: $arg" >&2; exit 2;;
  esac
done
need git
mkdir -p "$WORK_ROOT"
clone_if_needed() {
  local url="$1" dir="$2"
  if [[ -d "$dir/.git" ]]; then
    echo "[SKIP] $dir 已存在。不自动 git pull，以免破坏本地修改。"
  elif [[ "$url" == "https://github.com/lipku/LiveTalking.git" && -s "$dir/.upstream-commit" && -f "$dir/app.py" && -f "$dir/LICENSE" ]]; then
    echo "[SKIP] 使用随包附带的 LiveTalking 源码。"
  elif [[ -e "$dir" ]]; then
    echo "[ERROR] 目标路径存在且不是 git 仓库: $dir" >&2; exit 1
  else
    git clone --depth 1 "$url" "$dir"
  fi
}
clone_if_needed https://github.com/lipku/LiveTalking.git "$WORK_ROOT/LiveTalking"
if [[ "$LIVESTREAM_SOURCE_DIR" == "$WORK_ROOT/LiveStream" ]]; then
  clone_if_needed https://github.com/lipku/LiveStream.git "$LIVESTREAM_SOURCE_DIR"
else
  [[ -f "$LIVESTREAM_SOURCE_DIR/backend/app/main.py" && -f "$LIVESTREAM_SOURCE_DIR/frontend/package.json" ]] || {
    echo "[ERROR] 无效的 LiveStream 源码目录: $LIVESTREAM_SOURCE_DIR" >&2
    exit 1
  }
  echo "[SKIP] 使用本地 LiveStream: $LIVESTREAM_SOURCE_DIR"
fi
{
  printf 'LiveTalking  '; if [[ -d "$WORK_ROOT/LiveTalking/.git" ]]; then git -C "$WORK_ROOT/LiveTalking" rev-parse HEAD; else cat "$WORK_ROOT/LiveTalking/.upstream-commit"; fi
  printf 'LiveStream   '; if [[ -e "$LIVESTREAM_SOURCE_DIR/.git" ]]; then git -C "$LIVESTREAM_SOURCE_DIR" rev-parse HEAD; else printf "local source\n"; fi
} > "$KIT_ROOT/UPSTREAM_COMMITS.txt"
if (( ONLY_CLONE )); then echo "[OK] 两个仓库已准备，未安装依赖 (--clone-only)。"; exit 0; fi
need conda
if (( ! SKIP_FRONTEND )); then need npm; fi
need python3
ensure_env() {
  local env="$1"
  if conda env list | awk '{print $1}' | grep -qx "$env"; then
    echo "[SKIP] conda 环境已存在: $env"
  else
    conda create -y -n "$env" python=3.12
  fi
}
ensure_env livetalking
ensure_env livestream
if (( ! SKIP_TORCH )); then
  echo "[INFO] 安装 PyTorch ${PYTORCH_VERSION}，CUDA wheel: ${PYTORCH_INDEX_URL}"
  conda run -n livetalking python -m pip install \
    "torch==$PYTORCH_VERSION" "torchvision==$TORCHVISION_VERSION" "torchaudio==$TORCHAUDIO_VERSION" \
    --index-url "$PYTORCH_INDEX_URL"
fi
conda run -n livetalking python -m pip install -r "$WORK_ROOT/LiveTalking/requirements.txt"
conda run -n livestream python -m pip install -r "$LIVESTREAM_SOURCE_DIR/backend/requirements.txt"
mkdir -p "$LIVESTREAM_SOURCE_DIR/backend/data"
if (( ! SKIP_FRONTEND )); then
  (
    cd "$LIVESTREAM_SOURCE_DIR/frontend"
    if [[ -f package-lock.json ]]; then npm ci; else npm install; fi
    npm run build
  )
fi
printf '\n[OK] 源码/依赖安装步骤已完成。\n'
printf '接下来下载模型权重和 Avatar 数据，运行 python3 scripts/doctor.py，再启动。\n'
