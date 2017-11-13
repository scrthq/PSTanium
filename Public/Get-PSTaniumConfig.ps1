function Get-PSTaniumConfig {
    function Decrypt {
        Param($String)
        (New-Object System.Management.Automation.PSCredential ("PSTanium", (ConvertTo-SecureString -String $String -Key $script:ConfKey))).GetNetworkCredential().Password
    }
    Get-Content $script:ConfigPath | ConvertFrom-Json | Select-Object -Property @{N = 'Server';E = {Decrypt $_.Server}},@{N = 'Credential';E = {New-Object System.Management.Automation.PSCredential ((Decrypt $_.Username), (ConvertTo-SecureString (Decrypt $_.Password) -AsPlainText -Force))}}
}