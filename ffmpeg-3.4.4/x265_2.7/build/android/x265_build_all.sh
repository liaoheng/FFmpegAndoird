#!/bin/sh

# Created by jianxi on 2017/6/4
# https://github.com/mabeijianxi
# mabeijianxi@gmail.com

chmod a+x x265_*.sh

NDK=$1

if [ -z "$NDK" ]; then
  NDK=$HOME/android-ndk
fi

# Build armeabi
#./x265_arm_build.sh $NDK

# Build arm v7a
./x265_arm_v7a_build.sh $NDK

# Build arm64 v8a
#./x265_arm64_v8a_build.sh $NDK

# Build mips
#./x264_mips_build.sh

# Build x86
#./x264_x86_build.sh

# Build x86_64
#./x264_x86_64_build.sh
