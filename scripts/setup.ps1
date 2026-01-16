#Requires -RunAsAdministrator

$createnew = Read-Host "Create new user? [Y/N]?"
if (-not $createnew) { $createnew = "N" }
if ($CreateNew -eq 'Y') {
    $newUser = Read-Host "User to create [support]"
    if (-not $newUser) { $newUser = "support" }
    $newPass = Read-Host "User Password [strongPassword123]"
    if (-not $newPass) { $newPass = "strongPassword123" }
    try {
        Get-LocalUser -Name $newUser -ErrorAction Stop
        Write-Host "User already exists. User '$newUser' will not be created!"
    }
    catch {
        $securePass = ConvertTo-SecureString $newPass -AsPlainText -Force
        New-LocalUser -Name $newUser -Password $securePass
        Add-LocalGroupMember -Group "Administrators" -Member $newUser
        Write-Host "User '$newUser' created and added to Administrators."
    }
}
if (Get-LocalUser -Name "support" -ErrorAction SilentlyContinue) {
    Add-LocalGroupMember -Group "Administrators" -Member "support"
}
$adminPassw = Read-Host "Change admin password? [Y/N]"
if ($adminPassw -ieq 'Y') {
    $newPass = Read-Host "Admin Password [strongPassword123]"
    if (-not $newPass) { $newPass = "strongPassword123" }
    $securePass = ConvertTo-SecureString $newPass -AsPlainText -Force
    Set-LocalUser -Name "Administrator" -Password $securePass
}

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; `
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
  iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
$chocoBin = "$env:ALLUSERSPROFILE\chocolatey\bin"
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
[Environment]::SetEnvironmentVariable("PATH", "$machinePath;$chocoBin", "Machine")
$env:PATH = "$machinePath;$chocoBin"

# Modify OS Config
$global:ProgressPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
Set-TimeZone -Id "GMT Standard Time"
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
New-PSDrive -Name "HKCR" -PSProvider Registry -Root "HKEY_CLASSES_ROOT" | Out-Null
# Windows Defender Exclusions
Add-MpPreference -ExclusionPath 'C:\Program Files (x86)\Micro Focus'
Add-MpPreference -ExclusionPath 'C:\Program Files (x86)\Rocket Software'
Add-MpPreference -ExclusionPath 'C:\Program Files\Micro Focus'
Add-MpPreference -ExclusionPath 'C:\Program Files\Rocket Software'
# OpenSSH Server: Install and Start
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service sshd -StartupType Automatic
# UAC: Disable
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -Name "EnableLUA" -PropertyType DWord -Value 0 -Force
# MSI context menu: Extract MSI
New-Item -Path "HKCR:\Msi.Package\shell\extractMSI\command" -Force | Out-Null
New-ItemProperty -Path "HKCR:\Msi.Package\shell\extractMSI\command" `
    -Name "(default)" -PropertyType String `
    -Value 'msiexec /a "%1" /qb TARGETDIR="%1 Contents"' -Force
# MSI context menu: AcuSilent install
New-Item -Path "HKCR:\Msi.Package\shell\runas" -Force | Out-Null
New-ItemProperty -Path "HKCR:\Msi.Package\shell\runas" `
    -Name "(default)" -PropertyType String -Value "AcuSilent" -Force
New-Item -Path "HKCR:\Msi.Package\shell\runas\command" -Force | Out-Null
New-ItemProperty -Path "HKCR:\Msi.Package\shell\runas\command" `
    -Name "(default)" -PropertyType String `
    -Value 'msiexec /i "%1" ADDLOCAL=ALL WINDOWSVERSION=PostWindows7 /qb' -Force
# Windows Update: Defer Updates
$wuPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
New-Item -Path $wuPolicy -Force | Out-Null
New-ItemProperty -Path $wuPolicy -Name "DeferFeatureUpdates" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $wuPolicy -Name "DeferFeatureUpdatesPeriodInDays" -PropertyType DWord -Value 90 -Force
New-ItemProperty -Path $wuPolicy -Name "DeferQualityUpdates" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $wuPolicy -Name "DeferQualityUpdatesPeriodInDays" -PropertyType DWord -Value 30 -Force
# Disable Active Setup for Edge and OneDrive
New-ItemProperty `
  -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" `
  -Name "IsInstalled" -PropertyType DWord -Value 0 -Force
New-ItemProperty `
  -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" `
  -Name "IsInstalled" -PropertyType DWord -Value 0 -Force
