@REM @echo off
setlocal

rem Route Docker CLI to the remote daemon used in this environment.
set "DOCKER_HOST=ssh://root@10.12.1.238"
@REM set "DOCKER_HOST=tcp://10.12.1.238:2375"

rem Resolve the repository root from this script's location so the build
rem context stays correct even when the script is launched elsewhere.
pushd "%~dp0.."

rem Capture the current commit hash for the Docker build argument. The
rem Dockerfiles require this because .git is excluded from the build context.
for /f "usebackq delims=" %%i in (`git rev-parse HEAD`) do set "DSH_CLIENT_COMMIT_HASH=%%i"

if not defined DSH_CLIENT_COMMIT_HASH (
  echo Failed to resolve git commit hash.
  popd
  exit /b 1
)

docker build ^
  --build-arg HTTP_PROXY=http://10.12.1.132:1083 ^
  --build-arg HTTPS_PROXY=http://10.12.1.132:1083 ^
  --build-arg NO_PROXY=localhost,127.0.0.1 ^
  --build-arg DSH_CLIENT_COMMIT_HASH=%DSH_CLIENT_COMMIT_HASH% ^
  -f docker/Dockerfile.prod ^
  -t dsh-web-prod ^
  .

@REM docker build ^
@REM   --build-arg HTTP_PROXY=http://10.12.1.132:1083 ^
@REM   --build-arg HTTPS_PROXY=http://10.12.1.132:1083 ^
@REM   --build-arg NO_PROXY=localhost,127.0.0.1 ^
@REM   --build-arg DSH_CLIENT_COMMIT_HASH=%DSH_CLIENT_COMMIT_HASH% ^
@REM   -f docker/Dockerfile.dev ^
@REM   -t dsh-web-dev ^
@REM   .


set "EXIT_CODE=%ERRORLEVEL%"
popd
exit /b %EXIT_CODE%
