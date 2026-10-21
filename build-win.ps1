# Local development build script (Windows).
# Builds Double Commander with the Lazarus/FPC installation in C:\lazarus.
param(
  [string]$LazarusDir = 'C:\lazarus',
  [string]$BuildMode = 'release',
  [string]$WidgetSet = 'win32',
  [string]$Cpu = 'x86_64'
)

$ErrorActionPreference = 'Continue'
$env:PATH = "$LazarusDir;$LazarusDir\fpc\3.2.2\bin\$Cpu-win64;$env:PATH"

$log = Join-Path $env:TEMP 'dcbuild.log'
& lazbuild "src\doublecmd.lpi" --bm=$BuildMode --ws=$WidgetSet --cpu=$Cpu *> $log
$code = $LASTEXITCODE

if ($code -ne 0) {
  Write-Host "BUILD FAILED" -ForegroundColor Red
  Get-Content $log | Select-String -Pattern 'Fatal|Error:|Warning:' |
    Select-Object -First 60 | ForEach-Object { Write-Host $_.Line }
} else {
  Write-Host "BUILD OK" -ForegroundColor Green
  Get-Content $log | Select-String -Pattern 'lines compiled|Linking' |
    Select-Object -Last 3 | ForEach-Object { Write-Host $_.Line }
}
exit $code
