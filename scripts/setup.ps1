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
try {
    Get-LocalUser -Name "support" -ErrorAction Stop
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
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('http://internal/odata/repo/ChocolateyInstall.ps1'))
$chocoBin = "$env:ALLUSERSPROFILE\chocolatey\bin"
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
[Environment]::SetEnvironmentVariable("PATH", "$machinePath;$chocoBin", "Machine")

# Modify OS Config
Set-TimeZone -Id "GMT Standard Time"
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Add-MpPreference -ExclusionPath 'C:\Program Files (x86)\Micro Focus'
Add-MpPreference -ExclusionPath 'C:\Program Files (x86)\Rocket Software'
Add-MpPreference -ExclusionPath 'C:\Program Files\Micro Focus'
Add-MpPreference -ExclusionPath 'C:\Program Files\Rocket Software'
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service sshd -StartupType Automatic
# ---------- UAC ----------
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -Name "EnableLUA" -PropertyType DWord -Value 0 -Force
# ---------- MSI context menu: Extract ----------
New-Item -Path "HKCR:\Msi.Package\shell\extractMSI\command" -Force | Out-Null
New-ItemProperty -Path "HKCR:\Msi.Package\shell\extractMSI\command" `
    -Name "(default)" -PropertyType String `
    -Value 'msiexec /a "%1" /qb TARGETDIR="%1 Contents"' -Force
# ---------- MSI context menu: Run as admin ----------
New-Item -Path "HKCR:\Msi.Package\shell\runas" -Force | Out-Null
New-ItemProperty -Path "HKCR:\Msi.Package\shell\runas" `
    -Name "(default)" -PropertyType String -Value "AcuSilent" -Force
New-Item -Path "HKCR:\Msi.Package\shell\runas\command" -Force | Out-Null
New-ItemProperty -Path "HKCR:\Msi.Package\shell\runas\command" `
    -Name "(default)" -PropertyType String `
    -Value 'msiexec /i "%1" ADDLOCAL=ALL WINDOWSVERSION=PostWindows7 /qb' -Force
# ---------- Windows Update deferrals ----------
$wuPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
New-Item -Path $wuPolicy -Force | Out-Null
New-ItemProperty -Path $wuPolicy -Name "DeferFeatureUpdates" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $wuPolicy -Name "DeferFeatureUpdatesPeriodInDays" -PropertyType DWord -Value 90 -Force
New-ItemProperty -Path $wuPolicy -Name "DeferQualityUpdates" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $wuPolicy -Name "DeferQualityUpdatesPeriodInDays" -PropertyType DWord -Value 30 -Force
# ---------- Active Setup ----------
New-ItemProperty `
  -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" `
  -Name "IsInstalled" -PropertyType DWord -Value 0 -Force
New-ItemProperty `
  -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" `
  -Name "IsInstalled" -PropertyType DWord -Value 0 -Force
# ---------- Windows Update Active Hours ----------
$wu = "HKLM:\SOFTWARE\Microsoft\Windows\WindowsUpdate"
New-Item -Path $wu -Force | Out-Null
New-ItemProperty -Path $wu -Name "SetActiveHours" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $wu -Name "ActiveHoursStart" -PropertyType DWord -Value 0 -Force
New-ItemProperty -Path $wu -Name "ActiveHoursEnd" -PropertyType DWord -Value 0 -Force
# ---------- Explorer options (current user) ----------
$explorer = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
New-ItemProperty -Path $explorer -Name "HideFilesExt" -PropertyType DWord -Value 0 -Force
New-ItemProperty -Path $explorer -Name "Hidden" -PropertyType DWord -Value 0 -Force
$n=(Get-NetAdapter | where name -like '*Ether*').Name; netsh interface ip set dns name=\"$n\" static 1.1.1.1
$n=(Get-NetAdapter | where name -like '*Ether*').Name; netsh interface ip add dns name=\"$n\" 1.0.0.1 index=2
$n=(Get-NetAdapter | where name -like '*Ether*').Name; netsh interface ipv6 set dns name=\"$n\" static 2606:4700:4700::1111
$n=(Get-NetAdapter | where name -like '*Ether*').Name; netsh interface ipv6 add dns name=\"$n\" 2606:4700:4700::1001 index=2
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

