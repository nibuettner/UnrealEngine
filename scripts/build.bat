@echo off

rem ### Variables ##############################################################

SET PROJECT_DIR=<PATH\TO\PROJECT>
SET COMPILE_DIR=<NEW\PATH\TO\PROJECT_COMPILED>
SET UPROJECT_FILE=%PROJECT_DIR%\<UPROJECT FILE NAME>.uproject
SET UPROJECT_FILE_COMP=%COMPILE_DIR%\<UPROJECT FILE NAME>.uproject

rem !!! DON'T put BUILD_DIR below COMPILE_DIR (it will be deleted in the end) !!!
SET BUILD_DIR=%PROJECT_DIR%\Build
SET BUILD_NAME=<BUILD NAME>

SET UE4_DIR=<PATH\TO\COMPILED\UE4>
SET UAT_CMD=%UE4_DIR%\Engine\Build\BatchFiles\RunUAT.bat
SET UAT_GEN_CMD=%UE4_DIR%\Engine\Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe

SET ZIP_CMD=<PATH\TO\ZIP\EXE>

SET SRV_LOCAL_UPLD_PATH=%BUILD_DIR%\%BUILD_NAME%\LinuxServer
SET SRV_UPLD_FILENM=%BUILD_NAME%_Linux_Server.zip
SET CNT_LOCAL_UPLD_PATH=%BUILD_DIR%\%BUILD_NAME%\WindowsNoEditor
SET CNT_UPLD_FILENM=%BUILD_NAME%_Win64_Client.zip

SET PRIVATE_KEYFILE=<LOCAL\PATH\TO\PPK\FILE>

SET SRV_REMOTE_UPLD_PATH=<LINUX/APPLICATION/PATH>
SET SRV_REMOTE_RIGSRV_CMD=<SCRIPT NAME>.sh
SET REMOTE_MACHINE=<LINUX SERVER NAME OR IP>
SET REMOTE_USER=<LINUX USER>

SET PLINK_CMD=<LOCAL\PATH\TO\plink.exe>
SET PSCP_CMD=<LOCAL\PATH\TO\pscp.exe>

rem ### Preparations ###########################################################

if exist %COMPILE_DIR%\ rmdir /Q /S %COMPILE_DIR%
if exist %BUILD_DIR%\%BUILD_NAME%\ rmdir /Q /S %BUILD_DIR%\%BUILD_NAME%
mkdir %COMPILE_DIR%
mkdir %COMPILE_DIR%\Source
mkdir %COMPILE_DIR%\Plugins
mkdir %COMPILE_DIR%\Config
mkdir %COMPILE_DIR%\Content
if not exist %BUILD_DIR%\ mkdir %BUILD_DIR%

echo Create a copy of the project so that I can continue developing
echo ---------------------------------------------------------------------------
copy %UPROJECT_FILE% %COMPILE_DIR%
xcopy %PROJECT_DIR%\Source %COMPILE_DIR%\Source /E /H /C /I
xcopy %PROJECT_DIR%\Plugins %COMPILE_DIR%\Plugins /E /H /C /I
xcopy %PROJECT_DIR%\Config %COMPILE_DIR%\Config /E /H /C /I
xcopy %PROJECT_DIR%\Content %COMPILE_DIR%\Content /E /H /C /I

rem # Generate project files
%UAT_GEN_CMD% /projectfiles %UPROJECT_FILE_COMP%

timeout /T 2

rem ### Builds #################################################################

rem # empty log file
break > %PROJECT_DIR%\build_windows.log
start powershell Get-Content %PROJECT_DIR%\build_windows.log -Wait

timeout /T 2

echo Build Windows
echo ---------------------------------------------------------------------------
call %UAT_CMD% -ScriptsForProject=%UPROJECT_FILE_COMP% BuildCookRun -project=%UPROJECT_FILE_COMP% -noP4 -clientconfig=Development -serverconfig=Development -utf8output -platform=Win64 -build -cook -map=DM-Dunno+Intro+MainMenu -unversionedcookedcontent -compressed -stage -package -stagingdirectory=%BUILD_DIR%\%BUILD_NAME% -cmdline=" -Messaging" -compile > %PROJECT_DIR%\build_windows.log

timeout /T 2

rem # empty log file
break > %PROJECT_DIR%\build_linux_server.log
start powershell Get-Content %PROJECT_DIR%\build_linux_server.log -Wait

timeout /T 2

echo Build LinxServer
echo ---------------------------------------------------------------------------
call %UAT_CMD% -ScriptsForProject=%UPROJECT_FILE_COMP% BuildCookRun -project=%UPROJECT_FILE_COMP% -noP4 -clientconfig=Development -serverconfig=Development -utf8output -server -serverplatform=Linux -noclient -build -cook -map=DM-Dunno+Intro+MainMenu -unversionedcookedcontent -compressed -stage -package -stagingdirectory=%BUILD_DIR%\%BUILD_NAME% -cmdline=" -Messaging" -compile  > %PROJECT_DIR%\build_linux_server.log

