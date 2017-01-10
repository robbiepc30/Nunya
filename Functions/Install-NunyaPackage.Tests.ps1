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

        $filePathArg = "c:\test.msi"
        $filename = [System.IO.Path]::GetFileName($filePathArg)
        $argumentListArg = "/i `"$filePathArg`" /l*vx `"C:\Users\robert.p.courtney\AppData\Local\Temp\Nunya\$filename\install.log`" /quiet /norestart"
        Mock Test-Path { $true }
        Mock Start-Process {} -ParameterFilter { ($filePath -eq $filePathArg) -and ($ArgumentList -eq $argumentListArgs) }

        Mock T {} -ParameterFilter { ($SomeParam -eq "t") -and ($OtherParam -eq "o")}
        It "Should execute msi switch block" {
            #Arrange
            #Act
            $result = Install-NunyaPackage -FilePath $filePathArg -SilentArgs $argumentListArgs -Verbose 4>&1
            #Assert
            #Write-Verbose "Somthing is installing" -Verbose 4>&1 | Should Match "installing"
            $result | Should Match "installing $filename"
        }

        It "Testing multi parameters with Assert-MockCalled" {
            #Arrange
            #Act
            $r = T -SomeParam "t" "o"
            #Assert-MockCalled Start-Process -ParameterFilter {($filePath -eq $filePathArg) -and ($ArgumentList -eq $argumentListArgs)} -Exactly 1
            Assert-MockCalled T -ParameterFilter { ($SomeParam -eq "t") -and ($OtherParam -eq "o")} -Exactly 1

        }

    }

}
