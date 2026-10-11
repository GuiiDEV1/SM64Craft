# MarioCraft: puts a "MarioCraft" instance into Prism Launcher (Minecraft 26.3, Fabric, Fabric API,
# e4mc and the MarioCraft mod), or brings its mods up to date. Prism plays it with the Microsoft
# account you signed in to Prism with, so your own skin shows up in SM64 (and to other players).
#
# Run by "MarioCraft Launcher.exe" before every start (quick when nothing changed), or by hand:
#   powershell -ExecutionPolicy Bypass -File launcher\setup-prism.ps1
#
# Which Prism: the installed one (%APPDATA%\PrismLauncher), else SkyCraft's portable one
# (%LOCALAPPDATA%\SkyCraft\Prism). Only the selected MarioCraft-managed instance is touched.
param([switch]$Quiet, [switch]$MinecraftView, [switch]$AllowMissingRom)
$ErrorActionPreference = "Stop"
Import-Module Microsoft.PowerShell.Utility -ErrorAction Stop
$root = Split-Path -Parent $PSScriptRoot

function Say([string]$text) { if (-not $Quiet) { Write-Host $text } }

function Get-FileDigest([string]$Path, [string]$Algorithm = "SHA256") {
    $hasher = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    if ($null -eq $hasher) { throw "Unsupported hash algorithm: $Algorithm" }
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            return [System.BitConverter]::ToString($hasher.ComputeHash($stream)).Replace("-", "")
        } finally {
            $stream.Dispose()
        }
    } finally {
        $hasher.Dispose()
    }
}

# Where Prism keeps its instances, and its program.
$installedData = Join-Path $env:APPDATA "PrismLauncher"
$installedExe = @("$env:LOCALAPPDATA\Programs\PrismLauncher\prismlauncher.exe", "$env:ProgramFiles\PrismLauncher\prismlauncher.exe") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
$portable = Join-Path $env:LOCALAPPDATA "SkyCraft\Prism"
if ($installedExe -and (Test-Path $installedData)) {
    $prismExe = $installedExe
    $data = $installedData
} elseif (Test-Path "$portable\prismlauncher.exe") {
    $prismExe = "$portable\prismlauncher.exe"
    $data = $portable
} elseif ($installedExe) {
    throw "Prism Launcher is installed but hasn't been opened yet. Open it once, sign in (Accounts, top right: Manage Accounts, Add Microsoft) with the account that owns Minecraft, close it, then try again."
} else {
    throw "Prism Launcher isn't installed. Get it from https://prismlauncher.org, sign in to your Microsoft account in it once, then try again."
}

# The jars: Fabric API and e4mc pinned as SkyCraft pins them (checked against the same hashes),
# taken from SkyCraft's own Prism copy or this project's cache; the MarioCraft mod from the build.
$pins = @(
    @{ Name = "fabric-api-0.161.0+26.3.jar"; Url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/bNnaTiuM/fabric-api-0.161.0%2B26.3.jar";
       Sha512 = "ed6b2586d6fde11fde8472f5a527c51e99b67026e46f94d4bfd85e7e28ce5ee299173ee16ad576ceb51f39f98d30a811086a6deb1a86a524859cc16e12da109d" },
    @{ Name = "e4mc-fabric-6.2.2-modern.jar"; Url = "https://cdn.modrinth.com/data/qANg5Jrr/versions/AouleFRY/e4mc-fabric-6.2.2-modern.jar";
       Sha512 = "01ef0a8c5b76e2cb0effd337bad3350d8807d100d0ec661e01b2ffb20af7b652f756c5eaa11bee233c37905bfd7b573f7a85f3d15bfd2833962c76f02cd59a86" }
)
$cache = Join-Path $PSScriptRoot "cache"
$skycraftMods = Join-Path $env:LOCALAPPDATA "SkyCraft\Prism\instances\SkyCraft\.minecraft\mods"

function Get-PinnedJar($pin) {
    $cached = Join-Path $cache $pin.Name
    foreach ($candidate in @($cached, (Join-Path $skycraftMods $pin.Name))) {
        if ((Test-Path $candidate) -and (Get-FileDigest $candidate SHA512) -eq $pin.Sha512.ToUpper()) {
            return $candidate
        }
    }
    Say "Downloading $($pin.Name)..."
    New-Item -ItemType Directory $cache -Force | Out-Null
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $pin.Url -OutFile $cached -UseBasicParsing
    if ((Get-FileDigest $cached SHA512) -ne $pin.Sha512.ToUpper()) {
        Remove-Item $cached
        throw "$($pin.Name) didn't match its pinned hash"
    }
    return $cached
}

$modJar = Get-ChildItem "$root\SkyCraft\fabric\build\libs\skycraft-*.jar" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch '-sources' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $modJar) {
    throw "The MarioCraft Minecraft mod isn't built yet: in SkyCraft\fabric run .\gradlew build"
}

