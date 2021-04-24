; RiskOfRain2AutoSprint v1.0 beta 7

#MaxThreadsPerHotkey 1           ; Prevent accidental double-presses.
#NoEnv                           ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent                      ; Keep the script permanently running since we use a timer.
#Requires AutoHotkey v1.1.33.02+ ; Display an error and quit if this version requirement is not met.
#SingleInstance force            ; Allow only a single instance of the script to run.
#UseHook                         ; Allow listening for non-modifier keys.
#Warn                            ; Enable warnings to assist with detecting common errors.
SendMode Input                   ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%      ; Ensures a consistent starting directory.

; Register a function to be called on exit
OnExit("ExitFunc", -1)

configFileName := RTrim(A_ScriptName, A_IsCompiled ? ".exe" : ".ahk") . ".ini"
OutputDebug, init::configFileName %configFileName%

; Config file is missing, exit
if (!FileExist(configFileName))
	ExitWithErrorMessage(configFileName . " not found! The script will now exit.")

ReadConfigFile()
windowID := 0
SetTimer, OnFocusChanged, %focusCheckDelay%

return

; TODO fix Engineer W broken after using it the 2nd time after char swap
pressAndSprint:

; Fixes a bug where Captain's utility and special skills cannot be used properly
if (currentChar == "Char10" && (GetKeyState(utilityKey) || GetKeyState(specialKey)))
{
	OutputDebug, pressAndSprint::cancel
	return
}

; Beware, pressing multiple keys while the beep is playing causes some keys to not be released
if (bDebug)
	SoundBeep(25)

; Strip out the modifier from the latest hotkey
thisHotkey := LTrim(A_ThisHotkey, "~")
sprintDelay := GetSprintDelay(thisHotkey)

OutputDebug, pressAndSprint::%thisHotkey% begin
SendInput % "{" . thisHotkey . " down}"
OutputDebug, pressAndSprint::%thisHotkey% down
Sleep, %sprintDelay%
OutputDebug, pressAndSprint::%thisHotkey% sleep
ToggleSprint()
OutputDebug, pressAndSprint::%thisHotkey% sprint
KeyWait, %thisHotkey%
OutputDebug, pressAndSprint::%thisHotkey% wait
SendInput % "{" . thisHotkey . " up}"
OutputDebug, pressAndSprint::%thisHotkey% up

return

releaseAndSprint:

; Beware, pressing multiple keys while the beep is playing causes some keys to not be released
if (bDebug)
	SoundBeep(25)

; Strip out the modifier from the latest hotkey
thisHotkey := LTrim(A_ThisHotkey, "~")
sprintDelay := GetSprintDelay(thisHotkey)

OutputDebug, releaseAndSprint::%thisHotkey% begin
SendInput % "{" . thisHotkey . " down}"
OutputDebug, releaseAndSprint::%thisHotkey% down
KeyWait, %thisHotkey%
OutputDebug, releaseAndSprint::%thisHotkey% wait
SendInput % "{" . thisHotkey . " up}"
OutputDebug, releaseAndSprint::%thisHotkey% up
Sleep, %sprintDelay% ; hack to fix double click
OutputDebug, releaseAndSprint::%thisHotkey% sleep
ToggleSprint()
OutputDebug, releaseAndSprint::%thisHotkey% sprint

return

GetCharName(ByRef char)
{
	OutputDebug, GetCharName::switch %char%
	
	switch char
	{
		case "Char1":
			return "Commando"
		case "Char2":
			return "Huntress"
		case "Char3":
			return "Bandit"
		case "Char4":
			return "MUL-T"
		case "Char5":
			return "Engineer"
		case "Char6":
			return "Artificer"
		case "Char7":
			return "Mercenary"
		case "Char8":
			return "REX"
		case "Char9":
			return "Loader"
		case "Char10":
			return "Acrid"
		case "Char11":
			return "Captain"
		default:
			return "Unknown"
	}
}

