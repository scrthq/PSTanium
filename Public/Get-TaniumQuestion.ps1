function Get-TaniumQuestion {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        $Id,
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
            As          = $As
            ErrorAction = "Stop"
            Command     = "GetObject"
            ObjectType  = "question"
        }
        if ($PSBoundParameters.Keys -contains "Raw") {
            $itrParams["Raw"] = $Raw
        }
    }
    Process {
        $objectList = @()
        foreach ($item in $Id) {
            if ($item.id) {
                $objectList += @{
                    question = @{
                        id = $item.id
                    }
                }
            }
            else {
                $objectList += @{
                    question = @{
                        id = $item
                    }
                }
            }
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