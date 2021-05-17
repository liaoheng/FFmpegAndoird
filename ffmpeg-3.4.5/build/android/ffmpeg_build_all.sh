#!/bin/sh

# Created by jianxi on 2017/6/4
# https://github.com/mabeijianxi
# mabeijianxi@gmail.com

FDK_AAC=fdk-aac-0.1.6
X264=x264
X265=x265_2.7
NDK=$HOME/android-ndk
basepath=$(cd `dirname $0`; pwd)

chmod a+x ffmpeg_*.sh

#cd $basepath/../../$X265/build/android
#chmod a+x x265_build_all.sh
#./x265_build_all.sh $NDK
#cd $basepath

#cd $basepath/../../$X264/build/android
#chmod a+x x264_build_all.sh
#./x264_build_all.sh $NDK
#cd $basepath

#cd $basepath/../../$FDK_AAC/build/android
#chmod a+x fdk_aac_build_all.sh
#./fdk_aac_build_all.sh $NDK
#cd $basepath


# Build arm  v7a
./ffmpeg_arm_v7a_build.sh $NDK $FDK_AAC $X264 $X265

# Build arm64 v8a
./ffmpeg_arm64_v8a_build.sh $NDK $FDK_AAC $X264 $X265

# Build x86
./ffmpeg_x86_build.sh $NDK $FDK_AAC $X264 $X265

# Build x86_64
./ffmpeg_x86_64_build.sh $NDK $FDK_AAC $X264 $X265
