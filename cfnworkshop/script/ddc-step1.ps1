#==========================================================================
#
# Installation of Microsoft Roles and Features for Citrix Delivery Controller
#
# AUTHOR: Dennis Span (https://dennisspan.com)
# DATE  : 16.03.2017
#
# COMMENT:
#   This script installs the following roles:
#   -.Net Framework 3.5 (W2K8R2 only)
#   -.Net Framework 4.6 (W2K12 + W2K16)
#   -Desktop experience (W2K8R2 + W2K12)
#   -Group Policy Management Console
#   -Remote Server Administration Tools (AD DS Snap-Ins)
#   -Remote Desktop Licensing Tools
#   -Telnet Client
#   -Windows Process Activation Service
#
# This script has been prepared for Windows Server 2008 R2, 2012 R2 and 2016.
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

################
# Main section #
################

# Disable File Security
$env:SEE_MASK_NOZONECHECKS = 1

# Custom variables [edit]
$BaseLogDir = "C:\Logs"                                # [edit] add the location of your log directory here
$PackageName = "Citrix Delivery Controller Roles"      # [edit] enter the display name of the software (e.g. 'Arcobat Reader' or 'Microsoft Office')

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
# INSTALL MICROSOFT ROLES AND FEATURES          #
#################################################

DS_WriteLog "I" "Add Windows roles and features:" $LogFile
DS_WriteLog "I" "-.Net Framework 3.5 (W2K8R2 only)" $LogFile
DS_WriteLog "I" "-.Net Framework 4.6 (W2K12 + W2K16)" $LogFile
DS_WriteLog "I" "-Desktop experience (W2K8R2 + W2K12)" $LogFile
DS_WriteLog "I" "-Group Policy Management Console" $LogFile
DS_WriteLog "I" "-Remote Server Administration Tools (AD DS Snap-Ins)" $LogFile
DS_WriteLog "I" "-Remote Desktop Licensing Tools" $LogFile
DS_WriteLog "I" "-Telnet Client" $LogFile
DS_WriteLog "I" "-Windows Process Activation Service" $LogFile

DS_WriteLog "-" "" $LogFile

DS_WriteLog "I" "Retrieve the OS version and name" $LogFile

