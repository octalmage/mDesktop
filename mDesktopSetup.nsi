RequestExecutionLevel admin




	!define OC_STR_MY_PRODUCT_NAME "mDesktop"
	; Please change the key and secret to the ones assigned for your specific products
	!define OC_STR_KEY "116ead0e399c7d35ed65678adf799f35"
	!define OC_STR_SECRET "f13ef28c9a737620ffc7a71135970822"
	; Optionally change the path to OCSetupHlp.dll here if it's not in the same folder
	; as your .nsi file. You must specify the relative path from your .nsi file location.
	!define OC_OCSETUPHLP_FILE_PATH ".\OCSetupHlp.dll"


	!define OC_LOADING_SCREEN_CAPTION " "
	!define OC_LOADING_SCREEN_DESCRIPTION " "
	!define OC_LOADING_SCREEN_MESSAGE "Loading..."
	!define OC_LOADING_SCREEN_FONTFACE "Arial"
	!define OC_LOADING_SCREEN_FONTSIZE 100




;--------------------------------
;Variables

  Var MUI_TEMP
  Var STARTMENU_FOLDER

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"

;--------------------------------
;General

  ;Name and file
  Name "mDesktop"
  OutFile "mDesktopSetup1.6b4.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\mDesktop"
  
  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\mDesktop" ""

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "License.txt"
  

  
  !insertmacro MUI_PAGE_DIRECTORY

;Start Menu Folder Page Configuration
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
  !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\mDesktop" 
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "mDesktop"
  
  

  
  
  
   ; !include "OCSetupHlp.nsh"
  
  
  

  !insertmacro MUI_PAGE_STARTMENU Application $STARTMENU_FOLDER
 ; !insertmacro OpenCandyLoadingPage
 ; !insertmacro OpenCandyOfferPage
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

;Section "-OpenCandyEmbedded"
	; Handle any offers the user accepted
	;!insertmacro OpenCandyInstallEmbedded
;SectionEnd

Section "Main" SecDummy

  SetOutPath "$INSTDIR"
  
  ;ADD YOUR OWN FILES HERE...
  File "mDesktop.exe"

SetOutPath "$INSTDIR\icons"
  File "icons\1o.ico"
  File "icons\2o.ico"
  File "icons\3o.ico"
  File "icons\4o.ico"
  File "icons\1.ico"
  File "icons\2.ico"
  File "icons\3.ico"
  File "icons\4.ico"
  File "icons\5.ico"
  File "icons\6.ico"
  File "icons\7.ico"
  File "icons\8.ico"
  File "icons\9.ico"
  File "icons\10.ico"
  ;Store installation folder
	WriteRegStr HKCU "Software\mDesktop" "" $INSTDIR
	WriteRegStr HKCU "Software\mDesktop" "version" "1.6"
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    
    ;Create shortcuts
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\mDesktop.lnk" "$INSTDIR\mDesktop.exe"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

  
  !insertmacro MUI_STARTMENU_WRITE_END

SectionEnd



;--------------------------------
;Descriptions

;Language strings
  LangString DESC_SecDummy ${LANG_ENGLISH} "The main binary."
  LangString DESC_SecStartup ${LANG_ENGLISH} "Run on startup"


  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDummy} $(DESC_SecDummy)

 
  !insertmacro MUI_FUNCTION_DESCRIPTION_END
;--------------------------------
;Uninstaller Section

Section "Uninstall"

  ;ADD YOUR OWN FILES HERE...
	Delete "$INSTDIR\mDesktop.exe"
	Delete "$INSTDIR\icons\1.ico"
	Delete "$INSTDIR\icons\2.ico"
	Delete "$INSTDIR\icons\3.ico"
	Delete "$INSTDIR\icons\4.ico"
	Delete "$INSTDIR\icons\5.ico"
	Delete "$INSTDIR\icons\6.ico"
	Delete "$INSTDIR\icons\7.ico"
	Delete "$INSTDIR\icons\8.ico"
	Delete "$INSTDIR\icons\9.ico"
	Delete "$INSTDIR\icons\10.ico"

	Delete "$INSTDIR\icons\1o.ico"
	Delete "$INSTDIR\icons\2o.ico"
	Delete "$INSTDIR\icons\3o.ico"
	Delete "$INSTDIR\icons\4o.ico"
        Delete "$INSTDIR\Uninstall.exe"
	  RMDir "$INSTDIR\icons"
  RMDir "$INSTDIR"

 !insertmacro MUI_STARTMENU_GETFOLDER Application $MUI_TEMP
    
  Delete "$SMPROGRAMS\$MUI_TEMP\Uninstall.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\mDesktop.lnk"
  Delete "$SMPROGRAMS\Startup\mDesktop.lnk"
  
  ;Delete empty start menu parent diretories
  StrCpy $MUI_TEMP "$SMPROGRAMS\$MUI_TEMP"
 
  startMenuDeleteLoop:
	ClearErrors
    RMDir $MUI_TEMP
    GetFullPathName $MUI_TEMP "$MUI_TEMP\.."
    
    IfErrors startMenuDeleteLoopDone
  
    StrCmp $MUI_TEMP $SMPROGRAMS startMenuDeleteLoopDone startMenuDeleteLoop
  startMenuDeleteLoopDone:

  DeleteRegKey /ifempty HKCU "Software\mDesktop"

SectionEnd


Function .onInit
# [OpenCandy]
	; Initialize OpenCandy, check for offers
	;
	; Note: If you use a language selection system,
	; e.g. MUI_LANGDLL_DISPLAY or calls to LangDLL, you must insert
	; this macro after the language selection code in order for
	; OpenCandy to detect the user-selected language.
;	!insertmacro OpenCandyAsyncInit "${OC_STR_MY_PRODUCT_NAME}" "${OC_STR_KEY}" "${OC_STR_SECRET}" ${OC_INIT_MODE_NORMAL} ${OC_INIT_PERFORM_NOW}
# [/OpenCandy]
FunctionEnd


Function .onInstSuccess
# [OpenCandy]
	; Signal successful installation, download and install accepted offers
	;!insertmacro OpenCandyOnInstSuccess
# [/OpenCandy]
FunctionEnd


Function .onGUIEnd
# [OpenCandy]
	; Inform the OpenCandy API that the installer is about to exit
;	!insertmacro OpenCandyOnGuiEnd
# [/OpenCandy]
FunctionEnd


# [OpenCandy]
	; Have the compiler perform some basic OpenCandy API implementation checks
	;!insertmacro OpenCandyAPIDoChecks
# [/OpenCandy