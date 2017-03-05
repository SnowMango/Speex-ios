#! /bin/bash

#Created by 郑丰 on 2017/2/22.
#Copyright © 2017年 zhengfeng. All rights reserved.

cd `dirname $0`
set -e

#自定义选项
MINIOSVERSION="8.0"
SPEEX_DIR="speex-1.2.0"
#Build
BUILD_ROOT="`pwd`/build"
mkdir -p ${BUILD_ROOT};
ALL_ARCHS_IOS8_SDK="armv7 arm64 i386 x86_64"
ARCHS=${ALL_ARCHS_IOS8_SDK}

DEVELOPER=`xcode-select -print-path`
XCRUN_OSVERSION="-miphoneos-version-min=${MINIOSVERSION}"
#Config
SPEEX_COMMON_CONFIG=
SPEEX_COMMON_CONFIG="${SPEEX_COMMON_CONFIG} --enable-float-approx"
SPEEX_COMMON_CONFIG="${SPEEX_COMMON_CONFIG} --disable-shared"
SPEEX_COMMON_CONFIG="${SPEEX_COMMON_CONFIG} --enable-static"
SPEEX_COMMON_CONFIG="${SPEEX_COMMON_CONFIG} --with-pic"
SPEEX_COMMON_CONFIG="${SPEEX_COMMON_CONFIG} --disable-doc"
#Method
echo_check() {
    echo "===================="
    echo "[*] check xcode version"
    echo "====$ARCHS===="
    echo "github:https://github.com/SnowMango"
    echo "===================="
}

build_arch()
{
    ARCH=$1
    if [ -z "$ARCH" ]; then
        echo "You must specific an architecture 'armv7, armv7s, arm64, i386, x86_64, ...'.\n"
        exit 1
    fi
    ARCH_ROOT="${BUILD_ROOT}/speex-${ARCH}"
    ARCH_LIB="${ARCH_ROOT}/lib"
    ARCH_INCLUDE="${ARCH_ROOT}/include"
    mkdir -p ${ARCH_ROOT}
    mkdir -p ${ARCH_LIB}
    mkdir -p ${ARCH_INCLUDE}

    if [ "${ARCH}" == "i386" -o "${ARCH}" == "x86_64" ]
    then
        PLATFORM="iphonesimulator"
        EXTRA_CONFIG="--host=x86_64-apple-darwin"
    else
        PLATFORM="iphoneos"
        EXTRA_CONFIG="--host=arm-apple-darwin"
    fi
    SYSROOT=eval xcrun -sdk ${PLATFORM} --show-sdk-path
    SPEEX_COMMON_CONFIG="${SPEEX_COMMON_CONFIG} --with-sysroot=${SYSROOT}"
    SPEEX_COMMON_CONFIG="${SPEEX_COMMON_CONFIG} --libdir=${ARCH_LIB}"
    SPEEX_COMMON_CONFIG="${SPEEX_COMMON_CONFIG} --includedir=${ARCH_INCLUDE}"

export CC="xcrun -sdk ${PLATFORM} clang -arch ${ARCH} ${XCRUN_OSVERSION}"
export CCAS="xcrun -sdk ${PLATFORM} clang -arch ${ARCH} ${XCRUN_OSVERSION} -no-integrated-as"
    cd ${SPEEX_DIR}
    ./configure ${SPEEX_COMMON_CONFIG} \
        ${EXTRA_CONFIG}

    make
    make install
    make clean
    cd `dirname $0`
}

build_all()
{
    for ARCH in ${ARCHS}
    do
        build_arch $ARCH
    done
}

build_lipo()
{
    LIPO_ROOT="${BUILD_ROOT}/speex-lipo"
    LIPO_LIB_DIR="${LIPO_ROOT}/lib"
    mkdir -p ${LIPO_ROOT}
    mkdir -p ${LIPO_LIB_DIR}
    LIPO_OS="libspeex-iphoneos.a"
    LIPO_SIM="libspeex-iphonesimulator.a"
    LIPO_All="libspeex.a"

    LIPO_TARGET=$1

case "$LIPO_TARGET" in
    os)
        LIPO_OUTFILE=${LIPO_OS}
        LIPO_SOURCE_ARCH="armv7 arm64"
    ;;
    simulator)
        LIPO_OUTFILE=${LIPO_SIM}
        LIPO_SOURCE_ARCH="i386 x86_64"
    ;;
    all)
        LIPO_OUTFILE=${LIPO_All}
        LIPO_SOURCE_ARCH=${ARCHS}
    ;;
    *)
    echo "  speex-ios.sh lipo [all|os|simulator]"
    exit 1
    ;;
esac

    LIPO_FLAGS=
    for ARCH in $LIPO_SOURCE_ARCH
    do
        SOURCE_DIR="${BUILD_ROOT}/speex-${ARCH}"
        SOURCE_LIB_FILE="${SOURCE_DIR}/lib/libspeex.a"
        if [ -f "$SOURCE_LIB_FILE" ]; then
            LIPO_FLAGS="$LIPO_FLAGS $SOURCE_LIB_FILE"
        else
            echo "skip $SOURCE_LIB_FILE of $ARCH";
        fi
    done
    cd $LIPO_LIB_DIR
    xcrun lipo -create $LIPO_FLAGS -output $LIPO_LIB_DIR/$LIPO_OUTFILE
    xcrun lipo -info $LIPO_LIB_DIR/$LIPO_OUTFILE
    du -h $LIPO_LIB_DIR/$LIPO_OUTFILE
    cd `dirname $0`
    if [ -f "$LIPO_LIB_DIR/$LIPO_OUTFILE" ]; then
        cp -R "${SOURCE_DIR}/include" "${LIPO_ROOT}"
    fi
}

build_clean()
{
    echo "clean build"
    echo "================="
    rm -rf ${BUILD_ROOT}
    echo "clean success"
}
#main
main()
{
    TARGET=$1
    if [ "$TARGET" = "armv7" -o "$TARGET" = "arm64" ]; then
        build_arch $TARGET
    elif [ "$TARGET" = "i386" -o "$TARGET" = "x86_64" ]; then
        build_arch $TARGET
    elif [ "$TARGET" = "lipo" ]; then
        build_lipo $2
    elif [ "$TARGET" = "all" ]; then
        build_all
    elif [ "$TARGET" = "check" ]; then
        echo_check
    elif [ "$TARGET" = "clean" ]; then
        build_clean
    else
        echo "Usage:"
        echo "  speex-ios.sh armv7|arm64|i386|x86_64"
        echo "  speex-ios.sh lipo all[os|simulator]"
        echo "  speex-ios.sh all"
        echo "  speex-ios.sh clean"
        echo "  speex-ios.sh check"
    exit 1
    fi
}

echo "============================="
echo "[*] speex-ios.sh xecute start"
echo "============================="
main $1 $2
echo "=============================="
echo "[*] speex-ios.sh xecute finish"
echo "=============================="

