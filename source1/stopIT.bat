@echo off
cd source1
taskkill /F /FI "WindowTitle eq BatteryStateRecorder" /T
cd ..\data
del /f "result.csv"
del "tempo3.csv"
del "tempo2.txt"
del "tempo1.csv"
exit /B