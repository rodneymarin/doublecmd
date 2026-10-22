param(
  [string]$WorkDir = "$env:TEMP\opencode\dl",
  [int]$MemMB = 6144,
  [int]$Cpus = 4,
  [int]$SshPort = 2222,
  [int]$SeedPort = 8000,
  [string]$DiskSize = '24G',
  [switch]$NoKvm
)
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Arranca la VM Ubuntu (cloud image + semilla cloud-init) con QEMU.
# El acceso es por SSH en el puerto local $SshPort.
# ---------------------------------------------------------------------------

$base   = Join-Path $WorkDir 'jammy.img'
$overlay= Join-Path $WorkDir 'dcbuild.qcow2'
$log    = Join-Path $WorkDir 'qemu-console.log'

if(-not (Test-Path $base)){ throw "Falta $base" }

if(Test-Path $overlay){ Remove-Item $overlay -Force }
& qemu-img create -f qcow2 -F qcow2 -b $base $overlay $DiskSize | Out-Null
"overlay creado: $overlay"

# En Windows no hay KVM: QEMU usa TCG (emulacion por software).
$kvm = @('-accel','tcg,thread=multi')

# La semilla de cloud-init se sirve por HTTP desde el host (10.0.2.2) y se
# le indica a cloud-init con el numero de serie SMBIOS.
$smbios = @('-smbios', "type=1,serial=ds=nocloud-net;s=http://10.0.2.2:${SeedPort}/")

$args = @(
  '-name','dcbuild',
  '-m', $MemMB,
  '-smp', $Cpus,
  '-cpu','max',
  '-drive', "file=$overlay,if=virtio,format=qcow2,cache=writeback",
  '-netdev', "user,id=n0,hostfwd=tcp::${SshPort}-:22",
  '-device','virtio-net-pci,netdev=n0',
  '-display','none',
  '-serial', "file:$log",
  '-monitor','none',
  '-rtc','base=utc'
) + $kvm + $smbios

"arrancando QEMU (SSH en localhost:${SshPort}) ..."
& qemu-system-x86_64 @args
