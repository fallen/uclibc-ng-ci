#!/bin/bash
set -x

arch=$1
git clone git://git.busybox.net/buildroot
git clone https://cgit.uclibc-ng.org/cgi/cgit/uclibc-ng.git
git clone https://cgit.uclibc-ng.org/cgi/cgit/uclibc-ng-test.git
build_dir=$PWD/build_$arch
buildroot_defconfig=$(cat conf/$arch/buildroot_defconfig)
confdir=$PWD/conf/$arch/

mkdir -p $HOME/dl
export BR2_DL_DIR=$HOME/dl
cd buildroot
make O=$build_dir $buildroot_defconfig
cd $build_dir
echo "UCLIBC_OVERRIDE_SRCDIR = $PWD/../uclibc-ng" > local.mk
echo "UCLIBC_NG_TEST_OVERRIDE_SRCDIR = $PWD/../uclibc-ng-test" >> local.mk
sed -i -e "s/# BR2_PACKAGE_UCLIBC_NG_TEST is not set/BR2_PACKAGE_UCLIBC_NG_TEST=y/g" .config
sed -i -e '/BR2_TOOLCHAIN_BUILDROOT_GLIBC/d' .config
sed -i -e '/BR2_TOOLCHAIN_BUILDROOT_MUSL/d' .config
sed -i -e '/BR2_TOOLCHAIN_BUILDROOT_UCLIBC/d' .config
echo 'BR2_TOOLCHAIN_BUILDROOT_UCLIBC=y' >> .config
sed -i -e "s/BR2_JLEVEL=0/BR2_JLEVEL=2/g" .config

make olddefconfig

if [ -f $confdir/pre_build.sh ]; then
	$confdir/pre_build.sh
fi

make

if [ -f $confdir/post_build.sh ]; then
	$confdir/post_build.sh
fi

