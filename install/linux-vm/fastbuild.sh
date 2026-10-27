#!/bin/bash
# ------------------------------------------------------------------
# Build rapido e incremental de Double Commander con Qt6.
#   1. sincroniza el fuente (solo lo que cambia de verdad)
#   2. compila con fpc directamente (sin -B => incremental)
# ------------------------------------------------------------------
set -e
SRC="$HOME/doublecmd"
LOG=/tmp/dcbuild.log

echo "=== 1) sincronizando el fuente ==="
rm -rf /tmp/dcsrc && mkdir -p /tmp/dcsrc
tar -xzf /tmp/dc-src.tar.gz -C /tmp/dcsrc
# Normalizar los finales de linea unix en los scripts y fuentes
find /tmp/dcsrc \( -name '*.pas' -o -name '*.pp' -o -name '*.inc' -o -name '*.lpr' \
                   -o -name '*.lpi' -o -name '*.lfm' -o -name '*.cmd' -o -name '*.sh' \) \
     -print0 | xargs -0 -r sed -i 's/\r$//'
# El tar de Windows no conserva el bit de ejecucion
find /tmp/dcsrc \( -name '*.cmd' -o -name '*.sh' \) -print0 | xargs -0 -r chmod +x

# rsync con checksum: solo copia los ficheros cuyo contenido cambio.
# Los ficheros copiados se tocan para que fpc los recompile.
CHANGED=$(rsync -aci --itemize-changes \
            --exclude='.git/' --exclude='units/' --exclude='doublecmd' \
            --exclude='doublecmd.dbg' --exclude='*.ppu' --exclude='*.o' \
            /tmp/dcsrc/ "$SRC/" | grep -E '^[<>c]' | awk '{print $NF}')
if [ -n "$CHANGED" ]; then
  echo "$CHANGED" | while read -r f; do
    [ -f "$SRC/$f" ] && touch "$SRC/$f"
  done
  echo "ficheros actualizados:"
  echo "$CHANGED" | sed 's/^/  /'
else
  echo "sin cambios en el fuente"
fi

# El generador de la revision de git
mkdir -p "$SRC/units"
cat > "$SRC/units/dcrevision.inc" <<'EOF'
// Created by Git2RevisionInc
const dcRevision = '0';
const dcCommit = 'local';
EOF

echo
echo "=== 2) compilando (incremental) ==="
cd "$SRC/src"
# La linea de fpc capturada del build de lazbuild, sin la flag -B (build all)
CMD=$(grep -v '^-B$' /tmp/fpc_cmd.txt | tr '\n' ' ')
# fpc_cmd.txt ya trae el path del ejecutable en la primera linea
echo "$CMD" > /tmp/fpc_run.sh
chmod +x /tmp/fpc_run.sh
START=$(date +%s)
bash /tmp/fpc_run.sh > /tmp/fpc_out.log 2>&1 || { echo "ERROR AL COMPILAR"; tail -40 /tmp/fpc_out.log; exit 1; }
END=$(date +%s)
echo "compilacion terminada en $((END-START)) s"
tail -3 /tmp/fpc_out.log
strip "$SRC/doublecmd" 2>/dev/null || true
ls -la "$SRC/doublecmd"
echo "BUILD OK"
