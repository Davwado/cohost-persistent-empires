@echo off
setlocal EnableExtensions EnableDelayedExpansion
title CoHost PE Mod Installer
rem ==============================================================================================================
rem  CoHost PE Mod Installer
rem
rem  Double-click this file. It looks at your PC (Steam, Bannerlord, the original Persistent Empires, any existing
rem  CoHost install), tells you what it found and what to do next, and only changes something when YOU choose an
rem  option and confirm it. The install, update and check work is done by the PowerShell files in the "scripts"
rem  folder; this file starts them for one run with the script policy bypassed, and changes no Windows setting.
rem  It is plain text: open it in Notepad to read every step.
rem
rem  For support only: COHOST_STEAM (Steam folder), COHOST_PSEXE (powershell.exe) and COHOST_NOBROWSER can be set
rem  to override detection.
rem ==============================================================================================================

set "HERE=%~dp0"
set "WANT=v1.4.8"
set "ORIGID=2937242207"
set "COHOSTID=3827536748"
set "BAD=0"

:main
set "FAILS=0"
set "STEAM=" & set "GAME=" & set "GAMEVER=" & set "ORIG=" & set "ORIGPART=" & set "ORIGVER="
set "WS=" & set "WSPART=" & set "WSVER=" & set "GH=" & set "GHVER=" & set "SRC=" & set "SRCVER=" & set "RUN=" & set "NLIB=0"
echo.
echo  CoHost PE Mod Installer
echo  =======================
echo  Looking at this PC. Nothing is changed until you choose an option below.
echo.

rem ---- inside the zip?
echo "!HERE!" | find /i "\Temp1_" >nul && call :warn "This looks like the inside of the zip file. Close this, right-click the zip, choose Extract All, and run this file from the extracted folder."

rem ---- PowerShell (only the install, update and check steps need it; this report does not)
set "PSEXE=%COHOST_PSEXE%"
if not defined PSEXE set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "!PSEXE!" (call :ok "Windows PowerShell found") else call :fail "Windows PowerShell was not found. The install scripts need it. It is part of Windows 10 and 11."

rem ---- Steam and its libraries
set "STEAM=%COHOST_STEAM%"
if not defined STEAM for /f "tokens=2,*" %%a in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul ^| findstr /i "SteamPath"') do set "STEAM=%%b"
if defined STEAM set "STEAM=!STEAM:/=\!"
if defined STEAM if not exist "!STEAM!\steamapps" set "STEAM="
if defined STEAM call :addlib "!STEAM!"
if defined STEAM if exist "!STEAM!\steamapps\libraryfolders.vdf" for /f "tokens=1,*" %%a in ('findstr /i /c:"path" "!STEAM!\steamapps\libraryfolders.vdf"') do call :addvdf %%b
if defined STEAM (call :ok "Steam found: !STEAM!   [%NLIB% game libraries]") else call :fail "Steam was not found on this PC. Install Steam and Bannerlord first."

rem ---- Bannerlord
for /l %%i in (1,1,%NLIB%) do if not defined GAME if exist "!LIB%%i!\steamapps\common\Mount & Blade II Bannerlord\bin\Win64_Shipping_Client" set "GAME=!LIB%%i!\steamapps\common\Mount & Blade II Bannerlord"
if defined STEAM if not defined GAME call :fail "Bannerlord was not found in your Steam libraries. Install Bannerlord from Steam, then run this again."
if defined GAME call :getver "!GAME!\Modules\Native\SubModule.xml" GAMEVER
if defined GAME (
    if /i "!GAMEVER!"=="%WANT%" (call :ok "Bannerlord found: !GAME!   [version !GAMEVER!]") else call :warn "Bannerlord found [version !GAMEVER!] but this mod is built for %WANT%. In Steam: Bannerlord, Properties, Betas, choose the public branch."
)

rem ---- the original Persistent Empires, and the Workshop version of CoHost
call :findws %ORIGID% ORIG
call :findws %COHOSTID% WS
if defined ORIG (
    call :ok "Original Persistent Empires [Steam Workshop %ORIGID%] is installed   [version !ORIGVER!]"
) else if defined ORIGPART (
    call :warn "The original Persistent Empires is still downloading. Leave Steam open until it finishes."
) else if defined WS (
    call :info "The original Persistent Empires is not installed. That is fine: the Workshop version of CoHost includes what it needs."
) else (
    call :fail "The original Persistent Empires [Steam Workshop %ORIGID%] is NOT installed. The GitHub version needs it for the game assets. Choose 5 to open its page, click Subscribe and let Steam finish."
)
if defined WS (
    call :ok "CoHost Persistent Empires from the Steam Workshop is installed   [version !WSVER!]. Steam keeps it up to date."
) else if defined WSPART (
    call :warn "The Workshop version of CoHost is still downloading. Leave Steam open until it finishes."
) else (
    call :info "CoHost Persistent Empires from the Steam Workshop: not installed."
)

