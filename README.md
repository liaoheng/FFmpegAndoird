# FFmpegAndoird

1. ubuntu 18.04.1, ndk r13b, cmake 3.10, FFmpeg 3.4.4, libx265-2.7, libfdk-aac-0.1.6, x264-snapshot-20180927-2245

2. 安装依赖库

   ```bash
   sudo apt-get install autoconf automake build-essential cmake cmake-curses-gui git-core libass-dev libfreetype6-dev libtool libvorbis-dev pkg-config texinfo wget zlib1g-dev mercurial yasm nasm
   ```

3. 对libx265-2.7 进行修改
   > 进入 在 libx265 目录下找到 source 目录并打开里面的CMakeLists.txt文件：
   >
   > 删除或者注释：`list(APPEND PLATFORM_LIBS pthread)`

4. 对 libfdk-aac-0.1.6 进行修改
   > 进入 在 libfdk-aac 目录下找到 m4 目录并打开里面的 libtool.m4 文件：
   > 全局搜索 so.1,替换为 so
   > 全局搜索 `$versuffix` ,替换为空字符，也就是删除它
   > 全局搜索 `$major` ，,替换为空字符，也就是删除它

5. 在[https://github.com/mabeijianxi/FFmpeg4Android](https://github.com/mabeijianxi/FFmpeg4Android) 脚本基础上添加了x265并做了一些修改。

6. 谨慎调整各库的版本，以知FFmpeg4是不能编译能过。
