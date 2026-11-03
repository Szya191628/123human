#!/usr/bin/env python3
"""LiveTalking + LiveStream deployment preflight; stdlib only, read-only."""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent
W = ROOT / "workspace"
FAILURES: list[str] = []


def config() -> dict[str, str]:
    values = {"MODEL": "wav2lip", "AVATAR_ID": "wav2lip256_avatar1", "LT_PORT": "8010", "LS_PORT": "8020"}
    p = ROOT / "config" / "settings.env"
    if p.is_file():
        for line in p.read_text(encoding="utf-8").splitlines():
            s = line.strip()
            if not s or s.startswith("#") or "=" not in s:
                continue
            key, val = s.split("=", 1)
            values[key.strip()] = val.strip().strip("\"'")
    return values


def item(name: str, state: bool, explanation: str, *, important: bool = True):
    print(f"[{'PASS' if state else 'WARN'}] {name}: {explanation}")
    if important and not state:
        FAILURES.append(name)


def http(url: str, label: str, json_mode: bool = False):
    try:
        req = Request(url, headers={"User-Agent": "LocalDeploymentDoctor/2.0"})
        with urlopen(req, timeout=4) as result:
            body = result.read(150000)
            if json_mode:
                data = json.loads(body)
                ok = (data.get("code") == 0) if "code" in data else (data.get("status") == "ok")
                extra = f"status={result.status}; {str(data)[:160]}"
            else:
                ok = 200 <= result.status < 400
                extra = f"HTTP {result.status}"
            item(label, ok, f"{url} {extra}")
    except (HTTPError, URLError, OSError, TimeoutError, ValueError, json.JSONDecodeError) as exc:
        item(label, False, f"{url}: {exc}")


def gpu_check():
    tool = shutil.which("nvidia-smi")
    if not tool:
        item("GPU/驱动", False, "未检测到 nvidia-smi。WSL2 应检查 Windows NVIDIA 驱动及 GPU 映射。")
        return
    try:
        p = subprocess.run([tool, "--query-gpu=name,memory.total,driver_version", "--format=csv,noheader"],
                           capture_output=True, text=True, timeout=12)
        item("GPU/驱动", p.returncode == 0, (p.stdout or p.stderr).strip()[:240])
    except (OSError, subprocess.TimeoutExpired) as exc:
        item("GPU/驱动", False, str(exc))


def torch_check():
    if not shutil.which("conda"):
        return
    try:
        p = subprocess.run(["conda", "run", "-n", "livetalking", "python", "-c",
             "import torch; print('torch='+torch.__version__+', cuda_available='+str(torch.cuda.is_available()));"
             " print('gpu='+torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'gpu=none')"],
            capture_output=True, text=True, timeout=40)
        item("PyTorch CUDA", p.returncode == 0 and "cuda_available=True" in p.stdout,
             (p.stdout or p.stderr).strip()[:280])
    except (OSError, subprocess.TimeoutExpired) as exc:
        item("PyTorch CUDA", False, str(exc))


def main() -> int:
    parser = argparse.ArgumentParser(description="查看依赖、模型、显卡与直播服务的就绪情况")
    parser.add_argument("--live", action="store_true", help="同时查询运行中的本机 HTTP API")
    parser.add_argument("--torch", action="store_true", help="额外运行 PyTorch 的 CUDA 检查")
    parser.add_argument("--strict", action="store_true", help="存在 WARN 则返回退出码 1，适合 CI")
    args = parser.parse_args()
    c = config()
    local_ls = Path("/mnt/d/360download/LiveStream")
    default_ls = local_ls if (local_ls / "backend/app/main.py").is_file() and (local_ls / "frontend/package.json").is_file() else W / "LiveStream"
    livestream = Path(c.get("LIVESTREAM_SOURCE_DIR") or os.environ.get("LIVESTREAM_SOURCE_DIR") or default_ls)
    print(f"系统：{platform.system()} / Python {sys.version.split()[0]}")
    for name, executable in (("Git", "git"), ("Conda", "conda"), ("Node/npm", "npm"), ("tmux（可选的后台启动）", "tmux")):
        item(name, bool(shutil.which(executable)), shutil.which(executable) or "未安装", important=executable != "tmux")
    item("LiveTalking 源码", (W / "LiveTalking/app.py").is_file(), str(W / "LiveTalking/app.py"))
    item("LiveStream 源码", (livestream / "backend/app/main.py").is_file(), str(livestream / "backend/app/main.py"))
    item("LiveStream 前端", (livestream / "frontend/dist/index.html").is_file(), "需要 npm run build")
    lt = W / "LiveTalking"
    model = c["MODEL"]
    avatar = c["AVATAR_ID"]
    if model == "wav2lip":
        weight = lt / "models/wav2lip.pth"
        item("Wav2Lip 模型", weight.is_file() and weight.stat().st_size > 0,
             f"{weight}（必须自行下载，不在 ZIP 内）")
    else:
        item(f"模型 {model}", True, "当前跳过模型文件完整性检查，请以官方文档为准", important=False)
    item("Avatar 数据", (lt / "data/avatars" / avatar).is_dir(), str(lt / "data/avatars" / avatar))
    gpu_check()
    if args.torch:
        torch_check()
    if args.live:
        for key in ("LT_PORT", "LS_PORT"):
            if not c[key].isdigit() or not 1 <= int(c[key]) <= 65535:
                parser.error(f"{key} 配置必须是 1~65535 的端口号")
        http(f'http://127.0.0.1:{c["LT_PORT"]}/api/admin/sessions', "LiveTalking sessions", True)
        http(f'http://127.0.0.1:{c["LS_PORT"]}/api/health', "LiveStream health", True)
        http(f'http://127.0.0.1:{c["LS_PORT"]}/', "LiveStream UI")
    print(f"\n检查完成：{len(FAILURES)} 项警告。未运行 GPU 视频播放/OBS/平台推流验收。")
    return 1 if (args.strict and FAILURES) else 0


if __name__ == "__main__":
    sys.exit(main())
