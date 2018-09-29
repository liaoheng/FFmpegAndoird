#!/bin/sh

# Created by jianxi on 2017/6/4
# https://github.com/mabeijianxi
# mabeijianxi@gmail.com

CPU=arm
NDK=$1

if [ -z "$NDK" ]; then
  echo "NDK is null"
  exit
fi

basepath=$(cd `dirname $0`; pwd)

SYSROOT=$NDK/platforms/android-21/arch-arm
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64
CROSS_PREFIX=$TOOLCHAIN/bin/arm-linux-androideabi-

PREFIX=$basepath/$CPU

export TMPDIR=$basepath/temp/$CPU
mkdir -p $TMPDIR

cd ../../

./configure \
--prefix=$PREFIX \
--disable-shared \
--enable-static \
--disable-asm \
--enable-pic \
--enable-strip \
--host=arm-linux-androideabi \
--cross-prefix=$CROSS_PREFIX \
--sysroot=$SYSROOT \
--extra-cflags="-Os -fpic" \
--extra-ldflags="" \

$ADDITIONAL_CONFIGURE_FLAG
make clean
make -j4
make install

cd $basepath
