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
    
    if ($fileType -eq "msi")
    {
        $installLog = Join-Path $installerLogDirectory "install.log"
        $msiArgs = "/i `"$FilePath`" /l*vx `"$installLog`" $SilentArgs"
        $process = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
        $process.ExitCode
    }

    if ($fileType -eq "msu") 
    {
        $installLog = Join-Path $installerLogDirectory "install.etl"
        $msuArgs = "/log `"$installLog`" $SilentArgs"

        $process = Start-Process -FilePath "$env:SystemRoot\System32\wusa.exe" -ArgumentList $msuArgs -Wait -PassThru -RedirectStandardError $stdErrLog -RedirectStandardOutput $stdOutLog
        $process.ExitCode
    }
}


Install-NunyaPackage -FilePath "C:\Users\robert.p.courtney\Desktop\Win7x6-Client-Image-Patches\Win7x64\MS16-087\Windows6.1-KB3170455-x64.msu" -SilentArgs "/quiet /norestart"

