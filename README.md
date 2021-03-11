# Raspberry Pi OS Image builder

Pulls the root filesystem in archive form from the official rpi page,
verifies checksums, imports it into a docker or podman image and
removes _some_ unnecesary packages. To download the root filesystem and
create the image do:
```bash
(source build_image.sh; download_rootfs | import_rootfs docker)
```

if working with podman then:
```bash
(source build_image.sh; download_rootfs | import_rootfs podman)
```

if you prefer to save the rootfs archive in the disk:
```bash
(source build_image.sh;
    download_rootfs > rootfs.tar.xz &&
    cat rootfs.tar.xz | import_rootfs podman)
```

if you need a different Dockerfile to make changes, pass the file name
as the second argument to ``import_rootfs``, like so:
```bash
(source build_image.sh;
    download_rootfs > rootfs.tar.xz &&
    cat rootfs.tar.xz | import_rootfs podman my_dockerfile)
```

However, it's recommended to build on top of this image using the ``FROM``
directive. This is should only be used to slim down the image further.
