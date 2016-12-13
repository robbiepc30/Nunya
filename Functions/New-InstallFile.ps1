<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function New-InstallFile
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        $Path = '.',

        # Param2 help description
        [ValidateSet("msu", "msi", "exe")]
        [String[]]$Type
    )

    Process
    {
        
        $fileNameList = Get-ChildItem -Path $Path -Include *.msu -Recurse | select -ExpandProperty FullName
 
        foreach ($f in $fileNameList) {
                
                $installerFileName = Split-Path -Path $f -Leaf

                $code = '# Set Location to the path of this script
                        $currentPath = Split-Path -parent $MyInvocation.MyCommand.Definition
                        Set-Location -Path $currentPath
                
                        # Invoke Installer
                        $process = Start-Process  WUSA -ArgumentList "#MSUFile# /quiet /norestart" -Wait -PassThru
                        Exit $process.ExitCode' -replace "#MSUFile#", $installerFileName

                $ps1InstallFileName = $f + ".Install.ps1"

                createFile -Name $ps1InstallFileName -Content $code
        }
    }
}

function createFile ($Name, $Content)
{
    Set-Content -Path $Name -Value $Content -Encoding UTF8
}





















