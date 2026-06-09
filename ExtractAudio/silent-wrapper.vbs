' silent-wrapper.vbs - invisible launcher for main.ps1 (no CMD/PowerShell window flash).
' Called by Explorer context menu:  wscript.exe "silent-wrapper.vbs" "%1"
' WScript.Shell.Run uses CreateProcessW under the hood => Unicode-safe paths.
Option Explicit
Dim sh, fso, scriptDir, ps1, video, cmd
Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1 = scriptDir & "\main.ps1"

If WScript.Arguments.Count = 0 Then WScript.Quit 1
video = WScript.Arguments(0)

cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """ """ & video & """"

' 0 = hidden window, False = fire-and-forget (do not wait)
sh.Run cmd, 0, False
