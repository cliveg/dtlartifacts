<##################################################################################################

    Description
    ===========

	- This script does the following - 
		- installs chocolatey
		- installs specified chocolatey packages

	- This script generates logs in the following folder - 
		- %ALLUSERSPROFILE%\ChocolateyPackageInstaller-{TimeStamp}\Logs folder.


    Usage examples
    ==============
    
    Powershell -executionpolicy bypass -file ChocolateyPackageInstaller.ps1


    Pre-Requisites
    ==============

    - Ensure that the powershell execution policy is set to unrestricted (@TODO).


    Known issues / Caveats
    ======================
    
    - No known issues.


    Coming soon / planned work
    ==========================

    - N/A.    

##################################################################################################>

#
# Optional arguments to this script file.
#

Param(
    # comma or semicolon separated list of chocolatey packages.
    [ValidateNotNullOrEmpty()]
    [string]
    $RawPackagesList
)

##################################################################################################

#
# Powershell Configurations
#

# Note: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.  
$ErrorActionPreference = "stop"

# Ensure that current process can run scripts. 
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force 

###################################################################################################

#
# Custom Configurations
#

$ChocolateyPackageInstallerFolder = Join-Path $env:ALLUSERSPROFILE -ChildPath $("ChocolateyPackageInstaller-" + [System.DateTime]::Now.ToString("yyyy-MM-dd-HH-mm-ss"))

# Location of the log files
$ScriptLog = Join-Path -Path $ChocolateyPackageInstallerFolder -ChildPath "ChocolateyPackageInstaller.log"
$ChocolateyInstallLog = Join-Path -Path $ChocolateyPackageInstallerFolder -ChildPath "ChocolateyInstall.log"

##################################################################################################

# 
# Description:
#  - Displays the script argument values (default or user-supplied).
#
# Parameters:
#  - N/A.
#
# Return:
#  - N/A.
#
# Notes:
#  - Please ensure that the Initialize() method has been called at least once before this 
#    method. Else this method can only write to console and not to log files. 
#

function DisplayArgValues
{
    WriteLog "========== Configuration =========="
    WriteLog $("RawPackagesList : " + $RawPackagesList)
    WriteLog "========== Configuration =========="
}

##################################################################################################

# 
# Description:
#  - Creates the folder structure which'll be used for dumping logs generated by this script and
#    the logon task.
#
# Parameters:
#  - N/A.
#
# Return:
#  - N/A.
#
# Notes:
#  - N/A.
#

function InitializeFolders
{
    if ($false -eq (Test-Path -Path $ChocolateyPackageInstallerFolder))
    {
        New-Item -Path $ChocolateyPackageInstallerFolder -ItemType directory | Out-Null
    }
}

##################################################################################################

# 
# Description:
#  - Writes specified string to the console as well as to the script log (indicated by $ScriptLog).
#
# Parameters:
#  - $message: The string to write.
#
# Return:
#  - N/A.
#
# Notes:
#  - N/A.
#

function WriteLog
{
    Param(
        <# Can be null or empty #> $message
    )

    $timestampedMessage = $("[" + [System.DateTime]::Now + "] " + $message) | % {  
        Write-Host -Object $_
        Out-File -InputObject $_ -FilePath $ScriptLog -Append
    }
}

##################################################################################################

# 
# Description:
#  - Installs the chocolatey package manager.
#
# Parameters:
#  - N/A.
#
# Return:
#  - If installation is successful, then nothing is returned.
#  - Else a detailed terminating error is thrown.
#
# Notes:
#  - @TODO: Write to $chocolateyInstallLog log file.
#  - @TODO: Currently no errors are being written to the log file ($chocolateyInstallLog). This needs to be fixed.
#

function InstallChocolatey
{
    Param(
        [ValidateNotNullOrEmpty()] $chocolateyInstallLog
    )

    WriteLog "Installing Chocolatey..."

    Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) | Out-Null

    WriteLog "Success."
}

##################################################################################################

#
# Description:
#  - Installs the specified chocolatet packages on the machine.
#
# Parameters:
#  - N/A.
#
# Return:
#  - N/A.
#
# Notes:
#  - N/A.
#

function InstallPackages
{
    Param(
        [ValidateNotNullOrEmpty()][string] $packagesList
    )

    $Separator = @(";",",")
    $SplitOption = [System.StringSplitOptions]::RemoveEmptyEntries
    $packages = $packagesList.Trim().Split($Separator, $SplitOption)

    if (0 -eq $packages.Count)
    {
        WriteLog $("No packages were specified. Exiting...")
        return        
    }

    foreach ($package in $packages)
    {
        WriteLog $("Installing package: " + $package)

        # install git via chocolatey
        choco install $package --force --yes --acceptlicense --verbose | Out-Null 

        if ($? -eq $false)
        {
            $errMsg = $("Error! Installation failed. Please see the chocolatey logs in %ALLUSERSPROFILE%\chocolatey\logs folder for details.")
            WriteLog $errMsg
            Write-Error $errMsg 
        }
    
        WriteLog "Success."        
    }
}

##################################################################################################

#
# Description:
#  - Configure MDT on the machine.
#
# Parameters:
#  - N/A.
#
# Return:
#  - N/A.
#
# Notes:
#  - N/A.
#

