param([string]$GodotPath = "C:\Development\Godot\Godot_v4.7.2-stable_mono_win64_console.exe")
$ErrorActionPreference = "Stop"
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$releaseFolder = [IO.Path]::GetFullPath((Join-Path $projectRoot 'exports\windows'))
if (-not $releaseFolder.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar)) { throw 'Release path must remain in the project.' }
$templatePath = Join-Path $PSScriptRoot 'runtime\windows_release_x86_64.exe'
if (-not (Test-Path -LiteralPath $templatePath)) {
    & python (Join-Path $PSScriptRoot 'fetch_windows_template.py')
    if ($LASTEXITCODE -ne 0) { throw 'Windows runtime download failed.' }
}
New-Item -ItemType Directory -Force -Path $releaseFolder | Out-Null
& $GodotPath --headless --path $projectRoot --export-release 'Windows Desktop' (Join-Path $releaseFolder 'Subterranea.exe')
if ($LASTEXITCODE -ne 0) { throw 'Godot export failed.' }
foreach ($document in @('README.md','QA_REPORT.md','PERFORMANCE.md','COMBAT_BALANCE.md','EXPLORATION.md','NAVIGATION.md','FLEET.md','FLIGHT.md','SOUND.md','CHANGELOG.md')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $document) -Destination (Join-Path $releaseFolder $document) -Force
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'THIRD_PARTY_NOTICES.md') -Destination (Join-Path $releaseFolder 'THIRD_PARTY_NOTICES.md') -Force
$licenseFolder = Join-Path $releaseFolder 'licenses'
New-Item -ItemType Directory -Force -Path $licenseFolder | Out-Null
Get-ChildItem -LiteralPath (Join-Path $projectRoot 'licenses') -File | Copy-Item -Destination $licenseFolder -Force
foreach ($missionIndex in 0..3) {
    $verificationLog = Join-Path $projectRoot "exports\verify_$missionIndex.log"
    $verificationArgs = @('--headless', '--quit-after', '120', '--log-file', $verificationLog, '--', '--verify-release', "--verify-mission=$missionIndex")
    if ($missionIndex -eq 3) { $verificationArgs += '--verify-training' }
    $verificationRun = Start-Process -FilePath (Join-Path $releaseFolder 'Subterranea.exe') -ArgumentList $verificationArgs -WindowStyle Hidden -Wait -PassThru
    $verificationText = Get-Content -LiteralPath $verificationLog -Raw
    Write-Output $verificationText
    if ($verificationRun.ExitCode -ne 0 -or $verificationText -notmatch 'RELEASE VERIFY.*OK=true') { throw "Packaged mission $missionIndex validation failed." }
}
foreach ($feature in @('map','saves','profiles','fleet','chase','damage','breakup','audio','acoustics')) {
    $verificationLog = Join-Path $projectRoot "exports\verify_$feature.log"
    $verificationArgs = @('--headless', '--log-file', $verificationLog, '--', '--verify-release', "--verify-$feature")
    $verificationRun = Start-Process -FilePath (Join-Path $releaseFolder 'Subterranea.exe') -ArgumentList $verificationArgs -WindowStyle Hidden -Wait -PassThru
    $verificationText = Get-Content -LiteralPath $verificationLog -Raw
    Write-Output $verificationText
    if ($verificationRun.ExitCode -ne 0 -or $verificationText -notmatch 'RELEASE VERIFY.*OK=true') { throw "Packaged $feature validation failed." }
}
$zipPath = Join-Path $projectRoot 'exports\Subterranea-Windows-x64.zip'
Compress-Archive -Path (Join-Path $releaseFolder '*') -DestinationPath $zipPath -Force
$digest = Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
$checksumPath = Join-Path $projectRoot 'exports\SHA256SUMS.txt'
Set-Content -LiteralPath $checksumPath -Value ($digest.Hash.ToLower() + "  Subterranea-Windows-x64.zip")
$digest | Format-List
Write-Output "Portable Windows build ready: $zipPath"
