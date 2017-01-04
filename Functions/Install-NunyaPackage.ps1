function Install-NunyaPackage {
    [CmdletBinding()]
    param(
        [string]$FilePath,
        [string[]]$SilentArgs
    )
    
    # Setup loging directory and log paths
    $nunyaLogDirectory = Join-Path $env:temp "Nunya"
    $filnameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
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
            $process = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            return $process.ExitCode
        }
        "msu" 
        {
            $InstallLogPath = Join-Path $installerLogDirectory "install.etl"
            $msuArgs = "`"$FilePath`" /log:`"$InstallLogPath`" $SilentArgs"

            $process = Start-Process -FilePath "$env:SystemRoot\System32\wusa.exe" -ArgumentList $msuArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            return $process.ExitCode
        }
        "exe" 
        {
            $process = Start-Process -FilePath "$FilePath" -ArgumentList $SilentArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
            return $process.ExitCode
        }
        Default { throw "Unknown file type , Install-NunyaPackage can install, .msi, .msu, and .exe file types"}
    }
}


Install-NunyaPackage -FilePath "C:\Users\robert.p.courtney\Desktop\Win7x6-Client-Image-Patches\Win7x64\MS16-087\Windows6.1-KB3170455-x64.msu" -SilentArgs "/quiet /norestart"

