function Invoke-TaniumRequest {
    [CmdletBinding()]
    Param (
        # Hashtable of Objects
        [Parameter(Mandatory = $true, Position = 0)]
        [Hashtable[]]
        $ObjectList,
        # Hashtable of Options
        [Parameter(Mandatory = $false, Position = 1)]
        [Hashtable[]]
        $Options = @(@{suppress_object_list = 1}),
        # Uri of SOAP endpoint
        [Parameter(Mandatory = $false)]
        [Uri]
        $Uri = ([Uri]"https://$($script:PSTanium.Server)/soap"),
        [Parameter(Mandatory = $false)]
        [ValidateSet("GetResultInfo","GetResultData","GetMergedResultData","AddObject","GetObject","DeleteObject")]
        [String]
        $Command = "GetObject",
        [Parameter(Mandatory = $false)]
        [ValidateSet("Xml","Hashtable","PSObject")]
        [ValidateNotNullOrEmpty()]
        [String]
        $As = "Hashtable",
        [Parameter(Mandatory = $false)]
        [String]
        $ObjectType,
        [Parameter(Mandatory = $false)]
        [String]
        $ObjectSubType,
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
        try {
            $headers = @{
                Accept  = "*/*"
                session = (Get-TaniumSession -Server $Server -Credential $Credential -ErrorAction Stop)
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        $iwrParams = @{
            Uri         = $Uri
            Method      = "Post"
            Credential  = $Credential
            ErrorAction = "Stop"
            ContentType = "text/xml"
        }
        if (!$IsCoreCLR) {
            Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
        else {
            $iwrParams["SkipCertificateCheck"] = $true
        }
        $xml = [Xml]@"
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <SOAP-ENV:Body>
        <typens:tanium_soap_request xmlns:typens="urn:TaniumSOAP">
            <command>$Command</command>
        </typens:tanium_soap_request>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
"@
        if ($ObjectList) {
            $xml = Convert-HashToTanium -BaseXml $xml -Hashtable $ObjectList
        }
        if ($Options) {
            $xml = Convert-HashToTanium -BaseXml $xml -Hashtable $Options -ElementName "options"
        }
        Write-Verbose "InnerXML for query:`n`n$($xml.InnerXML)"
    }
    Process {
        try {
            $result = Invoke-WebRequest -Body "$($xml.InnerXml)" -Headers $headers @iwrParams
            $final = [Xml]($result.Content)
            if ($final.Envelope.Body.return.command -clike "ERROR: *") {
                throw "$($final.Envelope.Body.return.command)"
            }
            else {
                if (!$Raw) {
                    Write-Verbose "Formatting results"
                    if ($Command -eq "GetResultInfo") {
                        $final = [Xml]($final.Envelope.Body.return.ResultXML.'#cdata-section')
                        $ObjectType = "result_infos"
                        $ObjectSubType = "result_info"
                    }
                    elseif ($Command -eq "GetResultData") {
                        $final = [Xml]($final.Envelope.Body.return.ResultXML.'#cdata-section')
                        $ObjectType = "result_sets"
                        $ObjectSubType = "result_set"
                    }
                    else {
                        $final = $final.Envelope.Body.return.result_object
                    }
                    if ($ObjectType) {
                        if ($ObjectSubType) {
                            $final = $final.$ObjectType.$ObjectSubType
                        }
                        else {
                            $final = $final.$ObjectType
                        }
                    }
                }
                switch ($As) {
                    Xml {
                        return $final
                    }
                    Default {
                        return (Convert-XmlToHash -Node $final -As $As)
                    }
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}