; https://autohotkey.com/board/topic/69464-how-to-determine-a-window-is-in-which-monitor/?p=440355
GetMonitorIndexFromWindow(windowHandle)
{
	OutputDebug, GetMonitorIndexFromWindow::begin

	; Starts with 1.
	monitorIndex := 1

	VarSetCapacity(monitorInfo, 40)
	NumPut(40, monitorInfo)
	
	if (monitorHandle := DllCall("MonitorFromWindow", "uint", windowHandle, "uint", 0x2)) 
		&& DllCall("GetMonitorInfo", "uint", monitorHandle, "uint", &monitorInfo) 
	{
		monitorLeft   := NumGet(monitorInfo,  4, "Int")
		monitorTop    := NumGet(monitorInfo,  8, "Int")
		monitorRight  := NumGet(monitorInfo, 12, "Int")
		monitorBottom := NumGet(monitorInfo, 16, "Int")
		workLeft      := NumGet(monitorInfo, 20, "Int")
		workTop       := NumGet(monitorInfo, 24, "Int")
		workRight     := NumGet(monitorInfo, 28, "Int")
		workBottom    := NumGet(monitorInfo, 32, "Int")
		isPrimary     := NumGet(monitorInfo, 36, "Int") & 1

		SysGet, monitorCount, MonitorCount

		Loop, %monitorCount%
		{
			SysGet, tempMon, Monitor, %A_Index%

			; Compare location to determine the monitor index.
			if ((monitorLeft = tempMonLeft) and (monitorTop = tempMonTop)
				and (monitorRight = tempMonRight) and (monitorBottom = tempMonBottom))
			{
				monitorIndex := A_Index
				break
			}
		}
	}
	
	OutputDebug, GetMonitorIndexFromWindow::end
	return %monitorIndex%
}

GetSprintDelay(ByRef key)
{
	global
	
	OutputDebug, GetSprintDelay::switch %key%
	
	switch key
	{
		case primaryKey:
			return primarySprintDelay
		case secondaryKey:
			return secondarySprintDelay
		case utilityKey:
			return utilitySprintDelay
		case specialKey:
			return specialSprintDelay
		default:
			return 0
	}
}

HookWindow()
{
	; All the variables below are declared as global so they can be used in the whole script
	global

	; Make the hotkeys active only for a specific window
	OutputDebug, HookWindow::begin
	WinWaitActive, %windowName%
	OutputDebug, HookWindow::WinWaitActive
	Sleep, %hookDelay%
	WinGet, windowID, ID, %windowName%
	OutputDebug, HookWindow::WinGet %windowID%
	GroupAdd, windowIDGroup, ahk_id %windowID%
	Hotkey, IfWinActive, ahk_group windowIDGroup
	OutputDebug, HookWindow::end
}

IsWindowFullscreen(windowID)
{
	global windowName
	
	WinGetPos, windowX, windowY, windowWidth, windowHeight, %windowName%
	SysGet, monitor, Monitor, % GetMonitorIndexFromWindow(windowID)
	
	OutputDebug, IsWindowFullscreen::windowX %windowX%
	OutputDebug, IsWindowFullscreen::windowY %windowY%
	OutputDebug, IsWindowFullscreen::windowWidth %windowWidth%
	OutputDebug, IsWindowFullscreen::windowHeight %windowHeight%
	OutputDebug, IsWindowFullscreen::monitorLeft %monitorLeft%
	OutputDebug, IsWindowFullscreen::monitorTop %monitorTop%
	OutputDebug, IsWindowFullscreen::monitorRight %monitorRight%
	OutputDebug, IsWindowFullscreen::monitorBottom %monitorBottom%
	
	monitorWidth := monitorRight - monitorLeft
	OutputDebug, IsWindowFullscreen::monitorWidth %monitorWidth%
	monitorHeight := monitorBottom - monitorTop
	OutputDebug, IsWindowFullscreen::monitorHeight %monitorHeight%

	isFullscreen := (windowX == monitorLeft) && (windowY == monitorTop) && (windowWidth == monitorWidth) && (windowHeight == monitorHeight)
	OutputDebug, IsWindowFullscreen::isFullscreen %isFullscreen%
	
	return isFullscreen
}