# Set Active Hours to 00:00 - 00:00
$wu = "HKLM:\SOFTWARE\Microsoft\Windows\WindowsUpdate"
New-Item -Path $wu -Force | Out-Null
New-ItemProperty -Path $wu -Name "SetActiveHours" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $wu -Name "ActiveHoursStart" -PropertyType DWord -Value 0 -Force
New-ItemProperty -Path $wu -Name "ActiveHoursEnd" -PropertyType DWord -Value 0 -Force
# File Explorer: Show File Extensions and Hidden Files
$explorer = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
New-ItemProperty -Path $explorer -Name "HideFilesExt" -PropertyType DWord -Value 0 -Force
New-ItemProperty -Path $explorer -Name "Hidden" -PropertyType DWord -Value 0 -Force
# DNS Settings
$n = (Get-NetAdapter | Where-Object Name -like '*Ether*').Name
Set-DNSClientServerAddress "$n" -ServerAddresses ("1.1.1.1","1.0.0.1")
Set-DNSClientServerAddress "$n" -ServerAddresses ("2606:4700:4700::1111","2606:4700:4700::1001")
# Disable Windows Defender Real-Time Monitoring
Set-MpPreference -DisableRealtimeMonitoring $true

# Install Software
choco feature enable -n=allowGlobalConfirmation
choco install firefox
choco install procmon
choco install procexp
choco install vcredist140
choco install 7zip 
choco install winscp
choco install notepadplusplus 
choco install jq
choco install yq
choco install cascadiamono
choco install ntop.portable
choco install psql
choco install psqlodbc
choco install openjdk
choco install python
choco install clink-maintained
choco install fio
choco install kubernetes-cli
choco install vscode --params "/NoDesktopIcon"
# choco install visualstudio2017professional
# choco install visualstudio2019professional
# choco install visualstudio2022professional
# Package Parameters for VS
# --package-parameters "--wait --quiet --norestart --add Microsoft.Net.Component.4.5.TargetingPack --add Microsoft.Net.Component.4.5.2.TargetingPack --add Microsoft.Net.Component.4.7.2.TargetingPack --add Microsoft.VisualStudio.Component.Debugger.JustInTime --add Microsoft.VisualStudio.Component.GraphDocument --add Microsoft.VisualStudio.Component.NuGet --add Microsoft.VisualStudio.Component.Windows10SDK.18362 --add Microsoft.VisualStudio.Component.DockerTools --add Microsoft.VisualStudio.Component.VisualStudioData --add Microsoft.VisualStudio.Component.Web --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.Azure --add Microsoft.VisualStudio.Component.Wcf.Tooling --add Microsoft.VisualStudio.Component.SQL.SSDT --add Microsoft.VisualStudio.Workload.NetCoreTools --downloadThenInstall"
# choco install microsoft-windows-terminal
# choco install dotnet
# choco install windows-sdk-11-version-22h2-all
# choco install visualstudio2017buildtools
# choco install powertoys
# choco install office365business
# choco install adobereader
# choco install linkshellextension
# choco install dotpeek
# choco install tinytask
# choco install speedtest
# choco install clumsy

# Configure Clink
$clinkPath = "C:\Program Files (x86)\clink"
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($machinePath -notlike "*$clinkPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$machinePath;$clinkPath", "Machine")
}
$env:PATH = "$machinePath;$clinkPath"
& "$clinkPath\clink" autorun -a install
& "$clinkPath\clink" set clink.logo none
$currentPathExt = [Environment]::GetEnvironmentVariable("PATHEXT", "Machine")
if ($currentPathExt -notlike "*.MSI*" -or $currentPathExt -notlike "*.PS1*") {
    [Environment]::SetEnvironmentVariable(
        "PATHEXT",
        "$currentPathExt;.MSI;.PS1",
        "Machine"
    )
}
$env:PATHEXT = "$currentPathExt;.MSI;.PS1"

# VS Code: Install Extensions and Settings
$codePath = "C:\Program Files\Microsoft VS Code\bin"
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$env:PATH = "$machinePath;$codePath"
$extensions = @(
    "zhuangtongfa.material-theme",
    "rocketsoftware.rocket-enterprise",
    "rocketsoftware.rocket-acucobolgt",
    "humao.rest-client",
    "ms-vscode.hexeditor"
)
foreach ($ext in $extensions) {
    & code --install-extension $ext
}
$vsCodeUser = Join-Path $env:APPDATA "Code\User"
$settingsUrl = "https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/win/vscode/settings.json"
$keybindingsUrl = "https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/win/vscode/keybindings.json"
New-Item -ItemType Directory -Path $vsCodeUser -Force | Out-Null
Invoke-WebRequest -Uri $settingsUrl -OutFile (Join-Path $vsCodeUser "settings.json")
Invoke-WebRequest -Uri $keybindingsUrl -OutFile (Join-Path $vsCodeUser "keybindings.json")

