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
        $fileList = Get-ChildItem -Path $Path -Include *.msu,*.msi, *.exe -Recurse
        
        foreach ($f in $fileList) {
                $code = generateInstallerCode -File $f
                createInstallerFile -File $f -Code $code
        }
    }
}

function createInstallerFile ($File, $Code)
{
    $FullName = $File.FullName
    $installerFileName = Split-Path -Path $FullName -Leaf
    $ps1InstallFileName = $FullName + ".Install.ps1"
    Write-Verbose "Creating $ps1InstallFileName File"
    Set-Content -Path $ps1InstallFileName -Value $Code -Encoding UTF8
    
}

function generateInstallerCode ($File) {
    $FullName = $File.FullName
    $type = $FullName.Split('.')[-1]
    $installerFileName = Split-Path -Path $FullName -Leaf
    switch ($type) {
    'msi' { 
            '# Invoke Installer
            $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$PSScriptRoot\#MSUFile#`" /quiet /norestart" -Wait -PassThru
            Exit $process.ExitCode' -replace "#MSUFile#", $installerFileName 
          }
    'exe' { 
            switch ($x) {
                condition {  }
                Default {
                            '# Invoke Installer
                             $process = Start-Process -FilePath `"$PSScriptRoot\#MSUFile#`" -ArgumentList "/q /norestart" -Wait -PassThru
                            Exit $process.ExitCode' -replace "#MSUFile#", $installerFileName }
            } 
          }
    'msu' { 
            '# Invoke Installer
            $process = Start-Process  -FilePath wusa.exe -ArgumentList "`"$PSScriptRoot\#MSUFile#`" /quiet /norestart" -Wait -PassThru
            Exit $process.ExitCode' -replace "#MSUFile#", $installerFileName }
          }
} 




















