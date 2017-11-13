function Convert-HashToTanium {
    # Adapted from comment by DmitriyKiselev here: https://gallery.technet.microsoft.com/scriptcenter/Export-Hashtable-to-xml-in-122fda31/view/Discussions#content
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Xml]
        $BaseXml,
        [Parameter(ValueFromPipeline = $true, Position = 1)]
        [System.Collections.Hashtable[]]
        $Hashtable,
        [Parameter(ValueFromPipeline = $false, Position = 2)]
        [String]
        $ElementName = "object_list"
    )
    Begin {
        $elementToAdd = $BaseXml.CreateElement($ElementName)
        $ScriptBlock = {
            Param($Elem, $Root)
            if ($Elem.Value -is [Array]) {
                $Elem.Value | ForEach-Object {
                    $p = [System.Collections.DictionaryEntry]@{"Key" = $Elem.Key;"Value" = $_}
                    $ScriptBlock.Invoke($p, $Root)
                }
            }
            elseif ($Elem.Value -is [System.Collections.Hashtable]) {
                $RootNode = $Root.AppendChild($BaseXml.CreateNode([System.Xml.XmlNodeType]::Element,$Elem.Key,$Null))
                $Elem.Value.GetEnumerator() | ForEach-Object {
                    $Scriptblock.Invoke( @($_, $RootNode) )
                }
            }
            else {
                $Element = $BaseXml.CreateElement($Elem.Key)
                $p = if ($Elem.Value -is [Array]) {
                    $Elem.Value -join ','
                }
                else {
                    $Elem.Value | Out-String
                }
                if ($p -match '\S') {
                    $Element.InnerText = $p.Trim()
                }
                $Root.AppendChild($Element) | Out-Null
            }
        }
    }
    Process {
        foreach ($_hash in $Hashtable) {
            $_hash.GetEnumerator() | ForEach-Object {
                $scriptblock.Invoke( @($_, $elementToAdd) )
            }
        }
        $BaseXml.Envelope.Body.tanium_soap_request.AppendChild($elementToAdd) | Out-Null
        $BaseXml
    }
}