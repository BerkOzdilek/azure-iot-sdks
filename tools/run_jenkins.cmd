@setlocal
@echo off

set current-path=%~dp0

rem // remove trailing slash
set current-path=%current-path:~0,-1%

set build-root=%current-path%\..
rem // resolve to fully qualified path
for %%i in ("%build-root%") do set build-root=%%~fi

REM check that we have java handy
call :checkExists java
if not %errorlevel%==0 exit /b %errorlevel%

REM find current branch
for /f "usebackq tokens=*" %%i in (`git symbolic-ref -q HEAD`) do set "current_branch_ref=%%i"
if defined current_branch_ref set "current_branch=%current_branch_ref:refs/heads/=%"

REM handle detached HEAD
if not defined current_branch (
    echo You're not on any branch! Aborting...
    goto :eof
)

REM Must be on a topic branch when running this script
set __exit=1
if not "%current_branch%"=="master" if not "%current_branch%"=="develop" set __exit=0
if %__exit%==1 (
    echo You cannot call this script from 'develop' or 'master'. Change to a topic branch first.  Aborting...
    goto :eof
)

REM find tracking branch
for /f "usebackq tokens=*" %%i in (`git rev-parse --symbolic-full-name --abbrev-ref @{u}`) do set "tracking_branch=%%i"
if not defined tracking_branch (
    echo Branch ^'%current_branch%^' is not tracking a remote branch! Aborting...
    goto :eof
)

REM find repo url
for /f "usebackq tokens=*" %%i in (`git config --get remote.origin.url`) do set "repo_url=%%i"
if not defined tracking_branch (
    echo cannot the repository url! Aborting...
    goto :eof
)

echo ***********************************
echo commit_id: %current_branch%
echo repo_url:  %repo_url%
echo ***********************************


REM kick off the build!
java -jar "%build-root%"\tools\jenkins-cli.jar -s http://azure-iot-sdks-ci.westus.cloudapp.azure.com:8080/ build _anyrepo2M-integrate-into-develop -p COMMIT_ID=%current_branch% -p AZURE_REPO=%repo_url% -p BRANCH_TO_MERGE_TO=develop -s -v

rem -----------------------------------------------------------------------------
rem -- done
rem -----------------------------------------------------------------------------
goto :eof

rem -----------------------------------------------------------------------------
rem -- helper subroutines
rem -----------------------------------------------------------------------------
:checkExists
where %~1 >nul 2>nul
if not %errorlevel%==0 (
    echo "%~1" not found. Please make sure that "%~1" is installed and available in the path.
    exit /b %errorlevel%
)
goto :eof

