#!/bin/bash
set -x

SHA1=${1:-coolidge-for-upstream-v2}

git clone https://github.com/kalray/buildroot
cd buildroot
git checkout ${SHA1}
cd -
