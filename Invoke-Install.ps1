<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Invoke-Install
{
    [CmdletBinding()]
    Param
    (
        [String]$Path = '.'
    )
    # explicitly make this var an array by incolsing it in a @()
    # this protects the foreach loop from throwing an error if only one install script exist, because the var obj would not be an array type if only one *install.ps1 file exist
    $installerScripts = @(Get-ChildItem -Path $Path -Recurse -Include *.Install.ps1)

    $otherErrorCodes = @{ -2145124329 = "This update is not applicable to your computer"
                          2359302 = "This update is already installed on this computer"
                        }

    foreach ($i in $installerScripts) {
        
        $installerName = (Split-Path -Path $i.FullName -Leaf) -replace ".Install.ps1", ""
        Write-Progress -Activity "Installing updates" -Status ("{0:P1}" -f $($installerScripts.IndexOf($i)/$installerScripts.Length)) -CurrentOperation "Installing $installerName"  -PercentComplete (($installerScripts.IndexOf($i)/$installerScripts.Length) * 100)
        Write-Verbose "Installing $installerName"
        & $i.FullName
        if ($otherErrorCodes.ContainsKey($LASTEXITCODE)) {
            Write-Verbose " `t`t: $($otherErrorCodes.$LASTEXITCODE) , Exit code: $LASTEXITCODE" 
        } 
        else {
            Write-Verbose " `t`t : $([ComponentModel.Win32Exception]$LASTEXITCODE) , Exit code: $LASTEXITCODE"
        }
    }
}

