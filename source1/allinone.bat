@echo off
Title BatteryStateRecorder
setlocal enableextensions disabledelayedexpansion
set 
cd C:\Battery State
cd source1
mkdir ..\data
cd ..\data
::set "des=%userprofile%\Desktop\Battery State.lnk"
::set "sUP=%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
::copy "%des%" "%sUP%"
echo.Time,Charge Level,Charger Plugged > "Result.csv"
break>"tempo1.csv"
break>"tempo2.txt"
break>"tempo3.csv"
:a
for /f "tokens=2 delims==" %%a in ('WMIC PATH Win32_Battery Get EstimatedChargeRemaining /value') do set remain=%%a
for /f "tokens=2 delims==" %%a in ('WMIC Path Win32_Battery Get BatteryStatus /value') do set s=%%a
set /a s= %s%-1
echo.%remain%>>"tempo1.csv"
echo.%time:~0,5%>>"tempo2.txt"
echo.%s%>>"tempo3.csv"

set /a min=100
set /a max=0
set /a i=0
set /a j=0
set /a l=0

goto :function
:back
for /F "usebackq delims=" %%a in ("tempo1.csv") do (
set /A i+=1
call set "arr[%%i%%]=%%a"
call set n=%%i%%
)


for /F "usebackq delims=" %%x in ("tempo2.txt") do (
set /A j+=1
call set arr_date[%%j%%]=%%x
call set m=%%j%%
)
set /a result=0

call :strlen result arr_date[1]
::echo %result%
if %result% == 4 (

set "mins=%arr_date[1]:~2,5%" 

set "hr=%arr_date[1]:~0,1%"
)
if %result% == 5 (
set "mins=%arr_date[1]:~3,5%"
set "hr=%arr_date[1]:~0,2%"
)

for /F "usebackq delims=" %%y in ("tempo3.csv") do (
set /A l+=1
call set arr_stat[%%l%%]=%%y
call set o=%%l%%
)



set /a b=1
:minMax
	call set /a kk=%%arr[%b%]%%-%max%
	call set /a qq=%%arr[%b%]%%-%min%
	if %kk% gtr 0 set  max=%%arr[%b%]%%    
	if %qq% lss 0 set  min=%%arr[%b%]%%
	set /A b=%b%+1
	if /i  %b% gtr %i% (
		set /a b = 2
		call set /a max = %max%
		call set /a min = %min%
		
	goto :suite
	)
goto :minMax

:suite
::echo %remain%
::echo %min%,%max%
set /a k=1
echo.Time,Charge Level,Charger Plugged > "Result.csv"
:res
call set /a s=%%arr_stat[%k%]%%
if %s% equ 0 call set /a s=%min%-1
if %s% equ 1 call set /a s=%max%+1
echo %s%
call echo.%%arr_date[%k%]%%,%%arr[%k%]%%,%s%>>"Result.csv"
set /a k=%k%+1
if /i %k% gtr %i% goto :end
echo %k%
goto :res


:end


set "dayfolder=%Date:~6,4%-%Date:~3,2%-%Date:~0,2%_%hr%h%mins%"
set "k=%Date:~6,4%-%Date:~3,2%-%Date:~0,2%_%hr%h%mins%"
set bur=%USERPROFILE%\Desktop\Battery State History"
mkdir "%bur%"
mkdir "%bur%\%dayfolder%"
set bc=%USERPROFILE%\Desktop\Battery State History\%dayfolder%\%k%.png
set csvfile=%USERPROFILE%\Desktop\Battery State History\%dayfolder%\%k%.csv
break> "%csvfile%"
copy "Result.csv" "%csvfile%"
echo %cd%
cscript ..\source1\csvplot.vbs "%cd%\result.csv" "%bc%" 1200 600 1 3 1 2 
ping localhost -n 60> nul

goto :a 



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:function
    set "search= "
    set "replace="
	set "textFile=tempo2.txt"

    for /f "delims=" %%i in ('type "%textFile%" ^& break ^> "%textFile%" ') do (
        set "line=%%i"
        setlocal enabledelayedexpansion
        >>"%textFile%" echo(!line:%search%=%replace%!
        endlocal
    )
	
	for /f "usebackq tokens=* delims=" %%a in ("tempo2.txt") do (echo(%%a)>>~.txt
move /y  ~.txt "tempo2.txt"
goto back
:: ********* function2 *****************************
:strlen <resultVar> <stringVar>
(   
    setlocal EnableDelayedExpansion
    (set^ tmp=!%~2!)
    if defined tmp (
        set "len=1"
        for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
            if "!tmp:~%%P,1!" NEQ "" ( 
                set /a "len+=%%P"
                set "tmp=!tmp:~%%P!"
            )
        )
    ) ELSE (
        set len=0
    )
)

( 
    endlocal
    set "%~1=%len%"
)