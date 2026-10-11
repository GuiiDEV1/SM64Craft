param([ValidateSet('Host','Guest','Guest2')][string]$Role, [string]$Root, [switch]$ClientOnly,
    [ValidateSet('Socket','CoopNet')][string]$Transport='Socket', [string]$Scenario='multiplayer-probe.lua')
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
if (!$Root) { $Root = Join-Path $workspace 'dist/multiplayer-probe' }
$client = Join-Path $Root $Role
New-Item -ItemType Directory -Force $client, "$client/config", "$client/probe", "$client/native-saves" | Out-Null
# Commands belong to one process; replaying the previous quit during shader loading
# can stop Minecraft while native resource callbacks are still running.
if (Test-Path -LiteralPath "$client/probe/command.json") { Remove-Item -LiteralPath "$client/probe/command.json" }
$runtime = Join-Path $Root 'game'
if (!(Test-Path "$runtime/sm64coopdx.exe")) {
    New-Item -ItemType Directory -Force $runtime | Out-Null
    Copy-Item -Path "$workspace/dist/native-fast/video-diagnostic/game/*" -Destination $runtime -Recurse
    Copy-Item "$workspace/dist/native-fast/video-diagnostic/baserom.us.z64" "$runtime/baserom.us.z64"
    Copy-Item "$workspace/dist/native-fast/sm64coopdx-8cd6e5977d9f920d51ca71f2c61801d019ed79c6/build/us_pc/sm64coopdx.exe" "$runtime/sm64coopdx.exe"
}
Set-Content "$client/native-saves/sm64config.txt" "language English`nfullscreen false`nwindow_w 640`nwindow_h 360`ncoop_network_system 1`nskip_intro true`ncoop_menu_demos false" -Encoding ascii
New-Item -ItemType Directory -Force "$runtime/mods/multiplayer-validation" | Out-Null
Copy-Item "$workspace/tools/$Scenario" "$runtime/mods/multiplayer-validation/main.lua"
Set-Content "$client/options.txt" "pauseOnLostFocus:false`nmaxFps:30`nrenderDistance:4`nsimulationDistance:4`njoinedFirstServer:true" -Encoding ascii
$namespace = "Local\MarioCraft_probe_$Role"
$env:MARIOCRAFT_LINK = $namespace
$env:MARIOCRAFT_FRAME_LINK = "${namespace}_frame"
$env:MARIOCRAFT_EMBEDDED_VIEW = '1'
$nativeArgs = @('--console','--savepath',"$client/native-saves",'--backend','directx','--skip-intro','--skip-update-check','--no-discord','--playername',$Role,'--enable-mod','multiplayer-validation')
if ($Role -eq 'Host') {
    if ($Transport -eq 'CoopNet') { $nativeArgs += @('--coopnet','MarioCraftLocalValidation1010') }
    else { $nativeArgs += @('--server','27877') }
    $env:SKYCRAFT_LAN_PORT='25599'; $env:SKYCRAFT_LAN_OFFLINE='1'
} else {
    if ($Transport -eq 'Socket') { $nativeArgs += @('--client','127.0.0.1','27877','--playercount','4') }
    Remove-Item Env:SKYCRAFT_LAN_PORT -ErrorAction SilentlyContinue; Remove-Item Env:SKYCRAFT_LAN_OFFLINE -ErrorAction SilentlyContinue
}
if ($ClientOnly) {
    $native = Get-Process -Id (Get-Content "$client/pids.json" -Raw | ConvertFrom-Json).native
} else {
    $native = Start-Process "$runtime/sm64coopdx.exe" -ArgumentList $nativeArgs -WorkingDirectory $runtime -RedirectStandardOutput "$client/native.log" -RedirectStandardError "$client/native.err" -WindowStyle Hidden -PassThru
}
$launch = Get-Content "$workspace/SkyCraft/fabric/build/multiplayer-launch.json" -Raw | ConvertFrom-Json
$arguments = @('-Xmx2G','--enable-native-access=ALL-UNNAMED','-XX:StackShadowPages=32','--sun-misc-unsafe-memory-access=allow','-Dskycraft.quitWithSkyrim=false',"-Dfabric.dli.config=$workspace/SkyCraft/fabric/.gradle/loom-cache/launch.cfg",'-Dfabric.dli.env=client','-Dfabric.dli.main=net.fabricmc.loader.impl.launch.knot.KnotClient') + @($launch.jvmArgs) + @("-Dskycraft.link=$namespace", "-Dmariocraft.probe=$client/probe",'-Dskycraft.discordAppId=0','-cp',$launch.classpath,$launch.main) + @($launch.args) + @('--username',$Role,'--width','640','--height','360')
$argFile = Join-Path $client 'java.args'
$arguments | ForEach-Object { '"' + $_.Replace('\','\\').Replace('"','\"') + '"' } | Set-Content $argFile -Encoding utf8
$java = Join-Path $env:APPDATA 'PrismLauncher/java/java-runtime-epsilon/bin/java.exe'
$minecraft = Start-Process $java -ArgumentList "@$argFile" -WorkingDirectory $client -RedirectStandardOutput "$client/minecraft.log" -RedirectStandardError "$client/minecraft.err" -WindowStyle Hidden -PassThru
@{ native = $native.Id; minecraft = $minecraft.Id; root = $client } | ConvertTo-Json | Set-Content "$client/pids.json"
Get-Content "$client/pids.json"
