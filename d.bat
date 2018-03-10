@ECHO OFF
SET c=%1
IF [%1] EQU [] SET c=--version
IF [%1] EQU [b] SET c=build
IF [%1] EQU [r] SET c=restore
IF [%1] EQU [t] SET c=test --logger:"console;verbosity=normal"
IF [%1] EQU [p] SET c=pack
IF [%1] EQU [n] SET c=new
ECHO dotnet %c% %2 %3 %4 %5 %6 %7 %8 %9
dotnet %c% %2 %3 %4 %5 %6 %7 %8 %9