OnFocusChanged()
{
	global

	OutputDebug, OnFocusChanged::begin

	; Make sure to hook the window again if it no longer exists
	if (!WinExist(windowName) || !windowID)
	{
		HookWindow()
		RegisterHotkeys()	
	}
	else
	{
		OutputDebug, OnFocusChanged::WinWaitActive
		WinWaitActive, %windowName%
	}

	OutputDebug, OnFocusChanged::WinWaitNotActive
	WinWaitNotActive, %windowName%
	ReleaseAllKeys()
	OutputDebug, OnFocusChanged::end
}

ReadConfigFile()
{
	; All the variables below are declared as global so they can be used in the whole script
	global
	
	; General
	IniRead, windowName, %configFileName%, General, windowName
	IniRead, hookDelay, %configFileName%, General, hookDelay, 0
	IniRead, focusCheckDelay, %configFileName%, General, focusCheckDelay, 1000
	IniRead, textSize, %configFileName%, General, textSize, 10
	IniRead, textVisibleDelay, %configFileName%, General, textVisibleDelay, 1000
	IniRead, currentChar, %configFileName%, General, currentChar, Char0

	; Keys
	IniRead, forwardKey, %configFileName%, Keys, forwardKey, W
	IniRead, sprintKey, %configFileName%, Keys, sprintKey, LShift
	IniRead, primaryKey, %configFileName%, Keys, primaryKey, LButton
	IniRead, secondaryKey, %configFileName%, Keys, secondaryKey, RButton
	IniRead, utilityKey, %configFileName%, Keys, utilityKey, LCtrl
	IniRead, specialKey, %configFileName%, Keys, specialKey, R
	
	; Character
	IniRead, bPrimarySprint, %configFileName%, %currentChar%, bPrimarySprint, 1
	IniRead, bSecondarySprint, %configFileName%, %currentChar%, bSecondarySprint, 1
	IniRead, bUtilitySprint, %configFileName%, %currentChar%, bUtilitySprint, 1
	IniRead, bSpecialSprint, %configFileName%, %currentChar%, bSpecialSprint, 1
	IniRead, bForwardSprint, %configFileName%, %currentChar%, bForwardSprint, 1
	IniRead, bPrimaryPress, %configFileName%, %currentChar%, bPrimaryPress, 1
	IniRead, bSecondaryPress, %configFileName%, %currentChar%, bSecondaryPress, 1
	IniRead, bUtilityPress, %configFileName%, %currentChar%, bUtilityPress, 1
	IniRead, bSpecialPress, %configFileName%, %currentChar%, bSpecialPress, 1
	IniRead, primarySprintDelay, %configFileName%, %currentChar%, primarySprintDelay, 1
	IniRead, secondarySprintDelay, %configFileName%, %currentChar%, secondarySprintDelay, 1
	IniRead, utilitySprintDelay, %configFileName%, %currentChar%, utilitySprintDelay, 1
	IniRead, specialSprintDelay, %configFileName%, %currentChar%, specialSprintDelay, 1
	
	; Debug
	IniRead, bDebug, %configFileName%, Debug, bDebug, 0
	IniRead, bSound, %configFileName%, Debug, bSound, 1	
}

