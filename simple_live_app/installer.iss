; Inno Setup Script for Simple Live App
; Build: iscc installer.iss

#ifndef MyAppName
  #define MyAppName "Simple Live"
#endif

#ifndef MyAppVersion
  #define MyAppVersion "2.0.0"
#endif

#ifndef MyAppPublisher
  #define MyAppPublisher "Simple Live"
#endif

#ifndef MyAppExeName
  #define MyAppExeName "simple_live_app.exe"
#endif

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installer
OutputBaseFilename=SimpleLiveSetup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardImageFile=compiler:WizClassicImage.bmp
WizardSmallImageFile=compiler:WizClassicSmallImage.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// Check if WebView2 runtime is installed
function IsWebView2Installed(): Boolean;
var
  ResultCode: Integer;
begin
  Result := RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}') or
            RegKeyExists(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}') or
            RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}');
end;

// Download and install WebView2 runtime silently
procedure InstallWebView2;
var
  ResultCode: Integer;
  WebView2DownloadUrl: String;
  WebView2Installer: String;
begin
  WebView2DownloadUrl := 'https://go.microsoft.com/fwlink/p/?LinkId=2124703';
  WebView2Installer := ExpandConstant('{tmp}\MicrosoftEdgeWebView2Setup.exe');

  // Download WebView2
  if FileExists(WebView2Installer) then
    DeleteFile(WebView2Installer);

  // Using powershell to download
  Exec('powershell', '-Command "Invoke-WebRequest -Uri ''' + WebView2DownloadUrl + ''' -OutFile ''' + WebView2Installer + '''' , '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  // Install silently
  if FileExists(WebView2Installer) then
  begin
    Exec(WebView2Installer, '/silent /install', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Sleep(3000);
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result := True;

  // Check for WebView2
  if not IsWebView2Installed() then
  begin
    if MsgBox('WebView2 Runtime is required but not installed. Would you like to download and install it now?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      InstallWebView2();
    end else
    begin
      MsgBox('Warning: The application may not work correctly without WebView2 Runtime.', mbInformation, MB_OK);
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Ensure WebView2 is installed after installation
    if not IsWebView2Installed() then
    begin
      InstallWebView2();
    end;
  end;
end;
