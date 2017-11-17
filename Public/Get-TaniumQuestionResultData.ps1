function Get-TaniumQuestionResultData {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        $Id,
        [parameter(Mandatory = $false)]
        [String]
        $Delimiter = "`n",
        [Parameter(Mandatory = $false)]
        [ValidateSet("Xml","Hashtable","PSObject")]
        [ValidateNotNullOrEmpty()]
        [String]
        $As = "PSObject",
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
            Command     = "GetResultData"
            <# ObjectType  = "ResultXML" #>
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
            if ($Raw) {
                return $result
            }
            else {
                switch ($As) {
                    Xml {
                        return $result
                    }
                    Default {
                        $final = @()
                        $headers = $result.cs.c.dn
                        foreach ($row in ($result.rs.r)) {
                            $rowHash = @{}
                            for ($i = 0; $i -lt $headers.Count; $i++) {
                                $rowHash[$headers[$i]] = ($row.c[$i].v | Where-Object {![String]::IsNullOrWhiteSpace($_.ToString())}) -join "$Delimiter"
                            }
                            switch ($As) {
                                Hashtable {
                                    $final += $rowHash
                                }
                                PSObject {
                                    $final += [PSCustomObject]$rowHash
                                }
                            }
                        }
                        return $final
                    }
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}