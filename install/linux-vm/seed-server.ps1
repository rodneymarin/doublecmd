param(
  [string]$SeedDir = "$env:TEMP\opencode\dl\seed",
  [int]$Port = 8000
)
# ---------------------------------------------------------------------------
# Servidor HTTP minimo que publica la semilla de cloud-init.
# La VM la alcanza en 10.0.2.2 (el host visto desde QEMU user networking).
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
$listener.Start()
"seed server escuchando en 0.0.0.0:${Port} (raiz: $SeedDir)"

while($true){
  $client = $listener.AcceptTcpClient()
  $stream = $client.GetStream()
  $reader = New-Object System.IO.StreamReader($stream)
  $req = $reader.ReadLine()
  while($null -ne ($l = $reader.ReadLine()) -and $l -ne ''){ }
  $parts = ($req -split ' ')[1]
  $name = ($parts -split '\?')[0].TrimStart('/')
  if($name -eq ''){ $name = 'index.html' }

  $path = Join-Path $SeedDir $name
  if(Test-Path $path -PathType Leaf){
    $body = [System.IO.File]::ReadAllBytes($path)
    $head = "HTTP/1.1 200 OK`r`nContent-Type: text/plain`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
    $hb = [System.Text.Encoding]::ASCII.GetBytes($head)
    $stream.Write($hb, 0, $hb.Length)
    $stream.Write($body, 0, $body.Length)
    "  -> $name ($($body.Length) bytes)"
  } else {
    $msg = "not found: $name"
    $hb = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 404 Not Found`r`nContent-Length: $($msg.Length)`r`nConnection: close`r`n`r`n$msg")
    $stream.Write($hb, 0, $hb.Length)
    "  -> 404 $name"
  }
  $stream.Flush(); $client.Close()
}
