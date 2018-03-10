@ECHO OFF
SET c=%1
SET e=

IF [%1] EQU [] ( SET c=--version )
IF [%1] EQU [i] ( SET c=images )
IF [%1] EQU [c] ( SET c=container list )
IF [%1] EQU [b] (
  SET c=build -t 
  SET e="."
)
IF [%1] EQU [r] ( SET c=run -p 8080:80 -it )
IF [%1] EQU [rma] (
  REM ECHO "docker stop and remove all containers"
  powershell -Command "& {docker stop $(docker ps -a -q)}"
  powershell -Command "& {docker rm $(docker ps -a -q)}"
  goto :eof
)
ECHO docker %c% %2 %3 %4 %5 %6 %7 %8 %9
docker %c% %2 %3 %4 %5 %6 %7 %8 %9 %e%
:eof