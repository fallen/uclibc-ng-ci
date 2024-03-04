#!/bin/bash
set -x

arch=$1
ci_dir=$PWD
build_dir=$PWD/build_$arch
QEMU=$(cat conf/$arch/qemu)
QEMU_OPTS=$(cat conf/$arch/qemu_opts)
QEMU_PATH=$(cat conf/$arch/qemu_path)
KERNEL=$(cat conf/$arch/kernel)
LINUX_CMDLINE=$(cat conf/$arch/linux_cmdline)

if [ -f conf/$arch/get_qemu.sh ]; then
	conf/$arch/get_qemu.sh
fi

if [ ! -z "${QEMU_PATH}" ];
then
	QEMU=$(realpath ${QEMU_PATH}/${QEMU})
fi

mkdir -p $HOME/dl
export BR2_DL_DIR=$HOME/dl
cd $build_dir
rm -f /tmp/guest.in /tmp/guest.out
mkfifo /tmp/guest.in /tmp/guest.out
QEMU_AUDIO_DRV=none timeout -k 46m 45m $QEMU $QEMU_OPTS -kernel images/$KERNEL -append "$LINUX_CMDLINE" -serial pipe:/tmp/guest -monitor 'telnet:127.0.0.1:55555,server,nowait' &
python3 $ci_dir/bin/qemucomm.py /tmp/guest junit_report.xml
(echo "quit" | nc localhost 55555) || true
wait
