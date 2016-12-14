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
        $msuInstallSyntax = 'Start-Process  WUSA -ArgumentList "#MSUFile# /quiet /norestart" -Wait -PassThru' -replace "#MSUFile#", $installerFileName
        $fileNameList = Get-ChildItem -Path $Path -Include *.msu,*.msi -Recurse | select -ExpandProperty FullName
        
        foreach ($f in $fileNameList) {
                
                $installerFileName = Split-Path -Path $f -Leaf
                $ps1InstallFileName = $f + ".Install.ps1"

                $code = generateInstallerCode -InstallerFileName $installerFileName
                createFile -Name $ps1InstallFileName -Content $code
        }
    }
}

function createFile ($Name, $Content)
{
    Write-Verbose "Creating $Name File"
    Set-Content -Path $Name -Value $Content -Encoding UTF8
}

function generateInstallerCode ($InstallerFileName) {
    $type = $installerFileName.Split('.')[-1]
    switch ($type) {
    'msi' { 
            '# Invoke Installer
            $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$PSScriptRoot\#MSUFile#`" /quiet /norestart" -Wait -PassThru
            Exit $process.ExitCode' -replace "#MSUFile#", $installerFileName 
          }
    'exe' { 
            '# Invoke Installer
            $process = Start-Process -FilePath `"$PSScriptRoot\#MSUFile#`" -ArgumentList "/q /norestart" -Wait -PassThru
            Exit $process.ExitCode' -replace "#MSUFile#", $installerFileName 
          }
    'msu' { 
            '# Invoke Installer
            $process = Start-Process  -FilePath wusa.exe -ArgumentList "`"$PSScriptRoot\#MSUFile#`" /quiet /norestart" -Wait -PassThru
            Exit $process.ExitCode' -replace "#MSUFile#", $installerFileName }
          }
} 




