rem %UAT_CMD% BuildCookRun -project="%UPROJECT_FILE_COMP%" -noP4 -clientconfig=Development -platform=Win64 -targetplatform=Win64 -server -serverconfig=Development -serverplatform=Linux -maps=DM-Dunno+Intro+MainMenu -noclient -build -cook -compile -stage -stagingdirectory="%BUILD_DIR%\%BUILD_NAME%" -pak -cmdline=" -Messaging" > buildcookrun.log

timeout /T 2

echo ZIP Server Build Files
echo ---------------------------------------------------------------------------
echo %ZIP_CMD% %SRV_LOCAL_UPLD_PATH%\%SRV_UPLD_FILENM% %SRV_LOCAL_UPLD_PATH%\*
%ZIP_CMD% %SRV_LOCAL_UPLD_PATH%\%SRV_UPLD_FILENM% %SRV_LOCAL_UPLD_PATH%\*

rem ### Setup Linux Server #####################################################

rem PuTTY site: https://www.putty.org/
rem PuTTY downloads: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
rem Generate public/private key pair on Win client using puttygen
rem add key to authorized_keys on Linux machine:
rem   execute in Win PowerShell: type <path\to\local\windows\public\key\.ssh\id_ed25519.pub> | ssh <linux-user>@<server-ip> "cat >> /home/<linux-user>/.ssh/authorized_keys"
rem   you'll have to enter the password for <linux-user>@<server-ip> manually here once
rem use key file in plink/pscsp commands
rem example: <path\to\plink.exe> -batch -l <linux-user> -i <path\to\local\windows\private\key\.ssh\id_ed25519.ppk> <server-ip> uptime

echo Kill currently running RIGServer
echo ---------------------------------------------------------------------------
echo %PLINK_CMD% -batch -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %REMOTE_MACHINE% kill "`ps -ef | grep /opt/rig-server/RIG/Binaries/Linux/RIGServer | awk '{ print $2 }'`"
%PLINK_CMD% -batch -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %REMOTE_MACHINE% kill "`ps -ef | grep /opt/rig-server/RIG/Binaries/Linux/RIGServer | awk '{ print $2 }'`"

timeout /T 2

echo Delete remote file contents
echo ---------------------------------------------------------------------------
echo %PLINK_CMD% -batch -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %REMOTE_MACHINE% rm -Rf %SRV_REMOTE_UPLD_PATH%/*
%PLINK_CMD% -batch -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %REMOTE_MACHINE% rm -Rf %SRV_REMOTE_UPLD_PATH%/*

timeout /T 2

echo SCP RIGServer zip file to Linux machine
echo ---------------------------------------------------------------------------
echo %PSCP_CMD% -P 22 -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %SRV_LOCAL_UPLD_PATH%\%SRV_UPLD_FILENM% %REMOTE_MACHINE%:%SRV_REMOTE_UPLD_PATH%
%PSCP_CMD% -P 22 -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %SRV_LOCAL_UPLD_PATH%\%SRV_UPLD_FILENM% %REMOTE_MACHINE%:%SRV_REMOTE_UPLD_PATH%

timeout /T 2

echo Unzip RIGServer zip file on Linux machine
echo ---------------------------------------------------------------------------
%PLINK_CMD% -batch -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %REMOTE_MACHINE% unzip %SRV_REMOTE_UPLD_PATH%/%SRV_UPLD_FILENM% -d %SRV_REMOTE_UPLD_PATH%

timeout /T 2

echo Make RIGServer.sh executable for user
echo ---------------------------------------------------------------------------
echo %PLINK_CMD% -batch -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %REMOTE_MACHINE% chmod 500 %SRV_REMOTE_UPLD_PATH%/%SRV_REMOTE_RIGSRV_CMD%
%PLINK_CMD% -batch -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %REMOTE_MACHINE% chmod 500 %SRV_REMOTE_UPLD_PATH%/%SRV_REMOTE_RIGSRV_CMD%

timeout /T 2

echo Run RIGServer on Linux machine
echo ---------------------------------------------------------------------------
echo %PLINK_CMD% -batch -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %REMOTE_MACHINE% "%SRV_REMOTE_UPLD_PATH%/%SRV_REMOTE_RIGSRV_CMD% > /dev/null &"
%PLINK_CMD% -batch -l %REMOTE_USER% -i %PRIVATE_KEYFILE% %REMOTE_MACHINE% "%SRV_REMOTE_UPLD_PATH%/%SRV_REMOTE_RIGSRV_CMD% > /dev/null &"

echo Delete compile directory
echo ---------------------------------------------------------------------------
rmdir /Q /S %COMPILE_DIR%

rem shutdown -s -t 600

echo ---------------------------------------------------------------------------
echo DONE!
echo ---------------------------------------------------------------------------

pause