$clinkPath = "C:\Program Files (x86)\clink"
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($machinePath -notlike "*$clinkPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$machinePath;$clinkPath", "Machine")
}
& "$clinkPath\clink.exe" autorun -a install

& "$clinkPath\clink.exe" set clink.logo none
$currentPathExt = [Environment]::GetEnvironmentVariable("PATHEXT", "Machine")
if ($currentPathExt -notlike "*.MSI*") {
    [Environment]::SetEnvironmentVariable(
        "PATHEXT",
        "$currentPathExt;.MSI",
        "Machine"
    )
}

$codeExe = "C:\Program Files\Microsoft VS Code\bin\code.exe"
$extensions = @(
    "zhuangtongfa.material-theme",
    "rocketsoftware.rocket-enterprise",
    "rocketsoftware.rocket-acucobolgt",
    "rangav.humao.rest-client",
    "ms-vscode.hexeditor"
)
foreach ($ext in $extensions) {
    & $codeExe --install-extension $ext
}
$vsCodeUser = Join-Path $env:APPDATA "Code\User"
$settingsUrl = "https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/win/vscode/settings.json"
$keybindingsUrl = "https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/win/vscode/keybindings.json"
Invoke-WebRequest -Uri $settingsUrl -OutFile (Join-Path $vsCodeUser "settings.json")
Invoke-WebRequest -Uri $keybindingsUrl -OutFile (Join-Path $vsCodeUser "keybindings.json")

# DB2 Client
$db2Url = "https://mturner.s3.eu-west-2.amazonaws.com/Public/DB2/v11.5.9_ntx64_client.exe"
$db2Dest = "C:\Users\Public\Documents\v11.5.9_ntx64_client.exe"
Invoke-WebRequest -Uri $db2Url -OutFile $db2Dest




# Install Oracle Instant Client
$temp = 'C:\Users\Public\Documents'
$urls = @(
  'https://download.oracle.com/otn_software/nt/instantclient/2115000/instantclient-basic-nt-21.15.0.0.0dbru.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2115000/instantclient-odbc-nt-21.15.0.0.0dbru.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2115000/instantclient-sqlplus-nt-21.15.0.0.0dbru.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2115000/instantclient-sdk-nt-21.15.0.0.0dbru.zip'
  'https://mturner.s3.eu-west-2.amazonaws.com/Public/Oracle/InstantClient/21/instantclient-precomp-nt-21.15.0.0.0dbru.zip'
)
$dest = 'C:\instantClient32'
foreach ($url in $urls) {
    $file = Join-Path $temp (Split-Path $url -Leaf)
    Invoke-WebRequest -Uri $url -OutFile $file
    Expand-Archive -LiteralPath $file -DestinationPath $dest -Force
}
$urls = @(
  'https://download.oracle.com/otn_software/nt/instantclient/2115000/instantclient-basic-windows.x64-21.15.0.0.0dbru.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2115000/instantclient-odbc-windows.x64-21.15.0.0.0dbru.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2115000/instantclient-sqlplus-windows.x64-21.15.0.0.0dbru.zip'
  'https://download.oracle.com/otn_software/nt/instantclient/2115000/instantclient-sdk-windows.x64-21.15.0.0.0dbru.zip'
  'https://mturner.s3.eu-west-2.amazonaws.com/Public/Oracle/InstantClient/21/instantclient-precomp-windows.x64-21.15.0.0.0dbru.zip'
)
$dest = 'C:\instantClient64'
foreach ($url in $urls) {
    $file = Join-Path $temp (Split-Path $url -Leaf)
    Invoke-WebRequest -Uri $url -OutFile $file
    Expand-Archive -LiteralPath $file -DestinationPath $dest -Force
}

& "C:\instantClient32\instantclient_21_15\odbc_install.exe"
& "C:\instantClient64\instantclient_21_15\odbc_install.exe"
$pathsToAdd = @(
    "C:\instantClient32\instantclient_21_15"
    "C:\instantClient32\instantclient_21_15\sdk"
)
$machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
foreach ($p in $pathsToAdd) {
    if ($machinePath -notlike "*$p*") {
        $machinePath += ";$p"
    }
}
[Environment]::SetEnvironmentVariable("PATH", $machinePath, "Machine")