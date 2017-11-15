function Convert-XmlToHash {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        $Node,
        [parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("Hashtable","PSObject")]
        [String]
        $As = "Hashtable"

    )
    Process {
        $hash = @{}
        foreach ($attribute in $Node.attributes) {
            $hash.$($attribute.name) = $attribute.Value
        }
        $childNodesList = ($Node.childNodes | Where-Object {$_ -ne $null}).LocalName
        foreach ($childNode in ($Node.childNodes | Where-Object {$_ -ne $null})) {
            if (($childNodesList | Where-Object {$_ -eq $childNode.LocalName}).count -gt 1) {
                if (!($hash.$($childNode.LocalName))) {
                    $hash.$($childNode.LocalName) += @()
                }
                if ($childNode.'#text' -ne $null) {
                    $hash.$($childNode.LocalName) += $childNode.'#text'
                }
                elseif ($childNode.'#cdata-section' -ne $null) {
                    $hash.$($childNode.LocalName) += $childNode.'#cdata-section'
                }
                $hash.$($childNode.LocalName) += Convert-XmlToHash $childNode -As $As
            }
            else {
                if ($childNode.'#text' -ne $null) {
                    $hash.$($childNode.LocalName) = $childNode.'#text'
                }
                elseif ($childNode.'#cdata-section' -ne $null) {
                    $hash.$($childNode.LocalName) = $childNode.'#cdata-section'
                }
                else {
                    $hash.$($childNode.LocalName) = Convert-XmlToHash $childNode -As $As
                }
            }
        }
        switch ($As) {
            Hashtable {
                return $hash
            }
            PSObject {
                return [PSCustomObject]$hash
            }
        }
    }
}