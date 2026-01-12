# get-ffxiv-credential.ps1
# Credential Manager から FFXIV の資格情報を取得し、一時ファイルに書き出します。

try {
    if (-not (Get-Module -ListAvailable -Name CredentialManager)) {
        Install-Module -Name CredentialManager -Scope CurrentUser -Force -AllowClobber
    }
} catch {
    Write-Error "Failed to install CredentialManager module: $_"
    exit 1
}

Import-Module CredentialManager -Force

$target = "FFXIV-AutoLogin"
$c = Get-StoredCredential -Target $target
if (-not $c) {
    Write-Error "Credential not found for target '$target'. Run store-ffxiv-credential.ps1 first."
    exit 2
}

$out = Join-Path $PSScriptRoot 'ffxiv_creds.tmp'
"$($c.UserName)`n$($c.GetNetworkCredential().Password)" | Out-File -Encoding UTF8 -Force -FilePath $out
