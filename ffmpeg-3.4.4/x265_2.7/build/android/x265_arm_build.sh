#!/bin/sh

# Created by jianxi on 2017/6/4
# https://github.com/mabeijianxi
# mabeijianxi@gmail.com

CPU=armeabi
NDK=$1

if [ -z "$NDK" ]; then
  echo "NDK is null"
  exit
fi

basepath=$(cd `dirname $0`; pwd)

TMPDIR=$basepath/temp/$CPU

cmake -E make_directory $TMPDIR

cd $TMPDIR

cmake -DNDK=$NDK -DABI=$CPU -DCMAKE_TOOLCHAIN_FILE=$basepath/crosscompile.cmake -G "Unix Makefiles" $basepath/../../source && ccmake $basepath/../../source -DCMAKE_INSTALL_PREFIX=$basepath/$CPU

$ADDITIONAL_CONFIGURE_FLAG
make clean
make -j4
make install

cd $basepath
