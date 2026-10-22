param(
  [int]$Cpus = 8,
  [int]$MemMB = 12288,
  [switch]$NoBrowser
)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$work = "$env:TEMP\opencode\dl"
$env:PATH = "C:\Program Files\qemu;$env:PATH"

Write-Host ""
Write-Host "  === Double Commander - entorno Linux (Qt6) ===" -ForegroundColor Cyan
Write-Host ""

# --- 1. la VM ya esta corriendo? ---
$q = Get-Process qemu-system-x86_64 -ErrorAction SilentlyContinue
if(-not $q){
  Write-Host "[1/3] Levantando la VM Ubuntu (QEMU)..." -ForegroundColor Yellow
  Write-Host "      (la primera vez tarda ~1 min en arrancar)"
  Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","$root\install\linux-vm\run-vm.ps1",`
                    "-Cpus","$Cpus","-MemMB","$MemMB","-Display","none" -WindowStyle Hidden
  $q = $null
} else {
  Write-Host "[1/3] La VM ya estaba corriendo." -ForegroundColor Green
}

# --- 2. esperar a que responda el VNC ---
Write-Host "[2/3] Esperando al escritorio Linux..." -ForegroundColor Yellow
$ok = $false
for($i=0;$i -lt 60;$i++){
  Start-Sleep -Seconds 3
  try {
    $c = New-Object System.Net.Sockets.TcpClient
    $c.Connect("127.0.0.1", 5900)
    $c.Close()
    $ok = $true; break
  } catch { }
}
if(-not $ok){
  Write-Host "      La VM todavia no responde en el puerto 5900. Reintenta en un momento." -ForegroundColor Red
  exit 1
}

# --- 3. abrir el escritorio en el navegador ---
$url = "http://localhost:6080/vnc.html?autoconnect=1&resize=scale"
Write-Host "[3/3] Abriendo el escritorio Linux en el navegador..." -ForegroundColor Green
Write-Host ""
Write-Host "      URL: $url" -ForegroundColor White
Write-Host "      (si no se abre solo, copiala al navegador)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "      Click dentro de la pantalla negra para usar el teclado." -ForegroundColor DarkGray
Write-Host "      Para salir: Alt+F4 dentro de la app, o 'Exit Alt+X'." -ForegroundColor DarkGray
Write-Host ""
if(-not $NoBrowser){ Start-Process $url }
