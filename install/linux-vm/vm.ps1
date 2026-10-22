$ErrorActionPreference = 'Stop'
$WorkDir = "$env:TEMP\opencode\dl"
$Key     = "$WorkDir\dcbuild_ed25519"
$Host_   = 'ubuntu@127.0.0.1'
$Port    = 2222

function Invoke-VM([string]$remoteCmd) {
  & ssh -i $Key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR `
        -o ConnectTimeout=20 -p $Port $Host_ $remoteCmd 2>&1 | Out-String
}

# Envia un script local a la VM y lo ejecuta.
function Invoke-VMScript([string]$localPath, [string]$remotePath = '/tmp/script.sh', [string]$sudo = '') {
  & scp -i $Key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR `
        -P $Port $localPath "${Host_}:$remotePath" 2>&1 | Out-Null
  $cmd = if($sudo){ "sudo bash $remotePath" } else { "bash $remotePath" }
  Invoke-VM $cmd
}

# Copia archivos locales a la VM.
function Copy-ToVM([string]$localPath, [string]$remotePath) {
  & scp -i $Key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR `
        -P $Port $localPath "${Host_}:$remotePath" 2>&1 | Out-String
}
