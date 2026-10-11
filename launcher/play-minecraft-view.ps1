param([string]$SavePath)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$setup = Join-Path $PSScriptRoot "setup-prism.ps1"
$sm64 = Join-Path $root "sm64coopdx\build\us_pc\sm64coopdx.exe"
$sm64Dir = Split-Path -Parent $sm64
$savePath = if ([string]::IsNullOrWhiteSpace($SavePath)) {
	Join-Path $env:APPDATA "sm64coopdx-minecraft-view"
} else {
	[System.IO.Path]::GetFullPath($SavePath)
}
$rom = $null
$expectedRomSha1 = "9BEF1128717F958171A4AFAC3ED78EE2BB4E86CE"
$mutexName = "Local\MarioCraft_v1_minecraft"

if (-not ("MarioCraftViewWindowControl" -as [type])) {
	Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class MarioCraftViewWindowControl {
	private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
	[DllImport("user32.dll")] private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
	[DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
	[DllImport("user32.dll")] private static extern bool PostMessage(IntPtr hWnd, uint message, IntPtr wParam, IntPtr lParam);
	[DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr hWnd);
	[DllImport("user32.dll")] private static extern bool ShowWindow(IntPtr hWnd, int command);
	[DllImport("user32.dll")] private static extern bool SetForegroundWindow(IntPtr hWnd);

	public static int CloseProcessWindows(int targetPid) {
		int sent = 0;
		EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
			uint pid;
			GetWindowThreadProcessId(hWnd, out pid);
			if (pid == targetPid && PostMessage(hWnd, 0x0010, IntPtr.Zero, IntPtr.Zero)) sent++;
			return true;
		}, IntPtr.Zero);
		return sent;
	}

	public static bool FocusProcessWindow(int targetPid) {
		bool focused = false;
		EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
			uint pid;
			GetWindowThreadProcessId(hWnd, out pid);
			if (pid == targetPid && IsWindowVisible(hWnd)) {
				ShowWindow(hWnd, 9);
				focused = SetForegroundWindow(hWnd);
				return false;
			}
			return true;
		}, IntPtr.Zero);
		return focused;
	}
}
'@
}

function Test-MarioCraftMinecraftRunning {
	$mutex = $null
	try {
		$mutex = [System.Threading.Mutex]::OpenExisting($mutexName)
		return $true
	} catch [System.Threading.WaitHandleCannotBeOpenedException] {
		return $false
	} finally {
		if ($null -ne $mutex) { $mutex.Dispose() }
	}
}

function Close-LaunchedSm64([System.Diagnostics.Process]$process) {
	if ($null -eq $process -or $process.HasExited) { return }
	$null = $process.CloseMainWindow()
	if (-not $process.WaitForExit(2500)) {
		[void][MarioCraftViewWindowControl]::CloseProcessWindows($process.Id)
	}
	if (-not $process.WaitForExit(8000)) {
		Write-Warning "O SM64 não respondeu ao pedido de fechar. Salve e feche essa janela manualmente."
	}
}

if (-not (Test-Path -LiteralPath $sm64)) {
	throw "O executável SM64 não foi compilado. Rode install.bat primeiro."
}
if ((Get-Process -Name "sm64coopdx" -ErrorAction SilentlyContinue) -or (Test-MarioCraftMinecraftRunning)) {
	throw "MarioCraft já está aberto. Feche o jogo e tente novamente para evitar conectar sessões diferentes."
}

Write-Host "Preparando a instância separada MarioCraft-View..."
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup -MinecraftView
if ($LASTEXITCODE -ne 0) { throw "Não foi possível preparar a instância Minecraft View." }

$romFolderPathFile = Join-Path $PSScriptRoot "rom-folder-path.txt"
if (-not (Test-Path -LiteralPath $romFolderPathFile)) { throw "O instalador não registrou a pasta sm64craft da instância." }
$romFolder = (Get-Content -LiteralPath $romFolderPathFile -Raw).Trim()
$rom = Join-Path $romFolder "baserom.us.z64"
if (-not (Test-Path -LiteralPath $rom)) {
	throw "Coloque sua ROM USA em $romFolder e rode install.bat para validar a cópia."
}
$sha1 = [System.Security.Cryptography.SHA1]::Create()
try {
	$romStream = [System.IO.File]::OpenRead($rom)
	try {
		$actualRomSha1 = [System.BitConverter]::ToString($sha1.ComputeHash($romStream)).Replace("-", "")
	} finally {
		$romStream.Dispose()
	}
} finally {
	$sha1.Dispose()
}
if ($actualRomSha1 -ne $expectedRomSha1) {
	throw "O arquivo baserom.us.z64 dentro da pasta sm64craft não é a ROM USA esperada. Rode install.bat para validar."
}

$prismPathFile = Join-Path $PSScriptRoot "prism-path.txt"
if (-not (Test-Path -LiteralPath $prismPathFile)) { throw "O caminho do Prism Launcher não foi encontrado." }
$prism = (Get-Content -LiteralPath $prismPathFile -Raw).Trim()
if (-not (Test-Path -LiteralPath $prism)) { throw "Prism Launcher não foi encontrado em: $prism" }

New-Item -ItemType Directory -Force -Path $savePath | Out-Null
# Give View its own modest window size on first run. Preserve any existing View preferences,
# and keep the classic SM64 profile untouched.
$sm64Config = Join-Path $savePath "sm64config.txt"
if (-not (Test-Path -LiteralPath $sm64Config)) {
	@("fullscreen false", "window_w 960", "window_h 540", "vsync false", "frame_limit 60") |
		Set-Content -LiteralPath $sm64Config -Encoding Ascii
}
# The View build has an asynchronous D3D11 staging readback. OpenGL's glReadPixels path is
# synchronous and can stall SM64 while Minecraft is also rendering the mirrored chunks.
$sm64Args = "--savepath `"$savePath`" --backend directx"
$game = Start-Process -FilePath $sm64 -ArgumentList $sm64Args -WorkingDirectory $sm64Dir -PassThru
Start-Sleep -Milliseconds 1200
if ($game.HasExited) { throw "O SM64 fechou ao iniciar. Confira sm64coopdx-build.log e rom-startup.log." }

try {
	Write-Host "Abrindo o Minecraft visível. Jogue pela janela do Minecraft; o SM64 fornece a imagem."
	$null = Start-Process -FilePath $prism -ArgumentList "--launch MarioCraft-View" -PassThru
} catch {
	Close-LaunchedSm64 $game
	throw
}

Write-Host "Minecraft View iniciado. Fechar o Minecraft encerra o SM64 desta sessão; fechar o SM64 encerra o Minecraft."
$minecraftWasRunning = $false
$minecraftFocused = $false
while (-not $game.HasExited) {
	$viewProcess = Get-Process -Name javaw -ErrorAction SilentlyContinue |
		Where-Object { $_.MainWindowTitle -like "Minecraft*26.3*" } | Select-Object -First 1
	if (-not $minecraftFocused -and $null -ne $viewProcess) {
		$minecraftFocused = [MarioCraftViewWindowControl]::FocusProcessWindow($viewProcess.Id)
	}
	if (Test-MarioCraftMinecraftRunning) {
		$minecraftWasRunning = $true
	} elseif ($minecraftWasRunning) {
		Write-Host "Minecraft foi fechado; encerrando o SM64 desta sessão..."
		Close-LaunchedSm64 $game
		break
	}
	Start-Sleep -Seconds 1
}

Write-Host "Sessão MarioCraft encerrada."
