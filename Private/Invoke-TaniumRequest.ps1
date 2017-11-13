function Invoke-TaniumRequest {
    [CmdletBinding()]
    Param (
        # Hashtable of Objects
        [Parameter(Mandatory = $true, Position = 1)]
        [Hashtable[]]
        $ObjectList,
        # Hashtable of Options
        [Parameter(Mandatory = $false, Position = 2)]
        [Hashtable[]]
        $Options,
        # Uri of SOAP endpoint
        [Parameter(Mandatory = $false)]
        [Uri]
        $Uri = ([Uri]"https://$($script:PSTanium.Server)/soap"),
        # Command to run
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("GetResultInfo","GetResultData","GetMergedResultData","AddObject","GetObject","DeleteObject")]
        [String]
        $Command = "GetObject",
        # The Tanium Server FQDN or IP
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server = $script:PSTanium.Server,
        # Credentials for Tanium Server
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [PSCredential]
        $Credential = $script:PSTanium.Credential
    )
    Begin {
        try {
            $session = (Get-TaniumSession -Server $Server -Credential $Credential -ErrorAction Stop)
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        $iwrParams = @{
            Uri         = $uri
            Method      = "Get"
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
        $headers = @{
            Accept  = "*/*"
            session = $session
        }
        $Xml = [Xml]@"
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <SOAP-ENV:Body>
        <typens:tanium_soap_request xmlns:typens="urn:TaniumSOAP">
            <command>$Command</command>
        </typens:tanium_soap_request>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
"@
        if ($ObjectList) {
            $Xml = Convert-HashToTanium -BaseXml $Xml -Hashtable $ObjectList
        }
        if ($Options) {
            $Xml = Convert-HashToTanium -BaseXml $Xml -Hashtable $Options -ElementName "options"
        }
    }
    Process {
        try {
            $result = Invoke-WebRequest -Body "$($Xml.InnerXml)" -Headers $headers @iwrParams
            return $result.Content
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}