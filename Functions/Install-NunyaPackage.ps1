function Install-NunyaPackage {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [string[]]$SilentArgs = ""
    )
    
    # Test if file exist
    if (!(Test-Path $FilePath)) { throw "`"$FilePath`" file cannot be found. Check the -FilePath parameter and try again" }

    # Setup loging directory and log paths
    $nunyaLogDirectory = Join-Path $env:temp "Nunya"
    $filnameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $filename = [System.IO.Path]::GetFileName($FilePath)
    $installerLogDirectory = Join-Path $nunyaLogDirectory $filnameWOExtention
    if (!(Test-Path $installerLogDirectory)) { New-Item -Path $installerLogDirectory -ItemType Directory | Out-Null }
    $stdOutLog = Join-Path $installerLogDirectory "stdOut.log"
    $stdErrLog = Join-Path $installerLogDirectory "stdErr.log"

    $fileType = [System.IO.Path]::GetExtension($FilePath).Replace(".", "")
    
    switch ($fileType) {
        "msi" 
        {  
            $InstallLogPath = Join-Path $installerLogDirectory "install.log"
            $msiArgs = "/i `"$FilePath`" /l*vx `"$InstallLogPath`" $SilentArgs"
            Write-Debug "Starting MSI installer:  $env:SystemRoot\System32\msiexec.exe with Arguments: $msiArgs"
            Write-Verbose "Installing $filename..."
            $process = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            $exitCode = $process.ExitCode
            # return exit code if not null or empty
            if ($process.ExitCode) { return $process.ExitCode }
        }
        "msu" 
        {
            $InstallLogPath = Join-Path $installerLogDirectory "install.etl"
            $msuArgs = "`"$FilePath`" /log:`"$InstallLogPath`" $SilentArgs"

            $process = Start-Process -FilePath "$env:SystemRoot\System32\wusa.exe" -ArgumentList $msuArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            # return exit code if not null or empty
            if ($process.ExitCode) { return $process.ExitCode }
        }
        "exe" 
        {
            $process = Start-Process -FilePath "$FilePath" -ArgumentList $SilentArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            $exitCode = $process.ExitCode
            # return exit code if not null or empty
            if ($process.ExitCode) { return $process.ExitCode }
        }
        Default { throw "Unknown file type `".$fileType`" , Install-NunyaPackage can install, .msi, .msu, or .exe file types"}
    }
}

#Install-NunyaPackage -FilePath "C:\Users\robert.p.courtney\Desktop\Win7x6-Client-Image-Patches\Win7x64\MS16-087\Windows6.1-KB3170455-x64.msu" -SilentArgs "/quiet /norestart"
#Install-NunyaPackage -FilePath "c:test.exe" -SilentArgs "/s"

