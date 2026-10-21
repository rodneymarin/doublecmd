#!/bin/bash
# ---------------------------------------------------------------------------
# Aprovisiona el entorno de compilación de Double Commander dentro de WSL.
# Reproduce el recipe del CI oficial del proyecto:
#   .github/workflows/snapshots.yml  (job build-lin)
#   .github/scripts/create_snapshot.lnx
# ---------------------------------------------------------------------------
set -e
export DEBIAN_FRONTEND=noninteractive

DC_SRC="${DC_SRC:-/mnt/c/Users/rodne/Documents/Dev/doublecmd}"
LAZ_DIR="${LAZ_DIR:-/usr/local/share/lazarus}"

step() { echo; echo "=============== $* ==============="; }

step "1/6 Paquetes base del sistema"
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential git curl wget ca-certificates zip patchelf xz-utils \
  fp-units-rtl fp-units-gtk2 fp-compiler fp-units-base fp-units-fcl \
  fp-units-misc fp-units-net fp-utils \
  libgtk-3-dev libdbus-1-dev

step "2/6 Bibliotecas externas de Double Commander (github.com/doublecmd/external)"
mkdir -p "$DC_SRC/install"
cd "$DC_SRC"
if [ ! -f install/linux/lib/x86_64/qt6/libQt6Pas.so.6 ]; then
  wget -q -O /tmp/dc_linux.tar.gz https://github.com/doublecmd/external/raw/main/linux.tar.gz
  tar xzf /tmp/dc_linux.tar.gz -C install
  rm -f /tmp/dc_linux.tar.gz
fi

step "3/6 fpc.cfg: permitir librerias compartidas sin resolver"
if ! grep -q 'allow-shlib-undefined' /etc/fpc.cfg 2>/dev/null; then
  echo "-k--allow-shlib-undefined" | sudo tee -a /etc/fpc.cfg
fi

step "4/6 Lazarus (desde fuente, rama fixes_5, igual que el CI)"
if ! command -v lazbuild >/dev/null 2>&1; then
  if [ ! -d "$HOME/lazarus" ]; then
    git clone --branch fixes_5 --depth 1 \
      https://gitlab.com/freepascal.org/lazarus/lazarus.git "$HOME/lazarus"
  fi
  cd "$HOME/lazarus"
  make all
  sudo make install
fi
lazbuild --version 2>/dev/null || lazbuild -h >/dev/null

step "5/6 Configuracion del IDE Lazarus"
mkdir -p "$HOME/.lazarus"
cat > "$HOME/.lazarus/environmentoptions.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<CONFIG>
  <EnvironmentOptions>
    <CompilerFilename Value="fpc"/>
    <LazarusDirectory Value="$LAZ_DIR"/>
    <FPCSourceDirectory Value="/usr/lib/fpc/src"/>
  </EnvironmentOptions>
</CONFIG>
EOF

step "6/6 Registrando los paquetes que requiere Double Commander"
# Paquetes que ya trae Lazarus
for p in datetimectrls lazcontrols synedit; do
  LPK="$LAZ_DIR/components/$p/$p.lpk"
  [ -f "$LPK" ] && lazbuild --add-package-link "$LPK" && echo "  + $p"
done
# Paquetes que viven en el repositorio de Double Commander
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
  lazbuild --add-package-link "$DC_SRC/components/$DIR/$LPK" && echo "  + $DIR"
done

echo
echo "=============== ENTORNO LISTO ==============="
echo "Para compilar:"
echo "  cd $DC_SRC"
echo "  lcl=gtk3 ./build.sh release"
