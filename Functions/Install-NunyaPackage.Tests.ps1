$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

#Act, Arrange, Assert
Describe "Install-NunyaPackage" {
    
    Mock Start-Process {}
    
    It "throws error if file does not exist" {
        #Arrange
        $fileThatDoesNotExist = "DoesNotExist.exe"
        $throwError = "`"$fileThatDoesNotExist`" file cannot be found. Check the -FilePath parameter and try again"
        #Act & Assert
        { Install-NunyaPackage -FilePath $fileThatDoesNotExist -SilentArgs "/S" }| Should throw $throwError
    }

    Context "Test switch for install type .msi" {
        #Arrange

        # Install-NunyaPackage args
        $fiePath = "c:\test.msi"
        $argumentList = "/quiet /norestart"

        # Mocking args and vars
        $nunyaLogDirectory = Join-Path $env:temp "Nunya"
        $filenameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($fiePath)
        $filename = [System.IO.Path]::GetFileName($fiePath)
        $installerLogDirectory = Join-Path $nunyaLogDirectory $filenameWOExtention
        $exitCodeLog = Join-Path $installerLogDirectory "exitCode.log"
        $InstallLog = Join-Path $installerLogDirectory "install.log"
        
        $startProcArgList = "/i `"$fiePath`" /l*vx `"$InstallLog`" /quiet /norestart"
        $msiExecPath = "$env:SystemRoot\System32\msiexec.exe"
        
        Mock Start-Process {[PSCustomObject]@{ExitCode = 5}} -ParameterFilter { ($FilePath -eq $msiExecPath) -and ($ArgumentList -eq $startProcArgList) }
        Mock Out-File {}
        
        #mock the first Test-Path, the one that checks to see if the installer file exist
        Mock Test-Path { $true } -ParameterFilter { $Path -eq $fiePath }

        It "Should execute msi switch block" {
            #Act
            # Always make this an array, sometimes it  might only return one item in the pipeline
            #   if an exit code is not returned.  This always wraps the item(s) in an array
            #   I am only interested in the first item the verbose message for this test
            $result = @(Install-NunyaPackage -FilePath $fiePath -SilentArgs $argumentList -Verbose 4>&1)[0]
            #Assert
            $result | Should Match "installing $filename"
        }

        It "Should run Start-Process with correct args for MSI install" {          
            #Act
            #$result = Install-NunyaPackage -FilePath $fiePath -SilentArgs $argumentList
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { ($FilePath -eq $msiExecPath) -and ($ArgumentList -eq $startProcArgList) } -Exactly 1
        }

        It "Should write ExitCode to file, Out-File with correct args" {
            #Assert
            Assert-MockCalled Out-File -ParameterFilter { ($FilePath -eq $exitCodeLog) -and ($InputObject -eq 5) } -Exactly 1
        }
    }
}
