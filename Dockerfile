#
# krokiet Dockerfile
#
# https://github.com/jlesage/docker-krokiet
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG KROKIET_VERSION=11.0.0
ARG LIBHEIF_VERSION=1.21.2

# Define software download URLs.
ARG KROKIET_URL=https://github.com/qarmin/czkawka/archive/${KROKIET_VERSION}.tar.gz
ARG LIBHEIF_URL=https://github.com/strukturag/libheif/releases/download/v${LIBHEIF_VERSION}/libheif-${LIBHEIF_VERSION}.tar.gz

# Get Dockerfile cross-compilation helpers.
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

# Build Krokiet.
FROM --platform=$BUILDPLATFORM alpine:3.20 AS krokiet
ARG TARGETPLATFORM
ARG KROKIET_URL
ARG LIBHEIF_URL
COPY --from=xx / /
COPY src/krokiet /build
RUN /build/build.sh "$KROKIET_URL" "$LIBHEIF_URL"
RUN xx-verify \
    /tmp/krokiet-install/czkawka_cli \
    /tmp/krokiet-install/krokiet

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.20-v4.11.1

# Define working directory.
WORKDIR /tmp

ARG KROKIET_VERSION
ARG DOCKER_IMAGE_VERSION

# Install dependencies.
RUN add-pkg \
        alsa-lib \
        ffmpeg \
        ffplay \
        libde265 \
        libxkbcommon-x11 \
        # For the file dialog support (via XDG Desktop Portal backend).
        # https://lib.rs/crates/rfd
        dbus \
        xdg-desktop-portal-gtk \
        # For opening folders.
        pcmanfm \
        # Icons for the file picker and file manager.
        adwaita-icon-theme \
        # A font is needed.
        font-dejavu \
        && \
    true

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/krokiet-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY --from=krokiet /tmp/krokiet-install/czkawka_cli /usr/bin/
COPY --from=krokiet /tmp/krokiet-install/krokiet /usr/bin/
COPY --from=krokiet /tmp/libheif-install/usr/lib /usr/lib
COPY --from=krokiet /tmp/libheif-install/usr/bin/heif-convert /usr/bin/
COPY --from=krokiet /tmp/libheif-install/usr/bin/heif-dec /usr/bin/

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "Krokiet" && \
    set-cont-env APP_VERSION "$KROKIET_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Set public environment variables.
ENV \
    KROKIET_GUI_KROKIET=0

# Define mountable directories.
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="krokiet" \
      org.label-schema.description="Docker container for Krokiet" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-krokiet" \
      org.label-schema.schema-version="1.0"
