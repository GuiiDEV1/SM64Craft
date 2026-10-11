@echo off
rem MarioCraft source package installer. It copies only installer sources; game files and ROMs stay out.
if /i "%~1"=="--internal" goto run
set "MARIOCRAFT_INSTALL_HOME=%LOCALAPPDATA%\MarioCraft\Installer"
if /i "%~dp0"=="%MARIOCRAFT_INSTALL_HOME%\" goto run
echo Preparing MarioCraft in a short, writable folder...
if not exist "%MARIOCRAFT_INSTALL_HOME%" mkdir "%MARIOCRAFT_INSTALL_HOME%"
if errorlevel 1 goto copy_failed
robocopy "%~dp0" "%MARIOCRAFT_INSTALL_HOME%" /E /XD .git sm64coopdx SkyCraft dist /XF *.z64 *.n64 *.v64 *.log "MarioCraft Launcher.exe" /NFL /NDL /NJH /NJS /NP
if errorlevel 8 goto copy_failed
call "%MARIOCRAFT_INSTALL_HOME%\install.bat" --internal
exit /b %errorlevel%

:copy_failed
echo.
echo Couldn't prepare the installer under %MARIOCRAFT_INSTALL_HOME%.
echo Extract the zip to C:\MarioCraft and run install.bat there.
pause
exit /b 1

:run
cd /d "%~dp0"
set "MSYS2_ROOT=C:\msys64"
if not exist "%MSYS2_ROOT%\usr\bin\bash.exe" set "MSYS2_ROOT=%LOCALAPPDATA%\MarioCraft\Tools\msys64"
if not exist "%MSYS2_ROOT%\usr\bin\bash.exe" (
  echo Before MarioCraft can be installed, this PC needs MSYS2 ^(it builds Super Mario 64^).
  echo Opening its download page in your browser...
  echo.
  echo   Download the installer ^(msys2-x86_64-....exe^) and run it.
  echo   Keep the install folder as C:\msys64 ^(the default^).
  echo   When it finishes, untick "Run MSYS2 now", then run install.bat again.
  start "" "https://www.msys2.org/"
  echo.
  pause
  exit /b 1
)
set MSYSTEM=MINGW64
set CHERE_INVOKING=1
"%MSYS2_ROOT%\usr\bin\bash.exe" -l ./install.sh
echo.
pause
