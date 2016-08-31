#
 # Custom build script
 #
 # This software is licensed under the terms of the GNU General Public
 # License version 2, as published by the Free Software Foundation, and
 # may be copied, distributed, and modified under those terms.
 #
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # Please maintain this if you use this script or any part of it
 #

KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/arch/arm64/boot/Image
DTBTOOL=$KERNEL_DIR/tools/dtbToolCM
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
# Modify the following variable if you want to build
export CROSS_COMPILE="/home/nachiket/android/tomato/toolchains/Linaro/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
export LD_LIBRARY_PATH=/home/nachiket/android/tomato/toolchains/Linaro/aarch64-linux-android-4.9/lib/
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="nachiket"
export KBUILD_BUILD_HOST="reactor"
STRIP="/home/nachiket/android/tomato/toolchains/Linaro/aarch64-linux-android-4.9/bin/aarch64-linux-android-strip"
MODULES_DIR=$KERNEL_DIR/zipping/common
OUT_DIR=$KERNEL_DIR/zipping/tomato
REACTOR_VERSION="alpha-1"
compile_kernel ()
{
rm -rf $OUT_DIR/*.zip
rm -rf $OUT_DIR/modules/*
rm -rf $OUT_DIR/tools/zImage
rm -rf $OUT_DIR/*.img

echo -e "**********************************************************************************************"
echo "                    "
echo "                            Compiling BlackReactor Kernel                    "
echo "                    "
echo -e "**********************************************************************************************"
make cyanogenmod_tomato-64_defconfig
make Image -j64
make dtbs -j64
make modules -j64
if ! [ -a $KERN_IMG ];
then
echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
exit 1
fi
$DTBTOOL -2 -o $KERNEL_DIR/arch/arm64/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
strip_modules
}

strip_modules ()
{
echo "Copying modules"
rm $MODULES_DIR/*
find . -name '*.ko' -exec cp {} $MODULES_DIR/ \;
cd $MODULES_DIR
echo "Stripping modules for size"
$STRIP --strip-unneeded *.ko
zip -9 modules *
cd $KERNEL_DIR
}

packing() {

cp $KERNEL_DIR/arch/arm64/boot/Image  $OUT_DIR/zImage
cp $MODULES_DIR/*.ko $OUT_DIR/modules/
cd $OUT_DIR
zip -r BlackReactor-tomato-$REACTOR_VERSION-$(date +"%Y%m%d")-$(date +"%H%M%S").zip *
}

compile_kernel
packing

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
echo -e "$red zImage size (bytes): $(stat -c%s $KERN_IMG) $nocol"
