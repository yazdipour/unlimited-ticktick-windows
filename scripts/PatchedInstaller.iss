; This is a new installer, not a reconstruction of the vendor's setup code.
[Setup]
AppId=UnlimitedTickTick.Windows.Patched
AppName=TickTick Patched
AppVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\TickTick Patched
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputBaseFilename=TickTick Unlimited
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\TickTick.exe
CloseApplications=no

[Files]
Source: "{#PayloadDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Icons]
Name: "{autoprograms}\TickTick Patched"; Filename: "{app}\TickTick.exe"
Name: "{autodesktop}\TickTick Patched"; Filename: "{app}\TickTick.exe"; Tasks: desktopicon
