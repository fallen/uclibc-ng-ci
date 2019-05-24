#!/bin/bash
confdir=$WORKSPACE/uclibc-ng-ci/conf/$arch/
make linux-extract
cd build/linux-[0-9]*
patch -p1 < $confdir/0001-increase-ram-size.patch
