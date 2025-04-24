

<#
powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -File "C:\scripts\0.provisionOneDriveForUser.ps1"
#>





# This is the first script to run in a new ODL. When run manually in a new ODL VM, it asks for NuGet. Let's force install it even if it exists.

if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue -Force)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
}

if (-not (Get-Module Microsoft.Online.SharePoint.PowerShell -ListAvailable)) {
    Install-Module -Name Microsoft.Online.SharePoint.PowerShell -RequiredVersion 16.0.24810.12000 -Force -Scope AllUsers -Verbose
}

Import-Module Microsoft.Online.SharePoint.PowerShell -Verbose

# Read this tenant's creds into a hashtable
$htCreds = Get-Content "C:\temp\credentials.txt" | ConvertFrom-StringData

$gaPassword = $htCreds.pwd | ConvertTo-SecureString -AsPlainText -Force

$m365Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $htCreds.Usermail, $gaPassword


# Split our tenant low-level domain name from user mail
$domain = ($htCreds.Usermail.Split("@")[1]).split(".")[0] # first split is at "@"; second split takes leftmost item, which is LLD
$spAdminUrl = "https://$($domain)-admin.sharepoint.com"
$spAdminUrl

"Connect-SPOService started"
Connect-SPOService -Url $spAdminUrl -Credential $m365Cred -Verbose
"Connect-SPOService ended"

"Request-SPOPersonalSite started"
Request-SPOPersonalSite -UserEmails $($htCreds.Usermail) -Verbose
"Request-SPOPersonalSite ended"

# Check SPO site

$oneDriveSite = Get-SPOSite -IncludePersonalSite $true -Limit all -Filter "Url -like '-my.sharepoint.com/personal/'"
while ($null -eq $oneDriveSite.Url) {
    Start-Sleep -Seconds 600
    Write-Host "$(Get-Date -Format f): OneDrive not ready: URL is null"
    $oneDriveSite = Get-SPOSite -IncludePersonalSite $true -Limit all -Filter "Url -like '-my.sharepoint.com/personal/'"
    Test-SPOSite $oneDriveSite.Url -Verbose
    Write-Host "$(Get-Date -Format f): Slept 10 minutes. URL follows, if available: $($oneDriveSite.Url)"
}

Stop-Transcript 
