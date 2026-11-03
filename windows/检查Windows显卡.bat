@echo off
chcp 65001 >nul
nvidia-smi
if errorlevel 1 (
 echo 未找到 NVIDIA 驱动，请先安装或升级显卡驱动。
)
pause
