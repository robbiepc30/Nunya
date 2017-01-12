function Install-NunyaPackage {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [string[]]$SilentArgs
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
            if (!$SilentArgs) { $SilentArgs = "/quiet /norestart"}
            $msiArgs = "/i `"$FilePath`" /l*vx `"$InstallLog`" $SilentArgs"
            
            Write-Debug "Starting MSI installer:  $env:SystemRoot\System32\msiexec.exe with Arguments: $msiArgs"
            Write-Verbose "Installing .msi type: $filename..."
            
            $process = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            $process.ExitCode | Out-File -FilePath $exitCodeLog 
            # return exit code if not null or empty Needed for Pester Test
            return $process.ExitCode
        }
        "msu" 
        {
            # Set default silent args for MSI install if none are provided
            if (!$SilentArgs) { $SilentArgs = "/quiet /norestart"}
            $installLog = Join-Path $installerLogDirectory "install.etl"
            $msuArgs = "`"$FilePath`" /log:`"$installLog`" $SilentArgs"

            Write-Debug "Starting MSU installer:  $env:SystemRoot\System32\wusa.exe with Arguments: $msuArgs"
            Write-Verbose "Installing .msu type: $filename..."

            $process = Start-Process -FilePath "$env:SystemRoot\System32\wusa.exe" -ArgumentList $msuArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            $process.ExitCode | Out-File -FilePath $exitCodeLog
            
            return $process.ExitCode 
        }
        "exe" 
        {
            if (!$SilentArgs) { throw '-SilentArgs Parameter must be provided an argument.  Example: -SilentArgs "/S"'}
            Write-Debug "Starting EXE installer:  $filename : $SilentArgs"
            Write-Verbose "Installing .exe type: $filename..."

            $process = Start-Process -FilePath "$FilePath" -ArgumentList $SilentArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            $process.ExitCode | Out-File -FilePath $exitCodeLog
            
            return $process.ExitCode 
        }
        Default { throw "Unknown file type `".$fileType`" , Install-NunyaPackage can install, .msi, .msu, or .exe file types"}
    }
}

