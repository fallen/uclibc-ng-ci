build_dir=$WORKSPACE/build_$arch
QEMU=$(cat uclibc-ng-ci/conf/$arch/qemu)
QEMU_OPTS=$(cat uclibc-ng-ci/conf/$arch/qemu_opts)
KERNEL=$(cat uclibc-ng-ci/conf/$arch/kernel)
LINUX_CMDLINE=$(cat uclibc-ng-ci/conf/$arch/linux_cmdline)

mkdir -p $HOME/dl
export BR2_DL_DIR=$HOME/dl
cd $build_dir
rm -f /tmp/guest.in /tmp/guest.out
mkfifo /tmp/guest.in /tmp/guest.out
QEMU_AUDIO_DRV=none $QEMU $QEMU_OPTS -kernel images/$KERNEL -append "$LINUX_CMDLINE" -serial pipe:/tmp/guest -monitor 'telnet:127.0.0.1:55555,server,nowait' &
python3 $WORKSPACE/uclibc-ng-ci/bin/qemucomm.py /tmp/guest $WORKSPACE/junit_report.xml
(echo "quit" | nc localhost 55555) || true
wait
