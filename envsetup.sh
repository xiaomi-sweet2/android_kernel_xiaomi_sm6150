#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

### Customisable variables
export AK3_URL=https://github.com/dereference23/AnyKernel3
export AK3_BRANCH=main
export DEFCONFIG_NAME=sweet2
export TC_DIR="$PWD/../prebuilts/clang"
export ZIPNAME="positron-sweet2-$(date +%Y%m%d).zip"
export LLVM_VERSION=18.1.4

export KBUILD_OUTPUT=out
export KBUILD_BUILD_USER=dereference23
export KBUILD_BUILD_HOST=github.com
### End

# Set up environment
function envsetup() {
    export ARCH=arm64
    export PATH="$TC_DIR/$LLVM_VERSION/bin:$PATH"
    export CROSS_COMPILE=aarch64-linux-gnu-
    export CROSS_COMPILE_ARM32=arm-none-eabi-
    export CROSS_COMPILE_COMPAT=arm-none-eabi-
    [ -d "$TC_DIR/$LLVM_VERSION" ] || installtc
}

# Install toolchain
function installtc() {
    curl https://mirrors.edge.kernel.org/pub/tools/llvm/files/llvm-$LLVM_VERSION-$(uname -m).tar.xz | tar Jx --one-top-level="$TC_DIR/$LLVM_VERSION" --strip-components=1
}

# Wrapper to utilise all available cores
function m() {
	make -j$(nproc) DTC_EXT=dtc LLVM_IAS=1 HOSTAR=llvm-ar HOSTCC=clang HOSTCXX=clang++ HOSTLD=ld.lld CC="ccache clang" LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip "$@"
}

# Build kernel
function mka() {
    rd || return
    m
}

# Pack kernel and upload it
function pack() {
    AK3=AnyKernel3
    if [ ! -d $AK3 ]; then
        git clone $AK3_URL $AK3 -b $AK3_BRANCH --depth 1 -q || return
    fi

    OUT=arch/arm64/boot
    cp "$KBUILD_OUTPUT"/$OUT/Image $AK3 || return
    cp "$KBUILD_OUTPUT"/$OUT/dtbo.img $AK3 2> /dev/null
    find "$KBUILD_OUTPUT"/$OUT/dts -name *.dtb -exec cat {} + > $AK3/dtb
    rm $AK3/*.zip 2> /dev/null
    ( cd $AK3 && zip -r9 "$ZIPNAME" * -x .git README.md *placeholder ) || return
#    curl -T "$AK3/$ZIPNAME" https://oshi.at
    filedoge "$AK3/$ZIPNAME"
}

function recompress() {
    advzip -z4 AnyKernel3/*.zip
    curl -T AnyKernel3/*.zip https://oshi.at
}

# Regenerate defconfig
function rd() {
   m ${DEFCONFIG_NAME}_defconfig savedefconfig || return
   cp "$KBUILD_OUTPUT"/defconfig arch/arm64/configs/${DEFCONFIG_NAME}_defconfig
}

envsetup
