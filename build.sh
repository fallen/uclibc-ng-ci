#!/bin/bash
set -x

while getopts "a:l:t:b:" o; do
	case "${o}" in
		a)
			arch=${OPTARG}
			;;
		l)
			libc_sha1=${OPTARG}
			;;
		t)
			libc_test_sha1=${OPTARG}
			;;
		b)
			buildroot_sha1=${OPTARG}
			;;
	esac
done

git clone git://git.busybox.net/buildroot
if [ ! -z "$buildroot_sha1" ]; then
	cd buildroot; git checkout $buildroot_sha1; cd -
	echo "Buildroot SHA1: $buildroot_sha1" >> $GITHUB_STEP_SUMMARY
fi
git clone https://cgit.uclibc-ng.org/cgi/cgit/uclibc-ng.git
if [ ! -z "$libc_sha1" ]; then
	cd uclibc-ng; git checkout $libc_sha1; cd -
	echo "uClibc-ng SHA1: $libc_sha1" >> $GITHUB_STEP_SUMMARY
fi
git clone https://cgit.uclibc-ng.org/cgi/cgit/uclibc-ng-test.git
if [ ! -z "$libc_test_sha1" ]; then
	cd uclibc-ng-test; git checkout $libc_test_sha1; cd -
	echo "uClibc-ng testsuite SHA1: $libc_test_sha1" >> $GITHUB_STEP_SUMMARY
fi
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

