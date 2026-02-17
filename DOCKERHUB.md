# Docker container for Krokiet
[![Release](https://img.shields.io/github/release/jlesage/docker-krokiet.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-krokiet/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/krokiet/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/krokiet/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/krokiet?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/krokiet)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/krokiet?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/krokiet)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-krokiet/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-krokiet/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-krokiet)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This is a Docker container for [Krokiet](https://github.com/qarmin/czkawka).

The graphical user interface (GUI) of the application can be accessed through a
modern web browser, requiring no installation or configuration on the client

> This Docker container is entirely unofficial and not made by the creators of
> Krokiet.

---

[![Krokiet logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/krokiet-icon.png&w=110)](https://github.com/qarmin/czkawka)[![Krokiet](https://images.placeholders.dev/?width=224&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=Krokiet&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://github.com/qarmin/czkawka)

Krokiet is the new generation GUI frontend for Cakawka, written in Rust,
simple, fast and easy to use app to remove unnecessary files from your
computer.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

Launch the Krokiet docker container with the following command:
```shell
docker run -d \
    --name=krokiet \
    -p 5800:5800 \
    -v /docker/appdata/krokiet:/config:rw \
    -v /home/user:/storage:rw \
    jlesage/krokiet
```

Where:

  - `/docker/appdata/krokiet`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/home/user`: Contains files from the host that need to be accessible to the application.

Access the Krokiet GUI by browsing to `http://your-host-ip:5800`.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-krokiet.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/jlesage/docker-krokiet/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
