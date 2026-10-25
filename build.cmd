@echo off
rem Builds exe files of all projects into the "out" folder (see build.ps1)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*
pause
