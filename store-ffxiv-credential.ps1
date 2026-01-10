# store-ffxiv-credential.ps1
# Credential Manager に FFXIV 用の資格情報を保存します。

try {
    if (-not (Get-Module -ListAvailable -Name CredentialManager)) {
        Write-Host "CredentialManager module not found. Installing..."
        Install-Module -Name CredentialManager -Scope CurrentUser -Force -AllowClobber
    }
} catch {
    Write-Error "Failed to install CredentialManager module: $_"
    exit 1
}

Import-Module CredentialManager -Force

$target = "FFXIV-AutoLogin"
$cred = Get-Credential -Message "Enter FFXIV username and password"
if (-not $cred) { Write-Error "No credential provided."; exit 1 }

try {
    # Remove existing credential if present
    $existing = Get-StoredCredential -Target $target -ErrorAction SilentlyContinue
    if ($existing) {
        Remove-StoredCredential -Target $target -ErrorAction SilentlyContinue
    }
    New-StoredCredential -Target $target -UserName $cred.UserName -Password ($cred.GetNetworkCredential().Password) -Persist LocalMachine | Out-Null
    Write-Host "Credential saved to Credential Manager (Target: $target)."
} catch {
    Write-Error "Failed to save credential: $_"
    exit 1
}
