#!/bin/sh

# Created by jianxi on 2017/6/4
# https://github.com/mabeijianxi
# mabeijianxi@gmail.com

CPU=x86
basepath=$(cd `dirname $0`; pwd)
NDK=$1
if [ ! -n $NDK ]; then
  echo "NDK is null"
  exit
fi
FDK_AAC=$2
if [ ! -n $FDK_AAC ]; then
  echo "FDK_AAC is null"
  exit
fi
X264=$3
if [ ! -n $X264 ]; then
  echo "X264 is null"
  exit
fi
X265=$4
if [ ! -n $X265 ]; then
  echo "X265 is null"
  exit
fi

PREFIX=$basepath/$CPU

export TMPDIR=$basepath/temp/$CPU
mkdir -p $TMPDIR

SYSROOT=$NDK/platforms/android-21/arch-x86
TOOLCHAIN=$NDK/toolchains/x86-4.9/prebuilt/linux-x86_64
CROSS_PREFIX=${TOOLCHAIN}/bin/i686-linux-android-

FDK_PKGCONFIG=$basepath/../../$FDK_AAC/build/android/$CPU/lib/pkgconfig

X264_PKGCONFIG=$basepath/../../$X264/build/android/$CPU/lib/pkgconfig

X265_PKGCONFIG=$basepath/../../$X265/build/android/$CPU/lib/pkgconfig


FF_EXTRA_CFLAGS="-O3 -DANDROID -Dipv6mr_interface=ipv6mr_ifindex -fasm -Wno-psabi -fno-short-enums -fno-strict-aliasing -fomit-frame-pointer -march=k8 "
FF_CFLAGS="-O3 -Wall -pipe \
-ffast-math \
-fstrict-aliasing -Werror=strict-aliasing \
-Wno-psabi -Wa,--noexecstack \
-DANDROID  "

export PKG_CONFIG_PATH=$FDK_PKGCONFIG:$X264_PKGCONFIG:$X265_PKGCONFIG

cd ../../

./configure \
--pkg-config=pkg-config \
--prefix=$PREFIX \
--enable-cross-compile \
--disable-runtime-cpudetect \
--disable-asm \
--arch=x86 \
--target-os=android \
--cc=${CROSS_PREFIX}gcc \
--cross-prefix=$CROSS_PREFIX \
--disable-stripping \
--nm=${CROSS_PREFIX}nm \
--sysroot=$SYSROOT \
--enable-gpl \
--enable-shared \
--disable-static \
--enable-version3 \
--enable-pthreads \
--enable-small \
--disable-vda \
--disable-iconv \
--enable-encoders \
--enable-neon \
--enable-yasm \
--enable-libx264 \
--enable-libx265 \
--enable-libfdk_aac \
--enable-encoder=libx264 \
--enable-encoder=libx265 \
--enable-encoder=libfdk_aac \
--enable-encoder=mjpeg \
--enable-encoder=png \
--enable-nonfree \
--enable-muxers \
--enable-decoders \
--enable-demuxers \
--enable-parsers \
--enable-protocols \
--enable-zlib \
--enable-avfilter \
--disable-outdevs \
--disable-ffprobe \
--disable-ffplay \
--disable-ffmpeg \
--disable-ffserver \
--disable-debug \
--disable-ffprobe \
--disable-ffplay \
--disable-ffmpeg \
--disable-postproc \
--disable-avdevice \
--disable-symver \
--disable-stripping \
--extra-cflags="$FF_EXTRA_CFLAGS  $FF_CFLAGS" \
--extra-ldflags="  "

make clean
make -j4
make install

cd $basepath

cp $FDK_PKGCONFIG/../libfdk-aac.so $PREFIX/lib
cp $X265_PKGCONFIG/../libx265.so $PREFIX/lib