# The instance.
$instanceName = if ($MinecraftView) { "MarioCraft-View" } else { "MarioCraft" }
$instance = Join-Path $data "instances\$instanceName"
$mods = Join-Path $instance ".minecraft\mods"
$romFolder = Join-Path $data "instances\MarioCraft\.minecraft\sm64craft"
New-Item -ItemType Directory -Force -Path $romFolder, (Join-Path $instance ".minecraft\sm64craft") | Out-Null
$romSource = Join-Path $romFolder "baserom.us.z64"
$legacyRom = Join-Path $root "baserom.us.z64"
$romHash = "9BEF1128717F958171A4AFAC3ED78EE2BB4E86CE"
if (!(Test-Path -LiteralPath $romSource) -and (Test-Path -LiteralPath $legacyRom)) {
    if ((Get-FileDigest $legacyRom SHA1) -eq $romHash) {
        Copy-Item -LiteralPath $legacyRom -Destination $romSource
        Say "Moved the verified ROM into the Minecraft instance's sm64craft folder"
    } else {
        Say "Ignoring the old root ROM file; use the USA ROM in $romFolder"
    }
}
if (Test-Path -LiteralPath $romSource) {
    if ((Get-FileDigest $romSource SHA1) -ne $romHash) {
        throw "The ROM in $romFolder isn't the Super Mario 64 USA ROM. Run install.bat to validate it."
    }
    foreach ($romDestination in @(
        (Join-Path $root "sm64coopdx\build\us_pc\baserom.us.z64"),
        (Join-Path $env:APPDATA "sm64coopdx\baserom.us.z64")
    )) {
        if (!(Test-Path -LiteralPath $romDestination) -or
            (Get-FileDigest $romDestination SHA1) -ne $romHash) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $romDestination) | Out-Null
            Copy-Item -LiteralPath $romSource -Destination $romDestination -Force
        }
    }
} elseif (!$AllowMissingRom) {
    throw "No verified USA ROM found. Put your own baserom.us.z64 in $romFolder and run install.bat. MarioCraft doesn't include the ROM."
}
$new = -not (Test-Path "$instance\instance.cfg")
New-Item -ItemType Directory $mods -Force | Out-Null
if ($new) {
	Say "Adding the $instanceName instance to Prism ($data)"
	Copy-Item "$root\SkyCraft\tools\minecraft-bundle\Prism\instances\SkyCraft\mmc-pack.json" "$instance\mmc-pack.json"
}
if ($new -or $MinecraftView) {
	$instanceLabel = if ($MinecraftView) { "MarioCraft Minecraft View" } else { "MarioCraft" }
	$jvmArgs = if ($MinecraftView) {
		"--enable-native-access=ALL-UNNAMED -Dmariocraft.view=true -Dskycraft.showWindow=true -Dskycraft.discordAppId=0"
	} else {
		"--enable-native-access=ALL-UNNAMED -Dskycraft.startHidden=true -Dskycraft.discordAppId=0"
	}
    $utf8 = New-Object System.Text.UTF8Encoding $false
	if ($new) {
		$cfg = @"
[General]
InstanceType=OneSix
name=$instanceLabel
iconKey=default
notes=Managed by MarioCraft. Minecraft View shows the external SM64 renderer inside the Minecraft window.
OverrideJavaArgs=true
JvmArgs=$jvmArgs
OverrideMemory=true
MinMemAlloc=512
MaxMemAlloc=4096
OverrideConsole=true
ShowConsole=false
AutoCloseConsole=false
ShowConsoleOnError=true
"@
	} else {
		# Keep the existing instance's Java 25 override, memory settings and launcher metadata.
		$cfg = Get-Content -LiteralPath (Join-Path $instance "instance.cfg") -Raw
		$cfg = [regex]::Replace($cfg, '(?m)^name=.*$', "name=$instanceLabel")
		$cfg = [regex]::Replace($cfg, '(?m)^JvmArgs=.*$', "JvmArgs=$jvmArgs")
		$cfg = [regex]::Replace($cfg, '(?m)^OverrideJavaArgs=.*$', "OverrideJavaArgs=true")
	}
    [System.IO.File]::WriteAllText("$instance\instance.cfg", $cfg.Replace("`r`n", "`n"), $utf8)
}

# Mods: replace ours (and the pinned ones) whenever they differ; leave anything else the player added.
function Sync-Jar([string]$source, [string]$pattern, [string]$name) {
    $dest = Join-Path $mods $name
    Get-ChildItem $mods -Filter $pattern | Where-Object { $_.Name -ne $name } | Remove-Item -Force
    if (-not (Test-Path $dest) -or (Get-FileDigest $dest) -ne (Get-FileDigest $source)) {
        Copy-Item $source $dest -Force
        Say "Updated $name"
    }
}
foreach ($pin in $pins) {
    $pattern = if ($pin.Name -like "fabric-api-*") { "fabric-api-*.jar" } else { "e4mc-*.jar" }
    Sync-Jar (Get-PinnedJar $pin) $pattern $pin.Name
}
Sync-Jar $modJar.FullName "skycraft-*.jar" $modJar.Name

# For the launcher: which Prism to start.
Set-Content (Join-Path $PSScriptRoot "prism-path.txt") $prismExe -Encoding ASCII
Set-Content (Join-Path $PSScriptRoot "rom-folder-path.txt") $romFolder -Encoding ASCII
Say "$instanceName instance ready in $data"
