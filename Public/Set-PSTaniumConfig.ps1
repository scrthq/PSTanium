function Set-PSTaniumConfig {
    [CmdletBinding()]
    Param (
        # The Tanium Server FQDN or IP
        [Parameter(Mandatory = $false,Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server,
        # Credentials for Tanium Server
        [Parameter(Mandatory = $false,Position = 1)]
        [ValidateNotNull()]
        [PSCredential]
        $Credential
    )
    Process {
        Function Encrypt {
            param([String]$String)
            if ($String -notlike '') {
                ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String $String -AsPlainText -Force) -Key $script:ConfKey
            }
        }
        Switch ($PSBoundParameters.Keys) {
            'Server' {
                $Script:PSTanium.Server = $Server
            }
            'Credential' {
                $Script:PSTanium.Credential = $Credential
            }
        }
        $Script:PSTanium | Select-Object -Property @{N = 'Server';E = {Encrypt $_.Server}},@{N = 'Username';E = {Encrypt $_.Credential.Username}},@{N = 'Password';E = {Encrypt $_.Credential.GetNetworkCredential().Password}} | ConvertTo-Json | Set-Content $script:ConfigPath -Force
    }
}