# Install Oracle Instant Client
$temp = 'C:\Users\Public\Documents'
$urls = @(
  'https://download.oracle.com/otn_software/nt/instantclient/2118000/instantclient-basic-nt-21.18.0.0.0dbru.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2118000/instantclient-odbc-nt-21.18.0.0.0dbru.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2118000/instantclient-sqlplus-nt-21.18.0.0.0dbru.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2118000/instantclient-sdk-nt-21.18.0.0.0dbru.zip'
  'https://mturner.s3.eu-west-2.amazonaws.com/Public/Oracle/InstantClient/21/instantclient-precomp-nt-21.18.0.0.0dbru.zip'
)
$dest = 'C:\instantClient32'
foreach ($url in $urls) {
    $file = Join-Path $temp (Split-Path $url -Leaf)
    Invoke-WebRequest -Uri $url -OutFile $file
    Expand-Archive -LiteralPath $file -DestinationPath $dest -Force
}
$urls = @(
  'https://download.oracle.com/otn_software/nt/instantclient/2326000/instantclient-basic-windows.x64-23.26.0.0.0.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2326000/instantclient-odbc-windows.x64-23.26.0.0.0.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2326000/instantclient-sqlplus-windows.x64-23.26.0.0.0.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2326000/instantclient-sdk-windows.x64-23.26.0.0.0.zip'
  'https://mturner.s3.eu-west-2.amazonaws.com/Public/Oracle/InstantClient/23/instantclient-precomp-windows.x64-23.26.0.0.0.zip'
)
$dest = 'C:\instantClient64'
foreach ($url in $urls) {
    $file = Join-Path $temp (Split-Path $url -Leaf)
    Invoke-WebRequest -Uri $url -OutFile $file
    Expand-Archive -LiteralPath $file -DestinationPath $dest -Force
}

Start-Process `
  -FilePath "C:\instantClient32\instantclient_21_18\odbc_install.exe" `
  -WorkingDirectory "C:\instantClient32\instantclient_21_18" `
  -Wait
Start-Process `
  -FilePath "C:\instantClient64\instantclient_23_0\odbc_install.exe" `
  -WorkingDirectory "C:\instantClient64\instantclient_23_0" `
  -Wait
$pathsToAdd = @(
    "C:\instantClient32\instantclient_21_18"
    "C:\instantClient32\instantclient_21_18\sdk"
)
$machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
foreach ($p in $pathsToAdd) {
    if ($machinePath -notlike "*$p*") {
        $machinePath += ";$p"
    }
}
[Environment]::SetEnvironmentVariable("PATH", $machinePath, "Machine")

# DB2 Client
$db2Url = "https://mturner.s3.eu-west-2.amazonaws.com/Public/DB2/v11.5.9_ntx64_client.exe"
$db2Dest = "C:\Users\Public\Documents\v11.5.9_ntx64_client.exe"
Invoke-WebRequest -Uri $db2Url -OutFile $db2Dest
$rspPath = "C:\Users\Public\Documents\db2.win.rsp"
$rspContent = @"
PROD=CLIENT
LIC_AGREEMENT=ACCEPT
FILE=C:\Program Files\IBM\SQLLIB_01\
INSTALL_TYPE=CUSTOM
COMP=BASE_CLIENT
COMP=DOTNET_DATA_PROVIDER
COMP=JDBC_SUPPORT
COMP=ODBC_SUPPORT
COMP=OLE_DB_SUPPORT
COMP=SQLJ_SUPPORT
LANG=EN
INSTANCE=DB2
DB2.NAME=DB2
DEFAULT_INSTANCE=DB2
DB2.TYPE=CLIENT
DB2_EXTSECURITY=NO
DB2_COMMON_APP_DATA_TOP_PATH=C:\ProgramData
DB2_COPY_NAME=DB2
DEFAULT_COPY=YES
DEFAULT_CLIENT_INTERFACE_COPY=YES
"@
$rspContent | Set-Content -Path $rspPath -Encoding ASCII
$target = "C:\Users\Public\Documents"
Start-Process `
    -FilePath "C:\Users\Public\Documents\v11.5.9_ntx64_client.exe" `
    -ArgumentList "/auto", "`"$target`"" `
    -WorkingDirectory "C:\Users\Public\Documents" `
    -Wait
Start-Process `
    -FilePath "C:\Users\Public\Documents\CLIENT\setup.exe" `
    -ArgumentList "-u", "db2.win.rsp" `
    -WorkingDirectory $target `
    -Wait

# MQ Client
$dest = "C:\Program Files\IBM\MQ"
$url  = "https://mturner.s3.eu-west-2.amazonaws.com/Public/MQ/9.3.5.0-IBM-MQC-Redist-Win64.zip"
$zip = Join-Path $dest (Split-Path $url -Leaf)
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Invoke-WebRequest -Uri $url -OutFile $zip
Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force

# Create Support Files and Directories
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Everyone",
    "FullControl",
    "Allow"
)
$folders = @(
    "C:\temp",
    "C:\etc",
    "C:\AcuSupport",
    "C:\AcuResources",
    "C:\AcuDataFiles",
    "C:\AcuSamples",
    "C:\AcuInstallers",
    "C:\AcuScripts",
    "C:\AcuLogs"
)
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $acl = Get-Acl $folder
    $acl.SetAccessRule($rule)
    Set-Acl -Path $folder $acl
    
}
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/AcuScripts/setenvacu.cmd" `
  -OutFile "C:\AcuScripts\setenvacu.cmd"
