#!/bin/bash
set -x

mkdir qemu_install_dir
QEMU_INSTALL_DIR=$(realpath qemu_install_dir)

git clone https://github.com/kalray/qemu-builder.git
cd qemu-builder
git submodule update --init
make -j$(($(nproc) + 1)) PREFIX=${QEMU_INSTALL_DIR}
cd -
