@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
CLS
COLOR 1B
TITLE XBMC Addon for IPTV
SET comp=vs2010
SET target=dx
SET buildmode=ask
SET promptlevel=prompt

SET exitcode=0
FOR %%b in (%1, %2, %3, %4, %5) DO (
	IF %%b==vs2010 SET comp=vs2010
	IF %%b==dx SET target=dx
	IF %%b==gl SET target=gl
	IF %%b==clean SET buildmode=clean
)

SET buildconfig=Release

IF %comp%==vs2010 (
  REM look for MSBuild.exe in .NET Framework 4.x
  FOR /F "tokens=3* delims=	" %%A IN ('REG QUERY HKLM\SOFTWARE\Microsoft\MSBuild\ToolsVersions\4.0 /v MSBuildToolsPath') DO SET NET=%%AMSBuild.exe
  IF NOT EXIST "!NET!" (
    FOR /F "tokens=3* delims= " %%A IN ('REG QUERY HKLM\SOFTWARE\Microsoft\MSBuild\ToolsVersions\4.0 /v MSBuildToolsPath') DO SET NET=%%AMSBuild.exe
  )

  IF EXIST "!NET!" (
    set msbuildemitsolution=1
    set OPTS_EXE=xbmc-addon-p2pproxy.sln /t:Build /p:Configuration="%buildconfig%"
    set CLEAN_EXE=xbmc-addon-p2pproxy.sln /t:Clean /p:Configuration="%buildconfig%"
  ) ELSE (
    IF "%VS100COMNTOOLS%"=="" (
		set NET="%ProgramFiles%\Microsoft Visual Studio 10.0\Common7\IDE\VCExpress.exe"
	) ELSE IF EXIST "%VS100COMNTOOLS%\..\IDE\VCExpress.exe" (
		set NET="%VS100COMNTOOLS%\..\IDE\VCExpress.exe"
	) ELSE IF EXIST "%VS100COMNTOOLS%\..\IDE\devenv.exe" (
		set NET="%VS100COMNTOOLS%\..\IDE\devenv.exe"
	)

    set OPTS_EXE=xbmc-addon-p2pproxy.sln /build %buildconfig%
    set CLEAN_EXE=xbmc-addon-p2pproxy.sln /clean %buildconfig%
  )	
)

IF NOT EXIST %NET% (
   set DIETEXT=Visual Studio .NET 2010 was not found.
   goto DIE
)

ECHO Wait while preparing the build.
ECHO ------------------------------------------------------------
ECHO Cleaning Solution...
%NET% %CLEAN_EXE%
ECHO ------------------------------------------------------------
ECHO Compiling Addon for XBMC...
%NET% %OPTS_EXE%

IF EXIST ..\..\addons\pvr.p2pproxy\changelog.txt del ..\..\addons\pvr.p2pproxy\changelog.txt > NUL
IF EXIST ..\..\addons\pvr.p2pproxy\addon.xml del ..\..\addons\pvr.p2pproxy\addon.xml > NUL

REM ------- Grab version from configure.in into addon.xml file--------

setlocal enabledelayedexpansion 

for /f "usebackq delims=" %%i in ("..\..\configure.in") do (

	set "zeile=%%i"

	set zeile=!zeile:~11,30!
	set zeile1=!zeile:~0,5!
	IF !zeile1!==MAJOR (
		set maj=!zeile:~8,30!
		set maj=!maj:~0,-1!
		)
	IF !zeile1!==MINOR (
		set min=!zeile:~8,30!
		set min=!min:~0,-1!
		)
	IF !zeile1!==MICRO ( 
		set mic=!zeile:~8,30!
		set mic=!mic:~0,-1!
		echo !maj!.!min!.!mic!>>test.tmp
		)
	)

for /F "delims=" %%i in (test.tmp) do set "zeile=%%i"
set "Von=  version" 
set "Nach=  version="X"" 
set Nach=!Nach:X=%zeile%!

for /f "usebackq delims=" %%i in ("../../addons/pvr.p2pproxy/addon.xml.in") do (
	set "Line=%%i"
	set Line=!Line:%Von%=%Nach%!
	set Line1=!Line!
	set line1=!line1:~0,9!
	set line1=!line1:~2,7!
	if !Line1!==version set Line=!Line:~0,-12!
	echo !Line! >> ../../addons/pvr.p2pproxy/addon.xml 
	)

setlocal disabledelayedexpansion 

REM ------------------------------------------------------------------------------
 
copy ChangeLog ..\..\addons\pvr.vuplus\changelog.txt > NUL
IF EXIST test.tmp del test.tmp

set ZIP="..\BuildDependencies\bin\7za.exe"
IF NOT EXIST %ZIP% (
   set DIETEXT=7zip was not found.
     goto DIE
)

IF EXIST pvr.p2pproxy.%maj%.%min%.%mic%.zip del pvr.p2pproxy.%maj%.%min%.%mic%.zip > NUL

%ZIP% a pvr.p2pproxy.%maj%.%min%.%mic%.zip ..\..\addons\pvr.p2pproxy -xr!*.in -xr!*.am -xr!*.exp -xr!*.ilk -xr!*.pdb -xr!*.lib -xr!.gitignore >NUL

goto END

:DIE
  ECHO ------------------------------------------------------------
  ECHO !-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-
  ECHO    ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR
  ECHO !-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-
  set DIETEXT=ERROR: %DIETEXT%
  echo %DIETEXT%
  SET exitcode=1
  ECHO ------------------------------------------------------------

:END
IF %promptlevel% NEQ noprompt (
ECHO --------------------------------------------------------------- 
ECHO The file 'pvr.p2pproxy.%maj%.%min%.%mic%.zip' was created in the current directory.
ECHO --------------------------------------------------------------- 
ECHO Press any key to exit...
pause > NUL
)
EXIT /B %exitcode%
