function Install-NunyaPackage {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [string]$SilentArgs,
        [string]$LogArgs
    )
    
    # Test if file exist
    if (!(Test-Path $FilePath)) { throw "`"$FilePath`" file cannot be found. Check the -FilePath parameter and try again" }
    
    # Setup loging directory and log paths
    $nunyaLogDirectory = Join-Path $env:temp "Nunya"
    $filenameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $filename = [System.IO.Path]::GetFileName($FilePath)
    $installerLogDirectory = Join-Path $nunyaLogDirectory $filenameWOExtention
    if (!(Test-Path $installerLogDirectory)) { New-Item -Path $installerLogDirectory -ItemType Directory | Out-Null }
    $stdOutLog = Join-Path $installerLogDirectory "stdOut.log"
    $stdErrLog = Join-Path $installerLogDirectory "stdErr.log"
    $exitCodeLog = Join-Path $installerLogDirectory "exitCode.log"

    $fileType = [System.IO.Path]::GetExtension($FilePath).Replace(".", "")
    
    switch ($fileType) {
        "msi" 
        {  
            # Set default silent args for MSI install if none are provided
            $installLog = Join-Path $installerLogDirectory "install.log"
            if (!$SilentArgs) { $SilentArgs = "/quiet /norestart" }
            if (!$LogArgs) { $LogArgs = "/l*vx `"$InstallLog`""}
            $msiArgs = "/i `"$FilePath`""
            
            Write-Debug "Starting MSI installer:  $env:SystemRoot\System32\msiexec.exe with Arguments: $msiArgs $LogArgs $SilentArgs"
            Write-Verbose "Installing .msi type: $filename..."
            
            $process = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList $msiArgs, $LogArgs, $SilentArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            $process.ExitCode | Out-File -FilePath $exitCodeLog 
            
            return $process.ExitCode
        }
        "msu" 
        {
            # Set default silent args for MSI install if none are provided
            $installLog = Join-Path $installerLogDirectory "install.etl"
            if (!$SilentArgs) { $SilentArgs = "/quiet /norestart"}
            if (!$LogArgs) { $LogArgs = "/log:`"$installLog`"" }
            $msuArgs = "`"$FilePath`""

            Write-Debug "Starting MSU installer:  $env:SystemRoot\System32\wusa.exe with Arguments: $msuArgs $LogArgs $SilentArgs"
            Write-Verbose "Installing .msu type: $filename..."

            $process = Start-Process -FilePath "$env:SystemRoot\System32\wusa.exe" -ArgumentList $msuArgs, $LogArgs, $SilentArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            $process.ExitCode | Out-File -FilePath $exitCodeLog
            
            return $process.ExitCode 
        }
        "exe" 
        {   
            
            $productType = getProductType -File $file

            if (!$SilentArgs) { $SilentArgs = getExeSilentArgs -ExeProductType $productType }
            if (!$LogArgs) { $LogArgs = getExeLogArgs -ExeProductType $productType }

            Write-Debug "Starting EXE installer:  $filename : $SilentArgs $LogArgs"
            Write-Verbose "Installing .exe type: $filename..."

            if (!$LogArgs) {
                $process = Start-Process -FilePath "$FilePath" -ArgumentList $SilentArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
                $process.ExitCode | Out-File -FilePath $exitCodeLog
            }
            else {
                $process = Start-Process -FilePath "$FilePath" -ArgumentList $SilentArgs, $LogArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
                $process.ExitCode | Out-File -FilePath $exitCodeLog
            }

            return $process.ExitCode 
        }

        Default { throw "Unknown file type `".$fileType`" , Install-NunyaPackage can install, .msi, .msu, or .exe file types"}
    }
}

function getProductType ($FilePath) {
    $file = Get-ChildItem -Path $FilePath
    if ($file.VersionInfo.ProductName -like '*adobe*') { "Adobe" }
    elseif ($file.VersionInfo.ProductName -like '*java*') { "Java" }
    elseif ($file.Name -like '*Firefox*') { "Firefox" }
    else { "Unkown" }
}

function getExeSilentArgs ($ExeProductType) {
    switch ($ExeProductType) 
            {
               "Adobe" { return "/sAll /rs" }
               "Java" { return "/s" }
               "Firefox" { return "-ms" }
               "Microsoft" { return "/q /norestart" }
               Default { return "/q /norestart" } 
            } 
}

function getExeLogArgs ($ExeProductType) {
    switch ($ExeProductType) 
            {
               "Adobe" { return $null }
               "Java" { return $null}
               "Firefox" { return $null }
               "Microsoft" { return $null }
               Default { return $null } 
            }
}



