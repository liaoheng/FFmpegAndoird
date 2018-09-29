#!/bin/sh

# Created by jianxi on 2017/6/4
# https://github.com/mabeijianxi
# mabeijianxi@gmail.com

CPU=arm64-v8a
NDK=$1

if [ -z "$NDK" ]; then
  echo "NDK is null"
  exit
fi

basepath=$(cd `dirname $0`; pwd)

SYSROOT=$NDK/platforms/android-21/arch-arm64
TOOLCHAIN=$NDK/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64
CROSS_PREFIX=$TOOLCHAIN/bin/aarch64-linux-android-

PREFIX=$basepath/$CPU

export TMPDIR=$basepath/temp/$CPU
mkdir -p $TMPDIR

cd ../../

./configure \
--prefix=$PREFIX \
--disable-shared \
--enable-static \
--enable-pic \
--enable-strip \
--host=aarch64-linux \
--cross-prefix=$CROSS_PREFIX \
--sysroot=$SYSROOT \
--extra-cflags="-Os -fpic" \
--extra-ldflags="" \

$ADDITIONAL_CONFIGURE_FLAG
make clean
make -j4
make install

cd $basepath
