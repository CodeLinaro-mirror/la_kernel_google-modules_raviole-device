#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

BAZEL=tools/bazel
TRADEFED=prebuilts/tradefed/filegroups/tradefed/tradefed.sh
JDK_PATH=prebuilts/jdk/jdk11/linux-x86
DIST_DIR=$PWD/out/slider/dist
TEST_DIR=$PWD/out/slider/dist/tests
LOG_DIR=$PWD/out/test_logs/$(date +%Y%m%d_%H%M%S)
SERIAL_NUMBER=
TEST_FILTERS=
SELECTED_TESTS=
PLATFORM_BUILD=
FLASH_KERNEL=true
BUILD_KERNEL=true
GCOV=false
FLASH_CLI=/google/bin/releases/android/flashstation/cl_flashstation


print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script will build, load kernels and run tests on an Android device."
    echo ""
    echo "Available options:"
    echo "  --skip-build-kernel   Skip the kernel building step"
    echo "  --skip-flash-kernel   Skip the flash kernel step"
    echo "  -s, --serial=SERIAL   The device serial number."
    echo "  -b, --platform-build  The platform build to be flashed with."
    echo "                        Can be branch name or build-id."
    echo "                        If not specified, no platform build will be flashed"
    echo "  -d, --dist-dir=DIR    The kernel dist dir (default is /tmp/kernel_dist)"
    echo "  -t, --test=TEST_NAME  The test name. Can be repeated"
    echo "                        If test is not specified, no tests will be run"
    echo "  -h, --help            Display this help message and exit"
    echo ""
    echo "Examples:"
    echo "$0 -s 1C141FDEE003FH"
    echo "$0 -s 1C141FDEE003FH -b git_trunk_pixel_kernel_61-release"
    echo "$0 -s 1C141FDEE003FH -t kunit"
    echo "$0 -s 1C141FDEE003FH -t selftests"
    echo "$0 -s 1C141FDEE003FH -t selftests:kselftest_binderfs_binderfs_test"
    echo ""
    exit 0
}

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            print_help
            ;;
        --skip-build-kernel)
            BUILD_KERNEL=false
            shift
            ;;
        --skip-flash-kernel)
            FLASH_KERNEL=false
            shift
            ;;
        -d)
            shift
            if test $# -gt 0; then
                DIST_DIR=$1
            else
                echo "kernel distribution directory is not specified"
                exit 1
            fi
            shift
            ;;
        --dist-dir*)
            DIST_DIR=$(echo $1 | sed -e "s/^[^=]*=//g")
            shift
            ;;
        -s)
            shift
            if test $# -gt 0; then
                SERIAL_NUMBER=$1
            else
                echo "device serial is not specified"
                exit 1
            fi
            shift
            ;;
        --serial*)
            SERIAL_NUMBER=$(echo $1 | sed -e "s/^[^=]*=//g")
            shift
            ;;
        -b)
            shift
            if test $# -gt 0; then
                PLATFORM_BUILD=$1
            else
                echo "platform is not specified"
                exit 1
            fi
            shift
            ;;
        --platform-build*)
            PLATFORM_BUILD=$(echo $1 | sed -e "s/^[^=]*=//g")
            shift
            ;;
        -t)
            shift
            if test $# -gt 0; then
                TEST_NAME=$1
                TEST_NAME=$(echo $TEST_NAME | sed "s/:/ /g")
                TEST_FILTERS+="--include-filter '$TEST_NAME' "
            else
                echo "test name is not specified"
                exit 1
            fi
            shift
            ;;
        --test*)
            TEST_NAME=$(echo $1 | sed -e "s/^[^=]*=//g")
            TEST_NAME=$(echo $TEST_NAME | sed "s/:/ /g")
            TEST_FILTERS+="--include-filter '$TEST_NAME' "
            shift
            ;;
        --gcov)
            GCOV=true
            shift
            ;;
        *)
            ;;
    esac
done


if [ -z "$SERIAL_NUMBER" ]; then
    echo "Device serial is not provided with command line flag -s|--serial"
    exit 1
else
    echo "Test with device: $SERIAL_NUMBER"
fi

if [ -z "$PLATFORM_BUILD" ]; then
    echo "Platform build is not specified. Skip flashing platform build."
else
    flash_cmd="$FLASH_CLI -t userdebug -w -s $SERIAL_NUMBER "
    if echo "$PLATFORM_BUILD" | grep -q "git"; then
        echo "Flash $SERIAL_NUMBER with platform build from branch $PLATFORM_BUILD..."
        flash_cmd+="-l $PLATFORM_BUILD"
    else
        echo "Flash $SERIAL_NUMBER with platform build $PLATFORM_BUILD..."
        flash_cmd+="-b $PLATFORM_BUILD"
    fi
    eval $flash_cmd
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "Flash platform succeeded"
    else
        echo "Flash platform build failed with exit code $exit_code"
        exit 1
    fi
fi

if $BUILD_KERNEL; then
    echo "Building kernel for raviole device..."
    $BAZEL run --config=raviole --config=fast //private/google-modules/soc/gs:slider_dist \
    --  --dist_dir=$DIST_DIR
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "Build kernel succeeded"
    else
        echo "Build kernel failed with exit code $exit_code"
        exit 1
    fi
fi


tf_cli="JAVA_HOME=$JDK_PATH PATH=$JDK_PATH/bin:$PATH $TRADEFED \
run commandAndExit template/local_min \
--log-level-display info --log-file-path=$LOG_DIR \
-s $SERIAL_NUMBER"

if $FLASH_KERNEL; then
    cp -f $DIST_DIR/boot.img $TEST_DIR/boot.img
    cp -f $DIST_DIR/initramfs.img $TEST_DIR/initramfs.img
    cp -f $DIST_DIR/dtbo.img $TEST_DIR/dtbo.img
    cp -f $DIST_DIR/vendor_dlkm.img $TEST_DIR/vendor_dlkm.img
    tf_cli+=" --template:map preparers=template/preparers/gki-device-flash-preparer \
              --extra-file gki_boot.img=$TEST_DIR/boot.img \
              --extra-file initramfs.img=$TEST_DIR/initramfs.img \
              --extra-file dtbo.img=$TEST_DIR/dtbo.img \
              --extra-file vendor_dlkm.img=$TEST_DIR/vendor_dlkm.img"
fi

if [ -z "$TEST_FILTERS" ]; then
    echo "No test will be run..."
else
    if test -d "$TEST_DIR"; then
        echo "Unzip $DIST_DIR/tests.zip to $TEST_DIR"
    else
        mkdir $TEST_DIR
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo "Created directory $TEST_DIR and unzip $DIST_DIR/tests.zip"
        else
            echo "Failed to create test directory $TEST_DIR."
            exit 1
        fi
    fi
    unzip -oq $DIST_DIR/tests.zip -d $TEST_DIR
    tf_cli+=" --template:map test=suite/test_mapping_suite --tests-dir=$TEST_DIR"
    tf_cli+=" --primary-abi-only $TEST_FILTERS"
fi

if $GCOV; then
    tf_cli+=" --coverage --coverage-toolchain GCOV_KERNEL --auto-collect GCOV_KERNEL_COVERAGE"
fi

eval $tf_cli
