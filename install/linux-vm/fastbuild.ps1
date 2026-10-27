$ErrorActionPreference = 'Stop'
$root = "C:\Users\rodne\Documents\Dev\doublecmd"
$tmp  = "$env:TEMP\opencode"
$Key  = "$tmp\dl\dcbuild_ed25519"
$Port = 2222
$Host_ = 'ubuntu@127.0.0.1'

function Send([string]$local, [string]$remote) {
  & scp -i $Key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR `
        -P $Port $local "${Host_}:$remote" 2>&1 | Out-String
}
function Run([string]$remote) {
  & ssh -i $Key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR `
        -o ConnectTimeout=20 -p $Port $Host_ $remote 2>&1 | Out-String
}

# 1) empaquetar solo el fuente (sin .git, sin units, sin binarios)
$tar = "$tmp\dc-src.tar.gz"
if (Test-Path $tar) { Remove-Item $tar -Force }
Push-Location $root
& tar -czf $tar --exclude=.git --exclude=units --exclude=doublecmd --exclude=doublecmd.dbg `
        --exclude='*.ppu' --exclude='*.o' --exclude='*.compiled' -C . . 2>&1 | Out-Null
Pop-Location
Write-Host ("tar: {0:N1} MB" -f ((Get-Item $tar).Length/1MB))

# 2) subir el tar y el script de build
Send $tar "/tmp/dc-src.tar.gz" | Out-Null
Send "$tmp\fbuild.sh" "/tmp/fbuild.sh" | Out-Null

# 3) construir
$out = Run "bash /tmp/fbuild.sh"
Write-Host $out
if ($out -notmatch "BUILD OK") { throw "El build ha fallado" }
