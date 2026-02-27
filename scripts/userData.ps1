<powershell>

$Password = ConvertTo-SecureString "strongPassword123" -AsPlainText -Force

New-LocalUser -Name "support" -Password $Password

Set-LocalUser -Name "support" -PasswordNeverExpires $true

Add-LocalGroupMember -Group "Administrators" -Member "support"

$AdminKey = "C:\Users\Administrator\.ssh\authorized_keys"
$SupportSshDir = "C:\Users\support\.ssh"

if (Test-Path $AdminKey) {
    New-Item -ItemType Directory -Path $SupportSshDir -Force
    Copy-Item $AdminKey "$SupportSshDir\authorized_keys"
    icacls $SupportSshDir /inheritance:r
    icacls "$SupportSshDir\authorized_keys" /inheritance:r
}

</powershell>