# Check the windows version
# URL: https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_versions
# -Windows Server 2016    -> NT 10.0
# -Windows Server 2012 R2 -> NT 6.3
# -Windows Server 2012    -> NT 6.2
# -Windows Server 2008 R2 -> NT 6.1
# -Windows Server 2008	  -> NT 6.0
[string]$WindowsVersion = ( Get-WmiObject -class Win32_OperatingSystem ).Version
switch -wildcard ($WindowsVersion)
    { 
        "*10*" { 
                $OSVER = "W2K16"
                $OSName = "Windows Server 2016"
                $LogFile2 = Join-Path $LogDir "Install_RolesAndFeatures.log"

                DS_WriteLog "I" "The current operating system is $($OSNAME) ($($OSVER))" $LogFile
                DS_WriteLog "-" "" $LogFile
                DS_WriteLog "I" "Roles and Features installation log file: $LogFile2" $LogFile
                DS_WriteLog "I" "Start the installation ..." $LogFile

                # Install Windows Features
                try {
                    Install-WindowsFeature NET-Framework-45-Core,GPMC,RSAT-ADDS-Tools,RDS-Licensing-UI,WAS,Telnet-Client -logpath $LogFile2
                    DS_WriteLog "S" "The windows features were installed successfully!" $LogFile
                } catch {
                    DS_WriteLog "E" "An error occurred while installing the windows features (error: $($error[0]))" $LogFile
                    Exit 1
                }
            } 
        "*6.3*" { 
                $OSVER = "W2K12R2"
                $OSName = "Windows Server 2012 R2"
                $LogFile2 = Join-Path $LogDir "Install_RolesAndFeatures.log"

                DS_WriteLog "I" "The current operating system is $($OSNAME) ($($OSVER))" $LogFile
                DS_WriteLog "-" "" $LogFile
                DS_WriteLog "I" "Roles and Features installation log file: $LogFile2" $LogFile
                DS_WriteLog "I" "Start the installation ..." $LogFile

                # Install Windows Features
                try {
                    Install-WindowsFeature NET-Framework-45-Core,Desktop-Experience,GPMC,RSAT-ADDS-Tools,RDS-Licensing-UI,WAS,Telnet-Client -logpath $LogFile2
                    DS_WriteLog "S" "The windows features were installed successfully!" $LogFile
                } catch {
                    DS_WriteLog "E" "An error occurred while installing the windows features (error: $($error[0]))" $LogFile
                    Exit 1
                }
            } 
        "*6.2*" { 
                $OSVER = "W2K12"
                $OSName = "Windows Server 2012"
                $LogFile2 = Join-Path $LogDir "Install_RolesAndFeatures.log"
                
                DS_WriteLog "I" "The current operating system is $($OSNAME) ($($OSVER))" $LogFile
                DS_WriteLog "-" "" $LogFile
                DS_WriteLog "I" "Roles and Features installation log file: $LogFile2" $LogFile
                DS_WriteLog "I" "Start the installation ..." $LogFile

                # Install Windows Features
                try {
                    Install-WindowsFeature NET-Framework-45-Core,Desktop-Experience,GPMC,RSAT-ADDS-Tools,RDS-Licensing-UI,WAS,Telnet-Client -logpath $LogFile2
                    DS_WriteLog "S" "The windows features were installed successfully!" $LogFile
                } catch {
                    DS_WriteLog "E" "An error occurred while installing the windows features (error: $($error[0]))" $LogFile
                    Exit 1
                }
            }
        "*6.1*" {
                $OSVER = "W2K8R2"
                $OSName = "Windows Server 2008 R2"
                $LogFile2 = Join-Path $LogDir "Install_RolesAndFeatures.log"

                DS_WriteLog "I" "The current operating system is $($OSNAME) ($($OSVER))" $LogFile
                DS_WriteLog "-" "" $LogFile
                DS_WriteLog "I" "Roles and Features installation log file: $LogFile2" $LogFile
                DS_WriteLog "I" "Start the installation ..." $LogFile

                # Install Windows Features
                try {
                    Add-WindowsFeature NET-Framework-Core,Desktop-Experience,GPMC,RSAT-ADDS-Tools,RSAT-RDS-Licensing,WAS,Telnet-Client -logpath $LogFile2
                    DS_WriteLog "S" "The windows features were installed successfully!" $LogFile
                } catch {
                    DS_WriteLog "E" "An error occurred while installing the windows features (error: $($error[0]))" $LogFile
                    Exit 1
                }
            }
        "*6.0*" { 
                $OSVER = "W2K8"
                $OSName = "Windows Server 2008"
                $LogFile2 = Join-Path $LogDir "Install_RolesAndFeatures.log"

                DS_WriteLog "I" "The current operating system is $($OSNAME) ($($OSVER))" $LogFile
                DS_WriteLog "-" "" $LogFile
                DS_WriteLog "I" "Roles and Features installation log file: $LogFile2" $LogFile
                DS_WriteLog "I" "Start the installation ..." $LogFile

                # Install Windows Features
                try {
                    Add-WindowsFeature NET-Framework-Core,Desktop-Experience,GPMC,RSAT-ADDS-Tools,RSAT-RDS-Licensing,WAS,Telnet-Client -logpath $LogFile2
                    DS_WriteLog "S" "The windows features were installed successfully!" $LogFile
                } catch {
                    DS_WriteLog "E" "An error occurred while installing the windows features (error: $($error[0]))" $LogFile
                    Exit 1
                }
            }
        default { 
            $OSName = ( Get-WmiObject -class Win32_OperatingSystem ).Caption
            DS_WriteLog "E" "The current operating system $($OSName) is unsupported" $LogFile
            DS_WriteLog "I" "This script will now be terminated" $LogFile
            DS_WriteLog "-" "" $LogFile
            Exit 1
            }
    }

# Enable File Security  
Remove-Item env:\SEE_MASK_NOZONECHECKS

DS_WriteLog "-" "" $LogFile
DS_WriteLog "I" "End of script" $LogFile
