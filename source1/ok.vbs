Set oShell = CreateObject ("Wscript.Shell") 
Dim strArgs
strArgs = "cmd /c allinone.bat"
oShell.Run strArgs, 0, false