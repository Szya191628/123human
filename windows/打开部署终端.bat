@echo off
chcp 65001 >nul
REM Use the deployment folder next to this Windows helper.
for %%I in ("%~dp0..") do wsl.exe -d Ubuntu --cd "%%~fI" -- bash -lc "python3 scripts/doctor.py && bash scripts/start-all.sh && bash scripts/status.sh; exec bash"
pause
