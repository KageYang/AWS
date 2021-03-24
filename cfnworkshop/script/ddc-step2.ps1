#==========================================================================
#
# Install Citrix Delivery Controller
#
# AUTHOR: Dennis Span (https://dennisspan.com)
# DATE  : 05.04.2017
#
# COMMENT:
# This script has been prepared for Windows Server 2008 R2, 2012 R2 and 2016
#
# This script only installs the Citrix Delivery Controller. It does not configure it.
# The version of XenDesktop used in this script is 7.16 (released in Q4 2017). 
# Versions 7.13 to 7.15 have been tested as well.
#          
#==========================================================================

# Get the script parameters if there are any
param
(
    # The only parameter which is really required is 'Uninstall'
    # If no parameters are present or if the parameter is not
    # 'uninstall', an installation process is triggered
    [string]$Installationtype
)

# define Error handling
# note: do not change these values
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

# FUNCTION DS_WriteLog
#==========================================================================
Function DS_WriteLog {
    <#
        .SYNOPSIS
        Write text to this script's log file
        .DESCRIPTION
        Write text to this script's log file
        .PARAMETER InformationType
        This parameter contains the information type prefix. Possible prefixes and information types are:
            I = Information
            S = Success
            W = Warning
            E = Error
            - = No status
        .PARAMETER Text
        This parameter contains the text (the line) you want to write to the log file. If text in the parameter is omitted, an empty line is written.
        .PARAMETER LogFile
        This parameter contains the full path, the file name and file extension to the log file (e.g. C:\Logs\MyApps\MylogFile.log)
        .EXAMPLE
        DS_WriteLog -InformationType "I" -Text "Copy files to C:\Temp" -LogFile "C:\Logs\MylogFile.log"
        Writes a line containing information to the log file
        .Example
        DS_WriteLog -InformationType "E" -Text "An error occurred trying to copy files to C:\Temp (error: $($Error[0]))" -LogFile "C:\Logs\MylogFile.log"
        Writes a line containing error information to the log file
        .Example
        DS_WriteLog -InformationType "-" -Text "" -LogFile "C:\Logs\MylogFile.log"
        Writes an empty line to the log file
    #>
    [CmdletBinding()]
	Param( 
        [Parameter(Mandatory=$true, Position = 0)][String]$InformationType,
        [Parameter(Mandatory=$true, Position = 1)][AllowEmptyString()][String]$Text,
        [Parameter(Mandatory=$true, Position = 2)][AllowEmptyString()][String]$LogFile
    )

	$DateTime = (Get-Date -format dd-MM-yyyy) + " " + (Get-Date -format HH:mm:ss)
	
    if ( $Text -eq "" ) {
        Add-Content $LogFile -value ("") # Write an empty line
    } Else {
	    Add-Content $LogFile -value ($DateTime + " " + $InformationType + " - " + $Text)
    }
}
#==========================================================================

