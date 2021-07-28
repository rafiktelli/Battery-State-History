Set fso = CreateObject("Scripting.FileSystemObject")
If fso.FileExists("data\result.csv") Then
	Wscript.sleep(1000)
	result = MsgBox ("Program is running, do you want to stop it?", vbYesNo, "Battery State History")
	Select Case result
	Case vbYes
		Set oShell0 = CreateObject ("Wscript.Shell") 
		oShell0.Run "cmd /c source1\stopIT.bat", 0, false
		Set oShell0 = Nothing
		x=msgbox("	Stopped   ", 0, "Battery State History")
	Case vbNo
		
	End Select
Else
	result = MsgBox ("Start recording Battery Charge Variation?", vbYesNo, "Battery State History")
	Select Case result
	Case vbYes
		Set oWS = WScript.CreateObject("WScript.Shell")
		userProfile = oWS.ExpandEnvironmentStrings("%userprofile%")
		sLinkFile =userprofile & "\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Battery State.LNK"
		Set	oLink = oWS.CreateShortcut(sLinkFile)
		oLink.TargetPath ="C:\Battery State\source1\allinone2.bat"	
		oLink.Save

		Set obj = CreateObject("Scripting.FileSystemObject") 'Calls the File System Object
		if fso.FileExists("data\Result.csv") Then
			obj.DeleteFile("data\Result.csv") 'Deletes the file throught the DeleteFile function
		End If
		Set oShell2 = CreateObject ("Wscript.Shell") 
		oShell2.Run "cmd /c source1\allinone.bat", 0, false
		Set oShell2 = Nothing
	Case vbNo
		
	End Select
End If