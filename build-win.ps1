# Local development build script (Windows).
# Builds Double Commander with the Lazarus/FPC installation in C:\lazarus.
param(
  [string]$LazarusDir = 'C:\lazarus',
  [string]$BuildMode = 'release',
  [string]$WidgetSet = 'win32',
  [string]$Cpu = 'x86_64',
  [switch]$Clean
)
$ErrorActionPreference = 'Continue'
$env:PATH = "$LazarusDir;$LazarusDir\fpc\3.2.2\bin\$Cpu-win64;$env:PATH"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$units = Join-Path $root "units\$Cpu-win64-$WidgetSet"

if ($Clean -and (Test-Path $units)) {
  Write-Host "Cleaning $units" -ForegroundColor DarkGray
  Remove-Item $units -Recurse -Force
}

$log = Join-Path $env:TEMP 'dcbuild.log'
& lazbuild (Join-Path $root 'src\doublecmd.lpi') --bm=$BuildMode --ws=$WidgetSet --cpu=$Cpu *> $log
$code = $LASTEXITCODE

if ($code -ne 0) {
  Write-Host "BUILD FAILED" -ForegroundColor Red
  Get-Content $log | Select-String -Pattern 'Fatal|Error:' |
    Where-Object { $_.Line -notmatch 'dmhigh.json|doublecmd.svgz' } |
    Select-Object -First 40 | ForEach-Object { Write-Host $_.Line }
} else {
  Write-Host "BUILD OK" -ForegroundColor Green
  Get-Content $log | Select-String -Pattern 'lines compiled|Linking' |
    Select-Object -Last 2 | ForEach-Object { Write-Host $_.Line }
}
exit $code
