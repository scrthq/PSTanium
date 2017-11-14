function Get-TaniumSensor {
    [CmdletBinding(DefaultParameterSetName = "Name")]
    Param (
        [parameter(Mandatory = $true,Position = 0,ParameterSetName = "Name")]
        [String[]]
        $Name,
        [parameter(Mandatory = $true,Position = 0,ParameterSetName = "Id")]
        [String[]]
        $Id,
        [parameter(Mandatory = $true,Position = 0,ParameterSetName = "Hash")]
        [String[]]
        $Hash,
        [parameter(Mandatory = $true,Position = 0,ParameterSetName = "All")]
        [Switch]
        $All,
        [Parameter(Mandatory = $false)]
        [Switch]
        $Raw,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server = $script:PSTanium.Server,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [PSCredential]
        $Credential = $script:PSTanium.Credential
    )
    Begin {
        $itrParams = @{
            Server = $Server
            Credential = $Credential
            ErrorAction = "Stop"
            ObjectType = "sensor"
        }
        if ($PSBoundParameters.Keys -contains "Raw") {
            $itrParams["Raw"] = $Raw
        }
    }
    Process {
        $list = switch ($PSCmdlet.ParameterSetName) {
            Name {
                $Name
            }
            Id {
                $Id
            }
            Hash {
                $Hash
            }
            All {
                $null
            }
        }
        $objectList = @()
        if ($list) {
            foreach ($item in $list) {
                $objectList += @{
                    sensor = @{
                        "$(($PSCmdlet.ParameterSetName).ToLower())" = $item
                    }
                }
            }
        }
        else {
            $objectList += @{
                sensor = @{
                    name = $null
                }
            }
            $itrParams["ObjectType"] = "sensors"
            $itrParams["ObjectSubType"] = "sensor"
        }
        try {
            $result = Invoke-TaniumRequest -ObjectList $objectList @itrParams
            return $result
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}