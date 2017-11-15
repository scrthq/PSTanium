function Resolve-TaniumQuestion {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $true,Position = 0)]
        [String[]]
        $Question,
        [parameter(Mandatory = $false)]
        [Switch]
        $Top,
        [parameter(Mandatory = $false)]
        [Int]
        $ParserVersion = 2,
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
            Server        = $Server
            Credential    = $Credential
            As            = $As
            ErrorAction   = "Stop"
            Command       = "AddObject"
            ObjectType    = "parse_result_groups"
            ObjectSubType = "parse_result_group"
        }
        if ($PSBoundParameters.Keys -contains "Raw") {
            $itrParams["Raw"] = $Raw
        }
    }
    Process {
        $objectList = @()
        foreach ($item in $Question) {
            $job = @{
                question_text = $item
            }
            if ($ParserVersion) {
                $job["parser_version"] = $ParserVersion
            }
            $objectList += @{
                parse_job = $job
            }
        }
        try {
            $result = Invoke-TaniumRequest -ObjectList $objectList @itrParams
            if ($Top) {
                return $result.question[0]
            }
            else {
                return $result
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}