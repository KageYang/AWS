 #==========================================================================
#
# Configure Citrix StoreFront
#
# AUTHOR: Dennis Span (https://dennisspan.com)
# DATE  : 19.01.2018
#
# COMMENT:
# This script has been prepared for Windows Server 2008 R2, 2012 R2 and 2016.
# This script has been tested on Windows Server 2016 version 1607.
#
# The version of StoreFront used in this script is 3.13 (released in Q4 2017), but will most likely
# work on older versions as well (at least from StoreFront 3.8 and newer).
#
# This script configures the local Citrix StoreFront server and includes the following sections:
# -Install and bind SSL certificate
# -Create StoreFront deployment, stores, farms, Receiver for Web services and more
# -Disable CEIP
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
        DS_WriteLog -$InformationType "I" -Text "Copy files to C:\Temp" -LogFile "C:\Logs\MylogFile.log"
        Writes a line containing information to the log file
        .Example
        DS_WriteLog -$InformationType "E" -Text "An error occurred trying to copy files to C:\Temp (error: $($Error[0]))" -LogFile "C:\Logs\MylogFile.log"
        Writes a line containing error information to the log file
        .Example
        DS_WriteLog -$InformationType "-" -Text "" -LogFile "C:\Logs\MylogFile.log"
        Writes an empty line to the log file
    #>
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory=$true, Position = 0)][ValidateSet("I","S","W","E","-",IgnoreCase = $True)][String]$InformationType,
        [Parameter(Mandatory=$true, Position = 1)][AllowEmptyString()][String]$Text,
        [Parameter(Mandatory=$true, Position = 2)][AllowEmptyString()][String]$LogFile
    )
 
    begin {
    }
 
    process {
     $DateTime = (Get-Date -format dd-MM-yyyy) + " " + (Get-Date -format HH:mm:ss)
 
        if ( $Text -eq "" ) {
            Add-Content $LogFile -value ("") # Write an empty line
        } Else {
         Add-Content $LogFile -value ($DateTime + " " + $InformationType.ToUpper() + " - " + $Text)
        }
    }
 
    end {
    }
}
#==========================================================================

# FUNCTION DS_CreateRegistryKey
#==========================================================================
Function DS_CreateRegistryKey {
    <#
        .SYNOPSIS
        Create a registry key
        .DESCRIPTION
        Create a registry key
        .PARAMETER RegKeyPath
        This parameter contains the registry path, for example 'hklm:\Software\MyApp'
        .EXAMPLE
        DS_CreateRegistryKey -RegKeyPath "hklm:\Software\MyApp"
        Creates the new registry key 'hklm:\Software\MyApp'
    #>
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory=$true, Position = 0)][String]$RegKeyPath
    )

    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        DS_WriteLog "I" "START FUNCTION - $FunctionName" $LogFile
    }
 
    process {
        DS_WriteLog "I" "Create registry key $RegKeyPath" $LogFile
        if ( Test-Path $RegKeyPath ) {
            DS_WriteLog "I" "The registry key $RegKeyPath already exists. Nothing to do." $LogFile
        } else {
            try {
                New-Item -Path $RegkeyPath -Force | Out-Null
                DS_WriteLog "S" "The registry key $RegKeyPath was created successfully" $LogFile
            }
            catch{
                DS_WriteLog "E" "An error occurred trying to create the registry key $RegKeyPath (exit code: $($Error[0])!" $LogFile
                DS_WriteLog "I" "Note: define the registry path as follows: hklm:\Software\MyApp" $LogFile
                Exit 1
            }
        }
    }

    end {
        DS_WriteLog "I" "END FUNCTION - $FunctionName" $LogFile
    }
}
#==========================================================================

# FUNCTION DS_SetRegistryValue
#==========================================================================
Function DS_SetRegistryValue {
    <#
        .SYNOPSIS
        Set a registry value
        .DESCRIPTION
        Set a registry value
        .PARAMETER RegKeyPath
        This parameter contains the registry path, for example 'hklm:\Software\MyApp'
        .PARAMETER RegValueName
        This parameter contains the name of the new registry value, for example 'MyValue'
        .PARAMETER RegValue
        This parameter contains the value of the new registry entry, for example '1'
        .PARAMETER Type
        This parameter contains the type (possible options are: String, Binary, DWORD, QWORD, MultiString, ExpandString)
        .EXAMPLE
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyStringValue" -RegValue "Enabled" -Type "String"
        Creates a new string value called 'MyStringValue' with the value of 'Enabled'
        .Example
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyBinaryValue" -RegValue "01" -Type "Binary"
        Creates a new binary value called 'MyBinaryValue' with the value of '01'
        .Example
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyDWORDValue" -RegValue "1" -Type "DWORD"
        Creates a new DWORD value called 'MyDWORDValue' with the value of 1
        .Example
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyQWORDValue" -RegValue "1" -Type "QWORD"
        Creates a new QWORD value called 'MyQWORDValue' with the value of 1
        .Example
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyMultiStringValue" -RegValue "Value1,Value2,Value3" -Type "MultiString"
        Creates a new multistring value called 'MyMultiStringValue' with the value of 'Value1 Value2 Value3'
        .Example
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyExpandStringValue" -RegValue "MyValue" -Type "ExpandString"
        Creates a new expandstring value called 'MyExpandStringValue' with the value of 'MyValue'
    #>
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory=$true, Position = 0)][String]$RegKeyPath,
        [Parameter(Mandatory=$true, Position = 1)][String]$RegValueName,
        [Parameter(Mandatory=$false, Position = 2)][String[]]$RegValue = "",
        [Parameter(Mandatory=$true, Position = 3)][String]$Type
    )

    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        DS_WriteLog "I" "START FUNCTION - $FunctionName" $LogFile
    }
 
    process {
        DS_WriteLog "I" "Set registry value $RegValueName = $RegValue (type $Type) in $RegKeyPath" $LogFile

        # Create the registry key in case it does not exist
        if ( !( Test-Path $RegKeyPath ) ) {
            DS_CreateRegistryKey $RegKeyPath
        }
    
        # Create the registry value
        try {
            if ( ( "String", "ExpandString", "DWord", "QWord" ) -contains $Type ) {
                New-ItemProperty -Path $RegKeyPath -Name $RegValueName -Value $RegValue[0] -PropertyType $Type -Force | Out-Null
            } else {
                New-ItemProperty -Path $RegKeyPath -Name $RegValueName -Value $RegValue -PropertyType $Type -Force | Out-Null
            }
            DS_WriteLog "S" "The registry value $RegValueName = $RegValue (type $Type) in $RegKeyPath was set successfully" $LogFile
        } catch {
            DS_WriteLog "E" "An error occurred trying to set the registry value $RegValueName = $RegValue (type $Type) in $RegKeyPath" $LogFile
            DS_WriteLog "I" "Note: define the registry path as follows: hklm:\Software\MyApp" $LogFile
            Exit 1
        }
    }

    end {
        DS_WriteLog "I" "END FUNCTION - $FunctionName" $LogFile
    }
}
#==========================================================================

# FUNCTION DS_CreateDirectory
#==========================================================================
Function DS_CreateDirectory {
    <#
        .SYNOPSIS
        Create a new directory
        .DESCRIPTION
        Create a new directory
        .PARAMETER Directory
        This parameter contains the name of the new directory including the full path (for example C:\Temp\MyNewFolder).
        .EXAMPLE
        DS_CreateDirectory -Directory "C:\Temp\MyNewFolder"
        Creates the new directory "C:\Temp\MyNewFolder"
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position = 0)][String]$Directory
    )

    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        DS_WriteLog "I" "START FUNCTION - $FunctionName" $LogFile
    }
 
    process {
        DS_WriteLog "I" "Create directory $Directory" $LogFile
        if ( Test-Path $Directory ) {
            DS_WriteLog "I" "The directory $Directory already exists. Nothing to do." $LogFile
        } else {
            try {
                New-Item -ItemType Directory -Path $Directory -force | Out-Null
                DS_WriteLog "S" "Successfully created the directory $Directory" $LogFile
            } catch {
                DS_WriteLog "E" "An error occurred trying to create the directory $Directory (exit code: $($Error[0])!" $LogFile
                Exit 1
            }
        }
    }

    end {
        DS_WriteLog "I" "END FUNCTION - $FunctionName" $LogFile
    }
}
#==========================================================================

