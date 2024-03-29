#!/bin/bash
set -x

libc_git_official="https://cgit.uclibc-ng.org/cgi/cgit/uclibc-ng.git"

while getopts "a:l:t:b:g:" o; do
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
		g)
			libc_git=${OPTARG}
			;;
	esac
done

build_dir=$PWD/build_$arch
buildroot_defconfig=$(cat conf/$arch/buildroot_defconfig)
confdir=$PWD/conf/$arch/

if [ -z "$libc_git" ]; then
	libc_git=$libc_git_official
fi

if [ -f $confdir/get_buildroot.sh ]; then
	$confdir/get_buildroot.sh $buildroot_sha1
else
	git clone git://git.busybox.net/buildroot
	if [ ! -z "$buildroot_sha1" ]; then
		cd buildroot
		git checkout $buildroot_sha1
		cd -
	fi
fi
cd buildroot
buildroot_sha1=$(git rev-parse HEAD) # translate from master to sha1
cd -

git clone $libc_git
cd uclibc-ng
if [ ! -z "$libc_sha1" ]; then
	git checkout $libc_sha1
else
	libc_sha1=$(git rev-parse HEAD)
fi
cd -

git clone https://cgit.uclibc-ng.org/cgi/cgit/uclibc-ng-test.git
cd uclibc-ng-test
if [ ! -z "$libc_test_sha1" ]; then
	git checkout $libc_test_sha1
else
	libc_test_sha1=$(git rev-parse HEAD)
fi
cd -

if [ "$arch" == "aarch64" ]; then
	echo "uClibc-ng SHA1: $libc_sha1" >> $GITHUB_STEP_SUMMARY
	echo "uClibc-ng testsuite SHA1: $libc_test_sha1" >> $GITHUB_STEP_SUMMARY
	echo "Buildroot SHA1: $buildroot_sha1" >> $GITHUB_STEP_SUMMARY
	echo "uClibc-ng git repo: $libc_git" >> $GITHUB_STEP_SUMMARY
fi

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