function ConfigureMDT
{

# Setup-DeploymentShare
New-Item -Path "C:\DeploymentShare" -ItemType directory -ErrorAction SilentlyContinue
New-SmbShare -Name "DeploymentShare$" -Path "C:\DeploymentShare" -FullAccess Administrators -ErrorAction SilentlyContinue
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"

# Update NetworkPath if server name not MDTServer
new-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root "C:\DeploymentShare" -Description "MDT Deployment Share" -NetworkPath ("\\" + $env:computername + "\DeploymentShare$") -Verbose | add-MDTPersistentDrive -Verbose -ErrorAction SilentlyContinue

# Update SourcePath
Import-Module BitsTransfer  
Start-BitsTransfer -Source 'http://care.dlservice.microsoft.com/dl/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO' -Destination 'C:\Win2012r2.iso'
Mount-DiskImage -ImagePath 'D:\Win2012r2.iso'
import-mdtoperatingsystem -path "DS001:\Operating Systems" -SourcePath "F:\" -DestinationFolder "win2012r2" -Verbose
DisMount-DiskImage -ImagePath 'C:\DeploymentShare\Win2012r2.iso'

# Update Packages example below for WMF 5.0
new-item -path "DS001:\Packages" -enable "True" -Name "Win2012r2" -Comments "" -ItemType "folder" -Verbose
New-Item -Path "C:\DeploymentShare\PackageSource" -ItemType directory
Invoke-WebRequest -Uri 'http://go.microsoft.com/fwlink/?LinkId=717507' -OutFile 'C:\DeploymentShare\PackageSource\Win8.1AndW2K12R2-KB3134758-x64.msu'
import-mdtpackage -path "DS001:\Packages\Win2012r2" -SourcePath "C:\DeploymentShare\PackageSource" -Verbose

# Setup MDT Applications
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/cliveg/dtlartifacts/master/mdt/EnableRDP.ps1' -OutFile 'C:\DeploymentShare\Applications\EnableRDP.ps1'
new-item -path "DS001:\Applications" -enable "True" -Name "Tweaks" -Comments "" -ItemType "folder" -Verbose
import-MDTApplication -path "DS001:\Applications\Tweaks" -enable "True" -Name "Microsoft Enable Remote Desktop" -ShortName "Enable Remote Desktop" -Version "" -Publisher "Microsoft" -Language "" -CommandLine "Powershell -noprofile -executionpolicy bypass -file .\EnableRDP.ps1" -WorkingDirectory ".\Applications" -NoSource -Verbose

# Create Task Sequence
import-mdttasksequence -path "DS001:\Task Sequences" -Name "Windows Server 2012 R2 Standard" -Template "Server.xml" -Comments "" -ID "Server2012r2std" -Version "1.0" -OperatingSystemPath "DS001:\Operating Systems\Windows Server 2012 R2 SERVERSTANDARD in win2012r2 install.wim" -FullName "Employee" -OrgName "Microsoft Corporation" -HomePage "about:blank" -AdminPassword "P@ssword1" -Verbose
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/cliveg/dtlartifacts/master/mdt/ts.xml' -OutFile 'C:\DeploymentShare\Control\SERVER2012R2STD\ts.xml'

# Update CustomerSettings.ini and Bootstrap.ini
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/cliveg/dtlartifacts/master/mdt/CustomSettings.ini' -OutFile 'C:\DeploymentShare\Control\CustomSettings.ini'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/cliveg/dtlartifacts/master/mdt/Bootstrap.ini' -OutFile 'C:\DeploymentShare\Control\Bootstrap.ini'
Add-Content C:\DeploymentShare\Control\Bootstrap.ini ("`nDeployRoot=\\" + $env:computername + "\DeploymentShare$")
New-Item -Path "C:\DeploymentShare\SLShare" -ItemType directory
Add-Content C:\DeploymentShare\Control\CustomSettings.ini ("`nSLShare=\\" + $env:computername + "\DeploymentShare$\SLShare")
Add-Content C:\DeploymentShare\Control\CustomSettings.ini ("`nEventService=http://" + $env:computername + ":9800")

Invoke-WebRequest -Uri 'https://download.microsoft.com/download/5/0/8/508918E1-3627-4383-B7D8-AA07B3490D21/ConfigMgrTools.msi' -OutFile 'C:\DeploymentShare\ConfigMgrTools.msi'
Start-Process 'C:\DeploymentShare\ConfigMgrTools.msi' /qn -Wait

# Update Deployment Share
update-MDTDeploymentShare -path "DS001:" -Verbose

}

##################################################################################################



#
# 
#

try
{
    #
    InitializeFolders

    #
    DisplayArgValues
    
    # install the chocolatey package manager
    InstallChocolatey -chocolateyInstallLog $ChocolateyInstallLog

    # install the specified packages
    InstallPackages -packagesList $RawPackagesList

    # configure MDT
    ConfigureMDT


}
catch
{
    if (($null -ne $Error[0]) -and ($null -ne $Error[0].Exception) -and ($null -ne $Error[0].Exception.Message))
    {
        $errMsg = $Error[0].Exception.Message
        WriteLog $errMsg
        Write-Host $errMsg
    }

    # Important note: Throwing a terminating error (using $ErrorActionPreference = "stop") still returns exit 
    # code zero from the powershell script. The workaround is to use try/catch blocks and return a non-zero 
    # exit code from the catch block. 
    exit -1
}