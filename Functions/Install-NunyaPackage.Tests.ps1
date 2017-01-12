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
        $_filePath = "c:\test.msi"
        $_silentArgs = "/quiet /norestart"

        # Mocking args and vars
        $_nunyaLogDirectory = Join-Path $env:temp "Nunya"
        $_filenameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($_filePath)
        $_filename = [System.IO.Path]::GetFileName($_filePath)
        $_installerLogDirectory = Join-Path $_nunyaLogDirectory $_filenameWOExtention
        $_exitCodeLog = Join-Path $_installerLogDirectory "exitCode.log"
        $_InstallLog = Join-Path $_installerLogDirectory "install.log"
        
        $_msiArgsForStartProcess = "/i `"$_filePath`" /l*vx `"$_InstallLog`" $_silentArgs"
        $_msiExecPath = "$env:SystemRoot\System32\msiexec.exe"
        
        Mock Start-Process {[PSCustomObject]@{ExitCode = 8}}
        Mock Out-File {}
        
        # Mock the first Test-Path, the one that checks to see if the installer file exist
        Mock Test-Path { $true } -ParameterFilter { $Path -eq $_filePath }

        It "Should execute msi switch block" {
            #Act
            # Always make this an array, sometimes it  might only return one item in the pipeline
            #   if an exit code is not returned.  This always wraps the item(s) in an array
            #   I am only interested in the first item the verbose message for this test
            #$result = @(Install-NunyaPackage -FilePath $_filePath -SilentArgs $_silentArgs -Verbose 4>&1)[0]
            $result = @(Install-NunyaPackage -FilePath $_filePath -SilentArgs $_silentArgs -Verbose 4>&1)[0]
            #Assert
            $result | Should Match "Installing .msi type: $_filename"
        }

        It "Should run Start-Process with correct args for MSI install" {          
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { ($FilePath -eq $_msiExecPath) -and ($ArgumentList -eq $_msiArgsForStartProcess) } -Exactly 1
        }

        It "Should write ExitCode to file, Out-File with correct args" {
            #Assert
            Assert-MockCalled Out-File -ParameterFilter { ($FilePath -eq $_exitCodeLog) -and ($InputObject -eq 8) } -Exactly 1
        }

        It "Should use silent args from parameter if they are provided" {
            #Arrange
            $_custumSilentArgs = "/Custom /OtherSwitch"
            #Act
            $result = Install-NunyaPackage -FilePath $_filePath -SilentArgs $_custumSilentArgs
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { $ArgumentList -match $_custumSilentArgs } -Exactly 1
        }

        It "Should supply correct silent arguments for MSI installer if none are provided" {
           $result =  Install-NunyaPackage -FilePath $_filePath

           # Should have ran twice with the silent args, once from the (It "Should execute msi switch block")
           #    and once from this It block
           Assert-MockCalled Start-Process -ParameterFilter { $ArgumentList -match $_silentArgs } -Exactly 2
        }

    }

    Context "Test switch for install type .msu" {
        
        #***Arrange***
        # Install-NunyaPackage args
        $_filePath = "c:\test.msu"
        $_silentArgs = "/quiet /norestart"

        # Mocking args and vars
        $_nunyaLogDirectory = Join-Path $env:temp "Nunya"
        $_filenameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($_filePath)
        $_filename = [System.IO.Path]::GetFileName($_filePath)
        $_installerLogDirectory = Join-Path $_nunyaLogDirectory $_filenameWOExtention
        $_exitCodeLog = Join-Path $_installerLogDirectory "exitCode.log"
        $_InstallLog = Join-Path $_installerLogDirectory "install.etl"

        $_msuArgs = "`"$_FilePath`" /log:`"$_InstallLog`" $_silentArgs"
        $_wusaExecPath = "$env:SystemRoot\System32\wusa.exe"
        
        Mock Start-Process {[PSCustomObject]@{ExitCode = 2}}
        Mock Out-File {}
        # Mock the first Test-Path, the one that checks to see if the installer file exist
        Mock Test-Path { $true } -ParameterFilter { $Path -eq $_filePath }

        It "Should execute msu switch block" {
            #Act
            # Always make this an array, sometimes it  might only return one item in the pipeline
            #   if an exit code is not returned.  This always wraps the item(s) in an array
            #   I am only interested in the first item the verbose message for this test
            $result = @(Install-NunyaPackage -FilePath $_filePath -SilentArgs $_silentArgs -Verbose 4>&1)[0]
            #Assert
            $result | Should Match "Installing .msu type: $_filename"
        }

        It "Should run Start-Process with correct args for MSU install" {          
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { ($FilePath -eq $_wusaExecPath) -and ($ArgumentList -eq $_msuArgs) } -Exactly 1
        }

        It "Should write ExitCode to file, Out-File with correct args" {
            #Assert
            Assert-MockCalled Out-File -ParameterFilter { ($FilePath -eq $_exitCodeLog) -and ($InputObject -eq 2) } -Exactly 1
        }

        It "Should use silent args from parameter if they are provided" {
            #Arrange
            $_custumSilentArgs = "/Custom /OtherSwitch"
            #Act
            $result = Install-NunyaPackage -FilePath $_filePath -SilentArgs $_custumSilentArgs
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { $ArgumentList -match $_custumSilentArgs } -Exactly 1
        }

        It "Should supply correct silent arguments for MSI installer if none are provided" {
           $result =  Install-NunyaPackage -FilePath $_filePath

           # Should have ran twice with the silent args, once from the (It "Should execute msu switch block")
           #    and once from this It block
           Assert-MockCalled Start-Process -ParameterFilter { $ArgumentList -match $_silentArgs } -Exactly 2
        }
    }

    Context "Test switch for install type .exe" {
        
        #***Arrange***
        # Install-NunyaPackage args
        $_filePath = "c:\test.exe"
        $_silentArgs = "/sAll /rs"

        # Mocking args and vars
        $_nunyaLogDirectory = Join-Path $env:temp "Nunya"
        $_filenameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($_filePath)
        $_filename = [System.IO.Path]::GetFileName($_filePath)
        $_installerLogDirectory = Join-Path $_nunyaLogDirectory $_filenameWOExtention
        $_exitCodeLog = Join-Path $_installerLogDirectory "exitCode.log"
        
        Mock Start-Process {[PSCustomObject]@{ExitCode = 10}}
        Mock Out-File {}
        # Mock the first Test-Path, the one that checks to see if the installer file exist
        Mock Test-Path { $true } -ParameterFilter { $Path -eq $_filePath }

        It "Should execute exe switch block" {
            #Act
            # Always make this an array, sometimes it  might only return one item in the pipeline
            #   if an exit code is not returned.  This always wraps the item(s) in an array
            #   I am only interested in the first item the verbose message for this test
            $result = @(Install-NunyaPackage -FilePath $_filePath -SilentArgs $_silentArgs -Verbose 4>&1)[0]
            #Assert
            $result | Should Match "Installing .exe type: $_filename"
        }

        It "Should run Start-Process with correct args for EXE install" {          
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { ($FilePath -eq $_FilePath) -and ($ArgumentList -eq $_silentArgs) } -Exactly 1
        }

        It "Should write ExitCode to file, Out-File with correct args" {
            #Assert
            Assert-MockCalled Out-File -ParameterFilter { ($FilePath -eq $_exitCodeLog) -and ($InputObject -eq 10) } -Exactly 1
        }

        It "Should use silent args from parameter if they are provided" {
            #Arrange
            $_custumSilentArgs = "/Custom /OtherSwitch"
            #Act
            $result = Install-NunyaPackage -FilePath $_filePath -SilentArgs $_custumSilentArgs
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { ($FilePath -eq $_FilePath) -and ($ArgumentList -match $_custumSilentArgs) } -Exactly 1
        }

        It "Should throw error if silent args are not provided for EXE installer" {
           #Act, Assert
           { Install-NunyaPackage -FilePath $_filePath } | should throw '-SilentArgs Parameter must be provided an argument.  Example: -SilentArgs "/S"'
        }
    }
    





}
