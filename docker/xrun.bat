@echo off
setlocal

rem Route Docker CLI to the remote daemon used in this environment.
set "DOCKER_HOST=ssh://root@10.12.1.238"
set "REMOTE_HOST=root@10.12.1.238"
set "PUBLIC_HOST=10.12.1.238"
set "COPY_DATA=0"
set "IMAGE_NAME=dsh-web-prod"
rem IMAGE_TYPE dsh-web-dev or dsh-web-prod
set "IMAGE_TYPE=dsh-web-prod"
set "CONTAINER_NAME=dsh-web-prod"
set "DATA_PATH=/opt/dsh"

rem Resolve the repository root from this script's location so local paths stay
rem correct even when the script is launched elsewhere.
pushd "%~dp0.."

rem Allow callers to skip the remote data sync when the server already has the
rem expected files. Default behavior keeps copying so local changes stay in sync.
if /I "%~1"=="--no-copy" set "COPY_DATA=0"
if /I "%~1"=="--copy" set "COPY_DATA=1"

rem Copy the local docker\data tree onto the remote host first so the remote
rem Docker daemon can mount real server-side paths into the container.
if "%COPY_DATA%"=="1" (
  ssh "%REMOTE_HOST%" "mkdir -p %DATA_PATH% && rm -rf %DATA_PATH%/data"
  if errorlevel 1 (
    set "EXIT_CODE=%ERRORLEVEL%"
    popd
    exit /b %EXIT_CODE%
  )

  scp -r "%CD%\docker\data" "%REMOTE_HOST%:%DATA_PATH%/"
  if errorlevel 1 (
    set "EXIT_CODE=%ERRORLEVEL%"
    popd
    exit /b %EXIT_CODE%
  )

  rem The credentials plugin requires owner-only access to the mounted
  rem credential file, so fix the copied mode before container startup.
  ssh "%REMOTE_HOST%" "if [ -f %DATA_PATH%/data/%IMAGE_TYPE%/dsh-home/.credentials.yaml ]; then chmod 600 %DATA_PATH%/data/%IMAGE_TYPE%/dsh-home/.credentials.yaml; fi"
  ssh "%REMOTE_HOST%" "if [ -f %DATA_PATH%/data/dsh-web-dev/dsh-home/.credentials.yaml ]; then chmod 600 %DATA_PATH%/data/dsh-web-dev/dsh-home/.credentials.yaml; fi"
  ssh "%REMOTE_HOST%" "if [ -f %DATA_PATH%/data/dsh-web-prod/dsh-home/.credentials.yaml ]; then chmod 600 %DATA_PATH%/data/dsh-web-prod/dsh-home/.credentials.yaml; fi"

  if errorlevel 1 (
    set "EXIT_CODE=%ERRORLEVEL%"
    popd
    exit /b %EXIT_CODE%
  )
)

rem Run the production image with persisted DSH state, a mounted workspace, and
rem the copied server-side docker/data tree available under /opt/dsh/data.
rem Publish the externally reachable URL and trust that host for browser API
rem calls so workspace picking and other client APIs do not fail with HTTP 403.
docker rm -f %CONTAINER_NAME%

docker run -d ^
  --name %CONTAINER_NAME% ^
  -p 3080:3080 ^
  -e DSH_HOME=/data/dsh-home ^
  -e DSH_PUBLIC_URL=http://%PUBLIC_HOST%:3080 ^
  -e DSH_TRUSTED_HOSTS=%PUBLIC_HOST%,localhost,127.0.0.1 ^
  -v %DATA_PATH%/data/%IMAGE_TYPE%/dsh-home:/data/dsh-home ^
  -v %DATA_PATH%/data/%IMAGE_TYPE%/workspace:/workspace ^
  %IMAGE_NAME%

set "EXIT_CODE=%ERRORLEVEL%"

popd
exit /b %EXIT_CODE%
