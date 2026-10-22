; electron-builder includes this file in the NSIS installer. Its `protocols` setting registers the
; openbot:// scheme only on macOS and Linux, so the installer writes the Windows key itself.
; The application writes the same key at each start (`src/main/index.ts`).

!macro customInstall
  WriteRegStr SHCTX "Software\Classes\openbot" "" "URL:OpenBot invitations"
  WriteRegStr SHCTX "Software\Classes\openbot" "URL Protocol" ""
  WriteRegStr SHCTX "Software\Classes\openbot\DefaultIcon" "" "$appExe,0"
  WriteRegStr SHCTX "Software\Classes\openbot\shell\open\command" "" '"$appExe" "%1"'
!macroend

; An update runs the old uninstaller first. Keep the key then, so that links work during the update.
; Delete the key only when it still opens this copy. Another copy can own it now.
!macro customUnInstall
  ${ifNot} ${isUpdated}
    Push $0
    ReadRegStr $0 SHCTX "Software\Classes\openbot\shell\open\command" ""
    ${if} $0 == '"$INSTDIR\${APP_EXECUTABLE_FILENAME}" "%1"'
      DeleteRegKey SHCTX "Software\Classes\openbot"
    ${endIf}
    Pop $0
  ${endIf}
!macroend

; OpenBot installs for the current user only. The application writes the openbot:// key in HKCU at
; each start, and an update finds only one installation. This skips the "All users" page.
!macro customInstallMode
  StrCpy $isForceCurrentInstall "1"
!macroend

; The uninstaller and each update delete the whole installation folder. electron-builder adds an
; OpenBot subfolder only when the chosen path does not contain "OpenBot", so a choice such as
; %USERPROFILE%\OpenBot (the agent workspaces) or %APPDATA%\OpenBot (the user data) would be
; deleted. Use a folder that does not exist, is empty, or holds an earlier OpenBot installation.
; Until it does, add an OpenBot subfolder. The page shows nothing; Abort skips it.
!macro customPageAfterChangeDir
  !include FileFunc.nsh

  Page custom openBotSafeInstallDirectory

  Function openBotSafeInstallDirectory
    Push $0
    StrCpy $0 $INSTDIR 1 -1
    ${if} $0 == "\"
      StrCpy $INSTDIR $INSTDIR -1
    ${endIf}
    ${StrContains} $0 "${APP_FILENAME}" $INSTDIR
    ${if} $0 == ""
      StrCpy $INSTDIR "$INSTDIR\${APP_FILENAME}"
    ${endIf}
    ${do}
      ${if} ${FileExists} "$INSTDIR\${APP_EXECUTABLE_FILENAME}"
        ${exitDo}
      ${endIf}
      ${DirState} "$INSTDIR" $0
      ${if} $0 != 1
        ${exitDo}
      ${endIf}
      StrCpy $INSTDIR "$INSTDIR\${APP_FILENAME}"
    ${loop}
    Pop $0
    Abort
  FunctionEnd
!macroend
