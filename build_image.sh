#!/usr/bin/env bash

error () {
    echo "$@" 1>&2
}

# Downloads the root filesystem tar archive for armhf provided by the rpi org,
# sadly a similar facility is not provided for the arm64 version
download_rootfs () {
    local rootfs_link="https://downloads.raspberrypi.org/raspios_lite_armhf/root.tar.xz"
    local partitions_link="https://downloads.raspberrypi.org/raspios_lite_armhf/partitions.json"
    local expected_checksum partitions checksum_file checksum
    if ! partitions="$(curl "$partitions_link")"; then
        error "Failed to fetch partitions schema"
        return 1
    fi
    if ! expected_checksum="$(jq -r '.partitions[] | select(.label == "root") | .sha256sum' <(echo "$partitions"))"; then
        error "Failed to fetch checksum from paritions schema"
        return 1
    fi
    checksum_file="$(mktemp)"
    wget -qO- "$rootfs_link" | tee >(sha256sum | cut -d' ' -f1 > "$checksum_file")
    if ! (exit ${PIPESTATUS[0]}); then
        error "Failed to download rootfs"
        return 1;
    fi
    if ! checksum=$(cat "$checksum_file") || ! [[ "$checksum" == "$expected_checksum" ]]; then
        error "Expected checksum ${expected_checksum@Q}, got ${checksum@Q}"
        return 1;
    fi
}

import_rootfs () {
    local docker_like="${1:-docker}"
    local dockerfile="${2:-./Dockerfile}"
    local os_version_id os_version_codename
    if ! "$docker_like" import - raspberrypi_os:imported; then
        error "Failed to import tarball from stdin"
        return 1
    fi 
    if ! "$docker_like" build -f "$dockerfile" -t raspberrypi_os:latest .; then
        error "Failed to apply changes to imported image"
        return 1
    fi
    if ! os_version_id="$("$docker_like" run raspberrypi_os:latest bash -c 'source /etc/os-release && echo "$VERSION_ID"')"; then
        error "Failed to retrieve version id from image"
        return 1
    fi
    if ! "$docker_like" tag raspberrypi_os:latest raspberrypi_os:"$os_version_id"; then
        error "Failed to tag image with version id"
        return 1
    fi
    if ! os_version_codename="$("$docker_like" run raspberrypi_os:latest bash -c 'source /etc/os-release && echo "$VERSION_CODENAME"')"; then
        error "Failed to retrieve id from image"
        return 1
    fi
    if ! "$docker_like" tag raspberrypi_os:latest raspberrypi_os:"$os_version_codename"; then
        error "Failed to tag image with id"
        return 1
    fi
}
