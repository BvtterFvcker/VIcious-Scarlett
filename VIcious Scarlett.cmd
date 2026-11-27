@echo off
rem VIcious Scarlett launcher. First run asks where game_scarlett_master.exe is and remembers it (game-path.txt).
rem Cache and saves: %LOCALAPPDATA%\VIcious-Scarlett (the emulator refuses them inside its own source folder).
rem Logs: runs\ here. Nothing starts by itself: after the game closes you're back at the menu.
rem No ( ) blocks around paths on purpose: a ")" in a folder name would end the block and close this window.
setlocal EnableExtensions
cd /d "%~dp0"
title VIcious Scarlett
set "HERE=%~dp0"
set "CFG=%HERE%game-path.txt"
set "RUN=%LOCALAPPDATA%\VIcious-Scarlett"
set "EXE=%HERE%target\release\victory.exe"
if exist "%EXE%" goto built
set "EXE=%HERE%victory.exe"
if exist "%EXE%" goto built
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
if not defined GAME goto askgame
if exist "%GAME%" goto menu

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
if exist "%GAME%" goto gameok
echo   Not found: "%GAME%"
pause
goto askgame
:gameok
> "%CFG%" echo %GAME%

:menu
cls
echo.
echo   ===============  VIcious Scarlett  ===============
echo.
echo    A   Play (no DLSS)
echo    B   Play with DLSS (Balanced upscaling, NVIDIA RTX only)
echo    W   Only warm shaders/pipelines (no game)
echo    R   Make a performance report of the last run (copied to clipboard: send it to BvtterFvcker)
echo    G   Change game path
echo    Q   Quit
echo.
echo   Game: "%GAME%"
echo.
set "L="
set /p "L=  Letter (Enter = A): "
if "%L%"=="" set "L=A"
set "EXTRA="
if /i "%L%"=="Q" exit /b 0
if /i "%L%"=="G" goto askgame
if /i "%L%"=="A" goto go
if /i "%L%"=="B" goto dlss
if /i "%L%"=="W" goto warm
if /i "%L%"=="R" goto report
goto menu

:dlss
set "EXTRA=VICTORY_DLSS=1;VICTORY_DLSS_MODE=balanced"
goto go

:report
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%scripts\make-report.ps1"
pause
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
if %COMMITGB% GEQ 48 exit /b 0
echo   RAM + page file = %COMMITGB% GB, under 48 GB: VICTORY_POOL_COMMIT off. See README for the page file tip.
if defined EXTRA set "EXTRA=%EXTRA%;"
set "EXTRA=%EXTRA%VICTORY_POOL_COMMIT=0"
exit /b 0

:go
call :env
set "VICTORY_PIPELINE_WAIT_MS="
if exist "%RUN%\cache\.first-run-done" goto notfirst
set "VICTORY_PIPELINE_WAIT_MS=10000"
cls
echo.
echo   =====================  FIRST START: READ THIS  =====================
echo.
echo   Nothing is broken. On the very first start your PC has no shader
echo   pipelines yet, so they are made WHILE you play:
echo     - the intro and first minutes freeze, go black or crawl (1-5 fps)
echo     - this can last 10-20 minutes, let it run
echo.
echo   The game records what it needed. From the SECOND start on, the
echo   launcher makes all of it before the game opens (the "N of M" lines),
echo   and it plays smoothly. Send performance reports from run 2 or later.
echo.
echo   ====================================================================
echo.
pause
:notfirst
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%scripts\play-3070-launcher.ps1" -Game "%GAME%" -Prewarm -Hooks -Extra "%EXTRA%"
echo done> "%RUN%\cache\.first-run-done"
echo.
pause
goto menu

:warm
call :env
for %%D in ("%GAME%") do set "GAMEDIR=%%~dpD"
set "GAMEDIR=%GAMEDIR:~0,-1%"
set "VICTORY_GAME_DIR=%GAMEDIR%"
"%EXE%" shaders "%GAMEDIR%"
"%EXE%" warm
echo.
echo   Warm finished.
pause
goto menu
