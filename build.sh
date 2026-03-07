#!/bin/bash
SCRIPT_DIR="$(dirname $(readlink -fq $0))"

# update git submodules if exists
git submodule update --init --recursive || true

# clean up everything
clean_up() {
    rm -rf "${SCRIPT_DIR}/dist"
    rm -rf "${SCRIPT_DIR}/out"

    cd "${SCRIPT_DIR}/prebuilts_a166p" && \
        git clean -xdf
}

mkdir -p "${SCRIPT_DIR}/dist"

# check and install requirements and install Samsung's ndk
install_requirements() {
    local packages=('rsync' 'curl')
    local missing_pkgs=()

    if ! command -v dpkg &>/dev/null; then
        echo "This script is intended to run in Ubuntu/Debian-based Distributions only !"
        exit 1
    fi

    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        local unique_pkgs=$(echo "${missing_pkgs[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
        echo "Installing required package(s): ${unique_pkgs}"
        sudo apt update && sudo apt install -y "${unique_pkgs}"
    else
        echo "All required packages are already installed."
    fi

    # Init Samsung's ndk
    if [[ ! -d "${SCRIPT_DIR}/kernel/prebuilts" || ! -d "${SCRIPT_DIR}/prebuilts" ]]; then
        echo -e "[INFO] Cloning Samsung's NDK..."
        curl -LO "https://github.com/ravindu644/android_kernel_a166p/releases/download/toolchain/toolchain.tar.gz" || {
            echo "Failed to download Samsung's NDK. Please check your internet connection and try again."
            exit 1
        }
        tar -xf toolchain.tar.gz && rm toolchain.tar.gz
        cd "${SCRIPT_DIR}"
    fi
}

# Localversion
if [ -z "$BUILD_KERNEL_VERSION" ]; then
    export BUILD_KERNEL_VERSION="dev"
fi

echo -e "CONFIG_LOCALVERSION_AUTO=n\nCONFIG_LOCALVERSION=\"-Ubuntu-LXC-Docker-ravindu644-${BUILD_KERNEL_VERSION}\"\n" > "${SCRIPT_DIR}/custom_defconfigs/version_defconfig"

export_common_build_env() {

    echo "[INFO] Generating build config..."

    cd "${SCRIPT_DIR}/kernel-5.15"

    # cook build config
    python3 scripts/gen_build_config.py \
        --kernel-defconfig a25ex_00_defconfig \
        --kernel-defconfig-overlays "entry_level.config" \
        -m user -o ../out/target/product/a25ex/obj/KERNEL_OBJ/build.config

    # common exports from samsung's build_kernel.sh
    export ARCH=arm64
    export PLATFORM_VERSION=13
    export CROSS_COMPILE="aarch64-linux-gnu-"
    export CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
    export OUT_DIR="../out/target/product/a25ex/obj/KERNEL_OBJ"
    export DIST_DIR="../out/target/product/a25ex/obj/KERNEL_OBJ"
    export BUILD_CONFIG="../out/target/product/a25ex/obj/KERNEL_OBJ/build.config"

    cd "${SCRIPT_DIR}"

}

export_custom_build_env(){

    # add custom build options to here
    # check out the kernel/build/build.sh to possible variables
    export GKI_KERNEL_BUILD_OPTIONS=(
        "SKIP_MRPROPER=1"
        "KMI_SYMBOL_LIST_STRICT_MODE=0"
        "ABI_DEFINITION="
        "BUILD_BOOT_IMG=1"
        "MKBOOTIMG_PATH=${SCRIPT_DIR}/prebuilts_a166p/mkbootimg/mkbootimg.py"
        "KERNEL_BINARY=Image.gz"
        "BOOT_IMAGE_HEADER_VERSION=4"
        "SKIP_VENDOR_BOOT=1"
        "AVB_SIGN_BOOT_IMG=1"
        "AVB_BOOT_PARTITION_SIZE=67108864"
        "AVB_BOOT_KEY=${SCRIPT_DIR}/prebuilts_a166p/mkbootimg/tests/data/testkey_rsa2048.pem"
        "AVB_BOOT_ALGORITHM=SHA256_RSA2048"
        "AVB_BOOT_PARTITION_NAME=boot"
    )

    # Build options (extra)
    export MKBOOTIMG_EXTRA_ARGS="
        --os_version 13.0.0 \
        --os_patch_level 2025-07-00 \
        --pagesize 4096 \
    "

    # Run menuconfig only if you want to.
    # It's better to use MAKE_MENUCONFIG=0 when everything is already properly enabled, disabled, or configured.
    export MAKE_MENUCONFIG=0

    if [ "$MAKE_MENUCONFIG" = "1" ]; then
        export HERMETIC_TOOLCHAIN=0
    fi

    # environment variables for custom defconfigs support
    export MERGE_CONFIG="${SCRIPT_DIR}/kernel-5.15/scripts/kconfig/merge_config.sh"
    
    # Collect realpaths as a space-separated list
    if [ -d "${SCRIPT_DIR}/custom_defconfigs" ]; then
        CUSTOM_DEFCONFIGS_LIST=$(find "${SCRIPT_DIR}/custom_defconfigs" -maxdepth 1 -type f -exec realpath {} \; | tr '\n' ' ')
    else
        CUSTOM_DEFCONFIGS_LIST=""
    fi
    export CUSTOM_DEFCONFIGS_LIST

}

# main kernel build function
build_gki_kernel(){
    cd "${SCRIPT_DIR}/kernel"

    env "${GKI_KERNEL_BUILD_OPTIONS[@]}" ./build/build.sh && \
        cp "${SCRIPT_DIR}/out/target/product/a25ex/obj/KERNEL_OBJ/kernel-5.15/arch/arm64/boot/Image"* \
           "${SCRIPT_DIR}/out/target/product/a25ex/obj/KERNEL_OBJ/dist/boot.img" \
           "${SCRIPT_DIR}/dist"

    local exit_code=$?
    cd "${SCRIPT_DIR}"
    return $exit_code
}

# build vendor boot
build_vendor_boot(){
    SCRIPT_DIR="${SCRIPT_DIR}" \
        "${SCRIPT_DIR}/prebuilts_a166p/scripts/build_vendor_boot.sh"
}

# build vendor dlkm
build_vendor_dlkm(){
    SCRIPT_DIR="${SCRIPT_DIR}" \
        "${SCRIPT_DIR}/prebuilts_a166p/scripts/build_vendor_dlkm.sh"
}

# package stuffs
package_stuff(){
    cd "${SCRIPT_DIR}/dist"

    tar -cvf "SM-A253Z-Ubuntu-LXC-Docker-KernelSU-${BUILD_KERNEL_VERSION}.tar" boot.img vendor_boot.img || {
        echo "Error: Failed to create tar file"
        return 1
    }

    zip -9 -r "SM-A253Z-Ubuntu-LXC-Docker-KernelSU-${BUILD_KERNEL_VERSION}.zip" \
        "SM-A253Z-Ubuntu-LXC-Docker-KernelSU-${BUILD_KERNEL_VERSION}.tar" \
        vendor_dlkm.img || {
        echo "Error: Failed to create zip file"
        return 1
    }

    rm -f "SM-A253Z-Ubuntu-LXC-Docker-KernelSU-${BUILD_KERNEL_VERSION}.tar" vendor_dlkm.img boot.img vendor_boot.img

    cd "${SCRIPT_DIR}"
}

#clean_up
install_requirements
export_common_build_env
export_custom_build_env
build_gki_kernel || exit 1
build_vendor_boot || exit 1
build_vendor_dlkm || exit 1
package_stuff || exit 1

echo ""
echo "[INFO] Kernel build completed successfully"
