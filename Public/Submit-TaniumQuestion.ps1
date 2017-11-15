function Submit-TaniumQuestion {
    [CmdletBinding(DefaultParameterSetName = "InputObject")]
    Param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "InputObject")]
        [Hashtable[]]
        $InputObject,
        [parameter(Mandatory = $true, Position = 0, ParameterSetName = "Question")]
        [Hashtable[]]
        $Question,
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
            Command     = "AddObject"
            ObjectType  = "question"
        }
        if ($PSBoundParameters.Keys -contains "Raw") {
            $itrParams["Raw"] = $Raw
        }
    }
    Process {
        $question = (Get-Variable -Name ($PSCmdlet.ParameterSetName) -ValueOnly)
        if ($question.question) {
            $question = $question.question
        }
        $objectList = @(
            @{
                question = $question
            }
        )
        try {
            $result = Invoke-TaniumRequest -ObjectList $objectList @itrParams
            return $result
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}