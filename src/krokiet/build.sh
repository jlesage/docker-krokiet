#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

export CC=xx-clang
export CXX=xx-clang++

export RUSTFLAGS="-C link-args=-Wl,-zstack-size="8388608

KROKIET_FEATURES="container_trash,heif,libraw"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() {
    echo ">>> $*"
}

KROKIET_URL="$1"
LIBHEIF_URL="$2"

if [ -z "$KROKIET_URL" ]; then
    log "ERROR: Krokiet URL missing."
    exit 1
fi

if [ -z "$LIBHEIF_URL" ]; then
    log "ERROR: libheif URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    bash \
    curl \
    git \
    clang \
    cmake \
    make \
    g++ \
    lld \
    patch \
    pkgconf \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    libstdc++-dev \

# For libheif.
xx-apk --no-cache --no-scripts add \
    libde265-dev \
    x265-dev \
    aom-dev \
    libjpeg-turbo-dev \
    libpng-dev \

# Install Rust.
# NOTE: Krokiet often requires a recent version of Rust that is not available
#       yet in Alpine repository.
USE_RUST_FROM_ALPINE_REPO=false
if $USE_RUST_FROM_ALPINE_REPO; then
    apk --no-cache add \
        rust \
        cargo
else
    apk --no-cache add \
        gcc \
        musl-dev
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
    source /root/.cargo/env

    # NOTE: When not installing Rust from the Alpine repository, we must compile
    #       with `RUSTFLAGS="-C target-feature=-crt-static"` to avoid crash
    #       during GTK initialization.
    #       See https://github.com/qarmin/czkawka/issues/416.
    export RUSTFLAGS="$RUSTFLAGS -C target-feature=-crt-static"
fi

# Fix the xx-cargo setup. See https://github.com/tonistiigi/xx/issues/104.
# When building linux/arm/v6, there is a mismatch in triples:
#   - cargo: arm-unknown-linux-musleabi
#   - xx-info: armv6-alpine-linux-musleabihf.
if xx-info is-cross; then
    xx-cargo --setup-target-triple
    if [ ! -e "/$(xx-cargo --print-target-triple)" ]; then
        ln -s "$(xx-info)" "/$(xx-cargo --print-target-triple)"
    fi

    for d in $(find $(xx-info sysroot) -name "$(xx-info)" -type d); do
        cargo_d="$(dirname "$d")/$(xx-cargo --print-target-triple)"
        [ ! -e "$cargo_d" ] || continue

        log "xx-cargo setup fix: creating symlink '$cargo_d', pointing '$(xx-info)'."
        ln -s "$(xx-info)" "$cargo_d"
    done
fi

#
# Download sources.
#

log "Downloading Krokiet..."
mkdir /tmp/krokiet
curl -# -L -f ${KROKIET_URL} | tar xz --strip 1 -C /tmp/krokiet

log "Downloading libheif..."
mkdir /tmp/libheif
curl -# -L -f ${LIBHEIF_URL} | tar xz --strip 1 -C /tmp/libheif

#
# Compile libheif
#

log "Configuring libheif..."
(
    export CPPFLAGS="-O2"
    export CXXFLAGS="-O2"
    mkdir /tmp/libheif/build && \
    cd /tmp/libheif/build && cmake \
        $(xx-clang --print-cmake-defines) \
        -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=None \
        -DCMAKE_SKIP_INSTALL_RPATH=ON \
        -DWITH_EXAMPLES=ON \
        -DWITH_GDK_PIXBUF=OFF \
        -DBUILD_TESTING=OFF \
        ..
)

log "Compiling libheif..."
make -C /tmp/libheif/build -j$(nproc)

log "Installing libheif..."
make DESTDIR=$(xx-info sysroot) -C /tmp/libheif/build install
find $(xx-info sysroot)usr/lib -name "*.la" -delete

make DESTDIR=/tmp/libheif-install -C /tmp/libheif/build install
find /tmp/libheif-install -name "*.la" -delete
find /tmp/libheif-install -name "*.pc" -delete
rm -r /tmp/libheif-install/usr/lib/cmake
rm -r /tmp/libheif-install/usr/include

#
# Compile Krokiet.
#

# Create cargo profile.
# https://github.com/johnthagen/min-sized-rust
echo "" >> /tmp/krokiet/.cargo/config.toml
echo "[profile.release]" >> /tmp/krokiet/.cargo/config.toml
echo "strip = true" >> /tmp/krokiet/.cargo/config.toml
echo "debug = false" >> /tmp/krokiet/.cargo/config.toml
echo "overflow-checks = true" >> /tmp/krokiet/.cargo/config.toml
echo "opt-level = 's'" >> /tmp/krokiet/.cargo/config.toml
echo "lto = 'thin'" >> /tmp/krokiet/.cargo/config.toml
echo "panic = 'unwind'" >> /tmp/krokiet/.cargo/config.toml
echo "codegen-units = 1" >> /tmp/krokiet/.cargo/config.toml

log "Patching Krokiet..."
PATCHES="
    excluded-dir-warning-fix.patch
    container-trash.patch
    dark-theme.patch
    disable-trash-by-default.patch
"
for PATCH in $PATCHES; do
    log "Applying $PATCH..."
    patch  -p1 -d /tmp/krokiet < "$SCRIPT_DIR"/"$PATCH"
done

log "Compiling Czkawka CLI..."
(
    cd /tmp/krokiet
    # shared-mime-info.pc is under /usr/share/pkgconfig.
    PKG_CONFIG_PATH=/$(xx-info)/usr/share/pkgconfig \
    xx-cargo build --release --bin czkawka_cli --features "$KROKIET_FEATURES"
)

log "Compiling Krokiet GUI..."
(
    export SLINT_STYLE=fluent
    cd /tmp/krokiet
    # shared-mime-info.pc is under /usr/share/pkgconfig.
    PKG_CONFIG_PATH=/$(xx-info)/usr/share/pkgconfig \
    xx-cargo build --release --bin krokiet --no-default-features --features "winit_software,$KROKIET_FEATURES"
)

log "Installing Krokiet..."
mkdir /tmp/krokiet-install
find /tmp/krokiet/target -type f
cp -v /tmp/krokiet/target/*/release/czkawka_cli /tmp/krokiet-install/
cp -v /tmp/krokiet/target/*/release/krokiet /tmp/krokiet-install/