$urls = @(
  'https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/etc/AcuThin-AutoUpdate.cfg'
  'https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/etc/a_srvcfg'
  'https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/etc/acurcl.cfg'
  'https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/etc/acurcl.ini'
  'https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/etc/boomerang.cfg'
  'https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/etc/boomerang_alias.ini'
  'https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/etc/cblconfi'
  'https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/etc/fillCombo.js'
  'https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/etc/gateway.conf'
  'https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/windows/etc/gateway.toml'
)
$dest = 'C:\etc'
foreach ($url in $urls) {
    $file = Join-Path $dest (Split-Path $url -Leaf)
    Invoke-WebRequest -Uri $url -OutFile $file
}

$folders = @(
    "C:\MFSupport",
    "C:\MFSamples",
    "C:\MFSamples\JCL",
    "C:\MFSamples\CICS",
    "C:\MFSamples\CICS\loadlib",
    "C:\MFSamples\CICS\system",
    "C:\MFSamples\CICS\dataset",
    "C:\MFSamples\CICS\catalog",
    "C:\MFDataFiles"
    "C:\MFInstallers"
    "C:\MFScripts"
    "C:\CTF"
    "C:\CTF\TEXT"
    "C:\CTF\BIN"
)
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $acl = Get-Acl $folder
    $acl.SetAccessRule($rule)
    Set-Acl -Path $folder $acl
}
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/ctf.cfg" `
  -OutFile "C:\CTF\ctf.cfg"
$urls = @(
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/JCL.xml'
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/JCL.zip'
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/docs/es/MFBSI.cfg'
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/docs/es/VSE.cfg'
)
$dest = 'C:\MFSamples\JCL'
foreach ($url in $urls) {
    $file = Join-Path $dest (Split-Path $url -Leaf)
    Invoke-WebRequest -Uri $url -OutFile $file
}
$zip = Join-Path $dest 'JCL.zip'
Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force
$urls = @(
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/setenvmf.cmd'
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/MFESDIAGS.cmd'
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/FormatDumps.cmd'
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/AutoPAC.cmd'
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/disableSecurity.cmd'
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/VSMOD.cmd'
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/VSFIX.cmd'
    'https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/CTFdump.zip'
)
$dest = 'C:\MFScripts'
foreach ($url in $urls) {
    $file = Join-Path $dest (Split-Path $url -Leaf)
    Invoke-WebRequest -Uri $url -OutFile $file
}
$zip = Join-Path $dest 'CTFdump.zip'
Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force

$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
[Environment]::SetEnvironmentVariable("Path", "C:\AcuScripts;C:\MFScripts;C:\MFScripts\CTFdump;$machinePath", "Machine")

# AutoShutdown
$action = New-ScheduledTaskAction `
    -Execute "shutdown.exe" `
    -Argument "/s /f /t 1800"
$trigger = New-ScheduledTaskTrigger `
    -Daily `
    -At 8:00pm
Register-ScheduledTask `
    -TaskName "AutoShutdown" `
    -Action $action `
    -Trigger $trigger `
    -User "SYSTEM" `
    -RunLevel Highest `
    -Force
Get-ScheduledTask | Where {$_.TaskName -eq "AutoShutdown"} | Disable-ScheduledTask

# Pin folders to Home / Quick Access
$shell = New-Object -ComObject Shell.Application
$folders = @(
    "C:\temp",
    "C:\AcuSamples",
    "C:\AcuScripts",
    "C:\AcuSupport",
    "C:\etc",
    "C:\MFSamples",
    "C:\MFScripts",
    "C:\MFSupport",
    "C:\CTF"
)
foreach ($folder in $folders) {
    $shell.Namespace($folder).Self.InvokeVerb("pintohome")
}