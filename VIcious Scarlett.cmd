@echo off
rem VIcious Scarlett launcher. First run asks where game_scarlett_master.exe is and remembers it (game-path.txt).
rem Cache and saves stay in this folder (runs\). Nothing starts by itself: after the game closes you're back at the menu.
setlocal EnableExtensions
cd /d "%~dp0"
title VIcious Scarlett
set "CFG=%~dp0game-path.txt"
set "RUN=%~dp0runs"
if exist "%~dp0target\release\victory.exe" goto built
if exist "%~dp0victory.exe" goto built
echo.
echo   VIcious Scarlett isn't built yet. Do this once (needs Rust + Visual Studio C++ build tools, see README):
echo.
echo     1. Open PowerShell in this folder
echo     2. Run:  cargo build --release --locked -p victory
echo     3. When it says Finished, double-click this file again.
echo.
pause
exit /b 1
:built
set "GAME="
if exist "%CFG%" set /p GAME=<"%CFG%"
if defined GAME if not exist "%GAME%" set "GAME="
if defined GAME goto menu

:askgame
cls
echo.
echo   Where is your game? Paste the full path of game_scarlett_master.exe
echo   (or the folder it's in), then press Enter.
echo.
set "GAME="
set /p "GAME=  Path: "
if not defined GAME goto askgame
set "GAME=%GAME:"=%"
if exist "%GAME%\game_scarlett_master.exe" set "GAME=%GAME%\game_scarlett_master.exe"
if not exist "%GAME%" (echo   Not found: %GAME% & pause & goto askgame)
> "%CFG%" echo %GAME%

:menu
cls
echo.
echo   ===============  VIcious Scarlett  ===============
echo.
echo    A   Play (no DLSS)
echo    B   Play with DLSS (Balanced upscaling, NVIDIA RTX only)
echo    W   Only warm shaders/pipelines (no game)
echo    G   Change game path
echo    Q   Quit
echo.
echo   Game: %GAME%
echo.
set "L="
set /p "L=  Letter (Enter = A): "
if "%L%"=="" set "L=A"
if /i "%L%"=="q" exit /b 0
if /i "%L%"=="g" goto askgame
set "EXTRA="
if /i "%L%"=="A" goto go
if /i "%L%"=="B" (set "EXTRA=VICTORY_DLSS=1;VICTORY_DLSS_MODE=balanced" & goto go)
if /i "%L%"=="W" goto warm
goto menu

:env
if not exist "%RUN%\cache" mkdir "%RUN%\cache"
if not exist "%RUN%\data" mkdir "%RUN%\data"
set "VICTORY_CACHE_DIR=%RUN%\cache"
set "VICTORY_DATA_DIR=%RUN%\data"
set VICTORY_TELEMETRY=0
set VICTORY_DISCORD=0
rem The page pool is "committed" memory: it needs RAM + page file of about 48 GB. Below that it's left off (no crash).
set "COMMITGB=0"
for /f %%M in ('powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).TotalVirtualMemorySize/1MB)"') do set "COMMITGB=%%M"
if %COMMITGB% LSS 48 (
  echo   RAM + page file = %COMMITGB% GB, under 48 GB: VICTORY_POOL_COMMIT off. See README for the page file tip.
  if defined EXTRA (set "EXTRA=%EXTRA%;VICTORY_POOL_COMMIT=0") else (set "EXTRA=VICTORY_POOL_COMMIT=0")
)
exit /b 0

:go
call :env
set "VICTORY_PIPELINE_WAIT_MS="
if not exist "%RUN%\cache\.first-run-done" set VICTORY_PIPELINE_WAIT_MS=10000
if defined EXTRA (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\play-3070-launcher.ps1" -Game "%GAME%" -Prewarm -Hooks -Extra "%EXTRA%"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\play-3070-launcher.ps1" -Game "%GAME%" -Prewarm -Hooks
)
echo done> "%RUN%\cache\.first-run-done"
echo.
pause
goto menu

:warm
call :env
for %%D in ("%GAME%") do set "GAMEDIR=%%~dpD"
set "VICTORY_GAME_DIR=%GAMEDIR:~0,-1%"
"%~dp0victory.exe" shaders "%GAMEDIR:~0,-1%"
"%~dp0victory.exe" warm
echo.
echo   Warm finished.
pause
goto menu