# FUNCTION DS_InstallOrUninstallSoftware
#==========================================================================
Function DS_InstallOrUninstallSoftware {
     <#
        .SYNOPSIS
        Install or uninstall software (MSI or SETUP.exe)
        .DESCRIPTION
        Install or uninstall software (MSI or SETUP.exe)
        .PARAMETER File
        This parameter contains the file name including the path and file extension, for example C:\Temp\MyApp\Files\MyApp.msi or C:\Temp\MyApp\Files\MyApp.exe.
        .PARAMETER Installationtype
        This parameter contains the installation type, which is either 'Install' or 'Uninstall'.
        .PARAMETER Arguments
        This parameter contains the command line arguments. The arguments list can remain empty.
        In case of an MSI, the following parameters are automatically included in the function and do not have
        to be specified in the 'Arguments' parameter: /i (or /x) /qn /norestart /l*v "c:\Logs\MyLogFile.log"
        .EXAMPLE
        DS_InstallOrUninstallSoftware -File "C:\Temp\MyApp\Files\MyApp.msi" -InstallationType "Install" -Arguments ""
        Installs the MSI package 'MyApp.msi' with no arguments (the function already includes the following default arguments: /i /qn /norestart /l*v $LogFile)
        .Example
        DS_InstallOrUninstallSoftware -File "C:\Temp\MyApp\Files\MyApp.msi" -InstallationType "Uninstall" -Arguments ""
        Uninstalls the MSI package 'MyApp.msi' (the function already includes the following default arguments: /x /qn /norestart /l*v $LogFile)
        .Example
        DS_InstallOrUninstallSoftware -File "C:\Temp\MyApp\Files\MyApp.exe" -InstallationType "Install" -Arguments "/silent /logfile:C:\Logs\MyApp\log.log"
        Installs the SETUP file 'MyApp.exe'
    #>
    [CmdletBinding()]
	Param( 
        [Parameter(Mandatory=$true, Position = 0)][String]$File,
        [Parameter(Mandatory=$true, Position = 1)][AllowEmptyString()][String]$Installationtype,
        [Parameter(Mandatory=$true, Position = 2)][AllowEmptyString()][String]$Arguments
    )
    
    
    $FileName = ($File.Split("\"))[-1]
    $FileExt = $FileName.SubString(($FileName.Length)-3,3)

    # Prepare variables
    if ( !( $FileExt -eq "MSI") ) { $FileExt = "SETUP" }
    if ( $Installationtype -eq "Uninstall" ) {
        $Result1 = "uninstalled"
        $Result2 = "uninstallation"
    } else {
        $Result1 = "installed"
        $Result2 = "installation"
    }
    $LogFileAPP = Join-path $LogDir ( "$($Installationtype)_$($FileName.Substring(0,($FileName.Length)-4))_$($FileExt).log" )
     
    # Logging
    DS_WriteLog "I" "File name: $FileName" $LogFile
    DS_WriteLog "I" "File full path: $File" $LogFile
    if ([string]::IsNullOrEmpty($Arguments)) {   # check if custom arguments were defined
        DS_WriteLog "I" "File arguments: <no arguments defined>" $LogFile
    } Else {
        DS_WriteLog "I" "File arguments: $Arguments" $LogFile
    }

    # Install the MSI or SETUP.exe
    DS_WriteLog "-" "" $LogFile
    DS_WriteLog "I" "Start the $Result2" $LogFile
    if ( $FileExt -eq "MSI" ) {
        if ( $Installationtype -eq "Uninstall" ) {
            $FixedArguments = "/x ""$File"" /qn /norestart /l*v ""$LogFileAPP"""
        } else {
            $FixedArguments = "/i ""$File"" /qn /norestart /l*v ""$LogFileAPP"""
        }
        if ([string]::IsNullOrEmpty($Arguments)) {   # check if custom arguments were defined
            $arguments = $FixedArguments
            DS_WriteLog "I" "Command line: Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru" $LogFile
            $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru
        } Else {
            $arguments =  $FixedArguments + " " + $arguments
            DS_WriteLog "I" "Command line: Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru" $LogFile
            $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru
        }
    } Else {
        if ([string]::IsNullOrEmpty($Arguments)) {   # check if custom arguments were defined
            DS_WriteLog "I" "Command line: Start-Process -FilePath ""$File"" -Wait -PassThru" $LogFile
            $process = Start-Process -FilePath "$File" -Wait -PassThru
        } Else {
            DS_WriteLog "I" "Command line: Start-Process -FilePath ""$File"" -ArgumentList $arguments -Wait -PassThru" $LogFile
            $process = Start-Process -FilePath "$File" -ArgumentList $arguments -Wait -PassThru
        }
    }

    # Check the result (the exit code) of the installation
    switch ($Process.ExitCode)
    {        
        0 { DS_WriteLog "S" "The software was $Result1 successfully (exit code: 0)" $LogFile }
        3 { DS_WriteLog "S" "The software was $Result1 successfully (exit code: 3)" $LogFile } # Some Citrix products exit with 3 instead of 0
        1603 { DS_WriteLog "E" "A fatal error occurred (exit code: 1603). Some applications throw this error when the software is already (correctly) installed! Please check." $LogFile }
        1605 { DS_WriteLog "I" "The software is not currently installed on this machine (exit code: 1605)" $LogFile }
        3010 { DS_WriteLog "W" "A reboot is required (exit code: 3010)!" $LogFile }
        default { 
            [string]$ExitCode = $Process.ExitCode
            DS_WriteLog "E" "The $Result2 ended in an error (exit code: $ExitCode)!" $LogFile
            Exit 1
        }
    }
}
#==========================================================================


################
# Main section #
################

# Disable File Security
$env:SEE_MASK_NOZONECHECKS = 1

# Custom variables [edit]
$BaseLogDir = "C:\Logs"                                         # [edit] add the location of your log directory here
$PackageName = "Citrix Delivery Controller (installation)"      # [edit] enter the display name of the software (e.g. 'Arcobat Reader' or 'Microsoft Office')

# Global variables
$StartDir = $PSScriptRoot # the directory path of the script currently being executed
if (!($Installationtype -eq "Uninstall")) { $Installationtype = "Install" }
$LogDir = (Join-Path $BaseLogDir $PackageName).Replace(" ","_")
$LogFileName = "$($Installationtype)_$($PackageName).log"
$LogFile = Join-path $LogDir $LogFileName

# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }

# Create new log file (overwrite existing one)
New-Item $LogFile -ItemType "file" -force | Out-Null

DS_WriteLog "I" "START SCRIPT - $Installationtype $PackageName" $LogFile
DS_WriteLog "-" "" $LogFile

#################################################
# INSTALL CITRIX DELIVERY CONTROLLER            #
#################################################

DS_WriteLog "I" "Install the Citrix Delivery Controller" $LogFile

DS_WriteLog "-" "" $LogFile

$File = Join-Path $StartDir "Files\x64\XenDesktop Setup\XenDesktopServerSetup.exe"
$Arguments = "/components controller,desktopstudio /configure_firewall /nosql /noreboot /quiet /logpath ""$LogDir"""
DS_InstallOrUninstallSoftware -File $File -InstallationType "Install" -Arguments $Arguments

# Enable File Security  
Remove-Item env:\SEE_MASK_NOZONECHECKS

DS_WriteLog "-" "" $LogFile
DS_WriteLog "I" "End of script" $LogFile
