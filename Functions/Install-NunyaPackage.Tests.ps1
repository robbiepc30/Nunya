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

    Context "Test switch for different install types .msi, .msu, and .exe" {
        Mock Test-Path { $true }
        It "Should execute msi switch block" {
            #Arrange
            #Act
            $result = Install-NunyaPackage -FilePath "c:\test.msi" -SilentArgs "/quiet /norestart" -Verbose 4>&1
            #Assert
            #Write-Verbose "Somthing is installing" -Verbose 4>&1 | Should Match "installing"
            $result | Should Match "installing"
        }

    }
    


    
}
