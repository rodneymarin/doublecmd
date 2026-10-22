param(
  [string]$WorkDir = "$env:TEMP\opencode\dl",
  [string]$Password = 'dcbuild',
  [string]$PubKeyFile = "$env:TEMP\opencode\dl\dcbuild_ed25519.pub"
)
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Crea la semilla de cloud-init para la VM Ubuntu.
# Genera un disco FAT32 con la etiqueta "cidata" (que es lo que busca el
# datasource NoCloud de cloud-init) y lo convierte a imagen raw para QEMU.
# ---------------------------------------------------------------------------

$seedDir = Join-Path $WorkDir 'seed'
$vhd     = Join-Path $WorkDir 'seed.vhd'
$raw     = Join-Path $WorkDir 'seed.raw'

New-Item -ItemType Directory -Force -Path $seedDir | Out-Null

$pubKey = ''
if(Test-Path $PubKeyFile){ $pubKey = (Get-Content $PubKeyFile -Raw).Trim() }
if(-not $pubKey){ throw "No se encontro la clave publica en $PubKeyFile" }

$userData = @"
#cloud-config
hostname: dcbuild
manage_etc_hosts: true
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    plain_text_passwd: '$Password'
    ssh_authorized_keys:
      - $pubKey
ssh_pwauth: true
disable_root: false
chpasswd:
  list: |
    ubuntu:$Password
  expire: false
growpart:
  mode: auto
  devices: ['/']
resize_rootfs: true
final_message: "cloud-init done"
"@

$metaData = @"
instance-id: dcbuild-001
local-hostname: dcbuild
"@

[System.IO.File]::WriteAllText((Join-Path $seedDir 'user-data'), ($userData -replace "`r`n","`n"))
[System.IO.File]::WriteAllText((Join-Path $seedDir 'meta-data'), ($metaData -replace "`r`n","`n"))

Remove-Item $vhd,$raw -Force -ErrorAction SilentlyContinue

# --- crear y formatear el VHD FAT32 con etiqueta cidata via diskpart ---
$dp = Join-Path $WorkDir 'seed_dp.txt'
@"
create vdisk file="$vhd" maximum=64 type=fixed
select vdisk file="$vhd"
attach vdisk
format fs=fat32 label=cidata quick
assign letter=Z
"@ | Set-Content $dp -Encoding ASCII

Start-Process -FilePath "$env:SystemRoot\System32\diskpart.exe" -ArgumentList "/s", "`"$dp`"" -Wait -WindowStyle Hidden

Start-Sleep -Seconds 2
if(-not (Test-Path 'Z:\')){ throw "No se pudo asignar la letra Z: a la unidad" }

Copy-Item (Join-Path $seedDir 'user-data')  'Z:\user-data'  -Force
Copy-Item (Join-Path $seedDir 'meta-data')  'Z:\meta-data'  -Force

# --- expulsar ---
$dp2 = Join-Path $WorkDir 'seed_dp2.txt'
@"
select vdisk file="$vhd"
detach vdisk
"@ | Set-Content $dp2 -Encoding ASCII
Start-Process -FilePath "$env:SystemRoot\System32\diskpart.exe" -ArgumentList "/s", "`"$dp2`"" -Wait -WindowStyle Hidden

# --- convertir a raw ---
$qemuImg = 'C:\Program Files\qemu\qemu-img.exe'
if(-not (Test-Path $qemuImg)){
  $cmd = Get-Command qemu-img -ErrorAction SilentlyContinue
  if($cmd){ $qemuImg = $cmd.Source } else { throw "qemu-img no encontrado (instala QEMU o ajustá la ruta)" }
}
& $qemuImg convert -f vpc -O raw $vhd $raw
if(-not (Test-Path $raw)){ throw "qemu-img no genero $raw" }
"semilla creada: $raw ($([math]::Round((Get-Item $raw).Length/1KB)) KB)"
