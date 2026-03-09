$ErrorActionPreference = 'Stop'

$repoRoot = 'C:\Users\post\vscode\voicebox'
$webDir = Join-Path $repoRoot 'web'
$logDir = Join-Path $repoRoot '.run-logs'
$bunPath = 'C:\Users\post\AppData\Local\Microsoft\WinGet\Packages\Oven-sh.Bun_Microsoft.Winget.Source_8wekyb3d8bbwe\bun-windows-x64\bun.exe'
$serverExe = 'C:\Users\post\AppData\Local\Voicebox\voicebox-server.exe'
$dataDir = 'C:\Users\post\AppData\Local\Voicebox'
$backendPort = 17493
$webPort = 5173

function Get-LanIp {
  $udpClient = New-Object System.Net.Sockets.UdpClient
  try {
    $udpClient.Connect('8.8.8.8', 80)
    return $udpClient.Client.LocalEndPoint.Address.IPAddressToString
  } finally {
    $udpClient.Close()
  }
}

function Wait-HttpReady {
  param(
    [string]$Url,
    [int]$TimeoutSeconds = 30
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    try {
      Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 3 | Out-Null
      return
    } catch {
      Start-Sleep -Milliseconds 750
    }
  }

  throw "Timed out waiting for $Url"
}

function Stop-PortProcess {
  param([int]$Port)

  $connections = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
  if (-not $connections) {
    return
  }

  $processIds = $connections | Select-Object -ExpandProperty OwningProcess -Unique
  foreach ($processId in $processIds) {
    try {
      Stop-Process -Id $processId -Force -ErrorAction Stop
    } catch {
      Write-Warning "Failed to stop process ${processId} on port ${Port}: $($_.Exception.Message)"
    }
  }
}

function Test-BackendHealth {
  param([string]$BackendUrl)

  try {
    Invoke-WebRequest -UseBasicParsing -Uri "$BackendUrl/health" -TimeoutSec 5 | Out-Null
    return $true
  } catch {
    return $false
  }
}

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$lanIp = Get-LanIp
$backendUrl = "http://${lanIp}:${backendPort}"
$webUrlLocal = "http://127.0.0.1:$webPort"
$webUrlLan = "http://${lanIp}:${webPort}"

if (-not (Test-BackendHealth -BackendUrl $backendUrl)) {
  Start-Process `
    -FilePath $serverExe `
    -ArgumentList @('--host', '0.0.0.0', '--port', $backendPort, '--data-dir', $dataDir) `
    -WorkingDirectory $repoRoot `
    -WindowStyle Minimized `
    -RedirectStandardOutput (Join-Path $logDir 'backend.out.log') `
    -RedirectStandardError (Join-Path $logDir 'backend.err.log')

  Wait-HttpReady -Url "$backendUrl/health" -TimeoutSeconds 90
}

Stop-PortProcess -Port $webPort

$webCommand = "set VITE_SERVER_URL=$backendUrl&& `"$bunPath`" run dev --host 0.0.0.0 --port $webPort"
Start-Process `
  -FilePath 'cmd.exe' `
  -ArgumentList @('/c', $webCommand) `
  -WorkingDirectory $webDir `
  -WindowStyle Minimized `
  -RedirectStandardOutput (Join-Path $logDir 'web.out.log') `
  -RedirectStandardError (Join-Path $logDir 'web.err.log')

Wait-HttpReady -Url $webUrlLocal -TimeoutSeconds 45

Start-Process $webUrlLocal

Write-Host "Voicebox web is running."
Write-Host "Local URL: $webUrlLocal"
Write-Host "LAN URL:   $webUrlLan"
Write-Host "Backend:   $backendUrl"
