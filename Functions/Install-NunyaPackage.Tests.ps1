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
    function T ($SomeParam, $OtherParam) {
        Write-Host $SomeParam
    }

    Context "Test switch for install type .msi" {
        #Arrange

        # Install-NunyaPackage args
        $fiePath = "c:\test.msi"
        $argumentList = "/quiet /norestart"

        # Mocking args and vars
        $filnameWOExtention = [System.IO.Path]::GetFileNameWithoutExtension($fiePath)
        $filename = [System.IO.Path]::GetFileName($fiePath)
        $startProcArgList = "/i `"$fiePath`" /l*vx `"C:\Users\robert.p.courtney\AppData\Local\Temp\Nunya\$filnameWOExtention\install.log`" /quiet /norestart"
        $msiExecPath = "$env:SystemRoot\System32\msiexec.exe"
        
        Mock Start-Process {} -ParameterFilter { ($FilePath -eq $msiExecPath) -and ($ArgumentList -eq $startProcArgList) }
        Mock Test-Path { $true }


        It "Should execute msi switch block" {
            
            #Act
            $result = Install-NunyaPackage -FilePath $fiePath -SilentArgs $startProcArgLists -Verbose 4>&1
            #Assert
            $result | Should Match "installing $filename"
        }

        It "Should run Start-Process with correct args for MSI install" {          
            #Act
            $result = Install-NunyaPackage -FilePath $fiePath -SilentArgs $argumentList
            #Assert
            Assert-MockCalled Start-Process -ParameterFilter { ($FilePath -eq $msiExecPath) -and ($ArgumentList -eq $startProcArgList) } -Exactly 1
        }
    }
}
