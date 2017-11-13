function Get-ConfKey {
    if ($IsCoreCLR -and !$IsWindows) {
        $hostName = Invoke-Expression "hostname"
        $string = "$("$hostName\$env:USER" * 32)".Substring(0,32)
    }
    else {
        $string = "$("$env:COMPUTERNAME\$env:USERNAME" * 32)".Substring(0,32)
    }
    $length = $string.length
    $pad = 32 - $length
    $encoding = New-Object System.Text.ASCIIEncoding
    $bytes = $encoding.GetBytes($string + "0" * $pad)
    return $bytes
}