# Function DS_InstallCertificate
#==========================================================================
# The following main certificate stores exist:
# -"CA" = Intermediate Certificates Authorities
# -"My" = Personal
# -"Root" = Trusted Root Certificates Authorities
# -"TrustedPublisher" = Trusted Publishers
# Note: to find the names of all existing certificate stores, use the following PowerShell command: Get-Childitem cert:\localmachine
# Note: to secure passwords in a PowerShell script, see my article https://dennisspan.com/encrypting-passwords-in-a-powershell-script/
Function DS_InstallCertificate {
    <#
        .SYNOPSIS
        Install a certificate
        .DESCRIPTION
        Install a certificate
        .PARAMETER StoreScope
        This parameter determines whether the local machine or the current user store is to be used (possible values are: CurrentUser or LocalMachine)
        .PARAMETER StoreName
        This parameter contains the name of the store (possible values are: CA, My, Root, TrustedPublisher and more)
        .PARAMETER CertFile
        This parameter contains the name, including path and file extension, of the certificate file (e.g. C:\MyCert.cer)
        .PARAMETER CertPassword
        This parameter is optional and is required in case the exported certificate is password protected
        .EXAMPLE
        DS_InstallCertificate -StoreScope "LocalMachine" -StoreName "Root" -CertFile "C:\Temp\MyRootCert.cer"
        Installs the root certificate 'MyRootCert.cer' in the Trusted Root Certificates Authorities store of the local machine
        .EXAMPLE
        DS_InstallCertificate -StoreScope "LocalMachine" -StoreName "CA" -CertFile "C:\Temp\MyIntermediateCert.cer"
        Installs the intermediate certificate 'MyIntermediateCert.cer' in the Intermediate Certificates Authorities store of the local machine
        .EXAMPLE
        DS_InstallCertificate -StoreScope "LocalMachine" -StoreName "My" -CertFile "C:\Temp\MyPersonalCert.cer" -CertPassword "mypassword"
        Installs the password protected intermediate certificate 'MyPersonalCert.cer' in the Personal store of the local machine
        .EXAMPLE
        DS_InstallCertificate -StoreScope "CurrentUser" -StoreName "My" -CertFile "C:\Temp\MyUserCert.pfx"
        Installs the user certificate 'MyUserCert.pfx' in the Personal store of the current user
    #>
    [CmdletBinding()]  
    param (
        [parameter(mandatory=$True,Position=1)]
        [string] $StoreScope,
        [parameter(mandatory=$True,Position=2)]
        [string] $StoreName,
        [parameter(mandatory=$True,Position=3)]  
        [string] $CertFile,
        [parameter(mandatory=$False,Position=4)]  
        [string] $CertPassword
    )

    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        DS_WriteLog "I" "START FUNCTION - $FunctionName" $LogFile
    }
 
    process {
        # Translation table for StoreScope
        switch ($StoreScope) {
        "LocalMachine"       { $StoreScopeTemp = "local machine"}
        "CurrentUser"        { $StoreScopeTemp = "current user"}
        default {}
        }
        # Translation table for StoreName
        switch ($StoreName) {
        "CA"                { $StoreNameTemp = "Intermediate Certificates Authorities (= CA)"}
        "My"                { $StoreNameTemp = "Personal (= My)"}
        "Root"              { $StoreNameTemp = "Trusted Root Certificates Authorities (= Root)"}
        "TrustedPublisher"  { $StoreNameTemp = "Trusted Publishers (= TrustedPublisher)"}
        default {}
        }

        DS_WriteLog "I" "Import the certificate '$CertFile' in the $StoreScopeTemp store $StoreNameTemp" $LogFile
        
        # Check if the certificate file exists.
        if ( !(Test-Path $CertFile) ) {
            DS_WriteLog "E" "The file '$CertFile' does not exist. This script will now quit" $LogFile
            Exit 1
        }

        # Import the certificate to the store
        if (Test-Path "cert:\$StoreScope\$StoreName") {
            $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $CertFile,$CertPassword
            $Store = New-Object System.Security.Cryptography.X509Certificates.X509Store $StoreName,$StoreScope
            $Store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
            $Store.Add($Cert)
            $Store.Close()
            DS_WriteLog "S" "The certificate '$CertFile' was imported successfully in the $StoreScopeTemp store $StoreNameTemp" $LogFile
        } else {
            DS_WriteLog "E" "The store does not exist. This script will now quit" $LogFile
        }
    }
 
    end {
        DS_WriteLog "I" "END FUNCTION - $FunctionName" $LogFile
    }
}
#==========================================================================

# Function DS_BindCertificateToIISPort
#==========================================================================
Function DS_BindCertificateToIISPort {
# Reference: https://weblog.west-wind.com/posts/2016/Jun/23/Use-Powershell-to-bind-SSL-Certificates-to-an-IIS-Host-Header-Site#BindtheWebSitetotheHostHeaderIP
    <#
        .SYNOPSIS
        Bind a certificate to an IIS port
        .DESCRIPTION
        Bind a certificate to an IIS port
        .PARAMETER URL
        [Mandatory] This parameter contains the URL (e.g. apps.myurl.com) of the certificate
        If this parameter contains the prefix 'http://' or 'https://' or any suffixes, these are automatically deleted
        .PARAMETER Port
        [Optional] This parameter contains the port of the IIS site to which the certificate should be bound (e.g. 443)
        If this parameter is omitted, the value 443 is used
        .EXAMPLE
        DS_BindCertificateToIISSite -URL "myurl.com" -Port 443
        Binds the certificate containing the URL 'myurl.com' to port 443. The function automatically determines the hash value of the certificate
        .EXAMPLE
        DS_BindCertificateToIISSite -URL "anotherurl.com" -Port 12345
        Binds the certificate containing the URL 'anotherurl' to port 12345. The function automatically determines the hash value of the certificate
    #>
    [CmdletBinding()]  
    param (
        [Parameter(Mandatory=$True)]
        [string]$URL,
        [Parameter(Mandatory=$True)]
        [int]$Port = 443
    )

    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        DS_WriteLog "I" "START FUNCTION - $FunctionName" $LogFile
    }

    process {
        # Import the PowerShell module 'WebAdministration' for IIS
        try {
            Import-Module WebAdministration
        } catch {
            DS_WriteLog "E" "An error occurred trying to import the PowerShell module 'WebAdministration' for IIS (error: $($Error[0]))" $LogFile
            Exit 1
        }

        # Retrieve the domain name of the host base URL
        if ( $URL.StartsWith("http") ) {
            [string]$Domain = ([System.URI]$URL).host                                     # Retrieve the domain name from the URL. For example: if the host base URL is "http://apps.mydomain.com/folder/", using the data type [System.URI] and the property "host", the resulting value would be "www.mydomain.com"
        } else {
            [string]$Domain = $URL                                                        # Retrieve the domain name from the URL. For example: if the host base URL is "http://apps.mydomain.com/folder/", using the data type [System.URI] and the property "host", the resulting value would be "www.mydomain.com"
        }

        # Retrieve the certificate hash value
        DS_WriteLog "I" "Retrieve the hash value of the certificate for the host base URL '$URL' (check for the domain name '$Domain')" $LogFile
        try {
            If ( $Domain.StartsWith("*") ) {
                $Hash = (Get-ChildItem cert:\LocalMachine\My | where-object { $_.Subject -match "\*.$($Domain)" } | Select-Object -First 1).Thumbprint
            } else {
                $Hash = (Get-ChildItem cert:\LocalMachine\My | where-object { $_.Subject -like "*$Domain*" } | Select-Object -First 1).Thumbprint
            }
            if ( !($Hash) ) {
                DS_WriteLog "I" "The hash value could not be retrieved. Check if a wildcard or SAN certificate is installed." $LogFile
                [string[]]$Domain = (([System.URI]$URL).host).Split(".")              # Retrieve the domain name from the URL (e.g. apps.mydomain.com) and split it based on the dot (.)
                [string]$Domain = "$($Domain[-2]).$($Domain[-1])"                     # Read the last two items in the newly created array to retrieve the root level domain name (in our example this would be "mydomain.com")
                DS_WriteLog "I" "Retrieve the hash value of the certificate for the host base URL '$URL' (check for the domain name '*.$($Domain)')" $LogFile
                $Hash = (Get-ChildItem cert:\LocalMachine\My | where-object { $_.Subject -match "\*.$($Domain)" } | Select-Object -First 1).Thumbprint
                if ( !($Hash) ) {
                    DS_WriteLog "E" "The hash value could not be retrieved. The most likely cause is that the certificate for the host base URL '$URL' is not installed." $LogFile
                    Exit 1
                } else {
                    DS_WriteLog "S" "The hash value of the certificate for the host base URL '$URL' is $Hash" $LogFile
                }
            } else {
                DS_WriteLog "S" "The hash value of the certificate for the host base URL '$URL' is $Hash" $LogFile
            }
        } catch {
            DS_WriteLog "E" "An error occurred trying to retrieve the certificate hash value (error: $($Error[0]))" $LogFile
            Exit 1
        }

        # Bind the certificate to the IIS site   
        DS_WriteLog "I" "Bind the certificate to the IIS site" $LogFile
        try {
            Get-Item iis:\sslbindings\* | where { $_.Port -eq $Port } | Remove-Item
            Get-Item "cert:\LocalMachine\MY\$Hash" | New-Item "iis:\sslbindings\0.0.0.0!$Port"
            DS_WriteLog "S" "The certificate with hash $Hash was successfully bound to port $Port" $LogFile
        } catch {
            DS_WriteLog "E" "An error occurred trying to bind the certificate with hash $Hash to port $Port (error: $($Error[0]))" $LogFile
            Exit 1
        }
    }
 
    end {
        DS_WriteLog "I" "END FUNCTION - $FunctionName" $LogFile
    }
}
#==========================================================================