rem ---- a GitHub install in the game folder, and the mod files next to this file
if defined GAME if exist "!GAME!\Modules\CoHostPersistentEmpires\SubModule.xml" (
    set "GH=!GAME!\Modules\CoHostPersistentEmpires"
    call :getver "!GAME!\Modules\CoHostPersistentEmpires\SubModule.xml" GHVER
)
if defined GH (call :ok "CoHost Persistent Empires installed from GitHub   [version !GHVER!]") else call :info "CoHost Persistent Empires installed from GitHub: not installed."
if defined WS if defined GH call :warn "You have BOTH the Workshop version and the GitHub version. The game may list the mod twice or load the wrong one. Keep one: choose 4 to remove the GitHub copy."
set "SRC=%HERE%CoHostPersistentEmpires"
if not exist "!SRC!\SubModule.xml" set "SRC=%HERE%..\dist\CoHostPersistentEmpires"
if not exist "!SRC!\SubModule.xml" set "SRC="
if defined SRC call :getver "!SRC!\SubModule.xml" SRCVER
if defined SRC (call :ok "Mod files next to this file are ready   [version !SRCVER!]") else call :info "Mod files next to this file: not found. Only needed to install or reinstall; extract the whole zip first."
if defined GH if defined SRC if /i not "!GHVER!"=="!SRCVER!" call :warn "The installed version [!GHVER!] differs from the files next to this file [!SRCVER!]. Choose 2 to update, or 1 to reinstall from these files."

rem ---- is the game running?
for %%p in (Bannerlord.exe Bannerlord.Native.exe TaleWorlds.MountAndBlade.Launcher.exe) do tasklist /fi "imagename eq %%p" 2>nul | find /i "%%p" >nul && set "RUN=1"
if defined RUN call :warn "Bannerlord or its launcher is running. Close it before installing, updating or removing."

rem ---- what to do next
set "NEXT=Choose 1 to install."
if not defined SRC set "NEXT=Extract the whole zip, then run this file from the extracted folder. It needs the CoHostPersistentEmpires folder beside it."
if not defined ORIG if not defined WS set "NEXT=Choose 5, subscribe to the original Persistent Empires on Steam, wait for the download, then run this again."
if defined GH set "NEXT=Installed. Choose 2 to update it or 3 to check it."
if defined WS set "NEXT=You use the Workshop version, so there is nothing to install. Steam updates it. Do not also install the GitHub version."
if defined WS if defined GH set "NEXT=Keep only one copy. If you use the Workshop version, choose 4 to remove the GitHub copy."
if not defined GAME set "NEXT=Fix the [FAIL] lines above first: Steam and Bannerlord must be installed."
echo.
echo  WHAT TO DO NEXT
echo  ---------------
echo   !NEXT!

:menu
echo.
echo  What would you like to do?
echo    1  Install, or reinstall, the GitHub version
echo    2  Update the GitHub version
echo    3  Check the GitHub install for problems
echo    4  Uninstall the GitHub version
echo    5  Open the original Persistent Empires page on Steam
echo    Q  Quit
echo.
set "CH="
set /p "CH=  Type 1, 2, 3, 4, 5 or Q, then press Enter: "
if /i "!CH!"=="1" goto :do_install
if /i "!CH!"=="2" goto :do_update
if /i "!CH!"=="3" goto :do_verify
if /i "!CH!"=="4" goto :do_uninstall
if /i "!CH!"=="5" goto :do_open
if /i "!CH!"=="Q" goto :end
set /a BAD+=1
if !BAD! geq 4 goto :end
echo.
echo  [ -- ] That was not one of the choices.
goto :menu

:do_install
echo.
if not defined GAME (echo  [FAIL] Bannerlord was not found, so there is nothing to install into. & goto :again)
if defined RUN (echo  [FAIL] Close Bannerlord and its launcher first. & goto :again)
if not defined ORIG (echo  [FAIL] The original Persistent Empires is not installed. Choose 5, subscribe, and let Steam finish. & goto :again)
if not defined SRC (echo  [FAIL] The mod files were not found. Extract the whole zip and run this file from the extracted folder. & goto :again)
set "COHOST_GAME=!GAME!"
set "COHOST_ASSETS=!ORIG!"
set "COHOST_SOURCE=!SRC!"
call :runps Install-Module.ps1
goto :again

