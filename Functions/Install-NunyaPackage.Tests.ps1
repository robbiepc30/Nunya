$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

#Act, Arrange, Assert
Describe "Install-NunyaPackage" {
    
    Context "Test that applies to all install types" {
        # Just in case... mock out these cmdlets
        Mock Start-Process {}
        Mock Out-File {}

        It "throws error if file does not exist" {
            #Arrange
            $fileThatDoesNotExist = "DoesNotExist.exe"
            $throwError = "`"$fileThatDoesNotExist`" file cannot be found. Check the -FilePath parameter and try again"
            #Act & Assert
            { Install-NunyaPackage -FilePath $fileThatDoesNotExist -SilentArgs "/S" }| Should throw $throwError
        }
    }

    Context "Test switch for install type .msi" {
        #Arrange

        # Install-NunyaPackage args
        $filePath = "c:\test.msi"
        $silentArgs = "/quiet /norestart"

        # Mocking args and vars
        $nunyaLogDirectory = Join-Path $env:temp "Nunya"
        $filenameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        $filename = [System.IO.Path]::GetFileName($filePath)
        $installerLogDirectory = Join-Path $nunyaLogDirectory $filenameWOExtention
        $exitCodeLog = Join-Path $installerLogDirectory "exitCode.log"
        $InstallLog = Join-Path $installerLogDirectory "install.log"
        
        $msiArgs = "/i `"$filePath`" /l*vx `"$InstallLog`" $silentArgs"
        $msiExecPath = "$env:SystemRoot\System32\msiexec.exe"
        
        Mock Start-Process {[PSCustomObject]@{ExitCode = 8}} -ParameterFilter { ($FilePath -eq $msiExecPath) -and ($ArgumentList -eq $msiArgs) }
        Mock Out-File {}
        
        # Mock the first Test-Path, the one that checks to see if the installer file exist
        Mock Test-Path { $true } -ParameterFilter { $Path -eq $filePath }

        It "Should execute msi switch block" {
            #Act
            # Always make this an array, sometimes it  might only return one item in the pipeline
            #   if an exit code is not returned.  This always wraps the item(s) in an array
            #   I am only interested in the first item the verbose message for this test
            #$result = @(Install-NunyaPackage -FilePath $filePath -SilentArgs $silentArgs -Verbose 4>&1)[0]
            $result = @(Install-NunyaPackage -FilePath $filePath -SilentArgs $silentArgs -Verbose 4>&1)[0]
            #Assert
            $result | Should Match "Installing .msi type: $filename"
        }

        It "Should run Start-Process with correct args for MSI install" {          
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { ($FilePath -eq $msiExecPath) -and ($ArgumentList -eq $msiArgs) } -Exactly 1
        }

        It "Should write ExitCode to file, Out-File with correct args" {
            #Assert
            Assert-MockCalled Out-File -ParameterFilter { ($FilePath -eq $exitCodeLog) -and ($InputObject -eq 8) } -Exactly 1
        }

        It "Should use silent args from parameter if they are provided" {
            #Arrange
            $custumSilentArgs = "/Custom /OtherSwitch"
            #Act
            $result = Install-NunyaPackage -FilePath $filePath -SilentArgs $custumSilentArgs
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { $ArgumentList -match $custumSilentArgs } -Exactly 1
        }

        It "Should supply correct silent arguments for MSI installer if none are provided" {
           $result =  Install-NunyaPackage -FilePath $filePath

           # Should have ran twice with the silent args, once from the (It "Should execute msi switch block")
           #    and once from this It block
           Assert-MockCalled Start-Process -ParameterFilter { $ArgumentList -match $silentArgs } -Exactly 2
        }
    }

    Context "Test switch for install type .msu" {
        
        #***Arrange***
        # Install-NunyaPackage args
        $filePath = "c:\test.msu"
        $silentArgs = "/quiet /norestart"

        # Mocking args and vars
        $nunyaLogDirectory = Join-Path $env:temp "Nunya"
        $filenameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        $filename = [System.IO.Path]::GetFileName($filePath)
        $installerLogDirectory = Join-Path $nunyaLogDirectory $filenameWOExtention
        $exitCodeLog = Join-Path $installerLogDirectory "exitCode.log"
        $InstallLog = Join-Path $installerLogDirectory "install.etl"

        #$msiArgs = "/i `"$filePath`" /l*vx `"$InstallLog`" /quiet /norestart"
        $msuArgs = "`"$FilePath`" /log:`"$InstallLog`" $silentArgs"
        $wusaExecPath = "$env:SystemRoot\System32\wusa.exe"
        
        Mock Start-Process {[PSCustomObject]@{ExitCode = 2}} -ParameterFilter { ($FilePath -eq $wusaExecPath) -and ($ArgumentList -eq $msuArgs) }
        Mock Out-File {}
        # Mock the first Test-Path, the one that checks to see if the installer file exist
        Mock Test-Path { $true } -ParameterFilter { $Path -eq $filePath }

        It "Should execute msu switch block" {
            #Act
            # Always make this an array, sometimes it  might only return one item in the pipeline
            #   if an exit code is not returned.  This always wraps the item(s) in an array
            #   I am only interested in the first item the verbose message for this test
            $result = @(Install-NunyaPackage -FilePath $filePath -SilentArgs $silentArgs -Verbose 4>&1)[0]
            #Assert
            $result | Should Match "Installing .msu type: $filename"
        }

        It "Should run Start-Process with correct args for MSU install" {          
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { ($FilePath -eq $wusaExecPath) -and ($ArgumentList -eq $msuArgs) } -Exactly 1
        }

        It "Should write ExitCode to file, Out-File with correct args" {
            #Assert
            Assert-MockCalled Out-File -ParameterFilter { ($FilePath -eq $exitCodeLog) -and ($InputObject -eq 2) } -Exactly 1
        }

        It "Should use silent args from parameter if they are provided" {
            #Arrange
            $custumSilentArgs = "/Custom /OtherSwitch"
            #Act
            $result = Install-NunyaPackage -FilePath $filePath -SilentArgs $custumSilentArgs
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { $ArgumentList -match $custumSilentArgs } -Exactly 1
        }

        It "Should supply correct silent arguments for MSI installer if none are provided" {
           $result =  Install-NunyaPackage -FilePath $filePath

           # Should have ran twice with the silent args, once from the (It "Should execute msu switch block")
           #    and once from this It block
           Assert-MockCalled Start-Process -ParameterFilter { $ArgumentList -match $silentArgs } -Exactly 2
        }
    }
}