# Function DS_CreateStoreFrontStore
#==========================================================================
# Note: this function is based on the example script "SimpleDeployment.ps1" located in the following StoreFront installation subdirectory: "C:\Program Files\Citrix\Receiver StoreFront\PowerShellSDK\Examples".
Function DS_CreateStoreFrontStore {
    <#
        .SYNOPSIS
        Creates a single-site or multi-site StoreFront deployment, stores, farms and the Authentication, Receiver for Web and PNAgent services
        .DESCRIPTION
        Creates a single-site or multi-site StoreFront deployment, stores, farms and the Authentication, Receiver for Web and PNAgent services
        .PARAMETER FriendlyName
        [Optional] This parameter configures the friendly name of the store, for example "MyStore" or "Marketing"
        If this parameter is omitted, the script generates the friendly name automatically based on the farm name. For example, if the farm name is "MyFarm", the friendly name would be "Store - MyFarm" 
        .PARAMETER HostBaseUrl
        [Mandatory] This parameter determines the URL of the IIS site (the StoreFront "deployment"), for example "https://mysite.com" or "http://mysite.com"
        .PARAMETER CertSubjectName
        [Optional] This parameter determines the Certificate Subject Name of the certificate you want to bind to the IIS SSL port on the local StoreFront server
        Possible values are:
        -Local machine name: $($env:ComputerName).mydomain.local
        -Wilcard / Subject Alternative Name (SAN) certificate: *.mydomain.local or portal.mydomain.local
        If this parameter is omitted, the Certificate Subject Name will be automatically extracted from the host base URL.
        .PARAMETER AddHostHeaderToIISSiteBinding
        [Optional] This parameter determines whether the host base URl (the host name) is added to IIS site binding
        If this parameter is omitted, the value is set to '$false' and the host base URl (the host name) is NOT added to IIS site binding
        .PARAMETER IISSiteDir
        [Optional] This parameter contains the directory path to the IIS site. This parameter is only used in multiple deployment configurations whereby multiple IIS sites are created.
        If this parameter is omitted, a directory will be automatically generated by the script
        .PARAMETER Farmtype
        [Optional] This parameter determines the farm type. Possible values are: XenDesktop | XenApp | AppController | VDIinaBox.
        If this parameter is omitted, the default value "XenDesktop" is used
        .PARAMETER FarmName
        [Mandatory] This parameter contains the name of the farm within the store. The farm name should be unique within a store.
        .PARAMETER FarmServers
        [Mandatory] This parameter, which data type is an array, contains a list of farm servers (XML brokers or Delivery Controller). Enter the list comma separated (e.g. -FarmServers "Server1","Server2","Server3")
        .PARAMETER StoreVirtualPath
        [Optional] This parameter contains the partial path of the StoreFront store, for example: -StoreVirtualPath "/Citrix/MyStore" or -StoreVirtualPath "/Citrix/Store1".
        If this parameter is omitted, the default value "/Citrix/Store" is used
        .PARAMETER ReceiverVirtualPath
        [Optional] This parameter contains the partial path of the Receiver for Web site in the StoreFront store, for example: -ReceiverVirtualPath "/Citrix/MyStoreWeb" or -ReceiverVirtualPath "/Citrix/Store1ReceiverWeb". 
        If this parameter is omitted, the default value "/Citrix/StoreWeb" is used        
        .PARAMETER SSLRelayPort
        [Mandatory] This parameter contains the SSL Relay port (XenApp 6.5 only) used for communicating with the XenApp servers. Default value is 443 (HTTPS).
        .PARAMETER LoadBalanceServers
        [Optional] This parameter determines whether to load balance the Delivery Controllers or to use them in failover order (if specifying more than one server)
        If this parameter is omitted, the default value "$false" is used, which means that failover is used instead of load balancing
        .PARAMETER XMLPort
        [Optional] This parameter contains the XML service port used for communicating with the XenApp\XenDesktop servers. Default values are 80 (HTTP) and 443 (HTTPS), but you can also use other ports (depending on how you configured your XenApp/XenDesktop servers). 
        If this parameter is omitted, the default value 80 is used
        .PARAMETER HTTPPort
        [Optional] This parameter contains the port used for HTTP communication on the IIS site. The default value is 80, but you can also use other ports.
        If this parameter is omitted, the default value 80 is used.
        .PARAMETER HTTPSPort
        [Optional] This parameter contains the port used for HTTPS communication on the IIS site. If this value is not set, no HTTPS binding is created
        .PARAMETER TransportType
        [Optional] This parameter contains the type of transport to use for the XML service communication. Possible values are: HTTP | HTTPS | SSL
        If this parameter is omitted, the default value "HTTP" is used
        .PARAMETER EnablePNAgent
        [Mandatory] This parameter determines whether the PNAgent site is created and enabled. Possible values are: $True | $False
        If this parameter is omitted, the default value "$true" is used
        .PARAMETER PNAgentAllowUserPwdChange
        [Optional] This parameter determines whether the user is allowed to change their password on a PNAgent. Possible values are: $True | $False.
        Note: this parameter can only be used if the logon method for PNAgent is set to 'prompt'
        !! Only add this parameter when the parameter EnablePNAgent is set to $True
        If this parameter is omitted, the default value "$true" is used
        .PARAMETER PNAgentDefaultService
        [Optional] This parameter determines whether this PNAgent site is the default PNAgent site in the store. Possible values are: $True | $False.
        !! Only add this parameter when the parameter EnablePNAgent is set to $True
        If this parameter is omitted, the default value "$true" is used
        .PARAMETER LogonMethod
        [Optional] This parameter determines the logon method for the PNAgent site. Possible values are: Anonymous | Prompt | SSON | Smartcard_SSON | Smartcard_Prompt. Only one value can be used at a time. 
        !! Only add this parameter when the parameter EnablePNAgent is set to $True
        If this parameter is omitted, the default value "SSON" (Single Sign-On) is used
        .EXAMPLE
        DS_CreateStoreFrontStore -FriendlyName "MyStore"  -HostBaseUrl "https://myurl.com" -FarmName "MyFarm" -FarmServers "Server1","Server2" -EnablePNAgent $True
        Creates a basic StoreFront deployment, a XenDesktop store, farm, Receiver for Web site and a PNAgent site. The communication with the Delivery Controllers uses the default XML port 80 and transport type HTTP
        The above example uses only the 4 mandatory parameters and does not include any of the optional parameters
        In case the HostBaseUrl is different than an already configured one on the local StoreFront server, a new IIS site is automatically created
        .EXAMPLE
        DS_CreateStoreFrontStore -HostBaseUrl "https://myurl.com" -FarmName "MyFarm" -FarmServers "Server1","Server2" -StoreVirtualPath "/Citrix/MyStore" -ReceiverVirtualPath "/Citrix/MyStoreWeb" -XMLPort 443 -TransportType "HTTPS" -EnablePNAgent $True -PNAgentAllowUserPwdChange $False -PNAgentDefaultService $True -LogonMethod "Prompt"
        Creates a StoreFront deployment, a XenDesktop store, farm, Receiver for Web site and a PNAgent site. The communication with the Delivery Controllers uses port 443 and transport type HTTPS (please make sure that your Delivery Controller is listening on port 443!) 
        PNAgent users are not allowed to change their passwords and the logon method is "prompt" instead of the default SSON (= Single Sign-On).
        In case the HostBaseUrl is different than an already configured one on the local StoreFront server, a new IIS site is automatically created
        .EXAMPLE
        DS_CreateStoreFrontStore -HostBaseUrl "https://anotherurl.com" -FarmName "MyFarm" -FarmServers "Server1","Server2" -EnablePNAgent $False
        Creates a StoreFront deployment, a XenDesktop store, farm and Receiver for Web site, but DOES NOT create and enabled a PNAgent site. The communication with the Delivery Controllers uses the default XML port 80 and transport type HTTP.
        In case the HostBaseUrl is different than an already configured one on the local StoreFront server, a new IIS site is automatically created
    #>
    [CmdletBinding()]  
    param (
        [Parameter(Mandatory=$false)]
        [string]$FriendlyName,
        [Parameter(Mandatory=$true)]
        [string]$HostBaseUrl,
        [Parameter(Mandatory=$false)]
        [string]$CertSubjectName,
        [Parameter(Mandatory=$false)]
        [string]$AddHostHeaderToIISSiteBinding = $false,
        [Parameter(Mandatory=$false)]
        [string]$IISSiteDir,
        [Parameter(Mandatory=$false)]
        [ValidateSet("XenDesktop","XenApp","AppController","VDIinaBox")]
        [string]$FarmType = "XenDesktop",
        [Parameter(Mandatory=$true)]
        [string]$FarmName,
        [Parameter(Mandatory=$true)]
        [string[]]$FarmServers,
        [Parameter(Mandatory=$false)]
        [string]$StoreVirtualPath = "/Citrix/Store",
        [Parameter(Mandatory=$false)]
        [string]$ReceiverVirtualPath = "/Citrix/StoreWeb",
        [Parameter(Mandatory=$false)]
        [int]$SSLRelayPort,
        [Parameter(Mandatory=$false)]
        [bool]$LoadBalanceServers = $false,
        [Parameter(Mandatory=$false)]
        [int]$XMLPort = 80,
        [Parameter(Mandatory=$false)]
        [int]$HTTPPort = 80,
        [Parameter(Mandatory=$false)]
        [int]$HTTPSPort,
        [Parameter(Mandatory=$false)]
        [ValidateSet("HTTP","HTTPS","SSL")]
        [string]$TransportType = "HTTP",
        [Parameter(Mandatory=$true)]
        [bool]$EnablePNAgent = $true,
        [Parameter(Mandatory=$false)]
        [bool]$PNAgentAllowUserPwdChange = $true,
        [Parameter(Mandatory=$false)]
        [bool]$PNAgentDefaultService = $true,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Anonymous","Prompt","SSON","Smartcard_SSON","Smartcard_Prompt")]
        [string]$LogonMethod = "SSON"
    )

    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        DS_WriteLog "I" "START FUNCTION - $FunctionName" $LogFile
    }
 
    process {
        # Import StoreFront modules. Required for versions of PowerShell earlier than 3.0 that do not support autoloading.
        DS_WriteLog "I" "Import StoreFront PowerShell modules:" $LogFile
        [string[]] $Modules = "WebAdministration","Citrix.StoreFront","Citrix.StoreFront.Stores","Citrix.StoreFront.Authentication","Citrix.StoreFront.WebReceiver"   # Four StoreFront modules are required in this function. They are listed here in an array and in the following 'foreach' statement each of these four is loaded
        Foreach ( $Module in $Modules) {
            try {
                DS_WriteLog "I" "   -Import the StoreFront PowerShell module $Module" $LogFile
                Import-Module $Module
                DS_WriteLog "S" "    The StoreFront PowerShell module $Module was imported successfully" $LogFile
            } catch {
                DS_WriteLog "E" "    An error occurred trying to import the StoreFront PowerShell module $Module (error: $($Error[0]))" $LogFile
                Exit 1
            }
        }

        DS_WriteLog "-" "" $LogFile

        # Modify variables and/or create new ones for logging
        [int]$SiteId            = 1
        [string]$HostName       = ([System.URI]$HostBaseUrl).host                                                # Get the hostname (required for the IIS site) without prefixes such as "http://" or "https:// and no suffixes such as trailing slashes (/). The contents of the variable '$HostBaseURL' will look like this: portal.mydomain.com
        [string]$HostBaseUrl    = "$(([System.URI]$HostBaseUrl).scheme)://$(([System.URI]$HostBaseUrl).host)"    # Retrieve the 'clean' URL (e.g. in case the host base URL contains trailing slashes or more). The contents of the variable '$HostBaseURL' will look like this: https://portal.mydomain.com.
        If ( !($CertSubjectName) ) { $CertSubjectNameTemp = "<use the host base URL>" } else { $CertSubjectNameTemp = $CertSubjectName }
        If ( $CertSubjectName.StartsWith("*") ) { $CertSubjectName.Replace("*", "\*") | Out-Null }               # In case the certificate subject name starts with a *, place a backslash in front of it (this is required for the regular e
        If ( $AddHostHeaderToIISSiteBinding -eq $true ) { $AddHostHeaderToIISSiteBindingTemp = "yes" }
        If ( $AddHostHeaderToIISSiteBinding -eq $false ) { $AddHostHeaderToIISSiteBindingTemp = "no" }
        [string]$IISSiteDirTemp = $IISSiteDir
        If ( [string]::IsNullOrEmpty($FriendlyName) ) { $FriendlyName = "Store - $($FarmName)" }
        If ( [string]::IsNullOrEmpty($IISSiteDir) ) { $IISSiteDirTemp = "Default: $env:SystemDrive\inetpub\wwwroot" }
        If ( $LoadBalanceServers -eq $true ) { $LoadBalanceServersTemp = "yes" }
        If ( $LoadBalanceServers -eq $false ) { $LoadBalanceServersTemp = "no (fail-over)" }
        If ( !($HTTPSPort) ) { $HTTPSPortTemp = "<no IIS HTTPS/SSL>" } else { $HTTPSPortTemp = $HTTPSPort}
        If ( $EnablePNAgent -eq $true ) { $EnablePNAgentTemp = "yes" }
        If ( $EnablePNAgent -eq $false ) { $EnablePNAgentTemp = "no" }
        If ( $PNAgentAllowUserPwdChange -eq $true ) { $PNAgentAllowUserPwdChangeTemp = "yes" }
        If ( $PNAgentAllowUserPwdChange -eq $false ) { $PNAgentAllowUserPwdChangeTemp = "no" }
        If ( $PNAgentDefaultService -eq $true ) { $PNAgentDefaultServiceTemp = "yes" }
        If ( $PNAgentDefaultService -eq $false ) { $PNAgentDefaultServiceTemp = "no" } 
        
        # Start logging     
        DS_WriteLog "I" "Create the StoreFront store with the following parameters:" $LogFile
        DS_WriteLog "I" "   -Friendly name                      : $FriendlyName" $LogFile
        DS_WriteLog "I" "   -Host base URL                      : $HostBaseUrl" $LogFile
        DS_WriteLog "I" "   -Certificate subject name           : $CertSubjectNameTemp" $LogFile
        DS_WriteLog "I" "   -Add host name to IIS site binding  : $AddHostHeaderToIISSiteBindingTemp" $LogFile
        DS_WriteLog "I" "   -IIS site directory                 : $IISSiteDirTemp" $LogFile
        DS_WriteLog "I" "   -Farm type                          : $FarmType" $LogFile
        DS_WriteLog "I" "   -Farm name                          : $FarmName" $LogFile
        DS_WriteLog "I" "   -Farm servers                       : $FarmServers" $LogFile
        DS_WriteLog "I" "   -Store virtual path                 : $StoreVirtualPath" $LogFile
        DS_WriteLog "I" "   -Receiver virtual path              : $receiverVirtualPath" $LogFile
        If ( $FarmType -eq "XenApp" ) {
            DS_WriteLog "I" "   -SSL relay port (XenApp 6.5 only)   : $SSLRelayPort" $LogFile
        }
        DS_WriteLog "I" "   -Load Balancing                     : $LoadBalanceServersTemp" $LogFile
        DS_WriteLog "I" "   -XML Port                           : $XMLPort" $LogFile
        DS_WriteLog "I" "   -HTTP Port                          : $HTTPPort" $LogFile
        DS_WriteLog "I" "   -HTTPS Port                         : $HTTPSPortTemp" $LogFile
        DS_WriteLog "I" "   -Transport type                     : $TransportType" $LogFile
        DS_WriteLog "I" "   -Enable PNAgent                     : $EnablePNAgentTemp" $LogFile
        DS_WriteLog "I" "   -PNAgent allow user change password : $PNAgentAllowUserPwdChangeTemp" $LogFile
        DS_WriteLog "I" "   -PNAgent set to default             : $PNAgentDefaultServiceTemp" $LogFile
        DS_WriteLog "I" "   -PNAgent logon method               : $LogonMethod" $LogFile

        DS_WriteLog "-" "" $LogFile

        # Check if the parameters match
        If ( ( $TransportType -eq "HTTPS" ) -And ( $XMLPort -eq 80 ) ) {
            DS_WriteLog "W" "The transport type is set to HTTPS, but the XML port was set to 80. Changing the port to 443" $LogFile
            Exit 0
        }
        If ( ( $TransportType -eq "HTTP" ) -And ( $XMLPort -eq 443 ) ) {
            DS_WriteLog "W" "The transport type is set to HTTP, but the XML port was set to 443. Changing the port to 80" $LogFile
            Exit 0
        }

        #############################################################################
        # Create a new deployment with the host base URL set in the variable $HostBaseUrl
        #############################################################################
        DS_WriteLog "I" "Create a new StoreFront deployment (URL: $($HostBaseUrl)) unless one already exists" $LogFile

        # Port bindings
        If ( !($HTTPSPort) ) {
            if ( $AddHostHeaderToIISSiteBinding -eq $false ) {
                $Bindings = @(
                    @{protocol="http";bindingInformation="*:$($HTTPPort):"}
                )
            } else {
                $Bindings = @(
                    @{protocol="http";bindingInformation="*:$($HTTPPort):$($HostName)"}
                )
            }
        } else {
            if ( $AddHostHeaderToIISSiteBinding -eq $false ) {
                $Bindings = @(
                    @{protocol="http";bindingInformation="*:$($HTTPPort):"},
                    @{protocol="https";bindingInformation="*:$($HTTPSPort):"}
                )
            } else {
                $Bindings = @(
                    @{protocol="http";bindingInformation="*:$($HTTPPort):$($HostName)"},
                    @{protocol="https";bindingInformation="*:$($HTTPSPort):$($HostName)"}
                )
            }
        }

        # Determine if the deployment already exists
        $ExistingDeployments = Get-STFDeployment
        if( !($ExistingDeployments) ) {
            DS_WriteLog "I" "No StoreFront deployment exists. Prepare IIS for the first deployment" $LogFile
        
            # Delete the bindings on the Default Web Site
            DS_WriteLog "I" "Delete the bindings on the Default Web Site" $LogFile
            try {
                Clear-ItemProperty "IIS:\Sites\Default Web Site" -Name bindings
                DS_WriteLog "S" "The bindings on the Default Web Site have been successfully deleted" $LogFile
            } catch {
                DS_WriteLog "E" "An error occurred trying to delte the bindings on the Default Web Site (error: $($Error[0]))" $LogFile
                Exit 1
            }

            # Create the bindings on the Default Web Site
            DS_WriteLog "I" "Create the bindings on the Default Web Site" $LogFile
            try {
                Set-ItemProperty "IIS:\Sites\Default Web Site" -Name bindings -Value $Bindings
                DS_WriteLog "S" "The bindings on the Default Web Site have been successfully created" $LogFile
            } catch {
                DS_WriteLog "E" "An error occurred trying to create the bindings the Default Web Site (error: $($Error[0]))" $LogFile
                Exit 1
            }

            DS_WriteLog "-" "" $LogFile

            # Bind the certificate to the IIS Site (only when an HTTPS port has been defined in the variable $HTTPSPort)
            If ( $HTTPSPort ) {
                if ( !($CertSubjectName) ) {
                    DS_BindCertificateToIISPort -URL $HostBaseUrl -Port $HTTPSPort
                } else {
                    DS_BindCertificateToIISPort -URL $CertSubjectName -Port $HTTPSPort
                }
                DS_WriteLog "-" "" $LogFile
            }    
        
            # Create the first StoreFront deployment
            DS_WriteLog "I" "Create the first StoreFront deployment (this may take a couple of minutes)" $LogFile
            try {
                Add-STFDeployment -HostBaseUrl $HostbaseUrl -SiteId 1 -Confirm:$false                                                              # Create the first deployment on this server using the IIS default website (= site ID 1)
                DS_WriteLog "S" "The StoreFront deployment '$HostbaseUrl' on IIS site ID $SiteId has been successfully created" $LogFile
            } catch {
                DS_WriteLog "E" "An error occurred trying to create the StoreFront deployment '$HostBaseUrl' (error: $($Error[0]))" $LogFile
                Exit 1
            }
        } else {                                                                                                                                    # One or more deployments exists
            $ExistingDeploymentFound = $False
            Foreach ( $Deployment in $ExistingDeployments ) {                                                                                       # Loop through each deployment and check if the URL matches the one defined in the variable $HostbaseUrl
                if ($Deployment.HostbaseUrl -eq $HostBaseUrl) {                                                                                     # The deployment URL is the same as the one we want to add, so nothing to do
                    $SiteId = $Deployment.SiteId                                                                                                    # Set the value of the variable $SiteId to the correct IIS site ID
                    $ExistingDeploymentFound = $True
                    # The deployment exists and it is configured to the desired hostbase URL
                    DS_WriteLog "I" "A deployment has already been created with the hostbase URL '$HostBaseUrl' on this server and will be used (IIS site ID is $SiteId)" $LogFile
                }
            }

            # Create a new IIS site and StoreFront deployment in case existing deployments were found, but none matching the hostbase URL defined in the variable $HostbaseUrl
            If ( $ExistingDeploymentFound -eq $False ) {
                DS_WriteLog "I" "One or more deployments exist on this server, but all with a different host base URL" $LogFile
                DS_WriteLog "I" "A new IIS site will now be created which will host the host base URL '$HostBaseUrl' defined in variable `$HostbaseUrl" $LogFile

                # Generate a random, new directory for the new IIS site in case the directory was not specified in the variable $IISSiteDir 
                If ( [string]::IsNullOrEmpty($IISSiteDir) ) {                                                                                        # In case no directory for the new IIS site was specified in the variable $IISSiteDir, a new, random one must be created
                    DS_WriteLog "I" "No directory for the new IIS site was defined in variable `$HostbaseUrl. A new one will now be generated" $LogFile
                    DS_WriteLog "I" "Retrieve the list of existing IIS sites, identify the highest site ID, add 1 and use this number to generate a new IIS directory" $LogFile
                    $NewIISSiteNumber = ((((Get-ChildItem -Path IIS:\Sites).ID) | measure -Maximum).Maximum)+1                                       # Retrieve all existing IIS sites ('Get-ChildItem -Path IIS:\Sites'); list only one property, namely the site ID (ID); than use the Measure-Object (measure -Maximum) to get the highest site ID and add 1 to determine the new site ID
                    DS_WriteLog "S" "The new site ID is: $NewIISSiteNumber" $LogFile
                    $IISSiteDir = "$env:SystemDrive\inetpub\wwwroot$($NewIISSiteNumber)"                                                             # Set the directory for the new IIS site to "C:\inetpub\wwwroot#\" (# = the number of the new site ID retrieved in the previous line), for example "C:\inetpub\wwwroot2"   
                }

                DS_WriteLog "I" "The directory for the new IIS site is: $IISSiteDir" $LogFile

                # Create the directory for the new IIS site
                DS_WriteLog "I" "Create the directory for the new IIS site" $LogFile
                DS_CreateDirectory -Directory $IISSiteDir

                # Create the new IIS site
                DS_WriteLog "I" "Create the new IIS site" $LogFile
                try {
                    New-Item "iis:\Sites\$($FarmName)" -bindings $Bindings -physicalPath $IISSiteDir
                    DS_WriteLog "S" "The new IIS site for the URL '$HostbaseUrl' with site ID $SiteId has been successfully created" $LogFile
                } catch {
                    DS_WriteLog "E" "An error occurred trying to create the IIS site for the URL '$HostbaseUrl' with site ID $SiteId (error: $($Error[0]))" $LogFile
                    Exit 1
                }

                # Retrieve the site ID of the new site
                DS_WriteLog "I" "Retrieve the site ID of the new site" $LogFile
                $SiteId = (Get-ChildItem -Path IIS:\Sites | Where-Object { $_.Name -like "*$FarmName*" }).ID
                DS_WriteLog "S" "The new site ID is: $SiteId" $LogFile

                DS_WriteLog "-" "" $LogFile

                # Bind the certificate to the IIS Site (only when an HTTPS port has been defined in the variable $HTTPSPort)
                If ( $HTTPSPort ) {
                    if ( !($CertSubjectName) ) {
                        DS_BindCertificateToIISPort -URL $HostBaseUrl -Port $HTTPSPort
                        } else {
                            DS_BindCertificateToIISPort -URL $CertSubjectName -Port $HTTPSPort
                        }
                    DS_WriteLog "-" "" $LogFile
                }

                # Create the StoreFront deployment
                try {
                    Add-STFDeployment -HostBaseUrl $HostBaseUrl -SiteId $SiteId -Confirm:$false                                                       # Create a new deployment on this server using the new IIS default website (= site ID #)
                    DS_WriteLog "S" "The StoreFront deployment '$HostBaseUrl' on IIS site ID $SiteId has been successfully created" $LogFile
                } catch {
                    DS_WriteLog "E" "An error occurred trying to create the StoreFront deployment '$HostBaseUrl' (error: $($Error[0]))" $LogFile
                    Exit 1
                }
            }
        }

        DS_WriteLog "-" "" $LogFile

        #############################################################################
        # Determine the Authentication and Receiver virtual path to use based on the virtual path of the store defined in the variable '$StoreVirtualPath'
        # The variable '$StoreVirtualPath' is not mandatory. In case it is not defined, the default value '/Citrix/Store' is used.
        #############################################################################
        DS_WriteLog "I" "Set the virtual path for Authentication and Receiver:" $LogFile
        $authenticationVirtualPath = "$($StoreVirtualPath.TrimEnd('/'))Auth"
        DS_WriteLog "I" "   -Authentication virtual path is: $authenticationVirtualPath" $LogFile
        If ( [string]::IsNullOrEmpty($ReceiverVirtualPath) ) {                                                                                        # In case no directory for the Receiver for Web site was specified in the variable $ReceiverVirtualPath, a directory name will be automatically generated
            $receiverVirtualPath = "$($StoreVirtualPath.TrimEnd('/'))Web"
        }
        DS_WriteLog "I" "   -Receiver virtual path is: $receiverVirtualPath" $LogFile

        DS_WriteLog "-" "" $LogFile

        #############################################################################
        # Determine if the authentication service at the specified virtual path in the specific IIS site exists
        #############################################################################
        DS_WriteLog "I" "Determine if the authentication service at the path $authenticationVirtualPath in the IIS site $SiteId exists" $LogFile
        $authentication = Get-STFAuthenticationService -siteID $SiteId -VirtualPath $authenticationVirtualPath
        if ( !($authentication) ) {
            DS_WriteLog "I" "No authentication service exists at the path $authenticationVirtualPath in the IIS site $SiteId" $LogFile
            # Add an authentication service using the IIS path of the store appended with Auth
            DS_WriteLog "I" "Add the authentication service at the path $authenticationVirtualPath in the IIS site $SiteId" $LogFile
            try {
                $authentication = Add-STFAuthenticationService -siteID $SiteId -VirtualPath $authenticationVirtualPath
                DS_WriteLog "S" "The authentication service at the path $authenticationVirtualPath in the IIS site $SiteId was created successfully" $LogFile
            } catch {
                DS_WriteLog "E" "An error occurred trying to create the authentication service at the path $authenticationVirtualPath in the IIS site $SiteId (error: $($Error[0]))" $LogFile
                Exit 1
            }
        } else {
            DS_WriteLog "I" "An authentication service already exists at the path $authenticationVirtualPath in the IIS site $SiteID and will be used" $LogFile
        }

        DS_WriteLog "-" "" $LogFile

        #############################################################################
        # Create store and farm
        #############################################################################
        DS_WriteLog "I" "Determine if the store service at the path $StoreVirtualPath in the IIS site $SiteId exists" $LogFile
        $store = Get-STFStoreService -siteID $SiteId -VirtualPath $StoreVirtualPath
        if ( !($store) ) {
            DS_WriteLog "I" "No store service exists at the path $StoreVirtualPath in the IIS site $SiteId" $LogFile
            DS_WriteLog "I" "Add a store that uses the new authentication service configured to publish resources from the supplied servers" $LogFile
            # Add a store that uses the new authentication service configured to publish resources from the supplied servers
            try {
                #If ( $FarmType -eq "XenApp" ) {
                    $store = Add-STFStoreService -FriendlyName $FriendlyName -siteID $SiteId -VirtualPath $StoreVirtualPath -AuthenticationService $authentication -FarmName $FarmName -FarmType $FarmType -Servers $FarmServers -SSLRelayPort $SSLRelayPort -LoadBalance $LoadbalanceServers -Port $XMLPort -TransportType $TransportType
                #} else {
                 #   $store = Add-STFStoreService -FriendlyName $FriendlyName -siteID $SiteId -VirtualPath $StoreVirtualPath -AuthenticationService $authentication -FarmName $FarmName -FarmType $FarmType -Servers $FarmServers -LoadBalance $LoadbalanceServers -Port $XMLPort -TransportType $TransportType
                #}
                DS_WriteLog "S" "The store service with the following configuration was created successfully:" $LogFile
                DS_WriteLog "I" "   -FriendlyName : $FriendlyName" $LogFile
                DS_WriteLog "I" "   -siteId       : $SiteId" $LogFile
                DS_WriteLog "I" "   -VirtualPath  : $StoreVirtualPath" $LogFile
                DS_WriteLog "I" "   -AuthService  : $authenticationVirtualPath" $LogFile
                DS_WriteLog "I" "   -FarmName     : $FarmName" $LogFile
                DS_WriteLog "I" "   -FarmType     : $FarmType" $LogFile
                DS_WriteLog "I" "   -Servers      : $FarmServers" $LogFile
                If ( $FarmType -eq "XenApp" ) {
                    DS_WriteLog "I" "   -SSL relay port (XenApp 6.5 only)   : $SSLRelayPort" $LogFile
                }
                DS_WriteLog "I" "   -LoadBalance  : $LoadBalanceServersTemp" $LogFile
                DS_WriteLog "I" "   -XML Port     : $XMLPort" $LogFile
                DS_WriteLog "I" "   -TransportType: $TransportType" $LogFile
            } catch {
                DS_WriteLog "E" "An error occurred trying to create the store service with the following configuration (error: $($Error[0])):" $LogFile
                DS_WriteLog "I" "   -FriendlyName : $FriendlyName" $LogFile
                DS_WriteLog "I" "   -siteId       : $SiteId" $LogFile
                DS_WriteLog "I" "   -VirtualPath  : $StoreVirtualPath" $LogFile
                DS_WriteLog "I" "   -AuthService  : $authenticationVirtualPath" $LogFile
                DS_WriteLog "I" "   -FarmName     : $FarmName" $LogFile
                DS_WriteLog "I" "   -FarmType     : $FarmType" $LogFile
                DS_WriteLog "I" "   -Servers      : $FarmServers" $LogFile
                If ( $FarmType -eq "XenApp" ) {
                    DS_WriteLog "I" "   -SSL relay port (XenApp 6.5 only)   : $SSLRelayPort" $LogFile
                }
                DS_WriteLog "I" "   -LoadBalance  : $LoadBalanceServersTemp" $LogFile
                DS_WriteLog "I" "   -XML Port     : $XMLPort" $LogFile
                DS_WriteLog "I" "   -TransportType: $TransportType" $LogFile
                Exit 1
            }
        } else {
            # During the creation of the store at least one farm is defined, so there must at the very least be one farm present in the store
            DS_WriteLog "I" "A store service called $($Store.Name) already exists at the path $StoreVirtualPath in the IIS site $SiteId" $LogFile
            DS_WriteLog "I" "Retrieve the available farms in the store $($Store.Name)." $LogFile
            $ExistingFarms = (Get-STFStoreFarmConfiguration $Store).Farms.FarmName
            $TotalFarmsFound = $ExistingFarms.Count
            DS_WriteLog "I" "Total farms found: $TotalFarmsFound" $LogFile
            Foreach ( $Farm in $ExistingFarms ) {
                DS_WriteLog "I" "   -Farm name: $Farm" $LogFile    
            }

            # Loop through each farm, check if the farm name is the same as the one defined in the variable $FarmName. If not, create/add a new farm to the store
            $ExistingFarmFound = $False
            DS_WriteLog "I" "Check if the farm $FarmName already exists" $LogFile
            Foreach ( $Farm in $ExistingFarms ) {
                if ( $Farm -eq $FarmName ) {
                    $ExistingFarmFound = $True
                    # The farm exists. Nothing to do. This script will now end.
                    DS_WriteLog "I" "The farm $FarmName exists" $LogFile
                }
            }

            # Create a new farm in case existing farms were found, but none matching the farm name defined in the variable $HostbaseUrl
            If ( $ExistingFarmFound -eq $False ) {
                DS_WriteLog "I" "The farm $FarmName does not exist" $LogFile
                DS_WriteLog "I" "Create the new farm $FarmName" $LogFile
                # Create the new farm
                try {
                    Add-STFStoreFarm -StoreService $store -FarmName $FarmName -FarmType $FarmType -Servers $FarmServers -SSLRelayPort $SSLRelayPort -LoadBalance $LoadBalanceServers -Port $XMLPort -TransportType $TransportType
                    DS_WriteLog "S" "The farm $FarmName with the following configuration was created successfully:" $LogFile
                    DS_WriteLog "I" "   -siteId       : $SiteId" $LogFile
                    DS_WriteLog "I" "   -FarmName     : $FarmName" $LogFile
                    DS_WriteLog "I" "   -FarmType     : $FarmType" $LogFile
                    DS_WriteLog "I" "   -Servers      : $FarmServers" $LogFile
                    If ( $FarmType -eq "XenApp" ) {
                        DS_WriteLog "I" "   -SSL relay port (XenApp 6.5 only)   : $SSLRelayPort" $LogFile
                    }
                    DS_WriteLog "I" "   -LoadBalance  : $LoadBalanceServersTemp" $LogFile
                    DS_WriteLog "I" "   -XML Port     : $XMLPort" $LogFile
                    DS_WriteLog "I" "   -TransportType: $TransportType" $LogFile
                } catch {
                    DS_WriteLog "E" "An error occurred trying to create the farm $FarmName with the following configuration (error: $($Error[0])):" $LogFile
                    DS_WriteLog "I" "   -siteId       : $SiteId" $LogFile
                    DS_WriteLog "I" "   -FarmName     : $FarmName" $LogFile
                    DS_WriteLog "I" "   -FarmType     : $FarmType" $LogFile
                    DS_WriteLog "I" "   -Servers      : $FarmServers" $LogFile
                    If ( $FarmType -eq "XenApp" ) {
                        DS_WriteLog "I" "   -SSL relay port (XenApp 6.5 only)   : $SSLRelayPort" $LogFile
                    }
                    DS_WriteLog "I" "   -LoadBalance  : $LoadBalanceServersTemp" $LogFile
                    DS_WriteLog "I" "   -XML Port     : $XMLPort" $LogFile
                    DS_WriteLog "I" "   -TransportType: $TransportType" $LogFile
                Exit 1
                }
            }
        }

        DS_WriteLog "-" "" $LogFile

        ##############################################################################################
        # Determine if the Receiver for Web service at the specified virtual path and IIS site exists
        ##############################################################################################
        DS_WriteLog "I" "Determine if the Receiver for Web service at the path $receiverVirtualPath in the IIS site $SiteId exists" $LogFile
        try {
            $receiver = Get-STFWebReceiverService -siteID $SiteID -VirtualPath $receiverVirtualPath
        } catch {
            DS_WriteLog "E" "An error occurred trying to determine if the Receiver for Web service at the path $receiverVirtualPath in the IIS site $SiteId exists (error: $($Error[0]))" $LogFil
            Exit 1
        }

        # Create the receiver server if it does not exist
        if ( !($receiver) ) {
            DS_WriteLog "I" "No Receiver for Web service exists at the path $receiverVirtualPath in the IIS site $SiteId" $LogFile
            DS_WriteLog "I" "Add the Receiver for Web service at the path $receiverVirtualPath in the IIS site $SiteId" $LogFile
            # Add a Receiver for Web site so users can access the applications and desktops in the published in the Store
            try {
                $receiver = Add-STFWebReceiverService -siteID $SiteId -VirtualPath $receiverVirtualPath -StoreService $Store
                DS_WriteLog "S" "The Receiver for Web service at the path $receiverVirtualPath in the IIS site $SiteId was created successfully" $LogFile
            } catch {
                DS_WriteLog "E" "An error occurred trying to create the Receiver for Web service at the path $receiverVirtualPath in the IIS site $SiteId (error: $($Error[0]))" $LogFile
                Exit 1
            }
        } else {
            DS_WriteLog "I" "A Receiver for Web service already exists at the path $receiverVirtualPath in the IIS site $SiteId" $LogFile
        }

        DS_WriteLog "-" "" $LogFile

        ##############################################################################################
        # Determine if the PNAgent service at the specified virtual path and IIS site exists
        ##############################################################################################
        $StoreName = $Store.Name
        DS_WriteLog "I" "Determine if the PNAgent on the store '$StoreName' in the IIS site $SiteId is enabled" $LogFile
        try {
            $storePnaSettings = Get-STFStorePna -StoreService $Store
        } catch {
            DS_WriteLog "E" "An error occurred trying to determine if the PNAgent on the store '$StoreName' is enabled" $LogFil
            Exit 1
        }

        # Enable the PNAgent if required
        if ( $EnablePNAgent -eq $True ) {
            if ( !($storePnaSettings.PnaEnabled) ) {
                DS_WriteLog "I" "The PNAgent is not enabled on the store '$StoreName'" $LogFile
                DS_WriteLog "I" "Enable the PNAgent on the store '$StoreName'" $LogFile

                # Check for the following potential error: AllowUserPasswordChange is only compatible with logon method 'Prompt' authentication
                if ( ($PNAgentAllowUserPwdChange -eq $True) -and ( !($LogonMethod -eq "Prompt")) ) {
                    DS_WriteLog "I" "Important: AllowUserPasswordChange is only compatible with LogonMethod Prompt authentication" $LogFile
                    DS_WriteLog "I" "           The logon method is set to $LogonMethod, therefore AllowUserPasswordChange has been set to '`$false'" $LogFile
                    $PNAgentAllowUserPwdChange = $False
                }

                # Enable the PNAgent
                if ( ($PNAgentAllowUserPwdChange -eq $True) -and ($PNAgentDefaultService -eq $True) ) {
                    try {
                        Enable-STFStorePna -StoreService $store -AllowUserPasswordChange -DefaultPnaService -LogonMethod $LogonMethod
                        DS_WriteLog "S" "The PNAgent was enabled successfully on the store '$StoreName'" $LogFile
                        DS_WriteLog "S" "   -Allow user change password: yes" $LogFile
                        DS_WriteLog "S" "   -Default PNAgent service: yes" $LogFile
                    } catch {
                        DS_WriteLog "E" "An error occurred trying to enable the PNAgent on the store '$StoreName' (error: $($Error[0]))" $LogFile
                        Exit 1
                    }
                }
                if ( ($PNAgentAllowUserPwdChange -eq $False) -and ($PNAgentDefaultService -eq $True) ) {
                    try {
                        Enable-STFStorePna -StoreService $store -DefaultPnaService -LogonMethod $LogonMethod
                        DS_WriteLog "S" "The PNAgent was enabled successfully on the store '$StoreName'" $LogFile
                        DS_WriteLog "S" "   -Allow user change password: no" $LogFile
                        DS_WriteLog "S" "   -Default PNAgent service: yes" $LogFile
                    } catch {
                        DS_WriteLog "E" "An error occurred trying to enable the PNAgent on the store '$StoreName' (error: $($Error[0]))" $LogFile
                        Exit 1
                    }
                }
                if ( ($PNAgentAllowUserPwdChange -eq $True) -and ($PNAgentDefaultService -eq $False) ) {
                    try {
                        Enable-STFStorePna -StoreService $store -AllowUserPasswordChange -LogonMethod $LogonMethod
                        DS_WriteLog "S" "The PNAgent was enabled successfully on the store '$StoreName'" $LogFile
                        DS_WriteLog "S" "   -Allow user change password: yes" $LogFile
                        DS_WriteLog "S" "   -Default PNAgent service: no" $LogFile
                    } catch {
                        DS_WriteLog "E" "An error occurred trying to enable the PNAgent on the store '$StoreName' (error: $($Error[0]))" $LogFile
                        Exit 1
                    }
                }      
            } else {
                DS_WriteLog "I" "The PNAgent is already enabled on the store '$StoreName' in the IIS site $SiteId" $LogFile
            }
        } else {
            DS_WriteLog "I" "The PNAgent should not be enabled on the store '$StoreName' in the IIS site $SiteId" $LogFile
        }

        DS_WriteLog "-" "" $LogFile
    }
 
    end {
        DS_WriteLog "I" "END FUNCTION - $FunctionName" $LogFile
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
$PackageName = "Citrix StoreFront (configure)"                  # [edit] enter the display name of the software (e.g. 'Arcobat Reader' or 'Microsoft Office')

# Global variables
$ComputerName = $env:ComputerName
$StartDir = $PSScriptRoot # the directory path of the script currently being executed
if (!($Installationtype -eq "Uninstall")) { $Installationtype = "Install" }
$LogDir = (Join-Path $BaseLogDir $PackageName).Replace(" ","_")
$LogFileName = "$($Installationtype)_$($PackageName).log"
$LogFile = Join-path $LogDir $LogFileName

# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }

# Create new log file (overwrite existing one)
New-Item $LogFile -ItemType "file" -force | Out-Null

DS_WriteLog "I" "START SCRIPT - $PackageName" $LogFile
DS_WriteLog "-" "" $LogFile

# ---------------------------------------------------------------------------------------------------------------------------

# Install/import a root certificate to the local machine "Trusted Root Certificates Authorities" certificate store 
$CertFile = Join-Path $StartDir "\MyRootCert.cer"
DS_InstallCertificate -StoreScope "LocalMachine" -StoreName "Root" -CertFile $CertFile

DS_WriteLog "-" "" $LogFile

# Install/import a password protected personal certificate including private key to the local machine "Personal" store
$CertFile = Join-Path $StartDir "\MyPersonalCert.pfx"
DS_InstallCertificate -StoreScope "LocalMachine" -StoreName "My" -CertFile $CertFile -CertPassword "123456"

DS_WriteLog "-" "" $LogFile

# Create the StoreFront deployment, store and farm with SSL communication to the Delivery Controllers and port 80 and 554 enabled on the IIS site and PNAgent enabled
DS_CreateStoreFrontStore -FriendlyName "MyStore" -HostbaseUrl "https://portal.awspocc.com" -CertSubjectName "$($env:ComputerName).awspocc.com" -AddHostHeaderToIISSiteBinding $False -FarmName "MyFarm" -FarmServers "Server1.mydomain.com","Server2.mydomain.com" -StoreVirtualPath "/Citrix/MyStore" -ReceiverVirtualPath "/Citrix/MyStoreWeb" -LoadBalanceServers $True -XMLPort 443 -HTTPPort 80 -HTTPSPort 443 -TransportType "HTTPS" -EnablePNAgent $True -PNAgentDefaultService $True -LogonMethod "SSON"

DS_WriteLog "-" "" $LogFile

# Disable Customer Experience Improvement Program (CEIP)
DS_WriteLog "I" "Disable Customer Experience Improvement Program (CEIP)" $LogFile
DS_SetRegistryValue -RegKeyPath "hklm:\SOFTWARE\Citrix\Telemetry\CEIP" -RegValueName "Enabled" -RegValue "0" -Type "DWORD"

# ---------------------------------------------------------------------------------------------------------------------------

# Enable File Security  
Remove-Item env:\SEE_MASK_NOZONECHECKS

DS_WriteLog "-" "" $LogFile
DS_WriteLog "I" "End of script" $LogFile 
