# CMake toolchain file for cross compiling x265 for ARM arch
# This feature is only supported as experimental. Use with caution.
# Please report bugs on bitbucket
# Run cmake with: cmake -DCMAKE_TOOLCHAIN_FILE=crosscompile.cmake -G "Unix Makefiles" ../../source && ccmake ../../source

cmake_minimum_required(VERSION 3.7)


set(CMAKE_SYSTEM_NAME Android)
#此处设置Android的API版本
set(CMAKE_ANDROID_API 21)
#此处设置Android的ABI，如armeabi、armeabi-v7a、x86等
set(CMAKE_ANDROID_ARCH_ABI ${ABI})
#此处设置Android的NDK路径
set(CMAKE_ANDROID_NDK ${NDK})

#set(CMAKE_ANDROID_STL_TYPE c++_static)
#set(CMAKE_CXX_FLAGS "-std=c++11 ${CMAKE_CXX_FLAGS}")
#set(CMAKE_CXX_STANDARD 11)
