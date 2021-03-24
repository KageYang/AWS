# Run following script in powershell ise as Administrator to install Ctrix and required windows features

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
    if($Invocation.PSScriptRoot)
    {
        $Invocation.PSScriptRoot;
    }
    Elseif($Invocation.MyCommand.Path)
    {
        Split-Path $Invocation.MyCommand.Path
    }

}
#defining were logfile will be created
$currentDir =  Get-ScriptDirectory
$logfile = $currentDir + "\StoreFrontInstallLog.txt"
$WinFeaturesLog = $currentDir + "\WinFeaturesLog.log"
Remove-Item $logfile -force -EA SilentlyContinue
Remove-Item $WinFeaturesLog -Force -EA SilentlyContinue
# Function Write-Log - sends the results into a logfile as well as in the PowerShell window
Function Write-Log()
{
    Param( [parameter(Mandatory = $true, ValueFromPipeline = $true)] $logEntry,
       [switch]$displaygreen,
       [switch]$error,
       [switch]$warning,
       [switch]$displaynormal,
       [switch]$displayscriptstart,
       [switch]$displayscriptend
       )
    if($error) {Write-Host "$logEntry" -Foregroundcolor Red; $logEntry = "[ERROR] $logEntry" }
    elseif($warning) {Write-Host "$logEntry" -Foregroundcolor Yellow; $logEntry = "[WARNING] $logEntry"}
    elseif ($displaynormal) {Write-Host "$logEntry" -Foregroundcolor White; $logEntry = "[INFO] $logEntry" }
    elseif($displaygreen) {Write-Host "$logEntry" -Foregroundcolor Green; $logEntry = "[SUCCESS] $logEntry" }
    elseif($displayscriptstart) {Write-Host "$logEntry" -Foregroundcolor Green; $logEntry = "[SCRIPT_START] $logEntry" }
    elseif($displayscriptend) {Write-Host "$logEntry" -Foregroundcolor Green; $logEntry = "[SCRIPT_END] $logEntry" }
    else {Write-Host "$logEntry"; $logEntry = "$logEntry" }
 
    $logEntry | Out-File $logFile -Append
}
 
#importing PowerShell modules
Import-Module ServerManager
 
 
# getting list of installed Windows Features
$InstalledFeatures = Get-WindowsFeature | where {$_.installed -eq "True"} | select name
 
# Installing prerequisites for Citrix StoreFront 
#http://docs.citrix.com/en-us/storefront/3/sf-install-standard.html
 
Write-Log "Installing Citrix StoreFront Prerequisites" -displaynormal
Write-Log "Check list at: http://docs.citrix.com/en-us/storefront/3/sf-install-standard.html" -displaynormal
 
#Defining required prerequisites: Windows Features and Role Services
$prerequisites = @(
"Web-Server",
"Web-Basic-Auth",
"Web-Http-Redirect",
"Web-Windows-Auth",
"Web-App-Dev",
"Web-Net-Ext45",
"Web-AppInit",
"Web-Asp-Net45",
"Web-Mgmt-Tools",
"Web-Scripting-Tools",
"NET-Framework-45-Features"
)
 
#installing required Windows Features and Role Services
foreach ($prerequisite in $prerequisites)
{
    if ($InstalledFeatures -match $prerequisite)
    {
       Write-Log "The following feature/role: $prerequisite is already installed on the server." -displaynormal
    }
    else
    {
       Write-Log "Installing $prerequisite on the server." -displaynormal
       $install = Add-WindowsFeature -Name $prerequisite -LogPath $WinFeaturesLog
       if ($install.ExitCode -contains "Success")
       {
            Write-Log "$prerequisite was installed on the server successfully" -displaygreen
       }
       else
       {
            Write-Log "$prerequisite was not installed properly. Please check log in: $currentDir\logfile.log" -error
            Write-Log "Script will finish in 10 seconds." -warning
            Start-Sleep -Seconds 10
            exit
       }
    }
}
 
Write-Log "Finished Installing Prerequisites. All required Windows Features/Roles were installed successfully." -displaygreen
 
# Installing Citrix StoreFront 
 
Write-Log "Installing Citrix StoreFront" -displaynormal
# Checking if StoreFront setup media exists
if ((Test-Path -Path "$currentDir\CitrixStoreFront-x64.exe") -eq $true)
{
    Write-Log "Citrix StoreFront installer was found. Installation started." -displaynormal
    start-process -FilePath "$currentDir\CitrixStoreFront-x64.exe" -ArgumentList "-silent" -wait
}
else
{
    Write-Log "No setup media for Citrix StoreFront was found. Asking for path to the installer." -warning
    $installer = Read-Host "Provide FULL path to installer of Citrix StoreFront"
 
    if ((Test-Path -Path "$installer") -eq $false)
    {
        do
        {
            Write-Log "No setup media for Citrix StoreFront 3.0.1 was found. Asking for path to the installer." -warning
            $installer = Read-Host "Provide FULL path to installer of Citrix StoreFront"
        }
        until ((Test-Path -Path "$installer") -eq $false)
    }
 
        Write-Log "Citrix StoreFront installer was found. Installation started." -displaynormal
        start-process -FilePath $installer -ArgumentList "-silent" -wait
}
#checking if last PowerShell command was executed successfully
if($?)
{
    Write-Log "The last command executed successfully. Citrix StoreFront was installed successfully." -displaygreen
}
else
{
    Write-Log "The last command failed. Citrix StoreFront was " -error
}
 
#checking logged in users
$loggedUsers = Get-WmiObject -Class win32_process -computer $env:COMPUTERNAME -Filter "name='explorer.exe'" | % { $_.GetOwner() } | select user
 
if ($loggedUsers.count -lt 2)
{
# Reboot system
 
Write-Log “Rebooting System..." -displaynormal
 
Restart-Computer -ComputerName $env:COMPUTERNAME
}
else
{
    Write-Log "There are users logged to the server. Please reboot server manually." -warning
} 
