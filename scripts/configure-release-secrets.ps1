# Upload an existing signing key. This script never generates or replaces a key.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$KeystorePath,
    [string]$GoogleServicesPath = (Join-Path $PSScriptRoot '../google-services.json'),
    [string]$KeyAlias = 'meditrace',
    [string]$Repository = 'GrowNecro/meditracre'
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'Install GitHub CLI terlebih dahulu: winget install --id GitHub.cli. Lalu jalankan gh auth login.'
}
if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
    throw 'Repository harus memakai format pemilik/nama-repository.'
}

$signingFile = (Resolve-Path -LiteralPath $KeystorePath).Path
$firebaseFile = (Resolve-Path -LiteralPath $GoogleServicesPath).Path
if (-not (Test-Path -LiteralPath $signingFile -PathType Leaf)) {
    throw 'KeystorePath harus menunjuk ke file keystore release yang sudah ada.'
}
$firebaseJson = [IO.File]::ReadAllText($firebaseFile)
$firebaseConfig = $firebaseJson | ConvertFrom-Json
$androidClients = @($firebaseConfig.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq 'com.example.meditrace'
})
if ($androidClients.Count -eq 0) {
    throw 'google-services.json tidak memiliki client com.example.meditrace.'
}

& gh auth status
if ($LASTEXITCODE -ne 0) { throw 'Login dahulu dengan gh auth login, lalu ulangi skrip ini.' }

$storePassword = Read-Host 'Password keystore (input disembunyikan)' -AsSecureString
$keyPassword = Read-Host 'Password key (Enter jika sama dengan keystore)' -AsSecureString
if ($keyPassword.Length -eq 0) { $keyPassword = $storePassword }
if ($storePassword.Length -eq 0) { throw 'Password keystore tidak boleh kosong.' }
if ([string]::IsNullOrWhiteSpace($KeyAlias)) { throw 'KeyAlias tidak boleh kosong.' }

function Set-RepositorySecret([string]$Name, [string]$Value) {
    # Send sensitive values through stdin, never via command arguments or log output.
    # Write directly so PowerShell does not append a newline to signing passwords.
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = (Get-Command gh).Source
    $startInfo.Arguments = "secret set $Name --repo $Repository"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $process = [Diagnostics.Process]::Start($startInfo)
    try {
        $process.StandardInput.Write($Value)
        $process.StandardInput.Close()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "Gagal mengisi secret $Name. Periksa akses repository."
        }
    } finally {
        $process.Dispose()
    }
    Write-Host "Secret $Name tersimpan."
}

Set-RepositorySecret 'GOOGLE_SERVICES_JSON' $firebaseJson
Set-RepositorySecret 'ANDROID_KEYSTORE_BASE64' ([Convert]::ToBase64String([IO.File]::ReadAllBytes($signingFile)))
Set-RepositorySecret 'ANDROID_KEY_ALIAS' $KeyAlias
Set-RepositorySecret 'ANDROID_KEYSTORE_PASSWORD' ([Net.NetworkCredential]::new('', $storePassword).Password)
Set-RepositorySecret 'ANDROID_KEY_PASSWORD' ([Net.NetworkCredential]::new('', $keyPassword).Password)
Write-Host "Konfigurasi tersimpan di $Repository. Push tag v* baru yang berisi perubahan workflow."
