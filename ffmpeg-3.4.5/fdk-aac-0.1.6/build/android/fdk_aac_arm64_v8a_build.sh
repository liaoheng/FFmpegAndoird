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
CROSS_PREFIX=${TOOLCHAIN}/bin/aarch64-linux-android-

PREFIX=$basepath/$CPU

export TMPDIR=$basepath/temp/$CPU
mkdir -p $TMPDIR

CFLAGS=" "

FLAGS="--enable-static  --host=aarch64-linux --target=android"

export CXX="${CROSS_PREFIX}g++ --sysroot=${SYSROOT}"

export LDFLAGS=" -L$SYSROOT/usr/lib  $CFLAGS "

export CXXFLAGS=$CFLAGS

export CFLAGS=$CFLAGS

export CC="${CROSS_PREFIX}gcc --sysroot=${SYSROOT}"

export AR="${CROSS_PREFIX}ar"

export LD="${CROSS_PREFIX}ld"

export AS="${CROSS_PREFIX}gcc"

cd ../../

./configure $FLAGS \
--enable-pic \
--enable-strip \
--prefix=$PREFIX

make clean
make -j4
make install

cd $basepath