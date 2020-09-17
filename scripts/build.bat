@echo off

SET PROJECT_DIR=<PATH\TO\PROJECT>
SET COMPILE_DIR=<NEW\PATH\TO\PROJECT_COMPILED>
SET UPROJECT_FILE=%PROJECT_DIR%\<UPROJECT FILE NAME>.uproject
SET UPROJECT_FILE_COMP=%COMPILE_DIR%\<UPROJECT FILE NAME>.uproject
SET BUILD_DIR=%COMPILE_DIR%\Build
SET BUILD_NAME=<BUILD NAME>

SET UE4_DIR=<PATH\TO\COMPILED\UE4>
SET UAT_CMD=%UE4_DIR%\Engine\Build\BatchFiles\RunUAT.bat
SET UAT_GEN_CMD=%UE4_DIR%\Engine\Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe

SET ZIP_CMD=<PATH\TO\ZIP\EXE>

rmdir /Q /S %COMPILE_DIR%
mkdir %COMPILE_DIR%
mkdir %COMPILE_DIR%\Source
mkdir %COMPILE_DIR%\Plugins
mkdir %COMPILE_DIR%\Config
mkdir %COMPILE_DIR%\Content
mkdir %BUILD_DIR%

copy %UPROJECT_FILE% %COMPILE_DIR%
xcopy %PROJECT_DIR%\Source  %COMPILE_DIR%\Source /E /H /C /I
xcopy %PROJECT_DIR%\Plugins %COMPILE_DIR%\Plugins /E /H /C /I
xcopy %PROJECT_DIR%\Config  %COMPILE_DIR%\Config /E /H /C /I
xcopy %PROJECT_DIR%\Content %COMPILE_DIR%\Content /E /H /C /I

%UAT_GEN_CMD% /projectfiles %COMPILE_DIR%\RIG.uproject

echo Build Windows
call %UAT_CMD% -ScriptsForProject=%UPROJECT_FILE_COMP% BuildCookRun -project=%UPROJECT_FILE_COMP% -noP4 -clientconfig=Development -serverconfig=Development -utf8output -platform=Win64 -build -cook -map=DM-Dunno+Intro+MainMenu -unversionedcookedcontent -compressed -stage -package -stagingdirectory=%BUILD_DIR%\%BUILD_NAME% -cmdline=" -Messaging" -compile > build_windows.log

echo Build LinxServer
call %UAT_CMD% -ScriptsForProject=%UPROJECT_FILE_COMP% BuildCookRun -project=%UPROJECT_FILE_COMP% -noP4 -clientconfig=Development -serverconfig=Development -utf8output -server -serverplatform=Linux -noclient -build -cook -map=DM-Dunno+Intro+MainMenu -unversionedcookedcontent -compressed -stage -package -stagingdirectory=%BUILD_DIR%\%BUILD_NAME% -cmdline=" -Messaging" -compile  > build_linux_server.log

echo ZIP Server Build Files
%ZIP_CMD% %BUILD_DIR%\%BUILD_NAME%\LinuxServer\LinuxServer.zip %BUILD_DIR%\%BUILD_NAME%\LinuxServer\*

echo Upload to Server
rem WIP

echo Extract on Server
rem WIP

echo Run on Server
rem WIP

pause

