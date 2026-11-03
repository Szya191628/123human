# LiveTalking + LiveStream 数字人直播部署

本仓库提供 Windows + WSL2 的部署包。LiveTalking 负责生成数字人音视频，LiveStream 负责管理话术、循环播报和互动配置。

**[下载 v3 整合包](https://github.com/Szya191628/123human/blob/main/LiveTalking_LiveStream_Integrated_v3.zip)**。打开文件页后点击 **Download raw file**。

也可以直接浏览仓库中的 [LiveTalking 源码](workspace/LiveTalking)、[部署脚本](scripts)和[配置示例](config/settings.env.example)，或用 `git clone https://github.com/Szya191628/123human.git` 获取整个仓库。

| 组件 | v3 中的获取方式 |
| --- | --- |
| LiveTalking | ZIP 内含源码，位于 `workspace/LiveTalking`，保留上游 Apache-2.0 许可证 |
| LiveStream | WSL 下优先使用 `/mnt/d/360download/LiveStream`，对应 Windows 的 `D:\360download\LiveStream`。找不到可用的本地源码时，安装脚本从上游下载 |
| Wav2Lip 权重与数字人形象 | 按 LiveTalking 上游说明另行下载 |

如需使用其他位置的 LiveStream 源码，在 `config/settings.env` 中设置 `LIVESTREAM_SOURCE_DIR`，填写 Ubuntu 可访问的绝对路径。

## 安装与本地验证

1. 准备 WSL2 Ubuntu，以及 Ubuntu 中可用的 Git、Conda、Python 3、Node.js 和 npm。运行数字人还需要可在 WSL 中使用的 NVIDIA GPU 和兼容的 PyTorch CUDA 环境。
2. 在 Ubuntu 终端进入克隆后的仓库根目录，或解压 v3 后进入 `LiveTalking_LiveStream_Deploy_v2` 目录。以 `scripts/` 和 `config/` 所在位置为准。首次部署时执行：

   ```bash
   cp -n config/settings.env.example config/settings.env
   bash scripts/install.sh
   ```

   如需先核对源码来源，可运行 `bash scripts/install.sh --clone-only`。
3. 下载 Wav2Lip 权重和示例形象。将 `wav2lip256.pth` 重命名为 `wav2lip.pth`，放入 `workspace/LiveTalking/models/`。将解压后的 `wav2lip256_avatar1` 目录放入 `workspace/LiveTalking/data/avatars/`。[模型和形象下载说明](https://github.com/lipku/LiveTalking#21-下载模型)
4. 运行 `python3 scripts/doctor.py --torch` 检查依赖、模型和 CUDA。在两个 Ubuntu 终端分别运行 `bash scripts/start-livetalking.sh` 和 `bash scripts/start-livestream.sh`。
5. 打开 [LiveTalking 本地页面](http://127.0.0.1:8010/index.html)，建立 WebRTC 会话，用一段音频测试画面和口型。再打开 [LiveStream 本地后台](http://127.0.0.1:8020)，配置 LiveTalking 地址和会话，测试固定话术循环。

## 问答、语音和推流

- 固定音频播报可先独立测试。文本合成语音需要配置 TTS，AI 自动问答需要配置大模型服务，知识库还需配置 Embedding 服务。
- 画面和声音验证通过后，可用 OBS 或直播伴侣采集。正式开播和弹幕互动取决于平台权限及对应接入方式。

## 验证状态和上游

已验证 v3 安装脚本能选择本地 LiveStream 源码，也能在缺少本地源码时从上游下载。GPU 推理、完整启动和平台推流仍待实测。若 ZIP 内的旧版说明与本页冲突，请以本页和 v3 脚本为准。

上游项目：[LiveTalking](https://github.com/lipku/LiveTalking) · [LiveStream](https://github.com/lipku/LiveStream)
