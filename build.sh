git clone git://git.busybox.net/buildroot
git clone https://github.com/fallen/uclibc-ng-ci.git
build_dir=$PWD/build_$arch
buildroot_defconfig=$(cat uclibc-ng-ci/conf/$arch/buildroot_defconfig)
confdir=$PWD/uclibc-ng-ci/conf/$arch/

mkdir -p $HOME/dl
export BR2_DL_DIR=$HOME/dl
cd buildroot
sed -i -e "s@UCLIBC_SITE = .*@UCLIBC_SITE = git://uclibc-ng.org/git/uclibc-ng@g" package/uclibc/uclibc.mk
sed -i -e "s/UCLIBC_VERSION = .*/UCLIBC_VERSION = ${GIT_COMMIT}/g" package/uclibc/uclibc.mk
sed -i -e "/UCLIBC_SOURCE/d" package/uclibc/uclibc.mk
rm -f package/uclibc/*.patch package/uclibc/uclibc.hash
make O=$build_dir $buildroot_defconfig
cd $build_dir
sed -i -e "s/# BR2_PACKAGE_UCLIBC_NG_TEST is not set/BR2_PACKAGE_UCLIBC_NG_TEST=y/g" .config
sed -i -e "s/BR2_JLEVEL=0/BR2_JLEVEL=2/g" .config

if [ -f $confdir/pre_build.sh ]; then
	$confdir/pre_build.sh
fi

make

if [ -f $confdir/post_build.sh ]; then
	$confdir/post_build.sh
fi

