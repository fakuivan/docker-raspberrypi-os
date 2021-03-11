FROM raspberrypi_os:imported

RUN apt update && \
    apt remove raspberrypi-bootloader raspberrypi-kernel --auto-remove -y && \
    apt upgrade -y --auto-remove

