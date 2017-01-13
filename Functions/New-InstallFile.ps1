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
    $fileType = [System.IO.Path]::GetExtension($FilePath).Replace(".", "")
    $installerType = $FullName.Split('.')[-1]
    $filenameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $installerFileName = Split-Path -Path $FullName -Leaf
    switch ($installerType) {
    'msi' { 
            (Get-Content $PSScriptRoot\..\Resources\MSI-MSU.template) -replace "#FilePath#", $installerFileName
          }
    'msu' { 
            (Get-Content $PSScriptRoot\..\Resources\MSI-MSU.template) -replace "#FilePath#", $installerFileName
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
                    $silentArgs = "/sAll /rs"
                    ((Get-Content $PSScriptRoot\..\Resources\Standard-EXE.template) -replace "#FilePath#", $installerFileName) -replace "#SilentArgs#", $silentArgs
                }
               "Java" 
               { 
                   $silentArgs = "/s"
                    ((Get-Content $PSScriptRoot\..\Resources\Standard-EXE.template) -replace "#FilePath#", $installerFileName) -replace "#SilentArgs#", $silentArgs
               }
               "Firefox" 
               {
                   $silentArgs = "-ms"
                    ((Get-Content $PSScriptRoot\..\Resources\Standard-EXE.template) -replace "#FilePath#", $installerFileName) -replace "#SilentArgs#", $silentArgs
               }
               "Microsoft" {
                   $nunyaLogDirectory = Join-Path $env:temp "Nunya"
                   $installerLogDirectory = Join-Path $nunyaLogDirectory $filenameWOExtention
                   $silentArgs = "/q /norestart"
                   $logArgs = "/Log $nunyaLogDirectory = Join-Path $env:temp "Nunya""
                    ((Get-Content $PSScriptRoot\..\Resources\Standard-EXE.template) -replace "#FilePath#", $installerFileName) -replace "#SilentArgs#", $silentArgs
               }
               Default 
               {   
                   $silentArgs = "/q /norestart"
                    ((Get-Content $PSScriptRoot\..\Resources\Standard-EXE.template) -replace "#FilePath#", $installerFileName) -replace "#SilentArgs#", $silentArgs
               } 
            }
          }
    }
} 




















