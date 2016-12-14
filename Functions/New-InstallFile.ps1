function New-InstallFile
{
    [CmdletBinding()]
    Param
    (
        # Path search and create installer files
        $Path = '.',

        # Installer Types msu, msi, exe
        [ValidateSet("msu", "msi", "exe")]
        [String[]]$Type = @("msu", "msi", "exe")
    )

    Process
    {
        $includeTypes = $Type |  ForEach-Object {"*.$_"}
        $fileList = Get-ChildItem -Path $Path -Include $includeTypes -Recurse
        
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
    $installerType = $FullName.Split('.')[-1]
    $installerFileName = Split-Path -Path $FullName -Leaf
    switch ($installerType) {
    'msi' { 
            '# Invoke Installer
            $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$PSScriptRoot\#MSUFile#`" /quiet /norestart" -Wait -PassThru
            Exit $process.ExitCode' -replace "#MSUFile#", $installerFileName 
          }
    'exe' { 
            $productType = if ($File.VersionInfo.ProductName -like '*adobe*') {"Adobe"}
                           elseif ($File.VersionInfo.ProductName -like '*java*') {"Java"}
            switch ($productType) {
                "Adobe" { 
                        '# Invoke Installer
                        $process = Start-Process -FilePath `"$PSScriptRoot\#MSUFile#`" -ArgumentList "/sAll /rs" -Wait -PassThru
                        Exit $process.ExitCode' -replace "#MSUFile#", $installerFileName 
                       }
               "Java"  { 
                         '# Invoke Installer
                         $process = Start-Process -FilePath `"$PSScriptRoot\#MSUFile#`" -ArgumentList "/s" -Wait -PassThru
                         Exit $process.ExitCode' -replace "#MSUFile#", $installerFileName 
                       }
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




