:do_update
echo.
if defined GH goto :update_go
if defined WS (echo  [ -- ] You use the Workshop version. Steam updates it by itself, so there is nothing to update here. & goto :again)
echo  [ -- ] The GitHub version is not installed yet. Choose 1 first.
goto :again
:update_go
if defined RUN (echo  [FAIL] Close Bannerlord and its launcher first. & goto :again)
set "COHOST_GAME=!GAME!"
call :runps Update-Module.ps1
goto :again

:do_verify
echo.
if defined GH goto :verify_go
if defined WS (echo  [ -- ] You use the Workshop version, which Steam manages. In Steam you can right-click Bannerlord, Properties, Installed Files, Verify. & goto :again)
echo  [ -- ] The GitHub version is not installed, so there is nothing to check. Choose 1 first.
goto :again
:verify_go
set "COHOST_GAME=!GAME!"
if defined ORIG set "COHOST_ASSETS=!ORIG!"
if defined SRC set "COHOST_SOURCE=!SRC!"
call :runps Install-Module.ps1 -Verify
goto :again

:do_uninstall
echo.
if defined GH goto :uninstall_go
echo  [ -- ] The GitHub version is not installed, so there is nothing to remove.
goto :again
:uninstall_go
if defined RUN (echo  [FAIL] Close Bannerlord and its launcher first. & goto :again)
set "COHOST_GAME=!GAME!"
call :runps Install-Module.ps1 -Remove
goto :again

:do_open
echo.
if defined COHOST_NOBROWSER (echo  [ -- ] Would open https://steamcommunity.com/sharedfiles/filedetails/?id=%ORIGID%) else start "" "https://steamcommunity.com/sharedfiles/filedetails/?id=%ORIGID%"
echo  Opened in your browser. Click Subscribe, wait until Steam finishes downloading, then come back here.
goto :again

:again
echo.
echo  Press any key to look at this PC again...
pause >nul
goto :main

:end
echo.
endlocal
exit /b 0

rem ---------------------------------------------------------------------------------------------------- helpers
:ok
set "M=%~1"
echo   [ OK ] !M!
exit /b 0
:warn
set "M=%~1"
echo   [WARN] !M!
exit /b 0
:fail
set "M=%~1"
set /a FAILS+=1
echo   [FAIL] !M!
exit /b 0
:info
set "M=%~1"
echo   [ -- ] !M!
exit /b 0

:addlib
set /a NLIB+=1
set "LIB!NLIB!=%~1"
exit /b 0

:addvdf
set "P=%~1"
set "P=%P:\\=\%"
if exist "%P%\steamapps" call :addlib "%P%"
exit /b 0

:getver
set "%~2=unknown"
if not exist "%~1" exit /b 0
set "GOT="
for /f "usebackq tokens=* delims=" %%v in (`findstr /i /c:"<Version" "%~1"`) do if not defined GOT (
    set "L=%%v"
    set "L=!L:"=#!"
    for /f "tokens=2 delims=#" %%x in ("!L!") do set "%~2=%%x"
    set "GOT=1"
)
exit /b 0

:findws
set "%~2="
set "%~2PART="
for /l %%i in (1,1,%NLIB%) do (
    if exist "!LIB%%i!\steamapps\workshop\content\261550\%~1\SubModule.xml" if not defined %~2 set "%~2=!LIB%%i!\steamapps\workshop\content\261550\%~1"
    if exist "!LIB%%i!\steamapps\workshop\content\261550\%~1" if not defined %~2PART set "%~2PART=!LIB%%i!\steamapps\workshop\content\261550\%~1"
)
if defined %~2 call :getver "!%~2!\SubModule.xml" %~2VER
exit /b 0

:runps
set "SCRIPT=%HERE%scripts\%~1"
if not exist "!SCRIPT!" set "SCRIPT=%HERE%%~1"
if not exist "!SCRIPT!" (
    echo  [FAIL] The file %~1 is missing from the scripts folder. Download the zip again.
    exit /b 1
)
if not exist "!PSEXE!" (
    echo  [FAIL] Windows PowerShell was not found, so this step cannot run.
    exit /b 1
)
set "COHOST_LOGDIR=%HERE%"
echo.
"!PSEXE!" -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT!" %2
set "RC=!errorlevel!"
if not "!RC!"=="0" (
    echo.
    echo  [FAIL] That step reported a problem or stopped ^(code !RC!^). The details are shown above and written to a log file in:
    echo         !HERE!
    echo         Paste that log file in the Discord and we will help.
)
exit /b !RC!
