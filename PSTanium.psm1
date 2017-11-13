Param
(
    [parameter(Position = 0)]
    $ForceDotSource = $false
)
#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue )
$ModulePath = $PSScriptRoot
$ConfigFolder = "$env:HOME\.pstanium"
$ConfigPath = "$ConfigFolder\pstanium.config"

if (!(Test-Path $ConfigFolder)) {
    New-Item $ConfigFolder -ItemType Directory -Force | Out-Null
}

#Execute a scriptblock to load each function instead of dot sourcing (Issue #5)
foreach ($file in @($Public + $Private)) {
    if ($ForceDotSource) {
        . $file.FullName
    }
    else {
        $ExecutionContext.InvokeCommand.InvokeScript(
            $false,
            (
                [scriptblock]::Create(
                    [io.file]::ReadAllText(
                        $file.FullName,
                        [Text.Encoding]::UTF8
                    )
                )
            ),
            $null,
            $null
        )
    }
}

$ConfKey = (Get-ConfKey)

if (!(Test-Path -Path $ConfigPath -ErrorAction SilentlyContinue)) {
    Try {
        Write-Warning "Did not find config file '$ConfigPath', attempting to create"
        @{
            Server   = $null
            Username = $null
            Password = $null
        } | ConvertTo-Json | Set-Content $ConfigPath -Force
    }
    Catch {
        Write-Warning "Failed to create config file '$ConfigPath': $_"
    }
}
Try {
    $PSTanium = Get-PSTaniumConfig -ErrorAction Stop

}
Catch {
    Write-Warning "Error importing PSTanium config: $_"
}

Export-ModuleMember -Function $Public.Basename -Verbose:$false