@echo off

rem ### Variables ##############################################################

SET PROJECT_DIR=<PATH\TO\PROJECT>
SET UPROJECT_FILE=%PROJECT_DIR%\<UPROJECT FILE NAME>.uproject

SET UE4_DIR=<PATH\TO\COMPILED\UE4>
SET UAT_CMD=%UE4_DIR%\Engine\Build\BatchFiles\Build.bat
SET UAT_GEN_CMD=%UE4_DIR%\Engine\Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe
SET PROJECT_NM=<PROJEcT NAME>

rem # Generate project files
%UAT_GEN_CMD% /projectfiles %UPROJECT_FILE%
timeout /T 2

rem ### Builds #################################################################

rem # empty log file
break > %PROJECT_DIR%\compile_windows_editor.log
start powershell Get-Content %PROJECT_DIR%\compile_windows_editor.log -Wait

timeout /T 2

echo Compile Windows Editor
echo ---------------------------------------------------------------------------
call %UAT_CMD% %PROJECT_NM%Editor Win64 Development %UPROJECT_FILE% -WaitMutex > %PROJECT_DIR%\compile_windows_editor.log

pause