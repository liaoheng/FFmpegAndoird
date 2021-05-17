# Created by jianxi on 2017/6/4
# https://github.com/mabeijianxi
# mabeijianxi@gmail.com

CPU=x86_64
NDK=$1

if [ -z "$NDK" ]; then
  echo "NDK is null"
  exit
fi

basepath=$(cd `dirname $0`; pwd)

SYSROOT=$NDK/platforms/android-21/arch-x86_64
TOOLCHAIN=$NDK/toolchains/x86_64-4.9/prebuilt/linux-x86_64
CROSS_PREFIX=${TOOLCHAIN}/bin/x86_64-linux-android-

PREFIX=$basepath/$CPU

export TMPDIR=$basepath/temp/$CPU
mkdir -p $TMPDIR

CFLAGS=" "

FLAGS="--enable-static  --host=x86_64-linux --target=android"

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