RegisterHotkeys()
{
	global
	
	; Fix for autoforward bug (https://autohotkey.com/board/topic/56878-keywait-not-triggering)
	Hotkey, ~%forwardKey%, pressAndSprint, % bForwardSprint ? "On" : "Off"
	Hotkey, ~%primaryKey%, % bPrimaryPress ? "pressAndSprint" : "releaseAndSprint", % bPrimarySprint ? "On" : "Off"
	Hotkey, ~%secondaryKey%, % bSecondaryPress ? "pressAndSprint" : "releaseAndSprint", % bSecondarySprint ? "On" : "Off"
	Hotkey, ~%utilityKey%, % bUtilityPress ? "pressAndSprint" : "releaseAndSprint", % bUtilitySprint ? "On" : "Off"
	Hotkey, ~%specialKey%, % bSpecialPress ? "pressAndSprint" : "releaseAndSprint", % bSpecialSprint ? "On" : "Off"
}

ReleaseAllKeys()
{
	global
	
	; Don't release keys that aren't pressed
	if (GetKeyState(primaryKey))
		SendInput % "{" . primaryKey . " up}"
	if (GetKeyState(secondaryKey))
		SendInput % "{" . secondaryKey . " up}"
	if (GetKeyState(utilityKey))
		SendInput % "{" . utilityKey . " up}"
	if (GetKeyState(specialKey))
		SendInput % "{" . specialKey . " up}"
	if (GetKeyState(forwardKey))
		SendInput % "{" . forwardKey . " up}"
}

ReloadScript()
{
	SoundBeep()
	ReleaseAllKeys()
	Reload
}

ShowOverlay(currentChar, nextChar)
{
	global textSize
	global textVisibleDelay
	global windowID
	global windowName
	
	OutputDebug, ShowOverlay::begin
	
	; Adjust the text location based on windowed mode
	WinGetPos, windowX, windowY, windowWidth, windowHeight, %windowName%
	
	if (IsWindowFullscreen(windowID))
	{
		windowX += 3
		windowY -= 2
	}
	else
	{
		windowX += 10
		windowY += 30
	}
	
	; Display white text on a transparent background
	Gui, Destroy
	Gui +LastFound +AlwaysOnTop -Caption +ToolWindow
	Gui, Color, Black
	Gui, Font, s%textSize%
	Gui, Add, Text, X0 Y0 cWhite, % "Switched from " . GetCharName(currentChar) . " to " . GetCharName(nextChar)
	WinSet, TransColor, Black 255
	Gui, Show, X%windowX% Y%windowY% NoActivate
	
	Sleep, %textVisibleDelay%
	Gui, Destroy
	
	OutputDebug, ShowOverlay::end
}

SoundBeep(ByRef pDuration := 150)
{
	global bSound
	
	if (bSound)
		SoundBeep, 1000, pDuration
}

ToggleSprint()
{
	global sprintKey
	SendInput % "{" . sprintKey . "}"
	KeyWait, %sprintKey%
}

; Exit script
ExitFunc(pExitReason, pExitCode)
{
	if (!pExitCode)
		ReleaseAllKeys()
}

; Display an error message and exit
ExitWithErrorMessage(pErrorMessage)
{
	MsgBox, 16, Error, %pErrorMessage%
	ExitApp, 1
}

; Switch to another character and reload the script
!1:: ; ALT+1
!2:: ; ALT+2
!3:: ; ALT+3
!4:: ; ALT+4
!5:: ; ALT+5
!6:: ; ALT+6
!7:: ; ALT+7
!8:: ; ALT+8
!9:: ; ALT+9
!0:: ; ALT+0
!-:: ; ALT+-

OutputDebug, SwitchChar::begin

; Strip out the modifier from the latest hotkey
thisHotkey := LTrim(A_ThisHotkey, "!")
nextChar := "Char" . thisHotkey
OutputDebug, SwitchChar::nextChar %nextChar%

; The game has too many characters to fit in 9 keys so we use some extra keys
if (nextChar = "Char0")
	nextChar := "Char10"
else if (nextChar = "Char-")
	nextChar := "Char11"

; Don't switch unless it's a different character
if (currentChar != nextChar)
{	
	SoundBeep()
	OutputDebug, SwitchChar::from %currentChar% to %nextChar%
	IniWrite, %nextChar%, %configFileName%, General, currentChar
	ShowOverlay(currentChar, nextChar)
	ReadConfigFile()
	RegisterHotkeys()
}

OutputDebug, SwitchChar::end
return

; Reload the script (useful when key states are bugged)
!F10:: ; ALT+F10

; Make this hotkey exempt from suspension
Suspend, Permit
ReloadScript()

return

; Suspend/resume the script (useful in menus)
!F11:: ; ALT+F11

Suspend
ReleaseAllKeys()

; Single beep when suspended
if (A_IsSuspended)
	SoundBeep()
; Double beep when resumed
else
{
	SoundBeep()
	SoundBeep()
}

return

; Close the script
!F12:: ; ALT+F12

; Make this hotkey exempt from suspension
Suspend, Permit
ExitApp, 0

return