# Created by jianxi on 2017/6/4
# https://github.com/mabeijianxi
# mabeijianxi@gmail.com

CPU=x86
NDK=$1

if [ -z "$NDK" ]; then
  echo "NDK is null"
  exit
fi

basepath=$(cd `dirname $0`; pwd)

SYSROOT=$NDK/platforms/android-21/arch-x86
TOOLCHAIN=$NDK/toolchains/x86-4.9/prebuilt/linux-x86_64
CROSS_PREFIX=$TOOLCHAIN/bin/i686-linux-android-

PREFIX=$basepath/$CPU

export TMPDIR=$basepath/temp/$CPU
mkdir -p $TMPDIR

FLAGS="--enable-static  --host=i686-linux --target=android"

cd ../../

./configure $FLAGS \
--prefix=$PREFIX \
--disable-shared \
--enable-pic \
--enable-strip \
--cross-prefix=$CROSS_PREFIX \
--sysroot=$SYSROOT \
--extra-cflags="-Os -fpic" \
--extra-ldflags="" \

make clean
make -j4
make install

cd $basepath