#!/bin/bash
SCRIPT_DIR="$(dirname $(readlink -fq $0))"

# update git submodules if exists
git submodule update --init --recursive || true

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

export_common_build_env() {

    cd "${SCRIPT_DIR}/kernel-5.15"

    # cook build config
    python scripts/gen_build_config.py \
        --kernel-defconfig a16xm_00_defconfig \
        --kernel-defconfig-overlays "entry_level.config S98901AA1.config S98901AA1_debug.config" \
        -m user -o ../out/target/product/a16xm/obj/KERNEL_OBJ/build.config &>/dev/null

    # common exports from samsung's build_kernel.sh
    export ARCH=arm64
    export PLATFORM_VERSION=13
    export CROSS_COMPILE="aarch64-linux-gnu-"
    export CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
    export OUT_DIR="../out/target/product/a16xm/obj/KERNEL_OBJ"
    export DIST_DIR="../out/target/product/a16xm/obj/KERNEL_OBJ"
    export BUILD_CONFIG="../out/target/product/a16xm/obj/KERNEL_OBJ/build.config"

    cd "${SCRIPT_DIR}"

}

export_custom_build_env(){

    # add custom build options to here
    # check out the kernel/build/build.sh to possible variables
    export GKI_KERNEL_BUILD_OPTIONS=(
        "SKIP_MRPROPER=1"
        "KMI_SYMBOL_LIST_STRICT_MODE=0"
        "ABI_DEFINITION="
    )

}

# main kernel build function
build_gki_kernel(){
    cd "${SCRIPT_DIR}/kernel"
    env "${GKI_KERNEL_BUILD_OPTIONS[@]}" ./build/build.sh
    local exit_code=$?
    cd "${SCRIPT_DIR}"
    return $exit_code
}

install_requirements
export_common_build_env
export_custom_build_env
build_gki_kernel || exit 1
