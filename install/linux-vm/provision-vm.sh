#!/bin/bash
# ---------------------------------------------------------------------------
# Aprovisiona el entorno de compilación de Double Commander dentro de la VM
# Ubuntu (QEMU). Reproduce el recipe del CI oficial del proyecto:
#   .github/workflows/snapshots.yml  (job build-lin)
#
# Se ejecuta DENTRO de la VM, por SSH.
# ---------------------------------------------------------------------------
set -e
export DEBIAN_FRONTEND=noninteractive

DC_SRC="${DC_SRC:-/mnt/c/Users/rodne/Documents/Dev/doublecmd}"
DEB_DIR="${DEB_DIR:-/tmp/lazdebs}"

step() { echo; echo "=============== $* ==============="; }

step "1/7 Paquetes base del sistema"
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential git curl wget ca-certificates zip patchelf xz-utils \
  libgtk-3-dev libdbus-1-dev \
  xvfb x11-apps imagemagick \
  libgtk2.0-0 libqt5widgets5 libqt5gui5

step "2/7 FPC 3.2.2 + Lazarus 4.8 (paquetes DEB oficiales)"
cd "$DEB_DIR"
sudo dpkg -i ./fpc-laz_*.deb || true
sudo dpkg -i ./fpc-src_*.deb || true
sudo dpkg -i ./lazarus-project_*.deb || true
sudo apt-get -f install -y

export PATH="/usr/lib/fpc/3.2.2/bin:/usr/local/bin:$PATH"
echo "fpc:    $(fpc -iV 2>/dev/null || echo MISSING)"
echo "lazbuild: $(command -v lazbuild || echo MISSING)"

step "3/7 fpc.cfg: permitir librerias compartidas sin resolver"
if ! grep -q 'allow-shlib-undefined' /etc/fpc.cfg 2>/dev/null; then
  echo "-k--allow-shlib-undefined" | sudo tee -a /etc/fpc.cfg
fi

step "4/7 Bibliotecas externas de Double Commander"
mkdir -p "$DC_SRC/install"
cd "$DC_SRC"
if [ ! -d install/linux/lib ]; then
  wget -q -O /tmp/dc_linux.tar.gz https://github.com/doublecmd/external/raw/main/linux.tar.gz
  tar xzf /tmp/dc_linux.tar.gz -C install
  rm -f /tmp/dc_linux.tar.gz
fi

step "5/7 Configuracion del IDE Lazarus"
LAZ_DIR="$(dirname "$(dirname "$(command -v lazbuild)")")/share/lazarus"
[ -d "$LAZ_DIR" ] || LAZ_DIR=/usr/share/lazarus
mkdir -p "$HOME/.lazarus"
cat > "$HOME/.lazarus/environmentoptions.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<CONFIG>
  <EnvironmentOptions>
    <CompilerFilename Value="fpc"/>
    <LazarusDirectory Value="$LAZ_DIR"/>
    <FPCSourceDirectory Value="/usr/lib/fpc/3.2.2/"/>
  </EnvironmentOptions>
</CONFIG>
EOF
echo "LazarusDirectory: $LAZ_DIR"

step "6/7 Registrando los paquetes que requiere Double Commander"
# Paquetes incluidos en Lazarus
for p in datetimectrls lazcontrols synedit; do
  for lpk in $(find /usr /opt -name "$p.lpk" 2>/dev/null | head -1); do
    lazbuild --add-package-link "$lpk" && echo "  + $p ($lpk)"
  done
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

step "7/7 Compilando Double Commander"
cd "$DC_SRC"
export lcl="${LCL_WIDGETSET:-gtk3}"
./build.sh release 2>&1 | tail -40

echo
echo "=============== RESULTADO ==============="
if [ -x "$DC_SRC/doublecmd" ]; then
  echo "BINARIO: $DC_SRC/doublecmd"
  file "$DC_SRC/doublecmd"
  ls -lh "$DC_SRC/doublecmd"
else
  echo "NO SE GENERO EL BINARIO"
  exit 1
fi
