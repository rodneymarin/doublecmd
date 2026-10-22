#!/bin/bash
# ---------------------------------------------------------------------------
# Aprovisiona el entorno de compilación de Double Commander dentro de la VM
# Ubuntu (QEMU). Es la vía que funciona desde Windows sin WSL.
#
# Etapas:
#   1. Paquetes base (los mismos que el CI oficial del proyecto).
#   2. Lazarus 4.x compilado desde fuente (rama fixes_5) + lazbuild.
#   3. Registro de los 13 paquetes que requiere Double Commander.
#   4. Compilación de los componentes y del binario principal.
# ---------------------------------------------------------------------------
set -u
export DEBIAN_FRONTEND=noninteractive
export PATH="/usr/local/bin:$PATH"

DC_SRC="${DC_SRC:-$HOME/doublecmd}"
SRC_TAR="${SRC_TAR:-/tmp/dc-src.tar.gz}"

step() { echo; echo "=============== $* ==============="; }

step "1/6 Paquetes base del sistema"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  build-essential git curl wget ca-certificates zip patchelf xz-utils \
  fp-units-rtl fp-units-gtk2 fp-compiler fp-units-base fp-units-fcl \
  fp-units-misc fp-units-net fp-utils \
  libgtk-3-dev libdbus-1-dev \
  xvfb x11-apps imagemagick xdotool

step "2/6 Lazarus (desde fuente, rama fixes_5)"
if [ ! -d "$HOME/lazarus/.git" ]; then
  git clone --branch fixes_5 --depth 1 \
    https://gitlab.com/freepascal.org/lazarus/lazarus.git "$HOME/lazarus"
fi
cd "$HOME/lazarus"
if [ ! -x "$HOME/lazarus/lazbuild" ]; then
  make all
  sudo make install
fi
hash -r
echo "lazbuild: $(which lazbuild)"

step "3/6 Configuracion del IDE Lazarus"
mkdir -p "$HOME/.lazarus"
cat > "$HOME/.lazarus/environmentoptions.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<CONFIG>
  <EnvironmentOptions>
    <CompilerFilename Value="fpc"/>
    <LazarusDirectory Value="/usr/local/share/lazarus"/>
    <FPCSourceDirectory Value="/usr/lib/fpc/3.2.2/"/>
  </EnvironmentOptions>
</CONFIG>
EOF

step "4/6 Paquetes de Lazarus"
for p in datetimectrls lazcontrols synedit; do
  lpk=$(find /usr/local/share/lazarus -name "$p.lpk" 2>/dev/null | head -1)
  if [ -n "$lpk" ]; then
    lazbuild --add-package-link "$lpk" >/dev/null 2>&1 && echo "  + $p"
  else
    echo "  ! no se encontro $p.lpk"
  fi
done

step "5/6 Fuente de Double Commander y registro de sus paquetes"
if [ -f "$SRC_TAR" ]; then
  rm -rf "$DC_SRC"; mkdir -p "$DC_SRC"
  tar xzf "$SRC_TAR" -C "$DC_SRC"
fi
cd "$DC_SRC"
# Los scripts vienen con CRLF desde Windows: hay que normalizarlos a LF.
find . -name '*.sh' -o -name '*.cmd' | while read f; do
  sed -i 's/\r$//' "$f"; chmod +x "$f"
done
# Repo git mínimo para que el hook de revisión del .lpi funcione.
if [ ! -d .git ]; then
  git init -q .
  git add -A >/dev/null 2>&1
  git -c user.email=dc@local -c user.name=dc commit -q -m snapshot >/dev/null 2>&1
fi

cd "$DC_SRC/components"
for pair in \
  "chsdet:chsdet.lpk" \
  "multithreadprocs:multithreadprocslaz.lpk" \
  "kascrypt:kascrypt.lpk" \
  "doublecmd:doublecmd_common.lpk" \
  "Image32:Image32.lpk" \
  "KASToolBar:kascomp.lpk" \
  "viewer:viewerpackage.lpk" \
  "gifview:gifview.lpk" \
  "synunihighlighter:synuni.lpk" \
  "virtualterminal:virtualterminal.lpk" ; do
  DIR="${pair%%:*}"; LPK="${pair##*:}"
  lazbuild --add-package-link "$DC_SRC/components/$DIR/$LPK" >/dev/null 2>&1 && echo "  + $DIR"
done

step "6/6 Compilacion"
cd "$DC_SRC"
export lcl="${LCL_WIDGETSET:-gtk2}"
export CPU_TARGET=$(fpc -iTP)
export DC_ARCH="--widgetset=$lcl"
bash components/build.sh 2>&1 | grep -E 'Error|Fatal' | tail -5
bash build.sh doublecmd 2>&1 | grep -vE '^Hint: \(lazarus\)|^Info: \(lazarus\)' | tail -8

echo
echo "=============== RESULTADO ==============="
if [ -x "$DC_SRC/doublecmd" ]; then
  ls -la "$DC_SRC/doublecmd"
  file "$DC_SRC/doublecmd"
else
  echo "NO SE GENERO EL BINARIO"
  exit 1
fi
