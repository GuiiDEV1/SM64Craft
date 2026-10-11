param([Parameter(Mandatory=$true)][string]$Rom, [string]$Jar)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$bundle = Join-Path $root 'dist/native-fast/bundle'
$resources = Join-Path $root 'SkyCraft/fabric/src/client/resources/assets/skycraft/installer'
$test = Join-Path $root ('dist/native-fast/test-' + [guid]::NewGuid().ToString('N'))
$install = Join-Path $test 'sm64craft'
$setup = Join-Path $install '.setup'
$work = Join-Path $setup 'work'
New-Item -ItemType Directory -Path $work, (Join-Path $install 'saves'), (Join-Path $test 'mods') -Force | Out-Null
Copy-Item -LiteralPath $Rom -Destination (Join-Path $install 'baserom.us.z64')
foreach ($name in @('install-native.ps1', 'apply-native-patch.ps1')) {
    Copy-Item -LiteralPath (Join-Path $resources $name) -Destination $setup
}
foreach ($name in @('native-manifest.json', 'native-delta.gz')) {
    Copy-Item -LiteralPath (Join-Path $bundle $name) -Destination $setup
}
Copy-Item -LiteralPath (Join-Path $root 'patches/sm64coopdx.patch') -Destination $setup
if ($Jar) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $package = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($Jar))
    try {
        foreach ($name in @('install-native.ps1', 'apply-native-patch.ps1', 'native-manifest.json', 'native-delta.gz', 'sm64coopdx.patch')) {
            [IO.Compression.ZipFileExtensions]::ExtractToFile($package.GetEntry('assets/skycraft/installer/' + $name), (Join-Path $setup $name), $true)
        }
    } finally { $package.Dispose() }
}
Copy-Item -LiteralPath (Join-Path $root 'dist/native-fast/upstream.zip') -Destination (Join-Path $work 'upstream.zip')
$e4mc = Join-Path $env:APPDATA 'PrismLauncher/instances/MarioCraft-View/.minecraft/mods/e4mc-fabric-6.2.2-modern.jar'
if (Test-Path -LiteralPath $e4mc) { Copy-Item -LiteralPath $e4mc -Destination (Join-Path $test 'mods') }
$sentinel = Join-Path $install 'saves/preserve-test.txt'
[IO.File]::WriteAllText($sentinel, 'save must survive installation')
$timer = [Diagnostics.Stopwatch]::StartNew()
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $setup 'install-native.ps1') -InstallRoot $install
if ($LASTEXITCODE -ne 0) { throw "Installer failed; inspect $install" }
$timer.Stop()
$manifest = Get-Content (Join-Path $setup 'native-manifest.json') -Raw | ConvertFrom-Json
$exe = Join-Path $install 'game/sm64coopdx.exe'
if ((Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant() -ne $manifest.targetExeSha256) { throw 'Wrong executable after installation' }
if ((Get-Content $sentinel -Raw) -ne 'save must survive installation') { throw 'Save changed' }
if (Test-Path -LiteralPath $work) { throw 'Temporary downloads were not removed' }
$metadata = Get-Content (Join-Path $install 'installed.json') -Raw | ConvertFrom-Json
if ($metadata.installMethod -ne 'official-release-binary-delta') { throw 'Slow path was used' }
if ((Get-FileHash (Join-Path $install 'game/baserom.us.z64') -Algorithm SHA1).Hash.ToLowerInvariant() -ne $metadata.romSha1) { throw 'ROM changed' }

. (Join-Path $resources 'apply-native-patch.ps1')
# Hash rejection must leave an existing output untouched.
$badSource = Join-Path $test 'bad-source.exe'
[IO.File]::WriteAllBytes($badSource, [byte[]](1,2,3))
$output = Join-Path $test 'unchanged-output'
[IO.File]::WriteAllText($output, 'unchanged')
$rejected = $false
try { Apply-NativeDelta $badSource (Join-Path $bundle 'native-delta.gz') $output } catch { $rejected = $true }
if (!$rejected -or [IO.File]::ReadAllText($output) -ne 'unchanged') { throw 'Wrong-source guard failed' }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $root 'dist/native-fast/upstream.zip'))
$original = Join-Path $test 'original.exe'
try { [IO.Compression.ZipFileExtensions]::ExtractToFile($zip.GetEntry('sm64coopdx.exe'), $original) } finally { $zip.Dispose() }
$wrongBytes = [IO.File]::ReadAllBytes($original)
$wrongBytes[100] = $wrongBytes[100] -bxor 1
[IO.File]::WriteAllBytes($badSource, $wrongBytes)
$rejected = $false
try { Apply-NativeDelta $badSource (Join-Path $bundle 'native-delta.gz') $output } catch { $rejected = $true }
if (!$rejected -or [IO.File]::ReadAllText($output) -ne 'unchanged') { throw 'Source hash guard failed' }
$truncated = Join-Path $test 'truncated.gz'
$bytes = [IO.File]::ReadAllBytes((Join-Path $bundle 'native-delta.gz'))
[IO.File]::WriteAllBytes($truncated, $bytes[0..([int]($bytes.Length/2))])
$rejected = $false
try { Apply-NativeDelta $original $truncated $output } catch { $rejected = $true }
if (!$rejected -or [IO.File]::ReadAllText($output) -ne 'unchanged') { throw 'Truncated-patch guard failed' }
$size = (Get-ChildItem -LiteralPath $install -File -Recurse | Measure-Object Length -Sum).Sum
[pscustomobject]@{ SecondsWithoutDownload=[Math]::Round($timer.Elapsed.TotalSeconds,2); InstalledMiB=[Math]::Round($size/1MB,2); SavePreserved=$true; CorruptionRejected=$true; TestFolder=$test } | ConvertTo-Json
