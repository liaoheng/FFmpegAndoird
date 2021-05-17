#!/bin/sh

# Created by jianxi on 2017/6/4
# https://github.com/mabeijianxi
# mabeijianxi@gmail.com

chmod a+x x264_*.sh

NDK=$1

if [ -z "$NDK" ]; then
  NDK=$HOME/android-ndk
fi


# Build arm v7a
./x264_arm_v7a_build.sh $NDK

# Build arm64 v8a
./x264_arm64_v8a_build.sh $NDK

# Build x86
./x264_x86_build.sh $NDK

# Build x86_64
./x264_x86_64_build.sh $NDK
