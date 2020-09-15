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

SET 7Z_CMD=<PATH\TO\7-ZIP\EXE>

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

%UAT_CMD% BuildCookRun -project="%UPROJECT_FILE_COMP%" -noP4 -clientconfig=Development -platform=Win64 -targetplatform=Win64 -server -serverconfig=Development -serverplatform=Linux -maps=DM-Dunno+Intro+MainMenu -noclient -build -cook -compile -stage -stagingdirectory="%BUILD_DIR%\%BUILD_NAME%" -pak -cmdline=" -Messaging" > buildcookrun.log

%7Z_CMD% a %BUILD_DIR%\LinuxServer\LinuxServer.zip %BUILD_DIR%\LinuxServer\*

pause

