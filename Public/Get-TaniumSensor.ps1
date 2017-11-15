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
        [ValidateSet("Xml","Hashtable","PSObject")]
        [ValidateNotNullOrEmpty()]
        [String]
        $As = "Hashtable",
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
            Server      = $Server
            Credential  = $Credential
            ErrorAction = "Stop"
            Command     = "GetObject"
            ObjectType  = "sensor"
        }
        if ($All -and $As -ne "Xml") {
            Write-Warning "Returning results as 'Xml' instead of '$As' for efficiency"
            $As = "Xml"
        }
        $itrParams["As"] = $As
        if ($PSBoundParameters.Keys -contains "Raw") {
            $itrParams["Raw"] = $Raw
        }
        $list = switch ($PSCmdlet.ParameterSetName) {
            All {
                $null
            }
            Default {
                (Get-Variable -Name ($PSCmdlet.ParameterSetName) -ValueOnly)
            }
        }
    }
    Process {
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