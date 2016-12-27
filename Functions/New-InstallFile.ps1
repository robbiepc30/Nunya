function New-InstallFile
{
    [CmdletBinding()]
    Param
    (
        # Path search and create installer files
        $Path = '.',

        # Installer Types msu, msi, exe
        [ValidateSet("msu", "msi", "exe")]
        [String[]]$Type = @("msu", "msi", "exe"),
        [Switch]$Force
    )

    $includeTypes = $Type |  ForEach-Object {"*.$_"}
    $fileList = Get-ChildItem -Path $Path -Include $includeTypes -Recurse
    
    foreach ($f in $fileList) {
            $code = generateInstallerCode -File $f
            createInstallerFile -File $f -Code $code
    }

}

function createInstallerFile ($File, $Code)
{
    $FullName = $File.FullName
    $installerFileName = Split-Path -Path $FullName -Leaf
    $ps1InstallFileName = $FullName + ".Install.ps1"

    # If force switch is used overwrite file if it already exist
    if ($Force) {
        Write-Verbose "Creating $ps1InstallFileName File"
        Set-Content -Path $ps1InstallFileName -Value $Code -Encoding UTF8 
    } 
    else { # Check if file already exist, if so give warning
        if (!(Test-Path -Path $ps1InstallFileName)) {
            Write-Verbose "Creating $ps1InstallFileName File"
            Set-Content -Path $ps1InstallFileName -Value $Code -Encoding UTF8  
        } 
        else {
            Write-Warning -Message "$ps1InstallFileName file already exist, use -Force switch to overwrite file"
        }
    }
       
}

function generateInstallerCode ($File) 
{
    $FullName = $File.FullName
    $installerType = $FullName.Split('.')[-1]
    $installerFileName = Split-Path -Path $FullName -Leaf
    switch ($installerType) {
    'msi' { 
            '# Invoke Installer
            $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$PSScriptRoot\#File#`" /quiet /norestart" -Wait -PassThru
            Exit $process.ExitCode' -replace "#File#", $installerFileName 
          }
    'exe' { 
            $productType = if ($File.VersionInfo.ProductName -like '*adobe*') {"Adobe"}
                           elseif ($File.VersionInfo.ProductName -like '*java*') {"Java"}
                           elseif ($File.Name -like '*Firefox*') {"Firefox"}
                           else { "This is needed for Default to run..., otherwise if null switch will be skipped" }
            switch ($productType) 
            {
               "Adobe" 
                { 
                    '# Invoke Installer
                    $process = Start-Process -FilePath `""$PSScriptRoot\#File#"`" -ArgumentList "/sAll /rs" -Wait -PassThru
                    Exit $process.ExitCode' -replace "#File#", $installerFileName 
                }
               "Java" 
               { 
                    '# Invoke Installer
                    $process = Start-Process -FilePath `""$PSScriptRoot\#File#"`" -ArgumentList "/s" -Wait -PassThru
                    Exit $process.ExitCode' -replace "#File#", $installerFileName 
               }
               "Firefox" 
               {
                   '# Invoke Installer
                    $process = Start-Process -FilePath `""$PSScriptRoot\#File#"`" -ArgumentList "-ms" -Wait -PassThru
                    Exit $process.ExitCode' -replace "#File#", $installerFileName 
               }
               Default 
               {   
                    '# Invoke Installer
                    $process = Start-Process -FilePath `""$PSScriptRoot\#File#"`" -ArgumentList "/q /norestart" -Wait -PassThru
                    Exit $process.ExitCode' -replace "#File#", $installerFileName
               } 
            }
          }
    'msu' { 
            '# Invoke Installer
            $process = Start-Process  -FilePath wusa.exe -ArgumentList "`"$PSScriptRoot\#File#`" /quiet /norestart" -Wait -PassThru
            Exit $process.ExitCode' -replace "#File#", $installerFileName }
          }
} 




















