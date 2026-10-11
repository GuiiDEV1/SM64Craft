param([string]$Version)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$properties = Get-Content (Join-Path $root 'SkyCraft/fabric/gradle.properties') -Raw
if ([string]::IsNullOrWhiteSpace($Version)) {
	$match = [regex]::Match($properties, '(?m)^version=(.+)$')
	if (-not $match.Success) { throw 'Could not read the mod version from gradle.properties.' }
	$Version = $match.Groups[1].Value.Trim()
}

$jarSource = Join-Path $root "SkyCraft/fabric/build/libs/skycraft-$Version.jar"
if (-not (Test-Path -LiteralPath $jarSource -PathType Leaf)) {
	throw "Build the mod first; expected $jarSource"
}
$dist = Join-Path $root 'dist'
$stage = Join-Path $env:TEMP ('mariocraft-package-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $dist, $stage | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$jar = [System.IO.Compression.ZipFile]::OpenRead($jarSource)
try {
	$entries = @($jar.Entries | Where-Object { -not [string]::IsNullOrEmpty($_.Name) })
	$paths = @($entries | ForEach-Object { $_.FullName.Replace('\', '/') })
	foreach ($required in @(
		'fabric.mod.json',
		'assets/skycraft/installer/install-native.ps1',
		'assets/skycraft/installer/build-native.sh',
		'assets/skycraft/installer/sm64coopdx.patch',
		'assets/skycraft/installer/apply-native-patch.ps1',
		'assets/skycraft/installer/native-manifest.json',
		'assets/skycraft/installer/native-delta.gz'
	)) {
		if ($paths -notcontains $required) { throw "Mod JAR is missing required entry: $required" }
	}
	$metadataStream = $jar.GetEntry('fabric.mod.json').Open()
	try {
		$reader = [IO.StreamReader]::new($metadataStream)
		$metadata = $reader.ReadToEnd() | ConvertFrom-Json
	} finally {
		if ($null -ne $reader) { $reader.Dispose() } else { $metadataStream.Dispose() }
	}
	if ($metadata.id -ne 'skycraft' -or $metadata.version -ne $Version -or $metadata.name -ne 'MarioCraft') {
		throw 'The JAR metadata does not match the requested MarioCraft version.'
	}
	$manifestReader = [IO.StreamReader]::new($jar.GetEntry('assets/skycraft/installer/native-manifest.json').Open())
	try { $nativeManifest = $manifestReader.ReadToEnd() | ConvertFrom-Json } finally { $manifestReader.Dispose() }
	if ($nativeManifest.schemaVersion -ne 1 -or $nativeManifest.romIncluded -ne $false) { throw 'Invalid native manifest' }
	foreach ($check in @(
		@('assets/skycraft/installer/sm64coopdx.patch', $nativeManifest.sourcePatchSha256),
		@('assets/skycraft/installer/native-delta.gz', $nativeManifest.deltaSha256)
	)) {
		$stream = $jar.GetEntry($check[0]).Open()
		$sha = [Security.Cryptography.SHA256]::Create()
		try { $digest = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '').ToLowerInvariant() }
		finally { $sha.Dispose(); $stream.Dispose() }
		if ($digest -ne $check[1]) { throw "Native resource hash mismatch: $($check[0])" }
	}
	$forbidden = $entries | Where-Object {
		$_.FullName -match '(?i)(^|/)(game|build|saves|baserom)(/|$)|\.(z64|n64|v64|rom|exe|dll|bak)$'
	}
	if ($forbidden) { throw "The mod JAR contains ROM or native game data: $($forbidden.FullName -join ', ')" }
} finally {
	$jar.Dispose()
}

$jarName = "MarioCraft-$Version.jar"
$zipPath = Join-Path $dist "MarioCraft-$Version.zip"
Copy-Item -LiteralPath $jarSource -Destination (Join-Path $stage $jarName)
Copy-Item -LiteralPath (Join-Path $root 'README.md') -Destination (Join-Path $stage 'README.txt')
Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $stage 'LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $root 'THIRD-PARTY-NOTICES.md') -Destination (Join-Path $stage 'THIRD-PARTY-NOTICES.txt')
New-Item -ItemType Directory -Path (Join-Path $stage 'docs') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'docs/MULTIPLAYER-VALIDATION.md') -Destination (Join-Path $stage 'docs/MULTIPLAYER-VALIDATION.md')
Copy-Item -LiteralPath (Join-Path $root 'licenses') -Destination (Join-Path $stage 'licenses') -Recurse
$readmePath = Join-Path $stage 'README.txt'
$readme = [IO.File]::ReadAllText($readmePath)
$readme = [regex]::Replace($readme, '(?m)^!\[MarioCraft:.*\]\(docs/screenshot\.webp\)\r?\n\r?\n', '')
[IO.File]::WriteAllText($readmePath, $readme, [Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath $jarSource -Destination (Join-Path $dist $jarName)
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zipPath -CompressionLevel Optimal
$resolvedStage = [IO.Path]::GetFullPath($stage)
$resolvedTemporaryRoot = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
if (-not $resolvedStage.StartsWith($resolvedTemporaryRoot, [StringComparison]::OrdinalIgnoreCase) -or
    (Split-Path -Leaf $resolvedStage) -notlike 'mariocraft-package-*') {
    throw 'Refusing cleanup outside the package staging directory.'
}
Remove-Item -LiteralPath $resolvedStage -Recurse -Force

$size = (Get-Item -LiteralPath (Join-Path $dist $jarName)).Length
Write-Host "Created $jarName and MarioCraft-$Version.zip ($([math]::Round($size / 1KB)) KB; no ROM or native game files)."
